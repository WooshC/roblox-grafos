-- ReplicatedStorage/DialogoData/DialogosNivel2/Nivel2_Comparativa.lua
-- Diálogo comparativo BFS vs DFS — Barrio Oeste simplificado

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EfectosDialogo = require(ReplicatedStorage:WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
local ServicioCamara = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("ServicioCamara"))

local Utilidades = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("Utilidades"))

local function notificarRespuestaCorrecta()
	Utilidades.notificarDialogoCorrecto()
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
				Texto     = "Desde aquí puedes ver todo el Barrio Oeste. Seis nodos conectados en dos ramas principales. Este es el escenario ideal para comparar BFS y DFS lado a lado.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Cruce_z1", { altura = 35, angulo = 75, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Cruce_z1", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Tunel_Norte_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Tunel_Sur_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Cisterna_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Almacen_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Puente_z2", "ADYACENTE")
				end,
				Siguiente = "bfs_demo",
			},
			{
				Id        = "bfs_demo",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "BFS usa una cola FIFO. Desde el Cruce, encola Norte y Sur. Luego procesa Norte y encola Cisterna y Almacén. Procesa Sur y encola Puente. Todos los nodos del Nivel 2 descubiertos a la vez. BFS ilumina por niveles, como una onda.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Cruce_z1", "SELECCIONADO")
					EfectosDialogo.mostrarArista("Cruce_z1", "Tunel_Norte_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Cruce_z1", "Tunel_Sur_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarLabel("Cruce_z1", "Nivel 0", "SELECCIONADO")
					ServicioCamara.moverHaciaObjetivo("Cisterna_z2", { altura = 30, angulo = 65, duracion = 1.5 })
				end,
				Siguiente = "dfs_demo",
			},
			{
				Id        = "dfs_demo",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "DFS usa una pila LIFO. Desde el Cruce, apila Norte y Sur. Como Sur se apiló después, DFS va primero al Sur, luego al Puente. Sin vecinos nuevos, retrocede. Luego explora Norte → Almacén, retrocede, y finalmente Norte → Cisterna → Puente. DFS completó una rama antes de tocar la otra.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Cruce_z1", "SELECCIONADO")
					EfectosDialogo.mostrarArista("Cruce_z1", "Tunel_Sur_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Tunel_Sur_z2", "Puente_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarLabel("Puente_z2", "Fondo de rama", "SELECCIONADO")
					ServicioCamara.moverHaciaObjetivo("Puente_z2", { altura = 30, angulo = 65, duracion = 1.5 })
				end,
				Siguiente = "pregunta_comparativa",
			},
			{
				Id        = "pregunta_comparativa",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Curioso",
				Texto     = "En esta red de 6 nodos, ¿cuál es la diferencia principal entre BFS y DFS desde el Cruce?",
				Opciones = {
					{ Texto = "BFS ilumina nivel por nivel en onda; DFS se adentra por una rama antes de explorar la otra.", Siguiente = "resp_comp_bien" },
					{ Texto = "Ambos algoritmos producen el mismo orden de visita porque el grafo es conexo.", Siguiente = "resp_comp_mal" },
					{ Texto = "DFS siempre encuentra el camino más corto porque usa una pila LIFO.", Siguiente = "resp_comp_mal2" },
				},
			},
			{
				Id        = "resp_comp_bien",
				Numero    = 5,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "¡Exacto! Esa es la diferencia fundamental. Abre el Panel de Análisis (Tab) y ejecútalos tú mismo para ver la animación paso a paso.",
				Evento = function()
					local jugador = game:GetService("Players").LocalPlayer
					if jugador then
						local puntajeActual = jugador:GetAttribute("PuntajeDialogo") or 0
						jugador:SetAttribute("PuntajeDialogo", puntajeActual + 100)
					end
					notificarRespuestaCorrecta()
				end,
				Opciones = { { Texto = "Probaré el analizador", Siguiente = "consejo_final" } },
			},
			{
				Id        = "resp_comp_mal",
				Numero    = 5,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No, el orden es completamente diferente. Cola FIFO versus pila LIFO produce órdenes de exploración distintos. Prueba el analizador para verlo.",
				Opciones = { { Texto = "Entendido", Siguiente = "consejo_final" } },
			},
			{
				Id        = "resp_comp_mal2",
				Numero    = 5,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No, DFS no garantiza el camino más corto. BFS es el que encuentra el mínimo de saltos en grafos no ponderados.",
				Opciones = { { Texto = "Entendido", Siguiente = "consejo_final" } },
			},
			{
				Id        = "consejo_final",
				Numero    = 6,
				Actor     = "Sistema",
				Texto     = "Selecciona BFS en el Panel de Análisis y observa la cola. Luego cambia a DFS y observa la pila y el backtracking.",
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
