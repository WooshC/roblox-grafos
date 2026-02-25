-- Boot.server.lua
-- Punto de entrada único del servidor para EDA Quest v2.
--
-- FIX CRÍTICO: Con CharacterAutoLoads = false, Roblox NO copia StarterGui a
-- PlayerGui automáticamente hasta que el personaje spawne. Como el menú no
-- tiene personaje, hay que copiar la GUI manualmente al conectarse.
--
-- Ubicación Roblox: ServerScriptService/Boot.server.lua

local RS         = game:GetService("ReplicatedStorage")
local Players    = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

-- ── 1. Sin spawn automático ────────────────────────────────────────────────
Players.CharacterAutoLoads = false

-- ── 2. Esperar EventRegistry ───────────────────────────────────────────────
local eventsFolder = RS:WaitForChild("Events", 15)
if not eventsFolder then
	error("[EDA v2] Boot: Events no apareció en 15s.")
end

local remotesFolder  = eventsFolder:WaitForChild("Remotes", 5)
local serverReadyEv  = remotesFolder:WaitForChild("ServerReady",       5)
local requestPlayLEv = remotesFolder:WaitForChild("RequestPlayLevel",  5)
local levelReadyEv   = remotesFolder:WaitForChild("LevelReady",        5)
local returnToMenuEv = remotesFolder:WaitForChild("ReturnToMenu",      5)
local getProgressFn  = remotesFolder:WaitForChild("GetPlayerProgress", 5)

-- ── 3. Cargar servicios ────────────────────────────────────────────────────
local LevelLoader = require(script.Parent:WaitForChild("LevelLoader", 10))
local DataService = require(script.Parent:WaitForChild("DataService", 10))
print("[EDA v2] ✅ LevelLoader + DataService cargados")

-- ── 4. Copiar StarterGui → PlayerGui manualmente ──────────────────────────
-- Roblox solo hace esto automáticamente al spawnear el personaje.
-- Con CharacterAutoLoads = false nunca ocurre solo, así que lo hacemos aquí.
local function copyGuiToPlayer(player)
	local playerGui = player:WaitForChild("PlayerGui", 10)
	if not playerGui then
		warn("[EDA v2] PlayerGui no encontrado para", player.Name)
		return
	end

	for _, gui in ipairs(StarterGui:GetChildren()) do
		if not playerGui:FindFirstChild(gui.Name) then
			local clone = gui:Clone()
			clone.Parent = playerGui
			print("[EDA v2] ✅ GUI →", gui.Name, "copiada a", player.Name)
		end
	end
end

-- ── 5. Jugador conectado ───────────────────────────────────────────────────
local function onPlayerAdded(player)
	-- Copiar GUI primero (sin esperar DataService)
	task.spawn(function()
		copyGuiToPlayer(player)
	end)

	-- Pre-cargar datos del DataStore en paralelo
	task.spawn(function()
		DataService:load(player)
	end)

	-- Delay para dar tiempo a que la GUI arranque sus LocalScripts en el cliente
	task.delay(2, function()
		if player and player.Parent then
			serverReadyEv:FireClient(player)
			print("[EDA v2] ServerReady →", player.Name)
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)

-- Para jugadores ya conectados (pruebas en Studio con Play Solo)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- ── 6. GetPlayerProgress ───────────────────────────────────────────────────
getProgressFn.OnServerInvoke = function(player)
	return DataService:getProgressForClient(player)
end

-- ── 7. RequestPlayLevel ────────────────────────────────────────────────────
requestPlayLEv.OnServerEvent:Connect(function(player, nivelID)
	print("[EDA v2] RequestPlayLevel — Jugador:", player.Name, "/ Nivel:", nivelID)

	if type(nivelID) ~= "number" then
		warn("[EDA v2] nivelID inválido:", tostring(nivelID))
		return
	end

	local ok, err = pcall(function()
		LevelLoader:load(nivelID, player)
	end)

	if not ok then
		warn("[EDA v2] Error al cargar nivel:", err)
		if player and player.Parent then
			levelReadyEv:FireClient(player, {
				nivelID = nivelID,
				error   = "Error interno al cargar el nivel.",
			})
		end
	end
end)

-- ── 8. ReturnToMenu ────────────────────────────────────────────────────────
returnToMenuEv.OnServerEvent:Connect(function(player)
	print("[EDA v2] ReturnToMenu — Jugador:", player.Name)

	local ok, err = pcall(function()
		LevelLoader:unload()
		if player.Character then
			player.Character:Destroy()
			player.Character = nil
		end
	end)

	if not ok then
		warn("[EDA v2] Error al volver al menú:", err)
	end
end)

-- ── 9. Guardar al desconectarse ────────────────────────────────────────────
Players.PlayerRemoving:Connect(function(player)
	DataService:onPlayerLeaving(player)
end)

print("[EDA v2] ✅ Boot completo — CharacterAutoLoads=false — Servidor listo")