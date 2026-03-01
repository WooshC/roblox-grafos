-- StarterPlayerScripts/Dialogo/DialogoButtonHighlighter.lua
-- Destaca botones del HUD sin clonarlos: spotlight + UIStroke + puntero animado

--[[
    ╔════════════════════════════════════════════════════════════════╗
    ║           DIALOGOBUTTONHIGHLIGHTER — SEÑALIZACIÓN DE BOTONES  ║
    ╠════════════════════════════════════════════════════════════════╣
    ║  Estrategia de aislación (SIN clonar):                        ║
    ║  • Frame "SpotlightOverlay" se agrega al HUD (ZIndex alto),   ║
    ║    oscureciendo todo lo que queda debajo.                     ║
    ║  • El botón objetivo y sus ancestros reciben ZIndex aún mayor, ║
    ║    quedando visibles por encima del overlay.                  ║
    ║  • UIStroke + UIScale (opcional) dan el efecto de énfasis.    ║
    ║  • Puntero animado (línea + flecha) en ScreenGui independiente.║
    ║  • Todo se restaura exactamente al cerrar el diálogo.         ║
    ╚════════════════════════════════════════════════════════════════╝

    IMPORTANTE: El HUD se habilita temporalmente si estaba oculto.
    Al restaurar el botón, el HUD vuelve a su estado original.

    API pública:
        DialogoButtonHighlighter.new(hudGui)   → instance
        instance:destacarBoton(nombre, config)  → void
        instance:restaurarBoton(nombre)         → void
        instance:restaurarTodo()                → void
        instance:estaDestacado(nombre)          → boolean

    Config (tabla o string):
        nombre          = "BtnMapa",
        escala          = 1.2,            -- UIScale en el botón (1 = sin cambio)
        duracion        = 0.4,
        animacion       = "pulse",        -- "pulse" | "bounce" | "glow" | "none"
        flecha          = true,           -- mostrar puntero
        punteroDesde    = "dialogo",      -- "dialogo" | Vector2(escala 0-1)
        punteroEstilo   = "flecha",       -- "flecha" | "linea"
        punteroColor    = Color3(cyan),
        punteroAnimado  = true,
        textoAyuda      = "...",
        posicionTexto   = "auto",         -- "auto"|"arriba"|"abajo"|"izquierda"|"derecha"|"dialogo"
        oscurecerFondo  = true,
        alTerminar      = "restaurar",    -- "restaurar" | "mantener"
        onClick         = nil,
]]

local TweenService = game:GetService("TweenService")
local Players      = game:GetService("Players")

-- ════════════════════════════════════════════════════════════════
-- CONSTANTES
-- ════════════════════════════════════════════════════════════════

local POINTER_DISPLAY_ORDER = 120
local GLOW_COLOR            = Color3.fromRGB(0, 207, 255)
local SPOTLIGHT_ALPHA       = 0.60   -- opacidad del fondo oscuro
local LINE_THICKNESS        = 2
local ARROW_PX              = 22

local DEFAULT = {
	escala         = 1.2,
	duracion       = 0.4,
	animacion      = "pulse",
	flecha         = true,
	punteroDesde   = "dialogo",
	punteroEstilo  = "flecha",
	punteroColor   = GLOW_COLOR,
	punteroAnimado = true,
	oscurecerFondo = true,
	alTerminar     = "restaurar",
	onClick        = nil,
}

-- ════════════════════════════════════════════════════════════════
-- HELPERS INTERNOS
-- ════════════════════════════════════════════════════════════════

---Recorre todos los descendientes GuiObject y devuelve el ZIndex máximo encontrado
local function getMaxZIndex(root)
	local max = 1
	for _, desc in ipairs(root:GetDescendants()) do
		if desc:IsA("GuiObject") and desc.ZIndex > max then
			max = desc.ZIndex
		end
	end
	return max
end

---Construye la ruta [button → … → directChildOfHud] excluyendo hudRoot
local function buildPath(button, hudRoot)
	local path  = {}
	local node  = button
	local limit = 30
	while node and node ~= hudRoot and limit > 0 do
		table.insert(path, node)
		node  = node.Parent
		limit = limit - 1
	end
	return path
end

