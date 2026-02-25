-- EventRegistry.server.lua
-- Crea TODOS los RemoteEvents, RemoteFunctions y BindableEvents del juego.
-- Debe ejecutarse PRIMERO. En Roblox Studio colócalo en ServerScriptService/
-- con RunContext = Server y asegúrate de que tenga ejecución prioritaria
-- (o simplemente nómbralo con "00_" para que cargue antes que Boot).
--
-- Ubicación Roblox: ServerScriptService/EventRegistry.server.lua

local RS = game:GetService("ReplicatedStorage")

-- Limpiar instancia anterior (útil al re-ejecutar en Studio)
local existing = RS:FindFirstChild("EDAEvents")
if existing then existing:Destroy() end

-- Carpeta raíz
local eventsFolder = Instance.new("Folder")
eventsFolder.Name = "EDAEvents"
eventsFolder.Parent = RS

local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "Remotes"
remotesFolder.Parent = eventsFolder

local bindablesFolder = Instance.new("Folder")
bindablesFolder.Name = "Bindables"
bindablesFolder.Parent = eventsFolder

-- ── RemoteEvents (cliente ↔ servidor) ──────────────────────────────────────
local REMOTE_EVENTS = {
	"ServerReady",        -- Servidor → cliente: servidor inicializado
	"RequestPlayLevel",   -- Cliente → servidor: quiero jugar nivelID
	"LevelReady",         -- Servidor → cliente: nivel cargado, puedes entrar
	"LevelUnloaded",      -- Servidor → cliente: nivel fue descargado
	"UpdateVolume",       -- Cliente → servidor: cambio de volumen (ambiente / sfx)
	"ReturnToMenu",       -- Cliente → servidor: volver al menú desde gameplay
}

-- ── RemoteFunctions (cliente solicita dato al servidor) ────────────────────
local REMOTE_FUNCTIONS = {
	-- "GetPlayerProgress",  -- Fase 2: cuando integremos DataStore
}

-- ── BindableEvents (comunicación interna servidor) ─────────────────────────
local BINDABLE_EVENTS = {
	"LevelLoaded",        -- Disparado cuando el nivel terminó de cargar
	"LevelUnloaded",      -- Disparado cuando el nivel fue descargado
}

for _, name in ipairs(REMOTE_EVENTS) do
	local e = Instance.new("RemoteEvent")
	e.Name = name
	e.Parent = remotesFolder
end

for _, name in ipairs(REMOTE_FUNCTIONS) do
	local e = Instance.new("RemoteFunction")
	e.Name = name
	e.Parent = remotesFolder
end

for _, name in ipairs(BINDABLE_EVENTS) do
	local e = Instance.new("BindableEvent")
	e.Name = name
	e.Parent = bindablesFolder
end

print("[EDA v2] ✅ EventRegistry — Eventos creados en ReplicatedStorage/EDAEvents")
