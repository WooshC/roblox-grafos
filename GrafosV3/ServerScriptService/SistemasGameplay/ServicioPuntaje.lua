-- ServerScriptService/SistemasGameplay/ServicioPuntaje.lua
-- Sistema de rastreo de puntuación para GrafosV3
-- Adaptado de GrafosV2/ScoreTracker a la arquitectura V3

local ServicioPuntaje = {}

local _eventoActualizar = nil
local _datos = {}  -- keyed por player.UserId

function ServicioPuntaje:init(eventoActualizarPuntuacion)
	_eventoActualizar = eventoActualizarPuntuacion
	print("[ServicioPuntaje] ✅ init completado")
end

function ServicioPuntaje:iniciarNivel(jugador, nivelID, puntosConexion, penaFallo)
	_datos[jugador.UserId] = {
		nivelID = nivelID,
		conexiones = 0,       -- cables activos en este momento (sube y baja)
		aciertosTotal = 0,    -- total histórico de conexiones correctas (solo sube)
		fallos = 0,
		tiempoInicio = os.clock(),
		puntosConexion = puntosConexion or 50,
		penaFallo = penaFallo or 10,
		puntajeMision = 0,
	}
	self:_notificar(jugador)
	print("[ServicioPuntaje] iniciarNivel — Nivel:", nivelID, "/ Jugador:", jugador.Name)
end

-- Registra una conexión correcta.
-- conexiones = cables activos ahora (puede bajar si se desconecta)
-- aciertosTotal = total histórico (NUNCA baja)
function ServicioPuntaje:registrarConexion(jugador)
	local d = _datos[jugador.UserId]
	if not d then return end
	d.conexiones = d.conexiones + 1
	d.aciertosTotal = d.aciertosTotal + 1
end

function ServicioPuntaje:registrarFallo(jugador)
	local d = _datos[jugador.UserId]
	if not d then return end
	d.fallos = d.fallos + 1
end

-- Al desconectar un cable baja el contador de cables activos,
-- pero NO toca aciertosTotal (ese es histórico).
function ServicioPuntaje:registrarDesconexion(jugador)
	local d = _datos[jugador.UserId]
	if not d then return end
	d.conexiones = math.max(0, d.conexiones - 1)
	-- aciertosTotal NO cambia: la conexión correcta ya fue registrada
end

-- Llamado por ServicioMisiones al completar/revocar misiones.
-- ES el único que actualiza el HUD de puntaje.
function ServicioPuntaje:fijarPuntajeMision(jugador, puntos)
	local d = _datos[jugador.UserId]
	if not d then
		warn("[ServicioPuntaje] fijarPuntajeMision — sin datos para", jugador.Name)
		return
	end
	d.puntajeMision = puntos or 0
	self:_notificar(jugador)
end

-- Devuelve snapshot completo. Llamado por ServicioMisiones al completar nivel.
function ServicioPuntaje:finalizar(jugador)
	local d = _datos[jugador.UserId]
	if not d then
		warn("[ServicioPuntaje] finalizar — sin datos para", jugador.Name)
		return { conexiones=0, aciertos=0, fallos=0, tiempo=0, puntajeBase=0, nivelID=0 }
	end
	local tiempo = math.floor(os.clock() - d.tiempoInicio)
	local snap = {
		nivelID = d.nivelID,
		conexiones = d.conexiones,
		aciertosTotal = d.aciertosTotal,
		fallos = d.fallos,
		tiempo = tiempo,
		puntajeBase = d.puntajeMision,
	}
	print(string.format(
		"[ServicioPuntaje] finalizar → nivelID=%s puntaje=%d conexiones=%d aciertos=%d fallos=%d tiempo=%d",
		tostring(snap.nivelID), snap.puntajeBase, snap.conexiones,
		snap.aciertosTotal, snap.fallos, snap.tiempo))
	return snap
end

function ServicioPuntaje:reiniciar(jugador)
	if jugador then
		_datos[jugador.UserId] = nil
		print("[ServicioPuntaje] reiniciar — Jugador:", jugador.Name)
	end
end

function ServicioPuntaje:_notificar(jugador)
	if not _eventoActualizar then return end
	local d = _datos[jugador.UserId]
	if not d then return end
	_eventoActualizar:FireClient(jugador, {
		conexiones = d.conexiones,
		puntajeBase = d.puntajeMision,
	})
end

return ServicioPuntaje
