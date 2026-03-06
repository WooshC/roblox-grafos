-- ReplicatedStorage/Efectos/EfectosDialogo.lua
-- Efectos visuales exclusivos para el sistema de diálogos.
-- Encapsula: highlights, labels de nodos, arista falsa con billboard y blink.
--
-- Estructura de nodo esperada (NivelActual):
--   Nodo1_z1/           (Model)
--     Selector/          (Model o BasePart)
--       Attachment       (Attachment) ← para Beams
--       ClickDetector
--     Decoracion/
--
-- Todos los efectos usan el prefijo "Dialogo_" para poder
-- limpiarlos todos juntos con limpiarTodo().

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")

local EfectosHighlight = require(ReplicatedStorage:WaitForChild("Efectos"):WaitForChild("EfectosHighlight"))
local BillboardNombres = require(ReplicatedStorage:WaitForChild("Efectos"):WaitForChild("BillboardNombres"))

local EfectosDialogo = {}

-- ════════════════════════════════════════════════════════════════════
-- ESTADO INTERNO
-- ════════════════════════════════════════════════════════════════════

-- Parts temporales creadas (aristas falsas, anclas) → destruir en limpiarTodo
local _partsTemporales = {}

-- Beams de aristas falsas activos  { clave → { ancla, beam, pulsoConn } }
local _aristasFalsas = {}

-- Threads de blink activos  { clave → thread }
local _blinks = {}

-- ════════════════════════════════════════════════════════════════════
-- HELPERS PRIVADOS
-- ════════════════════════════════════════════════════════════════════

---Busca un nodo por nombre dentro de NivelActual (recursivo)
local function buscarNodo(nombre)
	local nivel = workspace:FindFirstChild("NivelActual")
	if not nivel then return nil end
	return nivel:FindFirstChild(nombre, true)
end

---Devuelve la BasePart del Selector de un nodo
local function getSelectorPart(nodo)
	if not nodo then return nil end
	local sel = nodo:FindFirstChild("Selector")
	if not sel then return nil end
	if sel:IsA("BasePart") then return sel end
	if sel:IsA("Model") then
		return sel.PrimaryPart or sel:FindFirstChildOfClass("BasePart")
	end
	return nil
end

---Devuelve la posición central de un nodo (via Selector o pivot)
local function getPosNodo(nodo)
	if not nodo then return Vector3.zero end
	local sel = getSelectorPart(nodo)
	if sel then return sel.Position end
	if nodo:IsA("Model") then return nodo:GetPivot().Position end
	if nodo:IsA("BasePart") then return nodo.Position end
	return Vector3.zero
end

---Devuelve (o crea) un Attachment dentro del Selector de un nodo
local function getAttachment(nodo, nombreAtt)
	local sel = getSelectorPart(nodo)
	if not sel then return nil end

	local att = sel:FindFirstChild(nombreAtt)
	if att and att:IsA("Attachment") then return att end

	-- Crear temporal
	att = Instance.new("Attachment")
	att.Name   = nombreAtt
	att.Parent = sel
	table.insert(_partsTemporales, att)
	return att
end

---Genera una clave de par de nodos (orden lexicográfico)
local function clavePar(a, b)
	return a < b and (a .. "|" .. b) or (b .. "|" .. a)
end

-- ════════════════════════════════════════════════════════════════════
-- API PÚBLICA
-- ════════════════════════════════════════════════════════════════════

-- ── HIGHLIGHTS ───────────────────────────────────────────────────────
-- tipo: "SELECCIONADO" | "AISLADO" | "ADYACENTE" | "CONECTADO" | "EXITO" | "ERROR"
-- La clave interna siempre es "Dialogo_<nombreNodo>" para permitir limpiar por prefijo.

---Resalta un nodo con EfectosHighlight
-- @param nombreNodo  string  — nombre del Model en NivelActual
-- @param tipo        string  — tipo de highlight (ver EfectosHighlight.CONFIG)
function EfectosDialogo.resaltarNodo(nombreNodo, tipo)
	local nodo = buscarNodo(nombreNodo)
	if not nodo then
		warn("[EfectosDialogo] Nodo no encontrado:", nombreNodo)
		return
	end
	local clave = "Dialogo_" .. nombreNodo
	EfectosHighlight.crear(clave, nodo, tipo)
end

---Quita el highlight de un nodo específico
function EfectosDialogo.quitarHighlight(nombreNodo)
	EfectosHighlight.destruir("Dialogo_" .. nombreNodo)
end

-- ── LABEL SOBRE NODO ─────────────────────────────────────────────────
-- Fondo negro semitransparente + borde y texto del color del highlight activo.
-- Se ancla al Selector del nodo con StudsOffsetWorldSpace para que siempre
-- quede sobre el nodo independientemente del ángulo de cámara.

