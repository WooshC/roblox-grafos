-- MenuController.client.lua
-- Ubicación Roblox: StarterGui  (LocalScript)
--
-- Correcciones en esta versión:
-- 1. Hero muestra ImageLabel con lv.imageId (además del emoji se reemplaza por imagen)
-- 2. updateSidebar usa nombres correctos: highScore, estrellas, tiempoMejor, conceptos
-- 3. Tras ReturnToMenu: loadProgress recarga datos Y re-llama updateSidebar si hay
--    un nivel seleccionado, para que StatsGrid.Val se vea actualizado inmediatamente
-- 4. buildGrid/loadProgress siempre reconstruye LEVELS desde el servidor

local Players      = game:GetService("Players")
local RS           = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local root   = player.PlayerGui:WaitForChild("EDAQuestMenu", 15)
if not root then warn("[MenuController] EDAQuestMenu no encontrado"); return end

-- ── Eventos ────────────────────────────────────────────────────────────────
local eventsFolder  = RS:WaitForChild("Events", 10)
local remotesFolder = eventsFolder and eventsFolder:WaitForChild("Remotes", 5)

local serverReadyEv  = remotesFolder and remotesFolder:FindFirstChild("ServerReady")
local requestPlayLEv = remotesFolder and remotesFolder:FindFirstChild("RequestPlayLevel")
local levelReadyEv   = remotesFolder and remotesFolder:FindFirstChild("LevelReady")
local returnToMenuEv = remotesFolder and remotesFolder:FindFirstChild("ReturnToMenu")
local getProgressFn  = remotesFolder and remotesFolder:FindFirstChild("GetPlayerProgress")

-- ── Frames ─────────────────────────────────────────────────────────────────
local S1 = root:WaitForChild("FrameMenu")
local S2 = root:WaitForChild("FrameLevels")
local S3 = root:WaitForChild("FrameSettings")
local S4 = root:WaitForChild("FrameCredits")
local S5 = root:WaitForChild("FrameExit")

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
	black   = Color3.fromRGB(0,   0,   0),
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

