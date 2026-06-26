-- SelectorAlgUI.lua
-- Interfaz de seleccion de algoritmos con estilo profesional.
-- Requisitos: responsive, pills uniformes, color por algoritmo, hover glow, BtnCerrar funcional.

local TweenService = game:GetService("TweenService")
local Players      = game:GetService("Players")

local SelectorAlgUI = {}

-- ════════════════════════════════════════════════════════════════
-- ESTADO
-- ════════════════════════════════════════════════════════════════
local estado = {
	hudGui      = nil,
	selectorAlg = nil,
	panel       = nil,
	pillsFrame  = nil,
	pills       = {},
	enPantalla  = false,
	modoGuiado  = true,
	btnToggle   = nil,
	onToggleModo = nil,
}

local PILL_NAMES = {
	bfs      = "PillBFS",
	dfs      = "PillDFS",
	dijkstra = "PillDijkstra",
	prim     = "PillPrim",
}

-- Colores distintivos por algoritmo
local COLORES_ALGORITMO = {
	bfs      = { main = Color3.fromRGB(37, 99, 235),  glow = Color3.fromRGB(96, 165, 250) },  -- Azul
	dfs      = { main = Color3.fromRGB(220, 38, 38),  glow = Color3.fromRGB(248, 113, 113) }, -- Rojo
	dijkstra = { main = Color3.fromRGB(234, 179, 8),  glow = Color3.fromRGB(250, 204, 21) },  -- Amarillo/Dorado
	prim     = { main = Color3.fromRGB(34, 197, 94),  glow = Color3.fromRGB(74, 222, 128) },  -- Verde
}

-- ════════════════════════════════════════════════════════════════
-- CONFIGURACION VISUAL
-- ════════════════════════════════════════════════════════════════
local TWEEN_APARECER  = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TWEEN_DESAPARECER = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local TWEEN_HOVER_IN  = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_HOVER_OUT = TweenInfo.new(0.2,  Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local COL_MODO_GUIADO     = Color3.fromRGB(59, 130, 246)  -- azul
local COL_MODO_EJECUCION  = Color3.fromRGB(100, 116, 139) -- gris

-- ════════════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════════════
local function limpiarHijos(tipo, parent)
	if not parent then return end
	for _, c in ipairs(parent:GetChildren()) do
		if c:IsA(tipo) then c:Destroy() end
	end
end

-- ════════════════════════════════════════════════════════════════
-- ESTILIZAR PANEL PRINCIPAL
-- ════════════════════════════════════════════════════════════════
local function estilizarPanel()
	local panel = estado.panel
	if not panel then return end

	panel.BackgroundColor3     = Color3.fromRGB(15, 23, 42)
	panel.BackgroundTransparency = 0.12
	panel.BorderSizePixel      = 0

	-- Esquinas redondeadas
	local corner = panel:FindFirstChildOfClass("UICorner")
	if not corner then
		corner = Instance.new("UICorner")
		corner.Parent = panel
	end
	corner.CornerRadius = UDim.new(0, 14)

	-- Borde sutil con brillo
	local stroke = panel:FindFirstChildOfClass("UIStroke")
	if not stroke then
		stroke = Instance.new("UIStroke")
		stroke.Parent = panel
	end
	stroke.Color        = Color3.fromRGB(99, 102, 241)
	stroke.Thickness    = 1.5
	stroke.Transparency = 0.35

	-- Sombra sutil (usando un frame debajo o UIGradient en el fondo)
	local fondo = panel:FindFirstChild("FondoSombra")
	if not fondo then
		fondo = Instance.new("Frame")
		fondo.Name = "FondoSombra"
		fondo.ZIndex = 0
		fondo.Size = UDim2.new(1, 0, 1, 0)
		fondo.BackgroundTransparency = 1
		fondo.Parent = panel
	end

	-- Panel ocupa todo el SelectorAlg
	panel.Size = UDim2.new(1, 0, 1, 0)

	-- Padding interno del panel (simulado manualmente en hijos)
	local pad = panel:FindFirstChildOfClass("UIPadding")
	if pad then pad:Destroy() end  -- Eliminamos UIPadding para evitar conflictos con posiciones absolutas

	-- ELIMINAR cualquier UIListLayout vertical que haya en el panel (causa el desastre)
	for _, child in ipairs(panel:GetChildren()) do
		if child:IsA("UIListLayout") then child:Destroy() end
	end
end

-- ════════════════════════════════════════════════════════════════
-- TOGGLE MODO GUIADO / EJECUCION
-- ════════════════════════════════════════════════════════════════
local function actualizarTextoToggle()
	if not estado.btnToggle then return end
	estado.btnToggle.Text = estado.modoGuiado and "Modo: Guiado" or "Modo: Ejecución"
	estado.btnToggle.BackgroundColor3 = estado.modoGuiado and COL_MODO_GUIADO or COL_MODO_EJECUCION
end

local function crearToggleModo()
	if not estado.panel then return end

	local btn = estado.panel:FindFirstChild("BtnToggleModo")
	if not btn then
		btn = Instance.new("TextButton")
		btn.Name = "BtnToggleModo"
		btn.Parent = estado.panel
	end

	btn.Size = UDim2.new(1, -28, 0, 26) 
    btn.Position = UDim2.new(0, 14, 0, 44)
	btn.BackgroundTransparency = 0.15
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = 13
	btn.Font = Enum.Font.GothamBold
	btn.AutoButtonColor = false
	btn.BorderSizePixel = 0
	btn.ZIndex = 2

	local corner = btn:FindFirstChildOfClass("UICorner")
	if not corner then
		corner = Instance.new("UICorner")
		corner.Parent = btn
	end
	corner.CornerRadius = UDim.new(0, 8)

	local stroke = btn:FindFirstChildOfClass("UIStroke")
	if not stroke then
		stroke = Instance.new("UIStroke")
		stroke.Parent = btn
	end
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 0.5
	stroke.Thickness = 1

	actualizarTextoToggle()

	btn.MouseButton1Click:Connect(function()
		estado.modoGuiado = not estado.modoGuiado
		actualizarTextoToggle()
		if estado.onToggleModo then
			estado.onToggleModo(estado.modoGuiado)
		end
	end)

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TWEEN_HOVER_IN, { BackgroundTransparency = 0.05 }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TWEEN_HOVER_OUT, { BackgroundTransparency = 0.15 }):Play()
	end)

	estado.btnToggle = btn
