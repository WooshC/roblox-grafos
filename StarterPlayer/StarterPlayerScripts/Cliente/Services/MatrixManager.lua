-- ================================================================
-- MatrixManager.lua (v3)
-- ✅ FIX: Desbordamiento — cellSize adaptativo + CanvasSize correcto
-- ✅ FIX: Tiempo real — escucha ActualizarUI y ArbolGenerado
-- ✅ FIX: Nodo 3D seleccionado → resalta en matriz + muestra grados
--         Escucha cableDragEvent "Start" para saber qué nodo clickeó el jugador
-- ================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local player            = Players.LocalPlayer

local MatrixManager = {}

-- ================================================================
-- ESTADO
-- ================================================================
local gui           = nil
local globalState   = nil
local LevelsConfig  = nil
local getMatrixFunc = nil
local matrizData    = nil   -- { Headers = {}, Matrix = {{}} }
local zonaActual    = nil
local nodoSelecIdx  = nil   -- índice (1-based) del nodo actualmente resaltado

-- ================================================================
-- ALIAS: nombre legible desde LevelsConfig
-- ================================================================
local function getAlias(nodeName)
	if not LevelsConfig or not nodeName then return nodeName or "--" end
	local nivelID = player:GetAttribute("CurrentLevelID") or 0
	local config  = LevelsConfig[nivelID]
	if not config then return nodeName end

	if config.Nodos and config.Nodos[nodeName] then
		local alias = config.Nodos[nodeName].Alias
		if alias and alias ~= "" then return alias end
	end
	if config.NombresPostes and config.NombresPostes[nodeName] then
		return config.NombresPostes[nodeName]
	end
	return nodeName
end

-- Dado un nombre interno de nodo, retorna su índice en matrizData.Headers
local function getHeaderIdx(nodeName)
	if not matrizData then return nil end
	for i, h in ipairs(matrizData.Headers) do
		if h == nodeName then return i end
	end
	return nil
end

-- ================================================================
-- COLORES
-- ================================================================
local C = {
	Header    = Color3.fromRGB(52,  152, 219),
	CeldaUno  = Color3.fromRGB(46,  204, 113),
	CeldaCero = Color3.fromRGB(50,   50,  50),
	Diag      = Color3.fromRGB(30,   30,  30),
	Esquina   = Color3.fromRGB(60,   60,  60),
	Selec     = Color3.fromRGB(255, 220,   0),   -- Amarillo seleccionado
	SelecCero = Color3.fromRGB(140, 110,   0),   -- Amarillo oscuro (adyacente sin conexión)
}

-- ================================================================
-- HELPERS UI
-- ================================================================
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

-- ================================================================
-- PANEL / SCROLL helpers
-- ================================================================
local function getPanel()
	return gui and gui:FindFirstChild("PanelMatrizAdyacencia", true)
end

local function getScroll()
	local p = getPanel()
	return p and p:FindFirstChild("CuadriculaMatriz", true)
end

-- ================================================================
-- ACTUALIZAR INFO NODO (MarcoInfoNodo)
-- ================================================================
local function actualizarInfoNodo(nombreInterno, gTotal, gEntrada, gSalida)
	local panel = getPanel()
	if not panel then return end
	local marco = panel:FindFirstChild("MarcoInfoNodo", true)
	if not marco then return end

	local alias = nombreInterno and getAlias(nombreInterno) or "--"

	local lblNombre = marco:FindFirstChild("NombreNodo")
	if lblNombre then lblNombre.Text = "Nodo: " .. alias end

	local lblStats = marco:FindFirstChild("EstadisticasNodo")
	if lblStats then
		lblStats.Text = string.format(
			"Grado: %d  |  Entrada: %d  |  Salida: %d",
			gTotal or 0, gEntrada or 0, gSalida or 0
		)
	end
end

-- ================================================================
-- CALCULAR GRADOS
-- ================================================================
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