---ScreenGui independiente para el puntero y el texto de ayuda
local function crearPunteroOverlay(ignoreGuiInset)
	local gui = Instance.new("ScreenGui")
	gui.Name           = "DBH_PunteroOverlay"
	gui.IgnoreGuiInset = ignoreGuiInset
	gui.DisplayOrder   = POINTER_DISPLAY_ORDER
	gui.ResetOnSpawn   = false
	gui.Parent         = Players.LocalPlayer:WaitForChild("PlayerGui")
	return gui
end

---Calcula el origen del puntero en coordenadas absolutas del overlay
local function getOrigenPuntero(desde, viewport, ignoreGuiInset)
	local insetY   = ignoreGuiInset and 0 or 36
	local contentH = viewport.Y - insetY
	if typeof(desde) == "Vector2" then
		return Vector2.new(desde.X * viewport.X, desde.Y * contentH)
	end
	-- "dialogo": estimación del centro inferior donde está la DialogoGUI
	return Vector2.new(viewport.X * 0.5, contentH * 0.78)
end

---Dibuja línea + arrowhead animado de fromAbs → toAbs
local function crearPuntero(overlay, fromAbs, toAbs, estilo, color, animado, dur)
	local dx   = toAbs.X - fromAbs.X
	local dy   = toAbs.Y - fromAbs.Y
	local dist = math.sqrt(dx * dx + dy * dy)
	if dist < 2 then return nil, nil end

	local angle = math.deg(math.atan2(dy, dx))
	local ux, uy = dx / dist, dy / dist

	-- Línea (termina antes de la punta para no superponerse)
	local lineLen  = (estilo == "linea") and dist or math.max(0, dist - ARROW_PX * 0.6)
	local lineMidX = fromAbs.X + ux * lineLen * 0.5
	local lineMidY = fromAbs.Y + uy * lineLen * 0.5

	local line = Instance.new("Frame")
	line.Name                   = "PunteroLinea"
	line.Size                   = UDim2.new(0, lineLen, 0, LINE_THICKNESS)
	line.AnchorPoint            = Vector2.new(0.5, 0.5)
	line.Position               = UDim2.new(0, lineMidX, 0, lineMidY)
	line.BackgroundColor3       = color
	line.BackgroundTransparency = 1
	line.BorderSizePixel        = 0
	line.Rotation               = angle
	line.ZIndex                 = 3
	line.Parent                 = overlay
	TweenService:Create(line, TweenInfo.new(dur * 0.7), {BackgroundTransparency = 0.25}):Play()

	if estilo == "linea" then return line, nil end

	-- Arrowhead: "▶" rotado con Rotation=angle apunta en la dirección de la flecha
	local arrowFrame = Instance.new("Frame")
	arrowFrame.Name                   = "PunteroFlecha"
	arrowFrame.Size                   = UDim2.new(0, ARROW_PX, 0, ARROW_PX)
	arrowFrame.AnchorPoint            = Vector2.new(0.5, 0.5)
	arrowFrame.Position               = UDim2.new(0, toAbs.X, 0, toAbs.Y)
	arrowFrame.BackgroundTransparency = 1
	arrowFrame.Rotation               = angle
	arrowFrame.ZIndex                 = 4
	arrowFrame.Parent                 = overlay

	local arrowLabel = Instance.new("TextLabel")
	arrowLabel.Size                   = UDim2.fromScale(1, 1)
	arrowLabel.BackgroundTransparency = 1
	arrowLabel.Text                   = "▶"
	arrowLabel.TextColor3             = color
	arrowLabel.TextScaled             = true
	arrowLabel.Font                   = Enum.Font.GothamBold
	arrowLabel.TextTransparency       = 1
	arrowLabel.ZIndex                 = 4
	arrowLabel.Parent                 = arrowFrame
	TweenService:Create(arrowLabel, TweenInfo.new(dur * 0.7), {TextTransparency = 0}):Play()

	-- Pulso de escala en el arrowhead
	if animado then
		local big  = UDim2.new(0, ARROW_PX * 1.45, 0, ARROW_PX * 1.45)
		local base = arrowFrame.Size
		local function loop()
			if not arrowFrame.Parent then return end
			TweenService:Create(arrowFrame, TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = big}):Play()
			task.wait(0.45)
			if not arrowFrame.Parent then return end
			TweenService:Create(arrowFrame, TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = base}):Play()
			task.wait(0.45)
			loop()
		end
		task.spawn(loop)
	end

	return line, arrowFrame
