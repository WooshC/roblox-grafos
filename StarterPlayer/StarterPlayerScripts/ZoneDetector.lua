-- StarterPlayerScripts/ZoneDetector.client.lua
-- Detecta en qué zona está el jugador pisando plataformas
-- Estructura esperada: Zonas > Zonas_juego > Zona_Estacion_1, Zona_Estacion_2, etc.
-- Cada Zona_Estacion_X debe tener al menos un BasePart hijo que actúe como plataforma

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Estado
local currentZone = nil  -- "Zona_Estacion_1", nil, etc.
local zoneOverlapCount = {} -- { [zonaID] = number } para manejar múltiples parts por zona

-- Eventos
local Remotes = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes")

-- Evento para notificar al server (y a la GUI)
local zoneChangedEvent = Remotes:FindFirstChild("ZoneChanged")
if not zoneChangedEvent then
	-- Si no existe, lo creamos (aunque idealmente Init.server.lua lo crea)
	warn("⚠️ ZoneDetector: ZoneChanged RemoteEvent no encontrado, esperando...")
	zoneChangedEvent = Remotes:WaitForChild("ZoneChanged", 10)
end

-- Evento local para la GUI (BindableEvent)
local Bindables = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Bindables")
local localZoneChanged = Bindables:FindFirstChild("LocalZoneChanged")
if not localZoneChanged then
	localZoneChanged = Instance.new("BindableEvent")
	localZoneChanged.Name = "LocalZoneChanged"
	localZoneChanged.Parent = Bindables
end

-- ============================================
-- LÓGICA DE DETECCIÓN
-- ============================================

local function getZoneIDFromPart(part)
	-- Subir en la jerarquía hasta encontrar Zona_Estacion_X
	local current = part
	while current do
		if current.Name:match("^Zona_Estacion_%d+$") then
			return current.Name
		end
		-- También aceptar nombres personalizados que estén dentro de Zonas_juego
		if current.Parent and current.Parent.Name == "Zonas_juego" then
			return current.Name
		end
		current = current.Parent
	end
	return nil
end

local function setCurrentZone(newZone)
	if newZone == currentZone then return end

	local oldZone = currentZone
	currentZone = newZone

	print("🗺️ Zona: " .. (oldZone or "ninguna") .. " → " .. (newZone or "ninguna"))

	-- Notificar al servidor
	if zoneChangedEvent then
		zoneChangedEvent:FireServer(newZone)
	end

	-- Notificar a la GUI local
	if localZoneChanged then
		localZoneChanged:Fire(newZone, oldZone)
	end

	-- Atributo en el jugador (para que otros scripts puedan leerlo)
	player:SetAttribute("CurrentZone", newZone or "")
end

local function onTouched(hit, zonaID)
	-- Verificar que es nuestro personaje
	local humanoid = hit.Parent and hit.Parent:FindFirstChild("Humanoid")
	if not humanoid then return end
	if hit.Parent ~= character then return end

	zoneOverlapCount[zonaID] = (zoneOverlapCount[zonaID] or 0) + 1
	setCurrentZone(zonaID)
end

local function onTouchEnded(hit, zonaID)
	local humanoid = hit.Parent and hit.Parent:FindFirstChild("Humanoid")
	if not humanoid then return end
	if hit.Parent ~= character then return end

	zoneOverlapCount[zonaID] = math.max(0, (zoneOverlapCount[zonaID] or 0) - 1)

	-- Si ya no tocamos ninguna part de esta zona
	if zoneOverlapCount[zonaID] <= 0 then
		zoneOverlapCount[zonaID] = 0

		-- ¿Seguimos en alguna otra zona?
		if currentZone == zonaID then
			local stillInAnyZone = false
			for otherZone, count in pairs(zoneOverlapCount) do
				if count > 0 then
					setCurrentZone(otherZone)
					stillInAnyZone = true
					break
				end
			end
			if not stillInAnyZone then
				setCurrentZone(nil)
			end
		end
	end
