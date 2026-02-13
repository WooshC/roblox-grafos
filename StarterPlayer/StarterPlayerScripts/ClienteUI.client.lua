-- ClienteUI.client.lua (Frontend Refactorizado V3)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))

-- Eventos Remotos
-- Eventos Remotos
local Remotes = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes")

local eventoReiniciar = Remotes:WaitForChild("ReiniciarNivel", 10)
local eventoAlgo = Remotes:WaitForChild("EjecutarAlgoritmo", 10)
local eventoInventario = Remotes:WaitForChild("ActualizarInventario", 10)

-- CONFIGURACIÓN DE UI
if playerGui:FindFirstChild("GameUI") then playerGui.GameUI:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GameUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- === COMPONENTES UI ===
local function crearBoton(nombre, texto, color, posicion)
	local boton = Instance.new("TextButton")
	boton.Name = nombre
	boton.Size = UDim2.new(0, 180, 0, 50)
	boton.Position = posicion
	boton.Text = texto
	boton.BackgroundColor3 = color
	boton.TextColor3 = Color3.new(1, 1, 1)
	boton.Font = Enum.Font.FredokaOne
	boton.TextSize = 20
	boton.Parent = screenGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = boton
	
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.new(0,0,0)
	stroke.Transparency = 0.5
	stroke.Parent = boton
	
	return boton
end

local btnReiniciar = crearBoton("BtnReiniciar", "🔄 REINICIAR", Color3.fromRGB(231, 76, 60), UDim2.new(0.5, 10, 0.9, -60))
local btnMapa = crearBoton("BtnMapa", "🗺️ MAPA", Color3.fromRGB(52, 152, 219), UDim2.new(0.5, -190, 0.9, -60))
local btnAlgo = crearBoton("BtnAlgo", "🧠 ALGORITMO", Color3.fromRGB(155, 89, 182), UDim2.new(0.5, 210, 0.9, -60))
local btnMisiones = crearBoton("BtnMisiones", "📋 MISIONES", Color3.fromRGB(46, 204, 113), UDim2.new(0.5, -390, 0.9, -60))
local btnMatriz = crearBoton("BtnMatriz", "🔢 MATRIZ", Color3.fromRGB(255, 159, 67), UDim2.new(0.5, 410, 0.9, -60))
local btnFinalizar = crearBoton("BtnFinalizar", "🏆 FINALIZAR NIVEL", Color3.fromRGB(46, 204, 113), UDim2.new(0.5, -95, 0.75, 0))

-- Label de Puntaje (siempre visible)
local lblPuntaje = Instance.new("TextLabel")
lblPuntaje.Name = "LabelPuntaje"
lblPuntaje.Size = UDim2.new(0, 250, 0, 60)
lblPuntaje.Position = UDim2.new(1, -270, 0, 20)
lblPuntaje.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
lblPuntaje.BackgroundTransparency = 0.3
lblPuntaje.Text = "⭐ 0 | 💰 0 pts"
lblPuntaje.TextColor3 = Color3.new(1, 1, 1)
lblPuntaje.Font = Enum.Font.FredokaOne
lblPuntaje.TextSize = 24
lblPuntaje.Parent = screenGui

local cornerPuntaje = Instance.new("UICorner")
cornerPuntaje.CornerRadius = UDim.new(0, 12)
cornerPuntaje.Parent = lblPuntaje

local strokePuntaje = Instance.new("UIStroke")
strokePuntaje.Thickness = 3
strokePuntaje.Color = Color3.fromRGB(255, 215, 0)
strokePuntaje.Parent = lblPuntaje

-- Visibilidad inicial
btnMapa.Visible = false
btnAlgo.Visible = false
btnFinalizar.Visible = false -- Solo aparece después de validación
lblPuntaje.Visible = false -- Se mostrará en gameplay

-- ============================================
-- DETECTOR DE MENÚ (Ocultar UI en menú)
-- ============================================
local mapaActivo = false 
local misionesActivo = false 
local tieneMapa = false -- NUEVO: Estado de posesión
local tieneAlgo = false -- NUEVO: Estado de posesión

local enMenu = true 
local botonesGameplay = {btnReiniciar, btnMapa, btnAlgo, btnMisiones, btnMatriz, btnFinalizar, lblPuntaje}

local function actualizarVisibilidadUI(estaEnMenu)
	enMenu = estaEnMenu
	
	-- Ocultar/Mostrar botones de gameplay
	for _, btn in ipairs(botonesGameplay) do
		if estaEnMenu then
			btn.Visible = false
		else
			-- Restaurar visibilidad según su estado lógico Y posesión
			if btn == btnFinalizar then
				btn.Visible = false -- Se activa por evento separado
			elseif btn == btnMapa then
				btn.Visible = tieneMapa
			elseif btn == btnAlgo then
				btn.Visible = tieneAlgo
			elseif btn == lblPuntaje then
				btn.Visible = true
			else
				btn.Visible = true
			end
		end
	end
	
	-- Ocultar Money (leaderstat) en menú
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local money = leaderstats:FindFirstChild("Money") or leaderstats:FindFirstChild("Dinero")
		if money then
			-- Roblox no permite ocultar leaderstats directamente, pero podemos ponerlo en 0 visualmente
			-- O crear un overlay que lo tape
			-- Por ahora solo registro que está en menú para otros scripts
		end
	end
end

