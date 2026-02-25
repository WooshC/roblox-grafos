-- LevelLoader.lua
-- Carga y descarga modelos de nivel en el Workspace.
-- Fase 0: solo carga el modelo, sin inicializar servicios de gameplay.
-- Fase futura: aquí se añadirá GraphService:init(), ScoreTracker:reset(), etc.
--
-- Ubicación Roblox: ServerScriptService/LevelLoader.lua

local LevelLoader = {}

local RS        = game:GetService("ReplicatedStorage")
local SS        = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

-- Config centralizada (ReplicatedStorage/Config/LevelsConfig)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local configFolder = ReplicatedStorage:FindFirstChild("Config")
if not configFolder then
	error("No se encontró la carpeta 'Config' en ReplicatedStorage")
end

local levelsConfigModule = configFolder:FindFirstChild("LevelsConfig")
if not levelsConfigModule then
	error("No se encontró el módulo 'LevelsConfig' dentro de Config")
end

local LEVELS_CONFIG = require(levelsConfigModule)

-- Esperar eventos (EventRegistry debe haber corrido antes que Boot)
local eventsFolder  = RS:WaitForChild("Events", 15)
local remotesFolder = eventsFolder:WaitForChild("Remotes", 5)
local levelReadyEv  = remotesFolder:WaitForChild("LevelReady", 5)
local levelUnloadEv = remotesFolder:WaitForChild("LevelUnloaded", 5)

local bindablesFolder = eventsFolder:WaitForChild("Bindables", 5)
local levelLoadedBE   = bindablesFolder:WaitForChild("LevelLoaded", 5)
local levelUnloadedBE = bindablesFolder:WaitForChild("LevelUnloaded", 5)

local NIVEL_ACTUAL = "NivelActual"

-- ── Descarga el nivel actual ───────────────────────────────────────────────
function LevelLoader:unload()
	local existing = Workspace:FindFirstChild(NIVEL_ACTUAL)
	if existing then
		existing:Destroy()
		levelUnloadedBE:Fire()
		print("[LevelLoader] Nivel anterior descargado.")
	end
end

-- ── Carga un nivel por ID ──────────────────────────────────────────────────
-- player: a quién notificar con LevelReady. nil = notifica a todos.
function LevelLoader:load(nivelID, player)
	local config = LEVELS_CONFIG[nivelID]
	if not config then
		warn("[LevelLoader] ❌ nivelID no existe en config:", nivelID)
		return false
	end

	-- Descargar nivel anterior limpiamente
	self:unload()

	-- Buscar modelo: primero ServerStorage/Niveles, luego Workspace directo
	local modelName = config.Modelo
	local sourceModel = nil

	local ssNiveles = SS:FindFirstChild("Niveles")
	if ssNiveles then
		sourceModel = ssNiveles:FindFirstChild(modelName)
	end

	if not sourceModel then
		-- Buscar en cualquier lugar de ServerStorage
		sourceModel = SS:FindFirstChild(modelName, true)
	end

	if not sourceModel then
		-- Fallback: buscar en Workspace (para pruebas en Studio)
		sourceModel = Workspace:FindFirstChild(modelName)
	end

	if not sourceModel then
		warn("[LevelLoader] ❌ Modelo no encontrado:", modelName,
			"— Asegúrate de que esté en ServerStorage/Niveles/", modelName)
		-- Notificar el error al cliente para que pueda mostrar mensaje
		local payload = {
			nivelID  = nivelID,
			nombre   = config.Nombre,
			error    = "Modelo '" .. modelName .. "' no encontrado en ServerStorage",
		}
		if player then
			levelReadyEv:FireClient(player, payload)
		else
			levelReadyEv:FireAllClients(payload)
		end
		return false
	end

	-- Clonar desde ServerStorage (no movemos el original)
	local nivelActual
	if sourceModel:IsDescendantOf(SS) then
		nivelActual = sourceModel:Clone()
	else
		-- Si ya está en Workspace, lo clonamos igual para mantener original
		nivelActual = sourceModel:Clone()
	end

	nivelActual.Name = NIVEL_ACTUAL
	nivelActual.Parent = Workspace

	print("[LevelLoader] ✅ Nivel cargado:", config.Nombre, "(ID:", nivelID, ")")

	-- ── Cargar personaje y teleportar al SpawnLocation del nivel ──────────
	if player then
		local spawnLoc = nivelActual:FindFirstChildOfClass("SpawnLocation", true)

		-- Desactivar para que Roblox no lo trate como punto de reaparición global
		if spawnLoc then
			spawnLoc.Enabled = false
		else
			warn("[LevelLoader] No hay SpawnLocation en el modelo", modelName,
				"— el personaje aparecerá en el origen del mundo")
		end

		-- Cargar personaje y teleportar (en pcall para no bloquear LevelReady si falla)
		local spawnOk, spawnErr = pcall(function()
			if not player.Character then
				player:LoadCharacter()
				local t = 0
				repeat task.wait(0.05); t = t + 0.05 until player.Character or t >= 5
			end

			local char = player.Character
			if char and spawnLoc then
				local hrp = char:WaitForChild("HumanoidRootPart", 5)
				if hrp then
					hrp.CFrame = spawnLoc.CFrame * CFrame.new(0, 5, 0)
					print("[LevelLoader] ✅ Jugador teleportado al nivel", nivelID)
				else
					warn("[LevelLoader] HumanoidRootPart no encontrado en", player.Name)
				end
			end
		end)

		if not spawnOk then
			warn("[LevelLoader] ⚠ Error al hacer spawn del personaje:", spawnErr)
			-- LevelReady se disparará de todas formas abajo para desbloquear al cliente
		end
	end

	-- Notificar BindableEvent (otros servicios del servidor escuchan esto)
	levelLoadedBE:Fire(nivelID, nivelActual)

	-- Notificar al cliente que el nivel está listo
	local payload = {
		nivelID  = nivelID,
		nombre   = config.Nombre,
		algoritmo = config.Algoritmo,
	}
	if player then
		levelReadyEv:FireClient(player, payload)
	else
		levelReadyEv:FireAllClients(payload)
	end

	return true
end

return LevelLoader
