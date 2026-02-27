-- ZoneTriggerManager.lua (CORREGIDO)
-- ModuleScript servidor: detecta ENTRADA y SALIDA de zonas de gameplay.

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")

local ZoneTriggerManager = {}

-- ── Estado ────────────────────────────────────────────────────────────────────
local _active    = false
local _player    = nil
local _conns     = {}
local _visitadas = {}
local _inZone    = {}
local _touchingPerZone = {}
local _zonasConfig = nil

-- BindableEvents
local _zoneEnteredEv = nil
local _zoneExitedEv  = nil

-- ── Helper ────────────────────────────────────────────────────────────────────
local function findTriggerInNivel(nivel, triggerName)
	-- Buscar recursivamente en todo el nivel el trigger por nombre
	if not nivel or not triggerName then return nil end

	-- Primero buscar directo
	local direct = nivel:FindFirstChild(triggerName, true)
	if direct and direct:IsA("BasePart") then
		return direct
	end

	-- Si no se encuentra, buscar en Zonas/
	local zonasFolder = nivel:FindFirstChild("Zonas")
	if zonasFolder then
		for _, zona in ipairs(zonasFolder:GetChildren()) do
			local trigger = zona:FindFirstChild(triggerName)
			if trigger and trigger:IsA("BasePart") then
				return trigger
			end
		end
	end

	return nil
end

-- ── activate ─────────────────────────────────────────────────────────────────
function ZoneTriggerManager.activate(nivel, zonas, player, zonasConfig)
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
	_zonasConfig     = zonasConfig

	-- Cachear BindableEvents
	local ev = RS:FindFirstChild("Events")
	if ev then
		local bind = ev:FindFirstChild("Bindables")
		if bind then
			_zoneEnteredEv = bind:FindFirstChild("ZoneEntered")
			_zoneExitedEv  = bind:FindFirstChild("ZoneExited")
		end
	end

	local registradas = 0
	for _, zonaDef in ipairs(zonas) do
		-- ================================================================
		-- FIX CRÍTICO: Buscar el trigger en TODO el nivel, no solo en Zonas_juego
		-- ================================================================
		local triggerPart = findTriggerInNivel(nivel, zonaDef.trigger)

		if triggerPart and triggerPart:IsA("BasePart") then
			local nombre  = zonaDef.nombre
			local trigKey = zonaDef.trigger
			_touchingPerZone[nombre] = {}

			print(string.format("[ZoneTriggerManager] Registrando zona '%s' con trigger '%s'", 
				nombre, trigKey))

			-- ── Touched: alguna Part del personaje entró al trigger ────────────
			local connEnter = triggerPart.Touched:Connect(function(touchedPart)
				if not _active then return end
				local character = _player and _player.Character
				if not character then return end

				-- Verificación más robusta de pertenencia al personaje
				local esMiPersonaje = false
				if touchedPart:IsDescendantOf(character) then
					esMiPersonaje = true
				else
					local modelo = touchedPart:FindFirstAncestorOfClass("Model")
					if modelo == character then
						esMiPersonaje = true
					end
				end

				if not esMiPersonaje then return end

				local touching = _touchingPerZone[nombre]
				local wasEmpty = next(touching) == nil
				touching[touchedPart] = true

				-- Transición: ninguna → alguna Part = el jugador acaba de entrar
				if wasEmpty and not _inZone[nombre] then
					_inZone[nombre] = true

					local primeraVez = not _visitadas[nombre]
					_visitadas[nombre] = true

					-- Setear atributo en el jugador para que el cliente sepa
					if _player then
						_player:SetAttribute("CurrentZone", nombre)
						print(string.format("[ZoneTriggerManager] >>> ENTRADA: '%s' | CurrentZone seteado", nombre))
					end

					-- Obtener descripción de la config
					local descripcion = _zonasConfig and _zonasConfig[nombre] and _zonasConfig[nombre].Descripcion

					if _zoneEnteredEv then
						_zoneEnteredEv:Fire({
							player    = _player,
							nombre    = nombre,
							trigger   = trigKey,
							primeraVez = primeraVez,
							descripcion = descripcion,
						})
					end
				end
			end)

			-- ── TouchEnded: alguna Part del personaje salió del trigger ────────
			local connExit = triggerPart.TouchEnded:Connect(function(touchedPart)
				if not _active then return end
				local character = _player and _player.Character
				if not character then return end

				-- Misma verificación robusta
				local esMiPersonaje = false
				if touchedPart:IsDescendantOf(character) then
					esMiPersonaje = true
				else
					local modelo = touchedPart:FindFirstAncestorOfClass("Model")
					if modelo == character then
						esMiPersonaje = true
					end
				end

				if not esMiPersonaje then return end

				local touching = _touchingPerZone[nombre]
				touching[touchedPart] = nil

				-- Transición: alguna → ninguna Part = el jugador ha salido completamente
				if next(touching) == nil and _inZone[nombre] then
					_inZone[nombre] = nil

					-- Limpiar atributo al salir de la zona
					if _player then
						if _player:GetAttribute("CurrentZone") == nombre then
							_player:SetAttribute("CurrentZone", nil)
							print(string.format("[ZoneTriggerManager] <<< SALIDA: '%s' | CurrentZone limpiado", nombre))
						end
					end

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
			warn(string.format("[ZoneTriggerManager] Trigger NO ENCONTRADO: '%s' para zona '%s'", 
				tostring(zonaDef.trigger), zonaDef.nombre))
		end
	end

	print(string.format("[ZoneTriggerManager] activate — registradas: %d/%d", registradas, #zonas))
end

-- ── deactivate ────────────────────────────────────────────────────────────────
function ZoneTriggerManager.deactivate()
	_active = false
	for _, conn in ipairs(_conns) do conn:Disconnect() end
	_conns           = {}
	_visitadas       = {}
	_inZone          = {}
	_touchingPerZone = {}
	_zonasConfig     = nil
	_player          = nil
	_zoneEnteredEv   = nil
	_zoneExitedEv    = nil
	print("[ZoneTriggerManager] deactivate — limpieza completa")
end

-- ── Consultas ─────────────────────────────────────────────────────────────────
function ZoneTriggerManager.isZonaVisitada(nombre)
	return _visitadas[nombre] == true
end

function ZoneTriggerManager.isEnZona(nombre)
	return _inZone[nombre] == true
end

function ZoneTriggerManager.getZonasVisitadas()
	local result = {}
	for nombre, _ in pairs(_visitadas) do
		table.insert(result, nombre)
	end
	return result
end

function ZoneTriggerManager.getZonaActual()
	for nombre, inside in pairs(_inZone) do
		if inside then return nombre end
	end
	return nil
end

function ZoneTriggerManager.marcarVisitada(nombre)
	_visitadas[nombre] = true
end

return ZoneTriggerManager