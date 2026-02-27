-- StarterPlayerScripts/Menu/ControladorMenu.client.lua
-- Controlador de la UI de seleccion de niveles
-- Adaptado para la GUI creada por crearGUIMenu.lua

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")

local jugador = Players.LocalPlayer
local playerGui = jugador:WaitForChild("PlayerGui")
local camara = workspace.CurrentCamera

-- Referencias a GUI (estructura de crearGUIMenu.lua)
local menuGui = playerGui:WaitForChild("EDAQuestMenu")
local frameMenu = menuGui:WaitForChild("FrameMenu")
local frameLevels = menuGui:WaitForChild("FrameLevels")
local frameSettings = menuGui:WaitForChild("FrameSettings")
local frameCredits = menuGui:WaitForChild("FrameCredits")
local frameExit = menuGui:WaitForChild("FrameExit")

-- Componentes de FrameLevels
local levelMainArea = frameLevels:WaitForChild("LevelMainArea")
local levelSidebar = levelMainArea:WaitForChild("LevelSidebar")
local gridArea = levelMainArea:WaitForChild("GridArea")
local topBar = frameLevels:WaitForChild("LevelTopBar")
local topCenter = topBar:WaitForChild("TopCenter")
local backBtn = topCenter:WaitForChild("BackBtn")
local playerTag = topCenter:FindFirstChild("PlayerTagBox", true):FindFirstChild("PlayerTag")

-- Sidebar components
local placeholder = levelSidebar:WaitForChild("Placeholder")
local infoContent = levelSidebar:WaitForChild("InfoContent")
local playButton = levelSidebar:FindFirstChild("PlayButton", true)

-- Cargar configuracion de niveles
local LevelsConfig = require(RS:WaitForChild("Config"):WaitForChild("LevelsConfig"))

-- Eventos
local eventos = RS:WaitForChild("EventosGrafosV3")
local remotos = eventos:WaitForChild("Remotos")
local obtenerProgresoFn = remotos:WaitForChild("ObtenerProgresoJugador")
local iniciarNivelEvento = remotos:WaitForChild("IniciarNivel")
local nivelListoEvento = remotos:WaitForChild("NivelListo")
local nivelDescargadoEvento = remotos:WaitForChild("NivelDescargado")

-- Variables de estado
local nivelSeleccionado = nil
local datosNiveles = {}
local cargando = false
local progresoCargado = false

-- ============================================
-- PALETA Y CONSTANTES (de crearGUIMenu.lua)
-- ============================================

local COLORES = {
	accent     = Color3.fromRGB(0, 212, 255),
	accentExito = Color3.fromRGB(16, 185, 129),
	panel      = Color3.fromRGB(17, 25, 39),
	fondo      = Color3.fromRGB(4, 7, 14),
	borde      = Color3.fromRGB(30, 45, 66),
	muted      = Color3.fromRGB(100, 116, 139),
	dim        = Color3.fromRGB(55, 65, 81),
	oro        = Color3.fromRGB(245, 158, 11),
	texto      = Color3.fromRGB(226, 232, 240),
	black      = Color3.fromRGB(0, 0, 0),
}

local ESTADO_COLORES = {
	completado = Color3.fromRGB(245, 158, 11),
	disponible = Color3.fromRGB(16, 185, 129),
	bloqueado  = Color3.fromRGB(100, 116, 139),
}

local ESTADO_TEXTOS = {
	completado = "COMPLETADO",
	disponible = "JUGAR",
	bloqueado  = "BLOQUEADO",
}

local FUENTES = {
	mono  = Enum.Font.RobotoMono,
	bold  = Enum.Font.GothamBold,
	body  = Enum.Font.Gotham,
	title = Enum.Font.GothamBlack,
}

-- ============================================
-- FUNCIONES UTILES
-- ============================================

local function tween(objeto, propiedades, tiempo)
	local info = TweenInfo.new(tiempo or 0.3)
	local tw = TweenService:Create(objeto, info, propiedades)
	tw:Play()
	return tw
end

local function crearInstancia(clase, props, parent)
	local inst = Instance.new(clase)
	for k, v in pairs(props) do
		inst[k] = v
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function crearEsquina(radio, parent)
	return crearInstancia("UICorner", {CornerRadius = UDim.new(0, radio)}, parent)
end

local function crearBorde(color, grosor, parent)
	return crearInstancia("UIStroke", {Color = color, Thickness = grosor}, parent)
