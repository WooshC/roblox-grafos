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

	-- Crear valores si no existen
	if not stats:FindFirstChild("Nivel") then
		local nivel = Instance.new("IntValue")
		nivel.Name = "Nivel"
		nivel.Value = 0
		nivel.Parent = stats
	end

	if not stats:FindFirstChild("Money") then
		local money = Instance.new("IntValue")
		money.Name = "Money"
		money.Value = 0
		money.Parent = stats
	end

	if not stats:FindFirstChild("Puntos") then
		local puntos = Instance.new("IntValue")
		puntos.Name = "Puntos"
		puntos.Value = 0
		puntos.Parent = stats
	end

	if not stats:FindFirstChild("Estrellas") then
		local estrellas = Instance.new("IntValue")
		estrellas.Name = "Estrellas"
		estrellas.Value = 0
		estrellas.Parent = stats
	end
end

-- ============================================
-- FUNCIONES DE CARGA Y GUARDADO
-- ============================================

local function loadData(player)
	local success, data = pcall(function()
		return MainStore:GetAsync("User_" .. player.UserId)
	end)

	if success and data then
		print("✅ Datos cargados para " .. player.Name)
	else
		print("🆕 Nuevos datos inicializados para " .. player.Name)
		data = {}
		for key, value in pairs(DEFAULT_DATA) do
			data[key] = value
		end
	end

	SessionData[player.UserId] = data

	-- Sincronizar inventario con InventoryService
	task.spawn(function()
		-- Esperar a que _G.Services esté disponible
		local attempts = 0
		while (not _G.Services or not _G.Services.Inventory) and attempts < 10 do
			task.wait(1)
			attempts = attempts + 1
		end
		
		local InventoryService = _G.Services and _G.Services.Inventory
		if InventoryService then
			InventoryService:loadPlayerData(player, data.Inventory)
			print("✅ ManagerData: Inventario sincronizado con InventoryService")
		else
			warn("⚠️ ManagerData: No se pudo sincronizar inventario (Servicio no encontrado)")
		end
	end)
	
	return data
end

local function saveData(player)
	local data = SessionData[player.UserId]
	if not data then return end

	-- Log de depuración para inventario
	if data.Inventory then
		print("💾 Guardando datos de " .. player.Name .. " | Inventario: " .. table.concat(data.Inventory, ", "))
	else
		warn("⚠️ Inventario vacío o nil al guardar para " .. player.Name)
	end

	local success, err = pcall(function()
		MainStore:SetAsync("User_" .. player.UserId, data)
	end)

	if success then
		print("✅ PROGRESO GUARDADO EXITOSAMENTE en DataStore para " .. player.Name)
	else
		warn("❌ ERROR CRÍTICO guardando datos: " .. tostring(err))
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

-- Esperar a que Init.server.lua registre _G.Services
print("⏳ ManagerData: Esperando a que _G.Services esté disponible...")
repeat 
	task.wait(0.1) 
until _G.Services and _G.Services.Level

local LevelService = _G.Services.Level
print("✅ ManagerData: LevelService conectado")

RequestPlayEvent.OnServerEvent:Connect(function(player, levelId)
	print("🎮 ManagerData: Solicitud de nivel " .. levelId .. " de " .. player.Name)
	
	local sID = tostring(levelId)
	local data = SessionData[player.UserId]

	if not data then 
		warn("⚠️ No hay datos de sesión para " .. player.Name)
		return 
	end

	local levelData = data.Levels[sID]

	-- Validar permisos
	if not (levelData and levelData.Unlocked) then
		warn("⛔ " .. player.Name .. " intentó acceder a Nivel BLOQUEADO: " .. sID)
		return
	end

	local config = LevelsConfig[tonumber(levelId)]
	if not config then
		warn("⚠️ Configuración de nivel " .. levelId .. " no encontrada")
		return
	end

	-- Cargar el nivel
	print("📦 ManagerData: Cargando nivel " .. levelId .. "...")
	local success = LevelService:loadLevel(tonumber(levelId))
	
	if success then
		print("✅ ManagerData: Nivel " .. levelId .. " cargado, teleportando jugador...")
		-- Esperar a que el nivel se replique
		task.wait(0.5)
		setupLevelForPlayer(player, tonumber(levelId), config)
	else
		warn("❌ ManagerData: Error al cargar nivel " .. levelId)
	end
end)

-- ============================================
-- LÓGICA DE JUEGO Y TELETRANSPORTE
-- ============================================

function setupLevelForPlayer(player, levelId, config)
	local character = player.Character or player.CharacterAdded:Wait()
	local rootPart = character:WaitForChild("HumanoidRootPart", 5) -- Timeout de 5s
	
	if not rootPart then
		warn("⚠️ ManagerData: No se encontró HumanoidRootPart para " .. player.Name)
		return
	end

	-- Asegurar que leaderstats existan antes de entrar al nivel
	setupLeaderstats(player)

	-- Esperar a que el nivel esté cargado en Workspace
	local nivelModel = NivelUtils.obtenerModeloNivel(levelId)
	if not nivelModel then
		print("⏳ Esperando que el nivel aparezca en Workspace...")
		task.wait(1)
		nivelModel = NivelUtils.obtenerModeloNivel(levelId)
	end

	if not nivelModel then
		warn("❌ Nivel no encontrado en Workspace después de esperar")
		return
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

		-- Forzar actualización de atributo para reactivar UI (minimapa, etc)
		player:SetAttribute("CurrentLevelID", -1)
		task.wait() 
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