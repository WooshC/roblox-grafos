local dialogueKitModule = require(script.Parent.Parent.DialogueKit)
local DialogueGenerator = require(script.Parent.DialogueGenerator)
local dialoguePrompt = workspace:WaitForChild("NivelActual"):WaitForChild("DialoguePrompts"):WaitForChild("TestPrompt1").PromptPart.ProximityPrompt

-- ============================================================================
-- CONFIGURACIÓN DE APARIENCIA
-- ============================================================================
local SKIN_NAME = "Hotline" 

-- ============================================================================
-- 1. ZONA DE EDICIÓN FÁCIL
-- ============================================================================

local VisualEffectsService = require(
	game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
		:WaitForChild("Cliente"):WaitForChild("Services"):WaitForChild("VisualEffectsService")
)
local LevelsConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("LevelsConfig"))

local DATA_DIALOGOS = {
	-- 1. INTRODUCCIÓN Y CONTEXTO
	["Bienvenida"] = {
		Actor = "Carlos",
		Expresion = "Sonriente",
		Texto = "Hola. Tú debes ser Tocino, ¿verdad?",
		Sonido = "rbxassetid://0",
		Opciones = {
			{ Texto = "Sí, soy Tocino.", Siguiente = "Saludo_Tocino" }
		}
	},

	["Saludo_Tocino"] = {
		Actor = "Carlos",
		Expresion = "Presentacion",
		Texto = "Qué bien que hayas venido. Necesitamos formar a alguien que entienda cómo funcionan las redes.",
		Sonido = "rbxassetid://0",
		Siguiente = "Fundamentos"
	},

	["Fundamentos"] = {
		Actor = "Carlos",
		Expresion = "Serio",
		Texto = {
			"Antes de resolver cualquier problema real, debes aprender los fundamentos básicos de los grafos.",
			"Sin comprender la estructura, no podrás analizar ninguna red."
		},
		Sonido = { "rbxassetid://0", "rbxassetid://0" },
		Siguiente = "Zona_1"
	},

	["Zona_1"] = {
		Actor = "Carlos",
		Expresion = "Serio",
		Texto = {
			"Dirígete a la Zona 1.",
			"Allí comenzarás con los primeros conceptos: nodos y conexiones."
		},
		Sonido = { "rbxassetid://0", "rbxassetid://0" },
		Evento = function()
			-- Ocultar techo y apuntar cámara a Zona 1
			VisualEffectsService:toggleTecho(false)
			local nodoZona1 = VisualEffectsService:findNodeByName("Nodo1_z1")
			if nodoZona1 then
				VisualEffectsService:focusCameraOn(nodoZona1, Vector3.new(20, 25, 20))
			end
		end,
		Siguiente = "Confirmacion_Final"
	},

	["Confirmacion_Final"] = {
		Actor = "Carlos",
		Expresion = "Sonriente",
		Texto = "¡Confío en ti. Suerte!",
		Sonido = "rbxassetid://0",
		Evento = function()
			VisualEffectsService:restoreCamera()
			VisualEffectsService:toggleTecho(true)
		end,
		Siguiente = "FIN"
	}
}

-- ============================================================================
-- 3. EJECUCIÓN
-- ============================================================================

dialoguePrompt.Triggered:Connect(function(player)
	-- Generamos la tabla compleja usando el módulo
	local layersComplejas = DialogueGenerator.GenerarEstructura(DATA_DIALOGOS, SKIN_NAME)

	-- Llamamos al módulo
	dialogueKitModule.CreateDialogue({
		InitialLayer = "Bienvenida", 
		SkinName = SKIN_NAME, 
		Config = script:FindFirstChild(SKIN_NAME .. "Config") or script, 
		Layers = layersComplejas
	})
end)



