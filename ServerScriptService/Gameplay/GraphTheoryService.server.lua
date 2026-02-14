-- ServerScriptService/Gameplay/GraphTheoryService.server.lua
-- SERVICIO DE TEORÍA DE GRAFOS (REFACTORIZADO + CORREGIDO)
-- Expone datos del grafo (Matriz de Adyacencia) al cliente para visualización UI

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Esperar inicialización de servicios
task.wait(1)

local GraphService = _G.Services.Graph
local GraphUtils = _G.Services.GraphUtils
local LevelService = _G.Services.Level

local eventsFolder = ReplicatedStorage:WaitForChild("Events")
local remotesFolder = eventsFolder:WaitForChild("Remotes")

-- Crear/Obtener RemoteFunction
local getMatrixFunc = remotesFolder:FindFirstChild("GetAdjacencyMatrix")
if not getMatrixFunc then
	getMatrixFunc = Instance.new("RemoteFunction")
	getMatrixFunc.Name = "GetAdjacencyMatrix"
	getMatrixFunc.Parent = remotesFolder
	print("✅ GraphTheoryService: RemoteFunction creada")
end

-- 🔥 FUNCIÓN HELPER: Calcular distancia entre dos nodos
local function calcularDistancia(nodeA, nodeB)
	if not nodeA or not nodeB then return 0 end
	
	-- Obtener posiciones
	local posA, posB
	
	if nodeA:IsA("Model") then
		posA = nodeA.PrimaryPart and nodeA.PrimaryPart.Position or nodeA:GetPivot().Position
	else
		posA = nodeA.Position
	end
	
	if nodeB:IsA("Model") then
		posB = nodeB.PrimaryPart and nodeB.PrimaryPart.Position or nodeB:GetPivot().Position
	else
		posB = nodeB.Position
	end
	
	return (posA - posB).Magnitude
end

-- Función principal invocada por cliente
local function getAdjacencyMatrix(player)
	print("📊 GraphTheoryService: Petición de matriz de " .. player.Name)
	
	if not GraphService or not GraphUtils or not LevelService then
		warn("❌ GraphTheoryService: Servicios no disponibles")
		return {Headers={}, Matrix={}}
	end
	
	-- Verificar que hay nivel cargado
	if not LevelService:isLevelLoaded() then
		warn("❌ GraphTheoryService: No hay nivel cargado")
		return {Headers={}, Matrix={}}
	end
	
	-- 1. Obtener Nodos (Postes)
	local nodes = GraphService:getNodes()
	
	if #nodes == 0 then
		warn("❌ GraphTheoryService: No hay nodos en el nivel")
		return {Headers={}, Matrix={}}
	end
	
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
					-- 🔥 CORREGIDO: Calcular peso (distancia en metros) usando función helper
					local distStuds = calcularDistancia(nodeA, nodeB)
					matrix[i][j] = math.floor(distStuds / 4) -- 4 studs = 1 metro
				else
					matrix[i][j] = 0
				end
			end
		end
	end
	
	print("📊 GraphTheoryService: Matriz enviada a " .. player.Name)
	print("   Nodos: " .. #headers)
	print("   Conexiones detectadas: " .. (function()
		local count = 0
		for i = 1, n do
			for j = 1, n do
				if matrix[i][j] > 0 then count = count + 1 end
			end
		end
		return count
	end)())
	
	return {
		Headers = headers,
		Matrix = matrix
	}
end

getMatrixFunc.OnServerInvoke = getAdjacencyMatrix

print("✅ GraphTheoryService (Refactorizado + Corregido) cargado")