-- PanelAlgoritmo3D.lua
-- Panel lateral derecho estilo "Laboratorio de Grafos".
-- Muestra información del algoritmo, minimapa y mensajes contextuales.
-- Soporta modo de espera por nodo dañado sin parpadeos.

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RS           = game:GetService("ReplicatedStorage")

local BillboardNombres = require(RS:WaitForChild("Efectos"):WaitForChild("BillboardNombres"))
local LevelsConfig     = require(RS:WaitForChild("Config"):WaitForChild("LevelsConfig"))
local GrafoHelpers     = require(RS:WaitForChild("Compartido"):WaitForChild("GrafoHelpers"))

local PanelAlgoritmo3D = {}

-- ════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN VISUAL
-- ════════════════════════════════════════════════════════════════

local COL = {
	FONDO_CONTENEDOR = Color3.fromRGB(18, 22, 36),
	FONDO_PANEL      = Color3.fromRGB(16, 20, 31),
	FONDO_CANVAS     = Color3.fromRGB(15, 19, 31),
	FONDO_INFO       = Color3.fromRGB(0, 255, 200),
	CIAN             = Color3.fromRGB(0, 255, 204),
	CIAN_OSCURO      = Color3.fromRGB(0, 204, 170),
	AZUL             = Color3.fromRGB(0, 166, 255),
	ROJO             = Color3.fromRGB(255, 107, 107),
	VERDE            = Color3.fromRGB(105, 219, 124),
	AMARILLO         = Color3.fromRGB(255, 217, 61),
	TEXTO_PRINCIPAL  = Color3.fromRGB(176, 240, 230),
	TEXTO_SECUNDARIO = Color3.fromRGB(106, 138, 138),
	TEXTO_CLARO      = Color3.fromRGB(226, 232, 240),
	BORDE            = Color3.fromRGB(0, 255, 200),
	BORDE_SUAVE      = Color3.fromRGB(99, 102, 241),
}

local FUENTE_TITULO = Enum.Font.GothamBlack
local FUENTE_NORMAL = Enum.Font.GothamBold
local FUENTE_VALOR  = Enum.Font.Gotham

local TWEEN_APARECER = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- ════════════════════════════════════════════════════════════════
-- ESTADO INTERNO
-- ════════════════════════════════════════════════════════════════

local jugador = Players.LocalPlayer

local estado = {
	hudGui      = nil,
	panelRoot   = nil,
	escala      = nil,
	visor       = nil,
	worldModel  = nil,
	camara      = nil,

	-- Labels del panel
	lblTitulo      = nil,
	lblPasoValor   = nil,
	frmEstructura  = nil,
	lblEstructura  = nil,
	frmVisitados   = nil,
	lblVisitados   = nil,
	frmCosto       = nil,
	lblCostoLabel  = nil,
	lblCostoValor  = nil,
	boxMensaje     = nil,
	lblMensaje     = nil,
	btnCerrar      = nil,
	onCerrar       = nil,

	-- Datos del grafo
	matrizData    = nil,
	adyacencias   = nil,
	nivelID       = nil,
	nodoInicio    = nil,
	nodoFin       = nil,

	-- Objetos del minimapa
	nodoParts     = {},
	aristaParts   = {},
	posiciones    = {},

	-- Reparaciones
	aristasReparadas  = {},
	nodosDaniados     = {},
	nodosDaniadosSet  = {}, -- lookup O(1)
	nodosReparados    = {},

	-- Flag para evitar que el mensaje se sobrescriba mientras esperamos reparación
	modoEsperaNodoDaniado = false,

	-- Billboards de nodos dañados (para mostrar " REPARAR")
	billboardsDaniados = {},
}

-- ════════════════════════════════════════════════════════════════
-- HELPERS DE UI (creación de frames, labels, botones)
-- ════════════════════════════════════════════════════════════════

local function crearFrame(nombre, parent, props)
	local f = Instance.new("Frame")
	f.Name = nombre
	f.BackgroundColor3 = props.bg or COL.FONDO_PANEL
	f.BackgroundTransparency = props.transp or 0
	f.BorderSizePixel = 0
	f.Size = props.size or UDim2.new(1, 0, 1, 0)
	f.Position = props.pos or UDim2.new(0, 0, 0, 0)
	f.Parent = parent
	if props.z then f.ZIndex = props.z end
	return f
end

local function crearLabel(nombre, parent, props)
	local l = Instance.new("TextLabel")
	l.Name = nombre
	l.Text = props.text or ""
	l.Font = props.font or FUENTE_NORMAL
	l.TextSize = props.size or 12
	l.TextColor3 = props.color or COL.TEXTO_PRINCIPAL
	l.BackgroundTransparency = 1
	l.Size = props.sz or UDim2.new(1, 0, 1, 0)
	l.Position = props.pos or UDim2.new(0, 0, 0, 0)
	l.TextXAlignment = props.alignX or Enum.TextXAlignment.Left
	l.TextYAlignment = props.alignY or Enum.TextYAlignment.Center
	l.TextWrapped = props.wrap or false
	l.TextTruncate = props.truncate or Enum.TextTruncate.None
	l.Parent = parent
	if props.z then l.ZIndex = props.z end
	return l
end

