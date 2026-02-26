-- MenuController.client.lua
-- Ubicación Roblox: StarterPlayerScripts/MenuController  (LocalScript)

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RS               = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local root = playerGui:WaitForChild("EDAQuestMenu", 30)
if not root then
	warn("[MenuController] ❌ EDAQuestMenu no encontrado en PlayerGui.")
	return
end
print("[MenuController] ✅ EDAQuestMenu encontrada")

-- ── Eventos ────────────────────────────────────────────────────────────────
local eventsFolder  = RS:WaitForChild("Events", 10)
local remotesFolder = eventsFolder:WaitForChild("Remotes", 5)

local serverReadyEv  = remotesFolder:FindFirstChild("ServerReady")
local requestPlayLEv = remotesFolder:FindFirstChild("RequestPlayLevel")
local levelReadyEv   = remotesFolder:FindFirstChild("LevelReady")
local getProgressFn  = remotesFolder:FindFirstChild("GetPlayerProgress")

-- ── Frames ─────────────────────────────────────────────────────────────────
local S1 = root:WaitForChild("FrameMenu")
local S2 = root:WaitForChild("FrameLevels")
local S3 = root:WaitForChild("FrameSettings")
local S4 = root:WaitForChild("FrameCredits")
local S5 = root:WaitForChild("FrameExit")

-- ── Colores / fuentes ──────────────────────────────────────────────────────
local C = {
	accent  = Color3.fromRGB(0,   212, 255),
	accent3 = Color3.fromRGB(16,  185, 129),
	panel   = Color3.fromRGB(17,  25,  39),
	border  = Color3.fromRGB(30,  45,  66),
	muted   = Color3.fromRGB(100, 116, 139),
	gold    = Color3.fromRGB(245, 158, 11),
	text    = Color3.fromRGB(226, 232, 240),
	black   = Color3.fromRGB(0,   0,   0),
	danger  = Color3.fromRGB(239, 68,  68),
	dim     = Color3.fromRGB(51,  65,  85),
}
local F = {
	title = Enum.Font.GothamBlack,
	mono  = Enum.Font.RobotoMono,
	body  = Enum.Font.Gotham,
	bold  = Enum.Font.GothamBold,
}

local STATUS_COLORS = { completado=C.gold, disponible=C.accent3, bloqueado=C.muted }
local STATUS_TEXTS  = { completado="✓ COMPLETADO", disponible="DISPONIBLE", bloqueado="🔒 BLOQUEADO" }

-- ── Estado ─────────────────────────────────────────────────────────────────
local LEVELS          = {}   -- llenado desde servidor, nunca hardcodeado
local selectedLevelID = nil
local isLoading       = false
local loadStartTime   = 0
-- Bandera para evitar doble carga (ServerReady + task.delay de respaldo)
local progressLoaded  = false

-- ── Helpers UI ────────────────────────────────────────────────────────────
local function n(cls, props, par)
	local o = Instance.new(cls)
	for k,v in pairs(props) do o[k]=v end
	if par then o.Parent=par end
	return o
end
local function corner(r,p) n("UICorner",{CornerRadius=UDim.new(0,r)},p) end
local function stroke(col,th,p) n("UIStroke",{Color=col,Thickness=th},p) end

