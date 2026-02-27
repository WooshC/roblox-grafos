-- StarterPlayerScripts/Menu/ControladorMenu.client.lua
-- Controlador de la UI de seleccion de niveles

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")

local jugador = Players.LocalPlayer
local playerGui = jugador:WaitForChild("PlayerGui")
local camara = workspace.CurrentCamera

-- Referencias a GUI
local menuGui = playerGui:WaitForChild("EDAQuestMenu")
local framePrincipal = menuGui:WaitForChild("FramePrincipal")
local panelNiveles = framePrincipal:WaitForChild("PanelNiveles")
local plantillaTarjeta = panelNiveles:WaitForChild("PlantillaTarjeta")
plantillaTarjeta.Visible = false

-- Cargar configuracion de niveles
local LevelsConfig = require(RS:WaitForChild("Config"):WaitForChild("LevelsConfig"))

-- Variables de estado
local nivelSeleccionado = nil
local datosProgreso = nil

-- ============================================
-- FUNCIONES UTILES
-- ============================================

local function formatearNumero(num)
	if num >= 1000000 then
		return string.format("%.1fM", num / 1000000)
	elseif num >= 1000 then
		return string.format("%.1fK", num / 1000)
	end
	return tostring(num)
end

local function tween(objeto, propiedades, tiempo, estilo, direccion)
	estilo = estilo or Enum.EasingStyle.Quart
	direccion = direccion or Enum.EasingDirection.Out
	
	local info = TweenInfo.new(tiempo, estilo, direccion)
	local tween = TweenService:Create(objeto, info, propiedades)
	tween:Play()
	return tween
end

-- ============================================
-- CONSTRUCCION DE TARJETAS DESDE CONFIG
-- ============================================

local function crearSeparadorSeccion(nombreSeccion, parent)
	local separador = Instance.new("Frame")
	separador.Name = "Separador_" .. nombreSeccion
	separador.Size = UDim2.new(1, -32, 0, 40)
	separador.BackgroundTransparency = 1
	separador.LayoutOrder = #parent:GetChildren()
	separador.Parent = parent
	
	local lineaIzq = Instance.new("Frame")
	lineaIzq.Name = "LineaIzq"
	lineaIzq.Size = UDim2.new(0.3, 0, 0, 2)
	lineaIzq.Position = UDim2.new(0, 0, 0.5, 0)
	lineaIzq.BackgroundColor3 = Color3.fromRGB(100, 116, 139)
	lineaIzq.BorderSizePixel = 0
	lineaIzq.Parent = separador
	
	local texto = Instance.new("TextLabel")
	texto.Name = "NombreSeccion"
	texto.Size = UDim2.new(0.4, 0, 1, 0)
	texto.Position = UDim2.new(0.3, 0, 0, 0)
	texto.BackgroundTransparency = 1
	texto.Text = nombreSeccion:upper()
	texto.TextColor3 = Color3.fromRGB(148, 163, 184)
	texto.TextSize = 14
	texto.Font = Enum.Font.GothamBold
	texto.Parent = separador
	
	local lineaDer = Instance.new("Frame")
	lineaDer.Name = "LineaDer"
	lineaDer.Size = UDim2.new(0.3, 0, 0, 2)
	lineaDer.Position = UDim2.new(0.7, 0, 0.5, 0)
	lineaDer.BackgroundColor3 = Color3.fromRGB(100, 116, 139)
	lineaDer.BorderSizePixel = 0
	lineaDer.Parent = separador
	
	return separador
end

