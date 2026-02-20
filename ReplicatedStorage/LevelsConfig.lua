-- ReplicatedStorage/LevelsConfig.lua
-- ✅ CORREGIDO: Nombres de nodos usan doble guión bajo (__z1) para coincidir con el modelo

local LevelsConfig = {}

--- ============================================
-- NIVEL 0: LABORATORIO DE GRAFOS
-- ============================================
LevelsConfig[0] = {
	Nombre = "Laboratorio de Grafos",
	DescripcionCorta = "Aprende teoría de grafos a través de 4 zonas educativas.",
	ImageId = "rbxassetid://87116895331866",
	Modelo = "Nivel0",
	Descripcion = "Bienvenido al Laboratorio. Aprenderás sobre grafos desde lo básico hasta conceptos avanzados.",
	DineroInicial = 0,
	CostoPorMetro = 0,
	Algoritmo = nil, -- Sin algoritmo en este nivel

	-- Victoria = completar todas las zonas
	CondicionVictoria = "ZONAS_COMPLETAS",

	Puntuacion = {
		TresEstrellas = 1000,
		DosEstrellas = 600,
		RecompensaXP = 500
	},

	Audio = {
		Ambiente = "Nivel0",       -- ReplicatedStorage/Audio/Ambiente/Nivel0
		Victoria = "Fanfare",      -- ReplicatedStorage/Audio/Victoria/Fanfare
		TemaVictoria = "Tema",     -- ReplicatedStorage/Audio/Victoria/Tema
	},

	NodoInicio = "PostePanel",
	NodoFin = "PostePanel",
	NodosTotales = 13,

	-- Nombres originales con un solo guión bajo (_z1)
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

	-- Misiones con nombres correctos
	Misiones = {
		{
			ID = 1, Zona = "Zona_Estacion_1",
			Texto = "Selecciona un nodo para ver su definición",
			Tipo = "NODO_SELECCIONADO", Puntos = 100,
			Parametros = { Nodo = "Nodo1_z1" }
		},
		{
			ID = 2, Zona = "Zona_Estacion_1",
			Texto = "Conecta Nodo 1 con Nodo 2 (crea una arista)",
			Tipo = "ARISTA_CREADA", Puntos = 150,
			Parametros = { NodoA = "Nodo1_z1", NodoB = "Nodo2_z1" }
		},
		{
			ID = 3, Zona = "Zona_Estacion_2",
			Texto = "Conecta un vecino al centro (grado 1)",
			Tipo = "GRADO_NODO", Puntos = 150,
			Parametros = { Nodo = "Nodo1_z2", GradoRequerido = 1 }
		},
		{
			ID = 4, Zona = "Zona_Estacion_2",
			Texto = "Conecta los tres vecinos al centro (grado 3)",
			Tipo = "GRADO_NODO", Puntos = 300,
			Parametros = { Nodo = "Nodo1_z2", GradoRequerido = 3 }
		},
		{
			ID = 5, Zona = "Zona_Estacion_3",
			Texto = "Crea la arista dirigida Nodo X → Nodo Y",
			Tipo = "ARISTA_DIRIGIDA", Puntos = 150,
			Parametros = { NodoOrigen = "Nodo1_z3", NodoDestino = "Nodo2_z3" }
		},
		{
			ID = 6, Zona = "Zona_Estacion_3",
			Texto = "Completa la cadena: Nodo Y → Nodo Z",
			Tipo = "ARISTA_DIRIGIDA", Puntos = 150,
			Parametros = { NodoOrigen = "Nodo2_z3", NodoDestino = "Nodo3_z3" }
		},
		{
			ID = 7, Zona = "Zona_Estacion_4",
			Texto = "Construye un grafo conexo (todos alcanzables)",
			Tipo = "GRAFO_CONEXO", Puntos = 250,
			Parametros = { Nodos = {"Nodo1_z4", "Nodo2_z4", "Nodo3_z4"} }
		},
		{
			ID = 8, Zona = nil,
			Texto = "BONUS: Conecta la Tableta con el Panel",
			Tipo = "ARISTA_CREADA", Puntos = 500,
			Parametros = { NodoA = "PostePanel", NodoB = "toma_corriente" }
		}
	},

	Objetos = {
		{ ID = "Tableta_Especial", Nombre = "Tableta Educativa", Descripcion = "Item especial del bonus", Icono = "📱", Modelo = "Tableta" },
		{ ID = "Mapa", Nombre = "Mapa del Laboratorio", Descripcion = "Desbloquea la vista de mapa", Icono = "🗺️", Modelo = "MapaModel" },
		{ ID = "Algoritmo_BFS", Nombre = "Manual de BFS", Descripcion = "Desbloquea el algoritmo BFS", Icono = "🧠", Modelo = "AlgoritmoBFS" }
	},

	-- Nodos con un solo guión bajo
	Nodos = {
		["Nodo1_z1"] = { Zona = "Zona_Estacion_1", Alias = "Nodo 1", Descripcion = "Un nodo es un punto en el grafo." },
		["Nodo2_z1"] = { Zona = "Zona_Estacion_1", Alias = "Nodo 2", Descripcion = "La conexión entre dos nodos es una arista." },
		["Nodo1_z2"] = { Zona = "Zona_Estacion_2", Alias = "Centro", Descripcion = "Nodo central. Su GRADO es el número de aristas conectadas." },
		["Nodo2_z2"] = { Zona = "Zona_Estacion_2", Alias = "Vecino 1", Descripcion = "Conecta al centro para aumentar el grado." },
		["Nodo3_z2"] = { Zona = "Zona_Estacion_2", Alias = "Vecino 2", Descripcion = "Segundo vecino. Incrementará el grado a 2." },
		["Nodo4_z2"] = { Zona = "Zona_Estacion_2", Alias = "Vecino 3", Descripcion = "Segundo vecino. Incrementará el grado a 3." },
		["Nodo1_z3"] = { Zona = "Zona_Estacion_3", Alias = "Nodo X", Descripcion = "Nodo origen. Aristas dirigidas tienen DIRECCIÓN." },
		["Nodo2_z3"] = { Zona = "Zona_Estacion_3", Alias = "Nodo Y", Descripcion = "Nodo intermedio. Recibe de X, envía a Z." },
		["Nodo3_z3"] = { Zona = "Zona_Estacion_3", Alias = "Nodo Z", Descripcion = "Nodo destino. Solo tiene entrada." },
		["Nodo4_z3"] = { Zona = "Zona_Estacion_3", Alias = "Nodo W", Descripcion = "Nodo Aislado. No tiene vecinos." },
		["Nodo1_z4"] = { Zona = "Zona_Estacion_4", Alias = "Nodo 1", Descripcion = "Conecta a todos para un GRAFO CONEXO." },
		["Nodo2_z4"] = { Zona = "Zona_Estacion_4", Alias = "Nodo 2", Descripcion = "Segundo vértice." },
		["Nodo3_z4"] = { Zona = "Zona_Estacion_4", Alias = "Nodo 3", Descripcion = "Todos deben ser alcanzables entre sí." },
		["Nodo4_z4"] = { Zona = "Zona_Estacion_4", Alias = "Nodo 4", Descripcion = "Todos deben ser alcanzables entre sí." },
		PostePanel = { Zona = nil, Alias = "🔌 Panel Central", Descripcion = "Panel principal del laboratorio." },
		toma_corriente = { Zona = nil, Alias = "⭐ Tableta Especial", Descripcion = "BONUS: Conecta esta tableta." }
	},

	Zonas = {
		["Zona_Estacion_1"] = {
			Modo = "ALL", Descripcion = "🟢 ZONA 1: Nodos y Aristas",
			Color = Color3.fromRGB(65, 105, 225), Concepto = "Fundamentos",
			NodosRequeridos = {"Nodo1_z1", "Nodo2_z1"}
		},
		["Zona_Estacion_2"] = {
			Modo = "ALL", Descripcion = "🔵 ZONA 2: Grado de Nodo",
			Color = Color3.fromRGB(34, 139, 34), Concepto = "Propiedades Locales",
			NodosRequeridos = {"Nodo1_z2", "Nodo2_z2", "Nodo3_z2"}
		},
		["Zona_Estacion_3"] = {
			Modo = "ALL", Descripcion = "🟡 ZONA 3: Grafos Dirigidos",
			Color = Color3.fromRGB(220, 20, 60), Concepto = "Direccionalidad",
			NodosRequeridos = {"Nodo1_z3", "Nodo2_z3", "Nodo3_z3"}
		},
		["Zona_Estacion_4"] = {
			Modo = "ALL", Descripcion = "🔴 ZONA 4: Conectividad",
			Color = Color3.fromRGB(184, 134, 11), Concepto = "Propiedades Globales",
			NodosRequeridos = {"Nodo1_z4", "Nodo2_z4", "Nodo3_z4"}
		},
		["Zona_luz_1"] = { Modo = "ALL", Descripcion = "Sector principal: Torre de Control", NodosRequeridos = {"toma_corriente"}, Oculta = true },
		["Zona_luz_2"] = { Modo = "ANY", Descripcion = "Sector secundario: Puerta", NodosRequeridos = {"toma_corriente"}, Oculta = true }
	},

	NombresPostes = {
		["Nodo1_z1"] = "Nodo 1", ["Nodo2_z1"] = "Nodo 2",
		["Nodo1_z2"] = "Centro", ["Nodo2_z2"] = "Vecino 1", ["Nodo3_z2"] = "Vecino 2",["Nodo4_z2"] = "Vecino 3",
		["Nodo1_z3"] = "Nodo X", ["Nodo2_z3"] = "Nodo Y", ["Nodo3_z3"] = "Nodo Z",
		["Nodo1_z4"] = "Nodo 1", ["Nodo2_z4"] = "Nodo 2", ["Nodo3_z4"] = "Nodo 3",
		["PostePanel"] = "Panel Central", ["toma_corriente"] = "Tableta Especial"
	}
}


