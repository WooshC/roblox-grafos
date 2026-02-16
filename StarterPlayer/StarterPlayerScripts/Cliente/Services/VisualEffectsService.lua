-- ================================================================
-- StarterPlayer/StarterPlayerScripts/Cliente/Services/VisualEffectsService.lua
-- Módulo centralizado con TODA la lógica visual del script original
-- ================================================================

local VisualEffectsService = {}
VisualEffectsService.__index = VisualEffectsService

local TweenService = game:GetService("TweenService")
local workspace = game.Workspace

-- ================================================================
-- ESTADO INTERNO
-- ================================================================

local activeHighlights = {}
local originalCameraCFrame = nil
local originalCameraType = nil

-- ================================================================
-- UTILIDADES PRIVADAS
-- ================================================================

--- Buscar nodo en el mapa (por nombre)
local function findNodePart(nodeName)
	for _, desc in ipairs(workspace:GetDescendants()) do
		if desc.Name == nodeName and desc:IsA("Model") then
			return desc.PrimaryPart or desc:FindFirstChild("Selector") or desc:FindFirstChildWhichIsA("BasePart")
		end
	end
	return nil
end

--- Obtener camera
local function getCamera()
	return workspace.CurrentCamera
end

--- Obtener player
local function getPlayer()
	return game.Players.LocalPlayer
end

-- ================================================================
-- API PÚBLICA
-- ================================================================

--- Mover cámara a un objetivo
function VisualEffectsService:focusCameraOn(targetPart, offset)
	if not targetPart then return end

	local camera = getCamera()

	-- Guardar estado original si es la primera vez
	if camera.CameraType ~= Enum.CameraType.Scriptable then
		originalCameraCFrame = camera.CFrame
		originalCameraType = camera.CameraType
		camera.CameraType = Enum.CameraType.Scriptable
	end

	local targetPos = targetPart.Position
	local camPos = targetPos + (offset or Vector3.new(10, 10, 10))
	local newCFrame = CFrame.new(camPos, targetPos)

	local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(camera, tweenInfo, {CFrame = newCFrame})
	tween:Play()

	return tween
end

--- Restaurar cámara a estado original
function VisualEffectsService:restoreCamera()
	if not originalCameraType then return end

	local camera = getCamera()
	local player = getPlayer()
	local tweenInfo = TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	-- Intentar volver a la posición original o al personaje
	local targetCFrame = originalCameraCFrame
	if player.Character and player.Character:FindFirstChild("Head") then
		-- Resetear suavemente hacia la vista del personaje
		targetCFrame = CFrame.new(
			player.Character.Head.Position + Vector3.new(0, 5, 10),
			player.Character.Head.Position
		)
	end

	local tween = TweenService:Create(camera, tweenInfo, {CFrame = targetCFrame})
	tween:Play()

	task.delay(1.0, function()
		camera.CameraType = originalCameraType or Enum.CameraType.Custom
		originalCameraType = nil
	end)

	return tween
end

--- Resaltar objeto con color
function VisualEffectsService:highlightObject(target, color)
	if not target then return end

	-- Si es un modelo, buscar su parte principal
	local model = target:IsA("Model") and target or target.Parent
	local part = target:IsA("BasePart") and target or (model and model.PrimaryPart)

	if not model then return end

	-- 1. Crear Highlight
	local h = Instance.new("Highlight")
	h.Adornee = model
	h.FillColor = color
	h.OutlineColor = Color3.new(1, 1, 1)
	h.FillTransparency = 0.5
	h.OutlineTransparency = 0
	h.Parent = model
	table.insert(activeHighlights, h)

	-- 2. Efecto Neon
	if part then
		part:SetAttribute("OriginalMaterial", part.Material)
		part:SetAttribute("OriginalColor", part.Color)
		part.Material = Enum.Material.Neon
		part.Color = color
		table.insert(activeHighlights, {Part = part, Type = "Material"})
	end
end

