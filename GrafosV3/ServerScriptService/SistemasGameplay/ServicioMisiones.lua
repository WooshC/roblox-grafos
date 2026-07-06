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
local _nodosReparados = {}  -- TG 07: { [nombreNodo] = true } nodos reparados manualmente
local _nodosSobrecargados = {}  -- { [nombreNodo] = true } nodos que sufrieron sobrecarga de grado
local _dialogosTerminados = {}  -- { [dialogoID] = true } diálogos cerrados durante el nivel
local _resultadoFinal = nil
local _mensajeFinal = nil
local _pesosTemporales = {}
local _actualizarPesosConn = nil

-- ── Timer de emergencia (instancia delegada) ──────────────────────────────────
local _timerEmergencia = nil
local _eventoTimerEmergencia = nil
local _eventoReproducirEfecto = nil
local _dialogoIniciadoConn = nil
local _dialogoTerminadoConn = nil
local _zonasVisitadas = {}
local _cooldownsDialogo = {}  -- [userId] = tick último evento

local function chequearCooldownDialogo(userId, segundos)
	segundos = segundos or 0.5
	local ahora = tick()
	local ultimo = _cooldownsDialogo[userId] or 0
	if (ahora - ultimo) < segundos then return false end
	_cooldownsDialogo[userId] = ahora
	return true
end

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function contarConexiones(nodo)
	local count = 0
	for key, _ in pairs(_cables) do
		local a, b = GrafoHelpers.parsearClave(key)
		if a == nodo or b == nodo then count = count + 1 end
	end
	return count
end

local function esAlcanzableConEnergia(inicio, meta, visitados)
	if inicio == meta then return true end
	visitados = visitados or {}
	visitados[inicio] = true

	for _, vecino in ipairs(ValidadorConexiones.obtenerConexiones(inicio)) do
		if not visitados[vecino] and esAlcanzableConEnergia(vecino, meta, visitados) then
			return true
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
				-- print(string.format(
				-- 	"[ServicioMisiones] Estrellas limitadas a 2 — Diálogos correctos: %d/%d",
				-- 	correctas, requeridas))
			end
		end
	end

	return estrellas
end

-- ── Validadores ───────────────────────────────────────────────────────────────
local Validadores = {}

Validadores.ARISTA_CREADA = function(params)
	local key = GrafoHelpers.clavePar(params.NodoA, params.NodoB)
	return _cables[key] == true
		and not ValidadorConexiones.esCableDefectuoso(params.NodoA, params.NodoB)
end

Validadores.ARISTA_DIRIGIDA = function(params)
	local key = GrafoHelpers.clavePar(params.NodoOrigen, params.NodoDestino)
	return _cables[key] == true
		and not ValidadorConexiones.esCableDefectuoso(params.NodoOrigen, params.NodoDestino)
end

Validadores.GRADO_NODO = function(params)
	return contarConexiones(params.Nodo) >= (params.GradoRequerido or 1)
end

