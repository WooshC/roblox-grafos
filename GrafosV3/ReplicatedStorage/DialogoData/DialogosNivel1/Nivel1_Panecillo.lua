-- ReplicatedStorage/DialogoData/DialogosNivel1/Nivel1_Panecillo.lua

local EfectosDialogo = require(game:GetService("ReplicatedStorage"):WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
local ServicioCamara = require(game:GetService("ReplicatedStorage"):WaitForChild("Compartido"):WaitForChild("ServicioCamara"))

local DIALOGOS = {
	["Nivel1_Panecillo"] = {
		Zona  = "Zona_Panecillo",
		Nivel = 1,
		Lineas = {
			{
				Id        = "intro_panecillo",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Sonriente",
				Texto     = "Finalmente, El Panecillo. La Virgen es un Componente Aislado gigantesco. Está apagada porque carece de un puente hacia nuestra red reparada.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Virgen_Panecillo", { altura = 40, angulo = 70, duracion = 1.8 })
					EfectosDialogo.resaltarNodo("Virgen_Panecillo", "ERROR")
				end,
				Siguiente = "pregunta_4",
			},
			{
				Id        = "pregunta_4",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "Una pregunta teórica: si tendemos el puente conectando este último subgrafo aislado al resto de zonas ya iluminadas... ¿Qué lograremos a nivel global?",
				Opciones = {
					{ Texto = "Múltiples componentes.", Siguiente = "resp_4_incorrecta" },
					{ Texto = "Un único Grafo Conexo.", Siguiente = "resp_4_correcta" },
					{ Texto = "Varios subgrafos cerrados.", Siguiente = "resp_4_incorrecta" },
				},
			},
			{
				Id        = "resp_4_correcta",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Extasiado",
				Texto     = "¡SÍ! Al unir las zonas con aristas puente, todos sus subgrafos locales se fusionan. Toda la ciudad se vuelve alcanzable. ¡Esto es un Grafo Conexo!",
				-- [TODO] Aquí agregaremos el puntaje +100 luego
				Opciones = { { Texto = "Continuar", Siguiente = "instruccion" } },
			},
			{
				Id        = "resp_4_incorrecta",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Triste",
				Texto     = "Incorrecto. Cuando logramos que absolutamente todos los subgrafos se conecten entre sí, forman un único bloque maestro donde cualquier nodo es alcanzable: un Grafo Conexo.",
				Opciones = { { Texto = "Entendido", Siguiente = "instruccion" } },
			},
			{
				Id        = "instruccion",
				Numero    = 4,
				Actor     = "Sistema",
				Texto     = "Crea el puente conectando la Cafetería Santo Domingo con el Poste de Subida, e ilumina la Virgen para ganar.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.restaurar(1.5)
				end,
				Siguiente = "FIN",
			},
		},
		Metadata = { TiempoDeEspera = 0.5, VelocidadTypewriter = 0.03, PuedeOmitir = true, OcultarHUD = true, UsarTTS = true },
		Configuracion = { bloquearMovimiento = true, bloquearSalto = true, apuntarCamara = true, ocultarTechos = true },
	},
}
return DIALOGOS
