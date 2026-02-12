-- ManagerData.server.lua
-- Maneja el guardado de progreso (Niveles, Estrellas, Puntajes, Inventario) y la carga de niveles.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))
local NivelUtils = require(ReplicatedStorage:WaitForChild("Utilidades"):WaitForChild("NivelUtils"))

local MainStore = DataStoreService:GetDataStore("PlayerData_v4_Levels") -- Incrementamos versión para limpiar datos viejos

-- ============================================
-- EVENTOS Y CARPETAS
-- ============================================
local EventsFolder = ReplicatedStorage:FindFirstChild("Events") or Instance.new("Folder", ReplicatedStorage)
EventsFolder.Name = "Events"

local RemotesFolder = EventsFolder:FindFirstChild("Remotes") or Instance.new("Folder", EventsFolder)
RemotesFolder.Name = "Remotes"

-- Función para que el cliente pida sus datos de progreso
local GetProgressFunc = RemotesFolder:FindFirstChild("GetPlayerProgress") or Instance.new("RemoteFunction", RemotesFolder)
GetProgressFunc.Name = "GetPlayerProgress"

-- Evento para que el cliente pida jugar un nivel
local RequestPlayEvent = RemotesFolder:FindFirstChild("RequestPlayLevel") or Instance.new("RemoteEvent", RemotesFolder)
RequestPlayEvent.Name = "RequestPlayLevel"

-- Cache en memoria de los datos de jugadores
local SessionData = {}

-- ============================================
-- CONFIGURACIÓN DE DATOS DEFAULT
-- ============================================
local DEFAULT_DATA = {
	-- Progreso por nivel
	Levels = {
		["0"] = { Unlocked = true, Stars = 0, HighScore = 0 }, -- Tutorial siempre abierto
		["1"] = { Unlocked = false, Stars = 0, HighScore = 0 },
		["2"] = { Unlocked = false, Stars = 0, HighScore = 0 },
		["3"] = { Unlocked = false, Stars = 0, HighScore = 0 },
		["4"] = { Unlocked = false, Stars = 0, HighScore = 0 }
	},
	-- Objetos coleccionables globales (Mapa, Algoritmos, etc.)
	Inventory = {} 
}

-- ============================================
-- GESTIÓN DE DATOS (LOAD/SAVE)
-- ============================================

local function loadData(player)
	local success, data = pcall(function()
		return MainStore:GetAsync("User_" .. player.UserId)
	end)

	if not success then
		warn("⚠️ Error cargando datos para " .. player.Name)
		data = nil
	end
	
	-- Deep Merge con Defaults (para asegurar que existan todos los campos)
	data = data or {}
	
	if not data.Levels then data.Levels = {} end
	if not data.Inventory then data.Inventory = {} end

	-- Asegurar que todos los niveles del config existan en la data
	for i = 0, 4 do -- Asumiendo niveles 0 a 4
		local sID = tostring(i)
		if not data.Levels[sID] then
			data.Levels[sID] = { 
				Unlocked = (i == 0), -- Solo el 0 desbloqueado por defecto
				Stars = 0, 
				HighScore = 0 
			}
		end
	end

	SessionData[player.UserId] = data
	return data
end

local function saveData(player)
	local data = SessionData[player.UserId]
	if not data then return end

	local success, err = pcall(function()
		MainStore:SetAsync("User_" .. player.UserId, data)
	end)

	if success then
		print("💾 Progreso guardado para " .. player.Name)
	else
		warn("❌ Error guardando datos: " .. tostring(err))
	end
end

-- ============================================
-- API PARA EL CLIENTE (REMOTES)
-- ============================================

-- El cliente pide "Dame mi progreso para pintar el menú"
GetProgressFunc.OnServerInvoke = function(player)
	local data = SessionData[player.UserId]
	if not data then 
		-- Si por alguna razón no cargó, intentar cargar de nuevo o devolver defaults
		data = loadData(player) 
	end
	return data
end

-- El cliente pide "Quiero jugar el Nivel X"
RequestPlayEvent.OnServerEvent:Connect(function(player, levelId)
	local sID = tostring(levelId)
	local data = SessionData[player.UserId]
	
	if not data then return end
	
	local levelData = data.Levels[sID]
	
	-- Validar si existe y está desbloqueado
	if levelData and levelData.Unlocked then
		print("🚀 " .. player.Name .. " solicitó ir al Nivel " .. sID)
		
		-- TELETRANSPORTE
		local config = LevelsConfig[tonumber(levelId)]
		if config then
			setupLevelForPlayer(player, tonumber(levelId), config)
		end
	else
		warn("⛔ " .. player.Name .. " intentó acceder a Nivel BLOQUEADO: " .. sID)
	end
end)

