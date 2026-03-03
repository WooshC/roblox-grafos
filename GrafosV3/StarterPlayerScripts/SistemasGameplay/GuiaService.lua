--!nocheck
-- StarterPlayerScripts/SistemasGameplay/GuiaService.lua
-- Sistema parametrizable de guia visual (Beam + Beacon).
-- Portado de GarfosV1/GuiaService para la arquitectura GrafosV3.
--
-- La secuencia de objetivos se define en LevelsConfig[nivelID].Guia.
-- Cualquier sistema avanza la guia llamando:
--   local GuiaService = require(this_module)
--   GuiaService.GuiaAvanzar:Fire("objetivoID")
--
-- Tipos de WaypointRef soportados:
--   "PART_EXISTENTE"  → Part ya colocada en NivelActual/Objetivos (Nombre)
--   "SOBRE_OBJETO"    → Crea Part invisible encima de un objeto del nivel (Nombre/Ruta + OffsetY)
--   "PART_DIRECTA"    → Usa una Part ya existente del nivel (Nombre/Ruta); NO la destruye
--   "POSICION_FIJA"   → Crea Part en un Vector3 absoluto (Posicion)
--
-- Busqueda por nombre vs ruta:
--   Nombre = "ZonaTrigger_Estacion1"                       → busqueda recursiva en el contenedor
--   Ruta   = {"Zonas","Zonas_juego","ZonaTrigger_Estacion1"} → ruta exacta paso a paso

local GuiaService = {}
GuiaService.__index = GuiaService

-- ============================================
-- SERVICIOS
-- ============================================

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EfectosVideo = require(ReplicatedStorage:WaitForChild("Efectos"):WaitForChild("EfectosVideo"))

local localPlayer = Players.LocalPlayer

-- ============================================
-- ESTADO INTERNO
-- ============================================

local listaObjetivos  = {}   -- tabla Guia del nivel activo [{ID, WaypointRef, ...}]
local indexActual     = 0    -- 1-based; 0 = sin guia activa
local headAttachment  = nil  -- Attachment en la cabeza del jugador
local guideBeam       = nil  -- Beam visual activo
local currentPart     = nil  -- Part waypoint activa
local completados     = {}   -- { [ID] = true } objetivos ya completados
local objetivosFolder = nil  -- NivelActual/Objetivos
local guideBillboard  = nil  -- BillboardGui sobre el waypoint activo
local zonaActualCliente = "" -- Zona actual, actualizada por ActualizarMisiones

-- ============================================
-- CONFIGURACION VISUAL (ajustable)
-- ============================================

local CFG = {
	-- Beam
	COLOR = ColorSequence.new({
		ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 215,  50)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 180)),
		ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 215,  50)),
	}),
	TRANSPARENCY = NumberSequence.new({
		NumberSequenceKeypoint.new(0,   0.5),
		NumberSequenceKeypoint.new(0.5, 0.0),
		NumberSequenceKeypoint.new(1,   0.5),
	}),
	WIDTH          = 0.5,
	LIGHT_EMISSION = 1,
	SEGMENTS       = 24,
	-- Textura de flechas
	TEXTURE_ID     = "rbxassetid://5886559421",
	TEXTURE_LENGTH = 1.5,
	TEXTURE_SPEED  = 0.8,

	-- Beacon flotante (cilindro Neon encima del waypoint)
	BEACON_SIZE   = Vector3.new(2.5, 0.3, 2.5),
	BEACON_COLOR  = Color3.fromRGB(255, 215, 50),
	BEACON_OFFSET = 2,
	BEACON_FLOAT  = 0.5,
	BEACON_SPEED  = 1.2,
}

-- ============================================
-- PRIVADAS – BUSQUEDA DE OBJETOS
-- ============================================

local function getLevelModel()
	return workspace:FindFirstChild("NivelActual")
end

