-- StarterPlayer/StarterPlayerScripts/Cliente/Services/ButtonManager.lua (CORREGIDO v3)
-- FIX: BtnMisiones ahora REALMENTE muestra MisionFrame

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ButtonManager = {}

local screenGui = nil
local MapManager = nil
local MissionsManager = nil
local LevelsConfig = nil

-- Referencias a botones
local btnReiniciar = nil
local btnMapa = nil
local btnAlgo = nil
local btnMisiones = nil
local btnMatriz = nil
local btnFinalizar = nil

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes")
local eventoReiniciar = Remotes:WaitForChild("ReiniciarNivel", 10)
local eventoAlgo = Remotes:WaitForChild("EjecutarAlgoritmo", 10)

-- RemoteFunction para obtener matriz
local getMatrixFunc = Remotes:WaitForChild("GetAdjacencyMatrix", 10)

function ButtonManager.initialize(gui, dependencies)
	screenGui = gui
	MapManager = dependencies.MapManager
	MissionsManager = dependencies.MissionsManager
	LevelsConfig = dependencies.LevelsConfig

	-- 🔥 CORREGIDO: Buscar botones en BarraBotonesMain
	local barraBotones = screenGui:FindFirstChild("BarraBotonesMain")
	if barraBotones then
		btnReiniciar = barraBotones:FindFirstChild("BtnReiniciar")
		btnMapa = barraBotones:FindFirstChild("BtnMapa")
		btnAlgo = barraBotones:FindFirstChild("BtnAlgo")
		btnMisiones = barraBotones:FindFirstChild("BtnMisiones")
		btnMatriz = barraBotones:FindFirstChild("BtnMatriz")
		btnFinalizar = barraBotones:FindFirstChild("BtnFinalizar")

		print("✅ ButtonManager: Botones encontrados en BarraBotonesMain")
	else
		-- Fallback: buscar directamente en screenGui
		btnReiniciar = screenGui:FindFirstChild("BtnReiniciar")
		btnMapa = screenGui:FindFirstChild("BtnMapa")
		btnAlgo = screenGui:FindFirstChild("BtnAlgo")
		btnMisiones = screenGui:FindFirstChild("BtnMisiones")
		btnMatriz = screenGui:FindFirstChild("BtnMatriz")
		btnFinalizar = screenGui:FindFirstChild("BtnFinalizar")

		print("⚠️ ButtonManager: Botones encontrados directamente en GUI (fallback)")
	end

	-- Verificar que al menos encontramos BtnMisiones
	if btnMisiones then
		print("✅ ButtonManager: BtnMisiones encontrado")
	else
		warn("❌ ButtonManager: BtnMisiones NO encontrado - revisar estructura")
	end

	print("✅ ButtonManager: Referencias obtenidas")
end