-- Escuchar cambios de cámara para detectar menú
task.spawn(function()
	while wait(0.5) do
		local cam = workspace.CurrentCamera
		if cam and cam.CameraType == Enum.CameraType.Scriptable then
			-- Probablemente en menú, PERO verificar que no sea el mapa
			if not enMenu and not mapaActivo then
				actualizarVisibilidadUI(true)
			end
		elseif cam and cam.CameraType == Enum.CameraType.Custom then
			-- En gameplay
			if enMenu then
				actualizarVisibilidadUI(false)
			end
		end
	end
end)

local distanciaLabel = Instance.new("TextLabel")

distanciaLabel.Name = "DistanciaLabel"
distanciaLabel.Size = UDim2.new(0, 200, 0, 30)
distanciaLabel.Position = UDim2.new(0.5, -100, 0.5, 40)
distanciaLabel.BackgroundTransparency = 1
distanciaLabel.TextColor3 = Color3.new(1, 1, 1)
distanciaLabel.TextStrokeTransparency = 0
distanciaLabel.Font = Enum.Font.GothamBold
distanciaLabel.TextSize = 20
distanciaLabel.Text = ""
distanciaLabel.Visible = false
distanciaLabel.Parent = screenGui

-- === LÓGICA DE MAPA ===
-- mapaActivo y misionesActivo movidos arriba
local camaraConnection = nil
local techoOriginalTransparency = {}
local zoomLevel = 80 -- Zoom FIJO (no se puede cambiar)
local zoomBloqueado = true -- NUEVO: Bloquear zoom para evitar crashes
local etiquetasNodos = {}

-- Panel de Misión mejorado (Definición Temprana)
local misionFrame = Instance.new("Frame")
misionFrame.Name = "MisionFrame"
misionFrame.Size = UDim2.new(0, 320, 0, 200) -- Más alto y ancho para acomodar texto largo
misionFrame.Position = UDim2.new(0, 20, 0.5, -100) -- A la izquierda
misionFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
misionFrame.BackgroundTransparency = 0.4
misionFrame.Visible = false
misionFrame.Parent = screenGui

local cornerM = Instance.new("UICorner"); cornerM.CornerRadius = UDim.new(0, 12); cornerM.Parent = misionFrame
local listLayout = Instance.new("UIListLayout")
listLayout.Parent = misionFrame
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 5)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

-- Botón Cerrar Mapa/Misiones
local btnCerrarMapa = Instance.new("TextButton")
btnCerrarMapa.Name = "BtnCerrar"
btnCerrarMapa.Size = UDim2.new(0, 30, 0, 30)
btnCerrarMapa.Position = UDim2.new(1, -35, 0, 5)
btnCerrarMapa.Text = "✕"
btnCerrarMapa.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
btnCerrarMapa.TextColor3 = Color3.new(1, 1, 1)
btnCerrarMapa.Font = Enum.Font.GothamBold
btnCerrarMapa.TextSize = 20
btnCerrarMapa.Parent = misionFrame

local cornerBtn = Instance.new("UICorner")
cornerBtn.CornerRadius = UDim.new(0, 8)
cornerBtn.Parent = btnCerrarMapa

btnCerrarMapa.MouseButton1Click:Connect(function()
	if mapaActivo then
		toggleMapa()
	elseif misionesActivo then
		toggleMisiones()
	end
end)

-- Titulo Misión
local tituloMision = Instance.new("TextLabel")
tituloMision.Name = "Titulo"
tituloMision.Size = UDim2.new(1,0,0,30)
tituloMision.BackgroundTransparency = 1
tituloMision.Text = " 📋 OBJETIVOS"
tituloMision.TextColor3 = Color3.new(1,0.8,0)
tituloMision.Font = Enum.Font.GothamBlack
tituloMision.TextSize = 20
tituloMision.TextXAlignment = Enum.TextXAlignment.Left
tituloMision.Parent = misionFrame

-- Panel de Puntaje y Estrellas (Centro de la pantalla)
local scoreFrame = Instance.new("Frame")
scoreFrame.Name = "ScoreFrame"
scoreFrame.Size = UDim2.new(0, 250, 0, 120)
scoreFrame.Position = UDim2.new(0.5, -125, 0.1, 0) -- Centro superior
scoreFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
scoreFrame.BackgroundTransparency = 0.3
scoreFrame.Visible = false
scoreFrame.Parent = screenGui

local cornerS = Instance.new("UICorner"); cornerS.CornerRadius = UDim.new(0, 16); cornerS.Parent = scoreFrame
local strokeS = Instance.new("UIStroke")
strokeS.Thickness = 3
strokeS.Color = Color3.fromRGB(255, 215, 0) -- Dorado
strokeS.Transparency = 0.3
strokeS.Parent = scoreFrame

-- Etiqueta de Estrellas
local estrellaLabel = Instance.new("TextLabel")
estrellaLabel.Name = "EstrellaLabel"
estrellaLabel.Size = UDim2.new(1, 0, 0.5, 0)
estrellaLabel.Position = UDim2.new(0, 0, 0.1, 0)
estrellaLabel.BackgroundTransparency = 1
estrellaLabel.Text = "⭐⭐⭐"
estrellaLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
estrellaLabel.Font = Enum.Font.GothamBlack
estrellaLabel.TextSize = 40
estrellaLabel.TextStrokeTransparency = 0.5
estrellaLabel.Parent = scoreFrame

-- Etiqueta de Puntaje
local puntajeLabel = Instance.new("TextLabel")
puntajeLabel.Name = "PuntajeLabel"
puntajeLabel.Size = UDim2.new(1, 0, 0.35, 0)
puntajeLabel.Position = UDim2.new(0, 0, 0.6, 0)
puntajeLabel.BackgroundTransparency = 1
puntajeLabel.Text = "0 / 1200 pts"
puntajeLabel.TextColor3 = Color3.new(1, 1, 1)
puntajeLabel.Font = Enum.Font.GothamBold
puntajeLabel.TextSize = 24
puntajeLabel.TextStrokeTransparency = 0.5
puntajeLabel.Parent = scoreFrame

