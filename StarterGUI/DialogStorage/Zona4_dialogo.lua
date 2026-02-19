-- StarterGUI/DialogStorage/Zona4_dialogo.lua
-- Zona 4: Conectividad — Grafo Conexo

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
	ZONA_OBJETIVO = "Zona_Estacion_4",
	SKIN_NAME     = "Hotline",
	NODOS = {
		nodo1 = "Nodo1_z4",
		nodo2 = "Nodo2_z4",
		nodo3 = "Nodo3_z4",
		nodo4 = "Nodo4_z4",
	},
	COLORES = {
		azul     = Color3.fromRGB(0, 170, 255),
		verde    = Color3.fromRGB(0, 255, 0),
		rojo     = Color3.fromRGB(255, 0, 0),
		amarillo = Color3.fromRGB(255, 255, 0),
		naranja  = Color3.fromRGB(255, 140, 0),
		cian     = Color3.fromRGB(0, 255, 220),
	},
	CAMARA = {
		offset_alto  = Vector3.new(18, 40, 18),
		offset_medio = Vector3.new(12, 28, 12),
		offset_cerca = Vector3.new(10, 20, 10),
		duracion     = 1.5,
	},
}

-- ================================================================
-- VARIABLES DINÁMICAS
-- ================================================================

local alias1 = LevelsConfig[0].Nodos[CONFIG.NODOS.nodo1].Alias
local alias2 = LevelsConfig[0].Nodos[CONFIG.NODOS.nodo2].Alias
local alias3 = LevelsConfig[0].Nodos[CONFIG.NODOS.nodo3].Alias
local alias4 = LevelsConfig[0].Nodos[CONFIG.NODOS.nodo4].Alias

-- ================================================================
-- UTILIDAD: Cámara centrada entre lista de partes
-- Usa focusCameraOn en el primer nodo para guardar originalCameraType
-- y así garantizar que restoreCamera() funcione.
-- ================================================================

local TweenService = game:GetService("TweenService")

local function enfocarEntre(partList, offset)
	if not partList or #partList == 0 then return end

	-- Primer nodo: guardar estado de cámara vía focusCameraOn
	VisualEffectsService:focusCameraOn(partList[1], offset)

	if #partList == 1 then return end

	-- Mover al centroide real del grupo tras un pequeño delay
	task.delay(0.05, function()
		local sum = Vector3.new(0, 0, 0)
		for _, p in ipairs(partList) do sum = sum + p.Position end
		local mid = sum / #partList
		TweenService:Create(workspace.CurrentCamera,
			TweenInfo.new(CONFIG.CAMARA.duracion, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ CFrame = CFrame.new(mid + offset, mid) }
		):Play()
	end)
end

-- ================================================================
-- DIÁLOGOS
-- ================================================================

