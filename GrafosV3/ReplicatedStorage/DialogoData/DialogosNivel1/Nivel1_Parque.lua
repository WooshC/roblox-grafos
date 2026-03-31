-- ReplicatedStorage/DialogoData/DialogosNivel1/Nivel1_Parque.lua

local EfectosDialogo = require(game:GetService("ReplicatedStorage"):WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
local ServicioCamara = require(game:GetService("ReplicatedStorage"):WaitForChild("Compartido"):WaitForChild("ServicioCamara"))

local DIALOGOS = {
	["Nivel1_Parque"] = {
		Zona  = "Zona_Parque_4",
		Nivel = 1,
		Lineas = {
			{
				Id        = "intro_panecillo",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Sonriente",
				Texto     = "Este es el Parque del Barrio. Aquí culmina nuestra misión. Revisa que no queden más casas desconectadas como las que el alcalde intentó ocultar.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Casa_Parque1_z4", { altura = 40, angulo = 70, duracion = 1.8 })
					EfectosDialogo.resaltarNodo("Casa_Parque1_z4", "ERROR")
				end,
				Siguiente = "pregunta_4",
			},
			{
				Id        = "pregunta_4",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "Para resolver el problema permanentemente y arreglar la red, ¿cuál debe ser el estado final de nuestro grafo al terminar de conectar los cables?",
				Opciones = {
					{ Texto = "Que existan múltiples componentes aislados.", Siguiente = "resp_4_incorrecta" },
					{ Texto = "Que la red abarque el 100% de los nodos, formando un Grafo Conexo.", Siguiente = "resp_4_correcta" },
					{ Texto = "Que varios subgrafos permanezcan cerrados.", Siguiente = "resp_4_incorrecta" },
				},
			},
			{
				Id        = "resp_4_correcta",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Extasiado",
				Texto     = "¡SÍ! Nuestra misión es la conectividad total. Si ningún nodo se queda fuera tras crear los bordes, hemos logrado el 100% de cobertura. ¡Termina las conexiones y salva el barrio!",
				-- [TODO] Aquí agregaremos el puntaje +100 luego
				Opciones = { { Texto = "Continuar", Siguiente = "instruccion" } },
			},
			{
				Id        = "resp_4_incorrecta",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Triste",
				Texto     = "Incorrecto. Cuando logramos crear cables (aristas) que integren absolutamente todos los subgrafos, forman un único bloque maestro llamado Grafo Conexo. Esa es nuestra meta.",
				Opciones = { { Texto = "Entendido", Siguiente = "instruccion" } },
			},
			{
				Id        = "instruccion",
				Numero    = 4,
				Actor     = "Sistema",
				Texto     = "Crea el puente final desde la Casa de las Canchas al Poste del Parque e ilumina todo el barrio para ganar.",
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
