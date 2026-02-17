-- ================================================================
-- MapManager.lua (MEJORADO CON ZONAS)
-- Gestiona activación/desactivación de vista de mapa
-- ✅ MANTIENE: updateAllPositions() en el loop de renderizado
-- 🔥 NUEVO: Resalta zonas con billboards cuando se activa el mapa
-- ================================================================

local MapManager = {}
MapManager.__index = MapManager

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Dependencias
local LevelsConfig = nil
local NodeLabelManager = nil
local MissionsManager = nil
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Estado
local state = nil
local screenGui = nil
local btnMapa = nil
local camaraConnection = nil
local techoOriginalTransparency = {}

-- 🔥 NUEVO: Estado de highlights de zonas
local zoneHighlights = {} -- { [zonaPart] = { Highlight, Billboard, OriginalTransparency } }

-- ================================================================
-- INICIALIZACIÓN
-- ================================================================

--- Inyecta dependencias y referencias
function MapManager.initialize(globalState, screenGui_ref, deps)
	state = globalState
	screenGui = screenGui_ref
	btnMapa = screenGui:WaitForChild("BtnMapa", 5)
	LevelsConfig = deps.LevelsConfig
	NodeLabelManager = deps.NodeLabelManager
	MissionsManager = deps.MissionsManager

	print("✅ MapManager: Inicializado con soporte de zonas")
end

-- ================================================================
-- 🔥 NUEVO: GESTIÓN DE ZONAS
-- ================================================================

--- Busca las zonas en el nivel actual
local function findZones(nivelModel)
	if not nivelModel then return {} end

	-- Buscar carpeta Zonas > Zonas_juego
	local zonas = nivelModel:FindFirstChild("Zonas")
	if not zonas then
		return {}
	end

	local zonasJuego = zonas:FindFirstChild("Zonas_juego")
	if not zonasJuego then
		return {}
	end

	return zonasJuego:GetChildren()
end

--- Obtiene la configuración de una zona desde LevelsConfig
local function getZoneConfig(zonaID, nivelID)
	local config = LevelsConfig[nivelID]
	if not config or not config.Zonas then return nil end

	return config.Zonas[zonaID]
end

--- Resalta una zona con color y billboard
local function highlightZone(zonaPart, zonaID, nivelID)
	if not zonaPart or not zonaPart:IsA("BasePart") then return end

	-- Obtener configuración de la zona
	local zoneConfig = getZoneConfig(zonaID, nivelID)
	if not zoneConfig then
		-- Si no hay config, usar valores por defecto
		zoneConfig = {
			Descripcion = zonaID,
			Color = Color3.fromRGB(65, 105, 225),
			Concepto = ""
		}
	end

	-- Verificar si es una zona oculta
	if zoneConfig.Oculta then
		return -- No resaltar zonas ocultas
	end

	-- Guardar transparencia original
	local originalTransparency = zonaPart.Transparency

	-- 1. Crear Highlight
	local highlight = Instance.new("Highlight")
	highlight.Name = "ZoneHighlight"
	highlight.Adornee = zonaPart
	highlight.FillColor = zoneConfig.Color or Color3.fromRGB(65, 105, 225)
	highlight.OutlineColor = Color3.new(1, 1, 1)
	highlight.FillTransparency = 0.3
	highlight.OutlineTransparency = 0
	highlight.Parent = zonaPart

	-- 2. Hacer la zona semi-transparente para ver el highlight
	zonaPart.Transparency = 0.7

	-- 3. Crear BillboardGui con nombre de zona
	local bb = Instance.new("BillboardGui")
	bb.Name = "ZoneBillboard"
	bb.Size = UDim2.new(0, 300, 0, 100)
	bb.StudsOffset = Vector3.new(0, 8, 0) -- Más alto que las etiquetas de nodos
	bb.AlwaysOnTop = true
	bb.Parent = zonaPart

	-- Frame contenedor
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = zoneConfig.Color or Color3.fromRGB(65, 105, 225)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.Parent = bb

	-- Esquinas redondeadas
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	-- Borde/stroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Thickness = 3
	stroke.Transparency = 0
	stroke.Parent = frame

	-- Label con descripción
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 0.6, 0)
	label.Position = UDim2.new(0, 10, 0, 10)
	label.BackgroundTransparency = 1
	label.Text = zoneConfig.Descripcion or zonaID
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Font = Enum.Font.FredokaOne
	label.TextSize = 22
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Parent = frame

	-- Label con concepto (solo si existe)
	if zoneConfig.Concepto and zoneConfig.Concepto ~= "" then
		local conceptLabel = Instance.new("TextLabel")
		conceptLabel.Size = UDim2.new(1, -20, 0.3, 0)
		conceptLabel.Position = UDim2.new(0, 10, 0.65, 0)
		conceptLabel.BackgroundTransparency = 1
		conceptLabel.Text = "📚 " .. zoneConfig.Concepto
		conceptLabel.TextColor3 = Color3.fromRGB(255, 255, 200)
		conceptLabel.TextStrokeTransparency = 0
		conceptLabel.Font = Enum.Font.GothamBold
		conceptLabel.TextSize = 14
		conceptLabel.TextScaled = true
		conceptLabel.TextXAlignment = Enum.TextXAlignment.Center
		conceptLabel.Parent = frame
	end

	-- Efecto de aparición
	frame.Size = UDim2.new(0, 0, 0, 0)
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(frame, tweenInfo, {Size = UDim2.new(1, 0, 1, 0)}):Play()

	-- Guardar referencias
	zoneHighlights[zonaPart] = {
		Highlight = highlight,
		Billboard = bb,
		OriginalTransparency = originalTransparency
	}

	print("🗺️ Zona resaltada: " .. zonaID)
