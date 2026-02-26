-- VisualEffectsService.client.lua
-- Módulo cliente: gestiona TODOS los efectos visuales del gameplay.
--
-- Al seleccionar un nodo el módulo busca la Part/Model llamada "Selector"
-- dentro del Nodo (nodoModel/Selector). Sobre ella aplica:
--   1. Instancia Highlight (Roblox native) — outline + fill de color
--   2. BasePart del Selector → Color, Material = Neon, Transparency casi sólida
-- El mismo efecto se aplica a los nodos adyacentes (color dorado).
--
-- Estructura esperada (compatible con BasePart o Model):
--   NodoModel/
--   ├── Decoracion/   (NO se toca)
--   └── Selector      (BasePart o Model) ← ÚNICO objetivo de los efectos
--       ├── Attachment
--       └── ClickDetector
--
-- Los Beams (cables) son server-side y replican automáticamente.
-- Este módulo NO toca Beams ni Decoracion.
--
-- Eventos escuchados (NotificarSeleccionNodo):
--   "NodoSeleccionado",   nodoModel, adjModels[]  → highlight seleccionado + adyacentes
--   "SeleccionCancelada"                          → limpiar todo
--   "ConexionCompletada", nomA, nomB              → limpiar todo
--   "ConexionInvalida",   nodoModel               → limpiar + flash rojo
--   "CableDesconectado",  nomA, nomB              → limpiar todo
--
-- Ubicación Roblox: StarterPlayer/StarterPlayerScripts/VisualEffectsService  (LocalScript)

local Players   = game:GetService("Players")
local RS        = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- ── Eventos ──────────────────────────────────────────────────────────────────
local eventsFolder  = RS:WaitForChild("Events", 10)
local remotesFolder = eventsFolder and eventsFolder:WaitForChild("Remotes", 5)
local notifyEv      = remotesFolder and remotesFolder:WaitForChild("NotificarSeleccionNodo", 5)
-- PlayEffect: efectos adicionales disparados por VisualEffectsManager (servidor)
local playEffectEv  = remotesFolder and remotesFolder:WaitForChild("PlayEffect", 5)

if not notifyEv then
	warn("[VisualEffectsService] ❌ NotificarSeleccionNodo no encontrado — módulo inactivo")
	return
end

-- ── Colores ──────────────────────────────────────────────────────────────────
local COLOR_SELECTED = Color3.fromRGB(0,   212, 255)  -- cyan:  nodo seleccionado
local COLOR_ADJACENT = Color3.fromRGB(255, 200,  50)  -- dorado: nodos adyacentes válidos
local COLOR_INVALID   = Color3.fromRGB(239,  68,  68)  -- rojo:  conexión inválida
local COLOR_ENERGIZED = Color3.fromRGB(0,   200, 255)  -- cian:  nodo energizado pulsante

-- ── Estado activo ─────────────────────────────────────────────────────────────
-- Instancias Highlight creadas (se destruyen en clearAll)
local _highlights  = {}
-- Estado original de cada BasePart modificada (se restaura en clearAll)
-- { part, origColor, origMaterial, origTransparency }
local _savedStates = {}
-- BillboardGui cross-room creados (se destruyen en clearAll)
local _billboards  = {}

-- ── Helpers ──────────────────────────────────────────────────────────────────

-- Devuelve (selectorAdornee, selectorBasePart) para un nodoModel.
-- selectorAdornee → lo que se usa como Adornee del Highlight
-- selectorBasePart → la BasePart a la que se cambian Material/Color/Transparency
-- Soporta Selector como BasePart directa O como Model que contiene una BasePart.
local function getSelectorTarget(nodoModel)
	local selector = nodoModel:FindFirstChild("Selector")
	if not selector then return nil, nil end
	if selector:IsA("BasePart") then
		return selector, selector
	end
	-- Selector es un Model → buscar la BasePart dentro (hitbox)
	local part = selector:FindFirstChildOfClass("BasePart")
	return selector, part
end

-- Crea un Highlight de Roblox sobre el adornee y lo registra para limpieza.
local function addHighlight(adornee, color)
	local h                   = Instance.new("Highlight")
	h.Adornee                 = adornee
	h.FillColor               = color
	h.FillTransparency        = 0.45    -- relleno semitransparente
	h.OutlineColor            = color
	h.OutlineTransparency     = 0       -- outline sólido
	h.DepthMode               = Enum.HighlightDepthMode.AlwaysOnTop
	h.Parent                  = Workspace  -- local-only (LocalScript)
	table.insert(_highlights, h)
end

-- Cambia Material, Color y Transparency de una BasePart.
-- Guarda el estado original para restaurarlo después.
local function styleBasePart(part, color)
	if not part then return end
	table.insert(_savedStates, {
		part     = part,
		origColor  = part.Color,
		origMat    = part.Material,
		origTransp = part.Transparency,
	})
	part.Color        = color
	part.Material     = Enum.Material.Neon  -- brilla en el oscuro
	part.Transparency = 0.10                -- casi sólido
