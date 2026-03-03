-- StarterPlayerScripts/HUD/ModulosHUD/ModuloMatriz.lua
-- Módulo cliente: visualiza la Matriz de Adyacencia en PanelMatrizAdyacencia.
-- Tipo: ModuleScript
--
-- GUI esperada en GUIExploradorV2:
--   PanelMatrizAdyacencia (Frame)
--     MatrizHeader (Frame)
--       TituloMatriz    (TextLabel)
--       BtnCerrarMatriz (TextButton)
--     MarcoInfoNodo (Frame)
--       FilaNodo    > Valor (TextLabel)
--       FilaGrado   > Valor
--       FilaEntrada > Valor
--       FilaSalida  > Valor
--     CuadriculaMatriz (ScrollingFrame)
--   SelectorModos
--     MatrizBtn (TextButton)   ← abre la matriz
--     VisualBtn (TextButton)   ← cierra y vuelve al minimapa
--   ContenedorMiniMapa (Frame) ← se oculta al abrir la matriz
--
-- API pública:
--   ModuloMatriz.inicializar(hudGui)
--   ModuloMatriz.configurarNivel(nivelActual, nivelID, configNivel)
--   ModuloMatriz.limpiar()

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")

local jugador    = Players.LocalPlayer
local LevelsConfig = require(RS:WaitForChild("Config"):WaitForChild("LevelsConfig"))

local ModuloMatriz = {}

-- ════════════════════════════════════════════════════════════════
-- ESTADO
-- ════════════════════════════════════════════════════════════════
local _hudGui        = nil
local _matrizData    = nil   -- { Headers={}, Matrix={{}}, NombresNodos={} }
local _nodoSelecIdx  = nil   -- índice (1-based) del nodo resaltado
local _zonaActual    = nil   -- última zona solicitada
local _getMatrixFunc = nil   -- RemoteFunction (lazy)
local _inicializado  = false
local _refreshPending = false

-- ════════════════════════════════════════════════════════════════
-- COLORES
-- ════════════════════════════════════════════════════════════════
local C = {
	Header    = Color3.fromRGB(52,  152, 219),
	CeldaUno  = Color3.fromRGB(46,  204, 113),
	CeldaCero = Color3.fromRGB(50,   50,  50),
	Diag      = Color3.fromRGB(30,   30,  30),
	Esquina   = Color3.fromRGB(60,   60,  60),
	Selec     = Color3.fromRGB(255, 220,   0),
	SelecCero = Color3.fromRGB(140, 110,   0),
}

-- ════════════════════════════════════════════════════════════════
-- HELPERS VISUALES
-- ════════════════════════════════════════════════════════════════
local function addCorner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 4)
	c.Parent = parent
end

local function addStroke(parent)
	local s = Instance.new("UIStroke")
	s.Thickness = 1
	s.Color = Color3.fromRGB(70, 70, 70)
	s.Transparency = 0.5
	s.Parent = parent
end

-- ════════════════════════════════════════════════════════════════
-- GETTERS GUI
-- ════════════════════════════════════════════════════════════════
local function getPanel()
	return _hudGui and _hudGui:FindFirstChild("PanelMatrizAdyacencia", true)
end

local function getScroll()
	local p = getPanel()
	return p and p:FindFirstChild("CuadriculaMatriz")
end

local function isVisible()
	local p = getPanel()
	return p ~= nil and p.Visible
end

-- Toggle del contenedor del minimapa (ContenedorMiniMapa)
local function setMinimapVisible(visible)
	if not _hudGui then return end
	local cont = _hudGui:FindFirstChild("ContenedorMiniMapa", true)
	if cont then cont.Visible = visible end
end

