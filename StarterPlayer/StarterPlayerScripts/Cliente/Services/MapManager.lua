-- ================================================================
-- MapManager.lua (FINAL v3)
-- Todas las funciones locales declaradas ANTES de usarse.
-- MapManager es el único dueño del estado del techo.
-- ================================================================

local MapManager = {}
MapManager.__index = MapManager

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Dependencias (inyectadas en initialize)
local LevelsConfig      = nil
local NodeLabelManager  = nil
local MissionsManager   = nil

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Estado del mapa
local state            = nil
local screenGui        = nil
local btnMapa          = nil
local camaraConnection = nil
local zoneHighlights   = {}

-- ================================================================
-- ESTADO DEL TECHO — fuente única de verdad
-- ================================================================
local techoValoresOriginales = {}    -- { [BasePart] = { Transparency, CastShadow } }
local techoCapturado         = false -- true = ya capturamos los valores reales
local techoEstaOculto        = false -- estado actual

-- ================================================================
-- FUNCIONES LOCALES (declaradas antes de usarse)
-- ================================================================

-- ---------- Techo ----------

local function capturarOriginales()
	if techoCapturado then return end
	local nivelActual = workspace:FindFirstChild("NivelActual")
	if not nivelActual then return end
	local techosFolder = nivelActual:FindFirstChild("Techos")
	if not techosFolder then return end
	for _, part in ipairs(techosFolder:GetChildren()) do
		if part:IsA("BasePart") then
			techoValoresOriginales[part] = {
				Transparency = part.Transparency,
				CastShadow   = part.CastShadow,
			}
		end
	end
	techoCapturado = true
	print("🏠 MapManager: Originales del techo capturados (solo esta vez)")
end

-- ---------- Zonas ----------

local function findZones(nivelModel)
	if not nivelModel then return {} end
	local zonas = nivelModel:FindFirstChild("Zonas")
	if not zonas then return {} end
	local zonasJuego = zonas:FindFirstChild("Zonas_juego")
	if not zonasJuego then return {} end
	return zonasJuego:GetChildren()
end

local function getZoneConfig(zonaID, nivelID)
	local config = LevelsConfig[nivelID]
	if not config or not config.Zonas then return nil end
	return config.Zonas[zonaID]
end

local function clearZoneHighlights()
	for zonaPart, data in pairs(zoneHighlights) do
		if zonaPart and zonaPart.Parent then
			zonaPart.Transparency = data.OriginalTransparency
		end
		if data.Highlight and data.Highlight.Parent then data.Highlight:Destroy() end
		if data.Billboard and data.Billboard.Parent then data.Billboard:Destroy() end
	end
	zoneHighlights = {}
end

