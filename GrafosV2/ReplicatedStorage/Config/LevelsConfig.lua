-- ReplicatedStorage/Config/LevelsConfig.lua
-- FUENTE ÚNICA DE VERDAD para todos los niveles.
-- Este archivo REEMPLAZA al stub minimal que existía en GrafosV2.
-- Es idéntico en estructura al de GarfosV1 pero vive en ReplicatedStorage/Config/
-- para que tanto el servidor (DataService, LevelLoader) como el cliente (MenuController)
-- lo usen sin duplicar datos.
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
	Descripcion      = "Bienvenido al Laboratorio. Aprenderás sobre grafos desde lo básico hasta conceptos avanzados.",
	DineroInicial    = 0,
	CostoPorMetro    = 0,
	Algoritmo        = nil,
	CondicionVictoria = "ZONAS_COMPLETAS",

	Puntuacion = {
		TresEstrellas  = 1000,
		DosEstrellas   = 600,
		RecompensaXP   = 500,
		PuntosConexion = 50,
		PenaFallo      = 10,
		BonusTiempo    = { Umbral1 = 120, Umbral2 = 300 },
	},

	Audio = {
		Ambiente    = "Nivel0",
		Victoria    = "Fanfare",
		TemaVictoria = "Tema",
	},

	NodoInicio   = "PostePanel",
	NodoFin      = "PostePanel",
	NodosTotales = 13,

	Adyacencias = {
		["Nodo1_z1"] = {"Nodo2_z1"},
		["Nodo2_z1"] = {"Nodo1_z1"},

		["Nodo1_z2"] = {"Nodo2_z2", "Nodo3_z2","Nodo4_z2"},
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

		["PostePanel"] = {"toma_corriente"},
		["toma_corriente"] = {"PostePanel"},
	},

	Misiones = {
		{ ID=1, Zona="Zona_Estacion_1", Texto="Selecciona un nodo para ver su definición",    Tipo="NODO_SELECCIONADO", Puntos=100, Parametros={Nodo="Nodo1_z1"} },
		{ ID=2, Zona="Zona_Estacion_1", Texto="Conecta Nodo 1 con Nodo 2 (crea una arista)",  Tipo="ARISTA_CREADA",     Puntos=150, Parametros={NodoA="Nodo1_z1",NodoB="Nodo2_z1"} },
		{ ID=3, Zona="Zona_Estacion_2", Texto="Conecta un vecino al centro (grado 1)",         Tipo="GRADO_NODO",        Puntos=150, Parametros={Nodo="Nodo1_z2",GradoRequerido=1} },
		{ ID=4, Zona="Zona_Estacion_2", Texto="Conecta los tres vecinos al centro (grado 3)",  Tipo="GRADO_NODO",        Puntos=300, Parametros={Nodo="Nodo1_z2",GradoRequerido=3} },
		{ ID=5, Zona="Zona_Estacion_3", Texto="Crea la arista dirigida Nodo X → Nodo Y",       Tipo="ARISTA_DIRIGIDA",   Puntos=150, Parametros={NodoOrigen="Nodo1_z3",NodoDestino="Nodo2_z3"} },
		{ ID=6, Zona="Zona_Estacion_3", Texto="Completa la cadena: Nodo Y → Nodo Z",           Tipo="ARISTA_DIRIGIDA",   Puntos=150, Parametros={NodoOrigen="Nodo2_z3",NodoDestino="Nodo3_z3"} },
		{ ID=7, Zona="Zona_Estacion_4", Texto="Construye un grafo conexo (todos alcanzables)", Tipo="GRAFO_CONEXO",      Puntos=250, Parametros={Nodos={"Nodo1_z4","Nodo2_z4","Nodo3_z4"}} },
		{ ID=8, Zona=nil,               Texto="BONUS: Conecta la Tableta con el Panel",        Tipo="ARISTA_CREADA",     Puntos=500, Parametros={NodoA="PostePanel",NodoB="toma_corriente"} },
	},

	Objetos = {
		{ ID="Tableta_Especial",  Nombre="Tableta Educativa",    Descripcion="Item especial del bonus",       Icono="📱", Modelo="Tableta" },
		{ ID="Mapa",              Nombre="Mapa del Laboratorio", Descripcion="Desbloquea la vista de mapa",   Icono="🗺️", Modelo="MapaModel" },
		{ ID="Algoritmo_BFS",     Nombre="Manual de BFS",        Descripcion="Desbloquea el algoritmo BFS",  Icono="🧠", Modelo="AlgoritmoBFS" },
	},

	Nodos = {
		["Nodo1_z1"] = { Zona="Zona_Estacion_1", Alias="Nodo 1",   Descripcion="Un nodo es un punto en el grafo." },
		["Nodo2_z1"] = { Zona="Zona_Estacion_1", Alias="Nodo 2",   Descripcion="La conexión entre dos nodos es una arista." },
		["Nodo1_z2"] = { Zona="Zona_Estacion_2", Alias="Centro",   Descripcion="Nodo central. Su GRADO es el número de aristas conectadas." },
		["Nodo2_z2"] = { Zona="Zona_Estacion_2", Alias="Vecino 1", Descripcion="Conecta al centro para aumentar el grado." },
		["Nodo3_z2"] = { Zona="Zona_Estacion_2", Alias="Vecino 2", Descripcion="Segundo vecino. Incrementará el grado a 2." },
		["Nodo4_z2"] = { Zona="Zona_Estacion_2", Alias="Vecino 3", Descripcion="Tercer vecino. Incrementará el grado a 3." },
		["Nodo1_z3"] = { Zona="Zona_Estacion_3", Alias="Nodo X",   Descripcion="Nodo origen. Aristas dirigidas tienen DIRECCIÓN." },
		["Nodo2_z3"] = { Zona="Zona_Estacion_3", Alias="Nodo Y",   Descripcion="Nodo intermedio. Recibe de X, envía a Z." },
		["Nodo3_z3"] = { Zona="Zona_Estacion_3", Alias="Nodo Z",   Descripcion="Nodo destino. Solo tiene entrada." },
		["Nodo4_z3"] = { Zona="Zona_Estacion_3", Alias="Nodo W",   Descripcion="Nodo Aislado. No tiene vecinos." },
		["Nodo1_z4"] = { Zona="Zona_Estacion_4", Alias="Nodo 1",   Descripcion="Conecta a todos para un GRAFO CONEXO." },
		["Nodo2_z4"] = { Zona="Zona_Estacion_4", Alias="Nodo 2",   Descripcion="Segundo vértice." },
		["Nodo3_z4"] = { Zona="Zona_Estacion_4", Alias="Nodo 3",   Descripcion="Todos deben ser alcanzables entre sí." },
		["Nodo4_z4"] = { Zona="Zona_Estacion_4", Alias="Nodo 4",   Descripcion="Todos deben ser alcanzables entre sí." },
		PostePanel      = { Zona=nil, Alias="🔌 Panel Central",    Descripcion="Panel principal del laboratorio." },
		toma_corriente  = { Zona=nil, Alias="⭐ Tableta Especial", Descripcion="BONUS: Conecta esta tableta." },
	},

	-- Trigger = nombre de la BasePart en NivelActual/Zonas/Zonas_juego/
	-- Zonas con Oculta=true no tienen Trigger (GameplayManager las omite)
	Zonas = {
		["Zona_Estacion_1"] = { Modo="ALL", Descripcion="🟢 ZONA 1: Nodos y Aristas",    Color=Color3.fromRGB(65,105,225),  Concepto="Fundamentos",        NodosRequeridos={"Nodo1_z1","Nodo2_z1"},            Trigger="ZonaTrigger_Estacion1" },
		["Zona_Estacion_2"] = { Modo="ALL", Descripcion="🔵 ZONA 2: Grado de Nodo",       Color=Color3.fromRGB(34,139,34),   Concepto="Propiedades Locales", NodosRequeridos={"Nodo1_z2","Nodo2_z2","Nodo3_z2"}, Trigger="ZonaTrigger_Estacion2" },
		["Zona_Estacion_3"] = { Modo="ALL", Descripcion="🟡 ZONA 3: Grafos Dirigidos",    Color=Color3.fromRGB(220,20,60),   Concepto="Direccionalidad",    NodosRequeridos={"Nodo1_z3","Nodo2_z3","Nodo3_z3"}, Trigger="ZonaTrigger_Estacion3" },
		["Zona_Estacion_4"] = { Modo="ALL", Descripcion="🔴 ZONA 4: Conectividad",         Color=Color3.fromRGB(184,134,11),  Concepto="Propiedades Globales",NodosRequeridos={"Nodo1_z4","Nodo2_z4","Nodo3_z4"}, Trigger="ZonaTrigger_Estacion4" },
		["Zona_luz_1"]      = { Modo="ALL", Descripcion="Sector principal: Torre de Control", NodosRequeridos={"toma_corriente"}, Oculta=true },
		["Zona_luz_2"]      = { Modo="ANY", Descripcion="Sector secundario: Puerta",          NodosRequeridos={"toma_corriente"}, Oculta=true },
	},

	NombresPostes = {
		["Nodo1_z1"]="Nodo 1",  ["Nodo2_z1"]="Nodo 2",
		["Nodo1_z2"]="Centro",  ["Nodo2_z2"]="Vecino 1", ["Nodo3_z2"]="Vecino 2", ["Nodo4_z2"]="Vecino 3",
		["Nodo1_z3"]="Nodo X",  ["Nodo2_z3"]="Nodo Y",   ["Nodo3_z3"]="Nodo Z",
		["Nodo1_z4"]="Nodo 1",  ["Nodo2_z4"]="Nodo 2",   ["Nodo3_z4"]="Nodo 3",
		["PostePanel"]="Panel Central", ["toma_corriente"]="Tableta Especial",
	},

	Guia = {
		{ ID="carlos", Label="Hablar con Carlos",   WaypointRef={Tipo="PART_EXISTENTE", Nombre="Objetivo_Carlos"}, DestruirAlCompletar=true },
		{ ID="zona1",  Zona="Zona_Estacion_1",      WaypointRef={Tipo="PART_DIRECTA",   BuscarEn="NIVEL_ACTUAL", Ruta={"Objetos","Postes","Nodo1_z1","Selector"}}, DestruirAlCompletar=false },
		{ ID="zona2",  Zona="Zona_Estacion_2",      WaypointRef={Tipo="SOBRE_OBJETO",   Nombre="Zona_Estacion_2", BuscarEn="NIVEL_ACTUAL", OffsetY=6}, DestruirAlCompletar=true },
		{ ID="zona3",  Zona="Zona_Estacion_3",      WaypointRef={Tipo="SOBRE_OBJETO",   Nombre="Zona_Estacion_3", BuscarEn="NIVEL_ACTUAL", OffsetY=6}, DestruirAlCompletar=true },
		{ ID="zona4",  Zona="Zona_Estacion_4",      WaypointRef={Tipo="SOBRE_OBJETO",   Nombre="Zona_Estacion_4", BuscarEn="NIVEL_ACTUAL", OffsetY=6}, DestruirAlCompletar=false },
	},
}

