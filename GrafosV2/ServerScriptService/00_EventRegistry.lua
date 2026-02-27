-- EventRegistry.server.lua
-- TIPO: Script (servidor) — se auto-ejecuta al arrancar el servidor.
-- Debe correr ANTES que Boot.server.lua.
-- En Studio: asegúrate de que este script tenga prioridad o que Boot use
-- WaitForChild("Events") para esperarlo (ya lo hace con timeout de 15s).
--
-- Responsabilidad: garantizar que todos los RemoteEvents, RemoteFunctions
-- y BindableEvents del juego existan en ReplicatedStorage/Events.
-- Si ya están creados en Studio → los deja intactos.
-- Si falta alguno → lo crea automáticamente.
--
-- Ubicación Roblox: ServerScriptService/EventRegistry.server.lua

local RS = game:GetService("ReplicatedStorage")

-- ── Eventos esperados ────────────────────────────────────────────────────────
local EXPECTED_REMOTES = {
	{ name = "GetPlayerProgress",      class = "RemoteFunction" },
	{ name = "RequestPlayLevel",       class = "RemoteEvent" },
	{ name = "CableDragEvent",         class = "RemoteEvent" },
	{ name = "LevelReady",             class = "RemoteEvent" },
	{ name = "LevelCompleted",         class = "RemoteEvent" },
	{ name = "UpdateScore",            class = "RemoteEvent" },
	{ name = "UpdateScoreFinal",       class = "RemoteEvent" },
	{ name = "PulseEvent",             class = "RemoteEvent" },
	{ name = "NotificarSeleccionNodo", class = "RemoteEvent" },
	{ name = "PlayEffect",             class = "RemoteEvent" },
	{ name = "ApplyDifficulty",        class = "RemoteEvent" },
	{ name = "ServerReady",            class = "RemoteEvent" },
	{ name = "ReturnToMenu",           class = "RemoteEvent" },
	{ name = "LevelUnloaded",          class = "RemoteEvent" },
	{ name = "UpdateMissions",         class = "RemoteEvent" },
	-- 🔥 NUEVO: Para clicks desde modo mapa
	{ name = "MapaClickNodo",          class = "RemoteEvent" },
	-- 🔥 NUEVO: Para actualizar estado de zonas en el mapa
	{ name = "UpdateZones",            class = "RemoteEvent" },
	{ name = "RestartLevel",           class = "RemoteEvent" },
}

-- Nota: "LevelCompleted" estaba duplicado en tu lista, lo dejé una sola vez

local EXPECTED_BINDABLES = {
	{ name = "ServerReady",       class = "BindableEvent" },
	{ name = "LevelLoaded",       class = "BindableEvent" },
	{ name = "LevelUnloaded",     class = "BindableEvent" },
	{ name = "ScoreChanged",      class = "BindableEvent" },
	{ name = "ZoneEntered",       class = "BindableEvent" },
	{ name = "ZoneExited",        class = "BindableEvent" },
	{ name = "DialogueRequested", class = "BindableEvent" },
	{ name = "OpenMenu",          class = "BindableEvent" },
	{ name = "GuiaAvanzar",       class = "BindableEvent" },
	{ name = "RestaurarObjetos",  class = "BindableEvent" },
	{ name = "ForceCloseMap",     class = "BindableEvent" },
	{ name = "ShowRoof",          class = "BindableEvent" },
	{ name = "RestoreRoof",       class = "BindableEvent" },
}

-- ── Helpers ──────────────────────────────────────────────────────────────────
local function ensureFolder(parent, name)
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name   = name
		f.Parent = parent
		print("[EventRegistry] Carpeta creada:", name)
	end
	return f
end

local function ensureEvent(parent, name, class)
	local existing = parent:FindFirstChild(name)
	if existing then return end
	local ev = Instance.new(class)
	ev.Name   = name
	ev.Parent = parent
	print("[EventRegistry] Creado (faltaba):", class, "/", name)
end

-- ── Crear estructura ─────────────────────────────────────────────────────────
local eventsFolder    = ensureFolder(RS, "Events")
local remotesFolder   = ensureFolder(eventsFolder, "Remotes")
local bindablesFolder = ensureFolder(eventsFolder, "Bindables")

for _, ev in ipairs(EXPECTED_REMOTES) do
	ensureEvent(remotesFolder, ev.name, ev.class)
end

for _, ev in ipairs(EXPECTED_BINDABLES) do
	ensureEvent(bindablesFolder, ev.name, ev.class)
end

print("[EventRegistry] ✅ Todos los eventos verificados/creados")