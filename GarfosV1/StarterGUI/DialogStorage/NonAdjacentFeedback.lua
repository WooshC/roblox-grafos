-- NonAdjacentFeedback.lua
-- Muestra un diálogo educativo cuando el jugador intenta conectar
-- dos nodos que NO son adyacentes según la configuración del nivel.
-- NOTA: errores de DIRECCIÓN en grafos dirigidos son manejados por DirectedFeedback.lua

local dialogueKitModule = require(script.Parent.Parent.DialogueKit)
local DialogueGenerator  = require(script.Parent.DialogueGenerator)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))

local DialogueVisibilityManager = require(
	ReplicatedStorage:WaitForChild("DialogueVisibilityManager", 5)
)

local SKIN_NAME = "Hotline"

-- ================================================================
-- HELPERS
-- ================================================================

-- Verificación de seguridad en el cliente: devuelve true si la conexión
-- nodo1→nodo2 falla porque existe la arista inversa nodo2→nodo1 en un dígrafo.
-- El servidor ya debería enviar DireccionInvalida en ese caso, pero esto
-- evita falsos positivos si hay alguna desincronización.
local function esDireccionInvalida(nodo1, nodo2)
	local cfg = LevelsConfig[0]  -- Nivel educativo (siempre nivel 0)
	if not cfg or not cfg.Adyacencias then return false end
	local ady = cfg.Adyacencias
	return ady[nodo2] and table.find(ady[nodo2], nodo1) ~= nil
end

-- Espera a que el kit no tenga ningún diálogo activo.
local function esperarKitLibre()
	while DialogueVisibilityManager:isActive() do
		task.wait(0.2)
	end
	task.wait(1.0)
end

-- Muestra el diálogo y luego restaura inmediatamente el movimiento
-- para que el jugador pueda caminar mientras lee.
local function mostrarFeedbackAdyacencia()
	task.spawn(function()
		esperarKitLibre()

		local data = {
			["NoAdyacente"] = {
				Actor     = "Sistema",
				Expresion = "Nodo",
				Texto     = {
					"Esos dos nodos no son adyacentes.",
					"En un grafo, solo puedes crear una arista entre nodos que sean vecinos definidos.",
					"Observa qué nodos están resaltados y elige solo entre ellos.",
				},
				Sonido    = {
					"rbxassetid://91232241403260",
					"rbxassetid://91232241403260",
					"rbxassetid://91232241403260",
				},
				Siguiente = "FIN",
			},
		}

		local layers = DialogueGenerator.GenerarEstructura(data, SKIN_NAME)
		dialogueKitModule.CreateDialogue({
			InitialLayer = "NoAdyacente",
			SkinName     = SKIN_NAME,
			Config       = script,
			Layers       = layers,
		})

		-- Restaurar movimiento del jugador inmediatamente después de mostrar el diálogo
		task.delay(0.15, function()
			local Players = game:GetService("Players")
			local char = Players.LocalPlayer.Character
			if char then
				local hum = char:FindFirstChildWhichIsA("Humanoid")
				if hum then
					local savedJump = hum:GetAttribute("_dlg_JumpHeight")
					hum.JumpHeight = savedJump or 7.2
					hum.WalkSpeed  = 16
				end
			end
		end)
	end)
end

-- ================================================================
-- LISTENER
-- ================================================================

task.spawn(function()
	local Remotes     = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes")
	local notifyEvent = Remotes:WaitForChild("NotificarSeleccionNodo", 30)

	if not notifyEvent then
		warn("❌ NonAdjacentFeedback: NotificarSeleccionNodo no encontrado (timeout)")
		return
	end

	notifyEvent.OnClientEvent:Connect(function(tipo, nodo1, nodo2)
		if tipo == "ConexionInvalida" then
			-- Seguridad cliente: no mostrar si en realidad es error de dirección en dígrafo
			-- (el servidor ya diferencia con DireccionInvalida, esto previene edge cases)
			if nodo1 and nodo2 and esDireccionInvalida(nodo1, nodo2) then
				return  -- DirectedFeedback.lua maneja este caso
			end
			mostrarFeedbackAdyacencia()
		end
	end)

	print("✅ NonAdjacentFeedback: escuchando ConexionInvalida")
end)
