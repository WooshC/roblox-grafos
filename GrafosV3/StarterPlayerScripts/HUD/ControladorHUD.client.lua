-- StarterPlayerScripts/HUD/ControladorHUD.client.lua
-- Orquestador del HUD de gameplay - integra todos los módulos

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local jugador = Players.LocalPlayer
local playerGui = jugador:WaitForChild("PlayerGui")

-- Cargar configuración de niveles
local LevelsConfig = require(RS:WaitForChild("Config"):WaitForChild("LevelsConfig"))

print("[GrafosV3] === ControladorHUD Iniciando ===")

-- Esperar GUI
local hudGui = playerGui:WaitForChild("GUIExploradorV2", 30)
if not hudGui then warn("[ControladorHUD] GUIExploradorV2 no encontrado"); return end

-- Evitar doble ejecución
if hudGui:GetAttribute("ControladorHUDActivo") then return end
hudGui:SetAttribute("ControladorHUDActivo", true)

-- Importar módulos
local ModulosHUD = script.Parent:WaitForChild("ModulosHUD")
local EventosHUD = require(ModulosHUD.EventosHUD)
local TransicionHUD = require(ModulosHUD.TransicionHUD)
local PuntajeHUD = require(ModulosHUD.PuntajeHUD)
local PanelMisionesHUD = require(ModulosHUD.PanelMisionesHUD)
local VictoriaHUD = require(ModulosHUD.VictoriaHUD)
local ModuloMapa = require(ModulosHUD.ModuloMapa)

-- Inicializar módulos con referencia al hud
TransicionHUD.reset()
PuntajeHUD.init(hudGui)
PanelMisionesHUD.init(hudGui)
VictoriaHUD.init(hudGui)
ModuloMapa.inicializar(hudGui)

-- Estado del HUD
local hudActivo = false

-- Función para activar el HUD (mostrar y resetear)
local function activarHUD()
	if hudActivo then return end
	hudActivo = true
	
	-- Asegurar que el HUD está visible
	hudGui.Enabled = true
	
	-- Resetear estado
	TransicionHUD.ocultarInmediato()
	PanelMisionesHUD.reiniciar()
	VictoriaHUD.ocultar()
	PuntajeHUD.fijar(0)
	
	print("[ControladorHUD] HUD activado")
end

-- Función para desactivar el HUD
local function desactivarHUD()
	hudActivo = false
	hudGui.Enabled = false
	VictoriaHUD.ocultar()
	
	-- Cerrar el mapa y limpiar al salir del nivel
	local exito, err = pcall(function()
		ModuloMapa.limpiar()
	end)
	if not exito then
		warn("[ControladorHUD] Error al limpiar mapa:", err)
	end
	
	print("[ControladorHUD] HUD desactivado")
end

-- Conectar eventos del servidor

-- NivelListo: El servidor notifica que el nivel está cargado y listo
EventosHUD.nivelListo.OnClientEvent:Connect(function(data)
	if data and data.error then
		warn("[ControladorHUD] Error al cargar nivel:", data.error)
		return
	end
	
	print("[ControladorHUD] NivelListo recibido — activando HUD")
	
	-- Activar HUD
	activarHUD()
	
	-- Configurar el mapa con el nivel actual
	local nivelID = jugador:GetAttribute("CurrentLevelID") or 0
	local nivelActual = workspace:FindFirstChild("NivelActual")
	local configNivel = LevelsConfig[nivelID]
	
	if nivelActual then
		local exito, err = pcall(function()
			ModuloMapa.configurarNivel(nivelActual, nivelID, configNivel)
		end)
		if not exito then
			warn("[ControladorHUD] Error al configurar mapa:", err)
		end
	end
	
	-- Forzar cámara Custom (seguridad)
	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
end)

-- ActualizarMisiones: El servidor envía actualización de estado de misiones
EventosHUD.actualizarMisiones.OnClientEvent:Connect(function(data)
	-- Inyectar zona actual desde atributo del jugador
	local zonaActual = jugador:GetAttribute("ZonaActual")
	if data then
		data.zonaActual = zonaActual
	end
	PanelMisionesHUD.reconstruir(data)
end)

-- Escuchar cambios de zona para actualizar el panel
jugador:GetAttributeChangedSignal("ZonaActual"):Connect(function()
	local zonaActual = jugador:GetAttribute("ZonaActual")
	print("[ControladorHUD] Zona cambiada a:", zonaActual)
	
	-- Solicitar actualización de misiones al servidor
	-- El servidor reenviará ActualizarMisiones con la nueva zona
	-- Por ahora reconstruimos con datos existentes + nueva zona
	local datos = { zonaActual = zonaActual }
	PanelMisionesHUD.reconstruir(datos)
end)

-- ActualizarPuntuacion: El servidor envía actualización de puntaje
EventosHUD.actualizarPuntuacion.OnClientEvent:Connect(function(data)
	if data then
		if data.puntajeBase then
			PuntajeHUD.fijar(data.puntajeBase)
		end
		if data.estrellas then
			PuntajeHUD.fijarEstrellas(data.estrellas)
		end
		if data.dinero then
			PuntajeHUD.fijarDinero(data.dinero)
		end
	end
end)

-- NivelCompletado: El servidor notifica que se completaron todas las misiones
EventosHUD.nivelCompletado.OnClientEvent:Connect(function(snap)
	print("[ControladorHUD] NivelCompletado recibido:", snap ~= nil and "con datos" or "SIN DATOS")
	
	-- Cerrar el mapa inmediatamente al ganar
	local exito, err = pcall(function()
		ModuloMapa.cerrar()
	end)
	if not exito then
		warn("[ControladorHUD] Error al cerrar mapa en victoria:", err)
	end
	
	if snap then
		VictoriaHUD.mostrar(snap)
	end
end)

-- Inicialmente, el HUD debe estar desactivado (el menú está activo)
desactivarHUD()

print("[GrafosV3] ✅ ControladorHUD activo y esperando NivelListo")
