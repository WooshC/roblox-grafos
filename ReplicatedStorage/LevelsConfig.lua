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
	Algoritmo = "BFS",

	Puntuacion = {
		TresEstrellas = 1000, 
		DosEstrellas = 600,
		RecompensaXP = 500 
	},

	NodoInicio = "PostePanel",
	NodoFin = "PostePanel",
	NodosTotales = 13,

	-- ============================================
	-- ZONA 1: NODO Y ARISTA (Fundamentos)
	-- ZONA 2: GRADO DE NODO
	-- ZONA 3: GRAFO DIRIGIDO
	-- ZONA 4: CONECTIVIDAD
	-- ============================================
	Adyacencias = {
		-- ZONA 1: Nodos y Aristas (sin sufijo)
		["Nodo1_z1"] = {"Nodo2_z1"},
		["Nodo2_z1"] = {"Nodo1_z1"},

		-- ZONA 2: Grado de Nodo (sufijo _z2)
		["Nodo1_z2"] = {"Nodo2_z2", "Nodo3_z2"},
		["Nodo2_z2"] = {"Nodo1_z2"},
		["Nodo3_z2"] = {"Nodo1_z2"},

		-- ZONA 3: Grafo Dirigido (sufijo _z3)
		["Nodo1_z3"] = {"Nodo2_z3"},
		["Nodo2_z3"] = {"Nodo3_z3"},
		["Nodo3_z3"] = {},

		-- ZONA 4: Conectividad (sufijo _z4)
		["Nodo1_z4"] = {"Nodo2_z4", "Nodo3_z4"},
		["Nodo2_z4"] = {"Nodo1_z4", "Nodo3_z4"},
		["Nodo3_z4"] = {"Nodo1_z4", "Nodo2_z4"},

		-- Panel y Bonus
		["PostePanel"] = {"toma_corriente"},
		["toma_corriente"] = {},
	},

	-- ============================================
	-- MISIONES POR ZONA
	-- ============================================
	Misiones = {
		-- ZONA 1: Nodos y Aristas
		{
			ID = 1,
			Texto = "🟢 ZONA 1: Selecciona un nodo para ver su definición",
			Tipo = "NODO_SELECCIONADO",
			Puntos = 100,
			Parametros = {
				Nodo = "Nodo1"
			}
		},
		{
			ID = 2,
			Texto = "🟢 ZONA 1: Conecta Nodo 1 con Nodo 2 (crea una arista)",
			Tipo = "ARISTA_CREADA",
			Puntos = 150,
			Parametros = {
				NodoA = "Nodo1",
				NodoB = "Nodo2"
			}
		},

		-- ZONA 2: Grado de Nodo
		{
			ID = 3,
			Texto = "🔵 ZONA 2: Haz que el nodo central tenga grado 1",
			Tipo = "GRADO_NODO",
			Puntos = 150,
			Parametros = {
				Nodo = "Nodo1_z2",
				GradoRequerido = 1
			}
		},
		{
			ID = 4,
			Texto = "🔵 ZONA 2: Aumenta el grado del nodo central a 2",
			Tipo = "GRADO_NODO",
			Puntos = 150,
			Parametros = {
				Nodo = "Nodo1_z2",
				GradoRequerido = 2
			}
		},

		-- ZONA 3: Grafo Dirigido
		{
			ID = 5,
			Texto = "🟡 ZONA 3: Crea una arista dirigida (Nodo X → Nodo Y)",
			Tipo = "ARISTA_DIRIGIDA",
			Puntos = 150,
			Parametros = {
				NodoOrigen = "Nodo1_z3",
				NodoDestino = "Nodo2_z3"
			}
		},
		{
			ID = 6,
			Texto = "🟡 ZONA 3: Completa la cadena dirigida hasta Nodo Z",
			Tipo = "ARISTA_DIRIGIDA",
			Puntos = 150,
			Parametros = {
				NodoOrigen = "Nodo2_z3",
				NodoDestino = "Nodo3_z3"
			}
		},

		-- ZONA 4: Conectividad
		{
			ID = 7,
			Texto = "🔴 ZONA 4: Construye un grafo conexo (todos los nodos alcanzables)",
			Tipo = "GRAFO_CONEXO",
			Puntos = 250,
			Parametros = {
				Nodos = {"Nodo1_z4", "Nodo2_z4", "Nodo3_z4"}
			}
		},

		-- BONUS
		{
			ID = 8,
			Texto = "⭐ BONUS: Conecta la Tableta Especial con el Panel",
			Tipo = "ARISTA_CREADA",
			Puntos = 500,
			Parametros = {
				NodoA = "PostePanel",
				NodoB = "toma_corriente"
			}
		}
	},

	Objetos = {
		{ ID = "Tableta_Especial", Nombre = "Tableta Educativa", Descripcion = "Item especial del bonus", Icono = "📱", Modelo = "Tableta" },
		{ ID = "Mapa", Nombre = "Mapa del Laboratorio", Descripcion = "Desbloquea la vista de mapa", Icono = "🗺️", Modelo = "MapaModel" },
		{ ID = "Algoritmo_BFS", Nombre = "Manual de BFS", Descripcion = "Desbloquea el algoritmo BFS", Icono = "🧠", Modelo = "AlgoritmoBFS" }
	},

	-- ============================================
	-- NODOS CON DESCRIPCIONES
	-- ============================================
	Nodos = {
		-- ZONA 1: Nodos y Aristas
		Nodo1 = { 
			Zona = "Zona_Estacion_1", 
			Alias = "🟢 Nodo 1",
			Descripcion = "Un nodo es un punto en el grafo. Puede representar cualquier cosa: una ciudad, una persona, un concepto."
		},
		Nodo2 = { 
			Zona = "Zona_Estacion_1", 
			Alias = "🟢 Nodo 2",
			Descripcion = "Otro nodo. La conexión entre dos nodos es una arista."
		},

		-- ZONA 2: Grado de Nodo
		Nodo1_z2 = { 
			Zona = "Zona_Estacion_2", 
			Alias = "🔵 Centro",
			Descripcion = "Este es el nodo central. Su GRADO es el número de aristas conectadas."
		},
		Nodo2_z2 = { 
			Zona = "Zona_Estacion_2", 
			Alias = "🔵 Vecino 1",
			Descripcion = "Conecta este nodo al centro para aumentar el grado."
		},
		Nodo3_z2 = { 
			Zona = "Zona_Estacion_2", 
			Alias = "🔵 Vecino 2",
			Descripcion = "Segundo vecino. Incrementará el grado a 2."
		},

		-- ZONA 3: Grafo Dirigido
		Nodo1_z3 = { 
			Zona = "Zona_Estacion_3", 
			Alias = "🟡 Nodo X",
			Descripcion = "Nodo origen. Las aristas dirigidas tienen DIRECCIÓN (una flecha)."
		},
		Nodo2_z3 = { 
			Zona = "Zona_Estacion_3", 
			Alias = "🟡 Nodo Y",
			Descripcion = "Nodo intermedio. Recibe entrada de X, envía salida a Z."
		},
		Nodo3_z3 = { 
			Zona = "Zona_Estacion_3", 
			Alias = "🟡 Nodo Z",
			Descripcion = "Nodo destino. Solo tiene entrada, no salida."
		},

		-- ZONA 4: Conectividad
		Nodo1_z4 = { 
			Zona = "Zona_Estacion_4", 
			Alias = "🔴 Nodo 1",
			Descripcion = "Parte del triángulo. Conecta a todos para formar un GRAFO CONEXO."
		},
		Nodo2_z4 = { 
			Zona = "Zona_Estacion_4", 
			Alias = "🔴 Nodo 2",
			Descripcion = "Segundo vértice del triángulo."
		},
		Nodo3_z4 = { 
			Zona = "Zona_Estacion_4", 
			Alias = "🔴 Nodo 3",
			Descripcion = "Tercer vértice. Todos deben ser alcanzables entre sí."
		},

		-- Panel y Bonus
		PostePanel = { 
			Zona = nil, 
			Alias = "🔌 Panel Central",
			Descripcion = "El panel principal del laboratorio."
		},
		toma_corriente = { 
			Zona = nil, 
			Alias = "⭐ Tableta Especial",
			Descripcion = "BONUS: Conecta esta tableta especial para desbloquear un logro."
		}
	},

	-- ============================================
	-- CONFIGURACIÓN DE ZONAS
	-- ============================================
	Zonas = {
		["Zona_Estacion_1"] = {
			Modo = "ALL",
			Descripcion = "🟢 ZONA 1: Nodos y Aristas - Aprende qué son",
			Color = Color3.fromRGB(65,105,225),
			Concepto = "Fundamentos"
		},
		["Zona_Estacion_2"] = {
			Modo = "ALL",
			Descripcion = "🔵 ZONA 2: Grado de Nodo - Cuenta conexiones",
			Color = Color3.fromRGB(34,139,34),
			Concepto = "Propiedades Locales"
		},
		["Zona_Estacion_3"] = {
			Modo = "ALL",
			Descripcion = "🟡 ZONA 3: Grafos Dirigidos - Flechas direccionales",
			Color = Color3.fromRGB(220,20,60),
			Concepto = "Direccionalidad"
		},
		["Zona_Estacion_4"] = {
			Modo = "ALL",
			Descripcion = "🔴 ZONA 4: Conectividad - Grafos conexos",
			Color = Color3.fromRGB(184,134,11),
			Concepto = "Propiedades Globales"
		}
	},

	-- ============================================
	-- RETROCOMPATIBILIDAD
	-- ============================================
	NombresPostes = {
		["Nodo1"] = "Nodo 1",
		["Nodo2"] = "Nodo 2",
		["Nodo1_z2"] = "Centro",
		["Nodo2_z2"] = "Vecino 1",
		["Nodo3_z2"] = "Vecino 2",
		["Nodo1_z3"] = "Nodo X",
		["Nodo2_z3"] = "Nodo Y",
		["Nodo3_z3"] = "Nodo Z",
		["Nodo1_z4"] = "Nodo 1",
		["Nodo2_z4"] = "Nodo 2",
		["Nodo3_z4"] = "Nodo 3",
		["PostePanel"] = "Panel Central",
		["toma_corriente"] = "Tableta Especial"
	}
}


