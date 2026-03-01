-- StarterPlayerScripts/SistemasGameplay/ControladorColisiones.client.lua
-- Controlador cliente para GestorColisiones - inicializa automáticamente al cargar nivel

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local jugador = Players.LocalPlayer

-- Importar GestorColisiones
local GestorColisiones = require(ReplicatedStorage.Compartido.GestorColisiones)

-- Eventos
local Eventos = ReplicatedStorage:WaitForChild("EventosGrafosV3")
local Remotos = Eventos:WaitForChild("Remotos")

print("[GrafosV3] === ControladorColisiones Iniciando ===")

-- Inicializar GestorColisiones cuando el nivel está listo
Remotos.NivelListo.OnClientEvent:Connect(function(data)
	if data and data.error then
		warn("[ControladorColisiones] Error al cargar nivel:", data.error)
		return
	end
	
	-- Esperar un frame para que el nivel esté completamente cargado
	task.wait()
	
	local nivelActual = Workspace:FindFirstChild("NivelActual")
	if nivelActual then
		-- Capturar techos del nivel
		local conteo = GestorColisiones:capturar(nivelActual)
		if conteo and conteo > 0 then
			print("[ControladorColisiones] Techos capturados:", conteo)
		else
			print("[ControladorColisiones] No se encontraron techos en el nivel")
		end
	else
		warn("[ControladorColisiones] No se encontró NivelActual en Workspace")
	end
end)

-- Limpiar cuando se descarga el nivel
Remotos.NivelDescargado.OnClientEvent:Connect(function()
	print("[ControladorColisiones] Nivel descargado - liberando referencias")
	GestorColisiones:liberar()
end)

-- API Pública para otros sistemas
local ControladorColisiones = {}

---Oculta los techos (para vista cenital del mapa)
function ControladorColisiones.ocultarTechos()
	GestorColisiones:ocultarTecho()
end

---Restaura los techos a su estado original
function ControladorColisiones.restaurarTechos()
	GestorColisiones:restaurar()
end

---Verifica si hay techos capturados
function ControladorColisiones.tieneTechos()
	return GestorColisiones:tieneTechosCapturados()
end

---Obtiene el gestor de colisiones subyacente (para uso avanzado)
function ControladorColisiones.obtenerGestor()
	return GestorColisiones
end

-- Exponer globalmente para facilitar acceso desde otros sistemas
_G.ControladorColisiones = ControladorColisiones

print("[GrafosV3] ✅ ControladorColisiones activo y esperando NivelListo")
