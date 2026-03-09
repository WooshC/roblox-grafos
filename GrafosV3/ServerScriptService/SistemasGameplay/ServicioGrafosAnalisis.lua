-- ServerScriptService/SistemasGameplay/ServicioGrafosAnalisis.lua
-- Proporciona el grafo COMPLETO de LevelsConfig al módulo de análisis.
-- A diferencia de MatrizAdyacencia, NO filtra por Hitboxes activos:
-- devuelve TODAS las aristas definidas en LevelsConfig.Adyacencias para la zona.
--
-- Responde a GetGrafoCompleto RemoteFunction:
--   InvokeServer(zonaID) → { Headers, Matrix, NombresNodos, EsDirigido }
--
-- El formato de respuesta es idéntico al de GetAdjacencyMatrix para que
-- buildAdyacencias() en el cliente funcione sin cambios.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LevelsConfig  = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("LevelsConfig"))
local GrafoHelpers  = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("GrafoHelpers"))

local Remotos = ReplicatedStorage
	:WaitForChild("EventosGrafosV3", 10)
	:WaitForChild("Remotos", 5)

local getGrafoCompletoFunc = Remotos:WaitForChild("GetGrafoCompleto", 10)

-- ═══════════════════════════════════════════════════════════════════
-- HANDLER
-- ═══════════════════════════════════════════════════════════════════

getGrafoCompletoFunc.OnServerInvoke = function(player, zonaID)
	if not zonaID or zonaID == "" then
		return { Headers = {}, Matrix = {}, NombresNodos = {}, EsDirigido = false, SinZona = true }
	end

	local nivelID      = player:GetAttribute("CurrentLevelID") or 0
	local config       = LevelsConfig[nivelID]
	local adyacencias  = config and config.Adyacencias or {}
	local nombresNodos = config and config.NombresNodos or {}

	local nodos = GrafoHelpers.nodosDeZona(adyacencias, zonaID, config)
	if #nodos == 0 then
		print(string.format("[ServicioGrafosAnalisis] Sin nodos para zona=%s nivel=%d", zonaID, nivelID))
		return { Headers = {}, Matrix = {}, NombresNodos = nombresNodos, EsDirigido = false }
	end

	local esDirigido = GrafoHelpers.detectarDirigido(adyacencias, nodos)

	local n         = #nodos
	local headers   = nodos
	local nameToIdx = {}
	for i, nom in ipairs(headers) do nameToIdx[nom] = i end

	local matrix = {}
	for i = 1, n do
		matrix[i] = {}
		for j = 1, n do matrix[i][j] = 0 end
	end

	-- Llenar con TODAS las aristas de LevelsConfig (sin filtrar por Hitboxes)
	for _, nomA in ipairs(nodos) do
		local listaA = adyacencias[nomA] or {}
		local idxA   = nameToIdx[nomA]

		for _, nomB in ipairs(listaA) do
			local idxB = nameToIdx[nomB]
			if not idxB then continue end

			matrix[idxA][idxB] = 1
			if not esDirigido then
				matrix[idxB][idxA] = 1
			end
		end
	end

	print(string.format("[ServicioGrafosAnalisis] Grafo completo %dx%d %s – %s (zona=%s)",
		n, n, esDirigido and "DÍGRAFO" or "NO DIRIGIDO", player.Name, zonaID))

	return {
		Headers      = headers,
		Matrix       = matrix,
		NombresNodos = nombresNodos,
		EsDirigido   = esDirigido,
	}
end

print("[ServicioGrafosAnalisis] Listo")