-- Comprueba que el camino más barato construido entre Inicio y Destino no
-- supere el máximo. Usa los pesos temporales configurados por el jugador.
Validadores.RUTA_COSTO = function(params)
	local inicio = params.Inicio
	local destino = params.Destino
	local pesoMaximo = params.PesoMaximo or params.PesoObjetivo
	if type(inicio) ~= "string" or type(destino) ~= "string" then return false end
	if type(pesoMaximo) ~= "number" or pesoMaximo < 0 then return false end

	local adyacencias = {}
	local aristasAgregadas = {}
	local pendientes = { inicio }
	local descubiertos = { [inicio] = true }
	local indicePendiente = 1

	-- ValidadorConexiones contiene la topología física real. Recorrer desde el
	-- inicio evita depender de que la copia interna de misiones esté sincronizada.
	while indicePendiente <= #pendientes do
		local nodoA = pendientes[indicePendiente]
		indicePendiente = indicePendiente + 1

		for _, nodoB in ipairs(ValidadorConexiones.obtenerConexiones(nodoA)) do
			local clave = GrafoHelpers.clavePar(nodoA, nodoB)
			if not aristasAgregadas[clave] then
				aristasAgregadas[clave] = true
				local peso = _pesosTemporales[clave]
					or GrafoHelpers.obtenerPeso(_nivelID, nodoA, nodoB, 0)
				if peso > 0 then
					adyacencias[nodoA] = adyacencias[nodoA] or {}
					adyacencias[nodoB] = adyacencias[nodoB] or {}
					table.insert(adyacencias[nodoA], { nodo = nodoB, peso = peso })
					table.insert(adyacencias[nodoB], { nodo = nodoA, peso = peso })
				end
			end
			if not descubiertos[nodoB] then
				descubiertos[nodoB] = true
				table.insert(pendientes, nodoB)
			end
		end
	end

	local distancias = { [inicio] = 0 }
	local visitados = {}
	while true do
		local actual = nil
		local menor = math.huge
		for nodo, distancia in pairs(distancias) do
			if not visitados[nodo] and distancia < menor then
				actual = nodo
				menor = distancia
			end
		end
		if not actual or menor > pesoMaximo then break end
		if actual == destino then
			print(string.format(
				"[ServicioMisiones] RUTA_COSTO completada: %s -> %s, costo=%s, maximo=%s",
				inicio, destino, tostring(menor), tostring(pesoMaximo)
			))
			return true
		end

		visitados[actual] = true
		for _, vecino in ipairs(adyacencias[actual] or {}) do
			local alternativa = menor + vecino.peso
			if alternativa <= pesoMaximo
				and alternativa < (distancias[vecino.nodo] or math.huge) then
				distancias[vecino.nodo] = alternativa
			end
		end
	end
	return false
end

Validadores.ARBOL_EXPANSION_MINIMA = function(params)
	local nodos = params.Nodos or {}
	local pesoMaximo = params.PesoMaximo
	if #nodos < 2 or type(pesoMaximo) ~= "number" then return false end

	local enArbol = {}
	for _, nodo in ipairs(nodos) do enArbol[nodo] = true end

	local adyacencias = {}
	local aristasVistas = {}
	local cantidadAristas = 0
	local pesoTotal = 0

	for _, nodoA in ipairs(nodos) do
		for _, nodoB in ipairs(ValidadorConexiones.obtenerConexiones(nodoA)) do
			if enArbol[nodoB] then
				local clave = GrafoHelpers.clavePar(nodoA, nodoB)
				if not aristasVistas[clave] then
					aristasVistas[clave] = true
					cantidadAristas = cantidadAristas + 1
					pesoTotal = pesoTotal
						+ (_pesosTemporales[clave] or GrafoHelpers.obtenerPeso(_nivelID, nodoA, nodoB, 0))
					adyacencias[nodoA] = adyacencias[nodoA] or {}
					adyacencias[nodoB] = adyacencias[nodoB] or {}
					table.insert(adyacencias[nodoA], nodoB)
					table.insert(adyacencias[nodoB], nodoA)
				end
			end
		end
	end

	-- Un árbol de n nodos debe tener exactamente n-1 aristas.
	if cantidadAristas ~= #nodos - 1 or pesoTotal > pesoMaximo then return false end

	local visitados = {}
	local cola = { nodos[1] }
	visitados[nodos[1]] = true
	local indice = 1
	while indice <= #cola do
		local actual = cola[indice]
		indice = indice + 1
		for _, vecino in ipairs(adyacencias[actual] or {}) do
			if not visitados[vecino] then
				visitados[vecino] = true
				table.insert(cola, vecino)
			end
		end
	end

	for _, nodo in ipairs(nodos) do
		if not visitados[nodo] then return false end
	end

	print(string.format(
		"[ServicioMisiones] MST válido: %d nodos, %d aristas, peso=%s, máximo=%s",
		#nodos, cantidadAristas, tostring(pesoTotal), tostring(pesoMaximo)
	))
	return true
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
				if not esAlcanzableConEnergia(nodos[i], nodos[j], {}) then
					return false
				end
			end
		end
	end
	return true
