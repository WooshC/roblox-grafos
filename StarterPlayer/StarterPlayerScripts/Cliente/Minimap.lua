--[[
	MINIMAPA INTEGRADO v2 - Dentro de GUIExplorador

	ESTADOS DE COLOR (solo cambia el Selector dentro del clon):
	  🟡 AMARILLO — Adyacente del nodo seleccionado
	  🔵 AZUL     — Conectado (tiene cables pero no energizado)
	  🟢 VERDE    — Energizado (alcanzable desde inicio)
	  🔴 ROJO     — Sin conectar
	  ⚪ GRIS     — Nodo inicio / especial

	CABLES: partes cilíndricas (verde=energizado, azul=conectado, gris=sin energía)
	PUNTERO: esfera amarilla que sigue al jugador
	PARTÍCULAS: clonadas y sincronizadas cada frame
]]

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player       = Players.LocalPlayer
local playerGui    = player:WaitForChild("PlayerGui")
local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))

print("🗺️ [Minimap] Iniciando...")

-- ================================================================
-- GUI BASE
-- ================================================================

local gui = playerGui:WaitForChild("GUIExplorador", 10)
if not gui then warn("❌ GUIExplorador no encontrada"); return end

local contenedorMiniMapa = gui:FindFirstChild("ContenedorMiniMapa")
if not contenedorMiniMapa then warn("❌ ContenedorMiniMapa no encontrado"); return end

local vista = contenedorMiniMapa:FindFirstChild("Vista")

local worldModel = vista:FindFirstChild("WorldModel")
if not worldModel then
	worldModel = Instance.new("WorldModel")
	worldModel.Name = "WorldModel"
	worldModel.Parent = vista
end

local miniCamera = vista.CurrentCamera
if not miniCamera then
	miniCamera = Instance.new("Camera")
	miniCamera.FieldOfView = 70
	miniCamera.Parent = vista
	vista.CurrentCamera = miniCamera
end

-- ================================================================
-- CONFIGURACIÓN
-- ================================================================

local ZOOM             = 100
local TAMANO_NODO      = 5    -- Tamaño de la Part cuadrada que representa cada nodo
local TAMANO_PARTICULA = 5    -- Tamaño de las TrafficParticle en el minimapa

local COL_ADYACENTE        = Color3.fromRGB(255, 220,   0)
local COL_ENERGIZADO       = Color3.fromRGB(46,  204, 113)
local COL_CONECTADO        = Color3.fromRGB(52,  152, 219)
local COL_LIBRE            = Color3.fromRGB(231,  76,  60)
local COL_INICIO           = Color3.fromRGB(180, 180, 180)
local COL_CABLE_ENERGIZADO = Color3.fromRGB(46,  204, 113)
local COL_CABLE_CONECTADO  = Color3.fromRGB(52,  152, 219)
local COL_CABLE_GRIS       = Color3.fromRGB(80,   80,  80)

-- ================================================================
-- ESTADO
-- ================================================================

local nivelActualIDAnterior = -999
local carpetaPostesReal     = nil
local nombreInicio          = nil
local mapaPostes            = {}  -- { [nombre] = { Poste, Clon, SelectorClon, Particulas } }
local nodosAdyacentes       = {}
local listaCables           = {}
local listaParticulas       = {}
local cantCablesAnterior    = 0
local punteroJugador        = nil
local updateConnection      = nil

-- ================================================================
-- PUNTERO DEL JUGADOR
-- ================================================================

local function crearPunteroJugador()
	if punteroJugador and punteroJugador.Parent then
		punteroJugador:Destroy()
	end
	local part = Instance.new("Part")
	part.Name         = "PunteroJugador"
	part.Anchored     = true
	part.CanCollide   = false
	part.CastShadow   = false
	part.Size         = Vector3.new(4, 4, 4)
	part.Color        = Color3.fromRGB(255, 220, 0)
	part.Material     = Enum.Material.Neon
	part.Transparency = 0
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent   = part
	part.Parent   = worldModel
	punteroJugador = part
end

-- ================================================================
-- LISTENER: CableDragEvent
-- ================================================================

local Events       = ReplicatedStorage:WaitForChild("Events", 10)
local Remotes      = Events and Events:WaitForChild("Remotes", 5)
local cableDragEvt = Remotes and Remotes:FindFirstChild("CableDragEvent")

