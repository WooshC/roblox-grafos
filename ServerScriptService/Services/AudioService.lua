-- ServerScriptService/Services/AudioService.lua
-- SERVICIO CENTRALIZADO para gestión de sonidos y música
-- Maneja efectos de sonido, música de fondo, avisos sonoros

local AudioService = {}
AudioService.__index = AudioService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums"))

-- Estado interno
local soundsFolder = nil
local currentBGM = nil
local soundVolumes = {
	bgm = 0.5,
	sfx = 0.7,
	voice = 0.8,
	ambient = 0.3
}

-- Eventos
local soundPlayedEvent = Instance.new("BindableEvent")

-- ============================================
-- INICIALIZACIÓN
-- ============================================

function AudioService:init()
	-- Crear o buscar carpeta de sonidos en ReplicatedStorage
	local audioFolder = ReplicatedStorage:FindFirstChild("Audio")
	if not audioFolder then
		audioFolder = Instance.new("Folder")
		audioFolder.Name = "Audio"
		audioFolder.Parent = ReplicatedStorage
		print("⚠️ AudioService: Carpeta Audio creada en ReplicatedStorage")
		print("   Añade archivos de sonido allí")
	else
		print("✅ AudioService: Carpeta Audio encontrada")
	end

	soundsFolder = audioFolder
	print("✅ AudioService inicializado")
end

-- ============================================
-- SONIDOS DE JUEGO
-- ============================================

-- Reproducer sonido de conexión exitosa
function AudioService:playCableConnected()
	self:playSound("CableConnected", "sfx", {
		pitch = 1.0,
		volume = soundVolumes.sfx
	})
end

-- Reproducir sonido de desconexión
function AudioService:playCableDisconnected()
	self:playSound("CableDisconnected", "sfx", {
		pitch = 0.9,
		volume = soundVolumes.sfx
	})
end

-- Reproducir sonido de energización
function AudioService:playEnergyFlow()
	self:playSound("EnergyFlow", "sfx", {
		pitch = 1.2,
		volume = soundVolumes.sfx * 0.8
	})
end

-- Reproducir sonido de error
function AudioService:playError()
	self:playSound("Error", "sfx", {
		pitch = 0.7,
		volume = soundVolumes.sfx
	})
end

-- Reproducir sonido de éxito
function AudioService:playSuccess()
	self:playSound("Success", "sfx", {
		pitch = 1.3,
		volume = soundVolumes.sfx
	})
end

-- Reproducir sonido de click
function AudioService:playClick()
	self:playSound("Click", "sfx", {
		pitch = 1.0,
		volume = soundVolumes.sfx * 0.5
	})
end

-- ============================================
-- MÚSICA DE FONDO
-- ============================================

-- Cambia la música de fondo del nivel
function AudioService:playBGM(nombreCancion, loop, fadeIn)
	loop = loop ~= false
	fadeIn = fadeIn or 0

	-- Si hay BGM actual, hacer fade out
	if currentBGM then
		self:stopBGM(fadeIn)
		task.wait(fadeIn)
	end

	self:playSound(nombreCancion, "bgm", {
		loop = loop,
		volume = soundVolumes.bgm,
		fadeIn = fadeIn
	})

	currentBGM = nombreCancion
	print("🎵 AudioService: Música de fondo cambiada a " .. nombreCancion)
end

-- Detiene la música de fondo actual
function AudioService:stopBGM(fadeOut)
	fadeOut = fadeOut or 0

	if currentBGM then
		self:fadeOutSound(currentBGM, fadeOut)
		currentBGM = nil
		print("🎵 AudioService: Música de fondo detenida")
	end
end

-- ============================================
-- REPRODUCCIÓN GENÉRICA
-- ============================================

-- Reproduce un sonido genérico
function AudioService:playSound(soundName, soundType, options)
	if not soundsFolder then
		print("⚠️ AudioService: Carpeta de sonidos no inicializada")
		return
	end

	soundType = soundType or "sfx"
	options = options or {}

	-- Buscar sonido en la carpeta
	local soundAsset = soundsFolder:FindFirstChild(soundName)
	if not soundAsset then
		print("⚠️ AudioService: Sonido '" .. soundName .. "' no encontrado")
		return
	end

	-- Crear instancia de sonido si es necesario
	local sound = Instance.new("Sound")
	sound.Name = soundName .. "_instance"
	sound.SoundId = soundAsset:IsA("Sound") and soundAsset.SoundId or "rbxassetid://0"
	sound.Volume = options.volume or soundVolumes[soundType] or 0.5
	sound.Pitch = options.pitch or 1.0
	sound.Looped = options.loop or false
	sound.Parent = workspace

	-- Reproducir
	sound:Play()

	-- Fade in si se especifica
	if options.fadeIn and options.fadeIn > 0 then
		self:fadeInSound(sound, options.fadeIn)
	end

	-- Limpiar después de terminar (si no es loop)
	if not sound.Looped then
		game:GetService("Debris"):AddItem(sound, sound.TimeLength + 1)
	end

	soundPlayedEvent:Fire(soundName, soundType)
	print("🔊 AudioService: Sonido reproducido - " .. soundName)

	return sound
