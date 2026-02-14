-- GameplayEvents_server.lua (VERSIÓN FINAL CON RESPETO A MODO ALL/ANY)
-- Respeta la configuración Zonas.Modo para determinar si se enciende o no

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- ============================================
-- CARGAR SERVICIOS
-- ============================================

task.wait(1)

local LevelService = _G.Services.Level
local GraphService = _G.Services.Graph
local EnergyService = _G.Services.Energy
local UIService = _G.Services.UI
local AudioService = _G.Services.Audio
local RewardService = _G.Services.Reward
local MissionService = _G.Services.Mission
local Enums = _G.Services.Enums

if not LevelService or not EnergyService or not GraphService then
	error("❌ CRÍTICO: Servicios no inicializados correctamente. Verifica Init.server.lua")
end

print("✅ GameplayEvents: Todos los servicios cargados")

-- ============================================
-- BÚSQUEDA UNIVERSAL DE ZONAS
-- ============================================

local function obtenerCarpetaZonas(nivel)
	if not nivel then return nil end

	-- Prioridad 1: Nivel/Zonas
	local zonas = nivel:FindFirstChild("Zonas")
	if zonas and zonas:IsA("Folder") then
		return zonas
	end

	-- Prioridad 2: Nivel/Objetos/Zonas
	local objetos = nivel:FindFirstChild("Objetos")
	if objetos then
		zonas = objetos:FindFirstChild("Zonas")
		if zonas and zonas:IsA("Folder") then
			return zonas
		end
	end

	-- Prioridad 3: Búsqueda recursiva
	for _, child in ipairs(nivel:GetDescendants()) do
		if child.Name == "Zonas" and child:IsA("Folder") then
			return child
		end
	end

	return nil
end

-- ============================================
-- 🔥 FUNCIÓN PRINCIPAL - RESPETA MODO ALL/ANY
-- ============================================

