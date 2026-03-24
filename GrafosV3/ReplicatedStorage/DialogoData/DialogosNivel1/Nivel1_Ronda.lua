-- ReplicatedStorage/DialogoData/DialogosNivel1/Nivel1_Ronda.lua

local EfectosDialogo = require(game:GetService("ReplicatedStorage"):WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
local ServicioCamara = require(game:GetService("ReplicatedStorage"):WaitForChild("Compartido"):WaitForChild("ServicioCamara"))

local DIALOGOS = {
	["Nivel1_Ronda"] = {
		Zona  = "Zona_Ronda",
		Nivel = 1,
		Lineas = {
			{
				Id        = "intro_ronda",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "Esta calle depende del Bulevar. Hemos creado un 'puente' para traer la energía. Ahora usaremos BFS localmente desde el poste de entrada.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Poste_LaRonda", { altura = 25, angulo = 65, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Poste_LaRonda", "ADYACENTE")
				end,
				Siguiente = "pregunta_2",
			},
			{
				Id        = "pregunta_2",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "¿Qué verificamos exactamente al lanzar un BFS solo en esta calle, iniciando desde el Poste La Ronda?",
				Opciones = {
					{ Texto = "La conexión con todo Quito.", Siguiente = "resp_2_incorrecta" },
					{ Texto = "La cobertura interna del Subgrafo local.", Siguiente = "resp_2_correcta" },
					{ Texto = "Si el puente está roto.", Siguiente = "resp_2_incorrecta" },
				},
			},
			{
				Id        = "resp_2_correcta",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Sonriente",
				Texto     = "¡Exacto! El analizador revisará que las casas dentro de La Ronda estén bien enredadas. Al asegurar el subgrafo interno, heredamos bien la luz del Bulevar.",
				-- [TODO] Aquí agregaremos el puntaje +100 luego
				Opciones = { { Texto = "Continuar", Siguiente = "instruccion" } },
			},
			{
				Id        = "resp_2_incorrecta",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Recuerda que estamos analizando zonas de forma local. Al lanzar el pulso desde el poste, comprobamos la cobertura interna exclusiva del subgrafo de esta calle.",
				Opciones = { { Texto = "Entendido", Siguiente = "instruccion" } },
			},
			{
				Id        = "instruccion",
				Numero    = 4,
				Actor     = "Sistema",
				Texto     = "Tiende el cable cruzando toda La Ronda para que el pulso pueda avanzar hacia Santo Domingo.",
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
