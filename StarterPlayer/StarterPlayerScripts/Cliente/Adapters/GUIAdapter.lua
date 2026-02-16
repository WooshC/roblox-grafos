-- StarterPlayer/StarterPlayerScripts/Cliente/Adapters/GUIAdapter.lua
-- Adaptador para UnifiedGUI - Proporciona API estandarizada para todos los servicios

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GUIAdapter = {}
GUIAdapter.__index = GUIAdapter

-- ============================================
-- OBTENER REFERENCIAS
-- ============================================

local screenGui = playerGui:WaitForChild("UnifiedGUI")
local topBar = screenGui:FindFirstChild("TopBar")
local mainButtonsBar = screenGui:FindFirstChild("MainButtonsBar")
local analysisOverlay = screenGui:FindFirstChild("AnalysisOverlay")
local matrixPanel = screenGui:FindFirstChild("MatrixPanel")
local minimapContainer = screenGui:FindFirstChild("MinimapContainer")
local modeSelector = screenGui:FindFirstChild("ModeSelector")

print("✅ GUIAdapter: Referencias de UnifiedGUI cargadas")

-- ============================================
-- REFERENCIAS A BOTONES
-- ============================================

function GUIAdapter:getButton(btnName)
    -- Botones principales en MainButtonsBar
    if mainButtonsBar then
        local btn = mainButtonsBar:FindFirstChild(btnName)
        if btn then return btn end
    end
    
    -- Fallback: Búsqueda recursiva
    local btn = screenGui:FindFirstChild(btnName, true)
    return btn
end

function GUIAdapter:getLabel(lblName)
    -- Labels en TopBar
    if topBar then
        local lbl = topBar:FindFirstChild(lblName)
        if lbl then return lbl end
    end
    
    -- Fallback
    local lbl = screenGui:FindFirstChild(lblName, true)
    return lbl
end

-- ============================================
-- GESTIÓN DE VISIBILIDAD GLOBAL
-- ============================================

function GUIAdapter:show()
    screenGui.Enabled = true
    print("👁️ GUI VISIBLE")
end

function GUIAdapter:hide()
    screenGui.Enabled = false
    print("🙈 GUI INVISIBLE")
end

function GUIAdapter:isVisible()
    return screenGui.Enabled
end

-- ============================================
-- MODOS GUI
-- ============================================

function GUIAdapter:showVisualMode()
    print("🎨 [GUIAdapter] Cambiando a MODO VISUAL")
    
    -- Mostrar componentes VISUAL
    if mainButtonsBar then mainButtonsBar.Visible = true end
    if topBar then topBar.Visible = true end
    
    -- Ocultar componentes de otros modos
    if analysisOverlay then analysisOverlay.Visible = false end
    if matrixPanel then matrixPanel.Visible = false end
    
    -- Mostrar minimapa
    if minimapContainer then minimapContainer.Visible = true end
end

function GUIAdapter:showMatrixMode()
    print("📊 [GUIAdapter] Cambiando a MODO MATEMÁTICO")
    
    -- Mostrar componentes MATRIX
    if mainButtonsBar then mainButtonsBar.Visible = true end
    if topBar then topBar.Visible = true end
    if matrixPanel then matrixPanel.Visible = true end
    
    -- Ocultar componentes de otros modos
    if analysisOverlay then analysisOverlay.Visible = false end
    
    -- Mostrar minimapa
    if minimapContainer then minimapContainer.Visible = true end
end

function GUIAdapter:showAnalysisMode()
    print("🧠 [GUIAdapter] Cambiando a MODO ANÁLISIS")
    
    -- Ocultar botones principales
    if mainButtonsBar then mainButtonsBar.Visible = false end
    if modeSelector then modeSelector.Visible = false end
    
    -- Mostrar overlay de análisis
    if analysisOverlay then 
        analysisOverlay.Visible = true
    end
    
    -- Ocultar otros panels
    if matrixPanel then matrixPanel.Visible = false end
    
    -- Minimapa pequeño dentro del análisis
    if minimapContainer then minimapContainer.Visible = true end
end

-- ============================================
-- ACTUALIZACIÓN DE PUNTAJE
-- ============================================