local function crearBoton(nombre, parent, props)
	local b = Instance.new("TextButton")
	b.Name = nombre
	b.Text = props.text or ""
	b.Font = props.font or FUENTE_NORMAL
	b.TextSize = props.size or 12
	b.TextColor3 = props.color or COL.TEXTO_CLARO
	b.BackgroundColor3 = props.bg or COL.CIAN_OSCURO
	b.BackgroundTransparency = props.transp or 0.1
	b.AutoButtonColor = false
	b.BorderSizePixel = 0
	b.Size = props.sz or UDim2.new(1, 0, 1, 0)
	b.Position = props.pos or UDim2.new(0, 0, 0, 0)
	b.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, props.radius or 20)
	corner.Parent = b

	local stroke = Instance.new("UIStroke")
	stroke.Color = props.strokeColor or COL.BORDE
	stroke.Thickness = props.strokeThick or 1
	stroke.Transparency = props.strokeTransp or 0.3
	stroke.Parent = b
	return b
end

local function aplicarCorner(frame, radio)
	local c = frame:FindFirstChildOfClass("UICorner")
	if not c then
		c = Instance.new("UICorner")
		c.Parent = frame
	end
	c.CornerRadius = UDim.new(0, radio or 8)
end

local function aplicarPadding(frame, izq, der, arriba, abajo)
	local p = frame:FindFirstChildOfClass("UIPadding")
	if not p then
		p = Instance.new("UIPadding")
		p.Parent = frame
	end
	p.PaddingLeft   = UDim.new(0, izq or 0)
	p.PaddingRight  = UDim.new(0, der or 0)
	p.PaddingTop    = UDim.new(0, arriba or 0)
	p.PaddingBottom = UDim.new(0, abajo or 0)
end

-- ════════════════════════════════════════════════════════════════
-- ALIAS DE NODOS (para mostrar nombres amigables)
-- ════════════════════════════════════════════════════════════════

local function getAlias(nome)
	if not nome then return "--" end
	if estado.matrizData and estado.matrizData.NombresNodos then
		local alias = estado.matrizData.NombresNodos[nome]
		if alias and alias ~= "" then return alias end
	end
	local cfg = LevelsConfig[estado.nivelID or 0]
	if cfg and cfg.NombresNodos then
		local alias = cfg.NombresNodos[nome]
		if alias and alias ~= "" then return alias end
	end
	return nome
end

local function listaAlias(lista)
	local partes = {}
	for _, v in ipairs(lista or {}) do
		local nome = tostring(v):match("^(.-)=") or tostring(v)
		table.insert(partes, getAlias(nome))
	end
	return #partes > 0 and table.concat(partes, " · ") or "—"
end

-- ════════════════════════════════════════════════════════════════
-- MINIMAPA (construcción y actualización)
-- ════════════════════════════════════════════════════════════════

local TAM_NODO_MINI   = 5
local TAM_ARISTA_MINI = 0.6

local function buscarPosNodo(nombre)
	local nivel = workspace:FindFirstChild("NivelActual")
	if not nivel then return nil end
	local grafos = nivel:FindFirstChild("Grafos")
	if not grafos then return nil end
	for _, grafo in ipairs(grafos:GetChildren()) do
		local f = grafo:FindFirstChild("Nodos")
		if f then
			local m = f:FindFirstChild(nombre)
			if m then
				local sel = m:FindFirstChild("Selector")
				local ref = nil
				if sel then
					if sel:IsA("BasePart") then ref = sel
					else ref = sel.PrimaryPart or sel:FindFirstChildWhichIsA("BasePart", true) end
				end
				if not ref then
					ref = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
				end
				if ref then return ref.Position end
			end
		end
	end
	return nil
end

local function calcularCentroideYAltura()
	local n = 0
	local sumX, sumZ = 0, 0
	for _, pos in pairs(estado.posiciones) do
		sumX = sumX + pos.X
		sumZ = sumZ + pos.Z
		n = n + 1
	end
	if n == 0 then return nil end
	local cx = sumX / n
	local cz = sumZ / n
	local maxR = 0
	for _, pos in pairs(estado.posiciones) do
		local r = math.sqrt((pos.X - cx)^2 + (pos.Z - cz)^2)
		if r > maxR then maxR = r end
	end
	local altura = math.max(40, maxR * 2.2)
	return cx, cz, altura
end

local function ajustarCamaraMinimapa()
	if not estado.camara then return end
	local cx, cz, altura = calcularCentroideYAltura()
	if not cx then return end
	local maxY = -math.huge
	for _, pos in pairs(estado.posiciones) do
		if pos.Y > maxY then maxY = pos.Y end
	end
	if maxY == -math.huge then maxY = 0 end
	estado.camara.CFrame = CFrame.new(cx, maxY + altura, cz) * CFrame.Angles(math.rad(-90), 0, 0)
	estado.camara.FieldOfView = 60
end

local function limpiarMinimapa()
	if estado.worldModel then
		estado.worldModel:ClearAllChildren()
	end
	estado.nodoParts   = {}
	estado.aristaParts = {}
	estado.posiciones  = {}
	estado.camara      = nil
end

