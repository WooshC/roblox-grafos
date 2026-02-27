-- MenuController.client.lua
-- Ubicación: StarterPlayer > StarterPlayerScripts > MenuController
-- Tipo: LocalScript
--
-- ⚠️ IMPORTANTE: Si existe un MenuController en StarterGui, ELIMINARLO.
--    Solo debe existir este en StarterPlayerScripts.
--
-- BUGS CORREGIDOS:
--
-- [BUG 1 - InfoContent no actualiza] sv() buscaba "Valor" pero el TextLabel
--   dentro de cada stat en StatsGrid se llama "Val".
--   FIX: Buscar "Val" primero, fallback a "Valor".
--
-- [BUG 2 - Aciertos muestra "—"] sv() tenía condición (lv.aciertos or 0)>0
--   que hacía mostrar "—" incluso cuando aciertos = 3.
--   FIX: Usar tostring(lv.aciertos or 0) sin condición.
--
-- [BUG 3 - InfoContent no se refresca al volver] loadProgress() no llamaba
--   updateSidebar() después de reconstruir el grid.
--   FIX: loadProgress() llama reapplySelection() + updateSidebar() al final.

local Players      = game:GetService("Players")
local RS           = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")

local player = Players.LocalPlayer
local root   = player.PlayerGui:WaitForChild("EDAQuestMenu", 20)
if not root then warn("[MenuController] EDAQuestMenu no encontrada"); return end

-- ── Eventos ────────────────────────────────────────────────────────────────
local eventsFolder    = RS:WaitForChild("Events", 10)
local remotesFolder   = eventsFolder and eventsFolder:WaitForChild("Remotes", 5)

local serverReadyEv   = remotesFolder and remotesFolder:FindFirstChild("ServerReady")
local requestPlayLEv  = remotesFolder and remotesFolder:FindFirstChild("RequestPlayLevel")
local levelReadyEv    = remotesFolder and remotesFolder:FindFirstChild("LevelReady")
local levelUnloadedEv = remotesFolder and remotesFolder:FindFirstChild("LevelUnloaded")
local getProgressFn   = remotesFolder and remotesFolder:FindFirstChild("GetPlayerProgress")

-- ── Frames ─────────────────────────────────────────────────────────────────
local S1 = root:WaitForChild("FrameMenu")
local S2 = root:WaitForChild("FrameLevels")
local S3 = root:FindFirstChild("FrameSettings")
local S4 = root:FindFirstChild("FrameCredits")
local S5 = root:FindFirstChild("FrameExit")

-- ── Paleta ─────────────────────────────────────────────────────────────────
local C = {
	accent  = Color3.fromRGB(0,   212, 255),
	accent3 = Color3.fromRGB(16,  185, 129),
	panel   = Color3.fromRGB(17,  25,  39),
	bg      = Color3.fromRGB(4,   7,   14),
	border  = Color3.fromRGB(30,  45,  66),
	muted   = Color3.fromRGB(100, 116, 139),
	dim     = Color3.fromRGB(55,  65,  81),
	gold    = Color3.fromRGB(245, 158, 11),
	text    = Color3.fromRGB(226, 232, 240),
	danger  = Color3.fromRGB(239, 68,  68),
}
local F = {
	mono  = Enum.Font.RobotoMono,
	bold  = Enum.Font.GothamBold,
	body  = Enum.Font.Gotham,
	title = Enum.Font.GothamBlack,
}
local STATUS_COLORS = { completado=C.gold, disponible=C.accent3, bloqueado=C.muted }
local STATUS_TEXTS  = { completado="◆ COMPLETADO", disponible="◆ DISPONIBLE", bloqueado="🔒 BLOQUEADO" }

