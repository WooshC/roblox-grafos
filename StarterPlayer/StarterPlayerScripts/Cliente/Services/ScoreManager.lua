-- ================================================================
-- ScoreManager.lua
-- Gestiona actualización de puntaje, estrellas y dinero
-- ================================================================

local ScoreManager = {}
ScoreManager.__index = ScoreManager

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Referencias de UI (se inyectan en initialize)
local screenGui = nil
local lblPuntaje = nil
local puntajeLabel = nil
local estrellaLabel = nil

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
end

--- Inicia listeners de cambios en stats
function ScoreManager:init()
	task.spawn(function()
		local stats = player:WaitForChild("leaderstats", 10)
		if not stats then
			warn("⚠️ ScoreManager: leaderstats no encontrado")
			return
		end

		local puntos = stats:WaitForChild("Puntos", 5)
		local estrellas = stats:WaitForChild("Estrellas", 5)
		local dinero = stats:FindFirstChild("Money") or stats:FindFirstChild("Dinero")

		if puntos then
			puntos.Changed:Connect(function()
				self:update()
			end)
		end

		if estrellas then
			estrellas.Changed:Connect(function()
				self:update()
			end)
		end

		if dinero then
			dinero.Changed:Connect(function()
				self:update()
			end)
		end

		-- Primera actualización
		self:update()
		print("✅ ScoreManager: Listeners conectados")
	end)
end

--- Actualiza todos los labels de puntaje
function ScoreManager:update()
	local stats = player:FindFirstChild("leaderstats")
	if not stats then return end

	local puntos = stats:FindFirstChild("Puntos")
	local estrellas = stats:FindFirstChild("Estrellas")

	-- Actualizar PuntajeLabel (en ScoreFrame si existe)
	if puntos and puntajeLabel then
		puntajeLabel.Text = puntos.Value .. " / 1200 pts"
	end

	-- Actualizar EstrellaLabel (en ScoreFrame si existe)
	local eVal = 0
	if estrellas and estrellaLabel then
		eVal = estrellas.Value
		local textoEstrellas = ""

		for i = 1, 3 do
			if i <= eVal then
				textoEstrellas = textoEstrellas .. "⭐"
			else
				textoEstrellas = textoEstrellas .. "☆"
			end
		end

		estrellaLabel.Text = textoEstrellas
	end

	-- Actualizar LabelPuntaje (HUD principal)
	if lblPuntaje then
		local pVal = puntos and puntos.Value or 0
		lblPuntaje.Text = "⭐ " .. eVal .. " | pts " .. pVal .. " pts"
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

return ScoreManager
