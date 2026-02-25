local function createUnifiedGUI()
	local TweenService = game:GetService("TweenService")
	local StarterGui = game:GetService("StarterGui")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")
	
	local player = Players.LocalPlayer
	
	local Theme = {
		Colors = {
			Background = Color3.fromRGB(20, 22, 28),
			Surface = Color3.fromRGB(30, 33, 42),
			Overlay = Color3.fromRGB(12, 13, 17),
			Visual = Color3.fromRGB(65, 180, 137),
			Matrix = Color3.fromRGB(100, 160, 215),
			Analysis = Color3.fromRGB(215, 140, 60),
			Success = Color3.fromRGB(76, 175, 80),
			Warning = Color3.fromRGB(255, 193, 7),
			Danger = Color3.fromRGB(229, 57, 53),
			Info = Color3.fromRGB(33, 150, 243),
			TextPrimary = Color3.fromRGB(240, 245, 250),
			TextSecondary = Color3.fromRGB(176, 190, 197),
			TextMuted = Color3.fromRGB(120, 135, 150),
			Grid = Color3.fromRGB(45, 52, 65),
		},
		Font = {
			Display = Enum.Font.GothamBold,
			Bold = Enum.Font.GothamBold,
			Regular = Enum.Font.Gotham,
			Mono = Enum.Font.Code,
		},
		Alpha = {
			Solid = 0, Subtle = 0.15, Moderate = 0.3, High = 0.5, Heavy = 0.7,
		},
		CornerRadius = 8,
	}

	local ComponentFactory = {}
	
	function ComponentFactory.Frame(name, parent, size, position, transparent)
		local frame = Instance.new("Frame")
		frame.Name = name
		frame.Size = size
		frame.Position = position or UDim2.new(0, 0, 0, 0)
		frame.BackgroundColor3 = transparent and Color3.new(0, 0, 0) or Theme.Colors.Surface
		frame.BackgroundTransparency = transparent and Theme.Alpha.Heavy or Theme.Alpha.Subtle
		frame.BorderSizePixel = 0
		frame.Parent = parent
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, Theme.CornerRadius)
		corner.Parent = frame
		
		return frame
	end
	
	function ComponentFactory.Label(name, parent, text, color, fontSize, font)
		local label = Instance.new("TextLabel")
		label.Name = name
		label.Text = text
		label.BackgroundTransparency = 1
		label.TextColor3 = color or Theme.Colors.TextPrimary
		label.Font = font or Theme.Font.Regular
		label.TextSize = fontSize or 14
		label.Parent = parent
		return label
	end
	
	function ComponentFactory.Button(name, parent, text, size, color)
		local button = Instance.new("TextButton")
		button.Name = name
		button.Text = text
		button.Size = size or UDim2.new(0, 120, 0, 40)
		button.BackgroundColor3 = color or Theme.Colors.Matrix
		button.BackgroundTransparency = Theme.Alpha.Subtle
		button.TextColor3 = Theme.Colors.TextPrimary
		button.Font = Theme.Font.Bold
		button.TextSize = 12
		button.Parent = parent
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = button
		
		local originalColor = button.BackgroundColor3
		local originalTransp = button.BackgroundTransparency
		
		button.MouseEnter:Connect(function()
			local tween = TweenService:Create(
				button,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{BackgroundTransparency = originalTransp - 0.1}
			)
			tween:Play()
		end)
		
		button.MouseLeave:Connect(function()
			local tween = TweenService:Create(
				button,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{BackgroundTransparency = originalTransp}
			)
			tween:Play()
		end)
		
		return button
	end

	if StarterGui:FindFirstChild("UnifiedGUI") then
		StarterGui.UnifiedGUI:Destroy()
	end
	
	local gui = Instance.new("ScreenGui")
	gui.Name = "UnifiedGUI"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = StarterGui
	gui.Enabled = false

	local topBar = ComponentFactory.Frame("TopBar", gui, UDim2.new(1, -40, 0, 60), UDim2.new(0, 20, 0, 15))
	
	local topBarLayout = Instance.new("UIListLayout")
	topBarLayout.FillDirection = Enum.FillDirection.Horizontal
	topBarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	topBarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	topBarLayout.Padding = UDim.new(0, 16)
	topBarLayout.Parent = topBar

	local titleLabel = ComponentFactory.Label("Title", topBar, "Explorador de Grafos", Theme.Colors.TextPrimary, 20, Theme.Font.Display)
	titleLabel.Size = UDim2.new(0.3, 0, 1, 0)

	local scorePanel = ComponentFactory.Frame("ScorePanel", topBar, UDim2.new(0.35, 0, 1, 0), UDim2.new(0.65, 0, 0, 0))
	
	local scorePanelLayout = Instance.new("UIListLayout")
	scorePanelLayout.FillDirection = Enum.FillDirection.Horizontal
	scorePanelLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	scorePanelLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	scorePanelLayout.Padding = UDim.new(0, 20)
	scorePanelLayout.Parent = scorePanel

	local starsContainer = Instance.new("Frame")
	starsContainer.Name = "StarsContainer"
	starsContainer.Size = UDim2.new(0, 120, 1, 0)
	starsContainer.BackgroundTransparency = 1
	starsContainer.Parent = scorePanel
	
	local starsLabel = ComponentFactory.Label("Label", starsContainer, "ESTRELLAS", Theme.Colors.Warning, 11, Theme.Font.Bold)
	starsLabel.Size = UDim2.new(1, 0, 0.4, 0)
	starsLabel.TextXAlignment = Enum.TextXAlignment.Center
	
	local starsValue = ComponentFactory.Label("Value", starsContainer, "0/3", Theme.Colors.Warning, 16, Theme.Font.Bold)
	starsValue.Size = UDim2.new(1, 0, 0.6, 0)
	starsValue.Position = UDim2.new(0, 0, 0.4, 0)
	starsValue.TextXAlignment = Enum.TextXAlignment.Center

	local pointsContainer = Instance.new("Frame")
	pointsContainer.Name = "PointsContainer"
	pointsContainer.Size = UDim2.new(0, 140, 1, 0)
	pointsContainer.BackgroundTransparency = 1
	pointsContainer.Parent = scorePanel
	
	local pointsLabel = ComponentFactory.Label("Label", pointsContainer, "PUNTOS", Theme.Colors.Info, 11, Theme.Font.Bold)
	pointsLabel.Size = UDim2.new(1, 0, 0.4, 0)
	pointsLabel.TextXAlignment = Enum.TextXAlignment.Center
	
	local pointsValue = ComponentFactory.Label("Value", pointsContainer, "0", Theme.Colors.Info, 16, Theme.Font.Bold)
	pointsValue.Size = UDim2.new(1, 0, 0.6, 0)
	pointsValue.Position = UDim2.new(0, 0, 0.4, 0)
	pointsValue.TextXAlignment = Enum.TextXAlignment.Center

	local mainButtonsBar = ComponentFactory.Frame("MainButtonsBar", gui, UDim2.new(0, 500, 0, 60), UDim2.new(0.5, -250, 0, 15))
	
	local btnLayout = Instance.new("UIListLayout")
	btnLayout.FillDirection = Enum.FillDirection.Horizontal
	btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	btnLayout.Padding = UDim.new(0, 8)
	btnLayout.Parent = mainButtonsBar

	local btnAlgo = ComponentFactory.Button("BtnAlgo", mainButtonsBar, "Algoritmo", UDim2.new(0, 105, 0, 45), Theme.Colors.Analysis)
	local btnMapa = ComponentFactory.Button("BtnMapa", mainButtonsBar, "Mapa", UDim2.new(0, 90, 0, 45), Theme.Colors.Visual)
	local btnMatriz = ComponentFactory.Button("BtnMatriz", mainButtonsBar, "Matriz", UDim2.new(0, 95, 0, 45), Theme.Colors.Matrix)
	local btnMisiones = ComponentFactory.Button("BtnMisiones", mainButtonsBar, "Misiones", UDim2.new(0, 105, 0, 45), Theme.Colors.Info)

	local secondaryButtonsBar = ComponentFactory.Frame("SecondaryButtonsBar", gui, UDim2.new(0, 230, 0, 60), UDim2.new(1, -250, 0, 15))
	
	local btnSecLayout = Instance.new("UIListLayout")
	btnSecLayout.FillDirection = Enum.FillDirection.Horizontal
	btnSecLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	btnSecLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	btnSecLayout.Padding = UDim.new(0, 8)
	btnSecLayout.Parent = secondaryButtonsBar

	local btnReiniciar = ComponentFactory.Button("BtnReiniciar", secondaryButtonsBar, "Reiniciar", UDim2.new(0, 105, 0, 45), Theme.Colors.Warning)
	local btnFinalizar = ComponentFactory.Button("BtnFinalizar", secondaryButtonsBar, "Finalizar", UDim2.new(0, 105, 0, 45), Theme.Colors.Success)
	btnFinalizar.Visible = false

	local modeSelector = ComponentFactory.Frame("ModeSelector", gui, UDim2.new(0, 380, 0, 60), UDim2.new(0.5, -190, 1, -70))
	
	local modeLayout = Instance.new("UIListLayout")
	modeLayout.FillDirection = Enum.FillDirection.Horizontal
	modeLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	modeLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	modeLayout.Padding = UDim.new(0, 8)
	modeLayout.Parent = modeSelector

	local modes = {
		{Name = "Modo Visual", Color = Theme.Colors.Visual},
		{Name = "Modo Matriz", Color = Theme.Colors.Matrix},
		{Name = "Modo Analisis", Color = Theme.Colors.Analysis},
	}

	local modeButtons = {}
	for _, mode in ipairs(modes) do
		local btn = ComponentFactory.Button(mode.Name .. "Btn", modeSelector, mode.Name, UDim2.new(0, 110, 0, 45), mode.Color)
		modeButtons[mode.Name] = btn
	end

	local minimapContainer = ComponentFactory.Frame("MinimapContainer", gui, UDim2.new(0, 280, 0, 280), UDim2.new(1, -295, 1, -295))
	
	local minimapTitle = ComponentFactory.Label("Title", minimapContainer, "MAPA EN VIVO", Theme.Colors.TextSecondary, 12, Theme.Font.Bold)
	minimapTitle.Size = UDim2.new(1, -20, 0, 25)
	minimapTitle.Position = UDim2.new(0, 10, 0, 5)
	minimapTitle.TextXAlignment = Enum.TextXAlignment.Left

	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "MapViewport"
	viewport.Size = UDim2.new(1, -20, 1, -40)
	viewport.Position = UDim2.new(0, 10, 0, 35)
	viewport.BackgroundColor3 = Theme.Colors.Overlay
	viewport.BorderSizePixel = 0
	viewport.Parent = minimapContainer
	
	local vpCorner = Instance.new("UICorner")
	vpCorner.CornerRadius = UDim.new(0, 6)
	vpCorner.Parent = viewport

	local matrixPanel = ComponentFactory.Frame("MatrixPanel", gui, UDim2.new(0, 320, 0.65, 0), UDim2.new(1, -330, 0.08, 0))
	matrixPanel.Visible = false
	
	local mpTitle = ComponentFactory.Label("Title", matrixPanel, "MATRIZ DE ADYACENCIA", Theme.Colors.TextPrimary, 16, Theme.Font.Bold)
	mpTitle.Size = UDim2.new(1, -20, 0, 35)
	mpTitle.Position = UDim2.new(0, 10, 0, 10)
	mpTitle.TextXAlignment = Enum.TextXAlignment.Left
	
	local nodeInfoBg = ComponentFactory.Frame("NodeInfo", matrixPanel, UDim2.new(0.9, 0, 0, 90), UDim2.new(0.5, 0, 0, 55), true)
	
	local selectedNodeName = ComponentFactory.Label("NodeName", nodeInfoBg, "Nodo: --", Theme.Colors.Matrix, 13, Theme.Font.Bold)
	selectedNodeName.Size = UDim2.new(1, -20, 0, 25)
	selectedNodeName.Position = UDim2.new(0, 10, 0, 5)
	selectedNodeName.TextXAlignment = Enum.TextXAlignment.Left
	
	local nodeStats = ComponentFactory.Label("Stats", nodeInfoBg, "Grado: 0 | Entrada: 0 | Salida: 0", Theme.Colors.TextMuted, 11, Theme.Font.Mono)
	nodeStats.Size = UDim2.new(1, -20, 0, 20)
	nodeStats.Position = UDim2.new(0, 10, 0, 30)
	nodeStats.TextXAlignment = Enum.TextXAlignment.Left
	
	local matrixGrid = Instance.new("ScrollingFrame")
	matrixGrid.Name = "MatrixGrid"
	matrixGrid.Size = UDim2.new(0.95, 0, 0.65, 0)
	matrixGrid.Position = UDim2.new(0.025, 0, 0, 160)
	matrixGrid.BackgroundTransparency = 1
	matrixGrid.ScrollBarThickness = 3
	matrixGrid.Parent = matrixPanel
	
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 40, 0, 40)
	gridLayout.CellPadding = UDim2.new(0, 1, 0, 1)
	gridLayout.FillDirection = Enum.FillDirection.Horizontal
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.Parent = matrixGrid

	for i = 1, 25 do
		local cell = ComponentFactory.Label("Cell" .. i, matrixGrid, tostring(math.random(0, 1)), Theme.Colors.TextPrimary, 14, Theme.Font.Mono)
		cell.Size = UDim2.new(0, 40, 0, 40)
		cell.BackgroundColor3 = (cell.Text == "1") and Theme.Colors.Success or Theme.Colors.Grid
		cell.BackgroundTransparency = 0
		cell.TextScaled = true
		
		local cellCorner = Instance.new("UICorner")
		cellCorner.CornerRadius = UDim.new(0, 4)
		cellCorner.Parent = cell
	end

	local analysisOverlay = ComponentFactory.Frame("AnalysisOverlay", gui, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), true)
	analysisOverlay.BackgroundTransparency = Theme.Alpha.Heavy
	analysisOverlay.Visible = false
	analysisOverlay.ZIndex = 10
	
	local analysisPanel = ComponentFactory.Frame("CenterPanel", analysisOverlay, UDim2.new(0, 700, 0, 550), UDim2.new(0.5, -350, 0.5, -275))
	analysisPanel.BackgroundColor3 = Theme.Colors.Surface
	analysisPanel.BackgroundTransparency = Theme.Alpha.Subtle
	analysisPanel.ZIndex = 11
	
	local analysisHeader = ComponentFactory.Frame("Header", analysisPanel, UDim2.new(1, 0, 0, 70), UDim2.new(0, 0, 0, 0))
	analysisHeader.BackgroundColor3 = Theme.Colors.Analysis
	analysisHeader.BackgroundTransparency = Theme.Alpha.Subtle
	
	local headerTitle = ComponentFactory.Label("Title", analysisHeader, "EJECUCION: BFS", Theme.Colors.TextPrimary, 24, Theme.Font.Display)
	headerTitle.Size = UDim2.new(1, -30, 1, 0)
	headerTitle.Position = UDim2.new(0, 15, 0, 0)
	
	local stepInfo = ComponentFactory.Label("StepInfo", analysisPanel, "Paso 1: Iniciando busqueda desde Inicio", Theme.Colors.TextSecondary, 13)
	stepInfo.Size = UDim2.new(1, -30, 0, 35)
	stepInfo.Position = UDim2.new(0, 15, 0, 80)
	stepInfo.TextXAlignment = Enum.TextXAlignment.Left
	
	local dataPanel = ComponentFactory.Frame("DataPanel", analysisPanel, UDim2.new(0.95, 0, 0.35, 0), UDim2.new(0.5, 0, 0.35, 0), true)
	
	local dataTitle = ComponentFactory.Label("Title", dataPanel, "ESTADO ACTUAL", Theme.Colors.TextPrimary, 12, Theme.Font.Bold)
	dataTitle.Size = UDim2.new(1, -20, 0, 20)
	dataTitle.Position = UDim2.new(0, 10, 0, 5)
	
	local dataText = ComponentFactory.Label("Text", dataPanel, 
		"COLA: [Nodo2, Nodo3, Nodo4]\nVISITADOS: {Nodo1}\nDISTANCIAS: Nodo1(0), Nodo2(1), Nodo3(1)", 
		Theme.Colors.Accent1, 11, Theme.Font.Mono)
	dataText.Size = UDim2.new(1, -20, 1, -30)
	dataText.Position = UDim2.new(0, 10, 0, 25)
	dataText.TextXAlignment = Enum.TextXAlignment.Left
	dataText.TextYAlignment = Enum.TextYAlignment.Top
	dataText.TextWrapped = true
	
	local controls = Instance.new("Frame")
	controls.Name = "Controls"
	controls.Size = UDim2.new(1, 0, 0, 70)
	controls.Position = UDim2.new(0, 0, 1, -70)
	controls.BackgroundTransparency = 1
	controls.Parent = analysisPanel
	
	local ctrlLayout = Instance.new("UIListLayout")
	ctrlLayout.FillDirection = Enum.FillDirection.Horizontal
	ctrlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	ctrlLayout.Padding = UDim.new(0, 15)
	ctrlLayout.Parent = controls
	
	ComponentFactory.Button("PrevBtn", controls, "Anterior", UDim2.new(0, 130, 0, 40), Theme.Colors.Warning)
	ComponentFactory.Button("NextBtn", controls, "Siguiente", UDim2.new(0, 130, 0, 40), Theme.Colors.Analysis)
	ComponentFactory.Button("ExitBtn", controls, "Salir", UDim2.new(0, 100, 0, 40), Theme.Colors.Danger)

	local ModeManager = {}
	local currentMode = "VISUAL"
	
	function ModeManager:SwitchMode(mode)
		minimapContainer.Visible = false
		matrixPanel.Visible = false
		analysisOverlay.Visible = false
		btnMisiones.Visible = false
		btnAlgo.Visible = false
		btnMapa.Visible = false
		
		if mode == "VISUAL" then
			minimapContainer.Visible = true
			btnMisiones.Visible = true
			btnAlgo.Visible = true
			btnMapa.Visible = true
			currentMode = "VISUAL"
			print("OK MODO VISUAL")
			
		elseif mode == "MATRIZ" then
			matrixPanel.Visible = true
			btnAlgo.Visible = true
			currentMode = "MATRIZ"
			print("OK MODO MATRIZ")
			
		elseif mode == "ANALISIS" then
			analysisOverlay.Visible = true
			currentMode = "ANALISIS"
			print("OK MODO ANALISIS")
		end
	end

	if modeButtons.Visual then
		modeButtons.Visual.MouseButton1Click:Connect(function()
			ModeManager:SwitchMode("VISUAL")
		end)
	end
	
	if modeButtons.Matriz then
		modeButtons.Matriz.MouseButton1Click:Connect(function()
			ModeManager:SwitchMode("MATRIZ")
		end)
	end
	
	if modeButtons.Analisis then
		modeButtons.Analisis.MouseButton1Click:Connect(function()
			ModeManager:SwitchMode("ANALISIS")
		end)
	end

	local UIReferences = {
		GUI = gui,
		Frames = {
			TopBar = topBar,
			ModeSelector = modeSelector,
			Minimap = minimapContainer,
			Matrix = matrixPanel,
			Analysis = analysisOverlay,
			ScorePanel = scorePanel,
		},
		Buttons = {
			BtnAlgo = btnAlgo,
			BtnMapa = btnMapa,
			BtnMatriz = btnMatriz,
			BtnMisiones = btnMisiones,
			BtnReiniciar = btnReiniciar,
			BtnFinalizar = btnFinalizar,
		},
		Labels = {
			StarsValue = starsValue,
			PointsValue = pointsValue,
			SelectedNode = selectedNodeName,
			NodeStats = nodeStats,
		},
		Elements = {
			MatrixGrid = matrixGrid,
			Viewport = viewport,
		},
		Theme = Theme,
		ModeManager = ModeManager,
	}

	print("OK GUI creada sin errores")
	_G.UnifiedGUI = UIReferences
	
	return UIReferences
end

return createUnifiedGUI()