end

--- Limpia todos los highlights de zonas
local function clearZoneHighlights()
	for zonaPart, data in pairs(zoneHighlights) do
		-- Restaurar transparencia original
		if zonaPart and zonaPart.Parent then
			zonaPart.Transparency = data.OriginalTransparency
		end

		-- Destruir highlight
		if data.Highlight and data.Highlight.Parent then
			data.Highlight:Destroy()
		end

		-- Destruir billboard
		if data.Billboard and data.Billboard.Parent then
			data.Billboard:Destroy()
		end
	end

	zoneHighlights = {}
end

--- Resalta todas las zonas del nivel
local function highlightAllZones(nivelModel, nivelID)
	local zonas = findZones(nivelModel)

	if #zonas == 0 then
		return
	end

	local zonasResaltadas = 0
	for _, zona in ipairs(zonas) do
		local zonaID = zona.Name -- "Zona_Estacion_1", etc.

		-- Buscar el BasePart principal de la zona
		local zonaPart = nil
		if zona:IsA("BasePart") then
			zonaPart = zona
		else
			-- Buscar el primer BasePart dentro (preferir el más grande)
			local largestSize = 0
			for _, child in ipairs(zona:GetDescendants()) do
				if child:IsA("BasePart") and not child:IsA("Attachment") then
					local size = child.Size.X * child.Size.Y * child.Size.Z
					if size > largestSize then
						zonaPart = child
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
-- CONTROL DE MAPA
-- ================================================================

--- Activa/desactiva el mapa
function MapManager:toggle(forceState)
	if forceState ~= nil then
		if forceState then self:enable() else self:disable() end
		return
	end

	if state.mapaActivo then
		self:disable()
	else
		self:enable()
	end
end

--- Activa vista de mapa
function MapManager:enable()
	state.mapaActivo = true

	-- Cambiar apariencia del botón
	if btnMapa then
		btnMapa.Text = "CERRAR MAPA"
		btnMapa.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
	end

	-- Cambiar cámara a modo scripteado
	camera.CameraType = Enum.CameraType.Scriptable

	-- Mostrar etiquetas de nodos
	if NodeLabelManager then
		NodeLabelManager:show()
	end

	-- Mostrar panel de misiones
	if MissionsManager then
		MissionsManager:show()
	end

	-- Transparentar techos
	self:_setRoofsTransparency(0.95)

	-- Poblar Etiquetas (Estilo Original)
	self:_populateLabels()

	-- 🔥 NUEVO: Resaltar zonas
	local nivelID = player:GetAttribute("CurrentLevelID") or 0
	local config = LevelsConfig[nivelID] or LevelsConfig[0]
	local nivelModel = self:_getLevelModel(nivelID, config)

	if nivelModel then
		task.delay(0.3, function()
			highlightAllZones(nivelModel, nivelID)
		end)
	end

	-- Iniciar loop de cámara
	self:_startCameraLoop()
