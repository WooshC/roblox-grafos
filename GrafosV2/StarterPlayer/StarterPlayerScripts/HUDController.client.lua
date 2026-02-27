-- HUDController.client.lua
-- Orquestador puro - solo conecta eventos y delega
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Esperar GUI
local hud = playerGui:WaitForChild("GUIExploradorV2", 30)
if not hud then warn("[HUDController] GUIExploradorV2 no encontrado"); return end

-- Evitar doble ejecución
if hud:GetAttribute("HUDControllerActive") then return end
hud:SetAttribute("HUDControllerActive", true)

-- Importar módulos
local HUDModules = script.Parent.HUDModules
local HUDEvents = require(HUDModules.HUDEvents)
local HUDFade = require(HUDModules.HUDFade)
local HUDScore = require(HUDModules.HUDScore)
local HUDModal = require(HUDModules.HUDModal)
local HUDMisionPanel = require(HUDModules.HUDMisionPanel)
local HUDVictory = require(HUDModules.HUDVictory)

-- Inicializar módulos con referencia al hud
HUDFade.init(hud)
HUDScore.init(hud)
HUDModal.init(hud, HUDFade)
HUDMisionPanel.init(hud)
HUDVictory.init(hud, HUDFade)

-- Conectar eventos del servidor usando :Connect() en .OnClientEvent
HUDEvents.levelReady.OnClientEvent:Connect(function(data)
	if data and data.error then return end
	HUDFade.reset()
	HUDMisionPanel.reset()
	HUDVictory.hide()
	-- BUG FIX: Forzar cámara Custom (doble seguridad con ClientBoot)
	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	print("[HUDController] LevelReady | estado reseteado")
end)

HUDEvents.updateMissions.OnClientEvent:Connect(function(data)
	HUDMisionPanel.rebuild(data)
end)

HUDEvents.updateScore.OnClientEvent:Connect(function(data)
	HUDScore.set(data.puntajeBase)
end)

HUDEvents.levelCompleted.OnClientEvent:Connect(function(snap)
	print("[HUDController] LevelCompleted recibido:", snap ~= nil and "con datos" or "SIN DATOS")
	HUDVictory.show(snap)
end)

print("[EDA v2] ✅ HUDController refactorizado activo")
