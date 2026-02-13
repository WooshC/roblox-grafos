-- ServerScriptService/Services/LevelService.lua
-- SERVICIO CENTRALIZADO para gestión de niveles
-- Maneja carga, descarga, inicialización y reset de niveles

local LevelService = {}
LevelService.__index = LevelService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local NivelUtils = require(ReplicatedStorage:WaitForChild("Utilidades"):WaitForChild("NivelUtils"))
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums"))

-- ============================================
-- ESTADO INTERNO
-- ============================================

local currentLevel = nil          -- Referencia al nivel actual en Workspace
local currentLevelID = nil        -- ID del nivel actual (0, 1, 2, etc.)
local levelConfig = nil           -- Configuración del nivel actual
local isLevelActive = false       -- Boolean para saber si hay un nivel activo

-- Eventos
local levelLoadedEvent = Instance.new("BindableEvent")
local levelUnloadedEvent = Instance.new("BindableEvent")
local levelResetEvent = Instance.new("BindableEvent")

-- Referencias a servicios (se inyectan después)
local graphService = nil
local energyService = nil
local misionManager = nil

-- ============================================
-- INICIALIZACIÓN
-- ============================================

function LevelService:setDependencies(graph, energy, misiones)
	graphService = graph
	energyService = energy
	misionManager = misiones
	print("✅ LevelService: Dependencias inyectadas")
end

-- ============================================
-- CARGA DE NIVELES
-- ============================================

-- Carga un nivel del ReplicatedStorage al Workspace
-- Parámetro: nivelID (number) - 0, 1, 2, etc.
function LevelService:loadLevel(nivelID)
	print("📦 LevelService: Cargando nivel " .. nivelID .. "...")
	
	-- Descargar nivel anterior si existe
	if currentLevel then
		self:unloadLevel()
	end
	
	-- Obtener configuración del nivel
	local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))
	levelConfig = LevelsConfig[nivelID]
	
	if not levelConfig then
		warn("❌ LevelService: Configuración de Nivel " .. nivelID .. " no encontrada")
		return false
	end
	
	-- Obtener el modelo del nivel
	local nivelModelo = NivelUtils.obtenerModeloNivel(nivelID)
	
	if not nivelModelo then
		warn("❌ LevelService: Modelo de Nivel " .. nivelID .. " no encontrado en ReplicatedStorage")
		return false
	end
	
	-- Clonar el nivel al Workspace
	local nivelClonado = nivelModelo:Clone()
	nivelClonado.Name = "NivelActual"  -- Nombre estándar para fácil acceso
	nivelClonado.Parent = Workspace
	
	-- Guardar referencias
	currentLevel = nivelClonado
	currentLevelID = nivelID
	isLevelActive = true
	
	-- Inicializar servicios con el nuevo nivel
	if graphService then
		graphService:init(currentLevel)
	end
	
	if energyService then
		energyService:setGraphService(graphService)
	end
	
	-- Emitir evento de carga
	levelLoadedEvent:Fire(nivelID, currentLevel, levelConfig)
	
	print("✅ LevelService: Nivel " .. nivelID .. " cargado correctamente")
	print("   → Nombre: " .. levelConfig.Nombre)
	print("   → Nodos: " .. levelConfig.NodosTotales)
	
	return true
end

-- Descarga el nivel actual del Workspace
function LevelService:unloadLevel()
	if not currentLevel then
		print("⚠️ LevelService: No hay nivel cargado para descargar")
		return false
	end
	
	print("📦 LevelService: Descargando nivel " .. currentLevelID .. "...")
	
	-- Limpiar servicios
	if graphService then
		graphService:clearAllCables()
	end
	
	-- Destruir el nivel
	currentLevel:Destroy()
	currentLevel = nil
	currentLevelID = nil
	levelConfig = nil
	isLevelActive = false
	
	-- Emitir evento de descarga
	levelUnloadedEvent:Fire()
	
	print("✅ LevelService: Nivel descargado")
	
	return true
end

-- ============================================
-- INFORMACIÓN DEL NIVEL
-- ============================================

-- Obtiene el nivel actual en Workspace
function LevelService:getCurrentLevel()
	return currentLevel
end

-- Obtiene el ID del nivel actual
function LevelService:getCurrentLevelID()
	return currentLevelID
end

-- Obtiene la configuración del nivel actual
function LevelService:getLevelConfig()
	return levelConfig
end

-- Verifica si hay un nivel activo
function LevelService:isLevelLoaded()
	return isLevelActive and currentLevel and currentLevel.Parent == Workspace
end

-- Obtiene información del nivel por ID
function LevelService:getLevelInfo(nivelID)
	local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))
	if LevelsConfig[nivelID] then
		return LevelsConfig[nivelID]
	end
	return nil
end

-- ============================================
-- BÚSQUEDA DE OBJETOS EN EL NIVEL
-- ============================================

