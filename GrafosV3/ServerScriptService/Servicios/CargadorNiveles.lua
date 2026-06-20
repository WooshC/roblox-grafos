-- ServerScriptService/Servicios/CargadorNiveles.lua
-- Carga y descarga modelos de nivel en el Workspace.
-- Adaptado de GrafosV2 a la arquitectura V3.

local CargadorNiveles = {}

local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local Replicado = game:GetService("ReplicatedStorage")
local Jugadores = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Configuracion de niveles
local LevelsConfig = require(Replicado:WaitForChild("Config"):WaitForChild("LevelsConfig"))

-- ValidadorConexiones se carga inmediatamente (CargadorNiveles es dueño de su ciclo de vida)
local ValidadorConexiones = require(ServerScriptService.SistemasGameplay.ValidadorConexiones)
local GrafoHelpers = require(Replicado:WaitForChild("Compartido"):WaitForChild("GrafoHelpers"))
local Utilidades = require(Replicado:WaitForChild("Compartido"):WaitForChild("Utilidades"))
local Constantes = require(Replicado:WaitForChild("Config"):WaitForChild("Constantes"))

-- Sistemas de gameplay (se cargan bajo demanda)
local ConectarCables = nil
local ServicioMisiones = nil
local GestorZonas = nil
local ServicioProgreso = nil
local ServicioEnergia = nil
local ServicioLogros = nil

-- Cargar ServicioPuntaje directamente (workaround para problema de caché de Studio)
local ServicioPuntaje = nil

-- Factory de lazy-loading para sistemas de gameplay
local function _cargarSistema(cacheRef, nombreModulo, carpeta)
	carpeta = carpeta or ServerScriptService:FindFirstChild("SistemasGameplay")
	if not carpeta then return nil end
	if not cacheRef then
		local modulo = carpeta:FindFirstChild(nombreModulo)
		if modulo then
			cacheRef = Utilidades.safeRequire(modulo, nombreModulo)
		end
	end
	return cacheRef
end

local function obtenerServicioProgreso()
	if not ServicioProgreso then
		ServicioProgreso = Utilidades.safeRequire(script.Parent.ServicioProgreso, "ServicioProgreso")
	end
	return ServicioProgreso
end

local function obtenerConectarCables()
	ConectarCables = _cargarSistema(ConectarCables, "ConectarCables")
	return ConectarCables
end

local function obtenerServicioMisiones()
	ServicioMisiones = _cargarSistema(ServicioMisiones, "ServicioMisiones")
	return ServicioMisiones
end

local function obtenerServicioEnergia()
	ServicioEnergia = _cargarSistema(ServicioEnergia, "ServicioEnergia")
	return ServicioEnergia
end

local function obtenerServicioLogros()
	ServicioLogros = _cargarSistema(ServicioLogros, "ServicioLogros")
	return ServicioLogros
end

local function obtenerServicioPuntaje()
	ServicioPuntaje = _cargarSistema(ServicioPuntaje, "ServicioPuntaje")
	if ServicioPuntaje then
		print("[CargadorNiveles] ServicioPuntaje cargado correctamente")
	end
	return ServicioPuntaje
end

local function obtenerGestorZonas()
	GestorZonas = _cargarSistema(GestorZonas, "GestorZonas")
	return GestorZonas
end

-- Eventos
local Eventos = Replicado:WaitForChild("EventosGrafosV3")
local Remotos = Eventos:WaitForChild("Remotos")
local nivelListoEvento = Remotos:WaitForChild("NivelListo")

local NOMBRE_NIVEL_ACTUAL = "NivelActual"
local _jugadorActual = nil
local _nivelIDActual = nil
local _spawnCFrameActual = nil
local _connRespawn = nil

