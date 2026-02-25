-- ReplicatedStorage/Utilidades/AliasUtils.lua
-- Sistema centralizado para obtener nombres personalizados de nodos
-- Evita duplicación de lógica y facilita cambios futuros

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))

local AliasUtils = {}

-- ============================================
-- OBTENER ALIAS DE UN NODO
-- ============================================

--- Obtiene el nombre personalizado de un nodo
--- Primero intenta obtenerlo de Nodos[nodeName].Alias
--- Si no existe, devuelve el nombre del nodo (fallback)
--- @param nivelID number
--- @param nodeName string
--- @return string nombreMostrar
function AliasUtils.getNodeAlias(nivelID, nodeName)
	if not nodeName then return "Nodo Desconocido" end

	local config = LevelsConfig[nivelID]
	if not config then return nodeName end

	-- PRIORIDAD 1: Buscar en Nodos[nodeName].Alias (Nueva estructura)
	if config.Nodos and config.Nodos[nodeName] then
		local nodoData = config.Nodos[nodeName]
		if nodoData.Alias and nodoData.Alias ~= "" then
			return nodoData.Alias
		end
	end

	-- PRIORIDAD 2: Buscar en NombresPostes (Retrocompatibilidad con viejo sistema)
	if config.NombresPostes and config.NombresPostes[nodeName] then
		return config.NombresPostes[nodeName]
	end

	-- FALLBACK: Devolver nombre del nodo
	return nodeName
end

--- Obtiene todos los aliases de un nivel
--- Útil para generar listas, mapeos, etc.
--- @param nivelID number
--- @return table { [nodeName] = "Alias" }
function AliasUtils.getAllNodeAliases(nivelID)
	local config = LevelsConfig[nivelID]
	local aliases = {}

	if not config or not config.Nodos then return aliases end

	for nodeName, nodoData in pairs(config.Nodos) do
		aliases[nodeName] = AliasUtils.getNodeAlias(nivelID, nodeName)
	end

	return aliases
end

--- Obtiene la zona de un nodo
--- @param nivelID number
--- @param nodeName string
--- @return string|nil zonaID
function AliasUtils.getNodeZone(nivelID, nodeName)
	local config = LevelsConfig[nivelID]

	if config and config.Nodos and config.Nodos[nodeName] then
		return config.Nodos[nodeName].Zona
	end

	return nil
end

--- Verifica si un nodo pertenece a una zona específica
--- @param nivelID number
--- @param nodeName string
--- @param zonaID string
--- @return boolean
function AliasUtils.nodeInZone(nivelID, nodeName, zonaID)
	return AliasUtils.getNodeZone(nivelID, nodeName) == zonaID
end

-- ============================================
-- OBTENER INFO DE ZONAS
-- ============================================

--- Obtiene todos los nodos de una zona específica
--- @param nivelID number
--- @param zonaID string
--- @return table array de nombres de nodos
function AliasUtils.getNodesInZone(nivelID, zonaID)
	local config = LevelsConfig[nivelID]
	local nodos = {}

	if not config or not config.Nodos then return nodos end

	for nodeName, nodoData in pairs(config.Nodos) do
		if nodoData.Zona == zonaID then
			table.insert(nodos, nodeName)
		end
	end

	return nodos
end

--- Obtiene la configuración completa de una zona
--- @param nivelID number
--- @param zonaID string
--- @return table|nil configZona
function AliasUtils.getZoneConfig(nivelID, zonaID)
	local config = LevelsConfig[nivelID]

	if config and config.Zonas and config.Zonas[zonaID] then
		return config.Zonas[zonaID]
	end

	return nil
end

-- ============================================
-- BÚSQUEDA Y VALIDACIÓN
-- ============================================

--- Busca un nodo por su alias (búsqueda inversa)
--- @param nivelID number
--- @param alias string
--- @return string|nil nombreNodo
function AliasUtils.getNodeByAlias(nivelID, alias)
	local config = LevelsConfig[nivelID]

	if not config or not config.Nodos then return nil end

	for nodeName, nodoData in pairs(config.Nodos) do
		if nodoData.Alias == alias then
			return nodeName
		end
	end

	return nil
end

--- Verifica si un nodo existe en el nivel
--- @param nivelID number
--- @param nodeName string
--- @return boolean
function AliasUtils.nodeExists(nivelID, nodeName)
	local config = LevelsConfig[nivelID]

	if not config or not config.Nodos then return false end

	return config.Nodos[nodeName] ~= nil
end

--- Obtiene todos los nombres de nodos del nivel
--- @param nivelID number
--- @return table array de nombres
function AliasUtils.getAllNodeNames(nivelID)
	local config = LevelsConfig[nivelID]
	local nombres = {}

	if not config or not config.Nodos then return nombres end

	for nodeName, _ in pairs(config.Nodos) do
		table.insert(nombres, nodeName)
	end

	return nombres
end

return AliasUtils