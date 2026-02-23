local dialogueKitModule = require(script.Parent.Parent.DialogueKit)
local DialogueGenerator = require(script.Parent.DialogueGenerator)
local desbloquearZona = require(game:GetService("ReplicatedStorage"):WaitForChild("DesbloquearZona"))

local VisualEffectsService = require(
	game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
		:WaitForChild("Cliente"):WaitForChild("Services"):WaitForChild("VisualEffectsService")
)

local MapManager = require(
	game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
		:WaitForChild("Cliente"):WaitForChild("Services"):WaitForChild("MapManager")
)

local LevelsConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("LevelsConfig"))

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ================================================================
-- OBTENER DialogueVisibilityManager
-- ================================================================

local DialogueVisibilityManager = require(
	ReplicatedStorage:WaitForChild("DialogueVisibilityManager", 5)
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
		azul        = Color3.fromRGB(0, 170, 255),
		verde       = Color3.fromRGB(0, 255, 0),
		rojo        = Color3.fromRGB(255, 0, 0),
		amarillo    = Color3.fromRGB(255, 255, 0),
		verde_debil = Color3.fromRGB(100, 200, 100)
	},
	CAMARA = {
		offset_inicio  = Vector3.new(22, 22, 22),
		offset_nodo    = Vector3.new(15, 18, 15),
		offset_arista  = Vector3.new(0, 25, 20),
		offset_objetivo= Vector3.new(0, 30, 25),
		offset_zoom    = Vector3.new(12, 15, 12),
		duracion       = 1.5
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
		Expresion = "Bienvenida",
		Texto = {
			"Bienvenido a la Zona 1.",
			"Aquí aprenderás qué es un nodo y qué es una conexión."
		},
		Sonido = { "rbxassetid://82943328777335", "rbxassetid://133631096743397" },
		Evento = function()
			-- ✅ El techo ya está oculto — DialogueVisibilityManager lo gestionó
			-- Solo mover la cámara al nodo inicial
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
		Sonido = {
			"rbxassetid://85119928661707",
			"rbxassetid://84437951272776",
			"rbxassetid://84784432074545",
			"rbxassetid://87649995326832",
			"rbxassetid://120274038079160"
		},
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
		Expresion = "Serio",
		Texto = {
			"Un nodo sin conexiones está aislado.",
			"No forma parte de una red."
		},
		Sonido = { "rbxassetid://71817259692490", "rbxassetid://127699663903662" },
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
				local camera = workspace.CurrentCamera
				game:GetService("TweenService"):Create(camera,
					TweenInfo.new(CONFIG.CAMARA.duracion, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{CFrame = CFrame.new(midPoint + CONFIG.CAMARA.offset_arista, midPoint)}
				):Play()
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
		Sonido = { "rbxassetid://138764900027849", "rbxassetid://135325741435287" },
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
				local camera = workspace.CurrentCamera
				game:GetService("TweenService"):Create(camera,
					TweenInfo.new(CONFIG.CAMARA.duracion, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{CFrame = CFrame.new(midPoint + CONFIG.CAMARA.offset_arista, midPoint)}
				):Play()
			end
		end,
		Siguiente = "Instrucciones_1"
	},

	["Instrucciones_1"] = {
		Actor = "Sistema",
		Expresion = "Bienvenida",
		Texto = "Selecciona un nodo de origen (" .. alias1 .. ").",
		Sonido = "rbxassetid://91232241403260",
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
		Actor = "Carlos",
		Expresion = "Serio",
		Texto = "Luego selecciona el nodo destino (" .. alias2 .. ").",
		Sonido = "rbxassetid://76732191360053",
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
		Actor = "Carlos",
		Expresion = "Feliz",
		Texto = "Así crearás una conexión.",
		Sonido = "rbxassetid://124195032304220",
		Evento = function()
			VisualEffectsService:clearEffects()
			local n1 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo1)
			local n2 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo2)

			if n1 and n2 then
				VisualEffectsService:highlightObject(n1, CONFIG.COLORES.azul)
				VisualEffectsService:highlightObject(n2, CONFIG.COLORES.azul)
				VisualEffectsService:showNodeLabel(n1, LevelsConfig[0].Nodos[CONFIG.NODOS.nodo1].Alias)
				VisualEffectsService:showNodeLabel(n2, LevelsConfig[0].Nodos[CONFIG.NODOS.nodo2].Alias)
				VisualEffectsService:createFakeEdge(n1, n2, CONFIG.COLORES.amarillo)

				local midPoint = n1.Position:Lerp(n2.Position, 0.5)
				local camera = workspace.CurrentCamera
				game:GetService("TweenService"):Create(camera,
					TweenInfo.new(CONFIG.CAMARA.duracion, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{CFrame = CFrame.new(midPoint + CONFIG.CAMARA.offset_arista, midPoint)}
				):Play()

				VisualEffectsService:blink(n1, 30, 1.5)
				task.wait(0.2)
				VisualEffectsService:blink(n2, 30, 1.5)
			end
		end,
		Siguiente = "Confirmacion"
	},

	["Confirmacion"] = {
		Actor = "Carlos",
		Expresion = "Feliz",
		Texto = {
			"Ahora es tu turno.",
			"Conecta los nodos."
		},
		Sonido = { "rbxassetid://98229492565124", "rbxassetid://98076423902070" },
		Evento = function()
			VisualEffectsService:clearEffects()
			VisualEffectsService:restoreCamera()
			desbloquearZona("Bloqueo_zona_2")
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
	if newZone ~= CONFIG.ZONA_OBJETIVO then return end

	local player = game.Players.LocalPlayer
	if not player.Character then return end

	yaSeMostro = true
	print("✅ " .. CONFIG.ZONA_OBJETIVO .. " detectada — iniciando diálogo")

	-- Cerrar mapa si está activo (también oculta techo vía ForceCloseMap)
	if MapManager:isActive() then
		print("🗺️ Zona1_Dialogo: Mapa activo — ForceCloseMap se disparará desde onDialogueStart")
	end

	-- ✅ Notificar inicio de diálogo (oculta techo, bloquea salto, cierra mapa)
	if DialogueVisibilityManager then
		DialogueVisibilityManager:onDialogueStart()
	end

	local layersComplejas = DialogueGenerator.GenerarEstructura(DATA_DIALOGOS, CONFIG.SKIN_NAME)

	dialogueKitModule.CreateDialogue({
		InitialLayer = "Inicio",
		SkinName = CONFIG.SKIN_NAME,
		Config = script:FindFirstChild(CONFIG.SKIN_NAME .. "Config") or script,
		Layers = layersComplejas,
		OnClose = function()
			-- ✅ Notificar fin de diálogo (restaura techo, desbloquea salto, restaura GUI)
			if DialogueVisibilityManager then
				DialogueVisibilityManager:onDialogueEnd()
			end
			print("✅ Zona1_Dialogo: Diálogo terminado — recursos restaurados")
		end
	})
end

local player = game.Players.LocalPlayer
player:GetAttributeChangedSignal("CurrentZone"):Connect(function()
	checkZone(player:GetAttribute("CurrentZone"))
end)

task.delay(1, function()
	local zona = player:GetAttribute("CurrentZone")
	if zona then checkZone(zona) end
end)

print("✅ Zona1_dialogo cargado")