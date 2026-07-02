-- ReplicatedStorage/DialogoData/DialogosNivel1/Nivel1_Parque.lua
-- Diálogo de la Zona 4 (Parque del Barrio) — Nivel 1: El Barrio Antiguo
-- Concepto BFS: Grafo Conexo Completo
-- Versión corta y directa: qué es una capa en BFS.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EfectosDialogo = require(ReplicatedStorage:WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
local ServicioCamara = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("ServicioCamara"))
local Utilidades = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("Utilidades"))

local function notificarRespuestaCorrecta()
	Utilidades.notificarDialogoCorrecto()
end

local DIALOGOS = {
	["Nivel1_Parque"] = {
		Zona  = "Zona_Parque_4",
		Nivel = 1,
		Lineas = {
			-- 1. Introducción rápida
			{
				Id        = "intro_parque",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "El Parque del Barrio. Seis nodos a oscuras. Aquí no hay tiempo para charlas largas: vamos directo al grano de BFS.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Fuente_z4", { altura = 42, angulo = 68, duracion = 1.8 })
					EfectosDialogo.resaltarNodo("Fuente_z4", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Poste1_z4", "ERROR")
					EfectosDialogo.resaltarNodo("Poste2_z4", "ERROR")
					EfectosDialogo.resaltarNodo("Poste3_z4", "ERROR")
					EfectosDialogo.resaltarNodo("Poste4_z4", "ERROR")
					EfectosDialogo.resaltarNodo("Kiosco_z4", "ERROR")
					EfectosDialogo.mostrarLabel("Poste1_z4", "Sin luz", "ERROR")
					EfectosDialogo.mostrarLabel("Fuente_z4", "Sin luz", "ERROR")
				end,
				Siguiente = "capas_bfs",
			},

			-- 2. Explicación directa de capas
			{
				Id        = "capas_bfs",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Presentacion",
				Texto     = "En BFS, una capa sucede cada vez que el algoritmo vacía todos los nodos que estaban esperando en la cola al mismo nivel de distancia.\n\n• Capa 0: el algoritmo pone el nodo inicial en la cola.\n• Capa 1: saca el inicial y encola sus vecinos directos.\n• Capa 2: saca los nodos de la capa 1 y encola sus vecinos no visitados.\n\nCada capa es un salto más lejos del inicio.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Poste1_z4", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("Poste1_z4", "Capa 0")
					task.delay(0.6, function()
						EfectosDialogo.resaltarNodo("Poste2_z4", "ADYACENTE")
						EfectosDialogo.resaltarNodo("Fuente_z4", "ADYACENTE")
						EfectosDialogo.mostrarLabel("Poste2_z4", "Capa 1")
						EfectosDialogo.mostrarLabel("Fuente_z4", "Capa 1")
					end)
					task.delay(1.2, function()
						EfectosDialogo.resaltarNodo("Poste3_z4", "ADYACENTE")
						EfectosDialogo.resaltarNodo("Kiosco_z4", "ADYACENTE")
						EfectosDialogo.mostrarLabel("Poste3_z4", "Capa 2")
						EfectosDialogo.mostrarLabel("Kiosco_z4", "Capa 2")
					end)
				end,
				Siguiente = "pregunta_capas",
			},

			-- 3. Pregunta directa
			{
				Id        = "pregunta_capas",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Sonriente",
				Texto     = "Poste 1 conecta con Poste 2 y la Fuente. Fuente conecta con Poste 3 y el Kiosco. Si BFS parte desde Poste 1… ¿cuántas capas necesita para visitar los 6 nodos?",
				Opciones = {
					{ Texto = "1 capa.",  Siguiente = "resp_incorrecta" },
					{ Texto = "2 capas.", Siguiente = "resp_correcta"   },
					{ Texto = "6 capas.", Siguiente = "resp_incorrecta" },
				},
			},

			-- 4a. Respuesta correcta
			{
				Id        = "resp_correcta",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "¡Exacto! Capa 1: Poste 2 y Fuente. Capa 2: Poste 3, Kiosco y Poste 4. Dos capas son suficientes porque el grafo del Parque está bien conectado. ¡Ahora tiende los cables y enciende todo el barrio!",
				Evento = function()
					local jugador = game:GetService("Players").LocalPlayer
					if jugador then
						local puntajeActual = jugador:GetAttribute("PuntajeDialogo") or 0
						jugador:SetAttribute("PuntajeDialogo", puntajeActual + 100)
					end
					notificarRespuestaCorrecta()
				end,
				Opciones = { { Texto = "¡Vamos!", Siguiente = "alcalde_parque" } },
			},

			-- 4b. Respuesta incorrecta
			{
				Id        = "resp_incorrecta",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No exactamente. BFS agrupa los nodos por distancia en saltos. Poste 2 y Fuente están a 1 salto del Poste 1; Poste 3, Kiosco y Poste 4 están a 2 saltos. Dos capas cubren los 6 nodos porque el grafo es compacto.",
				Opciones = { { Texto = "Entendido", Siguiente = "alcalde_parque" } },
			},

			-- 5. El Alcalde interviene una última vez
			{
				Id        = "alcalde_parque",
				Numero    = 5,
				Actor     = "Alcalde",
				Expresion = "Furioso",
				Texto     = "¡Bastante! Ustedes han paseado por todo el barrio cuestionando mi obra. Cuando terminen aquí, espero un informe técnico, no un sermón. Y recuerden: la ciudad me eligió a mí, no a su algoritmo.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Fuente_z4", { altura = 35, angulo = 65, duracion = 1.2 })
					EfectosDialogo.resaltarNodo("Fuente_z4", "ERROR")
				end,
				Siguiente = "instruccion",
			},

			-- 6. Instrucción final
			{
				Id        = "instruccion",
				Numero    = 6,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Ya lo escuchaste. Conecta el Poste 1 al Poste de las Canchas para unir el subgrafo aislado. Luego enlaza la Fuente y los demás postes para iluminar el Parque al 100%. Cuando todo el barrio brille, habrás formado un Grafo Conexo completo. ¡Victoria!",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.restaurar(1.5)
				end,
				Siguiente = "FIN",
			},
		},

		Metadata = { TiempoDeEspera = 0.5, VelocidadTypewriter = 0.03, PuedeOmitir = true, OcultarHUD = true, UsarTTS = true },
		Configuracion = { bloquearMovimiento = true, bloquearSalto = true, apuntarCamara = true, ocultarTechos = true },
	},
}
return DIALOGOS
