-- MisionManager.lua
-- ⚠️ DEPRECATED ON SERVER: Replaced by MissionService (ServerScriptService/Services/MissionService.lua)
-- This module is kept for Client-side compatibility only. Do not use for server verification.
-- Sistema de Misiones Flexible y Granular (Versión 2.2 - FIX inicialización)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")  -- ⭐ AGREGADO

local MisionManager = {}

-- Estado de misiones por jugador
local _estadoMisiones = {}

-- Evento para actualizar UI
local _eventoActualizar = nil

-- ============================================
-- VALIDADORES POR TIPO DE MISIÓN
-- ============================================

local Validadores = {
	NODOS_MINIMOS = function(params, estado)
		local cantidad = params.Cantidad or 0
		return estado.numNodosConectados >= cantidad
	end,

	NODO_ENERGIZADO = function(params, estado)
		local nodo = params.Nodo
		if not nodo then
			warn("⚠️ NODO_ENERGIZADO requiere parámetro 'Nodo'")
			return false
		end
		return estado.nodosVisitados[nodo] == true
	end,

	TODOS_LOS_NODOS = function(params, estado)
		local cantidad = params.Cantidad or 0
		return estado.numNodosConectados >= cantidad and estado.circuitoCerrado
	end,

	ZONA_ACTIVADA = function(params, estado)
		local zona = params.Zona
		if not zona then
			warn("⚠️ ZONA_ACTIVADA requiere parámetro 'Zona'")
			return false
		end
		return estado.zonasActivas and estado.zonasActivas[zona] == true
	end,

	PRESUPUESTO_RESTANTE = function(params, estado)
		local cantidad = params.Cantidad or 0
		return estado.dineroRestante >= cantidad
	end,

	CONEXIONES_MINIMAS = function(params, estado)
		local cantidad = params.Cantidad or 0
		return estado.numConexiones >= cantidad
	end,

	NODOS_LISTA = function(params, estado)
		local nodos = params.Nodos or {}
		for _, nodo in ipairs(nodos) do
			if not estado.nodosVisitados[nodo] then
				return false
			end
		end
		return #nodos > 0
	end,

	CUSTOM = function(params, estado)
		if params.Validador and type(params.Validador) == "function" then
			local success, result = pcall(params.Validador, estado)
			if success then
				return result
			else
				warn("⚠️ Error en validador CUSTOM: " .. tostring(result))
				return false
			end
		end
		warn("⚠️ CUSTOM requiere parámetro 'Validador' (función)")
		return false
	end,

	CIRCUITO_CERRADO = function(params, estado)
		return estado.circuitoCerrado == true
	end,

	GASTO_MAXIMO = function(params, estado)
		local gastoMaximo = params.Cantidad or 0
		local dineroInicial = estado.dineroInicial or 0
		local gastoActual = dineroInicial - estado.dineroRestante
		return gastoActual <= gastoMaximo
	end
}

-- ============================================
-- INICIALIZACIÓN
-- ============================================

function MisionManager.init()
	local Remotes = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes")
	_eventoActualizar = Remotes:WaitForChild("ActualizarMision")

	-- ⭐ INICIALIZAR JUGADORES EXISTENTES
	for _, player in ipairs(Players:GetPlayers()) do
		MisionManager.inicializarJugador(player)
	end
end

-- ============================================
-- GESTIÓN DE ESTADO
-- ============================================

function MisionManager.inicializarJugador(player)
	if _estadoMisiones[player.UserId] then
		print("⚠️ MisionManager: Jugador " .. player.Name .. " ya inicializado")
		return  -- Ya existe
	end

	_estadoMisiones[player.UserId] = {
		mision1 = false,
		mision2 = false,
		mision3 = false,
		mision4 = false,
		mision5 = false,
		mision6 = false,
		mision7 = false,
		mision8 = false
	}

	print("✅ MisionManager: Estado inicializado para " .. player.Name)
end

function MisionManager.limpiarJugador(player)
	_estadoMisiones[player.UserId] = nil
	print("🧹 MisionManager: Estado limpiado para " .. player.Name)
end

