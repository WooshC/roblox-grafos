-- ReplicatedStorage/Utilidades/NivelUtils.lua
-- Utilidades compartidas para todos los niveles
-- Se puede usar tanto en server como client

local NivelUtils = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))

-- ============================================
-- OBTENER CONFIG
-- ============================================

--- Retorna la config de un nivel por ID
function NivelUtils.getConfig(nivelID)
	return LevelsConfig[nivelID]
end

--- Retorna true si el nivel existe
function NivelUtils.levelExists(nivelID)
	return LevelsConfig[nivelID] ~= nil
end

--- Retorna lista de IDs de niveles disponibles
function NivelUtils.getAllLevelIDs()
	local ids = {}
	for id, _ in pairs(LevelsConfig) do
		table.insert(ids, id)
	end
	table.sort(ids)
	return ids
end

-- ============================================
-- NODOS
-- ============================================

--- Obtiene datos de un nodo por nombre
function NivelUtils.getNodeData(nivelID, nodeName)
	local config = LevelsConfig[nivelID]
	if not config or not config.Nodos then return nil end
	return config.Nodos[nodeName]
end

--- Obtiene alias visual del nodo (o su nombre si no hay alias)
function NivelUtils.getNodeAlias(nivelID, nodeName)
	local data = NivelUtils.getNodeData(nivelID, nodeName)
	if data and data.Alias then return data.Alias end
	local config = LevelsConfig[nivelID]
	if config and config.NombresPostes and config.NombresPostes[nodeName] then
		return config.NombresPostes[nodeName]
	end
	return nodeName
end

--- Obtiene la zona a la que pertenece un nodo
function NivelUtils.getNodeZone(nivelID, nodeName)
	local data = NivelUtils.getNodeData(nivelID, nodeName)
	return data and data.Zona or nil
end

--- Obtiene todos los nodos de una zona
function NivelUtils.getNodesInZone(nivelID, zonaID)
	local config = LevelsConfig[nivelID]
	if not config or not config.Nodos then return {} end

	local resultado = {}
	for nodeName, data in pairs(config.Nodos) do
		if data.Zona == zonaID then
			resultado[nodeName] = data
		end
	end
	return resultado
end

--- Obtiene vecinos (adyacencias) de un nodo
function NivelUtils.getNeighbors(nivelID, nodeName)
	local config = LevelsConfig[nivelID]
	if not config or not config.Adyacencias then return {} end
	return config.Adyacencias[nodeName] or {}
end

--- Verifica si dos nodos son adyacentes (en alguna dirección)
function NivelUtils.areAdjacent(nivelID, nodeA, nodeB)
	local neighborsA = NivelUtils.getNeighbors(nivelID, nodeA)
	local neighborsB = NivelUtils.getNeighbors(nivelID, nodeB)
	return table.find(neighborsA, nodeB) ~= nil or table.find(neighborsB, nodeA) ~= nil
end

--- Verifica si la arista es unidireccional (A→B pero no B→A)
function NivelUtils.isDirectedEdge(nivelID, nodeA, nodeB)
	local neighborsA = NivelUtils.getNeighbors(nivelID, nodeA)
	local neighborsB = NivelUtils.getNeighbors(nivelID, nodeB)
	local aToB = table.find(neighborsA, nodeB) ~= nil
	local bToA = table.find(neighborsB, nodeA) ~= nil
	return aToB and not bToA
end

-- ============================================
-- ZONAS
-- ============================================

--- Obtiene config de una zona
function NivelUtils.getZoneConfig(nivelID, zonaID)
	local config = LevelsConfig[nivelID]
	if not config or not config.Zonas then return nil end
	return config.Zonas[zonaID]
end

--- Obtiene todas las zonas del nivel
function NivelUtils.getAllZones(nivelID)
	local config = LevelsConfig[nivelID]
	if not config or not config.Zonas then return {} end
	return config.Zonas
end

--- Obtiene lista ordenada de zonas (por nombre)
function NivelUtils.getZoneList(nivelID)
	local config = LevelsConfig[nivelID]
	if not config or not config.Zonas then return {} end

	local zonas = {}
	for zonaID, zonaData in pairs(config.Zonas) do
		table.insert(zonas, {
			ID = zonaID,
			Descripcion = zonaData.Descripcion or zonaID,
			Color = zonaData.Color,
			Concepto = zonaData.Concepto,
			Modo = zonaData.Modo or "ANY",
			NodosRequeridos = zonaData.NodosRequeridos or {}
		})
	end
	table.sort(zonas, function(a, b) return a.ID < b.ID end)
	return zonas
