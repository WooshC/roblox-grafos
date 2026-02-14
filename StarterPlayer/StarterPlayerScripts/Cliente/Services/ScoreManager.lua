-- ================================================================
-- ScoreManager.lua (CORREGIDO CON FIX DE TIMING)
-- Gestiona actualización de puntaje, estrellas y dinero
-- ✅ AHORA CALCULA Y ACTUALIZA ESTRELLAS EN TIEMPO REAL (SIN LAG)
-- ================================================================

local ScoreManager = {}
ScoreManager.__index = ScoreManager

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Cargar LevelsConfig para obtener thresholds
local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))

-- Referencias de UI (se inyectan en initialize)
local screenGui = nil
local lblPuntaje = nil
local puntajeLabel = nil
local estrellaLabel = nil

-- Variables de estado
local puntosActuales = 0
local estrellasActuales = 0

-- ================================================================
-- INICIALIZACIÓN
-- ================================================================

--- Inyecta referencias de UI
function ScoreManager.initialize(gui)
	screenGui = gui
	lblPuntaje = gui:WaitForChild("LabelPuntaje", 5)

	-- Estos labels son opcionales (pueden no existir si borraste ScoreFrame)
	local scoreFrame = gui:FindFirstChild("ScoreFrame")
	if scoreFrame then
		puntajeLabel = scoreFrame:FindFirstChild("PuntajeLabel")
		estrellaLabel = scoreFrame:FindFirstChild("EstrellaLabel")
	end

	print("✅ ScoreManager: Inicializado")
end

--- ✅ NUEVA FUNCIÓN: Calcular estrellas basado en puntos y nivel
local function calcularEstrellas(puntos, nivelID)
	local config = LevelsConfig[nivelID]
	if not config or not config.Puntuacion then
		print("⚠️ ScoreManager: No hay configuración de puntuación para nivel " .. nivelID)
		return 0
	end

	local thresholds = config.Puntuacion
	
	-- Lógica: Comparar puntos con thresholds
	if puntos >= (thresholds.TresEstrellas or 1000) then
		return 3
	elseif puntos >= (thresholds.DosEstrellas or 500) then
		return 2
	elseif puntos > 0 then
		return 1
	else
		return 0
	end
end

--- Inicia listeners de cambios en stats
function ScoreManager:init()
	task.spawn(function()
		-- Esperar a que el jugador tenga leaderstats
		local stats = player:WaitForChild("leaderstats", 10)
		if not stats then
			warn("⚠️ ScoreManager: leaderstats no encontrado")
			return
		end

		local puntos = stats:WaitForChild("Puntos", 5)
		local estrellas = stats:WaitForChild("Estrellas", 5)
		local dinero = stats:FindFirstChild("Money") or stats:FindFirstChild("Dinero")

		-- 🔥 CRÍTICO: Conectar a cambios de Puntos
		if puntos then
			-- Actualizar inicial
			puntosActuales = puntos.Value
			self:updateScore()

			-- Conectar a cambios FUTUROS
			puntos.Changed:Connect(function(newValue)
				puntosActuales = newValue
				print("💰 [ScoreManager] Puntos cambiaron a: " .. newValue)
				
				-- ✅ CÁLCULO AUTOMÁTICO DE ESTRELLAS
				local nivelID = player:GetAttribute("CurrentLevelID") or 0
				local nuevasEstrellas = calcularEstrellas(newValue, nivelID)
				
				-- Actualizar leaderstats.Estrellas si cambió
				if estrellas and nuevasEstrellas ~= estrellas.Value then
					estrellas.Value = nuevasEstrellas
					print("⭐ [ScoreManager] Estrellas actualizadas a: " .. nuevasEstrellas .. 
						" (puntos: " .. newValue .. ", nivel: " .. nivelID .. ")")
					
					-- ✅ FIX DE TIMING: Esperar un frame para que se propague el cambio
					task.wait()
				end
				
				self:updateScore()  -- 🔥 ACTUALIZAR DESPUÉS de cambiar estrellas
			end)
		end

		if estrellas then
			-- Actualizar inicial
			estrellasActuales = estrellas.Value
			self:updateScore()

			-- Conectar a cambios
			estrellas.Changed:Connect(function(newValue)
				estrellasActuales = newValue
				print("⭐ [ScoreManager] Estrellas cambiaron a: " .. newValue)
				self:updateScore()  -- ✅ Actualizar UI cuando estrellas cambian
			end)
		end

		if dinero then
			dinero.Changed:Connect(function()
				self:updateScore()
			end)
		end

		print("✅ ScoreManager: Listeners conectados y activos")
	end)
