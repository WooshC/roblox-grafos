-- ReplicatedStorage/DialogoData/Feedback_Conexiones.lua
-- Diálogos cortos de retroalimentación para errores de conexión.
-- Se lanzan desde RetroalimentacionConexion.client.lua vía _G.ControladorDialogo.iniciar().

local DIALOGOS = {

	-- ════════════════════════════════════════════════════════════════════
	-- ERROR 1: Nodos no adyacentes
	-- ════════════════════════════════════════════════════════════════════
	["Feedback_ConexionInvalida"] = {
		Zona  = nil,
		Nivel = nil,

		Lineas = {
			{
				Id        = "inicio",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Esos dos nodos no tienen una arista definida en este grafo. En teoría de grafos, solo puedes crear aristas entre pares de nodos que el grafo declare como adyacentes.",
				Siguiente = "consejo",
			},
			{
				Id        = "consejo",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Normal",
				Texto     = "Revisa qué nodos están marcados como vecinos del nodo seleccionado y elige uno de ellos como destino.",
				Siguiente = "FIN",
			},
		},

		Metadata = {
			TiempoDeEspera      = 0,
			VelocidadTypewriter = 0.025,
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
			ocultarTechos      = false,
			cerrarMapa         = false,
		},
	},

	-- ════════════════════════════════════════════════════════════════════
	-- ERROR 2: Dirección incorrecta en dígrafo
	-- ════════════════════════════════════════════════════════════════════
	["Feedback_DireccionInvalida"] = {
		Zona  = nil,
		Nivel = nil,

		Lineas = {
			{
				Id        = "inicio",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Este es un DÍGRAFO — un grafo dirigido. La arista entre esos dos nodos existe, pero solo en el sentido contrario al que intentaste.",
				Siguiente = "consejo",
			},
			{
				Id        = "consejo",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Normal",
				Texto     = "En un dígrafo cada arista tiene una dirección única. Invierte el orden: haz clic primero en el nodo de destino y luego en el de origen.",
				Siguiente = "FIN",
			},
		},

		Metadata = {
			TiempoDeEspera      = 0,
			VelocidadTypewriter = 0.025,
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
			ocultarTechos      = false,
			cerrarMapa         = false,
		},
	},
}

return DIALOGOS
