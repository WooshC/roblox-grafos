--[[
	MINIMAPA v11 - Visualización Híbrida (Cables Fantasma + Reales)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))

-- CONFIGURACIÓN
local ZOOM = 140 
local TAMANO_MAPA = 250

-- 1. REFERENCIAR GUI EXISTENTE
local screenGui = player:WaitForChild("PlayerGui"):WaitForChild("MinimapGUI")
local viewport = screenGui:WaitForChild("MarcoMinimapa"):WaitForChild("Vista")

-- Configuración de Cámara
local miniCamera = Instance.new("Camera")
miniCamera.FieldOfView = 70
viewport.CurrentCamera = miniCamera

-- Referenciar WorldModel
local worldModel = viewport:WaitForChild("WorldModel")

-- Referencias
local nivelActualID = nil
local carpetaPostesReal = nil
local mapaSelectores = {}
local listaCables = {}
local listaParticulas = {}
local cantidadCablesAnterior = 0 

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

	-- 1. Prioridad: NivelActual (Instanciado por LevelService)
	local nivelModel = Workspace:FindFirstChild("NivelActual")

	-- 2. Fallback: Nombre del modelo en config (Testing/Legacy)
	if not nivelModel then
		nivelModel = Workspace:FindFirstChild(config.Modelo)
	end
	
	-- 3. Fallback: Búsqueda por patrón "NivelX"
	if not nivelModel and string.match(config.Modelo, "Nivel(%d+)") then
		local numNivel = string.match(config.Modelo, "Nivel(%d+)")
		nivelModel = Workspace:FindFirstChild("Nivel" .. numNivel)
	end

	if not nivelModel then
		warn("⚠️ [MINIMAPA] Modelo no encontrado: NivelActual ni " .. config.Modelo)
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

			selectorClon.Transparency = 0
			selectorClon.Material = Enum.Material.Neon

			local colorReal = selectorReal.Color

			-- Lógica de color (PRIORIDAD: Visualizador de Algoritmo - Material Neon/Glass)
			if selectorReal.Material == Enum.Material.Neon or selectorReal.Material == Enum.Material.Glass then
				selectorClon.Color = colorReal
				selectorClon.Material = Enum.Material.Neon -- Forzar Neon para visibilidad
			else
				-- Lógica normal de energía
				selectorClon.Material = Enum.Material.Neon

				if nombre == "PostePanel" or nombre == "GeneradorCentral" then
					selectorClon.Color = Color3.fromRGB(52, 152, 219) 
				elseif nombre == "PosteFinal" or nombre == "TorreControl" then
					selectorClon.Color = Color3.fromRGB(255, 140, 0)
				elseif energizado == true then
					selectorClon.Color = Color3.new(0, 1, 0) -- Verde (Energizado)
				else
					selectorClon.Color = Color3.fromRGB(231, 76, 60) -- Rojo (Sin energía)
				end
			end
		end
	end
end

