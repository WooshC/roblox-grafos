-- ReplicatedStorage/Efectos/EfectosCable.lua
-- Efectos visuales para cables (cliente)

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local PresetTween = require(script.Parent.PresetTween)

local EfectosCable = {}

EfectosCable.pulsosActivos = {}

function EfectosCable.crearBeamVisual(attachment0, attachment1, parent)
	local beam = Instance.new("Beam")
	beam.Name = "CableVisual"
	beam.Attachment0 = attachment0
	beam.Attachment1 = attachment1
	beam.Color = ColorSequence.new(PresetTween.COLORES.CABLE_NORMAL)
	beam.Width0 = 0.13
	beam.Width1 = 0.13
	beam.CurveSize0 = 0
	beam.CurveSize1 = 0
	beam.LightEmission = 0.6
	beam.LightInfluence = 0.4
	beam.Transparency = NumberSequence.new(0)
	beam.FaceCamera = true
	beam.Segments = 10
	beam.Parent = parent
	
	-- Animación de aparecer
	beam.Width0 = 0
	beam.Width1 = 0
	TweenService:Create(beam, PresetTween.PRESETS.CABLE_APARECER, {
		Width0 = 0.13,
		Width1 = 0.13
	}):Play()
	
	return beam
end

function EfectosCable.iniciarPulso(beam, esBidireccional)
	if not beam or not beam.Parent then return end
	
	local idPulso = beam:GetFullName()
	
	-- Detener pulso anterior si existe
	if EfectosCable.pulsosActivos[idPulso] then
		EfectosCable.pulsosActivos[idPulso]:Disconnect()
	end
	
	-- Crear textura de pulso
	local textura = Instance.new("Texture")
	textura.Name = "PulsoEnergia"
	textura.Texture = "rbxassetid://258128463" -- Efecto de energía
	textura.StudsPerTileU = 5
	textura.StudsPerTileV = 1
	textura.OffsetStudsV = 0.5
	textura.Transparency = 0.3
	textura.Parent = beam
	
	-- Animar el pulso
	local offset = 0
	local velocidad = esBidireccional and 2 or 1
	
	EfectosCable.pulsosActivos[idPulso] = RunService.Heartbeat:Connect(function(dt)
		if not textura or not textura.Parent then
			EfectosCable.pulsosActivos[idPulso]:Disconnect()
			EfectosCable.pulsosActivos[idPulso] = nil
			return
		end
		
		offset = offset + (dt * velocidad)
		if offset > 1 then offset = 0 end
		
		textura.OffsetStudsU = offset * 5
	end)
end

function EfectosCable.detenerPulso(beam)
	if not beam then return end
	
	local idPulso = beam:GetFullName()
	if EfectosCable.pulsosActivos[idPulso] then
		EfectosCable.pulsosActivos[idPulso]:Disconnect()
		EfectosCable.pulsosActivos[idPulso] = nil
	end
	
	local textura = beam:FindFirstChild("PulsoEnergia")
	if textura then
		textura:Destroy()
	end
end

function EfectosCable.detenerTodosLosPulsos()
	for idPulso, conexion in pairs(EfectosCable.pulsosActivos) do
		conexion:Disconnect()
	end
	EfectosCable.pulsosActivos = {}
end

function EfectosCable.crearPreviewArrastre(attachmentOrigen, posicionMouse)
	-- Crear un beam temporal para preview
	local attachmentMouse = Instance.new("Attachment")
	attachmentMouse.Name = "AttachmentPreview"
	attachmentMouse.WorldPosition = posicionMouse
	
	-- Crear part anclada invisible para el attachment
	local partSoporte = Instance.new("Part")
	partSoporte.Name = "SoportePreview"
	partSoporte.Anchored = true
	partSoporte.CanCollide = false
	partSoporte.Transparency = 1
	partSoporte.Size = Vector3.new(1, 1, 1)
	partSoporte.Position = posicionMouse
	partSoporte.Parent = workspace
	
	attachmentMouse.Parent = partSoporte
	
	local beam = Instance.new("Beam")
	beam.Name = "PreviewArrastre"
	beam.Attachment0 = attachmentOrigen
	beam.Attachment1 = attachmentMouse
	beam.Color = ColorSequence.new(PresetTween.COLORES.CABLE_NORMAL)
	beam.Width0 = 0.08
	beam.Width1 = 0.08
	beam.CurveSize0 = 0.5 -- Curva suave para el preview
	beam.CurveSize1 = 0.5
	beam.LightEmission = 0.4
	beam.Transparency = NumberSequence.new(0.3)
	beam.FaceCamera = true
	beam.Parent = partSoporte
	
	return {
		beam = beam,
		attachmentMouse = attachmentMouse,
		partSoporte = partSoporte,
		actualizar = function(nuevaPosicion)
			if partSoporte and partSoporte.Parent then
				partSoporte.Position = nuevaPosicion
			end
		end,
		destruir = function()
			if partSoporte then
				partSoporte:Destroy()
			end
		end
	}
end

return EfectosCable