-- ═══════════════════════════════════════════════════════════════════════════════
-- DESCARGAR NIVEL ACTUAL
-- ═══════════════════════════════════════════════════════════════════════════════
function CargadorNiveles.descargar()
	-- Desactivar sistemas de gameplay primero (en orden inverso)
	local moduloZonas = obtenerGestorZonas()
	if moduloZonas and moduloZonas.estaActivo() then
		moduloZonas.desactivar()
		print("[CargadorNiveles] GestorZonas desactivado")
	end

	local moduloCables = obtenerConectarCables()
	if moduloCables and moduloCables.estaActivo() then
		moduloCables.desactivar()
		print("[CargadorNiveles] ConectarCables desactivado")
	end

	-- Limpiar ValidadorConexiones explícitamente (fuente de verdad del estado de conexiones)
	ValidadorConexiones.limpiar()

	local moduloMisiones = obtenerServicioMisiones()
	if moduloMisiones and moduloMisiones.estaActivo() then
		moduloMisiones.desactivar()
		print("[CargadorNiveles] ServicioMisiones desactivado")
	end
	
	local moduloEnergia = obtenerServicioEnergia()
	if moduloEnergia then
		moduloEnergia.desactivar()
		print("[CargadorNiveles] ServicioEnergia desactivado")
	end

	local moduloPuntaje = obtenerServicioPuntaje()
	if moduloPuntaje and _jugadorActual then
		moduloPuntaje:reiniciar(_jugadorActual)
		print("[CargadorNiveles] ServicioPuntaje reiniciado")
	end

	local existente = Workspace:FindFirstChild(NOMBRE_NIVEL_ACTUAL)
	if existente then
		existente:Destroy()
		print("[CargadorNiveles] Nivel anterior descargado")
	end

	-- Destruir personajes de todos los jugadores
	for _, jugador in ipairs(Jugadores:GetPlayers()) do
		if jugador.Character then
			jugador.Character:Destroy()
		end
	end

	-- Desconectar respawn listener
	if _connRespawn then
		_connRespawn:Disconnect()
		_connRespawn = nil
	end
	_spawnCFrameActual = nil
	_jugadorActual = nil
	_nivelIDActual = nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CARGAR NIVEL
