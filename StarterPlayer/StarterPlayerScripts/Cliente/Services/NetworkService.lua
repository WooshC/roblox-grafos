-- ================================================================
-- NetworkService.lua
-- Capa de abstracción para comunicación Cliente-Servidor
-- ================================================================
-- PROPÓSITO:
--   - Centraliza toda la comunicación con RemoteEvents
--   - Maneja errores de red de forma consistente
--   - Implementa caché de eventos para mejor rendimiento
--   - Facilita testing con mocking
-- ================================================================

local NetworkService = {}
NetworkService.__index = NetworkService

-- ================================================================
-- DEPENDENCIAS
-- ================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Referencias a eventos
local Events = ReplicatedStorage:WaitForChild("Events")
local Remotes = Events:WaitForChild("Remotes")

-- ================================================================
-- ESTADO INTERNO
-- ================================================================

-- Cache de eventos para evitar búsquedas repetidas
local eventCache = {}

-- Conexiones activas (para limpieza)
local activeConnections = {}

-- Estadísticas de red (para debugging)
local networkStats = {
	eventsFired = 0,
	eventsReceived = 0,
	errors = 0
}

-- ================================================================
-- CONFIGURACIÓN
-- ================================================================

local CONFIG = {
	DEFAULT_TIMEOUT = 5,        -- Timeout por defecto en segundos
	RETRY_ATTEMPTS = 3,         -- Intentos de reintento
	RETRY_DELAY = 0.5,          -- Delay entre reintentos
	ENABLE_LOGGING = true,      -- Logging de eventos
	ENABLE_STATS = true         -- Estadísticas de red
}

-- ================================================================
-- UTILIDADES PRIVADAS
-- ================================================================

-- Log de eventos (solo en modo desarrollo)
local function log(message, level)
	if not CONFIG.ENABLE_LOGGING then return end

	level = level or "INFO"
	local prefix = "[NetworkService][" .. level .. "]"

	if level == "ERROR" then
		warn(prefix .. " " .. message)
	else
		print(prefix .. " " .. message)
	end
end

-- Validar nombre de evento
local function isValidEventName(eventName)
	return type(eventName) == "string" and #eventName > 0
end

-- ================================================================
-- MÉTODOS PÚBLICOS
-- ================================================================

--- Obtiene un RemoteEvent por nombre con caché
-- @param eventName (string) Nombre del evento
-- @param timeout (number, opcional) Tiempo de espera en segundos
-- @return RemoteEvent o nil si no se encuentra
function NetworkService:getEvent(eventName, timeout)
	if not isValidEventName(eventName) then
		log("Nombre de evento inválido: " .. tostring(eventName), "ERROR")
		return nil
	end

	-- Verificar caché
	if eventCache[eventName] then
		return eventCache[eventName]
	end

	-- Buscar evento
	local event = Remotes:WaitForChild(eventName, timeout or CONFIG.DEFAULT_TIMEOUT)

	if event then
		eventCache[eventName] = event
		log("Evento cacheado: " .. eventName)
	else
		log("Evento no encontrado: " .. eventName, "ERROR")
		if CONFIG.ENABLE_STATS then
			networkStats.errors = networkStats.errors + 1
		end
	end

	return event
end

--- Dispara un evento al servidor
-- @param eventName (string) Nombre del evento
-- @param ... Argumentos a enviar
-- @return boolean true si se envió correctamente
function NetworkService:fireServer(eventName, ...)
	local event = self:getEvent(eventName)

	if not event then
		log("No se puede disparar evento: " .. eventName, "ERROR")
		return false
	end

	-- Intentar enviar con reintentos
	local attempts = 0
	local success = false

	while attempts < CONFIG.RETRY_ATTEMPTS and not success do
		attempts = attempts + 1

		local ok, err = pcall(function()
			event:FireServer(...)
		end)

		if ok then
			success = true
			if CONFIG.ENABLE_STATS then
				networkStats.eventsFired = networkStats.eventsFired + 1
			end
			log("Evento disparado: " .. eventName .. " (intento " .. attempts .. ")")
		else
			log("Error al disparar evento " .. eventName .. ": " .. tostring(err), "ERROR")

			if attempts < CONFIG.RETRY_ATTEMPTS then
				task.wait(CONFIG.RETRY_DELAY)
			else
				if CONFIG.ENABLE_STATS then
					networkStats.errors = networkStats.errors + 1
				end
			end
		end
	end

	return success
