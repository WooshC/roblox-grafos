-- InventoryManager.lua
-- ⚠️ DEPRECATED ON SERVER: Replaced by InventoryService (ServerScriptService/Services/InventoryService.lua)
-- This module is kept for Client-side compatibility only. Do not use for server validation.
-- Sistema de inventario persistente para objetos coleccionables

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local InventoryManager = {}

-- Evento para sincronizar inventario con cliente
local _eventoInventario = nil

-- Inventario por jugador: { [UserId] = { ["Mapa"] = true, ["Algoritmo_BFS"] = true } }
local _inventarios = {}

-- ============================================
-- INICIALIZACIÓN
-- ============================================

function InventoryManager.init()
	-- Referencias a eventos estáticos
	local Remotes = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes")

	_eventoInventario = Remotes:WaitForChild("ActualizarInventario")

	-- Función para consultar inventario síncronamente
	local funcCheck = Remotes:WaitForChild("VerificarInventario")

	if funcCheck then
		funcCheck.OnServerInvoke = function(player, objetoID)
			return InventoryManager.tieneObjeto(player, objetoID)
		end
	end

	-- Función para obtener TODO el inventario
	local funcGetFull = Remotes:FindFirstChild("GetInventory")
	if not funcGetFull then
		funcGetFull = Instance.new("RemoteFunction", Remotes)
		funcGetFull.Name = "GetInventory"
	end

	funcGetFull.OnServerInvoke = function(player)
		return InventoryManager.obtenerInventario(player)
	end
end

-- ============================================
-- GESTIÓN DE INVENTARIO
-- ============================================

--- Inicializa el inventario de un jugador (Vacío)
function InventoryManager.inicializarJugador(player)
	if not _inventarios[player.UserId] then
		_inventarios[player.UserId] = {}
	end
end

--- Carga inventario desde datos guardados (ManagerData)
function InventoryManager.cargarInventario(player, listaItems)
	_inventarios[player.UserId] = {}
	if listaItems then
		for _, itemID in ipairs(listaItems) do
			_inventarios[player.UserId][itemID] = true
		end
	end
	print("🎒 Inventario CARGADO para " .. player.Name .. ": " .. tostring(#listaItems or 0) .. " items.")
	InventoryManager.sincronizarConCliente(player)
end

--- Limpia el inventario al salir
function InventoryManager.limpiarJugador(player)
	_inventarios[player.UserId] = nil
end

--- Agrega un objeto al inventario y PERSISTE
function InventoryManager.agregarObjeto(player, objetoID)
	local inventario = _inventarios[player.UserId]
	if not inventario then
		InventoryManager.inicializarJugador(player)
		inventario = _inventarios[player.UserId]
	end

	if inventario[objetoID] then return end -- Ya lo tiene

	-- Agregar objeto RAM
	inventario[objetoID] = true

	-- Notificar al cliente
	if _eventoInventario then
		_eventoInventario:FireClient(player, objetoID, true)
	end

	-- NOTIFICAR A MANAGERDATA (PERSISTENCIA)
	local Bindables = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Bindables")
	local eventoGuardar = Bindables:FindFirstChild("GuardarInventario")
	if eventoGuardar then
		eventoGuardar:Fire(player, objetoID)
	else
		warn("⚠️ No se encontró Bindable 'GuardarInventario', el objeto no se guardará permanentemente.")
	end
end

--- Verifica si tiene un objeto (Síncrono/Interno)
function InventoryManager.tieneObjeto(player, objetoID)
	local inventario = _inventarios[player.UserId]
	return inventario and inventario[objetoID] == true
end

--- Devuelve lista completa (para UI)
function InventoryManager.obtenerInventario(player)
	local inventario = _inventarios[player.UserId]
	if not inventario then return {} end

	local lista = {}
	for itemID, _ in pairs(inventario) do
		table.insert(lista, itemID)
	end
	return lista
end

--- Sincroniza TODO el inventario con el cliente (Al cargar)
function InventoryManager.sincronizarConCliente(player)
	if not _eventoInventario then return end

	local inventario = _inventarios[player.UserId]
	if not inventario then return end

	for itemID, _ in pairs(inventario) do
		_eventoInventario:FireClient(player, itemID, true)
	end
end

return InventoryManager
