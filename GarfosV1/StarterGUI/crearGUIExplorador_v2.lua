--!nocheck
-- ================================================================
-- crearGUIExplorador_v2 — GUI Unificada (Sprint 2)
-- ✅ LISTO PARA PEGAR EN EL COMMAND BAR DE ROBLOX STUDIO
-- ================================================================

-- ════════════════════════════════════════════════════════════════
-- PALETA DE COLORES
-- ════════════════════════════════════════════════════════════════
local C = {
	FondoBase  = Color3.fromRGB(8,  10, 15),
	FondoSurf  = Color3.fromRGB(14, 16, 22),
	FondoCard  = Color3.fromRGB(20, 23, 32),
	FondoEl    = Color3.fromRGB(26, 30, 42),

	Borde      = Color3.fromRGB(255, 255, 255),

	Texto1     = Color3.fromRGB(232, 238, 245),
	Texto2     = Color3.fromRGB(106, 122, 138),
	Texto3     = Color3.fromRGB(58,  74,  90),

	Verde      = Color3.fromRGB(62,  207, 142),
	Azul       = Color3.fromRGB(75,  157, 232),
	Naranja    = Color3.fromRGB(232, 147, 75),
	Violeta    = Color3.fromRGB(123, 110, 246),
	Oro        = Color3.fromRGB(245, 200, 66),
	Rojo       = Color3.fromRGB(224, 92,  92),
	Aviso      = Color3.fromRGB(232, 194, 75),
}

-- ════════════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════════════

local function frame(name, parent, size, pos, color, trans)
	local f         = Instance.new("Frame")
	f.Name          = name
	f.Size          = size
	f.Position      = pos or UDim2.new(0, 0, 0, 0)
	f.BackgroundColor3 = color or C.FondoCard
	f.BackgroundTransparency = trans or 0
	f.BorderSizePixel = 0
	f.ClipsDescendants = false
	f.Parent        = parent
	return f
end

local function corner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = parent
end

local function stroke(parent, color, thick, trans)
	local s = Instance.new("UIStroke")
	s.Color       = color or C.Borde
	s.Thickness   = thick or 1
	s.Transparency = trans or 0.87
	s.Parent      = parent
	return s
end

local function pad(parent, all, t, b, l, r)
	local p = Instance.new("UIPadding")
	p.PaddingTop    = UDim.new(0, t or all or 0)
	p.PaddingBottom = UDim.new(0, b or all or 0)
	p.PaddingLeft   = UDim.new(0, l or all or 0)
	p.PaddingRight  = UDim.new(0, r or all or 0)
	p.Parent = parent
end

local function label(name, parent, text, size, pos, font, ts, color, wrap, xa)
	local l = Instance.new("TextLabel")
	l.Name          = name
	l.Size          = size
	l.Position      = pos or UDim2.new(0, 0, 0, 0)
	l.Text          = text
	l.Font          = font or Enum.Font.GothamBold
	l.TextSize      = ts or 13
	l.TextColor3    = color or C.Texto1
	l.BackgroundTransparency = 1
	l.BorderSizePixel = 0
	l.TextWrapped   = wrap or false
	l.TextXAlignment = xa or Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.Parent        = parent
	return l
end

local function btn(name, parent, text, size, pos, bg, bgT, tc, font, ts)
	local b = Instance.new("TextButton")
	b.Name          = name
	b.Size          = size
	b.Position      = pos or UDim2.new(0, 0, 0, 0)
	b.Text          = text
	b.Font          = font or Enum.Font.GothamBold
	b.TextSize      = ts or 12
	b.TextColor3    = tc or C.Texto1
	b.BackgroundColor3 = bg or C.FondoEl
	b.BackgroundTransparency = bgT or 0
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	b.Parent        = parent
	return b
end

local function hlist(parent, padding)
	local l = Instance.new("UIListLayout")
	l.FillDirection        = Enum.FillDirection.Horizontal
	l.SortOrder            = Enum.SortOrder.LayoutOrder
	l.Padding              = UDim.new(0, padding or 5)
	l.VerticalAlignment    = Enum.VerticalAlignment.Center
	l.Parent = parent
	return l
end

local function vlist(parent, padding)
	local l = Instance.new("UIListLayout")
	l.FillDirection        = Enum.FillDirection.Vertical
	l.SortOrder            = Enum.SortOrder.LayoutOrder
	l.Padding              = UDim.new(0, padding or 4)
	l.Parent = parent
	return l
end

local function scroll(name, parent, size, pos)
	local s = Instance.new("ScrollingFrame")
	s.Name                  = name
	s.Size                  = size
	s.Position              = pos or UDim2.new(0, 0, 0, 0)
	s.BackgroundTransparency = 1
	s.BorderSizePixel       = 0
	s.ScrollBarThickness    = 3
	s.ScrollBarImageColor3  = C.Texto2
	s.CanvasSize            = UDim2.new(0, 0, 0, 0)
	s.AutomaticCanvasSize   = Enum.AutomaticSize.Y
	s.Parent                = parent
	return s
end

-- ════════════════════════════════════════════════════════════════
-- CONSTRUCCIÓN DE LA GUI
-- ════════════════════════════════════════════════════════════════

-- ── ScreenGui ───────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name             = "GUIExploradorV2"
gui.ResetOnSpawn     = false
gui.IgnoreGuiInset   = true
gui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
gui.Enabled          = true

-- ════════════════════════════════════════════════════════════════
-- 1. BARRA SUPERIOR (BarraSuperior)
-- ════════════════════════════════════════════════════════════════
local topBar = frame("BarraSuperior", gui,
	UDim2.new(1, 0, 0, 52), UDim2.new(0, 0, 0, 0),
	C.FondoBase, 0.06)
stroke(topBar, C.Borde, 1, 0.9)

-- Helper para compatibilidad con GUIExplorador.lua (busca "Titulo" directo)
local tituloHidden = label("Titulo", topBar,
	"📊 Explorador de Grafos",
	UDim2.new(0, 0, 0, 0), UDim2.new(0, 0, 0, 0),
	Enum.Font.GothamBold, 1, C.Texto1)
tituloHidden.Visible = false

-- ── Badge de título (izquierda) ─────────────────────────────────
local titleBadge = frame("TitleBadge", topBar,
	UDim2.new(0, 210, 1, -14), UDim2.new(0, 10, 0, 7),
	C.FondoEl, 0)
