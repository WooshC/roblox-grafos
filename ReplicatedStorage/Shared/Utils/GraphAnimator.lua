-- ReplicatedStorage/Shared/Utils/GraphAnimator.lua
-- Módulo dedicado EXCLUSIVAMENTE a generar los pasos de animación para visualización
-- Separa la lógica matemática (GraphUtils) de la lógica visual (GraphAnimator)

local GraphAnimator = {}

-- ==========================================
-- DIJKSTRA (Visual)
-- ==========================================
-- Genera una secuencia de pasos para animar el algoritmo de Dijkstra
-- @param inicio: string (nombre del nodo inicial)
-- @param fin: string (nombre del nodo final)
-- @param adyacencias: table (mapa de conexiones { ["NodoA"] = {"NodoB", "NodoC"} })
-- @return: table { Pasos, CaminoFinal, CostoTotal }
function GraphAnimator.DijkstraVisual(inicio, fin, adyacencias)
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
	
	-- Asegurar que inicio y fin estén en la cola y tabla
	if not distancias[inicio] then 
		table.insert(cola, inicio)
		distancias[inicio] = math.huge 
	end
	if not distancias[fin] then 
		table.insert(cola, fin)
		distancias[fin] = math.huge 
	end
	
	distancias[inicio] = 0
	
	while #cola > 0 do
		-- Encontrar nodo con menor distancia
		table.sort(cola, function(a, b) return distancias[a] < distancias[b] end)
		local u = table.remove(cola, 1)
		
		if distancias[u] == math.huge then break end
		if visitados[u] then continue end 
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
-- Genera una secuencia de pasos para animar BFS
-- @param inicio: string (nombre del nodo inicial)
-- @param fin: string (nombre del nodo final)
-- @param adyacencias: table (mapa de conexiones)
-- @return: table { Pasos, CaminoFinal, CostoTotal }
function GraphAnimator.BFSVisual(inicio, fin, adyacencias)
	local cola = {inicio}
	local visitados = {[inicio] = true} -- Marca como visitado al encolar
	local previo = {}
	
	local pasos = {}
	
	while #cola > 0 do
		local u = table.remove(cola, 1)
		
		-- Registrar paso visual: Nodo Actual (Visitando)
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
					
					-- Registrar paso visual: Explorando (Descubriendo)
					table.insert(pasos, {Tipo = "Explorando", Nodo = v, Origen = u})
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
	
	-- Calcular métricas simples para evitar dependencias
	return {
		Pasos = pasos,
		CaminoFinal = camino,
		CostoTotal = #camino - 1
	}
end

return GraphAnimator
