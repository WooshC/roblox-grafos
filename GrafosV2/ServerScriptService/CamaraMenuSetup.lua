-- CamaraMenuSetup.server.lua
-- Ubicación Roblox: ServerScriptService/CamaraMenuSetup  (Script)
--
-- Garantiza que exista una Part "CamaraMenu" en ReplicatedStorage para que
-- el cliente pueda leerla al arrancar el menú (sin personaje).
--
-- Lógica:
--   1. Si ya existe en ReplicatedStorage → no hace nada (ya está lista).
--   2. Si existe en Workspace → la CLONA a ReplicatedStorage (la original
--      se queda en Workspace para que puedas editarla en Studio).
--   3. Si no existe en ningún lado → la crea en ReplicatedStorage Y en
--      Workspace (para que puedas verla y moverla en Studio).

local RS        = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- ── Caso 1: ya está en RS ──────────────────────────────────────────────────
if RS:FindFirstChild("CamaraMenu") then
	print("[CamaraMenuSetup] ✅ CamaraMenu ya existe en ReplicatedStorage")
	return
end

-- ── Caso 2: existe en Workspace → clonar a RS ─────────────────────────────
local wsCAM = Workspace:FindFirstChild("CamaraMenu")
if wsCAM then
	local clone = wsCAM:Clone()
	clone.Parent = RS
	print("[CamaraMenuSetup] ✅ CamaraMenu clonada de Workspace → ReplicatedStorage")
	print("[CamaraMenuSetup]    Posición:", tostring(clone.CFrame.Position))
	return
end

-- ── Caso 3: no existe en ningún lugar → crear en ambos ────────────────────
local function makeCamPart(parent)
	local cam = Instance.new("Part")
	cam.Name         = "CamaraMenu"
	cam.Size         = Vector3.new(1, 1, 1)
	cam.Anchored     = true
	cam.CanCollide   = false
	cam.CanQuery     = false
	cam.CanTouch     = false
	cam.Transparency = 1

	-- ── Ajusta este CFrame para cambiar la vista del menú ──────────────
	-- CFrame.new(X, Y, Z)  →  posición en el mundo
	-- CFrame.Angles(pitch, yaw, roll)  →  pitch negativo = mira hacia abajo
	-- El valor por defecto apunta desde enfrente del área de spawn.
	cam.CFrame = CFrame.new(0, 20, 40) * CFrame.Angles(math.rad(-15), math.rad(180), 0)
	cam.Parent = parent
	return cam
end

-- Crear en Workspace (visible/editable en Studio)
local wsCam = makeCamPart(Workspace)
-- Clonar a RS (accesible por el cliente sin personaje)
local rsCam = wsCam:Clone()
rsCam.Parent = RS

print("[CamaraMenuSetup] ✅ CamaraMenu creada en Workspace y ReplicatedStorage")
print("[CamaraMenuSetup]    Posición:", tostring(wsCam.CFrame.Position))
print("[CamaraMenuSetup] ℹ️  Mueve la Part 'CamaraMenu' en el Workspace para ajustar la vista.")
print("[CamaraMenuSetup]    Luego actualiza el CFrame en este script para que persista al publicar.")