-- StarterGUI/DialogStorage/Zona3_dialogo.lua
-- Zona 3: Grafos Dirigidos
-- Cámara cenital (top-down) para ver la cadena X → Y → Z desde arriba.
-- Incluye pregunta de validación al final.

local dialogueKitModule = require(script.Parent.Parent.DialogueKit)
local DialogueGenerator  = require(script.Parent.DialogueGenerator)

local VisualEffectsService = require(
	game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
		:WaitForChild("Cliente"):WaitForChild("Services"):WaitForChild("VisualEffectsService")
)

local MapManager = require(
	game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
		:WaitForChild("Cliente"):WaitForChild("Services"):WaitForChild("MapManager")
)

local LevelsConfig      = require(game:GetService("ReplicatedStorage"):WaitForChild("LevelsConfig"))
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DialogueVisibilityManager = require(
	ReplicatedStorage:WaitForChild("DialogueVisibilityManager", 5)
)

-- ================================================================
-- CONFIGURACIÓN
-- ================================================================

local CONFIG = {
	ZONA_OBJETIVO = "Zona_Estacion_3",
	SKIN_NAME     = "Hotline",
	NODOS = {
		nodoX = "Nodo1_z3",  -- "Nodo X"  → origen
		nodoY = "Nodo2_z3",  -- "Nodo Y"  → intermediario
		nodoZ = "Nodo3_z3",  -- "Nodo Z"  → destino
		nodoW = "Nodo4_z3",  -- "Nodo W"  → aislado
	},
	COLORES = {
		azul        = Color3.fromRGB(0, 170, 255),
		verde       = Color3.fromRGB(0, 255, 0),
		rojo        = Color3.fromRGB(255, 0, 0),
		amarillo    = Color3.fromRGB(255, 255, 0),
		naranja     = Color3.fromRGB(255, 140, 0),
		verde_debil = Color3.fromRGB(100, 200, 100),
		cian        = Color3.fromRGB(0, 255, 220),
	},
	CAMARA = {
		-- Vista inclinada: ángulo casi perpendicular pero con componente horizontal
		-- para evitar que los muros tapen la vista al interactuar con nodos
		offset_alto  = Vector3.new(18, 40, 18),  -- vista general inclinada ~65°
		offset_medio = Vector3.new(12, 28, 12),  -- zoom medio inclinado
		offset_cerca = Vector3.new(10, 20, 10),  -- close-up inclinado
		duracion     = 1.5,
	},
}

-- ================================================================
-- VARIABLES DINÁMICAS
-- ================================================================

local aliasX = LevelsConfig[0].Nodos[CONFIG.NODOS.nodoX].Alias  -- "Nodo X"
local aliasY = LevelsConfig[0].Nodos[CONFIG.NODOS.nodoY].Alias  -- "Nodo Y"
local aliasZ = LevelsConfig[0].Nodos[CONFIG.NODOS.nodoZ].Alias  -- "Nodo Z"
local aliasW = LevelsConfig[0].Nodos[CONFIG.NODOS.nodoW].Alias  -- "Nodo W"

-- ================================================================
-- UTILIDAD: Centrar cámara entre múltiples partes, top-down
-- ================================================================

local TweenService = game:GetService("TweenService")

local function enfocarEntre(partList, offset)
	if not partList or #partList == 0 then return end
	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	local sum = Vector3.new(0, 0, 0)
	for _, p in ipairs(partList) do sum = sum + p.Position end
	local mid = sum / #partList
	TweenService:Create(workspace.CurrentCamera,
		TweenInfo.new(CONFIG.CAMARA.duracion, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = CFrame.new(mid + offset, mid) }
	):Play()
end

-- ================================================================
-- DIÁLOGOS
-- ================================================================

