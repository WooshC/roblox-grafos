-- ServerScriptService/Services/EventBridgeService.lua
-- SERVICIO PUENTE DE EVENTOS 
-- Reemplaza a 'GestorEventos.server.lua'
-- Su trabajo es redirigir eventos remotos (Cliente -> Servidor) a eventos locales (Servidor -> Scripts de Objetos)

local EventBridgeService = {}
EventBridgeService.__index = EventBridgeService

local ReplicatedStorage = game:GetService("ReplicatedStorage")

function EventBridgeService:init()
	print("🚀 EventBridgeService: Iniciando puente de eventos...")
	
	local Events = ReplicatedStorage:WaitForChild("Events")
	local Remotes = Events:WaitForChild("Remotes")
	local Bindables = Events:WaitForChild("Bindables")
	
	-- 1. Puente: Aparecer Objeto (Cliente -> Scripts Locales)
	local remoteAparecer = Remotes:WaitForChild("AparecerObjeto")
	local bindableDesbloquear = Bindables:WaitForChild("DesbloquearObjeto")
	
	if remoteAparecer and bindableDesbloquear then
		remoteAparecer.OnServerEvent:Connect(function(player, nivelID, objetoID)
			print("📡 Puente: Recibido 'AparecerObjeto' desde Cliente para: " .. tostring(objetoID))
			bindableDesbloquear:Fire(objetoID, nivelID)
		end)
		print("   ✅ Puente 'AparecerObjeto' configurado")
	end
	
	-- 2. Puente: Restaurar Objetos (Reinicio -> Scripts Locales)
	-- BindableEvent ya usado por SistemaUI_reinicio, no necesitamos puente extra si se comunica directo.
	
	print("✅ EventBridgeService inicializado correctamente")
end

return EventBridgeService
