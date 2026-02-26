-- MissionService.lua
-- ModuleScript servidor: rastrea el progreso de misiones del nivel activo.
-- Evalúa misiones contra el estado del grafo (cables, nodos seleccionados).
-- Notifica al cliente via UpdateMissions RemoteEvent.
-- Dispara LevelCompleted cuando todas las misiones están completadas.
--
-- Ubicación Roblox: ServerScriptService/MissionService  (ModuleScript)

local MissionService = {}

-- ── Estado ────────────────────────────────────────────────────────────────────
local _active        = false
local _player        = nil
local _nivelID       = nil
local _misiones      = {}
local _completadas   = {}   -- { [ID] = true } misiones actualmente satisfechas
local _permanentes   = {}   -- { [ID] = true } no se revocan (NODO_SELECCIONADO)
local _cables        = {}   -- { [key] = true } cables conectados actualmente
local _seleccionados = {}   -- { [nomNodo] = true } nodos clickeados alguna vez
local _zonaActual    = nil
local _puntosAcum    = 0    -- puntos acumulados por misiones completadas

local _updateMissionsEv = nil
local _levelCompletedEv = nil
local _scoreTracker     = nil
local _dataService      = nil
local _config           = nil

-- Tipos que no se revocan una vez completados
local TIPOS_PERMANENTES = {
	NODO_SELECCIONADO = true,
}

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function pairKey(a, b)
	if a > b then a, b = b, a end
	return a .. "|" .. b
end

local function getCableGrade(nom)
	local count = 0
	for key in pairs(_cables) do
		local a, b = key:match("^(.+)|(.+)$")
		if a == nom or b == nom then count = count + 1 end
	end
	return count
end

local function isConexo(nodos)
	if not nodos or #nodos == 0 then return false end
	local adj = {}
	for key in pairs(_cables) do
		local a, b = key:match("^(.+)|(.+)$")
		adj[a] = adj[a] or {}; adj[b] = adj[b] or {}
		adj[a][b] = true; adj[b][a] = true
	end
	local visited = { [nodos[1]] = true }
	local queue   = { nodos[1] }
	local head    = 1
	while head <= #queue do
		local curr = queue[head]; head = head + 1
		for nbr in pairs(adj[curr] or {}) do
			if not visited[nbr] then
				visited[nbr] = true
				table.insert(queue, nbr)
			end
		end
	end
	for _, n in ipairs(nodos) do
		if not visited[n] then return false end
	end
	return true
end

local function evalMision(m)
	local t, p = m.Tipo, m.Parametros or {}
	if     t == "ARISTA_CREADA"    then return _cables[pairKey(p.NodoA, p.NodoB)] == true
	elseif t == "ARISTA_DIRIGIDA"  then return _cables[pairKey(p.NodoOrigen, p.NodoDestino)] == true
	elseif t == "GRADO_NODO"       then return getCableGrade(p.Nodo) >= (p.GradoRequerido or 1)
	elseif t == "NODO_SELECCIONADO" then return _seleccionados[p.Nodo] == true
	elseif t == "GRAFO_CONEXO"     then return isConexo(p.Nodos)
	end
	return false
end

local function buildPayload(allComplete)
	local completadasArr, misionesArr = {}, {}
	for id in pairs(_completadas) do table.insert(completadasArr, id) end
	for _, m in ipairs(_misiones) do
		table.insert(misionesArr, { ID=m.ID, Texto=m.Texto, Zona=m.Zona, Puntos=m.Puntos })
	end
	return { misiones=misionesArr, completadas=completadasArr, zonaActual=_zonaActual, allComplete=allComplete or nil }
end

local function notify(allComplete)
	if not _updateMissionsEv or not _player or not _player.Parent then return end
	_updateMissionsEv:FireClient(_player, buildPayload(allComplete))
end

