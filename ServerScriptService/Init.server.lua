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
	-- Esperar a que existan las carpetas
	local shared = ReplicatedStorage:WaitForChild("Shared", 10)
	if not shared then
		warn("❌ CRÍTICO: No se encontró ReplicatedStorage/Shared")
		return false
	end
	
	-- Cargar Enums
	local enumsModule = shared:WaitForChild("Enums", 10)
	if enumsModule then
		local success, result = pcall(require, enumsModule)
		if success then
			Enums = result
			print("   ✅ Enums.lua cargado")
		else
			warn("   ❌ Error cargando Enums.lua:", result)
			return false
		end
	else
		warn("   ❌ No se encontró Shared/Enums.lua")
		return false
	end
	
	-- Cargar GraphUtils
	local utils = shared:WaitForChild("Utils", 10)
	if utils then
		local graphUtilsModule = utils:WaitForChild("GraphUtils", 10)
		if graphUtilsModule then
			local success, result = pcall(require, graphUtilsModule)
			if success then
				GraphUtils = result
				print("   ✅ GraphUtils.lua cargado")
			else
				warn("   ❌ Error cargando GraphUtils.lua:", result)
				return false
			end
		else
			warn("   ❌ No se encontró Utils/GraphUtils.lua")
			return false
		end
	else
		warn("   ❌ No se encontró Shared/Utils/")
		return false
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

local GraphService = nil
local EnergyService = nil
local LevelService = nil

-- GraphService
do
	local servicesFolder = ServerScriptService:WaitForChild("Services", 10)
	if not servicesFolder then
		error("❌ CRÍTICO: No se encontró ServerScriptService/Services")
	end
	
	local graphServiceModule = servicesFolder:WaitForChild("GraphService", 10)
	if graphServiceModule then
		local success, result = pcall(require, graphServiceModule)
		if success then
			GraphService = result
			print("   ✅ GraphService.lua cargado")
		else
			warn("   ❌ Error cargando GraphService.lua:", result)
			error("Deteniendo servidor")
		end
	else
		error("❌ CRÍTICO: No se encontró Services/GraphService.lua")
	end
end

-- EnergyService
do
	local servicesFolder = ServerScriptService:FindFirstChild("Services")
	local energyServiceModule = servicesFolder:WaitForChild("EnergyService", 10)
	if energyServiceModule then
		local success, result = pcall(require, energyServiceModule)
		if success then
			EnergyService = result
			print("   ✅ EnergyService.lua cargado")
		else
			warn("   ❌ Error cargando EnergyService.lua:", result)
			error("Deteniendo servidor")
		end
	else
		error("❌ CRÍTICO: No se encontró Services/EnergyService.lua")
	end
end

-- LevelService
do
	local servicesFolder = ServerScriptService:FindFirstChild("Services")
	local levelServiceModule = servicesFolder:WaitForChild("LevelService", 10)
	if levelServiceModule then
		local success, result = pcall(require, levelServiceModule)
		if success then
			LevelService = result
			print("   ✅ LevelService.lua cargado")
		else
			warn("   ❌ Error cargando LevelService.lua:", result)
			error("Deteniendo servidor")
		end
	else
		error("❌ CRÍTICO: No se encontró Services/LevelService.lua")
	end
end

-- AlgorithmService ⭐ NUEVO
local AlgorithmService = nil
do
	local servicesFolder = ServerScriptService:FindFirstChild("Services")
	local algorithmServiceModule = servicesFolder:WaitForChild("AlgorithmService", 10)
	if algorithmServiceModule then
		local success, result = pcall(require, algorithmServiceModule)
		if success then
			AlgorithmService = result
			print("   ✅ AlgorithmService.lua cargado")
		else
			warn("   ❌ Error cargando AlgorithmService.lua:", result)
		end
	else
		warn("   ⚠️ AlgorithmService.lua no encontrado (opcional)")
	end
end

-- UIService ⭐ NUEVO
local UIService = nil
do
	local servicesFolder = ServerScriptService:FindFirstChild("Services")
	local uiServiceModule = servicesFolder:WaitForChild("UIService", 10)
	if uiServiceModule then
		local success, result = pcall(require, uiServiceModule)
		if success then
			UIService = result
			print("   ✅ UIService.lua cargado")
		else
			warn("   ❌ Error cargando UIService.lua:", result)
		end
	else
		warn("   ⚠️ UIService.lua no encontrado (opcional)")
	end
end

