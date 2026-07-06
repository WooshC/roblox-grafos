-- StarterPlayerScripts/SistemasGameplay/ControladorBloqueos.client.lua
-- Controlador cliente para GestorBloqueos - inicializa automaticamente al cargar nivel
-- y escucha ActualizarMisiones para eliminar bloqueos al completar zonas.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local jugador = Players.LocalPlayer

-- Importar GestorBloqueos
local GestorBloqueos = require(ReplicatedStorage.Compartido.GestorBloqueos)

-- Eventos
local Eventos = ReplicatedStorage:WaitForChild("EventosGrafosV3")
local Remotos = Eventos:WaitForChild("Remotos")

print("[GrafosV3] === ControladorBloqueos Iniciando ===")

-- Zonas ya procesadas (para no intentar eliminar bloqueos de una zona repetidamente)
local _zonasProcesadas = {}
local _zonasCompletadas = {}

local function procesarZonaCompletada(nombreZona)
	if _zonasProcesadas[nombreZona] then return end

	local eliminados, intentoValido, configurados = GestorBloqueos:eliminarPorZona(nombreZona)
	if not intentoValido then
		print(string.format("[ControladorBloqueos] Zona '%s' pendiente hasta capturar los bloqueos", nombreZona))
		return
	end

	-- Si había un bloqueo configurado pero no se encontró, se conserva como
	-- pendiente para poder reintentarlo después de una nueva captura.
	if configurados and configurados > 0 and eliminados == 0 then
		warn(string.format("[ControladorBloqueos] Bloqueo de zona '%s' no encontrado; se reintentará", nombreZona))
		return
	end

	_zonasProcesadas[nombreZona] = true
end

local function reconciliarZonasCompletadas()
	for nombreZona in pairs(_zonasCompletadas) do
		procesarZonaCompletada(nombreZona)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- INICIALIZAR: Capturar bloqueos cuando el nivel esta listo
-- ═══════════════════════════════════════════════════════════════════════════════
Remotos.NivelListo.OnClientEvent:Connect(function(data)
	if data and data.error then
		warn("[ControladorBloqueos] Error al cargar nivel:", data.error)
		return
	end

	-- Reiniciar antes de ceder el hilo. ActualizarMisiones puede llegar durante
	-- la espera y sus zonas completadas deben conservarse para reconciliarlas.
	_zonasProcesadas = {}
	_zonasCompletadas = {}

	-- Esperar un frame para que el nivel este completamente cargado
	task.wait()

	local nivelActual = Workspace:FindFirstChild("NivelActual")
	if nivelActual then
		local conteo = GestorBloqueos:capturar(nivelActual)
		if conteo and conteo > 0 then
			print("[ControladorBloqueos] Bloqueos capturados:", conteo)
		else
			print("[ControladorBloqueos] No se encontraron bloqueos en el nivel")
		end
		reconciliarZonasCompletadas()
	else
		warn("[ControladorBloqueos] No se encontro NivelActual en Workspace")
	end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- LIMPIAR: Liberar referencias cuando se descarga el nivel
-- ═══════════════════════════════════════════════════════════════════════════════
Remotos.NivelDescargado.OnClientEvent:Connect(function()
	print("[ControladorBloqueos] Nivel descargado - liberando referencias")
	GestorBloqueos:liberar()
	_zonasProcesadas = {}
	_zonasCompletadas = {}
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- ESCUCHAR MISIONES: Eliminar bloqueos cuando una zona se completa
-- ═══════════════════════════════════════════════════════════════════════════════
local actualizarMisionesEv = Remotos:WaitForChild("ActualizarMisiones", 10)
if actualizarMisionesEv then
	actualizarMisionesEv.OnClientEvent:Connect(function(datos)
		if not datos or not datos.porZona then return end

		for nombreZona, infoZona in pairs(datos.porZona) do
			-- Si la zona tiene misiones y estan todas completadas
			if infoZona.total and infoZona.completadas and infoZona.total > 0 and infoZona.completadas >= infoZona.total then
				_zonasCompletadas[nombreZona] = true
				print(string.format("[ControladorBloqueos] Zona '%s' completada - verificando bloqueos...", nombreZona))
				procesarZonaCompletada(nombreZona)
			end
		end
	end)
	print("[ControladorBloqueos] Escuchando ActualizarMisiones para auto-eliminar bloqueos por zona")
else
	warn("[ControladorBloqueos] ActualizarMisiones no encontrado - eliminacion por zona no funcionara")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- API PUBLICA
-- ═══════════════════════════════════════════════════════════════════════════════
local ControladorBloqueos = {}

---Elimina un bloqueo por nombre
function ControladorBloqueos.eliminar(nombre)
	return GestorBloqueos:eliminar(nombre)
end

---Elimina bloqueos configurados para un dialogo especifico
function ControladorBloqueos.eliminarPorDialogo(dialogoID)
	GestorBloqueos:eliminarPorDialogo(dialogoID)
end

---Elimina bloqueos configurados para una zona especifica
function ControladorBloqueos.eliminarPorZona(zonaNombre)
	GestorBloqueos:eliminarPorZona(zonaNombre)
end

---Obtiene el gestor de bloqueos subyacente
function ControladorBloqueos.obtenerGestor()
	return GestorBloqueos
end

-- Exponer globalmente para facilitar acceso desde dialogos y otros sistemas
_G.ControladorBloqueos = ControladorBloqueos
_G.GestorBloqueos = GestorBloqueos

print("[GrafosV3] ControladorBloqueos activo y esperando NivelListo")