local function getContainer(buscarEn)
	if buscarEn == "NIVEL_ACTUAL" then
		return getLevelModel()
	elseif buscarEn == "WORKSPACE" then
		return workspace
	else
		return workspace:FindFirstChild(buscarEn, true) or workspace
	end
end

local function findTarget(container, ref)
	if ref.Ruta then
		local current = container
		for _, step in ipairs(ref.Ruta) do
			if not current then return nil end
			current = current:FindFirstChild(step)
		end
		return current
	elseif ref.Nombre then
		return container:FindFirstChild(ref.Nombre, true)
	end
	return nil
end

-- Para modelos, prioriza: PrimaryPart → hijo "Selector" → primera BasePart
local function getBasePart(instance)
	if not instance then return nil end
	if instance:IsA("BasePart") then return instance end
	if instance:IsA("Model") then
		return instance.PrimaryPart
			or instance:FindFirstChild("Selector")
			or instance:FindFirstChildWhichIsA("BasePart")
	end
	return nil
end

local function refDesc(ref)
	if ref.Ruta then return table.concat(ref.Ruta, "/") end
	return ref.Nombre or "?"
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Dado un objetivo, devuelve la Part del waypoint.
-- ─────────────────────────────────────────────────────────────────────────────
local function resolveWaypointPart(objetivo)
	local ref  = objetivo.WaypointRef
	local tipo = ref.Tipo

	-- ── PART_EXISTENTE ──────────────────────────────────────────
	if tipo == "PART_EXISTENTE" then
		if not objetivosFolder then
			warn("❌ GuiaService: objetivosFolder no inicializado")
			return nil
		end
		local part = objetivosFolder:FindFirstChild(ref.Nombre)
		if not part then
			warn("❌ GuiaService: Part '" .. ref.Nombre .. "' no encontrada en Objetivos")
		end
		return part

	-- ── PART_DIRECTA ─────────────────────────────────────────────
	elseif tipo == "PART_DIRECTA" then
		local container = getContainer(ref.BuscarEn or "NIVEL_ACTUAL")
		if not container then
			warn("❌ GuiaService: PART_DIRECTA – contenedor '" .. (ref.BuscarEn or "NIVEL_ACTUAL") .. "' no encontrado")
			return nil
		end
		local target   = findTarget(container, ref)
		local basePart = getBasePart(target)
		if not basePart then
			warn("❌ GuiaService: PART_DIRECTA – '" .. refDesc(ref) .. "' no encontrado o sin BasePart")
			return nil
		end
		return basePart

	-- ── SOBRE_OBJETO ─────────────────────────────────────────────
	elseif tipo == "SOBRE_OBJETO" then
		local container = getContainer(ref.BuscarEn or "NIVEL_ACTUAL")
		if not container then
			warn("❌ GuiaService: SOBRE_OBJETO – contenedor no encontrado")
			return nil
		end
		local target = findTarget(container, ref)
		if not target then
			warn("❌ GuiaService: SOBRE_OBJETO – '" .. refDesc(ref) .. "' no encontrado")
			return nil
		end
		local partName = "Objetivo_" .. objetivo.ID
		local existing = objetivosFolder and objetivosFolder:FindFirstChild(partName)
		if existing then return existing end

		local center = target:IsA("Model") and target:GetPivot().Position or target.Position
		local part   = Instance.new("Part")
		part.Name         = partName
		part.Anchored     = true
		part.CanCollide   = false
		part.CastShadow   = false
		part.Transparency = 1
		part.Size         = Vector3.new(3, 0.1, 3)
		part.CFrame       = CFrame.new(center + Vector3.new(0, ref.OffsetY or 6, 0))
		part.Parent       = objetivosFolder or workspace
		return part

	-- ── POSICION_FIJA ────────────────────────────────────────────
	elseif tipo == "POSICION_FIJA" then
		if not ref.Posicion then
			warn("❌ GuiaService: POSICION_FIJA sin campo 'Posicion' en WaypointRef")
			return nil
		end
		local partName = "Objetivo_" .. objetivo.ID
		local existing = objetivosFolder and objetivosFolder:FindFirstChild(partName)
		if existing then return existing end

		local part = Instance.new("Part")
		part.Name         = partName
		part.Anchored     = true
		part.CanCollide   = false
		part.CastShadow   = false
		part.Transparency = 1
		part.Size         = Vector3.new(3, 0.1, 3)
		part.CFrame       = CFrame.new(ref.Posicion)
		part.Parent       = objetivosFolder or workspace
		return part
	end

	warn("❌ GuiaService: WaypointRef.Tipo desconocido: '" .. tostring(tipo) .. "'")
	return nil