-- Función para actualizar el panel de puntaje
local function actualizarPanelPuntaje()
	local stats = player:FindFirstChild("leaderstats")
	if not stats then return end
	
	local puntos = stats:FindFirstChild("Puntos")
	local estrellas = stats:FindFirstChild("Estrellas")
	local dinero = stats:FindFirstChild("Money") or stats:FindFirstChild("Dinero")
	
	if puntos then
		puntajeLabel.Text = puntos.Value .. " / 1200 pts"
	end
	
	local eVal = 0
	if estrellas then
		local numEstrellas = estrellas.Value
		eVal = numEstrellas
		local textoEstrellas = ""
		
		for i = 1, 3 do
			if i <= numEstrellas then
				textoEstrellas = textoEstrellas .. "⭐"
			else
				textoEstrellas = textoEstrellas .. "☆"
			end
		end
		
		estrellaLabel.Text = textoEstrellas
	end
	
	-- Actualizar Label Principal (HUD) "⭐ 0 | 💰 0 pts"
	if lblPuntaje then
		local pVal = puntos and puntos.Value or 0
		local dVal = dinero and dinero.Value or 0
		-- Mostramos Estrellas y Puntos (o Dinero si prefieres)
		-- Asumimos Puntos ya que dice 'pts'
		lblPuntaje.Text = "⭐ " .. eVal .. " | 💰 " .. pVal .. " pts"
	end
end

-- Escuchar cambios en Puntos y Estrellas
task.spawn(function()
	local stats = player:WaitForChild("leaderstats", 10)
	if stats then
		local puntos = stats:WaitForChild("Puntos", 5)
		local estrellas = stats:WaitForChild("Estrellas", 5)
		local dinero = stats:WaitForChild("Money", 5) or stats:WaitForChild("Dinero", 5)
		
		if puntos then
			puntos.Changed:Connect(actualizarPanelPuntaje)
		end
		
		if estrellas then
			estrellas.Changed:Connect(actualizarPanelPuntaje)
		end
		
		if dinero then
			dinero.Changed:Connect(actualizarPanelPuntaje)
		end
		
		actualizarPanelPuntaje() -- Actualizar inicial
	end
end)

-- Evento Misión
local eventoMision = Remotes:WaitForChild("ActualizarMision", 5) 

-- Estado de misiones (para persistir entre abrir/cerrar mapa)
local estadoMisiones = {false, false, false, false, false, false, false, false}

if eventoMision then
	eventoMision.OnClientEvent:Connect(function(indiceMision, completada)
		print("🎯 Cliente recibió actualización Misión " .. indiceMision .. ": " .. tostring(completada))
		
		-- Actualizar estado local
		estadoMisiones[indiceMision] = completada
		
		-- Si el mapa está abierto, actualizar visualmente
		if not misionFrame.Visible then 
			print("⚠️ Mapa cerrado, guardando estado para cuando se abra")
			return 
		end
		
		-- Buscar la etiqueta correspondiente
		local labels = {}
		for _, child in ipairs(misionFrame:GetChildren()) do
			if child:IsA("TextLabel") and child.Name ~= "Titulo" then
				table.insert(labels, child)
			end
		end
		
		if labels[indiceMision] then
			local lbl = labels[indiceMision]
			
			-- Solo actualizar si no está ya marcada
			if not string.find(lbl.Text, "✅") then
				lbl.TextColor3 = Color3.fromRGB(46, 204, 113) -- Verde Éxito
				lbl.TextTransparency = 0.3
				lbl.Text = "✅ " .. lbl.Text
				print("✅ Misión " .. indiceMision .. " marcada visualmente")
			end
		else
			warn("⚠️ No se encontró label para misión " .. indiceMision)
		end
	end)
end

-- Evento de Inventario (Desbloquear botones)
if eventoInventario then
	eventoInventario.OnClientEvent:Connect(function(objetoID, tiene)
		print("🎒 Cliente Inventario Update: " .. objetoID .. " = " .. tostring(tiene))

		if objetoID == "Mapa" then
			tieneMapa = tiene
			btnMapa.Visible = tiene and (not enMenu)
			
			if tiene then
				-- Animación de notificación
				local notif = Instance.new("TextLabel")
				notif.Size = UDim2.new(0, 300, 0, 50)
				notif.Position = UDim2.new(0.5, -150, 0.2, 0)
				notif.Text = "¡Mapa Desbloqueado!"
				notif.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
				notif.TextColor3 = Color3.new(1,1,1)
				notif.Font = Enum.Font.FredokaOne
				notif.TextSize = 24
				notif.Parent = screenGui
				
				game.Debris:AddItem(notif, 3)
			end
			
		elseif objetoID == "Tablet" or objetoID == "Algoritmo_BFS" or objetoID == "Algoritmo_Dijkstra" then
			tieneAlgo = tiene
			btnAlgo.Visible = tiene and (not enMenu)
			
			if tiene then
				-- Animación notificación
				local notif = Instance.new("TextLabel")
				notif.Size = UDim2.new(0, 300, 0, 50)
				notif.Position = UDim2.new(0.5, -150, 0.2, 60) -- Un poco más abajo
				notif.Text = "¡Manual Algoritmo Obtenido!"
				notif.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
				notif.TextColor3 = Color3.new(1,1,1)
				notif.Font = Enum.Font.FredokaOne
				notif.TextSize = 24
				notif.Parent = screenGui
				
				game.Debris:AddItem(notif, 3)
			end
		end
	end)