local function highlightZone(zonaPart, zonaID, nivelID)
	if not zonaPart or not zonaPart:IsA("BasePart") then return end
	local zoneConfig = getZoneConfig(zonaID, nivelID)
	if not zoneConfig then
		zoneConfig = { Descripcion = zonaID, Color = Color3.fromRGB(65, 105, 225), Concepto = "" }
	end
	if zoneConfig.Oculta then return end

	local originalTransparency = zonaPart.Transparency

	local highlight = Instance.new("Highlight")
	highlight.Name             = "ZoneHighlight"
	highlight.Adornee          = zonaPart
	highlight.FillColor        = zoneConfig.Color or Color3.fromRGB(65, 105, 225)
	highlight.OutlineColor     = Color3.new(1, 1, 1)
	highlight.FillTransparency = 0.3
	highlight.OutlineTransparency = 0
	highlight.Parent           = zonaPart

	zonaPart.Transparency = 0.7

	local bb = Instance.new("BillboardGui")
	bb.Name         = "ZoneBillboard"
	bb.Size         = UDim2.new(0, 300, 0, 100)
	bb.StudsOffset  = Vector3.new(0, 8, 0)
	bb.AlwaysOnTop  = true
	bb.Parent       = zonaPart

	local frame = Instance.new("Frame")
	frame.Size                  = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3      = zoneConfig.Color or Color3.fromRGB(65, 105, 225)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel       = 0
	frame.Parent                = bb

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent       = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color     = Color3.new(1, 1, 1)
	stroke.Thickness = 3
	stroke.Parent    = frame

	local label = Instance.new("TextLabel")
	label.Size               = UDim2.new(1, -20, 0.6, 0)
	label.Position           = UDim2.new(0, 10, 0, 10)
	label.BackgroundTransparency = 1
	label.Text               = zoneConfig.Descripcion or zonaID
	label.TextColor3         = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3   = Color3.new(0, 0, 0)
	label.Font               = Enum.Font.FredokaOne
	label.TextSize           = 22
	label.TextScaled         = true
	label.TextXAlignment     = Enum.TextXAlignment.Center
	label.TextYAlignment     = Enum.TextYAlignment.Top
	label.Parent             = frame

	if zoneConfig.Concepto and zoneConfig.Concepto ~= "" then
		local conceptLabel = Instance.new("TextLabel")
		conceptLabel.Size               = UDim2.new(1, -20, 0.3, 0)
		conceptLabel.Position           = UDim2.new(0, 10, 0.65, 0)
		conceptLabel.BackgroundTransparency = 1
		conceptLabel.Text               = "📚 " .. zoneConfig.Concepto
		conceptLabel.TextColor3         = Color3.fromRGB(255, 255, 200)
		conceptLabel.TextStrokeTransparency = 0
		conceptLabel.Font               = Enum.Font.GothamBold
		conceptLabel.TextSize           = 14
		conceptLabel.TextScaled         = true
		conceptLabel.TextXAlignment     = Enum.TextXAlignment.Center
		conceptLabel.Parent             = frame
	end

	frame.Size = UDim2.new(0, 0, 0, 0)
	TweenService:Create(frame,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.new(1, 0, 1, 0) }
	):Play()

	zoneHighlights[zonaPart] = {
		Highlight            = highlight,
		Billboard            = bb,
		OriginalTransparency = originalTransparency,
	}
end

local function highlightAllZones(nivelModel, nivelID)
	local zonas = findZones(nivelModel)
	if #zonas == 0 then return end

	local zonasResaltadas = 0
	for _, zona in ipairs(zonas) do
		local zonaID   = zona.Name
		local zonaPart = nil

		if zona:IsA("BasePart") then
			zonaPart = zona
		else
			local largestSize = 0
			for _, child in ipairs(zona:GetDescendants()) do
				if child:IsA("BasePart") and not child:IsA("Attachment") then
					local size = child.Size.X * child.Size.Y * child.Size.Z
					if size > largestSize then
						zonaPart    = child
						largestSize = size
					end
				end
			end
		end

		if zonaPart then
			highlightZone(zonaPart, zonaID, nivelID)
			zonasResaltadas = zonasResaltadas + 1
		end
	end

	if zonasResaltadas > 0 then
		print("✅ MapManager: " .. zonasResaltadas .. " zonas resaltadas")
	end
end

-- ================================================================
-- INICIALIZACIÓN
-- ================================================================

function MapManager.initialize(globalState, screenGui_ref, deps)
	state            = globalState
	screenGui        = screenGui_ref
	LevelsConfig     = deps.LevelsConfig
	NodeLabelManager = deps.NodeLabelManager
	MissionsManager  = deps.MissionsManager

	-- Buscar BtnMapa
	local barraBotones = screenGui:FindFirstChild("BarraBotonesMain")
	if barraBotones then btnMapa = barraBotones:FindFirstChild("BtnMapa") end
	if not btnMapa  then btnMapa = screenGui:FindFirstChild("BtnMapa") end

	-- Conectar BindableEvents en background
	task.spawn(function()
		local Events    = ReplicatedStorage:WaitForChild("Events", 10)
		if not Events   then return end
		local Bindables = Events:WaitForChild("Bindables", 10)
		if not Bindables then return end

		local function getOrCreate(name)
			local e = Bindables:FindFirstChild(name)
			if not e then
				e      = Instance.new("BindableEvent")
				e.Name = name
				e.Parent = Bindables
			end
			return e
		end

		-- ForceCloseMap: cerrar mapa SIN restaurar techo
		getOrCreate("ForceCloseMap").Event:Connect(function()
			if state.mapaActivo then
				print("🗺️ MapManager: ForceCloseMap — cierre sin restaurar techo")
				MapManager:_cerrarMapa(false)
			end
		end)

		-- ShowRoof: diálogo pide ocultar techo
		getOrCreate("ShowRoof").Event:Connect(function()
			MapManager:showRoof()
		end)

		-- RestoreRoof: diálogo terminó, restaurar techo
		getOrCreate("RestoreRoof").Event:Connect(function()
			MapManager:restoreRoof()
		end)

		print("✅ MapManager: BindableEvents conectados (ForceCloseMap / ShowRoof / RestoreRoof)")
	end)

	print("✅ MapManager: Inicializado")
