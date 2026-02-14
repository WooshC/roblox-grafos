local objeto = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Esperar Inicialización de Servicios
local function waitForService(serviceName)
	local function getService()
		return _G.Services and _G.Services[serviceName]
	end
	
	local service = getService()
	while not service do
		task.wait(0.5)
		service = getService()
	end
	return service
end

local InventoryService = waitForService("Inventory")

-- === CONFIGURACIÓN MANUAL ===
local ID_OBJETO = "Mapa"
local NOMBRE_OBJETO = "Mapa del Pueblo"
local NIVEL_ID = 0 -- Pertenece al Tutorial

-- === ESTADO INICIAL ===
local activo = false 
local debounce = false
local historiaCompletada = false 

-- === FUNCIONES VISIBILIDAD ===
local function ocultarObjeto()
	activo = false
	if objeto:IsA("Model") then
		for _, part in ipairs(objeto:GetDescendants()) do
			if part:IsA("BasePart") or part:IsA("Decal") then
				if not part:GetAttribute("OriginalTransparency") then
					part:SetAttribute("OriginalTransparency", part.Transparency)
				end
				part.Transparency = 1
				if part:IsA("BasePart") then 
					part.CanCollide = false 
					part.CanTouch = false
				end
			end
		end
	end
end

local function mostrarObjeto()
	activo = true
	debounce = false 
	if objeto:IsA("Model") then
		for _, part in ipairs(objeto:GetDescendants()) do
			if part:IsA("BasePart") or part:IsA("Decal") then
				part.Transparency = part:GetAttribute("OriginalTransparency") or 0
				if part:IsA("BasePart") then 
					part.CanCollide = true 
					part.CanTouch = true
				end
			end
		end
	end
	print("🗺️ MAPA APARECIDO - Listo para recoger")
end

-- Ocultar al inicio
ocultarObjeto()

-- === LÓGICA DE RECOLECCIÓN (TOQUE) ===
local function alTocar(hit)
	if not activo or debounce then return end

	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)

	if player then
		debounce = true
		print("🎒 " .. player.Name .. " tocó y recogió: " .. ID_OBJETO)
		
		InventoryService:addItem(player, ID_OBJETO)

		local sonido = Instance.new("Sound")
		sonido.SoundId = "rbxassetid://12221967"
		sonido.Parent = character.Head
		sonido:Play()
		game.Debris:AddItem(sonido, 1)

		activo = false
		ocultarObjeto()
	end
end

if objeto:IsA("Model") then
	for _, child in ipairs(objeto:GetDescendants()) do
		if child:IsA("BasePart") then
			child.Touched:Connect(alTocar)
		end
	end
elseif objeto:IsA("BasePart") then
	objeto.Touched:Connect(alTocar)
end

-- === NUEVA ESTRUCTURA DE EVENTOS ===
-- Buscamos en ReplicatedStorage/Events/Bindables
local eventsFolder = ReplicatedStorage:WaitForChild("Events", 10)
if eventsFolder then
	local bindables = eventsFolder:WaitForChild("Bindables", 10)
	
	if bindables then
		-- 1. ESCUCHAR DESBLOQUEO (Desde Diálogo)
		local eventoDesbloquear = bindables:WaitForChild("DesbloquearObjeto", 10)
		if eventoDesbloquear then
			eventoDesbloquear.Event:Connect(function(idSolicitado, nivelSolicitado)
				-- print("🔓 Señal Desbloquear recibida para: " .. tostring(idSolicitado))
				if idSolicitado == ID_OBJETO then
					historiaCompletada = true
					mostrarObjeto()
				end
			end)
		end
		
		-- 2. ESCUCHAR RESTAURACIÓN (Reinicio)
		local eventoRestaurar = bindables:WaitForChild("RestaurarObjetos", 10)
		if eventoRestaurar then
			eventoRestaurar.Event:Connect(function(nivelReiniciado)
				if nivelReiniciado == NIVEL_ID then
					if historiaCompletada then
						mostrarObjeto()
					else
						ocultarObjeto()
					end
				end
			end)
		end
	end
end

print("✅ Script MAPA (TOQUE + ANTI-TRAMPA) Actualizado V3 - Usa InventoryService")
