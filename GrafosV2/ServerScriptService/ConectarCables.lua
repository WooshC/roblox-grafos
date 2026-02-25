-- ConectarCables.lua
-- ModuleScript servidor: SOLO lógica de conexión/desconexión entre nodos.
-- Los efectos visuales (SelectionBox, flash) están delegados a VisualEffectsService (cliente).
--
-- Estructura de nivel esperada:
--   NivelActual/Grafos/Grafo_ZonaX/
--       ├── Nodos/
--       │   └── <NodoModel>/
--       │       ├── Decoracion/ ← visual, NO tocado aquí
--       │       └── Selector/   ← hitbox de interacción
--       │           ├── Attachment    ← anclaje para Beam (pre-creado en Studio)
--       │           └── ClickDetector ← detecta clic del jugador (pre-creado en Studio)
--       └── Conexiones/ ← vacío; Beam + hitboxes se crean aquí en runtime
--
-- FLUJO:
--   Clic 1 → seleccionar nodo (estado + NotificarSeleccionNodo al cliente con adyacentes)
--   Clic 2 → intentar conectar:
--     a. Mismo nodo       → deseleccionar
--     b. Ya conectados    → desconectar + descontar puntos
--     c. Adyacente válido → Beam celeste + sumar puntos
--     d. No adyacente     → fallo + notificar cliente para flash rojo
--   Clic en hitbox cable → desconectar + descontar puntos
--
-- Ubicación Roblox: ServerScriptService/ConectarCables  (ModuleScript)

local RS        = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ConectarCables = {}

-- ── Eventos remotos (cacheados en activate) ──────────────────────────────────
local _notifyEv = nil   -- NotificarSeleccionNodo  (visual events al cliente)
local _dragEv   = nil   -- CableDragEvent          (preview de arrastre)
local _pulseEv  = nil   -- PulseEvent              (flujo de energía)

-- ── Estado interno ───────────────────────────────────────────────────────────
local _active         = false
local _nivel          = nil    -- Model "NivelActual" en Workspace
local _player         = nil    -- jugador activo (single-player)
local _tracker        = nil    -- ScoreTracker
local _adjLookup      = nil    -- { [nomA] = { [nomB] = true } } o nil (permisivo)
local _selected       = nil    -- Selector Model actualmente seleccionado
local _selectorByName = {}     -- { [nomNodo] = Selector Model } — para lookup O(1)

-- { key, beam, hitbox, nomA, nomB }
local _cables = {}
-- RBXScriptConnections a desconectar en deactivate()
local _conns  = {}

-- ── Constantes ───────────────────────────────────────────────────────────────
local CABLE_COLOR = Color3.fromRGB(0, 200, 255)   -- celeste brillante
local CABLE_WIDTH = 0.13                          -- studs
local CD_DIST     = 25                            -- MaxActivationDistance

-- ════════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════════════════════════

-- Clave canónica (orden alfabético) para evitar duplicados A-B / B-A
local function pairKey(nomA, nomB)
	if nomA > nomB then nomA, nomB = nomB, nomA end
	return nomA .. "|" .. nomB
end

local function getNombreNodo(selector)
	return selector.Parent.Name
end

local function getAttachment(selector)
	return selector:FindFirstChild("Attachment", true)
end

local function getClickDetector(selector)
	return selector:FindFirstChild("ClickDetector", true)
end

-- Carpeta Conexiones del grafo al que pertenece este selector
-- Ruta: Selector → Nodo → Nodos → Grafo_ZonaX → Conexiones
local function getConexionesFolder(selector)
	local grafo = selector.Parent.Parent.Parent
	if not grafo then return nil end
	local c = grafo:FindFirstChild("Conexiones")
	if not c then
		c        = Instance.new("Folder")
		c.Name   = "Conexiones"
		c.Parent = grafo
	end
	return c
end

