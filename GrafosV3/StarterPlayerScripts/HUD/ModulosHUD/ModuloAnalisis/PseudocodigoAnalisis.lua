-- ModuloAnalisis/PseudocodigoAnalisis.lua
-- Renderiza el panel de pseudocódigo y resalta la línea activa.

local AlgoritmosGrafo = require(script.Parent.Parent.AlgoritmosGrafo)

local E = require(script.Parent.EstadoAnalisis)
local C = require(script.Parent.ConstantesAnalisis)

local PseudocodigoAnalisis = {}

function PseudocodigoAnalisis.reconstruirPseudocodigo(algo)
	local scroll = C.buscar(E.overlay, "ScrollPseudocodigo")
	if not scroll then return end

	for _, child in ipairs(scroll:GetChildren()) do
		if not child:IsA("UIListLayout") then child:Destroy() end
	end
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)

	local pseudo = AlgoritmosGrafo.PSEUDOCODIGOS[algo]
	if not pseudo then return end

	local existing = scroll:FindFirstChildWhichIsA("UIListLayout")
	if not existing then
		local layout     = Instance.new("UIListLayout")
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding   = UDim.new(0, 2)
		layout.Parent    = scroll
	end

	local altLinea = 22
	for i, linea in ipairs(pseudo.lineas) do
		local lbl                  = Instance.new("TextLabel")
		lbl.Name                   = "Linea_" .. i
		lbl.LayoutOrder            = i
		lbl.Size                   = UDim2.new(1, -6, 0, altLinea)
		lbl.BackgroundTransparency = 1
		lbl.BackgroundColor3       = C.COL_LINEA_ACTIVA

		local textToDisplay = (linea == "") and " " or linea
		lbl.Text                   = "    " .. textToDisplay
		lbl.TextColor3             = C.COL_LINEA_NORMAL
		lbl.Font                   = Enum.Font.RobotoMono
		lbl.TextSize               = 13
		lbl.TextXAlignment         = Enum.TextXAlignment.Left
		lbl.TextTruncate           = Enum.TextTruncate.AtEnd
		lbl:SetAttribute("NumLinea", i)

		-- Suavizar bordes de la línea activa
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = lbl

		-- Borde izquierdo (Indicador visual de debugger)
		local borde = Instance.new("Frame")
		borde.Name = "BordeActivo"
		borde.Size = UDim2.new(0, 3, 1, 0)
		borde.BackgroundColor3 = C.COL_LINEA_ACTIVA
		borde.BorderSizePixel = 0
		borde.Visible = false
		borde.Parent = lbl

		-- Flecha de debugger
		local flecha = Instance.new("TextLabel")
		flecha.Name = "Flecha"
		flecha.Size = UDim2.new(0, 20, 1, 0)
		flecha.Position = UDim2.new(0, 3, 0, 0)
		flecha.BackgroundTransparency = 1
		flecha.Text = "▶"
		flecha.TextColor3 = C.COL_LINEA_ACTIVA
		flecha.Font = Enum.Font.Code
		flecha.TextSize = 12
		flecha.Visible = false
		flecha.Parent = lbl

		lbl.Parent                 = scroll
	end

	scroll.CanvasSize = UDim2.new(0, 0, 0, #pseudo.lineas * (altLinea + 2) + 8)

	local insignia = C.buscar(E.overlay, "InsigniaComplejidad")
	if insignia then
		local lbl = insignia:IsA("TextLabel") and insignia
		         or insignia:FindFirstChildWhichIsA("TextLabel")
		if lbl then
			lbl.Text = pseudo.titulo .. "  •  " .. pseudo.complejidad
		end
	end
end

function PseudocodigoAnalisis.resaltarLinea(numLinea)
	local scroll = C.buscar(E.overlay, "ScrollPseudocodigo")
	if not scroll then return end

	for _, child in ipairs(scroll:GetChildren()) do
		if not child:IsA("TextLabel") then continue end
		local n = child:GetAttribute("NumLinea")
		
		local flecha = child:FindFirstChild("Flecha")
		local borde = child:FindFirstChild("BordeActivo")

		if n == numLinea then
			-- Estilo de línea activa (Debug mode)
			child.TextColor3             = Color3.fromRGB(240, 240, 240) -- Texto más claro/blanco para contrastar
			child.BackgroundTransparency = 0.8  -- Fondo naranja sutil
			
			if flecha then flecha.Visible = true end
			if borde then borde.Visible = true end
		else
			-- Estilo de línea inactiva
			child.TextColor3             = C.COL_LINEA_NORMAL
			child.BackgroundTransparency = 1
			
			if flecha then flecha.Visible = false end
			if borde then borde.Visible = false end
		end
	end
end

return PseudocodigoAnalisis
