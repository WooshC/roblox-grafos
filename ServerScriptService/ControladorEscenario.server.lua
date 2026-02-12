-- ControladorEscenario.server.lua
-- Este script se encarga EXCLUSIVAMENTE de "NivelEscenario" en el Menu Principal.
-- Conecta todos los postes y activa las particulas.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Esperar a que exista el NivelEscenario
local nivel = workspace:WaitForChild("NivelEscenario", 10)
if not nivel then
	warn("⚠️ NivelEscenario no encontrado en Workspace tras 10s.")
	return
end

local objetos = nivel:WaitForChild("Objetos")
local postesFolder = objetos:WaitForChild("Postes")

-- Configuración de Conexiones (Grafo del escenario)
-- Define quien se conecta con quien
local conexiones = {
	{"PostePanel", "Poste1"},
	{"Poste1", "Poste2"},
	{"Poste2", "Poste3"},
	{"Poste3", "Poste4"}, -- Ajustar según tu diseño
	{"Poste1", "Poste4"},
	{"Poste1", "Poste5"},
	{"Poste4", "PosteFinal"},
	{"Poste5", "PosteFinal"},
	-- Agrega más conexiones si lo deseas
}

local function getAttachment(poste)
	-- Buscar attachment en el modelo del poste
	return poste:FindFirstChild("ConnectorAttachment", true) or poste:FindFirstChild("Attachment", true)
end

local function conectar(nombreA, nombreB)
	local posteA = postesFolder:FindFirstChild(nombreA)
	local posteB = postesFolder:FindFirstChild(nombreB)
	
	if not posteA or not posteB then return end
	
	local attA = getAttachment(posteA)
	local attB = getAttachment(posteB)
	
	if not attA or not attB then return end
	
	-- Crear Cable
	local rope = Instance.new("RopeConstraint")
	rope.Name = "Cable_" .. nombreA .. "_" .. nombreB
	rope.Attachment0 = attA
	rope.Attachment1 = attB
	rope.Visible = true
	rope.Thickness = 0.2
	rope.Color = BrickColor.new("Black")
	rope.Length = (attA.WorldPosition - attB.WorldPosition).Magnitude
	rope.Parent = nivel
	
	-- Beam (Haz de Luz decorativo - opcional)
	-- local beam = Instance.new("Beam") ...
	
	return posteA, posteB
end

-- 1. Crear Conexiones Físicas
local paresConectados = {}

for _, par in ipairs(conexiones) do
	local pA, pB = conectar(par[1], par[2])
	if pA and pB then
		table.insert(paresConectados, {pA, pB})
	end
end

print("✅ NivelEscenario conectado.")

-- 2. Activar Partículas (Pulse)
local eventsFolder = ReplicatedStorage:WaitForChild("Events")
local remotesFolder = eventsFolder:WaitForChild("Remotes")
local pulseEvent = remotesFolder:WaitForChild("PulseEvent")

local function iniciarPulsos(player)
	wait(2) -- Dar tiempo a carga
	print("✨ Iniciando pulsos de escenario para:", player.Name)
	for _, par in ipairs(paresConectados) do
		-- Enviar evento StartPulse al cliente
		pulseEvent:FireClient(player, "StartPulse", par[1], par[2], true) -- true = bidireccional
	end
end

Players.PlayerAdded:Connect(iniciarPulsos)

-- Para jugadores ya conectados (en testing)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(function() iniciarPulsos(p) end)
end
