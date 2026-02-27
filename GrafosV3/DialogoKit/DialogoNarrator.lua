--[[
    ╔════════════════════════════════════════════════════════════════╗
    ║              DIALOGONARRATOR — SISTEMA DE AUDIO                ║
    ║           Gestiona reproducción de audio y narración            ║
    ╚════════════════════════════════════════════════════════════════╝
]]

local DialogoNarrator = {}
DialogoNarrator.__index = DialogoNarrator

function DialogoNarrator.new()
    local self = setmetatable({}, DialogoNarrator)
    self.currentSound = nil
    self.soundVolume = 0.5
    self.soundParent = game:GetService("SoundService")
    return self
end

-- ════════════════════════════════════════════════════════════════
-- REPRODUCCIÓN DE AUDIO
-- ════════════════════════════════════════════════════════════════

---Reproduce un audio
function DialogoNarrator:Play(audioId)
    if not audioId or audioId == "" then
        return
    end
    
    -- Detener audio anterior
    self:Stop()
    
    -- Crear nuevo Sound
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
-- EFECTOS DE AUDIO
-- ════════════════════════════════════════════════════════════════

---Reproduce un sonido de confirmación
function DialogoNarrator:PlayConfirm()
    self:Play("rbxassetid://9125513529")
end

---Reproduce un sonido de error
function DialogoNarrator:PlayError()
    self:Play("rbxassetid://9125525454")
end

---Reproduce un sonido de transición
function DialogoNarrator:PlayTransition()
    self:Play("rbxassetid://9125598964")
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
