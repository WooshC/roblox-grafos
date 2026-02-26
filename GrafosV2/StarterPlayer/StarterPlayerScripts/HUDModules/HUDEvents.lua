-- HUDEvents.lua
-- Centraliza referencias a RemoteEvents para el HUD
-- Uso: local HUDEvents = require(HUDModules.HUDEvents)

local HUDEvents = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local eventsFolder = ReplicatedStorage:WaitForChild("Events", 15)
local remotesFolder = eventsFolder:WaitForChild("Remotes", 5)

-- RemoteEvents del servidor que escucha el HUD
HUDEvents.levelReady = remotesFolder:WaitForChild("LevelReady")
HUDEvents.updateMissions = remotesFolder:WaitForChild("UpdateMissions")
HUDEvents.updateScore = remotesFolder:WaitForChild("UpdateScore")
HUDEvents.levelCompleted = remotesFolder:WaitForChild("LevelCompleted")

-- RemoteEvents que el HUD puede enviar al servidor
HUDEvents.returnToMenu = remotesFolder:WaitForChild("ReturnToMenu")
HUDEvents.restartLevel = remotesFolder:WaitForChild("RestartLevel")

return HUDEvents
