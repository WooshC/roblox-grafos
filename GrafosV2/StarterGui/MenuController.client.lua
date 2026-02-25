-- MenuController.client.lua
-- Controla TODA la interactividad del menú EDA Quest v2:
--   · Navegación entre frames (Menú → Selector de Niveles → Modales)
--   · Tarjetas de nivel: selección + actualización del sidebar
--   · Botón JUGAR: transición con fade → solicita carga al servidor
--   · Sliders de volumen: drag funcional
--   · Modales: Ajustes, Créditos, Confirmación de Salir
--
-- Ubicación Roblox: StarterGui/MenuController.client.lua  (LocalScript)

local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RS             = game:GetService("ReplicatedStorage")
local SoundService   = game:GetService("SoundService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ── Esperar la GUI (creada por crearGUIMenu.lua) ───────────────────────────
local root = playerGui:WaitForChild("EDAQuestMenu", 30)
if not root then
	warn("[MenuController] ❌ EDAQuestMenu no encontrado en PlayerGui.")
	return
end

-- ── Conectar con eventos del servidor ─────────────────────────────────────
local eventsFolder   = RS:WaitForChild("EDAEvents", 10)
local remotesFolder  = eventsFolder and eventsFolder:WaitForChild("Remotes", 5)

local serverReadyEv    = remotesFolder and remotesFolder:FindFirstChild("ServerReady")
local requestPlayLEv   = remotesFolder and remotesFolder:FindFirstChild("RequestPlayLevel")
local levelReadyEv     = remotesFolder and remotesFolder:FindFirstChild("LevelReady")
local returnToMenuEv   = remotesFolder and remotesFolder:FindFirstChild("ReturnToMenu")

-- ── Referencias a frames ───────────────────────────────────────────────────
local S1 = root:WaitForChild("FrameMenu")
local S2 = root:WaitForChild("FrameLevels")
local S3 = root:WaitForChild("FrameSettings")
local S4 = root:WaitForChild("FrameCredits")
local S5 = root:WaitForChild("FrameExit")

-- ── Datos de niveles (espejo de crearGUIMenu.lua) ─────────────────────────
-- En Fase 2 estos datos vendrán del servidor via GetPlayerProgress.
local LEVELS = {
	[0] = {
		id = 0, name = "Laboratorio de Grafos", emoji = "🧪",
		tag  = "NIVEL 0 · FUNDAMENTOS",
		algo = "Grafos No Dirigidos",
		desc = "Aprende los conceptos básicos de grafos no dirigidos. Conecta los postes de la estación para establecer la red de energía.",
		concepts = {"Nodos", "Aristas", "Adyacencia"},
		status = "completado", stars = 3, score = 1480,
		aciertos = 12, fallos = 2, tiempo = "4:32", intentos = 3,
	},
	[1] = {
		id = 1, name = "La Red Desconectada", emoji = "🏙️",
		tag  = "NIVEL 1 · CONECTIVIDAD",
		algo = "Conectividad",
		desc = "La red urbana está fragmentada. Identifica los componentes y conéctalos para restaurar el servicio.",
		concepts = {"Componentes", "Conectividad", "BFS"},
		status = "completado", stars = 2, score = 960,
		aciertos = 8, fallos = 5, tiempo = "6:18", intentos = 4,
	},
	[2] = {
		id = 2, name = "La Fábrica de Señales", emoji = "🏭",
		tag  = "NIVEL 2 · ALGORITMOS",
		algo = "BFS · DFS",
		desc = "Recorre la fábrica usando BFS y DFS para activar todos los nodos de producción en el orden correcto.",
		concepts = {"BFS", "DFS", "Recorrido"},
		status = "disponible", stars = 0, score = 0,
		aciertos = 0, fallos = 0, tiempo = "—", intentos = 0,
	},
	[3] = {
		id = 3, name = "El Puente Roto", emoji = "🌉",
		tag  = "NIVEL 3 · GRAFOS DIRIGIDOS",
		algo = "Grafos Dirigidos",
		desc = "Los puentes de la ciudad tienen dirección. Planea las rutas de reparación usando grafos dirigidos.",
		concepts = {"Dirigido", "In-degree", "Out-degree"},
		status = "bloqueado", stars = 0, score = 0,
		aciertos = 0, fallos = 0, tiempo = "—", intentos = 0,
	},
	[4] = {
		id = 4, name = "Ruta Mínima", emoji = "🗺️",
		tag  = "NIVEL 4 · RUTAS ÓPTIMAS",
		algo = "Dijkstra",
		desc = "Encuentra el camino de menor costo para conectar la red usando el algoritmo de Dijkstra.",
		concepts = {"Dijkstra", "Peso", "Ruta mínima"},
		status = "bloqueado", stars = 0, score = 0,
		aciertos = 0, fallos = 0, tiempo = "—", intentos = 0,
	},
}

local STATUS_COLORS = {
	completado = Color3.fromRGB(245, 158, 11),
	disponible = Color3.fromRGB(16,  185, 129),
	bloqueado  = Color3.fromRGB(100, 116, 139),
}
local STATUS_TEXTS = {
	completado = "◆ COMPLETADO",
	disponible = "◆ DISPONIBLE",
	bloqueado  = "🔒 BLOQUEADO",
}

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

-- ── Estado global ──────────────────────────────────────────────────────────
local selectedLevelID   = nil
local isLoading         = false
local currentDifficulty = "Normal"  -- Normal / Difícil / Experto

-- ── Utilidades de animación ────────────────────────────────────────────────
local function tween(obj, props, t, style)
	local ti = TweenInfo.new(t or 0.15, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tw = TweenService:Create(obj, ti, props)
	tw:Play()
	return tw
end

-- ── Pantalla de transición (fade negro sobre todo) ─────────────────────────
local transOverlay = Instance.new("Frame")
transOverlay.Name            = "TransitionOverlay"
transOverlay.Size            = UDim2.new(1, 0, 1, 0)
transOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
transOverlay.BackgroundTransparency = 1
transOverlay.BorderSizePixel = 0
transOverlay.ZIndex          = 200
transOverlay.Visible         = false
transOverlay.Parent          = root

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
-- NAVEGACIÓN
-- ════════════════════════════════════════════════════════════════════════════

local function resetSidebar()
	local placeholder  = S2:FindFirstChild("Placeholder",  true)
	local infoContent  = S2:FindFirstChild("InfoContent",  true)
	if placeholder then placeholder.Visible = true end
	if infoContent then infoContent.Visible = false end

	local playBtn = S2:FindFirstChild("PlayButton", true)
	if playBtn then
		playBtn.Text       = "🔒  SELECCIONA UN NIVEL"
		playBtn.TextColor3 = C.muted
		playBtn.BackgroundColor3 = C.panel
		local stroke = playBtn:FindFirstChildOfClass("UIStroke")
		if stroke then stroke.Color = C.border end
	end
end

local function goToMenu()
	S1.Visible = true
	S2.Visible = false
	selectedLevelID = nil
end

local function goToLevels()
	S1.Visible = false
	S2.Visible = true
	resetSidebar()
	selectedLevelID = nil
	-- Highlight: desmarcar todas las tarjetas
	local gridArea = S2:FindFirstChild("GridArea", true)  -- búsqueda recursiva: GridArea está dentro de lsMain
	if gridArea then
		for id = 0, 4 do
			local card = gridArea:FindFirstChild("Card"..id, true)
			if card then
				local st = card:FindFirstChildOfClass("UIStroke")
				local lv = LEVELS[id]
				if st and lv then
					st.Color     = lv.status == "completado" and C.gold or C.border
					st.Thickness = 1
				end
			end
		end
	end
end

-- Modales son overlays (no ocultan el frame de fondo)
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

-- Hover visual (oscurecer/aclarar el fondo del botón)
local function addHover(btn, hoverBg, normalBg)
	if not btn then return end
	btn.MouseEnter:Connect(function()
		tween(btn, {BackgroundColor3 = hoverBg}, 0.1)
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, {BackgroundColor3 = normalBg}, 0.1)
	end)
end
if BtnSettings then addHover(BtnSettings, Color3.fromRGB(24, 34, 52), Color3.fromRGB(8, 14, 24)) end
if BtnCredits  then addHover(BtnCredits,  Color3.fromRGB(24, 34, 52), Color3.fromRGB(8, 14, 24)) end
if BtnExit     then addHover(BtnExit,     Color3.fromRGB(40, 10, 10), Color3.fromRGB(8, 14, 24)) end

-- ════════════════════════════════════════════════════════════════════════════
-- SELECTOR DE NIVELES (S2)
-- ════════════════════════════════════════════════════════════════════════════

local backBtn = S2:FindFirstChild("BackBtn", true)
if backBtn then backBtn.MouseButton1Click:Connect(goToMenu) end

-- Actualiza el sidebar con los datos del nivel seleccionado
local function updateSidebar(lv)
	local placeholder = S2:FindFirstChild("Placeholder",  true)
	local infoContent = S2:FindFirstChild("InfoContent",  true)
	if not infoContent then return end

	placeholder.Visible = false
	infoContent.Visible = true

	-- Hero (emoji + badge de estado)
	local hero         = infoContent:FindFirstChild("Hero")
	local heroEmoji    = hero and hero:FindFirstChild("HeroEmoji")
	local heroBadge    = hero and hero:FindFirstChild("HeroBadge")
	local heroBadgeTxt = heroBadge and heroBadge:FindFirstChild("HeroBadgeText")
	local heroGlow     = hero and hero:FindFirstChild("HeroGlow") -- puede no existir

	if heroEmoji    then heroEmoji.Text = lv.emoji end

	local sc = STATUS_COLORS[lv.status] or C.muted
	local bgColor = lv.status == "completado" and Color3.fromRGB(26,18,4)
		or lv.status == "disponible"  and Color3.fromRGB(4,26,18)
		or Color3.fromRGB(14,14,20)

	if heroBadge then
		heroBadge.BackgroundColor3 = bgColor
		local stk = heroBadge:FindFirstChildOfClass("UIStroke")
		if stk then stk.Color = sc end
	end
	if heroBadgeTxt then
		heroBadgeTxt.Text      = STATUS_TEXTS[lv.status] or "—"
		heroBadgeTxt.TextColor3 = sc
	end
	if heroGlow then
		tween(heroGlow, {BackgroundColor3 = sc}, 0.2)
	end

	-- Info body
	local infoBody = infoContent:FindFirstChild("InfoBody")
	if not infoBody then return end

	local infoTag  = infoBody:FindFirstChild("InfoTag")
	local infoName = infoBody:FindFirstChild("InfoName")
	local infoDesc = infoBody:FindFirstChild("InfoDesc")

	if infoTag  then infoTag.Text  = lv.tag  end
	if infoName then infoName.Text = lv.name end
	if infoDesc then infoDesc.Text = lv.desc end

	-- Estrellas
	local starsFrame = infoBody:FindFirstChild("Stars")
	if starsFrame then
		for i = 1, 3 do
			local star = starsFrame:FindFirstChild("Star"..i)
			if star then star.TextTransparency = i <= lv.stars and 0 or 0.7 end
		end
	end

	-- Stats
	local statsGrid = infoBody:FindFirstChild("StatsGrid")
	if statsGrid then
		local function setVal(statName, val)
			local box = statsGrid:FindFirstChild(statName)
			local lbl = box and box:FindFirstChild("Val")
			if lbl then lbl.Text = tostring(val) end
		end
		setVal("StatScore",  lv.score   > 0 and (lv.score .. " pts") or "—")
		setVal("StatStatus", lv.status == "completado" and "✓ Completado"
			or lv.status == "disponible"  and "Disponible"
			or "🔒 Bloqueado")
		setVal("StatAciert", lv.aciertos > 0 and tostring(lv.aciertos) or "—")
		setVal("StatFallos", lv.fallos   > 0 and tostring(lv.fallos)   or "—")
		setVal("StatTiempo", lv.tiempo  ~= "—" and tostring(lv.tiempo) or "—")
		setVal("StatInten",  lv.intentos > 0 and tostring(lv.intentos) or "—")
	end

	-- Tags de conceptos (rebuild)
	local tagsFrame = infoBody:FindFirstChild("Tags")
	if tagsFrame then
		for _, child in ipairs(tagsFrame:GetChildren()) do
			if child:IsA("TextButton") or child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		for _, concept in ipairs(lv.concepts or {}) do
			local tb = Instance.new("TextButton")
			tb.Size              = UDim2.new(0, 0, 0, 22)
			tb.AutomaticSize     = Enum.AutomaticSize.X
			tb.BackgroundColor3  = Color3.fromRGB(0, 20, 30)
			tb.Text              = concept
			tb.TextColor3        = Color3.fromRGB(0, 138, 170)
			tb.Font              = Enum.Font.RobotoMono
			tb.TextSize          = 9
			tb.BorderSizePixel   = 0
			tb.Parent            = tagsFrame
			local co = Instance.new("UICorner"); co.CornerRadius = UDim.new(0,3); co.Parent = tb
			local sk = Instance.new("UIStroke"); sk.Color = Color3.fromRGB(0,62,90); sk.Thickness = 1; sk.Parent = tb
			local pd = Instance.new("UIPadding")
			pd.PaddingTop = UDim.new(0,3); pd.PaddingBottom = UDim.new(0,3)
			pd.PaddingLeft = UDim.new(0,8); pd.PaddingRight = UDim.new(0,8)
			pd.Parent = tb
		end
	end

	-- Botón JUGAR
	local playBtn = S2:FindFirstChild("PlayButton", true)
	if playBtn then
		if lv.status == "bloqueado" then
			playBtn.Text             = "🔒  NIVEL BLOQUEADO"
			playBtn.TextColor3       = C.muted
			playBtn.BackgroundColor3 = C.panel
			local stk = playBtn:FindFirstChildOfClass("UIStroke")
			if stk then stk.Color = C.border end
		else
			local icon = lv.status == "completado" and "↺  REINTENTAR: " or "▶  JUGAR: "
			playBtn.Text             = icon .. lv.name:upper()
			playBtn.TextColor3       = C.black
			playBtn.BackgroundColor3 = C.accent3
			local stk = playBtn:FindFirstChildOfClass("UIStroke")
			if stk then stk.Color = C.accent3 end
		end
	end
end

-- Conectar tarjetas de nivel
local function connectLevelCards()
	local gridArea = S2:FindFirstChild("GridArea", true)  -- búsqueda recursiva: GridArea está dentro de lsMain
	if not gridArea then
		warn("[MenuController] ❌ GridArea no encontrado en FrameLevels")
		return
	end

	local cardsConnected = 0
	for id = 0, 4 do
		local card = gridArea:FindFirstChild("Card"..id, true)
		if card and card:IsA("TextButton") then
			local lvData = LEVELS[id]
			if lvData then
				cardsConnected += 1
				card.MouseButton1Click:Connect(function()
					if isLoading then return end
					selectedLevelID = id
					updateSidebar(lvData)

					-- Highlight: borde cyan en seleccionada, reset en las demás
					for i = 0, 4 do
						local c = gridArea:FindFirstChild("Card"..i, true)
						if c then
							local st = c:FindFirstChildOfClass("UIStroke")
							if st then
								if i == id then
									st.Color     = C.accent
									st.Thickness = 2
								else
									local lv = LEVELS[i]
									st.Color     = lv and lv.status == "completado" and C.gold or C.border
									st.Thickness = 1
								end
							end
						end
					end
				end)
			end
		end
	end
	print("[MenuController] Tarjetas conectadas:", cardsConnected, "/ 5")
end
connectLevelCards()

-- Botón JUGAR en el sidebar → solicitar carga al servidor
local playBtnSidebar = S2:FindFirstChild("PlayButton", true)
if playBtnSidebar then
	playBtnSidebar.MouseButton1Click:Connect(function()
		if isLoading then return end
		if selectedLevelID == nil then return end

		local lv = LEVELS[selectedLevelID]
		if not lv or lv.status == "bloqueado" then return end

		isLoading = true
		loadingLbl.Text = "Cargando  " .. lv.name .. "..."

		fadeIn(0.4, function()
			if requestPlayLEv then
				requestPlayLEv:FireServer(selectedLevelID)
			else
				-- Sin servidor (Studio en modo local sin server): simular carga
				warn("[MenuController] requestPlayLEv no disponible — modo sin servidor")
				task.delay(1.5, function()
					loadingLbl.Text = "✅ Modo sin servidor — nivel " .. selectedLevelID
					task.delay(1, function()
						fadeOut(0.4, function()
							root.Enabled = false
							isLoading = false
						end)
					end)
				end)
			end
		end)
	end)
end

-- ════════════════════════════════════════════════════════════════════════════
-- AJUSTES (S3)
-- ════════════════════════════════════════════════════════════════════════════

-- Cerrar modal
local function closeSettings()
	closeModal(S3)
end

do
	local closeBtn  = S3:FindFirstChild("CloseBtn",  true)
	local cancelBtn = S3:FindFirstChild("CancelBtn", true)
	local saveBtn   = S3:FindFirstChild("SaveBtn",   true)
	if closeBtn  then closeBtn.MouseButton1Click:Connect(closeSettings)  end
	if cancelBtn then cancelBtn.MouseButton1Click:Connect(closeSettings) end
	if saveBtn   then saveBtn.MouseButton1Click:Connect(closeSettings)   end
end

-- ── Sliders de volumen ─────────────────────────────────────────────────────
-- El slider funciona con MouseButton1Down en el Track + InputChanged global
local function connectSlider(sliderRow, onChange)
	if not sliderRow then
		warn("[MenuController] connectSlider: sliderRow es nil")
		return
	end
	local track = sliderRow:FindFirstChild("Track")
	local fill  = sliderRow:FindFirstChild("Fill")
	local pct   = sliderRow:FindFirstChild("Pct")

	if not track or not fill then
		warn("[MenuController] Slider '" .. sliderRow.Name .. "' sin Track/Fill. ¿crearGUIMenu actualizado?")
		return
	end

	local dragging = false

	local function updateFromScreenX(screenX)
		local trackAbsX    = track.AbsolutePosition.X
		local trackAbsSize = track.AbsoluteSize.X
		if trackAbsSize == 0 then return end

		local v = math.clamp((screenX - trackAbsX) / trackAbsSize, 0, 1)
		fill.Size = UDim2.new(v, 0, 1, 0)
		if pct then pct.Text = math.floor(v * 100) .. "%" end
		if onChange then onChange(v) end
		return v
	end

	-- MouseButton1Down da coordenadas relativas al botón → convertir a screen
	track.MouseButton1Down:Connect(function(relX, relY)
		dragging = true
		-- relX es relativo al botón; sumar posición absoluta del track
		updateFromScreenX(track.AbsolutePosition.X + relX)
	end)

	-- Input global para rastrear arrastre fuera del Track
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			updateFromScreenX(input.Position.X)
		end
	end)
