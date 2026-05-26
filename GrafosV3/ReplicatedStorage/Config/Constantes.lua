-- ReplicatedStorage/Config/Constantes.lua
-- Constantes centralizadas del proyecto GrafosV3.
-- Evita magic numbers y magic strings repetidos en múltiples archivos.

local Constantes = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- ILUMINACIÓN
-- ═══════════════════════════════════════════════════════════════════════════════

Constantes.ILUMINACION_DEFAULT = Color3.fromRGB(128, 128, 128)
Constantes.HORA_DIA_DEFAULT    = 14
Constantes.HORA_NOCHE_DEFAULT  = 0

-- ═══════════════════════════════════════════════════════════════════════════════
-- TIMER DE EMERGENCIA
-- ═══════════════════════════════════════════════════════════════════════════════

Constantes.TIMER_EMERGENCIA_TIEMPO_LIMITE_DEFAULT = 60
Constantes.TIMER_EMERGENCIA_PENALIZACION_FALLO    = -500

-- ═══════════════════════════════════════════════════════════════════════════════
-- PUNTUACIÓN
-- ═══════════════════════════════════════════════════════════════════════════════

Constantes.PUNTOS_PREGUNTA_CORRECTA = 100
Constantes.PUNTOS_CONEXION_DEFAULT  = 50

-- ═══════════════════════════════════════════════════════════════════════════════
-- MOVIMIENTO DEL JUGADOR (valores por defecto de Roblox)
-- ═══════════════════════════════════════════════════════════════════════════════

Constantes.WALK_SPEED_DEFAULT  = 16
Constantes.JUMP_POWER_DEFAULT  = 50
Constantes.JUMP_HEIGHT_DEFAULT = 7.2

-- ═══════════════════════════════════════════════════════════════════════════════
-- COLORES UI (HUD)
-- ═══════════════════════════════════════════════════════════════════════════════

Constantes.COLOR_HUD_VERDE   = Color3.fromRGB(46, 204, 64)
Constantes.COLOR_HUD_AMARILLO = Color3.fromRGB(241, 196, 15)
Constantes.COLOR_HUD_ROJO    = Color3.fromRGB(231, 76, 60)

return Constantes
