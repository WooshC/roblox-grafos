--Es importante seguir las recomendaciones del video tutorial. Rodrikius12
-- Modificado para requerir energía en toma_corriente

--Variables
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

local NODO_REQUERIDO = "toma_corriente"  -- Nodo que debe tener energía
local NIVEL_ID = 0  -- ID del nivel (0 = Tutorial)

-- Función para verificar si el nodo tiene energía
local function tieneEnergia()
	local carpetaPostes = workspace:FindFirstChild("Nivel0_Tutorial")
	if carpetaPostes then
		carpetaPostes = carpetaPostes:FindFirstChild("Objetos")
		if carpetaPostes then
			carpetaPostes = carpetaPostes:FindFirstChild("Postes")
		end
	end
	
	if not carpetaPostes then
		return false
	end
	
	local nodo = carpetaPostes:FindFirstChild(NODO_REQUERIDO)
	if not nodo then
		return false
	end
	
	-- Verificar atributo Energizado
	local energizado = nodo:GetAttribute("Energizado")
	return energizado == true
end

-- Función para actualizar el estado del ProximityPrompt
local function actualizarProximityPrompt()
	if tieneEnergia() then
		-- Tiene energía: permitir interacción
		Proximity.Enabled = true
		Proximity.ActionText = open and "Close" or "Open"
		Proximity.ObjectText = "Puerta"
	else
		-- No tiene energía: bloquear interacción
		Proximity.Enabled = false
		Proximity.ActionText = "🔒 Requiere energía"
		Proximity.ObjectText = "Puerta bloqueada"
	end
end

-- Inicializar estado
actualizarProximityPrompt()

-- Monitorear cambios de energía
task.spawn(function()
	while true do
		task.wait(1)  -- Verificar cada segundo
		actualizarProximityPrompt()
	end
end)

-- ============================================
-- LÓGICA ORIGINAL DE LA PUERTA
-- ============================================

Proximity.Triggered:Connect(function(Players)
	
	-- ⚡ VERIFICACIÓN DE ENERGÍA
	if not tieneEnergia() then
		warn("⚠️ Puerta bloqueada: " .. NODO_REQUERIDO .. " no tiene energía")
		return  -- No hacer nada si no hay energía
	end
	
	-- Lógica original de apertura/cierre
	if open == false then
		open = true
		OpenSound:Play()
		Proximity.ActionText = "Close"
		for i = 1, 20 do 
			Proximity.MaxActivationDistance = 0
			script.Parent.Parent:SetPrimaryPartCFrame(PrimaryPart.CFrame*CFrame.Angles(0, math.rad(5), 0))
			wait()
			Proximity.MaxActivationDistance = 10
		end
	else
		open = false
		CloseSound:Play()
		Proximity.ActionText = "Open"
		for i = 1, 20 do
			Proximity.MaxActivationDistance = 0
			script.Parent.Parent:SetPrimaryPartCFrame(PrimaryPart.CFrame*CFrame.Angles(0, math.rad(-5), 0))
			wait()
			Proximity.MaxActivationDistance = 10
		end
	end
	
	-- Actualizar estado del prompt después de abrir/cerrar
	actualizarProximityPrompt()
	
end)
