-- ============================================
-- ClienteUI v3 - COMPLETAMENTE CORREGIDO
-- ============================================
-- - GUI invisible hasta cargar nivel
-- - Botones funcionan correctamente
-- - Modos se activan sin superposición
-- - Sincronización de puntaje en tiempo real

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))
local Remotes = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes")

print("\n" .. string.rep("═", 60))
print("🎮 INICIANDO CLIENTEUI v3")
print(string.rep("═", 60) .. "\n")

-- ==========================================
-- ESPERAR Y VALIDAR GUI
-- ==========================================
print("⏳ Esperando GUI...")
local gui
local attempts = 0

while not _G.UnifiedGUI and attempts < 100 do
	task.wait(0.1)
	attempts = attempts + 1
end

if not _G.UnifiedGUI then
	warn("❌ GUI no se cargó después de 10 segundos")
	return
end

gui = _G.UnifiedGUI
print("✅ GUI cargada correctamente")
print("   - GUI.Enabled = " .. tostring(gui.GUI.Enabled))

-- ==========================================
-- REFERENCIAS RÁPIDAS
-- ==========================================
local buttons = gui.Buttons
local labels = gui.Labels
local ModeManager = gui.ModeManager
local screenGui = gui.GUI

-- ==========================================
-- GESTOR DE VISIBILIDAD
-- ==========================================
local VisibilityManager = {}

function VisibilityManager:show()
	screenGui.Enabled = true
	print("👁️ GUI VISIBLE")
end

function VisibilityManager:hide()
	screenGui.Enabled = false
	print("🙈 GUI INVISIBLE")
end

function VisibilityManager:toggle()
	screenGui.Enabled = not screenGui.Enabled
	if screenGui.Enabled then
		print("👁️ GUI VISIBLE")
	else
		print("🙈 GUI INVISIBLE")
	end
end

-- ==========================================
-- SISTEMA DE PUNTAJE
-- ==========================================
local ScoreSystem = {}

function ScoreSystem:updateUI()
	local stats = player:FindFirstChild("leaderstats")
	if not stats then return end
	
	local puntos = stats:FindFirstChild("Puntos")
	local estrellas = stats:FindFirstChild("Estrellas")
	
	if puntos then
		labels.PointsValue.Text = tostring(puntos.Value)
	end
	
	if estrellas then
		labels.StarsValue.Text = estrellas.Value .. "/3"
	end
end

function ScoreSystem:init()
	task.spawn(function()
		print("\n📊 Inicializando Sistema de Puntaje...")
		
		local stats = player:WaitForChild("leaderstats", 10)
		if not stats then
			warn("❌ leaderstats no encontrado")
			return
		end
		
		local puntos = stats:WaitForChild("Puntos", 5)
		local estrellas = stats:WaitForChild("Estrellas", 5)
		
		-- Actualizar inicial
		ScoreSystem:updateUI()
		
		-- Escuchar cambios
		if puntos then
			puntos.Changed:Connect(function()
				ScoreSystem:updateUI()
				print("📈 Puntos actualizados: " .. puntos.Value)
			end)
		end
		
		if estrellas then
			estrellas.Changed:Connect(function()
				ScoreSystem:updateUI()
				print("⭐ Estrellas actualizadas: " .. estrellas.Value .. "/3")
			end)
		end
		
		print("✅ Sistema de puntaje activo y escuchando cambios")
	end)
end

-- ==========================================
-- SISTEMA DE BOTONES
-- ==========================================
local ButtonSystem = {}

function ButtonSystem:connectBtnAlgo()
	buttons.BtnAlgo.MouseButton1Click:Connect(function()
		print("\n⚡ BtnAlgo presionado")
		
		local nivelID = player:GetAttribute("CurrentLevelID") or 0
		local config = LevelsConfig[nivelID]
		
		if not config then
			warn("❌ No hay configuración para nivel " .. nivelID)
			return
		end
		
		local ejecutarAlgoEvent = Remotes:WaitForChild("EjecutarAlgoritmo")
		local algoritmo = config.Algoritmo or "BFS"
		
		print("   🚀 Ejecutando " .. algoritmo)
		buttons.BtnAlgo.Text = "⏳ ..."
		
		ejecutarAlgoEvent:FireServer(algoritmo, config.NodoInicio, config.NodoFin, nivelID)
		
		task.wait(10)
		buttons.BtnAlgo.Text = "⚡ Algoritmo"
		
		-- Mostrar botón finalizar
		buttons.BtnFinalizar.Visible = true
		print("   ✅ Botón Finalizar visible")
	end)
	print("✅ BtnAlgo conectado")
end

function ButtonSystem:connectBtnFinalizar()
	buttons.BtnFinalizar.MouseButton1Click:Connect(function()
		print("\n✅ BtnFinalizar presionado")
		
		local nivelID = player:GetAttribute("CurrentLevelID") or 0
		local stats = player:FindFirstChild("leaderstats")
		local puntos = stats and stats:FindFirstChild("Puntos")
		local estrellas = stats and stats:FindFirstChild("Estrellas")
		
		print("   🏆 Completando Nivel " .. nivelID)
		print("   📊 Puntos: " .. (puntos and puntos.Value or 0))
		print("   ⭐ Estrellas: " .. (estrellas and estrellas.Value or 0) .. "/3")
		
		local LevelCompletedEvent = Remotes:FindFirstChild("LevelCompleted")
		if LevelCompletedEvent then
			LevelCompletedEvent:FireServer(
				nivelID,
				estrellas and estrellas.Value or 0,
				puntos and puntos.Value or 0
			)
			buttons.BtnFinalizar.Visible = false
			print("   ✅ Evento enviado al servidor")
		end
	end)
	print("✅ BtnFinalizar conectado")
