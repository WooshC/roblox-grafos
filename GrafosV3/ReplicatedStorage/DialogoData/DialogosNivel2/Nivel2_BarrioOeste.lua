-- ReplicatedStorage/DialogoData/DialogosNivel2/Nivel2_BarrioOeste.lua
-- Diálogo de la Zona 2 (Barrio Oeste) — Nivel 2: La Fábrica de Señales
-- Concepto: DFS paso a paso y Backtracking.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EfectosDialogo = require(ReplicatedStorage:WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
local ServicioCamara = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("ServicioCamara"))

-- Evento para notificar respuestas correctas al servidor
local function notificarRespuestaCorrecta()
	local eventos = ReplicatedStorage:FindFirstChild("EventosGrafosV3")
	if eventos then
		local remotos = eventos:FindFirstChild("Remotos")
		if remotos then
			local evento = remotos:FindFirstChild("DialogoCorrecto")
			if evento then
				evento:FireServer()
			end
		end
	end
end

local DIALOGOS = {
	["Nivel2_BarrioOeste"] = {
		Zona  = "Zona_BarrioOeste_2",
		Nivel = 2,
		Lineas = {
			{
				Id        = "intro_barrio",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "Llegamos al Barrio Oeste de la fábrica. Mira estos túneles: desde el Cruce Principal, la red se divide en dos ramas principales. DFS va a elegir una y seguirla hasta el fondo.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Cruce_z1", { altura = 28, angulo = 60, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Cruce_z1", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Tunel_Norte_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Tunel_Sur_z2", "ADYACENTE")
				end,
				Siguiente = "dfs_paso_a_paso",
			},
			{
				Id        = "dfs_paso_a_paso",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Presentacion",
				Texto     = "DFS paso a paso desde el Generador. Paso 1: apilamos el Generador. Pila: [Generador]. Cerrado: vacío. Paso 2: sacamos el Generador, lo marcamos visitado y apilamos sus vecinos: Entrada y Cruce. Como Cruce se apila después, está en el tope.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Gen_Fabrica_z1", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("Gen_Fabrica_z1", "Pila: [Gen]")
					EfectosDialogo.mostrarArista("Gen_Fabrica_z1", "Entrada_z1", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Gen_Fabrica_z1", "Cruce_z1", "ADYACENTE", { sinParticulas = true })
				end,
				Siguiente = "dfs_continua",
			},
			{
				Id        = "dfs_continua",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Paso 3: sacamos el tope de la pila, que es el Cruce. Lo visitamos y apilamos sus vecinos: Túnel Norte y Túnel Sur. Paso 4: sacamos el Túnel Sur. Tiene un vecino: el Puente. Pila: [Entrada, Túnel Norte, Puente].",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Cruce_z1", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("Cruce_z1", "Pila: [Ent, T.Norte, T.Sur]")
					EfectosDialogo.mostrarArista("Cruce_z1", "Tunel_Sur_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Tunel_Sur_z2", "Puente_z2", "ADYACENTE", { sinParticulas = true })
				end,
				Siguiente = "backtracking",
			},
			{
				Id        = "backtracking",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Extasiado",
				Texto     = "¡Aquí viene lo bueno! DFS saca el Puente. Desde el Puente puede ir a la Cisterna o a la Oficina. Supón que va a la Cisterna. Pero la Cisterna ya fue visitada... DFS no puede avanzar más por esta rama. ¿Qué hace?",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Puente_z2", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Cisterna_z2", "ADYACENTE")
					EfectosDialogo.mostrarLabel("Puente_z2", "¿Cisterna ya visitada?")
				end,
				Siguiente = "pregunta_backtracking",
			},
			{
				Id        = "pregunta_backtracking",
				Numero    = 5,
				Actor     = "Carlos",
				Expresion = "Curioso",
				Texto     = "Pregunta: cuando DFS llega a un nodo sin vecinos sin visitar, ¿qué hace el algoritmo?",
				Opciones = {
					{ Texto = "Retrocede al nodo anterior y prueba otra rama disponible.", Siguiente = "resp_back_bien" },
					{ Texto = "Se detiene y termina la exploración completamente.", Siguiente = "resp_back_mal" },
					{ Texto = "Salta a un nodo aleatorio del grafo que aún no haya visitado.", Siguiente = "resp_back_mal2" },
				},
			},
			{
				Id        = "resp_back_bien",
				Numero    = 6,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "¡Correcto! Eso se llama backtracking. DFS retrocede por la pila hasta encontrar un nodo que tenga vecinos sin visitar. Luego prueba esa nueva rama. Es la esencia de DFS: avanzar hasta no poder más, y entonces retroceder para explorar alternativas.",
				Evento = function()
					local jugador = game:GetService("Players").LocalPlayer
					if jugador then
						local puntajeActual = jugador:GetAttribute("PuntajeDialogo") or 0
						jugador:SetAttribute("PuntajeDialogo", puntajeActual + 100)
					end
					notificarRespuestaCorrecta()
				end,
				Opciones = { { Texto = "Continuar", Siguiente = "comparacion_orden" } },
			},
			{
				Id        = "resp_back_mal",
				Numero    = 6,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No, DFS no termina ahí. Esa es la magia del backtracking: cuando un nodo no tiene más vecinos sin visitar, DFS desapila y retrocede al nodo anterior. Sigue retrocediendo hasta encontrar una rama que aún no haya explorado.",
				Opciones = { { Texto = "Entendido", Siguiente = "comparacion_orden" } },
			},
			{
				Id        = "resp_back_mal2",
				Numero    = 6,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No, DFS nunca salta aleatoriamente. El orden de exploración está completamente determinado por la pila LIFO. Retrocede sistemáticamente por el camino que vino, probando cada rama que quedó pendiente.",
				Opciones = { { Texto = "Entendido", Siguiente = "comparacion_orden" } },
			},
			{
				Id        = "comparacion_orden",
				Numero    = 7,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "¿Notas la diferencia con BFS? En BFS el orden de visita desde el Generador sería: Generador, Entrada, Cruce, Sala Máquinas, Túnel Norte, Túnel Sur, Cisterna, Almacén, Puente... En DFS el orden es: Generador, Cruce, Túnel Sur, Puente, Cisterna, Túnel Norte, Almacén, Oficina... ¡DFS se fue directo hasta el fondo de la rama Sur antes de regresar!",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Gen_Fabrica_z1", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Cruce_z1", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Tunel_Sur_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Puente_z2", "ADYACENTE")
					ServicioCamara.moverHaciaObjetivo("Puente_z2", { altura = 30, angulo = 65, duracion = 1.5 })
				end,
				Siguiente = "instruccion_final",
			},
			{
				Id        = "instruccion_final",
				Numero    = 8,
				Actor     = "Sistema",
				Texto     = "Conecta los túneles del Barrio Oeste respetando el orden de ramificación del grafo. Abre el Panel de Análisis con DFS para visualizar el backtracking en acción. Avanza hacia la Oficina de Análisis cuando estés listo.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.restaurar(1.2)
				end,
				Siguiente = "comparativa_intro",
			},
			-- ═══════════════════════════════════════════════════════════════════
			-- SECCIÓN COMPARATIVA BFS vs DFS (grafo expandido de 11 nodos)
			-- ═══════════════════════════════════════════════════════════════════
			{
				Id        = "comparativa_intro",
				Numero    = 9,
				Actor     = "Carlos",
				Expresion = "Presentacion",
				Texto     = "Un momento, Tocino. Antes de que sigas, mira esta red completa del Barrio Oeste. Once nodos interconectados. Este es el escenario perfecto para que compares BFS y DFS lado a lado usando el Panel de Análisis.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Cruce_z1", { altura = 45, angulo = 80, duracion = 2 })
					EfectosDialogo.resaltarNodo("Cruce_z1", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Tunel_Norte_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Tunel_Sur_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Cisterna_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Almacen_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Puente_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Patio_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Taller_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Vestibulo_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Sotano_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Deposito_z2", "ADYACENTE")
				end,
				Siguiente = "bfs_demo_expandido",
			},
			{
				Id        = "bfs_demo_expandido",
				Numero    = 10,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "BFS desde el Cruce Principal iluminaría nivel por nivel: primero los Túneles Norte y Sur, luego Cisterna, Almacén, Patio, Puente y Vestíbulo, y finalmente Taller, Sótano y Depósito. BFS expande como una onda: uniforme, sin preferir ninguna rama.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Cruce_z1", "SELECCIONADO")
					EfectosDialogo.mostrarArista("Cruce_z1", "Tunel_Norte_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Cruce_z1", "Tunel_Sur_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarLabel("Cruce_z1", "Nivel 0: Cruce", "SELECCIONADO")
					ServicioCamara.moverHaciaObjetivo("Tunel_Norte_z2", { altura = 35, angulo = 70, duracion = 1.5 })
				end,
				Siguiente = "dfs_demo_expandido",
			},
			{
				Id        = "dfs_demo_expandido",
				Numero    = 11,
				Actor     = "Carlos",
				Expresion = "Extasiado",
				Texto     = "DFS, en cambio, se adentra por una sola rama hasta el fondo. Desde el Cruce, apila Túneles Norte y Sur. Como el Sur se apiló después, DFS va primero al Sur, luego al Vestíbulo, luego al Sótano. Sin vecinos nuevos, retrocede. Luego prueba el Puente, retrocede, y finalmente explora la rama Norte: Túnel Norte → Patio → Taller → Depósito. ¡Una rama completa antes de tocar la otra!",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Cruce_z1", "SELECCIONADO")
					EfectosDialogo.mostrarArista("Cruce_z1", "Tunel_Sur_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Tunel_Sur_z2", "Vestibulo_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Vestibulo_z2", "Sotano_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarLabel("Sotano_z2", "¡Fondo de rama Sur!", "SELECCIONADO")
					ServicioCamara.moverHaciaObjetivo("Sotano_z2", { altura = 30, angulo = 65, duracion = 1.5 })
				end,
				Siguiente = "pregunta_comparativa",
			},
			{
				Id        = "pregunta_comparativa",
				Numero    = 12,
				Actor     = "Carlos",
				Expresion = "Curioso",
				Texto     = "Pregunta de análisis: en esta red expandida de 11 nodos, ¿cuál es la principal diferencia visible entre ejecutar BFS versus DFS desde el Cruce Principal?",
				Opciones = {
					{ Texto = "BFS ilumina nivel por nivel en forma de onda, mientras DFS se adentra completamente por una rama antes de explorar la otra.", Siguiente = "resp_comp_bien" },
					{ Texto = "Ambos algoritmos producirían el mismo orden de visita porque el grafo es conexo.", Siguiente = "resp_comp_mal" },
					{ Texto = "DFS siempre encontraría el camino más corto al Depósito porque usa una pila LIFO.", Siguiente = "resp_comp_mal2" },
				},
			},
			{
				Id        = "resp_comp_bien",
				Numero    = 13,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "¡Exacto! Esa es la diferencia fundamental. BFS: Cruce → Túneles → Cisterna/Almacén/Patio/Puente/Vestíbulo → Taller/Sótano → Depósito. DFS: rama Sur completa (Sótano) → backtracking → rama Norte completa (Depósito). Abre el Panel de Análisis (Tab) y ejecútalos tú mismo para ver la animación paso a paso.",
				Evento = function()
					local jugador = game:GetService("Players").LocalPlayer
					if jugador then
						local puntajeActual = jugador:GetAttribute("PuntajeDialogo") or 0
						jugador:SetAttribute("PuntajeDialogo", puntajeActual + 100)
					end
					notificarRespuestaCorrecta()
				end,
				Opciones = { { Texto = "Probaré el analizador", Siguiente = "cierre_comparativa" } },
			},
			{
				Id        = "resp_comp_mal",
				Numero    = 13,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No, el orden es completamente diferente. La estructura de datos define todo: cola FIFO produce expansión por niveles; pila LIFO produce exploración en profundidad. En un grafo ramificado de 11 nodos, la diferencia es dramática y visible.",
				Opciones = { { Texto = "Entendido", Siguiente = "cierre_comparativa" } },
			},
			{
				Id        = "resp_comp_mal2",
				Numero    = 13,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No, DFS no garantiza el camino más corto. En este grafo, BFS encuentra el Depósito en 4 saltos (Cruce→Túnel Norte→Patio→Taller→Depósito). DFS podría explorar toda la rama Sur primero, tardando mucho más en llegar al Depósito.",
				Opciones = { { Texto = "Entendido", Siguiente = "cierre_comparativa" } },
			},
			{
				Id        = "cierre_comparativa",
				Numero    = 14,
				Actor     = "Sistema",
				Texto     = "Consejo: abre el Panel de Análisis (Tab), selecciona BFS, ejecuta y observa la cola. Luego cambia a DFS, reinicia y observa la pila y el backtracking. La misma red de 11 nodos, dos historias completamente diferentes.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.restaurar(1.5)
				end,
				Siguiente = "FIN",
			},
		},
		Metadata = { TiempoDeEspera = 0.5, VelocidadTypewriter = 0.03, PuedeOmitir = true, OcultarHUD = true, UsarTTS = true },
		Configuracion = { bloquearMovimiento = true, bloquearSalto = true, apuntarCamara = true, ocultarTechos = true },
		EventoSaltar = function()
			EfectosDialogo.limpiarTodo()
			ServicioCamara.restaurar(0)
		end,
	},
}
return DIALOGOS
