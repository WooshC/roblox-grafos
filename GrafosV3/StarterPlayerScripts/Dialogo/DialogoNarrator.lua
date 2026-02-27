-- StarterPlayerScripts/Dialogo/DialogoNarrator.lua
-- Sistema de audio y narración de diálogos

--[[
    ╔════════════════════════════════════════════════════════════════╗
    ║              DIALOGONARRATOR — SISTEMA DE AUDIO                ║
    ║           Gestiona reproducción de audio y narración            ║
    ╚════════════════════════════════════════════════════════════════╝
    
    NOTA: Este sistema usa el ControladorAudio centralizado de GrafosV3
    si está disponible. Si no, usa SoundService como fallback.
]]

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DialogoNarrator = {}
DialogoNarrator.__index = DialogoNarrator

function DialogoNarrator.new()
	local self = setmetatable({}, DialogoNarrator)
	self.currentSound = nil
	self.soundVolume = 0.5
	self.soundParent = SoundService
	
	-- Intentar obtener el ControladorAudio centralizado
	self.controladorAudio = nil
	local StarterPlayerScripts = game:GetService("StarterPlayer").StarterPlayerScripts
	local moduloAudio = StarterPlayerScripts:FindFirstChild("Compartido") 
		and StarterPlayerScripts.Compartido:FindFirstChild("ControladorAudio")
	
	if moduloAudio then
		local exito, resultado = pcall(function()
			return require(moduloAudio)
		end)
		if exito then
			self.controladorAudio = resultado
			print("[DialogoNarrator] ControladorAudio integrado")
		end
	end
	
	-- El TTS se establecerá externamente si está disponible
	self.tts = nil
	
	return self
end

---Establece el módulo TTS externamente
function DialogoNarrator:SetTTS(ttsModule)
	if ttsModule then
		self.tts = ttsModule
		print("[DialogoNarrator] TTS establecido externamente")
	end
	
	return self
end

-- ════════════════════════════════════════════════════════════════
-- REPRODUCCIÓN DE AUDIO
-- ════════════════════════════════════════════════════════════════

---Reproduce un audio
function DialogoNarrator:Play(audioId)
	if not audioId or audioId == "" or audioId == "rbxassetid://0" then
		return
	end
	
	-- Detener audio anterior
	self:Stop()
	
	-- Usar ControladorAudio si está disponible
	if self.controladorAudio and typeof(audioId) == "string" and audioId:find("rbxassetid://") then
		-- Extraer el ID del sonido
		local id = audioId:gsub("rbxassetid://", "")
		-- Reproducir como SFX usando el sistema centralizado
		local exito = pcall(function()
			-- Por ahora usamos el sistema tradicional para diálogos
			-- ya que los diálogos pueden tener IDs de audio personalizados
		end)
	end
	
	-- Crear nuevo Sound (método tradicional)
	local sound = Instance.new("Sound")
	sound.SoundId = audioId
	sound.Volume = self.soundVolume
	sound.Parent = self.soundParent
	
	-- Reproducir
	sound:Play()
	
	self.currentSound = sound
	
	-- Limpiar cuando termine
	game:GetService("Debris"):AddItem(sound, sound.TimeLength + 1)
	
	return sound
end

---Habla un texto usando TTS (Texto a Voz)
function DialogoNarrator:Speak(texto, personaje)
	if not texto or texto == "" then return end
	
	-- Detener audio anterior
	self:Stop()
	
	-- Si hay TTS disponible, usarlo
	if self.tts then
		-- Calcular duración aproximada del texto (para efectos de sonido)
		local palabras = #texto:split(" ")
		
		-- Reproducir sonido de inicio de diálogo
		self.tts:SonidoInicio(personaje)
		
		-- Reproducir sonidos de "habla" mientras el texto aparece
		self.tts:ReproducirSonidoHabla(personaje, palabras)
		
		-- Intentar usar TTS real si está disponible
		local exito, resultado = pcall(function()
			return self.tts:Hablar(texto, personaje)
		end)
		
		if exito and resultado then
			self.currentSound = resultado
		end
	end
end

---Detiene la reproducción de audio
function DialogoNarrator:Stop()
	if self.currentSound then
		self.currentSound:Stop()
		self.currentSound = nil
	end
