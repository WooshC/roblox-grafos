-- MisionManager.lua
-- Sistema de Misiones Flexible y Granular (Versión 2.0 - Refactorizado)
-- Reemplaza completamente el sistema antiguo

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MisionManager = {}

-- Estado de misiones por jugador
local _estadoMisiones = {}

-- Evento para actualizar UI
local _eventoActualizar = nil

-- ============================================
-- VALIDADORES POR TIPO DE MISIÓN
-- ============================================

local Validadores = {
	--- Verifica que al menos X nodos estén energizados
	NODOS_MINIMOS = function(params, estado)
		local cantidad = params.Cantidad or 0
		return estado.numNodosConectados >= cantidad
	end,
	
	--- Verifica que un nodo específico esté energizado
	NODO_ENERGIZADO = function(params, estado)
		local nodo = params.Nodo
		if not nodo then
			warn("⚠️ NODO_ENERGIZADO requiere parámetro 'Nodo'")
			return false
		end
		return estado.nodosVisitados[nodo] == true
	end,
	
	--- Verifica que TODOS los nodos del nivel estén energizados
	TODOS_LOS_NODOS = function(params, estado)
		local cantidad = params.Cantidad or 0
		return estado.numNodosConectados >= cantidad and estado.circuitoCerrado
	end,
	
	--- Verifica que una zona específica esté activada
	ZONA_ACTIVADA = function(params, estado)
		local zona = params.Zona
		if not zona then
			warn("⚠️ ZONA_ACTIVADA requiere parámetro 'Zona'")
			return false
		end
		return estado.zonasActivas and estado.zonasActivas[zona] == true
	end,
	
	--- Verifica que el jugador tenga al menos X dinero restante
	PRESUPUESTO_RESTANTE = function(params, estado)
		local cantidad = params.Cantidad or 0
		return estado.dineroRestante >= cantidad
	end,
	
	--- Verifica que haya al menos X cables conectados
	CONEXIONES_MINIMAS = function(params, estado)
		local cantidad = params.Cantidad or 0
		return estado.numConexiones >= cantidad
	end,
	
	--- Verifica que TODOS los nodos de una lista estén energizados
	NODOS_LISTA = function(params, estado)
		local nodos = params.Nodos or {}
		for _, nodo in ipairs(nodos) do
			if not estado.nodosVisitados[nodo] then
				return false
			end
		end
		return #nodos > 0
	end,
	
	--- Permite lógica personalizada mediante función
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
	
	--- Verifica que el circuito esté cerrado
	CIRCUITO_CERRADO = function(params, estado)
		return estado.circuitoCerrado == true
	end,
	
	--- Verifica que se hayan gastado menos de X dinero
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
	-- Referencias a eventos estáticos
	local Remotes = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes")
	_eventoActualizar = Remotes:WaitForChild("ActualizarMision")
end

-- ============================================
-- GESTIÓN DE ESTADO
-- ============================================

--- Inicializa el estado de misiones para un jugador
--- @param player Player
function MisionManager.inicializarJugador(player)
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
end

--- Limpia el estado al salir
--- @param player Player
function MisionManager.limpiarJugador(player)
	_estadoMisiones[player.UserId] = nil
end

--- Obtiene el estado actual de una misión
--- @param player Player
--- @param misionID number
--- @return boolean
function MisionManager.obtenerEstado(player, misionID)
	local estado = _estadoMisiones[player.UserId]
	if not estado then return false end
	
	return estado["mision" .. misionID] or false
end

-- ============================================
-- ACTUALIZACIÓN DE MISIONES
-- ============================================

--- Actualiza una misión solo si cambió de estado
--- @param player Player
--- @param misionID number
--- @param completada boolean
function MisionManager.actualizarMision(player, misionID, completada)
	local estado = _estadoMisiones[player.UserId]
	if not estado then
		MisionManager.inicializarJugador(player)
		estado = _estadoMisiones[player.UserId]
	end
	
	local key = "mision" .. misionID
	
	-- Solo disparar evento si el estado CAMBIÓ
	if estado[key] ~= completada then
		estado[key] = completada
		
		if _eventoActualizar then
			_eventoActualizar:FireClient(player, misionID, completada)
			print("✅ Misión " .. misionID .. " actualizada para " .. player.Name .. ": " .. tostring(completada))
		end
	end
end

--- Actualiza misiones para TODOS los jugadores (broadcast)
--- @param misionID number
--- @param completada boolean
function MisionManager.actualizarMisionGlobal(misionID, completada)
	if not _eventoActualizar then return end
	
	_eventoActualizar:FireAllClients(misionID, completada)
	print("📢 Misión " .. misionID .. " actualizada globalmente: " .. tostring(completada))
end

-- ============================================
-- VERIFICACIÓN DE MISIONES (NUEVO SISTEMA)
-- ============================================

--- Verifica el estado de una misión individual
--- @param misionConfig table - Configuración de la misión
--- @param estadoJuego table - Estado actual del juego
--- @return boolean
function MisionManager.verificarMision(misionConfig, estadoJuego)
	-- Compatibilidad: Si es string, retornar false (formato antiguo)
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

--- Verifica todas las misiones de un nivel
--- @param nivelConfig table - Configuración del nivel
--- @param estadoJuego table - Estado actual del juego
--- @return table - {[misionID] = completada}
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

--- Construye el objeto estadoJuego desde los datos de BFS
--- @param visitados table - Tabla de nodos visitados
--- @param numNodosConectados number - Cantidad de nodos energizados
--- @param config table - Configuración del nivel
--- @param player Player - Jugador (opcional)
--- @param zonasActivas table - Tabla de zonas activas (opcional)
--- @return table - Estado del juego
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

--- Resetea todas las misiones de un jugador
--- @param player Player
function MisionManager.resetearMisiones(player)
	MisionManager.inicializarJugador(player)
	
	-- Notificar al cliente
	if _eventoActualizar then
		for i = 1, 8 do
			_eventoActualizar:FireClient(player, i, false)
		end
	end
end

return MisionManager
