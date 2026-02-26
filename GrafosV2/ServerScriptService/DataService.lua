-- DataService.lua  (CORREGIDO)
-- Ubicación Roblox: ServerScriptService/DataService.lua  (ModuleScript)
--
-- CAMBIOS:
--   • saveResult guarda SIEMPRE los datos del intento actual, no solo si mejora el highScore.
--   • intentos siempre se incrementa.
--   • Los datos guardados son del intento actual (no del "mejor").

local DataService = {}

local DataStoreService = game:GetService("DataStoreService")
local RS               = game:GetService("ReplicatedStorage")

local store = DataStoreService:GetDataStore("EDAQuestV2_Progress_v1")

local LEVELS_CONFIG = require(RS:WaitForChild("Config", 10):WaitForChild("LevelsConfig", 10))

local DEFAULT_LEVEL = {
	desbloqueado = false,
	estrellas    = 0,
	highScore    = 0,
	aciertos     = 0,
	fallos       = 0,
	tiempoMejor  = 0,
	intentos     = 0,
}

local cache = {}

local function makeDefaultData()
	local data = {}
	for i = 0, 4 do
		local row = {}
		for k, v in pairs(DEFAULT_LEVEL) do row[k] = v end
		data[tostring(i)] = row
	end
	data["0"].desbloqueado = true
	return data
end

function DataService:load(player)
	if cache[player.UserId] then return cache[player.UserId] end

	local key = "player_" .. player.UserId
	local ok, raw = pcall(function() return store:GetAsync(key) end)
	local data = (ok and raw) or makeDefaultData()

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

function DataService:save(player)
	local data = cache[player.UserId]
	if not data then return end
	local key = "player_" .. player.UserId
	local ok, err = pcall(function() store:SetAsync(key, data) end)
	if ok then
		print("[DataService] Progreso guardado para", player.Name)
	else
		warn("[DataService] ❌ Error al guardar:", err)
	end
end

-- ── getProgressForClient ───────────────────────────────────────────────────
-- IMPORTANTE: Las claves son STRING ("0", "1", ...) no números.
-- Roblox descarta índice [0] numérico al pasar por RemoteFunction.
-- El cliente usa tonumber(k) para recuperar el nivelID numérico.
function DataService:getProgressForClient(player)
	local data   = self:load(player)
	local result = {}

	for i = 0, 4 do
		local k   = tostring(i)
		local ld  = data[k] or {}
		local cfg = LEVELS_CONFIG[i] or {}

		local desbloqueado = ld.desbloqueado or (i == 0)
		local estrellas    = ld.estrellas or 0

		local status = (not desbloqueado) and "bloqueado"
			or (estrellas > 0)            and "completado"
			or                                 "disponible"

		-- ⚠️ Clave STRING: result["0"], result["1"], ... result["4"]
		result[k] = {
			nivelID      = i,
			nombre       = cfg.Nombre      or ("Nivel " .. i),
			imageId      = cfg.ImageId     or "",
			algoritmo    = cfg.Algoritmo,
			tag          = cfg.Tag         or ("NIVEL " .. i),
			emoji        = cfg.Emoji       or "🔵",
			descripcion  = cfg.Descripcion or cfg.DescripcionCorta or "",
			conceptos    = cfg.Conceptos   or {},
			seccion      = cfg.Seccion     or "NIVELES",
			status       = status,
			desbloqueado = desbloqueado,
			estrellas    = estrellas,
			highScore    = ld.highScore   or 0,
			aciertos     = ld.aciertos    or 0,
			fallos       = ld.fallos      or 0,
			tiempoMejor  = ld.tiempoMejor or 0,
			intentos     = ld.intentos    or 0,
		}
	end

	return result
end

-- ── saveResult ─────────────────────────────────────────────────────────────
-- CORRECCIÓN: guarda SIEMPRE los datos del intento actual (no solo si mejora).
-- Los intentos siempre se incrementan.
-- El jugador SOLO ve datos de su intento más reciente, no del mejor histórico.
function DataService:saveResult(player, nivelID, result)
	local data = self:load(player)
	local k    = tostring(nivelID)
	local ld   = data[k] or {}

	-- ← SIEMPRE incrementar intentos
	ld.intentos = (ld.intentos or 0) + 1

	-- ← SIEMPRE sobrescribir con datos del intento actual
	ld.highScore   = result.highScore   or 0
	ld.estrellas   = result.estrellas   or 0
	ld.aciertos    = result.aciertos    or 0
	ld.fallos      = result.fallos      or 0
	ld.tiempoMejor = result.tiempoMejor or 0

	-- Desbloquear siguiente nivel si hay estrellas
	if (result.estrellas or 0) > 0 and nivelID < 4 then
		local nextK = tostring(nivelID + 1)
		if data[nextK] then data[nextK].desbloqueado = true end
	end

	data[k] = ld
	print(string.format(
		"[DataService] saveResult — nivelID=%d intentos=%d aciertos=%d fallos=%d highScore=%d estrellas=%d",
		nivelID, ld.intentos, ld.aciertos, ld.fallos, ld.highScore, ld.estrellas
		))

	-- Guardar en DataStore de forma asíncrona
	task.spawn(function() self:save(player) end)
end

function DataService:onPlayerLeaving(player)
	self:save(player)
	cache[player.UserId] = nil
end

return DataService