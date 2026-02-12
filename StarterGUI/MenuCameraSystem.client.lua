-- MenuCameraSystem.client.lua
-- Script Local corregido para manejar la cámara del menú principal.
-- Pegar este código en el script local donde estaba el código original "Tomiasz".

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local UI = script.Parent
local StarterGui = game:GetService("StarterGui")

-- Función segura para configurar CoreGui (Chat, Mochila, etc)
local function ConfigurarCoreGui(habilitado)
	task.spawn(function()
		local exito = false
		while not exito do
			exito, _ = pcall(function()
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, habilitado)
			end)
			if not exito then task.wait(0.2) end
		end
	end)
end

local TrancisionFrame = UI:WaitForChild("FrameDeTransicion", 10)
if not TrancisionFrame then warn("⚠️ FrameDeTransicion no encontrado") return end

-- PANTALLA NEGRA INMEDIATA (Ocultar carga)
TrancisionFrame.Visible = true
TrancisionFrame.BackgroundTransparency = 0
-- Haremos FadeIn al final de la inicialización

local Cameras = Workspace:WaitForChild("CamarasMenu", 10)
if not Cameras then warn("⚠️ Carpeta CamarasMenu no encontrada en Workspace") return end

local MenuPrincipal = UI:WaitForChild("MenuPrincipal")
local EscenariosFolder = UI:WaitForChild("Escenarios")

local CarpetaSonidos = UI:FindFirstChild("Sonidos")
local SFXCambioEscena = CarpetaSonidos and CarpetaSonidos:FindFirstChild("CambiarEscena")
local SFXBotonPlay = CarpetaSonidos and CarpetaSonidos:FindFirstChild("Play")
local SFXSeleccionar = CarpetaSonidos and CarpetaSonidos:FindFirstChild("Seleccion")
local SFXClick = CarpetaSonidos and CarpetaSonidos:FindFirstChild("Click")

-- // ESCENARIOS DISPONIBLES // --

local EscenarioCreditos = EscenariosFolder:WaitForChild("MenuCreditos")
local EscenarioAjustes = EscenariosFolder:WaitForChild("MenuAjustes")
local EscenarioSelector = EscenariosFolder:WaitForChild("SelectorNiveles")

-- // CONTENIDO DE LOS ESCENARIOS // --

local ContenidoMenuPrincipal = {
	BotonPlay = MenuPrincipal:WaitForChild("Play"),
	BotonAjustes = MenuPrincipal:WaitForChild("Ajustes"),
	BotonCreditos = MenuPrincipal:WaitForChild("Creditos"),
	Frame = MenuPrincipal:WaitForChild("Frame"),
	Logo = MenuPrincipal:WaitForChild("Logo")
}

-- // ESCENARIOS AÑADIBLES // --

local ContenidoEscenarioCreditos = {
	BotonCerrar = EscenarioCreditos:WaitForChild("Close"),
	FrameTextoCreditos = EscenarioCreditos:WaitForChild("CreditosFrame"),
	TextoCreditos = EscenarioCreditos:WaitForChild("CreditosFrame"):WaitForChild("TextCreditos"),
	TituloFrame = EscenarioCreditos:WaitForChild("Tittle"),
	TituloText = EscenarioCreditos:WaitForChild("Tittle"):WaitForChild("TittleText")
}

local ContenidoEscenarioAjustes = {
	BotonCerrar = EscenarioAjustes:WaitForChild("Close"),
	FrameAjustes = EscenarioAjustes:WaitForChild("AjustesFrame"),
	TituloFrame = EscenarioAjustes:WaitForChild("Tittle"),
	TituloText = EscenarioAjustes:WaitForChild("Tittle"):WaitForChild("TittleText")
}

local ContenidoSelectorNiveles = {
	BotonCerrar = EscenarioSelector:WaitForChild("Close"),
	FrameSelector = EscenarioSelector:WaitForChild("AjustesFrame"), 
	ContenedorInfo = EscenarioSelector:WaitForChild("Contenedor"), -- AQUI AGREGAMOS EL CONTENEDOR NUEVO
	TituloFrame = EscenarioSelector:WaitForChild("Tittle"),
	TituloText = EscenarioSelector:WaitForChild("Tittle"):WaitForChild("TittleText")
}


