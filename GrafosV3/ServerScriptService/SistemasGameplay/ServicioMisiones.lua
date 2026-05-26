-- ServerScriptService/SistemasGameplay/ServicioMisiones.lua
-- Sistema de validación de misiones para GrafosV3
-- Adaptado de GrafosV2/MissionService a la arquitectura V3

local ServicioMisiones = {}

local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local GrafoHelpers        = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("GrafoHelpers"))

-- Validador de conexiones para obtener conteo real al finalizar
local ValidadorConexiones = require(script.Parent:WaitForChild("ValidadorConexiones"))
local TimerEmergencia = require(script.Parent:WaitForChild("TimerEmergencia"))

-- ── Estado interno ────────────────────────────────────────────────────────────
local _activo = false
local _jugador = nil
local _nivelID = nil
local _config = nil
local _misiones = {}
local _completadas = {}
local _permanentes = {}
local _cables = {}
local _seleccionados = {}
local _zonaActual = nil
local _servicioPuntaje = nil
local _servicioDatos = nil
local _puntosAcum = 0
local _eventoActualizarMisiones = nil
local _eventoNivelCompletado    = nil
local _estrellasLimitadasPorDialogos = false  -- true si se limitaron estrellas por diálogos incorrectos

-- ── Timer de emergencia (instancia delegada) ──────────────────────────────────
local _timerEmergencia = nil
local _eventoTimerEmergencia = nil
local _eventoReproducirEfecto = nil
local _dialogoIniciadoConn = nil
local _dialogoTerminadoConn = nil
local _zonasVisitadas = {}

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function clavePar(a, b)
	return GrafoHelpers.clavePar(a, b)
end

local function contarConexiones(nodo)
	local count = 0
	for key, _ in pairs(_cables) do
		local a, b = key:match("^(.+)|(.+)$")
		if a == nodo or b == nodo then count = count + 1 end
	end
	return count
end

local function esAlcanzable(inicio, meta, visitados)
	if inicio == meta then return true end
	visitados = visitados or {}
	visitados[inicio] = true
	for key, _ in pairs(_cables) do
		local a, b = key:match("^(.+)|(.+)$")
		local otro = nil
		if a == inicio and not visitados[b] then otro = b
		elseif b == inicio and not visitados[a] then otro = a end
		if otro then
			if esAlcanzable(otro, meta, visitados) then return true end
		end
	end
	return false
end

local function calcularEstrellasHelper(puntos)
	local puntuacion = _config and _config.Puntuacion or {}
	local estrellas = 0
	if puntos >= (puntuacion.TresEstrellas or 999999) then estrellas = 3
	elseif puntos >= (puntuacion.DosEstrellas or 999999) then estrellas = 2
	elseif puntos > 0 then estrellas = 1
	end

	-- Verificar si el nivel requiere responder todos los diálogos correctamente para 3 estrellas
	if _config and _config.RequiereDialogosCorrectos and estrellas >= 3 then
		local obtenerDialogosCorrectos = _G.ObtenerDialogosCorrectos
		if obtenerDialogosCorrectos and _jugador then
			local correctas = obtenerDialogosCorrectos(_jugador)
			local requeridas = _config.TotalPreguntasDialogo or 0
			if correctas < requeridas then
				-- Limitar a 2 estrellas si no respondió todas las preguntas correctamente
				estrellas = 2
				_estrellasLimitadasPorDialogos = true
				print(string.format(
					"[ServicioMisiones] Estrellas limitadas a 2 — Diálogos correctos: %d/%d",
					correctas, requeridas))
			end
		end
	end

	return estrellas
end

-- ── Validadores ───────────────────────────────────────────────────────────────
local Validadores = {}

Validadores.ARISTA_CREADA = function(params)
	local key = clavePar(params.NodoA, params.NodoB)
	return _cables[key] == true
end

Validadores.ARISTA_DIRIGIDA = function(params)
	local key = clavePar(params.NodoOrigen, params.NodoDestino)
	return _cables[key] == true
end

Validadores.GRADO_NODO = function(params)
	return contarConexiones(params.Nodo) >= (params.GradoRequerido or 1)
end