end

-- Función etiquetas (Usando Part Invisible para máxima fiabilidad)
local function mostrarEtiquetasNodos(mostrar)
	if not mostrar then
		for _, obj in ipairs(etiquetasNodos) do 
			if obj.PartAncla then obj.PartAncla:Destroy() end -- Destruir parte física
			if obj.Gui then obj.Gui:Destroy() end -- Destruir GUI
		end
		etiquetasNodos = {}
		return
	end
	
	local nivelID = player:FindFirstChild("leaderstats") and player.leaderstats.Nivel.Value or 0
	local config = LevelsConfig[nivelID] or LevelsConfig[0]
	local nivelModel = workspace:FindFirstChild(config.Modelo)
	if not nivelModel and workspace:FindFirstChild("Nivel" .. nivelID) then
		nivelModel = workspace:FindFirstChild("Nivel" .. nivelID)
	end
	
	local postesFolder = nivelModel and nivelModel:FindFirstChild("Objetos") and nivelModel.Objetos:FindFirstChild("Postes")
	
	-- Configuración de Nombres Amigables (Si existiera en config, aquí se leería)
	-- local alias = config.NombresNodos or {} 
	
	if postesFolder then
		for _, poste in ipairs(postesFolder:GetChildren()) do
			if poste:IsA("Model") then
				-- Encontrar centro
				local centroPos = poste:GetPivot().Position
				if poste.PrimaryPart then centroPos = poste.PrimaryPart.Position end
				
				-- 1. Crear Parte Invisible (Ancla)
				local parteAncla = Instance.new("Part")
				parteAncla.Name = "EtiquetaAncla_" .. poste.Name
				parteAncla.Size = Vector3.new(1,1,1)
				parteAncla.Transparency = 1
				parteAncla.Anchored = true
				parteAncla.CanCollide = false
				parteAncla.Position = centroPos + Vector3.new(0, 8, 0) -- 8 Studs arriba del centro
				parteAncla.Parent = workspace -- Workspace directo para evitar problemas de jerarquía
				
				-- 2. Crear Billboard
				local bb = Instance.new("BillboardGui")
				bb.Name = "EtiquetaGui"
				bb.Size = UDim2.new(0, 200, 0, 80)
				bb.StudsOffset = Vector3.new(0, 2, 0)
				bb.AlwaysOnTop = true
				bb.Parent = parteAncla -- Hijo de la parte en workspace
				
				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(1,0,1,0)
				lbl.BackgroundTransparency = 1
				-- Usar alias si existe, sino nombre del poste
				lbl.Text = poste.Name 
				lbl.TextColor3 = Color3.new(1, 1, 1)
				lbl.TextStrokeTransparency = 0
				lbl.Font = Enum.Font.FredokaOne
				lbl.TextSize = 25 -- GRANDE
				lbl.Parent = bb
				
				-- Guardar referencias para limpieza y logica
				table.insert(etiquetasNodos, {PartAncla = parteAncla, Gui = bb, PosteRef = poste})
			end
		end
	else
		warn("⚠️ No se encontró carpeta de postes")
	end
end

-- ⚠️ ZOOM DESHABILITADO para evitar crashes
-- Si quieres habilitar zoom, cambia zoomBloqueado = false arriba
UserInputService.InputChanged:Connect(function(input, gameProcessed)
	if mapaActivo and input.UserInputType == Enum.UserInputType.MouseWheel and not zoomBloqueado then
		-- Zoom habilitado (actualmente deshabilitado)
		zoomLevel = zoomLevel - (input.Position.Z * 10)
		zoomLevel = math.clamp(zoomLevel, 70, 100) -- Rango más seguro
	end
end)

-- Restaurar visuales de un selector a su estado normal (Invisible)
local function restaurarSelector(selector)
	if not selector then return end
	selector.Transparency = 1 -- Volver a ser invisible
	selector.Color = Color3.fromRGB(196, 196, 196)
	selector.Material = Enum.Material.Plastic -- Restaurar material
	
	local origSize = selector:GetAttribute("OriginalSize")
	if origSize then selector.Size = origSize end
end

-- ============================================
-- TOGGLE MISIONES (Declaración temprana)
-- ============================================

local toggleMisiones  -- Declaración forward

