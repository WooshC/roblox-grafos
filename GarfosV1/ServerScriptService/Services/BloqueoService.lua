-- ServerScriptService/Services/BloqueoService.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BloqueoService = {}
BloqueoService.__index = BloqueoService

function BloqueoService:init()
	local Remotes = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes")

	local evento = Remotes:FindFirstChild("DesbloquearZona")
	if not evento then
		evento = Instance.new("RemoteEvent")
		evento.Name = "DesbloquearZona"
		evento.Parent = Remotes
	end

	evento.OnServerEvent:Connect(function(player, nombreBloqueo)
		local nivelActual = workspace:FindFirstChild("NivelActual")
		if not nivelActual then
			warn("⚠️ BloqueoService: NivelActual no encontrado")
			return
		end

		local bloqueos = nivelActual:FindFirstChild("Bloqueos")
		if not bloqueos then
			warn("⚠️ BloqueoService: Carpeta Bloqueos no encontrada")
			return
		end

		local part = bloqueos:FindFirstChild(nombreBloqueo)
		if part then
			part:Destroy()
			print("✅ BloqueoService: " .. nombreBloqueo .. " destruido por " .. player.Name)
		else
			warn("⚠️ BloqueoService: " .. nombreBloqueo .. " no encontrado (¿ya fue destruido?)")
		end
	end)

	print("✅ BloqueoService: inicializado")
end

return BloqueoService