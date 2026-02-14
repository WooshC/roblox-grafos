-- ClienteUI.client.lua (Frontend Refactorizado V3)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local AliasUtils = require(ReplicatedStorage:WaitForChild("Utilidades"):WaitForChild("AliasUtils"))


local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))

-- Eventos Remotos
-- Eventos Remotos (Estandarizado)
local Events = ReplicatedStorage:WaitForChild("Events")
local Remotes = Events:WaitForChild("Remotes")

local eventoUpdateUI = Remotes:WaitForChild("ActualizarUI")

-- Mantener compatibilidad con InventoryService directo
local eventoInventario = Remotes:WaitForChild("ActualizarInventario", 5) 

-- ============================================
-- 1. CONFIGURACIÓN DE UI E INICIALIZACIÓN
-- ============================================

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


-- (Existing lblPuntaje definition above)

-- Panel de Distancia
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

-- Panel de Misión
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


-- Visibilidad inicial
btnMapa.Visible = false
btnAlgo.Visible = false
btnFinalizar.Visible = false -- Solo aparece después de validación
lblPuntaje.Visible = false -- Se mostrará en gameplay

-- ============================================
-- 2. DETECTOR DE MENÚ (Ocultar UI en menú)
-- ============================================
local mapaActivo = false 
local misionesActivo = false 
local tieneMapa = false -- NUEVO: Estado de posesión
local tieneAlgo = false -- NUEVO: Estado de posesión

local enMenu = true 
local botonesGameplay = {btnReiniciar, btnMapa, btnAlgo, btnMisiones, btnMatriz, btnFinalizar, lblPuntaje}

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
		lblPuntaje.Text = "⭐ " .. eVal .. " | pts " .. pVal .. " pts"
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
end

-- ============================================
-- 3. LISTENER UNIFICADO DE UI (UIService)
-- ============================================

if eventoUpdateUI then
	eventoUpdateUI.OnClientEvent:Connect(function(data)
		if not data or not data.Type then return end
		
		print("🎨 ClienteUI recibido: " .. data.Type)

		if data.Type == "LevelReset" then
			-- Reiniciar estado local
			mapaActivo = false
			misionesActivo = false
			
			-- Limpiar misiones visuales
			estadoMisiones = {false, false, false, false, false, false, false, false}
			
			-- Ocultar paneles
			misionFrame.Visible = false
			scoreFrame.Visible = false
			
			-- Resetear visuales de postes (atributos locales)
			for _, obj in ipairs(workspace:GetDescendants()) do
				if obj:IsA("Model") and obj:GetAttribute("Energizado") then
					obj:SetAttribute("Energizado", nil)
				end
			end
			
			print("🔄 ClienteUI: Reset completado")
			
		elseif data.Type == "Energy" then
			-- Actualizar atributos visuales de postes
			local energizedNodes = data.EnergizedNodes or {}
			
			-- Iterar por los nodos energizados y marcar
			-- Nota: Esto asume que los modelos tienen el mismo nombre que los nodos
			local nivelModel = workspace:FindFirstChild("NivelActual") 
				or workspace:FindFirstChild("Nivel" .. (player:GetAttribute("CurrentLevelID") or 0))
				
			if nivelModel and nivelModel:FindFirstChild("Objetos") then
				local postes = nivelModel.Objetos:FindFirstChild("Postes")
				if postes then
					for _, poste in ipairs(postes:GetChildren()) do
						if energizedNodes[poste.Name] then
							poste:SetAttribute("Energizado", true)
						else
							poste:SetAttribute("Energizado", nil)
						end
					end
				end
			end
			
		elseif data.Type == "Missions" then
			-- Actualizar misiones
			
		elseif data.Type == "Algorithm" then
			-- Estado de algoritmo
			local algo = data.Algoritmo
			local estado = data.Estado
			
			if estado == "started" then
				-- Mostrar notificación nativa
				game:GetService("StarterGui"):SetCore("SendNotification", {
					Title = "Algoritmo";
					Text = "Ejecutando " .. algo .. "...";
					Duration = 3;
				})
			elseif estado == "completed" then
				game:GetService("StarterGui"):SetCore("SendNotification", {
					Title = "Algoritmo";
					Text = algo .. " finalizado.";
					Duration = 3;
				})
			end
		end
	end)
