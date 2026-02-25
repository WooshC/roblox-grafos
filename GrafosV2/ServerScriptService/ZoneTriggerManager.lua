-- ZoneTriggerManager.lua
-- ModuleScript servidor: detecta ENTRADA y SALIDA de zonas de gameplay.
--
-- Estructura esperada en el nivel:
--   NivelActual/
--   └── Zonas/
--       └── Zonas_juego/
--           ├── ZonaTrigger_1  (BasePart, CanCollide=false, Transparency=1)
--           └── ...
--
-- Configuración en LevelsConfig[nivelID].Zonas:
--   { { nombre = "Zona1", trigger = "ZonaTrigger_1" }, ... }
--
-- Detección de entrada/salida (Touched + TouchEnded):
--   El personaje tiene muchas BaseParts (torso, piernas, brazos...).
--   Touched/TouchEnded se disparan por cada Part del personaje que entre/salga.
--   _touchingPerZone rastrea cuáles Parts están actualmente dentro de cada zona,
--   y solo dispara los eventos en las TRANSICIONES:
--     ninguna → alguna  → ZoneEntered  (con { primeraVez = bool })
--     alguna  → ninguna → ZoneExited
--
-- Eventos disparados (BindableEvents):
--   ZoneEntered: { player, nombre, trigger, primeraVez }
--   ZoneExited:  { player, nombre, trigger }
--
-- Quién escucha: DialogueOrchestrator, MissionService, GuiaService
--
-- Ubicación Roblox: ServerScriptService/ZoneTriggerManager  (ModuleScript)

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")

local ZoneTriggerManager = {}

-- ── Estado ────────────────────────────────────────────────────────────────────
local _active    = false
local _player    = nil
local _conns     = {}    -- RBXScriptConnections a limpiar en deactivate

-- _visitadas[nombre]     = true → zona visitada al menos una vez en este nivel
--                          (nunca se resetea durante el nivel, útil para efectos de primer encuentro)
local _visitadas = {}

-- _inZone[nombre]        = true → jugador está ACTUALMENTE dentro de la zona
--                          (se resetea al salir, permite re-entrada)
local _inZone    = {}

-- _touchingPerZone[nombre] = { [touchedPart] = true }
--                          Cuántas Parts del personaje están actualmente tocando la zona.
--                          Usamos tabla (no contador) para sobrevivir a partes destruidas.
local _touchingPerZone = {}

-- BindableEvents
local _zoneEnteredEv = nil
local _zoneExitedEv  = nil

-- ── Helper ────────────────────────────────────────────────────────────────────
local function getZonasFolder(nivel)
	local zonas = nivel:FindFirstChild("Zonas")
	if not zonas then return nil end
	return zonas:FindFirstChild("Zonas_juego")
end

