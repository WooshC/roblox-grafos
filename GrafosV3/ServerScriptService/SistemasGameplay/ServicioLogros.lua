-- GrafosV3 - ServicioLogros.lua
-- Servidor: detecta, almacena y notifica logros desbloqueados.
-- Ubicación: ServerScriptService/SistemasGameplay/ServicioLogros.lua

local ServicioLogros = {}

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local LogrosConfig = require(RS:WaitForChild("Config"):WaitForChild("LogrosConfig"))
local LevelsConfig = require(RS:WaitForChild("Config"):WaitForChild("LevelsConfig"))

-- DataStore para logros (mismo scope que progreso para coherencia)
local storeLogros = DataStoreService:GetDataStore("GrafosV3_Logros_v1")

-- Cache en memoria: [userId] = { [logroID] = true/false, ... }
local cacheLogros = {}

-- Contadores por sesión para condiciones acumulativas
-- [userId] = { cablesConectados = N, fallos = N, dialogosCorrectos = N, zonasVisitadas = { [zona]=true }, ... }
local sesionStats = {}

-- Referencia al EventRegistry (se llena en init)
local Remotos = nil

-- ═══════════════════════════════════════════════════════════════════════════════
-- CARGAR / GUARDAR
-- ═══════════════════════════════════════════════════════════════════════════════

function ServicioLogros.cargar(jugador)
	local userId = jugador.UserId
	if cacheLogros[userId] then
		return cacheLogros[userId]
	end

	local key = "player_" .. userId
	local ok, datos = pcall(function()
		return storeLogros:GetAsync(key)
	end)

	local logrosJugador = {}
	if ok and datos then
		for id, estado in pairs(datos) do
			logrosJugador[id] = estado
		end
	end

	cacheLogros[userId] = logrosJugador
	sesionStats[userId] = {
		cablesConectados = 0,
		fallos = 0,
		dialogosCorrectos = 0,
		zonasVisitadas = {},
		totalZonasNivel = 0,
		tiempoInicioNivel = 0,
		nivelActual = nil,
	}

	print("[ServicioLogros] Datos cargados para", jugador.Name, "— desbloqueados:", ServicioLogros.contarDesbloqueados(jugador))
	return logrosJugador
end

function ServicioLogros.guardar(jugador)
	local datos = cacheLogros[jugador.UserId]
	if not datos then return end

	local key = "player_" .. jugador.UserId
	local ok, err = pcall(function()
		storeLogros:SetAsync(key, datos)
	end)

	if ok then
		print("[ServicioLogros] Guardado para", jugador.Name)
	else
		warn("[ServicioLogros] Error al guardar:", err)
	end
end

function ServicioLogros.alJugadorSalir(jugador)
	ServicioLogros.guardar(jugador)
	cacheLogros[jugador.UserId] = nil
	sesionStats[jugador.UserId] = nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- VERIFICACIÓN Y DESBLOQUEO
-- ═══════════════════════════════════════════════════════════════════════════════

function ServicioLogros.estaDesbloqueado(jugador, logroID)
	local datos = cacheLogros[jugador.UserId]
	if not datos then return false end
	return datos[logroID] == true
end

function ServicioLogros.desbloquear(jugador, logroID)
	if ServicioLogros.estaDesbloqueado(jugador, logroID) then
		return false -- ya estaba desbloqueado
	end

	local logro = LogrosConfig.obtenerLogro(logroID)
	if not logro then
		warn("[ServicioLogros] Logro no existe:", logroID)
		return false
	end

	local datos = cacheLogros[jugador.UserId]
	if not datos then
		datos = {}
		cacheLogros[jugador.UserId] = datos
	end

	datos[logroID] = true

	print(string.format("[ServicioLogros] 🏆 LOGRO DESBLOQUEADO — %s | Jugador: %s", logro.nombre, jugador.Name))

	-- Notificar al cliente
	if Remotos then
		local evento = Remotos:FindFirstChild("LogroDesbloqueado")
		if evento then
			evento:FireClient(jugador, {
				id = logroID,
				nombre = logro.nombre,
				descripcion = logro.descripcion,
				icono = logro.icono,
				categoria = logro.categoria,
			})
		end
	end

	-- Guardar async
	task.spawn(function()
		ServicioLogros.guardar(jugador)
	end)

	-- Verificar metalogros inmediatamente
	ServicioLogros.verificarMetalogros(jugador)

	return true
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- VERIFICACIÓN DE CONDICIONES
-- ═══════════════════════════════════════════════════════════════════════════════