if cableDragEvt then
	cableDragEvt.OnClientEvent:Connect(function(accion, _attachment, neighbors)
		if accion == "Start" and neighbors then
			nodosAdyacentes = {}
			for _, vecino in ipairs(neighbors) do
				if typeof(vecino) == "Instance" then
					nodosAdyacentes[vecino.Name] = true
				end
			end
		elseif accion == "Stop" then
			nodosAdyacentes = {}
		end
	end)
	print("✅ CableDragEvent conectado")
else
	warn("⚠️ CableDragEvent no encontrado")
end

-- ================================================================
-- UTILIDADES
-- ================================================================

local function tieneCable(poste)
	local conns = poste:FindFirstChild("Connections")
	return conns ~= nil and #conns:GetChildren() > 0
end

local function resolverColor(nombre, poste)
	if nombre == "PostePanel" or nombre == "GeneradorCentral"
		or nombre == "PosteFinal" or nombre == "TorreControl"
		or nombre == nombreInicio then
		return COL_INICIO, Enum.Material.SmoothPlastic
	end
	if nodosAdyacentes[nombre] then
		return COL_ADYACENTE, Enum.Material.Neon
	end
	if poste:GetAttribute("Energizado") == true then
		return COL_ENERGIZADO, Enum.Material.Neon
	end
	if tieneCable(poste) then
		return COL_CONECTADO, Enum.Material.Neon
	end
	return COL_LIBRE, Enum.Material.Neon
end

-- ================================================================
-- FUNCIÓN: CARGAR POSTES
-- Base idéntica al código funcional anterior +
-- búsqueda de SelectorClon y recolección de partículas
-- ================================================================

local function cargarPostes(nivelID)
	if nivelActualIDAnterior == nivelID and carpetaPostesReal and next(mapaPostes) then
		print("⚠️ Nivel " .. nivelID .. " ya cargado")
		return
	end

	print("🗺️ Cargando postes para nivel " .. nivelID)

	worldModel:ClearAllChildren()
	mapaPostes         = {}
	listaCables        = {}
	listaParticulas    = {}
	nodosAdyacentes    = {}
	carpetaPostesReal  = nil
	cantCablesAnterior = 0
	punteroJugador     = nil

	local config = LevelsConfig[nivelID]
	if not config then warn("⚠️ Config no existe para nivel " .. nivelID); return end

	nombreInicio = config.NodoInicio

	local nivelModel = Workspace:WaitForChild("NivelActual", 15)
	if not nivelModel then warn("⚠️ NivelActual no apareció"); return end

	local objetos = nivelModel:WaitForChild("Objetos", 10)
	if objetos then
		carpetaPostesReal = objetos:WaitForChild("Postes", 10)
	end
	if not carpetaPostesReal then
		carpetaPostesReal = nivelModel:FindFirstChild("Postes", true)
	end
	if not carpetaPostesReal then warn("⚠️ Carpeta Postes no encontrada"); return end

	print("📦 Postes: " .. carpetaPostesReal:GetFullName())

	local clonados = 0

	for _, poste in ipairs(carpetaPostesReal:GetChildren()) do
		if poste:IsA("Folder") then continue end
		if not poste:IsA("Model") then continue end

		-- Obtener posición del poste desde su PrimaryPart o cualquier BasePart
		local posicionRef = poste.PrimaryPart
		if not posicionRef then
			posicionRef = poste:FindFirstChildWhichIsA("BasePart", true)
		end
		if not posicionRef then continue end

		-- Crear Part cuadrada fija en la posición del poste
		local nodo = Instance.new("Part")
		nodo.Name        = poste.Name .. "_Nodo"
		nodo.Anchored    = true
		nodo.CanCollide  = false
		nodo.CastShadow  = false
		nodo.Size        = Vector3.new(TAMANO_NODO, TAMANO_NODO, TAMANO_NODO)
		nodo.CFrame      = CFrame.new(posicionRef.Position)
		nodo.Parent      = worldModel

		-- Color inicial
		local color, mat = resolverColor(poste.Name, poste)
		nodo.Color    = color
		nodo.Material = mat

		mapaPostes[poste.Name] = {
			Poste        = poste,
			PosicionRef  = posicionRef,
			SelectorClon = nodo,
		}

		clonados = clonados + 1
	end

	if clonados == 0 then warn("⚠️ No se clonó ningún poste"); return end

	print("✅ " .. clonados .. " postes clonados")
	nivelActualIDAnterior = nivelID

	crearPunteroJugador()
