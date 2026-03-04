-- ModuloAnalisis/PanelEstadoAnalisis.lua
-- Tabla de estado (ScrollEstado), pills de algoritmo, aplicarPaso y mensajes de UI.

local AlgoritmosGrafo    = require(script.Parent.Parent.AlgoritmosGrafo)
local ViewportAnalisis   = require(script.Parent.ViewportAnalisis)
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

-- Para Dijkstra/Prim los pendientes tienen formato "N1=0" o "N1=∞"
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
	local relleno = C.buscar(E.overlay, "RellenoProgreso")
	if relleno then relleno.Size = UDim2.new(0, 0, 1, 0) end
end

-- ════════════════════════════════════════════════════════════════
-- SCROLL ESTADO: tabla 3 columnas
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

	local altFila   = 22
	local altHeader = 20
	local orden     = 0

	local function crearFila3(col1, col2, col3, bgColor, esHeader)
		bgColor = bgColor or Color3.fromRGB(22, 33, 50)
		local frame             = Instance.new("Frame")
		frame.LayoutOrder       = orden
		frame.Size              = UDim2.new(1, -4, 0, esHeader and altHeader or altFila)
		frame.BackgroundColor3  = bgColor
		frame.BackgroundTransparency = esHeader and 0.1 or 0.4
		frame.BorderSizePixel   = 0
		frame.Parent            = scroll
		C.addCorner(frame, 3)

		local anchors = {0, 0.35, 0.70}
		local widths  = {0.35, 0.35, 0.30}
		local texts   = {col1, col2, col3}
		local cols    = {
			Color3.fromRGB(148, 163, 184),
			Color3.new(1, 1, 1),
			Color3.fromRGB(251, 191,  36),
		}

		for c = 1, 3 do
			local lbl               = Instance.new("TextLabel")
			lbl.Size                = UDim2.new(widths[c], -2, 1, 0)
			lbl.Position            = UDim2.new(anchors[c], 2, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text                = tostring(texts[c])
			lbl.TextColor3          = esHeader and Color3.fromRGB(148, 163, 184) or cols[c]
			lbl.Font                = esHeader and Enum.Font.GothamBold or Enum.Font.Gotham
			lbl.TextSize            = esHeader and 10 or 11
			lbl.TextXAlignment      = Enum.TextXAlignment.Left
			lbl.TextTruncate        = Enum.TextTruncate.AtEnd
			lbl.Parent              = frame
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

	if not step then
		scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		return
	end

	-- Cabecera
	crearFila3("ESTRUCTURA", "CONTENIDO", "DIST.", Color3.fromRGB(15, 23, 42), true)

	-- Estructura activa
	local pseudo      = AlgoritmosGrafo.PSEUDOCODIGOS[E.algoActual]
	local structNom   = pseudo and pseudo.structNombre or (step.struct or "—")
	local contenidoRaw = step.structConten or {}
	local contenParts  = {}
	for _, entry in ipairs(contenidoRaw) do
		contenParts[#contenParts+1] = getAlias(nombrePuro(entry))
	end
	local contenStr = #contenParts > 0 and table.concat(contenParts, " · ") or "(vacía)"
	crearFila3(structNom, contenStr, "—", Color3.fromRGB(17, 40, 80))

	-- Visitados
	local visitParts = {}
	for _, v in ipairs(step.visitados or {}) do
		visitParts[#visitParts+1] = getAlias(v)
	end
	local visitStr = #visitParts > 0 and table.concat(visitParts, " · ") or "—"
	crearFila3("Visitados", visitStr, "—", Color3.fromRGB(15, 50, 30))

	crearSeparador()

	-- Filas por nodo
	if E.matrizData then
		for _, nome in ipairs(E.matrizData.Headers) do
			local alias = getAlias(nome)

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

			local distStr = "∞"
			if step.distancias then
				local d = step.distancias[nome]
				if d ~= nil then distStr = tostring(d) end
			end

			crearFila3(alias, status, distStr, bgColor)
		end
	end

	scroll.CanvasSize = UDim2.new(0, 0, 0, orden * (altFila + 2) + 6)
end

-- ════════════════════════════════════════════════════════════════
-- APLICAR PASO
-- ════════════════════════════════════════════════════════════════

function PanelEstadoAnalisis.aplicarPaso(step)
	if not step then return end

	-- 1. Colorear nodos
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

	-- 3. Número y descripción del paso
	local numPasoLbl  = C.buscar(E.overlay, "NumPaso")
	local descPasoLbl = C.buscar(E.overlay, "DescPaso")
	if numPasoLbl  then numPasoLbl.Text  = "PASO " .. E.pasoActual .. " / " .. E.totalPasos end
	if descPasoLbl then descPasoLbl.Text = step.descripcion or "" end

	-- 4. Recorrido con aliases
	local labelRecorrido = C.buscar(E.overlay, "LabelRecorrido")
	if labelRecorrido then
		local partes = {}
		for _, v in ipairs(step.visitados) do
			partes[#partes+1] = getAlias(v)
		end
		labelRecorrido.Text = #partes > 0 and table.concat(partes, " → ") or "—"
	end

	-- 5. Pseudocódigo
	PseudocodigoAnalisis.resaltarLinea(step.lineaPseudo)

	-- 6. ScrollEstado
	PanelEstadoAnalisis.actualizarScrollEstado(step)

	-- 7. Métricas
	local totalNodos   = E.matrizData and #E.matrizData.Headers or 0
	local metricaPasos = C.buscar(E.overlay, "MetricaPasos")
	local metricaNodos = C.buscar(E.overlay, "MetricaNodos")
	if metricaPasos then metricaPasos.Text = E.pasoActual .. " / " .. E.totalPasos end
	if metricaNodos then metricaNodos.Text = #step.visitados .. " / " .. totalNodos end

	-- 8. Barra de progreso
	local relleno = C.buscar(E.overlay, "RellenoProgreso")
	if relleno and E.totalPasos > 0 then
		relleno.Size = UDim2.new(E.pasoActual / E.totalPasos, 0, 1, 0)
	end
end

return PanelEstadoAnalisis