-- ============================================
-- LÓGICA DE JUEGO Y TELETRANSPORTE
-- ============================================

function setupLevelForPlayer(player, levelId, config)
	local character = player.Character or player.CharacterAdded:Wait()
	local rootPart = character:WaitForChild("HumanoidRootPart")
	
	-- 1. Buscar Modelo de Nivel
	local nivelModel = NivelUtils.obtenerModeloNivel(levelId)
	if not nivelModel then
		warn("⚠️ Modelo de nivel no encontrado inmediatamente, esperando...")
		task.wait(1)
		nivelModel = NivelUtils.obtenerModeloNivel(levelId)
	end
	
	-- 2. Teletransportar
	local targetPosition = NivelUtils.obtenerPosicionSpawn(levelId)
	if targetPosition then
		-- Pequeña pausa para asegurar carga
		task.wait(0.5) 
		rootPart.CFrame = CFrame.new(targetPosition)
		
		-- 3. Configurar Leaderstats Temporales de la Sesión (Dinero del Nivel)
		local stats = player:FindFirstChild("leaderstats")
		if not stats then
			stats = Instance.new("Folder", player)
			stats.Name = "leaderstats"
		end
		
		-- Restaurar NIVEL para compatibilidad con ClienteUI antiguo
		local nivelVal = stats:FindFirstChild("Nivel") or Instance.new("IntValue", stats)
		nivelVal.Name = "Nivel"
		nivelVal.Value = tonumber(levelId) -- Le ponemos el ID del nivel actual
		
		-- Dinero (Es el presupuesto del nivel, se reinicia siempre)
		local money = stats:FindFirstChild("Money") or Instance.new("IntValue", stats)
		money.Name = "Money"
		money.Value = config.DineroInicial or 0
		
		-- Puntos del nivel actual (Reiniciados)
		local score = stats:FindFirstChild("Score") or Instance.new("IntValue", stats)
		score.Name = "Score"
		score.Value = 0

		-- Actualizar variable de sesión para saber en qué nivel está jugando
		-- (Útil para guardar al final)
		player:SetAttribute("CurrentLevelID", levelId)
		
		print("✅ " .. player.Name .. " listo en " .. config.Nombre .. " con $" .. money.Value)
	else
		warn("❌ No se encontró Spawn para Nivel " .. levelId)
	end
end


-- ============================================
-- FUNCIONES EXPORTADAS (GLOBALES)
-- Para usar desde otros scripts (ej: al completar nivel)
-- ============================================

-- Llamar a esto cuando el jugador gana el nivel
function _G.CompleteLevel(player, starsObtained, scoreObtained)
	local currentLevelId = player:GetAttribute("CurrentLevelID")
	if currentLevelId == nil then return end
	
	local sID = tostring(currentLevelId)
	local data = SessionData[player.UserId]
	if not data then return end
	
	-- Guardar mejor puntaje
	local lvlData = data.Levels[sID]
	if scoreObtained > lvlData.HighScore then
		lvlData.HighScore = scoreObtained
	end
	if starsObtained > lvlData.Stars then
		lvlData.Stars = starsObtained
	end
	
	-- DESBLOQUEAR SIGUIENTE NIVEL
	local nextLevelId = currentLevelId + 1
	local sNextID = tostring(nextLevelId)
	
	if LevelsConfig[nextLevelId] then -- Si existe el siguiente nivel en config
		if not data.Levels[sNextID] then
			data.Levels[sNextID] = { Unlocked = false, Stars = 0, HighScore = 0 }
		end
		
		if not data.Levels[sNextID].Unlocked then
			data.Levels[sNextID].Unlocked = true
			print("🔓 Nivel " .. nextLevelId .. " DESBLOQUEADO!")
			-- Aquí podrías mandar notificación al cliente
		end
	end
	
	saveData(player)
end

-- Llamar a esto cuando el jugador recoge un objeto especial (Mapa, Algoritmo)
function _G.CollectItem(player, itemId)
	local data = SessionData[player.UserId]
	if data and not table.find(data.Inventory, itemId) then
		table.insert(data.Inventory, itemId)
		print("🎒 Objeto recolectado: " .. itemId)
		saveData(player) -- Guardado seguro
	end
end

-- ============================================
-- CONEXIONES LIFECYCLE
-- ============================================

Players.PlayerAdded:Connect(function(player)
	loadData(player)
	-- NO teletransportamos automáticamente. El jugador se queda en el Lobby/Menú.
end)

Players.PlayerRemoving:Connect(function(player)
	saveData(player)
	SessionData[player.UserId] = nil
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		saveData(player)
	end
	task.wait(2) -- Dar tiempo a DataStore
end)
