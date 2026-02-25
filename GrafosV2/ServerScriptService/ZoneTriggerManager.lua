-- ZoneTriggerManager.lua
-- ModuleScript servidor: detecta cuando el jugador entra a zonas de gameplay.
--
-- Estructura esperada en el nivel:
--   NivelActual/
--   └── Zonas/
--       └── Zonas_juego/
--           ├── ZonaTrigger_1  (BasePart, CanCollide=false, Transparency=1)
--           ├── ZonaTrigger_2
--           └── ...
--
-- Configuración en LevelsConfig[nivelID].Zonas:
--   { { nombre = "Zona1", trigger = "ZonaTrigger_1" }, ... }
--   Para agregar zonas nuevas: añadir la Part en Studio y la entrada aquí.
--
-- Cuando el personaje del jugador toca un trigger:
--   1. Se registra como zona visitada (debounce — no se repite por nivel)
--   2. Se dispara BindableEvent "ZoneEntered" con datos de la zona
--      { player, nombre, trigger }
--   Quién puede escuchar: DialogueOrchestrator, MissionService, GuiaService
--
-- Ubicación Roblox: ServerScriptService/ZoneTriggerManager  (ModuleScript)

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")

local ZoneTriggerManager = {}

-- ── Estado ────────────────────────────────────────────────────────────────────
local _active        = false
local _player        = nil
local _conns         = {}        -- RBXScriptConnections a limpiar en deactivate
local _visitadas     = {}        -- { [nombreZona] = true } — evita re-disparo
local _zoneEnteredEv = nil       -- BindableEvent "ZoneEntered"

-- ── Helper: obtener la carpeta de triggers del nivel ─────────────────────────
local function getZonasFolder(nivel)
	local zonas = nivel:FindFirstChild("Zonas")
	if not zonas then return nil end
	return zonas:FindFirstChild("Zonas_juego")
end

-- ── activate ─────────────────────────────────────────────────────────────────
-- nivel   : Model "NivelActual" en Workspace
-- zonas   : tabla de LevelsConfig[id].Zonas = { { nombre, trigger }, ... }
-- player  : Player activo en el nivel
function ZoneTriggerManager.activate(nivel, zonas, player)
	if _active then ZoneTriggerManager.deactivate() end

	if not nivel or not zonas or #zonas == 0 then
		print("[ZoneTriggerManager] Sin zonas configuradas — inactivo")
		return
	end

	_player    = player
	_visitadas = {}
	_conns     = {}
	_active    = true

	-- Cachear BindableEvent
	local ev = RS:FindFirstChild("Events")
	if ev then
		local bind = ev:FindFirstChild("Bindables")
		if bind then
			_zoneEnteredEv = bind:FindFirstChild("ZoneEntered")
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

			local conn = triggerPart.Touched:Connect(function(touchedPart)
				-- Solo reaccionar al personaje del jugador configurado
				if not _active then return end
				local character = _player and _player.Character
				if not character then return end
				if not touchedPart:IsDescendantOf(character) then return end

				-- Debounce por zona: solo se dispara una vez por nivel
				if _visitadas[nombre] then return end
				_visitadas[nombre] = true

				print("[ZoneTriggerManager] ✅ Zona entrada:", nombre,
					"/ Trigger:", trigKey, "/ Jugador:", _player.Name)

				if _zoneEnteredEv then
					_zoneEnteredEv:Fire({
						player  = _player,
						nombre  = nombre,
						trigger = trigKey,
					})
				end
			end)

			table.insert(_conns, conn)
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
	_conns         = {}
	_visitadas     = {}
	_player        = nil
	_zoneEnteredEv = nil
	print("[ZoneTriggerManager] deactivate — limpieza completa")
end

-- ── Consultas ─────────────────────────────────────────────────────────────────
-- Verifica si el jugador ya visitó una zona en este nivel
function ZoneTriggerManager.isZonaVisitada(nombre)
	return _visitadas[nombre] == true
end

-- Devuelve lista de nombres de zonas visitadas hasta ahora
function ZoneTriggerManager.getZonasVisitadas()
	local result = {}
	for nombre, _ in pairs(_visitadas) do
		table.insert(result, nombre)
	end
	return result
end

-- Permite marcar una zona como visitada manualmente (útil para testing o tutoriales)
function ZoneTriggerManager.marcarVisitada(nombre)
	_visitadas[nombre] = true
end

return ZoneTriggerManager
