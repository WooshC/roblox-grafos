-- ReplicatedStorage/Compartido/EventosClientes.lua
-- Centraliza la obtención de RemoteEvents del cliente, con caché local.
-- Elimina las 25+ repeticiones de FindFirstChild("EventosGrafosV3") en toda la codebase.

local EventosClientes = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Caché local: nombre → RemoteEvent
local _cache = {}

-- Referencia perezosa a la carpeta Remotos
local _remotos = nil

local function _obtenerRemotos()
	if _remotos then return _remotos end
	local eventos = ReplicatedStorage:FindFirstChild("EventosGrafosV3")
	if not eventos then
		eventos = ReplicatedStorage:WaitForChild("EventosGrafosV3", 5)
	end
	if not eventos then
		warn("[EventosClientes] ❌ EventosGrafosV3 no encontrado en ReplicatedStorage")
		return nil
	end
	_remotos = eventos:FindFirstChild("Remotos")
	if not _remotos then
		_remotos = eventos:WaitForChild("Remotos", 5)
	end
	if not _remotos then
		warn("[EventosClientes] ❌ Remotos no encontrado en EventosGrafosV3")
	end
	return _remotos
end

---Obtiene un RemoteEvent por nombre, usando caché.
-- @param nombre string — Nombre del evento (ej. "DialogoCorrecto")
-- @param timeout number — Segundos de espera si no está en caché (default 2)
-- @return RemoteEvent|nil
function EventosClientes.obtener(nombre, timeout)
	timeout = timeout or 2
	if _cache[nombre] then
		return _cache[nombre]
	end
	local remotos = _obtenerRemotos()
	if not remotos then return nil end

	local ev = remotos:FindFirstChild(nombre)
	if not ev then
		ev = remotos:WaitForChild(nombre, timeout)
	end
	if ev then
		_cache[nombre] = ev
	else
		warn(string.format("[EventosClientes] ❌ '%s' no encontrado en Remotos (timeout=%ds)", nombre, timeout))
	end
	return ev
end

---Invalida la caché de un evento específico (útil si se recrea dinámicamente).
function EventosClientes.limpiarCache(nombre)
	if nombre then
		_cache[nombre] = nil
	else
		_cache = {}
	end
end

---Obtiene la carpeta Remotos cruda (para casos especiales).
function EventosClientes.obtenerCarpetaRemotos()
	return _obtenerRemotos()
end

return EventosClientes