end

-- ============================================
-- BUSCAR Y CONECTAR PLATAFORMAS
-- ============================================

local function setupZoneDetection()
	-- Buscar la carpeta de zonas
	local nivel = workspace:FindFirstChild("Nivel0") -- Ajustar según tu estructura
	if not nivel then
		-- Buscar en toda la jerarquía
		for _, child in ipairs(workspace:GetDescendants()) do
			if child.Name == "Zonas_juego" and child:IsA("Folder") then
				nivel = child.Parent
				break
			end
		end
	end

	if not nivel then
		warn("⚠️ ZoneDetector: No se encontró el nivel con Zonas_juego")
		return
	end

	local zonasFolder = nil

	-- Buscar Zonas > Zonas_juego o Zonas_juego directamente
	local zonas = nivel:FindFirstChild("Zonas")
	if zonas then
		zonasFolder = zonas:FindFirstChild("Zonas_juego")
	end

	if not zonasFolder then
		-- Buscar directamente
		zonasFolder = nivel:FindFirstChild("Zonas_juego")
	end

	if not zonasFolder then
		-- Buscar en descendants
		for _, desc in ipairs(nivel:GetDescendants()) do
			if desc.Name == "Zonas_juego" and (desc:IsA("Folder") or desc:IsA("Model")) then
				zonasFolder = desc
				break
			end
		end
	end

	if not zonasFolder then
		warn("⚠️ ZoneDetector: No se encontró Zonas_juego")
		return
	end

	print("🗺️ ZoneDetector: Encontrado " .. zonasFolder:GetFullName())

	-- Conectar cada zona
	local zonasConectadas = 0
	for _, zona in ipairs(zonasFolder:GetChildren()) do
		local zonaID = zona.Name -- "Zona_Estacion_1", etc.

		-- Conectar todos los BaseParts dentro de esta zona
		local partsConectados = 0
		for _, desc in ipairs(zona:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc.Touched:Connect(function(hit)
					onTouched(hit, zonaID)
				end)
				desc.TouchEnded:Connect(function(hit)
					onTouchEnded(hit, zonaID)
				end)
				partsConectados = partsConectados + 1
			end
		end

		-- Si la zona misma es un BasePart
		if zona:IsA("BasePart") then
			zona.Touched:Connect(function(hit)
				onTouched(hit, zonaID)
			end)
			zona.TouchEnded:Connect(function(hit)
				onTouchEnded(hit, zonaID)
			end)
			partsConectados = partsConectados + 1
		end

		if partsConectados > 0 then
			zonasConectadas = zonasConectadas + 1
			print("   ✅ " .. zonaID .. " (" .. partsConectados .. " parts)")
		else
			warn("   ⚠️ " .. zonaID .. " no tiene BaseParts para detección")
		end

		zoneOverlapCount[zonaID] = 0
	end

	print("🗺️ ZoneDetector: " .. zonasConectadas .. " zonas conectadas")
end

-- ============================================
-- MANEJAR RESPAWN
-- ============================================

local function onCharacterAdded(char)
	character = char
	currentZone = nil
	zoneOverlapCount = {}
	player:SetAttribute("CurrentZone", "")

	-- Esperar a que el personaje cargue
	char:WaitForChild("HumanoidRootPart", 10)
	task.wait(0.5)

	setupZoneDetection()
end

-- Conectar
player.CharacterAdded:Connect(onCharacterAdded)

-- Setup inicial
if character and character:FindFirstChild("HumanoidRootPart") then
	task.wait(1) -- Esperar a que el nivel cargue
	setupZoneDetection()
end

-- También re-setup cuando se carga un nivel nuevo
local levelLoaded = Bindables:FindFirstChild("LevelLoaded")
if levelLoaded then
	levelLoaded.Event:Connect(function()
		task.wait(1)
		currentZone = nil
		zoneOverlapCount = {}
		setupZoneDetection()
	end)
end

print("✅ ZoneDetector inicializado")