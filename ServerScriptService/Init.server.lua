-- ServerScriptService/_InitFirst.server.lua
-- Este script se ejecuta PRIMERO (por el prefijo _) y registra _G.Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

print("\n" .. string.rep("═", 60))
print("🚀 _InitFirst: Inicializando servicios globales")
print(string.rep("═", 60) .. "\n")

-- ============================================
-- PASO 1: Cargar módulos compartidos
-- ============================================

print("📦 Paso 1: Cargando módulos compartidos...")

local Enums = nil
local GraphUtils = nil

local function loadSharedModules()
	local shared = ReplicatedStorage:WaitForChild("Shared", 10)
	if not shared then
		warn("❌ CRÍTICO: No se encontró ReplicatedStorage/Shared")
		return false
	end

	local enumsModule = shared:WaitForChild("Enums", 10)
	if enumsModule then
		Enums = require(enumsModule)
		print("   ✅ Enums.lua cargado")
	end

	local utils = shared:WaitForChild("Utils", 10)
	if utils then
		local graphUtilsModule = utils:WaitForChild("GraphUtils", 10)
		if graphUtilsModule then
			GraphUtils = require(graphUtilsModule)
			print("   ✅ GraphUtils.lua cargado")
		end
	end

	return true
end

if not loadSharedModules() then
	error("❌ CRÍTICO: Falló cargar módulos compartidos")
end

-- ============================================
-- PASO 2: Cargar servicios
-- ============================================

print("\n📦 Paso 2: Cargando servicios...")

local servicesFolder = ServerScriptService:WaitForChild("Services", 10)

if not servicesFolder then
	error("❌ CRÍTICO: No se encontró ServerScriptService/Services")
end

local function loadService(name)
	local module = servicesFolder:FindFirstChild(name)
	if module then
		local success, result = pcall(require, module)
		if success then
			print("   ✅ " .. name .. " cargado")
			return result
		else
			warn("   ❌ Error cargando " .. name .. ":", result)
		end
	else
		warn("   ⚠️ " .. name .. " no encontrado")
	end
	return nil
end

local GraphService = loadService("GraphService")
local EnergyService = loadService("EnergyService")
local LevelService = loadService("LevelService")
local MissionService = loadService("MissionService")
local InventoryService = loadService("InventoryService")
local AlgorithmService = loadService("AlgorithmService")
local UIService = loadService("UIService")
local AudioService = loadService("AudioService")
local RewardService = loadService("RewardService")

-- ============================================
-- PASO 3: Inyectar dependencias
-- ============================================

print("\n📦 Paso 3: Inyectando dependencias...")

if MissionService then MissionService:init() end
if InventoryService then InventoryService:init() end
if AudioService then AudioService:init() end
if UIService then UIService:init() end

if EnergyService then
	EnergyService:setGraphService(GraphService)
end

if LevelService then
	LevelService:setDependencies(GraphService, EnergyService, MissionService, InventoryService)
end

if MissionService then
	MissionService:setDependencies(LevelService)
end

if InventoryService then
	InventoryService:setDependencies(LevelService)
end

if AlgorithmService then
	AlgorithmService:setGraphService(GraphService)
	AlgorithmService:setLevelService(LevelService)
end

if UIService then
	UIService:setDependencies(LevelService, GraphService, EnergyService, AlgorithmService)
end

if RewardService then
	RewardService:init()
	RewardService:setDependencies(LevelService, InventoryService, AudioService, UIService)
end

-- ============================================
-- PASO 4: Registrar en _G.Services (CRÍTICO)
-- ============================================

print("\n📦 Paso 4: Registrando _G.Services...")

_G.Services = {
	Graph = GraphService,
	Energy = EnergyService,
	Level = LevelService,
	Mission = MissionService,
	Inventory = InventoryService,
	Algorithm = AlgorithmService,
	UI = UIService,
	Audio = AudioService,
	Reward = RewardService,
	Enums = Enums,
	GraphUtils = GraphUtils
}

-- ============================================
-- PASO 6: Auto-init de Nivel (si existe en Workspace)
-- ============================================
if LevelService then
	LevelService:init()
end


-- ============================================
-- PASO 5: Configurar listeners
-- ============================================

print("\n📦 Paso 5: Configurando listeners...")

if LevelService then
	LevelService:onLevelLoaded(function(nivelID, levelFolder, config)
		print("🎮 Nivel " .. nivelID .. " cargado, reiniciando grafo...")
		if GraphService then GraphService:init(levelFolder) end
		if EnergyService then EnergyService:setGraphService(GraphService) end
	end)

	LevelService:onLevelUnloaded(function()
		print("🎮 Nivel descargado, limpiando grafo...")
		if GraphService then GraphService:clearAllCables() end
	end)

	-- Auto-detectar nivel en Workspace
	LevelService:init()
end

print("\n" .. string.rep("═", 60))
print("✅ SERVICIOS GLOBALES LISTOS - Otros scripts pueden continuar")
print(string.rep("═", 60) .. "\n")