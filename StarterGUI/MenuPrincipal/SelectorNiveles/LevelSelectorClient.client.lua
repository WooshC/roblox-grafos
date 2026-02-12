-- LevelSelectorClient.client.lua
-- Controla la lógica del menú de selección de niveles: Bloqueo, Información y Jugar.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Configuración
local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))
local Remotes = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes")
local GetProgressFunc = Remotes:WaitForChild("GetPlayerProgress")
local RequestPlayEvent = Remotes:WaitForChild("RequestPlayLevel")

-- Referencias UI
local SelectorMenu = script.Parent
local BotonesFrame = SelectorMenu:WaitForChild("AjustesFrame") 
local Contenedor = SelectorMenu:WaitForChild("Contenedor") 
local InfoPanel = Contenedor:WaitForChild("InfoNivelPanel") 

-- UI Elements del InfoPanel (Búsqueda Robusta)
local TituloNivel = InfoPanel:WaitForChild("TituloNivel", 5) or InfoPanel:FindFirstChild("Titulo")
if TituloNivel then TituloNivel.TextScaled = true end -- EVITAR DESBORDE DE TEXTO

local ImagenContainer = InfoPanel:WaitForChild("ImagenContainer", 5)
local ImagenNivel = ImagenContainer and (ImagenContainer:FindFirstChild("ImageLabel") or ImagenContainer:FindFirstChild("PreviewImage"))

local DescripcionContainer = InfoPanel:WaitForChild("DescripcionScroll", 5) or InfoPanel:FindFirstChild("DescripcionContainer")
local DescripcionTexto = DescripcionContainer and (DescripcionContainer:FindFirstChild("TextoDesc") or DescripcionContainer:FindFirstChild("DescripcionTexto"))

local BotonJugar = InfoPanel:WaitForChild("BotonJugar", 5)

-- Búsqueda recursiva para Stats (ya que pueden estar dentro de StatsFrame o sueltos)
local PuntajeTexto = InfoPanel:FindFirstChild("Puntaje", true) -- true busca recursivamente
local EstrellasTexto = InfoPanel:FindFirstChild("Estrellas", true)

-- Validaciones de UI urgentes
if not ImagenNivel then warn("⚠️ UI ERROR: No encuentro ImageLabel") end
if not PuntajeTexto then warn("⚠️ UI ERROR: No encuentro label Puntaje") end

-- Configuración Remotos
local Remotes = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes")
local GetProgressFunc = Remotes:WaitForChild("GetPlayerProgress", 10)
local RequestPlayEvent = Remotes:WaitForChild("RequestPlayLevel", 10)

if not GetProgressFunc or not RequestPlayEvent then return end

-- Estado Local
local NivelSeleccionado = nil
local DatosJugador = nil 

-- Colores
local ColorDesbloqueado = Color3.fromRGB(44, 62, 80)
local ColorBloqueado = Color3.fromRGB(149, 165, 166)

-- ============================================
-- FUNCIONES DE UI
-- ============================================

local function ActualizarPanelInfo(levelID)
	local config = LevelsConfig[levelID]
	if not config then return end
	
	NivelSeleccionado = levelID
	
	-- Actualizar Textos e Imagen
	TituloNivel.Text = "NIVEL " .. levelID .. ": " .. string.upper(config.Nombre)
	DescripcionTexto.Text = config.Descripcion or "Sin descripción."
	ImagenNivel.Image = config.ImageId or "rbxassetid://0"
	
	-- Actualizar Stats 
	local data = DatosJugador and DatosJugador.Levels[tostring(levelID)]
	local estrellas = data and data.Stars or 0
	local score = data and data.HighScore or 0
	
	if PuntajeTexto then PuntajeTexto.Text = "Récord: " .. score end
	
	-- Generar string de estrellas (ej: "⭐⭐⭐")
	local estrellasStr = ""
	for i = 1, 3 do
		if i <= estrellas then estrellasStr = estrellasStr .. "⭐" else estrellasStr = estrellasStr .. "☆" end
	end
	
	if EstrellasTexto then EstrellasTexto.Text = estrellasStr end
	BotonJugar.Text = "JUGAR " .. estrellasStr
	
	-- Habilitar botón jugar
	BotonJugar.Visible = true
	BotonJugar.AutoButtonColor = true
	BotonJugar.BackgroundColor3 = Color3.fromRGB(46, 204, 113) 
end

local function BloquearPanel()
	TituloNivel.Text = "SELECCIONA UN NIVEL"
	DescripcionTexto.Text = "Elige un nivel desbloqueado para ver los detalles y comenzar tu misión."
	ImagenNivel.Image = ""
	
	BotonJugar.Visible = false
	
	-- Limpiar basura visual (Valores por defecto)
	if EstrellasTexto then EstrellasTexto.Text = "" end
	if PuntajeTexto then PuntajeTexto.Text = "" end
	
	NivelSeleccionado = nil
end

local function CrearIconoCandado(padre)
	if padre:FindFirstChild("LockIcon") then return end
	
	local icon = Instance.new("TextLabel")
	icon.Name = "LockIcon"
	icon.Parent = padre
	icon.Size = UDim2.new(1, 0, 1, 0)
	icon.BackgroundTransparency = 1
	icon.Text = "🔒" -- Emoji simple, funcional y bonito
	icon.TextSize = 30
	icon.TextColor3 = Color3.fromRGB(50, 50, 50)
	icon.ZIndex = 2
