-- ServerScriptService/Services/AudioService.lua


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

local DEFAULT_SOUNDS = {
	CableConnect = "rbxassetid://77515099019542",
	CableSnap = "rbxassetid://131799331821436",
	ConnectionFailed = "rbxassetid://128503882926000",
	Click = "rbxassetid://129273414525214", -- Sonido genérico de click (ejemplo)
	Error = "rbxassetid://128503882926000", -- Sonido genérico de error (ejemplo)
	Success = "rbxassetid://132440961977628" -- Sonido genérico de éxito (ejemplo)
}

function AudioService:init()
	-- Crear o buscar carpeta de sonidos en ReplicatedStorage
	local audioFolder = ReplicatedStorage:FindFirstChild("Audio")
	if not audioFolder then
		audioFolder = Instance.new("Folder")
		audioFolder.Name = "Audio"
		audioFolder.Parent = ReplicatedStorage
	end

	soundsFolder = audioFolder

	-- Asegurar que exista la subcarpeta SFX
	local sfxFolder = soundsFolder:FindFirstChild("SFX")
	if not sfxFolder then
		sfxFolder = Instance.new("Folder")
		sfxFolder.Name = "SFX"
		sfxFolder.Parent = soundsFolder
	end

	-- Verificar y crear sonidos por defecto en la subcarpeta SFX
	for name, id in pairs(DEFAULT_SOUNDS) do
		if not sfxFolder:FindFirstChild(name) then
			local sound = Instance.new("Sound")
			sound.Name = name
			sound.SoundId = id
			sound.Parent = sfxFolder
			print("➕ AudioService: Sonido '" .. name .. "' creado (" .. id .. ")")
		end
	end

	print("✅ AudioService inicializado")
end

-- ============================================
-- SONIDOS DE JUEGO
-- ============================================

-- Reproducer sonido de conexión exitosa
function AudioService:playCableConnected()
	self:playSound("CableConnect", "sfx", {
		pitch = 1.0,
		volume = soundVolumes.sfx
	})
end

-- Reproducir sonido de desconexión
function AudioService:playCableDisconnected()
	self:playSound("CableSnap", "sfx", {
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
function AudioService:playBGM(nombreCancion, loop)
	loop = loop ~= false

	if currentBGM then
		self:stopBGM()
	end

	self:playSound(nombreCancion, "bgm", {
		loop = loop,
		volume = soundVolumes.bgm,
	})

	currentBGM = nombreCancion
end

-- Detiene la música de fondo actual
function AudioService:stopBGM()
	if currentBGM then
		local sound = soundsFolder and soundsFolder:FindFirstChild(currentBGM)
		if sound and sound:IsA("Sound") then sound:Stop() end
		currentBGM = nil
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

	-- Buscar sonido en la subcarpeta correcta según tipo, con fallback a la raíz
	local subfolderName = soundType == "sfx" and "SFX"
		or soundType == "ambient" and "Ambiente"
		or soundType == "bgm" and "Victoria"
		or nil
	local subfolder = subfolderName and soundsFolder:FindFirstChild(subfolderName)
	local soundAsset = (subfolder and subfolder:FindFirstChild(soundName))
		or soundsFolder:FindFirstChild(soundName)
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

	-- Limpiar después de terminar (si no es loop)
	if not sound.Looped then
		game:GetService("Debris"):AddItem(sound, sound.TimeLength + 1)
	end

	soundPlayedEvent:Fire(soundName, soundType)

	return sound
end

-- ============================================
-- CONTROL DE VOLUMEN
-- ============================================

-- Establece volumen para un tipo de sonido
function AudioService:setVolume(soundType, volumeLevel)
	volumeLevel = math.clamp(volumeLevel, 0, 1)
	soundVolumes[soundType] = volumeLevel
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
end

-- Restaura volúmenes
function AudioService:unmuteAll()
	soundVolumes.bgm = 0.5
	soundVolumes.sfx = 0.7
	soundVolumes.voice = 0.8
	soundVolumes.ambient = 0.3
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
end

-- Reproducir música de derrota
function AudioService:playDefeatMusic()
	self:playSound("DefeatTheme", "bgm", {
		loop = false,
		volume = soundVolumes.bgm
	})
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
end

-- Detiene ambiente actual
function AudioService:stopAmbiance()
	print("🌍 AudioService: Ambiente detenido")
end

-- ============================================
-- EVENTOS
-- ============================================

function AudioService:onSoundPlayed(callback)
	soundPlayedEvent.Event:Connect(callback)
end

return AudioService