local function actualizarLucesZonas(nivelID)
	if not LevelService:isLevelLoaded() then return end

	local nivel = LevelService:getCurrentLevel()
	if not nivel then return end

	local carpetaZonas = obtenerCarpetaZonas(nivel)
	if not carpetaZonas then return end

	-- Obtener nodos energizados desde EnergyService
	local startNode = LevelService:getStartNode()
	if not startNode then return end

	local energizados = EnergyService:calculateEnergy(startNode)

	-- Obtener configuración del nivel
	local config = LevelService:getLevelConfig()
	if not config or not config.Nodos then return end

	print("\n⚡ === ACTUALIZAR LUCES (RESPETANDO MODO ALL/ANY) ===")

	-- 🔥 PROCESAR CADA ZONA INDEPENDIENTEMENTE
	for _, zona in ipairs(carpetaZonas:GetChildren()) do
		if zona:IsA("Folder") and string.match(zona.Name, "^Zona") then
			print("\n🔆 Procesando " .. zona.Name .. "...")

			-- ✅ PASO 1: Identificar qué nodos pertenecen a ESTA zona
			local nodosDeEstaZona = {}
			for nodeName, nodoData in pairs(config.Nodos) do
				if nodoData.Zona == zona.Name then
					table.insert(nodosDeEstaZona, nodeName)
				end
			end

			-- ✅ PASO 2: OBTENER CONFIGURACIÓN DE MODO (ALL o ANY)
			local modoZona = "ANY"  -- Default
			if config.Zonas and config.Zonas[zona.Name] then
				modoZona = config.Zonas[zona.Name].Modo or "ANY"
			end

			print("  Modo: " .. modoZona)
			print("  Nodos en esta zona: " .. table.concat(nodosDeEstaZona, ", "))

			-- ✅ PASO 3: Verificar qué nodos están energizados
			local nodosEnergizadosEnZona = {}
			for _, nodeName in ipairs(nodosDeEstaZona) do
				if energizados[nodeName] then
					table.insert(nodosEnergizadosEnZona, nodeName)
				end
			end

			print("  Nodos energizados: " .. table.concat(nodosEnergizadosEnZona, ", ") .. " / " .. #nodosDeEstaZona)

			-- ✅ PASO 4: DETERMINAR SI LA ZONA SE ACTIVA (RESPETANDO MODO)
			local zonaActiva = false

			if modoZona == "ALL" then
				-- 🔥 TODOS los nodos deben estar energizados
				zonaActiva = (#nodosEnergizadosEnZona == #nodosDeEstaZona) and #nodosDeEstaZona > 0
				print("  Lógica: TODOS los nodos deben estar energizados")
				print("  Resultado: " .. (#nodosEnergizadosEnZona) .. " / " .. #nodosDeEstaZona .. " = " .. (zonaActiva and "✅ ACTIVA" or "❌ INACTIVA"))

			elseif modoZona == "ANY" then
				-- 🔥 CUALQUIER nodo energizado activa
				zonaActiva = #nodosEnergizadosEnZona > 0
				print("  Lógica: CUALQUIER nodo energizado activa")
				print("  Resultado: " .. (#nodosEnergizadosEnZona > 0 and "✅ ACTIVA" or "❌ INACTIVA"))
			end

			-- ✅ PASO 5: Buscar carpeta de componentes
			local componentesFolder = zona:FindFirstChild("ComponentesEnergeticos")
			if not componentesFolder then
				componentesFolder = zona
			end

			-- ✅ PASO 6: ACTUALIZAR SOLO LOS COMPONENTES DE ESTA ZONA
			local componentesActualizados = 0
			for _, componente in ipairs(componentesFolder:GetDescendants()) do
				local esDeEstaZona = false
				local ancestro = componente:FindFirstAncestor(zona.Name)
				if ancestro and ancestro.Name == zona.Name then
					esDeEstaZona = true
				end

				if esDeEstaZona then
					-- Luces
					if componente:IsA("Light") then
						componente.Enabled = zonaActiva
						componentesActualizados = componentesActualizados + 1
						if zonaActiva then
							print("  📍 Light '" .. componente.Parent.Name .. "/" .. componente.Name .. "' → ON")
						else
							print("  📍 Light '" .. componente.Parent.Name .. "/" .. componente.Name .. "' → OFF")
						end
					end

					-- Partículas
					if componente:IsA("ParticleEmitter") then
						componente.Enabled = zonaActiva
						componentesActualizados = componentesActualizados + 1
						if zonaActiva then
							print("  💨 Particle '" .. componente.Parent.Name .. "/" .. componente.Name .. "' → ON")
						end
					end

					-- Beams
					if componente:IsA("Beam") then
						componente.Enabled = zonaActiva
						componentesActualizados = componentesActualizados + 1
					end

					-- Partes Neon
					if componente:IsA("BasePart") and componente.Material == Enum.Material.Neon then
						if zonaActiva then
							componente.Material = Enum.Material.Neon
						else
							componente.Material = Enum.Material.Plastic
						end
						componentesActualizados = componentesActualizados + 1
					end
				end
			end

			print("  ✅ Actualizados: " .. componentesActualizados .. " componentes")
		end
	end

	print("\n✅ === FIN ACTUALIZACIÓN ===\n")
end

-- Pintar cables según su estado de energía
local function pintarCablesSegunEnergia()
	if not LevelService:isLevelLoaded() then return end

	local nivel = LevelService:getCurrentLevel()
	if not nivel then return end

	local startNode = LevelService:getStartNode()
	local endNode = LevelService:getEndNode()

	if not startNode then return end

	local energizados = EnergyService:calculateEnergy(startNode)
	local llegoAlFinal = energizados[endNode.Name] == true

	local cables = GraphService:getCables()

	for cableKey, cableInfo in pairs(cables) do
		if cableInfo.cableInstance and cableInfo.cableInstance:IsA("RopeConstraint") then
			local cable = cableInfo.cableInstance
			local nodoA = cableInfo.nodeA.Name
			local nodoB = cableInfo.nodeB.Name

			local ambosEnergizados = energizados[nodoA] and energizados[nodoB]

			if ambosEnergizados then
				if llegoAlFinal then
					cable.Color = BrickColor.new("Lime green")
				else
					cable.Color = BrickColor.new("Cyan")
				end
				cable.Thickness = 0.3
			else
				cable.Color = BrickColor.new("Black")
				cable.Thickness = 0.2
			end
		end
	end
end

-- Verificar conectividad y actualizar misiones
local function verificarYActualizarMisiones()
	if not LevelService:isLevelLoaded() then return end

	local nivelID = LevelService:getCurrentLevelID()
	local config = LevelService:getLevelConfig()
	local startNode = LevelService:getStartNode()

	if not startNode or not config then return end

	local energizados = EnergyService:calculateEnergy(startNode)

	if MissionService then
		local numNodosEnergizados = 0
		for _, _ in pairs(energizados) do
			numNodosEnergizados = numNodosEnergizados + 1
		end

		for _, player in ipairs(Players:GetPlayers()) do
			local estadoJuegoJugador = MissionService:buildGameState(player, energizados, numNodosEnergizados, energizados[config.NodoFin] == true, {})
			MissionService:checkMissions(player, estadoJuegoJugador)
		end
	end

	if UIService then
		UIService:updateProgress()
		UIService:updateEnergyStatus()
	end
end

-- ============================================
-- EVENTOS DE NIVEL
-- ============================================

if LevelService then
	LevelService:onLevelLoaded(function(nivelID, levelFolder, config)
		print("🎮 Nivel " .. nivelID .. " cargado: " .. config.Nombre)

		task.wait(0.5)
		actualizarLucesZonas(nivelID)

		if AudioService then
			local musicName = "Level_" .. nivelID .. "_BGM"
			AudioService:playBGM(musicName, true, 1.0)
		end

		if UIService then
			UIService:updateAll()
		end
	end)

	LevelService:onLevelReset(function(nivelID)
		print("🔄 Nivel " .. nivelID .. " reseteado")
		actualizarLucesZonas(nivelID)

		if UIService then
			UIService:notifyLevelReset()
			UIService:updateAll()
		end
	end)
end

if GraphService then
	GraphService:onConnectionChanged(function(action, nodeA, nodeB)
		print("🔌 Conexión cambió: " .. action .. " (" .. nodeA.Name .. " - " .. nodeB.Name .. ")")

		if AudioService then
			if action == "connected" then
				AudioService:playCableConnected()
				AudioService:playEnergyFlow()
			elseif action == "disconnected" then
				AudioService:playCableDisconnected()
			end
		end

		task.wait(0.2)
		pintarCablesSegunEnergia()
		actualizarLucesZonas(LevelService:getCurrentLevelID())
		verificarYActualizarMisiones()
	end)
end

-- ============================================
-- GESTIÓN DE JUGADORES
-- ============================================

Players.PlayerAdded:Connect(function(player)
	print("👤 Jugador conectado: " .. player.Name)

	if MissionService and MissionService.initializePlayer then
		MissionService:initializePlayer(player)
	end

	if UIService then
		UIService:initializePlayerUI(player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	print("👤 Jugador desconectado: " .. player.Name)

	if MissionService and MissionService.clearPlayer then
		MissionService:clearPlayer(player)
	end
end)

-- ============================================
-- EVENTO: FINALIZAR NIVEL
-- ============================================

local Remotes = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes")
local LevelCompletedEvent = Remotes:FindFirstChild("LevelCompleted")

if LevelCompletedEvent then
	LevelCompletedEvent.OnServerEvent:Connect(function(player, nivelID, estrellas, puntosTotalConBono)
		print("🏆 Jugador " .. player.Name .. " completó Nivel " .. nivelID)

		if RewardService then
			local recompensas = RewardService:giveCompletionRewards(player, nivelID)
		end

		if UIService then
			UIService:notifyLevelComplete()
		end

		if AudioService then
			AudioService:playVictoryMusic()
		end

		task.wait(2)
		local Bindables = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Bindables")
		local OpenMenuEvent = Bindables:FindFirstChild("OpenMenu")
		if OpenMenuEvent then
			OpenMenuEvent:Fire()
			LevelCompletedEvent:FireClient(player, nivelID, estrellas, puntosTotalConBono)
		end

		print("🎉 Nivel " .. nivelID .. " completado y recompensas otorgadas")
	end)

	print("✅ Listener LevelCompleted registrado")
else
	warn("❌ Evento LevelCompleted no encontrado")
end

-- ============================================
-- INICIALIZACIÓN
-- ============================================

print("⚡ GameplayEvents (FINAL - CON MODO ALL/ANY) cargado exitosamente")
print("   ✅ Respeta config.Zonas.Modo")
print("   ✅ Modo ALL: Todos los nodos deben estar energizados")
print("   ✅ Modo ANY: Cualquier nodo energizado activa la zona")