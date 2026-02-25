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
local activeBlinkThreads = {} -- Almacena threads de parpadeo activos { [node] = thread }
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

--- Restaurar material de un nodo
local function restoreNodeMaterial(node)
	if not node then return end
	local parts = node:GetDescendants()
	if node:IsA("BasePart") then
		table.insert(parts, node)
	end
	for _, part in ipairs(parts) do
		if part:IsA("BasePart") then
			part.Material = Enum.Material.Neon -- Restaurar a Neon por defecto
		end
	end
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
	-- 1. Limpiar Highlights y Materiales
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

	-- 2. Detener Parpadeos
	for node, thread in pairs(activeBlinkThreads) do
		if thread then task.cancel(thread) end
		restoreNodeMaterial(node)
	end
	activeBlinkThreads = {}
end

--- Mostrar etiqueta sobre un nodo
function VisualEffectsService:showNodeLabel(node, text)
	if not node then return end
	
	local part = node:IsA("Model") and node.PrimaryPart or node
	if not part then return end

	local bb = Instance.new("BillboardGui")
	bb.Name = "NodeLabel"
	bb.Size = UDim2.new(0, 150, 0, 50)
	bb.StudsOffset = Vector3.new(0, 4, 0)
	bb.AlwaysOnTop = true
	bb.Parent = part
	
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.TextStrokeTransparency = 0
	lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
	lbl.Font = Enum.Font.FredokaOne
	lbl.TextSize = 20
	lbl.Parent = bb

	table.insert(activeHighlights, bb)
	
	-- Efecto de aparición
	bb.Size = UDim2.new(0, 0, 0, 0)
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(bb, tweenInfo, {Size = UDim2.new(0, 150, 0, 50)}):Play()
end

--- Crear arista visual con cable, parpadeo y etiqueta
--- Crear arista visual con cable, parpadeo y etiqueta
function VisualEffectsService:createFakeEdge(node1, node2, color)
	if not node1 or not node2 then return end

	-- Buscar Attachments o crear temporales en la posición central
	local function getOrCreateAtt(node, name)
		-- Intentar usar un attachment existente si está bien ubicado, o crear uno nuevo en el centro
		local part = node:IsA("Model") and node.PrimaryPart or node
		
		local existing = part:FindFirstChild(name)
		if existing then return existing end

		local att = Instance.new("Attachment")
		att.Name = name
		att.Parent = part
		table.insert(activeHighlights, att)
		return att
	end

	local att1 = getOrCreateAtt(node1, "TempAtt1")
	local att2 = getOrCreateAtt(node2, "TempAtt2")

	local dist = (att1.WorldPosition - att2.WorldPosition).Magnitude

	-- Crear RopeConstraint (Cable Visual) - Restaurado
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

	-- EFECTO DE PARPADEO DEL CABLE (Restaurado para Rope)
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
	-- No necesitamos trackear este thread explícitamente porque el loop termina si beam.Parent es nil

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

--- Hacer que un nodo parpadee (cambio de material)
-- @param node (Instance) el nodo a parpadear
-- @param duration (number) duración total en segundos
-- @param frequency (number, opcional) parpadeos por segundo (default: 2)
function VisualEffectsService:blink(node, duration, frequency)
	if not node then return end

	-- Detener parpadeo previo si existe
	if activeBlinkThreads[node] then
		task.cancel(activeBlinkThreads[node])
		activeBlinkThreads[node] = nil
		restoreNodeMaterial(node)
	end

	duration = duration or 3
	frequency = frequency or 2
	local interval = 1 / frequency

	activeBlinkThreads[node] = task.spawn(function()
		local isVisible = true
		local elapsed = 0

		while elapsed < duration do
			task.wait(interval)
			elapsed = elapsed + interval

			-- Cambiar material para efecto parpadeo
			local parts = node:GetDescendants()
			if node:IsA("BasePart") then
				table.insert(parts, node)
			end

			for _, part in ipairs(parts) do
				if part:IsA("BasePart") then
					part.Material = isVisible and Enum.Material.Neon or Enum.Material.Plastic
				end
			end

			isVisible = not isVisible
		end

		-- Restaurar a Neon al terminar
		restoreNodeMaterial(node)
		activeBlinkThreads[node] = nil
	end)
end

return VisualEffectsService