end

-- ============================================
-- 4. EVENTOS ESPECIALES / LEGACY
-- ============================================

-- Evento de Inventario (Directo de InventoryService)
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


-- (Bloques duplicados eliminados: DistanciaLabel, MisionFrame, ScoreFrame, Stats Listeners)


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

-- Bloque inventario legacy eliminado (Manejado arriba)


local function mostrarEtiquetasNodos(mostrar)
	if not mostrar then
		for _, obj in ipairs(etiquetasNodos) do 
			if obj.PartAncla then obj.PartAncla:Destroy() end
			if obj.Gui then obj.Gui:Destroy() end
		end
		etiquetasNodos = {}
		return
	end

	local nivelID = player:FindFirstChild("leaderstats") and player.leaderstats.Nivel.Value or 0
	local config = LevelsConfig[nivelID] or LevelsConfig[0]
	-- 1. Prioridad: NivelActual (Instanciado)
	local nivelModel = workspace:FindFirstChild("NivelActual")

	-- 2. Fallbacks
	if not nivelModel then
		nivelModel = workspace:FindFirstChild(config.Modelo)
	end
	
	if not nivelModel then
		nivelModel = workspace:FindFirstChild("Nivel" .. nivelID) or workspace:FindFirstChild("Nivel" .. nivelID .. "_Tutorial")
	end

	local postesFolder = nivelModel and nivelModel:FindFirstChild("Objetos") and nivelModel.Objetos:FindFirstChild("Postes")

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
				parteAncla.Position = centroPos + Vector3.new(0, 8, 0)
				parteAncla.Parent = workspace

				-- 2. Crear Billboard
				local bb = Instance.new("BillboardGui")
				bb.Name = "EtiquetaGui"
				bb.Size = UDim2.new(0, 200, 0, 80)
				bb.StudsOffset = Vector3.new(0, 2, 0)
				bb.AlwaysOnTop = true
				bb.Parent = parteAncla

				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(1,0,1,0)
				lbl.BackgroundTransparency = 1

				-- ✅ REFACTORIZADO: Usar AliasUtils en lugar de config.NombresPostes
				lbl.Text = AliasUtils.getNodeAlias(nivelID, poste.Name)

				lbl.TextColor3 = Color3.new(1, 1, 1)
				lbl.TextStrokeTransparency = 0
				lbl.Font = Enum.Font.FredokaOne
				lbl.TextSize = 25
				lbl.Parent = bb

				-- Guardar referencias
				table.insert(etiquetasNodos, {PartAncla = parteAncla, Gui = bb, PosteRef = poste})
			end
		end
	else
		warn("⚠️ No se encontró carpeta de postes en: " .. (nivelModel and nivelModel.Name or "NIL"))
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

	-- 1. Prioridad: NivelActual
	local nivelModel = workspace:FindFirstChild("NivelActual")
	
	-- 2. Fallbacks
	if not nivelModel then
		nivelModel = workspace:FindFirstChild(config.Modelo)
	end

	if not nivelModel then
		nivelModel = workspace:FindFirstChild("Nivel" .. nivelID) or workspace:FindFirstChild("Nivel" .. nivelID .. "_Tutorial")
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
									local nombreMostrar = AliasUtils.getNodeAlias(nivelID, poste.Name)
									
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

		-- Ocultar Misión
		misionFrame.Visible = false
		
		mostrarEtiquetasNodos(false)

		if camaraConnection then
			camaraConnection:Disconnect()
			camaraConnection = nil
		end

		-- Restaurar Techos
		if techosFolder then
			for techo, trans in pairs(techoOriginalTransparency) do
				if techo and techo:IsA("BasePart") then
					techo.Transparency = trans
					techo.CastShadow = true
				end
			end
			table.clear(techoOriginalTransparency)
		end

		-- Ocultar Selectores
		if postesFolder then
			for _, poste in ipairs(postesFolder:GetChildren()) do
				if poste:IsA("Model") then
					local selector = poste:FindFirstChild("Selector")
					restaurarSelector(selector)
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
	local nivelID = player:FindFirstChild("leaderstats") and player.leaderstats.Nivel.Value or 0
	local config = LevelsConfig[nivelID] or LevelsConfig[0]
	local listaMisiones = config.Misiones or {"¡Conecta la red eléctrica!"}

	if misionesActivo then
		btnMisiones.BackgroundColor3 = Color3.fromRGB(231, 76, 60) -- Rojo (Cerrar)
		
		misionFrame.Visible = true
		for _, child in ipairs(misionFrame:GetChildren()) do
			if child:IsA("TextLabel") and child ~= tituloMision then child:Destroy() end
		end

		for i, misionConfig in ipairs(listaMisiones) do
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, -10, 0, 25)
			lbl.BackgroundTransparency = 1

			local texto
			if type(misionConfig) == "table" then
				texto = misionConfig.Texto or "Misión sin texto"
			else
				texto = tostring(misionConfig)
			end

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
		btnMisiones.BackgroundColor3 = Color3.fromRGB(46, 204, 113) -- Verde (Abrir)
		misionFrame.Visible = false
	end
