-- GrafosV3 - Boot.server.lua
-- Punto de entrada UNICO del servidor.
-- Responsabilidad: Iniciar el sistema y gestionar el ciclo de vida del jugador.
-- 
-- REGLA DE ORO: Mientras el menu esta activo, TODO lo relacionado al gameplay
-- esta completamente desconectado.
--
-- Principio: Separacion estricta entre "Sistema de Menu" y "Sistema de Gameplay".
-- Nunca deben coexistir activos.

local Servidores = game:GetService("ServerScriptService")
local Jugadores = game:GetService("Players")
local Replicado = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- Configuracion: Sin spawn automatico (el menu no necesita personaje)
Jugadores.CharacterAutoLoads = false

print("[GrafosV3] === Boot Servidor Iniciando ===")

-- ═══════════════════════════════════════════════════════════════════════════════
-- 1. ESPERAR EVENTOS (creados por EventRegistry.server.lua)
-- ═══════════════════════════════════════════════════════════════════════════════
local Eventos = Replicado:WaitForChild("EventosGrafosV3", 15)
if not Eventos then
	error("[GrafosV3] CRITICO: EventosGrafosV3 no encontrado. Asegurate de que EventRegistry.server.lua este en ServerScriptService/Nucleo/")
end

local Remotos = Eventos:WaitForChild("Remotos", 10)
if not Remotos then
	error("[GrafosV3] CRITICO: EventosGrafosV3/Remotos no encontrado")
end

print("[GrafosV3] Eventos conectados correctamente")

-- ═══════════════════════════════════════════════════════════════════════════════
-- 2. CARGAR SERVICIOS CORE
-- ═══════════════════════════════════════════════════════════════════════════════
local ServicioProgreso = nil
local CargadorNiveles = nil

local function cargarServicios()
	local carpetaServicios = script.Parent.Parent:WaitForChild("Servicios")
	
	-- Cargar ServicioProgreso
	local moduloProgreso = carpetaServicios:FindFirstChild("ServicioProgreso")
	if moduloProgreso then
		local exito, resultado = pcall(function()
			return require(moduloProgreso)
		end)
		if exito then
			ServicioProgreso = resultado
			print("[GrafosV3] ServicioProgreso cargado")
		else
			warn("[GrafosV3] Error en ServicioProgreso:", resultado)
		end
	end
	
	-- Cargar CargadorNiveles
	local moduloCargador = carpetaServicios:FindFirstChild("CargadorNiveles")
	if moduloCargador then
		local exito, resultado = pcall(function()
			return require(moduloCargador)
		end)
		if exito then
			CargadorNiveles = resultado
			print("[GrafosV3] CargadorNiveles cargado")
		else
			warn("[GrafosV3] Error en CargadorNiveles:", resultado)
		end
	end
end

cargarServicios()

-- ═══════════════════════════════════════════════════════════════════════════════
-- 3. FUNCIONES DE GUI
-- ═══════════════════════════════════════════════════════════════════════════════
local function copiarGuiAJugador(jugador)
	print("[GrafosV3] Copiando GUI para", jugador.Name)
	
	-- Con CharacterAutoLoads=false, PlayerGui NO se crea automaticamente
	local playerGui = jugador:FindFirstChild("PlayerGui")
	if not playerGui then
		playerGui = Instance.new("PlayerGui")
		playerGui.Name = "PlayerGui"
		playerGui.Parent = jugador
		print("[GrafosV3] PlayerGui creado para", jugador.Name)
	end
	
	local copiadas = 0
	for _, gui in ipairs(StarterGui:GetChildren()) do
		if gui:IsA("ScreenGui") and not playerGui:FindFirstChild(gui.Name) then
			local clone = gui:Clone()
			clone.Parent = playerGui
			copiadas = copiadas + 1
			print("[GrafosV3]   GUI copiada:", gui.Name)
		end
	end
	
	if copiadas == 0 then
		warn("[GrafosV3] No se copio ninguna GUI. StarterGui tiene las GUI?")
	else
		print("[GrafosV3] Total GUI copiadas:", copiadas)
	end
	
	return copiadas > 0
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 4. JUGADOR CONECTADO
-- ═══════════════════════════════════════════════════════════════════════════════
local function alJugadorConectado(jugador)
	print("[GrafosV3] Jugador conectado:", jugador.Name)
	
	-- 1. Copiar GUI inmediatamente (menu state)
	task.spawn(function()
		copiarGuiAJugador(jugador)
	end)
	
	-- 2. Cargar datos del jugador
	task.spawn(function()
		if ServicioProgreso and ServicioProgreso.cargar then
			ServicioProgreso.cargar(jugador)
		end
	end)
	
	-- 3. Notificar al cliente (menu listo)
	task.delay(2, function()
		if jugador and jugador.Parent then
			local servidorListo = Remotos:FindFirstChild("ServidorListo")
			if servidorListo then
				servidorListo:FireClient(jugador)
				print("[GrafosV3] ServidorListo enviado a", jugador.Name)
			end
		end
	end)
end

Jugadores.PlayerAdded:Connect(alJugadorConectado)

-- Para jugadores ya conectados (Play Solo)
for _, jugador in ipairs(Jugadores:GetPlayers()) do
	copiarGuiAJugador(jugador)
	alJugadorConectado(jugador)
end

