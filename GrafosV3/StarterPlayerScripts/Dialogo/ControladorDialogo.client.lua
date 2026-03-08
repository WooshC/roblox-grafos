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
local LevelsConfig = require(RS:WaitForChild("Config"):WaitForChild("LevelsConfig"))

-- Referencia al ModuloMapa (se obtiene dinámicamente para evitar dependencia circular)
local function obtenerModuloMapa()
	local playerScripts = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerScripts")
	if not playerScripts then return nil end
	local HUD = playerScripts:FindFirstChild("HUD")
	if not HUD then return nil end
	local ModulosHUD = HUD:FindFirstChild("ModulosHUD")
	if not ModulosHUD then return nil end
	local exito, modulo = pcall(function()
		return require(ModulosHUD:FindFirstChild("ModuloMapa"))
	end)
	return exito and modulo or nil
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
local framesHUD = {}

-- Estado del jugador antes del diálogo
local estadoJugador = {
	humanoid = nil,
	camaraOriginal = nil,
	cframeOriginal = nil,
	walkSpeedOriginal = nil,
	jumpPowerOriginal = nil
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

	-- Guardar estado original (valores numéricos exactos)
	estadoJugador.humanoid = humanoid
	estadoJugador.walkSpeedOriginal = humanoid.WalkSpeed
	estadoJugador.jumpPowerOriginal = humanoid.JumpPower
	estadoJugador.jumpHeightOriginal = humanoid.JumpHeight

	-- Aplicar restricciones
	if restricciones.bloquearMovimiento then
		humanoid.WalkSpeed = 0
	end

	if restricciones.bloquearSalto then
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0   -- bloquea el salto en ambas APIs (legado y nueva)
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
	-- Solo restaurar si bloquearMovimiento() fue realmente llamado
	if estadoJugador.humanoid then
		local personaje = jugador.Character
		if personaje then
			local humanoid = personaje:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = estadoJugador.walkSpeedOriginal or 16
				humanoid.JumpPower = estadoJugador.jumpPowerOriginal or 50
				humanoid.JumpHeight = estadoJugador.jumpHeightOriginal or 7.2
			end
		end
		ServicioCamara.restaurar(0.5)
		print("[ControladorDialogo] Movimiento restaurado")
	end

	-- Limpiar estado siempre
	estadoJugador = {
		humanoid = nil,
		camaraOriginal = nil,
		cframeOriginal = nil,
		walkSpeedOriginal = nil,
		jumpPowerOriginal = nil,
		jumpHeightOriginal = nil
	}
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
-- MODO CLICK AÉREO
-- Activo cuando un diálogo oculta techos (cámara cenital) y permite conexiones.
-- Usa raycast desde la cámara en lugar de ClickDetectors, que no funcionan
-- cuando CameraType = Scriptable y la cámara está muy alta.
-- ═══════════════════════════════════════════════════════════════════════════════

local UIS = game:GetService("UserInputService")
local _clickAereoConexion = nil
local _primerNodoAereo    = nil

local function _recolectarSelectores()
	local lista = {}
	local nivel = workspace:FindFirstChild("NivelActual")
	if not nivel then return lista end
	local grafos = nivel:FindFirstChild("Grafos")
	if not grafos then return lista end
	for _, grafo in ipairs(grafos:GetChildren()) do
		local nodos = grafo:FindFirstChild("Nodos")
		if nodos then
			for _, nodo in ipairs(nodos:GetChildren()) do
				if nodo:IsA("Model") then
					local sel = nodo:FindFirstChild("Selector")
					if sel and sel:IsA("BasePart") then
						table.insert(lista, sel)
					end
				end
			end
		end
	end
	return lista
end

local function activarClickAereo()
	if _clickAereoConexion then return end

	local selectores = _recolectarSelectores()
	if #selectores == 0 then
		warn("[ControladorDialogo] Click aéreo: sin selectores")
		return
	end

	-- Suprimir ClickDetectors del servidor mientras el diálogo maneja los clics
	jugador:SetAttribute("MapaAbierto", true)

	local camara = workspace.CurrentCamera
	local conectarEvento = remotos:FindFirstChild("ConectarDesdeMapa")
	local mapaNodoEvento  = remotos:FindFirstChild("MapaClickNodo")

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = selectores

	_primerNodoAereo = nil

	_clickAereoConexion = UIS.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

		local mousePos = UIS:GetMouseLocation()
		local ray = camara:ViewportPointToRay(mousePos.X, mousePos.Y)
		local resultado = workspace:Raycast(ray.Origin, ray.Direction * 2000, params)

		if not (resultado and resultado.Instance) then
			_primerNodoAereo = nil
			return
		end

		local selector  = resultado.Instance
		local nodo      = selector.Parent
		if not (nodo and nodo:IsA("Model")) then return end
		local nombreNodo = nodo.Name

		if _primerNodoAereo == nil then
			_primerNodoAereo = nombreNodo
			if mapaNodoEvento then mapaNodoEvento:FireServer(nombreNodo) end
			-- Notificar EsperarAccion "seleccionarNodo" directamente (sin roundtrip al servidor)
			if DialogoGUISystem and DialogoGUISystem._esperandoAccion then
				DialogoGUISystem:onAccionJugador("seleccionarNodo", { nodo = nombreNodo })
			end
		elseif _primerNodoAereo == nombreNodo then
			_primerNodoAereo = nil  -- cancelar
		else
			local nodoA = _primerNodoAereo
			_primerNodoAereo = nil
			if conectarEvento then
				conectarEvento:FireServer(nodoA, nombreNodo)
			end
		end
	end)

	print("[ControladorDialogo] Click aéreo activado —", #selectores, "selectores")
end

local function desactivarClickAereo()
	if _clickAereoConexion then
		_clickAereoConexion:Disconnect()
		_clickAereoConexion = nil
	end
	_primerNodoAereo = nil
	-- Limpiar atributo sólo si el mapa real no está abierto
	local mapa = obtenerModuloMapa()
	if not (mapa and mapa.estaAbierto and mapa.estaAbierto()) then
		jugador:SetAttribute("MapaAbierto", nil)
	end
	print("[ControladorDialogo] Click aéreo desactivado")
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
		local ModuloMapa = obtenerModuloMapa()
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
		metadata.buttonHighlighter = Modulos.DialogoButtonHighlighter.new(obtenerHudGui())
	end

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

	-- Determinar si debemos restaurar techos al cerrar
	local debenRestaurarTechos = ocultarTechosConfig

	-- Activar click aéreo si la cámara está cenital Y el diálogo permite conexiones
	local permitirConexiones = restricciones.permitirConexiones
	if ocultarTechosConfig and permitirConexiones then
		activarClickAereo()
	end

	DialogoGUISystem:OnClose(function()
		print("[ControladorDialogo] Diálogo cerrado:", dialogoID)

		-- Restaurar botones del HUD destacados (por si quedaron activos)
		if metadata.buttonHighlighter then
			metadata.buttonHighlighter:restaurarTodo()
		end

		-- Desactivar click aéreo si estaba activo
		desactivarClickAereo()

		-- Restaurar movimiento
		desbloquearMovimiento()

		-- Restaurar techos si es necesario
		if debenRestaurarTechos then
			print("[ControladorDialogo] Restaurando techos...")
			GestorColisiones:restaurar()
		end

		mostrarHUD()

		if metadata.config and metadata.config.alCerrar then
			metadata.config.alCerrar(metadata)
		end

		dialogoActivo = false
	end)

	local exito = DialogoGUISystem:Play(dialogoID, metadata)

	if not exito then
		-- Si falla, restaurar todo
		desactivarClickAereo()
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
	if dialogoActivo then return end
	if jugador:GetAttribute("ZonaActual") ~= nombreZona then return end

	ControladorDialogo.iniciar(dialogoID, {
		ocultarTechos = true,
	})
end

jugador:GetAttributeChangedSignal("ZonaActual"):Connect(onZonaChanged)


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
