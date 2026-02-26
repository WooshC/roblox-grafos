-- Boot.server.lua
-- Punto de entrada único del servidor para EDA Quest v2.
--
-- FIX CRÍTICO: Con CharacterAutoLoads = false, Roblox NO copia StarterGui a
-- PlayerGui automáticamente hasta que el personaje spawne. Como el menú no
-- tiene personaje, hay que copiar la GUI manualmente al conectarse.
--
-- Ubicación Roblox: ServerScriptService/Boot.server.lua

local RS         = game:GetService("ReplicatedStorage")
local Players    = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local Workspace  = game:GetService("Workspace")

-- ── 1. Sin spawn automático ────────────────────────────────────────────────
Players.CharacterAutoLoads = false

-- ── 2. Esperar EventRegistry ───────────────────────────────────────────────
local eventsFolder = RS:WaitForChild("Events", 15)
if not eventsFolder then
	error("[EDA v2] Boot: Events no apareció en 15s.")
end

local remotesFolder  = eventsFolder:WaitForChild("Remotes", 5)
local serverReadyEv  = remotesFolder:WaitForChild("ServerReady",       5)
local requestPlayLEv = remotesFolder:WaitForChild("RequestPlayLevel",  5)
local levelReadyEv   = remotesFolder:WaitForChild("LevelReady",        5)
local levelUnloadedEv = remotesFolder:WaitForChild("LevelUnloaded", 5)  -- servidor→cliente tras volver al menú
local returnToMenuEv = remotesFolder:WaitForChild("ReturnToMenu",      5)
local getProgressFn  = remotesFolder:WaitForChild("GetPlayerProgress", 5)
local updateScoreEv  = remotesFolder:WaitForChild("UpdateScore",       5)

-- ── 3. Cargar servicios ────────────────────────────────────────────────────
local LevelLoader        = require(script.Parent:WaitForChild("LevelLoader",        10))
local DataService        = require(script.Parent:WaitForChild("DataService",        10))
local ScoreTracker       = require(script.Parent:WaitForChild("ScoreTracker",       10))
local ConectarCables     = require(script.Parent:WaitForChild("ConectarCables",     10))
local ZoneTriggerManager = require(script.Parent:WaitForChild("ZoneTriggerManager", 10))
local MissionService     = require(script.Parent:WaitForChild("MissionService",     10))
local LevelsConfig       = require(RS:WaitForChild("Config", 5):WaitForChild("LevelsConfig", 5))

-- Cachear RemoteEvents y BindableEvents de zonas para conectar MissionService
local bindablesFolder = eventsFolder:WaitForChild("Bindables", 5)
local zoneEnteredEv   = bindablesFolder and bindablesFolder:FindFirstChild("ZoneEntered")
local zoneExitedEv    = bindablesFolder and bindablesFolder:FindFirstChild("ZoneExited")
local restartLevelEv  = remotesFolder:WaitForChild("RestartLevel", 5)
local levelCompletedEv = remotesFolder:WaitForChild("LevelCompleted", 5)

-- Conectar ZoneEntered/ZoneExited → MissionService
if zoneEnteredEv then
	zoneEnteredEv.Event:Connect(function(data)
		MissionService.onZoneEntered(data and data.nombre)
	end)
end
if zoneExitedEv then
	zoneExitedEv.Event:Connect(function(data)
		MissionService.onZoneExited(data and data.nombre)
	end)
end

ScoreTracker:init(updateScoreEv)
print("[EDA v2] ✅ LevelLoader + DataService + ScoreTracker + ConectarCables + ZoneTriggerManager + MissionService cargados")

-- ── 4. Copiar StarterGui → PlayerGui manualmente ──────────────────────────
-- Roblox solo hace esto automáticamente al spawnear el personaje.
-- Con CharacterAutoLoads = false nunca ocurre solo, así que lo hacemos aquí.
local function copyGuiToPlayer(player)
	local playerGui = player:WaitForChild("PlayerGui", 10)
	if not playerGui then
		warn("[EDA v2] PlayerGui no encontrado para", player.Name)
		return
	end

	for _, gui in ipairs(StarterGui:GetChildren()) do
		if not playerGui:FindFirstChild(gui.Name) then
			local clone = gui:Clone()
			clone.Parent = playerGui
			print("[EDA v2] ✅ GUI →", gui.Name, "copiada a", player.Name)
		end
	end
end

-- ── 5. Jugador conectado ───────────────────────────────────────────────────
local function onPlayerAdded(player)
	-- Copiar GUI primero (sin esperar DataService)
	task.spawn(function()
		copyGuiToPlayer(player)
	end)

	-- Pre-cargar datos del DataStore en paralelo
	task.spawn(function()
		DataService:load(player)
	end)

	-- Delay para dar tiempo a que la GUI arranque sus LocalScripts en el cliente
	task.delay(2, function()
		if player and player.Parent then
			serverReadyEv:FireClient(player)
			print("[EDA v2] ServerReady →", player.Name)
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)

-- Para jugadores ya conectados (pruebas en Studio con Play Solo)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- ── 6. GetPlayerProgress ───────────────────────────────────────────────────
getProgressFn.OnServerInvoke = function(player)
	return DataService:getProgressForClient(player)
end

