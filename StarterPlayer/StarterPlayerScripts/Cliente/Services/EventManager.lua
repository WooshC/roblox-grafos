-- ================================================================
-- EventManager.lua (ACTUALIZADO CON SOPORTE DE ZONAS)
-- Conecta listeners a eventos remotos del servidor
-- ================================================================

local EventManager = {}
EventManager.__index = EventManager

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Dependencias
local MapManager = nil
local MissionsManager = nil
local player = Players.LocalPlayer

-- Estado
local state = nil

-- Referencias a eventos remotos
local eventoUpdateUI = nil
local eventoInventario = nil
local eventoMision = nil
local eventoZone = nil  -- 🔥 NUEVO

-- ================================================================
-- INICIALIZACIÓN
-- ================================================================

--- Inyecta dependencias
function EventManager.initialize(globalState, deps)
	state = globalState
	MapManager = deps.MapManager
	MissionsManager = deps.MissionsManager

	-- Obtener referencias a eventos
	local Events = ReplicatedStorage:WaitForChild("Events", 5)
	local Remotes = Events:WaitForChild("Remotes", 5)
	local Bindables = Events:WaitForChild("Bindables", 5)

	eventoUpdateUI = Remotes:FindFirstChild("ActualizarUI")
	eventoInventario = Remotes:FindFirstChild("ActualizarInventario")
	eventoMision = Remotes:FindFirstChild("ActualizarMision")
	eventoZone = Remotes:FindFirstChild("ZoneChanged")  -- 🔥 NUEVO

	-- 🔥 NUEVO: Listener local de zona (desde ZoneDetector)
	local localZoneChanged = Bindables:FindFirstChild("LocalZoneChanged")
	if localZoneChanged then
		localZoneChanged.Event:Connect(function(newZone, oldZone)
			EventManager:_onZoneChanged(newZone, oldZone)
		end)
		print("✅ EventManager: Conectado a LocalZoneChanged")
	end

	print("✅ EventManager: Inicializado con soporte de zonas")
end

--- Conecta todos los listeners de eventos
function EventManager:init()
	self:_connectUIUpdates()
	self:_connectInventory()
	self:_connectMissions()
	-- _onZoneChanged ya está conectado en initialize

	print("✅ EventManager: Listeners conectados")
end

--- Conecta listener de actualizaciones de UI
function EventManager:_connectUIUpdates()
	if not eventoUpdateUI then
		warn("⚠️ EventManager: Evento ActualizarUI no encontrado")
		return
	end

	eventoUpdateUI.OnClientEvent:Connect(function(data)
		if not data or not data.Type then return end

		if data.Type == "LevelReset" then
			self:_onLevelReset()
		elseif data.Type == "Energy" then
			self:_onEnergyUpdate(data)
		elseif data.Type == "Algorithm" then
			self:_onAlgorithmEvent(data)
		end
	end)
end

--- Conecta listener de inventario
function EventManager:_connectInventory()
	if not eventoInventario then
		warn("⚠️ EventManager: Evento ActualizarInventario no encontrado")
		return
	end

	eventoInventario.OnClientEvent:Connect(function(objetoID, tiene)
		if objetoID == "Mapa" then
			state.tieneMapa = tiene
		elseif objetoID == "Tablet" or objetoID == "Algoritmo_BFS" or objetoID == "Algoritmo_Dijkstra" then
			state.tieneAlgo = tiene
		end

		print("🎒 Inventario: " .. objetoID .. " = " .. tostring(tiene))
	end)
end

--- Conecta listener de misiones
function EventManager:_connectMissions()
	if not eventoMision then
		warn("⚠️ EventManager: Evento ActualizarMision no encontrado")
		return
	end

	eventoMision.OnClientEvent:Connect(function(indice, completada)
		MissionsManager:updateMissionStatus(indice, completada)
		print("🎯 Misión actualizada: " .. indice .. " = " .. tostring(completada))
	end)
end

-- ================================================================
-- 🔥 NUEVO: MANEJO DE CAMBIOS DE ZONA
-- ================================================================

--- Maneja cambio de zona del jugador
function EventManager:_onZoneChanged(newZone, oldZone)
	print("🗺️ EventManager: Cambio de zona detectado")
	print("   Anterior: " .. tostring(oldZone))
	print("   Nueva: " .. tostring(newZone))
	
	-- Actualizar MissionsManager con la nueva zona
	if MissionsManager then
		MissionsManager:setZone(newZone)
	end
	
	-- Si el panel de misiones está visible, refrescar
	-- (MissionsManager ya lo maneja internamente, pero podríamos
	-- hacer efectos visuales adicionales aquí si queremos)
end

-- ================================================================
-- EVENTOS EXISTENTES (SIN CAMBIOS)
-- ================================================================

--- Maneja reset de nivel
function EventManager:_onLevelReset()
	print("🔄 EventManager: Reset recibido")

	MissionsManager:resetAll()

	if state.mapaActivo then
		MapManager:disable()
	end

	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Model") and obj:GetAttribute("Energizado") then
			obj:SetAttribute("Energizado", nil)
		end
	end
end

--- Maneja actualización de energía
function EventManager:_onEnergyUpdate(data)
	local energizedNodes = data.EnergizedNodes or {}

	local nivelID = player:GetAttribute("CurrentLevelID") or 0
	local nivelModel = workspace:FindFirstChild("NivelActual")
	if not nivelModel then
		nivelModel = workspace:FindFirstChild("Nivel" .. nivelID)
	end

	if nivelModel and nivelModel:FindFirstChild("Objetos") then
		local postes = nivelModel.Objetos:FindFirstChild("Postes")
		if postes then
			for _, poste in ipairs(postes:GetChildren()) do
				poste:SetAttribute("Energizado", energizedNodes[poste.Name] and true or nil)
			end
		end
	end
end

--- Maneja eventos de algoritmo
function EventManager:_onAlgorithmEvent(data)
	local algo = data.Algoritmo
	local estado = data.Estado

	if estado == "started" then
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "Algoritmo",
			Text = "Ejecutando " .. algo .. "...",
			Duration = 3,
		})
	elseif estado == "completed" then
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "Algoritmo",
			Text = algo .. " finalizado.",
			Duration = 3,
		})
	end
end

return EventManager