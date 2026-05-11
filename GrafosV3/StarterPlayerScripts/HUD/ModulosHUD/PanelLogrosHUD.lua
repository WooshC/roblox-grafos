-- GrafosV3 - PanelLogrosHUD.lua
-- Cliente: UI de logros dentro del HUD de gameplay.
-- Ubicación: StarterPlayerScripts/HUD/ModulosHUD/PanelLogrosHUD.lua

local PanelLogrosHUD = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")

local jugador = Players.LocalPlayer
local LogrosConfig = require(RS:WaitForChild("Config"):WaitForChild("LogrosConfig"))

-- Referencias
local parentHud = nil
local barraBotones = nil
local btnLogros = nil
local panelLogros = nil
local notificacionToast = nil
local gridLogros = nil

-- Estado
local estadoLogros = {}  -- [id] = { desbloqueado = bool, ... }
local panelVisible = false
local datosCargados = false

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONSTANTES DE ESTILO
-- ═══════════════════════════════════════════════════════════════════════════════

local COLORES = {
	fondo        = Color3.fromRGB(4, 7, 14),
	panel        = Color3.fromRGB(17, 25, 39),
	borde        = Color3.fromRGB(30, 45, 66),
	accent       = Color3.fromRGB(0, 212, 255),
	accentExito  = Color3.fromRGB(16, 185, 129),
	oro          = Color3.fromRGB(245, 158, 11),
	muted        = Color3.fromRGB(100, 116, 139),
	texto        = Color3.fromRGB(226, 232, 240),
	dim          = Color3.fromRGB(55, 65, 81),
	secreto      = Color3.fromRGB(60, 60, 70),
}