corner(titleBadge, 8)
stroke(titleBadge, C.Borde, 1, 0.87)
pad(titleBadge, nil, 0, 0, 10, 8)

label("IconoJuego", titleBadge, "📊",
	UDim2.new(0, 20, 1, 0), UDim2.new(0, 0, 0, 0),
	Enum.Font.GothamBold, 16, C.Texto1)

local titleStack = frame("TitleStack", titleBadge,
	UDim2.new(1, -26, 1, 0), UDim2.new(0, 24, 0, 0), C.FondoEl, 1)

label("NombreJuego", titleStack, "Explorador de Grafos",
	UDim2.new(1, 0, 0.55, 0), UDim2.new(0, 0, 0, 0),
	Enum.Font.GothamBold, 13, C.Texto1)

label("SubTitulo", titleStack, "Zona 1 — Estación",
	UDim2.new(1, 0, 0.45, 0), UDim2.new(0, 0, 0.55, 0),
	Enum.Font.Gotham, 9, C.Texto2)

-- ── Panel de puntuación (centro) ────────────────────────────────
local scorePanel = frame("PanelPuntuacion", topBar,
	UDim2.new(0, 270, 1, -14), UDim2.new(0.5, -135, 0, 7),
	C.FondoEl, 1)
hlist(scorePanel, 5)

-- Chip Estrellas
local chipEst = frame("ContenedorEstrellas", scorePanel,
	UDim2.new(0, 86, 1, 0), nil, C.FondoCard, 0)
chipEst.LayoutOrder = 1
corner(chipEst, 7)
stroke(chipEst, C.Borde, 1, 0.87)
pad(chipEst, nil, 0, 0, 8, 6)
label("Icono", chipEst, "⭐",
	UDim2.new(0, 14, 0.55, 0), UDim2.new(0, 0, 0, 0),
	Enum.Font.GothamBold, 13, C.Texto1)
label("Valor", chipEst, "☆☆☆",
	UDim2.new(1, -14, 0.55, 0), UDim2.new(0, 16, 0, 0),
	Enum.Font.GothamBold, 14, C.Oro)
label("Etiqueta", chipEst, "ESTRELLAS",
	UDim2.new(1, -14, 0.45, 0), UDim2.new(0, 16, 0.55, 0),
	Enum.Font.Gotham, 7, C.Texto2)

-- Chip Puntos
local chipPts = frame("ContenedorPuntos", scorePanel,
	UDim2.new(0, 86, 1, 0), nil, C.FondoCard, 0)
chipPts.LayoutOrder = 2
corner(chipPts, 7)
stroke(chipPts, C.Borde, 1, 0.87)
pad(chipPts, nil, 0, 0, 8, 6)
label("Icono", chipPts, "🏆",
	UDim2.new(0, 14, 0.55, 0), UDim2.new(0, 0, 0, 0),
	Enum.Font.GothamBold, 13, C.Texto1)
label("Valor", chipPts, "0",
	UDim2.new(1, -14, 0.55, 0), UDim2.new(0, 16, 0, 0),
	Enum.Font.GothamBold, 14, C.Azul)
label("Etiqueta", chipPts, "PUNTOS",
	UDim2.new(1, -14, 0.45, 0), UDim2.new(0, 16, 0.55, 0),
	Enum.Font.Gotham, 7, C.Texto2)

-- Chip Dinero
local chipDin = frame("ContenedorDinero", scorePanel,
	UDim2.new(0, 86, 1, 0), nil, C.FondoCard, 0)
chipDin.LayoutOrder = 3
corner(chipDin, 7)
stroke(chipDin, C.Borde, 1, 0.87)
pad(chipDin, nil, 0, 0, 8, 6)
label("Icono", chipDin, "💰",
	UDim2.new(0, 14, 0.55, 0), UDim2.new(0, 0, 0, 0),
	Enum.Font.GothamBold, 13, C.Texto1)
label("Valor", chipDin, "$0",
	UDim2.new(1, -14, 0.55, 0), UDim2.new(0, 16, 0, 0),
	Enum.Font.GothamBold, 14, C.Verde)
label("Etiqueta", chipDin, "DINERO",
	UDim2.new(1, -14, 0.45, 0), UDim2.new(0, 16, 0.55, 0),
	Enum.Font.Gotham, 7, C.Texto2)

-- ── Botones de acción (derecha) ──────────────────────────────────
local secBar = frame("BarraBotonesSecundarios", topBar,
	UDim2.new(0, 178, 1, -14), UDim2.new(1, -188, 0, 7),
	C.FondoEl, 1)
hlist(secBar, 6)

local btnRein = btn("BtnReiniciar", secBar, "🔄 Reiniciar",
	UDim2.new(0, 86, 1, 0), nil,
	Color3.fromRGB(45, 36, 8), 0, C.Aviso)
btnRein.LayoutOrder = 1
corner(btnRein, 7)
stroke(btnRein, C.Aviso, 1, 0.68)

local btnFin = btn("BtnFinalizar", secBar, "✓ Finalizar",
	UDim2.new(0, 86, 1, 0), nil,
	Color3.fromRGB(8, 42, 22), 0, C.Verde)
btnFin.LayoutOrder = 2
btnFin.Visible = false
corner(btnFin, 7)
stroke(btnFin, C.Verde, 1, 0.62)

-- ════════════════════════════════════════════════════════════════
-- 2. BARRA BOTONES MAIN
-- ════════════════════════════════════════════════════════════════
local mainBar = frame("BarraBotonesMain", gui,
	UDim2.new(0, 180, 0, 40), UDim2.new(0, 12, 0, 58),
	C.FondoBase, 0.06)
corner(mainBar, 10)
stroke(mainBar, C.Borde, 1, 0.87)
pad(mainBar, 5)
hlist(mainBar, 5)

local btnMapa = btn("BtnMapa", mainBar, "🗺️ Mapa",
	UDim2.new(0, 79, 1, -10), nil,
	Color3.fromRGB(8, 36, 22), 0, C.Verde)
btnMapa.LayoutOrder = 1
corner(btnMapa, 7)
stroke(btnMapa, C.Verde, 1, 0.72)

local btnMis = btn("BtnMisiones", mainBar, "📌 Misiones",
	UDim2.new(0, 86, 1, -10), nil,
	Color3.fromRGB(18, 12, 46), 0, C.Violeta)
btnMis.LayoutOrder = 2
corner(btnMis, 7)
stroke(btnMis, C.Violeta, 1, 0.72)

