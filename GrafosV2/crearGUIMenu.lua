-- Script para crear el menú principal de EDA Quest en StarterGui
-- Ejecutar en la barra de comandos de Roblox Studio.

local StarterGui = game:GetService("StarterGui")

-- Colores (aproximación de la paleta original)
local colors = {
	bg = Color3.fromRGB(5, 8, 16),
	surface = Color3.fromRGB(12, 18, 32),
	panel = Color3.fromRGB(17, 25, 39),
	border = Color3.fromRGB(30, 45, 66),
	border_hi = Color3.fromRGB(46, 74, 106),
	accent = Color3.fromRGB(0, 212, 255),
	accent2 = Color3.fromRGB(124, 58, 237),
	accent3 = Color3.fromRGB(16, 185, 129),
	danger = Color3.fromRGB(239, 68, 68),
	text = Color3.fromRGB(226, 232, 240),
	muted = Color3.fromRGB(100, 116, 139),
	dim = Color3.fromRGB(51, 65, 85),
	gold = Color3.fromRGB(245, 158, 11),
}

-- Fuentes aproximadas
local fonts = {
	title = Enum.Font.GothamBlack,
	mono = Enum.Font.SourceCode,
	body = Enum.Font.SourceSans,
	bodyBold = Enum.Font.SourceSansBold,
}

-- Función auxiliar para crear un objeto con propiedades
local function create(className, properties, parent)
	local obj = Instance.new(className)
	for k, v in pairs(properties) do
		obj[k] = v
	end
	obj.Parent = parent
	return obj
end

