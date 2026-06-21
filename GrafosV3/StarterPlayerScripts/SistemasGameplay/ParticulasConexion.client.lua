-- StarterPlayerScripts/SistemasGameplay/ParticulasConexion.client.lua
-- Sistema de partículas que viajan por las conexiones de grafos

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local jugador = Players.LocalPlayer

print("[ParticulasConexion] Sistema iniciado")

-- Configuración
local CONFIG = {
	VelocidadParticula = 10,       -- Más rápido
	TamanoParticula = 0.6,         -- Más grande (antes 0.3)
	ColorParticulaAB = Color3.fromRGB(0, 207, 255),  -- Azul cian (A -> B)
	ColorParticulaBA = Color3.fromRGB(255, 50, 100), -- Rosa/Rojo (B -> A)
	BrilloParticula = 3,           -- (ya no se usa: sin PointLight)
	FrecuenciaParticulas = 3.0,    -- Menos frecuente para reducir carga
	MaxParticulasPorConexion = 2   -- Menos partículas simultáneas
}

-- Estado
local conexionesActivas = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- FUNCIONES AUXILIARES
-- ═══════════════════════════════════════════════════════════════════════════════

local function esConexionDirigida(nodoA, nodoB)
	local nivelID = jugador:GetAttribute("CurrentLevelID") or 0
	local LevelsConfig = ReplicatedStorage:WaitForChild("Config"):WaitForChild("LevelsConfig")
	local config = require(LevelsConfig)

	if config[nivelID] and config[nivelID].Adyacencias then
		local ady = config[nivelID].Adyacencias
		local aPuedeIrB = false
		local bPuedeIrA = false

		if ady[nodoA] then
			for _, v in ipairs(ady[nodoA]) do
				if v == nodoB then aPuedeIrB = true break end
			end
		end

		if ady[nodoB] then
			for _, v in ipairs(ady[nodoB]) do
				if v == nodoA then bPuedeIrA = true break end
			end
		end

		return aPuedeIrB and not bPuedeIrA
	end

	return false
end

local function obtenerPosicionesNodos(nodoA, nodoB)
	local posA, posB = nil, nil
	local nivelActual = Workspace:FindFirstChild("NivelActual")
	if not nivelActual then return nil, nil end

	local grafos = nivelActual:FindFirstChild("Grafos")
	if not grafos then return nil, nil end

	for _, grafo in ipairs(grafos:GetChildren()) do
		local nodos = grafo:FindFirstChild("Nodos")
		if nodos then
			local modeloA = nodos:FindFirstChild(nodoA)
			local modeloB = nodos:FindFirstChild(nodoB)

			if modeloA then
				local selectorA = modeloA:FindFirstChild("Selector")
				if selectorA and selectorA:IsA("BasePart") then
					posA = selectorA.Position
				end
			end

			if modeloB then
				local selectorB = modeloB:FindFirstChild("Selector")
				if selectorB and selectorB:IsA("BasePart") then
					posB = selectorB.Position
				end
			end
		end
	end

	return posA, posB
end

-- Obtener la carpeta Conexiones del grafo donde están los nodos
local function obtenerCarpetaConexiones(nodoA, nodoB)
	local nivelActual = Workspace:FindFirstChild("NivelActual")
	if not nivelActual then return nil end

	local grafos = nivelActual:FindFirstChild("Grafos")
	if not grafos then return nil end

	for _, grafo in ipairs(grafos:GetChildren()) do
		local nodos = grafo:FindFirstChild("Nodos")
		if nodos then
			local modeloA = nodos:FindFirstChild(nodoA)
			if modeloA then
				-- Encontramos el grafo correcto, obtener o crear la carpeta Conexiones
				local conexiones = grafo:FindFirstChild("Conexiones")
				if not conexiones then
					conexiones = Instance.new("Folder")
					conexiones.Name = "Conexiones"
					conexiones.Parent = grafo
				end
				return conexiones
			end
		end
	end
	return nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE PARTÍCULAS
-- ═══════════════════════════════════════════════════════════════════════════════

local function crearParticulaVisual(direccion)
	-- direccion: "AB" (A->B) o "BA" (B->A)
	local color = (direccion == "AB") and CONFIG.ColorParticulaAB or CONFIG.ColorParticulaBA

	local particula = Instance.new("Part")
	particula.Name = "ParticulaConexion_" .. direccion
	particula.Shape = Enum.PartType.Ball
	particula.Size = Vector3.new(CONFIG.TamanoParticula, CONFIG.TamanoParticula, CONFIG.TamanoParticula)
	particula.BrickColor = BrickColor.new(color)
	particula.Material = Enum.Material.Neon
	particula.Anchored = true
	particula.CanCollide = false
	particula.CanQuery = false
	particula.CastShadow = false

	-- OPT: eliminados PointLight y Trail para reducir carga de renderizado.
	-- La esfera Neon sola ya es visible suficientemente.

	return particula
end

local function animarParticula(particula, desde, hasta, duracion, onCompleto, carpetaDestino)
	particula.Position = desde
	-- Usar la carpeta Conexiones si se proporciona, si no usar Workspace.Terrain
	particula.Parent = carpetaDestino or Workspace.Terrain

	local tween = TweenService:Create(
		particula,
		TweenInfo.new(duracion, Enum.EasingStyle.Linear),
		{Position = hasta}
	)

	tween.Completed:Connect(function()
		if onCompleto then onCompleto() end
		particula:Destroy()
	end)

	tween:Play()
	return tween