end

---Pausa el audio actual
function DialogoNarrator:Pause()
	if self.currentSound then
		self.currentSound:Pause()
	end
end

---Reanuda el audio pausado
function DialogoNarrator:Resume()
	if self.currentSound then
		self.currentSound:Resume()
	end
end

-- ════════════════════════════════════════════════════════════════
-- CONTROL DE VOLUMEN
-- ════════════════════════════════════════════════════════════════

---Establece el volumen del narrador
function DialogoNarrator:SetVolume(volume)
	self.soundVolume = math.clamp(volume, 0, 1)
	
	if self.currentSound then
		self.currentSound.Volume = self.soundVolume
	end
end

---Obtiene el volumen actual
function DialogoNarrator:GetVolume()
	return self.soundVolume
end

---Aumenta el volumen gradualmente
function DialogoNarrator:FadeInVolume(targetVolume, duration)
	duration = duration or 1
	targetVolume = math.clamp(targetVolume, 0, 1)
	
	if not self.currentSound then return end
	
	local startVolume = self.currentSound.Volume
	local startTime = tick()
	
	while tick() - startTime < duration and self.currentSound do
		local progress = (tick() - startTime) / duration
		self.currentSound.Volume = startVolume + (targetVolume - startVolume) * progress
		task.wait(0.016)
	end
	
	if self.currentSound then
		self.currentSound.Volume = targetVolume
	end
end

---Disminuye el volumen gradualmente
function DialogoNarrator:FadeOutVolume(duration)
	duration = duration or 1
	
	if not self.currentSound then return end
	
	local startVolume = self.currentSound.Volume
	local startTime = tick()
	
	while tick() - startTime < duration and self.currentSound do
		local progress = (tick() - startTime) / duration
		self.currentSound.Volume = startVolume * (1 - progress)
		task.wait(0.016)
	end
	
	if self.currentSound then
		self.currentSound.Volume = 0
		self.currentSound:Stop()
	end
end

-- ════════════════════════════════════════════════════════════════
-- INFORMACIÓN DE AUDIO
-- ════════════════════════════════════════════════════════════════

---Obtiene el tiempo actual del audio
function DialogoNarrator:GetTimePosition()
	if self.currentSound then
		return self.currentSound.TimePosition
	end
	return 0
end

---Obtiene la duración total del audio
function DialogoNarrator:GetDuration()
	if self.currentSound then
		return self.currentSound.TimeLength
	end
	return 0
end

---Verifica si está reproduciendo
function DialogoNarrator:IsPlaying()
	if not self.currentSound then return false end
	return self.currentSound.Playing
end

-- ════════════════════════════════════════════════════════════════
-- EFECTOS DE AUDIO (usando ControladorAudio si está disponible)
-- ════════════════════════════════════════════════════════════════

---Reproduce un sonido de confirmación
function DialogoNarrator:PlayConfirm()
	if self.controladorAudio and self.controladorAudio.playSFX then
		self.controladorAudio.playSFX("Success")
	else
		self:Play("rbxassetid://9113083740") -- Sonido de éxito por defecto
	end
end

---Reproduce un sonido de error
function DialogoNarrator:PlayError()
	if self.controladorAudio and self.controladorAudio.playSFX then
		self.controladorAudio.playSFX("Error")
	else
		self:Play("rbxassetid://9114488953") -- Sonido de error por defecto
	end
end

---Reproduce un sonido de transición
function DialogoNarrator:PlayTransition()
	if self.controladorAudio and self.controladorAudio.playSFX then
		self.controladorAudio.playUI("Click")
	else
		self:Play("rbxassetid://9119732940") -- Click por defecto
	end
end

-- ════════════════════════════════════════════════════════════════
-- EFECTOS DE VOZ
-- ════════════════════════════════════════════════════════════════

---Aplica pitch (tono) al audio
function DialogoNarrator:SetPitch(pitch)
	if self.currentSound then
		self.currentSound.PlaybackSpeed = pitch or 1
	end
end

---Obtiene el pitch actual
function DialogoNarrator:GetPitch()
	if self.currentSound then
		return self.currentSound.PlaybackSpeed
	end
	return 1
end

return DialogoNarrator
