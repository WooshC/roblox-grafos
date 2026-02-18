-- NonAdjacentFeedback.lua
-- Muestra un diálogo educativo cuando el jugador intenta conectar
-- dos nodos que NO son adyacentes según la configuración del nivel.
-- Funciona en cualquier zona. Permite movimiento durante el diálogo.

local dialogueKitModule = require(script.Parent.Parent.DialogueKit)
local DialogueGenerator  = require(script.Parent.DialogueGenerator)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DialogueVisibilityManager = require(
	ReplicatedStorage:WaitForChild("DialogueVisibilityManager", 5)
)

local SKIN_NAME = "Hotline"

-- ================================================================
-- HELPERS
-- ================================================================

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
		-- (el kit bloquea el salto via DialogueVisibilityManager, lo revertimos aquí)
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

	notifyEvent.OnClientEvent:Connect(function(tipo)
		if tipo == "ConexionInvalida" then
			mostrarFeedbackAdyacencia()
		end
	end)

	print("✅ NonAdjacentFeedback: escuchando ConexionInvalida")
end)
