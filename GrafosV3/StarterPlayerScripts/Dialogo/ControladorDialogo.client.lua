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

-- Referencia al ModuloMapa (se obtiene dinámicamente para evitar dependencia circular)
local function obtenerModuloMapa()
	local StarterPlayerScripts = game:GetService("StarterPlayer").StarterPlayerScripts
	local HUD = StarterPlayerScripts:FindFirstChild("HUD")
	if HUD then
		local ModulosHUD = HUD:FindFirstChild("ModulosHUD")
		if ModulosHUD then
			local exito, modulo = pcall(function()
				return require(ModulosHUD:FindFirstChild("ModuloMapa"))
			end)
			if exito then return modulo end
		end
	end
	return nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- REFERENCIAS A SISTEMAS EXTERNOS
-- ═══════════════════════════════════════════════════════════════════════════════

local function obtenerHudGui()
	local gui = playerGui:FindFirstChild("GUIExploradorV2")
	if gui then return gui end
	
	for _, child in ipairs(playerGui:GetChildren()) do
		if child:IsA("ScreenGui") then
			if child.Name:match("HUD") or child.Name:match("Explorador") or child.Name:match("Gameplay") then
				return child
			end
		end
	end
	return nil
end

local hudGui = obtenerHudGui()
local eventos = RS:WaitForChild("EventosGrafosV3")
local remotos = eventos:WaitForChild("Remotos")

-- ═══════════════════════════════════════════════════════════════════════════════
-- CARGAR TODOS LOS MÓDULOS DE DIÁLOGO
-- ═══════════════════════════════════════════════════════════════════════════════

local Dialogo = script.Parent

-- Función segura para cargar módulos
local function cargarModulo(nombre)
	local modulo = Dialogo:FindFirstChild(nombre)
	if not modulo then
		warn("[ControladorDialogo] Módulo no encontrado:", nombre)
		return nil
	end
	
	local exito, resultado = pcall(function()
		return require(modulo)
	end)
	
	if exito then
		print("[ControladorDialogo] ✓ Módulo cargado:", nombre)
		return resultado
	else
		warn("[ControladorDialogo] ✗ Error cargando", nombre .. ":", resultado)
		return nil
	end
end

-- Cargar módulos en orden
local Modulos = {
	DialogoController = cargarModulo("DialogoController"),
	DialogoRenderer = cargarModulo("DialogoRenderer"),
	DialogoNarrator = cargarModulo("DialogoNarrator"),
	DialogoEvents = cargarModulo("DialogoEvents"),
	DialogoTTS = cargarModulo("DialogoTTS"),
	DialogoGUISystem = cargarModulo("DialogoGUISystem")
}

-- Verificar que todos los módulos se cargaron
local modulosOk = true
for nombre, modulo in pairs(Modulos) do
	if not modulo then
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
-- ESTADO DEL SISTEMA
-- ═══════════════════════════════════════════════════════════════════════════════

local dialogoActivo = false
local promptsConectados = {}
local nivelActual = nil
local framesHUD = {}

-- Estado del jugador antes del diálogo
local estadoJugador = {
	humanoid = nil,
	camaraOriginal = nil,
	cframeOriginal = nil,
	puedeSaltarOriginal = nil,
	puedeCorrerOriginal = nil
}

