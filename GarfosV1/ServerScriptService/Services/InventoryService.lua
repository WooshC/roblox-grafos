-- ServerScriptService/Services/InventoryService.lua
-- SERVICIO CENTRALIZADO para gestión de Inventario
-- Reemplaza a InventoryManager (ReplicatedStorage)
-- Maneja propiedad de items, persistencia y sincronización con cliente

local InventoryService = {}
InventoryService.__index = InventoryService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Referencias a Singletons de Data (para persistencia real)
-- local DataService = require(...) -- Futuro

-- Estado interno
local playerInventories = {} -- { [UserId] = { ["ItemID"] = true } }
local updateEvent = nil

-- Dependencias
local levelService = nil

-- ============================================
-- INICIALIZACIÓN
-- ============================================

function InventoryService:init()
	local Remotes = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes")

	-- Evento para enviar actualizaciones al cliente
	updateEvent = Remotes:FindFirstChild("ActualizarInventario")
	if not updateEvent then
		updateEvent = Instance.new("RemoteEvent")
		updateEvent.Name = "ActualizarInventario"
		updateEvent.Parent = Remotes
	end

	-- Función remota para que el cliente consulte inventario completo
	local getInventoryFunc = Remotes:FindFirstChild("GetInventory")
	if not getInventoryFunc then
		getInventoryFunc = Instance.new("RemoteFunction")
		getInventoryFunc.Name = "GetInventory"
		getInventoryFunc.Parent = Remotes
	end

	getInventoryFunc.OnServerInvoke = function(player)
		return self:getPlayerInventory(player)
	end

	-- Función remota para verificar un item específico
	local checkItemFunc = Remotes:FindFirstChild("VerificarInventario")
	if checkItemFunc then
		checkItemFunc.OnServerInvoke = function(player, itemId)
			return self:hasItem(player, itemId)
		end
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

	print("✅ InventoryService inicializado")
end

function InventoryService:setDependencies(levelSvc)
	levelService = levelSvc
end

-- ============================================
-- GESTIÓN DE JUGADORES
-- ============================================

function InventoryService:initializePlayer(player)
	if playerInventories[player.UserId] then return end
	playerInventories[player.UserId] = {}

	-- TODO: Aquí cargaríamos datos de DataStore si existiera
	print("✅ InventoryService: Inventario inicializado para " .. player.Name)
end

function InventoryService:clearPlayer(player)
	playerInventories[player.UserId] = nil
end

-- Carga datos (usado por DataManager si existe)
function InventoryService:loadPlayerData(player, itemsList)
	if not playerInventories[player.UserId] then
		playerInventories[player.UserId] = {}
	end

	local inventory = playerInventories[player.UserId]
	if itemsList then
		for _, itemId in ipairs(itemsList) do
			inventory[itemId] = true
		end
	end

	self:syncToClient(player)
end

-- ============================================
-- OPERACIONES DE INVENTARIO
-- ============================================

-- Añade un item al inventario
function InventoryService:addItem(player, itemId)
	if not player or not itemId then return end

	local inventory = playerInventories[player.UserId]
	if not inventory then
		self:initializePlayer(player)
		inventory = playerInventories[player.UserId]
	end

	if inventory[itemId] then return end -- Ya lo tiene

	-- Añadir item
	inventory[itemId] = true

	-- Sincronizar con cliente
	if updateEvent then
		updateEvent:FireClient(player, itemId, true)
	end

	-- Persistencia (Emitir evento interno para que DataManager lo guarde)
	-- Usamos un BindableEvent para desacoplar
	local Bindables = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Bindables")
	local saveEvent = Bindables:FindFirstChild("GuardarInventario")
	if saveEvent then
		saveEvent:Fire(player, itemId)
	end

	print("🎒 InventoryService: " .. player.Name .. " recibió " .. itemId)
end

-- Remueve un item del inventario
function InventoryService:removeItem(player, itemId)
	if not player then return end
	local inventory = playerInventories[player.UserId]
	if not inventory then return end

	if inventory[itemId] then
		inventory[itemId] = nil

		if updateEvent then
			updateEvent:FireClient(player, itemId, false)
		end

		print("🎒 InventoryService: Item removido " .. itemId .. " de " .. player.Name)
	end
end

-- Verifica si tiene un item
function InventoryService:hasItem(player, itemId)
	local inventory = playerInventories[player.UserId]
	if not inventory then return false end
	return inventory[itemId] == true
end

-- Obtiene tabla completa de inventario
function InventoryService:getPlayerInventory(player)
	return playerInventories[player.UserId] or {}
end

-- Sincroniza todo el inventario al cliente
function InventoryService:syncToClient(player)
	local inventory = playerInventories[player.UserId] or {}
	if not updateEvent then return end

	for itemId, _ in pairs(inventory) do
		updateEvent:FireClient(player, itemId, true)
	end
end

-- Resetea items específicos de un nivel (si fueran temporales)
function InventoryService:resetLevelItems(player, levelId)
	-- Implementar si hay items que se pierden al reiniciar
	-- Por ahora dejaremos vacío ya que la mayoría de items parecen persistentes
end

return InventoryService
