-- ReplicatedStorage/Config/LevelsConfig.lua
-- FUENTE UNICA DE VERDAD para todos los niveles.
--
-- Campos usados actualmente:
--   Nombre, DescripcionCorta, ImageId, Modelo → MenuController
--   Seccion, Algoritmo, Tag, Conceptos        → MenuController (separadores y tarjetas)
--   Puntuacion.*                               → Boot → ScoreTracker / DataService
--   Adyacencias                                → Boot → ConectarCables
--   Zonas[x].Trigger                           → Boot → ZoneTriggerManager
--   NombresNodos                               → VisualEffectsService (billboard nodo)
--   Misiones                                   → MissionService
--
-- Ubicacion Roblox: ReplicatedStorage/Config/LevelsConfig  (ModuleScript)

local LevelsConfig = {}

-- ============================================
-- NIVEL 0: LABORATORIO DE GRAFOS
-- ============================================
LevelsConfig[0] = {
	Nombre           = "Laboratorio de Grafos",
	DescripcionCorta = "Aprende teoria de grafos a traves de 4 zonas educativas.",
	ImageId          = "rbxassetid://87116895331866",
	Modelo           = "Nivel0",

	-- Metadatos para el selector de niveles
	Tag       = "NIVEL 0 · FUNDAMENTOS",
	Seccion   = "Introduccion",
	Algoritmo = "Grafos No Dirigidos",
	Conceptos = { "Nodos", "Aristas", "Adyacencia", "Grado" },

	Puntuacion = {
		TresEstrellas  = 1250,
		DosEstrellas   = 600,
		RecompensaXP   = 500,
		PuntosConexion = 50,
		PenaFallo      = 10,
	},

	Adyacencias = {
		-- Zona 1: Nodos y Aristas — grafo simple de 2 nodos
		["Nodo1_z1"] = {"Nodo2_z1"},
		["Nodo2_z1"] = {"Nodo1_z1"},

		-- Zona 2: Grado de Nodo — grafo estrella (hub con 4 hojas)
		["NodoCentro_z2"] = {"NodoA_z2", "NodoB_z2", "NodoC_z2", "NodoD_z2"},
		["NodoA_z2"]      = {"NodoCentro_z2"},
		["NodoB_z2"]      = {"NodoCentro_z2"},
		["NodoC_z2"]      = {"NodoCentro_z2"},
		["NodoD_z2"]      = {"NodoCentro_z2"},

		-- Zona 3: Grafos Dirigidos — cadena dirigida A → B → C
		-- (sin reversa: representa direcciones explícitas)
		["NodoA_z3"] = {"NodoB_z3"},
		["NodoB_z3"] = {"NodoC_z3"},
		["NodoC_z3"] = {},

		-- Zona 4: Conectividad — cuatro nodos, dos pares inicialmente aislados
		-- El jugador une los pares y luego los conecta entre sí → grafo conexo
		["NodoA_z4"] = {"NodoB_z4", "NodoC_z4"},
		["NodoB_z4"] = {"NodoA_z4", "NodoD_z4"},
		["NodoC_z4"] = {"NodoA_z4", "NodoD_z4"},
		["NodoD_z4"] = {"NodoB_z4", "NodoC_z4"},

		["PostePanel"]     = {"toma_corriente"},
		["toma_corriente"] = {"PostePanel"},
	},

	Zonas = {
		["Zona_Estacion_1"] = { Trigger = "ZonaTrigger_Estacion1", Descripcion = "Nodos y Aristas"  },
		["Zona_Estacion_2"] = { Trigger = "ZonaTrigger_Estacion2", Descripcion = "Grado de Nodo"    },
		["Zona_Estacion_3"] = { Trigger = "ZonaTrigger_Estacion3", Descripcion = "Grafos Dirigidos" },
		["Zona_Estacion_4"] = { Trigger = "ZonaTrigger_Estacion4", Descripcion = "Conectividad"     },
	},

	NombresNodos = {
		-- Zona 1
		["Nodo1_z1"] = "Nodo 1",
		["Nodo2_z1"] = "Nodo 2",
		-- Zona 2
		["NodoCentro_z2"] = "Nodo Central",
		["NodoA_z2"]      = "Vecino A",
		["NodoB_z2"]      = "Vecino B",
		["NodoC_z2"]      = "Vecino C",
		["NodoD_z2"]      = "Vecino D",
		-- Zona 3
		["NodoA_z3"] = "Nodo A",
		["NodoB_z3"] = "Nodo B",
		["NodoC_z3"] = "Nodo C",
		-- Zona 4
		["NodoA_z4"] = "Nodo A",
		["NodoB_z4"] = "Nodo B",
		["NodoC_z4"] = "Nodo C",
		["NodoD_z4"] = "Nodo D",
		-- Especiales
		["PostePanel"]     = "Panel Central",
		["toma_corriente"] = "Tableta Especial",
	},

	Misiones = {
		-- ── Zona 1: Nodos y Aristas ──────────────────────────────────────────────
		{
			ID     = 1,
			Zona   = "Zona_Estacion_1",
			Texto  = "Selecciona cualquier nodo",
			Tipo   = "NODO_SELECCIONADO",
			Puntos = 100,
			Parametros = { Nodo = "ANY" },
		},
		{
			ID     = 2,
			Zona   = "Zona_Estacion_1",
			Texto  = "Conecta Nodo 1 con Nodo 2",
			Tipo   = "ARISTA_CREADA",
			Puntos = 150,
			Parametros = { NodoA = "Nodo1_z1", NodoB = "Nodo2_z1" },
		},

		-- ── Zona 2: Grado de Nodo ────────────────────────────────────────────────
		{
			ID     = 3,
			Zona   = "Zona_Estacion_2",
			Texto  = "Selecciona el Nodo Central",
			Tipo   = "NODO_SELECCIONADO",
			Puntos = 100,
			Parametros = { Nodo = "NodoCentro_z2" },
		},
		{
			ID     = 4,
			Zona   = "Zona_Estacion_2",
			Texto  = "Conecta 2 vecinos al Nodo Central (grado 2)",
			Tipo   = "GRADO_NODO",
			Puntos = 150,
			Parametros = { Nodo = "NodoCentro_z2", GradoRequerido = 2 },
		},
		{
			ID     = 5,
			Zona   = "Zona_Estacion_2",
			Texto  = "Conecta todos los vecinos al Nodo Central (grado 4)",
			Tipo   = "GRADO_NODO",
			Puntos = 200,
			Parametros = { Nodo = "NodoCentro_z2", GradoRequerido = 4 },
		},

		-- ── Zona 3: Grafos Dirigidos ─────────────────────────────────────────────
		{
			ID     = 6,
			Zona   = "Zona_Estacion_3",
			Texto  = "Selecciona Nodo A",
			Tipo   = "NODO_SELECCIONADO",
			Puntos = 100,
			Parametros = { Nodo = "NodoA_z3" },
		},
		{
			ID     = 7,
			Zona   = "Zona_Estacion_3",
			Texto  = "Conecta Nodo A → Nodo B",
			Tipo   = "ARISTA_CREADA",
			Puntos = 150,
			Parametros = { NodoA = "NodoA_z3", NodoB = "NodoB_z3" },
		},
		{
			ID     = 8,
			Zona   = "Zona_Estacion_3",
			Texto  = "Conecta Nodo B → Nodo C",
			Tipo   = "ARISTA_CREADA",
			Puntos = 150,
			Parametros = { NodoA = "NodoB_z3", NodoB = "NodoC_z3" },
		},

		-- ── Zona 4: Conectividad ─────────────────────────────────────────────────
		{
			ID     = 9,
			Zona   = "Zona_Estacion_4",
			Texto  = "Crea una arista entre Nodo A y Nodo B",
			Tipo   = "ARISTA_CREADA",
			Puntos = 100,
			Parametros = { NodoA = "NodoA_z4", NodoB = "NodoB_z4" },
		},
		{
			ID     = 10,
			Zona   = "Zona_Estacion_4",
			Texto  = "Conecta Nodo C con Nodo D",
			Tipo   = "ARISTA_CREADA",
			Puntos = 100,
			Parametros = { NodoA = "NodoC_z4", NodoB = "NodoD_z4" },
		},
		{
			ID     = 11,
			Zona   = "Zona_Estacion_4",
			Texto  = "Haz que el grafo sea completamente conexo",
			Tipo   = "GRAFO_CONEXO",
			Puntos = 300,
			Parametros = { Nodos = {"NodoA_z4", "NodoB_z4", "NodoC_z4", "NodoD_z4"} },
		},
	},

	-- Secuencia de guia visual: un objetivo por zona.
	-- GuiaService avanza automaticamente cuando todas las misiones de la zona se completan.
	-- Para avance manual: require(GuiaService).GuiaAvanzar:Fire("carlos")
	Guia = {
		-- 0. Hablar con Carlos (Part pre-colocada en workspace/Navegacion/Waypoints/)
		--    Avanzar desde el dialogo: require(GuiaService).GuiaAvanzar:Fire("carlos")
		{
			ID    = "carlos",
			Label = "Hablar con Carlos",
			WaypointRef = {
				Tipo     = "PART_DIRECTA",
				BuscarEn = "NIVEL_ACTUAL",
				Nombre   = "Objetivo_Carlos",  -- busqueda recursiva en NivelActual
			},
			DestruirAlCompletar = false,
		},
		{
			ID    = "estacion_1",
			Zona  = "Zona_Estacion_1",
			Label = "Ve a la Estacion 1",
			WaypointRef = {
				Tipo     = "PART_DIRECTA",
				BuscarEn = "NIVEL_ACTUAL",
				Nombre   = "ZonaTrigger_Estacion1",
			},
			DestruirAlCompletar = false,
		},
		{
			ID    = "estacion_2",
			Zona  = "Zona_Estacion_2",
			Label = "Ve a la Estacion 2",
			WaypointRef = {
				Tipo     = "PART_DIRECTA",
				BuscarEn = "NIVEL_ACTUAL",
				Nombre   = "ZonaTrigger_Estacion2",
			},
			DestruirAlCompletar = false,
		},
		{
			ID    = "estacion_3",
			Zona  = "Zona_Estacion_3",
			Label = "Ve a la Estacion 3",
			WaypointRef = {
				Tipo     = "PART_DIRECTA",
				BuscarEn = "NIVEL_ACTUAL",
				Nombre   = "ZonaTrigger_Estacion3",
			},
			DestruirAlCompletar = false,
		},
		{
			ID    = "estacion_4",
			Zona  = "Zona_Estacion_4",
			Label = "Ve a la Estacion 4",
			WaypointRef = {
				Tipo     = "PART_DIRECTA",
				BuscarEn = "NIVEL_ACTUAL",
				Nombre   = "ZonaTrigger_Estacion4",
			},
			DestruirAlCompletar = false,
		},
	},
}