-- ============================================
-- NIVEL 1: LA RED DESCONECTADA
-- ============================================
LevelsConfig[1] = {
	Nombre           = "La Red Desconectada",
	DescripcionCorta = "Identifica componentes y conéctalos para restaurar la red.",
	ImageId          = "rbxassetid://1234567891",
	Modelo           = "Nivel1",
	Descripcion      = "La red urbana está fragmentada. Identifica los componentes y conéctalos para restaurar el servicio.",
	DineroInicial    = 5000,
	CostoPorMetro    = 25,
	Algoritmo        = "Conectividad",
	CondicionVictoria = "CIRCUITO_CERRADO",

	Puntuacion = {
		TresEstrellas  = 1500,
		DosEstrellas   = 900,
		RecompensaXP   = 150,
		PuntosConexion = 50,
		PenaFallo      = 10,
		BonusTiempo    = { Umbral1 = 180, Umbral2 = 360 },
	},

	Audio = { Ambiente="Nivel1", Victoria="Fanfare", TemaVictoria="Tema" },
	Adyacencias = {},
	Misiones     = { { ID=1, Texto="Completa el circuito", Tipo="CIRCUITO_CERRADO", Parametros={} } },
	Nodos        = {},
	NombresPostes = {},
	Zonas        = {},
}