local function tween(obj, props, t, style)
	local tw = TweenService:Create(obj,
		TweenInfo.new(t or 0.15, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		props)
	tw:Play(); return tw
end

local function formatTime(s)
	if not s or s==0 then return "—" end
	return string.format("%d:%02d", math.floor(s/60), s%60)
end

-- ── Cámara ─────────────────────────────────────────────────────────────────
local camera = workspace.CurrentCamera

local function setupMenuCamera()
	camera.CameraType = Enum.CameraType.Scriptable

	-- Buscar primero en ReplicatedStorage (recomendado: sin personaje el
	-- Workspace puede no estar listo en el cliente al arrancar el menú).
	-- Si no está ahí, buscar en Workspace como fallback.
	local camPart = nil

	local camRS = RS:FindFirstChild("CamaraMenu")
	if camRS then
		camPart = camRS:IsA("BasePart") and camRS
			or (camRS:IsA("Model") and camRS.PrimaryPart)
	end

	if not camPart then
		local camWS = workspace:FindFirstChild("CamaraMenu", true)
		if camWS then
			camPart = camWS:IsA("BasePart") and camWS
				or (camWS:IsA("Model") and camWS.PrimaryPart)
		end
	end

	if camPart then
		camera.CFrame = camPart.CFrame
	else
		-- Fallback neutro si no existe CamaraMenu en ningún lugar
		camera.CFrame = CFrame.new(0, 20, 40) * CFrame.Angles(math.rad(-15), math.rad(180), 0)
	end
end

local function restoreGameCamera()
	camera.CameraType = Enum.CameraType.Custom
end

setupMenuCamera()  -- inmediato al arrancar

-- ── Transición ─────────────────────────────────────────────────────────────
local transOverlay = n("Frame",{
	Name="TransitionOverlay", Size=UDim2.new(1,0,1,0),
	BackgroundColor3=Color3.new(0,0,0), BackgroundTransparency=1,
	BorderSizePixel=0, ZIndex=200, Visible=false,
}, root)
local loadingLbl = n("TextLabel",{
	Size=UDim2.new(0.6,0,0,30), Position=UDim2.new(0.2,0,0.5,-15),
	BackgroundTransparency=1, Text="Cargando...",
	TextColor3=Color3.fromRGB(226,232,240), Font=F.mono,
	TextSize=14, TextXAlignment=Enum.TextXAlignment.Center, ZIndex=201,
}, transOverlay)

local function fadeIn(dur, cb)
	transOverlay.BackgroundTransparency=1; transOverlay.Visible=true
	local tw=tween(transOverlay,{BackgroundTransparency=0},dur or 0.35,Enum.EasingStyle.Linear)
	if cb then tw.Completed:Connect(cb) end
end
local function fadeOut(dur, cb)
	local tw=tween(transOverlay,{BackgroundTransparency=1},dur or 0.35,Enum.EasingStyle.Linear)
	tw.Completed:Connect(function() transOverlay.Visible=false; if cb then cb() end end)
end

-- ════════════════════════════════════════════════════════════════════
-- GRID DINÁMICO
-- ════════════════════════════════════════════════════════════════════

local connectLevelCards  -- forward declaration

-- Limpia TODO el contenido dinámico del grid, preservando solo
-- ProgressBar, LoadingFrame y el UIListLayout.
local function clearGrid(gridScroll)
	local KEEP = { ProgressBar=true, LoadingFrame=true, UIListLayout=true }
	for _, child in ipairs(gridScroll:GetChildren()) do
		if not KEEP[child.Name] and not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
end

local function buildLevelCard(lv, col, row, cont)
	local sc = STATUS_COLORS[lv.status] or C.muted
	local card = n("TextButton",{
		Name="Card"..lv.nivelID,
		Size=UDim2.new(0,200,0,165),
		Position=UDim2.new(0, col*214, 0, row*175),
		BackgroundColor3=C.panel, Text="", AutoButtonColor=false,
		BorderSizePixel=0, ZIndex=4,
	}, cont)
	corner(10,card); stroke(lv.status=="completado" and C.gold or C.border, 1, card)

	-- Etiqueta nivel
	n("TextLabel",{Size=UDim2.new(0,60,0,14),Position=UDim2.new(0,12,0,10),
		BackgroundTransparency=1,Text="Nivel "..lv.nivelID,TextColor3=C.accent,
		Font=F.mono,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5},card)

	-- Badge estado
	local sbg=n("Frame",{Name="StatusBadge",Size=UDim2.new(0,90,0,16),
		Position=UDim2.new(1,-98,0,9),BackgroundColor3=sc,
		BackgroundTransparency=0.88,BorderSizePixel=0,ZIndex=5},card)
	corner(3,sbg); stroke(sc,1,sbg)
	n("TextLabel",{Name="StatusText",Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
		Text=STATUS_TEXTS[lv.status] or "—",TextColor3=sc,Font=F.mono,TextSize=8,ZIndex=6},sbg)

	-- Emoji
	n("TextLabel",{Size=UDim2.new(1,0,0,40),Position=UDim2.new(0,0,0,26),
		BackgroundTransparency=1,Text=lv.emoji or "🔵",Font=F.body,TextSize=28,ZIndex=5},card)

	-- Nombre
	n("TextLabel",{Size=UDim2.new(1,-24,0,32),Position=UDim2.new(0,12,0,68),
		BackgroundTransparency=1,Text=lv.nombre,
		TextColor3=lv.status=="bloqueado" and C.muted or C.text,
		Font=F.bold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,
		TextWrapped=true,ZIndex=5},card)

	-- Algoritmo
	n("TextLabel",{Size=UDim2.new(1,-24,0,14),Position=UDim2.new(0,12,0,102),
		BackgroundTransparency=1,Text="· "..(lv.algoritmo or "—"),
		TextColor3=C.muted,Font=F.mono,TextSize=9,
		TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5},card)

	-- Footer
	local ft=n("Frame",{Name="CardFooter",Size=UDim2.new(1,0,0,28),
		Position=UDim2.new(0,0,1,-28),BackgroundTransparency=1,ZIndex=5},card)
	stroke(C.border,1,ft)
	local ss="" for i=1,3 do ss=ss..(i<=lv.estrellas and "★" or "☆") end
	n("TextLabel",{Name="CardStars",Size=UDim2.new(0,56,1,0),Position=UDim2.new(0,12,0,0),
		BackgroundTransparency=1,Text=ss,TextColor3=C.gold,Font=F.body,TextSize=13,
		TextXAlignment=Enum.TextXAlignment.Left,ZIndex=6},ft)
	n("TextLabel",{Name="CardScore",Size=UDim2.new(0,70,1,0),Position=UDim2.new(1,-78,0,0),
		BackgroundTransparency=1,Text=lv.highScore>0 and (lv.highScore.." pts") or "—",
		TextColor3=C.gold,Font=F.mono,TextSize=10,
		TextXAlignment=Enum.TextXAlignment.Right,ZIndex=6},ft)

	-- Overlay candado
	if lv.status=="bloqueado" then
		local ov=n("Frame",{Name="LockOverlay",Size=UDim2.new(1,0,1,0),
			BackgroundColor3=Color3.fromRGB(4,6,12),BackgroundTransparency=0.45,
			BorderSizePixel=0,ZIndex=7},card)
		corner(10,ov)
		n("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
			Text="🔒",Font=F.body,TextSize=26,ZIndex=8},ov)
	end
	return card
