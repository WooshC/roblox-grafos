-- StarterPlayerScripts/HUD/ModulosHUD/PuntajeHUD.lua
-- Actualiza los labels de puntaje en la barra superior del HUD
-- Maneja: ContenedorEstrellas, ContenedorPuntos, ContenedorDinero

local PuntajeHUD = {}

local parentHud = nil
local etiquetaEstrellas = nil
local etiquetaPuntos = nil
local etiquetaDinero = nil

function PuntajeHUD.init(hudRef)
	parentHud = hudRef
	PuntajeHUD._buscarEtiquetas()
end

function PuntajeHUD._buscarEtiquetas()
	local barraSuperior = parentHud:FindFirstChild("BarraSuperior")
	if not barraSuperior then
		-- Fallback: buscar recursivamente
		PuntajeHUD._buscarEtiquetasRecursivo()
		return
	end
	
	local panelPuntuacion = barraSuperior:FindFirstChild("PanelPuntuacion")
	if not panelPuntuacion then
		PuntajeHUD._buscarEtiquetasRecursivo()
		return
	end
	
	-- Buscar ContenedorEstrellas
	local contenedorEstrellas = panelPuntuacion:FindFirstChild("ContenedorEstrellas")
	if contenedorEstrellas then
		etiquetaEstrellas = contenedorEstrellas:FindFirstChild("Val") or contenedorEstrellas:FindFirstChild("Valor")
	end
	
	-- Buscar ContenedorPuntos
	local contenedorPuntos = panelPuntuacion:FindFirstChild("ContenedorPuntos")
	if contenedorPuntos then
		etiquetaPuntos = contenedorPuntos:FindFirstChild("Val") or contenedorPuntos:FindFirstChild("Valor")
	end
	
	-- Buscar ContenedorDinero
	local contenedorDinero = panelPuntuacion:FindFirstChild("ContenedorDinero")
	if contenedorDinero then
		etiquetaDinero = contenedorDinero:FindFirstChild("Val") or contenedorDinero:FindFirstChild("Valor")
	end
	
	-- Si no se encontraron, intentar fallback recursivo
	if not (etiquetaEstrellas and etiquetaPuntos) then
		PuntajeHUD._buscarEtiquetasRecursivo()
	end
end

function PuntajeHUD._buscarEtiquetasRecursivo()
	-- Fallback recursivo para estrellas
	if not etiquetaEstrellas then
		local fallbackEstrellas = parentHud:FindFirstChild("ContenedorEstrellas", true)
		if fallbackEstrellas then
			etiquetaEstrellas = fallbackEstrellas:FindFirstChild("Val") or fallbackEstrellas:FindFirstChild("Valor")
		end
	end
	
	-- Fallback recursivo para puntos
	if not etiquetaPuntos then
		local fallbackPuntos = parentHud:FindFirstChild("ContenedorPuntos", true)
		if fallbackPuntos then
			etiquetaPuntos = fallbackPuntos:FindFirstChild("Val") or fallbackPuntos:FindFirstChild("Valor")
		end
	end
	
	-- Fallback recursivo para dinero
	if not etiquetaDinero then
		local fallbackDinero = parentHud:FindFirstChild("ContenedorDinero", true)
		if fallbackDinero then
			etiquetaDinero = fallbackDinero:FindFirstChild("Val") or fallbackDinero:FindFirstChild("Valor")
		end
	end
end

-- Actualiza el puntaje en el contenedor de puntos (🏆)
function PuntajeHUD.fijar(valor)
	if not etiquetaPuntos then
		PuntajeHUD._buscarEtiquetas()
	end
	
	if etiquetaPuntos then
		etiquetaPuntos.Text = tostring(valor or 0)
	end
end

-- Actualiza las estrellas (⭐)
function PuntajeHUD.fijarEstrellas(valor)
	if not etiquetaEstrellas then
		PuntajeHUD._buscarEtiquetas()
	end
	
	if etiquetaEstrellas then
		etiquetaEstrellas.Text = tostring(valor or 0)
	end
end

-- Actualiza el dinero (💰)
function PuntajeHUD.fijarDinero(valor)
	if not etiquetaDinero then
		PuntajeHUD._buscarEtiquetas()
	end
	
	if etiquetaDinero then
		etiquetaDinero.Text = tostring(valor or 0)
	end
end

-- Actualiza todos los valores a la vez
function PuntajeHUD.actualizarTodo(estrellas, puntos, dinero)
	PuntajeHUD.fijarEstrellas(estrellas)
	PuntajeHUD.fijar(puntos)
	PuntajeHUD.fijarDinero(dinero)
end

return PuntajeHUD
