-- ReplicatedStorage/Compartido/GrafoHelpers.lua
-- Utilidades de grafo compartidas: fuente canónica única.
-- Requerido desde: MatrizAdyacencia, ServicioGrafosAnalisis,
--                  ConectarCables, ServicioMisiones, ValidadorConexiones.
-- Compatible con servidor Y cliente (no usa servicios de Roblox).

local GrafoHelpers = {}

-- ════════════════════════════════════════════════════════════════════
-- SEPARADOR CANÓNICO
-- ════════════════════════════════════════════════════════════════════
-- NUNCA usar "_": los nombres de nodo contienen "_" (ej. "Nodo1_z1").
-- El separador "|" no aparece en nombres de nodo.
local SEP = "|"

-- ════════════════════════════════════════════════════════════════════
-- clavePar: clave única para un par de nodos (orden normalizado A < B)
-- ════════════════════════════════════════════════════════════════════
function GrafoHelpers.clavePar(nomA, nomB)
	if nomA < nomB then
		return nomA .. SEP .. nomB
	else
		return nomB .. SEP .. nomA
	end
end

-- parsearClave: inverso de clavePar → (nomA, nomB)
function GrafoHelpers.parsearClave(clave)
	return clave:match("^(.+)%" .. SEP .. "(.+)$")
end

-- ════════════════════════════════════════════════════════════════════
-- nodosDeZona: lista de nombres de nodo que pertenecen a zonaID
-- ════════════════════════════════════════════════════════════════════
-- Estrategia 1 (prioritaria): config.NodosZona[zonaID] — mapeo explícito.
--   Permite cualquier nombre de zona ("Zona_electrica", etc.).
--   Solo incluye nodos que existan en Adyacencias.
--
-- Estrategia 2 (fallback): sufijo numérico "_z<N>" derivado de zonaID.
--   "Zona_Estacion_3" → nodos cuyo nombre termina en "_z3".
--   Retro-compatible con zonas sin NodosZona declarado.
--
-- Fail-safe: si el formato de zona es desconocido y no hay NodosZona,
--   devuelve {} con warn (nunca incluye todo silenciosamente).
function GrafoHelpers.nodosDeZona(adyacencias, zonaID, config)
	-- Estrategia 1: mapa explícito
	if config and config.NodosZona and config.NodosZona[zonaID] then
		local nodos = {}
		for _, nom in ipairs(config.NodosZona[zonaID]) do
			if adyacencias[nom] then
				table.insert(nodos, nom)
			end
		end
		table.sort(nodos)
		return nodos
	end

	-- Estrategia 2: sufijo numérico
	local zonaNum = zonaID:match("_(%d+)$")
	if not zonaNum then
		warn("[GrafoHelpers] nodosDeZona: formato de zona desconocido:", zonaID,
			"— devolviendo {} (fail-safe). Declara NodosZona en LevelsConfig si la zona no termina en _<N>.")
		return {}
	end

	local sufijo = "_z" .. zonaNum
	local nodos = {}
	for nomNodo in pairs(adyacencias) do
		if nomNodo:sub(-#sufijo) == sufijo then
			table.insert(nodos, nomNodo)
		end
	end
	table.sort(nodos)
	return nodos
end

-- ════════════════════════════════════════════════════════════════════
-- detectarDirigido: true si el grafo (filtrado a `nodos`) es dirigido
-- ════════════════════════════════════════════════════════════════════
-- Un grafo es dirigido si existe A→B (en adyacencias) donde B→A NO existe
-- entre los nodos de la zona.
function GrafoHelpers.detectarDirigido(adyacencias, nodos)
	local enZona = {}
	for _, nom in ipairs(nodos) do enZona[nom] = true end

	for _, nomA in ipairs(nodos) do
		local listaA = adyacencias[nomA] or {}
		for _, nomB in ipairs(listaA) do
			if not enZona[nomB] then continue end  -- nomB fuera de zona

			local listaB = adyacencias[nomB]
			if not listaB then return true end      -- B sin aristas de vuelta

			local tieneReversa = false
			for _, n in ipairs(listaB) do
				if n == nomA then tieneReversa = true; break end
			end
			if not tieneReversa then return true end
		end
	end
	return false
end

return GrafoHelpers
