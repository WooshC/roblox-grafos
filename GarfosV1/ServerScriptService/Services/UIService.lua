-- ServerScriptService/Services/UIService.lua
-- SERVICIO CENTRALIZADO para gestión de actualización de UI
-- Sincroniza UI del cliente con estado del servidor

local UIService = {}
UIService.__index = UIService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums"))

-- Estado interno
local levelService = nil
local graphService = nil
local energyService = nil
local algorithmService = nil

-- Referencias a eventos
local updateUIEvent = nil

-- Eventos internos
local uiUpdatedEvent = Instance.new("BindableEvent")

-- ============================================
-- INICIALIZACIÓN
-- ============================================

function UIService:init()
	-- Garantizar estructura de eventos
	local Events = ReplicatedStorage:FindFirstChild("Events")
	if not Events then
		Events = Instance.new("Folder")
		Events.Name = "Events"
		Events.Parent = ReplicatedStorage
	end

	local Remotes = Events:FindFirstChild("Remotes")
	if not Remotes then
		Remotes = Instance.new("Folder")
		Remotes.Name = "Remotes"
		Remotes.Parent = Events
	end

	-- 1. ActualizarUI (Principal)
	updateUIEvent = Remotes:FindFirstChild("ActualizarUI")
	if not updateUIEvent then
		updateUIEvent = Instance.new("RemoteEvent")
		updateUIEvent.Name = "ActualizarUI"
		updateUIEvent.Parent = Remotes
		print("✅ UIService: Evento ActualizarUI creado")
	end

	-- 2. Visual Effects Remotes (Soporte para VisualEffects.client.lua)
	local pulseEvent = Remotes:FindFirstChild("PulseEvent")
	if not pulseEvent then
		pulseEvent = Instance.new("RemoteEvent")
		pulseEvent.Name = "PulseEvent"
		pulseEvent.Parent = Remotes
	end

	local cableDragEvent = Remotes:FindFirstChild("CableDragEvent")
	if not cableDragEvent then
		cableDragEvent = Instance.new("RemoteEvent")
		cableDragEvent.Name = "CableDragEvent"
		cableDragEvent.Parent = Remotes
	end
	
	local reiniciarEvent = Remotes:FindFirstChild("ReiniciarNivel")
	if not reiniciarEvent then
		reiniciarEvent = Instance.new("RemoteEvent")
		reiniciarEvent.Name = "ReiniciarNivel"
		reiniciarEvent.Parent = Remotes
	end
end

function UIService:setDependencies(level, graph, energy, algorithm)
	levelService = level
	graphService = graph
	energyService = energy
	algorithmService = algorithm
	
	if algorithmService then
		self:hookAlgorithmEvents()
	end
	
	print("✅ UIService: Dependencias inyectadas")
end

-- ============================================
-- ACTUALIZACIÓN DEL NIVEL
-- ============================================

-- Actualiza toda la UI del nivel (se llama cuando carga nuevo nivel)
function UIService:updateLevelUI()
	if not levelService or not updateUIEvent then return end

	local config = levelService:getLevelConfig()
	local progress = levelService:getLevelProgress()

	local levelData = {
		Type = "LevelUI",
		LevelID = levelService:getCurrentLevelID(),
		LevelName = config.Nombre,
		LevelDescription = config.Descripcion,
		BudgetInitial = config.DineroInicial,
		CostPerMeter = config.CostoPorMetro,
		Algorithm = config.Algoritmo,
		TotalNodes = #graphService:getNodes(),
		NodesConnected = progress.nodesConnected,
		CablesPlaced = progress.cablesPlaced
	}

	updateUIEvent:FireAllClients(levelData)
	print("🎨 UIService: Nivel UI actualizado")
end

-- ============================================
-- ACTUALIZACIÓN DE PROGRESO
-- ============================================

-- Actualiza el progreso actual
function UIService:updateProgress()
	if not levelService or not updateUIEvent then return end

	local progress = levelService:getLevelProgress()

	local progressData = {
		Type = "Progress",
		NodesConnected = progress.nodesConnected,
		TotalNodes = levelService:getLevelConfig().NodosTotales,
		CablesPlaced = progress.cablesPlaced,
		NodesEnergized = #progress.energized,
		LevelComplete = progress.completed
	}

	updateUIEvent:FireAllClients(progressData)