-- ============================================
-- TOGGLE MAPA
-- ============================================
local function toggleMapa()
	-- A. Cerrar misiones si está abierto (evitar conflicto)
	if misionesActivo then
		toggleMisiones()
	end
	
	mapaActivo = not mapaActivo
	
	-- Detectar datos del nivel actual
	local nivelID = player:FindFirstChild("leaderstats") and player.leaderstats.Nivel.Value or 0
	local config = LevelsConfig[nivelID] or LevelsConfig[0]
	local nombreInicio = config.NodoInicio 
	local nombreFin = config.NodoFin
	local listaMisiones = config.Misiones or {"¡Conecta la red eléctrica!"}
	
	local nivelModel = workspace:FindFirstChild(config.Modelo)
	-- Fallback
	if not nivelModel and workspace:FindFirstChild("Nivel" .. nivelID) then
		nivelModel = workspace:FindFirstChild("Nivel" .. nivelID)
	end
	
	local techosFolder = nivelModel and nivelModel:FindFirstChild("Techos")
	local postesFolder = nivelModel and nivelModel:FindFirstChild("Objetos") and nivelModel.Objetos:FindFirstChild("Postes")
	
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	
	-- Función para crear efecto "Rayos X" en cables
	-- Visualización de cables ("Rayos X") ELIMINADA por causar artefactos verticales


	if mapaActivo then
		-- A. ACTIVAR
		camera.CameraType = Enum.CameraType.Scriptable
		btnMapa.Text = "CERRAR MAPA"
		btnMapa.BackgroundColor3 = Color3.fromRGB(46, 204, 113) 
		-- flechaNav.Visible = true -- ELIMINADO
		-- distanciaLabel.Visible = true -- ELIMINADO

		
		-- Mostrar panel de puntaje
		scoreFrame.Visible = true
		actualizarPanelPuntaje()
		
		-- Activar visión de cables "Rayos X" (ELIMINADO)

		
		-- ⚡ PERMITIR MOVIMIENTO: No anclar al jugador
		-- (Comentado para permitir movimiento durante el mapa)
		-- if root then
		-- 	root.Anchored = true
		-- end
		
		-- Mostrar Misión (Limpiar y Llenar)
		misionFrame.Visible = true
		for _, child in ipairs(misionFrame:GetChildren()) do
			if child:IsA("TextLabel") and child ~= tituloMision then child:Destroy() end
		end
		
		for i, misionConfig in ipairs(listaMisiones) do
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, -10, 0, 25)
			lbl.BackgroundTransparency = 1
			
			-- Extraer texto (soporta objetos y strings)
			local texto
			if type(misionConfig) == "table" then
				texto = misionConfig.Texto or "Misión sin texto"
			else
				texto = tostring(misionConfig)
			end
			
			-- Aplicar estado guardado
			if estadoMisiones[i] then
				lbl.Text = "✅ " .. texto
				lbl.TextColor3 = Color3.fromRGB(46, 204, 113)
				lbl.TextTransparency = 0.3
			else
				lbl.Text = "  " .. texto
				lbl.TextColor3 = Color3.new(1,1,1)
				lbl.TextTransparency = 0
			end
			
			lbl.Font = Enum.Font.GothamMedium
			lbl.TextSize = 14
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.TextWrapped = true
			lbl.AutomaticSize = Enum.AutomaticSize.Y -- Ajustar altura automáticamente
			lbl.Parent = misionFrame
		end
		
		mostrarEtiquetasNodos(true)
		
		-- Transparentar Techos
		if techosFolder then
			table.clear(techoOriginalTransparency)
			for _, techo in ipairs(techosFolder:GetChildren()) do
				if techo:IsA("BasePart") then
					techoOriginalTransparency[techo] = techo.Transparency
					techo.Transparency = 0.95
					techo.CastShadow = false
				end
			end
		end
		
		-- Loop Render
		camaraConnection = RunService.RenderStepped:Connect(function()
			if root and player.Character then
				local centro = root.Position
				
				-- Actualizar Cámara
				camera.CFrame = CFrame.new(centro + Vector3.new(0, zoomLevel, 0), centro)
				
				-- Variables para Flecha
				local objetivoNav = nil
				local distMin = math.huge
				
				if postesFolder then
					for _, poste in ipairs(postesFolder:GetChildren()) do
						if poste:IsA("Model") then
							local selector = poste:FindFirstChild("Selector")
							local distPlayer = (poste:GetPivot().Position - centro).Magnitude
							local distMetros = math.floor(distPlayer / 5)
							
							-- Gestionar Selectores
							if selector and selector:IsA("BasePart") then
								
								-- HACER VISIBLE
								selector.Transparency = 0
								
								local energizado = poste:GetAttribute("Energizado")
								local esInicio = (poste.Name == nombreInicio)
								local esFin = (poste.Name == nombreFin)
								
								-- 1. NODO INICIO (Azul Neon)
								if esInicio then
									selector.Color = Color3.fromRGB(52, 152, 219) -- Azul
									selector.Material = Enum.Material.Neon
									
								-- 2. NO ENERGIZADO (Rojo Neon + Grande)
								elseif energizado ~= true then -- nil or false
									selector.Color = Color3.fromRGB(231, 76, 60) -- Rojo mate
									selector.Material = Enum.Material.Neon
									
									-- Guardar tamaño original si no existe
									if not selector:GetAttribute("OriginalSize") then
										selector:SetAttribute("OriginalSize", selector.Size)
									end
									
									-- Aumentar tamaño levemente
									local origSize = selector:GetAttribute("OriginalSize")
									if origSize then selector.Size = origSize * 1.3 end
									
									-- Candidato a navegación (Buscamos errores)
									if distPlayer < distMin then
										distMin = distPlayer
										objetivoNav = poste
									end
									
								-- 3. ENERGIZADO (Verde Plastic)
								else
									selector.Color = Color3.fromRGB(46, 204, 113) -- Verde
									selector.Material = Enum.Material.Plastic
									
									local origSize = selector:GetAttribute("OriginalSize")
									if origSize then selector.Size = origSize end
								end
							end
							
							-- Actualizar Etiquetas de Distancia y Meta
							for _, objEtiqueta in ipairs(etiquetasNodos) do
								-- Comprobar si esta etiqueta pertenece al poste actual
								local esEstePoste = false
								if objEtiqueta.PosteRef == poste then
									esEstePoste = true
								elseif not objEtiqueta.PosteRef and objEtiqueta.PartAncla then
									-- Fallback por nombre si falla ref
									if string.find(objEtiqueta.PartAncla.Name, poste.Name) then
										esEstePoste = true
									end
								end
								
								if esEstePoste then
									local gui = objEtiqueta.Gui
									
									-- Nombre Personalizado
									local nombreMostrar = poste.Name
									if config.NombresPostes and config.NombresPostes[poste.Name] then
										nombreMostrar = config.NombresPostes[poste.Name]
									end
									
									local lblNombre = gui:FindFirstChild("TextLabel")
									if lblNombre and lblNombre.Text ~= nombreMostrar then
										lblNombre.Text = nombreMostrar
									end
									
									-- Cartel META
									if esFin then
										local lblMeta = gui:FindFirstChild("MetaLbl")
										if not lblMeta then
											lblMeta = Instance.new("TextLabel")
											lblMeta.Name = "MetaLbl"
											lblMeta.Size = UDim2.new(1,0,0.5,0)
											lblMeta.Position = UDim2.new(0,0,-0.8,0)
											lblMeta.BackgroundTransparency = 1
											lblMeta.Text = "🚩 META"
											lblMeta.TextColor3 = Color3.new(1, 0.5, 0)
											lblMeta.TextStrokeTransparency = 0
											lblMeta.Font = Enum.Font.FredokaOne
											lblMeta.TextSize = 22
											lblMeta.Parent = gui
										end
									end
									
									local lblDist = gui:FindFirstChild("DistanciaLbl")
									if not lblDist then
										lblDist = Instance.new("TextLabel")
										lblDist.Name = "DistanciaLbl"
										lblDist.Size = UDim2.new(1,0,0.5,0)
										lblDist.Position = UDim2.new(0,0,1,-5)
										lblDist.BackgroundTransparency = 1
										lblDist.Font = Enum.Font.FredokaOne
										lblDist.TextSize = 16
										lblDist.TextStrokeTransparency = 0
										lblDist.Parent = gui
									end
									
									local esEnergizado = poste:GetAttribute("Energizado")
									if esEnergizado == true and poste.Name ~= nombreInicio then
										lblDist.Visible = false
									else
										lblDist.Visible = false -- ⚠️ OCULTO: No mostrar metros en postes
										lblDist.Text = distMetros .. "m"
										lblDist.TextColor3 = (poste.Name == nombreInicio) and Color3.new(0,1,1) or Color3.new(1, 0.2, 0.2)
									end
								end
							end
						end
					end
				end
				
				-- Actualizar Flecha y Distancia (ELIMINADO)
				-- if objetivoNav then
					-- flechaNav.Visible = true
					-- distanciaLabel.Visible = true
					-- flechaNav.ImageColor3 = Color3.fromRGB(255, 80, 80) -- Flecha Roja
					
					-- local diff = objetivoNav:GetPivot().Position - centro
					-- local angle = math.atan2(diff.X, diff.Z)
					-- flechaNav.Rotation = -math.deg(angle) + 180
					
					-- distanciaLabel.Text = "Reparar: " .. math.floor(distMin / 5) .. "m"
				-- else
					-- flechaNav.Visible = false
					-- distanciaLabel.Text = "⚡ RED COMPLETADA"
					-- distanciaLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
				-- end
			end
		end)
		
	else
		-- B. DESACTIVAR
		camera.CameraType = Enum.CameraType.Custom
		btnMapa.Text = "🗺️ MAPA"
		btnMapa.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
		-- flechaNav.Visible = false -- ELIMINADO

		
		-- Ocultar panel de puntaje
		scoreFrame.Visible = false
		
		-- Limpiar visión de cables (ELIMINADO)

		
		-- ⚡ DESANCLAR AL JUGADOR (Comentado porque ya no anclamos)
		-- if root then
		-- 	root.Anchored = false
		-- end
		distanciaLabel.Visible = false -- Mantener oculto

		misionFrame.Visible = false
		
		mostrarEtiquetasNodos(false)
		
		if camaraConnection then 
			camaraConnection:Disconnect() 
			camaraConnection = nil
		end
		
		-- Restaurar Techos
		if techosFolder then
			for techo, tr in pairs(techoOriginalTransparency) do
				if techo and techo.Parent then
					techo.Transparency = tr
					techo.CastShadow = true
				end
			end
		end
		
		-- Restaurar Selectores (Invisibles y sin Highlight)
		if postesFolder then
			for _, poste in ipairs(postesFolder:GetChildren()) do
				local selector = poste:FindFirstChild("Selector")
				if selector then
					restaurarSelector(selector)
					if selector:FindFirstChild("AlertaVisual") then
						selector.AlertaVisual:Destroy()
					end
				end
			end
		end
	end