local function crearTarjetaNivel(idNivel, configNivel, estadoNivel, parent)
	local tarjeta = plantillaTarjeta:Clone()
	tarjeta.Name = "Nivel_" .. idNivel
	tarjeta.Visible = true
	tarjeta.LayoutOrder = idNivel
	
	-- Configurar desde LevelsConfig
	local nombreNivel = tarjeta:FindFirstChild("NombreNivel")
	local descripcion = tarjeta:FindFirstChild("Descripcion")
	local imagen = tarjeta:FindFirstChild("ImagenNivel")
	local tag = tarjeta:FindFirstChild("Tag")
	local algoritmo = tarjeta:FindFirstChild("Algoritmo")
	local estadoFrame = tarjeta:FindFirstChild("Estado")
	
	if nombreNivel then
		nombreNivel.Text = configNivel.Nombre or "Nivel " .. idNivel
	end
	
	if descripcion then
		descripcion.Text = configNivel.DescripcionCorta or ""
	end
	
	if imagen and configNivel.ImageId then
		imagen.Image = configNivel.ImageId
	end
	
	if tag and configNivel.Tag then
		tag.Text = configNivel.Tag
	end
	
	if algoritmo and configNivel.Algoritmo then
		algoritmo.Text = "🧠 " .. configNivel.Algoritmo
	end
	
	-- Estado visual
	if estadoFrame then
		local textoEstado = estadoFrame:FindFirstChild("TextoEstado")
		local iconoEstado = estadoFrame:FindFirstChild("IconoEstado")
		
		if estadoNivel == "completado" then
			estadoFrame.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
			if textoEstado then textoEstado.Text = "COMPLETADO" end
			if iconoEstado then iconoEstado.Text = "✓" end
		elseif estadoNivel == "desbloqueado" then
			estadoFrame.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
			if textoEstado then textoEstado.Text = "JUGAR" end
			if iconoEstado then iconoEstado.Text = "▶" end
		else
			estadoFrame.BackgroundColor3 = Color3.fromRGB(100, 116, 139)
			if textoEstado then textoEstado.Text = "BLOQUEADO" end
			if iconoEstado then iconoEstado.Text = "🔒" end
		end
	end
	
	-- Conceptos (chips)
	local conceptosFrame = tarjeta:FindFirstChild("Conceptos")
	if conceptosFrame and configNivel.Conceptos then
		local plantillaChip = conceptosFrame:FindFirstChild("PlantillaChip")
		if plantillaChip then
			plantillaChip.Visible = false
			for _, concepto in ipairs(configNivel.Conceptos) do
				local chip = plantillaChip:Clone()
				chip.Name = "Chip_" .. concepto
				chip.Text = concepto
				chip.Visible = true
				chip.Parent = conceptosFrame
			end
		end
	end
	
	-- Interaccion
	if estadoNivel ~= "bloqueado" then
		tarjeta.MouseButton1Click:Connect(function()
			nivelSeleccionado = idNivel
			mostrarConfirmacionInicio(idNivel, configNivel)
		end)
		
		tarjeta.MouseEnter:Connect(function()
			tween(tarjeta, {BackgroundColor3 = Color3.fromRGB(51, 65, 85)}, 0.2)
		end)
		
		tarjeta.MouseLeave:Connect(function()
			tween(tarjeta, {BackgroundColor3 = Color3.fromRGB(30, 41, 59)}, 0.2)
		end
	else
		tarjeta.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
		tarjeta.BackgroundTransparency = 0.5
	end
	
	tarjeta.Parent = parent
	return tarjeta
end

-- ============================================
-- CONSTRUIR LISTA DE NIVELES ORDENADA
-- ============================================

local function construirListaNiveles()
	-- Limpiar niveles existentes (excepto plantilla)
	for _, hijo in ipairs(panelNiveles:GetChildren()) do
		if hijo:IsA("GuiObject") and hijo.Name ~= "PlantillaTarjeta" and hijo.Name ~= "UIListLayout" then
			hijo:Destroy()
		end
	end
	
	-- Agrupar por seccion
	local nivelesPorSeccion = {}
	local seccionesOrdenadas = {}
	
	for idNivel, config in pairs(LevelsConfig) do
		if type(idNivel) == "number" then
			local seccion = config.Seccion or "General"
			if not nivelesPorSeccion[seccion] then
				nivelesPorSeccion[seccion] = {}
				table.insert(seccionesOrdenadas, seccion)
			end
			table.insert(nivelesPorSeccion[seccion], {
				id = idNivel,
				config = config
			})
		end
	end
	
	-- Ordenar secciones
	table.sort(seccionesOrdenadas)
	
	-- Ordenar niveles dentro de cada seccion
	for seccion, niveles in pairs(nivelesPorSeccion) do
		table.sort(niveles, function(a, b) return a.id < b.id end)
	end
	
	-- Construir UI
	local ultimaSeccion = nil
	
	for _, seccion in ipairs(seccionesOrdenadas) do
		crearSeparadorSeccion(seccion, panelNiveles)
		
		for _, nivelData in ipairs(nivelesPorSeccion[seccion]) do
			local estado = "bloqueado"
			if datosProgreso then
				if datosProgreso.nivelesCompletados[nivelData.id] then
					estado = "completado"
				elseif nivelData.id == 0 or datosProgreso.nivelesCompletados[nivelData.id - 1] then
					estado = "desbloqueado"
				end
			elseif nivelData.id == 0 then
				estado = "desbloqueado"
			end
			
			crearTarjetaNivel(nivelData.id, nivelData.config, estado, panelNiveles)
		end
	end
end

-- ============================================
-- PANTALLA DE CONFIRMACION
-- ============================================

function mostrarConfirmacionInicio(idNivel, configNivel)
	-- Crear overlay de confirmacion
	local overlay = Instance.new("Frame")
	overlay.Name = "OverlayConfirmacion"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.7
	overlay.Parent = framePrincipal
	
	local panel = Instance.new("Frame")
	panel.Name = "PanelConfirmacion"
	panel.Size = UDim2.new(0, 400, 0, 300)
	panel.Position = UDim2.new(0.5, -200, 0.5, -150)
	panel.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	panel.BorderSizePixel = 0
	panel.Parent = overlay
	
	local esquinas = Instance.new("UICorner")
	esquinas.CornerRadius = UDim.new(0, 12)
	esquinas.Parent = panel
	
	local titulo = Instance.new("TextLabel")
	titulo.Name = "Titulo"
	titulo.Size = UDim2.new(1, -40, 0, 40)
	titulo.Position = UDim2.new(0, 20, 0, 20)
	titulo.BackgroundTransparency = 1
	titulo.Text = "Iniciar: " .. (configNivel.Nombre or "Nivel " .. idNivel)
	titulo.TextColor3 = Color3.fromRGB(255, 255, 255)
	titulo.TextSize = 20
	titulo.Font = Enum.Font.GothamBold
	titulo.TextXAlignment = Enum.TextXAlignment.Left
	titulo.Parent = panel
	
	local descripcion = Instance.new("TextLabel")
	descripcion.Name = "Descripcion"
	descripcion.Size = UDim2.new(1, -40, 0, 60)
	descripcion.Position = UDim2.new(0, 20, 0, 70)
	descripcion.BackgroundTransparency = 1
	descripcion.Text = configNivel.DescripcionCorta or ""
	descripcion.TextColor3 = Color3.fromRGB(148, 163, 184)
	descripcion.TextSize = 16
	descripcion.Font = Enum.Font.Gotham
	descripcion.TextWrapped = true
	descripcion.TextXAlignment = Enum.TextXAlignment.Left
	descripcion.Parent = panel
	
	local btnCancelar = Instance.new("TextButton")
	btnCancelar.Name = "BtnCancelar"
	btnCancelar.Size = UDim2.new(0.45, -10, 0, 50)
	btnCancelar.Position = UDim2.new(0, 20, 1, -70)
	btnCancelar.BackgroundColor3 = Color3.fromRGB(71, 85, 105)
	btnCancelar.Text = "Cancelar"
	btnCancelar.TextColor3 = Color3.fromRGB(255, 255, 255)
	btnCancelar.TextSize = 16
	btnCancelar.Font = Enum.Font.GothamBold
	btnCancelar.Parent = panel
	
	local btnIniciar = Instance.new("TextButton")
	btnIniciar.Name = "BtnIniciar"
	btnIniciar.Size = UDim2.new(0.45, -10, 0, 50)
	btnIniciar.Position = UDim2.new(0.55, 0, 1, -70)
	btnIniciar.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
	btnIniciar.Text = "Iniciar Nivel"
	btnIniciar.TextColor3 = Color3.fromRGB(255, 255, 255)
	btnIniciar.TextSize = 16
	btnIniciar.Font = Enum.Font.GothamBold
	btnIniciar.Parent = panel
	
	-- Animacion de entrada
	panel.Size = UDim2.new(0, 360, 0, 280)
	panel.Position = UDim2.new(0.5, -180, 0.5, -140)
	tween(panel, {Size = UDim2.new(0, 400, 0, 300), Position = UDim2.new(0.5, -200, 0.5, -150)}, 0.3)
	
	-- Eventos
	btnCancelar.MouseButton1Click:Connect(function()
		tween(overlay, {BackgroundTransparency = 1}, 0.2)
		tween(panel, {Position = UDim2.new(0.5, -200, 1, 0)}, 0.3).Completed:Connect(function()
			overlay:Destroy()
		end)
	end)
	
	btnIniciar.MouseButton1Click:Connect(function()
		iniciarNivel(idNivel)
	end)
end

-- ============================================
-- INICIAR NIVEL
-- ============================================

function iniciarNivel(idNivel)
	-- Ocultar menu, mostrar HUD
	menuGui.Enabled = false
	
	local hud = playerGui:FindFirstChild("GUIExploradorV2")
	if hud then
		hud.Enabled = true
	end
	
	-- Notificar al servidor
	local eventos = RS:WaitForChild("EventosGrafosV3")
	local remotos = eventos:WaitForChild("Remotos")
	local iniciarNivelEvento = remotos:FindFirstChild("IniciarNivel")
	
	if iniciarNivelEvento then
		iniciarNivelEvento:FireServer(idNivel)
	end
	
	-- Cambiar camara a gameplay
	camara.CameraType = Enum.CameraType.Custom
end

-- ============================================
-- INICIALIZACION
-- ============================================

local function inicializar()
	-- Configurar camara del menu
	local camaraMenu = workspace:FindFirstChild("CamaraMenu")
	if camaraMenu then
		camara.CameraType = Enum.CameraType.Scriptable
		camara.CFrame = camaraMenu.CFrame
	end
	
	-- Construir lista de niveles
	construirListaNiveles()
	
	print("[ControladorMenu] Inicializado con LevelsConfig")
end

-- Iniciar
inicializar()
