-- ================================================================
-- StarterPlayer/StarterPlayerScripts/Cliente/Services/DialogueZoneManager.lua
-- SERVICIO CENTRALIZADO para efectos visuales de diálogos en zonas
-- ================================================================
-- PROPÓSITO:
--   - Gestionar cámara (tween, zoom, focus)
--   - Resaltar nodos (Highlights, colores)
--   - Mostrar/ocultar techo
--   - Crear "fake edges" para tutoriales
--   - REUTILIZABLE en todos los diálogos de zona
-- ================================================================

local DialogueZoneManager = {}
DialogueZoneManager.__index = DialogueZoneManager

local TweenService = game:GetService("TweenService")
local workspace = game.Workspace
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ================================================================
-- ESTADO INTERNO
-- ================================================================

local activeHighlights = {}
local activeEdges = {}
local originalCameraState = {
	CFrame = nil,
	Type = nil
}

-- ================================================================
-- INICIALIZACIÓN
-- ================================================================

function DialogueZoneManager:init()
	print("✅ DialogueZoneManager inicializado")
end

-- ================================================================
-- UTILIDADES: BÚSQUEDA DE OBJETOS
-- ================================================================

--- Busca un poste por nombre en el nivel cargado
local function findNodePart(nodeName)
	-- Prioridad: NivelActual (cargado dinámicamente)
	local nivelActual = workspace:FindFirstChild("NivelActual")
	if nivelActual then
		local postes = nivelActual:FindFirstChild("Objetos") 
			and nivelActual.Objetos:FindFirstChild("Postes")

		if postes then
			return postes:FindFirstChild(nodeName)
		end
	end

	-- Fallback: búsqueda recursiva
	for _, desc in ipairs(workspace:GetDescendants()) do
		if desc.Name == nodeName and desc:IsA("Model") then
			return desc
		end
	end

	return nil
end

--- Obtiene la parte principal de un nodo (Selector o PrimaryPart)
local function getNodePart(node)
	if not node then return nil end

	-- Si es una BasePart directa, retornarla
	if node:IsA("BasePart") then
		return node
	end

	-- Intentar Selector primero (más visible)
	local selector = node:FindFirstChild("Selector")
	if selector and selector:IsA("BasePart") then
		return selector
	end

	-- Fallback: PrimaryPart
	if node:IsA("Model") and node.PrimaryPart then
		return node.PrimaryPart
	end

	-- Buscar cualquier BasePart dentro
	for _, child in ipairs(node:GetChildren()) do
		if child:IsA("BasePart") then
			return child
		end
	end

	-- Si nada funciona, buscar en descendientes
	for _, child in ipairs(node:GetDescendants()) do
		if child:IsA("BasePart") then
			return child
		end
	end

	return nil
end

-- ================================================================
-- GESTIÓN DE CÁMARA
-- ================================================================

--- Enfoca cámara en un objetivo con animación suave
-- @param target (Instance) Model o Part a enfocar
-- @param offset (Vector3, opcional) Offset desde el target (default: (15, 15, 15))
-- @param duration (number, opcional) Duración en segundos (default: 1.5)
function DialogueZoneManager:focusCamera(target, offset, duration)
	if not target then 
		warn("❌ DialogueZoneManager: target es nil")
		return 
	end

	offset = offset or Vector3.new(15, 15, 15)
	duration = duration or 1.5

	local camera = workspace.CurrentCamera

	-- Guardar estado original si es la primera vez
	if not originalCameraState.Type then
		originalCameraState.Type = camera.CameraType
		originalCameraState.CFrame = camera.CFrame
		camera.CameraType = Enum.CameraType.Scriptable
	end

	-- Obtener la Part dentro del Model
	local targetPart = getNodePart(target)
	if not targetPart then
		warn("❌ DialogueZoneManager: No se encontró Part en " .. target.Name)
		return
	end

	-- Calcular posición de cámara
	local targetPos = targetPart.Position
	local camPos = targetPos + offset
	local newCFrame = CFrame.new(camPos, targetPos)

	-- Animar con tween
	local tweenInfo = TweenInfo.new(
		duration,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)

	local tween = TweenService:Create(camera, tweenInfo, {CFrame = newCFrame})
	tween:Play()

	print("📷 Cámara enfocada en " .. target.Name)
end

