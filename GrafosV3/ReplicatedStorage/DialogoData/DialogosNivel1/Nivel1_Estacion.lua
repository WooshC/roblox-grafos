-- ReplicatedStorage/DialogoData/DialogosNivel1/Nivel1_Estacion.lua
-- Diálogo de la Zona 1 (Estación Plana) — Nivel 1: El Barrio Antiguo
-- Concepto BFS: Expansión Capa por Capa (Cola FIFO)

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
	["Nivel1_Estacion"] = {
		Zona  = "Zona_Ferroviaria_1",
		Nivel = 1,
		Lineas = {
			{
				Id        = "intro_estacion",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Preocupado",
				Texto     = "¡Tocino! Este es tu primer encargo real. Estamos en el Barrio Antiguo... y mira esto. A las doce de la noche, todo debería estar iluminado, pero las casas están a oscuras.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Gen_Estacion_z1", { altura = 25, angulo = 65, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Gen_Estacion_z1", "SELECCIONADO")
				end,
				Siguiente = "la_mision",
			},
			{
				Id        = "la_mision",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "El alcalde asegura que 'todo el barrio está electrificado', pero eso es una mentira. Vamos a abrir el Panel de Análisis para estudiar la red paso a paso y revelar la verdad.",
				Evento = function()
					EfectosDialogo.mostrarLabel("Gen_Estacion_z1", "Generador Principal", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Casa_Estacion1_z1", "AISLADO")
					EfectosDialogo.resaltarNodo("Casa_Estacion2_z1", "AISLADO")
				end,
				Siguiente = "pregunta_1",
			},
			{
				Id        = "pregunta_1",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "Pregunta rápida: ¿Recuerdas cómo el algoritmo BFS explora los nodos en el Panel de Análisis?",
				Opciones = {
					{ Texto = "Explora a todos los vecinos inmediatos primero, capa por capa.", Siguiente = "resp_1_correcta" },
					{ Texto = "Va corriendo en una sola línea recta de principio a fin.", Siguiente = "resp_1_incorrecta" },
					{ Texto = "Mide la distancia en metros hacia cada poste.", Siguiente = "resp_1_incorrecta" },
				},
			},
			{
				Id        = "resp_1_correcta",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "¡Cierto! El algoritmo avanza hacia afuera en anillos, visitando a todos los vecinos de una misma capa antes de pasar a la siguiente. Eso nos permitirá ver exactamente dónde el alcalde dejó la red incompleta. ¡A descubrir la verdad!",
				Evento = function()
					-- Otorgar +100 puntos al responder correctamente
					local jugador = game:GetService("Players").LocalPlayer
					if jugador then
						local puntajeActual = jugador:GetAttribute("PuntajeDialogo") or 0
						jugador:SetAttribute("PuntajeDialogo", puntajeActual + 100)
					end
					-- Notificar al servidor para el conteo de 3 estrellas
					notificarRespuestaCorrecta()
				end,
				Opciones = { { Texto = "Continuar", Siguiente = "instruccion" } },
			},
			{
				Id        = "resp_1_incorrecta",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No exactamente, Tocino. Observarás que el algoritmo explora hacia afuera en forma de anillos, procesando todos los vecinos inmediatos capa por capa. Es como lanzar una piedra al agua: las ondas se expanden en círculos.",
				Opciones = { { Texto = "Entendido", Siguiente = "instruccion" } },
			},
			{
				Id        = "instruccion",
				Numero    = 5,
				Actor     = "Sistema",
				Texto     = "Abre el Analizador HUD (Tecla Tab) para estudiar esta primera zona antes de ir a conectar los cables faltantes. Observa cómo BFS expande capa por capa desde el Generador Principal.",
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
