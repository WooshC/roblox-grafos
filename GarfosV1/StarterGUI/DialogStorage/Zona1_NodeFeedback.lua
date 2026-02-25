-- Zona1_NodeFeedback.lua
-- Muestra retroalimentación de diálogo al seleccionar nodos en la Zona 1.
-- Usa VisualEffectsService para todos los efectos visuales (billboard nodo, arista).

local dialogueKitModule = require(script.Parent.Parent.DialogueKit)
local DialogueGenerator  = require(script.Parent.DialogueGenerator)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LevelsConfig      = require(ReplicatedStorage:WaitForChild("LevelsConfig"))

local VisualEffectsService = require(
	game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
		:WaitForChild("Cliente"):WaitForChild("Services"):WaitForChild("VisualEffectsService")
)

local DialogueVisibilityManager = require(
	ReplicatedStorage:WaitForChild("DialogueVisibilityManager", 5)
)

-- ================================================================
-- CONFIG PRINCIPAL
-- ================================================================
local CONFIG = {
	NIVEL         = 0,
	ZONA_OBJETIVO = "Zona_Estacion_1",
	SKIN_NAME     = "Hotline",
	NODO_A        = "Nodo1_z1",   -- Nombre interno primer nodo
	NODO_B        = "Nodo2_z1",   -- Nombre interno segundo nodo

	COLORES = {
		azul        = Color3.fromRGB(0, 170, 255),
		amarillo    = Color3.fromRGB(255, 255, 0),
	},

	-- ── Billboard sobre el NODO adyacente ─────────────────────────────────────
	-- Usa VisualEffectsService:highlightObject + showNodeLabel + blink
	BILLBOARD_NODO = {
		ACTIVO      = true,
		COLOR       = Color3.fromRGB(0, 170, 255),  -- Color del highlight
		BLINK_VECES = 30,
		BLINK_VEL   = 1,
	},

	-- ── Efecto sobre la ARISTA (se queda al completar la conexión) ────────────
	-- Usa VisualEffectsService:createFakeEdge + showNodeLabel en ambos nodos
	EFECTO_ARISTA = {
		ACTIVO      = true,
		COLOR       = Color3.fromRGB(255, 255, 0),  -- Color de la arista falsa
		-- Etiqueta que aparece sobre cada nodo al completar la conexión
		LABEL_A     = "Nodo 1 ⬤",
		LABEL_B     = "Nodo 2 ⬤",
	},

	-- ── Diálogos ──────────────────────────────────────────────────────────────
	-- Tokens en DIALOGO_NODO:     {alias}, {aliasAdyacente}
	-- Tokens en DIALOGO_CONEXION: {aliasA}, {aliasB}
	DIALOGO_NODO = {
		Actor     = "Carlos",
		Expresion = "Feliz",
		Texto = {
			"Correcto, has seleccionado el nodo {alias}.",
			"El nodo adyacente ({aliasAdyacente}) se ha resaltado en azul.",
			"Ahora selecciónalo para crear una arista.",
		},
		Sonido = {
			"rbxassetid://98229492565124",
			"rbxassetid://84437951272776",
			"rbxassetid://124195032304220",
		},
	},

	DIALOGO_CONEXION = {
		Actor     = "Carlos",
		Expresion = "Feliz",
		Texto     = "¡Bien hecho! Has creado la arista entre {aliasA} y {aliasB}.",
		Sonido    = "rbxassetid://98229492565124",
	},
}

-- ================================================================
-- FLAGS DE UN SOLO DISPARO
-- ================================================================
local feedbackNodoMostrado     = false
local feedbackConexionMostrado = false

-- ================================================================
-- HELPERS: LevelsConfig
-- ================================================================

local function getAlias(nombreInterno)
	local nodoData = LevelsConfig[CONFIG.NIVEL].Nodos[nombreInterno]
	return (nodoData and nodoData.Alias) or nombreInterno
end

-- Reemplaza {clave} en un string
local function fillTemplate(texto, tokens)
	return (texto:gsub("{(%w+)}", tokens))
end

-- Aplica fillTemplate a string o tabla de strings
local function applyTokens(textoOrTabla, tokens)
	if type(textoOrTabla) == "string" then
		return fillTemplate(textoOrTabla, tokens)
	elseif type(textoOrTabla) == "table" then
		local resultado = {}
		for _, linea in ipairs(textoOrTabla) do
			table.insert(resultado, fillTemplate(linea, tokens))
		end
		return resultado
	end
	return textoOrTabla
end

-- ================================================================
-- EFECTOS VISUALES (vía VisualEffectsService)
-- ================================================================

-- Resalta el nodo adyacente con highlight + label + blink
local function mostrarEfectoNodo(nombreInterno)
	if not CONFIG.BILLBOARD_NODO.ACTIVO then return end

	local nodo = VisualEffectsService:findNodeByName(nombreInterno)
	if not nodo then
		warn("⚠️ Zona1_NodeFeedback: findNodeByName no encontró '" .. nombreInterno .. "'")
		return
	end

	local cfg   = CONFIG.BILLBOARD_NODO
	local alias = getAlias(nombreInterno)

	VisualEffectsService:highlightObject(nodo, cfg.COLOR)
	VisualEffectsService:showNodeLabel(nodo, alias)
	VisualEffectsService:blink(nodo, cfg.BLINK_VECES, cfg.BLINK_VEL)

	print("✅ Efecto NODO sobre '" .. nombreInterno .. "' (" .. alias .. ")")