end

local function formatearTiempo(segundos)
	if not segundos or segundos <= 0 then
		return "0:00"
	end
	return string.format("%d:%02d", math.floor(segundos / 60), math.floor(segundos % 60))
end

-- ============================================
-- CONFIGURAR CAMARA DEL MENU
-- ============================================

local function configurarCamaraMenu()
	local camaraMenu = workspace:FindFirstChild("CamaraMenu")
	if camaraMenu then
		local parte = camaraMenu:IsA("BasePart") and camaraMenu or camaraMenu.PrimaryPart
		if parte then
			camara.CameraType = Enum.CameraType.Scriptable
			camara.CFrame = parte.CFrame
		end
	end
end

-- ============================================
-- NAVEGACION ENTRE FRAMES
-- ============================================

local function mostrarMenuPrincipal()
	frameMenu.Visible = true
	frameLevels.Visible = false
	frameSettings.Visible = false
	frameCredits.Visible = false
	frameExit.Visible = false
	configurarCamaraMenu()
end

local function mostrarSelectorNiveles()
	frameMenu.Visible = false
	frameLevels.Visible = true
	frameSettings.Visible = false
	frameCredits.Visible = false
	frameExit.Visible = false

	-- Cargar progreso si no está cargado
	if not progresoCargado then
		cargarProgreso()
	end
end

local function abrirModal(modal)
	if modal then
		modal.Visible = true
	end
end

local function cerrarModal(modal)
	if modal then
		modal.Visible = false
	end
end

-- ============================================
-- CONSTRUCCION DE TARJETAS
-- ============================================

