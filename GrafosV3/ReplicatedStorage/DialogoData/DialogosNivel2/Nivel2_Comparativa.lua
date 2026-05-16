-- ReplicatedStorage/DialogoData/DialogosNivel2/Nivel2_Comparativa.lua
-- Diálogo comparativo BFS vs DFS — Zona 2 expandida (Barrio Oeste)
-- Se recomienda asignar este diálogo a un trigger adicional cerca del Panel de Análisis.

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
	["Nivel2_Comparativa"] = {
		Zona  = "Zona_BarrioOeste_2",
		Nivel = 2,
		Lineas = {
			{
				Id        = "intro_comparativa",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Presentacion",
				Texto     = "Este es el punto de observación del Barrio Oeste. Desde aquí puedes ver toda la red expandida de la fábrica. Mira: once nodos conectados en múltiples direcciones. Este es el escenario perfecto para comparar BFS y DFS lado a lado.",
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
				Siguiente = "bfs_recorrido",
			},
			{
				Id        = "bfs_recorrido",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "Observa el recorrido de BFS desde el Cruce Principal. BFS usa una cola FIFO: primero procesa el Cruce, luego encola los Túneles Norte y Sur. Después procesa el Túnel Norte y encola Cisterna, Almacén y Patio. Luego el Túnel Sur y encola Puente y Vestíbulo. ¡BFS ilumina por niveles!",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Cruce_z1", "SELECCIONADO")
					EfectosDialogo.mostrarArista("Cruce_z1", "Tunel_Norte_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Cruce_z1", "Tunel_Sur_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarLabel("Cruce_z1", "Nivel 0", "SELECCIONADO")
					ServicioCamara.moverHaciaObjetivo("Tunel_Norte_z2", { altura = 35, angulo = 70, duracion = 1.5 })
				end,
				Siguiente = "bfs_nivel2",
			},
			{
				Id        = "bfs_nivel2",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Sonriente",
				Texto     = "Nivel 2 de BFS: Cisterna, Almacén, Patio, Puente, Vestíbulo. Todos fueron descubiertos a la misma profundidad. BFS no prefiere ninguna rama: expande uniformemente como una onda. Si buscas el camino más corto en saltos, BFS es tu elección.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Tunel_Norte_z2", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Tunel_Sur_z2", "SELECCIONADO")
					EfectosDialogo.mostrarArista("Tunel_Norte_z2", "Cisterna_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Tunel_Norte_z2", "Almacen_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Tunel_Norte_z2", "Patio_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Tunel_Sur_z2", "Puente_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Tunel_Sur_z2", "Vestibulo_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarLabel("Tunel_Norte_z2", "Nivel 1", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("Tunel_Sur_z2", "Nivel 1", "SELECCIONADO")
				end,
				Siguiente = "dfs_recorrido",
			},
			{
				Id        = "dfs_recorrido",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Ahora DFS. Misma red, misma reglas, pero DFS usa una pila LIFO. Desde el Cruce, apila los Túneles Norte y Sur. Como el Sur se apiló después, DFS lo procesa primero. Luego desde el Sur apila Puente y Vestíbulo. El Vestíbulo se apiló después, así que DFS va directo al Vestíbulo... luego al Sótano.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Cruce_z1", "SELECCIONADO")
					EfectosDialogo.mostrarArista("Cruce_z1", "Tunel_Sur_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Tunel_Sur_z2", "Vestibulo_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Vestibulo_z2", "Sotano_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarLabel("Sotano_z2", "¡Fondo de la rama!", "SELECCIONADO")
					ServicioCamara.moverHaciaObjetivo("Sotano_z2", { altura = 30, angulo = 65, duracion = 1.5 })
				end,
				Siguiente = "dfs_backtracking_demo",
			},
			{
				Id        = "dfs_backtracking_demo",
				Numero    = 5,
				Actor     = "Carlos",
				Expresion = "Extasiado",
				Texto     = "DFS llegó al fondo de la rama Sur. El Sótano no tiene vecinos sin visitar. ¿Qué hace? Backtracking: desapila y retrocede al Vestíbulo. Desde ahí prueba el Puente. Si el Puente tampoco lleva a nada nuevo, retrocede al Túnel Sur, luego al Cruce, y finalmente explora la rama Norte: Túnel Norte → Patio → Taller → Depósito. ¡DFS completó una rama entera antes de tocar la otra!",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Cruce_z1", "SELECCIONADO")
					EfectosDialogo.mostrarArista("Cruce_z1", "Tunel_Norte_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Tunel_Norte_z2", "Patio_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Patio_z2", "Taller_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Taller_z2", "Deposito_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarLabel("Deposito_z2", "Rama Norte completa", "SELECCIONADO")
					ServicioCamara.moverHaciaObjetivo("Deposito_z2", { altura = 30, angulo = 65, duracion = 1.5 })
				end,
				Siguiente = "pregunta_comparativa",
			},
			{
				Id        = "pregunta_comparativa",
				Numero    = 6,
				Actor     = "Carlos",
				Expresion = "Curioso",
				Texto     = "Pregunta de análisis: en esta red de 11 nodos del Barrio Oeste, ¿cuál sería la principal diferencia visible si ejecutas BFS versus DFS desde el Cruce Principal?",
				Opciones = {
					{ Texto = "BFS iluminaría todos los nodos nivel por nivel en forma de onda, mientras DFS se adentraría completamente por una rama antes de explorar la otra.", Siguiente = "resp_comp_bien" },
					{ Texto = "Ambos algoritmos producirían exactamente el mismo orden de visita porque el grafo es pequeño.", Siguiente = "resp_comp_mal" },
					{ Texto = "DFS siempre encontraría el camino más corto al Depósito porque usa una pila.", Siguiente = "resp_comp_mal2" },
				},
			},
			{
				Id        = "resp_comp_bien",
				Numero    = 7,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "¡Exacto! Esa es la diferencia fundamental. BFS expande en ondas: Cruce → Túneles → Cisterna/Almacén/Patio/Puente/Vestíbulo → Taller/Sótano → Depósito. DFS se va por la rama Sur hasta el Sótano, retrocede, y luego va por la Norte hasta el Depósito. Abre el Panel de Análisis (Tab) y ejecútalos tú mismo para ver la animación paso a paso.",
				Evento = function()
					local jugador = game:GetService("Players").LocalPlayer
					if jugador then
						local puntajeActual = jugador:GetAttribute("PuntajeDialogo") or 0
						jugador:SetAttribute("PuntajeDialogo", puntajeActual + 100)
					end
					notificarRespuestaCorrecta()
				end,
				Opciones = { { Texto = "Abriré el analizador", Siguiente = "consejo_final" } },
			},
			{
				Id        = "resp_comp_mal",
				Numero    = 7,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No, el orden de visita es completamente diferente. BFS y DFS usan estructuras de datos distintas: cola FIFO versus pila LIFO. Eso produce órdenes de exploración radicalmente distintos, especialmente visible en grafos ramificados como este de 11 nodos. Prueba el analizador para verlo tú mismo.",
				Opciones = { { Texto = "Entendido", Siguiente = "consejo_final" } },
			},
			{
				Id        = "resp_comp_mal2",
				Numero    = 7,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No, DFS no garantiza el camino más corto. DFS encuentra un camino, pero no necesariamente el de menos saltos. En este grafo, BFS encontraría el Depósito en 4 saltos (Cruce→Túnel Norte→Patio→Taller→Depósito). DFS podría tardar mucho más si se va primero por la rama Sur. BFS es el rey de los caminos más cortos en grafos no ponderados.",
				Opciones = { { Texto = "Entendido", Siguiente = "consejo_final" } },
			},
			{
				Id        = "consejo_final",
				Numero    = 8,
				Actor     = "Sistema",
				Texto     = "Consejo práctico: selecciona BFS en el Panel de Análisis y presiona Ejecutar. Observa la cola y el orden de niveles. Luego cambia a DFS, reinicia y observa la pila y el backtracking. La misma red, dos historias completamente diferentes.",
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
