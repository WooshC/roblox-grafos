-- ReplicatedStorage/DialogoData/DialogosNivel1/Nivel1_Parque.lua

local EfectosDialogo = require(game:GetService("ReplicatedStorage"):WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
local ServicioCamara = require(game:GetService("ReplicatedStorage"):WaitForChild("Compartido"):WaitForChild("ServicioCamara"))

local DIALOGOS = {
	["Nivel1_Parque"] = {
		Zona  = "Zona_Parque_4",
		Nivel = 1,
		Lineas = {
			{
				Id        = "intro_parque",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Sonriente",
				Texto     = "¡El Parque del Barrio! Un espacio con 4 postes de alumbrado, una Fuente Central y un Kiosco. Seis nodos en total. Una vez que los conectes a la red, BFS los cubre todos en solo 2 capas.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Fuente_z4", { altura = 42, angulo = 68, duracion = 1.8 })
					EfectosDialogo.resaltarNodo("Fuente_z4", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Poste1_z4", "ERROR")
					EfectosDialogo.resaltarNodo("Poste2_z4", "ERROR")
					EfectosDialogo.resaltarNodo("Poste3_z4", "ERROR")
					EfectosDialogo.resaltarNodo("Poste4_z4", "ERROR")
					EfectosDialogo.resaltarNodo("Kiosco_z4", "ERROR")
				end,
				Siguiente = "pregunta_capas",
			},
			{
				Id        = "pregunta_capas",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "Poste 1 conecta con Poste 2 y la Fuente. Fuente conecta con Poste 3 y el Kiosco. Poste 3 llega a Poste 4. ¿Cuántas capas de BFS necesita para visitar los 6 nodos desde el Poste 1?",
				Opciones = {
					{ Texto = "1 capa.",  Siguiente = "resp_incorrecta" },
					{ Texto = "2 capas.", Siguiente = "resp_correcta"   },
					{ Texto = "6 capas.", Siguiente = "resp_incorrecta" },
				},
			},
			{
				Id        = "resp_correcta",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Extasiado",
				Texto     = "¡Exacto! Capa 1: Poste 2 y Fuente. Capa 2: Poste 3, Kiosco y Poste 4. Dos capas son suficientes porque el grafo del Parque está bien conectado. ¡Ahora tiende los cables y enciende todo el barrio!",
				Opciones = { { Texto = "¡Vamos!", Siguiente = "instruccion" } },
			},
			{
				Id        = "resp_incorrecta",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Triste",
				Texto     = "No exactamente. BFS agrupa los nodos por distancia en saltos. Poste 2 y Fuente están a 1 salto del Poste 1; Poste 3, Kiosco y Poste 4 están a 2 saltos. Dos capas cubren los 6 nodos.",
				Opciones = { { Texto = "Entendido", Siguiente = "instruccion" } },
			},
			{
				Id        = "instruccion",
				Numero    = 4,
				Actor     = "Sistema",
				Texto     = "Conecta el Poste 1 al Poste de las Canchas para unir el subgrafo aislado. Luego enlaza la Fuente y los demás postes para iluminar el Parque al 100%.",
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
