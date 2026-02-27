-- StarterPlayerScripts/Compartido/ControladorAudio.client.lua
-- Controlador de audio unificado para GrafosV3.
-- Maneja SFX, BGM, Ambiente y UI de forma centralizada.
-- USA los objetos Sound EXISTENTES en ReplicatedStorage/Audio/
--
-- PRINCIPIO: Separacion Menu/Gameplay
-- - AudioMenu maneja sonidos del menu (BGM, UI clicks)
-- - AudioGameplay maneja sonidos del juego (SFX, Ambiente)
-- - Nunca suenan ambos al mismo tiempo

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ConfigAudio = require(ReplicatedStorage:WaitForChild("Audio"):WaitForChild("ConfigAudio"))

-- ═══════════════════════════════════════════════════════════════════════════════
-- ESTADO INTERNO
-- ═══════════════════════════════════════════════════════════════════════════════

local ControladorAudio = {}

-- Referencia a carpeta de audio
local _carpetaAudio = nil

-- Contenedor principal de sonidos activos
local _contenedor = nil

-- Sonidos activos
local _sfxActivos = {}        -- SFX actualmente sonando
local _maxSFXSimultaneos = 6  -- Limite de SFX simultaneos

-- Sonidos persistentes (clones)
local _bgmActual = nil        -- Sonido BGM actual (clon)
local _ambienteActual = nil   -- Sonido de ambiente actual (clon)

-- Estado
local _inicializado = false
local _muteado = false
local _volumenMaster = 1.0

-- Tween info para fades
local TWEEN_FADE_IN = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_FADE_OUT = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

-- ═══════════════════════════════════════════════════════════════════════════════
-- INICIALIZACION
-- ═══════════════════════════════════════════════════════════════════════════════

function ControladorAudio.init()
	if _inicializado then return end
	
	-- Obtener referencia a carpeta de audio
	_carpetaAudio = ReplicatedStorage:WaitForChild("Audio", 10)
	if not _carpetaAudio then
		error("[ControladorAudio] No se encontro ReplicatedStorage/Audio")
		return
	end
	
	-- Crear contenedor para sonidos activos en SoundService
	_contenedor = Instance.new("Folder")
	_contenedor.Name = "AudioGrafosV3_Activo"
	_contenedor.Parent = SoundService
	
	_inicializado = true
	print("[ControladorAudio] Inicializado - Usando sonidos de ReplicatedStorage/Audio")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- FUNCIONES INTERNAS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Buscar un objeto Sound en ReplicatedStorage/Audio segun la ruta
local function buscarSonidoOriginal(ruta)
	if not _carpetaAudio then return nil end
	
	local partes = string.split(ruta, "/")
	local actual = _carpetaAudio
	
	for _, parte in ipairs(partes) do
		actual = actual:FindFirstChild(parte)
		if not actual then
			warn("[ControladorAudio] No se encontro: " .. parte .. " en ruta " .. ruta)
			return nil
		end
	end
	
	if actual:IsA("Sound") then
		return actual
	else
		warn("[ControladorAudio] El objeto no es un Sound: " .. ruta)
		return nil
	end
end

-- Clonar un sonido para reproducirlo
local function clonarSonido(sonidoOriginal, parent, nombre)
	if not sonidoOriginal then return nil end
	
	local clon = sonidoOriginal:Clone()
	clon.Name = nombre or sonidoOriginal.Name
	clon.Parent = parent or _contenedor
	return clon
end

-- Aplicar configuracion de volumen y pitch a un sonido
local function aplicarConfiguracion(sonido, config)
	if not sonido or not config then return end
	
	local volumenFinal = ConfigAudio.calcularVolumen(config.Categoria, config.Volumen)
	sonido.Volume = volumenFinal * _volumenMaster
	sonido.PlaybackSpeed = config.Pitch or 1.0
	
	-- Aplicar loop si esta definido
	if config.Loop ~= nil then
		sonido.Looped = config.Loop
	end
end

