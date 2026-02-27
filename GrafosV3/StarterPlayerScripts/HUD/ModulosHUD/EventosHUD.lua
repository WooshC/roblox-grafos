-- StarterPlayerScripts/HUD/ModulosHUD/EventosHUD.lua
-- Centraliza referencias a RemoteEvents para el HUD

local EventosHUD = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local eventosFolder = ReplicatedStorage:WaitForChild("EventosGrafosV3", 15)
local remotosFolder = eventosFolder:WaitForChild("Remotos", 5)

-- RemoteEvents del servidor que escucha el HUD
EventosHUD.nivelListo = remotosFolder:WaitForChild("NivelListo")
EventosHUD.actualizarMisiones = remotosFolder:WaitForChild("ActualizarMisiones")
EventosHUD.actualizarPuntuacion = remotosFolder:WaitForChild("ActualizarPuntuacion")
EventosHUD.nivelCompletado = remotosFolder:WaitForChild("NivelCompletado")

-- RemoteEvents que el HUD puede enviar al servidor
EventosHUD.volverAlMenu = remotosFolder:WaitForChild("VolverAlMenu")
EventosHUD.reiniciarNivel = remotosFolder:WaitForChild("ReiniciarNivel")

return EventosHUD
