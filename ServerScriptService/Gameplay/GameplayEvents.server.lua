-- GameplayEvents_server.lua (VERSIÓN FINAL - ENCUENTRA ZONAS EN CUALQUIER ESTRUCTURA)
-- Usa los nuevos servicios: LevelService, EnergyService, UIService, AudioService, RewardService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- ============================================
-- CARGAR SERVICIOS
-- ============================================

-- Esperar a que Init.server.lua haya cargado los servicios
task.wait(1)

-- Servicios centralizados
local LevelService = _G.Services.Level
local GraphService = _G.Services.Graph
local EnergyService = _G.Services.Energy
local UIService = _G.Services.UI
local AudioService = _G.Services.Audio
local RewardService = _G.Services.Reward
local MissionService = _G.Services.Mission
local Enums = _G.Services.Enums

-- Validar que servicios existen
if not LevelService or not EnergyService or not GraphService then
	error("❌ CRÍTICO: Servicios no inicializados correctamente. Verifica Init.server.lua")
end

print("✅ GameplayEvents: Todos los servicios cargados")

-- ============================================
-- FUNCIONES LOCALES
-- ============================================

-- ✅ BÚSQUEDA UNIVERSAL DE ZONAS (Cualquier estructura)
local function obtenerCarpetaZonas(nivel)
	if not nivel then return nil end

	-- Prioridad 1: Nivel/Zonas (ESTRUCTURA ACTUAL - Tu caso)
	local zonas = nivel:FindFirstChild("Zonas")
	if zonas and zonas:IsA("Folder") then
		print("  📂 Zonas encontrada en: " .. nivel.Name .. "/Zonas")
		return zonas
	end

	-- Prioridad 2: Nivel/Objetos/Zonas (Estructura alternativa)
	local objetos = nivel:FindFirstChild("Objetos")
	if objetos then
		zonas = objetos:FindFirstChild("Zonas")
		if zonas and zonas:IsA("Folder") then
			print("  📂 Zonas encontrada en: " .. nivel.Name .. "/Objetos/Zonas")
			return zonas
		end
	end

	-- Prioridad 3: Buscar recursivamente en cualquier lugar
	for _, child in ipairs(nivel:GetDescendants()) do
		if child.Name == "Zonas" and child:IsA("Folder") then
			print("  📂 Zonas encontrada en: " .. child:GetFullName())
			return child
		end
	end

	print("  ⚠️  Carpeta Zonas NO encontrada en nivel " .. nivel.Name)
	return nil
end

