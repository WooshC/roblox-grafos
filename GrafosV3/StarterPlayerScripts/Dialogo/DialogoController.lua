-- StarterPlayerScripts/Dialogo/DialogoController.lua
-- Controlador de lógica de diálogos

--[[
    ╔════════════════════════════════════════════════════════════════╗
    ║              DIALOGOCONTROLLER — CONTROLADOR DE LOGICA         ║
    ║           Gestiona flujo, condiciones y eventos de líneas      ║
    ╚════════════════════════════════════════════════════════════════╝
]]

-- Cargar módulo de expresiones
local DialogoExpressions = require(script.Parent:FindFirstChild("DialogoExpressions"))

local DialogoController = {}
DialogoController.__index = DialogoController

function DialogoController.new(gui, system)
	local self = setmetatable({}, DialogoController)
	self.gui = gui
	self.system = system
	-- Rastreo de botones destacados activos: { {nombre, alTerminar, textoAyuda} }
	self._botonesDestacados = {}
	return self
end

---Devuelve MensajeLabel dentro de DialogoGUI (búsqueda lazy, sin caché para evitar refs stale)
function DialogoController:_getMensajeLabel()
	local playerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
	if not playerGui then return nil end
	return playerGui:FindFirstChild("MensajeLabel", true)
end

---Escribe texto en MensajeFrame.MensajeLabel y muestra el frame
function DialogoController:_setMensaje(texto)
	local label = self:_getMensajeLabel()
	if not label then return end
	label.Text        = texto
	label.TextScaled  = true
	label.TextWrapped = true
	if label.Parent then label.Parent.Visible = true end
end

---Limpia MensajeLabel y oculta el frame
function DialogoController:_clearMensaje()
	local label = self:_getMensajeLabel()
	if not label then return end
	label.Text = ""
	if label.Parent then label.Parent.Visible = false end
end

-- ════════════════════════════════════════════════════════════════
-- RENDERIZACIÓN DE LÍNEAS
-- ════════════════════════════════════════════════════════════════

---Renderiza una línea del diálogo
function DialogoController:RenderLine(lineIndex)
	local linea = self.system.currentDialogue.Lineas[lineIndex]
	if not linea then return end

	-- Verificar condición
	if linea.Condicion then
		if not linea.Condicion(self.system.metadata) then
			-- Saltar a siguiente línea automáticamente
			self.system:Next()
			return
		end
	end

	-- Restaurar botones de la línea anterior marcados como "restaurar"
	local highlighter = self.system.metadata and self.system.metadata.buttonHighlighter
	if highlighter then
		local mantener = {}
		for _, info in ipairs(self._botonesDestacados) do
			if info.alTerminar == "restaurar" then
				highlighter:restaurarBoton(info.nombre)
				if info.textoAyuda then self:_clearMensaje() end
			else
				table.insert(mantener, info)
			end
		end
		self._botonesDestacados = mantener
	end

	-- Limpiar efectos anteriores
	self:ClearEffects()

	-- Actualizar información del hablante
	self:UpdateSpeaker(linea)

	-- Mostrar imagen y expresión
	self:UpdateCharacter(linea)

	-- Ejecutar evento de la línea
	if linea.Evento then
		local exito, err = pcall(function()
			linea.Evento(self.gui, self.system.metadata)
		end)
		if not exito then
			warn("[DialogoController] Error en Evento de línea:", err)
		end
	end

	-- Iniciar audio ANTES del texto para que el narrador arranque primero
	if linea.Audio and linea.Audio ~= "" and linea.Audio ~= "rbxassetid://0" then
		print("[DialogoController] Reproduciendo audio personalizado:", linea.Audio)
		self.system.narrator:Play(linea.Audio)
	elseif linea.Texto and linea.Texto ~= "" then
		print("[DialogoController] Usando TTS para:", linea.Actor)
		self.system.narrator:Speak(linea.Texto, linea.Actor)
	end

	-- Esperar a que el pipeline TTS se active antes del typewriter
	-- Configurable por diálogo en Metadata.DelayTTS (default 0.1s)
	local delayTTS = (self.system.currentDialogue.Metadata or {}).DelayTTS or 0.1
	task.wait(delayTTS)

	-- Mostrar texto
	self:UpdateText(linea)

	-- Mostrar opciones o botones normales
	if linea.Opciones and #linea.Opciones > 0 then
		self:ShowChoices(linea.Opciones)
	else
		self:ShowNormalControls()
	end

	-- Actualizar progreso
	self:UpdateProgress(lineIndex)

	-- Destacar botón del HUD si la línea lo especifica
	if linea.DestacarBoton and highlighter then
		local config = linea.DestacarBoton
		local nombre
		if type(config) == "string" then
			nombre = config
			config = {}
		else
			nombre = config.nombre
		end
		if nombre then
			highlighter:destacarBoton(nombre, config)
			local textoAyuda = type(config) == "table" and config.textoAyuda or nil
			if textoAyuda and textoAyuda ~= "" then
				self:_setMensaje(textoAyuda)
			end
			table.insert(self._botonesDestacados, {
				nombre     = nombre,
				alTerminar = (type(linea.DestacarBoton) == "table" and linea.DestacarBoton.alTerminar) or "restaurar",
				textoAyuda = textoAyuda,
			})
		end
	end
