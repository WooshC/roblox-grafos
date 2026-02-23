--!nocheck
-- StarterPlayer/StarterPlayerScripts/Cliente/Services/GuiaService.lua
-- Sistema parametrizable de guía visual (Beam + Beacon).
--
-- La secuencia de objetivos se define en LevelsConfig[nivelID].Guia.
-- Cualquier sistema avanza la guía disparando:
--   ReplicatedStorage.Events.Bindables.GuiaAvanzar:Fire("objetivoID")
--
-- Tipos de WaypointRef soportados:
--   "PART_EXISTENTE"  → Part ya colocada manualmente en workspace.Objetivos (Nombre)
--   "SOBRE_OBJETO"    → Crea Part invisible encima de un objeto del nivel (Nombre/Ruta + OffsetY)
--   "PART_DIRECTA"    → Usa una Part ya existente del nivel (Nombre/Ruta); NO la destruye
--   "POSICION_FIJA"   → Crea Part en un Vector3 absoluto (Posicion)
--
-- Búsqueda por nombre vs ruta:
--   Nombre = "Nodo1_z1"                        → búsqueda recursiva en el contenedor
--   Ruta   = {"Objetos","Postes","Nodo1_z1","Selector"}  → ruta exacta paso a paso

local GuiaService = {}
GuiaService.__index = GuiaService

-- ============================================
-- SERVICIOS
-- ============================================

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer  = Players.LocalPlayer

-- ============================================
-- ESTADO INTERNO
-- ============================================

local listaObjetivos      = {}   -- tabla Guia del nivel activo [{ID, WaypointRef, ...}]
local indexActual         = 0    -- 1-based; 0 = sin guía activa
local headAttachment      = nil  -- Attachment en la cabeza del jugador
local guideBeam           = nil  -- Beam visual activo
local currentPart         = nil  -- Part waypoint activa
local completados         = {}   -- { [ID] = true } objetivos ya completados
local objetivosFolder     = nil  -- workspace.Objetivos
local misionesCompletadas = {}   -- { [misionID] = true } misiones completadas en la sesión
local guideBillboard      = nil  -- BillboardGui sobre el waypoint activo

-- ============================================
-- CONFIGURACIÓN VISUAL (ajustable)
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
	WIDTH          = 0.5,   -- ancho del beam (studs)
	LIGHT_EMISSION = 1,
	SEGMENTS       = 24,
	-- Textura de flechas
	TEXTURE_ID     = "rbxassetid://5886559421",
	TEXTURE_LENGTH = 1.5,   -- longitud de cada repetición (más corto = flechas más juntas)
	TEXTURE_SPEED  = 0.8,   -- velocidad de scroll (propiedad nativa Beam.TextureSpeed)

	-- Beacon flotante (cilindro Neon encima del waypoint)
	BEACON_SIZE    = Vector3.new(2.5, 0.3, 2.5),
	BEACON_COLOR   = Color3.fromRGB(255, 215, 50),
	BEACON_OFFSET  = 2,     -- studs sobre la Part ancla (eleva el beacon sobre el nodo/zona)
	BEACON_FLOAT   = 0.5,   -- amplitud del tween de flotación
	BEACON_SPEED   = 1.2,   -- duración de cada mitad del tween (s)
}

-- ============================================
-- PRIVADAS – BÚSQUEDA DE OBJETOS
-- ============================================

-- Devuelve el modelo del nivel activo en Workspace
local function getLevelModel()
	return workspace:FindFirstChild("NivelActual")
		or workspace:FindFirstChild("Nivel0")
end

-- Devuelve el contenedor según BuscarEn
local function getContainer(buscarEn)
	if buscarEn == "NIVEL_ACTUAL" then
		return getLevelModel()
	elseif buscarEn == "WORKSPACE" then
		return workspace
	else
		return workspace:FindFirstChild(buscarEn, true) or workspace
	end
end

-- Busca un objeto dentro de un contenedor.
--   ref.Ruta   = {"Objetos","Postes","Nodo1_z1","Selector"}  → ruta exacta paso a paso
--   ref.Nombre = "Nodo1_z1"                                  → búsqueda recursiva
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

-- Dada una instancia (Model o BasePart), devuelve la BasePart sobre la que
-- se puede crear un Attachment y el Beacon.
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

