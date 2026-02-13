-- ServerScriptService/Services/RewardService.lua
-- SERVICIO CENTRALIZADO para gestión de recompensas
-- Maneja XP, dinero, logros, desbloqueables, ítems

local RewardService = {}
RewardService.__index = RewardService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums"))

-- Estado interno
local levelService = nil
local inventoryManager = nil
local audioService = nil
local uiService = nil

-- Referencias a eventos
local rewardEvent = nil
local achievementEvent = nil

-- Eventos internos
local rewardGivenEvent = Instance.new("BindableEvent")
local achievementUnlockedEvent = Instance.new("BindableEvent")

-- Tablas de configuración
local REWARD_CONFIG = {
	XP_PER_LEVEL = {
		[0] = 50,   -- Tutorial
		[1] = 150,  -- Primera red
		[2] = 200,  -- Expansión
		[3] = 300,  -- Industrial
		[4] = 500   -- Metrópolis
	},
	MONEY_BONUS = {
		[0] = 100,
		[1] = 500,
		[2] = 1000,
		[3] = 2000,
		[4] = 5000
	},
	STAR_THRESHOLDS = {
		[0] = {tres = 100, dos = 50},
		[1] = {tres = 1200, dos = 800},
		[2] = {tres = 2500, dos = 1500},
		[3] = {tres = 4000, dos = 2500},
		[4] = {tres = 8000, dos = 5000}
	}
}

-- Logros disponibles
local ACHIEVEMENTS = {
	FIRST_CONNECTION = {id = "first_connection", nombre = "Primer Contacto", descripcion = "Conecta tu primer cable"},
	COMPLETE_TUTORIAL = {id = "complete_tutorial", nombre = "Aprendiz", descripcion = "Completa el tutorial"},
	COMPLETE_ALL_LEVELS = {id = "complete_all_levels", nombre = "Maestro", descripcion = "Completa todos los niveles"},
	PERFECT_LEVEL = {id = "perfect_level", nombre = "Perfeccionista", descripcion = "Completa un nivel sin desconectar cables"},
	SPEED_RUN = {id = "speed_run", nombre = "Rápido", descripcion = "Completa un nivel en menos de 2 minutos"},
	NO_WASTE = {id = "no_waste", nombre = "Ahorrador", descripcion = "Completa nivel gastando menos del 50% del presupuesto"},
	COLLECT_ALL = {id = "collect_all", nombre = "Coleccionista", descripcion = "Recolecta todos los objetos del juego"},
	DIJKSTRA_MASTER = {id = "dijkstra_master", nombre = "Experto Dijkstra", descripcion = "Usa Dijkstra exitosamente 5 veces"},
	CHAIN_REACTION = {id = "chain_reaction", nombre = "Reacción en Cadena", descripcion = "Energiza 10 nodos de una sola conexión"}
}

-- ============================================
-- INICIALIZACIÓN
-- ============================================

function RewardService:init()
	-- Obtener referencias a eventos remotos
	local Remotes = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes")

	rewardEvent = Remotes:FindFirstChild("DarRecompensa")
	if not rewardEvent then
		rewardEvent = Instance.new("RemoteEvent")
		rewardEvent.Name = "DarRecompensa"
		rewardEvent.Parent = Remotes
	end

	achievementEvent = Remotes:FindFirstChild("DesbloquearLogro")
	if not achievementEvent then
		achievementEvent = Instance.new("RemoteEvent")
		achievementEvent.Name = "DesbloquearLogro"
		achievementEvent.Parent = Remotes
	end

	print("✅ RewardService inicializado")
end

function RewardService:setDependencies(level, inventory, audio, ui)
	levelService = level
	inventoryManager = inventory
	audioService = audio
	uiService = ui
	print("✅ RewardService: Dependencias inyectadas")
end

-- ============================================
-- RECOMPENSAS DE XP
-- ============================================

-- Dar XP al jugador por completar nivel
function RewardService:giveXPForLevel(player, nivelID)
	if not player or not levelService then return 0 end

	local config = levelService:getLevelConfig()
	local xpReward = REWARD_CONFIG.XP_PER_LEVEL[nivelID] or 100

	-- Modificadores
	if config and config.Puntuacion and config.Puntuacion.RecompensaXP then
		xpReward = config.Puntuacion.RecompensaXP
	end

	self:addXP(player, xpReward)
	print("⭐ RewardService: " .. xpReward .. " XP dados a " .. player.Name)

	return xpReward
end

-- Dar XP por acción específica
function RewardService:giveXPForAction(player, accion, cantidad)
	if not player then return 0 end

	quantidade = cantidad or 10

	self:addXP(player, cantidad)
	print("⭐ RewardService: " .. cantidad .. " XP por " .. accion .. " a " .. player.Name)

	return cantidad
end

