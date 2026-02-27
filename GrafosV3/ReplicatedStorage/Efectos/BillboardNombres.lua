-- ReplicatedStorage/Efectos/BillboardNombres.lua
-- Sistema de billboards para mostrar nombres de nodos

local TweenService = game:GetService("TweenService")

local BillboardNombres = {}

-- Configuracion
local CONFIG = {
	tamano = UDim2.new(0, 120, 0, 35),
	tamanoLetra = 16,
	colorFondo = Color3.fromRGB(15, 23, 42),
	transparenciaFondo = 0.3,
	colorTexto = Color3.fromRGB(0, 212, 255),
	offsetY = 4,
	tiempoFade = 0.2,
}

-- Cache de billboards creados
local billboardsActivos = {}

-- Crear billboard para un nodo
function BillboardNombres.crear(nodoModelo, nombreMostrar)
	if not nodoModelo or not nodoModelo.Parent then
		return nil
	end
	
	local texto = nombreMostrar or nodoModelo.Name
	
	-- Eliminar si ya existe
	local existente = nodoModelo:FindFirstChild("BillboardNombre")
	if existente then
		existente:Destroy()
	end
	
	-- Crear BillboardGui
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BillboardNombre"
	billboard.Size = CONFIG.tamano
	billboard.StudsOffset = Vector3.new(0, CONFIG.offsetY, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 50
	
	-- Frame de fondo
	local frame = Instance.new("Frame")
	frame.Name = "Fondo"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = CONFIG.colorFondo
	frame.BackgroundTransparency = CONFIG.transparenciaFondo
	frame.BorderSizePixel = 0
	frame.Parent = billboard
	
	-- Esquinas redondeadas
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = frame
	
	-- Texto
	local label = Instance.new("TextLabel")
	label.Name = "TextoNombre"
	label.Size = UDim2.new(1, -10, 1, 0)
	label.Position = UDim2.new(0, 5, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = texto
	label.TextColor3 = CONFIG.colorTexto
	label.TextSize = CONFIG.tamanoLetra
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0.5
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.Parent = frame
	
	-- Anclar al nodo
	local parteAnclar = nodoModelo.PrimaryPart
	if not parteAnclar then
		parteAnclar = nodoModelo:FindFirstChildWhichIsA("BasePart")
	end
	
	if parteAnclar then
		billboard.Adornee = parteAnclar
		billboard.Parent = parteAnclar
	else
		billboard.Parent = nodoModelo
	end
	
	-- Animacion de entrada
	billboard.Enabled = true
	
	billboardsActivos[nodoModelo] = billboard
	return billboard
end

-- Destruir billboard de un nodo
function BillboardNombres.destruir(nodoModelo)
	local billboard = billboardsActivos[nodoModelo]
	if billboard and billboard.Parent then
		billboard:Destroy()
	end
	billboardsActivos[nodoModelo] = nil
end

-- Destruir todos los billboards
function BillboardNombres.destruirTodos()
	for nodo, billboard in pairs(billboardsActivos) do
		if billboard and billboard.Parent then
			billboard:Destroy()
		end
	end
	billboardsActivos = {}
end

return BillboardNombres
