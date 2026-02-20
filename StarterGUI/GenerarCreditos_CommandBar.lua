-- =====================================================================
-- GENERADOR DE UI: Créditos Mejorado
-- Pegar y ejecutar en el Command Bar de Roblox Studio
-- Modifica el contenido de MenuCreditos dentro de StarterGui
-- =====================================================================

local SG = game:GetService("StarterGui")

-- Buscar MenuCreditos
local mc
for _, d in ipairs(SG:GetDescendants()) do
	if d.Name == "MenuCreditos" and d:IsA("Frame") then mc = d; break end
end
assert(mc, "❌ No se encontró 'MenuCreditos' (Frame) en StarterGui. Verifica el nombre.")
print("✅ Encontrado: " .. mc:GetFullName())

-- Limpiar hijos existentes
for _, c in ipairs(mc:GetChildren()) do c:Destroy() end

-- =====================================================================
-- HELPERS
-- =====================================================================
local function N(cls, parent, props)
	local inst = Instance.new(cls)
	for k, v in pairs(props or {}) do inst[k] = v end
	inst.Parent = parent
	return inst
end

local function Gradient(parent, c0, c1, rot)
	return N("UIGradient", parent, {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, c0),
			ColorSequenceKeypoint.new(1, c1),
		}),
		Rotation = rot or 135,
	})
end

local function Separador(parent, yScale, yOffset)
	local sep = N("Frame", parent, {
		BackgroundColor3 = Color3.fromRGB(212, 175, 55),
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		Size = UDim2.new(0.62, 0, 0, 1),
		Position = UDim2.new(0.19, 0, yScale, yOffset),
		ZIndex = 4,
	})
	N("UIGradient", sep, {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(12, 10, 32)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(212, 175, 55)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 10, 32)),
		}),
	})
	return sep
end

-- =====================================================================
-- CONTENEDOR RAÍZ (menuCreditos — transparente, solo organiza)
-- =====================================================================
mc.BackgroundTransparency = 1
mc.BorderSizePixel = 0
mc.Size = UDim2.new(1, 0, 1, 0)
mc.Position = UDim2.new(0, 0, 0, 0)

-- ——— TITTLE y TITTLETEXT: requeridos por MenuCameraSystem, placeholders invisibles ———
local Tittle = N("Frame", mc, {
	Name = "Tittle",
	BackgroundTransparency = 1,
	Size = UDim2.new(0, 0, 0, 0),
	Position = UDim2.new(0, 0, 0, 0),
	ZIndex = 1,
})
N("TextLabel", Tittle, {
	Name = "TittleText",
	BackgroundTransparency = 1,
	Size = UDim2.new(0, 0, 0, 0),
	Text = "",
	ZIndex = 1,
	Visible = false,
})

-- =====================================================================
-- CREDITS FRAME — pantalla completa, controla visibilidad de todo
-- =====================================================================
local CF = N("Frame", mc, {
	Name = "CreditosFrame",
	BackgroundColor3 = Color3.fromRGB(6, 6, 20),
	BackgroundTransparency = 0,
	BorderSizePixel = 0,
	Size = UDim2.new(1, 0, 1, 0),
	Position = UDim2.new(0, 0, 0, 0),
	ZIndex = 2,
	ClipsDescendants = false,
})
N("UIGradient", CF, {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(4, 4, 18)),
		ColorSequenceKeypoint.new(0.45, Color3.fromRGB(16, 9, 42)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(4, 4, 18)),
	}),
	Rotation = 140,
})

-- TextCreditos: requerido por MenuCameraSystem (oculto)
N("TextLabel", CF, {
	Name = "TextCreditos",
	BackgroundTransparency = 1,
	Size = UDim2.new(0, 0, 0, 0),
	Text = "",
	ZIndex = 1,
	Visible = false,
})

