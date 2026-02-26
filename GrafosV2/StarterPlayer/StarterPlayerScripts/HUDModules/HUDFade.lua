-- HUDFade.lua
-- Maneja overlay de fade negro para transiciones
-- Uso: local HUDFade = require(HUDModules.HUDFade)

local TweenService = game:GetService("TweenService")

local HUDFade = {}

local fadeOverlay = nil
local parentHud = nil

function HUDFade.init(hudRef)
	parentHud = hudRef
	
	-- Limpiar overlay anterior si existe
	local oldOverlay = parentHud:FindFirstChild("SalirFade")
	if oldOverlay then oldOverlay:Destroy() end
	
	fadeOverlay = Instance.new("Frame")
	fadeOverlay.Name = "SalirFade"
	fadeOverlay.Size = UDim2.new(1, 0, 1, 0)
	fadeOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
	fadeOverlay.BackgroundTransparency = 1
	fadeOverlay.BorderSizePixel = 0
	fadeOverlay.ZIndex = 99
	fadeOverlay.Visible = false
	fadeOverlay.Parent = parentHud
end

function HUDFade.fadeToBlack(duration, callback)
	if not fadeOverlay then return end
	
	fadeOverlay.Visible = true
	local tween = TweenService:Create(
		fadeOverlay,
		TweenInfo.new(duration or 0.35, Enum.EasingStyle.Linear),
		{ BackgroundTransparency = 0 }
	)
	
	if callback then
		tween.Completed:Once(callback)
	end
	
	tween:Play()
	return tween
end

function HUDFade.reset()
	if not fadeOverlay then return end
	fadeOverlay.BackgroundTransparency = 1
	fadeOverlay.Visible = false
end

return HUDFade