end

-- ════════════════════════════════════════════════════════════════
-- EFECTOS (sobre UIStroke y UIScale del botón original)
-- ════════════════════════════════════════════════════════════════

-- pulse: UIStroke thickness + UIScale scale oscilan suavemente en loop
local function efectoPulse(stroke, uiScale, escala)
	local scaleBig = escala * 1.1
	local function loop()
		if not stroke.Parent then return end
		TweenService:Create(stroke, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Thickness = 5}):Play()
		if uiScale then TweenService:Create(uiScale, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Scale = scaleBig}):Play() end
		task.wait(0.55)
		if not stroke.Parent then return end
		TweenService:Create(stroke, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Thickness = 2}):Play()
		if uiScale then TweenService:Create(uiScale, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Scale = escala}):Play() end
		task.wait(0.55)
		loop()
	end
	task.spawn(loop)
end

-- bounce: spike elástico único en UIStroke y UIScale
local function efectoBounce(stroke, uiScale, escala)
	local ts = TweenService:Create(stroke, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out),     {Thickness = 9})
	local rs = TweenService:Create(stroke, TweenInfo.new(0.35, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Thickness = 2})
	ts:Play()
	ts.Completed:Connect(function() rs:Play() end)
	if uiScale then
		local tu = TweenService:Create(uiScale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out),     {Scale = escala * 1.3})
		local ru = TweenService:Create(uiScale, TweenInfo.new(0.35, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Scale = escala})
		tu:Play()
		tu.Completed:Connect(function() ru:Play() end)
	end
end

-- glow: UIStroke transparency oscila (aparece/desaparece el borde)
local function efectoGlow(stroke, _uiScale, _escala)
	local function loop()
		if not stroke.Parent then return end
		TweenService:Create(stroke, TweenInfo.new(0.75, Enum.EasingStyle.Sine), {Transparency = 0.55}):Play()
		task.wait(0.75)
		if not stroke.Parent then return end
		TweenService:Create(stroke, TweenInfo.new(0.75, Enum.EasingStyle.Sine), {Transparency = 0}):Play()
		task.wait(0.75)
		loop()
	end
	task.spawn(loop)
end

local EFECTOS = {
	pulse  = efectoPulse,
	bounce = efectoBounce,
	glow   = efectoGlow,
	none   = function() end,
}

-- ════════════════════════════════════════════════════════════════
-- CLASE PRINCIPAL
-- ════════════════════════════════════════════════════════════════

local DialogoButtonHighlighter = {}
DialogoButtonHighlighter.__index = DialogoButtonHighlighter

function DialogoButtonHighlighter.new(hudGui)
	return setmetatable({ hudGui = hudGui, _estado = {} }, DialogoButtonHighlighter)
end

function DialogoButtonHighlighter:_buscar(nombre)
	if not self.hudGui then
		warn("[DBH] hudGui nil al buscar:", nombre)
		return nil
	end
	local obj = self.hudGui:FindFirstChild(nombre, true)
	if not obj then warn("[DBH] Botón no encontrado:", nombre) end
	return obj
end

---Devuelve posición absoluta (ax,ay) y tamaño (aw,ah) en píxeles
-- AbsolutePosition se retiene aunque el ScreenGui esté deshabilitado.
function DialogoButtonHighlighter:_getAbsoluteRect(obj)
	local pos  = obj.AbsolutePosition
	local size = obj.AbsoluteSize
	local aw = size.X > 0 and size.X or (obj.Size.X.Offset > 0 and obj.Size.X.Offset or 80)
	local ah = size.Y > 0 and size.Y or (obj.Size.Y.Offset > 0 and obj.Size.Y.Offset or 36)
	return pos.X, pos.Y, aw, ah
end

-- ════════════════════════════════════════════════════════════════
-- LÓGICA PRINCIPAL: DESTACAR SIN CLONAR
-- ════════════════════════════════════════════════════════════════

