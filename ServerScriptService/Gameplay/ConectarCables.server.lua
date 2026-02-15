-- ConectarCables.server.lua
-- Usa CostoPorMetro para decidir si cobrar (no flag EsTutorial)
-- Registra selección de nodos via MissionService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

task.wait(1)

local LevelService = _G.Services.Level
local GraphService = _G.Services.Graph
local UIService = _G.Services.UI
local AudioService = _G.Services.Audio
local MissionService = _G.Services.Mission
local Enums = _G.Services.Enums
local GraphUtils = _G.Services.GraphUtils

if not LevelService or not GraphService then
	error("❌ CRÍTICO: Servicios no inicializados")
end

local selecciones = {}
local SOUND_CONNECT_ID = "rbxassetid://8089220692"
local SOUND_CLICK_ID = "rbxassetid://125043525599051"

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
		AudioService:playSound(id, "sfx", {volume = 0.5})
	else
		local sound = Instance.new("Sound")
		sound.SoundId = id
		sound.Volume = 0.5
		sound.Parent = parent
		sound:Play()
		game.Debris:AddItem(sound, 2)
	end
end

-- ============================================
-- DESCONECTAR
-- ============================================

local function desconectarPostes(poste1, poste2, player)
	if not LevelService:isLevelLoaded() then return end

	local config = LevelService:getLevelConfig()
	if not config then return end

	local connections1 = poste1:FindFirstChild("Connections")
	if not connections1 then return end

	local distanciaValue = connections1:FindFirstChild(poste2.Name)
	if not distanciaValue then return end

	local distanciaMetros = distanciaValue.Value

	-- Reembolso solo si hay costo
	local costoPorMetro = config.CostoPorMetro or 0
	if costoPorMetro > 0 then
		local reembolso = math.floor(distanciaMetros * costoPorMetro)
		local leaderstats = player:FindFirstChild("leaderstats")
		local money = leaderstats and leaderstats:FindFirstChild("Money")
		if money then
			money.Value = money.Value + reembolso
		end
	end

	-- Eliminar conexiones
	local connections2 = poste2:FindFirstChild("Connections")
	if connections1:FindFirstChild(poste2.Name) then
		connections1[poste2.Name]:Destroy()
	end
	if connections2 and connections2:FindFirstChild(poste1.Name) then
		connections2[poste1.Name]:Destroy()
	end

	GraphService:disconnectNodes(poste1, poste2)
	reproducirSonido(SOUND_CLICK_ID, poste1)

	if pulseEvent then
		pulseEvent:FireAllClients("StopPulse", poste1, poste2)
	end

	-- Limpiar etiqueta de peso
	for _, child in ipairs(workspace:GetChildren()) do
		if child.Name == "EtiquetaPeso_" .. poste1.Name .. "_" .. poste2.Name or
			child.Name == "EtiquetaPeso_" .. poste2.Name .. "_" .. poste1.Name then
			child:Destroy()
		end
	end

	if UIService then
		UIService:updateProgress()
		UIService:updateBudget(player)
	end
end

-- ============================================
-- CONECTAR
-- ============================================

local function conectarPostes(poste1, poste2, att1, att2, player)
	if not LevelService:isLevelLoaded() then return end

	local config = LevelService:getLevelConfig()
	if not config then return end

	-- Validar adyacencia
	if not LevelService:canConnect(poste1, poste2) then
		if AudioService then AudioService:playError() end
		if UIService then
			UIService:notifyError(player, "Conexión Inválida", "Estos postes no pueden conectarse")
		end
		return
	end

	-- Toggle: si ya conectados, desconectar
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
		desconectarPostes(poste1, poste2, player)
		return
	end

	-- Distancia
	local distanciaStuds = (att1.WorldPosition - att2.WorldPosition).Magnitude
	local distanciaMetros = math.floor(distanciaStuds / 4)

	-- Cobrar (solo si CostoPorMetro > 0)
	local costoPorMetro = config.CostoPorMetro or 0
	local costoTotal = distanciaMetros * costoPorMetro

	if costoPorMetro > 0 then
		local leaderstats = player:FindFirstChild("leaderstats")
		local money = leaderstats and leaderstats:FindFirstChild("Money")
		if not money then return end

		if money.Value < costoTotal then
			if AudioService then AudioService:playError() end
			if UIService then
				UIService:notifyError(player, "Fondos Insuficientes", "Necesitas $" .. costoTotal)
			end
			return
		end

		money.Value = money.Value - costoTotal
	end

	-- Crear cable visual
	local rope = Instance.new("RopeConstraint")
	rope.Name = "Cable_" .. poste1.Name .. "_" .. poste2.Name
	rope.Attachment0 = att1
	rope.Attachment1 = att2
	rope.Length = distanciaStuds
	rope.Visible = true
	rope.Thickness = Enums.Cable.NormalThickness
	rope.Color = BrickColor.new("Black")

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

	GraphService:connectNodes(poste1, poste2, rope)

	-- Dirección de pulso (aristas dirigidas)
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

	-- Etiqueta de peso (solo si hay costo)
	if costoPorMetro > 0 then
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
	end

	-- Sonido
	reproducirSonido(SOUND_CONNECT_ID, att2)
	if AudioService then AudioService:playCableConnected() end

	-- Guardar datos en postes
	local c1 = Instance.new("NumberValue")
	c1.Name = poste2.Name
	c1.Value = distanciaMetros
	c1.Parent = connections1

	local c2 = Instance.new("NumberValue")
	c2.Name = poste1.Name
	c2.Value = distanciaMetros
	c2.Parent = connections2

	-- UI
	if UIService then
		UIService:updateProgress()
		UIService:updateBudget(player)
		if costoPorMetro == 0 then
			UIService:notifySuccess(player, "Arista Creada", poste1.Name .. " ↔ " .. poste2.Name)
		else
			UIService:notifySuccess(player, "Conexión Exitosa", "Cable conectado por $" .. costoTotal)
		end
	end
end

-- ============================================
-- GESTOR DE CLICKS
-- ============================================

local function onClick(selector, player)
	local poste = getPosteFromSelector(selector)

	-- Registrar selección de nodo (para misiones NODO_SELECCIONADO)
	if MissionService then
		MissionService:registerNodeSelection(player, poste.Name)
	end

	local seleccionActual = selecciones[player]

	-- Primer click
	if not seleccionActual then
		selecciones[player] = selector
		reproducirSonido(SOUND_CLICK_ID, selector)
		if AudioService then AudioService:playClick() end

		local att = getAttachment(selector)
		if att then
			cableDragEvent:FireClient(player, "Start", att)
		end
		return
	end

	-- Segundo click
	local posteAnterior = getPosteFromSelector(seleccionActual)

	if poste == posteAnterior then
		selecciones[player] = nil
		cableDragEvent:FireClient(player, "Stop")
		return
	end

	local att1 = getAttachment(seleccionActual)
	local att2 = getAttachment(selector)

	if not att1 or not att2 then
		selecciones[player] = nil
		cableDragEvent:FireClient(player, "Stop")
		return
	end

	conectarPostes(posteAnterior, poste, att1, att2, player)

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
end

if LevelService then
	LevelService:onLevelLoaded(function(nivelID, levelFolder, config)
		local postesFolder = LevelService:getPostes()
		if postesFolder then registrarPostes(postesFolder) end
	end)
end

if LevelService and LevelService:isLevelLoaded() then
	local postesFolder = LevelService:getPostes()
	if postesFolder then registrarPostes(postesFolder) end
end

print("⚡ ConectarCables cargado")