Validadores.NODO_SELECCIONADO = function(params)
	-- Si Nodo es "ANY" o nil, cualquier nodo seleccionado cuenta
	if params.Nodo == "ANY" or params.Nodo == nil or params.Nodo == "" then
		-- Verificar si hay ALGÚN nodo seleccionado
		for nodo, seleccionado in pairs(_seleccionados) do
			if seleccionado then return true end
		end
		return false
	end
	-- Modo específico: solo ese nodo cuenta
	return _seleccionados[params.Nodo] == true
end

Validadores.GRAFO_CONEXO = function(params)
	local nodos = params.Nodos or {}
	if #nodos < 2 then return true end
	for i = 1, #nodos do
		for j = 1, #nodos do
			if i ~= j then
				if not esAlcanzable(nodos[i], nodos[j], {}) then
					return false
				end
			end
		end
	end
	return true
end

Validadores.EMERGENCIA = function(params)
	-- Primero verificar que el grafo esté conexo (misma lógica que GRAFO_CONEXO)
	local nodos = params.Nodos or {}
	if #nodos < 2 then return true end
	for i = 1, #nodos do
		for j = 1, #nodos do
			if i ~= j then
				if not esAlcanzable(nodos[i], nodos[j], {}) then
					return false
				end
			end
		end
	end
	-- Luego verificar que no haya expirado el tiempo
	if _timerEmergencia and _timerEmergencia:estaFallido() then
		return false
	end
	return true
end

-- ── Notificar cliente ─────────────────────────────────────────────────────────
local function construirPayload(overrideAllComplete)
	local porZona = {}
	for _, m in ipairs(_misiones) do
		local z = m.Zona or "General"
		if not porZona[z] then porZona[z] = { total=0, completadas=0, misiones={} } end
		local estado = _completadas[m.ID] and "completada" or "pendiente"
		table.insert(porZona[z].misiones, {
			id = m.ID,
			texto = m.Texto,
			puntos = m.Puntos or 0,
			estado = estado,
			zona = z,
		})
		porZona[z].total = porZona[z].total + 1
		if estado == "completada" then porZona[z].completadas = porZona[z].completadas + 1 end
	end
	return {
		porZona = porZona,
		zonaActual = _zonaActual,
		allComplete = overrideAllComplete,
	}
end

-- ════════════════════════════════════════════════════════════════════════════
-- TIMER DE EMERGENCIA (delegado a TimerEmergencia.lua)
-- ════════════════════════════════════════════════════════════════════════════

local function _onTimerExpirado(misionID)
	-- Penalización: -500 puntos por fallar la emergencia
	_puntosAcum = math.max(0, _puntosAcum - 500)
	if _servicioPuntaje then _servicioPuntaje:fijarPuntajeMision(_jugador, _puntosAcum, calcularEstrellasHelper(_puntosAcum)) end
	print(string.format("[ServicioMisiones] 💥 Penalización -500 pts | Puntaje actual: %d", _puntosAcum))
	verificarYNotificar()
end

local function _crearTimerEmergencia()
	_timerEmergencia = TimerEmergencia.nuevo({
		eventoTimer = _eventoTimerEmergencia,
		jugador     = _jugador,
		onExpirado  = _onTimerExpirado,
	})
end

local function iniciarTimerEmergenciaSiPendiente(nombreZona)
	if not nombreZona or nombreZona == "" then return end
	if not _timerEmergencia then return end
	for _, m in ipairs(_misiones) do
		if m.Zona == nombreZona and m.Tipo == "EMERGENCIA" and not _completadas[m.ID] then
			if _timerEmergencia and _timerEmergencia:obtenerMisionID() ~= m.ID and not _timerEmergencia:estaFallido() and not _timerEmergencia:estaCompletado() then
				_timerEmergencia:iniciar(m)
			end
			break
		end
	end
end


local function notificar(allComplete)
	if not _eventoActualizarMisiones or not _jugador or not _jugador.Parent then return end
	_eventoActualizarMisiones:FireClient(_jugador, construirPayload(allComplete))
end

