-- GestorEventos.server.lua
-- Script Servidor para manejar eventos de objetos y diálogos
-- Usa InventoryService en lugar de InventoryManager

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Esperar Inicialización de Servicios
local function waitForService(serviceName)
	local attempts = 0
	while not _G.Services or not _G.Services[serviceName] do
		if attempts > 30 then 
			warn("⚠️ GestorEventos: Esperando servicio " .. serviceName .. "...") 
			attempts = 0
		end
		task.wait(0.5)
		attempts = attempts + 1
	end
	return _G.Services[serviceName]
end

local InventoryService = waitForService("Inventory")
print("✅ InventoryService enlazado (desde GestorEventos)")

-- 2. Asegurar Estructura de Eventos (Estandarizada)
local eventsFolder = ReplicatedStorage:WaitForChild("Events")
local remotesFolder = eventsFolder:WaitForChild("Remotes")
local bindablesFolder = eventsFolder:WaitForChild("Bindables")

-- Evento para recibir señales del Cliente (Diálogos)
local eventoAparecer = remotesFolder:WaitForChild("AparecerObjeto")

-- Evento para comunicar con Scripts de Objetos (Servidor interno)
local eventoDesbloquear = bindablesFolder:WaitForChild("DesbloquearObjeto")

local eventoRestaurar = bindablesFolder:WaitForChild("RestaurarObjetos")

-- 3. Puente: Cliente (Diálogo) -> Servidor (Script Individual)
eventoAparecer.OnServerEvent:Connect(function(player, nivelID, objetoID)
	print("📡 Puente: Recibido 'AparecerObjeto' desde Cliente para: " .. tostring(objetoID))
	
	-- Redirigir a los scripts individuales que escuchan DesbloquearObjeto
	eventoDesbloquear:Fire(objetoID, nivelID)
end)

print("✅ GestorEventos cargado: Puente de eventos listo.")