-- ============================================
-- NIVEL 1: LA RED DESCONECTADA
-- ============================================
LevelsConfig[1] = {
	Nombre           = "La Red Desconectada",
	DescripcionCorta = "Identifica componentes y conectalos para restaurar la red.",
	ImageId          = "rbxassetid://1234567891",
	Modelo           = "Nivel1",

	Tag       = "NIVEL 1 · CONECTIVIDAD",
	Seccion   = "Busqueda y Conectividad",
	Algoritmo = "BFS / Componentes Conexas",
	Conceptos = { "Conectividad", "Componentes", "BFS", "Caminos" },

	Puntuacion = { TresEstrellas=1500, DosEstrellas=900, RecompensaXP=150, PuntosConexion=50, PenaFallo=10 },
	Adyacencias  = {},
	Zonas        = {},
	NombresNodos = {},
	Misiones     = {},
}

-- ============================================
-- NIVEL 2: LA FABRICA DE SENALES
-- ============================================
LevelsConfig[2] = {
	Nombre           = "La Fabrica de Senales",
	DescripcionCorta = "Recorre la fabrica aplicando BFS y DFS para procesar senales.",
	ImageId          = "rbxassetid://1234567892",
	Modelo           = "Nivel2",

	Tag       = "NIVEL 2 · RECORRIDOS",
	Seccion   = "Busqueda y Conectividad",
	Algoritmo = "BFS · DFS",
	Conceptos = { "BFS", "DFS", "Recorrido", "Cola", "Pila" },

	Puntuacion = { TresEstrellas=2500, DosEstrellas=1500, RecompensaXP=200, PuntosConexion=50, PenaFallo=10 },
	Adyacencias  = {},
	Zonas        = {},
	NombresNodos = {},
	Misiones     = {},
}