local DATA_DIALOGOS = {

	-- ============================================
	-- BLOQUE 1: ¿Qué es un grafo CONEXO?
	-- ============================================

	["Inicio"] = {
		Actor     = "Carlos",
		Expresion = "Feliz",
		Texto     = {
			"Bienvenido a la Zona 4.",
			"Aquí aprenderás la propiedad más global de un grafo: la CONECTIVIDAD.",
		},
		Sonido = {
			"rbxassetid://82943328777335",
			"rbxassetid://133631096743397",
		},
		Evento = function()
			local n1 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo1)
			local n2 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo2)
			local n3 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo3)
			local n4 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo4)
			local lista = {}
			for _, n in ipairs({n1, n2, n3, n4}) do
				if n then table.insert(lista, n) end
			end
			enfocarEntre(lista, CONFIG.CAMARA.offset_alto)
		end,
		Siguiente = "GrafoConexo",
	},

	["GrafoConexo"] = {
		Actor     = "Carlos",
		Expresion = "Serio",
		Texto     = {
			"Un grafo es CONEXO cuando desde cualquier nodo puedes llegar a cualquier otro.",
			"No importa el camino ni cuántos saltos; solo importa que sea posible.",
			"Si un nodo queda sin camino hacia los demás, el grafo ya NO es conexo.",
		},
		Sonido = {
			"rbxassetid://84437951272776",
			"rbxassetid://87649995326832",
			"rbxassetid://124195032304220",
		},
		Evento = function()
			VisualEffectsService:clearEffects()
			local n1 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo1)
			local n2 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo2)
			local n3 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo3)
			local n4 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo4)
			-- n1, n2, n3 conectados (cian) — n4 aislado (rojo, parpadea)
			if n1 then
				VisualEffectsService:highlightObject(n1, CONFIG.COLORES.cian)
				VisualEffectsService:showNodeLabel(n1, alias1)
			end
			if n2 then
				VisualEffectsService:highlightObject(n2, CONFIG.COLORES.cian)
				VisualEffectsService:showNodeLabel(n2, alias2)
			end
			if n3 then
				VisualEffectsService:highlightObject(n3, CONFIG.COLORES.cian)
				VisualEffectsService:showNodeLabel(n3, alias3)
			end
			if n4 then
				VisualEffectsService:highlightObject(n4, CONFIG.COLORES.rojo)
				VisualEffectsService:showNodeLabel(n4, alias4 .. " (aislado)")
				VisualEffectsService:blink(n4, 6, 2)
			end
			if n1 and n2 then VisualEffectsService:createFakeEdge(n1, n2, CONFIG.COLORES.cian) end
			if n2 and n3 then VisualEffectsService:createFakeEdge(n2, n3, CONFIG.COLORES.cian) end
			local lista = {}
			for _, n in ipairs({n1, n2, n3, n4}) do
				if n then table.insert(lista, n) end
			end
			enfocarEntre(lista, CONFIG.CAMARA.offset_alto)
		end,
		Siguiente = "Instruccion_1",
	},

	-- ============================================
	-- MISIÓN
	-- ============================================

	["Instruccion_1"] = {
		Actor     = "Sistema",
		Expresion = "Bienvenida",
		Texto     = "MISIÓN: Construye un grafo CONEXO conectando todos los nodos de la zona.",
		Sonido    = "rbxassetid://91232241403260",
		Evento = function()
			VisualEffectsService:clearEffects()
			local n1 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo1)
			local n2 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo2)
			local n3 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo3)
			local n4 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo4)
			if n1 then
				VisualEffectsService:highlightObject(n1, CONFIG.COLORES.verde)
				VisualEffectsService:showNodeLabel(n1, alias1)
				VisualEffectsService:blink(n1, 30, 1.5)
			end
			if n2 then
				VisualEffectsService:highlightObject(n2, CONFIG.COLORES.azul)
				VisualEffectsService:showNodeLabel(n2, alias2)
				VisualEffectsService:blink(n2, 30, 1.5)
			end
			if n3 then
				VisualEffectsService:highlightObject(n3, CONFIG.COLORES.naranja)
				VisualEffectsService:showNodeLabel(n3, alias3)
				VisualEffectsService:blink(n3, 30, 1.5)
			end
			if n4 then
				VisualEffectsService:highlightObject(n4, CONFIG.COLORES.cian)
				VisualEffectsService:showNodeLabel(n4, alias4)
				VisualEffectsService:blink(n4, 30, 1.5)
			end
			local lista = {}
			for _, n in ipairs({n1, n2, n3, n4}) do
				if n then table.insert(lista, n) end
			end
			enfocarEntre(lista, CONFIG.CAMARA.offset_alto)
		end,
		Siguiente = "Pregunta_Conexo",
	},

	-- ============================================
	-- PREGUNTA DE VALIDACIÓN
	-- ============================================

	["Pregunta_Conexo"] = {
		Actor     = "Carlos",
		Expresion = "Sorprendido",
		Texto     = "Tienes " .. alias1 .. "—" .. alias2 .. "—" .. alias3 .. ", pero " .. alias4 .. " no tiene ninguna conexión. ¿Es conexo ese grafo?",
		Sonido    = "rbxassetid://85119928661707",
		Evento = function()
			VisualEffectsService:clearEffects()
			local n1 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo1)
			local n2 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo2)
			local n3 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo3)
			local n4 = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodo4)
			if n1 then
				VisualEffectsService:highlightObject(n1, CONFIG.COLORES.cian)
				VisualEffectsService:showNodeLabel(n1, alias1)
			end
			if n2 then
				VisualEffectsService:highlightObject(n2, CONFIG.COLORES.cian)
				VisualEffectsService:showNodeLabel(n2, alias2)
			end
			if n3 then
				VisualEffectsService:highlightObject(n3, CONFIG.COLORES.cian)
				VisualEffectsService:showNodeLabel(n3, alias3)
			end
			if n4 then
				VisualEffectsService:highlightObject(n4, CONFIG.COLORES.rojo)
				VisualEffectsService:showNodeLabel(n4, alias4 .. " (sin conexión)")
				VisualEffectsService:blink(n4, 8, 2)
			end
			if n1 and n2 then VisualEffectsService:createFakeEdge(n1, n2, CONFIG.COLORES.amarillo) end
			if n2 and n3 then VisualEffectsService:createFakeEdge(n2, n3, CONFIG.COLORES.amarillo) end
			local lista = {}
			for _, n in ipairs({n1, n2, n3, n4}) do
				if n then table.insert(lista, n) end
			end
			enfocarEntre(lista, CONFIG.CAMARA.offset_alto)
		end,
		Opciones = {
			{ Texto = "No — " .. alias4 .. " está aislado",                                          Siguiente = "Respuesta_Correcta_Z4"   },
			{ Texto = "Sí — hay caminos entre " .. alias1 .. ", " .. alias2 .. " y " .. alias3,      Siguiente = "Respuesta_Incorrecta_Z4" },
		},
	},

	["Respuesta_Correcta_Z4"] = {
		Actor     = "Carlos",
		Expresion = "Feliz",
		Texto     = {
			"¡Correcto!",
			"El grafo no es conexo porque " .. alias4 .. " no tiene camino hacia los demás.",
			"Para que sea conexo, TODOS los nodos deben poder alcanzarse entre sí.",
		},
		Sonido = {
			"rbxassetid://98229492565124",
			"rbxassetid://84437951272776",
			"rbxassetid://124195032304220",
		},
		Siguiente = "Cierre_Z4",
	},

	["Respuesta_Incorrecta_Z4"] = {
		Actor     = "Carlos",
		Expresion = "Serio",
		Texto     = {
			"No exactamente.",
			"Que " .. alias1 .. ", " .. alias2 .. " y " .. alias3 .. " estén conectados no es suficiente.",
			alias4 .. " está aislado, así que el grafo completo NO es conexo.",
		},
		Sonido = {
			"rbxassetid://71817259692490",
			"rbxassetid://84437951272776",
			"rbxassetid://84784432074545",
		},
		Siguiente = "Cierre_Z4",
	},

	-- Nodo de cierre: limpia efectos y RESTAURA CÁMARA al jugador
	["Cierre_Z4"] = {
		Actor     = "Carlos",
		Expresion = "Sonriente",
		Texto     = "Conecta todos los nodos para que el grafo sea CONEXO. ¡Ninguno puede quedar aislado!",
		Sonido    = "rbxassetid://98229492565124",
		Evento    = function()
			VisualEffectsService:clearEffects()
			-- Forzar CameraType = Custom antes de restoreCamera para garantizar vuelta al jugador
			workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
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

	local player = game:GetService("Players").LocalPlayer
	if not player.Character then return end

	yaSeMostro = true
	print("✅ " .. CONFIG.ZONA_OBJETIVO .. " detectada — iniciando diálogo")

	if MapManager:isActive() then
		print("🗺️ Zona4_Dialogo: mapa activo — se cerrará con onDialogueStart")
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
	})
end

local player = game:GetService("Players").LocalPlayer
player:GetAttributeChangedSignal("CurrentZone"):Connect(function()
	checkZone(player:GetAttribute("CurrentZone"))
end)

task.delay(1, function()
	local zona = player:GetAttribute("CurrentZone")
	if zona then checkZone(zona) end
end)

print("✅ Zona4_dialogo cargado")