end

Validadores.EMERGENCIA = function(params)
	-- Comprobar energía real desde un generador. obtenerConexiones omite
	-- automáticamente los cables que todavía están defectuosos.
	local nodosEnergizar = params.NodosEnergizar or {}
	if #nodosEnergizar > 0 then
		local generadores = (_config and _config.Generadores) or {}
		for _, destino in ipairs(nodosEnergizar) do
			local energizado = false
			for _, generador in ipairs(generadores) do
				if esAlcanzableConEnergia(generador, destino, {}) then
					energizado = true
					break
				end
			end
			if not energizado then return false end
		end
		return true
	end

	-- Primero verificar que el grafo esté conexo (misma lógica que GRAFO_CONEXO)
	local nodos = params.Nodos or {}
	if #nodos < 2 then return true end
	for i = 1, #nodos do
		for j = 1, #nodos do
			if i ~= j then
				if not esAlcanzableConEnergia(nodos[i], nodos[j], {}) then
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

Validadores.DIALOGO_COMPLETADO = function(params)
	if not params.DialogoID or not _dialogosTerminados[params.DialogoID] then
		return false
	end
	for _, misionID in ipairs(params.RequiereMisiones or {}) do
		if not _completadas[misionID] then return false end
	end
	return true
end

Validadores.SOBRECARGA_EXPERIMENTADA = function(params)
	return _nodosSobrecargados[params.Nodo] == true
end

Validadores.NODO_REPARADO = function(params)
	return _nodosReparados[params.Nodo] == true
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

		-- TG 07: Emergencia además requiere que todos los nodos dañados de la zona estén reparados
		if ok and m.Tipo == "EMERGENCIA" then
			local zonaCfg = _config and _config.Zonas and _config.Zonas[m.Zona]
			if zonaCfg and zonaCfg.NodosDaniados then
				for _, nodo in ipairs(zonaCfg.NodosDaniados) do
					if not _nodosReparados[nodo] then
						ok = false
						break
					end
				end
			end
		end

		if ok and not _completadas[m.ID] then
			_completadas[m.ID] = true
			-- Solo marcar como permanente si NO es una misión de cableado ni de conectividad
			-- ARISTA_CREADA, ARISTA_DIRIGIDA y GRAFO_CONEXO pueden revocarse al desconectar
			-- EMERGENCIA es permanente: una vez superada o fallida, no cambia
			if m.Tipo ~= "ARISTA_CREADA"
				and m.Tipo ~= "ARISTA_DIRIGIDA"
				and m.Tipo ~= "GRAFO_CONEXO"
				and m.Tipo ~= "RUTA_COSTO"
				and m.Tipo ~= "ARBOL_EXPANSION_MINIMA" then
				_permanentes[m.ID] = true
			end
			_puntosAcum = _puntosAcum + (m.Puntos or 0)
			if _servicioPuntaje then _servicioPuntaje:fijarPuntajeMision(_jugador, _puntosAcum, calcularEstrellasHelper(_puntosAcum)) end
			cambiado = true
			-- print(string.format("[ServicioMisiones] Misión %d completada — +%d pts (total: %d)",
				-- m.ID, m.Puntos or 0, _puntosAcum))

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

			-- print(string.format(
			-- 	"[ServicioMisiones] Snapshot → puntaje=%d / aciertosTotal=%d / conexiones=%d / fallos=%d / tiempo=%d",
			-- 	snap.puntajeBase, snap.aciertosTotal or 0, snap.conexiones, snap.fallos, snap.tiempo
			-- 	))

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
				resultadoFinal = _resultadoFinal,
				mensajeFinal = _mensajeFinal,
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
-- TIMER DE EMERGENCIA (delegado a TimerEmergencia.lua)
-- ════════════════════════════════════════════════════════════════════════════