local function crearTarjetaNivel(datosNivel, columna, fila, parent)
	local idNivel = datosNivel.nivelID
	local estado = datosNivel.status or "bloqueado"
	local colorEstado = ESTADO_COLORES[estado] or COLORES.muted

	-- Contenedor de la tarjeta (usar tamaño similar a GrafosV2)
	local tarjeta = crearInstancia("TextButton", {
		Name = "Card" .. idNivel,
		Size = UDim2.new(0.5, -8, 0, 140),
		Position = UDim2.new(columna == 1 and 0 or 0.5, columna == 1 and 4 or 0, 0, fila * 156),
		BackgroundColor3 = COLORES.panel,
		Text = "",
		BorderSizePixel = 0,
		ZIndex = 5,
	}, parent)
	crearEsquina(10, tarjeta)
	crearBorde(COLORES.borde, 1, tarjeta)

	-- Imagen del nivel
	if datosNivel.imageId and datosNivel.imageId ~= "" then
		local imagen = crearInstancia("ImageLabel", {
			Size = UDim2.new(1, 0, 0, 70),
			BackgroundTransparency = 1,
			Image = datosNivel.imageId,
			ScaleType = Enum.ScaleType.Crop,
			ZIndex = 6,
		}, tarjeta)
		crearEsquina(10, imagen)
	end

	-- Badge de estado
	local badge = crearInstancia("Frame", {
		Size = UDim2.new(0, 90, 0, 18),
		Position = UDim2.new(0, 8, 0, 74),
		BackgroundColor3 = COLORES.fondo,
		BorderSizePixel = 0,
		ZIndex = 7,
	}, tarjeta)
	crearEsquina(6, badge)
	crearBorde(colorEstado, 1, badge)

	crearInstancia("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = estado == "completado" and "◆ COMPLETADO" or (estado == "disponible" and "◆ DISPONIBLE" or "🔒 BLOQUEADO"),
		TextColor3 = colorEstado,
		Font = FUENTES.mono,
		TextSize = 9,
		ZIndex = 8,
	}, badge)

	-- Nombre del nivel
	crearInstancia("TextLabel", {
		Size = UDim2.new(1, -16, 0, 26),
		Position = UDim2.new(0, 8, 0, 96),
		BackgroundTransparency = 1,
		Text = datosNivel.nombre or "Nivel " .. idNivel,
		TextColor3 = COLORES.texto,
		Font = FUENTES.bold,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 6,
	}, tarjeta)

	-- Footer con estrellas y puntuacion
	local footer = crearInstancia("Frame", {
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.new(0, 0, 1, -22),
		BackgroundColor3 = Color3.fromRGB(10, 10, 18),
		BorderSizePixel = 0,
		ZIndex = 6,
	}, tarjeta)
	crearEsquina(10, footer)

	local estrellas = datosNivel.estrellas or 0
	crearInstancia("TextLabel", {
		Size = UDim2.new(0, 60, 1, 0),
		Position = UDim2.new(0, 6, 0, 0),
		BackgroundTransparency = 1,
		Text = (estrellas >= 1 and "⭐" or "☆") .. (estrellas >= 2 and "⭐" or "☆") .. (estrellas >= 3 and "⭐" or "☆"),
		TextColor3 = COLORES.oro,
		Font = FUENTES.body,
		TextSize = 12,
		ZIndex = 7,
	}, footer)

	local puntuacion = datosNivel.highScore or 0
	crearInstancia("TextLabel", {
		Size = UDim2.new(0, 60, 1, 0),
		Position = UDim2.new(1, -66, 0, 0),
		BackgroundTransparency = 1,
		Text = puntuacion > 0 and (puntuacion .. " pts") or "—",
		TextColor3 = COLORES.dim,
		Font = FUENTES.mono,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 7,
	}, footer)

	-- Interacciones (permitir ver detalles en todos los niveles)
	tarjeta.MouseButton1Click:Connect(function()
		if cargando then return end
		nivelSeleccionado = idNivel
		actualizarSidebar(datosNivel)

		-- Actualizar borde de seleccion
		for _, hijo in ipairs(parent:GetDescendants()) do
			if hijo:IsA("TextButton") and hijo.Name:match("Card%d+") then
				local bordeInst = hijo:FindFirstChildOfClass("UIStroke")
				if bordeInst then
					local esSeleccionada = hijo == tarjeta
					local idTarjeta = tonumber(hijo.Name:match("Card(%d+)"))
					local datosTarjeta = datosNiveles[tostring(idTarjeta)]
					local colorCompletado = datosTarjeta and datosTarjeta.status == "completado" and COLORES.oro or COLORES.borde

					bordeInst.Color = esSeleccionada and COLORES.accent or colorCompletado
					bordeInst.Thickness = esSeleccionada and 2 or 1
				end
			end
		end
	end)

	if estado ~= "bloqueado" then
		tarjeta.MouseEnter:Connect(function()
			tween(tarjeta, {BackgroundColor3 = Color3.fromRGB(51, 65, 85)}, 0.2)
		end)

		tarjeta.MouseLeave:Connect(function()
			tween(tarjeta, {BackgroundColor3 = COLORES.panel}, 0.2)
		end)
	else
		-- Niveles bloqueados: permitir hover suave pero diferente
		tarjeta.MouseEnter:Connect(function()
			tween(tarjeta, {BackgroundColor3 = Color3.fromRGB(25, 35, 55)}, 0.2)
		end)

		tarjeta.MouseLeave:Connect(function()
			tween(tarjeta, {BackgroundColor3 = Color3.fromRGB(15, 23, 42)}, 0.2)
		end)
		tarjeta.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
		tarjeta.BackgroundTransparency = 0.3
	end

	return tarjeta
end

-- ============================================
-- SIDEBAR CON DETALLES DEL NIVEL
-- ============================================

