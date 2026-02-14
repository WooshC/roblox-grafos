-- ServerScriptService/Services/LevelService.lua
-- SERVICIO CENTRALIZADO para gestión de niveles
-- Maneja carga, descarga, inicialización y reset de niveles

local LevelService = {}
LevelService.__index = LevelService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

-- Dependencias Utilidades
local NivelUtils = require(ReplicatedStorage:WaitForChild("Utilidades"):WaitForChild("NivelUtils"))
local GraphUtils = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"):WaitForChild("GraphUtils"))
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
local missionService = nil  -- Antes misionManager
local inventoryService = nil -- Antes inventoryManager

-- ============================================
-- INICIALIZACIÓN
-- ============================================

function LevelService:setDependencies(graph, energy, mission, inventory)
	graphService = graph
	energyService = energy
	missionService = mission
	inventoryService = inventory
	print("✅ LevelService: Dependencias inyectadas (Graph, Energy, Mission, Inventory)")
end

function LevelService:init()
	print("🚀 LevelService: Iniciando auto-detección de niveles...")
	local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))
	
	-- Auto-detectar nivel en Workspace (para Testing en Studio)
	for id, config in pairs(LevelsConfig) do
		local modelName = config.Modelo
		-- Chequear nombre exacto o fallback común para Tutorial
		if Workspace:FindFirstChild(modelName) or (id == 0 and Workspace:FindFirstChild("Nivel0_Tutorial")) then
			print("   ℹ️ Nivel pre-existente detectado: " .. modelName .. " (ID: " .. id .. ")")
			self:loadLevel(id)
			return
		end
	end
	
	print("   ℹ️ Ningún nivel pre-cargado detectado.")
end

-- ============================================
-- CARGA DE NIVELES
-- ============================================

-- Busca el modelo del nivel en ReplicatedStorage (NUEVA UBICACIÓN)
local function findLevelModelInStorage(modelName)
	-- Intentar buscar en carpeta "Niveles" si existe
	local nivelesFolder = ReplicatedStorage:FindFirstChild("Niveles")
	if nivelesFolder then
		local modelo = nivelesFolder:FindFirstChild(modelName)
		if modelo then 
			print("   ✅ Modelo encontrado en ReplicatedStorage/Niveles/" .. modelName)
			return modelo 
		end
	end

	-- Si no, buscar en la raíz de ReplicatedStorage
	local modeloRaiz = ReplicatedStorage:FindFirstChild(modelName)
	if modeloRaiz then
		print("   ✅ Modelo encontrado en ReplicatedStorage/" .. modelName)
	end
	return modeloRaiz
end

-- Carga un nivel del ReplicatedStorage al Workspace
-- Parámetro: nivelID (number) - 0, 1, 2, etc.
function LevelService:loadLevel(nivelID)
	print("📦 LevelService: Cargando nivel " .. nivelID .. "...")
	
	-- Obtener configuración del nivel
	local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))
	levelConfig = LevelsConfig[nivelID]
	
	if not levelConfig then
		warn("❌ LevelService: Configuración de Nivel " .. nivelID .. " no encontrada")
		return false
	end

	local nombreModelo = levelConfig.Modelo

	-- Descargar nivel anterior si existe
	if currentLevel then
		self:unloadLevel()
	end
	
	-- LÓGICA DE CARGA CENTRALIZADA
	local nivelClonado = nil
	local nivelEnWorkspace = Workspace:FindFirstChild(nombreModelo) or Workspace:FindFirstChild("NivelActual")
	
	-- Caso 1: Desarrollo/Testing - El nivel ya está en Workspace
	if nivelEnWorkspace then
		print("   ℹ️ Nivel encontrado en Workspace. Usando instancia existente.")
		nivelClonado = nivelEnWorkspace
	else
		-- Caso 2: Producción - Cargar desde ReplicatedStorage
		print("   📦 Buscando modelo '" .. nombreModelo .. "' en ReplicatedStorage/Niveles...")
		local modeloOriginal = findLevelModelInStorage(nombreModelo)
		
		-- Fallback para tutorial (nombres legacy)
		if not modeloOriginal and nivelID == 0 then
			print("   🔄 Intentando fallback: Nivel0_Tutorial...")
			modeloOriginal = findLevelModelInStorage("Nivel0_Tutorial")
		end
		
		if not modeloOriginal then
			warn("❌ LevelService: CRÍTICO - Modelo '" .. nombreModelo .. "' no encontrado en ReplicatedStorage/Niveles")
			warn("   💡 Verifica que el modelo exista en ReplicatedStorage/Niveles/" .. nombreModelo)
			return false
		end
		
		print("   🔄 Clonando nivel al Workspace...")
		nivelClonado = modeloOriginal:Clone()
		nivelClonado.Name = "NivelActual" -- Estandarizar nombre
		nivelClonado.Parent = Workspace
		print("   ✅ Nivel clonado exitosamente")
	end
	
	-- Guardar referencias
	currentLevel = nivelClonado
	currentLevelID = nivelID
	isLevelActive = true
	
	-- Limpiar cache de utilidades para evitar referencias viejas
	NivelUtils.limpiarCache()
	
	-- Inicializar servicios con el nuevo nivel
	if graphService then
		graphService:init(currentLevel)
	end
	
	if energyService then
		energyService:setGraphService(graphService)
	end
	
	-- Actualizar atributo en todos los jugadores (para Minimap y UI)
	for _, player in ipairs(Players:GetPlayers()) do
		player:SetAttribute("CurrentLevelID", nivelID)
	end

	-- Emitir evento de carga
	levelLoadedEvent:Fire(nivelID, currentLevel, levelConfig)
	
	print("✅ LevelService: Nivel " .. nivelID .. " cargado correctamente")
	
	return true
