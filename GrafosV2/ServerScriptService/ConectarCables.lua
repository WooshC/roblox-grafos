-- ConectarCables.lua
-- ModuleScript servidor: gestiona la conexión/desconexión de cables entre nodos.
-- Reescrito para la estructura real de niveles v2:
--
--   NivelActual/Grafos/Grafo_ZonaX/
--       ├── Nodos/
--       │   ├── Nodo1_z1/ (Model)
--       │   │   ├── Decoracion/ (Model) ← visual, NO tocado por este script
--       │   │   └── Selector/   (Model) ← hitbox de interacción
--       │   │       ├── Attachment    ← anclaje para RopeConstraints (pre-creado en Studio)
--       │   │       └── ClickDetector ← detecta clic del jugador (pre-creado en Studio)
--       └── Conexiones/ (Folder) ← vacío; RopeConstraints + hitboxes se crean aquí en runtime
--
-- FLUJO:
--   Clic 1 → seleccionar nodo (SelectionBox cyan + NotificarSeleccionNodo al cliente)
--   Clic 2 → intentar conectar:
--     a. Ya conectados       → desconectar
--     b. Adyacentes (válido) → crear cable + ScoreTracker.registrarConexion
--     c. No adyacentes       → flash rojo + ScoreTracker.registrarFallo
--   Clic en hitbox del cable → desconectar (sin penalización)
--
-- ADYACENCIAS (formato lista de GarfosV1/LevelsConfig):
--   { ["Nodo1_z1"] = {"Nodo2_z1"}, ["Nodo2_z1"] = {"Nodo1_z1"} }
--   Directional: Nodo1→Nodo2 existe, pero Nodo2→Nodo1 puede no estar → grafo dirigido.
--   Si adjacencias = nil → modo permisivo (cualquier par es válido).
--
-- Ubicación Roblox: ServerScriptService/ConectarCables  (ModuleScript)

local RS        = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ConectarCables = {}

-- ── Eventos remotos (se obtienen internamente) ───────────────────────────────
local _notifyEv = nil   -- NotificarSeleccionNodo
local _dragEv   = nil   -- CableDragEvent
local _pulseEv  = nil   -- PulseEvent

-- ── Estado interno ───────────────────────────────────────────────────────────
local _active      = false
local _nivel       = nil    -- Model "NivelActual" en Workspace
local _player      = nil    -- jugador activo
local _tracker     = nil    -- ScoreTracker
local _adjLookup   = nil    -- { [nomA] = { [nomB] = true } } o nil (permisivo)

local _selected    = nil    -- Selector Model seleccionado actualmente (o nil)
local _selBox      = nil    -- SelectionBox activo

-- { key, rope, hitbox }
local _cables      = {}
-- RBXScriptConnection para limpiar en deactivate()
local _conns       = {}

-- ── Constantes visuales ──────────────────────────────────────────────────────
local COLOR_SELECT  = Color3.fromRGB(0, 212, 255)   -- cyan: nodo seleccionado
local COLOR_ERROR   = Color3.fromRGB(239, 68, 68)   -- rojo: conexión inválida
local CABLE_THICK   = 0.07                          -- studs
local CD_DIST       = 25                            -- MaxActivationDistance

-- ════════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════════════════════════

-- Clave canónica (orden alfabético) para evitar duplicados A-B / B-A
local function pairKey(nomA, nomB)
	if nomA > nomB then nomA, nomB = nomB, nomA end
	return nomA .. "|" .. nomB
end

-- Nombre del nodo a partir de su Selector (selector.Parent = nodo Model)
local function getNombreNodo(selector)
	return selector.Parent.Name
end

-- Attachment dentro del Selector (puede estar en una BasePart hija del Model)
local function getAttachment(selector)
	return selector:FindFirstChild("Attachment", true)
end

-- ClickDetector dentro del Selector
local function getClickDetector(selector)
	return selector:FindFirstChild("ClickDetector", true)
end

-- Carpeta Conexiones del grafo al que pertenece este selector
-- Ruta: Selector → Nodo → Nodos → Grafo_ZonaX → Conexiones
local function getConexionesFolder(selector)
	local grafo = selector.Parent.Parent.Parent   -- Grafo_ZonaX (Folder)
	if not grafo then return nil end
	local c = grafo:FindFirstChild("Conexiones")
	if not c then
		c        = Instance.new("Folder")
		c.Name   = "Conexiones"
		c.Parent = grafo
	end
	return c
end

-- ── Construir lookup O(1) desde el formato lista de LevelsConfig ─────────────
-- Input:  { ["Nodo1_z1"] = {"Nodo2_z1", ...}, ... }
-- Output: { ["Nodo1_z1"] = { ["Nodo2_z1"] = true, ... }, ... }
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

-- ── Verificar adyacencia (respeta dirección) ────────────────────────────────
local function isAdjacent(nomA, nomB)
	if _adjLookup == nil then return true end  -- modo permisivo
	return (_adjLookup[nomA] and _adjLookup[nomA][nomB]) == true