function actualizarSidebar(datosNivel)
	-- Mostrar InfoContent, ocultar Placeholder
	placeholder.Visible = false
	infoContent.Visible = true

	local colorEstado = ESTADO_COLORES[datosNivel.status] or COLORES.muted

	-- Hero section
	local hero = infoContent:FindFirstChild("Hero")
	if hero then
		local bgColor = datosNivel.status == "completado" and Color3.fromRGB(26, 18, 4)
			or datosNivel.status == "disponible" and Color3.fromRGB(4, 26, 18)
			or Color3.fromRGB(14, 14, 20)
		hero.BackgroundColor3 = bgColor

		-- Hero glow color
		local heroGlow = hero:FindFirstChild("HeroGlow")
		if heroGlow then
			tween(heroGlow, {BackgroundColor3 = colorEstado}, 0.2)
		end

		-- Imagen
		local heroImage = hero:FindFirstChild("HeroImage")
		local heroEmoji = hero:FindFirstChild("HeroEmoji")
		if datosNivel.imageId and datosNivel.imageId ~= "" then
			if not heroImage then
				heroImage = crearInstancia("ImageLabel", {
					Name = "HeroImage",
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Image = datosNivel.imageId,
					ScaleType = Enum.ScaleType.Crop,
					ZIndex = 6,
				}, hero)
			else
				heroImage.Image = datosNivel.imageId
				heroImage.Visible = true
			end
			if heroEmoji then
				heroEmoji.Visible = false
			end
		elseif heroImage then
			heroImage.Visible = false
			if heroEmoji then
				heroEmoji.Visible = true
			end
		end

		-- Badge de estado
		local heroBadge = hero:FindFirstChild("HeroBadge")
		local heroBadgeText = heroBadge and heroBadge:FindFirstChild("HeroBadgeText")
		if heroBadge then
			heroBadge.BackgroundColor3 = bgColor
			local stroke = heroBadge:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = colorEstado
			end
		end
		if heroBadgeText then
			heroBadgeText.Text = datosNivel.status == "completado" and "◆ COMPLETADO" or "◆ DISPONIBLE"
			heroBadgeText.TextColor3 = colorEstado
		end
	end

	-- Info body
	local infoBody = infoContent:FindFirstChild("InfoBody")
	if infoBody then
		local infoTag = infoBody:FindFirstChild("InfoTag")
		local infoName = infoBody:FindFirstChild("InfoName")
		local infoDesc = infoBody:FindFirstChild("InfoDesc")

		if infoTag then
			infoTag.Text = datosNivel.tag or ""
		end
		if infoName then
			infoName.Text = datosNivel.nombre or ""
		end
		if infoDesc then
			infoDesc.Text = datosNivel.descripcion or ""
		end

		-- Estrellas grandes
		local starsFrame = infoBody:FindFirstChild("Stars")
		if starsFrame then
			for i = 1, 3 do
				local star = starsFrame:FindFirstChild("Star" .. i)
				if star then
					star.TextTransparency = i <= (datosNivel.estrellas or 0) and 0 or 0.7
				end
			end
		end

		-- Stats grid
		local statsGrid = infoBody:FindFirstChild("StatsGrid")
		if statsGrid then
			local function actualizarStat(nombre, valor)
				local stat = statsGrid:FindFirstChild(nombre)
				if stat then
					local lbl = stat:FindFirstChild("Val") or stat:FindFirstChild("Valor")
					if lbl then
						lbl.Text = tostring(valor)
					end
				end
			end

			actualizarStat("StatScore", datosNivel.status == "completado" and ((datosNivel.highScore or 0) .. " pts") or "—")
			actualizarStat("StatStatus", datosNivel.status == "completado" and "✓ Completado"
				or datosNivel.status == "disponible" and "Disponible"
				or "🔒 Bloqueado")
			actualizarStat("StatAciert", tostring(datosNivel.aciertos or 0))
			actualizarStat("StatFallos", tostring(datosNivel.fallos or 0))
			actualizarStat("StatTiempo", formatearTiempo(datosNivel.tiempoMejor or 0))
			actualizarStat("StatInten", tostring(datosNivel.intentos or 0))
		end

		-- Tags de conceptos
		local tagsFrame = infoBody:FindFirstChild("Tags")
		if tagsFrame then
			for _, hijo in ipairs(tagsFrame:GetChildren()) do
				if hijo:IsA("TextButton") then
					hijo:Destroy()
				end
			end
			for _, concepto in ipairs(datosNivel.conceptos or {}) do
				local tag = crearInstancia("TextButton", {
					Size = UDim2.new(0, 0, 0, 22),
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundColor3 = Color3.fromRGB(0, 20, 30),
					Text = concepto,
					TextColor3 = Color3.fromRGB(0, 138, 170),
					Font = FUENTES.mono,
					TextSize = 9,
					BorderSizePixel = 0,
					ZIndex = 5,
				}, tagsFrame)
				crearEsquina(4, tag)
				crearBorde(Color3.fromRGB(0, 62, 90), 1, tag)
			end
		end
	end

	-- Boton de jugar
	if playButton then
		if datosNivel.status == "bloqueado" then
			playButton.Text = "🔒  NIVEL BLOQUEADO"
			playButton.TextColor3 = COLORES.muted
			playButton.BackgroundColor3 = COLORES.panel
			local stroke = playButton:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = COLORES.borde
			end
		else
			local icono = datosNivel.status == "completado" and "↺  REINTENTAR: " or "▶  JUGAR: "
			playButton.Text = icono .. (datosNivel.nombre or ""):upper()
			playButton.TextColor3 = COLORES.black
			playButton.BackgroundColor3 = COLORES.accentExito
			local stroke = playButton:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = COLORES.accentExito
			end
		end
	end
end