-- ── Helpers UI ─────────────────────────────────────────────────────────────
local function n(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do inst[k] = v end
	if parent then inst.Parent = parent end
	return inst
end
local function corner(r, p) n("UICorner", {CornerRadius=UDim.new(0,r)}, p) end
local function stroke(c, t, p) return n("UIStroke", {Color=c, Thickness=t}, p) end
local function pad(t, b, l, r, p)
	local pd = Instance.new("UIPadding")
	pd.PaddingTop=UDim.new(0,t); pd.PaddingBottom=UDim.new(0,b)
	pd.PaddingLeft=UDim.new(0,l); pd.PaddingRight=UDim.new(0,r)
	pd.Parent=p
end
local function tween(obj, props, t)
	TweenService:Create(obj, TweenInfo.new(t or 0.3), props):Play()
end

-- ── Estado global ──────────────────────────────────────────────────────────
local LEVELS          = {}
local selectedLevelID = nil
local isLoading       = false
local loadStartTime   = 0
local progressLoaded  = false
local menuCameraActive = false

-- forward declarations
local updateSidebar
local connectLevelCards

-- ── Cámara ─────────────────────────────────────────────────────────────────
local camera = workspace.CurrentCamera
local function setupMenuCamera()
	local camObj = workspace:FindFirstChild("CamaraMenu", true)
	if not camObj then menuCameraActive=false; return end
	local part = (camObj:IsA("BasePart") and camObj)
		or (camObj:IsA("Model") and camObj.PrimaryPart)
	if not part then menuCameraActive=false; return end
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame     = part.CFrame
	menuCameraActive  = true
end
local function restoreGameCamera()
	camera.CameraType = Enum.CameraType.Custom
	menuCameraActive  = false
end

-- ── Fade ───────────────────────────────────────────────────────────────────
local loadingScreen = S2:FindFirstChild("LoadingFrame", true)
local loadingLbl    = loadingScreen and loadingScreen:FindFirstChild("LoadingText")
local function fadeIn(t, cb)
	if loadingScreen then
		loadingScreen.Visible=true; loadingScreen.BackgroundTransparency=1
		tween(loadingScreen, {BackgroundTransparency=0}, t)
	end
	task.delay(t, function() if cb then cb() end end)
end
local function fadeOut(t, cb)
	if loadingScreen then
		tween(loadingScreen, {BackgroundTransparency=1}, t)
		task.delay(t, function() loadingScreen.Visible=false; if cb then cb() end end)
	else
		if cb then cb() end
	end
end

-- ── Formato tiempo ─────────────────────────────────────────────────────────
local function formatTime(s)
	if not s or s <= 0 then return "—" end
	return string.format("%d:%02d", math.floor(s/60), math.floor(s%60))
end

-- ════════════════════════════════════════════════════════════════════════════
-- TARJETA DE NIVEL
-- Mitad superior: ImageZone (imagen del nivel)
-- Mitad inferior: badge estado, nombre, algoritmo, footer estrellas/score
-- ════════════════════════════════════════════════════════════════════════════
local CARD_W = 200
local CARD_H = 200
local IMG_H  = 90

local function buildLevelCard(lv, col, row, cont)
	local sc   = STATUS_COLORS[lv.status] or C.muted
	local card = n("TextButton", {
		Name="Card"..lv.nivelID,
		Size=UDim2.new(0,CARD_W,0,CARD_H),
		Position=UDim2.new(0, col*(CARD_W+14), 0, row*(CARD_H+14)),
		BackgroundColor3=C.panel, Text="", AutoButtonColor=false,
		BorderSizePixel=0, ZIndex=4,
	}, cont)
	corner(10, card)
	stroke(lv.status=="completado" and C.gold or C.border, 1, card)

	-- Zona imagen
	local imgZone = n("Frame", {
		Name="ImageZone",
		Size=UDim2.new(1,0,0,IMG_H),
		BackgroundColor3=Color3.fromRGB(8,14,26),
		BorderSizePixel=0, ZIndex=5, ClipsDescendants=true,
	}, card)
	corner(10, imgZone)
	-- Cuadrar esquinas inferiores del frame de imagen
	n("Frame",{Size=UDim2.new(1,0,0,10),Position=UDim2.new(0,0,1,-10),
		BackgroundColor3=Color3.fromRGB(8,14,26),BorderSizePixel=0,ZIndex=6},imgZone)

	if lv.imageId and lv.imageId ~= "" then
		n("ImageLabel",{
			Name="LevelImage", Size=UDim2.new(1,0,1,0),
			BackgroundTransparency=1, Image=lv.imageId,
			ScaleType=Enum.ScaleType.Crop, ZIndex=7,
		}, imgZone)
	else
		local fb=n("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=C.accent,
			BackgroundTransparency=0.82,BorderSizePixel=0,ZIndex=7},imgZone)
		n("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
			Text=tostring(lv.nivelID),TextColor3=C.accent,Font=F.title,TextSize=36,ZIndex=8},fb)
	end

	-- Divisor
	n("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,0,IMG_H),
		BackgroundColor3=C.border,BorderSizePixel=0,ZIndex=5},card)

	local cY = IMG_H+1

	-- Badge estado
	local sbg=n("Frame",{Name="StatusBadge",Size=UDim2.new(1,-24,0,16),
		Position=UDim2.new(0,12,0,cY+8),BackgroundColor3=sc,
		BackgroundTransparency=0.85,BorderSizePixel=0,ZIndex=5},card)
	corner(3,sbg); stroke(sc,1,sbg)
	n("TextLabel",{Name="StatusText",Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
		Text=STATUS_TEXTS[lv.status] or "—",TextColor3=sc,Font=F.mono,TextSize=8,ZIndex=6},sbg)

	-- Nombre
	n("TextLabel",{Name="CardName",Size=UDim2.new(1,-24,0,30),
		Position=UDim2.new(0,12,0,cY+28),BackgroundTransparency=1,
		Text=lv.nombre or "",TextColor3=lv.status=="bloqueado" and C.muted or C.text,
		Font=F.bold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,
		TextWrapped=true,ZIndex=5},card)

	-- Algoritmo
	n("TextLabel",{Size=UDim2.new(1,-24,0,14),Position=UDim2.new(0,12,0,cY+60),
		BackgroundTransparency=1,Text="· "..(lv.algoritmo or "—"),
		TextColor3=C.muted,Font=F.mono,TextSize=9,
		TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5},card)

	-- Footer
	local ft=n("Frame",{Name="CardFooter",Size=UDim2.new(1,0,0,26),
		Position=UDim2.new(0,0,1,-26),BackgroundTransparency=1,ZIndex=5},card)
	stroke(C.border,1,ft)
	local ss="" for i=1,3 do ss=ss..(i<=(lv.estrellas or 0) and "★" or "☆") end
	n("TextLabel",{Name="CardStars",Size=UDim2.new(0,52,1,0),Position=UDim2.new(0,10,0,0),
		BackgroundTransparency=1,Text=ss,TextColor3=C.gold,Font=F.body,TextSize=12,
		TextXAlignment=Enum.TextXAlignment.Left,ZIndex=6},ft)
	n("TextLabel",{Name="CardScore",Size=UDim2.new(0,72,1,0),Position=UDim2.new(1,-80,0,0),
		BackgroundTransparency=1,
		Text=(lv.highScore or 0)>0 and (lv.highScore.." pts") or "—",
		TextColor3=C.gold,Font=F.mono,TextSize=9,
		TextXAlignment=Enum.TextXAlignment.Right,ZIndex=6},ft)

	-- Overlay candado
	if lv.status=="bloqueado" then
		local ov=n("Frame",{Name="LockOverlay",Size=UDim2.new(1,0,1,0),
			BackgroundColor3=Color3.fromRGB(4,6,12),BackgroundTransparency=0.45,
			BorderSizePixel=0,ZIndex=9},card)
		corner(10,ov)
		n("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
			Text="🔒",Font=F.body,TextSize=28,ZIndex=10},ov)
	end
	return card
