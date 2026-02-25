-- Boot.server.lua
-- Punto de entrada único del servidor para EDA Quest v2.
-- Secuencia garantizada:
--   1. CharacterAutoLoads = false  (personaje solo aparece al entrar a un nivel)
--   2. Espera EventRegistry
--   3. Carga LevelLoader + DataService
--   4. Pre-carga datos del jugador al unirse
--   5. Responde GetPlayerProgress (RemoteFunction)
--   6. Escucha RequestPlayLevel → LevelLoader:load()
--   7. Escucha ReturnToMenu → unload + destruir personaje
--   8. Guarda datos al desconectarse
--
-- Ubicación Roblox: ServerScriptService/Boot.server.lua

local RS      = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- ── 1. Sin spawn automático ────────────────────────────────────────────────
-- El personaje se crea explícitamente en LevelLoader:load() al entrar a un nivel.
-- En el menú el jugador no tiene personaje → no cae al vacío.
Players.CharacterAutoLoads = false

-- ── 2. Esperar EventRegistry ───────────────────────────────────────────────
local eventsFolder = RS:WaitForChild("Events", 15)
if not eventsFolder then
	error("[EDA v2] Boot: EDAEvents no apareció en 15s. ¿Corrió EventRegistry?")
end

local remotesFolder  = eventsFolder:WaitForChild("Remotes", 5)
local serverReadyEv  = remotesFolder:WaitForChild("ServerReady",       5)
local requestPlayLEv = remotesFolder:WaitForChild("RequestPlayLevel",  5)
local levelReadyEv   = remotesFolder:WaitForChild("LevelReady",        5)
local levelUnloadEv  = remotesFolder:WaitForChild("LevelUnloaded",     5)
local returnToMenuEv = remotesFolder:WaitForChild("ReturnToMenu",      5)
local getProgressFn  = remotesFolder:WaitForChild("GetPlayerProgress", 5)

-- ── 3. Cargar servicios ────────────────────────────────────────────────────
local LevelLoader = require(script.Parent:WaitForChild("LevelLoader", 10))
local DataService = require(script.Parent:WaitForChild("DataService", 10))
print("[EDA v2] ✅ LevelLoader + DataService cargados")

-- ── 4. Jugador conectado: pre-cargar datos + notificar GUI ─────────────────
local function onPlayerAdded(player)
	-- Pre-cargar datos del DataStore para que GetPlayerProgress responda rápido
	task.spawn(function()
		DataService:load(player)
	end)

	-- Con CharacterAutoLoads=false, StarterGui NO se replica a PlayerGui hasta
	-- que el personaje cargue por primera vez. Este LoadCharacter() dispara esa
	-- replicación → MenuController, HUDController y los demás LocalScripts de
	-- StarterGui pueden ejecutarse y mostrar el menú al jugador.
	-- LevelLoader:load() destruirá y recargará el personaje al entrar a un nivel.
	-- Durante el menú el personaje estará en el SpawnLocation del mundo menú;
	-- MenuController fija la cámara al escenario configurado (Part "CamaraMenu").
	player:LoadCharacter()

	-- Delay ampliado: da tiempo al personaje de cargar y a los scripts de
	-- StarterGui de inicializarse antes de que ServerReady active la GUI.
	task.delay(2, function()
		if player and player.Parent then
			serverReadyEv:FireClient(player)
			print("[EDA v2] ServerReady →", player.Name)
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- ── 5. GetPlayerProgress ───────────────────────────────────────────────────
getProgressFn.OnServerInvoke = function(player)
	return DataService:getProgressForClient(player)
end

-- ── 6. RequestPlayLevel ────────────────────────────────────────────────────
requestPlayLEv.OnServerEvent:Connect(function(player, nivelID)
	print("[EDA v2] RequestPlayLevel — Jugador:", player.Name, "/ Nivel:", nivelID)

	if type(nivelID) ~= "number" then
		warn("[EDA v2] RequestPlayLevel: nivelID inválido:", tostring(nivelID))
		return
	end

	local ok, err = pcall(function()
		LevelLoader:load(nivelID, player)
	end)

	if not ok then
		warn("[EDA v2] Error al cargar nivel:", err)
		-- Desbloquear al cliente: sin este Fire la pantalla quedaría en negro
		if player and player.Parent then
			levelReadyEv:FireClient(player, {
				nivelID = nivelID,
				error   = "Error interno al cargar el nivel.",
			})
		end
	end
end)

-- ── 7. ReturnToMenu ────────────────────────────────────────────────────────
returnToMenuEv.OnServerEvent:Connect(function(player)
	print("[EDA v2] ReturnToMenu — Jugador:", player.Name)

	local ok, err = pcall(function()
		LevelLoader:unload()
		-- Destruir personaje al volver al menú → no flota en el mundo vacío
		if player.Character then
			player.Character:Destroy()
		end
	end)

	if not ok then
		warn("[EDA v2] Error al volver al menú:", err)
	end

	-- Notificar al cliente que el nivel fue descargado.
	-- MenuController usa este evento para resetear isLoading y limpiar overlays.
	if player and player.Parent then
		levelUnloadEv:FireClient(player)
	end
end)

-- ── 8. Guardar al desconectarse ────────────────────────────────────────────
Players.PlayerRemoving:Connect(function(player)
	DataService:onPlayerLeaving(player)
end)

print("[EDA v2] ✅ Boot completo — Servidor EDA Quest v2 listo")