end

-- ============================================
-- PRIVADAS – ATTACHMENT
-- ============================================

local function getOrCreateHeadAtt(character)
	local head = character:WaitForChild("Head", 5)
	if not head then
		warn("❌ GuiaService: Personaje sin Head (timeout)")
		return nil
	end
	local att = head:FindFirstChild("GuiaHeadAtt")
	if att then headAttachment = att; return att end
	att          = Instance.new("Attachment")
	att.Name     = "GuiaHeadAtt"
	att.Position = Vector3.new(0, 0.65, 0)
	att.Parent   = head
	headAttachment = att
	return att
end

local function getOrCreateObjAtt(part)
	local att = part:FindFirstChild("GuiaObjAtt")
	if att then return att end
	att        = Instance.new("Attachment")
	att.Name   = "GuiaObjAtt"
	att.Parent = part
	return att
end

-- ============================================
-- PRIVADAS – BEAM
-- ============================================

local function destroyBeam()
	if guideBeam and guideBeam.Parent then guideBeam:Destroy() end
	guideBeam = nil
end

local function createBeamBetween(headAtt, objAtt)
	destroyBeam()
	local beam = Instance.new("Beam")
	beam.Name           = "GuiaBeam"
	beam.Attachment0    = headAtt
	beam.Attachment1    = objAtt
	beam.Color          = CFG.COLOR
	beam.Transparency   = CFG.TRANSPARENCY
	beam.Width0         = CFG.WIDTH
	beam.Width1         = CFG.WIDTH
	beam.LightEmission  = CFG.LIGHT_EMISSION
	beam.LightInfluence = 0
	beam.FaceCamera     = true
	beam.Segments       = CFG.SEGMENTS
	beam.CurveSize0     = 0
	beam.CurveSize1     = 0
	beam.Texture        = CFG.TEXTURE_ID
	beam.TextureLength  = CFG.TEXTURE_LENGTH
	beam.TextureMode    = Enum.TextureMode.Wrap
	beam.TextureSpeed   = CFG.TEXTURE_SPEED
	beam.Parent         = headAtt.Parent
	guideBeam = beam
end

-- ============================================
-- PRIVADAS – BEACON
-- ============================================

local function createBeacon(part)
	local old = part:FindFirstChild("GuiaBeacon")
	if old then old:Destroy() end

	local signo = EfectosVideo.clonarSigno(part, 1)
	if not signo then return end
	signo.Name = "GuiaBeacon"
end

-- ============================================
-- PRIVADAS – BILLBOARD
-- ============================================

local function destroyBillboard()
	if guideBillboard and guideBillboard.Parent then
		guideBillboard:Destroy()
	end
	guideBillboard = nil
end

