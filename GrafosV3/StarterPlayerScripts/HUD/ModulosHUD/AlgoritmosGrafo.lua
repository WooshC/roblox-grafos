-- StarterPlayerScripts/HUD/ModulosHUD/AlgoritmosGrafo.lua
-- Generadores de pasos para BFS, DFS, Dijkstra y Prim.
-- Módulo puro: sin dependencias de GUI ni servicios de Roblox.
--
-- Uso:
--   local steps = AlgoritmosGrafo.bfs(nodos, adyacencias, inicio)
--   -- steps[i] = { nodoActual, visitados, pendientes, distancias,
--   --              descripcion, lineaPseudo, struct, structConten }

local AlgoritmosGrafo = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- PSEUDOCÓDIGOS
-- ═══════════════════════════════════════════════════════════════════════════════

AlgoritmosGrafo.PSEUDOCODIGOS = {
	bfs = {
		titulo       = "BFS — Búsqueda en Anchura",
		complejidad  = "O(V + E)",
		espacio      = "O(V)",
		structNombre = "Cola (FIFO)",
		lineas = {
			"fun BFS(grafo, inicio):",
			"  cola ← [inicio]",
			"  visitados ← {inicio}",
			"  dist[inicio] ← 0",
			"",
			"  mientras cola ≠ ∅:",
			"    u ← desencolar(cola)",
			"    para v en vecinos(u):",
			"      si v ∉ visitados:",
			"        encolar(cola, v)",
			"        visitados ← v",
			"        dist[v] ← dist[u] + 1",
			"  retornar dist",
		},
	},
	dfs = {
		titulo       = "DFS — Búsqueda en Profundidad",
		complejidad  = "O(V + E)",
		espacio      = "O(V)",
		structNombre = "Pila (LIFO)",
		lineas = {
			"fun DFS(grafo, inicio):",
			"  pila ← [inicio]",
			"  visitados ← {}",
			"",
			"  mientras pila ≠ ∅:",
			"    u ← desapilar(pila)",
			"    si u ∉ visitados:",
			"      visitados ← u",
			"      para v en vecinos(u):",
			"        si v ∉ visitados:",
			"          apilar(pila, v)",
			"  retornar visitados",
		},
	},
	dijkstra = {
		titulo       = "Dijkstra — Camino más corto",
		complejidad  = "O((V+E) log V)",
		espacio      = "O(V)",
		structNombre = "Cola de prioridad",
		lineas = {
			"fun Dijkstra(grafo, inicio):",
			"  dist[v] ← ∞  para todo v",
			"  dist[inicio] ← 0",
			"  PQ ← {(0, inicio)}",
			"",
			"  mientras PQ ≠ ∅:",
			"    (d, u) ← extraerMin(PQ)",
			"    para (v, w) en vecinos(u):",
			"      alt ← dist[u] + w",
			"      si alt < dist[v]:",
			"        dist[v] ← alt",
			"        PQ ← (alt, v)",
			"  retornar dist",
		},
	},
	prim = {
		titulo       = "Prim — Árbol de expansión mínima",
		complejidad  = "O(E log V)",
		espacio      = "O(V)",
		structNombre = "Cola de prioridad",
		lineas = {
			"fun Prim(grafo, raiz):",
			"  key[v] ← ∞  para todo v",
			"  key[raiz] ← 0",
			"  padre[raiz] ← nulo",
			"  PQ ← todos los nodos",
			"",
			"  mientras PQ ≠ ∅:",
			"    u ← extraerMin(PQ)",
			"    para (v, w) en vecinos(u):",
			"      si v ∈ PQ  y  w < key[v]:",
			"        padre[v] ← u",
			"        key[v] ← w",
			"  retornar padre",
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- UTILIDADES INTERNAS
-- ═══════════════════════════════════════════════════════════════════════════════

local function copiarTabla(t)
	local c = {}
	for _, v in ipairs(t) do c[#c+1] = v end
	return c
end

local function copiarDict(d)
	local c = {}
	for k, v in pairs(d) do c[k] = v end
	return c
end

local function contiene(lista, valor)
	for _, v in ipairs(lista) do
		if v == valor then return true end
	end
	return false
end

-- Convierte tabla de booleanos {[nodo]=true} en lista ordenada
local function dictALista(dict, orden)
	local lista = {}
	for _, n in ipairs(orden) do
		if dict[n] then lista[#lista+1] = n end
	end
	return lista
end

-- Convierte {[nodo]=true, ...} en lista (sin orden garantizado)
local function setALista(set)
	local lista = {}
	for k in pairs(set) do lista[#lista+1] = k end
	table.sort(lista)
	return lista
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- BFS
-- ═══════════════════════════════════════════════════════════════════════════════

function AlgoritmosGrafo.bfs(nodos, adyacencias, inicio)
	inicio = inicio or nodos[1]
	if not inicio then return {} end

	local steps = {}

	-- Paso 0: Inicializar
	local cola      = { inicio }
	local visitados = { [inicio] = true }
	local dist      = { [inicio] = 0 }

	steps[#steps+1] = {
		nodoActual   = inicio,
		visitados    = { inicio },
		pendientes   = copiarTabla(cola),
		distancias   = copiarDict(dist),
		descripcion  = "Inicializar: cola = [" .. inicio .. "], dist[" .. inicio .. "] = 0",
		lineaPseudo  = 2,
		struct       = "Cola",
		structConten = copiarTabla(cola),
	}

	local cabeza = 1  -- índice del frente de la cola

	while cabeza <= #cola do
		local u = cola[cabeza]
		cabeza += 1

		-- Paso: desencolar u
		local colaActual = {}
		for i = cabeza, #cola do colaActual[#colaActual+1] = cola[i] end

		local vecinos = adyacencias[u] or {}
		local nuevosPendientes = {}

		for _, v in ipairs(vecinos) do
			if not visitados[v] then
				visitados[v] = true
				dist[v] = dist[u] + 1
				cola[#cola+1] = v
				nuevosPendientes[#nuevosPendientes+1] = v
			end
		end

		-- Construir lista de cola restante
		local colaPost = {}
		for i = cabeza, #cola do colaPost[#colaPost+1] = cola[i] end

		local desc
		if #nuevosPendientes > 0 then
			desc = "Desencolar " .. u .. " — vecinos no visitados encolados: " .. table.concat(nuevosPendientes, ", ")
		else
			desc = "Desencolar " .. u .. " — todos sus vecinos ya visitados"
		end

		steps[#steps+1] = {
			nodoActual   = u,
			visitados    = dictALista(visitados, nodos),
			pendientes   = colaPost,
			distancias   = copiarDict(dist),
			descripcion  = desc,
			lineaPseudo  = 7,
			struct       = "Cola",
			structConten = colaPost,
		}
	end

	-- Paso final
	steps[#steps+1] = {
		nodoActual   = nil,
		visitados    = dictALista(visitados, nodos),
		pendientes   = {},
		distancias   = copiarDict(dist),
		descripcion  = "Cola vacía — BFS completado. Distancias calculadas.",
		lineaPseudo  = 13,
		struct       = "Cola",
		structConten = {},
	}

	return steps
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- DFS
-- ═══════════════════════════════════════════════════════════════════════════════

function AlgoritmosGrafo.dfs(nodos, adyacencias, inicio)
	inicio = inicio or nodos[1]
	if not inicio then return {} end

	local steps = {}

	-- Paso 0: Inicializar
	local pila      = { inicio }
	local visitados = {}

	steps[#steps+1] = {
		nodoActual   = nil,
		visitados    = {},
		pendientes   = copiarTabla(pila),
		distancias   = nil,
		descripcion  = "Inicializar: pila = [" .. inicio .. "]",
		lineaPseudo  = 2,
		struct       = "Pila",
		structConten = copiarTabla(pila),
	}

	while #pila > 0 do
		-- Desapilar (tope de la pila)
		local u = pila[#pila]
		pila[#pila] = nil

		if not visitados[u] then
			visitados[u] = true
			local vecinos = adyacencias[u] or {}
			local apiladosAhora = {}

			-- Apilar en orden inverso para mantener orden natural de visita
			for i = #vecinos, 1, -1 do
				local v = vecinos[i]
				if not visitados[v] then
					pila[#pila+1] = v
					table.insert(apiladosAhora, 1, v)
				end
			end

			local desc
			if #apiladosAhora > 0 then
				desc = "Visitar " .. u .. " — vecinos apilados: " .. table.concat(apiladosAhora, ", ")
			else
				desc = "Visitar " .. u .. " — sin vecinos nuevos que apilar"
			end

			steps[#steps+1] = {
				nodoActual   = u,
				visitados    = dictALista(visitados, nodos),
				pendientes   = copiarTabla(pila),
				distancias   = nil,
				descripcion  = desc,
				lineaPseudo  = 8,
				struct       = "Pila",
				structConten = copiarTabla(pila),
			}
		else
			-- Nodo ya visitado: descartar
			steps[#steps+1] = {
				nodoActual   = u,
				visitados    = dictALista(visitados, nodos),
				pendientes   = copiarTabla(pila),
				distancias   = nil,
				descripcion  = "Desapilar " .. u .. " — ya visitado, se descarta",
				lineaPseudo  = 7,
				struct       = "Pila",
				structConten = copiarTabla(pila),
			}
		end
	end

	-- Paso final
	steps[#steps+1] = {
		nodoActual   = nil,
		visitados    = dictALista(visitados, nodos),
		pendientes   = {},
		distancias   = nil,
		descripcion  = "Pila vacía — DFS completado. Nodos visitados: " .. table.concat(dictALista(visitados, nodos), ", "),
		lineaPseudo  = 12,
		struct       = "Pila",
		structConten = {},
	}

	return steps
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- DIJKSTRA (pesos todos = 1)
-- ═══════════════════════════════════════════════════════════════════════════════

function AlgoritmosGrafo.dijkstra(nodos, adyacencias, inicio)
	inicio = inicio or nodos[1]
	if not inicio then return {} end

	local INF = math.huge
	local steps = {}

	-- Inicializar distancias
	local dist     = {}
	local enPQ     = {}  -- {[nodo]=true} — nodos aún en la cola de prioridad
	local extraidos = {} -- {[nodo]=true} — nodos ya procesados

	for _, n in ipairs(nodos) do
		dist[n]  = INF
		enPQ[n]  = true
	end
	dist[inicio] = 0

	-- Representación de PQ como lista de pares para el UI
	local function pqComoLista()
		local lista = {}
		for _, n in ipairs(nodos) do
			if enPQ[n] then
				local d = dist[n]
				lista[#lista+1] = (d == INF) and (n .. "=∞") or (n .. "=" .. d)
			end
		end
		return lista
	end

	-- Distancias para UI
	local function distParaUI()
		local d = {}
		for k, v in pairs(dist) do
			d[k] = (v == INF) and "∞" or tostring(v)
		end
		return d
	end

	-- Paso 0: Inicializar
	steps[#steps+1] = {
		nodoActual   = nil,
		visitados    = {},
		pendientes   = pqComoLista(),
		distancias   = distParaUI(),
		descripcion  = "Inicializar: dist[" .. inicio .. "]=0, resto=∞. PQ tiene todos los nodos.",
		lineaPseudo  = 2,
		struct       = "Cola de prioridad",
		structConten = pqComoLista(),
	}

	-- Función: extraer mínimo de PQ
	local function extraerMin()
		local minNodo = nil
		local minDist = INF
		for _, n in ipairs(nodos) do
			if enPQ[n] and dist[n] <= minDist then
				minDist = dist[n]
				minNodo = n
			end
		end
		return minNodo
	end

	-- Iterar
	while true do
		local u = extraerMin()
		if not u then break end
		if dist[u] == INF then break end  -- sin conexión

		enPQ[u] = nil
		extraidos[u] = true

		local vecinos = adyacencias[u] or {}
		local actualizados = {}

		for _, v in ipairs(vecinos) do
			if enPQ[v] then
				local alt = dist[u] + 1  -- peso = 1
				if alt < dist[v] then
					dist[v] = alt
					actualizados[#actualizados+1] = v .. "(dist=" .. alt .. ")"
				end
			end
		end

		local visitList = {}
		for _, n in ipairs(nodos) do
			if extraidos[n] then visitList[#visitList+1] = n end
		end

		local desc
		if #actualizados > 0 then
			desc = "Extraer " .. u .. " (dist=" .. tostring(dist[u]) .. ") — actualizar: " .. table.concat(actualizados, ", ")
		else
			desc = "Extraer " .. u .. " (dist=" .. tostring(dist[u]) .. ") — sin actualizaciones"
		end

		steps[#steps+1] = {
			nodoActual   = u,
			visitados    = visitList,
			pendientes   = pqComoLista(),
			distancias   = distParaUI(),
			descripcion  = desc,
			lineaPseudo  = 7,
			struct       = "Cola de prioridad",
			structConten = pqComoLista(),
		}
	end

	-- Paso final
	local visitList = {}
	for _, n in ipairs(nodos) do
		if extraidos[n] then visitList[#visitList+1] = n end
	end

	steps[#steps+1] = {
		nodoActual   = nil,
		visitados    = visitList,
		pendientes   = {},
		distancias   = distParaUI(),
		descripcion  = "PQ vacía — Dijkstra completado. Distancias mínimas calculadas.",
		lineaPseudo  = 13,
		struct       = "Cola de prioridad",
		structConten = {},
	}

	return steps
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- PRIM (MST, pesos todos = 1)
-- ═══════════════════════════════════════════════════════════════════════════════

function AlgoritmosGrafo.prim(nodos, adyacencias, raiz)
	raiz = raiz or nodos[1]
	if not raiz then return {} end

	local INF = math.huge
	local steps = {}

	local key    = {}  -- coste mínimo para conectar el nodo al MST
	local padre  = {}  -- padre en el MST
	local enPQ   = {}  -- nodos aún en la cola de prioridad
	local enMST  = {}  -- nodos ya incluidos en el MST

	for _, n in ipairs(nodos) do
		key[n]   = INF
		padre[n] = nil
		enPQ[n]  = true
	end
	key[raiz] = 0

	local function pqComoLista()
		local lista = {}
		for _, n in ipairs(nodos) do
			if enPQ[n] then
				local k = key[n]
				lista[#lista+1] = (k == INF) and (n .. "=∞") or (n .. "=" .. k)
			end
		end
		return lista
	end

	-- Paso 0
	steps[#steps+1] = {
		nodoActual   = nil,
		visitados    = {},
		pendientes   = pqComoLista(),
		distancias   = nil,
		descripcion  = "Inicializar: key[" .. raiz .. "]=0, resto=∞. PQ tiene todos los nodos.",
		lineaPseudo  = 2,
		struct       = "Cola de prioridad",
		structConten = pqComoLista(),
	}

	local function extraerMin()
		local minNodo = nil
		local minKey  = INF
		for _, n in ipairs(nodos) do
			if enPQ[n] and key[n] <= minKey then
				minKey = key[n]
				minNodo = n
			end
		end
		return minNodo
	end

	while true do
		local u = extraerMin()
		if not u then break end
		if key[u] == INF then break end

		enPQ[u] = nil
		enMST[u] = true

		local vecinos = adyacencias[u] or {}
		local actualizados = {}

		for _, v in ipairs(vecinos) do
			if enPQ[v] and 1 < key[v] then
				key[v]   = 1
				padre[v] = u
				actualizados[#actualizados+1] = v .. "(padre=" .. u .. ")"
			end
		end

		local mstList = {}
		for _, n in ipairs(nodos) do
			if enMST[n] then mstList[#mstList+1] = n end
		end

		local desc
		if #actualizados > 0 then
			desc = "Agregar " .. u .. " al MST — actualizar vecinos: " .. table.concat(actualizados, ", ")
		else
			desc = "Agregar " .. u .. " al MST — sin vecinos que actualizar"
		end

		steps[#steps+1] = {
			nodoActual   = u,
			visitados    = mstList,
			pendientes   = pqComoLista(),
			distancias   = nil,
			descripcion  = desc,
			lineaPseudo  = 8,
			struct       = "Cola de prioridad",
			structConten = pqComoLista(),
		}
	end

	-- Paso final
	local mstList = {}
	for _, n in ipairs(nodos) do
		if enMST[n] then mstList[#mstList+1] = n end
	end

	-- Construir descripción del MST (aristas padre→hijo)
	local aristasDesc = {}
	for _, n in ipairs(nodos) do
		if padre[n] then aristasDesc[#aristasDesc+1] = padre[n] .. "—" .. n end
	end

	steps[#steps+1] = {
		nodoActual   = nil,
		visitados    = mstList,
		pendientes   = {},
		distancias   = nil,
		descripcion  = "PQ vacía — MST completado. Aristas: " .. (next(aristasDesc) and table.concat(aristasDesc, ", ") or "(grafo desconectado)"),
		lineaPseudo  = 13,
		struct       = "Cola de prioridad",
		structConten = {},
	}

	return steps
end

return AlgoritmosGrafo
