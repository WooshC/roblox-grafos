-- NodeEffects.lua
-- Efectos visuales para nodos del grafo

local TweenService = game:GetService("TweenService")
local TweenPresets = require(script.Parent.TweenPresets)

local NodeEffects = {}

-- Estado de selección compartido
NodeEffects.selectedNode = nil
NodeEffects.adjacentNodes = {}

function NodeEffects.setSelection(nodoNombre, adyacentes)
	NodeEffects.selectedNode = nodoNombre
	NodeEffects.adjacentNodes = {}

	if adyacentes then
		for _, vecino in ipairs(adyacentes) do
			NodeEffects.adjacentNodes[vecino] = true
		end
	end
end

function NodeEffects.clearSelection()
	NodeEffects.selectedNode = nil
	NodeEffects.adjacentNodes = {}
end

function NodeEffects.isSelected(nombre)
	return NodeEffects.selectedNode == nombre
end

function NodeEffects.isAdjacent(nombre)
	return NodeEffects.adjacentNodes[nombre] == true
end

function NodeEffects.getNodeState(nombre, energizado, conectado, esInicio, esFin)
	if NodeEffects.isSelected(nombre) then
		return "SELECTED"
	elseif NodeEffects.isAdjacent(nombre) then
		return "ADJACENT"
	elseif nombre == esInicio then
		return "START"
	elseif energizado then
		return "ENERGIZED"
	elseif conectado then
		return "CONNECTED"
	else
		return "DISCONNECTED"
	end
end

function NodeEffects.getStateColor(state)
	local colors = {
		SELECTED = TweenPresets.COLORS.NODE_SELECTED,
		ADJACENT = TweenPresets.COLORS.NODE_ADJACENT,
		START = TweenPresets.COLORS.NODE_START,
		ENERGIZED = TweenPresets.COLORS.NODE_ENERGIZED,
		CONNECTED = TweenPresets.COLORS.NODE_CONNECTED,
		DISCONNECTED = TweenPresets.COLORS.NODE_DISCONNECTED
	}
	return colors[state] or TweenPresets.COLORS.NODE_DISCONNECTED
end

function NodeEffects.getStateMaterial(state)
	if state == "SELECTED" or state == "ADJACENT" or state == "START" or state == "DISCONNECTED" then
		return TweenPresets.MATERIALS.NEON
	else
		return TweenPresets.MATERIALS.PLASTIC
	end
end

function NodeEffects.getStateSizeMultiplier(state)
	local sizes = {
		SELECTED = TweenPresets.SIZES.NODE_SELECTED,
		ADJACENT = TweenPresets.SIZES.NODE_ADJACENT,
		DISCONNECTED = TweenPresets.SIZES.NODE_DISCONNECTED
	}
	return sizes[state] or TweenPresets.SIZES.NODE_DEFAULT
end

function NodeEffects.applyToSelector(selectorPart, state, baseSize)
	if not selectorPart or not selectorPart:IsA("BasePart") then return end

	local color = NodeEffects.getStateColor(state)
	local material = NodeEffects.getStateMaterial(state)
	local sizeMult = NodeEffects.getStateSizeMultiplier(state)

	-- Aplicar color y material inmediatamente
	selectorPart.Color = color
	selectorPart.Material = material

	-- Tween de tamaño si cambió
	local targetSize = baseSize * sizeMult
	if (selectorPart.Size - targetSize).Magnitude > 0.01 then
		TweenService:Create(selectorPart, TweenPresets.PRESETS.NODE_COLOR_CHANGE, {
			Size = targetSize
		}):Play()
	end
end

function NodeEffects.resetSelector(selectorPart, baseSize)
	if not selectorPart then return end

	if selectorPart:IsA("BasePart") then
		selectorPart.Transparency = 1
		selectorPart.Color = Color3.fromRGB(196, 196, 196)
		selectorPart.Material = TweenPresets.MATERIALS.PLASTIC
		if baseSize then
			selectorPart.Size = baseSize
		end
	elseif selectorPart:IsA("Model") then
		for _, part in ipairs(selectorPart:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Transparency = 1
				part.Color = Color3.fromRGB(196, 196, 196)
				part.Material = TweenPresets.MATERIALS.PLASTIC
			end
		end
	end
end

return NodeEffects