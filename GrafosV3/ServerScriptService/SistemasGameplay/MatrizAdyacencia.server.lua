-- ServerScriptService/SistemasGameplay/MatrizAdyacencia.server.lua
-- Proporciona la Matriz de Adyacencia del grafo activo al cliente.
-- Tipo: Script (servidor) — se auto-ejecuta, no require.
--
-- Responde a GetAdjacencyMatrix RemoteFunction:
--   InvokeServer(zonaID?)  →  { Headers, Matrix, NombresNodos }
--
-- Escanea NivelActual en tiempo real, sin estado interno adicional.
-- Filtro de zona: si zonaID (e.g. "Zona_Estacion_1") se envía, solo
-- incluye nodos cuyo nombre termina en "_z<N>" correspondiente.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local LevelsConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("LevelsConfig"))

local Remotos = ReplicatedStorage
	:WaitForChild("EventosGrafosV3", 10)
	:WaitForChild("Remotos", 5)

local getMatrixFunc = Remotos:WaitForChild("GetAdjacencyMatrix", 10)

-- ═══════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════

-- Determina si un nodo pertenece a la zona filtrada.
-- Estrategia 1: atributo "Zona" en el grafo folder (Studio).
-- Estrategia 2: sufijo "_z<N>" en el nombre del nodo vs "_<N>" final de zonaID.
local function nodoEnZona(nodeName, grafoZona, zonaID)
	if not zonaID or zonaID == "" then return true end

	-- Estrategia 1: el grafo folder tiene atributo Zona declarado
	if grafoZona then
		return grafoZona == zonaID
	end

	-- Estrategia 2: "Zona_Estacion_1" → buscar "_z1$" en el nombre del nodo
	local zonaNum = zonaID:match("_(%d+)$")
	if not zonaNum then return true end  -- formato desconocido: incluir todo
	return nodeName:find("_z" .. zonaNum .. "$") ~= nil
end

-- Recolecta todos los nodos (Models) del nivel, con filtro de zona opcional.
local function recolectarNodos(nivelActual, zonaID)
	local nodos = {}
	local grafosFolder = nivelActual:FindFirstChild("Grafos")
	if not grafosFolder then return nodos end

	for _, grafo in ipairs(grafosFolder:GetChildren()) do
		local grafoZona = grafo:GetAttribute("Zona")  -- puede ser nil

		-- Si hay atributo Zona en el folder y no coincide, saltamos el grafo completo
		if zonaID and zonaID ~= "" and grafoZona and grafoZona ~= zonaID then
			continue
		end

		local nodosFolder = grafo:FindFirstChild("Nodos")
		if not nodosFolder then continue end

		for _, nodo in ipairs(nodosFolder:GetChildren()) do
			if nodo:IsA("Model") then
				-- Solo filtrar por nombre si el grafo no tiene atributo Zona
				if nodoEnZona(nodo.Name, grafoZona, zonaID) then
					table.insert(nodos, nodo)
				end
			end
		end
	end

	return nodos
end

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
	local nivelActual = Workspace:FindFirstChild("NivelActual")
	if not nivelActual then
		warn("[MatrizAdyacencia] NivelActual no encontrado")
		return { Headers = {}, Matrix = {}, NombresNodos = {} }
	end

	local nivelID      = player:GetAttribute("CurrentLevelID") or 0
	local config       = LevelsConfig[nivelID]
	local nombresNodos = config and config.NombresNodos or {}

	-- 1. Recolectar y ordenar nodos
	local nodos = recolectarNodos(nivelActual, zonaID)
	if #nodos == 0 then
		print(string.format("[MatrizAdyacencia] Sin nodos (zona=%s nivel=%d)", tostring(zonaID), nivelID))
		return { Headers = {}, Matrix = {}, NombresNodos = nombresNodos }
	end

	table.sort(nodos, function(a, b) return a.Name < b.Name end)

	local n        = #nodos
	local headers  = {}
	local nameToIdx = {}
	local matrix   = {}

	for i, nodo in ipairs(nodos) do
		headers[i]          = nodo.Name
		nameToIdx[nodo.Name] = i
		matrix[i] = {}
		for j = 1, n do matrix[i][j] = 0 end
	end

	-- 2. Llenar matriz con conexiones activas
	local conexiones = recolectarConexiones(nivelActual)
	for clave in pairs(conexiones) do
		local nomA, nomB = clave:match("^(.+)|(.+)$")
		local idxA = nameToIdx[nomA]
		local idxB = nameToIdx[nomB]
		if idxA and idxB then
			matrix[idxA][idxB] = 1
			matrix[idxB][idxA] = 1
		end
	end

	print(string.format("[MatrizAdyacencia] %dx%d para %s (zona=%s)",
		n, n, player.Name, tostring(zonaID)))

	return {
		Headers     = headers,
		Matrix      = matrix,
		NombresNodos = nombresNodos,
	}
end

print("[MatrizAdyacencia] Listo")
