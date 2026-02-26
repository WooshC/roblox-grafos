-- VisualEffectsManager.lua
-- ModuleScript servidor: API para disparar efectos visuales al cliente.
-- El servidor NUNCA aplica efectos visuales directamente (son local-only en el cliente).
-- Solo dispara PlayEffect (RemoteEvent) al jugador correspondiente.
--
-- INICIALIZAR una vez desde GameplayManager:
--   VEM.init(remotesFolder)   -- remotesFolder = RS.Events.Remotes
--
-- Uso desde cualquier ModuleScript / Script servidor:
--   local VEM = require(SSS.VisualEffectsManager)
--   local VEC = require(RS.Shared.VisualEffectsConfig)
--
--   VEM.fire(player,  VEC.Effects.NODE_ERROR,      nodoModel)
--   VEM.fireAll(      VEC.Effects.ZONE_COMPLETE,    "Zona_Estacion_1")
--   VEM.fireAll(      VEC.Effects.CLEAR_ALL)
--
-- Ubicación Roblox: ServerScriptService/VisualEffectsManager  (ModuleScript)

local VEM = {}

local _playEffectEv = nil   -- RemoteEvent "PlayEffect" (cacheado en init)

-- ── init ─────────────────────────────────────────────────────────────────────
-- Llamar una sola vez, pasando la carpeta Remotes de ReplicatedStorage/Events.
function VEM.init(remotes)
	_playEffectEv = remotes and remotes:FindFirstChild("PlayEffect")
	if _playEffectEv then
		print("[VisualEffectsManager] init ✅ — PlayEffect cacheado")
	else
		warn("[VisualEffectsManager] ⚠ PlayEffect RemoteEvent no encontrado en:",
			remotes and remotes:GetFullName() or "nil")
	end
end

-- ── fire ─────────────────────────────────────────────────────────────────────
-- Dispara un efecto visual a UN jugador específico.
-- effectType : string de VEC.Effects  (ej. VEC.Effects.NODE_ERROR)
-- ...        : argumentos según el tipo de efecto (nodoModel, nomA, nomB, zonaID…)
function VEM.fire(player, effectType, ...)
	if not _playEffectEv then return end
	if not player or not player.Parent then return end
	_playEffectEv:FireClient(player, effectType, ...)
end

-- ── fireAll ──────────────────────────────────────────────────────────────────
-- Dispara un efecto visual a TODOS los jugadores conectados.
function VEM.fireAll(effectType, ...)
	if not _playEffectEv then return end
	_playEffectEv:FireAllClients(effectType, ...)
end

-- ── isReady ──────────────────────────────────────────────────────────────────
-- True si PlayEffect fue cacheado correctamente.
function VEM.isReady()
	return _playEffectEv ~= nil
end

return VEM