-- // CAMARAS PARA CADA ESCENARIO // --

local CamarasTotales = {
	MenuPrincipalCamara = Cameras:WaitForChild("Menu"),
	AjustesCamara = Cameras:WaitForChild("CamaraAjuste"),
	CreditosCamara = Cameras:WaitForChild("CamaraCreditos"),
	SelectorCamara = Cameras:WaitForChild("CamaraSelector")
}

-- // AJUSTES PRINCIPALES // --

local TiempoTransicion = 1.5
local Cooldown = 1.7
local BotonesBloqueados = false
local EnMenu = true -- Variable de control para saber si estamos en menú

-- // SCRIPT // --


local function AnimarTransicion(aparecer, callback)
	local transparenciaInicial = aparecer and 1 or 0
	local transparenciaFinal = aparecer and 0 or 1

	TrancisionFrame.BackgroundTransparency = transparenciaInicial
	TrancisionFrame.Visible = true -- Asegurar visibilidad
	
	local tween = TweenService:Create(TrancisionFrame, TweenInfo.new(TiempoTransicion), {BackgroundTransparency = transparenciaFinal})
	tween:Play()
	
	tween.Completed:Connect(function()
		if callback then
			callback()
		end
		-- Si terminamos de desaparecer (fade out), ocultar frame si se quiere (opcional)
		if not aparecer then
			-- TrancisionFrame.Visible = false 
		end
	end)
end

local function CambiarVisibilidad(contenidoVisible, contenidoOcultar)
	for _, objeto in pairs(contenidoOcultar) do
		if objeto and objeto:IsA("GuiObject") then objeto.Visible = false end
	end

	for _, objeto in pairs(contenidoVisible) do
		if objeto and objeto:IsA("GuiObject") then objeto.Visible = true end
	end
end

local function OcultarTodo()
	for _, objeto in pairs(UI:GetDescendants()) do
		if objeto:IsA("GuiObject") and objeto ~= TrancisionFrame and objeto.Parent ~= TrancisionFrame then
			objeto.Visible = false
		end
	end
end

-- ============================================
-- FIX: FORZAR CÁMARA
-- ============================================
local function ForzarCamaraScriptable()
	if EnMenu then
		workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	end
end

local function CambiarEscenario(camaraDestino, contenidoVisible, contenidoOcultar)
	if BotonesBloqueados then return end
	BotonesBloqueados = true

	if SFXCambioEscena then SFXCambioEscena:Play() end

	-- PRE-CARGA DE ZONA (Fix StreamingEnabled)
	if Players.LocalPlayer then
		Players.LocalPlayer:RequestStreamAroundAsync(camaraDestino.Position)
	end

	AnimarTransicion(true, function()
		ForzarCamaraScriptable() -- Asegurar tipo antes de mover
		workspace.CurrentCamera.CFrame = camaraDestino.CFrame
		CambiarVisibilidad(contenidoVisible, contenidoOcultar)
		
		-- FORZAR VISIBILIDAD DE ELEMENTOS DEL SELECTOR
		if contenidoVisible == ContenidoSelectorNiveles then
			task.wait(0.1) -- Pequeño delay para asegurar que todo cargó
			if ContenidoSelectorNiveles.ContenedorInfo then 
				ContenidoSelectorNiveles.ContenedorInfo.Visible = true 
			end
			if ContenidoSelectorNiveles.FrameSelector then 
				ContenidoSelectorNiveles.FrameSelector.Visible = true 
			end
			-- Hacer visibles los hijos del Contenedor también
			if ContenidoSelectorNiveles.ContenedorInfo then
				for _, child in ipairs(ContenidoSelectorNiveles.ContenedorInfo:GetChildren()) do
					if child:IsA("GuiObject") then
						child.Visible = true
					end
				end
			end
		end
		
		AnimarTransicion(false)
		task.wait(Cooldown)
		BotonesBloqueados = false
	end)