function MisionManager.obtenerEstado(player, misionID)
	-- ⭐ AUTO-INICIALIZAR si no existe
	if not _estadoMisiones[player.UserId] then
		print("⚠️ Auto-inicializando jugador " .. player.Name .. " en obtenerEstado")
		MisionManager.inicializarJugador(player)
	end

	local estado = _estadoMisiones[player.UserId]
	if not estado then return false end

	return estado["mision" .. misionID] or false
end

-- ============================================
-- ACTUALIZACIÓN DE MISIONES
-- ============================================

function MisionManager.actualizarMision(player, misionID, completada)
	-- ⭐ AUTO-INICIALIZAR si no existe
	if not _estadoMisiones[player.UserId] then
		MisionManager.inicializarJugador(player)
	end

	local estado = _estadoMisiones[player.UserId]
	local key = "mision" .. misionID

	if estado[key] ~= completada then
		estado[key] = completada

		if _eventoActualizar then
			_eventoActualizar:FireClient(player, misionID, completada)
			print("✅ Misión " .. misionID .. " actualizada para " .. player.Name .. ": " .. tostring(completada))
		end
	end
end

function MisionManager.actualizarMisionGlobal(misionID, completada)
	if not _eventoActualizar then return end

	-- ⭐ AUTO-INICIALIZAR TODOS los jugadores conectados si no existen
	for _, player in ipairs(Players:GetPlayers()) do
		if not _estadoMisiones[player.UserId] then
			print("⚠️ Auto-inicializando jugador " .. player.Name .. " en actualizarMisionGlobal")
			MisionManager.inicializarJugador(player)
		end
	end

	-- Actualizar estado en todos los jugadores
	for userId, estado in pairs(_estadoMisiones) do
		local key = "mision" .. misionID
		if estado[key] ~= completada then
			estado[key] = completada
		end
	end

	-- Notificar a todos los clientes
	_eventoActualizar:FireAllClients(misionID, completada)
	print("📢 Misión " .. misionID .. " actualizada globalmente: " .. tostring(completada))
end

-- ============================================
-- VERIFICACIÓN DE MISIONES
-- ============================================

function MisionManager.verificarMision(misionConfig, estadoJuego)
	if type(misionConfig) ~= "table" then
		return false
	end

	local tipo = misionConfig.Tipo
	if not tipo then
		warn("⚠️ Misión sin tipo definido")
		return false
	end

	local validador = Validadores[tipo]
	if not validador then
		warn("⚠️ Tipo de misión desconocido: " .. tostring(tipo))
		return false
	end

	local params = misionConfig.Parametros or {}
	local success, resultado = pcall(validador, params, estadoJuego)

	if not success then
		warn("⚠️ Error al validar misión: " .. tostring(resultado))
		return false
	end

	return resultado == true
end

function MisionManager.verificarTodasLasMisiones(nivelConfig, estadoJuego)
	local resultados = {}

	if not nivelConfig or not nivelConfig.Misiones then
		return resultados
	end

	for _, misionConfig in ipairs(nivelConfig.Misiones) do
		if type(misionConfig) == "table" and misionConfig.ID then
			local id = misionConfig.ID
			local completada = MisionManager.verificarMision(misionConfig, estadoJuego)
			resultados[id] = completada
		end
	end

	return resultados
end

function MisionManager.construirEstadoJuego(visitados, numNodosConectados, config, player, zonasActivas)
	local estado = {
		nodosVisitados = visitados or {},
		numNodosConectados = numNodosConectados or 0,
		circuitoCerrado = false,
		dineroRestante = 0,
		dineroInicial = config and config.DineroInicial or 0,
		numConexiones = 0,
		zonasActivas = zonasActivas or {}
	}

	if config and config.NodoFin then
		estado.circuitoCerrado = visitados[config.NodoFin] == true
	end

	if player and player:FindFirstChild("leaderstats") then
		local moneyValue = player.leaderstats:FindFirstChild("Money")
		if moneyValue then
			estado.dineroRestante = moneyValue.Value
		end
	end

	return estado
end

-- ============================================
-- RESET
-- ============================================

function MisionManager.resetearMisiones(player)
	MisionManager.inicializarJugador(player)

	if _eventoActualizar then
		for i = 1, 8 do
			_eventoActualizar:FireClient(player, i, false)
		end
	end
end

return MisionManager
