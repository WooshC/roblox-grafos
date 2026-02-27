-- OrquestadorGameplay.lua
-- UNICO responsable: Activar/desactivar TODO el sistema de gameplay como unidad.
-- 
-- Regla de Oro: Mientras este el menu activo, TODO lo de gameplay esta desconectado.
-- Este orquestador garantiza que todos los modulos se activen/desactiven juntos.

local OrquestadorGameplay = {}

-- Referencias a modulos (se cargan en inicializar)
local MODULOS = {}

-- Estado
OrquestadorGameplay.activo = false
OrquestadorGameplay.jugadorActual = nil
OrquestadorGameplay.idNivelActual = nil

-- ═══════════════════════════════════════════════════════════════════════════════
-- CARGAR MODULO SEGURO: Intenta cargar un modulo con varios nombres posibles
-- ═══════════════════════════════════════════════════════════════════════════════
local function cargarModuloSeguro(nombres, ubicaciones)
	for _, ubicacion in ipairs(ubicaciones) do
		for _, nombre in ipairs(nombres) do
			local modulo = ubicacion:FindFirstChild(nombre)
			if modulo then
				local exito, resultado = pcall(function()
					return require(modulo)
				end)
				if exito then
					return resultado
				else
					warn("[OrquestadorGameplay] Error cargando " .. nombre .. ": " .. tostring(resultado))
				end
			end
		end
	end
	return nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- INICIALIZAR: Cargar referencias a modulos (llamar una vez desde Boot)
