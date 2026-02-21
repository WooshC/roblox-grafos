-- MenuCameraSystem.client.lua


local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local UI = script.Parent
local StarterGui = game:GetService("StarterGui")

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

TrancisionFrame.Visible = true
TrancisionFrame.BackgroundTransparency = 0

local Cameras = Workspace:WaitForChild("CamarasMenu", 10)
if not Cameras then warn("⚠️ Carpeta CamarasMenu no encontrada en Workspace") return end

local MenuPrincipal    = UI:WaitForChild("MenuPrincipal")
local EscenariosFolder = UI:WaitForChild("Escenarios")

local CarpetaSonidos  = UI:FindFirstChild("Sonidos")
local SFXCambioEscena = CarpetaSonidos and CarpetaSonidos:FindFirstChild("CambiarEscena")
local SFXBotonPlay    = CarpetaSonidos and CarpetaSonidos:FindFirstChild("Play")
local SFXSeleccionar  = CarpetaSonidos and CarpetaSonidos:FindFirstChild("Seleccion")

local MusicaPorEscenario = {
	["Menu"]           = "MusicaMenu",
	["CamaraCreditos"] = "MusicaCreditos",
	["CamaraAjuste"]   = "MusicaMenu",
	["CamaraSelector"] = "MusicaMenu",
}
local MusicaActual = nil

-- ─── ESCENARIOS ──────────────────────────────────────────────

local EscenarioCreditos = EscenariosFolder:WaitForChild("MenuCreditos")
local EscenarioAjustes  = EscenariosFolder:WaitForChild("MenuAjustes")
local EscenarioSelector = EscenariosFolder:WaitForChild("SelectorNiveles")   -- Folder

-- ✅ Contenedor_2 es el único Frame hijo del Folder SelectorNiveles
local SelectorContenedor = EscenarioSelector:WaitForChild("Contenedor_2")

-- ─── CONTENIDO DE CADA ESCENARIO ─────────────────────────────

local ContenidoMenuPrincipal = {
	BotonPlay     = MenuPrincipal:WaitForChild("Play"),
	BotonAjustes  = MenuPrincipal:WaitForChild("Ajustes"),
	BotonCreditos = MenuPrincipal:WaitForChild("Creditos"),
	Frame         = MenuPrincipal:WaitForChild("Frame"),
	Logo          = MenuPrincipal:WaitForChild("Logo"),
}

local ContenidoEscenarioCreditos = {
	BotonCerrar        = EscenarioCreditos:WaitForChild("Close"),
	FrameTextoCreditos = EscenarioCreditos:WaitForChild("CreditosFrame"),
	TextoCreditos      = EscenarioCreditos:WaitForChild("CreditosFrame"):WaitForChild("TextCreditos"),
	TituloFrame        = EscenarioCreditos:WaitForChild("Tittle"),
	TituloText         = EscenarioCreditos:WaitForChild("Tittle"):WaitForChild("TittleText"),
}

local ContenidoEscenarioAjustes = {
	BotonCerrar  = EscenarioAjustes:WaitForChild("Close"),
	FrameAjustes = EscenarioAjustes:WaitForChild("AjustesFrame"),
	TituloFrame  = EscenarioAjustes:WaitForChild("Tittle"),
	TituloText   = EscenarioAjustes:WaitForChild("Tittle"):WaitForChild("TittleText"),
}

-- ✅ Selector: solo el Contenedor_2 y su BtnCerrar dentro de Header
local ContenidoSelectorNiveles = {
	BotonCerrar = SelectorContenedor:WaitForChild("Header"):WaitForChild("BtnCerrar"),
	Contenedor  = SelectorContenedor,
}

-- ─── CÁMARAS ─────────────────────────────────────────────────

local CamarasTotales = {
	MenuPrincipalCamara = Cameras:WaitForChild("Menu"),
	AjustesCamara       = Cameras:WaitForChild("CamaraAjuste"),
	CreditosCamara      = Cameras:WaitForChild("CamaraCreditos"),
	SelectorCamara      = Cameras:WaitForChild("CamaraSelector"),
}

-- ─── AJUSTES ─────────────────────────────────────────────────

local TiempoTransicion  = 1.5
local Cooldown          = 1.7
local BotonesBloqueados = false
local EnMenu            = true
local CameraAtual       = nil

-- ─── HELPERS ─────────────────────────────────────────────────

