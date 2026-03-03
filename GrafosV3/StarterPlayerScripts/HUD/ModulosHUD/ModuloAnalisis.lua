-- StarterPlayerScripts/HUD/ModulosHUD/ModuloAnalisis.lua
-- Modo Análisis: simulador paso-a-paso de BFS, DFS, Dijkstra y Prim.
-- Sigue el mismo ciclo de vida que Minimap.lua y ModuloMatriz.lua.
--
-- API pública:
--   ModuloAnalisis.inicializar(hudGui)
--   ModuloAnalisis.configurarNivel(nivelModel, nivelID, configNivel)
--   ModuloAnalisis.abrir()
--   ModuloAnalisis.cerrar()
--   ModuloAnalisis.limpiar()
--   ModuloAnalisis.estaAbierto() -> bool

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")

local AlgoritmosGrafo = require(script.Parent.AlgoritmosGrafo)

local jugador = Players.LocalPlayer

local ModuloAnalisis = {}

-- ════════════════════════════════════════════════════════════════
-- COLORES
-- ════════════════════════════════════════════════════════════════
local COL_DEFAULT   = Color3.fromRGB(100, 116, 139)  -- gris  (sin visitar)
local COL_ACTUAL    = Color3.fromRGB(251, 146,  60)  -- naranja (nodo procesado)
local COL_VISITADO  = Color3.fromRGB( 34, 197,  94)  -- verde  (visitado / en MST)
local COL_PENDIENTE = Color3.fromRGB( 59, 130, 246)  -- azul   (en cola/pila/PQ)

local COL_ARISTA_DEF = Color3.fromRGB(71, 85, 105)   -- gris oscuro

local COL_LINEA_ACTIVA = Color3.fromRGB(251, 146,  60)
local COL_LINEA_NORMAL = Color3.fromRGB(176, 190, 197)

local COL_PILL_ACTIVO   = Color3.fromRGB( 59, 130, 246)
local COL_PILL_INACTIVO = Color3.fromRGB( 30,  41,  59)

local TAM_NODO   = 3    -- diámetro de la esfera de nodo (studs)
local TAM_ARISTA = 0.4  -- grosor del cilindro de arista

-- ════════════════════════════════════════════════════════════════
-- ESTADO INTERNO
-- ════════════════════════════════════════════════════════════════
local _hudGui     = nil
local _overlay    = nil   -- Frame OverlayAnalisis
local _abierto    = false

local _nivelModel  = nil
local _nivelID     = nil

-- RemoteFunction (lazy)
local _getMatrixFunc = nil

-- Datos del grafo activo
local _matrizData  = nil   -- { Headers, Matrix, NombresNodos, EsDirigido }
local _adyacencias = {}    -- { [nomNodo] = { nomVecino, ... } }

-- Simulación
local _pasos      = {}
local _pasoActual = 0
local _totalPasos = 0
local _algoActual = "bfs"

-- ViewportFrame
local _visor      = nil
local _worldModel = nil
local _camAnalisis = nil
local _nodoParts   = {}   -- { [nombre] = Part esfera }
local _aristaParts = {}   -- array de Parts cilíndricas

-- ════════════════════════════════════════════════════════════════
-- HELPERS GUI
-- ════════════════════════════════════════════════════════════════
local function buscar(parent, nombre)
	if not parent then return nil end
	return parent:FindFirstChild(nombre, true)
end

local function addCorner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 4)
	c.Parent = parent
end

-- Para Dijkstra/Prim los pendientes tienen formato "N1=0" o "N1=∞";
-- esta función extrae el nombre puro antes del "=".
local function esNodoPendiente(pendientes, nome)
	for _, v in ipairs(pendientes) do
		local n = tostring(v):match("^(.-)=") or v
		if n == nome then return true end
	end
	return false
end

