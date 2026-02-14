-- ================================================================
-- EventManager.lua
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

	eventoUpdateUI = Remotes:FindFirstChild("ActualizarUI")
	eventoInventario = Remotes:FindFirstChild("ActualizarInventario")
	eventoMision = Remotes:FindFirstChild("ActualizarMision")

	print("✅ EventManager: Inicializado")
end

--- Conecta todos los listeners de eventos
function EventManager:init()
	self:_connectUIUpdates()
	self:_connectInventory()
	self:_connectMissions()

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

--- Maneja reset de nivel
function EventManager:_onLevelReset()
	print("🔄 EventManager: Reset recibido")

	-- Resetear estado visual
	MissionsManager:resetAll()

	-- Cerrar mapa si está abierto
	if state.mapaActivo then
		MapManager:disable()
	end

	-- Limpiar atributos de postes
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Model") and obj:GetAttribute("Energizado") then
			obj:SetAttribute("Energizado", nil)
		end
	end
end

--- Maneja actualización de energía
function EventManager:_onEnergyUpdate(data)
	local energizedNodes = data.EnergizedNodes or {}

	-- Buscar nivel actual
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