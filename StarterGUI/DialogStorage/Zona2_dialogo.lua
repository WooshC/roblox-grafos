-- StarterGUI/DialogStorage/Zona2_dialogo.lua
-- Diálogo para la Zona 2: Explicación del grado de un nodo.

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

local LevelsConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("LevelsConfig"))
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
		nodoA = "Nodo1_z2",
		nodoB = "Nodo2_z2",
		nodoC = "Nodo3_z2",
		nodoD = "Nodo4_z2",
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
		offset_inicio = Vector3.new(22, 22, 22),
		offset_nodo   = Vector3.new(15, 18, 15),
		offset_arista = Vector3.new(0, 25, 20),
		offset_grado  = Vector3.new(10, 15, 10),
		offset_zoom   = Vector3.new(8, 10, 8),
		duracion      = 1.5,
	},
}

-- ================================================================
-- VARIABLES DINÁMICAS
-- ================================================================

local aliasA = LevelsConfig[0].Nodos[CONFIG.NODOS.nodoA].Alias
local aliasB = LevelsConfig[0].Nodos[CONFIG.NODOS.nodoB].Alias
local aliasC = LevelsConfig[0].Nodos[CONFIG.NODOS.nodoC].Alias
local aliasD = LevelsConfig[0].Nodos[CONFIG.NODOS.nodoD].Alias

-- FIX: conexión del indicador guardada a nivel de módulo (no en Attribute)
local gradoIndicador = nil
local gradoConexion  = nil

-- ================================================================
-- UTILIDADES
-- ================================================================

-- FIX: cuenta hijos de la carpeta "Connections" replicada desde el servidor
local function contarConexiones(nodoPart)
	local modelo = nodoPart.Parent -- BasePart → Modelo
	if not modelo then return 0 end
	local folder = modelo:FindFirstChild("Connections")
	if not folder then return 0 end
	return #folder:GetChildren()
end

-- ================================================================
-- INDICADOR DE GRADO EN TIEMPO REAL
-- ================================================================

local function mostrarGradoEnTiempoReal(nodoPart, nodoAlias)
	-- Limpiar indicador anterior
	if gradoConexion then
		gradoConexion:Disconnect()
		gradoConexion = nil
	end
	if gradoIndicador and gradoIndicador.Parent then
		gradoIndicador:Destroy()
	end

	-- nodoPart es un BasePart (devuelto por findNodeByName)
	local base = nodoPart

	gradoIndicador = Instance.new("BillboardGui")
	gradoIndicador.Name    = "GradoIndicator"
	gradoIndicador.Size    = UDim2.new(0, 130, 0, 50)
	gradoIndicador.StudsOffset = Vector3.new(0, 6, 0)
	gradoIndicador.AlwaysOnTop = true
	gradoIndicador.Parent  = base

	local fondo = Instance.new("Frame")
	fondo.Size                 = UDim2.new(1, 0, 1, 0)
	fondo.BackgroundColor3     = Color3.fromRGB(0, 0, 0)
	fondo.BackgroundTransparency = 0.3
	fondo.BorderSizePixel      = 2
	fondo.BorderColor3         = CONFIG.COLORES.azul
	fondo.Parent               = gradoIndicador

	local texto = Instance.new("TextLabel")
	texto.Size                 = UDim2.new(1, 0, 1, 0)
	texto.BackgroundTransparency = 1
	texto.TextColor3           = Color3.new(1, 1, 1)
	texto.TextSize             = 22
	texto.Font                 = Enum.Font.GothamBold
	texto.Text                 = "Grado: 0"
	texto.Parent               = fondo

	-- FIX: conexión guardada en variable de módulo
	gradoConexion = game:GetService("RunService").Heartbeat:Connect(function()
		if not gradoIndicador or not gradoIndicador.Parent then
			gradoConexion:Disconnect()
			gradoConexion = nil
			return
		end

		local grado = contarConexiones(nodoPart)
		texto.Text = "Grado: " .. grado

		if grado == 0 then
			fondo.BorderColor3 = CONFIG.COLORES.rojo
		elseif grado >= 3 then
			fondo.BorderColor3 = CONFIG.COLORES.verde
		else
			fondo.BorderColor3 = CONFIG.COLORES.amarillo
		end
	end)
end

local function limpiarIndicador()
	if gradoConexion then
		gradoConexion:Disconnect()
		gradoConexion = nil
	end
	if gradoIndicador and gradoIndicador.Parent then
		gradoIndicador:Destroy()
		gradoIndicador = nil
	end
end

-- ================================================================
-- DIÁLOGOS
-- ================================================================