end

function ButtonSystem:connectBtnReiniciar()
	buttons.BtnReiniciar.MouseButton1Click:Connect(function()
		print("\n🔄 BtnReiniciar presionado")
		
		local reiniciarEvent = Remotes:WaitForChild("ReiniciarNivel")
		buttons.BtnReiniciar.Text = "⏳ ..."
		
		reiniciarEvent:FireServer()
		print("   ✅ Evento enviado al servidor")
		
		task.wait(1)
		buttons.BtnReiniciar.Text = "🔄 Reiniciar"
		buttons.BtnFinalizar.Visible = false
	end)
	print("✅ BtnReiniciar conectado")
end

function ButtonSystem:connectBtnMapa()
	buttons.BtnMapa.MouseButton1Click:Connect(function()
		print("\n🗺️ BtnMapa presionado")
		
		local toggleMapEvent = Remotes:FindFirstChild("ToggleMap")
		if toggleMapEvent then
			toggleMapEvent:FireServer()
			print("   ✅ Evento enviado al servidor")
		else
			warn("   ⚠️ ToggleMap no encontrado")
		end
	end)
	print("✅ BtnMapa conectado")
end

function ButtonSystem:connectBtnMisiones()
	buttons.BtnMisiones.MouseButton1Click:Connect(function()
		print("\n📋 BtnMisiones presionado")
		
		local toggleMisionsEvent = Remotes:FindFirstChild("ToggleMissions")
		if toggleMisionsEvent then
			toggleMisionsEvent:FireServer()
			print("   ✅ Evento enviado al servidor")
		else
			warn("   ⚠️ ToggleMissions no encontrado")
		end
	end)
	print("✅ BtnMisiones conectado")
end

function ButtonSystem:connectBtnMatriz()
	buttons.BtnMatriz.MouseButton1Click:Connect(function()
		print("\n🔢 BtnMatriz presionado")
		print("   📊 Cambiando a modo Matriz...")
		ModeManager:SwitchMode("MATRIZ")
	end)
	print("✅ BtnMatriz conectado")
end

function ButtonSystem:connectAll()
	print("\n🔌 Conectando botones...")
	self:connectBtnAlgo()
	self:connectBtnFinalizar()
	self:connectBtnReiniciar()
	self:connectBtnMapa()
	self:connectBtnMisiones()
	self:connectBtnMatriz()
	print("✅ Todos los botones conectados\n")
end

-- ==========================================
-- EVENTOS DEL SERVIDOR
-- ==========================================
local EventListener = {}

function EventListener:connectUIUpdates()
	local updateUIEvent = Remotes:FindFirstChild("ActualizarUI")
	if not updateUIEvent then 
		print("⚠️ ActualizarUI no encontrado")
		return 
	end
	
	updateUIEvent.OnClientEvent:Connect(function(data)
		if data and data.Type == "AlgorithmCompleted" then
			print("✅ Servidor notifica: Algoritmo completado")
			buttons.BtnFinalizar.Visible = true
		end
	end)
	print("✅ Listener ActualizarUI conectado")
end

function EventListener:connectAll()
	print("📡 Conectando listeners de eventos...")
	self:connectUIUpdates()
end

-- ==========================================
-- GESTOR DE NIVEL
-- ==========================================
local LevelManager = {}

function LevelManager:onLevelLoaded()
	print("\n🎮 NIVEL CARGADO - Mostrando GUI")
	VisibilityManager:show()
	ModeManager:SwitchMode("VISUAL")
	print("✅ GUI en modo VISUAL")
end

function LevelManager:onMenuActive()
	print("\n📋 MENÚ ACTIVO - Ocultando GUI")
	VisibilityManager:hide()
end

function LevelManager:init()
	print("\n🔍 Inicializando Gestor de Nivel...")
	
	-- Escuchar cambios de nivel
	player:GetAttributeChangedSignal("CurrentLevelID"):Connect(function()
		local levelID = player:GetAttribute("CurrentLevelID")
		if levelID and levelID > 0 then
			self:onLevelLoaded()
		else
			self:onMenuActive()
		end
	end)
	
	-- Verificar estado inicial
	local levelID = player:GetAttribute("CurrentLevelID") or 0
	if levelID > 0 then
		self:onLevelLoaded()
	else
		self:onMenuActive()
	end
	
	print("✅ Gestor de Nivel activo")
end

-- ==========================================
-- INICIALIZACIÓN PRINCIPAL
-- ==========================================
print("1️⃣ Paso 1: Sistema de Puntaje")
ScoreSystem:init()

print("2️⃣ Paso 2: Conectar Botones")
ButtonSystem:connectAll()

print("3️⃣ Paso 3: Conectar Eventos")
EventListener:connectAll()

print("4️⃣ Paso 4: Gestor de Nivel")
LevelManager:init()

print(string.rep("═", 60))
print("✅ CLIENTEUI v3 COMPLETAMENTE INICIALIZADO")
print(string.rep("═", 60))

print("\n📚 RESUMEN:")
print("   ⚙️ Sistema de Puntaje: ACTIVO")
print("   🎮 Botones: 6 CONECTADOS")
print("   📡 Eventos: ESCUCHANDO")
print("   🔄 Modos: FUNCIONANDO")
print("   👁️ GUI: INVISIBLE (esperando nivel)")
print("")