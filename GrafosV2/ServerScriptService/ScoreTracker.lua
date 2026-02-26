-- ScoreTracker.lua
-- Singleton servidor: rastrea conexiones, fallos, tiempo y puntos de misiones.
--
-- Fuente de puntos visible en HUD: SOLO misiones (via setMisionPuntaje).
-- Conexiones/desconexiones solo se registran internamente para estadísticas.
--
-- Ubicación Roblox: ServerScriptService/ScoreTracker  (ModuleScript)

local ScoreTracker = {}

local _updateEv = nil
local _data     = {}  -- keyed por player.UserId

function ScoreTracker:init(updateScoreEv)
	_updateEv = updateScoreEv
	print("[ScoreTracker] ✅ init completado")
end

function ScoreTracker:startLevel(player, nivelID, puntosConexion, penaFallo)
	_data[player.UserId] = {
		nivelID        = nivelID,
		conexiones     = 0,
		fallos         = 0,
		startTime      = os.clock(),
		puntosConexion = puntosConexion or 50,
		penaFallo      = penaFallo      or 10,
		misionPuntaje  = 0,
	}
	self:_notify(player)
	print("[ScoreTracker] startLevel — Nivel:", nivelID, "/ Jugador:", player.Name)
end

-- Solo registra el contador; NO actualiza HUD (los puntos visibles son de misiones)
function ScoreTracker:registrarConexion(player)
	local d = _data[player.UserId]
	if not d then return end
	d.conexiones = d.conexiones + 1
end

function ScoreTracker:registrarFallo(player)
	local d = _data[player.UserId]
	if not d then return end
	d.fallos = d.fallos + 1
end

function ScoreTracker:registrarDesconexion(player)
	local d = _data[player.UserId]
	if not d then return end
	d.conexiones = math.max(0, d.conexiones - 1)
end

-- Llamado por MissionService al completar/revocar misiones.
-- ES el único que actualiza el HUD de puntaje.
function ScoreTracker:setMisionPuntaje(player, puntos)
	local d = _data[player.UserId]
	if not d then
		warn("[ScoreTracker] setMisionPuntaje — sin datos para", player.Name)
		return
	end
	d.misionPuntaje = puntos or 0
	self:_notify(player)
end

-- Devuelve snapshot completo. Llamado por MissionService justo DESPUÉS de
-- setMisionPuntaje, así que d.misionPuntaje ya está actualizado.
function ScoreTracker:finalize(player)
	local d = _data[player.UserId]
	if not d then
		warn("[ScoreTracker] finalize — sin datos para", player.Name)
		return { conexiones=0, fallos=0, tiempo=0, puntajeBase=0, nivelID=0 }
	end
	local tiempo = math.floor(os.clock() - d.startTime)
	local snap = {
		nivelID      = d.nivelID,
		conexiones   = d.conexiones,
		fallos       = d.fallos,
		tiempo       = tiempo,
		puntajeBase  = d.misionPuntaje,
	}
	print(string.format("[ScoreTracker] finalize → nivelID=%s puntaje=%d conexiones=%d fallos=%d tiempo=%d",
		tostring(snap.nivelID), snap.puntajeBase, snap.conexiones, snap.fallos, snap.tiempo))
	return snap
end

function ScoreTracker:reset(player)
	if player then
		_data[player.UserId] = nil
		print("[ScoreTracker] reset — Jugador:", player.Name)
	end
end

function ScoreTracker:_notify(player)
	if not _updateEv then return end
	local d = _data[player.UserId]
	if not d then return end
	_updateEv:FireClient(player, {
		conexiones  = d.conexiones,
		puntajeBase = d.misionPuntaje,
	})
end

return ScoreTracker