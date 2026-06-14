-- ReplicatedStorage/DialogoData/DialogosNivel2/Nivel2_Oficina.lua
-- Diálogo de la Zona 3 (Oficina de Análisis) — Nivel 2: La Ruta Más Corta
-- Concepto: cierre de Dijkstra, repaso de relajación y uso del algoritmo.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LevelsConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("LevelsConfig"))
local EfectosDialogo = require(ReplicatedStorage:WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
local ServicioCamara = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("ServicioCamara"))
local Utilidades = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("Utilidades"))

local function notificarRespuestaCorrecta()
	Utilidades.notificarDialogoCorrecto()
end

-- Alias de nodos amigables
local nombres = LevelsConfig[2].NombresNodos
local aliasOficina  = nombres["Oficina_z3"]  or "Oficina"
local aliasServidor = nombres["Servidor_z3"] or "Servidor"
local aliasAntena   = nombres["Antena_z3"]   or "Antena"

local COSTO_POR_METRO = LevelsConfig[2].CostoPorMetro or 500

local function costo(peso)
	return peso * COSTO_POR_METRO
end

local DIALOGOS = {
	["Nivel2_Oficina"] = {
		Zona  = "Zona_Oficina_3",
		Nivel = 2,
		Lineas = {
			{
				Id        = "intro_oficina",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Sonriente",
				Texto     = "Llegamos a la Oficina de Análisis. Aquí revisamos toda la red de la ciudad. En esta zona conectaremos la " .. aliasOficina .. " con el " .. aliasServidor .. " y la " .. aliasAntena .. ", siempre buscando el menor costo.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Oficina_z3", { altura = 25, angulo = 60, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Oficina_z3", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Servidor_z3", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Antena_z3", "ADYACENTE")
					EfectosDialogo.mostrarLabel("Oficina_z3", aliasOficina)
				end,
				Siguiente = "repaso_dijkstra",
			},
			{
				Id        = "repaso_dijkstra",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Presentacion",
				Texto     = "Dijkstra es un algoritmo codicioso: en cada paso elige el nodo no visitado con menor costo acumulado. Desde allí relaja las aristas de sus vecinos, actualizando distancias si encuentra un camino más barato.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Oficina_z3", { altura = 26, angulo = 58, duracion = 1.2 })
					EfectosDialogo.resaltarNodo("Oficina_z3", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Servidor_z3", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Antena_z3", "ADYACENTE")
					EfectosDialogo.mostrarArista("Oficina_z3", "Servidor_z3", "ADYACENTE", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Oficina_z3", "Antena_z3", "ADYACENTE", { sinParticulas = true })
				end,
				Siguiente = "ejemplo_oficina",
			},
			{
				Id        = "ejemplo_oficina",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "Por ejemplo, para llegar a la " .. aliasAntena .. " desde la " .. aliasOficina .. " solo existe una arista directa de 4 metros. Eso cuesta $" .. costo(4) .. ". Dijkstra la marca como la ruta mínima porque no hay otra forma más barata de llegar.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Antena_z3", { altura = 24, angulo = 60, duracion = 1.2 })
					EfectosDialogo.resaltarNodo("Oficina_z3", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Antena_z3", "EXITO")
					EfectosDialogo.mostrarArista("Oficina_z3", "Antena_z3", "SELECCIONADO", { sinParticulas = true })
					task.delay(0.3, function()
						EfectosDialogo.mostrarLabel("Oficina_z3", "0 m")
						EfectosDialogo.mostrarLabel("Antena_z3", "4 m → $" .. costo(4) .. " ✓")
					end)
				end,
				Siguiente = "pregunta_relajacion",
			},
			{
				Id        = "pregunta_relajacion",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Curioso",
				Texto     = "Pregunta: en Dijkstra, ¿qué significa relajar una arista?",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Servidor_z3", { altura = 26, angulo = 60, duracion = 1.0 })
					EfectosDialogo.resaltarNodo("Servidor_z3", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("Servidor_z3", "¿Relajación?")
				end,
				Opciones = {
					{ Texto = "Comprobar si llegar a un vecino por el nodo actual reduce su costo mínimo conocido.", Siguiente = "resp_relajacion_bien" },
					{ Texto = "Eliminar aristas que no forman parte del camino más corto.", Siguiente = "resp_relajacion_mal" },
					{ Texto = "Ordenar los nodos alfabéticamente antes de procesarlos.", Siguiente = "resp_relajacion_mal2" },
				},
			},
			{
				Id        = "resp_relajacion_bien",
				Numero    = 5,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "¡Exacto! Relajar significa: si distancia[nodo actual] + peso de la arista < distancia[vecino], entonces actualizamos la distancia del vecino. Esa es la operación que hace Dijkstra una y otra vez.",
				Evento = function()
					local jugador = game:GetService("Players").LocalPlayer
					if jugador then
						local puntajeActual = jugador:GetAttribute("PuntajeDialogo") or 0
						jugador:SetAttribute("PuntajeDialogo", puntajeActual + 100)
					end
					notificarRespuestaCorrecta()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Antena_z3", "EXITO")
					EfectosDialogo.blink("Antena_z3", "EXITO", 3)
				end,
				Opciones = { { Texto = "Continuar", Siguiente = "resumen" } },
			},
			{
				Id        = "resp_relajacion_mal",
				Numero    = 5,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No, Dijkstra no elimina aristas. Relajar compara costos y actualiza la mejor distancia conocida cuando encuentra un camino más barato. El grafo completo sigue ahí.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Oficina_z3", "ERROR")
					EfectosDialogo.mostrarLabel("Oficina_z3", "No elimina aristas")
				end,
				Opciones = { { Texto = "Entendido", Siguiente = "resumen" } },
			},
			{
				Id        = "resp_relajacion_mal2",
				Numero    = 5,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No, Dijkstra no ordena alfabéticamente. Usa una cola de prioridad ordenada por costo acumulado, siempre extrayendo el nodo más barato primero.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Servidor_z3", "ERROR")
					EfectosDialogo.mostrarLabel("Servidor_z3", "Orden por costo")
				end,
				Opciones = { { Texto = "Entendido", Siguiente = "resumen" } },
			},
			{
				Id        = "resumen",
				Numero    = 6,
				Actor     = "Carlos",
				Expresion = "Presentacion",
				Texto     = "Recuerda: Dijkstra = menor costo acumulado. Cada arista tiene un peso, cada peso se convierte en dinero, y cada paso relaja vecinos para encontrar el camino más barato. Es la base para rutas óptimas en mapas, redes y videojuegos.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Gen_Fabrica_z1", { altura = 40, angulo = 75, duracion = 2 })
					EfectosDialogo.resaltarNodo("Oficina_z3", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Servidor_z3", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Antena_z3", "ADYACENTE")
				end,
				Siguiente = "cierre_nivel",
			},
			{
				Id        = "cierre_nivel",
				Numero    = 7,
				Actor     = "Carlos",
				Expresion = "Extasiado",
				Texto     = "¡Excelente trabajo, Tocino! Dominaste Dijkstra: pesos, costos, relajación y la diferencia con BFS. La ciudad ahora tiene la red eléctrica más económica posible. ¡Nos vemos en el siguiente nivel!",
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
