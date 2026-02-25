-- LevelsConfig.lua
-- Fuente única de verdad para la configuración de todos los niveles.
-- Ubicación Roblox: ReplicatedStorage/Config/LevelsConfig  (ModuleScript)
-- Accesible tanto desde el servidor (LevelLoader, Boot) como desde el cliente (MenuController).
--
-- Estructura de nodos en Studio (ver ESTRUCTURA_ASSETS_NIVELES.md):
--   NivelActual/Grafos/Grafo_ZonaX/Nodos/<NodoModel>/Selector/Attachment
--
-- Adyacencias (formato lista, igual que GarfosV1):
--   { ["NomNodo"] = {"Vecino1", "Vecino2"} }
--   Directional: si A→B existe pero B→A no, el grafo es dirigido en esa arista.
--   ConectarCables.lua convierte este formato a lookup O(1) al activarse.

return {
	-- ══════════════════════════════════════════════════════════════
	-- NIVEL 0: LABORATORIO DE GRAFOS
	-- ══════════════════════════════════════════════════════════════
	[0] = {
		Nombre      = "Laboratorio de Grafos",
		Modelo      = "Nivel0",
		Algoritmo   = nil,
		Tag         = "NIVEL 0 · FUNDAMENTOS",
		Emoji       = "🧪",
		Descripcion = "Aprende los conceptos básicos de grafos no dirigidos. Conecta los postes de la estación para establecer la red de energía.",
		Conceptos   = {"Nodos", "Aristas", "Adyacencia"},
		Seccion     = "INTRODUCCIÓN A GRAFOS",

		Puntuacion = {
			TresEstrellas  = 1000,
			DosEstrellas   = 600,
			RecompensaXP   = 500,
			BonusTiempo    = {
				Umbral1 = 120,   -- < 2 min → +200 pts
				Umbral2 = 300,   -- < 5 min → +100 pts
			},
			PuntosConexion = 50,  -- pts por cable correcto colocado
			PenaFallo      = 10,  -- pts descontados por intento inválido (al final)
		},

		-- Adyacencias por zona (coincide con los nombres de nodos en Studio)
		-- Zona 1: Nodos y Aristas (grafo no dirigido simple)
		-- Zona 2: Grado de Nodo (estrella: Nodo1_z2 centro, vecinos 2-4)
		-- Zona 3: Grafos Dirigidos (cadena A→B→C, solo un sentido)
		-- Zona 4: Conectividad (grafo conexo)
		Adyacencias = {
			-- ZONA 1 — no dirigido
			["Nodo1_z1"] = {"Nodo2_z1"},
			["Nodo2_z1"] = {"Nodo1_z1"},

			-- ZONA 2 — no dirigido (estrella)
			["Nodo1_z2"] = {"Nodo2_z2", "Nodo3_z2", "Nodo4_z2"},
			["Nodo2_z2"] = {"Nodo1_z2"},
			["Nodo3_z2"] = {"Nodo1_z2"},
			["Nodo4_z2"] = {"Nodo1_z2"},

			-- ZONA 3 — DIRIGIDO (cadena unidireccional)
			-- Nodo1→Nodo2→Nodo3 (solo este sentido es válido)
			["Nodo1_z3"] = {"Nodo2_z3"},
			["Nodo2_z3"] = {"Nodo3_z3"},
			["Nodo3_z3"] = {},    -- nodo destino, sin salidas
			-- Nodo4_z3 es aislado (no aparece → ninguna conexión válida)

			-- ZONA 4 — no dirigido (grafo conexo)
			["Nodo1_z4"] = {"Nodo2_z4", "Nodo3_z4"},
			["Nodo2_z4"] = {"Nodo1_z4", "Nodo3_z4"},
			["Nodo3_z4"] = {"Nodo1_z4", "Nodo2_z4"},
			["Nodo4_z4"] = {"Nodo3_z4", "Nodo2_z4"},

			-- BONUS — no dirigido
			["PostePanel"]      = {"toma_corriente"},
			["toma_corriente"]  = {"PostePanel"},
		},
	},

	-- ══════════════════════════════════════════════════════════════
	-- NIVEL 1: LA RED DESCONECTADA
	-- ══════════════════════════════════════════════════════════════
	[1] = {
		Nombre      = "La Red Desconectada",
		Modelo      = "Nivel1",
		Algoritmo   = "Conectividad",
		Tag         = "NIVEL 1 · CONECTIVIDAD",
		Emoji       = "🏙️",
		Descripcion = "La red urbana está fragmentada. Identifica los componentes y conéctalos para restaurar el servicio.",
		Conceptos   = {"Componentes", "Conectividad", "BFS"},
		Seccion     = "INTRODUCCIÓN A GRAFOS",

		Puntuacion = {
			TresEstrellas  = 1500,
			DosEstrellas   = 900,
			RecompensaXP   = 600,
			BonusTiempo    = { Umbral1 = 150, Umbral2 = 360 },
			PuntosConexion = 50,
			PenaFallo      = 10,
		},

		-- Por definir cuando el modelo de Nivel1 esté en Studio
		Adyacencias = {},
	},

	-- ══════════════════════════════════════════════════════════════
	-- NIVEL 2: LA FÁBRICA DE SEÑALES
	-- ══════════════════════════════════════════════════════════════
	[2] = {
		Nombre      = "La Fábrica de Señales",
		Modelo      = "Nivel2",
		Algoritmo   = "BFS/DFS",
		Tag         = "NIVEL 2 · ALGORITMOS",
		Emoji       = "🏭",
		Descripcion = "Recorre la fábrica usando BFS y DFS para activar todos los nodos de producción en el orden correcto.",
		Conceptos   = {"BFS", "DFS", "Recorrido"},
		Seccion     = "ALGORITMOS DE BÚSQUEDA",

		Puntuacion = {
			TresEstrellas  = 2000,
			DosEstrellas   = 1200,
			RecompensaXP   = 700,
			BonusTiempo    = { Umbral1 = 180, Umbral2 = 420 },
			PuntosConexion = 50,
			PenaFallo      = 15,
		},

		Adyacencias = {},
	},

	-- ══════════════════════════════════════════════════════════════
	-- NIVEL 3: EL PUENTE ROTO
	-- ══════════════════════════════════════════════════════════════
	[3] = {
		Nombre      = "El Puente Roto",
		Modelo      = "Nivel3",
		Algoritmo   = "Grafos Dirigidos",
		Tag         = "NIVEL 3 · GRAFOS DIRIGIDOS",
		Emoji       = "🌉",
		Descripcion = "Los puentes de la ciudad tienen dirección. Planea las rutas de reparación usando grafos dirigidos.",
		Conceptos   = {"Dirigido", "In-degree", "Out-degree"},
		Seccion     = "ALGORITMOS DE BÚSQUEDA",

		Puntuacion = {
			TresEstrellas  = 2500,
			DosEstrellas   = 1500,
			RecompensaXP   = 800,
			BonusTiempo    = { Umbral1 = 200, Umbral2 = 480 },
			PuntosConexion = 50,
			PenaFallo      = 20,
		},

		Adyacencias = {},
	},

	-- ══════════════════════════════════════════════════════════════
	-- NIVEL 4: RUTA MÍNIMA
	-- ══════════════════════════════════════════════════════════════
	[4] = {
		Nombre      = "Ruta Mínima",
		Modelo      = "Nivel4",
		Algoritmo   = "Dijkstra",
		Tag         = "NIVEL 4 · RUTAS ÓPTIMAS",
		Emoji       = "🗺️",
		Descripcion = "Encuentra el camino de menor costo para conectar la red usando el algoritmo de Dijkstra.",
		Conceptos   = {"Dijkstra", "Peso", "Ruta mínima"},
		Seccion     = "RUTAS ÓPTIMAS",

		Puntuacion = {
			TresEstrellas  = 3500,
			DosEstrellas   = 2000,
			RecompensaXP   = 1000,
			BonusTiempo    = { Umbral1 = 240, Umbral2 = 600 },
			PuntosConexion = 60,
			PenaFallo      = 25,
		},

		Adyacencias = {},
	},
}
