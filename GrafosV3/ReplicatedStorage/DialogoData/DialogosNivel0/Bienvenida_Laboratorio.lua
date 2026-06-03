-- ReplicatedStorage/DialogoData/DialogosNivel0/Bienvenida_Laboratorio.lua
-- Diálogo inicial del Nivel 0: bienvenida + controles básicos + tutorial HUD + guía hacia Carlos
-- Se lanza automáticamente desde ControladorHUD.client.lua al cargar el nivel

local Workspace = game:GetService("Workspace")

local DIALOGOS = {

	["Bienvenida_Laboratorio"] = {
		Zona  = "Tutorial",
		Nivel = 0,

		Lineas = {
			-- 1. Bienvenida
			{
				Id        = "bienvenida",
				Numero    = 1,
				Actor     = "Sistema",
				Expresion = "Normal",
				Texto     = "¡Bienvenido al Laboratorio de Grafos! Soy tu asistente virtual.",
				Siguiente = "controles",
			},
			-- 2. Controles básicos (al inicio, para que el jugador sepa cómo avanzar)
			{
				Id        = "controles",
				Numero    = 2,
				Actor     = "Sistema",
				Expresion = "Normal",
				Texto     = "Presiona la barra espaciadora para continuar los diálogos. Presiona la tecla M para abrir el mapa en cualquier momento.",
				Siguiente = "explicacion",
			},
			-- 3. Qué aprenderá
			{
				Id        = "explicacion",
				Numero    = 3,
				Actor     = "Sistema",
				Expresion = "Normal",
				Texto     = "Aquí aprenderás los fundamentos de la teoría de grafos: nodos, aristas, conectividad y mucho más.",
				Siguiente = "hud_misiones",
			},
			-- 4. Tutorial: Misiones
			{
				Id        = "hud_misiones",
				Numero    = 4,
				Actor     = "Sistema",
				Expresion = "Normal",
				Texto     = "Presiona el botón de Misiones para ver tus objetivos. Completa cada misión para avanzar a la siguiente zona.",

				DestacarBoton = {
					nombre         = "BtnMisiones",
					escala         = 1.3,
					duracion       = 0.4,
					animacion      = "pulse",
					flecha         = true,
					punteroDesde   = "dialogo",
					punteroEstilo  = "flecha",
					textoAyuda     = "Click para ver misiones",
					oscurecerFondo = true,
					alTerminar     = "restaurar",
				},

				Siguiente = "hud_minimapa",
			},
			-- 5. Tutorial: Minimapa
			{
				Id        = "hud_minimapa",
				Numero    = 5,
				Actor     = "Sistema",
				Expresion = "Normal",
				Texto     = "En la esquina inferior izquierda verás el minimapa. Te ayuda a orientarte dentro del nivel.",
				Siguiente = "hud_guia",
			},
			-- 6. Tutorial: Flecha de guía
			{
				Id        = "hud_guia",
				Numero    = 6,
				Actor     = "Sistema",
				Expresion = "Normal",
				Texto     = "Sigue la flecha amarilla que sale de tu personaje. Te indicará el camino hacia tu próximo objetivo.",
				Siguiente = "mostrar_carlos",
			},
			-- 7. Enfocar cámara en Carlos
			{
				Id        = "mostrar_carlos",
				Numero    = 7,
				Actor     = "Sistema",
				Expresion = "Normal",
				Texto     = "Carlos es tu instructor. Te espera cerca de la entrada.",

				Evento = function(gui, metadata)
					local nivelActual = Workspace:FindFirstChild("NivelActual")
					local objetivoCarlos = nil
					if nivelActual then
						objetivoCarlos = nivelActual:FindFirstChild("Objetivo_Carlos", true)
					end

					if objetivoCarlos then
						_G.ControladorDialogo.moverCamara(objetivoCarlos, {
							altura   = 18,
							angulo   = 55,
							duracion = 1.2,
						})
					end
				end,

				Siguiente = "instruccion_final",
			},
			-- 8. Instrucción final + activar guía
			{
				Id        = "instruccion_final",
				Numero    = 8,
				Actor     = "Sistema",
				Expresion = "Normal",
				Texto     = "Ve a hablar con él para comenzar tu entrenamiento. ¡Suerte!",

				Evento = function(gui, metadata)
					_G.ControladorDialogo.restaurarCamara(0.6)

					local GuiaService = _G.GuiaService
					if GuiaService then
						GuiaService.GuiaAvanzar:Fire("carlos")
					else
						warn("[Evento] GuiaService no disponible")
					end
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
			DelayTTS            = 0.15,
		},

		Configuracion = {
			bloquearMovimiento = true,
			bloquearSalto      = true,
			bloquearCarrera    = true,
			apuntarCamara      = true,
			permitirConexiones = false,
		},
	},
}

return DIALOGOS
