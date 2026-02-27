-- GrafosV3 - ServicioProgreso.lua
-- Formatea los datos del jugador para mostrar en el menu.

local ServicioProgreso = {}

-- Configuracion de niveles
local CONFIG_NIVELES = {
	[0] = {
		nombre = "Laboratorio de Grafos",
		descripcion = "Aprende los conceptos básicos de grafos",
		seccion = "TUTORIAL"
	},
	[1] = {
		nombre = "Estación Central",
		descripcion = "Conecta las vías del tren",
		seccion = "NIVELES PRINCIPALES"
	},
	[2] = {
		nombre = "Complejo Industrial",
		descripcion = "Optimiza las conexiones eléctricas",
		seccion = "NIVELES PRINCIPALES"
	},
	[3] = {
		nombre = "Ciudad Digital",
		descripcion = "Resuelve el problema de red",
		seccion = "NIVELES AVANZADOS"
	}
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- OBTENER PROGRESO FORMATEADO PARA EL CLIENTE
-- ═══════════════════════════════════════════════════════════════════════════════
function ServicioProgreso.obtenerProgreso(jugador)
	-- Obtener servicio de datos (si existe)
	local ServicioDatos = nil
	pcall(function()
		local servicios = game:GetService("ServerScriptService"):WaitForChild("Servicios")
		ServicioDatos = require(servicios:WaitForChild("ServicioDatos"))
	end)
	
	local datosJugador = nil
	if ServicioDatos and ServicioDatos.obtener then
		datosJugador = ServicioDatos.obtener(jugador)
	end
	
	local nivelesDesbloqueados = {0}  -- Por defecto solo nivel 0
	local progresoNiveles = {}
	
	if datosJugador then
		nivelesDesbloqueados = datosJugador.nivelesDesbloqueados or {0}
		progresoNiveles = datosJugador.progresoNiveles or {}
	end
	
	-- Construir array de niveles para el cliente
	local resultado = {}
	
	for nivelID, config in pairs(CONFIG_NIVELES) do
		local progreso = progresoNiveles[nivelID] or {}
		local desbloqueado = table.find(nivelesDesbloqueados, nivelID) ~= nil
		
		local estado = "bloqueado"
		if desbloqueado then
			if (progreso.estrellas or 0) >= 1 then
				estado = "completado"
			else
				estado = "disponible"
			end
		end
		
		table.insert(resultado, {
			nivelID = nivelID,
			nombre = config.nombre,
			descripcion = config.descripcion,
			seccion = config.seccion,
			estado = estado,
			estrellas = progreso.estrellas or 0,
			puntajeAlto = progreso.puntajeAlto or 0,
			aciertos = progreso.aciertos or 0,
			fallos = progreso.fallos or 0,
			tiempoMejor = progreso.tiempoMejor or 0,
			intentos = progreso.intentos or 0
		})
	end
	
	-- Ordenar por nivelID
	table.sort(resultado, function(a, b)
		return a.nivelID < b.nivelID
	end)
	
	return resultado
end

return ServicioProgreso