-- ================================================================
-- RESALTAR fila + columna del nodo seleccionado (solo visual)
-- ================================================================
local function resaltarEnMatriz(idx)
	local scroll = getScroll()
	if not scroll or not matrizData then return end

	local n = #matrizData.Headers

	for _, child in ipairs(scroll:GetChildren()) do
		if not (child:IsA("TextLabel") or child:IsA("TextButton")) then continue end

		local cx, cy = child.Name:match("Cell_(%d+)_(%d+)")
		cx = tonumber(cx); cy = tonumber(cy)
		if not cx or not cy then continue end

		local esDiag   = (cx == cy and cx > 0)
		local esEsquina = (cx == 0 and cy == 0)
		local esHdrCol = (cy == 0 and cx > 0)   -- header de columna
		local esHdrFil = (cx == 0 and cy > 0)   -- header de fila
		local esDato   = (cx > 0 and cy > 0)

		local val = 0
		if esDato then
			val = (matrizData.Matrix[cy] and matrizData.Matrix[cy][cx]) or 0
		end

		if esEsquina then
			-- No cambiar
		elseif idx == nil then
			-- Sin selección: restaurar todo
			if esHdrCol or esHdrFil then
				child.BackgroundColor3 = C.Header
			elseif esDiag then
				child.BackgroundColor3 = C.Diag
			elseif esDato then
				child.BackgroundColor3 = val > 0 and C.CeldaUno or C.CeldaCero
			end
		else
			-- Con selección
			local esHdrSelec  = (esHdrCol and cx == idx) or (esHdrFil and cy == idx)
			local esFilaSelec = (esDato and cy == idx and not esDiag)
			local esColSelec  = (esDato and cx == idx and not esDiag)

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

-- ================================================================
-- SELECCIONAR NODO (desde click en mundo 3D o en header de matriz)
-- ================================================================
local function seleccionarNodo(nodeName)
	if not matrizData then return end

	local idx = getHeaderIdx(nodeName)
	if not idx then
		-- Nodo no está en la zona actual, limpiar
		nodoSelecIdx = nil
		actualizarInfoNodo(nil, 0, 0, 0)
		resaltarEnMatriz(nil)
		return
	end

	nodoSelecIdx = idx
	local n = #matrizData.Headers
	local gT, gE, gS = calcularGrados(matrizData.Matrix, idx, n)
	actualizarInfoNodo(nodeName, gT, gE, gS)
	resaltarEnMatriz(idx)
end

-- ================================================================
-- RENDERIZAR MATRIZ EN CuadriculaMatriz
-- ================================================================
local function renderizarMatriz(data)
	local panel = getPanel()
	if not panel then warn("❌ MatrixManager: PanelMatrizAdyacencia no encontrado"); return end

	local scroll = getScroll()
	if not scroll then warn("❌ MatrixManager: CuadriculaMatriz no encontrado"); return end

	-- Limpiar todo excepto UIListLayout
	for _, child in ipairs(scroll:GetChildren()) do
		if not child:IsA("UIListLayout") then child:Destroy() end
	end

	local headers = data.Headers
	local matrix  = data.Matrix
	local n       = #headers

	if n == 0 then
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 0, 40)
		lbl.BackgroundTransparency = 1
		lbl.Text = "Sin nodos en esta zona"
		lbl.TextColor3 = Color3.fromRGB(176, 190, 197)
		lbl.Font = Enum.Font.Gotham; lbl.TextSize = 13
		lbl.Parent = scroll
		return
	end

	-- ── Tamaño configurable mínimo + scroll ──────────────────────────────
	-- Celda configurable (mínimo 10px). Si la matriz no cabe, el ScrollingFrame hace scroll.
	local cellSize = math.max(10, matrizData.CellSize or 48)  -- Configurable, mínimo 10px
	local padding  = 3
	local paso     = cellSize + padding
	local total    = (n + 1) * paso + padding

	scroll.CanvasSize        = UDim2.new(0, total, 0, total)
	scroll.ScrollingEnabled  = true
	scroll.ScrollBarThickness = 6

	-- ── Esquina vacía (0,0) ─────────────────────────────────────
	local esquina = Instance.new("TextLabel")
	esquina.Name = "Cell_0_0"
	esquina.Size = UDim2.new(0, cellSize, 0, cellSize)
	esquina.Position = UDim2.new(0, 0, 0, 0)
	esquina.BackgroundColor3 = C.Esquina
	esquina.BackgroundTransparency = 0
	esquina.BorderSizePixel = 0
	esquina.Text = ""
	esquina.Parent = scroll
	addCorner(esquina, 4)

	-- ── Headers de columna (row=0, col=1..n) ────────────────────
	for i, hNombre in ipairs(headers) do
		local alias = getAlias(hNombre)
		local btn   = Instance.new("TextButton")
		btn.Name    = string.format("Cell_%d_0", i)
		btn.Size    = UDim2.new(0, cellSize, 0, cellSize)
		btn.Position= UDim2.new(0, i * paso, 0, 0)
		btn.BackgroundColor3 = C.Header
		btn.BackgroundTransparency = 0
		btn.BorderSizePixel = 0
		btn.Text    = alias
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Font    = Enum.Font.GothamBold
		btn.TextSize= 11; btn.TextScaled = true
		btn.AutoButtonColor = false
		btn.Parent  = scroll
		addCorner(btn, 4); addStroke(btn)

		local cn = hNombre
		btn.MouseButton1Click:Connect(function()
			seleccionarNodo(cn)
		end)
	end

	-- ── Filas 1..n ───────────────────────────────────────────────
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
		btnFila.MouseButton1Click:Connect(function()
			seleccionarNodo(rn)
		end)

		-- Celdas de datos (solo mostramos 0 o 1, no pesos)
		for colIdx = 1, n do
			local rawVal = (matrix[rowIdx] and matrix[rowIdx][colIdx]) or 0
			local val    = rawVal > 0 and 1 or 0   -- forzar binario
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

	-- Reaplicar resaltado si había un nodo seleccionado
	if nodoSelecIdx then
		resaltarEnMatriz(nodoSelecIdx)
	end

	print(string.format("📊 MatrixManager: Matriz %dx%d renderizada (celda=%dpx)", n, n, cellSize))
