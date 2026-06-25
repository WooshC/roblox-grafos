-- StarterPlayerScripts/SistemasGameplay/OrquestadorModos.lua
-- Orquestador de modos visuales del cliente.
--
-- RESPONSABILIDAD:
--   Garantizar que solo un modo visual esté activo en el mundo 3D a la vez
--   (visual, mapa, algoritmo3d) y notificar a todos los sistemas cuando cambia.
--
-- USO:
--   local OrquestadorModos = require(script.Parent:WaitForChild("OrquestadorModos"))
--   OrquestadorModos.registrarModo("visual", {
--       activar = function() ... end,
--       limpiar = function() ... end,
--   })
--   OrquestadorModos.setModo("mapa")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GestorEfectos = require(script.Parent:WaitForChild("GestorEfectos"))

local OrquestadorModos = {}

-- Modos registrados: { nombre = { activar = fn, limpiar = fn } }
local _modos = {}

-- Modo actual
local _modoActual = "visual"

-- Callback externo para sincronizar UI (SelectorModosHUD)
local _callbackUI = nil

---Registra un modo visual.
-- @param nombre string
-- @param handlers table { activar = function()?, limpiar = function()? }
function OrquestadorModos.registrarModo(nombre, handlers)
	if type(nombre) ~= "string" then
		warn("[OrquestadorModos] registrarModo: nombre debe ser string")
		return
	end
	if type(handlers) ~= "table" then
		warn("[OrquestadorModos] registrarModo: handlers debe ser table")
		return
	end
	_modos[nombre] = {
		activar = type(handlers.activar) == "function" and handlers.activar or function() end,
		limpiar = type(handlers.limpiar) == "function" and handlers.limpiar or function() end,
	}
end

---Establece un callback para sincronizar la UI del selector de modos.
-- @param callback function(nombreModo)
function OrquestadorModos.setCallbackUI(callback)
	if type(callback) == "function" then
		_callbackUI = callback
	end
end

---Cambia el modo visual activo.
-- Limpia el modo anterior, activa el nuevo y notifica a todos los sistemas.
-- @param nombre string — nombre del modo destino
function OrquestadorModos.setModo(nombre)
	if nombre == _modoActual then return end
	if not _modos[nombre] then
		warn("[OrquestadorModos] Modo no registrado:", nombre)
		return
	end

	local anterior = _modoActual
	print(string.format("[OrquestadorModos] Cambiando modo: %s → %s", anterior, nombre))

	-- 1. Limpiar modo anterior
	local modoAnterior = _modos[anterior]
	if modoAnterior then
		local ok, err = pcall(modoAnterior.limpiar)
		if not ok then
			warn("[OrquestadorModos] Error limpiando modo '" .. anterior .. "':", err)
		end
	end

	-- 2. Actualizar estado
	_modoActual = nombre

	-- 3. Notificar a todos los sistemas via bus ANTES de activar el nuevo modo.
	--    Esto garantiza que los sistemas de efectos limpien su estado antes de que
	--    el nuevo modo (p. ej. mapa) aplique sus propios colores/highlight.
	GestorEfectos.emitir("CambioModo", { modo = nombre, anterior = anterior })

	-- 4. Sincronizar UI
	if _callbackUI then
		local ok2, err2 = pcall(_callbackUI, nombre)
		if not ok2 then
			warn("[OrquestadorModos] Error en callbackUI:", err2)
		end
	end

	-- 5. Activar modo nuevo
	local modoNuevo = _modos[nombre]
	local ok, err = pcall(modoNuevo.activar)
	if not ok then
		warn("[OrquestadorModos] Error activando modo '" .. nombre .. "':", err)
	end
end

---Devuelve el nombre del modo actual.
function OrquestadorModos.obtenerModoActual()
	return _modoActual
end

---Devuelve si el modo dado es el actual.
function OrquestadorModos.esModoActual(nombre)
	return _modoActual == nombre
end

-- Registro del modo visual por defecto (no hace nada especial, solo existe)
OrquestadorModos.registrarModo("visual", {})

print("[OrquestadorModos] Inicializado — modo:", _modoActual)

return OrquestadorModos
