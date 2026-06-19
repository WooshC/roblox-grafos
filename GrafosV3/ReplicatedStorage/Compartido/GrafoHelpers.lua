-- ReplicatedStorage/Compartido/GrafoHelpers.lua
-- Utilidades de grafo compartidas: fuente canónica única.
-- Requerido desde: MatrizAdyacencia, ServicioGrafosAnalisis,
--                  ConectarCables, ServicioMisiones, ValidadorConexiones.
-- Compatible con servidor Y cliente (no usa servicios de Roblox).

local GrafoHelpers = {}

-- ════════════════════════════════════════════════════════════════════
-- DEPENDENCIAS (solo módulos puros compartidos)
-- ════════════════════════════════════════════════════════════════════
local LevelsConfig = require(script.Parent.Parent:WaitForChild("Config"):WaitForChild("LevelsConfig"))

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
-- ALCANCE DESDE UN NODO (BFS puro)
-- ════════════════════════════════════════════════════════════════════
function GrafoHelpers.nodosAlcanzables(adyacencias, inicio)
	local alcanzados = {}
	local cola = {inicio}
	alcanzados[inicio] = true
	local idx = 1
	while idx <= #cola do
		local u = cola[idx]
		idx = idx + 1
		for _, v in ipairs(adyacencias[u] or {}) do
			if not alcanzados[v] then
				alcanzados[v] = true
				table.insert(cola, v)
			end
		end
	end
	return alcanzados
end

function GrafoHelpers.nodosNoAlcanzables(adyacencias, inicio, nodos)
	local alcanzados = GrafoHelpers.nodosAlcanzables(adyacencias, inicio)
	local set = {}
	for _, nom in ipairs(nodos) do
		if not alcanzados[nom] then
			set[nom] = true
		end
	end
	return set
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

-- ════════════════════════════════════════════════════════════════════
-- RESOLVER CONFIG DESDE número (nivelID) o tabla
-- ════════════════════════════════════════════════════════════════════
local function resolverConfig(configOrNivelID)
	if type(configOrNivelID) == "number" then
		return LevelsConfig[configOrNivelID]
	elseif type(configOrNivelID) == "table" then
		return configOrNivelID
	end
	return nil
end

-- ════════════════════════════════════════════════════════════════════
-- PESO DE ARISTA (bidireccional, con default)
-- ════════════════════════════════════════════════════════════════════
function GrafoHelpers.obtenerPeso(configOrNivelID, nomA, nomB, default)
	default = default or 0
	local cfg = resolverConfig(configOrNivelID)
	if not cfg or not cfg.PesosAristas then return default end

	-- 1) búsqueda rápida con separador canónico en ambos sentidos
	local claves = {
		GrafoHelpers.clavePar(nomA, nomB),
		nomA .. SEP .. nomB,
		nomB .. SEP .. nomA,
	}
	for _, clave in ipairs(claves) do
		local peso = cfg.PesosAristas[clave]
		if peso ~= nil then return peso end
	end

	-- 2) búsqueda tolerante al separador usado en config
	for clave, peso in pairs(cfg.PesosAristas) do
		local a, b = clave:match("^(.-)|(.+)$")
		if not a then
			a, b = clave:match("^(.-)_(.+)$")
		end
		if a and b then
			if (a == nomA and b == nomB) or (a == nomB and b == nomA) then
				return peso
			end
		end
	end

	return default
end

-- ════════════════════════════════════════════════════════════════════
-- CABLE DEFECTUOSO (según config estática o tabla Defectuosos)
-- ════════════════════════════════════════════════════════════════════
function GrafoHelpers.esCableDefectuoso(configOrNivelID, nomA, nomB)
	local cfg = resolverConfig(configOrNivelID)
	if not cfg then return false end
	if cfg.Defectuosos then
		local claves = {
			GrafoHelpers.clavePar(nomA, nomB),
			nomA .. SEP .. nomB,
			nomB .. SEP .. nomA,
		}
		for _, clave in ipairs(claves) do
			if cfg.Defectuosos[clave] == true then return true end
		end
	end
	if cfg.CablesDefectuosos then
		for _, par in ipairs(cfg.CablesDefectuosos) do
			if (par[1] == nomA and par[2] == nomB) or (par[1] == nomB and par[2] == nomA) then
				return true
			end
		end
	end
	return false