function DialogoButtonHighlighter:destacarBoton(nombreBoton, config)
	if type(config) == "string" then config = {nombre = config} end
	config = config or {}
	local nombre = config.nombre or nombreBoton
	if not nombre or nombre == "" then
		warn("[DBH] destacarBoton: nombre vacío")
		return
	end

	if self._estado[nombre] then self:restaurarBoton(nombre) end

	-- Combinar defaults con la config recibida
	local cfg = {}
	for k, v in pairs(DEFAULT) do cfg[k] = v end
	for k, v in pairs(config)  do cfg[k] = v end
	cfg.nombre = nombre

	-- ── Paso 1: Encontrar el botón original ──
	local original = self:_buscar(nombre)
	if not original then return end

	-- ── Paso 2: Re-habilitar el HUD si estaba oculto ──
	-- El HUD se oculta durante el diálogo (hud.Enabled = false).
	-- Para mostrar el botón original necesitamos que sea visible.
	local hudWasDisabled = false
	if self.hudGui and not self.hudGui.Enabled then
		hudWasDisabled = true
		self.hudGui.Enabled = true
	end

	-- ── Paso 3: SpotlightFrame + ZIndex boost ──
	-- Construir ruta de ancestros desde el botón hasta el HUD root
	local path       = buildPath(original, self.hudGui)
	local savedZIndex = {}
	local spotlight  = nil

	if cfg.oscurecerFondo ~= false then
		-- Usar ZIndex dinámico para garantizar que el spotlight quede
		-- encima de todo el HUD existente, y el botón encima del spotlight.
		local maxZ      = getMaxZIndex(self.hudGui)
		local spotlightZ = maxZ + 1
		local focusZ     = maxZ + 2

		-- Frame oscuro cubre el HUD completo
		spotlight = Instance.new("Frame")
		spotlight.Name                   = "DBH_Spotlight"
		spotlight.Size                   = UDim2.fromScale(1, 1)
		spotlight.BackgroundColor3       = Color3.new(0, 0, 0)
		spotlight.BackgroundTransparency = 1   -- fade in
		spotlight.BorderSizePixel        = 0
		spotlight.ZIndex                 = spotlightZ
		spotlight.Parent                 = self.hudGui
		TweenService:Create(spotlight,
			TweenInfo.new(cfg.duracion * 0.6),
			{BackgroundTransparency = SPOTLIGHT_ALPHA}
		):Play()

		-- Elevar ZIndex de todos los ancestros del botón para que queden visibles
		for _, el in ipairs(path) do
			savedZIndex[el] = el.ZIndex
			el.ZIndex = focusZ
		end
	end

	-- ── Paso 4: UIStroke en el botón original ──
	local existingStroke = original:FindFirstChild("DBH_Stroke")
	if existingStroke then existingStroke:Destroy() end
	local stroke = Instance.new("UIStroke")
	stroke.Name         = "DBH_Stroke"
	stroke.Color        = cfg.punteroColor or GLOW_COLOR
	stroke.Thickness    = 2
	stroke.Transparency = 0
	stroke.Parent       = original

	-- ── Paso 5: UIScale (opcional, solo si escala ≠ 1) ──
	-- Nota: escala desde la esquina top-left del botón (AnchorPoint = 0,0 default).
	-- Si se necesita escalar desde el centro, ajustar AnchorPoint en Studio.
	local uiScale = nil
	if cfg.escala and cfg.escala ~= 1 then
		local existing = original:FindFirstChild("DBH_Scale")
		if existing then existing:Destroy() end
		uiScale = Instance.new("UIScale")
		uiScale.Name  = "DBH_Scale"
		uiScale.Scale = cfg.escala
		uiScale.Parent = original
	end

	-- ── Paso 6: Iniciar efecto de animación ──
	local fn = EFECTOS[cfg.animacion] or EFECTOS.pulse
	fn(stroke, uiScale, cfg.escala or 1)

	-- ── Paso 7: Click handler en el botón original ──
	local clickConn = nil
	if cfg.onClick then
		local btn = (original:IsA("TextButton") and original)
		         or original:FindFirstChildWhichIsA("TextButton", true)
		if btn then
			clickConn = btn.MouseButton1Click:Connect(function() pcall(cfg.onClick) end)
		end
	end

	-- ── Paso 8: Puntero + label en ScreenGui independiente ──
	local ax, ay, aw, ah = self:_getAbsoluteRect(original)
	local cx, cy = ax + aw * 0.5, ay + ah * 0.5

	local ignoreInset = self.hudGui and self.hudGui.IgnoreGuiInset or false
	local viewport    = workspace.CurrentCamera.ViewportSize

	local punteroOverlay = nil
	if cfg.flecha ~= false then
		punteroOverlay = crearPunteroOverlay(ignoreInset)
	end

	local _lineFrame, _arrowFrame = nil, nil

	if cfg.flecha ~= false and punteroOverlay then
		local origen = getOrigenPuntero(cfg.punteroDesde, viewport, ignoreInset)
		local dx = cx - origen.X
		local dy = cy - origen.Y
		local distOC = math.sqrt(dx * dx + dy * dy)
		local arrowTip
		if distOC > 1 then
			-- La punta se detiene en el borde del botón (considerando UIScale)
			local radio = math.max(aw, ah) * (cfg.escala or 1) * 0.5 + 6
			arrowTip = Vector2.new(
				cx - (dx / distOC) * radio,
				cy - (dy / distOC) * radio
			)
		else
			arrowTip = Vector2.new(cx, cy)
		end
		_lineFrame, _arrowFrame = crearPuntero(
			punteroOverlay, origen, arrowTip,
			cfg.punteroEstilo, cfg.punteroColor, cfg.punteroAnimado, cfg.duracion
		)
	end

	-- ── Guardar estado para restauración ──
	self._estado[nombre] = {
		original       = original,
		path           = path,
		savedZIndex    = savedZIndex,
		spotlight      = spotlight,
		stroke         = stroke,
		uiScale        = uiScale,
		clickConn      = clickConn,
		punteroOverlay = punteroOverlay,
		hudWasDisabled = hudWasDisabled,
		alTerminar     = cfg.alTerminar or "restaurar",
	}
	print("[DBH] Destacado (original):", nombre)
