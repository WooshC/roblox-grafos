-- ReplicatedStorage/Shared/VisualEffectsConfig.lua
-- Constantes compartidas de efectos visuales.
-- Sin instancias de Roblox → seguro de requerir desde servidor Y cliente.
--
-- Uso:
--   local VEC = require(ReplicatedStorage.Shared.VisualEffectsConfig)
--   VEM.fire(player, VEC.Effects.NODE_ERROR, nodoModel)
--
-- Ubicación Roblox: ReplicatedStorage/Shared/VisualEffectsConfig  (ModuleScript)

return {

	-- ── Colores ──────────────────────────────────────────────────────────────────
	Colors = {
		Selected  = Color3.fromRGB(0,   212, 255),  -- cyan   (nodo seleccionado)
		Adjacent  = Color3.fromRGB(255, 200,  50),  -- dorado (adyacentes válidos)
		Invalid   = Color3.fromRGB(239,  68,  68),  -- rojo   (conexión inválida)
		Connected = Color3.fromRGB(80,  255, 120),  -- verde  (cable conectado)
		Energized = Color3.fromRGB(0,   200, 255),  -- cian   (nodo energizado)
	},

	-- ── Duraciones ───────────────────────────────────────────────────────────────
	Durations = {
		Flash  = 0.35,   -- duración del flash de error o conexión
		Pulse  = 1.2,    -- período del glow pulsante (energized)
		FadeIn = 0.2,    -- fade in suave de efectos
	},

	-- ── Tipos de efecto (PlayEffect RemoteEvent) ──────────────────────────────────
	-- Primer argumento de PlayEffect:FireClient(player, Effects.X, ...)
	Effects = {

		-- Nodos
		-- arg1 = nodoModel (Model), arg2 = adjModels[] (array de Models)
		NODE_SELECTED   = "NodeSelected",

		-- arg1 = nodoModel (Model) → flash rojo breve
		NODE_ERROR      = "NodeError",

		-- arg1 = nodoModel (Model) → glow cian pulsante permanente hasta ClearAll
		NODE_ENERGIZED  = "NodeEnergized",

		-- Cables
		-- arg1 = nomA (string), arg2 = nomB (string)
		CABLE_CONNECTED = "CableConnected",
		CABLE_REMOVED   = "CableRemoved",

		-- Zonas
		-- arg1 = zonaID (string) → celebración de zona completada
		ZONE_COMPLETE   = "ZoneComplete",

		-- Limpia todos los efectos activos (sin args)
		CLEAR_ALL       = "ClearAll",
	},

}