-- ==========================================
-- NIVEL 2-4 (sin cambios significativos)
-- ==========================================
LevelsConfig[2] = {
	Nombre = "Expansión Urbana",
	DescripcionCorta = "Una zona más amplia requiere planificación cuidadosa.",
	ImageId = "rbxassetid://1234567892",
	Modelo = "Nivel2_Expansion",
	Descripcion = "La ciudad crece. Conecta los nuevos distritos comerciales.",
	Audio = { Ambiente = "Nivel2", Victoria = "Fanfare", TemaVictoria = "Tema" },
	DineroInicial = 8000, CostoPorMetro = 35, Algoritmo = "DFS",
	CondicionVictoria = "CIRCUITO_CERRADO",
	NodoInicio = "GeneradorCentral", NodoFin = "SubestacionNorte",
	Puntuacion = { TresEstrellas = 2500, DosEstrellas = 1500, RecompensaXP = 200 },
	Adyacencias = {},
	Misiones = { { ID = 1, Texto = "Completa el circuito", Tipo = "CIRCUITO_CERRADO", Parametros = {} } },
	Nodos = {
		GeneradorCentral = { Zona = nil, Alias = "⚙️ Generador Central" },
		SubestacionNorte = { Zona = "Zona_Norte", Alias = "🚩 Subestación Norte" }
	},
	NombresPostes = { ["GeneradorCentral"] = "Generador Central", ["SubestacionNorte"] = "Subestación Norte" },
	Zonas = { ["Zona_Norte"] = { Modo = "ALL", Descripcion = "Distrito comercial norte" } }
}

