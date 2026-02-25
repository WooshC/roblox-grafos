-- Boot.server.lua
-- Punto de entrada único del servidor para EDA Quest v2.
-- Secuencia garantizada:
--   1. Espera que EventRegistry haya creado los eventos
--   2. Carga LevelLoader (el único servicio necesario en Fase 0)
--   3. Notifica a jugadores conectados que el servidor está listo
--   4. Escucha RequestPlayLevel y delega a LevelLoader
--
-- Ubicación Roblox: ServerScriptService/Boot.server.lua
-- IMPORTANTE: EventRegistry debe ejecutarse antes. En Studio, asegúrate de que
-- EventRegistry esté por encima de Boot en el explorador, o usa un nombre
-- que lo ponga primero alfabéticamente (ej: "00_EventRegistry.server.lua").

local RS      = game:GetService("ReplicatedStorage")
local SSS     = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- ── 1. Esperar EventRegistry ───────────────────────────────────────────────
local eventsFolder = RS:WaitForChild("EDAEvents", 15)
if not eventsFolder then
	error("[EDA v2] Boot: EDAEvents no apareció en 15s. ¿Corrió EventRegistry?")
end

local remotesFolder = eventsFolder:WaitForChild("Remotes", 5)
local serverReadyEv  = remotesFolder:WaitForChild("ServerReady",      5)
local requestPlayLEv = remotesFolder:WaitForChild("RequestPlayLevel",  5)
local returnToMenuEv = remotesFolder:WaitForChild("ReturnToMenu",      5)

-- ── 2. Cargar servicios ────────────────────────────────────────────────────
-- LevelLoader es el único servicio de Fase 0.
-- En fases futuras aquí se cargarán GraphService, ScoreTracker, etc.
--
-- Buscamos LevelLoader en la misma carpeta que este script (script.Parent),
-- sin asumir ningún nombre de carpeta concreto.
local LevelLoader = require(script.Parent:WaitForChild("LevelLoader", 10))
print("[EDA v2] ✅ LevelLoader cargado")

-- ── 3. Notificar jugadores cuando el servidor está listo ───────────────────
local function notifyPlayerReady(player)
	-- Pequeña espera para que el cliente cargue la GUI primero
	task.delay(1, function()
		if player and player.Parent then
			serverReadyEv:FireClient(player)
			print("[EDA v2] ServerReady → ", player.Name)
		end
	end)
end

-- Jugadores que se unan después del boot
Players.PlayerAdded:Connect(notifyPlayerReady)

-- Jugadores que ya estaban conectados cuando arrancó el boot
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(notifyPlayerReady, player)
end

-- ── 4. Manejar RequestPlayLevel ────────────────────────────────────────────
requestPlayLEv.OnServerEvent:Connect(function(player, nivelID)
	print("[EDA v2] RequestPlayLevel — Jugador:", player.Name, "/ Nivel:", nivelID)

	if type(nivelID) ~= "number" then
		warn("[EDA v2] RequestPlayLevel: nivelID inválido recibido:", tostring(nivelID))
		return
	end

	local ok, err = pcall(function()
		LevelLoader:load(nivelID, player)
	end)

	if not ok then
		warn("[EDA v2] Error al cargar nivel:", err)
	end
end)

-- ── 5. Manejar ReturnToMenu ────────────────────────────────────────────────
returnToMenuEv.OnServerEvent:Connect(function(player)
	print("[EDA v2] ReturnToMenu — Jugador:", player.Name)
	-- Fase 0: solo descargar el nivel
	-- Fases futuras: GameplayManager:deactivate(), ScoreTracker:reset(), etc.
	local ok, err = pcall(function()
		LevelLoader:unload()
	end)
	if not ok then
		warn("[EDA v2] Error al descargar nivel:", err)
	end
end)

print("[EDA v2] ✅ Boot completo — Servidor EDA Quest v2 listo")
