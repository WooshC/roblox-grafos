-- HUDMisionPanel.lua (corregido - formato contador)
-- Panel de misiones: fuera de zona = resumen por zonas, dentro de zona = solo misiones de esa zona

local HUDMisionPanel = {}

local parentHud = nil
local misionFrame = nil
local misionCuerpo = nil
local btnMisiones = nil
local btnCerrar = nil
local isPanelOpen = false

local COLOR_COMPLETA = Color3.fromRGB(80, 200, 120)
local COLOR_PENDIENTE = Color3.fromRGB(200, 200, 200)
local COLOR_ZONA_BG = Color3.fromRGB(30, 30, 50)
local COLOR_ZONA_ACTIVA = Color3.fromRGB(30, 50, 90)
local ROW_HEIGHT = 22

function HUDMisionPanel.init(hudRef)
	parentHud = hudRef
	misionFrame = parentHud:FindFirstChild("MisionFrame", true)
	misionCuerpo = misionFrame and misionFrame:FindFirstChild("Cuerpo", true)
	btnMisiones = parentHud:FindFirstChild("BtnMisiones", true)
	btnCerrar = misionFrame and misionFrame:FindFirstChild("BtnCerrarMisiones", true)

	HUDMisionPanel._connectToggleButtons()
end

function HUDMisionPanel._connectToggleButtons()
	if btnMisiones then
		btnMisiones.MouseButton1Click:Connect(HUDMisionPanel.toggle)
	end
	if btnCerrar then
		btnCerrar.MouseButton1Click:Connect(function()
			isPanelOpen = false
			if misionFrame then misionFrame.Visible = false end
		end)
	end
end

function HUDMisionPanel.toggle()
	if not misionFrame then return end
	isPanelOpen = not isPanelOpen
	misionFrame.Visible = isPanelOpen
end

function HUDMisionPanel.reset()
	isPanelOpen = false
	if misionFrame then misionFrame.Visible = false end
	HUDMisionPanel.clear()
end

function HUDMisionPanel.clear()
	if not misionCuerpo then return end
	for _, child in ipairs(misionCuerpo:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

local function createLabel(parent, text, color, size, isBold, useRichText)
	local label = Instance.new("TextLabel")
	label.Size = size or UDim2.new(1, 0, 0, ROW_HEIGHT)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextScaled = false
	label.TextSize = 14
	label.Font = isBold and Enum.Font.GothamBold or Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.RichText = useRichText or false
	label.Parent = parent
	return label
end

-- Convierte formato porZona (servidor) a formato plano
local function normalizarDatos(missionData)
	if not missionData then return nil end
	if missionData.misiones then return missionData end

	local misiones = {}
	local completadas = {}
	local zonaActual = missionData.zonaActual

	if missionData.porZona then
		for nombreZona, datosZona in pairs(missionData.porZona) do
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

function HUDMisionPanel.rebuild(missionData)
	HUDMisionPanel.clear()

	local data = normalizarDatos(missionData)
	if not data or not misionCuerpo then 
		warn("[HUDMisionPanel] No hay datos o misionCuerpo")
		return 
	end

	local misiones = data.misiones or {}
	local completadas = data.completadas or {}
	local zonaActual = data.zonaActual

	print(string.format("[HUDMisionPanel] Rebuild: %d misiones, zonaActual: %s", 
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

	-- MODO 1: Dentro de zona específica - mostrar SOLO misiones de esa zona
	if zonaActual and zonaActual ~= "" and zonasMap[zonaActual] then
		print("[HUDMisionPanel] Modo: DENTRO de zona " .. zonaActual)
		HUDMisionPanel._mostrarMisionesZona(zonaActual, zonasMap[zonaActual], completadasSet)
	else
		-- MODO 2: Fuera de zona - mostrar resumen de TODAS las zonas
		print("[HUDMisionPanel] Modo: FUERA de zona - mostrando resumen")
		for _, nombreZona in ipairs(zonasOrden) do
			HUDMisionPanel._mostrarHeaderZona(nombreZona, zonasMap[nombreZona])
		end
	end

	-- Ajustar canvas
	local listLayout = misionCuerpo:FindFirstChildOfClass("UIListLayout")
	if listLayout then
		misionCuerpo.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
	end

	if misionFrame then misionFrame.Visible = isPanelOpen end
end

-- Muestra solo el header de zona con contador (modo resumen)
-- Formato: "Zona_Estacion_1 · (0/2)" o "Zona_Estacion_1 · ✅"
function HUDMisionPanel._mostrarHeaderZona(nombreZona, datosZona)
	local completadas = datosZona.completadas
	local total = datosZona.total
	local todasCompletas = (completadas >= total)

	local headerFrame = Instance.new("Frame")
	headerFrame.Size = UDim2.new(1, 0, 0, ROW_HEIGHT + 4)
	headerFrame.BackgroundColor3 = COLOR_ZONA_BG
	headerFrame.BorderSizePixel = 0
	headerFrame.Parent = misionCuerpo

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = headerFrame

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = headerFrame

	-- Formato: "(completadas/total)" o "✅" si todas completas
	local textoEstado = todasCompletas and "✅" or string.format("(%d/%d)", completadas, total)
	createLabel(headerFrame,
		string.format("%s  ·  %s", nombreZona:gsub("_", " "), textoEstado),
		todasCompletas and COLOR_COMPLETA or Color3.fromRGB(220, 220, 255),
		UDim2.new(1, -16, 1, 0), true, false)
end

-- Muestra header + lista de misiones de una zona específica
function HUDMisionPanel._mostrarMisionesZona(nombreZona, datosZona, completadasSet)
	local completadas = datosZona.completadas
	local total = datosZona.total

	-- Header destacado (zona activa) - mismo formato de contador
	local headerFrame = Instance.new("Frame")
	headerFrame.Size = UDim2.new(1, 0, 0, ROW_HEIGHT + 4)
	headerFrame.BackgroundColor3 = COLOR_ZONA_ACTIVA
	headerFrame.BorderSizePixel = 0
	headerFrame.Parent = misionCuerpo

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = headerFrame

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = headerFrame

	local todasCompletas = (completadas >= total)
	local textoEstado = todasCompletas and "✅" or string.format("(%d/%d)", completadas, total)
	createLabel(headerFrame,
		string.format("%s  ·  %s", nombreZona:gsub("_", " "), textoEstado),
		todasCompletas and COLOR_COMPLETA or Color3.fromRGB(220, 220, 255),
		UDim2.new(1, -16, 1, 0), true, false)

	-- Lista de misiones de esta zona
	for _, mision in ipairs(datosZona.misiones) do
		local estaCompleta = completadasSet[mision.ID] == true
		local puntosTexto = mision.Puntos and mision.Puntos > 0 and (" (+%d pts)"):format(mision.Puntos) or ""
		local icono = estaCompleta and "✅ " or "○ "

		local rowFrame = Instance.new("Frame")
		rowFrame.Size = UDim2.new(1, 0, 0, ROW_HEIGHT + 16)
		rowFrame.BackgroundTransparency = 1
		rowFrame.Parent = misionCuerpo

		if estaCompleta then
			createLabel(rowFrame,
				string.format("<s>%s%s%s</s>", icono, mision.Texto or "?", puntosTexto),
				COLOR_COMPLETA, UDim2.new(1, -22, 1, 0), false, true)
		else
			createLabel(rowFrame,
				icono .. (mision.Texto or "?") .. puntosTexto,
				COLOR_PENDIENTE, UDim2.new(1, -22, 1, 0), false, false)
		end
	end
end

return HUDMisionPanel