-- StarterPlayerScripts/HUD/ModulosHUD/AlgoritmosGrafo.lua
-- Generadores de pasos para BFS, DFS, Dijkstra y Prim.
-- Módulo puro: sin dependencias de GUI ni servicios de Roblox.
--
-- Uso:
--   local steps = AlgoritmosGrafo.bfs(nodos, adyacencias, inicio)
--   -- steps[i] = { nodoActual, visitados, pendientes, distancias,
--   --              descripcion, lineaPseudo, struct, structConten,
--   --              aristasRecorridas, aristaNueva }
--
-- aristasRecorridas : [ {nomA, nomB}, ... ] — árbol/camino acumulado hasta este paso
-- aristaNueva       : {nomA, nomB} | nil   — arista específica recién añadida en este paso

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

-- NOTA: dictALista sigue disponible para uso interno pero ya no se usa
-- en BFS ni DFS para el campo `visitados` (se reemplazó por visitOrder).
local function dictALista(dict, orden)
	local lista = {}
	for _, n in ipairs(orden) do
		if dict[n] then lista[#lista+1] = n end
	end
	return lista
end

-- Construye la lista de aristas del árbol a partir del dict padre.
-- Orden: sigue la lista `orden` para que el resultado sea determinista.
local function buildAristasRecorridas(orden, padre)
	local aristas = {}
	for _, n in ipairs(orden) do
		if padre[n] then
			aristas[#aristas+1] = { padre[n], n }
		end
	end
	return aristas
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- BFS
-- ═══════════════════════════════════════════════════════════════════════════════

function AlgoritmosGrafo.bfs(nodos, adyacencias, inicio)
	inicio = inicio or nodos[1]
	if not inicio then return {} end

	local steps = {}

	local cola       = { inicio }
	local visitados  = { [inicio] = true }
	local visitOrder = { inicio }            -- orden real de descubrimiento (no alfabético)
	local dist       = { [inicio] = 0 }
	local padre      = {}  -- padre[v] = u  ↔  arista u→v en el árbol BFS

	steps[#steps+1] = {
		nodoActual       = inicio,
		visitados        = { inicio },
		pendientes       = copiarTabla(cola),
		distancias       = copiarDict(dist),
		descripcion      = "Inicializar: cola = [" .. inicio .. "], dist[" .. inicio .. "] = 0",
		lineaPseudo      = 2,
		struct           = "Cola",
		structConten     = copiarTabla(cola),
		aristasRecorridas = {},
		aristaNueva      = nil,
	}

	local cabeza = 1

	while cabeza <= #cola do
		local u = cola[cabeza]
		cabeza += 1

		local vecinos   = adyacencias[u] or {}
		local hayNuevos = false

		for _, v in ipairs(vecinos) do
			if not visitados[v] then
				hayNuevos                 = true
				visitados[v]              = true
				visitOrder[#visitOrder+1] = v
				dist[v]                   = dist[u] + 1
				padre[v]                  = u
				cola[#cola+1]             = v

				-- Cola restante DESPUÉS de cabeza (ya incluye v recién encolado)
				local colaPost = {}
				for i = cabeza, #cola do colaPost[#colaPost+1] = cola[i] end

				-- Un paso por cada nuevo vecino descubierto → una arista naranja a la vez
				steps[#steps+1] = {
					nodoActual        = u,
					visitados         = copiarTabla(visitOrder),
					pendientes        = colaPost,
					distancias        = copiarDict(dist),
					descripcion       = "Desde " .. u .. ": encolar " .. v .. " (dist=" .. dist[v] .. ")",
					lineaPseudo       = 9,
					struct            = "Cola",
					structConten      = colaPost,
					aristasRecorridas = buildAristasRecorridas(nodos, padre),
					aristaNueva       = { u, v },
				}
			end
		end

		-- Sin vecinos nuevos: mostrar que u fue desencolado sin añadir aristas
		if not hayNuevos then
			local colaPost = {}
			for i = cabeza, #cola do colaPost[#colaPost+1] = cola[i] end

			steps[#steps+1] = {
				nodoActual        = u,
				visitados         = copiarTabla(visitOrder),
				pendientes        = colaPost,
				distancias        = copiarDict(dist),
				descripcion       = "Desencolar " .. u .. " — todos sus vecinos ya visitados",
				lineaPseudo       = 7,
				struct            = "Cola",
				structConten      = colaPost,
				aristasRecorridas = buildAristasRecorridas(nodos, padre),
				aristaNueva       = nil,
			}
		end
	end

	steps[#steps+1] = {
		nodoActual        = nil,
		visitados         = copiarTabla(visitOrder),
		pendientes        = {},
		distancias        = copiarDict(dist),
		descripcion       = "Cola vacía — BFS completado. Distancias calculadas.",
		lineaPseudo       = 13,
		struct            = "Cola",
		structConten      = {},
		aristasRecorridas = buildAristasRecorridas(nodos, padre),
		aristaNueva       = nil,
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

	local pila       = { inicio }
	local visitados  = {}
	local visitOrder = {}  -- orden real de visita (cuando se desapila y procesa)
	local padre      = {}  -- padre[v] = u  ↔  arista u→v en el árbol DFS

	steps[#steps+1] = {
		nodoActual        = nil,
		visitados         = {},
		pendientes        = copiarTabla(pila),
		distancias        = nil,
		descripcion       = "Inicializar: pila = [" .. inicio .. "]",
		lineaPseudo       = 2,
		struct            = "Pila",
		structConten      = copiarTabla(pila),
		aristasRecorridas = {},
		aristaNueva       = nil,
	}

	while #pila > 0 do
		local u = pila[#pila]
		pila[#pila] = nil

		if not visitados[u] then
			visitados[u]              = true
			visitOrder[#visitOrder+1] = u   -- ← registrar en orden de visita real

			local vecinos       = adyacencias[u] or {}
			local apiladosAhora = {}

			for i = #vecinos, 1, -1 do
				local v = vecinos[i]
				if not visitados[v] then
					pila[#pila+1] = v
					if not padre[v] then
						padre[v] = u
					end
					table.insert(apiladosAhora, 1, v)
				end
			end

			local desc
			if #apiladosAhora > 0 then
				desc = "Visitar " .. u .. " — vecinos apilados: " .. table.concat(apiladosAhora, ", ")
			else
				desc = "Visitar " .. u .. " — sin vecinos nuevos que apilar"
			end

			local aristaNueva = padre[u] and { padre[u], u } or nil

			steps[#steps+1] = {
				nodoActual        = u,
				visitados         = copiarTabla(visitOrder),   -- ← orden real, no alfabético
				pendientes        = copiarTabla(pila),
				distancias        = nil,
				descripcion       = desc,
				lineaPseudo       = 8,
				struct            = "Pila",
				structConten      = copiarTabla(pila),
				aristasRecorridas = buildAristasRecorridas(nodos, padre),
				aristaNueva       = aristaNueva,
			}
		else
			steps[#steps+1] = {
				nodoActual        = u,
				visitados         = copiarTabla(visitOrder),   -- ← orden real, no alfabético
				pendientes        = copiarTabla(pila),
				distancias        = nil,
				descripcion       = "Desapilar " .. u .. " — ya visitado, se descarta",
				lineaPseudo       = 7,
				struct            = "Pila",
				structConten      = copiarTabla(pila),
				aristasRecorridas = buildAristasRecorridas(nodos, padre),
				aristaNueva       = nil,
			}
		end
	end

	steps[#steps+1] = {
		nodoActual        = nil,
		visitados         = copiarTabla(visitOrder),           -- ← orden real, no alfabético
		pendientes        = {},
		distancias        = nil,
		descripcion       = "Pila vacía — DFS completado. Nodos visitados: " .. table.concat(visitOrder, ", "),
		lineaPseudo       = 12,
		struct            = "Pila",
		structConten      = {},
		aristasRecorridas = buildAristasRecorridas(nodos, padre),
		aristaNueva       = nil,
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

	local dist       = {}
	local enPQ       = {}
	local extraidos  = {}
	local extractOrder = {}  -- orden real de extracción (no alfabético)
	local pred       = {}  -- pred[v] = u  ↔  arista u→v en el árbol de caminos mínimos

	for _, n in ipairs(nodos) do
		dist[n] = INF
		enPQ[n] = true
	end
	dist[inicio] = 0

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

	local function distParaUI()
		local d = {}
		for k, v in pairs(dist) do
			d[k] = (v == INF) and "∞" or tostring(v)
		end
		return d
	end

	steps[#steps+1] = {
		nodoActual        = nil,
		visitados         = {},
		pendientes        = pqComoLista(),
		distancias        = distParaUI(),
		descripcion       = "Inicializar: dist[" .. inicio .. "]=0, resto=∞. PQ tiene todos los nodos.",
		lineaPseudo       = 2,
		struct            = "Cola de prioridad",
		structConten      = pqComoLista(),
		aristasRecorridas = {},
		aristaNueva       = nil,
	}

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

	while true do
		local u = extraerMin()
		if not u then break end
		if dist[u] == INF then break end

		enPQ[u]                    = nil
		extraidos[u]               = true
		extractOrder[#extractOrder+1] = u   -- ← registrar orden real de extracción

		local vecinos      = adyacencias[u] or {}
		local actualizados = {}

		for _, v in ipairs(vecinos) do
			if enPQ[v] then
				local alt = dist[u] + 1
				if alt < dist[v] then
					dist[v] = alt
					pred[v] = u
					actualizados[#actualizados+1] = v .. "(dist=" .. alt .. ")"
				end
			end
		end

		local desc
		if #actualizados > 0 then
			desc = "Extraer " .. u .. " (dist=" .. tostring(dist[u]) .. ") — actualizar: " .. table.concat(actualizados, ", ")
		else
			desc = "Extraer " .. u .. " (dist=" .. tostring(dist[u]) .. ") — sin actualizaciones"
		end

		local aristaNueva = pred[u] and { pred[u], u } or nil

		steps[#steps+1] = {
			nodoActual        = u,
			visitados         = copiarTabla(extractOrder),   -- ← orden real de extracción
			pendientes        = pqComoLista(),
			distancias        = distParaUI(),
			descripcion       = desc,
			lineaPseudo       = 7,
			struct            = "Cola de prioridad",
			structConten      = pqComoLista(),
			aristasRecorridas = buildAristasRecorridas(nodos, pred),
			aristaNueva       = aristaNueva,
		}
	end

	steps[#steps+1] = {
		nodoActual        = nil,
		visitados         = copiarTabla(extractOrder),       -- ← orden real de extracción
		pendientes        = {},
		distancias        = distParaUI(),
		descripcion       = "PQ vacía — Dijkstra completado. Distancias mínimas calculadas.",
		lineaPseudo       = 13,
		struct            = "Cola de prioridad",
		structConten      = {},
		aristasRecorridas = buildAristasRecorridas(nodos, pred),
		aristaNueva       = nil,
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

	local key      = {}
	local padre    = {}
	local enPQ     = {}
	local enMST    = {}
	local mstOrder = {}  -- orden real de inserción en el MST (no alfabético)

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

	steps[#steps+1] = {
		nodoActual        = nil,
		visitados         = {},
		pendientes        = pqComoLista(),
		distancias        = nil,
		descripcion       = "Inicializar: key[" .. raiz .. "]=0, resto=∞. PQ tiene todos los nodos.",
		lineaPseudo       = 2,
		struct            = "Cola de prioridad",
		structConten      = pqComoLista(),
		aristasRecorridas = {},
		aristaNueva       = nil,
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

		enPQ[u]              = nil
		enMST[u]             = true
		mstOrder[#mstOrder+1] = u   -- ← registrar orden real de inserción en MST

		local vecinos      = adyacencias[u] or {}
		local actualizados = {}

		for _, v in ipairs(vecinos) do
			if enPQ[v] and 1 < key[v] then
				key[v]   = 1
				padre[v] = u
				actualizados[#actualizados+1] = v .. "(padre=" .. u .. ")"
			end
		end

		local desc
		if #actualizados > 0 then
			desc = "Agregar " .. u .. " al MST — actualizar vecinos: " .. table.concat(actualizados, ", ")
		else
			desc = "Agregar " .. u .. " al MST — sin vecinos que actualizar"
		end

		local aristaNueva = padre[u] and { padre[u], u } or nil

		steps[#steps+1] = {
			nodoActual        = u,
			visitados         = copiarTabla(mstOrder),   -- ← orden real de inserción en MST
			pendientes        = pqComoLista(),
			distancias        = nil,
			descripcion       = desc,
			lineaPseudo       = 8,
			struct            = "Cola de prioridad",
			structConten      = pqComoLista(),
			aristasRecorridas = buildAristasRecorridas(nodos, padre),
			aristaNueva       = aristaNueva,
		}
	end

	local aristasDesc = {}
	for _, n in ipairs(nodos) do
		if padre[n] then aristasDesc[#aristasDesc+1] = padre[n] .. "—" .. n end
	end

	steps[#steps+1] = {
		nodoActual        = nil,
		visitados         = copiarTabla(mstOrder),           -- ← orden real de inserción en MST
		pendientes        = {},
		distancias        = nil,
		descripcion       = "PQ vacía — MST completado. Aristas: " .. (next(aristasDesc) and table.concat(aristasDesc, ", ") or "(grafo desconectado)"),
		lineaPseudo       = 13,
		struct            = "Cola de prioridad",
		structConten      = {},
		aristasRecorridas = buildAristasRecorridas(nodos, padre),
		aristaNueva       = nil,
	}

	return steps
end

return AlgoritmosGrafo