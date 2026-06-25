-- StarterPlayerScripts/SistemasGameplay/GestorEfectos.lua
-- Bus centralizado de efectos visuales para el cliente.
-- TIPO: ModuleScript (sin sufijo .client — requirable desde LocalScripts)
--
-- ARQUITECTURA:
--   1. Este módulo se carga UNA vez. Los LocalScripts lo requieren con:
--        require(script.Parent:WaitForChild("GestorEfectos"))
--   2. Escucha los eventos del servidor una sola vez y despacha a handlers.
--   3. Los subsistemas de efectos se registran aquí en lugar de conectarse
--      directamente al RemoteEvent, eliminando conexiones duplicadas.
--
-- API:
--   GestorEfectos.registrar(tipoEfecto, handler)
--     → handler(params) — registrar un callback para un tipo de efecto
--   GestorEfectos.emitir(tipoEfecto, params)
--     → despacha localmente sin red (para efectos internos)
--
-- Tipos de efectos que gestiona (desde NotificarSeleccionNodo):
--   "NodoSeleccionado"   params: { arg1=Model nodo, arg2={Model,...} adyacentes }
--   "ConexionCompletada" params: { arg1=string nodoA, arg2=string nodoB, arg3=number peso }
--   "CableDesconectado"  params: { arg1=string nodoA, arg2=string nodoB }
--   "SeleccionCancelada" params: {}
--   "ConexionInvalida"   params: { arg1=Model nodo }
--   "DireccionInvalida"  params: { arg1=Model nodo }
--   "CableCreadoConPeso" params: { arg1=string nodoA, arg2=string nodoB, arg3=number peso }
--   "ClicReparacion"     params: { arg1=string nodo, arg2=number restantes }
--   "NodoReparado"       params: { arg1=string nodo }
--   "FaltaDineroReparacion" params: { arg1=string nodo, arg2=number costo }
--   "FaltaDineroCable"   params: { arg1=string nodoA, arg2=string nodoB, arg3=number peso }
--   "NodoSobrecargado"   params: { arg1=string nodo }
--
-- Eventos de ciclo de vida emitidos localmente:
--   "NivelListo"         params: { arg1=table data }
--   "NivelDescargado"    params: {}
--   "CambioModo"         params: { modo=string, anterior=string|nil }

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GestorEfectos = {}

-- ── Registro de handlers ───────────────────────────────────────────────────
-- _handlers[tipoEfecto] = { handler1, handler2, ... }
local _handlers = {}

---Registra un handler para un tipo de efecto.
-- Permite múltiples handlers por tipo.
function GestorEfectos.registrar(tipoEfecto, handler)
	if type(tipoEfecto) ~= "string" or type(handler) ~= "function" then
		warn("[GestorEfectos] registrar: argumentos inválidos")
		return
	end
	if not _handlers[tipoEfecto] then
		_handlers[tipoEfecto] = {}
	end
	table.insert(_handlers[tipoEfecto], handler)
end

---Despacha un efecto a todos los handlers registrados para ese tipo.
function GestorEfectos.emitir(tipoEfecto, params)
	local lista = _handlers[tipoEfecto]
	if not lista then return end
	for _, handler in ipairs(lista) do
		local ok, err = pcall(handler, params or {})
		if not ok then
			warn("[GestorEfectos] Error en handler de '" .. tipoEfecto .. "':", err)
		end
	end
end

-- ── Conexión única con el servidor ────────────────────────────────────────

local eventos  = ReplicatedStorage:WaitForChild("EventosGrafosV3")
local remotos  = eventos:WaitForChild("Remotos")

local notificar = remotos:WaitForChild("NotificarSeleccionNodo", 10)
if notificar then
	notificar.OnClientEvent:Connect(function(tipoEvento, arg1, arg2, arg3)
		GestorEfectos.emitir(tipoEvento, { arg1 = arg1, arg2 = arg2, arg3 = arg3 })
	end)
	print("[GestorEfectos] Conectado a NotificarSeleccionNodo")
else
	warn("[GestorEfectos] NotificarSeleccionNodo no encontrado — efectos desactivados")
end

-- Eventos de ciclo de vida del nivel
local nivelListoEv = remotos:WaitForChild("NivelListo", 10)
if nivelListoEv then
	nivelListoEv.OnClientEvent:Connect(function(data)
		GestorEfectos.emitir("NivelListo", { arg1 = data })
	end)
	print("[GestorEfectos] Conectado a NivelListo")
else
	warn("[GestorEfectos] NivelListo no encontrado")
end

local nivelDescargadoEv = remotos:WaitForChild("NivelDescargado", 10)
if nivelDescargadoEv then
	nivelDescargadoEv.OnClientEvent:Connect(function()
		GestorEfectos.emitir("NivelDescargado", {})
	end)
	print("[GestorEfectos] Conectado a NivelDescargado")
else
	warn("[GestorEfectos] NivelDescargado no encontrado")
end

print("[GestorEfectos] Bus de efectos listo")

return GestorEfectos
