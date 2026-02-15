-- ReplicatedStorage/Shared/Utils/GraphUtils.lua
-- Utilidades de grafos: BFS, conectividad, grado
-- MEJORADO: Funciona con cables del GraphService

local GraphUtils = {}

--- BFS desde un nodo. Retorna { [nodeName] = true } para todos los alcanzables
--- @param startNode Instance — el poste/modelo de inicio
--- @param cables table — tabla de cables { [key] = { nodeA, nodeB, cableInstance } }
--- @return table alcanzables { [nodeName] = true }
function GraphUtils.bfs(startNode, cables)
	if not startNode then return {} end

	local alcanzables = {}
	local queue = { startNode.Name }
	alcanzables[startNode.Name] = true

	-- Construir grafo de adyacencia desde cables
	local adj = {}
	for _, info in pairs(cables) do
		local nA = info.nodeA.Name
		local nB = info.nodeB.Name
		if not adj[nA] then adj[nA] = {} end
		if not adj[nB] then adj[nB] = {} end
		table.insert(adj[nA], nB)
		table.insert(adj[nB], nA)
	end

	local head = 1
	while head <= #queue do
		local current = queue[head]
		head = head + 1

		local vecinos = adj[current] or {}
		for _, vecino in ipairs(vecinos) do
			if not alcanzables[vecino] then
				alcanzables[vecino] = true
				table.insert(queue, vecino)
			end
		end
	end

	return alcanzables
end

--- BFS desde un nodo usando la tabla de adyacencias de LevelsConfig
--- (para planificación sin cables reales)
--- @param startName string — nombre del nodo de inicio
--- @param adyacencias table — tabla { [nodo] = {vecino1, vecino2, ...} }
--- @return table alcanzables { [nodeName] = true }
function GraphUtils.bfsFromConfig(startName, adyacencias)
	if not startName or not adyacencias then return {} end

	local alcanzables = {}
	local queue = { startName }
	alcanzables[startName] = true

	local head = 1
	while head <= #queue do
		local current = queue[head]
		head = head + 1

		local vecinos = adyacencias[current] or {}
		for _, vecino in ipairs(vecinos) do
			if not alcanzables[vecino] then
				alcanzables[vecino] = true
				table.insert(queue, vecino)
			end
		end
	end

	return alcanzables
end

--- Verifica si un conjunto de nodos están todos conectados entre sí
--- @param nodeNames table — lista de nombres {"Nodo1", "Nodo2", ...}
--- @param cables table — cables del GraphService
--- @return boolean
function GraphUtils.areAllConnected(nodeNames, cables)
	if not nodeNames or #nodeNames == 0 then return false end
	if #nodeNames == 1 then return true end

	-- Crear un nodo dummy para BFS
	local fakeStart = { Name = nodeNames[1] }
	local alcanzables = GraphUtils.bfs(fakeStart, cables)

	for _, name in ipairs(nodeNames) do
		if not alcanzables[name] then
			return false
		end
	end
	return true
end

--- Calcula el grado de un nodo (número de cables conectados)
--- @param nodeName string
--- @param cables table
--- @return number
function GraphUtils.degree(nodeName, cables)
	local count = 0
	for _, info in pairs(cables) do
		if info.nodeA.Name == nodeName or info.nodeB.Name == nodeName then
			count = count + 1
		end
	end
	return count
end

--- Retorna todos los vecinos de un nodo según los cables existentes
--- @param nodeName string
--- @param cables table
--- @return table vecinos { string }
function GraphUtils.getConnectedNeighbors(nodeName, cables)
	local vecinos = {}
	for _, info in pairs(cables) do
		if info.nodeA.Name == nodeName then
			table.insert(vecinos, info.nodeB.Name)
		elseif info.nodeB.Name == nodeName then
			table.insert(vecinos, info.nodeA.Name)
		end
	end
	return vecinos
end

--- Cuenta componentes conexos en el grafo actual
--- @param nodeNames table — todos los nodos del nivel
--- @param cables table
--- @return number
function GraphUtils.countComponents(nodeNames, cables)
	local visited = {}
	local components = 0

	for _, name in ipairs(nodeNames) do
		if not visited[name] then
			components = components + 1
			local fakeStart = { Name = name }
			local alcanzables = GraphUtils.bfs(fakeStart, cables)
			for alcName, _ in pairs(alcanzables) do
				visited[alcName] = true
			end
		end
	end

	return components
end

--- Dijkstra simple (para niveles con pesos)
--- @param startName string
--- @param cables table — con info de distancia
--- @return table distancias { [nodeName] = number }, table previos { [nodeName] = string }
function GraphUtils.dijkstra(startName, cables)
	local dist = {}
	local prev = {}
	local visited = {}

	-- Construir grafo ponderado
	local adj = {}
	for _, info in pairs(cables) do
		local nA = info.nodeA.Name
		local nB = info.nodeB.Name
		local weight = 1
		-- Si el cable tiene distancia guardada
		if info.nodeA:FindFirstChild("Connections") then
			local conn = info.nodeA.Connections:FindFirstChild(nB)
			if conn then weight = conn.Value end
		end
		if not adj[nA] then adj[nA] = {} end
		if not adj[nB] then adj[nB] = {} end
		table.insert(adj[nA], { node = nB, weight = weight })
		table.insert(adj[nB], { node = nA, weight = weight })
	end

	dist[startName] = 0

	while true do
		-- Encontrar nodo no visitado con menor distancia
		local minNode = nil
		local minDist = math.huge

		for node, d in pairs(dist) do
			if not visited[node] and d < minDist then
				minNode = node
				minDist = d
			end
		end

		if not minNode then break end
		visited[minNode] = true

		local vecinos = adj[minNode] or {}
		for _, edge in ipairs(vecinos) do
			local alt = dist[minNode] + edge.weight
			if not dist[edge.node] or alt < dist[edge.node] then
				dist[edge.node] = alt
				prev[edge.node] = minNode
			end
		end
	end

	return dist, prev
end

--- Reconstruye camino desde Dijkstra
--- @param prev table — tabla de nodos previos
--- @param startName string
--- @param endName string
--- @return table path — lista ordenada de nombres de nodos
function GraphUtils.reconstructPath(prev, startName, endName)
	local path = {}
	local current = endName

	while current do
		table.insert(path, 1, current)
		if current == startName then break end
		current = prev[current]
	end

	if path[1] ~= startName then
		return {} -- No hay camino
	end

	return path
end

return GraphUtils