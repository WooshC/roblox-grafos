-- ReplicatedStorage/DialogoData/DialogosNivel1/Nivel1_Estacion.lua

local EfectosDialogo = require(game:GetService("ReplicatedStorage"):WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
local ServicioCamara = require(game:GetService("ReplicatedStorage"):WaitForChild("Compartido"):WaitForChild("ServicioCamara"))

local DIALOGOS = {
	["Nivel1_Estacion"] = {
		Zona  = "Zona_Ferroviaria_1",
		Nivel = 1,
		Lineas = {
			{
				Id        = "intro_bulevar",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Preocupado",
				Texto     = "¡Tocino! Este es tu primer encargo real. Estamos en el Barrio Antiguo. Los vecinos se quejan de que la luz va y viene misteriosamente por aquí.",
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
				Texto     = "El alcalde asegura que 'todo el barrio está electrificado', pero miente. Vamos a abrir el Panel de Análisis para estudiar la red paso a paso y revelar la verdad.",
				Evento = function()
					EfectosDialogo.mostrarLabel("Gen_Estacion_z1", "Generador Principal", "SELECCIONADO")
				end,
				Siguiente = "pregunta_1",
			},
			{
				Id        = "pregunta_1",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "Pregunta: ¿Acaso recuerdas cómo el algoritmo explora los nodos en nuestro Panel de Análisis?",
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
				Texto     = "¡Cierto! El algoritmo avanza hacia afuera, visitando a todos los vecinos de una misma capa antes de pasar a la siguiente. ¡A descubrir la verdad!",
				-- [TODO] Aquí agregaremos el puntaje +100 luego
				Opciones = { { Texto = "Continuar", Siguiente = "instruccion" } },
			},
			{
				Id        = "resp_1_incorrecta",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No exactamente, Tocino. Observarás que el algoritmo explora hacia afuera en forma de anillos, procesando todos los vecinos inmediatos capa por capa.",
				Opciones = { { Texto = "Entendido", Siguiente = "instruccion" } },
			},
			{
				Id        = "instruccion",
				Numero    = 5,
				Actor     = "Sistema",
				Texto     = "Abre el Analizador HUD para estudiar esta primera zona antes de ir a conectar los cables faltantes.",
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
