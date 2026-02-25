-- ================================================================
-- UIServiceSync.server.lua
-- Complemento a UIService que sincroniza cambios en leaderstats
-- con todos los clientes conectados
-- ================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("🔄 [UIServiceSync] Iniciando sistema de sincronización...")

-- ================================================================
-- OBTENER REFERENCIAS A EVENTOS
-- ================================================================

local Events = ReplicatedStorage:FindFirstChild("Events")
if not Events then
	Events = Instance.new("Folder")
	Events.Name = "Events"
	Events.Parent = ReplicatedStorage
end

local Remotes = Events:FindFirstChild("Remotes")
if not Remotes then
	Remotes = Instance.new("Folder")
	Remotes.Name = "Remotes"
	Remotes.Parent = Events
end

local syncUIEvent = Remotes:FindFirstChild("SyncUI")
if not syncUIEvent then
	syncUIEvent = Instance.new("RemoteEvent")
	syncUIEvent.Name = "SyncUI"
	syncUIEvent.Parent = Remotes
end

print("✅ [UIServiceSync] Evento SyncUI creado")

-- ================================================================
-- MONITOREAR CAMBIOS EN LEADERSTATS
-- ================================================================

Players.PlayerAdded:Connect(function(player)
	print("👤 [UIServiceSync] Jugador conectado: " .. player.Name)

	-- Esperar a que se cree leaderstats
	local stats = player:WaitForChild("leaderstats", 10)
	if not stats then
		warn("⚠️ [UIServiceSync] leaderstats no encontrado para " .. player.Name)
		return
	end

	print("✅ [UIServiceSync] leaderstats encontrado para " .. player.Name)

	-- ================================================================
	-- MONITOREAR PUNTOS
	-- ================================================================
	local puntos = stats:FindFirstChild("Puntos")
	if puntos then
		puntos.Changed:Connect(function(newValue)
			print("💰 [UIServiceSync] Puntos cambió a " .. newValue .. " para " .. player.Name)

			-- Enviar actualización al cliente
			syncUIEvent:FireClient(player, {
				type = "puntos",
				value = newValue
			})
		end)
		print("   ✓ Conectado a cambios de Puntos")
	end

	-- ================================================================
	-- MONITOREAR ESTRELLAS
	-- ================================================================
	local estrellas = stats:FindFirstChild("Estrellas")
	if estrellas then
		estrellas.Changed:Connect(function(newValue)
			print("⭐ [UIServiceSync] Estrellas cambió a " .. newValue .. " para " .. player.Name)

			-- Enviar actualización al cliente
			syncUIEvent:FireClient(player, {
				type = "estrellas",
				value = newValue
			})
		end)
		print("   ✓ Conectado a cambios de Estrellas")
	end

	-- ================================================================
	-- MONITOREAR DINERO
	-- ================================================================
	local dinero = stats:FindFirstChild("Money")
	if dinero then
		dinero.Changed:Connect(function(newValue)
			print("💵 [UIServiceSync] Dinero cambió a " .. newValue .. " para " .. player.Name)

			-- Enviar actualización al cliente
			syncUIEvent:FireClient(player, {
				type = "dinero",
				value = newValue
			})
		end)
		print("   ✓ Conectado a cambios de Dinero")
	end
end)

print("╔════════════════════════════════════════════╗")
print("║  ✅ UIServiceSync ACTIVO                 ║")
print("║  Los cambios en leaderstats se sincronizan║")
print("║  automáticamente a todos los clientes     ║")
print("╚════════════════════════════════════════════╝")