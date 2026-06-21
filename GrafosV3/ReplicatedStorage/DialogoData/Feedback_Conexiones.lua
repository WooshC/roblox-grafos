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

	-- ════════════════════════════════════════════════════════════════════
	-- ERROR 3: Nodo sobrecargado
	-- ════════════════════════════════════════════════════════════════════
	["Feedback_NodoSobrecargado"] = {
		Zona  = nil,
		Nivel = nil,

		Lineas = {
			{
				Id        = "inicio",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "El nodo se ha dañado por sobrecarga. Repáralo dando clic 3 veces sobre el nodo.",
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
	-- REPARACIÓN: quita el límite de grado
	-- ════════════════════════════════════════════════════════════════════
	["Feedback_RepararQuitaLimite"] = {
		Zona  = nil,
		Nivel = nil,

		Lineas = {
			{
				Id        = "inicio",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Normal",
				Texto     = "Reparar este nodo quitará el límite de grado y podrás conectar varios cables sin problema.",
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
	-- REPARACIÓN: mantiene el límite de grado
	-- ════════════════════════════════════════════════════════════════════
	["Feedback_RepararMantieneLimite"] = {
		Zona  = nil,
		Nivel = nil,

		Lineas = {
			{
				Id        = "inicio",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Reparar este nodo no quitará el límite, ya que es un nodo muy viejo y no soporta más conexiones de las permitidas.",
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
