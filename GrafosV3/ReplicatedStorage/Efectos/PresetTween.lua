-- ReplicatedStorage/Efectos/PresetTween.lua
-- Configuraciones de tweening reutilizables para efectos visuales

local PresetTween = {}

PresetTween.COLORES = {
	-- Estados de nodos
	NODO_SELECCIONADO = Color3.fromRGB(0, 212, 255),      -- Cyan brillante
	NODO_ADYACENTE = Color3.fromRGB(16, 185, 129),        -- Verde
	NODO_INICIO = Color3.fromRGB(245, 158, 11),           -- Naranja/Dorado
	NODO_ENERGIZADO = Color3.fromRGB(168, 85, 247),       -- Púrpura
	NODO_CONECTADO = Color3.fromRGB(59, 130, 246),        -- Azul
	NODO_DESCONECTADO = Color3.fromRGB(100, 116, 139),    -- Gris
	
	-- Efectos de cable
	CABLE_NORMAL = Color3.fromRGB(0, 200, 255),           -- Celeste
	CABLE_PULSO = Color3.fromRGB(255, 255, 255),          -- Blanco brillante
	CABLE_ERROR = Color3.fromRGB(239, 68, 68),            -- Rojo
	
	-- UI
	EXITO = Color3.fromRGB(16, 185, 129),
	ERROR = Color3.fromRGB(239, 68, 68),
	ADVERTENCIA = Color3.fromRGB(245, 158, 11),
}

PresetTween.MATERIALES = {
	NEON = Enum.Material.Neon,
	PLASTICO = Enum.Material.Plastic,
	METAL = Enum.Material.Metal,
}

PresetTween.TAMANOS = {
	NODO_SELECCIONADO = 1.3,
	NODO_ADYACENTE = 1.15,
	NODO_DEFAULT = 1.0,
}

PresetTween.DURACIONES = {
	RAPIDA = 0.15,
	NORMAL = 0.3,
	LENTA = 0.5,
	FLASH = 0.1,
}

PresetTween.PRESETS = {
	-- Cambio de color de nodo
	NODO_COLOR_CHANGE = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	
	-- Pulso de energía
	PULSO_ENERGIA = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	
	-- Flash de error
	FLASH_ERROR = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 3),
	
	-- Aparecer cable
	CABLE_APARECER = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	
	-- Desvanecer
	DESVANECER = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
}

return PresetTween
