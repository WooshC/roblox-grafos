-- GestorEventos.server.lua
-- Script Servidor para manejar eventos de objetos y diálogos
-- Usa InventoryService en lugar de InventoryManager

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- P0-2 / P1-10: Esperar ServicesReady en lugar de polling infinito con task.wait(0.5)
local bindablesFolder = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Bindables")
bindablesFolder:WaitForChild("ServicesReady").Event:Wait()

local InventoryService = _G.Services.Inventory
print("✅ InventoryService enlazado (desde GestorEventos)")

-- Estructura de Eventos (ya creada por Init.server.lua)
local eventsFolder = ReplicatedStorage:WaitForChild("Events")
local remotesFolder = eventsFolder:WaitForChild("Remotes")

-- Evento para recibir señales del Cliente (Diálogos)
local eventoAparecer = remotesFolder:WaitForChild("AparecerObjeto")

-- Evento para comunicar con Scripts de Objetos (Servidor interno)
-- P0-6: DesbloquearObjeto y RestaurarObjetos ya existen (creados por Init.server.lua)
local eventoDesbloquear = bindablesFolder:WaitForChild("DesbloquearObjeto")
local eventoRestaurar   = bindablesFolder:WaitForChild("RestaurarObjetos")

-- 3. Puente: Cliente (Diálogo) -> Servidor (Script Individual)
eventoAparecer.OnServerEvent:Connect(function(player, nivelID, objetoID)
	print("📡 Puente: Recibido 'AparecerObjeto' desde Cliente para: " .. tostring(objetoID))
	
	-- Agregar al inventario usando el servicio centralizado
	if InventoryService then
		InventoryService:addItem(player, objetoID)
	end
	
	-- Redirigir a los scripts individuales que escuchan DesbloquearObjeto
	eventoDesbloquear:Fire(objetoID, nivelID)
end)

print("✅ GestorEventos cargado: Puente de eventos listo.")