-- Agrega XP al jugador
function RewardService:addXP(player, cantidad)
	if not player then return end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		print("⚠️ RewardService: No hay leaderstats para " .. player.Name)
		return
	end

	local xpValue = leaderstats:FindFirstChild("XP")
	if not xpValue then
		xpValue = Instance.new("IntValue")
		xpValue.Name = "XP"
		xpValue.Value = 0
		xpValue.Parent = leaderstats
	end

	xpValue.Value = xpValue.Value + cantidad

	rewardGivenEvent:Fire("XP", player, cantidad)

	if rewardEvent then
		rewardEvent:FireClient(player, "XP", cantidad)
	end
end

-- ============================================
-- RECOMPENSAS DE DINERO
-- ============================================

-- Dar dinero por completar nivel
function RewardService:giveMoneyForLevel(player, nivelID, completionPercent)
	if not player or not levelService then return 0 end

	completionPercent = completionPercent or 1.0

	local config = levelService:getLevelConfig()
	local bonusBase = REWARD_CONFIG.MONEY_BONUS[nivelID] or 100

	-- Multiplicador por porcentaje de presupuesto usado
	local bonusMultiplier = completionPercent > 0.5 and 1.0 or (completionPercent * 2)
	local totalBonus = math.floor(bonusBase * bonusMultiplier)

	self:addMoney(player, totalBonus)
	print("💰 RewardService: $" .. totalBonus .. " dados a " .. player.Name)

	return totalBonus
end

-- Agrega dinero al jugador
function RewardService:addMoney(player, cantidad)
	if not player then return end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local moneyValue = leaderstats:FindFirstChild("Money")
	if not moneyValue then return end

	moneyValue.Value = moneyValue.Value + cantidad

	rewardGivenEvent:Fire("Money", player, cantidad)

	if rewardEvent then
		rewardEvent:FireClient(player, "Money", cantidad)
	end
end

-- ============================================
-- RECOMPENSAS DE ESTRELLAS
-- ============================================

-- Calcula estrellas según desempeño
function RewardService:calculateStars(nivelID, pressupuestoUsado, tiempoTranscurrido)
	if not levelService then return 1 end

	local config = levelService:getLevelConfig()
	if not config or not config.Puntuacion then return 1 end

	local score = config.Puntuacion.RecompensaXP or 100

	-- Estrellas basadas en presupuesto
	local thresholds = REWARD_CONFIG.STAR_THRESHOLDS[nivelID]
	if thresholds then
		if pressupuestoUsado <= thresholds.tres then
			return 3
		elseif pressupuestoUsado <= thresholds.dos then
			return 2
		else
			return 1
		end
	end

	return 1
end

-- Da recompensas basadas en estrellas
function RewardService:giveStarRewards(player, nivelID, stars)
	if not player then return 0 end

	local xpReward = 0
	local moneyReward = 0

	-- Multiplicadores por número de estrellas
	if stars == 3 then
		xpReward = 150
		moneyReward = 500
		print("⭐⭐⭐ RewardService: 3 ESTRELLAS - " .. player.Name)
	elseif stars == 2 then
		xpReward = 100
		moneyReward = 250
		print("⭐⭐ RewardService: 2 ESTRELLAS - " .. player.Name)
	elseif stars == 1 then
		xpReward = 50
		moneyReward = 100
		print("⭐ RewardService: 1 ESTRELLA - " .. player.Name)
	end

	self:addXP(player, xpReward)
	self:addMoney(player, moneyReward)

	return {xp = xpReward, money = moneyReward}
end

-- ============================================
-- LOGROS
-- ============================================

-- Desbloquea un logro
function RewardService:unlockAchievement(player, achievementID)
	if not player or not ACHIEVEMENTS[achievementID] then return false end

	local achievement = ACHIEVEMENTS[achievementID]

	print("🏆 RewardService: Logro desbloqueado - " .. achievement.nombre .. " (" .. player.Name .. ")")

	-- Reproducir sonido
	if audioService then
		audioService:playSuccess()
	end

	-- Notificar UI
	if uiService then
		uiService:notifySuccess(player, "¡Logro Desbloqueado!", achievement.nombre)
	end

	-- Emitir evento
	achievementUnlockedEvent:Fire(achievementID, player)

	if achievementEvent then
		achievementEvent:FireClient(player, achievementID, achievement)
	end

	-- Dar bonus por logro
	self:addXP(player, 50)
	self:addMoney(player, 100)

	return true
end

-- Valida y desbloquea logros automáticamente
function RewardService:validateAndUnlockAchievements(player, nivelID)
	if not player or not levelService then return end

	-- Logro: Primera conexión
	if nivelID == 0 then
		local cables = levelService:getCables()
		if #cables > 0 then
			self:unlockAchievement(player, "FIRST_CONNECTION")
		end
	end

	-- Logro: Completar tutorial
	if nivelID == 0 and levelService:checkLevelCompletion() then
		self:unlockAchievement(player, "COMPLETE_TUTORIAL")
	end

	-- Logro: Ahorrador
	local progress = levelService:getLevelProgress()
	if progress.completed then
		local config = levelService:getLevelConfig()
		local presupuesto = config.DineroInicial
		local gastado = presupuesto - progress.dineroRestante

		if gastado < presupuesto * 0.5 then
			self:unlockAchievement(player, "NO_WASTE")
		end
	end