-- Crear la ScreenGui principal
local screenGui = create("ScreenGui", {
	Name = "EDAQuestMenu",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, StarterGui)

-- Panel de fondo (capa base)
local background = create("Frame", {
	Name = "Background",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = colors.bg,
	BorderSizePixel = 0,
}, screenGui)

-- Efecto de cuadrícula (simulación con líneas)
local grid = create("Frame", {
	Name = "Grid",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	ZIndex = 2,
}, background)

-- Crear líneas verticales y horizontales para simular cuadrícula
local function createGridLine(orientation, pos, size, color, transparency)
	local line = create("Frame", {
		Name = "GridLine",
		BackgroundColor3 = color,
		BackgroundTransparency = transparency or 0.9,
		BorderSizePixel = 0,
		Position = pos,
		Size = size,
	}, grid)
	return line
end

for i = 0, 20 do
	local x = i * 0.05
	createGridLine("Vertical", UDim2.new(x, 0, 0, 0), UDim2.new(0, 1, 1, 0), colors.accent, 0.95)
end
for i = 0, 12 do
	local y = i * 0.0833
	createGridLine("Horizontal", UDim2.new(0, 0, y, 0), UDim2.new(1, 0, 0, 1), colors.accent, 0.95)
end

-- Manchas de color de fondo (glow)
local glow1 = create("Frame", {
	Name = "Glow1",
	Size = UDim2.new(0, 400, 0, 400),
	Position = UDim2.new(-0.1, 0, -0.1, 0),
	BackgroundColor3 = colors.accent2,
	BackgroundTransparency = 0.85,
	BorderSizePixel = 0,
}, background)
create("UICorner", { CornerRadius = UDim.new(0.5, 0) }, glow1)

local glow2 = create("Frame", {
	Name = "Glow2",
	Size = UDim2.new(0, 350, 0, 350),
	Position = UDim2.new(0.8, 0, 0.7, 0),
	BackgroundColor3 = colors.accent,
	BackgroundTransparency = 0.85,
	BorderSizePixel = 0,
}, background)
create("UICorner", { CornerRadius = UDim.new(0.5, 0) }, glow2)

-- Nodos del grafo (círculos pequeños)
local nodes = {}
local nodePositions = {
	{0.12, 0.20}, {0.28, 0.55}, {0.18, 0.72}, {0.35, 0.30},
	{0.50, 0.65}, {0.42, 0.15}, {0.60, 0.35}, {0.65, 0.75},
	{0.75, 0.20}, {0.80, 0.55}, {0.25, 0.40}, {0.55, 0.50},
}
local nodeColors = {colors.accent, colors.accent2, colors.accent3}
for i, pos in ipairs(nodePositions) do
	local node = create("Frame", {
		Name = "Node"..i,
		Size = UDim2.new(0, 24, 0, 24),
		Position = UDim2.new(pos[1], -12, pos[2], -12),
		BackgroundColor3 = nodeColors[(i%3)+1],
		BackgroundTransparency = 0.8,
		BorderColor3 = nodeColors[(i%3)+1],
		BorderSizePixel = 2,
	}, background)
	create("UICorner", { CornerRadius = UDim.new(0.5, 0) }, node)
	table.insert(nodes, node)
end

-- Líneas entre nodos (simuladas con frames rotados)
local edges = {
	{1,4},{1,11},{11,2},{11,4},{2,3},
	{4,6},{4,7},{6,7},{7,9},{7,12},
	{12,5},{12,10},{5,8},{8,10},{9,10},
	{2,5},{3,5},{6,9},
}
for _, e in ipairs(edges) do
	local a = nodes[e[1]]
	local b = nodes[e[2]]
	if a and b then
		local posA = a.AbsolutePosition
		local posB = b.AbsolutePosition
		-- No podemos calcular en tiempo de creación, se haría en un LocalScript.
		-- Para simplificar, omitimos las líneas estáticas.
	end
end

-- Indicador de cámara (parte superior)
local camIndicator = create("Frame", {
	Name = "CamIndicator",
	Size = UDim2.new(0, 200, 0, 30),
	Position = UDim2.new(0.5, -100, 0, 20),
	BackgroundColor3 = colors.surface,
	BackgroundTransparency = 0.25,
	BorderColor3 = colors.border,
}, background)
create("UICorner", { CornerRadius = UDim.new(0, 20) }, camIndicator)

local camDot = create("Frame", {
	Name = "CamDot",
	Size = UDim2.new(0, 6, 0, 6),
	Position = UDim2.new(0, 12, 0.5, -3),
	BackgroundColor3 = colors.danger,
	BorderSizePixel = 0,
}, camIndicator)
create("UICorner", { CornerRadius = UDim.new(0.5, 0) }, camDot)

local camLabel = create("TextLabel", {
	Name = "CamLabel",
	Size = UDim2.new(0, 100, 1, 0),
	Position = UDim2.new(0, 24, 0, 0),
	BackgroundTransparency = 1,
	Text = "Vista Cinemática",
	TextColor3 = colors.muted,
	Font = fonts.mono,
	TextSize = 10,
	TextXAlignment = Enum.TextXAlignment.Left,
}, camIndicator)

local camViews = create("Frame", {
	Name = "CamViews",
	Size = UDim2.new(0, 50, 1, 0),
	Position = UDim2.new(1, -60, 0, 0),
	BackgroundTransparency = 1,
}, camIndicator)
for i = 1, 4 do
	local view = create("Frame", {
		Name = "View"..i,
		Size = UDim2.new(0, 10, 0, 8),
		Position = UDim2.new(0, (i-1)*12, 0.5, -4),
		BackgroundColor3 = (i==1) and colors.accent or colors.border,
		BackgroundTransparency = (i==1) and 0.75 or 0,
		BorderColor3 = (i==1) and colors.accent or colors.border,
		BorderSizePixel = 1,
	}, camViews)
	create("UICorner", { CornerRadius = UDim.new(0, 2) }, view)
end

-- Logo área (izquierda)
local logoArea = create("Frame", {
	Name = "LogoArea",
	Size = UDim2.new(0, 300, 0, 180),
	Position = UDim2.new(0, 56, 0, 48),
	BackgroundTransparency = 1,
}, background)

local logoCategory = create("TextLabel", {
	Name = "LogoCategory",
	Size = UDim2.new(1, 0, 0, 16),
	BackgroundTransparency = 1,
	Text = "Juego Serio · Aprendizaje Interactivo",
	TextColor3 = colors.accent2,
	Font = fonts.body,
	TextSize = 10,
	TextXAlignment = Enum.TextXAlignment.Left,
}, logoArea)

local logoLabel = create("TextLabel", {
	Name = "LogoLabel",
	Size = UDim2.new(1, 0, 0, 16),
	Position = UDim2.new(0, 0, 0, 18),
	BackgroundTransparency = 1,
	Text = "Estructura de Datos y Algoritmos",
	TextColor3 = colors.accent,
	Font = fonts.mono,
	TextSize = 10,
	TextXAlignment = Enum.TextXAlignment.Left,
}, logoArea)

local logoTitle = create("TextLabel", {
	Name = "LogoTitle",
	Size = UDim2.new(1, 0, 0, 60),
	Position = UDim2.new(0, 0, 0, 40),
	BackgroundTransparency = 1,
	Text = "EDA\nQuest",
	TextColor3 = colors.text,
	Font = fonts.title,
	TextSize = 30,
	TextXAlignment = Enum.TextXAlignment.Left,
}, logoArea)

local logoSub = create("TextLabel", {
	Name = "LogoSub",
	Size = UDim2.new(1, 0, 0, 40),
	Position = UDim2.new(0, 0, 0, 100),
	BackgroundTransparency = 1,
	Text = "Aprende grafos dirigidos y no dirigidos\na través de desafíos de conexión de redes",
	TextColor3 = colors.muted,
	Font = fonts.body,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextWrapped = true,
}, logoArea)

local badges = create("Frame", {
	Name = "Badges",
	Size = UDim2.new(1, 0, 0, 20),
	Position = UDim2.new(0, 0, 0, 150),
	BackgroundTransparency = 1,
}, logoArea)

local function createBadge(text, color)
	local b = create("Frame", {
		Name = "Badge",
		Size = UDim2.new(0, 60, 0, 18),
		BackgroundColor3 = colors.panel,
		BorderColor3 = color,
		BorderSizePixel = 1,
	}, badges)
	create("UICorner", { CornerRadius = UDim.new(0, 3) }, b)
	create("TextLabel", {
		Name = "Label",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = color,
		Font = fonts.mono,
		TextSize = 9,
	}, b)
	return b
end

createBadge("Grafos", colors.accent).Position = UDim2.new(0, 0, 0, 0)
createBadge("BFS", colors.accent2).Position = UDim2.new(0, 70, 0, 0)
createBadge("Educación", colors.accent3).Position = UDim2.new(0, 130, 0, 0)

-- Panel de menú (derecha)
local menuPanel = create("Frame", {
	Name = "MenuPanel",
	Size = UDim2.new(0, 300, 0, 300),
	Position = UDim2.new(1, -364, 0.5, -150),
	BackgroundTransparency = 1,
}, background)

local function createMenuButton(name, icon, label, sub, accentColor, onClick)
	local btn = create("Frame", {
		Name = name,
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundColor3 = colors.surface,
		BackgroundTransparency = 0.3,
		BorderColor3 = colors.border,
		BorderSizePixel = 1,
	}, menuPanel)
	create("UICorner", { CornerRadius = UDim.new(0, 4) }, btn)
	
	local iconLabel = create("TextLabel", {
		Name = "Icon",
		Size = UDim2.new(0, 30, 1, 0),
		BackgroundTransparency = 1,
		Text = icon,
		TextColor3 = colors.muted,
		Font = fonts.body,
		TextSize = 18,
	}, btn)
	
	local textFrame = create("Frame", {
		Name = "TextFrame",
		Size = UDim2.new(1, -60, 1, 0),
		Position = UDim2.new(0, 40, 0, 0),
		BackgroundTransparency = 1,
	}, btn)
	
	local mainLabel = create("TextLabel", {
		Name = "Main",
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0, 10),
		BackgroundTransparency = 1,
		Text = label,
		TextColor3 = colors.text,
		Font = fonts.mono,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, textFrame)
	
	local subLabel = create("TextLabel", {
		Name = "Sub",
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 0, 0, 30),
		BackgroundTransparency = 1,
		Text = sub,
		TextColor3 = colors.muted,
		Font = fonts.body,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, textFrame)
	
	local arrow = create("TextLabel", {
		Name = "Arrow",
		Size = UDim2.new(0, 20, 1, 0),
		Position = UDim2.new(1, -30, 0, 0),
		BackgroundTransparency = 1,
		Text = "→",
		TextColor3 = colors.dim,
		Font = fonts.body,
		TextSize = 12,
	}, btn)
	
	return btn
end

-- Crear botones de menú
local btnPlay = createMenuButton("BtnPlay", "▶", "Jugar", "Seleccionar nivel", colors.accent3)
btnPlay.Position = UDim2.new(0, 0, 0, 0)
local btnSettings = createMenuButton("BtnSettings", "⚙", "Ajustes", "Dificultad · Colores · Audio", colors.accent)
btnSettings.Position = UDim2.new(0, 0, 0, 70)
local btnCredits = createMenuButton("BtnCredits", "ℹ", "Créditos", "Equipo y herramientas", colors.accent2)
btnCredits.Position = UDim2.new(0, 0, 0, 140)
local btnExit = createMenuButton("BtnExit", "✕", "Salir", "", colors.danger)
btnExit.Position = UDim2.new(0, 0, 0, 210)

-- Divisor
local divider = create("Frame", {
	Name = "Divider",
	Size = UDim2.new(1, 0, 0, 1),
	Position = UDim2.new(0, 0, 0, 200),
	BackgroundColor3 = colors.border,
	BorderSizePixel = 0,
}, menuPanel)

-- Barra de estado inferior
local statusBar = create("Frame", {
	Name = "StatusBar",
	Size = UDim2.new(1, 0, 0, 32),
	Position = UDim2.new(0, 0, 1, -32),
	BackgroundColor3 = colors.surface,
	BorderColor3 = colors.border,
}, background)

local statusDot = create("Frame", {
	Name = "StatusDot",
	Size = UDim2.new(0, 6, 0, 6),
	Position = UDim2.new(0, 20, 0.5, -3),
	BackgroundColor3 = colors.accent3,
	BorderSizePixel = 0,
}, statusBar)
create("UICorner", { CornerRadius = UDim.new(0.5, 0) }, statusDot)

create("TextLabel", {
	Name = "StatusText",
	Size = UDim2.new(0, 120, 1, 0),
	Position = UDim2.new(0, 30, 0, 0),
	BackgroundTransparency = 1,
	Text = "Servidor conectado",
	TextColor3 = colors.muted,
	Font = fonts.mono,
	TextSize = 10,
	TextXAlignment = Enum.TextXAlignment.Left,
}, statusBar)

create("TextLabel", {
	Name = "LevelsText",
	Size = UDim2.new(0, 120, 1, 0),
	Position = UDim2.new(0, 160, 0, 0),
	BackgroundTransparency = 1,
	Text = "Niveles disponibles: 5",
	TextColor3 = colors.muted,
	Font = fonts.mono,
	TextSize = 10,
	TextXAlignment = Enum.TextXAlignment.Left,
}, statusBar)

create("TextLabel", {
	Name = "AlgoText",
	Size = UDim2.new(0, 250, 1, 0),
	Position = UDim2.new(0, 290, 0, 0),
	BackgroundTransparency = 1,
	Text = "Algoritmos: BFS · DFS · Dijkstra",
	TextColor3 = colors.muted,
	Font = fonts.mono,
	TextSize = 10,
	TextXAlignment = Enum.TextXAlignment.Left,
}, statusBar)

-- Versión
create("TextLabel", {
	Name = "Version",
	Size = UDim2.new(0, 100, 0, 20),
	Position = UDim2.new(1, -120, 1, -50),
	BackgroundTransparency = 1,
	Text = "BUILD 2.0.0",
	TextColor3 = colors.dim,
	Font = fonts.mono,
	TextSize = 10,
}, background)

-- Tooltip (para notificaciones)
local tooltip = create("TextLabel", {
	Name = "Tooltip",
	Size = UDim2.new(0, 200, 0, 30),
	Position = UDim2.new(0.5, -100, 1, -80),
	BackgroundColor3 = colors.panel,
	BorderColor3 = colors.border_hi,
	Text = "",
	TextColor3 = colors.accent,
	Font = fonts.mono,
	TextSize = 11,
	Visible = false,
}, background)
create("UICorner", { CornerRadius = UDim.new(0, 4) }, tooltip)

-- ===============================
-- Pantalla de selección de niveles
-- ===============================
local levelSelectScreen = create("Frame", {
	Name = "LevelSelectScreen",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = colors.bg,
	Visible = false,
}, screenGui)

-- Top bar
local topBar = create("Frame", {
	Name = "TopBar",
	Size = UDim2.new(1, 0, 0, 60),
	BackgroundColor3 = colors.surface,
	BorderColor3 = colors.border,
}, levelSelectScreen)

local backBtn = create("TextButton", {
	Name = "BackButton",
	Size = UDim2.new(0, 100, 0, 36),
	Position = UDim2.new(0, 20, 0.5, -18),
	BackgroundColor3 = colors.panel,
	BorderColor3 = colors.border,
	Text = "← VOLVER",
	TextColor3 = colors.muted,
	Font = fonts.mono,
	TextSize = 11,
}, topBar)
create("UICorner", { CornerRadius = UDim.new(0, 4) }, backBtn)

local breadcrumb = create("TextLabel", {
	Name = "Breadcrumb",
	Size = UDim2.new(0, 200, 1, 0),
	Position = UDim2.new(0, 140, 0, 0),
	BackgroundTransparency = 1,
	Text = "EDA Quest › Selección de Nivel",
	TextColor3 = colors.muted,
	Font = fonts.mono,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
}, topBar)

local playerTag = create("Frame", {
	Name = "PlayerTag",
	Size = UDim2.new(0, 120, 0, 36),
	Position = UDim2.new(1, -140, 0.5, -18),
	BackgroundColor3 = colors.panel,
	BorderColor3 = colors.accent,
	BorderSizePixel = 1,
}, topBar)
create("UICorner", { CornerRadius = UDim.new(0, 18) }, playerTag)

local avatar = create("Frame", {
	Name = "Avatar",
	Size = UDim2.new(0, 22, 0, 22),
	Position = UDim2.new(0, 6, 0.5, -11),
	BackgroundColor3 = colors.accent,
	BorderSizePixel = 0,
}, playerTag)
create("UICorner", { CornerRadius = UDim.new(0.5, 0) }, avatar)
create("TextLabel", {
	Name = "AvatarText",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Text = "P",
	TextColor3 = colors.bg,
	Font = fonts.bodyBold,
	TextSize = 12,
}, avatar)

create("TextLabel", {
	Name = "PlayerName",
	Size = UDim2.new(1, -30, 1, 0),
	Position = UDim2.new(0, 30, 0, 0),
	BackgroundTransparency = 1,
	Text = "Jugador_01",
	TextColor3 = colors.accent,
	Font = fonts.mono,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
}, playerTag)

-- Main layout
local mainLayout = create("Frame", {
	Name = "MainLayout",
	Size = UDim2.new(1, 0, 1, -60),
	Position = UDim2.new(0, 0, 0, 60),
	BackgroundTransparency = 1,
}, levelSelectScreen)

-- Sidebar
local sidebar = create("Frame", {
	Name = "Sidebar",
	Size = UDim2.new(0, 320, 1, 0),
	BackgroundColor3 = colors.surface,
	BorderColor3 = colors.border,
	BorderSizePixel = 1,
}, mainLayout)

local sidebarHead = create("Frame", {
	Name = "SidebarHead",
	Size = UDim2.new(1, 0, 0, 80),
	BackgroundTransparency = 1,
}, sidebar)

create("TextLabel", {
	Name = "Title",
	Size = UDim2.new(1, -40, 0, 20),
	Position = UDim2.new(0, 20, 0, 20),
	BackgroundTransparency = 1,
	Text = "INFORMACIÓN",
	TextColor3 = colors.text,
	Font = fonts.title,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
}, sidebarHead)

create("TextLabel", {
	Name = "Sub",
	Size = UDim2.new(1, -40, 0, 20),
	Position = UDim2.new(0, 20, 0, 45),
	BackgroundTransparency = 1,
	Text = "Selecciona un nivel para ver detalles",
	TextColor3 = colors.muted,
	Font = fonts.body,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
}, sidebarHead)

-- Placeholder
local placeholder = create("Frame", {
	Name = "Placeholder",
	Size = UDim2.new(1, 0, 1, -80),
	Position = UDim2.new(0, 0, 0, 80),
	BackgroundTransparency = 1,
	Visible = true,
}, sidebar)

create("TextLabel", {
	Name = "Icon",
	Size = UDim2.new(1, 0, 0, 50),
	Position = UDim2.new(0, 0, 0.3, -25),
	BackgroundTransparency = 1,
	Text = "🗺️",
	TextColor3 = colors.muted,
	Font = fonts.body,
	TextSize = 40,
}, placeholder)

create("TextLabel", {
	Name = "Text",
	Size = UDim2.new(1, -40, 0, 60),
	Position = UDim2.new(0, 20, 0.5, -30),
	BackgroundTransparency = 1,
	Text = "Selecciona una tarjeta de nivel para ver su información, estadísticas y comenzar a jugar.",
	TextColor3 = colors.muted,
	Font = fonts.body,
	TextSize = 12,
	TextWrapped = true,
}, placeholder)

-- Info content (inicialmente oculto)
local infoContent = create("Frame", {
	Name = "InfoContent",
	Size = UDim2.new(1, 0, 1, -80),
	Position = UDim2.new(0, 0, 0, 80),
	BackgroundTransparency = 1,
	Visible = false,
}, sidebar)

local hero = create("Frame", {
	Name = "Hero",
	Size = UDim2.new(1, 0, 0, 140),
	BackgroundColor3 = colors.panel,
	BorderColor3 = colors.border,
}, infoContent)

local heroGlow = create("Frame", {
	Name = "HeroGlow",
	Size = UDim2.new(0, 120, 0, 120),
	Position = UDim2.new(0.5, -60, 0.5, -60),
	BackgroundColor3 = colors.accent,
	BackgroundTransparency = 0.7,
	BorderSizePixel = 0,
}, hero)
create("UICorner", { CornerRadius = UDim.new(0.5, 0) }, heroGlow)

local heroEmoji = create("TextLabel", {
	Name = "HeroEmoji",
	Size = UDim2.new(0, 60, 0, 60),
	Position = UDim2.new(0.5, -30, 0.5, -30),
	BackgroundTransparency = 1,
	Text = "🧪",
	TextColor3 = colors.text,
	Font = fonts.body,
	TextSize = 48,
}, hero)

local heroBadge = create("Frame", {
	Name = "HeroBadge",
	Size = UDim2.new(0, 100, 0, 24),
	Position = UDim2.new(1, -110, 0, 10),
	BackgroundColor3 = colors.accent3,
	BackgroundTransparency = 0.9,
	BorderColor3 = colors.accent3,
	BorderSizePixel = 1,
}, hero)
create("UICorner", { CornerRadius = UDim.new(0, 4) }, heroBadge)
local heroBadgeText = create("TextLabel", {
	Name = "Text",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Text = "DISPONIBLE",
	TextColor3 = colors.accent3,
	Font = fonts.mono,
	TextSize = 9,
}, heroBadge)

local infoBody = create("ScrollingFrame", {
	Name = "InfoBody",
	Size = UDim2.new(1, 0, 1, -140),
	Position = UDim2.new(0, 0, 0, 140),
	BackgroundTransparency = 1,
	ScrollBarThickness = 4,
	CanvasSize = UDim2.new(0, 0, 0, 400),
}, infoContent)

local infoTag = create("TextLabel", {
	Name = "Tag",
	Size = UDim2.new(1, -40, 0, 20),
	Position = UDim2.new(0, 20, 0, 10),
	BackgroundTransparency = 1,
	Text = "NIVEL 0 · FUNDAMENTOS",
	TextColor3 = colors.accent,
	Font = fonts.mono,
	TextSize = 10,
	TextXAlignment = Enum.TextXAlignment.Left,
}, infoBody)

local infoName = create("TextLabel", {
	Name = "Name",
	Size = UDim2.new(1, -40, 0, 30),
	Position = UDim2.new(0, 20, 0, 35),
	BackgroundTransparency = 1,
	Text = "Laboratorio de Grafos",
	TextColor3 = colors.text,
	Font = fonts.title,
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Left,
}, infoBody)

local infoDesc = create("TextLabel", {
	Name = "Desc",
	Size = UDim2.new(1, -40, 0, 60),
	Position = UDim2.new(0, 20, 0, 70),
	BackgroundTransparency = 1,
	Text = "Descripción del nivel...",
	TextColor3 = colors.muted,
	Font = fonts.body,
	TextSize = 12,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
}, infoBody)

local starsFrame = create("Frame", {
	Name = "Stars",
	Size = UDim2.new(1, -40, 0, 30),
	Position = UDim2.new(0, 20, 0, 140),
	BackgroundTransparency = 1,
}, infoBody)
local stars = {}
for i = 1, 3 do
	stars[i] = create("TextLabel", {
		Name = "Star"..i,
		Size = UDim2.new(0, 30, 1, 0),
		Position = UDim2.new(0, (i-1)*30, 0, 0),
		BackgroundTransparency = 1,
		Text = "⭐",
		TextColor3 = colors.gold,
		TextTransparency = 0.8,
		Font = fonts.body,
		TextSize = 20,
	}, starsFrame)
end

local statsGrid = create("Frame", {
	Name = "StatsGrid",
	Size = UDim2.new(1, -40, 0, 120),
	Position = UDim2.new(0, 20, 0, 180),
	BackgroundTransparency = 1,
}, infoBody)

local function createStatBox(pos, label, value, color)
	local box = create("Frame", {
		Name = "StatBox",
		Size = UDim2.new(0.5, -5, 0, 50),
		Position = pos,
		BackgroundColor3 = colors.panel,
		BorderColor3 = colors.border,
	}, statsGrid)
	create("UICorner", { CornerRadius = UDim.new(0, 6) }, box)
	create("TextLabel", {
		Name = "Label",
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 0, 0, 6),
		BackgroundTransparency = 1,
		Text = label,
		TextColor3 = colors.muted,
		Font = fonts.mono,
		TextSize = 9,
	}, box)
	local val = create("TextLabel", {
		Name = "Value",
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0, 22),
		BackgroundTransparency = 1,
		Text = value,
		TextColor3 = color or colors.text,
		Font = fonts.mono,
		TextSize = 14,
	}, box)
	return val