-- ════════════════════════════════════════════════════════════════
-- BUSCAR POSICIÓN DE UN NODO EN EL NIVEL
-- Patrón idéntico a Minimap.lua
-- ════════════════════════════════════════════════════════════════
local function buscarPosNodo(nombre)
	if not _nivelModel then return Vector3.zero end
	local grafos = _nivelModel:FindFirstChild("Grafos")
	if not grafos then return Vector3.zero end

	for _, grafo in ipairs(grafos:GetChildren()) do
		local nodosFolder = grafo:FindFirstChild("Nodos")
		if not nodosFolder then continue end
		local nodoModelo = nodosFolder:FindFirstChild(nombre)
		if not nodoModelo then continue end

		local selector = nodoModelo:FindFirstChild("Selector")
		local posRef   = nil
		if selector then
			if selector:IsA("BasePart") then
				posRef = selector
			elseif selector:IsA("Model") then
				posRef = selector.PrimaryPart
				    or selector:FindFirstChildWhichIsA("BasePart", true)
			end
		end
		if not posRef then
			posRef = nodoModelo.PrimaryPart
			    or nodoModelo:FindFirstChildWhichIsA("BasePart", true)
		end
		if posRef then return posRef.Position end
	end
	return Vector3.zero
end

-- ════════════════════════════════════════════════════════════════
-- VIEWPORT: construir nodos y aristas en WorldModel
-- ════════════════════════════════════════════════════════════════
local function construirViewport()
	if not _visor or not _worldModel or not _matrizData then return end

	_worldModel:ClearAllChildren()
	_nodoParts  = {}
	_aristaParts = {}

	local headers    = _matrizData.Headers
	local posiciones = {}  -- { [nombre] = Vector3 }

	-- Nodos
	for _, nome in ipairs(headers) do
		local pos = buscarPosNodo(nome)
		posiciones[nome] = pos

		local part        = Instance.new("Part")
		part.Name         = nome .. "_ANA"
		part.Shape        = Enum.PartType.Ball
		part.Anchored     = true
		part.CanCollide   = false
		part.CastShadow   = false
		part.Material     = Enum.Material.SmoothPlastic
		part.Size         = Vector3.new(TAM_NODO, TAM_NODO, TAM_NODO)
		part.Color        = COL_DEFAULT
		part.CFrame       = CFrame.new(pos)
		part.Parent       = _worldModel

		_nodoParts[nome] = part
	end

	-- Aristas (sin duplicar A-B / B-A)
	local vistos = {}
	for nomA, lista in pairs(_adyacencias) do
		for _, nomB in ipairs(lista) do
			local key = nomA < nomB and (nomA .. "|" .. nomB) or (nomB .. "|" .. nomA)
			if vistos[key] then continue end
			vistos[key] = true

			local posA = posiciones[nomA]
			local posB = posiciones[nomB]
			if not posA or not posB then continue end

			local dist = (posA - posB).Magnitude
			if dist < 0.1 then continue end

			local centro = (posA + posB) / 2
			local arista        = Instance.new("Part")
			arista.Name         = "Arista_ANA"
			arista.Anchored     = true
			arista.CanCollide   = false
			arista.CastShadow   = false
			arista.Material     = Enum.Material.SmoothPlastic
			arista.Size         = Vector3.new(TAM_ARISTA, TAM_ARISTA, dist)
			arista.CFrame       = CFrame.lookAt(centro, posB)
			arista.Color        = COL_ARISTA_DEF
			arista.Parent       = _worldModel

			table.insert(_aristaParts, arista)
		end
	end

	-- Cámara top-down sobre el centroide de los nodos
	local n = 0
	local sumX, sumY, sumZ = 0, 0, 0
	for _, pos in pairs(posiciones) do
		sumX = sumX + pos.X
		sumY = sumY + pos.Y
		sumZ = sumZ + pos.Z
		n    = n + 1
	end

	if n > 0 and _camAnalisis then
		local cx = sumX / n
		local cy = sumY / n
		local cz = sumZ / n

		local maxR = 0
		for _, pos in pairs(posiciones) do
			local r = math.sqrt((pos.X - cx)^2 + (pos.Z - cz)^2)
			if r > maxR then maxR = r end
		end
		local altura = math.max(30, maxR * 2.5)

		_camAnalisis.CFrame      = CFrame.new(cx, cy + altura, cz) * CFrame.Angles(math.rad(-90), 0, 0)
		_camAnalisis.FieldOfView = 70
	end

	print("[ModuloAnalisis] Viewport construido —", #headers, "nodos")
end

-- ════════════════════════════════════════════════════════════════
-- PSEUDOCÓDIGO: reconstruir TextLabels en ScrollPseudocodigo
-- ════════════════════════════════════════════════════════════════
local function reconstruirPseudocodigo(algo)
	local scroll = buscar(_overlay, "ScrollPseudocodigo")
	if not scroll then return end

	-- Limpiar
	for _, child in ipairs(scroll:GetChildren()) do
		if not child:IsA("UIListLayout") then child:Destroy() end
	end
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)

	local pseudo = AlgoritmosGrafo.PSEUDOCODIGOS[algo]
	if not pseudo then return end

	-- Layout
	local existing = scroll:FindFirstChildWhichIsA("UIListLayout")
	if not existing then
		local layout        = Instance.new("UIListLayout")
		layout.SortOrder    = Enum.SortOrder.LayoutOrder
		layout.Padding      = UDim.new(0, 2)
		layout.Parent       = scroll
	end

	local altLinea = 20

	for i, linea in ipairs(pseudo.lineas) do
		local lbl                    = Instance.new("TextLabel")
		lbl.Name                     = "Linea_" .. i
		lbl.LayoutOrder              = i
		lbl.Size                     = UDim2.new(1, -6, 0, altLinea)
		lbl.BackgroundTransparency   = 1
		lbl.Text                     = (linea == "") and " " or linea
		lbl.TextColor3               = COL_LINEA_NORMAL
		lbl.Font                     = Enum.Font.Code
		lbl.TextSize                 = 12
		lbl.TextXAlignment           = Enum.TextXAlignment.Left
		lbl.TextTruncate             = Enum.TextTruncate.AtEnd
		lbl:SetAttribute("NumLinea", i)
		lbl.Parent                   = scroll
	end

	local total = #pseudo.lineas * (altLinea + 2) + 8
	scroll.CanvasSize = UDim2.new(0, 0, 0, total)

	-- Insignia de complejidad
	local insignia = buscar(_overlay, "InsigniaComplejidad")
	if insignia then
		local lbl = insignia:IsA("TextLabel") and insignia
		         or insignia:FindFirstChildWhichIsA("TextLabel")
		if lbl then
			lbl.Text = pseudo.titulo .. "  •  " .. pseudo.complejidad
		end
	end
