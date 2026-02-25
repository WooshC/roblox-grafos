-- MenuController.client.lua v2.2
-- CORRECCIONES:
--   - setupMenuCamera: solo activa cámara scriptable si CamaraMenu existe en workspace
--   - restoreGameCamera: restaura CameraType a Custom Y desvincula el Subject del personaje
--     antes de ocultar el menú para que Roblox retome control normal
--   - LevelReady: llama restoreGameCamera() ANTES de hacer fadeOut y ocultar root
--   - ReturnToMenu: vuelve a activar cámara del menú si CamaraMenu existe
--
-- Ubicación Roblox: StarterGui/MenuController.client.lua  (LocalScript)

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RS               = game:GetService("ReplicatedStorage")
local RunService       = game:GetService("RunService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ── Esperar la GUI ─────────────────────────────────────────────────────────
local root = playerGui:WaitForChild("EDAQuestMenu", 30)
if not root then
	warn("[MenuController] ❌ EDAQuestMenu no encontrado en PlayerGui.")
	return
end

-- ── Eventos del servidor ───────────────────────────────────────────────────
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
	border  = Color3.fromRGB(30,  45,  66),
	muted   = Color3.fromRGB(100, 116, 139),
	gold    = Color3.fromRGB(245, 158, 11),
	text    = Color3.fromRGB(226, 232, 240),
	black   = Color3.fromRGB(0,   0,   0),
	danger  = Color3.fromRGB(239, 68,  68),
}

local STATUS_COLORS = { completado=C.gold, disponible=C.accent3, bloqueado=C.muted }
local STATUS_TEXTS  = { completado="◆ COMPLETADO", disponible="◆ DISPONIBLE", bloqueado="🔒 BLOQUEADO" }

-- ── Tabla de niveles ───────────────────────────────────────────────────────
local LEVELS = {
	[0] = { id=0, name="Laboratorio de Grafos", emoji="🧪", tag="NIVEL 0 · FUNDAMENTOS",    algo="Grafos No Dirigidos", desc="Aprende los conceptos básicos de grafos no dirigidos.",         concepts={"Nodos","Aristas","Adyacencia"},        status="disponible", stars=0, score=0, aciertos=0, fallos=0, tiempo="—", intentos=0 },
	[1] = { id=1, name="La Red Desconectada",   emoji="🏙️", tag="NIVEL 1 · CONECTIVIDAD",   algo="Conectividad",        desc="La red urbana está fragmentada.",                              concepts={"Componentes","Conectividad","BFS"},    status="bloqueado",  stars=0, score=0, aciertos=0, fallos=0, tiempo="—", intentos=0 },
	[2] = { id=2, name="La Fábrica de Señales", emoji="🏭", tag="NIVEL 2 · ALGORITMOS",     algo="BFS · DFS",           desc="Recorre la fábrica usando BFS y DFS.",                         concepts={"BFS","DFS","Recorrido"},               status="bloqueado",  stars=0, score=0, aciertos=0, fallos=0, tiempo="—", intentos=0 },
	[3] = { id=3, name="El Puente Roto",        emoji="🌉", tag="NIVEL 3 · GRAFOS DIRIGIDOS",algo="Grafos Dirigidos",    desc="Los puentes de la ciudad tienen dirección.",                   concepts={"Dirigido","In-degree","Out-degree"},   status="bloqueado",  stars=0, score=0, aciertos=0, fallos=0, tiempo="—", intentos=0 },
	[4] = { id=4, name="Ruta Mínima",           emoji="🗺️", tag="NIVEL 4 · RUTAS ÓPTIMAS",  algo="Dijkstra",            desc="Encuentra el camino de menor costo con Dijkstra.",             concepts={"Dijkstra","Peso","Ruta mínima"},       status="bloqueado",  stars=0, score=0, aciertos=0, fallos=0, tiempo="—", intentos=0 },
}

-- ── Estado global ──────────────────────────────────────────────────────────
local selectedLevelID   = nil
local isLoading         = false
local loadStartTime     = 0
local currentDifficulty = "Normal"
local menuCameraActive  = false   -- true mientras la cámara está en modo menú

-- ════════════════════════════════════════════════════════════════════════════
-- CÁMARA — FIX PRINCIPAL
-- ════════════════════════════════════════════════════════════════════════════

local camera = workspace.CurrentCamera