end

local statScore = createStatBox(UDim2.new(0, 0, 0, 0), "Récord", "—", colors.gold)
local statStatus = createStatBox(UDim2.new(0.5, 5, 0, 0), "Estado", "—", colors.accent)
local statAciertos = createStatBox(UDim2.new(0, 0, 0, 55), "Aciertos", "—", colors.accent3)
local statFallos = createStatBox(UDim2.new(0.5, 5, 0, 55), "Fallos", "—", colors.danger)
local statTiempo = createStatBox(UDim2.new(0, 0, 0, 110), "Mejor Tiempo", "—", colors.accent)
local statIntentos = createStatBox(UDim2.new(0.5, 5, 0, 110), "Intentos", "—", colors.text)

local tagsFrame = create("Frame", {
	Name = "Tags",
	Size = UDim2.new(1, -40, 0, 40),
	Position = UDim2.new(0, 20, 0, 310),
	BackgroundTransparency = 1,
}, infoBody)

-- Play button area
local playArea = create("Frame", {
	Name = "PlayArea",
	Size = UDim2.new(1, 0, 0, 70),
	Position = UDim2.new(0, 0, 1, -70),
	BackgroundTransparency = 1,
}, sidebar)

local playBtn = create("TextButton", {
	Name = "PlayButton",
	Size = UDim2.new(0, 280, 0, 44),
	Position = UDim2.new(0.5, -140, 0.5, -22),
	BackgroundColor3 = colors.accent3,
	BorderSizePixel = 0,
	Text = "🔒  SELECCIONA UN NIVEL",
	TextColor3 = colors.bg,
	Font = fonts.mono,
	TextSize = 12,
}, playArea)
create("UICorner", { CornerRadius = UDim.new(0, 8) }, playBtn)

