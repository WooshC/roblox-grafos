-- ZoneManager.lua
-- Gestión de zonas y sus efectos visuales

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ZoneEffects = require(ReplicatedStorage.Effects.ZoneEffects)
local TweenPresets = require(ReplicatedStorage.Effects.TweenPresets)

local ZoneManager = {}

-- Estado
ZoneManager.activeHighlights = {}
ZoneManager.zonasConfig = nil
ZoneManager.player = Players.LocalPlayer

function ZoneManager.init(config)
	ZoneManager.zonasConfig = config
end

function ZoneManager.findZonesInLevel(nivelModel)
	if not nivelModel then return {} end

	local zonas = nivelModel:FindFirstChild("Zonas")
	if not zonas then 
		warn("[ZoneManager] No se encontró folder 'Zonas'")
		return {} 
	end

	local zonasJuego = zonas:FindFirstChild("Zonas_juego")
	if not zonasJuego then 
		warn("[ZoneManager] No se encontró 'Zonas_juego'")
		return {} 
	end

	return zonasJuego:GetChildren()
end

function ZoneManager.getZonaIDFromPartName(partName)
	if not ZoneManager.zonasConfig then return partName end

	for zonaID, zonaData in pairs(ZoneManager.zonasConfig) do
		if zonaData.Trigger == partName then
			return zonaID
		end
	end

	return partName
end

function ZoneManager.highlightZone(zonaObj, zonaID, estadoZona, nivelID)
	local zonaPart = nil

	if zonaObj:IsA("BasePart") then
		zonaPart = zonaObj
	else
		-- Encontrar la parte más grande para el highlight
		local largestSize = 0
		for _, child in ipairs(zonaObj:GetDescendants()) do
			if child:IsA("BasePart") then
				local size = child.Size.X * child.Size.Y * child.Size.Z
				if size > largestSize then
					zonaPart = child
					largestSize = size
				end
			end
		end
	end

	if not zonaPart then 
		warn("[ZoneManager] No BasePart para zona:", zonaID)
		return nil 
	end

	local color = ZoneEffects.getZoneColor(estadoZona)

	-- Crear highlight
	local highlightData = ZoneEffects.createHighlight(zonaPart, color)

	-- Obtener descripción
	local descripcion = nil
	if ZoneManager.zonasConfig and ZoneManager.zonasConfig[zonaID] then
		descripcion = ZoneManager.zonasConfig[zonaID].Descripcion
	end

	-- Crear billboard
	local billboardData = ZoneEffects.createBillboard(zonaPart, zonaID, descripcion, color)

	-- Configurar visibilidad
	local function updateVisibility()
		local currentZone = ZoneManager.player:GetAttribute("CurrentZone")
		ZoneEffects.updateBillboardVisibility(billboardData, zonaID, currentZone)
	end

	-- Verificación inicial
	task.delay(0.1, updateVisibility)

	-- Conectar a cambios de zona
	local connection = ZoneManager.player:GetAttributeChangedSignal("CurrentZone"):Connect(function()
		task.delay(0.05, updateVisibility)
	end)

	local zoneData = {
		Part = zonaPart,
		ZonaID = zonaID,
		Highlight = highlightData.Highlight,
		Billboard = billboardData.Billboard,
		OriginalTransparency = highlightData.OriginalTransparency,
		ZoneConnection = connection
	}

	ZoneManager.activeHighlights[zonaPart] = zoneData
	return zoneData
end

function ZoneManager.highlightAllZones(nivelModel, nivelID, datosMisiones, levelsConfig)
	ZoneManager.cleanup()

	local zonas = ZoneManager.findZonesInLevel(nivelModel)
	if #zonas == 0 then return end

	-- Cargar config
	if levelsConfig and levelsConfig[nivelID] then
		ZoneManager.init(levelsConfig[nivelID].Zonas)
	end

	-- Calcular estados
	local estados = {}
	if datosMisiones and datosMisiones.porZona then
		for zonaNombre, datos in pairs(datosMisiones.porZona) do
			if datos.completadas >= datos.total then
				estados[zonaNombre] = "completada"
			elseif datos.completadas > 0 then
				estados[zonaNombre] = "activa"
			else
				estados[zonaNombre] = "inactiva"
			end
		end
	end

	-- Crear highlights
	for _, zonaObj in ipairs(zonas) do
		local partName = zonaObj.Name
		local zonaID = ZoneManager.getZonaIDFromPartName(partName)

		ZoneManager.highlightZone(zonaObj, zonaID, estados[zonaID] or "inactiva", nivelID)
	end
end

function ZoneManager.cleanup()
	for _, data in pairs(ZoneManager.activeHighlights) do
		ZoneEffects.cleanupZone(data)
	end
	ZoneManager.activeHighlights = {}
end

return ZoneManager