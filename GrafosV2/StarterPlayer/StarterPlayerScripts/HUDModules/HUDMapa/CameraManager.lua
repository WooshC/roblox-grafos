-- CameraManager.lua
-- Control de cámara y techo para el mapa

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CameraEffects = require(ReplicatedStorage.Effects.CameraEffects)

local CameraManager = {}

CameraManager.camera = workspace.CurrentCamera
CameraManager.player = Players.LocalPlayer
CameraManager.connection = nil
CameraManager.isActive = false
CameraManager.config = {
	alturaCamara = 80
}

function CameraManager.init(config)
	CameraManager.config = config or CameraManager.config
end

-- ================================================================
-- TECHO (Delegado a CameraEffects)
-- ================================================================

function CameraManager.captureRoof(nivelModel)
	CameraEffects.captureRoof(nivelModel)
end

function CameraManager.hideRoof()
	CameraEffects.hideRoof()
end

function CameraManager.showRoof()
	CameraEffects.showRoof()
end

function CameraManager.resetRoof()
	CameraEffects.resetRoof()
end

-- ================================================================
-- CÁMARA
-- ================================================================

function CameraManager.savePlayerCamera()
	return CameraEffects.saveState(CameraManager.camera)
end

function CameraManager.calculateMapCFrame(nivelModel)
	local bounds = CameraEffects.calculateMapBounds(nivelModel)
	if not bounds then return nil end

	return CameraEffects.calculateOverheadCFrame(bounds, 50)
end

function CameraManager.tweenToMap(targetCFrame, onComplete)
	CameraManager.isActive = true
	return CameraEffects.tweenToMapView(CameraManager.camera, targetCFrame, onComplete)
end

function CameraManager.tweenToPlayer(targetCFrame, onComplete)
	CameraManager.isActive = false
	return CameraEffects.tweenToPlayerView(CameraManager.camera, targetCFrame, onComplete)
end

function CameraManager.startFollowingPlayer()
	if CameraManager.connection then
		CameraManager.connection:Disconnect()
	end

	CameraManager.connection = RunService.RenderStepped:Connect(function()
		if not CameraManager.isActive then return end

		local char = CameraManager.player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then return end

		CameraEffects.followPlayer(
			CameraManager.camera, 
			root.Position, 
			CameraManager.config.alturaCamara
		)
	end)
end

function CameraManager.stopFollowing()
	if CameraManager.connection then
		CameraManager.connection:Disconnect()
		CameraManager.connection = nil
	end
	CameraManager.isActive = false
end

return CameraManager