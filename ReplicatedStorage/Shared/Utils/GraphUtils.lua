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
	
	-- Intento 1 (Directo)
	local p = levelFolder:FindFirstChild("Postes")
	if p then return p end
	
	-- Intento 2 (Dentro de Objetos - Estructura estándar actual)
	local objetos = levelFolder:FindFirstChild("Objetos")
	if objetos then
		return objetos:FindFirstChild("Postes")
	end
	
	return nil
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
-- ALGORITMOS DE GRAFOS
-- ============================================

-- Verifica si dos nodos están conectados (usando tabla de cables)
function GraphUtils.areConnected(nodeA, nodeB, cablesTable)
	local key = GraphUtils.getCableKey(nodeA, nodeB)
	return cablesTable[key] ~= nil
end

-- Obtiene los vecinos de un nodo
function GraphUtils.getNeighbors(node, cablesTable)
	local neighbors = {}
	for key, data in pairs(cablesTable) do
		if data.nodeA == node then
			table.insert(neighbors, data.nodeB)
		elseif data.nodeB == node then
			table.insert(neighbors, data.nodeA)
		end
	end
	return neighbors
end

-- Verifica si un nodo tiene conexiones
function GraphUtils.hasConnections(node, cablesTable)
	for key, data in pairs(cablesTable) do
		if data.nodeA == node or data.nodeB == node then
			return true
		end
	end
	return false
end

-- ============================================
-- ALGORITMOS DE BÚSQUEDA (BFS / DFS / Dijkstra)
-- ============================================

-- BFS: Búsqueda en Anchura
-- Retorna: { [nombreNodo] = true } (nodos alcanzables)
function GraphUtils.bfs(startNode, cablesTable)
	local visited = {}
	local queue = {startNode}
	visited[startNode.Name] = true

	while #queue > 0 do
		local current = table.remove(queue, 1)
		
		local neighbors = GraphUtils.getNeighbors(current, cablesTable)
		for _, neighbor in ipairs(neighbors) do
			if not visited[neighbor.Name] then
				visited[neighbor.Name] = true
				table.insert(queue, neighbor)
			end
		end
	end

	return visited
end

-- DFS: Búsqueda en Profundidad
-- Retorna: { [nombreNodo] = true }
function GraphUtils.dfs(startNode, cablesTable, visited)
	visited = visited or {}
	visited[startNode.Name] = true

	local neighbors = GraphUtils.getNeighbors(startNode, cablesTable)
	for _, neighbor in ipairs(neighbors) do
		if not visited[neighbor.Name] then
			GraphUtils.dfs(neighbor, cablesTable, visited)
		end
	end

	return visited
end

-- Dijkstra: Distancia más corta
-- Retorna: { [nombreNodo] = distancia }
function GraphUtils.dijkstra(startNode, cablesTable)
	local distances = {}
	local unvisited = {}

	-- Inicializar
	-- (Nota: Necesitamos la lista de todos los nodos para inicializar distancias a infinito
	--  pero aquí simplificamos asumiendo que solo visitamos lo alcanzable)
	
	distances[startNode.Name] = 0
	local queue = {{node = startNode, dist = 0}}

	-- Usar una cola de prioridad simple
	while #queue > 0 do
		-- Ordenar por distancia (ineficiente para grafos grandes, pero ok aquí)
		table.sort(queue, function(a, b) return a.dist < b.dist end)
		local current = table.remove(queue, 1)
		local u = current.node
		local d = current.dist

		if d > (distances[u.Name] or math.huge) then
			continue
		end

		local neighbors = GraphUtils.getNeighbors(u, cablesTable)
		for _, v in ipairs(neighbors) do
			-- Peso = 1 por defecto (o leer atributo Peso)
			local weight = 1 
			-- Podríamos leer weight de la conexión si existiera
			
			if (distances[u.Name] + weight) < (distances[v.Name] or math.huge) then
				distances[v.Name] = distances[u.Name] + weight
				table.insert(queue, {node = v, dist = distances[v.Name]})
			end
		end
	end

	return distances
end


-- ============================================
-- MATRIZ DE ADYACENCIA
-- ============================================

function GraphUtils.getAdjacencyMatrix(nodesList, cablesTable)
	local matrix = {}
	local size = #nodesList

	-- Inicializar matriz vacía
	for i = 1, size do
		matrix[i] = {}
		for j = 1, size do
			matrix[i][j] = 0
		end
	end

	-- Llenar conexiones
	for i, nodeA in ipairs(nodesList) do
		for j, nodeB in ipairs(nodesList) do
			if GraphUtils.areConnected(nodeA, nodeB, cablesTable) then
				matrix[i][j] = 1
			end
		end
	end

	return matrix
end

return GraphUtils