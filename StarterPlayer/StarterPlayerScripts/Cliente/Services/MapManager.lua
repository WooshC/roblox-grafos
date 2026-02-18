-- ================================================================
-- MapManager.lua (v6 - colores: rojo/azul/verde/amarillo adyacentes)
-- ================================================================

local MapManager = {}
MapManager.__index = MapManager

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")

local LevelsConfig      = nil
local NodeLabelManager  = nil
local MissionsManager   = nil
local MatrixManager     = nil  -- 🔥 NUEVO: Para limpiar selección al entrar en modo mapa

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local state            = nil
local screenGui        = nil
local btnMapa          = nil
local camaraConnection = nil
local clickConnection  = nil
local zoneHighlights   = {}

local mapaClickEvent   = nil

-- ================================================================
-- ESTADO DE SELECCIÓN EN MODO MAPA
-- ================================================================
local nodoSeleccionado        = nil  -- nombre del poste del primer click
local adyacentesSeleccionados = {}   -- { [nombrePoste] = true }

local function limpiarSeleccionMapa()
	nodoSeleccionado        = nil
	adyacentesSeleccionados = {}
end

local function calcularAdyacentes(nombrePoste, nivelID)
	adyacentesSeleccionados = {}
	local config = LevelsConfig and (LevelsConfig[nivelID] or LevelsConfig[0])
	if not config or not config.Adyacencias then return end
	local ady = config.Adyacencias[nombrePoste]
	if not ady then return end
	for _, vecino in ipairs(ady) do
		adyacentesSeleccionados[vecino] = true
	end
end

-- ================================================================
-- ESTADO DEL TECHO
-- ================================================================
local techoValoresOriginales = {}
local techoCapturado         = false
local techoEstaOculto        = false

-- ================================================================
-- FUNCIONES LOCALES
-- ================================================================

local function capturarOriginales()
	if techoCapturado then return end
	local nivelActual = workspace:FindFirstChild("NivelActual")
	if not nivelActual then return end
	local techosFolder = nivelActual:FindFirstChild("Techos")
	if not techosFolder then return end
	for _, part in ipairs(techosFolder:GetChildren()) do
		if part:IsA("BasePart") then
			techoValoresOriginales[part] = {
				Transparency = part.Transparency,
				CastShadow   = part.CastShadow,
				CanQuery     = part.CanQuery,
			}
		end
	end
	techoCapturado = true
	print("🏠 MapManager: Originales del techo capturados")
end

local function findZones(nivelModel)
	if not nivelModel then return {} end
	local zonas = nivelModel:FindFirstChild("Zonas")
	if not zonas then return {} end
	local zonasJuego = zonas:FindFirstChild("Zonas_juego")
	if not zonasJuego then return {} end
	return zonasJuego:GetChildren()
end

local function getZoneConfig(zonaID, nivelID)
	local config = LevelsConfig[nivelID]
	if not config or not config.Zonas then return nil end
	return config.Zonas[zonaID]
end

local function clearZoneHighlights()
	for zonaPart, data in pairs(zoneHighlights) do
		if zonaPart and zonaPart.Parent then
			zonaPart.Transparency = data.OriginalTransparency
		end
		if data.Highlight and data.Highlight.Parent then data.Highlight:Destroy() end
		if data.Billboard and data.Billboard.Parent then data.Billboard:Destroy() end
		if data.ZoneConnection then data.ZoneConnection:Disconnect() end  -- 🔥 NUEVO: Limpiar conexión
	end
	zoneHighlights = {}
end

