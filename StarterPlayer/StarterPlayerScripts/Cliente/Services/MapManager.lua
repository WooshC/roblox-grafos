-- ================================================================
-- MapManager.lua
-- Gestiona activación/desactivación de vista de mapa
-- ================================================================

local MapManager = {}
MapManager.__index = MapManager

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

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

	print("✅ MapManager: Inicializado")
end

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

	-- Iniciar loop de cámara
	self:_startCameraLoop()

	print("✅ MapManager: Mapa activado")
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
    -- Si estamos en menú, VisibilityManager o la lógica de menú manejará la cámara
    -- Pero para salir de modo mapa, volvemos a Custom a menos que estemos en menú
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

	-- Detener loop de cámara
	if camaraConnection then
		camaraConnection:Disconnect()
		camaraConnection = nil
	end

	-- Restaurar selectores
	self:_restoreSelectors()

	print("✅ MapManager: Mapa desactivado")
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

    print("ℹ️ MapManager: Poblando etiquetas para " .. #postesFolder:GetChildren() .. " postes")

    for _, poste in ipairs(postesFolder:GetChildren()) do
        if poste:IsA("Model") then
             -- Crear etiqueta inmediatamente
             if NodeLabelManager then
                 NodeLabelManager:getLabelForNode(poste)
             end
        end
    end
end

return MapManager