-- StarterPlayer/StarterPlayerScripts/Cliente/Services/VictoryScreenManager.lua
-- Muestra la pantalla de resultados tras completar un nivel.
-- Se activa cuando AudioClient notifica que la Fanfare terminó.

local VictoryScreenManager = {}
VictoryScreenManager.__index = VictoryScreenManager

local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local gui             = nil
local pantallaVictoria = nil
local audioClient     = nil
local lastNivelID     = nil

-- ============================================
-- UTILIDADES
-- ============================================

local function formatTiempo(segundos)
	local m = math.floor(segundos / 60)
	local s = segundos % 60
	return string.format("%d:%02d", m, s)
end

local function formatPuntos(n)
	local s = tostring(math.floor(n))
	local resultado = ""
	local contador  = 0
	for i = #s, 1, -1 do
		if contador > 0 and contador % 3 == 0 then
			resultado = "," .. resultado
		end
		resultado = s:sub(i, i) .. resultado
		contador = contador + 1
	end
	return resultado
end

-- ============================================
-- INICIALIZACIÓN
-- ============================================

function VictoryScreenManager.initialize(guiRef, deps)
	gui         = guiRef
	audioClient = deps.AudioClient

	pantallaVictoria = gui:FindFirstChild("PantallaVictoria")
	if not pantallaVictoria then
		warn("⚠️ VictoryScreenManager: Frame 'PantallaVictoria' no encontrado en GUIExplorador. Créalo en Studio.")
		return
	end

	pantallaVictoria.Visible = false
	VictoryScreenManager:_conectarBotones()
	print("✅ VictoryScreenManager: Inicializado")
end

-- ============================================
-- FUNCIONES PÚBLICAS
-- ============================================

function VictoryScreenManager:mostrar(stats)
	if not pantallaVictoria then
		warn("⚠️ VictoryScreenManager: PantallaVictoria no disponible (¿se creó en Studio?)")
		return
	end

	lastNivelID = stats and stats.nivelID

	-- Poblar estadísticas
	local contenedor = pantallaVictoria:FindFirstChild("ContenedorPrincipal")
	if contenedor then
		local estadFrame = contenedor:FindFirstChild("EstadisticasFrame")
		if estadFrame then
			local filaTiempo   = estadFrame:FindFirstChild("FilaTiempo")
			local filaAciertos = estadFrame:FindFirstChild("FilaAciertos")
			local filaErrores  = estadFrame:FindFirstChild("FilaErrores")
			local filaPuntaje  = estadFrame:FindFirstChild("FilaPuntaje")

			if filaTiempo   then filaTiempo.Text   = "Tiempo: "     .. formatTiempo(stats.tiempo   or 0) end
			if filaAciertos then filaAciertos.Text = "Conexiones: " .. tostring(stats.aciertos or 0)    end
			if filaErrores  then filaErrores.Text  = "Errores: "    .. tostring(stats.errores   or 0)   end
			if filaPuntaje  then filaPuntaje.Text  = "Puntaje: "    .. formatPuntos(stats.puntos  or 0) end
		end

		-- Estrellas (espera 3 ImageLabel: Estrella1, Estrella2, Estrella3)
		local estrellasMostrar = contenedor:FindFirstChild("EstrellasMostrar")
		if estrellasMostrar then
			local estrellas = stats.estrellas or 0
			for i = 1, 3 do
				local estrella = estrellasMostrar:FindFirstChild("Estrella" .. i)
				if estrella and estrella:IsA("ImageLabel") then
					estrella.ImageTransparency = i <= estrellas and 0 or 0.7
				end
			end
		end
	end

	-- Mostrar con fade in
	pantallaVictoria.Visible = true
	if pantallaVictoria:IsA("CanvasGroup") then
		pantallaVictoria.GroupTransparency = 1
		TweenService:Create(pantallaVictoria, TweenInfo.new(0.5), { GroupTransparency = 0 }):Play()
	end

	print("🏆 VictoryScreenManager: Pantalla de victoria mostrada")
end

function VictoryScreenManager:ocultar()
	if not pantallaVictoria then return end

	if pantallaVictoria:IsA("CanvasGroup") then
		local tween = TweenService:Create(pantallaVictoria, TweenInfo.new(0.4), { GroupTransparency = 1 })
		tween.Completed:Connect(function()
			pantallaVictoria.Visible = false
		end)
		tween:Play()
	else
		pantallaVictoria.Visible = false
	end
end

-- ============================================
-- BOTONES
-- ============================================

function VictoryScreenManager:_conectarBotones()
	local contenedor  = pantallaVictoria:FindFirstChild("ContenedorPrincipal")
	if not contenedor then return end

	local botonesFrame = contenedor:FindFirstChild("BotonesFrame")
	if not botonesFrame then return end

	-- Botón "Repetir"
	local botonRepetir = botonesFrame:FindFirstChild("BotonRepetir")
	if botonRepetir then
		botonRepetir.MouseButton1Click:Connect(function()
			self:ocultar()

			local Remotes = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes")
			local reiniciarEvent = Remotes:FindFirstChild("ReiniciarNivel")
			if reiniciarEvent then
				reiniciarEvent:FireServer()
			else
				warn("⚠️ VictoryScreenManager: RemoteEvent 'ReiniciarNivel' no encontrado")
			end

			-- Reanudar ambiente
			if audioClient and lastNivelID then
				audioClient:iniciarAmbiente(lastNivelID)
			end
		end)
	end

	-- Botón "Continuar"
	local botonContinuar = botonesFrame:FindFirstChild("BotonContinuar")
	if botonContinuar then
		botonContinuar.MouseButton1Click:Connect(function()
			self:ocultar()

			if audioClient then
				audioClient:detenerTodo()
			end

			local Bindables = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Bindables")
			local openMenuEvent = Bindables:FindFirstChild("OpenMenu")
			if openMenuEvent then
				openMenuEvent:Fire()
			else
				warn("⚠️ VictoryScreenManager: BindableEvent 'OpenMenu' no encontrado")
			end
		end)
	end

	print("✅ VictoryScreenManager: Botones conectados")
end

return VictoryScreenManager
