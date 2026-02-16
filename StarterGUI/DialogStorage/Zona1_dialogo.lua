local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local dialogueKitModule = require(script.Parent.Parent.DialogueKit)
local DialogueGenerator = require(script.Parent.DialogueGenerator)

-- Intentar cargar VisibilityManager
local player = Players.LocalPlayer
local PlayerScripts = player:WaitForChild("PlayerScripts")
local VisibilityManager = nil

task.spawn(function()
	local success, result = pcall(function()
		return require(PlayerScripts:WaitForChild("Cliente"):WaitForChild("Services"):WaitForChild("VisibilityManager"))
	end)
	if success then
		VisibilityManager = result
	else
		warn("⚠️ Zona1_dialogo: No se pudo cargar VisibilityManager: " .. tostring(result))
	end
end)

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
	-- Intentar buscar en todo el workspace recursivamente
	-- Imprimiremos dónde estamos buscando para debug
	print("🔍 Buscando nodo: " .. nodeName)
	
	for _, desc in ipairs(workspace:GetDescendants()) do
		if desc.Name == nodeName then
			-- Encontramos algo con el nombre, verificamos si es modelo o parte
			if desc:IsA("Model") then
				local part = desc.PrimaryPart or desc:FindFirstChild("Selector") or desc:FindFirstChildWhichIsA("BasePart")
				if part then 
					print("✅ Nodo encontrado (Model): " .. desc:GetFullName())
					return part 
				end
			elseif desc:IsA("BasePart") then
				print("✅ Nodo encontrado (Part): " .. desc:GetFullName())
				return desc
			end
		end
	end
	
	warn("❌ NO SE ENCONTRÓ EL NODO: " .. nodeName)
	return nil
end

-- Mover cámara a un objetivo
local function focusCameraOn(targetPart, offset)
	if not targetPart then 
		warn("⚠️ focusCameraOn: targetPart es nil")
		return 
	end
	
	print("🎥 Enfocando cámara en: " .. targetPart.Name)
	
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
	print("🎥 Restaurando cámara...")
	if originalCameraType then
		local tweenInfo = TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		-- Intentar volver al personaje
		local targetCFrame = originalCameraCFrame
		if player.Character and player.Character:FindFirstChild("Head") then
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

-- Limpiar efecto
local function clearEffects()
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
			-- Ocultar HUD
			if VisibilityManager then VisibilityManager:setDialogueMode(true) end
			
			-- Enfocar cámara
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
			
			if n1 and n2 then
				local midPoint = n1.Position:Lerp(n2.Position, 0.5)
				local camPos = midPoint + Vector3.new(0, 20, 10) 
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
			local n1 = findNodePart("Nodo1_z1")
			if n1 then
				focusCameraOn(n1, Vector3.new(5, 8, 5))
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
			-- Mostrar HUD
			if VisibilityManager then VisibilityManager:setDialogueMode(false) end
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
