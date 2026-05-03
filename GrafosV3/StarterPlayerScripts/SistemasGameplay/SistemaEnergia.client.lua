-- StarterPlayerScripts/SistemasGameplay/SistemaEnergia.client.lua
-- Gestiona el estado visual (encendido/apagado) de las zonas eléctricas del nivel.
--
-- ESTRATEGIA SIMPLE Y ROBUSTA:
--   1. Al cargar el nivel, busca cada carpeta Zona_luz_X por nombre (de _mapaZonas).
--   2. Itera TODOS sus descendientes y apaga las luces sincronamente.
--   3. No requiere ninguna convención de nombre interior (ComponentesEnergeticos,
--      Foco, etc.) — simplemente apaga todo lo que esté dentro de la zona.
--
-- En Studio: asegúrate de que cada Zona_luz_X exista y tenga los modelos adentro.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local LevelsConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("LevelsConfig"))
local jugador      = Players.LocalPlayer

print("[SistemaEnergia] Sistema iniciado")

-- ════════════════════════════════════════════════════════════════════
-- MAPA: ZonaID → nombre de CarpetaLuz (p.ej. "Zona_luz_1")
-- ════════════════════════════════════════════════════════════════════
local _mapaZonas = {}

local function construirMapa(nivelID_arg)
	_mapaZonas = {}
	local nivelID = nivelID_arg or jugador:GetAttribute("CurrentLevelID") or 0
	local config  = LevelsConfig[nivelID]
	if not config or not config.Zonas then return end

	local count = 0
	for zonaID, datos in pairs(config.Zonas) do
		if datos.CarpetaLuz then
			_mapaZonas[zonaID] = datos.CarpetaLuz
			count = count + 1
		end
	end
	print(string.format("[SistemaEnergia] Mapa construido — nivel %d | zonas: %d", nivelID, count))
	for zid, carp in pairs(_mapaZonas) do
		print(string.format("[SistemaEnergia]   → %s → %s", zid, carp))
	end
end

-- ════════════════════════════════════════════════════════════════════
-- VALORES ORIGINALES — guardados antes del apagado para restaurar
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

-- Estado: qué zonas están energizadas
local _zonasEncendidas = {}
local _conexionesZonas = {} -- Conexiones para DescendantAdded

-- ════════════════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════════════════

-- Encuentra una carpeta de zona en el workspace por nombre
local function obtenerCarpeta(nombreCarpeta)
	local nivel = workspace:FindFirstChild("NivelActual")
	if not nivel then return nil end
	-- Busca primero en el hijo "Zonas", luego en cualquier lugar del nivel
	local zonas = nivel:FindFirstChild("Zonas")
	return (zonas and zonas:FindFirstChild(nombreCarpeta))
		or nivel:FindFirstChild(nombreCarpeta, true)
end

-- ════════════════════════════════════════════════════════════════════
-- PROCESAMIENTO DE COMPONENTES DE LUZ (APAGADO/ESTADO INICIAL)
-- Asegura que las luces que cargan tarde (Streaming) tomen el estado correcto.
-- ════════════════════════════════════════════════════════════════════
local function procesarComponente(obj, zonaID)
	if not obj or not obj.Parent then return 0, 0, 0 end

	local esLuzVal = esLuz(obj)
	local esBeamParticle = obj:IsA("Beam") or obj:IsA("ParticleEmitter")
	local esNeon = obj:IsA("BasePart") and obj.Material == Enum.Material.Neon

	if not (esLuzVal or esBeamParticle or esNeon) then return 0, 0, 0 end

	-- Si ya se procesó, no hacer nada
	if _valoresOriginales[obj] then return 0, 0, 0 end

	-- 1. Guardar valor original
	if esLuzVal then
		local fb = FALLBACK_LUZ[obj.ClassName] or { Brightness = 5, Range = 20 }
		_valoresOriginales[obj] = {
			Brightness = obj.Brightness > 0 and obj.Brightness or fb.Brightness,
			Range      = obj.Range      > 0 and obj.Range      or fb.Range,
		}
	else
		_valoresOriginales[obj] = true
	end

	-- 2. Aplicar estado actual de la zona (usualmente 0 al inicio)
	local porcentaje = _zonasEncendidas[zonaID] or 0

	if esLuzVal then
		local cfg = _valoresOriginales[obj]
		if porcentaje <= 0 then
			obj.Brightness = 0
			obj.Enabled = false
		else
			obj.Brightness = cfg.Brightness * porcentaje
			obj.Range = cfg.Range
			obj.Enabled = true
		end
		return 1, 0, 0
	elseif esBeamParticle then
		obj.Enabled = (porcentaje > 0)
		return 0, 1, 0
	elseif esNeon then
		if porcentaje <= 0 then
			obj.Transparency = 1
		else
			obj.Material = Enum.Material.Neon
			obj.Transparency = 1 - porcentaje
		end
		return 0, 0, 1
	end
	
	return 0, 0, 0
