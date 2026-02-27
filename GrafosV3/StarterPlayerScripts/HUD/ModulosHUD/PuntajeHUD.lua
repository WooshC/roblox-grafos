-- StarterPlayerScripts/HUD/ModulosHUD/PuntajeHUD.lua
-- Actualiza el label de puntaje en la barra superior del HUD

local PuntajeHUD = {}

local parentHud = nil
local etiquetaPuntaje = nil

function PuntajeHUD.init(hudRef)
	parentHud = hudRef
	PuntajeHUD._buscarEtiquetaPuntaje()
end

function PuntajeHUD._buscarEtiquetaPuntaje()
	local barraSuperior = parentHud:FindFirstChild("BarraSuperior")
	local panelPuntuacion = barraSuperior and barraSuperior:FindFirstChild("PanelPuntuacion")
	local contenedorPuntos = panelPuntuacion and panelPuntuacion:FindFirstChild("ContenedorPuntos")
	
	if contenedorPuntos then
		etiquetaPuntaje = contenedorPuntos:FindFirstChild("Val") or contenedorPuntos:FindFirstChild("Valor")
	end
	
	-- Fallback recursivo si no se encontró en la ruta esperada
	if not etiquetaPuntaje then
		local fallbackContenedor = parentHud:FindFirstChild("ContenedorPuntos", true)
		if fallbackContenedor then
			etiquetaPuntaje = fallbackContenedor:FindFirstChild("Val") or fallbackContenedor:FindFirstChild("Valor")
		end
	end
	
	return etiquetaPuntaje
end

function PuntajeHUD.fijar(valor)
	if not etiquetaPuntaje then
		PuntajeHUD._buscarEtiquetaPuntaje()
	end
	
	if etiquetaPuntaje then
		etiquetaPuntaje.Text = tostring(valor or 0)
	end
end

return PuntajeHUD