-- ── 7. RequestPlayLevel ────────────────────────────────────────────────────
requestPlayLEv.OnServerEvent:Connect(function(player, nivelID)
	print("[EDA v2] RequestPlayLevel — Jugador:", player.Name, "/ Nivel:", nivelID)

	if type(nivelID) ~= "number" then
		warn("[EDA v2] nivelID inválido:", tostring(nivelID))
		return
	end

	local ok, err = pcall(function()
		LevelLoader:load(nivelID, player)
	end)

	if ok then
		-- LevelLoader colocó el nivel en Workspace como "NivelActual"
		-- y ya disparó LevelReady al cliente. Ahora activamos el gameplay.
		local nivelActual = Workspace:FindFirstChild("NivelActual")
		if nivelActual then
			local config         = LevelsConfig[nivelID]
			local adjacencias    = config and config.Adyacencias or nil
			local puntosConexion = config and config.Puntuacion and config.Puntuacion.PuntosConexion or 50
			local penaFallo      = config and config.Puntuacion and config.Puntuacion.PenaFallo      or 10

			-- FIX: convertir dict Zonas → array { {nombre, trigger} }
			-- ZoneTriggerManager usa #zonas == 0 como guarda; #dict == 0 siempre en Lua
			-- → sin esta conversión ninguna zona se registra jamás
			local function buildZonasArray(zonasDict)
				local arr = {}
				for nombre, cfg in pairs(zonasDict or {}) do
					if cfg.Trigger then
						table.insert(arr, { nombre = nombre, trigger = cfg.Trigger })
					end
				end
				return arr
			end
			local zonasArr = buildZonasArray(config and config.Zonas)

			ScoreTracker:startLevel(player, nivelID, puntosConexion, penaFallo)
			MissionService.activate(config, nivelID, player, remotesFolder, ScoreTracker, DataService)
			ConectarCables.activate(nivelActual, adjacencias, player, ScoreTracker, MissionService)
			ZoneTriggerManager.activate(nivelActual, zonasArr, player)
			print("[EDA v2] ✅ ScoreTracker + ConectarCables + ZoneTriggerManager activos — Nivel", nivelID,
				"/ adyacencias:", adjacencias ~= nil and "definidas" or "modo permisivo",
				"/ zonas:", #zonasArr)
		else
			warn("[EDA v2] NivelActual no encontrado en Workspace tras cargar")
		end
	else
		warn("[EDA v2] Error al cargar nivel:", err)
		if player and player.Parent then
			levelReadyEv:FireClient(player, {
				nivelID = nivelID,
				error   = "Error interno al cargar el nivel.",
			})
		end
	end
end)

-- ── 8. ReturnToMenu ────────────────────────────────────────────────────────
returnToMenuEv.OnServerEvent:Connect(function(player)
	print("[EDA v2] ReturnToMenu — Jugador:", player.Name)

	-- Notificar al cliente INMEDIATAMENTE para que MenuController refresque los datos
	-- antes de que el jugador pueda hacer clic en "Jugar" de nuevo.
	-- Se hace aquí al inicio porque el caché de DataService ya fue actualizado
	-- cuando MissionService guardó el resultado al completar las misiones.
	if levelUnloadedEv and player and player.Parent then
		levelUnloadedEv:FireClient(player)
	end

	-- Desactivar gameplay ANTES de destruir el nivel
	MissionService.deactivate()
	ConectarCables.deactivate()
	ZoneTriggerManager.deactivate()
	ScoreTracker:reset(player)

	local ok, err = pcall(function()
		LevelLoader:unload()
		if player.Character then
			player.Character:Destroy()
			player.Character = nil
		end
	end)

	if not ok then
		warn("[EDA v2] Error al volver al menú:", err)
	end
end)

-- ── 9. RestartLevel ────────────────────────────────────────────────────────
-- Cliente pide reiniciar el mismo nivel desde la pantalla de victoria.
if restartLevelEv then
	restartLevelEv.OnServerEvent:Connect(function(player, nivelID)
		if type(nivelID) ~= "number" then return end
		print("[EDA v2] RestartLevel — Jugador:", player.Name, "/ Nivel:", nivelID)

		-- Limpiar todo primero (igual que ReturnToMenu)
		MissionService.deactivate()
		ConectarCables.deactivate()
		ZoneTriggerManager.deactivate()
		ScoreTracker:reset(player)

		local ok, err = pcall(function()
			LevelLoader:unload()
			if player.Character then
				player.Character:Destroy()
				player.Character = nil
			end
		end)

		-- Re-cargar el mismo nivel
		local ok2, err2 = pcall(function()
			LevelLoader:load(nivelID, player)
		end)

		if ok2 then
			local nivelActual = Workspace:FindFirstChild("NivelActual")
			if nivelActual then
				local config         = LevelsConfig[nivelID]
				local adjacencias    = config and config.Adyacencias or nil
				local puntosConexion = config and config.Puntuacion and config.Puntuacion.PuntosConexion or 50
				local penaFallo      = config and config.Puntuacion and config.Puntuacion.PenaFallo      or 10
				local function buildZonasArray(zonasDict)
					local arr = {}
					for nombre, cfg in pairs(zonasDict or {}) do
						if cfg.Trigger then table.insert(arr, { nombre = nombre, trigger = cfg.Trigger }) end
					end
					return arr
				end
				local zonasArr = buildZonasArray(config and config.Zonas)
				ScoreTracker:startLevel(player, nivelID, puntosConexion, penaFallo)
				MissionService.activate(config, nivelID, player, remotesFolder, ScoreTracker, DataService)
				ConectarCables.activate(nivelActual, adjacencias, player, ScoreTracker, MissionService)
				ZoneTriggerManager.activate(nivelActual, zonasArr, player)
				print("[EDA v2] ✅ RestartLevel completado — Nivel", nivelID)
			end
		else
			warn("[EDA v2] RestartLevel: error al re-cargar nivel:", err2)
		end
	end)
end

-- ── 10. Guardar al desconectarse ────────────────────────────────────────────
Players.PlayerRemoving:Connect(function(player)
	DataService:onPlayerLeaving(player)
end)

print("[EDA v2] ✅ Boot completo — CharacterAutoLoads=false — Servidor listo")