function ServicioLogros.verificarCondicion(jugador, condicion, contexto)
	if not condicion then return false end

	local stats = sesionStats[jugador.UserId] or {}
	local tipo = condicion.tipo

	if tipo == "nivelCompletado" then
		local nid = contexto and contexto.nivelID
		return nid == condicion.nivelID

	elseif tipo == "nivelesCompletados" then
		-- Requiere contar niveles completados (estrellas > 0) desde ServicioProgreso
		local progreso = _G.ObtenerProgresoParaLogros and _G.ObtenerProgresoParaLogros(jugador)
		if progreso then
			local completados = 0
			for _, nivelDatos in pairs(progreso) do
				if (nivelDatos.estrellas or 0) > 0 then
					completados = completados + 1
				end
			end
			return completados >= condicion.count
		end
		return false

	elseif tipo == "estrellasNivel" then
		local progreso = _G.ObtenerProgresoParaLogros and _G.ObtenerProgresoParaLogros(jugador)
		if not progreso then return false end

		local target = condicion.nivelID
		local reqEstrellas = condicion.estrellas

		if target == "cualquiera" then
			for _, nivelDatos in pairs(progreso) do
				if (nivelDatos.estrellas or 0) >= reqEstrellas then
					return true
				end
			end
			return false
		elseif target == "todos" then
			for _, nivelDatos in pairs(progreso) do
				if (nivelDatos.estrellas or 0) < reqEstrellas then
					return false
				end
			end
			return true
		else
			local nd = progreso[tostring(target)]
			return nd and (nd.estrellas or 0) >= reqEstrellas
		end

	elseif tipo == "cablesConectados" then
		return (stats.cablesConectados or 0) >= condicion.count

	elseif tipo == "sinFallos" then
		return (stats.fallos or 0) == 0 and (contexto and contexto.nivelCompletado)

	elseif tipo == "dialogosPerfectos" then
		local totalPreguntas = contexto and contexto.totalPreguntasDialogo or 0
		local correctas = stats.dialogosCorrectos or 0
		return totalPreguntas > 0 and correctas >= totalPreguntas

	elseif tipo == "todasZonasVisitadas" then
		local totalZonas = stats.totalZonasNivel or 0
		local visitadas = 0
		for _ in pairs(stats.zonasVisitadas or {}) do
			visitadas = visitadas + 1
		end
		return totalZonas > 0 and visitadas >= totalZonas and (contexto and contexto.nivelCompletado)

	elseif tipo == "tiempoRecord" then
		local tiempoInicio = stats.tiempoInicioNivel or 0
		if tiempoInicio > 0 and (contexto and contexto.tiempoSegundos) then
			return contexto.tiempoSegundos <= condicion.segundosMax
		end
		return false

	elseif tipo == "logrosDesbloqueados" then
		return ServicioLogros.contarDesbloqueados(jugador) >= condicion.count

	end

	return false
end

function ServicioLogros.verificarLogro(jugador, logroID, contexto)
	if ServicioLogros.estaDesbloqueado(jugador, logroID) then
		return false
	end

	local logro = LogrosConfig.obtenerLogro(logroID)
	if not logro then return false end

	if ServicioLogros.verificarCondicion(jugador, logro.condicion, contexto) then
		return ServicioLogros.desbloquear(jugador, logroID)
	end
	return false
end

function ServicioLogros.verificarTodos(jugador, contexto)
	local desbloqueados = 0
	for _, logro in ipairs(LogrosConfig.LOGROS) do
		if ServicioLogros.verificarLogro(jugador, logro.id, contexto) then
			desbloqueados = desbloqueados + 1
		end
	end
	return desbloqueados
end

function ServicioLogros.verificarMetalogros(jugador)
	-- Verificar solo logros que dependen de "logrosDesbloqueados"
	for _, logro in ipairs(LogrosConfig.LOGROS) do
		if logro.condicion and logro.condicion.tipo == "logrosDesbloqueados" then
			ServicioLogros.verificarLogro(jugador, logro.id, {})
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONTADORES Y ESTADÍSTICAS DE SESIÓN
-- ═══════════════════════════════════════════════════════════════════════════════

function ServicioLogros.iniciarNivel(jugador, nivelID)
	local stats = sesionStats[jugador.UserId]
	if not stats then
		stats = {}
		sesionStats[jugador.UserId] = stats
	end

	stats.cablesConectados = 0
	stats.fallos = 0
	stats.dialogosCorrectos = 0
	stats.zonasVisitadas = {}
	stats.tiempoInicioNivel = tick()
	stats.nivelActual = nivelID

	-- Contar zonas del nivel
	local config = LevelsConfig[nivelID]
	if config and config.Zonas then
		local count = 0
		for _ in pairs(config.Zonas) do
			count = count + 1
		end
		stats.totalZonasNivel = count
	else
		stats.totalZonasNivel = 0
	end

	print("[ServicioLogros] Sesión iniciada para nivel", nivelID, "— zonas:", stats.totalZonasNivel)
end

function ServicioLogros.registrarCableConectado(jugador)
	local stats = sesionStats[jugador.UserId]
	if stats then
		stats.cablesConectados = (stats.cablesConectados or 0) + 1
		-- Verificar conector_rapido inmediatamente
		ServicioLogros.verificarLogro(jugador, "conector_rapido", {})
	end
end

function ServicioLogros.registrarFallo(jugador)
	local stats = sesionStats[jugador.UserId]
	if stats then
		stats.fallos = (stats.fallos or 0) + 1
	end