--- Limpiar todos los efectos
function VisualEffectsService:clearEffects()
	for _, item in ipairs(activeHighlights) do
		if typeof(item) == "Instance" then
			item:Destroy()
		elseif type(item) == "table" and item.Type == "Material" then
			local part = item.Part
			if part then
				part.Material = part:GetAttribute("OriginalMaterial") or Enum.Material.Plastic
				part.Color = part:GetAttribute("OriginalColor") or Color3.new(1, 1, 1)
			end
		end
	end
	activeHighlights = {}
end

--- Crear arista visual con cable, parpadeo y etiqueta
function VisualEffectsService:createFakeEdge(node1, node2, color)
	if not node1 or not node2 then return end

	-- Buscar Attachments o crear temporales
	local att1 = node1:FindFirstChild("Attachment", true) 
	local att2 = node2:FindFirstChild("Attachment", true)

	if not att1 then
		att1 = Instance.new("Attachment")
		att1.Name = "TempAtt1"
		att1.Parent = node1:IsA("Model") and node1.PrimaryPart or node1
		table.insert(activeHighlights, att1)
	end

	if not att2 then
		att2 = Instance.new("Attachment")
		att2.Name = "TempAtt2"
		att2.Parent = node2:IsA("Model") and node2.PrimaryPart or node2
		table.insert(activeHighlights, att2)
	end

	local dist = (att1.WorldPosition - att2.WorldPosition).Magnitude

	-- Crear RopeConstraint (Cable Visual)
	local rope = Instance.new("RopeConstraint")
	rope.Name = "FakeEdgeRope"
	rope.Attachment0 = att1
	rope.Attachment1 = att2
	rope.Length = dist
	rope.Visible = true
	rope.Thickness = 0.3 
	rope.Color = BrickColor.new(color)
	rope.Parent = workspace

	table.insert(activeHighlights, rope)

	-- EFECTO DE PARPADEO
	task.spawn(function()
		local t = 0
		while rope and rope.Parent do
			t = t + 0.1
			local alpha = (math.sin(t * 5) + 1) / 2
			rope.Thickness = 0.3 + (alpha * 0.2)
			if alpha > 0.5 then
				rope.Color = BrickColor.new(color)
			else
				rope.Color = BrickColor.new("White")
			end
			task.wait(0.05)
		end
	end)

	-- ETIQUETA "ARISTA"
	local midPoint = (att1.WorldPosition + att2.WorldPosition) / 2
	local labelPart = Instance.new("Part")
	labelPart.Name = "AristaLabelPart"
	labelPart.Size = Vector3.new(0.1, 0.1, 0.1)
	labelPart.Transparency = 1
	labelPart.Anchored = true
	labelPart.CanCollide = false
	labelPart.Position = midPoint
	labelPart.Parent = workspace
	table.insert(activeHighlights, labelPart)

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 100, 0, 50)
	bb.StudsOffset = Vector3.new(0, 2, 0)
	bb.AlwaysOnTop = true
	bb.Parent = labelPart

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = "⬇ ARISTA"
	lbl.TextColor3 = Color3.fromRGB(255, 255, 0)
	lbl.TextStrokeTransparency = 0
	lbl.Font = Enum.Font.FredokaOne
	lbl.TextSize = 24
	lbl.Parent = bb

	-- Animacion de la etiqueta
	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local tween = TweenService:Create(bb, tweenInfo, {StudsOffset = Vector3.new(0, 3, 0)})
	tween:Play()
end

--- Toggle visibilidad del Techo
function VisualEffectsService:toggleTecho(visible)
	local opacity = visible and 0 or 1
	local active = visible

	local nivelActual = workspace:FindFirstChild("NivelActual")
	if nivelActual then
		local techoObj = nivelActual:FindFirstChild("Techo", true)

		if techoObj then
			local parts = {}
			if techoObj:IsA("BasePart") then
				table.insert(parts, techoObj)
			end
			for _, p in ipairs(techoObj:GetDescendants()) do
				if p:IsA("BasePart") then
					table.insert(parts, p)
				end
			end

			for _, part in ipairs(parts) do
				part.Transparency = opacity
				part.CanCollide = active
				part.CastShadow = active
				part.CanQuery = active
				part.CanTouch = active
			end
		end
	end
end

--- Buscar nodo por nombre (API pública)
function VisualEffectsService:findNodeByName(nodeName)
	return findNodePart(nodeName)
end

return VisualEffectsService