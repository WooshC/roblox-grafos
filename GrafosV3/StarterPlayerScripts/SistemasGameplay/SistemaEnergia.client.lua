-- StarterPlayerScripts/SistemasGameplay/SistemaEnergia.client.lua
-- Gestiona el estado visual (encendido/apagado) de las zonas eléctricas del nivel.
--
-- Eventos escuchados:
--   NivelListo       → construye mapa, espera NivelActual, apaga luces
--   ZonaEnergizada   → enciende la carpeta correspondiente con animación
--   ZonaApagada      → apaga la carpeta (grafo dejó de ser conexo)
--   NivelDescargado  → limpia estado interno

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local LevelsConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("LevelsConfig"))
local jugador      = Players.LocalPlayer

print("[SistemaEnergia] Sistema iniciado")

-- ════════════════════════════════════════════════════════════════════
-- MAPA: ZonaID → CarpetaLuz  (leído desde LevelsConfig en runtime)
-- ════════════════════════════════════════════════════════════════════
local _mapaZonas = {}

local function construirMapa()
	_mapaZonas = {}
	local nivelID = jugador:GetAttribute("CurrentLevelID") or 0
	local config  = LevelsConfig[nivelID]
	if not config or not config.Zonas then return end

	local count = 0
	for zonaID, datos in pairs(config.Zonas) do
		if datos.CarpetaLuz then
			_mapaZonas[zonaID] = datos.CarpetaLuz
			count = count + 1
		end
	end
	print("[SistemaEnergia] Mapa construido para nivel", nivelID, "—", count, "zonas con luz")
end

-- ════════════════════════════════════════════════════════════════════
-- VALORES ORIGINALES
-- Se guardan con un scan previo al apagado para que "encender" siempre
-- pueda restaurar los valores configurados en Studio.
-- Fallback: si Brightness == 0 en Studio usamos 5 (luz encendida).
-- ════════════════════════════════════════════════════════════════════
local _valoresOriginales = {}

local FALLBACK_LUZ = {
	PointLight   = { Brightness = 5, Range = 20 },
	SpotLight    = { Brightness = 5, Range = 20 },
	SurfaceLight = { Brightness = 3, Range = 12 },
}

local function esLuz(obj)
	return obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight")
end

-- Itera descendientes de "ComponentesEnergeticos" (Nivel 0) o las partes llamadas "Foco" (Nivel 1)
local function iterarComponentes(carpeta, callback)
	for _, ce in ipairs(carpeta:GetDescendants()) do
		if ce.Name == "ComponentesEnergeticos" then
			for _, desc in ipairs(ce:GetDescendants()) do
				callback(desc)
			end
		elseif ce.Name == "Foco" then
			-- En Nivel 1, el 'Foco' es la parte en sí y contiene la luz
			callback(ce)
			for _, desc in ipairs(ce:GetDescendants()) do
				callback(desc)
			end
		end
	end
end

local function guardarValoresOriginales(carpeta)
	iterarComponentes(carpeta, function(desc)
		if esLuz(desc) and not _valoresOriginales[desc] then
			local fb = FALLBACK_LUZ[desc.ClassName] or { Brightness = 5, Range = 20 }
			_valoresOriginales[desc] = {
				Brightness = desc.Brightness > 0 and desc.Brightness or fb.Brightness,
				Range      = desc.Range      > 0 and desc.Range      or fb.Range,
			}
		end
	end)
end

-- Estado: qué zonas están energizadas en la sesión actual
local _zonasEncendidas = {}

-- ════════════════════════════════════════════════════════════════════
-- HELPERS — buscar carpeta de zona
-- ════════════════════════════════════════════════════════════════════

local function obtenerCarpeta(nombreCarpeta)
	local nivel = workspace:FindFirstChild("NivelActual")
	if not nivel then return nil end
	local zonas = nivel:FindFirstChild("Zonas")
	return (zonas and zonas:FindFirstChild(nombreCarpeta))
	    or nivel:FindFirstChild(nombreCarpeta, true)
end

-- ════════════════════════════════════════════════════════════════════
-- ESTABLECER PROGRESO DE ENERGÍA (PORCENTAJE)
-- ════════════════════════════════════════════════════════════════════