local DATA_DIALOGOS = {

	["Inicio"] = {
		Actor     = "Carlos",
		Expresion = "Serio",
		Texto     = {
			"Bienvenido a la Zona 3.",
			"Hasta ahora las conexiones no tenían dirección.",
			"Aquí aprenderás qué es un GRAFO DIRIGIDO.",
		},
		Sonido    = {
			"rbxassetid://82943328777335",
			"rbxassetid://133631096743397",
			"rbxassetid://85119928661707",
		},
		Evento    = function()
			local nX = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoX)
			if nX then
				VisualEffectsService:focusCameraOn(nX, CONFIG.CAMARA.offset_alto)
			end
		end,
		Siguiente = "QueEsDirigido",
	},

	["QueEsDirigido"] = {
		Actor     = "Carlos",
		Expresion = "Serio",
		Texto     = {
			"En un grafo normal, una arista conecta dos nodos en AMBOS sentidos.",
			"En un grafo DIRIGIDO, cada arista tiene UNA sola dirección.",
			"Como una calle de un solo sentido.",
		},
		Sonido    = { "rbxassetid://84437951272776", "rbxassetid://71817259692490", "rbxassetid://84784432074545" },
		Evento    = function()
			VisualEffectsService:clearEffects()
			local nX = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoX)
			local nY = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoY)
			if nX and nY then
				VisualEffectsService:highlightObject(nX, CONFIG.COLORES.azul)
				VisualEffectsService:highlightObject(nY, CONFIG.COLORES.naranja)
				VisualEffectsService:showNodeLabel(nX, aliasX .. " →")
				VisualEffectsService:showNodeLabel(nY, aliasY)
				VisualEffectsService:createFakeEdge(nX, nY, CONFIG.COLORES.cian)
				enfocarEntre({nX, nY}, CONFIG.CAMARA.offset_alto)
			end
		end,
		Siguiente = "DireccionImporta",
	},

	["DireccionImporta"] = {
		Actor     = "Carlos",
		Expresion = "Serio",
		Texto     = {
			"Si " .. aliasX .. " apunta a " .. aliasY .. ", puedes ir de X a Y.",
			"Pero por esa misma arista NO puedes regresar de Y a X.",
			"La dirección definida es la única permitida.",
		},
		Sonido    = { "rbxassetid://87649995326832", "rbxassetid://120274038079160", "rbxassetid://127699663903662" },
		Evento    = function()
			VisualEffectsService:clearEffects()
			local nX = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoX)
			local nY = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoY)
			if nX and nY then
				VisualEffectsService:highlightObject(nX, CONFIG.COLORES.cian)
				VisualEffectsService:highlightObject(nY, CONFIG.COLORES.naranja)
				VisualEffectsService:showNodeLabel(nX, aliasX .. " (Origen)")
				VisualEffectsService:showNodeLabel(nY, aliasY .. " (Destino)")
				VisualEffectsService:createFakeEdge(nX, nY, CONFIG.COLORES.amarillo)
				VisualEffectsService:blink(nX, 5, 2)
				enfocarEntre({nX, nY}, CONFIG.CAMARA.offset_alto)
			end
		end,
		Siguiente = "NodoAislado",
	},

	["NodoAislado"] = {
		Actor     = "Carlos",
		Expresion = "Serio",
		Texto     = {
			"Este nodo es " .. aliasW .. ".",
			"Está AISLADO: no tiene ninguna arista válida.",
			"No puede conectarse con ningún otro nodo de esta zona.",
		},
		Sonido    = { "rbxassetid://138764900027849", "rbxassetid://135325741435287", "rbxassetid://71817259692490" },
		Evento    = function()
			VisualEffectsService:clearEffects()
			local nW = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoW)
			if nW then
				VisualEffectsService:highlightObject(nW, CONFIG.COLORES.rojo)
				VisualEffectsService:showNodeLabel(nW, aliasW .. " (Aislado)")
				VisualEffectsService:focusCameraOn(nW, CONFIG.CAMARA.offset_medio)
				VisualEffectsService:blink(nW, 4, 1.5)
			end
		end,
		Siguiente = "ConceptoCamino",
	},

	["ConceptoCamino"] = {
		Actor     = "Carlos",
		Expresion = "Feliz",
		Texto     = {
			"Cuando varias aristas dirigidas se encadenan forman un CAMINO.",
			"Cada nodo recibe y reenvía en la dirección definida.",
		},
		Sonido    = { "rbxassetid://98229492565124", "rbxassetid://84437951272776" },
		Evento    = function()
			VisualEffectsService:clearEffects()
			local nX = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoX)
			local nY = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoY)
			local nZ = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoZ)
			if nX and nY and nZ then
				VisualEffectsService:highlightObject(nX, CONFIG.COLORES.azul)
				VisualEffectsService:highlightObject(nY, CONFIG.COLORES.naranja)
				VisualEffectsService:highlightObject(nZ, CONFIG.COLORES.verde)
				VisualEffectsService:showNodeLabel(nX, aliasX)
				VisualEffectsService:showNodeLabel(nY, aliasY)
				VisualEffectsService:showNodeLabel(nZ, aliasZ)
				enfocarEntre({nX, nY, nZ}, CONFIG.CAMARA.offset_alto)
			end
		end,
		Siguiente = "EjemploCamino",
	},

	["EjemploCamino"] = {
		Actor     = "Carlos",
		Expresion = "Feliz",
		Texto     = {
			"La cadena de esta zona es: " .. aliasX .. " → " .. aliasY .. " → " .. aliasZ .. ".",
			aliasX .. " envía a " .. aliasY .. ", y " .. aliasY .. " envía a " .. aliasZ .. ".",
			"La información fluye en UN solo sentido a lo largo de la cadena.",
		},
		Sonido    = { "rbxassetid://87649995326832", "rbxassetid://98076423902070", "rbxassetid://124195032304220" },
		Evento    = function()
			VisualEffectsService:clearEffects()
			local nX = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoX)
			local nY = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoY)
			local nZ = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoZ)
			if nX and nY and nZ then
				VisualEffectsService:highlightObject(nX, CONFIG.COLORES.cian)
				VisualEffectsService:highlightObject(nY, CONFIG.COLORES.naranja)
				VisualEffectsService:highlightObject(nZ, CONFIG.COLORES.verde)
				VisualEffectsService:showNodeLabel(nX, aliasX .. " →")
				VisualEffectsService:showNodeLabel(nY, "→ " .. aliasY .. " →")
				VisualEffectsService:showNodeLabel(nZ, "→ " .. aliasZ)
				VisualEffectsService:createFakeEdge(nX, nY, CONFIG.COLORES.amarillo)
				VisualEffectsService:createFakeEdge(nY, nZ, CONFIG.COLORES.amarillo)
				enfocarEntre({nX, nY, nZ}, CONFIG.CAMARA.offset_alto)
			end
		end,
		Siguiente = "Instruccion_1",
	},

	-- ============================================
	-- MISIONES
	-- ============================================

	["Instruccion_1"] = {
		Actor     = "Sistema",
		Expresion = "Bienvenida",
		Texto     = "MISIÓN: Crea la arista " .. aliasX .. " → " .. aliasY .. ".",
		Sonido    = "rbxassetid://91232241403260",
		Evento    = function()
			VisualEffectsService:clearEffects()
			local nX = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoX)
			local nY = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoY)
			if nX and nY then
				VisualEffectsService:highlightObject(nX, CONFIG.COLORES.verde)
				VisualEffectsService:highlightObject(nY, CONFIG.COLORES.azul)
				VisualEffectsService:showNodeLabel(nX, aliasX .. " (1° clic)")
				VisualEffectsService:showNodeLabel(nY, aliasY .. " (2° clic)")
				VisualEffectsService:focusCameraOn(nX, CONFIG.CAMARA.offset_medio)
				VisualEffectsService:blink(nX, 30, 1.5)
			end
		end,
		Siguiente = "Instruccion_2",
	},

	["Instruccion_2"] = {
		Actor     = "Sistema",
		Expresion = "Bienvenida",
		Texto     = "Ahora completa la cadena: " .. aliasY .. " → " .. aliasZ .. ".",
		Sonido    = "rbxassetid://76732191360053",
		Evento    = function()
			VisualEffectsService:clearEffects()
			local nX = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoX)
			local nY = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoY)
			local nZ = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoZ)
			if nX and nY and nZ then
				VisualEffectsService:highlightObject(nX, CONFIG.COLORES.verde_debil)
				VisualEffectsService:highlightObject(nY, CONFIG.COLORES.verde)
				VisualEffectsService:highlightObject(nZ, CONFIG.COLORES.azul)
				VisualEffectsService:showNodeLabel(nX, aliasX .. " ✔")
				VisualEffectsService:showNodeLabel(nY, aliasY .. " (1° clic)")
				VisualEffectsService:showNodeLabel(nZ, aliasZ .. " (2° clic)")
				enfocarEntre({nX, nY, nZ}, CONFIG.CAMARA.offset_alto)
				VisualEffectsService:blink(nY, 30, 1.5)
				task.wait(0.4)
				VisualEffectsService:blink(nZ, 30, 1.5)
			end
		end,
		Siguiente = "Pregunta_Dirigido",
	},

	-- ============================================
	-- PREGUNTA DE VALIDACIÓN
	-- ============================================

	["Pregunta_Dirigido"] = {
		Actor     = "Carlos",
		Expresion = "Sorprendido",
		Texto     = "Si solo existe la arista " .. aliasX .. " → " .. aliasY .. ", ¿puede " .. aliasY .. " enviar datos a " .. aliasX .. "?",
		Sonido    = "rbxassetid://85119928661707",
		Evento    = function()
			VisualEffectsService:clearEffects()
			local nX = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoX)
			local nY = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoY)
			if nX and nY then
				VisualEffectsService:highlightObject(nX, CONFIG.COLORES.cian)
				VisualEffectsService:highlightObject(nY, CONFIG.COLORES.naranja)
				VisualEffectsService:showNodeLabel(nX, aliasX)
				VisualEffectsService:showNodeLabel(nY, aliasY)
				VisualEffectsService:createFakeEdge(nX, nY, CONFIG.COLORES.amarillo)
				enfocarEntre({nX, nY}, CONFIG.CAMARA.offset_alto)
			end
		end,
		Opciones = {
			{ Texto = "No, la dirección no lo permite",      Siguiente = "Respuesta_Correcta_Z3"   },
			{ Texto = "Sí, las aristas son bidireccionales", Siguiente = "Respuesta_Incorrecta_Z3" },
		},
	},

	["Respuesta_Correcta_Z3"] = {
		Actor     = "Carlos",
		Expresion = "Feliz",
		Texto     = {
			"¡Correcto!",
			"En una arista dirigida, solo el origen puede enviar al destino.",
			aliasY .. " no puede usar esa arista para regresar a " .. aliasX .. ".",
		},
		Sonido    = { "rbxassetid://98229492565124", "rbxassetid://84437951272776", "rbxassetid://124195032304220" },
		Siguiente = "Cierre_Z3",
	},

	["Respuesta_Incorrecta_Z3"] = {
		Actor     = "Carlos",
		Expresion = "Serio",
		Texto     = {
			"No exactamente.",
			"En un grafo DIRIGIDO, la arista tiene un solo sentido.",
			"Solo " .. aliasX .. " puede enviar a " .. aliasY .. ", no al revés.",
		},
		Sonido    = { "rbxassetid://71817259692490", "rbxassetid://84437951272776", "rbxassetid://84784432074545" },
		Siguiente = "Cierre_Z3",
	},

	-- Nodo de cierre: limpia efectos y devuelve la cámara antes de FIN
	["Cierre_Z3"] = {
		Actor     = "Carlos",
		Expresion = "Sonriente",
		Texto     = "Ahora crea las aristas " .. aliasX .. " → " .. aliasY .. " y " .. aliasY .. " → " .. aliasZ .. " para completar la cadena dirigida.",
		Sonido    = "rbxassetid://98229492565124",
		Evento    = function()
			VisualEffectsService:clearEffects()
			VisualEffectsService:restoreCamera()
		end,
		Siguiente = "FIN",
	},
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

	if MapManager:isActive() then
		print("🗺️ Zona3_Dialogo: mapa activo — se cerrará con onDialogueStart")
	end

	if DialogueVisibilityManager then
		DialogueVisibilityManager:onDialogueStart()
	end

	local layersComplejas = DialogueGenerator.GenerarEstructura(DATA_DIALOGOS, CONFIG.SKIN_NAME)

	dialogueKitModule.CreateDialogue({
		InitialLayer = "Inicio",
		SkinName     = CONFIG.SKIN_NAME,
		Config       = script:FindFirstChild(CONFIG.SKIN_NAME .. "Config") or script,
		Layers       = layersComplejas,
		-- OnClose no es ejecutado por DialogueKit; el cleanup ocurre en Cierre_Z3.Evento
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

print("✅ Zona3_dialogo cargado")