end

-- Descarga el nivel actual del Workspace
function LevelService:unloadLevel()
	if not currentLevel then return false end
	
	print("📦 LevelService: Descargando nivel " .. currentLevelID .. "...")
	
	-- Limpiar servicios vinculados
	if graphService then
		graphService:clearAllCables()
	end
	
	-- Destruir el nivel (Solo si fue instanciado dinámicamente o renombrado a NivelActual)
	if currentLevel.Parent == Workspace and currentLevel.Name == "NivelActual" then
		currentLevel:Destroy()
	else
		-- Si es un nivel de desarrollo (no renombrado), no lo destruimos, solo limpiamos referencia
		print("   ⚠️ Nivel no destruido (Modo Desarrollo/Testing)")
	end
	
	currentLevel = nil
	currentLevelID = nil
	levelConfig = nil
	isLevelActive = false
	
	-- Limpiar atributo en jugadores
	for _, player in ipairs(Players:GetPlayers()) do
		player:SetAttribute("CurrentLevelID", -1) -- -1 indica sin nivel
	end

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
	return LevelsConfig[nivelID]
end

-- ============================================
-- BÚSQUEDA DE OBJETOS EN EL NIVEL
-- ============================================

-- Obtiene los postes del nivel actual
function LevelService:getPostes()
	if not currentLevel then return nil end
	return GraphUtils.getPostesFolder(currentLevel)
end

-- Obtiene un poste específico por nombre
function LevelService:getPoste(nombrePoste)
	if not currentLevel then return nil end
	return GraphUtils.getNodeByName(currentLevel, nombrePoste)
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
	return GraphUtils.getAllNodes(currentLevel)
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
	if not currentLevel then 
		warn("⚠️ No hay nivel activo para resetear")
		return false 
	end
	
	print("🔄 LevelService: Reseteando nivel " .. currentLevelID .. "...")
	
	-- 1. Limpiar cables
	if graphService then
		graphService:clearAllCables()
		print("   ✅ Cables limpiados")
	end
	
	-- 2. Restaurar energía
	if energyService then
		energyService:resetAll()
		print("   ✅ Sistema de energía reseteado")
	end
	
	-- 3. Resetear misiones
	if missionService then
		missionService:resetMissions()
		print("   ✅ Misiones reseteadas")
	end
	
	-- Emitir evento de reset
	levelResetEvent:Fire(currentLevelID, currentLevel)
	
	print("✅ LevelService: Nivel reseteado correctamente")
	return true
end

-- ============================================
-- EVENTOS PÚBLICOS
-- ============================================

function LevelService:onLevelLoaded(callback)
	return levelLoadedEvent.Event:Connect(callback)
end

function LevelService:onLevelUnloaded(callback)
	return levelUnloadedEvent.Event:Connect(callback)
end

function LevelService:onLevelReset(callback)
	return levelResetEvent.Event:Connect(callback)
end

-- ============================================
-- UTILIDADES
-- ============================================

-- Verifica si existe un nivel por ID
function LevelService:levelExists(nivelID)
	local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))
	return LevelsConfig[nivelID] ~= nil
end

-- Obtiene lista de todos los niveles disponibles
function LevelService:getAllLevels()
	local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))
	local levels = {}
	for id, config in pairs(LevelsConfig) do
		table.insert(levels, {
			id = id,
			nombre = config.Nombre or "Nivel " .. id,
			modelo = config.Modelo
		})
	end
	return levels
end

return LevelService