local btnAlgoCompat = btn("BtnAlgoritmo", mainBar, "",
	UDim2.new(0, 0, 0, 0), nil, C.FondoBase, 1, C.Naranja)
btnAlgoCompat.Visible      = false
btnAlgoCompat.LayoutOrder  = 98

local btnMatrizCompat = btn("BtnMatriz", mainBar, "",
	UDim2.new(0, 0, 0, 0), nil, C.FondoBase, 1, C.Azul)
btnMatrizCompat.Visible     = false
btnMatrizCompat.LayoutOrder = 99

-- ════════════════════════════════════════════════════════════════
-- 3. SELECTOR DE MODOS (SelectorModos)
-- ════════════════════════════════════════════════════════════════
local modeSel = frame("SelectorModos", gui,
	UDim2.new(0, 298, 0, 42), UDim2.new(0, 12, 1, -54),
	C.FondoBase, 0.06)
corner(modeSel, 10)
stroke(modeSel, C.Borde, 1, 0.87)
pad(modeSel, 4)
hlist(modeSel, 3)

local function modeBtn(nombre, texto, color, order, active)
	local b = btn(nombre, modeSel, texto,
		UDim2.new(0, 94, 1, -8), nil,
		active and Color3.fromRGB(8, 34, 20) or C.FondoEl,
		active and 0 or 0.5,
		active and color or C.Texto2)
	b.LayoutOrder = order
	b.TextSize    = 10
	corner(b, 7)
	stroke(b, color, 1, active and 0.72 or 1)
	return b
end

modeBtn("VisualBtn",   "● Visual",     C.Verde,   1, true)
modeBtn("MatrizBtn",   "● Matemático", C.Azul,    2, false)
modeBtn("AnalisisBtn", "● Análisis",   C.Naranja, 3, false)

-- ════════════════════════════════════════════════════════════════
-- 4. MINIMAPA (ContenedorMiniMapa)
-- ════════════════════════════════════════════════════════════════
local minimap = frame("ContenedorMiniMapa", gui,
	UDim2.new(0, 200, 0, 192), UDim2.new(1, -212, 1, -204),
	C.FondoBase, 0.06)
minimap.ClipsDescendants = true
corner(minimap, 10)
stroke(minimap, C.Verde, 1, 0.80)

local mmHead = frame("Header", minimap,
	UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 0),
	Color3.fromRGB(8, 36, 22), 0)
pad(mmHead, nil, 0, 0, 10, 0)
label("Titulo", mmHead, "● MINIMAPA",
	UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0),
	Enum.Font.GothamBold, 9, C.Verde)

local visor = Instance.new("ViewportFrame")
visor.Name                  = "Visor"
visor.Size                  = UDim2.new(1, 0, 0, 130)
visor.Position              = UDim2.new(0, 0, 0, 24)
visor.BackgroundColor3      = Color3.fromRGB(4, 8, 14)
visor.BackgroundTransparency = 0
visor.BorderSizePixel       = 0
visor.Parent                = minimap

local mmFoot = frame("PanelInfoGrafo", minimap,
	UDim2.new(1, 0, 0, 38), UDim2.new(0, 0, 0, 154),
	C.FondoCard, 0)
pad(mmFoot, nil, 4, 4, 6, 6)
hlist(mmFoot, 4)

label("EtiquetaInfoGrafo", mmFoot, "",
	UDim2.new(0, 0, 0, 0), UDim2.new(0, 0, 0, 0),
	Enum.Font.Gotham, 1, C.Texto2).Visible = false

label("EstadisticasGrafo", mmFoot, "",
	UDim2.new(0, 0, 0, 0), UDim2.new(0, 0, 0, 0),
	Enum.Font.Gotham, 1, C.Texto2).Visible = false

local function mmStat(nombre, k, v, order)
	local f = frame(nombre, mmFoot,
		UDim2.new(0, 54, 1, -8), nil, C.FondoEl, 0)
	f.LayoutOrder = order
	corner(f, 5)
	stroke(f, C.Borde, 1, 0.87)
	label("K", f, k, UDim2.new(1, 0, 0.45, 0), UDim2.new(0, 0, 0, 0),
		Enum.Font.Gotham, 7, C.Texto2, false, Enum.TextXAlignment.Center)
	label("V", f, v, UDim2.new(1, 0, 0.55, 0), UDim2.new(0, 0, 0.45, 0),
		Enum.Font.GothamBold, 12, C.Texto1, false, Enum.TextXAlignment.Center)
	return f
end
mmStat("StatNodos",   "NODOS",   "0", 1)
mmStat("StatAristas", "ARISTAS", "0", 2)
mmStat("StatTipo",    "TIPO",    "—", 3)

-- ════════════════════════════════════════════════════════════════
-- 5. PANEL MATEMÁTICO (PanelMatrizAdyacencia)
-- ════════════════════════════════════════════════════════════════
local matPanel = frame("PanelMatrizAdyacencia", gui,
	UDim2.new(0, 258, 1, -104), UDim2.new(1, -270, 0, 58),
	C.FondoBase, 0.04)
matPanel.Visible          = false
matPanel.ClipsDescendants = true
corner(matPanel, 10)
stroke(matPanel, C.Azul, 1, 0.78)

local matHead = frame("MatrizHeader", matPanel,
	UDim2.new(1, 0, 0, 32), UDim2.new(0, 0, 0, 0),
	Color3.fromRGB(4, 16, 36), 0)
pad(matHead, nil, 0, 0, 10, 8)

label("TituloMatriz", matHead, "📋 MATRIZ DE ADYACENCIA",
	UDim2.new(1, -32, 1, 0), UDim2.new(0, 0, 0, 0),
	Enum.Font.GothamBold, 9, C.Azul)

local matClose = btn("BtnCerrarMatriz", matHead, "X",
	UDim2.new(0, 22, 0, 22), UDim2.new(1, -24, 0.5, -11),
	Color3.fromRGB(54, 16, 16), 0, C.Rojo)
corner(matClose, 5)
stroke(matClose, C.Rojo, 1, 0.70)

local nodoInfo = frame("MarcoInfoNodo", matPanel,
	UDim2.new(1, -14, 0, 58), UDim2.new(0, 7, 0, 38),
	Color3.fromRGB(4, 16, 36), 0)
corner(nodoInfo, 7)
stroke(nodoInfo, C.Azul, 1, 0.82)
pad(nodoInfo, nil, 4, 4, 8, 8)

