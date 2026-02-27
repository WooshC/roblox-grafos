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

-- Sistemas de gameplay (se cargan bajo demanda)
local ConectarCables = nil
local ServicioMisiones = nil
local ServicioPuntaje = nil

local function obtenerConectarCables()
	if not ConectarCables then
		local sistemasFolder = ServerScriptService:FindFirstChild("SistemasGameplay")
		if not sistemasFolder then return nil end
		local modulo = sistemasFolder:FindFirstChild("ConectarCables")
		if modulo then
			ConectarCables = require(modulo)
		end
	end
	return ConectarCables
end

local function obtenerServicioMisiones()
	if not ServicioMisiones then
		local sistemasFolder = ServerScriptService:FindFirstChild("SistemasGameplay")
		if not sistemasFolder then return nil end
		local modulo = sistemasFolder:FindFirstChild("ServicioMisiones")
		if modulo then
			ServicioMisiones = require(modulo)
		end
	end
	return ServicioMisiones
end

local function obtenerServicioPuntaje()
	if not ServicioPuntaje then
		local sistemasFolder = ServerScriptService:FindFirstChild("SistemasGameplay")
		if not sistemasFolder then return nil end
		local modulo = sistemasFolder:FindFirstChild("ServicioPuntaje")
		if modulo then
			ServicioPuntaje = require(modulo)
		end
	end
	return ServicioPuntaje
end

-- Eventos
local Eventos = Replicado:WaitForChild("EventosGrafosV3")
local Remotos = Eventos:WaitForChild("Remotos")
local nivelListoEvento = Remotos:WaitForChild("NivelListo")

local NOMBRE_NIVEL_ACTUAL = "NivelActual"
local _jugadorActual = nil
local _nivelIDActual = nil

-- ═══════════════════════════════════════════════════════════════════════════════
-- DESCARGAR NIVEL ACTUAL
-- ═══════════════════════════════════════════════════════════════════════════════
function CargadorNiveles.descargar()
	-- Desactivar sistemas de gameplay primero
	local moduloCables = obtenerConectarCables()
	if moduloCables and moduloCables.estaActivo() then
		moduloCables.desactivar()
		print("[CargadorNiveles] ConectarCables desactivado")
	end
	
	-- Desactivar ServicioMisiones
	local moduloMisiones = obtenerServicioMisiones()
	if moduloMisiones and moduloMisiones.estaActivo() then
		moduloMisiones.desactivar()
		print("[CargadorNiveles] ServicioMisiones desactivado")
	end
	
	-- Reiniciar ServicioPuntaje
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
	
	-- Cargar personaje y teleportar
	if jugador then
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
		
		-- Iniciar tracking de puntaje para este nivel
		local puntuacion = config.Puntuacion or {}
		moduloPuntaje:iniciarNivel(
			jugador, 
			nivelID, 
			puntuacion.PuntosConexion or 50, 
			puntuacion.PenaFallo or 10
		)
	end
	
	-- 2. Inicializar ServicioMisiones
	local moduloMisiones = obtenerServicioMisiones()
	if moduloMisiones then
		local servicioDatos = nil  -- Opcional: integrar con ServicioDatos si existe
		
		moduloMisiones.activar(
			config,
			nivelID,
			jugador,
			Remotos,
			moduloPuntaje,
			servicioDatos
		)
	end
	
	-- 3. Activar ConectarCables si hay adyacencias configuradas
	local moduloCables = obtenerConectarCables()
	local sistemasActivados = false
	
	if moduloCables then
		local adyacencias = config.Adyacencias
		if adyacencias and next(adyacencias) then
			moduloCables.activar(nivelActual, adyacencias, jugador, nivelID)
			sistemasActivados = true
			print("[CargadorNiveles] ConectarCables activado")
			
			-- Conectar eventos de ConectarCables a ServicioMisiones
			CargadorNiveles._conectarEventosSistemas(moduloCables, moduloMisiones, moduloPuntaje)
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
-- CONECTAR EVENTOS ENTRE SISTEMAS
-- ═══════════════════════════════════════════════════════════════════════════════
function CargadorNiveles._conectarEventosSistemas(moduloCables, moduloMisiones, moduloPuntaje)
	-- Los eventos ya están conectados dentro de ConectarCables
	-- Pero necesitamos propagarlos a ServicioMisiones y ServicioPuntaje
	
	-- Escuchar eventos remotos para propagar a los servicios
	local notificarEvento = Remotos:FindFirstChild("NotificarSeleccionNodo")
	if notificarEvento then
		-- El evento ya es disparado por ConectarCables
		-- Necesitamos interceptarlo para actualizar misiones y puntaje
		
		-- Crear conexión temporal para escuchar cuando se crean/eliminan cables
		-- Nota: Esto se maneja mediante el sistema de eventos existente
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CARGAR PERSONAJE Y TELEPORTAR
-- ═══════════════════════════════════════════════════════════════════════════════
function CargadorNiveles.cargarPersonaje(jugador, nivelActual)
	local spawnLoc = nivelActual:FindFirstChildOfClass("SpawnLocation", true)
	
	-- Desactivar SpawnLocation para que Roblox no lo use globalmente
	if spawnLoc then
		spawnLoc.Enabled = false
	else
		warn("[CargadorNiveles] No hay SpawnLocation en el nivel")
	end
	
	-- Cargar personaje (con pcall para no bloquear)
	local exito, errorMsg = pcall(function()
		-- Destruir personaje actual
		if jugador.Character then
			jugador.Character:Destroy()
			task.wait(0.1)
		end
		
		-- Habilitar spawn automatico temporalmente
		Jugadores.CharacterAutoLoads = true
		
		-- Cargar nuevo personaje
		jugador:LoadCharacter()
		
		-- Restaurar configuracion
		Jugadores.CharacterAutoLoads = false
		
		-- Esperar personaje
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
		
		-- Teleportar al spawn
		if spawnLoc then
			local hrp = personaje:WaitForChild("HumanoidRootPart", 8)
			if hrp then
				hrp.CFrame = spawnLoc.CFrame * CFrame.new(0, 5, 0)
				print("[CargadorNiveles] Jugador teleportado al nivel")
			end
		end
	end)
	
	if not exito then
		warn("[CargadorNiveles] Error al cargar personaje:", errorMsg)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- NOTIFICACIONES EXTERNAS (llamadas por otros sistemas)