-- AudioService ⭐ NUEVO
local AudioService = nil
do
	local servicesFolder = ServerScriptService:FindFirstChild("Services")
	local audioServiceModule = servicesFolder:WaitForChild("AudioService", 10)
	if audioServiceModule then
		local success, result = pcall(require, audioServiceModule)
		if success then
			AudioService = result
			print("   ✅ AudioService.lua cargado")
		else
			warn("   ❌ Error cargando AudioService.lua:", result)
		end
	else
		warn("   ⚠️ AudioService.lua no encontrado (opcional)")
	end
end

-- RewardService ⭐ NUEVO
local RewardService = nil
do
	local servicesFolder = ServerScriptService:FindFirstChild("Services")
	local rewardServiceModule = servicesFolder:WaitForChild("RewardService", 10)
	if rewardServiceModule then
		local success, result = pcall(require, rewardServiceModule)
		if success then
			RewardService = result
			print("   ✅ RewardService.lua cargado")
		else
			warn("   ❌ Error cargando RewardService.lua:", result)
		end
	else
		warn("   ⚠️ RewardService.lua no encontrado (opcional)")
	end
end

-- ============================================
-- PASO 3: Inyectar dependencias
-- ============================================

print("\n📦 Paso 3: Inyectando dependencias...")

-- EnergyService necesita GraphService
EnergyService:setGraphService(GraphService)
print("   ✅ EnergyService recibió GraphService")

-- LevelService necesita todos los servicios anteriores
-- (El parámetro misionManager lo dejamos como nil por ahora, puede actualizarse después)
LevelService:setDependencies(GraphService, EnergyService, nil)
print("   ✅ LevelService recibió dependencias")

-- AlgorithmService necesita GraphService y LevelService
if AlgorithmService then
	AlgorithmService:setGraphService(GraphService)
	AlgorithmService:setLevelService(LevelService)
	print("   ✅ AlgorithmService recibió dependencias")
end

-- UIService necesita todos los servicios
if UIService then
	UIService:init()
	if AlgorithmService then
		UIService:setDependencies(LevelService, GraphService, EnergyService, AlgorithmService)
	else
		UIService:setDependencies(LevelService, GraphService, EnergyService, nil)
	end
	print("   ✅ UIService inicializado y recibió dependencias")
end

-- AudioService
if AudioService then
	AudioService:init()
	print("   ✅ AudioService inicializado")
end

-- RewardService necesita todos los servicios
if RewardService then
	RewardService:init()
	if UIService and AudioService then
		RewardService:setDependencies(LevelService, InventoryManager, AudioService, UIService)
	else
		RewardService:setDependencies(LevelService, InventoryManager, nil, nil)
	end
	print("   ✅ RewardService inicializado y recibió dependencias")
end

-- ============================================
-- PASO 4: Escuchar eventos de cambios
-- ============================================

print("\n📦 Paso 4: Configurando listeners de eventos...")

-- Cuando se carga un nivel, inicializar GraphService
LevelService:onLevelLoaded(function(nivelID, levelFolder, config)
	print("🎮 Init.server: Nivel " .. nivelID .. " cargado, inicializando GraphService...")
	GraphService:init(levelFolder)
	EnergyService:setGraphService(GraphService)
	print("✅ GraphService e EnergyService inicializados para nivel " .. nivelID)
end)

-- Cuando se descarga un nivel, limpiar
LevelService:onLevelUnloaded(function()
	print("🎮 Init.server: Nivel descargado, limpiando servicios...")
	GraphService:clearAllCables()
	print("✅ Servicios limpiados")
end)

-- Cuando hay cambios en conexiones, emitir eventos para clientes
GraphService:onConnectionChanged(function(action, nodeA, nodeB)
	-- Aquí puedes notificar a clientes si es necesario
	-- local Remotes = ReplicatedStorage.Events.Remotes
	-- local event = Remotes:FindFirstChild("ConexionActualizada")
	-- if event then event:FireAllClients(action, nodeA.Name, nodeB.Name) end
end)

print("   ✅ Listeners configurados")

-- ============================================
-- PASO 5: Cargar managers y otros servicios
-- ============================================

print("\n📦 Paso 5: Cargando managers adicionales...")

local MisionManager = nil
local InventoryManager = nil

-- Cargar MisionManager
if ReplicatedStorage:FindFirstChild("Utilidades") then
	local utilidades = ReplicatedStorage.Utilidades
	if utilidades:FindFirstChild("MisionManager") then
		local success, result = pcall(require, utilidades.MisionManager)
		if success then
			MisionManager = result
			if MisionManager.init then
				MisionManager.init()
			end
			print("   ✅ MisionManager cargado")
			
			-- Inyectar en LevelService
			LevelService:setDependencies(GraphService, EnergyService, MisionManager)
		else
			warn("   ⚠️ Error cargando MisionManager:", result)
		end
	end
end