local function highlightZone(zonaPart, zonaID, nivelID)
	if not zonaPart or not zonaPart:IsA("BasePart") then return end
	local zoneConfig = getZoneConfig(zonaID, nivelID)
	if not zoneConfig then
		zoneConfig = { Descripcion = zonaID, Color = Color3.fromRGB(65, 105, 225), Concepto = "" }
	end
	if zoneConfig.Oculta then return end

	local originalTransparency = zonaPart.Transparency

	local highlight = Instance.new("Highlight")
	highlight.Name             = "ZoneHighlight"
	highlight.Adornee          = zonaPart
	highlight.FillColor        = zoneConfig.Color or Color3.fromRGB(65, 105, 225)
	highlight.OutlineColor     = Color3.new(1, 1, 1)
	highlight.FillTransparency = 0.3
	highlight.OutlineTransparency = 0
	highlight.Parent           = zonaPart

	zonaPart.Transparency = 0.7

	local bb = Instance.new("BillboardGui")
	bb.Name         = "ZoneBillboard"
	bb.Size         = UDim2.new(0, 300, 0, 100)
	bb.StudsOffset  = Vector3.new(0, 8, 0)
	bb.AlwaysOnTop  = true
	bb.Parent       = zonaPart

	local frame = Instance.new("Frame")
	frame.Size                  = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3      = zoneConfig.Color or Color3.fromRGB(65, 105, 225)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel       = 0
	frame.Parent                = bb

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent       = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color     = Color3.new(1, 1, 1)
	stroke.Thickness = 3
	stroke.Parent    = frame

	local label = Instance.new("TextLabel")
	label.Size               = UDim2.new(1, -20, 0.6, 0)
	label.Position           = UDim2.new(0, 10, 0, 10)
	label.BackgroundTransparency = 1
	label.Text               = zoneConfig.Descripcion or zonaID
	label.TextColor3         = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3   = Color3.new(0, 0, 0)
	label.Font               = Enum.Font.FredokaOne
	label.TextSize           = 22
	label.TextScaled         = true
	label.TextXAlignment     = Enum.TextXAlignment.Center
	label.TextYAlignment     = Enum.TextYAlignment.Top
	label.Parent             = frame

	if zoneConfig.Concepto and zoneConfig.Concepto ~= "" then
		local conceptLabel = Instance.new("TextLabel")
		conceptLabel.Size               = UDim2.new(1, -20, 0.3, 0)
		conceptLabel.Position           = UDim2.new(0, 10, 0.65, 0)
		conceptLabel.BackgroundTransparency = 1
		conceptLabel.Text               = "📚 " .. zoneConfig.Concepto
		conceptLabel.TextColor3         = Color3.fromRGB(255, 255, 200)
		conceptLabel.TextStrokeTransparency = 0
		conceptLabel.Font               = Enum.Font.GothamBold
		conceptLabel.TextSize           = 14
		conceptLabel.TextScaled         = true
		conceptLabel.TextXAlignment     = Enum.TextXAlignment.Center
		conceptLabel.Parent             = frame
	end

	frame.Size = UDim2.new(0, 0, 0, 0)
	TweenService:Create(frame,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.new(1, 0, 1, 0) }
	):Play()

	-- 🔥 NUEVO: Ocultar billboard cuando el jugador está dentro de la zona
	local function updateBillboardVisibility()
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root or not zonaPart then return end
		
		-- Verificar si el jugador está dentro de la zona usando CurrentZone
		local currentZone = player:GetAttribute("CurrentZone")
		local isInZone = currentZone == zonaID
		
		-- Ocultar billboard si está dentro de la zona
		if bb and bb.Parent then
			bb.Enabled = not isInZone
		end
	end
	
	-- Actualizar visibilidad inicialmente
	updateBillboardVisibility()
	
	-- Actualizar cuando cambia la zona
	local zoneConnection = player:GetAttributeChangedSignal("CurrentZone"):Connect(updateBillboardVisibility)

	zoneHighlights[zonaPart] = {
		Highlight            = highlight,
		Billboard            = bb,
		OriginalTransparency = originalTransparency,
		ZoneConnection       = zoneConnection,  -- Guardar para limpiar después
	}
end

local function highlightAllZones(nivelModel, nivelID)
	local zonas = findZones(nivelModel)
	if #zonas == 0 then return end

	local zonasResaltadas = 0
	for _, zona in ipairs(zonas) do
		local zonaID   = zona.Name
		local zonaPart = nil

		if zona:IsA("BasePart") then
			zonaPart = zona
		else
			local largestSize = 0
			for _, child in ipairs(zona:GetDescendants()) do
				if child:IsA("BasePart") and not child:IsA("Attachment") then
					local size = child.Size.X * child.Size.Y * child.Size.Z
					if size > largestSize then
						zonaPart    = child
						largestSize = size
					end
				end
			end
		end

		if zonaPart then
			highlightZone(zonaPart, zonaID, nivelID)
			zonasResaltadas = zonasResaltadas + 1
		end
	end

	if zonasResaltadas > 0 then
		print("✅ MapManager: " .. zonasResaltadas .. " zonas resaltadas")
	end
end

-- ================================================================
-- INICIALIZACIÓN
-- ================================================================

