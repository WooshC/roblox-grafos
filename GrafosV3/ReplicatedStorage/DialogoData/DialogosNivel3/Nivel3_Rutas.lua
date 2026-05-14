-- ReplicatedStorage/DialogoData/DialogosNivel3/Nivel3_Rutas.lua
-- Diálogo de la Zona 2 (Rutas de Suministro) — Nivel 3: El Camino Más Eficiente
-- Concepto: Dijkstra paso a paso, relajación de aristas y decisión de rutas óptimas.

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
	["Nivel3_Rutas"] = {
		Zona  = "Zona_Rutas_2",
		Nivel = 3,
		Lineas = {
			{
				Id        = "intro_rutas",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "Bienvenido a las Rutas de Suministro. Aquí es donde la teoría se convierte en práctica. Mira este mapa: cada cable tiene un número que representa su costo de instalación.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Cruce_Norte_z2", { altura = 28, angulo = 60, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Cruce_Norte_z2", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Mercado_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Taller_z2", "ADYACENTE")
				end,
				Siguiente = "inicializacion",
			},
			{
				Id        = "inicializacion",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Presentacion",
				Texto     = "Paso uno de Dijkstra: inicializamos las distancias. La distancia al nodo origen, la Bodega, es cero. La distancia a todos los demás nodos es infinito, porque aún no sabemos cuánto cuestan.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Gen_Bodega_z1", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("Gen_Bodega_z1", "dist = 0")
					EfectosDialogo.mostrarLabel("Poste_Norte_z1", "dist = ∞")
					EfectosDialogo.mostrarLabel("Poste_Sur_z1", "dist = ∞")
					EfectosDialogo.mostrarLabel("Cruce_Norte_z2", "dist = ∞")
				end,
				Siguiente = "relajacion",
			},
			{
				Id        = "relajacion",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "Paso dos: elegimos el nodo no visitado con la distancia mínima. Al inicio, ese es la Bodega con distancia cero. Paso tres: para cada vecino, calculamos la distancia nueva. Si es menor que la registrada, la actualizamos. Eso se llama relajación de aristas.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Gen_Bodega_z1", "SELECCIONADO")
					EfectosDialogo.mostrarArista("Gen_Bodega_z1", "Poste_Norte_z1", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Gen_Bodega_z1", "Poste_Sur_z1", "ADYACENTE", { sinParticulas = true })
					EfectosDialogo.mostrarLabel("Poste_Norte_z1", "dist = 0+4 = 4")
					EfectosDialogo.mostrarLabel("Poste_Sur_z1", "dist = 0+7 = 7")
				end,
				Siguiente = "ejemplo_ruta",
			},
			{
				Id        = "ejemplo_ruta",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Sigamos. El no visitado con menor distancia es el Poste Norte con cuatro. Desde él llegamos al Cruce Norte con costo tres: distancia acumulada siete. Luego al Mercado con costo tres más: diez. Pero ojo: desde el Mercado a la Plaza cuesta solo dos...",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Poste_Norte_z1", "SELECCIONADO")
					EfectosDialogo.mostrarArista("Poste_Norte_z1", "Cruce_Norte_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Cruce_Norte_z2", "Mercado_z2", "ADYACENTE", { sinParticulas = true })
					EfectosDialogo.mostrarLabel("Cruce_Norte_z2", "dist = 4+3 = 7")
					EfectosDialogo.mostrarLabel("Mercado_z2", "dist = 7+3 = 10")
				end,
				Siguiente = "relajacion_accion",
			},
			{
				Id        = "relajacion_accion",
				Numero    = 5,
				Actor     = "Carlos",
				Expresion = "Extasiado",
				Texto     = "¡Aquí viene lo bueno! También podemos llegar a la Plaza desde el Taller con costo uno, y al Taller desde el Cruce Sur con costo cuatro. Si comparamos rutas: Bodega → Norte → Cruce Norte → Mercado → Plaza = doce. Pero Bodega → Norte → Cruce Norte → Taller → Plaza = doce también... espera, hay una mejor.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Plaza_z2", "SELECCIONADO")
					EfectosDialogo.mostrarArista("Mercado_z2", "Plaza_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Taller_z2", "Plaza_z2", "ADYACENTE", { sinParticulas = true })
					EfectosDialogo.mostrarLabel("Plaza_z2", "Comparando rutas...")
				end,
				Siguiente = "pregunta_ruta",
			},
			{
				Id        = "pregunta_ruta",
				Numero    = 6,
				Actor     = "Carlos",
				Expresion = "Curioso",
				Texto     = "Pregunta: si quieres llegar a la Plaza Central gastando lo menos posible, y ya tienes conectados el Poste Norte y el Cruce Norte... ¿qué arista deberías tender primero?",
				Opciones = {
					{ Texto = "Cruce Norte → Taller (costo 8)", Siguiente = "resp_ruta_mal" },
					{ Texto = "Cruce Norte → Mercado (costo 3), luego Mercado → Plaza (costo 2)", Siguiente = "resp_ruta_bien" },
					{ Texto = "Cruce Norte → Taller (costo 8), luego Taller → Plaza (costo 1)", Siguiente = "resp_ruta_mal2" },
				},
			},
			{
				Id        = "resp_ruta_bien",
				Numero    = 7,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "¡Exacto! Cruce Norte → Mercado cuesta tres, y Mercado → Plaza cuesta dos. Total acumulado desde la Bodega: cuatro + tres + dos = nueve. Esa es la ruta más barata en este momento. Dijkstra la descubrirá automáticamente al procesar cada nodo por orden de distancia mínima.",
				Evento = function()
					local jugador = game:GetService("Players").LocalPlayer
					if jugador then
						local puntajeActual = jugador:GetAttribute("PuntajeDialogo") or 0
						jugador:SetAttribute("PuntajeDialogo", puntajeActual + 100)
					end
					notificarRespuestaCorrecta()
				end,
				Opciones = { { Texto = "Continuar", Siguiente = "consejo_presupuesto" } },
			},
			{
				Id        = "resp_ruta_mal",
				Numero    = 7,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No exactamente. Cruzar directamente al Taller desde el Cruce Norte cuesta ocho, lo cual es muy caro. Dijkstra nunca elegiría esa arista primero porque hay caminos mucho más baratos disponibles. Recuerda: el algoritmo siempre expande el nodo con la distancia acumulada más pequeña.",
				Opciones = { { Texto = "Entendido", Siguiente = "consejo_presupuesto" } },
			},
			{
				Id        = "resp_ruta_mal2",
				Numero    = 7,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Casi, pero no. El Taller → Plaza cuesta uno, sí, pero llegar al Taller desde el Cruce Norte cuesta ocho. Eso da un total de trece solo para esas dos aristas. En cambio, ir por el Mercado cuesta tres + dos = cinco. Dijkstra siempre suma el costo ACUMULADO desde el origen, no solo la arista individual.",
				Opciones = { { Texto = "Entendido", Siguiente = "consejo_presupuesto" } },
			},
			{
				Id        = "consejo_presupuesto",
				Numero    = 8,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Recuerda tu presupuesto. Cada cable que tiendes consume dinero real. Si gastas en aristas caras de más, podrías quedarte sin fondos antes de iluminar todo el pueblo. Planifica con Dijkstra, ejecuta con cabeza.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Plaza_z2", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Mercado_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Taller_z2", "ADYACENTE")
					ServicioCamara.moverHaciaObjetivo("Plaza_z2", { altura = 30, angulo = 65, duracion = 1.5 })
				end,
				Siguiente = "instruccion_final",
			},
			{
				Id        = "instruccion_final",
				Numero    = 9,
				Actor     = "Sistema",
				Texto     = "Conecta las rutas de suministro respetando el presupuesto. Usa el Panel de Análisis con Dijkstra para planificar la ruta más económica antes de gastar. Recuerda: el costo acumulado importa más que el costo individual de cada cable.",
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
