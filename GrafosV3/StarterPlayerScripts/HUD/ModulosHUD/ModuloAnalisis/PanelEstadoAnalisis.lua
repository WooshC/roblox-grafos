-- ModuloAnalisis/PanelEstadoAnalisis.lua
-- Tabla de estado (ScrollEstado), pills de algoritmo, aplicarPaso y mensajes de UI.

local AlgoritmosGrafo      = require(script.Parent.Parent.AlgoritmosGrafo)
local ViewportAnalisis     = require(script.Parent.ViewportAnalisis)
local PseudocodigoAnalisis = require(script.Parent.PseudocodigoAnalisis)

local E = require(script.Parent.EstadoAnalisis)
local C = require(script.Parent.ConstantesAnalisis)

local PanelEstadoAnalisis = {}

-- ════════════════════════════════════════════════════════════════
-- HELPERS LOCALES
-- ════════════════════════════════════════════════════════════════

local function getAlias(nome)
	if E.matrizData and E.matrizData.NombresNodos then
		local alias = E.matrizData.NombresNodos[nome]
		if alias and alias ~= "" then return alias end
	end
	return nome
end

local function esNodoPendiente(pendientes, nome)
	for _, v in ipairs(pendientes) do
		local n = tostring(v):match("^(.-)=") or v
		if n == nome then return true end
	end
	return false
end

local function nombrePuro(entry)
	return tostring(entry):match("^(.-)=") or tostring(entry)
end

-- Devuelve el texto pedagógico para el lineaPseudo del paso actual.
local function getConceptoPaso(lineaPseudo)
	if not E.analisisConfig then return nil end
	local cAlgo = E.analisisConfig.conceptos and E.analisisConfig.conceptos[E.algoActual]
	if not cAlgo or not cAlgo.pasos then return nil end
	return cAlgo.pasos[lineaPseudo]
end

-- ════════════════════════════════════════════════════════════════
-- PILLS
-- ════════════════════════════════════════════════════════════════

local PILL_NAMES = {
	bfs      = "PillBFS",
	dfs      = "PillDFS",
	dijkstra = "PillDijkstra",
	prim     = "PillPrim",
}
PanelEstadoAnalisis.PILL_NAMES = PILL_NAMES

function PanelEstadoAnalisis.actualizarPills(algoActivo)
	for id, pillName in pairs(PILL_NAMES) do
		local pill = C.buscar(E.overlay, pillName)
		if pill then
			pill.BackgroundColor3 = (id == algoActivo) and C.COL_PILL_ACTIVO or C.COL_PILL_INACTIVO
		end
	end
end

-- Oculta pills no disponibles en la zona. nil = mostrar todas.
function PanelEstadoAnalisis.actualizarPillsVisibles(algoritmos)
	for id, pillName in pairs(PILL_NAMES) do
		local pill = C.buscar(E.overlay, pillName)
		if pill then
			if algoritmos == nil then
				pill.Visible = true
			else
				local visible = false
				for _, a in ipairs(algoritmos) do
					if a == id then visible = true; break end
				end
				pill.Visible = visible
			end
		end
	end
end

-- ════════════════════════════════════════════════════════════════
-- MENSAJE EN PANEL
-- ════════════════════════════════════════════════════════════════

function PanelEstadoAnalisis.mostrarMensajeDesc(msg)
	local descLbl = C.buscar(E.overlay, "DescPaso")
	if descLbl then descLbl.Text = msg end
	local numLbl = C.buscar(E.overlay, "NumPaso")
	if numLbl then numLbl.Text = "— / —" end
	local recLbl = C.buscar(E.overlay, "LabelRecorrido")
	if recLbl then recLbl.Text = "—" end
	local conceptoLbl = C.buscar(E.overlay, "LabelConcepto")
	if conceptoLbl then conceptoLbl.Text = "" end
	local relleno = C.buscar(E.overlay, "RellenoProgreso")
	if relleno then relleno.Size = UDim2.new(0, 0, 1, 0) end
end

