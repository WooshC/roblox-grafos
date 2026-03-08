-- StarterPlayerScripts/SistemasGameplay/RetroalimentacionConexion.client.lua
-- Escucha NotificarSeleccionNodo y abre el diálogo de retroalimentación educativa
-- cuando el jugador intenta una conexión inválida o en dirección incorrecta.

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local jugador = Players.LocalPlayer

-- Mapa: tipo de evento → ID del diálogo de retroalimentación
local DIALOGO_POR_TIPO = {
	ConexionInvalida  = "Feedback_ConexionInvalida",
	DireccionInvalida = "Feedback_DireccionInvalida",
}

-- Esperar a que ControladorDialogo esté listo (se registra en _G al iniciar)
local function obtenerControlador()
	local intentos = 0
	while not _G.ControladorDialogo and intentos < 100 do
		task.wait(0.1)
		intentos = intentos + 1
	end
	return _G.ControladorDialogo
end

local function mapaEstaAbierto()
	return jugador:GetAttribute("MapaAbierto") == true
end

local eventos   = ReplicatedStorage:WaitForChild("EventosGrafosV3")
local remotos   = eventos:WaitForChild("Remotos")
local notificar = remotos:WaitForChild("NotificarSeleccionNodo", 10)

if not notificar then
	warn("[RetroalimentacionConexion] NotificarSeleccionNodo no encontrado")
	return
end

-- Obtener controlador en background para no bloquear la conexión del evento
local controlador = nil
task.spawn(function()
	controlador = obtenerControlador()
	if controlador then
		print("[RetroalimentacionConexion] ✓ ControladorDialogo obtenido")
	else
		warn("[RetroalimentacionConexion] ControladorDialogo no disponible")
	end
end)

notificar.OnClientEvent:Connect(function(tipo)
	local dialogoID = DIALOGO_POR_TIPO[tipo]
	if not dialogoID then return end

	-- Si el controlador aún no está listo, ignorar
	if not controlador then return end

	-- No interrumpir si ya hay un diálogo activo (por ejemplo, diálogo de zona)
	if controlador.estaActivo() then return end

	-- Si el mapa está abierto, NO abrir el diálogo: su GUI bloquearía los clics
	-- del mapa (gameProcessed = true) impidiendo seleccionar nodos.
	if mapaEstaAbierto() then return end

	controlador.iniciar(dialogoID)
end)

print("[RetroalimentacionConexion] ✓ Escuchando errores de conexión")
