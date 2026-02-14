-- ================================================================
-- ClienteUI.client.lua
-- Punto de entrada principal (VERSION MODULAR)
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
print("🚀 Cargando ClienteUI Modular...")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:WaitForChild("GameUI")
-- Minimap GUI (para control de visibilidad)
local minimapGui = playerGui:WaitForChild("MinimapGUI")

-- 1. Inicializar Managers con Dependencias
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

ScoreManager.initialize(screenGui)

-- 2. Iniciar Lógica
NodeLabelManager.initialize({
    LevelsConfig = LevelsConfig
})
MapManager:toggle(false) -- Asegurar apagado
VisibilityManager:init()
EventManager:init()
ButtonManager:init()
ScoreManager:init()

print("✅ ClienteUI Modular Inicializado Correctamente")