-- ═══════════════════════════════════════════════════════════════════════════════
function CargadorNiveles.cargar(nivelID, jugador)
	local config = LevelsConfig[nivelID]
	if not config then
		warn("[CargadorNiveles] NivelID no existe en config:", nivelID)
		return false
	end

	-- Guardar referencias
	_jugadorActual = jugador
	_nivelIDActual = nivelID

	-- Descargar nivel anterior
	CargadorNiveles.descargar()

	-- Buscar modelo
	local nombreModelo = config.Modelo
	local modeloFuente = nil

	-- 1. Buscar en ServerStorage/Niveles
	local ssNiveles = ServerStorage:FindFirstChild("Niveles")
	if ssNiveles then
		modeloFuente = ssNiveles:FindFirstChild(nombreModelo)
	end

	-- 2. Buscar en cualquier lugar de ServerStorage
	if not modeloFuente then
		modeloFuente = ServerStorage:FindFirstChild(nombreModelo, true)
	end

	-- 3. Fallback: buscar en Workspace (para pruebas)
	if not modeloFuente then
		modeloFuente = Workspace:FindFirstChild(nombreModelo)
	end

	if not modeloFuente then
		warn("[CargadorNiveles] Modelo no encontrado:", nombreModelo)
		nivelListoEvento:FireClient(jugador, {
			nivelID = nivelID,
			error = "Modelo '" .. nombreModelo .. "' no encontrado en ServerStorage"
		})
		return false
	end

	-- Clonar modelo
	local nivelActual = modeloFuente:Clone()
	nivelActual.Name = NOMBRE_NIVEL_ACTUAL
	nivelActual.Parent = Workspace

	print("[CargadorNiveles] Nivel cargado:", config.Nombre, "(ID:", nivelID, ")")

	-- Aplicar configuración de entorno/iluminación
	local Lighting = game:GetService("Lighting")
	if config.ConfiguracionEntorno then
		Lighting.ClockTime = config.ConfiguracionEntorno.Reloj or 14
		Lighting.Ambient = config.ConfiguracionEntorno.IluminacionAmbiental or Constantes.ILUMINACION_DEFAULT
		Lighting.OutdoorAmbient = config.ConfiguracionEntorno.IluminacionExteriores or Constantes.ILUMINACION_DEFAULT
	else
		Lighting.ClockTime = Constantes.HORA_DIA_DEFAULT
		Lighting.Ambient = Constantes.ILUMINACION_DEFAULT
		Lighting.OutdoorAmbient = Constantes.ILUMINACION_DEFAULT
	end


	-- Cargar personaje y teleportar
	if jugador then
		jugador:SetAttribute("CurrentLevelID", nivelID)
		CargadorNiveles.cargarPersonaje(jugador, nivelActual)
	end

	-- ═══════════════════════════════════════════════════════════════════════════
	-- INICIALIZAR SISTEMAS DE GAMEPLAY
	-- ═══════════════════════════════════════════════════════════════════════════

	-- 1. Inicializar ServicioPuntaje
	local moduloPuntaje = obtenerServicioPuntaje()

	if moduloPuntaje then
		local eventoActualizarPuntaje = Remotos:FindFirstChild("ActualizarPuntuacion")
		if moduloPuntaje.init then
			moduloPuntaje:init(eventoActualizarPuntaje)
		end

		local puntuacion = config.Puntuacion or {}
		moduloPuntaje:iniciarNivel(
			jugador, 
			nivelID, 
			puntuacion.PuntosConexion or 50, 
			puntuacion.PenaFallo or 10
		)

		-- Inicializar presupuesto si el nivel lo define
		if config.Presupuesto and config.Presupuesto.Inicial then
			moduloPuntaje:iniciarPresupuesto(jugador, config.Presupuesto.Inicial)
			print("[CargadorNiveles] Presupuesto inicial cargado:", config.Presupuesto.Inicial)
		end
	else
		warn("[CargadorNiveles] ServicioPuntaje no se pudo cargar!")
	end

	-- 2. Inicializar ServicioMisiones
	local moduloMisiones = obtenerServicioMisiones()
	local moduloProgreso = obtenerServicioProgreso()

	if moduloMisiones then
		moduloMisiones.activar(config, nivelID, jugador, Remotos, moduloPuntaje, moduloProgreso)
	end

	-- 3. Inicializar GestorZonas si hay zonas configuradas
	local moduloZonas = obtenerGestorZonas()
	if moduloZonas and config.Zonas and next(config.Zonas) then
		moduloZonas.activar(nivelActual, config.Zonas, jugador, moduloMisiones)
	end
	
	-- 3.5 Inicializar ServicioEnergia
	local moduloEnergia = obtenerServicioEnergia()
	if moduloEnergia then
		moduloEnergia.activar(config, nivelID, Remotos)
	end

	-- 4. Configurar ValidadorConexiones (fuente de verdad — antes de ConectarCables)
	ValidadorConexiones.configurar({
		Adyacencias = config.Adyacencias,
		nivelID     = nivelID,
	})

	-- 5. Activar ConectarCables si hay adyacencias configuradas
	local moduloCables = obtenerConectarCables()
	local sistemasActivados = false

	if moduloCables then
		local adyacencias = config.Adyacencias
		if adyacencias and next(adyacencias) then
			-- Preparar callbacks para notificar a los servicios
			-- CAPTURAR moduloMisiones y moduloPuntaje en locals para los closures
			local misionesRef = moduloMisiones
			local puntajeRef = moduloPuntaje
			local jugadorRef = jugador

			local logrosRef = obtenerServicioLogros()

			local callbacks = {
				onCableCreado = function(nomA, nomB)
					-- PRIMERO registrar en puntaje (para que el conteo esté actualizado)
					if puntajeRef then
						puntajeRef:registrarConexion(jugadorRef)
					end
					-- Registrar en logros
					if logrosRef and logrosRef.registrarCableConectado then
						logrosRef.registrarCableConectado(jugadorRef)
					end
					-- LUEGO verificar misiones (puede disparar victoria)
					if misionesRef and misionesRef.estaActivo() then
						misionesRef.alCrearCable(nomA, nomB)
					end
				end,
				onCableEliminado = function(nomA, nomB)
					-- PRIMERO registrar en puntaje
					if puntajeRef then
						puntajeRef:registrarDesconexion(jugadorRef)
					end
					-- Reembolsar costo de la arista si el nivel usa presupuesto
					local peso = GrafoHelpers.obtenerPeso(nivelID, nomA, nomB, 0)
					if peso > 0 and puntajeRef then
						local costoTotal = GrafoHelpers.calcularCosto(peso, (LevelsConfig[nivelID] or {}).CostoPorMetro)
						if costoTotal > 0 then
							puntajeRef:reembolsar(jugadorRef, costoTotal)
						end
					end
					-- LUEGO verificar misiones
					if misionesRef and misionesRef.estaActivo() then
						misionesRef.alEliminarCable(nomA, nomB)
					end
				end,
				onNodoSeleccionado = function(nomNodo)
					if misionesRef and misionesRef.estaActivo() then
						misionesRef.alSeleccionarNodo(nomNodo)
					end
				end,
				onFalloConexion = function()
					if puntajeRef then
						puntajeRef:registrarFallo(jugadorRef)
					end
					-- Registrar fallo en logros
					if logrosRef and logrosRef.registrarFallo then
						logrosRef.registrarFallo(jugadorRef)
					end
				end,
				onNodoReparado = function(nombreNodo, costo)
					if costo and costo > 0 and puntajeRef then
						local ok = puntajeRef:gastar(jugadorRef, costo)
						if not ok then
							return false -- Bloquear reparacion: no hay dinero suficiente
						end
					end
					-- Notificar a misiones si implementan reparaciones en el futuro
					if misionesRef and misionesRef.alRepararNodo then
						misionesRef.alRepararNodo(nombreNodo)
					end
					return true
				end,
				onNodoSobrecargado = function(nombreNodo)
					if misionesRef and misionesRef.alSobrecargarNodo then
						misionesRef.alSobrecargarNodo(nombreNodo)
					end
				end,
				onAntesCrearCable = function(nomA, nomB, peso)
					if peso and peso > 0 and puntajeRef then
						local costoTotal = GrafoHelpers.calcularCosto(peso, (LevelsConfig[nivelID] or {}).CostoPorMetro)
						if costoTotal > 0 then
							local ok = puntajeRef:gastar(jugadorRef, costoTotal)
							if not ok then
								return false -- Bloquear conexion: no hay dinero suficiente
							end
						end
					end
					return true
				end,
			}

			moduloCables.activar(nivelActual, adyacencias, jugador, nivelID, callbacks)
			sistemasActivados = true
		end
	end

	-- Notificar al cliente
	nivelListoEvento:FireClient(jugador, {
		nivelID = nivelID,
		nombre = config.Nombre,
		algoritmo = config.Algoritmo,
		sistemasActivados = sistemasActivados
	})

	return true
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CARGAR PERSONAJE Y TELEPORTAR
-- ═══════════════════════════════════════════════════════════════════════════════
function CargadorNiveles.cargarPersonaje(jugador, nivelActual)
	local spawnLoc = nivelActual:FindFirstChildOfClass("SpawnLocation", true)

	if spawnLoc then
		spawnLoc.Enabled = false
	else
		warn("[CargadorNiveles] No hay SpawnLocation en el nivel")
	end

	local exito, errorMsg = pcall(function()
		if jugador.Character then
			jugador.Character:Destroy()
			task.wait(0.1)
		end

		Jugadores.CharacterAutoLoads = true
		jugador:LoadCharacter()
		Jugadores.CharacterAutoLoads = false

		local personaje
		local tiempo = 0
		repeat
			task.wait(0.05)
			tiempo = tiempo + 0.05
			personaje = jugador.Character
		until personaje or tiempo >= 8

		if not personaje then
			warn("[CargadorNiveles] Personaje no cargo en 8s:", jugador.Name)
			return
		end

		if spawnLoc then
			_spawnCFrameActual = spawnLoc.CFrame * CFrame.new(0, 5, 0)
			local hrp = personaje:WaitForChild("HumanoidRootPart", 8)
			if hrp then
				hrp.CFrame = _spawnCFrameActual
				print("[CargadorNiveles] Jugador teleportado al nivel")
				
				-- Añadir luz al jugador si la configuración lo pide
				local nivelIDActual = jugador:GetAttribute("CurrentLevelID")
				local cfg = LevelsConfig[nivelIDActual]
				if cfg and cfg.ConfiguracionEntorno and cfg.ConfiguracionEntorno.LinternaJugador then
					local linterna = Instance.new("PointLight")
					linterna.Name = "LuzJugadorNoche"
					linterna.Brightness = 1.2
					linterna.Range = 25
					linterna.Color = Color3.fromRGB(255, 230, 200)
					linterna.Shadows = false -- Apagado para evitar bugs visuales pegados al jugador
					linterna.Parent = hrp
				end
			end
		end
		
		-- Conectar respawn automático al morir (CharacterAutoLoads = false)
		local humanoid = personaje:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Died:Connect(function()
				task.wait(3)
				if jugador and jugador.Parent then
					jugador:LoadCharacter()
				end
			end)
		end

			-- Teleportar al spawn cada vez que el personaje reaparece (respawn por muerte)
			if _connRespawn then
				_connRespawn:Disconnect()
			end
			_connRespawn = jugador.CharacterAdded:Connect(function(nuevoPersonaje)
				if not _spawnCFrameActual then return end
				task.wait(0.1)
				local nuevoHRP = nuevoPersonaje:WaitForChild("HumanoidRootPart", 3)
				if nuevoHRP then
					nuevoHRP.CFrame = _spawnCFrameActual
					print("[CargadorNiveles] Jugador respawneado y teleportado al nivel")
				end
			end)
	end)

	if not exito then
		warn("[CargadorNiveles] Error al cargar personaje:", errorMsg)
	end
end

return CargadorNiveles