end

--- Desactiva vista de mapa
function MapManager:disable()
	state.mapaActivo = false

	-- Cambiar apariencia del botón
	if btnMapa then
		btnMapa.Text = "🗺️ MAPA"
		btnMapa.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
	end

	-- Cambiar cámara a modo normal (si no estamos en menú)
	if not state.enMenu then
		camera.CameraType = Enum.CameraType.Custom
	end

	-- Ocultar etiquetas
	if NodeLabelManager then
		NodeLabelManager:hide()
	end

	-- Ocultar panel de misiones
	if MissionsManager then
		MissionsManager:hide()
	end

	-- Restaurar techos
	self:_restoreRoofs()

	-- 🔥 NUEVO: Limpiar highlights de zonas
	clearZoneHighlights()

	-- Detener loop de cámara
	if camaraConnection then
		camaraConnection:Disconnect()
		camaraConnection = nil
	end

	-- Restaurar selectores
	self:_restoreSelectors()
end

--- Inicia el loop de renderizado de la cámara
function MapManager:_startCameraLoop()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")

	local nivelID = player:GetAttribute("CurrentLevelID") or 0
	local config = LevelsConfig[nivelID] or LevelsConfig[0]
	local nombreInicio = config.NodoInicio
	local nombreFin = config.NodoFin

	local nivelModel = self:_getLevelModel(nivelID, config)
	if not nivelModel then return end

	local postesFolder = nivelModel:FindFirstChild("Objetos") and nivelModel.Objetos:FindFirstChild("Postes")

	if camaraConnection then
		camaraConnection:Disconnect()
	end

	camaraConnection = RunService.RenderStepped:Connect(function()
		if not root or not player.Character then return end

		local centro = root.Position

		-- Actualizar posición de cámara
		camera.CFrame = CFrame.new(centro + Vector3.new(0, state.zoomLevel, 0), centro)

		-- ✅ Actualizar posiciones de TODAS las etiquetas en cada frame
		if NodeLabelManager then
			NodeLabelManager:updateAllPositions()
		end

		-- Actualizar selectores y etiquetas
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

--- Actualiza apariencia del selector de un nodo
function MapManager:_updateNodeSelector(poste, nombreInicio, nombreFin)
	local selector = poste:FindFirstChild("Selector")
	if not selector or not selector:IsA("BasePart") then return end

	selector.Transparency = 0

	local energizado = poste:GetAttribute("Energizado")
	local esInicio = (poste.Name == nombreInicio)
	local esFin = (poste.Name == nombreFin)

	if esInicio then
		-- Nodo de inicio: Azul Neon
		selector.Color = Color3.fromRGB(52, 152, 219)
		selector.Material = Enum.Material.Neon
	elseif energizado ~= true then
		-- No energizado: Rojo Neon + grande
		selector.Color = Color3.fromRGB(231, 76, 60)
		selector.Material = Enum.Material.Neon

		if not selector:GetAttribute("OriginalSize") then
			selector:SetAttribute("OriginalSize", selector.Size)
		end

		local origSize = selector:GetAttribute("OriginalSize")
		if origSize then
			selector.Size = origSize * 1.3
		end
	else
		-- Energizado: Verde Plastic
		selector.Color = Color3.fromRGB(46, 204, 113)
		selector.Material = Enum.Material.Plastic

		local origSize = selector:GetAttribute("OriginalSize")
		if origSize then
			selector.Size = origSize
		end
	end
end

--- Actualiza etiqueta de distancia de un nodo
function MapManager:_updateNodeLabel(poste, centroCamara)
	if not NodeLabelManager then return end
	local obj = NodeLabelManager:getLabelForNode(poste)
	if not obj then return end

	local distancia = math.floor((poste:GetPivot().Position - centroCamara).Magnitude / 5)

	-- Actualizar distancia
	NodeLabelManager:updateNodeDistance(poste, distancia)

	-- Añadir indicador META si es necesario
	local nivelID = player:GetAttribute("CurrentLevelID") or 0
	NodeLabelManager:addMetaIndicator(poste, nivelID)
end

--- Establece transparencia de techos
function MapManager:_setRoofsTransparency(alpha)
	local nivelModel = self:_getLevelModel(player:GetAttribute("CurrentLevelID") or 0, nil)
	if not nivelModel then return end

	local techosFolder = nivelModel:FindFirstChild("Techos")
	if not techosFolder then return end

	table.clear(techoOriginalTransparency)

	for _, techo in ipairs(techosFolder:GetChildren()) do
		if techo:IsA("BasePart") then
			techoOriginalTransparency[techo] = techo.Transparency
			techo.Transparency = alpha
			techo.CastShadow = false
		end
	end
end

--- Restaura transparencia original de techos
function MapManager:_restoreRoofs()
	for techo, trans in pairs(techoOriginalTransparency) do
		if techo and techo:IsA("BasePart") then
			techo.Transparency = trans
			techo.CastShadow = true
		end
	end
	table.clear(techoOriginalTransparency)
end

--- Retorna si el mapa está activo actualmente
function MapManager:isActive()
	return state ~= nil and state.mapaActivo == true
end

--- Restaura selectores a estado invisible
function MapManager:_restoreSelectors()
	local nivelModel = self:_getLevelModel(player:GetAttribute("CurrentLevelID") or 0, nil)
	if not nivelModel then return end

	local postesFolder = nivelModel:FindFirstChild("Objetos") and nivelModel.Objetos:FindFirstChild("Postes")
	if not postesFolder then return end

	for _, poste in ipairs(postesFolder:GetChildren()) do
		if poste:IsA("Model") then
			local selector = poste:FindFirstChild("Selector")
			if selector and selector:IsA("BasePart") then
				selector.Transparency = 1
				selector.Color = Color3.fromRGB(196, 196, 196)
				selector.Material = Enum.Material.Plastic

				local origSize = selector:GetAttribute("OriginalSize")
				if origSize then
					selector.Size = origSize
				end
			end
		end
	end
end

--- Obtiene modelo del nivel
function MapManager:_getLevelModel(nivelID, config)
	local nivelModel = workspace:FindFirstChild("NivelActual")
	if nivelModel then return nivelModel end

	if config then
		nivelModel = workspace:FindFirstChild(config.Modelo)
		if nivelModel then return nivelModel end
	end

	nivelModel = workspace:FindFirstChild("Nivel" .. nivelID)
	if nivelModel then return nivelModel end

	return workspace:FindFirstChild("Nivel" .. nivelID .. "_Tutorial")
end

--- Poblar etiquetas inmediatamente (similar al script original)
function MapManager:_populateLabels()
	local nivelID = player:GetAttribute("CurrentLevelID") or 0
	local config = LevelsConfig[nivelID] or LevelsConfig[0]
	local nivelModel = self:_getLevelModel(nivelID, config)

	if not nivelModel then 
		warn("⚠️ MapManager: No se encontró modelo de nivel para etiquetas")
		return 
	end

	local postesFolder = nivelModel:FindFirstChild("Objetos") and nivelModel.Objetos:FindFirstChild("Postes")
	if not postesFolder then
		warn("⚠️ MapManager: No se encontró carpeta de Postes")
		return
	end

	for _, poste in ipairs(postesFolder:GetChildren()) do
		if poste:IsA("Model") then
			-- Crear etiqueta inmediatamente
			if NodeLabelManager then
				NodeLabelManager:getLabelForNode(poste)
			end
		end
	end
end

-- ================================================================
-- LIMPIEZA
-- ================================================================

player.AncestryChanged:Connect(function(_, parent)
	if parent == nil then
		if camaraConnection then
			camaraConnection:Disconnect()
		end
		clearZoneHighlights()
	end
end)

return MapManager