end

-- ============================================
-- TOGGLE MISIONES (Implementación)
-- ============================================

toggleMisiones = function()
	-- A. Cerrar mapa si está abierto (evitar conflicto)
	if mapaActivo then
		toggleMapa()
	end
	
	misionesActivo = not misionesActivo
	
	if misionesActivo then
		-- Mostrar panel de misiones
		local nivelID = player:FindFirstChild("leaderstats") and player.leaderstats.Nivel.Value or 0
		local config = LevelsConfig[nivelID] or LevelsConfig[0]
		local listaMisiones = config.Misiones or {"¡Conecta la red eléctrica!"}
		
		misionFrame.Visible = true
		btnMisiones.Text = "✅ CERRAR"
		btnMisiones.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
		
		-- Limpiar y llenar misiones
		for _, child in ipairs(misionFrame:GetChildren()) do
			if child:IsA("TextLabel") and child ~= tituloMision then child:Destroy() end
		end
		
		for i, misionConfig in ipairs(listaMisiones) do
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, -10, 0, 25)
			lbl.BackgroundTransparency = 1
			
			-- Extraer texto (soporta objetos y strings)
			local texto
			if type(misionConfig) == "table" then
				texto = misionConfig.Texto or "Misión sin texto"
			else
				texto = tostring(misionConfig)
			end
			
			-- Aplicar estado guardado
			if estadoMisiones[i] then
				lbl.Text = "✅ " .. texto
				lbl.TextColor3 = Color3.fromRGB(46, 204, 113)
				lbl.TextTransparency = 0.3
			else
				lbl.Text = "  " .. texto
				lbl.TextColor3 = Color3.new(1,1,1)
				lbl.TextTransparency = 0
			end
			
			lbl.Font = Enum.Font.GothamMedium
			lbl.TextSize = 14
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.TextWrapped = true
			lbl.AutomaticSize = Enum.AutomaticSize.Y
			lbl.Parent = misionFrame
		end
	else
		-- Ocultar panel
		misionFrame.Visible = false
		btnMisiones.Text = "📋 MISIONES"
		btnMisiones.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
	end
