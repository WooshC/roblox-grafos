-- StarterPlayerScripts/HUD/ControladorHUD.client.lua
-- Orquestador del HUD de gameplay - integra todos los módulos

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local jugador = Players.LocalPlayer
local playerGui = jugador:WaitForChild("PlayerGui")

-- Cargar configuración de niveles
local LevelsConfig = require(RS:WaitForChild("Config"):WaitForChild("LevelsConfig"))

-- Módulo centralizado de controles de teclado
local Controles = require(script.Parent.Parent:WaitForChild("Compartido"):WaitForChild("Controles"))

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
local ModuloMapa   = require(ModulosHUD.ModuloMapa)
local Minimap      = require(ModulosHUD.Minimap)
local ModuloMatriz   = require(ModulosHUD.ModuloMatriz)
local ModuloAnalisis = require(ModulosHUD.ModuloAnalisis)
local PanelLogrosHUD = require(ModulosHUD.PanelLogrosHUD)
local TimerEmergenciaHUD = require(ModulosHUD.TimerEmergenciaHUD)
local SelectorModosHUD = require(ModulosHUD.SelectorModosHUD)
local EjecutorAlgoritmo3D = require(ModulosHUD.EjecutorAlgoritmo3D)

-- Inicializar módulos con referencia al hud
TransicionHUD.reset()
PuntajeHUD.init(hudGui)
PanelMisionesHUD.init(hudGui)
VictoriaHUD.init(hudGui)
ModuloMapa.inicializar(hudGui)
Minimap.inicializar(hudGui)
ModuloMatriz.inicializar(hudGui)
ModuloAnalisis.inicializar(hudGui)
PanelLogrosHUD.init(hudGui)
TimerEmergenciaHUD.init(hudGui)
SelectorModosHUD.init(hudGui)
EjecutorAlgoritmo3D.inicializar(hudGui)

-- Asegurar que la leyenda del mapa inicie oculta (por si el GUI la tiene visible por defecto)
task.defer(function()
	local leyenda = hudGui:FindFirstChild("Leyenda", true)
	if leyenda then
		leyenda.Visible = false
	end
end)

-- ════════════════════════════════════════════════════════════════
-- WRAPPERS: sincronizar SelectorModos con Matriz y Análisis
-- ════════════════════════════════════════════════════════════════
local _matrizAbrir = ModuloMatriz.abrir
local _matrizCerrar = ModuloMatriz.cerrar
local _analisisAbrir = ModuloAnalisis.abrir
local _analisisCerrar = ModuloAnalisis.cerrar

ModuloMatriz.abrir = function(...)
	_matrizAbrir(...)
	SelectorModosHUD.setModoActivo("matriz")
end
ModuloMatriz.cerrar = function(...)
	_matrizCerrar(...)
	SelectorModosHUD.setModoActivo("visual")
end
ModuloAnalisis.abrir = function(...)
	_analisisAbrir(...)
	SelectorModosHUD.setModoActivo("analisis")
end
ModuloAnalisis.cerrar = function(...)
	_analisisCerrar(...)
	SelectorModosHUD.setModoActivo("visual")
end

-- Inicializar módulo centralizado de controles de teclado
Controles.init({
	ModuloMapa = ModuloMapa,
	ModuloAnalisis = ModuloAnalisis,
	ModuloMatriz = ModuloMatriz,
	PanelMisionesHUD = PanelMisionesHUD,
})

-- Helper: cuando el mapa intenta conectar/desconectar nodos,
-- la matriz (si está abierta) se refresca automáticamente.
ModuloMapa.setConexionCallback(function()
	ModuloMatriz.refrescar()
end)

-- Helper: cuando el jugador selecciona el PRIMER nodo en modo mapa,
-- la matriz resalta su fila/columna sin esperar al servidor.
ModuloMapa.setSeleccionCallback(function(nombre)
	ModuloMatriz.seleccionarNodoExterno(nombre)
end)

-- Helper: cuando se cancela la selección en modo mapa,
-- la matriz limpia el resaltado.
ModuloMapa.setCancelCallback(function()
	ModuloMatriz.cancelarSeleccion()
end)

-- Estado del HUD
local hudActivo = false

