-- StarterPlayerScripts/HUD/ModulosHUD/VictoriaHUD.lua
-- Maneja la pantalla de victoria y sus estadísticas finales

local VictoriaHUD = {}

local parentHud = nil

local victoriaFondo = nil
local victoriaStats = nil
local botonRepetir = nil
local botonContinuar = nil

local nivelIDActual = nil
local procesando = false

function VictoriaHUD.init(hudRef)
	parentHud = hudRef
	
	VictoriaHUD._buscarElementos()
	VictoriaHUD._conectarBotones()
end

function VictoriaHUD._buscarElementos()
	-- Navegar jerarquía exacta: VictoriaFondo → PantallaVictoria → ContenedorPrincipal
	victoriaFondo = parentHud:FindFirstChild("VictoriaFondo", true)
	
	local pantallaVictoria = victoriaFondo and victoriaFondo:FindFirstChild("PantallaVictoria")
	local contenedorPrincipal = pantallaVictoria and pantallaVictoria:FindFirstChild("ContenedorPrincipal")
	
	victoriaStats = contenedorPrincipal and contenedorPrincipal:FindFirstChild("EstadisticasFrame")
	local botonesFrame = contenedorPrincipal and contenedorPrincipal:FindFirstChild("BotonesFrame")
	
	botonRepetir = botonesFrame and botonesFrame:FindFirstChild("BotonRepetir")
	botonContinuar = botonesFrame and botonesFrame:FindFirstChild("BotonContinuar")

	-- Fallbacks recursivos si la jerarquía es diferente
	if not victoriaStats then
		victoriaStats = parentHud:FindFirstChild("EstadisticasFrame", true)
	end
	if not botonRepetir then
		botonRepetir = parentHud:FindFirstChild("BotonRepetir", true)
	end
	if not botonContinuar then
		botonContinuar = parentHud:FindFirstChild("BotonContinuar", true)
	end
	
	-- Diagnóstico
	print("[VictoriaHUD] victoriaFondo:", victoriaFondo and "✅" or "❌")
	print("[VictoriaHUD] victoriaStats:", victoriaStats and "✅" or "❌")
	print("[VictoriaHUD] botonRepetir:", botonRepetir and "✅" or "❌")
	print("[VictoriaHUD] botonContinuar:", botonContinuar and "✅" or "❌")
end

function VictoriaHUD._conectarBotones()
	if botonRepetir then
		botonRepetir.MouseButton1Click:Connect(VictoriaHUD._hacerReinicio)
	end
	if botonContinuar then
		botonContinuar.MouseButton1Click:Connect(VictoriaHUD._hacerVolverAlMenu)
	end
end

function VictoriaHUD._hacerReinicio()
	if procesando or not nivelIDActual then return end
	procesando = true
	
	VictoriaHUD.ocultar()
	
	-- Fade a negro y reiniciar
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local eventos = ReplicatedStorage:WaitForChild("EventosGrafosV3")
	local remotos = eventos:WaitForChild("Remotos")
	local reiniciarEvento = remotos:WaitForChild("ReiniciarNivel")
	
	if reiniciarEvento then
		reiniciarEvento:FireServer(nivelIDActual)
	end
	
	procesando = false
	print("[VictoriaHUD] ReiniciarNivel enviado →", nivelIDActual)
end

function VictoriaHUD._hacerVolverAlMenu()
	if procesando then return end
	procesando = true
	
	VictoriaHUD.ocultar()
	
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local eventos = ReplicatedStorage:WaitForChild("EventosGrafosV3")
	local remotos = eventos:WaitForChild("Remotos")
	local volverEvento = remotos:WaitForChild("VolverAlMenu")
	
	if volverEvento then
		volverEvento:FireServer()
	end
	
	procesando = false
end

function VictoriaHUD.ocultar()
	if victoriaFondo then
		victoriaFondo.Visible = false
	end
	nivelIDActual = nil
end

function VictoriaHUD.mostrar(snapshotVictoria)
	if not victoriaFondo then
		warn("[VictoriaHUD] ❌ VictoriaFondo no encontrado")
		return
	end

	if victoriaStats and snapshotVictoria then
		-- Guardar nivelID para posible restart
		nivelIDActual = snapshotVictoria.nivelID or snapshotVictoria.nivelId
		
		-- Fallback: obtener del atributo del jugador
		if not nivelIDActual then
			local jugador = game:GetService("Players").LocalPlayer
			nivelIDActual = jugador:GetAttribute("CurrentLevelID")
		end

		local function fijarValorStat(nombreFila, valor)
			local statRow = victoriaStats:FindFirstChild(nombreFila)
			if not statRow then
				warn("[VictoriaHUD] ⚠ Fila no encontrada:", nombreFila)
				return
			end
			
			-- Buscar "Val" primero (nombre en GUIExploradorV2), fallback a "Valor"
			local valueLabel = statRow:FindFirstChild("Val") or statRow:FindFirstChild("Valor")
			if not valueLabel then
				warn("[VictoriaHUD] ⚠ No se encontró 'Val' ni 'Valor' en:", nombreFila)
				return
			end
			
			valueLabel.Text = tostring(valor)
		end

		local tiempoSegundos = snapshotVictoria.tiempo or 0
		fijarValorStat("FilaTiempo", string.format("%d:%02d", math.floor(tiempoSegundos / 60), tiempoSegundos % 60))
		
		-- Cambiar label de "Aciertos" a "Conexiones"
			local filaAciertos = victoriaStats:FindFirstChild("FilaAciertos")
			if filaAciertos then
				local labelKey = filaAciertos:FindFirstChild("K")
				if labelKey and labelKey:IsA("TextLabel") then
					labelKey.Text = "Conexiones"
				end
			end
			fijarValorStat("FilaAciertos", tostring(snapshotVictoria.aciertos or snapshotVictoria.conexiones or 0))
		fijarValorStat("FilaErrores", tostring(snapshotVictoria.fallos or 0))
		fijarValorStat("FilaPuntaje", tostring(snapshotVictoria.puntajeBase or 0))
	else
		if not victoriaStats then
			warn("[VictoriaHUD] ❌ victoriaStats no encontrado")
		end
		if not snapshotVictoria then
			warn("[VictoriaHUD] ❌ snapshotVictoria es nil")
		end
	end

	victoriaFondo.Visible = true
end

return VictoriaHUD
