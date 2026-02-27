-- StarterPlayerScripts/Dialogo/DialogoRenderer.lua
-- Efectos visuales y animaciones de diálogo

--[[
    ╔════════════════════════════════════════════════════════════════╗
    ║              DIALOGORENDERER — EFECTOS VISUALES                ║
    ║         Typewriter, transiciones, animaciones de texto         ║
    ╚════════════════════════════════════════════════════════════════╝
]]

local DialogoRenderer = {}
DialogoRenderer.__index = DialogoRenderer

function DialogoRenderer.new(gui)
	local self = setmetatable({}, DialogoRenderer)
	self.gui = gui
	self.isTyping = false
	self.typeThread = nil
	return self
end

-- ════════════════════════════════════════════════════════════════
-- TYPEWRITER EFFECT
-- ════════════════════════════════════════════════════════════════

---Renderiza texto con efecto typewriter
function DialogoRenderer:RenderText(text, textLabel, speed)
	if not textLabel then return end
	
	if self.isTyping and self.typeThread then
		task.cancel(self.typeThread)
	end
	
	self.isTyping = true
	textLabel.Text = ""
	
	local textoCompleto = text or ""
	
	self.typeThread = task.spawn(function()
		for i = 1, #textoCompleto do
			if not self.isTyping then break end
			
			textLabel.Text = textoCompleto:sub(1, i)
			task.wait(speed or 0.03)
		end
		self.isTyping = false
	end)
end

---Completa el texto instantáneamente
function DialogoRenderer:CompleteText(textLabel, text)
	if self.typeThread then
		task.cancel(self.typeThread)
	end
	self.isTyping = false
	if textLabel then
		textLabel.Text = text or ""
	end
end

---Verifica si se está escribiendo
function DialogoRenderer:IsTyping()
	return self.isTyping
end

-- ════════════════════════════════════════════════════════════════
-- TRANSICIONES
-- ════════════════════════════════════════════════════════════════

---Muestra elemento con fade in
function DialogoRenderer:FadeIn(element, duration)
	if not element then return end
	
	duration = duration or 0.3
	element.BackgroundTransparency = 1
	
	local startTime = tick()
	while tick() - startTime < duration do
		local progress = (tick() - startTime) / duration
		element.BackgroundTransparency = 1 - progress
		task.wait(0.016)
	end
	element.BackgroundTransparency = 0
end

---Oculta elemento con fade out
function DialogoRenderer:FadeOut(element, duration)
	if not element then return end
	
	duration = duration or 0.3
	element.BackgroundTransparency = 0
	
	local startTime = tick()
	while tick() - startTime < duration do
		local progress = (tick() - startTime) / duration
		element.BackgroundTransparency = progress
		task.wait(0.016)
	end
	element.BackgroundTransparency = 1
end

-- ════════════════════════════════════════════════════════════════
-- ANIMACIONES DE PERSONAJE
-- ════════════════════════════════════════════════════════════════

---Anima el retrato del personaje (aparición)
function DialogoRenderer:AnimatePortrait(duration)
	if not self.gui.portraitImage then return end
	
	duration = duration or 0.5
	local portrait = self.gui.portraitImage
	
	portrait.ImageTransparency = 1
	
	local startTime = tick()
	while tick() - startTime < duration do
		local progress = (tick() - startTime) / duration
		portrait.ImageTransparency = 1 - progress
		task.wait(0.016)
	end
	portrait.ImageTransparency = 0
end

---Hace parpadeo al personaje
function DialogoRenderer:BlinkPortrait(times)
	if not self.gui.portraitImage then return end
	
	times = times or 2
	local portrait = self.gui.portraitImage
	
	for i = 1, times do
		portrait.ImageTransparency = 0.5
		task.wait(0.1)
		portrait.ImageTransparency = 0
		task.wait(0.1)
	end
end

-- ════════════════════════════════════════════════════════════════
-- ANIMACIONES DE BOTONES
-- ════════════════════════════════════════════════════════════════

---Resalta un botón
function DialogoRenderer:HighlightButton(button, color)
	if not button then return end
	
	color = color or Color3.fromRGB(0, 207, 255)
	button.BorderColor3 = color
	button.BorderSizePixel = 2
end

---Restaura el estado normal de un botón
function DialogoRenderer:UnhighlightButton(button)
	if not button then return end
	
	button.BorderColor3 = Color3.fromRGB(26, 45, 71)
	button.BorderSizePixel = 1
end

-- ════════════════════════════════════════════════════════════════
-- PULSO Y EFECTOS
-- ════════════════════════════════════════════════════════════════

---Efecto de pulso en un elemento
function DialogoRenderer:Pulse(element, duration, intensity)
	if not element then return end
	
	duration = duration or 0.5
	intensity = intensity or 0.3
	
	local startTime = tick()
	local originalSize = element.Size
	
	while tick() - startTime < duration do
		local progress = (tick() - startTime) / duration
		local wave = math.sin(progress * math.pi) * intensity
		
		element.Size = originalSize * (1 + wave)
		task.wait(0.016)
	end
	
	element.Size = originalSize
end

---Efecto de temblor
function DialogoRenderer:Shake(element, duration, intensity)
	if not element then return end
	
	duration = duration or 0.3
	intensity = intensity or 5
	
	local originalPos = element.Position
	local startTime = tick()
	
	while tick() - startTime < duration do
		local offsetX = math.random(-intensity, intensity)
		local offsetY = math.random(-intensity, intensity)
		
		element.Position = originalPos + UDim2.new(0, offsetX, 0, offsetY)
		task.wait(0.016)
	end
	
	element.Position = originalPos
end

-- ════════════════════════════════════════════════════════════════
-- CAMBIO DE EXPRESIÓN
-- ════════════════════════════════════════════════════════════════

---Cambia la expresión con animación
function DialogoRenderer:AnimateExpression(newExpression, duration)
	if not self.gui.expressionLabel then return end
	
	duration = duration or 0.3
	local expression = self.gui.expressionLabel
	
	-- Fade out
	self:FadeOut(expression, duration / 2)
	
	-- Cambiar texto
	expression.Text = newExpression
	
	-- Fade in
	self:FadeIn(expression, duration / 2)
end

-- ════════════════════════════════════════════════════════════════
-- EFECTOS DE PANTALLA
-- ════════════════════════════════════════════════════════════════

---Destella la pantalla completa
function DialogoRenderer:ScreenFlash(duration, color)
	if not self.gui.screenGui then return end
	
	duration = duration or 0.2
	color = color or Color3.fromRGB(255, 255, 255)
	
	local flash = Instance.new("Frame")
	flash.Size = UDim2.new(1, 0, 1, 0)
	flash.BackgroundColor3 = color
	flash.BackgroundTransparency = 0
	flash.BorderSizePixel = 0
	flash.ZIndex = 100
	flash.Parent = self.gui.screenGui
	
	self:FadeOut(flash, duration)
	
	game:GetService("Debris"):AddItem(flash, duration)
end

return DialogoRenderer
