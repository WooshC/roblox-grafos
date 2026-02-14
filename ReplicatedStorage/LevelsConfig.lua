local LevelsConfig = {}

-- ============================================
-- NIVEL 0: TUTORIAL BÁSICO
-- ============================================
LevelsConfig[0] = {
	Nombre = "Campo de Entrenamiento",
	DescripcionCorta = "Aprende los conceptos básicos de conexión.",
	ImageId = "rbxassetid://1234567890",
	Modelo = "Nivel0_Tutorial", 
	Descripcion = "Bienvenido a Villa Conexa. Tu misión es aprender a conectar los generadores con las torres usando cables. ¡No gastes todo tu presupuesto!",
	DineroInicial = 0,
	CostoPorMetro = 0,
	Algoritmo = "BFS",

	Puntuacion = {
		TresEstrellas = 1000, 
		DosEstrellas = 600,
		RecompensaXP = 500 
	},

	NodoInicio = "PostePanel",
	NodoFin = "PosteFinal",
	NodosTotales = 8,

	Adyacencias = {
		["PostePanel"] = {"Poste1","Poste5","toma_corriente"},
		["Poste1"] = {"PostePanel", "Poste2","Poste4"},
		["Poste2"] = {"Poste1", "Poste3"},
		["Poste3"] = {"Poste2", "Poste4"},
		["Poste4"] = {"Poste1", "PosteFinal","Poste3"},
		["Poste5"] = {"PostePanel", "PosteFinal"},
		["PosteFinal"] = {"Poste4","Poste5"},
	},

	-- ============================================
	-- MISIONES (CRÍTICO PARA PUNTAJE)
	-- ============================================
	Misiones = {
		{
			ID = 1,
			Texto = "Energiza la Toma de Corriente (toma_corriente)",
			Tipo = "NODO_ENERGIZADO",
			Puntos = 250,
			Parametros = {
				Nodo = "toma_corriente"
			}
		},
		{
			ID = 2,
			Texto = "Energiza al menos 3 nodos",
			Tipo = "NODOS_MINIMOS",
			Puntos = 250,
			Parametros = {
				Cantidad = 3
			}
		},
		{
			ID = 3,
			Texto = "¡Llega a la Torre de Control!",
			Tipo = "NODO_ENERGIZADO",
			Puntos = 250,
			Parametros = {
				Nodo = "PosteFinal"
			}
		},
		{
			ID = 4,
			Texto = "¡Energiza toda la red! (8/8 nodos)",
			Tipo = "TODOS_LOS_NODOS",
			Puntos = 250,
			Parametros = {
				Cantidad = 8
			}
		}
	},

	Objetos = {
		{ ID = "Mapa", Nombre = "Mapa de Villa Conexa", Descripcion = "Desbloquea la vista de mapa", Icono = "🗺️", Modelo = "MapaModel" },
		{ ID = "Algoritmo_BFS", Nombre = "Manual de BFS", Descripcion = "Desbloquea el algoritmo BFS", Icono = "🧠", Modelo = "AlgoritmoBFS" },
		{ ID = "Algoritmo_Dijkstra", Nombre = "Manual de Dijkstra", Descripcion = "Desbloquea el algoritmo Dijkstra", Icono = "⚡", Modelo = "AlgoritmoDijkstra" }
	},

	-- ============================================
	-- NODOS CON ALIASES INTEGRADOS
	-- ============================================
	Nodos = {
		PostePanel = { Zona = nil, Alias = "🔌 Generador" },
		Poste1 = { Zona = "Zona_luz_1", Alias = "🏢 Torre 1" },
		Poste2 = { Zona = "Zona_luz_1", Alias = "🏢 Torre 2" },
		Poste3 = { Zona = "Zona_luz_1", Alias = "🏢 Torre 3" },
		Poste4 = { Zona = "Zona_luz_1", Alias = "🏢 Torre 4" },
		Poste5 = { Zona = "Zona_luz_1", Alias = "🏢 Torre 5" },
		PosteFinal = { Zona = "Zona_luz_1", Alias = "🚩 Torre Control" },
		toma_corriente = { Zona = "Zona_luz_2", Alias = "💡 Toma Corriente" }
	},

	-- ============================================
	-- RETROCOMPATIBILIDAD (Viejo formato)
	-- ============================================
	NombresPostes = {
		["PostePanel"] = "Generador",
		["PosteFinal"] = "Torre Control",
		["Poste1"] = "Torre 1",
		["Poste2"] = "Torre 2",
		["Poste3"] = "Torre 3",
		["Poste5"] = "Torre 5",
		["toma_corriente"] = "Toma Corriente"
	},

	-- ============================================
	-- CONFIGURACIÓN DE ZONAS
	-- ============================================
	Zonas = {
		["Zona_luz_1"] = {
			Modo = "ALL",
			Descripcion = "Sector principal: Torre de Control"
		},
		["Zona_luz_2"] = {
			Modo = "ANY",
			Descripcion = "Sector secundario: Puerta"
		}
	}
}