local function construirMinimapa()
	limpiarMinimapa()
	if not estado.worldModel or not estado.matrizData then return end

	local headers = estado.matrizData.Headers
	local esDirigido = estado.matrizData.EsDirigido or false

	for _, nome in ipairs(headers) do
		estado.posiciones[nome] = buscarPosNodo(nome) or Vector3.zero
	end

	local cam = Instance.new("Camera")
	cam.Name = "CamaraMinimapa"
	estado.camara = cam
	estado.visor.CurrentCamera = cam

	for _, nome in ipairs(headers) do
		local pos = estado.posiciones[nome]
		local part = Instance.new("Part")
		part.Name = "NodoMini_" .. nome
		part.Shape = Enum.PartType.Ball
		part.Anchored = true
		part.CanCollide = false
		part.CastShadow = false
		part.Material = Enum.Material.SmoothPlastic
		part.Size = Vector3.new(TAM_NODO_MINI, TAM_NODO_MINI, TAM_NODO_MINI)
		part.Color = COL.CIAN_OSCURO
		part.CFrame = CFrame.new(pos)
		part.Parent = estado.worldModel
		estado.nodoParts[nome] = part
	end

	local vistosND = {}
	for nomA, lista in pairs(estado.adyacencias or {}) do
		for _, nomB in ipairs(lista) do
			local key = GrafoHelpers.clavePar(nomA, nomB)
			if not esDirigido then
				if vistosND[key] then continue end
				vistosND[key] = true
			end
			local posA = estado.posiciones[nomA]
			local posB = estado.posiciones[nomB]
			if not posA or not posB then continue end
			local dist = (posA - posB).Magnitude
			if dist < 0.1 then continue end
			local centro = (posA + posB) / 2
			local part = Instance.new("Part")
			part.Name = "AristaMini_" .. key
			part.Anchored = true
			part.CanCollide = false
			part.CastShadow = false
			part.Material = Enum.Material.SmoothPlastic
			part.Size = Vector3.new(TAM_ARISTA_MINI, TAM_ARISTA_MINI, dist)
			part.CFrame = CFrame.lookAt(centro, posB)
			part.Color = COL.CIAN_OSCURO
			part.Transparency = 0.45
			part.Parent = estado.worldModel
			estado.aristaParts[key] = {
				part = part,
				nomA = nomA,
				nomB = nomB,
			}
		end
	end
	ajustarCamaraMinimapa()
end

local function colorArista(key, tipo)
	local info = estado.aristaParts[key]
	if not info then return end
	local part = info.part
	if not part then return end
	if tipo == "defectuosa" then
		part.Color = COL.ROJO
		part.Material = Enum.Material.Neon
		part.Transparency = 0.1
	elseif tipo == "reparada" then
		part.Color = COL.AMARILLO
		part.Material = Enum.Material.Neon
		part.Transparency = 0.1
	elseif tipo == "nueva" then
		part.Color = COL.AMARILLO
		part.Material = Enum.Material.Neon
		part.Transparency = 0
	elseif tipo == "recorrida" then
		part.Color = COL.CIAN
		part.Material = Enum.Material.Neon
		part.Transparency = 0
	elseif tipo == "camino" then
		part.Color = Color3.new(1, 1, 1)
		part.Material = Enum.Material.Neon
		part.Transparency = 0
	else
		part.Color = COL.CIAN_OSCURO
		part.Material = Enum.Material.SmoothPlastic
		part.Transparency = 0.45
	end
end

local function colorNodo(nome, tipo)
	local part = estado.nodoParts[nome]
	if not part then return end
	if tipo == "actual" then
		part.Color = COL.CIAN
		part.Material = Enum.Material.Neon
	elseif tipo == "inicio" then
		part.Color = Color3.fromRGB(255, 170, 0)
		part.Material = Enum.Material.Neon
	elseif tipo == "fin" then
		part.Color = COL.VERDE
		part.Material = Enum.Material.Neon
	elseif tipo == "visitado" then
		part.Color = COL.VERDE
		part.Material = Enum.Material.Neon
	elseif tipo == "camino" then
		part.Color = Color3.new(1, 1, 1)
		part.Material = Enum.Material.Neon
	else
		part.Color = COL.CIAN_OSCURO
		part.Material = Enum.Material.SmoothPlastic
	end
end

