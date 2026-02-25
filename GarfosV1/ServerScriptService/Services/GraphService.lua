-- ServerScriptService/Services/GraphService.lua
-- SERVICIO CENTRALIZADO para gestión de cables y conexiones
-- Todos los cambios en la estructura del grafo pasan por aquí

local GraphService = {}
GraphService.__index = GraphService

local GraphUtils = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Utils"):WaitForChild("GraphUtils"))
local Enums = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Enums"))

-- ============================================
-- ESTADO INTERNO
-- ============================================

local nodes = {}           -- Array de todos los nodos (Postes)
local cables = {}          -- Tabla { "NodoA_NodoB" = { nodeA, nodeB, cable } }
local levelFolder = nil    -- Referencia al nivel actual

-- Eventos para comunicar cambios
local connectionChangedEvent = Instance.new("BindableEvent")
local cableAddedEvent = Instance.new("BindableEvent")
local cableRemovedEvent = Instance.new("BindableEvent")

-- ============================================
-- INICIALIZACIÓN
-- ============================================

function GraphService:init(level)
	levelFolder = level
	self:loadNodes()
	print("✅ GraphService inicializado con " .. #nodes .. " nodos")
end

-- ============================================
-- CARGA DE NODOS
-- ============================================

function GraphService:loadNodes()
	nodes = {}
	cables = {}

	if not levelFolder then
		warn("❌ GraphService: No hay nivel cargado")
		return
	end

	local postesFolder = GraphUtils.getPostesFolder(levelFolder)
	if not postesFolder then
		warn("❌ GraphService: No se encontró carpeta 'Postes'")
		return
	end

	for _, poste in pairs(postesFolder:GetChildren()) do
		if poste:IsA("Model") or poste:IsA("BasePart") then
			table.insert(nodes, poste)
		end
	end

	print("✅ GraphService cargó " .. #nodes .. " nodos")
end

-- ============================================
-- GESTIÓN DE CABLES
-- ============================================

-- CONECTA DOS NODOS
-- Si ya existen conectados, no hace nada
function GraphService:connectNodes(nodeA, nodeB, cableInstance)
	if not nodeA or not nodeB then return false end

	local key = GraphUtils.getCableKey(nodeA, nodeB)

	-- Si ya está conectado, ignorar
	if cables[key] then
		print("⚠️ GraphService: Cable ya existe entre " .. nodeA.Name .. " y " .. nodeB.Name)
		return false
	end

	-- Guardar conexión
	cables[key] = {
		nodeA = nodeA,
		nodeB = nodeB,
		cableInstance = cableInstance  -- Referencia al RopeConstraint o visualización
	}

	-- Emitir eventos
	connectionChangedEvent:Fire("connected", nodeA, nodeB)
	cableAddedEvent:Fire(nodeA, nodeB, cableInstance)

	print("🔗 GraphService: Conectado " .. key)
	return true
end

-- DESCONECTA DOS NODOS
function GraphService:disconnectNodes(nodeA, nodeB)
	if not nodeA or not nodeB then return false end

	local key = GraphUtils.getCableKey(nodeA, nodeB)

	if not cables[key] then
		print("⚠️ GraphService: Cable no existe entre " .. nodeA.Name .. " y " .. nodeB.Name)
		return false
	end

	local cableInfo = cables[key]
	cables[key] = nil

	-- Emitir eventos
	connectionChangedEvent:Fire("disconnected", nodeA, nodeB)
	cableRemovedEvent:Fire(nodeA, nodeB, cableInfo.cableInstance)

	print("✂️ GraphService: Desconectado " .. key)
	return true
end

-- ============================================
-- CONSULTAS DE CONEXIÓN
-- ============================================

-- Obtiene todos los cables
function GraphService:getCables()
	return cables
end

-- Obtiene todos los nodos
function GraphService:getNodes()
	return nodes
end

-- Valida si dos nodos están conectados
function GraphService:areConnected(nodeA, nodeB)
	return GraphUtils.areConnected(nodeA, nodeB, cables)
end

-- Obtiene los vecinos de un nodo
function GraphService:getNeighbors(node)
	return GraphUtils.getNeighbors(node, cables)
end

-- Valida si un nodo tiene al menos una conexión
function GraphService:hasConnections(node)
	return GraphUtils.hasConnections(node, cables)
end

-- Obtiene la cantidad de conexiones de un nodo
function GraphService:getConnectionCount(node)
	local count = 0
	for key, cable in pairs(cables) do
		if cable.nodeA == node or cable.nodeB == node then
			count = count + 1
		end
	end
	return count
end

-- ============================================
-- ALGORITMOS DE BÚSQUEDA
-- ============================================

-- BFS desde un nodo inicial (retorna nodos alcanzables)
function GraphService:getReachableNodes(startNode)
	return GraphUtils.bfs(startNode, cables)
end

-- DFS desde un nodo inicial
function GraphService:dfsTraversal(startNode)
	return GraphUtils.dfs(startNode, cables)
end

-- Dijkstra (distancia mínima)
function GraphService:getDistances(startNode)
	return GraphUtils.dijkstra(startNode, cables)
end

-- ============================================
-- MATRIZ DE ADYACENCIA
-- ============================================

-- Obtiene la matriz de adyacencia del grafo actual
function GraphService:getAdjacencyMatrix()
	return GraphUtils.getAdjacencyMatrix(nodes, cables)
end

-- ============================================
-- EVENTOS
-- ============================================

-- Se ejecuta CADA VEZ que hay un cambio en conexiones
function GraphService:onConnectionChanged(callback)
	connectionChangedEvent.Event:Connect(callback)
end

-- Se ejecuta cuando se AGREGA un cable
function GraphService:onCableAdded(callback)
	cableAddedEvent.Event:Connect(callback)
end

-- Se ejecuta cuando se REMUEVE un cable
function GraphService:onCableRemoved(callback)
	cableRemovedEvent.Event:Connect(callback)
end

-- ============================================
-- LIMPIEZA
-- ============================================

-- Limpia TODOS los cables (al resetear nivel)
function GraphService:clearAllCables()
	print("🗑️ GraphService: Limpiando todos los cables...")

	for key, cableInfo in pairs(cables) do
		cableRemovedEvent:Fire(cableInfo.nodeA, cableInfo.nodeB, cableInfo.cableInstance)
	end

	cables = {}
	print("✅ GraphService: Cables limpiados")
end

-- Reinicializa el servicio (al cambiar de nivel)
function GraphService:reset(newLevel)
	self:clearAllCables()
	self:init(newLevel)
end

return GraphService