-- Actualizar luces de zonas cuando hay energía
local function actualizarLucesZonas(nivelID)
	if not LevelService:isLevelLoaded() then 
		-- print("⚠️ GameplayEvents: Nivel no cargado")
		return 
	end

	local nivel = LevelService:getCurrentLevel()
	if not nivel then 
		print("⚠️ GameplayEvents: No hay nivel cargado para actualizar luces")
		return 
	end

	-- ✅ USAR FUNCIÓN UNIVERSAL DE BÚSQUEDA
	local carpetaZonas = obtenerCarpetaZonas(nivel)

	-- Si no existe carpeta de zonas, salir silenciosamente
	if not carpetaZonas then 
		return 
	end

	-- Obtener nodos energizados desde EnergyService
	local startNode = LevelService:getStartNode()
	if not startNode then 
		print("⚠️ GameplayEvents: No hay nodo de inicio")
		return 
	end

	local energizados = EnergyService:calculateEnergy(startNode)

	-- Obtener configuración del nivel
	local config = LevelService:getLevelConfig()
	if not config then 
		print("⚠️ GameplayEvents: No hay configuración del nivel")
		return 
	end

	print("⚡ GameplayEvents: Actualizando " .. #carpetaZonas:GetChildren() .. " zonas (" .. 
		table.concat(require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"):WaitForChild("GraphUtils")).bfs(startNode, GraphService:getCables()) and (function() 
			local keys = {} 
			for k in pairs(energizados) do table.insert(keys, k) end 
			return keys 
		end)() or {}, ", ") .. ")")

	-- Activar/desactivar componentes de cada zona
	for _, zona in ipairs(carpetaZonas:GetChildren()) do
		if zona:IsA("Folder") and string.match(zona.Name, "^Zona") then
			-- ✅ BÚSQUEDA FLEXIBLE DE COMPONENTES
			-- Opción A: ComponentesEnergeticos
			local componentesFolder = zona:FindFirstChild("ComponentesEnergeticos")
			
			-- Opción B: Si no existe, usar la zona misma como contenedor
			if not componentesFolder then
				componentesFolder = zona
			end

			if componentesFolder then
				-- Verificar si hay nodos energizados en esta zona
				local zonaActiva = false
				local nodosEnZona = {}

				if config.Nodos then
					-- Buscar nodos que pertenecen a esta zona
					for nodeName, nodoData in pairs(config.Nodos) do
						if nodoData.Zona == zona.Name then
							table.insert(nodosEnZona, nodeName)
							-- Verificar si este nodo está energizado
							if energizados[nodeName] then
								zonaActiva = true
							end
						end
					end
				end

				-- DEBUG: Mostrar estado
				if #nodosEnZona > 0 then
					local estado = zonaActiva and "✅ ACTIVA" or "❌ inactiva"
					print("  🔆 " .. zona.Name .. ": " .. #nodosEnZona .. " nodos | " .. estado)
				end

				-- ✅ ACTIVAR/DESACTIVAR TODOS LOS COMPONENTES
				for _, componente in ipairs(componentesFolder:GetDescendants()) do
					-- Luces
					if componente:IsA("Light") then
						componente.Enabled = zonaActiva
					end
					
					-- Partículas
					if componente:IsA("ParticleEmitter") then
						componente.Enabled = zonaActiva
					end
					
					-- Beams
					if componente:IsA("Beam") then
						componente.Enabled = zonaActiva
					end
					
					-- Partes Neon (cambiar material)
					if componente:IsA("BasePart") and componente.Material == Enum.Material.Neon then
						if zonaActiva then
							componente.Material = Enum.Material.Neon
						else
							componente.Material = Enum.Material.Plastic
						end
					end
				end
			end
		end
	end

	-- print("✅ GameplayEvents: Luces de zonas actualizadas")
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

	-- Verificar todas las misiones usando MissionService
	if MissionService then
		-- Recalcular numNodosEnergizados
		local numNodosEnergizados = 0
		for _, _ in pairs(energizados) do
			numNodosEnergizados = numNodosEnergizados + 1
		end

		-- Iterar sobre todos los jugadores para actualizar sus misiones individualmente
		for _, player in ipairs(Players:GetPlayers()) do
			-- Construir estado del juego usando MissionService
			local estadoJuegoJugador = MissionService:buildGameState(player, energizados, numNodosEnergizados, energizados[config.NodoFin] == true, {})
			
			MissionService:checkMissions(player, estadoJuegoJugador)
		end
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

		-- Inicializar luces (primero apagadas)
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

		-- Apagar todas las luces al resetear
		actualizarLucesZonas(nivelID)

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

	-- Inicializar en MissionService
	if MissionService and MissionService.initializePlayer then
		MissionService:initializePlayer(player)
	end

	-- Inicializar UI para jugador
	if UIService then
		UIService:initializePlayerUI(player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	print("👤 Jugador desconectado: " .. player.Name)

	-- Limpiar en MissionService
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

		-- Usar RewardService para dar todas las recompensas
		if RewardService then
			local recompensas = RewardService:giveCompletionRewards(player, nivelID)
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

print("⚡ GameplayEvents (FINAL) cargado exitosamente")
print("   ✅ Busca Zonas en CUALQUIER estructura")
print("   ✅ Prioridad 1: Nivel/Zonas")
print("   ✅ Prioridad 2: Nivel/Objetos/Zonas")
print("   ✅ Prioridad 3: Búsqueda recursiva")