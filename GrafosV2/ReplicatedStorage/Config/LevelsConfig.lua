-- ReplicatedStorage/Config/LevelsConfig.lua
-- FUENTE ÚNICA DE VERDAD para todos los niveles.
--
-- Campos usados actualmente:
--   Nombre, DescripcionCorta, ImageId, Modelo → MenuController
--   Puntuacion.*                               → Boot → ScoreTracker / DataService
--   Adyacencias                                → Boot → ConectarCables
--   Zonas[x].Trigger                           → Boot → ZoneTriggerManager
--   NombresNodos                               → VisualEffectsService (billboard nodo)
--   Misiones                                   → MissionService
--
-- Ubicación Roblox: ReplicatedStorage/Config/LevelsConfig  (ModuleScript)

local LevelsConfig = {}

-- ============================================
-- NIVEL 0: LABORATORIO DE GRAFOS
-- ============================================
LevelsConfig[0] = {
	Nombre           = "Laboratorio de Grafos",
	DescripcionCorta = "Aprende teoría de grafos a través de 4 zonas educativas.",
	ImageId          = "rbxassetid://87116895331866",
	Modelo           = "Nivel0",

	Puntuacion = {
		TresEstrellas  = 1250,
		DosEstrellas   = 600,
		RecompensaXP   = 500,
		PuntosConexion = 50,
		PenaFallo      = 10,
	},

	-- Qué conexiones son válidas. Boot pasa esto a ConectarCables.
	Adyacencias = {
		["Nodo1_z1"] = {"Nodo2_z1"},
		["Nodo2_z1"] = {"Nodo1_z1"},

		["Nodo1_z2"] = {"Nodo2_z2", "Nodo3_z2", "Nodo4_z2"},
		["Nodo2_z2"] = {"Nodo1_z2"},
		["Nodo3_z2"] = {"Nodo1_z2"},
		["Nodo4_z2"] = {"Nodo1_z2"},

		["Nodo1_z3"] = {"Nodo2_z3"},
		["Nodo2_z3"] = {"Nodo3_z3"},
		["Nodo3_z3"] = {},

		["Nodo1_z4"] = {"Nodo2_z4", "Nodo3_z4"},
		["Nodo2_z4"] = {"Nodo1_z4", "Nodo3_z4"},
		["Nodo3_z4"] = {"Nodo1_z4", "Nodo2_z4"},
		["Nodo4_z4"] = {"Nodo3_z4", "Nodo2_z4"},

		["PostePanel"]     = {"toma_corriente"},
		["toma_corriente"] = {"PostePanel"},
	},

	-- Trigger = BasePart en NivelActual/Zonas/Zonas_juego/
	Zonas = {
		["Zona_Estacion_1"] = { Trigger = "ZonaTrigger_Estacion1", Descripcion = "Nodos y Aristas" },
		["Zona_Estacion_2"] = { Trigger = "ZonaTrigger_Estacion2", Descripcion = "Grado de Nodo"  },
		["Zona_Estacion_3"] = { Trigger = "ZonaTrigger_Estacion3", Descripcion = "Grafos Dirigidos"},
		["Zona_Estacion_4"] = { Trigger = "ZonaTrigger_Estacion4", Descripcion = "Conectividad"   },
	},

	-- Nombres amigables mostrados en el BillboardGui de cada nodo
	NombresNodos = {
		["Nodo1_z1"] = "Nodo 1",    ["Nodo2_z1"] = "Nodo 2",
		["Nodo1_z2"] = "Centro",    ["Nodo2_z2"] = "Vecino 1",
		["Nodo3_z2"] = "Vecino 2",  ["Nodo4_z2"] = "Vecino 3",
		["Nodo1_z3"] = "Nodo X",    ["Nodo2_z3"] = "Nodo Y",    ["Nodo3_z3"] = "Nodo Z",
		["Nodo4_z3"] = "Nodo W",
		["Nodo1_z4"] = "Nodo 1",    ["Nodo2_z4"] = "Nodo 2",    ["Nodo3_z4"] = "Nodo 3",
		["Nodo4_z4"] = "Nodo 4",
		["PostePanel"]     = "Panel Central",
		["toma_corriente"] = "Tableta Especial",
	},

	-- Misiones ordenadas por zona. MissionService las valida en tiempo real.
	-- Tipos de misión:
	--   ARISTA_CREADA    → cable existe entre NodoA y NodoB
	--   ARISTA_DIRIGIDA  → cable existe entre NodoOrigen y NodoDestino (dirección documentada)
	--   GRADO_NODO       → nodo Nodo tiene al menos GradoRequerido cables conectados
	--   NODO_SELECCIONADO→ nodo Nodo fue clickeado al menos una vez
	--   GRAFO_CONEXO     → todos los Nodos son alcanzables entre sí
	Misiones = {
		{ ID=1, Zona="Zona_Estacion_1", Texto="Selecciona cualquier nodo",                   Tipo="NODO_SELECCIONADO", Puntos=100, Parametros={Nodo="Nodo1_z1"} },
		{ ID=2, Zona="Zona_Estacion_1", Texto="Conecta Nodo 1 con Nodo 2 (crea una arista)", Tipo="ARISTA_CREADA",     Puntos=150, Parametros={NodoA="Nodo1_z1", NodoB="Nodo2_z1"} },
	},
}

-- ============================================
-- NIVEL 1 — stub
-- ============================================
LevelsConfig[1] = {
	Nombre           = "La Red Desconectada",
	DescripcionCorta = "Identifica componentes y conéctalos para restaurar la red.",
	ImageId          = "rbxassetid://1234567891",
	Modelo           = "Nivel1",
	Puntuacion = { TresEstrellas=1500, DosEstrellas=900, RecompensaXP=150, PuntosConexion=50, PenaFallo=10 },
	Adyacencias = {},
	Zonas       = {},
	NombresNodos = {},
	Misiones     = {},
}

-- ============================================
-- NIVEL 2 — stub
-- ============================================
LevelsConfig[2] = {
	Nombre           = "La Fábrica de Señales",
	DescripcionCorta = "Una zona más amplia requiere planificación cuidadosa.",
	ImageId          = "rbxassetid://1234567892",
	Modelo           = "Nivel2",
	Puntuacion = { TresEstrellas=2500, DosEstrellas=1500, RecompensaXP=200, PuntosConexion=50, PenaFallo=10 },
	Adyacencias = {},
	Zonas       = {},
	NombresNodos = {},
	Misiones     = {},
}

-- ============================================
-- NIVEL 3 — stub
-- ============================================
LevelsConfig[3] = {
	Nombre           = "El Puente Roto",
	DescripcionCorta = "Alta demanda de energía y rutas costosas.",
	ImageId          = "rbxassetid://1234567893",
	Modelo           = "Nivel3",
	Puntuacion = { TresEstrellas=4000, DosEstrellas=2500, RecompensaXP=300, PuntosConexion=50, PenaFallo=10 },
	Adyacencias = {},
	Zonas       = {},
	NombresNodos = {},
	Misiones     = {},
}

-- ============================================
-- NIVEL 4 — stub
-- ============================================
LevelsConfig[4] = {
	Nombre           = "Ruta Mínima",
	DescripcionCorta = "El desafío final de optimización.",
	ImageId          = "rbxassetid://1234567894",
	Modelo           = "Nivel4",
	Puntuacion = { TresEstrellas=8000, DosEstrellas=5000, RecompensaXP=500, PuntosConexion=50, PenaFallo=10 },
	Adyacencias = {},
	Zonas       = {},
	NombresNodos = {},
	Misiones     = {},
}

return LevelsConfig