-- Aplicar fade in a un sonido
local function fadeIn(sonido, duracion, volumenFinal)
	duracion = duracion or 1.0
	
	local volumenObjetivo = volumenFinal or sonido.Volume
	sonido.Volume = 0
	
	-- Asegurar que el sonido este sonando antes de hacer fade
	if not sonido.IsPlaying then
		sonido:Play()
	end
	
	local tween = TweenService:Create(sonido, TweenInfo.new(duracion, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Volume = volumenObjetivo})
	tween:Play()
	return tween
end

-- Aplicar fade out a un sonido
local function fadeOut(sonido, duracion, callback)
	if not sonido then
		if callback then callback() end
		return nil
	end
	
	duracion = duracion or 1.0
	local volumenOriginal = sonido.Volume
	
	-- Si el volumen ya es 0, solo detener
	if volumenOriginal <= 0.01 then
		sonido:Stop()
		if callback then callback() end
		return nil
	end
	
	local tween = TweenService:Create(sonido, TweenInfo.new(duracion, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Volume = 0})
	tween.Completed:Connect(function()
		sonido:Stop()
		sonido.Volume = volumenOriginal
		if callback then callback() end
	end)
	tween:Play()
	return tween
end

-- Limpiar SFX que ya terminaron
local function limpiarSFXTerminados()
	for i = #_sfxActivos, 1, -1 do
		local sfx = _sfxActivos[i]
		if not sfx or not sfx.Parent or not sfx.IsPlaying then
			if sfx and sfx.Parent then
				sfx:Destroy()
			end
			table.remove(_sfxActivos, i)
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SFX - EFECTOS DE SONIDO
-- ═══════════════════════════════════════════════════════════════════════════════

-- Reproducir un SFX por nombre
function ControladorAudio.playSFX(nombreSFX, callback)
	if not _inicializado then ControladorAudio.init() end
	if _muteado then return nil end
	
	local config = ConfigAudio.obtenerConfig("SFX", nombreSFX)
	if not config then
		warn("[ControladorAudio] SFX no encontrado en config: " .. tostring(nombreSFX))
		return nil
	end
	
	-- Buscar sonido original
	local sonidoOriginal = buscarSonidoOriginal(config.Ruta)
	if not sonidoOriginal then
		warn("[ControladorAudio] Sonido original no encontrado: " .. config.Ruta)
		return nil
	end
	
	-- Limpiar SFX viejos
	limpiarSFXTerminados()
	
	-- Limitar SFX simultaneos
	if #_sfxActivos >= _maxSFXSimultaneos then
		-- Destruir el mas antiguo
		local viejo = table.remove(_sfxActivos, 1)
		if viejo and viejo.Parent then
			viejo:Destroy()
		end
	end
	
	-- Clonar y reproducir
	local clon = clonarSonido(sonidoOriginal, _contenedor, "SFX_" .. nombreSFX)
	if not clon then return nil end
	
	aplicarConfiguracion(clon, config)
	
	-- Conectar callback
	if callback then
		clon.Ended:Connect(callback)
	end
	
	-- Auto-limpiar al terminar
	clon.Ended:Connect(function()
		task.delay(0.1, function()
			if clon and clon.Parent then
				clon:Destroy()
			end
			limpiarSFXTerminados()
		end)
	end)
	
	clon:Play()
	table.insert(_sfxActivos, clon)
	
	return clon
end

-- Reproducir SFX de UI
function ControladorAudio.playUI(tipo, callback)
	if not _inicializado then ControladorAudio.init() end
	if _muteado then return nil end
	
	local config = ConfigAudio.obtenerConfig("UI", tipo)
	if not config then
		-- Fallback a Click si no existe
		if tipo ~= "Click" then
			return ControladorAudio.playUI("Click", callback)
		end
		return nil
	end
	
	-- Buscar sonido original
	local sonidoOriginal = buscarSonidoOriginal(config.Ruta)
	if not sonidoOriginal then
		return nil
	end
	
	-- Limpiar
	limpiarSFXTerminados()
	
	-- Clonar y reproducir
	local clon = clonarSonido(sonidoOriginal, _contenedor, "UI_" .. tipo)
	if not clon then return nil end
	
	aplicarConfiguracion(clon, config)
	
	if callback then
		clon.Ended:Connect(callback)
	end
	
	clon.Ended:Connect(function()
		task.delay(0.1, function()
			if clon and clon.Parent then
				clon:Destroy()
			end
		end)
	end)
	
	clon:Play()
	table.insert(_sfxActivos, clon)
	
	return clon
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- BGM - MUSICA DE FONDO
-- ═══════════════════════════════════════════════════════════════════════════════

