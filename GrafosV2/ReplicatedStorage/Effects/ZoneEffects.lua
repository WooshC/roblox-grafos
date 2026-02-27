-- ZoneEffects.lua
-- Efectos visuales para zonas del mapa

local TweenService = game:GetService("TweenService")
local TweenPresets = require(script.Parent.TweenPresets)

local ZoneEffects = {}

-- Configuración
local CONFIG = {
	BILLBOARD_SIZE = UDim2.new(0, 300, 0, 100),
	BILLBOARD_OFFSET = Vector3.new(0, 8, 0),
	HIGHLIGHT_FILL_TRANSPARENCY = 0.3,
	HIGHLIGHT_OUTLINE_TRANSPARENCY = 0,
	ZONE_TRANSPARENCY = 0.7,
	CORNER_RADIUS = UDim.new(0, 12),
	STROKE_THICKNESS = 3
}

-- Caché de zonas activas
ZoneEffects.activeZones = {}

function ZoneEffects.createHighlight(zonaPart, color)
	if not zonaPart or not zonaPart:IsA("BasePart") then return nil end

	local highlight = Instance.new("Highlight")
	highlight.Name = "ZoneHighlight"
	highlight.Adornee = zonaPart
	highlight.FillColor = color
	highlight.OutlineColor = TweenPresets.COLORS.UI_WHITE
	highlight.FillTransparency = CONFIG.HIGHLIGHT_FILL_TRANSPARENCY
	highlight.OutlineTransparency = CONFIG.HIGHLIGHT_OUTLINE_TRANSPARENCY
	highlight.Parent = zonaPart

	-- Guardar transparencia original
	local originalTransparency = zonaPart.Transparency
	zonaPart.Transparency = CONFIG.ZONE_TRANSPARENCY

	return {
		Highlight = highlight,
		OriginalTransparency = originalTransparency
	}
end

function ZoneEffects.createBillboard(zonaPart, zonaID, descripcion, color)
	if not zonaPart then return nil end

	local bb = Instance.new("BillboardGui")
	bb.Name = "ZoneBillboard"
	bb.Size = CONFIG.BILLBOARD_SIZE
	bb.StudsOffset = CONFIG.BILLBOARD_OFFSET
	bb.AlwaysOnTop = true
	bb.Parent = zonaPart

	-- Frame contenedor
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.Parent = bb

	-- Esquinas redondeadas
	local corner = Instance.new("UICorner")
	corner.CornerRadius = CONFIG.CORNER_RADIUS
	corner.Parent = frame

	-- Borde
	local stroke = Instance.new("UIStroke")
	stroke.Color = TweenPresets.COLORS.UI_STROKE
	stroke.Thickness = CONFIG.STROKE_THICKNESS
	stroke.Parent = frame

	-- Texto
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 0.6, 0)
	label.Position = UDim2.new(0, 10, 0, 10)
	label.BackgroundTransparency = 1
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.FredokaOne
	label.TextSize = 22
	label.TextScaled = true
	label.Text = descripcion or zonaID:gsub("_", " ")
	label.TextColor3 = TweenPresets.COLORS.UI_WHITE
	label.Parent = frame

	-- Animación de entrada
	frame.Size = UDim2.new(0, 0, 0, 0)
	TweenService:Create(frame, TweenPresets.PRESETS.ZONE_HIGHLIGHT, {
		Size = UDim2.new(1, 0, 1, 0)
	}):Play()

	return {
		Billboard = bb,
		Frame = frame,
		Label = label
	}
end

function ZoneEffects.updateBillboardVisibility(billboardData, zonaID, currentZone)
	if not billboardData or not billboardData.Billboard then return end

	local estoyEnEstaZona = (currentZone == zonaID)
	billboardData.Billboard.Enabled = not estoyEnEstaZona

	return estoyEnEstaZona
end

function ZoneEffects.getZoneColor(estado)
	if estado == "completada" then
		return TweenPresets.COLORS.ZONE_COMPLETED
	elseif estado == "activa" then
		return TweenPresets.COLORS.ZONE_ACTIVE
	else
		return TweenPresets.COLORS.ZONE_INACTIVE
	end
end

function ZoneEffects.cleanupZone(zonaData)
	if not zonaData then return end

	if zonaData.Highlight and zonaData.Highlight.Parent then
		zonaData.Highlight:Destroy()
	end

	if zonaData.Billboard and zonaData.Billboard.Parent then
		zonaData.Billboard:Destroy()
	end

	if zonaData.ZoneConnection then
		zonaData.ZoneConnection:Disconnect()
	end

	-- Restaurar transparencia original
	if zonaData.Part and zonaData.Part.Parent and zonaData.OriginalTransparency then
		zonaData.Part.Transparency = zonaData.OriginalTransparency
	end
end

function ZoneEffects.cleanupAll()
	for _, data in pairs(ZoneEffects.activeZones) do
		ZoneEffects.cleanupZone(data)
	end
	ZoneEffects.activeZones = {}
end

return ZoneEffects