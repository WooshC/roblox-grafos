-- StarterPlayerScripts/Dialogo/DialogoTTS.lua
-- Sistema de Texto a Voz (TTS) para diálogos
-- Usa la API oficial AudioTextToSpeech de Roblox

--[[
    ╔════════════════════════════════════════════════════════════════╗
    ║              DIALOGOTTS — TEXTO A VOZ                          ║
    ║      Usa AudioTextToSpeech API de Roblox (2025+)               ║
    ║      Soporta: Inglés, Español, Italiano, Alemán, Francés       ║
    ╚════════════════════════════════════════════════════════════════╝
    
    DOCUMENTACIÓN:
    - https://create.roblox.com/docs/reference/engine/classes/AudioTextToSpeech
    
    VOCES DISPONIBLES (VoiceId):
    - "0" = Default/David (Inglés masculino)
    - "1" = English Female
    - "2" = Spanish Male     
    - "3" = Spanish Female
    - "4" = Italian Male
    - "5" = Italian Female
    - "6" = German Male
    - "7" = German Female
    - "8" = French Male
    - "9" = French Female
]]

local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local DialogoTTS = {}
DialogoTTS.__index = DialogoTTS

-- Mapeo de personajes a voces
local VOCES_POR_PERSONAJE = {
	["Carlos"] = {
		voiceId = "101",         -- Spanish Male (Español Masculino)
		volumen = 0.6,
		velocidad = 1.0
	},
	["Sistema"] = {
		voiceId = "0",           -- Default/David (English)
		volumen = 0.4,
		velocidad = 1.1
	},
	["Narrador"] = {
		voiceId = "101",         -- Spanish Male (Español Masculino)
		volumen = 0.7,
		velocidad = 0.9
	},
	["Maria"] = {
		voiceId = "102",         -- Spanish Female (Español Femenino)
		volumen = 0.6,
		velocidad = 1.0
	},
	["Default"] = {
		voiceId = "101",         -- Spanish Male (default para español)
		volumen = 0.5,
		velocidad = 1.0
	}
}

-- Idiomas soportados
local IDIOMAS = {
	ESPANOL = "es",
	INGLES = "en",
	ITALIANO = "it",
	ALEMAN = "de",
	FRANCES = "fr"
}

function DialogoTTS.new()
	local self = setmetatable({}, DialogoTTS)
	self.audioTTS = nil
	self.deviceOutput = nil
	self.wire = nil
	self.habilitado = true
	self.volumenGlobal = 1.0
	self.idioma = IDIOMAS.ESPANOL  -- Default español
	
	-- Verificar si AudioTextToSpeech está disponible
	self.ttsDisponible = pcall(function()
		local test = Instance.new("AudioTextToSpeech")
		test:Destroy()
	end)
	
	if self.ttsDisponible then
		print("[DialogoTTS] ✓ AudioTextToSpeech API disponible")
		self:InicializarAudio()
	else
		warn("[DialogoTTS] ✗ AudioTextToSpeech no disponible en esta versión de Roblox")
	end
	
	return self
end

-- ════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN DEL SISTEMA DE AUDIO
-- ════════════════════════════════════════════════════════════════

---Inicializa el sistema de audio TTS
function DialogoTTS:InicializarAudio()
	if not self.ttsDisponible then return end
	
	-- Crear instancia AudioTextToSpeech
	self.audioTTS = Instance.new("AudioTextToSpeech")
	self.audioTTS.Name = "DialogoTTS_Audio"
	
	-- Crear dispositivo de salida
	self.deviceOutput = Instance.new("AudioDeviceOutput")
	self.deviceOutput.Name = "DialogoTTS_Output"
	
	-- Crear wire para conectar
	self.wire = Instance.new("Wire")
	self.wire.Name = "DialogoTTS_Wire"
	
	-- Conectar: AudioTextToSpeech -> Wire -> AudioDeviceOutput
	self.wire.SourceInstance = self.audioTTS
	self.wire.TargetInstance = self.deviceOutput
	
	-- Parent a SoundService para que sea global
	self.audioTTS.Parent = SoundService
	self.deviceOutput.Parent = SoundService
	self.wire.Parent = SoundService
	
	print("[DialogoTTS] Sistema de audio inicializado")
end

-- ════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ════════════════════════════════════════════════════════════════