local function AnimarTransicion(aparecer, callback)
	local ini = aparecer and 1 or 0
	local fin = aparecer and 0 or 1
	TrancisionFrame.BackgroundTransparency = ini
	TrancisionFrame.Visible = true
	local tween = TweenService:Create(
		TrancisionFrame,
		TweenInfo.new(TiempoTransicion),
		{ BackgroundTransparency = fin }
	)
	tween:Play()
	tween.Completed:Connect(function()
		if callback then callback() end
	end)
end

local function CambiarVisibilidad(contenidoVisible, contenidoOcultar)
	for _, objeto in pairs(contenidoOcultar) do
		if objeto and objeto:IsA("GuiObject") then
			objeto.Visible = false
		end
	end
	for _, objeto in pairs(contenidoVisible) do
		if objeto and objeto:IsA("GuiObject") then
			objeto.Visible = true
			local padre = objeto.Parent
			while padre and padre ~= UI and padre:IsA("GuiObject") do
				padre.Visible = true
				padre = padre.Parent
			end
			for _, desc in pairs(objeto:GetDescendants()) do
				if desc:IsA("GuiObject") then
					desc.Visible = true
				end
			end
		end
	end
end

local function CambiarMusica(camaraDestino)
	if not CarpetaSonidos then return end
	local nombreNueva = MusicaPorEscenario[camaraDestino.Name]
	local nuevaMusica = nombreNueva and CarpetaSonidos:FindFirstChild(nombreNueva)
	if nuevaMusica == MusicaActual then return end
	if MusicaActual then MusicaActual:Stop() end
	if nuevaMusica then
		nuevaMusica.Looped = true
		nuevaMusica:Play()
	end
	MusicaActual = nuevaMusica
end

local function OcultarTodo()
	for _, objeto in pairs(UI:GetDescendants()) do
		if objeto:IsA("GuiObject") and objeto ~= TrancisionFrame and objeto.Parent ~= TrancisionFrame then
			objeto.Visible = false
		end
	end
end

local function ForzarCamaraScriptable()
	if EnMenu then
		workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	end
end

-- ─── CAMBIAR ESCENARIO ───────────────────────────────────────

local function CambiarEscenario(camaraDestino, contenidoVisible, contenidoOcultar)
	if BotonesBloqueados then return end
	BotonesBloqueados = true

	if SFXCambioEscena then SFXCambioEscena:Play() end

	if Players.LocalPlayer then
		Players.LocalPlayer:RequestStreamAroundAsync(camaraDestino.Position)
	end

	AnimarTransicion(true, function()
		ForzarCamaraScriptable()
		workspace.CurrentCamera.CFrame = camaraDestino.CFrame
		CambiarVisibilidad(contenidoVisible, contenidoOcultar)
		CameraAtual = camaraDestino
		CambiarMusica(camaraDestino)
		AnimarTransicion(false)
		task.wait(Cooldown)
		BotonesBloqueados = false
	end)
end

-- ─── GLOBAL: INICIAR JUEGO ───────────────────────────────────

function _G.StartGame()
	print("🎬 Iniciando transición al juego...")
	if BotonesBloqueados then return end
	BotonesBloqueados = true

	AnimarTransicion(true, function()
		EnMenu = false
		OcultarTodo()
		if MusicaActual then MusicaActual:Stop() end
		MusicaActual = nil

		local cam = workspace.CurrentCamera
		cam.CameraType = Enum.CameraType.Custom
		if Players.LocalPlayer.Character then
			cam.CameraSubject = Players.LocalPlayer.Character:FindFirstChild("Humanoid")
		end

		AnimarTransicion(false)
		BotonesBloqueados = false
	end)
end

-- ─── BOTONES MENÚ PRINCIPAL ──────────────────────────────────

ContenidoMenuPrincipal.BotonPlay.MouseButton1Click:Connect(function()
	print("🖱️ Click Play -> Selector")
	if SFXBotonPlay then SFXBotonPlay:Play() end
	CambiarEscenario(CamarasTotales.SelectorCamara, ContenidoSelectorNiveles, ContenidoMenuPrincipal)
end)

ContenidoMenuPrincipal.BotonCreditos.MouseButton1Click:Connect(function()
	print("🖱️ Click Creditos")
	CambiarEscenario(CamarasTotales.CreditosCamara, ContenidoEscenarioCreditos, ContenidoMenuPrincipal)
end)

ContenidoMenuPrincipal.BotonAjustes.MouseButton1Click:Connect(function()
	print("🖱️ Click Ajustes")
	CambiarEscenario(CamarasTotales.AjustesCamara, ContenidoEscenarioAjustes, ContenidoMenuPrincipal)
end)

-- ─── BOTONES CERRAR ──────────────────────────────────────────