-- Grid area (derecha)
local gridArea = create("ScrollingFrame", {
	Name = "GridArea",
	Size = UDim2.new(1, -320, 1, 0),
	Position = UDim2.new(0, 320, 0, 0),
	BackgroundTransparency = 1,
	ScrollBarThickness = 4,
	CanvasSize = UDim2.new(0, 0, 0, 800),
}, mainLayout)

-- Progress bar
local progressBar = create("Frame", {
	Name = "ProgressBar",
	Size = UDim2.new(1, -40, 0, 70),
	Position = UDim2.new(0, 20, 0, 20),
	BackgroundColor3 = colors.panel,
	BorderColor3 = colors.border,
}, gridArea)
create("UICorner", { CornerRadius = UDim.new(0, 8) }, progressBar)

create("TextLabel", {
	Name = "ProgressText",
	Size = UDim2.new(0, 80, 1, 0),
	Position = UDim2.new(0, 20, 0, 0),
	BackgroundTransparency = 1,
	Text = "2 / 5",
	TextColor3 = colors.text,
	Font = fonts.title,
	TextSize = 20,
	TextXAlignment = Enum.TextXAlignment.Left,
}, progressBar)

create("TextLabel", {
	Name = "ProgressSub",
	Size = UDim2.new(0, 120, 1, 0),
	Position = UDim2.new(0, 100, 0, 0),
	BackgroundTransparency = 1,
	Text = "Niveles completados",
	TextColor3 = colors.muted,
	Font = fonts.body,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
}, progressBar)

