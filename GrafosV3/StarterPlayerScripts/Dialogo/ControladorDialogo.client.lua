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
	DuracionTransicion = 0.3
}

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
	
	for _, modeloDialogo in ipairs(dialoguePrompts:GetChildren()) do
		if modeloDialogo:IsA("Model") or modeloDialogo:IsA("Folder") then
			local promptPart = modeloDialogo:FindFirstChild("PromptPart")
			if promptPart then
				local config = {
					id = modeloDialogo:GetAttribute("DialogoID") or modeloDialogo.Name,
					actionText = modeloDialogo:GetAttribute("ActionText") or "Hablar",
					objectText = modeloDialogo:GetAttribute("ObjectText") or modeloDialogo.Name,
					tecla = modeloDialogo:GetAttribute("Tecla") or Enum.KeyCode.E,
					distancia = modeloDialogo:GetAttribute("Distancia") or 20,
					holdDuration = modeloDialogo:GetAttribute("HoldDuration") or 0,
					unaVez = modeloDialogo:GetAttribute("UnaVez") or false,
					ocultarHUD = modeloDialogo:GetAttribute("OcultarHUD") ~= false
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
	
	if metadata.config and metadata.config.ocultarHUD then
		ocultarHUD()
	end
	
	DialogoGUISystem:OnClose(function()
		print("[ControladorDialogo] Diálogo cerrado:", dialogoID)
		mostrarHUD()
		
		if metadata.config and metadata.config.alCerrar then
			metadata.config.alCerrar(metadata)
		end
		
		dialogoActivo = false
	end)
	
	local exito = DialogoGUISystem:Play(dialogoID, metadata)
	
	if not exito then
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
