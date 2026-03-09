-- StarterPlayerScripts/SistemasGameplay/ControladorEfectos.client.lua
-- Controlador de efectos visuales - Adaptado de GrafosV2

local Players = game:GetService("Players")
local Replicado = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local EfectosHighlight = require(Replicado.Efectos.EfectosHighlight)
local EfectosVideo     = require(Replicado.Efectos.EfectosVideo)
local EfectosNodo      = require(Replicado.Efectos.EfectosNodo)
local BillboardNombres = require(Replicado.Efectos.BillboardNombres)

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONFIGURACION Y ESTADO
-- ═══════════════════════════════════════════════════════════════════════════════

local COLOR_SELECCIONADO = Color3.fromRGB(0, 212, 255)    -- Cyan
local COLOR_ADYACENTE = Color3.fromRGB(255, 200, 50)      -- Dorado
local COLOR_ERROR = Color3.fromRGB(239, 68, 68)           -- Rojo

-- Estado
local _highlights = {}      -- Instancias Highlight creadas (referencia local, limpiar vía EfectosHighlight)
local _savedStates = {}     -- Estados originales de las partes
local _nombresNodos = {}    -- Nombres amigables desde LevelsConfig

-- ═══════════════════════════════════════════════════════════════════════════════
-- LEVELS CONFIG (para nombres de nodos)
-- ═══════════════════════════════════════════════════════════════════════════════

local LevelsConfig = require(Replicado:WaitForChild("Config"):WaitForChild("LevelsConfig"))

-- Actualizar nombres cuando carga un nivel
local Eventos = Replicado:WaitForChild("EventosGrafosV3")
local Remotos = Eventos:WaitForChild("Remotos")
local nivelListoEv = Remotos:WaitForChild("NivelListo")