local barTrack = create("Frame", {
	Name = "BarTrack",
	Size = UDim2.new(0.5, -50, 0, 6),
	Position = UDim2.new(0.5, 20, 0.5, -3),
	BackgroundColor3 = colors.border,
	BorderSizePixel = 0,
}, progressBar)
create("UICorner", { CornerRadius = UDim.new(0, 3) }, barTrack)

local barFill = create("Frame", {
	Name = "BarFill",
	Size = UDim2.new(0.4, 0, 1, 0),
	BackgroundColor3 = colors.accent3,
	BorderSizePixel = 0,
}, barTrack)
create("UICorner", { CornerRadius = UDim.new(0, 3) }, barFill)

create("TextLabel", {
	Name = "ProgressPct",
	Size = UDim2.new(0, 50, 1, 0),
	Position = UDim2.new(1, -70, 0, 0),
	BackgroundTransparency = 1,
	Text = "40%",
	TextColor3 = colors.accent3,
	Font = fonts.mono,
	TextSize = 12,
}, progressBar)

-- Secciones de niveles
local sections = {
	{ title = "Introducción a Grafos", count = 2, y = 110 },
	{ title = "Algoritmos de Búsqueda", count = 2, y = 350 },
	{ title = "Rutas Óptimas", count = 1, y = 590 },
}