-- ── Descripción legible del ref para mensajes de error ──────────────────────
local function refDesc(ref)
	if ref.Ruta then return table.concat(ref.Ruta, "/") end
	return ref.Nombre or "?"
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Dado un objetivo (elemento de Guia), devuelve la Part del waypoint.
-- Nunca crea duplicados: si ya existe, la reutiliza (útil en respawns).
-- ─────────────────────────────────────────────────────────────────────────────
local function resolveWaypointPart(objetivo)
	local ref  = objetivo.WaypointRef
	local tipo = ref.Tipo

	-- ── PART_EXISTENTE ──────────────────────────────────────────
	-- Part colocada manualmente en workspace.Objetivos
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
		-- Usa una Part ya existente en el nivel como ancla del beam.
		-- NO crea nada en Objetivos. NO la destruye al avanzar.
		-- Ideal para apuntar a nodos específicos (ej. Nodo1_z1 o su Selector).
	elseif tipo == "PART_DIRECTA" then
		local container = getContainer(ref.BuscarEn or "NIVEL_ACTUAL")
		if not container then
			warn("❌ GuiaService: PART_DIRECTA – contenedor '" .. (ref.BuscarEn or "NIVEL_ACTUAL") .. "' no encontrado")
			return nil
		end

		local target  = findTarget(container, ref)
		local basePart = getBasePart(target)
		if not basePart then
			warn("❌ GuiaService: PART_DIRECTA – '" .. refDesc(ref) .. "' no encontrado o sin BasePart")
			return nil
		end
		return basePart

		-- ── SOBRE_OBJETO ─────────────────────────────────────────────
		-- Crea una Part invisible encima del objeto indicado.
		-- Admite Nombre (recursivo) o Ruta (exacta).
	elseif tipo == "SOBRE_OBJETO" then
		local container = getContainer(ref.BuscarEn or "NIVEL_ACTUAL")
		if not container then
			warn("❌ GuiaService: SOBRE_OBJETO – contenedor '" .. (ref.BuscarEn or "NIVEL_ACTUAL") .. "' no encontrado")
			return nil
		end

		local target = findTarget(container, ref)
		if not target then
			warn("❌ GuiaService: SOBRE_OBJETO – '" .. refDesc(ref) .. "' no encontrado")
			return nil
		end

		-- Evitar duplicados (útil en respawn)
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
		-- Crea una Part en una posición absoluta (Vector3 en ref.Posicion)
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
	-- WaitForChild porque el personaje puede no estar completamente cargado aún
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
	beam.FaceCamera     = true   -- la textura siempre mira a la cámara
	beam.Segments       = CFG.SEGMENTS
	beam.CurveSize0     = 0
	beam.CurveSize1     = 0
	beam.Texture        = CFG.TEXTURE_ID
	beam.TextureLength  = CFG.TEXTURE_LENGTH
	beam.TextureMode    = Enum.TextureMode.Wrap
	beam.TextureSpeed   = CFG.TEXTURE_SPEED  -- animación nativa (no requiere Heartbeat)
	beam.Parent         = headAtt.Parent

	guideBeam = beam
end

-- ============================================
-- PRIVADAS – BEACON
-- ============================================

local function createBeacon(part)
	local old = part:FindFirstChild("GuiaBeacon")
	if old then old:Destroy() end

	local center  = part:IsA("Model") and part:GetPivot().Position or part.Position
	local beacon  = Instance.new("Part")
	beacon.Name         = "GuiaBeacon"
	beacon.Anchored     = true
	beacon.CanCollide   = false
	beacon.CastShadow   = false
	beacon.Size         = CFG.BEACON_SIZE
	beacon.Color        = CFG.BEACON_COLOR
	beacon.Material     = Enum.Material.Neon
	beacon.Shape        = Enum.PartType.Cylinder
	beacon.Transparency = 0.25
	beacon.CFrame       = CFrame.new(center + Vector3.new(0, CFG.BEACON_OFFSET, 0))
		* CFrame.Angles(0, 0, math.pi / 2)  -- cilindro horizontal
	beacon.Parent       = part

	local basePos = beacon.CFrame
	TweenService:Create(beacon,
		TweenInfo.new(CFG.BEACON_SPEED, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ CFrame = basePos + Vector3.new(0, CFG.BEACON_FLOAT, 0) }
	):Play()
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

-- Crea un BillboardGui sobre la Part del waypoint.
-- Muestra la descripción de la zona o el Label personalizado del objetivo.
local function createBillboard(part, objetivo)
	destroyBillboard()
	if not part or not part.Parent then return end

	-- Texto descriptivo: Label > Zonas[Zona].Descripcion > ID en mayúsculas
	local labelText = objetivo.Label
	if not labelText and objetivo.Zona then
		local nivelID = localPlayer:GetAttribute("CurrentLevelID")
		if nivelID then
			local cfg = require(ReplicatedStorage:WaitForChild("LevelsConfig"))
			local levelCfg = cfg[nivelID]
			if levelCfg and levelCfg.Zonas and levelCfg.Zonas[objetivo.Zona] then
				labelText = levelCfg.Zonas[objetivo.Zona].Descripcion
			end
		end
	end
	labelText = labelText or objetivo.ID:upper()

	local bill = Instance.new("BillboardGui")
	bill.Name           = "GuiaBillboard"
	bill.Adornee        = part
	bill.AlwaysOnTop    = true   -- visible aunque haya paredes entre medias
	bill.StudsOffset    = Vector3.new(0, CFG.BEACON_OFFSET + 3.5, 0)
	bill.Size           = UDim2.new(0, 240, 0, 52)
	bill.MaxDistance    = 80
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

