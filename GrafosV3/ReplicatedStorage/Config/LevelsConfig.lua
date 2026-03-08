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
--   AnalisisConfig[zonaID]                     → ModuloAnalisis (analizador educativo)
--     .algoritmos   → pills disponibles en esa zona
--     .nodoInicio   → nodo desde el que arrancan BFS/DFS/Dijkstra/Prim
--     .nodoFin      → nodo destino (opcional, resalta ruta en Dijkstra)
--     .conceptos    → tabla de conceptos clave por algoritmo (textos didácticos)

local LevelsConfig = {}

-- ============================================
-- NIVEL 0: LABORATORIO DE GRAFOS
-- ============================================
LevelsConfig[0] = {
	Nombre           = "Laboratorio de Grafos",
	DescripcionCorta = "Aprende teoria de grafos a traves de 4 zonas educativas.",
	ImageId          = "rbxassetid://87116895331866",
	Modelo           = "Nivel0",

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

		-- Zona 3: Grafos Dirigidos — cadena dirigida A → B → C --> A
		["NodoA_z3"] = {"NodoB_z3"},
		["NodoB_z3"] = {"NodoC_z3"},
		["NodoC_z3"] = {"NodoA_z3"},

		-- Zona 4: Conectividad — cuatro nodos en cuadrado
		["NodoA_z4"] = {"NodoB_z4", "NodoC_z4"},
		["NodoB_z4"] = {"NodoA_z4", "NodoD_z4"},
		["NodoC_z4"] = {"NodoA_z4", "NodoD_z4"},
		["NodoD_z4"] = {"NodoB_z4", "NodoC_z4"},

		["PostePanel"]     = {"toma_corriente"},
		["toma_corriente"] = {"PostePanel"},
	},

	Zonas = {
		["Zona_Estacion_1"] = { Trigger = "ZonaTrigger_Estacion1", Descripcion = "Nodos y Aristas",  Dialogo = "Zona1_NodosAristas"    },
		["Zona_Estacion_2"] = { Trigger = "ZonaTrigger_Estacion2", Descripcion = "Grado de Nodo",    Dialogo = "Zona2_GradoNodo"        },
		["Zona_Estacion_3"] = { Trigger = "ZonaTrigger_Estacion3", Descripcion = "Grafos Dirigidos", Dialogo = "Zona3_GrafosDirigidos"  },
		["Zona_Estacion_4"] = { Trigger = "ZonaTrigger_Estacion4", Descripcion = "Conectividad",     Dialogo = "Zona4_Conectividad"     },
	},

	NombresNodos = {
		["Nodo1_z1"]      = "Nodo 1",
		["Nodo2_z1"]      = "Nodo 2",
		["NodoCentro_z2"] = "Nodo Central",
		["NodoA_z2"]      = "Vecino A",
		["NodoB_z2"]      = "Vecino B",
		["NodoC_z2"]      = "Vecino C",
		["NodoD_z2"]      = "Vecino D",
		["NodoA_z3"]      = "Nodo A",
		["NodoB_z3"]      = "Nodo B",
		["NodoC_z3"]      = "Nodo C",
		["NodoA_z4"]      = "Nodo A",
		["NodoB_z4"]      = "Nodo B",
		["NodoC_z4"]      = "Nodo C",
		["NodoD_z4"]      = "Nodo D",
		["PostePanel"]     = "Panel Central",
		["toma_corriente"] = "Tableta Especial",
	},

	-- ═══════════════════════════════════════════════════════════════
	-- CONFIGURACIÓN DEL ANALIZADOR POR ZONA
	-- ═══════════════════════════════════════════════════════════════
	-- algoritmos : pills visibles para esa zona
	-- nodoInicio : desde dónde arranca el algoritmo
	-- nodoFin    : destino para Dijkstra (nil = calcular a todos)
	-- conceptos  : textos pedagógicos mostrados en el panel por algoritmo y momento
	--   .intro   → se muestra al seleccionar el algoritmo (antes de ejecutar)
	--   .pasos   → tabla de frases indexada por lineaPseudo (opcional, enriquece descripción)
	-- ═══════════════════════════════════════════════════════════════
	AnalisisConfig = {
		["Zona_Estacion_1"] = {
			algoritmos = { "bfs", "dfs" },
			nodoInicio = "Nodo1_z1",
			nodoFin    = nil,
			conceptos  = {
				bfs = {
					intro = "BFS explora nivel a nivel usando una cola FIFO. Visita primero todos los vecinos directos antes de avanzar.",
					pasos = {
						[2]  = "Añadimos el nodo inicial a la cola y lo marcamos como visitado.",
						[7]  = "Desencolamos el nodo frontal: es el que procesaremos ahora.",
						[9]  = "Vecino no visitado encontrado: lo encolamos para procesarlo después.",
						[13] = "Cola vacía — todos los nodos alcanzables fueron visitados.",
					},
				},
				dfs = {
					intro = "DFS se adentra lo más posible por cada rama antes de retroceder, usando una pila LIFO.",
					pasos = {
						[2]  = "Apilamos el nodo inicial. La pila mantiene el camino pendiente de explorar.",
						[7]  = "Desapilamos el tope: si ya fue visitado lo descartamos.",
						[8]  = "Nodo nuevo: lo marcamos visitado y apilamos sus vecinos.",
						[12] = "Pila vacía — DFS completó la exploración.",
					},
				},
			},
		},

		["Zona_Estacion_2"] = {
			algoritmos = { "bfs", "dfs" },
			nodoInicio = "NodoA_z2",
			nodoFin    = nil,
			conceptos  = {
				bfs = {
					intro = "En un grafo estrella, BFS visita el hub central y luego todos sus vecinos en una sola ronda.",
					pasos = {
						[2]  = "Partimos de Vecino A. La cola empieza con un solo nodo.",
						[7]  = "Procesamos el nodo al frente de la cola.",
						[9]  = "Cada nuevo vecino descubierto se encola — el orden importa.",
						[13] = "BFS completó el grafo estrella en exactamente 2 niveles.",
					},
				},
				dfs = {
					intro = "DFS en un grafo estrella sigue una rama hasta el hub y luego retrocede a los demás vecinos.",
					pasos = {
						[2]  = "Iniciamos desde Vecino A. DFS irá directo hacia el centro.",
						[7]  = "Si el nodo ya fue visitado, lo descartamos sin procesar.",
						[8]  = "Visitamos el nodo y apilamos sus vecinos en orden inverso.",
						[12] = "DFS recorrió toda la estrella retrocediendo desde el hub.",
					},
				},
			},
		},

		["Zona_Estacion_3"] = {
			algoritmos = { "bfs", "dfs" },
			nodoInicio = "NodoA_z3",
			nodoFin    = "NodoC_z3",
			conceptos  = {
				bfs = {
					intro = "Grafo dirigido: las aristas van en una sola dirección. BFS respeta esas direcciones al explorar.",
					pasos = {
						[2]  = "Solo podemos ir de A→B→C. No hay camino de regreso.",
						[7]  = "Desencolamos y exploramos solo los vecinos alcanzables desde aquí.",
						[9]  = "Nuevo nodo descubierto siguiendo la dirección de la arista.",
						[13] = "BFS llegó a Nodo C siguiendo el único camino dirigido posible.",
					},
				},
				dfs = {
					intro = "DFS en un dígrafo solo puede avanzar en la dirección permitida por cada arista.",
					pasos = {
						[2]  = "Apilamos Nodo A. Solo podemos avanzar hacia donde apuntan las aristas.",
						[7]  = "Nodo ya visitado — DFS no retrocede en grafos dirigidos sin ciclos.",
						[8]  = "Visitamos y apilamos solo los vecinos alcanzables según las direcciones.",
						[12] = "DFS completó la cadena dirigida A→B→C.",
					},
				},
			},
		},

		["Zona_Estacion_4"] = {
			algoritmos = { "bfs", "dfs", "dijkstra", "prim" },
			nodoInicio = "NodoA_z4",
			nodoFin    = "NodoD_z4",
			conceptos  = {
				bfs = {
					intro = "BFS en este grafo de 4 nodos encuentra el camino más corto en número de saltos desde A hasta D.",
					pasos = {
						[2]  = "Nivel 0: solo Nodo A. La cola crece por niveles.",
						[7]  = "Procesamos nodo — todos sus vecinos no visitados se añaden al siguiente nivel.",
						[9]  = "Nivel +1: nodo descubierto. La distancia es la cantidad de saltos desde A.",
						[13] = "BFS halló las distancias mínimas (en saltos) desde A a todos los nodos.",
					},
				},
				dfs = {
					intro = "DFS explora en profundidad. El camino encontrado no es necesariamente el más corto.",
					pasos = {
						[2]  = "Apilamos Nodo A. DFS irá tan lejos como pueda antes de retroceder.",
						[7]  = "Nodo ya procesado — lo descartamos del tope de la pila.",
						[8]  = "Nuevo nodo: lo marcamos visitado y continuamos por sus vecinos.",
						[12] = "DFS llegó a D, pero quizá no por el camino más corto.",
					},
				},
				dijkstra = {
					intro = "Dijkstra garantiza el camino de MENOR COSTO desde A hasta cualquier nodo. Con pesos iguales equivale a BFS.",
					pasos = {
						[2]  = "Inicializamos: dist[A]=0, todos los demás=∞. Nadie ha sido explorado.",
						[7]  = "Extraemos el nodo con menor distancia conocida — el más 'barato' hasta ahora.",
						[9]  = "Relajación: si llegar por aquí es más corto, actualizamos la distancia.",
						[13] = "PQ vacía — Dijkstra garantiza que todas las distancias son mínimas.",
					},
				},
				prim = {
					intro = "Prim construye el Árbol de Expansión Mínima (MST): el subconjunto de aristas que conecta todos los nodos con el menor costo total.",
					pasos = {
						[2]  = "Inicializamos: key[A]=0 (la raíz), todos los demás=∞.",
						[8]  = "El nodo con key mínima se une al MST. Se actualizan sus vecinos.",
						[9]  = "Si una arista ofrece un costo menor para llegar a este vecino, lo actualizamos.",
						[13] = "MST completo — este árbol conecta todos los nodos con el mínimo de aristas.",
					},
				},
			},
		},
	},

	Misiones = {
		-- ── Zona 1 ──────────────────────────────────────────────────────────────
		{ ID=1, Zona="Zona_Estacion_1", Texto="Selecciona cualquier nodo",         Tipo="NODO_SELECCIONADO", Puntos=100, Parametros={ Nodo="ANY" } },
		{ ID=2, Zona="Zona_Estacion_1", Texto="Conecta Nodo 1 con Nodo 2",         Tipo="ARISTA_CREADA",     Puntos=150, Parametros={ NodoA="Nodo1_z1", NodoB="Nodo2_z1" } },
		-- ── Zona 2 ──────────────────────────────────────────────────────────────
		{ ID=3, Zona="Zona_Estacion_2", Texto="Selecciona el Nodo Central",        Tipo="NODO_SELECCIONADO", Puntos=100, Parametros={ Nodo="NodoCentro_z2" } },
		{ ID=4, Zona="Zona_Estacion_2", Texto="Conecta 2 vecinos al Nodo Central", Tipo="GRADO_NODO",        Puntos=150, Parametros={ Nodo="NodoCentro_z2", GradoRequerido=2 } },
		{ ID=5, Zona="Zona_Estacion_2", Texto="Conecta todos los vecinos (grado 4)",Tipo="GRADO_NODO",       Puntos=200, Parametros={ Nodo="NodoCentro_z2", GradoRequerido=4 } },
		-- ── Zona 3 ──────────────────────────────────────────────────────────────
		{ ID=6, Zona="Zona_Estacion_3", Texto="Selecciona Nodo A",                 Tipo="NODO_SELECCIONADO", Puntos=100, Parametros={ Nodo="NodoA_z3" } },
		{ ID=7, Zona="Zona_Estacion_3", Texto="Conecta Nodo A → Nodo B",           Tipo="ARISTA_CREADA",     Puntos=150, Parametros={ NodoA="NodoA_z3", NodoB="NodoB_z3" } },
		{ ID=8, Zona="Zona_Estacion_3", Texto="Conecta Nodo B → Nodo C",           Tipo="ARISTA_CREADA",     Puntos=150, Parametros={ NodoA="NodoB_z3", NodoB="NodoC_z3" } },
		-- ── Zona 4 ──────────────────────────────────────────────────────────────
		{ ID=9,  Zona="Zona_Estacion_4", Texto="Crea una arista entre Nodo A y Nodo B",   Tipo="ARISTA_CREADA", Puntos=100, Parametros={ NodoA="NodoA_z4", NodoB="NodoB_z4" } },
		{ ID=10, Zona="Zona_Estacion_4", Texto="Conecta Nodo C con Nodo D",               Tipo="ARISTA_CREADA", Puntos=100, Parametros={ NodoA="NodoC_z4", NodoB="NodoD_z4" } },
		{ ID=11, Zona="Zona_Estacion_4", Texto="Haz que el grafo sea completamente conexo",Tipo="GRAFO_CONEXO",  Puntos=300, Parametros={ Nodos={"NodoA_z4","NodoB_z4","NodoC_z4","NodoD_z4"} } },
	},

	Guia = {
		{ ID="carlos",     Label="Hablar con Carlos",    WaypointRef={ Tipo="PART_DIRECTA", BuscarEn="NIVEL_ACTUAL", Nombre="Objetivo_Carlos"         }, DestruirAlCompletar=false },
		{ ID="estacion_1", Zona="Zona_Estacion_1", Label="Ve a la Estacion 1", WaypointRef={ Tipo="PART_DIRECTA", BuscarEn="NIVEL_ACTUAL", Nombre="ZonaTrigger_Estacion1" }, DestruirAlCompletar=false },
		{ ID="estacion_2", Zona="Zona_Estacion_2", Label="Ve a la Estacion 2", WaypointRef={ Tipo="PART_DIRECTA", BuscarEn="NIVEL_ACTUAL", Nombre="ZonaTrigger_Estacion2" }, DestruirAlCompletar=false },
		{ ID="estacion_3", Zona="Zona_Estacion_3", Label="Ve a la Estacion 3", WaypointRef={ Tipo="PART_DIRECTA", BuscarEn="NIVEL_ACTUAL", Nombre="ZonaTrigger_Estacion3" }, DestruirAlCompletar=false },
		{ ID="estacion_4", Zona="Zona_Estacion_4", Label="Ve a la Estacion 4", WaypointRef={ Tipo="PART_DIRECTA", BuscarEn="NIVEL_ACTUAL", Nombre="ZonaTrigger_Estacion4" }, DestruirAlCompletar=false },
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
	Puntuacion    = { TresEstrellas=1500, DosEstrellas=900, RecompensaXP=150, PuntosConexion=50, PenaFallo=10 },
	Adyacencias   = {},
	Zonas         = {},
	NombresNodos  = {},
	AnalisisConfig = {},
	Misiones      = {},
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
	Puntuacion    = { TresEstrellas=2500, DosEstrellas=1500, RecompensaXP=200, PuntosConexion=50, PenaFallo=10 },
	Adyacencias   = {},
	Zonas         = {},
	NombresNodos  = {},
	AnalisisConfig = {},
	Misiones      = {},
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
	Puntuacion    = { TresEstrellas=4000, DosEstrellas=2500, RecompensaXP=300, PuntosConexion=50, PenaFallo=10 },
	Adyacencias   = {},
	Zonas         = {},
	NombresNodos  = {},
	AnalisisConfig = {},
	Misiones      = {},
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
	Puntuacion    = { TresEstrellas=8000, DosEstrellas=5000, RecompensaXP=500, PuntosConexion=50, PenaFallo=10 },
	Adyacencias   = {},
	Zonas         = {},
	NombresNodos  = {},
	AnalisisConfig = {},
	Misiones      = {},
}

return LevelsConfig