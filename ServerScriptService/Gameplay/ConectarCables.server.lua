-- ConectarCables_server.lua (REFACTORIZADO)
-- Usa los nuevos servicios: LevelService, GraphService, AudioService, UIService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- ============================================
-- CARGAR SERVICIOS
-- ============================================

-- Esperar servicios globales
repeat task.wait(0.1) until _G.Services

-- Servicios centralizados
local LevelService = _G.Services.Level
local GraphService = _G.Services.Graph
local UIService = _G.Services.UI
local AudioService = _G.Services.Audio
local Enums = _G.Services.Enums
local GraphUtils = _G.Services.GraphUtils

-- Validar que servicios existen
if not LevelService or not GraphService then
	error("❌ CRÍTICO: Servicios no inicializados correctamente. Verifica Init.server.lua")
end

print("✅ ConectarCables: Todos los servicios cargados")

-- ============================================
-- CONFIGURACIÓN
-- ============================================

local selecciones = {}  -- { [Player] = selector }
local SOUND_CONNECT_ID = "rbxassetid://8089220692"
local SOUND_CLICK_ID = "rbxassetid://125043525599051"

-- Referencias a eventos
local Remotes = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes")
local cableDragEvent = Remotes:WaitForChild("CableDragEvent")
local pulseEvent = Remotes:WaitForChild("PulseEvent")

-- ============================================
-- UTILIDADES
-- ============================================

local function getPosteFromSelector(selector)
	return selector.Parent
end

local function getAttachment(selector)
	return selector:FindFirstChild("Attachment")
end

local function reproducirSonido(id, parent)
	if AudioService then
		-- Usar AudioService si está disponible
		AudioService:playSound(id, "sfx", {volume = 0.5})
	else
		-- Fallback a método antiguo
		local sound = Instance.new("Sound")
		sound.SoundId = id
		sound.Volume = 0.5
		sound.Parent = parent
		sound:Play()
		game.Debris:AddItem(sound, 2)
	end
end

-- ============================================
-- DESCONECTAR POSTES
-- ============================================

local function desconectarPostes(poste1, poste2, player)
	-- Validar nivel del jugador
	local nivelID = LevelService:getCurrentLevelID()
	if not LevelService:isLevelLoaded() or not nivelID then
		warn("⚠️ No hay nivel cargado")
		return
	end

	-- Obtener información de conexión
	local connections1 = poste1:FindFirstChild("Connections")
	if not connections1 then return end

	local distanciaValue = connections1:FindFirstChild(poste2.Name)
	if not distanciaValue then return end

	local distanciaMetros = distanciaValue.Value
	local config = LevelService:getLevelConfig()

	if not config then return end

	-- Calcular reembolso
	local costoPorMetro = config.CostoPorMetro
	local reembolso = math.floor(distanciaMetros * costoPorMetro)

	-- Devolver dinero
	local leaderstats = player:FindFirstChild("leaderstats")
	local money = leaderstats and leaderstats:FindFirstChild("Money")

	if money then
		money.Value = money.Value + reembolso
		print("💰 Dinero reembolsado: $" .. reembolso)
	end

	-- Eliminar datos de conexión en postes
	local connections2 = poste2:FindFirstChild("Connections")
	if connections1:FindFirstChild(poste2.Name) then
		connections1[poste2.Name]:Destroy()
	end
	if connections2 and connections2:FindFirstChild(poste1.Name) then
		connections2[poste1.Name]:Destroy()
	end

	-- Desregistrar cable en GraphService
	GraphService:disconnectNodes(poste1, poste2)

	-- Reproducir sonido
	reproducirSonido(SOUND_CLICK_ID, poste1)

	-- Detener pulso visual
	if pulseEvent then
		pulseEvent:FireAllClients("StopPulse", poste1, poste2)
	end

	-- Eliminar etiqueta de peso
	for _, child in ipairs(workspace:GetChildren()) do
		if child.Name == "EtiquetaPeso_" .. poste1.Name .. "_" .. poste2.Name or 
			child.Name == "EtiquetaPeso_" .. poste2.Name .. "_" .. poste1.Name then
			child:Destroy()
		end
	end

	-- Notificar al cliente UI
	if UIService then
		UIService:updateProgress()
		UIService:updateBudget(player)
	end

	print("🔌 DESCONEXIÓN EXITOSA: " .. poste1.Name .. " <-> " .. poste2.Name)
end

-- ============================================
-- CONECTAR POSTES (FUNCIÓN PRINCIPAL)
-- ============================================

