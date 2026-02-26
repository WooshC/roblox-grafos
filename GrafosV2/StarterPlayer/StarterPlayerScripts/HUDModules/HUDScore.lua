-- HUDScore.lua
-- Actualiza el label de puntaje en la barra superior del HUD
-- Uso: local HUDScore = require(HUDModules.HUDScore)

local HUDScore = {}

local parentHud = nil
local scoreLabel = nil

function HUDScore.init(hudRef)
	parentHud = hudRef
	HUDScore._findScoreLabel()
end

function HUDScore._findScoreLabel()
	local barraSuperior = parentHud:FindFirstChild("BarraSuperior")
	local panelPuntuacion = barraSuperior and barraSuperior:FindFirstChild("PanelPuntuacion")
	local contenedorPuntos = panelPuntuacion and panelPuntuacion:FindFirstChild("ContenedorPuntos")
	
	if contenedorPuntos then
		scoreLabel = contenedorPuntos:FindFirstChild("Val") or contenedorPuntos:FindFirstChild("Valor")
	end
	
	-- Fallback recursivo si no se encontró en la ruta esperada
	if not scoreLabel then
		local fallbackContenedor = parentHud:FindFirstChild("ContenedorPuntos", true)
		if fallbackContenedor then
			scoreLabel = fallbackContenedor:FindFirstChild("Val") or fallbackContenedor:FindFirstChild("Valor")
		end
	end
	
	return scoreLabel
end

function HUDScore.set(valor)
	if not scoreLabel then
		HUDScore._findScoreLabel()
	end
	
	if scoreLabel then
		scoreLabel.Text = tostring(valor or 0)
	end
end

return HUDScore
