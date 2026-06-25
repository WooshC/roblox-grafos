-- StarterPlayerScripts/SistemasGameplay/AudioGameplay.client.lua
-- Controlador de audio especifico para el Gameplay.

local Players = game:GetService("Players")
local StarterPlayerScripts = game:GetService("StarterPlayer").StarterPlayerScripts

local player = Players.LocalPlayer

print("[AudioGameplay] Script iniciado")

-- Esperar y obtener ControladorAudio
local ControladorAudio = nil
local exito, resultado = pcall(function()
	local modulo = StarterPlayerScripts:WaitForChild("Compartido", 5):WaitForChild("ControladorAudio", 5)
	return require(modulo)
end)

if exito then
	ControladorAudio = resultado
	print("[AudioGameplay] ControladorAudio cargado")
else
	warn("[AudioGameplay] Error cargando ControladorAudio:", resultado)
	return -- Terminar si no hay audio
end

-- Estado
local _activo = false
local _nivelID = nil
local _conexiones = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- ACTIVACION / DESACTIVACION
-- ═══════════════════════════════════════════════════════════════════════════════

local function activar(nivelID)
	if _activo then return end
	_activo = true
	_nivelID = nivelID
	
	print("[AudioGameplay] Activando audio del gameplay - Nivel: " .. tostring(nivelID))
	
	if ControladorAudio then
		-- Fade in suave del ambiente (3 segundos)
		ControladorAudio.playAmbientePorNivel(nivelID)
	end
end

local function desactivar()
	if not _activo then return end
	_activo = false
	
	print("[AudioGameplay] Desactivando audio del gameplay")
	
	-- No desconectamos los eventos (ya validan internamente 'if not _activo').
	-- Eso prevendría que dejen de funcionar si el jugador vuelve a entrar a un nivel.
	
	if ControladorAudio then
		-- Detener ambiente
		if ControladorAudio.stopAmbiente then
			ControladorAudio.stopAmbiente(2.0)
		end
		
		-- IMPORTANTE: Detener musica de victoria si esta sonando
		-- Usar stopVictoria para detener tanto la fanfarria como el tema
		if ControladorAudio.stopVictoria then
			ControladorAudio.stopVictoria(1.0)
		elseif ControladorAudio.stopBGM then
			-- Fallback: solo detener BGM
			ControladorAudio.stopBGM(1.0)
		end
		
		-- Limpiar SFX
		if ControladorAudio.cleanup then
			ControladorAudio.cleanup()
		end
	end
	
	_nivelID = nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONEXION A EVENTOS DEL SERVIDOR (via GestorEfectos)
-- ═══════════════════════════════════════════════════════════════════════════════

local GestorEfectos = require(script.Parent:WaitForChild("GestorEfectos"))

local function conectarEventos()
	-- Eventos de conexion de cables
	GestorEfectos.registrar("NodoSeleccionado", function(_params)
		if not _activo or not ControladorAudio then return end
		ControladorAudio.playNodoSeleccionado()
	end)

	GestorEfectos.registrar("ConexionCompletada", function(_params)
		if not _activo or not ControladorAudio then return end
		ControladorAudio.playCableConectar(true)
	end)

	GestorEfectos.registrar("ConexionInvalida", function(_params)
		if not _activo or not ControladorAudio then return end
		ControladorAudio.playCableConectar(false)
	end)

	GestorEfectos.registrar("CableDesconectado", function(_params)
		if not _activo or not ControladorAudio then return end
		ControladorAudio.playCableDesconectar()
	end)

	-- Evento de victoria (se mantiene directo porque no es un efecto de gameplay)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Eventos = ReplicatedStorage:WaitForChild("EventosGrafosV3", 10)
	if Eventos then
		local Remotos = Eventos:WaitForChild("Remotos")
		local nivelCompletado = Remotos:WaitForChild("NivelCompletado")
		local conn = nivelCompletado.OnClientEvent:Connect(function(data)
			if not _activo or not ControladorAudio then return end
			print("[AudioGameplay] Nivel completado - Reproduciendo victoria")
			ControladorAudio.playVictoria()
		end)
		table.insert(_conexiones, conn)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- INICIALIZACION
-- ═══════════════════════════════════════════════════════════════════════════════

print("[AudioGameplay] Inicializando...")

-- Conectar eventos
conectarEventos()

-- Escuchar eventos de ciclo de vida via GestorEfectos
GestorEfectos.registrar("NivelListo", function(params)
	local data = params.arg1
	if data and data.nivelID ~= nil then
		activar(data.nivelID)
	end
end)

GestorEfectos.registrar("NivelDescargado", function(_params)
	desactivar()
end)

print("[AudioGameplay] Sistema de audio del gameplay inicializado")
