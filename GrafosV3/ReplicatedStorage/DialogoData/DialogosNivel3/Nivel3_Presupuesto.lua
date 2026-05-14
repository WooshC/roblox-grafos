-- ReplicatedStorage/DialogoData/DialogosNivel3/Nivel3_Presupuesto.lua
-- Diálogo de la Zona 1 (Oficina de Presupuesto) — Nivel 3: El Camino Más Eficiente
-- Concepto: ¿Por qué BFS no alcanza? Introducción a Dijkstra y presupuesto.

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
	["Nivel3_Presupuesto"] = {
		Zona  = "Zona_Presupuesto_1",
		Nivel = 3,
		Lineas = {
			{
				Id        = "intro_presupuesto",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Preocupado",
				Texto     = "Tocino, tenemos un problema grave. El alcalde recibió la factura del mantenimiento de las rutas de suministro... y el costo subió un trescientos por ciento. Nos exige reducir gastos de inmediato.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Gen_Bodega_z1", { altura = 25, angulo = 65, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Gen_Bodega_z1", "SELECCIONADO")
				end,
				Siguiente = "problema_bfs",
			},
			{
				Id        = "problema_bfs",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Ya sabemos explorar el pueblo con BFS y DFS. Pero hay algo que ninguno de los dos considera: los pesos de las aristas. Si de la Bodega a la Plaza Central hay dos rutas, una de tres pasos y otra de dos, BFS te da la de dos pasos. ¿Pero qué pasa si la de tres pasos cuesta nueve y la de dos pasos cuesta veinticinco?",
				Evento = function()
					EfectosDialogo.mostrarLabel("Gen_Bodega_z1", "Generador Bodega", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Poste_Norte_z1", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Poste_Sur_z1", "ADYACENTE")
				end,
				Siguiente = "respuesta_tocino",
			},
			{
				Id        = "respuesta_tocino",
				Numero    = 3,
				Actor     = "Tocino",
				Expresion = "Normal",
				Texto     = "BFS elegiría la de dos pasos aunque sea mucho más cara...",
				Siguiente = "explica_dijkstra",
			},
			{
				Id        = "explica_dijkstra",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "Exacto. BFS minimiza pasos, no costos. Para grafos ponderados necesitamos un algoritmo que tome decisiones basadas en los pesos. Ahí entra Dijkstra.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Gen_Bodega_z1", "SELECCIONADO")
					EfectosDialogo.mostrarArista("Gen_Bodega_z1", "Poste_Norte_z1", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Gen_Bodega_z1", "Poste_Sur_z1", "ADYACENTE", { sinParticulas = true })
					EfectosDialogo.mostrarLabel("Poste_Norte_z1", "Costo: 4")
					EfectosDialogo.mostrarLabel("Poste_Sur_z1", "Costo: 7")
				end,
				Siguiente = "concepto_dijkstra",
			},
			{
				Id        = "concepto_dijkstra",
				Numero    = 5,
				Actor     = "Carlos",
				Expresion = "Presentacion",
				Texto     = "El Algoritmo de Dijkstra resuelve el Problema del Camino Mínimo: encuentra la ruta de menor costo acumulado desde un nodo origen hacia todos los demás nodos. Solo funciona con pesos no negativos.",
				Siguiente = "pregunta_pesos_negativos",
			},
			{
				Id        = "pregunta_pesos_negativos",
				Numero    = 6,
				Actor     = "Carlos",
				Expresion = "Curioso",
				Texto     = "Pregunta rápida: ¿por qué crees que Dijkstra solo funciona con pesos no negativos?",
				Opciones = {
					{ Texto = "Porque con pesos negativos, añadir más aristas podría bajar el costo total y romper la garantía del algoritmo.", Siguiente = "resp_pesos_bien" },
					{ Texto = "Porque Dijkstra no sabe restar números negativos.", Siguiente = "resp_pesos_mal" },
					{ Texto = "Porque los pesos negativos no existen en la vida real.", Siguiente = "resp_pesos_mal" },
				},
			},
			{
				Id        = "resp_pesos_bien",
				Numero    = 7,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "¡Correcto! Dijkstra se basa en una garantía crítica: una vez que encuentra el camino mínimo a un nodo, ese costo no puede mejorar. Si hubiera pesos negativos, añadir más aristas podría bajar el costo, rompiendo esa garantía. En la vida real, ningún camino tiene distancia negativa.",
				Evento = function()
					local jugador = game:GetService("Players").LocalPlayer
					if jugador then
						local puntajeActual = jugador:GetAttribute("PuntajeDialogo") or 0
						jugador:SetAttribute("PuntajeDialogo", puntajeActual + 100)
					end
					notificarRespuestaCorrecta()
				end,
				Opciones = { { Texto = "Continuar", Siguiente = "presupuesto_intro" } },
			},
			{
				Id        = "resp_pesos_mal",
				Numero    = 7,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No exactamente. La razón es que Dijkstra asume que una vez que fija la distancia mínima a un nodo, esa distancia no puede mejorar. Si existieran pesos negativos, podrías encontrar un camino más barato pasando por más aristas, lo que invalidaría todo el algoritmo.",
				Opciones = { { Texto = "Entendido", Siguiente = "presupuesto_intro" } },
			},
			{
				Id        = "presupuesto_intro",
				Numero    = 8,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Ahora, el detalle importante: el alcalde nos dio un presupuesto limitado para tender cables. Cada arista que conectes consume su peso en dinero. Si gastas de más, fallas la misión. Usa Dijkstra en el Panel de Análisis para planificar la ruta más barata antes de gastar.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Gen_Bodega_z1", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Poste_Norte_z1", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Poste_Sur_z1", "ADYACENTE")
					ServicioCamara.moverHaciaObjetivo("Gen_Bodega_z1", { altura = 35, angulo = 70, duracion = 1.5 })
				end,
				Siguiente = "instruccion_final",
			},
			{
				Id        = "instruccion_final",
				Numero    = 9,
				Actor     = "Sistema",
				Texto     = "Presupuesto inicial: 50 unidades. Cada cable cuesta su peso. Planifica con Dijkstra antes de conectar. Abre el Panel de Análisis (Tecla Tab) para simular el algoritmo paso a paso.",
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
