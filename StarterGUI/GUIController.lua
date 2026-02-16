-- ============================================
-- UNIFIED GUI CONTROLLER (LOGIC ONLY)
-- ============================================
-- Este script asume que la GUI "UnifiedGUI" ya existe en StarterGui/PlayerGui.
-- Se encarga de dar funcionalidad a los botones y gestionar los modos.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))
local Remotes = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes")

-- ==========================================
-- 1. REFERENCIAS A LA GUI EXISTENTE
-- ==========================================
local PlayerGui = player:WaitForChild("PlayerGui")
local gui = PlayerGui:WaitForChild("UnifiedGUI")

-- Mapeamos los componentes (Asegúrate que los nombres coincidan con la versión generada)
local References = {
	TopBar = gui:WaitForChild("TopBar"),
	ActionPanel = gui:FindFirstChild("ActionPanel") or gui:FindFirstChild("MainButtonsBar"), -- Soporte V4/V3
	MatrixPanel = gui:WaitForChild("MatrixPanel"),
	AnalysisOverlay = gui:WaitForChild("AnalysisOverlay"),
	MinimapContainer = gui:WaitForChild("MinimapContainer"),
	ModeSelector = gui:WaitForChild("ModeSelector"),
}

-- Botones de Acción (ActionPanel)
local Buttons = {
	Algo = References.ActionPanel:FindFirstChild("BtnAlgo"),
	Misiones = References.ActionPanel:FindFirstChild("BtnMisiones"),
	Check = References.ActionPanel:FindFirstChild("BtnCheck") or References.ActionPanel:FindFirstChild("BtnFinalizar"), -- Alias V4/V3
	Reset = References.ActionPanel:FindFirstChild("BtnReset") -- Si existe
}

-- Botones de Modo (ModeSelector)
local ModeBtns = {
	Visual = References.ModeSelector:FindFirstChild("Visual") or References.ModeSelector:FindFirstChild("VisualBtn"),
	Matrix = References.ModeSelector:FindFirstChild("Matriz") or References.ModeSelector:FindFirstChild("MatrizBtn"),
	Analysis = References.ModeSelector:FindFirstChild("Analisis") or References.ModeSelector:FindFirstChild("AnálisisBtn"),
}

print("✅ GUI Controller: Elementos mapeados correctamente")

-- ==========================================
-- 2. GESTOR DE MODOS
-- ==========================================
local ModeManager = {}

function ModeManager:SwitchMode(modeName)
	-- 1. Ocultar todo primero
	References.MinimapContainer.Visible = false
	References.MatrixPanel.Visible = false
	References.AnalysisOverlay.Visible = false
	
	-- 2. Mostrar según modo
	if modeName == "VISUAL" then
		References.MinimapContainer.Visible = true
		if Buttons.Misiones then Buttons.Misiones.Visible = true end
		print("👉 Modo cambiado a: VISUAL")
		
	elseif modeName == "MATRIZ" then
		References.MatrixPanel.Visible = true
		if Buttons.Misiones then Buttons.Misiones.Visible = false end
		print("👉 Modo cambiado a: MATRIZ")
		
	elseif modeName == "ANALISIS" then
		References.AnalysisOverlay.Visible = true
		-- En análisis ocultamos botones de acción normales si se desea
		print("👉 Modo cambiado a: ANALISIS")
	end
end

-- ==========================================
-- 3. CONEXIONES DE EVENTOS (CLICK)
-- ==========================================

-- Clicks en Selector de Modos
if ModeBtns.Visual then
	ModeBtns.Visual.MouseButton1Click:Connect(function() ModeManager:SwitchMode("VISUAL") end)
end
if ModeBtns.Matrix then
	ModeBtns.Matrix.MouseButton1Click:Connect(function() ModeManager:SwitchMode("MATRIZ") end)
end
if ModeBtns.Analysis then
	ModeBtns.Analysis.MouseButton1Click:Connect(function() ModeManager:SwitchMode("ANALISIS") end)
end

-- Clicks en Acciones
if Buttons.Algo then
	Buttons.Algo.MouseButton1Click:Connect(function()
		print("⚡ Ejecutando Algoritmo...")
		local levelID = player:GetAttribute("CurrentLevelID")
		local config = LevelsConfig[levelID]
		if config then
			local remote = Remotes:FindFirstChild("EjecutarAlgoritmo")
			if remote then
				remote:FireServer(config.Algoritmo, config.NodoInicio, config.NodoFin, levelID)
				ModeManager:SwitchMode("ANALISIS") -- Auto-cambiar a análisis al ejecutar
			end
		end
	end)
end

if Buttons.Misiones then
	Buttons.Misiones.MouseButton1Click:Connect(function()
		print("� Toggle Misiones")
		local remote = Remotes:FindFirstChild("ToggleMissions")
		if remote then remote:FireServer() end
	end)
end

-- ==========================================
-- 4. VISIBILIDAD POR NIVEL (Level Manager)
-- ==========================================
local function CheckLevelVisibility()
	local levelID = player:GetAttribute("CurrentLevelID")
	
	if levelID and levelID ~= -1 then
		gui.Enabled = true
		ModeManager:SwitchMode("VISUAL") -- Reset a visual al entrar
		print("✅ Nivel " .. levelID .. " activo. GUI Visible.")
	else
		gui.Enabled = false
		print("⛔ Sin nivel. GUI Oculta.")
	end
end

player:GetAttributeChangedSignal("CurrentLevelID"):Connect(CheckLevelVisibility)

-- Inicialización
task.wait(1) -- Esperar carga inicial
CheckLevelVisibility()
print("✅ UnifiedGUI Controller Iniciado")