--[[
    ╔════════════════════════════════════════════════════════════════╗
    ║         EJEMPLO: ACTIVAR DIALOGO POR PROXIMIDAD                ║
    ║     Ubicar en: workspace > Zona1 > ProximityPrompt (Part)      ║
    ╚════════════════════════════════════════════════════════════════╝
]]

local DialogoGUISystem = nil

-- Esperar a que el sistema de diálogos se cargue
local function WaitForDialogoSystem()
    local maxTries = 100
    local tries = 0
    
    while not DialogoGUISystem and tries < maxTries do
        pcall(function()
            DialogoGUISystem = require(
                game.Players.LocalPlayer:WaitForChild("PlayerGui", 1)
                    :FindFirstChild("DialogoGUI", 1)
                    .Parent.Parent
                    .StarterPlayerScripts
                    .Cliente
                    .Services
                    .DialogoGUISystem
            )
        end)
        tries = tries + 1
        task.wait(0.1)
    end
    
    if not DialogoGUISystem then
        print("[ProximityZona1] ERROR: No se pudo cargar DialogoGUISystem")
        return false
    end
    
    print("[ProximityZona1] ✓ DialogoGUISystem cargado")
    return true
end

-- Obtener referencias
local proximityPrompt = script.Parent
local player = game.Players.LocalPlayer

-- Esperar sistema
if not WaitForDialogoSystem() then
    return
end

-- ════════════════════════════════════════════════════════════════
-- VARIABLES DE CONTROL
-- ════════════════════════════════════════════════════════════════

local dialogueShown = false
local cooldown = false

-- ════════════════════════════════════════════════════════════════
-- EVENTO DE PROXIMIDAD
-- ════════════════════════════════════════════════════════════════

proximityPrompt.Triggered:Connect(function(playerWhoTriggered)
    if playerWhoTriggered ~= player then return end
    if dialogueShown or cooldown then return end
    
    cooldown = true
    
    print("[ProximityZona1] ✓ Proximidad detectada - iniciando diálogo")
    
    -- Metadata que se pasa al diálogo
    local metadata = {
        primeraVez = not player:GetAttribute("VisitedZona1"),
        progreso = player:GetAttribute("Progreso") or 0,
        proximityTriggered = true
    }
    
    -- Guardar que se visitó la zona
    player:SetAttribute("VisitedZona1", true)
    
    -- INICIAR DIÁLOGO
    DialogoGUISystem:Play("Zona1_Intro", metadata)
    dialogueShown = true
    
    -- Callback cuando el diálogo termina
    DialogoGUISystem:OnClose(function()
        print("[ProximityZona1] Diálogo cerrado - recursos restaurados")
        dialogueShown = false
        
        -- Cooldown para no repetir inmediatamente
        task.wait(1)
        cooldown = false
    end)
end)

print("[ProximityZona1] ✓ Script cargado - esperando proximidad")

--[[
    ════════════════════════════════════════════════════════════════
    CONFIGURACIÓN
    ════════════════════════════════════════════════════════════════
    
    PASOS:
    1. Crear un Part en workspace > Zona1
    2. Agregar ProximityPrompt como hijo del Part
    3. Insertar este script como LocalScript dentro del ProximityPrompt
    4. Configurar ProximityPrompt en la propiedad MaxActivationDistance
    
    PROPIEDADES DEL PROXIMITYPROMPT:
    - MaxActivationDistance: 30 (rango de detección)
    - ActionText: "Hablar"
    - ObjectText: "Carlos"
    - KeyboardKeyCode: E (tecla para activar)
    
    ALTERNATIVA: ACTIVAR DESDE ZONA
    
    Si prefieres usar zonas en lugar de proximidad, puedes hacer:
    
    player:GetAttributeChangedSignal("CurrentZone"):Connect(function()
        local zone = player:GetAttribute("CurrentZone")
        
        if zone == "Zona1_Station" and not dialogueShown then
            DialogoGUISystem:Play("Zona1_Intro", metadata)
            dialogueShown = true
        end
    end)
]]