local function createBillboard(part, objetivo)
	destroyBillboard()
	if not part or not part.Parent then return end

	-- Texto: Label > Zonas[Zona].Descripcion > ID en mayusculas
	local labelText = objetivo.Label
	if not labelText and objetivo.Zona then
		local nivelID = localPlayer:GetAttribute("CurrentLevelID")
		if nivelID then
			local ok, cfg = pcall(function()
				return require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("LevelsConfig"))
			end)
			if ok and cfg then
				local levelCfg = cfg[nivelID]
				if levelCfg and levelCfg.Zonas and levelCfg.Zonas[objetivo.Zona] then
					labelText = levelCfg.Zonas[objetivo.Zona].Descripcion
				end
			end
		end
	end
	labelText = labelText or objetivo.ID:upper()

	local bill = Instance.new("BillboardGui")
	bill.Name           = "GuiaBillboard"
	bill.Adornee        = part
	bill.AlwaysOnTop    = true
	bill.StudsOffset    = Vector3.new(0, CFG.BEACON_OFFSET + 3.5, 0)
	bill.Size           = UDim2.new(0, 240, 0, 52)
	bill.MaxDistance    = 0    -- 0 = siempre visible sin limite de distancia
	bill.LightInfluence = 0
	bill.Parent         = part

	local frame = Instance.new("Frame")
	frame.Size                   = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3       = Color3.fromRGB(8, 8, 18)
	frame.BackgroundTransparency = 0.25
	frame.BorderSizePixel        = 0
	frame.Parent                 = bill

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent       = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color     = CFG.BEACON_COLOR
	stroke.Thickness = 2
	stroke.Parent    = frame

	local label = Instance.new("TextLabel")
	label.Size                   = UDim2.new(1, -12, 1, 0)
	label.Position               = UDim2.new(0, 6, 0, 0)
	label.BackgroundTransparency = 1
	label.Text                   = labelText
	label.TextColor3             = Color3.new(1, 1, 1)
	label.TextScaled             = true
	label.Font                   = Enum.Font.GothamBold
	label.TextXAlignment         = Enum.TextXAlignment.Center
	label.TextYAlignment         = Enum.TextYAlignment.Center
	label.Parent                 = frame

	guideBillboard = bill
end

local function setGuideVisible(visible)
	if guideBeam and guideBeam.Parent then
		guideBeam.Enabled = visible
	end
	if guideBillboard and guideBillboard.Parent then
		guideBillboard.Enabled = visible
	end
end

-- Ocultar beam+billboard si el jugador ya esta en la zona objetivo.
local function updateGuideVisibility()
	local current = listaObjetivos[indexActual]
	if not current or not current.Zona then
		setGuideVisible(true)
		return
	end
	if completados[current.ID] then
		setGuideVisible(true)
		return
	end
	-- Ocultar si ya estamos en la zona objetivo
	setGuideVisible(zonaActualCliente ~= current.Zona)
end

-- ============================================
-- PRIVADAS – APUNTAR Y LIMPIAR
-- ============================================

local function apuntarA(part, objetivo)
	local char = localPlayer.Character
	if not char then
		warn("❌ GuiaService: Sin personaje para apuntar guia")
		return
	end
	local headAtt = getOrCreateHeadAtt(char)
	if not headAtt then return end
	local objAtt = getOrCreateObjAtt(part)
	createBeamBetween(headAtt, objAtt)
	createBeacon(part)
	createBillboard(part, objetivo)
	currentPart = part
	updateGuideVisibility()
end

-- destroyPart = true  → destruye la Part entera (PART_EXISTENTE / SOBRE_OBJETO)
-- destroyPart = false → solo elimina el Beacon y el Attachment que añadimos
local function cleanupObjective(part, destroyPart)
	if not part or not part.Parent then return end
	local beacon = part:FindFirstChild("GuiaBeacon")
	local att    = part:FindFirstChild("GuiaObjAtt")

	if beacon then
		TweenService:Create(beacon,
			TweenInfo.new(0.4, Enum.EasingStyle.Sine),
			{ Transparency = 1 }
		):Play()
	end

	task.delay(0.45, function()
		if destroyPart then
			if part and part.Parent then part:Destroy() end
		else
			if beacon and beacon.Parent then beacon:Destroy() end
			if att   and att.Parent   then att:Destroy()    end
		end
	end)
end

-- ============================================
-- PUBLICO: avanzar al siguiente objetivo
-- Llamar con el ID del objetivo ACTUAL que acabo de completarse.
-- ============================================