-- Activa la cámara cinemática del menú SOLO si existe CamaraMenu en workspace.
-- Si no existe, deja la cámara en Custom para no bloquear al jugador.
local function setupMenuCamera()
	local camObj = workspace:FindFirstChild("CamaraMenu", true)
	if not camObj then
		-- Sin CamaraMenu: no tocar la cámara; el jugador mantiene control normal
		menuCameraActive = false
		return
	end

	local part = (camObj:IsA("BasePart") and camObj)
		or (camObj:IsA("Model") and camObj.PrimaryPart)
	if not part then
		menuCameraActive = false
		return
	end

	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame     = part.CFrame
	menuCameraActive  = true
	print("[MenuController] 🎥 Cámara del menú activada")
end

-- Restaura el control de cámara y movimiento al jugador.
-- DEBE llamarse ANTES de ocultar el menú al entrar a un nivel.
local function restoreGameCamera()
	if not menuCameraActive then return end

	-- Restaurar tipo de cámara a Custom (seguir al personaje)
	camera.CameraType = Enum.CameraType.Custom

	-- Vincular la cámara al personaje si ya existe
	local char = player.Character
	if char then
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			-- CameraSubject debe ser el Humanoid para que funcione el follow-cam
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if humanoid then
				camera.CameraSubject = humanoid
			end
		end
	end

	menuCameraActive = false
	print("[MenuController] 🎥 Cámara restaurada al jugador")
end

-- También restaurar cámara cuando el personaje aparezca/reaparezca
-- (cubre el caso en que el personaje se crea después de LevelReady)
player.CharacterAdded:Connect(function(char)
	if not menuCameraActive then
		-- El menú no está activo: asegurar que la cámara siga al nuevo personaje
		task.wait()  -- esperar un frame para que el personaje esté listo
		local humanoid = char:WaitForChild("Humanoid", 5)
		if humanoid then
			camera.CameraType    = Enum.CameraType.Custom
			camera.CameraSubject = humanoid
		end
	end
end)

