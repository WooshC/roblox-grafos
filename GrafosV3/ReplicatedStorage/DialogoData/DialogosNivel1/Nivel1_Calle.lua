-- ReplicatedStorage/DialogoData/DialogosNivel1/Nivel1_Calle.lua
-- Diálogo para la Zona de la Calle Principal

local EfectosDialogo = require(game:GetService("ReplicatedStorage"):WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
local ServicioCamara = require(game:GetService("ReplicatedStorage"):WaitForChild("Compartido"):WaitForChild("ServicioCamara"))

local DIALOGOS = {

	["Nivel1_Calle"] = {
		Zona  = "Zona_Calle",
		Nivel = 1,

		Lineas = {
			{
				Id        = "calle_oscura",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Esta calle es el puente hacia el resto del barrio. Sin este poste conectado, la energía nunca llegará a la periferia.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Poste_Calle", { altura = 22, angulo = 60, duracion = 1.2 })
					EfectosDialogo.resaltarNodo("Poste_Calle", "ADYACENTE")
				end,
				Siguiente = "instruccion",
			},
			{
				Id        = "instruccion",
				Numero    = 2,
				Actor     = "Sistema",
				Texto     = "Extiende la red: conecta la Bodega Don Pepe con el Poste de Alumbrado.",
				Evento = function()
					EfectosDialogo.mostrarLabel("Poste_Calle", "Poste Clave")
				end,
				EsperarAccion = { tipo = "conectarNodos", nodoA = "Casa_B", nodoB = "Poste_Calle" },
				Siguiente = "buen_progreso",
			},
			{
				Id        = "buen_progreso",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "¡Bien! El flujo de energía ahora puede avanzar. Sigue hacia la periferia, allí es donde más nos necesitan.",
				Evento = function()
					ServicioCamara.restaurar(1.0)
				end,
				Siguiente = "FIN",
			},
		},
	},
}

return DIALOGOS