function MapManager.initialize(globalState, screenGui_ref, deps)
	state            = globalState
	screenGui        = screenGui_ref
	LevelsConfig     = deps.LevelsConfig
	NodeLabelManager = deps.NodeLabelManager
	MissionsManager  = deps.MissionsManager
	MatrixManager    = deps.MatrixManager  -- 🔥 NUEVO

	local barraBotones = screenGui:FindFirstChild("BarraBotonesMain")
	if barraBotones then btnMapa = barraBotones:FindFirstChild("BtnMapa") end
	if not btnMapa  then btnMapa = screenGui:FindFirstChild("BtnMapa") end

	task.spawn(function()
		local Events    = ReplicatedStorage:WaitForChild("Events", 10)
		if not Events then return end

		local Remotes   = Events:WaitForChild("Remotes", 10)
		local Bindables = Events:WaitForChild("Bindables", 10)

		if Remotes then
			mapaClickEvent = Remotes:WaitForChild("MapaClickNodo", 10)
			if mapaClickEvent then
				print("✅ MapManager: mapaClickEvent listo")
			else
				warn("❌ MapManager: MapaClickNodo no encontrado")
			end
		end

		if not Bindables then return end

		local function getOrCreate(name)
			local e = Bindables:FindFirstChild(name)
			if not e then
				e      = Instance.new("BindableEvent")
				e.Name = name
				e.Parent = Bindables
			end
			return e
		end

		getOrCreate("ForceCloseMap").Event:Connect(function()
			if state.mapaActivo then
				MapManager:_cerrarMapa(false)
			end
		end)

		getOrCreate("ShowRoof").Event:Connect(function()
			MapManager:showRoof()
		end)

		getOrCreate("RestoreRoof").Event:Connect(function()
			MapManager:restoreRoof()
		end)

		print("✅ MapManager: BindableEvents conectados")
	end)

	print("✅ MapManager: Inicializado")
end

-- ================================================================
-- API PÚBLICA DE TECHOS
-- ================================================================

function MapManager:showRoof()
	if techoEstaOculto then return end
	capturarOriginales()
	for part in pairs(techoValoresOriginales) do
		if part and part.Parent then
			part.Transparency = 0.95
			part.CastShadow   = false
			part.CanQuery     = false
		end
	end
	techoEstaOculto = true
	print("🏠 MapManager: Techo ocultado")
end

function MapManager:restoreRoof()
	if not techoEstaOculto then return end
	for part, orig in pairs(techoValoresOriginales) do
		if part and part.Parent then
			part.Transparency = orig.Transparency
			part.CastShadow   = orig.CastShadow
			part.CanQuery     = orig.CanQuery
		end
	end
	techoEstaOculto = false
	print("🏠 MapManager: Techo restaurado")
end

function MapManager:resetRoofCache()
	techoValoresOriginales = {}
	techoCapturado         = false
	techoEstaOculto        = false
end

-- ================================================================
-- MINIMAP
-- ================================================================

function MapManager:_setMinimapVisible(visible)
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return end

	local guiExplorador = playerGui:FindFirstChild("GUIExplorador")
	if guiExplorador then
		local contenedor = guiExplorador:FindFirstChild("ContenedorMiniMapa")
		if contenedor then
			contenedor.Visible = visible
			print("🗺️ ContenedorMiniMapa " .. (visible and "mostrado" or "ocultado"))
			return
		end
	end

	warn("⚠️ MapManager: No se encontró ContenedorMiniMapa en GUIExplorador")
end

-- ================================================================
-- CONTROL DEL MAPA
-- ================================================================

function MapManager:toggle(forceState)
	if forceState ~= nil then
		if forceState then self:enable() else self:disable() end
		return
	end
	if state.mapaActivo then self:disable() else self:enable() end
end

function MapManager:enable()
	state.mapaActivo = true

	-- 🔥 FIX: Limpiar selección de matriz al entrar en modo mapa
	if MatrixManager and MatrixManager.clearSelection then
		MatrixManager.clearSelection()
	end

	if btnMapa then
		btnMapa.Text             = "CERRAR MAPA"
		btnMapa.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
	end

	camera.CameraType = Enum.CameraType.Scriptable

	if NodeLabelManager then NodeLabelManager:show() end
	if MissionsManager  then MissionsManager:hide()  end

	self:showRoof()
	self:_setMinimapVisible(false)

	local nivelID    = player:GetAttribute("CurrentLevelID") or 0
	local config     = LevelsConfig[nivelID] or LevelsConfig[0]
	local nivelModel = self:_getLevelModel(nivelID, config)
	if nivelModel then
		task.delay(0.3, function()
			highlightAllZones(nivelModel, nivelID)
		end)
	end

	self:_populateLabels()
	self:_startCameraLoop()
	self:_startClickInput()
