-- StarterGUI/DialogStorage/DirectedFeedback.lua
-- Muestra un diálogo educativo cuando el jugador intenta conectar dos nodos
-- en la dirección INCORRECTA dentro de un grafo dirigido.
-- Ejemplo: intenta Y→X cuando la arista válida es X→Y.
-- El servidor detecta el caso y envía el evento "DireccionInvalida".

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

local function getAlias(nodeName)
	local cfg = LevelsConfig[0]
	if cfg and cfg.Nodos and cfg.Nodos[nodeName] then
		return cfg.Nodos[nodeName].Alias or nodeName
	end
	return nodeName
end

local function esperarKitLibre()
	while DialogueVisibilityManager:isActive() do
		task.wait(0.2)
	end
	task.wait(1.0)
end

-- ================================================================
-- DIÁLOGO
-- ================================================================

-- poste1Name = primer nodo clicado (origen intentado, INCORRECTO)
-- poste2Name = segundo nodo clicado (destino intentado, INCORRECTO)
-- La dirección VÁLIDA es poste2 → poste1 (sentido contrario al intento)
local function mostrarFeedbackDireccion(poste1Name, poste2Name)
	task.spawn(function()
		esperarKitLibre()

		local aliasIntento  = getAlias(poste1Name) .. " → " .. getAlias(poste2Name)
		local aliasCorrecta = getAlias(poste2Name) .. " → " .. getAlias(poste1Name)

		local data = {
			["DireccionInvalida"] = {
				Actor     = "Sistema",
				Expresion = "Nodo",
				Texto     = {
					"¡Dirección incorrecta en un grafo DIRIGIDO!",
					"Intentaste: " .. aliasIntento,
					"La flecha válida es: " .. aliasCorrecta,
					"En un dígrafo, el orden en que haces clic importa: primero el ORIGEN, luego el DESTINO.",
				},
				Sonido    = {
					"rbxassetid://91232241403260",
					"rbxassetid://91232241403260",
					"rbxassetid://91232241403260",
					"rbxassetid://91232241403260",
				},
				Siguiente = "FIN",
			},
		}

		local layers = DialogueGenerator.GenerarEstructura(data, SKIN_NAME)
		dialogueKitModule.CreateDialogue({
			InitialLayer = "DireccionInvalida",
			SkinName     = SKIN_NAME,
			Config       = script,
			Layers       = layers,
		})

		-- Restaurar movimiento del jugador (mismo patrón que NonAdjacentFeedback)
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
		warn("❌ DirectedFeedback: NotificarSeleccionNodo no encontrado (timeout)")
		return
	end

	notifyEvent.OnClientEvent:Connect(function(tipo, nodo1, nodo2)
		if tipo == "DireccionInvalida" then
			mostrarFeedbackDireccion(nodo1, nodo2)
		end
	end)

	print("✅ DirectedFeedback: escuchando DireccionInvalida")
end)