-- ── activate ─────────────────────────────────────────────────────────────────
function ZoneTriggerManager.activate(nivel, zonas, player)
	if _active then ZoneTriggerManager.deactivate() end

	if not nivel or not zonas or #zonas == 0 then
		print("[ZoneTriggerManager] Sin zonas configuradas — inactivo")
		return
	end

	_player          = player
	_visitadas       = {}
	_inZone          = {}
	_touchingPerZone = {}
	_conns           = {}
	_active          = true

	-- Cachear BindableEvents
	local ev = RS:FindFirstChild("Events")
	if ev then
		local bind = ev:FindFirstChild("Bindables")
		if bind then
			_zoneEnteredEv = bind:FindFirstChild("ZoneEntered")
			_zoneExitedEv  = bind:FindFirstChild("ZoneExited")
		end
	end

	local zonasFolder = getZonasFolder(nivel)
	if not zonasFolder then
		warn("[ZoneTriggerManager] No se encontró NivelActual/Zonas/Zonas_juego/")
		return
	end

	local registradas = 0
	for _, zonaDef in ipairs(zonas) do
		local triggerPart = zonasFolder:FindFirstChild(zonaDef.trigger)
		if triggerPart and triggerPart:IsA("BasePart") then
			local nombre  = zonaDef.nombre
			local trigKey = zonaDef.trigger
			_touchingPerZone[nombre] = {}

			-- ── Touched: alguna Part del personaje entró al trigger ────────────
			local connEnter = triggerPart.Touched:Connect(function(touchedPart)
				if not _active then return end
				local character = _player and _player.Character
				if not character or not touchedPart:IsDescendantOf(character) then return end

				local touching = _touchingPerZone[nombre]
				local wasEmpty = next(touching) == nil
				touching[touchedPart] = true

				-- Transición: ninguna → alguna Part = el jugador acaba de entrar
				if wasEmpty and not _inZone[nombre] then
					_inZone[nombre] = true

					local primeraVez = not _visitadas[nombre]
					_visitadas[nombre] = true

					print("[ZoneTriggerManager] ▶ Zona ENTRADA:", nombre,
						"/ primeraVez:", primeraVez, "/ Jugador:", _player.Name)

					if _zoneEnteredEv then
						_zoneEnteredEv:Fire({
							player    = _player,
							nombre    = nombre,
							trigger   = trigKey,
							primeraVez = primeraVez,
						})
					end
				end
			end)

			-- ── TouchEnded: alguna Part del personaje salió del trigger ────────
			local connExit = triggerPart.TouchEnded:Connect(function(touchedPart)
				if not _active then return end
				local character = _player and _player.Character
				if not character or not touchedPart:IsDescendantOf(character) then return end

				local touching = _touchingPerZone[nombre]
				touching[touchedPart] = nil

				-- Transición: alguna → ninguna Part = el jugador ha salido completamente
				if next(touching) == nil and _inZone[nombre] then
					_inZone[nombre] = nil

					print("[ZoneTriggerManager] ◀ Zona SALIDA:", nombre,
						"/ Jugador:", _player.Name)

					if _zoneExitedEv then
						_zoneExitedEv:Fire({
							player  = _player,
							nombre  = nombre,
							trigger = trigKey,
						})
					end
				end
			end)

			table.insert(_conns, connEnter)
			table.insert(_conns, connExit)
			registradas = registradas + 1
		else
			warn("[ZoneTriggerManager] Trigger no encontrado o no es BasePart:",
				zonaDef.trigger or "?",
				"— Asegúrate de que la Part exista en NivelActual/Zonas/Zonas_juego/")
		end
	end

	print("[ZoneTriggerManager] activate — triggers registrados:", registradas,
		"/ total en config:", #zonas)
end

-- ── deactivate ────────────────────────────────────────────────────────────────
function ZoneTriggerManager.deactivate()
	_active = false
	for _, conn in ipairs(_conns) do conn:Disconnect() end
	_conns           = {}
	_visitadas       = {}
	_inZone          = {}
	_touchingPerZone = {}
	_player          = nil
	_zoneEnteredEv   = nil
	_zoneExitedEv    = nil
	print("[ZoneTriggerManager] deactivate — limpieza completa")
end

-- ── Consultas ─────────────────────────────────────────────────────────────────

-- ¿El jugador visitó esta zona al menos una vez en este nivel?
function ZoneTriggerManager.isZonaVisitada(nombre)
	return _visitadas[nombre] == true
end

-- ¿El jugador está AHORA MISMO dentro de esta zona?
function ZoneTriggerManager.isEnZona(nombre)
	return _inZone[nombre] == true
end

-- Lista de nombres de zonas visitadas al menos una vez
function ZoneTriggerManager.getZonasVisitadas()
	local result = {}
	for nombre, _ in pairs(_visitadas) do
		table.insert(result, nombre)
	end
	return result
end

-- Zona actual del jugador (nil si no está en ninguna zona reconocida)
function ZoneTriggerManager.getZonaActual()
	for nombre, inside in pairs(_inZone) do
		if inside then return nombre end
	end
	return nil
end

-- Marcar manualmente como visitada (testing / tutoriales)
function ZoneTriggerManager.marcarVisitada(nombre)
	_visitadas[nombre] = true
end

return ZoneTriggerManager
