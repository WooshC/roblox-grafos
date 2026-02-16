-- ReplicatedStorage/Services/DialogueVisibilityManager.lua
-- Controla la visibilidad de la GUI durante diálogos

local DialogueVisibilityManager = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Referencias
local guiExplorador = nil
local dialogueKit = nil
local isDialogueActive = false

function DialogueVisibilityManager.initialize()
	-- Esperar a que DialogueKit esté disponible
	task.spawn(function()
		dialogueKit = playerGui:WaitForChild("DialogueKit", 10)
		if dialogueKit then
			print("✅ DialogueVisibilityManager: DialogueKit encontrado")
		end
	end)

	-- Esperar a que GUIExplorador esté disponible
	task.spawn(function()
		guiExplorador = playerGui:WaitForChild("GUIExplorador", 10)
		if guiExplorador then
			print("✅ DialogueVisibilityManager: GUIExplorador encontrado")
		end
	end)

	print("✅ DialogueVisibilityManager: Inicializado")
end

--- Llama esto cuando un diálogo comienza
function DialogueVisibilityManager:onDialogueStart()
	if isDialogueActive then return end

	isDialogueActive = true

	if guiExplorador then
		guiExplorador.Enabled = false
		print("🔒 DialogueVisibilityManager: GUIExplorador ocultada")
	end
end

--- Llama esto cuando un diálogo termina
function DialogueVisibilityManager:onDialogueEnd()
	if not isDialogueActive then return end

	isDialogueActive = false

	if guiExplorador then
		guiExplorador.Enabled = true
		print("📖 DialogueVisibilityManager: GUIExplorador restaurada")
	end
end

return DialogueVisibilityManager