end

-- ============================================
-- EFECTOS DE SONIDO
-- ============================================

-- Fade in de volumen
function AudioService:fadeInSound(sound, duration)
	duration = duration or 1.0
	local startVolume = 0
	local endVolume = soundVolumes.sfx

	local startTime = tick()
	local connection

	connection = game:GetService("RunService").RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		local progress = math.min(elapsed / duration, 1)

		sound.Volume = startVolume + (endVolume - startVolume) * progress

		if progress >= 1 then
			connection:Disconnect()
		end
	end)
end

-- Fade out de volumen
function AudioService:fadeOutSound(sound, duration)
	duration = duration or 1.0
	local startVolume = sound.Volume
	local endVolume = 0

	local startTime = tick()
	local connection

	connection = game:GetService("RunService").RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		local progress = math.min(elapsed / duration, 1)

		sound.Volume = startVolume + (endVolume - startVolume) * progress

		if progress >= 1 then
			connection:Disconnect()
			sound:Stop()
		end
	end)
end

-- ============================================
-- CONTROL DE VOLUMEN
-- ============================================

-- Establece volumen para un tipo de sonido
function AudioService:setVolume(soundType, volumeLevel)
	volumeLevel = math.clamp(volumeLevel, 0, 1)
	soundVolumes[soundType] = volumeLevel
	print("🔊 AudioService: Volumen de " .. soundType .. " = " .. (volumeLevel * 100) .. "%")
end

-- Obtiene volumen actual de un tipo
function AudioService:getVolume(soundType)
	return soundVolumes[soundType] or 0.5
end

-- Mutea todos los sonidos
function AudioService:muteAll()
	for soundType, _ in pairs(soundVolumes) do
		soundVolumes[soundType] = 0
	end
	print("🔇 AudioService: Todos los sonidos muteados")
end

-- Restaura volúmenes
function AudioService:unmuteAll()
	soundVolumes.bgm = 0.5
	soundVolumes.sfx = 0.7
	soundVolumes.voice = 0.8
	soundVolumes.ambient = 0.3
	print("🔊 AudioService: Sonidos restaurados a volumen normal")
end

-- ============================================
-- EVENTOS DE JUEGO
-- ============================================

-- Reproducir sonidos cuando se conectan cables
function AudioService:onCableConnected(graphService)
	if graphService then
		graphService:onConnectionChanged(function(action, nodeA, nodeB)
			if action == "connected" then
				self:playCableConnected()
				self:playEnergyFlow()
			elseif action == "disconnected" then
				self:playCableDisconnected()
			end
		end)
	end
end

-- Reproducir sonidos cuando se completa un nivel
function AudioService:onLevelComplete(levelService)
	if levelService then
		levelService:onLevelLoaded(function(nivelID, levelFolder, config)
			-- Reproducir música del nivel
			local musicName = "Level_" .. nivelID .. "_BGM"
			self:playBGM(musicName, true, 1.0)
		end)
	end
end

-- ============================================
-- MÚSICA POR EVENTO
-- ============================================

-- Reproducir música de victoria
function AudioService:playVictoryMusic()
	self:playSound("VictoryTheme", "bgm", {
		loop = false,
		volume = soundVolumes.bgm
	})
	print("🎵 AudioService: Música de victoria reproducida")
end

-- Reproducir música de derrota
function AudioService:playDefeatMusic()
	self:playSound("DefeatTheme", "bgm", {
		loop = false,
		volume = soundVolumes.bgm
	})
	print("🎵 AudioService: Música de derrota reproducida")
end

-- Reproducir música de menú
function AudioService:playMenuMusic()
	self:playBGM("MenuBGM", true, 1.0)
end

-- ============================================
-- SONIDOS AMBIENTES
-- ============================================

-- Inicia ambientes del nivel
function AudioService:playAmbiance(levelID)
	local ambianceName = "Ambiance_Level_" .. levelID
	self:playSound(ambianceName, "ambient", {
		loop = true,
		volume = soundVolumes.ambient
	})
	print("🌍 AudioService: Ambiente del nivel reproducido")
end

-- Detiene ambiente actual
function AudioService:stopAmbiance()
	-- Buscar y detener cualquier sonido looped de tipo ambient
	print("🌍 AudioService: Ambiente detenido")
end

-- ============================================
-- EVENTOS
-- ============================================

function AudioService:onSoundPlayed(callback)
	soundPlayedEvent.Event:Connect(callback)
end

-- ============================================
-- DEBUG
-- ============================================

function AudioService:debug()
	print("\n📊 ===== DEBUG AudioService =====")
	print("Volúmenes actuales:")
	for soundType, volume in pairs(soundVolumes) do
		print("   " .. soundType .. ": " .. (volume * 100) .. "%")
	end

	if soundsFolder then
		local soundCount = #soundsFolder:GetChildren()
		print("Sonidos disponibles: " .. soundCount)
	else
		print("⚠️ Carpeta de sonidos no inicializada")
	end

	if currentBGM then
		print("BGM actual: " .. currentBGM)
	else
		print("BGM actual: Ninguno")
	end

	print("===== Fin DEBUG =====\n")
end

return AudioService