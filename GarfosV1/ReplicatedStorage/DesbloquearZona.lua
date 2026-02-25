-- ReplicatedStorage/DesbloquearZona.lua
-- Función helper que el cliente llama al terminar cada diálogo
-- Uso: require(ReplicatedStorage.DesbloquearZona)("Zona1_dialogo")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function desbloquear(dialogoID)
	local evento = ReplicatedStorage
		:WaitForChild("Events", 5)
		:WaitForChild("Remotes", 5)
		:WaitForChild("DesbloquearZona", 5)

	if evento then
		evento:FireServer(dialogoID)
		print("🔓 DesbloquearZona: enviado → " .. tostring(dialogoID))
	else
		warn("⚠️ DesbloquearZona: evento no encontrado")
	end
end

return desbloquear