local DATA_DIALOGOS = {

	["Inicio"] = {
		Actor     = "Carlos",
		Expresion = "Bienvenida",
		Texto     = {
			"Bienvenido a la Zona 2.",
			"Ahora aprenderás sobre el GRADO de un nodo.",
		},
		Sonido    = { "rbxassetid://82943328777335", "rbxassetid://133631096743397" },
		Evento    = function()
			local nodoA = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoA)
			if nodoA then
				VisualEffectsService:focusCameraOn(nodoA, CONFIG.CAMARA.offset_inicio)
			end
		end,
		Siguiente = "QueEsGrado",
	},

	["QueEsGrado"] = {
		Actor     = "Carlos",
		Expresion = "Serio",
		Texto     = {
			"El GRADO de un nodo es el número de conexiones que tiene.",
			"Básicamente, cuántas aristas salen de él.",
		},
		Sonido    = { "rbxassetid://85119928661707", "rbxassetid://84437951272776" },
		Evento    = function()
			VisualEffectsService:clearEffects()
			local nodoA = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoA)
			if nodoA then
				VisualEffectsService:highlightObject(nodoA, CONFIG.COLORES.azul)
				VisualEffectsService:showNodeLabel(nodoA, aliasA)
				VisualEffectsService:focusCameraOn(nodoA, CONFIG.CAMARA.offset_nodo)
			end
		end,
		Siguiente = "EjemploGrado0",
	},

	["EjemploGrado0"] = {
		Actor     = "Carlos",
		Expresion = "Serio",
		Texto     = {
			"Por ejemplo, si un nodo no tiene conexiones...",
			"su grado es CERO. Está aislado.",
		},
		Sonido    = { "rbxassetid://71817259692490", "rbxassetid://127699663903662" },
		Evento    = function()
			VisualEffectsService:clearEffects()
			local nodoA = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoA)
			if nodoA then
				VisualEffectsService:highlightObject(nodoA, CONFIG.COLORES.rojo)
				VisualEffectsService:showNodeLabel(nodoA, aliasA .. " (Grado 0)")
				VisualEffectsService:focusCameraOn(nodoA, CONFIG.CAMARA.offset_grado)
			end
		end,
		Siguiente = "EjemploGrado1",
	},

	["EjemploGrado1"] = {
		Actor     = "Carlos",
		Expresion = "Feliz",
		Texto     = "Si lo conectas a otro nodo, su grado será UNO.",
		Sonido    = "rbxassetid://91232241403260",
		Evento    = function()
			VisualEffectsService:clearEffects()
			local nodoA = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoA)
			local nodoB = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoB)
			if nodoA and nodoB then
				VisualEffectsService:highlightObject(nodoA, CONFIG.COLORES.azul)
				VisualEffectsService:highlightObject(nodoB, CONFIG.COLORES.azul)
				VisualEffectsService:showNodeLabel(nodoA, aliasA .. " (Grado 1)")
				VisualEffectsService:showNodeLabel(nodoB, aliasB .. " (Grado 1)")
				VisualEffectsService:createFakeEdge(nodoA, nodoB, CONFIG.COLORES.amarillo)

				local midPoint = nodoA.Position:Lerp(nodoB.Position, 0.5)
				local camera   = workspace.CurrentCamera
				game:GetService("TweenService"):Create(camera,
					TweenInfo.new(CONFIG.CAMARA.duracion, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ CFrame = CFrame.new(midPoint + CONFIG.CAMARA.offset_arista, midPoint) }
				):Play()
			end
		end,
		Siguiente = "GradoMultiple",
	},

	["GradoMultiple"] = {
		Actor     = "Carlos",
		Expresion = "Feliz",
		Texto     = {
			"Y si conectas más nodos, el grado aumenta.",
			"El grado puede ser cualquier número: 2, 3, 4…",
			"Mientras más conexiones, mayor es el grado.",
		},
		Sonido    = { "rbxassetid://84784432074545", "rbxassetid://87649995326832", "rbxassetid://120274038079160" },
		Evento    = function()
			VisualEffectsService:clearEffects()
			local nodoA = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoA)
			local nodoB = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoB)
			local nodoC = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoC)
			local nodoD = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoD)
			if nodoA and nodoB and nodoC and nodoD then
				VisualEffectsService:highlightObject(nodoA, CONFIG.COLORES.naranja)
				VisualEffectsService:createFakeEdge(nodoA, nodoB, CONFIG.COLORES.amarillo)
				VisualEffectsService:createFakeEdge(nodoA, nodoC, CONFIG.COLORES.amarillo)
				VisualEffectsService:createFakeEdge(nodoA, nodoD, CONFIG.COLORES.amarillo)
				VisualEffectsService:showNodeLabel(nodoA, aliasA .. " (Grado 3)")
				VisualEffectsService:showNodeLabel(nodoB, aliasB)
				VisualEffectsService:showNodeLabel(nodoC, aliasC)
				VisualEffectsService:showNodeLabel(nodoD, aliasD)
				VisualEffectsService:focusCameraOn(nodoA, CONFIG.CAMARA.offset_grado)
			end
		end,
		Siguiente = "GradoEnTiempoReal",
	},

	["GradoEnTiempoReal"] = {
		Actor     = "Carlos",
		Expresion = "Feliz",
		Texto     = {
			"Observa cómo el grado cambia en tiempo real.",
			"Cada nueva conexión que hagas incrementará el contador.",
		},
		Sonido    = { "rbxassetid://98229492565124", "rbxassetid://98076423902070" },
		Evento    = function()
			VisualEffectsService:clearEffects()
			local nodoA = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoA)
			if nodoA then
				VisualEffectsService:highlightObject(nodoA, CONFIG.COLORES.azul)
				VisualEffectsService:focusCameraOn(nodoA, CONFIG.CAMARA.offset_zoom)
				mostrarGradoEnTiempoReal(nodoA, aliasA)
			end
		end,
		Siguiente = "Mision1",
	},

	["Mision1"] = {
		Actor     = "Sistema",
		Expresion = "NodoPrincipal",
		Texto     = "MISIÓN: Haz que el nodo " .. aliasA .. " tenga GRADO 1.",
		Sonido    = "rbxassetid://91232241403260",
		Evento    = function()
			VisualEffectsService:clearEffects()
			local nodoA = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoA)
			local nodoB = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoB)
			local nodoC = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoC)
			local nodoD = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoD)
			if nodoA and nodoB and nodoC and nodoD then
				VisualEffectsService:highlightObject(nodoA, CONFIG.COLORES.verde)
				VisualEffectsService:highlightObject(nodoB, CONFIG.COLORES.azul)
				VisualEffectsService:highlightObject(nodoC, CONFIG.COLORES.azul)
				VisualEffectsService:highlightObject(nodoD, CONFIG.COLORES.azul)
				VisualEffectsService:showNodeLabel(nodoA, aliasA .. " (Objetivo: Grado 1)")
				VisualEffectsService:showNodeLabel(nodoB, aliasB)
				VisualEffectsService:showNodeLabel(nodoC, aliasC)
				VisualEffectsService:showNodeLabel(nodoD, aliasD)
				mostrarGradoEnTiempoReal(nodoA, aliasA)

				local midPoint = nodoA.Position:Lerp(nodoD.Position, 0.5)
				local camera   = workspace.CurrentCamera
				game:GetService("TweenService"):Create(camera,
					TweenInfo.new(CONFIG.CAMARA.duracion, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ CFrame = CFrame.new(midPoint + Vector3.new(0, 25, 25), midPoint) }
				):Play()
			end
		end,
		Siguiente = "Mision2",
	},

	["Mision2"] = {
		Actor     = "Sistema",
		Expresion = "NodoPrincipal",
		Texto     = "Ahora lleva el grado de " .. aliasA .. " hasta GRADO 3.",
		Sonido    = "rbxassetid://76732191360053",
		Evento    = function()
			local nodoB = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoB)
			local nodoC = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoC)
			local nodoD = VisualEffectsService:findNodeByName(CONFIG.NODOS.nodoD)
			if nodoB then VisualEffectsService:blink(nodoB, 20, 2) end
			task.wait(0.3)
			if nodoC then VisualEffectsService:blink(nodoC, 20, 2) end
			task.wait(0.3)
			if nodoD then VisualEffectsService:blink(nodoD, 20, 2) end
		end,
		Siguiente = "ExplicacionFinal",
	},

	["ExplicacionFinal"] = {
		Actor     = "Carlos",
		Expresion = "Feliz",
		Texto     = {
			"¡Excelente!",
			"Has aprendido que el GRADO es el número de conexiones de un nodo.",
			"Este concepto es fundamental en teoría de grafos.",
		},
		Sonido    = { "rbxassetid://98229492565124", "rbxassetid://84437951272776", "rbxassetid://124195032304220" },
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
		print("🗺️ Zona2_Dialogo: Mapa activo — ForceCloseMap se disparará desde onDialogueStart")
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
			limpiarIndicador()
			if DialogueVisibilityManager then
				DialogueVisibilityManager:onDialogueEnd()
			end
			print("✅ Zona2_Dialogo: Diálogo terminado — recursos restaurados")
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

print("✅ Zona2_dialogo cargado")