-- ════════════════════════════════════════════════════════════════
-- ALIAS (nombre legible del nodo)
-- Prioridad: NombresNodos del servidor → LevelsConfig cliente → nombre interno
-- ════════════════════════════════════════════════════════════════
local function getAlias(nodeName)
	if not nodeName then return "--" end
	-- 1. Desde datos de la matriz (enviados por el servidor)
	if _matrizData and _matrizData.NombresNodos then
		local alias = _matrizData.NombresNodos[nodeName]
		if alias and alias ~= "" then return alias end
	end
	-- 2. Fallback: LevelsConfig cargado localmente
	local nivelID = jugador:GetAttribute("CurrentLevelID") or 0
	local cfg = LevelsConfig[nivelID]
	if cfg and cfg.NombresNodos then
		local alias = cfg.NombresNodos[nodeName]
		if alias and alias ~= "" then return alias end
	end
	return nodeName
end

local function getHeaderIdx(nodeName)
	if not _matrizData then return nil end
	for i, h in ipairs(_matrizData.Headers) do
		if h == nodeName then return i end
	end
	return nil
end

-- ════════════════════════════════════════════════════════════════
-- INFORMACIÓN DE NODO (MarcoInfoNodo)
-- ════════════════════════════════════════════════════════════════
local function actualizarInfoNodo(nombreInterno, gTotal, gEntrada, gSalida)
	local panel = getPanel()
	if not panel then return end
	local marco = panel:FindFirstChild("MarcoInfoNodo")
	if not marco then return end

	local alias = nombreInterno and getAlias(nombreInterno) or "--"

	local function setValor(frameName, text)
		local frame = marco:FindFirstChild(frameName)
		local valor = frame and frame:FindFirstChild("Valor")
		if valor then valor.Text = text end
	end

	setValor("FilaNodo",    alias)
	setValor("FilaGrado",   tostring(gTotal   or 0))
	setValor("FilaEntrada", tostring(gEntrada or 0))
	setValor("FilaSalida",  tostring(gSalida  or 0))
end

-- ════════════════════════════════════════════════════════════════
-- CÁLCULO DE GRADOS
-- ════════════════════════════════════════════════════════════════
local function calcularGrados(matrix, idx, n)
	local gSalida, gEntrada = 0, 0
	for j = 1, n do
		if matrix[idx] and (matrix[idx][j] or 0) > 0 then gSalida  = gSalida  + 1 end
		if matrix[j]   and (matrix[j][idx]  or 0) > 0 then gEntrada = gEntrada + 1 end
	end
	local esDigrafo = false
	for r = 1, n do
		for c = 1, n do
			if matrix[r] and matrix[c]
				and (matrix[r][c] or 0) ~= (matrix[c][r] or 0) then
				esDigrafo = true; break
			end
		end
		if esDigrafo then break end
	end
	local gTotal = esDigrafo and (gEntrada + gSalida) or gEntrada
	return gTotal, gEntrada, gSalida
end

-- ════════════════════════════════════════════════════════════════
-- RESALTAR FILA + COLUMNA DEL NODO SELECCIONADO
-- ════════════════════════════════════════════════════════════════
local function resaltarEnMatriz(idx)
	local scroll = getScroll()
	if not scroll or not _matrizData then return end

	for _, child in ipairs(scroll:GetChildren()) do
		if not (child:IsA("TextLabel") or child:IsA("TextButton")) then continue end

		local cx, cy = child.Name:match("Cell_(%d+)_(%d+)")
		cx = tonumber(cx); cy = tonumber(cy)
		if not cx or not cy then continue end

		local esDiag    = (cx == cy and cx > 0)
		local esEsquina = (cx == 0 and cy == 0)
		local esHdrCol  = (cy == 0 and cx > 0)
		local esHdrFil  = (cx == 0 and cy > 0)
		local esDato    = (cx > 0 and cy > 0)

		local val = 0
		if esDato then
			val = (_matrizData.Matrix[cy] and _matrizData.Matrix[cy][cx]) or 0
		end

		if esEsquina then
			-- sin cambios
		elseif idx == nil then
			if esHdrCol or esHdrFil then child.BackgroundColor3 = C.Header
			elseif esDiag             then child.BackgroundColor3 = C.Diag
			elseif esDato             then child.BackgroundColor3 = val > 0 and C.CeldaUno or C.CeldaCero
			end
		else
			local esHdrSelec  = (esHdrCol and cx == idx) or (esHdrFil and cy == idx)
			local esFilaSelec = esDato and cy == idx and not esDiag
			local esColSelec  = esDato and cx == idx and not esDiag

			if esHdrSelec then
				child.BackgroundColor3 = C.Selec
			elseif esDiag then
				child.BackgroundColor3 = C.Diag
			elseif esFilaSelec or esColSelec then
				child.BackgroundColor3 = val > 0 and C.Selec or C.SelecCero
			elseif esHdrCol or esHdrFil then
				child.BackgroundColor3 = C.Header
			elseif esDato then
				child.BackgroundColor3 = val > 0 and C.CeldaUno or C.CeldaCero
			end
		end
	end
