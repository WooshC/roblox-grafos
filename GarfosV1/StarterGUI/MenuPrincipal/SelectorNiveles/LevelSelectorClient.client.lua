-- StarterGui/MenuPrincipal/SelectorNiveles/LevelSelectorClient.client.lua
-- Estructura real:
-- SelectorNiveles (Folder)
--   └── Contenedor_2 (Frame)
--         ├── Header > Icon, Titulo, BtnCerrar
--         └── Body
--               ├── GridFrame (vacío, se llena por script)
--               └── InfoPanel
--                     ├── Placeholder
--                     └── InfoContent
--                           ├── InfoImageBg > NivelImagen (ImageLabel)
--                           ├── InfoBody > InfoTag, InfoTitle, InfoDesc,
--                           │             StarsFrame (Estrella1/2/3),
--                           │             StatsGrid (StatRecord, StatStatus)
--                           └── BtnJugar

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ─── REMOTOS ──────────────────────────────────────────────────
local LevelsConfig     = require(ReplicatedStorage:WaitForChild("LevelsConfig"))
local Remotes          = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes")
local GetProgressFunc  = Remotes:WaitForChild("GetPlayerProgress", 10)
local RequestPlayEvent = Remotes:WaitForChild("RequestPlayLevel",  10)

if not GetProgressFunc or not RequestPlayEvent then
	warn("❌ LevelSelectorClient: Remotos no encontrados")
	return
end

-- ─── REFERENCIAS UI ───────────────────────────────────────────
local SelectorFolder  = script.Parent                             -- Folder SelectorNiveles
local Contenedor      = SelectorFolder:WaitForChild("Contenedor_2")
local Header          = Contenedor:WaitForChild("Header")
local Body            = Contenedor:WaitForChild("Body")
local GridFrame       = Body:WaitForChild("GridFrame")
local InfoPanel       = Body:WaitForChild("InfoPanel")

local BtnCerrar       = Header:WaitForChild("BtnCerrar")

local Placeholder     = InfoPanel:WaitForChild("Placeholder")
local InfoContent     = InfoPanel:WaitForChild("InfoContent")

local InfoImageBg     = InfoContent:WaitForChild("InfoImageBg")
local NivelImagen     = InfoImageBg:WaitForChild("NivelImagen")   -- ImageLabel creado en el editor
local InfoBody        = InfoContent:WaitForChild("InfoBody")
local BtnJugar        = InfoContent:WaitForChild("BtnJugar")

local InfoTag         = InfoBody:WaitForChild("InfoTag")
local InfoTitle       = InfoBody:WaitForChild("InfoTitle")
local InfoDesc        = InfoBody:WaitForChild("InfoDesc")
local StarsFrame      = InfoBody:WaitForChild("StarsFrame")
local StatsGrid       = InfoBody:WaitForChild("StatsGrid")

local Estrella = {
	StarsFrame:WaitForChild("Estrella1"),
	StarsFrame:WaitForChild("Estrella2"),
	StarsFrame:WaitForChild("Estrella3"),
}

local StatRecord = StatsGrid:WaitForChild("StatRecord"):WaitForChild("StatValue")
local StatStatus = StatsGrid:WaitForChild("StatStatus"):WaitForChild("StatValue")

-- ─── COLORES ──────────────────────────────────────────────────
local C = {
	accent     = Color3.fromRGB(0, 212, 255),
	gold       = Color3.fromRGB(255, 215, 0),
	green      = Color3.fromRGB(0, 255, 136),
	muted      = Color3.fromRGB(74, 96, 128),
	black      = Color3.fromRGB(0, 0, 0),
	locked     = Color3.fromRGB(42, 52, 69),
	cardBg     = Color3.fromRGB(19, 26, 43),
	cardActive = Color3.fromRGB(13, 30, 53),
	border     = Color3.fromRGB(30, 45, 71),
	white      = Color3.fromRGB(255, 255, 255),
}

-- ─── ESTADO ───────────────────────────────────────────────────
local NivelSeleccionado = nil
local DatosJugador      = nil
local ResultsLastRun    = nil
local Cargando          = false
local BotonesBloqueados = false
local cardRefs          = {}

-- =====================================================
-- PANEL INFO
-- =====================================================

local function mostrarPlaceholder()
	Placeholder.Visible = true
	InfoContent.Visible = false
	NivelSeleccionado   = nil
end