---Habilita o deshabilita el TTS
function DialogoTTS:SetHabilitado(habilitado)
	self.habilitado = habilitado
end

---Establece el volumen global (0-1)
function DialogoTTS:SetVolumen(volumen)
	self.volumenGlobal = math.clamp(volumen, 0, 1)
	if self.deviceOutput then
		self.deviceOutput.Volume = self.volumenGlobal
	end
end

---Registra una voz personalizada para un personaje
function DialogoTTS:RegistrarVoz(personaje, config)
	VOCES_POR_PERSONAJE[personaje] = {
		voiceId = config.voiceId or "2",
		volumen = config.volumen or 0.5,
		velocidad = config.velocidad or 1.0
	}
end

---Cambia el idioma del TTS
function DialogoTTS:SetIdioma(idioma)
	self.idioma = idioma
	
	-- Actualizar voces default según idioma (VoiceIds oficiales de Roblox 2026)
	if idioma == IDIOMAS.ESPANOL then
		VOCES_POR_PERSONAJE["Default"].voiceId = "101"  -- Spanish Male
	elseif idioma == IDIOMAS.INGLES then
		VOCES_POR_PERSONAJE["Default"].voiceId = "0"    -- English Male (David)
	elseif idioma == IDIOMAS.ITALIANO then
		VOCES_POR_PERSONAJE["Default"].voiceId = "301"  -- Italian Male
	elseif idioma == IDIOMAS.ALEMAN then
		VOCES_POR_PERSONAJE["Default"].voiceId = "201"  -- German Male
	elseif idioma == IDIOMAS.FRANCES then
		VOCES_POR_PERSONAJE["Default"].voiceId = "401"  -- French Male
	end
end

-- ════════════════════════════════════════════════════════════════
-- REPRODUCCIÓN TTS
-- ════════════════════════════════════════════════════════════════

---Habla un texto usando TTS
function DialogoTTS:Hablar(texto, personaje)
	if not self.habilitado then 
		print("[DialogoTTS] TTS deshabilitado")
		return false 
	end
	if not self.ttsDisponible or not self.audioTTS then 
		print("[DialogoTTS] TTS no disponible, usando fallback")
		self:ReproducirSonidoFallback(personaje)
		return false 
	end
	if not texto or texto == "" then 
		print("[DialogoTTS] Texto vacío")
		return false 
	end
	
	-- Preparar texto (limitar longitud y limpiar)
	local textoPreparado = self:PrepararTexto(texto)
	if textoPreparado == "" then 
		print("[DialogoTTS] Texto preparado vacío")
		return false 
	end
	
	-- Obtener configuración de voz
	local config = VOCES_POR_PERSONAJE[personaje] or VOCES_POR_PERSONAJE["Default"]
	
	print("[DialogoTTS] Hablando:", textoPreparado:sub(1, 30) .. "...", "Voz:", config.voiceId, "Personaje:", personaje)
	
	-- Detener reproducción anterior
	self:Detener()
	
	-- Configurar el AudioTextToSpeech
	self.audioTTS.Text = textoPreparado
	self.audioTTS.VoiceId = config.voiceId
	self.audioTTS.PlaybackSpeed = config.velocidad
	
	-- Configurar volumen usando AudioFader o similar si es necesario
	-- Nota: AudioDeviceOutput no tiene propiedad Volume directa
	-- El volumen se controla a través del AudioTextToSpeech o del sistema de audio
	
	-- Reproducir
	print("[DialogoTTS] Intentando reproducir con VoiceId:", config.voiceId)
	
	local exito, err = pcall(function()
		self.audioTTS:Play()
	end)
	
	if exito then
		print("[DialogoTTS] ✓ Reproducción iniciada exitosamente")
		return true
	else
		warn("[DialogoTTS] ✗ Error al reproducir:", err)
		return false
	end
end

---Prepara el texto para TTS
function DialogoTTS:PrepararTexto(texto)
	if not texto then return "" end
	
	-- Limite de caracteres de la API de Roblox (recomendado)
	local maxChars = 500
	if #texto > maxChars then
		texto = texto:sub(1, maxChars - 3) .. "..."
	end
	
	-- Limpiar caracteres que pueden causar problemas
	texto = texto:gsub("[\n\r]", " ")  -- Quitar saltos de línea
	texto = texto:gsub("%s+", " ")      -- Normalizar espacios
	texto = texto:gsub("\"", "'")        -- Cambiar comillas dobles a simples
	
	return texto