end

function MapManager:disable()
	self:_cerrarMapa(true)
end

function MapManager:isActive()
	return state ~= nil and state.mapaActivo == true
end

function MapManager:_cerrarMapa(restaurarTecho)
	state.mapaActivo = false

	if btnMapa then
		btnMapa.Text             = "🗺️ MAPA"
		btnMapa.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
	end

	if not state.enMenu then
		camera.CameraType = Enum.CameraType.Custom
	end

	if NodeLabelManager then NodeLabelManager:hide() end

	if restaurarTecho then
		self:restoreRoof()
	end

	clearZoneHighlights()

	if camaraConnection then
		camaraConnection:Disconnect()
		camaraConnection = nil
	end

	self:_stopClickInput()
	limpiarSeleccionMapa()
	self:_setMinimapVisible(true)
	self:_restoreSelectors()
end

-- ================================================================
-- LOOP DE CÁMARA
-- ================================================================

function MapManager:_startCameraLoop()
	local nivelID    = player:GetAttribute("CurrentLevelID") or 0
	local config     = LevelsConfig[nivelID] or LevelsConfig[0]
	local nivelModel = self:_getLevelModel(nivelID, config)
	if not nivelModel then return end

	local postesFolder = nivelModel:FindFirstChild("Objetos")
		and nivelModel.Objetos:FindFirstChild("Postes")
	local nombreInicio = config.NodoInicio
	local nombreFin    = config.NodoFin

	if camaraConnection then camaraConnection:Disconnect() end

	camaraConnection = RunService.RenderStepped:Connect(function()
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then return end

		local centro = root.Position
		camera.CFrame = CFrame.new(centro + Vector3.new(0, state.zoomLevel, 0), centro)

		if NodeLabelManager then NodeLabelManager:updateAllPositions() end

		if postesFolder then
			for _, poste in ipairs(postesFolder:GetChildren()) do
				if poste:IsA("Model") then
					self:_updateNodeSelector(poste, nombreInicio, nombreFin)
					self:_updateNodeLabel(poste, centro)
				end
			end
		end
	end)
end

-- ================================================================
-- INPUT DE CLICK
-- ================================================================

