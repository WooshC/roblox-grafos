-- StarterGUI/DialogStorage/Zona3_dialogo.lua
-- Zona 3: Grafos Dirigidos
-- Enseña el concepto de arista dirigida y caminos mediante la cadena X → Y → Z.
-- Nodo W es un ejemplo de nodo aislado sin conexiones válidas.

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

local LevelsConfig  = require(game:GetService("ReplicatedStorage"):WaitForChild("LevelsConfig"))
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
		nodoX = "Nodo1_z3",  -- Nodo X: origen de la cadena
		nodoY = "Nodo2_z3",  -- Nodo Y: intermediario
		nodoZ = "Nodo3_z3",  -- Nodo Z: destino final
		nodoW = "Nodo4_z3",  -- Nodo W: aislado (sin adyacencias)
	},
	COLORES = {
		azul        = Color3.fromRGB(0, 170, 255),
		verde       = Color3.fromRGB(0, 255, 0),
		rojo        = Color3.fromRGB(255, 0, 0),
		amarillo    = Color3.fromRGB(255, 255, 0),
		naranja     = Color3.fromRGB(255, 140, 0),
		gris        = Color3.fromRGB(150, 150, 150),
		verde_debil = Color3.fromRGB(100, 200, 100),
		cian        = Color3.fromRGB(0, 255, 220),
	},
	CAMARA = {
		offset_inicio  = Vector3.new(25, 25, 25),
		offset_nodo    = Vector3.new(12, 15, 12),
		offset_cadena  = Vector3.new(0, 28, 22),
		offset_zoom    = Vector3.new(8, 10, 8),
		duracion       = 1.5,
	},
}

-- ================================================================
-- VARIABLES DINÁMICAS
-- ================================================================

local aliasX = LevelsConfig[0].Nodos[CONFIG.NODOS.nodoX].Alias -- "Nodo X"
local aliasY = LevelsConfig[0].Nodos[CONFIG.NODOS.nodoY].Alias -- "Nodo Y"
local aliasZ = LevelsConfig[0].Nodos[CONFIG.NODOS.nodoZ].Alias -- "Nodo Z"
local aliasW = LevelsConfig[0].Nodos[CONFIG.NODOS.nodoW].Alias -- "Nodo W"

-- ================================================================
-- UTILIDAD: centrar cámara entre dos nodos
-- ================================================================

local function enfocarCadenaDos(partA, partB, offset)
	if not partA or not partB then return end
	local mid    = partA.Position:Lerp(partB.Position, 0.5)
	local camera = workspace.CurrentCamera
	game:GetService("TweenService"):Create(camera,
		TweenInfo.new(CONFIG.CAMARA.duracion, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = CFrame.new(mid + offset, mid) }
	):Play()
end

local function enfocarCadenaTres(partA, partB, partC, offset)
	if not partA or not partB or not partC then return end
	local mid    = (partA.Position + partB.Position + partC.Position) / 3
	local camera = workspace.CurrentCamera
	game:GetService("TweenService"):Create(camera,
		TweenInfo.new(CONFIG.CAMARA.duracion, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = CFrame.new(mid + offset, mid) }
	):Play()
end

-- ================================================================
-- DIÁLOGOS
-- ================================================================