-- ── Helpers ────────────────────────────────────────────────────────────────
local function formatTime(seconds)
	if not seconds or seconds == 0 then return "—" end
	return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function tween(obj, props, t, style)
	local ti = TweenInfo.new(t or 0.15, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tw = TweenService:Create(obj, ti, props)
	tw:Play()
	return tw
end

-- ── Pantalla de transición ─────────────────────────────────────────────────
local transOverlay = Instance.new("Frame")
transOverlay.Name                  = "TransitionOverlay"
transOverlay.Size                  = UDim2.new(1, 0, 1, 0)
transOverlay.BackgroundColor3      = Color3.new(0, 0, 0)
transOverlay.BackgroundTransparency = 1
transOverlay.BorderSizePixel       = 0
transOverlay.ZIndex                = 200
transOverlay.Visible               = false
transOverlay.Parent                = root

local loadingLbl = Instance.new("TextLabel")
loadingLbl.Size               = UDim2.new(0.6, 0, 0, 30)
loadingLbl.Position           = UDim2.new(0.2, 0, 0.5, -15)
loadingLbl.BackgroundTransparency = 1
loadingLbl.Text               = "Cargando..."
loadingLbl.TextColor3         = Color3.fromRGB(226, 232, 240)
loadingLbl.Font               = Enum.Font.RobotoMono
loadingLbl.TextSize           = 14
loadingLbl.TextXAlignment     = Enum.TextXAlignment.Center
loadingLbl.ZIndex             = 201
loadingLbl.Parent             = transOverlay

local function fadeIn(duration, onDone)
	transOverlay.BackgroundTransparency = 1
	transOverlay.Visible = true
	local tw = tween(transOverlay, {BackgroundTransparency = 0}, duration or 0.35, Enum.EasingStyle.Linear)
	if onDone then tw.Completed:Connect(onDone) end
end

local function fadeOut(duration, onDone)
	local tw = tween(transOverlay, {BackgroundTransparency = 1}, duration or 0.35, Enum.EasingStyle.Linear)
	tw.Completed:Connect(function()
		transOverlay.Visible = false
		if onDone then onDone() end
	end)
end

-- ════════════════════════════════════════════════════════════════════════════
-- PROGRESO DEL SERVIDOR
-- ════════════════════════════════════════════════════════════════════════════

local function updateProgressBar()
	local completed, total = 0, 0
	for id = 0, 4 do
		total = total + 1
		if LEVELS[id] and LEVELS[id].status == "completado" then completed = completed + 1 end
	end
	local pct = total > 0 and (completed / total) or 0
	local progCount = S2:FindFirstChild("ProgCount", true)
	local progFill  = S2:FindFirstChild("ProgFill",  true)
	local progPct   = S2:FindFirstChild("ProgPct",   true)
	if progCount then progCount.Text = completed .. " / " .. total end
	if progFill  then tween(progFill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.4) end
	if progPct   then progPct.Text = math.floor(pct * 100) .. "%" end
end

local function updateCardVisuals(card, lv)
	if not card or not lv then return end
	local sc = STATUS_COLORS[lv.status] or C.muted
	local cardStroke = card:FindFirstChildOfClass("UIStroke")
	if cardStroke then cardStroke.Color = lv.status == "completado" and C.gold or C.border end
	local badge = card:FindFirstChild("StatusBadge")
	if badge then
		badge.BackgroundColor3 = sc
		local bs = badge:FindFirstChildOfClass("UIStroke"); if bs then bs.Color = sc end
		local txt = badge:FindFirstChild("StatusText")
		if txt then txt.Text = STATUS_TEXTS[lv.status] or "—"; txt.TextColor3 = sc end
	end
	local footer = card:FindFirstChild("CardFooter")
	if footer then
		local starsLbl = footer:FindFirstChild("CardStars")
		local scoreLbl = footer:FindFirstChild("CardScore")
		if starsLbl then
			local ss = ""
			for i = 1, 3 do ss = ss .. (i <= lv.stars and "★" or "☆") end
			starsLbl.Text = ss
		end
		if scoreLbl then scoreLbl.Text = lv.score > 0 and (lv.score .. " pts") or "—" end
	end
	local lockOv = card:FindFirstChild("LockOverlay")
	if lockOv then lockOv.Visible = lv.status == "bloqueado" end
end

local function loadProgress()
	if not getProgressFn then return end
	local ok, progress = pcall(function() return getProgressFn:InvokeServer() end)
	if not ok or type(progress) ~= "table" then
		warn("[MenuController] ⚠ No se pudo obtener progreso:", tostring(progress))
		return
	end
	for id = 0, 4 do
		local p = progress[id]
		if p and LEVELS[id] then
			LEVELS[id].status   = p.status   or LEVELS[id].status
			LEVELS[id].stars    = p.estrellas or 0
			LEVELS[id].score    = p.highScore  or 0
			LEVELS[id].aciertos = p.aciertos   or 0
			LEVELS[id].fallos   = p.fallos     or 0
			LEVELS[id].tiempo   = formatTime(p.tiempoMejor)
			LEVELS[id].intentos = p.intentos   or 0
		end
	end
	local gridArea = S2:FindFirstChild("GridArea", true)
	if gridArea then
		for id = 0, 4 do
			local card = gridArea:FindFirstChild("Card" .. id, true)
			if card and LEVELS[id] then updateCardVisuals(card, LEVELS[id]) end
		end
	end
	updateProgressBar()
	print("[MenuController] ✅ Progreso actualizado")
end

-- ════════════════════════════════════════════════════════════════════════════
-- NAVEGACIÓN
-- ════════════════════════════════════════════════════════════════════════════

local function resetSidebar()
	local placeholder = S2:FindFirstChild("Placeholder", true)
	local infoContent = S2:FindFirstChild("InfoContent", true)
	if placeholder then placeholder.Visible = true  end
	if infoContent then infoContent.Visible = false end
	local playBtn = S2:FindFirstChild("PlayButton", true)
	if playBtn then
		playBtn.Text             = "🔒  SELECCIONA UN NIVEL"
		playBtn.TextColor3       = C.muted
		playBtn.BackgroundColor3 = C.panel
		local stroke = playBtn:FindFirstChildOfClass("UIStroke")
		if stroke then stroke.Color = C.border end
	end
end

local function showMenu()
	root.Enabled = true
	S1.Visible   = true
	S2.Visible   = false
	S3.Visible   = false
	S4.Visible   = false
	S5.Visible   = false
	setupMenuCamera()
end

local function goToMenu()
	S1.Visible = true
	S2.Visible = false
	selectedLevelID = nil
	setupMenuCamera()
end

local function goToLevels()
	S1.Visible = false
	S2.Visible = true
	resetSidebar()
	selectedLevelID = nil
	local gridArea = S2:FindFirstChild("GridArea", true)
	if gridArea then
		for id = 0, 4 do
			local card = gridArea:FindFirstChild("Card" .. id, true)
			if card then
				local st = card:FindFirstChildOfClass("UIStroke")
				local lv = LEVELS[id]
				if st and lv then st.Color = lv.status == "completado" and C.gold or C.border; st.Thickness = 1 end
			end
		end
	end
	task.spawn(loadProgress)
end

local function openModal(frame)  frame.Visible = true  end
local function closeModal(frame) frame.Visible = false end

-- ════════════════════════════════════════════════════════════════════════════
-- MENÚ PRINCIPAL (S1)
-- ════════════════════════════════════════════════════════════════════════════

local menuPanel   = S1:FindFirstChild("MenuPanel")
local BtnPlay     = menuPanel and menuPanel:FindFirstChild("BtnPlay")
local BtnSettings = menuPanel and menuPanel:FindFirstChild("BtnSettings")
local BtnCredits  = menuPanel and menuPanel:FindFirstChild("BtnCredits")
local BtnExit     = menuPanel and menuPanel:FindFirstChild("BtnExit")

if BtnPlay     then BtnPlay.MouseButton1Click:Connect(goToLevels)                         end
if BtnSettings then BtnSettings.MouseButton1Click:Connect(function() openModal(S3) end)  end
if BtnCredits  then BtnCredits.MouseButton1Click:Connect(function() openModal(S4) end)   end
if BtnExit     then BtnExit.MouseButton1Click:Connect(function() openModal(S5) end)      end

local function addHover(btn, hoverBg, normalBg)
	if not btn then return end
	btn.MouseEnter:Connect(function() tween(btn, {BackgroundColor3 = hoverBg},  0.1) end)
	btn.MouseLeave:Connect(function() tween(btn, {BackgroundColor3 = normalBg}, 0.1) end)
end
if BtnSettings then addHover(BtnSettings, Color3.fromRGB(24,34,52), Color3.fromRGB(8,14,24)) end
if BtnCredits  then addHover(BtnCredits,  Color3.fromRGB(24,34,52), Color3.fromRGB(8,14,24)) end
if BtnExit     then addHover(BtnExit,     Color3.fromRGB(40,10,10), Color3.fromRGB(8,14,24)) end

-- ════════════════════════════════════════════════════════════════════════════
-- SELECTOR DE NIVELES (S2)
-- ════════════════════════════════════════════════════════════════════════════

local backBtn = S2:FindFirstChild("BackBtn", true)
if backBtn then backBtn.MouseButton1Click:Connect(goToMenu) end

local function updateSidebar(lv)
	local placeholder = S2:FindFirstChild("Placeholder", true)
	local infoContent = S2:FindFirstChild("InfoContent", true)
	if not infoContent then return end
	if placeholder then placeholder.Visible = false end
	infoContent.Visible = true

	local hero         = infoContent:FindFirstChild("Hero")
	local heroEmoji    = hero and hero:FindFirstChild("HeroEmoji")
	local heroBadge    = hero and hero:FindFirstChild("HeroBadge")
	local heroBadgeTxt = heroBadge and heroBadge:FindFirstChild("HeroBadgeText")
	local heroGlow     = hero and hero:FindFirstChild("HeroGlow")
	if heroEmoji then heroEmoji.Text = lv.emoji end
	local sc      = STATUS_COLORS[lv.status] or C.muted
	local bgColor = lv.status == "completado" and Color3.fromRGB(26,18,4)
		or lv.status == "disponible" and Color3.fromRGB(4,26,18) or Color3.fromRGB(14,14,20)
	if heroBadge    then heroBadge.BackgroundColor3 = bgColor; local stk = heroBadge:FindFirstChildOfClass("UIStroke"); if stk then stk.Color = sc end end
	if heroBadgeTxt then heroBadgeTxt.Text = STATUS_TEXTS[lv.status] or "—"; heroBadgeTxt.TextColor3 = sc end
	if heroGlow     then tween(heroGlow, {BackgroundColor3 = sc}, 0.2) end

	local infoBody = infoContent:FindFirstChild("InfoBody")
	if not infoBody then return end
	local infoTag = infoBody:FindFirstChild("InfoTag"); if infoTag then infoTag.Text = lv.tag end
	local infoName= infoBody:FindFirstChild("InfoName"); if infoName then infoName.Text= lv.name end
	local infoDesc= infoBody:FindFirstChild("InfoDesc"); if infoDesc then infoDesc.Text= lv.desc end

	local starsFrame = infoBody:FindFirstChild("Stars")
	if starsFrame then
		for i = 1, 3 do
			local star = starsFrame:FindFirstChild("Star" .. i)
			if star then star.TextTransparency = i <= lv.stars and 0 or 0.7 end
		end
	end

	local statsGrid = infoBody:FindFirstChild("StatsGrid")
	if statsGrid then
		local function setVal(n, v) local b=statsGrid:FindFirstChild(n); local l=b and b:FindFirstChild("Val"); if l then l.Text=tostring(v) end end
		setVal("StatScore",  lv.score    > 0 and (lv.score.." pts") or "—")
		setVal("StatStatus", lv.status=="completado" and "✓ Completado" or lv.status=="disponible" and "Disponible" or "🔒 Bloqueado")
		setVal("StatAciert", lv.aciertos > 0 and tostring(lv.aciertos) or "—")
		setVal("StatFallos", lv.fallos   > 0 and tostring(lv.fallos)   or "—")
		setVal("StatTiempo", lv.tiempo  ~= "—" and lv.tiempo           or "—")
		setVal("StatInten",  lv.intentos > 0 and tostring(lv.intentos) or "—")
	end

	local tagsFrame = infoBody:FindFirstChild("Tags")
	if tagsFrame then
		for _, child in ipairs(tagsFrame:GetChildren()) do
			if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
		end
		for _, concept in ipairs(lv.concepts or {}) do
			local tb = Instance.new("TextButton")
			tb.Size=UDim2.new(0,0,0,22); tb.AutomaticSize=Enum.AutomaticSize.X
			tb.BackgroundColor3=Color3.fromRGB(0,20,30); tb.Text=concept
			tb.TextColor3=Color3.fromRGB(0,138,170); tb.Font=Enum.Font.RobotoMono
			tb.TextSize=9; tb.BorderSizePixel=0; tb.Parent=tagsFrame
			local co=Instance.new("UICorner"); co.CornerRadius=UDim.new(0,3); co.Parent=tb
			local sk=Instance.new("UIStroke"); sk.Color=Color3.fromRGB(0,62,90); sk.Thickness=1; sk.Parent=tb
			local pd=Instance.new("UIPadding"); pd.PaddingTop=UDim.new(0,3); pd.PaddingBottom=UDim.new(0,3); pd.PaddingLeft=UDim.new(0,8); pd.PaddingRight=UDim.new(0,8); pd.Parent=tb
		end
	end

	local playBtn = S2:FindFirstChild("PlayButton", true)
	if playBtn then
		if lv.status == "bloqueado" then
			playBtn.Text="🔒  NIVEL BLOQUEADO"; playBtn.TextColor3=C.muted; playBtn.BackgroundColor3=C.panel
			local stk=playBtn:FindFirstChildOfClass("UIStroke"); if stk then stk.Color=C.border end
		else
			local icon = lv.status == "completado" and "↺  REINTENTAR: " or "▶  JUGAR: "
			playBtn.Text=icon..lv.name:upper(); playBtn.TextColor3=C.black; playBtn.BackgroundColor3=C.accent3
			local stk=playBtn:FindFirstChildOfClass("UIStroke"); if stk then stk.Color=C.accent3 end
		end
	end
end

local function connectLevelCards()
	local gridArea = S2:FindFirstChild("GridArea", true)
	if not gridArea then warn("[MenuController] ❌ GridArea no encontrado"); return end
	local count = 0
	for id = 0, 4 do
		local card = gridArea:FindFirstChild("Card" .. id, true)
		if card and card:IsA("TextButton") and LEVELS[id] then
			count += 1
			card.MouseButton1Click:Connect(function()
				if isLoading then return end
				selectedLevelID = id
				updateSidebar(LEVELS[id])
				for i = 0, 4 do
					local c = gridArea:FindFirstChild("Card" .. i, true)
					if c then
						local st = c:FindFirstChildOfClass("UIStroke")
						if st then
							st.Color     = i == id and C.accent or (LEVELS[i] and LEVELS[i].status == "completado" and C.gold or C.border)
							st.Thickness = i == id and 2 or 1
						end
					end
				end
			end)
		end
	end
	print("[MenuController] Tarjetas conectadas:", count, "/ 5")
end
connectLevelCards()

local playBtnSidebar = S2:FindFirstChild("PlayButton", true)
if playBtnSidebar then
	playBtnSidebar.MouseButton1Click:Connect(function()
		if isLoading then return end
		if selectedLevelID == nil then return end
		local lv = LEVELS[selectedLevelID]
		if not lv or lv.status == "bloqueado" then return end

		isLoading     = true
		local thisLoad = os.clock()
		loadStartTime  = thisLoad
		loadingLbl.Text = "Cargando  " .. lv.name .. "..."

		fadeIn(0.4, function()
			if requestPlayLEv then
				requestPlayLEv:FireServer(selectedLevelID)
				-- Watchdog
				task.spawn(function()
					task.wait(10)
					if isLoading and loadStartTime == thisLoad then
						warn("[MenuController] ⏱ Timeout — LevelReady no llegó en 10s")
						loadingLbl.Text = "⏱ Sin respuesta del servidor"
						task.delay(1.5, function()
							if isLoading and loadStartTime == thisLoad then
								isLoading = false
								-- Restaurar cámara incluso en timeout
								restoreGameCamera()
								fadeOut(0.35, function() goToLevels() end)
							end
						end)
					end
				end)
			else
				warn("[MenuController] requestPlayLEv no disponible")
				task.delay(1.5, function()
					restoreGameCamera()
					fadeOut(0.4, function() root.Enabled = false; isLoading = false end)
				end)
			end
		end)
	end)
end

-- ════════════════════════════════════════════════════════════════════════════
-- AJUSTES (S3)
-- ════════════════════════════════════════════════════════════════════════════

local function closeSettings() closeModal(S3) end
do
	local closeBtn  = S3:FindFirstChild("CloseBtn",  true)
	local cancelBtn = S3:FindFirstChild("CancelBtn", true)
	local saveBtn   = S3:FindFirstChild("SaveBtn",   true)
	if closeBtn  then closeBtn.MouseButton1Click:Connect(closeSettings)  end
	if cancelBtn then cancelBtn.MouseButton1Click:Connect(closeSettings) end
	if saveBtn   then saveBtn.MouseButton1Click:Connect(closeSettings)   end
end

local function connectSlider(sliderRow, onChange)
	if not sliderRow then return end
	local track = sliderRow:FindFirstChild("Track") or sliderRow:FindFirstChild("Track", true)
	if not track then warn("[MenuController] Slider '" .. sliderRow.Name .. "' sin Track"); return end
	local fill = track:FindFirstChild("Fill")
	if not fill then warn("[MenuController] Slider '" .. sliderRow.Name .. "' sin Fill"); return end
	local pct = sliderRow:FindFirstChild("Pct")
	local dragging = false

	local function updateFromScreenX(screenX)
		local sz = track.AbsoluteSize.X
		if sz == 0 then return end
		local v = math.clamp((screenX - track.AbsolutePosition.X) / sz, 0, 1)
		fill.Size = UDim2.new(v, 0, 1, 0)
		if pct then pct.Text = math.floor(v * 100) .. "%" end
		if onChange then onChange(v) end
	end

	track.MouseButton1Down:Connect(function(relX) dragging = true; updateFromScreenX(track.AbsolutePosition.X + relX) end)
	UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
	UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then updateFromScreenX(i.Position.X) end end)
