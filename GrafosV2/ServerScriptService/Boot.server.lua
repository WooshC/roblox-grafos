-- Boot.server.lua
-- Punto de entrada unico del servidor para EDA Quest v2.
-- REFACTORIZADO: Ahora usa OrquestadorGameplay para gestionar modulos.
--
-- Regla de Oro: Mientras este el menu activo, TODO lo de gameplay esta desconectado.

local RS         = game:GetService("ReplicatedStorage")
local Players    = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local Workspace  = game:GetService("Workspace")

-- ── 1. Sin spawn automatico ─────────────────────────────────────────────────
Players.CharacterAutoLoads = false

-- ── 2. Esperar EventRegistry ────────────────────────────────────────────────
local eventsFolder = RS:WaitForChild("Events", 15)
if not eventsFolder then
	error("[EDA v2] Boot: Events no aparecio en 15s.")
end

local remotesFolder   = eventsFolder:WaitForChild("Remotes", 5)
local serverReadyEv   = remotesFolder:WaitForChild("ServerReady",       5)
local requestPlayLEv  = remotesFolder:WaitForChild("RequestPlayLevel",  5)
local levelReadyEv    = remotesFolder:WaitForChild("LevelReady",        5)
local levelUnloadedEv = remotesFolder:WaitForChild("LevelUnloaded",     5)
local returnToMenuEv  = remotesFolder:WaitForChild("ReturnToMenu",      5)
local getProgressFn   = remotesFolder:WaitForChild("GetPlayerProgress", 5)
local updateScoreEv   = remotesFolder:WaitForChild("UpdateScore",       5)
local restartLevelEv  = remotesFolder:WaitForChild("RestartLevel",      5)

-- ── 3. Cargar Orquestador y Servicios ───────────────────────────────────────
local OrquestadorGameplay = require(script.Parent.Gameplay:WaitForChild("OrquestadorGameplay", 10))
local LevelLoader         = require(script.Parent:WaitForChild("LevelLoader", 10))
local DataService         = require(script.Parent:WaitForChild("DataService", 10))
local ScoreTracker        = require(script.Parent:WaitForChild("ScoreTracker", 10))
local LevelsConfig        = require(RS:WaitForChild("Config", 5):WaitForChild("LevelsConfig", 5))

-- Cargar modulos legacy (temporalmente, hasta migrarlos a Gameplay/Modulos/)
local ConectarCables     = require(script.Parent:WaitForChild("ConectarCables", 10))
local ZoneTriggerManager = require(script.Parent:WaitForChild("ZoneTriggerManager", 10))
local MissionService     = require(script.Parent:WaitForChild("MissionService", 10))

-- Inicializar Orquestador con referencias a modulos
OrquestadorGameplay:inicializar()

-- Cachear BindableEvents de zonas para conectar MissionService (legacy)
local bindablesFolder = eventsFolder:WaitForChild("Bindables", 5)
local zoneEnteredEv   = bindablesFolder and bindablesFolder:FindFirstChild("ZoneEntered")
local zoneExitedEv    = bindablesFolder and bindablesFolder:FindFirstChild("ZoneExited")

-- Conectar ZoneEntered/ZoneExited → MissionService (legacy)
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
print("[EDA v2] ✅ OrquestadorGameplay + LevelLoader + DataService + ScoreTracker cargados")

-- ── 4. Copiar StarterGui → PlayerGui manualmente ──────────────────────────
local function copiarGuiAJugador(jugador)
	local playerGui = jugador:WaitForChild("PlayerGui", 10)
	if not playerGui then
		warn("[EDA v2] PlayerGui no encontrado para", jugador.Name)
		return
	end

	for _, gui in ipairs(StarterGui:GetChildren()) do
		if not playerGui:FindFirstChild(gui.Name) then
			local clone = gui:Clone()
			clone.Parent = playerGui
			print("[EDA v2] ✅ GUI →", gui.Name, "copiada a", jugador.Name)
		end
	end
end

-- ── 5. Jugador conectado ───────────────────────────────────────────────────
local function alJugadorAgregado(jugador)
	task.spawn(function()
		copiarGuiAJugador(jugador)
	end)

	task.spawn(function()
		DataService:load(jugador)
	end)

	task.delay(2, function()
		if jugador and jugador.Parent then
			serverReadyEv:FireClient(jugador)
			print("[EDA v2] ServerReady →", jugador.Name)
		end
	end)
end

Players.PlayerAdded:Connect(alJugadorAgregado)

for _, jugador in ipairs(Players:GetPlayers()) do
	task.spawn(alJugadorAgregado, jugador)
end

-- ── 6. GetPlayerProgress ───────────────────────────────────────────────────
getProgressFn.OnServerInvoke = function(jugador)
	return DataService:getProgressForClient(jugador)
end