end

-- ============================================
-- MISIONES
-- ============================================

--- Obtiene misiones filtradas por zona
function NivelUtils.getMissionsByZone(nivelID, zonaID)
	local config = LevelsConfig[nivelID]
	if not config or not config.Misiones then return {} end

	local resultado = {}
	for _, mision in ipairs(config.Misiones) do
		if mision.Zona == zonaID then
			table.insert(resultado, mision)
		end
	end
	return resultado
end

--- Obtiene misiones sin zona (bonus/globales)
function NivelUtils.getGlobalMissions(nivelID)
	return NivelUtils.getMissionsByZone(nivelID, nil)
end

--- Obtiene todas las misiones
function NivelUtils.getAllMissions(nivelID)
	local config = LevelsConfig[nivelID]
	if not config or not config.Misiones then return {} end
	return config.Misiones
end

--- Cuenta misiones por zona
function NivelUtils.countMissionsInZone(nivelID, zonaID)
	local misiones = NivelUtils.getMissionsByZone(nivelID, zonaID)
	return #misiones
end

--- Obtiene total de puntos posibles del nivel
function NivelUtils.getTotalPoints(nivelID)
	local config = LevelsConfig[nivelID]
	if not config or not config.Misiones then return 0 end

	local total = 0
	for _, mision in ipairs(config.Misiones) do
		total = total + (mision.Puntos or 0)
	end
	return total
end

-- ============================================
-- CONDICIÓN DE VICTORIA
-- ============================================

--- Retorna el tipo de condición de victoria
function NivelUtils.getVictoryCondition(nivelID)
	local config = LevelsConfig[nivelID]
	if not config then return nil end
	return config.CondicionVictoria or "CIRCUITO_CERRADO"
end

--- Retorna true si el nivel usa algoritmos
function NivelUtils.hasAlgorithm(nivelID)
	local config = LevelsConfig[nivelID]
	return config and config.Algoritmo ~= nil
end

--- Retorna el algoritmo del nivel (nil si no tiene)
function NivelUtils.getAlgorithm(nivelID)
	local config = LevelsConfig[nivelID]
	return config and config.Algoritmo
end

--- Retorna true si el nivel es gratuito (sin costo por cable)
function NivelUtils.isFreeLevel(nivelID)
	local config = LevelsConfig[nivelID]
	return config and (config.CostoPorMetro or 0) == 0
end

-- ============================================
-- PUNTUACIÓN
-- ============================================

--- Calcula estrellas basado en puntos
function NivelUtils.calculateStars(nivelID, puntos)
	local config = LevelsConfig[nivelID]
	if not config or not config.Puntuacion then return 0 end

	local p = config.Puntuacion
	if puntos >= (p.TresEstrellas or math.huge) then return 3 end
	if puntos >= (p.DosEstrellas or math.huge) then return 2 end
	if puntos > 0 then return 1 end
	return 0
end

--- Obtiene la recompensa XP del nivel
function NivelUtils.getXPReward(nivelID)
	local config = LevelsConfig[nivelID]
	return config and config.Puntuacion and config.Puntuacion.RecompensaXP or 0
end

-- ============================================
-- UTILIDADES DE GRAFO
-- ============================================

--- Cuenta el total de nodos del nivel
function NivelUtils.getNodeCount(nivelID)
	local config = LevelsConfig[nivelID]
	if config and config.NodosTotales then return config.NodosTotales end
	if config and config.Nodos then
		local count = 0
		for _ in pairs(config.Nodos) do count = count + 1 end
		return count
	end
	return 0
end

--- Cuenta el total de aristas posibles (adyacencias)
function NivelUtils.getEdgeCount(nivelID)
	local config = LevelsConfig[nivelID]
	if not config or not config.Adyacencias then return 0 end

	local edges = {}
	for nodeA, neighbors in pairs(config.Adyacencias) do
		for _, nodeB in ipairs(neighbors) do
			local key = nodeA < nodeB and (nodeA .. "_" .. nodeB) or (nodeB .. "_" .. nodeA)
			edges[key] = true
		end
	end

	local count = 0
	for _ in pairs(edges) do count = count + 1 end
	return count
end

--- Verifica si un nodo es el inicio o fin del nivel
function NivelUtils.isSpecialNode(nivelID, nodeName)
	local config = LevelsConfig[nivelID]
	if not config then return false end
	return nodeName == config.NodoInicio or nodeName == config.NodoFin
end

return NivelUtils