end

-- ============================================
-- ACTUALIZACIÓN DE ENERGÍA
-- ============================================

-- Actualiza qué nodos están energizados
function UIService:updateEnergyStatus()
	if not levelService or not energyService or not updateUIEvent then return end

	local startNode = levelService:getStartNode()
	if not startNode then return end

	local energized = energyService:calculateEnergy(startNode)

	local energyData = {
		Type = "Energy",
		EnergizedNodes = energized,
		TotalEnergized = #energized
	}

	updateUIEvent:FireAllClients(energyData)
	print("⚡ UIService: Estado de energía actualizado (" .. #energized .. " nodos)")
end

-- ============================================
-- ACTUALIZACIÓN DE DINERO
-- ============================================

-- Actualiza dinero restante del jugador
function UIService:updateBudget(player)
	if not levelService or not updateUIEvent then return end

	local dineroRestante = 0
	if player and player:FindFirstChild("leaderstats") then
		local moneyValue = player.leaderstats:FindFirstChild("Money")
		if moneyValue then
			dineroRestante = moneyValue.Value
		end
	end

	local budgetData = {
		Type = "Budget",
		Initial = levelService:getInitialBudget(),
		Remaining = dineroRestante,
		Spent = levelService:getInitialBudget() - dineroRestante
	}

	if player then
		updateUIEvent:FireClient(player, budgetData)
	else
		updateUIEvent:FireAllClients(budgetData)
	end

	print("💰 UIService: Presupuesto actualizado")
end

-- ============================================
-- ACTUALIZACIÓN DE MISIONES
-- ============================================

-- Actualiza estado de misiones
function UIService:updateMissions()
	if not levelService or not updateUIEvent then return end

	local misiones = levelService:getMisiones()

	local misionesData = {
		Type = "Missions",
		Misiones = {}
	}

	for _, mision in pairs(misiones) do
		table.insert(misionesData.Misiones, {
			ID = mision.ID,
			Texto = mision.Texto,
			Tipo = mision.Tipo,
			Completada = false  -- Se calcula en cliente o aquí
		})
	end

	updateUIEvent:FireAllClients(misionesData)
	print("📋 UIService: Misiones actualizadas (" .. #misiones .. " misiones)")
end

-- ============================================
-- ACTUALIZACIÓN DE OBJETOS
-- ============================================

-- Actualiza objetos coleccionables visibles
function UIService:updateCollectibles()
	if not levelService or not updateUIEvent then return end

	local coleccionables = levelService:getColeccionables()

	local collectiblesData = {
		Type = "Collectibles",
		Objetos = {}
	}

	for _, objeto in pairs(coleccionables) do
		table.insert(collectiblesData.Objetos, {
			Name = objeto.Name,
			Position = objeto:IsA("Model") and objeto:GetPivot().Position or objeto.Position
		})
	end

	updateUIEvent:FireAllClients(collectiblesData)
	print("🎁 UIService: Objetos actualizados (" .. #coleccionables .. " objetos)")
end

-- ============================================
-- NOTIFICACIONES
-- ============================================

-- Envía notificación al jugador
function UIService:notifyPlayer(player, titulo, mensaje, tipo)
	if not updateUIEvent then return end

	tipo = tipo or "info"  -- info, success, warning, error

	local notificacion = {
		Type = "Notification",
		Titulo = titulo,
		Mensaje = mensaje,
		TipoNotificacion = tipo,
		Timestamp = os.time()
	}

	if player then
		updateUIEvent:FireClient(player, notificacion)
	else
		updateUIEvent:FireAllClients(notificacion)
	end

	print("💬 UIService: Notificación enviada - " .. titulo)
end

-- Notifica éxito
function UIService:notifySuccess(player, titulo, mensaje)
	self:notifyPlayer(player, titulo, mensaje, "success")
end

-- Notifica error
function UIService:notifyError(player, titulo, mensaje)
	self:notifyPlayer(player, titulo, mensaje, "error")
end

-- Notifica advertencia
function UIService:notifyWarning(player, titulo, mensaje)
	self:notifyPlayer(player, titulo, mensaje, "warning")
end

-- ============================================
-- ACTUALIZACIÓN DE ALGORITMOS
-- ============================================

-- Actualiza información de algoritmo ejecutándose
function UIService:updateAlgorithmStatus(algoritmo, estado)
	if not updateUIEvent then return end

	-- estado: "started", "running", "completed"

	local algData = {
		Type = "Algorithm",
		Algoritmo = algoritmo,
		Estado = estado,
		Timestamp = os.time()
	}

	updateUIEvent:FireAllClients(algData)
	print("🧠 UIService: Estado de algoritmo actualizado - " .. algoritmo .. " (" .. estado .. ")")
end

-- ============================================
-- ACTUALIZACIÓN COMPLETA
-- ============================================

-- Actualiza toda la UI de una vez (para cambios de nivel)
function UIService:updateAll()
	print("🔄 UIService: Actualizando toda la UI...")

	self:updateLevelUI()
	task.wait(0.1)

	self:updateProgress()
	task.wait(0.1)

	self:updateEnergyStatus()
	task.wait(0.1)

	self:updateMissions()
	task.wait(0.1)

	self:updateCollectibles()
	task.wait(0.1)

	print("✅ UIService: Toda la UI actualizada")
end

-- ============================================
-- ACTUALIZACIÓN DE ESTADO DEL JUEGO
-- ============================================

-- Notifica que el nivel fue completado
function UIService:notifyLevelComplete()
	if not levelService or not updateUIEvent then return end

	local config = levelService:getLevelConfig()

	local completionData = {
		Type = "LevelComplete",
		LevelID = levelService:getCurrentLevelID(),
		LevelName = config.Nombre,
		Timestamp = os.time()
	}

	updateUIEvent:FireAllClients(completionData)
	print("🎉 UIService: Notificación de nivel completado")
end

-- Notifica que el nivel fue reseteado
function UIService:notifyLevelReset()
	if not updateUIEvent then return end


	local resetData = {
		Type = "LevelReset",
		Timestamp = os.time()
	}

	updateUIEvent:FireAllClients(resetData)
	
	-- Compatibilidad con VisualEffects.client.lua
	local remotes = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("Remotes")
	if remotes and remotes:FindFirstChild("ReiniciarNivel") then
		remotes.ReiniciarNivel:FireAllClients()
	end

	print("🔄 UIService: Notificación de reset de nivel")
end

-- ============================================
-- ACTUALIZACIÓN PARA JUGADORES ESPECÍFICOS
-- ============================================

-- Actualiza UI para un jugador específico
function UIService:updatePlayerUI(player)
	if not player then return end

	self:updateProgress()
	self:updateBudget(player)
	self:updateEnergyStatus()

	print("👤 UIService: UI actualizada para " .. player.Name)
end

-- Actualiza todas las UIs cuando se conecta un jugador
function UIService:initializePlayerUI(player)
	print("👤 UIService: Inicializando UI para " .. player.Name)

	task.wait(1)  -- Esperar a que se cargue todo

	self:updateLevelUI()
	task.wait(0.1)
	self:updatePlayerUI(player)

	print("✅ UIService: UI inicializada para " .. player.Name)
end

-- ============================================
-- ACTUALIZACIÓN REACTIVA
-- ============================================

-- Se ejecuta cuando hay cambio de conexión
function UIService:onConnectionChanged()
	if graphService then
		graphService:onConnectionChanged(function(action, nodeA, nodeB)
			-- Actualizar energía
			self:updateEnergyStatus()

			-- Actualizar progreso
			self:updateProgress()
			
			-- Actualizar efectos visuales (Pulse)
			local remotes = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("Remotes")
			if remotes and remotes:FindFirstChild("PulseEvent") then
				local pulseAction = (action == "connected") and "StartPulse" or "StopPulse"
				-- Asumimos bidireccional por defecto en conexiones simples
				remotes.PulseEvent:FireAllClients(pulseAction, nodeA, nodeB, true)
			end
		end)
	end
end

-- Se ejecuta cuando se carga un nivel
function UIService:onLevelLoaded()
	if levelService then
		levelService:onLevelLoaded(function(nivelID, levelFolder, config)
			task.wait(0.5)
			self:updateAll()
		end)
	end
end

-- Se ejecuta cuando se conecta un Algoritmo
function UIService:hookAlgorithmEvents()
	if algorithmService then
		algorithmService:onAlgorithmStarted(function(algoritmo, startNode, endNode)
			self:updateAlgorithmStatus(algoritmo, "started")
			-- Enviar datos extra si es necesario
		end)

		algorithmService:onAlgorithmStep(function(paso)
			-- Retransmitir paso a clientes (si ClienteUI lo soporta)
			-- Por ahora, UI simple solo muestra estado
			if updateUIEvent then
				updateUIEvent:FireAllClients({
					Type = "AlgorithmStep",
					Paso = paso
				})
			end
		end)

		algorithmService:onAlgorithmCompleted(function(algoritmo, camino, costo)
			self:updateAlgorithmStatus(algoritmo, "completed")
			-- Notificar resultado
			if updateUIEvent then
				updateUIEvent:FireAllClients({
					Type = "AlgorithmResult",
					Algoritmo = algoritmo,
					Camino = camino,
					Costo = costo
				})
			end
		end)
		print("✅ UIService: Conectado a eventos de algoritmo")
		
		-- Escuchar peticiones del cliente (EjecutarAlgoritmo)
		local Remotes = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("Remotes")
		if Remotes then
			local ejecutarAlgoEvent = Remotes:FindFirstChild("EjecutarAlgoritmo")
			if not ejecutarAlgoEvent then
				ejecutarAlgoEvent = Instance.new("RemoteEvent")
				ejecutarAlgoEvent.Name = "EjecutarAlgoritmo"
				ejecutarAlgoEvent.Parent = Remotes
			end
			
			-- Conectar solo si no tiene conexiones previas (o limpiar)
			-- Como esto corre una vez al inicio, está bien.
			ejecutarAlgoEvent.OnServerEvent:Connect(function(player, algoritmo, inicioName, finName, nivelID)
				print("🧠 UIService: Petición de ejecución " .. algoritmo .. " de " .. player.Name)
				
				if not algorithmService or not levelService then 
					warn("❌ Servicios no listos para ejecutar algoritmo")
					return 
				end
				
				local startNode = levelService:getPoste(inicioName)
				local endNode = levelService:getPoste(finName)
				
				if not startNode or not endNode then
					warn("❌ Nodos no encontrados para algoritmo: " .. tostring(inicioName) .. " -> " .. tostring(finName))
					return
				end
				
				if algoritmo == "Dijkstra" or algoritmo == "DIJKSTRA" then
					algorithmService:executeDijkstra(startNode, endNode)
				elseif algoritmo == "BFS" then
					algorithmService:executeBFS(startNode, endNode)
				elseif algoritmo == "DFS" then
					algorithmService:executeDFS(startNode, endNode)
				end
			end)
		end
	end
end

-- Se ejecuta cuando se resetea el nivel
function UIService:onLevelReset()
	if levelService then
		levelService:onLevelReset(function(nivelID)
			self:notifyLevelReset()
			task.wait(0.5)
			self:updateAll()
		end)
	end
end

-- ============================================
-- DEBUG
-- ============================================

function UIService:debug()
	print("\n📊 ===== DEBUG UIService =====")

	if levelService then
		local config = levelService:getLevelConfig()
		print("Nivel: " .. (config and config.Nombre or "N/A"))

		local progress = levelService:getLevelProgress()
		print("Progreso: " .. progress.nodesConnected .. "/" .. progress.totalNodes .. " nodos")
	else
		print("⚠️ LevelService no inicializado")
	end

	if updateUIEvent then
		print("✅ Evento ActualizarUI disponible")
	else
		print("❌ Evento ActualizarUI no disponible")
	end

	print("===== Fin DEBUG =====\n")
end

return UIService