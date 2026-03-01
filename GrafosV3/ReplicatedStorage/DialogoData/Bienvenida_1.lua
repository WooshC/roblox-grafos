-- ReplicatedStorage/DialogoData/Bienvenida_1.lua
-- Diálogo de bienvenida de Carlos - Tutorial del Nivel 0
-- Adaptado del sistema antiguo al nuevo sistema de diálogos

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

		Lineas = {
			-- 1. INTRODUCCIÓN
			{
				Id = "bienvenida",
				Numero = 1,
				Actor = "Carlos",
				Expresion = "Sonriente",
				Texto = "Hola. Tú debes ser Tocino, ¿verdad?",
				ImagenPersonaje = "rbxassetid://0",

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
				Numero = 2,
				Actor = "Carlos",
				Expresion = "Presentacion",
				Texto = "Qué bien que hayas venido. Necesitamos formar a alguien que entienda cómo funcionan las redes.",
				ImagenPersonaje = "rbxassetid://0",
				Siguiente = "fundamentos"
			},

			-- 3. FUNDAMENTOS (Línea larga dividida)
			{
				Id = "fundamentos",
				Numero = 3,
				Actor = "Carlos",
				Expresion = "Serio",
				Texto = "Antes de resolver cualquier problema real, debes aprender los fundamentos básicos de los grafos.",
				ImagenPersonaje = "rbxassetid://0",
				Siguiente = "fundamentos_2"
			},

			{
				Id = "fundamentos_2",
				Numero = 4,
				Actor = "Carlos",
				Expresion = "Serio",
				Texto = "Sin comprender la estructura, no podrás analizar ninguna red.",
				ImagenPersonaje = "rbxassetid://0",
				Siguiente = "zona_1"
			},

			-- 4. ZONA 1 (Con efectos visuales - CÁMARA SE MUEVE AQUÍ)
			{
				Id = "zona_1",
				Numero = 5,
				Actor = "Carlos",
				Expresion = "Serio",
				Texto = "Dirígete a la Zona 1. Allí comenzarás con los primeros conceptos: nodos y conexiones.",
				ImagenPersonaje = "rbxassetid://0",

				-- Este evento se ejecuta cuando se muestra esta línea
				Evento = function(gui, metadata)
					print("[Evento] Mostrando Zona 1...")

					-- Ocultar techo para ver la zona
					toggleTecho(false)

					-- Mover cámara a Zona 1 (TOP-DOWN)
					-- Usar el ControladorDialogo global
					local ControladorDialogo = _G.ControladorDialogo
					if ControladorDialogo and ControladorDialogo.moverCamara then
						ControladorDialogo.moverCamara("Nodo1_z1", 1.0) -- 1 segundo de transición
					else
						warn("[Evento] ControladorDialogo no disponible")
					end
				end,

				Siguiente = "confirmacion_final"
			},

			-- 5. CONFIRMACIÓN FINAL (Con desbloqueo)
			{
				Id = "confirmacion_final",
				Numero = 6,
				Actor = "Carlos",
				Expresion = "Sonriente",
				Texto = "¡Confío en ti. Suerte!",
				ImagenPersonaje = "rbxassetid://0",

				Evento = function(gui, metadata)
					print("[Evento] Restaurando...")

					-- Restaurar cámara al jugador
					local ControladorDialogo = _G.ControladorDialogo
					if ControladorDialogo and ControladorDialogo.restaurarCamara then
						ControladorDialogo.restaurarCamara()
					end

					-- Mostrar techo nuevamente
					toggleTecho(true)
				end,

				Siguiente = "FIN"
			}
		},

		Metadata = {
			TiempoDeEspera = 0.5,
			VelocidadTypewriter = 0.03,
			PuedeOmitir = true,
			OcultarHUD = true,
			UsarTTS = true
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
			-- Usar ControladorDialogo.moverCamara() en los Eventos de las líneas
			apuntarCamara = true,         -- Bloquea la cámara (Scriptable) pero no la mueve

			-- PERMISOS ESPECIALES
			permitirConexiones = false    -- Si true, el jugador puede conectar cables durante el diálogo
		}
	}
}

return DIALOGOS