end

connectSlider(S3:FindFirstChild("AmbientSlider", true), function(_v) end)
connectSlider(S3:FindFirstChild("SFXSlider",     true), function(_v) end)

local function connectDifficultyRows()
	local sScroll = S3:FindFirstChildOfClass("ScrollingFrame", true)
	if not sScroll then return end
	local diffRows = {}
	for _, child in ipairs(sScroll:GetDescendants()) do
		if child:IsA("Frame") and child.Size.Y.Offset == 48 then
			for _, c2 in ipairs(child:GetChildren()) do
				if c2:IsA("Frame") and c2.Size.X.Offset == 12 then table.insert(diffRows, child); break end
			end
		end
	end
	if #diffRows == 0 then return end
	local diffNames = {"Normal","Difícil","Experto"}
	local function selectDiff(idx)
		currentDifficulty = diffNames[idx] or "Normal"
		for i, row in ipairs(diffRows) do
			local sel = i == idx
			local dot = nil
			for _, c in ipairs(row:GetChildren()) do if c:IsA("Frame") and c.Size.X.Offset == 12 then dot = c; break end end
			local rs = row:FindFirstChildOfClass("UIStroke"); if rs then rs.Color = sel and C.accent or C.border end
			if dot then tween(dot, {BackgroundColor3 = sel and C.accent or C.panel}, 0.15); local ds=dot:FindFirstChildOfClass("UIStroke"); if ds then ds.Color=sel and C.accent or C.border end end
			for _, lbl in ipairs(row:GetChildren()) do if lbl:IsA("TextLabel") and lbl.TextSize==12 then tween(lbl, {TextColor3 = sel and C.text or C.muted}, 0.15) end end
		end
	end
	for i, row in ipairs(diffRows) do
		local btn=Instance.new("TextButton"); btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""; btn.BorderSizePixel=0; btn.ZIndex=row.ZIndex+5; btn.Parent=row
		local idx=i; btn.MouseButton1Click:Connect(function() selectDiff(idx) end)
	end