-- Jugador desconectado
Jugadores.PlayerRemoving:Connect(function(jugador)
	if ServicioProgreso and ServicioProgreso.alJugadorSalir then
		ServicioProgreso.alJugadorSalir(jugador)
	end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 5. HANDLERS DE EVENTOS (Menu System)
-- ═══════════════════════════════════════════════════════════════════════════════

-- ObtenerProgresoJugador: El menu solicita datos del jugador
local obtenerProgreso = Remotos:WaitForChild("ObtenerProgresoJugador")
obtenerProgreso.OnServerInvoke = function(jugador)
	print("[GrafosV3] ObtenerProgresoJugador solicitado por", jugador.Name)
	
	if ServicioProgreso and ServicioProgreso.obtenerProgresoParaCliente then
		return ServicioProgreso.obtenerProgresoParaCliente(jugador)
	end
	
	-- Fallback: construir desde LevelsConfig
	local LevelsConfig = require(Replicado:WaitForChild("Config"):WaitForChild("LevelsConfig"))
	local resultado = {}
	
	for i = 0, 4 do
		local config = LevelsConfig[i] or {}
		local status = (i == 0) and "disponible" or "bloqueado"
		
		resultado[tostring(i)] = {
			nivelID = i,
			nombre = config.Nombre or ("Nivel " .. i),
			descripcion = config.DescripcionCorta or "",
			imageId = config.ImageId or "",
			tag = config.Tag or ("NIVEL " .. i),
			algoritmo = config.Algoritmo,
			seccion = config.Seccion or "NIVELES",
			conceptos = config.Conceptos or {},
			status = status,
			estrellas = 0,
			highScore = 0,
			aciertos = 0,
			fallos = 0,
			tiempoMejor = 0,
			intentos = 0
		}
	end
	
	return resultado
end

-- IniciarNivel: El jugador quiere jugar un nivel
local iniciarNivel = Remotos:WaitForChild("IniciarNivel")
iniciarNivel.OnServerEvent:Connect(function(jugador, idNivel)
	print("[GrafosV3] IniciarNivel - Jugador:", jugador.Name, "Nivel:", idNivel)
	
	-- Transicion de Menu -> Gameplay
	if CargadorNiveles then
		CargadorNiveles.cargar(idNivel, jugador)
	else
		warn("[GrafosV3] CargadorNiveles no disponible")
		local nivelListo = Remotos:WaitForChild("NivelListo")
		nivelListo:FireClient(jugador, {
			nivelID = idNivel,
			error = "Servidor no listo para cargar niveles"
		})
	end
end)

-- VolverAlMenu: El jugador quiere volver al menu
local volverAlMenu = Remotos:WaitForChild("VolverAlMenu")
volverAlMenu.OnServerEvent:Connect(function(jugador)
	print("[GrafosV3] VolverAlMenu - Jugador:", jugador.Name)
	
	-- Transicion de Gameplay -> Menu
	if CargadorNiveles then
		CargadorNiveles.descargar()
	end
	
	-- Destruir personaje del jugador
	if jugador.Character then
		jugador.Character:Destroy()
	end
	
	local nivelDescargado = Remotos:WaitForChild("NivelDescargado")
	nivelDescargado:FireClient(jugador)
end)

-- ReiniciarNivel: El jugador quiere reiniciar el nivel actual
local reiniciarNivel = Remotos:WaitForChild("ReiniciarNivel")
reiniciarNivel.OnServerEvent:Connect(function(jugador, nivelID)
	print("[GrafosV3] ReiniciarNivel - Jugador:", jugador.Name, "Nivel:", nivelID)
	
	-- Volver a cargar el mismo nivel
	if CargadorNiveles then
		-- Descargar primero
		CargadorNiveles.descargar()
		task.wait(0.5)
		
		-- Volver a cargar
		CargadorNiveles.cargar(nivelID, jugador)
	end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 6. SISTEMA DE GAMEPLAY (Desconectado inicialmente)
-- ═══════════════════════════════════════════════════════════════════════════════
-- NOTA: Todos los sistemas de gameplay se inicializan bajo demanda
-- cuando se inicia un nivel, y se destruyen al volver al menu.

local SistemaGameplay = {
	activo = false,
	nivelActual = nil,
	jugadoresEnNivel = {},
}

function SistemaGameplay.iniciar(nivelID, jugador)
	if SistemaGameplay.activo then
		warn("[GrafosV3] SistemaGameplay ya esta activo")
		return
	end
	
	print("[GrafosV3] Iniciando sistema de gameplay - Nivel:", nivelID)
	SistemaGameplay.activo = true
	SistemaGameplay.nivelActual = nivelID
	SistemaGameplay.jugadoresEnNivel[jugador.UserId] = true
	
	-- AQUI: Inicializar todos los sistemas de gameplay:
	-- - MissionService
	-- - ScoreTracker
	-- - ZoneTriggerManager
	-- - ConectarCables
	-- - VisualEffectsManager
	-- etc.
end

function SistemaGameplay.terminar(jugador)
	if not SistemaGameplay.activo then
		return
	end
	
	SistemaGameplay.jugadoresEnNivel[jugador.UserId] = nil
	
	-- Si no quedan jugadores, terminar completamente
	local quedanJugadores = false
	for _, _ in pairs(SistemaGameplay.jugadoresEnNivel) do
		quedanJugadores = true
		break
	end
	
	if not quedanJugadores then
		print("[GrafosV3] Terminando sistema de gameplay")
		SistemaGameplay.activo = false
		SistemaGameplay.nivelActual = nil
		
		-- AQUI: Destruir todos los sistemas de gameplay
	end
end

print("[GrafosV3] === Boot Servidor Listo ===")
print("[GrafosV3] Estado: Menu activo, Gameplay desconectado")