-- ═══════════════════════════════════════════════════════════════════════════════
function OrquestadorGameplay:inicializar()
	local servidorScriptService = game:GetService("ServerScriptService")
	local gameplayFolder = script.Parent
	local modulosFolder = gameplayFolder:FindFirstChild("Modulos")
	
	print("[OrquestadorGameplay] Inicializando...")
	print("[OrquestadorGameplay]   Folder gameplay: " .. tostring(gameplayFolder))
	print("[OrquestadorGameplay]   Folder modulos: " .. tostring(modulosFolder))
	
	-- Definir ubicaciones de busqueda
	local ubicaciones = {servidorScriptService}
	if modulosFolder then
		table.insert(ubicaciones, 1, modulosFolder) -- Priorizar Modulos/
	end
	
	-- Cargar cada modulo con nombres alternativos
	MODULOS.puntaje = cargarModuloSeguro(
		{"RegistroPuntaje", "ScoreTracker"},
		ubicaciones
	)
	
	MODULOS.cables = cargarModuloSeguro(
		{"ModuloConexionCables", "ConectarCables"},
		ubicaciones
	)
	
	MODULOS.zonas = cargarModuloSeguro(
		{"ModuloDeteccionZonas", "ZoneTriggerManager"},
		ubicaciones
	)
	
	MODULOS.misiones = cargarModuloSeguro(
		{"ModuloValidacionMisiones", "MissionService"},
		ubicaciones
	)
	
	-- Reportar estado
	print("[OrquestadorGameplay] Modulos cargados:")
	print("  - Puntaje: " .. (MODULOS.puntaje and "✅" or "❌"))
	print("  - Cables: " .. (MODULOS.cables and "✅" or "❌"))
	print("  - Zonas: " .. (MODULOS.zonas and "✅" or "❌"))
	print("  - Misiones: " .. (MODULOS.misiones and "✅" or "❌"))
	
	print("[OrquestadorGameplay] ✅ Inicializado")
	return self
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- INICIAR NIVEL: Llamado UNA VEZ cuando el jugador entra a un nivel
-- ═══════════════════════════════════════════════════════════════════════════════
function OrquestadorGameplay:iniciarNivel(jugador, idNivel, configuracionNivel, carpetaRemotos)
	if self.activo then
		print("[OrquestadorGameplay] ⚠️ Ya hay un nivel activo, deteniendo primero...")
		self:detenerNivel()
	end
	
	print(string.format("[OrquestadorGameplay] ▶️ INICIAR NIVEL | Jugador: %s | Nivel: %d", 
		tostring(jugador and jugador.Name), tonumber(idNivel) or 0))
	
	-- Guardar estado
	self.activo = true
	self.jugadorActual = jugador
	self.idNivelActual = idNivel
	
	-- Preparar contexto para modulos
	local contexto = {
		jugador = jugador,
		idNivel = idNivel,
		configuracion = configuracionNivel,
		nivelActual = workspace:FindFirstChild("NivelActual"),
		carpetaRemotos = carpetaRemotos,
	}
	
	-- ORDEN CRITICO de inicializacion (algunos modulos dependen de otros)
	local exito, errorMsg = pcall(function()
		-- 1. Puntaje primero (otros modulos pueden reportar puntos)
		if MODULOS.puntaje then
			if MODULOS.puntaje.activar then
				MODULOS.puntaje:activar(contexto)
			elseif MODULOS.puntaje.startLevel then
				-- Compatibilidad con ScoreTracker actual
				local puntosConexion = configuracionNivel.Puntuacion and configuracionNivel.Puntuacion.PuntosConexion or 50
				local penaFallo = configuracionNivel.Puntuacion and configuracionNivel.Puntuacion.PenaFallo or 10
				MODULOS.puntaje:startLevel(jugador, idNivel, puntosConexion, penaFallo)
			end
			print("[OrquestadorGameplay]   ✓ Puntaje iniciado")
		end
		
		-- 2. Zonas (misiones y guias dependen de esto)
		if MODULOS.zonas then
			-- Construir array de zonas si hay configuracion
			local zonasArray = {}
			if configuracionNivel and configuracionNivel.Zonas then
				for nombre, cfg in pairs(configuracionNivel.Zonas) do
					if cfg.Trigger then
						table.insert(zonasArray, { nombre = nombre, trigger = cfg.Trigger })
					end
				end
			end
			
			if MODULOS.zonas.activar then
				contexto.zonasArray = zonasArray
				MODULOS.zonas:activar(contexto)
			elseif MODULOS.zonas.activate then
				MODULOS.zonas.activate(contexto.nivelActual, zonasArray, jugador, configuracionNivel.Zonas)
			end
			print("[OrquestadorGameplay]   ✓ Zonas iniciadas")
		end
		
		-- 3. Misiones (necesitan zonas para saber donde esta el jugador)
		if MODULOS.misiones then
			if MODULOS.misiones.activar then
				MODULOS.misiones:activar(contexto)
			elseif MODULOS.misiones.activate then
				-- MissionService.activate(config, nivelID, player, remotes, scoreTracker, dataService)
				MODULOS.misiones.activate(
					configuracionNivel, 
					idNivel, 
					jugador, 
					carpetaRemotos, 
					MODULOS.puntaje, 
					nil -- DataService se obtiene internamente
				)
			end
			print("[OrquestadorGameplay]   ✓ Misiones iniciadas")
		end
		
		-- 4. Cables (necesitan misiones para reportar progreso)
		if MODULOS.cables then
			local adjacencias = configuracionNivel and configuracionNivel.Adyacencias or nil
			
			if MODULOS.cables.activar then
				contexto.adjacencias = adjacencias
				MODULOS.cables:activar(contexto)
			elseif MODULOS.cables.activate then
				MODULOS.cables.activate(
					contexto.nivelActual, 
					adjacencias, 
					jugador, 
					MODULOS.puntaje, 
					MODULOS.misiones
				)
			end
			print("[OrquestadorGameplay]   ✓ Cables iniciados")
		end
	end)
	
	if not exito then
		warn("[OrquestadorGameplay] ❌ Error al iniciar nivel:", errorMsg)
		self.activo = false
		return false
	end
	
	print("[OrquestadorGameplay] ✅ Gameplay activo - Todos los modulos iniciados")
	return true
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- DETENER NIVEL: Llamado UNA VEZ cuando el jugador sale del nivel
-- ═══════════════════════════════════════════════════════════════════════════════
function OrquestadorGameplay:detenerNivel()
	if not self.activo then
		print("[OrquestadorGameplay] ⏹️ No hay nivel activo para detener")
		return
	end
	
	print("[OrquestadorGameplay] ⏹️ DETENER NIVEL")
	
	-- ORDEN INVERSO de limpieza (lo ultimo que se inicia, primero se cierra)
	local exito, errorMsg = pcall(function()
		-- 1. Cables primero (deja de detectar input inmediatamente)
		if MODULOS.cables then
			if MODULOS.cables.desactivar then
				MODULOS.cables.desactivar()
			elseif MODULOS.cables.deactivate then
				MODULOS.cables.deactivate()
			end
			print("[OrquestadorGameplay]   ✓ Cables detenidos")
		end
		
		-- 2. Misiones
		if MODULOS.misiones then
			if MODULOS.misiones.desactivar then
				MODULOS.misiones.desactivar()
			elseif MODULOS.misiones.deactivate then
				MODULOS.misiones.deactivate()
			end
			print("[OrquestadorGameplay]   ✓ Misiones detenidas")
		end
		
		-- 3. Zonas
		if MODULOS.zonas then
			if MODULOS.zonas.desactivar then
				MODULOS.zonas.desactivar()
			elseif MODULOS.zonas.deactivate then
				MODULOS.zonas.deactivate()
			end
			print("[OrquestadorGameplay]   ✓ Zonas detenidas")
		end
		
		-- 4. Puntaje al final (puede guardar datos)
		if MODULOS.puntaje then
			if MODULOS.puntaje.desactivar then
				MODULOS.puntaje.desactivar()
			elseif MODULOS.puntaje.reset then
				MODULOS.puntaje.reset(self.jugadorActual)
			end
			print("[OrquestadorGameplay]   ✓ Puntaje detenido")
		end
	end)
	
	if not exito then
		warn("[OrquestadorGameplay] ⚠️ Error durante limpieza:", errorMsg)
	end
	
	-- Limpiar estado
	self.activo = false
	self.jugadorActual = nil
	self.idNivelActual = nil
	
	print("[OrquestadorGameplay] ⬛ Gameplay detenido completamente")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONSULTAS
-- ═══════════════════════════════════════════════════════════════════════════════
function OrquestadorGameplay:estaActivo()
	return self.activo
end

function OrquestadorGameplay:obtenerJugadorActual()
	return self.jugadorActual
end

function OrquestadorGameplay:obtenerNivelActual()
	return self.idNivelActual
end

return OrquestadorGameplay