end
connectDifficultyRows()

-- ════════════════════════════════════════════════════════════════════════════
-- CRÉDITOS (S4)
-- ════════════════════════════════════════════════════════════════════════════

do
	local cb=S4:FindFirstChild("CloseBtn",true); local ok=S4:FindFirstChild("OkBtn",true)
	if cb then cb.MouseButton1Click:Connect(function() closeModal(S4) end) end
	if ok then ok.MouseButton1Click:Connect(function() closeModal(S4) end) end
end

-- ════════════════════════════════════════════════════════════════════════════
-- SALIR (S5)
-- ════════════════════════════════════════════════════════════════════════════

do
	local cb=S5:FindFirstChild("CloseBtn",true); local cancel=S5:FindFirstChild("CancelBtn",true); local confirm=S5:FindFirstChild("ConfirmBtn",true)
	if cb      then cb.MouseButton1Click:Connect(function()      closeModal(S5) end) end
	if cancel  then cancel.MouseButton1Click:Connect(function()  closeModal(S5) end) end
	if confirm then confirm.MouseButton1Click:Connect(function() player:Kick("¡Hasta pronto! Gracias por jugar EDA Quest.") end) end
end

-- ════════════════════════════════════════════════════════════════════════════
-- RESPUESTA DEL SERVIDOR: LevelReady — FIX DE CÁMARA AQUÍ
-- ════════════════════════════════════════════════════════════════════════════

