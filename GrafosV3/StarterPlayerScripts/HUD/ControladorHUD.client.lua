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
local AyudaHUD = require(ModulosHUD.AyudaHUD)
local OrquestadorModos = require(script.Parent.Parent:WaitForChild("SistemasGameplay"):WaitForChild("OrquestadorModos"))

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
EjecutorAlgoritmo3D.inicializar(hudGui)

-- Selector de modos: recibe ordenes de OrquestadorModos y también las emite
SelectorModosHUD.init(hudGui, {
	onModoCambiado = function(nuevoModo)
		if nuevoModo == "visual" then
			-- Volver al modo visual: cerrar mapa y paneles UI
			OrquestadorModos.setModo("visual")
			ModuloMatriz.cerrar()
			ModuloAnalisis.cerrar()
		elseif nuevoModo == "matriz" then
			OrquestadorModos.setModo("visual") -- paneles UI requieren modo visual
			ModuloAnalisis.cerrar()
			if ModuloMatriz.estaAbierto and ModuloMatriz.estaAbierto() then
				ModuloMatriz.cerrar()
			else
				ModuloMatriz.abrir()
			end
		elseif nuevoModo == "analisis" then
			OrquestadorModos.setModo("visual") -- paneles UI requieren modo visual
			ModuloMatriz.cerrar()
			if ModuloAnalisis.estaAbierto and ModuloAnalisis.estaAbierto() then
				ModuloAnalisis.cerrar()
			else
				ModuloAnalisis.abrir()
			end
		end
	end
})

-- Conectar OrquestadorModos con SelectorModosHUD
OrquestadorModos.setCallbackUI(function(modo)
	SelectorModosHUD.setModoActivo(modo)
end)

-- Registrar modo visual por defecto (cleanup de modos anteriores)
OrquestadorModos.registrarModo("visual", {
	activar = function()
		-- Al volver a visual no es necesario hacer nada especial;
		-- cada sistema escucha CambioModo y limpia sus efectos.
	end,
	limpiar = function()
		-- No-op: el cleanup real lo hacen los sistemas al recibir CambioModo.
	end
})

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

-- ═══════════════════════════════════════════════════════════════════════════════
-- MODAL DE CONFIRMACIÓN (reutilizable para Reiniciar / Salir)
-- ═══════════════════════════════════════════════════════════════════════════════

local modalFondo = hudGui:FindFirstChild("ModalSalirFondo", true)
local modalPanel = modalFondo and modalFondo:FindFirstChild("ModalSalir")
local modalTitulo = modalPanel and modalPanel:FindFirstChild("ModalTitulo", true)
local modalSub = modalPanel and modalPanel:FindFirstChild("ModalSub", true)
local modalMsg = modalPanel and modalPanel:FindFirstChild("ModalMsg", true)
local modalNote = modalPanel and modalPanel:FindFirstChild("ModalNoteLabel", true)
local btnCancelar = modalPanel and modalPanel:FindFirstChild("BtnCancelarSalir", true)
local btnConfirmar = modalPanel and modalPanel:FindFirstChild("BtnConfirmarSalir", true)

local _modalCallback = nil

local function ocultarModal()
	if modalFondo then
		modalFondo.Visible = false
	end
	_modalCallback = nil
end

local function mostrarModal(titulo, sub, mensaje, nota, callback)
	if not modalFondo or not modalPanel then
		warn("[ControladorHUD] Modal no encontrado, ejecutando acción directamente")
		if callback then callback() end
		return
	end
	if modalTitulo then modalTitulo.Text = titulo or "" end
	if modalSub then modalSub.Text = sub or "" end
	if modalMsg then modalMsg.Text = mensaje or "" end
	if modalNote then modalNote.Text = nota or "" end
	_modalCallback = callback
	modalFondo.Visible = true
end

-- Conectar botones del modal una sola vez
if btnCancelar then
	btnCancelar.MouseButton1Click:Connect(ocultarModal)
end
if btnConfirmar then
	btnConfirmar.MouseButton1Click:Connect(function()
		if _modalCallback then
			local ok, err = pcall(_modalCallback)
			if not ok then
				warn("[ControladorHUD] Error en modal callback:", err)
			end
		end
		ocultarModal()
	end)
end

-- Asegurar que el modal inicie oculto
if modalFondo then
	modalFondo.Visible = false
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- BOTONES DEL HUD (Reiniciar, Salir)
-- ═══════════════════════════════════════════════════════════════════════════════

-- Inicializar GUI de ayuda
AyudaHUD.init(hudGui)