end

---Detiene la reproducción TTS
function DialogoTTS:Detener()
	if self.audioTTS then
		local exito, err = pcall(function()
			self.audioTTS:Stop()
		end)
	end
end

---Pausa el TTS
function DialogoTTS:Pausar()
	if self.audioTTS then
		local exito, err = pcall(function()
			-- AudioTextToSpeech no tiene Pause nativo, usamos Stop
			self.audioTTS:Stop()
		end)
	end
end

-- ════════════════════════════════════════════════════════════════
-- EVENTOS
-- ════════════════════════════════════════════════════════════════

---Conecta un callback para cuando termina el TTS
function DialogoTTS:OnTerminar(callback)
	if not self.audioTTS then return end
	
	return self.audioTTS.Ended:Connect(function()
		callback()
	end)
end

-- ════════════════════════════════════════════════════════════════
-- FALLBACK (cuando TTS no está disponible)
-- ════════════════════════════════════════════════════════════════

---Reproduce un sonido de fallback cuando TTS no está disponible
function DialogoTTS:ReproducirSonidoFallback(personaje)
	local config = VOCES_POR_PERSONAJE[personaje] or VOCES_POR_PERSONAJE["Default"]
	
	-- Crear sonido simple de notificación
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://9119732940"  -- Click suave
	sound.Volume = 0.3 * self.volumenGlobal
	sound.PlaybackSpeed = 1 + (math.random() - 0.5) * 0.2
	sound.Parent = SoundService
	
	sound:Play()
	
	game:GetService("Debris"):AddItem(sound, 2)
end

---Reproduce un sonido de inicio de diálogo
function DialogoTTS:SonidoInicio(personaje)
	local config = VOCES_POR_PERSONAJE[personaje] or VOCES_POR_PERSONAJE["Default"]
	
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://6895079853"  -- Sonido UI simple
	sound.Volume = 0.2 * self.volumenGlobal
	sound.PlaybackSpeed = config.velocidad or 1.0
	sound.Parent = SoundService
	
	sound:Play()
	
	game:GetService("Debris"):AddItem(sound, 2)
end

---Reproduce sonidos de "habla" mientras aparece el texto
-- Útil para dar feedback visual de que alguien está hablando
function DialogoTTS:ReproducirSonidoHabla(personaje, numPalabras)
	if self.ttsDisponible and self.audioTTS then
		-- Si TTS está disponible, no necesitamos sonidos de habla
		-- porque el AudioTextToSpeech ya reproduce la voz
		return
	end
	
	-- Fallback: reproducir sonidos de habla simulada
	local config = VOCES_POR_PERSONAJE[personaje] or VOCES_POR_PERSONAJE["Default"]
	local numSonidos = math.min(math.max(math.floor((numPalabras or 10) / 3), 1), 5)
	
	task.spawn(function()
		for i = 1, numSonidos do
			local sound = Instance.new("Sound")
			sound.SoundId = "rbxassetid://9119732940"
			sound.Volume = 0.2 * self.volumenGlobal
			sound.PlaybackSpeed = (config.velocidad or 1.0) + (math.random() - 0.5) * 0.1
			sound.Parent = SoundService
			
			sound:Play()
			game:GetService("Debris"):AddItem(sound, 1)
			
			task.wait(0.15 + math.random() * 0.1)
		end
	end)
end

-- ════════════════════════════════════════════════════════════════
-- CONSTANTES PÚBLICAS
-- ════════════════════════════════════════════════════════════════

DialogoTTS.IDIOMAS = IDIOMAS

DialogoTTS.VOCES = {
	-- Inglés
	DAVID = "0",           -- English Male (Default)
	ENGLISH_FEMALE = "1",
	
	-- Español (Nuevas voces 2026)
	SPANISH_MALE = "101",    -- ✅ Español Masculino
	SPANISH_FEMALE = "102",  -- ✅ Español Femenino
	
	-- Alemán
	GERMAN_MALE = "201",
	GERMAN_FEMALE = "202",
	
	-- Italiano
	ITALIAN_MALE = "301",
	ITALIAN_FEMALE = "302",
	
	-- Francés
	FRENCH_MALE = "401",
	FRENCH_FEMALE = "402"
}

return DialogoTTS
