-- ModuloAnalisis/EstadoAnalisis.lua
-- Tabla mutable compartida entre todos los sub-módulos de ModuloAnalisis.

local E = {}

-- ── GUI ─────────────────────────────────────────────────────────────
E.hudGui  = nil
E.overlay = nil
E.abierto = false

-- ── Nivel ───────────────────────────────────────────────────────────
E.nivelModel = nil
E.nivelID    = nil

-- ── Remote ──────────────────────────────────────────────────────────
E.grafoCompletoFunc = nil

-- ── Datos del grafo / algoritmo ─────────────────────────────────────
E.matrizData    = nil   -- { Headers, Matrix, NombresNodos, EsDirigido }
E.adyacencias   = {}
E.pasos         = {}
E.pasoActual    = 0
E.totalPasos    = 0
E.algoActual    = "bfs"

-- ── Configuración del analizador (de LevelsConfig.AnalisisConfig[zona]) ─
E.analisisConfig  = nil   -- toda la tabla de la zona activa
E.nodoInicio      = nil   -- string: nodo desde el que arranca el algoritmo
E.nodoFin         = nil   -- string | nil: nodo destino para Dijkstra

-- ── Viewport 3D ─────────────────────────────────────────────────────
E.visor           = nil
E.worldModel      = nil
E.camAnalisis     = nil
E.nodoParts       = {}
E.aristaParts     = {}
E.posicionesNodos = {}

-- ── Partículas ───────────────────────────────────────────────────────
E.partActivas = {}

-- ── Auto-play ────────────────────────────────────────────────────────
E.autoPlaying = false
E.btnEjecRef  = nil

return E