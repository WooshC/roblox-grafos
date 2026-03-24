-- ReplicatedStorage/DialogoData/DialogosNivel1/Nivel1_Periferia.lua
-- Diálogo para la Zona de la Periferia

local EfectosDialogo = require(game:GetService("ReplicatedStorage"):WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
local ServicioCamara = require(game:GetService("ReplicatedStorage"):WaitForChild("Compartido"):WaitForChild("ServicioCamara"))

local DIALOGOS = {

	["Nivel1_Periferia"] = {
		Zona  = "Zona_Periferia",
		Nivel = 1,

		Lineas = {
			{
				Id        = "periferia_aislada",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Preocupado",
				Texto     = "Aquí estamos... la periferia. Estas casas están completamente aisladas del grafo principal. Son 'Nodos Aislados'.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Casa_F", { altura = 25, angulo = 65, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Casa_D", "ERROR")
					EfectosDialogo.resaltarNodo("Casa_E", "ERROR")
					EfectosDialogo.resaltarNodo("Casa_F", "ERROR")
				end,
				Siguiente = "el_alcalde",
			},
			{
				Id        = "el_alcalde",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Incluso la casa del Alcalde está a oscuras. Si logras conectar todo este sector al generador, habrás salvado el barrio.",
				Evento = function()
					EfectosDialogo.mostrarLabel("Casa_F", "Casa del Alcalde")
				end,
				Siguiente = "meta_final",
			},
			{
				Id        = "meta_final",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Sonriente",
				Texto     = "Haz que el barrio sea un 'Grafo Conexo'. ¡Ilumínalo todo!",
				Evento = function()
					ServicioCamara.restaurar(1.0)
				end,
				Siguiente = "FIN",
			},
		},
	},
}

return DIALOGOS
