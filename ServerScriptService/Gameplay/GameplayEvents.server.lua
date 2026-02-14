-- GameplayEvents_server.lua (REFACTORIZADO)
-- Usa los nuevos servicios: LevelService, EnergyService, UIService, AudioService, RewardService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- ============================================
-- CARGAR SERVICIOS
-- ============================================

-- Esperar servicios globales
repeat task.wait(0.1) until _G.Services

-- Servicios centralizados
local LevelService = _G.Services.Level
local GraphService = _G.Services.Graph
local EnergyService = _G.Services.Energy
local UIService = _G.Services.UI
local AudioService = _G.Services.Audio
local RewardService = _G.Services.Reward
local MisionManager = _G.Services.Misiones
local Enums = _G.Services.Enums

-- Validar que servicios existen
if not LevelService or not EnergyService or not GraphService then
	error("❌ CRÍTICO: Servicios no inicializados correctamente. Verifica Init.server.lua")
end

print("✅ GameplayEvents: Todos los servicios cargados")

-- ============================================
-- FUNCIONES LOCALES
-- ============================================

-- Actualizar luces de zonas cuando hay energía
local function actualizarLucesZonas(nivelID)
	if not LevelService:isLevelLoaded() then return end

	local nivel = LevelService:getCurrentLevel()
	if not nivel then return end

	local carpetaZonas = nivel:FindFirstChild("Zonas")
	if not carpetaZonas then return end

	-- Obtener nodos energizados desde EnergyService
	local startNode = LevelService:getStartNode()
	if not startNode then return end

	local energizados = EnergyService:calculateEnergy(startNode)

	-- Activar/desactivar componentes de cada zona
	for _, zona in ipairs(carpetaZonas:GetChildren()) do
		if zona:IsA("Folder") and string.match(zona.Name, "^Zona") then
			local componentesFolder = zona:FindFirstChild("ComponentesEnergeticos")
			if componentesFolder then
				-- Verificar si hay nodos energizados en esta zona
				local zonaActiva = false

				local config = LevelService:getLevelConfig()
				if config and config.Nodos then
					for nodeName, nodoData in pairs(config.Nodos) do
						if nodoData.Zona and string.match(zona.Name, nodoData.Zona) then
							if energizados[nodeName] then
								zonaActiva = true
								break
							end
						end
					end
				end

				-- Activar/desactivar luces, particles, beams
				for _, componente in ipairs(componentesFolder:GetDescendants()) do
					if componente:IsA("Light") or componente:IsA("ParticleEmitter") or componente:IsA("Beam") then
						componente.Enabled = zonaActiva
					elseif componente:IsA("BasePart") and componente.Material == Enum.Material.Neon then
						componente.Material = zonaActiva and Enum.Material.Neon or Enum.Material.Plastic
					end
				end
			end
		end
	end
end

-- Pintar cables según su estado de energía
local function pintarCablesSegunEnergia()
	if not LevelService:isLevelLoaded() then return end

	local nivel = LevelService:getCurrentLevel()
	if not nivel then return end

	local startNode = LevelService:getStartNode()
	local endNode = LevelService:getEndNode()

	if not startNode then return end

	-- Obtener nodos energizados
	local energizados = EnergyService:calculateEnergy(startNode)
	local llegoAlFinal = energizados[endNode.Name] == true

	-- Obtener cables desde GraphService
	local cables = GraphService:getCables()

	-- Pintar cada cable
	for cableKey, cableInfo in pairs(cables) do
		if cableInfo.cableInstance and cableInfo.cableInstance:IsA("RopeConstraint") then
			local cable = cableInfo.cableInstance
			local nodoA = cableInfo.nodeA.Name
			local nodoB = cableInfo.nodeB.Name

			-- Verificar si ambos nodos están energizados
			local ambosEnergizados = energizados[nodoA] and energizados[nodoB]

			if ambosEnergizados then
				if llegoAlFinal then
					cable.Color = BrickColor.new("Lime green")  -- Verde lime si llegó al final
				else
					cable.Color = BrickColor.new("Cyan")  -- Cyan si está energizado pero sin llegar al final
				end
				cable.Thickness = 0.3
			else
				cable.Color = BrickColor.new("Black")  -- Negro si no está energizado
				cable.Thickness = 0.2
			end
		end
	end

	print("🎨 Cables pintados según energía")
end