local function actualizarPanelInfo(levelID)
	local config = LevelsConfig[levelID]
	if not config then return end
	NivelSeleccionado = levelID

	local data      = DatosJugador and DatosJugador.Levels[tostring(levelID)]
	local unlocked  = data and data.Unlocked  or false
	local estrellas = data and data.Stars     or 0
	local score     = data and data.HighScore or 0

	if ResultsLastRun and ResultsLastRun.LevelID == levelID then
		estrellas = ResultsLastRun.Stars
		score     = ResultsLastRun.Score
	end

	-- Imagen del nivel (si existe)
	NivelImagen.Image = config.ImageId or ""

	InfoTag.Text   = "NIVEL " .. levelID .. (config.Algoritmo and (" · " .. config.Algoritmo) or " · EDUCATIVO")
	InfoTitle.Text = config.Nombre or ("Nivel " .. levelID)
	InfoDesc.Text  = config.Descripcion or config.DescripcionCorta or ""

	for i, s in ipairs(Estrella) do
		s.TextTransparency = i <= estrellas and 0 or 0.75
	end

	StatRecord.Text       = score > 0 and (tostring(score) .. " pts") or "—"
	StatRecord.TextColor3 = C.gold

	if not unlocked then
		StatStatus.Text       = "BLOQUEADO"
		StatStatus.TextColor3 = C.muted
	elseif estrellas == 3 then
		StatStatus.Text       = "★★★"
		StatStatus.TextColor3 = C.gold
	elseif estrellas > 0 then
		StatStatus.Text       = "PROGRESO"
		StatStatus.TextColor3 = C.accent
	else
		StatStatus.Text       = "NUEVO"
		StatStatus.TextColor3 = C.green
	end

	if unlocked then
		BtnJugar.Text             = "▶  JUGAR NIVEL " .. levelID
		BtnJugar.BackgroundColor3 = C.accent
		BtnJugar.TextColor3       = C.black
		BtnJugar.AutoButtonColor  = true
	else
		BtnJugar.Text             = "🔒  NIVEL BLOQUEADO"
		BtnJugar.BackgroundColor3 = C.locked
		BtnJugar.TextColor3       = C.muted
		BtnJugar.AutoButtonColor  = false
	end

	Placeholder.Visible = false
	InfoContent.Visible = true
end

-- =====================================================
-- CARDS (creación dinámica)
-- =====================================================

local function resaltarCard(id)
	for lid, ref in pairs(cardRefs) do
		if lid == id then
			ref.card.BackgroundColor3 = C.cardActive
			ref.stroke.Color          = C.accent
			ref.stroke.Thickness      = 1.5
		else
			ref.card.BackgroundColor3 = C.cardBg
			ref.stroke.Color          = C.border
			ref.stroke.Thickness      = 1
		end
	end
end

local function limpiarCards()
	for _, ref in pairs(cardRefs) do
		if ref.card and ref.card.Parent then ref.card:Destroy() end
	end
	cardRefs = {}
end