end

-- ============================================
-- GLOBAL: INICIAR JUEGO (Libera la cámara)
-- ============================================
function _G.StartGame()
	print("🎬 Iniciando transición al juego...")
	if BotonesBloqueados then return end
	BotonesBloqueados = true
	
	AnimarTransicion(true, function()
		EnMenu = false -- Importante: Ya no forzamos la cámara en el respawn
		OcultarTodo()
		
		local cam = workspace.CurrentCamera
		cam.CameraType = Enum.CameraType.Custom
		if Players.LocalPlayer.Character then
			cam.CameraSubject = Players.LocalPlayer.Character:FindFirstChild("Humanoid")
		end
		
		AnimarTransicion(false)
		BotonesBloqueados = false
	end)
end

-- ============================================
-- GLOBAL: ABRIR SELECTOR (Con BindableEvent)
-- ============================================
local Bindables = game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Bindables")
local OpenMenuEvent = Bindables:FindFirstChild("OpenMenu") or Instance.new("BindableEvent", Bindables)
OpenMenuEvent.Name = "OpenMenu"

OpenMenuEvent.Event:Connect(function()
	print("🎞️ Regresando al Selector de Niveles (Evento Recibido)...")
	
	-- Restaurar estado menú
	EnMenu = true
	BotonesBloqueados = false -- Asegurar desbloqueo
	
	-- IMPORTANTE: Asegurar que UI de Roblox se oculte
	ConfigurarCoreGui(false)
	
	-- Forzar Cámara Scriptable
	ForzarCamaraScriptable()
	
	-- Asegurar que CurrentCamera esté en una posición inicial válida antes de tween
	-- (Opcional, pero ayuda si la cámara estaba muy lejos)
	
	-- Transición al Selector
	CambiarEscenario(CamarasTotales.SelectorCamara, ContenidoSelectorNiveles, ContenidoMenuPrincipal)
end)

ContenidoMenuPrincipal.BotonPlay.MouseButton1Click:Connect(function()
	print("🖱️ Click Play -> Ir a Selector de Niveles")
	CambiarEscenario(CamarasTotales.SelectorCamara, ContenidoSelectorNiveles, ContenidoMenuPrincipal)
end)



-- // DIRECCIONES DE LOS BOTONES DEL MENU PRINCIPAL PARA DETERMINADO MENU/ESCENARIOS // --

ContenidoMenuPrincipal.BotonCreditos.MouseButton1Click:Connect(function()
	print("🖱️ Click Creditos")
	CambiarEscenario(CamarasTotales.CreditosCamara, ContenidoEscenarioCreditos, ContenidoMenuPrincipal)
end)

ContenidoMenuPrincipal.BotonAjustes.MouseButton1Click:Connect(function()
	print("🖱️ Click Ajustes")
	CambiarEscenario(CamarasTotales.AjustesCamara, ContenidoEscenarioAjustes, ContenidoMenuPrincipal)
end)


-- // BOTONES DE CIERRE, PARA VOLVER AL MENU PRINCIPAL // --

ContenidoEscenarioCreditos.BotonCerrar.MouseButton1Click:Connect(function()
	print("🖱️ Cerrar Creditos")
	CambiarEscenario(CamarasTotales.MenuPrincipalCamara, ContenidoMenuPrincipal, ContenidoEscenarioCreditos)
end)

ContenidoEscenarioAjustes.BotonCerrar.MouseButton1Click:Connect(function()
	print("🖱️ Cerrar Ajustes")
	CambiarEscenario(CamarasTotales.MenuPrincipalCamara, ContenidoMenuPrincipal, ContenidoEscenarioAjustes)
end)

ContenidoSelectorNiveles.BotonCerrar.MouseButton1Click:Connect(function()
	print("🖱️ Cerrar Selector de Niveles")
	CambiarEscenario(CamarasTotales.MenuPrincipalCamara, ContenidoMenuPrincipal, ContenidoSelectorNiveles)
end)


