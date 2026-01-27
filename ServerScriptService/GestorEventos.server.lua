local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryManager = require(ReplicatedStorage:WaitForChild("Utilidades"):WaitForChild("InventoryManager"))

-- 1. Inicializar Sistemas Base
InventoryManager.init()
print("✅ InventoryManager inicializado (desde GestorEventos)")

-- 2. Asegurar Estructura de Eventos
local serverEvents = ReplicatedStorage:FindFirstChild("ServerEvents")
if not serverEvents then
	serverEvents = Instance.new("Folder")
	serverEvents.Name = "ServerEvents"
	serverEvents.Parent = ReplicatedStorage
end

-- Evento para recibir señales del Cliente (Diálogos)
local eventoAparecer = serverEvents:FindFirstChild("AparecerObjeto")
if not eventoAparecer then
	eventoAparecer = Instance.new("RemoteEvent")
	eventoAparecer.Name = "AparecerObjeto"
	eventoAparecer.Parent = serverEvents
end

-- Evento para comunicar con Scripts de Objetos (Servidor interno)
local eventoDesbloquear = serverEvents:FindFirstChild("DesbloquearObjeto")
if not eventoDesbloquear then
	eventoDesbloquear = Instance.new("BindableEvent")
	eventoDesbloquear.Name = "DesbloquearObjeto"
	eventoDesbloquear.Parent = serverEvents
end

local eventoRestaurar = serverEvents:FindFirstChild("RestaurarObjetos")
if not eventoRestaurar then
	eventoRestaurar = Instance.new("BindableEvent")
	eventoRestaurar.Name = "RestaurarObjetos"
	eventoRestaurar.Parent = serverEvents
end

-- 3. Puente: Cliente (Diálogo) -> Servidor (Script Individual)
eventoAparecer.OnServerEvent:Connect(function(player, nivelID, objetoID)
	print("📡 Puente: Recibido 'AparecerObjeto' desde Cliente para: " .. tostring(objetoID))
	
	-- Redirigir a los scripts individuales que escuchan DesbloquearObjeto
	eventoDesbloquear:Fire(objetoID, nivelID)
end)

print("✅ GestorEventos cargado: Puente de eventos listo.")
