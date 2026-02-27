--[[
    ╔════════════════════════════════════════════════════════════════╗
    ║              DIALOGOEVENTS — EVENTOS Y BOTONES                 ║
    ║         Conecta interacciones de usuario a funcionalidad       ║
    ╚════════════════════════════════════════════════════════════════╝
]]

local DialogoEvents = {}
DialogoEvents.__index = DialogoEvents

function DialogoEvents.new(gui, controller)
    local self = setmetatable({}, DialogoEvents)
    self.gui = gui
    self.controller = controller
    self:ConnectButtons()
    return self
end

-- ════════════════════════════════════════════════════════════════
-- CONEXIÓN DE BOTONES
-- ════════════════════════════════════════════════════════════════

---Conecta todos los botones a sus funciones
function DialogoEvents:ConnectButtons()
    -- Botón CONTINUAR
    local nextBtn = self.gui.nextBtn
    if nextBtn then
        nextBtn.MouseButton1Click:Connect(function()
            self:OnNextClicked()
        end)
    end
    
    -- Botón SALTAR
    local skipBtn = self.gui.skipBtn
    if skipBtn then
        skipBtn.MouseButton1Click:Connect(function()
            self:OnSkipClicked()
        end)
    end
    
    -- Botón OJO (mostrar/ocultar personaje)
    local eyeBtn = self.gui.dialogueBox:FindFirstChild("SpeakerTag")
        and self.gui.dialogueBox:FindFirstChild("SpeakerTag"):FindFirstChild("EyeBtn")
    if eyeBtn then
        eyeBtn.MouseButton1Click:Connect(function()
            self:OnEyeClicked()
        end)
    end
    
    -- Teclado
    local userInputService = game:GetService("UserInputService")
    userInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        self:OnKeyPressed(input.KeyCode)
    end)
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
        self.controller.system.renderer:CompleteText(
            self.gui.dialogueText,
            linea.Texto
        )
        return
    end
    
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
    self.gui.charArea.Visible = not self.gui.charArea.Visible
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
    self.gui.nextBtn.Active = enabled
    self.gui.skipBtn.Active = enabled
end

---Cambia el texto del botón CONTINUAR
function DialogoEvents:SetNextButtonText(text)
    self.gui.nextBtn.Text = text
end

---Cambia el texto del botón SALTAR
function DialogoEvents:SetSkipButtonText(text)
    self.gui.skipBtn.Text = text
end

return DialogoEvents