local function actualizarMinimapa(step)
	if not step then return end
	local esDijkstra = estado.algoritmoActual == "dijkstra"
	local esUltimoPaso = estado.pasoActual and estado.totalPasos and estado.pasoActual >= estado.totalPasos

	for nome, part in pairs(estado.nodoParts) do
		colorNodo(nome, "default")
	end

	for key, info in pairs(estado.aristaParts) do
		local esDefectuosa = false
		local setDinamico = estado.matrizData and estado.matrizData.Defectuosos
		if setDinamico then
			esDefectuosa = GrafoHelpers.esCableDefectuoso(setDinamico, info.nomA, info.nomB)
		end
		local reparada = estado.aristasReparadas[key]
		if esDefectuosa and not reparada then
			colorArista(key, "defectuosa")
		elseif reparada then
			colorArista(key, "reparada")
		else
			colorArista(key, "default")
		end
	end

	if esDijkstra and esUltimoPaso then
		for _, arista in ipairs(step.aristasRecorridas or {}) do
			local key = GrafoHelpers.clavePar(arista[1], arista[2])
			colorArista(key, "camino")
		end
	else
		for _, arista in ipairs(step.aristasRecorridas or {}) do
			local key = GrafoHelpers.clavePar(arista[1], arista[2])
			colorArista(key, "recorrida")
		end
	end

	if step.aristaNueva then
		local key = GrafoHelpers.clavePar(step.aristaNueva[1], step.aristaNueva[2])
		colorArista(key, "nueva")
	end

	if esDijkstra and esUltimoPaso then
		local caminoSet = {}
		for _, arista in ipairs(step.aristasRecorridas or {}) do
			caminoSet[arista[1]] = true
			caminoSet[arista[2]] = true
		end
		for nome in pairs(caminoSet) do
			colorNodo(nome, "camino")
		end
	else
		for _, nome in ipairs(step.visitados or {}) do
			colorNodo(nome, "visitado")
		end
	end

	if step.nodoActual then
		colorNodo(step.nodoActual, "actual")
	end
	if estado.nodoInicio then
		colorNodo(estado.nodoInicio, "inicio")
	end
	if estado.nodoFin then
		colorNodo(estado.nodoFin, "fin")
	end

	-- Nodos dañados en rojo (a menos que estén reparados)
	for nome, part in pairs(estado.nodoParts) do
		if estado.nodosDaniadosSet[nome] and not estado.nodosReparados[nome] then
			part.Color = COL.ROJO
			part.Material = Enum.Material.Neon
		end
	end
end

-- ════════════════════════════════════════════════════════════════
-- CONSTRUCCIÓN DEL PANEL PRINCIPAL
-- ════════════════════════════════════════════════════════════════

local function crearInfoItem(parent, nombre, orden, labelText)
	local item = crearFrame(nombre, parent, {
		bg = COL.FONDO_INFO,
		size = UDim2.new(1, 0, 0, 46),
		transp = 0.96,
	})
	aplicarCorner(item, 8)
	aplicarPadding(item, 10, 10, 6, 6)
	item.LayoutOrder = orden

	local lbl = crearLabel("Label", item, {
		text = labelText,
		font = FUENTE_NORMAL,
		size = 10,
		color = COL.TEXTO_SECUNDARIO,
		sz = UDim2.new(1, 0, 0, 12),
		pos = UDim2.new(0, 0, 0, 0),
		alignY = Enum.TextYAlignment.Top,
	})
	lbl.TextScaled = false
	lbl.TextTruncate = Enum.TextTruncate.AtEnd

	local val = crearLabel("Valor", item, {
		text = "—",
		font = FUENTE_VALOR,
		size = 13,
		color = COL.TEXTO_PRINCIPAL,
		sz = UDim2.new(1, 0, 0, 22),
		pos = UDim2.new(0, 0, 0, 13),
		wrap = true,
		alignY = Enum.TextYAlignment.Top,
	})
	val.TextScaled = false
	val.AutomaticSize = Enum.AutomaticSize.Y
	item.AutomaticSize = Enum.AutomaticSize.Y
	return item, lbl, val
end

