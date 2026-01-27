local LevelsConfig = {}

-- Configuración Global de Estructura
-- Los modelos de los niveles deben estar guardados en: ServerStorage > Niveles
-- El nombre del modelo debe coincidir con el campo 'Modelo' definido abajo.

-- Nivel 0: Campo de Entrenamiento (Tutorial)
LevelsConfig[0] = {
	Nombre = "Campo de Entrenamiento",
	Modelo = "Nivel0_Tutorial", -- El nombre del Modelo en ServerStorage/Niveles
	Descripcion = "Aprende los conceptos básicos: Nodos, Aristas y Pesos.",
	DineroInicial = 2000,
	CostoPorMetro = 2, -- Pequeño costo para enseñar concepto
	Algoritmo = "BFS", -- El tutorial enseña conectividad básica

	-- Configuración del Grafo Tutorial
	NodoInicio = "PostePanel",
	NodoFin = "PosteFinal",
	NodosTotales = 8, -- Total de postes (PostePanel, Poste1-5, PosteFinal, toma_corriente)
	Adyacencias = {
		["PostePanel"] = {"Poste1","Poste5","toma_corriente"},
		["Poste1"] = {"PostePanel", "Poste2","Poste4"},
		["Poste2"] = {"Poste1", "Poste3"},
		["Poste3"] = {"Poste2", "Poste4"},
		["Poste4"] = {"Poste1", "PosteFinal","Poste3"},
		["Poste5"] = {"PostePanel", "PosteFinal"},
		["PosteFinal"] = {"Poste4","Poste5"},
		["toma_corriente"] = {"PostePanel"}  -- Nuevo nodo
	},

	-- Checklist de Misión (Nuevo formato declarativo)
	Misiones = {
		{
			ID = 1,
			Texto = "Conecta el Generador a la Torre 1 (Poste1)",
			Tipo = "NODO_ENERGIZADO",
			Parametros = {
				Nodo = "Poste1"
			}
		},
		{
			ID = 2,
			Texto = "¡Llega a la Torre de Control!",
			Tipo = "NODO_ENERGIZADO",
			Parametros = {
				Nodo = "PosteFinal"
			}
		},
		{
			ID = 3,
			Texto = "¡Energiza toda la red! (8/8 nodos)",
			Tipo = "TODOS_LOS_NODOS",
			Parametros = {
				Cantidad = 8
			}
		},
		{
			ID = 4,
			Texto = "Energiza la Toma de Corriente y recoge el mapa",
			Tipo = "NODO_ENERGIZADO",
			Parametros = {
				Nodo = "toma_corriente"
			}
		}
	},

	-- Objetos Coleccionables del Nivel
	-- Cada objeto debe tener un Model en el nivel con ProximityPrompt (o agregarse por script)
	Objetos = {
		{
			ID = "Mapa",
			Nombre = "Mapa de Villa Conexa",
			Descripcion = "Desbloquea la vista de mapa",
			Icono = "🗺️",
			Modelo = "MapaModel" -- Nombre del modelo físico en el nivel
		},
		{
			ID = "Algoritmo_BFS",
			Nombre = "Manual de BFS",
			Descripcion = "Desbloquea el algoritmo BFS",
			Icono = "🧠",
			Modelo = "AlgoritmoBFS" -- Nombre del modelo físico (ej: en el mostrador)
		}
	},

	-- Configuración de Nodos y sus Zonas
	-- Cada nodo puede pertenecer a una zona específica
	-- Si un nodo tiene energía, su zona se enciende
	Nodos = {
		PostePanel = { 
			Zona = nil,  -- No pertenece a ninguna zona (es el generador)
			Alias = "Generador"
		},
		Poste1 = { 
			Zona = "Zona_luz_1",  -- Pertenece a Zona_luz_1
			Alias = "Torre 1"
		},
		Poste2 = { 
			Zona = "Zona_luz_1",  -- Pertenece a Zona_luz_1
			Alias = "Torre 2"
		},
		Poste3 = { 
			Zona = "Zona_luz_1",  -- Pertenece a Zona_luz_1
			Alias = "Torre 3"
		},
		Poste4 = { 
			Zona = "Zona_luz_1",  -- Pertenece a Zona_luz_1
			Alias = "Torre 4"
		},
		Poste5 = { 
			Zona = "Zona_luz_1",  -- Pertenece a Zona_luz_1
			Alias = "Torre 5"
		},
		PosteFinal = { 
			Zona = "Zona_luz_1",  -- Pertenece a Zona_luz_1
			Alias = "Torre Control"
		},
		toma_corriente = { 
			Zona = "Zona_luz_2",  -- ⚡ ÚNICO nodo en Zona_luz_2
			Alias = "Toma Corriente"
		}
	},

	-- Configuración de Zonas
	-- Modo: "ANY" = al menos un nodo energizado, "ALL" = todos los nodos energizados
	Zonas = {
		["Zona_luz_1"] = {
			Modo = "ALL",  -- Requiere Postes 1, 2, 3, 4, 5 y Final
			Descripcion = "Sector principal: Torre de Control"
		},
		["Zona_luz_2"] = {
			Modo = "ANY",  -- Requiere toma_corriente
			Descripcion = "Sector secundario: Puerta"
		}
	},

	-- Nombres Personalizados para Etiquetas
	NombresPostes = {
		["PostePanel"] = "Generador",
		["PosteFinal"] = "Torre Control",
		["Poste1"] = "Torre 1",
		["Poste2"] = "Torre 2",
		["Poste3"] = "Torre 3",
		["toma_corriente"] = "Toma Corriente"
	},

	-- Sistema de Puntuación (Idealización)
	Puntuacion = {
		TresEstrellas = 100, 
		DosEstrellas = 200,
		RecompensaXP = 50 
	}
}

-- Nivel 1: Primer Desafío
LevelsConfig[1] = {
	Nombre = "La Primera Red",
	Modelo = "Nivel1_Basico",
	Descripcion = "Conecta el panel principal sin gastar todo tu presupuesto.",
	DineroInicial = 5000,
	CostoPorMetro = 20,
	Algoritmo = "BFS", -- Barrio Laberíntico usa BFS/DFS
	NodoInicio = "PostePanel",
	NodoFin = "Poste6",

	-- Configuración de Puntuación
	Puntuacion = {
		TresEstrellas = 1200, 
		DosEstrellas = 2000,
		RecompensaXP = 150
	},

	-- DEFINICIÓN PROFESIONAL DEL GRAFO (Grafo Ideal)
	-- Aquí defines qué postes PUEDEN conectarse entre sí.
	Adyacencias = {
		["PostePanel"] = {"Poste1", "Poste2"},
		["Poste1"] = {"PostePanel", "Poste2"},
		["Poste2"] = {"PostePanel", "Poste1", "Poste6"},
		["Poste6"] = {"Poste2"}
		-- Agrega más nodos aquí si los tienes (ej: Poste3, Poste4...)
	}
}

-- Nivel 2
LevelsConfig[2] = {
	Nombre = "Expansion Urbana",
	Modelo = "Nivel2_Expansion",
	DineroInicial = 8000,
	CostoPorMetro = 35
}

return LevelsConfig