-- Obtiene los postes del nivel actual
function LevelService:getPostes()
	if not currentLevel then return {} end
	return NivelUtils.obtenerCarpetaPostes(currentLevelID)
end

-- Obtiene un poste específico por nombre
function LevelService:getPoste(nombrePoste)
	if not currentLevel then return nil end
	local carpetaPostes = NivelUtils.obtenerCarpetaPostes(currentLevelID)
	if carpetaPostes then
		return carpetaPostes:FindFirstChild(nombrePoste)
	end
	return nil
end

-- Obtiene el nodo inicial (generador)
function LevelService:getStartNode()
	if not levelConfig or not levelConfig.NodoInicio then return nil end
	return self:getPoste(levelConfig.NodoInicio)
end

-- Obtiene el nodo final (objetivo)
function LevelService:getEndNode()
	if not levelConfig or not levelConfig.NodoFin then return nil end
	return self:getPoste(levelConfig.NodoFin)
end

-- Obtiene todos los nodos del nivel
function LevelService:getAllNodes()
	if not currentLevel then return {} end
	
	local postesFolder = self:getPostes()
	if not postesFolder then return {} end
	
	local nodes = {}
	for _, poste in pairs(postesFolder:GetChildren()) do
		table.insert(nodes, poste)
	end
	return nodes
end

-- Obtiene cables del nivel actual
function LevelService:getCables()
	if graphService then
		return graphService:getCables()
	end
	return {}
end

-- ============================================
-- RESET DE NIVEL
-- ============================================

-- Resetea el nivel actual (limpia cables, restaura posiciones)
function LevelService:resetLevel()
	if not currentLevel or not currentLevelID then
		print("⚠️ LevelService: No hay nivel para resetear")
		return false
	end
	
	print("🔄 LevelService: Reseteando nivel " .. currentLevelID .. "...")
	
	-- Limpiar todos los cables
	if graphService then
		graphService:clearAllCables()
	end
	
	-- Restaurar posiciones de objetos coleccionables (si existen)
	local objetosFolder = currentLevel:FindFirstChild("Objetos")
	if objetosFolder then
		local coleccionablesFolder = objetosFolder:FindFirstChild("Coleccionables")
		if coleccionablesFolder then
			for _, objeto in pairs(coleccionablesFolder:GetChildren()) do
				if objeto:IsA("Model") then
					-- Restaurar posición original
					local originalPos = objeto:FindFirstChild("OriginalPosition")
					if originalPos then
						objeto:MoveTo(originalPos.Value)
					end
				end
			end
		end
	end
	
	-- Resetear misiones
	if misionManager then
		-- Emitir evento para que MisionManager reset misiones del nivel
		-- misionManager:resetearMisiones(player)
	end
	
	-- Emitir evento de reset
	levelResetEvent:Fire(currentLevelID)
	
	print("✅ LevelService: Nivel " .. currentLevelID .. " reseteado")
	
	return true
end

-- ============================================
-- VALIDACIÓN DE NIVEL
-- ============================================

-- Valida si el nivel está completado (objetivo alcanzado)
function LevelService:checkLevelCompletion()
	if not currentLevel or not energyService then
		return false
	end
	
	return energyService:checkLevelCompletion(currentLevel)
end

-- Obtiene el progreso del jugador en el nivel
function LevelService:getLevelProgress()
	if not currentLevel or not graphService then
		return {
			nodesConnected = 0,
			totalNodes = levelConfig and levelConfig.NodosTotales or 0,
			cablesPlaced = 0,
			energized = {},
			completed = false
		}
	end
	
	local cables = graphService:getCables()
	local nodes = graphService:getNodes()
	local energized = {}
	
	-- Calcular nodos energizados desde el inicio
	local startNode = self:getStartNode()
	if startNode and energyService then
		energized = energyService:calculateEnergy(startNode)
	end
	
	return {
		nodesConnected = #nodes,
		totalNodes = levelConfig and levelConfig.NodosTotales or 0,
		cablesPlaced = #cables,
		energized = energized,
		completed = self:checkLevelCompletion()
	}
end

-- ============================================
-- VALIDACIÓN DE ADYACENCIAS
-- ============================================

-- Valida si dos nodos pueden conectarse según la configuración
function LevelService:canConnect(nodoA, nodoB)
	if not levelConfig or not levelConfig.Adyacencias then
		return true  -- Si no hay restricciones, permite cualquier conexión
	end
	
	local nombreA = nodoA.Name
	local nombreB = nodoB.Name
	
	local adyacentes = levelConfig.Adyacencias[nombreA]
	if not adyacentes then return false end
	
	for _, nombre in pairs(adyacentes) do
		if nombre == nombreB then
			return true
		end
	end
	
	return false
end

-- ============================================
-- DINERO Y PRESUPUESTO
-- ============================================

-- Obtiene el presupuesto inicial del nivel
function LevelService:getInitialBudget()
	if levelConfig and levelConfig.DineroInicial then
		return levelConfig.DineroInicial
	end
	return 0
