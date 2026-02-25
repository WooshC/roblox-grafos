-- DataService.lua
-- Centraliza el acceso a DataStore para el progreso del jugador por nivel.
-- Expone getProgressForClient() para responder GetPlayerProgress.
-- Expone saveResult() para guardar resultados al completar un nivel.
--
-- Ubicación Roblox: ServerScriptService/DataService.lua  (ModuleScript)

local DataService = {}

local DataStoreService = game:GetService("DataStoreService")
local RS               = game:GetService("ReplicatedStorage")

-- Nombre del DataStore — cambia la versión si necesitas resetear todo el progreso
local store = DataStoreService:GetDataStore("EDAQuestV2_Progress_v1")

-- Config centralizada (ReplicatedStorage/Config/LevelsConfig)
local LEVELS_CONFIG = require(RS:WaitForChild("Config", 10):WaitForChild("LevelsConfig", 10))

-- Datos por defecto para un nivel (un jugador nuevo)
local DEFAULT_LEVEL = {
	desbloqueado = false,
	estrellas    = 0,
	highScore    = 0,
	aciertos     = 0,
	fallos       = 0,
	tiempoMejor  = 0,   -- en segundos
	intentos     = 0,
}

-- Cache en memoria para no llamar a DataStore en cada petición
local cache = {}  -- [userId] = { ["0"]={...}, ["1"]={...}, ... }

-- ── Construye la estructura de datos vacía para un jugador nuevo ────────────
local function makeDefaultData()
	local data = {}
	for i = 0, 4 do
		local row = {}
		for k, v in pairs(DEFAULT_LEVEL) do row[k] = v end
		data[tostring(i)] = row
	end
	data["0"].desbloqueado = true   -- nivel 0 siempre desbloqueado
	return data
end

-- ── Carga los datos del jugador (DataStore → cache) ────────────────────────
function DataService:load(player)
	if cache[player.UserId] then
		return cache[player.UserId]
	end

	local key = "player_" .. player.UserId
	local ok, raw = pcall(function()
		return store:GetAsync(key)
	end)

	local data = (ok and raw) or makeDefaultData()

	-- Rellenar niveles que falten (jugador antiguo antes de que se agregó un nivel)
	for i = 0, 4 do
		local k = tostring(i)
		if not data[k] then
			local row = {}
			for kk, vv in pairs(DEFAULT_LEVEL) do row[kk] = vv end
			if i == 0 then row.desbloqueado = true end
			data[k] = row
		end
	end

	cache[player.UserId] = data
	print("[DataService] Datos cargados para", player.Name)
	return data
end

-- ── Guarda los datos del jugador en DataStore ──────────────────────────────
function DataService:save(player)
	local data = cache[player.UserId]
	if not data then return end

	local key = "player_" .. player.UserId
	local ok, err = pcall(function()
		store:SetAsync(key, data)
	end)
	if ok then
		print("[DataService] Progreso guardado para", player.Name)
	else
		warn("[DataService] ❌ Error al guardar progreso de", player.Name, "—", err)
	end
end

-- ── Devuelve el progreso formateado para el cliente ────────────────────────
-- Retorna tabla indexada por nivelID (número) lista para enviar por RemoteFunction
function DataService:getProgressForClient(player)
	local data = self:load(player)
	local result = {}

	for i = 0, 4 do
		local k   = tostring(i)
		local ld  = data[k] or {}
		local cfg = LEVELS_CONFIG[i] or {}

		local desbloqueado = ld.desbloqueado or (i == 0)
		local estrellas    = ld.estrellas or 0

		-- Calcular status derivado
		local status = (not desbloqueado) and "bloqueado"
			or (estrellas > 0)            and "completado"
			or                                 "disponible"

		-- IMPORTANTE: usar clave string ("0","1",...) en lugar de numérica (0,1,...).
		-- Roblox descarta la clave numérica 0 al serializar tablas en RemoteFunctions
		-- porque sus tablas empiezan desde 1. Con string keys el dato llega correctamente.
		result[k] = {
			nivelID      = i,
			nombre       = cfg.Nombre   or ("Nivel " .. i),
			algoritmo    = cfg.Algoritmo,
			status       = status,
			desbloqueado = desbloqueado,
			estrellas    = estrellas,
			highScore    = ld.highScore  or 0,
			aciertos     = ld.aciertos   or 0,
			fallos       = ld.fallos     or 0,
			tiempoMejor  = ld.tiempoMejor or 0,   -- segundos; el cliente formatea
			intentos     = ld.intentos   or 0,
		}
	end

	return result
end

-- ── Guarda el resultado de completar un nivel ──────────────────────────────
-- result = { highScore, estrellas, aciertos, fallos, tiempoMejor }
function DataService:saveResult(player, nivelID, result)
	local data = self:load(player)
	local k    = tostring(nivelID)
	local ld   = data[k] or {}

	ld.intentos = (ld.intentos or 0) + 1

	-- Solo actualizar si el nuevo puntaje supera el récord anterior
	if (result.highScore or 0) > (ld.highScore or 0) then
		ld.highScore   = result.highScore
		ld.estrellas   = result.estrellas
		ld.aciertos    = result.aciertos
		ld.fallos      = result.fallos
		ld.tiempoMejor = result.tiempoMejor
	end

	-- Desbloquear el siguiente nivel al conseguir al menos 1 estrella
	if (result.estrellas or 0) > 0 and nivelID < 4 then
		local nextK = tostring(nivelID + 1)
		if data[nextK] then
			data[nextK].desbloqueado = true
		end
	end

	data[k] = ld

	-- Guardar en DataStore de forma asíncrona para no bloquear el gameplay
	task.spawn(function()
		self:save(player)
	end)
end

-- ── Limpiar cache al salir ─────────────────────────────────────────────────
function DataService:onPlayerLeaving(player)
	self:save(player)
	cache[player.UserId] = nil
end

return DataService
