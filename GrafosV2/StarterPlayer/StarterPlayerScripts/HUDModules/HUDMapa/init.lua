-- init.lua
-- API pública de HUDMapa - orquestador principal

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Sub-módulos
local ZoneManager = require(script.Parent.ZoneManager)
local NodeManager = require(script.Parent.NodeManager)
local CameraManager = require(script.Parent.CameraManager)
local InputManager = require(script.Parent.InputManager)

-- Effects
local CameraEffects = require(ReplicatedStorage.Effects.CameraEffects)

local HUDMapa = {}

-- Estado
local isMapaAbierto = false
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Referencias UI
local parentHud = nil
local mapaFrame = nil
local btnMapa = nil
local btnCerrarMapa = nil

-- Configuración
local CONFIG = {
	alturaCamara = 80,
	velocidadTween = 0.4
}

-- Referencias externas
local HUDMisionPanel = nil
local mapaClickEvent = nil
local LevelsConfig = nil

-- ================================================================
-- INICIALIZACIÓN
-- ================================================================

function HUDMapa.init(hudRef, deps)
	parentHud = hudRef
	HUDMisionPanel = deps and deps.HUDMisionPanel

	-- UI
	mapaFrame = parentHud:FindFirstChild("PantallaMapaGrande", true)
	btnMapa = parentHud:FindFirstChild("BtnMapa", true)
	btnCerrarMapa = parentHud:FindFirstChild("BtnCerrarMapa", true)

	-- Config
	LevelsConfig = _G.LevelsConfig or require(ReplicatedStorage.Config.LevelsConfig)

	-- Evento remoto
	task.spawn(function()
		local Events = ReplicatedStorage:WaitForChild("Events", 10)
		if Events then
			local Remotes = Events:WaitForChild("Remotes", 10)
			if Remotes then
				mapaClickEvent = Remotes:WaitForChild("MapaClickNodo", 10)
			end
		end
	end)

	-- Inicializar managers
	CameraManager.init({ alturaCamara = CONFIG.alturaCamara })

	HUDMapa._conectarBotones()
	print("[HUDMapa] Inicializado")
end

function HUDMapa._conectarBotones()
	if btnMapa then
		btnMapa.MouseButton1Click:Connect(function()
			if isMapaAbierto then
				HUDMapa.cerrar()
			else
				HUDMapa.abrir()
			end
		end)
	end

	if btnCerrarMapa then
		btnCerrarMapa.MouseButton1Click:Connect(HUDMapa.cerrar)
	end
end

-- ================================================================
-- ABRIR / CERRAR (Con manejo completo del techo)
-- ================================================================

function HUDMapa.abrir()
	if isMapaAbierto then return end
	isMapaAbierto = true

	if btnMapa then
		btnMapa.Text = "❌ CERRAR MAPA"
	end

	mapaFrame.Visible = true

	-- Guardar cámara y cambiar a scriptable
	CameraManager.savePlayerCamera()

	-- Calcular y hacer tween a vista cenital
	local nivelActual = workspace:FindFirstChild("NivelActual")
	if not nivelActual then 
		warn("[HUDMapa] No se encontró NivelActual")
		return 
	end

	-- ================================================================
	-- CAPTURAR Y OCULTAR TECHO (Integración de MapManager antiguo)
	-- ================================================================
	CameraManager.captureRoof(nivelActual)
	CameraManager.hideRoof()

	local targetCFrame = CameraManager.calculateMapCFrame(nivelActual)
	if targetCFrame then
		CameraManager.tweenToMap(targetCFrame)
	end

	-- Inicializar managers
	local nivelID = player:GetAttribute("CurrentLevelID") or 0
	local nivelConfig = LevelsConfig[nivelID]

	NodeManager.init(nivelActual, nivelConfig)
	CameraManager.startFollowingPlayer()

	-- Zonas con delay para sincronización
	local datosMisiones = HUDMisionPanel and HUDMisionPanel.getMissionState and HUDMisionPanel.getMissionState()

	task.delay(0.3, function()
		ZoneManager.highlightAllZones(nivelActual, nivelID, datosMisiones, LevelsConfig)
	end)

	-- Input
	InputManager.init(nivelActual, HUDMapa._onNodeClicked)
	InputManager.startListening()

	print("[HUDMapa] Mapa abierto - Techo oculto")
end

function HUDMapa.cerrar()
	if not isMapaAbierto then return end
	isMapaAbierto = false

	if btnMapa then
		btnMapa.Text = "🗺️ MAPA"
	end

	mapaFrame.Visible = false

	-- Limpiar managers
	ZoneManager.cleanup()
	CameraManager.stopFollowing()
	InputManager.stopListening()
	NodeManager.clearSelection()
	NodeManager.resetAllSelectors()

	-- ================================================================
	-- RESTAURAR TECHO (Integración de MapManager antiguo)
	-- ================================================================
	CameraManager.showRoof()

	-- Restaurar cámara
	local original = CameraEffects.originalState
	if original then
		CameraManager.tweenToPlayer(original.CFrame, function()
			camera.CameraType = original.CameraType
			camera.CameraSubject = original.CameraSubject
		end)
	end

	-- Resetear caché del techo para el próximo nivel
	CameraManager.resetRoof()

	print("[HUDMapa] Mapa cerrado - Techo restaurado")
end

-- ================================================================
-- CALLBACKS
-- ================================================================

function HUDMapa._onNodeClicked(poste, selectorPart)
	local nombre = poste.Name
	local nivelID = player:GetAttribute("CurrentLevelID") or 0

	-- Toggle selección
	if NodeEffects.selectedNode == nombre then
		NodeManager.clearSelection()
	else
		-- Calcular adyacentes
		local adyacentes = {}
		local config = LevelsConfig[nivelID]
		if config and config.Adyacencias then
			adyacentes = config.Adyacencias[nombre] or {}
		end
		NodeManager.setSelection(nombre, adyacentes)
	end

	-- Notificar servidor
	if mapaClickEvent then
		pcall(function()
			mapaClickEvent:FireServer(selectorPart)
		end)
	end
end

-- ================================================================
-- API PÚBLICA ADICIONAL
-- ================================================================

function HUDMapa.actualizarZonas(datosMisiones)
	if not isMapaAbierto then return end

	ZoneManager.cleanup()
	local nivelActual = workspace:FindFirstChild("NivelActual")
	local nivelID = player:GetAttribute("CurrentLevelID") or 0

	if nivelActual then
		ZoneManager.highlightAllZones(nivelActual, nivelID, datosMisiones, LevelsConfig)
	end
end

function HUDMapa.isOpen()
	return isMapaAbierto
end

-- ================================================================
-- API DE TECHO (Para compatibilidad con código antiguo)
-- ================================================================

function HUDMapa.showRoof()
	CameraManager.showRoof()
end

function HUDMapa.hideRoof()
	CameraManager.hideRoof()
end

function HUDMapa.restoreRoof()
	CameraManager.showRoof()
end

function HUDMapa.resetRoofCache()
	CameraManager.resetRoof()
end

return HUDMapa