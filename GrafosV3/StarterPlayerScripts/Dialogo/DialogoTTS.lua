-- StarterPlayerScripts/Dialogo/DialogoTTS.lua
-- Sistema de Texto a Voz (TTS) para diálogos
-- Usa la API oficial AudioTextToSpeech de Roblox

local SoundService = game:GetService("SoundService")
local Debris       = game:GetService("Debris")

local DialogoTTS = {}
DialogoTTS.__index = DialogoTTS

-- ════════════════════════════════════════════════════════════════
-- CATÁLOGO DE VOCES — fuente única de verdad para VoiceIds
-- ════════════════════════════════════════════════════════════════

local VOCES = {
	-- Inglés
	DAVID          = "0",
	ENGLISH_FEMALE = "1",
	-- Español
	SPANISH_MALE   = "101",
	SPANISH_FEMALE = "102",
	-- Alemán
	GERMAN_MALE    = "201",
	GERMAN_FEMALE  = "202",
	-- Italiano
	ITALIAN_MALE   = "301",
	ITALIAN_FEMALE = "302",
	-- Francés
	FRENCH_MALE    = "401",
	FRENCH_FEMALE  = "402",
}

local IDIOMAS = {
	ESPANOL  = "es",
	INGLES   = "en",
	ITALIANO = "it",
	ALEMAN   = "de",
	FRANCES  = "fr",
}

-- Lookup tabla idioma → voz por defecto (elimina if-else en SetIdioma)
local IDIOMA_A_VOZ_DEFAULT = {
	[IDIOMAS.ESPANOL]  = VOCES.SPANISH_MALE,
	[IDIOMAS.INGLES]   = VOCES.DAVID,
	[IDIOMAS.ITALIANO] = VOCES.ITALIAN_MALE,
	[IDIOMAS.ALEMAN]   = VOCES.GERMAN_MALE,
	[IDIOMAS.FRANCES]  = VOCES.FRENCH_MALE,
}

-- Conjunto de VoiceIds válidos (construido automáticamente desde VOCES)
local VOCES_VALIDAS = {}
for _, id in pairs(VOCES) do
	VOCES_VALIDAS[id] = true
end

-- ════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN DE PERSONAJES — referencia VOCES, no IDs crudos
-- ════════════════════════════════════════════════════════════════

local CONFIG_PERSONAJES = {
	Carlos   = { voiceId = VOCES.SPANISH_MALE,   volumen = 0.6, velocidad = 1.0 },
	Sistema  = { voiceId = VOCES.DAVID,           volumen = 0.4, velocidad = 1.1 },
	Narrador = { voiceId = VOCES.SPANISH_MALE,    volumen = 0.7, velocidad = 0.9 },
	Maria    = { voiceId = VOCES.SPANISH_FEMALE,  volumen = 0.6, velocidad = 1.0 },
	Default  = { voiceId = VOCES.SPANISH_MALE,    volumen = 0.5, velocidad = 1.0 },
}

-- ════════════════════════════════════════════════════════════════
-- FUNCIONES PRIVADAS
-- ════════════════════════════════════════════════════════════════

local function _validarVoz(voiceId)
	return VOCES_VALIDAS[voiceId] == true
end

local function _prepararTexto(texto)
	if not texto then return "" end
	if #texto > 500 then
		texto = texto:sub(1, 497) .. "..."
	end
	texto = texto:gsub("[\n\r]", " ")
	texto = texto:gsub("%s+", " ")
	texto = texto:gsub('"', "'")
	return texto
end

local function _crearSonido(soundId, volumen, speed)
	local sound = Instance.new("Sound")
	sound.SoundId       = soundId
	sound.Volume        = volumen
	sound.PlaybackSpeed = speed
	sound.Parent        = SoundService
	sound:Play()
	Debris:AddItem(sound, 3)
end

-- ════════════════════════════════════════════════════════════════
-- CONSTRUCTOR
-- ════════════════════════════════════════════════════════════════

function DialogoTTS.new()
	local self = setmetatable({}, DialogoTTS)
	self.audioTTS      = nil
	self.deviceOutput  = nil
	self.wire          = nil
	self.habilitado    = true
	self.volumenGlobal = 1.0
	self.idioma        = IDIOMAS.ESPANOL
	self.currentText   = nil
	self.reproduciendo = false

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
-- GESTIÓN DEL PIPELINE DE AUDIO
-- ════════════════════════════════════════════════════════════════

function DialogoTTS:InicializarAudio()
	if not self.ttsDisponible then return end

	self.audioTTS             = Instance.new("AudioTextToSpeech")
	self.audioTTS.Name        = "DialogoTTS_Audio"

	self.deviceOutput         = Instance.new("AudioDeviceOutput")
	self.deviceOutput.Name    = "DialogoTTS_Output"

	self.wire                 = Instance.new("Wire")
	self.wire.Name            = "DialogoTTS_Wire"
	self.wire.SourceInstance  = self.audioTTS
	self.wire.TargetInstance  = self.deviceOutput

	self.audioTTS.Parent      = SoundService
	self.deviceOutput.Parent  = SoundService
	self.wire.Parent          = SoundService

	print("[DialogoTTS] Pipeline de audio inicializado")
end

