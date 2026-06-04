-- StarterPlayerScripts/HUD/ModulosHUD/SelectorModosHUD.lua
-- Maneja el visual del SelectorModos: tamaños, textos y colores según modo activo.

local SelectorModosHUD = {}

-- ════════════════════════════════════════════════════════════════
-- ESTADO
-- ════════════════════════════════════════════════════════════════
local _selector = nil
local _botones  = {}
local _modoActual = "visual"  -- visual | matriz | analisis

-- ════════════════════════════════════════════════════════════════
-- COLORES
-- ════════════════════════════════════════════════════════════════
local C = {
	inactivoBg   = Color3.fromRGB(17, 28, 46),
	inactivoText = Color3.fromRGB(100, 116, 139),
	activoText   = Color3.fromRGB(255, 255, 255),
	visual       = Color3.fromRGB(0, 207, 255),   -- cyan
	matriz       = Color3.fromRGB(52, 152, 219),  -- blue
	analisis     = Color3.fromRGB(124, 58, 237),  -- purple
}

-- ════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN VISUAL
-- ════════════════════════════════════════════════════════════════
local CONFIG = {
	botonTextSize = 18,
	botonSize     = UDim2.new(0, 110, 0, 44),
	selectorSize  = UDim2.new(0, 0, 0, 52),  -- AutomaticSize X
}

-- ════════════════════════════════════════════════════════════════
-- FUNCIONES PRIVADAS
-- ════════════════════════════════════════════════════════════════
local function _ajustarBoton(btn)
	if not btn then return end
	btn.TextSize = CONFIG.botonTextSize
	btn.Size = CONFIG.botonSize
	btn.Font = Enum.Font.GothamBold
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = true
end

local function _aplicarEstilo(btn, activo, colorActivo)
	if not btn then return end
	if activo then
		btn.BackgroundColor3 = colorActivo
		btn.TextColor3 = C.activoText
	else
		btn.BackgroundColor3 = C.inactivoBg
		btn.TextColor3 = C.inactivoText
	end
end

local function _refrescarVisual()
	_aplicarEstilo(_botones.visual,   _modoActual == "visual",   C.visual)
	_aplicarEstilo(_botones.matriz,   _modoActual == "matriz",   C.matriz)
	_aplicarEstilo(_botones.analisis, _modoActual == "analisis", C.analisis)
end

-- ════════════════════════════════════════════════════════════════
-- API PÚBLICA
-- ════════════════════════════════════════════════════════════════

function SelectorModosHUD.init(hudGui)
	_selector = hudGui:FindFirstChild("SelectorModos", true)
	if not _selector then
		warn("[SelectorModosHUD] SelectorModos no encontrado")
		return
	end

	-- Referencias
	_botones.visual   = _selector:FindFirstChild("VisualBtn")
	_botones.matriz   = _selector:FindFirstChild("MatrizBtn")
	_botones.analisis = _selector:FindFirstChild("AnalisisBtn")

	-- Ajustar tamaño del selector
	_selector.AutomaticSize = Enum.AutomaticSize.X
	_selector.Size = CONFIG.selectorSize

	-- Ajustar tamaño y texto de los 3 botones
	for _, btn in pairs(_botones) do
		_ajustarBoton(btn)
	end

	-- Aplicar estilo inicial
	_modoActual = "visual"
	_refrescarVisual()

	print("[SelectorModosHUD] Inicializado — modo:", _modoActual)
end

function SelectorModosHUD.setModoActivo(modo)
	if modo ~= "visual" and modo ~= "matriz" and modo ~= "analisis" then
		warn("[SelectorModosHUD] Modo inválido:", modo)
		return
	end
	_modoActual = modo
	_refrescarVisual()
end

function SelectorModosHUD.obtenerModoActivo()
	return _modoActual
end

return SelectorModosHUD
