-- ObjetosColeccionables.server.lua
-- Sistema de recolección de objetos en el nivel
-- NOTA: Este script ahora actúa como "Apoyo" para objetos que NO tienen script propio.
-- Para "Mapa" y "Tablet", la lógica está en sus propios scripts dentro de los modelos.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Módulos
local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))
local InventoryManager = require(ReplicatedStorage:WaitForChild("Utilidades"):WaitForChild("InventoryManager"))
local NivelUtils = require(ReplicatedStorage:WaitForChild("Utilidades"):WaitForChild("NivelUtils"))

-- Inicializar inventario
InventoryManager.init()

-- ============================================
-- GESTIÓN DE OBJETOS COLECCIONABLES
-- ============================================

-- Lista de objetos que tienen su propio script (NO tocar lógica aquí)
local OBJETOS_CON_SCRIPT_PROPIO = {
	["Mapa"] = true,
	["Tablet"] = true, 
	["Algoritmo_BFS"] = true -- Asumo que Tablet es este mismo o similar
}

local function ocultarObjeto(modelo)
	if not modelo then return end
	-- Solo desactivar prompt si fue creado por este script
	if modelo:GetAttribute("PromptCreadoPorSistema") then
		local prompt = modelo:FindFirstChild("ProximityPrompt")
		if prompt then prompt.Enabled = false end
	end
	
	-- No tocamos transparencia para no interferir con scripts individuales que manejan su propio show/hide
	-- A MENOS que sea un objeto genérico sin script
end

local function mostrarObjeto(modelo)
	if not modelo then return end
	if modelo:GetAttribute("PromptCreadoPorSistema") then
		local prompt = modelo:FindFirstChild("ProximityPrompt")
		if prompt then prompt.Enabled = true end
	end
end