function GUIAdapter:updateScore(puntos, estrellas, dinero)
    local lblPuntaje = self:getLabel("PuntajeLabel") or self:getLabel("Puntos")
    local lblEstrellas = self:getLabel("EstrellasLabel") or self:getLabel("Estrellas")
    local lblDinero = self:getLabel("DineroLabel") or self:getLabel("Money")
    
    if lblPuntaje then
        lblPuntaje.Text = "Pts: " .. puntos
    end
    
    if lblEstrellas then
        local estrellasStr = ""
        for i = 1, 3 do
            estrellasStr = estrellasStr .. (i <= estrellas and "⭐" or "☆")
        end
        lblEstrellas.Text = estrellasStr
    end
    
    if lblDinero then
        lblDinero.Text = "$" .. dinero
    end
end

-- ============================================
-- CONTROL DE BOTONES ESPECÍFICOS
-- ============================================

function GUIAdapter:showButtonFinalizar()
    local btn = self:getButton("BtnFinalizar")
    if btn then 
        btn.Visible = true
        btn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        print("✅ Botón Finalizar mostrado")
    end
end

function GUIAdapter:hideButtonFinalizar()
    local btn = self:getButton("BtnFinalizar")
    if btn then 
        btn.Visible = false
        print("✅ Botón Finalizar ocultado")
    end
end

function GUIAdapter:setAlgoButtonText(texto)
    local btn = self:getButton("BtnAlgo")
    if btn then
        btn.Text = texto
    end
end

-- ============================================
-- MATRIZ PANEL (MODO MATEMÁTICO)
-- ============================================

function GUIAdapter:showMatrixPanel(visible)
    if matrixPanel then
        matrixPanel.Visible = visible
    end
end

function GUIAdapter:updateMatrixCell(row, col, value)
    -- Buscar celda en la matriz
    if matrixPanel then
        local cell = matrixPanel:FindFirstChild("Cell_" .. row .. "_" .. col)
        if cell then
            cell.Text = tostring(value)
            
            -- Animar cambio de color
            if value > 0 then
                cell.BackgroundColor3 = Color3.fromRGB(46, 204, 113)  -- Verde
            else
                cell.BackgroundColor3 = Color3.fromRGB(50, 50, 50)    -- Gris
            end
        end
    end
end

function GUIAdapter:highlightMatrixRow(row, highlight)
    if matrixPanel then
        for i = 1, 20 do  -- Asumir máx 20 columnas
            local cell = matrixPanel:FindFirstChild("Cell_" .. row .. "_" .. i)
            if cell then
                if highlight then
                    cell.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
                    cell.BackgroundTransparency = 0.3
                else
                    cell.BackgroundTransparency = 0
                end
            end
        end
    end
end

-- ============================================
-- ANALYSIS OVERLAY (MODO ANÁLISIS)
-- ============================================

function GUIAdapter:updateAnalysisPanel(data)
    -- data = {
    --   algorithmType = "BFS",
    --   currentStep = 5,
    --   queue = {"A", "B", "C"},
    --   visited = {"A", "B"},
    --   distances = {A=0, B=1, C=2}
    -- }
    
    if analysisOverlay then
        local titleLbl = analysisOverlay:FindFirstChild("AlgorithmTitle")
        if titleLbl then
            titleLbl.Text = "🧠 " .. (data.algorithmType or "ALGORITMO")
        end
        
        local queueLbl = analysisOverlay:FindFirstChild("QueueLabel")
        if queueLbl then
            queueLbl.Text = "Cola: " .. table.concat(data.queue or {}, ", ")
        end
        
        local visitedLbl = analysisOverlay:FindFirstChild("VisitedLabel")
        if visitedLbl then
            visitedLbl.Text = "Visitados: " .. table.concat(data.visited or {}, ", ")
        end
        
        local stepLbl = analysisOverlay:FindFirstChild("StepLabel")
        if stepLbl then
            stepLbl.Text = "Paso: " .. (data.currentStep or 0)
        end
    end
end

function GUIAdapter:showAnalysisPanel()
    if analysisOverlay then
        analysisOverlay.Visible = true
    end
end

function GUIAdapter:hideAnalysisPanel()
    if analysisOverlay then
        analysisOverlay.Visible = false
    end
end

-- ============================================
-- ACCESO A COMPONENTES DIRECTOS
-- ============================================

function GUIAdapter:getScreenGui()
    return screenGui
end

function GUIAdapter:getTopBar()
    return topBar
end

function GUIAdapter:getMainButtonsBar()
    return mainButtonsBar
end

function GUIAdapter:getMatrixPanel()
    return matrixPanel
end

function GUIAdapter:getAnalysisOverlay()
    return analysisOverlay
end

function GUIAdapter:getMinimapContainer()
    return minimapContainer
end

function GUIAdapter:getModeSelector()
    return modeSelector
end

return GUIAdapter