end

local function apagarCarpetaZona(carpeta, zonaID)
	local contLuces, contBeams, contNeon = 0, 0, 0

	-- Procesar los descendientes que ya existen
	for _, obj in ipairs(carpeta:GetDescendants()) do
		local l, b, n = procesarComponente(obj, zonaID)
		contLuces = contLuces + l
		contBeams = contBeams + b
		contNeon = contNeon + n
	end

	-- Escuchar por nuevos descendientes (StreamingEnabled o Replicación Atrasada)
	local conn = carpeta.DescendantAdded:Connect(function(obj)
		-- Con un pequeño delay para asegurar que las propiedades del obj se enviaron completas
		task.delay(0.1, function()
			if not obj or not obj.Parent then return end
			local l, b, n = procesarComponente(obj, zonaID)
			-- Podríamos loguear esto, pero causaría spam en streaming
		end)
	end)
	table.insert(_conexionesZonas, conn)

	return contLuces, contBeams, contNeon
end

-- ════════════════════════════════════════════════════════════════════
-- GAMEPLAY: ajuste animado al cambiar el progreso de energía
-- Llamado únicamente por el evento ProgresoEnergia (mid-gameplay).
-- ════════════════════════════════════════════════════════════════════
local function ajustarNivelEnergia(carpeta, porcentaje)
	local i = 0
	for _, obj in ipairs(carpeta:GetDescendants()) do
		if not _valoresOriginales[obj] then continue end

		task.delay(i * 0.02, function()
			if not obj or not obj.Parent then return end

			if esLuz(obj) then
				local cfg = type(_valoresOriginales[obj]) == "table" and _valoresOriginales[obj] or FALLBACK_LUZ[obj.ClassName] or { Brightness = 5, Range = 20 }

				if porcentaje <= 0 then
					TweenService:Create(obj, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Brightness = 0 }):Play()
					task.delay(0.65, function()
						if obj and obj.Parent then obj.Enabled = false end
					end)
				else
					obj.Enabled = true
					TweenService:Create(obj, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Brightness = cfg.Brightness * porcentaje,
						Range      = cfg.Range,
					}):Play()
				end

			elseif obj:IsA("Beam") or obj:IsA("ParticleEmitter") then
				obj.Enabled = (porcentaje > 0)
				if obj:IsA("ParticleEmitter") and porcentaje > 0 then
					obj:Emit(10)
				end

			elseif obj:IsA("BasePart") then
				if porcentaje <= 0 then
					TweenService:Create(obj, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Transparency = 1 }):Play()
				else
					obj.Material = Enum.Material.Neon
					TweenService:Create(obj, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Transparency = 1 - porcentaje,
					}):Play()
				end
			end
		end)
		i = i + 1
	end
end

