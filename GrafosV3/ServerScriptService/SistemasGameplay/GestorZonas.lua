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
			local connEntrada = triggerPart.Touched:Connect(function(parteTocada)
				if not _activo then return end
				local personaje = _jugador and _jugador.Character
				if not personaje then return end

				-- Verificar que es parte del personaje
				local esMiPersonaje = false
				if parteTocada:IsDescendantOf(personaje) then
					esMiPersonaje = true
				else
					local modelo = parteTocada:FindFirstAncestorOfClass("Model")
					if modelo == personaje then
						esMiPersonaje = true
					end
				end

				if not esMiPersonaje then return end

				local tocando = _tocandoPorZona[nombre]
				local estabaVacio = next(tocando) == nil
				tocando[parteTocada] = true

				-- Transicion: vacio → con partes = entrada
				if estabaVacio and not _enZona[nombre] then
					_enZona[nombre] = true
					_visitadas[nombre] = true

					-- Setear atributo en jugador
					if _jugador then
						_jugador:SetAttribute("ZonaActual", nombre)
						print(string.format("[GestorZonas] >>> ENTRADA: '%s'", nombre))
					end

					-- Notificar a ServicioMisiones
					if _servicioMisiones and _servicioMisiones.estaActivo() then
						_servicioMisiones.alEntrarZona(nombre)
					end

					-- Callback
					if _callbackEntrada then
						_callbackEntrada(nombre)
					end
				end
			end)

			-- TouchEnded: salida de la zona
			local connSalida = triggerPart.TouchEnded:Connect(function(parteTocada)
				if not _activo then return end
				local personaje = _jugador and _jugador.Character
				if not personaje then return end

				local esMiPersonaje = false
				if parteTocada:IsDescendantOf(personaje) then
					esMiPersonaje = true
				else
					local modelo = parteTocada:FindFirstAncestorOfClass("Model")
					if modelo == personaje then
						esMiPersonaje = true
					end
				end

				if not esMiPersonaje then return end

				local tocando = _tocandoPorZona[nombre]
				tocando[parteTocada] = nil

				-- Transicion: con partes → vacio = salida
				if next(tocando) == nil and _enZona[nombre] then
					_enZona[nombre] = nil

					if _jugador then
						if _jugador:GetAttribute("ZonaActual") == nombre then
							_jugador:SetAttribute("ZonaActual", nil)
							print(string.format("[GestorZonas] <<< SALIDA: '%s'", nombre))
						end
					end

					-- Notificar a ServicioMisiones
					if _servicioMisiones and _servicioMisiones.estaActivo() then
						_servicioMisiones.alSalirZona(nombre)
					end

					-- Callback
					if _callbackSalida then
						_callbackSalida(nombre)
					end
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
