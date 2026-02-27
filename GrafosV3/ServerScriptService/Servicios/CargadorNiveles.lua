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
local GestorZonas = nil
local ServicioProgreso = nil

-- Cargar ServicioPuntaje directamente (workaround para problema de caché de Studio)
local ServicioPuntaje = nil
local function cargarServicioPuntajeDirecto()
	local exito, resultado = pcall(function()
		-- Intentar cargar directamente desde la ruta conocida
		return require(ServerScriptService.SistemasGameplay.ServicioPuntaje)
	end)
	if exito then
		return resultado
	else
		warn("[CargadorNiveles] No se pudo cargar ServicioPuntaje directamente:", resultado)
		return nil
	end
end

-- Cargar ServicioProgreso
local function obtenerServicioProgreso()
	if not ServicioProgreso then
		local exito, resultado = pcall(function()
			return require(script.Parent.ServicioProgreso)
		end)
		if exito then
			ServicioProgreso = resultado
		else
			warn("[CargadorNiveles] Error al cargar ServicioProgreso:", resultado)
		end
	end
	return ServicioProgreso
end

-- Cache de modulos
local function obtenerConectarCables()
	if not ConectarCables then
		local sistemasFolder = ServerScriptService:FindFirstChild("SistemasGameplay")
		if not sistemasFolder then return nil end
		local modulo = sistemasFolder:FindFirstChild("ConectarCables")
		if modulo then ConectarCables = require(modulo) end
	end
	return ConectarCables
end

local function obtenerServicioMisiones()
	if not ServicioMisiones then
		local sistemasFolder = ServerScriptService:FindFirstChild("SistemasGameplay")
		if not sistemasFolder then return nil end
		local modulo = sistemasFolder:FindFirstChild("ServicioMisiones")
		if modulo then ServicioMisiones = require(modulo) end
	end
	return ServicioMisiones
end

local function obtenerServicioPuntaje()
	if not ServicioPuntaje then
		local sistemasFolder = ServerScriptService:FindFirstChild("SistemasGameplay")
		if not sistemasFolder then 
			warn("[CargadorNiveles] obtenerServicioPuntaje: No se encontro SistemasGameplay")
			return nil 
		end
		local modulo = sistemasFolder:FindFirstChild("ServicioPuntaje")
		if modulo then
			local exito, resultado = pcall(function()
				return require(modulo)
			end)
			if exito then
				ServicioPuntaje = resultado
				print("[CargadorNiveles] ServicioPuntaje cargado correctamente")
			else
				warn("[CargadorNiveles] Error al cargar ServicioPuntaje:", resultado)
			end
		else
			warn("[CargadorNiveles] No se encontro el modulo ServicioPuntaje en SistemasGameplay")
		end
	end
	return ServicioPuntaje
end

local function obtenerGestorZonas()
	if not GestorZonas then
		local sistemasFolder = ServerScriptService:FindFirstChild("SistemasGameplay")
		if not sistemasFolder then return nil end
		local modulo = sistemasFolder:FindFirstChild("GestorZonas")
		if modulo then GestorZonas = require(modulo) end
	end
	return GestorZonas
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
	
	local moduloMisiones = obtenerServicioMisiones()
	if moduloMisiones and moduloMisiones.estaActivo() then
		moduloMisiones.desactivar()
		print("[CargadorNiveles] ServicioMisiones desactivado")
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
	print("[CargadorNiveles] moduloPuntaje:", moduloPuntaje and "OK" or "NIL")
	
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
		print("[CargadorNiveles] ServicioPuntaje iniciado correctamente")
	else
		warn("[CargadorNiveles] ServicioPuntaje no se pudo cargar!")
	end
	
	-- 2. Inicializar ServicioMisiones
	local moduloMisiones = obtenerServicioMisiones()
	local moduloProgreso = obtenerServicioProgreso()
	print("[CargadorNiveles] moduloMisiones:", moduloMisiones and "OK" or "NIL")
	print("[CargadorNiveles] moduloProgreso:", moduloProgreso and "OK" or "NIL")
	
	if moduloMisiones then
		moduloMisiones.activar(config, nivelID, jugador, Remotos, moduloPuntaje, moduloProgreso)
		print("[CargadorNiveles] ServicioMisiones activado con moduloPuntaje:", moduloPuntaje and "OK" or "NIL", "moduloProgreso:", moduloProgreso and "OK" or "NIL")
	end
	
	-- 3. Inicializar GestorZonas si hay zonas configuradas
	local moduloZonas = obtenerGestorZonas()
	if moduloZonas and config.Zonas and next(config.Zonas) then
		moduloZonas.activar(nivelActual, config.Zonas, jugador, moduloMisiones)
	end
	
	-- 4. Activar ConectarCables si hay adyacencias configuradas
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
			
			local callbacks = {
				onCableCreado = function(nomA, nomB)
					print(string.format("[CargadorNiveles.Callback] Cable creado: %s | %s", nomA, nomB))
					print(string.format("[CargadorNiveles.Callback] misionesRef=%s puntajeRef=%s", tostring(misionesRef), tostring(puntajeRef)))
					if misionesRef and misionesRef.estaActivo() then
						print("[CargadorNiveles.Callback] -> Notificando a ServicioMisiones")
						misionesRef.alCrearCable(nomA, nomB)
					else
						print("[CargadorNiveles.Callback] -> ServicioMisiones no activo")
					end
					if puntajeRef then
						print("[CargadorNiveles.Callback] -> Notificando a ServicioPuntaje")
						puntajeRef:registrarConexion(jugadorRef)
					end
				end,
				onCableEliminado = function(nomA, nomB)
					print(string.format("[CargadorNiveles.Callback] Cable eliminado: %s | %s", nomA, nomB))
					if misionesRef and misionesRef.estaActivo() then
						misionesRef.alEliminarCable(nomA, nomB)
					end
					if puntajeRef then
						puntajeRef:registrarDesconexion(jugadorRef)
					end
				end,
				onNodoSeleccionado = function(nomNodo)
					print(string.format("[CargadorNiveles.Callback] Nodo seleccionado: %s", nomNodo))
					if misionesRef and misionesRef.estaActivo() then
						misionesRef.alSeleccionarNodo(nomNodo)
					end
				end,
				onFalloConexion = function()
					print("[CargadorNiveles.Callback] Fallo de conexion")
					if puntajeRef then
						puntajeRef:registrarFallo(jugadorRef)
					end
				end
			}
			
			moduloCables.activar(nivelActual, adyacencias, jugador, nivelID, callbacks)
			sistemasActivados = true
			print("[CargadorNiveles] ConectarCables activado")
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

return CargadorNiveles
