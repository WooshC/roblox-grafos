local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryManager = require(ReplicatedStorage:WaitForChild("Utilidades"):WaitForChild("InventoryManager"))

-- 1. Inicializar Sistemas Base
InventoryManager.init()
print("✅ InventoryManager inicializado (desde GestorEventos)")

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