-- Construir lookup O(1) desde formato lista de LevelsConfig
local function buildLookup(ady)
	if not ady then return nil end
	local t = {}
	for nomA, vecinos in pairs(ady) do
		t[nomA] = t[nomA] or {}
		for _, nomB in ipairs(vecinos) do
			t[nomA][nomB] = true
		end
	end
	return t
end

local function isAdjacent(nomA, nomB)
	if _adjLookup == nil then return true end
	return (_adjLookup[nomA] and _adjLookup[nomA][nomB]) == true
end

local function isBidireccional(nomA, nomB)
	return isAdjacent(nomA, nomB) and isAdjacent(nomB, nomA)
end

local function findCableIndex(nomA, nomB)
	local key = pairKey(nomA, nomB)
	for i, c in ipairs(_cables) do
		if c.key == key then return i end
	end
	return nil
end

-- Recolectar todos los Selectors del nivel y poblar _selectorByName
local function getAllSelectors()
	_selectorByName = {}
	if not _nivel then return {} end
	local selectors    = {}
	local grafosFolder = _nivel:FindFirstChild("Grafos")
	if not grafosFolder then
		warn("[ConectarCables] ⚠ No se encontró carpeta 'Grafos' en NivelActual")
		return selectors
	end
	for _, grafo in ipairs(grafosFolder:GetChildren()) do
		local nodosFolder = grafo:FindFirstChild("Nodos")
		if nodosFolder then
			for _, nodo in ipairs(nodosFolder:GetChildren()) do
				if nodo:IsA("Model") then
					local sel = nodo:FindFirstChild("Selector")
					if sel then
						table.insert(selectors, sel)
						_selectorByName[nodo.Name] = sel
					else
						warn("[ConectarCables] Nodo sin Selector:", nodo:GetFullName())
					end
				end
			end
		end
	end
	return selectors
end

-- Obtener Models de los nodos adyacentes (para highlight en el cliente)
local function getAdjModels(nomA)
	if not _adjLookup or not _adjLookup[nomA] then return {} end
	local models = {}
	for nomVecino, _ in pairs(_adjLookup[nomA]) do
		local adjSel = _selectorByName[nomVecino]
		if adjSel then
			table.insert(models, adjSel.Parent)
		end
	end
	return models
end

-- Estado de selección (sin lógica visual — delegada al cliente)
local function selectNodo(selector)
	_selected = selector
end

-- ════════════════════════════════════════════════════════════════════════════
-- CREAR / ELIMINAR CABLES
-- ════════════════════════════════════════════════════════════════════════════