ContenidoEscenarioCreditos.BotonCerrar.MouseButton1Click:Connect(function()
	print("🖱️ Cerrar Creditos")
	CambiarEscenario(CamarasTotales.MenuPrincipalCamara, ContenidoMenuPrincipal, ContenidoEscenarioCreditos)
end)

ContenidoEscenarioAjustes.BotonCerrar.MouseButton1Click:Connect(function()
	print("🖱️ Cerrar Ajustes")
	CambiarEscenario(CamarasTotales.MenuPrincipalCamara, ContenidoMenuPrincipal, ContenidoEscenarioAjustes)
end)

-- ✅ BtnCerrar del Selector — mismo objeto referenciado en ContenidoSelectorNiveles
ContenidoSelectorNiveles.BotonCerrar.MouseButton1Click:Connect(function()
	print("🖱️ Cerrar Selector de Niveles")
	CambiarEscenario(CamarasTotales.MenuPrincipalCamara, ContenidoMenuPrincipal, ContenidoSelectorNiveles)
end)

-- ─── EFECTOS HOVER ───────────────────────────────────────────

for _, objeto in pairs(UI:GetDescendants()) do
	if objeto:IsA("TextButton") then
		objeto.MouseEnter:Connect(function()
			if SFXSeleccionar then SFXSeleccionar:Play() end
		end)
	end
end

-- ─── INICIALIZACIÓN ──────────────────────────────────────────

local cam = workspace.CurrentCamera
cam.CameraType = Enum.CameraType.Scriptable
cam.CFrame     = CamarasTotales.MenuPrincipalCamara.CFrame
CameraAtual    = CamarasTotales.MenuPrincipalCamara

task.spawn(function()
	for i = 1, 60 do
		if EnMenu and CameraAtual then
			cam.CameraType = Enum.CameraType.Scriptable
			cam.CFrame     = CameraAtual.CFrame
		else
			break
		end
		task.wait()
	end
end)

if Players.LocalPlayer then
	Players.LocalPlayer:RequestStreamAroundAsync(CamarasTotales.MenuPrincipalCamara.Position)
end

Players.LocalPlayer.CharacterAdded:Connect(function()
	if EnMenu and CameraAtual then
		cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame     = CameraAtual.CFrame
	end
end)

-- Visibilidad inicial
CambiarVisibilidad(ContenidoMenuPrincipal, {})
for _, obj in pairs(ContenidoEscenarioCreditos) do if obj:IsA("GuiObject") then obj.Visible = false end end
for _, obj in pairs(ContenidoEscenarioAjustes) do if obj:IsA("GuiObject") then obj.Visible = false end end
SelectorContenedor.Visible = false   -- ✅ Ocultar el frame completo del selector

ConfigurarCoreGui(false)

task.defer(function()
	task.wait(0.5)
	AnimarTransicion(false)
	CambiarMusica(CamarasTotales.MenuPrincipalCamara)
end)

-- ─── EVENTO: Regresar al Selector desde Gameplay ─────────────

local ReplicatedStorage = game:GetService("ReplicatedStorage")
task.spawn(function()
	local Events = ReplicatedStorage:WaitForChild("Events", 10)
	if not Events then warn("❌ No se encontró carpeta Events") return end

	local Bindables = Events:WaitForChild("Bindables", 5)
	if not Bindables then warn("❌ No se encontró carpeta Bindables") return end

	local OpenMenuEvent = Bindables:FindFirstChild("OpenMenu")
	if not OpenMenuEvent then
		OpenMenuEvent = Instance.new("BindableEvent")
		OpenMenuEvent.Name   = "OpenMenu"
		OpenMenuEvent.Parent = Bindables
		print("✅ MenuCameraSystem: Evento OpenMenu creado")
	end

	OpenMenuEvent.Event:Connect(function()
		print("🎉 Regresando al Selector de Niveles...")
		EnMenu = true
		BotonesBloqueados = false
		ConfigurarCoreGui(false)

		local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui", 5)
		if playerGui then
			local guiExplorador = playerGui:FindFirstChild("GUIExplorador")
			if guiExplorador then
				guiExplorador.Enabled = false
				print("🔒 GUIExplorador ocultada al regresar al menú")
			end
		end

		local Camera = Workspace.CurrentCamera
		if Camera then Camera.CameraType = Enum.CameraType.Scriptable end

		CambiarEscenario(CamarasTotales.SelectorCamara, ContenidoSelectorNiveles, ContenidoMenuPrincipal)
	end)

	print("✅ MenuCameraSystem: Escuchando evento OpenMenu")
end)