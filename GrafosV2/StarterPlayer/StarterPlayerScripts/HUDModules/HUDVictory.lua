-- HUDVictory.lua
-- Maneja la pantalla de victoria y sus estadísticas finales
-- Uso: local HUDVictory = require(HUDModules.HUDVictory)

local HUDVictory = {}

local parentHud = nil
local fadeModule = nil

local victoriaFondo = nil
local victoriaStats = nil
local botonRepetir = nil
local botonContinuar = nil

local nivelIDActual = nil
local isProcessing = false

function HUDVictory.init(hudRef, fadeRef)
	parentHud = hudRef
	fadeModule = fadeRef
	
	HUDVictory._findVictoryElements()
	HUDVictory._connectButtons()
	
	-- Diagnóstico
	print("[HUDVictory] victoriaFondo:", victoriaFondo and "✅" or "❌")
	print("[HUDVictory] victoriaStats:", victoriaStats and "✅" or "❌")
	print("[HUDVictory] botonRepetir:", botonRepetir and "✅" or "❌")
	print("[HUDVictory] botonContinuar:", botonContinuar and "✅" or "❌")
end

function HUDVictory._findVictoryElements()
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
end

function HUDVictory._connectButtons()
	if botonRepetir then
		botonRepetir.MouseButton1Click:Connect(HUDVictory._doRestart)
	end
	if botonContinuar then
		botonContinuar.MouseButton1Click:Connect(HUDVictory._doReturnToMenu)
	end
end

function HUDVictory._doRestart()
	if isProcessing or not nivelIDActual then return end
	isProcessing = true
	
	HUDVictory.hide()
	
	fadeModule.fadeToBlack(0.3, function()
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local restartLevelEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes"):WaitForChild("RestartLevel")
		if restartLevelEvent then
			restartLevelEvent:FireServer(nivelIDActual)
		end
		
		fadeModule.reset()
		isProcessing = false
		print("[HUDVictory] RestartLevel enviado →", nivelIDActual)
	end)
end

function HUDVictory._doReturnToMenu()
	if isProcessing then return end
	isProcessing = true
	
	HUDVictory.hide()
	
	fadeModule.fadeToBlack(0.4, function()
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local returnToMenuEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes"):WaitForChild("ReturnToMenu")
		if returnToMenuEvent then
			returnToMenuEvent:FireServer()
		end
		
		fadeModule.reset()
		isProcessing = false
	end)
end

function HUDVictory.hide()
	if victoriaFondo then
		victoriaFondo.Visible = false
	end
	nivelIDActual = nil
end

function HUDVictory.show(victorySnapshot)
	if not victoriaFondo then
		warn("[HUDVictory] ❌ VictoriaFondo no encontrado")
		return
	end

	if victoriaStats and victorySnapshot then
		-- Guardar nivelID para posible restart
		nivelIDActual = victorySnapshot.nivelID

		local function setStatValue(statRowName, value)
			local statRow = victoriaStats:FindFirstChild(statRowName)
			if not statRow then
				warn("[HUDVictory] ⚠ Fila no encontrada:", statRowName)
				return
			end
			
			-- BUG FIX: buscar "Val" primero (nombre en GUIExploradorV2), fallback a "Valor"
			local valueLabel = statRow:FindFirstChild("Val") or statRow:FindFirstChild("Valor")
			if not valueLabel then
				warn("[HUDVictory] ⚠ No se encontró 'Val' ni 'Valor' en:", statRowName)
				-- Debug: listar hijos
				for _, child in ipairs(statRow:GetChildren()) do
					print("  Hijo en", statRowName, "→", child.Name, "/", child.ClassName)
				end
				return
			end
			
			valueLabel.Text = tostring(value)
		end

		local tiempoSegundos = victorySnapshot.tiempo or 0
		setStatValue("FilaTiempo", string.format("%d:%02d", math.floor(tiempoSegundos / 60), tiempoSegundos % 60))
		
		-- BUG FIX: usar victorySnapshot.aciertos (aciertosTotal histórico), no victorySnapshot.conexiones
		setStatValue("FilaAciertos", tostring(victorySnapshot.aciertos or victorySnapshot.conexiones or 0))
		setStatValue("FilaErrores", tostring(victorySnapshot.fallos or 0))
		setStatValue("FilaPuntaje", tostring(victorySnapshot.puntajeBase or 0))
	else
		if not victoriaStats then
			warn("[HUDVictory] ❌ victoriaStats no encontrado")
		end
		if not victorySnapshot then
			warn("[HUDVictory] ❌ victorySnapshot es nil")
		end
	end

	victoriaFondo.Visible = true
	
	print(string.format("[HUDVictory] 🏆 Victoria | aciertos=%s fallos=%s puntaje=%s tiempo=%s",
		tostring(victorySnapshot and (victorySnapshot.aciertos or victorySnapshot.conexiones) or "?"),
		tostring(victorySnapshot and victorySnapshot.fallos or "?"),
		tostring(victorySnapshot and victorySnapshot.puntajeBase or "?"),
		tostring(victorySnapshot and victorySnapshot.tiempo or "?")))
end

return HUDVictory
