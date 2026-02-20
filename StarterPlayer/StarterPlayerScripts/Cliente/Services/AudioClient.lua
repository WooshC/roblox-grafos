-- StarterPlayer/StarterPlayerScripts/Cliente/Services/AudioClient.lua
-- Maneja música de ambiente, fanfare de victoria y tema de resultados en el cliente.
-- Usa TweenService para fades (funciona en LocalScript, a diferencia de RenderStepped en servidor).

local AudioClient = {}
AudioClient.__index = AudioClient

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService     = game:GetService("TweenService")

local player = Players.LocalPlayer

local LevelsConfig        = nil
local victoryScreenManager = nil   -- inyectado desde GUIExplorador

local soundAmbiente = nil   -- Sound activo de ambiente
local soundsFolder  = nil

local FADE_IN_DUR   = 1.5
local FADE_OUT_DUR  = 0.5
local VOL_AMBIENTE  = 0.4

-- ============================================
-- UTILIDADES INTERNAS
-- ============================================

local function getAudioFolder()
	if soundsFolder then return soundsFolder end
	local audio = ReplicatedStorage:FindFirstChild("Audio")
	soundsFolder = audio
	return audio
end

local function getSoundInFolder(subcarpeta, nombre)
	local audio = getAudioFolder()
	if not audio then return nil end
	local folder = audio:FindFirstChild(subcarpeta)
	if not folder then return nil end
	return folder:FindFirstChild(nombre)
end

local function fadeIn(sound, duracion, volObjetivo)
	sound.Volume = 0
	sound:Play()
	TweenService:Create(sound, TweenInfo.new(duracion), { Volume = volObjetivo }):Play()
end

local function fadeOut(sound, duracion, callback)
	local tween = TweenService:Create(sound, TweenInfo.new(duracion), { Volume = 0 })
	tween.Completed:Connect(function()
		sound:Stop()
		if callback then callback() end
	end)
	tween:Play()
end

-- ============================================
-- FUNCIONES PÚBLICAS
-- ============================================

function AudioClient.initialize(deps)
	LevelsConfig = deps.LevelsConfig

	-- Escuchar cambios de nivel para iniciar/detener ambiente
	player:GetAttributeChangedSignal("CurrentLevelID"):Connect(function()
		local id = player:GetAttribute("CurrentLevelID")
		if id and id >= 0 then
			AudioClient:iniciarAmbiente(id)
		else
			AudioClient:detenerTodo()
		end
	end)

	-- Escuchar evento de victoria desde el servidor
	local Remotes = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes")
	local LevelCompletedEvent = Remotes:FindFirstChild("LevelCompleted")
	if LevelCompletedEvent then
		LevelCompletedEvent.OnClientEvent:Connect(function(stats)
			AudioClient:_onLevelCompleted(stats)
		end)
	else
		warn("⚠️ AudioClient: LevelCompletedEvent no encontrado")
	end

	-- Trigger inicial si ya hay un nivel cargado
	local initialID = player:GetAttribute("CurrentLevelID")
	if initialID and initialID >= 0 then
		AudioClient:iniciarAmbiente(initialID)
	end

	print("✅ AudioClient: Inicializado")
end

function AudioClient.setVictoryScreenManager(vsm)
	victoryScreenManager = vsm
end

function AudioClient:iniciarAmbiente(nivelID)
	-- Detener y destruir clone anterior
	if soundAmbiente then
		local soundToFade = soundAmbiente
		soundAmbiente = nil
		fadeOut(soundToFade, FADE_OUT_DUR, function()
			soundToFade:Destroy()
		end)
	end

	local config = LevelsConfig and LevelsConfig[nivelID]
	if not config or not config.Audio or not config.Audio.Ambiente then return end

	local sourceSound = getSoundInFolder("Ambiente", config.Audio.Ambiente)
	if not sourceSound then
		warn("AudioClient: Ambiente '" .. config.Audio.Ambiente .. "' no encontrado en ReplicatedStorage/Audio/Ambiente/")
		return
	end

	-- Clonar a SoundService para tener propiedad local (evita conflictos de replicación)
	local sound = sourceSound:Clone()
	sound.Parent = game:GetService("SoundService")
	sound.Looped = true
	soundAmbiente = sound
	fadeIn(sound, FADE_IN_DUR, VOL_AMBIENTE)
	print("🎵 AudioClient: Ambiente iniciado — " .. config.Audio.Ambiente)
end

function AudioClient:detenerAmbiente()
	if soundAmbiente then
		local soundToFade = soundAmbiente
		soundAmbiente = nil
		fadeOut(soundToFade, FADE_OUT_DUR, function()
			soundToFade:Destroy()
		end)
	end
end

function AudioClient:reproducirFanfare(nivelID, callback)
	local config  = LevelsConfig and LevelsConfig[nivelID]
	local nombre  = config and config.Audio and config.Audio.Victoria or "Fanfare"
	local sound   = getSoundInFolder("Victoria", nombre)

	if not sound then
		warn("AudioClient: Fanfare '" .. nombre .. "' no encontrado")
		if callback then callback() end
		return
	end

	sound.Looped = false
	sound:Play()

	-- Llamar callback cuando el sonido termina
	local conn
	conn = sound.Ended:Connect(function()
		conn:Disconnect()
		if callback then callback() end
	end)
	print("🎺 AudioClient: Fanfare iniciada")
end

function AudioClient:reproducirTemaVictoria(nivelID)
	local config = LevelsConfig and LevelsConfig[nivelID]
	local nombre = config and config.Audio and config.Audio.TemaVictoria or "Tema"
	local sound  = getSoundInFolder("Victoria", nombre)

	if not sound then
		warn("AudioClient: TemaVictoria '" .. nombre .. "' no encontrado")
		return
	end

	sound.Looped = true
	fadeIn(sound, FADE_IN_DUR, 0.5)
	print("🎶 AudioClient: Tema de victoria iniciado")
end

function AudioClient:detenerTodo()
	self:detenerAmbiente()

	-- Detener cualquier sonido activo en la carpeta Victoria
	local audio = getAudioFolder()
	if not audio then return end
	local victoriaFolder = audio:FindFirstChild("Victoria")
	if victoriaFolder then
		for _, sound in ipairs(victoriaFolder:GetChildren()) do
			if sound:IsA("Sound") and sound.IsPlaying then
				fadeOut(sound, FADE_OUT_DUR)
			end
		end
	end
end

-- ============================================
-- INTERNO: recibe evento de victoria
-- ============================================

function AudioClient:_onLevelCompleted(stats)
	local nivelID = (stats and stats.nivelID) or player:GetAttribute("CurrentLevelID") or 0

	-- Fade out del ambiente
	self:detenerAmbiente()

	-- Reproducir fanfare; cuando termina → mostrar pantalla de victoria
	self:reproducirFanfare(nivelID, function()
		self:reproducirTemaVictoria(nivelID)

		if victoryScreenManager then
			victoryScreenManager:mostrar(stats)
		else
			warn("AudioClient: VictoryScreenManager no inyectado — pantalla de victoria no aparecerá")
		end
	end)
end

return AudioClient
