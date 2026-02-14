-- DoorScript MEJORADO (VERSIÓN FINAL)
-- Ahora usa EnergyService en lugar de atributos
-- Esto asegura sincronización perfecta con el sistema de energía

local PrimaryPart = script.Parent.Parent.PrimaryPart
local open = false
local Door = script.Parent.Parent
local Proximity = script.Parent:WaitForChild("ProximityPrompt")
local OpenSound = script.Parent.Sounds.Open
local CloseSound = script.Parent.Sounds.Close

OpenSound.Parent = Door
CloseSound.Parent = Door
Proximity.Parent = Door 

-- ============================================
-- CONFIGURACIÓN DE BLOQUEO POR ENERGÍA
-- ============================================
local NODO_REQUERIDO = "toma_corriente"
local NIVEL_ID = 0

-- ============================================
-- FUNCIÓN MEJORADA: Usa EnergyService
-- ============================================

local function tieneEnergia()
	-- Obtener servicios
	local LevelService = _G.Services and _G.Services.Level
	local EnergyService = _G.Services and _G.Services.Energy

	if not LevelService or not EnergyService then
		print("⚠️ [Puerta] Servicios no disponibles en _G")
		return false
	end

	-- Verificar que hay un nivel cargado
	if not LevelService:isLevelLoaded() then
		return false
	end

	-- Obtener nodo de inicio (generador)
	local startNode = LevelService:getStartNode()
	if not startNode then
		return false
	end

	-- Obtener nodos energizados
	local energizados = EnergyService:calculateEnergy(startNode)

	-- Verificar si el nodo requerido está energizado
	local tieneEnergia = energizados[NODO_REQUERIDO] == true

	if tieneEnergia then
		-- print("✅ [Puerta] " .. NODO_REQUERIDO .. " tiene energía")
	else
		-- print("❌ [Puerta] " .. NODO_REQUERIDO .. " NO tiene energía")
	end

	return tieneEnergia
end

-- ============================================
-- FUNCIÓN: Actualizar estado del ProximityPrompt
-- ============================================

local function actualizarProximityPrompt()
	if tieneEnergia() then
		-- Tiene energía: permitir interacción
		Proximity.Enabled = true
		Proximity.ActionText = open and "Close" or "Open"
		Proximity.ObjectText = "Puerta"
	else
		-- No tiene energía: bloquear interacción
		Proximity.Enabled = false
		Proximity.ActionText = "🔒 Sin energía"
		Proximity.ObjectText = "Puerta bloqueada"
	end
end

-- ============================================
-- INICIALIZAR
-- ============================================

print("✅ DoorScript cargado - Esperando nivel...")

-- Esperar a que el nivel esté cargado
task.wait(2)
actualizarProximityPrompt()

-- ============================================
-- MONITOREAR CAMBIOS DE ENERGÍA
-- ============================================

-- Opción A: Monitoreo periódico (más simple)
task.spawn(function()
	while true do
		task.wait(0.5)  -- Revisar cada medio segundo
		actualizarProximityPrompt()
	end
end)

-- Opción B: Escuchar cambios en GraphService (más eficiente)
task.spawn(function()
	task.wait(1)
	local GraphService = _G.Services and _G.Services.Graph
	if GraphService then
		GraphService:onConnectionChanged(function(action, nodeA, nodeB)
			-- Cuando cambia una conexión, actualizar el estado
			actualizarProximityPrompt()
		end)
		print("✅ [Puerta] Escuchando cambios de conexión")
	end
end)

-- ============================================
-- LÓGICA DE APERTURA/CIERRE
-- ============================================

Proximity.Triggered:Connect(function(player)
	-- ⚡ VERIFICACIÓN DE ENERGÍA (Antes de abrir)
	if not tieneEnergia() then
		print("⚠️ [Puerta] Intento de abrir sin energía por " .. player.Name)

		-- Feedback al jugador
		if AudioService then
			AudioService:playError()
		end

		return  -- No hacer nada si no hay energía
	end

	print("✅ [Puerta] Abierta por " .. player.Name)

	-- ============================================
	-- LÓGICA ORIGINAL DE APERTURA/CIERRE
	-- ============================================

	if open == false then
		-- ABRIR
		open = true
		OpenSound:Play()
		Proximity.ActionText = "Close"

		for i = 1, 20 do 
			Proximity.MaxActivationDistance = 0
			script.Parent.Parent:SetPrimaryPartCFrame(PrimaryPart.CFrame * CFrame.Angles(0, math.rad(5), 0))
			task.wait()
			Proximity.MaxActivationDistance = 10
		end

	else
		-- CERRAR
		open = false
		CloseSound:Play()
		Proximity.ActionText = "Open"

		for i = 1, 20 do
			Proximity.MaxActivationDistance = 0
			script.Parent.Parent:SetPrimaryPartCFrame(PrimaryPart.CFrame * CFrame.Angles(0, math.rad(-5), 0))
			task.wait()
			Proximity.MaxActivationDistance = 10
		end
	end

	-- Actualizar estado del prompt después de abrir/cerrar
	actualizarProximityPrompt()
end)

-- ============================================
-- SEGURIDAD: Cerrar puerta al cargar nivel
-- ============================================

task.spawn(function()
	task.wait(1)
	local LevelService = _G.Services and _G.Services.Level
	if LevelService then
		LevelService:onLevelLoaded(function(nivelID)
			open = false
			actualizarProximityPrompt()
			print("✅ [Puerta] Cerrada al cargar nivel " .. nivelID)
		end)
	end
end)

print("✅ DoorScript MEJORADO listo - Usando EnergyService")