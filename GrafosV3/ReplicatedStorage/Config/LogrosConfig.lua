-- GrafosV3 - LogrosConfig.lua
-- Configuración centralizada de todos los logros del juego
-- Ubicación: ReplicatedStorage/Config/LogrosConfig.lua

local LogrosConfig = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- DEFINICIÓN DE LOGROS
-- ═══════════════════════════════════════════════════════════════════════════════
-- Cada logro tiene:
--   id          : string único (usado como clave en DataStore)
--   nombre      : string para mostrar
--   descripcion : string explicativa
--   icono       : emoji o rbxassetid
--   categoria   : "progreso", "habilidad", "secreto"
--   secreto     : boolean — si true, se muestra oculto hasta desbloquear
--   condicion   : tabla con tipo y parámetros para verificación automática
--
-- Tipos de condición:
--   { tipo = "nivelCompletado", nivelID = number }
--   { tipo = "estrellasNivel", nivelID = number | "cualquiera" | "todos", estrellas = number }
--   { tipo = "nivelesCompletados", count = number }
--   { tipo = "cablesConectados", count = number, nivelID = number | "cualquiera" }
--   { tipo = "sinFallos", nivelID = number | "cualquiera" }
--   { tipo = "dialogosPerfectos", nivelID = number | "cualquiera" }
--   { tipo = "tiempoRecord", nivelID = number, segundosMax = number }
--   { tipo = "todasZonasVisitadas", nivelID = number }
--   { tipo = "logrosDesbloqueados", count = number } — metalogro
-- ═══════════════════════════════════════════════════════════════════════════════

LogrosConfig.LOGROS = {
	{
		id = "primeros_pasos",
		nombre = "Primeros Pasos",
		descripcion = "Completa el tutorial del Laboratorio de Grafos (Nivel 0).",
		icono = "🎓",
		categoria = "progreso",
		secreto = false,
		condicion = { tipo = "nivelCompletado", nivelID = 0 },
	},
	{
		id = "electricista_novato",
		nombre = "Electricista Novato",
		descripcion = "Repara la red eléctrica del Barrio Antiguo (Nivel 1).",
		icono = "🔌",
		categoria = "progreso",
		secreto = false,
		condicion = { tipo = "nivelCompletado", nivelID = 1 },
	},
	{
		id = "electricista_experto",
		nombre = "Electricista Experto",
		descripcion = "Completa todos los niveles disponibles del juego.",
		icono = "⚡",
		categoria = "progreso",
		secreto = false,
		condicion = { tipo = "nivelesCompletados", count = 5 }, -- Niveles 0-4
	},
	{
		id = "estrella_perfecta",
		nombre = "Estrella Perfecta",
		descripcion = "Obtén 3 estrellas en cualquier nivel.",
		icono = "⭐",
		categoria = "habilidad",
		secreto = false,
		condicion = { tipo = "estrellasNivel", nivelID = "cualquiera", estrellas = 3 },
	},
	{
		id = "maestro_estrellas",
		nombre = "Maestro de Estrellas",
		descripcion = "Obtén 3 estrellas en todos los niveles del juego.",
		icono = "🌟",
		categoria = "habilidad",
		secreto = false,
		condicion = { tipo = "estrellasNivel", nivelID = "todos", estrellas = 3 },
	},
	{
		id = "conector_rapido",
		nombre = "Conector Rápido",
		descripcion = "Conecta 10 cables correctamente en un solo nivel.",
		icono = "🔗",
		categoria = "habilidad",
		secreto = false,
		condicion = { tipo = "cablesConectados", count = 10, nivelID = "cualquiera" },
	},
	{
		id = "manos_estables",
		nombre = "Manos Estables",
		descripcion = "Completa un nivel sin cometer ningún error de conexión.",
		icono = "🙌",
		categoria = "habilidad",
		secreto = false,
		condicion = { tipo = "sinFallos", nivelID = "cualquiera" },
	},
	{
		id = "sabio_grafos",
		nombre = "Sabio de los Grafos",
		descripcion = "Responde todas las preguntas de diálogo correctamente en un nivel.",
		icono = "🧠",
		categoria = "habilidad",
		secreto = false,
		condicion = { tipo = "dialogosPerfectos", nivelID = "cualquiera" },
	},
	{
		id = "explorador_barrio",
		nombre = "Explorador del Barrio",
		descripcion = "Visita todas las zonas de un nivel antes de completarlo.",
		icono = "🗺️",
		categoria = "habilidad",
		secreto = false,
		condicion = { tipo = "todasZonasVisitadas", nivelID = "cualquiera" },
	},
	{
		id = "velocista_electrico",
		nombre = "Velocista Eléctrico",
		descripcion = "Completa un nivel en menos de 3 minutos.",
		icono = "⏱️",
		categoria = "habilidad",
		secreto = false,
		condicion = { tipo = "tiempoRecord", nivelID = "cualquiera", segundosMax = 180 },
	},
	{
		id = "coleccionista",
		nombre = "Coleccionista",
		descripcion = "Desbloquea 5 logros diferentes.",
		icono = "🏆",
		categoria = "progreso",
		secreto = false,
		condicion = { tipo = "logrosDesbloqueados", count = 5 },
	},
	{
		id = "leyenda_grafos",
		nombre = "Leyenda de los Grafos",
		descripcion = "Desbloquea todos los logros del juego.",
		icono = "👑",
		categoria = "progreso",
		secreto = false,
		condicion = { tipo = "logrosDesbloqueados", count = 12 }, -- Total de logros
	},
	{
		id = "conexion_secreta",
		nombre = "Conexión Secreta",
		descripcion = "¿Qué habrá detrás de esta conexión oculta?",
		icono = "❓",
		categoria = "secreto",
		secreto = true,
		condicion = { tipo = "nivelCompletado", nivelID = 2 }, -- Placeholder para nivel futuro
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- ÍNDICES RÁPIDOS
-- ═══════════════════════════════════════════════════════════════════════════════

LogrosConfig.porID = {}
for _, logro in ipairs(LogrosConfig.LOGROS) do
	LogrosConfig.porID[logro.id] = logro
end

LogrosConfig.TOTAL_LOGROS = #LogrosConfig.LOGROS
LogrosConfig.TOTAL_PUBLICOS = 0
for _, logro in ipairs(LogrosConfig.LOGROS) do
	if not logro.secreto then
		LogrosConfig.TOTAL_PUBLICOS = LogrosConfig.TOTAL_PUBLICOS + 1
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- UTILIDADES
-- ═══════════════════════════════════════════════════════════════════════════════

function LogrosConfig.obtenerLogro(id)
	return LogrosConfig.porID[id]
end

function LogrosConfig.obtenerTodos()
	return LogrosConfig.LOGROS
end

function LogrosConfig.obtenerPorCategoria(categoria)
	local resultado = {}
	for _, logro in ipairs(LogrosConfig.LOGROS) do
		if logro.categoria == categoria then
			table.insert(resultado, logro)
		end
	end
	return resultado
end

return LogrosConfig
o_grafos	❌ BUG	Boot.server.lua recibe DialogoCorrecto pero nunca llama ServicioLogros.registrarDialogoCorrecto(). El contador siempre queda en 0.