function ControladorAudio.playBGM(nombreMusica, fadeInDuracion)
	if not _inicializado then ControladorAudio.init() end
	if _muteado then return nil end
	
	local config = ConfigAudio.obtenerConfig("BGM", nombreMusica)
	if not config then
		warn("[ControladorAudio] BGM no encontrado: " .. tostring(nombreMusica))
		return nil
	end
	
	-- Buscar sonido original
	local sonidoOriginal = buscarSonidoOriginal(config.Ruta)
	if not sonidoOriginal then
		return nil
	end
	
	-- Si ya existe un BGM del mismo tipo, no hacer nada
	if _bgmActual and _bgmActual.Name == "BGM_" .. nombreMusica and _bgmActual.IsPlaying then
		print("[ControladorAudio] BGM ya esta sonando: " .. nombreMusica)
		return _bgmActual
	end
	
	-- Detener BGM anterior suavemente
	local bgmAnterior = _bgmActual
	if bgmAnterior then
		fadeOut(bgmAnterior, 1.5, function()
			if bgmAnterior and bgmAnterior.Parent then
				bgmAnterior:Destroy()
			end
		end)
		_bgmActual = nil
	end
	
	-- Crear nuevo BGM (clon)
	_bgmActual = clonarSonido(sonidoOriginal, _contenedor, "BGM_" .. nombreMusica)
	if not _bgmActual then return nil end
	
	aplicarConfiguracion(_bgmActual, config)
	
	-- Aplicar fade in mas suave
	local volumenObjetivo = _bgmActual.Volume
	fadeIn(_bgmActual, fadeInDuracion or 2.0, volumenObjetivo)
	
	print("[ControladorAudio] BGM iniciado: " .. nombreMusica)
	return _bgmActual
end

function ControladorAudio.stopBGM(fadeOutDuracion)
	if not _bgmActual then return end
	
	local bgm = _bgmActual
	_bgmActual = nil -- Limpiar referencia inmediatamente
	
	fadeOut(bgm, fadeOutDuracion or 2.0, function()
		if bgm and bgm.Parent then
			bgm:Destroy()
		end
	end)
end

function ControladorAudio.crossfadeBGM(nuevaMusica, duracion)
	duracion = duracion or 2.0
	
	-- Si no hay BGM actual, solo reproducir el nuevo
	if not _bgmActual then
		ControladorAudio.playBGM(nuevaMusica, duracion)
		return
	end
	
	-- Si es la misma musica, no hacer nada
	if _bgmActual.Name == "BGM_" .. nuevaMusica then
		return
	end
	
	-- Fade out del actual
	local bgmAnterior = _bgmActual
	_bgmActual = nil
	
	fadeOut(bgmAnterior, duracion, function()
		if bgmAnterior and bgmAnterior.Parent then
			bgmAnterior:Destroy()
		end
	end)
	
	-- Fade in del nuevo con solapamiento
	task.delay(duracion * 0.5, function()
		ControladorAudio.playBGM(nuevaMusica, duracion * 0.8)
	end)
end

function ControladorAudio.isBGMPlaying()
	return _bgmActual ~= nil and _bgmActual.IsPlaying
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- AMBIENTE - SONIDOS DE NIVEL
-- ═══════════════════════════════════════════════════════════════════════════════