--- Restaura la cámara a su estado original
-- @param duration (number, opcional) Duración en segundos (default: 1.0)
function DialogueZoneManager:restoreCamera(duration)
	duration = duration or 1.0

	if not originalCameraState.Type then return end

	local camera = workspace.CurrentCamera

	-- Determinar target: personaje o posición guardada
	local targetCFrame = originalCameraState.CFrame
	local player = game.Players.LocalPlayer

	if player and player.Character then
		local head = player.Character:FindFirstChild("Head")
		if head then
			targetCFrame = CFrame.new(
				head.Position + Vector3.new(0, 5, 10),
				head.Position
			)
		end
	end

	-- Animar restauración
	local tweenInfo = TweenInfo.new(
		duration,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)

	local tween = TweenService:Create(camera, tweenInfo, {CFrame = targetCFrame})
	tween:Play()

	-- Restaurar tipo de cámara después
	task.wait(duration)
	if originalCameraState.Type then
		camera.CameraType = originalCameraState.Type
	end

	print("📷 Cámara restaurada")
end

-- ================================================================
-- GESTIÓN DE HIGHLIGHTS (RESALTAR NODOS)
-- ================================================================

--- Resalta un nodo con color y outline
-- @param nodeName (string) Nombre del nodo a resaltar
-- @param color (Color3, opcional) Color del resalte (default: azul)
function DialogueZoneManager:highlightNode(nodeName, color)
	color = color or Color3.fromRGB(0, 170, 255)

	local node = findNodePart(nodeName)
	if not node then 
		warn("❌ DialogueZoneManager: Nodo no encontrado: " .. nodeName)
		return 
	end

	-- Guardar propiedades originales
	if not activeHighlights[nodeName] then
		activeHighlights[nodeName] = {
			Node = node,
			Part = getNodePart(node),
			OriginalColor = nil,
			OriginalMaterial = nil,
			Highlight = nil
		}
	end

	local ref = activeHighlights[nodeName]
	local part = ref.Part

	if not part then 
		warn("❌ DialogueZoneManager: No se encontró Part en " .. nodeName)
		return 
	end

	-- Guardar originales
	if not ref.OriginalColor then
		ref.OriginalColor = part.Color
		ref.OriginalMaterial = part.Material
	end

	-- Aplicar cambios visuales
	part.Color = color
	part.Material = Enum.Material.Neon
	part.Transparency = 0

	-- Crear Highlight si no existe (en el Model, no en la Part)
	if not ref.Highlight then
		local highlight = Instance.new("Highlight")
		highlight.Adornee = node
		highlight.FillColor = color
		highlight.OutlineColor = Color3.new(1, 1, 1)
		highlight.FillTransparency = 0.5
		highlight.OutlineTransparency = 0
		highlight.Parent = node
		ref.Highlight = highlight
	else
		-- Actualizar color si ya existe
		ref.Highlight.FillColor = color
	end

	print("🟡 Nodo resaltado: " .. nodeName)
end

--- Resalta múltiples nodos
-- @param nodeNames (table) Array de nombres de nodos
-- @param color (Color3, opcional)
function DialogueZoneManager:highlightMultiple(nodeNames, color)
	if not nodeNames then return end

	for _, nodeName in ipairs(nodeNames) do
		self:highlightNode(nodeName, color)
	end
end

--- Limpia todos los highlights
function DialogueZoneManager:clearAllHighlights()
	for nodeName, ref in pairs(activeHighlights) do
		if ref.Part and ref.OriginalColor and ref.OriginalMaterial then
			ref.Part.Color = ref.OriginalColor
			ref.Part.Material = ref.OriginalMaterial
		end

		if ref.Highlight then
			ref.Highlight:Destroy()
		end
	end

	activeHighlights = {}
	print("🧹 Highlights limpiados")
end

-- ================================================================
-- GESTIÓN DE ARISTAS VISUALES (FAKE EDGES)
-- ================================================================

