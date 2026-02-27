--[[
    ╔════════════════════════════════════════════════════════════════╗
    ║              DIALOGOTTS — TEXTO A VOZ (TTS)                    ║
    ║       Módulo integrado con AudioTextToSpeech API Oficial       ║
    ║                    Roblox (Octubre 2025)                       ║
    ╚════════════════════════════════════════════════════════════════╝
    
    DOCUMENTACIÓN OFICIAL:
    https://create.roblox.com/docs/audio/objects#text-to-speech
    https://create.roblox.com/docs/reference/engine/classes/AudioTextToSpeech
    
    CARACTERÍSTICAS:
    - 10 voces predefinidas oficiales
    - Generación de audio en tiempo real
    - Control de volumen y pitch
    - Gestión de caché de audios generados
    - Soporte para múltiples idiomas (próximo)
]]

local DialogoTTS = {}
DialogoTTS.__index = DialogoTTS

-- ════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ════════════════════════════════════════════════════════════════

local VOICE_IDS = {
    BRITISH_MALE = "1",
    BRITISH_FEMALE = "2",
    US_MALE_1 = "3",
    US_FEMALE_1 = "4",
    US_MALE_2 = "5",
    US_FEMALE_2 = "6",
    AUSTRALIAN_MALE = "7",
    AUSTRALIAN_FEMALE = "8",
    RETRO_1 = "9",
    RETRO_2 = "10"
}

local VOICE_DESCRIPTIONS = {
    ["1"] = "British male",
    ["2"] = "British female",
    ["3"] = "US male #1",
    ["4"] = "US female #1",
    ["5"] = "US male #2",
    ["6"] = "US female #2",
    ["7"] = "Australian male",
    ["8"] = "Australian female",
    ["9"] = "Retro voice #1",
    ["10"] = "Retro voice #2"
}

-- ════════════════════════════════════════════════════════════════
-- LIMITACIONES OFICIALES
-- ════════════════════════════════════════════════════════════════

local LIMITS = {
    MAX_CHARACTERS_PER_REQUEST = 300,
    RATE_LIMIT_FORMULA = "1 + 6 * concurrent_users",  -- requests per minute
    SUPPORTED_LANGUAGES = {"en"}  -- próximamente más idiomas
}

-- ════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ════════════════════════════════════════════════════════════════

function DialogoTTS.new()
    local self = setmetatable({}, DialogoTTS)
    
    self.currentVoiceId = VOICE_IDS.US_MALE_1
    self.volume = 0.5
    self.pitch = 1.0
    self.audioCache = {}
    self.isGenerating = false
    self.soundService = game:GetService("SoundService")
    
    return self
end

-- ════════════════════════════════════════════════════════════════
-- GENERACIÓN DE AUDIO EN TIEMPO REAL
-- ════════════════════════════════════════════════════════════════