function ControladorAudio.playAmbiente(nombreAmbiente, fadeInDuracion)
	if not _inicializado then ControladorAudio.init() end
	if _muteado then return nil end
	
	local config = ConfigAudio.obtenerConfig("AMBIENTE", nombreAmbiente)
	if not config then
		warn("[ControladorAudio] Ambiente no encontrado: " .. tostring(nombreAmbiente))
		return nil
	end
	
	-- Buscar sonido original
	local sonidoOriginal = buscarSonidoOriginal(config.Ruta)
	if not sonidoOriginal then
		return nil
	end
	
	-- Si ya existe el mismo ambiente, no hacer nada
	if _ambienteActual and _ambienteActual.Name == "Ambiente_" .. nombreAmbiente and _ambienteActual.IsPlaying then
		return _ambienteActual
	end
	
	-- Detener ambiente anterior suavemente
	local ambienteAnterior = _ambienteActual
	if ambienteAnterior then
		fadeOut(ambienteAnterior, 2.0, function()
			if ambienteAnterior and ambienteAnterior.Parent then
				ambienteAnterior:Destroy()
			end
		end)
		_ambienteActual = nil
	end
	
	-- Crear nuevo ambiente (clon)
	_ambienteActual = clonarSonido(sonidoOriginal, _contenedor, "Ambiente_" .. nombreAmbiente)
	if not _ambienteActual then return nil end
	
	aplicarConfiguracion(_ambienteActual, config)
	
	local volumenObjetivo = _ambienteActual.Volume
	fadeIn(_ambienteActual, fadeInDuracion or 3.0, volumenObjetivo)
	
	print("[ControladorAudio] Ambiente iniciado: " .. nombreAmbiente)
	return _ambienteActual
end

function ControladorAudio.stopAmbiente(fadeOutDuracion)
	if not _ambienteActual then return end
	
	local ambiente = _ambienteActual
	_ambienteActual = nil
	
	fadeOut(ambiente, fadeOutDuracion or 3.0, function()
		if ambiente and ambiente.Parent then
			ambiente:Destroy()
		end
	end)
end

function ControladorAudio.playAmbientePorNivel(nivelID)
	local nombreAmbiente = "Nivel" .. tostring(nivelID)
	return ControladorAudio.playAmbiente(nombreAmbiente, 2.0)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- GAMEPLAY - SONIDOS ESPECIFICOS
-- ═══════════════════════════════════════════════════════════════════════════════

function ControladorAudio.playCableConectar(exito)
	if exito then
		return ControladorAudio.playSFX("CableConnect")
	else
		ControladorAudio.playSFX("ConnectionFailed")
		task.delay(0.1, function()
			ControladorAudio.playSFX("CableSnap")
		end)
	end
end

function ControladorAudio.playCableDesconectar()
	return ControladorAudio.playSFX("CableSnap")
end

function ControladorAudio.playNodoSeleccionado()
	return ControladorAudio.playSFX("NodoSeleccionado")
end

-- Variable local para rastrear la fanfarria de victoria
local _victoriaFanfare = nil

function ControladorAudio.playVictoria()
	if not _inicializado then ControladorAudio.init() end
	
	-- Detener cualquier BGM anterior
	if _bgmActual then
		local bgmAnterior = _bgmActual
		_bgmActual = nil
		fadeOut(bgmAnterior, 0.5, function()
			if bgmAnterior and bgmAnterior.Parent then
				bgmAnterior:Destroy()
			end
		end)
	end
	
	-- Detener ambiente
	ControladorAudio.stopAmbiente(1.0)
	
	-- Buscar config de fanfarria
	local configFanfare = ConfigAudio.obtenerConfig("VICTORIA", "Fanfare")
	if configFanfare then
		local sonidoOriginal = buscarSonidoOriginal(configFanfare.Ruta)
		if sonidoOriginal then
			-- Limpiar fanfarria anterior si existe
			if _victoriaFanfare and _victoriaFanfare.Parent then
				_victoriaFanfare:Destroy()
			end
			
			_victoriaFanfare = clonarSonido(sonidoOriginal, _contenedor, "Victoria_Fanfare")
			if _victoriaFanfare then
				aplicarConfiguracion(_victoriaFanfare, configFanfare)
				_victoriaFanfare:Play()
				
				-- Luego reproducir tema de victoria en loop
				local configTema = ConfigAudio.obtenerConfig("VICTORIA", "Tema")
				if configTema then
					task.delay(sonidoOriginal.TimeLength or 3, function()
						-- Solo reproducir tema si la fanfarria sigue activa (no se cancelo)
						if _victoriaFanfare and _victoriaFanfare.Parent then
							_victoriaFanfare:Destroy()
							_victoriaFanfare = nil
							
							local sonidoTema = buscarSonidoOriginal(configTema.Ruta)
							if sonidoTema then
								_bgmActual = clonarSonido(sonidoTema, _contenedor, "Victoria_Tema")
								if _bgmActual then
									aplicarConfiguracion(_bgmActual, configTema)
									fadeIn(_bgmActual, 1.0)
									_bgmActual:Play()
								end
							end
						end
					end)
				end
				
				return _victoriaFanfare
			end
		end
	end
	return nil
