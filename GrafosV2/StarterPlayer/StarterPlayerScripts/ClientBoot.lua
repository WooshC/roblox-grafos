-- ClientBoot.client.lua
-- Ubicación: StarterPlayer > StarterPlayerScripts > ClientBoot
-- Tipo: LocalScript
--
-- ÚNICO responsable de:
--   · Activar/desactivar EDAQuestMenu y GUIExploradorV2
--   · Cambiar CameraType entre Scriptable (menú) y Custom (gameplay)
--
-- BUGS CORREGIDOS:
--
-- [BUG CÁMARA RESTARTLEVEL] Al reiniciar el nivel, LevelLoader destruye y
--   recrea el personaje DESPUÉS de disparar LevelReady. Cuando Roblox crea
--   el nuevo personaje, fuerza CameraType = Custom automáticamente, pero si
--   el Subject (a quién sigue la cámara) no está seteado, la cámara flota.
--   FIX: En LevelReady, además de setCameraGame(), escuchar CharacterAdded
--   y reasignar camera.CameraSubject al Humanoid del nuevo personaje, con
--   un pequeño delay para que el personaje esté completamente cargado.

local Players  = game:GetService("Players")
local RS       = game:GetService("ReplicatedStorage")
local UIS      = game:GetService("UserInputService")

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

-- FIX: setCameraGame ahora también reasigna CameraSubject al Humanoid.
-- Esto es crítico en RestartLevel: el personaje es destruido y recreado,
-- por lo que el Subject queda apuntando a nil hasta que se reasigna.
local function setCameraGame()
	camera.CameraType = Enum.CameraType.Custom

	-- Intentar asignar Subject al personaje actual
	local char = player.Character
	if char then
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
			print("[ClientBoot] Cámara → Custom | Subject asignado al Humanoid actual")
			return
		end
	end

	-- Si el personaje aún no existe (RestartLevel: se está creando),
	-- esperar CharacterAdded y asignar cuando llegue.
	print("[ClientBoot] Cámara → Custom | esperando personaje para asignar Subject...")
	local conn
	conn = player.CharacterAdded:Connect(function(newChar)
		conn:Disconnect()
		-- Esperar a que el Humanoid esté disponible dentro del personaje
		local humanoid = newChar:FindFirstChildOfClass("Humanoid")
			or newChar:WaitForChild("Humanoid", 5)
		if humanoid then
			-- Pequeño delay para que el motor de física esté listo
			task.wait(0.1)
			camera.CameraType    = Enum.CameraType.Custom
			camera.CameraSubject = humanoid
			print("[ClientBoot] Cámara → Subject asignado tras CharacterAdded")
		else
			warn("[ClientBoot] ⚠ Humanoid no encontrado en el nuevo personaje")
		end
	end)
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
		setCameraGame()  -- FIX: ahora maneja Subject + CharacterAdded
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