end

-- CONEXIONES DE BOTONES
btnReiniciar.MouseButton1Click:Connect(function()
	local evt = Remotes:FindFirstChild("ReiniciarNivel")
	if evt then
		evt:FireServer()
		-- Animación simple de feedback
		btnReiniciar.Text = "⏳ ..."
		wait(1)
		btnReiniciar.Text = "🔄 REINICIAR"
	end
end)

btnMapa.MouseButton1Click:Connect(function()
	toggleMapa()
end)

btnAlgo.MouseButton1Click:Connect(function()
	local eventoAlgo = Remotes:FindFirstChild("EjecutarAlgoritmo")
	if eventoAlgo then
		-- 1. Obtener Nivel Actual
		local nivelID = player:GetAttribute("CurrentLevelID")
		if not nivelID or nivelID == -1 then
			nivelID = player:FindFirstChild("leaderstats") and player.leaderstats.Nivel.Value or 0
		end

		-- 2. Obtener Configuración
		local config = LevelsConfig[nivelID]
		if not config then
			warn("⚠️ No hay configuración para Nivel " .. tostring(nivelID))
			return
		end

		-- 3. Obtener Parámetros
		local algoritmo = config.Algoritmo or "BFS"
		local nodoInicio = config.NodoInicio
		local nodoFin = config.NodoFin

		if not nodoInicio or not nodoFin then
			warn("⚠️ Nivel " .. nivelID .. " no tiene NodoInicio o NodoFin definidos")
			return
		end

		print("🧠 Cliente solicitando algoritmo: " .. algoritmo .. " (" .. nodoInicio .. " -> " .. nodoFin .. ")")

		-- 4. Enviar al Servidor
		eventoAlgo:FireServer(algoritmo, nodoInicio, nodoFin, nivelID)
	else
		warn("❌ No se encontró el evento EjecutarAlgoritmo")
	end
end)

btnMisiones.MouseButton1Click:Connect(function()
	toggleMisiones()
end)

if btnCerrarMapa then
	btnCerrarMapa.MouseButton1Click:Connect(function()
		if mapaActivo then
			toggleMapa()
		elseif misionesActivo then
			toggleMisiones()
		end
	end)
end


btnMatriz.MouseButton1Click:Connect(function()
	print("🔢 Matriz Adyacencia solicitada (Pendiente de implementar UI visual)")
	-- Aquí podrías abrir un Frame con la matriz generada por un RemoteFunction
end)

btnFinalizar.MouseButton1Click:Connect(function()
	-- Lógica de finalizar nivel
	print("🏆 Finalizar nivel solicitado")
end)

print("✅ ClienteUI V3 cargado correctamente")