LevelsConfig[3] = {
	Nombre = "Complejo Industrial",
	DescripcionCorta = "Alta demanda de energía y rutas costosas.",
	ImageId = "rbxassetid://1234567893",
	Modelo = "Nivel3_Industrial",
	Descripcion = "Las fábricas necesitan potencia estable.",
	Audio = { Ambiente = "Nivel3", Victoria = "Fanfare", TemaVictoria = "Tema" },
	DineroInicial = 12000, CostoPorMetro = 50, Algoritmo = "Dijkstra",
	CondicionVictoria = "CIRCUITO_CERRADO",
	NodoInicio = "PlantaNuclear", NodoFin = "FabricaAceros",
	Puntuacion = { TresEstrellas = 4000, DosEstrellas = 2500, RecompensaXP = 300 },
	Adyacencias = {},
	Misiones = { { ID = 1, Texto = "Completa el circuito", Tipo = "CIRCUITO_CERRADO", Parametros = {} } },
	Nodos = {
		PlantaNuclear = { Zona = nil, Alias = "⚛️ Planta Nuclear" },
		FabricaAceros = { Zona = "Zona_Industrial", Alias = "🏭 Fábrica de Aceros" }
	},
	NombresPostes = { ["PlantaNuclear"] = "Planta Nuclear", ["FabricaAceros"] = "Fábrica de Aceros" },
	Zonas = { ["Zona_Industrial"] = { Modo = "ALL", Descripcion = "Complejo industrial" } }
}

LevelsConfig[4] = {
	Nombre = "Gran Metrópolis",
	DescripcionCorta = "El desafío final de optimización.",
	ImageId = "rbxassetid://1234567894",
	Modelo = "Nivel4_Final",
	Descripcion = "Toda la ciudad depende de ti.",
	Audio = { Ambiente = "Nivel4", Victoria = "Fanfare", TemaVictoria = "Tema" },
	DineroInicial = 20000, CostoPorMetro = 45, Algoritmo = "Dijkstra",
	CondicionVictoria = "CIRCUITO_CERRADO",
	NodoInicio = "CentralHidro", NodoFin = "Rascacielos",
	Puntuacion = { TresEstrellas = 8000, DosEstrellas = 5000, RecompensaXP = 500 },
	Adyacencias = {},
	Misiones = { { ID = 1, Texto = "Completa el circuito", Tipo = "CIRCUITO_CERRADO", Parametros = {} } },
	Nodos = {
		CentralHidro = { Zona = nil, Alias = "💧 Central Hidroeléctrica" },
		Rascacielos = { Zona = "Centro_Financiero", Alias = "🏢 Torre Rascacielos" }
	},
	NombresPostes = { ["CentralHidro"] = "Central Hidroeléctrica", ["Rascacielos"] = "Torre Rascacielos" },
	Zonas = { ["Centro_Financiero"] = { Modo = "ALL", Descripcion = "Centro financiero" } }
}

return LevelsConfig