local niGrid = Instance.new("UIGridLayout")
niGrid.CellSize    = UDim2.new(0.5, -4, 0.5, -2)
niGrid.CellPadding = UDim2.new(0, 4, 0, 2)
niGrid.SortOrder   = Enum.SortOrder.LayoutOrder
niGrid.Parent      = nodoInfo

local function niRow(nombre, k, v, order)
	local row = frame(nombre, nodoInfo,
		UDim2.new(0, 0, 0, 0), nil, C.FondoBase, 1)
	row.LayoutOrder = order
	label("K", row, k, UDim2.new(0.45, 0, 1, 0), nil,
		Enum.Font.Gotham, 9, C.Texto2)
	local vLbl = label("V", row, v, UDim2.new(0.55, 0, 1, 0), UDim2.new(0.45, 0, 0, 0),
		Enum.Font.GothamBold, 10, C.Azul)
	return vLbl
end
niRow("FilaNodo",    "Nodo",    "—", 1)
niRow("FilaGrado",   "Grado",   "0", 2)
niRow("FilaEntrada", "Entrada", "0", 3)
niRow("FilaSalida",  "Salida",  "0", 4)

local matScroll = Instance.new("ScrollingFrame")
matScroll.Name                = "CuadriculaMatriz"
matScroll.Size                = UDim2.new(1, -10, 1, -106)
matScroll.Position            = UDim2.new(0, 5, 0, 102)
matScroll.BackgroundTransparency = 1
matScroll.BorderSizePixel     = 0
matScroll.ScrollBarThickness  = 4
matScroll.ScrollBarImageColor3 = C.Azul
matScroll.CanvasSize          = UDim2.new(0, 200, 0, 200)
matScroll.AutomaticCanvasSize = Enum.AutomaticSize.XY
matScroll.Parent              = matPanel

-- ════════════════════════════════════════════════════════════════
-- 6. PANEL DE MISIONES (MisionFrame)
-- ════════════════════════════════════════════════════════════════
local misionFrame = frame("MisionFrame", gui,
	UDim2.new(0, 222, 0, 320), UDim2.new(0, 12, 0, 106),
	C.FondoBase, 0.04)
misionFrame.Visible          = false
misionFrame.ClipsDescendants = true
corner(misionFrame, 10)
stroke(misionFrame, C.Violeta, 1, 0.75)

local misHead = frame("MisHeader", misionFrame,
	UDim2.new(1, 0, 0, 32), UDim2.new(0, 0, 0, 0),
	Color3.fromRGB(18, 10, 46), 0)
pad(misHead, nil, 0, 0, 10, 8)

label("Titulo", misHead, "📋 MISIONES",
	UDim2.new(1, -30, 1, 0), UDim2.new(0, 0, 0, 0),
	Enum.Font.GothamBold, 10, C.Violeta)

local misClose = btn("BtnCerrarMisiones", misHead, "X",
	UDim2.new(0, 22, 0, 22), UDim2.new(1, -24, 0.5, -11),
	Color3.fromRGB(54, 16, 16), 0, C.Rojo)
corner(misClose, 5)
stroke(misClose, C.Rojo, 1, 0.70)

local misBody = scroll("Cuerpo", misionFrame,
	UDim2.new(1, -12, 1, -36), UDim2.new(0, 6, 0, 36))
pad(misBody, 5)
vlist(misBody, 4)

-- ════════════════════════════════════════════════════════════════
-- 7. PANTALLA DE MAPA GRANDE (PantallaMapaGrande)
-- ════════════════════════════════════════════════════════════════
local mapScreen = frame("PantallaMapaGrande", gui,
	UDim2.new(1, 0, 1, -52), UDim2.new(0, 0, 0, 52),
	C.FondoBase, 0.02)
mapScreen.Visible  = false
mapScreen.ZIndex   = 5

local mapHead = frame("MapaHeader", mapScreen,
	UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 0),
	Color3.fromRGB(6, 12, 8), 0)
pad(mapHead, nil, 0, 0, 14, 10)
stroke(mapHead, C.Verde, 1, 0.88)

label("MapaTitulo", mapHead, "● MAPA DEL NIVEL — Zona 1",
	UDim2.new(0.5, 0, 1, 0), UDim2.new(0, 0, 0, 0),
	Enum.Font.GothamBold, 11, C.Texto1)

local mapBtnBar = frame("MapaBotones", mapHead,
	UDim2.new(0, 282, 0, 30), UDim2.new(1, -292, 0.5, -15),
	C.FondoBase, 1)
hlist(mapBtnBar, 6)

local mapBtnMis = btn("BtnMisionesEnMapa", mapBtnBar, "📌 Misiones",
	UDim2.new(0, 88, 1, 0), nil,
	Color3.fromRGB(18, 10, 46), 0, C.Violeta)
mapBtnMis.LayoutOrder = 1
corner(mapBtnMis, 7); stroke(mapBtnMis, C.Violeta, 1, 0.70)

local mapBtnMat = btn("BtnMatematico", mapBtnBar, "📋 Matemático",
	UDim2.new(0, 88, 1, 0), nil,
	Color3.fromRGB(4, 16, 36), 0, C.Azul)
mapBtnMat.LayoutOrder = 2
corner(mapBtnMat, 7); stroke(mapBtnMat, C.Azul, 1, 0.70)

local mapBtnClose = btn("BtnCerrarMapa", mapBtnBar, "X Cerrar",
	UDim2.new(0, 78, 1, 0), nil,
	Color3.fromRGB(54, 12, 12), 0, C.Rojo)
mapBtnClose.LayoutOrder = 3
corner(mapBtnClose, 7); stroke(mapBtnClose, C.Rojo, 1, 0.70)

local mapInfoStrip = frame("MapaInfoStrip", mapScreen,
	UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 0, 40),
	Color3.fromRGB(4, 10, 6), 0)
pad(mapInfoStrip, nil, 0, 0, 14, 14)
hlist(mapInfoStrip, 20)

local function mapInfoPill(k, order)
	local f = frame("MapInfo"..k, mapInfoStrip,
		UDim2.new(0, 80, 1, 0), nil, C.FondoBase, 1)
	f.LayoutOrder = order
	label("K", f, k..": ", UDim2.new(0, 36, 1, 0), nil,
		Enum.Font.Gotham, 9, C.Texto2)
	label("V", f, "—", UDim2.new(0, 44, 1, 0), UDim2.new(0, 36, 0, 0),
		Enum.Font.GothamBold, 9, C.Texto1)
