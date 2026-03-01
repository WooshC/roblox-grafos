-- EfectosZonas.lua
-- Sistema de billboards y highlights para zonas del nivel (solo visible en modo mapa)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EfectosHighlight = require(ReplicatedStorage.Efectos.EfectosHighlight)
local EfectosZonas = {}

-- Estado
local billboardsCreados = {} -- nombreZona -> BillboardGui
local triggersCreados    = {} -- nombreZona -> BasePart (trigger part)
local configZonas = nil      -- Configuración de zonas desde LevelsConfig
local nivelActual = nil
local zonaActual = nil       -- Zona donde está el jugador actualmente
local mapaVisible = false    -- Si el mapa está actualmente abierto

-- Configuración visual
local CONFIG = {
	tamanoBillboard = UDim2.new(0, 200, 0, 50),
	offsetVertical = 8,          -- Studs arriba del trigger
	colorFondo = Color3.fromRGB(0, 0, 0),
	transparenciaFondo = 0.5,
	colorTexto = Color3.fromRGB(255, 255, 255),
	colorBorde = Color3.fromRGB(0, 212, 255), -- Cyan para zonas
	transparenciaBorde = 0.3,
	tamanoTexto = 14,
	fuente = Enum.Font.GothamBold,
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════════════════════

function EfectosZonas.inicializar(nivelModel, configNivel)
	nivelActual = nivelModel
	configZonas = configNivel and configNivel.Zonas or {}
	billboardsCreados = {}
	triggersCreados   = {}
	zonaActual = nil
	mapaVisible = false

	print("[EfectosZonas] Inicializado")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- BUSCAR TRIGGER DE ZONA
-- ═══════════════════════════════════════════════════════════════════════════════

function EfectosZonas._obtenerParteTrigger(nombreTrigger)
	if not nivelActual then return nil end

	local trigger = nivelActual:FindFirstChild(nombreTrigger, true)
	if trigger and trigger:IsA("BasePart") then
		return trigger
	end

	trigger = Workspace:FindFirstChild(nombreTrigger, true)
	if trigger and trigger:IsA("BasePart") then
		return trigger
	end

	return nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CREAR BILLBOARD PARA UNA ZONA
-- ═══════════════════════════════════════════════════════════════════════════════

function EfectosZonas._crearBillboardZona(nombreZona, datosZona)
	local nombreTrigger = datosZona.Trigger
	local descripcion = datosZona.Descripcion

	if not nombreTrigger or not descripcion then
		warn("[EfectosZonas] Zona incompleta:", nombreZona)
		return nil
	end

	local parteTrigger = EfectosZonas._obtenerParteTrigger(nombreTrigger)
	if not parteTrigger then
		warn("[EfectosZonas] No se encontró trigger:", nombreTrigger)
		return nil
	end

	-- Guardar referencia al trigger para poder recrear el highlight después
	triggersCreados[nombreZona] = parteTrigger

	-- Destruir billboard anterior si existe
	local nombreBillboard = "ZonaBB_" .. nombreZona
	local anterior = Workspace:FindFirstChild(nombreBillboard)
	if anterior then
		anterior:Destroy()
	end

	-- Crear BillboardGui
	local billboard = Instance.new("BillboardGui")
	billboard.Name = nombreBillboard
	billboard.Adornee = parteTrigger
	billboard.Size = CONFIG.tamanoBillboard
	billboard.StudsOffset = Vector3.new(0, CONFIG.offsetVertical, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 500
	billboard.Parent = Workspace

	-- Fondo con borde
	local frame = Instance.new("Frame")
	frame.Name = "Fondo"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = CONFIG.colorFondo
	frame.BackgroundTransparency = CONFIG.transparenciaFondo
	frame.BorderSizePixel = 0
	frame.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = CONFIG.colorBorde
	stroke.Thickness = 2
	stroke.Transparency = CONFIG.transparenciaBorde
	stroke.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)
	padding.Parent = frame

	local label = Instance.new("TextLabel")
	label.Name = "Descripcion"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = descripcion
	label.TextColor3 = CONFIG.colorTexto
	label.TextScaled = true
	label.Font = CONFIG.fuente
	label.TextSize = CONFIG.tamanoTexto
	label.Parent = frame

	billboardsCreados[nombreZona] = billboard

	-- Crear Highlight en la part del trigger
	EfectosHighlight.resaltarZona(nombreZona, parteTrigger)

	print("[EfectosZonas] Billboard y Highlight creados para", nombreZona, "->", descripcion)
	return billboard
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- MOSTRAR/OCULTAR BILLBOARDS
-- ═══════════════════════════════════════════════════════════════════════════════

function EfectosZonas.mostrarTodos()
	mapaVisible = true
	if not configZonas then return end

	-- Crear billboards para las zonas que no existen aún
	for nombreZona, datosZona in pairs(configZonas) do
		if not billboardsCreados[nombreZona] then
			EfectosZonas._crearBillboardZona(nombreZona, datosZona)
		else
			-- Billboard ya existe, pero el highlight pudo haber sido destruido al cerrar el mapa.
			-- Recrearlo a partir del trigger guardado.
			local parteTrigger = triggersCreados[nombreZona]
			if parteTrigger then
				EfectosHighlight.resaltarZona(nombreZona, parteTrigger)
			end
		end
	end

	-- Mostrar/ocultar según zona actual del jugador
	for nombreZona, billboard in pairs(billboardsCreados) do
		if billboard and billboard.Parent then
			local esCurrent = (nombreZona == zonaActual)
			billboard.Enabled = not esCurrent

			local h = EfectosHighlight.obtener("Zona_" .. nombreZona)
			if h then h.Enabled = not esCurrent end
		end
	end

	print("[EfectosZonas] Billboards y Highlights mostrados (zona actual oculta:", zonaActual or "ninguna", ")")
end

function EfectosZonas.ocultarTodos()
	mapaVisible = false
	-- Deshabilitar todos los billboards
	for _, billboard in pairs(billboardsCreados) do
		if billboard and billboard.Parent then
			billboard.Enabled = false
		end
	end

	-- Destruir todos los highlights de zonas (se recrean en mostrarTodos)
	EfectosHighlight.limpiarTodasZonas()

	print("[EfectosZonas] Billboards y Highlights ocultos")
end

function EfectosZonas.limpiar()
	mapaVisible = false
	-- Destruir todos los billboards
	for _, billboard in pairs(billboardsCreados) do
		if billboard and billboard.Parent then
			billboard:Destroy()
		end
	end

	-- Destruir todos los highlights de zonas
	EfectosHighlight.limpiarTodasZonas()

	billboardsCreados = {}
	triggersCreados   = {}
	configZonas = nil
	nivelActual = nil
	zonaActual = nil

	print("[EfectosZonas] Limpieza completada")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- GESTIÓN DE ZONA ACTUAL
-- ═══════════════════════════════════════════════════════════════════════════════

---Establece la zona actual donde está el jugador y oculta su billboard y highlight
function EfectosZonas.establecerZonaActual(nombreZona)
	local zonaAnterior = zonaActual
	zonaActual = nombreZona

	-- Solo actualizar visibilidad si el mapa está abierto
	if not mapaVisible then return end

	-- Mostrar el billboard y highlight de la zona anterior
	if zonaAnterior then
		local bb = billboardsCreados[zonaAnterior]
		if bb then bb.Enabled = true end

		local h = EfectosHighlight.obtener("Zona_" .. zonaAnterior)
		if h then h.Enabled = true end

		print("[EfectosZonas] Zona anterior restaurada:", zonaAnterior)
	end

	-- Ocultar el billboard y highlight de la zona actual
	if zonaActual then
		local bb = billboardsCreados[zonaActual]
		if bb then bb.Enabled = false end

		local h = EfectosHighlight.obtener("Zona_" .. zonaActual)
		if h then h.Enabled = false end

		print("[EfectosZonas] Zona actual ocultada:", zonaActual)
	end
end

---Obtiene la zona actual
function EfectosZonas.obtenerZonaActual()
	return zonaActual
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- ACTUALIZAR VISIBILIDAD (útil cuando cambia la zona mientras el mapa está abierto)
-- ═══════════════════════════════════════════════════════════════════════════════

function EfectosZonas.actualizarVisibilidad()
	for nombreZona, billboard in pairs(billboardsCreados) do
		if billboard and billboard.Parent then
			local esCurrent = (nombreZona == zonaActual)
			billboard.Enabled = not esCurrent

			local h = EfectosHighlight.obtener("Zona_" .. nombreZona)
			if h then h.Enabled = not esCurrent end
		end
	end
end

return EfectosZonas