end

-- ============================================
-- VIEW MATRIX LOGIC
-- ============================================

local matrixFrame = Instance.new("Frame")
matrixFrame.Name = "MatrixFrame"
matrixFrame.Size = UDim2.new(0, 600, 0, 450)
matrixFrame.Position = UDim2.new(0.5, -300, 0.5, -225)
matrixFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
matrixFrame.BackgroundTransparency = 0.1
matrixFrame.Visible = false
matrixFrame.Parent = screenGui

local cornerMat = Instance.new("UICorner"); cornerMat.CornerRadius = UDim.new(0, 12); cornerMat.Parent = matrixFrame

-- Titulo Matrix
local titleMat = Instance.new("TextLabel")
titleMat.Size = UDim2.new(1, 0, 0, 40)
titleMat.BackgroundTransparency = 1
titleMat.Text = "🔢 MATRIZ DE ADYACENCIA"
titleMat.TextColor3 = Color3.fromRGB(255, 159, 67)
titleMat.Font = Enum.Font.GothamBlack
titleMat.TextSize = 24
titleMat.Parent = matrixFrame

local closeMat = Instance.new("TextButton")
closeMat.Size = UDim2.new(0, 30, 0, 30)
closeMat.Position = UDim2.new(1, -40, 0, 5)
closeMat.Text = "X"
closeMat.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
closeMat.TextColor3 = Color3.new(1,1,1)
closeMat.Parent = matrixFrame
local cornerC = Instance.new("UICorner"); cornerC.CornerRadius = UDim.new(0, 8); cornerC.Parent = closeMat

closeMat.MouseButton1Click:Connect(function() matrixFrame.Visible = false end)

-- Scroll para la Grid
local scrollMat = Instance.new("ScrollingFrame")
scrollMat.Size = UDim2.new(1, -40, 1, -60)
scrollMat.Position = UDim2.new(0, 20, 0, 50)
scrollMat.BackgroundTransparency = 1
scrollMat.CanvasSize = UDim2.new(2, 0, 2, 0) -- Expandable
scrollMat.Parent = matrixFrame

local getMatrixFunc = Remotes:WaitForChild("GetAdjacencyMatrix", 5)