end

-- ════════════════════════════════════════════════════════════════
-- SELECCIONAR NODO (actualiza info + resaltado en matriz)
-- ════════════════════════════════════════════════════════════════
local function seleccionarNodo(nodeName)
	if not _matrizData then return end

	local idx = getHeaderIdx(nodeName)
	if not idx then
		_nodoSelecIdx = nil
		actualizarInfoNodo(nil, 0, 0, 0)
		resaltarEnMatriz(nil)
		return
	end

	_nodoSelecIdx = idx
	local n = #_matrizData.Headers
	local gT, gE, gS = calcularGrados(_matrizData.Matrix, idx, n)
	actualizarInfoNodo(nodeName, gT, gE, gS)
	resaltarEnMatriz(idx)
end

-- ════════════════════════════════════════════════════════════════
-- RENDERIZAR MATRIZ — tamaño de celda ADAPTATIVO
-- Las celdas llenan el espacio disponible del ScrollingFrame.
-- Si hay demasiados nodos, se activa el scroll (mínimo 14px/celda).
-- ════════════════════════════════════════════════════════════════
local function renderizarMatriz(data)
	local scroll = getScroll()
	if not scroll then warn("[ModuloMatriz] CuadriculaMatriz no encontrada"); return end

	-- Limpiar celdas previas
	for _, child in ipairs(scroll:GetChildren()) do
		if not child:IsA("UIListLayout") then child:Destroy() end
	end

	local headers = data.Headers
	local matrix  = data.Matrix
	local n       = #headers

	if n == 0 then
		local lbl = Instance.new("TextLabel")
		lbl.Size  = UDim2.new(1, 0, 0, 40)
		lbl.BackgroundTransparency = 1
		lbl.Text  = "Sin nodos en esta zona"
		lbl.TextColor3 = Color3.fromRGB(176, 190, 197)
		lbl.Font  = Enum.Font.Gotham
		lbl.TextSize = 13
		lbl.Parent = scroll
		return
	end

	-- ── Calcular tamaño adaptativo de celda ─────────────────────
	-- AbsoluteSize es válido porque el panel ya está visible.
	local padding = 3
	local sX = scroll.AbsoluteSize.X
	local sY = scroll.AbsoluteSize.Y
	if sX < 10 then sX = 300 end   -- fallback si aún no está renderizado
	if sY < 10 then sY = 300 end

	-- Cuánto espacio queda por celda si distribuimos (n+1) columnas/filas
	local fitX = math.floor((sX - padding) / (n + 1)) - padding
	local fitY = math.floor((sY - padding) / (n + 1)) - padding
	local maxFit  = math.min(fitX, fitY)
	local cellSize = math.max(14, math.min(maxFit, 60))  -- clamp: 14..60 px

	local paso  = cellSize + padding
	local total = (n + 1) * paso + padding

	scroll.CanvasSize         = UDim2.new(0, total, 0, total)
	scroll.ScrollingEnabled   = true
	scroll.ScrollBarThickness = total > sX and 6 or 0  -- mostrar scroll solo si necesario

	-- Celda (0,0) — esquina vacía
	local esquina = Instance.new("TextLabel")
	esquina.Name               = "Cell_0_0"
	esquina.Size               = UDim2.new(0, cellSize, 0, cellSize)
	esquina.Position           = UDim2.new(0, 0, 0, 0)
	esquina.BackgroundColor3   = C.Esquina
	esquina.BackgroundTransparency = 0
	esquina.BorderSizePixel    = 0
	esquina.Text               = ""
	esquina.Parent             = scroll
	addCorner(esquina, 4)

	-- Headers de columna (row=0, col=1..n)
	for i, hNombre in ipairs(headers) do
		local alias = getAlias(hNombre)
		local btn   = Instance.new("TextButton")
		btn.Name    = string.format("Cell_%d_0", i)
		btn.Size    = UDim2.new(0, cellSize, 0, cellSize)
		btn.Position = UDim2.new(0, i * paso, 0, 0)
		btn.BackgroundColor3 = C.Header
		btn.BackgroundTransparency = 0
		btn.BorderSizePixel = 0
		btn.Text    = alias
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Font    = Enum.Font.GothamBold
		btn.TextSize = 11; btn.TextScaled = true
		btn.AutoButtonColor = false
		btn.Parent  = scroll
		addCorner(btn, 4); addStroke(btn)

		local cn = hNombre
		btn.MouseButton1Click:Connect(function() seleccionarNodo(cn) end)
	end

	-- Filas 1..n
	for rowIdx, rowNombre in ipairs(headers) do
		local alias = getAlias(rowNombre)

		-- Header de fila (col=0)
		local btnFila = Instance.new("TextButton")
		btnFila.Name  = string.format("Cell_0_%d", rowIdx)
		btnFila.Size  = UDim2.new(0, cellSize, 0, cellSize)
		btnFila.Position = UDim2.new(0, 0, 0, rowIdx * paso)
		btnFila.BackgroundColor3 = C.Header
		btnFila.BackgroundTransparency = 0
		btnFila.BorderSizePixel = 0
		btnFila.Text  = alias
		btnFila.TextColor3 = Color3.new(1, 1, 1)
		btnFila.Font  = Enum.Font.GothamBold
		btnFila.TextSize = 11; btnFila.TextScaled = true
		btnFila.AutoButtonColor = false
		btnFila.Parent = scroll
		addCorner(btnFila, 4); addStroke(btnFila)

		local rn = rowNombre
		btnFila.MouseButton1Click:Connect(function() seleccionarNodo(rn) end)

		-- Celdas de datos (col=1..n)
		for colIdx = 1, n do
			local rawVal = (matrix[rowIdx] and matrix[rowIdx][colIdx]) or 0
			local val    = rawVal > 0 and 1 or 0
			local esDiag = (rowIdx == colIdx)
			local color  = esDiag and C.Diag or (val > 0 and C.CeldaUno or C.CeldaCero)
			local texto  = esDiag and "—" or tostring(val)

			local cell = Instance.new("TextLabel")
			cell.Name  = string.format("Cell_%d_%d", colIdx, rowIdx)
			cell.Size  = UDim2.new(0, cellSize, 0, cellSize)
			cell.Position = UDim2.new(0, colIdx * paso, 0, rowIdx * paso)
			cell.BackgroundColor3 = color
			cell.BackgroundTransparency = 0
			cell.BorderSizePixel = 0
			cell.Text  = texto
			cell.TextColor3 = Color3.new(1, 1, 1)
			cell.Font  = Enum.Font.Code
			cell.TextSize = 14; cell.TextScaled = true
			cell.Parent = scroll
			addCorner(cell, 4); addStroke(cell)
		end
	end

	-- Reaplicar resaltado previo
	if _nodoSelecIdx then resaltarEnMatriz(_nodoSelecIdx) end

	print(string.format("[ModuloMatriz] %dx%d (celda=%dpx)", n, n, cellSize))