end

-- Funcion para detener especificamente la musica de victoria
function ControladorAudio.stopVictoria(fadeOutDuracion)
	fadeOutDuracion = fadeOutDuracion or 1.0
	
	-- Detener fanfarria si existe
	if _victoriaFanfare and _victoriaFanfare.Parent then
		local fanfare = _victoriaFanfare
		_victoriaFanfare = nil
		fadeOut(fanfare, fadeOutDuracion, function()
			if fanfare and fanfare.Parent then
				fanfare:Destroy()
			end
		end)
	end
	
	-- Detener tema de victoria si existe
	if _bgmActual and (_bgmActual.Name == "Victoria_Tema" or _bgmActual.Name:find("Victoria")) then
		ControladorAudio.stopBGM(fadeOutDuracion)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONTROL GLOBAL
-- ═══════════════════════════════════════════════════════════════════════════════

function ControladorAudio.setMasterVolume(volumen)
	_volumenMaster = math.clamp(volumen, 0, 1)
	ConfigAudio.Volumenes.MASTER = _volumenMaster
	
	-- Actualizar volumenes activos
	if _bgmActual then
		local config = ConfigAudio.obtenerConfig("BGM", _bgmActual.Name:gsub("BGM_", ""))
		if config then
			_bgmActual.Volume = ConfigAudio.calcularVolumen("BGM", config.Volumen)
		end
	end
	
	if _ambienteActual then
		local config = ConfigAudio.obtenerConfig("AMBIENTE", _ambienteActual.Name:gsub("Ambiente_", ""))
		if config then
			_ambienteActual.Volume = ConfigAudio.calcularVolumen("AMBIENTE", config.Volumen)
		end
	end
end

function ControladorAudio.getMasterVolume()
	return _volumenMaster
end

function ControladorAudio.muteAll()
	_muteado = true
	if _bgmActual then
		_bgmActual.Volume = 0
	end
	if _ambienteActual then
		_ambienteActual.Volume = 0
	end
end

function ControladorAudio.unmuteAll()
	_muteado = false
	-- Restaurar volumenes
	ControladorAudio.setMasterVolume(_volumenMaster)
end

function ControladorAudio.isMuted()
	return _muteado
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CLEANUP
-- ═══════════════════════════════════════════════════════════════════════════════

function ControladorAudio.cleanup()
	-- Detener todo
	if ControladorAudio.stopVictoria then
		ControladorAudio.stopVictoria(0.1)
	end
	ControladorAudio.stopBGM(0.1)
	ControladorAudio.stopAmbiente(0.1)
	
	-- Destruir SFX activos
	for _, sfx in ipairs(_sfxActivos) do
		if sfx and sfx.Parent then
			sfx:Destroy()
		end
	end
	_sfxActivos = {}
	
	print("[ControladorAudio] Cleanup completado")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- INICIALIZACION AUTOMATICA
-- ═══════════════════════════════════════════════════════════════════════════════

ControladorAudio.init()

print("[ControladorAudio] Sistema de audio listo - Usando objetos Sound de ReplicatedStorage")

return ControladorAudio
