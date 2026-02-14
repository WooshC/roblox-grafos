-- Controllers/CameraController.lua
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StateManager = require(script.Parent.Parent.Services.StateManager)

local CameraController = {
    camera = workspace.CurrentCamera,
    connection = nil,
    zoomLevel = 90,
    originalCameraType = Enum.CameraType.Custom,
    roofs = {}, -- Cache de techos originales
}

function CameraController.init()
    StateManager.subscribe("mapActive", CameraController._onToggle)
end

function CameraController._onToggle(isActive)
    if isActive then
        CameraController._enable()
    else
        CameraController._disable()
    end
end

function CameraController._enable()
    local camera = CameraController.camera
    CameraController.originalCameraType = camera.CameraType
    
    camera.CameraType = Enum.CameraType.Scriptable
    
    -- Transparencia de techos
    CameraController._setRoofsTransparency(0.95)
    
    -- Loop de render
    CameraController.connection = RunService.RenderStepped:Connect(function()
        local char = game.Players.LocalPlayer.Character
        if not char then return end
        
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            local pos = root.Position
            camera.CFrame = CFrame.new(pos + Vector3.new(0, CameraController.zoomLevel, 0), pos)
        end
    end)
end

function CameraController._disable()
    if CameraController.connection then
        CameraController.connection:Disconnect()
        CameraController.connection = nil
    end
    
    CameraController.camera.CameraType = CameraController.originalCameraType
    CameraController._restoreRoofs()
end

function CameraController._setRoofsTransparency(alpha)
    local level = CameraController._getCurrentLevelModel()
    if not level then return end
    
    local techos = level:FindFirstChild("Techos")
    if not techos then return end
    
    for _, techo in ipairs(techos:GetChildren()) do
        if techo:IsA("BasePart") then
            CameraController.roofs[techo] = techo.Transparency
            techo.Transparency = alpha
            techo.CastShadow = false
        end
    end
end

function CameraController._restoreRoofs()
    for techo, original in pairs(CameraController.roofs) do
        if techo and techo:IsA("BasePart") then
            techo.Transparency = original
            techo.CastShadow = true
        end
    end
    table.clear(CameraController.roofs)
end

function CameraController._getCurrentLevelModel()
    local levelId = StateManager.get("level.id") or 0
    return workspace:FindFirstChild("NivelActual")
        or workspace:FindFirstChild("Nivel" .. levelId)
end

return CameraController