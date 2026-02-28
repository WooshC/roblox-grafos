-- ReplicatedStorage/DialogoData/Nivel0_CarlosBienvenida.lua
-- Diálogo de bienvenida de Carlos - Tutorial del Nivel 0
-- Adaptado del sistema antiguo al nuevo sistema de diálogos

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Referencias a servicios externos (si existen)
local VisualEffectsService = nil
-- local desbloquearZona = nil  -- COMENTADO: No existe en este proyecto

-- Cargar servicios opcionales
local function cargarServicios()
	local StarterPlayerScripts = game:GetService("StarterPlayer").StarterPlayerScripts
	local exito, resultado = pcall(function()
		return require(StarterPlayerScripts.Cliente.Services.VisualEffectsService)
	end)
	if exito then VisualEffectsService = resultado end
	
	-- COMENTADO: DesbloquearZona no existe en este proyecto
	-- exito, resultado = pcall(function()
	-- 	return require(ReplicatedStorage:WaitForChild("DesbloquearZona"))
	-- end)
	-- if exito then desbloquearZona = resultado end
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

local function focusCameraOn(nombreNodo, offset)
	if VisualEffectsService and VisualEffectsService.focusCameraOn then
		local nivel = Workspace:FindFirstChild("NivelActual")
		if nivel then
			local nodo = nivel:FindFirstChild(nombreNodo, true)
			if nodo then
				VisualEffectsService:focusCameraOn(nodo, offset)
			end
		end
	end
end

local function restoreCamera()
	if VisualEffectsService and VisualEffectsService.restoreCamera then
		VisualEffectsService:restoreCamera()
	else
		-- Fallback: restaurar cámara normal
		local camara = Workspace.CurrentCamera
		camara.CameraType = Enum.CameraType.Custom
	end
end

--[[ COMENTADO: Función de desbloqueo de zona
-- Solo se usa si existe el módulo DesbloquearZona
local function desbloquear(nombreZona)
	if desbloquearZona then
		desbloquearZona(nombreZona)
	else
		-- Fallback: destruir partes con ese nombre
		local nivel = Workspace:FindFirstChild("NivelActual")
		if nivel then
			local bloqueo = nivel:FindFirstChild(nombreZona, true)
			if bloqueo then bloqueo:Destroy() end
		end
	end
	
	-- También disparar evento GuiaAvanzar si existe
	task.spawn(function()
		local events = ReplicatedStorage:FindFirstChild("Events")
		if events then
			local bindables = events:FindFirstChild("Bindables")
			if bindables then
				local guia = bindables:FindFirstChild("GuiaAvanzar")
				if guia then
					guia:Fire("carlos")
				end
			end
		end
	end)
end
]]

-- Función placeholder (no hace nada, para evitar errores)
local function desbloquear(nombreZona)
	print("[Diálogo] Desbloquear zona:", nombreZona, "(función desactivada)")
end

local DIALOGOS = {
	
	["Nivel0_CarlosBienvenida"] = {
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
			
			-- 4. ZONA 1 (Con efectos visuales)
			{
				Id = "zona_1",
				Numero = 5,
				Actor = "Carlos",
				Expresion = "Serio",
				Texto = "Dirígete a la Zona 1. Allí comenzarás con los primeros conceptos: nodos y conexiones.",
				ImagenPersonaje = "rbxassetid://0",
				
				Evento = function(gui, metadata)
					print("[Evento] Mostrando Zona 1...")
					-- Ocultar techo
					toggleTecho(false)
					-- Apuntar cámara a Zona 1
					focusCameraOn("Nodo1_z1", Vector3.new(20, 25, 20))
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
					print("[Evento] Desbloqueando zona...")
					-- Restaurar cámara
					restoreCamera()
					-- Mostrar techo
					toggleTecho(true)
					-- Desbloquear zona
					desbloquear("Bloqueo_zona_1")
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
		-- CONFIGURACIÓN DE RESTRICCIONES (Opcional)
		-- ═══════════════════════════════════════════════════════════════
		-- Aquí defines el comportamiento del diálogo
		-- Se puede activar por: ProximityPrompt, Misión, Zona, o código
		Configuracion = {
			-- BLOQUEO DE CONTROLES
			bloquearMovimiento = true,    -- El jugador no puede moverse (WASD)
			bloquearSalto = true,         -- El jugador no puede saltar (Espacio)
			bloquearCarrera = true,       -- El jugador no puede correr (Shift)
			
			-- CONTROL DE CÁMARA
			apuntarCamara = true,         -- La cámara mira al punto de enfoque
			
			-- ENFOQUE DE CÁMARA (dónde mira)
			-- Opciones:
			--   nil                = Usa el promptPart (si existe)
			--   "NombreNodo"       = Nombre de un nodo en el nivel
			--   Vector3.new(x,y,z) = Posición específica
			enfoqueCamara = "Nodo1_z1",   -- En este ejemplo, mira al nodo de la Zona 1
			
			-- PERMISOS ESPECIALES
			permitirConexiones = false    -- Si true, el jugador puede conectar cables durante el diálogo
			                              -- Útil para tutoriales guiados
		}
	}
}

return DIALOGOS