local function crearCard(levelID, config, nivelData)
	local unlocked  = nivelData and nivelData.Unlocked  or false
	local estrellas = nivelData and nivelData.Stars     or 0
	local score     = nivelData and nivelData.HighScore or 0

	local card = Instance.new("Frame")
	card.Name             = "Card_" .. levelID
	card.BackgroundColor3 = C.cardBg
	card.BorderSizePixel  = 0
	card.LayoutOrder      = levelID + 1  -- Para ordenar según ID
	card.Parent           = GridFrame

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 12)
	uiCorner.Parent = card

	local uiStroke = Instance.new("UIStroke")
	uiStroke.Thickness = 1
	uiStroke.Color     = C.border
	uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	uiStroke.Parent = card

	local inner = Instance.new("Frame")
	inner.Size   = UDim2.new(1, -16, 1, -14)
	inner.Position = UDim2.new(0, 8, 0, 7)
	inner.BackgroundTransparency = 1
	inner.BorderSizePixel = 0
	inner.Parent = card

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.Padding       = UDim.new(0, 4)
	listLayout.Parent        = inner

	-- Imagen de la tarjeta (desde config)
	local cardImage = Instance.new("ImageLabel")
	cardImage.Name = "CardImage"
	cardImage.Size = UDim2.new(1, 0, 0, 70)  -- Alto fijo, ancho completo
	cardImage.BackgroundColor3 = C.cardBg
	cardImage.BackgroundTransparency = 0.2
	cardImage.Image = config.ImageId or ""
	cardImage.ScaleType = Enum.ScaleType.Crop
	cardImage.LayoutOrder = 0
	cardImage.Parent = inner

	-- Fila top
	local topRow = Instance.new("Frame")
	topRow.Size   = UDim2.new(1, 0, 0, 18)
	topRow.BackgroundTransparency = 1
	topRow.BorderSizePixel = 0
	topRow.LayoutOrder = 1
	topRow.Parent = inner

	local numLbl = Instance.new("TextLabel")
	numLbl.Size  = UDim2.new(0.55, 0, 1, 0)
	numLbl.Text  = "NIVEL " .. levelID
	numLbl.TextSize = 10
	numLbl.Font  = Enum.Font.GothamBold
	numLbl.TextColor3 = C.accent
	numLbl.BackgroundTransparency = 1
	numLbl.BorderSizePixel = 0
	numLbl.TextXAlignment = Enum.TextXAlignment.Left
	numLbl.Parent = topRow

	local badge = Instance.new("TextLabel")
	badge.Name  = "Badge"
	badge.Size  = UDim2.new(0.45, 0, 1, 0)
	badge.Position = UDim2.new(0.55, 0, 0, 0)
	badge.TextSize = 9
	badge.Font  = Enum.Font.GothamBold
	badge.BackgroundTransparency = 1
	badge.BorderSizePixel = 0
	badge.TextXAlignment = Enum.TextXAlignment.Right
	badge.Parent = topRow

	if not unlocked then
		badge.Text = "BLOQUEADO" ; badge.TextColor3 = C.muted
	elseif estrellas > 0 then
		badge.Text = "✓ COMPLETADO" ; badge.TextColor3 = C.green
	else
		badge.Text = "DISPONIBLE" ; badge.TextColor3 = C.accent
	end

	-- Nombre del nivel
	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size  = UDim2.new(1, 0, 0, 32)
	titleLbl.Text  = config.Nombre or ("Nivel " .. levelID)
	titleLbl.TextSize = 13
	titleLbl.Font  = Enum.Font.GothamBold
	titleLbl.TextColor3 = C.white
	titleLbl.BackgroundTransparency = 1
	titleLbl.BorderSizePixel = 0
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.TextWrapped    = true
	titleLbl.LayoutOrder    = 2
	titleLbl.Parent = inner

	-- Concepto (usamos Algoritmo o un texto por defecto)
	local concepto = config.Algoritmo or (levelID == 0 and "Fundamentos") or ""
	local concLbl = Instance.new("TextLabel")
	concLbl.Size  = UDim2.new(1, 0, 0, 14)
	concLbl.Text  = concepto
	concLbl.TextSize = 11
	concLbl.Font  = Enum.Font.Gotham
	concLbl.TextColor3 = C.muted
	concLbl.BackgroundTransparency = 1
	concLbl.BorderSizePixel = 0
	concLbl.TextXAlignment = Enum.TextXAlignment.Left
	concLbl.LayoutOrder    = 3
	concLbl.Parent = inner

	-- Footer
	local footer = Instance.new("Frame")
	footer.Size  = UDim2.new(1, 0, 0, 20)
	footer.BackgroundTransparency = 1
	footer.BorderSizePixel = 0
	footer.LayoutOrder     = 4
	footer.Parent = inner

	local line = Instance.new("Frame")
	line.Size  = UDim2.new(1, 0, 0, 1)
	line.BackgroundColor3 = C.border
	line.BorderSizePixel  = 0
	line.Parent = footer

	local starsStr = ""
	for i = 1, 3 do starsStr = starsStr .. (i <= estrellas and "⭐ " or "☆ ") end

	local starsLbl = Instance.new("TextLabel")
	starsLbl.Size  = UDim2.new(0.55, 0, 0, 18)
	starsLbl.Position = UDim2.new(0, 0, 0, 2)
	starsLbl.Text  = starsStr
	starsLbl.TextSize = 11
	starsLbl.Font  = Enum.Font.GothamBold
	starsLbl.TextColor3 = estrellas > 0 and C.gold or C.muted
	starsLbl.BackgroundTransparency = 1
	starsLbl.BorderSizePixel = 0
	starsLbl.TextXAlignment = Enum.TextXAlignment.Left
	starsLbl.Parent = footer

	local scoreLbl = Instance.new("TextLabel")
	scoreLbl.Size  = UDim2.new(0.45, 0, 0, 18)
	scoreLbl.Position = UDim2.new(0.55, 0, 0, 2)
	scoreLbl.Text  = score > 0 and (tostring(score) .. " pts") or "—"
	scoreLbl.TextSize = 10
	scoreLbl.Font  = Enum.Font.GothamBold
	scoreLbl.TextColor3 = C.muted
	scoreLbl.BackgroundTransparency = 1
	scoreLbl.BorderSizePixel = 0
	scoreLbl.TextXAlignment = Enum.TextXAlignment.Right
	scoreLbl.Parent = footer

	-- Overlay candado
	if not unlocked then
		local lockOverlay = Instance.new("TextLabel")
		lockOverlay.Size  = UDim2.new(1, 0, 1, 0)
		lockOverlay.Text  = "🔒"
		lockOverlay.TextSize = 28
		lockOverlay.Font  = Enum.Font.GothamBold
		lockOverlay.TextColor3 = C.white
		lockOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		lockOverlay.BackgroundTransparency = 0.55
		lockOverlay.BorderSizePixel = 0
		lockOverlay.ZIndex = 5
		lockOverlay.Parent = card
		local lc = Instance.new("UICorner")
		lc.CornerRadius = UDim.new(0, 12)
		lc.Parent = lockOverlay
	end

	-- Botón invisible para click
	local btn = Instance.new("TextButton")
	btn.Size  = UDim2.new(1, 0, 1, 0)
	btn.BackgroundTransparency = 1
	btn.Text  = ""
	btn.ZIndex = 6
	btn.Parent = card

	btn.MouseButton1Click:Connect(function()
		resaltarCard(levelID)
		actualizarPanelInfo(levelID)
	end)

	cardRefs[levelID] = { card = card, stroke = uiStroke }
