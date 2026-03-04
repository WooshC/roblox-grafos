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

	local altLinea = 20
	for i, linea in ipairs(pseudo.lineas) do
		local lbl                  = Instance.new("TextLabel")
		lbl.Name                   = "Linea_" .. i
		lbl.LayoutOrder            = i
		lbl.Size                   = UDim2.new(1, -6, 0, altLinea)
		lbl.BackgroundTransparency = 1
		lbl.Text                   = (linea == "") and " " or linea
		lbl.TextColor3             = C.COL_LINEA_NORMAL
		lbl.Font                   = Enum.Font.Code
		lbl.TextSize               = 12
		lbl.TextXAlignment         = Enum.TextXAlignment.Left
		lbl.TextTruncate           = Enum.TextTruncate.AtEnd
		lbl:SetAttribute("NumLinea", i)
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
		if n == numLinea then
			child.TextColor3             = C.COL_LINEA_ACTIVA
			child.BackgroundTransparency = 0.6
			child.BackgroundColor3       = Color3.fromRGB(120, 60, 10)
		else
			child.TextColor3             = C.COL_LINEA_NORMAL
			child.BackgroundTransparency = 1
		end
	end
end

return PseudocodigoAnalisis
