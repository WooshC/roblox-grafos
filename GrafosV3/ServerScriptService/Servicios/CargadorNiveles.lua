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
local function obtenerConectarCables()
	if not ConectarCables then
		local sistemasFolder = ServerScriptService:WaitForChild("SistemasGameplay")
		local modulo = sistemasFolder:WaitForChild("ConectarCables")
		ConectarCables = require(modulo)
	end
	return ConectarCables
end

-- Eventos
local Eventos = Replicado:WaitForChild("EventosGrafosV3")
local Remotos = Eventos:WaitForChild("Remotos")
local nivelListoEvento = Remotos:WaitForChild("NivelListo")

local NOMBRE_NIVEL_ACTUAL = "NivelActual"

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
	
	-- Activar sistemas de gameplay
	local sistemasActivados = false
	
	-- Activar ConectarCables si hay adyacencias configuradas
	local moduloCables = obtenerConectarCables()
	if moduloCables then
		local adyacencias = config.Adyacencias
		if adyacencias and next(adyacencias) then
			moduloCables.activar(nivelActual, adyacencias, jugador, nivelID)
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

return CargadorNiveles