function GuiaService:avanzar(objetivoID)
	local current = listaObjetivos[indexActual]
	if not current then
		warn("⚠️ GuiaService:avanzar() – No hay objetivo activo (indexActual=" .. indexActual .. ")")
		return
	end
	if current.ID ~= objetivoID then return end
	if completados[objetivoID] then return end
	completados[objetivoID] = true

	local prevPart      = currentPart
	local shouldDestroy = current.DestruirAlCompletar ~= false  -- true por defecto

	indexActual += 1
	local next = listaObjetivos[indexActual]

	destroyBeam()

	if next then
		local nextPart = resolveWaypointPart(next)
		if nextPart then
			apuntarA(nextPart, next)
			print("🧭 GuiaService: [" .. (indexActual - 1) .. "→" .. indexActual .. "] " .. current.ID .. " → " .. next.ID)
		else
			warn("❌ GuiaService: No se pudo resolver waypoint para '" .. next.ID .. "'")
		end
	else
		currentPart = nil
		print("🏁 GuiaService: Todos los objetivos completados")
	end

	cleanupObjective(prevPart, shouldDestroy)
end

-- ============================================
-- PUBLICO: inicializar guia para un nivel dado
-- ============================================

function GuiaService:initForLevel(nivelID)
	self:limpiar()
	completados = {}

	local ok, LevelsConfig = pcall(function()
		return require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("LevelsConfig"))
	end)
	if not ok then
		warn("❌ GuiaService: No se pudo cargar LevelsConfig:", LevelsConfig)
		return
	end

	local levelCfg = LevelsConfig[nivelID]
	if not levelCfg then
		print("ℹ️ GuiaService: Nivel " .. tostring(nivelID) .. " no existe en LevelsConfig")
		return
	end
	if not levelCfg.Guia or #levelCfg.Guia == 0 then
		print("ℹ️ GuiaService: Nivel " .. tostring(nivelID) .. " sin seccion 'Guia'")
		return
	end

	listaObjetivos = levelCfg.Guia

	local levelModel = getLevelModel()
	if not levelModel then
		warn("❌ GuiaService: NivelActual no encontrado en Workspace")
		return
	end

	-- Carpeta de waypoints: NivelActual/Navegacion/Waypoints
	local navegacion = levelModel:FindFirstChild("Navegacion")
	objetivosFolder  = navegacion and navegacion:FindFirstChild("Waypoints")
	if not objetivosFolder then
		warn("❌ GuiaService: NivelActual/Navegacion/Waypoints no encontrado")
		return
	end

	-- Asegurar personaje disponible
	local _ = localPlayer.Character or localPlayer.CharacterAdded:Wait()

	-- Mostrar primer objetivo
	indexActual  = 1
	local first  = listaObjetivos[1]
	local firstP = resolveWaypointPart(first)
	if firstP then
		apuntarA(firstP, first)
		print("🧭 GuiaService: Guia iniciada → Objetivo[1] '" .. first.ID .. "'")
	else
		warn("❌ GuiaService: No se pudo resolver primer waypoint '" .. first.ID .. "'")
	end
end

-- ============================================
-- PUBLICO: limpiar toda la guia visual
-- ============================================

function GuiaService:limpiar()
	destroyBeam()
	destroyBillboard()
	if headAttachment and headAttachment.Parent then
		headAttachment:Destroy()
	end
	headAttachment  = nil
	currentPart     = nil
	indexActual     = 0
	listaObjetivos  = {}
	completados     = {}
	zonaActualCliente = ""
end

-- ============================================
-- INIT – conecta eventos
-- ============================================

