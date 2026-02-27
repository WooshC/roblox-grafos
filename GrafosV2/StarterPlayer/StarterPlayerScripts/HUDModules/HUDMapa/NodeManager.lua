-- NodeManager.lua
-- Gestión de nodos del grafo

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NodeEffects = require(ReplicatedStorage.Effects.NodeEffects)

local NodeManager = {}

NodeManager.allNodes = {}
NodeManager.nivelActual = nil
NodeManager.config = nil

function NodeManager.init(nivelModel, nivelConfig)
	NodeManager.nivelActual = nivelModel
	NodeManager.config = nivelConfig
	NodeManager.allNodes = {}

	local grafosFolder = nivelModel:FindFirstChild("Grafos")
	if not grafosFolder then return end

	for _, grafo in ipairs(grafosFolder:GetChildren()) do
		local nodosFolder = grafo:FindFirstChild("Nodos")
		if nodosFolder then
			for _, nodo in ipairs(nodosFolder:GetChildren()) do
				if nodo:IsA("Model") then
					table.insert(NodeManager.allNodes, nodo)
				end
			end
		end
	end
end

function NodeManager.hasConnections(poste)
	local connections = poste:FindFirstChild("Connections")
	return connections and #connections:GetChildren() > 0
end

function NodeManager.getSelectorPart(poste)
	local selector = poste:FindFirstChild("Selector")
	if not selector then return nil end

	if selector:IsA("BasePart") then
		return selector
	elseif selector:IsA("Model") then
		for _, part in ipairs(selector:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "Attachment" then
				return part
			end
		end
	end

	return nil
end

function NodeManager.updateNodeVisuals(poste, nombreInicio, nombreFin)
	local selectorPart = NodeManager.getSelectorPart(poste)
	if not selectorPart then return end

	-- Guardar tamaño original
	if not selectorPart:GetAttribute("OriginalSize") then
		selectorPart:SetAttribute("OriginalSize", selectorPart.Size)
	end

	local nombre = poste.Name
	local energizado = poste:GetAttribute("Energizado")
	local conectado = NodeManager.hasConnections(poste)

	-- Determinar estado
	local state = NodeEffects.getNodeState(nombre, energizado, conectado, nombreInicio, nombreFin)

	-- Aplicar efectos
	NodeEffects.applyToSelector(selectorPart, state, selectorPart:GetAttribute("OriginalSize"))
end

function NodeManager.updateAllNodes()
	if not NodeManager.config then return end

	local nombreInicio = NodeManager.config.NodoInicio
	local nombreFin = NodeManager.config.NodoFin

	for _, poste in ipairs(NodeManager.allNodes) do
		NodeManager.updateNodeVisuals(poste, nombreInicio, nombreFin)
	end
end

function NodeManager.setSelection(nodoNombre, adyacentes)
	NodeEffects.setSelection(nodoNombre, adyacentes)
	NodeManager.updateAllNodes()
end

function NodeManager.clearSelection()
	NodeEffects.clearSelection()
	NodeManager.updateAllNodes()
end

function NodeManager.resetAllSelectors()
	for _, poste in ipairs(NodeManager.allNodes) do
		local selector = poste:FindFirstChild("Selector")
		if selector then
			local baseSize = nil
			if selector:IsA("BasePart") then
				baseSize = selector:GetAttribute("OriginalSize")
			end
			NodeEffects.resetSelector(selector, baseSize)
		end
	end
end

function NodeManager.getNodeFromSelector(selectorPart)
	local poste = selectorPart:FindFirstAncestorOfClass("Model")
	while poste and not poste:FindFirstChild("Selector") do
		poste = poste.Parent
		if poste == NodeManager.nivelActual then 
			return nil
		end
	end
	return poste
end

return NodeManager