local FUENTES = {
	mono  = Enum.Font.RobotoMono,
	bold  = Enum.Font.GothamBold,
	body  = Enum.Font.Gotham,
	title = Enum.Font.GothamBlack,
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- UTILIDADES
-- ═══════════════════════════════════════════════════════════════════════════════

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

local function tween(objeto, propiedades, tiempo)
	local info = TweenInfo.new(tiempo or 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tw = TweenService:Create(objeto, info, propiedades)
	tw:Play()
	return tw
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CREAR BOTÓN DE LOGROS EN LA BARRA
-- ═══════════════════════════════════════════════════════════════════════════════

local function crearBotonLogros()
	if not barraBotones then return nil end

	-- Si ya existe, retornarlo
	local existente = barraBotones:FindFirstChild("BtnLogros")
	if existente then return existente end

	-- Buscar el layout para insertar antes de BtnSalir
	local layout = barraBotones:FindFirstChildOfClass("UIListLayout")

	local btn = crearInstancia("TextButton", {
		Name = "BtnLogros",
		Size = UDim2.new(0, 90, 0, 32),
		BackgroundColor3 = COLORES.panel,
		Text = "🏆  Logros",
		TextColor3 = COLORES.texto,
		Font = FUENTES.mono,
		TextSize = 11,
		BorderSizePixel = 0,
		LayoutOrder = 99,
		ZIndex = 5,
	}, barraBotones)

	crearEsquina(6, btn)
	crearBorde(COLORES.borde, 1, btn)

	-- Hover effects
	btn.MouseEnter:Connect(function()
		tween(btn, {BackgroundColor3 = Color3.fromRGB(51, 65, 85)}, 0.2)
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, {BackgroundColor3 = COLORES.panel}, 0.2)
	end)

	return btn
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CREAR PANEL DE LOGROS
-- ═══════════════════════════════════════════════════════════════════════════════

local function crearPanelLogros()
	if not parentHud then return nil end

	local existente = parentHud:FindFirstChild("PanelLogros")
	if existente then return existente end

	-- Fondo oscuro que cubre toda la pantalla
	local fondo = crearInstancia("Frame", {
		Name = "PanelLogros",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.5,
		Visible = false,
		ZIndex = 50,
	}, parentHud)

	-- Contenedor principal centrado
	local contenedor = crearInstancia("Frame", {
		Name = "Contenedor",
		Size = UDim2.new(0, 520, 0, 420),
		Position = UDim2.new(0.5, -260, 0.5, -210),
		BackgroundColor3 = COLORES.panel,
		BorderSizePixel = 0,
		ZIndex = 51,
	}, fondo)
	crearEsquina(12, contenedor)
	crearBorde(COLORES.borde, 1, contenedor)

	-- Header
	local header = crearInstancia("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundTransparency = 1,
		ZIndex = 52,
	}, contenedor)

	crearInstancia("TextLabel", {
		Name = "Titulo",
		Size = UDim2.new(0, 300, 1, 0),
		Position = UDim2.new(0, 20, 0, 0),
		BackgroundTransparency = 1,
		Text = "🏆  LOGROS",
		TextColor3 = COLORES.texto,
		Font = FUENTES.bold,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 53,
	}, header)

	-- Contador
	local lblContador = crearInstancia("TextLabel", {
		Name = "Contador",
		Size = UDim2.new(0, 120, 1, 0),
		Position = UDim2.new(1, -200, 0, 0),
		BackgroundTransparency = 1,
		Text = "0 / 0",
		TextColor3 = COLORES.muted,
		Font = FUENTES.mono,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 53,
	}, header)

	-- Botón cerrar
	local btnCerrar = crearInstancia("TextButton", {
		Name = "BtnCerrar",
		Size = UDim2.new(0, 32, 0, 32),
		Position = UDim2.new(1, -42, 0, 9),
		BackgroundColor3 = COLORES.fondo,
		Text = "✕",
		TextColor3 = COLORES.muted,
		Font = FUENTES.bold,
		TextSize = 14,
		BorderSizePixel = 0,
		ZIndex = 53,
	}, header)
	crearEsquina(6, btnCerrar)
	crearBorde(COLORES.borde, 1, btnCerrar)

	btnCerrar.MouseButton1Click:Connect(function()
		PanelLogrosHUD.ocultarPanel()
	end)
	btnCerrar.MouseEnter:Connect(function()
		tween(btnCerrar, {BackgroundColor3 = Color3.fromRGB(80, 30, 30)}, 0.2)
	end)
	btnCerrar.MouseLeave:Connect(function()
		tween(btnCerrar, {BackgroundColor3 = COLORES.fondo}, 0.2)
	end)

	-- ScrollFrame para el grid
	local scroll = crearInstancia("ScrollingFrame", {
		Name = "Scroll",
		Size = UDim2.new(1, -20, 1, -60),
		Position = UDim2.new(0, 10, 0, 50),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = COLORES.dim,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ZIndex = 52,
	}, contenedor)

	crearInstancia("UIPadding", {
		PaddingLeft = UDim.new(0, 5),
		PaddingRight = UDim.new(0, 5),
		PaddingTop = UDim.new(0, 5),
		PaddingBottom = UDim.new(0, 5),
	}, scroll)

	-- Grid layout
	local gridLayout = crearInstancia("UIGridLayout", {
		CellSize = UDim2.new(0, 235, 0, 80),
		CellPadding = UDim2.new(0, 10, 0, 10),
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, scroll)

	-- Guardar referencias
	gridLogros = scroll
	PanelLogrosHUD._lblContador = lblContador

	return fondo
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CREAR TOAST DE NOTIFICACIÓN
-- ═══════════════════════════════════════════════════════════════════════════════

local function crearToastNotificacion()
	if not parentHud then return nil end

	local existente = parentHud:FindFirstChild("ToastLogro")
	if existente then return existente end

	local toast = crearInstancia("Frame", {
		Name = "ToastLogro",
		Size = UDim2.new(0, 320, 0, 70),
		Position = UDim2.new(0.5, -160, 0, -80),
		BackgroundColor3 = COLORES.panel,
		BorderSizePixel = 0,
		ZIndex = 100,
	}, parentHud)
	crearEsquina(10, toast)
	crearBorde(COLORES.accent, 1, toast)

	-- Glow de borde
	local glow = crearInstancia("Frame", {
		Name = "Glow",
		Size = UDim2.new(1, 4, 1, 4),
		Position = UDim2.new(0, -2, 0, -2),
		BackgroundTransparency = 1,
		ZIndex = 99,
	}, toast)
	local glowStroke = crearBorde(COLORES.accent, 2, glow)
	glowStroke.Transparency = 0.8

	-- Icono
	local icono = crearInstancia("TextLabel", {
		Name = "Icono",
		Size = UDim2.new(0, 40, 0, 40),
		Position = UDim2.new(0, 12, 0.5, -20),
		BackgroundTransparency = 1,
		Text = "🏆",
		Font = FUENTES.body,
		TextSize = 28,
		ZIndex = 101,
	}, toast)

	-- Título
	local titulo = crearInstancia("TextLabel", {
		Name = "Titulo",
		Size = UDim2.new(1, -70, 0, 22),
		Position = UDim2.new(0, 58, 0, 10),
		BackgroundTransparency = 1,
		Text = "¡Logro Desbloqueado!",
		TextColor3 = COLORES.accent,
		Font = FUENTES.bold,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 101,
	}, toast)

	-- Nombre del logro
	local nombre = crearInstancia("TextLabel", {
		Name = "NombreLogro",
		Size = UDim2.new(1, -70, 0, 20),
		Position = UDim2.new(0, 58, 0, 34),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = COLORES.texto,
		Font = FUENTES.body,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 101,
	}, toast)

	-- Descripción
	local desc = crearInstancia("TextLabel", {
		Name = "Desc",
		Size = UDim2.new(1, -70, 0, 18),
		Position = UDim2.new(0, 58, 0, 52),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = COLORES.muted,
		Font = FUENTES.body,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 101,
	}, toast)

	return toast
end

local function mostrarToast(datosLogro)
	if not notificacionToast then return end

	local icono = notificacionToast:FindFirstChild("Icono")
	local nombre = notificacionToast:FindFirstChild("NombreLogro")
	local desc = notificacionToast:FindFirstChild("Desc")

	if icono then icono.Text = datosLogro.icono or "🏆" end
	if nombre then nombre.Text = datosLogro.nombre or "" end
	if desc then desc.Text = datosLogro.descripcion or "" end

	-- Animar entrada
	notificacionToast.Position = UDim2.new(0.5, -160, 0, -80)
	notificacionToast.Visible = true

	tween(notificacionToast, {Position = UDim2.new(0.5, -160, 0, 20)}, 0.4)

	-- Auto-ocultar después de 4 segundos
	task.delay(4, function()
		if notificacionToast and notificacionToast.Visible then
			local tw = tween(notificacionToast, {Position = UDim2.new(0.5, -160, 0, -80)}, 0.3)
			tw.Completed:Connect(function()
				notificacionToast.Visible = false
			end)
		end
	end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONSTRUIR TARJETA DE LOGRO
-- ═══════════════════════════════════════════════════════════════════════════════

local function crearTarjetaLogro(logroConfig, estado, parent)
	local desbloqueado = estado and estado.desbloqueado
	local esSecreto = logroConfig.secreto and not desbloqueado

	-- Colores según estado
	local bgColor = desbloqueado and Color3.fromRGB(26, 35, 55) or COLORES.panel
	local bordeColor = desbloqueado and COLORES.accentExito or COLORES.borde
	local iconoTexto = esSecreto and "❓" or (logroConfig.icono or "🏆")
	local nombreTexto = esSecreto and "Logro Secreto" or logroConfig.nombre
	local descTexto = esSecreto and "Descubre cómo desbloquear este logro..." or logroConfig.descripcion

	local tarjeta = crearInstancia("Frame", {
		Name = "Logro_" .. logroConfig.id,
		Size = UDim2.new(0, 235, 0, 80),
		BackgroundColor3 = bgColor,
		BorderSizePixel = 0,
		ZIndex = 55,
	}, parent)
	crearEsquina(8, tarjeta)
	crearBorde(bordeColor, 1, tarjeta)

	-- Icono
	crearInstancia("TextLabel", {
		Name = "Icono",
		Size = UDim2.new(0, 36, 0, 36),
		Position = UDim2.new(0, 10, 0.5, -18),
		BackgroundTransparency = 1,
		Text = iconoTexto,
		Font = FUENTES.body,
		TextSize = 24,
		ZIndex = 56,
	}, tarjeta)

	-- Nombre
	crearInstancia("TextLabel", {
		Name = "Nombre",
		Size = UDim2.new(1, -60, 0, 18),
		Position = UDim2.new(0, 52, 0, 10),
		BackgroundTransparency = 1,
		Text = nombreTexto,
		TextColor3 = desbloqueado and COLORES.texto or COLORES.muted,
		Font = FUENTES.bold,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 56,
	}, tarjeta)

	-- Descripción
	crearInstancia("TextLabel", {
		Name = "Desc",
		Size = UDim2.new(1, -60, 0, 28),
		Position = UDim2.new(0, 52, 0, 30),
		BackgroundTransparency = 1,
		Text = descTexto,
		TextColor3 = desbloqueado and COLORES.muted or COLORES.dim,
		Font = FUENTES.body,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		ZIndex = 56,
	}, tarjeta)

	-- Badge de estado
	local badgeTexto = desbloqueado and "✓ Desbloqueado" or "🔒 Bloqueado"
	local badgeColor = desbloqueado and COLORES.accentExito or COLORES.dim

	crearInstancia("TextLabel", {
		Name = "Badge",
		Size = UDim2.new(0, 90, 0, 14),
		Position = UDim2.new(0, 52, 1, -20),
		BackgroundTransparency = 1,
		Text = badgeTexto,
		TextColor3 = badgeColor,
		Font = FUENTES.mono,
		TextSize = 9,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 56,
	}, tarjeta)

	-- Si está desbloqueado, efecto sutil de brillo
	if desbloqueado then
		tarjeta.MouseEnter:Connect(function()
			tween(tarjeta, {BackgroundColor3 = Color3.fromRGB(36, 50, 80)}, 0.2)
		end)
		tarjeta.MouseLeave:Connect(function()
			tween(tarjeta, {BackgroundColor3 = bgColor}, 0.2)
		end)
	end

	return tarjeta
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- ACTUALIZAR PANEL
-- ═══════════════════════════════════════════════════════════════════════════════

function PanelLogrosHUD.reconstruirPanel()
	if not gridLogros then return end

	-- Limpiar grid
	for _, hijo in ipairs(gridLogros:GetChildren()) do
		if hijo:IsA("Frame") or hijo:IsA("TextLabel") then
			hijo:Destroy()
		end
	end

	-- Ordenar logros: desbloqueados primero, luego por categoría
	local logrosOrdenados = {}
	for _, logro in ipairs(LogrosConfig.LOGROS) do
		table.insert(logrosOrdenados, logro)
	end

	table.sort(logrosOrdenados, function(a, b)
		local da = estadoLogros[a.id] and estadoLogros[a.id].desbloqueado
		local db = estadoLogros[b.id] and estadoLogros[b.id].desbloqueado
		if da ~= db then
			return da and not db
		end
		return (a.categoria or "") < (b.categoria or "")
	end)

	-- Crear tarjetas
	for _, logro in ipairs(logrosOrdenados) do
		local estado = estadoLogros[logro.id]
		crearTarjetaLogro(logro, estado, gridLogros)
	end

	-- Actualizar contador
	if PanelLogrosHUD._lblContador then
		local total = #LogrosConfig.LOGROS
		local desbloqueados = 0
		for _, e in pairs(estadoLogros) do
			if e.desbloqueado then desbloqueados = desbloqueados + 1 end
		end
		PanelLogrosHUD._lblContador.Text = desbloqueados .. " / " .. total .. " logros"
	end

	-- Ajustar canvas size
	task.defer(function()
		local layout = gridLogros:FindFirstChildOfClass("UIGridLayout")
		if layout then
			local abs = layout.AbsoluteContentSize
			gridLogros.CanvasSize = UDim2.new(0, 0, 0, abs.Y + 20)
		end
	end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CARGAR DATOS DEL SERVIDOR
-- ═══════════════════════════════════════════════════════════════════════════════

function PanelLogrosHUD.cargarDatos()
	if datosCargados then return end

	local EventosHUD = require(script.Parent.EventosHUD)
	local obtenerLogros = EventosHUD.obtenerLogros

	if not obtenerLogros then
		warn("[PanelLogrosHUD] obtenerLogros no disponible")
		return
	end

	local exito, datos = pcall(function()
		return obtenerLogros:InvokeServer()
	end)

	if exito and datos then
		estadoLogros = datos
		datosCargados = true
		PanelLogrosHUD.reconstruirPanel()
		print("[PanelLogrosHUD] Datos de logros cargados")
	else
		warn("[PanelLogrosHUD] Error al cargar logros:", tostring(datos))
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- MOSTRAR / OCULTAR PANEL
-- ═══════════════════════════════════════════════════════════════════════════════

function PanelLogrosHUD.mostrarPanel()
	if not panelLogros then return end
	if panelVisible then return end

	panelVisible = true
	panelLogros.Visible = true

	-- Cargar datos si no están cargados
	if not datosCargados then
		PanelLogrosHUD.cargarDatos()
	else
		PanelLogrosHUD.reconstruirPanel()
	end

	-- Animar entrada
	local contenedor = panelLogros:FindFirstChild("Contenedor")
	if contenedor then
		contenedor.Size = UDim2.new(0, 480, 0, 380)
		contenedor.Position = UDim2.new(0.5, -240, 0.5, -190)
		tween(contenedor, {Size = UDim2.new(0, 520, 0, 420), Position = UDim2.new(0.5, -260, 0.5, -210)}, 0.25)
	end
end

function PanelLogrosHUD.ocultarPanel()
	if not panelLogros then return end
	if not panelVisible then return end

	panelVisible = false

	local contenedor = panelLogros:FindFirstChild("Contenedor")
	if contenedor then
		local tw = tween(contenedor, {Size = UDim2.new(0, 480, 0, 380), Position = UDim2.new(0.5, -240, 0.5, -190)}, 0.2)
		tw.Completed:Connect(function()
			if not panelVisible then
				panelLogros.Visible = false
			end
		end)
	else
		panelLogros.Visible = false
	end
end

function PanelLogrosHUD.togglePanel()
	if panelVisible then
		PanelLogrosHUD.ocultarPanel()
	else
		PanelLogrosHUD.mostrarPanel()
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- NOTIFICACIÓN DE LOGRO DESBLOQUEADO
-- ═══════════════════════════════════════════════════════════════════════════════

function PanelLogrosHUD.alLogroDesbloqueado(datos)
	-- Actualizar estado local
	if datos and datos.id then
		estadoLogros[datos.id] = {
			id = datos.id,
			nombre = datos.nombre,
			descripcion = datos.descripcion,
			icono = datos.icono,
			categoria = datos.categoria,
			secreto = datos.secreto,
			desbloqueado = true,
		}
		-- Reconstruir panel si está visible
		if panelVisible then
			PanelLogrosHUD.reconstruirPanel()
		end
	end

	-- Mostrar toast
	mostrarToast(datos)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════════════════════

function PanelLogrosHUD.init(hudRef)
	parentHud = hudRef

	-- Buscar barra de botones
	barraBotones = parentHud:FindFirstChild("BarraBotonesMain", true)
	if not barraBotones then
		warn("[PanelLogrosHUD] BarraBotonesMain no encontrada")
		return
	end

	-- Crear botón
	btnLogros = crearBotonLogros()
	if btnLogros then
		btnLogros.MouseButton1Click:Connect(PanelLogrosHUD.togglePanel)
	end

	-- Crear panel
	panelLogros = crearPanelLogros()

	-- Crear toast
	notificacionToast = crearToastNotificacion()

	print("[PanelLogrosHUD] Inicializado")
end

function PanelLogrosHUD.limpiar()
	panelVisible = false
	datosCargados = false
	estadoLogros = {}
	if panelLogros then
		panelLogros.Visible = false
	end
	if notificacionToast then
		notificacionToast.Visible = false
	end
end

return PanelLogrosHUD
