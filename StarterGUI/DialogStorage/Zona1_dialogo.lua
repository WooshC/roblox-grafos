-- ================================================================
-- StarterGUI/DialogStorage/Zona1_dialogo.lua
-- Instrucción simple: 4 pasos de explicación visual (sin click)
-- ================================================================

local dialogueKitModule = require(script.Parent.Parent.DialogueKit)
local DialogueGenerator = require(script.Parent.DialogueGenerator)

local VisualEffectsService = require(
	game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
		:WaitForChild("Cliente"):WaitForChild("Services"):WaitForChild("VisualEffectsService")
)

-- ================================================================
-- CONFIGURACIÓN
-- ================================================================

local CONFIG = {
	ZONA_OBJETIVO = "Zona_Estacion_1",
	SKIN_NAME = "Hotline",
	NODOS = {
		nodo1 = "Nodo1_z1",
		nodo2 = "Nodo2_z1"
	},
	COLORES = {
		azul = Color3.fromRGB(0, 170, 255),
		verde = Color3.fromRGB(0, 255, 0),
		rojo = Color3.fromRGB(255, 0, 0),
		amarillo = Color3.fromRGB(255, 255, 0),
		verde_debil = Color3.fromRGB(100, 200, 100)
	},
	CAMARA = {
		offset_inicio = Vector3.new(22, 22, 22),
		offset_nodo = Vector3.new(15, 18, 15),
		offset_arista = Vector3.new(0, 25, 20),
		offset_objetivo = Vector3.new(0, 30, 25),
		offset_zoom = Vector3.new(12, 15, 12),
		duracion = 1.5
	}
}

-- ================================================================
-- DIÁLOGOS
-- ================================================================

