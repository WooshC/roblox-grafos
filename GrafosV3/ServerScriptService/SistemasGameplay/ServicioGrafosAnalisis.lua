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

	local matrix = GrafoHelpers.construirMatriz(adyacencias, nodos, esDirigido)

	print(string.format("[ServicioGrafosAnalisis] Grafo completo %dx%d %s – %s (zona=%s)",
		#nodos, #nodos, esDirigido and "DÍGRAFO" or "NO DIRIGIDO", player.Name, zonaID))

	-- Nodos danados de esta zona
	local nodosDaniados = {}
	if config and config.Zonas and config.Zonas[zonaID] and config.Zonas[zonaID].NodosDaniados then
		for _, nom in ipairs(config.Zonas[zonaID].NodosDaniados) do
			if table.find(nodos, nom) then
				table.insert(nodosDaniados, nom)
			end
		end
	end

	-- Cables defectuosos como set de claves canónicas
	local defectuososSet = GrafoHelpers.defectuososSet(config)

	return {
		Headers       = nodos,
		Matrix        = matrix,
		NombresNodos  = nombresNodos,
		EsDirigido    = esDirigido,
		NodosDaniados = nodosDaniados,
		PesosAristas  = config and config.PesosAristas or {},
		CostoPorMetro = config and config.CostoPorMetro or 0,
		Defectuosos   = defectuososSet,
	}
end

print("[ServicioGrafosAnalisis] Listo")