-- 4. FUNCIÓN PARA ACTUALIZAR CABLES (Híbrido)
local function actualizarCables()
	-- Limpiar cables anteriores
	for _, cable in ipairs(listaCables) do
		if cable and cable.Parent then
			cable:Destroy()
		end
	end
	listaCables = {}

	if not carpetaPostesReal then return end

	-- Calculamos el color "base" si está energizado (para cables normales)
	local config = LevelsConfig[nivelActualID] or LevelsConfig[0]
	local nombreFin = config.NodoFin or "PosteFinal"
	local posteFin = carpetaPostesReal:FindFirstChild(nombreFin) or carpetaPostesReal.Parent:FindFirstChild(nombreFin)
	local finalEnergizado = posteFin and posteFin:GetAttribute("Energizado")
	local colorBaseEnergizado = finalEnergizado and Color3.new(0, 1, 0) or Color3.fromRGB(0, 162, 255)

	-- Helper para getKey
	local function getCableKey(att0, att1)
		if not att0 or not att1 then return nil end
		local p0 = att0.Parent; local p1 = att1.Parent
		if not p0 or not p1 then return nil end
		local m0 = p0:FindFirstAncestorWhichIsA("Model")
		local m1 = p1:FindFirstAncestorWhichIsA("Model")
		if m0 and m1 then
			return (m0.Name < m1.Name) and (m0.Name.."_"..m1.Name) or (m1.Name.."_"..m0.Name)
		end
		return nil
	end

	-- 1. MAPEAR CABLES FANTASMA (Algoritmo)
	local mapaFantasmas = {} -- Key -> RopeConstraint object
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj.Name == "CableFantasmaAlgoritmo" and obj:IsA("RopeConstraint") and obj.Visible then
			local key = getCableKey(obj.Attachment0, obj.Attachment1)
			if key then
				mapaFantasmas[key] = obj
			end
		end
	end

	-- 2. DIBUJAR CABLES REALES (Con prioridad Fantasma)
	local carpetaConexiones = carpetaPostesReal:FindFirstChild("Conexiones") 
		or carpetaPostesReal.Parent:FindFirstChild("Conexiones")
		or carpetaPostesReal:FindFirstChild("Connections")

	if carpetaConexiones then
		for _, cable in ipairs(carpetaConexiones:GetChildren()) do
			if cable:IsA("RopeConstraint") and cable.Visible then
				local attA = cable.Attachment0
				local attB = cable.Attachment1

				if attA and attB then
					local key = getCableKey(attA, attB)
					if key then
						local dist = (attA.WorldPosition - attB.WorldPosition).Magnitude
						local centro = (attA.WorldPosition + attB.WorldPosition) / 2

						local cablePart = Instance.new("Part")
						cablePart.Name = "CableVisualPart"
						cablePart.Anchored = true
						cablePart.CanCollide = false
						cablePart.CastShadow = false
						cablePart.Material = Enum.Material.Neon
						cablePart.Size = Vector3.new(2, 2, dist)
						cablePart.CFrame = CFrame.lookAt(centro, attB.WorldPosition)

						-- DECIDIR COLOR
						if mapaFantasmas[key] then
							-- PRIORIDAD: Fantasma
							local fantasma = mapaFantasmas[key]
							cablePart.Color = fantasma.Color.Color 
							cablePart.Material = Enum.Material.Neon
							mapaFantasmas[key] = nil -- Consumir
						else
							-- Lógica normal
							local pA = attA.Parent:FindFirstAncestorWhichIsA("Model")
							local pB = attB.Parent:FindFirstAncestorWhichIsA("Model")
							local eA = pA and pA:GetAttribute("Energizado")
							local eB = pB and pB:GetAttribute("Energizado")

							if eA and eB then
								cablePart.Color = colorBaseEnergizado
							else
								cablePart.Color = Color3.fromRGB(80, 80, 80)
							end
						end

						cablePart.Transparency = 0
						cablePart.Parent = worldModel
						table.insert(listaCables, cablePart)
					end
				end
			end
		end
	end

	-- 3. DIBUJAR FANTASMAS RESTANTES
	for key, fantasma in pairs(mapaFantasmas) do
		local attA = fantasma.Attachment0
		local attB = fantasma.Attachment1
		if attA and attB then
			local dist = (attA.WorldPosition - attB.WorldPosition).Magnitude
			local centro = (attA.WorldPosition + attB.WorldPosition) / 2

			local cablePart = Instance.new("Part")
			cablePart.Name = "CableFantasmaVisual"
			cablePart.Anchored = true
			cablePart.CanCollide = false
			cablePart.CastShadow = false
			cablePart.Material = Enum.Material.Neon
			cablePart.Size = Vector3.new(2.5, 2.5, dist)
			cablePart.CFrame = CFrame.lookAt(centro, attB.WorldPosition)

			cablePart.Color = fantasma.Color.Color
			cablePart.Transparency = 0

			cablePart.Parent = worldModel
			table.insert(listaCables, cablePart)
		end
	end

	-- Log opcional
	if #listaCables ~= cantidadCablesAnterior then
		-- print("🔌 [MINIMAPA] Cables actualizados: " .. #listaCables)
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

-- LISTENERS
task.spawn(function()
	local Events = ReplicatedStorage:WaitForChild("Events", 10)
	if not Events then return end
	local Bindables = Events:WaitForChild("Bindables", 10)
	if not Bindables then return end

	local OpenMenuEvent = Bindables:WaitForChild("OpenMenu", 10)
	if OpenMenuEvent then
		OpenMenuEvent.Event:Connect(function()
			print("🗺️ [MINIMAPA] Ocultando por regreso al menú")
			screenGui.Enabled = false
			nivelActualID = nil
			carpetaPostesReal = nil
		end)
	end
end)

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

-- INIT CHECK
local currentLevel = player:GetAttribute("CurrentLevelID")
if currentLevel and currentLevel >= 0 then
	nivelActualID = currentLevel
	task.wait(1.5)
	cargarSelectores(currentLevel)
	actualizarCables()
	screenGui.Enabled = true
end

-- UPDATE LOOP
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

print("✅ Minimapa v11 (Híbrido) Listo")