-- =====================================================================
-- ESTRELLAS DECORATIVAS
-- =====================================================================
local starData = {
	{0.04, 0.06, 3}, {0.13, 0.19, 2}, {0.24, 0.07, 4}, {0.37, 0.13, 2},
	{0.51, 0.05, 3}, {0.67, 0.10, 2}, {0.83, 0.07, 4}, {0.95, 0.21, 2},
	{0.06, 0.38, 2}, {0.16, 0.74, 3}, {0.88, 0.43, 3}, {0.97, 0.63, 2},
	{0.02, 0.57, 4}, {0.77, 0.83, 2}, {0.43, 0.91, 3}, {0.61, 0.87, 2},
	{0.31, 0.79, 2}, {0.92, 0.88, 3}, {0.11, 0.52, 2}, {0.57, 0.33, 2},
	{0.47, 0.67, 3}, {0.74, 0.48, 2}, {0.34, 0.27, 2}, {0.81, 0.60, 3},
	{0.49, 0.44, 2}, {0.20, 0.30, 3}, {0.65, 0.22, 2}, {0.08, 0.88, 2},
}
for _, s in ipairs(starData) do
	local st = N("Frame", CF, {
		Name = "Estrella",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = math.random(40, 82) / 100,
		BorderSizePixel = 0,
		Size = UDim2.new(0, s[3], 0, s[3]),
		Position = UDim2.new(s[1], 0, s[2], 0),
		ZIndex = 1,
	})
	N("UICorner", st, { CornerRadius = UDim.new(1, 0) })
end

-- =====================================================================
-- TÍTULO PRINCIPAL
-- =====================================================================
local titFrame = N("Frame", CF, {
	Name = "TituloDecor",
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0.14, 0),
	Position = UDim2.new(0, 0, 0, 0),
	ZIndex = 5,
})
local titLabel = N("TextLabel", titFrame, {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 1, 0),
	Text = "✦   C R É D I T O S   ✦",
	Font = Enum.Font.GothamBold,
	TextSize = 38,
	TextScaled = false,
	TextColor3 = Color3.fromRGB(212, 175, 55),
	ZIndex = 5,
})
N("UIStroke", titLabel, {
	Color = Color3.fromRGB(100, 60, 0),
	Thickness = 2.5,
	Transparency = 0.15,
})

-- Línea dorada decorativa bajo el título
local linTop = N("Frame", CF, {
	Name = "LineaTitulo",
	BackgroundColor3 = Color3.fromRGB(212, 175, 55),
	BackgroundTransparency = 0,
	BorderSizePixel = 0,
	Size = UDim2.new(0.55, 0, 0, 2),
	Position = UDim2.new(0.225, 0, 0.138, 0),
	ZIndex = 5,
})
N("UIGradient", linTop, {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(6, 6, 20)),
		ColorSequenceKeypoint.new(0.2, Color3.fromRGB(212, 175, 55)),
		ColorSequenceKeypoint.new(0.8, Color3.fromRGB(212, 175, 55)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 6, 20)),
	}),
})

-- Puntos decorativos a los lados de la línea
for _, side in ipairs({0.21, 0.79}) do
	local dot = N("Frame", CF, {
		BackgroundColor3 = Color3.fromRGB(212, 175, 55),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 6, 0, 6),
		Position = UDim2.new(side, -3, 0.138, -2),
		ZIndex = 5,
	})
	N("UICorner", dot, { CornerRadius = UDim.new(1, 0) })
end

-- =====================================================================
-- CARD DE CONTENIDO PRINCIPAL
-- =====================================================================
local card = N("Frame", CF, {
	Name = "ContentCard",
	BackgroundColor3 = Color3.fromRGB(11, 9, 30),
	BackgroundTransparency = 0.06,
	BorderSizePixel = 0,
	Size = UDim2.new(0.76, 0, 0.72, 0),
	Position = UDim2.new(0.12, 0, 0.15, 0),
	ZIndex = 3,
})
N("UICorner", card, { CornerRadius = UDim.new(0, 22) })
N("UIStroke", card, {
	Color = Color3.fromRGB(212, 175, 55),
	Thickness = 1.5,
	Transparency = 0.22,
})
Gradient(card, Color3.fromRGB(18, 13, 48), Color3.fromRGB(8, 7, 26), 135)

-- =====================================================================
-- LOGO UNIVERSIDAD (reemplazar rbxassetid://0 con el ID real)
-- =====================================================================
local logoCirc = N("Frame", card, {
	Name = "LogoUniversidad",
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.88,
	BorderSizePixel = 0,
	Size = UDim2.new(0, 108, 0, 108),
	Position = UDim2.new(0.5, -54, 0, 18),
	ZIndex = 5,
})
N("UICorner", logoCirc, { CornerRadius = UDim.new(1, 0) })
N("UIStroke", logoCirc, {
	Color = Color3.fromRGB(212, 175, 55),
	Thickness = 2.5,
	Transparency = 0,
})
Gradient(logoCirc, Color3.fromRGB(30, 22, 70), Color3.fromRGB(18, 12, 50), 135)

-- ImageLabel: cambiar Image al assetid del logo cuando lo tengas
N("ImageLabel", logoCirc, {
	Name = "LogoImage",
	BackgroundTransparency = 1,
	Size = UDim2.new(0.80, 0, 0.80, 0),
	Position = UDim2.new(0.10, 0, 0.10, 0),
	Image = "rbxassetid://0", -- ← REEMPLAZAR CON ID DEL LOGO
	ScaleType = Enum.ScaleType.Fit,
	ZIndex = 7,
})

-- Emoji placeholder (ocultar cuando tengas el logo real)
N("TextLabel", logoCirc, {
	Name = "LogoPlaceholder",
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 1, 0),
	Text = "🎓",
	Font = Enum.Font.GothamBold,
	TextSize = 48,
	TextColor3 = Color3.fromRGB(212, 175, 55),
	ZIndex = 8,
})