end

-- ════════════════════════════════════════════════════════════════
-- ACTUALIZACIÓN DE ELEMENTOS
-- ════════════════════════════════════════════════════════════════

---Actualiza el nombre del hablante
function DialogoController:UpdateSpeaker(linea)
	if not self.gui.speakerName then return end

	self.gui.speakerName.Text = linea.Actor or "Sistema"
end

---Actualiza imagen y expresión del personaje
-- La expresión determina la imagen del personaje automáticamente
function DialogoController:UpdateCharacter(linea)
	local actor = linea.Actor or "Default"
	local expresion = linea.Expresion or "Normal"
	local imagenFinal = nil

	-- Prioridad 1: Si hay ImagenPersonaje explícita, usarla
	if linea.ImagenPersonaje and linea.ImagenPersonaje ~= "" and linea.ImagenPersonaje ~= "rbxassetid://0" then
		imagenFinal = linea.ImagenPersonaje
	elseif DialogoExpressions then
		-- Prioridad 2: Buscar la expresión en el catálogo
		imagenFinal = DialogoExpressions.GetExpression(actor, expresion)
	end

	-- Mostrar/ocultar área de personaje con la imagen correcta
	if self.gui.charArea and self.gui.portraitImage then
		if imagenFinal then
			self.gui.charArea.Visible = true
			self.gui.portraitImage.Image = imagenFinal
			print("[DialogoController] Mostrando", actor, "con expresión:", expresion)
		else
			self.gui.charArea.Visible = false
			warn("[DialogoController] No se encontró imagen para:", actor, "-", expresion)
		end
	end

	-- Nombre del personaje
	if linea.Actor and self.gui.charName then
		self.gui.charName.Text = linea.Actor
	end

	-- Expresión (como texto)
	if self.gui.expressionLabel then
		if linea.Expresion then
			self.gui.expressionLabel.Text = linea.Expresion
			self.gui.expressionLabel.Visible = true
		else
			self.gui.expressionLabel.Visible = false
		end
	end
end

---Actualiza el texto del diálogo
function DialogoController:UpdateText(linea)
	local velocidad = (self.system.currentDialogue.Metadata or {}).VelocidadTypewriter or 0.03

	if self.gui.dialogueText then
		self.system.renderer:RenderText(
			linea.Texto or "",
			self.gui.dialogueText,
			velocidad
		)
	end
end

---Actualiza el indicador de progreso
function DialogoController:UpdateProgress(lineIndex)
	if not self.gui.progCount then return end

	local total = self.system:GetTotalLines()
	self.gui.progCount.Text = lineIndex .. " / " .. total
end

-- ════════════════════════════════════════════════════════════════
-- OPCIONES Y CONTROLES
-- ════════════════════════════════════════════════════════════════

---Muestra el panel de opciones
function DialogoController:ShowChoices(opciones)
	if not self.gui.dialogueBox or not self.gui.choicesPanel then return end

	-- Ocultar diálogo normal, mostrar panel de elecciones
	self.gui.dialogueBox.Visible = false
	self.gui.choicesPanel.Visible = true

	local linea = self.system:GetCurrentLine()

	-- Propagar nombre del actor al SpeakerTag del ChoicesPanel
	if linea and self.gui.choicesSpeakerName then
		self.gui.choicesSpeakerName.Text = linea.Actor or "Sistema"
	end

	-- Actualizar pregunta
	if linea and linea.Texto and self.gui.questionText then
		self.gui.questionText.Text = linea.Texto
	end

	-- Limpiar opciones anteriores
	if self.gui.choicesList then
		for _, child in pairs(self.gui.choicesList:GetChildren()) do
			if child:IsA("Frame") or child:IsA("TextButton") then
				if child.Name:match("^Choice_") then
					child:Destroy()
				end
			end
		end

		-- Crear botones de opciones
		for i, opcion in ipairs(opciones) do
			self:CreateChoiceButton(i, opcion)
		end
	end
