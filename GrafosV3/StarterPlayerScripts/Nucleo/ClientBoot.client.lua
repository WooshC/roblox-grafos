-- StarterPlayerScripts/Nucleo/ClientBoot.client.lua
-- Punto de entrada del cliente para GrafosV3

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local jugador = Players.LocalPlayer
local playerGui = jugador:WaitForChild("PlayerGui")

print("[GrafosV3] === ClientBoot Iniciando ===")

-- Esperar estructura de eventos
local eventos = RS:WaitForChild("EventosGrafosV3")
local remotos = eventos:WaitForChild("Remotos")
local servidorListo = remotos:WaitForChild("ServidorListo")

-- Referencias a GUI
local menuGui = playerGui:WaitForChild("EDAQuestMenu")
local hudGui = playerGui:WaitForChild("GUIExploradorV2")

-- Estado inicial: ambos desactivados hasta que el servidor diga
menuGui.Enabled = false
hudGui.Enabled = false

print("[GrafosV3] === ClientBoot Listo - Esperando ServerReady ===")

-- Cuando el servidor notifica que esta listo
servidorListo.OnClientEvent:Connect(function()
	print("[GrafosV3] ServidorListo recibido - Activando Menu")
	
	-- Mostrar menu, ocultar HUD
	menuGui.Enabled = true
	hudGui.Enabled = false
	
	-- El ControladorMenu.client.lua se ejecuta automaticamente
	-- (es un LocalScript en StarterPlayerScripts)
end)

-- Evento para cuando se descarga un nivel (volver al menu)
local nivelDescargado = remotos:WaitForChild("NivelDescargado")
nivelDescargado.OnClientEvent:Connect(function()
	print("[GrafosV3] NivelDescargado recibido - Volviendo al menu")
	
	menuGui.Enabled = true
	hudGui.Enabled = false
end)
