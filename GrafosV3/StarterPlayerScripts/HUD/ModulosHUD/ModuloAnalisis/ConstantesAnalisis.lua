-- ModuloAnalisis/ConstantesAnalisis.lua
-- Colores, tamaños, velocidades y helpers UI sin dependencias externas.

local C = {}

-- ── Colores de nodos ─────────────────────────────────────────────────
C.COL_DEFAULT   = Color3.fromRGB(100, 116, 139)  -- gris  (sin visitar)
C.COL_ACTUAL    = Color3.fromRGB(251, 146,  60)  -- naranja (nodo actual)
C.COL_VISITADO  = Color3.fromRGB( 34, 197,  94)  -- verde  (visitado)
C.COL_PENDIENTE = Color3.fromRGB( 59, 130, 246)  -- azul   (en cola/pila)

-- ── Colores de aristas ───────────────────────────────────────────────
C.COL_ARISTA_NUEVA   = Color3.fromRGB(251, 146,  60)  -- naranja: arista recién creada
C.COL_ARISTA_VISIT   = Color3.fromRGB( 34, 197,  94)  -- verde:   arista ya recorrida
C.COL_ARISTA_DEFAULT = Color3.fromRGB(100, 116, 139)  -- gris:    arista no recorrida aún

-- ── Colores pseudocódigo ─────────────────────────────────────────────
C.COL_LINEA_ACTIVA = Color3.fromRGB(251, 146,  60)
C.COL_LINEA_NORMAL = Color3.fromRGB(176, 190, 197)

-- ── Colores pills ────────────────────────────────────────────────────
C.COL_PILL_ACTIVO   = Color3.fromRGB( 59, 130, 246)
C.COL_PILL_INACTIVO = Color3.fromRGB( 30,  41,  59)

-- ── Colores partículas ───────────────────────────────────────────────
C.COL_PART_NUEVA  = Color3.fromRGB(251, 146,  60)  -- naranja en arista nueva
C.COL_PART_VISIT  = Color3.fromRGB( 34, 197,  94)  -- verde en aristas visitadas

-- ── Tamaños / velocidades ────────────────────────────────────────────
C.TAM_NODO    = 3      -- esfera nodo (studs)
C.TAM_ARISTA  = 0.4   -- cilindro arista
C.TAM_PART    = 2.0   -- bola partícula
C.VEL_PART    = 40    -- studs/segundo
C.FREQ_PART   = 1.2   -- segundos entre disparos por dirección
C.VEL_AUTO    = 1.3   -- segundos entre pasos del auto-play

-- ── Helpers UI ───────────────────────────────────────────────────────

function C.buscar(parent, nombre)
	if not parent then return nil end
	return parent:FindFirstChild(nombre, true)
end

function C.addCorner(parent, r)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, r or 4)
	corner.Parent = parent
end

return C