end

-- Buscar los sliders (nombres agregados en crearGUIMenu.lua)
local ambientSlider = S3:FindFirstChild("AmbientSlider", true)
local sfxSlider     = S3:FindFirstChild("SFXSlider",     true)

connectSlider(ambientSlider, function(v)
	-- Aquí se puede ajustar volumen de música ambiente
	-- SoundService.AmbientReverb = ... o controlar instancias de sonido
	-- print("[Audio] Ambiente:", math.floor(v*100).."%")
end)

connectSlider(sfxSlider, function(v)
	-- Aquí se puede ajustar volumen de efectos
	-- print("[Audio] SFX:", math.floor(v*100).."%")
end)

-- ── Dificultad — radio buttons ─────────────────────────────────────────────
-- Buscar filas de dificultad dentro del scroll de ajustes
local function connectDifficultyRows()
	local sScroll = S3:FindFirstChildOfClass("ScrollingFrame", true)
	if not sScroll then return end

	-- Las filas de dificultad son los primeros 3 Frames hijos del contenedor dG.
	-- dG no tiene nombre, pero es el 2do hijo con LayoutOrder=2 del sScroll.
	-- Buscamos todos los frames de 48px alto que tengan un UIStroke y dots.
	local diffRows = {}
	for _, child in ipairs(sScroll:GetDescendants()) do
		if child:IsA("Frame") and child.Size.Y.Offset == 48 then
			-- Verificar que tiene el dot (frame circular de 12x12)
			for _, c2 in ipairs(child:GetChildren()) do
				if c2:IsA("Frame") and c2.Size.X.Offset == 12 then
					table.insert(diffRows, child)
					break
				end
			end
		end
	end

	if #diffRows == 0 then return end

	local diffNames = {"Normal", "Difícil", "Experto"}
	local accentColor   = Color3.fromRGB(0, 212, 255)
	local borderColor   = Color3.fromRGB(30, 45, 66)
	local textColor     = Color3.fromRGB(226, 232, 240)
	local mutedColor    = Color3.fromRGB(100, 116, 139)

	local function selectDiff(selectedIdx)
		currentDifficulty = diffNames[selectedIdx] or "Normal"
		for i, row in ipairs(diffRows) do
			local isSelected = (i == selectedIdx)
			local dot = nil
			for _, c in ipairs(row:GetChildren()) do
				if c:IsA("Frame") and c.Size.X.Offset == 12 then dot = c; break end
			end
			-- Update stroke color
			local rowStroke = row:FindFirstChildOfClass("UIStroke")
			if rowStroke then
				rowStroke.Color = isSelected and accentColor or borderColor
			end
			-- Update dot fill
			if dot then
				tween(dot, {BackgroundColor3 = isSelected and accentColor or C.panel}, 0.15)
				local dotStroke = dot:FindFirstChildOfClass("UIStroke")
				if dotStroke then dotStroke.Color = isSelected and accentColor or borderColor end
			end
			-- Update text colors
			for _, lbl in ipairs(row:GetChildren()) do
				if lbl:IsA("TextLabel") and lbl.TextSize == 12 then
					tween(lbl, {TextColor3 = isSelected and textColor or mutedColor}, 0.15)
				end
			end
		end
	end

	for i, row in ipairs(diffRows) do
		-- Hacer la fila clickeable
		local btn = Instance.new("TextButton")
		btn.Size                 = UDim2.new(1, 0, 1, 0)
		btn.BackgroundTransparency = 1
		btn.Text                 = ""
		btn.BorderSizePixel      = 0
		btn.ZIndex               = row.ZIndex + 5
		btn.Parent               = row
		local idx = i
		btn.MouseButton1Click:Connect(function()
			selectDiff(idx)
		end)
	end
