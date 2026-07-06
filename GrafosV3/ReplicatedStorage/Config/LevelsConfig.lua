local LevelsConfig = {}

-- ============================================
-- NIVEL 0: LABORATORIO DE GRAFOS
-- ============================================
LevelsConfig[0] = {
	Nombre           = "Laboratorio de Grafos",
	DescripcionCorta = "Aprende teoria de grafos a traves de 4 zonas educativas.",
	Historia         = "Estas instalaciones de pruebas de la Empresa Electrica fueron creadas para simular lo que el Alcalde hizo mal en la ciudad. Carlos te entrenara en nodos, aristas, grafos dirigidos y conectividad para que puedas detectar cables mal tendidos, rutas inutiles y sobrecargas. Cada ejercicio aqui te prepara para auditar los contratos inflados del Alcalde.",
	ImageId          = "rbxassetid://87116895331866",
	Modelo           = "Nivel0",

	Tag       = "NIVEL 0 · FUNDAMENTOS",
	Seccion   = "Introduccion",
	Algoritmo = "Grafos No Dirigidos",
	Conceptos = { "Nodos", "Aristas", "Adyacencia", "Grado" },
	Generadores = { "NodoE_z4" },
	DialogoInicial = "Bienvenida_Laboratorio",

	Puntuacion = {
		TresEstrellas  = 1250,
		DosEstrellas   = 600,
		RecompensaXP   = 500,
		PuntosConexion = 50,
		PenaFallo      = 10,
	},

	Presupuesto = {
		Inicial = 250,
		AdvertenciaBajo = 50,
	},

	CostosReparacion = {
		["NodoC_z4"] = 200,
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

	},

	LimitesGrado = {
		-- Zona 4: La Carolina tiene un transformador viejo que solo soporta 2 conexiones.
		-- CablesMaximos representa la cantidad total de cables conectados al nodo.
		["NodoC_z4"] = { CablesMaximos = 2, QuitarLimiteAlReparar = false },
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
		{ ID=12, Zona="Zona_Estacion_4", Texto="Observa la sobrecarga en La Carolina",                Tipo="SOBRECARGA_EXPERIMENTADA", Puntos=100, Parametros={ Nodo="NodoC_z4" } },
		{ ID=13, Zona="Zona_Estacion_4", Texto="Repara La Carolina tras la explosion",                Tipo="NODO_REPARADO", Puntos=150, Parametros={ Nodo="NodoC_z4" } },
	},

	Guia = {
		{ ID="carlos",     Label="Hablar con Carlos",    WaypointRef={ Tipo="PART_DIRECTA", BuscarEn="NIVEL_ACTUAL", Nombre="Objetivo_Carlos"         }, DestruirAlCompletar=false },
		{ ID="estacion_1", Zona="Zona_Estacion_1", Label="Ve a la Zona 1: Nodos y Aristas", WaypointRef={ Tipo="PART_DIRECTA", BuscarEn="NIVEL_ACTUAL", Nombre="ZonaTrigger_Estacion1" }, DestruirAlCompletar=false },
		{ ID="estacion_2", Zona="Zona_Estacion_2", Label="Ve a Zona 2: Grado de un Nodo", WaypointRef={ Tipo="PART_DIRECTA", BuscarEn="NIVEL_ACTUAL", Nombre="ZonaTrigger_Estacion2" }, DestruirAlCompletar=false },
		{ ID="estacion_3", Zona="Zona_Estacion_3", Label="Ve a la Zona 3: Grafos Dirigidos", WaypointRef={ Tipo="PART_DIRECTA", BuscarEn="NIVEL_ACTUAL", Nombre="ZonaTrigger_Estacion3" }, DestruirAlCompletar=false },
		{ ID="estacion_4", Zona="Zona_Estacion_4", Label="Ve a la Zona 4: Conectividad", WaypointRef={ Tipo="PART_DIRECTA", BuscarEn="NIVEL_ACTUAL", Nombre="ZonaTrigger_Estacion4" }, DestruirAlCompletar=false },
	},

	Bloqueos = {
		Puerta_Principal_z1 = { Dialogo = "Bienvenida_1" },
		Muro_Simple_z2      = { Zona = "Zona_Estacion_1" },
		Muro_Simple_z3	={ Zona = "Zona_Estacion_2" },
		Muro_Simple_z4	={ Zona = "Zona_Estacion_3" },
	}
}


