-- GrafosV3 - ServicioDatos.lua
-- Maneja el guardado y carga de datos del jugador.

local ServicioDatos = {}

local DataStoreService = game:GetService("DataStoreService")
local MainStore = DataStoreService:GetDataStore("GrafosV3_Data")

-- Cache de datos en memoria
ServicioDatos.cache = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- CARGAR DATOS DEL JUGADOR
-- ═══════════════════════════════════════════════════════════════════════════════
function ServicioDatos.cargar(jugador)
	local userId = jugador.UserId
	local clave = "Player_" .. userId
	
	print("[ServicioDatos] Cargando datos para", jugador.Name)
	
	local exito, datos = pcall(function()
		return MainStore:GetAsync(clave)
	end)
	
	if exito and datos then
		ServicioDatos.cache[userId] = datos
		print("[ServicioDatos] ✅ Datos cargados para", jugador.Name)
	else
		-- Crear datos iniciales
		local datosIniciales = {
			nivelesDesbloqueados = {0},  -- Solo nivel 0
			nivelActual = 0,
			progresoNiveles = {}  -- { [nivelID] = { estrellas, puntajeAlto, etc } }
		}
		
		ServicioDatos.cache[userId] = datosIniciales
		print("[ServicioDatos] ✅ Datos iniciales creados para", jugador.Name)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- GUARDAR DATOS DEL JUGADOR
-- ═══════════════════════════════════════════════════════════════════════════════
function ServicioDatos.guardar(jugador)
	local userId = jugador.UserId
	local clave = "Player_" .. userId
	local datos = ServicioDatos.cache[userId]
	
	if not datos then
		warn("[ServicioDatos] ⚠️ No hay datos en cache para", jugador.Name)
		return
	end
	
	print("[ServicioDatos] Guardando datos para", jugador.Name)
	
	local exito, error = pcall(function()
		MainStore:SetAsync(clave, datos)
	end)
	
	if exito then
		print("[ServicioDatos] ✅ Datos guardados para", jugador.Name)
	else
		warn("[ServicioDatos] ❌ Error guardando:", error)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- OBTENER DATOS EN CACHE
-- ═══════════════════════════════════════════════════════════════════════════════
function ServicioDatos.obtener(jugador)
	return ServicioDatos.cache[jugador.UserId]
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- ACTUALIZAR PROGRESO DE NIVEL
-- ═══════════════════════════════════════════════════════════════════════════════
function ServicioDatos.actualizarNivel(jugador, nivelID, datosNivel)
	local userId = jugador.UserId
	local datos = ServicioDatos.cache[userId]
	
	if not datos then return end
	
	datos.progresoNiveles[nivelID] = datosNivel
	
	-- Desbloquear siguiente nivel si completo este
	if datosNivel.estrellas and datosNivel.estrellas > 0 then
		local siguienteNivel = nivelID + 1
		if not table.find(datos.nivelesDesbloqueados, siguienteNivel) then
			table.insert(datos.nivelesDesbloqueados, siguienteNivel)
			print("[ServicioDatos] ✅ Nivel desbloqueado:", siguienteNivel)
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- AL JUGADOR SALIR
-- ═══════════════════════════════════════════════════════════════════════════════
function ServicioDatos.alSalir(jugador)
	ServicioDatos.guardar(jugador)
	ServicioDatos.cache[jugador.UserId] = nil
end

return ServicioDatos
