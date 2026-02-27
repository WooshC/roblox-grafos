-- StarterPlayerScripts/SistemasGameplay/ParticulasConexion.client.lua
-- Sistema de partículas que viajan por las conexiones de grafos

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local jugador = Players.LocalPlayer
local eventos = ReplicatedStorage:WaitForChild("EventosGrafosV3")
local remotos = eventos:WaitForChild("Remotos")

print("[ParticulasConexion] Sistema iniciado")

-- Configuración
local CONFIG = {
	VelocidadParticula = 8,
	TamanoParticula = 0.3,
	ColorParticula = Color3.fromRGB(0, 207, 255),
	BrilloParticula = 2,
	FrecuenciaParticulas = 1.5,
	MaxParticulasPorConexion = 3
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

-- ═══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE PARTÍCULAS
-- ═══════════════════════════════════════════════════════════════════════════════

local function crearParticulaVisual()
	local particula = Instance.new("Part")
	particula.Name = "ParticulaConexion"
	particula.Shape = Enum.PartType.Ball
	particula.Size = Vector3.new(CONFIG.TamanoParticula, CONFIG.TamanoParticula, CONFIG.TamanoParticula)
	particula.BrickColor = BrickColor.new(CONFIG.ColorParticula)
	particula.Material = Enum.Material.Neon
	particula.Anchored = true
	particula.CanCollide = false
	particula.CanQuery = false
	particula.CastShadow = false

	local puntoLuz = Instance.new("PointLight")
	puntoLuz.Color = CONFIG.ColorParticula
	puntoLuz.Brightness = CONFIG.BrilloParticula
	puntoLuz.Range = 3
	puntoLuz.Parent = particula

	return particula
end

local function animarParticula(particula, desde, hasta, duracion, onCompleto)
	particula.Position = desde
	particula.Parent = Workspace.Terrain

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

	local distancia = (posB - posA).Magnitude
	local duracionViaje = distancia / CONFIG.VelocidadParticula

	conexionesActivas[idConexion] = {
		nodoA = nodoA,
		nodoB = nodoB,
		posA = posA,
		posB = posB,
		esDirigido = esDirigido,
		particulas = {}
	}

	local conexion = conexionesActivas[idConexion]

	local function crearParticulaAB()
		if not conexionesActivas[idConexion] then return end
		if #conexion.particulas >= CONFIG.MaxParticulasPorConexion then return end

		local particula = crearParticulaVisual()
		table.insert(conexion.particulas, particula)

		animarParticula(particula, posA, posB, duracionViaje, function()
			for i, p in ipairs(conexion.particulas) do
				if p == particula then
					table.remove(conexion.particulas, i)
					break
				end
			end
		end)
	end

	local function crearParticulaBA()
		if not conexionesActivas[idConexion] then return end
		if #conexion.particulas >= CONFIG.MaxParticulasPorConexion then return end

		local particula = crearParticulaVisual()
		table.insert(conexion.particulas, particula)

		animarParticula(particula, posB, posA, duracionViaje, function()
			for i, p in ipairs(conexion.particulas) do
				if p == particula then
					table.remove(conexion.particulas, i)
					break
				end
			end
		end)
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

	print("[ParticulasConexion] Flujo iniciado:", idConexion, "Dirigido:", esDirigido)
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

	print("[ParticulasConexion] Flujo detenido:", idConexion)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- EVENTOS
-- ═══════════════════════════════════════════════════════════════════════════════

-- El servidor usa NotificarSeleccionNodo con tipo de mensaje
local notificarEvento = remotos:FindFirstChild("NotificarSeleccionNodo")
if notificarEvento then
	notificarEvento.OnClientEvent:Connect(function(tipoMensaje, nodoA, nodoB)
		if tipoMensaje == "ConexionCompletada" and nodoA and nodoB then
			local idConexion = nodoA .. "_" .. nodoB
			local esDirigido = esConexionDirigida(nodoA, nodoB)

			print("[ParticulasConexion] Conexión creada:", nodoA, "->", nodoB, "Dirigido:", esDirigido)
			iniciarFlujoParticulas(idConexion, nodoA, nodoB, esDirigido)
			
		elseif tipoMensaje == "CableDesconectado" and nodoA and nodoB then
			local idConexion = nodoA .. "_" .. nodoB
			print("[ParticulasConexion] Conexión eliminada:", nodoA, "->", nodoB)
			detenerFlujoParticulas(idConexion)
		end
	end)
end

-- API Pública
local ParticulasConexion = {}

function ParticulasConexion.iniciar(nodoA, nodoB, esDirigido)
	if not esDirigido then
		esDirigido = esConexionDirigida(nodoA, nodoB)
	end
	local idConexion = nodoA .. "_" .. nodoB
	iniciarFlujoParticulas(idConexion, nodoA, nodoB, esDirigido)
end

function ParticulasConexion.detener(nodoA, nodoB)
	local idConexion = nodoA .. "_" .. nodoB
	detenerFlujoParticulas(idConexion)
	-- También intentar con la clave inversa
	detenerFlujoParticulas(nodoB .. "_" .. nodoA)
end

function ParticulasConexion.esConexionDirigida(nodoA, nodoB)
	return esConexionDirigida(nodoA, nodoB)
end

function ParticulasConexion.configurar(nuevaConfig)
	for key, value in pairs(nuevaConfig) do
		CONFIG[key] = value
	end
end

_G.ParticulasConexion = ParticulasConexion

print("[ParticulasConexion] Sistema listo")

return ParticulasConexion