end

local function iniciarFlujoParticulas(idConexion, nodoA, nodoB, esDirigido)
	if conexionesActivas[idConexion] then
		return
	end

	local posA, posB = obtenerPosicionesNodos(nodoA, nodoB)
	if not posA or not posB then
		warn("[ParticulasConexion] No se encontraron posiciones para:", nodoA, nodoB)
		return
	end

	-- Obtener la carpeta donde se crearán las partículas
	local carpetaConexiones = obtenerCarpetaConexiones(nodoA, nodoB)

	local distancia = (posB - posA).Magnitude
	local duracionViaje = distancia / CONFIG.VelocidadParticula

	conexionesActivas[idConexion] = {
		nodoA = nodoA,
		nodoB = nodoB,
		posA = posA,
		posB = posB,
		esDirigido = esDirigido,
		particulas = {},
		carpetaConexiones = carpetaConexiones
	}

	local conexion = conexionesActivas[idConexion]

	local function crearParticulaAB()
		if not conexionesActivas[idConexion] then return end
		if #conexion.particulas >= CONFIG.MaxParticulasPorConexion then return end

		local particula = crearParticulaVisual("AB")
		table.insert(conexion.particulas, particula)

		animarParticula(particula, posA, posB, duracionViaje, function()
			for i, p in ipairs(conexion.particulas) do
				if p == particula then
					table.remove(conexion.particulas, i)
					break
				end
			end
		end, conexion.carpetaConexiones)
	end

	local function crearParticulaBA()
		if not conexionesActivas[idConexion] then return end
		if #conexion.particulas >= CONFIG.MaxParticulasPorConexion then return end

		local particula = crearParticulaVisual("BA")
		table.insert(conexion.particulas, particula)

		animarParticula(particula, posB, posA, duracionViaje, function()
			for i, p in ipairs(conexion.particulas) do
				if p == particula then
					table.remove(conexion.particulas, i)
					break
				end
			end
		end, conexion.carpetaConexiones)
	end

	conexion.loopAB = task.spawn(function()
		while conexionesActivas[idConexion] do
			crearParticulaAB()
			task.wait(CONFIG.FrecuenciaParticulas)
		end
	end)

	if not esDirigido then
		conexion.loopBA = task.spawn(function()
			task.wait(CONFIG.FrecuenciaParticulas / 2)
			while conexionesActivas[idConexion] do
				crearParticulaBA()
				task.wait(CONFIG.FrecuenciaParticulas)
			end
		end)
	end

	-- print("[ParticulasConexion] Flujo iniciado:", idConexion, "Dirigido:", esDirigido)
end

local function detenerFlujoParticulas(idConexion)
	local conexion = conexionesActivas[idConexion]
	if not conexion then return end

	conexionesActivas[idConexion] = nil

	for _, particula in ipairs(conexion.particulas) do
		if particula and particula.Parent then
			particula:Destroy()
		end
	end

	-- print("[ParticulasConexion] Flujo detenido:", idConexion)
end

-- Detener todos los flujos que pasan por un nodo (usado al sobrecargar)
local function detenerFlujosDeNodo(nombreNodo)
	local ids = {}
	for idConexion, conexion in pairs(conexionesActivas) do
		if conexion.nodoA == nombreNodo or conexion.nodoB == nombreNodo then
			table.insert(ids, idConexion)
		end
	end
	for _, id in ipairs(ids) do
		detenerFlujoParticulas(id)
		detenerFlujoParticulas(id:gsub("^(.+)_(.+)$", "%2_%1"))
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- EVENTOS (via GestorEfectos — sin conexión directa al RemoteEvent)
-- ═══════════════════════════════════════════════════════════════════════════════

local GestorEfectos = require(script.Parent:WaitForChild("GestorEfectos"))

GestorEfectos.registrar("ConexionCompletada", function(params)
	local nodoA, nodoB = params.arg1, params.arg2
	if not nodoA or not nodoB then return end
	local idConexion = nodoA .. "_" .. nodoB
	local esDirigido = esConexionDirigida(nodoA, nodoB)
	-- print("[ParticulasConexion] Conexión creada:", nodoA, "->", nodoB, "Dirigido:", esDirigido)
	iniciarFlujoParticulas(idConexion, nodoA, nodoB, esDirigido)
end)

GestorEfectos.registrar("CableDesconectado", function(params)
	local nodoA, nodoB = params.arg1, params.arg2
	if not nodoA or not nodoB then return end
	local idConexion = nodoA .. "_" .. nodoB
	-- print("[ParticulasConexion] Conexión eliminada:", nodoA, "->", nodoB)
	detenerFlujoParticulas(idConexion)
	detenerFlujoParticulas(nodoB .. "_" .. nodoA)
end)

GestorEfectos.registrar("NodoSobrecargado", function(params)
	local nombreNodo = params.arg1
	if not nombreNodo then return end
	-- print("[ParticulasConexion] Nodo sobrecargado, limpiando partículas:", nombreNodo)
	detenerFlujosDeNodo(nombreNodo)
end)

print("[ParticulasConexion] Sistema listo")