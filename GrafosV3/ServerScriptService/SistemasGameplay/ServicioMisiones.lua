-- ServerScriptService/SistemasGameplay/ServicioMisiones.lua
-- Sistema de validación de misiones para GrafosV3
-- Adaptado de GrafosV2/MissionService a la arquitectura V3

local ServicioMisiones = {}

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
local _eventoNivelCompletado = nil

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function clavePar(a, b)
	if a > b then a, b = b, a end
	return a .. "|" .. b
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
			_permanentes[m.ID] = true
			_puntosAcum = _puntosAcum + (m.Puntos or 0)
			if _servicioPuntaje then _servicioPuntaje:fijarPuntajeMision(_jugador, _puntosAcum) end
			cambiado = true
			print(string.format("[ServicioMisiones] ✅ Misión %d completada — +%d pts (total: %d)",
				m.ID, m.Puntos or 0, _puntosAcum))
		elseif not ok and _completadas[m.ID] and not _permanentes[m.ID] then
			_completadas[m.ID] = nil
			_puntosAcum = math.max(0, _puntosAcum - (m.Puntos or 0))
			if _servicioPuntaje then _servicioPuntaje:fijarPuntajeMision(_jugador, _puntosAcum) end
			cambiado = true
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
		print("[ServicioMisiones] 🏆 ¡Todas las misiones completadas! — puntosAcum:", _puntosAcum)

		if _eventoNivelCompletado and _servicioPuntaje and _jugador then
			local snap = _servicioPuntaje:finalizar(_jugador)

			print(string.format(
				"[ServicioMisiones] Snapshot → puntaje=%d / aciertosTotal=%d / conexiones=%d / fallos=%d / tiempo=%d",
				snap.puntajeBase, snap.aciertosTotal or 0, snap.conexiones, snap.fallos, snap.tiempo
			))

			-- Guardar en DataStore antes de mostrar victoria
			if _servicioDatos and _nivelID ~= nil then
				local puntuacion = _config and _config.Puntuacion or {}
				local estrellas = 0
				if snap.puntajeBase >= (puntuacion.TresEstrellas or 999999) then estrellas = 3
				elseif snap.puntajeBase >= (puntuacion.DosEstrellas or 999999) then estrellas = 2
				elseif snap.puntajeBase > 0 then estrellas = 1
				end

				local aciertosGuardar = snap.aciertosTotal or snap.conexiones

				_servicioDatos:guardarResultado(_jugador, _nivelID, {
					highScore = snap.puntajeBase,
					estrellas = estrellas,
					aciertos = aciertosGuardar,
					fallos = snap.fallos,
					tiempoMejor = snap.tiempo,
				})
				print("[ServicioMisiones] 💾 Guardado — estrellas:", estrellas, "/ aciertos:", aciertosGuardar)
			end

			-- Enviar snap al cliente con campo "aciertos" explícito
			local snapCliente = {
				nivelID = snap.nivelID,
				conexiones = snap.conexiones,
				aciertos = snap.aciertosTotal or snap.conexiones,
				fallos = snap.fallos,
				tiempo = snap.tiempo,
				puntajeBase = snap.puntajeBase,
			}
			_eventoNivelCompletado:FireClient(_jugador, snapCliente)
		end

		_activo = false
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- API PÚBLICA
-- ════════════════════════════════════════════════════════════════════════════

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

	if eventos then
		_eventoActualizarMisiones = eventos:FindFirstChild("ActualizarMisiones")
		_eventoNivelCompletado = eventos:FindFirstChild("NivelCompletado")
	end

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
	_eventoNivelCompletado = nil
	_servicioDatos = nil
	_config = nil
	print("[ServicioMisiones] desactivar")
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
	notificar(nil)
	print("[ServicioMisiones] Zona entrada:", nombre)
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