end
mapInfoPill("Nodos",   1)
mapInfoPill("Aristas", 2)
mapInfoPill("Tipo",    3)

local mapVisor = Instance.new("ViewportFrame")
mapVisor.Name                  = "VisorMapa"
mapVisor.Size                  = UDim2.new(1, 0, 1, -68)
mapVisor.Position              = UDim2.new(0, 0, 0, 68)
mapVisor.BackgroundColor3      = Color3.fromRGB(4, 8, 14)
mapVisor.BackgroundTransparency = 0
mapVisor.BorderSizePixel       = 0
mapVisor.Parent                = mapScreen

-- ════════════════════════════════════════════════════════════════
-- 8. OVERLAY DE ANÁLISIS (OverlayAnalisis)
-- ════════════════════════════════════════════════════════════════
local anaOverlay = frame("OverlayAnalisis", gui,
	UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0),
	Color3.fromRGB(0, 0, 0), 0.16)
anaOverlay.Visible = false
anaOverlay.ZIndex  = 15

local anaPanel = frame("PanelAnalisis", anaOverlay,
	UDim2.new(0, 900, 0, 482), UDim2.new(0.5, -450, 0.5, -241),
	C.FondoBase, 0.02)
corner(anaPanel, 14)
stroke(anaPanel, C.Naranja, 1, 0.75)
anaPanel.ZIndex = 16

local anaHead = frame("EncabezadoAnalisis", anaPanel,
	UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0, 0),
	Color3.fromRGB(38, 18, 4), 0)
pad(anaHead, nil, 0, 0, 14, 10)

label("TituloAnalisis", anaHead, "🎯 MODO ANÁLISIS",
	UDim2.new(0, 200, 0.6, 0), UDim2.new(0, 0, 0, 0),
	Enum.Font.GothamBold, 15, C.Naranja)
label("SubtituloAnalisis", anaHead, "Zona 1 · Grafo en tiempo real",
	UDim2.new(0, 200, 0.4, 0), UDim2.new(0, 0, 0.6, 0),
	Enum.Font.Gotham, 9, C.Texto2)

local pillsBar = frame("PillsAlgo", anaHead,
	UDim2.new(0, 270, 0, 30), UDim2.new(0.5, -80, 0.5, -15),
	C.FondoBase, 1)
hlist(pillsBar, 4)

local function pill(nombre, texto, color, order)
	local p = btn(nombre, pillsBar, texto,
		UDim2.new(0, 62, 1, 0), nil,
		C.FondoEl, 0.5, C.Texto2, Enum.Font.GothamBold, 9)
	p.LayoutOrder = order
	corner(p, 14)
	stroke(p, color, 1, 0.70)
	return p
end
pill("PillBFS",      "BFS",      C.Azul,    1)
pill("PillDFS",      "DFS",      C.Verde,   2)
pill("PillDijkstra", "Dijkstra", C.Oro,     3)
pill("PillPrim",     "Prim",     C.Violeta, 4)

local btnAlgoExec = btn("BtnEjecutarAlgo", anaHead, "▶ EJECUTAR",
	UDim2.new(0, 88, 0, 28), UDim2.new(1, -200, 0.5, -14),
	C.Naranja, 0, Color3.fromRGB(255, 255, 255))
corner(btnAlgoExec, 7)

local anaClose = btn("BtnCerrarAnalisis", anaHead, "X",
	UDim2.new(0, 24, 0, 24), UDim2.new(1, -26, 0.5, -12),
	Color3.fromRGB(54, 16, 16), 0, C.Rojo)
corner(anaClose, 7)
stroke(anaClose, C.Rojo, 1, 0.70)

local anaBody = frame("PanelDatos", anaPanel,
	UDim2.new(1, 0, 1, -50), UDim2.new(0, 0, 0, 50),
	C.FondoBase, 1)
local anaBodyLayout = Instance.new("UIListLayout")
anaBodyLayout.FillDirection = Enum.FillDirection.Horizontal
anaBodyLayout.SortOrder     = Enum.SortOrder.LayoutOrder
anaBodyLayout.Parent        = anaBody

-- Columna 1: Grafo de la zona
local col1 = frame("ColGrafo", anaBody,
	UDim2.new(0, 260, 1, 0), nil,
	Color3.fromRGB(4, 8, 14), 0)
col1.LayoutOrder = 1
stroke(col1, C.Borde, 1, 0.88)

label("ColGrafoTitulo", col1, "GRAFO DE LA ZONA",
	UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 0),
	Enum.Font.GothamBold, 9, C.Texto2, false, Enum.TextXAlignment.Center)

local col1VP = Instance.new("ViewportFrame")
col1VP.Name                  = "VisorGrafoAna"
col1VP.Size                  = UDim2.new(1, 0, 1, -80)
col1VP.Position              = UDim2.new(0, 0, 0, 26)
col1VP.BackgroundColor3      = Color3.fromRGB(4, 8, 14)
col1VP.BackgroundTransparency = 0
col1VP.BorderSizePixel       = 0
col1VP.Parent                = col1

local col1Leg = frame("LeyendaGrafo", col1,
	UDim2.new(1, 0, 0, 54), UDim2.new(0, 0, 1, -54),
	Color3.fromRGB(4, 8, 14), 0)
pad(col1Leg, nil, 4, 0, 6, 6)
local col1LegLayout = Instance.new("UIGridLayout")
col1LegLayout.CellSize    = UDim2.new(0.5, -4, 0.5, -2)
col1LegLayout.CellPadding = UDim2.new(0, 4, 0, 2)
col1LegLayout.SortOrder   = Enum.SortOrder.LayoutOrder
col1LegLayout.Parent      = col1Leg

local function legItem(texto, color, order)
	local f = frame("Leg"..order, col1Leg, UDim2.new(0,0,0,0), nil, C.FondoBase, 1)
	f.LayoutOrder = order
	local dot = frame("Dot", f, UDim2.new(0,7,0,7), UDim2.new(0,0,0.5,-3.5), color, 0)
	corner(dot, 4)
	label("K", f, texto, UDim2.new(1,-12,1,0), UDim2.new(0,12,0,0),
		Enum.Font.Gotham, 8, C.Texto2)
end
legItem("Visitado",   C.Verde,   1)
legItem("Actual",     C.Naranja, 2)
legItem("En cola",    C.Azul,    3)
legItem("Pendiente",  C.Texto3,  4)

