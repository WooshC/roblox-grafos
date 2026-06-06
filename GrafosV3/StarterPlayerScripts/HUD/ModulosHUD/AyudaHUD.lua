-- StarterPlayerScripts/HUD/ModulosHUD/AyudaHUD.lua
-- GUI de ayuda / guia de controles del juego (con paginacion)

local AyudaHUD = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local jugador = Players.LocalPlayer

local _hudGui = nil
local _frameAyuda = nil
local _panelAbierto = false
local _paginas = {}
local _btnPaginas = {}
local _paginaActual = 1

-- ═══════════════════════════════════════════════════════════════════════════════
-- PALETA DE COLORES (tema cian del juego)
-- ═══════════════════════════════════════════════════════════════════════════════
local C = {
	fondoPanel    = Color3.fromRGB(0, 15, 45),
	borde         = Color3.fromRGB(0, 200, 255),
	titulo        = Color3.fromRGB(0, 229, 255),
	texto         = Color3.fromRGB(200, 230, 255),
	textoMuted    = Color3.fromRGB(123, 216, 240),
	cardFondo     = Color3.fromRGB(0, 200, 255),
	cardBorde     = Color3.fromRGB(0, 200, 255),
	keyFondo      = Color3.fromRGB(0, 160, 210),
	keyTexto      = Color3.fromRGB(0, 229, 255),
	divider       = Color3.fromRGB(0, 200, 255),
	btnNavOff     = Color3.fromRGB(0, 200, 255),
	btnNavOn      = Color3.fromRGB(0, 229, 255),
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- CREAR GUI
-- ═══════════════════════════════════════════════════════════════════════════════

function AyudaHUD.init(hudGui)
	_hudGui = hudGui

	-- Fondo oscuro que cubre toda la pantalla
	_frameAyuda = Instance.new("Frame")
	_frameAyuda.Name = "PantallaAyuda"
	_frameAyuda.Size = UDim2.new(1, 0, 1, 0)
	_frameAyuda.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	_frameAyuda.BackgroundTransparency = 0.45
	_frameAyuda.BorderSizePixel = 0
	_frameAyuda.Visible = false
	_frameAyuda.ZIndex = 100
	_frameAyuda.Parent = _hudGui

	-- Panel central
	local panel = Instance.new("Frame")
	panel.Name = "PanelAyuda"
	panel.Size = UDim2.new(0, 660, 0, 500)
	panel.Position = UDim2.new(0.5, 0, 0.5, 0)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.BackgroundColor3 = C.fondoPanel
	panel.BackgroundTransparency = 0.05
	panel.BorderSizePixel = 0
	panel.ZIndex = 101
	panel.Parent = _frameAyuda

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 12)
	panelCorner.Parent = panel

	local panelStroke = Instance.new("UIStroke")
	panelStroke.Color = C.borde
	panelStroke.Thickness = 2
	panelStroke.Transparency = 0.2
	panelStroke.Parent = panel

	-- Sombra del panel
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.Size = UDim2.new(1, 40, 1, 40)
	shadow.Position = UDim2.new(0, -20, 0, -20)
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://1316045217"
	shadow.ImageColor3 = Color3.fromRGB(0, 200, 255)
	shadow.ImageTransparency = 0.85
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(10, 10, 118, 118)
	shadow.ZIndex = 100
	shadow.Parent = panel

	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 54)
	header.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
	header.BackgroundTransparency = 0.92
	header.BorderSizePixel = 0
	header.ZIndex = 102
	header.Parent = panel

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 12)
	headerCorner.Parent = header

	local headerFix = Instance.new("Frame")
	headerFix.Size = UDim2.new(1, 0, 0.5, 0)
	headerFix.Position = UDim2.new(0, 0, 0.5, 0)
	headerFix.BackgroundColor3 = header.BackgroundColor3
	headerFix.BackgroundTransparency = header.BackgroundTransparency
	headerFix.BorderSizePixel = 0
	headerFix.ZIndex = 102
	headerFix.Parent = header

	local tituloLabel = Instance.new("TextLabel")
	tituloLabel.Name = "Titulo"
	tituloLabel.Size = UDim2.new(1, -60, 1, 0)
	tituloLabel.Position = UDim2.new(0, 20, 0, 0)
	tituloLabel.BackgroundTransparency = 1
	tituloLabel.Text = "AYUDA  —  GUÍA DEL SISTEMA"
	tituloLabel.TextColor3 = C.titulo
	tituloLabel.Font = Enum.Font.GothamBold
	tituloLabel.TextSize = 20
	tituloLabel.TextXAlignment = Enum.TextXAlignment.Left
	tituloLabel.ZIndex = 103
	tituloLabel.Parent = header

	-- Boton cerrar (X)
	local btnCerrar = Instance.new("TextButton")
	btnCerrar.Name = "BtnCerrarAyuda"
	btnCerrar.Size = UDim2.new(0, 32, 0, 32)
	btnCerrar.Position = UDim2.new(1, -42, 0.5, -16)
	btnCerrar.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
	btnCerrar.BackgroundTransparency = 0.85
	btnCerrar.Text = "X"
	btnCerrar.TextColor3 = C.titulo
	btnCerrar.Font = Enum.Font.GothamBold
	btnCerrar.TextSize = 16
	btnCerrar.BorderSizePixel = 0
	btnCerrar.AutoButtonColor = true
	btnCerrar.ZIndex = 103
	btnCerrar.Parent = header

	local btnCerrarCorner = Instance.new("UICorner")
	btnCerrarCorner.CornerRadius = UDim.new(0, 6)
	btnCerrarCorner.Parent = btnCerrar

	local btnCerrarStroke = Instance.new("UIStroke")
	btnCerrarStroke.Color = C.borde
	btnCerrarStroke.Thickness = 1.5
	btnCerrarStroke.Transparency = 0.4
	btnCerrarStroke.Parent = btnCerrar

	btnCerrar.MouseButton1Click:Connect(AyudaHUD.ocultar)

	-- Barra de navegacion (paginas 1, 2, 3)
	local navFrame = Instance.new("Frame")
	navFrame.Name = "NavPaginas"
	navFrame.Size = UDim2.new(1, -40, 0, 36)
	navFrame.Position = UDim2.new(0, 20, 0, 62)
	navFrame.BackgroundTransparency = 1
	navFrame.ZIndex = 102
	navFrame.Parent = panel

	local navLayout = Instance.new("UIListLayout")
	navLayout.FillDirection = Enum.FillDirection.Horizontal
	navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	navLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	navLayout.Padding = UDim.new(0, 12)
	navLayout.Parent = navFrame

	local nombresPaginas = { "Botones Principales", "Controles del Teclado", "Otros" }
	for i = 1, 3 do
		local btn = Instance.new("TextButton")
		btn.Name = "BtnPagina" .. i
		btn.Size = UDim2.new(0, 170, 0, 32)
		btn.BackgroundColor3 = C.fondoPanel
		btn.BackgroundTransparency = 0.3
		btn.BorderSizePixel = 0
		btn.Text = nombresPaginas[i]
		btn.TextColor3 = Color3.fromRGB(150, 210, 230)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 12
		btn.ZIndex = 103
		btn.Parent = navFrame

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = btn

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(0, 200, 255)
		stroke.Thickness = 1
		stroke.Transparency = 0.6
		stroke.Parent = btn

		btn.MouseButton1Click:Connect(function()
			_mostrarPagina(i)
		end)

		_btnPaginas[i] = { btn = btn, stroke = stroke }
	end

	-- Contenedor de paginas
	local contenedorPaginas = Instance.new("Frame")
	contenedorPaginas.Name = "ContenedorPaginas"
	contenedorPaginas.Size = UDim2.new(1, -32, 1, -116)
	contenedorPaginas.Position = UDim2.new(0, 16, 0, 104)
	contenedorPaginas.BackgroundTransparency = 1
	contenedorPaginas.BorderSizePixel = 0
	contenedorPaginas.ZIndex = 102
	contenedorPaginas.Parent = panel

	-- ═══════════════════════════════════════════════════════════════════════════
	-- PAGINA 1: BOTONES PRINCIPALES
	-- ═══════════════════════════════════════════════════════════════════════════
	local pagina1 = Instance.new("Frame")
	pagina1.Name = "PaginaBotones"
	pagina1.Size = UDim2.new(1, 0, 1, 0)
	pagina1.BackgroundTransparency = 1
	pagina1.ZIndex = 103
	pagina1.Parent = contenedorPaginas

	local titulo1 = _crearTituloSeccion(pagina1, "◆  BOTONES PRINCIPALES")
	titulo1.Position = UDim2.new(0, 0, 0, 0)

	local gridBotones = Instance.new("Frame")
	gridBotones.Name = "GridBotones"
	gridBotones.Size = UDim2.new(1, 0, 1, -28)
	gridBotones.Position = UDim2.new(0, 0, 0, 28)
	gridBotones.BackgroundTransparency = 1
	gridBotones.ZIndex = 103
	gridBotones.Parent = pagina1

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 200, 0, 118)
	gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = gridBotones

	_crearCardBoton(gridBotones, "🗺️", "VER MAPA", "Abre el mapa cenital del nivel. Muestra nodos, conexiones y zonas desde una vista aérea.")
	_crearCardBoton(gridBotones, "📋", "MISIONES", "Panel lateral con las misiones activas del nivel y su progreso.")
	_crearCardBoton(gridBotones, "🔢", "MATEMÁTICO", "Muestra la tabla de conexiones entre nodos en formato matricial.")
	_crearCardBoton(gridBotones, "📊", "ANÁLISIS", "Ejecuta algoritmos de grafos sobre el nivel actual: BFS, DFS, Dijistra, Prim.")
	_crearCardBoton(gridBotones, "▶", "EJECUTAR ALGORITMO", "Elige entre la lista de algoritmos y comparalos en un mundo 3D. Presiona el mismo botón para detener.")
	_crearCardBoton(gridBotones, "🔄", "REINICIAR", "Reinicia el nivel actual desde el principio. Se pierde el progreso actual.")
	_crearCardBoton(gridBotones, "🚪", "SALIR", "Sale del nivel actual. No guarda el progreso del nivel.")

	_paginas[1] = pagina1

	-- ═══════════════════════════════════════════════════════════════════════════
	-- PAGINA 2: CONTROLES DE TECLADO
	-- ═══════════════════════════════════════════════════════════════════════════
	local pagina2 = Instance.new("Frame")
	pagina2.Name = "PaginaTeclado"
	pagina2.Size = UDim2.new(1, 0, 1, 0)
	pagina2.BackgroundTransparency = 1
	pagina2.Visible = false
	pagina2.ZIndex = 103
	pagina2.Parent = contenedorPaginas

	local titulo2 = _crearTituloSeccion(pagina2, "◆  CONTROLES DE TECLADO")
	titulo2.Position = UDim2.new(0, 0, 0, 0)

	local gridTeclas = Instance.new("Frame")
	gridTeclas.Name = "GridTeclas"
	gridTeclas.Size = UDim2.new(1, 0, 1, -28)
	gridTeclas.Position = UDim2.new(0, 0, 0, 28)
	gridTeclas.BackgroundTransparency = 1
	gridTeclas.ZIndex = 103
	gridTeclas.Parent = pagina2

	local gridTeclasLayout = Instance.new("UIGridLayout")
	gridTeclasLayout.CellSize = UDim2.new(0, 290, 0, 52)
	gridTeclasLayout.CellPadding = UDim2.new(0, 14, 0, 14)
	gridTeclasLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridTeclasLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	gridTeclasLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridTeclasLayout.Parent = gridTeclas

	_crearControlTeclado(gridTeclas, "M", "Abrir / cerrar Mapa Cenital")
	_crearControlTeclado(gridTeclas, "T", "Abrir / cerrar Panel de Análisis")
	_crearControlTeclado(gridTeclas, "F", "Abrir / cerrar Matriz de Adyacencia")
	_crearControlTeclado(gridTeclas, "Y", "Abrir / cerrar Panel de Misiones")
	_crearControlTeclado(gridTeclas, "SPACE", "Continuar diálogo / completar texto")

	_paginas[2] = pagina2

	-- ═══════════════════════════════════════════════════════════════════════════
	-- PAGINA 3: OTROS (Minimapa + Guía Visual)
	-- ═══════════════════════════════════════════════════════════════════════════
	local pagina3 = Instance.new("Frame")
	pagina3.Name = "PaginaOtros"
	pagina3.Size = UDim2.new(1, 0, 1, 0)
	pagina3.BackgroundTransparency = 1
	pagina3.Visible = false
	pagina3.ZIndex = 103
	pagina3.Parent = contenedorPaginas

	local titulo3a = _crearTituloSeccion(pagina3, "◆  MINIMAPA")
	titulo3a.Position = UDim2.new(0, 0, 0, 0)

	local textoMinimap = Instance.new("TextLabel")
	textoMinimap.Size = UDim2.new(1, 0, 0, 0)
	textoMinimap.Position = UDim2.new(0, 0, 0, 28)
	textoMinimap.BackgroundTransparency = 1
	textoMinimap.Text = "El minimapa aparece en la esquina inferior derecha de la pantalla.\nMuestra en tiempo real tu posición, los nodos cercanos y las rutas trazadas."
	textoMinimap.TextColor3 = C.textoMuted
	textoMinimap.Font = Enum.Font.Gotham
	textoMinimap.TextSize = 14
	textoMinimap.TextXAlignment = Enum.TextXAlignment.Left
	textoMinimap.TextWrapped = true
	textoMinimap.AutomaticSize = Enum.AutomaticSize.Y
	textoMinimap.ZIndex = 104
	textoMinimap.Parent = pagina3

	local titulo3b = _crearTituloSeccion(pagina3, "◆  GUÍA VISUAL")
	titulo3b.Position = UDim2.new(0, 0, 0, 100)

	local textoGuia = Instance.new("TextLabel")
	textoGuia.Size = UDim2.new(1, 0, 0, 0)
	textoGuia.Position = UDim2.new(0, 0, 0, 128)
	textoGuia.BackgroundTransparency = 1
	textoGuia.Text = "Un beam amarillo con flechas animadas guía hacia el siguiente objetivo.\nSigue la dirección del beacon flotante para completar las misiones.\nLa guía avanza automáticamente al completar cada zona."
	textoGuia.TextColor3 = C.textoMuted
	textoGuia.Font = Enum.Font.Gotham
	textoGuia.TextSize = 14
	textoGuia.TextXAlignment = Enum.TextXAlignment.Left
	textoGuia.TextWrapped = true
	textoGuia.AutomaticSize = Enum.AutomaticSize.Y
	textoGuia.ZIndex = 104
	textoGuia.Parent = pagina3

	_paginas[3] = pagina3

	-- Iniciar en pagina 1
	_mostrarPagina(1)

	-- Cerrar al presionar Escape o clic fuera del panel
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not _panelAbierto then return end
		if gameProcessed then return end
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Escape then
			AyudaHUD.ocultar()
		end
	end)

	_frameAyuda.InputBegan:Connect(function(input)
		if not _panelAbierto then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local mousePos = UserInputService:GetMouseLocation()
			local panelAbsPos = panel.AbsolutePosition
			local panelAbsSize = panel.AbsoluteSize
			if mousePos.X < panelAbsPos.X or mousePos.X > panelAbsPos.X + panelAbsSize.X
				or mousePos.Y < panelAbsPos.Y or mousePos.Y > panelAbsPos.Y + panelAbsSize.Y then
				AyudaHUD.ocultar()
			end
		end
	end)

	print("[AyudaHUD] GUI de ayuda inicializada con paginacion")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- PAGINACION
