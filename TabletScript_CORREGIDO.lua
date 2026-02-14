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
local ID_OBJETO = "Tablet"
local NOMBRE_OBJETO = "Manual BFS"
local NIVEL_ID = 0 

-- === ESTADO ===
local activo = true
local debounce = false

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
end

-- === LÓGICA DE RECOLECCIÓN (TOQUE) ===
local function alTocar(hit)
	if not activo or debounce then return end

	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)

	if player then
		debounce = true
		print("🎒 " .. player.Name .. " tocó y recogió: " .. ID_OBJETO)
		
		InventoryService:addItem(player, ID_OBJETO)

		-- Efecto de sonido
		local sonido = Instance.new("Sound")
		sonido.SoundId = "rbxassetid://12221967"
		sonido.Parent = character.Head
		sonido:Play()
		game.Debris:AddItem(sonido, 1)

		ocultarObjeto()
	end
end

-- Conectar evento Touched
if objeto:IsA("Model") then
	for _, child in ipairs(objeto:GetDescendants()) do
		if child:IsA("BasePart") then
			child.Touched:Connect(alTocar)
		end
	end
elseif objeto:IsA("BasePart") then
	objeto.Touched:Connect(alTocar)
end

-- === NUEVA ESTRUCTURA DE EVENTOS (FIX) ===
local eventsFolder = ReplicatedStorage:WaitForChild("Events", 10)
if eventsFolder then
	local bindables = eventsFolder:WaitForChild("Bindables", 10)
	local eventoRestaurar = bindables and bindables:WaitForChild("RestaurarObjetos", 10)
	
	if eventoRestaurar then
		eventoRestaurar.Event:Connect(function(nivelReiniciado)
			if nivelReiniciado == NIVEL_ID then
				mostrarObjeto()
			end
		end)
	end
end

print("✅ Script TABLET (TOQUE) Corregido V3 - Usa InventoryService")
