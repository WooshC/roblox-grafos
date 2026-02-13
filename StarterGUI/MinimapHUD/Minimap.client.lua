--[[
	MINIMAPA v10 - Cables en carpeta Conexiones
	
	✅ Los cables ahora están en Postes/Conexiones
	✅ Colores automáticos según energización
	✅ Nodos rojos brillantes cuando NO están energizados
	✅ Estructura mucho más limpia y organizada
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))

-- CONFIGURACIÓN
local ZOOM = 80
local TAMANO_MAPA = 250

-- 1. CREAR GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MinimapGUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local marco = Instance.new("Frame")
marco.Name = "MarcoMinimapa"
marco.Size = UDim2.new(0, TAMANO_MAPA, 0, TAMANO_MAPA)
marco.Position = UDim2.new(1, -TAMANO_MAPA - 20, 1, -TAMANO_MAPA - 20)
marco.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
marco.BorderSizePixel = 2
marco.Parent = screenGui

local viewport = Instance.new("ViewportFrame")
viewport.Name = "Vista"
viewport.Size = UDim2.new(1, -6, 1, -6)
viewport.Position = UDim2.new(0.5, 0, 0.5, 0)
viewport.AnchorPoint = Vector2.new(0.5, 0.5)
viewport.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
viewport.BackgroundTransparency = 0
viewport.Ambient = Color3.fromRGB(255, 255, 255)
viewport.LightColor = Color3.fromRGB(255, 255, 255)
viewport.LightDirection = Vector3.new(0, -1, 0)
viewport.Parent = marco

-- Cuadrado del jugador
local cuadrado = Instance.new("Frame")
cuadrado.Name = "Jugador"
cuadrado.Size = UDim2.new(0, 15, 0, 15)
cuadrado.Position = UDim2.new(0.5, 0, 0.5, 0)
cuadrado.AnchorPoint = Vector2.new(0.5, 0.5)
cuadrado.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
cuadrado.BorderSizePixel = 2
cuadrado.BorderColor3 = Color3.fromRGB(0, 0, 0)
cuadrado.ZIndex = 2
cuadrado.Parent = marco

local cornerCuadrado = Instance.new("UICorner")
cornerCuadrado.CornerRadius = UDim.new(0.2, 0)
cornerCuadrado.Parent = cuadrado

-- Cámara
local miniCamera = Instance.new("Camera")
miniCamera.FieldOfView = 70
viewport.CurrentCamera = miniCamera

-- WorldModel
local worldModel = Instance.new("WorldModel")
worldModel.Parent = viewport

-- Referencias
local nivelActualID = nil
local carpetaPostesReal = nil
local mapaSelectores = {}
local listaCables = {}
local listaParticulas = {}
local cantidadCablesAnterior = 0 -- Para evitar spam de logs

-- 2. FUNCIÓN PARA CARGAR SELECTORES
local function cargarSelectores(nivelID)
	print("🗺️ [MINIMAPA] Cargando nivel " .. nivelID)

	worldModel:ClearAllChildren()
	mapaSelectores = {}
	listaCables = {}
	listaParticulas = {}

	local config = LevelsConfig[nivelID]
	if not config then
		warn("⚠️ [MINIMAPA] No existe config para nivel " .. nivelID)
		return
	end

	local nivelModel = Workspace:FindFirstChild(config.Modelo)
	-- FALLBACK: Si no encuentra "Nivel1_Basico", busca "Nivel1"
	if not nivelModel and string.match(config.Modelo, "Nivel(%d+)") then
		local numNivel = string.match(config.Modelo, "Nivel(%d+)")
		nivelModel = Workspace:FindFirstChild("Nivel" .. numNivel)
	end
	
	if not nivelModel then
		warn("⚠️ [MINIMAPA] Modelo no encontrado: " .. config.Modelo)
		return
	end

	carpetaPostesReal = nivelModel:FindFirstChild("Objetos") 
		and nivelModel.Objetos:FindFirstChild("Postes")

	if not carpetaPostesReal then
		carpetaPostesReal = nivelModel:FindFirstChild("Postes", true)
	end

	if not carpetaPostesReal then
		warn("⚠️ [MINIMAPA] No se encontró carpeta Postes")
		return
	end

	print("📦 [MINIMAPA] Clonando selectores de " .. carpetaPostesReal:GetFullName())

	local cantidadClonados = 0
	for _, poste in pairs(carpetaPostesReal:GetChildren()) do
		if poste:IsA("Model") then
			local selectorReal = poste:FindFirstChild("Selector")
			if selectorReal and selectorReal:IsA("BasePart") then
				local selectorClon = selectorReal:Clone()
				selectorClon.Name = poste.Name .. "_Selector"
				selectorClon.CanCollide = false
				selectorClon.Anchored = true
				selectorClon.CastShadow = false

				for _, child in pairs(selectorClon:GetDescendants()) do
					if child:IsA("Script") or child:IsA("LocalScript") then
						child:Destroy()
					end
				end

				selectorClon.Parent = worldModel

				mapaSelectores[poste.Name] = {
					Real = selectorReal,
					Clon = selectorClon,
					Poste = poste
				}

				cantidadClonados = cantidadClonados + 1
			end
		end
	end

	print("✅ [MINIMAPA] Clonados " .. cantidadClonados .. " selectores")
