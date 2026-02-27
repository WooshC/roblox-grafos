-- StarterPlayerScripts/HUD/ModulosHUD/TransicionHUD.lua
-- Maneja transiciones de fade in/out para el HUD

local TransicionHUD = {}

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local jugador = Players.LocalPlayer
local playerGui = jugador:WaitForChild("PlayerGui")

-- Crear pantalla negra para fade si no existe
local fadeGui = nil
local fadeFrame = nil

local function asegurarFadeGui()
	if fadeGui then return end
	
	fadeGui = playerGui:FindFirstChild("FadeOverlay")
	if not fadeGui then
		fadeGui = Instance.new("ScreenGui")
		fadeGui.Name = "FadeOverlay"
		fadeGui.DisplayOrder = 100
		fadeGui.ResetOnSpawn = false
		fadeGui.Parent = playerGui
		
		fadeFrame = Instance.new("Frame")
		fadeFrame.Name = "FadeFrame"
		fadeFrame.Size = UDim2.new(1, 0, 1, 0)
		fadeFrame.BackgroundColor3 = Color3.new(0, 0, 0)
		fadeFrame.BackgroundTransparency = 1
		fadeFrame.BorderSizePixel = 0
		fadeFrame.Parent = fadeGui
	else
		fadeFrame = fadeGui:FindFirstChild("FadeFrame")
	end
end

function TransicionHUD.fadeToBlack(duracion, callback)
	asegurarFadeGui()
	if not fadeFrame then return end
	
	duracion = duracion or 0.5
	
	local tween = TweenService:Create(
		fadeFrame,
		TweenInfo.new(duracion, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 0 }
	)
	
	if callback then
		tween.Completed:Connect(callback)
	end
	
	tween:Play()
end

function TransicionHUD.fadeFromBlack(duracion, callback)
	asegurarFadeGui()
	if not fadeFrame then return end
	
	duracion = duracion or 0.5
	
	local tween = TweenService:Create(
		fadeFrame,
		TweenInfo.new(duracion, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	)
	
	if callback then
		tween.Completed:Connect(callback)
	end
	
	tween:Play()
end

function TransicionHUD.reset()
	asegurarFadeGui()
	if fadeFrame then
		fadeFrame.BackgroundTransparency = 1
	end
end

function TransicionHUD.ocultarInmediato()
	asegurarFadeGui()
	if fadeFrame then
		fadeFrame.BackgroundTransparency = 1
	end
end

return TransicionHUD