-- Cargar InventoryManager
if ReplicatedStorage:FindFirstChild("Utilidades") then
	local utilidades = ReplicatedStorage.Utilidades
	if utilidades:FindFirstChild("InventoryManager") then
		local success, result = pcall(require, utilidades.InventoryManager)
		if success then
			InventoryManager = result
			if InventoryManager.init then
				InventoryManager.init()
			end
			print("   ✅ InventoryManager cargado")
		else
			warn("   ⚠️ Error cargando InventoryManager:", result)
		end
	end
end

-- ============================================
-- PASO 6: Escuchar conexión de jugadores
-- ============================================

print("\n📦 Paso 6: Configurando eventos de jugadores...")

Players.PlayerAdded:Connect(function(player)
	print("👤 Jugador conectado: " .. player.Name)
	
	-- Inicializar estado del jugador en managers
	if MisionManager and MisionManager.inicializarJugador then
		MisionManager.inicializarJugador(player)
	end
	
	if InventoryManager and InventoryManager.inicializarJugador then
		InventoryManager.inicializarJugador(player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	print("👤 Jugador desconectado: " .. player.Name)
	
	-- Limpiar estado del jugador
	if MisionManager and MisionManager.limpiarJugador then
		MisionManager.limpiarJugador(player)
	end
	
	if InventoryManager and InventoryManager.limpiarJugador then
		InventoryManager.limpiarJugador(player)
	end
end)

print("   ✅ Eventos de jugadores configurados")

-- ============================================
-- PASO 7: Escuchar solicitudes de carga de nivel
-- ============================================

print("\n📦 Paso 7: Configurando eventos de cambio de nivel...")

local Remotes = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes")
local requestPlayLevelEvent = Remotes:WaitForChild("RequestPlayLevel")

requestPlayLevelEvent.OnServerEvent:Connect(function(player, nivelID)
	print("🎮 Init.server: Solicitud de cargar nivel " .. nivelID .. " por " .. player.Name)
	
	-- Validar que el nivel existe
	if not LevelService:levelExists(nivelID) then
		warn("❌ Nivel " .. nivelID .. " no existe")
		return
	end
	
	-- Cargar el nivel
	local success = LevelService:loadLevel(nivelID)
	
	if success then
		print("✅ Nivel " .. nivelID .. " cargado exitosamente")
		
		-- Notificar al cliente que el nivel fue cargado
		-- Aquí puedes emitir un evento al cliente si es necesario
	else
		warn("❌ Falló cargar nivel " .. nivelID)
	end
end)

print("   ✅ Eventos de cambio de nivel configurados")

-- ============================================
-- PASO 8: Crear tabla global de servicios
-- ============================================

print("\n📦 Paso 8: Registrando servicios globales...")

_G.Services = {
	Graph = GraphService,
	Energy = EnergyService,
	Level = LevelService,
	Algorithm = AlgorithmService,
	UI = UIService,
	Audio = AudioService,
	Reward = RewardService,
	Misiones = MisionManager,
	Inventory = InventoryManager,
	Enums = Enums,
	GraphUtils = GraphUtils
}

print("   ✅ Servicios disponibles en _G.Services")

-- ============================================
-- INICIALIZACIÓN COMPLETADA
-- ============================================

print("\n" .. string.rep("═", 60))
print("✅ SERVIDOR INICIALIZADO EXITOSAMENTE")
print(string.rep("═", 60))
print("\n📊 Servicios Disponibles:")
print("   • GraphService     → _G.Services.Graph")
print("   • EnergyService    → _G.Services.Energy")
print("   • LevelService     → _G.Services.Level")
print("   • AlgorithmService → _G.Services.Algorithm ⭐")
print("   • UIService        → _G.Services.UI ⭐")
print("   • AudioService     → _G.Services.Audio ⭐")
print("   • RewardService    → _G.Services.Reward ⭐")
print("   • MisionManager    → _G.Services.Misiones")
print("   • InventoryManager → _G.Services.Inventory")
print("\n💡 Ejemplo de uso en scripts:")
print("   local LevelService = _G.Services.Level")
print("   LevelService:loadLevel(0)")
print("\n" .. string.rep("═", 60) .. "\n")

-- ============================================
-- SCRIPT DE CONFIGURACIÓN INICIAL (Opcional)
-- ============================================

-- Si quieres cargar un nivel al iniciar el servidor (para testing):
-- Descomenta la línea siguiente:

-- task.wait(2)  -- Esperar a que todo esté listo
-- LevelService:loadLevel(0)  -- Cargar Nivel 0 (Tutorial)

return {
	GraphService = GraphService,
	EnergyService = EnergyService,
	LevelService = LevelService,
	MisionManager = MisionManager,
	InventoryManager = InventoryManager
}