end

-- ════════════════════════════════════════════════════════════════
-- ESTILIZAR ENCABEZADO
-- ════════════════════════════════════════════════════════════════
local function estilizarEncabezado()
	local encabezado = estado.panel and estado.panel:FindFirstChild("EncabezadoAnalisis")
	if not encabezado then return end

	encabezado.BackgroundTransparency = 1
	encabezado.Size = UDim2.new(1, -28, 0, 28)
	encabezado.Position = UDim2.new(0, 14, 0, 10)  -- padding manual: 14 izq, 10 arriba
	encabezado.LayoutOrder = 0

	local pad = encabezado:FindFirstChildOfClass("UIPadding")
	if not pad then
		pad = Instance.new("UIPadding")
		pad.Parent = encabezado
	end
	pad.PaddingLeft   = UDim.new(0, 2)
	pad.PaddingRight  = UDim.new(0, 2)
	pad.PaddingBottom = UDim.new(0, 6)

	-- Titulo (si no existe, lo creamos)
	local titulo = encabezado:FindFirstChild("TituloSelector")
	if not titulo then
		titulo = Instance.new("TextLabel")
		titulo.Name = "TituloSelector"
		titulo.Text = "Selecciona un algoritmo"
		titulo.Font = Enum.Font.GothamBold
		titulo.TextSize = 14
		titulo.TextColor3 = Color3.fromRGB(226, 232, 240)
		titulo.TextXAlignment = Enum.TextXAlignment.Left
		titulo.TextYAlignment = Enum.TextYAlignment.Center
		titulo.BackgroundTransparency = 1
		titulo.Size = UDim2.new(1, -40, 1, 0)
		titulo.Parent = encabezado
	end

	-- Boton cerrar
	local btnCerrar = encabezado:FindFirstChild("BtnCerrarSelector")
	if not btnCerrar then
		btnCerrar = Instance.new("TextButton")
		btnCerrar.Name = "BtnCerrarSelector"
		btnCerrar.Text = "✕"
		btnCerrar.Parent = encabezado
	end
	btnCerrar.Size            = UDim2.new(0, 26, 0, 26)
	btnCerrar.Position        = UDim2.new(1, -28, 0, 0)
	btnCerrar.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
	btnCerrar.BackgroundTransparency = 0.15
	btnCerrar.TextColor3      = Color3.fromRGB(255, 255, 255)
	btnCerrar.TextSize        = 14
	btnCerrar.Font            = Enum.Font.GothamBold
	btnCerrar.AutoButtonColor = false
	btnCerrar.BorderSizePixel = 0

	local corner = btnCerrar:FindFirstChildOfClass("UICorner")
	if not corner then
		corner = Instance.new("UICorner")
		corner.Parent = btnCerrar
	end
	corner.CornerRadius = UDim.new(0, 7)

	-- Hover del boton cerrar
	btnCerrar.MouseEnter:Connect(function()
		TweenService:Create(btnCerrar, TWEEN_HOVER_IN, { BackgroundColor3 = Color3.fromRGB(220, 38, 38), Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(1, -30, 0, -1) }):Play()
	end)
	btnCerrar.MouseLeave:Connect(function()
		TweenService:Create(btnCerrar, TWEEN_HOVER_OUT, { BackgroundColor3 = Color3.fromRGB(239, 68, 68), Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(1, -28, 0, 0) }):Play()
	end)
