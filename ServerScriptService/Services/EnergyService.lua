-- ServerScriptService/Services/EnergyService.lua
-- SERVICIO CENTRALIZADO para cálculos de energía
-- Usa BFS para determinar qué nodos están energizados

local EnergyService = {}
EnergyService.__index = EnergyService

local GraphUtils = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Utils"):WaitForChild("GraphUtils"))
local Enums = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Enums"))

-- Estado interno
local graphService = nil  -- Se inyecta desde el servidor
local energyChangedEvent = Instance.new("BindableEvent")

-- ============================================
-- INICIALIZACIÓN
-- ============================================

function EnergyService:setGraphService(graph)
	graphService = graph
end

-- ============================================
-- CÁLCULO DE ENERGÍA
-- ============================================

-- Calcula qué nodos están ENERGIZADOS desde un nodo fuente
-- Retorna tabla { "NodoA" = true, "NodoB" = true, ... }
function EnergyService:calculateEnergy(sourceNode)
	if not sourceNode or not graphService then
		return {}
	end

	-- Usa BFS del GraphUtils
	local energized = GraphUtils.bfs(sourceNode, graphService:getCables())

	print("⚡ EnergyService: Nodos energizados desde " .. sourceNode.Name .. ":")
	for nodeName, _ in pairs(energized) do
		print("   • " .. nodeName)
	end

	return energized
end

-- Calcula energía para MÚLTIPLES fuentes
-- Útil si hay múltiples postes generadores
function EnergyService:calculateMultiSourceEnergy(sourceNodes)
	if not sourceNodes or #sourceNodes == 0 then
		return {}
	end

	local energized = {}

	for _, source in pairs(sourceNodes) do
		local result = self:calculateEnergy(source)
		for nodeName, isEnergized in pairs(result) do
			energized[nodeName] = isEnergized
		end
	end

	return energized
end

-- ============================================
-- VALIDACIÓN DE SOLUCIONES
-- ============================================

-- Valida si un nodo está energizado
function EnergyService:isNodeEnergized(node, sourceNode)
	if not node or not sourceNode then return false end

	local energized = self:calculateEnergy(sourceNode)
	return energized[node.Name] or false
end

-- Valida si TODOS los nodos objetivo están energizados desde fuentes dadas
function EnergyService:areAllTargetsEnergized(targetNodes, sourceNodes)
	if not targetNodes or #targetNodes == 0 then
		return true
	end

	local energized = self:calculateMultiSourceEnergy(sourceNodes)

	for _, target in pairs(targetNodes) do
		if not energized[target.Name] then
			return false
		end
	end

	return true
end

-- Valida si el jugador ganó el nivel (todos los objetivos energizados)
function EnergyService:checkLevelCompletion(levelFolder)
	if not levelFolder then return false end

	-- Obtener nodos fuente (generadores de energía)
	local sources = {}
	local objectivos = {}

	local postes = levelFolder:FindFirstChild("Postes")
	if postes then
		for _, poste in pairs(postes:GetChildren()) do
			-- Asumir que postes con tag "Source" son generadores
			if poste:FindFirstChild("IsSource") then
				table.insert(sources, poste)
			end
			-- Asumir que postes con tag "Target" son objetivos
			if poste:FindFirstChild("IsTarget") then
				table.insert(objectivos, poste)
			end
		end
	end

	-- Si no hay objetivos, nivel incompleto
	if #objectivos == 0 then
		return false
	end

	-- Si no hay fuentes, objetivo imposible
	if #sources == 0 then
		return false
	end

	-- Validar que todos los objetivos están energizados
	return self:areAllTargetsEnergized(objectivos, sources)
end

-- ============================================
-- ANÁLISIS DE CIRCUITOS
-- ============================================

-- Obtiene el "costo" en términos de cables para alcanzar cada nodo
-- Retorna tabla { "NodoA" = 2, "NodoB" = 4, ... } (número de cables)
function EnergyService:getEnergyCost(sourceNode)
	if not sourceNode or not graphService then
		return {}
	end

	return GraphUtils.dijkstra(sourceNode, graphService:getCables())
end

-- Identifica postes "críticos" (si los quitas, se desconectan otros nodos)
function EnergyService:findCriticalNodes(sourceNode)
	if not sourceNode or not graphService then
		return {}
	end

	local critical = {}
	local cables = graphService:getCables()
	local nodes = graphService:getNodes()

	-- Para cada nodo, verificar si es crítico
	for _, node in pairs(nodes) do
		if node ~= sourceNode then
			-- Simular remover el nodo
			local tempCables = {}
			for key, cable in pairs(cables) do
				-- Si el cable NO usa este nodo, lo guardamos
				if cable.nodeA ~= node and cable.nodeB ~= node then
					tempCables[key] = cable
				end
			end

			-- Verificar si el grafo se desconecta
			local visitedWithout = GraphUtils.bfs(sourceNode, tempCables)
			local visitedWith = GraphUtils.bfs(sourceNode, cables)

			if #visitedWithout < #visitedWith then
				table.insert(critical, node)
			end
		end
	end

	print("🔴 EnergyService: Nodos críticos detectados:")
	for _, node in pairs(critical) do
		print("   • " .. node.Name)
	end

	return critical
end

-- ============================================
-- EVENTOS
-- ============================================

-- Se ejecuta cuando hay cambio en energía
function EnergyService:onEnergyChanged(callback)
	energyChangedEvent.Event:Connect(callback)
end

-- Emite evento de cambio de energía
function EnergyService:emitEnergyChanged(sourceNode, energized)
	energyChangedEvent:Fire(sourceNode, energized)
end

-- ============================================
-- DEBUG
-- ============================================

-- Imprime información del estado energético actual
function EnergyService:debug(sourceNode)
	if not sourceNode then
		print("❌ EnergyService:debug() - No hay nodo fuente")
		return
	end

	print("\n📊 ===== DEBUG EnergyService =====")
	print("Fuente: " .. sourceNode.Name)

	local energized = self:calculateEnergy(sourceNode)
	print("Total nodos energizados: " .. #energized)

	local cost = self:getEnergyCost(sourceNode)
	print("\nCostos por nodo:")
	for nodeName, distance in pairs(cost) do
		print("   " .. nodeName .. " = " .. distance)
	end

	local critical = self:findCriticalNodes(sourceNode)
	print("\nNodos críticos: " .. #critical)

	print("===== Fin DEBUG =====\n")
end

return EnergyService