local function conectarPostes(poste1, poste2, att1, att2, player)
	-- VALIDAR NIVEL CARGADO
	if not LevelService:isLevelLoaded() then
		warn("❌ No hay nivel cargado")
		return
	end

	local nivelID = LevelService:getCurrentLevelID()
	local config = LevelService:getLevelConfig()

	if not config then return end

	-- VALIDAR QUE PUEDE CONECTAR
	if not LevelService:canConnect(poste1, poste2) then
		print("🚫 CONEXIÓN INVÁLIDA: Adyacencia no permitida")
		if AudioService then
			AudioService:playError()
		end
		if UIService then
			UIService:notifyError(player, "Conexión Inválida", "Estos postes no pueden conectarse")
		end
		return
	end

	-- VALIDAR DUPLICADOS
	local connections1 = poste1:FindFirstChild("Connections")
	if not connections1 then
		connections1 = Instance.new("Folder")
		connections1.Name = "Connections"
		connections1.Parent = poste1
	end

	local connections2 = poste2:FindFirstChild("Connections")
	if not connections2 then
		connections2 = Instance.new("Folder")
		connections2.Name = "Connections"
		connections2.Parent = poste2
	end

	if connections1:FindFirstChild(poste2.Name) then
		print("🔄 Ya conectados. Desconectando...")
		desconectarPostes(poste1, poste2, player)
		return
	end

	-- CALCULAR DISTANCIA Y COSTO
	local distanciaStuds = (att1.WorldPosition - att2.WorldPosition).Magnitude
	local distanciaMetros = math.floor(distanciaStuds / 4)

	local costoPorMetro = config.CostoPorMetro
	local costoTotal = distanciaMetros * costoPorMetro

	-- VALIDAR DINERO
	local leaderstats = player:FindFirstChild("leaderstats")
	local money = leaderstats and leaderstats:FindFirstChild("Money")

	if not money then
		warn("⚠️ No se encontró Money en leaderstats")
		return
	end

	if money.Value < costoTotal then
		print("🚫 FONDOS INSUFICIENTES. Necesitas: $" .. costoTotal .. " | Tienes: $" .. money.Value)
		if AudioService then
			AudioService:playError()
		end
		if UIService then
			UIService:notifyError(player, "Fondos Insuficientes", "Necesitas $" .. costoTotal)
		end
		return
	end

	-- DESCONTAR DINERO
	money.Value = money.Value - costoTotal
	print("💰 Dinero descontado: $" .. costoTotal .. " | Dinero restante: $" .. money.Value)

	-- CREAR CABLE VISUAL
	local rope = Instance.new("RopeConstraint")
	rope.Name = "Cable_" .. poste1.Name .. "_" .. poste2.Name
	rope.Attachment0 = att1
	rope.Attachment1 = att2
	rope.Length = distanciaStuds
	rope.Visible = true
	rope.Thickness = Enums.Cable.NormalThickness
	rope.Color = BrickColor.new("Black")

	-- Parentear en carpeta Conexiones
	local nivel = LevelService:getCurrentLevel()
	if nivel then
		local objetos = nivel:FindFirstChild("Objetos")
		if objetos then
			local postesFolder = objetos:FindFirstChild("Postes")
			if postesFolder then
				local carpetaConexiones = postesFolder:FindFirstChild("Conexiones")
				if not carpetaConexiones then
					carpetaConexiones = Instance.new("Folder")
					carpetaConexiones.Name = "Conexiones"
					carpetaConexiones.Parent = postesFolder
				end
				rope.Parent = carpetaConexiones
			end
		end
	end

	print("✅ Cable creado: " .. rope:GetFullName())

	-- REGISTRAR EN GRAPHSERVICE
	GraphService:connectNodes(poste1, poste2, rope)

	-- CONFIGURAR PARTÍCULAS (PULSO VISUAL)
	local esBidireccional = true
	local nodoOrigen = poste1
	local nodoDestino = poste2

	if config.Adyacencias then
		local ady = config.Adyacencias
		local p1 = poste1.Name
		local p2 = poste2.Name

		local puedeIr_1to2 = ady[p1] and table.find(ady[p1], p2) or false
		local puedeIr_2to1 = ady[p2] and table.find(ady[p2], p1) or false

		if puedeIr_1to2 and not puedeIr_2to1 then
			esBidireccional = false
			nodoOrigen = poste1
			nodoDestino = poste2
		elseif puedeIr_2to1 and not puedeIr_1to2 then
			esBidireccional = false
			nodoOrigen = poste2
			nodoDestino = poste1
		end
	end

	if pulseEvent then
		pulseEvent:FireAllClients("StartPulse", nodoOrigen, nodoDestino, esBidireccional)
	end

	-- VISUALIZAR PESO (ETIQUETA DE DISTANCIA)
	local midPoint = (att1.WorldPosition + att2.WorldPosition) / 2
	local etiquetaPart = Instance.new("Part")
	etiquetaPart.Name = "EtiquetaPeso_" .. poste1.Name .. "_" .. poste2.Name
	etiquetaPart.Size = Vector3.new(0.5, 0.5, 0.5)
	etiquetaPart.Transparency = 1
	etiquetaPart.Anchored = true
	etiquetaPart.CanCollide = false
	etiquetaPart.Position = midPoint
	etiquetaPart.Parent = workspace

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 80, 0, 40)
	bb.StudsOffset = Vector3.new(0, 2, 0)
	bb.AlwaysOnTop = true
	bb.Parent = etiquetaPart

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = string.format("$%d | %dm", costoTotal, distanciaMetros)
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.TextStrokeTransparency = 0
	lbl.Font = Enum.Font.FredokaOne
	lbl.TextSize = 20
	lbl.Parent = bb

	-- REPRODUCIR SONIDO
	reproducirSonido(SOUND_CONNECT_ID, att2)
	if AudioService then
		AudioService:playCableConnected()
	end

	-- GUARDAR DATOS LÓGICOS EN POSTES
	local c1 = Instance.new("NumberValue")
	c1.Name = poste2.Name
	c1.Value = distanciaMetros
	c1.Parent = connections1

	local c2 = Instance.new("NumberValue")
	c2.Name = poste1.Name
	c2.Value = distanciaMetros
	c2.Parent = connections2

	-- ACTUALIZAR UI
	if UIService then
		UIService:updateProgress()
		UIService:updateBudget(player)
		UIService:notifySuccess(player, "Conexión Exitosa", "Cable conectado por $" .. costoTotal)
	end

	print("✅ CONEXIÓN EXITOSA: " .. poste1.Name .. " <-> " .. poste2.Name .. " ($" .. costoTotal .. ")")
