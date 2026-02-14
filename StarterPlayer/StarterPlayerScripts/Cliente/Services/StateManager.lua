-- ================================================================
-- StateManager.lua
-- Gestor de Estado Centralizado con Patrón Observer
-- ================================================================
-- PROPÓSITO:
--   - Gestión centralizada del estado de la aplicación
--   - Implementa patrón Observer para reactividad
--   - Path-based access para navegación fácil
--   - Historial de cambios para debugging
-- ================================================================

local StateManager = {}
StateManager.__index = StateManager

-- ================================================================
-- ESTADO GLOBAL
-- ================================================================

local state = {
	-- Información del nivel actual
	level = {
		id = 0,
		name = "",
		progress = 0,
		completed = false,
		startNode = nil,
		endNode = nil
	},

	-- Estado de la interfaz
	ui = {
		mapActive = false,
		missionsActive = false,
		zoomLevel = 85,
		selectedNode = nil,
		inMenu = true
	},

	-- Nodos del nivel
	nodes = {},

	-- Cables conectados
	cables = {},

	-- Inventario del jugador
	inventory = {},

	-- Misiones activas
	missions = {}
}

-- ================================================================
-- OBSERVADORES Y EVENTOS
-- ================================================================

-- Observadores suscritos a paths específicos
-- Formato: { [path] = { callback1, callback2, ... } }
local observers = {}

-- Historial de cambios (para debugging y undo/redo)
local history = {}
local MAX_HISTORY_SIZE = 50

-- ================================================================
-- CONFIGURACIÓN
-- ================================================================

local CONFIG = {
	ENABLE_LOGGING = true,      -- Logging de cambios
	ENABLE_HISTORY = true,      -- Historial de cambios
	DEEP_CLONE = true           -- Clonar valores al obtenerlos
}

-- ================================================================
-- UTILIDADES PRIVADAS
-- ================================================================

-- Log de cambios
local function log(message, level)
	if not CONFIG.ENABLE_LOGGING then return end

	level = level or "INFO"
	local prefix = "[StateManager][" .. level .. "]"

	if level == "ERROR" then
		warn(prefix .. " " .. message)
	else
		print(prefix .. " " .. message)
	end
end

-- Clona un valor profundamente (para evitar mutaciones)
local function deepClone(value)
	if not CONFIG.DEEP_CLONE then
		return value
	end

	if type(value) ~= "table" then
		return value
	end

	local clone = {}
	for k, v in pairs(value) do
		clone[k] = deepClone(v)
	end

	return clone
end

-- Divide un path en keys
local function splitPath(path)
	if type(path) ~= "string" then
		return {}
	end
	return string.split(path, ".")
end

