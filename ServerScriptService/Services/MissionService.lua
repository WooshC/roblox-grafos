-- ServerScriptService/Services/MissionService.lua (CORREGIDO)
-- FIX: Ahora actualiza estrellas cuando se completan misiones

local MissionService = {}
MissionService.__index = MissionService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))

-- Estado interno
local playerMissions = {}   -- { [UserId] = { [MisionID] = boolean } }
local playerSelections = {}  -- { [UserId] = { [nodeName] = true } }
local updateEvent = nil

-- Dependencias
local levelService = nil
local graphService = nil

-- ============================================
-- VALIDADORES DE MISIONES (UNIVERSALES)
-- ============================================

local Validators = {}

-- Un nodo fue clickeado/seleccionado por el jugador
Validators.NODO_SELECCIONADO = function(params, estado)
	local nodo = params.Nodo
	if not nodo then return false end
	local selecciones = estado.nodosSeleccionados or {}
	return selecciones[nodo] == true
end

-- Existe un cable entre NodoA y NodoB
Validators.ARISTA_CREADA = function(params, estado)
	local nodoA = params.NodoA
	local nodoB = params.NodoB
	if not nodoA or not nodoB then return false end
	local conexiones = estado.conexionesActivas or {}
	-- Clave ordenada
	local k1 = nodoA < nodoB and (nodoA .. "_" .. nodoB) or (nodoB .. "_" .. nodoA)
	return conexiones[k1] == true
end

-- El nodo tiene >= GradoRequerido conexiones
Validators.GRADO_NODO = function(params, estado)
	local nodo = params.Nodo
	local requerido = params.GradoRequerido or 0
	if not nodo then return false end
	local grados = estado.gradoNodos or {}
	return (grados[nodo] or 0) >= requerido
end

-- Existe cable entre NodoOrigen y NodoDestino (para aristas dirigidas)
Validators.ARISTA_DIRIGIDA = function(params, estado)
	local origen = params.NodoOrigen
	local destino = params.NodoDestino
	if not origen or not destino then return false end
	local conexiones = estado.conexionesActivas or {}
	local k1 = origen < destino and (origen .. "_" .. destino) or (destino .. "_" .. origen)
	return conexiones[k1] == true
end

-- Todos los nodos de la lista son alcanzables entre sí (BFS)
Validators.GRAFO_CONEXO = function(params, estado)
	local nodos = params.Nodos or {}
	if #nodos == 0 then return false end
	local alcanzables = estado.alcanzablesDesde or {}
	-- Verificar que todos los nodos son alcanzables desde el primero
	local raiz = nodos[1]
	local alcDesdeRaiz = alcanzables[raiz] or {}
	for _, nodo in ipairs(nodos) do
		if not alcDesdeRaiz[nodo] then
			return false
		end
	end
	return true
end

-- Niveles normales
Validators.NODOS_MINIMOS = function(params, estado)
	return (estado.numNodosConectados or 0) >= (params.Cantidad or 0)
end

Validators.NODO_ENERGIZADO = function(params, estado)
	local nodo = params.Nodo
	return nodo and estado.nodosVisitados and estado.nodosVisitados[nodo] == true
end

Validators.TODOS_LOS_NODOS = function(params, estado)
	return (estado.numNodosConectados or 0) >= (params.Cantidad or 0) and estado.circuitoCerrado
end

Validators.ZONA_ACTIVADA = function(params, estado)
	local zona = params.Zona
	return zona and estado.zonasActivas and estado.zonasActivas[zona] == true
end

Validators.PRESUPUESTO_RESTANTE = function(params, estado)
	return (estado.dineroRestante or 0) >= (params.Cantidad or 0)
end

Validators.CONEXIONES_MINIMAS = function(params, estado)
	return (estado.numConexiones or 0) >= (params.Cantidad or 0)
end

Validators.NODOS_LISTA = function(params, estado)
	local nodos = params.Nodos or {}
	for _, nodo in ipairs(nodos) do
		if not estado.nodosVisitados or not estado.nodosVisitados[nodo] then
			return false
		end
	end
	return #nodos > 0
