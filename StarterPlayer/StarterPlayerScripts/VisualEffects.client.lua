-- VisualEffects.client.lua
-- Maneja efectos visuales locales: Cable Dragging y Pulse Traffic

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes")
local cableDragEvent = remotes:WaitForChild("CableDragEvent")
local pulseEvent = remotes:WaitForChild("PulseEvent")
local eventoReiniciar = remotes:WaitForChild("ReiniciarNivel")
if eventoReiniciar then
	print("✅ VisualEffects: Escuchando evento ReiniciarNivel")
end



-- ==========================================
-- CABLE DRAGGING LOGIC
-- ==========================================
local hazActual = nil
local attJugadorActual = nil

local function limpiarCable()
	if hazActual then hazActual:Destroy() end
	if attJugadorActual then attJugadorActual:Destroy() end
	hazActual = nil
	attJugadorActual = nil
end


cableDragEvent.OnClientEvent:Connect(function(action, attStart)
	if action == "Start" and attStart then
		limpiarCable()
		
		local char = player.Character
		if not char then return end
		
		local hand = char:FindFirstChild("RightHand") or char:FindFirstChild("HumanoidRootPart")
		if not hand then return end
		
		attJugadorActual = Instance.new("Attachment")
		attJugadorActual.Name = "CableDragAtt"
		attJugadorActual.Parent = hand
		
		hazActual = Instance.new("Beam")
		hazActual.Name = "VisualDragCable"
		hazActual.Attachment0 = attStart
		hazActual.Attachment1 = attJugadorActual
		hazActual.FaceCamera = true
		hazActual.Width0 = 0.15
		hazActual.Width1 = 0.15
		hazActual.Color = ColorSequence.new(Color3.new(0,0,0))
		hazActual.CurveSize0 = 1
		hazActual.CurveSize1 = 1
		hazActual.Parent = char
		
	elseif action == "Stop" then
		limpiarCable()
	end

end)

-- ==========================================
-- PULSE TRAFFIC LOGIC (PARTICULAS)
-- ==========================================

local pulsosActivos = {} -- { [keyID] = {Parts = {...}} }

local function obtenerClave(p1, p2)
	-- Key única indiferente del orden para enlaces no dirigidos
	if p1.Name < p2.Name then return p1.Name .. "_" .. p2.Name else return p2.Name .. "_" .. p1.Name end
end

local function generarParticulaTrafico(posInicio, posFin, color, duracion)
	local parte = Instance.new("Part")
	parte.Size = Vector3.new(0.6, 0.6, 0.6)
	parte.Shape = Enum.PartType.Ball
	parte.Material = Enum.Material.Neon
	parte.Color = color
	parte.Transparency = 0
	parte.CanCollide = false
	parte.Anchored = true
	parte.Position = posInicio
	parte.Name = "TrafficParticle"
	parte.Parent = workspace
	
	-- Efecto Trail
	local rastro = Instance.new("Trail")
	rastro.Attachment0 = Instance.new("Attachment", parte); rastro.Attachment0.Position = Vector3.new(0, 0.1, 0)
	rastro.Attachment1 = Instance.new("Attachment", parte); rastro.Attachment1.Position = Vector3.new(0, -0.1, 0)
	rastro.FaceCamera = true
	rastro.Lifetime = 0.3
	rastro.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)})
	rastro.Color = ColorSequence.new(color)
	rastro.Parent = parte
	
	-- Animación manual con RenderStepped para loop limpio A->B
	local t = 0
	local conexion
	conexion = RunService.RenderStepped:Connect(function(dt)
		if not parte.Parent then 
			conexion:Disconnect() 
			return 
		end
		
		t = t + (dt / duracion)
		if t > 1 then 
			t = 0 -- Reset instantaneo a inicio
		end
		
		parte.Position = posInicio:Lerp(posFin, t)
	end)
	
	return parte
end


pulseEvent.OnClientEvent:Connect(function(accion, p1, p2, esBidireccional)
	local clave = obtenerClave(p1, p2)
	
	if accion == "StartPulse" then
		if pulsosActivos[clave] then return end -- Evitar duplicados
		
		-- Obtener posiciones
		local att1 = p1:FindFirstChild("Attachment", true) or p1.PrimaryPart
		local att2 = p2:FindFirstChild("Attachment", true) or p2.PrimaryPart
		
		if not att1 or not att2 then return end
		
		local pos1 = att1.WorldPosition
		local pos2 = att2.WorldPosition
		
		local particulas = {}
		
		-- 1. Particula A -> B (Cyan)
		local part1 = generarParticulaTrafico(pos1, pos2, Color3.fromRGB(0, 255, 255), 2.0)
		table.insert(particulas, part1)
		
		-- 2. Particula B -> A (Gold) -- Si es bidireccional
		if esBidireccional then
			local part2 = generarParticulaTrafico(pos2, pos1, Color3.fromRGB(255, 200, 0), 2.0)
			table.insert(particulas, part2)
		end
		
		pulsosActivos[clave] = particulas
		
	elseif accion == "StopPulse" then
		if pulsosActivos[clave] then
			for _, p in ipairs(pulsosActivos[clave]) do
				p:Destroy()
			end
			pulsosActivos[clave] = nil
		end
	end
end)

-- Limpiar partículas al reiniciar
if eventoReiniciar then
	eventoReiniciar.OnClientEvent:Connect(function()
		for clave, particulas in pairs(pulsosActivos) do
			for _, p in ipairs(particulas) do
				p:Destroy()
			end
		end
		table.clear(pulsosActivos)
		print("VisualEffects: Particulas limpiadas por reinicio")
	end)
end

print("VisualEffects Client cargado (Particles + Drag)")