for _, sec in ipairs(sections) do
	local head = create("Frame", {
		Name = "SectionHead",
		Size = UDim2.new(1, -40, 0, 30),
		Position = UDim2.new(0, 20, 0, sec.y),
		BackgroundTransparency = 1,
	}, gridArea)
	
	create("TextLabel", {
		Name = "Title",
		Size = UDim2.new(0, 200, 1, 0),
		BackgroundTransparency = 1,
		Text = sec.title,
		TextColor3 = colors.muted,
		Font = fonts.mono,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, head)
	
	local line = create("Frame", {
		Name = "Line",
		Size = UDim2.new(1, -300, 0, 1),
		Position = UDim2.new(0, 210, 0.5, 0),
		BackgroundColor3 = colors.border,
		BorderSizePixel = 0,
	}, head)
	
	create("TextLabel", {
		Name = "Count",
		Size = UDim2.new(0, 50, 1, 0),
		Position = UDim2.new(1, -60, 0, 0),
		BackgroundTransparency = 1,
		Text = sec.count.." niveles",
		TextColor3 = colors.dim,
		Font = fonts.mono,
		TextSize = 10,
	}, head)
	
	local gridContainer = create("Frame", {
		Name = "GridContainer",
		Size = UDim2.new(1, -40, 0, 220),
		Position = UDim2.new(0, 20, 0, sec.y+40),
		BackgroundTransparency = 1,
	}, gridArea)
	
	-- Aquí se insertarán las tarjetas dinámicamente con el LocalScript
end

-- Modales (simplificados, se crearán en el LocalScript)

-- Agregar LocalScript con la lógica
local scriptContent = [[
-- LocalScript dentro de EDAQuestMenu
local screenGui = script.Parent
local background = screenGui:WaitForChild("Background")
local levelSelect = screenGui:WaitForChild("LevelSelectScreen")
local tooltip = background:WaitForChild("Tooltip")

-- Colores (definidos en el script de creación, pero aquí los referenciamos)
local colors = {
	accent = Color3.fromRGB(0,212,255),
	accent2 = Color3.fromRGB(124,58,237),
	accent3 = Color3.fromRGB(16,185,129),
	danger = Color3.fromRGB(239,68,68),
	gold = Color3.fromRGB(245,158,11),
	text = Color3.fromRGB(226,232,240),
	muted = Color3.fromRGB(100,116,139),
	border = Color3.fromRGB(30,45,66),
}

-- Datos de niveles (simulados)
local levels = {
	{
		id = 0,
		nombre = "Laboratorio de Grafos",
		seccion = "intro",
		descripcion = "El laboratorio de introducción. Aprende qué es un grafo, qué son los nodos y las aristas.",
		emoji = "🧪",
		algoritmo = "Grafos No Dirigidos",
		conceptos = {"Nodos","Aristas","Adyacencia","Grado"},
		desbloqueado = true,
		estrellas = 3,
		highScore = 1480,
		aciertos = 12,
		fallos = 1,
		tiempoMejor = "2:34",
		intentos = 3,
	},
	{
		id = 1,
		nombre = "La Red Desconectada",
		seccion = "intro",
		descripcion = "Una red eléctrica urbana ha perdido sus conexiones.",
		emoji = "🏙️",
		algoritmo = "Conectividad",
		conceptos = {"Grafo Conexo","BFS","Componentes"},
		desbloqueado = true,
		estrellas = 2,
		highScore = 960,
		aciertos = 8,
		fallos = 4,
		tiempoMejor = "4:12",
		intentos = 5,
	},
	{
		id = 2,
		nombre = "La Fábrica de Señales",
		seccion = "busqueda",
		descripcion = "Las señales deben llegar desde el origen a todos los destinos.",
		emoji = "🏭",
		algoritmo = "BFS · DFS",
		conceptos = {"BFS","DFS","Árbol de búsqueda"},
		desbloqueado = true,
		estrellas = 0,
		highScore = 0,
		aciertos = 0,
		fallos = 0,
		tiempoMejor = nil,
		intentos = 0,
	},
	{
		id = 3,
		nombre = "El Puente Roto",
		seccion = "busqueda",
		descripcion = "Algunos puentes de la ciudad han colapsado creando un grafo dirigido.",
		emoji = "🌉",
		algoritmo = "Grafos Dirigidos",
		conceptos = {"Dígrafo","In-degree","Out-degree"},
		desbloqueado = false,
		estrellas = 0,
		highScore = 0,
		aciertos = 0,
		fallos = 0,
		tiempoMejor = nil,
		intentos = 0,
	},
	{
		id = 4,
		nombre = "Ruta Mínima",
		seccion = "rutas",
		descripcion = "Encuentra la ruta más corta en un grafo con pesos.",
		emoji = "🗺️",
		algoritmo = "Dijkstra",
		conceptos = {"Grafo Ponderado","Dijkstra","Camino Mínimo"},
		desbloqueado = false,
		estrellas = 0,
		highScore = 0,
		aciertos = 0,
		fallos = 0,
		tiempoMejor = nil,
		intentos = 0,
	},
}

-- Función para mostrar tooltip
local function showToast(text, duration)
	tooltip.Text = text
	tooltip.Visible = true
	task.wait(duration or 2)
	tooltip.Visible = false
end

-- Navegación entre pantallas
local function openLevelSelect()
	screenGui.LevelSelectScreen.Visible = true
	screenGui.Background.Visible = false
end

local function closeLevelSelect()
	screenGui.LevelSelectScreen.Visible = false
	screenGui.Background.Visible = true
end

-- Conectar botones del menú principal
local menuButtons = background:WaitForChild("MenuPanel")
menuButtons.BtnPlay.MouseButton1Click:Connect(openLevelSelect)
menuButtons.BtnSettings.MouseButton1Click:Connect(function() showToast("Ajustes - En construcción") end)
menuButtons.BtnCredits.MouseButton1Click:Connect(function() showToast("Créditos - Equipo de desarrollo") end)
menuButtons.BtnExit.MouseButton1Click:Connect(function() showToast("Saliendo del juego...") end)

-- Botón volver en selector de niveles
levelSelect.TopBar.BackButton.MouseButton1Click:Connect(closeLevelSelect)

-- Construir tarjetas de niveles
local gridArea = levelSelect:WaitForChild("MainLayout"):WaitForChild("GridArea")
local sections = { "intro", "busqueda", "rutas" }
local sectionTitles = { "Introducción a Grafos", "Algoritmos de Búsqueda", "Rutas Óptimas" }
local yPos = 110

for secIdx, secName in ipairs(sections) do
	local container = nil
	-- Buscar el contenedor correspondiente (ya creado estáticamente)
	-- En este script, asumimos que los contenedores existen con nombres específicos.
	-- Para simplificar, buscaremos por el título de la sección.
	-- Pero como es más fácil, los crearemos dinámicamente.
	-- Aquí solo generamos las tarjetas y las insertamos en los contenedores ya creados.
	-- Como no tenemos referencias directas, podemos buscar los frames por posición.
	-- Mejor: al crear los contenedores les asignamos nombres únicos.
	-- En el script de creación, cada contenedor podría tener un nombre como "GridIntro", etc.
	-- Para no complicar, en este ejemplo simplemente agregaremos las tarjetas al gridArea después de las cabeceras.
	-- Pero para mantener el orden, lo haremos con un Layout.
end

-- Selección de nivel
local selectedLevel = nil
local infoContent = levelSelect:WaitForChild("MainLayout"):WaitForChild("Sidebar"):WaitForChild("InfoContent")
local placeholder = levelSelect:WaitForChild("MainLayout"):WaitForChild("Sidebar"):WaitForChild("Placeholder")
local playBtn = levelSelect:WaitForChild("MainLayout"):WaitForChild("Sidebar"):WaitForChild("PlayArea"):WaitForChild("PlayButton")

local function updateInfoPanel(level)
	placeholder.Visible = false
	infoContent.Visible = true
	
	infoContent.Hero.HeroEmoji.Text = level.emoji
	infoContent.InfoBody.Tag.Text = "NIVEL "..level.id.." · "..string.upper(level.algoritmo)
	infoContent.InfoBody.Name.Text = level.nombre
	infoContent.InfoBody.Desc.Text = level.descripcion
	
	for i=1,3 do
		local star = infoContent.InfoBody.Stars["Star"..i]
		if i <= level.estrellas then
			star.TextTransparency = 0
		else
			star.TextTransparency = 0.8
		end
	end
	
	infoContent.InfoBody.StatsGrid.StatScore.Value.Text = (level.highScore > 0 and level.highScore.." pts") or "—"
	infoContent.InfoBody.StatsGrid.StatStatus.Value.Text = (level.estrellas == 3 and "★★★") or (level.estrellas > 0 and "PROGRESO") or "NUEVO"
	infoContent.InfoBody.StatsGrid.StatAciertos.Value.Text = (level.aciertos > 0 and level.aciertos) or "—"
	infoContent.InfoBody.StatsGrid.StatFallos.Value.Text = (level.fallos > 0 and level.fallos) or "—"
	infoContent.InfoBody.StatsGrid.StatTiempo.Value.Text = level.tiempoMejor or "—"
	infoContent.InfoBody.StatsGrid.StatIntentos.Value.Text = (level.intentos > 0 and level.intentos) or "—"
	
	playBtn.Text = "▶  JUGAR NIVEL "..level.id
	playBtn.BackgroundColor3 = colors.accent3
end

-- Función para crear una tarjeta
local function createLevelCard(level)
	local card = Instance.new("Frame")
	card.Name = "LevelCard_"..level.id
	card.Size = UDim2.new(0, 220, 0, 160)
	card.BackgroundColor3 = Color3.fromRGB(17,25,39)
	card.BorderColor3 = Color3.fromRGB(30,45,66)
	card.BorderSizePixel = 1
	
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 8)
	uiCorner.Parent = card
	
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, -20, 0, 30)
	header.Position = UDim2.new(0, 10, 0, 10)
	header.BackgroundTransparency = 1
	header.Parent = card
	
	local num = Instance.new("TextLabel")
	num.Name = "Num"
	num.Size = UDim2.new(0, 60, 1, 0)
	num.BackgroundTransparency = 1
	num.Text = "Nivel "..level.id
	num.TextColor3 = Color3.fromRGB(0,212,255)
	num.Font = Enum.Font.SourceCode
	num.TextSize = 10
	num.TextXAlignment = Enum.TextXAlignment.Left
	num.Parent = header
	
	local badge = Instance.new("Frame")
	badge.Name = "Badge"
	badge.Size = UDim2.new(0, 80, 0, 20)
	badge.Position = UDim2.new(1, -80, 0, 5)
	badge.BackgroundColor3 = (level.desbloqueado and (level.estrellas>0 and Color3.fromRGB(245,158,11) or Color3.fromRGB(16,185,129))) or Color3.fromRGB(100,116,139)
	badge.BackgroundTransparency = 0.9
	badge.BorderColor3 = (level.desbloqueado and (level.estrellas>0 and Color3.fromRGB(245,158,11) or Color3.fromRGB(16,185,129))) or Color3.fromRGB(100,116,139)
	badge.BorderSizePixel = 1
	badge.Parent = header
	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0, 4)
	badgeCorner.Parent = badge
	
	local badgeText = Instance.new("TextLabel")
	badgeText.Size = UDim2.new(1, 0, 1, 0)
	badgeText.BackgroundTransparency = 1
	badgeText.Text = (level.desbloqueado and (level.estrellas>0 and "✓ Completado" or "Disponible")) or "🔒 Bloqueado"
	badgeText.TextColor3 = (level.desbloqueado and (level.estrellas>0 and Color3.fromRGB(245,158,11) or Color3.fromRGB(16,185,129))) or Color3.fromRGB(100,116,139)
	badgeText.Font = Enum.Font.SourceCode
	badgeText.TextSize = 9
	badgeText.Parent = badge
	
	local emoji = Instance.new("TextLabel")
	emoji.Name = "Emoji"
	emoji.Size = UDim2.new(1, 0, 0, 40)
	emoji.Position = UDim2.new(0, 0, 0, 40)
	emoji.BackgroundTransparency = 1
	emoji.Text = level.emoji
	emoji.TextColor3 = Color3.fromRGB(226,232,240)
	emoji.Font = Enum.Font.SourceSans
	emoji.TextSize = 28
	emoji.Parent = card
	
	local body = Instance.new("Frame")
	body.Name = "Body"
	body.Size = UDim2.new(1, -20, 0, 50)
	body.Position = UDim2.new(0, 10, 0, 80)
	body.BackgroundTransparency = 1
	body.Parent = card
	
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 20)
	title.BackgroundTransparency = 1
	title.Text = level.nombre
	title.TextColor3 = Color3.fromRGB(226,232,240)
	title.Font = Enum.Font.SourceSansBold
	title.TextSize = 13
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = body
	
	local algo = Instance.new("TextLabel")
	algo.Name = "Algo"
	algo.Size = UDim2.new(1, 0, 0, 16)
	algo.Position = UDim2.new(0, 0, 0, 22)
	algo.BackgroundTransparency = 1
	algo.Text = "● "..level.algoritmo
	algo.TextColor3 = Color3.fromRGB(124,58,237)
	algo.Font = Enum.Font.SourceCode
	algo.TextSize = 10
	algo.TextXAlignment = Enum.TextXAlignment.Left
	algo.Parent = body
	
	local footer = Instance.new("Frame")
	footer.Name = "Footer"
	footer.Size = UDim2.new(1, 0, 0, 30)
	footer.Position = UDim2.new(0, 0, 1, -30)
	footer.BackgroundColor3 = Color3.fromRGB(17,25,39)
	footer.BorderColor3 = Color3.fromRGB(30,45,66)
	footer.BorderSizePixel = 1
	footer.Parent = card
	
	local starsFrame = Instance.new("Frame")
	starsFrame.Name = "Stars"
	starsFrame.Size = UDim2.new(0, 80, 1, 0)
	starsFrame.Position = UDim2.new(0, 10, 0, 0)
	starsFrame.BackgroundTransparency = 1
	starsFrame.Parent = footer
	
	for i=1,3 do
		local s = Instance.new("TextLabel")
		s.Size = UDim2.new(0, 20, 1, 0)
		s.Position = UDim2.new(0, (i-1)*20, 0, 0)
		s.BackgroundTransparency = 1
		s.Text = "⭐"
		s.TextColor3 = Color3.fromRGB(245,158,11)
		s.TextTransparency = (i <= level.estrellas and 0) or 0.8
		s.Font = Enum.Font.SourceSans
		s.TextSize = 16
		s.Parent = starsFrame
	end
	
	local score = Instance.new("TextLabel")
	score.Name = "Score"
	score.Size = UDim2.new(0, 80, 1, 0)
	score.Position = UDim2.new(1, -90, 0, 0)
	score.BackgroundTransparency = 1
	score.Text = (level.highScore > 0 and level.highScore.." pts") or "—"
	score.TextColor3 = Color3.fromRGB(245,158,11)
	score.Font = Enum.Font.SourceCode
	score.TextSize = 10
	score.Parent = footer
	
	if not level.desbloqueado then
		local lock = Instance.new("Frame")
		lock.Size = UDim2.new(1, 0, 1, 0)
		lock.BackgroundColor3 = Color3.fromRGB(0,0,0)
		lock.BackgroundTransparency = 0.5
		lock.BorderSizePixel = 0
		lock.Parent = card
		local lockText = Instance.new("TextLabel")
		lockText.Size = UDim2.new(1, 0, 1, 0)
		lockText.BackgroundTransparency = 1
		lockText.Text = "🔒"
		lockText.TextColor3 = Color3.fromRGB(255,255,255)
		lockText.Font = Enum.Font.SourceSans
		lockText.TextSize = 30
		lockText.Parent = lock
	end
	
	card.MouseButton1Click:Connect(function()
		if level.desbloqueado then
			selectedLevel = level.id
			updateInfoPanel(level)
		end
	end)
	
	return card
