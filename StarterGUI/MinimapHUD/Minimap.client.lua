--[[
	MINIMAPA v6 - ViewportFrame con Sincronización en Tiempo Real
	
	Clona los Selectores de los postes y los mantiene sincronizados
	con el estado real del juego (Energizado, Color, Material).
	Clona cables y partículas desde Workspace.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))

-- CONFIGURACIÓN
local ZOOM = 80 -- Altura de la cámara
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
local mapaSelectores = {} -- { [nombrePoste] = {Real = BasePart, Clon = BasePart} }
local listaCables = {}
local listaParticulas = {}

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
				-- Clonar el selector
				local selectorClon = selectorReal:Clone()
				selectorClon.Name = poste.Name .. "_Selector"
				selectorClon.CanCollide = false
				selectorClon.Anchored = true
				selectorClon.CastShadow = false
				
				-- Limpiar scripts
				for _, child in pairs(selectorClon:GetDescendants()) do
					if child:IsA("Script") or child:IsA("LocalScript") then
						child:Destroy()
					end
				end
				
				selectorClon.Parent = worldModel
				
				-- Guardar referencia
				mapaSelectores[poste.Name] = {
					Real = selectorReal,
					Clon = selectorClon
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
		
		if selectorReal and selectorReal.Parent and selectorClon and selectorClon.Parent then
			-- Sincronizar Color
			if selectorClon.Color ~= selectorReal.Color then
				selectorClon.Color = selectorReal.Color
			end
			
			-- Sincronizar Material
			if selectorClon.Material ~= selectorReal.Material then
				selectorClon.Material = selectorReal.Material
			end
			
			-- Sincronizar Transparency
			if selectorClon.Transparency ~= selectorReal.Transparency then
				selectorClon.Transparency = selectorReal.Transparency
			end
		end
	end
end

-- 4. FUNCIÓN PARA CLONAR CABLES
local function actualizarCables()
	-- Limpiar cables anteriores
	for _, cable in ipairs(listaCables) do
		if cable and cable.Parent then
			cable:Destroy()
		end
	end
	listaCables = {}
	
	-- Buscar cables en Workspace
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("RopeConstraint") and obj.Visible then
			local a0 = obj.Attachment0
			local a1 = obj.Attachment1
			
			if a0 and a1 then
				local part0 = a0.Parent
				local part1 = a1.Parent
				
				if part0 and part1 then
					local modelA = part0:FindFirstAncestorWhichIsA("Model")
					local modelB = part1:FindFirstAncestorWhichIsA("Model")
					
					if modelA and modelB and carpetaPostesReal and 
					   modelA.Parent == carpetaPostesReal and 
					   modelB.Parent == carpetaPostesReal then
						
						-- Buscar selectores clonados
						local refA = mapaSelectores[modelA.Name]
						local refB = mapaSelectores[modelB.Name]
						
						if refA and refB then
							local selectorClonA = refA.Clon
							local selectorClonB = refB.Clon
							
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
							
							-- Crear cable
							local cableClon = Instance.new("RopeConstraint")
							cableClon.Attachment0 = attA
							cableClon.Attachment1 = attB
							cableClon.Length = (attA.WorldPosition - attB.WorldPosition).Magnitude
							cableClon.Visible = true
							cableClon.Thickness = (obj.Thickness or 0.3) * 1.5
							cableClon.Color = obj.Color
							cableClon.Parent = worldModel
							
							table.insert(listaCables, cableClon)
						end
					end
				end
			end
		end
	end
end

-- 5. FUNCIÓN PARA CLONAR PARTÍCULAS
local function actualizarParticulas()
	-- Limpiar partículas anteriores
	for _, particula in ipairs(listaParticulas) do
		if particula and particula.Parent then
			particula:Destroy()
		end
	end
	listaParticulas = {}
	
	-- Clonar partículas de tráfico
	for _, obj in ipairs(Workspace:GetChildren()) do
		if obj.Name == "TrafficParticle" and obj:IsA("BasePart") then
			local clonParticula = obj:Clone()
			clonParticula.Parent = worldModel
			table.insert(listaParticulas, clonParticula)
		end
	end
end

-- 6. DETECTAR CAMBIO DE NIVEL
player:GetAttributeChangedSignal("CurrentLevelID"):Connect(function()
	local levelID = player:GetAttribute("CurrentLevelID")
	if levelID and levelID >= 0 then
		print("🗺️ [MINIMAPA] Activando para nivel " .. levelID)
		nivelActualID = levelID
		task.wait(1.5) -- Esperar a que cargue el nivel
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
	
	-- Cámara cenital (igual que el mapa grande)
	miniCamera.CFrame = CFrame.new(pos.X, pos.Y + ZOOM, pos.Z) * CFrame.Angles(math.rad(-90), 0, 0)
	
	-- Sincronizar colores cada frame
	sincronizarSelectores()
	
	-- Actualizar cables periódicamente
	tiempoActualizacionCables = tiempoActualizacionCables + dt
	if tiempoActualizacionCables >= 0.5 then
		tiempoActualizacionCables = 0
		actualizarCables()
	end
	
	-- Actualizar partículas periódicamente
	tiempoActualizacionParticulas = tiempoActualizacionParticulas + dt
	if tiempoActualizacionParticulas >= 0.3 then
		tiempoActualizacionParticulas = 0
		actualizarParticulas()
	end
end)

print("✅ Minimapa v6 (Sincronización Completa) Listo")
