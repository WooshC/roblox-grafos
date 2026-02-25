local Algoritmos = {}

-- Función auxiliar para obtener vecinos y pesos
local function obtenerAdyacencias(nivelID)
	local LevelsConfig = require(game.ReplicatedStorage:WaitForChild("LevelsConfig"))
	local config = LevelsConfig[nivelID] or LevelsConfig[0]
	return config.Adyacencias or {}
end

-- ==========================================
-- DIJKSTRA (Visual)
-- ==========================================
function Algoritmos.DijkstraVisual(inicio, fin, nivelID)
	local adyacencias = obtenerAdyacencias(nivelID)
	local distancias = {}
	local previo = {}
	local cola = {}
	local visitados = {}

	-- Lista de pasos para la animación
	local pasos = {}

	-- Inicialización
	for nodo, _ in pairs(adyacencias) do
		distancias[nodo] = math.huge
		table.insert(cola, nodo)
	end
	-- Asegurar que inicio y fin estén en la cola
	if not distancias[inicio] then table.insert(cola, inicio); distancias[inicio] = math.huge end
	if not distancias[fin] then table.insert(cola, fin); distancias[fin] = math.huge end

	distancias[inicio] = 0

	while #cola > 0 do
		-- Encontrar nodo con menor distancia
		table.sort(cola, function(a, b) return distancias[a] < distancias[b] end)
		local u = table.remove(cola, 1)

		if distancias[u] == math.huge then break end
		if visitados[u] then continue end -- Evitar duplicados si los hubiera
		visitados[u] = true

		-- Registrar paso visual: Nodo Actual
		table.insert(pasos, {Tipo = "NodoActual", Nodo = u})

		if u == fin then
			table.insert(pasos, {Tipo = "Destino", Nodo = u})
			break 
		end

		local vecinos = adyacencias[u]
		if vecinos then
			for _, v in ipairs(vecinos) do
				if not visitados[v] then
					-- Registrar paso visual: Explorando arista
					table.insert(pasos, {Tipo = "Explorando", Nodo = v, Origen = u})

					local peso = 1 -- Peso por defecto (podría venir de config)
					local alt = distancias[u] + peso

					if alt < distancias[v] then
						distancias[v] = alt
						previo[v] = u
					end
				end
			end
		end
	end

	-- Reconstruir camino
	local camino = {}
	local u = fin
	if previo[u] or u == inicio then
		while u do
			table.insert(camino, 1, u)
			u = previo[u]
		end
	end

	return {
		Pasos = pasos,
		CaminoFinal = camino,
		CostoTotal = distancias[fin]
	}
end

-- ==========================================
-- BFS (Visual) - Breadth First Search
-- ==========================================
function Algoritmos.BFSVisual(inicio, fin, nivelID)
	local adyacencias = obtenerAdyacencias(nivelID)
	local cola = {inicio}
	local visitados = {[inicio] = true}
	local previo = {}

	local pasos = {}

	while #cola > 0 do
		local u = table.remove(cola, 1)

		-- Registrar paso visual: Nodo Actual
		table.insert(pasos, {Tipo = "NodoActual", Nodo = u})

		if u == fin then
			table.insert(pasos, {Tipo = "Destino", Nodo = u})
			break
		end

		local vecinos = adyacencias[u]
		if vecinos then
			for _, v in ipairs(vecinos) do
				if not visitados[v] then
					visitados[v] = true
					previo[v] = u
					table.insert(cola, v)

					-- Registrar paso visual: Explorando
					table.insert(pasos, {Tipo = "Explorando", Nodo = v, Origen = u})
				end
			end
		end
	end

	-- Reconstruir camino y calcular distancia física real
	local camino = {}
	local u = fin
	if previo[u] or u == inicio then
		while u do
			table.insert(camino, 1, u)
			u = previo[u]
		end
	end

	-- Calcular distancia física total del camino
	local distanciaTotal = 0
	local function getPos(nombre)
		-- Búsqueda simplificada de posición (asume estructura estándar)
		local nivelName = (nivelID == 0) and "Nivel0_Tutorial" or ("Nivel" .. nivelID)
		local modelo = workspace:FindFirstChild(nivelName)
		local postes = modelo and modelo:FindFirstChild("Objetos") and modelo.Objetos:FindFirstChild("Postes")
		local obj = postes and postes:FindFirstChild(nombre)
		if obj then
			if obj:IsA("Model") and obj.PrimaryPart then return obj.PrimaryPart.Position end
			if obj:IsA("Model") then return obj:GetPivot().Position end
		end
		return Vector3.new(0,0,0)
	end

	for i = 1, #camino - 1 do
		local p1 = getPos(camino[i])
		local p2 = getPos(camino[i+1])
		distanciaTotal = distanciaTotal + (p1 - p2).Magnitude
	end

	local distanciaMetros = math.floor(distanciaTotal / 4) -- Conversión 4 studs = 1m

	return {
		Pasos = pasos,
		CaminoFinal = camino,
		CostoTotal = #camino - 1, -- Costo lógico BFS (Saltos)
		DistanciaTotal = distanciaMetros -- Costo físico (Metros)
	}
end

return Algoritmos
