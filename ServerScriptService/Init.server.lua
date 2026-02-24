-- ServerScriptService/Init.server.lua
-- SCRIPT DE INICIALIZACIÓN - Carga todos los servicios en orden correcto
-- Este es el punto de entrada principal del servidor

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

print("\n" .. string.rep("═", 60))
print("🚀 INICIANDO SERVIDOR - Cargando Servicios")
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
	error("❌ CRÍTICO: Falló cargar módulos compartidos. Deteniendo servidor.")
end

-- ============================================
-- PASO 2: Cargar servicios
-- ============================================

print("\n📦 Paso 2: Cargando servicios...")

local Services = {}
local servicesFolder = ServerScriptService:WaitForChild("Services", 10)

if not servicesFolder then
	error("❌ CRÍTICO: No se encontró ServerScriptService/Services")
end

local function loadService(name)
	local module = servicesFolder:FindFirstChild(name)
	if module then
		local success, result = pcall(require, module)
		if success then
			Services[name] = result
			print("   ✅ " .. name .. " cargado")
			return result
		else
			warn("   ❌ Error cargando " .. name .. ":", result)
		end
	else
		warn("   ⚠️ " .. name .. " no encontrado (opcional)")
	end
	return nil
end

-- Orden de carga sugerido (aunque require es sincrónico, definimos variables locales)
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
-- PASO 3: Inicialización y Dependencias
-- ============================================

print("\n📦 Paso 3: Inicializando y conectando dependencias...")

-- 1. Inicializar servicios básicos (que no dependen de otros para init)
if MissionService then MissionService:init() end
if InventoryService then InventoryService:init() end
if AudioService then AudioService:init() end
if UIService then UIService:init() end

-- 2. Inyectar dependencias

-- EnergyService -> GraphService
if EnergyService then
	EnergyService:setGraphService(GraphService)
end

-- LevelService -> Graph, Energy, Mission, Inventory
if LevelService then
	LevelService:setDependencies(GraphService, EnergyService, MissionService, InventoryService)
end

-- MissionService -> LevelService, GraphService
if MissionService then
	MissionService:setDependencies(LevelService, GraphService)
end

-- InventoryService -> LevelService
if InventoryService then
	InventoryService:setDependencies(LevelService)
end

-- AlgorithmService -> Graph, Level
if AlgorithmService then
	AlgorithmService:setGraphService(GraphService)
	AlgorithmService:setLevelService(LevelService)
end

-- UIService -> Level, Graph, Energy, Algorithm
if UIService then
	UIService:setDependencies(LevelService, GraphService, EnergyService, AlgorithmService)
end

-- RewardService -> Level, Inventory, Audio, UI
if RewardService then
	RewardService:init() -- Init puede requerir eventos ya creados
	RewardService:setDependencies(LevelService, InventoryService, AudioService, UIService)
end

-- ============================================
-- PASO 4: Crear infraestructura de eventos
-- ============================================

print("\n📦 Paso 4: Creando infraestructura de eventos...")

-- Asegurar que la carpeta Events/Remotes/Bindables existe
local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
if not eventsFolder then
	eventsFolder = Instance.new("Folder")
	eventsFolder.Name = "Events"
	eventsFolder.Parent = ReplicatedStorage
end

local remotesFolder = eventsFolder:FindFirstChild("Remotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = eventsFolder
end

local bindablesFolder = eventsFolder:FindFirstChild("Bindables")
if not bindablesFolder then
	bindablesFolder = Instance.new("Folder")
	bindablesFolder.Name = "Bindables"
	bindablesFolder.Parent = eventsFolder
end

-- Crear todos los BindableEvents necesarios (P0-5, P0-6)
local function crearBindable(nombre)
	if not bindablesFolder:FindFirstChild(nombre) then
		local be = Instance.new("BindableEvent")
		be.Name = nombre
		be.Parent = bindablesFolder
		print("   ✅ BindableEvent creado: " .. nombre)
	end
end

crearBindable("RestaurarObjetos")
crearBindable("GuardarInventario")
crearBindable("AristaConectada")
crearBindable("DesbloquearObjeto")

-- ServicesReady: señal para que los scripts dependientes sepan que _G.Services está listo (P0-2)
local ServicesReady = Instance.new("BindableEvent")
ServicesReady.Name = "ServicesReady"
ServicesReady.Parent = bindablesFolder
print("   ✅ BindableEvent creado: ServicesReady")

-- ============================================
-- PASO 5: Configurando listeners globales
-- ============================================

print("\n📦 Paso 5: Configurando listeners de eventos...")

if LevelService then
	-- Cuando se carga un nivel, inicializar GraphService y EnergyService
	LevelService:onLevelLoaded(function(nivelID, levelFolder, config)
		print("🎮 Init: Nivel " .. nivelID .. " cargado, reiniciando servicios de grafo...")
		if GraphService then GraphService:init(levelFolder) end
		if EnergyService then EnergyService:setGraphService(GraphService) end
	end)

	-- Cuando se descarga un nivel
	LevelService:onLevelUnloaded(function()
		print("🎮 Init: Nivel descargado, limpiando grafo...")
		if GraphService then GraphService:clearAllCables() end
	end)
end

-- NOTA P0-3: El listener de RequestPlayLevel fue eliminado de aquí.
-- ManagerData.lua ya maneja RequestPlayLevel vía setupLevelForPlayer,
-- que internamente llama LevelService:loadLevel(). Tener dos listeners
-- causaba condición de carrera y posible doble carga de nivel.

-- ============================================
-- PASO 6: Exportar a _G (Opcional)
-- ============================================

print("\n📦 Paso 6: Registrando en _G.Services...")

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
-- PASO 7: Auto-init de Nivel (si existe en Workspace)
-- ============================================
if LevelService then
	LevelService:init()
end

-- ============================================
-- FIN — Disparar ServicesReady (P0-2)
-- ============================================
-- Esto notifica a ConectarCables, GameplayEvents, SistemaUI_reinicio
-- y GraphTheoryService que pueden acceder a _G.Services de forma segura.
ServicesReady:Fire()

print("\n" .. string.rep("═", 60))
print("✅ SERVIDOR INICIALIZADO - ARQUITECTURA SERVICIOS UNIFICADA")
print(string.rep("═", 60) .. "\n")