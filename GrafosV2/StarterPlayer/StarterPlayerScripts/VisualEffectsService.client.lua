-- VisualEffectsService.client.lua
-- Módulo cliente: gestiona TODOS los efectos visuales del gameplay.
-- ConectarCables.lua (servidor) delega aquí toda la lógica visual.
--
-- Efectos gestionados:
--   · SelectionBox cyan      → nodo seleccionado por el jugador
--   · SelectionBox dorado    → nodos adyacentes al seleccionado (conexiones válidas posibles)
--   · Flash rojo             → conexión inválida (nodos no adyacentes)
--   · Flash naranja          → dirección incorrecta (arista existe pero en sentido opuesto)
--   · Limpieza de highlights → al completar conexión, deseleccionar o desconectar
--
-- Los Beams (cables) son creados server-side y replican automáticamente al cliente.
-- Este módulo NO crea Beams — solo gestiona SelectionBoxes y flashes.
--
-- Eventos escuchados (NotificarSeleccionNodo):
--   "NodoSeleccionado",   nodoModel, adjModels[]  → highlight seleccionado + adyacentes
--   "SeleccionCancelada"                          → limpiar highlights
--   "ConexionCompletada", nomA, nomB              → limpiar highlights
--   "ConexionInvalida",   nodoModel               → limpiar + flash rojo
--   "DireccionInvalida",  nodoModel               → limpiar + flash naranja
--   "CableDesconectado",  nomA, nomB              → limpiar highlights
--
-- Ubicación Roblox: StarterPlayer/StarterPlayerScripts/VisualEffectsService  (LocalScript)

local Players      = game:GetService("Players")
local RS           = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace    = game:GetService("Workspace")

local player = Players.LocalPlayer

-- ── Eventos ──────────────────────────────────────────────────────────────────
local eventsFolder  = RS:WaitForChild("Events", 10)
local remotesFolder = eventsFolder and eventsFolder:WaitForChild("Remotes", 5)

local notifyEv = remotesFolder and remotesFolder:WaitForChild("NotificarSeleccionNodo", 5)

if not notifyEv then
	warn("[VisualEffectsService] ❌ NotificarSeleccionNodo no encontrado — módulo inactivo")
	return
end

-- ── Colores ──────────────────────────────────────────────────────────────────
local COLOR_SELECTED  = Color3.fromRGB(0,   212, 255)  -- cyan: nodo seleccionado
local COLOR_ADJACENT  = Color3.fromRGB(255, 200,  50)  -- dorado: nodos adyacentes válidos
local COLOR_INVALID   = Color3.fromRGB(239,  68,  68)  -- rojo: conexión inválida
local COLOR_DIRECTION = Color3.fromRGB(255, 140,   0)  -- naranja: dirección incorrecta

-- ── Estado activo ────────────────────────────────────────────────────────────
local _selBox   = nil   -- SelectionBox del nodo seleccionado
local _adjBoxes = {}    -- { SelectionBox } de los nodos adyacentes

-- ── Helpers ──────────────────────────────────────────────────────────────────

local function makeSelectionBox(adornee, color, surfAlpha)
	local box                = Instance.new("SelectionBox")
	box.Adornee              = adornee
	box.Color3               = color
	box.LineThickness        = 0.06
	box.SurfaceTransparency  = surfAlpha or 0.88
	box.SurfaceColor3        = color
	box.Parent               = Workspace
	return box
end

local function clearSelection()
	if _selBox and _selBox.Parent then _selBox:Destroy() end
	_selBox = nil
	for _, box in ipairs(_adjBoxes) do
		if box and box.Parent then box:Destroy() end
	end
	_adjBoxes = {}
end

-- Colorea brevemente todos los BaseParts de un Model y luego restaura los originales.
local function flashModel(model, flashColor, duration)
	if not model then return end
	local parts     = {}
	local originals = {}
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			table.insert(parts, desc)
			table.insert(originals, desc.Color)
			desc.Color = flashColor
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

-- ── Handler principal ─────────────────────────────────────────────────────────
notifyEv.OnClientEvent:Connect(function(eventType, arg1, arg2)

	-- ── Nodo seleccionado: highlight seleccionado + adyacentes ──────────────
	if eventType == "NodoSeleccionado" then
		-- arg1 = nodoModel  (Model del nodo seleccionado)
		-- arg2 = adjModels  (array de Models adyacentes)
		clearSelection()
		if arg1 then
			_selBox = makeSelectionBox(arg1, COLOR_SELECTED, 0.82)
		end
		local adjModels = arg2
		if type(adjModels) == "table" then
			for _, adjModel in ipairs(adjModels) do
				if adjModel and adjModel ~= arg1 then
					local box = makeSelectionBox(adjModel, COLOR_ADJACENT, 0.90)
					table.insert(_adjBoxes, box)
				end
			end
		end

	-- ── Deselección / conexión completada / cable desconectado ──────────────
	elseif eventType == "SeleccionCancelada"
		or eventType == "ConexionCompletada"
		or eventType == "CableDesconectado" then
		clearSelection()

	-- ── Conexión inválida: flash rojo en el nodo destino ────────────────────
	elseif eventType == "ConexionInvalida" then
		-- arg1 = nodoModel del segundo nodo (el que recibió el intento inválido)
		clearSelection()
		flashModel(arg1, COLOR_INVALID, 0.35)

	-- ── Dirección incorrecta: flash naranja en el nodo destino ──────────────
	elseif eventType == "DireccionInvalida" then
		-- arg1 = nodoModel del segundo nodo (arista existe pero en sentido contrario)
		clearSelection()
		flashModel(arg1, COLOR_DIRECTION, 0.35)

	end
end)

print("[EDA v2] ✅ VisualEffectsService activo")
