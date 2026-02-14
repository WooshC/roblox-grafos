-- ClienteUI.client.lua
-- Punto de entrada principal del Refactor
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Estructura de Carpetas
local Cliente = script.Parent:WaitForChild("Cliente")
local Services = Cliente.Services
local Controllers = Cliente.Controllers
local Components = Cliente.Components

-- Servicios
local NetworkService = require(Services.NetworkService)
local StateManager = require(Services.StateManager)

-- Controladores
local UIManager = require(Controllers.UIManager)
local CameraController = require(Controllers.CameraController)
local VisualController = require(Controllers.VisualController)

-- Componentes (para actualizaciones directas si es necesario)
local ScorePanel = require(Components.ScorePanel)

-- ============================================================================
-- INICIALIZACIÓN
-- ============================================================================

print("🚀 Iniciando ClienteUI Refactorizado...")

-- 1. Inicializar Controladores
UIManager.init()
CameraController.init()
VisualController.init()

-- 2. Conectar Eventos de Red -> StateManager
NetworkService.subscribeToUIUpdates(function(data)
	if not data or not data.Type then return end
    print("🎨 Evento UI Recibido: " .. data.Type)

	if data.Type == "LevelReset" then
		print("🔄 Reseteando Estado Local...")
		StateManager.reset()
		-- Forzar actualización visual
		StateManager.set("energyUpdated", os.time())
		
	elseif data.Type == "Energy" then
		-- Actualizar nodos energizados
		local energizedNodes = data.EnergizedNodes or {}
		StateManager.set("energizedNodes", energizedNodes)
		-- Notificar cambio para VisualController
		StateManager.set("energyUpdated", os.time())
		
	elseif data.Type == "Algorithm" then
		-- Notificaciones de algoritmo
		local algo = data.Algoritmo
		local estado = data.Estado
		
		if estado == "started" then
			game:GetService("StarterGui"):SetCore("SendNotification", {
				Title = "Algoritmo";
				Text = "Ejecutando " .. algo .. "...";
				Duration = 3;
			})
		elseif estado == "completed" then
			game:GetService("StarterGui"):SetCore("SendNotification", {
				Title = "Algoritmo";
				Text = algo .. " finalizado.";
				Duration = 3;
			})
		end
	end
end)

NetworkService.subscribeToInventory(function(itemID, hasItem)
	print("🎒 Inventario: " .. itemID .. " = " .. tostring(hasItem))
	if itemID == "Mapa" then
		StateManager.set("hasMap", hasItem)
	elseif itemID == "Tablet" or itemID == "Algoritmo_BFS" or itemID == "Algoritmo_Dijkstra" then
		-- Simplificación: Si tiene cualquiera, tiene acceso a algoritmos
		StateManager.set("hasAlgorithm", hasItem) 
	end
end)

NetworkService.subscribeToMissions(function(index, completed)
	print("🎯 Misión Actualizada: " .. index .. " = " .. tostring(completed))
	local missions = StateManager.get("missions") or {}
	-- Asegurar que es tabla
	if type(missions) ~= "table" then missions = {} end
	
	missions[index] = completed
	StateManager.set("missions", missions) 
end)

-- 3. Conectar Leaderstats -> ScorePanel
local function updateScore()
	local player = Players.LocalPlayer
	local stats = player:FindFirstChild("leaderstats")
	local playerGui = player:WaitForChild("PlayerGui")
	local screenGui = playerGui:FindFirstChild("GameUI")
	
	if stats and screenGui then
		local p = stats:FindFirstChild("Puntos") and stats.Puntos.Value or 0
		local s = stats:FindFirstChild("Estrellas") and stats.Estrellas.Value or 0
		local m = stats:FindFirstChild("Money") and stats.Money.Value or 0
		
		ScorePanel.update(screenGui, p, s, m)
	end
end

task.spawn(function()
	local player = Players.LocalPlayer
	local stats = player:WaitForChild("leaderstats", 10)
	if stats then
		local p = stats:WaitForChild("Puntos", 5)
		local e = stats:WaitForChild("Estrellas", 5)
		local m = stats:WaitForChild("Money", 5)
		
		if p then p.Changed:Connect(updateScore) end
		if e then e.Changed:Connect(updateScore) end
		if m then m.Changed:Connect(updateScore) end
		
		updateScore()
	end
end)

-- 4. Sincronizar Nivel Inicial
local function syncLevel()
	local levelID = Players.LocalPlayer:GetAttribute("CurrentLevelID") or 0
	print("🗺️ Sincronizando Nivel ID: " .. levelID)
	StateManager.set("level.id", levelID)
	-- Forzar recarga visual
	StateManager.set("energyUpdated", os.time())
end

Players.LocalPlayer:GetAttributeChangedSignal("CurrentLevelID"):Connect(syncLevel)
task.wait(1) -- Pequeña espera para asegurar carga
syncLevel()


print("✅ ClienteUI Refactorizado Inicializado Correctamente")