function ButtonManager:init()
	if not screenGui then
		warn("❌ ButtonManager no inicializado correctamente")
		return
	end

	-- ============================================
	-- BOTÓN REINICIAR
	-- ============================================
	if btnReiniciar then
		btnReiniciar.MouseButton1Click:Connect(function()
			if eventoReiniciar then
				eventoReiniciar:FireServer()
				btnReiniciar.Text = "⏳ ..."
				task.wait(1)
				btnReiniciar.Text = "🔄 REINICIAR"
				print("🔄 Reinicio solicitado")
			end
		end)
	end

	-- ============================================
	-- BOTÓN MAPA
	-- ============================================
	if btnMapa then
		btnMapa.MouseButton1Click:Connect(function()
			if MapManager then
				MapManager:toggle()
				print("🗺️ Toggle mapa")
			end
		end)
	end

	-- ============================================
	-- BOTÓN ALGORITMO
	-- ============================================
	if btnAlgo then
		btnAlgo.MouseButton1Click:Connect(function()
			local player = Players.LocalPlayer
			local nivelID = player:GetAttribute("CurrentLevelID")

			if not nivelID or nivelID == -1 then
				nivelID = player:FindFirstChild("leaderstats") and player.leaderstats.Nivel.Value or 0
			end

			local config = LevelsConfig[nivelID]
			if not config then
				warn("⚠️ No hay configuración para Nivel " .. tostring(nivelID))
				return
			end

			local algoritmo = config.Algoritmo or "BFS"
			local nodoInicio = config.NodoInicio
			local nodoFin = config.NodoFin

			if not nodoInicio or not nodoFin then
				warn("⚠️ Nivel " .. nivelID .. " no tiene NodoInicio o NodoFin definidos")
				return
			end

			print("🧠 Cliente solicitando algoritmo: " .. algoritmo .. " (" .. nodoInicio .. " -> " .. nodoFin .. ")")
			eventoAlgo:FireServer(algoritmo, nodoInicio, nodoFin, nivelID)
		end)
	end

	-- ============================================
	-- 🔥 BOTÓN MISIONES (VERSIÓN 3 - AHORA FUNCIONA)
	-- ============================================
	if btnMisiones then
		btnMisiones.MouseButton1Click:Connect(function()
			print("📋 ===== BtnMisiones CLICKEADO =====")
			print("📋 MissionsManager disponible: " .. tostring(MissionsManager ~= nil))

			if MissionsManager then
				print("📋 Llamando a MissionsManager:toggle()")
				local ok, err = pcall(function()
					MissionsManager:toggle()
				end)

				if ok then
					print("✅ MissionsManager:toggle() ejecutado exitosamente")
				else
					print("❌ Error en MissionsManager:toggle(): " .. tostring(err))
				end
			else
				warn("❌ MissionsManager NO disponible")
				print("   Tipo de valor: " .. type(MissionsManager))
				print("   Referencia nula: " .. tostring(MissionsManager == nil))
			end
		end)
		print("✅ ButtonManager: Listener de BtnMisiones conectado")
	else
		warn("❌ ButtonManager: BtnMisiones NO ENCONTRADO - no se puede conectar listener")
	end

	-- ============================================
	-- BOTÓN MATRIZ
	-- ============================================
	if btnMatriz then
		btnMatriz.MouseButton1Click:Connect(function()
			print("🔢 Matriz de Adyacencia solicitada")

			if not getMatrixFunc then
				warn("❌ RemoteFunction GetAdjacencyMatrix no encontrada")
				return
			end

			-- Cambiar apariencia del botón mientras carga
			btnMatriz.Text = "⏳ Cargando..."
			btnMatriz.BackgroundColor3 = Color3.fromRGB(127, 140, 141)

			-- Invocar servidor
			local success, resultado = pcall(function()
				return getMatrixFunc:InvokeServer()
			end)

			-- Restaurar botón
			btnMatriz.Text = "🔢 MATRIZ"
			btnMatriz.BackgroundColor3 = Color3.fromRGB(255, 159, 67)

			if success and resultado then
				print("✅ Matriz recibida del servidor:")
				print("   Nodos:", table.concat(resultado.Headers, ", "))

				-- MOSTRAR MATRIZ EN UI
				mostrarMatrizUI(resultado)
			else
				warn("❌ Error obteniendo matriz:", resultado)
			end
		end)
	end

	-- ============================================
	-- BOTÓN FINALIZAR
	-- ============================================
	if btnFinalizar then
		btnFinalizar.MouseButton1Click:Connect(function()
			print("🏆 Finalizar nivel solicitado")
		end)
	end

	print("✅ ButtonManager: Todos los listeners conectados")
end