end

--- Conecta un callback a un evento del servidor
-- @param eventName (string) Nombre del evento
-- @param callback (function) Función a ejecutar cuando se recibe el evento
-- @return RBXScriptConnection o nil si falla
function NetworkService:onServerEvent(eventName, callback)
	if type(callback) ~= "function" then
		log("Callback debe ser una función", "ERROR")
		return nil
	end

	local event = self:getEvent(eventName)

	if not event then
		log("No se puede conectar a evento: " .. eventName, "ERROR")
		return nil
	end

	-- Wrappear callback para logging y estadísticas
	local wrappedCallback = function(...)
		if CONFIG.ENABLE_STATS then
			networkStats.eventsReceived = networkStats.eventsReceived + 1
		end

		log("Evento recibido: " .. eventName)

		-- Ejecutar callback en modo protegido
		local ok, err = pcall(callback, ...)

		if not ok then
			log("Error en callback de " .. eventName .. ": " .. tostring(err), "ERROR")
		end
	end

	-- Conectar y guardar referencia
	local connection = event.OnClientEvent:Connect(wrappedCallback)

	if not activeConnections[eventName] then
		activeConnections[eventName] = {}
	end

	table.insert(activeConnections[eventName], connection)

	log("Conectado a evento: " .. eventName)

	return connection
end

--- Desconecta todas las conexiones de un evento
-- @param eventName (string) Nombre del evento
function NetworkService:disconnect(eventName)
	if activeConnections[eventName] then
		for _, connection in ipairs(activeConnections[eventName]) do
			connection:Disconnect()
		end

		activeConnections[eventName] = nil
		log("Desconectado de evento: " .. eventName)
	end
end

--- Desconecta todas las conexiones activas
function NetworkService:disconnectAll()
	for eventName, connections in pairs(activeConnections) do
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
	end

	activeConnections = {}
	log("Todas las conexiones desconectadas")
end

--- Limpia el caché de eventos
-- @param eventName (string, opcional) Si se especifica, solo limpia ese evento
function NetworkService:clearCache(eventName)
	if eventName then
		eventCache[eventName] = nil
		log("Caché limpiado para: " .. eventName)
	else
		eventCache = {}
		log("Caché completamente limpiado")
	end
end

--- Obtiene estadísticas de red
-- @return table con estadísticas
function NetworkService:getStats()
	return {
		eventsFired = networkStats.eventsFired,
		eventsReceived = networkStats.eventsReceived,
		errors = networkStats.errors,
		cachedEvents = #eventCache,
		activeConnections = 0 -- Calcular total
	}
end

--- Resetea estadísticas de red
function NetworkService:resetStats()
	networkStats = {
		eventsFired = 0,
		eventsReceived = 0,
		errors = 0
	}
	log("Estadísticas reseteadas")
end

-- ================================================================
-- FUNCIONES DE UTILIDAD ESPECÍFICAS DEL PROYECTO
-- ================================================================

--- Solicita ejecución de algoritmo (función específica del proyecto)
function NetworkService.requestAlgorithm(algorithmName, startNode, endNode, levelID)
	return NetworkService:fireServer("EjecutarAlgoritmo", algorithmName, startNode, endNode, levelID)
end

--- Solicita reiniciar el nivel
function NetworkService.resetLevel()
	return NetworkService:fireServer("ReiniciarNivel")
end

--- Suscribe a actualizaciones de UI
function NetworkService.subscribeToUIUpdates(callback)
	return NetworkService:onServerEvent("ActualizarUI", callback)
end

--- Suscribe a actualizaciones de inventario
function NetworkService.subscribeToInventory(callback)
	return NetworkService:onServerEvent("ActualizarInventario", callback)
end
--- Subscribe to mission updates
function NetworkService.subscribeToMissions(callback)
    return NetworkService:onServerEvent("ActualizarMision", callback)
end


-- ================================================================
-- INICIALIZACIÓN Y LIMPIEZA
-- ================================================================

-- Limpieza automática cuando el jugador sale
if game:GetService("Players").LocalPlayer then
	game:GetService("Players").LocalPlayer.AncestryChanged:Connect(function()
		NetworkService:disconnectAll()
	end)
end

-- ================================================================
-- EXPORTAR
-- ================================================================

return NetworkService