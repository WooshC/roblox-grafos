-- SistemaUI_reinicio.server.lua (REFACTORIZADO)
-- Maneja el reinicio del nivel utilizando servicios centralizados

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Esperar servicios globales
repeat task.wait(0.1) until _G.Services

local LevelService = _G.Services.Level
local GraphService = _G.Services.Graph
local UIService = _G.Services.UI
local AudioService = _G.Services.Audio

-- Referencias a eventos
local Events = ReplicatedStorage:WaitForChild("Events")
local Remotes = Events:WaitForChild("Remotes")
local Bindables = Events:WaitForChild("Bindables")

local remoteEvent = Remotes:WaitForChild("ReiniciarNivel")

-- Eventos legacy para compatibilidad con scripts antiguos de objetos
local eventoLegacy = nil
local serverEvents = ReplicatedStorage:FindFirstChild("ServerEvents")
if serverEvents then
	eventoLegacy = serverEvents:FindFirstChild("RestaurarObjetos")
end
local eventoRestaurar = Bindables:FindFirstChild("RestaurarObjetos")

-- ============================================
-- LÓGICA DE REINICIO
-- ============================================

remoteEvent.OnServerEvent:Connect(function(player)
	print("🔄 SOLICITUD DE REINICIO RECIBIDA:", player.Name)
	
	if not LevelService then
		warn("❌ SistemaUI: LevelService no disponible")
		return
	end
	
	-- 1. Resetear Nivel (Lógica centralizada)
	-- Esto limpia cables, restaura objetos y reinicia misiones
	LevelService:resetLevel()
	
	-- 2. Restablecer Dinero y Stats del Jugador
	-- (Esto es específico del jugador, LevelService maneja el nivel en sí)
	local nivelID = LevelService:getCurrentLevelID()
	local config = LevelService:getLevelConfig()
	
	if not config then
		-- Fallback si no hay nivel cargado oficialmente (aunque LevelService debería tenerlo)
		local stats = player:FindFirstChild("leaderstats")
		if stats and stats:FindFirstChild("Nivel") then
			nivelID = stats.Nivel.Value
			local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))
			config = LevelsConfig[nivelID] or LevelsConfig[0]
		end
	end
	
	if config then
		local dineroBase = config.DineroInicial or 2000
		local stats = player:FindFirstChild("leaderstats")
		
		if stats then
			-- Resetear Dinero
			if stats:FindFirstChild("Money") then
				stats.Money.Value = dineroBase
				print("💰 Dinero restablecido a $" .. dineroBase .. " (Nivel " .. (nivelID or "?") .. ")")
			end
			
			-- Resetear Puntos y Estrellas
			if stats:FindFirstChild("Puntos") then stats.Puntos.Value = 0 end
			if stats:FindFirstChild("Estrellas") then stats.Estrellas.Value = 0 end
			
			print("⭐ Puntaje y estrellas reseteados")
		end
	end
	
	-- 3. Limpieza Visual Extra (Por seguridad)
	-- GraphService ya limpió cables lógicos, pero aseguramos limpieza visual de residuos
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj.Name == "CableFantasma" or string.sub(obj.Name, 1, 8) == "Etiqueta" then 
			obj:Destroy()
		end
	end
	
	-- 4. Eventos de compatibilidad (Objetos recolectables legacy)
	if nivelID then
		if eventoLegacy then
			eventoLegacy:Fire(nivelID)
		end
		if eventoRestaurar then
			eventoRestaurar:Fire(nivelID)
		end
	end
	
	-- 5. Audio
	if AudioService then
		AudioService:playClick() -- O sonido de 'trash' / reset
	end
	
	-- 6. Actualizar UI
	if UIService then
		UIService:notifyLevelReset()
		UIService:updateAll()
		UIService:notifyPlayer(player, "Nivel Reiniciado", "El nivel ha sido restaurado.", "info")
	end
	
	print("✅ NIVEL REINICIADO EXITOSAMENTE")
end)

print("✅ SistemaUI_reinicio (Refactorizado) cargado")
