-- StarterPlayerScripts/HUD/ModulosHUD/PanelMisionesHUD.lua
-- Panel de misiones: fuera de zona = resumen por zonas, dentro de zona = solo misiones de esa zona

local PanelMisionesHUD = {}

local parentHud = nil
local frameMisiones = nil
local cuerpoMisiones = nil
local btnMisiones = nil
local btnCerrar = nil
local panelAbierto = false
local _ultimosDatos = nil  -- Cache de datos para reconstruir al cambiar de zona

local COLOR_COMPLETA = Color3.fromRGB(80, 200, 120)
local COLOR_PENDIENTE = Color3.fromRGB(200, 200, 200)
local COLOR_ZONA_BG = Color3.fromRGB(30, 30, 50)
local COLOR_ZONA_ACTIVA = Color3.fromRGB(30, 50, 90)
local ALTURA_FILA = 22

function PanelMisionesHUD.init(hudRef)
	parentHud = hudRef
	frameMisiones = parentHud:FindFirstChild("MisionFrame", true)
	cuerpoMisiones = frameMisiones and frameMisiones:FindFirstChild("Cuerpo", true)
	btnMisiones = parentHud:FindFirstChild("BtnMisiones", true)
	btnCerrar = frameMisiones and frameMisiones:FindFirstChild("BtnCerrarMisiones", true)

	PanelMisionesHUD._conectarBotones()
end

function PanelMisionesHUD._conectarBotones()
	if btnMisiones then
		btnMisiones.MouseButton1Click:Connect(PanelMisionesHUD.alternar)
	end
	if btnCerrar then
		btnCerrar.MouseButton1Click:Connect(function()
			panelAbierto = false
			if frameMisiones then frameMisiones.Visible = false end
		end)
	end
end

function PanelMisionesHUD.alternar()
	if not frameMisiones then return end
	panelAbierto = not panelAbierto
	frameMisiones.Visible = panelAbierto
end

function PanelMisionesHUD.reiniciar()
	panelAbierto = false
	_ultimosDatos = nil
	if frameMisiones then frameMisiones.Visible = false end
	PanelMisionesHUD.limpiar()
end

