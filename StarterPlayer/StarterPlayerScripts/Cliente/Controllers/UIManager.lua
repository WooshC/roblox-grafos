-- Services/UIManager.lua
local Players = game:GetService("Players")
local StateManager = require(script.Parent.Parent.Services.StateManager)

local UIManager = {
    playerGui = nil,
    screenGui = nil,
    components = {}
}

-- Referencias a componentes UI
local UIComponents = {
    ScorePanel = require(script.Parent.Parent.Components.ScorePanel),
    MissionPanel = require(script.Parent.Parent.Components.MissionPanel)
}

function UIManager.init()
    UIManager.playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    UIManager.screenGui = UIManager.playerGui:WaitForChild("GameUI")
    
    UIManager._setupButtons()
    UIManager._subscribeToState()
end

function UIManager._setupButtons()
    local buttons = {
        Reiniciar = { btn = UIManager.screenGui:WaitForChild("BtnReiniciar"), action = "reset" },
        Mapa = { btn = UIManager.screenGui:WaitForChild("BtnMapa"), action = "toggleMap" },
        Algo = { btn = UIManager.screenGui:WaitForChild("BtnAlgo"), action = "runAlgo" },
        Misiones = { btn = UIManager.screenGui:WaitForChild("BtnMisiones"), action = "toggleMissions" },
        Matriz = { btn = UIManager.screenGui:WaitForChild("BtnMatriz"), action = "showMatrix" },
        Finalizar = { btn = UIManager.screenGui:WaitForChild("BtnFinalizar"), action = "finish" }
    }
    
    for name, data in pairs(buttons) do
        data.btn.MouseButton1Click:Connect(function()
            UIManager._handleAction(data.action, data.btn)
        end)
        UIManager.components[name] = data.btn
    end
end

function UIManager._subscribeToState()
    -- Actualizar visibilidad según estado
    StateManager.subscribe("inMenu", UIManager._updateVisibility)
    StateManager.subscribe("hasMap", function(has) 
        UIManager.components.Mapa.Visible = has and not StateManager.get("inMenu")
    end)
    StateManager.subscribe("hasAlgorithm", function(has)
        UIManager.components.Algo.Visible = has and not StateManager.get("inMenu")
    end)
    StateManager.subscribe("mapActive", function(active)
        UIManager.components.Mapa.Text = active and "CERRAR MAPA" or "🗺️ MAPA"
        UIManager.components.Mapa.BackgroundColor3 = active and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(52, 152, 219)
        
        -- Toggle paneles
        if active then
            UIComponents.ScorePanel.show(UIManager.screenGui)
            UIComponents.MissionPanel.show(UIManager.screenGui, StateManager.missionStatus)
        else
            UIComponents.ScorePanel.hide()
            UIComponents.MissionPanel.hide()
        end
    end)
    StateManager.subscribe("missionsActive", function(active)
        UIManager.components.Misiones.BackgroundColor3 = active and Color3.fromRGB(231, 76, 60) or Color3.fromRGB(46, 204, 113)
        if active then
            UIComponents.MissionPanel.show(UIManager.screenGui, StateManager.missionStatus)
        else
            UIComponents.MissionPanel.hide()
        end
    end)
end

function UIManager._updateVisibility(inMenu)
    local gameplayElements = {"Reiniciar", "Mapa", "Algo", "Misiones", "Matriz", "Finalizar"}
    for _, name in ipairs(gameplayElements) do
        local btn = UIManager.components[name]
        if btn then
            if inMenu then
                btn.Visible = false
            else
                -- Lógica específica por botón
                if name == "Mapa" then
                    btn.Visible = StateManager.get("hasMap")
                elseif name == "Algo" then
                    btn.Visible = StateManager.get("hasAlgorithm")
                elseif name == "Finalizar" then
                    btn.Visible = false -- Se activa por evento
                else
                    btn.Visible = true
                end
            end
        end
    end
end

function UIManager._handleAction(action, btn)
    local NetworkService = require(script.Parent.Parent.Services.NetworkService)
    
    if action == "reset" then
        btn.Text = "⏳ ..."
        NetworkService.resetLevel()
        task.delay(1, function() btn.Text = "🔄 REINICIAR" end)
        
    elseif action == "toggleMap" then
        -- Cerrar misiones si está abierto
        if StateManager.get("missionsActive") then
            StateManager.set("missionsActive", false)
        end
        StateManager.set("mapActive", not StateManager.get("mapActive"))
        
    elseif action == "toggleMissions" then
        if StateManager.get("mapActive") then
            StateManager.set("mapActive", false)
        end
        StateManager.set("missionsActive", not StateManager.get("missionsActive"))
        
    elseif action == "runAlgo" then
        local levelId = StateManager.currentLevel
        local LevelsConfig = require(game.ReplicatedStorage.LevelsConfig)
        local config = LevelsConfig[levelId]
        if config then
            NetworkService.runAlgorithm(config.Algoritmo or "BFS", config.NodoInicio, config.NodoFin, levelId)
        end
        
    elseif action == "showMatrix" then
        print("🔢 Matriz pendiente")
        
    elseif action == "finish" then
        print("🏆 Finalizar nivel")
    end
end

return UIManager