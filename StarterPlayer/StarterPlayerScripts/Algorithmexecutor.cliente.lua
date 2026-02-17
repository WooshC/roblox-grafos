-- ================================================================
-- AlgorithmExecutor.client.lua
-- Maneja la ejecución de algoritmos y botón de finalización
-- ================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:WaitForChild("GUIExplorador")

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes")
local ejecutarAlgoEvent = Remotes:WaitForChild("EjecutarAlgoritmo")
local LevelCompletedEvent = Remotes:FindFirstChild("LevelCompleted")

-- LevelsConfig
local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))

-- Estado
local algorithmRunning = false
local btnFinalizar = nil 
local btnAlgo = nil

-- Función para buscar botones recursivamente o en rutas específicas
local function actualizarReferenciasGui()
	if not screenGui then return end
	
	-- Buscar BtnFinalizar en su ruta correcta
	local barraSup = screenGui:FindFirstChild("BarraSuperior")
	local barraSec = barraSup and barraSup:FindFirstChild("BarraBotonesSecundarios")
	btnFinalizar = barraSec and barraSec:FindFirstChild("BtnFinalizar")
	
	-- Buscar BtnAlgoritmo en su ruta correcta
	local barraMain = screenGui:FindFirstChild("BarraBotonesMain")
	btnAlgo = barraMain and barraMain:FindFirstChild("BtnAlgoritmo")
end

-- Intentar buscar referencias iniciales
actualizarReferenciasGui()

-- ================================================================
-- FUNCIÓN: Finalizar Nivel
-- ================================================================

local function finalizarNivel()
	if not btnFinalizar then actualizarReferenciasGui() end
	if not btnFinalizar then return end

	local nivelID = player:GetAttribute("CurrentLevelID") or 0
	local config = LevelsConfig[nivelID]

	if not config then return end

	-- 🔥 CALCULAR PUNTAJE Y ESTRELLAS
	local stats = player:FindFirstChild("leaderstats")
	local puntos = stats and stats:FindFirstChild("Puntos")
	local puntosActuales = puntos and puntos.Value or 0

	-- Calcular estrellas basado en puntaje
	local estrellas = 1
	local thresholds = config.Puntuacion or {}

	if puntosActuales >= (thresholds.TresEstrellas or 1000) then
		estrellas = 3
	elseif puntosActuales >= (thresholds.DosEstrellas or 500) then
		estrellas = 2
	else
		estrellas = 1
	end

	print("🏆 Completando Nivel " .. nivelID)
	print("   Puntos: " .. puntosActuales)
	print("   Estrellas: " .. estrellas)

	-- Ocultar botón
	btnFinalizar.Visible = false
	btnFinalizar.Text = "FINALIZAR"

	-- Notificar al servidor
	if LevelCompletedEvent then
		LevelCompletedEvent:FireServer(nivelID, estrellas, puntosActuales)
		print("✅ Servidor notificado de nivel completado")
	else
		warn("⚠️ LevelCompletedEvent no encontrado")
	end
end

-- ================================================================
-- FUNCIÓN: Mostrar Botón Finalizar
-- ================================================================

local function mostrarBotonFinalizar(algoritmo)
	if not btnFinalizar then actualizarReferenciasGui() end
	
	if not btnFinalizar then
		return
	end

	-- 🔥 CAMBIAR TEXTO SEGÚN ALGORITMO
	local nivelID = player:GetAttribute("CurrentLevelID") or 0
	local config = LevelsConfig[nivelID]
	local nombreAlgo = config and config.Algoritmo or algoritmo or "Algoritmo"

	btnFinalizar.Text = "✅ FINALIZAR (" .. nombreAlgo .. ")"
	btnFinalizar.Visible = true
	btnFinalizar.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
	btnFinalizar.AutoButtonColor = true

	print("✅ Botón FINALIZAR mostrado: (" .. nombreAlgo .. ")")

	-- Conectar evento del botón (solo una vez)
	if not btnFinalizar:GetAttribute("ListenerConnected") then
		btnFinalizar.MouseButton1Click:Connect(function()
			finalizarNivel()
		end)
		btnFinalizar:SetAttribute("ListenerConnected", true)
	end
end

-- ================================================================
-- FUNCIÓN: Ejecutar Algoritmo
-- ================================================================

local function ejecutarAlgoritmo()
	if algorithmRunning then
		print("⚠️ Ya hay un algoritmo ejecutándose")
		return
	end

	local nivelID = player:GetAttribute("CurrentLevelID") or 0
	local config = LevelsConfig[nivelID]

	if not config then
		-- Silencioso en menú principal o niveles sin config
		return
	end

	local algoritmo = config.Algoritmo or "BFS"
	local nodoInicio = config.NodoInicio
	local nodoFin = config.NodoFin

	if not nodoInicio or not nodoFin then
		print("❌ Nodos no definidos para nivel " .. nivelID)
		return
	end

	algorithmRunning = true
	print("🧠 Ejecutando " .. algoritmo .. " (" .. nodoInicio .. " -> " .. nodoFin .. ")")

	-- Cambiar apariencia del botón
	if not btnAlgo then actualizarReferenciasGui() end
	
	if btnAlgo then
		btnAlgo.Text = "⏳ " .. algoritmo .. "..."
		btnAlgo.BackgroundColor3 = Color3.fromRGB(127, 140, 141)
	end

	-- Enviar solicitud al servidor
	ejecutarAlgoEvent:FireServer(algoritmo, nodoInicio, nodoFin, nivelID)

	-- Esperar a que el servidor termine (con timeout de 10 segundos)
	task.wait(10)

	algorithmRunning = false

	-- Restaurar botón
	if btnAlgo then
		btnAlgo.Text = "🧠 " .. algoritmo
		btnAlgo.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
	end

	-- 🔥 MOSTRAR BOTÓN FINALIZAR
	mostrarBotonFinalizar(algoritmo)
end

-- ================================================================
-- CONECTAR BOTÓN ALGORITMO
-- ================================================================

-- Intentar conectar si el botón ya existe
if btnAlgo then
	btnAlgo.MouseButton1Click:Connect(ejecutarAlgoritmo)
	print("✅ AlgorithmExecutor: Conectado a BtnAlgoritmo")
end

-- Escuchar por si se añade el botón después (ej. carga dinámica de GUI)
screenGui.DescendantAdded:Connect(function(descendant)
	if descendant.Name == "BtnAlgoritmo" and descendant:IsA("GuiButton") then
		btnAlgo = descendant
		btnAlgo.MouseButton1Click:Connect(ejecutarAlgoritmo)
		-- print("✅ AlgorithmExecutor: Conectado a BtnAlgoritmo (Dinámico)")
	elseif descendant.Name == "BtnFinalizar" and descendant:IsA("GuiButton") then
		btnFinalizar = descendant
	end
end)

-- ================================================================
-- INICIALIZACIÓN
-- ================================================================

-- Solo imprimimos si estamos en un contexto relevante, para evitar spam en menú
if player:GetAttribute("CurrentLevelID") then
	print("✅ AlgorithmExecutor listo")
end