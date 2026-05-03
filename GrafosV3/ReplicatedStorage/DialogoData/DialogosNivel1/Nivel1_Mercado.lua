-- ReplicatedStorage/DialogoData/DialogosNivel1/Nivel1_Mercado.lua
-- Diálogo de la Zona 2 (Mercado Central) — Nivel 1: El Barrio Antiguo
-- Concepto BFS: Distancia Mínima en Saltos

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
	["Nivel1_Mercado"] = {
		Zona  = "Zona_Mercado_2",
		Nivel = 1,
		Lineas = {
			-- ── Introducción ──────────────────────────────────────────────────
			{
				Id        = "intro_mercado",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "¡Llegamos al Mercado! Aunque a estas horas los puestos están cerrados, podemos ver el cableado. Cada cable que tiendes crea una nueva ARISTA entre dos nodos.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Poste_Mercado_z2", { altura = 28, angulo = 60, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Poste_Mercado_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Puesto_Mercado_z2", "SELECCIONADO")
				end,
				Siguiente = "concepto_adyacencia",
			},
			-- ── Concepto: Adyacencia ──────────────────────────────────────────
			{
				Id        = "concepto_adyacencia",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "Dos nodos son ADYACENTES si existe una arista directa entre ellos. El Poste del Mercado es adyacente al Puesto porque los une el cable que ya está tendido. Pero recuerda: adyacente no significa 'cerca en el mapa', significa 'conectado directamente'.",
				Evento = function()
					EfectosDialogo.mostrarArista("Poste_Mercado_z2", "Puesto_Mercado_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarLabel("Poste_Mercado_z2", "Poste del Mercado")
					EfectosDialogo.mostrarLabel("Puesto_Mercado_z2", "Puesto del Mercado")
				end,
				Siguiente = "pregunta_adyacencia",
			},
			-- ── Pregunta 1: Adyacencia ────────────────────────────────────────
			{
				Id        = "pregunta_adyacencia",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Curioso",
				Texto     = "Escucha bien: si el nodo A está conectado a B, y B está conectado a C, pero A NO tiene cable directo con C… ¿qué relación tiene A con C?",
				Opciones = {
					{ Texto = "A y C son adyacentes.",             Siguiente = "resp_adyacencia_mal"  },
					{ Texto = "A y C no son adyacentes, pero C es alcanzable desde A.", Siguiente = "resp_adyacencia_bien" },
					{ Texto = "A y C son el mismo nodo.",          Siguiente = "resp_adyacencia_mal"  },
				},
			},
			{
				Id        = "resp_adyacencia_bien",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Sonriente",
				Texto     = "¡Correcto! La adyacencia requiere arista directa. Pero C sigue siendo alcanzable desde A pasando por B. BFS descubrirá C cuando procese los vecinos de B. Esa es la magia de explorar por capas.",
				Evento = function()
					local jugador = game:GetService("Players").LocalPlayer
					if jugador then
						local puntajeActual = jugador:GetAttribute("PuntajeDialogo") or 0
						jugador:SetAttribute("PuntajeDialogo", puntajeActual + 100)
					end
					notificarRespuestaCorrecta()
				end,
				Opciones = { { Texto = "Continuar", Siguiente = "concepto_bfs_cola" } },
			},
			{
				Id        = "resp_adyacencia_mal",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No exactamente. Adyacente significa arista DIRECTA. A-C no tienen cable, así que NO son adyacentes. Pero C sí es alcanzable desde A viajando por B. BFS lo encontrará en la siguiente capa de exploración.",
				Opciones = { { Texto = "Entendido", Siguiente = "concepto_bfs_cola" } },
			},
			-- ── Concepto: Cola FIFO de BFS ────────────────────────────────────
			{
				Id        = "concepto_bfs_cola",
				Numero    = 5,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "BFS usa una estructura llamada COLA. Es FIFO: el primero en entrar es el primero en salir. Los vecinos del nodo actual se colocan al final de la cola y se procesan en orden. Por eso nunca salta de nivel: primero termina toda una capa antes de pasar a la siguiente.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Poste_Mercado_z2", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Puesto_Mercado_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Parque_z2", "ADYACENTE")
					EfectosDialogo.mostrarLabel("Poste_Mercado_z2", "Capa 0")
					EfectosDialogo.mostrarLabel("Puesto_Mercado_z2", "Capa 1")
					EfectosDialogo.mostrarLabel("Parque_z2", "Capa 1")
				end,
				Siguiente = "pregunta_bfs_cola",
			},
			-- ── Pregunta 2: Cola FIFO ─────────────────────────────────────────
			{
				Id        = "pregunta_bfs_cola",
				Numero    = 6,
				Actor     = "Carlos",
				Expresion = "Curioso",
				Texto     = "Si la cola de BFS tiene [B, C, D] y procesas B descubriendo E y F, ¿cuál es el nuevo estado de la cola?",
				Opciones = {
					{ Texto = "[E, F, C, D]",    Siguiente = "resp_cola_mal"  },
					{ Texto = "[C, D, E, F]",    Siguiente = "resp_cola_bien" },
					{ Texto = "[B, C, D, E, F]", Siguiente = "resp_cola_mal"  },
				},
			},
			{
				Id        = "resp_cola_bien",
				Numero    = 7,
				Actor     = "Carlos",
				Expresion = "Extasiado",
				Texto     = "¡Perfecto! B salió por el frente (fue procesado), y E y F se añaden al final. La cola queda [C, D, E, F]. Esto garantiza que BFS termine capa por capa, nunca salteando niveles. ¡Así se encuentra la ruta más corta en saltos!",
				Evento = function()
					local jugador = game:GetService("Players").LocalPlayer
					if jugador then
						local puntajeActual = jugador:GetAttribute("PuntajeDialogo") or 0
						jugador:SetAttribute("PuntajeDialogo", puntajeActual + 100)
					end
					notificarRespuestaCorrecta()
				end,
				Opciones = { { Texto = "Continuar", Siguiente = "instruccion" } },
			},
			{
				Id        = "resp_cola_mal",
				Numero    = 7,
				Actor     = "Carlos",
				Expresion = "Triste",
				Texto     = "Recuerda: FIFO. B sale del frente (ya fue procesado), y los nuevos nodos E y F se añaden al FINAL. C y D siguen esperando su turno. La cola correcta es [C, D, E, F]. Eso mantiene el orden de capas.",
				Opciones = { { Texto = "Entendido", Siguiente = "instruccion" } },
			},
			-- ── Instrucción final ─────────────────────────────────────────────
			{
				Id        = "instruccion",
				Numero    = 8,
				Actor     = "Sistema",
				Texto     = "Usa el Analizador BFS para ver la cola en acción. Conecta el Parque del Mercado y el Puesto antes de avanzar hacia las Canchas. Recuerda: cada arista nueva acerca la luz a más familias.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.restaurar(1.2)
				end,
				Siguiente = "FIN",
			},
		},
		Metadata = { TiempoDeEspera = 0.5, VelocidadTypewriter = 0.03, PuedeOmitir = true, OcultarHUD = true, UsarTTS = true },
		Configuracion = { bloquearMovimiento = true, bloquearSalto = true, apuntarCamara = true, ocultarTechos = true },
	},
}
return DIALOGOS