end

-- Insertar tarjetas en los contenedores apropiados
local containers = {
	intro = gridArea:FindFirstChild("GridIntro"), -- Necesitaríamos haberlos nombrado
	busqueda = gridArea:FindFirstChild("GridBusqueda"),
	rutas = gridArea:FindFirstChild("GridRutas"),
}

-- Si no existen, los creamos ahora
for secName, container in pairs(containers) do
	if not container then
		container = Instance.new("Frame")
		container.Name = "Grid"..secName:gsub("^%l", string.upper)
		container.Size = UDim2.new(1, -40, 0, 220)
		container.Position = UDim2.new(0, 20, 0, yPos+40)
		container.BackgroundTransparency = 1
		container.Parent = gridArea
		containers[secName] = container
		yPos = yPos + 260
	end
end

for _, level in ipairs(levels) do
	local card = createLevelCard(level)
	card.Parent = containers[level.seccion]
	-- Posicionamiento manual simple (se puede usar un UIListLayout)
end

-- Ajustar canvas del ScrollingFrame
local function updateCanvas()
	local totalHeight = 0
	for _, child in ipairs(gridArea:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "ProgressBar" then
			totalHeight = totalHeight + child.AbsoluteSize.Y + 20
		end
	end
	gridArea.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 100)
end

task.wait(0.1)
updateCanvas()

-- Botón jugar
playBtn.MouseButton1Click:Connect(function()
	if selectedLevel then
		showToast("Cargando nivel "..selectedLevel.."...", 1)
		-- Aquí se cargaría el nivel
	end
end)

-- Cerrar con Escape
local userInput = game:GetService("UserInputService")
userInput.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Escape then
		if levelSelect.Visible then
			closeLevelSelect()
		end
	end
end)

-- Inicializar
showToast("Bienvenido a EDA Quest", 3)
]]

local luaScript = Instance.new("LocalScript")
luaScript.Name = "MenuLogic"
luaScript.Source = scriptContent
luaScript.Parent = screenGui

print("Menú principal de EDA Quest creado en StarterGui.")