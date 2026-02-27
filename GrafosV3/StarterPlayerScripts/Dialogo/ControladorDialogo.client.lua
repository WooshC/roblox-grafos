-- StarterPlayerScripts/Dialogo/ControladorDialogo.client.lua
-- Orquestador del sistema de diálogos - integra dialogos con el HUD

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local jugador = Players.LocalPlayer
local playerGui = jugador:WaitForChild("PlayerGui")

print("[GrafosV3] === ControladorDialogo Iniciando ===")

-- ═══════════════════════════════════════════════════════════════════════════════
-- REFERENCIAS A SISTEMAS EXTERNOS
-- ═══════════════════════════════════════════════════════════════════════════════

local hudGui = playerGui:WaitForChild("GUIExploradorV2", 30)
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
local function bloquearMovimiento(restricciones, promptPart)
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
	
	-- Controlar cámara si está habilitado
	if restricciones.apuntarCamara and promptPart then
		local camara = workspace.CurrentCamera
		estadoJugador.camaraOriginal = camara.CameraType
		estadoJugador.cframeOriginal = camara.CFrame
		
		-- Crear CFrame que mire al prompt desde una posición cercana
		local posicionJugador = personaje:WaitForChild("HumanoidRootPart").Position
		local posicionPrompt = promptPart.Position
		
		-- Calcular posición de la cámara (detrás y arriba del jugador, mirando al prompt)
		local direccion = (posicionPrompt - posicionJugador).Unit
		local posicionCamara = posicionJugador - (direccion * CONFIG.Camara.Distancia) + Vector3.new(0, CONFIG.Camara.Altura, 0)
		local nuevoCFrame = CFrame.lookAt(posicionCamara, posicionPrompt)
		
		-- Aplicar suavizado a la cámara
		camara.CameraType = Enum.CameraType.Scriptable
		
		-- Animar la transición
		task.spawn(function()
			local duracion = 0.5
			local inicio = tick()
			local cframeInicial = camara.CFrame
			
			while tick() - inicio < duracion do
				local alpha = (tick() - inicio) / duracion
				alpha = math.sin(alpha * math.pi / 2) -- Easing suave
				camara.CFrame = cframeInicial:Lerp(nuevoCFrame, alpha)
				task.wait(0.016)
			end
			
			camara.CFrame = nuevoCFrame
		end)
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
			humanoid.WalkSpeed = 16  -- Velocidad default
		else
			humanoid.WalkSpeed = 10
		end
		
		-- Restaurar salto
		if estadoJugador.puedeSaltarOriginal then
			humanoid.JumpPower = 50  -- JumpPower default
		else
			humanoid.JumpPower = 0
		end
	end
	
	-- Restaurar cámara
	if estadoJugador.camaraOriginal then
		local camara = workspace.CurrentCamera
		
		-- Animar regreso
		task.spawn(function()
			local duracion = 0.3
			local inicio = tick()
			local cframeInicial = camara.CFrame
			local cframeFinal = estadoJugador.cframeOriginal
			
			while tick() - inicio < duracion do
				local alpha = (tick() - inicio) / duracion
				camara.CFrame = cframeInicial:Lerp(cframeFinal, alpha)
				task.wait(0.016)
			end
			
			camara.CFrame = cframeFinal
			-- Solo restaurar CameraType si teníamos uno guardado
			if estadoJugador.camaraOriginal then
				camara.CameraType = estadoJugador.camaraOriginal
			else
				camara.CameraType = Enum.CameraType.Custom
			end
		end)
	end
	
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

local function obtenerFramesHUD()
	if not hudGui then return end
	
	for _, nombreFrame in ipairs(CONFIG.FramesAOcultar) do
		local frame = hudGui:FindFirstChild(nombreFrame, true)
		if frame then
			framesHUD[nombreFrame] = frame
		end
	end
end

local function ocultarHUD()
	for nombre, frame in pairs(framesHUD) do
		if frame and frame:IsA("GuiObject") then
			frame:SetAttribute("VisibleAntesDialogo", frame.Visible)
			
			local tween = game:GetService("TweenService"):Create(
				frame,
				TweenInfo.new(CONFIG.DuracionTransicion, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{BackgroundTransparency = 1}
			)
			tween:Play()
			
			task.delay(CONFIG.DuracionTransicion, function()
				frame.Visible = false
			end)
		end
	end
end

local function mostrarHUD()
	for nombre, frame in pairs(framesHUD) do
		if frame and frame:IsA("GuiObject") then
			local eraVisible = frame:GetAttribute("VisibleAntesDialogo")
			if eraVisible ~= false then
				frame.Visible = true
				
				local tween = game:GetService("TweenService"):Create(
					frame,
					TweenInfo.new(CONFIG.DuracionTransicion, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{BackgroundTransparency = 0}
				)
				tween:Play()
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
	
	dialogoActivo = true
	
	-- Obtener restricciones del diálogo o usar defaults
	local restricciones = RESTRICCIONES_DEFAULT
	if metadata.config and metadata.config.restricciones then
		for key, value in pairs(metadata.config.restricciones) do
			restricciones[key] = value
		end
	end
	
	-- Guardar restricciones en metadata para que otros sistemas las consulten
	metadata.restricciones = restricciones
	
	-- Bloquear movimiento si está configurado
	if restricciones.bloquearMovimiento or restricciones.bloquearSalto or restricciones.apuntarCamara then
		bloquearMovimiento(restricciones, metadata.promptPart)
	end
	
	if metadata.config and metadata.config.ocultarHUD then
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

function ControladorDialogo.iniciar(dialogoID, metadata)
	return iniciarDialogo(dialogoID, metadata or {})
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
