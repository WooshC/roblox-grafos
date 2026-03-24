-- ReplicatedStorage/DialogoData/DialogosNivel1/Nivel1_Bulevar.lua

local EfectosDialogo = require(game:GetService("ReplicatedStorage"):WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
local ServicioCamara = require(game:GetService("ReplicatedStorage"):WaitForChild("Compartido"):WaitForChild("ServicioCamara"))

local DIALOGOS = {
	["Nivel1_Bulevar"] = {
		Zona  = "Zona_Bulevar",
		Nivel = 1,
		Lineas = {
			{
				Id        = "intro_bulevar",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Preocupado",
				Texto     = "¡Tocino! El Centro Histórico de Quito está en penumbras. Empezaremos aquí, en el Bulevar 24 de Mayo, donde está el Generador Central.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Transformador_Bulevar", { altura = 25, angulo = 65, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Transformador_Bulevar", "SELECCIONADO")
				end,
				Siguiente = "la_mision",
			},
			{
				Id        = "la_mision",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "La ciudad se divide en zonas. Nuestra meta es arreglar cada 'Subgrafo' local para que, al conectarlos mediante puentes, formemos un Grafo Conexo Global.",
				Evento = function()
					EfectosDialogo.mostrarLabel("Transformador_Bulevar", "Generador 24 de Mayo", "SELECCIONADO")
				end,
				Siguiente = "pregunta_1",
			},
			{
				Id        = "pregunta_1",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "Pregunta de validación: ¿A qué llamamos explorar el 'Nivel 1' en un algoritmo BFS (Breadth-First Search)?",
				Opciones = {
					{ Texto = "A los vecinos directos del nodo inicial.", Siguiente = "resp_1_correcta" },
					{ Texto = "Al nodo que está más lejos del generador.", Siguiente = "resp_1_incorrecta" },
					{ Texto = "A cualquier casa con luz.", Siguiente = "resp_1_incorrecta" },
				},
			},
			{
				Id        = "resp_1_correcta",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "¡Exactamente! BFS expande la energía como una onda: primero toca a todos los vecinos colindantes directos. ¡A conectar!",
				-- [TODO] Aquí agregaremos el puntaje +100 luego
				Opciones = { { Texto = "Continuar", Siguiente = "instruccion" } },
			},
			{
				Id        = "resp_1_incorrecta",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No es así. El 'Nivel 1' en BFS siempre se refiere a los vecinos inmediatamente conectados al nodo desde donde iniciamos el pulso.",
				Opciones = { { Texto = "Entendido", Siguiente = "instruccion" } },
			},
			{
				Id        = "instruccion",
				Numero    = 5,
				Actor     = "Sistema",
				Texto     = "Revisa el Transformador del Bulevar y abre el Panel de Análisis para enviar tu primer pulso.",
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