local function drawMatrix()
	if not getMatrixFunc then return end
	
	-- Limpiar
	scrollMat:ClearAllChildren()
	
	local nivelID = player:FindFirstChild("leaderstats") and player.leaderstats.Nivel.Value or 0
	local data = getMatrixFunc:InvokeServer(nivelID)
	
	if not data or not data.Matrix then return end
	
	local headers = data.Headers
	local matrix = data.Matrix
	local cellWidth = 80
	local cellHeight = 40
	
	-- 1. Cabecera Filas (Top)
	for col, name in ipairs(headers) do
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(0, cellWidth, 0, cellHeight)
		lbl.Position = UDim2.new(0, cellWidth * col, 0, 0) -- Shifted by 1 cell for corner
		lbl.Text = name:sub(1, 8) -- Truncate
		lbl.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		lbl.TextColor3 = Color3.new(1,1,1)
		lbl.BorderSizePixel = 1
		lbl.BorderColor3 = Color3.new(0,0,0)
		lbl.Parent = scrollMat
	end
	
	-- 2. Filas de datos
	for row, name in ipairs(headers) do
		-- Cabecera Columna (Left)
		local lblHeader = Instance.new("TextLabel")
		lblHeader.Size = UDim2.new(0, cellWidth, 0, cellHeight)
		lblHeader.Position = UDim2.new(0, 0, 0, cellHeight * row)
		lblHeader.Text = name:sub(1, 8)
		lblHeader.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		lblHeader.TextColor3 = Color3.new(1,1,1)
		lblHeader.BorderSizePixel = 1
		lblHeader.BorderColor3 = Color3.new(0,0,0)
		lblHeader.Parent = scrollMat
		
		-- Celdas
		for col, val in ipairs(matrix[row]) do
			local cell = Instance.new("TextLabel")
			cell.Size = UDim2.new(0, cellWidth, 0, cellHeight)
			cell.Position = UDim2.new(0, cellWidth * col, 0, cellHeight * row)
			
			if val == 0 then
				cell.Text = "0"
				cell.TextColor3 = Color3.fromRGB(150, 150, 150)
			else
				cell.Text = tostring(val)
				cell.TextColor3 = Color3.fromRGB(46, 204, 113) -- Verde si hay conexión
				cell.Font = Enum.Font.GothamBold
			end
			
			cell.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			cell.BorderSizePixel = 1
			cell.BorderColor3 = Color3.new(0.2,0.2,0.2)
			cell.Parent = scrollMat
		end
	end
	
	scrollMat.CanvasSize = UDim2.new(0, (#headers + 1) * cellWidth, 0, (#headers + 1) * cellHeight)
end

btnMatriz.MouseButton1Click:Connect(function()
	matrixFrame.Visible = not matrixFrame.Visible
	if matrixFrame.Visible then
		drawMatrix()
	end
end)

-- === LISTENERS ===
btnMapa.MouseButton1Click:Connect(toggleMapa)
btnMisiones.MouseButton1Click:Connect(toggleMisiones)

btnReiniciar.MouseButton1Click:Connect(function()
	if eventoReiniciar then 
		eventoReiniciar:FireServer() 
		if mapaActivo then toggleMapa() end -- Cerrar mapa al reiniciar
		if misionesActivo then toggleMisiones() end -- Cerrar misiones al reiniciar
	end
end)

-- Actualizar texto botón Algoritmo
task.spawn(function()
	while true do
		task.wait(1)
		if player:FindFirstChild("leaderstats") then
			local nivelID = player.leaderstats.Nivel.Value
			local config = LevelsConfig[nivelID]
			if config and config.Algoritmo then
				btnAlgo.Text = "🧠 EJECUTAR " .. config.Algoritmo
			else
				btnAlgo.Text = "🧠 EJECUTAR DIJKSTRA"
			end
		end
	end
end)

btnAlgo.MouseButton1Click:Connect(function()
	local nivelID = player:FindFirstChild("leaderstats") and player.leaderstats.Nivel.Value or 0
	local config = LevelsConfig[nivelID] or LevelsConfig[0]
	local algoName = config.Algoritmo or "Dijkstra"
	
	print("Enviando petición algoritmo: " .. algoName .. " para Nivel: " .. nivelID)
	
	-- Ocultar botón finalizar si estaba visible
	btnFinalizar.Visible = false
	
	-- Unificamos todos los algoritmos bajo un solo evento maestro
	if eventoAlgo then
		local inicio = config.NodoInicio or "PostePanel"
		local fin = config.NodoFin or "PosteFinal"
		
		eventoAlgo:FireServer(algoName, inicio, fin, nivelID)
		print("🧠 Solicitando algoritmo: " .. algoName)
	end
end)

-- ============================================
-- BOTÓN FINALIZAR NIVEL
-- ============================================
btnFinalizar.MouseButton1Click:Connect(function()
	local nivelID = player:FindFirstChild("leaderstats") and player.leaderstats.Nivel.Value or 0
	local stats = player:FindFirstChild("leaderstats")
	local estrellas = stats and stats:FindFirstChild("Estrellas") and stats.Estrellas.Value or 0
	local puntos = stats and stats:FindFirstChild("Puntos") and stats.Puntos.Value or 0
	
	print("🏆 Finalizando nivel " .. nivelID)
	
	-- Disparar evento de nivel completado
	local LevelCompletedEvent = Remotes:FindFirstChild("LevelCompleted")
	if LevelCompletedEvent then
		LevelCompletedEvent:FireServer(nivelID, estrellas, puntos)
		btnFinalizar.Visible = false -- Ocultar para evitar doble click
	else
		warn("❌ Evento LevelCompleted no encontrado")
	end
end)

-- Listener: Mostrar botón después de validación
task.spawn(function()
	local messageSub
	messageSub = game:GetService("LogService").MessageOut:Connect(function(message, messageType)
		-- Detectar mensaje de validación completa
		if message:find("Algoritmo completado") or message:find("💰 BONUS NETO:") then
			task.wait(1) -- Pequeña espera
			if not enMenu then -- Solo mostrar si estamos en gameplay
				btnFinalizar.Visible = true
				print("🏆 Botón Finalizar activado")
			end
		end
	end)
end)

-- ============================================
-- ACTUALIZAR LABEL DE PUNTAJE
-- ============================================
task.spawn(function()
	local function actualizarLabelPuntaje()
		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats then return end
		
		local estrellas = leaderstats:FindFirstChild("Estrellas")
		local puntos = leaderstats:FindFirstChild("Puntos")
		
		local txtEstrellas = estrellas and estrellas.Value or 0
		local txtPuntos = puntos and puntos.Value or 0
		
		lblPuntaje.Text = string.format("⭐ %d | 💰 %d pts", txtEstrellas, txtPuntos)
	end
	
	-- Actualizar inicialmente
	task.wait(1)
	actualizarLabelPuntaje()
	
	-- Monitorear cambios
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if leaderstats then
		local estrellas = leaderstats:FindFirstChild("Estrellas")
		local puntos = leaderstats:FindFirstChild("Puntos")
		
		if estrellas then
			estrellas:GetPropertyChangedSignal("Value"):Connect(actualizarLabelPuntaje)
		end
		
		if puntos then
			puntos:GetPropertyChangedSignal("Value"):Connect(actualizarLabelPuntaje)
		end
	end
end)

print("✅ ClienteUI V3 Cargado: Funcionalidad completa de Mapa yAlgoritmos")

-- ============================================
-- 🔄 RECUPERAR INVENTARIO (Persistencia al cambiar nivel)
-- ============================================
task.spawn(function()
	task.wait(2) -- Esperar a que todo cargue
	local funcGetInv = Remotes:WaitForChild("GetInventory", 5)
	if funcGetInv then
		print("🎒 Solicitando inventario persistente...")
		local inventario = funcGetInv:InvokeServer()
		
		if inventario then
			for itemID, _ in pairs(inventario) do
				print("   - Recuperado: " .. itemID)
				
				if itemID == "Mapa" then
					tieneMapa = true
				elseif itemID == "Tablet" or itemID == "Algoritmo_BFS" or itemID == "Algoritmo_Dijkstra" then
					tieneAlgo = true
				end
			end
			-- Sincronizar UI con el estado recuperado
			actualizarVisibilidadUI(enMenu)
		end
	end
end)