end

-- ════════════════════════════════════════════════════════════════
-- SOLICITAR MATRIZ AL SERVIDOR
-- ════════════════════════════════════════════════════════════════
local function solicitarMatriz(zonaID)
	if not _getMatrixFunc then
		local ok, remote = pcall(function()
			return RS:WaitForChild("EventosGrafosV3", 10)
			          :WaitForChild("Remotos", 5)
			          :WaitForChild("GetAdjacencyMatrix", 5)
		end)
		if ok and remote then
			_getMatrixFunc = remote
		else
			warn("[ModuloMatriz] GetAdjacencyMatrix no encontrada"); return
		end
	end

	-- Actualizar título
	local panel = getPanel()
	if panel then
		local header = panel:FindFirstChild("MatrizHeader")
		local titulo = header and header:FindFirstChild("TituloMatriz")
		if titulo then
			titulo.Text = "MATRIZ DE ADYACENCIA" .. (zonaID and (" — " .. zonaID) or "")
		end
	end

	actualizarInfoNodo(nil, 0, 0, 0)

	task.spawn(function()
		local ok, resultado = pcall(function()
			return _getMatrixFunc:InvokeServer(zonaID)
		end)

		if ok and resultado and resultado.Headers then
			-- Preservar selección previa
			local nombrePrevio = nil
			if _nodoSelecIdx and _matrizData and _matrizData.Headers then
				nombrePrevio = _matrizData.Headers[_nodoSelecIdx]
			end

			_matrizData = resultado
			_zonaActual = zonaID
			renderizarMatriz(resultado)

			if nombrePrevio then
				local nuevoIdx = getHeaderIdx(nombrePrevio)
				if nuevoIdx then
					_nodoSelecIdx = nuevoIdx
					local n = #resultado.Headers
					local gT, gE, gS = calcularGrados(resultado.Matrix, nuevoIdx, n)
					actualizarInfoNodo(nombrePrevio, gT, gE, gS)
					resaltarEnMatriz(nuevoIdx)
				else
					_nodoSelecIdx = nil
					actualizarInfoNodo(nil, 0, 0, 0)
				end
			end
		else
			warn("[ModuloMatriz] Error del servidor: " .. tostring(resultado))
			_matrizData = nil
			local scroll = getScroll()
			if scroll then
				for _, c in ipairs(scroll:GetChildren()) do
					if not c:IsA("UIListLayout") then c:Destroy() end
				end
				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(1, 0, 0, 40)
				lbl.BackgroundTransparency = 1
				lbl.Text = "Sin datos para esta zona"
				lbl.TextColor3 = Color3.fromRGB(176, 190, 197)
				lbl.Font = Enum.Font.Gotham; lbl.TextSize = 13
				lbl.Parent = scroll
			end
		end
	end)