function GuiaService:init()
	print("🧭 GuiaService: Inicializando...")

	task.spawn(function()
		local remotos = ReplicatedStorage
			:WaitForChild("EventosGrafosV3", 15)
			:WaitForChild("Remotos", 10)

		if not remotos then
			warn("❌ GuiaService: No se encontro EventosGrafosV3/Remotos")
			return
		end

		-- 1. NivelListo → iniciar guia para el nivel cargado
		local nivelListoEv = remotos:WaitForChild("NivelListo", 10)
		if nivelListoEv then
			nivelListoEv.OnClientEvent:Connect(function(data)
				if data and not data.error and data.nivelID ~= nil then
					task.delay(2, function()
						self:initForLevel(data.nivelID)
					end)
				end
			end)
		else
			warn("⚠️ GuiaService: RemoteEvent 'NivelListo' no encontrado")
		end

		-- 2. NivelDescargado → limpiar guia
		local nivelDescargadoEv = remotos:WaitForChild("NivelDescargado", 10)
		if nivelDescargadoEv then
			nivelDescargadoEv.OnClientEvent:Connect(function()
				self:limpiar()
			end)
		end

		-- 3. ActualizarMisiones → auto-avanzar guia cuando la zona se completa
		--    Payload: { porZona = { [zona] = { total, completadas, misiones } }, zonaActual, allComplete }
		local actualizarMisionesEv = remotos:WaitForChild("ActualizarMisiones", 10)
		if actualizarMisionesEv then
			actualizarMisionesEv.OnClientEvent:Connect(function(payload)
				if not payload then return end

				-- Verificar si la zona del objetivo actual esta completa
				local current = listaObjetivos[indexActual]
				if not current or not current.Zona then return end
				if completados[current.ID] then return end

				local zonaData = payload.porZona and payload.porZona[current.Zona]
				if not zonaData then return end
				if zonaData.total > 0 and zonaData.completadas >= zonaData.total then
					print("🧭 GuiaService: Zona '" .. current.Zona .. "' completada → avanzando guia")
					self:avanzar(current.ID)
				end
			end)
			print("✅ GuiaService: Escuchando 'ActualizarMisiones' para auto-avanzar por zona")
		else
			warn("⚠️ GuiaService: 'ActualizarMisiones' no encontrado en Remotos")
		end

		-- 4. GuiaAvanzar BindableEvent → avance manual desde otro script cliente
		local bindables = remotos.Parent:WaitForChild("Bindables", 5)
		if bindables then
			GuiaService.GuiaAvanzar = bindables:WaitForChild("GuiaAvanzar", 5)
			if GuiaService.GuiaAvanzar then
				GuiaService.GuiaAvanzar.Event:Connect(function(id)
					self:avanzar(id)
				end)
			else
				warn("⚠️ GuiaService: BindableEvent 'GuiaAvanzar' no encontrado en Bindables")
			end
		else
			warn("⚠️ GuiaService: Carpeta 'Bindables' no encontrada en EventosGrafosV3")
		end

		print("✅ GuiaService: Inicializado correctamente")
	end)

	-- 5. Atributo ZonaActual replicado desde GestorZonas (server → client) → actualizar visibilidad
	--    GestorZonas hace SetAttribute("ZonaActual", nombre) al entrar y SetAttribute("ZonaActual", nil) al salir.
	--    Esto es mas confiable que depender del payload de ActualizarMisiones (que usa string vacio al salir).
	localPlayer:GetAttributeChangedSignal("ZonaActual"):Connect(function()
		zonaActualCliente = localPlayer:GetAttribute("ZonaActual") or ""
		updateGuideVisibility()
	end)

	-- 7. Reconectar beam si el personaje respawna (sin reiniciar progreso)
	localPlayer.CharacterAdded:Connect(function()
		task.delay(1.5, function()
			if currentPart and currentPart.Parent and indexActual > 0 then
				local char = localPlayer.Character
				if not char then return end
				local hAtt = getOrCreateHeadAtt(char)
				if hAtt then
					local oAtt = getOrCreateObjAtt(currentPart)
					createBeamBetween(hAtt, oAtt)
				end
			end
		end)
	end)
end

-- Auto-init al hacer require
GuiaService:init()

-- Exponer globalmente para acceso desde eventos de dialogo (igual que _G.ControladorDialogo)
_G.GuiaService = GuiaService

return GuiaService