end

-- Obtiene el costo por metro de cable del nivel
function LevelService:getCostPerMeter()
	if levelConfig and levelConfig.CostoPorMetro then
		return levelConfig.CostoPorMetro
	end
	return 0
end

-- ============================================
-- MISIONES
-- ============================================

-- Obtiene las misiones del nivel actual
function LevelService:getMisiones()
	if levelConfig and levelConfig.Misiones then
		return levelConfig.Misiones
	end
	return {}
end

-- Valida si una misión está completada
function LevelService:isMisionCompleted(misionID, estadoJuego)
	if not misionManager then return false end
	
	local misions = self:getMisiones()
	for _, mision in pairs(misions) do
		if mision.ID == misionID then
			return misionManager:verificarMision(mision, estadoJuego)
		end
	end
	
	return false
end

-- ============================================
-- OBJETOS COLECCIONABLES
-- ============================================

-- Obtiene los objetos coleccionables del nivel
function LevelService:getColeccionables()
	if not currentLevel then return {} end
	
	local objetosFolder = currentLevel:FindFirstChild("Objetos")
	if not objetosFolder then return {} end
	
	local coleccionablesFolder = objetosFolder:FindFirstChild("Coleccionables")
	if not coleccionablesFolder then return {} end
	
	local coleccionables = {}
	for _, objeto in pairs(coleccionablesFolder:GetChildren()) do
		table.insert(coleccionables, objeto)
	end
	
	return coleccionables
end

-- ============================================
-- ALGORITMO DEL NIVEL
-- ============================================

-- Obtiene el algoritmo que debe usar el nivel
function LevelService:getAlgorithm()
	if levelConfig and levelConfig.Algoritmo then
		return levelConfig.Algoritmo
	end
	return "BFS"  -- Default
end

-- ============================================
-- EVENTOS
-- ============================================

-- Se ejecuta cuando un nivel es cargado
function LevelService:onLevelLoaded(callback)
	levelLoadedEvent.Event:Connect(callback)
end

-- Se ejecuta cuando un nivel es descargado
function LevelService:onLevelUnloaded(callback)
	levelUnloadedEvent.Event:Connect(callback)
end

-- Se ejecuta cuando un nivel es reseteado
function LevelService:onLevelReset(callback)
	levelResetEvent.Event:Connect(callback)
end

-- ============================================
-- DEBUG
-- ============================================

-- Imprime información del nivel actual
function LevelService:debug()
	if not currentLevel then
		print("❌ LevelService:debug() - No hay nivel cargado")
		return
	end
	
	print("\n📊 ===== DEBUG LevelService =====")
	print("Nivel ID: " .. currentLevelID)
	print("Nombre: " .. (levelConfig and levelConfig.Nombre or "N/A"))
	print("Nodo Inicio: " .. (levelConfig and levelConfig.NodoInicio or "N/A"))
	print("Nodo Fin: " .. (levelConfig and levelConfig.NodoFin or "N/A"))
	print("Dinero Inicial: $" .. self:getInitialBudget())
	print("Costo por Metro: $" .. self:getCostPerMeter())
	print("Algoritmo: " .. self:getAlgorithm())
	
	print("\nMisiones (" .. #self:getMisiones() .. "):")
	for _, mision in pairs(self:getMisiones()) do
		print("  • Misión " .. mision.ID .. ": " .. mision.Texto)
	end
	
	print("\nObjetos Coleccionables (" .. #self:getColeccionables() .. "):")
	for _, objeto in pairs(self:getColeccionables()) do
		print("  • " .. objeto.Name)
	end
	
	local progress = self:getLevelProgress()
	print("\nProgreso:")
	print("  Nodos conectados: " .. progress.nodesConnected .. "/" .. progress.totalNodes)
	print("  Cables colocados: " .. progress.cablesPlaced)
	print("  Nodos energizados: " .. #progress.energized)
	print("  Completado: " .. (progress.completed and "✅ SÍ" or "❌ NO"))
	
	print("===== Fin DEBUG =====\n")
end

-- ============================================
-- MÉTODOS DE UTILIDAD
-- ============================================

-- Obtiene todos los niveles disponibles
function LevelService:getAllLevels()
	local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))
	local levels = {}
	
	for nivelID, config in pairs(LevelsConfig) do
		table.insert(levels, {
			id = nivelID,
			nombre = config.Nombre,
			descripcion = config.DescripcionCorta,
			config = config
		})
	end
	
	return levels
end

-- Obtiene el siguiente nivel (secuencial)
function LevelService:getNextLevel()
	return currentLevelID and currentLevelID + 1 or nil
end

-- Obtiene el nivel anterior (secuencial)
function LevelService:getPreviousLevel()
	return currentLevelID and currentLevelID - 1 or nil
end

-- Valida si un nivel existe
function LevelService:levelExists(nivelID)
	local info = self:getLevelInfo(nivelID)
	return info ~= nil
end

return LevelService