end

-- Debounce para refrescos automáticos
local function scheduleRefresh()
	if _refreshPending then return end
	_refreshPending = true
	task.delay(0.3, function()
		_refreshPending = false
		if isVisible() then
			solicitarMatriz(_zonaActual)
		end
	end)
end

-- ════════════════════════════════════════════════════════════════
-- ACTIVAR / DESACTIVAR
-- ════════════════════════════════════════════════════════════════
local function activar()
	local panel = getPanel()
	if not panel then return end
	panel.Visible = true
	setMinimapVisible(false)   -- ← ocultar minimapa al abrir la matriz

	_nodoSelecIdx = nil
	actualizarInfoNodo(nil, 0, 0, 0)

	local zona = jugador:GetAttribute("ZonaActual") or ""
	solicitarMatriz(zona ~= "" and zona or nil)
	print("[ModuloMatriz] Activado")
end

local function desactivar()
	local panel = getPanel()
	if panel then panel.Visible = false end
	setMinimapVisible(true)    -- ← restaurar minimapa al cerrar la matriz

	_nodoSelecIdx = nil
	_matrizData   = nil
	print("[ModuloMatriz] Desactivado")
end

-- ════════════════════════════════════════════════════════════════
-- API PÚBLICA
-- ════════════════════════════════════════════════════════════════

