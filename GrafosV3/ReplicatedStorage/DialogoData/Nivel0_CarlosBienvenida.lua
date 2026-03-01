-- ReplicatedStorage/DialogoData/Nivel0_CarlosBienvenida.lua
-- Diálogo de bienvenida de Carlos - Tutorial del Nivel 0

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Funciones auxiliares de eventos
local function toggleTecho(visible)
	local nivel = Workspace:FindFirstChild("NivelActual")
	if nivel then
		local techo = nivel:FindFirstChild("Techo", true)
		if techo then 
			techo.Transparency = visible and 0 or 1 
		end
	end
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
				
				Opciones = {
					{
						Numero = 1,
						Texto = "Sí, soy Tocino.",
						Color = Color3.fromRGB(0, 207, 255),
						Siguiente = "saludo_tocino"
					}
				},
				
				Siguiente = "bienvenida"
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
			
			-- 3. FUNDAMENTOS
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
			
			-- 4. ZONA 1 (Cámara se mueve aquí)
			{
				Id = "zona_1",
				Numero = 5,
				Actor = "Carlos",
				Expresion = "Serio",
				Texto = "Dirígete a la Zona 1. Allí comenzarás con los primeros conceptos: nodos y conexiones.",
				ImagenPersonaje = "rbxassetid://0",
				
				Evento = function(gui, metadata)
					print("[Evento] Mostrando Zona 1...")
					toggleTecho(false)
					
					-- Mover cámara a Zona 1
					local ControladorDialogo = _G.ControladorDialogo
					if ControladorDialogo and ControladorDialogo.moverCamara then
						ControladorDialogo.moverCamara("Nodo1_z1", 1.0)
					end
				end,
				
				Siguiente = "confirmacion_final"
			},
			
			-- 5. CONFIRMACIÓN FINAL
			{
				Id = "confirmacion_final",
				Numero = 6,
				Actor = "Carlos",
				Expresion = "Sonriente",
				Texto = "¡Confío en ti. Suerte!",
				ImagenPersonaje = "rbxassetid://0",
				
				Evento = function(gui, metadata)
					print("[Evento] Restaurando...")
					
					local ControladorDialogo = _G.ControladorDialogo
					if ControladorDialogo and ControladorDialogo.restaurarCamara then
						ControladorDialogo.restaurarCamara()
					end
					
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
		
		Configuracion = {
			bloquearMovimiento = true,
			bloquearSalto = true,
			bloquearCarrera = true,
			apuntarCamara = true,  -- Bloquea cámara pero NO la mueve automáticamente
			permitirConexiones = false
		}
	}
}

return DIALOGOS