end

-- ============================================
-- GESTOR DE CLICKS
-- ============================================

local function onClick(selector, player)
	local poste = getPosteFromSelector(selector)
	local seleccionActual = selecciones[player]

	-- PRIMER CLICK (Seleccionar inicio)
	if not seleccionActual then
		selecciones[player] = selector
		print("👉 Seleccionado Inicio: " .. poste.Name)

		-- Sonido click
		reproducirSonido(SOUND_CLICK_ID, selector)
		if AudioService then
			AudioService:playClick()
		end

		-- Iniciar visualización en cliente
		local att = getAttachment(selector)
		if att then
			cableDragEvent:FireClient(player, "Start", att)
		end
		return
	end

	-- SEGUNDO CLICK
	local posteAnterior = getPosteFromSelector(seleccionActual)

	-- Si hace click en el mismo poste, cancelar
	if poste == posteAnterior then
		print("⌛ Mismo poste. Cancelando selección.")
		selecciones[player] = nil
		cableDragEvent:FireClient(player, "Stop")
		return
	end

	-- Obtener attachments
	local att1 = getAttachment(seleccionActual)
	local att2 = getAttachment(selector)

	if not att1 or not att2 then
		warn("⚠️ Error: No se encontraron attachments")
		selecciones[player] = nil
		cableDragEvent:FireClient(player, "Stop")
		return
	end

	-- Realizar conexión
	conectarPostes(posteAnterior, poste, att1, att2, player)

	-- Limpiar selección
	selecciones[player] = nil
	cableDragEvent:FireClient(player, "Stop")
end

-- ============================================
-- REGISTRAR CLICK DETECTORS
-- ============================================

local function registrarPostes(carpetaPostes)
	for _, poste in ipairs(carpetaPostes:GetChildren()) do
		if poste:IsA("Model") then
			local selector = poste:FindFirstChild("Selector")
			if selector then
				local clickDetector = selector:FindFirstChild("ClickDetector")
				if clickDetector then
					clickDetector.MouseClick:Connect(function(player)
						onClick(selector, player)
					end)
				end
			end
		end
	end
	print("✅ ClickDetectors registrados en: " .. carpetaPostes:GetFullName())
end

-- Buscar y registrar postes en nivel actual
if LevelService then
	LevelService:onLevelLoaded(function(nivelID, levelFolder, config)
		print("🔌 ConectarCables: Registrando postes para Nivel " .. nivelID)

		local postesFolder = LevelService:getPostes()
		if postesFolder then
			registrarPostes(postesFolder)
		end
	end)
end

-- ============================================
-- INICIALIZACIÓN
-- ============================================

-- Si el nivel ya está cargado al iniciar este script, registrar postes manualmente
if LevelService and LevelService:isLevelLoaded() then
	print("🔌 ConectarCables: Nivel ya cargado, registrando postes diferido...")
	local postesFolder = LevelService:getPostes()
	if postesFolder then
		registrarPostes(postesFolder)
	end
end

print("⚡ ConectarCables (REFACTORIZADO) cargado exitosamente")
print("   ✅ Usa: LevelService, GraphService")
print("   ✅ Usa: UIService, AudioService")