-- ============================================
-- NIVEL 2: LA FÁBRICA DE SEÑALES
-- ============================================
LevelsConfig[2] = {
	Nombre           = "La Fábrica de Señales",
	DescripcionCorta = "Una zona más amplia requiere planificación cuidadosa.",
	ImageId          = "rbxassetid://1234567892",
	Modelo           = "Nivel2",
	Descripcion      = "La ciudad crece. Conecta los nuevos distritos comerciales.",
	DineroInicial    = 8000,
	CostoPorMetro    = 35,
	Algoritmo        = "BFS/DFS",
	CondicionVictoria = "CIRCUITO_CERRADO",

	Puntuacion = {
		TresEstrellas  = 2500,
		DosEstrellas   = 1500,
		RecompensaXP   = 200,
		PuntosConexion = 50,
		PenaFallo      = 10,
		BonusTiempo    = { Umbral1 = 180, Umbral2 = 420 },
	},

	Audio = { Ambiente="Nivel2", Victoria="Fanfare", TemaVictoria="Tema" },
	Adyacencias = {},
	Misiones     = { { ID=1, Texto="Completa el circuito", Tipo="CIRCUITO_CERRADO", Parametros={} } },
	Nodos        = {},
	NombresPostes = {},
	Zonas        = {},
}