-- ============================================
-- FUNCIÓN: MOSTRAR MATRIZ EN UI
-- ============================================
function mostrarMatrizUI(data)
	-- Buscar o crear GUI de matriz
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	-- Limpiar matriz anterior si existe
	local matrizGui = playerGui:FindFirstChild("MatrizGUI")
	if matrizGui then
		matrizGui:Destroy()
	end

	-- Crear nueva GUI
	matrizGui = Instance.new("ScreenGui")
	matrizGui.Name = "MatrizGUI"
	matrizGui.ResetOnSpawn = false
	matrizGui.Parent = playerGui

	-- Frame principal
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MatrizFrame"
	mainFrame.Size = UDim2.new(0, 600, 0, 500)
	mainFrame.Position = UDim2.new(0.5, -300, 0.5, -250)
	mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	mainFrame.BackgroundTransparency = 0.1
	mainFrame.Parent = matrizGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = mainFrame

	-- Título
	local titulo = Instance.new("TextLabel")
	titulo.Name = "Titulo"
	titulo.Size = UDim2.new(1, 0, 0, 50)
	titulo.Position = UDim2.new(0, 0, 0, 0)
	titulo.BackgroundTransparency = 1
	titulo.Text = "📊 MATRIZ DE ADYACENCIA"
	titulo.TextColor3 = Color3.fromRGB(255, 215, 0)
	titulo.Font = Enum.Font.FredokaOne
	titulo.TextSize = 24
	titulo.Parent = mainFrame

	-- Botón cerrar
	local btnCerrar = Instance.new("TextButton")
	btnCerrar.Name = "BtnCerrar"
	btnCerrar.Size = UDim2.new(0, 40, 0, 40)
	btnCerrar.Position = UDim2.new(1, -45, 0, 5)
	btnCerrar.Text = "✕"
	btnCerrar.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
	btnCerrar.TextColor3 = Color3.new(1, 1, 1)
	btnCerrar.Font = Enum.Font.GothamBold
	btnCerrar.TextSize = 24
	btnCerrar.Parent = mainFrame

	local cornerBtn = Instance.new("UICorner")
	cornerBtn.CornerRadius = UDim.new(0, 8)
	cornerBtn.Parent = btnCerrar

	btnCerrar.MouseButton1Click:Connect(function()
		matrizGui:Destroy()
	end)

	-- ScrollingFrame para la matriz
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "MatrizScroll"
	scrollFrame.Size = UDim2.new(1, -20, 1, -70)
	scrollFrame.Position = UDim2.new(0, 10, 0, 60)
	scrollFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	scrollFrame.BackgroundTransparency = 0.3
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 8
	scrollFrame.Parent = mainFrame

	local cornerScroll = Instance.new("UICorner")
	cornerScroll.CornerRadius = UDim.new(0, 8)
	cornerScroll.Parent = scrollFrame

	-- Crear tabla
	local headers = data.Headers
	local matrix = data.Matrix
	local cellSize = 60
	local padding = 5

	-- Calcular tamaño total
	local totalWidth = (#headers + 1) * (cellSize + padding)
	local totalHeight = (#headers + 1) * (cellSize + padding)

	scrollFrame.CanvasSize = UDim2.new(0, totalWidth, 0, totalHeight)

	-- Celda vacía esquina superior izquierda
	crearCelda(scrollFrame, "", 0, 0, cellSize, Color3.fromRGB(60, 60, 60), true)

	-- Headers horizontales
	for i, nodeName in ipairs(headers) do
		crearCelda(scrollFrame, nodeName, i, 0, cellSize, Color3.fromRGB(52, 152, 219), true)
	end

	-- Headers verticales + datos
	for i, nodeName in ipairs(headers) do
		-- Header vertical
		crearCelda(scrollFrame, nodeName, 0, i, cellSize, Color3.fromRGB(52, 152, 219), true)

		-- Datos de la matriz
		for j, value in ipairs(matrix[i]) do
			local color = Color3.fromRGB(50, 50, 50)
			local texto = tostring(value)

			-- Colorear según valor
			if value > 0 then
				color = Color3.fromRGB(46, 204, 113) -- Verde (conectado)
			end

			crearCelda(scrollFrame, texto, j, i, cellSize, color, false)
		end
	end

	print("✅ Matriz UI creada con " .. #headers .. " nodos")
end

-- Helper para crear celdas de la matriz
function crearCelda(parent, texto, x, y, size, color, esHeader)
	local cellSize = size
	local padding = 5

	local cell = Instance.new("TextLabel")
	cell.Name = "Cell_" .. x .. "_" .. y
	cell.Size = UDim2.new(0, cellSize, 0, cellSize)
	cell.Position = UDim2.new(0, x * (cellSize + padding), 0, y * (cellSize + padding))
	cell.BackgroundColor3 = color
	cell.BackgroundTransparency = 0
	cell.BorderSizePixel = 0
	cell.Text = texto
	cell.TextColor3 = Color3.new(1, 1, 1)
	cell.Font = esHeader and Enum.Font.GothamBold or Enum.Font.Gotham
	cell.TextSize = esHeader and 14 or 16
	cell.TextScaled = true
	cell.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = cell

	-- Stroke para definición
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Color = Color3.fromRGB(70, 70, 70)
	stroke.Transparency = 0.5
	stroke.Parent = cell
end

return ButtonManager