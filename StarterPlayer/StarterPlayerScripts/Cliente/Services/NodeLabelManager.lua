-- ================================================================
-- NodeLabelManager.lua (CORREGIDO)
-- Gestiona etiquetas flotantes sobre los nodos (postes)
-- ✅ ARREGLO: Las etiquetas ahora se actualizan en posición en tiempo real
-- ================================================================

local NodeLabelManager = {}
NodeLabelManager.__index = NodeLabelManager

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AliasUtils = require(ReplicatedStorage:WaitForChild("Utilidades"):WaitForChild("AliasUtils"))
if not AliasUtils then warn("❌ NodeLabelManager: AliasUtils es nil") end

-- Estado
local labels = {} -- { [poste] = { Ancla = part, Gui = billboard, Poste = ref } }
local visible = false
local LevelsConfig = nil -- Will be injected

-- ================================================================
-- API
-- ================================================================

function NodeLabelManager.initialize(deps)
	if deps then
		LevelsConfig = deps.LevelsConfig
	end
	print("✅ NodeLabelManager: Inicializado")
end

function NodeLabelManager:show()
	visible = true
	-- Las etiquetas se crean bajo demanda en updateNodeLabel o pre-cargadas
	-- MapManager las actualiza en el loop
end

function NodeLabelManager:hide()
	visible = false
	self:_clearLabels()
end

--- Obtiene (o crea) la etiqueta para un poste
function NodeLabelManager:getLabelForNode(poste)
	if not visible then return nil end
	if not poste then return nil end

	if labels[poste] then
		return labels[poste]
	end

	-- Crear etiqueta nueva
	local ancla = Instance.new("Part")
	ancla.Name = "EtiquetaAncla_" .. poste.Name
	ancla.Transparency = 1
	ancla.Anchored = true
	ancla.CanCollide = false
	ancla.Size = Vector3.new(1,1,1)
	-- ✅ POSICIÓN INICIAL: Arriba del poste
	ancla.Position = poste:GetPivot().Position + Vector3.new(0, 8, 0)
	ancla.Parent = workspace

	local bb = Instance.new("BillboardGui")
	bb.Name = "EtiquetaGui"
	bb.Size = UDim2.new(0, 200, 0, 80)
	bb.StudsOffset = Vector3.new(0, 2, 0)
	bb.AlwaysOnTop = true
	bb.Parent = ancla

	local lblName = Instance.new("TextLabel")
	lblName.Name = "NombreLbl"
	lblName.Size = UDim2.new(1,0,1,0)
	lblName.BackgroundTransparency = 1
	lblName.TextColor3 = Color3.new(1,1,1)
	lblName.TextStrokeTransparency = 0
	lblName.Font = Enum.Font.FredokaOne
	lblName.TextSize = 25
	lblName.Parent = bb

	-- Obtener ID de nivel del jugador para el alias
	local player = game.Players.LocalPlayer
	local levelId = player:GetAttribute("CurrentLevelID") or 0
	local alias = AliasUtils.getNodeAlias(levelId, poste.Name)
	lblName.Text = alias

	print(string.format("🏷️ Etiqueta creada: %s -> %s (Nivel %d) en posición: %s", poste.Name, alias, levelId, tostring(ancla.Position)))

	labels[poste] = {
		Ancla = ancla,
		Gui = bb,
		LblName = lblName,
		Poste = poste  -- ✅ Guardar referencia al poste para actualizar posición
	}

	return labels[poste]
end

--- ✅ NUEVA FUNCIÓN: Actualizar posiciones de todas las etiquetas
function NodeLabelManager:updateAllPositions()
	if not visible then return end

	for poste, labelObj in pairs(labels) do
		if labelObj and labelObj.Ancla and poste and poste.Parent then
			-- Actualizar posición del ancla al poste + offset arriba
			labelObj.Ancla.Position = poste:GetPivot().Position + Vector3.new(0, 8, 0)
		end
	end
end

function NodeLabelManager:updateNodeDistance(poste, distanciaMetros)
	local labelObj = self:getLabelForNode(poste)
	if not labelObj then return end

	local bb = labelObj.Gui
	local lblDist = bb:FindFirstChild("DistanciaLbl")

	if not lblDist then
		lblDist = Instance.new("TextLabel")
		lblDist.Name = "DistanciaLbl"
		lblDist.Size = UDim2.new(1,0,0.5,0)
		lblDist.Position = UDim2.new(0,0,1,-5)
		lblDist.BackgroundTransparency = 1
		lblDist.Font = Enum.Font.FredokaOne
		lblDist.TextSize = 16
		lblDist.TextStrokeTransparency = 0
		lblDist.Parent = bb
	end

	-- Lógica de color según si es inicio o no (asumiendo que MapManager pasa info, 
	-- pero aquí solo actualizamos texto por simplicidad)
	lblDist.Text = distanciaMetros .. "m"

	-- Ocultar si está energizado (opcional, replicando lógica anterior)
	if poste:GetAttribute("Energizado") == true then
		lblDist.Visible = false
	else
		lblDist.Visible = true
		lblDist.TextColor3 = Color3.new(1, 0.2, 0.2)
	end
end

function NodeLabelManager:addMetaIndicator(poste, levelId)
	local labelObj = self:getLabelForNode(poste)
	if not labelObj then return end

	if not LevelsConfig then 
		LevelsConfig = require(ReplicatedStorage.LevelsConfig) -- Fallback
	end 
	local config = LevelsConfig[levelId]
	if not config or poste.Name ~= config.NodoFin then return end

	local bb = labelObj.Gui
	if bb:FindFirstChild("MetaLbl") then return end

	local lblMeta = Instance.new("TextLabel")
	lblMeta.Name = "MetaLbl"
	lblMeta.Size = UDim2.new(1,0,0.5,0)
	lblMeta.Position = UDim2.new(0,0,-0.8,0)
	lblMeta.BackgroundTransparency = 1
	lblMeta.Text = "🚩 META"
	lblMeta.TextColor3 = Color3.new(1, 0.5, 0)
	lblMeta.TextStrokeTransparency = 0
	lblMeta.Font = Enum.Font.FredokaOne
	lblMeta.TextSize = 22
	lblMeta.Parent = bb
end

function NodeLabelManager:_clearLabels()
	for poste, obj in pairs(labels) do
		if obj.Ancla then obj.Ancla:Destroy() end
	end
	labels = {}
end

return NodeLabelManager