-- ── checkAndNotify ────────────────────────────────────────────────────────────
local function checkAndNotify()
	if not _active then return end

	local changed = false

	for _, m in ipairs(_misiones) do
		local cumplida     = evalMision(m)
		local estabaMarca  = _completadas[m.ID] == true
		local esPermanente = _permanentes[m.ID] == true

		if cumplida and not estabaMarca then
			_completadas[m.ID] = true
			if TIPOS_PERMANENTES[m.Tipo] then _permanentes[m.ID] = true end
			_puntosAcum = _puntosAcum + (m.Puntos or 0)
			changed     = true
			print("[MissionService] ✅ Misión completada —", m.ID, m.Texto, "(+" .. tostring(m.Puntos or 0) .. " pts)")

		elseif not cumplida and estabaMarca and not esPermanente then
			_completadas[m.ID] = nil
			_puntosAcum = math.max(0, _puntosAcum - (m.Puntos or 0))
			changed     = true
			print("[MissionService] ↩ Misión revocada —", m.ID, m.Texto, "(-" .. tostring(m.Puntos or 0) .. " pts)")
		end
	end

	-- 1. Actualizar HUD de puntaje con el total actual
	if changed and _scoreTracker and _player then
		_scoreTracker:setMisionPuntaje(_player, _puntosAcum)
	end

	-- 2. Comprobar victoria
	local total            = #_misiones
	local completadasCount = 0
	for _ in pairs(_completadas) do completadasCount = completadasCount + 1 end
	local allComplete = (total > 0 and completadasCount >= total)

	-- 3. Notificar cliente con estado actualizado
	if changed then
		notify(allComplete or nil)
	end

	-- 4. Disparar victoria SOLO si todas completas
	--    setMisionPuntaje ya sincronizó _data en ScoreTracker → finalize() lee valor correcto
	if allComplete then
		print("[MissionService] 🏆 ¡Todas las misiones completadas! — puntosAcum:", _puntosAcum)
		if _levelCompletedEv and _scoreTracker and _player then
			local snap = _scoreTracker:finalize(_player)
			print(string.format("[MissionService] Snapshot → puntaje=%d / conexiones=%d / fallos=%d / tiempo=%d",
				snap.puntajeBase, snap.conexiones, snap.fallos, snap.tiempo))

			-- Guardar resultado en DataStore antes de mostrar victoria al cliente
			if _dataService and _nivelID ~= nil then
				local puntuacion = _config and _config.Puntuacion or {}
				local estrellas  = 0
				if     snap.puntajeBase >= (puntuacion.TresEstrellas or 999999) then estrellas = 3
				elseif snap.puntajeBase >= (puntuacion.DosEstrellas  or 999999) then estrellas = 2
				elseif snap.puntajeBase >  0                                    then estrellas = 1
				end
				_dataService:saveResult(_player, _nivelID, {
					highScore   = snap.puntajeBase,
					estrellas   = estrellas,
					aciertos    = snap.conexiones,
					fallos      = snap.fallos,
					tiempoMejor = snap.tiempo,
				})
				print("[MissionService] 💾 Resultado guardado — estrellas:", estrellas)
			end

			_levelCompletedEv:FireClient(_player, snap)
		end
		_active = false
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- API PÚBLICA
-- ════════════════════════════════════════════════════════════════════════════

function MissionService.activate(config, nivelID, player, remotes, scoreTracker, dataService)
	_active        = true
	_player        = player
	_nivelID       = nivelID
	_config        = config
	_misiones      = (config and config.Misiones) or {}
	_completadas   = {}
	_permanentes   = {}
	_cables        = {}
	_seleccionados = {}
	_zonaActual    = nil
	_scoreTracker  = scoreTracker
	_dataService   = dataService
	_puntosAcum    = 0

	if remotes then
		_updateMissionsEv = remotes:FindFirstChild("UpdateMissions")
		_levelCompletedEv = remotes:FindFirstChild("LevelCompleted")
	end

	task.delay(1, function()
		if _active and _player and _player.Parent then notify(nil) end
	end)

	print(string.format("[MissionService] activate — nivelID=%s / misiones=%d / jugador=%s",
		tostring(nivelID), #_misiones, player.Name))
end

function MissionService.deactivate()
	_active=false; _player=nil; _nivelID=nil
	_misiones={}; _completadas={}; _permanentes={}
	_cables={}; _seleccionados={}; _zonaActual=nil
	_scoreTracker=nil; _puntosAcum=0
	_updateMissionsEv=nil; _levelCompletedEv=nil
	_dataService=nil; _config=nil
	print("[MissionService] deactivate")
end

function MissionService.onCableCreated(nomA, nomB)
	if not _active then return end
	_cables[pairKey(nomA, nomB)] = true
	checkAndNotify()
end

function MissionService.onCableRemoved(nomA, nomB)
	if not _active then return end
	_cables[pairKey(nomA, nomB)] = nil
	checkAndNotify()
end

function MissionService.onNodeSelected(nomNodo)
	if not _active then return end
	if _seleccionados[nomNodo] then return end
	_seleccionados[nomNodo] = true
	checkAndNotify()
end

function MissionService.onZoneEntered(nombre)
	if not _active then return end
	_zonaActual = nombre
	notify(nil)
	print("[MissionService] Zona entrada:", nombre)
end

function MissionService.onZoneExited(nombre)
	if not _active then return end
	if _zonaActual == nombre then _zonaActual = nil; notify(nil) end
end

function MissionService.getMissionState()
	return buildPayload(nil)
end

return MissionService	