end

-- ── updateCardVisuals ──────────────────────────────────────────────────────
local function updateCardVisuals(card, lv)
	local sc = STATUS_COLORS[lv.status] or C.muted
	local st = card:FindFirstChildOfClass("UIStroke")
	if st then st.Color = lv.status=="completado" and C.gold or C.border end

	local imgZone = card:FindFirstChild("ImageZone")
	if imgZone then
		local imgLbl = imgZone:FindFirstChild("LevelImage")
		if imgLbl and lv.imageId and lv.imageId~="" then imgLbl.Image=lv.imageId end
	end

	local sbg = card:FindFirstChild("StatusBadge",true)
	if sbg then
		sbg.BackgroundColor3=sc
		local stk=sbg:FindFirstChildOfClass("UIStroke"); if stk then stk.Color=sc end
		local stxt=sbg:FindFirstChild("StatusText"); if stxt then stxt.Text=STATUS_TEXTS[lv.status] or "—"; stxt.TextColor3=sc end
	end
	local nm=card:FindFirstChild("CardName",true); if nm then nm.TextColor3=lv.status=="bloqueado" and C.muted or C.text end
	local ss="" for i=1,3 do ss=ss..(i<=(lv.estrellas or 0) and "★" or "☆") end
	local stars=card:FindFirstChild("CardStars",true); if stars then stars.Text=ss end
	local score=card:FindFirstChild("CardScore",true)
	if score then score.Text=(lv.highScore or 0)>0 and (lv.highScore.." pts") or "—" end

	local ov=card:FindFirstChild("LockOverlay")
	if lv.status=="bloqueado" then
		if not ov then
			ov=n("Frame",{Name="LockOverlay",Size=UDim2.new(1,0,1,0),
				BackgroundColor3=Color3.fromRGB(4,6,12),BackgroundTransparency=0.45,
				BorderSizePixel=0,ZIndex=9},card)
			corner(10,ov)
			n("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="🔒",Font=F.body,TextSize=28,ZIndex=10},ov)
		end
	else
		if ov then ov:Destroy() end
	end
end

-- ── Separador de sección ───────────────────────────────────────────────────
local function buildSectionHeader(title, count, lo, parent)
	local sh=n("Frame",{Name="SecH_"..lo,Size=UDim2.new(1,0,0,28),
		BackgroundTransparency=1,ZIndex=4,LayoutOrder=lo},parent)
	n("TextLabel",{Size=UDim2.new(0,220,1,0),BackgroundTransparency=1,
		Text=title:upper(),TextColor3=C.accent,Font=F.mono,TextSize=9,
		TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5},sh)
	n("Frame",{Size=UDim2.new(1,-230,0,1),Position=UDim2.new(0,220,0.5,0),
		BackgroundColor3=C.border,BorderSizePixel=0,ZIndex=5},sh)
	n("TextLabel",{Size=UDim2.new(0,60,1,0),Position=UDim2.new(1,-60,0,0),
		BackgroundTransparency=1,Text=count..(count==1 and " nivel" or " niveles"),
		TextColor3=C.dim,Font=F.mono,TextSize=9,
		TextXAlignment=Enum.TextXAlignment.Right,ZIndex=5},sh)
end

-- ── buildGrid ──────────────────────────────────────────────────────────────
local function buildGrid(progressData)
	local gridScroll = S2:FindFirstChild("GridArea",true)
	if not gridScroll then warn("[MenuController] GridArea no encontrado"); return end

	-- Limpiar contenido dinámico
	local KEEP = {ProgressBar=true, LoadingFrame=true}
	for _, child in ipairs(gridScroll:GetChildren()) do
		if not KEEP[child.Name] and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
	local lf=gridScroll:FindFirstChild("LoadingFrame"); if lf then lf.Visible=false end

	-- Reconstruir LEVELS desde datos del servidor (claves STRING)
	LEVELS = {}
	local totalNiveles = 0
	for k, datos in pairs(progressData) do
		local id = tonumber(k)
		if id ~= nil and datos then
			datos.nivelID = id
			LEVELS[id] = datos
			totalNiveles = totalNiveles + 1
		end
	end
	print("[MenuController] Niveles recibidos:", totalNiveles)

	-- Agrupar por sección
	local secciones = {}
	local ordenSec  = {}
	for i = 0, 4 do
		local d = LEVELS[i]; if not d then continue end
		local sec = d.seccion or "NIVELES"
		if not secciones[sec] then secciones[sec]={}; table.insert(ordenSec, sec) end
		table.insert(secciones[sec], d)
	end
	table.sort(ordenSec, function(a,b)
		local ma = secciones[a][1] and secciones[a][1].nivelID or 999
		local mb = secciones[b][1] and secciones[b][1].nivelID or 999
		return ma < mb
	end)

	-- ProgressBar=LayoutOrder 1, spacer=2, secciones desde 3
	local lo = 3
	local cols = 2

	for secIdx, secNombre in ipairs(ordenSec) do
		local niveles = secciones[secNombre]
		buildSectionHeader(secNombre, #niveles, lo, gridScroll); lo=lo+1

		local rows  = math.ceil(#niveles/cols)
		local contH = rows*(CARD_H+14)
		local cont  = n("Frame",{Name="Sec_"..secIdx,Size=UDim2.new(1,0,0,contH),
			BackgroundTransparency=1,ZIndex=4,LayoutOrder=lo},gridScroll); lo=lo+1

		for i, lv in ipairs(niveles) do
			buildLevelCard(lv, (i-1)%cols, math.floor((i-1)/cols), cont)
		end

		n("Frame",{Name="Gap_"..secIdx,Size=UDim2.new(1,0,0,18),
			BackgroundTransparency=1,LayoutOrder=lo},gridScroll); lo=lo+1
	end

	-- Ajustar CanvasSize
	local layout=gridScroll:FindFirstChildOfClass("UIListLayout")
	if layout then
		task.defer(function()
			gridScroll.CanvasSize=UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+60)
		end)
	end

	connectLevelCards()
	print("[MenuController] ✅ Grid listo —", #ordenSec, "secciones")
end

-- ── updateProgressBar ──────────────────────────────────────────────────────
local function updateProgressBar()
	local total, completados = 0, 0
	for i=0,4 do if LEVELS[i] then total=total+1; if LEVELS[i].status=="completado" then completados=completados+1 end end end
	local gs=S2:FindFirstChild("GridArea",true); if not gs then return end
	local pb=gs:FindFirstChild("ProgressBar"); if not pb then return end
	local pct=total>0 and (completados/total) or 0
	local pt=pb:FindFirstChild("ProgText"); if pt then pt.Text=completados.." / "..total end
	local pp=pb:FindFirstChild("ProgPct");  if pp then pp.Text=math.floor(pct*100).."%" end
	local pf=pb:FindFirstChild("ProgFill",true); if pf then tween(pf,{Size=UDim2.new(pct,0,1,0)},0.4) end
end

-- ════════════════════════════════════════════════════════════════════════════
-- SIDEBAR — updateSidebar
-- Actualiza: Hero con ImageLabel, badge, InfoBody (tag/nombre/desc/estrellas),
--            StatsGrid (todos los Val), Tags/conceptos, botón de jugar
-- ════════════════════════════════════════════════════════════════════════════
updateSidebar = function(lv)
	local placeholder = S2:FindFirstChild("Placeholder",true)
	local infoContent = S2:FindFirstChild("InfoContent",true)
	if not infoContent then return end
	if placeholder then placeholder.Visible=false end
	infoContent.Visible=true

	local sc = STATUS_COLORS[lv.status] or C.muted

	-- ── Hero ─────────────────────────────────────────────────────────────
	local hero = infoContent:FindFirstChild("Hero")
	if hero then
		-- Color de fondo del hero según estado
		local bgColor = lv.status=="completado" and Color3.fromRGB(26,18,4)
			or lv.status=="disponible" and Color3.fromRGB(4,26,18)
			or Color3.fromRGB(14,14,20)
		hero.BackgroundColor3 = bgColor

		-- HeroGlow tween al color del estado
		local heroGlow = hero:FindFirstChild("HeroGlow")
		if heroGlow then tween(heroGlow, {BackgroundColor3=sc}, 0.2) end

		-- [CORRECCIÓN] HeroEmoji: ocultar si hay imagen, mostrar si no
		local heroEmoji = hero:FindFirstChild("HeroEmoji")

		-- Buscar o crear HeroImage
		local heroImage = hero:FindFirstChild("HeroImage")
		if lv.imageId and lv.imageId ~= "" then
			-- Usar imagen
			if heroEmoji then heroEmoji.Visible=false end
			if not heroImage then
				heroImage = n("ImageLabel",{
					Name="HeroImage",
					Size=UDim2.new(1,0,1,0),
					Position=UDim2.new(0,0,0,0),
					BackgroundTransparency=1,
					Image=lv.imageId,
					ScaleType=Enum.ScaleType.Crop,
					ZIndex=6,
				}, hero)
			else
				heroImage.Image   = lv.imageId
				heroImage.Visible = true
			end
		else
			-- Sin imagen: mostrar emoji
			if heroImage then heroImage.Visible=false end
			if heroEmoji then heroEmoji.Visible=true end
		end

		-- Badge de estado en Hero
		local heroBadge    = hero:FindFirstChild("HeroBadge")
		local heroBadgeTxt = heroBadge and heroBadge:FindFirstChild("HeroBadgeText")
		if heroBadge then
			heroBadge.BackgroundColor3 = bgColor
			local stk=heroBadge:FindFirstChildOfClass("UIStroke"); if stk then stk.Color=sc end
		end
		if heroBadgeTxt then
			heroBadgeTxt.Text      = STATUS_TEXTS[lv.status] or "—"
			heroBadgeTxt.TextColor3 = sc
		end
	end

	-- ── InfoBody ──────────────────────────────────────────────────────────
	local infoBody = infoContent:FindFirstChild("InfoBody")
	if not infoBody then return end

	local infoTag  = infoBody:FindFirstChild("InfoTag")
	local infoName = infoBody:FindFirstChild("InfoName")
	local infoDesc = infoBody:FindFirstChild("InfoDesc")
	if infoTag  then infoTag.Text  = lv.tag         or "" end
	if infoName then infoName.Text = lv.nombre       or "" end
	if infoDesc then infoDesc.Text = lv.descripcion  or "" end

	-- Estrellas
	local starsFrame = infoBody:FindFirstChild("Stars")
	if starsFrame then
		for i=1,3 do
			local s=starsFrame:FindFirstChild("Star"..i)
			if s then s.TextTransparency = i<=(lv.estrellas or 0) and 0 or 0.7 end
		end
	end

	-- ── StatsGrid — CORRECCIÓN PRINCIPAL ─────────────────────────────────
	-- Nombres de campo que llegan del servidor: highScore, aciertos, fallos,
	-- tiempoMejor, intentos (NO score/stars/tiempo como en versiones anteriores)
	local statsGrid = infoBody:FindFirstChild("StatsGrid")
	if statsGrid then
		local function sv(nm, val)
			local box = statsGrid:FindFirstChild(nm)
			local lbl = box and box:FindFirstChild("Val")
			if lbl then lbl.Text = tostring(val) end
		end
		sv("StatScore",  (lv.highScore  or 0)>0 and (lv.highScore.." pts")      or "—")
		sv("StatStatus", lv.status=="completado" and "✓ Completado"
			or lv.status=="disponible" and "Disponible" or "🔒 Bloqueado")
		sv("StatAciert", (lv.aciertos   or 0)>0 and tostring(lv.aciertos)       or "—")
		sv("StatFallos", (lv.fallos     or 0)>0 and tostring(lv.fallos)         or "—")
		sv("StatTiempo", (lv.tiempoMejor or 0)>0 and formatTime(lv.tiempoMejor) or "—")
		sv("StatInten",  (lv.intentos   or 0)>0 and tostring(lv.intentos)       or "—")
	end

	-- Tags/conceptos
	local tagsFrame = infoBody:FindFirstChild("Tags")
	if tagsFrame then
		for _, c in ipairs(tagsFrame:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		for _, concept in ipairs(lv.conceptos or {}) do
			local tb=n("TextButton",{Size=UDim2.new(0,0,0,22),AutomaticSize=Enum.AutomaticSize.X,
				BackgroundColor3=Color3.fromRGB(0,20,30),Text=concept,
				TextColor3=Color3.fromRGB(0,138,170),Font=F.mono,TextSize=9,BorderSizePixel=0},tagsFrame)
			corner(3,tb); stroke(Color3.fromRGB(0,62,90),1,tb)
			pad(3,3,8,8,tb)
		end
	end

	-- Botón jugar
	local pb=S2:FindFirstChild("PlayButton",true)
	if pb then
		if lv.status=="bloqueado" then
			pb.Text="🔒  NIVEL BLOQUEADO"; pb.TextColor3=C.muted; pb.BackgroundColor3=C.panel
			local stk=pb:FindFirstChildOfClass("UIStroke"); if stk then stk.Color=C.border end
		else
			local icon=lv.status=="completado" and "↺  REINTENTAR: " or "▶  JUGAR: "
			pb.Text=icon..lv.nombre:upper(); pb.TextColor3=C.black; pb.BackgroundColor3=C.accent3
			local stk=pb:FindFirstChildOfClass("UIStroke"); if stk then stk.Color=C.accent3 end
		end
	end
end

-- ── resetSidebar ───────────────────────────────────────────────────────────
local function resetSidebar()
	local ph=S2:FindFirstChild("Placeholder",true)
	local ic=S2:FindFirstChild("InfoContent",true)
	if ph then ph.Visible=true  end
	if ic then ic.Visible=false end
	local pb=S2:FindFirstChild("PlayButton",true)
	if pb then
		pb.Text="🔒  SELECCIONA UN NIVEL"; pb.TextColor3=C.muted; pb.BackgroundColor3=C.panel
		local stk=pb:FindFirstChildOfClass("UIStroke"); if stk then stk.Color=C.border end
	end
end

-- ── connectLevelCards ──────────────────────────────────────────────────────
connectLevelCards = function()
	local gridScroll=S2:FindFirstChild("GridArea",true); if not gridScroll then return end
	local count=0
	for id=0,4 do
		local card=gridScroll:FindFirstChild("Card"..id,true)
		if card and card:IsA("TextButton") and LEVELS[id] then
			count=count+1
			card.MouseButton1Click:Connect(function()
				if isLoading then return end
				selectedLevelID=id
				updateSidebar(LEVELS[id])
				for i=0,4 do
					local c=gridScroll:FindFirstChild("Card"..i,true)
					if c then
						local st=c:FindFirstChildOfClass("UIStroke")
						if st then
							st.Color    = i==id and C.accent or (LEVELS[i] and LEVELS[i].status=="completado" and C.gold or C.border)
							st.Thickness= i==id and 2 or 1
						end
					end
				end
			end)
		end
	end
	print("[MenuController] Tarjetas conectadas:", count, "/ 5")
end

-- ── loadProgress ───────────────────────────────────────────────────────────
local function loadProgress()
	if progressLoaded then return end
	progressLoaded = true
	if not getProgressFn then warn("[MenuController] GetPlayerProgress no disponible"); return end

	local ok, data = pcall(function() return getProgressFn:InvokeServer() end)
	if not ok or not data then
		warn("[MenuController] ❌ Error al obtener progreso"); progressLoaded=false; return
	end

	buildGrid(data)
	updateProgressBar()

	-- [CORRECCIÓN] Si hay un nivel seleccionado, refrescar sidebar con datos nuevos
	-- Esto actualiza los StatsGrid.Val tras volver de una partida
	if selectedLevelID ~= nil and LEVELS[selectedLevelID] then
		updateSidebar(LEVELS[selectedLevelID])
	end

	-- Nombre del jugador
	local playerTag=S2:FindFirstChild("PlayerTag",true)
	if playerTag then playerTag.Text = player.DisplayName or player.Name end

	print("[MenuController] ✅ Progreso cargado")
end

-- ── Navegación ─────────────────────────────────────────────────────────────
local function goToMenu()
	S1.Visible=true; S2.Visible=false; selectedLevelID=nil; setupMenuCamera()
end

local function goToLevels()
	S1.Visible=false; S2.Visible=true
	resetSidebar(); selectedLevelID=nil
	progressLoaded=false
	task.spawn(loadProgress)
end

local function openModal(f)  if f then f.Visible=true  end end
local function closeModal(f) if f then f.Visible=false end end

-- ── Menú principal (S1) ────────────────────────────────────────────────────
local mp = S1:FindFirstChild("MenuPanel")
local Bp = mp and mp:FindFirstChild("BtnPlay")
local Bs = mp and mp:FindFirstChild("BtnSettings")
local Bc = mp and mp:FindFirstChild("BtnCredits")
local Be = mp and mp:FindFirstChild("BtnExit")
if Bp then Bp.MouseButton1Click:Connect(goToLevels) end
if Bs then Bs.MouseButton1Click:Connect(function() openModal(S3) end) end
if Bc then Bc.MouseButton1Click:Connect(function() openModal(S4) end) end
if Be then Be.MouseButton1Click:Connect(function() openModal(S5) end) end

for _, frame in ipairs({S3, S4, S5}) do
	local bc=frame:FindFirstChild("BtnClose",true)
	if bc then bc.MouseButton1Click:Connect(function() closeModal(frame) end) end
end

-- ── Selector de niveles (S2) ───────────────────────────────────────────────
local backBtn = S2:FindFirstChild("BackBtn",true) or S2:FindFirstChild("BtnBack",true)
if backBtn then backBtn.MouseButton1Click:Connect(goToMenu) end

-- Botón jugar en sidebar
local playBtnSidebar = S2:FindFirstChild("PlayButton",true)
if playBtnSidebar then
	playBtnSidebar.MouseButton1Click:Connect(function()
		if isLoading or selectedLevelID==nil then return end
		local lv=LEVELS[selectedLevelID]
		if not lv or lv.status=="bloqueado" then return end

		isLoading=true
		local thisLoad=os.clock(); loadStartTime=thisLoad
		if loadingLbl then loadingLbl.Text="Cargando  "..(lv.nombre or "").."..." end

		fadeIn(0.4, function()
			if requestPlayLEv then
				requestPlayLEv:FireServer(selectedLevelID)
				task.spawn(function()
					task.wait(10)
					if isLoading and loadStartTime==thisLoad then
						if loadingLbl then loadingLbl.Text="⏱ Sin respuesta del servidor" end
						task.delay(1.5, function()
							if isLoading and loadStartTime==thisLoad then
								fadeOut(0.4, function() isLoading=false; goToLevels() end)
							end
						end)
					end
				end)
			end
		end)
	end)
end

-- ── LevelReady ─────────────────────────────────────────────────────────────
if levelReadyEv then
	levelReadyEv.OnClientEvent:Connect(function(data)
		if data and data.error then
			if loadingLbl then loadingLbl.Text="❌ "..data.error end
			task.delay(2.5, function() fadeOut(0.4, function() isLoading=false; goToLevels() end) end)
			return
		end
		if loadingLbl then loadingLbl.Text="✅  "..(data and data.nombre or "Nivel cargado") end
		task.delay(0.6, function()
			fadeOut(0.4, function()
				root.Enabled=false; isLoading=false; restoreGameCamera()
			end)
		end)
	end)
end

-- ── ReturnToMenu ───────────────────────────────────────────────────────────
if returnToMenuEv then
	returnToMenuEv.OnClientEvent:Connect(function()
		task.delay(0.1, function()
			root.Enabled=true
			setupMenuCamera()
			game:GetService("UserInputService").MouseBehavior=Enum.MouseBehavior.Default
			-- Forzar recarga completa para mostrar datos frescos del último intento
			-- selectedLevelID se conserva para que updateSidebar lo use tras buildGrid
			progressLoaded=false
			task.spawn(loadProgress)
			print("[MenuController] Menú restaurado — recargando progreso y sidebar")
		end)
	end)
end

-- ── ServerReady ────────────────────────────────────────────────────────────
if serverReadyEv then
	serverReadyEv.OnClientEvent:Connect(function()
		print("[MenuController] ServerReady recibido")
		task.spawn(loadProgress)
	end)
end

-- Respaldo si ServerReady llegó antes que este script
task.delay(5, function()
	if not progressLoaded then
		print("[MenuController] Respaldo: cargando progreso")
		task.spawn(loadProgress)
	end
end)

-- Nombre del jugador inicial
local playerTag=S2:FindFirstChild("PlayerTag",true)
if playerTag then playerTag.Text = player.DisplayName or player.Name end

setupMenuCamera()
print("[EDA v2] ✅ MenuController activo")