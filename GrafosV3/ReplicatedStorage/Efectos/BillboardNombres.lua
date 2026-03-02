-- ReplicatedStorage/Efectos/BillboardNombres.lua
-- Sistema centralizado de billboards con presets visuales
-- Uso: BillboardNombres.crear(adornee, texto, preset, nombreClave)

local BillboardNombres = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- PRESETS VISUALES
-- ═══════════════════════════════════════════════════════════════════════════════

-- NODO_MAPA: etiqueta simple encima de nodos en el modo mapa cenital
-- ZONA_DESCRIPCION: panel con borde cyan sobre los triggers de zona
local PRESETS = {
	NODO_MAPA = {
		tamano              = UDim2.new(0, 160, 0, 40),
		offsetY             = 5.5,
		maxDistance         = 0,       -- 0 = siempre visible
		conFondo            = false,
		colorTexto          = Color3.fromRGB(255, 255, 255),
		tamanoLetra         = 14,
		fuente              = Enum.Font.GothamBold,
		conStroke           = true,
		colorStroke         = Color3.new(0, 0, 0),
		transparenciaStroke = 0.1,
	},
	ZONA_DESCRIPCION = {
		tamano              = UDim2.new(0, 200, 0, 50),
		offsetY             = 8,
		maxDistance         = 500,
		conFondo            = true,
		colorFondo          = Color3.fromRGB(0, 0, 0),
		transparenciaFondo  = 0.5,
		colorTexto          = Color3.fromRGB(255, 255, 255),
		fuente              = Enum.Font.GothamBold,
		colorBorde          = Color3.fromRGB(0, 212, 255),
		transparenciaBorde  = 0.3,
		radioBorde          = UDim.new(0, 8),
		conPadding          = true,
		textoEscalado       = true,
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- CACHE
-- ═══════════════════════════════════════════════════════════════════════════════

-- nombreClave (string) -> BillboardGui
local billboardsActivos = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- CREAR BILLBOARD
-- ═══════════════════════════════════════════════════════════════════════════════

-- adornee    : BasePart a la que se ancla el billboard
-- texto      : texto a mostrar
-- preset     : "NODO_MAPA" | "ZONA_DESCRIPCION"
-- nombreClave: clave única de string para gestión posterior (también usada como Name)
function BillboardNombres.crear(adornee, texto, preset, nombreClave)
	if not adornee or not adornee.Parent then
		warn("[BillboardNombres] adornee no válido para clave:", tostring(nombreClave))
		return nil
	end

	local cfg = PRESETS[preset]
	if not cfg then
		warn("[BillboardNombres] Preset desconocido:", tostring(preset))
		return nil
	end

	-- Destruir anterior con la misma clave
	local anterior = billboardsActivos[nombreClave]
	if anterior and anterior.Parent then
		anterior:Destroy()
	end
	billboardsActivos[nombreClave] = nil

	local workspace = game:GetService("Workspace")

	local billboard = Instance.new("BillboardGui")
	billboard.Name        = nombreClave
	billboard.Adornee     = adornee
	billboard.Size        = cfg.tamano
	billboard.StudsOffset = Vector3.new(0, cfg.offsetY, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = cfg.maxDistance or 0
	billboard.Parent      = workspace

	if cfg.conFondo then
		local frame = Instance.new("Frame")
		frame.Name                 = "Fondo"
		frame.Size                 = UDim2.new(1, 0, 1, 0)
		frame.BackgroundColor3     = cfg.colorFondo
		frame.BackgroundTransparency = cfg.transparenciaFondo
		frame.BorderSizePixel      = 0
		frame.Parent               = billboard

		local corner = Instance.new("UICorner")
		corner.CornerRadius = cfg.radioBorde or UDim.new(0, 6)
		corner.Parent = frame

		if cfg.colorBorde then
			local stroke = Instance.new("UIStroke")
			stroke.Color       = cfg.colorBorde
			stroke.Thickness   = 2
			stroke.Transparency = cfg.transparenciaBorde or 0
			stroke.Parent      = frame
		end

		if cfg.conPadding then
			local padding = Instance.new("UIPadding")
			padding.PaddingLeft   = UDim.new(0, 8)
			padding.PaddingRight  = UDim.new(0, 8)
			padding.PaddingTop    = UDim.new(0, 4)
			padding.PaddingBottom = UDim.new(0, 4)
			padding.Parent        = frame
		end

		local label = Instance.new("TextLabel")
		label.Name                = "TextoNombre"
		label.Size                = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text                = texto
		label.TextColor3          = cfg.colorTexto
		label.Font                = cfg.fuente or Enum.Font.GothamBold
		if cfg.textoEscalado then
			label.TextScaled = true
		else
			label.TextSize = cfg.tamanoLetra or 14
		end
		label.Parent = frame
	else
		-- Sin fondo: TextLabel directo en el billboard
		local label = Instance.new("TextLabel")
		label.Name                = "Label"
		label.Size                = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text                = texto
		label.TextColor3          = cfg.colorTexto
		label.Font                = cfg.fuente or Enum.Font.GothamBold
		label.TextSize            = cfg.tamanoLetra or 14
		if cfg.conStroke then
			label.TextStrokeTransparency = cfg.transparenciaStroke or 0.1
			label.TextStrokeColor3       = cfg.colorStroke or Color3.new(0, 0, 0)
		end
		label.Parent = billboard
	end

	billboardsActivos[nombreClave] = billboard
	return billboard
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- GESTIÓN
-- ═══════════════════════════════════════════════════════════════════════════════

function BillboardNombres.destruir(nombreClave)
	local bb = billboardsActivos[nombreClave]
	if bb and bb.Parent then
		bb:Destroy()
	end
	billboardsActivos[nombreClave] = nil
end

function BillboardNombres.destruirPorPrefijo(prefijo)
	local aEliminar = {}
	for clave in pairs(billboardsActivos) do
		if clave:sub(1, #prefijo) == prefijo then
			table.insert(aEliminar, clave)
		end
	end
	for _, clave in ipairs(aEliminar) do
		local bb = billboardsActivos[clave]
		if bb and bb.Parent then
			bb:Destroy()
		end
		billboardsActivos[clave] = nil
	end
end

function BillboardNombres.destruirTodos()
	for _, bb in pairs(billboardsActivos) do
		if bb and bb.Parent then
			bb:Destroy()
		end
	end
	billboardsActivos = {}
end

function BillboardNombres.setEnabled(nombreClave, habilitado)
	local bb = billboardsActivos[nombreClave]
	if bb and bb.Parent then
		bb.Enabled = habilitado
	end
end

function BillboardNombres.obtener(nombreClave)
	return billboardsActivos[nombreClave]
end

return BillboardNombres
