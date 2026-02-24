-- ServerScriptService/Gameplay/GraphTheoryService.server.lua
-- SERVICIO DE TEORÍA DE GRAFOS (REFACTORIZADO + CORREGIDO)
-- Expone datos del grafo (Matriz de Adyacencia) al cliente para visualización UI

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- P0-2: Esperar señal de ServicesReady en lugar de task.wait(1) fijo
ReplicatedStorage:WaitForChild("Events"):WaitForChild("Bindables"):WaitForChild("ServicesReady").Event:Wait()

local GraphService = _G.Services.Graph
local GraphUtils = _G.Services.GraphUtils
local LevelService = _G.Services.Level

local NivelUtils    = require(ReplicatedStorage:WaitForChild("Utilidades"):WaitForChild("NivelUtils"))
local LevelsConfig  = require(ReplicatedStorage:WaitForChild("LevelsConfig"))

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
local function getAdjacencyMatrix(player, zonaID)
	print("📊 GraphTheoryService: Petición de matriz de " .. player.Name .. (zonaID and (" (Zona: " .. zonaID .. ")") or " (Global)"))
	
	if not GraphService or not GraphUtils or not LevelService then
		warn("❌ GraphTheoryService: Servicios no disponibles")
		return {Headers={}, Matrix={}}
	end
	
	-- Verificar que hay nivel cargado
	if not LevelService:isLevelLoaded() then
		warn("❌ GraphTheoryService: No hay nivel cargado")
		return {Headers={}, Matrix={}}
	end

	local nivelID = LevelService:getCurrentLevelID()
	
	-- 1. Obtener Nodos (Postes)
	local allNodes = GraphService:getNodes()
	
	if #allNodes == 0 then
		warn("❌ GraphTheoryService: No hay nodos en el nivel")
		return {Headers={}, Matrix={}}
	end
	
	-- ============================================
	-- ROBUST NODE ZONE CHECK
	-- ============================================
	local function safeGetNodeZone(nid, nodeName)
		-- Try strict module call
		if NivelUtils and NivelUtils.getNodeZone then
			return NivelUtils.getNodeZone(nid, nodeName)
		end
		
		-- Fallback: Try to recreate logic if module is broken
		-- Logic: Get config -> Nodos -> nodeName -> Zona
		local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))
		if LevelsConfig and LevelsConfig[nid] and LevelsConfig[nid].Nodos then
			local nodeData = LevelsConfig[nid].Nodos[nodeName]
			if nodeData then 
				return nodeData.Zona
			end
		end
		
		return nil
	end
	
	-- FILTRADO POR ZONA
	local filteredNodes = {}
	if zonaID and zonaID ~= "" then
		for _, node in ipairs(allNodes) do
			local nodeZone = safeGetNodeZone(nivelID, node.Name)
			
			-- Incluir si la zona coincide
			if nodeZone == zonaID then
				table.insert(filteredNodes, node)
			end
		end
		
		-- Si no hay nodos en la zona, devolver vacío
		if #filteredNodes == 0 then
			print("⚠️ GraphTheoryService: No hay nodos en la zona " .. zonaID)
			return {Headers={}, Matrix={}}
		end
	else
		-- Sin filtro (Global)
		for _, node in ipairs(allNodes) do
			table.insert(filteredNodes, node)
		end
	end

	-- Clonar y ordenar alfabéticamente para consistencia visual en la matriz
	local sortedNodes = filteredNodes
	table.sort(sortedNodes, function(a, b) return a.Name < b.Name end)
	
	-- 2. Construir Matriz
	local headers = {}
	local matrix = {}
	local n = #sortedNodes

	-- Obtener cables actuales y adyacencias para determinar direccionalidad
	local cables     = GraphService:getCables()
	local levelCfg   = LevelsConfig[nivelID]
	local adyacencias = levelCfg and levelCfg.Adyacencias or nil

	-- Mapeo nombre -> índice
	local nameToIndex = {}
	for i, node in ipairs(sortedNodes) do
		headers[i]          = node.Name
		nameToIndex[node.Name] = i
		matrix[i] = {}
		for j = 1, n do
			matrix[i][j] = 0
		end
	end

	-- Rellenar según cables + direccionalidad definida en Adyacencias
	for _, info in pairs(cables) do
		local nA   = info.nodeA.Name
		local nB   = info.nodeB.Name
		local idxA = nameToIndex[nA]
		local idxB = nameToIndex[nB]

		if idxA and idxB and idxA ~= idxB then
			local distStuds = calcularDistancia(info.nodeA, info.nodeB)
			local peso      = math.max(1, math.floor(distStuds / 4)) -- 4 studs = 1 metro

			if adyacencias then
				local aToB = adyacencias[nA] and table.find(adyacencias[nA], nB)
				local bToA = adyacencias[nB] and table.find(adyacencias[nB], nA)

				if aToB then matrix[idxA][idxB] = peso end
				if bToA then matrix[idxB][idxA] = peso end

				-- Fallback: ninguna dirección definida → bidireccional
				if not aToB and not bToA then
					matrix[idxA][idxB] = peso
					matrix[idxB][idxA] = peso
				end
			else
				-- Sin adyacencias: tratar como no-dirigido
				matrix[idxA][idxB] = peso
				matrix[idxB][idxA] = peso
			end
		end
	end
	
	print("📊 GraphTheoryService: Matriz enviada a " .. player.Name)
	print("   Nodos: " .. #headers)
	
	return {
		Headers = headers,
		Matrix = matrix
	}
end

getMatrixFunc.OnServerInvoke = getAdjacencyMatrix

print("✅ GraphTheoryService (Refactorizado + Corregido) cargado")