end

Validators.CIRCUITO_CERRADO = function(params, estado)
	return estado.circuitoCerrado == true
end

Validators.GASTO_MAXIMO = function(params, estado)
	local gastoMax = params.Cantidad or 0
	local gasto = (estado.dineroInicial or 0) - (estado.dineroRestante or 0)
	return gasto <= gastoMax
end

-- ============================================
-- INICIALIZACIÓN
-- ============================================

function MissionService:init()
	local Remotes = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes")

	updateEvent = Remotes:FindFirstChild("ActualizarMision")
	if not updateEvent then
		updateEvent = Instance.new("RemoteEvent")
		updateEvent.Name = "ActualizarMision"
		updateEvent.Parent = Remotes
	end

	Players.PlayerAdded:Connect(function(player)
		self:initializePlayer(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		self:clearPlayer(player)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		self:initializePlayer(player)
	end

	print("✅ MissionService inicializado (validadores universales)")
end

function MissionService:setDependencies(levelSvc, graphSvc)
	levelService = levelSvc
	graphService = graphSvc
end

-- ============================================
-- GESTIÓN DE JUGADORES
-- ============================================

function MissionService:initializePlayer(player)
	if playerMissions[player.UserId] then return end
	playerMissions[player.UserId] = {}
	playerSelections[player.UserId] = {}
end

function MissionService:clearPlayer(player)
	playerMissions[player.UserId] = nil
	playerSelections[player.UserId] = nil
end

function MissionService:resetMissions(player)
	if not player then return end
	playerMissions[player.UserId] = {}
	playerSelections[player.UserId] = {}

	if updateEvent then
		-- Enviar reset de todas las misiones posibles
		local config = levelService and levelService:getLevelConfig()
		local total = config and config.Misiones and #config.Misiones or 8
		for i = 1, total do
			updateEvent:FireClient(player, i, false)
		end
	end
end

-- ============================================
-- REGISTRO DE SELECCIÓN DE NODOS
-- ============================================

function MissionService:registerNodeSelection(player, nodeName)
	if not player or not nodeName then return end
	local sels = playerSelections[player.UserId]
	if not sels then
		playerSelections[player.UserId] = {}
		sels = playerSelections[player.UserId]
	end
	sels[nodeName] = true

	-- Marcar todos los nodos de la misma zona como seleccionados
	local config = levelService and levelService:getLevelConfig()
	if config and config.Nodos and config.Nodos[nodeName] then
		local zona = config.Nodos[nodeName].Zona
		if zona then
			for otroNodo, otroData in pairs(config.Nodos) do
				if otroData.Zona == zona then
					sels[otroNodo] = true
				end
			end
		end
	end

	-- Re-verificar misiones
	self:checkMissions(player)
end

-- ============================================
-- CONSTRUIR ESTADO DEL JUEGO (Universal)
-- ============================================

function MissionService:buildFullGameState(player)
	local estado = {
		nodosSeleccionados = playerSelections[player.UserId] or {},
		conexionesActivas = {},   -- { ["NodoA_NodoB"] = true }
		gradoNodos = {},          -- { ["Nodo"] = number }
		alcanzablesDesde = {},    -- { ["Nodo"] = { ["OtroNodo"] = true } }
		nodosVisitados = {},
		numNodosConectados = 0,
		numConexiones = 0,
		circuitoCerrado = false,
		dineroRestante = 0,
		dineroInicial = 0,
		zonasActivas = {},
	}

	if not graphService or not levelService then return estado end

	local config = levelService:getLevelConfig()
	if not config then return estado end

	estado.dineroInicial = config.DineroInicial or 0

	if player:FindFirstChild("leaderstats") then
		local money = player.leaderstats:FindFirstChild("Money")
		if money then estado.dineroRestante = money.Value end
	end

	-- Construir conexiones activas y grados
	local cables = graphService:getCables()
	local gradoCount = {}

	for key, cableInfo in pairs(cables) do
		local nA = cableInfo.nodeA.Name
		local nB = cableInfo.nodeB.Name
		local clave = nA < nB and (nA .. "_" .. nB) or (nB .. "_" .. nA)
		estado.conexionesActivas[clave] = true
		estado.numConexiones = estado.numConexiones + 1

		gradoCount[nA] = (gradoCount[nA] or 0) + 1
		gradoCount[nB] = (gradoCount[nB] or 0) + 1
	end
	estado.gradoNodos = gradoCount

	-- Nodos conectados (tienen al menos 1 cable)
	local nodosConConexion = {}
	for nodo, grado in pairs(gradoCount) do
		if grado > 0 then
			nodosConConexion[nodo] = true
			estado.numNodosConectados = estado.numNodosConectados + 1
		end
	end

	-- Calcular alcanzables desde cada nodo (para GRAFO_CONEXO)
	local GraphUtils = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"):WaitForChild("GraphUtils"))
	local nodos = graphService:getNodes()

	for _, nodo in ipairs(nodos) do
		local alcanzables = GraphUtils.bfs(nodo, cables)
		estado.alcanzablesDesde[nodo.Name] = alcanzables
	end

	-- Nodos energizados (para niveles con energía)
	local startNode = levelService:getStartNode()
	local endNode = levelService:getEndNode()
	if startNode then
		local EnergyService = _G.Services and _G.Services.Energy
		if EnergyService then
			estado.nodosVisitados = EnergyService:calculateEnergy(startNode)
		end
	end

	-- Circuito cerrado
	if startNode and endNode and estado.nodosVisitados then
		estado.circuitoCerrado = estado.nodosVisitados[endNode.Name] == true
	end

	return estado
end

-- ============================================
-- VERIFICACIÓN DE MISIONES
-- ============================================

function MissionService:checkMissions(player, gameStateOverride)
	if not player or not levelService then return end

	local config = levelService:getLevelConfig()
	if not config or not config.Misiones then return end

	local playerState = playerMissions[player.UserId]
	if not playerState then
		self:initializePlayer(player)
		playerState = playerMissions[player.UserId]
	end

	-- Construir estado completo si no se proporcionó uno
	local estado = gameStateOverride or self:buildFullGameState(player)

	for _, missionConfig in ipairs(config.Misiones) do
		local missionId = missionConfig.ID

		if not playerState[missionId] then
			local tipo = missionConfig.Tipo
			local validator = Validators[tipo]

			if not validator then
				warn("⚠️ MissionService: Tipo desconocido: " .. tostring(tipo))
			else
				local params = missionConfig.Parametros or {}
				local ok, result = pcall(validator, params, estado)

				if ok and result == true then
					self:completeMission(player, missionId)
				elseif not ok then
					warn("⚠️ MissionService: Error en misión " .. missionId .. ": " .. tostring(result))
				end
			end
		end
	end

	-- Verificar condición de victoria
	self:checkVictoryCondition(player)
end

--- Llamar cuando cambian cables (para todos los jugadores)
function MissionService:onConnectionChanged()
	for _, player in ipairs(Players:GetPlayers()) do
		self:checkMissions(player)
	end
end

-- ============================================
-- VICTORIA
-- ============================================

function MissionService:checkVictoryCondition(player)
	if not levelService then return false end

	local config = levelService:getLevelConfig()
	if not config then return false end

	local condicion = config.CondicionVictoria or "CIRCUITO_CERRADO"
	local victoria = false

	if condicion == "ZONAS_COMPLETAS" then
		victoria = self:areAllZonesComplete(player)
	elseif condicion == "CIRCUITO_CERRADO" then
		local estado = self:buildFullGameState(player)
		victoria = estado.circuitoCerrado
	end

	if victoria then
		-- Notificar (el botón finalizar aparece automáticamente)
		player:SetAttribute("NivelCompletable", true)
		print("🏆 MissionService: " .. player.Name .. " cumple condición de victoria (" .. condicion .. ")")
	else
		player:SetAttribute("NivelCompletable", false)
	end

	return victoria
end

--- Verifica si todas las zonas tienen sus misiones completadas
function MissionService:areAllZonesComplete(player)
	if not levelService then return false end

	local config = levelService:getLevelConfig()
	if not config or not config.Zonas or not config.Misiones then return false end

	local playerState = playerMissions[player.UserId] or {}

	for zonaID, _ in pairs(config.Zonas) do
		-- Verificar que TODAS las misiones de esta zona estén completadas
		local zonaTieneMisiones = false
		for _, mision in ipairs(config.Misiones) do
			if mision.Zona == zonaID then
				zonaTieneMisiones = true
				if not playerState[mision.ID] then
					return false -- Falta al menos una misión
				end
			end
		end
		if not zonaTieneMisiones then
			-- Zona sin misiones = se considera completa
		end
	end

	return true
end

--- Obtiene misiones filtradas por zona
function MissionService:getMissionsByZone(zonaID)
	if not levelService then return {} end
	local config = levelService:getLevelConfig()
	if not config or not config.Misiones then return {} end

	local resultado = {}
	for _, mision in ipairs(config.Misiones) do
		if mision.Zona == zonaID or (zonaID == nil and mision.Zona == nil) then
			table.insert(resultado, mision)
		end
	end
	return resultado
end

--- Obtiene estado de zona (% completada)
function MissionService:getZoneProgress(player, zonaID)
	if not levelService then return 0, 0 end
	local config = levelService:getLevelConfig()
	if not config or not config.Misiones then return 0, 0 end

	local playerState = playerMissions[player.UserId] or {}
	local total = 0
	local completadas = 0

	for _, mision in ipairs(config.Misiones) do
		if mision.Zona == zonaID then
			total = total + 1
			if playerState[mision.ID] then
				completadas = completadas + 1
			end
		end
	end

	return completadas, total
end

-- ============================================
-- COMPLETAR MISIÓN (CORREGIDO)
-- ============================================

function MissionService:completeMission(player, missionId)
	local playerState = playerMissions[player.UserId]
	if not playerState then return end
	if playerState[missionId] then return end

	playerState[missionId] = true

	if updateEvent then
		updateEvent:FireClient(player, missionId, true)
	end

	print("🎉 Misión " .. missionId .. " completada por " .. player.Name)

	-- 🔥 OBTENER CONFIG Y SUMAR PUNTOS
	if levelService then
		local config = levelService:getLevelConfig()
		if config and config.Misiones then
			for _, mc in ipairs(config.Misiones) do
				if mc.ID == missionId and (mc.Puntos or 0) > 0 then
					local ls = player:FindFirstChild("leaderstats")
					if ls then
						local puntos = ls:FindFirstChild("Puntos")
						if puntos then
							puntos.Value = puntos.Value + mc.Puntos
							print("💰 +" .. mc.Puntos .. " pts (Total: " .. puntos.Value .. ")")
							
							-- 🔥 NUEVA: Calcular y actualizar estrellas automáticamente
							local estrellas = ls:FindFirstChild("Estrellas")
							if estrellas then
								local nuevasEstrellas = self:_calcularEstrellas(puntos.Value, levelService:getCurrentLevelID())
								if nuevasEstrellas ~= estrellas.Value then
									estrellas.Value = nuevasEstrellas
									print("⭐ Estrellas actualizadas a: " .. nuevasEstrellas)
								end
							end
						end
					end
					break
				end
			end
		end
	end
end

-- 🔥 NUEVA FUNCIÓN: Calcular estrellas
function MissionService:_calcularEstrellas(puntos, nivelID)
	local config = LevelsConfig[nivelID]
	if not config or not config.Puntuacion then
		return 0
	end

	local p = config.Puntuacion
	if puntos >= (p.TresEstrellas or math.huge) then return 3 end
	if puntos >= (p.DosEstrellas or math.huge) then return 2 end
	if puntos > 0 then return 1 end
	return 0
end

function MissionService:getMissionStatus(player, missionId)
	local ps = playerMissions[player.UserId]
	if not ps then return false end
	return ps[missionId] == true
end

return MissionService