end
connectDifficultyRows()

-- ════════════════════════════════════════════════════════════════════════════
-- CRÉDITOS (S4)
-- ════════════════════════════════════════════════════════════════════════════

do
	local closeBtn = S4:FindFirstChild("CloseBtn", true)
	local okBtn    = S4:FindFirstChild("OkBtn",    true)
	if closeBtn then closeBtn.MouseButton1Click:Connect(function() closeModal(S4) end) end
	if okBtn    then okBtn.MouseButton1Click:Connect(function()    closeModal(S4) end) end
end

-- ════════════════════════════════════════════════════════════════════════════
-- CONFIRMACIÓN SALIR (S5)
-- ════════════════════════════════════════════════════════════════════════════

do
	local closeBtn   = S5:FindFirstChild("CloseBtn",   true)
	local cancelBtn  = S5:FindFirstChild("CancelBtn",  true)
	local confirmBtn = S5:FindFirstChild("ConfirmBtn", true)

	if closeBtn  then closeBtn.MouseButton1Click:Connect(function()  closeModal(S5) end) end
	if cancelBtn then cancelBtn.MouseButton1Click:Connect(function() closeModal(S5) end) end

	if confirmBtn then
		confirmBtn.MouseButton1Click:Connect(function()
			-- Roblox no permite cerrar el juego desde un LocalScript directamente.
			-- La convención es usar Kick o simplemente ocultar el juego.
			player:Kick("¡Hasta pronto! Gracias por jugar EDA Quest.")
		end)
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- RESPUESTA DEL SERVIDOR: LevelReady
-- ════════════════════════════════════════════════════════════════════════════

