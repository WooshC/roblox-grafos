-- ReplicatedStorage/DialogoData/DialogosNivel1/Nivel1_Canchas.lua
-- Diálogo de la Zona 3 (Las Canchas) — Nivel 1: El Barrio Antiguo
-- Concepto BFS: Nodos y Subgrafos Aislados

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
	["Nivel1_Canchas"] = {
		Zona  = "Zona_Canchas_3",
		Nivel = 1,
		Lineas = {
			{
				Id        = "intro_canchas",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Preocupado",
				Texto     = "Las Canchas... El alcalde juró que incluso los vecindarios más alejados tenían luz. Pero mira: hay dos postes, y la Casa de las Canchas sigue completamente a oscuras. Ejecuta BFS desde el Poste de las Canchas y verás exactamente dónde se rompe la cadena.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Poste_Canchas_z3", { altura = 32, angulo = 58, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Casa_Canchas_z3", "ERROR")
					EfectosDialogo.resaltarNodo("Poste2_Canchas_z3", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Poste_Canchas_z3", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("Casa_Canchas_z3", "Sin luz", "ERROR")
				end,
				Siguiente = "pregunta_componente",
			},
			{
				Id        = "pregunta_componente",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "BFS agotó su cola sin visitar todos los nodos. En teoría de grafos, ¿cómo se llama formalmente esta parte del barrio que quedó sin energía y sin conexión al resto?",
				Opciones = {
					{ Texto = "Un subgrafo dirigido.",         Siguiente = "resp_incorrecta" },
					{ Texto = "Un componente conexo aislado.", Siguiente = "resp_correcta"   },
					{ Texto = "Un nodo raíz externo.",         Siguiente = "resp_incorrecta" },
				},
			},
			{
				Id        = "resp_correcta",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "¡Correcto! Un Componente Conexo es un subconjunto de nodos donde todos se pueden alcanzar entre sí, pero no tienen ninguna arista que los una al resto del grafo. ¡Eso es exactamente lo que el alcalde ocultó! Una manzana entera aislada.",
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
				Id        = "resp_incorrecta",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Triste",
				Texto     = "No exactamente. Cuando un BFS se detiene con la cola vacía y aún quedan nodos sin visitar, esos nodos forman un Componente Conexo aislado: un 'islote' sin cables que lo unan al grafo principal. Es como una isla sin puentes.",
				Opciones = { { Texto = "Entendido", Siguiente = "instruccion" } },
			},
			{
				Id        = "instruccion",
				Numero    = 4,
				Actor     = "Sistema",
				Texto     = "Conecta el Segundo Poste de las Canchas e ilumina la zona completa. Luego tiende el cable hacia el Parque para rescatar el componente aislado. Cada componente aislado que unes es una familia que recupera la luz.",
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