local function crearPanelUI()
	local root = Instance.new("Frame")
	root.Name = "PanelAlgoritmo3D"
	root.BackgroundTransparency = 1
	root.AnchorPoint = Vector2.new(1, 0)
	root.Size = UDim2.new(0.33, 0, 1, 0)
	root.Position = UDim2.new(1, 0, 0, 0)
	root.Visible = false
	root.ZIndex = 10
	root.Parent = estado.hudGui

	local escala = Instance.new("UIScale")
	escala.Name = "EscalaPanel"
	escala.Scale = 1
	escala.Parent = root
	estado.escala = escala

	local cont = crearFrame("LabContainer", root, {
		bg = COL.FONDO_CONTENEDOR,
		size = UDim2.new(1, 0, 1, 0),
		pos = UDim2.new(0, 0, 0, 0),
	})
	local stroke = Instance.new("UIStroke")
	stroke.Color = COL.BORDE
	stroke.Thickness = 1
	stroke.Transparency = 0.8
	stroke.Parent = cont

	local mainList = Instance.new("UIListLayout")
	mainList.SortOrder = Enum.SortOrder.LayoutOrder
	mainList.Padding = UDim.new(0, 10)
	mainList.Parent = cont

	local mainPad = Instance.new("UIPadding")
	mainPad.PaddingLeft = UDim.new(0, 14)
	mainPad.PaddingRight = UDim.new(0, 14)
	mainPad.PaddingTop = UDim.new(0, 12)
	mainPad.PaddingBottom = UDim.new(0, 12)
	mainPad.Parent = cont

	-- Header
	local header = crearFrame("LabHeader", cont, {
		bg = COL.FONDO_CONTENEDOR,
		size = UDim2.new(1, 0, 0, 40),
	})
	header.LayoutOrder = 1

	estado.lblTitulo = crearLabel("TituloAlgoritmo", header, {
		text = "⚡ ALGORITMO",
		font = FUENTE_TITULO,
		size = 18,
		color = COL.CIAN,
		sz = UDim2.new(1, -80, 1, 0),
		pos = UDim2.new(0, 0, 0, 0),
		alignX = Enum.TextXAlignment.Left,
	})

	estado.btnCerrar = crearBoton("BtnCerrar", header, {
		text = "✕",
		sz = UDim2.new(0, 34, 0, 34),
		pos = UDim2.new(1, -34, 0, 3),
		bg = Color3.fromRGB(239, 68, 68),
		color = Color3.fromRGB(255, 255, 255),
		strokeColor = Color3.fromRGB(255, 255, 255),
		transp = 0.15,
		radius = 8,
	})

	-- Minimapa
	local canvasWrap = crearFrame("CanvasWrapper", cont, {
		bg = COL.FONDO_CANVAS,
		size = UDim2.new(1, 0, 0.42, 0),
	})
	canvasWrap.LayoutOrder = 2
	aplicarCorner(canvasWrap, 14)

	local visor = Instance.new("ViewportFrame")
	visor.Name = "VisorGrafo"
	visor.Size = UDim2.new(1, -12, 1, -12)
	visor.Position = UDim2.new(0, 6, 0, 6)
	visor.BackgroundColor3 = Color3.fromRGB(10, 13, 23)
	visor.BackgroundTransparency = 0
	visor.BorderSizePixel = 0
	visor.Parent = canvasWrap
	aplicarCorner(visor, 10)
	estado.visor = visor

	local wm = Instance.new("WorldModel")
	wm.Name = "WorldModel"
	wm.Parent = visor
	estado.worldModel = wm

	-- Panel de información
	local infoPanel = Instance.new("ScrollingFrame")
	infoPanel.Name = "InfoPanel"
	infoPanel.BackgroundColor3 = COL.FONDO_PANEL
	infoPanel.BackgroundTransparency = 0
	infoPanel.BorderSizePixel = 0
	infoPanel.Size = UDim2.new(1, 0, 0.58, -84)
	infoPanel.Position = UDim2.new(0, 0, 0, 0)
	infoPanel.LayoutOrder = 3
	infoPanel.ScrollBarThickness = 6
	infoPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
	infoPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
	infoPanel.Parent = cont
	aplicarCorner(infoPanel, 14)
	aplicarPadding(infoPanel, 12, 12, 12, 12)

	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 8)
	list.Parent = infoPanel

	-- Items de información
	local _, _, valPaso = crearInfoItem(infoPanel, "InfoPaso", 1, "▶ PASO DEL ALGORITMO")
	estado.lblPasoValor = valPaso

	local frmEst, lblEst, valEst = crearInfoItem(infoPanel, "InfoEstructura", 2, "ESTRUCTURA")
	estado.frmEstructura = frmEst
	estado.lblEstructuraLabel = lblEst
	estado.lblEstructura = valEst

	local frmVis, _, valVis = crearInfoItem(infoPanel, "InfoVisitados", 3, "VISITADOS")
	estado.frmVisitados = frmVis
	estado.lblVisitados = valVis

	local frmCost, lblCostLabel, valCost = crearInfoItem(infoPanel, "InfoCosto", 4, "COSTO / DISTANCIA")
	estado.frmCosto = frmCost
	estado.lblCostoLabel = lblCostLabel
	estado.lblCostoValor = valCost

	-- Caja de mensaje
	local msgBox = crearFrame("MessageBox", infoPanel, {
		bg = Color3.fromRGB(255, 200, 0),
		size = UDim2.new(1, 0, 0, 70),
		transp = 0.96,
	})
	msgBox.LayoutOrder = 5
	aplicarCorner(msgBox, 10)
	local msgStroke = Instance.new("UIStroke")
	msgStroke.Color = Color3.fromRGB(255, 200, 0)
	msgStroke.Transparency = 0.8
	msgStroke.Thickness = 1
	msgStroke.Parent = msgBox
	aplicarPadding(msgBox, 10, 10, 10, 10)
	estado.boxMensaje = msgBox

	estado.lblMensaje = crearLabel("Mensaje", msgBox, {
		text = "Iniciando algoritmo...",
		font = FUENTE_VALOR,
		size = 12,
		color = COL.TEXTO_PRINCIPAL,
		sz = UDim2.new(1, 0, 1, 0),
		wrap = true,
		alignX = Enum.TextXAlignment.Left,
		alignY = Enum.TextYAlignment.Top,
	})

	-- Leyenda
	local legend = crearFrame("Legend", infoPanel, {
		bg = COL.FONDO_PANEL,
		size = UDim2.new(1, 0, 0, 20),
	})
	legend.LayoutOrder = 7
	local listLeg = Instance.new("UIListLayout")
	listLeg.FillDirection = Enum.FillDirection.Horizontal
	listLeg.HorizontalAlignment = Enum.HorizontalAlignment.Left
	listLeg.VerticalAlignment = Enum.VerticalAlignment.Center
	listLeg.Padding = UDim.new(0, 10)
	listLeg.Parent = legend

	local function crearLegendItem(texto, color)
		local item = crearFrame("LegendItem", legend, {
			bg = COL.FONDO_PANEL,
			size = UDim2.new(0, 70, 1, 0),
		})
		local dot = crearFrame("Dot", item, {
			bg = color,
			size = UDim2.new(0, 14, 0, 3),
			pos = UDim2.new(0, 0, 0.5, -1),
		})
		aplicarCorner(dot, 2)
		crearLabel("Text", item, {
			text = texto,
			font = FUENTE_NORMAL,
			size = 9,
			color = COL.TEXTO_SECUNDARIO,
			sz = UDim2.new(1, -20, 1, 0),
			pos = UDim2.new(0, 18, 0, 0),
			alignX = Enum.TextXAlignment.Left,
		})
	end
	crearLegendItem("Normal", COL.CIAN_OSCURO)
	crearLegendItem("Defectuosa", COL.ROJO)
	crearLegendItem("Reparada", COL.AMARILLO)

	estado.btnCerrar.MouseButton1Click:Connect(function()
		if estado.onCerrar then estado.onCerrar() end
	end)

	estado.panelRoot = root
