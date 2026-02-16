-- GameplayEvents_server.lua (REFACTORIZADO)
-- Zonas se activan por NodosRequeridos con conexiones, o por energía según nivel

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

task.wait(1)

local LevelService = _G.Services.Level
local GraphService = _G.Services.Graph
local EnergyService = _G.Services.Energy
local UIService = _G.Services.UI
local AudioService = _G.Services.Audio
local RewardService = _G.Services.Reward
local MissionService = _G.Services.Mission
local Enums = _G.Services.Enums

if not LevelService or not GraphService then
	error("❌ CRÍTICO: Servicios no inicializados")
end

print("✅ GameplayEvents cargado")

-- ============================================
-- BÚSQUEDA DE ZONAS EN WORKSPACE
-- ============================================

local function obtenerCarpetaZonas(nivel)
	if not nivel then return nil end
	local zonas = nivel:FindFirstChild("Zonas")
	if zonas and zonas:IsA("Folder") then return zonas end
	local objetos = nivel:FindFirstChild("Objetos")
	if objetos then
		zonas = objetos:FindFirstChild("Zonas")
		if zonas and zonas:IsA("Folder") then return zonas end
	end
	for _, child in ipairs(nivel:GetDescendants()) do
		if child.Name == "Zonas" and child:IsA("Folder") then return child end
	end
	return nil
end

-- ============================================
-- DETERMINAR SI ZONA ESTÁ ACTIVA
-- Usa NodosRequeridos si existen, sino energía
-- ============================================

local function determinarZonaActiva(zonaID, config, energizados)
	local zonaConfig = config.Zonas and config.Zonas[zonaID]
	if not zonaConfig then return false end

	local modoZona = zonaConfig.Modo or "ANY"

	-- PRIORIDAD: Si la zona tiene NodosRequeridos, verificar por conexiones
	local nodosReq = zonaConfig.NodosRequeridos
	if nodosReq and #nodosReq > 0 then
		local conConexion = 0
		for _, nodoNombre in ipairs(nodosReq) do
			local poste = LevelService:getPoste(nodoNombre)
			if poste and GraphService:hasConnections(poste) then
				conConexion = conConexion + 1
			end
		end

		if modoZona == "ALL" then
			return conConexion == #nodosReq
		else
			return conConexion > 0
		end
	end

	-- FALLBACK: Verificar por energía (niveles normales)
	local nodosDeZona = {}
	if config.Nodos then
		for nodeName, nodoData in pairs(config.Nodos) do
			if nodoData.Zona == zonaID then
				table.insert(nodosDeZona, nodeName)
			end
		end
	end

	local nodosEnergizados = 0
	for _, nodeName in ipairs(nodosDeZona) do
		if energizados[nodeName] then
			nodosEnergizados = nodosEnergizados + 1
		end
	end

	if modoZona == "ALL" then
		return nodosEnergizados == #nodosDeZona and #nodosDeZona > 0
	else
		return nodosEnergizados > 0
	end
end

-- ============================================
-- ACTUALIZAR LUCES DE ZONAS
-- ============================================

local function actualizarLucesZonas(nivelID)
	if not LevelService:isLevelLoaded() then return end
	local nivel = LevelService:getCurrentLevel()
	if not nivel then return end
	local carpetaZonas = obtenerCarpetaZonas(nivel)
	if not carpetaZonas then return end
	local config = LevelService:getLevelConfig()
	if not config then return end

	-- Energía (para niveles que la usan)
	local energizados = {}
	local startNode = LevelService:getStartNode()
	if startNode and EnergyService then
		energizados = EnergyService:calculateEnergy(startNode)
	end

	for _, zona in ipairs(carpetaZonas:GetChildren()) do
		if zona:IsA("Folder") and string.match(zona.Name, "^Zona") then
			local zonaActiva = determinarZonaActiva(zona.Name, config, energizados)

			-- Actualizar componentes visuales
			local componentesFolder = zona:FindFirstChild("ComponentesEnergeticos") or zona
			for _, comp in ipairs(componentesFolder:GetDescendants()) do
				local esDeZona = comp:FindFirstAncestor(zona.Name) ~= nil
				if esDeZona then
					if comp:IsA("Light") then comp.Enabled = zonaActiva end
					if comp:IsA("ParticleEmitter") then comp.Enabled = zonaActiva end
					if comp:IsA("Beam") then comp.Enabled = zonaActiva end
					if comp:IsA("BasePart") and comp.Material == Enum.Material.Neon then
						comp.Material = zonaActiva and Enum.Material.Neon or Enum.Material.Plastic
					end
				end
			end
		end
	end
