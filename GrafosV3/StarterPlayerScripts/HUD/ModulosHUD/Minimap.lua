-- StarterPlayerScripts/HUD/ModulosHUD/Minimap.lua
-- Minimapa 3D persistente para GrafosV3
--
-- Muestra en ContenedorMiniMapa > Vista (ViewportFrame) > WorldModel:
--   • Nodos: Parts coloreadas según estado (EfectosNodo)
--   • Cables: Parts cilíndricas por cada Beam activo
--   • Puntero: esfera amarilla que sigue al jugador
--   • Partículas: dots animados sobre conexiones activas
--
-- Lifecycle:
--   Minimap.inicializar(hudGui)              ← ControladorHUD al inicio
--   Minimap.configurarNivel(model, id, cfg)  ← ControladorHUD en NivelListo
--   Minimap.limpiar()                        ← ControladorHUD en desactivarHUD

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EfectosNodo       = require(ReplicatedStorage.Efectos.EfectosNodo)
local EstadoConexiones  = require(script.Parent.EstadoConexiones)

local Minimap = {}

-- ════════════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ════════════════════════════════════════════════════════════════════════

local ZOOM               = 45     -- studs de altura de la mini-cámara sobre el jugador
local TAMANO_NODO        = 5      -- lado (studs) de la Part cuadrada de cada nodo
local TAMANO_CABLE       = 0.5    -- grosor (studs) del cilindro de cable
local TAMANO_PARTICULA   = 2.5   -- diámetro de las bolas de partículas
local INTERVALO_CABLES   = 0.3   -- segundos entre reconstrucciones de cables

-- Colores de nodos (idénticos a ControladorEfectos para consistencia visual)
local COL_SELECCIONADO = Color3.fromRGB(0, 212, 255)    -- cyan
local COL_ADYACENTE    = Color3.fromRGB(255, 200, 50)   -- dorado amarillo
local COL_CONECTADO    = Color3.fromRGB(59, 130, 246)   -- azul
local COL_DESCONECTADO = Color3.fromRGB(100, 116, 139)  -- gris

local COL_CABLE   = Color3.fromRGB(255, 255, 255)    -- blanco para cables (distinto del nodo seleccionado)
local COL_PUNTERO = Color3.fromRGB(255, 220, 0)      -- amarillo para el puntero

local CFG_PART = {
	velocidad  = 10,    -- studs/segundo
	frecuencia = 1.5,   -- segundos entre disparos
	colorAB    = Color3.fromRGB(0, 207, 255),   -- dirección A→B
	colorBA    = Color3.fromRGB(255, 50, 100),  -- dirección B→A
}

-- ════════════════════════════════════════════════════════════════════════
-- ESTADO INTERNO
-- ════════════════════════════════════════════════════════════════════════

local jugador = Players.LocalPlayer

-- Referencias GUI / 3D
local contenedor = nil   -- Frame "ContenedorMiniMapa"
local worldModel = nil   -- WorldModel dentro del ViewportFrame
local miniCamera = nil   -- Camera del ViewportFrame

-- Nivel activo
local nivelModel = nil
local nivelID    = nil

-- Objetos en el WorldModel
local mapaPostes  = {}   -- [nomNodo] = { posRef: BasePart, clon: Part }
local listaCables = {}   -- array de Parts cilíndricas
local puntero     = nil  -- Part esférica del jugador

-- Partículas por conexión activa
local partActivas = {}   -- [idConexion (string)] = true | nil

-- Timers
local tiempoCables = 0
local updateConn   = nil

-- ════════════════════════════════════════════════════════════════════════
-- COLOR DE NODO
-- ════════════════════════════════════════════════════════════════════════

local function resolverColor(nomNodo)
	-- Orden de prioridad: seleccionado > adyacente > conectado > desconectado
	if nomNodo == EfectosNodo.nodoSeleccionado then
		return COL_SELECCIONADO, Enum.Material.Neon
	end
	if EfectosNodo.nodosAdyacentes[nomNodo] then
		return COL_ADYACENTE, Enum.Material.Neon
	end
	if EstadoConexiones.tieneConexiones(nomNodo) then
		return COL_CONECTADO, Enum.Material.SmoothPlastic
	end
	return COL_DESCONECTADO, Enum.Material.SmoothPlastic
end

-- ════════════════════════════════════════════════════════════════════════
-- PUNTERO DEL JUGADOR
-- ════════════════════════════════════════════════════════════════════════

local function crearPuntero()
	if puntero and puntero.Parent then puntero:Destroy() end

	local p = Instance.new("Part")
	p.Name       = "PunteroJugador"
	p.Anchored   = true
	p.CanCollide = false
	p.CastShadow = false
	p.Size       = Vector3.new(4, 4, 4)
	p.Color      = COL_PUNTERO
	p.Material   = Enum.Material.Neon

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent   = p

	p.Parent = worldModel
	puntero  = p
end

-- ════════════════════════════════════════════════════════════════════════
-- CARGAR NODOS
-- ════════════════════════════════════════════════════════════════════════