local function _onTimerExpirado(misionID)
	if not _activo then return end

	-- Penalización: -500 puntos por fallar la emergencia
	_puntosAcum = math.max(0, _puntosAcum - 500)
	if _servicioPuntaje then
		_servicioPuntaje:fijarPuntajeMision(_jugador, _puntosAcum, calcularEstrellasHelper(_puntosAcum))
	end
	-- print(string.format("[ServicioMisiones] Penalización -500 pts | Puntaje actual: %d", _puntosAcum))

	if verificarYNotificar then
		verificarYNotificar()
	end
end

local function _crearTimerEmergencia()
	_timerEmergencia = TimerEmergencia.nuevo({
		eventoTimer = _eventoTimerEmergencia,
		jugador     = _jugador,
		onExpirado  = _onTimerExpirado,
	})
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
	_nodosReparados = {}
	_nodosSobrecargados = {}
	_dialogosTerminados = {}
	_resultadoFinal = nil
	_mensajeFinal = nil
	_pesosTemporales = {}
	if _timerEmergencia then _timerEmergencia:detener() end
	_timerEmergencia = nil

	if eventos then
		_eventoActualizarMisiones = eventos:FindFirstChild("ActualizarMisiones")
		_eventoNivelCompletado    = eventos:FindFirstChild("NivelCompletado")
		_eventoTimerEmergencia    = eventos:FindFirstChild("TimerEmergencia")

		local actualizarPesos = eventos:FindFirstChild("ActualizarPesosTemporales")
			or eventos:WaitForChild("ActualizarPesosTemporales", 2)
		if _actualizarPesosConn then
			_actualizarPesosConn:Disconnect()
			_actualizarPesosConn = nil
		end
		if actualizarPesos then
			_actualizarPesosConn = actualizarPesos.OnServerEvent:Connect(function(player, cambios)
				if not _activo or player ~= _jugador or type(cambios) ~= "table" then return end

				local aceptados = 0
				for _, cambio in ipairs(cambios) do
					local nodoA = cambio.nodoA
					local nodoB = cambio.nodoB
					local peso = cambio.peso
					if type(nodoA) == "string"
						and type(nodoB) == "string"
						and type(peso) == "number"
						and peso >= 1 and peso <= 50 and peso % 1 == 0
						and GrafoHelpers.obtenerPeso(_nivelID, nodoA, nodoB, 0) > 0 then
						local clave = GrafoHelpers.clavePar(nodoA, nodoB)
						_pesosTemporales[clave] = peso

						-- _config es la misma tabla LevelsConfig usada por los
						-- servicios del servidor durante esta partida. Actualizarla
						-- hace que ConectarCables cobre y reembolse el peso nuevo.
						if _config then
							_config.PesosAristas = _config.PesosAristas or {}
							_config.PesosAristas[clave] = peso
						end
						aceptados = aceptados + 1
					end
				end
				print(string.format(
					"[ServicioMisiones] Pesos temporales recibidos de %s: %d aceptados",
					player.Name, aceptados
				))
				verificarYNotificar()
			end)
		end

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
			print("[ServicioMisiones] Creado ReproducirEfecto dinámicamente en activar()")
		end

		-- Escuchar pausa/reanudación desde diálogos (conexión sincrónica para evitar race conditions)
		local dialogoIniciado = eventos:FindFirstChild("DialogoIniciado") or eventos:WaitForChild("DialogoIniciado", 2)
		if dialogoIniciado and not _dialogoIniciadoConn then
			_dialogoIniciadoConn = dialogoIniciado.OnServerEvent:Connect(function(player)
				if not chequearCooldownDialogo(player.UserId, 0.3) then return end
				-- print(string.format("[ServicioMisiones] DialogoIniciado recibido de %s | _jugador=%s", tostring(player), tostring(_jugador)))
				if player == _jugador and _timerEmergencia then _timerEmergencia:pausar() end
			end)
			print("[ServicioMisiones] Conectado DialogoIniciado")
		elseif not dialogoIniciado then
			warn("[ServicioMisiones] DialogoIniciado no encontrado en eventos")
		else
			print("[ServicioMisiones] DialogoIniciado ya conectado, saltando")
		end
		local dialogoTerminado = eventos:FindFirstChild("DialogoTerminado") or eventos:WaitForChild("DialogoTerminado", 2)
		if dialogoTerminado and not _dialogoTerminadoConn then
			_dialogoTerminadoConn = dialogoTerminado.OnServerEvent:Connect(function(player, dialogoID, resultado)
				if not chequearCooldownDialogo(player.UserId, 0.3) then return end
				-- print(string.format("[ServicioMisiones] DialogoTerminado recibido de %s | _jugador=%s", tostring(player), tostring(_jugador)))
				if player ~= _jugador then return end
				if type(dialogoID) == "string" and dialogoID ~= "" then
					local primeraFinalizacion = _dialogosTerminados[dialogoID] == nil
					_dialogosTerminados[dialogoID] = resultado or true

					for _, mision in ipairs(_misiones) do
						local params = mision.Parametros or {}
						if mision.Tipo == "DIALOGO_COMPLETADO" and params.DialogoID == dialogoID then
							if resultado == "exito" then
								_resultadoFinal = "exito"
								_mensajeFinal = params.MensajeExito
							else
								_resultadoFinal = "fracaso"
								_mensajeFinal = params.MensajeFallo
								if primeraFinalizacion then
									local penalizacion = params.PenalizacionFallo or 0
									_puntosAcum = _puntosAcum - penalizacion
									if _servicioPuntaje then
										_servicioPuntaje:fijarPuntajeMision(
											_jugador,
											_puntosAcum,
											calcularEstrellasHelper(_puntosAcum)
										)
									end
								end
							end
							break
						end
					end
					verificarYNotificar()
				end
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
			print("[ServicioMisiones] Conectado DialogoTerminado")
		elseif not dialogoTerminado then
			warn("[ServicioMisiones] DialogoTerminado no encontrado en eventos")
		else
			print("[ServicioMisiones] DialogoTerminado ya conectado, saltando")
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
	_nodosReparados = {}
	_nodosSobrecargados = {}
	_dialogosTerminados = {}
	_resultadoFinal = nil
	_mensajeFinal = nil
	_pesosTemporales = {}

	-- Limpiar conexiones de diálogo y timer para evitar fugas entre niveles
	if _actualizarPesosConn then _actualizarPesosConn:Disconnect(); _actualizarPesosConn = nil end
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
	_cables[GrafoHelpers.clavePar(nomA, nomB)] = true
	verificarYNotificar()
end

function ServicioMisiones.alEliminarCable(nomA, nomB)
	if not _activo then return end
	_cables[GrafoHelpers.clavePar(nomA, nomB)] = nil
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

---Devuelve true si hay una misión de emergencia PENDIENTE (no completada) en la zona dada.
-- @param zonaID string
-- @return boolean
function ServicioMisiones.hayEmergenciaPendienteEnZona(zonaID)
	if not _activo or not zonaID then return false end
	for _, m in ipairs(_misiones) do
		if m.Zona == zonaID and m.Tipo == "EMERGENCIA" and not _completadas[m.ID] then
			return true
		end
	end
	return false
end

---Devuelve true si hay alguna misión de emergencia pendiente en cualquier zona.
---Registra que un nodo dañado fue reparado manualmente.
-- @param nombreNodo string
function ServicioMisiones.alRepararNodo(nombreNodo)
	if not nombreNodo then return end
	_nodosReparados[nombreNodo] = true
	-- Re-verificar misiones inmediatamente (puede desbloquear emergencia)
	verificarYNotificar()
end

function ServicioMisiones.alSobrecargarNodo(nombreNodo)
	if not nombreNodo then return end
	_nodosSobrecargados[nombreNodo] = true
	verificarYNotificar()
end

function ServicioMisiones.hayEmergenciaPendiente()
	if not _activo then return false end
	for _, m in ipairs(_misiones) do
		if m.Tipo == "EMERGENCIA" and not _completadas[m.ID] then
			return true
		end
	end
	return false
end

return ServicioMisiones
