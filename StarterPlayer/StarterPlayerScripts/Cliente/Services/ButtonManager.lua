-- ================================================================
-- ButtonManager.lua
-- Gestiona acciones de botones
-- ================================================================

local ButtonManager = {}
ButtonManager.__index = ButtonManager

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Dependencias
local MapManager = nil
local MissionsManager = nil
local LevelsConfig = nil
local player = Players.LocalPlayer

-- Referencias de UI
local btnReiniciar = nil
local btnMapa = nil
local btnAlgo = nil
local btnMisiones = nil
local btnMatriz = nil
local btnFinalizar = nil

-- ================================================================
-- INICIALIZACIÓN
-- ================================================================

--- Inyecta referencias y dependencias
function ButtonManager.initialize(screenGui, deps)
	MapManager = deps.MapManager
	MissionsManager = deps.MissionsManager
	LevelsConfig = deps.LevelsConfig

	-- Obtener referencias a botones
	btnReiniciar = screenGui:WaitForChild("BtnReiniciar", 5)
	btnMapa = screenGui:WaitForChild("BtnMapa", 5)
	btnAlgo = screenGui:WaitForChild("BtnAlgo", 5)
	btnMisiones = screenGui:WaitForChild("BtnMisiones", 5)
	btnMatriz = screenGui:WaitForChild("BtnMatriz", 5)
	btnFinalizar = screenGui:WaitForChild("BtnFinalizar", 5)

	print("✅ ButtonManager: Inicializado")
end

--- Conecta listeners a todos los botones
function ButtonManager:init()
	if btnReiniciar then
		btnReiniciar.MouseButton1Click:Connect(function()
			self:_onReiniciarClick()
		end)
	end

	if btnMapa then
		btnMapa.MouseButton1Click:Connect(function()
			MapManager:toggle()
		end)
	end

	if btnAlgo then
		btnAlgo.MouseButton1Click:Connect(function()
			self:_onAlgoClick()
		end)
	end

	if btnMisiones then
		btnMisiones.MouseButton1Click:Connect(function()
			MissionsManager:toggle()
		end)
	end

	if btnMatriz then
		btnMatriz.MouseButton1Click:Connect(function()
			self:_onMatrizClick()
		end)
	end

	if btnFinalizar then
		btnFinalizar.MouseButton1Click:Connect(function()
			self:_onFinalizarClick()
		end)
	end

	print("✅ ButtonManager: Botones conectados")
end

--- Maneja clic en botón Reiniciar
function ButtonManager:_onReiniciarClick()
	local Remotes = ReplicatedStorage:FindFirstChild("Events")
		and ReplicatedStorage.Events:FindFirstChild("Remotes")

	if not Remotes then
		warn("❌ Remotes no encontrado")
		return
	end

	local eventoReinicio = Remotes:FindFirstChild("ReiniciarNivel")
	if not eventoReinicio then
		warn("❌ Evento ReiniciarNivel no encontrado")
		return
	end

	btnReiniciar.Text = "⏳ ..."
	eventoReinicio:FireServer()

	task.wait(1)
	btnReiniciar.Text = "🔄 REINICIAR"

	print("🔄 Reinicio solicitado")
end

--- Maneja clic en botón Algoritmo
function ButtonManager:_onAlgoClick()
	local Remotes = ReplicatedStorage:FindFirstChild("Events")
		and ReplicatedStorage.Events:FindFirstChild("Remotes")

	if not Remotes then
		warn("❌ Remotes no encontrado")
		return
	end

	local eventoAlgo = Remotes:FindFirstChild("EjecutarAlgoritmo")
	if not eventoAlgo then
		warn("❌ Evento EjecutarAlgoritmo no encontrado")
		return
	end

	-- Obtener datos del nivel
	local nivelID = player:GetAttribute("CurrentLevelID") or 0
	local config = LevelsConfig[nivelID]

	if not config then
		warn("⚠️ No hay configuración para nivel " .. nivelID)
		return
	end

	local algoritmo = config.Algoritmo or "BFS"
	local nodoInicio = config.NodoInicio
	local nodoFin = config.NodoFin

	if not nodoInicio or not nodoFin then
		warn("⚠️ Nodos no definidos para nivel " .. nivelID)
		return
	end

	print("🧠 Ejecutando " .. algoritmo .. " (" .. nodoInicio .. " -> " .. nodoFin .. ")")
	eventoAlgo:FireServer(algoritmo, nodoInicio, nodoFin, nivelID)
end

--- Maneja clic en botón Matriz
function ButtonManager:_onMatrizClick()
	print("🔢 Matriz de Adyacencia solicitada")
	-- Implementar visualización de matriz cuando sea necesario
end

--- Maneja clic en botón Finalizar
function ButtonManager:_onFinalizarClick()
	print("🏆 Nivel finalizado")
	-- Implementar lógica de finalización
end

return ButtonManager