end

-- ════════════════════════════════════════════════════════════════
-- FORMATEO DE INFORMACIÓN POR ALGORITMO
-- ════════════════════════════════════════════════════════════════

local function formatearPesoCosto(nomA, nomB)
	local peso = GrafoHelpers.obtenerPeso(estado.nivelID, nomA, nomB, 0)
	if peso <= 0 then return nil end
	local cfg = LevelsConfig[estado.nivelID] or {}
	local costoPorMetro = cfg.CostoPorMetro or 0
	local texto = "Peso: " .. peso
	if costoPorMetro > 0 then
		texto = texto .. "  ·  Costo: " .. GrafoHelpers.formatearDinero(GrafoHelpers.calcularCosto(peso, costoPorMetro))
	end
	return texto
end

local function calcularCostoAcumulado(aristas)
	if not aristas or #aristas == 0 then return 0 end
	local total = 0
	for _, arista in ipairs(aristas) do
		local peso = GrafoHelpers.obtenerPeso(estado.nivelID, arista[1], arista[2], 1)
		total = total + peso
	end
	return total
end

local function formatearCostoTotal(aristas)
	local peso = calcularCostoAcumulado(aristas)
	if peso <= 0 then return nil end
	local cfg = LevelsConfig[estado.nivelID] or {}
	local costoPorMetro = cfg.CostoPorMetro or 0
	local texto = "Peso total: " .. peso
	if costoPorMetro > 0 then
		texto = texto .. "  ·  Costo total: " .. GrafoHelpers.formatearDinero(GrafoHelpers.calcularCosto(peso, costoPorMetro))
	end
	return texto
end

-- ════════════════════════════════════════════════════════════════
-- ACTUALIZACIÓN DEL PANEL DE INFORMACIÓN (con respeto al flag)
-- ════════════════════════════════════════════════════════════════

local function actualizarInfoPanel(step, pasoActual, totalPasos, algoritmo)
	if not step then return end

	-- Actualizar número de paso siempre
	estado.lblPasoValor.Text = pasoActual .. " / " .. totalPasos
	estado.lblPasoValor.TextColor3 = COL.CIAN

	-- Si estamos en modo espera nodo dañado, NO sobrescribir el mensaje ni su estilo
	if not estado.modoEsperaNodoDaniado then
		estado.lblMensaje.Text = step.descripcion or ""

		local msgStroke = estado.boxMensaje:FindFirstChildOfClass("UIStroke")
		local fuenteDefectuosos = estado.matrizData and estado.matrizData.Defectuosos or nil
		if step.aristaNueva and GrafoHelpers.esCableDefectuoso(fuenteDefectuosos or estado.nivelID, step.aristaNueva[1], step.aristaNueva[2]) then
			estado.boxMensaje.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
			msgStroke.Color = COL.ROJO
			estado.lblMensaje.TextColor3 = COL.ROJO
		else
			estado.boxMensaje.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
			msgStroke.Color = Color3.fromRGB(255, 200, 0)
			estado.lblMensaje.TextColor3 = COL.TEXTO_PRINCIPAL
		end
	end

	-- Resto de la información siempre se actualiza
	if algoritmo == "bfs" then
		estado.lblCostoLabel.Text = "DISTANCIA / NIVEL"
		estado.frmEstructura.Visible = true
		estado.lblEstructuraLabel.Text = "COLA (FIFO)"
		estado.lblEstructura.Text = listaAlias(step.structConten)
		estado.lblVisitados.Text = listaAlias(step.visitados)
		if step.distancias and step.nodoActual then
			local d = step.distancias[step.nodoActual]
			estado.lblCostoValor.Text = (d ~= nil) and tostring(d) or "—"
		else
			estado.lblCostoValor.Text = "—"
		end

	elseif algoritmo == "dfs" then
		estado.lblCostoLabel.Text = "PROFUNDIDAD"
		estado.frmEstructura.Visible = true
		estado.lblEstructuraLabel.Text = "PILA (LIFO)"
		estado.lblEstructura.Text = listaAlias(step.structConten)
		estado.lblVisitados.Text = listaAlias(step.visitados)
		estado.lblCostoValor.Text = #step.visitados

	elseif algoritmo == "dijkstra" then
		estado.lblCostoLabel.Text = "COSTO ESTIMADO (RUTA)"
		estado.frmEstructura.Visible = true
		estado.lblEstructuraLabel.Text = "COLA DE PRIORIDAD"
		estado.lblEstructura.Text = listaAlias(step.pendientes)
		estado.lblVisitados.Text = listaAlias(step.visitados)

		local textoCosto = "—"
		if step.distancias then
			local meta = estado.nodoFin and step.distancias[estado.nodoFin]
			if not meta or meta == "∞" then
				meta = step.nodoActual and step.distancias[step.nodoActual]
			end
			if meta and meta ~= "∞" then
				textoCosto = getAlias(estado.nodoFin or step.nodoActual) .. " : " .. tostring(meta)
			end
		end
		local infoTotal = formatearCostoTotal(step.aristasRecorridas)
		if infoTotal then
			textoCosto = textoCosto .. "\n" .. infoTotal
		end
		estado.lblCostoValor.Text = textoCosto

	elseif algoritmo == "prim" then
		estado.lblCostoLabel.Text = "COSTO TOTAL MST"
		estado.frmEstructura.Visible = true
		estado.lblEstructuraLabel.Text = "COLA DE PRIORIDAD"
		estado.lblEstructura.Text = listaAlias(step.pendientes)
		estado.lblVisitados.Text = listaAlias(step.visitados)

		local infoTotal = formatearCostoTotal(step.aristasRecorridas)
		estado.lblCostoValor.Text = infoTotal or "—"
	else
		estado.lblCostoLabel.Text = "INFO"
		estado.lblCostoValor.Text = "—"
	end
