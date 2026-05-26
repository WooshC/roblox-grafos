-- ReplicatedStorage/Compartido/Utilidades.lua
-- Utilidades centralizadas para cargar módulos, obtener eventos y enviar datos de forma segura.
-- Evita duplicar pcall+require, FindFirstChild de eventos, y FireServer en toda la codebase.

local Utilidades = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- SAFE REQUIRE
-- ═══════════════════════════════════════════════════════════════════════════════

---Carga un módulo con pcall y loguea errores de forma uniforme.
-- @param ruta Instance|string — Referencia al ModuleScript o ruta string
-- @param nombreParaLog string — Nombre descriptivo para el mensaje de error (opcional)
-- @return table|nil — El módulo requerido, o nil si falló
function Utilidades.safeRequire(ruta, nombreParaLog)
	local exito, resultado = pcall(function()
		if typeof(ruta) == "Instance" and ruta:IsA("ModuleScript") then
			return require(ruta)
		elseif typeof(ruta) == "string" then
			-- Si es string, asumimos que es una ruta relativa a un servicio conocido
			-- o un require directo. Para simplificar, solo soportamos Instance aquí.
			warn("[safeRequire] Ruta string no soportada directamente. Pasa la instancia ModuleScript.")
			return nil
		end
		return require(ruta)
	end)
	if not exito then
		warn(string.format("[safeRequire] Error cargando %s: %s",
			nombreParaLog or tostring(ruta), tostring(resultado)))
		return nil
	end
	return resultado
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- OBTENCIÓN SEGURA DE EVENTOS REMOTOS
-- ═══════════════════════════════════════════════════════════════════════════════

---Busca un RemoteEvent en una carpeta, con WaitForChild de respaldo.
-- @param carpeta Folder — Carpeta padre (ej. Remotos)
-- @param nombre string — Nombre del evento
-- @param timeout number — Segundos de espera (default 2)
-- @return RemoteEvent|nil
function Utilidades.obtenerEvento(carpeta, nombre, timeout)
	timeout = timeout or 2
	if not carpeta then
		warn(string.format("[obtenerEvento] Carpeta nil al buscar '%s'", nombre))
		return nil
	end
	local ev = carpeta:FindFirstChild(nombre)
	if not ev then
		ev = carpeta:WaitForChild(nombre, timeout)
	end
	if not ev then
		warn(string.format("[obtenerEvento] '%s' no encontrado en %s (timeout=%ds)",
			nombre, carpeta.Name, timeout))
	end
	return ev
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- FIRESERVER SEGURO
-- ═══════════════════════════════════════════════════════════════════════════════

---Envía FireServer con pcall y loguea errores.
-- @param evento RemoteEvent|nil
-- @param ... any — Argumentos a enviar
-- @return boolean — true si se envió exitosamente
function Utilidades.fireServerSeguro(evento, ...)
	if not evento then
		warn("[fireServerSeguro] Evento nil, no se envió nada")
		return false
	end
	local args = {...}
	local ok, err = pcall(function()
		evento:FireServer(table.unpack(args))
	end)
	if not ok then
		warn(string.format("[fireServerSeguro] Error en FireServer (%s): %s",
			evento.Name, tostring(err)))
		return false
	end
	return true
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- NOTIFICACIÓN DE DIÁLOGO CORRECTO (helper específico del proyecto)
-- ═══════════════════════════════════════════════════════════════════════════════

local EventosClientes = require(game:GetService("ReplicatedStorage"):WaitForChild("Compartido"):WaitForChild("EventosClientes"))

---Notifica al servidor que el jugador respondió correctamente una pregunta de diálogo.
-- Centraliza el patrón repetido en 11+ archivos de diálogo.
function Utilidades.notificarDialogoCorrecto()
	local evento = EventosClientes.obtener("DialogoCorrecto", 2)
	Utilidades.fireServerSeguro(evento)
end

return Utilidades