local function crearCable(selector1, selector2)
	local nomA = getNombreNodo(selector1)
	local nomB = getNombreNodo(selector2)
	local key  = pairKey(nomA, nomB)
	local att1 = getAttachment(selector1)
	local att2 = getAttachment(selector2)
	local cxns = getConexionesFolder(selector1)

	if not att1 or not att2 then
		warn("[ConectarCables] Faltan Attachments:", nomA, nomB)
		return
	end
	if not cxns then
		warn("[ConectarCables] No se encontró Conexiones para", nomA)
		return
	end

	-- Hitbox invisible para click-to-disconnect
	local mid    = (att1.WorldPosition + att2.WorldPosition) / 2
	local dist   = (att1.WorldPosition - att2.WorldPosition).Magnitude
	local hitbox = Instance.new("Part")
	hitbox.Name        = "Hitbox_" .. key
	hitbox.Size        = Vector3.new(0.3, 0.3, dist)
	hitbox.CFrame      = CFrame.new(mid, att2.WorldPosition)
	hitbox.Transparency = 1
	hitbox.CanCollide  = false
	hitbox.Anchored    = true
	hitbox.Parent      = cxns

	-- Beam visual: siempre tenso, color celeste brillante
	-- CurveSize 0 = línea recta sin caída de gravedad
	local beam              = Instance.new("Beam")
	beam.Name               = "Cable_" .. key
	beam.Attachment0        = att1
	beam.Attachment1        = att2
	beam.Color              = ColorSequence.new(CABLE_COLOR)
	beam.Width0             = CABLE_WIDTH
	beam.Width1             = CABLE_WIDTH
	beam.CurveSize0         = 0
	beam.CurveSize1         = 0
	beam.LightEmission      = 0.6
	beam.LightInfluence     = 0.4
	beam.Transparency       = NumberSequence.new(0)
	beam.FaceCamera         = true   -- siempre visible desde cualquier ángulo
	beam.Segments           = 10
	beam.Parent             = hitbox -- se destruye junto con el hitbox

	local cd = Instance.new("ClickDetector")
	cd.MaxActivationDistance = CD_DIST
	cd.Parent                = hitbox

	local entry = { key = key, beam = beam, hitbox = hitbox, nomA = nomA, nomB = nomB }
	table.insert(_cables, entry)

	-- Clic en hitbox → desconectar y descontar puntos
	local conn = cd.MouseClick:Connect(function(pl)
		if pl ~= _player then return end
		for i, e in ipairs(_cables) do
			if e.hitbox == hitbox then
				e.hitbox:Destroy()   -- destruye beam y cd también (son hijos)
				table.remove(_cables, i)
				if _tracker then _tracker:registrarDesconexion(pl) end
				if _notifyEv then
					_notifyEv:FireClient(pl, "CableDesconectado", e.nomA, e.nomB)
				end
				print("[ConectarCables] Cable desconectado (hitbox):", e.key)
				break
			end
		end
	end)
	table.insert(_conns, conn)

	-- Pulso de energía (VisualEffectsService puede animar el flujo)
	if _pulseEv then
		local bidir   = isBidireccional(nomA, nomB)
		local origen  = selector1.Parent
		local destino = selector2.Parent
		if not bidir and not isAdjacent(nomA, nomB) then
			origen, destino = destino, origen
		end
		_pulseEv:FireAllClients("StartPulse", origen, destino, bidir)
	end

	print("[ConectarCables] Cable creado:", key)
end

local function eliminarCable(idx)
	local e = _cables[idx]
	if e then
		if e.hitbox and e.hitbox.Parent then
			e.hitbox:Destroy()   -- beam y cd son hijos → destruidos automáticamente
		end
		table.remove(_cables, idx)
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- LÓGICA DE CONEXIÓN
-- ════════════════════════════════════════════════════════════════════════════

local function tryConnect(player, selector1, selector2)
	local nomA = getNombreNodo(selector1)
	local nomB = getNombreNodo(selector2)

	-- Helper: limpiar selección y detener arrastre
	local function finalize()
		selectNodo(nil)
		if _dragEv then _dragEv:FireClient(player, "Stop") end
	end

	-- Mismo nodo → deseleccionar
	if nomA == nomB then
		if _notifyEv then _notifyEv:FireClient(player, "SeleccionCancelada") end
		finalize()
		return
	end

	-- ¿Ya conectados? → desconectar y descontar puntos
	local idx = findCableIndex(nomA, nomB)
	if idx then
		local cEntry = _cables[idx]    -- capturar ANTES de eliminar
		eliminarCable(idx)
		if _tracker then _tracker:registrarDesconexion(player) end
		if _notifyEv then
			_notifyEv:FireClient(player, "CableDesconectado", cEntry.nomA, cEntry.nomB)
		end
		print("[ConectarCables] Desconectado al reconectar:", cEntry.key)
		finalize()
		return
	end

	-- ¿Conexión válida según adyacencias?
	if isAdjacent(nomA, nomB) then
		crearCable(selector1, selector2)
		_tracker:registrarConexion(player)
		if _notifyEv then
			_notifyEv:FireClient(player, "ConexionCompletada", nomA, nomB)
		end
	else
		-- Registrar tipo de error en log (sin distinción visual en el cliente)
		local tipoError = isAdjacent(nomB, nomA) and "DireccionInvalida" or "ConexionInvalida"
		_tracker:registrarFallo(player)
		if _notifyEv then
			-- Siempre "ConexionInvalida" → flash rojo, sin distinción naranja
			_notifyEv:FireClient(player, "ConexionInvalida", selector2.Parent)
		end
		print("[ConectarCables] Fallo (" .. tipoError .. "):", nomA, "→", nomB)
	end

	finalize()
