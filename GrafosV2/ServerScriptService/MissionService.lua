-- MissionService.lua
-- ModuleScript servidor: rastrea el progreso de misiones del nivel activo.
-- Evalúa misiones contra el estado del grafo (cables, nodos seleccionados).
-- Notifica al cliente via UpdateMissions RemoteEvent.
-- Dispara LevelCompleted cuando todas las misiones están completadas.
--
-- FLUJO:
--   Boot.server.lua:
--     1. MissionService.activate(config, nivelID, player, remotes, scoreTracker)
--     2. ConectarCables → llama callbacks:
--          MissionService.onCableCreated(nomA, nomB)
--          MissionService.onCableRemoved(nomA, nomB)
--          MissionService.onNodeSelected(nomNodo)
--     3. Boot conecta ZoneEntered/ZoneExited BindableEvents a:
--          MissionService.onZoneEntered(nombre)
--          MissionService.onZoneExited(nombre)
--   MissionService:
--     → Evalúa misiones pendientes en cada cambio de estado
--     → Missions son permanentes: una vez completada NO se deshace
--     → Envía estado completo vía UpdateMissions en cada cambio
--     → Cuando todas completas: dispara LevelCompleted con snapshot del ScoreTracker
--
-- Payload de UpdateMissions:
--   {
--     misiones   = { {ID, Texto, Zona, Puntos} },   -- definición completa
--     completadas = { 1, 2, ... },                  -- IDs completados
--     zonaActual  = "Zona_Estacion_1" | nil,
--     allComplete = true | nil,
--   }
--
-- Ubicación Roblox: ServerScriptService/MissionService  (ModuleScript)

local MissionService = {}

-- ── Estado ────────────────────────────────────────────────────────────────────
local _active        = false
local _player        = nil
local _nivelID       = nil
local _misiones      = {}   -- array de definición de misiones
local _completadas   = {}   -- { [ID] = true } permanente durante el nivel
local _cables        = {}   -- { [key] = true } cables conectados actualmente
local _seleccionados = {}   -- { [nomNodo] = true } nodos clickeados alguna vez
local _zonaActual    = nil  -- nombre de la zona donde está el jugador (o nil)

local _updateMissionsEv = nil
local _levelCompletedEv = nil
local _scoreTracker     = nil

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function pairKey(a, b)
	if a > b then a, b = b, a end
	return a .. "|" .. b
end

-- Cuenta cuántos cables tiene el nodo `nom` (grado en el grafo actual).
local function getCableGrade(nom)
	local count = 0
	for key, _ in pairs(_cables) do
		local a, b = key:match("^(.+)|(.+)$")
		if a == nom or b == nom then count = count + 1 end
	end
	return count
end

-- BFS: ¿todos los nodos en `nodos` son alcanzables entre sí en el grafo actual?
local function isConexo(nodos)
	if not nodos or #nodos == 0 then return false end

	-- Construir adyacencia desde cables activos
	local adj = {}
	for key, _ in pairs(_cables) do
		local a, b = key:match("^(.+)|(.+)$")
		adj[a] = adj[a] or {}
		adj[b] = adj[b] or {}
		adj[a][b] = true
		adj[b][a] = true
	end

	-- BFS desde nodos[1]
	local visited = {}
	local queue   = { nodos[1] }
	visited[nodos[1]] = true
	local head = 1
	while head <= #queue do
		local curr = queue[head]; head = head + 1
		for neighbor in pairs(adj[curr] or {}) do
			if not visited[neighbor] then
				visited[neighbor] = true
				table.insert(queue, neighbor)
			end
		end
	end

	for _, n in ipairs(nodos) do
		if not visited[n] then return false end
	end
	return true
end

-- Evalúa si una misión está actualmente satisfecha.
local function evalMision(m)
	local t = m.Tipo
	local p = m.Parametros or {}

	if t == "ARISTA_CREADA" then
		return _cables[pairKey(p.NodoA, p.NodoB)] == true

	elseif t == "ARISTA_DIRIGIDA" then
		return _cables[pairKey(p.NodoOrigen, p.NodoDestino)] == true

	elseif t == "GRADO_NODO" then
		return getCableGrade(p.Nodo) >= (p.GradoRequerido or 1)

	elseif t == "NODO_SELECCIONADO" then
		return _seleccionados[p.Nodo] == true

	elseif t == "GRAFO_CONEXO" then
		return isConexo(p.Nodos)
	end
	return false
end

-- ── buildPayload ──────────────────────────────────────────────────────────────
-- Construye el payload que se envía al cliente en cada actualización.
local function buildPayload(allComplete)
	local completadasArr = {}
	for id, _ in pairs(_completadas) do
		table.insert(completadasArr, id)
	end

	local misionesArr = {}
	for _, m in ipairs(_misiones) do
		table.insert(misionesArr, {
			ID     = m.ID,
			Texto  = m.Texto,
			Zona   = m.Zona,
			Puntos = m.Puntos,
		})
	end

	return {
		misiones    = misionesArr,
		completadas = completadasArr,
		zonaActual  = _zonaActual,
		allComplete = allComplete or nil,
	}