local barraSecundaria = hudGui:FindFirstChild("BarraBotonesSecundarios", true)
if barraSecundaria then
	local btnReiniciar = barraSecundaria:FindFirstChild("BtnReiniciar")
	if btnReiniciar then
		btnReiniciar.MouseButton1Click:Connect(function()
			local nivelID = jugador:GetAttribute("CurrentLevelID")
			mostrarModal(
				"REINICIAR NIVEL",
				"Confirmación requerida",
				"¿Desea reiniciar el nivel? Se perderá todo el progreso no guardado.",
				"Esta acción no se puede deshacer.",
				function()
					if nivelID then
						EventosHUD.reiniciarNivel:FireServer(nivelID)
						print("[ControladorHUD] ReiniciarNivel solicitado — Nivel:", nivelID)
					end
				end
			)
		end)
		print("[ControladorHUD] BtnReiniciar conectado (con modal)")
	else
		warn("[ControladorHUD] BtnReiniciar no encontrado en BarraBotonesSecundarios")
	end

	local btnAyuda = barraSecundaria:FindFirstChild("BtnAyuda")
	if btnAyuda then
		btnAyuda.MouseButton1Click:Connect(function()
			AyudaHUD.alternar()
		end)
		print("[ControladorHUD] BtnAyuda conectado")
	else
		warn("[ControladorHUD] BtnAyuda no encontrado en BarraBotonesSecundarios")
	end
end

local barraMain = hudGui:FindFirstChild("BarraBotonesMain", true)
if barraMain then
	local btnSalir = barraMain:FindFirstChild("BtnSalir")
	if btnSalir then
		btnSalir.MouseButton1Click:Connect(function()
			mostrarModal(
				"SALIR DEL NIVEL",
				"Confirmación requerida",
				"¿Desea salir al menú principal? Se perderá el progreso del nivel actual.",
				"Tu progreso general se mantendrá guardado.",
				function()
					EventosHUD.volverAlMenu:FireServer()
					print("[ControladorHUD] VolverAlMenu solicitado")
				end
			)
		end)
		print("[ControladorHUD] BtnSalir conectado (con modal)")
	else
		warn("[ControladorHUD] BtnSalir no encontrado en BarraBotonesMain")
	end
end

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

-- NivelDescargado: El servidor notifica que el nivel se está descargando (reinicio/salida)
EventosHUD.nivelDescargado.OnClientEvent:Connect(function()
	print("[ControladorHUD] NivelDescargado recibido — limpiando HUD")
	desactivarHUD()
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

local function _configurarBotonesBarra(barra, nombreBarra)
	if not barra then return end

	-- Recolectar botones
	local botones = {}
	for _, btn in ipairs(barra:GetChildren()) do
		if btn:IsA("TextButton") then
			table.insert(botones, btn)
		end
	end
	if #botones == 0 then
		print("[ControladorHUD] No hay botones en", nombreBarra)
		return
	end

	-- Asegurar que todos los botones sean visibles y tengan texto
	for _, btn in ipairs(botones) do
		btn.Visible = true
		btn.TextSize = 18
		btn.Font = Enum.Font.GothamBold
	end

	-- Encontrar el ancho necesario para el texto mas largo
	local maxAncho = 0
	for _, btn in ipairs(botones) do
		local bounds = TextService:GetTextSize(btn.Text, btn.TextSize, btn.Font, Vector2.new(9999, 9999))
		maxAncho = math.max(maxAncho, bounds.X)
	end

	-- Aplicar el mismo ancho a todos (+24px de padding interno)
	local anchoUniforme = maxAncho + 24
	for _, btn in ipairs(botones) do
		btn.Size = UDim2.new(0, anchoUniforme, 1, 0)
	end

	print(string.format("[ControladorHUD] %s configurada. Botones: %d, Ancho: %d",
		nombreBarra, #botones, anchoUniforme))
end

local function _configurarBotonesHUD()
	-- Barra principal
	local barraMain = hudGui:FindFirstChild("BarraBotonesMain", true)
	if barraMain then
		barraMain.Size = UDim2.new(barraMain.Size.X.Scale, barraMain.Size.X.Offset, 0, 52)
		_configurarBotonesBarra(barraMain, "BarraBotonesMain")
	end

	-- Barra secundaria
	local barraSec = hudGui:FindFirstChild("BarraBotonesSecundarios", true)
	if barraSec then
		barraSec.Size = UDim2.new(barraSec.Size.X.Scale, barraSec.Size.X.Offset, 0, 52)
		_configurarBotonesBarra(barraSec, "BarraBotonesSecundarios")
	end
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

print("[GrafosV3] ControladorHUD activo y esperando NivelListo")
