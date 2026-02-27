-- TweenPresets.lua
-- Librería centralizada de configuraciones de Tween

local TweenPresets = {}

-- Duraciones estándar
TweenPresets.DURATION = {
	INSTANT = 0,
	FAST = 0.2,
	NORMAL = 0.4,
	SLOW = 0.8,
	MAP_TRANSITION = 0.4
}

-- Estilos comunes
TweenPresets.STYLE = {
	DEFAULT = Enum.EasingStyle.Quad,
	BOUNCE = Enum.EasingStyle.Back,
	ELASTIC = Enum.EasingStyle.Elastic,
	SMOOTH = Enum.EasingStyle.Cubic
}

-- Direcciones
TweenPresets.DIRECTION = {
	IN = Enum.EasingDirection.In,
	OUT = Enum.EasingDirection.Out,
	INOUT = Enum.EasingDirection.InOut
}

-- Presets preconfigurados
TweenPresets.PRESETS = {
	-- UI: Aparecer con bounce
	UI_POP_IN = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),

	-- UI: Desaparecer rápido
	UI_FADE_OUT = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),

	-- Cámara: Transición suave de mapa
	CAMERA_MAP = TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut),

	-- Zonas: Aparecer highlight
	ZONE_HIGHLIGHT = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),

	-- Nodos: Pulso de selección
	NODE_PULSE = TweenInfo.new(0.3, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),

	-- Nodos: Cambio de color estándar
	NODE_COLOR_CHANGE = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
}

-- Colores estándar del juego
TweenPresets.COLORS = {
	-- Zonas
	ZONE_ACTIVE = Color3.fromRGB(62, 207, 142),      -- Verde
	ZONE_INACTIVE = Color3.fromRGB(200, 200, 200),   -- Gris
	ZONE_COMPLETED = Color3.fromRGB(245, 200, 66),   -- Oro

	-- Nodos
	NODE_SELECTED = Color3.fromRGB(0, 120, 255),     -- Azul
	NODE_ADJACENT = Color3.fromRGB(255, 220, 0),     -- Amarillo
	NODE_ENERGIZED = Color3.fromRGB(46, 204, 113),   -- Verde
	NODE_CONNECTED = Color3.fromRGB(52, 152, 219),   -- Azul claro
	NODE_DISCONNECTED = Color3.fromRGB(231, 76, 60), -- Rojo
	NODE_START = Color3.fromRGB(52, 152, 219),       -- Azul

	-- UI
	UI_WHITE = Color3.new(1, 1, 1),
	UI_BLACK = Color3.new(0, 0, 0),
	UI_STROKE = Color3.new(1, 1, 1)
}

-- Materiales estándar
TweenPresets.MATERIALS = {
	NEON = Enum.Material.Neon,
	PLASTIC = Enum.Material.Plastic,
	SMOOTH_PLASTIC = Enum.Material.SmoothPlastic
}

-- Tamaños relativos
TweenPresets.SIZES = {
	NODE_DEFAULT = 1.0,
	NODE_SELECTED = 1.3,
	NODE_ADJACENT = 1.2,
	NODE_DISCONNECTED = 1.3
}

return TweenPresets