end

-- ================================================================
-- API PÚBLICA DE TECHOS
-- ================================================================

function MapManager:showRoof()
	if techoEstaOculto then return end
	capturarOriginales()
	for part in pairs(techoValoresOriginales) do
		if part and part.Parent then
			part.Transparency = 0.95
			part.CastShadow   = false
		end
	end
	techoEstaOculto = true
	print("🏠 MapManager: Techo ocultado")
end

function MapManager:restoreRoof()
	if not techoEstaOculto then return end
	for part, orig in pairs(techoValoresOriginales) do
		if part and part.Parent then
			part.Transparency = orig.Transparency
			part.CastShadow   = orig.CastShadow
		end
	end
	techoEstaOculto = false
	print("🏠 MapManager: Techo restaurado a valores originales")
end

function MapManager:resetRoofCache()
	techoValoresOriginales = {}
	techoCapturado         = false
	techoEstaOculto        = false
end

-- ================================================================
-- CONTROL DEL MAPA
-- ================================================================

function MapManager:toggle(forceState)
	if forceState ~= nil then
		if forceState then self:enable() else self:disable() end
		return
	end
	if state.mapaActivo then self:disable() else self:enable() end
end

function MapManager:enable()
	state.mapaActivo = true

	if btnMapa then
		btnMapa.Text             = "CERRAR MAPA"
		btnMapa.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
	end

	camera.CameraType = Enum.CameraType.Scriptable

	if NodeLabelManager then NodeLabelManager:show() end
	if MissionsManager  then MissionsManager:hide()  end

	self:showRoof()

	local nivelID    = player:GetAttribute("CurrentLevelID") or 0
	local config     = LevelsConfig[nivelID] or LevelsConfig[0]
	local nivelModel = self:_getLevelModel(nivelID, config)
	if nivelModel then
		task.delay(0.3, function()
			highlightAllZones(nivelModel, nivelID)
		end)
	end

	self:_populateLabels()
	self:_startCameraLoop()
end

function MapManager:disable()
	self:_cerrarMapa(true)
end

function MapManager:isActive()
	return state ~= nil and state.mapaActivo == true
end

--- @param restaurarTecho boolean
function MapManager:_cerrarMapa(restaurarTecho)
	state.mapaActivo = false

	if btnMapa then
		btnMapa.Text             = "🗺️ MAPA"
		btnMapa.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
	end

	if not state.enMenu then
		camera.CameraType = Enum.CameraType.Custom
	end

	if NodeLabelManager then NodeLabelManager:hide() end

	if restaurarTecho then
		self:restoreRoof()
	else
		print("🏠 MapManager: Techo NO restaurado — el diálogo toma control")
	end

	clearZoneHighlights()

	if camaraConnection then
		camaraConnection:Disconnect()
		camaraConnection = nil
	end

	self:_restoreSelectors()
end

-- ================================================================
-- LOOP DE CÁMARA
-- ================================================================

function MapManager:_startCameraLoop()
	local nivelID    = player:GetAttribute("CurrentLevelID") or 0
	local config     = LevelsConfig[nivelID] or LevelsConfig[0]
	local nivelModel = self:_getLevelModel(nivelID, config)
	if not nivelModel then return end

	local postesFolder = nivelModel:FindFirstChild("Objetos")
		and nivelModel.Objetos:FindFirstChild("Postes")
	local nombreInicio = config.NodoInicio
	local nombreFin    = config.NodoFin

	if camaraConnection then camaraConnection:Disconnect() end

	camaraConnection = RunService.RenderStepped:Connect(function()
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then return end

		local centro = root.Position
		camera.CFrame = CFrame.new(centro + Vector3.new(0, state.zoomLevel, 0), centro)

		if NodeLabelManager then NodeLabelManager:updateAllPositions() end

		if postesFolder then
			for _, poste in ipairs(postesFolder:GetChildren()) do
				if poste:IsA("Model") then
					self:_updateNodeSelector(poste, nombreInicio, nombreFin)
					self:_updateNodeLabel(poste, centro)
				end
			end
		end
	end)
