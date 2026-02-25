local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local VELOCIDAD_BASE = 32

local function vigilarVelocidad()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid", 10)
	
	if not humanoid then return end
	
	-- Chequeo constante pero ligero (Heartbeat está bien, o PropertyChangedSignal)
	-- Usamos PropertyChangedSignal para ser eficientes
	humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
		if humanoid.WalkSpeed < VELOCIDAD_BASE and humanoid.WalkSpeed > 0 then
			humanoid.WalkSpeed = VELOCIDAD_BASE
			-- print("⚡ (Cliente) Velocidad restaurada a " .. VELOCIDAD_BASE)
		end
	end)
	
	-- Forzar inicial
	humanoid.WalkSpeed = VELOCIDAD_BASE
end

player.CharacterAdded:Connect(vigilarVelocidad)
if player.Character then vigilarVelocidad() end

print("⚡ SpeedManagerClient activado: Velocidad mínima " .. VELOCIDAD_BASE)
