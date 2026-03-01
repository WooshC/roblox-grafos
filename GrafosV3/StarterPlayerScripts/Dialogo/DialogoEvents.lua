-- StarterPlayerScripts/Dialogo/DialogoEvents.lua
-- Eventos y controles de entrada del sistema de diálogos

--[[
    ╔════════════════════════════════════════════════════════════════╗
    ║              DIALOGOEVENTS — EVENTOS Y BOTONES                 ║
    ║         Conecta interacciones de usuario a funcionalidad       ║
    ╚════════════════════════════════════════════════════════════════╝
]]

local UserInputService = game:GetService("UserInputService")

local DialogoEvents = {}
DialogoEvents.__index = DialogoEvents

function DialogoEvents.new(gui, controller)
	local self = setmetatable({}, DialogoEvents)
	self.gui = gui
	self.controller = controller
	self.connections = {}
	
	self:ConnectButtons()
	
	return self
end

-- ════════════════════════════════════════════════════════════════
-- CONEXIÓN DE BOTONES
-- ════════════════════════════════════════════════════════════════

---Conecta todos los botones a sus funciones
function DialogoEvents:ConnectButtons()
	-- Limpiar conexiones anteriores
	self:DisconnectAll()
	
	-- Botón CONTINUAR
	if self.gui.nextBtn then
		local conn = self.gui.nextBtn.MouseButton1Click:Connect(function()
			self:OnNextClicked()
		end)
		table.insert(self.connections, conn)
	end
	
	-- Botón SALTAR
	if self.gui.skipBtn then
		local conn = self.gui.skipBtn.MouseButton1Click:Connect(function()
			self:OnSkipClicked()
		end)
		table.insert(self.connections, conn)
	end
	
	-- Botón OJO (mostrar/ocultar personaje)
	if self.gui.eyeBtn then
		local conn = self.gui.eyeBtn.MouseButton1Click:Connect(function()
			self:OnEyeClicked()
		end)
		table.insert(self.connections, conn)
	end
	
	-- Teclado
	local conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		self:OnKeyPressed(input.KeyCode)
	end)
	table.insert(self.connections, conn)
end

---Desconecta todas las conexiones
function DialogoEvents:DisconnectAll()
	for _, conn in ipairs(self.connections) do
		if conn then
			conn:Disconnect()
		end
	end
	self.connections = {}
end

-- ════════════════════════════════════════════════════════════════
-- CALLBACKS DE BOTONES
-- ════════════════════════════════════════════════════════════════

---Se ejecuta cuando se presiona CONTINUAR
function DialogoEvents:OnNextClicked()
	if not self.controller.system.isPlaying then return end

	-- Si está escribiendo, completar el texto
	if self.controller.system.renderer:IsTyping() then
		local linea = self.controller.system:GetCurrentLine()
		if linea and self.gui.dialogueText then
			self.controller.system.renderer:CompleteText(
				self.gui.dialogueText,
				linea.Texto
			)
		end
		return
	end

	-- Destruir y recrear pipeline de audio para eliminar cualquier estado acumulado
	local narrator = self.controller.system.narrator
	if narrator then narrator:Reiniciar() end

	-- Avanzar a siguiente línea
	self.controller.system:Next()
end

---Se ejecuta cuando se presiona SALTAR
function DialogoEvents:OnSkipClicked()
	if not self.controller.system.isPlaying then return end
	
	self.controller.system:Skip()
end

---Se ejecuta cuando se presiona el botón OJO
function DialogoEvents:OnEyeClicked()
	if not self.controller.system.isPlaying then return end
	
	-- Ocultar/mostrar personaje
	if self.gui.charArea then
		self.gui.charArea.Visible = not self.gui.charArea.Visible
	end
end

-- ════════════════════════════════════════════════════════════════
-- CALLBACKS DE TECLADO
-- ════════════════════════════════════════════════════════════════

---Se ejecuta cuando se presiona una tecla
function DialogoEvents:OnKeyPressed(keyCode)
	if not self.controller.system.isPlaying then return end
	
	-- ESPACIO o ENTER = CONTINUAR
	if keyCode == Enum.KeyCode.Space or keyCode == Enum.KeyCode.Return then
		self:OnNextClicked()
	end
	
	-- ESC = SALTAR
	if keyCode == Enum.KeyCode.Escape then
		self:OnSkipClicked()
	end
	
	-- H = OJO
	if keyCode == Enum.KeyCode.H then
		self:OnEyeClicked()
	end
	
	-- FLECHAS (navegación opcional)
	if keyCode == Enum.KeyCode.Right then
		self.controller.system:Next()
	end
	
	if keyCode == Enum.KeyCode.Left then
		self.controller.system:Previous()
	end
end

-- ════════════════════════════════════════════════════════════════
-- EFECTOS DE BOTONES
-- ════════════════════════════════════════════════════════════════

---Resalta un botón al pasar el mouse
function DialogoEvents:HighlightButton(button)
	if not button then return end
	
	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = Color3.fromRGB(25, 40, 60)
		button.BackgroundTransparency = 0.2
	end)
	
	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = Color3.fromRGB(17, 28, 46)
		button.BackgroundTransparency = 0
	end)
end

-- ════════════════════════════════════════════════════════════════
-- EVENTOS PERSONALIZADOS
-- ════════════════════════════════════════════════════════════════

---Habilita/deshabilita los botones
function DialogoEvents:SetButtonsEnabled(enabled)
	if self.gui.nextBtn then
		self.gui.nextBtn.Active = enabled
	end
	if self.gui.skipBtn then
		self.gui.skipBtn.Active = enabled
	end
end

---Cambia el texto del botón CONTINUAR
function DialogoEvents:SetNextButtonText(text)
	if self.gui.nextBtn then
		self.gui.nextBtn.Text = text
	end
end

---Cambia el texto del botón SALTAR
function DialogoEvents:SetSkipButtonText(text)
	if self.gui.skipBtn then
		self.gui.skipBtn.Text = text
	end
end

return DialogoEvents
