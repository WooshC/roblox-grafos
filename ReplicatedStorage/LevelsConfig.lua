local LevelsConfig = {}

-- Configuración Global de Estructura
-- Los modelos de los niveles deben estar guardados en: ServerStorage > Niveles
-- El nombre del modelo debe coincidir con el campo 'Modelo' definido abajo.

-- ==========================================
-- NIVEL 0: TUTORIAL BÁSICO
-- ==========================================
LevelsConfig[0] = {
	Nombre = "Campo de Entrenamiento",
	DescripcionCorta = "Aprende los conceptos básicos de conexión.",
	ImageId = "rbxassetid://1234567890", -- Placeholder
	Modelo = "Nivel0_Tutorial", 
	Descripcion = "Bienvenido a Villa Conexa. Tu misión es aprender a conectar los generadores con las torres usando cables. ¡No gastes todo tu presupuesto!",
	DineroInicial = 0, -- Tutorial no usa dinero
	CostoPorMetro = 0,
	Algoritmo = "BFS",
	
	-- Puntuación (Fácil para tutorial)
	Puntuacion = {
		TresEstrellas = 100, 
		DosEstrellas = 50,
		RecompensaXP = 50 
	},

	-- Configuración del Grafo
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
	-- Entidades y Misiones
	Objetos = {
		{ ID = "Mapa", Nombre = "Mapa de Villa Conexa", Descripcion = "Desbloquea la vista de mapa", Icono = "🗺️", Modelo = "MapaModel" },
		{ ID = "Algoritmo_BFS", Nombre = "Manual de BFS", Descripcion = "Desbloquea el algoritmo BFS", Icono = "🧠", Modelo = "AlgoritmoBFS" }
	},
	Nodos = {
		PostePanel = { Zona = nil, Alias = "Generador" },
		Poste1 = { Zona = "Zona_luz_1", Alias = "Torre 1" },
		Poste2 = { Zona = "Zona_luz_1", Alias = "Torre 2" },
		Poste3 = { Zona = "Zona_luz_1", Alias = "Torre 3" },
		Poste4 = { Zona = "Zona_luz_1", Alias = "Torre 4" },
		Poste5 = { Zona = "Zona_luz_1", Alias = "Torre 5" },
		PosteFinal = { Zona = "Zona_luz_1", Alias = "Torre Control" },
		toma_corriente = { Zona = "Zona_luz_2", Alias = "Toma Corriente" }
	},
	Zonas = {
		["Zona_luz_1"] = { Modo = "ALL", Descripcion = "Sector principal: Torre de Control" },
		["Zona_luz_2"] = { Modo = "ANY", Descripcion = "Sector secundario: Puerta" }
	}
}

-- ==========================================
-- NIVEL 1: LA PRIMERA RED
-- ==========================================
LevelsConfig[1] = {
	Nombre = "La Primera Red",
	DescripcionCorta = "Conecta el barrio residencial con bajo presupuesto.",
	ImageId = "rbxassetid://1234567891", -- Placeholder
	Modelo = "Nivel1_Basico",
	Descripcion = "Los residentes necesitan luz. Usa el algoritmo BFS para encontrar la ruta más corta y ahorrar dinero.",
	DineroInicial = 5000,
	CostoPorMetro = 20,
	Algoritmo = "BFS",
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
	}
}

-- ==========================================
-- NIVEL 2: EXPANSIÓN URBANA
-- ==========================================
LevelsConfig[2] = {
	Nombre = "Expansión Urbana",
	DescripcionCorta = "Una zona más amplia requiere planificación cuidadosa.",
	ImageId = "rbxassetid://1234567892", -- Placeholder
	Modelo = "Nivel2_Expansion", -- Asegúrate de tener este modelo o cambiar el nombre
	Descripcion = "La ciudad crece. Conecta los nuevos distritos comerciales. Cuidado con los obstáculos que encarecen el cableado.",
	DineroInicial = 8000,
	CostoPorMetro = 35,
	Algoritmo = "DFS", -- Introducción a DFS tal vez?
	NodoInicio = "GeneradorCentral",
	NodoFin = "SubestacionNorte",

	Puntuacion = {
		TresEstrellas = 2500, 
		DosEstrellas = 1500,
		RecompensaXP = 200
	},
	Adyacencias = {} -- Rellenar con grafo real
}

-- ==========================================
-- NIVEL 3: EL COMPLEJO INDUSTRIAL
-- ==========================================
LevelsConfig[3] = {
	Nombre = "Complejo Industrial",
	DescripcionCorta = "Alta demanda de energía y rutas costosas.",
	ImageId = "rbxassetid://1234567893", -- Placeholder
	Modelo = "Nivel3_Industrial",
	Descripcion = "Las fábricas necesitan potencia estable. Las distancias son largas y el cobre es caro.",
	DineroInicial = 12000,
	CostoPorMetro = 50,
	Algoritmo = "Dijkstra", -- Introducción a pesos?
	NodoInicio = "PlantaNuclear",
	NodoFin = "FabricaAceros",

	Puntuacion = {
		TresEstrellas = 4000, 
		DosEstrellas = 2500,
		RecompensaXP = 300
	},
	Adyacencias = {}
}

-- ==========================================
-- NIVEL 4: LA GRAN METRÓPOLIS
-- ==========================================
LevelsConfig[4] = {
	Nombre = "Gran Metrópolis",
	DescripcionCorta = "El desafío final de optimización.",
	ImageId = "rbxassetid://1234567894", -- Placeholder
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
	Adyacencias = {}
}

return LevelsConfig
