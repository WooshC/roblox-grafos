-- ReplicatedStorage/Shared/Utils/GraphUtils.lua
-- Funciones COMPARTIDAS para trabajar con grafos
-- Usadas por GraphService, EnergyService, VisualizadorAlgoritmos

local GraphUtils = {}

-- ============================================
-- FUNCIONES DE CLAVES DE CABLE
-- ============================================

-- Genera una clave ÚNICA y CONSISTENTE para un cable entre dos nodos
-- getCableKey(poste_A, poste_B) = "Poste_0_Poste_1" o "Poste_1_Poste_0" (siempre el mismo)
function GraphUtils.getCableKey(nodeA, nodeB)
	local nameA = nodeA.Name
	local nameB = nodeB.Name

	-- Orden alfabético para garantizar consistencia
	if nameA < nameB then
		return nameA .. "_" .. nameB
	else
		return nameB .. "_" .. nameA
	end
end

-- ============================================
-- FUNCIONES DE BÚSQUEDA
-- ============================================

-- Obtiene la carpeta de Postes del nivel actual
function GraphUtils.getPostesFolder(levelFolder)
	if not levelFolder then return nil end
	return levelFolder:FindFirstChild("Postes")
end

-- Obtiene todos los postes de un nivel
function GraphUtils.getAllNodes(levelFolder)
	local postesFolder = GraphUtils.getPostesFolder(levelFolder)
	if not postesFolder then return {} end

	local nodes = {}
	for _, poste in pairs(postesFolder:GetChildren()) do
		table.insert(nodes, poste)
	end
	return nodes
end

-- Obtiene un poste por nombre
function GraphUtils.getNodeByName(levelFolder, nodeName)
	local postesFolder = GraphUtils.getPostesFolder(levelFolder)
	if not postesFolder then return nil end

	return postesFolder:FindFirstChild(nodeName)
end

-- ============================================
-- FUNCIONES DE POSICIÓN
-- ============================================

-- Obtiene la posición de un nodo (con Attachment o sin)
function GraphUtils.getNodePosition(node)
	if not node then return Vector3.new(0, 0, 0) end

	-- Intenta usar Attachment si existe
	local attachment = node:FindFirstChild("Attachment")
	if attachment then
		return attachment.WorldPosition
	end

	-- Si no, usa la posición del nodo
	return node.Position
end

-- Calcula la distancia entre dos nodos
function GraphUtils.getDistance(nodeA, nodeB)
	local posA = GraphUtils.getNodePosition(nodeA)
	local posB = GraphUtils.getNodePosition(nodeB)
	return (posA - posB).Magnitude
end

-- ============================================
-- FUNCIONES DE VALIDACIÓN
-- ============================================

-- Valida que dos nodos estén conectados (existe cable entre ellos)
function GraphUtils.areConnected(nodeA, nodeB, cables)
	if not nodeA or not nodeB then return false end

	local key = GraphUtils.getCableKey(nodeA, nodeB)
	return cables[key] ~= nil
end

-- Valida que un nodo tenga al menos una conexión
function GraphUtils.hasConnections(node, cables)
	if not node then return false end

	for key, cable in pairs(cables) do
		if cable.nodeA == node or cable.nodeB == node then
			return true
		end
	end

	return false
end

-- Obtiene todos los vecinos de un nodo
function GraphUtils.getNeighbors(node, cables)
	local neighbors = {}

	for key, cable in pairs(cables) do
		if cable.nodeA == node then
			table.insert(neighbors, cable.nodeB)
		elseif cable.nodeB == node then
			table.insert(neighbors, cable.nodeA)
		end
	end

	return neighbors
end

-- ============================================
-- FUNCIONES DE BÚSQUEDA EN GRAFO
-- ============================================

-- BFS (Breadth-First Search) - Encuentra todos los nodos alcanzables desde un nodo inicial
function GraphUtils.bfs(startNode, cables)
	if not startNode then return {} end

	local visited = {}
	local queue = { startNode }
	visited[startNode.Name] = true

	while #queue > 0 do
		local current = table.remove(queue, 1)
		local neighbors = GraphUtils.getNeighbors(current, cables)

		for _, neighbor in pairs(neighbors) do
			if not visited[neighbor.Name] then
				visited[neighbor.Name] = true
				table.insert(queue, neighbor)
			end
		end
	end

	return visited
end

-- DFS (Depth-First Search) - Alternativa a BFS
function GraphUtils.dfs(startNode, cables)
	if not startNode then return {} end

	local visited = {}

	local function explore(node)
		visited[node.Name] = true
		local neighbors = GraphUtils.getNeighbors(node, cables)

		for _, neighbor in pairs(neighbors) do
			if not visited[neighbor.Name] then
				explore(neighbor)
			end
		end
	end

	explore(startNode)
	return visited
end

-- Dijkstra simplificado (todos los aristas tienen peso 1)
function GraphUtils.dijkstra(startNode, cables)
	if not startNode then return {} end

	local distances = {}
	local unvisited = {}

	-- Inicializar
	distances[startNode.Name] = 0

	-- Obtener todos los nodos del grafo
	local allNodes = {}
	local visited = {}

	local function gatherNodes(node)
		if visited[node.Name] then return end
		visited[node.Name] = true
		table.insert(allNodes, node)
		distances[node.Name] = math.huge
		table.insert(unvisited, node)

		local neighbors = GraphUtils.getNeighbors(node, cables)
		for _, neighbor in pairs(neighbors) do
			if not visited[neighbor.Name] then
				gatherNodes(neighbor)
			end
		end
	end

	gatherNodes(startNode)
	distances[startNode.Name] = 0

	-- Dijkstra
	while #unvisited > 0 do
		-- Encontrar nodo no visitado con menor distancia
		local minIdx = 1
		local minDist = math.huge

		for i, node in pairs(unvisited) do
			if (distances[node.Name] or math.huge) < minDist then
				minDist = distances[node.Name] or math.huge
				minIdx = i
			end
		end

		if minDist == math.huge then break end

		local current = table.remove(unvisited, minIdx)
		local neighbors = GraphUtils.getNeighbors(current, cables)

		for _, neighbor in pairs(neighbors) do
			local newDist = (distances[current.Name] or math.huge) + 1
			if newDist < (distances[neighbor.Name] or math.huge) then
				distances[neighbor.Name] = newDist
			end
		end
	end

	return distances
end

-- ============================================
-- FUNCIONES DE MATRIZ DE ADYACENCIA
-- ============================================

-- Genera la matriz de adyacencia para un grafo
function GraphUtils.getAdjacencyMatrix(nodes, cables)
	local matrix = {}
	local headers = {}

	-- Crear encabezados
	for i, node in pairs(nodes) do
		headers[i] = node.Name
	end

	-- Crear matriz
	for i = 1, #nodes do
		matrix[i] = {}
		for j = 1, #nodes do
			local connected = GraphUtils.areConnected(nodes[i], nodes[j], cables)
			matrix[i][j] = connected and 1 or 0
		end
	end

	return { headers = headers, matrix = matrix }
end

return GraphUtils