if levelReadyEv then
	levelReadyEv.OnClientEvent:Connect(function(data)
		if data.error then
			-- El nivel no se encontró: mostrar mensaje y volver al menú
			loadingLbl.Text = "❌ " .. data.error
			task.delay(2.5, function()
				fadeOut(0.4, function()
					isLoading = false
					goToLevels()
				end)
			end)
			return
		end

		-- Nivel cargado correctamente
		loadingLbl.Text = "✅  " .. (data.nombre or "Nivel " .. tostring(data.nivelID))
		task.delay(0.6, function()
			fadeOut(0.4, function()
				-- Ocultar menú completo → el gameplay toma el control
				root.Enabled = false
				isLoading = false
				print("[MenuController] Nivel", data.nivelID, "listo — menú ocultado")
			end)
		end)
	end)
end

-- ════════════════════════════════════════════════════════════════════════════
-- ESPERAMOS ServerReady (por si el servidor tarda)
-- La GUI ya es visible mientras espera — el jugador puede ver el menú
-- ════════════════════════════════════════════════════════════════════════════

if serverReadyEv then
	serverReadyEv.OnClientEvent:Connect(function()
		print("[MenuController] ServerReady recibido — servidor listo")
		-- En Fase 2 aquí se llamará GetPlayerProgress para cargar datos del jugador
	end)
end

print("[EDA v2] ✅ MenuController activo")