-- Muestra u oculta el beam y el billboard.
-- El beacon se mantiene visible siempre (marca la ubicación aunque ya estés ahí).
local function setGuideVisible(visible)
	if guideBeam and guideBeam.Parent then
		guideBeam.Enabled = visible
	end
	if guideBillboard and guideBillboard.Parent then
		guideBillboard.Enabled = visible
	end
end

-- Actualizar visibilidad basada en la zona actual del jugador.
-- Si el jugador ya está en la zona objetivo → oculta beam+billboard.
-- Si está fuera → muestra. Para objetivos sin zona (carlos) siempre visible.
local function updateGuideVisibility()
	local current = listaObjetivos[indexActual]
	if not current or not current.Zona then
		setGuideVisible(true)
		return
	end
	if completados[current.ID] then
		-- Ya avanzó: current es el siguiente objetivo, siempre visible
		setGuideVisible(true)
		return
	end
	local playerZone = localPlayer:GetAttribute("CurrentZone") or ""
	-- Ocultar si el jugador ya está en la zona objetivo
	setGuideVisible(playerZone ~= current.Zona)
end

-- ============================================
-- PRIVADAS – APUNTAR Y LIMPIAR
-- ============================================

local function apuntarA(part, objetivo)
	local char = localPlayer.Character
	if not char then
		warn("❌ GuiaService: Sin personaje para apuntar guía")
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
--                       (PART_DIRECTA: la Part pertenece al nivel, no se toca)
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
			-- Eliminamos la Part completa (y con ella el beacon + att)
			if part and part.Parent then part:Destroy() end
		else
			-- Solo limpiamos lo que añadimos; la Part del nivel se conserva
			if beacon and beacon.Parent then beacon:Destroy() end
			if att   and att.Parent   then att:Destroy()    end
		end
	end)
end

-- ============================================
-- PÚBLICO: avanzar al siguiente objetivo
--
-- Llamar con el ID del objetivo ACTUAL que acaba de completarse.
-- Ejemplo: GuiaAvanzar:Fire("carlos")
-- ============================================

function GuiaService:avanzar(objetivoID)
	local current = listaObjetivos[indexActual]
	if not current then
		warn("⚠️ GuiaService:avanzar() – No hay objetivo activo (indexActual=" .. indexActual .. ")")
		return
	end

	if current.ID ~= objetivoID then
		-- Silencioso: puede ser un evento de otra etapa o desfase temporal
		return
	end

	if completados[objetivoID] then return end
	completados[objetivoID] = true

	local prevPart      = currentPart
	local shouldDestroy = current.DestruirAlCompletar ~= false  -- true por defecto

	-- Avanzar índice
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
-- PÚBLICO: inicializar guía para un nivel dado
-- ============================================

function GuiaService:initForLevel(nivelID)
	self:limpiar()
	completados = {}

	local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))
	local levelCfg = LevelsConfig[nivelID]
	if not levelCfg then
		print("ℹ️ GuiaService: Nivel " .. tostring(nivelID) .. " no existe en LevelsConfig")
		return
	end
	if not levelCfg.Guia or #levelCfg.Guia == 0 then
		print("ℹ️ GuiaService: Nivel " .. tostring(nivelID) .. " sin sección 'Guia'")
		return
	end

	listaObjetivos = levelCfg.Guia

	-- Obtener modelo del nivel activo
	local levelModel = getLevelModel()
	if not levelModel then
		warn("❌ GuiaService: NivelActual no encontrado en Workspace")
		return
	end

	-- Buscar Objetivos dentro del nivel
	objetivosFolder = levelModel:FindFirstChild("Objetivos")
		or levelModel:WaitForChild("Objetivos", 10)

	if not objetivosFolder then
		warn("❌ GuiaService: 'Objetivos' no encontrada dentro de NivelActual")
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
		print("🧭 GuiaService: Guía iniciada → Objetivo[1] '" .. first.ID .. "'")
	else
		warn("❌ GuiaService: No se pudo resolver primer waypoint '" .. first.ID .. "'")
	end
end

-- ============================================
-- PÚBLICO: limpiar toda la guía visual
-- ============================================

