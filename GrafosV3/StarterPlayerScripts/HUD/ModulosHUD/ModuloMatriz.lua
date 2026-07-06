-- StarterPlayerScripts/HUD/ModulosHUD/ModuloMatriz.lua
-- Módulo cliente: visualiza la Matriz de Adyacencia en PanelMatrizAdyacencia.
-- Versión con UI de información de nodo mejorada (sin solapamientos).

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")

local jugador    = Players.LocalPlayer
local LevelsConfig = require(RS:WaitForChild("Config"):WaitForChild("LevelsConfig"))
local GrafoHelpers = require(RS:WaitForChild("Compartido"):WaitForChild("GrafoHelpers"))
local GestorEfectos = require(script.Parent.Parent.Parent:WaitForChild("SistemasGameplay"):WaitForChild("GestorEfectos"))

local ModuloMatriz = {}

-- ════════════════════════════════════════════════════════════════
-- ESTADO
-- ════════════════════════════════════════════════════════════════
local _hudGui        = nil
local _matrizData    = nil
local _nodoSelecIdx  = nil
local _zonaActual    = nil
local _getMatrixFunc = nil
local _inicializado  = false
local _refreshPending = false
local _esDirigido    = false
local _nodosReparadosLocal = {}

-- ════════════════════════════════════════════════════════════════
-- COLORES
-- ════════════════════════════════════════════════════════════════
local C = {
	Header       = Color3.fromRGB(52,  152, 219),
	CeldaUno     = Color3.fromRGB(46,  204, 113),
	CeldaCero    = Color3.fromRGB(50,   50,  50),
	Diag         = Color3.fromRGB(30,   30,  30),
	Esquina      = Color3.fromRGB(60,   60,  60),
	Selec        = Color3.fromRGB(255, 220,   0),
	SelecCero    = Color3.fromRGB(140, 110,   0),
	Daniado      = Color3.fromRGB(200,  50,  50),
	DaniadoSelec = Color3.fromRGB(255, 100, 100),
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

local function setMinimapVisible(visible)
	if not _hudGui then return end
	local cont = _hudGui:FindFirstChild("ContenedorMiniMapa", true)
	if cont then cont.Visible = visible end
end

local function setLeyendaVisible(visible)
	if not _hudGui then return end
	local leg = _hudGui:FindFirstChild("Leyenda", true)
	if leg then leg.Visible = visible end
end

-- ════════════════════════════════════════════════════════════════
-- ALIAS Y HELPERS DE MATRIZ
-- ════════════════════════════════════════════════════════════════
local function getAlias(nodeName)
	if not nodeName then return "--" end
	if _matrizData and _matrizData.NombresNodos then
		local alias = _matrizData.NombresNodos[nodeName]
		if alias and alias ~= "" then return alias end
	end
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

local function esNodoDaniadoVisible(nodeName)
	if _nodosReparadosLocal[nodeName] then return false end
	if not _matrizData or not _matrizData.NodosDaniados then return false end
	for _, n in ipairs(_matrizData.NodosDaniados) do
		if n == nodeName then return true end
	end
	return false
end

local function obtenerLimiteCables(nombreNodo)
	if not nombreNodo then return nil end
	local nivelID = jugador:GetAttribute("CurrentLevelID") or 0
	local cfg = LevelsConfig[nivelID]
	local limite = cfg and cfg.LimitesGrado and cfg.LimitesGrado[nombreNodo]
	return limite and limite.CablesMaximos or nil
end

local function configurarInfoNodo()
	local panel = getPanel()
	if not panel then return end
	
	panel.Size = UDim2.new(0, 420, 0, 480)
	panel.Position = UDim2.new(0, 10, 0.5, -230)
	local header = panel:FindFirstChild("MatrizHeader")
	if header then
		header.Size     = UDim2.new(1, 0, 0, 36)
		header.Position = UDim2.new(0, 0, 0, 0)
	end

	local marco = panel:FindFirstChild("MarcoInfoNodo")
	if not marco then
		marco = Instance.new("Frame")
		marco.Name   = "MarcoInfoNodo"
		marco.Parent = panel
		addCorner(marco, 8)
		addStroke(marco)
	end

	marco.Size               = UDim2.new(1, -20, 0, 68)
	marco.Position           = UDim2.new(0, 10, 0, 42)
	marco.BackgroundColor3   = Color3.fromRGB(20, 30, 50)
	marco.BackgroundTransparency = 0.2
	marco.BorderSizePixel    = 0

	-- Limpiar TODO dentro del marco
	for _, child in ipairs(marco:GetChildren()) do
		child:Destroy()
	end

	-- Padding visual
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft   = UDim.new(0, 8)
	pad.PaddingRight  = UDim.new(0, 8)
	pad.PaddingTop    = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.Parent = marco

	-- Posiciones absolutas: 2 columnas × 3 filas
	-- Cada fila: 18px alto, gap de 4px → total 3 filas = 18*3 + 4*2 = 62px (cabe en 68px)
	local COL1_X = 0            -- columna izquierda: 0%
	local COL2_X = 0.5          -- columna derecha:   50%
	local ANCHO  = 0.5          -- cada columna ocupa 50%

	local filasDef = {
		-- { name, titulo, colX, rowY }
		{ name = "FilaNodo",    titulo = "Nodo",    col = COL1_X, row = 0   },
		{ name = "FilaGrado",   titulo = "Grado",   col = COL1_X, row = 22  },
		{ name = "FilaEntrada", titulo = "Entrada", col = COL1_X, row = 44  },
		{ name = "FilaSalida",  titulo = "Salida",  col = COL2_X, row = 0   },
		{ name = "GradoMax",    titulo = "Límite",  col = COL2_X, row = 22  },
	}

	for _, def in ipairs(filasDef) do
		local f = Instance.new("Frame")
		f.Name                  = def.name
		f.Size                  = UDim2.new(ANCHO, -4, 0, 18)
		f.Position              = UDim2.new(def.col, 2, 0, def.row)
		f.BackgroundTransparency = 1
		f.Parent                = marco

		local titulo = Instance.new("TextLabel")
		titulo.Name             = "T"
		titulo.Size             = UDim2.new(0, 55, 1, 0)
		titulo.Position         = UDim2.new(0, 0, 0, 0)
		titulo.BackgroundTransparency = 1
		titulo.Font             = Enum.Font.Gotham
		titulo.TextSize         = 11
		titulo.TextColor3       = Color3.fromRGB(180, 190, 210)
		titulo.TextXAlignment   = Enum.TextXAlignment.Left
		titulo.TextYAlignment   = Enum.TextYAlignment.Center
		titulo.Text             = def.titulo .. ":"
		titulo.Parent           = f

		local valor = Instance.new("TextLabel")
		valor.Name              = "Valor"
		valor.Size              = UDim2.new(1, -57, 1, 0)
		valor.Position          = UDim2.new(0, 57, 0, 0)
		valor.BackgroundTransparency = 1
		valor.Font              = Enum.Font.GothamBold
		valor.TextSize          = 11
		valor.TextColor3        = Color3.fromRGB(255, 255, 255)
		valor.TextXAlignment    = Enum.TextXAlignment.Left
		valor.TextYAlignment    = Enum.TextYAlignment.Center
		valor.Text              = "--"
		valor.Parent            = f
	end

	-- Cuadrícula justo debajo: 42 header + 68 info + 8 margen = 118
	local scroll = getScroll()
	if scroll then
		scroll.Position = UDim2.new(0, 5, 0, 118)
		scroll.Size     = UDim2.new(1, -10, 1, -126)
	end
end
-- ════════════════════════════════════════════════════════════════
-- ACTUALIZAR INFORMACIÓN DEL NODO
-- ════════════════════════════════════════════════════════════════
local function actualizarInfoNodo(nombreInterno, gTotal, gEntrada, gSalida, cablesMaximos)
	local panel = getPanel()
	if not panel then return end
	local marco = panel:FindFirstChild("MarcoInfoNodo")
	if not marco then return end

	local alias = nombreInterno and getAlias(nombreInterno) or "--"

	-- Función auxiliar para escribir en el Valor de una fila
	local function setValor(frameName, text, alerta)
		local f = marco:FindFirstChild(frameName)
		local valor = f and f:FindFirstChild("Valor")
		if valor then
			valor.Text = text
			if alerta then
				valor.TextColor3 = Color3.fromRGB(255, 80, 80)
			else
				valor.TextColor3 = Color3.fromRGB(255, 255, 255)
			end
		end
	end

	setValor("FilaNodo",    alias)
	setValor("FilaGrado",   tostring(gTotal   or 0))
	setValor("FilaEntrada", tostring(gEntrada or 0))
	setValor("FilaSalida",  tostring(gSalida  or 0))

	-- Actualizar GradoMax (Límite)
	local fMax = marco:FindFirstChild("GradoMax")
	local valorMax = fMax and fMax:FindFirstChild("Valor")
	if valorMax then
		if cablesMaximos then
			valorMax.Text = string.format("%d cables", cablesMaximos)
		else
			valorMax.Text = "--"
		end
	end
end

-- ════════════════════════════════════════════════════════════════
-- CÁLCULO DE GRADOS
-- ════════════════════════════════════════════════════════════════
local function calcularGrados(matrix, idx, n)
	local gSalida, gEntrada = 0, 0
	for j = 1, n do
		if matrix[idx] and (matrix[idx][j] or 0) > 0 then gSalida = gSalida + 1 end
		if matrix[j] and (matrix[j][idx] or 0) > 0 then gEntrada = gEntrada + 1 end
	end
	local esDigrafo = false
	for r = 1, n do
		for c = 1, n do
			if matrix[r] and matrix[c] and (matrix[r][c] or 0) ~= (matrix[c][r] or 0) then
				esDigrafo = true; break
			end
		end
		if esDigrafo then break end
	end
	local gTotal = esDigrafo and (gEntrada + gSalida) or gEntrada
	return gTotal, gEntrada, gSalida
end

-- ════════════════════════════════════════════════════════════════
-- RESALTAR MATRIZ
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
		local esDefectuoso = false
		if esDato then
			local rawVal = (_matrizData.Matrix[cy] and _matrizData.Matrix[cy][cx]) or 0
			val = rawVal > 0 and 1 or 0
			local nomA = _matrizData.Headers[cy]
			local nomB = _matrizData.Headers[cx]
			esDefectuoso = GrafoHelpers.esCableDefectuoso(_matrizData, nomA, nomB)
		end

		local function colorHeaderBase(nombre)
			return esNodoDaniadoVisible(nombre) and C.Daniado or C.Header
		end

		if esEsquina then
			-- sin cambios
		elseif idx == nil then
			if esHdrCol then
				child.BackgroundColor3 = colorHeaderBase(_matrizData.Headers[cx])
			elseif esHdrFil then
				child.BackgroundColor3 = colorHeaderBase(_matrizData.Headers[cy])
			elseif esDiag then
				child.BackgroundColor3 = C.Diag
			elseif esDato then
				if esDefectuoso then
					child.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
				else
					child.BackgroundColor3 = val > 0 and C.CeldaUno or C.CeldaCero
				end
			end
		else
			local esHdrSelec  = (esHdrCol and cx == idx) or (esHdrFil and cy == idx)
			local esFilaSelec = esDato and cy == idx and not esDiag
			local esColSelec  = esDato and cx == idx and not esDiag

			if esHdrSelec then
				local nombreSelec = esHdrCol and _matrizData.Headers[cx] or _matrizData.Headers[cy]
				child.BackgroundColor3 = esNodoDaniadoVisible(nombreSelec) and C.DaniadoSelec or C.Selec
			elseif esDiag then
				child.BackgroundColor3 = C.Diag
			elseif esFilaSelec or esColSelec then
				if esDefectuoso then
					child.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
				else
					child.BackgroundColor3 = val > 0 and C.Selec or C.SelecCero
				end
			elseif esHdrCol then
				child.BackgroundColor3 = colorHeaderBase(_matrizData.Headers[cx])
			elseif esHdrFil then
				child.BackgroundColor3 = colorHeaderBase(_matrizData.Headers[cy])
			elseif esDato then
				if esDefectuoso then
					child.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
				else
					child.BackgroundColor3 = val > 0 and C.CeldaUno or C.CeldaCero
				end
			end
		end
	end
end

-- ════════════════════════════════════════════════════════════════
-- SELECCIONAR NODO
-- ════════════════════════════════════════════════════════════════
local function seleccionarNodo(nodeName)
	if not _matrizData then return end

	local idx = getHeaderIdx(nodeName)
	if not idx then
		_nodoSelecIdx = nil
		actualizarInfoNodo(nil, 0, 0, 0, nil, nil)
		resaltarEnMatriz(nil)
		return
	end

	_nodoSelecIdx = idx
	local n = #_matrizData.Headers
	local gT, gE, gS = calcularGrados(_matrizData.Matrix, idx, n)
	local cablesMaximos = obtenerLimiteCables(nodeName)
	actualizarInfoNodo(nodeName, gT, gE, gS, cablesMaximos)
	resaltarEnMatriz(idx)
end

-- ════════════════════════════════════════════════════════════════
-- RENDERIZAR MATRIZ
-- ════════════════════════════════════════════════════════════════
local function renderizarMatriz(data)
	local scroll = getScroll()
	if not scroll then warn("[ModuloMatriz] CuadriculaMatriz no encontrada"); return end

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

	local padding = 3
	local sX = scroll.AbsoluteSize.X
	local sY = scroll.AbsoluteSize.Y
	if sX < 10 then sX = 300 end
	if sY < 10 then sY = 300 end

	local fitX = math.floor((sX - padding) / (n + 1)) - padding
	local fitY = math.floor((sY - padding) / (n + 1)) - padding
	local maxFit  = math.min(fitX, fitY)
	local cellSize = math.max(14, math.min(maxFit, 60))

	local paso  = cellSize + padding
	local total = (n + 1) * paso + padding

	scroll.CanvasSize = UDim2.new(0, total, 0, total)
	scroll.ScrollingEnabled = true
	scroll.ScrollBarThickness = total > sX and 6 or 0

	-- Esquina
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

	-- Headers columna
	for i, hNombre in ipairs(headers) do
		local alias = getAlias(hNombre)
		local btn = Instance.new("TextButton")
		btn.Name = string.format("Cell_%d_0", i)
		btn.Size = UDim2.new(0, cellSize, 0, cellSize)
		btn.Position = UDim2.new(0, i * paso, 0, 0)
		btn.BackgroundColor3 = esNodoDaniadoVisible(hNombre) and C.Daniado or C.Header
		btn.BackgroundTransparency = 0
		btn.BorderSizePixel = 0
		btn.Text = alias
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 11; btn.TextScaled = true
		btn.AutoButtonColor = false
		btn.Parent = scroll
		addCorner(btn, 4); addStroke(btn)
		btn.MouseButton1Click:Connect(function() seleccionarNodo(hNombre) end)
	end

	-- Filas
	for rowIdx, rowNombre in ipairs(headers) do
		local alias = getAlias(rowNombre)

		-- Header fila
		local btnFila = Instance.new("TextButton")
		btnFila.Name = string.format("Cell_0_%d", rowIdx)
		btnFila.Size = UDim2.new(0, cellSize, 0, cellSize)
		btnFila.Position = UDim2.new(0, 0, 0, rowIdx * paso)
		btnFila.BackgroundColor3 = esNodoDaniadoVisible(rowNombre) and C.Daniado or C.Header
		btnFila.BackgroundTransparency = 0
		btnFila.BorderSizePixel = 0
		btnFila.Text = alias
		btnFila.TextColor3 = Color3.new(1, 1, 1)
		btnFila.Font = Enum.Font.GothamBold
		btnFila.TextSize = 11; btnFila.TextScaled = true
		btnFila.AutoButtonColor = false
		btnFila.Parent = scroll
		addCorner(btnFila, 4); addStroke(btnFila)
		btnFila.MouseButton1Click:Connect(function() seleccionarNodo(rowNombre) end)

		-- Celdas
		for colIdx = 1, n do
			local rawVal = (matrix[rowIdx] and matrix[rowIdx][colIdx]) or 0
			local val = rawVal > 0 and 1 or 0
			local nomA = headers[rowIdx]
			local nomB = headers[colIdx]
			local esDefectuoso = GrafoHelpers.esCableDefectuoso(_matrizData, nomA, nomB)
			local esDiag = (rowIdx == colIdx)

			local color
			if esDiag then
				color = C.Diag
			elseif esDefectuoso then
				color = Color3.fromRGB(200, 50, 50)
			else
				color = val > 0 and C.CeldaUno or C.CeldaCero
			end
			local texto = esDiag and "—" or tostring(val)

			local cell = Instance.new("TextLabel")
			cell.Name = string.format("Cell_%d_%d", colIdx, rowIdx)
			cell.Size = UDim2.new(0, cellSize, 0, cellSize)
			cell.Position = UDim2.new(0, colIdx * paso, 0, rowIdx * paso)
			cell.BackgroundColor3 = color
			cell.BackgroundTransparency = 0
			cell.BorderSizePixel = 0
			cell.Text = texto
			cell.TextColor3 = Color3.new(1, 1, 1)
			cell.Font = Enum.Font.Code
			cell.TextSize = 14; cell.TextScaled = true
			cell.Parent = scroll
			addCorner(cell, 4); addStroke(cell)
		end
	end

	if _nodoSelecIdx then resaltarEnMatriz(_nodoSelecIdx) end
	print(string.format("[ModuloMatriz] %dx%d (celda=%dpx)", n, n, cellSize))
end

-- ════════════════════════════════════════════════════════════════
-- MOSTRAR MENSAJE EN CUADRÍCULA
-- ════════════════════════════════════════════════════════════════
local function mostrarMensaje(texto)
	local scroll = getScroll()
	if not scroll then return end
	for _, c in ipairs(scroll:GetChildren()) do
		if not c:IsA("UIListLayout") then c:Destroy() end
	end
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = texto
	lbl.TextColor3 = Color3.fromRGB(176, 190, 197)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 14
	lbl.TextWrapped = true
	lbl.TextXAlignment = Enum.TextXAlignment.Center
	lbl.Parent = scroll
end

-- ════════════════════════════════════════════════════════════════
-- SOLICITAR MATRIZ
-- ════════════════════════════════════════════════════════════════
local function solicitarMatriz(zonaID)
	if not _getMatrixFunc then
		local ok, remote = pcall(function()
			return RS:WaitForChild("EventosGrafosV3", 10):WaitForChild("Remotos", 5):WaitForChild("GetAdjacencyMatrix", 5)
		end)
		if ok and remote then
			_getMatrixFunc = remote
		else
			warn("[ModuloMatriz] GetAdjacencyMatrix no encontrada"); return
		end
	end

	actualizarInfoNodo(nil, 0, 0, 0, nil, nil)

	task.spawn(function()
		local ok, resultado = pcall(function()
			return _getMatrixFunc:InvokeServer(zonaID)
		end)

		if ok and resultado then
			if resultado.SinZona or #resultado.Headers == 0 then
				_matrizData = nil
				_esDirigido = false
				_nodoSelecIdx = nil
				mostrarMensaje(resultado.SinZona and "Entra en una zona para ver su matriz" or "Esta zona no tiene grafo definido")
				local panel = getPanel()
				local header = panel and panel:FindFirstChild("MatrizHeader")
				local titulo = header and header:FindFirstChild("TituloMatriz")
				if titulo then titulo.Text = "MATRIZ DE ADYACENCIA" end
				return
			end

			local nombrePrevio = nil
			if _nodoSelecIdx and _matrizData and _matrizData.Headers then
				nombrePrevio = _matrizData.Headers[_nodoSelecIdx]
			end

			_matrizData = resultado
			_esDirigido = resultado.EsDirigido or false
			_zonaActual = zonaID
			renderizarMatriz(resultado)

			local panel = getPanel()
			local header = panel and panel:FindFirstChild("MatrizHeader")
			local titulo = header and header:FindFirstChild("TituloMatriz")
			if titulo then
				local tipo = _esDirigido and "DÍGRAFO" or "GRAFO NO DIRIGIDO"
				titulo.Text = tipo .. " — " .. (zonaID or "")
			end

			if nombrePrevio then
				local nuevoIdx = getHeaderIdx(nombrePrevio)
				if nuevoIdx then
					_nodoSelecIdx = nuevoIdx
					local n = #resultado.Headers
					local gT, gE, gS = calcularGrados(resultado.Matrix, nuevoIdx, n)
					local cablesMaximos = obtenerLimiteCables(nombrePrevio)
					actualizarInfoNodo(nombrePrevio, gT, gE, gS, cablesMaximos)
					resaltarEnMatriz(nuevoIdx)
				else
					_nodoSelecIdx = nil
					actualizarInfoNodo(nil, 0, 0, 0, nil, nil)
				end
			end
		else
			warn("[ModuloMatriz] Error del servidor: " .. tostring(resultado))
			_matrizData = nil
			mostrarMensaje("Error al obtener la matriz")
		end
	end)
end

local function scheduleRefresh()
	if _refreshPending then return end
	_refreshPending = true
	task.delay(0.3, function()
		_refreshPending = false
		if isVisible() then solicitarMatriz(_zonaActual) end
	end)
end

-- ════════════════════════════════════════════════════════════════
-- ACTIVAR / DESACTIVAR
-- ════════════════════════════════════════════════════════════════
local function activar()
	local panel = getPanel()
	if not panel then return end
	panel.Visible = true
	setMinimapVisible(false)
	setLeyendaVisible(false)

	_nodoSelecIdx = nil
	actualizarInfoNodo(nil, 0, 0, 0, nil, nil)

	local zona = jugador:GetAttribute("ZonaActual") or ""
	if zona == "" then
		mostrarMensaje("Entra en una zona para ver su matriz")
		local header = panel:FindFirstChild("MatrizHeader")
		local tl = header and header:FindFirstChild("TituloMatriz")
		if tl then tl.Text = "MATRIZ DE ADYACENCIA" end
		print("[ModuloMatriz] Activado (sin zona)")
		return
	end

	solicitarMatriz(zona)
	print("[ModuloMatriz] Activado")
end

local function desactivar()
	local panel = getPanel()
	if panel then panel.Visible = false end
	setMinimapVisible(true)
	local mapaAbierto = jugador:GetAttribute("MapaAbierto") == true
	setLeyendaVisible(mapaAbierto)
	_nodoSelecIdx = nil
	_matrizData = nil
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
	if panel then
		panel.Visible = false
		configurarInfoNodo()  -- Crea y organiza el marco de información
	end

	local selectorModos = hudGui:FindFirstChild("SelectorModos", true)
	if selectorModos then
		local matrizBtn = selectorModos:FindFirstChild("MatrizBtn")
		local visualBtn = selectorModos:FindFirstChild("VisualBtn")
		if matrizBtn then matrizBtn.MouseButton1Click:Connect(function() ModuloMatriz.abrir() end) end
		if visualBtn then visualBtn.MouseButton1Click:Connect(function() ModuloMatriz.cerrar() end) end
	else
		warn("[ModuloMatriz] SelectorModos no encontrado")
	end

	if panel then
		local header = panel:FindFirstChild("MatrizHeader")
		local btnCerrar = header and header:FindFirstChild("BtnCerrarMatriz")
		if btnCerrar then btnCerrar.MouseButton1Click:Connect(desactivar) end
	end

	local ok, remotos = pcall(function()
		return RS:WaitForChild("EventosGrafosV3", 10):WaitForChild("Remotos", 5)
	end)

	if ok and remotos then
		-- Escuchar eventos de gameplay via GestorEfectos (único listener centralizado)
		GestorEfectos.registrar("NodoSeleccionado", function(params)
			if not isVisible() then return end
			local arg1 = params.arg1
			local nombre = type(arg1) == "string" and arg1 or (typeof(arg1) == "Instance" and arg1.Name) or nil
			if nombre then seleccionarNodo(nombre) end
		end)

		GestorEfectos.registrar("CableDesconectado", function(_params)
			if not isVisible() then return end
			scheduleRefresh()
		end)

		GestorEfectos.registrar("ConexionCompletada", function(_params)
			if not isVisible() then return end
			scheduleRefresh()
		end)

		GestorEfectos.registrar("SeleccionCancelada", function(_params)
			if not isVisible() then return end
			_nodoSelecIdx = nil
			actualizarInfoNodo(nil, 0, 0, 0, nil, nil)
			resaltarEnMatriz(nil)
		end)

		GestorEfectos.registrar("ClicReparacion", function(params)
			print(string.format("[ModuloMatriz] Reparando %s: faltan %d clics", tostring(params.arg1), tonumber(params.arg2) or 0))
		end)

		GestorEfectos.registrar("NodoReparado", function(params)
			local nombre = type(params.arg1) == "string" and params.arg1 or nil
			if nombre then
				_nodosReparadosLocal[nombre] = true
				print("[ModuloMatriz] Nodo reparado:", nombre)
				if isVisible() then renderizarMatriz(_matrizData) end
			end
		end)

		print("[ModuloMatriz] Escucha GestorEfectos registrada")

		local actualizarConex = remotos:FindFirstChild("ActualizarEstadoConexiones")
		if actualizarConex then
			actualizarConex.OnClientEvent:Connect(scheduleRefresh)
			print("[ModuloMatriz] Escucha ActualizarEstadoConexiones")
		end
	else
		warn("[ModuloMatriz] No se encontraron los Remotos de EventosGrafosV3")
	end

	jugador:GetAttributeChangedSignal("ZonaActual"):Connect(function()
		if not isVisible() then return end
		local zona = jugador:GetAttribute("ZonaActual") or ""
		if zona == "" then
			_matrizData = nil
			_esDirigido = false
			_nodoSelecIdx = nil
			actualizarInfoNodo(nil, 0, 0, 0, nil, nil)
			mostrarMensaje("Entra en una zona para ver su matriz")
		else
			solicitarMatriz(zona)
		end
	end)

	print("[ModuloMatriz] Inicializado")
end

function ModuloMatriz.configurarNivel(_, _, _)
	if isVisible() then scheduleRefresh() end
end

function ModuloMatriz.refrescar()
	if isVisible() then scheduleRefresh() end
end

function ModuloMatriz.seleccionarNodoExterno(nombre)
	if not isVisible() then return end
	seleccionarNodo(nombre)
end

function ModuloMatriz.cancelarSeleccion()
	if not isVisible() then return end
	_nodoSelecIdx = nil
	actualizarInfoNodo(nil, 0, 0, 0, nil, nil)
	resaltarEnMatriz(nil)
end

function ModuloMatriz.limpiar()
	desactivar()
	print("[ModuloMatriz] Limpiado")
end

function ModuloMatriz.estaAbierta()
	return isVisible()
end

function ModuloMatriz.estaAbierto()
	return isVisible()
end

function ModuloMatriz.abrir()
	activar()
end

function ModuloMatriz.cerrar()
	desactivar()
end

return ModuloMatriz
