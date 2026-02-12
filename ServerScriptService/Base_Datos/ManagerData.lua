-- ManagerData.server.lua
-- Maneja el guardado de progreso (Niveles, Estrellas, Puntajes, Inventario) y la carga de niveles.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))
local NivelUtils = require(ReplicatedStorage:WaitForChild("Utilidades"):WaitForChild("NivelUtils"))

local MainStore = DataStoreService:GetDataStore("PlayerData_v4_Levels")

-- ============================================
-- EVENTOS Y CARPETAS
-- ============================================
local EventsFolder = ReplicatedStorage:FindFirstChild("Events") or Instance.new("Folder", ReplicatedStorage)
EventsFolder.Name = "Events"

local RemotesFolder = EventsFolder:FindFirstChild("Remotes") or Instance.new("Folder", EventsFolder)
RemotesFolder.Name = "Remotes"

local GetProgressFunc = RemotesFolder:FindFirstChild("GetPlayerProgress") or Instance.new("RemoteFunction", RemotesFolder)
GetProgressFunc.Name = "GetPlayerProgress"

local RequestPlayEvent = RemotesFolder:FindFirstChild("RequestPlayLevel") or Instance.new("RemoteEvent", RemotesFolder)
RequestPlayEvent.Name = "RequestPlayLevel"

local LevelCompletedEvent = RemotesFolder:FindFirstChild("LevelCompleted") or Instance.new("RemoteEvent", RemotesFolder)
LevelCompletedEvent.Name = "LevelCompleted"

-- Cache en memoria de los datos de jugadores
local SessionData = {}

-- ============================================
-- CONFIGURACIÓN DE DATOS DEFAULT
-- ============================================
local DEFAULT_DATA = {
	Levels = {
		["0"] = { Unlocked = true, Stars = 0, HighScore = 0 },
		["1"] = { Unlocked = false, Stars = 0, HighScore = 0 },
		["2"] = { Unlocked = false, Stars = 0, HighScore = 0 },
		["3"] = { Unlocked = false, Stars = 0, HighScore = 0 },
		["4"] = { Unlocked = false, Stars = 0, HighScore = 0 }
	},
	Inventory = {} 
}

-- ============================================
-- 🔧 NUEVA FUNCIÓN: INICIALIZACIÓN DE LEADERSTATS
-- ============================================
local function setupLeaderstats(player)
	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		stats = Instance.new("Folder")
		stats.Name = "leaderstats"
		stats.Parent = player
	end

	-- Nivel actual
	if not stats:FindFirstChild("Nivel") then
		local nivel = Instance.new("IntValue")
		nivel.Name = "Nivel"
		nivel.Value = 0
		nivel.Parent = stats
	end

	-- Dinero (presupuesto)
	if not stats:FindFirstChild("Money") then
		local money = Instance.new("IntValue")
		money.Name = "Money"
		money.Value = 0
		money.Parent = stats
	end

	-- ⭐ PUNTOS - Sistema de misiones (CRÍTICO)
	if not stats:FindFirstChild("Puntos") then
		local puntos = Instance.new("IntValue")
		puntos.Name = "Puntos"
		puntos.Value = 0
		puntos.Parent = stats
		print("✅ IntValue 'Puntos' creado para " .. player.Name)
	end

	-- ⭐ ESTRELLAS - Basado en puntaje (CRÍTICO)
	if not stats:FindFirstChild("Estrellas") then
		local estrellas = Instance.new("IntValue")
		estrellas.Name = "Estrellas"
		estrellas.Value = 0
		estrellas.Parent = stats
		print("✅ IntValue 'Estrellas' creado para " .. player.Name)
	end

	print("📊 Leaderstats configurados para " .. player.Name)