end

-- ================================================================
-- SINCRONIZAR COLORES Y PARTÍCULAS
-- ================================================================

local function sincronizarEstados()
	for nombre, refs in pairs(mapaPostes) do
		local poste        = refs.Poste
		local selectorClon = refs.SelectorClon

		if selectorClon and selectorClon.Parent then
			local color, mat = resolverColor(nombre, poste)
			selectorClon.Color    = color
			selectorClon.Material = mat
		end
	end
end

-- ================================================================
-- ACTUALIZAR CABLES
-- ================================================================

local function actualizarCables()
	for _, c in ipairs(listaCables) do
		if c and c.Parent then c:Destroy() end
	end
	listaCables = {}

	if not carpetaPostesReal then return end

	local carpetaConexiones = carpetaPostesReal:FindFirstChild("Conexiones")
	if not carpetaConexiones then
		local parent = carpetaPostesReal.Parent
		carpetaConexiones = parent and parent:FindFirstChild("Conexiones")
	end
	if not carpetaConexiones then return end

	local function getKey(att0, att1)
		if not (att0 and att1) then return nil end
		local m0 = att0.Parent and att0.Parent:FindFirstAncestorWhichIsA("Model")
		local m1 = att1.Parent and att1.Parent:FindFirstAncestorWhichIsA("Model")
		if m0 and m1 then
			return m0.Name < m1.Name
				and (m0.Name .. "_" .. m1.Name)
				or  (m1.Name .. "_" .. m0.Name)
		end
		return nil
	end

	local fantasmas = {}
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj.Name == "CableFantasmaAlgoritmo" and obj:IsA("RopeConstraint") and obj.Visible then
			local key = getKey(obj.Attachment0, obj.Attachment1)
			if key then fantasmas[key] = obj end
		end
	end

	for _, rope in ipairs(carpetaConexiones:GetChildren()) do
		if not (rope:IsA("RopeConstraint") and rope.Visible) then continue end
		local attA = rope.Attachment0
		local attB = rope.Attachment1
		if not (attA and attB) then continue end

		local dist   = (attA.WorldPosition - attB.WorldPosition).Magnitude
		local centro = (attA.WorldPosition  + attB.WorldPosition) / 2
		local key    = getKey(attA, attB)

		local part = Instance.new("Part")
		part.Name         = "CableVisualPart"
		part.Anchored     = true
		part.CanCollide   = false
		part.CastShadow   = false
		part.Material     = Enum.Material.Neon
		part.Size         = Vector3.new(2, 2, dist)
		part.CFrame       = CFrame.lookAt(centro, attB.WorldPosition)
		part.Transparency = 0

		if key and fantasmas[key] then
			part.Color = fantasmas[key].Color.Color
			fantasmas[key] = nil
		else
			local mA = attA.Parent and attA.Parent:FindFirstAncestorWhichIsA("Model")
			local mB = attB.Parent and attB.Parent:FindFirstAncestorWhichIsA("Model")
			local eA = mA and mA:GetAttribute("Energizado") == true
			local eB = mB and mB:GetAttribute("Energizado") == true
			if eA and eB then
				part.Color = COL_CABLE_ENERGIZADO
			elseif (mA and tieneCable(mA)) and (mB and tieneCable(mB)) then
				part.Color = COL_CABLE_CONECTADO
			else
				part.Color = COL_CABLE_GRIS
			end
		end

		part.Parent = worldModel
		table.insert(listaCables, part)
	end

	for _, fantasma in pairs(fantasmas) do
		local attA = fantasma.Attachment0
		local attB = fantasma.Attachment1
		if not (attA and attB) then continue end
		local dist   = (attA.WorldPosition - attB.WorldPosition).Magnitude
		local centro = (attA.WorldPosition  + attB.WorldPosition) / 2
		local part = Instance.new("Part")
		part.Name         = "CableFantasmaVisual"
		part.Anchored     = true
		part.CanCollide   = false
		part.CastShadow   = false
		part.Material     = Enum.Material.Neon
		part.Size         = Vector3.new(2.5, 2.5, dist)
		part.CFrame       = CFrame.lookAt(centro, attB.WorldPosition)
		part.Color        = fantasma.Color.Color
		part.Transparency = 0
		part.Parent       = worldModel
		table.insert(listaCables, part)
	end

	if #listaCables ~= cantCablesAnterior then
		print("🔌 Cables: " .. #listaCables)
		cantCablesAnterior = #listaCables
	end
end

-- ================================================================
-- ACTUALIZAR PARTÍCULAS (re-escanea cada poste cada 0.5s)
-- ================================================================

local function actualizarParticulas()
	for _, p in ipairs(listaParticulas) do
		if p and p.Parent then p:Destroy() end
	end
	listaParticulas = {}

	if not carpetaPostesReal then return end

	for _, poste in ipairs(carpetaPostesReal:GetChildren()) do
		if not poste:IsA("Model") then continue end
		for _, obj in ipairs(poste:GetDescendants()) do
			if obj.Name == "TrafficParticle" and obj:IsA("BasePart") then
				local clon = obj:Clone()
				clon.Anchored   = true
				clon.CanCollide = false
				clon.Size       = Vector3.new(TAMANO_PARTICULA, TAMANO_PARTICULA, TAMANO_PARTICULA)
				clon.CFrame     = obj.CFrame
				clon.Parent     = worldModel
				table.insert(listaParticulas, clon)
			end
		end
	end
end

-- ================================================================
-- ACTIVAR / DESACTIVAR
-- ================================================================

local function activar(nivelID)
	task.spawn(function()
		cargarPostes(nivelID)
		actualizarCables()
		contenedorMiniMapa.Visible = true
		print("✅ Minimapa activo — nivel " .. nivelID)
	end)
end

local function desactivar()
	contenedorMiniMapa.Visible = false
	nivelActualIDAnterior = -999
	carpetaPostesReal     = nil
	mapaPostes            = {}
	listaCables           = {}
	nodosAdyacentes       = {}
	punteroJugador        = nil
	worldModel:ClearAllChildren()
end

-- ================================================================
-- LISTENERS
-- ================================================================

player:GetAttributeChangedSignal("CurrentLevelID"):Connect(function()
	local lvl = player:GetAttribute("CurrentLevelID")
	if lvl and lvl >= 0 then activar(lvl) else desactivar() end
end)

task.spawn(function()
	local evts     = ReplicatedStorage:FindFirstChild("Events")
	local binds    = evts and evts:FindFirstChild("Bindables")
	local openMenu = binds and binds:FindFirstChild("OpenMenu")
	if openMenu then openMenu.Event:Connect(desactivar) end
end)

task.spawn(function()
	task.wait(2)
	local lvl = player:GetAttribute("CurrentLevelID")
	if lvl and lvl >= 0 then activar(lvl) end
end)

-- ================================================================
-- LOOP PRINCIPAL
-- ================================================================

local tiempoCables     = 0
local tiempoParticulas = 0
if updateConnection then updateConnection:Disconnect() end

updateConnection = RunService.RenderStepped:Connect(function(dt)
	if not contenedorMiniMapa.Visible then return end

	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local pos = root.Position

	miniCamera.CFrame = CFrame.new(pos.X, pos.Y + ZOOM, pos.Z)
		* CFrame.Angles(math.rad(-90), 0, 0)

	if punteroJugador and punteroJugador.Parent then
		punteroJugador.CFrame = CFrame.new(pos.X, pos.Y + 2, pos.Z)
	end

	sincronizarEstados()

	tiempoCables = tiempoCables + dt
	if tiempoCables >= 0.3 then
		tiempoCables = 0
		actualizarCables()
	end

	tiempoParticulas = tiempoParticulas + dt
	if tiempoParticulas >= 0.3 then
		tiempoParticulas = 0
		actualizarParticulas()
	end
end)

-- ================================================================
-- LIMPIEZA
-- ================================================================

player.AncestryChanged:Connect(function(_, parent)
	if parent == nil then
		if updateConnection then updateConnection:Disconnect() end
		worldModel:ClearAllChildren()
	end
end)

print("╔══════════════════════════════════════════════════╗")
print("║  ✅ MINIMAPA v2 CARGADO                        ║")
print("║  🟡 Adyacente · 🔵 Conectado · 🟢 Energizado  ║")
print("║  🔴 Libre · 🟡 Puntero jugador · Partículas    ║")
print("╚══════════════════════════════════════════════════╝")