-- ── Helpers ────────────────────────────────────────────────────────────────
local function n(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do inst[k] = v end
	if parent then inst.Parent = parent end
	return inst
end
local function corner(r, p)   n("UICorner", {CornerRadius=UDim.new(0,r)}, p) end
local function stroke(c, t, p) n("UIStroke", {Color=c, Thickness=t}, p) end
local function pad(t, b, l, r, p)
	local pd = Instance.new("UIPadding")
	pd.PaddingTop=UDim.new(0,t); pd.PaddingBottom=UDim.new(0,b)
	pd.PaddingLeft=UDim.new(0,l); pd.PaddingRight=UDim.new(0,r)
	pd.Parent = p
end
local function tween(obj, props, t)
	TweenService:Create(obj, TweenInfo.new(t or 0.3), props):Play()
end
local function formatTime(s)
	if not s or s <= 0 then return "0:00" end
	return string.format("%d:%02d", math.floor(s/60), math.floor(s%60))
end

-- ── Estado ─────────────────────────────────────────────────────────────────
local LEVELS          = {}
local selectedLevelID = nil
local isLoading       = false
local loadStartTime   = 0
local progressLoaded  = false

local updateSidebar      -- forward declaration
local connectLevelCards  -- forward declaration

-- ── Cámara (solo para el menú — ClientBoot gestiona gameplay) ───────────────
local function setupMenuCamera()
	local cam    = workspace.CurrentCamera
	local camObj = workspace:FindFirstChild("CamaraMenu", true)
	local part   = camObj and (
		(camObj:IsA("BasePart") and camObj) or
			(camObj:IsA("Model")    and camObj.PrimaryPart)
	)
	if part then
		cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame     = part.CFrame
	end
end

-- ── Fade de carga ───────────────────────────────────────────────────────────
local loadingScreen = S2:FindFirstChild("LoadingFrame", true)
local loadingLbl    = loadingScreen and loadingScreen:FindFirstChild("LoadingText")

local function fadeIn(t, cb)
	if loadingScreen then
		loadingScreen.Visible = true
		loadingScreen.BackgroundTransparency = 1
		tween(loadingScreen, {BackgroundTransparency=0}, t)
	end
	task.delay(t, function() if cb then cb() end end)
end
local function fadeOut(t, cb)
	if loadingScreen then
		tween(loadingScreen, {BackgroundTransparency=1}, t)
		task.delay(t, function()
			loadingScreen.Visible = false
			if cb then cb() end
		end)
	else
		if cb then cb() end
	end
end

-- ── Configuración de tarjetas ─────────────────────────────────────────────
local CARD_H = 140  -- Aumentado de 110 a 140
local CARD_W = 0.5  -- Ancho relativo (50% del contenedor menos gap)

-- ── Tarjetas de nivel ─────────────────────────────────────────────────────
local function buildLevelCard(lv, col, row, parent)
	local sc   = STATUS_COLORS[lv.status] or C.muted
	local xOff = col == 1 and 8 or 0  -- Aumentado gap entre columnas
	local card = n("TextButton", {
		Name             = "Card"..lv.nivelID,
		Size             = UDim2.new(CARD_W, -8, 0, CARD_H),  -- Más ancho y alto
		Position         = UDim2.new(col==1 and 0.5 or 0, xOff, 0, row*(CARD_H+16)),  -- Más espaciado
		BackgroundColor3 = C.panel, Text="", BorderSizePixel=0, ZIndex=5,
	}, parent)
	corner(10, card); stroke(C.border, 1, card)  -- Esquinas más redondeadas

	-- Área de imagen más grande
	if lv.imageId and lv.imageId ~= "" then
		local img = n("ImageLabel", {
			Size=UDim2.new(1,0,0,70),  -- Aumentado de 54 a 70
			BackgroundTransparency=1,
			Image=lv.imageId, 
			ScaleType=Enum.ScaleType.Crop, 
			ZIndex=6,
		}, card)
		corner(10, img)
	end

	-- Badge de estado reposicionado
	local badge = n("Frame", {
		Size=UDim2.new(0,90,0,18),  -- Más grande
		Position=UDim2.new(0,8,0,74),  -- Ajustado por imagen más grande
		BackgroundColor3=C.bg, 
		BorderSizePixel=0, 
		ZIndex=7,
	}, card)
	corner(6, badge); 
	n("UIStroke", {Color=sc, Thickness=1}, badge)
	n("TextLabel", {
		Size=UDim2.new(1,0,1,0), 
		BackgroundTransparency=1,
		Text=STATUS_TEXTS[lv.status] or "—",
		TextColor3=sc, 
		Font=F.mono, 
		TextSize=9,  -- Ligeramente más grande
		ZIndex=8,
	}, badge)

	-- Título del nivel
	n("TextLabel", {
		Size=UDim2.new(1,-16,0,26),  -- Más espacio
		Position=UDim2.new(0,8,0,96),  -- Ajustado
		BackgroundTransparency=1, 
		Text=lv.nombre or "Nivel "..lv.nivelID,
		TextColor3=C.text, 
		Font=F.bold, 
		TextSize=12,  -- Ligeramente más grande
		TextXAlignment=Enum.TextXAlignment.Left,
		TextTruncate=Enum.TextTruncate.AtEnd, 
		ZIndex=6,
	}, card)

	-- Footer con estrellas y score
	local footer = n("Frame", {
		Size=UDim2.new(1,0,0,22),  -- Más alto
		Position=UDim2.new(0,0,1,-22),
		BackgroundColor3=Color3.fromRGB(10,10,18), 
		BorderSizePixel=0, 
		ZIndex=6,
	}, card)
	corner(10, footer)

	local st = lv.estrellas or 0
	n("TextLabel", {
		Size=UDim2.new(0,60,1,0), 
		Position=UDim2.new(0,6,0,0),
		BackgroundTransparency=1,
		Text=(st>=1 and "⭐" or "☆")..(st>=2 and "⭐" or "☆")..(st>=3 and "⭐" or "☆"),
		TextColor3=C.gold, 
		Font=F.body, 
		TextSize=12,  -- Ligeramente más grande
		ZIndex=7,
	}, footer)

	n("TextLabel", {
		Size=UDim2.new(0,60,1,0), 
		Position=UDim2.new(1,-66,0,0),
		BackgroundTransparency=1,
		Text=(lv.highScore or 0)>0 and (lv.highScore.." pts") or "—",
		TextColor3=C.dim, 
		Font=F.mono, 
		TextSize=10,  -- Ligeramente más grande
		ZIndex=7,
		TextXAlignment=Enum.TextXAlignment.Right,
	}, footer)

	return card
end

-- ── Loading overlay dentro de tarjeta ─────────────────────────────────────
local function showCardLoading(card)
	-- Remover loading previo si existe
	local old = card:FindFirstChild("CardLoading")
	if old then old:Destroy() end

	local loading = n("Frame", {
		Name = "CardLoading",
		Size = UDim2.new(1,0,1,0),
		BackgroundColor3 = Color3.fromRGB(0,0,0),
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		ZIndex = 20,  -- Por encima de todo en la tarjeta
	}, card)
	corner(10, loading)

	-- Spinner animado
	local spinner = n("ImageLabel", {
		Name = "Spinner",
		Size = UDim2.new(0,32,0,32),
		Position = UDim2.new(0.5,-16,0.5,-16),
		BackgroundTransparency = 1,
		Image = "rbxassetid://6031094670",  -- Icono de carga de Roblox (o tu propio asset)
		ZIndex = 21,
	}, loading)

	-- Animación de rotación
	task.spawn(function()
		while spinner and spinner.Parent do
			spinner.Rotation = (spinner.Rotation + 12) % 360
			task.wait(0.03)
		end
	end)

	n("TextLabel", {
		Size = UDim2.new(1,0,0,20),
		Position = UDim2.new(0,0,0.5,20),
		BackgroundTransparency = 1,
		Text = "Cargando...",
		TextColor3 = C.text,
		Font = F.mono,
		TextSize = 10,
		ZIndex = 21,
	}, loading)

	return loading
end

local function hideCardLoading(card)
	local loading = card:FindFirstChild("CardLoading")
	if loading then
		loading:Destroy()
	end
end

-- ── Header de sección ─────────────────────────────────────────────────────
local function buildSectionHeader(title, count, lo, parent)
	local sh = n("Frame", {
		Name="SecH_"..lo, 
		Size=UDim2.new(1,0,0,32),  -- Ligeramente más alto
		BackgroundTransparency=1, 
		ZIndex=4, 
		LayoutOrder=lo,
	}, parent)

	n("TextLabel", {
		Size=UDim2.new(0,220,1,0), 
		BackgroundTransparency=1,
		Text=title:upper(), 
		TextColor3=C.accent, 
		Font=F.mono, 
		TextSize=10,  -- Ligeramente más grande
		TextXAlignment=Enum.TextXAlignment.Left, 
		ZIndex=5,
	}, sh)

	n("Frame", {
		Size=UDim2.new(1,-230,0,1), 
		Position=UDim2.new(0,220,0.5,0),
		BackgroundColor3=C.border, 
		BorderSizePixel=0, 
		ZIndex=5,
	}, sh)

	n("TextLabel", {
		Size=UDim2.new(0,70,1,0), 
		Position=UDim2.new(1,-70,0,0),
		BackgroundTransparency=1,
		Text=count..(count==1 and " nivel" or " niveles"),
		TextColor3=C.dim, 
		Font=F.mono, 
		TextSize=10,  -- Ligeramente más grande
		TextXAlignment=Enum.TextXAlignment.Right, 
		ZIndex=5,
	}, sh)
end

-- ── buildGrid ─────────────────────────────────────────────────────────────
local function buildGrid(progressData)
	local gridScroll = S2:FindFirstChild("GridArea", true)
	if not gridScroll then 
		warn("[MenuController] GridArea no encontrado"); 
		return 
	end

	-- Limpiar contenido anterior (manteniendo layout y padding)
	local KEEP = {ProgressBar=true, LoadingFrame=true}
	for _, child in ipairs(gridScroll:GetChildren()) do
		if not KEEP[child.Name] and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end

	-- Ocultar loading global si existe
	local lf = gridScroll:FindFirstChild("LoadingFrame")
	if lf then 
		lf.Visible = false 
	end

	-- Procesar datos de niveles
	LEVELS = {}
	for k, datos in pairs(progressData) do
		local id = tonumber(k)
		if id ~= nil and datos then 
			datos.nivelID = id
			LEVELS[id] = datos 
		end
	end

	-- Agrupar por secciones
	local secciones, ordenSec = {}, {}
	for i = 0, 4 do
		local d = LEVELS[i]
		if not d then continue end
		local sec = d.seccion or "NIVELES"
		if not secciones[sec] then 
			secciones[sec] = {}
			table.insert(ordenSec, sec) 
		end
		table.insert(secciones[sec], d)
	end

	-- Ordenar secciones por ID de primer nivel
	table.sort(ordenSec, function(a, b)
		return (secciones[a][1] and secciones[a][1].nivelID or 999) <
			(secciones[b][1] and secciones[b][1].nivelID or 999)
	end)

	-- Construir grid
	local lo, cols = 3, 2
	for secIdx, secNombre in ipairs(ordenSec) do
		local niveles = secciones[secNombre]

		-- Header de sección
		buildSectionHeader(secNombre, #niveles, lo, gridScroll)
		lo = lo + 1

		-- Contenedor de tarjetas
		local contH = math.ceil(#niveles / cols) * (CARD_H + 16)
		local cont = n("Frame", {
			Name="Sec_"..secIdx, 
			Size=UDim2.new(1,0,0,contH),
			BackgroundTransparency=1, 
			ZIndex=4, 
			LayoutOrder=lo,
		}, gridScroll)
		lo = lo + 1

		-- Crear tarjetas
		for i, lv in ipairs(niveles) do
			local card = buildLevelCard(lv, (i-1) % cols, math.floor((i-1) / cols), cont)

			-- Guardar referencia al nivel en la tarjeta para el loading
			card:SetAttribute("NivelID", lv.nivelID)
		end

		-- Gap entre secciones
		n("Frame", {
			Name="Gap_"..secIdx, 
			Size=UDim2.new(1,0,0,20),  -- Más espacio entre secciones
			BackgroundTransparency=1, 
			LayoutOrder=lo,
		}, gridScroll)
		lo = lo + 1
	end

	-- Ajustar canvas size
	local layout = gridScroll:FindFirstChildOfClass("UIListLayout")
	if layout then
		task.defer(function()
			gridScroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 80)
		end)
	end

	connectLevelCards()
	print("[MenuController] Grid listo —", #ordenSec, "secciones,", #LEVELS, "niveles cargados")
end

-- ── Funciones exportadas para loading por tarjeta ─────────────────────────
local function showLevelLoading(nivelID)
	local gridScroll = S2:FindFirstChild("GridArea", true)
	if not gridScroll then return end

	local card = gridScroll:FindFirstChild("Card"..nivelID, true)
	if card then
		return showCardLoading(card)
	end
end

local function hideLevelLoading(nivelID)
	local gridScroll = S2:FindFirstChild("GridArea", true)
	if not gridScroll then return end

	local card = gridScroll:FindFirstChild("Card"..nivelID, true)
	if card then
		hideCardLoading(card)
	end
end

-- ── updateProgressBar ──────────────────────────────────────────────────────
local function updateProgressBar()
	local total, completados = 0, 0
	for i = 0, 4 do
		if LEVELS[i] then total = total + 1
			if LEVELS[i].status == "completado" then completados = completados + 1 end
		end
	end
	local gs = S2:FindFirstChild("GridArea", true); if not gs then return end
	local pb = gs:FindFirstChild("ProgressBar");    if not pb then return end
	local pct = total > 0 and (completados / total) or 0
	local pt = pb:FindFirstChild("ProgText"); if pt then pt.Text = completados.." / "..total end
	local pp = pb:FindFirstChild("ProgPct");  if pp then pp.Text = math.floor(pct*100).."%" end
	local pf = pb:FindFirstChild("ProgFill", true)
	if pf then tween(pf, {Size=UDim2.new(pct, 0, 1, 0)}, 0.4) end
end

-- ── resetSidebar ───────────────────────────────────────────────────────────
local function resetSidebar()
	local ph = S2:FindFirstChild("Placeholder", true)
	local ic = S2:FindFirstChild("InfoContent",  true)
	if ph then ph.Visible = true  end
	if ic then ic.Visible = false end
end

-- ── updateSidebar ──────────────────────────────────────────────────────────
updateSidebar = function(lv)
	local ph = S2:FindFirstChild("Placeholder", true)
	local ic = S2:FindFirstChild("InfoContent",  true)
	if not ic then return end
	if ph then ph.Visible = false end
	ic.Visible = true

	local sc = STATUS_COLORS[lv.status] or C.muted

	local hero = ic:FindFirstChild("Hero")
	if hero then
		local bgColor = lv.status=="completado" and Color3.fromRGB(26,18,4)
			or lv.status=="disponible"           and Color3.fromRGB(4,26,18)
			or Color3.fromRGB(14, 14, 20)
		hero.BackgroundColor3 = bgColor
		local heroGlow = hero:FindFirstChild("HeroGlow")
		if heroGlow then tween(heroGlow, {BackgroundColor3=sc}, 0.2) end

		local heroEmoji = hero:FindFirstChild("HeroEmoji")
		local heroImage = hero:FindFirstChild("HeroImage")
		if lv.imageId and lv.imageId ~= "" then
			if heroEmoji then heroEmoji.Visible = false end
			if not heroImage then
				heroImage = n("ImageLabel", {
					Name="HeroImage", Size=UDim2.new(1,0,1,0),
					BackgroundTransparency=1, Image=lv.imageId,
					ScaleType=Enum.ScaleType.Crop, ZIndex=6,
				}, hero)
			else
				heroImage.Image   = lv.imageId
				heroImage.Visible = true
			end
		else
			if heroImage then heroImage.Visible = false end
			if heroEmoji then heroEmoji.Visible = true  end
		end

		local heroBadge    = hero:FindFirstChild("HeroBadge")
		local heroBadgeTxt = heroBadge and heroBadge:FindFirstChild("HeroBadgeText")
		if heroBadge then
			heroBadge.BackgroundColor3 = bgColor
			local stk = heroBadge:FindFirstChildOfClass("UIStroke"); if stk then stk.Color = sc end
		end
		if heroBadgeTxt then
			heroBadgeTxt.Text       = STATUS_TEXTS[lv.status] or "—"
			heroBadgeTxt.TextColor3 = sc
		end
	end

	local infoBody = ic:FindFirstChild("InfoBody")
	if not infoBody then return end

	local infoTag  = infoBody:FindFirstChild("InfoTag")
	local infoName = infoBody:FindFirstChild("InfoName")
	local infoDesc = infoBody:FindFirstChild("InfoDesc")
	if infoTag  then infoTag.Text  = lv.tag        or "" end
	if infoName then infoName.Text = lv.nombre      or "" end
	if infoDesc then infoDesc.Text = lv.descripcion or "" end

	local starsFrame = infoBody:FindFirstChild("Stars")
	if starsFrame then
		for i = 1, 3 do
			local s = starsFrame:FindFirstChild("Star"..i)
			if s then s.TextTransparency = i <= (lv.estrellas or 0) and 0 or 0.7 end
		end
	end

	-- ── StatsGrid ─────────────────────────────────────────────────────────
	local statsGrid = infoBody:FindFirstChild("StatsGrid")
	if statsGrid then
		-- BUG 1+2 FIX: buscar "Val" (nombre confirmado), con fallback a "Valor".
		-- Mostrar el valor SIEMPRE sin condición (>0) — así aciertos=0 muestra "0".
		local function sv(nm, val)
			local box = statsGrid:FindFirstChild(nm)
			if not box then return end
			-- Buscar "Val" primero, luego "Valor" por compatibilidad
			local lbl = box:FindFirstChild("Val") or box:FindFirstChild("Valor")
			if lbl then
				lbl.Text = tostring(val)
			else
				warn("[MenuController] No se encontró 'Val' ni 'Valor' en:", nm)
				-- Debug: listar hijos para identificar el nombre real
				for _, hijo in ipairs(box:GetChildren()) do
					print("  Hijo en "..nm..": "..hijo.Name.." / "..hijo.ClassName)
				end
			end
		end

		sv("StatScore",  lv.status=="completado" and ((lv.highScore or 0).." pts") or "—")
		sv("StatStatus", lv.status=="completado" and "✓ Completado"
			or lv.status=="disponible"            and "Disponible"
			or                                        "🔒 Bloqueado")
		-- Sin condición >0: si aciertos=3, muestra "3"; si es 0, muestra "0"
		sv("StatAciert", tostring(lv.aciertos    or 0))
		sv("StatFallos", tostring(lv.fallos      or 0))
		sv("StatTiempo", formatTime(lv.tiempoMejor or 0))
		sv("StatInten",  tostring(lv.intentos    or 0))
	end

	local tagsFrame = infoBody:FindFirstChild("Tags")
	if tagsFrame then
		for _, c in ipairs(tagsFrame:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		for _, concept in ipairs(lv.conceptos or {}) do
			local tb = n("TextButton", {
				Size=UDim2.new(0,0,0,22), AutomaticSize=Enum.AutomaticSize.X,
				BackgroundColor3=Color3.fromRGB(0,20,30), Text=concept,
				TextColor3=Color3.fromRGB(0,138,170), Font=F.mono,
				TextSize=9, BorderSizePixel=0, ZIndex=5,
			}, tagsFrame)
			corner(4, tb); stroke(Color3.fromRGB(0,62,90), 1, tb); pad(3,3,8,8, tb)
		end
	end

	local pb = S2:FindFirstChild("PlayButton", true)
	if pb then
		if lv.status == "bloqueado" then
			pb.Text = "🔒  NIVEL BLOQUEADO"
			pb.TextColor3 = C.muted; pb.BackgroundColor3 = C.panel
			local stk = pb:FindFirstChildOfClass("UIStroke"); if stk then stk.Color = C.border end
		else
			local icon = lv.status == "completado" and "↺  REINTENTAR: " or "▶  JUGAR: "
			pb.Text = icon .. (lv.nombre or ""):upper()
			pb.TextColor3 = Color3.new(0,0,0); pb.BackgroundColor3 = C.accent3
			local stk = pb:FindFirstChildOfClass("UIStroke"); if stk then stk.Color = C.accent3 end
		end
	end
end

-- ── reapplySelection ───────────────────────────────────────────────────────
local function reapplySelection()
	if selectedLevelID == nil then return end
	local gridScroll = S2:FindFirstChild("GridArea", true); if not gridScroll then return end
	for i = 0, 4 do
		local c  = gridScroll:FindFirstChild("Card"..i, true); if not c  then continue end
		local st = c:FindFirstChildOfClass("UIStroke");        if not st then continue end
		st.Color     = i == selectedLevelID and C.accent
			or (LEVELS[i] and LEVELS[i].status == "completado" and C.gold or C.border)
		st.Thickness = i == selectedLevelID and 2 or 1
	end
end

-- ── connectLevelCards ──────────────────────────────────────────────────────
connectLevelCards = function()
	local gridScroll = S2:FindFirstChild("GridArea", true); if not gridScroll then return end
	local count = 0
	for id = 0, 4 do
		local card = gridScroll:FindFirstChild("Card"..id, true)
		if card and card:IsA("TextButton") and LEVELS[id] then
			count = count + 1
			card.MouseButton1Click:Connect(function()
				if isLoading then return end
				selectedLevelID = id
				updateSidebar(LEVELS[id])
				for i = 0, 4 do
					local c  = gridScroll:FindFirstChild("Card"..i, true); if not c  then continue end
					local st = c:FindFirstChildOfClass("UIStroke");        if not st then continue end
					st.Color     = i == id and C.accent
						or (LEVELS[i] and LEVELS[i].status == "completado" and C.gold or C.border)
					st.Thickness = i == id and 2 or 1
				end
			end)
		end
	end
	print("[MenuController] Tarjetas conectadas:", count)
end

-- ── loadProgress ───────────────────────────────────────────────────────────
local function loadProgress()
	if progressLoaded then return end
	progressLoaded = true
	if not getProgressFn then
		warn("[MenuController] GetPlayerProgress no disponible"); return
	end

	local ok, data = pcall(function() return getProgressFn:InvokeServer() end)
	if not ok or not data then
		warn("[MenuController] Error al obtener progreso:", tostring(data))
		progressLoaded = false; return
	end

	buildGrid(data)
	updateProgressBar()

	-- BUG 3 FIX: re-aplicar selección y actualizar sidebar con datos frescos.
	-- Sin esto, InfoContent seguía mostrando los datos previos al volver del nivel.
	reapplySelection()
	if selectedLevelID ~= nil and LEVELS[selectedLevelID] then
		updateSidebar(LEVELS[selectedLevelID])
		print("[MenuController] Sidebar actualizado para nivel", selectedLevelID)
	end

	local playerTag = S2:FindFirstChild("PlayerTag", true)
	if playerTag then playerTag.Text = player.DisplayName or player.Name end

	print("[MenuController] ✅ Progreso cargado")
end

-- ── Navegación ─────────────────────────────────────────────────────────────
local function goToMenu()
	S1.Visible = true; S2.Visible = false
	selectedLevelID = nil
	setupMenuCamera()
end

local function goToLevels()
	S1.Visible = false; S2.Visible = true
	resetSidebar(); selectedLevelID = nil
	progressLoaded = false
	task.spawn(loadProgress)
end

local function openModal(f)  if f then f.Visible = true  end end
local function closeModal(f) if f then f.Visible = false end end

-- ── Botones menú principal ─────────────────────────────────────────────────
local mp = S1:FindFirstChild("MenuPanel")
local Bp = mp and mp:FindFirstChild("BtnPlay")
local Bs = mp and mp:FindFirstChild("BtnSettings")
local Bc = mp and mp:FindFirstChild("BtnCredits")
local Be = mp and mp:FindFirstChild("BtnExit")
-- ── BackBtn (Volver al menú principal) ─────────────────────────────────────
local backBtn = S2:FindFirstChild("BackBtn", true)

if Bp then Bp.MouseButton1Click:Connect(goToLevels) end
if Bs then Bs.MouseButton1Click:Connect(function() openModal(S3) end) end
if Bc then Bc.MouseButton1Click:Connect(function() openModal(S4) end) end
if Be then Be.MouseButton1Click:Connect(function() openModal(S5) end) end
for _, frame in ipairs({S3, S4, S5}) do
	if not frame then continue end
	for _, name in ipairs({"BtnClose","CloseBtn","OkBtn","SaveBtn","CancelBtn"}) do
		local b = frame:FindFirstChild(name, true)
		if b then b.MouseButton1Click:Connect(function() closeModal(frame) end) end
	end
end



if backBtn then
	backBtn.MouseButton1Click:Connect(function()
		if isLoading then return end  -- No permitir volver si está cargando un nivel
		goToMenu()
	end)
else
	warn("[MenuController] BackBtn no encontrado en FrameLevels")
end


-- ── PlayButton en sidebar ──────────────────────────────────────────────────
local playBtnSidebar = S2:FindFirstChild("PlayButton", true)
if playBtnSidebar then
	playBtnSidebar.MouseButton1Click:Connect(function()
		if isLoading or selectedLevelID == nil then return end
		local lv = LEVELS[selectedLevelID]
		if not lv or lv.status == "bloqueado" then return end

		isLoading = true
		local thisLoad = os.clock(); loadStartTime = thisLoad

		-- Mostrar loading DENTRO de la tarjeta seleccionada, no el LoadingFrame global
		local cardLoading = showLevelLoading(selectedLevelID)

		-- Opcional: pequeño delay visual para que el usuario vea el feedback
		task.delay(0.3, function()
			if not isLoading or loadStartTime ~= thisLoad then return end

			if requestPlayLEv then
				requestPlayLEv:FireServer(selectedLevelID)

				-- Timeout de 10s
				task.spawn(function()
					task.wait(10)
					if isLoading and loadStartTime == thisLoad then
						-- Remover loading de tarjeta y mostrar error
						hideLevelLoading(selectedLevelID)
						-- Opcional: mostrar notificación de error en la tarjeta
						local gridScroll = S2:FindFirstChild("GridArea", true)
						local card = gridScroll and gridScroll:FindFirstChild("Card"..selectedLevelID, true)
						if card then
							local errLbl = card:FindFirstChild("ErrorLabel") or n("TextLabel", {
								Name = "ErrorLabel",
								Size = UDim2.new(1, 0, 0, 20),
								Position = UDim2.new(0, 0, 1, -20),
								BackgroundColor3 = C.danger,
								BackgroundTransparency = 0.2,
								Text = "⏱ Timeout",
								TextColor3 = C.text,
								Font = F.mono,
								TextSize = 9,
								ZIndex = 25,
							}, card)
							corner(4, errLbl)
							task.delay(2, function() if errLbl then errLbl:Destroy() end end)
						end

						isLoading = false
					end
				end)
			end
		end)
	end)
end

-- ── LevelReady → ocultar loading de tarjeta ────────────────────────────────
if levelReadyEv then
	levelReadyEv.OnClientEvent:Connect(function(data)
		-- Siempre ocultar el loading de la tarjeta primero
		if selectedLevelID then
			hideLevelLoading(selectedLevelID)
		end

		if data and data.error then
			-- Mostrar error en la tarjeta o sidebar
			local gridScroll = S2:FindFirstChild("GridArea", true)
			local card = gridScroll and gridScroll:FindFirstChild("Card"..selectedLevelID, true)
			if card then
				local errOverlay = n("Frame", {
					Name = "ErrorOverlay",
					Size = UDim2.new(1, 0, 0, 30),
					Position = UDim2.new(0, 0, 0.5, -15),
					BackgroundColor3 = C.danger,
					BackgroundTransparency = 0.3,
					ZIndex = 25,
				}, card)
				corner(6, errOverlay)
				n("TextLabel", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Text = "❌ "..(data.error or "Error"),
					TextColor3 = C.text,
					Font = F.bold,
					TextSize = 10,
					ZIndex = 26,
				}, errOverlay)
				task.delay(2.5, function() if errOverlay then errOverlay:Destroy() end end)
			end

			isLoading = false
			return
		end

		-- Éxito: el ClientBoot manejará la transición de cámara y GUI
		isLoading = false
	end)
end

-- ── LevelUnloaded → refrescar datos y mostrar selector ─────────────────────
-- ClientBoot ya activó root.Enabled. Aquí recargamos el progreso para que
-- InfoContent muestre los valores actualizados del intento recién completado.
if levelUnloadedEv then
	levelUnloadedEv.OnClientEvent:Connect(function()
		task.delay(0.15, function()
			if isLoading then progressLoaded = false; return end
			S1.Visible = false
			S2.Visible = true
			UIS.MouseBehavior = Enum.MouseBehavior.Default
			progressLoaded = false
			task.spawn(loadProgress)
			print("[MenuController] LevelUnloaded → recargando progreso")
		end)
	end)
end

-- ── ServerReady ────────────────────────────────────────────────────────────
if serverReadyEv then
	serverReadyEv.OnClientEvent:Connect(function()
		task.spawn(loadProgress)
	end)
end

task.delay(5, function()
	if not progressLoaded then task.spawn(loadProgress) end
end)

local playerTag = S2:FindFirstChild("PlayerTag", true)
if playerTag then playerTag.Text = player.DisplayName or player.Name end

setupMenuCamera()
print("[EDA v2] ✅ MenuController activo")