-- Función para activar el HUD (mostrar y resetear)
local function activarHUD()
	if hudActivo then return end
	hudActivo = true

	-- Asegurar que el HUD está visible
	hudGui.Enabled = true

	-- Resetear estado
	TransicionHUD.reset()
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

	local exitoMM, errMM = pcall(function()
		Minimap.limpiar()
	end)
	if not exitoMM then
		warn("[ControladorHUD] Error al limpiar minimap:", errMM)
	end

	local exitoMatriz, errMatriz = pcall(function()
		ModuloMatriz.limpiar()
	end)
	if not exitoMatriz then
		warn("[ControladorHUD] Error al limpiar matriz:", errMatriz)
	end

	local exitoAna, errAna = pcall(function()
		ModuloAnalisis.limpiar()
	end)
	if not exitoAna then
		warn("[ControladorHUD] Error al limpiar analisis:", errAna)
	end

	local exitoAlg3D, errAlg3D = pcall(function()
		EjecutorAlgoritmo3D.limpiar()
	end)
	if not exitoAlg3D then
		warn("[ControladorHUD] Error al limpiar ejecutor 3D:", errAlg3D)
	end

	local exitoLogros, errLogros = pcall(function()
		PanelLogrosHUD.limpiar()
	end)
	if not exitoLogros then
		warn("[ControladorHUD] Error al limpiar logros:", errLogros)
	end

	local exitoTimer, errTimer = pcall(function()
		TimerEmergenciaHUD.ocultar()
	end)
	if not exitoTimer then
		warn("[ControladorHUD] Error al ocultar timer:", errTimer)
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
	local nivelID = (data and data.nivelID) or jugador:GetAttribute("CurrentLevelID") or 0
	local nivelActual = workspace:FindFirstChild("NivelActual")
	local configNivel = LevelsConfig[nivelID]

	if nivelActual then
		local exito, err = pcall(function()
			ModuloMapa.configurarNivel(nivelActual, nivelID, configNivel)
		end)
		if not exito then
			warn("[ControladorHUD] Error al configurar mapa:", err)
		end

		local exitoMM, errMM = pcall(function()
			Minimap.configurarNivel(nivelActual, nivelID, configNivel)
		end)
		if not exitoMM then
			warn("[ControladorHUD] Error al configurar minimap:", errMM)
		end

		local exitoMatriz, errMatriz = pcall(function()
			ModuloMatriz.configurarNivel(nivelActual, nivelID, configNivel)
		end)
		if not exitoMatriz then
			warn("[ControladorHUD] Error al configurar matriz:", errMatriz)
		end

		local exitoAna, errAna = pcall(function()
			ModuloAnalisis.configurarNivel(nivelActual, nivelID, configNivel)
		end)
		if not exitoAna then
			warn("[ControladorHUD] Error al configurar analisis:", errAna)
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
		if data.dinero ~= nil then
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

-- LogroDesbloqueado: El servidor notifica que se desbloqueó un logro
EventosHUD.logroDesbloqueado.OnClientEvent:Connect(function(datos)
	print("[ControladorHUD] LogroDesbloqueado recibido:", datos and datos.nombre or "SIN DATOS")
	if datos then
		PanelLogrosHUD.alLogroDesbloqueado(datos)
	end
end)

