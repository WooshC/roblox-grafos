-- ReplicatedStorage/DialogoData/Bienvenida_1.lua
-- Diálogo de bienvenida de Carlos - Tutorial del Nivel 0
-- Adaptado del sistema antiguo al nuevo sistema de diálogos
-- NARRATIVA: Se introduce la corrupción del alcalde y la misión de descubrir la verdad.

local Workspace = game:GetService("Workspace")

-- Referencias a servicios externos (si existen)
local VisualEffectsService = nil

-- Cargar servicios opcionales
local function cargarServicios()
	local StarterPlayerScripts = game:GetService("StarterPlayer").StarterPlayerScripts
	local exito, resultado = pcall(function()
		return require(StarterPlayerScripts.Cliente.Services.VisualEffectsService)
	end)
	if exito then VisualEffectsService = resultado end
end

-- Ejecutar carga asíncrona
task.spawn(cargarServicios)

-- Funciones auxiliares de eventos
local function toggleTecho(visible)
	if VisualEffectsService and VisualEffectsService.toggleTecho then
		VisualEffectsService:toggleTecho(visible)
	else
		-- Fallback: buscar techo en el nivel
		local nivel = Workspace:FindFirstChild("NivelActual")
		if nivel then
			local techo = nivel:FindFirstChild("Techo", true)
			if techo then techo.Transparency = visible and 0 or 1 end
		end
	end
end