end

-- ── Detectar si la arista es bidireccional (grafo no dirigido) ──────────────
local function isBidireccional(nomA, nomB)
	return isAdjacent(nomA, nomB) and isAdjacent(nomB, nomA)
end

-- ── Buscar cable existente entre dos nodos ───────────────────────────────────
local function findCableIndex(nomA, nomB)
	local key = pairKey(nomA, nomB)
	for i, c in ipairs(_cables) do
		if c.key == key then return i end
	end
	return nil
end

-- ── Recolectar todos los Selectors del nivel activo ─────────────────────────
-- Itera NivelActual/Grafos/Grafo_ZonaX/Nodos/<NodoModel>/Selector
local function getAllSelectors()
	if not _nivel then return {} end
	local selectors = {}
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
					else
						warn("[ConectarCables] Nodo sin Selector:", nodo:GetFullName())
					end
				end
			end
		end
	end
	return selectors
end

-- ════════════════════════════════════════════════════════════════════════════
-- VISUAL
-- ════════════════════════════════════════════════════════════════════════════

local function selectNodo(selector)
	if _selBox then _selBox:Destroy(); _selBox = nil end
	_selected = nil
	if selector then
		_selected          = selector
		_selBox            = Instance.new("SelectionBox")
		_selBox.Adornee    = selector.Parent    -- resaltar el nodo Model completo
		_selBox.Color3     = COLOR_SELECT
		_selBox.LineThickness         = 0.05
		_selBox.SurfaceTransparency   = 0.85
		_selBox.SurfaceColor3         = COLOR_SELECT
		_selBox.Parent     = Workspace
	end
end

local function flashError(selector)
	local part = selector:FindFirstChildOfClass("BasePart")
	if not part then return end
	local original = part.Color
	part.Color = COLOR_ERROR
	task.delay(0.3, function()
		if part and part.Parent then part.Color = original end
	end)
end

-- ════════════════════════════════════════════════════════════════════════════
-- CREAR / ELIMINAR CABLES
-- ════════════════════════════════════════════════════════════════════════════

local function crearCable(selector1, selector2)
	local nomA  = getNombreNodo(selector1)
	local nomB  = getNombreNodo(selector2)
	local key   = pairKey(nomA, nomB)
	local att1  = getAttachment(selector1)
	local att2  = getAttachment(selector2)
	local cxns  = getConexionesFolder(selector1)

	if not att1 or not att2 then
		warn("[ConectarCables] Faltan Attachments:", nomA, nomB)
		return
	end
	if not cxns then
		warn("[ConectarCables] No se encontró carpeta Conexiones para", nomA)
		return
	end

	-- RopeConstraint (visual del cable)
	local rope          = Instance.new("RopeConstraint")
	rope.Name           = "Cable_" .. nomA .. "_" .. nomB
	rope.Attachment0    = att1
	rope.Attachment1    = att2
	rope.Visible        = true
	rope.Thickness      = CABLE_THICK
	rope.Color          = BrickColor.new("Black")
	rope.Length         = (att1.WorldPosition - att2.WorldPosition).Magnitude + 0.1
	rope.Restitution    = 0
	rope.Parent         = cxns

	-- Hitbox invisible en el punto medio (para desconectar haciendo clic)
	local mid    = (att1.WorldPosition + att2.WorldPosition) / 2
	local dist   = (att1.WorldPosition - att2.WorldPosition).Magnitude
	local hitbox = Instance.new("Part")
	hitbox.Name         = "Hitbox_" .. key
	hitbox.Size         = Vector3.new(0.3, 0.3, dist)
	hitbox.CFrame       = CFrame.new(mid, att2.WorldPosition)
	hitbox.Transparency = 1
	hitbox.CanCollide   = false
	hitbox.Anchored     = true
	hitbox.Parent       = cxns

	local cd = Instance.new("ClickDetector")
	cd.MaxActivationDistance = CD_DIST
	cd.Parent                = hitbox

	local entry = { key = key, rope = rope, hitbox = hitbox }
	table.insert(_cables, entry)

	-- Clic en hitbox → desconectar (sin penalización)
	local conn = cd.MouseClick:Connect(function(player)
		if player ~= _player then return end
		for i, e in ipairs(_cables) do
			if e.hitbox == hitbox then
				e.rope:Destroy()
				e.hitbox:Destroy()
				table.remove(_cables, i)
				print("[ConectarCables] Cable desconectado (hitbox):", key)
				break
			end
		end
	end)
	table.insert(_conns, conn)

	-- Pulso visual (opcional; el cliente puede ignorarlo si no tiene handler aún)
	if _pulseEv then
		local bidir   = isBidireccional(nomA, nomB)
		local origen  = selector1.Parent
		local destino = selector2.Parent
		if not bidir then
			-- Asegurarse de que el origen sea el que tiene la dirección A→B
			if not isAdjacent(nomA, nomB) then
				origen, destino = destino, origen
			end
		end
		_pulseEv:FireAllClients("StartPulse", origen, destino, bidir)
	end

	print("[ConectarCables] Cable creado:", key)