end

-- ════════════════════════════════════════════════════════════════
-- RESTAURACIÓN
-- ════════════════════════════════════════════════════════════════

---Restaura el botón y elimina todos los efectos con fade-out
-- @param nombreBoton string
function DialogoButtonHighlighter:restaurarBoton(nombreBoton)
	local st = self._estado[nombreBoton]
	if not st then return end
	self._estado[nombreBoton] = nil

	-- Restaurar ZIndex de la ruta de ancestros
	for _, el in ipairs(st.path or {}) do
		if el.Parent and st.savedZIndex[el] ~= nil then
			el.ZIndex = st.savedZIndex[el]
		end
	end

	-- Fade-out y destrucción del SpotlightFrame
	if st.spotlight and st.spotlight.Parent then
		TweenService:Create(st.spotlight, TweenInfo.new(0.18), {BackgroundTransparency = 1}):Play()
		task.delay(0.22, function()
			if st.spotlight and st.spotlight.Parent then st.spotlight:Destroy() end
		end)
	end

	-- Quitar UIStroke y UIScale del botón original
	if st.stroke and st.stroke.Parent then
		st.stroke:Destroy()
	end
	if st.uiScale and st.uiScale.Parent then
		st.uiScale:Destroy()
	end

	-- Desconectar click handler
	if st.clickConn then
		st.clickConn:Disconnect()
	end

	-- Destruir overlay del puntero
	if st.punteroOverlay and st.punteroOverlay.Parent then
		st.punteroOverlay:Destroy()
	end

	-- Volver a deshabilitar el HUD si nosotros lo habilitamos
	-- (ControladorDialogo llamará a mostrarHUD() justo después de restaurarTodo())
	if st.hudWasDisabled and self.hudGui and self.hudGui.Parent then
		self.hudGui.Enabled = false
	end

	print("[DBH] Restaurado:", nombreBoton)
end

---Restaura todos los botones destacados activos
function DialogoButtonHighlighter:restaurarTodo()
	local nombres = {}
	for nombre in pairs(self._estado) do table.insert(nombres, nombre) end
	for _, nombre in ipairs(nombres)  do self:restaurarBoton(nombre) end
end

---Devuelve true si el botón está actualmente destacado
-- @param nombreBoton string → boolean
function DialogoButtonHighlighter:estaDestacado(nombreBoton)
	return self._estado[nombreBoton] ~= nil
end

return DialogoButtonHighlighter