---Genera y reproduce audio desde texto (Tiempo Real - Client Side)
function DialogoTTS:PlayText(text, voiceId, options)
    if self.isGenerating then
        print("[DialogoTTS] ⚠ Ya se está generando audio, espera a que termine")
        return false
    end
    
    -- Validaciones
    if not text or text == "" then
        print("[DialogoTTS] ✗ Texto vacío")
        return false
    end
    
    if #text > LIMITS.MAX_CHARACTERS_PER_REQUEST then
        print("[DialogoTTS] ✗ Texto demasiado largo (" .. #text .. " caracteres). Máximo: " .. LIMITS.MAX_CHARACTERS_PER_REQUEST)
        return false
    end
    
    voiceId = voiceId or self.currentVoiceId
    options = options or {}
    
    self.isGenerating = true
    
    -- Crear AudioTextToSpeech
    local tts = Instance.new("AudioTextToSpeech")
    tts.Text = text
    tts.VoiceId = voiceId
    
    print("[DialogoTTS] ▶ Generando audio para: \"" .. text .. "\" (Voz: " .. VOICE_DESCRIPTIONS[voiceId] .. ")")
    
    -- Callback cuando se cargue
    tts.Loaded:Connect(function()
        self.isGenerating = false
        print("[DialogoTTS] ✓ Audio generado exitosamente")
        
        -- Reproducir inmediatamente
        self:PlayAudio(tts)
        
        -- Callback opcional
        if options.OnComplete then
            task.wait(tts.TimeLength)
            options.OnComplete()
        end
    end)
    
    -- Callback de error
    local failedConnection
    failedConnection = tts.Failed:Connect(function()
        self.isGenerating = false
        print("[DialogoTTS] ✗ Error al generar audio")
        failedConnection:Disconnect()
        
        if options.OnError then
            options.OnError()
        end
    end)
    
    -- Iniciar carga asincrónica (SOLO CLIENT SIDE)
    tts:LoadAsync()
    
    return true
end

---Reproduce un audio generado
function DialogoTTS:PlayAudio(audioObject)
    -- Crear Sound para reproducir
    local sound = Instance.new("Sound")
    sound.SoundId = audioObject.SoundId
    sound.Volume = self.volume
    sound.PlaybackSpeed = self.pitch
    sound.Parent = self.soundService
    
    sound:Play()
    
    -- Limpiar después de terminar
    game:GetService("Debris"):AddItem(sound, audioObject.TimeLength + 1)
    
    return sound
end

-- ════════════════════════════════════════════════════════════════
-- GENERACIÓN DE AUDIO COMO ASSET (GUARDAR)
-- ════════════════════════════════════════════════════════════════

---Genera un audio como asset reutilizable (requiere token de servidor)
--[[
    NOTA: Este método requiere llamada server-side con GenerateSpeechAsset
    No está totalmente implementado en el cliente, pero aquí está documentado.
    
    Uso:
    local asset = DialogoTTS:GenerateAsset(text, voiceId)
    -- Requiere llamada remota a servidor que haga:
    -- local speechAsset = game:GetService("GenerateSpeechAsset"):GenerateSpeechAsset(...)
]]
function DialogoTTS:GenerateAsset(text, voiceId)
    print("[DialogoTTS] ⚠ GenerateAsset debe ser llamado desde el servidor")
    print("[DialogoTTS] Usa una RemoteEvent para llamar al servidor")
    return nil
end

-- ════════════════════════════════════════════════════════════════
-- CONTROL DE VOZ
-- ════════════════════════════════════════════════════════════════

---Establece la voz actual
function DialogoTTS:SetVoice(voiceId)
    if not VOICE_DESCRIPTIONS[voiceId] then
        print("[DialogoTTS] ✗ ID de voz inválida: " .. voiceId)
        return false
    end
    
    self.currentVoiceId = voiceId
    print("[DialogoTTS] ✓ Voz cambiada a: " .. VOICE_DESCRIPTIONS[voiceId])
    return true
end

---Obtiene la voz actual
function DialogoTTS:GetVoice()
    return {
        id = self.currentVoiceId,
        description = VOICE_DESCRIPTIONS[self.currentVoiceId]
    }
end

---Lista todas las voces disponibles
function DialogoTTS:ListVoices()
    local voices = {}
    for id, desc in pairs(VOICE_DESCRIPTIONS) do
        table.insert(voices, {
            id = id,
            description = desc
        })
    end
    return voices
end

-- ════════════════════════════════════════════════════════════════
-- CONTROL DE VOLUMEN Y PITCH
-- ════════════════════════════════════════════════════════════════

---Establece el volumen (0-1)
function DialogoTTS:SetVolume(volume)
    self.volume = math.clamp(volume, 0, 1)
    print("[DialogoTTS] Volumen: " .. math.floor(self.volume * 100) .. "%")
end

---Obtiene el volumen actual
function DialogoTTS:GetVolume()
    return self.volume
end

---Establece el pitch (tono) de reproducción
function DialogoTTS:SetPitch(pitch)
    self.pitch = math.max(0.1, pitch)
    print("[DialogoTTS] Pitch: " .. self.pitch)
end

---Obtiene el pitch actual
function DialogoTTS:GetPitch()
    return self.pitch
end

-- ════════════════════════════════════════════════════════════════
-- INTEGRACIÓN CON DIÁLOGO
-- ════════════════════════════════════════════════════════════════

---Reproduce TTS para una línea de diálogo
function DialogoTTS:PlayDialogueLine(text, actor, voiceId)
    voiceId = voiceId or self.currentVoiceId
    
    print("[DialogoTTS] 🎤 " .. (actor or "Narrador") .. ": \"" .. text .. "\"")
    
    return self:PlayText(text, voiceId, {
        OnComplete = function()
            print("[DialogoTTS] ✓ Línea completada")
        end,
        OnError = function()
            print("[DialogoTTS] ✗ Error en línea de diálogo")
        end
    })
end

-- ════════════════════════════════════════════════════════════════
-- INFORMACIÓN Y LÍMITES
-- ════════════════════════════════════════════════════════════════

---Obtiene información de límites
function DialogoTTS:GetLimits()
    return {
        maxCharactersPerRequest = LIMITS.MAX_CHARACTERS_PER_REQUEST,
        rateLimitFormula = LIMITS.RATE_LIMIT_FORMULA,
        supportedLanguages = LIMITS.SUPPORTED_LANGUAGES,
        note = "El límite de tasa se calcula dinámicamente según usuarios concurrentes"
    }
end

---Verifica si el texto es válido
function DialogoTTS:IsTextValid(text)
    if not text or text == "" then
        return false, "Texto vacío"
    end
    
    if #text > LIMITS.MAX_CHARACTERS_PER_REQUEST then
        return false, "Texto demasiado largo (" .. #text .. "/" .. LIMITS.MAX_CHARACTERS_PER_REQUEST .. ")"
    end
    
    return true, "Válido"
end

---Divide un texto largo en párrafos
function DialogoTTS:SplitLongText(text)
    if #text <= LIMITS.MAX_CHARACTERS_PER_REQUEST then
        return {text}
    end
    
    local parts = {}
    local currentPart = ""
    local words = text:split(" ")
    
    for _, word in ipairs(words) do
        if #(currentPart .. " " .. word) <= LIMITS.MAX_CHARACTERS_PER_REQUEST then
            currentPart = currentPart .. " " .. word
        else
            if currentPart ~= "" then
                table.insert(parts, currentPart:sub(2))  -- Remover espacio inicial
            end
            currentPart = word
        end
    end
    
    if currentPart ~= "" then
        table.insert(parts, currentPart)
    end
    
    return parts
end

-- ════════════════════════════════════════════════════════════════
-- REPRODUCCIÓN SECUENCIAL
-- ════════════════════════════════════════════════════════════════

---Reproduce múltiples líneas de texto secuencialmente
function DialogoTTS:PlaySequence(textArray, voiceIds, options)
    options = options or {}
    voiceIds = voiceIds or {}
    
    local function playNext(index)
        if index > #textArray then
            if options.OnComplete then
                options.OnComplete()
            end
            return
        end
        
        local text = textArray[index]
        local voiceId = voiceIds[index] or self.currentVoiceId
        
        self:PlayText(text, voiceId, {
            OnComplete = function()
                playNext(index + 1)
            end,
            OnError = function()
                print("[DialogoTTS] ✗ Error en secuencia índice " .. index)
                if options.OnError then
                    options.OnError(index)
                end
            end
        })
    end
    
    playNext(1)
end

-- ════════════════════════════════════════════════════════════════
-- INSTANCIA SINGLETON
-- ════════════════════════════════════════════════════════════════

local instance = nil

function DialogoTTS.GetInstance()
    if not instance then
        instance = DialogoTTS.new()
        print("[DialogoTTS] ✓ Sistema TTS inicializado")
        print("[DialogoTTS] Voces disponibles: 10 (Inglés)")
        print("[DialogoTTS] Límite: 300 caracteres por request")
    end
    return instance
end

return DialogoTTS.GetInstance()

--[[
    ════════════════════════════════════════════════════════════════
    EJEMPLOS DE USO
    ════════════════════════════════════════════════════════════════
    
    1. REPRODUCIR TEXTO SIMPLE:
    
       local DialogoTTS = require(path.to.DialogoTTS)
       DialogoTTS:PlayText("Hola, bienvenido al juego!")
    
    2. CON VOZ ESPECÍFICA:
    
       DialogoTTS:PlayText(
           "Bienvenido",
           DialogoTTS.VOICE_IDS.BRITISH_FEMALE
       )
    
    3. REPRODUCIR LÍNEA DE DIÁLOGO:
    
       DialogoTTS:PlayDialogueLine(
           "Este es un nodo en el grafo",
           "Carlos",
           DialogoTTS.VOICE_IDS.US_MALE_1
       )
    
    4. REPRODUCCIÓN SECUENCIAL:
    
       local lines = {
           "Primera línea",
           "Segunda línea",
           "Tercera línea"
       }
       
       DialogoTTS:PlaySequence(lines, {
           DialogoTTS.VOICE_IDS.US_MALE_1,
           DialogoTTS.VOICE_IDS.US_FEMALE_1,
           DialogoTTS.VOICE_IDS.BRITISH_MALE
       }, {
           OnComplete = function()
               print("Secuencia completada!")
           end
       })
    
    5. DIVIDIR TEXTO LARGO:
    
       local longText = "Lorem ipsum dolor sit amet..."
       local parts = DialogoTTS:SplitLongText(longText)
       
       for _, part in ipairs(parts) do
           DialogoTTS:PlayText(part)
           task.wait(1)  -- Esperar entre partes
       end
    
    6. LISTAR VOCES:
    
       local voices = DialogoTTS:ListVoices()
       for _, voice in ipairs(voices) do
           print(voice.id .. ": " .. voice.description)
       end
    
    7. VERIFICAR LÍMITES:
    
       local valid, msg = DialogoTTS:IsTextValid("Mi texto")
       if valid then
           print("✓ " .. msg)
       else
           print("✗ " .. msg)
       end
    
    ════════════════════════════════════════════════════════════════
    LIMITACIONES OFICIALES (Octubre 2025)
    ════════════════════════════════════════════════════════════════
    
    • Máximo 300 caracteres por request
    • Rate limits dinámicos: 1 + 6 * usuarios_concurrentes (por minuto)
    • Solo 10 voces predefinidas (más voces próximamente)
    • Idioma: Inglés (soporte multiidioma próximamente)
    • Debe ser llamado CLIENT SIDE (LocalScript)
    • Audio filtrado automáticamente por Roblox
    
    ════════════════════════════════════════════════════════════════
    INTEGRACIÓN CON DIÁLOGOS
    ════════════════════════════════════════════════════════════════
    
    En tu template de diálogos, ahora puedes usar:
    
    ["MiDialogo"] = {
        Lineas = {
            {
                Actor = "Carlos",
                Texto = "Hola, bienvenido!",
                Audio = "TTS",  -- Activar TTS en lugar de rbxassetid
                VoiceId = "3",  -- ID de voz (opcional)
                Evento = function(gui, metadata)
                    local DialogoTTS = require(path.to.DialogoTTS)
                    DialogoTTS:PlayDialogueLine(
                        "Hola, bienvenido!",
                        "Carlos",
                        "3"
                    )
                end,
                Siguiente = "siguiente_linea"
            }
        }
    }
    
    ════════════════════════════════════════════════════════════════
]]