-- Configuración por defecto de restricciones
local RESTRICCIONES_DEFAULT = {
	bloquearMovimiento = true,
	bloquearSalto = true,
	bloquearCarrera = true,
	apuntarCamara = true,
	permitirConexiones = false  -- Si true, el jugador puede hacer conexiones durante el diálogo
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════════════════════

local CONFIG = {
	FramesAOcultar = {
		"PanelMisiones",
		"PanelPuntaje", 
		"PanelMapa",
		"BotonesAccion"
	},
	DuracionTransicion = 0.3,
	
	-- Configuración de cámara
	Camara = {
		Distancia = 8,           -- Distancia del personaje
		Altura = 3,              -- Altura sobre el personaje
		Suavizado = 0.1          -- Velocidad de transición (0-1)
	}
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- FUNCIONES DE CONTROL DEL JUGADOR
-- ═══════════════════════════════════════════════════════════════════════════════

---Bloquea el movimiento del jugador
local function bloquearMovimiento(restricciones)
	local personaje = jugador.Character
	if not personaje then return end
	
	local humanoid = personaje:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	-- Guardar estado original
	estadoJugador.humanoid = humanoid
	estadoJugador.puedeSaltarOriginal = humanoid.JumpPower > 0
	estadoJugador.puedeCorrerOriginal = humanoid.WalkSpeed > 10
	
	-- Aplicar restricciones
	if restricciones.bloquearMovimiento then
		humanoid.WalkSpeed = 0
	end
	
	if restricciones.bloquearSalto then
		humanoid.JumpPower = 0
	end
	
	-- Solo bloquear la cámara (Scriptable) si está habilitado, pero NO moverla
	-- El movimiento de cámara se hace mediante ServicioCamara.moverTopDown() en eventos específicos
	if restricciones.apuntarCamara then
		ServicioCamara.bloquear()
	end
	
	print("[ControladorDialogo] Movimiento bloqueado")
end

---Restaura el movimiento del jugador
local function desbloquearMovimiento()
	local personaje = jugador.Character
	if not personaje then return end
	
	local humanoid = personaje:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Restaurar velocidad
		if estadoJugador.puedeCorrerOriginal then
			humanoid.WalkSpeed = 16
		else
			humanoid.WalkSpeed = 10
		end
		
		-- Restaurar salto
		if estadoJugador.puedeSaltarOriginal then
			humanoid.JumpPower = 50
		else
			humanoid.JumpPower = 0
		end
	end
	
	-- Restaurar cámara usando ServicioCamara
	ServicioCamara.restaurar(0.5)
	
	-- Limpiar estado
	estadoJugador = {
		humanoid = nil,
		camaraOriginal = nil,
		cframeOriginal = nil,
		puedeSaltarOriginal = nil,
		puedeCorrerOriginal = nil
	}
	
	print("[ControladorDialogo] Movimiento restaurado")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- FUNCIONES DE GESTIÓN DEL HUD
-- ═══════════════════════════════════════════════════════════════════════════════

-- Esta función ya no se usa (ahora se desactiva todo el ScreenGui)
-- Se mantiene por compatibilidad
local function obtenerFramesHUD()
	local hud = obtenerHudGui()
	if not hud then return end
	
	for _, nombreFrame in ipairs(CONFIG.FramesAOcultar) do
		local frame = hud:FindFirstChild(nombreFrame, true)
		if frame then
			framesHUD[nombreFrame] = frame
		end
	end
end

local function ocultarHUD()
	-- Buscar HUD dinámicamente
	local hud = obtenerHudGui()
	
	-- Desactivar todo el ScreenGui del HUD
	if hud then
		hud:SetAttribute("EnabledAntesDialogo", hud.Enabled)
		hud.Enabled = false
		print("[ControladorDialogo] HUD ocultado:", hud.Name)
	else
		warn("[ControladorDialogo] No se encontró HUD para ocultar")
	end
end

local function mostrarHUD()
	-- Buscar HUD dinámicamente
	local hud = obtenerHudGui()
	
	-- Restaurar el ScreenGui del HUD
	if hud then
		local eraEnabled = hud:GetAttribute("EnabledAntesDialogo")
		if eraEnabled ~= false then
			hud.Enabled = true
		end
		print("[ControladorDialogo] HUD mostrado:", hud.Name)
	else
		-- Fallback: restaurar cualquier ScreenGui que ocultamos
		for _, gui in ipairs(playerGui:GetChildren()) do
			if gui:IsA("ScreenGui") and gui:GetAttribute("EnabledAntesDialogo") ~= nil then
				gui.Enabled = gui:GetAttribute("EnabledAntesDialogo")
				print("[ControladorDialogo] HUD restaurado (fallback):", gui.Name)
			end
		end
	end
end

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
		print("[ControladorDialogo] No hay DialoguePrompts en este nivel")
		return
	end
	
	print("[ControladorDialogo] Buscando prompts en:", dialoguePrompts.Name)
	print("[ControladorDialogo] Hijos encontrados en DialoguePrompts:", #dialoguePrompts:GetChildren())
	
	for _, modeloDialogo in ipairs(dialoguePrompts:GetChildren()) do
		print("[ControladorDialogo] Revisando:", modeloDialogo.Name, "Tipo:", modeloDialogo.ClassName)
		
		if modeloDialogo:IsA("Model") or modeloDialogo:IsA("Folder") then
			local promptPart = modeloDialogo:FindFirstChild("PromptPart")
			if promptPart then
				print("[ControladorDialogo] ✓ PromptPart encontrado en:", modeloDialogo.Name)
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
	-- PASO 0: CERRAR MAPA SI ESTÁ ABIERTO (evita bugs de cámara)
	-- ═══════════════════════════════════════════════════════════════════════════════
	local ModuloMapa = obtenerModuloMapa()
	if ModuloMapa and ModuloMapa.estaAbierto and ModuloMapa.estaAbierto() then
		print("[ControladorDialogo] Cerrando mapa antes de iniciar diálogo...")
		ModuloMapa.cerrar()
		task.wait(0.1) -- Pequeña espera para que termine el cierre
	end
	
	dialogoActivo = true
	
	-- Obtener datos del diálogo para leer Configuracion
	local datosDialogo = nil
	if DialogoGUISystem then
		datosDialogo = DialogoGUISystem:LoadDialogue(dialogoID)
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
	
	-- NOTA: La cámara NO se mueve aquí automáticamente.
	-- El movimiento de cámara se hace mediante Eventos en las líneas de diálogo específicas.
	
	-- Bloquear movimiento si está configurado
	if restricciones.bloquearMovimiento or restricciones.bloquearSalto or restricciones.apuntarCamara then
		bloquearMovimiento(restricciones)
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
		ocultarHUD()
	end
	
	DialogoGUISystem:OnClose(function()
		print("[ControladorDialogo] Diálogo cerrado:", dialogoID)
		
		-- Restaurar movimiento
		desbloquearMovimiento()
		
		mostrarHUD()
		
		if metadata.config and metadata.config.alCerrar then
			metadata.config.alCerrar(metadata)
		end
		
		dialogoActivo = false
	end)
	
	local exito = DialogoGUISystem:Play(dialogoID, metadata)
	
	if not exito then
		-- Si falla, restaurar todo
		desbloquearMovimiento()
		mostrarHUD()
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
--     promptPart = BasePart,  -- Parte para enfocar la cámara
--     alIniciar = function,   -- Callback al iniciar
--     alCerrar = function,    -- Callback al cerrar
--     restricciones = {       -- Sobreescribe la configuración del archivo
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
			ocultarHUD = opciones.ocultarHUD
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

---Mueve la cámara a un punto de enfoque (TOP-DOWN)
-- Uso desde eventos de diálogo: _G.ControladorDialogo.moverCamara("Nodo1_z1")
-- @param enfoque string (nombre nodo), Vector3, BasePart, o Model
-- @param duracion number - Opcional, duración de la transición (default: 0.8)
function ControladorDialogo.moverCamara(enfoque, duracion)
	return ServicioCamara.moverTopDown(enfoque, 13, duracion)
end

---Restaura la cámara a su estado original
-- Uso desde eventos de diálogo: _G.ControladorDialogo.restaurarCamara()
function ControladorDialogo.restaurarCamara()
	ServicioCamara.restaurar(0.5)
end

---Obtiene el servicio de cámara para uso avanzado
function ControladorDialogo.obtenerServicioCamara()
	return ServicioCamara
end

_G.ControladorDialogo = ControladorDialogo

-- ═══════════════════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════════════════════

obtenerFramesHUD()

remotos.NivelListo.OnClientEvent:Connect(function(data)
	if data and data.error then return end
	
	print("[ControladorDialogo] Nivel cargado - buscando prompts de diálogo")
	
	task.wait(0.5)
	buscarYConectarPrompts()
end)

remotos.NivelDescargado.OnClientEvent:Connect(function()
	print("[ControladorDialogo] Nivel descargado - limpiando")
	
	if dialogoActivo then
		DialogoGUISystem:Close()
	end
	
	promptsConectados = {}
	nivelActual = nil
end)

print("[GrafosV3] ✅ ControladorDialogo activo y esperando niveles")