function MapManager:_startClickInput()
	if clickConnection then clickConnection:Disconnect() end

	if not mapaClickEvent then
		warn("⚠️ MapManager: mapaClickEvent no listo, reintentando en 1s...")
		task.delay(1, function()
			if state.mapaActivo then
				self:_startClickInput()
			end
		end)
		return
	end

	-- Garantizar CanQuery = true en todos los Selectores
	local nivelID    = player:GetAttribute("CurrentLevelID") or 0
	local config     = LevelsConfig[nivelID] or LevelsConfig[0]
	local nivelModel = self:_getLevelModel(nivelID, config)
	if nivelModel then
		local postesFolder = nivelModel:FindFirstChild("Objetos")
			and nivelModel.Objetos:FindFirstChild("Postes")
		if postesFolder then
			for _, poste in ipairs(postesFolder:GetChildren()) do
				local sel = poste:FindFirstChild("Selector")
				if sel and sel:IsA("BasePart") then
					sel.CanQuery = true
				end
			end
		end
	end

	clickConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local mouseLocation = UserInputService:GetMouseLocation()
		local ray = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)

		local nivelID2    = player:GetAttribute("CurrentLevelID") or 0
		local config2     = LevelsConfig[nivelID2] or LevelsConfig[0]
		local nivelModel2 = self:_getLevelModel(nivelID2, config2)

		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		local candidatos = {}

		if nivelModel2 then
			local pf = nivelModel2:FindFirstChild("Objetos")
				and nivelModel2.Objetos:FindFirstChild("Postes")
			if pf then
				for _, poste in ipairs(pf:GetChildren()) do
					local sel = poste:FindFirstChild("Selector")
					if sel and sel:IsA("BasePart") then
						table.insert(candidatos, sel)
					end
				end
			end
			if #candidatos == 0 then
				for _, d in ipairs(nivelModel2:GetDescendants()) do
					if d.Name == "Selector" and d:IsA("BasePart") then
						table.insert(candidatos, d)
					end
				end
			end
		end

		if #candidatos == 0 then
			warn("⚠️ MapManager: No se encontraron Selectores para click")
			return
		end

		params.FilterDescendantsInstances = candidatos
		local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)

		if result and result.Instance then
			local selector    = result.Instance
			local posteNombre = selector.Parent and selector.Parent.Name or "DESCONOCIDO"
			print("🎯 MapClick detectado → Poste: " .. posteNombre)
			
			if not mapaClickEvent then
				warn("❌ MapManager: mapaClickEvent no está disponible, no se puede enviar al servidor")
				return
			end

			if not nodoSeleccionado then
				-- Primer click: guardar selección y calcular adyacentes
				nodoSeleccionado = posteNombre
				calcularAdyacentes(posteNombre, nivelID2)
				print("   → Primer nodo seleccionado: " .. posteNombre)
				local adyList = {}
				for k in pairs(adyacentesSeleccionados or {}) do
					table.insert(adyList, k)
				end
				print("   → Adyacentes: " .. (#adyList > 0 and table.concat(adyList, ", ") or "ninguno"))
			else
				-- Segundo click: limpiar selección
				print("   → Segundo click, limpiando selección")
				limpiarSeleccionMapa()
			end

			-- Enviar al servidor
			print("   → Enviando al servidor...")
			local success, err = pcall(function()
				mapaClickEvent:FireServer(selector)
			end)
			
			if not success then
				warn("❌ Error al enviar MapaClickNodo: " .. tostring(err))
			else
				print("   ✅ Evento enviado correctamente")
			end
		else
			-- Diagnóstico
			local paramsDebug = RaycastParams.new()
			paramsDebug.FilterType = Enum.RaycastFilterType.Exclude
			local debugExclude = {}
			if player.Character then table.insert(debugExclude, player.Character) end
			for part, _ in pairs(techoValoresOriginales) do
				table.insert(debugExclude, part)
			end
			paramsDebug.FilterDescendantsInstances = debugExclude
			local rd = workspace:Raycast(ray.Origin, ray.Direction * 1000, paramsDebug)
			if rd then
				print("❌ Click fallido. El rayo golpeó: " .. rd.Instance.Name .. " (" .. rd.Instance.Parent.Name .. ")")
			else
				print("❌ Click fallido. El rayo no golpeó nada.")
			end
		end
	end)

	print("✅ MapManager: Click input activo")
end

function MapManager:_stopClickInput()
	if clickConnection then
		clickConnection:Disconnect()
		clickConnection = nil
	end
end

-- ================================================================
-- SELECTORES Y ETIQUETAS
-- ================================================================

-- Devuelve true si el poste tiene al menos una conexión activa
local function tieneConexiones(poste)
	local connections = poste:FindFirstChild("Connections")
	if not connections then return false end
	return #connections:GetChildren() > 0
end

function MapManager:_updateNodeSelector(poste, nombreInicio, nombreFin)
	local selector = poste:FindFirstChild("Selector")
	if not selector or not selector:IsA("BasePart") then return end
	selector.Transparency = 0
	selector.CanQuery     = true

	-- Guardar tamaño original la primera vez
	if not selector:GetAttribute("OriginalSize") then
		selector:SetAttribute("OriginalSize", selector.Size)
	end
	local origSize = selector:GetAttribute("OriginalSize")

	local nombre     = poste.Name
	local energizado = poste:GetAttribute("Energizado")
	local conectado  = tieneConexiones(poste)

	-- ================================================================
	-- PRIORIDAD DE COLORES:
	-- 1. 🟡 AMARILLO  — adyacente del nodo seleccionado (primer click activo)
	-- 2. 🔵 AZUL VIF  — nodo actualmente seleccionado (esperando segundo click)
	-- 3. ⚪ AZUL CLARO — nodo inicio especial (siempre)
	-- 4. 🟢 VERDE     — energizado (corriente llega desde inicio)
	-- 5. 🔵 AZUL      — tiene cables pero no energizado aún
	-- 6. 🔴 ROJO      — aislado, sin ninguna conexión
	-- ================================================================

	if nodoSeleccionado and adyacentesSeleccionados[nombre] then
		selector.Color    = Color3.fromRGB(255, 220, 0)   -- 🟡 Amarillo
		selector.Material = Enum.Material.Neon
		if origSize then selector.Size = origSize * 1.2 end

	elseif nodoSeleccionado == nombre then
		selector.Color    = Color3.fromRGB(0, 120, 255)   -- 🔵 Azul vivo (seleccionado)
		selector.Material = Enum.Material.Neon
		if origSize then selector.Size = origSize * 1.3 end

	elseif nombre == nombreInicio then
		selector.Color    = Color3.fromRGB(52, 152, 219)  -- ⚪ Azul claro (inicio)
		selector.Material = Enum.Material.Neon
		if origSize then selector.Size = origSize end

	elseif energizado == true then
		selector.Color    = Color3.fromRGB(46, 204, 113)  -- 🟢 Verde (energizado)
		selector.Material = Enum.Material.Plastic
		if origSize then selector.Size = origSize end

	elseif conectado then
		selector.Color    = Color3.fromRGB(52, 152, 219)  -- 🔵 Azul (conectado, sin energía)
		selector.Material = Enum.Material.Neon
		if origSize then selector.Size = origSize end

	else
		selector.Color    = Color3.fromRGB(231, 76, 60)   -- 🔴 Rojo (aislado)
		selector.Material = Enum.Material.Neon
		if origSize then selector.Size = origSize * 1.3 end
	end
end

function MapManager:_updateNodeLabel(poste, centroCamara)
	if not NodeLabelManager then return end
	local obj = NodeLabelManager:getLabelForNode(poste)
	if not obj then return end
	local distancia = math.floor((poste:GetPivot().Position - centroCamara).Magnitude / 5)
	NodeLabelManager:updateNodeDistance(poste, distancia)
	local nivelID = player:GetAttribute("CurrentLevelID") or 0
	NodeLabelManager:addMetaIndicator(poste, nivelID)
end

-- ================================================================
-- UTILIDADES
-- ================================================================

function MapManager:_restoreSelectors()
	local nivelModel = self:_getLevelModel(player:GetAttribute("CurrentLevelID") or 0, nil)
	if not nivelModel then return end
	local postesFolder = nivelModel:FindFirstChild("Objetos")
		and nivelModel.Objetos:FindFirstChild("Postes")
	if not postesFolder then return end

	for _, poste in ipairs(postesFolder:GetChildren()) do
		if poste:IsA("Model") then
			local selector = poste:FindFirstChild("Selector")
			if selector and selector:IsA("BasePart") then
				selector.Transparency = 1
				selector.Color        = Color3.fromRGB(196, 196, 196)
				selector.Material     = Enum.Material.Plastic
				selector.CanQuery     = true  -- ClickDetectors necesitan CanQuery=true
				local origSize        = selector:GetAttribute("OriginalSize")
				if origSize then selector.Size = origSize end
			end
		end
	end
end

function MapManager:_getLevelModel(nivelID, config)
	local m = workspace:FindFirstChild("NivelActual")
	if m then return m end
	if config then
		m = workspace:FindFirstChild(config.Modelo)
		if m then return m end
	end
	if nivelID then
		m = workspace:FindFirstChild("Nivel" .. nivelID)
		if m then return m end
		m = workspace:FindFirstChild("Nivel" .. nivelID .. "_Tutorial")
		if m then return m end
	end
	for _, child in ipairs(workspace:GetChildren()) do
		if child.Name:match("^Nivel%d+") then
			return child
		end
	end
	return nil
end

function MapManager:_populateLabels()
	local nivelID    = player:GetAttribute("CurrentLevelID") or 0
	local config     = LevelsConfig[nivelID] or LevelsConfig[0]
	local nivelModel = self:_getLevelModel(nivelID, config)
	if not nivelModel then return end

	local postesFolder = nivelModel:FindFirstChild("Objetos")
		and nivelModel.Objetos:FindFirstChild("Postes")
	if not postesFolder then return end

	for _, poste in ipairs(postesFolder:GetChildren()) do
		if poste:IsA("Model") and NodeLabelManager then
			NodeLabelManager:getLabelForNode(poste)
		end
	end
end

-- ================================================================
-- LIMPIEZA
-- ================================================================

player.AncestryChanged:Connect(function(_, parent)
	if parent == nil then
		if camaraConnection then camaraConnection:Disconnect() end
		if clickConnection  then clickConnection:Disconnect()  end
		clearZoneHighlights()
	end
end)

return MapManager