-- // EFECTOS DE SONIDO // --
for _, objeto in pairs(UI:GetDescendants()) do
	if objeto:IsA("TextButton") then
		objeto.MouseEnter:Connect(function()
			if SFXSeleccionar then SFXSeleccionar:Play() end
		end)
	end
end

-- ============================================
-- INICIALIZACIÓN
-- ============================================

-- ============================================
-- INICIALIZACIÓN ROBUSTA (Para evitar parpadeo de cámara)
-- ============================================

-- 1. Forzar cámara INMEDIATAMENTE
local cam = workspace.CurrentCamera
cam.CameraType = Enum.CameraType.Scriptable
cam.CFrame = CamarasTotales.MenuPrincipalCamara.CFrame

-- 2. Mantener forzado durante un momento (combate el auto-spawn inicial)
task.spawn(function()
	for i = 1, 60 do -- 1 segundo aprox
		if EnMenu then
			cam.CameraType = Enum.CameraType.Scriptable
			cam.CFrame = CamarasTotales.MenuPrincipalCamara.CFrame
		else
			break
		end
		task.wait()
	end
end)

-- 3. Pre-Cargar zona
if Players.LocalPlayer then
	Players.LocalPlayer:RequestStreamAroundAsync(CamarasTotales.MenuPrincipalCamara.Position)
end

-- 4. Eventos de Personaje (Respawn en menú)
Players.LocalPlayer.CharacterAdded:Connect(function()
	if EnMenu then
		cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame = CamarasTotales.MenuPrincipalCamara.CFrame
	end
end)

-- 5. Visibilidad Inicial UI
CambiarVisibilidad(ContenidoMenuPrincipal, {})
for _, obj in pairs(ContenidoEscenarioCreditos) do if obj:IsA("GuiObject") then obj.Visible = false end end
for _, obj in pairs(ContenidoEscenarioAjustes) do if obj:IsA("GuiObject") then obj.Visible = false end end
for _, obj in pairs(ContenidoSelectorNiveles) do if obj:IsA("GuiObject") then obj.Visible = false end end

-- Ocultar UI de Roblox al inicio
ConfigurarCoreGui(false)

-- FADE IN PARA MOSTRAR MENÚ
task.defer(function()
	task.wait(0.5) -- Pequeña pausa para asegurar carga de modelos
	AnimarTransicion(false)
end)

-- ============================================
-- EVENTO: Regresar al Selector (Desde Gameplay)
-- ============================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
task.spawn(function()
	local Events = ReplicatedStorage:WaitForChild("Events", 10)
	if not Events then warn("❌ No se encontró carpeta Events") return end
	
	local Bindables = Events:WaitForChild("Bindables", 5)
	if not Bindables then warn("❌ No se encontró carpeta Bindables") return end
	
	local OpenMenuEvent = Bindables:FindFirstChild("OpenMenu")
	if not OpenMenuEvent then
		OpenMenuEvent = Instance.new("BindableEvent")
		OpenMenuEvent.Name = "OpenMenu"
		OpenMenuEvent.Parent = Bindables
		print("✅ MenuCameraSystem: Evento OpenMenu creado")
	end
	
	OpenMenuEvent.Event:Connect(function()
		print("🎉 Regresando al Selector de Niveles...")
		
		-- Restaurar estado menú
		EnMenu = true
		BotonesBloqueados = false
		
		-- Ocultar UI de Roblox
		ConfigurarCoreGui(false)
		
		-- Forzar cámara scriptable
		local Camera = Workspace.CurrentCamera
		if Camera then
			Camera.CameraType = Enum.CameraType.Scriptable
		end
		
		-- Transición al Selector
		CambiarEscenario(CamarasTotales.SelectorCamara, ContenidoSelectorNiveles, ContenidoMenuPrincipal)
	end)
	
	print("✅ MenuCameraSystem: Escuchando evento OpenMenu")
end)