end

function ServicioLogros.registrarDialogoCorrecto(jugador)
	local stats = sesionStats[jugador.UserId]
	if stats then
		stats.dialogosCorrectos = (stats.dialogosCorrectos or 0) + 1
	end
end

function ServicioLogros.registrarZonaVisitada(jugador, nombreZona)
	local stats = sesionStats[jugador.UserId]
	if stats and nombreZona then
		if not stats.zonasVisitadas then
			stats.zonasVisitadas = {}
		end
		stats.zonasVisitadas[nombreZona] = true
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- EVENTO: NIVEL COMPLETADO — verificación masiva
-- ═══════════════════════════════════════════════════════════════════════════════

function ServicioLogros.alNivelCompletado(jugador, nivelID, snapshotVictoria)
	local stats = sesionStats[jugador.UserId] or {}
	local tiempoSegundos = 0
	if stats.tiempoInicioNivel and stats.tiempoInicioNivel > 0 then
		tiempoSegundos = math.floor(tick() - stats.tiempoInicioNivel)
	end

	local contexto = {
		nivelID = nivelID,
		nivelCompletado = true,
		tiempoSegundos = tiempoSegundos,
		totalPreguntasDialogo = snapshotVictoria and snapshotVictoria.totalPreguntasDialogo or 0,
	}

	print(string.format(
		"[ServicioLogros] Nivel completado — Jugador: %s | Nivel: %d | Tiempo: %ds | Cables: %d | Fallos: %d | DialogosCorrectos: %d",
		jugador.Name, nivelID, tiempoSegundos, stats.cablesConectados or 0, stats.fallos or 0, stats.dialogosCorrectos or 0
	))

	-- Verificar logros relevantes
	ServicioLogros.verificarLogro(jugador, "primeros_pasos", contexto)
	ServicioLogros.verificarLogro(jugador, "electricista_novato", contexto)
	ServicioLogros.verificarLogro(jugador, "electricista_experto", contexto)
	ServicioLogros.verificarLogro(jugador, "estrella_perfecta", contexto)
	ServicioLogros.verificarLogro(jugador, "maestro_estrellas", contexto)
	ServicioLogros.verificarLogro(jugador, "conector_rapido", contexto)
	ServicioLogros.verificarLogro(jugador, "manos_estables", contexto)
	ServicioLogros.verificarLogro(jugador, "sabio_grafos", contexto)
	ServicioLogros.verificarLogro(jugador, "explorador_barrio", contexto)
	ServicioLogros.verificarLogro(jugador, "velocista_electrico", contexto)
	ServicioLogros.verificarLogro(jugador, "conexion_secreta", contexto)

	-- Metalogros
	ServicioLogros.verificarMetalogros(jugador)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- API PÚBLICA
-- ═══════════════════════════════════════════════════════════════════════════════

function ServicioLogros.reset(jugador)
	local userId = jugador.UserId
	
	-- Limpiar cache en memoria
	cacheLogros[userId] = {}
	sesionStats[userId] = {
		cablesConectados = 0,
		fallos = 0,
		dialogosCorrectos = 0,
		zonasVisitadas = {},
		totalZonasNivel = 0,
		tiempoInicioNivel = 0,
		nivelActual = nil,
	}
	
	-- Limpiar DataStore persistente
	local key = "player_" .. userId
	local ok, err = pcall(function()
		storeLogros:RemoveAsync(key)
	end)
	
	if ok then
		print(string.format("[ServicioLogros] ✅ Logros RESETEADOS para %s (%d)", jugador.Name, userId))
	else
		warn("[ServicioLogros] Error al resetear logros:", err)
	end
end

function ServicioLogros.contarDesbloqueados(jugador)
	local datos = cacheLogros[jugador.UserId]
	if not datos then return 0 end
	local count = 0
	for _, v in pairs(datos) do
		if v == true then
			count = count + 1
		end
	end
	return count
end

function ServicioLogros.obtenerEstadoParaCliente(jugador)
	local datos = cacheLogros[jugador.UserId] or {}
	local resultado = {}
	for _, logro in ipairs(LogrosConfig.LOGROS) do
		local desbloqueado = datos[logro.id] == true
		resultado[logro.id] = {
			id = logro.id,
			nombre = logro.nombre,
			descripcion = logro.descripcion,
			icono = logro.icono,
			categoria = logro.categoria,
			secreto = logro.secreto,
			desbloqueado = desbloqueado,
		}
	end
	return resultado
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════════════════════

function ServicioLogros.init(remotosFolder)
	Remotos = remotosFolder

	-- RemoteFunction: ObtenerLogros (Cliente solicita estado actual)
	local obtenerLogros = Remotos:FindFirstChild("ObtenerLogros")
	if obtenerLogros then
		obtenerLogros.OnServerInvoke = function(jugador)
			ServicioLogros.cargar(jugador)
			return ServicioLogros.obtenerEstadoParaCliente(jugador)
		end
	end

	print("[ServicioLogros] Inicializado")
end

return ServicioLogros