-- ── 7. RequestPlayLevel ────────────────────────────────────────────────────
requestPlayLEv.OnServerEvent:Connect(function(jugador, idNivel)
	print("[EDA v2] RequestPlayLevel — Jugador:", jugador.Name, "/ Nivel:", idNivel)

	if type(idNivel) ~= "number" then
		warn("[EDA v2] idNivel invalido:", tostring(idNivel))
		return
	end

	local exito, error = pcall(function()
		LevelLoader:load(idNivel, jugador)
	end)

	if exito then
		local nivelActual = Workspace:FindFirstChild("NivelActual")
		if nivelActual then
			local configuracion = LevelsConfig[idNivel]
			
			-- Usar OrquestadorGameplay para activar TODOS los modulos
			local exitoOrquestador = OrquestadorGameplay:iniciarNivel(
				jugador, 
				idNivel, 
				configuracion,
				remotesFolder
			)
			
			if exitoOrquestador then
				print("[EDA v2] ✅ Gameplay iniciado via Orquestador — Nivel", idNivel)
			else
				warn("[EDA v2] ⚠️ OrquestadorGameplay fallo al iniciar, usando metodo legacy...")
				-- Fallback a metodo manual (legacy)
				local adjacencias    = configuracion and configuracion.Adyacencias or nil
				local puntosConexion = configuracion and configuracion.Puntuacion and configuracion.Puntuacion.PuntosConexion or 50
				local penaFallo      = configuracion and configuracion.Puntuacion and configuracion.Puntuacion.PenaFallo or 10
				
				local function construirArrayZonas(zonasDict)
					local arr = {}
					for nombre, cfg in pairs(zonasDict or {}) do
						if cfg.Trigger then
							table.insert(arr, { nombre = nombre, trigger = cfg.Trigger })
						end
					end
					return arr
				end
				local zonasArr = construirArrayZonas(configuracion and configuracion.Zonas)

				ScoreTracker:startLevel(jugador, idNivel, puntosConexion, penaFallo)
				MissionService.activate(configuracion, idNivel, jugador, remotesFolder, ScoreTracker, DataService)
				ConectarCables.activate(nivelActual, adjacencias, jugador, ScoreTracker, MissionService)
				ZoneTriggerManager.activate(nivelActual, zonasArr, jugador, configuracion.Zonas)
			end
		else
			warn("[EDA v2] NivelActual no encontrado en Workspace tras cargar")
		end
	else
		warn("[EDA v2] Error al cargar nivel:", error)
		if jugador and jugador.Parent then
			levelReadyEv:FireClient(jugador, {
				idNivel = idNivel,
				error   = "Error interno al cargar el nivel.",
			})
		end
	end
end)

-- ── 8. ReturnToMenu ────────────────────────────────────────────────────────
returnToMenuEv.OnServerEvent:Connect(function(jugador)
	print("[EDA v2] ReturnToMenu — Jugador:", jugador.Name)

	-- Notificar al cliente PRIMERO
	if levelUnloadedEv and jugador and jugador.Parent then
		levelUnloadedEv:FireClient(jugador)
	end

	-- Usar OrquestadorGameplay para detener TODO
	OrquestadorGameplay:detenerNivel()

	local exito, error = pcall(function()
		LevelLoader:unload()
		if jugador.Character then
			jugador.Character:Destroy()
			jugador.Character = nil
		end
	end)

	if not exito then
		warn("[EDA v2] Error al volver al menu:", error)
	end
end)

-- ── 9. RestartLevel ────────────────────────────────────────────────────────
if restartLevelEv then
	restartLevelEv.OnServerEvent:Connect(function(jugador, idNivel)
		if type(idNivel) ~= "number" then return end
		print("[EDA v2] RestartLevel — Jugador:", jugador.Name, "/ Nivel:", idNivel)

		-- Usar Orquestador para detener primero
		OrquestadorGameplay:detenerNivel()

		local exito, error = pcall(function()
			LevelLoader:unload()
			if jugador.Character then
				jugador.Character:Destroy()
				jugador.Character = nil
			end
		end)

		-- Re-cargar el mismo nivel
		local exito2, error2 = pcall(function()
			LevelLoader:load(idNivel, jugador)
		end)

		if exito2 then
			local configuracion = LevelsConfig[idNivel]
			local exitoOrquestador = OrquestadorGameplay:iniciarNivel(
				jugador, 
				idNivel, 
				configuracion,
				remotesFolder
			)
			
			if exitoOrquestador then
				print("[EDA v2] ✅ RestartLevel completado via Orquestador — Nivel", idNivel)
			else
				-- Fallback legacy
				local nivelActual = Workspace:FindFirstChild("NivelActual")
				if nivelActual then
					local adjacencias    = configuracion and configuracion.Adyacencias or nil
					local puntosConexion = configuracion and configuracion.Puntuacion and configuracion.Puntuacion.PuntosConexion or 50
					local penaFallo      = configuracion and configuracion.Puntuacion and configuracion.Puntuacion.PenaFallo or 10
					
					local function construirArrayZonas(zonasDict)
						local arr = {}
						for nombre, cfg in pairs(zonasDict or {}) do
							if cfg.Trigger then table.insert(arr, { nombre = nombre, trigger = cfg.Trigger }) end
						end
						return arr
					end
					local zonasArr = construirArrayZonas(configuracion and configuracion.Zonas)
					
					ScoreTracker:startLevel(jugador, idNivel, puntosConexion, penaFallo)
					MissionService.activate(configuracion, idNivel, jugador, remotesFolder, ScoreTracker, DataService)
					ConectarCables.activate(nivelActual, adjacencias, jugador, ScoreTracker, MissionService)
					ZoneTriggerManager.activate(nivelActual, zonasArr, jugador)
					print("[EDA v2] ✅ RestartLevel completado (legacy) — Nivel", idNivel)
				end
			end
		else
			warn("[EDA v2] RestartLevel: error al re-cargar nivel:", error2)
		end
	end)
end

-- ── 10. Guardar al desconectarse ────────────────────────────────────────────
Players.PlayerRemoving:Connect(function(jugador)
	-- Si el jugador esta en medio de un nivel, detener gameplay primero
	if OrquestadorGameplay:estaActivo() and OrquestadorGameplay:obtenerJugadorActual() == jugador then
		OrquestadorGameplay:detenerNivel()
	end
	DataService:onPlayerLeaving(jugador)
end)

print("[EDA v2] ✅ Boot completo con OrquestadorGameplay — Servidor listo")
