-- ReplicatedStorage/DialogoData/DialogosNivel3/Nivel3_Control.lua
-- Diálogo de la Zona 3 (Centro de Control) — Nivel 3: El Camino Más Eficiente
-- Concepto: Eficiencia de Dijkstra, aplicaciones reales y cierre del nivel.

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
	["Nivel3_Control"] = {
		Zona  = "Zona_Control_3",
		Nivel = 3,
		Lineas = {
			{
				Id        = "intro_control",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Sonriente",
				Texto     = "Llegamos al Centro de Control. Desde aquí se ven todas las rutas del pueblo en las pantallas. Y tengo buenas noticias: usando Dijkstra, las rutas de suministro de Villa Conexa ahora son un cuarenta por ciento más eficientes.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Centro_Control_z3", { altura = 25, angulo = 60, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Centro_Control_z3", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Antena_z3", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Terminal_z3", "ADYACENTE")
				end,
				Siguiente = "pregunta_gps",
			},
			{
				Id        = "pregunta_gps",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Curioso",
				Texto     = "Pregunta: ¿Dijkstra se usa en aplicaciones reales como Google Maps o los sistemas de navegación de aviones?",
				Opciones = {
					{ Texto = "Sí, absolutamente. Todos usan versiones optimizadas de Dijkstra.", Siguiente = "resp_gps_bien" },
					{ Texto = "No, los GPS usan trigonometría básica sin grafos.", Siguiente = "resp_gps_mal" },
					{ Texto = "Solo en redes sociales, no en navegación.", Siguiente = "resp_gps_mal" },
				},
			},
			{
				Id        = "resp_gps_bien",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "¡Correcto! Google Maps, Waze, los sistemas de enrutación de internet, los algoritmos de navegación de aviones... todos usan versiones optimizadas de Dijkstra. Es uno de los algoritmos más aplicados en toda la industria de la computación.",
				Evento = function()
					local jugador = game:GetService("Players").LocalPlayer
					if jugador then
						local puntajeActual = jugador:GetAttribute("PuntajeDialogo") or 0
						jugador:SetAttribute("PuntajeDialogo", puntajeActual + 100)
					end
					notificarRespuestaCorrecta()
				end,
				Opciones = { { Texto = "Continuar", Siguiente = "complejidad" } },
			},
			{
				Id        = "resp_gps_mal",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No exactamente. Dijkstra y sus variantes optimizadas son la base de casi todos los sistemas de navegación modernos. Cuando Google Maps te dice la ruta más rápida, en el fondo está resolviendo el Problema del Camino Mínimo en un grafo ponderado gigante.",
				Opciones = { { Texto = "Entendido", Siguiente = "complejidad" } },
			},
			{
				Id        = "complejidad",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "Hablemos de eficiencia. Con una Matriz de Adyacencia, Dijkstra es O de N al cuadrado porque cada vez que busca el nodo de menor distancia, recorre todos los nodos. Con una Lista de Adyacencia más un Min-Heap, baja a O de (N + A) por logaritmo de N. Para grafos grandes y dispersos, la segunda versión es mucho más rápida.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Centro_Control_z3", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Terminal_z3", "ADYACENTE")
					EfectosDialogo.mostrarArista("Centro_Control_z3", "Antena_z3", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Antena_z3", "Terminal_z3", "ADYACENTE", { sinParticulas = true })
				end,
				Siguiente = "limitaciones",
			},
			{
				Id        = "limitaciones",
				Numero    = 5,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "¿Hay algún caso donde Dijkstra no funcione? Sí: cuando existen aristas con pesos negativos. Para eso existe Bellman-Ford. Y si necesitas los caminos mínimos entre todos los pares de nodos, usarías Floyd-Warshall. Un algoritmo para cada variante del problema.",
				Siguiente = "dijkstra_vs_prim",
			},
			{
				Id        = "dijkstra_vs_prim",
				Numero    = 6,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "Antes de terminar, una comparación crucial. Dijkstra busca el camino de menor costo desde un nodo origen hasta todos los demás. Prim, en cambio, busca conectar TODOS los nodos con el menor costo total posible. Ese segundo problema se llama Árbol de Expansión Mínima, o MST.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Gen_Bodega_z1", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Terminal_z3", "SELECCIONADO")
					ServicioCamara.moverHaciaObjetivo("Plaza_z2", { altura = 40, angulo = 75, duracion = 2 })
				end,
				Siguiente = "cierre_presupuesto",
			},
			{
				Id        = "cierre_presupuesto",
				Numero    = 7,
				Actor     = "Carlos",
				Expresion = "Sonriente",
				Texto     = "En este nivel aprendiste algo valioso: no basta con conectar nodos. Hay que hacerlo de la forma más económica posible. El presupuesto del pueblo es limitado, y cada decisión cuenta. Dijkstra te da la herramienta matemática para tomar esas decisiones correctamente.",
				Siguiente = "cierre_nivel",
			},
			{
				Id        = "cierre_nivel",
				Numero    = 8,
				Actor     = "Carlos",
				Expresion = "Extasiado",
				Texto     = "¡Excelente trabajo, Tocino! Las rutas de suministro de Villa Conexa son ahora un cuarenta por ciento más eficientes. En el siguiente nivel aprenderemos algo diferente: no cómo ir de A a B de la forma más barata, sino cómo conectar todos los nodos del pueblo con el menor costo total posible. ¡Nos vemos pronto!",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.restaurar(1.2)
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