-- ==========================================
-- NIVEL 2: EXPANSIÓN URBANA
-- ==========================================
LevelsConfig[2] = {
	Nombre = "Expansión Urbana",
	DescripcionCorta = "Una zona más amplia requiere planificación cuidadosa.",
	ImageId = "rbxassetid://1234567892",
	Modelo = "Nivel2_Expansion",
	Descripcion = "La ciudad crece. Conecta los nuevos distritos comerciales. Cuidado con los obstáculos que encarecen el cableado.",
	DineroInicial = 8000,
	CostoPorMetro = 35,
	Algoritmo = "DFS",
	NodoInicio = "GeneradorCentral",
	NodoFin = "SubestacionNorte",

	Puntuacion = {
		TresEstrellas = 2500, 
		DosEstrellas = 1500,
		RecompensaXP = 200
	},

	Adyacencias = {},

	Misiones = {
		{
			ID = 1,
			Texto = "Completa el circuito",
			Tipo = "CIRCUITO_CERRADO",
			Parametros = {}
		}
	},

	Nodos = {
		GeneradorCentral = { Zona = nil, Alias = "⚙️ Generador Central" },
		SubestacionNorte = { Zona = "Zona_Norte", Alias = "🚩 Subestación Norte" }
	},

	NombresPostes = {
		["GeneradorCentral"] = "Generador Central",
		["SubestacionNorte"] = "Subestación Norte"
	},

	Zonas = {
		["Zona_Norte"] = {
			Modo = "ALL",
			Descripcion = "Distrito comercial norte"
		}
	}
}