local function cargarNodos()
	if not nivelModel then return end

	local grafos = nivelModel:FindFirstChild("Grafos")
	if not grafos then
		warn("[Minimap] Carpeta Grafos no encontrada en NivelActual")
		return
	end

	local conteo = 0
	for _, grafo in ipairs(grafos:GetChildren()) do
		local nodosFolder = grafo:FindFirstChild("Nodos")
		if not nodosFolder then continue end

		for _, nodoModelo in ipairs(nodosFolder:GetChildren()) do
			-- Obtener BasePart de referencia de posición (Selector BasePart)
			local selector = nodoModelo:FindFirstChild("Selector")
			local posRef   = nil

			if selector then
				if selector:IsA("BasePart") then
					posRef = selector
				elseif selector:IsA("Model") then
					posRef = selector.PrimaryPart
						or selector:FindFirstChildWhichIsA("BasePart", true)
				end
			end
			if not posRef then
				posRef = nodoModelo.PrimaryPart
					or nodoModelo:FindFirstChildWhichIsA("BasePart", true)
			end
			if not posRef then continue end

			local color, mat = resolverColor(nodoModelo.Name)

			local clon = Instance.new("Part")
			clon.Name       = nodoModelo.Name .. "_MM"
			clon.Anchored   = true
			clon.CanCollide = false
			clon.CastShadow = false
			clon.Size       = Vector3.new(TAMANO_NODO, TAMANO_NODO, TAMANO_NODO)
			clon.CFrame     = CFrame.new(posRef.Position)
			clon.Color      = color
			clon.Material   = mat
			clon.Parent     = worldModel

			mapaPostes[nodoModelo.Name] = { posRef = posRef, clon = clon }
			conteo = conteo + 1
		end
	end

	print("[Minimap] Nodos cargados:", conteo)
end

-- ════════════════════════════════════════════════════════════════════════
-- SINCRONIZAR COLORES (cada frame)
-- ════════════════════════════════════════════════════════════════════════

local function sincronizarColores()
	for nomNodo, datos in pairs(mapaPostes) do
		local clon = datos.clon
		if clon and clon.Parent then
			local color, mat = resolverColor(nomNodo)
			clon.Color    = color
			clon.Material = mat
		end
	end
end

-- ════════════════════════════════════════════════════════════════════════
-- CABLES: EstadoConexiones → Parts cilíndricas en el WorldModel
-- (No usa Beams ni Ropes — ambos son invisibles en ViewportFrame/WorldModel)
-- ════════════════════════════════════════════════════════════════════════

local function actualizarCables()
	for _, c in ipairs(listaCables) do
		if c and c.Parent then c:Destroy() end
	end
	listaCables = {}

	local vistos = {}  -- evitar duplicados A-B / B-A

	for nomA, dA in pairs(mapaPostes) do
		local conectados = EstadoConexiones.obtenerConexiones(nomA)
		for _, nomB in ipairs(conectados) do
			-- Deduplicar: solo crear el cable una vez por par
			local key = nomA < nomB and (nomA .. "|" .. nomB) or (nomB .. "|" .. nomA)
			if vistos[key] then continue end
			vistos[key] = true

			local dB = mapaPostes[nomB]
			if not dB then continue end

			local posA = dA.posRef.Position
			local posB = dB.posRef.Position
			local dist = (posA - posB).Magnitude
			if dist < 0.1 then continue end

			local centro = (posA + posB) / 2
			local part   = Instance.new("Part")
			part.Name        = "CableVis"
			part.Anchored    = true
			part.CanCollide  = false
			part.CastShadow  = false
			part.Material    = Enum.Material.Neon
			part.Size        = Vector3.new(TAMANO_CABLE, TAMANO_CABLE, dist)
			part.CFrame      = CFrame.lookAt(centro, posB)
			part.Color       = COL_CABLE
			part.Parent      = worldModel

			table.insert(listaCables, part)
		end
	end
end

-- ════════════════════════════════════════════════════════════════════════
-- PARTÍCULAS: dots animados viajando entre nodos conectados
-- ════════════════════════════════════════════════════════════════════════

local function spawnParticula(desde, hasta, color)
	local dist = (hasta - desde).Magnitude
	if dist < 0.1 then return end

	local duracion = dist / CFG_PART.velocidad

	local p = Instance.new("Part")
	p.Name       = "PartMM"
	p.Shape      = Enum.PartType.Ball
	p.Anchored   = true
	p.CanCollide = false
	p.CastShadow = false
	p.Material   = Enum.Material.Neon
	p.Size       = Vector3.new(TAMANO_PARTICULA, TAMANO_PARTICULA, TAMANO_PARTICULA)
	p.Color      = color
	p.Position   = desde
	p.Parent     = worldModel

	local tween = TweenService:Create(
		p,
		TweenInfo.new(duracion, Enum.EasingStyle.Linear),
		{ Position = hasta }
	)
	tween.Completed:Connect(function()
		if p and p.Parent then p:Destroy() end
	end)
	tween:Play()
end