-- ==========================================
-- NIVEL 1: LA PRIMERA RED
-- ==========================================
LevelsConfig[1] = {
	Nombre = "La Primera Red",
	DescripcionCorta = "Conecta el barrio residencial con bajo presupuesto.",
	ImageId = "rbxassetid://1234567891",
	Modelo = "Nivel1_Basico",
	Descripcion = "Los residentes necesitan luz. Usa el algoritmo BFS para encontrar la ruta más corta y ahorrar dinero.",
	DineroInicial = 5000,
	CostoPorMetro = 20,
	Algoritmo = "Dijkstra",
	NodoInicio = "PostePanel",
	NodoFin = "Poste6",

	Puntuacion = {
		TresEstrellas = 1200, 
		DosEstrellas = 800,
		RecompensaXP = 150
	},

	Adyacencias = {
		["PostePanel"] = {"Poste1", "Poste2"},
		["Poste1"] = {"PostePanel", "Poste2"},
		["Poste2"] = {"PostePanel", "Poste1", "Poste6"},
		["Poste6"] = {"Poste2"}
	},

	Misiones = {
		{
			ID = 1,
			Texto = "Conecta al menos 2 nodos",
			Tipo = "NODOS_MINIMOS",
			Parametros = { Cantidad = 2 }
		},
		{
			ID = 2,
			Texto = "Llega al nodo final",
			Tipo = "CIRCUITO_CERRADO",
			Parametros = {}
		},
		{
			ID = 3,
			Texto = "Ahorra presupuesto: Mantén al menos $3000",
			Tipo = "PRESUPUESTO_RESTANTE",
			Parametros = { Cantidad = 3000 }
		}
	},

	-- ============================================
	-- NODOS CON ALIASES
	-- ============================================
	Nodos = {
		PostePanel = { Zona = nil, Alias = "🔌 Generador Principal" },
		Poste1 = { Zona = "Zona_Residencial", Alias = "🏠 Torre Residencial 1" },
		Poste2 = { Zona = "Zona_Residencial", Alias = "🏠 Torre Residencial 2" },
		Poste6 = { Zona = "Zona_Residencial", Alias = "🚩 Torre Distribuidora" }
	},

	-- ============================================
	-- RETROCOMPATIBILIDAD
	-- ============================================
	NombresPostes = {
		["PostePanel"] = "Generador Principal",
		["Poste1"] = "Torre Residencial 1",
		["Poste2"] = "Torre Residencial 2",
		["Poste6"] = "Torre Distribuidora"
	},

	Zonas = {
		["Zona_Residencial"] = {
			Modo = "ALL",
			Descripcion = "Zona de casas residenciales"
		}
	},

	Objetos = {
		{ ID = "Algoritmo_Dijkstra", Nombre = "Manual de Dijkstra", Descripcion = "Aprende a encontrar el camino más barato", Icono = "⚡", Modelo = "AlgoritmoDijkstra" }
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