end

-- ================================================================
-- SELECTORES Y ETIQUETAS
-- ================================================================

function MapManager:_updateNodeSelector(poste, nombreInicio, nombreFin)
	local selector = poste:FindFirstChild("Selector")
	if not selector or not selector:IsA("BasePart") then return end
	selector.Transparency = 0

	local energizado = poste:GetAttribute("Energizado")
	local esInicio   = (poste.Name == nombreInicio)

	if esInicio then
		selector.Color    = Color3.fromRGB(52, 152, 219)
		selector.Material = Enum.Material.Neon
	elseif energizado ~= true then
		selector.Color    = Color3.fromRGB(231, 76, 60)
		selector.Material = Enum.Material.Neon
		if not selector:GetAttribute("OriginalSize") then
			selector:SetAttribute("OriginalSize", selector.Size)
		end
		local origSize = selector:GetAttribute("OriginalSize")
		if origSize then selector.Size = origSize * 1.3 end
	else
		selector.Color    = Color3.fromRGB(46, 204, 113)
		selector.Material = Enum.Material.Plastic
		local origSize    = selector:GetAttribute("OriginalSize")
		if origSize then selector.Size = origSize end
	end
end

function MapManager:_updateNodeLabel(poste, centroCamara)
	if not NodeLabelManager then return end
	local obj = NodeLabelManager:getLabelForNode(poste)
	if not obj then return end
	local distancia = math.floor((poste:GetPivot().Position - centroCamara).Magnitude / 5)
	NodeLabelManager:updateNodeDistance(poste, distancia)
	local nivelID = player:GetAttribute("CurrentLevelID") or 0
	NodeLabelManager:addMetaIndicator(poste, nivelID)
end

-- ================================================================
-- UTILIDADES
-- ================================================================

function MapManager:_restoreSelectors()
	local nivelModel = self:_getLevelModel(player:GetAttribute("CurrentLevelID") or 0, nil)
	if not nivelModel then return end
	local postesFolder = nivelModel:FindFirstChild("Objetos")
		and nivelModel.Objetos:FindFirstChild("Postes")
	if not postesFolder then return end

	for _, poste in ipairs(postesFolder:GetChildren()) do
		if poste:IsA("Model") then
			local selector = poste:FindFirstChild("Selector")
			if selector and selector:IsA("BasePart") then
				selector.Transparency = 1
				selector.Color        = Color3.fromRGB(196, 196, 196)
				selector.Material     = Enum.Material.Plastic
				local origSize        = selector:GetAttribute("OriginalSize")
				if origSize then selector.Size = origSize end
			end
		end
	end
end

function MapManager:_getLevelModel(nivelID, config)
	local m = workspace:FindFirstChild("NivelActual")
	if m then return m end
	if config then
		m = workspace:FindFirstChild(config.Modelo)
		if m then return m end
	end
	m = workspace:FindFirstChild("Nivel" .. nivelID)
	if m then return m end
	return workspace:FindFirstChild("Nivel" .. nivelID .. "_Tutorial")
end

function MapManager:_populateLabels()
	local nivelID    = player:GetAttribute("CurrentLevelID") or 0
	local config     = LevelsConfig[nivelID] or LevelsConfig[0]
	local nivelModel = self:_getLevelModel(nivelID, config)
	if not nivelModel then return end

	local postesFolder = nivelModel:FindFirstChild("Objetos")
		and nivelModel.Objetos:FindFirstChild("Postes")
	if not postesFolder then return end

	for _, poste in ipairs(postesFolder:GetChildren()) do
		if poste:IsA("Model") and NodeLabelManager then
			NodeLabelManager:getLabelForNode(poste)
		end
	end
end

-- ================================================================
-- LIMPIEZA
-- ================================================================

player.AncestryChanged:Connect(function(_, parent)
	if parent == nil then
		if camaraConnection then camaraConnection:Disconnect() end
		clearZoneHighlights()
	end
end)

return MapManager