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

local Remotos = ReplicatedStorage
	:WaitForChild("EventosGrafosV3", 10)
	:WaitForChild("Remotos", 5)

local getMatrixFunc = Remotos:WaitForChild("GetAdjacencyMatrix", 10)

-- ═══════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════

-- Recolecta conexiones activas buscando Hitbox_* en todas las carpetas Conexiones.
-- Retorna: set { ["NomA|NomB"] = true }
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
				conexiones[clave] = true
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
	
	-- 4.5 Detectar defectuosos
	local cablesDefectuosos = {}
	if config.CablesDefectuosos then
		for _, par in ipairs(config.CablesDefectuosos) do
			cablesDefectuosos[par[1] .. "|" .. par[2]] = true
			cablesDefectuosos[par[2] .. "|" .. par[1]] = true
		end
	end

	-- 5. Llenar la matriz según adyacencias + Hitboxes activos.
	--    Para cada arista A→B definida en LevelsConfig: si hay un Hitbox activo
	--    (en cualquier orden de nombres) → matrix[A][B] = 1.
	--    Dígrafo: NO se marca la celda simétrica.
	--    No dirigido: se marca también matrix[B][A] (la simetría ya viene de la config).
	for _, nomA in ipairs(nodos) do
		local listaA = adyacencias[nomA] or {}
		local idxA   = nameToIdx[nomA]

		for _, nomB in ipairs(listaA) do
			local idxB = nameToIdx[nomB]
			if not idxB then continue end  -- nomB está fuera de esta zona

			-- ConectarCables puede crear el Hitbox en cualquier orden
			local claveAB   = nomA .. "|" .. nomB
			local claveBA   = nomB .. "|" .. nomA
			local conectado = conexiones[claveAB] or conexiones[claveBA]

			if conectado then
				local esDefectuoso = cablesDefectuosos[claveAB] or cablesDefectuosos[claveBA]
				local val = esDefectuoso and 2 or 1
				
				matrix[idxA][idxB] = val
				if not esDirigido then
					-- Grafo no dirigido: la celda simétrica también va a 1 o 2
					matrix[idxB][idxA] = val
				end
			end
		end
	end

	print(string.format("[MatrizAdyacencia] %dx%d %s – %s (zona=%s)",
		n, n, esDirigido and "DÍGRAFO" or "NO DIRIGIDO", player.Name, zonaID))

	return {
		Headers      = headers,
		Matrix       = matrix,
		NombresNodos = nombresNodos,
		EsDirigido   = esDirigido,
	}
end

print("[MatrizAdyacencia] Listo")
