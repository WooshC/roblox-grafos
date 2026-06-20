-- ReplicatedStorage/DialogoData/DialogosNivel0/ZonaCompletada_Generico.lua
-- Diálogo genérico de felicitación al completar una zona (NO es la última)
-- Se lanza desde ControladorHUD.client.lua al detectar zona completada vía ActualizarMisiones

local DIALOGOS = {

	["ZonaCompletada_Generico"] = {
		Zona  = nil,
		Nivel = nil,

		Lineas = {
			{
				Id        = "felicitacion",
				Numero    = 1,
				Actor     = "Sistema",
				Expresion = "Feliz",
				Texto     = "¡Excelente trabajo! Has completado todas las misiones de esta zona.",
				Siguiente = "siguiente_zona",
			},
			{
				Id        = "verdad",
				Numero    = 2,
				Actor     = "Sistema",
				Expresion = "Procesando",
				Texto     = "Cada zona completada deja en evidencia los malos manejos del alcalde. Sigue así: estamos armando las pruebas necesarias.",
				Siguiente = "siguiente_zona",
			},
			{
				Id        = "siguiente_zona",
				Numero    = 3,
				Actor     = "Sistema",
				Expresion = "Presentacion",
				Texto     = "Dirígete a la siguiente zona para continuar tu aprendizaje.",
				Siguiente = "FIN",
			},
		},

		Metadata = {
			TiempoDeEspera      = 0.3,
			VelocidadTypewriter = 0.03,
			PuedeOmitir         = true,
			OcultarHUD          = false,
			UsarTTS             = true,
		},

		Configuracion = {
			bloquearMovimiento = false,
			bloquearSalto      = false,
			bloquearCarrera    = false,
			apuntarCamara      = false,
			permitirConexiones = true,
		},
	},
}

return DIALOGOS