end

-- ════════════════════════════════════════════════════════════════
-- ESTILIZAR PILLS
-- ════════════════════════════════════════════════════════════════
local function estilizarPills()
	local frame = estado.pillsFrame
	if not frame then return end

	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1, -28, 0, 40)
	frame.Position = UDim2.new(0, 14, 0, 76) 
	frame.LayoutOrder = 1

	-- Layout horizontal centrado
	local list = frame:FindFirstChildOfClass("UIListLayout")
	if not list then
		list = Instance.new("UIListLayout")
		list.Parent = frame
	end
	list.FillDirection       = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment   = Enum.VerticalAlignment.Center
	list.Padding             = UDim.new(0, 10)

	-- Asegurar que haya un UIAspectRatioConstraint en el contenedor padre para responsiveness
	local selector = estado.selectorAlg
	if selector then
		local scale = selector:FindFirstChildOfClass("UIScale")
		if not scale then
			scale = Instance.new("UIScale")
			scale.Scale = 1
			scale.Parent = selector
		end
	end

	-- Estilizar cada pill
	for algoId, nombre in pairs(PILL_NAMES) do
		local pill = frame:FindFirstChild(nombre)
		if pill then
			estado.pills[algoId] = pill

			local colores = COLORES_ALGORITMO[algoId]
			if not colores then continue end

			-- Tamano uniforme
			pill.Size = UDim2.new(0, 82, 0, 36)
			pill.BackgroundColor3 = colores.main
			pill.BackgroundTransparency = 0.15
			pill.TextColor3 = Color3.fromRGB(255, 255, 255)
			pill.TextSize = 13
			pill.Font = Enum.Font.GothamBold
			pill.AutoButtonColor = false
			pill.BorderSizePixel = 0
			pill.TextScaled = false
			pill.ClipsDescendants = true

			-- Esquinas redondeadas
			local pc = pill:FindFirstChildOfClass("UICorner")
			if not pc then
				pc = Instance.new("UICorner")
				pc.Parent = pill
			end
			pc.CornerRadius = UDim.new(0, 9)

			-- Borde sutil con color del algoritmo
			local ps = pill:FindFirstChildOfClass("UIStroke")
			if not ps then
				ps = Instance.new("UIStroke")
				ps.Parent = pill
			end
			ps.Color = colores.glow
			ps.Thickness = 1.2
			ps.Transparency = 0.4

			-- Glow interno (frame detrás del texto para efecto hover)
			local glow = pill:FindFirstChild("GlowHover")
			if not glow then
				glow = Instance.new("Frame")
				glow.Name = "GlowHover"
				glow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				glow.BackgroundTransparency = 1
				glow.BorderSizePixel = 0
				glow.Size = UDim2.new(1, 0, 1, 0)
				glow.ZIndex = 0
				glow.Parent = pill
				local gc = Instance.new("UICorner")
				gc.CornerRadius = pc.CornerRadius
				gc.Parent = glow
			end

			-- HOVER: Glow blanco semi-transparente + ligero scale up
			pill.MouseEnter:Connect(function()
				TweenService:Create(pill, TWEEN_HOVER_IN, { Size = UDim2.new(0, 86, 0, 38), BackgroundTransparency = 0.05 }):Play()
				TweenService:Create(glow, TWEEN_HOVER_IN, { BackgroundTransparency = 0.75 }):Play()
				TweenService:Create(ps, TWEEN_HOVER_IN, { Transparency = 0.1, Thickness = 2 }):Play()
			end)

			pill.MouseLeave:Connect(function()
				TweenService:Create(pill, TWEEN_HOVER_OUT, { Size = UDim2.new(0, 82, 0, 36), BackgroundTransparency = 0.15 }):Play()
				TweenService:Create(glow, TWEEN_HOVER_OUT, { BackgroundTransparency = 1 }):Play()
				TweenService:Create(ps, TWEEN_HOVER_OUT, { Transparency = 0.4, Thickness = 1.2 }):Play()
			end)
		end
	end
end

-- ════════════════════════════════════════════════════════════════
-- POSICION RESPONSIVA
-- ════════════════════════════════════════════════════════════════
local function calcularPosicionResponsiva(pillsVisibles)
    pillsVisibles = pillsVisibles or 4
    local ancho = math.clamp(pillsVisibles * 92 + 48, 280, 420)
    local alto  = 130
    return UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0, ancho, 0, alto)