-- ═══════════════════════════════════════════════════════════════════════════════

-- Llamado por ConectarCables cuando se crea un cable
function CargadorNiveles.notificarCableCreado(nomA, nomB)
	local moduloMisiones = obtenerServicioMisiones()
	local moduloPuntaje = obtenerServicioPuntaje()
	
	if moduloMisiones and moduloMisiones.estaActivo() then
		moduloMisiones.alCrearCable(nomA, nomB)
	end
	
	if moduloPuntaje and _jugadorActual then
		moduloPuntaje:registrarConexion(_jugadorActual)
	end
end

-- Llamado por ConectarCables cuando se elimina un cable
function CargadorNiveles.notificarCableEliminado(nomA, nomB)
	local moduloMisiones = obtenerServicioMisiones()
	local moduloPuntaje = obtenerServicioPuntaje()
	
	if moduloMisiones and moduloMisiones.estaActivo() then
		moduloMisiones.alEliminarCable(nomA, nomB)
	end
	
	if moduloPuntaje and _jugadorActual then
		moduloPuntaje:registrarDesconexion(_jugadorActual)
	end
end

-- Llamado por ConectarCables cuando se selecciona un nodo
function CargadorNiveles.notificarNodoSeleccionado(nomNodo)
	local moduloMisiones = obtenerServicioMisiones()
	
	if moduloMisiones and moduloMisiones.estaActivo() then
		moduloMisiones.alSeleccionarNodo(nomNodo)
	end
end

-- Llamado por ConectarCables cuando hay un fallo de conexión
function CargadorNiveles.notificarFalloConexion()
	local moduloPuntaje = obtenerServicioPuntaje()
	
	if moduloPuntaje and _jugadorActual then
		moduloPuntaje:registrarFallo(_jugadorActual)
	end
end

return CargadorNiveles