-- Columna 2: Pasos y estado
local col2 = frame("ColPasos", anaBody,
	UDim2.new(1, -490, 1, 0), nil, C.FondoBase, 1)
col2.LayoutOrder = 2
col2.ZIndex      = 2   -- renderiza encima de ColCodigo (ZIndex=1)
stroke(col2, C.Borde, 1, 0.90)

label("ColPasosTitulo", col2, "ESTADO DEL ALGORITMO",
	UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 0),
	Enum.Font.GothamBold, 9, C.Texto2, false, Enum.TextXAlignment.Center)

local pathBar = frame("BarraRecorrido", col2,
	UDim2.new(1, -16, 0, 38), UDim2.new(0, 8, 0, 30),
	C.FondoEl, 0)
corner(pathBar, 7)
pad(pathBar, nil, 0, 0, 8, 8)
label("LabelRecorrido", pathBar, "Recorrido: —",
	UDim2.new(1, 0, 1, 0), nil,
	Enum.Font.Code, 10, C.Texto2)

local stepCard = frame("TarjetaPaso", col2,
	UDim2.new(1, -16, 0, 52), UDim2.new(0, 8, 0, 74),
	C.FondoEl, 0)
corner(stepCard, 7)
stroke(stepCard, C.Borde, 1, 0.87)
pad(stepCard, 7)

label("NumPaso", stepCard, "⟶ PASO 1 / —",
	UDim2.new(1, 0, 0.38, 0), nil,
	Enum.Font.GothamBold, 9, C.Naranja)
label("DescPaso", stepCard,
	"Iniciando búsqueda desde el nodo inicial…",
	UDim2.new(1, 0, 0.62, 0), UDim2.new(0, 0, 0.38, 0),
	Enum.Font.Gotham, 10, C.Texto1, true)

local stateScroll = scroll("ScrollEstado", col2,
	UDim2.new(1, -16, 1, -174), UDim2.new(0, 8, 0, 132))
stateScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
vlist(stateScroll, 2)

local stepCtrl = frame("ControlesAnalisis", col2,
	UDim2.new(1, 0, 0, 42), UDim2.new(0, 0, 1, -42),
	C.FondoCard, 0)
pad(stepCtrl, nil, 0, 0, 6, 6)
hlist(stepCtrl, 5)

local btnPrev = btn("BtnAnterior", stepCtrl, "⬅",
	UDim2.new(0, 34, 0, 28), nil, C.FondoEl, 0, C.Texto2)
btnPrev.LayoutOrder = 1; corner(btnPrev, 6)

local progOuter = frame("BarraProgreso", stepCtrl,
	UDim2.new(1, -136, 0, 4), nil, C.FondoEl, 0)
progOuter.LayoutOrder   = 2
progOuter.AnchorPoint   = Vector2.new(0, 0.5)
corner(progOuter, 2)
local progFill = frame("RellenoProgreso", progOuter,
	UDim2.new(0, 0, 1, 0), nil, C.Naranja, 0)
corner(progFill, 2)
local progGrad = Instance.new("UIGradient")
progGrad.Color  = ColorSequence.new(C.Naranja, C.Oro)
progGrad.Parent = progFill

local btnNext = btn("BtnSiguiente", stepCtrl, "Siguiente ➡",
	UDim2.new(0, 80, 0, 28), nil,
	Color3.fromRGB(46, 22, 4), 0, C.Naranja)
btnNext.LayoutOrder = 3; corner(btnNext, 6); stroke(btnNext, C.Naranja, 1, 0.70)

local btnExitAna = btn("BtnSalirAnalisis", stepCtrl, "X",
	UDim2.new(0, 26, 0, 28), nil,
	Color3.fromRGB(50, 10, 10), 0, C.Rojo)
btnExitAna.LayoutOrder = 4; corner(btnExitAna, 6); stroke(btnExitAna, C.Rojo, 1, 0.70)

-- Columna 3: Pseudocódigo + métricas
local col3 = frame("ColCodigo", anaBody,
	UDim2.new(0, 230, 1, 0), nil,
	Color3.fromRGB(4, 8, 14), 0)
col3.LayoutOrder = 3
stroke(col3, C.Borde, 1, 0.88)

label("ColCodigoTitulo", col3, "PSEUDOCÓDIGO",
	UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 0),
	Enum.Font.GothamBold, 9, C.Texto2, false, Enum.TextXAlignment.Center)

local pseudoScroll = scroll("ScrollPseudocodigo", col3,
	UDim2.new(1, 0, 1, -82), UDim2.new(0, 0, 0, 26))
pseudoScroll.ScrollBarThickness = 3
vlist(pseudoScroll, 0)

local metricsBox = frame("MetricasAnalisis", col3,
	UDim2.new(1, 0, 0, 56), UDim2.new(0, 0, 1, -56),
	C.FondoEl, 0)
stroke(metricsBox, C.Borde, 1, 0.90)
pad(metricsBox, 6)

label("InsigniaComplejidad", metricsBox, "O(V + E)",
	UDim2.new(1, 0, 0, 20), nil,
	Enum.Font.Code, 11, C.Azul, false, Enum.TextXAlignment.Center)
label("MetricaPasos", metricsBox, "Pasos: 0 / 0",
	UDim2.new(1, 0, 0, 14), UDim2.new(0, 0, 0, 22),
	Enum.Font.Gotham, 9, C.Texto2)
label("MetricaNodos", metricsBox, "Nodos visitados: 0",
	UDim2.new(1, 0, 0, 14), UDim2.new(0, 0, 0, 36),
	Enum.Font.Gotham, 9, C.Texto2)

-- ════════════════════════════════════════════════════════════════
-- 9. PANTALLA DE VICTORIA (PantallaVictoria)
-- ════════════════════════════════════════════════════════════════
local victOverlay = frame("VictoriaFondo", gui,
	UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0),
	Color3.fromRGB(0, 0, 0), 0.10)
victOverlay.Visible = false
victOverlay.ZIndex  = 20

local victCanvas = Instance.new("CanvasGroup")
victCanvas.Name              = "PantallaVictoria"
victCanvas.Size              = UDim2.new(0, 420, 0, 396)
victCanvas.Position          = UDim2.new(0.5, -210, 0.5, -198)
victCanvas.BackgroundTransparency = 1
victCanvas.GroupTransparency = 0
victCanvas.BorderSizePixel   = 0
victCanvas.ZIndex            = 21
victCanvas.Parent            = victOverlay

