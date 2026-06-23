-- ReplicatedStorage/DialogoData/DialogosNivel1/Nivel1_Canchas.lua
-- Diálogo de la Zona 3 (Las Canchas) — Nivel 1: El Barrio Antiguo
-- Concepto DFS: Pila LIFO, Retroceso y Componentes Aislados

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EfectosDialogo = require(ReplicatedStorage:WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
local ServicioCamara = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("ServicioCamara"))

-- Evento para notificar respuestas correctas al servidor
local Utilidades = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("Utilidades"))

local function notificarRespuestaCorrecta()
	Utilidades.notificarDialogoCorrecto()
end

local DIALOGOS = {
	["Nivel1_Canchas"] = {
		Zona  = "Zona_Canchas_3",
		Nivel = 1,
		Lineas = {
			-- ── 1. INTRODUCCIÓN ─────────────────────────────────────────
			{
				Id        = "intro_canchas",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Preocupado",
				Texto     = "“Las Canchas… El alcalde juró que incluso los vecindarios más alejados tendrían electricidad. Pero la red no soportó la demanda: varios nodos se sobrecargaron, el voltaje se disparó y las estaciones terminaron explotando una tras otra",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Poste_Canchas_z3", { altura = 32, angulo = 58, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Casa_Canchas_z3", "ERROR")
					EfectosDialogo.resaltarNodo("Poste2_Canchas_z3", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Poste_Canchas_z3", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("Casa_Canchas_z3", "Sin luz", "ERROR")
				end,
				Siguiente = "por_que_dfs",
			},

			-- ── 2. ¿POR QUÉ DFS EN LAS CANCHAS? ─────────────────────────
			{
				Id        = "por_que_dfs",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "DFS es ideal para este problema porque se adentra a fondo en cada rama antes de retroceder. Es como explorar un callejón hasta el final antes de darte cuenta de que no hay salida. Así descubrimos rápidamente si un camino llega a un callejón sin salida... o a una casa sin luz.",
				Siguiente = "pregunta_pila",
			},

			-- ── 3. PREGUNTA: ESTRUCTURA DE DFS ──────────────────────────
			{
				Id        = "pregunta_pila",
				Numero    = 3,
				Actor     = "Sistema",
				Expresion = "Feliz",
				Texto     = "Pregunta rápida: DFS usa una estructura llamada PILA. ¿Qué significa LIFO, la regla que gobierna una pila?",
				Opciones = {
					{ Texto = "Last In, First Out: el último en entrar es el primero en salir.", Siguiente = "resp_correcta" },
					{ Texto = "Last In, First On: el último en entrar se queda al fondo.",       Siguiente = "resp_incorrecta" },
					{ Texto = "Large Input, Fast Output: cuanto más grande, más rápido.",        Siguiente = "resp_incorrecta" },
				},
			},

			-- ── 4a. RESPUESTA CORRECTA ──────────────────────────────────
			{
				Id        = "resp_correcta",
				Numero    = 4,
				Actor     = "Sistema",
				Expresion = "Feliz",
				Texto     = "¡Exacto! LIFO = Last In, First Out. Cuando DFS apila los vecinos de un nodo, el último vecino añadido será el primero en procesarse. Por eso DFS se adentra tan profundo: siempre sigue el camino más reciente antes de volver atrás.",
				Evento = function()
					local jugador = game:GetService("Players").LocalPlayer
					if jugador then
						local puntajeActual = jugador:GetAttribute("PuntajeDialogo") or 0
						jugador:SetAttribute("PuntajeDialogo", puntajeActual + 100)
					end
					notificarRespuestaCorrecta()
				end,
				Opciones = { { Texto = "Continuar", Siguiente = "componente_aislado" } },
			},

			-- ── 4b. RESPUESTA INCORRECTA ────────────────────────────────
			{
				Id        = "resp_incorrecta",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No exactamente. LIFO significa Last In, First Out: el último elemento que entra a la pila es el primero que sale. Imagina una pila de platos: el último que pones arriba es el primero que quitas. DFS usa esa regla para siempre seguir el camino más reciente antes de retroceder.",
				Opciones = { { Texto = "Entendido", Siguiente = "componente_aislado" } },
			},

			-- ── 5. COMPONENTE AISLADO ───────────────────────────────────
			{
				Id        = "componente_aislado",
				Numero    = 5,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Cuando DFS agota su pila sin visitar todos los nodos, significa que llegó al final de una rama y no encontró más conexiones",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Poste_Canchas_z3", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Poste2_Canchas_z3", "ADYACENTE")
					EfectosDialogo.mostrarLabel("Poste_Canchas_z3", "DFS inicia aquí")
					EfectosDialogo.mostrarLabel("Casa_Canchas_z3", "Componente aislado", "ERROR")
				end,
				EfectosDialogo.limpiarTodo(),
				Siguiente = "FIN",
			},
		},

		Metadata = { TiempoDeEspera = 0.5, VelocidadTypewriter = 0.03, PuedeOmitir = true, OcultarHUD = true, UsarTTS = true },
		Configuracion = { bloquearMovimiento = true, bloquearSalto = true, apuntarCamara = true, ocultarTechos = true },
	},
}
return DIALOGOS