end

-- Crea la arista falsa persistente entre los dos nodos y labels sobre ellos
local function mostrarEfectoArista()
	if not CONFIG.EFECTO_ARISTA.ACTIVO then return end

	local n1 = VisualEffectsService:findNodeByName(CONFIG.NODO_A)
	local n2 = VisualEffectsService:findNodeByName(CONFIG.NODO_B)
	if not n1 or not n2 then
		warn("⚠️ Zona1_NodeFeedback: no se encontraron nodos para la arista")
		return
	end

	local cfg = CONFIG.EFECTO_ARISTA

	-- Arista visual (reutiliza el mismo método que usa Zona1_dialogo)
	VisualEffectsService:createFakeEdge(n1, n2, cfg.COLOR)

	-- Labels sobre ambos nodos para contextualizar la conexión
	VisualEffectsService:showNodeLabel(n1, getAlias(CONFIG.NODO_A))
	VisualEffectsService:showNodeLabel(n2, getAlias(CONFIG.NODO_B))

	-- Highlight suave en azul para remarcar que están conectados
	VisualEffectsService:highlightObject(n1, CONFIG.COLORES.azul)
	VisualEffectsService:highlightObject(n2, CONFIG.COLORES.azul)

	print("✅ Efecto ARISTA creado entre '" .. CONFIG.NODO_A .. "' y '" .. CONFIG.NODO_B .. "'")
end

-- Limpia los efectos del nodo adyacente (sin tocar la arista)
local function limpiarEfectoNodo()
	local nodo = VisualEffectsService:findNodeByName(
		(not feedbackConexionMostrado) and CONFIG.NODO_B or CONFIG.NODO_A
	)
	-- clearEffects limpia todo; aquí solo lo llamamos antes de crear la arista
	-- para no dejar el highlight del nodo flotando
	VisualEffectsService:clearEffects()
end

-- ================================================================
-- HELPERS DE DIÁLOGO
-- ================================================================

local function esperarKitLibre()
	while DialogueVisibilityManager:isActive() do
		task.wait(0.2)
	end
	task.wait(1.0)
end

local function mostrarFeedback(data, initialLayer)
	task.spawn(function()
		esperarKitLibre()
		local layers = DialogueGenerator.GenerarEstructura(data, CONFIG.SKIN_NAME)
		dialogueKitModule.CreateDialogue({
			InitialLayer = initialLayer,
			SkinName     = CONFIG.SKIN_NAME,
			Config       = script,
			Layers       = layers,
		})
	end)
end

-- ================================================================
-- LISTENER DE SELECCIÓN DE NODOS
-- ================================================================

task.spawn(function()
	local Remotes     = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes")
	local notifyEvent = Remotes:WaitForChild("NotificarSeleccionNodo", 30)

	if not notifyEvent then
		warn("❌ Zona1_NodeFeedback: NotificarSeleccionNodo no encontrado (timeout)")
		return
	end

	notifyEvent.OnClientEvent:Connect(function(tipo, nombreNodo)
		local localPlayer = game:GetService("Players").LocalPlayer
		if localPlayer:GetAttribute("CurrentZone") ~= CONFIG.ZONA_OBJETIVO then return end

		-- ── Primer nodo seleccionado ──────────────────────────────────────
		if tipo == "NodoSeleccionado" and not feedbackNodoMostrado then
			feedbackNodoMostrado = true

			local aliasSeleccionado = getAlias(nombreNodo)
			local nodoAdyacente     = (nombreNodo == CONFIG.NODO_A) and CONFIG.NODO_B or CONFIG.NODO_A
			local aliasAdyacente    = getAlias(nodoAdyacente)

			-- Resaltar el nodo adyacente con highlight + label + blink
			mostrarEfectoNodo(nodoAdyacente)

			-- Diálogo con aliases reales de LevelsConfig
			local cfg    = CONFIG.DIALOGO_NODO
			local tokens = { alias = aliasSeleccionado, aliasAdyacente = aliasAdyacente }

			mostrarFeedback({
				["FeedbackNodo"] = {
					Actor     = cfg.Actor,
					Expresion = cfg.Expresion,
					Texto     = applyTokens(cfg.Texto, tokens),
					Sonido    = cfg.Sonido,
					Siguiente = "FIN",
				},
			}, "FeedbackNodo")

			-- ── Conexión completada ────────────────────────────────────────────
		elseif tipo == "ConexionCompletada" and not feedbackConexionMostrado then
			feedbackConexionMostrado = true

			-- Limpiar highlight del nodo y crear efecto de arista persistente
			limpiarEfectoNodo()
			mostrarEfectoArista()

			-- Diálogo con aliases reales de LevelsConfig
			local cfg    = CONFIG.DIALOGO_CONEXION
			local tokens = {
				aliasA = getAlias(CONFIG.NODO_A),
				aliasB = getAlias(CONFIG.NODO_B),
			}

			mostrarFeedback({
				["FeedbackConexion"] = {
					Actor     = cfg.Actor,
					Expresion = cfg.Expresion,
					Texto     = applyTokens(cfg.Texto, tokens),
					Sonido    = cfg.Sonido,
					Siguiente = "FIN",
				},
			}, "FeedbackConexion")
		end
	end)

	print("✅ Zona1_NodeFeedback: escuchando NotificarSeleccionNodo")
end)