end

-- ================================================================
-- SOLICITAR MATRIZ AL SERVIDOR
-- ================================================================
function MatrixManager.solicitarMatriz(zonaID)
	if not getMatrixFunc then
		local ok, remote = pcall(function()
			return ReplicatedStorage
				:WaitForChild("Events", 5)
				:WaitForChild("Remotes", 5)
				:WaitForChild("GetAdjacencyMatrix", 5)
		end)
		if ok and remote then
			getMatrixFunc = remote
		else
			warn("❌ MatrixManager: GetAdjacencyMatrix no encontrada"); return
		end
	end

	-- Actualizar título
	local panel = getPanel()
	if panel then
		local t = panel:FindFirstChild("Titulo")
		if t then
			t.Text = "📋 MATRIZ DE ADYACENCIA" .. (zonaID and (" — " .. zonaID) or "")
		end
	end

	-- Limpiar info nodo mientras carga
	actualizarInfoNodo(nil, 0, 0, 0)

	task.spawn(function()
		local ok, resultado = pcall(function()
			return getMatrixFunc:InvokeServer(zonaID)
		end)

		if ok and resultado and resultado.Headers then
			-- Guardar nombre del nodo seleccionado antes de reemplazar datos
			local nombrePrevio = nil
			if nodoSelecIdx and matrizData and matrizData.Headers then
				nombrePrevio = matrizData.Headers[nodoSelecIdx]
			end
			matrizData = resultado
			zonaActual = zonaID
			renderizarMatriz(resultado)
			-- Reaplicar selección si el nodo sigue en la nueva zona/datos
			if nombrePrevio then
				local nuevoIdx = nil
				for i, h in ipairs(resultado.Headers) do
					if h == nombrePrevio then nuevoIdx = i; break end
				end
				if nuevoIdx then
					nodoSelecIdx = nuevoIdx
					local n = #resultado.Headers
					local gT, gE, gS = calcularGrados(resultado.Matrix, nuevoIdx, n)
					actualizarInfoNodo(nombrePrevio, gT, gE, gS)
					resaltarEnMatriz(nuevoIdx)
				else
					-- Nodo ya no existe en esta zona
					nodoSelecIdx = nil
					actualizarInfoNodo(nil, 0, 0, 0)
				end
			end
		else
			warn("❌ MatrixManager: Error del servidor — " .. tostring(resultado))
			matrizData = nil
			local scroll = getScroll()
			if scroll then
				for _, c in ipairs(scroll:GetChildren()) do
					if not c:IsA("UIListLayout") then c:Destroy() end
				end
				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(1, 0, 0, 40)
				lbl.BackgroundTransparency = 1
				lbl.Text = "⚠ Sin datos para esta zona"
				lbl.TextColor3 = Color3.fromRGB(176, 190, 197)
				lbl.Font = Enum.Font.Gotham; lbl.TextSize = 13
				lbl.Parent = scroll
			end
		end
	end)
