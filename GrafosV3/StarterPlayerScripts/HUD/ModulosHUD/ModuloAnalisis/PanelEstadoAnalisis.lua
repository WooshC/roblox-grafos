-- ModuloAnalisis/PanelEstadoAnalisis.lua
-- Tabla de estado (ScrollEstado), pills de algoritmo, aplicarPaso y mensajes de UI.
--
-- CAMBIOS:
--   • Eliminada la leyenda de colores (Actual / Visitado / En cola / Sin visitar).
--   • ScrollEstado dividido en DOS secciones con header propio:
--       1. "📋 INFORMACIÓN DEL PASO"  → estructura activa (Cola/Pila) + Visitados + 💡 concepto
--       2. "🔵 NODOS"                 → tabla Nodo | Estado | Nivel/Dist.

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
-- SCROLL ESTADO — dos secciones con header propio
-- ════════════════════════════════════════════════════════════════

function PanelEstadoAnalisis.actualizarScrollEstado(step)
	local scroll = C.buscar(E.overlay, "ScrollEstado")
	if not scroll then return end

	-- Limpiar contenido anterior
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

	-- Determinar si mostramos columna de distancia/nivel
	local mostrarDist = (E.algoActual == "bfs" or E.algoActual == "dijkstra")
	local distHeader  = E.algoActual == "bfs" and "NIVEL" or "DIST."

	-- Alturas de los distintos tipos de fila
	local altSectionHeader = 20   -- cabecera de sección (azul/verde oscuro)
	local altFilaHeader    = 18   -- cabecera de columnas dentro de tabla
	local altFilaConten    = 34   -- fila con texto largo (estructura, visitados)
	local altFilaNodo      = 22   -- fila compacta por nodo
	local orden            = 0

	-- ── Helper: separador fino ────────────────────────────────────────────────
	local function crearSeparador()
		local sep            = Instance.new("Frame")
		sep.LayoutOrder      = orden
		sep.Size             = UDim2.new(1, -8, 0, 1)
		sep.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
		sep.BackgroundTransparency = 0
		sep.BorderSizePixel  = 0
		sep.Parent           = scroll
		orden = orden + 1
	end

	-- ── Helper: header de sección coloreado ──────────────────────────────────
	local function crearHeaderSeccion(titulo, bgColor)
		local frame            = Instance.new("Frame")
		frame.LayoutOrder      = orden
		frame.Size             = UDim2.new(1, -4, 0, altSectionHeader)
		frame.BackgroundColor3 = bgColor
		frame.BackgroundTransparency = 0.15
		frame.BorderSizePixel  = 0
		frame.Parent           = scroll
		C.addCorner(frame, 4)

		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 6)
		pad.Parent = frame

		local lbl               = Instance.new("TextLabel")
		lbl.Size                = UDim2.new(1, 0, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text                = titulo
		lbl.TextColor3          = Color3.fromRGB(226, 232, 240)
		lbl.Font                = Enum.Font.GothamBold
		lbl.TextSize            = 11
		lbl.TextXAlignment      = Enum.TextXAlignment.Left
		lbl.TextYAlignment      = Enum.TextYAlignment.Center
		lbl.Parent              = frame
		orden = orden + 1
		return frame
	end

	-- ── Helper: fila genérica de 2 columnas (clave | valor) ──────────────────
	local function crearFilaKV(clave, valor, bgColor, altFila, conWrap)
		bgColor = bgColor or Color3.fromRGB(22, 33, 50)
		local frame            = Instance.new("Frame")
		frame.LayoutOrder      = orden
		frame.Size             = UDim2.new(1, -4, 0, altFila or altFilaConten)
		frame.BackgroundColor3 = bgColor
		frame.BackgroundTransparency = 0.4
		frame.BorderSizePixel  = 0
		frame.Parent           = scroll
		C.addCorner(frame, 3)

		-- Clave
		local lblK               = Instance.new("TextLabel")
		lblK.Size                = UDim2.new(0.33, -2, 1, 0)
		lblK.Position            = UDim2.new(0, 4, 0, 0)
		lblK.BackgroundTransparency = 1
		lblK.Text                = clave
		lblK.TextColor3          = Color3.fromRGB(148, 163, 184)
		lblK.Font                = Enum.Font.GothamBold
		lblK.TextSize            = 10
		lblK.TextXAlignment      = Enum.TextXAlignment.Left
		lblK.TextYAlignment      = Enum.TextYAlignment.Top
		lblK.TextWrapped         = false
		lblK.TextTruncate        = Enum.TextTruncate.AtEnd
		lblK.Parent              = frame

		-- Valor
		local lblV               = Instance.new("TextLabel")
		lblV.Size                = UDim2.new(0.65, -2, 1, 0)
		lblV.Position            = UDim2.new(0.35, 0, 0, 0)
		lblV.BackgroundTransparency = 1
		lblV.Text                = valor
		lblV.TextColor3          = Color3.new(1, 1, 1)
		lblV.Font                = Enum.Font.Gotham
		lblV.TextSize            = 10
		lblV.TextXAlignment      = Enum.TextXAlignment.Left
		lblV.TextYAlignment      = Enum.TextYAlignment.Top
		if conWrap then
			lblV.TextWrapped  = true
			lblV.TextTruncate = Enum.TextTruncate.None
		else
			lblV.TextWrapped  = false
			lblV.TextTruncate = Enum.TextTruncate.AtEnd
		end
		lblV.Parent = frame
		orden = orden + 1
	end

	-- ── Helper: cabecera de columnas para la tabla de nodos ──────────────────
	local function crearCabeceraTabla()
		local frame            = Instance.new("Frame")
		frame.LayoutOrder      = orden
		frame.Size             = UDim2.new(1, -4, 0, altFilaHeader)
		frame.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
		frame.BackgroundTransparency = 0.1
		frame.BorderSizePixel  = 0
		frame.Parent           = scroll
		C.addCorner(frame, 3)

		local cols, anchors, widths
		if mostrarDist then
			cols    = {"NODO", "ESTADO", distHeader}
			anchors = {0, 0.38, 0.76}
			widths  = {0.38, 0.38, 0.22}
		else
			cols    = {"NODO", "ESTADO"}
			anchors = {0, 0.40}
			widths  = {0.40, 0.58}
		end

		for i, texto in ipairs(cols) do
			local lbl               = Instance.new("TextLabel")
			lbl.Size                = UDim2.new(widths[i], -2, 1, 0)
			lbl.Position            = UDim2.new(anchors[i], (i == 1) and 4 or 2, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text                = texto
			lbl.TextColor3          = Color3.fromRGB(148, 163, 184)
			lbl.Font                = Enum.Font.GothamBold
			lbl.TextSize            = 10
			lbl.TextXAlignment      = Enum.TextXAlignment.Left
			lbl.TextYAlignment      = Enum.TextYAlignment.Center
			lbl.Parent              = frame
		end
		orden = orden + 1
	end

	-- ── Helper: fila de nodo en la tabla ─────────────────────────────────────
	local function crearFilaNodo(col1, col2, col3, bgColor)
		bgColor = bgColor or Color3.fromRGB(22, 33, 50)
		local frame            = Instance.new("Frame")
		frame.LayoutOrder      = orden
		frame.Size             = UDim2.new(1, -4, 0, altFilaNodo)
		frame.BackgroundColor3 = bgColor
		frame.BackgroundTransparency = 0.4
		frame.BorderSizePixel  = 0
		frame.Parent           = scroll
		C.addCorner(frame, 3)

		local cols, anchors, widths, colores
		if mostrarDist then
			cols    = {col1, col2, col3 or "—"}
			anchors = {0, 0.38, 0.76}
			widths  = {0.38, 0.38, 0.22}
			colores = {
				Color3.fromRGB(226, 232, 240),
				Color3.new(1, 1, 1),
				Color3.fromRGB(251, 191, 36),
			}
		else
			cols    = {col1, col2}
			anchors = {0, 0.40}
			widths  = {0.40, 0.58}
			colores = {
				Color3.fromRGB(226, 232, 240),
				Color3.new(1, 1, 1),
			}
		end

		for i, texto in ipairs(cols) do
			local lbl               = Instance.new("TextLabel")
			lbl.Size                = UDim2.new(widths[i], -2, 1, 0)
			lbl.Position            = UDim2.new(anchors[i], (i == 1) and 4 or 2, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text                = tostring(texto)
			lbl.TextColor3          = colores[i]
			lbl.Font                = Enum.Font.Gotham
			lbl.TextSize            = 11
			lbl.TextXAlignment      = Enum.TextXAlignment.Left
			lbl.TextYAlignment      = Enum.TextYAlignment.Center
			lbl.TextWrapped         = false
			lbl.TextTruncate        = Enum.TextTruncate.AtEnd
			lbl.Parent              = frame
		end
		orden = orden + 1
	end

	if not step then
		scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		return
	end

	-- ════════════════════════════════════════════════════════════
	-- SECCIÓN 1 — INFORMACIÓN DEL PASO
	-- ════════════════════════════════════════════════════════════
	crearHeaderSeccion("INFORMACIÓN DEL PASO", Color3.fromRGB(30, 58, 138))

	-- Fila estructura activa (Cola / Pila / etc.)
	local pseudo      = AlgoritmosGrafo.PSEUDOCODIGOS[E.algoActual]
	local structNom   = pseudo and pseudo.structNombre or (step.struct or "—")
	local contenParts = {}
	for _, entry in ipairs(step.structConten or {}) do
		contenParts[#contenParts + 1] = getAlias(nombrePuro(entry))
	end
	local contenStr = #contenParts > 0 and table.concat(contenParts, " · ") or "(vacía)"
	crearFilaKV(structNom, contenStr, Color3.fromRGB(17, 40, 80), altFilaConten, true)

	-- Fila visitados
	local visitParts = {}
	for _, v in ipairs(step.visitados or {}) do
		visitParts[#visitParts + 1] = getAlias(v)
	end
	local visitStr = #visitParts > 0 and table.concat(visitParts, " · ") or "—"
	crearFilaKV("Visitados", visitStr, Color3.fromRGB(15, 50, 30), altFilaConten, true)

	-- Bloque 💡 concepto pedagógico (si existe)
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

	-- ════════════════════════════════════════════════════════════
	-- SECCIÓN 2 — NODOS
	-- ════════════════════════════════════════════════════════════
	crearHeaderSeccion("NODOS", Color3.fromRGB(6, 78, 59))
	crearCabeceraTabla()

	local totalNodos = E.matrizData and #E.matrizData.Headers or 0

	if E.matrizData then
		for _, nome in ipairs(E.matrizData.Headers) do
			local alias = getAlias(nome)

			local sufijo = ""
			if nome == E.nodoInicio                    then sufijo = "(Inicio)" end
			if E.nodoFin and nome == E.nodoFin         then sufijo = "(Fin)" end

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
				if E.modoValidacion and E.pasoActual and E.totalPasos > 0 and E.pasoActual >= E.totalPasos then
					status  = "❌ Nodo Aislado (Defectuoso/Falta)"
					bgColor = Color3.fromRGB(120, 20, 20)
				else
					status  = "○ sin visitar"
					bgColor = Color3.fromRGB(22, 33, 50)
				end
			end

			local distStr = "—"
			if mostrarDist and step.distancias then
				local d = step.distancias[nome]
				distStr = (d ~= nil) and tostring(d) or "∞"
			end

			crearFilaNodo(alias .. sufijo, status, distStr, bgColor)
		end
	end

	-- ── Calcular altura total del canvas ─────────────────────────────────────
	local alturaTotal =
		(altSectionHeader + 2)                          -- header sección 1
		+ (altFilaConten  + 2) * 2                      -- Cola/Pila + Visitados
		+ (conceptoH > 0 and (conceptoH + 2) or 0)     -- concepto opcional
		+ 1 + 2                                         -- separador
		+ (altSectionHeader + 2)                        -- header sección 2
		+ (altFilaHeader  + 2)                          -- cabecera tabla
		+ (altFilaNodo    + 2) * totalNodos             -- filas de nodos
		+ 8                                             -- padding final

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
			if (E.modoValidacion or E.validacionTerminada) and (E.totalPasos and E.totalPasos > 0) and (E.pasoActual and E.pasoActual >= E.totalPasos) then
				part.Color    = Color3.fromRGB(200, 50, 50)
				part.Material = Enum.Material.Neon
			else
				part.Color    = C.COL_DEFAULT
				part.Material = Enum.Material.SmoothPlastic
			end
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