end

-- ════════════════════════════════════════════════════════════════
-- API PUBLICA
-- ════════════════════════════════════════════════════════════════
function SelectorAlgUI.inicializar(hudGui)
	estado.hudGui = hudGui
	estado.selectorAlg = hudGui:FindFirstChild("SelectorAlg", true)
	if not estado.selectorAlg then
		warn("[SelectorAlgUI] SelectorAlg no encontrado en HUD")
		return
	end

	estado.panel = estado.selectorAlg:FindFirstChild("PanelAnalisis")
	estado.pillsFrame = estado.panel and estado.panel:FindFirstChild("PillsAlgo")

	-- Posicion inicial responsiva
	local pos, size = calcularPosicionResponsiva()
	estado.selectorAlg.Position = pos
	estado.selectorAlg.Size     = size
	estado.selectorAlg.AnchorPoint = Vector2.new(0.5, 0.5)
	estado.selectorAlg.Visible  = false
	estado.selectorAlg.BackgroundTransparency = 1

	estilizarPanel()
	crearToggleModo()
	estilizarEncabezado()
	estilizarPills()

	-- Recalcular posicion si cambia el viewport (siempre centrado)
	local function recalcular()
		if not estado.enPantalla then return end
		local pillsVisibles = 0
		for _, pill in pairs(estado.pills) do
			if pill and pill.Visible then pillsVisibles = pillsVisibles + 1 end
		end
		local _, nuevaSize = calcularPosicionResponsiva(pillsVisibles)
		TweenService:Create(estado.selectorAlg, TweenInfo.new(0.2), { Size = nuevaSize }):Play()
	end

	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(recalcular)
	end

	print("[SelectorAlgUI] Inicializado ")
end

function SelectorAlgUI.mostrar(algoritmos)
	if not estado.selectorAlg then return end

	-- Filtrar pills segun algoritmos permitidos
	for id, pill in pairs(estado.pills) do
		if pill then
			local visible = (algoritmos == nil)
			if not visible and algoritmos then
				for _, a in ipairs(algoritmos) do
					if a == id then visible = true; break end
				end
			end
			pill.Visible = visible
		end
	end

	-- Calcular ancho dinamico basado en pills visibles
	local pillsVisibles = 0
	for _, pill in pairs(estado.pills) do
		if pill and pill.Visible then pillsVisibles = pillsVisibles + 1 end
	end
	-- Resetear a modo guiado cada vez que se abre el selector
	estado.modoGuiado = true
	actualizarTextoToggle()

	local pos, nuevoSize = calcularPosicionResponsiva(pillsVisibles)

	-- Animacion de entrada
	local scale = estado.selectorAlg:FindFirstChildOfClass("UIScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Parent = estado.selectorAlg
	end
	scale.Scale = 0.85

	estado.selectorAlg.Position = pos
	estado.selectorAlg.Size     = nuevoSize
	estado.selectorAlg.Visible  = true
	estado.enPantalla = true

	TweenService:Create(scale, TWEEN_APARECER, { Scale = 1 }):Play()
end

function SelectorAlgUI.ocultar()
	if not estado.selectorAlg or not estado.enPantalla then return end

	local scale = estado.selectorAlg:FindFirstChildOfClass("UIScale")
	if scale then
		local tween = TweenService:Create(scale, TWEEN_DESAPARECER, { Scale = 0.85 })
		tween.Completed:Connect(function()
			if not estado.enPantalla then
				estado.selectorAlg.Visible = false
			end
		end)
		tween:Play()
	else
		estado.selectorAlg.Visible = false
	end
	estado.enPantalla = false
end

function SelectorAlgUI.estaVisible()
	return estado.enPantalla
end

function SelectorAlgUI.conectarCerrar(callback)
	local btn = estado.panel
		and estado.panel:FindFirstChild("EncabezadoAnalisis")
		and estado.panel.EncabezadoAnalisis:FindFirstChild("BtnCerrarSelector")
	if btn and callback then
		-- Limpiar conexiones anteriores si las hay (evitar duplicados)
		btn.MouseButton1Click:Connect(callback)
	end
end

function SelectorAlgUI.conectarPill(algo, callback)
	local pill = estado.pills[algo]
	if pill and callback then
		pill.MouseButton1Click:Connect(callback)
	end
end

function SelectorAlgUI.estaModoGuiado()
	return estado.modoGuiado
end

function SelectorAlgUI.establecerModoGuiado(valor)
	estado.modoGuiado = (valor ~= false)
	actualizarTextoToggle()
end

function SelectorAlgUI.conectarToggle(callback)
	estado.onToggleModo = callback
end

return SelectorAlgUI
