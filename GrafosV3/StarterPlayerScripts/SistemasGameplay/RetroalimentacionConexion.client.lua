-- StarterPlayerScripts/SistemasGameplay/RetroalimentacionConexion.client.lua
-- Escucha NotificarSeleccionNodo y abre el diálogo de retroalimentación educativa
-- cuando el jugador intenta una conexión inválida o en dirección incorrecta.

local Players = game:GetService("Players")

local jugador = Players.LocalPlayer

-- Mapa: tipo de efecto → ID del diálogo de retroalimentación
local DIALOGO_POR_TIPO = {
	ConexionInvalida  = "Feedback_ConexionInvalida",
	DireccionInvalida = "Feedback_DireccionInvalida",
}

local function mapaEstaAbierto()
	return jugador:GetAttribute("MapaAbierto") == true
end

-- Esperar a que ControladorDialogo esté listo (se registra en _G al iniciar)
local function obtenerControlador()
	local intentos = 0
	while not _G.ControladorDialogo and intentos < 100 do
		task.wait(0.1)
		intentos = intentos + 1
	end
	return _G.ControladorDialogo
end

local controlador = nil
task.spawn(function()
	controlador = obtenerControlador()
	if controlador then
		print("[RetroalimentacionConexion] ✓ ControladorDialogo obtenido")
	else
		warn("[RetroalimentacionConexion] ControladorDialogo no disponible")
	end
end)

-- Registrar en GestorEfectos en lugar de conectarse directamente al RemoteEvent
local GestorEfectos = require(script.Parent:WaitForChild("GestorEfectos"))

GestorEfectos.registrar("ConexionInvalida", function(_params)
	if not controlador then return end
	if controlador.estaActivo() then return end
	if mapaEstaAbierto() then return end
	controlador.iniciar(DIALOGO_POR_TIPO.ConexionInvalida)
end)

GestorEfectos.registrar("DireccionInvalida", function(_params)
	if not controlador then return end
	if controlador.estaActivo() then return end
	if mapaEstaAbierto() then return end
	controlador.iniciar(DIALOGO_POR_TIPO.DireccionInvalida)
end)

print("[RetroalimentacionConexion] ✓ Escuchando errores de conexión")
