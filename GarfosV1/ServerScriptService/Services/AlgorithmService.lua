-- ServerScriptService/Services/AlgorithmService.lua
-- SERVICIO CENTRALIZADO para ejecución y visualización de algoritmos
-- Maneja Dijkstra, BFS, DFS con animación y pasos visuales

local AlgorithmService = {}
AlgorithmService.__index = AlgorithmService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Algoritmos = require(ReplicatedStorage:WaitForChild("Algoritmos"))
local GraphUtils = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"):WaitForChild("GraphUtils"))
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums"))

-- Estado interno
local graphService = nil
local levelService = nil
local currentAlgorithm = nil
local algorithmSteps = {}

-- Eventos
local algorithmStartedEvent = Instance.new("BindableEvent")
local algorithmStepEvent = Instance.new("BindableEvent")
local algorithmCompletedEvent = Instance.new("BindableEvent")

-- ============================================
-- INICIALIZACIÓN
-- ============================================

function AlgorithmService:setGraphService(graph)
	graphService = graph
end

function AlgorithmService:setLevelService(level)
	levelService = level
end

-- ============================================
-- EJECUCIÓN DE ALGORITMOS
-- ============================================

-- Ejecuta Dijkstra con visualización paso a paso
function AlgorithmService:executeDijkstra(startNode, endNode)
	if not graphService or not startNode or not endNode then
		warn("❌ AlgorithmService: Datos insuficientes para ejecutar Dijkstra")
		return nil
	end

	print("🚀 AlgorithmService: Ejecutando Dijkstra de " .. startNode.Name .. " a " .. endNode.Name)

	algorithmStartedEvent:Fire("DIJKSTRA", startNode, endNode)
	currentAlgorithm = "DIJKSTRA"

	-- Usar módulo Algoritmos existente
	local resultado = Algoritmos.DijkstraVisual(startNode.Name, endNode.Name, levelService:getCurrentLevelID())

	if resultado then
		algorithmSteps = resultado.Pasos

		-- Emitir pasos
		for _, paso in ipairs(algorithmSteps) do
			algorithmStepEvent:Fire(paso)
			task.wait(0.3)  -- Delay para visualización
		end

		algorithmCompletedEvent:Fire("DIJKSTRA", resultado.CaminoFinal, resultado.CostoTotal)

		print("✅ AlgorithmService: Dijkstra completado")
		print("   Camino: " .. table.concat(resultado.CaminoFinal, " → "))
		print("   Costo: " .. resultado.CostoTotal)

		return resultado
	end

	return nil
end

-- Ejecuta BFS con visualización paso a paso
function AlgorithmService:executeBFS(startNode, endNode)
	if not graphService or not startNode or not endNode then
		warn("❌ AlgorithmService: Datos insuficientes para ejecutar BFS")
		return nil
	end

	print("🚀 AlgorithmService: Ejecutando BFS de " .. startNode.Name .. " a " .. endNode.Name)

	algorithmStartedEvent:Fire("BFS", startNode, endNode)
	currentAlgorithm = "BFS"

	local resultado = Algoritmos.BFSVisual(startNode.Name, endNode.Name, levelService:getCurrentLevelID())

	if resultado then
		algorithmSteps = resultado.Pasos

		-- Emitir pasos
		for _, paso in ipairs(algorithmSteps) do
			algorithmStepEvent:Fire(paso)
			task.wait(0.3)
		end

		algorithmCompletedEvent:Fire("BFS", resultado.CaminoFinal, resultado.CostoTotal)

		print("✅ AlgorithmService: BFS completado")
		print("   Camino: " .. table.concat(resultado.CaminoFinal, " → "))
		print("   Saltos: " .. resultado.CostoTotal)

		return resultado
	end

	return nil
end