-- Navega por el estado usando un array de keys
local function navigate(current, keys, createMissing)
	for i, key in ipairs(keys) do
		if current[key] == nil then
			if createMissing and i < #keys then
				current[key] = {}
			else
				return nil
			end
		end

		if i < #keys then
			current = current[key]
		end
	end

	return current, keys[#keys]
end

-- Agrega un cambio al historial
local function addToHistory(path, oldValue, newValue)
	if not CONFIG.ENABLE_HISTORY then return end

	table.insert(history, {
		timestamp = os.clock(),
		path = path,
		oldValue = deepClone(oldValue),
		newValue = deepClone(newValue)
	})

	-- Limitar tamaño del historial
	if #history > MAX_HISTORY_SIZE then
		table.remove(history, 1)
	end
end

-- ================================================================
-- MÉTODOS PÚBLICOS - LECTURA
-- ================================================================

--- Obtiene un valor del estado usando un path
-- @param path (string) Path con notación de puntos (ej: "level.id")
-- @return valor o nil si no existe
function StateManager:get(path)
	if not path then
		-- Retornar todo el estado si no se especifica path
		return deepClone(state)
	end

	local keys = splitPath(path)
	if #keys == 0 then
		return deepClone(state)
	end

	local parent, lastKey = navigate(state, keys, false)

	if parent and lastKey then
		return deepClone(parent[lastKey])
	end

	return nil
end

--- Verifica si existe un valor en el path especificado
-- @param path (string) Path a verificar
-- @return boolean
function StateManager:has(path)
	local keys = splitPath(path)
	if #keys == 0 then return true end

	local parent, lastKey = navigate(state, keys, false)
	return parent ~= nil and parent[lastKey] ~= nil
end

-- ================================================================
-- MÉTODOS PÚBLICOS - ESCRITURA
-- ================================================================

--- Establece un valor en el estado
-- @param path (string) Path con notación de puntos
-- @param value (any) Valor a establecer
function StateManager:set(path, value)
	local keys = splitPath(path)

	if #keys == 0 then
		log("Path inválido para set: " .. tostring(path), "ERROR")
		return
	end

	-- Navegar hasta el penúltimo nivel, creando objetos si es necesario
	local parent, lastKey = navigate(state, keys, true)

	if not parent then
		log("No se pudo navegar al path: " .. path, "ERROR")
		return
	end

	-- Obtener valor anterior
	local oldValue = parent[lastKey]

	-- Establecer nuevo valor
	parent[lastKey] = value

	-- Agregar al historial
	addToHistory(path, oldValue, value)

	-- Log del cambio
	log(string.format("SET %s: %s -> %s", path, tostring(oldValue), tostring(value)))

	-- Notificar a observadores
	self:notifyObservers(path, value, oldValue)
end

--- Actualiza un valor usando una función
-- @param path (string) Path del valor
-- @param updater (function) Función que recibe el valor actual y retorna el nuevo
function StateManager:update(path, updater)
	if type(updater) ~= "function" then
		log("Updater debe ser una función", "ERROR")
		return
	end

	local currentValue = self:get(path)
	local newValue = updater(currentValue)
	self:set(path, newValue)
end

--- Elimina un valor del estado
-- @param path (string) Path del valor a eliminar
function StateManager:delete(path)
	local keys = splitPath(path)

	if #keys == 0 then
		log("No se puede eliminar el estado raíz", "ERROR")
		return
	end

	local parent, lastKey = navigate(state, keys, false)

	if parent and lastKey then
		local oldValue = parent[lastKey]
		parent[lastKey] = nil

		addToHistory(path, oldValue, nil)
		log("DELETE " .. path)

		self:notifyObservers(path, nil, oldValue)
	end
end

--- Resetea el estado a sus valores iniciales
function StateManager:reset()
	local oldState = deepClone(state)

	state = {
		level = { id = 0, name = "", progress = 0, completed = false, startNode = nil, endNode = nil },
		ui = { mapActive = false, missionsActive = false, zoomLevel = 85, selectedNode = nil, inMenu = true },
		nodes = {},
		cables = {},
		inventory = {},
		missions = {}
	}

	history = {}
	log("Estado reseteado")

	-- Notificar a todos los observadores
	for path in pairs(observers) do
		self:notifyObservers(path, self:get(path), nil)
	end
end

-- ================================================================
-- MÉTODOS PÚBLICOS - OBSERVADORES
-- ================================================================

--- Suscribe un callback a cambios en un path específico
-- @param path (string) Path a observar
-- @param callback (function) Función a ejecutar cuando cambia el valor
-- @return function de desuscripción
function StateManager:subscribe(path, callback)
	if type(callback) ~= "function" then
		log("Callback debe ser una función", "ERROR")
		return function() end
	end

	if not observers[path] then
		observers[path] = {}
	end

	table.insert(observers[path], callback)

	log("Observador agregado para: " .. path)

	-- Retornar función de desuscripción
	return function()
		local index = table.find(observers[path], callback)
		if index then
			table.remove(observers[path], index)
			log("Observador removido de: " .. path)
		end
	end
end

--- Notifica a los observadores de un path
-- @param path (string) Path que cambió
-- @param newValue (any) Nuevo valor
-- @param oldValue (any) Valor anterior
function StateManager:notifyObservers(path, newValue, oldValue)
	-- Notificar observadores exactos
	if observers[path] then
		for _, callback in ipairs(observers[path]) do
			task.spawn(function()
				local ok, err = pcall(callback, newValue, oldValue)
				if not ok then
					log("Error en observer de " .. path .. ": " .. tostring(err), "ERROR")
				end
			end)
		end
	end

	-- Notificar observadores de paths padres
	-- Por ejemplo, si cambia "level.id", notificar a observers de "level"
	local keys = splitPath(path)
	for i = 1, #keys - 1 do
		local parentPath = table.concat(keys, ".", 1, i)
		if observers[parentPath] then
			local parentValue = self:get(parentPath)
			for _, callback in ipairs(observers[parentPath]) do
				task.spawn(function()
					local ok, err = pcall(callback, parentValue, nil)
					if not ok then
						log("Error en observer de " .. parentPath .. ": " .. tostring(err), "ERROR")
					end
				end)
			end
		end
	end
end

-- ================================================================
-- MÉTODOS PÚBLICOS - HISTORIAL
-- ================================================================

--- Obtiene el historial de cambios
-- @param limit (number, opcional) Número máximo de entradas
-- @return array de cambios
function StateManager:getHistory(limit)
	local result = {}

	local start = limit and math.max(1, #history - limit + 1) or 1

	for i = start, #history do
		table.insert(result, {
			timestamp = history[i].timestamp,
			path = history[i].path,
			oldValue = history[i].oldValue,
			newValue = history[i].newValue
		})
	end

	return result
end

--- Limpia el historial de cambios
function StateManager:clearHistory()
	history = {}
	log("Historial limpiado")
end

-- ================================================================
-- MÉTODOS PÚBLICOS - DEBUGGING
-- ================================================================

--- Imprime el estado actual en consola
function StateManager:debug()
	print("\n========== STATE DEBUG ==========")
	print("Estado actual:")

	local function printTable(tbl, indent)
		indent = indent or ""
		for k, v in pairs(tbl) do
			if type(v) == "table" then
				print(indent .. tostring(k) .. ":")
				printTable(v, indent .. "  ")
			else
				print(indent .. tostring(k) .. ": " .. tostring(v))
			end
		end
	end

	printTable(state)

	print("\nObservadores activos:")
	for path, observers in pairs(observers) do
		print("  " .. path .. ": " .. #observers .. " observer(s)")
	end

	print("\nHistorial: " .. #history .. " cambios")
	print("=================================\n")
end

--- Obtiene estadísticas del estado
-- @return table con estadísticas
function StateManager:getStats()
	local function countKeys(tbl)
		local count = 0
		for _ in pairs(tbl) do
			count = count + 1
		end
		return count
	end

	return {
		nodesCount = countKeys(state.nodes),
		cablesCount = countKeys(state.cables),
		inventoryCount = countKeys(state.inventory),
		missionsCount = countKeys(state.missions),
		observersCount = countKeys(observers),
		historySize = #history
	}
end

-- ================================================================
-- EXPORTAR
-- ================================================================

return StateManager