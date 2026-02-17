-- StarterPlayer/StarterPlayerScripts/ZoneDetector.client.lua
-- ✅ CORREGIDO: Busca EXCLUSIVAMENTE NivelActual > Zonas > Zonas_juego
-- Detecta en qué zona está el jugador pisando plataformas

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = nil

-- Estado
local currentZone = nil
local zoneOverlapCount = {}
local isSetupActive = false
local setupConnections = {}

-- Eventos
local zoneChangedEvent = nil
local localZoneChanged = nil

-- ============================================
-- INICIALIZAR EVENTOS
-- ============================================

local function initializeEvents()
	local Events = ReplicatedStorage:WaitForChild("Events", 10)
	local Remotes = Events:WaitForChild("Remotes", 10)
	local Bindables = Events:WaitForChild("Bindables", 10)

	-- Solo esperamos que existan
	zoneChangedEvent = Remotes:WaitForChild("ZoneChanged", 10)
	localZoneChanged = Bindables:WaitForChild("LocalZoneChanged", 10)

	if zoneChangedEvent and localZoneChanged then
		print("✅ [ZoneDetector] Eventos inicializados")
	else
		warn("⚠️ [ZoneDetector] Error crítico: No se encontraron los eventos necesarios")
	end
end

-- ============================================
-- UTILIDADES
-- ============================================

local function setCurrentZone(newZone)
	if newZone == currentZone then return end

	local oldZone = currentZone
	currentZone = newZone

	print("🗺️ [ZoneDetector] Zona: " .. (oldZone or "ninguna") .. " → " .. (newZone or "ninguna"))

	-- Notificar al servidor
	if zoneChangedEvent then
		zoneChangedEvent:FireServer(newZone)
	end

	-- Notificar a la GUI local
	if localZoneChanged then
		localZoneChanged:Fire(newZone, oldZone)
	end

	-- Atributo en el jugador
	player:SetAttribute("CurrentZone", newZone or "")
end

local function onTouched(hit, zonaID)
	-- Verificación simple de personaje
	if not character then return end
	local parent = hit.Parent
	if parent ~= character then return end
	if not parent:FindFirstChild("Humanoid") then return end

	zoneOverlapCount[zonaID] = (zoneOverlapCount[zonaID] or 0) + 1
	setCurrentZone(zonaID)
end

local function onTouchEnded(hit, zonaID)
	if not character then return end
	local parent = hit.Parent
	if parent ~= character then return end
	if not parent:FindFirstChild("Humanoid") then return end

	zoneOverlapCount[zonaID] = math.max(0, (zoneOverlapCount[zonaID] or 0) - 1)

	if zoneOverlapCount[zonaID] <= 0 then
		zoneOverlapCount[zonaID] = 0

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
-- SETUP Y CLEANUP
-- ============================================

local function setupZoneDetection()
	print("🗺️ [ZoneDetector] Esperando NivelActual...")

	-- Esperar explícitamente a que NivelActual exista
	-- Esto soluciona el problema de que el nivel se clona asíncronamente
	local nivelActual = Workspace:WaitForChild("NivelActual", 20)

	if not nivelActual then
		warn("❌ [ZoneDetector] Timeout: NivelActual no apareció")
		return false
	end

	print("✅ [ZoneDetector] Nivel detectado: " .. nivelActual.Name)

	-- Ruta ESTRICTA: NivelActual > Zonas > Zonas_juego
	local zonas = nivelActual:WaitForChild("Zonas", 10)
	if not zonas then
		warn("❌ [ZoneDetector] No se encontró carpeta 'Zonas'")
		return false
	end

	local zonasFolder = zonas:WaitForChild("Zonas_juego", 10)
	if not zonasFolder then
		warn("❌ [ZoneDetector] No se encontró carpeta 'Zonas_juego'")
		return false
	end

	print("✅ [ZoneDetector] Zonas_juego disponible")

	-- Limpiar overlaps previos
	zoneOverlapCount = {}
	setupConnections = {}

	-- Conectar cada zona
	local zonasConectadas = 0
	for _, zona in ipairs(zonasFolder:GetChildren()) do
		local zonaID = zona.Name
		local partsConectados = 0

		-- Conectar descendientes BaseParts
		for _, desc in ipairs(zona:GetDescendants()) do
			if desc:IsA("BasePart") then
				local conn1 = desc.Touched:Connect(function(hit)
					onTouched(hit, zonaID)
				end)
				local conn2 = desc.TouchEnded:Connect(function(hit)
					onTouchEnded(hit, zonaID)
				end)
				table.insert(setupConnections, conn1)
				table.insert(setupConnections, conn2)
				partsConectados = partsConectados + 1
			end
		end

		-- Si la zona misma es un BasePart
		if zona:IsA("BasePart") then
			local conn1 = zona.Touched:Connect(function(hit)
				onTouched(hit, zonaID)
			end)
			local conn2 = zona.TouchEnded:Connect(function(hit)
				onTouchEnded(hit, zonaID)
			end)
			table.insert(setupConnections, conn1)
			table.insert(setupConnections, conn2)
			partsConectados = partsConectados + 1
		end

		if partsConectados > 0 then
			zonasConectadas = zonasConectadas + 1
			-- print("   ✅ " .. zonaID .. " (" .. partsConectados .. " parts)") -- Reducir log
			zoneOverlapCount[zonaID] = 0
		end
	end

	if zonasConectadas == 0 then
		warn("❌ [ZoneDetector] Ninguna zona conectada (revisa estructura)")
		return false
	end

	print("✅ [ZoneDetector] " .. zonasConectadas .. " zonas conectadas correctamente")
	return true
