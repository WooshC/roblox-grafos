-- StarterPlayerScripts/Dialogo/ControladorDialogo.client.lua
-- Orquestador del sistema de diálogos - integra dialogos con el HUD
-- REFACTORIZADO: Usa ServicioCamara y cierra mapa automáticamente

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local jugador = Players.LocalPlayer
local playerGui = jugador:WaitForChild("PlayerGui")

print("[GrafosV3] === ControladorDialogo Iniciando ===")

-- ═══════════════════════════════════════════════════════════════════════════════
-- SERVICIOS COMPARTIDOS
-- ═══════════════════════════════════════════════════════════════════════════════

local ServicioCamara = require(RS:WaitForChild("Compartido"):WaitForChild("ServicioCamara"))
local GestorColisiones = require(RS:WaitForChild("Compartido"):WaitForChild("GestorColisiones"))
local GestorBloqueos = require(RS:WaitForChild("Compartido"):WaitForChild("GestorBloqueos"))
local LevelsConfig = require(RS:WaitForChild("Config"):WaitForChild("LevelsConfig"))
local Utilidades = require(RS:WaitForChild("Compartido"):WaitForChild("Utilidades"))
local DialogoJugadorController = require(script.Parent:WaitForChild("DialogoJugadorController"))

-- (obtenerModuloMapa movido a DialogoJugadorController)

-- ═══════════════════════════════════════════════════════════════════════════════
-- REFERENCIAS A SISTEMAS EXTERNOS
-- ═══════════════════════════════════════════════════════════════════════════════

local eventos = RS:WaitForChild("EventosGrafosV3")
local remotos = eventos:WaitForChild("Remotos")

-- ═══════════════════════════════════════════════════════════════════════════════
-- CARGAR TODOS LOS MÓDULOS DE DIÁLOGO
-- ═══════════════════════════════════════════════════════════════════════════════

local Dialogo = script.Parent

-- Función segura para cargar módulos (delegada a Utilidades.safeRequire)
local function cargarModulo(nombre)
	local modulo = Dialogo:FindFirstChild(nombre)
	if not modulo then
		warn("[ControladorDialogo] Módulo no encontrado:", nombre)
		return nil
	end
	local resultado = Utilidades.safeRequire(modulo, nombre)
	if resultado then
		print("[ControladorDialogo] ✓ Módulo cargado:", nombre)
	end
	return resultado
end

-- Cargar módulos en orden
local Modulos = {
	DialogoController        = cargarModulo("DialogoController"),
	DialogoRenderer          = cargarModulo("DialogoRenderer"),
	DialogoNarrator          = cargarModulo("DialogoNarrator"),
	DialogoEvents            = cargarModulo("DialogoEvents"),
	DialogoTTS               = cargarModulo("DialogoTTS"),
	DialogoGUISystem         = cargarModulo("DialogoGUISystem"),
	DialogoButtonHighlighter = cargarModulo("DialogoButtonHighlighter"),   -- señalización de botones HUD
}

-- Módulos opcionales (no bloquean el inicio si faltan)
local MODULOS_OPCIONALES = { DialogoButtonHighlighter = true }

-- Verificar que todos los módulos requeridos se cargaron
local modulosOk = true
for nombre, modulo in pairs(Modulos) do
	if not modulo and not MODULOS_OPCIONALES[nombre] then
		warn("[ControladorDialogo] Módulo faltante:", nombre)
		modulosOk = false
	end
end

if not modulosOk then
	warn("[ControladorDialogo] Sistema de diálogos no disponible - faltan módulos")
	return
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- INICIALIZAR SISTEMA DE DIÁLOGOS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Establecer dependencias
Modulos.DialogoGUISystem:SetModules(Modulos)

-- Crear instancia y inicializar
local DialogoGUISystem = Modulos.DialogoGUISystem.new()
local initExito = DialogoGUISystem:InitSafe()

if not initExito then
	warn("[ControladorDialogo] Falló la inicialización del sistema de diálogos")
	return
end

print("[ControladorDialogo] ✓ Sistema de diálogos inicializado correctamente")

