-- ServerScriptService/Services/ModeManager.lua
-- Orquesta los cambios entre modos y mantiene el estado

local ModeManager = {}
ModeManager.__index = ModeManager

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Dependencias (se inyectan)
local LevelService = nil
local GraphService = nil

-- Estado global
local modeState = {
    currentMode = "VISUAL",           -- VISUAL | MATEMÁTICO | ANÁLISIS
    previousMode = nil,
    lastChangeTime = 0,
    modeLockDuration = 0.5,           -- No permitir cambios muy rápido
}

-- Eventos internos
local modeChangedEvent = Instance.new("BindableEvent")

-- ============================================
-- INICIALIZACIÓN
-- ============================================

function ModeManager:setDependencies(level, graph)
    LevelService = level
    GraphService = graph
    print("✅ ModeManager: Dependencias inyectadas")
end

function ModeManager:init()
    -- Crear evento remoto para cambios de modo desde cliente
    local Events = ReplicatedStorage:WaitForChild("Events")
    local Remotes = Events:WaitForChild("Remotes")
    
    local requestModeEvent = Remotes:FindFirstChild("RequestModeChange")
    if not requestModeEvent then
        requestModeEvent = Instance.new("RemoteEvent")
        requestModeEvent.Name = "RequestModeChange"
        requestModeEvent.Parent = Remotes
    end
    
    -- Escuchar solicitudes de cambio de modo
    requestModeEvent.OnServerEvent:Connect(function(player, newMode)
        self:switchMode(newMode)
    end)
    
    print("✅ ModeManager: Inicializado")
end

-- ============================================
-- CAMBIO DE MODO
-- ============================================

function ModeManager:switchMode(newMode)
    -- Validar que el modo es válido
    if newMode ~= "VISUAL" and newMode ~= "MATEMÁTICO" and newMode ~= "ANÁLISIS" then
        warn("❌ ModeManager: Modo inválido: " .. newMode)
        return false
    end
    
    -- Prevenir cambios muy rápido
    if tick() - modeState.lastChangeTime < modeState.modeLockDuration then
        print("⚠️ ModeManager: Cambios de modo muy rápido, ignorando")
        return false
    end
    
    -- No cambiar si ya estamos en ese modo
    if modeState.currentMode == newMode then
        print("ℹ️ ModeManager: Ya estamos en modo " .. newMode)
        return false
    end
    
    local oldMode = modeState.currentMode
    modeState.previousMode = oldMode
    modeState.currentMode = newMode
    modeState.lastChangeTime = tick()
    
    print("🔄 ModeManager: Cambio de modo " .. oldMode .. " → " .. newMode)
    
    -- Ejecutar lógica específica del cambio
    self:_executeModeSwitchLogic(oldMode, newMode)
    
    -- Emitir evento
    modeChangedEvent:Fire(newMode, oldMode)
    
    -- Notificar a clientes
    local Remotes = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes")
    local notifyModeEvent = Remotes:FindFirstChild("ModeChanged")
    if notifyModeEvent then
        notifyModeEvent:FireAllClients(newMode, oldMode)
    end
    
    return true
end

-- ============================================
-- LÓGICA DE CAMBIO ESPECÍFICA POR MODO
-- ============================================

function ModeManager:_executeModeSwitchLogic(oldMode, newMode)
    -- Limpieza del modo anterior
    if oldMode == "ANÁLISIS" then
        self:_cleanupAnalysisMode()
    elseif oldMode == "MATEMÁTICO" then
        self:_cleanupMatrixMode()
    end
    
    -- Inicialización del nuevo modo
    if newMode == "VISUAL" then
        self:_initVisualMode()
    elseif newMode == "MATEMÁTICO" then
        self:_initMatrixMode()
    elseif newMode == "ANÁLISIS" then
        self:_initAnalysisMode()
    end
end

-- ============================================
-- MODO VISUAL
-- ============================================

function ModeManager:_initVisualMode()
    print("📌 Inicializando MODO VISUAL")
    
    -- Jugador puede moverse libremente
    local player = Players.LocalPlayer
    if player and player.Character then
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 32  -- Velocidad normal
            print("   ✓ Movimiento habilitado")
        end
    end
    
    -- Mostrar minimapa
    -- (Handled por GUIAdapter en cliente)
    
    -- Restablecer modo de cámara a Custom
    print("   ✓ Modo VISUAL listo")
end

function ModeManager:_cleanupVisualMode()
    -- No mucho que limpiar en VISUAL
    print("   ✓ Limpieza de MODO VISUAL")
end

-- ============================================
-- MODO MATEMÁTICO
-- ============================================

function ModeManager:_initMatrixMode()
    print("📌 Inicializando MODO MATEMÁTICO")
    
    -- El jugador sigue pudiendo moverse
    local player = Players.LocalPlayer
    if player and player.Character then
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 32
            print("   ✓ Movimiento habilitado")
        end
    end
    
    -- Generar matriz si no existe
    if GraphService then
        local nodes = GraphService:getNodes()
        local cables = GraphService:getCables()
        print("   ✓ Matriz actualizada (" .. #nodes .. " nodos)")
    end
end

function ModeManager:_cleanupMatrixMode()
    print("   ✓ Limpieza de MODO MATEMÁTICO")
end

-- ============================================
-- MODO ANÁLISIS
-- ============================================

function ModeManager:_initAnalysisMode()
    print("📌 Inicializando MODO ANÁLISIS")
    
    -- Desactivar movimiento del jugador
    local player = Players.LocalPlayer
    if player and player.Character then
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 0  -- Congelado
            print("   ✓ Movimiento deshabilitado")
        end
    end
    
    -- Cambiar cámara a modo scriptable (oscurecer fondo)
    local camera = workspace.CurrentCamera
    camera.CameraType = Enum.CameraType.Scriptable
    -- La distancia y posición se ajustan desde cliente
    
    -- Inicializar simulador de algoritmo (será manejado por AnalysisService)
    print("   ✓ Modo ANÁLISIS listo")
end

function ModeManager:_cleanupAnalysisMode()
    print("   ✓ Limpieza de MODO ANÁLISIS")
    
    -- Reactivar movimiento
    local player = Players.LocalPlayer
    if player and player.Character then
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 32
        end
    end
    
    -- Restaurar cámara a Custom
    local camera = workspace.CurrentCamera
    camera.CameraType = Enum.CameraType.Custom
end

-- ============================================
-- QUERIES DE ESTADO
-- ============================================

function ModeManager:getCurrentMode()
    return modeState.currentMode
end

function ModeManager:getPreviousMode()
    return modeState.previousMode
end

function ModeManager:isInMode(mode)
    return modeState.currentMode == mode
end

function ModeManager:getModeState()
    return {
        currentMode = modeState.currentMode,
        previousMode = modeState.previousMode,
        lastChangeTime = modeState.lastChangeTime
    }
end

-- ============================================
-- EVENTOS
-- ============================================

function ModeManager:onModeChanged(callback)
    modeChangedEvent.Event:Connect(callback)
end

return ModeManager