end

-- 3. FUNCIÓN PARA SINCRONIZAR SELECTORES
local function sincronizarSelectores()
	if not carpetaPostesReal then return end

	for nombrePoste, refs in pairs(mapaSelectores) do
		local selectorReal = refs.Real
		local selectorClon = refs.Clon
		local posteReal = refs.Poste

		if selectorReal and selectorClon and posteReal then
			local energizado = posteReal:GetAttribute("Energizado")
			local nombre = posteReal.Name
			
			-- 🔥 SIEMPRE VISIBLE EN EL MINIMAPA
			selectorClon.Transparency = 0
			selectorClon.Material = Enum.Material.Neon

			-- Lógica de color INDEPENDIENTE del mundo real
			if nombre == "PostePanel" or nombre == "GeneradorCentral" then
				selectorClon.Color = Color3.fromRGB(52, 152, 219) -- Azul (Generador)
			elseif nombre == "PosteFinal" or nombre == "TorreControl" then
				selectorClon.Color = Color3.fromRGB(255, 140, 0) -- Naranja (Destino)
			elseif energizado == true then
				selectorClon.Color = Color3.fromRGB(46, 204, 113) -- Verde (Energizado)
			else
				selectorClon.Color = Color3.fromRGB(231, 76, 60) -- Rojo (Sin energía)
			end
		end
	end
end