local function idConexion(nomA, nomB)
	return nomA < nomB and (nomA .. "_" .. nomB) or (nomB .. "_" .. nomA)
end

local function iniciarParticulas(id, nomA, nomB)
	if partActivas[id] then return end

	local dA = mapaPostes[nomA]
	local dB = mapaPostes[nomB]
	if not dA or not dB then return end

	local posA = dA.posRef.Position
	local posB = dB.posRef.Position

	partActivas[id] = true

	-- A → B
	task.spawn(function()
		while partActivas[id] do
			spawnParticula(posA, posB, CFG_PART.colorAB)
			task.wait(CFG_PART.frecuencia)
		end
	end)

	-- B → A (desfasado medio ciclo)
	task.spawn(function()
		task.wait(CFG_PART.frecuencia / 2)
		while partActivas[id] do
			spawnParticula(posB, posA, CFG_PART.colorBA)
			task.wait(CFG_PART.frecuencia)
		end
	end)
end

local function detenerParticulas(id)
	partActivas[id] = nil
end

-- ════════════════════════════════════════════════════════════════════════
-- ACTIVAR MINIMAPA (después de configurarNivel)
-- ════════════════════════════════════════════════════════════════════════

local function activar()
	task.spawn(function()
		task.wait(0.3)  -- pequeño delay para que los Beams del servidor estén replicados

		worldModel:ClearAllChildren()
		mapaPostes   = {}
		listaCables  = {}
		partActivas  = {}
		puntero      = nil
		tiempoCables = 0

		cargarNodos()
		actualizarCables()
		crearPuntero()

		if contenedor then contenedor.Visible = true end
		print("[Minimap] Activo — nivel", nivelID)
	end)
end

-- ════════════════════════════════════════════════════════════════════════
-- API PÚBLICA
-- ════════════════════════════════════════════════════════════════════════

-- Llamar una vez al inicio desde ControladorHUD
function Minimap.inicializar(hudGui)
	-- Buscar ContenedorMiniMapa en cualquier nivel de la jerarquía
	contenedor = hudGui:FindFirstChild("ContenedorMiniMapa", true)
	
	local vista = contenedor:FindFirstChild("Vista")
	-- WorldModel: obtener o crear
	worldModel = vista:FindFirstChild("WorldModel")

	-- Cámara del ViewportFrame: obtener o crear
	miniCamera = vista.CurrentCamera
	if not miniCamera then
		miniCamera              = Instance.new("Camera")
		miniCamera.FieldOfView  = 70
		miniCamera.Parent       = vista
		vista.CurrentCamera     = miniCamera
	end

	-- Escuchar eventos de conexión para las partículas
	local evts    = ReplicatedStorage:FindFirstChild("EventosGrafosV3")
	local remotos = evts and evts:FindFirstChild("Remotos")
	local notEvt  = remotos and remotos:FindFirstChild("NotificarSeleccionNodo")

	if notEvt then
		notEvt.OnClientEvent:Connect(function(tipo, nomA, nomB)
			if tipo == "ConexionCompletada" and nomA and nomB then
				iniciarParticulas(idConexion(nomA, nomB), nomA, nomB)
			elseif tipo == "CableDesconectado" and nomA and nomB then
				detenerParticulas(idConexion(nomA, nomB))
			end
		end)
	end

	-- Loop principal
	if updateConn then updateConn:Disconnect() end
	updateConn = RunService.RenderStepped:Connect(function(dt)
		if not contenedor or not contenedor.Visible then return end
		if not worldModel then return end

		local char = jugador.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then return end

		local pos = root.Position

		-- Cámara top-down centrada en el jugador
		miniCamera.CFrame = CFrame.new(pos.X, pos.Y + ZOOM, pos.Z)
			* CFrame.Angles(math.rad(-90), 0, 0)

		-- Puntero del jugador
		if puntero and puntero.Parent then
			puntero.CFrame = CFrame.new(pos.X, pos.Y + 2, pos.Z)
		end

		-- Actualizar colores de nodos cada frame
		sincronizarColores()

		-- Reconstruir cables cada INTERVALO_CABLES segundos
		tiempoCables = tiempoCables + dt
		if tiempoCables >= INTERVALO_CABLES then
			tiempoCables = 0
			actualizarCables()
		end
	end)

	contenedor.Visible = false
	print("[Minimap] Inicializado ✅")
end

-- Llamar en NivelListo desde ControladorHUD (mismo patrón que ModuloMapa.configurarNivel)
function Minimap.configurarNivel(nivelModelParam, nivelIDParam, _configNivel)
	nivelModel = nivelModelParam
	nivelID    = nivelIDParam
	activar()
end

-- Llamar en desactivarHUD desde ControladorHUD
function Minimap.limpiar()
	if contenedor then contenedor.Visible = false end

	partActivas = {}
	mapaPostes  = {}
	listaCables = {}
	puntero     = nil
	nivelModel  = nil
	nivelID     = nil

	if worldModel then worldModel:ClearAllChildren() end
	print("[Minimap] Limpieza completada")
end

return Minimap