-- Mapa tipo → color (mismo que EfectosHighlight.COLORES)
local TIPO_COLOR = {
	SELECCIONADO = Color3.fromRGB(0,   212, 255),  -- cyan
	ADYACENTE    = Color3.fromRGB(255, 200,  50),  -- dorado
	CONECTADO    = Color3.fromRGB(0,   212, 255),  -- cyan
	AISLADO      = Color3.fromRGB(239,  68,  68),  -- rojo
	EXITO        = Color3.fromRGB(34,  197,  94),  -- verde
	ERROR        = Color3.fromRGB(239,  68,  68),  -- rojo
}

---Muestra una etiqueta de texto sobre un nodo
-- @param nombreNodo string — nombre del Model en NivelActual
-- @param texto      string — texto a mostrar (generalmente el alias)
-- @param tipo       string — tipo de highlight para determinar el color (opcional, default "SELECCIONADO")
function EfectosDialogo.mostrarLabel(nombreNodo, texto, tipo)
	local nodo = buscarNodo(nombreNodo)
	if not nodo then return end

	local sel = getSelectorPart(nodo)
	if not sel then return end

	local clave = "Dialogo_Label_" .. nombreNodo

	-- Destruir anterior si existe
	BillboardNombres.destruir(clave)

	local color = TIPO_COLOR[tipo] or TIPO_COLOR.SELECCIONADO

	-- BillboardGui
	local bb = Instance.new("BillboardGui")
	bb.Name                    = clave
	bb.Adornee                 = sel
	bb.StudsOffsetWorldSpace   = Vector3.new(0, 4.5, 0)
	bb.AlwaysOnTop             = true
	bb.Size                    = UDim2.fromOffset(120, 32)
	bb.ResetOnSpawn            = false
	bb.LightInfluence          = 0
	bb.Parent                  = workspace

	-- Fondo negro semitransparente
	local bg = Instance.new("Frame")
	bg.Size                    = UDim2.fromScale(1, 1)
	bg.BackgroundColor3        = Color3.new(0, 0, 0)
	bg.BackgroundTransparency  = 0.45
	bg.BorderSizePixel         = 0
	bg.Parent                  = bb

	local corner = Instance.new("UICorner")
	corner.CornerRadius        = UDim.new(0, 6)
	corner.Parent              = bg

	-- Borde de color
	local stroke = Instance.new("UIStroke")
	stroke.Color               = color
	stroke.Thickness           = 2
	stroke.Parent              = bg

	-- Texto
	local label = Instance.new("TextLabel")
	label.Size                 = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text                 = texto
	label.TextColor3           = color
	label.TextScaled           = true
	label.Font                 = Enum.Font.GothamBold
	label.Parent               = bg

	-- Registrar en BillboardNombres para que limpiarTodo() lo encuentre por prefijo
	-- (accedemos al cache interno via un billboard "fantasma" registrado con la clave)
	-- En su lugar, lo guardamos en _partsTemporales para destrucción manual
	table.insert(_partsTemporales, bb)
end

---Quita la etiqueta de un nodo
function EfectosDialogo.quitarLabel(nombreNodo)
	-- Buscar en workspace (registrado con el nombre = clave)
	local clave = "Dialogo_Label_" .. nombreNodo
	local bb = workspace:FindFirstChild(clave)
	if bb then bb:Destroy() end
	-- También limpiar del cache de BillboardNombres por si acaso
	BillboardNombres.destruir(clave)
end

-- ── ARISTA FALSA ─────────────────────────────────────────────────────
-- Dibuja un Beam entre los Selector de dos nodos y
-- muestra un BillboardGui "⟵ ARISTA ⟶" en el punto medio.
-- También anima el Beam con un pulso de grosor.

