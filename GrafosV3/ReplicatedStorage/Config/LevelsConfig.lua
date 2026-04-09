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
	Generadores = { "NodoE_z4" },

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

		-- Zona 4: Conectividad — 5 estaciones + generador
		--   Ruta sur→norte: El Ejido(A) · La Pradera(B) · La Carolina(C) · Iñaquito(F) · El Labrador(D)
		--   Empresa Eléctrica(E) alimenta solo a El Ejido (nodo de entrada)
		["NodoE_z4"] = {"NodoA_z4"},                                          -- Empresa Eléctrica
		["NodoA_z4"] = {"NodoE_z4", "NodoB_z4", "NodoC_z4"},                  -- El Ejido
		["NodoB_z4"] = {"NodoA_z4", "NodoC_z4", "NodoD_z4"},                  -- La Pradera
		["NodoC_z4"] = {"NodoA_z4", "NodoB_z4", "NodoF_z4"},                  -- La Carolina
		["NodoD_z4"] = {"NodoB_z4", "NodoF_z4"},                              -- El Labrador
		["NodoF_z4"] = {"NodoC_z4", "NodoD_z4"},                              -- Iñaquito

		["PostePanel"]     = {"toma_corriente"},
		["toma_corriente"] = {"PostePanel"},
	},

	Zonas = {
		["Zona_Estacion_1"] = { Trigger = "ZonaTrigger_Estacion1", Descripcion = "Nodos y Aristas",  Dialogo = "Zona1_NodosAristas"   },
		["Zona_Estacion_2"] = { Trigger = "ZonaTrigger_Estacion2", Descripcion = "Grado de Nodo",    Dialogo = "Zona2_GradoNodo",       CarpetaLuz = "Zona_luz_2" },
		["Zona_Estacion_3"] = { Trigger = "ZonaTrigger_Estacion3", Descripcion = "Grafos Dirigidos", Dialogo = "Zona3_GrafosDirigidos", CarpetaLuz = "Zona_luz_3" },
		["Zona_Estacion_4"] = { Trigger = "ZonaTrigger_Estacion4", Descripcion = "Conectividad",     Dialogo = "Zona4_Conectividad",    CarpetaLuz = "Zona_luz_4" },
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
		["NodoE_z4"]      = "Empresa Eléctrica",
		["NodoA_z4"]      = "Estacion El Ejido",
		["NodoB_z4"]      = "Estacion La Pradera",
		["NodoC_z4"]      = "Estacion La Carolina",
		["NodoF_z4"]      = "Estacion Iñaquito",
		["NodoD_z4"]      = "Estacion El Labrador",
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
			nodoInicio = "NodoE_z4",
			nodoFin    = "NodoD_z4",
			conceptos  = {
				bfs = {
					intro = "BFS parte desde Empresa Eléctrica y halla el camino más corto (en saltos) hasta cada estación del metro.",
					pasos = {
						[2]  = "Nivel 0: solo Empresa Eléctrica en la cola. La red aún no fue explorada.",
						[7]  = "Procesamos el nodo del frente — sus estaciones vecinas pasan al siguiente nivel.",
						[9]  = "Nueva estación descubierta. Su distancia = saltos desde Empresa Eléctrica.",
						[13] = "Cola vacía — BFS alcanzó todas las estaciones desde el generador.",
					},
				},
				dfs = {
					intro = "DFS parte desde Empresa Eléctrica y se adentra rama a rama. El camino hallado puede no ser el más corto.",
					pasos = {
						[2]  = "Apilamos Empresa Eléctrica. DFS irá tan profundo como pueda antes de retroceder.",
						[7]  = "Estación ya visitada — la descartamos del tope de la pila.",
						[8]  = "Nueva estación: la marcamos visitada y apilamos sus vecinas.",
						[12] = "Pila vacía — DFS recorrió toda la red desde el generador.",
					},
				},
				dijkstra = {
					intro = "Dijkstra garantiza la ruta de MENOR COSTO desde Empresa Eléctrica hasta Est. El Labrador. En un grafo con pesos iguales equivale a BFS.",
					pasos = {
						[2]  = "Inicializamos: dist[Empresa Eléctrica]=0, todas las estaciones=∞.",
						[7]  = "Extraemos la estación más 'barata' de alcanzar hasta el momento.",
						[9]  = "Relajación: si llegar por aquí es más económico, actualizamos la distancia.",
						[13] = "Cola vacía — Dijkstra garantiza las rutas mínimas a todas las estaciones.",
					},
				},
				prim = {
					intro = "Prim construye el Árbol de Expansión Mínima (MST): el conjunto de cables que conecta todas las estaciones con el menor tendido total.",
					pasos = {
						[2]  = "Raíz: Empresa Eléctrica con key=0. El resto de estaciones empieza en ∞.",
						[8]  = "La estación con key mínima se integra al MST. Se actualizan sus vecinas.",
						[9]  = "Si este cable es más corto para llegar a una estación, actualizamos su key.",
						[13] = "MST completo — toda la red conectada con el tendido mínimo de cables.",
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
		{ ID=9,  Zona="Zona_Estacion_4", Texto="Conecta Empresa Eléctrica con Est. El Ejido",         Tipo="ARISTA_CREADA", Puntos=100, Parametros={ NodoA="NodoE_z4", NodoB="NodoA_z4" } },
		{ ID=10, Zona="Zona_Estacion_4", Texto="Conecta Est. Iñaquito con Est. El Labrador",          Tipo="ARISTA_CREADA", Puntos=100, Parametros={ NodoA="NodoF_z4", NodoB="NodoD_z4" } },
		{ ID=11, Zona="Zona_Estacion_4", Texto="Haz el grafo completamente conexo (6 nodos)",         Tipo="GRAFO_CONEXO",  Puntos=300, Parametros={ Nodos={"NodoE_z4","NodoA_z4","NodoB_z4","NodoC_z4","NodoF_z4","NodoD_z4"} } },
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
-- NIVEL 1: EL BARRIO ANTIGUO (La Ferroviaria)
-- ============================================
LevelsConfig[1] = {
	Nombre           = "El Barrio Antiguo",
	DescripcionCorta = "El Barrio Antiguo esta a oscuras. Usa el Panel de Analisis para estudiar el cableado desordenado y reconecta los nodos aislados.",
	ImageId          = "rbxassetid://87116895331866",
	Modelo           = "Nivel1",

	Tag       = "NIVEL 1 · CONECTIVIDAD",
	Seccion   = "Busqueda y Conectividad",
	Algoritmo = "BFS",
	Conceptos = { "Onda por Capas", "Mínimo de Saltos", "Nodos Aislados", "Grafo Conexo (100%)" },
	Generadores = { "Gen_Estacion_z1" },

	ConfiguracionEntorno = {
		Reloj = 0, -- 00:00:00 (Medianoche)
		IluminacionAmbiental = Color3.fromRGB(15, 15, 35), -- Azul muy oscuro
		IluminacionExteriores = Color3.fromRGB(10, 10, 25),
		LinternaJugador = true -- Activa la luz cálida que sigue al jugador
	},
	
	CablesIniciales = {
		-- Conexiones que estarán pre-creadas y son válidas
		{"Gen_Estacion_z1", "Casa_Estacion1_z1"},
		{"Parque_z1", "Poste_Mercado_z2"}
	},
	CablesDefectuosos = {
		-- Conexiones pre-creadas visualmente, pero que no enrutan energía y ocasionan nodos aislados
		{"Poste_Canchas_z3", "Casa_Canchas_z3"}
	},

	Puntuacion = {
		TresEstrellas  = 2500,
		DosEstrellas   = 1500,
		RecompensaXP   = 800,
		PuntosConexion = 50,
		PenaFallo      = 20,
		PuntosPreguntaCorrecta = 100, -- Para otorgar 100 puntos en respuestas correctas
	},

	Adyacencias = {
		-- Zona 1: Estación Plana
		["Gen_Estacion_z1"] = {"Casa_Estacion1_z1", "Casa_Estacion2_z1"},
		["Casa_Estacion1_z1"] = {"Gen_Estacion_z1","Parque_z1"},
		["Casa_Estacion2_z1"] = {"Gen_Estacion_z1","Parque_z1","Parque_z2"},
		["Parque_z1"] = {"Casa_Estacion1_z1","Casa_Estacion2_z1", "Poste_Mercado_z2"},

		-- Zona 2: Mercado Central
		["Poste_Mercado_z2"]  = {"Parque_z1", "Puesto_Mercado_z2","Parque_z2"},
		["Puesto_Mercado_z2"] = {"Poste_Mercado_z2", "Poste_Canchas_z3"},
		["Parque_z2"]={"Poste_Mercado_z2","Casa_Estacion1_z1"},

		-- Zona 3: Las Canchas
		["Poste_Canchas_z3"] = {"Puesto_Mercado_z2", "Casa_Canchas_z3","Parque_z1","Poste2_Canchas_z3"},
		["Casa_Canchas_z3"]  = {"Poste_Canchas_z3", "Poste1_z4"},
		["Poste2_Canchas_z3"]={"Puesto_Mercado_z2","Poste_Canchas_z3"},

		-- Zona 4: Parque Central (Componente inicialmente aislado)
		["Poste1_z4"] = {"Poste2_z4", "Fuente_z4", "Casa_Canchas_z3"},
		["Fuente_z4"] = {"Poste1_z4", "Poste3_z4", "Kiosco_z4"},
		["Poste2_z4"] = {"Poste1_z4", "Poste3_z4"},
		["Poste3_z4"] = {"Poste2_z4", "Fuente_z4", "Poste4_z4"},
		["Poste4_z4"] = {"Poste3_z4", "Kiosco_z4"},
		["Kiosco_z4"] = {"Fuente_z4", "Poste4_z4"},
	},

	Zonas = {
		["Zona_Ferroviaria_1"] = { 
			Trigger = "ZonaTrigger_Inicio",  
			Descripcion = "La Estación Plana", 
			Dialogo = "Nivel1_Estacion",
			CarpetaLuz = "Zona_luz_1"
		},
		["Zona_Mercado_2"] = { 
			Trigger = "ZonaTrigger_Mercado", 
			Descripcion = "Mercado Central", 
			Dialogo = "Nivel1_Mercado",
			CarpetaLuz = "Zona_luz_2"
		},
		["Zona_Canchas_3"] = { 
			Trigger = "ZonaTrigger_Canchas", 
			Descripcion = "Las Canchas Barriales", 
			Dialogo = "Nivel1_Canchas",
			CarpetaLuz = "Zona_luz_3"
		},
		["Zona_Parque_4"] = { 
			Trigger = "ZonaTrigger_Parque", 
			Descripcion = "Parque del Barrio", 
			Dialogo = "Nivel1_Parque",
			CarpetaLuz = "Zona_luz_4"
		},
	},

	NombresNodos = {
		["Gen_Estacion_z1"]   = "Generador Principal",
		["Casa_Estacion1_z1"] = "Casa Estación 1",
		["Casa_Estacion2_z1"] = "Casa Estación 2",
		["Parque_z1"]         = "Parque de la Estación",
		["Poste_Mercado_z2"]  = "Poste del Mercado",
		["Puesto_Mercado_z2"] = "Puesto del Mercado",
		["Parque_z2"]         = "Parque del Mercado",
		["Poste_Canchas_z3"]  = "Poste de las Canchas",
		["Poste2_Canchas_z3"] = "Segundo Poste de las Canchas",
		["Casa_Canchas_z3"]   = "Casa de las Canchas",
		["Poste1_z4"] = "Poste 1 del Parque",
		["Poste2_z4"] = "Poste 2 del Parque",
		["Poste3_z4"] = "Poste 3 del Parque",
		["Poste4_z4"] = "Poste 4 del Parque",
		["Fuente_z4"] = "Fuente Central",
		["Kiosco_z4"] = "Kiosco del Parque",
	},

	Misiones = {
		-- ── Zona 1: Estación ──────────────────────────────────────────────────
		{ ID=101,  Zona="Zona_Ferroviaria_1", Texto="Selecciona el Generador Principal",             Tipo="NODO_SELECCIONADO", Puntos=100, Parametros={ Nodo="Gen_Estacion_z1" } },
		{ ID=1011, Zona="Zona_Ferroviaria_1", Texto="Conecta las dos casas al Generador",            Tipo="GRAFO_CONEXO",     Puntos=150, Parametros={ Nodos={"Gen_Estacion_z1","Casa_Estacion1_z1","Casa_Estacion2_z1"} } },
		{ ID=1012, Zona="Zona_Ferroviaria_1", Texto="Ilumina toda la Estación (incluye el Parque)",  Tipo="GRAFO_CONEXO",     Puntos=150, Parametros={ Nodos={"Gen_Estacion_z1","Casa_Estacion1_z1","Casa_Estacion2_z1","Parque_z1"} } },

		-- ── Zona 2: Mercado ───────────────────────────────────────────────────
		{ ID=102,  Zona="Zona_Mercado_2", Texto="Tiende el cable desde el Parque al Poste del Mercado",   Tipo="ARISTA_CREADA", Puntos=200, Parametros={ NodoA="Parque_z1",        NodoB="Poste_Mercado_z2" } },
		{ ID=1021, Zona="Zona_Mercado_2", Texto="Conecta también el Parque del Mercado",                  Tipo="ARISTA_CREADA", Puntos=100, Parametros={ NodoA="Parque_z2",        NodoB="Poste_Mercado_z2" } },
		{ ID=1022, Zona="Zona_Mercado_2", Texto="Ilumina todo el Mercado",                                Tipo="GRAFO_CONEXO",  Puntos=200, Parametros={ Nodos={"Gen_Estacion_z1","Casa_Estacion1_z1","Parque_z1","Poste_Mercado_z2","Puesto_Mercado_z2","Parque_z2"} } },

		-- ── Zona 3: Canchas ────────────────────────────────────────────────────
		{ ID=103,  Zona="Zona_Canchas_3", Texto="Lleva energía al Poste de las Canchas",               Tipo="ARISTA_CREADA", Puntos=200, Parametros={ NodoA="Puesto_Mercado_z2", NodoB="Poste_Canchas_z3" } },
		{ ID=1031, Zona="Zona_Canchas_3", Texto="Conecta el Segundo Poste de las Canchas",              Tipo="ARISTA_CREADA", Puntos=150, Parametros={ NodoA="Poste_Canchas_z3",  NodoB="Poste2_Canchas_z3" } },
		{ ID=1032, Zona="Zona_Canchas_3", Texto="Ilumina todas las Canchas",                            Tipo="GRAFO_CONEXO",  Puntos=200, Parametros={ Nodos={"Gen_Estacion_z1","Parque_z1","Poste_Mercado_z2","Puesto_Mercado_z2","Poste_Canchas_z3","Poste2_Canchas_z3","Casa_Canchas_z3"} } },

		-- ── Zona 4: Parque del Barrio ──────────────────────────────────────────
		{ ID=104,  Zona="Zona_Parque_4", Texto="Tiende el puente desde las Canchas al Parque",  Tipo="ARISTA_CREADA", Puntos=300, Parametros={ NodoA="Casa_Canchas_z3", NodoB="Poste1_z4" } },
		{ ID=1041, Zona="Zona_Parque_4", Texto="Conecta la Fuente Central al Poste 1",          Tipo="ARISTA_CREADA", Puntos=150, Parametros={ NodoA="Poste1_z4",       NodoB="Fuente_z4" } },
		{ ID=1042, Zona="Zona_Parque_4", Texto="Ilumina el Parque (Postes, Fuente y Kiosco)",   Tipo="GRAFO_CONEXO",  Puntos=200, Parametros={ Nodos={"Poste1_z4","Poste2_z4","Poste3_z4","Poste4_z4","Fuente_z4","Kiosco_z4"} } },
		{ ID=105,  Zona="Zona_Parque_4", Texto="¡Grafo 100% conexo! Ilumina todo el barrio",    Tipo="GRAFO_CONEXO",  Puntos=500, Parametros={ Nodos={"Gen_Estacion_z1","Casa_Estacion1_z1","Casa_Estacion2_z1","Parque_z1","Poste_Mercado_z2","Puesto_Mercado_z2","Parque_z2","Poste_Canchas_z3","Poste2_Canchas_z3","Casa_Canchas_z3","Poste1_z4","Poste2_z4","Poste3_z4","Poste4_z4","Fuente_z4","Kiosco_z4"} } },
	},

	AnalisisConfig = {
		["Zona_Ferroviaria_1"] = {
			algoritmos = { "bfs" },
			nodoInicio = "Gen_Estacion_z1",
			conceptos = {
				bfs = {
					intro = "Abre el Panel de Análisis. Al ejecutar BFS paso a paso, verás cómo el algoritmo explora la red capa por capa, encolando todos los vecinos directos simultáneamente.",
					pasos = {
						[2]  = "El algoritmo encola el Generador y comienza a escanear sus vecinos directos en el Nivel 1.",
						[13] = "Exploración terminada. El algoritmo ha recorrido todos los nodos alcanzables de esta zona.",
					},
				},
			},
		},
		["Zona_Mercado_2"] = {
			algoritmos = { "bfs" },
			nodoInicio = "Poste_Mercado_z2",
			conceptos = {
				bfs = {
					intro = "En el Analizador, observa cómo explorar por capas le garantiza a BFS hallar las rutas con la menor cantidad posible de postes (vía más corta en saltos).",
					pasos = {
						[2]  = "El algoritmo recorre la red sin importar distancias métricas, priorizando el nivel de saltos.",
						[13] = "Verificación completada. El Mercado ha sido explorado con el mínimo de saltos posibles.",
					},
				},
			},
		},
		["Zona_Canchas_3"] = {
			algoritmos = { "bfs" },
			nodoInicio = "Poste_Canchas_z3",
			conceptos = {
				bfs = {
					intro = "Aquí descubrirás gráficamente si el Alcalde mintió. Ejecuta el algoritmo y verás que la exploración se detiene al encontrar un vacío: un sector aislado.",
					pasos = {
						[2]  = "El algoritmo avanza por Las Canchas añadiendo vecinos a su Cola FIFO.",
						[13] = "Algoritmo detenido con cola vacía. Hay casas sin visitar. ¡Acabamos de detectar un Componente Aislado por falta de cables!",
					},
				},
			},
		},
		["Zona_Parque_4"] = {
			algoritmos = { "bfs" },
			nodoInicio = "Poste1_z4",
			conceptos = {
				bfs = {
					intro = "El Parque tiene 6 nodos: 4 postes de alumbrado, la Fuente Central y el Kiosco. BFS parte desde el Poste 1 y cubre todo el subgrafo en 2 capas. Conecta primero el cable desde las Canchas y observa cómo se expande.",
					pasos = {
						[2]  = "Capa 0: Poste 1. BFS encola a Poste 2 y Fuente como vecinos directos.",
						[7]  = "Capa 1: procesamos Fuente y Poste 2. Sus vecinos (Poste 3, Kiosco) pasan a la cola.",
						[13] = "¡100% de nodos visitados en 2 capas! El Parque forma un subgrafo completamente conexo.",
					},
				},
			},
		},
	},
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