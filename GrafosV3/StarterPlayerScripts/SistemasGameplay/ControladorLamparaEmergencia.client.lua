-- StarterPlayerScripts/SistemasGameplay/ControladorLamparaEmergencia.client.lua
-- Controla directamente las lámparas Emergencia_Lampara del nivel.
-- Enciende/apaga su PointLight existente con efecto sirena rojo/azul.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Eventos = ReplicatedStorage:WaitForChild("EventosGrafosV3")
local Remotos = Eventos:WaitForChild("Remotos")
local estadoLamparaEv = Remotos:WaitForChild("EstadoLamparaEmergencia")

local COLOR_ROJO = Color3.fromRGB(255, 0, 20)
local COLOR_AZUL = Color3.fromRGB(0, 60, 255)
local BRILLO_MAX = 8

-- { [zonaID] = { modelo, luz, colorOriginal, conn, intensidad } }
local lamparas = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════════════════

local function obtenerZonaDeLampara(modelo)
	local nivel = Workspace:FindFirstChild("NivelActual")
	if not nivel then return nil end
	local actual = modelo.Parent
	local zona = nil
	while actual and actual ~= nivel do
		if actual.Name == "Zonas" then
			return zona
		end
		zona = actual.Name
		actual = actual.Parent
	end
	return zona
end

local function buscarPointLight(modelo)
	-- Busca un PointLight ya existente dentro del modelo
	for _, desc in ipairs(modelo:GetDescendants()) do
		if desc:IsA("PointLight") then
			return desc
		end
	end
	-- Fallback: crear uno en la primera BasePart
	local parte = modelo:FindFirstChildOfClass("BasePart")
	if parte then
		local luz = Instance.new("PointLight")
		luz.Name = "LuzEmergencia"
		luz.Brightness = 0
		luz.Range = 30
		luz.Parent = parte
		return luz
	end
	return nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SIRENA
-- ═══════════════════════════════════════════════════════════════════════════════

local function detenerSirena(datos)
	if datos.conn then
		datos.conn:Disconnect()
		datos.conn = nil
	end
end

local function iniciarSirena(datos)
	if datos.conn then return end
	local ciclo = 0
	datos.conn = RunService.Heartbeat:Connect(function(dt)
		ciclo = ciclo + dt
		local fase = math.floor(ciclo / 0.5) % 2
		datos.luz.Color = (fase == 0) and COLOR_ROJO or COLOR_AZUL
		local pulso = 0.8 + 0.2 * math.sin(ciclo * 8)
		datos.luz.Brightness = BRILLO_MAX * datos.intensidad * pulso
	end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CICLO DE VIDA
-- ═══════════════════════════════════════════════════════════════════════════════

local function inicializar()
	limpiar()

	local nivel = Workspace:FindFirstChild("NivelActual")
	if not nivel then return end

	for _, obj in ipairs(nivel:GetDescendants()) do
		if obj:IsA("Model") and obj.Name == "Emergencia_Lampara" then
			local zona = obtenerZonaDeLampara(obj)
			if zona and not lamparas[zona] then
				local luz = buscarPointLight(obj)
				if luz then
					-- Guardar transparencias originales de todas las partes
					local transparencias = {}
					for _, desc in ipairs(obj:GetDescendants()) do
						if desc:IsA("BasePart") then
							transparencias[desc] = desc.Transparency
						end
					end
					lamparas[zona] = {
						modelo = obj,
						luz = luz,
						colorOriginal = luz.Color,
						transparencias = transparencias,
						conn = nil,
						intensidad = 0,
					}
				end
			end
		end
	end
end

local function ocultarModelo(datos)
	for parte, _ in pairs(datos.transparencias) do
		if parte and parte.Parent then
			parte.Transparency = 1
		end
	end
end

local function mostrarModelo(datos)
	for parte, transpOriginal in pairs(datos.transparencias) do
		if parte and parte.Parent then
			parte.Transparency = transpOriginal
		end
	end
end

local function limpiar()
	for zona, datos in pairs(lamparas) do
		detenerSirena(datos)
		if datos.luz and datos.luz.Parent then
			datos.luz.Brightness = 0
			datos.luz.Color = datos.colorOriginal
		end
		mostrarModelo(datos)
	end
	lamparas = {}
end

local function establecerIntensidad(zona, intensidad)
	intensidad = math.clamp(intensidad or 0, 0, 1)
	local datos = lamparas[zona]
	if not datos then return end

	datos.intensidad = intensidad
	if intensidad <= 0 then
		detenerSirena(datos)
		datos.luz.Brightness = 0
		datos.luz.Color = datos.colorOriginal
		ocultarModelo(datos)
	else
		mostrarModelo(datos)
		iniciarSirena(datos)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- EVENTOS
-- ═══════════════════════════════════════════════════════════════════════════════

estadoLamparaEv.OnClientEvent:Connect(function(zona, intensidad, hayEmergencia)
	establecerIntensidad(zona, intensidad)
end)

Remotos:WaitForChild("NivelListo").OnClientEvent:Connect(function()
	inicializar()
end)

Remotos:WaitForChild("NivelDescargado").OnClientEvent:Connect(function()
	limpiar()
end)

-- Hot-reload: si el nivel ya está cargado
task.delay(1, function()
	if Workspace:FindFirstChild("NivelActual") and next(lamparas) == nil then
		inicializar()
	end
end)

print("[ControladorLamparaEmergencia] Inicializado")