end

-- =====================================================
-- CARGAR NIVELES (desde LevelsConfig)
-- =====================================================

local function cargarNiveles()
	if Cargando then return end
	Cargando = true

	DatosJugador = GetProgressFunc:InvokeServer()
	if not DatosJugador or not DatosJugador.Levels then
		warn("❌ LevelSelectorClient: Sin datos de progreso")
		Cargando = false
		return
	end

	-- Eliminar tarjetas anteriores (las que haya, sean estáticas o dinámicas)
	limpiarCards()

	-- Obtener lista de IDs desde LevelsConfig
	local ids = {}
	for id, _ in pairs(LevelsConfig) do
		table.insert(ids, id)
	end
	table.sort(ids)  -- Orden ascendente (0,1,2,3...)

	-- Crear una tarjeta por cada nivel
	for _, id in ipairs(ids) do
		local config = LevelsConfig[id]
		if config then
			crearCard(id, config, DatosJugador.Levels[tostring(id)])
		end
	end

	Cargando = false
	print("✅ LevelSelectorClient: Niveles cargados")
end

-- =====================================================
-- BOTÓN JUGAR
-- =====================================================

BtnJugar.MouseButton1Click:Connect(function()
	if not NivelSeleccionado or BotonesBloqueados then return end
	local data = DatosJugador and DatosJugador.Levels[tostring(NivelSeleccionado)]
	if not data or not data.Unlocked then return end

	BotonesBloqueados = true
	BtnJugar.Text             = "⏳  CARGANDO..."
	BtnJugar.BackgroundColor3 = C.muted

	RequestPlayEvent:FireServer(NivelSeleccionado)
	task.wait(0.4)

	if _G.StartGame then
		_G.StartGame()
	else
		warn("❌ _G.StartGame no encontrado")
	end

	BotonesBloqueados = false
end)

-- =====================================================
-- EVENTO: OpenMenu (volver del gameplay)
-- =====================================================

task.spawn(function()
	local Bindables   = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Bindables")
	local OpenMenuEvt = Bindables:WaitForChild("OpenMenu", 10)
	if OpenMenuEvt then
		OpenMenuEvt.Event:Connect(function()
			task.wait(0.5)
			mostrarPlaceholder()
			cargarNiveles()
			if ResultsLastRun then
				task.wait(0.1)
				actualizarPanelInfo(ResultsLastRun.LevelID)
			end
		end)
		print("✅ LevelSelectorClient: Escuchando OpenMenu")
	end
end)

-- =====================================================
-- EVENTO: Nivel completado
-- =====================================================

local LevelCompletedEvent = Remotes:FindFirstChild("LevelCompleted")
if LevelCompletedEvent then
	LevelCompletedEvent.OnClientEvent:Connect(function(stats)
		if type(stats) == "table" then
			ResultsLastRun = {
				LevelID = stats.nivelID,
				Stars   = stats.estrellas,
				Score   = stats.puntos,
			}
		end
	end)
end

-- =====================================================
-- INIT
-- =====================================================

mostrarPlaceholder()
cargarNiveles()

print("✅ LevelSelectorClient: Inicializado (con imágenes dinámicas)")