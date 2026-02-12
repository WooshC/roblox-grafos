-- MenuCameraSystem.client.lua
-- Script Local corregido para manejar la cámara del menú principal.
-- Pegar este código en el script local donde estaba el código original "Tomiasz".

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local UI = script.Parent
local TrancisionFrame = UI:WaitForChild("FrameDeTransicion", 10)
if not TrancisionFrame then warn("⚠️ FrameDeTransicion no encontrado en " .. UI.Name) return end

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


-- // CAMARAS PARA CADA ESCENARIO // --

local CamarasTotales = {
	MenuPrincipalCamara = Cameras:WaitForChild("Menu"),
	AjustesCamara = Cameras:WaitForChild("CamaraAjuste"),
	CreditosCamara = Cameras:WaitForChild("CamaraCreditos")
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
		AnimarTransicion(false)
		task.wait(Cooldown)
		BotonesBloqueados = false
	end)
end

ContenidoMenuPrincipal.BotonPlay.MouseButton1Click:Connect(function()
	if BotonesBloqueados then return end
	BotonesBloqueados = true
	if SFXBotonPlay then SFXBotonPlay:Play() end

	AnimarTransicion(true, function()
		OcultarTodo()
		EnMenu = false -- Ya no estamos en menú
		
		local camaraActual = workspace.CurrentCamera
		local jugador = Players.LocalPlayer
		
		-- Restaurar cámara de juego
		camaraActual.CameraType = Enum.CameraType.Custom
		if jugador.Character then
			camaraActual.CameraSubject = jugador.Character:FindFirstChild("Humanoid")
		end
		
		AnimarTransicion(false)
		task.wait(Cooldown)
		BotonesBloqueados = false
	end)
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

-- Esperar a que cargue el personaje
local player = Players.LocalPlayer
player.CharacterAdded:Connect(function()
	-- Si el personaje respawnea y sigo en el menú, forzar la cámara de nuevo
	if EnMenu then
		workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
		workspace.CurrentCamera.CFrame = CamarasTotales.MenuPrincipalCamara.CFrame
	end
end)

-- Configuración inicial
player:RequestStreamAroundAsync(CamarasTotales.MenuPrincipalCamara.Position)
workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
workspace.CurrentCamera.CFrame = CamarasTotales.MenuPrincipalCamara.CFrame

-- Visibilidad inicial
CambiarVisibilidad(ContenidoMenuPrincipal, {})
-- Asegurarse de ocultar los otros marcos explícitamente si CambiarVisibilidad no lo hizo (por estar vacio el segundo arg)
for _, obj in pairs(ContenidoEscenarioCreditos) do if obj:IsA("GuiObject") then obj.Visible = false end end
for _, obj in pairs(ContenidoEscenarioAjustes) do if obj:IsA("GuiObject") then obj.Visible = false end end

print("✅ MenuCameraSystem Corregido Cargado")
