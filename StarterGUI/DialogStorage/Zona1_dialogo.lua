local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local dialogueKitModule = require(script.Parent.Parent.DialogueKit)
local DialogueGenerator = require(script.Parent.DialogueGenerator)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local SKIN_NAME = "Hotline" 

-- ============================================================================
-- 1. UTILIDADES VISUALES (CÁMARA Y HIGHLIGHTS)
-- ============================================================================

local activeHighlights = {}
local originalCameraCFrame = nil
local originalCameraType = nil

-- Buscar nodo en el mapa (por nombre)
local function findNodePart(nodeName)
	-- Intentar buscar en la carpeta de Nivel cargado
	for _, desc in ipairs(workspace:GetDescendants()) do
		-- Buscamos el "Selector" dentro del modelo del nodo, o el modelo mismo
		if desc.Name == nodeName and desc:IsA("Model") then
			return desc.PrimaryPart or desc:FindFirstChild("Selector") or desc:FindFirstChildWhichIsA("BasePart")
		end
	end
	return nil
end

-- Mover cámara a un objetivo
local function focusCameraOn(targetPart, offset)
	if not targetPart then return end
	
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
end

-- Restaurar cámara
local function restoreCamera()
	if originalCameraType then
		local tweenInfo = TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		-- Intentar volver a la posición original o al personaje
		local targetCFrame = originalCameraCFrame
		if player.Character and player.Character:FindFirstChild("Head") then
			-- Resetear suavemente hacia la vista del personaje
			targetCFrame = CFrame.new(player.Character.Head.Position + Vector3.new(0, 5, 10), player.Character.Head.Position)
		end
		
		local tween = TweenService:Create(camera, tweenInfo, {CFrame = targetCFrame})
		tween:Play()
		
		task.delay(1.0, function()
			camera.CameraType = originalCameraType or Enum.CameraType.Custom
			originalCameraType = nil
		end)
	end
end

-- Resaltar objeto
local function highlightObject(target, color)
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

	-- 2. Efecto Neon (opcional)
	if part then
		-- Guardamos material original en atributo para restaurar luego si queremos
		part:SetAttribute("OriginalMaterial", part.Material)
		part:SetAttribute("OriginalColor", part.Color)
		part.Material = Enum.Material.Neon
		part.Color = color
		
		-- Agregar a lista de limpieza especial si es necesario, 
		-- pero por simplicidad solo limpiamos el Highlight y revertimos manual.
		table.insert(activeHighlights, {Part = part, Type = "Material"})
	end
end

-- Limpiar efecto
local function clearEffects()
	for _, item in ipairs(activeHighlights) do
		if typeof(item) == "Instance" then
			item:Destroy()
		elseif type(item) == "table" and item.Type == "Material" then
			-- Restaurar material
			local part = item.Part
			if part then
				part.Material = part:GetAttribute("OriginalMaterial") or Enum.Material.Plastic
				part.Color = part:GetAttribute("OriginalColor") or Color3.new(1, 1, 1)
			end
		end
	end
	activeHighlights = {}
end

-- ============================================================================
-- 2. ZONA DE EDICIÓN DE DIÁLOGOS
-- ============================================================================

local DATA_DIALOGOS = {
	["Inicio"] = {
		Actor = "Carlos",
		Expresion = "Serio",
		Texto = {
			"Bien, has llegado a la Zona 1. Aquí pondremos en práctica la teoría.",
			"Escucha con atención, porque no repetiré esto dos veces."
		},
		Sonido = { "rbxassetid://0", "rbxassetid://0" },
		Evento = function()
			-- Solo enfocar la cámara general
			local nodo1 = findNodePart("Nodo1_z1")
			if nodo1 then focusCameraOn(nodo1, Vector3.new(15, 15, 15)) end
		end,
		Siguiente = "Explicacion_Objetivo"
	},

	["Explicacion_Objetivo"] = {
		Actor = "Carlos",
		Expresion = "Presentacion",
		Texto = "Tu objetivo es simple: Conectar el Nodo 1 con el Nodo 2 para restablecer el flujo en este sector.",
		Sonido = "rbxassetid://0",
		Evento = function()
			clearEffects()
			local n1 = findNodePart("Nodo1_z1")
			local n2 = findNodePart("Nodo2_z1")
			
			if n1 then highlightObject(n1, Color3.fromRGB(0, 255, 0)) end -- Verde
			if n2 then highlightObject(n2, Color3.fromRGB(255, 0, 0)) end -- Rojo
			
			-- Mover cámara entre los dos
			if n1 and n2 then
				local midPoint = n1.Position:Lerp(n2.Position, 0.5)
				local camPos = midPoint + Vector3.new(0, 20, 10) -- Altura isométrica
				local newCF = CFrame.new(camPos, midPoint)
				
				TweenService:Create(camera, TweenInfo.new(1.5), {CFrame = newCF}):Play()
			end
		end,
		Siguiente = "Instruccion_Tecnica"
	},

	["Instruccion_Tecnica"] = {
		Actor = "Sistema",
		Expresion = "Arista",
		Texto = "Haz Click en el 'Nodo 1' (Verde) y luego en el 'Nodo 2' para crear una ARISTA (Cable).",
		Sonido = "rbxassetid://0",
		Evento = function()
			-- Enfocar agresivamente en Nodo 1 primero
			local n1 = findNodePart("Nodo1_z1")
			if n1 then
				focusCameraOn(n1, Vector3.new(5, 8, 5))
				-- Parpadeo o highlight intenso (ya está verde, lo mantenemos)
			end
		end,
		Siguiente = "Despedida"
	},

	["Despedida"] = {
		Actor = "Carlos",
		Expresion = "Sonriente",
		Texto = "Si lo haces bien, verás como la energía fluye. ¡Adelante!",
		Sonido = "rbxassetid://0",
		Evento = function()
			clearEffects()
			restoreCamera()
		end,
		Siguiente = "FIN"
	}
}

-- ============================================================================
-- 3. LÓGICA DE ACTIVACIÓN (ZONA ID)
-- ============================================================================

local ZONA_OBJETIVO = "Zona_Estacion_1"
local yaSeMostro = false

local function checkZone(newZone)
	if yaSeMostro then return end
	
	if newZone == ZONA_OBJETIVO then
		-- Doble chequeo: solo si hay personaje vivo
		if not player.Character then return end
		
		yaSeMostro = true
		print("✅ Zona 1 detectada (Sistema de Zonas) - Iniciando Diálogo Interactivo")
		
		-- Generar y lanzar diálogo
		local layersComplejas = DialogueGenerator.GenerarEstructura(DATA_DIALOGOS, SKIN_NAME)
		
		dialogueKitModule.CreateDialogue({
			InitialLayer = "Inicio", 
			SkinName = SKIN_NAME, 
			Config = script:FindFirstChild(SKIN_NAME .. "Config") or script, 
			Layers = layersComplejas
		})
	end
end

-- Listener para cambios de zona
player:GetAttributeChangedSignal("CurrentZone"):Connect(function()
	local zona = player:GetAttribute("CurrentZone")
	checkZone(zona)
end)

-- Chequear estado inicial
task.delay(1, function()
	local zona = player:GetAttribute("CurrentZone")
	if zona then checkZone(zona) end
end)