--- Crea una arista visual falsa entre dos nodos (para tutoriales)
-- @param nodeName1 (string) Nombre del primer nodo
-- @param nodeName2 (string) Nombre del segundo nodo
-- @param color (Color3, opcional) Color de la arista (default: amarillo)
local function createFakeEdge(nodeName1, nodeName2, color)
	color = color or Color3.fromRGB(255, 255, 0)

	local node1 = findNodePart(nodeName1)
	local node2 = findNodePart(nodeName2)

	if not node1 or not node2 then
		warn("❌ DialogueZoneManager: Uno o ambos nodos no encontrados")
		return nil
	end

	-- Obtener partes dentro de los Models
	local part1 = getNodePart(node1)
	local part2 = getNodePart(node2)

	if not part1 or not part2 then
		warn("❌ DialogueZoneManager: No se encontraron Parts en los nodos")
		return nil
	end

	-- Obtener attachments existentes
	local att1 = part1:FindFirstChild("Attachment", true)
	local att2 = part2:FindFirstChild("Attachment", true)

	-- Crear attachments temporales si no existen
	if not att1 then
		att1 = Instance.new("Attachment")
		att1.Parent = part1
		activeEdges[nodeName1 .. "_att"] = att1
	end

	if not att2 then
		att2 = Instance.new("Attachment")
		att2.Parent = part2
		activeEdges[nodeName2 .. "_att"] = att2
	end

	-- Crear RopeConstraint (cable visual)
	local dist = (att1.WorldPosition - att2.WorldPosition).Magnitude

	local rope = Instance.new("RopeConstraint")
	rope.Name = "FakeEdge_" .. nodeName1 .. "_" .. nodeName2
	rope.Attachment0 = att1
	rope.Attachment1 = att2
	rope.Length = dist
	rope.Visible = true
	rope.Thickness = 0.3
	rope.Color = BrickColor.new(color)
	rope.Parent = workspace

	local key = nodeName1 .. "_" .. nodeName2
	activeEdges[key] = rope

	print("➡️ Arista visual creada: " .. nodeName1 .. " -> " .. nodeName2)

	return rope
end

--- Crea múltiples aristas visuales
-- @param edges (table) Array de {node1, node2, color}
function DialogueZoneManager:createFakeEdges(edges)
	if not edges then return end

	for _, edge in ipairs(edges) do
		createFakeEdge(edge[1], edge[2], edge[3])
	end
end

--- Limpia todas las aristas visuales
function DialogueZoneManager:clearAllFakeEdges()
	for key, obj in pairs(activeEdges) do
		if obj and obj.Parent then
			obj:Destroy()
		end
	end

	activeEdges = {}
	print("🧹 Aristas visuales limpiadas")
end

-- ================================================================
-- GESTIÓN DE TECHO
-- ================================================================

--- Muestra u oculta el techo del nivel
-- @param visible (boolean) true para mostrar, false para ocultar
function DialogueZoneManager:toggleRoof(visible)
	local nivelActual = workspace:FindFirstChild("NivelActual")
	if not nivelActual then return end

	local techo = nivelActual:FindFirstChild("Techo", true)
	if not techo then return end

	local opacity = visible and 0 or 1
	local active = visible

	-- Obtener todas las partes del techo
	local parts = {}
	if techo:IsA("BasePart") then
		table.insert(parts, techo)
	end

	for _, part in ipairs(techo:GetDescendants()) do
		if part:IsA("BasePart") then
			table.insert(parts, part)
		end
	end

	-- Aplicar cambios
	for _, part in ipairs(parts) do
		part.Transparency = opacity
		part.CanCollide = active
		part.CastShadow = active
		part.CanQuery = active
		part.CanTouch = active
	end

	print(visible and "🏠 Techo mostrado" or "🏠 Techo ocultado")
end

-- ================================================================
-- SECUENCIAS COMUNES (PRESETS)
-- ================================================================

--- Limpia TODOS los efectos visuales
function DialogueZoneManager:cleanAll()
	self:clearAllHighlights()
	self:clearAllFakeEdges()
	self:restoreCamera(0.5)
	self:toggleRoof(true) -- Mostrar techo al terminar

	print("🧹 Todos los efectos visuales limpiados")
end

--- Setup inicial para mostrar una zona (mostrar techo, preparar cámara)
function DialogueZoneManager:setupZoneView()
	self:toggleRoof(false) -- Ocultar techo para mejor vista
	print("📍 Zona lista para diálogo")
end

--- Cleanup final después de un diálogo (restaurar todo)
function DialogueZoneManager:cleanupZoneView()
	self:cleanAll()
end

return DialogueZoneManager