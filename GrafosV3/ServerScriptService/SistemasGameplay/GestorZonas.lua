-- ServerScriptService/SistemasGameplay/GestorZonas.lua
-- Sistema de deteccion de zonas para GrafosV3
-- Adaptado de GrafosV2/ZoneTriggerManager

local GestorZonas = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- Estado
local _activo = false
local _jugador = nil
local _conexiones = {}
local _visitadas = {}
local _enZona = {}
local _tocandoPorZona = {}
local _configZonas = nil
local _servicioMisiones = nil

-- Callbacks
local _callbackEntrada = nil
local _callbackSalida = nil

-- Helper: buscar trigger en el nivel
local function buscarTriggerEnNivel(nivel, nombreTrigger)
	if not nivel or not nombreTrigger then return nil end

	-- Buscar directo
	local directo = nivel:FindFirstChild(nombreTrigger, true)
	if directo and directo:IsA("BasePart") then
		return directo
	end

	-- Buscar en Zonas/
	local zonasFolder = nivel:FindFirstChild("Zonas")
	if zonasFolder then
		for _, zona in ipairs(zonasFolder:GetChildren()) do
			local trigger = zona:FindFirstChild(nombreTrigger)
			if trigger and trigger:IsA("BasePart") then
				return trigger
			end
		end
	end

	return nil
end

function GestorZonas.activar(nivel, zonasConfig, jugador, servicioMisiones)
	if _activo then GestorZonas.desactivar() end

	if not nivel or not zonasConfig then
		print("[GestorZonas] Sin zonas configuradas — inactivo")
		return
	end

	_jugador = jugador
	_servicioMisiones = servicioMisiones
	_visitadas = {}
	_enZona = {}
	_tocandoPorZona = {}
	_conexiones = {}
	_activo = true
	_configZonas = zonasConfig

	-- Preparar lista de zonas desde la config
	local zonas = {}
	for nombreZona, datos in pairs(zonasConfig) do
		if datos and datos.Trigger then
			table.insert(zonas, {
				nombre = nombreZona,
				trigger = datos.Trigger
			})
		end
	end

	local registradas = 0
	for _, zonaDef in ipairs(zonas) do
		local triggerPart = buscarTriggerEnNivel(nivel, zonaDef.trigger)

		if triggerPart and triggerPart:IsA("BasePart") then
			local nombre = zonaDef.nombre
			_tocandoPorZona[nombre] = {}

			print(string.format("[GestorZonas] Registrando zona '%s' con trigger '%s'", 
				nombre, zonaDef.trigger))

			-- Touched: entrada a la zona
			-- IMPORTANTE: Touched/TouchEnded se disparan por CADA parte del cuerpo
			-- (piernas, torso, HRP...) y las partes "parpadean" al caminar.
			-- Solucion: solo reaccionar a la HumanoidRootPart para un unico disparo.
			local connEntrada = triggerPart.Touched:Connect(function(parteTocada)
				if not _activo then return end
				local personaje = _jugador and _jugador.Character
				if not personaje then return end

				-- Solo la HRP garantiza un unico disparo por zona
				if parteTocada.Name ~= "HumanoidRootPart" then return end
				if not parteTocada:IsDescendantOf(personaje) then return end

				-- Ignorar si ya estamos dentro
				if _enZona[nombre] then return end

				_enZona[nombre] = true
				_visitadas[nombre] = true

				if _jugador then
					_jugador:SetAttribute("ZonaActual", nombre)
					print(string.format("[GestorZonas] >>> ENTRADA: '%s'", nombre))
				end

				if _servicioMisiones and _servicioMisiones.estaActivo() then
					_servicioMisiones.alEntrarZona(nombre)
				end

				if _callbackEntrada then
					_callbackEntrada(nombre)
				end
			end)

			-- TouchEnded: salida de la zona
			-- Solo reaccionamos a la HumanoidRootPart (mismo filtro que Touched)
			local connSalida = triggerPart.TouchEnded:Connect(function(parteTocada)
				if not _activo then return end
				local personaje = _jugador and _jugador.Character
				if not personaje then return end

				if parteTocada.Name ~= "HumanoidRootPart" then return end
				if not parteTocada:IsDescendantOf(personaje) then return end

				-- Ignorar si ya no estabamos en la zona
				if not _enZona[nombre] then return end

				_enZona[nombre] = nil

				if _jugador then
					if _jugador:GetAttribute("ZonaActual") == nombre then
						_jugador:SetAttribute("ZonaActual", nil)
						print(string.format("[GestorZonas] <<< SALIDA: '%s'", nombre))
					end
				end

				if _servicioMisiones and _servicioMisiones.estaActivo() then
					_servicioMisiones.alSalirZona(nombre)
				end

				if _callbackSalida then
					_callbackSalida(nombre)
				end
			end)

			table.insert(_conexiones, connEntrada)
			table.insert(_conexiones, connSalida)
			registradas = registradas + 1
		else
			warn(string.format("[GestorZonas] Trigger NO ENCONTRADO: '%s' para zona '%s'", 
				tostring(zonaDef.trigger), zonaDef.nombre))
		end
	end

	print(string.format("[GestorZonas] activar — registradas: %d/%d", registradas, #zonas))
end

function GestorZonas.desactivar()
	_activo = false
	for _, conn in ipairs(_conexiones) do conn:Disconnect() end
	_conexiones = {}
	_visitadas = {}
	_enZona = {}
	_tocandoPorZona = {}
	_configZonas = nil
	_jugador = nil
	_servicioMisiones = nil
	print("[GestorZonas] desactivar")
end

function GestorZonas.estaActivo()
	return _activo
end

function GestorZonas.getZonaActual()
	for nombre, dentro in pairs(_enZona) do
		if dentro then return nombre end
	end
	return nil
end

function GestorZonas.setCallbacks(entrada, salida)
	_callbackEntrada = entrada
	_callbackSalida = salida
end

return GestorZonas