-- TimerEmergencia: El servidor envía actualización del timer de emergencia
EventosHUD.timerEmergencia.OnClientEvent:Connect(function(restante, texto, expirado, completada)
	TimerEmergenciaHUD.actualizar(restante, texto, expirado, completada)
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONFIGURACION DE BOTONES DEL HUD (tamaños grandes)
-- ═══════════════════════════════════════════════════════════════════════════════

local TextService = game:GetService("TextService")

local function _configurarBotonesHUD()
	local barraMain = hudGui:FindFirstChild("BarraBotonesMain", true)
	if not barraMain then return end

	-- Aumentar altura de la barra principal
	barraMain.Size = UDim2.new(barraMain.Size.X.Scale, barraMain.Size.X.Offset, 0, 52)

	-- Recolectar botones
	local botones = {}
	for _, btn in ipairs(barraMain:GetChildren()) do
		if btn:IsA("TextButton") then
			table.insert(botones, btn)
		end
	end
	if #botones == 0 then return end

	-- Encontrar el ancho necesario para el texto mas largo
	local maxAncho = 0
	for _, btn in ipairs(botones) do
		btn.TextSize = 18
		local bounds = TextService:GetTextSize(btn.Text, btn.TextSize, btn.Font, Vector2.new(9999, 9999))
		maxAncho = math.max(maxAncho, bounds.X)
	end

	-- Aplicar el mismo ancho a todos (+24px de padding interno)
	local anchoUniforme = maxAncho + 24
	for _, btn in ipairs(botones) do
		btn.Size = UDim2.new(0, anchoUniforme, 1, 0)
	end

	print("[ControladorHUD] Botones del HUD configurados. Ancho uniforme:", anchoUniforme)
end

_configurarBotonesHUD()

-- ═══════════════════════════════════════════════════════════════════════════════
-- SONIDO + DIALOGO AL COMPLETAR ZONA
-- ═══════════════════════════════════════════════════════════════════════════════

local ControladorAudio = require(script.Parent.Parent:WaitForChild("Compartido"):WaitForChild("ControladorAudio"))
local _zonasCompletadasNotificadas = {}
local _totalZonasNivel = 0

EventosHUD.actualizarMisiones.OnClientEvent:Connect(function(data)
	-- Inyectar zona actual desde atributo del jugador
	local zonaActual = jugador:GetAttribute("ZonaActual")
	if data then
		data.zonaActual = zonaActual
	end
	PanelMisionesHUD.reconstruir(data)

	-- Detectar zonas completadas
	if data and data.porZona then
		local nivelID = jugador:GetAttribute("CurrentLevelID") or 0
		local configNivel = LevelsConfig[nivelID]
		local zonasConfig = configNivel and configNivel.Zonas or {}
		local totalZonas = 0
		for _ in pairs(zonasConfig) do totalZonas = totalZonas + 1 end

		for nombreZona, infoZona in pairs(data.porZona) do
			if infoZona.total and infoZona.completadas and infoZona.total > 0 and infoZona.completadas >= infoZona.total then
				if not _zonasCompletadasNotificadas[nombreZona] then
					_zonasCompletadasNotificadas[nombreZona] = true

					-- Reproducir sonido de exito
					pcall(function()
						ControladorAudio.playSFX("ZonaCompletadaSFX")
					end)

					-- Contar zonas completadas
					local zonasCompletadasCount = 0
					for _, zdata in pairs(data.porZona) do
						if zdata.completadas and zdata.total and zdata.completadas >= zdata.total then
							zonasCompletadasCount = zonasCompletadasCount + 1
						end
					end

					-- Solo mostrar dialogo si NO es la ultima zona
					if zonasCompletadasCount < totalZonas then
						task.delay(0.5, function()
							if _G.ControladorDialogo and _G.ControladorDialogo.iniciar then
								_G.ControladorDialogo.iniciar("ZonaCompletada_Generico", {
									metadata = { zonaNombre = nombreZona }
								})
							end
						end)
					end
				end
			end
		end
	end
end)

-- Limpiar zonas notificadas al cargar nuevo nivel
EventosHUD.nivelListo.OnClientEvent:Connect(function()
	_zonasCompletadasNotificadas = {}
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- DIALOGO INICIAL AL ENTRAR AL NIVEL 0
-- ═══════════════════════════════════════════════════════════════════════════════

EventosHUD.nivelListo.OnClientEvent:Connect(function(data)
	if data and data.error then return end

	local nivelID = (data and data.nivelID) or jugador:GetAttribute("CurrentLevelID") or 0
	local configNivel = LevelsConfig[nivelID]

	if configNivel and configNivel.DialogoInicial then
		task.delay(2, function()
			if _G.ControladorDialogo and _G.ControladorDialogo.iniciar then
				_G.ControladorDialogo.iniciar(configNivel.DialogoInicial)
			end
		end)
	end
end)

-- Inicialmente, el HUD debe estar desactivado (el menú está activo)
desactivarHUD()

print("[GrafosV3] ✅ ControladorHUD activo y esperando NivelListo")