end

-- ════════════════════════════════════════════════════════════════
-- MANEJO DE BILLBOARDS DE NODO DAÑADO
-- ════════════════════════════════════════════════════════════════

local function crearBillboardNodoDaniado(nome, selector)
	if estado.billboardsDaniados[nome] then return end
	if not selector then return end
	local bb = BillboardNombres.crear(
		selector,
		"⚠️ REPARAR",
		"NODO_DANIADO",
		"NodoDanado_BB_" .. nome,
		{
			colorTexto = Color3.fromRGB(255, 80, 80),
			colorBorde = Color3.fromRGB(255, 80, 80),
		}
	)
	estado.billboardsDaniados[nome] = bb
end

-- ════════════════════════════════════════════════════════════════
-- API PÚBLICA
-- ════════════════════════════════════════════════════════════════

function PanelAlgoritmo3D.getAlias(nome)
	return getAlias(nome)
end

function PanelAlgoritmo3D.inicializar(hudGui)
	if estado.panelRoot then return end
	estado.hudGui = hudGui
	crearPanelUI()
end

function PanelAlgoritmo3D.mostrar(algoritmo, nodoInicio, nodoFin, matrizData, adyacencias)
	if not estado.panelRoot then return end

	estado.algoritmoActual = algoritmo
	estado.nodoInicio = nodoInicio
	estado.nodoFin = nodoFin
	estado.matrizData = matrizData
	estado.adyacencias = adyacencias or {}
	estado.nivelID = jugador:GetAttribute("CurrentLevelID") or 0
	estado.aristasReparadas = {}
	-- No reiniciar nodosReparados para persistir reparaciones
	PanelAlgoritmo3D.actualizarNodosDaniados((matrizData and matrizData.NodosDaniados) or {})
	estado.modoEsperaNodoDaniado = false

	local titulos = {
		bfs = "⚡ BÚSQUEDA EN ANCHURA",
		dfs = "⚡ BÚSQUEDA EN PROFUNDIDAD",
		dijkstra = "⚡ DIJKSTRA",
		prim = "⚡ PRIM",
	}
	estado.lblTitulo.Text = titulos[algoritmo] or "⚡ ALGORITMO"

	estado.lblPasoValor.Text = "0 / 0"
	estado.lblMensaje.Text = "Iniciando algoritmo..."
	estado.lblEstructura.Text = "—"
	estado.lblVisitados.Text = "—"
	estado.lblCostoValor.Text = "—"

	construirMinimapa()

	estado.panelRoot.Visible = true
	if estado.escala then
		estado.escala.Scale = 0.9
		TweenService:Create(estado.escala, TWEEN_APARECER, { Scale = 1 }):Play()
	end
end

function PanelAlgoritmo3D.ocultar()
	if not estado.panelRoot then return end
	estado.panelRoot.Visible = false
	limpiarMinimapa()
end

function PanelAlgoritmo3D.limpiar()
	estado.modoEsperaNodoDaniado = false

	for nome, bb in pairs(estado.billboardsDaniados) do
		if bb and bb.Parent then bb:Destroy() end
	end
	table.clear(estado.billboardsDaniados)

	if estado.panelRoot then
		estado.panelRoot:Destroy()
		estado.panelRoot = nil
	end
	estado.visor = nil
	estado.worldModel = nil
	estado.camara = nil
	estado.hudGui = nil
	estado.matrizData = nil
	estado.adyacencias = nil
	estado.btnCerrar = nil
	estado.onCerrar = nil
	estado.nodoParts = {}
	estado.aristaParts = {}
	estado.posiciones = {}
	estado.aristasReparadas = {}
	estado.nodosDaniados = {}
	table.clear(estado.nodosDaniadosSet)
	estado.nodosReparados = {}
end

function PanelAlgoritmo3D.aplicarPaso(step, pasoActual, totalPasos)
	if not estado.panelRoot or not estado.panelRoot.Visible then return end
	estado.pasoActual = pasoActual
	estado.totalPasos = totalPasos
	actualizarInfoPanel(step, pasoActual, totalPasos, estado.algoritmoActual)
	actualizarMinimapa(step)
end