-- Muestra la intro pedagógica al seleccionar un algoritmo (antes del paso 1).
function PanelEstadoAnalisis.mostrarIntroAlgo(algo, nodoInicio)
	local conceptoLbl = C.buscar(E.overlay, "LabelConcepto")
	if not conceptoLbl then return end

	local pseudo      = AlgoritmosGrafo.PSEUDOCODIGOS[algo]
	local tituloAlgo  = pseudo and pseudo.titulo or algo:upper()
	local aliasInicio = nodoInicio and getAlias(nodoInicio) or "?"

	local header = tituloAlgo .. "  ·  Inicio: " .. aliasInicio
	if E.nodoFin and algo == "dijkstra" then
		header = header .. "  ·  Destino: " .. getAlias(E.nodoFin)
	end

	local introTexto = ""
	if E.analisisConfig then
		local cAlgo = E.analisisConfig.conceptos and E.analisisConfig.conceptos[algo]
		if cAlgo and cAlgo.intro then
			introTexto = cAlgo.intro
		end
	end

	conceptoLbl.Text = (#introTexto > 0) and (header .. "\n" .. introTexto) or header
end

-- ════════════════════════════════════════════════════════════════
-- SCROLL ESTADO
-- ════════════════════════════════════════════════════════════════

function PanelEstadoAnalisis.actualizarScrollEstado(step)
	local scroll = C.buscar(E.overlay, "ScrollEstado")
	if not scroll then return end

	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)

	local layout     = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding   = UDim.new(0, 2)
	layout.Parent    = scroll

	local mostrarDist = (E.algoActual == "bfs" or E.algoActual == "dijkstra")
	local distHeader  = E.algoActual == "bfs" and "NIVEL" or "DIST."

	local altHeader     = 20
	local altFilaConten = 36
	local altFilaNodo   = 22
	local altLeyenda    = 18
	local orden         = 0

	local function crearFila(col1, col2, col3, bgColor, esHeader, conWrap)
		bgColor = bgColor or Color3.fromRGB(22, 33, 50)
		local alturaFila = esHeader and altHeader or (conWrap and altFilaConten or altFilaNodo)

		local frame            = Instance.new("Frame")
		frame.LayoutOrder      = orden
		frame.Size             = UDim2.new(1, -4, 0, alturaFila)
		frame.BackgroundColor3 = bgColor
		frame.BackgroundTransparency = esHeader and 0.1 or 0.4
		frame.BorderSizePixel  = 0
		frame.ClipsDescendants = false
		frame.Parent           = scroll
		C.addCorner(frame, 3)

		local anchors, widths, texts, colores
		if mostrarDist then
			anchors = {0, 0.32, 0.72}
			widths  = {0.32, 0.40, 0.27}
			texts   = {col1, col2, col3 or "—"}
			colores = {Color3.fromRGB(148,163,184), Color3.new(1,1,1), Color3.fromRGB(251,191,36)}
		else
			anchors = {0, 0.35}
			widths  = {0.35, 0.63}
			texts   = {col1, col2}
			colores = {Color3.fromRGB(148,163,184), Color3.new(1,1,1)}
		end

		local numCols = mostrarDist and 3 or 2
		for c = 1, numCols do
			local lbl               = Instance.new("TextLabel")
			lbl.Size                = UDim2.new(widths[c], -2, 1, 0)
			lbl.Position            = UDim2.new(anchors[c], 2, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text                = tostring(texts[c])
			lbl.TextColor3          = esHeader and Color3.fromRGB(148,163,184) or colores[c]
			lbl.Font                = esHeader and Enum.Font.GothamBold or Enum.Font.Gotham
			lbl.TextSize            = esHeader and 10 or 11
			lbl.TextXAlignment      = Enum.TextXAlignment.Left
			lbl.TextYAlignment      = Enum.TextYAlignment.Top
			if c == 2 and conWrap and not esHeader then
				lbl.TextWrapped  = true
				lbl.TextTruncate = Enum.TextTruncate.None
			else
				lbl.TextWrapped  = false
				lbl.TextTruncate = Enum.TextTruncate.AtEnd
			end
			lbl.Parent = frame
		end
		orden = orden + 1
		return frame
	end

	local function crearSeparador()
		local sep              = Instance.new("Frame")
		sep.LayoutOrder        = orden
		sep.Size               = UDim2.new(1, -8, 0, 1)
		sep.BackgroundColor3   = Color3.fromRGB(51, 65, 85)
		sep.BackgroundTransparency = 0
		sep.BorderSizePixel    = 0
		sep.Parent             = scroll
		orden = orden + 1
	end

	local function crearLeyenda()
		local frame            = Instance.new("Frame")
		frame.LayoutOrder      = orden
		frame.Size             = UDim2.new(1, -4, 0, altLeyenda)
		frame.BackgroundColor3 = Color3.fromRGB(10, 15, 25)
		frame.BackgroundTransparency = 0.2
		frame.BorderSizePixel  = 0
		frame.Parent           = scroll
		C.addCorner(frame, 3)

		local items = {
			{color = C.COL_ACTUAL,    texto = "▶ Actual"},
			{color = C.COL_VISITADO,  texto = "✓ Visitado"},
			{color = C.COL_PENDIENTE, texto = "⌛ En cola"},
			{color = C.COL_DEFAULT,   texto = "○ Sin visitar"},
		}
		local segW = 1 / #items
		for i, item in ipairs(items) do
			local lbl               = Instance.new("TextLabel")
			lbl.Size                = UDim2.new(segW, -2, 1, 0)
			lbl.Position            = UDim2.new(segW * (i-1), 2, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text                = item.texto
			lbl.TextColor3          = item.color
			lbl.Font                = Enum.Font.GothamBold
			lbl.TextSize            = 9
			lbl.TextXAlignment      = Enum.TextXAlignment.Center
			lbl.TextTruncate        = Enum.TextTruncate.AtEnd
			lbl.Parent              = frame
		end
		orden = orden + 1
	end

	if not step then
		scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		return
	end

	-- Cabecera
	crearFila("ESTRUCTURA", "CONTENIDO", distHeader, Color3.fromRGB(15, 23, 42), true, false)

	-- Fila estructura activa
	local pseudo      = AlgoritmosGrafo.PSEUDOCODIGOS[E.algoActual]
	local structNom   = pseudo and pseudo.structNombre or (step.struct or "—")
	local contenParts = {}
	for _, entry in ipairs(step.structConten or {}) do
		contenParts[#contenParts+1] = getAlias(nombrePuro(entry))
	end
	local contenStr = #contenParts > 0 and table.concat(contenParts, " · ") or "(vacía)"
	crearFila(structNom, contenStr, "—", Color3.fromRGB(17, 40, 80), false, true)

	-- Fila visitados
	local visitParts = {}
	for _, v in ipairs(step.visitados or {}) do
		visitParts[#visitParts+1] = getAlias(v)
	end
	local visitStr = #visitParts > 0 and table.concat(visitParts, " · ") or "—"
	crearFila("Visitados", visitStr, "—", Color3.fromRGB(15, 50, 30), false, true)

	-- Bloque concepto 💡 (si hay texto para esta lineaPseudo)
	local conceptoTexto = getConceptoPaso(step.lineaPseudo)
	local conceptoH     = 0
	if conceptoTexto then
		conceptoH = 36
		local frame            = Instance.new("Frame")
		frame.LayoutOrder      = orden
		frame.Size             = UDim2.new(1, -4, 0, conceptoH)
		frame.BackgroundColor3 = Color3.fromRGB(30, 20, 60)
		frame.BackgroundTransparency = 0.3
		frame.BorderSizePixel  = 0
		frame.Parent           = scroll
		C.addCorner(frame, 3)

		local icono        = Instance.new("TextLabel")
		icono.Size         = UDim2.new(0, 22, 1, 0)
		icono.Position     = UDim2.new(0, 4, 0, 0)
		icono.BackgroundTransparency = 1
		icono.Text         = "💡"
		icono.TextSize     = 14
		icono.Font         = Enum.Font.Gotham
		icono.Parent       = frame

		local lbl          = Instance.new("TextLabel")
		lbl.Size           = UDim2.new(1, -30, 1, 0)
		lbl.Position       = UDim2.new(0, 28, 0, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text           = conceptoTexto
		lbl.TextColor3     = Color3.fromRGB(196, 181, 253)
		lbl.Font           = Enum.Font.Gotham
		lbl.TextSize       = 10
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextYAlignment = Enum.TextYAlignment.Center
		lbl.TextWrapped    = true
		lbl.TextTruncate   = Enum.TextTruncate.None
		lbl.Parent         = frame
		orden = orden + 1
	end

	crearSeparador()
	crearLeyenda()
	crearSeparador()

	-- Filas por nodo
	if E.matrizData then
		for _, nome in ipairs(E.matrizData.Headers) do
			local alias = getAlias(nome)

			local sufijo = ""
			if nome == E.nodoInicio                        then sufijo = " 🔵" end
			if E.nodoFin and nome == E.nodoFin             then sufijo = " 🎯" end

			local status, bgColor
			if nome == step.nodoActual then
				status  = "▶ actual"
				bgColor = Color3.fromRGB(70, 40, 10)
			elseif table.find(step.visitados, nome) then
				status  = "✓ visitado"
				bgColor = Color3.fromRGB(15, 50, 30)
			elseif esNodoPendiente(step.pendientes, nome) then
				status  = "⌛ en cola"
				bgColor = Color3.fromRGB(20, 35, 70)
			else
				status  = "○ sin visitar"
				bgColor = Color3.fromRGB(22, 33, 50)
			end

			local distStr = "—"
			if mostrarDist and step.distancias then
				local d = step.distancias[nome]
				distStr = (d ~= nil) and tostring(d) or "∞"
			end

			crearFila(alias .. sufijo, status, distStr, bgColor, false, false)
		end
	end

	local totalNodos = E.matrizData and #E.matrizData.Headers or 0
	local alturaTotal = (altHeader + 2)
		+ (altFilaConten + 2) * 2
		+ (conceptoH > 0 and (conceptoH + 2) or 0)
		+ 3 + 3
		+ (altLeyenda + 2)
		+ (altFilaNodo + 2) * totalNodos
		+ 8
	scroll.CanvasSize = UDim2.new(0, 0, 0, alturaTotal)
end

-- ════════════════════════════════════════════════════════════════
-- APLICAR PASO
-- ════════════════════════════════════════════════════════════════

function PanelEstadoAnalisis.aplicarPaso(step)
	if not step then return end

	-- 1. Colorear nodos en viewport
	for nome, part in pairs(E.nodoParts) do
		if nome == step.nodoActual then
			part.Color    = C.COL_ACTUAL
			part.Material = Enum.Material.Neon
		elseif table.find(step.visitados, nome) then
			part.Color    = C.COL_VISITADO
			part.Material = Enum.Material.Neon
		elseif esNodoPendiente(step.pendientes, nome) then
			part.Color    = C.COL_PENDIENTE
			part.Material = Enum.Material.Neon
		else
			part.Color    = C.COL_DEFAULT
			part.Material = Enum.Material.SmoothPlastic
		end
	end

	-- 2. Aristas progresivas
	ViewportAnalisis.reconstruirAristas(step)

	-- 3. Número y descripción técnica
	local numPasoLbl  = C.buscar(E.overlay, "NumPaso")
	local descPasoLbl = C.buscar(E.overlay, "DescPaso")
	if numPasoLbl  then numPasoLbl.Text  = "PASO " .. E.pasoActual .. " / " .. E.totalPasos end
	if descPasoLbl then descPasoLbl.Text = step.descripcion or "" end

	-- 4. Concepto pedagógico del paso (LabelConcepto)
	local conceptoLbl = C.buscar(E.overlay, "LabelConcepto")
	if conceptoLbl then
		local texto = getConceptoPaso(step.lineaPseudo)
		if texto then
			conceptoLbl.Text = "💡 " .. texto
		end
		-- Si no hay concepto para esta línea, no borramos el texto anterior (evita parpadeo)
	end

	-- 5. Recorrido con aliases en orden real
	local labelRecorrido = C.buscar(E.overlay, "LabelRecorrido")
	if labelRecorrido then
		local partes = {}
		for _, v in ipairs(step.visitados) do
			partes[#partes+1] = getAlias(v)
		end
		local recStr = #partes > 0 and table.concat(partes, " → ") or "—"
		if E.nodoFin and E.algoActual == "dijkstra" then
			recStr = recStr .. "  ·  🎯 " .. getAlias(E.nodoFin)
		end
		labelRecorrido.Text = recStr
	end

	-- 6. Pseudocódigo
	PseudocodigoAnalisis.resaltarLinea(step.lineaPseudo)

	-- 7. ScrollEstado
	PanelEstadoAnalisis.actualizarScrollEstado(step)

	-- 8. Métricas
	local totalNodos   = E.matrizData and #E.matrizData.Headers or 0
	local metricaPasos = C.buscar(E.overlay, "MetricaPasos")
	local metricaNodos = C.buscar(E.overlay, "MetricaNodos")
	if metricaPasos then metricaPasos.Text = E.pasoActual .. " / " .. E.totalPasos end
	if metricaNodos then metricaNodos.Text = #step.visitados .. " / " .. totalNodos end

	-- 9. Barra de progreso
	local relleno = C.buscar(E.overlay, "RellenoProgreso")
	if relleno and E.totalPasos > 0 then
		relleno.Size = UDim2.new(E.pasoActual / E.totalPasos, 0, 1, 0)
	end
end

return PanelEstadoAnalisis