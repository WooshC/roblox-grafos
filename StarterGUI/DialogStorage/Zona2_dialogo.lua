-- StarterGUI/DialogStorage/Zona2_dialogo.lua
-- Zona 2: Grado de un nodo
-- Cámara cenital (top-down) para ver el patrón hub-and-spoke del grado.
-- Incluye pregunta de validación al final.

local dialogueKitModule = require(script.Parent.Parent.DialogueKit)
local DialogueGenerator  = require(script.Parent.DialogueGenerator)
local RunService         = game:GetService("RunService")

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
	ZONA_OBJETIVO = "Zona_Estacion_2",
	SKIN_NAME     = "Hotline",
	-- FIX: nombres correctos según LevelsConfig
	NODOS = {
		nodoA = "Nodo1_z2",  -- "Centro"
		nodoB = "Nodo2_z2",  -- "Vecino 1"
		nodoC = "Nodo3_z2",  -- "Vecino 2"
		nodoD = "Nodo4_z2",  -- "Vecino 3"
	},
	COLORES = {
		azul        = Color3.fromRGB(0, 170, 255),
		verde       = Color3.fromRGB(0, 255, 0),
		rojo        = Color3.fromRGB(255, 0, 0),
		amarillo    = Color3.fromRGB(255, 255, 0),
		naranja     = Color3.fromRGB(255, 165, 0),
		verde_debil = Color3.fromRGB(100, 200, 100),
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

local aliasA = LevelsConfig[0].Nodos[CONFIG.NODOS.nodoA].Alias  -- "Centro"
local aliasB = LevelsConfig[0].Nodos[CONFIG.NODOS.nodoB].Alias  -- "Vecino 1"
local aliasC = LevelsConfig[0].Nodos[CONFIG.NODOS.nodoC].Alias  -- "Vecino 2"
local aliasD = LevelsConfig[0].Nodos[CONFIG.NODOS.nodoD].Alias  -- "Vecino 3"

-- ================================================================
-- INDICADOR DE GRADO EN TIEMPO REAL
-- FIX: conexión guardada en variable de módulo, no en Attribute
-- ================================================================

local gradoIndicador = nil
local gradoConexion  = nil  -- RBXScriptConnection almacenada aquí

-- FIX: lee la carpeta Connections replicada desde el servidor
local function contarConexiones(nodoPart)
	local modelo = nodoPart and nodoPart.Parent
	if not modelo then return 0 end
	local folder = modelo:FindFirstChild("Connections")
	return folder and #folder:GetChildren() or 0
end

local function mostrarGradoEnTiempoReal(nodoPart)
	-- Limpiar indicador anterior
	if gradoConexion then gradoConexion:Disconnect(); gradoConexion = nil end
	if gradoIndicador and gradoIndicador.Parent then gradoIndicador:Destroy() end

	gradoIndicador = Instance.new("BillboardGui")
	gradoIndicador.Name          = "GradoIndicator"
	gradoIndicador.Size          = UDim2.new(0, 130, 0, 50)
	gradoIndicador.StudsOffset   = Vector3.new(0, 6, 0)
	gradoIndicador.AlwaysOnTop   = true
	gradoIndicador.Parent        = nodoPart

	local fondo = Instance.new("Frame")
	fondo.Size                   = UDim2.new(1, 0, 1, 0)
	fondo.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
	fondo.BackgroundTransparency = 0.3
	fondo.BorderSizePixel        = 2
	fondo.BorderColor3           = CONFIG.COLORES.azul
	fondo.Parent                 = gradoIndicador

	local texto = Instance.new("TextLabel")
	texto.Size                   = UDim2.new(1, 0, 1, 0)
	texto.BackgroundTransparency = 1
	texto.TextColor3             = Color3.new(1, 1, 1)
	texto.TextSize               = 22
	texto.Font                   = Enum.Font.GothamBold
	texto.Text                   = "Grado: 0"
	texto.Parent                 = fondo

	-- FIX: conexión guardada en variable de módulo
	gradoConexion = RunService.Heartbeat:Connect(function()
		if not gradoIndicador or not gradoIndicador.Parent then
			gradoConexion:Disconnect()
			gradoConexion = nil
			return
		end
		local g = contarConexiones(nodoPart)
		texto.Text = "Grado: " .. g
		if g == 0 then
			fondo.BorderColor3 = CONFIG.COLORES.rojo
		elseif g >= 3 then
			fondo.BorderColor3 = CONFIG.COLORES.verde
		else
			fondo.BorderColor3 = CONFIG.COLORES.amarillo
		end
	end)
end

local function limpiarIndicador()
	if gradoConexion then gradoConexion:Disconnect(); gradoConexion = nil end
	if gradoIndicador and gradoIndicador.Parent then
		gradoIndicador:Destroy()
		gradoIndicador = nil
	end
end

-- ================================================================
-- UTILIDAD: Centrar cámara entre dos partes, top-down
-- ================================================================

local TweenService = game:GetService("TweenService")

local function enfocarEntre(partA, partB, offset)
	if not partA or not partB then return end
	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	local mid = partA.Position:Lerp(partB.Position, 0.5)
	TweenService:Create(workspace.CurrentCamera,
		TweenInfo.new(CONFIG.CAMARA.duracion, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = CFrame.new(mid + offset, mid) }
	):Play()
end

local function enfocarCuatro(nA, nB, nC, nD, offset)
	if not nA or not nB or not nC or not nD then return end
	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	local mid = (nA.Position + nB.Position + nC.Position + nD.Position) / 4
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
			"Bienvenido a la Zona 2.",
			"Aquí aprenderás sobre el GRADO de un nodo.",
		},
		Sonido    = { "rbxassetid://82943328777335", "rbxassetid://133631096743397" },
		Evento    = function()
			local nA = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoA)
			if nA then
				VisualEffectsService:focusCameraOn(nA, CONFIG.CAMARA.offset_alto)
			end
		end,
		Siguiente = "QueEsGrado",
	},

	["QueEsGrado"] = {
		Actor     = "Carlos",
		Expresion = "Serio",
		Texto     = {
			"El GRADO de un nodo es el número de conexiones que tiene.",
			"Cuantas más aristas tiene, mayor es su grado.",
		},
		Sonido    = { "rbxassetid://85119928661707", "rbxassetid://84437951272776" },
		Evento    = function()
			VisualEffectsService:clearEffects()
			local nA = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoA)
			if nA then
				VisualEffectsService:highlightObject(nA, CONFIG.COLORES.azul)
				VisualEffectsService:showNodeLabel(nA, aliasA)
				VisualEffectsService:focusCameraOn(nA, CONFIG.CAMARA.offset_medio)
			end
		end,
		Siguiente = "EjemploGrado0",
	},

	["EjemploGrado0"] = {
		Actor     = "Carlos",
		Expresion = "Serio",
		Texto     = {
			"Si un nodo no tiene ninguna conexión, su grado es CERO.",
			"Está completamente aislado de la red.",
		},
		Sonido    = { "rbxassetid://71817259692490", "rbxassetid://127699663903662" },
		Evento    = function()
			VisualEffectsService:clearEffects()
			local nA = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoA)
			if nA then
				VisualEffectsService:highlightObject(nA, CONFIG.COLORES.rojo)
				VisualEffectsService:showNodeLabel(nA, aliasA .. " (Grado 0)")
				VisualEffectsService:focusCameraOn(nA, CONFIG.CAMARA.offset_medio)
			end
		end,
		Siguiente = "EjemploGrado1",
	},

	["EjemploGrado1"] = {
		Actor     = "Carlos",
		Expresion = "Feliz",
		Texto     = "Al conectarlo con un vecino, su grado sube a UNO.",
		Sonido    = "rbxassetid://91232241403260",
		Evento    = function()
			VisualEffectsService:clearEffects()
			local nA = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoA)
			local nB = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoB)
			if nA and nB then
				VisualEffectsService:highlightObject(nA, CONFIG.COLORES.azul)
				VisualEffectsService:highlightObject(nB, CONFIG.COLORES.azul)
				VisualEffectsService:showNodeLabel(nA, aliasA .. " (Grado 1)")
				VisualEffectsService:showNodeLabel(nB, aliasB .. " (Grado 1)")
				VisualEffectsService:createFakeEdge(nA, nB, CONFIG.COLORES.amarillo)
				enfocarEntre(nA, nB, CONFIG.CAMARA.offset_alto)
			end
		end,
		Siguiente = "GradoMultiple",
	},

	["GradoMultiple"] = {
		Actor     = "Carlos",
		Expresion = "Feliz",
		Texto     = {
			"Al añadir más vecinos, el grado sigue creciendo.",
			"Con tres vecinos conectados al " .. aliasA .. ", su grado es TRES.",
		},
		Sonido    = { "rbxassetid://84784432074545", "rbxassetid://87649995326832" },
		Evento    = function()
			VisualEffectsService:clearEffects()
			local nA = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoA)
			local nB = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoB)
			local nC = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoC)
			local nD = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoD)
			if nA and nB and nC and nD then
				VisualEffectsService:highlightObject(nA, CONFIG.COLORES.naranja)
				VisualEffectsService:createFakeEdge(nA, nB, CONFIG.COLORES.amarillo)
				VisualEffectsService:createFakeEdge(nA, nC, CONFIG.COLORES.amarillo)
				VisualEffectsService:createFakeEdge(nA, nD, CONFIG.COLORES.amarillo)
				VisualEffectsService:showNodeLabel(nA, aliasA .. " (Grado 3)")
				VisualEffectsService:showNodeLabel(nB, aliasB)
				VisualEffectsService:showNodeLabel(nC, aliasC)
				VisualEffectsService:showNodeLabel(nD, aliasD)
				enfocarCuatro(nA, nB, nC, nD, CONFIG.CAMARA.offset_alto)
			end
		end,
		Siguiente = "GradoEnTiempoReal",
	},

	["GradoEnTiempoReal"] = {
		Actor     = "Carlos",
		Expresion = "Feliz",
		Texto     = {
			"Este contador muestra el grado del " .. aliasA .. " en tiempo real.",
			"Cada vez que conectes un vecino, el número subirá.",
		},
		Sonido    = { "rbxassetid://98229492565124", "rbxassetid://98076423902070" },
		Evento    = function()
			VisualEffectsService:clearEffects()
			local nA = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoA)
			if nA then
				VisualEffectsService:highlightObject(nA, CONFIG.COLORES.azul)
				VisualEffectsService:focusCameraOn(nA, CONFIG.CAMARA.offset_medio)
				mostrarGradoEnTiempoReal(nA)
			end
		end,
		Siguiente = "ModoMatematico",
	},

	["ModoMatematico"] = {
		Actor     = "Carlos",
		Expresion = "Presentacion",
		Texto     = {
			"Por cierto, puedes activar el Modo Matemático desde el panel de herramientas.",
			"Verás la matriz de adyacencia de la red y los grados de cada nodo actualizándose en tiempo real.",
			"Cada conexión que hagas se reflejará ahí de inmediato.",
		},
		Sonido    = {
			"rbxassetid://98229492565124",
			"rbxassetid://84784432074545",
			"rbxassetid://87649995326832",
		},
		Siguiente = "Mision1",
	},

	-- ============================================
	-- MISIONES
	-- ============================================

	["Mision1"] = {
		Actor     = "Sistema",
		Expresion = "Bienvenida",
		Texto     = "MISIÓN: Conecta un vecino al " .. aliasA .. ". Grado objetivo: 1.",
		Sonido    = "rbxassetid://91232241403260",
		Evento    = function()
			VisualEffectsService:clearEffects()
			local nA = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoA)
			local nB = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoB)
			local nC = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoC)
			local nD = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoD)
			if nA then
				VisualEffectsService:highlightObject(nA, CONFIG.COLORES.verde)
				VisualEffectsService:showNodeLabel(nA, aliasA .. " (Objetivo: Grado 1)")
				mostrarGradoEnTiempoReal(nA)
			end
			if nB then
				VisualEffectsService:highlightObject(nB, CONFIG.COLORES.azul)
				VisualEffectsService:showNodeLabel(nB, aliasB)
				VisualEffectsService:blink(nB, 20, 2)
			end
			if nC then
				VisualEffectsService:highlightObject(nC, CONFIG.COLORES.azul)
				VisualEffectsService:showNodeLabel(nC, aliasC)
			end
			if nD then
				VisualEffectsService:highlightObject(nD, CONFIG.COLORES.azul)
				VisualEffectsService:showNodeLabel(nD, aliasD)
			end
			if nA then
				VisualEffectsService:focusCameraOn(nA, CONFIG.CAMARA.offset_alto)
			end
		end,
		Siguiente = "Mision2",
	},

	["Mision2"] = {
		Actor     = "Sistema",
		Expresion = "Bienvenida",
		Texto     = "Ahora conecta los otros dos vecinos. Grado objetivo: 3.",
		Sonido    = "rbxassetid://76732191360053",
		Evento    = function()
			local nC = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoC)
			local nD = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoD)
			if nC then VisualEffectsService:blink(nC, 25, 2) end
			task.wait(0.3)
			if nD then VisualEffectsService:blink(nD, 25, 2) end
		end,
		Siguiente = "Pregunta_Grado",
	},

	-- ============================================
	-- PREGUNTA DE VALIDACIÓN
	-- ============================================

	["Pregunta_Grado"] = {
		Actor     = "Carlos",
		Expresion = "Sorprendido",
		Texto     = "Si conectas los tres vecinos al " .. aliasA .. ", ¿cuál será su grado?",
		Sonido    = "rbxassetid://85119928661707",
		Evento    = function()
			VisualEffectsService:clearEffects()
			local nA = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoA)
			local nB = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoB)
			local nC = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoC)
			local nD = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoD)
			if nA then VisualEffectsService:highlightObject(nA, CONFIG.COLORES.naranja) end
			if nB then VisualEffectsService:highlightObject(nB, CONFIG.COLORES.azul) end
			if nC then VisualEffectsService:highlightObject(nC, CONFIG.COLORES.azul) end
			if nD then VisualEffectsService:highlightObject(nD, CONFIG.COLORES.azul) end
			if nA then VisualEffectsService:focusCameraOn(nA, CONFIG.CAMARA.offset_alto) end
		end,
		Opciones = {
			{ Texto = "Grado 3",  Siguiente = "Respuesta_Correcta"   },
			{ Texto = "Grado 1",  Siguiente = "Respuesta_Incorrecta" },
			{ Texto = "Grado 6",  Siguiente = "Respuesta_Incorrecta" },
		},
	},

	["Respuesta_Correcta"] = {
		Actor     = "Carlos",
		Expresion = "Feliz",
		Texto     = {
			"¡Exacto! El grado del " .. aliasA .. " será 3.",
			"Una arista por cada vecino conectado: tres vecinos, grado tres.",
		},
		Sonido    = { "rbxassetid://98229492565124", "rbxassetid://124195032304220" },
		Siguiente = "Cierre_Z2",
	},

	["Respuesta_Incorrecta"] = {
		Actor     = "Carlos",
		Expresion = "Serio",
		Texto     = {
			"No exactamente.",
			"El GRADO es el número total de aristas conectadas.",
			"Con tres vecinos, el " .. aliasA .. " tiene grado 3.",
		},
		Sonido    = { "rbxassetid://71817259692490", "rbxassetid://84437951272776", "rbxassetid://84784432074545" },
		Siguiente = "Cierre_Z2",
	},

	-- Nodo de cierre: limpia efectos y devuelve la cámara antes de FIN
	["Cierre_Z2"] = {
		Actor     = "Carlos",
		Expresion = "Sonriente",
		Texto     = "Ahora conecta el " .. aliasA .. " con sus tres vecinos y observa el contador de grado en tiempo real.",
		Sonido    = "rbxassetid://98229492565124",
		Evento    = function()
			limpiarIndicador()
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
		print("🗺️ Zona2_Dialogo: mapa activo — se cerrará con onDialogueStart")
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
		-- OnClose no es ejecutado por DialogueKit; el cleanup ocurre en Cierre_Z2.Evento
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

print("✅ Zona2_dialogo cargado")