---Crea una arista visual falsa entre dos nodos
-- @param nombreA   string — nombre del primer nodo
-- @param nombreB   string — nombre del segundo nodo
-- @param colorTipo string — "SELECCIONADO" | "ADYACENTE" | "EXITO" (define el color del beam)
function EfectosDialogo.mostrarArista(nombreA, nombreB, colorTipo)
	local clave = clavePar(nombreA, nombreB)

	-- Destruir anterior si existe
	EfectosDialogo.quitarArista(nombreA, nombreB)

	local nodoA = buscarNodo(nombreA)
	local nodoB = buscarNodo(nombreB)
	if not (nodoA and nodoB) then
		warn("[EfectosDialogo] No se encontraron nodos para arista:", nombreA, nombreB)
		return
	end

	-- Attachments en los Selectores
	local attA = getAttachment(nodoA, "Dialogo_AttA")
	local attB = getAttachment(nodoB, "Dialogo_AttB")
	if not (attA and attB) then return end

	-- Color según tipo
	local colores = EfectosHighlight.COLORES
	local COLOR_MAP = {
		SELECCIONADO = colores.SELECCIONADO,   -- cyan
		ADYACENTE    = colores.ADYACENTE,       -- dorado
		EXITO        = colores.EXITO,           -- verde
		AISLADO      = colores.AISLADO,         -- rojo
	}
	local color = COLOR_MAP[colorTipo] or colores.SELECCIONADO

	-- Part ancla invisible para el Beam (los beams necesitan estar parented)
	local ancla = Instance.new("Part")
	ancla.Name        = "EfectosDialogo_Arista_" .. clave
	ancla.Anchored    = true
	ancla.CanCollide  = false
	ancla.Transparency = 1
	ancla.Size        = Vector3.new(0.1, 0.1, 0.1)
	ancla.Position    = getPosNodo(nodoA):Lerp(getPosNodo(nodoB), 0.5)
	ancla.Parent      = workspace
	table.insert(_partsTemporales, ancla)

	-- Beam
	local beam = Instance.new("Beam")
	beam.Name         = "Beam_" .. clave
	beam.Attachment0  = attA
	beam.Attachment1  = attB
	beam.Color        = ColorSequence.new(color)
	beam.Width0       = 0.18
	beam.Width1       = 0.18
	beam.CurveSize0   = 0
	beam.CurveSize1   = 0
	beam.LightEmission = 0.8
	beam.LightInfluence = 0.3
	beam.Transparency = NumberSequence.new(0)
	beam.FaceCamera   = true
	beam.Segments     = 10
	beam.Parent       = ancla

	-- Pulso de grosor (mismo patrón que EfectosCable)
	local pulsoConn = RunService.Heartbeat:Connect(function(dt)
		if not beam or not beam.Parent then return end
		local t = tick() * 3
		local alpha = (math.sin(t) + 1) / 2
		beam.Width0 = 0.14 + alpha * 0.10
		beam.Width1 = 0.14 + alpha * 0.10
	end)

	-- Billboard "ARISTA" en el punto medio
	local posA = getPosNodo(nodoA)
	local posB = getPosNodo(nodoB)
	local mid  = posA:Lerp(posB, 0.5)

	local anclaLabel = Instance.new("Part")
	anclaLabel.Name       = "EfectosDialogo_AristaLabel_" .. clave
	anclaLabel.Anchored   = true
	anclaLabel.CanCollide = false
	anclaLabel.Transparency = 1
	anclaLabel.Size       = Vector3.new(0.1, 0.1, 0.1)
	anclaLabel.Position   = mid
	anclaLabel.Parent     = workspace
	table.insert(_partsTemporales, anclaLabel)

	-- BillboardGui sobre la ancla de la etiqueta
	local bb = Instance.new("BillboardGui")
	bb.Name           = "Dialogo_BillboardArista_" .. clave
	bb.Adornee        = anclaLabel
	bb.AlwaysOnTop    = true
	bb.LightInfluence = 0
	bb.Size           = UDim2.new(0, 180, 0, 52)
	bb.StudsOffset    = Vector3.new(0, 3, 0)
	bb.MaxDistance    = 0
	bb.Parent         = workspace

	local frame = Instance.new("Frame")
	frame.Size                   = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.35
	frame.BorderSizePixel        = 0
	frame.Parent                 = bb

	local stroke = Instance.new("UIStroke")
	stroke.Color       = color
	stroke.Thickness   = 2
	stroke.Transparency = 0.15
	stroke.Parent      = frame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent       = frame

	local label = Instance.new("TextLabel")
	label.Size                   = UDim2.new(1, -8, 1, -4)
	label.Position               = UDim2.new(0, 4, 0, 2)
	label.BackgroundTransparency = 1
	label.Text                   = "⟵  ARISTA  ⟶"
	label.TextColor3             = color
	label.Font                   = Enum.Font.GothamBold
	label.TextSize               = 15
	label.TextScaled             = false
	label.TextTransparency       = 1
	label.Parent                 = frame

	-- Aparecer suave
	frame.BackgroundTransparency = 1
	TweenService:Create(frame, TweenInfo.new(0.4), { BackgroundTransparency = 0.35 }):Play()
	TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 0 }):Play()
	TweenService:Create(beam,  TweenInfo.new(0.35, Enum.EasingStyle.Quad),
		{ Width0 = 0.18, Width1 = 0.18 }):Play()

	-- Animación float del billboard
	local floatConn = RunService.Heartbeat:Connect(function()
		if not anclaLabel or not anclaLabel.Parent then return end
		local t   = tick() * 0.8
		local yOff = math.sin(t) * 0.4
		bb.StudsOffset = Vector3.new(0, 3 + yOff, 0)
	end)

	_aristasFalsas[clave] = {
		ancla      = ancla,
		anclaLabel = anclaLabel,
		billboard  = bb,
		beam       = beam,
		pulsoConn  = pulsoConn,
		floatConn  = floatConn,
	}