end

-- ================================================================
-- INICIALIZACIÓN
-- ================================================================
function MatrixManager.initialize(state, guiRef, depRef)
	globalState  = state
	gui          = guiRef
	LevelsConfig = depRef and depRef.LevelsConfig

	local Events    = ReplicatedStorage:WaitForChild("Events", 5)
	local Remotes   = Events and Events:WaitForChild("Remotes",   5)
	local Bindables = Events and Events:WaitForChild("Bindables", 5)

	-- ── 1. Cambio de zona ───────────────────────────────────────
	-- Fuente A: BindableEvent LocalZoneChanged (cliente ZoneDetector)
	local lzc = Bindables and Bindables:FindFirstChild("LocalZoneChanged")
	if lzc then
		lzc.Event:Connect(function(nuevaZona)
			if globalState and globalState.modoActual == "MATEMATICO" then
				print("📊 MatrixManager: zona → " .. tostring(nuevaZona))
				MatrixManager.solicitarMatriz(nuevaZona ~= "" and nuevaZona or nil)
			end
		end)
		print("✅ MatrixManager: escucha LocalZoneChanged")
	end

	-- Fuente B: Atributo CurrentZone (servidor ZoneTracker lo actualiza también)
	-- Esto cubre el caso donde el jugador entra a la zona ANTES de activar el modo
	player:GetAttributeChangedSignal("CurrentZone"):Connect(function()
		if not (globalState and globalState.modoActual == "MATEMATICO") then return end
		local zona = player:GetAttribute("CurrentZone") or ""
		print("📊 MatrixManager: atributo CurrentZone → " .. zona)
		MatrixManager.solicitarMatriz(zona ~= "" and zona or nil)
	end)
	print("✅ MatrixManager: escucha CurrentZone (atributo)")

	-- ── 2. Actualización en tiempo real ───────────────────────────
	-- Observa directamente los Connections folders de los postes en el workspace.
	-- Esto dispara cada vez que se crea o destruye un NumberValue dentro de Connections,
	-- es decir, exactamente cuando ConectarCables conecta o desconecta un cable.
	local function observarPostes()
		local nivel = workspace:FindFirstChild("NivelActual")
		if not nivel then
			-- intentar con nombre genérico
			local nivelID = player:GetAttribute("CurrentLevelID") or 0
			nivel = workspace:FindFirstChild("Nivel" .. nivelID)
		end
		if not nivel then return end

		local postesFolder = nivel:FindFirstChildWhereIsA("Folder", true)
		-- Buscar la carpeta Postes recursivamente
		local function findPostes(parent)
			for _, child in ipairs(parent:GetChildren()) do
				if child.Name == "Postes" and child:IsA("Folder") then
					return child
				end
				local found = findPostes(child)
				if found then return found end
			end
		end
		postesFolder = findPostes(nivel)
		if not postesFolder then return end

		-- Para cada poste, observar su carpeta Connections
		local function observarPoste(poste)
			if not poste:IsA("Model") then return end
				local function onConnectionsChange()
					local panel = getPanel()
					if not (panel and panel.Visible) then return end
					-- Pequeño debounce para no refrescar varias veces por la misma operación
					if _G._matrixRefreshPending then return end
					_G._matrixRefreshPending = true
					task.delay(0.15, function()
						_G._matrixRefreshPending = false
						print("🔄 MatrixManager: Refrescando matriz por cambio en Connections")
						MatrixManager.refrescar()
					end)
				end

			local connections = poste:FindFirstChild("Connections")
			if connections then
				connections.ChildAdded:Connect(onConnectionsChange)
				connections.ChildRemoved:Connect(onConnectionsChange)
			end
			-- Si Connections no existe aún, esperarla
			poste.ChildAdded:Connect(function(child)
				if child.Name == "Connections" then
					child.ChildAdded:Connect(onConnectionsChange)
					child.ChildRemoved:Connect(onConnectionsChange)
				end
			end)
		end

		for _, poste in ipairs(postesFolder:GetChildren()) do
			observarPoste(poste)
		end
		-- Postes que se agreguen después
		postesFolder.ChildAdded:Connect(function(poste)
			task.wait(0.1)
			observarPoste(poste)
		end)
		print("✅ MatrixManager: observando Connections de " .. #postesFolder:GetChildren() .. " postes")
	end

	-- Intentar ahora y también cuando el nivel cargue
	observarPostes()
	workspace.ChildAdded:Connect(function(child)
		if child.Name == "NivelActual" or child.Name:sub(1,5) == "Nivel" then
			task.wait(0.5)  -- esperar que los postes estén dentro
			observarPostes()
		end
	end)

	-- ── 3. Nodo seleccionado en mundo 3D ────────────────────────
	--       ConectarCables.server dispara cableDragEvent:FireClient("Start", att, neighbors)
	--       cuando el jugador clickea un nodo. Escuchamos eso para saber cuál nodo fue.
	local cableDragEvent = Remotes and Remotes:FindFirstChild("CableDragEvent")
	if cableDragEvent then
		cableDragEvent.OnClientEvent:Connect(function(tipo, att, _neighbors)
			local panel = getPanel()
			if not (panel and panel.Visible) then return end

			if tipo == "Start" and att then
				-- Primer click: seleccionar nodo en la matriz
				-- att.Parent = Selector, att.Parent.Parent = Poste (Model)
				if att.Parent and att.Parent.Parent then
					local nodeName = att.Parent.Parent.Name
					print("📊 MatrixManager: nodo seleccionado en 3D → " .. nodeName)
					seleccionarNodo(nodeName)
				end
			elseif tipo == "Stop" then
				-- Segundo click completado (cable conectado o cancelado)
				-- 🔥 FIX: Mantener selección pero refrescar datos
				print("📊 MatrixManager: Refrescando matriz tras Stop")
				-- Guardar el nodo que estaba seleccionado
				local nodoSeleccionadoNombre = nil
				if nodoSelecIdx and matrizData and matrizData.Headers then
					nodoSeleccionadoNombre = matrizData.Headers[nodoSelecIdx]
				end
				-- Refrescar la matriz completa para obtener datos actualizados del servidor
				task.delay(0.3, function()
					MatrixManager.refrescar()
					-- Después de refrescar, recalcular y mostrar stats del nodo seleccionado
					task.wait(0.1)
					if nodoSeleccionadoNombre and matrizData and matrizData.Headers then
						local nuevoIdx = getHeaderIdx(nodoSeleccionadoNombre)
						if nuevoIdx then
							nodoSelecIdx = nuevoIdx
							local n = #matrizData.Headers
							local gT, gE, gS = calcularGrados(matrizData.Matrix, nuevoIdx, n)
							actualizarInfoNodo(nodoSeleccionadoNombre, gT, gE, gS)
							resaltarEnMatriz(nuevoIdx)
							print("📊 MatrixManager: Stats actualizados tras conexión")
						else
							-- Nodo ya no existe, limpiar
							nodoSelecIdx = nil
							actualizarInfoNodo(nil, 0, 0, 0)
							resaltarEnMatriz(nil)
						end
					end
				end)
			end
		end)
		print("✅ MatrixManager: escucha CableDragEvent (selección 3D)")
	else
		warn("⚠️ MatrixManager: CableDragEvent no encontrado — selección 3D no disponible")
	end

	-- ── 4. Notificación de nueva arista via BindableEvent ────────
	--       Si tu EventManager ya tiene un BindableEvent "AristaConectada"
	local aristaConectada = Bindables and Bindables:FindFirstChild("AristaConectada")
	if aristaConectada then
		aristaConectada.Event:Connect(function()
			local panel = getPanel()
			if not (panel and panel.Visible) then return end
			MatrixManager.refrescar()
		end)
		print("✅ MatrixManager: escucha AristaConectada")
	end

	-- ── 5. Notificación de selección de nodos desde el mapa ──────
	local notifyEvent = Remotes and Remotes:FindFirstChild("NotificarSeleccionNodo")
	if notifyEvent then
		notifyEvent.OnClientEvent:Connect(function(tipo, nodeName)
			local panel = getPanel()
			if not (panel and panel.Visible) then return end
			
			if tipo == "NodoSeleccionado" then
				print("🗺️ MatrixManager: Nodo seleccionado en mapa → " .. tostring(nodeName))
				seleccionarNodo(nodeName)
			elseif tipo == "SeleccionCancelada" then
				print("🗺️ MatrixManager: Selección cancelada")
				nodoSelecIdx = nil
				actualizarInfoNodo(nil, 0, 0, 0)
				resaltarEnMatriz(nil)
			elseif tipo == "ConexionCompletada" then
				print("🗺️ MatrixManager: Conexión completada desde mapa")
				-- 🔥 FIX: Mantener selección pero refrescar datos
				-- Guardar el nodo que estaba seleccionado
				local nodoSeleccionadoNombre = nil
				if nodoSelecIdx and matrizData and matrizData.Headers then
					nodoSeleccionadoNombre = matrizData.Headers[nodoSelecIdx]
				end
				task.delay(0.3, function()
					MatrixManager.refrescar()
					-- Después de refrescar, recalcular y mostrar stats del nodo seleccionado
					task.wait(0.1)
					if nodoSeleccionadoNombre and matrizData and matrizData.Headers then
						local nuevoIdx = getHeaderIdx(nodoSeleccionadoNombre)
						if nuevoIdx then
							nodoSelecIdx = nuevoIdx
							local n = #matrizData.Headers
							local gT, gE, gS = calcularGrados(matrizData.Matrix, nuevoIdx, n)
							actualizarInfoNodo(nodoSeleccionadoNombre, gT, gE, gS)
							resaltarEnMatriz(nuevoIdx)
							print("📊 MatrixManager: Stats actualizados tras conexión en mapa")
						else
							-- Nodo ya no existe, limpiar
							nodoSelecIdx = nil
							actualizarInfoNodo(nil, 0, 0, 0)
							resaltarEnMatriz(nil)
						end
					end
				end)
			end
		end)
		print("✅ MatrixManager: escucha NotificarSeleccionNodo (mapa)")
	end

	print("✅ MatrixManager inicializado (v3)")
end

-- ================================================================
-- API PÚBLICA
-- ================================================================

-- 🔥 NUEVO: Limpiar selección de nodo (útil al cambiar de modo)
function MatrixManager.clearSelection()
	nodoSelecIdx = nil
	actualizarInfoNodo(nil, 0, 0, 0)
	resaltarEnMatriz(nil)
	print("📊 MatrixManager: Selección limpiada")
end

function MatrixManager.activar()
	local panel = getPanel()
	if panel then panel.Visible = true end

	-- 🔥 FIX: Limpiar cualquier selección previa al activar
	nodoSelecIdx = nil
	actualizarInfoNodo(nil, 0, 0, 0)

	-- Configurar tamaño de celda a 10px (configurable)
	if not matrizData then matrizData = {} end
	matrizData.CellSize = 10  -- Tamaño mínimo configurable

	local zona = player:GetAttribute("CurrentZone") or ""
	MatrixManager.solicitarMatriz(zona ~= "" and zona or nil)
	print("📊 MatrixManager: ACTIVADO (celda 10px)")
end

function MatrixManager.desactivar()
	local panel = getPanel()
	if panel then panel.Visible = false end
	nodoSelecIdx = nil
	matrizData = nil
	print("📊 MatrixManager: desactivado")
end

function MatrixManager.refrescar()
	local panel = getPanel()
	if not (panel and panel.Visible) then return end
	local zona = player:GetAttribute("CurrentZone") or ""
	MatrixManager.solicitarMatriz(zona ~= "" and zona or zonaActual)
end

-- Permite que otros módulos (EventManager) notifiquen un nodo seleccionado
function MatrixManager.onNodoSeleccionado(nodeName)
	local panel = getPanel()
	if not (panel and panel.Visible) then return end
	seleccionarNodo(nodeName)
end

-- Configurar el tamaño de celda (mínimo 10px)
function MatrixManager.setCellSize(size)
	if not matrizData then matrizData = {} end
	matrizData.CellSize = math.max(10, size or 48)
	-- Si el panel está visible, refrescar para aplicar el nuevo tamaño
	local panel = getPanel()
	if panel and panel.Visible and matrizData.Headers then
		renderizarMatriz(matrizData)
	end
	print("📐 MatrixManager: Tamaño de celda configurado a " .. matrizData.CellSize .. "px")
end

return MatrixManager