local DIALOGOS = {

	["Bienvenida_1"] = {
		Zona = "Tutorial",
		Nivel = 0,

		-- Se ejecuta tanto al terminar normalmente como al hacer skip
		EventoSalida = function()
			print("[EventoSalida] Bienvenida_1 finalizado")

			-- Avanzar guía si aún no se ha avanzado (evita duplicados gracias a GuiaService)
			local GuiaService = _G.GuiaService
			if GuiaService and GuiaService.GuiaAvanzar then
				GuiaService.GuiaAvanzar:Fire("carlos")
			else
				warn("[EventoSalida] GuiaService no disponible")
			end

			-- Eliminar bloqueo configurado para este diálogo
			if _G.GestorBloqueos then
				_G.GestorBloqueos:eliminarPorDialogo("Bienvenida_1")
			else
				warn("[EventoSalida] GestorBloqueos no disponible")
			end

			-- Restaurar cámara y techo por seguridad
			if _G.ControladorDialogo and _G.ControladorDialogo.restaurarCamara then
				_G.ControladorDialogo.restaurarCamara(0.5)
			end
			toggleTecho(true)
		end,

		Lineas = {
			-- 1. INTRODUCCIÓN
			{
				Id = "bienvenida",
				Numero = 1,
				Actor = "Carlos",
				Expresion = "Sonriente",
				Texto = "Hola. Tú debes ser Tocino, ¿verdad?",

				-- Opción de respuesta
				Opciones = {
					{
						Numero = 1,
						Texto = "Sí, soy Tocino.",
						Color = Color3.fromRGB(0, 207, 255),
						Siguiente = "saludo_tocino"
					}
				},

				Siguiente = "bienvenida" -- Loop hasta que seleccione opción
			},

			-- 2. SALUDO
			{
				Id = "saludo_tocino",
				Numero = 3,
				Actor = "Carlos",
				Expresion = "Presentacion",
				Texto = "Qué bien que hayas venido. Necesitamos formar a alguien que entienda cómo funcionan las redes de verdad.",
				Siguiente = "contexto_alcalde"
			},

			-- 3. CONTEXTO: EL ALCALDE Y LA CORRUPCIÓN
			{
				Id = "contexto_alcalde",
				Numero = 4,
				Actor = "Carlos",
				Expresion = "Serio",
				Texto = "Villa Conexa está hecha un desastre. El alcalde aprobó proyectos mal planificados durante años, favoreciendo contratos costosos que solo empeoraron el caos.",
				Siguiente = "contexto_contratos"
			},

			{
				Id = "contexto_contratos",
				Numero = 5,
				Actor = "Carlos",
				Expresion = "Serio",
				Texto = "Dicen que gastaron millones en cableado 'de primera', pero si miras bien verás postes sobrecargados, cables mal tendidos y rutas que no llevan a ninguna parte. Eso huele a dinero mal invertido.",
				Siguiente = "carlos_intro_alcalde"
			},

			-- 4b. CARLOS INTRODUCE LO QUE DIJO EL ALCALDE
			{
				Id = "carlos_intro_alcalde",
				Numero = 6,
				Actor = "Carlos",
				Expresion = "Serio",
				Texto = "El alcalde me llamó personalmente. Esto es más o menos lo que dijo...",
				Siguiente = "alcalde_dice_1"
			},
			{
				Id = "alcalde_dice_1",
				Numero = 7,
				Actor = "Alcalde",
				Expresion = "Codicioso",
				Texto = "Veo que ustedes son una empresa eléctrica nueva... y bastante económica. Me interesa contratarlos para unos 'ajustes' en la red. Claro, el presupuesto oficial ya está comprometido, así que espero que su propuesta sea... competitiva.",
				Siguiente = "alcalde_dice_2"
			},
			{
				Id = "alcalde_dice_2",
				Numero = 8,
				Actor = "Alcalde",
				Expresion = "Enojado",
				Texto = "Hay muchos opositores que están saboteando mi arduo trabajo y quiero que ustedes arreglen unos cables. No creo que cueste mucho, ¿cierto? Solo sigan mis indicaciones y no se metan donde no les importa.",
				Siguiente = "alcalde_dice_3"
			},
			{
				Id = "alcalde_dice_3",
				Numero = 9,
				Actor = "Alcalde",
				Expresion = "Malevolo",
				Texto = "Estaré en contacto. Les enviaré una factura por los 'materiales administrativos' y otros gastos de gestión. Son cosas normales en cualquier obra pública... muy normales.",
				Siguiente = "carlos_resume_alcalde"
			},
			{
				Id = "carlos_resume_alcalde",
				Numero = 10,
				Actor = "Carlos",
				Expresion = "Serio",
				Texto = "Y eso es lo que dijo el alcalde. No lo dijo directamente, pero escuché claramente: quiere trabajo barato, facturas sin explicación y, sobre todo, que nadie revise los números.",
				Siguiente = "mision_descubrir"
			},

			-- 4c. MISIÓN: DESCUBRIR LA VERDAD
			{
				Id = "mision_descubrir",
				Numero = 11,
				Actor = "Carlos",
				Expresion = "Serio",
				Texto = "Mi empresa, Redes y Caminos, fue contratada para arreglar esto. Pero no solo vamos a conectar cables: cada nodo que organices correctamente nos acerca a la verdad de esos contratos inflados.",
				Siguiente = "fundamentos"
			},

			-- 5. FUNDAMENTOS (Línea larga dividida)
			{
				Id = "fundamentos",
				Numero = 12,
				Actor = "Carlos",
				Expresion = "Serio",
				Texto = "Antes de salir a las calles caóticas, debes aprender los fundamentos de los grafos. Sin comprender la estructura, no podrás distinguir una conexión útil de un cable mal tendido.",
				Siguiente = "fundamentos_2"
			},

			{
				Id = "fundamentos_2",
				Numero = 13,
				Actor = "Carlos",
				Expresion = "Serio",
				Texto = "En este laboratorio seguro aprenderás a identificar nodos, aristas, direcciones y conectividad. Esa es tu herramienta para desenmascarar el desorden del alcalde.",
				Siguiente = "zona_1"
			},

			-- 6. ZONA 1 (Con efectos visuales - CÁMARA SE MUEVE AQUÍ)
			{
				Id = "zona_1",
				Numero = 14,
				Actor = "Sistema",
				Expresion = "Procesando",
				Texto = "Dirígete a la Zona 1. Allí comenzarás con los primeros conceptos: nodos y conexiones. Recuerda: no basta con conectar, hay que conectar con sentido.",

				-- Este evento se ejecuta cuando se muestra esta línea
				Evento = function(gui, metadata)
					print("[Evento] Mostrando Zona 1...")

					-- Avanzar guía: carlos → estacion_1
					-- El beacon y billboard de ZonaTrigger_Estacion1 aparecen aquí
					local GuiaService = _G.GuiaService
					if GuiaService then
						GuiaService.GuiaAvanzar:Fire("carlos")
					else
						warn("[Evento] GuiaService no disponible")
					end

					-- Ocultar techo para ver la zona
					toggleTecho(false)

					-- Mover cámara hacia Zona 1 (inclinada, apuntando a Nodo1_z1)
					_G.ControladorDialogo.moverCamara("Nodo1_z1", {
						altura   = 25,   -- altura sobre el nodo
						angulo   = 65,   -- 65°: no del todo cenital, algo de perspectiva
						duracion = 1.0,
					})
				end,

				Siguiente = "confirmacion_final"
			},

			-- 7. CONFIRMACIÓN FINAL
			{
				Id = "confirmacion_final",
				Numero = 15,
				Actor = "Carlos",
				Expresion = "Sonriente",
				Texto = "¡Confío en ti. Aprende bien, porque cada conexión correcta será una prueba contra el caos!",

				Evento = function(gui, metadata)
					print("[Evento] Restaurando...")

					-- Restaurar cámara al jugador
					_G.ControladorDialogo.restaurarCamara(0.5)

					-- Mostrar techo nuevamente
					toggleTecho(true)

					-- Eliminar bloqueo configurado para este dialogo (ejemplo)
					if _G.GestorBloqueos then
						_G.GestorBloqueos:eliminarPorDialogo("Bienvenida_1")
					end
				end,

				Siguiente = "FIN"
			},

		},

		Metadata = {
			TiempoDeEspera = 0.5,
			VelocidadTypewriter = 0.03,
			PuedeOmitir = true,
			OcultarHUD = true,
			UsarTTS = true,
			DelayTTS = 0.15,    -- Segundos que el typewriter espera tras iniciar TTS
		},

		-- ═══════════════════════════════════════════════════════════════
		-- CONFIGURACIÓN DE RESTRICCIONES
		-- ═══════════════════════════════════════════════════════════════
		Configuracion = {
			-- BLOQUEO DE CONTROLES
			bloquearMovimiento = true,    -- El jugador no puede moverse (WASD)
			bloquearSalto = true,         -- El jugador no puede saltar (Espacio)
			bloquearCarrera = true,       -- El jugador no puede correr (Shift)

			-- CONTROL DE CÁMARA
			-- NOTA: La cámara NO se mueve automáticamente al inicio.
			-- Usar _G.ControladorDialogo.moverCamara() en los Eventos de las líneas.
			apuntarCamara = true,         -- Bloquea la cámara (Scriptable) pero no la mueve

			-- PERMISOS ESPECIALES
			permitirConexiones = false    -- Si true, el jugador puede conectar cables durante el diálogo
		}
	}
}

return DIALOGOS