end

function GrafoHelpers.defectuososSet(configOrNivelID)
	local cfg = resolverConfig(configOrNivelID)
	local set = {}
	if not cfg then return set end
	if cfg.Defectuosos then
		for clave, _ in pairs(cfg.Defectuosos) do
			set[clave] = true
		end
	end
	if cfg.CablesDefectuosos then
		for _, par in ipairs(cfg.CablesDefectuosos) do
			set[GrafoHelpers.clavePar(par[1], par[2])] = true
		end
	end
	return set
end

-- ════════════════════════════════════════════════════════════════════
-- CÁLCULO Y FORMATO DE COSTO
-- ════════════════════════════════════════════════════════════════════
function GrafoHelpers.calcularCosto(peso, costoPorMetro)
	if not peso or not costoPorMetro or costoPorMetro <= 0 then return 0 end
	return math.floor(peso * costoPorMetro)
end

function GrafoHelpers.formatearDinero(valor)
	local num = tostring(math.floor((valor or 0) + 0.5))
	local resultado = ""
	local contador = 0
	for i = #num, 1, -1 do
		if contador > 0 and contador % 3 == 0 then
			resultado = "," .. resultado
		end
		resultado = num:sub(i, i) .. resultado
		contador = contador + 1
	end
	return "$" .. resultado
end

-- ════════════════════════════════════════════════════════════════════
-- ADYACENCIAS DESDE RESPUESTA DE MATRIZ
-- ════════════════════════════════════════════════════════════════════
function GrafoHelpers.adjDesdeMatriz(data, incluirDefectuosas, configOrNivelID)
	local adj = {}
	local headers = data.Headers
	if not headers then return adj end
	local esDirigido = data.EsDirigido or false

	local sets = {}
	for _, a in ipairs(headers) do
		adj[a] = {}
		sets[a] = {}
	end

	for i = 1, #headers do
		local a = headers[i]
		local fila = data.Matrix[i]
		if fila then
			for j = 1, #headers do
				if (fila[j] or 0) > 0 then
					local b = headers[j]
					if not incluirDefectuosas then
						local fuente = configOrNivelID or data
						if GrafoHelpers.esCableDefectuoso(fuente, a, b) then
							continue
						end
					end
					if not sets[a][b] then
						table.insert(adj[a], b)
						sets[a][b] = true
					end
					if not esDirigido and not sets[b][a] then
						table.insert(adj[b], a)
						sets[b][a] = true
					end
				end
			end
		end
	end
	return adj
end

-- ════════════════════════════════════════════════════════════════════
-- MATRIZ TEÓRICA DESDE LevelsConfig.Adyacencias
-- ════════════════════════════════════════════════════════════════════
function GrafoHelpers.construirMatriz(adyacencias, nodos, esDirigido)
	local n = #nodos
	local nameToIdx = {}
	for i, nom in ipairs(nodos) do nameToIdx[nom] = i end

	local matrix = {}
	for i = 1, n do
		matrix[i] = {}
		for j = 1, n do matrix[i][j] = 0 end
	end

	for _, nomA in ipairs(nodos) do
		for _, nomB in ipairs(adyacencias[nomA] or {}) do
			local idxA = nameToIdx[nomA]
			local idxB = nameToIdx[nomB]
			if idxA and idxB then
				matrix[idxA][idxB] = 1
				if not esDirigido then
					matrix[idxB][idxA] = 1
				end
			end
		end
	end
	return matrix
end

return GrafoHelpers
