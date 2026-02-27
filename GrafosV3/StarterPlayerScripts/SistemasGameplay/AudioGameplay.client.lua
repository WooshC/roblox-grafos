-- StarterPlayerScripts/SistemasGameplay/AudioGameplay.client.lua
-- Controlador de audio especifico para el Gameplay.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
	
	-- Desconectar conexiones de eventos de gameplay
	for _, conn in ipairs(_conexiones) do
		if conn then conn:Disconnect() end
	end
	_conexiones = {}
	
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
-- CONEXION A EVENTOS DEL SERVIDOR
-- ═══════════════════════════════════════════════════════════════════════════════

local function conectarEventos()
	local Eventos = ReplicatedStorage:WaitForChild("EventosGrafosV3", 10)
	if not Eventos then return end
	
	local Remotos = Eventos:WaitForChild("Remotos")
	
	-- Eventos de conexion de cables
	local notificarEvento = Remotos:WaitForChild("NotificarSeleccionNodo")
	local conn1 = notificarEvento.OnClientEvent:Connect(function(eventType, arg1, arg2)
		if not _activo or not ControladorAudio then return end
		
		if eventType == "NodoSeleccionado" then
			ControladorAudio.playNodoSeleccionado()
			
		elseif eventType == "ConexionCompletada" then
			ControladorAudio.playCableConectar(true)
			
		elseif eventType == "ConexionInvalida" then
			ControladorAudio.playCableConectar(false)
			
		elseif eventType == "CableDesconectado" then
			ControladorAudio.playCableDesconectar()
			
		end
	end)
	table.insert(_conexiones, conn1)
	
	-- Evento de victoria
	local nivelCompletado = Remotos:WaitForChild("NivelCompletado")
	local conn2 = nivelCompletado.OnClientEvent:Connect(function(data)
		if not _activo or not ControladorAudio then return end
		print("[AudioGameplay] Nivel completado - Reproduciendo victoria")
		ControladorAudio.playVictoria()
	end)
	table.insert(_conexiones, conn2)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- INICIALIZACION
-- ═══════════════════════════════════════════════════════════════════════════════

print("[AudioGameplay] Inicializando...")

-- Conectar eventos
conectarEventos()

-- Escuchar evento de nivel listo
local Eventos = ReplicatedStorage:WaitForChild("EventosGrafosV3", 10)
if Eventos then
	local Remotos = Eventos:WaitForChild("Remotos")
	
	local nivelListo = Remotos:WaitForChild("NivelListo")
	nivelListo.OnClientEvent:Connect(function(data)
		if data and data.nivelID ~= nil then
			activar(data.nivelID)
		end
	end)
	
	local nivelDescargado = Remotos:WaitForChild("NivelDescargado")
	nivelDescargado.OnClientEvent:Connect(function()
		desactivar()
	end)
end

print("[AudioGameplay] Sistema de audio del gameplay inicializado")
