-- StarterPlayerScripts/SistemasGameplay/ControladorEfectos.client.lua
-- Controlador de efectos visuales - Adaptado de GrafosV2

local Players = game:GetService("Players")
local Replicado = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONFIGURACION Y ESTADO
-- ═══════════════════════════════════════════════════════════════════════════════

local COLOR_SELECCIONADO = Color3.fromRGB(0, 212, 255)    -- Cyan
local COLOR_ADYACENTE = Color3.fromRGB(255, 200, 50)      -- Dorado
local COLOR_ERROR = Color3.fromRGB(239, 68, 68)           -- Rojo

-- Estado
local _highlights = {}      -- Instancias Highlight creadas
local _billboards = {}      -- BillboardGuis creados
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

-- Crear Highlight de Roblox
local function addHighlight(adornee, color)
	local h = Instance.new("Highlight")
	h.Adornee = adornee
	h.FillColor = color
	h.FillTransparency = 0.45
	h.OutlineColor = color
	h.OutlineTransparency = 0
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Parent = Workspace
	table.insert(_highlights, h)
	return h
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

-- Crear Billboard con nombre del nodo
local function addBillboard(part, color, nodeName)
	if not part or not part:IsA("BasePart") then return end
	
	local displayName = _nombresNodos[nodeName] or nodeName or ""
	
	local bb = Instance.new("BillboardGui")
	bb.Name = "NombreNodo"
	bb.Adornee = part
	bb.StudsOffsetWorldSpace = Vector3.new(0, 4.5, 0)
	bb.AlwaysOnTop = true
	bb.Size = UDim2.fromOffset(120, 32)
	bb.ResetOnSpawn = false
	bb.Parent = Workspace
	
	-- Fondo
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.new(0, 0, 0)
	bg.BackgroundTransparency = 0.45
	bg.BorderSizePixel = 0
	bg.Parent = bb
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = bg
	
	-- Borde de color
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 2
	stroke.Parent = bg
	
	-- Texto
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = displayName
	label.TextColor3 = color
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = bg
	
	table.insert(_billboards, bb)
end

-- Highlight completo de un nodo (selector + billboard)
local function highlightNode(nodoModel, color)
	local adornee, basePart = getSelector(nodoModel)
	if adornee then
		addHighlight(adornee, color)
	end
	if basePart then
		styleBasePart(basePart, color)
		addBillboard(basePart, color, nodoModel.Name)
	end
end

-- Limpiar TODOS los efectos y restaurar estados originales
local function clearAll()
	-- Destruir highlights
	for _, h in ipairs(_highlights) do
		if h and h.Parent then h:Destroy() end
	end
	_highlights = {}
	
	-- Destruir billboards
	for _, b in ipairs(_billboards) do
		if b and b.Parent then b:Destroy() end
	end
	_billboards = {}
	
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

-- Flash de error (color rojo breve)
local function flashModel(model, color, duration)
	if not model then return end
	
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

-- ═══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE PARTÍCULAS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Cargar sistema de partículas de conexiones
local ParticulasConexion = nil
local exito, resultado = pcall(function()
	return require(script.Parent:FindFirstChild("ParticulasConexion"))
end)

if exito and resultado then
	ParticulasConexion = resultado
	print("[ControladorEfectos] ParticulasConexion integrado")
else
	warn("[ControladorEfectos] No se pudo cargar ParticulasConexion:", resultado)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- EVENTOS
-- ═══════════════════════════════════════════════════════════════════════════════

local notifyEv = Remotos:WaitForChild("NotificarSeleccionNodo")

notifyEv.OnClientEvent:Connect(function(eventType, arg1, arg2)
	
	-- Nodo seleccionado: arg1 = nodo, arg2 = adyacentes
	if eventType == "NodoSeleccionado" then
		clearAll()
		if arg1 then
			highlightNode(arg1, COLOR_SELECCIONADO)
		end
		if type(arg2) == "table" then
			for _, adjModel in ipairs(arg2) do
				if adjModel and adjModel ~= arg1 then
					highlightNode(adjModel, COLOR_ADYACENTE)
				end
			end
		end
		
	-- Conexión completada: iniciar partículas
	elseif eventType == "ConexionCompletada" then
		clearAll()
		-- arg1 = nombreNodoA, arg2 = nombreNodoB
		if ParticulasConexion and arg1 and arg2 then
			local esDirigido = ParticulasConexion.esConexionDirigida 
				and ParticulasConexion.esConexionDirigida(arg1, arg2) 
				or false
			ParticulasConexion.iniciar(arg1, arg2, esDirigido)
		end
		
	-- Cable desconectado: detener partículas
	elseif eventType == "CableDesconectado" then
		clearAll()
		if ParticulasConexion and arg1 and arg2 then
			ParticulasConexion.detener(arg1, arg2)
		end
		
	-- Selección cancelada: solo limpiar
	elseif eventType == "SeleccionCancelada" then
		clearAll()
		
	-- Error: flash rojo
	elseif eventType == "ConexionInvalida" then
		clearAll()
		flashModel(arg1, COLOR_ERROR, 0.35)
		
	end
end)

print("[ControladorEfectos] Sistema de efectos inicializado")