end

-- ════════════════════════════════════════════════════════════════
-- PSEUDOCÓDIGO: resaltar línea activa
-- ════════════════════════════════════════════════════════════════
local function resaltarLinea(numLinea)
	local scroll = buscar(_overlay, "ScrollPseudocodigo")
	if not scroll then return end

	for _, child in ipairs(scroll:GetChildren()) do
		if not child:IsA("TextLabel") then continue end
		local n = child:GetAttribute("NumLinea")
		if n == numLinea then
			child.TextColor3           = COL_LINEA_ACTIVA
			child.BackgroundTransparency = 0.6
			child.BackgroundColor3     = Color3.fromRGB(120, 60, 10)
		else
			child.TextColor3           = COL_LINEA_NORMAL
			child.BackgroundTransparency = 1
		end
	end
end

-- ════════════════════════════════════════════════════════════════
-- SCROLL ESTADO: reconstruir filas con el estado actual
-- ════════════════════════════════════════════════════════════════
local function actualizarScrollEstado(step)
	local scroll = buscar(_overlay, "ScrollEstado")
	if not scroll then return end

	-- Limpiar
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)

	if not step then return end

	local layout     = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding   = UDim.new(0, 3)
	layout.Parent    = scroll

	local altFila = 22
	local orden   = 0

	local function crearFila(etiqueta, valor, bgColor)
		bgColor = bgColor or Color3.fromRGB(30, 41, 59)
		local frame             = Instance.new("Frame")
		frame.LayoutOrder       = orden
		frame.Size              = UDim2.new(1, -4, 0, altFila)
		frame.BackgroundColor3  = bgColor
		frame.BackgroundTransparency = 0.3
		frame.BorderSizePixel   = 0
		frame.Parent            = scroll
		addCorner(frame, 4)

		local etiq              = Instance.new("TextLabel")
		etiq.Size               = UDim2.new(0.38, 0, 1, 0)
		etiq.BackgroundTransparency = 1
		etiq.Text               = etiqueta
		etiq.TextColor3         = Color3.fromRGB(148, 163, 184)
		etiq.Font               = Enum.Font.Gotham
		etiq.TextSize           = 11
		etiq.TextXAlignment     = Enum.TextXAlignment.Left
		etiq.Parent             = frame

		local val               = Instance.new("TextLabel")
		val.Size                = UDim2.new(0.62, 0, 1, 0)
		val.Position            = UDim2.new(0.38, 0, 0, 0)
		val.BackgroundTransparency = 1
		val.Text                = tostring(valor)
		val.TextColor3          = Color3.new(1, 1, 1)
		val.Font                = Enum.Font.Code
		val.TextSize            = 11
		val.TextXAlignment      = Enum.TextXAlignment.Left
		val.TextTruncate        = Enum.TextTruncate.AtEnd
		val.Parent              = frame

		orden = orden + 1
	end

	-- Estructura activa
	crearFila(step.struct .. ":",
		#step.structConten > 0 and table.concat(step.structConten, ", ") or "(vacía)",
		Color3.fromRGB(20, 50, 90))

	-- Nodo actual
	if step.nodoActual then
		crearFila("Nodo actual:", step.nodoActual, Color3.fromRGB(90, 50, 10))
	end

	-- Visitados
	crearFila("Visitados:",
		#step.visitados > 0 and table.concat(step.visitados, ", ") or "ninguno")

	-- Pendientes
	crearFila("Pendientes:",
		#step.pendientes > 0 and table.concat(step.pendientes, ", ") or "ninguno")

	-- Distancias (BFS / Dijkstra)
	if step.distancias then
		local keys = {}
		for k in pairs(step.distancias) do keys[#keys+1] = k end
		table.sort(keys)
		local partes = {}
		for _, k in ipairs(keys) do
			partes[#partes+1] = k .. ":" .. tostring(step.distancias[k])
		end
		if #partes > 0 then
			crearFila("Distancias:", table.concat(partes, "  "))
		end
	end

	scroll.CanvasSize = UDim2.new(0, 0, 0, orden * (altFila + 3) + 8)
end

-- ════════════════════════════════════════════════════════════════
-- APLICAR PASO: actualizar viewport + toda la UI
-- ════════════════════════════════════════════════════════════════
local function aplicarPaso(step)
	if not step then return end

	-- 1. Colorear nodos en WorldModel
	for nome, part in pairs(_nodoParts) do
		if nome == step.nodoActual then
			part.Color    = COL_ACTUAL
			part.Material = Enum.Material.Neon
		elseif table.find(step.visitados, nome) then
			part.Color    = COL_VISITADO
			part.Material = Enum.Material.Neon
		elseif esNodoPendiente(step.pendientes, nome) then
			part.Color    = COL_PENDIENTE
			part.Material = Enum.Material.Neon
		else
			part.Color    = COL_DEFAULT
			part.Material = Enum.Material.SmoothPlastic
		end
	end

	-- 2. Número y descripción del paso
	local numPasoLbl = buscar(_overlay, "NumPaso")
	local descPasoLbl = buscar(_overlay, "DescPaso")
	if numPasoLbl  then numPasoLbl.Text  = "PASO " .. _pasoActual .. " / " .. _totalPasos end
	if descPasoLbl then descPasoLbl.Text = step.descripcion or "" end

	-- 3. Barra de recorrido
	local labelRecorrido = buscar(_overlay, "LabelRecorrido")
	if labelRecorrido then
		labelRecorrido.Text = #step.visitados > 0
			and table.concat(step.visitados, " → ")
			or "—"
	end

	-- 4. Resaltar línea de pseudocódigo
	resaltarLinea(step.lineaPseudo)

	-- 5. ScrollEstado
	actualizarScrollEstado(step)

	-- 6. Métricas
	local totalNodos   = _matrizData and #_matrizData.Headers or 0
	local metricaPasos = buscar(_overlay, "MetricaPasos")
	local metricaNodos = buscar(_overlay, "MetricaNodos")
	if metricaPasos then metricaPasos.Text = _pasoActual .. " / " .. _totalPasos end
	if metricaNodos then metricaNodos.Text = #step.visitados .. " / " .. totalNodos end

	-- 7. Barra de progreso
	local relleno = buscar(_overlay, "RellenoProgreso")
	if relleno and _totalPasos > 0 then
		relleno.Size = UDim2.new(_pasoActual / _totalPasos, 0, 1, 0)
	end
end

-- ════════════════════════════════════════════════════════════════
-- CONSTRUIR ADYACENCIAS DESDE LOS DATOS DE LA MATRIZ
-- ════════════════════════════════════════════════════════════════
local function buildAdyacencias(data)
	local adj     = {}
	local headers = data.Headers
	local n       = #headers
	for i = 1, n do
		local nomA   = headers[i]
		adj[nomA]    = adj[nomA] or {}
		local fila   = data.Matrix[i]
		if fila then
			for j = 1, n do
				if (fila[j] or 0) > 0 then
					table.insert(adj[nomA], headers[j])
				end
			end
		end
	end
	return adj
end

-- ════════════════════════════════════════════════════════════════
-- EJECUTAR ALGORITMO (o re-ejecutar)
-- ════════════════════════════════════════════════════════════════
local function ejecutarAlgoritmo()
	if not _matrizData then return end

	local nodos = _matrizData.Headers
	local fn    = AlgoritmosGrafo[_algoActual]
	if not fn then
		warn("[ModuloAnalisis] Algoritmo desconocido:", _algoActual)
		return
	end

	_pasos      = fn(nodos, _adyacencias, nodos[1])
	_totalPasos = #_pasos
	_pasoActual = 1

	if _totalPasos > 0 then
		aplicarPaso(_pasos[_pasoActual])
	end

	print(string.format("[ModuloAnalisis] %s — %d pasos sobre %d nodos",
		_algoActual:upper(), _totalPasos, #nodos))
end

-- ════════════════════════════════════════════════════════════════
-- PILLS: actualizar colores y cambiar algoritmo
-- ════════════════════════════════════════════════════════════════
local PILL_NAMES = {
	bfs      = "PillBFS",
	dfs      = "PillDFS",
	dijkstra = "PillDijkstra",
	prim     = "PillPrim",
}

local function actualizarPills(algoActivo)
	for id, pillName in pairs(PILL_NAMES) do
		local pill = buscar(_overlay, pillName)
		if pill then
			pill.BackgroundColor3 = (id == algoActivo) and COL_PILL_ACTIVO or COL_PILL_INACTIVO
		end
	end
end

local function seleccionarAlgo(algo)
	_algoActual = algo
	actualizarPills(algo)
	reconstruirPseudocodigo(algo)
	if _matrizData then ejecutarAlgoritmo() end
end

-- ════════════════════════════════════════════════════════════════
-- LAZY-GET RemoteFunction
-- ════════════════════════════════════════════════════════════════
local function getMatrixFunc()
	if _getMatrixFunc then return _getMatrixFunc end
	local ok, remote = pcall(function()
		return RS:WaitForChild("EventosGrafosV3", 10)
		          :WaitForChild("Remotos", 5)
		          :WaitForChild("GetAdjacencyMatrix", 5)
	end)
	if ok and remote then
		_getMatrixFunc = remote
		return remote
	end
	warn("[ModuloAnalisis] GetAdjacencyMatrix no encontrada")
	return nil
end

-- ════════════════════════════════════════════════════════════════
-- MENSAJE EN EL PANEL (cuando no hay datos)
-- ════════════════════════════════════════════════════════════════
local function mostrarMensajeDesc(msg)
	local descLbl = buscar(_overlay, "DescPaso")
	if descLbl then descLbl.Text = msg end
	local numLbl = buscar(_overlay, "NumPaso")
	if numLbl then numLbl.Text = "— / —" end
	local recLbl = buscar(_overlay, "LabelRecorrido")
	if recLbl then recLbl.Text = "—" end
	local relleno = buscar(_overlay, "RellenoProgreso")
	if relleno then relleno.Size = UDim2.new(0, 0, 1, 0) end
end

-- ════════════════════════════════════════════════════════════════
-- API PÚBLICA
-- ════════════════════════════════════════════════════════════════

function ModuloAnalisis.inicializar(hudGui)
	_hudGui = hudGui

	_overlay = hudGui:FindFirstChild("OverlayAnalisis", true)
	if not _overlay then
		warn("[ModuloAnalisis] OverlayAnalisis no encontrado en GUIExploradorV2")
		return
	end
	_overlay.Visible = false

	-- ViewportFrame VisorGrafoAna
	_visor = buscar(_overlay, "VisorGrafoAna")
	if _visor then
		_worldModel = _visor:FindFirstChild("WorldModel")
		if not _worldModel then
			_worldModel        = Instance.new("WorldModel")
			_worldModel.Parent = _visor
		end

		_camAnalisis = _visor.CurrentCamera
		if not _camAnalisis then
			_camAnalisis             = Instance.new("Camera")
			_camAnalisis.FieldOfView = 70
			_camAnalisis.Parent      = _visor
			_visor.CurrentCamera     = _camAnalisis
		end
	else
		warn("[ModuloAnalisis] VisorGrafoAna no encontrado")
	end

	-- Conectar pills de algoritmo
	for algo, pillName in pairs(PILL_NAMES) do
		local pill = buscar(_overlay, pillName)
		if pill then
			local a = algo
			pill.MouseButton1Click:Connect(function()
				seleccionarAlgo(a)
			end)
		end
	end

	-- Botón Re-ejecutar
	local btnEjec = buscar(_overlay, "BtnEjecutarAlgo")
	if btnEjec then
		btnEjec.MouseButton1Click:Connect(function()
			if not _abierto then return end
			local zona = jugador:GetAttribute("ZonaActual") or ""
			if zona == "" then
				mostrarMensajeDesc("Entra en una zona para analizar su grafo.")
				return
			end
			local fn = getMatrixFunc()
			if not fn then return end
			mostrarMensajeDesc("Actualizando datos…")
			task.spawn(function()
				local ok, datos = pcall(function() return fn:InvokeServer(zona) end)
				if ok and datos and not datos.SinZona and #datos.Headers > 0 then
					_matrizData  = datos
					_adyacencias = buildAdyacencias(datos)
					construirViewport()
					ejecutarAlgoritmo()
				else
					mostrarMensajeDesc("Sin datos para zona: " .. zona)
					actualizarScrollEstado(nil)
				end
			end)
		end)
	end

	-- Botones de cerrar
	local btnCerrar = buscar(_overlay, "BtnCerrarAnalisis")
	if btnCerrar then
		btnCerrar.MouseButton1Click:Connect(function() ModuloAnalisis.cerrar() end)
	end
	local btnSalir = buscar(_overlay, "BtnSalirAnalisis")
	if btnSalir then
		btnSalir.MouseButton1Click:Connect(function() ModuloAnalisis.cerrar() end)
	end

	-- Botón Siguiente
	local btnSig = buscar(_overlay, "BtnSiguiente")
	if btnSig then
		btnSig.MouseButton1Click:Connect(function()
			if not _abierto or _totalPasos == 0 then return end
			if _pasoActual < _totalPasos then
				_pasoActual = _pasoActual + 1
				aplicarPaso(_pasos[_pasoActual])
			end
		end)
	end

	-- Botón Anterior
	local btnAnt = buscar(_overlay, "BtnAnterior")
	if btnAnt then
		btnAnt.MouseButton1Click:Connect(function()
			if not _abierto or _totalPasos == 0 then return end
			if _pasoActual > 1 then
				_pasoActual = _pasoActual - 1
				aplicarPaso(_pasos[_pasoActual])
			end
		end)
	end

	-- Refrescar cuando el jugador cambie de zona mientras el panel está abierto
	jugador:GetAttributeChangedSignal("ZonaActual"):Connect(function()
		if not _abierto then return end
		local zona = jugador:GetAttribute("ZonaActual") or ""
		if zona == "" then
			_matrizData = nil
			_pasos      = {}
			_totalPasos = 0
			_pasoActual = 0
			if _worldModel then _worldModel:ClearAllChildren() end
			_nodoParts  = {}
			_aristaParts = {}
			mostrarMensajeDesc("Entra en una zona para ver el análisis.")
			actualizarScrollEstado(nil)
			return
		end
		mostrarMensajeDesc("Cargando zona: " .. zona .. "…")
		local fn = getMatrixFunc()
		if not fn then return end
		task.spawn(function()
			local ok, datos = pcall(function() return fn:InvokeServer(zona) end)
			if ok and datos and not datos.SinZona and #datos.Headers > 0 then
				_matrizData  = datos
				_adyacencias = buildAdyacencias(datos)
				construirViewport()
				ejecutarAlgoritmo()
			else
				mostrarMensajeDesc("Sin datos para zona: " .. zona)
			end
		end)
	end)

	-- AnalisisBtn en SelectorModos (mismo patrón que ModuloMatriz con MatrizBtn)
	local selectorModos = hudGui:FindFirstChild("SelectorModos", true)
	if selectorModos then
		local analisisBtn = selectorModos:FindFirstChild("AnalisisBtn")
		if analisisBtn then
			analisisBtn.MouseButton1Click:Connect(function()
				if _abierto then
					ModuloAnalisis.cerrar()
				else
					ModuloAnalisis.abrir()
				end
			end)
		else
			warn("[ModuloAnalisis] AnalisisBtn no encontrado en SelectorModos")
		end
	else
		warn("[ModuloAnalisis] SelectorModos no encontrado")
	end

	-- Estado inicial de pills y pseudocódigo
	actualizarPills(_algoActual)
	reconstruirPseudocodigo(_algoActual)

	print("[ModuloAnalisis] Inicializado ✅")
end

function ModuloAnalisis.configurarNivel(nivelModelParam, nivelIDParam, _configNivel)
	_nivelModel = nivelModelParam
	_nivelID    = nivelIDParam
	-- No se abre automáticamente; el jugador lo activa manualmente.
end

function ModuloAnalisis.abrir()
	if not _overlay then
		warn("[ModuloAnalisis] Overlay no disponible — ¿inicializar() fue llamado?")
		return
	end

	_abierto         = true
	_overlay.Visible = true

	local zona = jugador:GetAttribute("ZonaActual") or ""
	if zona == "" then
		mostrarMensajeDesc("Entra en una zona para ver el análisis de su grafo.")
		actualizarScrollEstado(nil)
		print("[ModuloAnalisis] Abierto (sin zona activa)")
		return
	end

	mostrarMensajeDesc("Cargando datos del grafo…")

	local fn = getMatrixFunc()
	if not fn then
		mostrarMensajeDesc("Error: GetAdjacencyMatrix no disponible.")
		return
	end

	task.spawn(function()
		local ok, datos = pcall(function() return fn:InvokeServer(zona) end)
		if ok and datos and not datos.SinZona and #datos.Headers > 0 then
			_matrizData  = datos
			_adyacencias = buildAdyacencias(datos)
			construirViewport()
			seleccionarAlgo(_algoActual)
		else
			_matrizData = nil
			mostrarMensajeDesc("Sin datos para la zona \"" .. zona .. "\".")
			actualizarScrollEstado(nil)
		end
	end)

	print("[ModuloAnalisis] Abierto — zona:", zona)
end

function ModuloAnalisis.cerrar()
	_abierto = false
	if _overlay then _overlay.Visible = false end
	print("[ModuloAnalisis] Cerrado")
end

function ModuloAnalisis.limpiar()
	ModuloAnalisis.cerrar()
	_matrizData   = nil
	_adyacencias  = {}
	_pasos        = {}
	_pasoActual   = 0
	_totalPasos   = 0
	_nivelModel   = nil
	_nivelID      = nil
	_nodoParts    = {}
	_aristaParts  = {}
	if _worldModel then _worldModel:ClearAllChildren() end
	print("[ModuloAnalisis] Limpiado")
end

function ModuloAnalisis.estaAbierto()
	return _abierto
end

return ModuloAnalisis
