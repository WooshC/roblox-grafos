-- ModuloAnalisis/EstadoAnalisis.lua
-- Tabla mutable compartida entre todos los sub-módulos de ModuloAnalisis.
-- Todos los sub-módulos hacen: local E = require(script.Parent.EstadoAnalisis)
-- En ModuloAnalisis.lua (main): local E = require(script.EstadoAnalisis)
--
-- IMPORTANTE: esta tabla se mutea directamente; no hay getters/setters.

local E = {}

-- ── GUI ─────────────────────────────────────────────────────────────
E.hudGui  = nil
E.overlay = nil
E.abierto = false

-- ── Nivel ───────────────────────────────────────────────────────────
E.nivelModel = nil
E.nivelID    = nil

-- ── Remote ──────────────────────────────────────────────────────────
E.grafoCompletoFunc = nil   -- lazy-cached RemoteFunction GetGrafoCompleto

-- ── Datos del grafo / algoritmo ─────────────────────────────────────
E.matrizData  = nil   -- { Headers, Matrix, NombresNodos, EsDirigido }
E.adyacencias = {}    -- { [nombre] = { vecino, ... } }
E.pasos       = {}
E.pasoActual  = 0
E.totalPasos  = 0
E.algoActual  = "bfs"

-- ── Viewport 3D ─────────────────────────────────────────────────────
E.visor           = nil
E.worldModel      = nil
E.camAnalisis     = nil
E.nodoParts       = {}   -- { [nombre] = Part esfera }
E.aristaParts     = {}   -- array de Parts cilíndricas activas
E.posicionesNodos = {}   -- { [nombre] = Vector3 }

-- ── Partículas ───────────────────────────────────────────────────────
E.partActivas = {}   -- { [idConexion] = true }

-- ── Auto-play ────────────────────────────────────────────────────────
E.autoPlaying = false
E.btnEjecRef  = nil

return E
