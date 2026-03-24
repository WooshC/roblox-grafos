-- ReplicatedStorage/DialogoData/DialogosNivel1/Nivel1_SantoDomingo.lua

local EfectosDialogo = require(game:GetService("ReplicatedStorage"):WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
local ServicioCamara = require(game:GetService("ReplicatedStorage"):WaitForChild("Compartido"):WaitForChild("ServicioCamara"))

local DIALOGOS = {
	["Nivel1_SantoDomingo"] = {
		Zona  = "Zona_SantoDomingo",
		Nivel = 1,
		Lineas = {
			{
				Id        = "intro_plaza",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Preocupado",
				Texto     = "Esta es la majestuosa Plaza de Santo Domingo. Pero si observas bien... aquí los cables desaparecen abruptamente.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Iglesia_SantoDomingo", { altura = 30, angulo = 60, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Casa_Plaza", "ERROR")
				end,
				Siguiente = "pregunta_3",
			},
			{
				Id        = "pregunta_3",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Imagina que lanzas un pulso BFS ahora mismo. Si la onda de luz se detiene bruscamente en la Cafetería y no logra avanzar hacia El Panecillo... ¿Qué significa eso para nuestra red?",
				Opciones = {
					{ Texto = "Que necesitamos lanzar un DFS.", Siguiente = "resp_3_incorrecta" },
					{ Texto = "Que el Grafo es No Dirigido.", Siguiente = "resp_3_incorrecta" },
					{ Texto = "Que tenemos un Componente Aislado.", Siguiente = "resp_3_correcta" },
				},
			},
			{
				Id        = "resp_3_correcta",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "¡Correcto! Si el pulso se detiene y quedan nodos apagados, significa que nuestro sistema eléctrico NO es un grafo conexo. Hemos detectado una componente aislada.",
				-- [TODO] Aquí agregaremos el puntaje +100 luego
				Opciones = { { Texto = "Continuar", Siguiente = "instruccion" } },
			},
			{
				Id        = "resp_3_incorrecta",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Triste",
				Texto     = "No exactamente. Si un BFS se detiene y quedan nodos sin visitar (en negro), significa que NO tenemos un grafo conexo. Esa zona apagada es un Componente Aislado.",
				Opciones = { { Texto = "Entendido", Siguiente = "instruccion" } },
			},
			{
				Id        = "instruccion",
				Numero    = 4,
				Actor     = "Sistema",
				Texto     = "Revisa que la energía llegue a la Iglesia de Santo Domingo, y prepárate para construir el puente hacia la montaña.",
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
