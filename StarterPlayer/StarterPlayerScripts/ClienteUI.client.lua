-- ================================================================
-- ClienteUI.client.lua (VERSION MODULAR - CORREGIDA)
-- Punto de entrada principal para la UI del cliente
-- ================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Estructura de Carpetas
local Cliente = script.Parent:WaitForChild("Cliente")
local Services = Cliente:WaitForChild("Services")

-- Servicios Modulares
local MapManager = require(Services:WaitForChild("MapManager"))
local MissionsManager = require(Services:WaitForChild("MissionsManager"))
local VisibilityManager = require(Services:WaitForChild("VisibilityManager"))
local EventManager = require(Services:WaitForChild("EventManager"))
local ButtonManager = require(Services:WaitForChild("ButtonManager"))
local ScoreManager = require(Services:WaitForChild("ScoreManager"))
local NodeLabelManager = require(Services:WaitForChild("NodeLabelManager"))

-- Configuración Global
local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))

-- ================================================================
-- ESTADO GLOBAL
-- ================================================================
local globalState = {
	mapaActivo = false,
	misionesActivo = false,
	zoomLevel = 90,
	enMenu = true,
	tieneMapa = false,
	tieneAlgo = false,
}

-- ================================================================
-- INICIALIZACIÓN
-- ================================================================
print("🚀 Cargando ClienteUI Modular (CORREGIDO)...")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:WaitForChild("GameUI")
-- Minimap GUI (para control de visibilidad)
local minimapGui = playerGui:WaitForChild("MinimapGUI")

print("✅ Encontradas referencias de UI")

-- ================================================================
-- PASO 1: INICIALIZAR SCOREMANAGER PRIMERO
-- ================================================================
print("📊 Inicializando ScoreManager...")
ScoreManager.initialize(screenGui)
print("✅ ScoreManager inicializado")

-- ================================================================
-- PASO 2: Inicializar otros Managers con Dependencias
-- ================================================================
MapManager.initialize(globalState, screenGui, {
	LevelsConfig = LevelsConfig,
	NodeLabelManager = NodeLabelManager,
	MissionsManager = MissionsManager
})

MissionsManager.initialize(globalState, screenGui, {
	LevelsConfig = LevelsConfig
})

-- Invertir la dependencia: MissionsManager necesita MapManager para cerrar mapa
MissionsManager.toggle = function(self)
    if not self.MapManager then self.MapManager = require(Services.MapManager) end
	-- Cerrar mapa si está abierto
	if globalState.mapaActivo then
		self.MapManager:disable()
	end
	globalState.misionesActivo = not globalState.misionesActivo
	if globalState.misionesActivo then
		self:show()
	else
		self:hide()
	end
end

VisibilityManager.initialize(globalState, screenGui, minimapGui)

EventManager.initialize(globalState, {
	MapManager = MapManager,
	MissionsManager = MissionsManager
})

ButtonManager.initialize(screenGui, {
	MapManager = MapManager,
	MissionsManager = MissionsManager,
	LevelsConfig = LevelsConfig
})

print("✅ Todos los managers inicializados")

-- ================================================================
-- PASO 3: Iniciar Lógica de los Servicios
-- ================================================================
NodeLabelManager.initialize({
    LevelsConfig = LevelsConfig
})

-- 🔥 CRÍTICO: Iniciar ScoreManager ANTES de los demás
print("🔄 Iniciando ScoreManager...")
ScoreManager:init()
print("✅ ScoreManager iniciado y escuchando cambios")

-- Iniciar otros servicios
MapManager:toggle(false) -- Asegurar apagado
VisibilityManager:init()
EventManager:init()
ButtonManager:init()

print("✅ ClienteUI Modular Inicializado Correctamente (CORREGIDO)")
print("   🎯 ScoreManager está escuchando cambios de leaderstats")
print("   💰 Los puntos se actualizarán en tiempo real")
print("   ⭐ Las estrellas se actualizarán en tiempo real")

-- ================================================================
-- PASO 4: Cargar AlgorithmExecutor (Sistema de Algoritmos)
-- ================================================================

print("🧠 Cargando AlgorithmExecutor...")
local success, result = pcall(function()
	return require(script.Parent:WaitForChild("AlgorithmExecutor", 5))
end)

if success and result then
	print("✅ AlgorithmExecutor cargado correctamente")
	print("   🧠 Sistema de ejecución de algoritmos activo")
else
	warn("⚠️ AlgorithmExecutor no encontrado o error: " .. tostring(result))
end

-- ================================================================
-- DEBUGGING: Verificar que ScoreManager funciona
-- ================================================================
task.wait(2)

-- Verificar que los listeners están activos
print("\n📊 === ESTADO INICIAL DE SCOREMANAGER ===")
print("Puntos actuales: " .. ScoreManager:getPoints())
print("Estrellas actuales: " .. ScoreManager:getStars())
print("Dinero actual: $" .. ScoreManager:getMoney())
print("=====================================\n")