-- ═══════════════════════════════════════════════════════════════════════════════

function _mostrarPagina(numero)
	for i, pagina in ipairs(_paginas) do
		pagina.Visible = (i == numero)
	end
	for i, data in ipairs(_btnPaginas) do
		local activo = (i == numero)
		-- Alto contraste: activo = fondo cian brillante + texto oscuro
		-- Inactivo = fondo transparente + texto cian apagado
		data.btn.TextColor3 = activo and Color3.fromRGB(0, 15, 45) or Color3.fromRGB(150, 210, 230)
		data.btn.BackgroundColor3 = activo and Color3.fromRGB(0, 200, 255) or C.fondoPanel
		data.btn.BackgroundTransparency = activo and 0.1 or 0.3
		data.stroke.Color = activo and Color3.fromRGB(0, 229, 255) or Color3.fromRGB(0, 200, 255)
		data.stroke.Transparency = activo and 0.0 or 0.6
	end
	_paginaActual = numero
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPERS VISUALES
-- ═══════════════════════════════════════════════════════════════════════════════

function _crearTituloSeccion(parent, texto)
	local frame = Instance.new("Frame")
	frame.Name = "TituloSeccion_" .. texto:gsub("[^%w]", "")
	frame.Size = UDim2.new(1, 0, 0, 24)
	frame.BackgroundTransparency = 1
	frame.ZIndex = 104
	frame.Parent = parent

	local barra = Instance.new("Frame")
	barra.Size = UDim2.new(0, 3, 0, 16)
	barra.Position = UDim2.new(0, 0, 0.5, -8)
	barra.BackgroundColor3 = C.borde
	barra.BorderSizePixel = 0
	barra.ZIndex = 104
	barra.Parent = frame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -12, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = texto
	label.TextColor3 = Color3.fromRGB(0, 200, 255)
	label.TextTransparency = 0.35
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 104
	label.Parent = frame

	return frame