end

local function CargarBotonesNiveles()
	DatosJugador = GetProgressFunc:InvokeServer()
	if not DatosJugador or not DatosJugador.Levels then
		warn("❌ Error obteniendo datos del jugador")
		return
	end
	
	print("📊 Datos recibidos:", DatosJugador.Levels)

	for _, boton in pairs(BotonesFrame:GetChildren()) do
		if boton:IsA("GuiButton") and boton.Name:find("Nivel_") then
			-- Extraer ID del nombre "Nivel_1" -> 1
			local sID = boton.Name:match("Nivel_(%d+)")
			local nID = tonumber(sID)
			
			if nID then
				local nivelData = DatosJugador.Levels[sID]
				local estaDesbloqueado = nivelData and nivelData.Unlocked
				
				-- Reiniciar conexiones previas (simple)
				-- En sistemas complejos usariamos Maid/Janitor, aqui desconectamos al destruir si recargamos
				
				if estaDesbloqueado then
					-- ESTILO DESBLOQUEADO
					boton.BackgroundColor3 = ColorDesbloqueado
					boton.AutoButtonColor = true
					boton.TextTransparency = 0
					if boton:FindFirstChild("LockIcon") then boton.LockIcon:Destroy() end
					
					-- Evento Click Normal
					boton.MouseButton1Click:Connect(function()
						ActualizarPanelInfo(nID)
					end)
				else
					-- ESTILO BLOQUEADO (Pero visible)
					boton.BackgroundColor3 = ColorBloqueado
					boton.AutoButtonColor = true -- Permitir click
					boton.TextTransparency = 0.5 
					CrearIconoCandado(boton)
					
					boton.MouseButton1Click:Connect(function()
						-- Mostrar info del nivel bloqueado
						ActualizarPanelInfo(nID)
						
						-- Desactivar botón jugar explícitamente
						BotonJugar.Visible = true
						BotonJugar.Text = "BLOQUEADO 🔒"
						BotonJugar.BackgroundColor3 = Color3.fromRGB(127, 140, 141) -- Gris
						BotonJugar.AutoButtonColor = false
						
						-- Desconectar evento jugar anterior (la función Jugar chequea NivelSeleccionado, pero aqui prevenimos visualmente)
						-- Un truco simple es cambiar NivelSeleccionado a nil temporalmente al pulsar Jugar si estuviera bloqueado, 
						-- pero mejor controlamos en el evento del boton jugar.
					end)
				end
			end
		end
	end
end

-- ============================================
-- INTERACCIÓN PRINCIPAL
-- ============================================

BotonJugar.MouseButton1Click:Connect(function()
	if NivelSeleccionado ~= nil then
		-- VALIDAR BLOQUEO REAL
		local nivelData = DatosJugador and DatosJugador.Levels[tostring(NivelSeleccionado)]
		if not nivelData or not nivelData.Unlocked then
			print("🔒 Intento de jugar nivel bloqueado")
			BotonJugar.Text = "BLOQUEADO"
			task.wait(1)
			BotonJugar.Text = "Jugar" -- Restaurar texto aunque siga bloqueado visualmente
			return
		end
		
		print("🎮 Solicitando jugar Nivel " .. NivelSeleccionado)
		-- Feedback visual
		BotonJugar.Text = "CARGANDO..."
		BotonJugar.BackgroundColor3 = Color3.fromRGB(127, 140, 141)
		
		RequestPlayEvent:FireServer(NivelSeleccionado)
		
		-- LIBERAR CÁMARA E INICIAR JUEGO
		if _G.StartGame then
			task.wait(0.5) -- Pequeña pausa para sincronizar con el server spawneando
			_G.StartGame()
		else
			warn("❌ _G.StartGame no encontrado en MenuCameraSystem")
		end
	end
end)

-- Cuando se muestre este menú (usamos BotonesFrame como referencia visual ya que la carpeta padre no tiene propiedad Visible)
BotonesFrame:GetPropertyChangedSignal("Visible"):Connect(function()
	if BotonesFrame.Visible then
		-- FORZAR VISIBILIDAD DE CONTENEDORES (Fix por si están ocultos)
		if Contenedor then Contenedor.Visible = true end
		InfoPanel.Visible = true 
		
		BloquearPanel() -- Resetear panel derecho
		task.wait(0.1) -- Pequeño delay para asegurar carga de datos remotos
		CargarBotonesNiveles()
	end
end)

-- Carga inicial si ya está visible
if BotonesFrame.Visible then
	CargarBotonesNiveles()
	BloquearPanel()
end

-- EVENTO NIVEL COMPLETADO (Victory!)
local LevelCompletedEvent = Remotes:WaitForChild("LevelCompleted", 5)
if LevelCompletedEvent then
	LevelCompletedEvent.OnClientEvent:Connect(function(nivelID, estrellas, puntos)
		print("🏆 ¡Nivel " .. nivelID .. " Completado! " .. estrellas .. " Estrellas")
		
		task.wait(2) -- Esperar celebración en juego (si la hay)
		
		-- Volver al selector para mostrar progreso
		local Bindables = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Bindables")
		local OpenMenuEvent = Bindables:FindFirstChild("OpenMenu")
		
		if OpenMenuEvent then
			OpenMenuEvent:Fire()
		else
			warn("❌ Evento OpenMenu no encontrado en Bindables")
		end
	end)
end

print("✅ Selector de Niveles (Cliente) Inicializado correctamente")
