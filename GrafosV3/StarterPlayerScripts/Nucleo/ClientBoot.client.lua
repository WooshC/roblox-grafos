-- StarterPlayerScripts/Nucleo/ClientBoot.client.lua
-- Punto de entrada del cliente para GrafosV3

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local jugador = Players.LocalPlayer
local playerGui = jugador:WaitForChild("PlayerGui")

print("[GrafosV3] === ClientBoot Iniciando ===")

-- ═══════════════════════════════════════════════════════════════════════════════
-- 1. CARGAR SISTEMAS COMPARTIDOS PRIMERO
-- ═══════════════════════════════════════════════════════════════════════════════

-- Cargar ControladorAudio (sistema compartido)
-- NOTA: El ControladorAudio se ejecuta automaticamente como LocalScript
-- Solo necesitamos verificar que existe y esta listo

local ControladorAudio = nil
local StarterPlayerScripts = game:GetService("StarterPlayer").StarterPlayerScripts

-- Esperar a que el ControladorAudio exista
local moduloAudio = StarterPlayerScripts:WaitForChild("Compartido", 5):WaitForChild("ControladorAudio", 5)
if moduloAudio then
	local exito, resultado = pcall(function()
		return require(moduloAudio)
	end)
	
	if exito then
		ControladorAudio = resultado
		print("[GrafosV3] ControladorAudio cargado exitosamente")
	else
		warn("[GrafosV3] Error cargando ControladorAudio:", resultado)
	end
else
	warn("[GrafosV3] ControladorAudio no encontrado")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 2. ESPERAR ESTRUCTURA DE EVENTOS
-- ═══════════════════════════════════════════════════════════════════════════════

local eventos = RS:WaitForChild("EventosGrafosV3")
local remotos = eventos:WaitForChild("Remotos")
local servidorListo = remotos:WaitForChild("ServidorListo")

-- ═══════════════════════════════════════════════════════════════════════════════
-- 3. CONFIGURAR GUI INICIAL
-- ═══════════════════════════════════════════════════════════════════════════════

-- Referencias a GUI
local menuGui = playerGui:WaitForChild("EDAQuestMenu")
local hudGui = playerGui:WaitForChild("GUIExploradorV2")

-- Estado inicial: ambos desactivados hasta que el servidor diga
menuGui.Enabled = false
hudGui.Enabled = false

print("[GrafosV3] === ClientBoot Listo - Esperando ServerReady ===")

-- ═══════════════════════════════════════════════════════════════════════════════
-- 4. MANEJAR EVENTOS DEL SERVIDOR
-- ═══════════════════════════════════════════════════════════════════════════════

-- Cuando el servidor notifica que esta listo
servidorListo.OnClientEvent:Connect(function()
	print("[GrafosV3] ServidorListo recibido - Activando Menu")
	
	-- Mostrar menu, ocultar HUD
	menuGui.Enabled = true
	hudGui.Enabled = false
	
	-- El ControladorMenu.client.lua, AudioMenu.client.lua y AudioGameplay.client.lua
	-- se ejecutan automaticamente (son LocalScripts en StarterPlayerScripts)
end)

-- Evento para cuando se descarga un nivel (volver al menu)
local nivelDescargado = remotos:WaitForChild("NivelDescargado")
nivelDescargado.OnClientEvent:Connect(function()
	print("[GrafosV3] NivelDescargado recibido - Volviendo al menu")
	
	menuGui.Enabled = true
	hudGui.Enabled = false
end)

-- Evento para cuando inicia un nivel
local nivelListo = remotos:WaitForChild("NivelListo")
nivelListo.OnClientEvent:Connect(function(data)
	if data and data.error then
		warn("[GrafosV3] Error al cargar nivel:", data.error)
		return
	end
	
	print("[GrafosV3] NivelListo recibido - Activando Gameplay")
	
	-- Ocultar menu, mostrar HUD
	menuGui.Enabled = false
	hudGui.Enabled = true
end)

print("[GrafosV3] === ClientBoot Inicializacion Completa ===")
