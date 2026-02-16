local dialogueKitModule = require(script.Parent.Parent.DialogueKit)
local DialogueGenerator = require(script.Parent.DialogueGenerator)

local VisualEffectsService = require(
	game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
		:WaitForChild("Cliente"):WaitForChild("Services"):WaitForChild("VisualEffectsService")
)
local LevelsConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("LevelsConfig"))

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
-- VARIABLES DINÁMICAS
-- ================================================================

local alias1 = LevelsConfig[0].Nodos[CONFIG.NODOS.nodo1].Alias
local alias2 = LevelsConfig[0].Nodos[CONFIG.NODOS.nodo2].Alias

-- ================================================================
-- DIÁLOGOS
-- ================================================================

local DATA_DIALOGOS = {

	["Inicio"] = {
		Actor = "Carlos",
		Expresion = "Serio",
		Texto = {
			"Bienvenido a la Zona 1.",
			"Aquí aprenderás qué es un nodo y qué es una conexión."
		},
		Sonido = { "rbxassetid://133631096743397", "rbxassetid://82943328777335" },
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
		Expresion = "Feliz",
		Texto = {
			"Observa este punto frente a ti.",
			"Eso es un NODO.",
			"En teoría de grafos, un nodo representa un elemento dentro de una red.",
			"Un nodo puede representar cualquier cosa: una persona, una ciudad, una computadora…",
			"Lo importante es que es un punto que puede conectarse con otros."
		},
		Sonido = { "rbxassetid://0", "rbxassetid://0" },
		Evento = function()
			VisualEffectsService:clearEffects()
			local n1 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo1)
			if n1 then
				VisualEffectsService:highlightObject(n1, CONFIG.COLORES.azul)
				VisualEffectsService:showNodeLabel(n1, alias1)
				VisualEffectsService:focusCameraOn(n1, CONFIG.CAMARA.offset_nodo)
			end
		end,
		Siguiente = "Nodo_Aislado"
	},

	["Nodo_Aislado"] = {
		Actor = "Carlos",
		Expresion = "Presentacion",
		Texto = {
			"Un nodo sin conexiones está aislado.",
			"No forma parte de una red."
		},
		Sonido = { "rbxassetid://0", "rbxassetid://0" },
		Evento = function()
			VisualEffectsService:clearEffects()
			local n1 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo1)
			local n2 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo2)

			if n1 and n2 then
				VisualEffectsService:highlightObject(n1, CONFIG.COLORES.rojo)
				VisualEffectsService:highlightObject(n2, CONFIG.COLORES.rojo)

				VisualEffectsService:showNodeLabel(n1, alias1)
				VisualEffectsService:showNodeLabel(n2, alias2)

				local midPoint = n1.Position:Lerp(n2.Position, 0.5)
				local camPos = midPoint + CONFIG.CAMARA.offset_arista
				local newCF = CFrame.new(camPos, midPoint)

				local camera = workspace.CurrentCamera
				local tweenInfo = TweenInfo.new(CONFIG.CAMARA.duracion, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				game:GetService("TweenService"):Create(camera, tweenInfo, {CFrame = newCF}):Play()
			end
		end,
		Siguiente = "Concepto_Arista"
	},


	["Concepto_Arista"] = {
		Actor = "Carlos",
		Expresion = "Serio",
		Texto = {
			"Cuando conectas dos nodos, creas una ARISTA.",
			"La arista representa una relación entre ellos."
		},
		Sonido = { "rbxassetid://0", "rbxassetid://0" },
		Evento = function()
			VisualEffectsService:clearEffects()
			local n1 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo1)
			local n2 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo2)

			if n1 and n2 then
				VisualEffectsService:highlightObject(n1, CONFIG.COLORES.azul)
				VisualEffectsService:highlightObject(n2, CONFIG.COLORES.azul)

				VisualEffectsService:showNodeLabel(n1, alias1)
				VisualEffectsService:showNodeLabel(n2, alias2)

				VisualEffectsService:createFakeEdge(n1, n2, CONFIG.COLORES.amarillo)

				local midPoint = n1.Position:Lerp(n2.Position, 0.5)
				local camPos = midPoint + CONFIG.CAMARA.offset_arista
				local newCF = CFrame.new(camPos, midPoint)

				local camera = workspace.CurrentCamera
				local tweenInfo = TweenInfo.new(CONFIG.CAMARA.duracion, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				game:GetService("TweenService"):Create(camera, tweenInfo, {CFrame = newCF}):Play()
			end
		end,
		Siguiente = "Instrucciones_1"
	},

	["Instrucciones_1"] = {
		Actor = "Sistema",
		Expresion = "Serio",
		Texto = "Selecciona un nodo de origen (" .. alias1 .. ").",
		Sonido = "rbxassetid://0",
		Evento = function()
			VisualEffectsService:clearEffects()
			local n1 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo1)
			if n1 then
				VisualEffectsService:highlightObject(n1, CONFIG.COLORES.verde)
				VisualEffectsService:showNodeLabel(n1, alias1)
				VisualEffectsService:focusCameraOn(n1, CONFIG.CAMARA.offset_zoom)
				VisualEffectsService:blink(n1, 30, 1)
			end
		end,
		Siguiente = "Instrucciones_2"
	},

	["Instrucciones_2"] = {
		Actor = "Sistema",
		Expresion = "Serio",
		Texto = "Luego selecciona el nodo destino (" .. alias2 .. ").",
		Sonido = "rbxassetid://0",
		Evento = function()
			VisualEffectsService:clearEffects()
			local n1 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo1)
			local n2 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo2)


			if n1 and n2 then
				VisualEffectsService:highlightObject(n1, CONFIG.COLORES.verde_debil)
				VisualEffectsService:highlightObject(n2, CONFIG.COLORES.rojo)

				VisualEffectsService:showNodeLabel(n1, LevelsConfig[0].Nodos[CONFIG.NODOS.nodo1].Alias)
				VisualEffectsService:showNodeLabel(n2, LevelsConfig[0].Nodos[CONFIG.NODOS.nodo2].Alias)

				VisualEffectsService:focusCameraOn(n2, CONFIG.CAMARA.offset_zoom)
				VisualEffectsService:blink(n2, 30, 1)
			end
		end,
		Siguiente = "Instrucciones_3"
	},

	["Instrucciones_3"] = {
		Actor = "Sistema",
		Expresion = "Feliz",
		Texto = "Así crearás una conexión.",
		Sonido = "rbxassetid://0",
		Evento = function()
			VisualEffectsService:clearEffects()
			local n1 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo1)
			local n2 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo2)

			if n1 and n2 then
				VisualEffectsService:highlightObject(n1, CONFIG.COLORES.verde)
				VisualEffectsService:highlightObject(n2, CONFIG.COLORES.verde)

				VisualEffectsService:showNodeLabel(n1, LevelsConfig[0].Nodos[CONFIG.NODOS.nodo1].Alias)
				VisualEffectsService:showNodeLabel(n2, LevelsConfig[0].Nodos[CONFIG.NODOS.nodo2].Alias)

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
		Siguiente = "Confirmacion"
	},

	["Confirmacion"] = {
		Actor = "Carlos",
		Expresion = "Serio",
		Texto = {
			"Ahora es tu turno.",
			"Conecta los nodos."
		},
		Sonido = { "rbxassetid://0", "rbxassetid://0" },
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