end

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

	data = data or {}

	if not data.Levels then data.Levels = {} end
	if not data.Inventory then data.Inventory = {} end

	-- Asegurar que todos los niveles existan
	for i = 0, 4 do
		local sID = tostring(i)
		if not data.Levels[sID] then
			data.Levels[sID] = { 
				Unlocked = (i == 0),
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

GetProgressFunc.OnServerInvoke = function(player)
	local data = SessionData[player.UserId]
	if not data then 
		data = loadData(player) 
	end
	return data
end

RequestPlayEvent.OnServerEvent:Connect(function(player, levelId)
	local sID = tostring(levelId)
	local data = SessionData[player.UserId]

	if not data then return end

	local levelData = data.Levels[sID]

	if levelData and levelData.Unlocked then
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

	-- Asegurar que leaderstats existan antes de entrar al nivel
	setupLeaderstats(player)

	local nivelModel = NivelUtils.obtenerModeloNivel(levelId)
	if not nivelModel then
		warn("⚠️ Modelo de nivel no encontrado, esperando...")
		task.wait(1)
		nivelModel = NivelUtils.obtenerModeloNivel(levelId)
	end

	local targetPosition = NivelUtils.obtenerPosicionSpawn(levelId)
	if targetPosition then
		task.wait(0.5) 
		rootPart.CFrame = CFrame.new(targetPosition)

		local stats = player:FindFirstChild("leaderstats")

		-- Actualizar valores del nivel
		local nivelVal = stats:FindFirstChild("Nivel")
		if nivelVal then
			nivelVal.Value = tonumber(levelId)
		end

		local money = stats:FindFirstChild("Money")
		if money then
			money.Value = config.DineroInicial or 0
		end

		-- 🔧 RESETEAR Puntos y Estrellas al iniciar nivel
		local puntos = stats:FindFirstChild("Puntos")
		if puntos then
			puntos.Value = 0
			print("🔄 Puntos reseteados para nuevo nivel")
		end

		local estrellas = stats:FindFirstChild("Estrellas")
		if estrellas then
			estrellas.Value = 0
			print("🔄 Estrellas reseteadas para nuevo nivel")
		end

		player:SetAttribute("CurrentLevelID", levelId)

		print("✅ " .. player.Name .. " listo en " .. config.Nombre .. " con $" .. (money and money.Value or 0))
	else
		warn("❌ No se encontró Spawn para Nivel " .. levelId)
	end
end

-- ============================================
-- FUNCIONES EXPORTADAS (GLOBALES)
-- ============================================

function _G.CompleteLevel(player, starsObtained, scoreObtained)
	local currentLevelId = player:GetAttribute("CurrentLevelID")
	if currentLevelId == nil then return end

	local sID = tostring(currentLevelId)
	local data = SessionData[player.UserId]
	if not data then return end

	local lvlData = data.Levels[sID]
	lvlData.HighScore = scoreObtained
	lvlData.Stars = starsObtained

	print("📝 Nivel " .. sID .. " actualizado: " .. starsObtained .. "⭐ | " .. scoreObtained .. " pts")

	-- DESBLOQUEAR SIGUIENTE NIVEL
	local nextLevelId = currentLevelId + 1
	local sNextID = tostring(nextLevelId)

	if LevelsConfig[nextLevelId] then
		if not data.Levels[sNextID] then
			data.Levels[sNextID] = { Unlocked = false, Stars = 0, HighScore = 0 }
		end

		if not data.Levels[sNextID].Unlocked then
			data.Levels[sNextID].Unlocked = true
			print("🔓 Nivel " .. nextLevelId .. " DESBLOQUEADO!")
		end
	end

	saveData(player)
end

function _G.CollectItem(player, itemId)
	local data = SessionData[player.UserId]
	if data and not table.find(data.Inventory, itemId) then
		table.insert(data.Inventory, itemId)
		print("🎒 Objeto recolectado: " .. itemId)
		saveData(player)
	end
end

-- ============================================
-- CONEXIONES LIFECYCLE
-- ============================================

Players.PlayerAdded:Connect(function(player)
	-- 🔧 PRIMERO: Inicializar leaderstats
	setupLeaderstats(player)

	-- SEGUNDO: Cargar datos de progreso
	loadData(player)

	print("👤 " .. player.Name .. " conectado - Datos y leaderstats listos")
end)

Players.PlayerRemoving:Connect(function(player)
	saveData(player)
	SessionData[player.UserId] = nil
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		saveData(player)
	end
	task.wait(2)
end)

print("✅ ManagerData v4 FIXED - Sistema completo cargado")
