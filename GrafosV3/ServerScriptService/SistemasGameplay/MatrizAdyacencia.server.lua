-- ServerScriptService/SistemasGameplay/MatrizAdyacencia.server.lua
-- Proporciona la Matriz de Adyacencia del grafo activo al cliente.
-- Tipo: Script (servidor) — se auto-ejecuta, no require.
--
-- Responde a GetAdjacencyMatrix RemoteFunction:
--   InvokeServer(zonaID)  →  { Headers, Matrix, NombresNodos, EsDirigido }
--
-- Fuente de nodos: LevelsConfig.Adyacencias (no escanea el workspace para nodos).
-- Dirección: detectada automáticamente — si alguna arista A→B no tiene reversa B→A
--   en los nodos de la zona, el grafo se trata como dígrafo.
-- Conexiones activas: lee Hitbox_NomA|NomB del workspace (estado real).
-- Filtro de zona: "Zona_Estacion_3" → sufijo "_z3" en claves de Adyacencias.
-- Requisito: zonaID debe ser no-nil y no-vacío; si es nil devuelve SinZona=true.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local LevelsConfig  = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("LevelsConfig"))
local GrafoHelpers  = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("GrafoHelpers"))
local ValidadorConexiones = require(script.Parent:WaitForChild("ValidadorConexiones"))

local Remotos = ReplicatedStorage
	:WaitForChild("EventosGrafosV3", 10)
	:WaitForChild("Remotos", 5)

local getMatrixFunc = Remotos:WaitForChild("GetAdjacencyMatrix", 10)

-- ═══════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════

-- Recolecta conexiones activas buscando Hitbox_* en todas las carpetas Conexiones.
-- Retorna: set { [clavePar] = true }
local function recolectarConexiones(nivelActual)
	local conexiones = {}
	local grafosFolder = nivelActual:FindFirstChild("Grafos")
	if not grafosFolder then return conexiones end

	for _, grafo in ipairs(grafosFolder:GetChildren()) do
		local carpeta = grafo:FindFirstChild("Conexiones")
		if not carpeta then continue end

		for _, child in ipairs(carpeta:GetChildren()) do
			-- Hitbox_NomA|NomB  (creado por ConectarCables)
			local clave = child.Name:match("^Hitbox_(.+)$")
			if clave then
				-- Normalizar la clave para no depender del orden A|B o B|A
				local a, b = GrafoHelpers.parsearClave(clave)
				if a and b then
					conexiones[GrafoHelpers.clavePar(a, b)] = true
				else
					conexiones[clave] = true
				end
			end
		end
	end

	return conexiones
end

-- ═══════════════════════════════════════════════════════════════════
-- HANDLER PRINCIPAL
-- ═══════════════════════════════════════════════════════════════════

getMatrixFunc.OnServerInvoke = function(player, zonaID)
	-- Requerir zona activa no vacía
	if not zonaID or zonaID == "" then
		return { Headers = {}, Matrix = {}, NombresNodos = {}, EsDirigido = false, SinZona = true }
	end

	local nivelActual = Workspace:FindFirstChild("NivelActual")
	if not nivelActual then
		warn("[MatrizAdyacencia] NivelActual no encontrado")
		return { Headers = {}, Matrix = {}, NombresNodos = {}, EsDirigido = false }
	end

	local nivelID      = player:GetAttribute("CurrentLevelID") or 0
	local config       = LevelsConfig[nivelID]
	local adyacencias  = config and config.Adyacencias or {}
	local nombresNodos = config and config.NombresNodos or {}

	-- 1. Obtener nodos de la zona desde LevelsConfig
	local nodos = GrafoHelpers.nodosDeZona(adyacencias, zonaID, config)
	if #nodos == 0 then
		print(string.format("[MatrizAdyacencia] Sin nodos para zona=%s nivel=%d", zonaID, nivelID))
		return { Headers = {}, Matrix = {}, NombresNodos = nombresNodos, EsDirigido = false }
	end

	-- 2. Detectar si el grafo de esta zona es dirigido
	local esDirigido = GrafoHelpers.detectarDirigido(adyacencias, nodos)

	-- 3. Construir headers y mapa nombre→índice
	local n         = #nodos
	local headers   = nodos
	local nameToIdx = {}
	for i, nom in ipairs(headers) do nameToIdx[nom] = i end

	local matrix = {}
	for i = 1, n do
		matrix[i] = {}
		for j = 1, n do matrix[i][j] = 0 end
	end

	-- 4. Leer conexiones activas del nivel (estado real del jugador)
	local conexiones = recolectarConexiones(nivelActual)

	-- 5. Llenar la matriz según adyacencias + Hitboxes activas.
	--    Para cada arista A→B definida en LevelsConfig: si hay un Hitbox activo
	--    → matrix[A][B] = 1.
	--    Dígrafo: NO se marca la celda simétrica.
	--    No dirigido: se marca también matrix[B][A].
	--    El estado defectuoso va en un campo separado (Defectuosos), no en el peso.
	local defectuososSet = {}
	for _, nomA in ipairs(nodos) do
		local listaA = adyacencias[nomA] or {}
		local idxA   = nameToIdx[nomA]

		for _, nomB in ipairs(listaA) do
			local idxB = nameToIdx[nomB]
			if not idxB then continue end  -- nomB está fuera de esta zona

			local clave = GrafoHelpers.clavePar(nomA, nomB)
			if conexiones[clave] then
				if ValidadorConexiones.esCableDefectuoso(nomA, nomB) then
					defectuososSet[clave] = true
				end

				local peso = GrafoHelpers.obtenerPeso(config, nomA, nomB, 1)
				matrix[idxA][idxB] = peso
				if not esDirigido then
					matrix[idxB][idxA] = peso
				end
			end
		end
	end

	print(string.format("[MatrizAdyacencia] %dx%d %s – %s (zona=%s)",
		n, n, esDirigido and "DÍGRAFO" or "NO DIRIGIDO", player.Name, zonaID))

	-- Nodos danados de esta zona
	local nodosDaniados = {}
	if config and config.Zonas and config.Zonas[zonaID] and config.Zonas[zonaID].NodosDaniados then
		for _, nom in ipairs(config.Zonas[zonaID].NodosDaniados) do
			if table.find(nodos, nom) then
				table.insert(nodosDaniados, nom)
			end
		end
	end

	return {
		Headers       = headers,
		Matrix        = matrix,
		NombresNodos  = nombresNodos,
		EsDirigido    = esDirigido,
		NodosDaniados = nodosDaniados,
		PesosAristas  = config and config.PesosAristas or {},
		CostoPorMetro = config and config.CostoPorMetro or 0,
		Defectuosos   = defectuososSet,
	}
end

print("[MatrizAdyacencia] Listo")