end

-- ── notify ────────────────────────────────────────────────────────────────────
local function notify(allComplete)
	if not _updateMissionsEv or not _player or not _player.Parent then return end
	_updateMissionsEv:FireClient(_player, buildPayload(allComplete))
end

-- ── checkAndNotify ────────────────────────────────────────────────────────────
-- Evalúa todas las misiones no completadas. Si alguna se completa, notifica.
-- Misiones son permanentes: una vez completada no se deshace.
local function checkAndNotify()
	if not _active then return end

	local changed = false
	for _, m in ipairs(_misiones) do
		if not _completadas[m.ID] and evalMision(m) then
			_completadas[m.ID] = true
			changed = true
			print("[MissionService] ✅ Misión completada —", m.ID, m.Texto)
		end
	end

	-- ¿Todas las misiones completadas?
	local total     = #_misiones
	local completadasCount = 0
	for _ in pairs(_completadas) do completadasCount = completadasCount + 1 end
	local allComplete = (total > 0 and completadasCount >= total)

	if changed then
		notify(allComplete or nil)
	end

	if allComplete then
		print("[MissionService] 🏆 ¡Todas las misiones completadas!")
		-- Obtener snapshot del ScoreTracker y disparar LevelCompleted
		if _levelCompletedEv and _scoreTracker and _player then
			local snap = _scoreTracker:finalize(_player)
			_levelCompletedEv:FireClient(_player, snap)
		end
		_active = false  -- desactivar para no disparar múltiples veces
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- API PÚBLICA
-- ════════════════════════════════════════════════════════════════════════════

-- ── activate ─────────────────────────────────────────────────────────────────
-- nivelID, player, remotes = RS.Events.Remotes, scoreTracker = ScoreTracker singleton
function MissionService.activate(config, nivelID, player, remotes, scoreTracker)
	_active        = true
	_player        = player
	_nivelID       = nivelID
	_misiones      = (config and config.Misiones) or {}
	_completadas   = {}
	_cables        = {}
	_seleccionados = {}
	_zonaActual    = nil
	_scoreTracker  = scoreTracker

	if remotes then
		_updateMissionsEv = remotes:FindFirstChild("UpdateMissions")
		_levelCompletedEv = remotes:FindFirstChild("LevelCompleted")
	end

	-- Enviar estado inicial al cliente (con retardo para dejar que HUDController arranque)
	task.delay(1, function()
		if _active and _player and _player.Parent then
			notify(nil)
		end
	end)

	print(string.format("[MissionService] activate — nivelID=%s / misiones=%d / jugador=%s",
		tostring(nivelID), #_misiones, player.Name))
end

-- ── deactivate ────────────────────────────────────────────────────────────────
function MissionService.deactivate()
	_active        = false
	_player        = nil
	_nivelID       = nil
	_misiones      = {}
	_completadas   = {}
	_cables        = {}
	_seleccionados = {}
	_zonaActual    = nil
	_scoreTracker  = nil
	_updateMissionsEv = nil
	_levelCompletedEv = nil
	print("[MissionService] deactivate")
end

-- ── onCableCreated ────────────────────────────────────────────────────────────
-- Llamado por ConectarCables cuando se crea un cable exitosamente.
function MissionService.onCableCreated(nomA, nomB)
	if not _active then return end
	_cables[pairKey(nomA, nomB)] = true
	checkAndNotify()
end

-- ── onCableRemoved ────────────────────────────────────────────────────────────
-- Llamado por ConectarCables cuando se destruye un cable.
function MissionService.onCableRemoved(nomA, nomB)
	if not _active then return end
	_cables[pairKey(nomA, nomB)] = nil
	-- Misiones ya completadas son permanentes: no re-evaluar
	-- Solo notificar al cliente (el estado de completadas no cambia)
	notify(nil)
end

-- ── onNodeSelected ────────────────────────────────────────────────────────────
-- Llamado por ConectarCables en el primer clic de un nodo.
function MissionService.onNodeSelected(nomNodo)
	if not _active then return end
	if _seleccionados[nomNodo] then return end  -- ya registrado
	_seleccionados[nomNodo] = true
	checkAndNotify()
end

-- ── onZoneEntered ─────────────────────────────────────────────────────────────
-- Llamado desde Boot cuando ZoneEntered BindableEvent se dispara.
function MissionService.onZoneEntered(nombre)
	if not _active then return end
	_zonaActual = nombre
	notify(nil)
	print("[MissionService] Zona entrada:", nombre)
end

-- ── onZoneExited ──────────────────────────────────────────────────────────────
-- Llamado desde Boot cuando ZoneExited BindableEvent se dispara.
function MissionService.onZoneExited(nombre)
	if not _active then return end
	if _zonaActual == nombre then
		_zonaActual = nil
		notify(nil)
	end
end

-- ── getMissionState ───────────────────────────────────────────────────────────
function MissionService.getMissionState()
	return buildPayload(nil)
end

return MissionService
