-- GrafosV3 - ServicioProgreso.lua
-- Enriquece datos de LevelsConfig con progreso del jugador

local ServicioProgreso = {}

local DataStoreService = game:GetService("DataStoreService")
local RS = game:GetService("ReplicatedStorage")

local store = DataStoreService:GetDataStore("GrafosV3_Progreso_v1")
local LevelsConfig = require(RS:WaitForChild("Config"):WaitForChild("LevelsConfig"))

-- Datos por defecto para cada nivel
local DATOS_NIVEL_DEFAULT = {
	desbloqueado = false,
	estrellas = 0,
	puntajeAlto = 0,
	aciertos = 0,
	fallos = 0,
	tiempoMejor = 0,
	intentos = 0,
}

local cache = {}

-- ============================================
-- UTILIDADES
-- ============================================

local function crearDatosDefault()
	local datos = {}
	for i = 0, 4 do
		local fila = {}
		for k, v in pairs(DATOS_NIVEL_DEFAULT) do
			fila[k] = v
		end
		datos[tostring(i)] = fila
	end
	-- Nivel 0 siempre desbloqueado
	datos["0"].desbloqueado = true
	return datos
end

-- ============================================
-- CARGAR/GUARDAR DATOS
-- ============================================

function ServicioProgreso.cargar(jugador)
	if cache[jugador.UserId] then
		return cache[jugador.UserId]
	end
	
	local key = "player_" .. jugador.UserId
	local ok, raw = pcall(function()
		return store:GetAsync(key)
	end)
	
	local datos = (ok and raw) or crearDatosDefault()
	
	-- Asegurar que existan todos los niveles
	for i = 0, 4 do
		local k = tostring(i)
		if not datos[k] then
			local fila = {}
			for kk, vv in pairs(DATOS_NIVEL_DEFAULT) do
				fila[kk] = vv
			end
			if i == 0 then
				fila.desbloqueado = true
			end
			datos[k] = fila
		end
	end
	
	cache[jugador.UserId] = datos
	print("[ServicioProgreso] Datos cargados para", jugador.Name)
	return datos
end

function ServicioProgreso.guardar(jugador)
	local datos = cache[jugador.UserId]
	if not datos then
		return
	end
	
	local key = "player_" .. jugador.UserId
	local ok, err = pcall(function()
		store:SetAsync(key, datos)
	end)
	
	if ok then
		print("[ServicioProgreso] Progreso guardado para", jugador.Name)
	else
		warn("[ServicioProgreso] Error al guardar:", err)
	end
end

function ServicioProgreso.guardarResultado(jugador, nivelID, resultado)
	local datos = ServicioProgreso.cargar(jugador)
	local k = tostring(nivelID)
	local nivelDatos = datos[k] or {}
	
	-- Siempre incrementar intentos
	nivelDatos.intentos = (nivelDatos.intentos or 0) + 1
	
	-- Guardar datos del intento actual
	nivelDatos.puntajeAlto = resultado.puntaje or 0
	nivelDatos.estrellas = resultado.estrellas or 0
	nivelDatos.aciertos = resultado.aciertos or 0
	nivelDatos.fallos = resultado.fallos or 0
	nivelDatos.tiempoMejor = resultado.tiempo or 0
	
	-- Desbloquear siguiente nivel si tiene estrellas
	if (resultado.estrellas or 0) > 0 and nivelID < 4 then
		local nextK = tostring(nivelID + 1)
		if datos[nextK] then
			datos[nextK].desbloqueado = true
		end
	end
	
	datos[k] = nivelDatos
	print(string.format(
		"[ServicioProgreso] Resultado guardado - nivel=%d intentos=%d aciertos=%d fallos=%d puntaje=%d estrellas=%d",
		nivelID, nivelDatos.intentos, nivelDatos.aciertos, nivelDatos.fallos, 
		nivelDatos.puntajeAlto, nivelDatos.estrellas
	))
	
	-- Guardar async
	task.spawn(function()
		ServicioProgreso.guardar(jugador)
	end)
end

-- ============================================
-- OBTENER PROGRESO ENRIQUECIDO PARA CLIENTE
-- ============================================

function ServicioProgreso.obtenerProgresoParaCliente(jugador)
	local datos = ServicioProgreso.cargar(jugador)
	local resultado = {}
	
	for i = 0, 4 do
		local k = tostring(i)
		local nivelDatos = datos[k] or {}
		local config = LevelsConfig[i] or {}
		
		local desbloqueado = nivelDatos.desbloqueado or (i == 0)
		local estrellas = nivelDatos.estrellas or 0
		
		local status = (not desbloqueado) and "bloqueado"
			or (estrellas > 0) and "completado"
			or "disponible"
		
		-- Enriquecer con datos de LevelsConfig
		resultado[k] = {
			nivelID = i,
			nombre = config.Nombre or ("Nivel " .. i),
			imageId = config.ImageId or "",
			algoritmo = config.Algoritmo,
			tag = config.Tag or ("NIVEL " .. i),
			descripcion = config.DescripcionCorta or "",
			conceptos = config.Conceptos or {},
			seccion = config.Seccion or "NIVELES",
			status = status,
			desbloqueado = desbloqueado,
			estrellas = estrellas,
			highScore = nivelDatos.puntajeAlto or 0,
			aciertos = nivelDatos.aciertos or 0,
			fallos = nivelDatos.fallos or 0,
			tiempoMejor = nivelDatos.tiempoMejor or 0,
			intentos = nivelDatos.intentos or 0,
		}
	end
	
	return resultado
end

function ServicioProgreso.alJugadorSalir(jugador)
	ServicioProgreso.guardar(jugador)
	cache[jugador.UserId] = nil
end

return ServicioProgreso