-- ============================================
-- NIVEL 3: EL PUENTE ROTO
-- ============================================
LevelsConfig[3] = {
	Nombre           = "El Puente Roto",
	DescripcionCorta = "Alta demanda de energía y rutas costosas.",
	ImageId          = "rbxassetid://1234567893",
	Modelo           = "Nivel3",
	Descripcion      = "Las fábricas necesitan potencia estable.",
	DineroInicial    = 12000,
	CostoPorMetro    = 50,
	Algoritmo        = "Grafos Dirigidos",
	CondicionVictoria = "CIRCUITO_CERRADO",

	Puntuacion = {
		TresEstrellas  = 4000,
		DosEstrellas   = 2500,
		RecompensaXP   = 300,
		PuntosConexion = 50,
		PenaFallo      = 10,
		BonusTiempo    = { Umbral1 = 180, Umbral2 = 480 },
	},

	Audio = { Ambiente="Nivel3", Victoria="Fanfare", TemaVictoria="Tema" },
	Adyacencias = {},
	Misiones     = { { ID=1, Texto="Completa el circuito", Tipo="CIRCUITO_CERRADO", Parametros={} } },
	Nodos        = {},
	NombresPostes = {},
	Zonas        = {},
}

-- ============================================
-- NIVEL 4: RUTA MÍNIMA
-- ============================================
LevelsConfig[4] = {
	Nombre           = "Ruta Mínima",
	DescripcionCorta = "El desafío final de optimización.",
	ImageId          = "rbxassetid://1234567894",
	Modelo           = "Nivel4",
	Descripcion      = "Toda la ciudad depende de ti.",
	DineroInicial    = 20000,
	CostoPorMetro    = 45,
	Algoritmo        = "Dijkstra",
	CondicionVictoria = "CIRCUITO_CERRADO",

	Puntuacion = {
		TresEstrellas  = 8000,
		DosEstrellas   = 5000,
		RecompensaXP   = 500,
		PuntosConexion = 50,
		PenaFallo      = 10,
		BonusTiempo    = { Umbral1 = 180, Umbral2 = 540 },
	},

	Audio = { Ambiente="Nivel4", Victoria="Fanfare", TemaVictoria="Tema" },
	Adyacencias = {},
	Misiones     = { { ID=1, Texto="Completa el circuito", Tipo="CIRCUITO_CERRADO", Parametros={} } },
	Nodos        = {},
	NombresPostes = {},
	Zonas        = {},
}

return LevelsConfig