-- Etiqueta bajo el logo
N("TextLabel", card, {
	Name = "EtiquetaLogo",
	BackgroundTransparency = 1,
	Size = UDim2.new(0.9, 0, 0, 22),
	Position = UDim2.new(0.05, 0, 0, 136),
	Text = "[ Logo de la Universidad ]",
	Font = Enum.Font.Gotham,
	TextSize = 13,
	TextColor3 = Color3.fromRGB(110, 95, 175),
	ZIndex = 4,
})

-- Separador superior
Separador(card, 0, 168)

-- =====================================================================
-- TARJETA: AUTOR
-- =====================================================================
local tA = N("Frame", card, {
	Name = "TarjetaAutor",
	BackgroundColor3 = Color3.fromRGB(20, 15, 60),
	BackgroundTransparency = 0.04,
	BorderSizePixel = 0,
	Size = UDim2.new(0.84, 0, 0, 90),
	Position = UDim2.new(0.08, 0, 0, 184),
	ZIndex = 4,
})
N("UICorner", tA, { CornerRadius = UDim.new(0, 15) })
N("UIStroke", tA, {
	Color = Color3.fromRGB(120, 95, 255),
	Thickness = 1.2,
	Transparency = 0.12,
})
Gradient(tA, Color3.fromRGB(34, 24, 82), Color3.fromRGB(17, 13, 54), 90)

-- Barra de color izquierda (acento púrpura)
local barA = N("Frame", tA, {
	BackgroundColor3 = Color3.fromRGB(120, 95, 255),
	BackgroundTransparency = 0.3,
	BorderSizePixel = 0,
	Size = UDim2.new(0, 4, 0.7, 0),
	Position = UDim2.new(0, 0, 0.15, 0),
	ZIndex = 5,
})
N("UICorner", barA, { CornerRadius = UDim.new(0, 4) })

N("TextLabel", tA, {
	BackgroundTransparency = 1,
	Size = UDim2.new(0, 54, 1, 0),
	Position = UDim2.new(0, 10, 0, 0),
	Text = "💻",
	Font = Enum.Font.GothamBold,
	TextSize = 34,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	ZIndex = 5,
})
N("TextLabel", tA, {
	Name = "Rol",
	BackgroundTransparency = 1,
	Size = UDim2.new(0.73, 0, 0.44, 0),
	Position = UDim2.new(0, 70, 0, 10),
	Text = "DESARROLLADO POR",
	Font = Enum.Font.Gotham,
	TextSize = 12,
	TextColor3 = Color3.fromRGB(170, 148, 255),
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 5,
})
N("TextLabel", tA, {
	Name = "Nombre",
	BackgroundTransparency = 1,
	Size = UDim2.new(0.73, 0, 0.50, 0),
	Position = UDim2.new(0, 70, 0.46, 0),
	Text = "Moisés Arequipa",
	Font = Enum.Font.GothamBold,
	TextSize = 22,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 5,
})

-- =====================================================================
-- TARJETA: TUTORA
-- =====================================================================
local tT = N("Frame", card, {
	Name = "TarjetaTutora",
	BackgroundColor3 = Color3.fromRGB(36, 12, 42),
	BackgroundTransparency = 0.04,
	BorderSizePixel = 0,
	Size = UDim2.new(0.84, 0, 0, 90),
	Position = UDim2.new(0.08, 0, 0, 285),
	ZIndex = 4,
})
N("UICorner", tT, { CornerRadius = UDim.new(0, 15) })
N("UIStroke", tT, {
	Color = Color3.fromRGB(225, 100, 205),
	Thickness = 1.2,
	Transparency = 0.12,
})
Gradient(tT, Color3.fromRGB(54, 18, 60), Color3.fromRGB(27, 9, 38), 90)

