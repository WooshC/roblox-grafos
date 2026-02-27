-- GrafosV3 - Boot.server.lua
-- Punto de entrada UNICO del servidor.
-- Responsabilidad: Iniciar el sistema y gestionar el ciclo de vida del jugador.

local Servidores = game:GetService("ServerScriptService")
local Jugadores = game:GetService("Players")
local Replicado = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- Configuracion: Sin spawn automatico (el menu no necesita personaje)
Jugadores.CharacterAutoLoads = false

print("[GrafosV3] === Boot Servidor Iniciando ===")

-- ═══════════════════════════════════════════════════════════════════════════════
-- 1. REGISTRO DE EVENTOS (Primero - todos los sistemas lo necesitan)
-- ═══════════════════════════════════════════════════════════════════════════════
local function registrarEventos()
	-- Crear estructura de carpetas
	local carpetaEventos = Replicado:FindFirstChild("EventosGrafosV3")
	if not carpetaEventos then
		carpetaEventos = Instance.new("Folder")
		carpetaEventos.Name = "EventosGrafosV3"
		carpetaEventos.Parent = Replicado
	end
	
	local remotes = carpetaEventos:FindFirstChild("Remotos")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotos"
		remotes.Parent = carpetaEventos
	end
	
	-- Eventos necesarios para el menu y progreso (nombres en español)
	local eventosNecesarios = {
		{ nombre = "ServidorListo", tipo = "RemoteEvent" },
		{ nombre = "ObtenerProgresoJugador", tipo = "RemoteFunction" },
		{ nombre = "IniciarNivel", tipo = "RemoteEvent" },
		{ nombre = "NivelListo", tipo = "RemoteEvent" },
		{ nombre = "NivelDescargado", tipo = "RemoteEvent" },
		{ nombre = "VolverAlMenu", tipo = "RemoteEvent" },
	}
	
	for _, evento in ipairs(eventosNecesarios) do
		local existente = remotes:FindFirstChild(evento.nombre)
		if not existente then
			if evento.tipo == "RemoteFunction" then
				local rf = Instance.new("RemoteFunction")
				rf.Name = evento.nombre
				rf.Parent = remotes
			else
				local re = Instance.new("RemoteEvent")
				re.Name = evento.nombre
				re.Parent = remotes
			end
			print("[GrafosV3] Evento registrado:", evento.nombre)
		end
	end
	
	return remotes
end

local Remotes = registrarEventos()

-- ═══════════════════════════════════════════════════════════════════════════════
-- 2. CARGAR SERVICIOS CORE
-- ═══════════════════════════════════════════════════════════════════════════════
local ServicioDatos = nil
local ServicioProgreso = nil

local function cargarServicios()
	local carpetaServicios = script.Parent.Parent:WaitForChild("Servicios")
	
	-- Cargar ServicioDatos
	local moduloDatos = carpetaServicios:FindFirstChild("ServicioDatos")
	if moduloDatos then
		local exito, resultado = pcall(function()
			return require(moduloDatos)
		end)
		if exito then
			ServicioDatos = resultado
			print("[GrafosV3] ServicioDatos cargado")
		else
			warn("[GrafosV3] Error en ServicioDatos:", resultado)
		end
	end
	
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
	
	-- 1. Copiar GUI inmediatamente
	task.spawn(function()
		copiarGuiAJugador(jugador)
	end)
	
	-- 2. Cargar datos del jugador (si existe servicio)
	task.spawn(function()
		if ServicioProgreso and ServicioProgreso.cargar then
			ServicioProgreso.cargar(jugador)
		end
	end)
	
	-- 3. Notificar al cliente despues de dar tiempo a copiar GUI
	task.delay(2, function()
		if jugador and jugador.Parent then
			local servidorListo = Remotes:FindFirstChild("ServidorListo")
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
-- 5. HANDLERS DE EVENTOS
-- ═══════════════════════════════════════════════════════════════════════════════

-- ObtenerProgresoJugador: El menu solicita datos del jugador (ENRIQUECIDOS)
local obtenerProgreso = Remotes:FindFirstChild("ObtenerProgresoJugador")
if obtenerProgreso then
	obtenerProgreso.OnServerInvoke = function(jugador)
		print("[GrafosV3] ObtenerProgresoJugador solicitado por", jugador.Name)
		
		if ServicioProgreso and ServicioProgreso.obtenerProgresoParaCliente then
			return ServicioProgreso.obtenerProgresoParaCliente(jugador)
		end
		
		-- Fallback: construir desde LevelsConfig (todos los niveles)
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
end

-- IniciarNivel: El jugador quiere jugar un nivel
local iniciarNivel = Remotes:FindFirstChild("IniciarNivel")
if iniciarNivel then
	iniciarNivel.OnServerEvent:Connect(function(jugador, idNivel)
		print("[GrafosV3] IniciarNivel - Jugador:", jugador.Name, "Nivel:", idNivel)
		
		-- AQUI: Logica de carga de nivel (spawn personaje, cargar modelo, etc.)
		-- Por ahora solo notificar al cliente que esta listo
		
		local nivelListo = Remotes:FindFirstChild("NivelListo")
		if nivelListo then
			nivelListo:FireClient(jugador, {
				nivelID = idNivel,
				estado = "cargado"
			})
		end
	end)
end

-- VolverAlMenu: El jugador quiere volver al menu
local volverAlMenu = Remotes:FindFirstChild("VolverAlMenu")
if volverAlMenu then
	volverAlMenu.OnServerEvent:Connect(function(jugador)
		print("[GrafosV3] VolverAlMenu - Jugador:", jugador.Name)
		
		local nivelDescargado = Remotes:FindFirstChild("NivelDescargado")
		if nivelDescargado then
			nivelDescargado:FireClient(jugador)
		end
	end)
end

print("[GrafosV3] === Boot Servidor Listo ===")
