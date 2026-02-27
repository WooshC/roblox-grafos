-- StarterPlayerScripts/Dialogo/DialogoGUISystem.lua
-- Sistema principal de diálogos - Adaptado para GrafosV3

--[[
    ╔════════════════════════════════════════════════════════════════╗
    ║               DIALOGOGUISYSTEM — SISTEMA PRINCIPAL             ║
    ║            Centro de control de todos los diálogos              ║
    ╚════════════════════════════════════════════════════════════════╝
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DialogoGUISystem = {}
DialogoGUISystem.__index = DialogoGUISystem

-- Estado
DialogoGUISystem.gui = {}
DialogoGUISystem.isPlaying = false
DialogoGUISystem.currentDialogue = {}
DialogoGUISystem.currentLineIndex = 1
DialogoGUISystem.metadata = {}
DialogoGUISystem.controller = nil
DialogoGUISystem.renderer = nil
DialogoGUISystem.narrator = nil
DialogoGUISystem.events = nil

-- Referencias a módulos (se establecen externamente)
DialogoGUISystem._modules = nil

---Establece las dependencias del sistema
function DialogoGUISystem:SetModules(modules)
	self._modules = modules
end

-- ════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ════════════════════════════════════════════════════════════════

function DialogoGUISystem:Init()
	print("[DialogoGUISystem] Inicializando sistema...")
	
	if not self._modules then
		error("[DialogoGUISystem] Módulos no establecidos. Llama SetModules primero.")
	end
	
	-- Obtener los módulos
	local DialogoController = self._modules.DialogoController
	local DialogoRenderer = self._modules.DialogoRenderer
	local DialogoNarrator = self._modules.DialogoNarrator
	local DialogoEvents = self._modules.DialogoEvents
	
	if not (DialogoController and DialogoRenderer and DialogoNarrator and DialogoEvents) then
		error("[DialogoGUISystem] Faltan módulos requeridos")
	end
	
	-- Obtener la GUI del jugador
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local screenGui = playerGui:WaitForChild("DialogoGUI", 5)
	
	if not screenGui then
		warn("[DialogoGUISystem] DialogoGUI no encontrada. Creando GUI básica...")
		screenGui = self:CrearGUIBasica(playerGui)
	end
	
	-- Obtener referencias a elementos GUI
	self.gui = self:ObtenerReferenciasGUI(screenGui)
	
	-- Inicializar módulos
	self.controller = DialogoController.new(self.gui, self)
	self.renderer = DialogoRenderer.new(self.gui)
	self.narrator = DialogoNarrator.new()
	
	-- Pasar TTS al narrator si está disponible
	if self._modules.DialogoTTS then
		local ttsInstance = self._modules.DialogoTTS.new()
		if ttsInstance then
			self.narrator:SetTTS(ttsInstance)
		end
	end
	
	self.events = DialogoEvents.new(self.gui, self.controller)
	
	-- Ocultar GUI inicialmente
	screenGui.Enabled = false
	
	print("[DialogoGUISystem] ✓ Sistema inicializado")
end

---Crea una GUI básica si no existe
function DialogoGUISystem:CrearGUIBasica(playerGui)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DialogoGUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui
	
	-- Canvas principal
	local canvas = Instance.new("Frame")
	canvas.Name = "Canvas"
	canvas.Size = UDim2.new(1, 0, 1, 0)
	canvas.BackgroundTransparency = 1
	canvas.Parent = screenGui
	
	-- DialogueBox
	local dialogueBox = Instance.new("Frame")
	dialogueBox.Name = "DialogueBox"
	dialogueBox.Size = UDim2.new(0.6, 0, 0.25, 0)
	dialogueBox.Position = UDim2.new(0.2, 0, 0.7, 0)
	dialogueBox.BackgroundColor3 = Color3.fromRGB(17, 28, 46)
	dialogueBox.BorderSizePixel = 0
	dialogueBox.Parent = canvas
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = dialogueBox
	
	-- SpeakerTag
	local speakerTag = Instance.new("Frame")
	speakerTag.Name = "SpeakerTag"
	speakerTag.Size = UDim2.new(0, 120, 0, 30)
	speakerTag.Position = UDim2.new(0, 15, 0, -15)
	speakerTag.BackgroundColor3 = Color3.fromRGB(0, 207, 255)
	speakerTag.Parent = dialogueBox
	
	local cornerTag = Instance.new("UICorner")
	cornerTag.CornerRadius = UDim.new(0, 6)
	cornerTag.Parent = speakerTag
	
	local speakerName = Instance.new("TextLabel")
	speakerName.Name = "SpeakerName"
	speakerName.Size = UDim2.new(1, 0, 1, 0)
	speakerName.BackgroundTransparency = 1
	speakerName.Text = "Personaje"
	speakerName.TextColor3 = Color3.fromRGB(255, 255, 255)
	speakerName.TextSize = 14
	speakerName.Font = Enum.Font.GothamBold
	speakerName.Parent = speakerTag
	
	-- DialogueText
	local textArea = Instance.new("Frame")
	textArea.Name = "TextArea"
	textArea.Size = UDim2.new(1, -30, 0.6, 0)
	textArea.Position = UDim2.new(0, 15, 0, 25)
	textArea.BackgroundTransparency = 1
	textArea.Parent = dialogueBox
	
	local dialogueText = Instance.new("TextLabel")
	dialogueText.Name = "DialogueText"
	dialogueText.Size = UDim2.new(1, 0, 1, 0)
	dialogueText.BackgroundTransparency = 1
	dialogueText.Text = ""
	dialogueText.TextColor3 = Color3.fromRGB(221, 233, 245)
	dialogueText.TextSize = 16
	dialogueText.Font = Enum.Font.Gotham
	dialogueText.TextWrapped = true
	dialogueText.TextXAlignment = Enum.TextXAlignment.Left
	dialogueText.TextYAlignment = Enum.TextYAlignment.Top
	dialogueText.Parent = textArea
	
	-- Controls
	local controls = Instance.new("Frame")
	controls.Name = "Controls"
	controls.Size = UDim2.new(1, -30, 0, 30)
	controls.Position = UDim2.new(0, 15, 1, -40)
	controls.BackgroundTransparency = 1
	controls.Parent = dialogueBox
	
	local nextBtn = Instance.new("TextButton")
	nextBtn.Name = "NextBtn"
	nextBtn.Size = UDim2.new(0, 80, 0, 25)
	nextBtn.Position = UDim2.new(1, -80, 0, 0)
	nextBtn.BackgroundColor3 = Color3.fromRGB(0, 207, 255)
	nextBtn.Text = "Continuar"
	nextBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	nextBtn.TextSize = 12
	nextBtn.Font = Enum.Font.GothamBold
	nextBtn.Parent = controls
	
	local skipBtn = Instance.new("TextButton")
	skipBtn.Name = "SkipBtn"
	skipBtn.Size = UDim2.new(0, 60, 0, 25)
	skipBtn.Position = UDim2.new(1, -150, 0, 0)
	skipBtn.BackgroundColor3 = Color3.fromRGB(244, 63, 94)
	skipBtn.Text = "Saltar"
	skipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	skipBtn.TextSize = 12
	skipBtn.Font = Enum.Font.GothamBold
	skipBtn.Parent = controls
	
	-- CharacterArea
	local charArea = Instance.new("Frame")
	charArea.Name = "CharacterArea"
	charArea.Size = UDim2.new(0, 150, 0, 200)
	charArea.Position = UDim2.new(0.05, 0, 0.5, 0)
	charArea.BackgroundTransparency = 1
	charArea.Visible = false
	charArea.Parent = canvas
	
	local portraitFrame = Instance.new("Frame")
	portraitFrame.Name = "PortraitFrame"
	portraitFrame.Size = UDim2.new(1, 0, 1, 0)
	portraitFrame.BackgroundColor3 = Color3.fromRGB(17, 28, 46)
	portraitFrame.Parent = charArea
	
	local portraitImage = Instance.new("ImageLabel")
	portraitImage.Name = "PortraitImage"
	portraitImage.Size = UDim2.new(1, -10, 1, -10)
	portraitImage.Position = UDim2.new(0, 5, 0, 5)
	portraitImage.BackgroundTransparency = 1
	portraitImage.Image = ""
	portraitImage.Parent = portraitFrame
	
	-- ChoicesPanel
	local choicesPanel = Instance.new("Frame")
	choicesPanel.Name = "ChoicesPanel"
	choicesPanel.Size = UDim2.new(0.6, 0, 0.4, 0)
	choicesPanel.Position = UDim2.new(0.2, 0, 0.55, 0)
	choicesPanel.BackgroundColor3 = Color3.fromRGB(17, 28, 46)
	choicesPanel.Visible = false
	choicesPanel.Parent = canvas
	
	local questionArea = Instance.new("Frame")
	questionArea.Name = "QuestionArea"
	questionArea.Size = UDim2.new(1, -30, 0, 50)
	questionArea.Position = UDim2.new(0, 15, 0, 10)
	questionArea.BackgroundTransparency = 1
	questionArea.Parent = choicesPanel
	
	local questionText = Instance.new("TextLabel")
	questionText.Name = "QuestionText"
	questionText.Size = UDim2.new(1, 0, 1, 0)
	questionText.BackgroundTransparency = 1
	questionText.Text = ""
	questionText.TextColor3 = Color3.fromRGB(221, 233, 245)
	questionText.TextSize = 18
	questionText.Font = Enum.Font.GothamBold
	questionText.TextWrapped = true
	questionText.Parent = questionArea
	
	local choicesList = Instance.new("Frame")
	choicesList.Name = "ChoicesList"
	choicesList.Size = UDim2.new(1, -30, 0.7, 0)
	choicesList.Position = UDim2.new(0, 15, 0, 70)
	choicesList.BackgroundTransparency = 1
	choicesList.Parent = choicesPanel
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 8)
	listLayout.Parent = choicesList
	
	return screenGui
end

---Obtiene referencias a los elementos de la GUI
function DialogoGUISystem:ObtenerReferenciasGUI(screenGui)
	local gui = { screenGui = screenGui }
	
	local canvas = screenGui:FindFirstChild("Canvas") or screenGui
	
	-- CharacterArea
	gui.charArea = canvas:FindFirstChild("CharacterArea")
	if gui.charArea then
		local portraitFrame = gui.charArea:FindFirstChild("PortraitFrame")
		if portraitFrame then
			gui.portraitImage = portraitFrame:FindFirstChild("PortraitImage")
		end
		gui.charNameFrame = gui.charArea:FindFirstChild("CharNameFrame")
		if gui.charNameFrame then
			gui.charName = gui.charNameFrame:FindFirstChild("CharName")
		end
		gui.expressionLabel = gui.charArea:FindFirstChild("Expression")
	end
	
	-- DialogueBox
	gui.dialogueBox = canvas:FindFirstChild("DialogueBox")
	if gui.dialogueBox then
		local speakerTag = gui.dialogueBox:FindFirstChild("SpeakerTag")
		if speakerTag then
			gui.speakerName = speakerTag:FindFirstChild("SpeakerName")
			gui.eyeBtn = speakerTag:FindFirstChild("EyeBtn")
		end
		
		local textArea = gui.dialogueBox:FindFirstChild("TextArea")
		if textArea then
			gui.dialogueText = textArea:FindFirstChild("DialogueText")
		end
		
		local controls = gui.dialogueBox:FindFirstChild("Controls")
		if controls then
			gui.nextBtn = controls:FindFirstChild("NextBtn")
			gui.skipBtn = controls:FindFirstChild("SkipBtn")
			gui.progCount = controls:FindFirstChild("ProgressCount")
		end
	end
	
	-- ChoicesPanel
	gui.choicesPanel = canvas:FindFirstChild("ChoicesPanel")
	if gui.choicesPanel then
		local questionArea = gui.choicesPanel:FindFirstChild("QuestionArea")
		if questionArea then
			gui.questionText = questionArea:FindFirstChild("QuestionText")
		end
		gui.choicesList = gui.choicesPanel:FindFirstChild("ChoicesList")
	end
	
	return gui
end

-- ════════════════════════════════════════════════════════════════
-- API PÚBLICA
-- ════════════════════════════════════════════════════════════════

function DialogoGUISystem:Play(dialogueKey, metadata)
	if self.isPlaying then
		print("[DialogoGUISystem] ⚠ Ya hay un diálogo en reproducción")
		return false
	end
	
	local dialogueData = self:LoadDialogue(dialogueKey)
	if not dialogueData then
		print("[DialogoGUISystem] ✗ No se encontró diálogo: " .. tostring(dialogueKey))
		return false
	end
	
	self.isPlaying = true
	self.currentDialogue = dialogueData
	self.currentLineIndex = 1
	self.metadata = metadata or {}
	
	print("[DialogoGUISystem] ▶ Iniciando diálogo: " .. tostring(dialogueKey))
	
	self.gui.screenGui.Enabled = true
	self.controller:RenderLine(self.currentLineIndex)
	
	return true
end

function DialogoGUISystem:Next()
	if not self.isPlaying then return end
	
	self.currentLineIndex = self.currentLineIndex + 1
	
	if self.currentLineIndex > #self.currentDialogue.Lineas then
		self:Close()
		return
	end
	
	self.controller:RenderLine(self.currentLineIndex)
end

function DialogoGUISystem:Previous()
	if not self.isPlaying then return end
	
	if self.currentLineIndex > 1 then
		self.currentLineIndex = self.currentLineIndex - 1
		self.controller:RenderLine(self.currentLineIndex)
	end
end

function DialogoGUISystem:Skip()
	if not self.isPlaying then return end
	
	print("[DialogoGUISystem] Saltando diálogo...")
	
	-- Detener TTS si está reproduciendo
	if self.narrator then
		self.narrator:Stop()
	end
	
	-- Cerrar el diálogo inmediatamente
	self:Close()
end

function DialogoGUISystem:SelectChoice(optionIndex)
	if not self.isPlaying then return end
	
	local linea = self.currentDialogue.Lineas[self.currentLineIndex]
	if not linea.Opciones or not linea.Opciones[optionIndex] then return end
	
	local opcion = linea.Opciones[optionIndex]
	
	if opcion.OnSelect then
		opcion.OnSelect(self.gui, self.metadata)
	end
	
	if opcion.Siguiente and opcion.Siguiente ~= "FIN" then
		self:GoToLine(opcion.Siguiente)
	else
		self:Close()
	end
end

function DialogoGUISystem:GoToLine(lineId)
	if not self.isPlaying then return end
	
	for i, linea in ipairs(self.currentDialogue.Lineas) do
		if linea.Id == lineId then
			self.currentLineIndex = i
			self.controller:RenderLine(self.currentLineIndex)
			return true
		end
	end
	
	print("[DialogoGUISystem] ⚠ Línea no encontrada: " .. tostring(lineId))
	return false
end

function DialogoGUISystem:Pause()
	if self.narrator then
		self.narrator:Stop()
	end
end

function DialogoGUISystem:Resume()
	local linea = self.currentDialogue.Lineas[self.currentLineIndex]
	if linea and linea.Audio then
		self.narrator:Play(linea.Audio)
	end
end

function DialogoGUISystem:Close()
	if not self.isPlaying then return end
	
	self.isPlaying = false
	self.gui.screenGui.Enabled = false
	self.narrator:Stop()
	
	print("[DialogoGUISystem] ◼ Diálogo cerrado")
	
	if self.onClose then
		self.onClose()
	end
end

function DialogoGUISystem:OnClose(callback)
	self.onClose = callback
end

-- ════════════════════════════════════════════════════════════════
-- CARGA DE DIÁLOGOS
-- ════════════════════════════════════════════════════════════════

function DialogoGUISystem:LoadDialogue(key)
	local DialogoData = ReplicatedStorage:FindFirstChild("DialogoData")
	
	if not DialogoData then
		print("[DialogoGUISystem] ✗ Carpeta DialogoData no encontrada en ReplicatedStorage")
		return nil
	end
	
	print("[DialogoGUISystem] Buscando diálogo '" .. tostring(key) .. "' en DialogoData...")
	
	local modulosEncontrados = 0
	
	for _, module in pairs(DialogoData:GetChildren()) do
		if module:IsA("ModuleScript") then
			modulosEncontrados = modulosEncontrados + 1
			print("[DialogoGUISystem] Intentando cargar módulo:", module.Name)
			
			local exito, data = pcall(function()
				return require(module)
			end)
			
			if not exito then
				warn("[DialogoGUISystem] Error cargando módulo", module.Name .. ":", data)
			elseif type(data) ~= "table" then
				warn("[DialogoGUISystem] Módulo", module.Name, "no retorna una tabla, retorna:", type(data))
			else
				print("[DialogoGUISystem] Módulo", module.Name, "cargado. Buscando clave '" .. tostring(key) .. "'...")
				if data[key] then
					print("[DialogoGUISystem] ✓ Diálogo encontrado:", tostring(key))
					return data[key]
				else
					-- Mostrar qué diálogos están disponibles
					local disponibles = {}
					for k, _ in pairs(data) do
						table.insert(disponibles, k)
					end
					print("[DialogoGUISystem] Diálogos disponibles en", module.Name .. ":", table.concat(disponibles, ", "))
				end
			end
		end
	end
	
	print("[DialogoGUISystem] ✗ Diálogo no encontrado: " .. tostring(key) .. " (módulos revisados: " .. modulosEncontrados .. ")")
	return nil
end

-- ════════════════════════════════════════════════════════════════
-- UTILIDADES
-- ════════════════════════════════════════════════════════════════

function DialogoGUISystem:GetCurrentLine()
	return self.currentDialogue.Lineas[self.currentLineIndex]
end

function DialogoGUISystem:GetLineIndex()
	return self.currentLineIndex
end

function DialogoGUISystem:GetTotalLines()
	return #self.currentDialogue.Lineas
end

function DialogoGUISystem:IsPlaying()
	return self.isPlaying
end

-- ════════════════════════════════════════════════════════════════
-- INSTANCIA SINGLETON
-- ════════════════════════════════════════════════════════════════

local instance = nil
local initialized = false

function DialogoGUISystem.new()
	if not instance then
		instance = setmetatable({}, DialogoGUISystem)
	end
	return instance
end

function DialogoGUISystem:InitSafe()
	if initialized then return true end
	
	local exito, resultado = pcall(function()
		self:Init()
	end)
	
	if exito then
		initialized = true
		return true
	else
		warn("[DialogoGUISystem] Error en inicialización:", resultado)
		return false
	end
end

return DialogoGUISystem