end

-- Obtiene información de un logro
function RewardService:getAchievementInfo(achievementID)
	return ACHIEVEMENTS[achievementID]
end

-- Obtiene todos los logros
function RewardService:getAllAchievements()
	return ACHIEVEMENTS
end

-- ============================================
-- OBJETOS DESBLOQUEABLES
-- ============================================

-- Desbloquea un objeto coleccionable
function RewardService:unlockObject(player, objectID)
	if not player or not inventoryManager then return false end

	-- Agregar al inventario
	inventoryManager:agregarObjeto(player, objectID)

	print("🎁 RewardService: Objeto desbloqueado - " .. objectID .. " (" .. player.Name .. ")")

	-- Notificar
	if uiService then
		uiService:notifySuccess(player, "¡Nuevo Objeto!", objectID .. " desbloqueado")
	end

	return true
end

-- Desbloquea objetos de un nivel
function RewardService:unlockLevelObjects(player, nivelID)
	if not player or not levelService or not inventoryManager then return end

	local config = levelService:getLevelConfig()
	if config and config.Objetos then
		for _, objeto in pairs(config.Objetos) do
			inventoryManager:agregarObjeto(player, objeto.ID)
		end
	end

	print("🎁 RewardService: Objetos del nivel " .. nivelID .. " desbloqueados para " .. player.Name)
end

-- ============================================
-- RECOMPENSA COMPLETA POR NIVEL
-- ============================================

-- Da todas las recompensas al completar un nivel
function RewardService:giveCompletionRewards(player, nivelID)
	if not player or not levelService then
		warn("❌ RewardService: Faltan parámetros para dar recompensas")
		return
	end

	print("🎉 RewardService: Dando recompensas de nivel " .. nivelID .. " a " .. player.Name)

	-- 1. Calcular estrellas
	local config = levelService:getLevelConfig()
	local presupuestoUsado = config.DineroInicial - (player.leaderstats.Money.Value or 0)
	local stars = self:calculateStars(nivelID, presupuestoUsado)

	-- 2. XP
	local xpReward = self:giveXPForLevel(player, nivelID)

	-- 3. Dinero bonus
	local moneyReward = self:giveMoneyForLevel(player, nivelID, (1 - presupuestoUsado / config.DineroInicial))

	-- 4. Bonus por estrellas
	local starBonuses = self:giveStarRewards(player, nivelID, stars)

	-- 5. Desbloquear objetos
	self:unlockLevelObjects(player, nivelID)

	-- 6. Validar logros
	self:validateAndUnlockAchievements(player, nivelID)

	-- 7. Notificar
	if uiService then
		local notificacion = "⭐ x" .. stars .. " | XP +" .. (xpReward + starBonuses.xp) .. " | $ +" .. (moneyReward + starBonuses.money)
		uiService:notifySuccess(player, "¡Nivel Completado!", notificacion)
	end

	print("✅ RewardService: Recompensas completas dadas")

	return {
		stars = stars,
		xp = xpReward + starBonuses.xp,
		money = moneyReward + starBonuses.money
	}
end

-- ============================================
-- ESTADÍSTICAS
-- ============================================

-- Obtiene estadísticas totales del jugador
function RewardService:getPlayerStats(player)
	if not player then return nil end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return nil end

	return {
		level = leaderstats:FindFirstChild("Nivel") and leaderstats.Nivel.Value or 0,
		xp = leaderstats:FindFirstChild("XP") and leaderstats.XP.Value or 0,
		money = leaderstats:FindFirstChild("Money") and leaderstats.Money.Value or 0,
		levelsCompleted = 0  -- Contar desde base de datos
	}
end

-- ============================================
-- EVENTOS
-- ============================================

function RewardService:onRewardGiven(callback)
	rewardGivenEvent.Event:Connect(callback)
end

function RewardService:onAchievementUnlocked(callback)
	achievementUnlockedEvent.Event:Connect(callback)
end

-- ============================================
-- DEBUG
-- ============================================

function RewardService:debug()
	print("\n📊 ===== DEBUG RewardService =====")
	print("Logros disponibles: " .. #ACHIEVEMENTS)

	for id, achievement in pairs(ACHIEVEMENTS) do
		print("   • " .. achievement.nombre .. " (" .. id .. ")")
	end

	print("\nRecompensas por nivel:")
	for nivel, xp in pairs(REWARD_CONFIG.XP_PER_LEVEL) do
		local money = REWARD_CONFIG.MONEY_BONUS[nivel]
		print("   Nivel " .. nivel .. ": " .. xp .. " XP, $" .. money)
	end

	print("===== Fin DEBUG =====\n")
end

return RewardService