-- ============================================
-- NIVEL 1: EL BARRIO ANTIGUO (La Ferroviaria)
-- ============================================
LevelsConfig[1] = {
	Nombre           = "El Barrio Antiguo",
	DescripcionCorta = "El Barrio Antiguo esta a oscuras. Usa el Panel de Analisis para estudiar el cableado desordenado y reconecta los nodos aislados.",
	Historia         = "A las doce de la noche todo deberia estar iluminado, pero las casas estan a oscuras. El Alcalde asegura que su plan fue impecable y que alguien saboteo la red, pero Carlos descubre la verdad: una sobrecarga en el Mercado Central derribo el poste principal y el grafo electrico colapso. Junto a Carlos deberas recorrer la Estacion, el Mercado, las Canchas y el Parque usando DFS y BFS para restaurar la luz.",
	ImageId          = "rbxassetid://134869694289632",
	Modelo           = "Nivel1",

	Tag       = "NIVEL 1 · CONECTIVIDAD",
	Seccion   = "Busqueda y Conectividad",
	Algoritmo = "BFS / DFS",
	Conceptos = { "Onda por Capas", "Mínimo de Saltos", "Nodos Aislados", "Grafo Conexo (100%)" },
	Generadores = { "Gen_Estacion_z1" },

	ConfiguracionEntorno = {
		Reloj = 0, -- 00:00:00 (Medianoche)
		IluminacionAmbiental = Color3.fromRGB(15, 15, 35), -- Azul muy oscuro
		IluminacionExteriores = Color3.fromRGB(10, 10, 25),
		LinternaJugador = true -- Activa la luz cálida que sigue al jugador
	},

	Presupuesto = {
		Inicial = 250,
		AdvertenciaBajo = 50,
	},

	CostosReparacion = {
		["NodoC_z4"] = 200,
	},

	LimitesGrado = {
		["Poste_Mercado_z2"] = { CablesMaximos = 3, QuitarLimiteAlReparar = false },
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

	-- Requisito especial para 3 estrellas: responder todas las preguntas de diálogo correctamente
	RequiereDialogosCorrectos = true,
	TotalPreguntasDialogo = 4,  -- 0 (Estación) + 2 (Mercado) + 1 (Canchas) + 1 (Parque)

	Adyacencias = {
		-- Zona 1: Estación Plana
		["Gen_Estacion_z1"] = {"Casa_Estacion1_z1", "Casa_Estacion2_z1"},
		["Casa_Estacion1_z1"] = {"Casa_Estacion3_z1","Casa_Estacion4_z1"},
		["Casa_Estacion4_z1"] = {"Poste2_z4","Casa_Estacion3_z1"},
		["Casa_Estacion3_z1"] = {"Casa_Estacion2_z1","Poste2_z4","Parque_z1"},
		["Casa_Estacion2_z1"] = {"Gen_Estacion_z1","Parque_z1","Parque_z2"},
		["Parque_z1"] = {"Casa_Estacion2_z1", "Poste_Mercado_z2","Casa_Estacion3_z1"},

		-- Zona 2: Mercado Central
		["Poste_Mercado_z2"]  = {"Parque_z1", "Puesto_Mercado_z2","Parque_z2","Poste_Canchas_z3"},
		["Puesto_Mercado_z2"] = {"Poste_Mercado_z2", "Poste_Canchas_z3","Entrada_Tunel_z2","Poste_aux_z2"},
		["Entrada_Tunel_z2"] = {},
		["Poste_aux_z2"] = {},
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
			CarpetaLuz = "Zona_luz_2",
			NodosDaniados = {"Poste_Mercado_z2"}
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
		["Entrada_Tunel_z2"]= "Entrada del Túnel",
		["Poste_aux_z2"]         = "Poste auxiliar",
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
		{ ID=1022, Zona="Zona_Mercado_2", Texto="Traspasa energia al mercado",                                Tipo="GRAFO_CONEXO",  Puntos=200, Parametros={ Nodos={"Gen_Estacion_z1","Casa_Estacion1_z1","Parque_z1","Poste_Mercado_z2","Puesto_Mercado_z2","Parque_z2"} } },
		{ ID=1023, Zona="Zona_Mercado_2", Texto="¡Emergencia eléctrica! Repara el poste dañado y reconecta el Mercado antes de que el tiempo se agote.", Tipo="EMERGENCIA", Puntos=400, Parametros={ Nodos={"Parque_z1","Poste_Mercado_z2","Puesto_Mercado_z2","Parque_z2"}, TiempoLimite=90 } },

		-- ── Zona 3: Canchas ────────────────────────────────────────────────────
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
			algoritmos = { "dfs", "bfs" },
			nodoInicio = "Gen_Estacion_z1",
			conceptos = {
				dfs = {
					intro = "Abre el Panel de Análisis y ejecuta DFS. Observa cómo la pila LIFO hace que el algoritmo se adentre lo más posible por cada rama antes de retroceder.",
					pasos = {
						[2]  = "DFS apila el Generador y toma su primer vecino, adentrándose en la rama.",
						[12] = "DFS ha agotado una rama y retrocede. La pila decide el siguiente camino a explorar.",
					},
				},
				bfs = {
					intro = "También puedes ejecutar BFS para comparar. Mientras DFS se adentra en profundidad, BFS expande en anillos desde el Generador.",
					pasos = {
						[2]  = "BFS encola el Generador y procesa todos sus vecinos directos simultáneamente.",
						[13] = "BFS termina todas las capas. Compara con DFS: mismo resultado, orden diferente.",
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
			algoritmos = { "dfs" },
			nodoInicio = "Poste_Canchas_z3",
			conceptos = {
				dfs = {
					intro = "Ejecuta DFS desde el Poste de las Canchas. Verás cómo se adentra a fondo en cada rama antes de retroceder, descubriendo rápidamente dónde se corta la conexión.",
					pasos = {
						[2]  = "DFS apila el Poste de las Canchas y sigue su primer vecino hacia el fondo de la rama.",
						[12] = "DFS ha llegado al final de una rama. La pila se vacía parcialmente: ¡detectamos un callejón sin salida!",
						[13] = "DFS termina con nodos sin visitar. Esos nodos forman un Componente Conexo Aislado del grafo principal.",
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

	Guia = {
		{ ID="estacion_1",    Zona="Zona_Ferroviaria_1", Label="Ve a la Estacion Plana",    WaypointRef={ Tipo="PART_DIRECTA", BuscarEn="NIVEL_ACTUAL", Nombre="ZonaTrigger_Inicio"   }, DestruirAlCompletar=false },
		{ ID="mercado_2",     Zona="Zona_Mercado_2",     Label="Ve al Mercado Central",     WaypointRef={ Tipo="PART_DIRECTA", BuscarEn="NIVEL_ACTUAL", Nombre="ZonaTrigger_Mercado"  }, DestruirAlCompletar=false },
		{ ID="canchas_3",     Zona="Zona_Canchas_3",     Label="Ve a las Canchas",          WaypointRef={ Tipo="PART_DIRECTA", BuscarEn="NIVEL_ACTUAL", Nombre="ZonaTrigger_Canchas"  }, DestruirAlCompletar=false },
		{ ID="parque_4",      Zona="Zona_Parque_4",      Label="Ve al Parque del Barrio",   WaypointRef={ Tipo="PART_DIRECTA", BuscarEn="NIVEL_ACTUAL", Nombre="ZonaTrigger_Parque"   }, DestruirAlCompletar=false },
	},

	Bloqueos = {
		Muro_PuertaMercado = { Zona = "Zona_Ferroviaria_1" },
	},
}



-- ============================================
-- ============================================
-- NIVEL 2: LA RUTA MAS CORTA
-- ============================================
-- Concepto: Algoritmo de Dijkstra.
-- El jugador aprende que una red puede tener muchos caminos entre dos nodos,
-- pero solo uno tiene el menor costo acumulado. Cada arista tiene un peso
-- (metros de cable) y un costo en dinero.
-- ============================================
LevelsConfig[2] = {
	Nombre           = "La Ruta Mas Corta",
	DescripcionCorta = "La ciudad necesita la ruta de cable mas economica. Usa Dijkstra para encontrar el camino de menor costo acumulado.",
	Historia         = "La ciudad necesita reconectar su red electrica gastando la menor cantidad de cable posible. No basta con iluminar todo: debes elegir la ruta mas barata. Carlos te ensenara el algoritmo de Dijkstra para sumar pesos, comparar costos acumulados y relajar aristas. Desde la Fabrica hasta la Oficina de Analisis, cada metro de cable cuenta.",
	ImageId          = "rbxassetid://71112098383800",
	Modelo           = "Nivel2",

	Tag       = "NIVEL 2 · DIJKSTRA",
	Seccion   = "Algoritmos de Ruta",
	Algoritmo = "Dijkstra",
	Conceptos = { "Dijkstra", "Peso de Arista", "Ruta Minima", "Costo Acumulado" },
	Generadores = { "Gen_Fabrica_z1" },

	Puntuacion = {
		TresEstrellas  = 2800,
		DosEstrellas   = 1600,
		RecompensaXP   = 600,
		PuntosConexion = 50,
		PenaFallo      = 15,
		PuntosPreguntaCorrecta = 100,
	},

	ConfiguracionEntorno = {
		Reloj = 0, -- 00:00:00 (Medianoche)
		IluminacionAmbiental = Color3.fromRGB(15, 15, 35), -- Azul muy oscuro
		IluminacionExteriores = Color3.fromRGB(10, 10, 25),
		LinternaJugador = true -- Activa la luz cálida que sigue al jugador
	},


	-- Presupuesto para construir cables (cada arista consume peso x CostoPorMetro)
	Presupuesto = {
		-- La red principal óptima cuesta $10 500; queda un margen pequeño
		-- para equivocarse y corregir sin permitir cablear todas las alternativas.
		Inicial = 12000,
		AdvertenciaBajo = 2000,
	},

	-- Costo por metro de cable (en dolares). El peso de la arista = metros.
	CostoPorMetro = 500,

	-- Requisito especial para 3 estrellas: responder todas las preguntas correctamente
	RequiereDialogosCorrectos = true,
	TotalPreguntasDialogo = 3,

	Adyacencias = {
		-- Zona 1: La Ciudad Grande
		["Gen_Fabrica_z1"]    = {"Entrada_z1", "Sala_Maquinas_z1", "Patio_Carga_z1"},
		["Entrada_z1"]        = {"Gen_Fabrica_z1", "Sala_Maquinas_z1", "Patio_Carga_z1", "Oficinas_Admin_z1"},
		["Sala_Maquinas_z1"]  = {"Entrada_z1", "Gen_Fabrica_z1", "Cruce_z1", "Oficinas_Admin_z1"},
		["Cruce_z1"]          = {"Sala_Maquinas_z1", "Tunel_Norte_z2", "Paso_Sur_z2", "Oficinas_Admin_z1"},
		["Patio_Carga_z1"]    = {"Gen_Fabrica_z1", "Entrada_z1"},
		["Oficinas_Admin_z1"] = {"Entrada_z1", "Sala_Maquinas_z1", "Cruce_z1"},

		-- Zona 2: El Barrio Oeste
		["Tunel_Norte_z2"]    = {"Cruce_z1", "Cisterna_z2", "Almacen_z2", "Taller_Mecanico_z2"},
		["Paso_Sur_z2"]       = {"Cruce_z1", "Puente_z2", "Mercado_Negro_z2"},
		["Cisterna_z2"]       = {"Tunel_Norte_z2", "Puente_z2"},
		["Almacen_z2"]        = {"Tunel_Norte_z2", "Taller_Mecanico_z2"},
		["Puente_z2"]         = {"Paso_Sur_z2", "Cisterna_z2", "Oficina_z3", "Mercado_Negro_z2"},

		-- Zona 3: La Oficina de Análisis
		["Oficina_z3"]        = {"Puente_z2", "Servidor_z3", "Antena_z3", "Laboratorio_z3", "Sala_Reuniones_z3"},
		["Servidor_z3"]       = {"Oficina_z3", "Antena_z3", "Laboratorio_z3"},
		["Antena_z3"]         = {"Oficina_z3", "Servidor_z3", "Sala_Reuniones_z3"},
	},

	-- Pesos de cada arista (actualizado con las nuevas conexiones)
	PesosAristas = {
		-- Zona 1
		["Gen_Fabrica_z1|Entrada_z1"]      = 2,
		["Gen_Fabrica_z1|Sala_Maquinas_z1"] = 10,
		["Gen_Fabrica_z1|Patio_Carga_z1"]  = 4,
		["Entrada_z1|Sala_Maquinas_z1"]    = 3,
		["Entrada_z1|Patio_Carga_z1"]      = 3,
		["Entrada_z1|Oficinas_Admin_z1"]   = 5,
		["Sala_Maquinas_z1|Cruce_z1"]      = 1,
		["Sala_Maquinas_z1|Oficinas_Admin_z1"] = 6,
		["Cruce_z1|Oficinas_Admin_z1"]     = 4,

		-- Zona 2
		["Cruce_z1|Tunel_Norte_z2"]        = 2,
		["Cruce_z1|Paso_Sur_z2"]           = 6,
		["Tunel_Norte_z2|Cisterna_z2"]     = 4,
		["Tunel_Norte_z2|Almacen_z2"]      = 7,
		["Paso_Sur_z2|Puente_z2"]          = 2,
		["Cisterna_z2|Puente_z2"]          = 1,

		-- Zona 3
		["Puente_z2|Oficina_z3"]           = 5,
		["Oficina_z3|Servidor_z3"]         = 2,
		["Oficina_z3|Antena_z3"]           = 4,
		["Servidor_z3|Antena_z3"]          = 1,
	},

	Zonas = {
		["Zona_Laberinto_1"] = {
			Trigger = "ZonaTrigger_Laberinto",
			Descripcion = "La Ciudad Grande",
			Dialogo = "Nivel2_CiudadGrande",
			CarpetaLuz = "Zona_luz_1",
			NodosDaniados = { "Gen_Fabrica_z1", "Entrada_z1", "Sala_Maquinas_z1" },
		},
		["Zona_BarrioOeste_2"] = {
			Trigger = "ZonaTrigger_BarrioOeste",
			Descripcion = "El Barrio Oeste",
			Dialogo = "Nivel2_BarrioOeste",
			CarpetaLuz = "Zona_luz_2",
		},
		["Zona_Oficina_3"] = {
			Trigger = "ZonaTrigger_Oficina",
			Descripcion = "Oficina de Analisis",
			Dialogo = "Nivel2_Oficina",
			CarpetaLuz = "Zona_luz_3",
			NodosDaniados = { "Oficina_z3" },
		},
	},

	-- Mapeo explicito de nodos por zona
	NodosZona = {
		["Zona_Laberinto_1"] = {
			"Gen_Fabrica_z1", "Entrada_z1", "Sala_Maquinas_z1",
			"Patio_Carga_z1", "Cruce_z1","Oficinas_Admin_z1"
		},
		["Zona_BarrioOeste_2"] = {
			"Cruce_z1", "Tunel_Norte_z2", "Paso_Sur_z2", "Cisterna_z2",
			"Almacen_z2", "Puente_z2", "Taller_Mecanico_z2", "Mercado_Negro_z2",
		},
		["Zona_Oficina_3"] = {
			"Oficina_z3", "Servidor_z3", "Antena_z3",
		},
	},



	NombresNodos = {
		["Gen_Fabrica_z1"]    = "Generador Ciudad",
		["Entrada_z1"]        = "Entrada de la Ciudad",
		["Cruce_z1"]          = "Cruce Principal",
		["Sala_Maquinas_z1"]  = "Sala de Maquinas",
		["Patio_Carga_z1"]    = "Patio de Carga",
		["Oficinas_Admin_z1"] = "Oficinas Administrativas",
		["Tunel_Norte_z2"]    = "Avenida Norte",
		["Paso_Sur_z2"]      = "Avenida Sur",
		["Cisterna_z2"]       = "Cisterna",
		["Almacen_z2"]        = "Almacen",
		["Puente_z2"]         = "Puente Metalico",
		["Taller_Mecanico_z2"] = "Taller Mecanico",
		["Mercado_Negro_z2"]   = "Mercado Negro",

		["Oficina_z3"]        = "Oficina de Analisis",
		["Servidor_z3"]       = "Servidor Central",
		["Antena_z3"]         = "Antena de Comunicaciones",
		["Laboratorio_z3"]     = "Laboratorio",
		["Sala_Reuniones_z3"] = "Sala de Reuniones",
	},

	AnalisisConfig = {
		["Zona_Laberinto_1"] = {
			algoritmos = { "dijkstra" },
			nodoInicio = "Gen_Fabrica_z1",
			nodoFin    = "Cruce_z1",
			conceptos  = {
				dijkstra = {
					intro = "Dijkstra encuentra la ruta de MENOR COSTO acumulado desde el Generador hasta el Cruce Principal. Los nodos secundarios ofrecen alternativas, pero solo una ruta tiene el menor costo total.",
					pasos = {
						[2]  = "Inicializamos: dist[Generador]=0, todos los demas nodos=∞.",
						[7]  = "Extraemos el nodo no visitado con menor distancia acumulada.",
						[9]  = "Relajacion: si llegar por aqui es mas barato, actualizamos la distancia del vecino.",
						[13] = "Cola vacia — Dijkstra garantiza la ruta minima al destino.",
					},
				},
			},
		},
		["Zona_BarrioOeste_2"] = {
			algoritmos = { "dijkstra" },
			nodoInicio = "Cruce_z1",
			nodoFin    = "Puente_z2",
			conceptos  = {
				dijkstra = {
					intro = "Desde el Cruce hay dos caminos hacia el Puente. Dijkstra suma los metros de cada arista y elige el camino mas corto en costo total.",
					pasos = {
						[2]  = "Cruce inicia con distancia 0. Sus vecinos reciben sus primeros costos.",
						[7]  = "Procesamos el nodo con menor distancia provisional.",
						[9]  = "Relajacion: encontramos una forma mas barata de llegar a un nodo.",
						[13] = "Ruta minima confirmada. El costo acumulado no puede mejorarse.",
					},
				},
			},
		},
		["Zona_Oficina_3"] = {
			algoritmos = { "dijkstra" },
			nodoInicio = "Oficina_z3",
			nodoFin    = "Antena_z3",
			conceptos  = {
				dijkstra = {
					intro = "Compara la conexion directa con la ruta por el Servidor. Dijkstra encuentra el camino mas barato desde la Oficina hasta la Antena.",
					pasos = {
						[2]  = "Oficina inicia con distancia 0. El resto empieza en infinito.",
						[7]  = "Extraemos el nodo con menor distancia acumulada.",
						[9]  = "Relajamos aristas: actualizamos si encontramos un camino mas barato.",
						[13] = "Destino alcanzado con costo minimo garantizado.",
					},
				},
			},
		},
	},

	Misiones = {
		-- Zona 1: Ciudad Grande
		{ ID=201, Zona="Zona_Laberinto_1", Texto="Selecciona el Generador Ciudad",                      Tipo="NODO_SELECCIONADO", Puntos=100, Parametros={ Nodo="Gen_Fabrica_z1" } },
		{ ID=203, Zona="Zona_Laberinto_1", Texto="Encuentra una ruta al Cruce Principal con peso total 5 o menor", Tipo="RUTA_COSTO", Puntos=200, Parametros={ Inicio="Gen_Fabrica_z1", Destino="Cruce_z1", PesoMaximo=5 } },
		{ ID=299, Zona="Zona_Laberinto_1", Texto="EMERGENCIA! Energiza el Cruce Principal en 60 segundos", Tipo="EMERGENCIA",       Puntos=500, Parametros={ NodosEnergizar={"Cruce_z1"}, TiempoLimite=60 } },

		-- Zona 2: Barrio Oeste
		{ ID=206, Zona="Zona_BarrioOeste_2", Texto="Tiende cable al Tunnel Norte desde el Cruce (costo 2)", Tipo="ARISTA_CREADA", Puntos=200, Parametros={ NodoA="Cruce_z1",       NodoB="Tunel_Norte_z2" } },
		{ ID=208, Zona="Zona_BarrioOeste_2", Texto="Conecta la Cisterna al Tunnel Norte (costo 4)",         Tipo="ARISTA_CREADA", Puntos=150, Parametros={ NodoA="Tunel_Norte_z2", NodoB="Cisterna_z2" } },
		{ ID=210, Zona="Zona_BarrioOeste_2", Texto="Completa la ruta minima hasta el Puente (costo total 7)", Tipo="ARISTA_CREADA", Puntos=150, Parametros={ NodoA="Cisterna_z2", NodoB="Puente_z2" } },
		{ ID=211, Zona="Zona_BarrioOeste_2", Texto="Energiza el Puente por el camino minimo",               Tipo="GRAFO_CONEXO",  Puntos=400, Parametros={ Nodos={"Cruce_z1","Tunel_Norte_z2","Cisterna_z2","Puente_z2"} } },
		{ ID=209, Zona="Zona_BarrioOeste_2", Texto="Habilita la Oficina desde el Puente",                    Tipo="ARISTA_CREADA", Puntos=200, Parametros={ NodoA="Puente_z2", NodoB="Oficina_z3" } },

		-- Zona 3: Oficina de Analisis
		{ ID=213, Zona="Zona_Oficina_3", Texto="Conecta el Servidor Central a la Oficina (costo 2)",    Tipo="ARISTA_CREADA", Puntos=150, Parametros={ NodoA="Oficina_z3", NodoB="Servidor_z3" } },
		{ ID=214, Zona="Zona_Oficina_3", Texto="Completa la ruta minima del Servidor a la Antena (costo total 3)", Tipo="ARISTA_CREADA", Puntos=150, Parametros={ NodoA="Servidor_z3", NodoB="Antena_z3" } },
	},

	Guia = {
		{ ID="ciudad_1",    Zona="Zona_Laberinto_1",    Label="Ve a la Ciudad Grande",      WaypointRef={ Tipo="PART_DIRECTA", BuscarEn="NIVEL_ACTUAL", Nombre="ZonaTrigger_Laberinto"    }, DestruirAlCompletar=false },
		{ ID="barrio_2",       Zona="Zona_BarrioOeste_2",  Label="Ve al Barrio Oeste",   WaypointRef={ Tipo="PART_DIRECTA", BuscarEn="NIVEL_ACTUAL", Nombre="ZonaTrigger_BarrioOeste"  }, DestruirAlCompletar=false },
		{ ID="oficina_3",      Zona="Zona_Oficina_3",      Label="Ve a la Oficina",      WaypointRef={ Tipo="PART_DIRECTA", BuscarEn="NIVEL_ACTUAL", Nombre="ZonaTrigger_Oficina"    }, DestruirAlCompletar=false },
	},
}

-- ============================================
-- NIVEL 3: EL ARBOL DE EXPANSION MINIMA
-- ============================================

LevelsConfig[3] = {
	Nombre           = "El Arbol de Expansion Minima",
	DescripcionCorta = "El presupuesto es ajustado. Usa Prim para conectar toda la red con el minimo tendido de cable.",
	Historia         = "Carlos encontro algo raro en los contratos del Alcalde: cables entre casi todas las viviendas, incluso donde no hacian falta. Cada conexion extra eleva el costo y satura los nodos. Debes auditar la propuesta con Prim, construyendo un Arbol de Expansion Minima sin ciclos ni desperdicio. La investigacion culmina en el Hospital Central, donde una emergencia electrica y una rueda de prensa decidirán si el Alcalde enfrenta la justicia.",
	ImageId          = "rbxassetid://78181422127836",
	Modelo           = "Nivel3",

	Tag       = "NIVEL 3 · PRIM + MST",
	Seccion   = "Algoritmos de Ruta",
	Algoritmo = "Prim",
	Conceptos = { "Prim", "Arbol de Expansion Minima", "Peso", "Conectar todo al minimo costo" },
	Generadores = { "Gen_Estacion_z1" },

	ConfiguracionEntorno = {
		Reloj = 0,
		IluminacionAmbiental = Color3.fromRGB(15, 15, 35),
		IluminacionExteriores = Color3.fromRGB(10, 10, 25),
		LinternaJugador = true,
	},

	-- Presupuesto del nivel (en dolares): cada arista consume su peso x CostoPorMetro
	Presupuesto = {
		-- MST global: peso 46 x $500 = $23 000; reparaciones: $900.
		-- El margen de $2 100 permite corregir, pero no mantener ciclos costosos.
		Inicial = 26000,
		AdvertenciaBajo = 2500,
	},

	CostosReparacion = {
		["Poste_Alcaldia_z2"]   = 300,
		["Poste_secundario_z2"] = 300,
		["Poste_principal_z2"]  = 300,
	},

	LimitesGrado = {
		["Poste_Casa1_z1"] = {
			CablesMaximos = 3,
			QuitarLimiteAlReparar = false,
		},
		["Poste_principal_z2"] = {
			CablesMaximos = 3,
			QuitarLimiteAlReparar = false,
		},
	},

	-- Costo por metro de cable (en dolares). El peso de la arista = metros.
	CostoPorMetro = 500,

	Puntuacion = {
		TresEstrellas  = 3500,
		DosEstrellas   = 2000,
		RecompensaXP   = 1000,
		PuntosConexion = 50,
		PenaFallo      = 15,
		PuntosPreguntaCorrecta = 100,
	},

	-- Requisito especial para 3 estrellas: responder todas las preguntas correctamente
	RequiereDialogosCorrectos = true,
	TotalPreguntasDialogo = 6,

	Adyacencias = {
		-- Zona 1: Sector Residencial
		["Gen_Estacion_z1"]   = {"Casa_Estacion1_z1", "Casa_Estacion2_z1", "Parque2_z1", "Poste_Casa1_z1", "Poste_Parque2_z1", "Parque_z1", "Poste_Canchas_z1"},
		["Casa_Estacion1_z1"] = {"Gen_Estacion_z1", "Poste_Parque2_z1", "Poste_principal_z2"}, -- Conexión interzona añadida
		["Poste_Casa1_z1"]    = {"Gen_Estacion_z1"},
		["Poste_Parque2_z1"]  = {"Gen_Estacion_z1", "Casa_Estacion1_z1", "Casa_Estacion2_z1", "Parque_z1"},
		["Casa_Estacion2_z1"] = {"Gen_Estacion_z1", "Poste_Parque2_z1", "Parque_z1"},
		["Parque_z1"]         = {"Gen_Estacion_z1", "Poste_Parque2_z1", "Casa_Estacion2_z1", "Parque2_z1"},
		["Parque2_z1"]        = {"Gen_Estacion_z1", "Parque_z1", "Poste_Canchas_z1"},
		["Poste_Canchas_z1"]  = {"Gen_Estacion_z1", "Parque2_z1"},

		-- Zona 2: Sector Hospitalario
		["Poste_Alcaldia_z2"]   = {"Poste_luz_z2", "Poste_secundario_z2", "Poste_parque_z2"},
		["Poste_luz_z2"]        = {"Poste_Alcaldia_z2", "Poste_secundario_z2", "PosteHospital_z2"},
		["Poste_parque_z2"]     = {"Poste_Alcaldia_z2", "Poste_principal_z2", "Poste_secundario_z2", "PosteHospital_z2"},
		["Poste_principal_z2"]  = {"Poste_secundario_z2", "Poste_parque_z2", "Casa_Estacion1_z1"}, -- Conexión interzona añadida
		["Poste_secundario_z2"] = {"Poste_Alcaldia_z2", "Poste_luz_z2", "Poste_principal_z2", "Poste_parque_z2"},
		["PosteCanchas_z2"]     = {"PosteHospital_z2"},
		["PosteHospital_z2"]    = {"PosteCanchas_z2", "Poste_parque_z2", "Poste_luz_z2"}
	},



	PesosAristas = {
		------------------------------------------------------------------------
		-- ZONA 1: SECTOR RESIDENCIAL (13 aristas internas)
		------------------------------------------------------------------------
		["Casa_Estacion1_z1|Gen_Estacion_z1"]   = 4,
		["Casa_Estacion1_z1|Poste_Parque2_z1"]  = 2,

		["Casa_Estacion2_z1|Gen_Estacion_z1"]   = 6,
		["Casa_Estacion2_z1|Parque_z1"]          = 1,
		["Casa_Estacion2_z1|Poste_Parque2_z1"]  = 3,

		["Gen_Estacion_z1|Parque2_z1"]          = 5,
		["Gen_Estacion_z1|Parque_z1"]           = 5,
		["Gen_Estacion_z1|Poste_Canchas_z1"]    = 4,
		["Gen_Estacion_z1|Poste_Casa1_z1"]       = 2,
		["Gen_Estacion_z1|Poste_Parque2_z1"]    = 3,

		["Parque2_z1|Parque_z1"]                = 6,
		["Parque2_z1|Poste_Canchas_z1"]          = 5,

		["Parque_z1|Poste_Parque2_z1"]          = 3,

		------------------------------------------------------------------------
		-- PUENTE INTERZONA (Conexión entre Zona 1 y Zona 2)
		------------------------------------------------------------------------
		["Casa_Estacion1_z1|Poste_principal_z2"] = 4,

		------------------------------------------------------------------------
		-- ZONA 2: SECTOR HOSPITALARIO (10 aristas reales corregidas)
		------------------------------------------------------------------------
		["Poste_Alcaldia_z2|Poste_luz_z2"]        = 3,
		["Poste_Alcaldia_z2|Poste_parque_z2"]     = 4,
		["Poste_Alcaldia_z2|Poste_secundario_z2"] = 2,

		["Poste_luz_z2|PosteHospital_z2"]        = 4,
		["Poste_luz_z2|Poste_secundario_z2"]     = 3,

		["Poste_parque_z2|PosteHospital_z2"]     = 5,
		["Poste_parque_z2|Poste_principal_z2"]    = 3,
		["Poste_parque_z2|Poste_secundario_z2"]  = 6,

		["Poste_principal_z2|Poste_secundario_z2"] = 5,

		["PosteCanchas_z2|PosteHospital_z2"]     = 6
	},

	CablesDefectuosos = {
		{"Poste_Alcaldia_z2", "Poste_secundario_z2"},
		{"Poste_principal_z2", "Poste_secundario_z2"},
	},

	Zonas = {
		["Zona_Residencial_1"] = {
			Trigger = "ZonaTrigger_Residencial",
			Descripcion = "Sector Residencial",
			Dialogo = "Nivel3_Presupuesto",
			CarpetaLuz = "Zona_luz_1"
		},
		["Zona_Hospital_2"] = {
			Trigger = "ZonaTrigger_Hospital",
			Descripcion = "Complejo Hospitalario",
			Dialogo = "Nivel3_Rutas",
			CarpetaLuz = "Zona_luz_2",
			NodosDaniados = {"Poste_Alcaldia_z2", "Poste_secundario_z2", "Poste_principal_z2"},
		},
		["Zona_Alcaldia"] = {
			Trigger = "ZonaTrigger_Alcaldia",
			Descripcion = "Alcaldía",
			-- Nivel3_Control.lua registra este diálogo con la clave Final_1.
			Dialogo = "Final_1",
			RequiereZonaCompleta = "Zona_Hospital_2",
		}
	},

	NodosZona = {
		["Zona_Residencial_1"] = {
			"Gen_Estacion_z1", "Casa_Estacion1_z1", "Casa_Estacion2_z1",
			"Parque2_z1", "Parque_z1", "Poste_Canchas_z1",
			"Poste_Casa1_z1", "Poste_Parque2_z1"
		},
		["Zona_Hospital_2"] = {
			"Poste_Alcaldia_z2", "Poste_luz_z2", "Poste_parque_z2",
			"Poste_principal_z2", "Poste_secundario_z2", "PosteCanchas_z2",
			"PosteHospital_z2"
		},
		-- Zona narrativa: no contiene nodos del grafo ni análisis algorítmico.
		["Zona_Alcaldia"] = {},
	},


	NombresNodos = {
		-- ========================================================================
		-- ZONA 1: SECTOR RESIDENCIAL
		-- ========================================================================
		["Gen_Estacion_z1"]   = "Subestación Residencial",
		["Casa_Estacion1_z1"] = "Casa Los Pinos",
		["Casa_Estacion2_z1"] = "Casa Las Acacias",
		["Parque2_z1"]        = "Parque Infantil",
		["Parque_z1"]         = "Parque Central",
		["Poste_Canchas_z1"]  = "Poste Deportivo",
		["Poste_Casa1_z1"]    = "Poste Los Pinos",
		["Poste_Parque2_z1"]  = "Poste Parque Infantil",

		-- ========================================================================
		-- ZONA 2: SECTOR HOSPITALARIO / CENTRO
		-- ========================================================================
		["Poste_Alcaldia_z2"]   = "Poste de la Alcaldía",
		["Poste_luz_z2"]        = "Poste de Luz Central",
		["Poste_parque_z2"]     = "Poste del Parque Médico",
		["Poste_principal_z2"]  = "Subestación Médica",
		["Poste_secundario_z2"] = "Poste Secundario de Apoyo",
		["PosteCanchas_z2"]     = "Acceso de Ambulancias",
		["PosteHospital_z2"]    = "Poste Hospitalario Principal"
	},

	AnalisisConfig = {
		["Zona_Residencial_1"] = {
			algoritmos = { "prim" },
			nodoInicio = "Gen_Estacion_z1",
			nodoFin    = nil,
			conceptos  = {
				prim = {
					intro = "Prim parte de la Subestación Residencial y conecta las ocho ubicaciones sin ciclos. El MST óptimo de esta zona tiene peso total 20.",
					pasos = {
						[2]  = "La Subestación Residencial inicia con key=0; los demás nodos comienzan en infinito.",
						[8]  = "Integra al MST el nodo pendiente cuya arista de entrada tenga el menor peso.",
						[9]  = "Compara los cables vecinos y conserva para cada nodo la alternativa más barata.",
						[13] = "MST residencial completo: 7 aristas, 8 nodos y peso total 20.",
					},
				},
			},
		},
		["Zona_Hospital_2"] = {
			algoritmos = { "prim" },
			nodoInicio = "Poste_principal_z2",
			nodoFin    = nil,
			conceptos  = {
				prim = {
					intro = "Prim parte de la Subestación Médica para conectar los siete puntos del complejo. El MST óptimo de esta zona tiene peso total 22.",
					pasos = {
						[2]  = "La Subestación Médica inicia con key=0; sus conexiones reciben los primeros pesos.",
						[8]  = "Selecciona el área pendiente conectada por el cable candidato más barato.",
						[9]  = "Actualiza la key solamente cuando aparece una conexión de menor peso.",
						[13] = "MST hospitalario completo: 6 aristas, 7 nodos y peso total 22.",
					},
				},
			},
		},
	},

	Misiones = {
		-- Zona 1: Prim debe formar un árbol de 8 nodos, 7 aristas y peso <= 20.
		{ ID=301, Zona="Zona_Residencial_1", Texto="Selecciona la Subestación Residencial", Tipo="NODO_SELECCIONADO", Puntos=100, Parametros={ Nodo="Gen_Estacion_z1" } },
		{ ID=302, Zona="Zona_Residencial_1", Texto="Construye el árbol residencial: 8 nodos, 7 cables y peso total 20 o menor", Tipo="ARBOL_EXPANSION_MINIMA", Puntos=900, Parametros={ Nodos={"Gen_Estacion_z1","Casa_Estacion1_z1","Casa_Estacion2_z1","Parque2_z1","Parque_z1","Poste_Canchas_z1","Poste_Casa1_z1","Poste_Parque2_z1"}, PesoMaximo=20 } },


		-- Zona 2: reparar los nodos reales y construir su MST de peso <= 22.
		{ ID=310, Zona="Zona_Hospital_2", Texto="Selecciona la Subestación Médica", Tipo="NODO_SELECCIONADO", Puntos=100, Parametros={ Nodo="Poste_principal_z2" } },
		{ ID=311, Zona="Zona_Hospital_2", Texto="Repara el Poste de la Alcaldía", Tipo="NODO_REPARADO", Puntos=150, Parametros={ Nodo="Poste_Alcaldia_z2" } },
		{ ID=312, Zona="Zona_Hospital_2", Texto="Repara el Poste Secundario de Apoyo", Tipo="NODO_REPARADO", Puntos=150, Parametros={ Nodo="Poste_secundario_z2" } },
		{ ID=313, Zona="Zona_Hospital_2", Texto="Repara la Subestación Médica", Tipo="NODO_REPARADO", Puntos=150, Parametros={ Nodo="Poste_principal_z2" } },
		{ ID=314, Zona="Zona_Hospital_2", Texto="Construye el árbol hospitalario: 7 nodos, 6 cables y peso total 22 o menor", Tipo="ARBOL_EXPANSION_MINIMA", Puntos=900, Parametros={ Nodos={"Poste_Alcaldia_z2","Poste_luz_z2","Poste_parque_z2","Poste_principal_z2","Poste_secundario_z2","PosteCanchas_z2","PosteHospital_z2"}, PesoMaximo=22 } },
		{ ID=319, Zona="Zona_Hospital_2", Texto="Completa el árbol global de 15 nodos con peso total 46 o menor", Tipo="ARBOL_EXPANSION_MINIMA", Puntos=700, Parametros={ Nodos={"Gen_Estacion_z1","Casa_Estacion1_z1","Casa_Estacion2_z1","Parque2_z1","Parque_z1","Poste_Canchas_z1","Poste_Casa1_z1","Poste_Parque2_z1","Poste_Alcaldia_z2","Poste_luz_z2","Poste_parque_z2","Poste_principal_z2","Poste_secundario_z2","PosteCanchas_z2","PosteHospital_z2"}, PesoMaximo=46 } },
		{ ID=320, Zona="Zona_Hospital_2", Texto="EMERGENCIA: repara los tres nodos dañados y devuelve energía al complejo", Tipo="EMERGENCIA", Puntos=800, Parametros={ NodosEnergizar={"Poste_Alcaldia_z2","Poste_secundario_z2","Poste_principal_z2"}, TiempoLimite=180 } },
		{ ID=321, Zona="Zona_Alcaldia", Texto="Cuenta la verdad durante la rueda de prensa del Alcalde", Tipo="DIALOGO_COMPLETADO", Puntos=0, Parametros={
			DialogoID="Final_1",
			RequiereMisiones={
				301,302,310,311,312,313,314,319,320,
			},
			PenalizacionFallo=1000,
			MensajeExito="El Alcalde fue desenmascarado con las pruebas de Prim.",
			MensajeFallo="El Alcalde se salió con la suya y fuimos denunciados por calumnia.",
		} },
	},

	Guia = {
		{ ID="residencial_1", Zona="Zona_Residencial_1", Label="Ve al Sector Residencial", WaypointRef={ Tipo="PART_DIRECTA", BuscarEn="NIVEL_ACTUAL", Nombre="ZonaTrigger_Residencial" }, DestruirAlCompletar=false },
		{ ID="hospital_2",    Zona="Zona_Hospital_2",    Label="Ve al Complejo Hospitalario", WaypointRef={ Tipo="PART_DIRECTA", BuscarEn="NIVEL_ACTUAL", Nombre="ZonaTrigger_Hospital" }, DestruirAlCompletar=false },
		{ ID="alcaldia_3", Zona="Zona_Alcaldia", Label="Ve a la Alcaldía y presenta las pruebas", WaypointRef={ Tipo="PART_DIRECTA", BuscarEn="NIVEL_ACTUAL", Nombre="ZonaTrigger_Alcaldia" }, DestruirAlCompletar=false },
	},

	Bloqueos = {
		Colisionador_2 = { Zona = "Zona_Residencial_1" },
		Colisionador_Rueda={ Zona = "Zona_Hospital_2" }
	}
}



return LevelsConfig