end

local function cleanupZoneDetection()
	print("🧹 [ZoneDetector] Limpiando...")

	-- Desconectar todas las conexiones
	for _, conn in ipairs(setupConnections) do
		if conn then conn:Disconnect() end
	end
	setupConnections = {}

	-- Resetear estado
	currentZone = nil
	zoneOverlapCount = {}
	player:SetAttribute("CurrentZone", "")
	isSetupActive = false

	print("✅ [ZoneDetector] Limpieza completa")
end

-- ============================================
-- ESCUCHAR CAMBIOS DE NIVEL
-- ============================================

player:GetAttributeChangedSignal("CurrentLevelID"):Connect(function()
	local levelID = player:GetAttribute("CurrentLevelID")

	if levelID and levelID >= 0 then
		-- 🔥 ENTRÓ A UN NIVEL
		print("📍 [ZoneDetector] Nivel " .. levelID .. " detectado - Iniciando espera...")

		if not isSetupActive then
			task.spawn(function()
				-- Esperar un momento breve para estabilización
				task.wait(0.5)

				-- Intentar setup incluso si el personaje no está listo, 
				-- ya que necesitamos conectar los eventos de las partes del nivel.
				-- La validación 'onTouched' se encargará de verificar el personaje en tiempo real.
				if setupZoneDetection() then
					isSetupActive = true
					print("✅ [ZoneDetector] ACTIVADO para nivel " .. levelID)
				else
					warn("⚠️ [ZoneDetector] Fallo al conectar zonas")
				end
			end)
		end
	else
		-- 🔥 SALIÓ DEL NIVEL (menú)
		print("📍 [ZoneDetector] Salió del nivel")

		if isSetupActive then
			cleanupZoneDetection()
		end
	end
end)

-- ============================================
-- MANEJAR RESPAWN
-- ============================================

local function onCharacterAdded(char)
	character = char
	print("👤 [ZoneDetector] Nuevo personaje detectado")

	-- No necesitamos reiniciar la detección de zonas si el nivel no ha cambiado,
	-- ya que las conexiones están en las Partes del workspace (nivel), no en el personaje.
	-- Solo necesitamos actualizar la referencia 'character' (hecho arriba).
end

-- ============================================
-- INICIALIZACIÓN
-- ============================================

initializeEvents()

if player.Character then
	character = player.Character
	print("👤 [ZoneDetector] Personaje inicial listo")
else
	-- No bloqueamos la inicialización esperando el personaje
	print("👤 [ZoneDetector] Esperando personaje...")
end

player.CharacterAdded:Connect(onCharacterAdded)

print("╔════════════════════════════════════════════╗")
print("║  ✅ ZoneDetector LISTO (v2.0)            ║")
print("║  Ruta estricta: NivelActual/Zonas/Juego  ║")
print("║  Espera dinámica de nivel                ║")
print("╚════════════════════════════════════════════╝")