function PanelMisionesHUD.limpiar()
	if not cuerpoMisiones then return end
	for _, child in ipairs(cuerpoMisiones:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

local function crearEtiqueta(parent, texto, color, tamanyo, esNegrita, usarRichText)
	local label = Instance.new("TextLabel")
	label.Size = tamanyo or UDim2.new(1, 0, 0, ALTURA_FILA)
	label.BackgroundTransparency = 1
	label.Text = texto
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextScaled = false
	label.TextSize = 14
	label.Font = esNegrita and Enum.Font.GothamBold or Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.RichText = usarRichText or false
	label.Parent = parent
	return label
end

-- Convierte formato porZona (servidor) a formato plano
local function normalizarDatos(datosMision)
	if not datosMision then return nil end
	if datosMision.misiones then return datosMision end

	local misiones = {}
	local completadas = {}
	local zonaActual = datosMision.zonaActual

	if datosMision.porZona then
		for nombreZona, datosZona in pairs(datosMision.porZona) do
			if datosZona.misiones then
				for _, m in ipairs(datosZona.misiones) do
					table.insert(misiones, {
						ID = m.id or m.ID,
						Texto = m.texto or m.Texto,
						Zona = m.zona or nombreZona,
						Puntos = m.puntos or m.Puntos or 0,
						estado = m.estado or "pendiente"
					})
					if m.estado == "completada" or m.completada then
						table.insert(completadas, m.id or m.ID)
					end
				end
			end
		end
	end

	return { misiones = misiones, completadas = completadas, zonaActual = zonaActual }
end

function PanelMisionesHUD.reconstruir(datosMision)
	PanelMisionesHUD.limpiar()

	-- Actualizar cache: mantener misiones previas si solo viene zonaActual
	if datosMision then
		if datosMision.porZona or datosMision.misiones then
			-- Datos completos, reemplazar cache
			_ultimosDatos = datosMision
		elseif datosMision.zonaActual and _ultimosDatos then
			-- Solo zona nueva, actualizar cache
			_ultimosDatos.zonaActual = datosMision.zonaActual
		end
	end
	
	-- Usar datos cacheados si no hay datos nuevos
	local datosFuente = _ultimosDatos
	if not datosFuente then
		warn("[PanelMisionesHUD] No hay datos de misiones")
		return
	end
	
	local datos = normalizarDatos(datosFuente)
	if not datos or not cuerpoMisiones then 
		warn("[PanelMisionesHUD] No hay datos o cuerpoMisiones")
		return 
	end

	local misiones = datos.misiones or {}
	local completadas = datos.completadas or {}
	local zonaActual = datos.zonaActual

	print(string.format("[PanelMisionesHUD] Reconstruir: %d misiones, zonaActual: %s", 
		#misiones, tostring(zonaActual)))

	local completadasSet = {}
	for _, id in ipairs(completadas) do completadasSet[id] = true end

	-- Agrupar por zona
	local zonasMap, zonasOrden = {}, {}
	for _, mision in ipairs(misiones) do
		local nombreZona = mision.Zona or "SIN_ZONA"
		if not zonasMap[nombreZona] then
			zonasMap[nombreZona] = { misiones = {}, total = 0, completadas = 0 }
			table.insert(zonasOrden, nombreZona)
		end
		table.insert(zonasMap[nombreZona].misiones, mision)
		zonasMap[nombreZona].total = zonasMap[nombreZona].total + 1
		if completadasSet[mision.ID] then
			zonasMap[nombreZona].completadas = zonasMap[nombreZona].completadas + 1
		end
	end

	-- MODO 1: Dentro de zona especifica - mostrar SOLO misiones de esa zona
	if zonaActual and zonaActual ~= "" and zonasMap[zonaActual] then
		print("[PanelMisionesHUD] Modo: DENTRO de zona " .. zonaActual)
		PanelMisionesHUD._mostrarMisionesZona(zonaActual, zonasMap[zonaActual], completadasSet)
	else
		-- MODO 2: Fuera de zona - mostrar resumen de TODAS las zonas
		print("[PanelMisionesHUD] Modo: FUERA de zona - mostrando resumen")
		for _, nombreZona in ipairs(zonasOrden) do
			PanelMisionesHUD._mostrarHeaderZona(nombreZona, zonasMap[nombreZona])
		end
	end

	-- Ajustar canvas
	local listLayout = cuerpoMisiones:FindFirstChildOfClass("UIListLayout")
	if listLayout then
		cuerpoMisiones.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
	end

	if frameMisiones then frameMisiones.Visible = panelAbierto end
end

-- Muestra solo el header de zona con contador (modo resumen)
function PanelMisionesHUD._mostrarHeaderZona(nombreZona, datosZona)
	local completadas = datosZona.completadas
	local total = datosZona.total
	local todasCompletas = (completadas >= total)

	local headerFrame = Instance.new("Frame")
	headerFrame.Size = UDim2.new(1, 0, 0, ALTURA_FILA + 4)
	headerFrame.BackgroundColor3 = COLOR_ZONA_BG
	headerFrame.BorderSizePixel = 0
	headerFrame.Parent = cuerpoMisiones

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = headerFrame

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = headerFrame

	-- Formato: "(completadas/total)" o "✅" si todas completas
	local textoEstado = todasCompletas and "✅" or string.format("(%d/%d)", completadas, total)
	crearEtiqueta(headerFrame,
		string.format("%s  ·  %s", nombreZona:gsub("_", " "), textoEstado),
		todasCompletas and COLOR_COMPLETA or Color3.fromRGB(220, 220, 255),
		UDim2.new(1, -16, 1, 0), true, false)
end

-- Muestra header + lista de misiones de una zona especifica
function PanelMisionesHUD._mostrarMisionesZona(nombreZona, datosZona, completadasSet)
	local completadas = datosZona.completadas
	local total = datosZona.total

	-- Header destacado (zona activa)
	local headerFrame = Instance.new("Frame")
	headerFrame.Size = UDim2.new(1, 0, 0, ALTURA_FILA + 4)
	headerFrame.BackgroundColor3 = COLOR_ZONA_ACTIVA
	headerFrame.BorderSizePixel = 0
	headerFrame.Parent = cuerpoMisiones

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = headerFrame

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = headerFrame

	local todasCompletas = (completadas >= total)
	local textoEstado = todasCompletas and "✅" or string.format("(%d/%d)", completadas, total)
	crearEtiqueta(headerFrame,
		string.format("%s  ·  %s", nombreZona:gsub("_", " "), textoEstado),
		todasCompletas and COLOR_COMPLETA or Color3.fromRGB(220, 220, 255),
		UDim2.new(1, -16, 1, 0), true, false)

	-- Lista de misiones de esta zona
	for _, mision in ipairs(datosZona.misiones) do
		local estaCompleta = completadasSet[mision.ID] == true
		local puntosTexto = mision.Puntos and mision.Puntos > 0 and (" (+%d pts)"):format(mision.Puntos) or ""
		local icono = estaCompleta and "✅ " or "○ "

		local rowFrame = Instance.new("Frame")
		rowFrame.Size = UDim2.new(1, 0, 0, ALTURA_FILA + 16)
		rowFrame.BackgroundTransparency = 1
		rowFrame.Parent = cuerpoMisiones

		if estaCompleta then
			crearEtiqueta(rowFrame,
				string.format("<s>%s%s%s</s>", icono, mision.Texto or "?", puntosTexto),
				COLOR_COMPLETA, UDim2.new(1, -22, 1, 0), false, true)
		else
			crearEtiqueta(rowFrame,
				icono .. (mision.Texto or "?") .. puntosTexto,
				COLOR_PENDIENTE, UDim2.new(1, -22, 1, 0), false, false)
		end
	end
end

return PanelMisionesHUD
