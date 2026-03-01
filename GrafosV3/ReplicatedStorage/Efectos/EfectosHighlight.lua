-- ReplicatedStorage/Efectos/EfectosHighlight.lua
-- Sistema centralizado de Highlights de Roblox para efectos visuales
-- Usado por: Zonas, Nodos, Conexiones, Errores

local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local EfectosHighlight = {}

-- Estado
local highlightsActivos = {} -- nombre -> Highlight instance

-- Colores predefinidos
EfectosHighlight.COLORES = {
	ZONA        = Color3.fromRGB(0, 212, 255),   -- Cyan
	SELECCIONADO = Color3.fromRGB(0, 212, 255),  -- Cyan
	ADYACENTE   = Color3.fromRGB(255, 200, 50),  -- Dorado
	CONECTADO   = Color3.fromRGB(0, 212, 255),   -- Cyan (igual que zona/seleccionado)
	AISLADO     = Color3.fromRGB(239, 68, 68),   -- Rojo
	ERROR       = Color3.fromRGB(239, 68, 68),   -- Rojo
	EXITO       = Color3.fromRGB(34, 197, 94),   -- Verde éxito
}

-- Configuración por tipo
EfectosHighlight.CONFIG = {
	ZONA = {
		FillColor = EfectosHighlight.COLORES.ZONA,
		FillTransparency = 0.7,
		OutlineColor = EfectosHighlight.COLORES.ZONA,
		OutlineTransparency = 0,
		DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
	},
	SELECCIONADO = {
		FillColor = EfectosHighlight.COLORES.SELECCIONADO,
		FillTransparency = 0.6,
		OutlineColor = EfectosHighlight.COLORES.SELECCIONADO,
		OutlineTransparency = 0.1,
		DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
	},
	ADYACENTE = {
		FillColor = EfectosHighlight.COLORES.ADYACENTE,
		FillTransparency = 0.5,
		OutlineColor = EfectosHighlight.COLORES.ADYACENTE,
		OutlineTransparency = 0.1,
		DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
	},
	-- Estado de nodo en modo mapa: tiene al menos una conexión
	CONECTADO = {
		FillColor = EfectosHighlight.COLORES.CONECTADO,
		FillTransparency = 0.65,
		OutlineColor = EfectosHighlight.COLORES.CONECTADO,
		OutlineTransparency = 0.1,
		DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
	},
	-- Estado de nodo en modo mapa: sin conexiones
	AISLADO = {
		FillColor = EfectosHighlight.COLORES.AISLADO,
		FillTransparency = 0.75,
		OutlineColor = EfectosHighlight.COLORES.AISLADO,
		OutlineTransparency = 0.3,
		DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
	},
	ERROR = {
		FillColor = EfectosHighlight.COLORES.ERROR,
		FillTransparency = 0.4,
		OutlineColor = EfectosHighlight.COLORES.ERROR,
		OutlineTransparency = 0,
		DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- CREAR HIGHLIGHT
-- ═══════════════════════════════════════════════════════════════════════════════

---Crea un Highlight para un objeto
-- @param nombre string - Identificador único para el highlight
-- @param adornee Instance - El objeto a resaltar (Part, Model, etc.)
-- @param tipo string - Tipo de highlight: "ZONA", "SELECCIONADO", "ADYACENTE", "ERROR"
-- @return Highlight - La instancia creada
function EfectosHighlight.crear(nombre, adornee, tipo)
	if not adornee then
		warn("[EfectosHighlight] No se proporcionó adornee para:", nombre)
		return nil
	end
	
	-- Destruir highlight anterior si existe
	EfectosHighlight.destruir(nombre)
	
	local config = EfectosHighlight.CONFIG[tipo] or EfectosHighlight.CONFIG.SELECCIONADO
	
	local highlight = Instance.new("Highlight")
	highlight.Name = "Highlight_" .. nombre
	highlight.Adornee = adornee
	highlight.FillColor = config.FillColor
	highlight.FillTransparency = config.FillTransparency
	highlight.OutlineColor = config.OutlineColor
	highlight.OutlineTransparency = config.OutlineTransparency
	highlight.DepthMode = config.DepthMode
	highlight.Parent = Workspace
	
	highlightsActivos[nombre] = highlight
	
	return highlight
end

---Crea un highlight temporal que se destruye después de un tiempo
-- @param nombre string - Identificador único
-- @param adornee Instance - El objeto a resaltar
-- @param tipo string - Tipo de highlight
-- @param duracion number - Segundos antes de destruir
function EfectosHighlight.flash(nombre, adornee, tipo, duracion)
	duracion = duracion or 0.5
	
	local highlight = EfectosHighlight.crear(nombre, adornee, tipo)
	if not highlight then return end
	
	-- Animar opacidad de outline para hacerlo "pulsar"
	task.spawn(function()
		local inicio = tick()
		while tick() - inicio < duracion do
			if not highlight or not highlight.Parent then break end
			local alpha = (tick() - inicio) / duracion
			-- Pulsación: 0 -> 1 -> 0
			local pulse = math.sin(alpha * math.pi * 4) * 0.5 + 0.5
			highlight.OutlineTransparency = 0.5 - (pulse * 0.5)
			task.wait(0.03)
		end
		
		EfectosHighlight.destruir(nombre)
	end)
	
	return highlight
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- DESTRUIR HIGHLIGHT
-- ═══════════════════════════════════════════════════════════════════════════════

---Destruye un highlight específico
-- @param nombre string - El identificador del highlight
function EfectosHighlight.destruir(nombre)
	local highlight = highlightsActivos[nombre]
	if highlight and highlight.Parent then
		highlight:Destroy()
	end
	highlightsActivos[nombre] = nil
end

---Destruye todos los highlights
function EfectosHighlight.limpiarTodo()
	for nombre, highlight in pairs(highlightsActivos) do
		if highlight and highlight.Parent then
			highlight:Destroy()
		end
	end
	highlightsActivos = {}
end

---Destruye todos los highlights de un tipo específico
-- @param tipo string - El tipo a limpiar
function EfectosHighlight.limpiarPorTipo(tipo)
	for nombre, highlight in pairs(highlightsActivos) do
		if highlight and highlight.Name:find("^Highlight_" .. tipo .. "_") then
			highlight:Destroy()
			highlightsActivos[nombre] = nil
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONSULTAS
-- ═══════════════════════════════════════════════════════════════════════════════

---Verifica si existe un highlight
-- @param nombre string
-- @return boolean
function EfectosHighlight.existe(nombre)
	return highlightsActivos[nombre] ~= nil and highlightsActivos[nombre].Parent ~= nil
end

---Obtiene un highlight activo
-- @param nombre string
-- @return Highlight|nil
function EfectosHighlight.obtener(nombre)
	return highlightsActivos[nombre]
end

---Obtiene todos los highlights activos
-- @return table
function EfectosHighlight.obtenerTodos()
	return highlightsActivos
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPERS PARA NODOS (Integración con sistema de cables)
-- ═══════════════════════════════════════════════════════════════════════════════

---Resalta el modelo completo de un nodo
-- @param nodo Model - El modelo del nodo
-- @param tipo string - Tipo de highlight
-- @return Highlight|nil
function EfectosHighlight.resaltarNodo(nodo, tipo)
	if not nodo then return nil end

	local nombre = "Nodo_" .. nodo.Name
	return EfectosHighlight.crear(nombre, nodo, tipo)
end

---Resalta un nodo con flash temporal (para errores)
-- @param nodo Model - El modelo del nodo
-- @param duracion number - Duración del flash
function EfectosHighlight.flashErrorNodo(nodo, duracion)
	if not nodo then return nil end

	local nombre = "Error_" .. nodo.Name .. "_" .. tick()
	return EfectosHighlight.flash(nombre, nodo, "ERROR", duracion or 0.5)
end

---Resalta un nodo adyacente
-- @param nodo Model - El modelo del nodo adyacente
function EfectosHighlight.resaltarAdyacente(nodo)
	return EfectosHighlight.resaltarNodo(nodo, "ADYACENTE")
end

---Limpia el highlight de un nodo específico
-- @param nodo Model
function EfectosHighlight.limpiarNodo(nodo)
	if not nodo then return end
	local nombre = "Nodo_" .. nodo.Name
	EfectosHighlight.destruir(nombre)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPERS PARA ZONAS
-- ═══════════════════════════════════════════════════════════════════════════════

---Resalta el trigger de una zona
-- @param nombreZona string - Nombre identificador de la zona
-- @param parteTrigger BasePart - La parte del trigger
-- @return Highlight|nil
function EfectosHighlight.resaltarZona(nombreZona, parteTrigger)
	if not parteTrigger then return nil end
	
	local nombre = "Zona_" .. nombreZona
	return EfectosHighlight.crear(nombre, parteTrigger, "ZONA")
end

---Limpia el highlight de una zona
-- @param nombreZona string
function EfectosHighlight.limpiarZona(nombreZona)
	local nombre = "Zona_" .. nombreZona
	EfectosHighlight.destruir(nombre)
end

---Limpia todos los highlights de zonas
function EfectosHighlight.limpiarTodasZonas()
	for nombre, highlight in pairs(highlightsActivos) do
		if nombre:find("^Zona_") then
			if highlight and highlight.Parent then
				highlight:Destroy()
			end
			highlightsActivos[nombre] = nil
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPERS PARA MODO MAPA
-- ═══════════════════════════════════════════════════════════════════════════════

---Crea (o actualiza) el highlight de un nodo en modo mapa según su estado
-- @param nodo Model - El modelo del nodo
-- @param tipo string - "SELECCIONADO" | "ADYACENTE" | "CONECTADO" | "AISLADO"
function EfectosHighlight.resaltarNodoMapa(nodo, tipo)
	if not nodo then return nil end
	local nombre = "MapaNodo_" .. nodo.Name
	return EfectosHighlight.crear(nombre, nodo, tipo)
end

---Limpia únicamente los highlights creados por el modo mapa (prefijo "MapaNodo_")
function EfectosHighlight.limpiarMapaNodos()
	for nombre, highlight in pairs(highlightsActivos) do
		if nombre:find("^MapaNodo_") then
			if highlight and highlight.Parent then
				highlight:Destroy()
			end
			highlightsActivos[nombre] = nil
		end
	end
end

return EfectosHighlight
