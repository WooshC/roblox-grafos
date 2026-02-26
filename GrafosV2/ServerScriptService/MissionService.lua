-- MissionService.lua  (VERSIÓN CORREGIDA COMPLETA)
-- Ubicación Roblox: ServerScriptService/MissionService  (ModuleScript)
--
-- CAMBIO PRINCIPAL respecto a la versión anterior:
--   • Al disparar victoria, el snap enviado al cliente incluye
--     snap.aciertos = snap.aciertosTotal (el total de conexiones correctas hechas,
--     no solo las que están activas en ese momento).
--   • DataService:saveResult recibe aciertos = snap.aciertosTotal.

local MissionService = {}

-- ── Estado interno ────────────────────────────────────────────────────────────
local _active         = false
local _player         = nil
local _nivelID        = nil
local _config         = nil
local _misiones       = {}
local _completadas    = {}
local _permanentes    = {}
local _cables         = {}
local _seleccionados  = {}
local _zonaActual     = nil
local _scoreTracker   = nil
local _dataService    = nil
local _puntosAcum     = 0
local _updateMissionsEv = nil
local _levelCompletedEv = nil

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function pairKey(a, b)
	if a > b then a, b = b, a end
	return a .. "|" .. b
end

local function countConnections(nodo)
	local count = 0
	for key, _ in pairs(_cables) do
		local a, b = key:match("^(.+)|(.+)$")
		if a == nodo or b == nodo then count = count + 1 end
	end
	return count
end

local function isReachable(start, goal, visited)
	if start == goal then return true end
	visited = visited or {}
	visited[start] = true
	for key, _ in pairs(_cables) do
		local a, b = key:match("^(.+)|(.+)$")
		local other = nil
		if a == start and not visited[b] then other = b
		elseif b == start and not visited[a] then other = a end
		if other then
			if isReachable(other, goal, visited) then return true end
		end
	end
	return false
end

-- ── Validadores ───────────────────────────────────────────────────────────────
local Validators = {}

Validators.ARISTA_CREADA = function(params)
	local key = pairKey(params.NodoA, params.NodoB)
	return _cables[key] == true
end

Validators.ARISTA_DIRIGIDA = function(params)
	local key = pairKey(params.NodoOrigen, params.NodoDestino)
	return _cables[key] == true
end

Validators.GRADO_NODO = function(params)
	return countConnections(params.Nodo) >= (params.GradoRequerido or 1)
end

Validators.NODO_SELECCIONADO = function(params)
	return _seleccionados[params.Nodo] == true
end

Validators.GRAFO_CONEXO = function(params)
	local nodos = params.Nodos or {}
	if #nodos < 2 then return true end
	for i = 1, #nodos do
		for j = 1, #nodos do
			if i ~= j then
				if not isReachable(nodos[i], nodos[j], {}) then
					return false
				end
			end
		end
	end
	return true
end

-- ── Notificar cliente ─────────────────────────────────────────────────────────
local function buildPayload(overrideAllComplete)
	local porZona = {}
	for _, m in ipairs(_misiones) do
		local z = m.Zona or "General"
		if not porZona[z] then porZona[z] = { total=0, completadas=0, misiones={} } end
		local estado = _completadas[m.ID] and "completada" or "pendiente"
		table.insert(porZona[z].misiones, {
			id        = m.ID,
			texto     = m.Texto,
			puntos    = m.Puntos or 0,
			estado    = estado,
			zona      = z,
		})
		porZona[z].total = porZona[z].total + 1
		if estado == "completada" then porZona[z].completadas = porZona[z].completadas + 1 end
	end
	return {
		porZona      = porZona,
		zonaActual   = _zonaActual,
		allComplete  = overrideAllComplete,
	}
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
		if _permanentes[m.ID] then continue end  -- ya completada permanentemente

		local validator = Validators[m.Tipo]
		if not validator then continue end

		local ok = validator(m.Parametros or {})

		if ok and not _completadas[m.ID] then
			_completadas[m.ID] = true
			_permanentes[m.ID] = true  -- permanente: no se deshace
			_puntosAcum = _puntosAcum + (m.Puntos or 0)
			if _scoreTracker then _scoreTracker:setMisionPuntaje(_player, _puntosAcum) end
			changed = true
			print(string.format("[MissionService] ✅ Misión %d completada — +%d pts (total: %d)",
				m.ID, m.Puntos or 0, _puntosAcum))
		elseif not ok and _completadas[m.ID] and not _permanentes[m.ID] then
			_completadas[m.ID] = nil
			_puntosAcum = math.max(0, _puntosAcum - (m.Puntos or 0))
			if _scoreTracker then _scoreTracker:setMisionPuntaje(_player, _puntosAcum) end
			changed = true
		end
	end

	local total            = #_misiones
	local completadasCount = 0
	for _ in pairs(_completadas) do completadasCount = completadasCount + 1 end
	local allComplete = (total > 0 and completadasCount >= total)

	if changed then
		notify(allComplete or nil)
	end

	-- ── VICTORIA ──────────────────────────────────────────────────────────
	if allComplete then
		print("[MissionService] 🏆 ¡Todas las misiones completadas! — puntosAcum:", _puntosAcum)

		if _levelCompletedEv and _scoreTracker and _player then
			local snap = _scoreTracker:finalize(_player)

			print(string.format(
				"[MissionService] Snapshot → puntaje=%d / aciertosTotal=%d / conexiones=%d / fallos=%d / tiempo=%d",
				snap.puntajeBase, snap.aciertosTotal or 0, snap.conexiones, snap.fallos, snap.tiempo
				))

			-- Guardar en DataStore antes de mostrar victoria
			if _dataService and _nivelID ~= nil then
				local puntuacion = _config and _config.Puntuacion or {}
				local estrellas  = 0
				if     snap.puntajeBase >= (puntuacion.TresEstrellas or 999999) then estrellas = 3
				elseif snap.puntajeBase >= (puntuacion.DosEstrellas  or 999999) then estrellas = 2
				elseif snap.puntajeBase >  0                                    then estrellas = 1
				end

				-- ← CORRECCIÓN: usar aciertosTotal (no conexiones actuales)
				local aciertosGuardar = snap.aciertosTotal or snap.conexiones

				_dataService:saveResult(_player, _nivelID, {
					highScore   = snap.puntajeBase,
					estrellas   = estrellas,
					aciertos    = aciertosGuardar,
					fallos      = snap.fallos,
					tiempoMejor = snap.tiempo,
				})
				print("[MissionService] 💾 Guardado — estrellas:", estrellas, "/ aciertos:", aciertosGuardar)
			end

			-- ← CORRECCIÓN: enviar snap al cliente con campo "aciertos" explícito
			local snapCliente = {
				nivelID     = snap.nivelID,
				conexiones  = snap.conexiones,
				aciertos    = snap.aciertosTotal or snap.conexiones,  -- ← para FilaAciertos
				fallos      = snap.fallos,
				tiempo      = snap.tiempo,
				puntajeBase = snap.puntajeBase,
			}
			_levelCompletedEv:FireClient(_player, snapCliente)
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