-- Ejecuta DFS con visualización
function AlgorithmService:executeDFS(startNode, endNode)
	if not graphService or not startNode or not endNode then
		warn("❌ AlgorithmService: Datos insuficientes para ejecutar DFS")
		return nil
	end

	print("🚀 AlgorithmService: Ejecutando DFS de " .. startNode.Name .. " a " .. endNode.Name)

	algorithmStartedEvent:Fire("DFS", startNode, endNode)
	currentAlgorithm = "DFS"

	-- DFS genérico de GraphUtils
	local cables = graphService:getCables()
	local visited = GraphUtils.dfs(startNode, cables)

	if visited[endNode.Name] then
		algorithmCompletedEvent:Fire("DFS", {startNode.Name, endNode.Name}, #visited)
		print("✅ AlgorithmService: DFS completado - Nodo alcanzable")
		return { 
			Visitados = visited,
			Alcanzable = true 
		}
	else
		print("❌ AlgorithmService: DFS completado - Nodo NO alcanzable")
		return {
			Visitados = visited,
			Alcanzable = false
		}
	end
end

-- ============================================
-- VALIDACIÓN Y ANÁLISIS
-- ============================================

-- Valida si una ruta es correcta según el algoritmo seleccionado
function AlgorithmService:validatePath(nodoInicio, nodoFin, algoritmo)
	local cables = graphService:getCables()

	if algoritmo == "DIJKSTRA" then
		local distancias = GraphUtils.dijkstra(nodoInicio, cables)
		return distancias[nodoFin.Name] and distancias[nodoFin.Name] < math.huge
	elseif algoritmo == "BFS" then
		local alcanzables = GraphUtils.bfs(nodoInicio, cables)
		return alcanzables[nodoFin.Name] == true
	elseif algoritmo == "DFS" then
		local alcanzables = GraphUtils.dfs(nodoInicio, cables)
		return alcanzables[nodoFin.Name] == true
	end

	return false
end

-- Obtiene la ruta óptima según algoritmo
function AlgorithmService:getOptimalPath(startNode, endNode, algoritmo)
	if not startNode or not endNode then return nil end

	if algoritmo == Enums.Algorithms.DIJKSTRA then
		local distancias = GraphUtils.dijkstra(startNode, graphService:getCables())
		-- Reconstruir ruta desde distancias
		return self:reconstructPath(startNode, endNode, distancias)
	elseif algoritmo == Enums.Algorithms.BFS then
		local alcanzables = GraphUtils.bfs(startNode, graphService:getCables())
		if alcanzables[endNode.Name] then
			return {startNode.Name, endNode.Name}
		end
	end

	return nil
end

-- Reconstruye la ruta desde el resultado de Dijkstra
function AlgorithmService:reconstructPath(startNode, endNode, distancias)
	-- Implementación simplificada
	if distancias[endNode.Name] and distancias[endNode.Name] < math.huge then
		return {startNode.Name, endNode.Name}
	end
	return nil
end

-- Obtiene la distancia total de una ruta
function AlgorithmService:calculateRouteCost(path, algorithm)
	if not path or #path < 2 then return 0 end

	local totalCost = 0

	if algorithm == Enums.Algorithms.DIJKSTRA then
		-- Costo en metros (o studs)
		for i = 1, #path - 1 do
			local nodeA = levelService:getPoste(path[i])
			local nodeB = levelService:getPoste(path[i + 1])
			if nodeA and nodeB then
				totalCost = totalCost + GraphUtils.getDistance(nodeA, nodeB)
			end
		end
		-- Convertir a metros (4 studs = 1 metro)
		return math.floor(totalCost / 4)
	else
		-- Costo en saltos
		return #path - 1
	end
end

-- Calcula el costo de dinero para un cable
function AlgorithmService:calculateCableCost(nodoA, nodoB)
	if not levelService or not nodoA or not nodoB then return 0 end

	local distancia = GraphUtils.getDistance(nodoA, nodoB)
	local costoPorMetro = levelService:getCostPerMeter()
	local distanciaMetros = math.floor(distancia / 4)  -- 4 studs = 1 metro

	return distanciaMetros * costoPorMetro
end

-- ============================================
-- ANÁLISIS DE GRAFO
-- ============================================

-- Encuentra el camino más corto en términos de dinero
function AlgorithmService:findCheapestPath(startNode, endNode)
	if not startNode or not endNode then return nil end

	local cables = graphService:getCables()
	local distancias = GraphUtils.dijkstra(startNode, cables)

	if distancias[endNode.Name] and distancias[endNode.Name] < math.huge then
		return {
			camino = {startNode.Name, endNode.Name},
			costoDinero = self:calculateCableCost(startNode, endNode),
			distancia = GraphUtils.getDistance(startNode, endNode)
		}
	end

	return nil
end

-- Encuentra nodos alcanzables desde un nodo dado
function AlgorithmService:getReachableNodes(startNode)
	if not startNode or not graphService then return {} end

	local cables = graphService:getCables()
	local alcanzables = GraphUtils.bfs(startNode, cables)

	local resultado = {}
	for nodeName, _ in pairs(alcanzables) do
		table.insert(resultado, nodeName)
	end

	return resultado
end

-- Identifica nodos aislados (sin conexiones)
function AlgorithmService:findIsolatedNodes()
	if not graphService or not levelService then return {} end

	local aislados = {}
	local nodos = graphService:getNodes()
	local cables = graphService:getCables()

	for _, nodo in pairs(nodos) do
		if not GraphUtils.hasConnections(nodo, cables) then
			table.insert(aislados, nodo.Name)
		end
	end

	return aislados
end

-- ============================================
-- RECOMENDACIONES Y SUGERENCIAS
-- ============================================

-- Sugiere el algoritmo más apropiado para el nivel
function AlgorithmService:recommendAlgorithm()
	if not levelService then return "BFS" end

	local config = levelService:getLevelConfig()
	if config and config.Algoritmo then
		return config.Algoritmo
	end

	return "BFS"  -- Default
end

-- Sugiere pasos para completar el nivel
function AlgorithmService:suggestNextSteps()
	if not levelService or not graphService then return {} end

	local startNode = levelService:getStartNode()
	local endNode = levelService:getEndNode()

	if not startNode or not endNode then return {} end

	local aislados = self:findIsolatedNodes()
	local recomendaciones = {}

	if #aislados > 0 then
		table.insert(recomendaciones, "Conecta los nodos aislados: " .. table.concat(aislados, ", "))
	end

	if not self:validatePath(startNode, endNode, "BFS") then
		table.insert(recomendaciones, "Necesitas conectar una ruta desde " .. startNode.Name .. " a " .. endNode.Name)
	end

	return recomendaciones
end

-- ============================================
-- EVENTOS
-- ============================================

function AlgorithmService:onAlgorithmStarted(callback)
	algorithmStartedEvent.Event:Connect(callback)
end

function AlgorithmService:onAlgorithmStep(callback)
	algorithmStepEvent.Event:Connect(callback)
end

function AlgorithmService:onAlgorithmCompleted(callback)
	algorithmCompletedEvent.Event:Connect(callback)
end

-- ============================================
-- DEBUG
-- ============================================

function AlgorithmService:debug()
	if not levelService then
		print("❌ AlgorithmService:debug() - LevelService no inicializado")
		return
	end

	print("\n📊 ===== DEBUG AlgorithmService =====")

	local startNode = levelService:getStartNode()
	if startNode then
		print("Nodo inicio: " .. startNode.Name)
		local alcanzables = self:getReachableNodes(startNode)
		print("Nodos alcanzables desde inicio: " .. #alcanzables)

		local endNode = levelService:getEndNode()
		if endNode then
			local bfsValid = self:validatePath(startNode, endNode, "BFS")
			print("¿Objetivo alcanzable (BFS)?: " .. (bfsValid and "✅ SÍ" or "❌ NO"))
		end
	end

	local aislados = self:findIsolatedNodes()
	if #aislados > 0 then
		print("\nNodos aislados:")
		for _, nodo in pairs(aislados) do
			print("   • " .. nodo)
		end
	else
		print("\nTodos los nodos están conectados")
	end

	print("===== Fin DEBUG =====\n")
end

return AlgorithmService