end

-- ── Handler de clic en Selector ──────────────────────────────────────────────
local function onSelectorClicked(player, selector)
	if player ~= _player then return end
	if not _active then return end

	if _selected == nil then
		-- Primer clic: seleccionar nodo
		selectNodo(selector)

		local nomA      = getNombreNodo(selector)
		local nodoModel = selector.Parent
		local adjModels = getAdjModels(nomA)

		-- Notificar al cliente: destacar nodo seleccionado + adyacentes
		if _notifyEv then
			_notifyEv:FireClient(player, "NodoSeleccionado", nodoModel, adjModels)
		end

		-- Enviar info de arrastre (drag visual, sin ID de adyacentes)
		if _dragEv then
			local att1    = getAttachment(selector)
			local vecinos = {}
			if _adjLookup and _adjLookup[nomA] then
				for nomV, _ in pairs(_adjLookup[nomA]) do
					table.insert(vecinos, nomV)
				end
			end
			if att1 then _dragEv:FireClient(player, "Start", att1, vecinos) end
		end

	elseif _selected == selector then
		-- Clic en el mismo nodo → deseleccionar
		selectNodo(nil)
		if _notifyEv then _notifyEv:FireClient(player, "SeleccionCancelada") end
		if _dragEv   then _dragEv:FireClient(player, "Stop") end

	else
		-- Segundo clic en nodo distinto → intentar conectar
		tryConnect(player, _selected, selector)
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- INTERFAZ PÚBLICA
-- ════════════════════════════════════════════════════════════════════════════

function ConectarCables.activate(nivel, adjacencias, player, tracker)
	if _active then ConectarCables.deactivate() end

	_nivel     = nivel
	_player    = player
	_tracker   = tracker
	_selected  = nil
	_cables    = {}
	_conns     = {}
	_active    = true
	_adjLookup = buildLookup(adjacencias)

	-- Cachear eventos remotos
	local ev = RS:FindFirstChild("Events")
	if ev then
		local rem = ev:FindFirstChild("Remotes")
		if rem then
			_notifyEv = rem:FindFirstChild("NotificarSeleccionNodo")
			_dragEv   = rem:FindFirstChild("CableDragEvent")
			_pulseEv  = rem:FindFirstChild("PulseEvent")
		end
	end

	local selectors = getAllSelectors()
	print("[ConectarCables] activate — nodos:", #selectors,
		"/ modo:", adjacencias == nil and "PERMISIVO" or "ADYACENCIAS")

	for _, selector in ipairs(selectors) do
		local cd = getClickDetector(selector)
		if cd then
			local conn = cd.MouseClick:Connect(function(pl)
				onSelectorClicked(pl, selector)
			end)
			table.insert(_conns, conn)
		else
			warn("[ConectarCables] ClickDetector no encontrado en:", selector:GetFullName())
		end
	end
end

function ConectarCables.deactivate()
	_active = false
	selectNodo(nil)

	-- Desconectar todos los listeners de ClickDetectors
	for _, conn in ipairs(_conns) do conn:Disconnect() end
	_conns = {}

	-- Destruir cables (hitbox destruye beam y cd automáticamente)
	for _, e in ipairs(_cables) do
		if e.hitbox and e.hitbox.Parent then e.hitbox:Destroy() end
	end
	_cables = {}

	-- Detener todos los pulsos visuales
	if _pulseEv then _pulseEv:FireAllClients("StopAll") end

	_nivel          = nil
	_player         = nil
	_tracker        = nil
	_adjLookup      = nil
	_selected       = nil
	_selectorByName = {}

	print("[ConectarCables] deactivate — limpieza completa")
end

function ConectarCables.getConnections()
	local result = {}
	for _, c in ipairs(_cables) do table.insert(result, c.key) end
	return result
end

function ConectarCables.getConnectionCount()
	return #_cables
end

return ConectarCables
