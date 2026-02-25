-- DataService.lua
-- Centraliza el acceso a DataStore para el progreso del jugador por nivel.
-- CORRECCIONES v2.1:
--   - makeDefaultData usa LEVELS_CONFIG para determinar el número real de niveles
--   - getProgressForClient garantiza que todos los campos existen antes de enviar
--   - cache con mutex simple para evitar doble-load concurrente
--   - compatibilidad con LevelsConfig completo (GarfosV1) o stub (GrafosV2)
--
-- Ubicación Roblox: ServerScriptService/DataService.lua  (ModuleScript)

local DataService = {}

local DataStoreService = game:GetService("DataStoreService")
local RS               = game:GetService("ReplicatedStorage")

-- Nombre del DataStore — incrementa la versión para resetear progreso en producción
local store = DataStoreService:GetDataStore("EDAQuestV2_Progress_v1")

-- ── Cargar LevelsConfig — soporta ubicación en Config/ o directamente en RS ──
local levelsConfigModule = (RS:FindFirstChild("Config") and RS.Config:FindFirstChild("LevelsConfig"))
	or RS:FindFirstChild("LevelsConfig")

if not levelsConfigModule then
	error("[DataService] ❌ No se encontró LevelsConfig en ReplicatedStorage ni en ReplicatedStorage/Config")
end

local LEVELS_CONFIG = require(levelsConfigModule)

-- Determinar rango de niveles desde el config (no hardcodear 0-4)
local MIN_LEVEL, MAX_LEVEL = math.huge, -math.huge
for id, _ in pairs(LEVELS_CONFIG) do
	if type(id) == "number" then
		MIN_LEVEL = math.min(MIN_LEVEL, id)
		MAX_LEVEL = math.max(MAX_LEVEL, id)
	end
end
if MIN_LEVEL == math.huge then MIN_LEVEL = 0; MAX_LEVEL = 4 end  -- fallback seguro

-- ── Estructura por defecto para un nivel sin jugar ────────────────────────
local DEFAULT_LEVEL = {
	desbloqueado = false,
	estrellas    = 0,
	highScore    = 0,
	aciertos     = 0,
	fallos       = 0,
	tiempoMejor  = 0,   -- segundos
	intentos     = 0,
}

-- ── Cache: [userId] = data  /  loadingSet: evita doble-load concurrente ───
local cache      = {}
local loadingSet = {}   -- [userId] = true mientras carga

-- ── Construye la estructura vacía para un jugador nuevo ───────────────────
local function makeDefaultData()
	local data = {}
	for i = MIN_LEVEL, MAX_LEVEL do
		local row = {}
		for k, v in pairs(DEFAULT_LEVEL) do row[k] = v end
		data[tostring(i)] = row
	end
	-- Nivel inicial siempre desbloqueado
	if data[tostring(MIN_LEVEL)] then
		data[tostring(MIN_LEVEL)].desbloqueado = true
	end
	return data
end

-- ── Rellena campos que falten en datos antiguos (migraciones) ─────────────
local function migrateData(data)
	for i = MIN_LEVEL, MAX_LEVEL do
		local k = tostring(i)
		if not data[k] then
			local row = {}
			for kk, vv in pairs(DEFAULT_LEVEL) do row[kk] = vv end
			if i == MIN_LEVEL then row.desbloqueado = true end
			data[k] = row
		else
			-- Asegurar que no falte ningún campo
			for kk, vv in pairs(DEFAULT_LEVEL) do
				if data[k][kk] == nil then
					data[k][kk] = vv
				end
			end
		end
	end
	return data
end

-- ── Carga los datos del jugador (DataStore → cache) ───────────────────────
-- Seguro para llamar concurrentemente: solo hace GetAsync una vez.
function DataService:load(player)
	local uid = player.UserId

	-- Ya en cache
	if cache[uid] then
		return cache[uid]
	end

	-- Otro hilo ya está cargando — esperar
	if loadingSet[uid] then
		local t = 0
		repeat task.wait(0.05); t = t + 0.05 until cache[uid] or t > 5
		return cache[uid] or makeDefaultData()
	end

	loadingSet[uid] = true

	local key = "player_" .. uid
	local ok, raw = pcall(function()
		return store:GetAsync(key)
	end)

	local data = (ok and type(raw) == "table" and raw) or makeDefaultData()
	data = migrateData(data)

	cache[uid]      = data
	loadingSet[uid] = nil

	print("[DataService] ✅ Datos cargados para", player.Name,
		"— niveles:", MIN_LEVEL, "→", MAX_LEVEL)
	return data