-- ── checkAndNotify ────────────────────────────────────────────────────────────
local function verificarYNotificar()
	if not _activo then return end

	local cambiado = false

	for _, m in ipairs(_misiones) do
		if _permanentes[m.ID] then continue end

		local validador = Validadores[m.Tipo]
		if not validador then continue end

		local ok = validador(m.Parametros or {})

		if ok and not _completadas[m.ID] then
			_completadas[m.ID] = true
			-- Solo marcar como permanente si NO es una misión de cableado ni de conectividad
			-- ARISTA_CREADA, ARISTA_DIRIGIDA y GRAFO_CONEXO pueden revocarse al desconectar
			-- EMERGENCIA es permanente: una vez superada o fallida, no cambia
			if m.Tipo ~= "ARISTA_CREADA" and m.Tipo ~= "ARISTA_DIRIGIDA" and m.Tipo ~= "GRAFO_CONEXO" then
				_permanentes[m.ID] = true
			end
			_puntosAcum = _puntosAcum + (m.Puntos or 0)
			if _servicioPuntaje then _servicioPuntaje:fijarPuntajeMision(_jugador, _puntosAcum, calcularEstrellasHelper(_puntosAcum)) end
			cambiado = true
			print(string.format("[ServicioMisiones] ✅ Misión %d completada — +%d pts (total: %d)",
				m.ID, m.Puntos or 0, _puntosAcum))

			-- Si es emergencia, detener timer, limpiar efectos de daño y notificar éxito
			if m.Tipo == "EMERGENCIA" then
				if _timerEmergencia then _timerEmergencia:marcarComoSuperada() end
			end

			-- EVENTO DE ENERGIA TRATADO POR SERVICIO INDEPENDIENTE AHORA
		elseif not ok and _completadas[m.ID] and not _permanentes[m.ID] then
			_completadas[m.ID] = nil
			_puntosAcum = math.max(0, _puntosAcum - (m.Puntos or 0))
			if _servicioPuntaje then _servicioPuntaje:fijarPuntajeMision(_jugador, _puntosAcum, calcularEstrellasHelper(_puntosAcum)) end
			cambiado = true
			-- EVENTO DE ENERGIA TRATADO POR SERVICIO INDEPENDIENTE AHORA
		end
	end

	local total = #_misiones
	local completadasCount = 0
	for _ in pairs(_completadas) do completadasCount = completadasCount + 1 end
	local allComplete = (total > 0 and completadasCount >= total)

	if cambiado then
		notificar(allComplete or nil)
	end

	-- ── VICTORIA ──────────────────────────────────────────────────────────
	if allComplete then

		if _eventoNivelCompletado and _jugador then
			local snap = nil
			if _servicioPuntaje then
				snap = _servicioPuntaje:finalizar(_jugador)
			else
				-- Si no hay servicio de puntaje, crear un snap básico
				snap = {
					nivelID = _nivelID,
					conexiones = 0,
					aciertosTotal = 0,
					fallos = 0,
					tiempo = 0,
					puntajeBase = _puntosAcum,
				}
			end

			print(string.format(
				"[ServicioMisiones] Snapshot → puntaje=%d / aciertosTotal=%d / conexiones=%d / fallos=%d / tiempo=%d",
				snap.puntajeBase, snap.aciertosTotal or 0, snap.conexiones, snap.fallos, snap.tiempo
				))

			-- Guardar en DataStore antes de mostrar victoria
			if _servicioDatos and _nivelID ~= nil then
				local estrellas = calcularEstrellasHelper(snap.puntajeBase)

				-- Usar conteo real del ValidadorConexiones (conexiones actuales)
				local conexionesActuales = snap.conexiones
				if ValidadorConexiones.contarConexiones then
					conexionesActuales = ValidadorConexiones.contarConexiones()
				end
				local aciertosGuardar = conexionesActuales

				_servicioDatos.guardarResultado(_jugador, _nivelID, {
					puntaje = snap.puntajeBase,
					estrellas = estrellas,
					aciertos = aciertosGuardar,
					fallos = snap.fallos,
					tiempo = snap.tiempo,
				})
			end

			-- Obtener conexiones actuales del validador para mayor precisión
			local conexionesFinales = snap.conexiones
			if ValidadorConexiones.contarConexiones then
				conexionesFinales = ValidadorConexiones.contarConexiones()
			end

			-- Enviar snap al cliente con campo "aciertos" = conexiones actuales
			local snapCliente = {
				nivelID = snap.nivelID,
				conexiones = conexionesFinales,
				aciertos = conexionesFinales,  -- ACIERTOS = conexiones actuales al finalizar
				fallos = snap.fallos,
				tiempo = snap.tiempo,
				puntajeBase = snap.puntajeBase,
				estrellasLimitadasPorDialogos = _estrellasLimitadasPorDialogos,
				totalPreguntasDialogo = (_config and _config.TotalPreguntasDialogo) or 0,
			}
			_eventoNivelCompletado:FireClient(_jugador, snapCliente)

			-- Notificar a ServicioLogros
			local notificarLogros = _G.NotificarNivelCompletadoLogros
			if notificarLogros and _jugador then
				notificarLogros(_jugador, _nivelID, snapCliente)
			end
		end

		_activo = false
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- API PÚBLICA
-- ════════════════════════════════════════════════════════════════════════════
-- (Timer de emergencia extraído a TimerEmergencia.lua)