local function ajustarNivelEnergia(carpeta, porcentaje)
	local i = 0
	iterarComponentes(carpeta, function(obj)
		task.delay(i * 0.02, function()
			if not obj or not obj.Parent then return end

			if esLuz(obj) then
				local cfg = _valoresOriginales[obj] or FALLBACK_LUZ[obj.ClassName] or { Brightness = 5, Range = 20 }
				
				if porcentaje <= 0 then
					TweenService:Create(obj, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Brightness = 0 }):Play()
					task.delay(0.65, function() if obj and obj.Parent then obj.Enabled = false end end)
				else
					obj.Enabled = true
					local targetBrightness = cfg.Brightness * porcentaje
					TweenService:Create(obj, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { 
						Brightness = targetBrightness, 
						Range = cfg.Range 
					}):Play()
				end

			elseif obj:IsA("Beam") or obj:IsA("ParticleEmitter") then
				obj.Enabled = (porcentaje > 0)
				if obj:IsA("ParticleEmitter") and porcentaje > 0 and porcentaje > (_zonasEncendidas[carpeta] or 0) then
					obj:Emit(10)
				end

			elseif obj:IsA("BasePart") then
				if porcentaje <= 0 then
					TweenService:Create(obj, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Transparency = 1 }):Play()
				else
					obj.Material = Enum.Material.Neon
					TweenService:Create(obj, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { 
						Transparency = 1 - porcentaje 
					}):Play()
				end
			end
		end)
		i = i + 1
	end)
end

local function actualizarProgresoZona(zonaID, porcentaje)
	local nombreCarpeta = _mapaZonas[zonaID]
	if not nombreCarpeta then return end
	local carpeta = obtenerCarpeta(nombreCarpeta)
	if not carpeta then return end
	
	local viejoPorcentaje = _zonasEncendidas[zonaID] or 0
	if viejoPorcentaje == porcentaje then return end
	
	_zonasEncendidas[zonaID] = porcentaje
	print(string.format("[SistemaEnergia] ⚡ Zona: %s → %d%%", nombreCarpeta, math.floor(porcentaje * 100)))
	ajustarNivelEnergia(carpeta, porcentaje)
end

-- Espera NivelActual en workspace, guarda valores originales y apaga todo
local function inicializarApagado()
	-- Esperar a que NivelActual esté replicado (timeout 10s)
	local nivel = workspace:FindFirstChild("NivelActual")
		or workspace:WaitForChild("NivelActual", 10)
	if not nivel then
		warn("[SistemaEnergia] NivelActual no encontrado — luces no inicializadas")
		return
	end

	for _, nombreCarpeta in pairs(_mapaZonas) do
		local carpeta = obtenerCarpeta(nombreCarpeta)
		if carpeta then
			guardarValoresOriginales(carpeta)   -- capturar antes de modificar
			ajustarNivelEnergia(carpeta, 0)
		end
	end
	_zonasEncendidas = {}
	print("[SistemaEnergia] Todas las zonas inicializadas al 0% de energia")
end

-- ════════════════════════════════════════════════════════════════════
-- CONEXIÓN A EVENTOS
-- ════════════════════════════════════════════════════════════════════

local eventos = ReplicatedStorage:WaitForChild("EventosGrafosV3")
local remotos = eventos:WaitForChild("Remotos")

local function conectar(nombre, callback)
	local ev = remotos:WaitForChild(nombre, 10)
	if ev then
		ev.OnClientEvent:Connect(callback)
		print("[SistemaEnergia] ✓ Escuchando", nombre)
	else
		warn("[SistemaEnergia] Evento no encontrado:", nombre)
	end
end

-- Nivel listo → construir mapa y apagar (task.spawn para permitir WaitForChild)
conectar("NivelListo", function()
	construirMapa()
	task.spawn(inicializarApagado)
end)

-- Nivel descargado → limpiar estado
conectar("NivelDescargado", function()
	_mapaZonas       = {}
	_zonasEncendidas = {}
end)

-- Progreso de Energía variable (0.0 a 1.0)
conectar("ProgresoEnergia", function(zonaID, porcentaje)
	actualizarProgresoZona(zonaID, porcentaje)
end)