-- ═══════════════════════════════════════════════════════════════════════════════
-- FORWARDING DE ACCIONES DE GAMEPLAY AL SISTEMA DE DIÁLOGOS INTERACTIVOS
-- ═══════════════════════════════════════════════════════════════════════════════
-- Escucha eventos de ConectarCables y los traduce para que un diálogo con
-- EsperarAccion pueda avanzar automáticamente cuando el jugador actúa.

local notificarSeleccionNodo = remotos:WaitForChild("NotificarSeleccionNodo", 10)
if notificarSeleccionNodo then
	notificarSeleccionNodo.OnClientEvent:Connect(function(tipo, argA, argB)
		if not DialogoGUISystem.isPlaying or not DialogoGUISystem._esperandoAccion then return end

		if tipo == "NodoSeleccionado" then
			-- argA = Model del nodo seleccionado (instancia)
			local nombreNodo = argA and argA.Name
			if nombreNodo then
				DialogoGUISystem:onAccionJugador("seleccionarNodo", { nodo = nombreNodo })
			end
		elseif tipo == "ConexionCompletada" then
			-- argA = nomA (string), argB = nomB (string)
			if argA and argB then
				DialogoGUISystem:onAccionJugador("conectarNodos", { nodoA = argA, nodoB = argB })
			end
		end
	end)
	print("[ControladorDialogo] ✓ Forwarding de acciones de gameplay conectado")
else
	warn("[ControladorDialogo] NotificarSeleccionNodo no encontrado - diálogos interactivos no funcionarán")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- ESTADO DEL SISTEMA
-- ═══════════════════════════════════════════════════════════════════════════════

local dialogoActivo = false
local promptsConectados = {}
local nivelActual = nil