-- Verificar conectividad y actualizar misiones
local function verificarYActualizarMisiones()
	if not LevelService:isLevelLoaded() then return end

	local nivelID = LevelService:getCurrentLevelID()
	local config = LevelService:getLevelConfig()
	local startNode = LevelService:getStartNode()

	if not startNode or not config then return end

	-- Obtener nodos energizados usando EnergyService
	local energizados = EnergyService:calculateEnergy(startNode)

	-- Construir estado del juego
	local numNodosEnergizados = 0
	for _, _ in pairs(energizados) do
		numNodosEnergizados = numNodosEnergizados + 1
	end

	local estadoJuego = {
		nodosVisitados = energizados,
		numNodosConectados = numNodosEnergizados,
		circuitoCerrado = energizados[config.NodoFin] == true,
		dineroRestante = 0,
		dineroInicial = config.DineroInicial,
		numConexiones = 0,
		zonasActivas = {}
	}

	-- Obtener dinero restante del jugador actual
	local players = Players:GetPlayers()
	if #players > 0 then
		local player = players[1]
		if player and player:FindFirstChild("leaderstats") then
			local moneyValue = player.leaderstats:FindFirstChild("Money")
			if moneyValue then
				estadoJuego.dineroRestante = moneyValue.Value
			end
		end
	end

	-- Verificar todas las misiones usando MisionManager
	if MisionManager then
		local resultados = MisionManager.verificarTodasLasMisiones(config, estadoJuego)

		-- Actualizar misiones para todos los jugadores
		for misionID, completada in pairs(resultados) do
			MisionManager.actualizarMisionGlobal(misionID, completada)
		end

		print("📋 Misiones verificadas: " .. tostring(resultados))
	end

	-- Actualizar UI
	if UIService then
		UIService:updateProgress()
		UIService:updateEnergyStatus()
	end
end

-- ============================================
-- EVENTOS DE NIVEL
-- ============================================

-- Cuando se carga un nivel
if LevelService then
	LevelService:onLevelLoaded(function(nivelID, levelFolder, config)
		print("🎮 Nivel " .. nivelID .. " cargado: " .. config.Nombre)

		-- Teletransportar jugadores al spawn del nuevo nivel
		local NivelUtils = require(ReplicatedStorage:WaitForChild("Utilidades"):WaitForChild("NivelUtils"))
		local spawnPos = NivelUtils.obtenerPosicionSpawn(nivelID)

		if spawnPos then
			print("📍 Teletransportando jugadores a: " .. tostring(spawnPos))
			for _, player in ipairs(Players:GetPlayers()) do
				local char = player.Character
				if char then
					char:PivotTo(CFrame.new(spawnPos))
				end
			end
		else
			warn("⚠️ No se encontró punto de spawn para Nivel " .. nivelID)
		end

		-- Inicializar luces
		task.wait(0.5)
		actualizarLucesZonas(nivelID)

		-- Reproducir música si AudioService existe
		if AudioService then
			local musicName = "Level_" .. nivelID .. "_BGM"
			AudioService:playBGM(musicName, true, 1.0)
		end

		-- Actualizar UI completamente
		if UIService then
			UIService:updateAll()
		end
	end)

	LevelService:onLevelReset(function(nivelID)
		print("🔄 Nivel " .. nivelID .. " reseteado")

		-- Resetear UI
		if UIService then
			UIService:notifyLevelReset()
			UIService:updateAll()
		end
	end)
end

-- Cuando hay cambio en conexiones (desde GraphService)
if GraphService then
	GraphService:onConnectionChanged(function(action, nodeA, nodeB)
		print("🔌 Conexión cambió: " .. action .. " (" .. nodeA.Name .. " - " .. nodeB.Name .. ")")

		-- Reproducir sonido si AudioService existe
		if AudioService then
			if action == "connected" then
				AudioService:playCableConnected()
				AudioService:playEnergyFlow()
			elseif action == "disconnected" then
				AudioService:playCableDisconnected()
			end
		end

		-- Recalcular energía y misiones
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

	-- Inicializar en MisionManager
	if MisionManager and MisionManager.inicializarJugador then
		MisionManager.inicializarJugador(player)
	end

	-- Inicializar UI para jugador
	if UIService then
		UIService:initializePlayerUI(player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	print("👤 Jugador desconectado: " .. player.Name)

	-- Limpiar en MisionManager
	if MisionManager and MisionManager.limpiarJugador then
		MisionManager.limpiarJugador(player)
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

		-- Usar RewardService para dar todas las recompensas
		if RewardService then
			local recompensas = RewardService:giveCompletionRewards(player, nivelID)

			print("✅ Recompensas dadas:")
			print("   ⭐ Estrellas: " .. recompensas.stars)
			print("   ⭐ XP: " .. recompensas.xp)
			print("   💰 Dinero: $" .. recompensas.money)
		end

		-- Actualizar UI
		if UIService then
			UIService:notifyLevelComplete()
		end

		-- Reproducir sonido de victoria
		if AudioService then
			AudioService:playVictoryMusic()
		end

		-- Volver a menú
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

print("⚡ GameplayEvents (REFACTORIZADO) cargado exitosamente")
print("   ✅ Usa: LevelService, GraphService, EnergyService")
print("   ✅ Usa: UIService, AudioService, RewardService")