if levelReadyEv then
	levelReadyEv.OnClientEvent:Connect(function(data)
		if data and data.error then
			loadingLbl.Text = "❌ " .. data.error
			task.delay(2.5, function()
				restoreGameCamera()  -- restaurar incluso en error
				fadeOut(0.4, function()
					isLoading = false
					goToLevels()
				end)
			end)
			return
		end

		-- Nivel cargado OK
		loadingLbl.Text = "✅  " .. (data and data.nombre or "Nivel " .. tostring(data and data.nivelID or "?"))

		task.delay(0.6, function()
			-- ══ PASO 1: Restaurar cámara y control del jugador ══
			-- Esto DEBE ocurrir antes de ocultar el menú para que
			-- Roblox tenga un frame con CameraType=Custom antes de
			-- que el ScreenGui desaparezca.
			restoreGameCamera()

			-- ══ PASO 2: Fade out y ocultar menú ══
			fadeOut(0.4, function()
				root.Enabled = false
				isLoading    = false
				print("[MenuController] ✅ Nivel", data and data.nivelID, "— menú ocultado, cámara restaurada")
			end)
		end)
	end)
end

-- ════════════════════════════════════════════════════════════════════════════
-- ReturnToMenu (desde el nivel de vuelta al menú)
-- ════════════════════════════════════════════════════════════════════════════

-- Escuchar si el servidor señala que el nivel fue descargado
local levelUnloadedEv = remotesFolder and remotesFolder:FindFirstChild("LevelUnloaded")
if levelUnloadedEv then
	levelUnloadedEv.OnClientEvent:Connect(function()
		showMenu()
		print("[MenuController] 🏠 Volviendo al menú")
	end)
end

-- ════════════════════════════════════════════════════════════════════════════
-- ServerReady
-- ════════════════════════════════════════════════════════════════════════════

if serverReadyEv then
	serverReadyEv.OnClientEvent:Connect(function()
		print("[MenuController] ServerReady recibido")
		task.spawn(loadProgress)
	end)
end

-- Inicializar cámara del menú al cargar
setupMenuCamera()

print("[EDA v2] ✅ MenuController v2.2 activo — cámara y control de personaje corregidos")