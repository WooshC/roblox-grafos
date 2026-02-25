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

-- Esperar eventos (EventRegistry debe haber corrido antes que Boot)
local eventsFolder  = RS:WaitForChild("EDAEvents", 15)
local remotesFolder = eventsFolder:WaitForChild("Remotes", 5)
local levelReadyEv  = remotesFolder:WaitForChild("LevelReady", 5)
local levelUnloadEv = remotesFolder:WaitForChild("LevelUnloaded", 5)

local bindablesFolder = eventsFolder:WaitForChild("Bindables", 5)
local levelLoadedBE   = bindablesFolder:WaitForChild("LevelLoaded", 5)
local levelUnloadedBE = bindablesFolder:WaitForChild("LevelUnloaded", 5)

-- Config mínima de niveles (se expandirá cuando exista Config/LevelsConfig.lua)
local LEVELS_CONFIG = {
	[0] = { Nombre = "Laboratorio de Grafos", Modelo = "Nivel0",   Algoritmo = nil },
	[1] = { Nombre = "La Red Desconectada",   Modelo = "Nivel1",   Algoritmo = "Conectividad" },
	[2] = { Nombre = "La Fábrica de Señales", Modelo = "Nivel2",   Algoritmo = "BFS/DFS" },
	[3] = { Nombre = "El Puente Roto",        Modelo = "Nivel3",   Algoritmo = "Grafos Dirigidos" },
	[4] = { Nombre = "Ruta Mínima",           Modelo = "Nivel4",   Algoritmo = "Dijkstra" },
}

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

	-- ── Teleportar jugador al SpawnLocation del nivel ──────────────────────
	if player then
		local spawnLoc = nivelActual:FindFirstChildOfClass("SpawnLocation", true)
		local char     = player.Character

		if spawnLoc and char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				-- Desactivar SpawnLocation global para que no interfiera
				spawnLoc.Enabled = false
				-- Teleportar encima del SpawnLocation
				hrp.CFrame = spawnLoc.CFrame * CFrame.new(0, 5, 0)
				print("[LevelLoader] Jugador teleportado al SpawnLocation del nivel", nivelID)
			else
				warn("[LevelLoader] HumanoidRootPart no encontrado en", player.Name)
			end
		elseif not spawnLoc then
			warn("[LevelLoader] No hay SpawnLocation en el modelo", modelName,
				"— el personaje no será teleportado")
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