function ServicioMisiones.activar(config, nivelID, jugador, eventos, servicioPuntaje, servicioDatos)
	_activo = true
	_jugador = jugador
	_nivelID = nivelID
	_config = config
	_misiones = (config and config.Misiones) or {}
	_completadas = {}
	_permanentes = {}
	_cables = {}
	_seleccionados = {}
	_zonaActual = nil
	_servicioPuntaje = servicioPuntaje
	_servicioDatos = servicioDatos
	_puntosAcum = 0
	_estrellasLimitadasPorDialogos = false
	_zonasVisitadas = {}
	if _timerEmergencia then _timerEmergencia:detener() end
	_timerEmergencia = nil

	if eventos then
		_eventoActualizarMisiones = eventos:FindFirstChild("ActualizarMisiones")
		_eventoNivelCompletado    = eventos:FindFirstChild("NivelCompletado")
		_eventoTimerEmergencia    = eventos:FindFirstChild("TimerEmergencia")

		_eventoReproducirEfecto = eventos:FindFirstChild("ReproducirEfecto")
		if not _eventoReproducirEfecto then
			-- Fallback: crear evento si EventRegistry aún no lo creó
			local rs = game:GetService("ReplicatedStorage")
			local eventosCarpeta = rs:FindFirstChild("EventosGrafosV3") or Instance.new("Folder")
			if not eventosCarpeta.Parent then eventosCarpeta.Name = "EventosGrafosV3"; eventosCarpeta.Parent = rs end
			local remotosCarpeta = eventosCarpeta:FindFirstChild("Remotos") or Instance.new("Folder")
			if not remotosCarpeta.Parent then remotosCarpeta.Name = "Remotos"; remotosCarpeta.Parent = eventosCarpeta end
			_eventoReproducirEfecto = Instance.new("RemoteEvent")
			_eventoReproducirEfecto.Name = "ReproducirEfecto"
			_eventoReproducirEfecto.Parent = remotosCarpeta
			print("[ServicioMisiones] 🔧 Creado ReproducirEfecto dinámicamente en activar()")
		end

		-- Escuchar pausa/reanudación desde diálogos (conexión sincrónica para evitar race conditions)
		local dialogoIniciado = eventos:FindFirstChild("DialogoIniciado") or eventos:WaitForChild("DialogoIniciado", 2)
		if dialogoIniciado and not _dialogoIniciadoConn then
			_dialogoIniciadoConn = dialogoIniciado.OnServerEvent:Connect(function(player)
				print(string.format("[ServicioMisiones] 📥 DialogoIniciado recibido de %s | _jugador=%s", tostring(player), tostring(_jugador)))
				if player == _jugador and _timerEmergencia then _timerEmergencia:pausar() end
			end)
			print("[ServicioMisiones] 🔌 Conectado DialogoIniciado")
		elseif not dialogoIniciado then
			warn("[ServicioMisiones] ❌ DialogoIniciado no encontrado en eventos")
		else
			print("[ServicioMisiones] ⚠️ DialogoIniciado ya conectado, saltando")
		end
		local dialogoTerminado = eventos:FindFirstChild("DialogoTerminado") or eventos:WaitForChild("DialogoTerminado", 2)
		if dialogoTerminado and not _dialogoTerminadoConn then
			_dialogoTerminadoConn = dialogoTerminado.OnServerEvent:Connect(function(player)
				print(string.format("[ServicioMisiones] 📥 DialogoTerminado recibido de %s | _jugador=%s", tostring(player), tostring(_jugador)))
				if player ~= _jugador then return end
				if _timerEmergencia then _timerEmergencia:reanudar() end
				-- Si el timer nunca se inició (primera vez), iniciarlo ahora
				-- Usar zona actual si existe; si no, buscar cualquier emergencia pendiente
				if _zonaActual then
					iniciarTimerEmergenciaSiPendiente(_zonaActual)
				else
					for _, m in ipairs(_misiones) do
						if m.Tipo == "EMERGENCIA" and not _completadas[m.ID] then
							if _timerEmergencia:obtenerMisionID() ~= m.ID and not _timerEmergencia:estaFallido() and not _timerEmergencia:estaCompletado() then
								_timerEmergencia:iniciar(m)
							end
							break
						end
					end
				end
			end)
			print("[ServicioMisiones] 🔌 Conectado DialogoTerminado")
		elseif not dialogoTerminado then
			warn("[ServicioMisiones] ❌ DialogoTerminado no encontrado en eventos")
		else
			print("[ServicioMisiones] ⚠️ DialogoTerminado ya conectado, saltando")
		end
	end

	_crearTimerEmergencia()

	task.delay(1, function()
		if _activo and _jugador and _jugador.Parent then notificar(nil) end
	end)

	print(string.format("[ServicioMisiones] activar — nivelID=%s / misiones=%d / jugador=%s",
		tostring(nivelID), #_misiones, jugador.Name))
end

function ServicioMisiones.desactivar()
	_activo = false
	_jugador = nil
	_nivelID = nil
	_misiones = {}
	_completadas = {}
	_permanentes = {}
	_cables = {}
	_seleccionados = {}
	_zonaActual = nil
	_servicioPuntaje = nil
	_puntosAcum = 0
	_eventoActualizarMisiones = nil
	_eventoNivelCompletado    = nil
	_servicioDatos = nil
	_config = nil

	-- Limpiar conexiones de diálogo y timer para evitar fugas entre niveles
	if _dialogoIniciadoConn then _dialogoIniciadoConn:Disconnect(); _dialogoIniciadoConn = nil end
	if _dialogoTerminadoConn then _dialogoTerminadoConn:Disconnect(); _dialogoTerminadoConn = nil end
	if _timerEmergencia then _timerEmergencia:detener() end
	_timerEmergencia = nil
	_eventoTimerEmergencia = nil
	_eventoReproducirEfecto = nil
	print("[ServicioMisiones] Desactivado — conexiones limpiadas")
end

function ServicioMisiones.alCrearCable(nomA, nomB)
	if not _activo then return end
	_cables[clavePar(nomA, nomB)] = true
	verificarYNotificar()
end

function ServicioMisiones.alEliminarCable(nomA, nomB)
	if not _activo then return end
	_cables[clavePar(nomA, nomB)] = nil
	verificarYNotificar()
end

function ServicioMisiones.alSeleccionarNodo(nomNodo)
	if not _activo then return end
	if _seleccionados[nomNodo] then return end
	_seleccionados[nomNodo] = true
	verificarYNotificar()
end

function ServicioMisiones.alEntrarZona(nombre)
	if not _activo then return end
	_zonaActual = nombre

	-- Iniciar timer de emergencia si hay una misión pendiente en esta zona
	for _, m in ipairs(_misiones) do
		if m.Zona == nombre and m.Tipo == "EMERGENCIA" and not _completadas[m.ID] then
			if _timerEmergencia and _timerEmergencia:obtenerMisionID() ~= m.ID and not _timerEmergencia:estaFallido() and not _timerEmergencia:estaCompletado() then
				_timerEmergencia:iniciar(m)
			end
			break
		end
	end

	notificar(nil)
end

function ServicioMisiones.alSalirZona(nombre)
	if not _activo then return end
	if _zonaActual == nombre then _zonaActual = nil; notificar(nil) end
end

function ServicioMisiones.obtenerEstadoMisiones()
	return construirPayload(nil)
end

function ServicioMisiones.estaActivo()
	return _activo
end

return ServicioMisiones
