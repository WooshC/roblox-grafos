-- Controllers/VisualController.lua
local VisualController = {
    labels = {}, -- { PartAncla, Gui, PosteRef }
    selectors = {}, -- Cache de selectores originales
    AliasUtils = require(game.ReplicatedStorage:WaitForChild("Utilidades"):WaitForChild("AliasUtils")),
}

local StateManager = require(script.Parent.Parent.Services.StateManager)
local LevelsConfig = require(game.ReplicatedStorage:WaitForChild("LevelsConfig"))

function VisualController.init()
    StateManager.subscribe("ui.mapActive", VisualController._onToggle)
    StateManager.subscribe("energizedNodes", VisualController._showSelectors)
end

function VisualController._onToggle(isActive)
    if isActive then
        VisualController._showNodeLabels()
        VisualController._showSelectors()
    else
        VisualController._hideNodeLabels()
        VisualController._hideSelectors()
    end
end

function VisualController._showNodeLabels()
    local level = VisualController._getLevelModel()
    local postes = level and level:FindFirstChild("Objetos") and level.Objetos:FindFirstChild("Postes")
    if not postes then return end
    
    local levelId = StateManager.get("level.id")
    
    for _, poste in ipairs(postes:GetChildren()) do
        if poste:IsA("Model") then
            local label = VisualController._createLabel(poste, levelId)
            table.insert(VisualController.labels, label)
        end
    end
end

function VisualController._createLabel(poste, levelId)
    local pos = poste:GetPivot().Position + Vector3.new(0, 8, 0)
    
    local anchor = Instance.new("Part")
    anchor.Size = Vector3.new(1,1,1)
    anchor.Transparency = 1
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.Position = pos
    anchor.Parent = workspace
    
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 200, 0, 80)
    bb.StudsOffset = Vector3.new(0, 2, 0)
    bb.AlwaysOnTop = true
    bb.Parent = anchor
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = VisualController.AliasUtils.getNodeAlias(levelId, poste.Name)
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.TextStrokeTransparency = 0
    lbl.Font = Enum.Font.FredokaOne
    lbl.TextSize = 25
    lbl.Parent = bb
    
    -- Añadir indicador META si es nodo final
    VisualController._addMetaIndicator(bb, poste, levelId)
    
    return { PartAncla = anchor, Gui = bb, PosteRef = poste }
end

function VisualController._addMetaIndicator(gui, poste, levelId)
    local config = LevelsConfig[levelId] or {}
    if poste.Name ~= config.NodoFin then return end
    
    local meta = Instance.new("TextLabel")
    meta.Name = "MetaLbl"
    meta.Size = UDim2.new(1,0,0.5,0)
    meta.Position = UDim2.new(0,0,-0.8,0)
    meta.BackgroundTransparency = 1
    meta.Text = "🚩 META"
    meta.TextColor3 = Color3.new(1, 0.5, 0)
    meta.TextStrokeTransparency = 0
    meta.Font = Enum.Font.FredokaOne
    meta.TextSize = 22
    meta.Parent = gui
end

function VisualController._hideNodeLabels()
    for _, obj in ipairs(VisualController.labels) do
        if obj.PartAncla then obj.PartAncla:Destroy() end
    end
    VisualController.labels = {}
end

function VisualController._showSelectors()
    local level = VisualController._getLevelModel()
    local postes = level and level:FindFirstChild("Objetos") and level.Objetos:FindFirstChild("Postes")
    if not postes then return end
    
    local config = LevelsConfig[StateManager.get("level.id")] or {}
    
    for _, poste in ipairs(postes:GetChildren()) do
        local selector = poste:FindFirstChild("Selector")
        if selector and selector:IsA("BasePart") then
            -- Guardar estado original
            if not VisualController.selectors[selector] then
                VisualController.selectors[selector] = {
                    transparency = selector.Transparency,
                    color = selector.Color,
                    material = selector.Material,
                    size = selector.Size
                }
            end
            
            VisualController._updateSelectorAppearance(selector, poste, config)
        end
    end
end

function VisualController._updateSelectorAppearance(selector, poste, config)
    local isStart = poste.Name == config.NodoInicio
    local isEnd = poste.Name == config.NodoFin
    local energizedNodes = StateManager.get("energizedNodes") or {}
    local isEnergized = energizedNodes[poste.Name]
    
    selector.Transparency = 0
    
    if isStart then
        selector.Color = Color3.fromRGB(52, 152, 219)
        selector.Material = Enum.Material.Neon
    elseif not isEnergized then
        selector.Color = Color3.fromRGB(231, 76, 60)
        selector.Material = Enum.Material.Neon
        selector.Size = VisualController.selectors[selector].size * 1.3
    else
        selector.Color = Color3.fromRGB(46, 204, 113)
        selector.Material = Enum.Material.Plastic
        selector.Size = VisualController.selectors[selector].size
    end
end

function VisualController._hideSelectors()
    for selector, original in pairs(VisualController.selectors) do
        if selector then
            selector.Transparency = original.transparency
            selector.Color = original.color
            selector.Material = original.material
            selector.Size = original.size
        end
    end
    VisualController.selectors = {}
end

function VisualController._updateEnergy(nodes)
    if not StateManager.get("ui.mapActive") then return end
    -- Re-renderizar selectores con nuevo estado
    VisualController._showSelectors()
end

function VisualController._getLevelModel()
    return workspace:FindFirstChild("NivelActual")
        or workspace:FindFirstChild("Nivel" .. (StateManager.get("level.id") or 0))
end

return VisualController