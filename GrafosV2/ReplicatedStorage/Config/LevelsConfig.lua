-- LevelsConfig.lua
-- Fuente única de verdad para la configuración de todos los niveles.
-- Ubicación Roblox: ReplicatedStorage/Config/LevelsConfig  (ModuleScript)
-- Accesible tanto desde el servidor (LevelLoader, DataService) como desde el cliente.

return {
	[0] = {
		Nombre        = "Laboratorio de Grafos",
		Modelo        = "Nivel0",
		Algoritmo     = nil,
		Tag           = "NIVEL 0 · FUNDAMENTOS",
		Emoji         = "🧪",
		Descripcion   = "Aprende los conceptos básicos de grafos no dirigidos. Conecta los postes de la estación para establecer la red de energía.",
		Conceptos     = {"Nodos", "Aristas", "Adyacencia"},
		Seccion       = "INTRODUCCIÓN A GRAFOS",
	},
	[1] = {
		Nombre        = "La Red Desconectada",
		Modelo        = "Nivel1",
		Algoritmo     = "Conectividad",
		Tag           = "NIVEL 1 · CONECTIVIDAD",
		Emoji         = "🏙️",
		Descripcion   = "La red urbana está fragmentada. Identifica los componentes y conéctalos para restaurar el servicio.",
		Conceptos     = {"Componentes", "Conectividad", "BFS"},
		Seccion       = "INTRODUCCIÓN A GRAFOS",
	},
	[2] = {
		Nombre        = "La Fábrica de Señales",
		Modelo        = "Nivel2",
		Algoritmo     = "BFS/DFS",
		Tag           = "NIVEL 2 · ALGORITMOS",
		Emoji         = "🏭",
		Descripcion   = "Recorre la fábrica usando BFS y DFS para activar todos los nodos de producción en el orden correcto.",
		Conceptos     = {"BFS", "DFS", "Recorrido"},
		Seccion       = "ALGORITMOS DE BÚSQUEDA",
	},
	[3] = {
		Nombre        = "El Puente Roto",
		Modelo        = "Nivel3",
		Algoritmo     = "Grafos Dirigidos",
		Tag           = "NIVEL 3 · GRAFOS DIRIGIDOS",
		Emoji         = "🌉",
		Descripcion   = "Los puentes de la ciudad tienen dirección. Planea las rutas de reparación usando grafos dirigidos.",
		Conceptos     = {"Dirigido", "In-degree", "Out-degree"},
		Seccion       = "ALGORITMOS DE BÚSQUEDA",
	},
	[4] = {
		Nombre        = "Ruta Mínima",
		Modelo        = "Nivel4",
		Algoritmo     = "Dijkstra",
		Tag           = "NIVEL 4 · RUTAS ÓPTIMAS",
		Emoji         = "🗺️",
		Descripcion   = "Encuentra el camino de menor costo para conectar la red usando el algoritmo de Dijkstra.",
		Conceptos     = {"Dijkstra", "Peso", "Ruta mínima"},
		Seccion       = "RUTAS ÓPTIMAS",
	},
}