end

-- ============================================
-- PINTAR CABLES
-- ============================================

local function pintarCables()
	if not LevelService:isLevelLoaded() then return end
	local config = LevelService:getLevelConfig()
	if not config then return end

	local cables = GraphService:getCables()

	-- Sin costo = cables verdes directamente
	if (config.CostoPorMetro or 0) == 0 then
		for _, info in pairs(cables) do
			if info.cableInstance and info.cableInstance:IsA("RopeConstraint") then
				info.cableInstance.Color = BrickColor.new("Lime green")
				info.cableInstance.Thickness = 0.25
			end
		end
		return
	end

	-- Con energía
	local startNode = LevelService:getStartNode()
	local endNode = LevelService:getEndNode()
	if not startNode then return end

	local energizados = EnergyService:calculateEnergy(startNode)
	local llegoAlFinal = endNode and energizados[endNode.Name] == true

	for _, info in pairs(cables) do
		if info.cableInstance and info.cableInstance:IsA("RopeConstraint") then
			local cable = info.cableInstance
			local ambos = energizados[info.nodeA.Name] and energizados[info.nodeB.Name]
			if ambos then
				cable.Color = llegoAlFinal and BrickColor.new("Lime green") or BrickColor.new("Cyan")
				cable.Thickness = 0.3
			else
				cable.Color = BrickColor.new("Black")
				cable.Thickness = 0.2
			end
		end
	end
end

-- ============================================
-- EVENTOS
-- ============================================

if LevelService then
	LevelService:onLevelLoaded(function(nivelID, levelFolder, config)
		print("🎮 Nivel " .. nivelID .. " cargado: " .. config.Nombre)
		task.wait(0.5)
		actualizarLucesZonas(nivelID)
		if AudioService then AudioService:playBGM("Level_" .. nivelID .. "_BGM", true, 1.0) end
		if UIService then UIService:updateAll() end
	end)

	LevelService:onLevelReset(function(nivelID)
		actualizarLucesZonas(nivelID)
		if UIService then UIService:notifyLevelReset(); UIService:updateAll() end
	end)
end

if GraphService then
	GraphService:onConnectionChanged(function(action, nodeA, nodeB)
		if AudioService then
			if action == "connected" then AudioService:playCableConnected()
			else AudioService:playCableDisconnected() end
		end
		task.wait(0.2)
		pintarCables()
		actualizarLucesZonas(LevelService:getCurrentLevelID())
		-- MissionService se actualiza via Init.server.lua hook
	end)
end

-- Jugadores
Players.PlayerAdded:Connect(function(player)
	if MissionService and MissionService.initializePlayer then MissionService:initializePlayer(player) end
	if UIService then UIService:initializePlayerUI(player) end
end)

Players.PlayerRemoving:Connect(function(player)
	if MissionService and MissionService.clearPlayer then MissionService:clearPlayer(player) end
end)

-- Finalizar nivel
local Remotes = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes")
local LevelCompletedEvent = Remotes:FindFirstChild("LevelCompleted")

if LevelCompletedEvent then
	LevelCompletedEvent.OnServerEvent:Connect(function(player, nivelID, estrellas, puntos)
		print("🏆 " .. player.Name .. " completó Nivel " .. nivelID)
		if RewardService then RewardService:giveCompletionRewards(player, nivelID) end
		if UIService then UIService:notifyLevelComplete() end
		if AudioService then AudioService:playVictoryMusic() end

		-- Notificar al cliente (Menú / Victoria)
		if LevelCompletedEvent then
			LevelCompletedEvent:FireClient(player, nivelID, estrellas, puntos)
		end
		
		-- Intentar avisar a otros scripts del server (opcional)
		local Bindables = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Bindables")
		local OpenMenuEvent = Bindables:FindFirstChild("OpenMenu")
		if OpenMenuEvent then
			OpenMenuEvent:Fire()
		end
	end)
end

print("⚡ GameplayEvents (REFACTORIZADO) cargado")