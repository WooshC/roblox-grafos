-- ReplicatedStorage/DialogoData/DialogosNivel1/Nivel1_Mercado.lua

local EfectosDialogo = require(game:GetService("ReplicatedStorage"):WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
local ServicioCamara = require(game:GetService("ReplicatedStorage"):WaitForChild("Compartido"):WaitForChild("ServicioCamara"))

local DIALOGOS = {
	["Nivel1_Mercado"] = {
		Zona  = "Zona_Mercado_2",
		Nivel = 1,
		Lineas = {
			{
				Id        = "intro_ronda",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "Buen trabajo con el puente. Hemos llegado al Mercado Central de la locación. El Panel de Análisis nos mostrará cómo BFS continúa expandiéndose.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Poste_Mercado_z2", { altura = 25, angulo = 65, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Poste_Mercado_z2", "ADYACENTE")
				end,
				Siguiente = "pregunta_2",
			},
			{
				Id        = "pregunta_2",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "¿Qué beneficio especial obtenemos al expandir la exploración por 'capas' concéntricas usando BFS en este barrio plano?",
				Opciones = {
					{ Texto = "Las luces encienden todas exactamente en la misma dirección cardinal.", Siguiente = "resp_2_incorrecta" },
					{ Texto = "Hallamos el camino usando la menor cantidad de uniones o saltos.", Siguiente = "resp_2_correcta" },
					{ Texto = "Ahorramos consumo eléctrico en redes con distancias pesadas.", Siguiente = "resp_2_incorrecta" },
				},
			},
			{
				Id        = "resp_2_correcta",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Sonriente",
				Texto     = "¡Exacto! Al no tener cables de distintos pesos, probar el algoritmo por capas de BFS nos garantiza la ruta con menos saltos posibles.",
				-- [TODO] Aquí agregaremos el puntaje +100 luego
				Opciones = { { Texto = "Continuar", Siguiente = "instruccion" } },
			},
			{
				Id        = "resp_2_incorrecta",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Piénsalo bien. Explorar en capas permite que BFS alcance sus destinos usando el camino que necesita atravesar la menor cantidad de 'postes' o 'saltos'.",
				Opciones = { { Texto = "Entendido", Siguiente = "instruccion" } },
			},
			{
				Id        = "instruccion",
				Numero    = 4,
				Actor     = "Sistema",
				Texto     = "Verifica la red del Mercado con el Analizador y tiende el nuevo cable para seguir cruzando el barrio.",
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