end

-- BillboardGui flotante con AlwaysOnTop = true sobre la BasePart.
-- Visible a través de paredes y a distancia arbitraria (cross-room).
local function addBillboard(part, color)
	if not part or not part:IsA("BasePart") then return end
	local bb                      = Instance.new("BillboardGui")
	bb.Adornee                    = part
	bb.StudsOffsetWorldSpace      = Vector3.new(0, 4, 0)  -- siempre vertical en world-space
	bb.AlwaysOnTop                = true   -- visible a través de paredes ✅
	bb.Size                       = UDim2.fromOffset(50, 50)
	bb.ResetOnSpawn               = false
	bb.Parent                     = Workspace

	local icon                    = Instance.new("TextLabel")
	icon.Size                     = UDim2.fromScale(1, 1)
	icon.BackgroundTransparency   = 1
	icon.Text                     = "●"
	icon.TextColor3               = color
	icon.TextScaled               = true
	icon.Parent                   = bb

	table.insert(_billboards, bb)
end

-- Aplica Highlight + estilo a la Part "Selector" de un nodoModel.
local function highlightNode(nodoModel, color)
	local adornee, basePart = getSelectorTarget(nodoModel)
	if adornee  then addHighlight(adornee, color) end
	if basePart then
		styleBasePart(basePart, color)
		addBillboard(basePart, color)   -- cross-room: visible a través de paredes
	end
end

-- Destruye todos los Highlights, BillboardGuis y restaura las BaseParts.
local function clearAll()
	for _, h in ipairs(_highlights) do
		if h and h.Parent then h:Destroy() end
	end
	_highlights = {}

	for _, b in ipairs(_billboards) do
		if b and b.Parent then b:Destroy() end
	end
	_billboards = {}

	for _, state in ipairs(_savedStates) do
		if state.part and state.part.Parent then
			state.part.Color        = state.origColor
			state.part.Material     = state.origMat
			state.part.Transparency = state.origTransp
		end
	end
	_savedStates = {}
end

-- Flash de color en todos los BaseParts de un Model (error visual breve).
-- Solo modifica Color, no Material ni Transparency.
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

	-- ── Nodo seleccionado ──────────────────────────────────────────────────
	-- arg1 = nodoModel (Model del nodo seleccionado)
	-- arg2 = adjModels (array de Models adyacentes)
	if eventType == "NodoSeleccionado" then
		clearAll()
		if arg1 then
			highlightNode(arg1, COLOR_SELECTED)
		end
		if type(arg2) == "table" then
			for _, adjModel in ipairs(arg2) do
				if adjModel and adjModel ~= arg1 then
					highlightNode(adjModel, COLOR_ADJACENT)
				end
			end
		end

		-- ── Limpiar highlights ─────────────────────────────────────────────────
	elseif eventType == "SeleccionCancelada"
		or eventType == "ConexionCompletada"
		or eventType == "CableDesconectado" then
		clearAll()

		-- ── Conexión inválida: flash rojo en nodo destino ─────────────────────
		-- arg1 = nodoModel del segundo nodo
	elseif eventType == "ConexionInvalida" then
		clearAll()
		flashModel(arg1, COLOR_INVALID, 0.35)

	end
end)

-- ── Handler PlayEffect ────────────────────────────────────────────────────────
-- Efectos adicionales disparados por VisualEffectsManager (servidor).
-- Complementa NotificarSeleccionNodo con nuevos tipos de efecto.
if playEffectEv then
	playEffectEv.OnClientEvent:Connect(function(effectType, arg1, arg2)

		if effectType == "NodeSelected" then
			-- arg1 = nodoModel, arg2 = adjModels[] (mismo formato que NodoSeleccionado)
			clearAll()
			if arg1 then highlightNode(arg1, COLOR_SELECTED) end
			if type(arg2) == "table" then
				for _, adjModel in ipairs(arg2) do
					if adjModel and adjModel ~= arg1 then
						highlightNode(adjModel, COLOR_ADJACENT)
					end
				end
			end

		elseif effectType == "NodeError" then
			-- arg1 = nodoModel → flash rojo breve
			clearAll()
			flashModel(arg1, COLOR_INVALID, 0.35)

		elseif effectType == "NodeEnergized" then
			-- arg1 = nodoModel → glow cian pulsante (permanente hasta ClearAll)
			clearAll()
			if arg1 then highlightNode(arg1, COLOR_ENERGIZED) end

		elseif effectType == "CableConnected"
			or effectType == "CableRemoved"
			or effectType == "ZoneComplete"
			or effectType == "ClearAll" then
			-- Limpiar efectos activos en cualquiera de estos eventos
			clearAll()

		end
	end)
	print("[EDA v2] ✅ VisualEffectsService — PlayEffect conectado")
else
	warn("[EDA v2] ⚠ PlayEffect no encontrado — efectos adicionales desactivados")
end

print("[EDA v2] ✅ VisualEffectsService activo")