-- 4. ✅ FUNCIÓN CORREGIDA PARA CLONAR CABLES (busca en carpeta Conexiones)
local function actualizarCables()
	-- Limpiar cables anteriores
	for _, cable in ipairs(listaCables) do
		if cable and cable.Parent then
			cable:Destroy()
		end
	end
	listaCables = {}

	if not carpetaPostesReal then return end

	-- ✅ BUSCAR en carpeta Conexiones
	local carpetaConexiones = carpetaPostesReal:FindFirstChild("Conexiones")
	if not carpetaConexiones then 
		-- Si no hay carpeta, no hay cables
		return 
	end

	for _, cable in ipairs(carpetaConexiones:GetChildren()) do
		if cable:IsA("RopeConstraint") and cable.Visible then
			local a0 = cable.Attachment0
			local a1 = cable.Attachment1

			if a0 and a1 then
				local part0 = a0.Parent
				local part1 = a1.Parent

				if part0 and part1 then
					local modelA = part0:FindFirstAncestorWhichIsA("Model")
					local modelB = part1:FindFirstAncestorWhichIsA("Model")

					if modelA and modelB and 
						modelA.Parent == carpetaPostesReal and 
						modelB.Parent == carpetaPostesReal then

						-- Buscar selectores clonados
						local refA = mapaSelectores[modelA.Name]
						local refB = mapaSelectores[modelB.Name]

						if refA and refB then
							local selectorClonA = refA.Clon
							local selectorClonB = refB.Clon
							local posteA = refA.Poste
							local posteB = refB.Poste

							-- Crear attachments en los selectores clonados
							local attA = selectorClonA:FindFirstChildOfClass("Attachment")
							if not attA then
								attA = Instance.new("Attachment")
								attA.Parent = selectorClonA
							end

							local attB = selectorClonB:FindFirstChildOfClass("Attachment")
							if not attB then
								attB = Instance.new("Attachment")
								attB.Parent = selectorClonB
							end

							-- Crear cable clonado
							local cableClon = Instance.new("RopeConstraint")
							cableClon.Attachment0 = attA
							cableClon.Attachment1 = attB
							cableClon.Length = (attA.WorldPosition - attB.WorldPosition).Magnitude
							cableClon.Visible = true
							cableClon.Thickness = 0.5

							-- ✅ DETERMINAR COLOR BASADO EN ENERGIZACIÓN
							local energizadoA = posteA:GetAttribute("Energizado")
							local energizadoB = posteB:GetAttribute("Energizado")
							
							if energizadoA == true and energizadoB == true then
								-- Ambos energizados -> verde
								cableClon.Color = BrickColor.new("Lime green")
							else
								-- Al menos uno sin energía -> negro
								cableClon.Color = BrickColor.new("Black")
							end

							cableClon.Parent = worldModel

							table.insert(listaCables, cableClon)
						end
					end
				end
			end
		end
	end

	-- Solo imprimir si cambió la cantidad de cables
	if #listaCables ~= cantidadCablesAnterior then
		print("🔌 [MINIMAPA] Cables actualizados: " .. #listaCables)
		cantidadCablesAnterior = #listaCables
	end
end

-- 5. FUNCIÓN PARA CLONAR PARTÍCULAS
local function actualizarParticulas()
	for _, particula in ipairs(listaParticulas) do
		if particula and particula.Parent then
			particula:Destroy()
		end
	end
	listaParticulas = {}

	if not carpetaPostesReal then return end

	for _, poste in pairs(carpetaPostesReal:GetChildren()) do
		if poste:IsA("Model") then
			for _, obj in ipairs(poste:GetDescendants()) do
				if obj.Name == "TrafficParticle" and obj:IsA("BasePart") then
					local clonParticula = obj:Clone()
					clonParticula.Parent = worldModel
					table.insert(listaParticulas, clonParticula)
				end
			end
		end
	end
end

-- 6. DETECTAR CAMBIO DE NIVEL
player:GetAttributeChangedSignal("CurrentLevelID"):Connect(function()
	local levelID = player:GetAttribute("CurrentLevelID")
	if levelID and levelID >= 0 then
		print("🗺️ [MINIMAPA] Activando para nivel " .. levelID)
		nivelActualID = levelID
		task.wait(1.5)
		cargarSelectores(levelID)
		actualizarCables()
		screenGui.Enabled = true
	else
		print("🗺️ [MINIMAPA] Desactivando")
		screenGui.Enabled = false
		nivelActualID = nil
		carpetaPostesReal = nil
	end
end)

-- Activar si ya está en un nivel
local currentLevel = player:GetAttribute("CurrentLevelID")
if currentLevel and currentLevel >= 0 then
	nivelActualID = currentLevel
	task.wait(1.5)
	cargarSelectores(currentLevel)
	actualizarCables()
	screenGui.Enabled = true
end

-- 7. UPDATE LOOP
local tiempoActualizacionCables = 0
local tiempoActualizacionParticulas = 0

RunService.RenderStepped:Connect(function(dt)
	if not screenGui.Enabled then return end

	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local pos = root.Position

	miniCamera.CFrame = CFrame.new(pos.X, pos.Y + ZOOM, pos.Z) * CFrame.Angles(math.rad(-90), 0, 0)

	sincronizarSelectores()

	tiempoActualizacionCables = tiempoActualizacionCables + dt
	if tiempoActualizacionCables >= 0.3 then
		tiempoActualizacionCables = 0
		actualizarCables()
	end

	tiempoActualizacionParticulas = tiempoActualizacionParticulas + dt
	if tiempoActualizacionParticulas >= 0.5 then
		tiempoActualizacionParticulas = 0
		actualizarParticulas()
	end
end)

print("✅ Minimapa v10 (Cables en Conexiones) Listo")