local DATA_DIALOGOS = {

	-- ----------------------------------------------------------
	-- PRESENTACIÓN
	-- ----------------------------------------------------------

	["Inicio"] = {
		Actor     = "Carlos",
		Expresion = "Bienvenida",
		Texto     = {
			"Bienvenido a la Zona 3.",
			"Hasta ahora conectaste nodos sin importar la dirección.",
			"Ahora aprenderás qué es un GRAFO DIRIGIDO.",
		},
		Sonido    = {
			"rbxassetid://82943328777335",
			"rbxassetid://133631096743397",
			"rbxassetid://85119928661707",
		},
		Evento = function()
			local nX = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoX)
			if nX then
				VisualEffectsService:focusCameraOn(nX, CONFIG.CAMARA.offset_inicio)
			end
		end,
		Siguiente = "QueEsDirigido",
	},

	-- ----------------------------------------------------------
	-- CONCEPTO: GRAFO DIRIGIDO
	-- ----------------------------------------------------------

	["QueEsDirigido"] = {
		Actor     = "Carlos",
		Expresion = "Serio",
		Texto     = {
			"En un grafo normal, la conexión entre A y B vale en AMBOS sentidos.",
			"En un grafo DIRIGIDO, cada arista tiene una sola dirección.",
			"Es decir: A puede ir a B, pero B no necesariamente puede ir a A.",
		},
		Sonido    = {
			"rbxassetid://84437951272776",
			"rbxassetid://71817259692490",
			"rbxassetid://84784432074545",
		},
		Evento = function()
			VisualEffectsService:clearEffects()
			local nX = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoX)
			local nY = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoY)
			if nX and nY then
				VisualEffectsService:highlightObject(nX, CONFIG.COLORES.azul)
				VisualEffectsService:highlightObject(nY, CONFIG.COLORES.naranja)
				VisualEffectsService:showNodeLabel(nX, aliasX .. "  →")
				VisualEffectsService:showNodeLabel(nY, aliasY)
				VisualEffectsService:createFakeEdge(nX, nY, CONFIG.COLORES.cian)
				enfocarCadenaDos(nX, nY, CONFIG.CAMARA.offset_cadena)
			end
		end,
		Siguiente = "DireccionImporta",
	},

	["DireccionImporta"] = {
		Actor     = "Carlos",
		Expresion = "Serio",
		Texto     = {
			"Piénsalo como una calle de un solo sentido.",
			"Si " .. aliasX .. " apunta a " .. aliasY .. ", puedes ir de X a Y.",
			"Pero NO puedes regresar de Y a X por esa misma arista.",
		},
		Sonido    = {
			"rbxassetid://87649995326832",
			"rbxassetid://120274038079160",
			"rbxassetid://127699663903662",
		},
		Evento = function()
			-- Mostrar los dos nodos; el parpadeo en X indica el origen
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
				enfocarCadenaDos(nX, nY, CONFIG.CAMARA.offset_cadena)
			end
		end,
		Siguiente = "NodoAislado",
	},

	-- ----------------------------------------------------------
	-- NODO W: AISLADO
	-- ----------------------------------------------------------

	["NodoAislado"] = {
		Actor     = "Carlos",
		Expresion = "Serio",
		Texto     = {
			"Observa este otro nodo: " .. aliasW .. ".",
			"Está completamente AISLADO.",
			"No tiene ninguna arista válida que lo conecte con los demás.",
		},
		Sonido    = {
			"rbxassetid://138764900027849",
			"rbxassetid://135325741435287",
			"rbxassetid://71817259692490",
		},
		Evento = function()
			VisualEffectsService:clearEffects()
			local nW = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoW)
			if nW then
				VisualEffectsService:highlightObject(nW, CONFIG.COLORES.rojo)
				VisualEffectsService:showNodeLabel(nW, aliasW .. " (Aislado)")
				VisualEffectsService:focusCameraOn(nW, CONFIG.CAMARA.offset_nodo)
				VisualEffectsService:blink(nW, 4, 1.5)
			end
		end,
		Siguiente = "ConceptoCamino",
	},

	-- ----------------------------------------------------------
	-- CONCEPTO: CAMINO
	-- ----------------------------------------------------------

	["ConceptoCamino"] = {
		Actor     = "Carlos",
		Expresion = "Feliz",
		Texto     = {
			"Cuando las aristas dirigidas se encadenan, forman un CAMINO.",
			"Un camino es una secuencia de nodos donde cada uno apunta al siguiente.",
		},
		Sonido    = {
			"rbxassetid://98229492565124",
			"rbxassetid://84437951272776",
		},
		Evento = function()
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
				enfocarCadenaTres(nX, nY, nZ, CONFIG.CAMARA.offset_cadena)
			end
		end,
		Siguiente = "EjemploCamino",
	},

	["EjemploCamino"] = {
		Actor     = "Carlos",
		Expresion = "Feliz",
		Texto     = {
			"Mira estos tres nodos: " .. aliasX .. ", " .. aliasY .. " y " .. aliasZ .. ".",
			aliasX .. " puede enviar a " .. aliasY .. ".",
			aliasY .. " puede enviar a " .. aliasZ .. ".",
			"La cadena completa es: " .. aliasX .. " → " .. aliasY .. " → " .. aliasZ .. ".",
		},
		Sonido    = {
			"rbxassetid://87649995326832",
			"rbxassetid://120274038079160",
			"rbxassetid://98076423902070",
			"rbxassetid://124195032304220",
		},
		Evento = function()
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
				enfocarCadenaTres(nX, nY, nZ, CONFIG.CAMARA.offset_cadena)
			end
		end,
		Siguiente = "Instruccion_1",
	},

	-- ----------------------------------------------------------
	-- MISIONES
	-- ----------------------------------------------------------

	["Instruccion_1"] = {
		Actor     = "Sistema",
		Expresion = "Arista",
		Texto     = "MISIÓN: Crea la arista dirigida  " .. aliasX .. " → " .. aliasY .. ".",
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
				VisualEffectsService:focusCameraOn(nX, CONFIG.CAMARA.offset_zoom)
				VisualEffectsService:blink(nX, 30, 1.5)
			end
		end,
		Siguiente = "Instruccion_2",
	},

	["Instruccion_2"] = {
		Actor     = "Sistema",
		Expresion = "Arista_conectada",
		Texto     = "¡Bien! Ahora completa la cadena: " .. aliasY .. " → " .. aliasZ .. ".",
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
				VisualEffectsService:focusCameraOn(nY, CONFIG.CAMARA.offset_zoom)
				VisualEffectsService:blink(nY, 30, 1.5)
				task.wait(0.4)
				VisualEffectsService:blink(nZ, 30, 1.5)
			end
		end,
		Siguiente = "Confirmacion",
	},

	-- ----------------------------------------------------------
	-- CIERRE
	-- ----------------------------------------------------------

	["Confirmacion"] = {
		Actor     = "Carlos",
		Expresion = "Feliz",
		Texto     = {
			"¡Excelente!",
			"Has construido la cadena dirigida: " .. aliasX .. " → " .. aliasY .. " → " .. aliasZ .. ".",
			"En un grafo dirigido, la información fluye en un único sentido.",
			"Este concepto es la base de los algoritmos de recorrido.",
		},
		Sonido    = {
			"rbxassetid://98229492565124",
			"rbxassetid://124195032304220",
			"rbxassetid://84437951272776",
			"rbxassetid://87649995326832",
		},
		Evento = function()
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
		print("🗺️ Zona3_Dialogo: Mapa activo — ForceCloseMap se disparará desde onDialogueStart")
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
		OnClose      = function()
			if DialogueVisibilityManager then
				DialogueVisibilityManager:onDialogueEnd()
			end
			print("✅ Zona3_Dialogo: Diálogo terminado — recursos restaurados")
		end,
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