end

local function buildSectionHeader(title, count, lo, parent)
	local sh=n("Frame",{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,
		ZIndex=4,LayoutOrder=lo},parent)
	n("TextLabel",{Size=UDim2.new(0,210,1,0),BackgroundTransparency=1,Text=title,
		TextColor3=C.muted,Font=F.bold,TextSize=10,
		TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5},sh)
	n("Frame",{Size=UDim2.new(1,-230,0,1),Position=UDim2.new(0,220,0.5,0),
		BackgroundColor3=C.border,BorderSizePixel=0,ZIndex=5},sh)
	n("TextLabel",{Size=UDim2.new(0,80,1,0),Position=UDim2.new(1,-80,0,0),
		BackgroundTransparency=1,Text=count.." niveles",TextColor3=C.dim,
		Font=F.mono,TextSize=9,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=5},sh)
end

local function buildGrid(progressData)
	local gridScroll = S2:FindFirstChild("GridArea", true)
	if not gridScroll then warn("[MenuController] GridArea no encontrado"); return end

	-- ── Limpiar TODO el contenido dinámico anterior ──────────────────────
	clearGrid(gridScroll)

	-- Ocultar spinner
	local loadingFrame = gridScroll:FindFirstChild("LoadingFrame")
	if loadingFrame then loadingFrame.Visible=false end

	-- ── Poblar LEVELS desde claves STRING del servidor ───────────────────
	-- DataService envía {"0":{...},"1":{...},...} porque Roblox descarta la
	-- clave numérica [0] al serializar RemoteFunctions. Convertimos aquí.
	LEVELS = {}
	local totalNiveles = 0
	for k, datos in pairs(progressData) do
		local id = tonumber(k)
		if id ~= nil and datos then
			datos.nivelID = id
			LEVELS[id]    = datos
			totalNiveles += 1
		end
	end
	print("[MenuController] Niveles recibidos del servidor:", totalNiveles)

	-- ── Agrupar por sección en orden numérico ─────────────────────────────
	local secciones      = {}
	local ordenSecciones = {}

	for i = 0, 4 do
		local datos = LEVELS[i]
		if datos then
			local sec = datos.seccion or "NIVELES"
			if not secciones[sec] then
				secciones[sec] = {}
				table.insert(ordenSecciones, sec)
			end
			table.insert(secciones[sec], datos)
		end
	end

	-- Ordenar secciones por nivelID mínimo que contienen
	table.sort(ordenSecciones, function(a,b)
		local ma = secciones[a][1] and secciones[a][1].nivelID or 999
		local mb = secciones[b][1] and secciones[b][1].nivelID or 999
		return ma < mb
	end)

	-- ── Crear frames en el grid ───────────────────────────────────────────
	-- ProgressBar ya tiene LayoutOrder=1, el spacer tras él tiene LayoutOrder=2.
	-- Las secciones empiezan en 3 y van subiendo.
	local lo = 3

	for secIdx, secNombre in ipairs(ordenSecciones) do
		local niveles = secciones[secNombre]

		buildSectionHeader(secNombre, #niveles, lo, gridScroll)
		lo += 1

		local rows = math.ceil(#niveles / 2)
		local cont = n("Frame",{
			Name="Sec_"..secIdx,
			Size=UDim2.new(1,0,0, rows*175),
			BackgroundTransparency=1, ZIndex=4, LayoutOrder=lo,
		}, gridScroll)
		lo += 1

		for i, lv in ipairs(niveles) do
			buildLevelCard(lv, (i-1)%2, math.floor((i-1)/2), cont)
		end

		-- Espaciador entre secciones
		n("Frame",{Name="Gap_"..secIdx,Size=UDim2.new(1,0,0,22),
			BackgroundTransparency=1, LayoutOrder=lo}, gridScroll)
		lo += 1
	end

	-- Actualizar CanvasSize después de que el layout procese
	local layout = gridScroll:FindFirstChildOfClass("UIListLayout")
	if layout then
		task.defer(function()
			gridScroll.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y+60)
		end)
	end

	connectLevelCards()
	print("[MenuController] ✅ Grid listo —", #ordenSecciones, "secciones,", totalNiveles, "niveles")
end

local function updateProgressBar(progressData)
	local total, completed = 0, 0
	for i=0,4 do
		local lv = progressData[i]
		if lv then
			total += 1
			if lv.status=="completado" then completed += 1 end
		end
	end
	local progWrap = S2:FindFirstChild("ProgressBar", true)
	if not progWrap then return end
	local pct = total>0 and (completed/total) or 0
	local pt  = progWrap:FindFirstChild("ProgText")
	local pf  = progWrap:FindFirstChild("ProgFill")
	local pp  = progWrap:FindFirstChild("ProgPct")
	if pt then pt.Text=completed.." / "..total end
	if pp then pp.Text=math.floor(pct*100).."%" end
	if pf then tween(pf,{Size=UDim2.new(pct,0,1,0)},0.4) end
end

local function loadProgress()
	-- Evitar doble ejecución
	if progressLoaded then return end
	progressLoaded = true

	if not getProgressFn then
		warn("[MenuController] GetPlayerProgress no disponible"); return
	end

	local ok, data = pcall(function() return getProgressFn:InvokeServer() end)

	if not ok or not data then
		warn("[MenuController] ❌ Error al obtener progreso del servidor")
		progressLoaded = false   -- permitir reintento
		local lf = S2:FindFirstChild("LoadingFrame", true)
		if lf then
			local t = lf:FindFirstChild("LoadingText")
			if t then t.Text="❌ Error al cargar niveles. Reintentando..." end
		end
		-- Reintentar en 3 segundos
		task.delay(3, loadProgress)
		return
	end

	local playerTag = S2:FindFirstChild("PlayerTag", true)
	if playerTag then playerTag.Text = player.DisplayName end

	buildGrid(data)
	updateProgressBar(data)
end

-- ════════════════════════════════════════════════════════════════════
-- SIDEBAR
-- ════════════════════════════════════════════════════════════════════

local function updateSidebar(lv)
	local placeholder = S2:FindFirstChild("Placeholder", true)
	local infoContent = S2:FindFirstChild("InfoContent", true)
	if not infoContent then return end
	placeholder.Visible=false; infoContent.Visible=true

	local hero    = infoContent:FindFirstChild("Hero")
	local sc      = STATUS_COLORS[lv.status] or C.muted
	local heroEmoji    = hero and hero:FindFirstChild("HeroEmoji")
	local heroBadge    = hero and hero:FindFirstChild("HeroBadge")
	local heroBadgeTxt = heroBadge and heroBadge:FindFirstChild("HeroBadgeText")
	local heroGlow     = hero and hero:FindFirstChild("HeroGlow")

	if heroEmoji then heroEmoji.Text=lv.emoji or "🔵" end
	local bgColor = lv.status=="completado" and Color3.fromRGB(26,18,4)
		or lv.status=="disponible" and Color3.fromRGB(4,26,18)
		or Color3.fromRGB(14,14,20)
	if heroBadge then
		heroBadge.BackgroundColor3=bgColor
		local stk=heroBadge:FindFirstChildOfClass("UIStroke")
		if stk then stk.Color=sc end
	end
	if heroBadgeTxt then heroBadgeTxt.Text=STATUS_TEXTS[lv.status] or "—"; heroBadgeTxt.TextColor3=sc end
	if heroGlow then tween(heroGlow,{BackgroundColor3=sc},0.2) end

	local ib = infoContent:FindFirstChild("InfoBody")
	if not ib then return end

	local function set(name, val)
		local e=ib:FindFirstChild(name); if e then e.Text=tostring(val) end
	end
	set("InfoTag",  lv.tag        or "")
	set("InfoName", lv.nombre     or "")
	set("InfoDesc", lv.descripcion or "")

	local sf = ib:FindFirstChild("Stars")
	if sf then
		for i=1,3 do
			local s=sf:FindFirstChild("Star"..i)
			if s then s.TextTransparency=i<=lv.estrellas and 0 or 0.7 end
		end
	end

	local sg = ib:FindFirstChild("StatsGrid")
	if sg then
		local function sv(nm, v)
			local b=sg:FindFirstChild(nm); local l=b and b:FindFirstChild("Val")
			if l then l.Text=tostring(v) end
		end
		sv("StatScore",  lv.highScore>0   and (lv.highScore.." pts")     or "—")
		sv("StatStatus", lv.status=="completado" and "✓ Completado"
			or lv.status=="disponible" and "Disponible" or "🔒 Bloqueado")
		sv("StatAciert", lv.aciertos>0    and lv.aciertos                or "—")
		sv("StatFallos", lv.fallos>0      and lv.fallos                  or "—")
		sv("StatTiempo", lv.tiempoMejor>0 and formatTime(lv.tiempoMejor) or "—")
		sv("StatInten",  lv.intentos>0    and lv.intentos                or "—")
	end

	local tf = ib:FindFirstChild("Tags")
	if tf then
		for _,c in ipairs(tf:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		for _, concept in ipairs(lv.conceptos or {}) do
			local tb=n("TextButton",{Size=UDim2.new(0,0,0,22),AutomaticSize=Enum.AutomaticSize.X,
				BackgroundColor3=Color3.fromRGB(0,20,30),Text=concept,
				TextColor3=Color3.fromRGB(0,138,170),Font=F.mono,TextSize=9,BorderSizePixel=0},tf)
			corner(3,tb); stroke(Color3.fromRGB(0,62,90),1,tb)
			n("UIPadding",{PaddingTop=UDim.new(0,3),PaddingBottom=UDim.new(0,3),
				PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)},tb)
		end
	end

	local pb = S2:FindFirstChild("PlayButton", true)
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

-- ════════════════════════════════════════════════════════════════════
-- CONEXIÓN DE TARJETAS
-- ════════════════════════════════════════════════════════════════════

connectLevelCards = function()
	local gridArea = S2:FindFirstChild("GridArea", true)
	if not gridArea then return end
	local connected=0
	for i=0,4 do
		local lv   = LEVELS[i]
		local card = lv and gridArea:FindFirstChild("Card"..i, true)
		if card and card:IsA("TextButton") then
			connected += 1
			card.MouseButton1Click:Connect(function()
				if isLoading then return end
				selectedLevelID=i
				updateSidebar(lv)
				-- Highlight borde
				for j=0,4 do
					local c=gridArea:FindFirstChild("Card"..j, true)
					if c then
						local st=c:FindFirstChildOfClass("UIStroke")
						if st then
							st.Color     = j==i and C.accent or (LEVELS[j] and LEVELS[j].status=="completado" and C.gold or C.border)
							st.Thickness = j==i and 2 or 1
						end
					end
				end
			end)
		end
	end
	print("[MenuController] Tarjetas conectadas:", connected)
end

-- ════════════════════════════════════════════════════════════════════
-- NAVEGACIÓN
-- ════════════════════════════════════════════════════════════════════

local function resetSidebar()
	local ph=S2:FindFirstChild("Placeholder",true)
	local ic=S2:FindFirstChild("InfoContent",true)
	if ph then ph.Visible=true end
	if ic then ic.Visible=false end
	local pb=S2:FindFirstChild("PlayButton",true)
	if pb then
		pb.Text="🔒  SELECCIONA UN NIVEL"; pb.TextColor3=C.muted; pb.BackgroundColor3=C.panel
		local stk=pb:FindFirstChildOfClass("UIStroke"); if stk then stk.Color=C.border end
	end
end

local function goToMenu()
	S1.Visible=true; S2.Visible=false; selectedLevelID=nil
end

local function goToLevels()
	S1.Visible=false; S2.Visible=true
	resetSidebar(); selectedLevelID=nil
	-- Recargar progreso si ya se había cargado antes (para reflejar cambios)
	progressLoaded=false
	task.spawn(loadProgress)
end

local function openModal(f)  f.Visible=true  end
local function closeModal(f) f.Visible=false end

-- ════════════════════════════════════════════════════════════════════
-- MENÚ PRINCIPAL (S1)
-- ════════════════════════════════════════════════════════════════════

local mp  = S1:FindFirstChild("MenuPanel")
local Bp  = mp and mp:FindFirstChild("BtnPlay")
local Bs  = mp and mp:FindFirstChild("BtnSettings")
local Bc  = mp and mp:FindFirstChild("BtnCredits")
local Be  = mp and mp:FindFirstChild("BtnExit")

if Bp then Bp.MouseButton1Click:Connect(goToLevels)                       end
if Bs then Bs.MouseButton1Click:Connect(function() openModal(S3) end)     end
if Bc then Bc.MouseButton1Click:Connect(function() openModal(S4) end)     end
if Be then Be.MouseButton1Click:Connect(function() openModal(S5) end)     end

local function addHover(btn, hov, nor)
	if not btn then return end
	btn.MouseEnter:Connect(function() tween(btn,{BackgroundColor3=hov},0.1) end)
	btn.MouseLeave:Connect(function() tween(btn,{BackgroundColor3=nor},0.1) end)
end
addHover(Bs, Color3.fromRGB(24,34,52), Color3.fromRGB(8,14,24))
addHover(Bc, Color3.fromRGB(24,34,52), Color3.fromRGB(8,14,24))
addHover(Be, Color3.fromRGB(40,10,10), Color3.fromRGB(8,14,24))

-- ════════════════════════════════════════════════════════════════════
-- SELECTOR (S2)
-- ════════════════════════════════════════════════════════════════════

local backBtn = S2:FindFirstChild("BackBtn", true)
if backBtn then backBtn.MouseButton1Click:Connect(goToMenu) end

local playBtn = S2:FindFirstChild("PlayButton", true)
if playBtn then
	playBtn.MouseButton1Click:Connect(function()
		if isLoading or selectedLevelID==nil then return end
		local lv=LEVELS[selectedLevelID]
		if not lv or lv.status=="bloqueado" then return end

		isLoading=true
		loadingLbl.Text="Cargando  "..lv.nombre.."..."
		local thisLoad=os.clock(); loadStartTime=thisLoad

		fadeIn(0.4, function()
			if requestPlayLEv then
				requestPlayLEv:FireServer(selectedLevelID)
				task.spawn(function()
					task.wait(10)
					if isLoading and loadStartTime==thisLoad then
						warn("[MenuController] ⏱ Timeout")
						loadingLbl.Text="⏱ Sin respuesta del servidor"
						task.delay(1.5, function()
							if isLoading and loadStartTime==thisLoad then
								isLoading=false; fadeOut(0.35, goToLevels)
							end
						end)
					end
				end)
			else
				task.delay(1.5, function()
					fadeOut(0.4, function() root.Enabled=false; isLoading=false end)
				end)
			end
		end)
	end)
end

-- ════════════════════════════════════════════════════════════════════
-- AJUSTES (S3)
-- ════════════════════════════════════════════════════════════════════
do
	local function close() closeModal(S3) end
	local cb=S3:FindFirstChild("CloseBtn",true)
	local cn=S3:FindFirstChild("CancelBtn",true)
	local sv=S3:FindFirstChild("SaveBtn",true)
	if cb then cb.MouseButton1Click:Connect(close) end
	if cn then cn.MouseButton1Click:Connect(close) end
	if sv then sv.MouseButton1Click:Connect(close) end
end

local function connectSlider(row, onChange)
	if not row then return end
	local track=row:FindFirstChild("Track")
	local fill =row:FindFirstChild("Fill")
	local pct  =row:FindFirstChild("Pct")
	if not track or not fill then return end
	local drag=false
	local function upd(sx)
		local v=math.clamp((sx-track.AbsolutePosition.X)/math.max(track.AbsoluteSize.X,1),0,1)
		fill.Size=UDim2.new(v,0,1,0)
		if pct then pct.Text=math.floor(v*100).."%" end
		if onChange then onChange(v) end
	end
	track.MouseButton1Down:Connect(function(rx) drag=true; upd(track.AbsolutePosition.X+rx) end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if drag and i.UserInputType==Enum.UserInputType.MouseMovement then upd(i.Position.X) end
	end)
end
connectSlider(S3:FindFirstChild("AmbientSlider",true))
connectSlider(S3:FindFirstChild("SFXSlider",true))

-- ════════════════════════════════════════════════════════════════════
-- CRÉDITOS (S4)
-- ════════════════════════════════════════════════════════════════════
do
	local cb=S4:FindFirstChild("CloseBtn",true); local ok=S4:FindFirstChild("OkBtn",true)
	if cb then cb.MouseButton1Click:Connect(function() closeModal(S4) end) end
	if ok then ok.MouseButton1Click:Connect(function() closeModal(S4) end) end
end

-- ════════════════════════════════════════════════════════════════════
-- SALIR (S5)
-- ════════════════════════════════════════════════════════════════════
do
	local cb=S5:FindFirstChild("CloseBtn",true)
	local cn=S5:FindFirstChild("CancelBtn",true)
	local cf=S5:FindFirstChild("ConfirmBtn",true)
	if cb then cb.MouseButton1Click:Connect(function() closeModal(S5) end) end
	if cn then cn.MouseButton1Click:Connect(function() closeModal(S5) end) end
	if cf then cf.MouseButton1Click:Connect(function()
			player:Kick("¡Hasta pronto! Gracias por jugar EDA Quest.")
		end) end
end

-- ════════════════════════════════════════════════════════════════════
-- ReturnToMenu — restaurar cámara y reactivar menú
-- ════════════════════════════════════════════════════════════════════
-- ClientBoot reactiva root.Enabled, pero la cámara queda en el estado
-- del gameplay. Escuchamos el mismo evento para restaurarla aquí.
local returnToMenuEv = remotesFolder:FindFirstChild("ReturnToMenu")
if returnToMenuEv then
	returnToMenuEv.OnClientEvent:Connect(function()
		-- Pequeño delay para que ClientBoot termine de reactivar la GUI primero
		task.delay(0.1, function()
			root.Enabled = true
			setupMenuCamera()
			-- Liberar el mouse por si el gameplay lo había bloqueado
			local UIS = game:GetService("UserInputService")
			UIS.MouseBehavior = Enum.MouseBehavior.Default
			-- Resetear progreso para recargar tarjetas con datos frescos
			progressLoaded = false
			task.spawn(loadProgress)
			print("[MenuController] Menú restaurado tras ReturnToMenu")
		end)
	end)
end

-- ════════════════════════════════════════════════════════════════════
-- LevelReady
-- ════════════════════════════════════════════════════════════════════
if levelReadyEv then
	levelReadyEv.OnClientEvent:Connect(function(data)
		if data.error then
			loadingLbl.Text="❌ "..data.error
			task.delay(2.5, function()
				fadeOut(0.4, function() isLoading=false; goToLevels() end)
			end)
			return
		end
		loadingLbl.Text="✅  "..(data.nombre or "Nivel "..tostring(data.nivelID))
		task.delay(0.6, function()
			fadeOut(0.4, function()
				root.Enabled=false; isLoading=false
				restoreGameCamera()
			end)
		end)
	end)
end

-- ════════════════════════════════════════════════════════════════════
-- ServerReady → carga inicial (una sola vez)
-- ════════════════════════════════════════════════════════════════════
if serverReadyEv then
	serverReadyEv.OnClientEvent:Connect(function()
		print("[MenuController] ServerReady recibido")
		task.spawn(loadProgress)
	end)
end

-- Respaldo por si ServerReady llegó antes de que este script corriera.
-- La bandera progressLoaded evita doble ejecución.
task.delay(5, function()
	if not progressLoaded then
		print("[MenuController] Respaldo: ServerReady no recibido, cargando igual")
		task.spawn(loadProgress)
	end
end)

print("[EDA v2] ✅ MenuController activo")