-- Configuración por defecto de restricciones
local RESTRICCIONES_DEFAULT = {
	bloquearMovimiento = true,
	bloquearSalto = true,
	bloquearCarrera = true,
	apuntarCamara = true,
	permitirConexiones = false  -- Si true, el jugador puede hacer conexiones durante el diálogo
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- FUNCIONES DE GESTIÓN DE PROMPTS
-- ═══════════════════════════════════════════════════════════════════════════════

local function conectarPrompt(promptPart, configDialogo)
	if not promptPart then return end

	local prompt = promptPart:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		warn("[ControladorDialogo] No se encontró ProximityPrompt en:", promptPart.Name)
		return
	end

	if promptsConectados[prompt] then return end
	promptsConectados[prompt] = true

	print("[ControladorDialogo] Conectando prompt:", promptPart.Name, "-> Dialogo:", configDialogo.id)

	prompt.ActionText = configDialogo.actionText or "Hablar"
	prompt.ObjectText = configDialogo.objectText or "Personaje"
	prompt.KeyboardKeyCode = configDialogo.tecla or Enum.KeyCode.E
	prompt.MaxActivationDistance = configDialogo.distancia or 20
	prompt.HoldDuration = configDialogo.holdDuration or 0

	prompt.Triggered:Connect(function(playerWhoTriggered)
		if playerWhoTriggered ~= jugador then return end
		if dialogoActivo then return end
		if configDialogo.unaVez and jugador:GetAttribute("DialogoVisto_" .. configDialogo.id) then
			print("[ControladorDialogo] Diálogo ya visto:", configDialogo.id)
			return
		end

		print("[ControladorDialogo] Iniciando diálogo:", configDialogo.id)

		if configDialogo.unaVez then
			jugador:SetAttribute("DialogoVisto_" .. configDialogo.id, true)
		end

		local metadata = {
			nivelID = jugador:GetAttribute("CurrentLevelID") or 0,
			zonaActual = jugador:GetAttribute("ZonaActual") or "",
			promptPart = promptPart,
			config = configDialogo
		}

		if configDialogo.alIniciar then
			configDialogo.alIniciar(metadata)
		end

		iniciarDialogo(configDialogo.id, metadata)
	end)
end

local function buscarYConectarPrompts()
	promptsConectados = {}

	nivelActual = Workspace:FindFirstChild("NivelActual")
	if not nivelActual then
		warn("[ControladorDialogo] No se encontró NivelActual en Workspace")
		return
	end

	local dialoguePrompts = nivelActual:FindFirstChild("DialoguePrompts")
	if not dialoguePrompts then
		-- print("[ControladorDialogo] No hay DialoguePrompts en este nivel")
		return
	end

	-- print("[ControladorDialogo] Buscando prompts en:", dialoguePrompts.Name)
	-- print("[ControladorDialogo] Hijos encontrados en DialoguePrompts:", #dialoguePrompts:GetChildren())

	for _, modeloDialogo in ipairs(dialoguePrompts:GetChildren()) do
		-- print("[ControladorDialogo] Revisando:", modeloDialogo.Name, "Tipo:", modeloDialogo.ClassName)

		if modeloDialogo:IsA("Model") or modeloDialogo:IsA("Folder") then
			local promptPart = modeloDialogo:FindFirstChild("PromptPart")
			if promptPart then
				-- print("[ControladorDialogo] ✓ PromptPart encontrado en:", modeloDialogo.Name)
				local config = {
					id = modeloDialogo:GetAttribute("DialogoID") or modeloDialogo.Name,
					actionText = modeloDialogo:GetAttribute("ActionText") or "Hablar",
					objectText = modeloDialogo:GetAttribute("ObjectText") or modeloDialogo.Name,
					tecla = modeloDialogo:GetAttribute("Tecla") or Enum.KeyCode.E,
					distancia = modeloDialogo:GetAttribute("Distancia") or 20,
					holdDuration = modeloDialogo:GetAttribute("HoldDuration") or 0,
					unaVez = modeloDialogo:GetAttribute("UnaVez") or false,
					ocultarHUD = modeloDialogo:GetAttribute("OcultarHUD") ~= false,

					-- Nuevas opciones de restricción
					restricciones = {
						bloquearMovimiento = modeloDialogo:GetAttribute("BloquearMovimiento") ~= false,  -- default true
						bloquearSalto = modeloDialogo:GetAttribute("BloquearSalto") ~= false,            -- default true
						bloquearCarrera = modeloDialogo:GetAttribute("BloquearCarrera") ~= false,        -- default true
						apuntarCamara = modeloDialogo:GetAttribute("ApuntarCamara") ~= false,            -- default true
						permitirConexiones = modeloDialogo:GetAttribute("PermitirConexiones") == true    -- default false
					}
				}

				conectarPrompt(promptPart, config)
			else
				warn("[ControladorDialogo] Modelo sin PromptPart:", modeloDialogo.Name)
			end
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- FUNCIÓN PRINCIPAL: INICIAR DIÁLOGO
-- ═══════════════════════════════════════════════════════════════════════════════

function iniciarDialogo(dialogoID, metadata)
	if dialogoActivo then
		warn("[ControladorDialogo] Ya hay un diálogo activo")
		return false
	end

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- PASO 0: CARGAR DATOS DEL DIÁLOGO (necesario antes de leer Configuracion)
	-- ═══════════════════════════════════════════════════════════════════════════════
	local datosDialogo = nil
	if DialogoGUISystem then
		datosDialogo = DialogoGUISystem:LoadDialogue(dialogoID)
	end

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- PASO 0.5: CERRAR MAPA SI ESTÁ ABIERTO (evita bugs de cámara)
	-- Se omite si el diálogo (o las opciones) declaran cerrarMapa = false
	-- ═══════════════════════════════════════════════════════════════════════════════
	local cerrarMapaConfig = metadata.config and metadata.config.cerrarMapa
	-- Leer del archivo de diálogo si no viene en las opciones
	if cerrarMapaConfig == nil and datosDialogo and datosDialogo.Configuracion then
		cerrarMapaConfig = datosDialogo.Configuracion.cerrarMapa
	end
	local cerrarMapaAlIniciar = not (cerrarMapaConfig == false)
	if cerrarMapaAlIniciar then
		local ModuloMapa = DialogoJugadorController.obtenerModuloMapa()
		if ModuloMapa and ModuloMapa.estaAbierto and ModuloMapa.estaAbierto() then
			print("[ControladorDialogo] Cerrando mapa antes de iniciar diálogo...")
			ModuloMapa.cerrar()
			task.wait(0.1)
		end
	end

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- PASO 1: OCULTAR TECHOS SI ESTÁ CONFIGURADO
	-- ═══════════════════════════════════════════════════════════════════════════════
	local ocultarTechosConfig = (metadata.config and metadata.config.ocultarTechos)
		or (datosDialogo and datosDialogo.Configuracion and datosDialogo.Configuracion.ocultarTechos)
	if ocultarTechosConfig then
		print("[ControladorDialogo] Ocultando techos para diálogo...")
		GestorColisiones:ocultarTecho()
	end

	dialogoActivo = true

	-- Notificar al servidor que el diálogo inició (pausar timer de emergencia)
	local dialogoIniciadoEvento = remotos:FindFirstChild("DialogoIniciado")
	if dialogoIniciadoEvento then
		local ok, err = pcall(function() dialogoIniciadoEvento:FireServer() end)
		if ok then
			print("[ControladorDialogo] 📤 DialogoIniciado enviado al servidor")
		else
			warn("[ControladorDialogo] ❌ Error enviando DialogoIniciado:", err)
		end
	else
		warn("[ControladorDialogo] ❌ DialogoIniciado no encontrado en Remotos")
	end

	-- Combinar restricciones: Defaults → Config del archivo → Config del prompt/atributos
	local restricciones = {}

	-- 1. Empezar con defaults
	for key, value in pairs(RESTRICCIONES_DEFAULT) do
		restricciones[key] = value
	end

	-- 2. Aplicar configuración del archivo de diálogo (si existe)
	if datosDialogo and datosDialogo.Configuracion then
		for key, value in pairs(datosDialogo.Configuracion) do
			restricciones[key] = value
		end
		print("[ControladorDialogo] Configuración cargada del archivo de diálogo")
	end

	-- 3. Aplicar configuración del prompt/atributos (si existe, tiene prioridad)
	if metadata.config and metadata.config.restricciones then
		for key, value in pairs(metadata.config.restricciones) do
			restricciones[key] = value
		end
	end

	-- Guardar restricciones en metadata para que otros sistemas las consulten
	metadata.restricciones = restricciones

	-- Crear instancia del highlighter de botones (nil si el módulo no cargó)
	if Modulos.DialogoButtonHighlighter then
		metadata.buttonHighlighter = Modulos.DialogoButtonHighlighter.new(DialogoJugadorController.obtenerHudGui())
	end

	-- NOTA: La cámara NO se mueve aquí automáticamente.
	-- El movimiento de cámara se hace mediante Eventos en las líneas de diálogo específicas.

	-- Bloquear movimiento si está configurado
	if restricciones.bloquearMovimiento or restricciones.bloquearSalto or restricciones.apuntarCamara then
		DialogoJugadorController.bloquear(restricciones)
	end

	-- Verificar si ocultar HUD (del archivo o del prompt)
	local debeOcultarHUD = true
	if datosDialogo and datosDialogo.Metadata and datosDialogo.Metadata.OcultarHUD ~= nil then
		debeOcultarHUD = datosDialogo.Metadata.OcultarHUD
	end
	if metadata.config and metadata.config.ocultarHUD ~= nil then
		debeOcultarHUD = metadata.config.ocultarHUD
	end

	if debeOcultarHUD then
		DialogoJugadorController.ocultarHUD()
	end

	-- Determinar si debemos restaurar techos al cerrar
	local debenRestaurarTechos = ocultarTechosConfig

	-- Activar click aéreo si la cámara está cenital Y el diálogo permite conexiones
	local permitirConexiones = restricciones.permitirConexiones
	if ocultarTechosConfig and permitirConexiones then
		DialogoJugadorController.activarClickAereo(function(nombreNodo)
			if DialogoGUISystem and DialogoGUISystem._esperandoAccion then
				DialogoGUISystem:onAccionJugador("seleccionarNodo", { nodo = nombreNodo })
			end
		end)
	end

	DialogoGUISystem:OnClose(function()
		print("[ControladorDialogo] Diálogo cerrado:", dialogoID)

		-- Restaurar botones del HUD destacados (por si quedaron activos)
		if metadata.buttonHighlighter then
			metadata.buttonHighlighter:restaurarTodo()
		end

		-- Desactivar click aéreo si estaba activo
		DialogoJugadorController.desactivarClickAereo()

		-- Restaurar movimiento
		DialogoJugadorController.desbloquear()

		-- Restaurar techos si es necesario
		if debenRestaurarTechos then
			print("[ControladorDialogo] Restaurando techos...")
			GestorColisiones:restaurar()
		end

		DialogoJugadorController.mostrarHUD()

		if metadata.config and metadata.config.alCerrar then
			metadata.config.alCerrar(metadata)
		end

		-- Notificar al servidor que el diálogo terminó (reanudar timer de emergencia)
		local dialogoTerminadoEvento = remotos:FindFirstChild("DialogoTerminado")
		if dialogoTerminadoEvento then
			local ok, err = pcall(function() dialogoTerminadoEvento:FireServer() end)
			if ok then
				print("[ControladorDialogo] 📤 DialogoTerminado enviado al servidor")
			else
				warn("[ControladorDialogo] ❌ Error enviando DialogoTerminado:", err)
			end
		else
			warn("[ControladorDialogo] ❌ DialogoTerminado no encontrado en Remotos")
		end

		dialogoActivo = false
	end)

	local exito = DialogoGUISystem:Play(dialogoID, metadata)

	if not exito then
		-- Si falla, restaurar todo
		DialogoJugadorController.desactivarClickAereo()
		DialogoJugadorController.desbloquear()
		DialogoJugadorController.mostrarHUD()
		-- Notificar al servidor que el diálogo terminó (aunque falló)
		local dialogoTerminadoEvento = remotos:FindFirstChild("DialogoTerminado")
		if dialogoTerminadoEvento then
			local ok, err = pcall(function() dialogoTerminadoEvento:FireServer() end)
			if ok then
				print("[ControladorDialogo] 📤 DialogoTerminado enviado al servidor (fallback)")
			else
				warn("[ControladorDialogo] ❌ Error enviando DialogoTerminado (fallback):", err)
			end
		else
			warn("[ControladorDialogo] ❌ DialogoTerminado no encontrado en Remotos (fallback)")
		end
		dialogoActivo = false
	end

	return exito
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- API PÚBLICA
-- ═══════════════════════════════════════════════════════════════════════════════

local ControladorDialogo = {}

---Inicia un diálogo programáticamente
-- @param dialogoID string - ID del diálogo (ej: "Nivel0_Carlos_Bienvenida")
-- @param opciones table - Opcional. Configuración adicional:
--   {
--     promptPart = BasePart,    -- Parte para enfocar la cámara
--     alIniciar = function,     -- Callback al iniciar
--     alCerrar = function,      -- Callback al cerrar
--     ocultarHUD = true/false,  -- Ocultar HUD durante diálogo (default: true)
--     ocultarTechos = true/false, -- Ocultar techos durante diálogo (default: false)
--     restricciones = {         -- Sobreescribe la configuración del archivo
--       bloquearMovimiento = true/false,
--       bloquearSalto = true/false,
--       apuntarCamara = true/false,
--       permitirConexiones = true/false
--     }
--   }
function ControladorDialogo.iniciar(dialogoID, opciones)
	opciones = opciones or {}

	-- Construir metadata compatible
	local metadata = {
		nivelID = jugador:GetAttribute("CurrentLevelID") or 0,
		zonaActual = jugador:GetAttribute("ZonaActual") or "",
		promptPart = opciones.promptPart,
		config = {
			restricciones = opciones.restricciones,
			alIniciar = opciones.alIniciar,
			alCerrar = opciones.alCerrar,
			ocultarHUD = opciones.ocultarHUD,
			ocultarTechos = opciones.ocultarTechos
		}
	}

	return iniciarDialogo(dialogoID, metadata)
end

function ControladorDialogo.estaActivo()
	return dialogoActivo
end

function ControladorDialogo.cerrar()
	if dialogoActivo then
		DialogoGUISystem:Close()
	end
end

function ControladorDialogo.obtenerSistema()
	return DialogoGUISystem
end

---Mueve la cámara hacia un punto de enfoque.
-- Uso simple (top-down):
--   _G.ControladorDialogo.moverCamara("Nodo1_z1")
--   _G.ControladorDialogo.moverCamara("Nodo1_z1", 1.0)       -- con duración
-- Uso avanzado (tabla de opciones):
--   _G.ControladorDialogo.moverCamara("Nodo1_z1", {
--       altura   = 20,   -- altura sobre el objetivo (default: 13)
--       angulo   = 65,   -- 90=cenital, 60=estrategia, 45=isométrico (default: 90)
--       distancia = 0,   -- offset horizontal adicional (default: 0)
--       duracion = 1.0,  -- duración de la transición (default: 0.8)
--   })
-- @param enfoque string (nombre nodo), Vector3, BasePart, o Model
-- @param opcionesODuracion table|number - Opciones avanzadas o duración simple
function ControladorDialogo.moverCamara(enfoque, opcionesODuracion)
	if type(opcionesODuracion) == "table" then
		return ServicioCamara.moverHaciaObjetivo(enfoque, opcionesODuracion)
	else
		-- API simple: segundo arg es duracion (número) o nil → top-down con defaults
		return ServicioCamara.moverHaciaObjetivo(enfoque, {
			altura   = 13,
			angulo   = 90,
			duracion = opcionesODuracion or 0.8,
		})
	end
end

---Restaura la cámara a su estado original
-- Uso desde eventos de diálogo: _G.ControladorDialogo.restaurarCamara()
-- @param duracion number - Opcional, duración de la transición (default: 0.5)
function ControladorDialogo.restaurarCamara(duracion)
	ServicioCamara.restaurar(duracion or 0.5)
end

_G.ControladorDialogo = ControladorDialogo
_G.GestorBloqueos = GestorBloqueos

local dialogosZonaVistos = {}

---Devuelve el DialogoID configurado para una zona en el nivel actual, o nil si no tiene.
local function obtenerDialogoDeZona(nombreZona)
	local nivelID  = jugador:GetAttribute("CurrentLevelID") or 0
	local config   = LevelsConfig[nivelID]
	if not config or not config.Zonas then return nil end

	local zonaData = config.Zonas[nombreZona]
	return zonaData and zonaData.Dialogo or nil
end

---Se llama cada vez que ZonaActual cambia. Lanza el diálogo si la zona lo tiene configurado.
local function onZonaChanged()
	local nombreZona = jugador:GetAttribute("ZonaActual") or ""
	if nombreZona == "" then return end

	-- ¿Ya se mostró en este nivel?
	if dialogosZonaVistos[nombreZona] then return end

	-- ¿Esta zona tiene diálogo configurado?
	local dialogoID = obtenerDialogoDeZona(nombreZona)
	if not dialogoID then return end

	-- ¿Ya hay un diálogo activo?
	if dialogoActivo then
		print("[ControladorDialogo] Diálogo activo al entrar a zona, omitiendo:", nombreZona)
		return
	end

	-- Marcar antes del wait para evitar doble disparo si el jugador sale y vuelve rápido
	dialogosZonaVistos[nombreZona] = true
	print(string.format("[ControladorDialogo] Zona '%s' → iniciando diálogo '%s'", nombreZona, dialogoID))

	-- Espera breve para que el jugador esté bien dentro de la zona
	task.wait(0.6)

	-- Re-verificar tras el wait (pudo haber cambiado de zona o ya hay diálogo activo)
	if dialogoActivo then 
		dialogosZonaVistos[nombreZona] = nil
		return 
	end
	if jugador:GetAttribute("ZonaActual") ~= nombreZona then 
		dialogosZonaVistos[nombreZona] = nil
		return 
	end

	ControladorDialogo.iniciar(dialogoID, {
		ocultarTechos = true,
	})
end

jugador:GetAttributeChangedSignal("ZonaActual"):Connect(onZonaChanged)


-- ═══════════════════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════════════════════

remotos.NivelListo.OnClientEvent:Connect(function(data)
	if data and data.error then return end

	-- print("[ControladorDialogo] Nivel cargado - buscando prompts de diálogo")

	task.wait(0.5)
	buscarYConectarPrompts()
end)

remotos.NivelDescargado.OnClientEvent:Connect(function()
	-- print("[ControladorDialogo] Nivel descargado - limpiando")

	if dialogoActivo then
		DialogoGUISystem:Close()
	end

	promptsConectados = {}
	nivelActual = nil
end)

print("[GrafosV3] ✅ ControladorDialogo activo y esperando niveles")
