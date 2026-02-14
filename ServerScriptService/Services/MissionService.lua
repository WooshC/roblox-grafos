-- ServerScriptService/Services/MissionService.lua
-- SERVICIO CENTRALIZADO para gestión de Misiones
-- Reemplaza a MisionManager (ReplicatedStorage)
-- Maneja validación de objetivos y estado de misiones por jugador

local MissionService = {}
MissionService.__index = MissionService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))

-- Estado interno
local playerMissions = {} -- { [UserId] = { [MisionID] = boolean } }
local updateEvent = nil

-- Dependencias
local levelService = nil

-- ============================================
-- VALIDADORES DE MISIONES
-- ============================================
local Validators = {
	NODOS_MINIMOS = function(params, estado)
		local cantidad = params.Cantidad or 0
		return (estado.numNodosConectados or 0) >= cantidad
	end,

	NODO_ENERGIZADO = function(params, estado)
		local nodo = params.Nodo
		if not nodo then return false end
		return estado.nodosVisitados and estado.nodosVisitados[nodo] == true
	end,

	TODOS_LOS_NODOS = function(params, estado)
		local cantidad = params.Cantidad or 0
		return (estado.numNodosConectados or 0) >= cantidad and estado.circuitoCerrado
	end,

	ZONA_ACTIVADA = function(params, estado)
		local zona = params.Zona
		if not zona then return false end
		return estado.zonasActivas and estado.zonasActivas[zona] == true
	end,

	PRESUPUESTO_RESTANTE = function(params, estado)
		local cantidad = params.Cantidad or 0
		return (estado.dineroRestante or 0) >= cantidad
	end,

	CONEXIONES_MINIMAS = function(params, estado)
		local cantidad = params.Cantidad or 0
		return (estado.numConexiones or 0) >= cantidad
	end,

	NODOS_LISTA = function(params, estado)
		local nodos = params.Nodos or {}
		for _, nodo in ipairs(nodos) do
			if not estado.nodosVisitados or not estado.nodosVisitados[nodo] then
				return false
			end
		end
		return #nodos > 0
	end,

	CIRCUITO_CERRADO = function(params, estado)
		return estado.circuitoCerrado == true
	end,

	GASTO_MAXIMO = function(params, estado)
		local gastoMaximo = params.Cantidad or 0
		local dineroInicial = estado.dineroInicial or 0
		local gastoActual = dineroInicial - (estado.dineroRestante or 0)
		return gastoActual <= gastoMaximo
	end
}

-- ============================================
-- INICIALIZACIÓN
-- ============================================