end

---Destruye una arista falsa con fade-out
function EfectosDialogo.quitarArista(nombreA, nombreB)
	local clave = clavePar(nombreA, nombreB)
	local datos = _aristasFalsas[clave]
	if not datos then return end

	-- Desconectar loops
	if datos.pulsoConn then datos.pulsoConn:Disconnect() end
	if datos.floatConn then datos.floatConn:Disconnect() end

	-- Fade out
	if datos.beam and datos.beam.Parent then
		TweenService:Create(datos.beam, TweenInfo.new(0.3),
			{ Width0 = 0, Width1 = 0 }):Play()
	end
	if datos.billboard and datos.billboard.Parent then
		local fr = datos.billboard:FindFirstChild("Fondo") or datos.billboard:FindFirstChild("Frame")
		if fr then
			TweenService:Create(fr, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
			local lbl = fr:FindFirstChildOfClass("TextLabel")
			if lbl then
				TweenService:Create(lbl, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
			end
		end
	end

	task.delay(0.35, function()
		if datos.ancla      and datos.ancla.Parent      then datos.ancla:Destroy() end
		if datos.anclaLabel and datos.anclaLabel.Parent then datos.anclaLabel:Destroy() end
		if datos.billboard  and datos.billboard.Parent  then datos.billboard:Destroy() end
	end)

	_aristasFalsas[clave] = nil
end

-- ── BLINK (parpadeo de highlight) ────────────────────────────────────
-- Alterna entre el tipo dado y ningún highlight, N veces.
-- Equivalente al viejo VisualEffectsService:blink().

---Hace parpadear el highlight de un nodo
-- @param nombreNodo  string  — nombre del nodo
-- @param tipo        string  — tipo de highlight en los pulsos "on"
-- @param ciclos      number  — cuántas veces parpadear (default 4)
-- @param intervaloOn number  — segundos encendido (default 0.35)
-- @param intervaloOff number — segundos apagado  (default 0.25)
function EfectosDialogo.blink(nombreNodo, tipo, ciclos, intervaloOn, intervaloOff)
	local clave  = "Dialogo_" .. nombreNodo
	ciclos       = ciclos      or 4
	intervaloOn  = intervaloOn  or 0.35
	intervaloOff = intervaloOff or 0.25

	-- Cancelar blink anterior si existe
	EfectosDialogo.detenerBlink(nombreNodo)

	local nodo = buscarNodo(nombreNodo)
	if not nodo then return end

	local thread = task.spawn(function()
		for _ = 1, ciclos do
			EfectosHighlight.crear(clave, nodo, tipo)
			task.wait(intervaloOn)
			EfectosHighlight.destruir(clave)
			task.wait(intervaloOff)
		end
		-- Dejar el highlight encendido al terminar
		EfectosHighlight.crear(clave, nodo, tipo)
		_blinks[nombreNodo] = nil
	end)

	_blinks[nombreNodo] = thread
end

---Detiene el blink de un nodo sin limpiar el highlight
function EfectosDialogo.detenerBlink(nombreNodo)
	local thread = _blinks[nombreNodo]
	if thread then
		task.cancel(thread)
		_blinks[nombreNodo] = nil
	end
end

-- ── LIMPIEZA ─────────────────────────────────────────────────────────

---Limpia TODOS los efectos del diálogo activo:
--- highlights, labels, aristas, blinks, parts temporales.
function EfectosDialogo.limpiarTodo()
	-- Highlights con prefijo "Dialogo_"
	EfectosHighlight.destruirPorPrefijo("Dialogo_")

	-- Labels (BillboardGui en workspace con Name = "Dialogo_Label_*")
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj:IsA("BillboardGui") and obj.Name:sub(1, 13) == "Dialogo_Label" then
			obj:Destroy()
		end
	end
	BillboardNombres.destruirPorPrefijo("Dialogo_Label_")

	-- Aristas falsas
	for clave, datos in pairs(_aristasFalsas) do
		if datos.pulsoConn then datos.pulsoConn:Disconnect() end
		if datos.floatConn then datos.floatConn:Disconnect() end
		if datos.ancla      and datos.ancla.Parent      then datos.ancla:Destroy() end
		if datos.anclaLabel and datos.anclaLabel.Parent then datos.anclaLabel:Destroy() end
		if datos.billboard  and datos.billboard.Parent  then datos.billboard:Destroy() end
	end
	_aristasFalsas = {}

	-- Blinks
	for nombre, thread in pairs(_blinks) do
		task.cancel(thread)
	end
	_blinks = {}

	-- Parts temporales (attachments creados dinámicamente, etc.)
	for _, inst in ipairs(_partsTemporales) do
		if inst and inst.Parent then inst:Destroy() end
	end
	_partsTemporales = {}
end

return EfectosDialogo