function GuiaService:limpiar()
	destroyBeam()
	destroyBillboard()
	if headAttachment and headAttachment.Parent then
		headAttachment:Destroy()
	end
	headAttachment        = nil
	currentPart           = nil
	indexActual           = 0
	listaObjetivos        = {}
	misionesCompletadas   = {}
end

-- ============================================
-- INIT – conecta eventos y atributos
-- ============================================

function GuiaService:init()
	print("🧭 GuiaService: Inicializando...")

	-- 1. Escuchar cambio de nivel (servidor pone CurrentLevelID)
	localPlayer:GetAttributeChangedSignal("CurrentLevelID"):Connect(function()
		local id = localPlayer:GetAttribute("CurrentLevelID")
		if id and id >= 0 then
			-- Pequeña espera para que el nivel y el personaje estén listos
			task.delay(2, function()
				self:initForLevel(id)
			end)
		else
			self:limpiar()
		end
	end)

	-- 2. Reconectar beam si el personaje respawna (sin reiniciar progreso)
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

	-- 3. Escuchar BindableEvents desde ReplicatedStorage/Events/Bindables
	task.spawn(function()
		local Events    = ReplicatedStorage:WaitForChild("Events", 15)
		if not Events then
			warn("❌ GuiaService: Carpeta Events no encontrada")
			return
		end
		local Bindables = Events:WaitForChild("Bindables", 10)
		if not Bindables then
			warn("❌ GuiaService: Carpeta Bindables no encontrada")
			return
		end

		-- GuiaAvanzar:Fire("objetivoID") → avanza la guía
		local guiaEv = Bindables:WaitForChild("GuiaAvanzar", 10)
		if guiaEv then
			guiaEv.Event:Connect(function(id)
				self:avanzar(id)
			end)
			print("✅ GuiaService: Escuchando 'GuiaAvanzar'")
		else
			warn("⚠️ GuiaService: BindableEvent 'GuiaAvanzar' no encontrado en Bindables")
		end

		-- Limpiar guía al volver al menú
		local openMenu = Bindables:FindFirstChild("OpenMenu")
		if openMenu then
			openMenu.Event:Connect(function()
				self:limpiar()
			end)
		end
	end)

	-- 4. Auto-avanzar guía cuando se completan todas las misiones de la zona actual.
	--    El server dispara ActualizarMision(misionID, true/false) al cliente.
	--    GuiaService lo escucha y verifica si todas las misiones de current.Zona están listas.
	task.spawn(function()
		local Events  = ReplicatedStorage:WaitForChild("Events", 15)
		if not Events then return end
		local Remotes = Events:WaitForChild("Remotes", 10)
		if not Remotes then return end
		local actualizarEv = Remotes:WaitForChild("ActualizarMision", 10)
		if not actualizarEv then
			warn("⚠️ GuiaService: 'ActualizarMision' no encontrado en Remotes")
			return
		end

		local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))

		actualizarEv.OnClientEvent:Connect(function(misionID, completada)
			misionesCompletadas[misionID] = completada or nil

			-- Solo actuar si hay un objetivo activo con zona asignada
			local current = listaObjetivos[indexActual]
			if not current or not current.Zona then return end
			if completados[current.ID] then return end

			local nivelID = localPlayer:GetAttribute("CurrentLevelID")
			if not nivelID then return end
			local levelCfg = LevelsConfig[nivelID]
			if not levelCfg or not levelCfg.Misiones then return end

			-- Verificar que TODAS las misiones de la zona estén completas
			local hayMisiones = false
			for _, mision in ipairs(levelCfg.Misiones) do
				if mision.Zona == current.Zona then
					hayMisiones = true
					if not misionesCompletadas[mision.ID] then return end
				end
			end

			if not hayMisiones then return end  -- zona sin misiones → no auto-avanzar

			print("🧭 GuiaService: Zona '" .. current.Zona .. "' completada → avanzando guía")
			self:avanzar(current.ID)
		end)

		print("✅ GuiaService: Escuchando 'ActualizarMision' para auto-avanzar por zona")
	end)

	-- 5. Ocultar/mostrar beam+billboard según si el jugador está en la zona objetivo
	localPlayer:GetAttributeChangedSignal("CurrentZone"):Connect(function()
		updateGuideVisibility()
	end)

	-- 6. Si ya hay nivel activo al cargar (Studio / rejoins)
	local existingID = localPlayer:GetAttribute("CurrentLevelID")
	if existingID and existingID >= 0 then
		task.delay(2, function()
			self:initForLevel(existingID)
		end)
	end

	print("✅ GuiaService: Inicializado correctamente")
end

-- Auto-init al hacer require
GuiaService:init()

return GuiaService