function ModuloMatriz.inicializar(hudGui)
	if _inicializado then return end
	_inicializado = true
	_hudGui = hudGui

	local panel = getPanel()
	if panel then panel.Visible = false end

	-- Botones SelectorModos
	local selectorModos = hudGui:FindFirstChild("SelectorModos", true)
	if selectorModos then
		local matrizBtn = selectorModos:FindFirstChild("MatrizBtn")
		local visualBtn = selectorModos:FindFirstChild("VisualBtn")
		if matrizBtn then matrizBtn.MouseButton1Click:Connect(activar)  end
		if visualBtn then visualBtn.MouseButton1Click:Connect(desactivar) end
	else
		warn("[ModuloMatriz] SelectorModos no encontrado")
	end

	-- Botón cerrar del panel
	if panel then
		local header    = panel:FindFirstChild("MatrizHeader")
		local btnCerrar = header and header:FindFirstChild("BtnCerrarMatriz")
		if btnCerrar then btnCerrar.MouseButton1Click:Connect(desactivar) end
	end

	-- Conexión a eventos remotos
	local ok, remotos = pcall(function()
		return RS:WaitForChild("EventosGrafosV3", 10):WaitForChild("Remotos", 5)
	end)

	if ok and remotos then
		-- NotificarSeleccionNodo: sincronizar selección 3D ↔ matriz
		local notifyEvent = remotos:FindFirstChild("NotificarSeleccionNodo")
		if notifyEvent then
			notifyEvent.OnClientEvent:Connect(function(tipo, arg1)
				if not isVisible() then return end

				if tipo == "NodoSeleccionado" then
					-- arg1 puede ser string (nombre) o Instance (Model del nodo)
					local nombre = type(arg1) == "string" and arg1
					           or (typeof(arg1) == "Instance" and arg1.Name)
					           or nil
					if nombre then seleccionarNodo(nombre) end

				elseif tipo == "CableDesconectado" or tipo == "ConexionCompletada" then
					-- Un cable fue creado o eliminado → refrescar matriz
					scheduleRefresh()

				elseif tipo == "SeleccionCancelada" then
					_nodoSelecIdx = nil
					actualizarInfoNodo(nil, 0, 0, 0)
					resaltarEnMatriz(nil)
				end
			end)
			print("[ModuloMatriz] Escucha NotificarSeleccionNodo")
		end

		-- ActualizarEstadoConexiones: cobertura adicional (ConectarCables lo dispara
		-- tanto al conectar como al desconectar desde cualquier ruta de código)
		local actualizarConex = remotos:FindFirstChild("ActualizarEstadoConexiones")
		if actualizarConex then
			actualizarConex.OnClientEvent:Connect(function()
				scheduleRefresh()
			end)
			print("[ModuloMatriz] Escucha ActualizarEstadoConexiones")
		end
	else
		warn("[ModuloMatriz] No se encontraron los Remotos de EventosGrafosV3")
	end

	-- Cambio de zona del jugador → refrescar si está abierto
	jugador:GetAttributeChangedSignal("ZonaActual"):Connect(function()
		if not isVisible() then return end
		local zona = jugador:GetAttribute("ZonaActual") or ""
		solicitarMatriz(zona ~= "" and zona or nil)
	end)

	print("[ModuloMatriz] Inicializado")
end

function ModuloMatriz.configurarNivel(_nivelActual, _nivelID, _configNivel)
	if isVisible() then scheduleRefresh() end
end

-- API pública para que módulos externos (e.g. ModuloMapa via ControladorHUD)
-- soliciten un refresco de la matriz. Solo actúa si el panel está visible.
function ModuloMatriz.refrescar()
	if isVisible() then scheduleRefresh() end
end

-- Resalta el nodo con ese nombre en la matriz (llamado desde ModuloMapa en
-- el primer click del modo mapa). No hace nada si el panel no está visible.
function ModuloMatriz.seleccionarNodoExterno(nombre)
	if not isVisible() then return end
	seleccionarNodo(nombre)
end

-- Limpia el resaltado de selección (llamado desde ModuloMapa al cancelar
-- la selección en modo mapa). No hace nada si el panel no está visible.
function ModuloMatriz.cancelarSeleccion()
	if not isVisible() then return end
	_nodoSelecIdx = nil
	actualizarInfoNodo(nil, 0, 0, 0)
	resaltarEnMatriz(nil)
end

function ModuloMatriz.limpiar()
	desactivar()
	print("[ModuloMatriz] Limpiado")
end

return ModuloMatriz