local victPanel = frame("ContenedorPrincipal", victCanvas,
	UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0),
	Color3.fromRGB(10, 12, 18), 0)
corner(victPanel, 18)
stroke(victPanel, C.Oro, 1, 0.78)

local victHead = frame("VictoriaHead", victPanel,
	UDim2.new(1, 0, 0, 110), UDim2.new(0, 0, 0, 0),
	Color3.fromRGB(24, 16, 0), 0)
pad(victHead, nil, 14, 8, 0, 0)

label("TituloVictoria", victHead, "¡NIVEL COMPLETADO!",
	UDim2.new(1, 0, 0, 30), nil,
	Enum.Font.GothamBold, 24, C.Oro, false, Enum.TextXAlignment.Center)

label("SubtituloVictoria", victHead, "ZONA 1 — ESTACIÓN SUPERADA",
	UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 0, 30),
	Enum.Font.Gotham, 9, C.Texto2, false, Enum.TextXAlignment.Center)

local starsRow = frame("EstrellasMostrar", victHead,
	UDim2.new(0, 148, 0, 44), UDim2.new(0.5, -74, 0, 52),
	C.FondoBase, 1)
local starsLayout = Instance.new("UIListLayout")
starsLayout.FillDirection          = Enum.FillDirection.Horizontal
starsLayout.SortOrder              = Enum.SortOrder.LayoutOrder
starsLayout.Padding                = UDim.new(0, 8)
starsLayout.VerticalAlignment      = Enum.VerticalAlignment.Center
starsLayout.HorizontalAlignment    = Enum.HorizontalAlignment.Center
starsLayout.Parent                 = starsRow

for i = 1, 3 do
	local star = Instance.new("ImageLabel")
	star.Name               = "Estrella" .. i
	star.Size               = UDim2.new(0, 38, 0, 38)
	star.BackgroundTransparency = 1
	star.Image              = "rbxassetid://6031071057"
	star.ImageColor3        = C.Oro
	star.ImageTransparency  = 0.72
	star.LayoutOrder        = i
	star.Parent             = starsRow
end

local statsFrame = frame("EstadisticasFrame", victPanel,
	UDim2.new(1, -28, 0, 140), UDim2.new(0, 14, 0, 116),
	C.FondoBase, 1)
vlist(statsFrame, 5)

local function statRow(nombre, k, v)
	local row = frame(nombre, statsFrame,
		UDim2.new(1, 0, 0, 30), nil, C.FondoEl, 0)
	corner(row, 7)
	stroke(row, C.Borde, 1, 0.90)
	pad(row, nil, 0, 0, 12, 12)
	label("K", row, k, UDim2.new(0.62, 0, 1, 0), nil,
		Enum.Font.Gotham, 11, C.Texto2)
	local vLbl = label("V", row, v, UDim2.new(0.38, 0, 1, 0), UDim2.new(0.62, 0, 0, 0),
		Enum.Font.GothamBold, 13, C.Texto1, false, Enum.TextXAlignment.Right)
	return vLbl
end

statRow("FilaTiempo",   "⏱ Tiempo",         "0:00")
statRow("FilaAciertos", "🔗 Conexiones",      "0 / 0")
statRow("FilaErrores",  "❌ Errores",          "0")
local puntajeLbl = statRow("FilaPuntaje", "🏆 Puntaje Final", "0")
puntajeLbl.TextColor3 = C.Oro
puntajeLbl.TextSize   = 17

local victBtns = frame("BotonesFrame", victPanel,
	UDim2.new(1, -28, 0, 40), UDim2.new(0, 14, 0, 266),
	C.FondoBase, 1)
hlist(victBtns, 9)

local botonRepetir = btn("BotonRepetir", victBtns, "🔄 Repetir",
	UDim2.new(0.5, -4, 1, 0), nil,
	Color3.fromRGB(42, 32, 5), 0, C.Aviso)
botonRepetir.LayoutOrder = 1
corner(botonRepetir, 9); stroke(botonRepetir, C.Aviso, 1, 0.70)

local botonContinuar = btn("BotonContinuar", victBtns, "Continuar ➡",
	UDim2.new(0.5, -4, 1, 0), nil,
	Color3.fromRGB(8, 40, 20), 0, C.Verde)
botonContinuar.LayoutOrder = 2
corner(botonContinuar, 9); stroke(botonContinuar, C.Verde, 1, 0.65)

-- ════════════════════════════════════════════════════════════════
-- 10. LEYENDA DE NODOS (Leyenda)
-- ════════════════════════════════════════════════════════════════
local legendPanel = frame("Leyenda", gui,
	UDim2.new(0, 104, 0, 86), UDim2.new(1, -116, 1, -108),
	C.FondoBase, 0.06)
legendPanel.Visible = false  -- el modo Visual la activa; oculta en otros modos
corner(legendPanel, 7)
stroke(legendPanel, C.Borde, 1, 0.87)
pad(legendPanel, nil, 6, 6, 8, 8)
vlist(legendPanel, 3)

label("LeyendaTitulo", legendPanel, "LEYENDA",
	UDim2.new(1, 0, 0, 11), nil,
	Enum.Font.GothamBold, 7, C.Texto2).LayoutOrder = 0

local function legRow(nombre, color, texto, order)
	local row = frame(nombre, legendPanel,
		UDim2.new(1, 0, 0, 13), nil, C.FondoBase, 1)
	row.LayoutOrder = order
	local dot = frame("Dot", row,
		UDim2.new(0, 7, 0, 7), UDim2.new(0, 0, 0.5, -3.5), color, 0)
	corner(dot, 4)
	label("K", row, texto,
		UDim2.new(1, -12, 1, 0), UDim2.new(0, 12, 0, 0),
		Enum.Font.Gotham, 8, C.Texto2)
end
legRow("LegInicial",    Color3.fromRGB(75,  157, 232), "Inicial",    1)
legRow("LegEnergizado", Color3.fromRGB(62,  207, 142), "Energizado", 2)
legRow("LegMeta",       Color3.fromRGB(245, 200, 66),  "Meta",       3)
legRow("LegAdyacente",  Color3.fromRGB(232, 147, 75),  "Adyacente",  4)
legRow("LegAislado",    Color3.fromRGB(224, 92,  92),  "Aislado",    5)

-- ════════════════════════════════════════════════════════════════
-- 11. GUIDE HUD (GuiaHUD)
-- ════════════════════════════════════════════════════════════════
local guideHud = frame("GuiaHUD", gui,
	UDim2.new(0, 220, 0, 26), UDim2.new(0.5, -110, 0, 104),
	Color3.fromRGB(38, 28, 0), 0)
