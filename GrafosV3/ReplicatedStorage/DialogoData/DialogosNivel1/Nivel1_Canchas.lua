-- ReplicatedStorage/DialogoData/DialogosNivel1/Nivel1_Canchas.lua

local EfectosDialogo = require(game:GetService("ReplicatedStorage"):WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
local ServicioCamara = require(game:GetService("ReplicatedStorage"):WaitForChild("Compartido"):WaitForChild("ServicioCamara"))

local DIALOGOS = {
	["Nivel1_Canchas"] = {
		Zona  = "Zona_Canchas_3",
		Nivel = 1,
		Lineas = {
			{
				Id        = "intro_plaza",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Preocupado",
				Texto     = "Llegamos a Las Canchas. Ejecuta el Analizador ahora: verás que la exploración avanza, procesa un par de casas y luego ¡puf!, se detiene con la cola vacía.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Poste_Canchas_z3", { altura = 30, angulo = 60, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Casa_Canchas_z3", "ERROR")
				end,
				Siguiente = "pregunta_3",
			},
			{
				Id        = "pregunta_3",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Alcalde o no, los cables no mienten. Si el algoritmo de BFS se detiene abruptamente y el nodo 'Casa de las Canchas' nunca es visitado, ¿qué acabamos de descubrir?",
				Opciones = {
					{ Texto = "Que necesitamos lanzar un algoritmo DFS en su lugar.", Siguiente = "resp_3_incorrecta" },
					{ Texto = "Que el Grafo es No Dirigido.", Siguiente = "resp_3_incorrecta" },
					{ Texto = "Que el barrio tiene un Componente Aislado.", Siguiente = "resp_3_correcta" },
				},
			},
			{
				Id        = "resp_3_correcta",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "¡Correcto! Si el algoritmo agota su cola y quedan nodos sin procesar, entonces no es un Grafo Conexo. ¡El alcalde dejó componentes aisladas completamente desconectadas!",
				-- [TODO] Aquí agregaremos el puntaje +100 luego
				Opciones = { { Texto = "Continuar", Siguiente = "instruccion" } },
			},
			{
				Id        = "resp_3_incorrecta",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Triste",
				Texto     = "No exactamente, Tocino. Si un BFS se detiene y la cola queda vacía dejando nodos sin visitar, significa que graficamente NO somos conexos. Hay un Componente Aislado.",
				Opciones = { { Texto = "Entendido", Siguiente = "instruccion" } },
			},
			{
				Id        = "instruccion",
				Numero    = 4,
				Actor     = "Sistema",
				Texto     = "Construye los puentes de cable necesarios desde las Canchas hacia el Parque para llevar energía al resto.",
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