-- ============================================
-- CONSTRUIR GRID DE NIVELES
-- ============================================

local function construirGrid(datosProgreso)
	-- Ocultar loading
	local loadingFrame = gridArea:FindFirstChild("LoadingFrame")
	if loadingFrame then
		loadingFrame.Visible = false
	end

	-- Limpiar contenido anterior (mantener ProgressBar y LoadingFrame)
	local KEEP = {ProgressBar = true, LoadingFrame = true, GridLayout = true, UIPadding = true}
	for _, hijo in ipairs(gridArea:GetChildren()) do
		if not KEEP[hijo.Name] and not hijo:IsA("UIListLayout") and not hijo:IsA("UIPadding") then
			hijo:Destroy()
		end
	end

	-- Guardar cache
	datosNiveles = datosProgreso

	-- Agrupar por secciones
	local secciones = {}
	local ordenSecciones = {}

	for k, datos in pairs(datosProgreso) do
		local idNivel = tonumber(k)
		if idNivel ~= nil and datos then
			datos.nivelID = idNivel
			local nombreSeccion = datos.seccion or "NIVELES"

			if not secciones[nombreSeccion] then
				secciones[nombreSeccion] = {}
				table.insert(ordenSecciones, nombreSeccion)
			end
			table.insert(secciones[nombreSeccion], datos)
		end
	end

	-- Ordenar secciones por ID del primer nivel
	table.sort(ordenSecciones, function(a, b)
		return (secciones[a][1] and secciones[a][1].nivelID or 999) <
			(secciones[b][1] and secciones[b][1].nivelID or 999)
	end)

	-- Construir UI
	local ordenLayout = 3  -- Después de ProgressBar y gap
	local columnas = 2

	for idxSeccion, nombreSeccion in ipairs(ordenSecciones) do
		local niveles = secciones[nombreSeccion]

		-- Header de seccion
		local header = crearInstancia("Frame", {
			Name = "SecH_" .. nombreSeccion,
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundTransparency = 1,
			LayoutOrder = ordenLayout,
		}, gridArea)
		ordenLayout = ordenLayout + 1

		crearInstancia("TextLabel", {
			Size = UDim2.new(0, 220, 1, 0),
			BackgroundTransparency = 1,
			Text = nombreSeccion:upper(),
			TextColor3 = COLORES.accent,
			Font = FUENTES.mono,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 5,
		}, header)

		crearInstancia("Frame", {
			Size = UDim2.new(1, -230, 0, 1),
			Position = UDim2.new(0, 220, 0.5, 0),
			BackgroundColor3 = COLORES.borde,
			BorderSizePixel = 0,
			ZIndex = 5,
		}, header)

		crearInstancia("TextLabel", {
			Size = UDim2.new(0, 70, 1, 0),
			Position = UDim2.new(1, -70, 0, 0),
			BackgroundTransparency = 1,
			Text = #niveles .. (#niveles == 1 and " nivel" or " niveles"),
			TextColor3 = COLORES.dim,
			Font = FUENTES.mono,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 5,
		}, header)

		-- Contenedor de tarjetas
		local alturaContenedor = math.ceil(#niveles / columnas) * 156
		local contenedor = crearInstancia("Frame", {
			Name = "Sec_" .. idxSeccion,
			Size = UDim2.new(1, 0, 0, alturaContenedor),
			BackgroundTransparency = 1,
			LayoutOrder = ordenLayout,
		}, gridArea)
		ordenLayout = ordenLayout + 1

		-- Crear tarjetas
		for i, datosNivel in ipairs(niveles) do
			local columna = ((i - 1) % columnas) + 1
			local fila = math.floor((i - 1) / columnas)
			crearTarjetaNivel(datosNivel, columna, fila, contenedor)
		end

		-- Gap entre secciones
		crearInstancia("Frame", {
			Name = "Gap_" .. idxSeccion,
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			LayoutOrder = ordenLayout,
		}, gridArea)
		ordenLayout = ordenLayout + 1
	end

	-- Ajustar canvas size
	local layout = gridArea:FindFirstChildOfClass("UIListLayout")
	if layout then
		task.defer(function()
			gridArea.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 80)
		end)
	end

	-- Actualizar barra de progreso
	actualizarBarraProgreso()

	print("[ControladorMenu] Grid construido -", #ordenSecciones, "secciones cargadas")
end

function actualizarBarraProgreso()
	local total, completados = 0, 0
	for i = 0, 4 do
		local datos = datosNiveles[tostring(i)]
		if datos then
			total = total + 1
			if datos.status == "completado" then
				completados = completados + 1
			end
		end
	end

	local progressBar = gridArea:FindFirstChild("ProgressBar")
	if not progressBar then return end

	local pct = total > 0 and (completados / total) or 0

	local progText = progressBar:FindFirstChild("ProgText")
	if progText then
		progText.Text = completados .. " / " .. total
	end

	local progPct = progressBar:FindFirstChild("ProgPct")
	if progPct then
		progPct.Text = math.floor(pct * 100) .. "%"
	end

	local progFill = progressBar:FindFirstChild("ProgFill", true)
	if progFill then
		tween(progFill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.4)
	end
end

-- ============================================
-- CARGAR PROGRESO DEL SERVIDOR
-- ============================================

function cargarProgreso()
	if progresoCargado then return end
	progresoCargado = true

	local exito, datos = pcall(function()
		return obtenerProgresoFn:InvokeServer()
	end)

	if not exito or not datos then
		warn("[ControladorMenu] Error al obtener progreso:", tostring(datos))
		progresoCargado = false
		return
	end

	construirGrid(datos)

	-- Actualizar nombre del jugador
	if playerTag then
		playerTag.Text = jugador.DisplayName or jugador.Name
	end

	print("[ControladorMenu] Progreso cargado exitosamente")
end

-- Función para recargar el progreso al volver del nivel
local function recargarProgreso()
	print("[ControladorMenu] Recargando progreso...")
	progresoCargado = false
	cargarProgreso()
end

-- ============================================
-- INICIAR NIVEL
-- ============================================

function iniciarNivel(idNivel)
	if cargando then
		return
	end

	cargando = true

	-- Mostrar loading en la tarjeta
	local tarjeta = gridArea:FindFirstChild("Card" .. idNivel, true)
	if tarjeta then
		local loading = crearInstancia("Frame", {
			Name = "CardLoading",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			ZIndex = 20,
		}, tarjeta)
		crearEsquina(10, loading)

		local spinner = crearInstancia("ImageLabel", {
			Name = "Spinner",
			Size = UDim2.new(0, 32, 0, 32),
			Position = UDim2.new(0.5, -16, 0.5, -16),
			BackgroundTransparency = 1,
			Image = "rbxassetid://6031094670",
			ZIndex = 21,
		}, loading)

		-- Animar spinner
		task.spawn(function()
			while spinner and spinner.Parent do
				spinner.Rotation = (spinner.Rotation + 12) % 360
				task.wait(0.03)
			end
		end)

		crearInstancia("TextLabel", {
			Size = UDim2.new(1, 0, 0, 20),
			Position = UDim2.new(0, 0, 0.5, 20),
			BackgroundTransparency = 1,
			Text = "Cargando...",
			TextColor3 = COLORES.texto,
			Font = FUENTES.mono,
			TextSize = 10,
			ZIndex = 21,
		}, loading)
	end

	-- Notificar al servidor
	iniciarNivelEvento:FireServer(idNivel)

	-- Timeout de 10s
	task.delay(10, function()
		if cargando then
			cargando = false
			local loading = tarjeta and tarjeta:FindFirstChild("CardLoading")
			if loading then
				loading:Destroy()
			end
			warn("[ControladorMenu] Timeout al cargar nivel", idNivel)
		end
	end)
end

-- ============================================
-- CONECTAR BOTONES DE NAVEGACION
-- ============================================

local function conectarBotonesNavegacion()
	-- Boton JUGAR en menu principal
	local btnPlay = frameMenu:FindFirstChild("BtnPlay", true)
	if btnPlay then
		btnPlay.MouseButton1Click:Connect(function()
			mostrarSelectorNiveles()
		end)
	end

	-- Boton VOLVER en selector de niveles
	if backBtn then
		backBtn.MouseButton1Click:Connect(function()
			mostrarMenuPrincipal()
		end)
	end

	-- Boton AJUSTES
	local btnSettings = frameMenu:FindFirstChild("BtnSettings", true)
	if btnSettings then
		btnSettings.MouseButton1Click:Connect(function()
			abrirModal(frameSettings)
		end)
	end

	-- Boton CREDITOS
	local btnCredits = frameMenu:FindFirstChild("BtnCredits", true)
	if btnCredits then
		btnCredits.MouseButton1Click:Connect(function()
			abrirModal(frameCredits)
		end)
	end

	-- Boton SALIR
	local btnExit = frameMenu:FindFirstChild("BtnExit", true)
	if btnExit then
		btnExit.MouseButton1Click:Connect(function()
			abrirModal(frameExit)
		end)
	end

	-- Botones de cerrar en modales
	for _, modal in ipairs({frameSettings, frameCredits, frameExit}) do
		if modal then
			local closeBtn = modal:FindFirstChild("CloseBtn", true)
			if closeBtn then
				closeBtn.MouseButton1Click:Connect(function()
					cerrarModal(modal)
				end)
			end

			-- Botones específicos
			local cancelBtn = modal:FindFirstChild("CancelBtn", true)
			if cancelBtn then
				cancelBtn.MouseButton1Click:Connect(function()
					cerrarModal(modal)
				end)
			end

			local okBtn = modal:FindFirstChild("OkBtn", true)
			if okBtn then
				okBtn.MouseButton1Click:Connect(function()
					cerrarModal(modal)
				end)
			end

			local saveBtn = modal:FindFirstChild("SaveBtn", true)
			if saveBtn then
				saveBtn.MouseButton1Click:Connect(function()
					-- Guardar ajustes y cerrar
					cerrarModal(modal)
				end)
			end

			local confirmBtn = modal:FindFirstChild("ConfirmBtn", true)
			if confirmBtn and modal == frameExit then
				confirmBtn.MouseButton1Click:Connect(function()
					-- Salir del juego
					jugador:Kick("Gracias por jugar EDA Quest!")
				end)
			end
		end
	end

	-- Boton JUGAR en sidebar (playButton)
	if playButton then
		playButton.MouseButton1Click:Connect(function()
			if nivelSeleccionado and datosNiveles[tostring(nivelSeleccionado)] then
				local datos = datosNiveles[tostring(nivelSeleccionado)]
				if datos.status ~= "bloqueado" then
					iniciarNivel(nivelSeleccionado)
				end
			end
		end)
	end
end

-- ============================================
-- EVENTOS DEL SERVIDOR
-- ============================================

if nivelListoEvento then
	nivelListoEvento.OnClientEvent:Connect(function(data)
		cargando = false

		if data and data.error then
			warn("[ControladorMenu] Error del servidor:", data.error)
			return
		end

		-- Ocultar menu, mostrar HUD
		menuGui.Enabled = false

		local hud = playerGui:FindFirstChild("GUIExploradorV2")
		if hud then
			hud.Enabled = true
		end

		-- Restaurar camara
		camara.CameraType = Enum.CameraType.Custom

		print("[ControladorMenu] Nivel iniciado:", nivelSeleccionado)
	end)
end

-- Manejar vuelta al menu (recargar progreso)
if nivelDescargadoEvento then
	nivelDescargadoEvento.OnClientEvent:Connect(function()
		print("[ControladorMenu] NivelDescargado recibido - Volviendo al menu y recargando progreso")

		-- Mostrar menu, ocultar HUD
		menuGui.Enabled = true

		local hud = playerGui:FindFirstChild("GUIExploradorV2")
		if hud then
			hud.Enabled = false
		end

		-- Configurar camara del menu
		configurarCamaraMenu()

		-- Recargar el progreso para mostrar datos actualizados
		recargarProgreso()

		-- Resetear estado
		nivelSeleccionado = nil
		cargando = false

		-- Resetear sidebar a estado inicial
		local sidebar = levelMainArea:WaitForChild("LevelSidebar")
		local placeholder = sidebar:WaitForChild("Placeholder")
		local infoContent = sidebar:WaitForChild("InfoContent")
		placeholder.Visible = true
		infoContent.Visible = false

		-- Resetear boton de jugar
		local playBtn = sidebar:WaitForChild("PlayArea"):WaitForChild("PlayButton")
		playBtn.Text = "🔒  SELECCIONA UN NIVEL"
		playBtn.BackgroundColor3 = Color3.fromRGB(17, 25, 39)

		-- Volver a la pantalla de niveles
		mostrarSelectorNiveles()
	end)
end

-- ============================================
-- INICIALIZACION
-- ============================================

local function inicializar()
	-- Configurar estado inicial
	mostrarMenuPrincipal()
	configurarCamaraMenu()
	conectarBotonesNavegacion()

	print("[ControladorMenu] Inicializado")
end

inicializar()