guideHud.Visible = false
corner(guideHud, 13)
stroke(guideHud, C.Oro, 1, 0.72)
pad(guideHud, nil, 0, 0, 10, 10)


-- ════════════════════════════════════════════════════════════════
-- 12. BOTÓN SALIR (BarraBotonesMain — añadido)
-- ════════════════════════════════════════════════════════════════
local btnSalir = btn("BtnSalir", mainBar, "🚪 Salir",
	UDim2.new(0, 70, 1, -10), nil,
	Color3.fromRGB(42, 10, 10), 0, C.Rojo)
btnSalir.LayoutOrder = 3
corner(btnSalir, 7)
stroke(btnSalir, C.Rojo, 1, 0.68)

-- Ampliar el ancho de la barra para acomodar el nuevo botón
mainBar.Size = UDim2.new(0, 258, 0, 40)

-- ════════════════════════════════════════════════════════════════
-- 13. MODAL DE CONFIRMACIÓN (ModalSalir)
-- ════════════════════════════════════════════════════════════════
local modalOverlay = frame("ModalSalirFondo", gui,
	UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0),
	Color3.fromRGB(0, 0, 0), 0.45)
modalOverlay.Visible = false
modalOverlay.ZIndex  = 30

local modalPanel = frame("ModalSalir", modalOverlay,
	UDim2.new(0, 340, 0, 210), UDim2.new(0.5, -170, 0.5, -105),
	C.FondoBase, 0.02)
corner(modalPanel, 14)
stroke(modalPanel, C.Rojo, 1, 0.65)
modalPanel.ZIndex = 31

-- Cabecera roja
local modalHead = frame("ModalHead", modalPanel,
	UDim2.new(1, 0, 0, 52), UDim2.new(0, 0, 0, 0),
	Color3.fromRGB(38, 8, 8), 0)
pad(modalHead, nil, 0, 0, 16, 10)

label("ModalIcono", modalHead, "🚪",
	UDim2.new(0, 24, 1, 0), UDim2.new(0, 0, 0, 0),
	Enum.Font.GothamBold, 20, C.Texto1)

local modalTitleStack = frame("ModalTitleStack", modalHead,
	UDim2.new(1, -34, 1, 0), UDim2.new(0, 28, 0, 0), C.FondoBase, 1)

label("ModalTitulo", modalTitleStack, "¿SALIR DEL NIVEL?",
	UDim2.new(1, 0, 0.55, 0), UDim2.new(0, 0, 0, 0),
	Enum.Font.GothamBold, 14, C.Rojo)

label("ModalSub", modalTitleStack, "Tu progreso actual no se guardará",
	UDim2.new(1, 0, 0.45, 0), UDim2.new(0, 0, 0.55, 0),
	Enum.Font.Gotham, 9, C.Texto2)

-- Cuerpo / advertencia
local modalBody = frame("ModalBody", modalPanel,
	UDim2.new(1, -28, 0, 62), UDim2.new(0, 14, 0, 58),
	C.FondoCard, 0)
corner(modalBody, 8)
stroke(modalBody, C.Borde, 1, 0.90)
pad(modalBody, 10)

label("ModalMsg", modalBody,
	"Si sales ahora perderás los puntos obtenidos en esta sesión y el nivel se reiniciará desde el principio.",
	UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0),
	Enum.Font.Gotham, 10, C.Texto2, true)

-- Botones de acción
local modalBtns = frame("ModalBtns", modalPanel,
	UDim2.new(1, -28, 0, 36), UDim2.new(0, 14, 0, 132),
	C.FondoBase, 1)
hlist(modalBtns, 10)

local btnCancelarModal = btn("BtnCancelarSalir", modalBtns, "✕ Cancelar",
	UDim2.new(0.5, -5, 1, 0), nil,
	C.FondoEl, 0, C.Texto1)
btnCancelarModal.LayoutOrder = 1
corner(btnCancelarModal, 8)
stroke(btnCancelarModal, C.Borde, 1, 0.80)

local btnConfirmarModal = btn("BtnConfirmarSalir", modalBtns, "🚪 Sí, salir",
	UDim2.new(0.5, -5, 1, 0), nil,
	Color3.fromRGB(54, 10, 10), 0, C.Rojo)
btnConfirmarModal.LayoutOrder = 2
corner(btnConfirmarModal, 8)
stroke(btnConfirmarModal, C.Rojo, 1, 0.60)

-- Nota de progreso guardado (opcional, abajo del todo)
local modalNote = frame("ModalNote", modalPanel,
	UDim2.new(1, -28, 0, 20), UDim2.new(0, 14, 0, 178),
	C.FondoBase, 1)

label("ModalNoteLabel", modalNote,
	"💾  Los logros permanentes sí quedan registrados",
	UDim2.new(1, 0, 1, 0), nil,
	Enum.Font.Gotham, 8, C.Texto3, false, Enum.TextXAlignment.Center)

-- ════════════════════════════════════════════════════════════════
-- LÓGICA DEL MODAL
-- ════════════════════════════════════════════════════════════════
btnSalir.MouseButton1Click:Connect(function()
	modalOverlay.Visible = true
end)

btnCancelarModal.MouseButton1Click:Connect(function()
	modalOverlay.Visible = false
end)

-- Cerrar también si se hace clic en el fondo oscuro
modalOverlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		-- Sólo cierra si el clic fue en el fondo, no en el panel
		modalOverlay.Visible = false
	end
end)
-- Evita que el clic en el panel cierre el overlay
modalPanel.InputBegan:Connect(function(input)
	input.Handled = true -- consume el evento
end)

btnConfirmarModal.MouseButton1Click:Connect(function()
	modalOverlay.Visible = false
	-- ─── Aquí va tu lógica para salir del nivel ───
	-- Ejemplo: game:GetService("TeleportService"):Teleport(PLACE_ID)
	-- o: game:GetService("Players").LocalPlayer:Kick("Saliste del nivel")
	print("🚪 El jugador confirmó salir del nivel")
end)


label("GuiaLabel", guideHud,
	"🧭 Dirígete a: —",
	UDim2.new(1, 0, 1, 0), nil,
	Enum.Font.GothamBold, 9, C.Oro, false, Enum.TextXAlignment.Center)

gui.Parent = game:GetService("StarterGui")
print("✅ GUIExploradorV2 creada en StarterGui")