end

---Muestra controles normales (SALTAR, CONTINUAR)
function DialogoController:ShowNormalControls()
	if self.gui.dialogueBox then
		self.gui.dialogueBox.Visible = true
	end
	if self.gui.choicesPanel then
		self.gui.choicesPanel.Visible = false
	end
end

---Crea un botón de opción dinámicamente
function DialogoController:CreateChoiceButton(index, opcion)
	if not self.gui.choicesList then return end

	local choiceBtn = Instance.new("Frame")
	choiceBtn.Name = "Choice_" .. index
	choiceBtn.Size = UDim2.new(1, -8, 0, 40)
	choiceBtn.BackgroundColor3 = Color3.fromRGB(17, 28, 46)
	choiceBtn.BorderSizePixel = 1
	choiceBtn.BorderColor3 = opcion.Color or Color3.fromRGB(0, 207, 255)
	choiceBtn.Parent = self.gui.choicesList

	-- UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = choiceBtn

	-- Índice
	local indexLabel = Instance.new("TextLabel")
	indexLabel.Name = "Index"
	indexLabel.Text = tostring(index)
	indexLabel.Size = UDim2.new(0, 20, 0, 14)
	indexLabel.Position = UDim2.new(0, 8, 0.5, -7)
	indexLabel.BackgroundTransparency = 1
	indexLabel.TextColor3 = opcion.Color or Color3.fromRGB(0, 207, 255)
	indexLabel.TextSize = 10
	indexLabel.Font = Enum.Font.GothamBold
	indexLabel.Parent = choiceBtn

	-- Texto
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Text"
	textLabel.Text = opcion.Texto or "Opción"
	textLabel.Size = UDim2.new(0.6, -40, 0, 14)
	textLabel.Position = UDim2.new(0, 38, 0.5, -7)
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = Color3.fromRGB(221, 233, 245)
	textLabel.TextSize = 12
	textLabel.Font = Enum.Font.Gotham
	textLabel.TextWrapped = true
	textLabel.Parent = choiceBtn

	-- Pista
	if opcion.Pista then
		local hintLabel = Instance.new("TextLabel")
		hintLabel.Name = "Hint"
		hintLabel.Text = opcion.Pista
		hintLabel.Size = UDim2.new(0, 70, 0, 14)
		hintLabel.Position = UDim2.new(1, -88, 0.5, -7)
		hintLabel.BackgroundTransparency = 1
		hintLabel.TextColor3 = Color3.fromRGB(90, 122, 158)
		hintLabel.TextSize = 8
		hintLabel.Font = Enum.Font.Gotham
		hintLabel.Parent = choiceBtn
	end

	-- Flecha
	local arrowLabel = Instance.new("TextLabel")
	arrowLabel.Name = "Arrow"
	arrowLabel.Text = ">"
	arrowLabel.Size = UDim2.new(0, 12, 0, 14)
	arrowLabel.Position = UDim2.new(1, -16, 0.5, -7)
	arrowLabel.BackgroundTransparency = 1
	arrowLabel.TextColor3 = opcion.Color or Color3.fromRGB(0, 207, 255)
	arrowLabel.TextSize = 12
	arrowLabel.Font = Enum.Font.Gotham
	arrowLabel.Parent = choiceBtn

	-- Botón interactivo
	local button = Instance.new("TextButton")
	button.Name = "SelectBtn"
	button.Size = UDim2.new(1, 0, 1, 0)
	button.BackgroundTransparency = 1
	button.TextTransparency = 1
	button.Parent = choiceBtn

	local sistema = self.system
	button.MouseButton1Click:Connect(function()
		sistema:SelectChoice(index)
	end)

	-- Efecto hover
	button.MouseEnter:Connect(function()
		choiceBtn.BackgroundColor3 = Color3.fromRGB(25, 40, 60)
	end)

	button.MouseLeave:Connect(function()
		choiceBtn.BackgroundColor3 = Color3.fromRGB(17, 28, 46)
	end)
end

-- ════════════════════════════════════════════════════════════════
-- LIMPIEZA Y UTILIDADES
-- ════════════════════════════════════════════════════════════════

---Limpia efectos visuales previos
function DialogoController:ClearEffects()
	if self.gui.charArea then
		self.gui.charArea.Visible = true
	end
	if self.gui.expressionLabel then
		self.gui.expressionLabel.Visible = false
	end
	if self.gui.dialogueBox then
		self.gui.dialogueBox.Visible = true
	end
	if self.gui.choicesPanel then
		self.gui.choicesPanel.Visible = false
	end
end

return DialogoController