-- ==========================================
-- NIVEL 3: EL COMPLEJO INDUSTRIAL
-- ==========================================
LevelsConfig[3] = {
	Nombre = "Complejo Industrial",
	DescripcionCorta = "Alta demanda de energía y rutas costosas.",
	ImageId = "rbxassetid://1234567893",
	Modelo = "Nivel3_Industrial",
	Descripcion = "Las fábricas necesitan potencia estable. Las distancias son largas y el cobre es caro.",
	DineroInicial = 12000,
	CostoPorMetro = 50,
	Algoritmo = "Dijkstra",
	NodoInicio = "PlantaNuclear",
	NodoFin = "FabricaAceros",

	Puntuacion = {
		TresEstrellas = 4000, 
		DosEstrellas = 2500,
		RecompensaXP = 300
	},

	Adyacencias = {},

	Misiones = {
		{
			ID = 1,
			Texto = "Completa el circuito",
			Tipo = "CIRCUITO_CERRADO",
			Parametros = {}
		}
	},

	Nodos = {
		PlantaNuclear = { Zona = nil, Alias = "⚛️ Planta Nuclear" },
		FabricaAceros = { Zona = "Zona_Industrial", Alias = "🏭 Fábrica de Aceros" }
	},

	NombresPostes = {
		["PlantaNuclear"] = "Planta Nuclear",
		["FabricaAceros"] = "Fábrica de Aceros"
	},

	Zonas = {
		["Zona_Industrial"] = {
			Modo = "ALL",
			Descripcion = "Complejo industrial"
		}
	}
}

-- ==========================================
-- NIVEL 4: LA GRAN METRÓPOLIS
-- ==========================================
LevelsConfig[4] = {
	Nombre = "Gran Metrópolis",
	DescripcionCorta = "El desafío final de optimización.",
	ImageId = "rbxassetid://1234567894",
	Modelo = "Nivel4_Final",
	Descripcion = "Toda la ciudad depende de ti. Debes interconectar múltiples subestaciones con la máxima eficiencia posible.",
	DineroInicial = 20000,
	CostoPorMetro = 45,
	Algoritmo = "Dijkstra",
	NodoInicio = "CentralHidro",
	NodoFin = "Rascacielos",

	Puntuacion = {
		TresEstrellas = 8000, 
		DosEstrellas = 5000,
		RecompensaXP = 500
	},

	Adyacencias = {},

	Misiones = {
		{
			ID = 1,
			Texto = "Completa el circuito",
			Tipo = "CIRCUITO_CERRADO",
			Parametros = {}
		}
	},

	Nodos = {
		CentralHidro = { Zona = nil, Alias = "💧 Central Hidroeléctrica" },
		Rascacielos = { Zona = "Centro_Financiero", Alias = "🏢 Torre Rascacielos" }
	},

	NombresPostes = {
		["CentralHidro"] = "Central Hidroeléctrica",
		["Rascacielos"] = "Torre Rascacielos"
	},

	Zonas = {
		["Centro_Financiero"] = {
			Modo = "ALL",
			Descripcion = "Centro financiero de la metrópolis"
		}
	}
}

return LevelsConfig