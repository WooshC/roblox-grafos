-- DataManager.server.lua (Antes MoneyData)
-- Maneja Dinero, Nivel y Teletransporte inicial

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))
local NivelUtils = require(ReplicatedStorage:WaitForChild("Utilidades"):WaitForChild("NivelUtils"))

local MainStore = DataStoreService:GetDataStore("PlayerData_v3_Mezclado")

-- ============================================
-- TELETRANSPORTE
-- ============================================

local function teleportToLevel(player, nivelID)
	-- Esperar a que el personaje exista físicamente
	local character = player.Character or player.CharacterAdded:Wait()
	local rootPart = character:WaitForChild("HumanoidRootPart")

	-- Parche por si el personaje no ha terminado de cargar bien
	task.wait(0.5) 

	local config = LevelsConfig[nivelID]

	-- Validación de seguridad
	if not config then 
		warn("⚠️ Nivel " .. tostring(nivelID) .. " no configurado. Enviando a Nivel 0.")
		nivelID = 0
		config = LevelsConfig[0]
	end

	-- Buscar modelo de nivel usando utilidad
	local nivelModel = NivelUtils.obtenerModeloNivel(nivelID)
	
	if not nivelModel then
		warn("⚠️ Esperando modelo de nivel: " .. config.Modelo)
		task.wait(2)
		nivelModel = NivelUtils.obtenerModeloNivel(nivelID)
	end

	if not nivelModel then
		warn("❌ ERROR CRÍTICO: No se encontró el modelo '" .. tostring(config.Modelo) .. "' tras esperar.")
		return
	end

	-- ✅ USAR UTILIDAD PARA OBTENER SPAWN (Prioriza SpawnLocation correctamente)
	local targetPosition = NivelUtils.obtenerPosicionSpawn(nivelID)

	if targetPosition then
		rootPart.CFrame = CFrame.new(targetPosition)
		print("🚀 " .. player.Name .. " enviado a: " .. config.Nombre .. " (Pos: " .. tostring(targetPosition) .. ")")

		-- AL ENTRAR AL NIVEL: RESETEAR DINERO DE PRESUPUESTO
		local stats = player:FindFirstChild("leaderstats")
		if stats then
			local money = stats:FindFirstChild("Money")
			if money then
				money.Value = config.DineroInicial or 2000
				print("💰 Presupuesto asignado: $" .. money.Value)
			end
		end
	else
		warn("⚠️ No hay dónde spawnear en Nivel " .. nivelID)
	end
end

-- === 2. GESTIÓN DE DATOS ===

-- Datos por defecto
local DEFAULT_DATA = {
	NivelActual = 0,
	XP = 0,
	-- Money = 0 -- Si quisieras guardar dinero global, iría aquí.
	-- Pero como es un puzzle de presupuesto, el dinero es volátil por nivel.
}

-- Cargar datos
local function loadData(player)
	local success, data = pcall(function()
		return MainStore:GetAsync("User_" .. player.UserId)
	end)

	if not success then
		warn("⚠️ Error cargando datos para " .. player.Name .. ": " .. tostring(data))
		data = nil -- Forzar default
	end

	-- Merge con defaults por si agregamos campos nuevos en el futuro
	data = data or {}
	for k, v in pairs(DEFAULT_DATA) do
		if data[k] == nil then data[k] = v end
	end

	return data
end

-- Guardar datos
local function saveData(player)
	if not player:FindFirstChild("leaderstats") then return end

	local nivelVal = player.leaderstats:FindFirstChild("Nivel")
	-- El dinero no lo guardamos porque es presupuesto de nivel

	if nivelVal then
		local dataToSave = {
			NivelActual = nivelVal.Value,
			XP = 0 -- Aquí podrías leer un valor de XP si lo tuvieras
		}

		pcall(function()
			MainStore:SetAsync("User_" .. player.UserId, dataToSave)
			print("💾 Progreso guardado: Nivel " .. dataToSave.NivelActual)
		end)
	end
end

-- Crear HUD de stats
local function createLeaderstats(player, data)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	-- Nivel (Progreso Global)
	local nivel = Instance.new("IntValue")
	nivel.Name = "Nivel"
	nivel.Value = data.NivelActual or 0
	nivel.Parent = leaderstats

	-- Dinero (Presupuesto de la Sesión/Nivel)
	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Value = 0 -- Se setea al teleportar
	money.Parent = leaderstats

	-- Puntos (Score del nivel actual)
	local puntos = Instance.new("IntValue")
	puntos.Name = "Puntos"
	puntos.Value = 0
	puntos.Parent = leaderstats

	-- Estrellas (Calificación)
	local estrellas = Instance.new("IntValue")
	estrellas.Name = "Estrellas"
	estrellas.Value = 0
	estrellas.Parent = leaderstats
end

-- === 3. CONEXIONES ===

Players.PlayerAdded:Connect(function(player)
	local data = loadData(player)
	createLeaderstats(player, data)

	-- Cuando cargue el personaje, lo mandamos a su nivel
	player.CharacterAdded:Connect(function()
		local stats = player:FindFirstChild("leaderstats")
		local nivelActual = stats and stats.Nivel.Value or 0
		teleportToLevel(player, nivelActual)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	saveData(player)
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		saveData(player)
	end
end)

-- DEBUG: Comando para testear avance (opcional)
-- game.ReplicatedStorage:WaitForChild("CompletarNivel").OnServerEvent...
local eventoCompletar = Instance.new("RemoteEvent")
eventoCompletar.Name = "CompletarNivel"
eventoCompletar.Parent = ReplicatedStorage or workspace

eventoCompletar.OnServerEvent:Connect(function(player)
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Nivel.Value = stats.Nivel.Value + 1
		print("🎉 NIVEL COMPLETADO! Avanzando a Nivel " .. stats.Nivel.Value)
		saveData(player)
		player:LoadCharacter() -- Respawn para cargar siguiente nivel
	end
end)