end

-- ── Persiste los datos en DataStore ──────────────────────────────────────
function DataService:save(player)
	local uid  = player.UserId
	local data = cache[uid]
	if not data then
		warn("[DataService] save() llamado sin datos en cache para", player.Name)
		return
	end

	local key = "player_" .. uid
	local ok, err = pcall(function()
		store:SetAsync(key, data)
	end)

	if ok then
		print("[DataService] 💾 Progreso guardado para", player.Name)
	else
		warn("[DataService] ❌ Error al guardar progreso de", player.Name, "—", err)
	end
end

-- ── Devuelve el progreso formateado para el cliente ───────────────────────
-- Retorna tabla [nivelID] = { status, estrellas, highScore, aciertos, ... }
-- CORRECCIÓN: garantiza que TODOS los campos existen antes de enviar.
function DataService:getProgressForClient(player)
	local data   = self:load(player)
	local result = {}

	for i = MIN_LEVEL, MAX_LEVEL do
		local k   = tostring(i)
		local ld  = data[k] or {}
		local cfg = LEVELS_CONFIG[i] or {}

		local desbloqueado = (ld.desbloqueado == true) or (i == MIN_LEVEL)
		local estrellas    = tonumber(ld.estrellas) or 0
		local highScore    = tonumber(ld.highScore)  or 0
		local intentos     = tonumber(ld.intentos)   or 0

		-- status derivado — la UI solo necesita este string
		local status
		if not desbloqueado then
			status = "bloqueado"
		elseif estrellas > 0 then
			status = "completado"
		else
			status = "disponible"
		end

		result[i] = {
			nivelID      = i,
			nombre       = (type(cfg.Nombre) == "string" and cfg.Nombre) or ("Nivel " .. i),
			algoritmo    = cfg.Algoritmo or nil,
			status       = status,
			desbloqueado = desbloqueado,
			estrellas    = estrellas,
			highScore    = highScore,
			aciertos     = tonumber(ld.aciertos)    or 0,
			fallos       = tonumber(ld.fallos)       or 0,
			tiempoMejor  = tonumber(ld.tiempoMejor)  or 0,  -- el cliente formatea a mm:ss
			intentos     = intentos,
		}
	end

	return result
end

-- ── Guarda el resultado de completar un nivel ─────────────────────────────
-- result = { highScore, estrellas, aciertos, fallos, tiempoMejor }
function DataService:saveResult(player, nivelID, result)
	local data = self:load(player)
	local k    = tostring(nivelID)

	if not data[k] then
		warn("[DataService] saveResult: nivelID", nivelID, "no existe en datos")
		return
	end

	local ld = data[k]
	ld.intentos = (ld.intentos or 0) + 1

	-- Solo actualizar récord si el nuevo puntaje supera al anterior
	local newScore = tonumber(result.highScore) or 0
	local oldScore = tonumber(ld.highScore)     or 0

	if newScore > oldScore then
		ld.highScore   = newScore
		ld.estrellas   = math.max(0, math.min(3, tonumber(result.estrellas) or 0))
		ld.aciertos    = tonumber(result.aciertos)    or 0
		ld.fallos      = tonumber(result.fallos)       or 0
		ld.tiempoMejor = tonumber(result.tiempoMejor)  or 0
		print("[DataService] 🏆 Nuevo récord en nivel", nivelID, "→", newScore, "pts")
	else
		-- Siempre actualizar estrellas si son mejores (aunque el puntaje sea menor)
		local newStars = tonumber(result.estrellas) or 0
		if newStars > (ld.estrellas or 0) then
			ld.estrellas = newStars
		end
	end

	-- Desbloquear el siguiente nivel al obtener al menos 1 estrella
	local estrellas = tonumber(ld.estrellas) or 0
	if estrellas > 0 and nivelID < MAX_LEVEL then
		local nextK = tostring(nivelID + 1)
		if data[nextK] then
			data[nextK].desbloqueado = true
			print("[DataService] 🔓 Nivel", nivelID + 1, "desbloqueado para", player.Name)
		end
	end

	data[k] = ld

	-- Guardar en DataStore de forma asíncrona
	task.spawn(function()
		self:save(player)
	end)
end

-- ── Limpieza al desconectarse ─────────────────────────────────────────────
function DataService:onPlayerLeaving(player)
	self:save(player)
	cache[player.UserId]      = nil
	loadingSet[player.UserId] = nil
end

return DataService