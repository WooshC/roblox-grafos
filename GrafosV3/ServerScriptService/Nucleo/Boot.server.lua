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
	local carpetaEventos = Replicado:FindFirstChild("Events")
	if not carpetaEventos then
		carpetaEventos = Instance.new("Folder")
		carpetaEventos.Name = "Events"
		carpetaEventos.Parent = Replicado
	end
	
	local remotes = carpetaEventos:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = carpetaEventos
	end
	
	-- Eventos necesarios para el menu y progreso
	local eventosNecesarios = {
		"ServerReady",           -- Servidor listo para recibir al jugador
		"GetPlayerProgress",     -- Obtener progreso del jugador (RemoteFunction)
		"RequestPlayLevel",      -- Solicitar jugar un nivel
		"LevelReady",            -- Nivel cargado y listo
		"LevelUnloaded",         -- Nivel descargado, volver al menu
		"ReturnToMenu",          -- Solicitud de volver al menu
	}
	
	for _, nombre in ipairs(eventosNecesarios) do
		if not remotes:FindFirstChild(nombre) then
			if nombre == "GetPlayerProgress" then
				local rf = Instance.new("RemoteFunction")
				rf.Name = nombre
				rf.Parent = remotes
			else
				local re = Instance.new("RemoteEvent")
				re.Name = nombre
				re.Parent = remotes
			end
			print("[GrafosV3] Evento registrado:", nombre)
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
			print("[GrafosV3] ✅ ServicioDatos cargado")
		else
			warn("[GrafosV3] ❌ Error en ServicioDatos:", resultado)
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
			print("[GrafosV3] ✅ ServicioProgreso cargado")
		else
			warn("[GrafosV3] ❌ Error en ServicioProgreso:", resultado)
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
		warn("[GrafosV3] ⚠️ No se copio ninguna GUI. ¿StarterGui tiene las GUI?")
	else
		print("[GrafosV3] ✅ Total GUI copiadas:", copiadas)
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
		if ServicioDatos and ServicioDatos.cargar then
			ServicioDatos.cargar(jugador)
		end
	end)
	
	-- 3. Notificar al cliente despues de dar tiempo a copiar GUI
	task.delay(2, function()
		if jugador and jugador.Parent then
			local serverReady = Remotes:FindFirstChild("ServerReady")
			if serverReady then
				serverReady:FireClient(jugador)
				print("[GrafosV3] ServerReady enviado a", jugador.Name)
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

-- ═══════════════════════════════════════════════════════════════════════════════
-- 5. HANDLERS DE EVENTOS
-- ═══════════════════════════════════════════════════════════════════════════════

-- GetPlayerProgress: El menu solicita datos del jugador
local getProgress = Remotes:FindFirstChild("GetPlayerProgress")
if getProgress then
	getProgress.OnServerInvoke = function(jugador)
		print("[GrafosV3] GetPlayerProgress solicitado por", jugador.Name)
		
		if ServicioProgreso and ServicioProgreso.obtenerProgreso then
			return ServicioProgreso.obtenerProgreso(jugador)
		end
		
		-- Datos dummy si no hay servicio
		return {
			{
				nivelID = 0,
				nombre = "Laboratorio de Grafos",
				estado = "disponible",
				estrellas = 0,
				puntajeAlto = 0,
				aciertos = 0,
				fallos = 0,
				tiempoMejor = 0,
				intentos = 0
			},
			{
				nivelID = 1,
				nombre = "Estacion Central",
				estado = "bloqueado",
				estrellas = 0,
				puntajeAlto = 0,
				aciertos = 0,
				fallos = 0,
				tiempoMejor = 0,
				intentos = 0
			}
		}
	end
end

-- RequestPlayLevel: El jugador quiere jugar un nivel
local requestPlay = Remotes:FindFirstChild("RequestPlayLevel")
if requestPlay then
	requestPlay.OnServerEvent:Connect(function(jugador, idNivel)
		print("[GrafosV3] RequestPlayLevel - Jugador:", jugador.Name, "Nivel:", idNivel)
		
		-- AQUI: Logica de carga de nivel (por ahora solo notificar)
		local levelReady = Remotes:FindFirstChild("LevelReady")
		if levelReady then
			levelReady:FireClient(jugador, {
				nivelID = idNivel,
				nombre = "Nivel " .. idNivel,
				estado = "cargado"
			})
		end
	end)
end

-- ReturnToMenu: El jugador quiere volver al menu
local returnToMenu = Remotes:FindFirstChild("ReturnToMenu")
if returnToMenu then
	returnToMenu.OnServerEvent:Connect(function(jugador)
		print("[GrafosV3] ReturnToMenu - Jugador:", jugador.Name)
		
		local levelUnloaded = Remotes:FindFirstChild("LevelUnloaded")
		if levelUnloaded then
			levelUnloaded:FireClient(jugador)
		end
	end)
end

print("[GrafosV3] === Boot Servidor Listo ===")
