local ScorePanel = {}

function ScorePanel.show(screenGui)
	local scoreFrame = screenGui:FindFirstChild("ScoreFrame")
	if scoreFrame then
		scoreFrame.Visible = true
	end
	
	local lblPuntaje = screenGui:FindFirstChild("LabelPuntaje")
	if lblPuntaje then
		lblPuntaje.Visible = true
	end
end

function ScorePanel.hide(screenGui)
	-- Nota: screenGui podría no ser pasado si se llama desde un contexto global,
	-- así que idealmente deberíamos guardar la referencia o pasarla siempre.
	-- Asumiremos que se pasa o buscaremos en PlayerGui si es necesario en una implementación más robusta.
	if screenGui then
		local scoreFrame = screenGui:FindFirstChild("ScoreFrame")
		if scoreFrame then
			scoreFrame.Visible = false
		end
		-- LabelPuntaje usualmente se mantiene visible en gameplay, dependiendo del diseño.
		-- En el código original, lblPuntaje se ocultaba/mostraba con toggleMapa/misiones?
		-- Revisando código original: lblPuntaje.Visible = true en toggleMapa y en updateVisibility.
	end
end

function ScorePanel.update(screenGui, points, stars, money)
	-- Actualizar Label Principal (HUD)
	local lblPuntaje = screenGui:FindFirstChild("LabelPuntaje")
	if lblPuntaje then
		local eVal = stars or 0
		local pVal = points or 0
		lblPuntaje.Text = "⭐ " .. eVal .. " | pts " .. pVal .. " pts"
	end

	-- Actualizar Panel Central (ScoreFrame)
	local scoreFrame = screenGui:FindFirstChild("ScoreFrame")
	if scoreFrame then
		local puntajeLabel = scoreFrame:FindFirstChild("PuntajeLabel")
		local estrellaLabel = scoreFrame:FindFirstChild("EstrellaLabel")

		if puntajeLabel then
			puntajeLabel.Text = (points or 0) .. " / 1200 pts"
		end

		if estrellaLabel then
			local numEstrellas = stars or 0
			local textoEstrellas = ""
			for i = 1, 3 do
				if i <= numEstrellas then
					textoEstrellas = textoEstrellas .. "⭐"
				else
					textoEstrellas = textoEstrellas .. "☆"
				end
			end
			estrellaLabel.Text = textoEstrellas
		end
	end
end

return ScorePanel