---Destruye las instancias de audio y crea unas nuevas desde cero
function DialogoTTS:Reiniciar()
	self.currentText   = nil
	self.reproduciendo = false

	if self.wire         then self.wire:Destroy();         self.wire         = nil end
	if self.deviceOutput then self.deviceOutput:Destroy(); self.deviceOutput = nil end
	if self.audioTTS     then self.audioTTS:Destroy();     self.audioTTS     = nil end

	if self.ttsDisponible then
		self:InicializarAudio()
	end

	print("[DialogoTTS] Pipeline reiniciado")
end

-- ════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ════════════════════════════════════════════════════════════════

function DialogoTTS:SetHabilitado(habilitado)
	self.habilitado = habilitado
end

function DialogoTTS:SetVolumen(volumen)
	self.volumenGlobal = math.clamp(volumen, 0, 1)
	if self.deviceOutput then
		self.deviceOutput.Volume = self.volumenGlobal
	end
end

function DialogoTTS:SetIdioma(idioma)
	self.idioma = idioma
	local vozDefault = IDIOMA_A_VOZ_DEFAULT[idioma]
	if vozDefault then
		CONFIG_PERSONAJES.Default.voiceId = vozDefault
	end
end

function DialogoTTS:RegistrarVoz(personaje, config)
	CONFIG_PERSONAJES[personaje] = {
		voiceId   = config.voiceId   or VOCES.SPANISH_MALE,
		volumen   = config.volumen   or 0.5,
		velocidad = config.velocidad or 1.0,
	}
end

-- ════════════════════════════════════════════════════════════════
-- REPRODUCCIÓN TTS
-- ════════════════════════════════════════════════════════════════

function DialogoTTS:Hablar(texto, personaje)
	if not self.habilitado then return false end

	if not self.ttsDisponible or not self.audioTTS then
		self:ReproducirSonidoFallback(personaje)
		return false
	end

	local textoPreparado = _prepararTexto(texto)
	if textoPreparado == "" then return false end

	local config  = CONFIG_PERSONAJES[personaje] or CONFIG_PERSONAJES.Default
	local voiceId = config.voiceId

	if not _validarVoz(voiceId) then
		warn("[DialogoTTS] VoiceId inválido:", voiceId, "→ usando Default")
		voiceId = CONFIG_PERSONAJES.Default.voiceId
	end

	print("[DialogoTTS] Hablando:", textoPreparado:sub(1, 30) .. "...", "| Voz:", voiceId, "| Personaje:", personaje)

	self.currentText            = textoPreparado
	self.audioTTS.Text          = textoPreparado
	self.audioTTS.VoiceId       = voiceId
	self.audioTTS.PlaybackSpeed = config.velocidad

	local exito, err = pcall(function() self.audioTTS:Play() end)
	if exito then
		self.reproduciendo = true
		print("[DialogoTTS] ✓ Reproducción iniciada")
		return true
	else
		warn("[DialogoTTS] ✗ Error al reproducir:", err)
		return false
	end
end

function DialogoTTS:Detener()
	self.currentText   = nil
	self.reproduciendo = false
	if self.audioTTS then
		pcall(function() self.audioTTS:Stop() end)
	end
end

function DialogoTTS:Pausar()
	-- AudioTextToSpeech no tiene Pause nativo
	self:Detener()
end

-- Compatibilidad: PrepararTexto público delega a la función privada
function DialogoTTS:PrepararTexto(texto)
	return _prepararTexto(texto)
end

-- ════════════════════════════════════════════════════════════════
-- EVENTOS
-- ════════════════════════════════════════════════════════════════

function DialogoTTS:OnTerminar(callback)
	if not self.audioTTS then return end
	return self.audioTTS.Ended:Connect(callback)
end

-- ════════════════════════════════════════════════════════════════
-- FALLBACK (cuando TTS no está disponible)
-- ════════════════════════════════════════════════════════════════

function DialogoTTS:ReproducirSonidoFallback(personaje)
	_crearSonido("rbxassetid://9119732940", 0.3 * self.volumenGlobal, 1 + (math.random() - 0.5) * 0.2)
end

function DialogoTTS:SonidoInicio(personaje)
	local config = CONFIG_PERSONAJES[personaje] or CONFIG_PERSONAJES.Default
	_crearSonido("rbxassetid://6895079853", 0.2 * self.volumenGlobal, config.velocidad)
end

function DialogoTTS:ReproducirSonidoHabla(personaje, numPalabras)
	if self.ttsDisponible and self.audioTTS then return end

	local config     = CONFIG_PERSONAJES[personaje] or CONFIG_PERSONAJES.Default
	local numSonidos = math.clamp(math.floor((numPalabras or 10) / 3), 1, 5)

	task.spawn(function()
		for _ = 1, numSonidos do
			_crearSonido(
				"rbxassetid://9119732940",
				0.2 * self.volumenGlobal,
				config.velocidad + (math.random() - 0.5) * 0.1
			)
			task.wait(0.15 + math.random() * 0.1)
		end
	end)
end

-- ════════════════════════════════════════════════════════════════
-- CONSTANTES PÚBLICAS
-- ════════════════════════════════════════════════════════════════

DialogoTTS.VOCES   = VOCES    -- misma tabla, no copia
DialogoTTS.IDIOMAS = IDIOMAS

return DialogoTTS
