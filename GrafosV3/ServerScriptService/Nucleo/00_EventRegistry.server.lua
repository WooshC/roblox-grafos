-- ServerScriptService/Nucleo/EventRegistry.server.lua
-- TIPO: Script (servidor) - se auto-ejecuta al arrancar el servidor.
-- Debe correr ANTES que Boot.server.lua.
--
-- Responsabilidad: garantizar que todos los RemoteEvents, RemoteFunctions
-- existan en ReplicatedStorage/EventosGrafosV3/Remotos.
-- Si ya estan creados en Studio -> los deja intactos.
-- Si falta alguno -> lo crea automaticamente.
--
-- Ubicacion Roblox: ServerScriptService/Nucleo/EventRegistry.server.lua

local Replicado = game:GetService("ReplicatedStorage")

-- ═══════════════════════════════════════════════════════════════════════════════
-- EVENTOS REMOTOS ESPERADOS
-- ═══════════════════════════════════════════════════════════════════════════════
local EVENTOS_REMOTOS = {
	-- Menu y Progreso
	{ nombre = "ServidorListo",         tipo = "RemoteEvent" },      -- Server -> Cliente (GUI lista)
	{ nombre = "ObtenerProgresoJugador", tipo = "RemoteFunction" },  -- Cliente <-> Server (datos niveles)
	{ nombre = "IniciarNivel",           tipo = "RemoteEvent" },      -- Cliente -> Server (click jugar)
	{ nombre = "NivelListo",             tipo = "RemoteEvent" },      -- Server -> Cliente (nivel cargado)
	{ nombre = "NivelDescargado",        tipo = "RemoteEvent" },      -- Server -> Cliente (volver al menu)
	{ nombre = "VolverAlMenu",           tipo = "RemoteEvent" },      -- Cliente -> Server (salir del nivel)
	
	-- Gameplay - Cableado
	{ nombre = "CableDragEvent",         tipo = "RemoteEvent" },      -- Server -> Cliente (preview arrastre)
	{ nombre = "NotificarSeleccionNodo", tipo = "RemoteEvent" },      -- Server -> Cliente (efectos nodo)
	{ nombre = "PulsoEvent",             tipo = "RemoteEvent" },      -- Server -> Cliente (pulso energia cable)
	
	-- Gameplay - Puntuacion
	{ nombre = "ActualizarPuntuacion",   tipo = "RemoteEvent" },      -- Server -> Cliente (puntos en tiempo real)
	{ nombre = "PuntuacionFinal",        tipo = "RemoteEvent" },      -- Server -> Cliente (resultado final)
	
	-- Gameplay - Efectos
	{ nombre = "ReproducirEfecto",       tipo = "RemoteEvent" },      -- Server -> Cliente (efectos visuales)
	{ nombre = "PulsoEvent",             tipo = "RemoteEvent" },      -- Server -> Cliente (pulso de energia)
	
	-- Gameplay - Misiones y Progreso
	{ nombre = "ActualizarMisiones",     tipo = "RemoteEvent" },      -- Server -> Cliente (misiones activas)
	{ nombre = "NivelCompletado",        tipo = "RemoteEvent" },      -- Server -> Cliente (victoria)
	{ nombre = "ReiniciarNivel",         tipo = "RemoteEvent" },      -- Cliente -> Server (reintentar)
	{ nombre = "RestartLevel",           tipo = "RemoteEvent" },      -- Cliente -> Server (reintentar - compat)
	
	-- Gameplay - Mapa
	{ nombre = "MapaClickNodo",          tipo = "RemoteEvent" },      -- Cliente -> Server (click en nodo desde mapa)
	{ nombre = "ConectarDesdeMapa",      tipo = "RemoteEvent" },      -- Cliente -> Server (solicitar conexión desde mapa)
	
	-- Configuracion
	{ nombre = "AplicarDificultad",      tipo = "RemoteEvent" },      -- Cliente -> Server (cambiar dificultad)
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════════════════
local function asegurarCarpeta(parent, nombre)
	local carpeta = parent:FindFirstChild(nombre)
	if not carpeta then
		carpeta = Instance.new("Folder")
		carpeta.Name = nombre
		carpeta.Parent = parent
		print("[EventRegistry] Carpeta creada:", nombre)
	end
	return carpeta
end

local function asegurarEvento(parent, nombre, tipo)
	local existente = parent:FindFirstChild(nombre)
	if existente then
		return existente
	end
	
	local evento = Instance.new(tipo)
	evento.Name = nombre
	evento.Parent = parent
	return evento
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CREAR ESTRUCTURA
-- ═══════════════════════════════════════════════════════════════════════════════
local function inicializar()
	print("[EventRegistry] === Inicializando Registro de Eventos ===")
	
	-- Crear estructura de carpetas: ReplicatedStorage/EventosGrafosV3/Remotos
	local carpetaEventos = asegurarCarpeta(Replicado, "EventosGrafosV3")
	local carpetaRemotos = asegurarCarpeta(carpetaEventos, "Remotos")
	
	-- Crear todos los eventos remotos
	for _, config in ipairs(EVENTOS_REMOTOS) do
		asegurarEvento(carpetaRemotos, config.nombre, config.tipo)
	end
	
	print("[EventRegistry] === Todos los eventos verificados ===")
end

inicializar()