end

function _crearCardBoton(parent, icono, nombre, descripcion)
	local card = Instance.new("Frame")
	card.Name = "Card_" .. nombre:gsub("[^%w]", "")
	card.Size = UDim2.new(0, 200, 0, 118)
	card.BackgroundColor3 = C.cardFondo
	card.BackgroundTransparency = 0.94
	card.BorderSizePixel = 0
	card.ZIndex = 104
	card.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = C.cardBorde
	stroke.Thickness = 1
	stroke.Transparency = 0.7
	stroke.Parent = card

	local lblIcono = Instance.new("TextLabel")
	lblIcono.Name = "Icono"
	lblIcono.Size = UDim2.new(0, 30, 0, 30)
	lblIcono.Position = UDim2.new(0, 12, 0, 10)
	lblIcono.BackgroundTransparency = 1
	lblIcono.Text = icono
	lblIcono.TextColor3 = C.titulo
	lblIcono.Font = Enum.Font.GothamBold
	lblIcono.TextSize = 22
	lblIcono.ZIndex = 105
	lblIcono.Parent = card

	local lblNombre = Instance.new("TextLabel")
	lblNombre.Name = "Nombre"
	lblNombre.Size = UDim2.new(1, -16, 0, 20)
	lblNombre.Position = UDim2.new(0, 8, 0, 44)
	lblNombre.BackgroundTransparency = 1
	lblNombre.Text = nombre
	lblNombre.TextColor3 = C.titulo
	lblNombre.Font = Enum.Font.GothamBold
	lblNombre.TextSize = 13
	lblNombre.TextXAlignment = Enum.TextXAlignment.Left
	lblNombre.ZIndex = 105
	lblNombre.Parent = card

	local lblDesc = Instance.new("TextLabel")
	lblDesc.Name = "Descripcion"
	lblDesc.Size = UDim2.new(1, -16, 0, 0)
	lblDesc.Position = UDim2.new(0, 8, 0, 64)
	lblDesc.BackgroundTransparency = 1
	lblDesc.Text = descripcion
	lblDesc.TextColor3 = C.textoMuted
	lblDesc.Font = Enum.Font.Gotham
	lblDesc.TextSize = 12
	lblDesc.TextXAlignment = Enum.TextXAlignment.Left
	lblDesc.TextWrapped = true
	lblDesc.AutomaticSize = Enum.AutomaticSize.Y
	lblDesc.ZIndex = 105
	lblDesc.Parent = card