function MissionService:init()
	-- Configurar eventos remotos
	local Remotes = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes")

	updateEvent = Remotes:FindFirstChild("ActualizarMision")
	if not updateEvent then
		updateEvent = Instance.new("RemoteEvent")
		updateEvent.Name = "ActualizarMision"
		updateEvent.Parent = Remotes
	end

	-- Conectar eventos de jugadores
	Players.PlayerAdded:Connect(function(player)
		self:initializePlayer(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:clearPlayer(player)
	end)

	-- Inicializar jugadores actuales
	for _, player in ipairs(Players:GetPlayers()) do
		self:initializePlayer(player)
	end

	print("✅ MissionService inicializado")
end

function MissionService:setDependencies(levelSvc)
	levelService = levelSvc
end

-- ============================================
-- GESTIÓN DE JUGADORES
-- ============================================

function MissionService:initializePlayer(player)
	if playerMissions[player.UserId] then return end

	-- Inicializar todas las posibles misiones como falsas
	playerMissions[player.UserId] = {}
	print("✅ MissionService: Jugador " .. player.Name .. " inicializado")
end

function MissionService:clearPlayer(player)
	playerMissions[player.UserId] = nil
end

function MissionService:resetMissions(player)
	if not player then return end

	-- Reiniciar estado
	playerMissions[player.UserId] = {}

	-- Notificar al cliente que todas las misiones se resetearon (podríamos enviar un evento de reset)
	-- Por compatibilidad con el sistema anterior, actualizamos las primeras 8 a false
	if updateEvent then
		for i = 1, 8 do
			updateEvent:FireClient(player, i, false)
		end
	end

	print("🔄 MissionService: Misiones reseteadas para " .. player.Name)
end

-- ============================================
-- LOGICA DE MISIONES
-- ============================================

-- Verifica todas las misiones del nivel actual para un jugador dado el estado del juego
function MissionService:checkMissions(player, gameState)
	if not player or not levelService then return end

	local levelConfig = levelService:getLevelConfig()
	if not levelConfig or not levelConfig.Misiones then return end

	local playerState = playerMissions[player.UserId]
	if not playerState then
		self:initializePlayer(player)
		playerState = playerMissions[player.UserId]
	end

	for _, missionConfig in ipairs(levelConfig.Misiones) do
		local missionId = missionConfig.ID

		-- Si ya está completada, no hacer nada (o verificar si se puede 'perder' el estado)
		-- Asumimos que una vez completada, se queda completada hasta el reset
		if not playerState[missionId] then
			local isCompleted = self:validateMission(missionConfig, gameState)

			if isCompleted then
				self:completeMission(player, missionId)
			end
		end
	end
end

-- Valida una misión individual
function MissionService:validateMission(missionConfig, gameState)
	local tipo = missionConfig.Tipo
	local validator = Validators[tipo]

	if not validator then
		warn("⚠️ MissionService: Tipo de misión desconocido: " .. tostring(tipo))
		return false
	end

	local params = missionConfig.Parametros or {}
	local success, result = pcall(validator, params, gameState)

	if not success then
		warn("⚠️ MissionService: Error validando misión " .. tostring(missionConfig.ID) .. ": " .. tostring(result))
		return false
	end

	return result == true
end

-- Marca una misión como completada
function MissionService:completeMission(player, missionId)
	local playerState = playerMissions[player.UserId]
	if not playerState then return end

	if not playerState[missionId] then
		playerState[missionId] = true

		-- Notificar al cliente
		if updateEvent then
			updateEvent:FireClient(player, missionId, true)
		end

		print("🎉 MissionService: Jugador " .. player.Name .. " completó misión " .. missionId)

		-- ✅ AGREGAR PUNTOS AUTOMÁTICAMENTE DESDE LA MISIÓN
		if levelService then
			local config = levelService:getLevelConfig()
			if config and config.Misiones then
				-- Buscar la configuración de esta misión
				for _, missionConfig in ipairs(config.Misiones) do
					if missionConfig.ID == missionId then
						-- Obtener puntos de la misión (si existen en config)
						local puntosBonus = missionConfig.Puntos or 0
						
						if puntosBonus > 0 then
							-- Sumar puntos al jugador
							local leaderstats = player:FindFirstChild("leaderstats")
							if leaderstats then
								local puntos = leaderstats:FindFirstChild("Puntos")
								if puntos then
									puntos.Value = puntos.Value + puntosBonus
									print("💰 MissionService: +" .. puntosBonus .. " pts a " .. player.Name .. 
										" por misión " .. missionId .. " (Total: " .. puntos.Value .. ")")
								else
									warn("⚠️ MissionService: No hay IntValue 'Puntos' en leaderstats de " .. player.Name)
								end
							else
								warn("⚠️ MissionService: No hay leaderstats para " .. player.Name)
							end
						else
							print("ℹ️ MissionService: Misión " .. missionId .. " no tiene puntos configurados")
						end
						break
					end
				end
			end
		else
			warn("⚠️ MissionService: levelService no está inicializado")
		end
	end
end

-- Obtiene el estado de una misión específica
function MissionService:getMissionStatus(player, missionId)
	local playerState = playerMissions[player.UserId]
	if not playerState then return false end
	return playerState[missionId] == true
end

-- ============================================
-- UTILIDADES
-- ============================================

-- Construye el objeto gameState necesario para las validaciones
function MissionService:buildGameState(player, visitados, connectedCount, circuitClosed, activeZones)
	local gameState = {
		nodosVisitados = visitados or {},
		numNodosConectados = connectedCount or 0,
		circuitoCerrado = circuitClosed or false,
		dineroRestante = 0,
		dineroInicial = 0,
		numConexiones = 0, -- TODO: Obtener del GraphService
		zonasActivas = activeZones or {}
	}

	if levelService then
		local config = levelService:getLevelConfig()
		gameState.dineroInicial = config and config.DineroInicial or 0
	end

	if player and player:FindFirstChild("leaderstats") then
		local money = player.leaderstats:FindFirstChild("Money")
		if money then
			gameState.dineroRestante = money.Value
		end
	end

	return gameState
end

return MissionService
