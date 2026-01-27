-- InventoryManager.lua
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
end

-- ============================================
-- GESTIÓN DE INVENTARIO
-- ============================================

--- Inicializa el inventario de un jugador
--- @param player Player
function InventoryManager.inicializarJugador(player)
	_inventarios[player.UserId] = {}
	print("🎒 Inventario inicializado para " .. player.Name)
end

--- Limpia el inventario al salir
--- @param player Player
function InventoryManager.limpiarJugador(player)
	_inventarios[player.UserId] = nil
end

--- Agrega un objeto al inventario
--- @param player Player
--- @param objetoID string - ID del objeto (ej: "Mapa", "Algoritmo_BFS")
function InventoryManager.agregarObjeto(player, objetoID)
	local inventario = _inventarios[player.UserId]
	if not inventario then
		InventoryManager.inicializarJugador(player)
		inventario = _inventarios[player.UserId]
	end
	
	-- Agregar objeto
	inventario[objetoID] = true
	
	-- Notificar al cliente
	if _eventoInventario then
		_eventoInventario:FireClient(player, objetoID, true)
		print("✅ " .. player.Name .. " obtuvo: " .. objetoID)
	end
end

--- Verifica si el jugador tiene un objeto
--- @param player Player
--- @param objetoID string
--- @return boolean
function InventoryManager.tieneObjeto(player, objetoID)
	local inventario = _inventarios[player.UserId]
	if not inventario then return false end
	
	return inventario[objetoID] == true
end

--- Obtiene todo el inventario del jugador
--- @param player Player
--- @return table
function InventoryManager.obtenerInventario(player)
	return _inventarios[player.UserId] or {}
end

--- Resetea los objetos de un nivel específico
--- @param player Player
--- @param nivelID number
--- @param objetosDelNivel table - Lista de IDs de objetos del nivel
function InventoryManager.resetearNivel(player, nivelID, objetosDelNivel)
	local inventario = _inventarios[player.UserId]
	if not inventario then return end
	
	-- Remover solo los objetos de este nivel
	for _, objetoID in ipairs(objetosDelNivel) do
		if inventario[objetoID] then
			inventario[objetoID] = nil
			
			-- Notificar al cliente
			if _eventoInventario then
				_eventoInventario:FireClient(player, objetoID, false)
			end
		end
	end
	
	print("🔄 Objetos del Nivel " .. nivelID .. " reseteados para " .. player.Name)
end

--- Sincroniza el inventario completo con el cliente
--- @param player Player
function InventoryManager.sincronizarConCliente(player)
	local inventario = _inventarios[player.UserId] or {}
	
	if _eventoInventario then
		-- Enviar cada objeto
		for objetoID, tiene in pairs(inventario) do
			_eventoInventario:FireClient(player, objetoID, tiene)
		end
	end
end

return InventoryManager
