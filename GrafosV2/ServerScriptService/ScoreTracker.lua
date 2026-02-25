-- ScoreTracker.lua
-- Singleton servidor: rastrea aciertos (conexiones válidas), fallos e tiempo por jugador.
-- Es el ÚNICO módulo que toca los datos de puntaje durante el gameplay.
--
-- Separación de responsabilidades:
--   · ConectarCables  → llama registrarConexion / registrarFallo
--   · HUD             → recibe UpdateScore (RemoteEvent) y muestra puntajeBase
--   · VictoryScreen   → recibe el snapshot de finalize() con desglose completo
--
-- Ubicación Roblox: ServerScriptService/ScoreTracker  (ModuleScript)

local ScoreTracker = {}

-- ── Estado ──────────────────────────────────────────────────────────────────
local _updateEv = nil  -- RemoteEvent "UpdateScore"

-- Keyed por player.UserId
-- { nivelID, conexiones, fallos, startTime, puntosConexion, penaFallo }
local _data = {}

-- ── init ─────────────────────────────────────────────────────────────────────
-- Llamado desde Boot.server.lua después de obtener los RemoteEvents.
function ScoreTracker:init(updateScoreEv)
	_updateEv = updateScoreEv
	print("[ScoreTracker] ✅ init completado")
end

-- ── startLevel ───────────────────────────────────────────────────────────────
-- Llamado ANTES de activar ConectarCables para el nivel.
-- puntosConexion y penaFallo pueden venir de LevelsConfig.Puntuacion (opcionales).
function ScoreTracker:startLevel(player, nivelID, puntosConexion, penaFallo)
	_data[player.UserId] = {
		nivelID        = nivelID,
		conexiones     = 0,
		fallos         = 0,
		startTime      = os.clock(),
		puntosConexion = puntosConexion or 50,
		penaFallo      = penaFallo      or 10,
	}
	self:_notify(player)
	print("[ScoreTracker] startLevel — Nivel:", nivelID, "/ Jugador:", player.Name)
end

-- ── registrarConexion ────────────────────────────────────────────────────────
-- Llamado por ConectarCables al colocar un cable válido.
-- Aumenta el puntajeBase visible en el HUD.
function ScoreTracker:registrarConexion(player)
	local d = _data[player.UserId]
	if not d then
		warn("[ScoreTracker] registrarConexion — sin datos para", player.Name)
		return
	end
	d.conexiones = d.conexiones + 1
	self:_notify(player)
end

-- ── registrarFallo ────────────────────────────────────────────────────────────
-- Llamado por ConectarCables al intentar una conexión inválida.
-- NO notifica al cliente: la penalización es una "sorpresa" en la pantalla final.
function ScoreTracker:registrarFallo(player)
	local d = _data[player.UserId]
	if not d then return end
	d.fallos = d.fallos + 1
	-- Intencional: sin _notify → el jugador no ve la penalización en vivo
end

-- ── finalize ─────────────────────────────────────────────────────────────────
-- Devuelve snapshot completo para VictoryScreen / RewardService.
-- Llamado cuando MissionService o GameplayManager detecta victoria.
function ScoreTracker:finalize(player)
	local d = _data[player.UserId]
	if not d then
		return { conexiones = 0, fallos = 0, tiempo = 0, puntajeBase = 0, nivelID = 0 }
	end
	local tiempo      = math.floor(os.clock() - d.startTime)
	local puntajeBase = d.conexiones * d.puntosConexion
	return {
		nivelID      = d.nivelID,
		conexiones   = d.conexiones,
		fallos       = d.fallos,
		tiempo       = tiempo,
		puntajeBase  = puntajeBase,
	}
end

-- ── reset ────────────────────────────────────────────────────────────────────
-- Limpia el estado al salir del nivel SIN victoria (progreso descartado).
function ScoreTracker:reset(player)
	if player then
		_data[player.UserId] = nil
		print("[ScoreTracker] reset — Jugador:", player.Name)
	end
end

-- ── _notify (privado) ─────────────────────────────────────────────────────────
-- Envía puntajeBase actual al cliente para el HUD.
function ScoreTracker:_notify(player)
	if not _updateEv then return end
	local d = _data[player.UserId]
	if not d then return end
	_updateEv:FireClient(player, {
		conexiones  = d.conexiones,
		puntajeBase = d.conexiones * d.puntosConexion,
	})
end

return ScoreTracker