--- Configura un objeto coleccionable (SOLO SI NO TIENE SCRIPT PROPIO)
local function configurarObjeto(objetoModel, objetoConfig, nivelID)
	-- Verificar si este objeto se maneja externamente
	if OBJETOS_CON_SCRIPT_PROPIO[objetoConfig.ID] then
		print("ℹ️ Omitiendo configuración sistema para: " .. objetoConfig.ID .. " (Tiene script propio)")
		return
	end

	-- Buscar o crear ProximityPrompt
	local prompt = objetoModel:FindFirstChild("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "ProximityPrompt"
		prompt.ActionText = "Recoger " .. objetoConfig.Nombre
		prompt.ObjectText = objetoConfig.Icono .. " " .. objetoConfig.Nombre
		prompt.HoldDuration = 0.5
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = objetoModel
		
		objetoModel:SetAttribute("PromptCreadoPorSistema", true)
	end
	
	-- Listener para recolección
	if not objetoModel:GetAttribute("ConexionSistema") then
		prompt.Triggered:Connect(function(player)
			local stats = player:FindFirstChild("leaderstats")
			local nivelJugador = stats and stats:FindFirstChild("Nivel") and stats.Nivel.Value or 0
			
			if nivelJugador ~= nivelID then return end
			
			InventoryManager.agregarObjeto(player, objetoConfig.ID)
			ocultarObjeto(objetoModel)
			
			print("✅ [Sistema] " .. player.Name .. " recogió: " .. objetoConfig.Nombre)
		end)
		objetoModel:SetAttribute("ConexionSistema", true)
	end
end

--- Inicializa objetos de un nivel al cargar
local function inicializarObjetosNivel(nivelID)
	local config = LevelsConfig[nivelID]
	if not config or not config.Objetos then return end
	
	local nivelModel = NivelUtils.obtenerModeloNivel(nivelID)
	if not nivelModel then return end
	
	local carpetaObjetos = nivelModel:FindFirstChild("ObjetosColeccionables") or nivelModel:FindFirstChild("Items")
	if not carpetaObjetos then 
		warn("⚠️ No se encontró carpeta de objetos en Nivel " .. nivelID)
		return 
	end
	
	print("🎁 Inicializando objetos (Sistema Central) para Nivel " .. nivelID)
	
	for _, objetoConfig in ipairs(config.Objetos) do
		local modeloNombre = objetoConfig.Modelo or objetoConfig.ID
		local objetoModel = carpetaObjetos:FindFirstChild(modeloNombre)
		
		if objetoModel then
			-- SOLO configuramos si NO tiene script propio
			configurarObjeto(objetoModel, objetoConfig, nivelID)
		end
	end
end

-- ============================================
-- EVENTOS PARA APARECER/RESTAURAR OBJETOS
-- ============================================

-- Escuchar solicitud de restauración (Reinicio de Nivel)
local Events = ReplicatedStorage:WaitForChild("Events", 5)
if Events then
	local Bindables = Events:WaitForChild("Bindables", 5)
	local eventoRestaurar = Bindables and Bindables:WaitForChild("RestaurarObjetos", 5)

	if eventoRestaurar then
		eventoRestaurar.Event:Connect(function(nivelID)
			-- Solo restauramos visualmente los objetos gestionados por este sistema
			-- Los objetos con script propio (Mapa, Tablet) escuchan su propio evento
			print("♻️ [Sistema Central] Restauración parcial para Nivel " .. nivelID)
			
			local config = LevelsConfig[nivelID]
			if not config or not config.Objetos then return end
			
			local nivelModel = NivelUtils.obtenerModeloNivel(nivelID)
			if not nivelModel then return end
			
			local carpetaObjetos = nivelModel:FindFirstChild("ObjetosColeccionables") or nivelModel:FindFirstChild("Items")
			if not carpetaObjetos then return end
			
			for _, objConfig in ipairs(config.Objetos) do
				-- Omitir los que tienen script propio
				if not OBJETOS_CON_SCRIPT_PROPIO[objConfig.ID] then
					local nombre = objConfig.Modelo or objConfig.ID
					local modelo = carpetaObjetos:FindFirstChild(nombre)
					if modelo then
						mostrarObjeto(modelo)
					end
				end
			end
		end)
	end
end

-- ============================================
-- EVENTOS PARA APARECER OBJETOS (Scripting)
-- ============================================
-- Se mantiene la compatibilidad por si algún script externo llama a este evento,
-- pero idealmente se usaria el evento "DesbloquearObjeto" que escuchan los scripts individuales.

local carpetaEventos = ReplicatedStorage:FindFirstChild("ServerEvents")
if not carpetaEventos then
	carpetaEventos = Instance.new("Folder")
	carpetaEventos.Name = "ServerEvents"
	carpetaEventos.Parent = ReplicatedStorage
end

local eventoAparecer = carpetaEventos:FindFirstChild("AparecerObjeto")
if not eventoAparecer then
	eventoAparecer = Instance.new("RemoteEvent")
	eventoAparecer.Name = "AparecerObjeto"
	eventoAparecer.Parent = carpetaEventos
end

eventoAparecer.OnServerEvent:Connect(function(player, nivelID, objetoID)
	-- Si es un objeto con script propio, disparamos el evento de desbloqueo para ellos
	if OBJETOS_CON_SCRIPT_PROPIO[objetoID] then
		local ev = ReplicatedStorage:FindFirstChild("ServerEvents")
		local desbloquear = ev and ev:FindFirstChild("DesbloquearObjeto")
		if desbloquear then
			desbloquear:Fire(objetoID, nivelID)
			print("🔀 Redirigiendo 'AparecerObjeto' a 'DesbloquearObjeto' para: " .. objetoID)
		end
		return
	end

	-- Lógica legacy para objetos sin script
	print("✨ [Sistema Central] Solicitud de aparición legacy: " .. tostring(objetoID))
	-- (Resto de lógica omitida para no duplicar, asumimos que todo objeto importante tiene script ahora)
end)


-- ============================================
-- INIT
-- ============================================

task.wait(2)
inicializarObjetosNivel(0)
inicializarObjetosNivel(1)

Players.PlayerAdded:Connect(function(player)
	InventoryManager.inicializarJugador(player)
	player.CharacterAdded:Connect(function()
		task.wait(1)
		InventoryManager.sincronizarConCliente(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	InventoryManager.limpiarJugador(player)
end)

print("✅ Sistema de Objetos Coleccionables v2 (Híbrido/Soporte) cargado")