local DATA_DIALOGOS = {
	["Inicio"] = {
		Actor = "Carlos",
		Expresion = "Serio",
		Texto = {
			"Bien, has llegado a la Zona 1. Aquí pondremos en práctica la teoría.",
			"Escucha con atención, porque no repetiré esto dos veces."
		},
		Sonido = { "rbxassetid://0", "rbxassetid://0" },
		Evento = function()
			VisualEffectsService:toggleTecho(false)
			local nodo1 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo1)
			if nodo1 then
				VisualEffectsService:focusCameraOn(nodo1, CONFIG.CAMARA.offset_inicio)
			end
		end,
		Siguiente = "Concepto_Nodo"
	},

	["Concepto_Nodo"] = {
		Actor = "Carlos",
		Expresion = "Explicando",
		Texto = {
			"Antes de conectar nada, debes entender qué estás viendo.",
			"Este punto que observas se llama NODO.",
			"En teoría de grafos, un nodo representa un punto dentro de una red.",
			"Puede ser una ciudad, una computadora, una estación... aquí representa una estación de energía."
		},
		Sonido = { "rbxassetid://0", "rbxassetid://0", "rbxassetid://0", "rbxassetid://0" },
		Evento = function()
			VisualEffectsService:clearEffects()
			local n1 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo1)
			if n1 then
				VisualEffectsService:highlightObject(n1, CONFIG.COLORES.azul)
				VisualEffectsService:focusCameraOn(n1, CONFIG.CAMARA.offset_nodo)
			end
		end,
		Siguiente = "Concepto_Arista"
	},

	["Concepto_Arista"] = {
		Actor = "Carlos",
		Expresion = "Didactico",
		Texto = {
			"Cuando conectas dos nodos, creas una ARISTA.",
			"Una arista representa una relación o conexión entre dos puntos.",
			"Sin aristas, los nodos están aislados. Mira esto..."
		},
		Sonido = { "rbxassetid://0", "rbxassetid://0", "rbxassetid://0" },
		Evento = function()
			VisualEffectsService:clearEffects()
			local n1 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo1)
			local n2 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo2)

			if n1 and n2 then
				VisualEffectsService:highlightObject(n1, CONFIG.COLORES.azul)
				VisualEffectsService:highlightObject(n2, CONFIG.COLORES.azul)
				VisualEffectsService:createFakeEdge(n1, n2, CONFIG.COLORES.amarillo)

				local midPoint = n1.Position:Lerp(n2.Position, 0.5)
				local camPos = midPoint + CONFIG.CAMARA.offset_arista
				local newCF = CFrame.new(camPos, midPoint)

				local camera = workspace.CurrentCamera
				local tweenInfo = TweenInfo.new(CONFIG.CAMARA.duracion, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				game:GetService("TweenService"):Create(camera, tweenInfo, {CFrame = newCF}):Play()
			end
		end,
		Siguiente = "Explicacion_Objetivo"
	},

	["Explicacion_Objetivo"] = {
		Actor = "Carlos",
		Expresion = "Presentacion",
		Texto = "Tu objetivo es simple: Conectar el Nodo 1 con el Nodo 2 para restablecer el flujo en este sector.",
		Sonido = "rbxassetid://0",
		Evento = function()
			VisualEffectsService:clearEffects()
			local n1 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo1)
			local n2 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo2)

			if n1 then VisualEffectsService:highlightObject(n1, CONFIG.COLORES.verde) end
			if n2 then VisualEffectsService:highlightObject(n2, CONFIG.COLORES.rojo) end

			if n1 and n2 then
				local midPoint = n1.Position:Lerp(n2.Position, 0.5)
				local camPos = midPoint + CONFIG.CAMARA.offset_objetivo
				local newCF = CFrame.new(camPos, midPoint)

				local camera = workspace.CurrentCamera
				local tweenInfo = TweenInfo.new(CONFIG.CAMARA.duracion, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				game:GetService("TweenService"):Create(camera, tweenInfo, {CFrame = newCF}):Play()
			end
		end,
		Siguiente = "Instruccion_Tecnica"
	},

	-- ================================================================
	-- INSTRUCCIÓN EN 4 PASOS: Solo explicación visual
	-- El jugador OBSERVA cómo se conectan los nodos
	-- ================================================================

	["Instruccion_Tecnica"] = {
		Actor = "Sistema",
		Expresion = "Arista",
		Texto = "Te mostraré cómo conectar nodos. Presta atención...",
		Sonido = "rbxassetid://0",
		Evento = function()
			VisualEffectsService:clearEffects()

			local n1 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo1)
			if n1 then
				VisualEffectsService:highlightObject(n1, CONFIG.COLORES.verde)
				VisualEffectsService:focusCameraOn(n1, CONFIG.CAMARA.offset_zoom)
			end
		end,
		Siguiente = "Instruccion_Paso2"
	},

	["Instruccion_Paso2"] = {
		Actor = "Sistema",
		Expresion = "Arista",
		Texto = "Primero: haz click en el Nodo 1 (Verde). Este es el ORIGEN.",
		Sonido = "rbxassetid://0",
		Evento = function()
			local n1 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo1)
			if n1 then
				VisualEffectsService:blink(n1, 30, 1)
			end
		end,
		Siguiente = "Instruccion_Paso3"
	},

	["Instruccion_Paso3"] = {
		Actor = "Sistema",
		Expresion = "Arista",
		Texto = "Segundo: haz click en el Nodo 2 (Rojo). Este es el DESTINO.",
		Sonido = "rbxassetid://0",
		Evento = function()
			VisualEffectsService:clearEffects()

			local n1 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo1)
			local n2 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo2)

			if n1 and n2 then
				VisualEffectsService:highlightObject(n1, CONFIG.COLORES.verde_debil)
				VisualEffectsService:highlightObject(n2, CONFIG.COLORES.rojo)
				VisualEffectsService:focusCameraOn(n2, CONFIG.CAMARA.offset_zoom)
				VisualEffectsService:blink(n2, 30, 1)
			end
		end,
		Siguiente = "Instruccion_Paso4"
	},

	["Instruccion_Paso4"] = {
		Actor = "Sistema",
		Expresion = "Arista",
		Texto = "Y así se crea la ARISTA entre ambos. ¡Mira!",
		Sonido = "rbxassetid://0",
		Evento = function()
			VisualEffectsService:clearEffects()

			local n1 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo1)
			local n2 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo2)

			if n1 and n2 then
				VisualEffectsService:highlightObject(n1, CONFIG.COLORES.verde)
				VisualEffectsService:highlightObject(n2, CONFIG.COLORES.verde)
				VisualEffectsService:createFakeEdge(n1, n2, CONFIG.COLORES.amarillo)

				local midPoint = n1.Position:Lerp(n2.Position, 0.5)
				local camPos = midPoint + CONFIG.CAMARA.offset_arista
				local newCF = CFrame.new(camPos, midPoint)

				local camera = workspace.CurrentCamera
				local tweenInfo = TweenInfo.new(CONFIG.CAMARA.duracion, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				game:GetService("TweenService"):Create(camera, tweenInfo, {CFrame = newCF}):Play()

				VisualEffectsService:blink(n1, 30, 1.5)
				task.wait(0.2)
				VisualEffectsService:blink(n2, 30, 1.5)
			end
		end,
		Siguiente = "Instruccion_Confirmacion"
	},

	["Instruccion_Confirmacion"] = {
		Actor = "Sistema",
		Expresion = "Arista",
		Texto = "¿Entendiste? Ahora es tu turno. Conecta el Nodo 1 con el Nodo 2.",
		Sonido = "rbxassetid://0",
		Evento = function()
			VisualEffectsService:clearEffects()

			local n1 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo1)
			local n2 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo2)

			if n1 then VisualEffectsService:highlightObject(n1, CONFIG.COLORES.verde) end
			if n2 then VisualEffectsService:highlightObject(n2, CONFIG.COLORES.rojo) end
		end,
		Siguiente = "Despedida"
	},

	["Despedida"] = {
		Actor = "Carlos",
		Expresion = "Sonriente",
		Texto = "¡Adelante! Conecta los nodos y verás la energía fluir.",
		Sonido = "rbxassetid://0",
		Evento = function()
			VisualEffectsService:clearEffects()
			VisualEffectsService:toggleTecho(true)
			VisualEffectsService:restoreCamera()
		end,
		Siguiente = "FIN"
	}
}

-- ================================================================
-- LÓGICA DE ACTIVACIÓN
-- ================================================================

local yaSeMostro = false

local function checkZone(newZone)
	if yaSeMostro then return end

	if newZone == CONFIG.ZONA_OBJETIVO then
		local player = game.Players.LocalPlayer
		if not player.Character then return end

		yaSeMostro = true
		print("✅ " .. CONFIG.ZONA_OBJETIVO .. " detectada")

		local layersComplejas = DialogueGenerator.GenerarEstructura(DATA_DIALOGOS, CONFIG.SKIN_NAME)

		dialogueKitModule.CreateDialogue({
			InitialLayer = "Inicio", 
			SkinName = CONFIG.SKIN_NAME, 
			Config = script:FindFirstChild(CONFIG.SKIN_NAME .. "Config") or script, 
			Layers = layersComplejas
		})
	end
end

local player = game.Players.LocalPlayer
player:GetAttributeChangedSignal("CurrentZone"):Connect(function()
	local zona = player:GetAttribute("CurrentZone")
	checkZone(zona)
end)

task.delay(1, function()
	local zona = player:GetAttribute("CurrentZone")
	if zona then checkZone(zona) end
end)

print("✅ Zona1_dialogo cargado")