-- ============================================
-- NIVEL 3: EL PUENTE ROTO
-- ============================================
LevelsConfig[3] = {
	Nombre           = "El Puente Roto",
	DescripcionCorta = "Los puentes tienen direccion. Aprende grafos dirigidos.",
	ImageId          = "rbxassetid://1234567893",
	Modelo           = "Nivel3",

	Tag       = "NIVEL 3 · GRAFOS DIRIGIDOS",
	Seccion   = "Grafos Dirigidos",
	Algoritmo = "Grafos Dirigidos",
	Conceptos = { "Dirigido", "In-degree", "Out-degree", "Ciclos" },

	Puntuacion = { TresEstrellas=4000, DosEstrellas=2500, RecompensaXP=300, PuntosConexion=50, PenaFallo=10 },
	Adyacencias  = {},
	Zonas        = {},
	NombresNodos = {},
	Misiones     = {},
}

-- ============================================
-- NIVEL 4: RUTA MINIMA
-- ============================================
LevelsConfig[4] = {
	Nombre           = "Ruta Minima",
	DescripcionCorta = "Encuentra el camino de menor costo con el algoritmo de Dijkstra.",
	ImageId          = "rbxassetid://1234567894",
	Modelo           = "Nivel4",

	Tag       = "NIVEL 4 · RUTAS OPTIMAS",
	Seccion   = "Algoritmos de Ruta",
	Algoritmo = "Dijkstra",
	Conceptos = { "Dijkstra", "Peso", "Ruta minima", "Greedy" },

	Puntuacion = { TresEstrellas=8000, DosEstrellas=5000, RecompensaXP=500, PuntosConexion=50, PenaFallo=10 },
	Adyacencias  = {},
	Zonas        = {},
	NombresNodos = {},
	Misiones     = {},
}

return LevelsConfig
