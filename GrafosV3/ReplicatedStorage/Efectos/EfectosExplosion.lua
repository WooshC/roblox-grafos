-- ReplicatedStorage/Efectos/EfectosExplosion.lua
-- Efectos de explosión/chispa para emergencias fallidas.
-- Crea partículas proceduralmente (no requiere assets en EfectosVideo).

local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local EfectosExplosion = {}

-- Busca el Selector (BasePart) de un nodo a partir de su nombre en Workspace
local function buscarSelector(nombreNodo)
	local nodo = Workspace:FindFirstChild(nombreNodo, true)
	if not nodo or not nodo:IsA("Model") then return nil end

	local selector = nodo:FindFirstChild("Selector")
	if not selector then return nil end

	if selector:IsA("BasePart") then
		return selector
	elseif selector:IsA("Model") then
		return selector:FindFirstChildOfClass("BasePart")
	end
	return nil
end

---Crea un efecto de explosión pequeña con chispas en la posición dada.
-- @param posicion Vector3 — centro de la explosión
-- @param duracion number — segundos que dura el efecto (default 1.5)
function EfectosExplosion.chispazo(posicion, duracion)
	duracion = duracion or 1.5
	print(string.format("[EfectosExplosion] ✨ Creando chispazo en %s | duracion=%.1fs", tostring(posicion), duracion))

	-- Parte ancla invisible para los emitters
	local ancla = Instance.new("Part")
	ancla.Name = "EfectoExplosion_Temp"
	ancla.Anchored = true
	ancla.CanCollide = false
	ancla.Transparency = 1
	ancla.Size = Vector3.new(0.1, 0.1, 0.1)
	ancla.Position = posicion
	ancla.Parent = Workspace

	-- Luz puntual que parpadea
	local luz = Instance.new("PointLight")
	luz.Color = Color3.fromRGB(255, 120, 30)
	luz.Brightness = 8
	luz.Range = 25
	luz.Parent = ancla

	-- ParticleEmitter: chispas (rápidas, cortas)
	local chispas = Instance.new("ParticleEmitter")
	chispas.Name = "Chispas"
	chispas.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 50)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 100, 20)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 20, 10)),
	})
	chispas.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(0.3, 0.5),
		NumberSequenceKeypoint.new(1, 0.1),
	})
	chispas.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.7, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	chispas.Lifetime = NumberRange.new(0.2, 0.6)
	chispas.Rate = 0
	chispas.Speed = NumberRange.new(15, 35)
	chispas.SpreadAngle = Vector2.new(180, 180)
	chispas.Acceleration = Vector3.new(0, -60, 0)
	chispas.Drag = 2
	chispas.Rotation = NumberRange.new(0, 360)
	chispas.RotSpeed = NumberRange.new(-180, 180)
	chispas.Texture = "rbxassetid://288795586" -- spark texture (Roblox default)
	chispas.LightEmission = 1
	chispas.LightInfluence = 0
	chispas.Parent = ancla

	-- ParticleEmitter: humo (lento, ascendente)
	local humo = Instance.new("ParticleEmitter")
	humo.Name = "Humo"
	humo.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 80, 80)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 40)),
	})
	humo.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 2.5),
		NumberSequenceKeypoint.new(1, 4),
	})
	humo.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.5, 0.6),
		NumberSequenceKeypoint.new(1, 1),
	})
	humo.Lifetime = NumberRange.new(0.8, 1.5)
	humo.Rate = 0
	humo.Speed = NumberRange.new(3, 8)
	humo.SpreadAngle = Vector2.new(30, 30)
	humo.Acceleration = Vector3.new(0, 8, 0)
	humo.Drag = 1
	humo.Texture = "rbxassetid://288795586"
	humo.LightEmission = 0
	humo.LightInfluence = 1
	humo.Parent = ancla

	-- Burst inicial
	chispas:Emit(40)
	humo:Emit(15)

	-- Flash de luz: brillo alto → bajo
	local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(luz, tweenInfo, { Brightness = 0, Range = 5 }):Play()

	-- Limpiar
	task.delay(duracion, function()
		if ancla and ancla.Parent then
			ancla:Destroy()
		end
	end)
end

---Efecto de explosión pequeña en el Selector de un nodo.
-- @param nombreNodo string — nombre del nodo en Workspace
function EfectosExplosion.explosionGenerador(nombreNodo)
	print("[EfectosExplosion] 🔍 Buscando selector para:", nombreNodo)
	local selector = buscarSelector(nombreNodo)
	if not selector then
		warn("[EfectosExplosion] Selector no encontrado para:", nombreNodo)
		return
	end
	print("[EfectosExplosion] ✓ Selector encontrado en:", tostring(selector.Position))
	EfectosExplosion.chispazo(selector.Position + Vector3.new(0, 2, 0), 2)
end

return EfectosExplosion