function PanelAlgoritmo3D.desactivarModoEspera()
	estado.modoEsperaNodoDaniado = false
end

-- Mensajes que DESACTIVAN el modo espera y actualizan el mensaje
function PanelAlgoritmo3D.mostrarMensajeInfo(texto)
	estado.modoEsperaNodoDaniado = false
	if not estado.lblMensaje then return end
	estado.lblMensaje.Text = texto or ""
	estado.lblMensaje.TextColor3 = COL.TEXTO_PRINCIPAL
	local stroke = estado.boxMensaje:FindFirstChildOfClass("UIStroke")
	if stroke then stroke.Color = Color3.fromRGB(255, 200, 0) end
	estado.boxMensaje.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
end

function PanelAlgoritmo3D.mostrarMensajeEspera(aristaEsperada)
	estado.modoEsperaNodoDaniado = false
	if not estado.lblMensaje then return end
	local a = aristaEsperada and getAlias(aristaEsperada[1]) or "?"
	local b = aristaEsperada and getAlias(aristaEsperada[2]) or "?"
	estado.lblMensaje.Text = "⏳ Conecta la arista " .. a .. " → " .. b .. " para continuar."
	estado.lblMensaje.TextColor3 = COL.TEXTO_PRINCIPAL
	local stroke = estado.boxMensaje:FindFirstChildOfClass("UIStroke")
	if stroke then stroke.Color = Color3.fromRGB(255, 200, 0) end
	estado.boxMensaje.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
end

function PanelAlgoritmo3D.mostrarMensajeCorrecto(aristaEsperada)
	estado.modoEsperaNodoDaniado = false
	if not estado.lblMensaje then return end
	local a = aristaEsperada and getAlias(aristaEsperada[1]) or "?"
	local b = aristaEsperada and getAlias(aristaEsperada[2]) or "?"
	estado.lblMensaje.Text = "✅ Arista " .. a .. " → " .. b .. " correcta. Avanzando..."
	estado.lblMensaje.TextColor3 = COL.VERDE
	local stroke = estado.boxMensaje:FindFirstChildOfClass("UIStroke")
	if stroke then stroke.Color = COL.VERDE end
	estado.boxMensaje.BackgroundColor3 = COL.VERDE
end

function PanelAlgoritmo3D.mostrarMensajeDefectuoso(aristaEsperada)
	estado.modoEsperaNodoDaniado = false
	if not estado.lblMensaje then return end
	local a = aristaEsperada and getAlias(aristaEsperada[1]) or "?"
	local b = aristaEsperada and getAlias(aristaEsperada[2]) or "?"
	estado.lblMensaje.Text = "❌ Arista " .. a .. " → " .. b .. " defectuosa. Desconecta el cable y vuelve a conectar."
	estado.lblMensaje.TextColor3 = COL.ROJO
	local stroke = estado.boxMensaje:FindFirstChildOfClass("UIStroke")
	if stroke then stroke.Color = COL.ROJO end
	estado.boxMensaje.BackgroundColor3 = COL.ROJO
end

-- Mensaje de nodo dañado: ACTIVA el modo espera y crea billboard
function PanelAlgoritmo3D.mostrarMensajeNodoDaniado(nome, selector)
	if not estado.lblMensaje then return end
	local alias = getAlias(nome) or nome
	estado.lblMensaje.Text = "⚠️ El nodo " .. alias .. " está defectuoso. Acércate y repáralo para continuar."
	estado.lblMensaje.TextColor3 = COL.ROJO
	local stroke = estado.boxMensaje:FindFirstChildOfClass("UIStroke")
	if stroke then stroke.Color = COL.ROJO end
	estado.boxMensaje.BackgroundColor3 = COL.ROJO

	estado.modoEsperaNodoDaniado = true
	crearBillboardNodoDaniado(nome, selector)
end

function PanelAlgoritmo3D.repararArista(nomA, nomB)
	local key = GrafoHelpers.clavePar(nomA, nomB)
	estado.aristasReparadas[key] = true
	if estado.aristaParts[key] then
		colorArista(key, "reparada")
	end
end

function PanelAlgoritmo3D.nodoEstaDaniado(nome)
	if estado.nodosReparados[nome] then return false end
	return estado.nodosDaniadosSet[nome] == true
end

function PanelAlgoritmo3D.marcarNodoReparado(nome)
	estado.nodosReparados[nome] = true
	if estado.nodoParts[nome] then
		local part = estado.nodoParts[nome]
		part.Color = COL.AMARILLO
		part.Material = Enum.Material.Neon
	end
	-- Destruir billboard si existe
	if estado.billboardsDaniados[nome] then
		estado.billboardsDaniados[nome]:Destroy()
		estado.billboardsDaniados[nome] = nil
	end
end

function PanelAlgoritmo3D.setCerrarCallback(callback)
	estado.onCerrar = callback
end

function PanelAlgoritmo3D.actualizarNodosDaniados(lista)
	estado.nodosDaniados = lista or {}
	table.clear(estado.nodosDaniadosSet)
	for _, n in ipairs(estado.nodosDaniados) do
		estado.nodosDaniadosSet[n] = true
	end
end

function PanelAlgoritmo3D.estaVisible()
	return estado.panelRoot and estado.panelRoot.Visible
end

return PanelAlgoritmo3D