-- Barra de color izquierda (acento rosa)
local barT = N("Frame", tT, {
	BackgroundColor3 = Color3.fromRGB(225, 100, 205),
	BackgroundTransparency = 0.3,
	BorderSizePixel = 0,
	Size = UDim2.new(0, 4, 0.7, 0),
	Position = UDim2.new(0, 0, 0.15, 0),
	ZIndex = 5,
})
N("UICorner", barT, { CornerRadius = UDim.new(0, 4) })

N("TextLabel", tT, {
	BackgroundTransparency = 1,
	Size = UDim2.new(0, 54, 1, 0),
	Position = UDim2.new(0, 10, 0, 0),
	Text = "🎓",
	Font = Enum.Font.GothamBold,
	TextSize = 34,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	ZIndex = 5,
})
N("TextLabel", tT, {
	Name = "Rol",
	BackgroundTransparency = 1,
	Size = UDim2.new(0.73, 0, 0.44, 0),
	Position = UDim2.new(0, 70, 0, 10),
	Text = "TUTORA",
	Font = Enum.Font.Gotham,
	TextSize = 12,
	TextColor3 = Color3.fromRGB(255, 158, 232),
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 5,
})
N("TextLabel", tT, {
	Name = "Nombre",
	BackgroundTransparency = 1,
	Size = UDim2.new(0.73, 0, 0.50, 0),
	Position = UDim2.new(0, 70, 0.46, 0),
	Text = "Mayra Carrión",
	Font = Enum.Font.GothamBold,
	TextSize = 22,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 5,
})

-- Separador inferior
Separador(card, 1, -52)

-- Pie de página
N("TextLabel", card, {
	Name = "Pie",
	BackgroundTransparency = 1,
	Size = UDim2.new(0.9, 0, 0, 28),
	Position = UDim2.new(0.05, 0, 1, -40),
	Text = "© 2025  ·  Proyecto Universitario  ·  Roblox",
	Font = Enum.Font.Gotham,
	TextSize = 13,
	TextColor3 = Color3.fromRGB(75, 65, 115),
	ZIndex = 4,
})

-- =====================================================================
-- SONIDO Y CONTROL DE MÚSICA
-- =====================================================================
N("Sound", CF, {
	Name = "MusicaCreditos",
	SoundId = "rbxassetid://1843463543", -- ← Cambiar por tu ID de música favorita
	Volume = 0.38,
	Looped = true,
	RollOffMaxDistance = 10000,
})

local ls = N("LocalScript", CF, { Name = "ControlMusica" })
ls.Source = [[
-- ControlMusica: controla música cuando se abren/cierran los créditos
local frame = script.Parent
local music = frame:WaitForChild("MusicaCreditos", 10)
if not music then return end

frame:GetPropertyChangedSignal("Visible"):Connect(function()
	if frame.Visible then
		music:Play()
	else
		music:Stop()
	end
end)

if frame.Visible then music:Play() end
]]

-- =====================================================================
-- BOTÓN CERRAR (requerido como "Close" por MenuCameraSystem)
-- =====================================================================
local Close = N("TextButton", mc, {
	Name = "Close",
	BackgroundColor3 = Color3.fromRGB(14, 11, 38),
	BackgroundTransparency = 0,
	BorderSizePixel = 0,
	Size = UDim2.new(0.24, 0, 0, 48),
	Position = UDim2.new(0.38, 0, 0.895, 0),
	Text = "← VOLVER AL MENÚ",
	Font = Enum.Font.GothamBold,
	TextSize = 17,
	TextColor3 = Color3.fromRGB(212, 175, 55),
	ZIndex = 7,
	AutoButtonColor = true,
})
N("UICorner", Close, { CornerRadius = UDim.new(0, 13) })
N("UIStroke", Close, {
	Color = Color3.fromRGB(212, 175, 55),
	Thickness = 1.5,
	Transparency = 0.12,
})
Gradient(Close, Color3.fromRGB(28, 20, 76), Color3.fromRGB(12, 8, 38), 90)

-- =====================================================================
print("✅ UI de Créditos creada en: " .. mc:GetFullName())
print("🎵 Reemplaza SoundId en 'MusicaCreditos' con tu música (rbxassetid://XXXX)")
print("🎓 Reemplaza Image en 'LogoImage' con el logo de la universidad (rbxassetid://XXXX)")
print("📍 Compatibilidad MenuCameraSystem: ✓ Close  ✓ CreditosFrame  ✓ TextCreditos  ✓ Tittle  ✓ TittleText")