end

local function eliminarCable(idx)
	local e = _cables[idx]
	if e then
		if e.rope   and e.rope.Parent   then e.rope:Destroy()   end
		if e.hitbox and e.hitbox.Parent then e.hitbox:Destroy() end
		table.remove(_cables, idx)
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- LÓGICA DE CONEXIÓN
-- ════════════════════════════════════════════════════════════════════════════

local function tryConnect(player, selector1, selector2)
	local nomA = getNombreNodo(selector1)
	local nomB = getNombreNodo(selector2)

	-- Mismo nodo → deseleccionar
	if nomA == nomB then
		selectNodo(nil)
		if _dragEv then _dragEv:FireClient(player, "Stop") end
		return
	end

	-- ¿Ya conectados? → desconectar
	local idx = findCableIndex(nomA, nomB)
	if idx then
		eliminarCable(idx)
		selectNodo(nil)
		if _dragEv then _dragEv:FireClient(player, "Stop") end
		print("[ConectarCables] Desconectado al reconectar:", pairKey(nomA, nomB))
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
		-- Detectar si es error de dirección (la arista existe pero en sentido contrario)
		local tipoError = "ConexionInvalida"
		if isAdjacent(nomB, nomA) then
			tipoError = "DireccionInvalida"
		end
		flashError(selector2)
		_tracker:registrarFallo(player)

		if _notifyEv then
			_notifyEv:FireClient(player, tipoError, nomA, nomB)
		end
		print("[ConectarCables] Fallo (" .. tipoError .. "):", nomA, "→", nomB)
	end

	selectNodo(nil)
	if _dragEv then _dragEv:FireClient(player, "Stop") end
end

-- ── Handler de clic en un Selector ──────────────────────────────────────────
local function onSelectorClicked(player, selector)
	if player ~= _player then return end
	if not _active then return end

	if _selected == nil then
		-- Primer clic: seleccionar
		selectNodo(selector)

		local nomA  = getNombreNodo(selector)
		local att1  = getAttachment(selector)

		if _notifyEv then
			_notifyEv:FireClient(player, "NodoSeleccionado", nomA)
		end

		-- Enviar vecinos al cliente para el efecto de arrastre visual
		if _dragEv and att1 and _adjLookup then
			local vecinos = {}
			local adjA = _adjLookup[nomA]
			if adjA then
				for nomVecino, _ in pairs(adjA) do
					table.insert(vecinos, nomVecino)
				end
			end
			_dragEv:FireClient(player, "Start", att1, vecinos)
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

-- ── activate ─────────────────────────────────────────────────────────────────
-- nivel        : Model "NivelActual" en Workspace
-- adjacencias  : tabla lista de LevelsConfig (nil = modo permisivo)
-- player       : Player activo en el nivel
-- tracker      : módulo ScoreTracker (ya inicializado con init())
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

	-- Obtener eventos remotos (solo la primera vez — están cacheados después)
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
	print("[ConectarCables] activate — nodos encontrados:", #selectors,
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

-- ── deactivate ───────────────────────────────────────────────────────────────
function ConectarCables.deactivate()
	_active = false

	-- Limpiar selección visual
	selectNodo(nil)

	-- Desconectar todos los listeners
	for _, conn in ipairs(_conns) do
		conn:Disconnect()
	end
	_conns = {}

	-- Destruir cables (limpiando cada Conexiones folder por grafo)
	-- Los ropes y hitboxes están en NivelActual/Grafos/Grafo_ZonaX/Conexiones/
	-- Se limpian automáticamente cuando LevelLoader destruye el modelo,
	-- pero los eliminamos explícitamente aquí para el caso de RestartLevel.
	for _, e in ipairs(_cables) do
		if e.rope   and e.rope.Parent   then e.rope:Destroy()   end
		if e.hitbox and e.hitbox.Parent then e.hitbox:Destroy() end
	end
	_cables = {}

	-- Detener pulsos si se dejó alguno activo
	if _pulseEv then
		_pulseEv:FireAllClients("StopAll")
	end

	_nivel     = nil
	_player    = nil
	_tracker   = nil
	_adjLookup = nil
	_selected  = nil

	print("[ConectarCables] deactivate — limpieza completa")
end

-- ── getConnections ───────────────────────────────────────────────────────────
-- Devuelve lista de claves "NomA|NomB" de cables activos.
function ConectarCables.getConnections()
	local result = {}
	for _, c in ipairs(_cables) do
		table.insert(result, c.key)
	end
	return result
end

function ConectarCables.getConnectionCount()
	return #_cables
end

return ConectarCables
