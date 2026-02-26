-- ScoreTracker.lua
-- Singleton servidor: rastrea conexiones, fallos, tiempo y puntos de misiones.
--
-- BUGS CORREGIDOS:
--
-- [BUG ACIERTOS] d.conexiones bajaba con registrarDesconexion(), por lo que
--   finalize() devolvía el número de cables ACTIVOS al final, no el total
--   histórico de conexiones correctas hechas durante el nivel.
--   FIX: Añadir d.aciertosTotal que solo sube, nunca baja. finalize() lo
--   incluye como snap.aciertos. MissionService ya guarda snap.aciertos en
--   DataStore. HUDController ya lo lee con snap.aciertos || snap.conexiones.
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
		conexiones     = 0,       -- cables activos en este momento (sube y baja)
		aciertosTotal  = 0,       -- FIX: total histórico de conexiones correctas (solo sube)
		fallos         = 0,
		startTime      = os.clock(),
		puntosConexion = puntosConexion or 50,
		penaFallo      = penaFallo      or 10,
		misionPuntaje  = 0,
	}
	self:_notify(player)
	print("[ScoreTracker] startLevel — Nivel:", nivelID, "/ Jugador:", player.Name)
end

-- Registra una conexión correcta.
-- conexiones = cables activos ahora (puede bajar si se desconecta)
-- aciertosTotal = total histórico (NUNCA baja)
function ScoreTracker:registrarConexion(player)
	local d = _data[player.UserId]
	if not d then return end
	d.conexiones    = d.conexiones + 1
	d.aciertosTotal = d.aciertosTotal + 1  -- FIX: histórico acumulado
end

function ScoreTracker:registrarFallo(player)
	local d = _data[player.UserId]
	if not d then return end
	d.fallos = d.fallos + 1
end

-- Al desconectar un cable baja el contador de cables activos,
-- pero NO toca aciertosTotal (ese es histórico).
function ScoreTracker:registrarDesconexion(player)
	local d = _data[player.UserId]
	if not d then return end
	d.conexiones = math.max(0, d.conexiones - 1)
	-- aciertosTotal NO cambia: la conexión correcta ya fue registrada
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

-- Devuelve snapshot completo. Llamado por MissionService al completar nivel.
-- Incluye aciertos (histórico) además de conexiones (cables activos al final).
function ScoreTracker:finalize(player)
	local d = _data[player.UserId]
	if not d then
		warn("[ScoreTracker] finalize — sin datos para", player.Name)
		return { conexiones=0, aciertos=0, fallos=0, tiempo=0, puntajeBase=0, nivelID=0 }
	end
	local tiempo = math.floor(os.clock() - d.startTime)
	local snap = {
		nivelID      = d.nivelID,
		conexiones   = d.conexiones,       -- cables activos al terminar
		aciertos     = d.aciertosTotal,    -- FIX: total histórico de conexiones correctas
		fallos       = d.fallos,
		tiempo       = tiempo,
		puntajeBase  = d.misionPuntaje,
	}
	print(string.format(
		"[ScoreTracker] finalize → nivelID=%s puntaje=%d conexiones=%d aciertos=%d fallos=%d tiempo=%d",
		tostring(snap.nivelID), snap.puntajeBase, snap.conexiones,
		snap.aciertos, snap.fallos, snap.tiempo))
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