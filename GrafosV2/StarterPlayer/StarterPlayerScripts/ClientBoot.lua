-- ClientBoot.client.lua
-- Ubicación: StarterPlayer > StarterPlayerScripts > ClientBoot
-- Tipo: LocalScript
--
-- ÚNICO responsable de:
--   · Activar/desactivar EDAQuestMenu y GUIExploradorV2
--   · Cambiar CameraType entre Scriptable (menú) y Custom (gameplay)
--
-- HUDController y MenuController NUNCA tocan .Enabled ni CameraType.

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local UIS     = game:GetService("UserInputService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local menu = playerGui:WaitForChild("EDAQuestMenu",    20)
local hud  = playerGui:WaitForChild("GUIExploradorV2", 20)

if not menu then warn("[ClientBoot] ❌ EDAQuestMenu no encontrada");    return end
if not hud  then warn("[ClientBoot] ❌ GUIExploradorV2 no encontrada"); return end

-- Estado inicial
menu.Enabled = true
hud.Enabled  = false

-- ── Cámara ─────────────────────────────────────────────────────────────────
local camera = workspace.CurrentCamera

local function setCameraMenu()
	local camObj = workspace:FindFirstChild("CamaraMenu", true)
	local part   = camObj and (
		(camObj:IsA("BasePart") and camObj) or
		(camObj:IsA("Model")    and camObj.PrimaryPart)
	)
	if part then
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame     = part.CFrame
		print("[ClientBoot] Cámara → Scriptable (menú)")
	end
end

local function setCameraGame()
	-- Forzar Custom para que Roblox siga al personaje.
	-- CRÍTICO en RestartLevel: la cámara queda en Scriptable del menú si no se fuerza aquí.
	camera.CameraType = Enum.CameraType.Custom
	print("[ClientBoot] Cámara → Custom (gameplay)")
end

-- ── Eventos ────────────────────────────────────────────────────────────────
local eventsFolder  = RS:WaitForChild("Events", 15)
local remotesFolder = eventsFolder and eventsFolder:WaitForChild("Remotes", 5)

local levelReadyEv    = remotesFolder and remotesFolder:WaitForChild("LevelReady",    10)
local levelUnloadedEv = remotesFolder and remotesFolder:WaitForChild("LevelUnloaded", 10)

if levelReadyEv then
	levelReadyEv.OnClientEvent:Connect(function(data)
		if data and data.error then return end
		menu.Enabled = false
		hud.Enabled  = true
		setCameraGame()
		print("[ClientBoot] ✅ LevelReady → menú OFF | HUD ON")
	end)
end

if levelUnloadedEv then
	levelUnloadedEv.OnClientEvent:Connect(function()
		hud.Enabled  = false
		menu.Enabled = true
		setCameraMenu()
		UIS.MouseBehavior = Enum.MouseBehavior.Default
		print("[ClientBoot] ✅ LevelUnloaded → HUD OFF | menú ON")
	end)
end

setCameraMenu()
print("[ClientBoot] ✅ Activo")