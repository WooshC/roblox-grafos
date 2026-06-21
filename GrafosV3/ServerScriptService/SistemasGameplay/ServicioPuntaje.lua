-- ServerScriptService/SistemasGameplay/ServicioPuntaje.lua
-- Sistema de rastreo de puntuación para GrafosV3
-- Adaptado de GrafosV2/ScoreTracker a la arquitectura V3

local ServicioPuntaje = {}

-- Validador de conexiones para obtener conteo real al finalizar
local ValidadorConexiones = require(script.Parent:WaitForChild("ValidadorConexiones"))

local _eventoActualizar = nil
local _datos = {}  -- keyed por player.UserId

function ServicioPuntaje:init(eventoActualizarPuntuacion)
	_eventoActualizar = eventoActualizarPuntuacion
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
		estrellasMision = 0,
		dinero = nil,         -- se inicializa aparte con iniciarPresupuesto
	}
	self:_notificar(jugador)
	print("[ServicioPuntaje] iniciarNivel — Nivel:", nivelID, "/ Jugador:", jugador.Name)
end

-- Inicializa el presupuesto de dinero para niveles que lo requieren.
function ServicioPuntaje:iniciarPresupuesto(jugador, cantidad)
	local d = _datos[jugador.UserId]
	if not d then return end
	d.dinero = cantidad or 0
	self:_notificar(jugador)
	print("[ServicioPuntaje] Presupuesto inicial:", d.dinero, "/ Jugador:", jugador.Name)
end

-- Intenta gastar una cantidad de dinero. Devuelve true si se pudo.
function ServicioPuntaje:gastar(jugador, cantidad)
	local d = _datos[jugador.UserId]
	if not d then return false end
	if d.dinero == nil then return false end
	if (d.dinero or 0) < cantidad then return false end
	d.dinero = d.dinero - cantidad
	self:_notificar(jugador)
	-- print(string.format("[ServicioPuntaje] Gasto: %d | Restante: %d | Jugador: %s", cantidad, d.dinero, jugador.Name))
	return true
end

-- Devuelve el dinero actual del jugador (0 si no tiene presupuesto activo).
function ServicioPuntaje:obtenerDinero(jugador)
	local d = _datos[jugador.UserId]
	if not d or d.dinero == nil then return 0 end
	return d.dinero
end

-- Reembolsa dinero al jugador (por ejemplo, al desconectar un cable).
function ServicioPuntaje:reembolsar(jugador, cantidad)
	local d = _datos[jugador.UserId]
	if not d then return end
	if d.dinero == nil then return end
	d.dinero = d.dinero + (cantidad or 0)
	self:_notificar(jugador)
	-- print(string.format("[ServicioPuntaje] Reembolso: +%d | Nuevo saldo: %d | Jugador: %s", cantidad or 0, d.dinero, jugador.Name))
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
function ServicioPuntaje:fijarPuntajeMision(jugador, puntos, estrellas)
	local d = _datos[jugador.UserId]
	if not d then
		warn("[ServicioPuntaje] fijarPuntajeMision — sin datos para", jugador.Name)
		return
	end
	d.puntajeMision = puntos or 0
	d.estrellasMision = estrellas or 0
	self:_notificar(jugador)
end

-- Intenta gastar puntos de misión. Devuelve true si se pudo.
function ServicioPuntaje:gastarPuntajeMision(jugador, cantidad)
	local d = _datos[jugador.UserId]
	if not d then return false end
	if (d.puntajeMision or 0) < cantidad then return false end
	d.puntajeMision = d.puntajeMision - cantidad
	self:_notificar(jugador)
	return true
end

-- Descuenta puntos de misión SIN bloquear por saldo insuficiente.
-- Permite puntaje negativo para situaciones de emergencia (ej. reparar sin presupuesto).
function ServicioPuntaje:descontarPuntajeMision(jugador, cantidad)
	local d = _datos[jugador.UserId]
	if not d then return false end
	cantidad = cantidad or 0
	d.puntajeMision = (d.puntajeMision or 0) - cantidad
	self:_notificar(jugador)
	return true
end

-- Devuelve snapshot completo. Llamado por ServicioMisiones al completar nivel.
function ServicioPuntaje:finalizar(jugador)
	local d = _datos[jugador.UserId]
	if not d then
		warn("[ServicioPuntaje] finalizar — sin datos para", jugador.Name)
		return { conexiones=0, aciertos=0, fallos=0, tiempo=0, puntajeBase=0, nivelID=0 }
	end
	local tiempo = math.floor(os.clock() - d.tiempoInicio)
	
	-- Usar conteo real del ValidadorConexiones (fuente de verdad)
	local conexionesFinales = d.conexiones
	if ValidadorConexiones and ValidadorConexiones.contarConexiones then
		conexionesFinales = ValidadorConexiones.contarConexiones()
	end
	
	local snap = {
		nivelID = d.nivelID,
		conexiones = conexionesFinales,  -- Conexiones actuales al finalizar (del Validador)
		aciertosTotal = conexionesFinales,  -- ACIERTOS = conexiones actuales (no histórico)
		fallos = d.fallos,
		tiempo = tiempo,
		puntajeBase = d.puntajeMision,
	}
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
		estrellas = d.estrellasMision,
		dinero = d.dinero,
	})
end

return ServicioPuntaje