end

--- 🔥 FUNCIÓN CLAVE: Actualiza todos los labels inmediatamente
function ScoreManager:updateScore()
	local stats = player:FindFirstChild("leaderstats")
	if not stats then 
		print("⚠️ [ScoreManager] No hay leaderstats")
		return 
	end

	local puntos = stats:FindFirstChild("Puntos")
	local estrellas = stats:FindFirstChild("Estrellas")

	-- 1️⃣ Actualizar PuntajeLabel (en ScoreFrame si existe)
	if puntos and puntajeLabel then
		local config = LevelsConfig[player:GetAttribute("CurrentLevelID") or 0]
		local maxPuntos = config and config.Puntuacion and config.Puntuacion.TresEstrellas or 1200
		local texto = puntos.Value .. " / " .. maxPuntos .. " pts"
		puntajeLabel.Text = texto
		print("🎯 [ScoreManager] PuntajeLabel actualizado: " .. texto)
	end

	-- 2️⃣ Actualizar EstrellaLabel (en ScoreFrame si existe)
	local eVal = 0
	if estrellas then
		eVal = estrellas.Value  -- ✅ Leer valor ACTUAL de leaderstats
	end
	
	if estrellaLabel then
		local textoEstrellas = ""

		for i = 1, 3 do
			if i <= eVal then
				textoEstrellas = textoEstrellas .. "⭐"
			else
				textoEstrellas = textoEstrellas .. "☆"
			end
		end

		estrellaLabel.Text = textoEstrellas
		print("⭐ [ScoreManager] EstrellaLabel actualizado: " .. textoEstrellas .. " (valor: " .. eVal .. ")")
	end

	-- 3️⃣ Actualizar LabelPuntaje (HUD principal - EL MÁS IMPORTANTE)
	if lblPuntaje then
		local pVal = puntos and puntos.Value or 0
		-- ✅ CRÍTICO: Usar eVal directamente en lugar de local eVal obsoleto
		local nuevoTexto = "⭐ " .. eVal .. " | pts " .. pVal .. " pts"

		-- Solo actualizar si el texto cambió (evita spam innecesario)
		if lblPuntaje.Text ~= nuevoTexto then
			lblPuntaje.Text = nuevoTexto
			print("🔴 [ScoreManager] LabelPuntaje actualizado: " .. nuevoTexto .. " (valor real de estrellas: " .. eVal .. ")")
		else
			print("ℹ️ [ScoreManager] LabelPuntaje igual, no necesita cambio")
		end
	end
end

--- Obtiene valor actual de puntos
function ScoreManager:getPoints()
	local stats = player:FindFirstChild("leaderstats")
	if not stats then return 0 end

	local puntos = stats:FindFirstChild("Puntos")
	return puntos and puntos.Value or 0
end

--- Obtiene valor actual de estrellas
function ScoreManager:getStars()
	local stats = player:FindFirstChild("leaderstats")
	if not stats then return 0 end

	local estrellas = stats:FindFirstChild("Estrellas")
	return estrellas and estrellas.Value or 0
end

--- Obtiene valor actual de dinero
function ScoreManager:getMoney()
	local stats = player:FindFirstChild("leaderstats")
	if not stats then return 0 end

	local money = stats:FindFirstChild("Money")
	return money and money.Value or 0
end

return ScoreManager