-- ServerScriptService/Gameplay/GraphTheoryService.server.lua
-- SERVICIO DE TEORÍA DE GRAFOS (REFACTORIZADO)
-- Expone datos del grafo (Matriz de Adyacencia) al cliente para visualización UI

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Esperar inicialización de servicios
repeat task.wait(0.1) until _G.Services

local GraphService = _G.Services.Graph
local GraphUtils = _G.Services.GraphUtils

local eventsFolder = ReplicatedStorage:WaitForChild("Events")
local remotesFolder = eventsFolder:WaitForChild("Remotes")

-- Crear/Obtener RemoteFunction
local getMatrixFunc = remotesFolder:FindFirstChild("GetAdjacencyMatrix")
if not getMatrixFunc then
	getMatrixFunc = Instance.new("RemoteFunction")
	getMatrixFunc.Name = "GetAdjacencyMatrix"
	getMatrixFunc.Parent = remotesFolder
end

-- Función principal invocada por cliente
local function getAdjacencyMatrix(player)
	if not GraphService or not GraphUtils then
		warn("❌ GraphTheoryService: Servicios no disponibles")
		return {Headers={}, Matrix={}}
	end
	
	-- 1. Obtener Nodos (Postes)
	local nodes = GraphService:getNodes()
	
	-- Clonar y ordenar alfabéticamente para consistencia visual en la matriz
	local sortedNodes = {}
	for _, node in ipairs(nodes) do
		table.insert(sortedNodes, node)
	end
	table.sort(sortedNodes, function(a, b) return a.Name < b.Name end)
	
	-- 2. Construir Matriz
	local headers = {}
	local matrix = {}
	local n = #sortedNodes
	
	-- Obtener cables actuales
	local cables = GraphService:getCables()
	
	for i = 1, n do
		headers[i] = sortedNodes[i].Name
		matrix[i] = {}
		
		for j = 1, n do
			local nodeA = sortedNodes[i]
			local nodeB = sortedNodes[j]
			
			if i == j then
				matrix[i][j] = 0
			else
				-- Verificar conexión usando GraphUtils/Service
				if GraphUtils.areConnected(nodeA, nodeB, cables) then
					-- Calcular peso (distancia en metros)
					-- Asumimos 4 studs = 1 metro como en el resto del juego
					local distStuds = GraphUtils.getDistance(nodeA, nodeB)
					matrix[i][j] = math.floor(distStuds / 4)
				else
					matrix[i][j] = 0
				end
			end
		end
	end
	
	print("📊 GraphTheoryService: Matriz enviada a " .. player.Name)
	
	return {
		Headers = headers,
		Matrix = matrix
	}
end

getMatrixFunc.OnServerInvoke = getAdjacencyMatrix

print("✅ GraphTheoryService (Refactorizado) cargado")
