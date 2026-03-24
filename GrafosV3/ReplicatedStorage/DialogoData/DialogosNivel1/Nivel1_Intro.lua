-- ReplicatedStorage/DialogoData/Nivel1_Intro.lua
-- Diálogo introductorio para el Nivel 1: El Barrio de las Sombras

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LevelsConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("LevelsConfig"))
local EfectosDialogo = require(ReplicatedStorage:WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
local ServicioCamara = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("ServicioCamara"))

local DIALOGOS = {

	["Nivel1_Intro"] = {
		Zona  = "Zona_Barrio",
		Nivel = 1,

		Lineas = {
			{
				Id        = "bienvenida",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Preocupado",
				Texto     = "¡Tocino, qué bueno que llegas! El Barrio de las Sombras hace honor a su nombre... la gente está a oscuras.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Generador", { altura = 25, angulo = 65, duracion = 1.5 })
				end,
				Siguiente = "el_problema",
			},
			{
				Id        = "el_problema",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Mira el Generador Central. Debería alimentar a todo el barrio, pero hay casas que quedaron aisladas del grafo principal.",
				Evento = function()
					EfectosDialogo.resaltarNodo("Generador", "ADYACENTE")
					EfectosDialogo.mostrarLabel("Generador", "Generador Central")
				end,
				Siguiente = "la_mision",
			},
			{
				Id        = "la_mision",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Sonriente",
				Texto     = "Tu misión es encontrar esas casas apagadas (nodos aislados) y conectarlas. Necesitamos una Cobertura del 100%.",
				Evento = function()
					-- Resaltar un par de casas como ejemplo si es posible
					EfectosDialogo.resaltarNodo("Casa_D", "ERROR")
					EfectosDialogo.resaltarNodo("Casa_E", "ERROR")
					EfectosDialogo.mostrarLabel("Casa_D", "Sin Energía")
				end,
				Siguiente = "el_pulso",
			},
			{
				Id        = "el_pulso",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "Abre el Panel de Análisis y lanza un Pulso BFS desde el Generador. Si la luz llega a cada rincón, ¡habremos salvado el barrio!",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.restaurar(1.2)
				end,
				Siguiente = "FIN",
			},
		},

		Metadata = {
			TiempoDeEspera      = 0.5,
			VelocidadTypewriter = 0.03,
			PuedeOmitir         = true,
			OcultarHUD          = true,
			UsarTTS             = true,
		},

		Configuracion = {
			bloquearMovimiento = true,
			bloquearSalto      = true,
			apuntarCamara      = true,
			ocultarTechos      = true,
		},
	},
}

return DIALOGOS