nivelListoEv.OnClientEvent:Connect(function(data)
	if data and data.nivelID ~= nil then
		local cfg = LevelsConfig[data.nivelID]
		_nombresNodos = (cfg and cfg.NombresNodos) or {}
		print("[ControladorEfectos] Nombres cargados para nivel", data.nivelID)
	end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Obtener el selector de un nodo (puede ser BasePart o Model)
local function getSelector(nodoModel)
	local selector = nodoModel:FindFirstChild("Selector")
	if not selector then return nil, nil end

	if selector:IsA("BasePart") then
		return selector, selector
	end

	-- Selector es un Model, buscar BasePart dentro
	local part = selector:FindFirstChildOfClass("BasePart")
	return selector, part
end

-- Crear Highlight usando el sistema centralizado
local function addHighlight(adornee, color, tipo)
	local tipoHighlight = tipo or "SELECCIONADO"
	if color == COLOR_ADYACENTE then
		tipoHighlight = "ADYACENTE"
	elseif color == COLOR_ERROR then
		tipoHighlight = "ERROR"
	end

	local nombre = "Nodo_" .. (adornee.Name or tostring(adornee))
	return EfectosHighlight.crear(nombre, adornee, tipoHighlight)
end

-- Cambiar estilo de una BasePart y guardar estado original
local function styleBasePart(part, color)
	if not part then return end

	-- Guardar estado original
	table.insert(_savedStates, {
		part = part,
		origColor = part.Color,
		origMat = part.Material,
		origTransp = part.Transparency,
	})

	-- Aplicar nuevo estilo
	part.Color = color
	part.Material = Enum.Material.Neon
	part.Transparency = 0.10
end

-- Crear Billboard con nombre del nodo usando el sistema centralizado
local function addBillboard(part, color, nodeName)
	if not part or not part:IsA("BasePart") then return end

	local displayName = _nombresNodos[nodeName] or nodeName or ""
	local clave = "CE_" .. (nodeName or tostring(part))

	BillboardNombres.crear(part, displayName, "NODO_INTERACCION", clave, {
		colorBorde = color,
		colorTexto = color,
	})
end

-- Highlight completo de un nodo (modelo + billboard en selector)
local function highlightNode(nodoModel, color)
	local _, basePart = getSelector(nodoModel)
	-- Highlight va en el MODELO, no en el selector
	addHighlight(nodoModel, color)
	if basePart then
		styleBasePart(basePart, color)
		addBillboard(basePart, color, nodoModel.Name)
	end
end

-- Limpiar TODOS los efectos y restaurar estados originales
local function clearAll()
	EfectosNodo.limpiarSeleccion()
	-- Destruir todos los Highlights gestionados por EfectosHighlight
	EfectosHighlight.limpiarTodo()
	_highlights = {}

	-- Destruir billboards gestionados por BillboardNombres
	BillboardNombres.destruirPorPrefijo("CE_")

	-- Restaurar partes modificadas
	for _, state in ipairs(_savedStates) do
		if state.part and state.part.Parent then
			state.part.Color = state.origColor
			state.part.Material = state.origMat
			state.part.Transparency = state.origTransp
		end
	end
	_savedStates = {}
end

-- Flash de error usando Highlight
local function flashModel(model, color, duration)
	if not model then return end

	-- Usar el sistema de highlights para el error
	local selector = model:FindFirstChild("Selector")
	if selector then
		EfectosHighlight.flashErrorNodo(model, duration or 0.5)
	else
		-- Fallback: cambiar color de partes directamente
		local parts = {}
		local originals = {}

		for _, desc in ipairs(model:GetDescendants()) do
			if desc:IsA("BasePart") then
				table.insert(parts, desc)
				table.insert(originals, desc.Color)
				desc.Color = color
			end
		end

		task.delay(duration or 0.35, function()
			for i, part in ipairs(parts) do
				if part and part.Parent then
					part.Color = originals[i]
				end
			end
		end)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- EVENTOS (via GestorEfectos — conexión única centralizada)
-- ═══════════════════════════════════════════════════════════════════════════════

local GestorEfectos = require(script.Parent:WaitForChild("GestorEfectos"))

-- Nodo seleccionado: arg1 = Model nodo, arg2 = {Model,...} adyacentes
GestorEfectos.registrar("NodoSeleccionado", function(params)
	local arg1, arg2 = params.arg1, params.arg2
	clearAll()
	local adyNames = {}
	if type(arg2) == "table" then
		for _, adjModel in ipairs(arg2) do
			if typeof(adjModel) == "Instance" then
				table.insert(adyNames, adjModel.Name)
			elseif type(adjModel) == "string" then
				table.insert(adyNames, adjModel)
			end
		end
	end
	EfectosNodo.establecerSeleccion(arg1 and arg1.Name or nil, adyNames)
	if arg1 then highlightNode(arg1, COLOR_SELECCIONADO) end
	if type(arg2) == "table" then
		for _, adjModel in ipairs(arg2) do
			if adjModel and adjModel ~= arg1 then
				highlightNode(adjModel, COLOR_ADYACENTE)
			end
		end
	end
end)

-- Conexión completada: efecto VFX en cada Selector
-- (partículas son responsabilidad de ParticulasConexion)
GestorEfectos.registrar("ConexionCompletada", function(params)
	local arg1, arg2 = params.arg1, params.arg2
	clearAll()
	if arg1 then EfectosVideo.reproducirConexion(arg1, "EfectoConexion", 5, 2) end
	if arg2 then EfectosVideo.reproducirConexion(arg2, "EfectoConexion", 5, 2) end
end)

-- Cable desconectado: solo limpiar highlights
GestorEfectos.registrar("CableDesconectado", function(_params)
	clearAll()
end)

-- Selección cancelada
GestorEfectos.registrar("SeleccionCancelada", function(_params)
	clearAll()
end)

-- Error de conexión: flash rojo
GestorEfectos.registrar("ConexionInvalida", function(params)
	clearAll()
	flashModel(params.arg1, COLOR_ERROR, 0.35)
end)

GestorEfectos.registrar("DireccionInvalida", function(params)
	clearAll()
	flashModel(params.arg1, COLOR_ERROR, 0.35)
end)

print("[ControladorEfectos] Sistema de efectos inicializado")