local function actualizarProgresoZona(zonaID, porcentaje)
	print(string.format("[SistemaEnergia] 📡 Recibido ProgresoEnergia: zonaID=%s porcentaje=%.2f", tostring(zonaID), porcentaje))
	
	local nombreCarpeta = _mapaZonas[zonaID]
	if not nombreCarpeta then
		warn(string.format("[SistemaEnergia] ⚠ zonaID '%s' no está en _mapaZonas. Zonas conocidas:", tostring(zonaID)))
		for zid, carp in pairs(_mapaZonas) do
			warn(string.format("  → %s → %s", zid, carp))
		end
		return
	end
	local carpeta = obtenerCarpeta(nombreCarpeta)
	if not carpeta then
		warn(string.format("[SistemaEnergia] ⚠ Carpeta '%s' no encontrada en workspace para zona '%s'", nombreCarpeta, tostring(zonaID)))
		return
	end

	local viejoPorcentaje = _zonasEncendidas[zonaID] or 0
	if viejoPorcentaje == porcentaje then
		print(string.format("[SistemaEnergia] ⚡ %s → %d%% (sin cambio, ignorado)", nombreCarpeta, math.floor(porcentaje * 100)))
		return
	end

	_zonasEncendidas[zonaID] = porcentaje
	print(string.format("[SistemaEnergia] ⚡ %s → %d%%", nombreCarpeta, math.floor(porcentaje * 100)))
	ajustarNivelEnergia(carpeta, porcentaje)
end

-- ════════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN AL CARGAR EL NIVEL
-- ════════════════════════════════════════════════════════════════════
local function inicializarApagado()
	-- 1. Esperar a que NivelActual esté replicado al cliente
	local nivel = workspace:FindFirstChild("NivelActual")
		or workspace:WaitForChild("NivelActual", 10)
	if not nivel then
		warn("[SistemaEnergia] NivelActual no encontrado")
		return
	end

	-- 2. Buscar cada Zona_luz_X por nombre y apagar todo su contenido
	local totalLuces, totalBeams, totalNeon = 0, 0, 0
	local zonasApagadas = 0

	for zonaID, nombreCarpeta in pairs(_mapaZonas) do
		-- WaitForChild para esperar replicación de cada carpeta (timeout 5s)
		local nivel2 = workspace:FindFirstChild("NivelActual")
		local zonas  = nivel2 and nivel2:FindFirstChild("Zonas")
		local carpeta = obtenerCarpeta(nombreCarpeta)

		if not carpeta then
			-- Intentar con WaitForChild si no está replicada aún
			local zonas2 = nivel2 and (nivel2:FindFirstChild("Zonas") or nivel2:WaitForChild("Zonas", 3))
			if zonas2 then
				carpeta = zonas2:WaitForChild(nombreCarpeta, 5)
			end
			if not carpeta then
				carpeta = nivel2 and nivel2:FindFirstChild(nombreCarpeta, true)
			end
		end

		if carpeta then
			local l, b, n = apagarCarpetaZona(carpeta, zonaID)
			totalLuces = totalLuces + l
			totalBeams = totalBeams + b
			totalNeon  = totalNeon  + n
			zonasApagadas = zonasApagadas + 1
			print(string.format("[SistemaEnergia] %s → %d luces apagadas", nombreCarpeta, l))
		else
			warn(string.format("[SistemaEnergia] ⚠ No encontrada: '%s' (ZonaID: %s)", nombreCarpeta, tostring(zonaID)))
		end
	end

	_zonasEncendidas = {}
	print(string.format("[SistemaEnergia] ✅ %d/%d zonas | %d luces | %d beams | %d neon apagados",
		zonasApagadas, #(function() local t={} for _ in pairs(_mapaZonas) do t[#t+1]=1 end return t end)(),
		totalLuces, totalBeams, totalNeon))
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

-- Nivel listo → construir mapa y apagar
conectar("NivelListo", function(info)
	local nivelID = (info and info.nivelID) or nil
	construirMapa(nivelID)
	task.spawn(inicializarApagado)
end)

-- Nivel descargado → limpiar estado
conectar("NivelDescargado", function()
	for _, conn in ipairs(_conexionesZonas) do
		conn:Disconnect()
	end
	_conexionesZonas   = {}
	_mapaZonas         = {}
	_zonasEncendidas   = {}
	_valoresOriginales = {}
end)

-- Progreso de energía variable → animar encendido/apagado
conectar("ProgresoEnergia", function(zonaID, porcentaje)
	actualizarProgresoZona(zonaID, porcentaje)
end)