end

function _crearControlTeclado(parent, tecla, descripcion)
	local ctrl = Instance.new("Frame")
	ctrl.Name = "Ctrl_" .. tecla
	ctrl.Size = UDim2.new(0, 290, 0, 52)
	ctrl.BackgroundColor3 = C.cardFondo
	ctrl.BackgroundTransparency = 0.95
	ctrl.BorderSizePixel = 0
	ctrl.ZIndex = 104
	ctrl.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = ctrl

	local stroke = Instance.new("UIStroke")
	stroke.Color = C.cardBorde
	stroke.Thickness = 1
	stroke.Transparency = 0.8
	stroke.Parent = ctrl

	local keyLabel = Instance.new("TextLabel")
	keyLabel.Name = "Key"
	keyLabel.Size = UDim2.new(0, 0, 0, 28)
	keyLabel.AutomaticSize = Enum.AutomaticSize.X
	keyLabel.Position = UDim2.new(0, 10, 0.5, -14)
	keyLabel.BackgroundColor3 = C.keyFondo
	keyLabel.BackgroundTransparency = 0.75
	keyLabel.BorderSizePixel = 0
	keyLabel.Text = "  " .. tecla .. "  "
	keyLabel.TextColor3 = C.keyTexto
	keyLabel.Font = Enum.Font.GothamBold
	keyLabel.TextSize = 14
	keyLabel.ZIndex = 105
	keyLabel.Parent = ctrl

	local keyCorner = Instance.new("UICorner")
	keyCorner.CornerRadius = UDim.new(0, 4)
	keyCorner.Parent = keyLabel

	local keyStroke = Instance.new("UIStroke")
	keyStroke.Color = C.borde
	keyStroke.Thickness = 1
	keyStroke.Transparency = 0.5
	keyStroke.Parent = keyLabel

	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "Desc"
	descLabel.Size = UDim2.new(1, -80, 1, 0)
	descLabel.Position = UDim2.new(0, 66, 0, 0)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = descripcion
	descLabel.TextColor3 = C.textoMuted
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 13
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.ZIndex = 105
	descLabel.Parent = ctrl
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- API PUBLICA
-- ═══════════════════════════════════════════════════════════════════════════════

function AyudaHUD.mostrar()
	if not _frameAyuda then return end
	_panelAbierto = true
	_frameAyuda.Visible = true
	_mostrarPagina(1)

	-- Tween de entrada
	local panel = _frameAyuda:FindFirstChild("PanelAyuda")
	if panel then
		panel.Size = UDim2.new(0, 600, 0, 440)
		panel.BackgroundTransparency = 0.3
		TweenService:Create(panel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 660, 0, 500),
			BackgroundTransparency = 0.05
		}):Play()
	end
end

function AyudaHUD.ocultar()
	if not _frameAyuda then return end
	_panelAbierto = false
	_frameAyuda.Visible = false
end

function AyudaHUD.alternar()
	if _panelAbierto then
		AyudaHUD.ocultar()
	else
		AyudaHUD.mostrar()
	end
end

return AyudaHUD
