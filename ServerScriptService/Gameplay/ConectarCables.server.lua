-- ConectarCables.server.lua (CORREGIDO)
-- ✅ CORRECCIÓN: Los RopeConstraints ahora se parentean dentro del modelo del primer poste
-- Esto organiza mejor la jerarquía y evita que estén sueltos en workspace

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))
local NivelUtils = require(ReplicatedStorage:WaitForChild("Utilidades"):WaitForChild("NivelUtils"))

-- Gestionar selecciones por jugador
local selecciones = {} -- { [Player] = selector }

-- Configuración de Sonido
local SOUND_CONNECT_ID = "rbxassetid://8089220692"
local SOUND_CLICK_ID = "rbxassetid://125043525599051"

-- Referencias a eventos
local eventsFolder = ReplicatedStorage:WaitForChild("Events")
local remotesFolder = eventsFolder:WaitForChild("Remotes")

local pulseEvent = remotesFolder:WaitForChild("PulseEvent")
local cableDragEvent = remotesFolder:WaitForChild("CableDragEvent")

-- ============================================
-- UTILIDADES LOCALES
-- ============================================

local function getPosteFromSelector(selector)
	return selector.Parent
end

local function getAttachment(selector)
	return selector:FindFirstChild("Attachment")
end

local function reproducirSonido(id, parent)
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = 0.5
	sound.Parent = parent
	sound:Play()
	game.Debris:AddItem(sound, 2)
end

-- Función para desconectar y reembolsar
local function desconectarPostes(poste1, poste2, player)
	local connections1 = poste1:FindFirstChild("Connections")
	local connections2 = poste2:FindFirstChild("Connections")

	local val1 = connections1 and connections1:FindFirstChild(poste2.Name)

	if not val1 then return end

	local distancia = val1.Value

	local nivelIDPoste, configNivel = NivelUtils.obtenerNivelDelPoste(poste1)

	if not NivelUtils.puedeModificarNivel(player, nivelIDPoste) then
		local stats = player:FindFirstChild("leaderstats")
		local nivelJugador = stats and stats:FindFirstChild("Nivel") and stats.Nivel.Value or 0
		print("🔒 No puedes modificar cables de un nivel que no es el tuyo. (Tú: " .. nivelJugador .. ", Poste: " .. nivelIDPoste .. ")")
		return
	end

	local costoPorMetro = configNivel.CostoPorMetro
	local reembolso = math.floor(distancia * costoPorMetro)

	-- Devolver dinero
	local leaderstats = player:FindFirstChild("leaderstats")
	local money = leaderstats and leaderstats:FindFirstChild("Money")

	if money then
		money.Value = money.Value + reembolso
	end

	-- Borrar datos de conexión
	if connections1:FindFirstChild(poste2.Name) then connections1[poste2.Name]:Destroy() end
	if connections2:FindFirstChild(poste1.Name) then connections2[poste1.Name]:Destroy() end

	-- ✅ BUSCAR Y DESTRUIR CABLE EN CARPETA CONEXIONES
	local carpetaPostes = poste1.Parent
	local carpetaConexiones = carpetaPostes and carpetaPostes:FindFirstChild("Conexiones")
	
	if carpetaConexiones then
		for _, cable in ipairs(carpetaConexiones:GetChildren()) do
			if cable:IsA("RopeConstraint") then
				local a0 = cable.Attachment0
				local a1 = cable.Attachment1

				if a0 and a1 then
					local p1 = a0.Parent and a0.Parent.Parent
					local p2 = a1.Parent and a1.Parent.Parent

					if (p1 == poste1 and p2 == poste2) or (p1 == poste2 and p2 == poste1) then
						cable:Destroy()
						print("🗑️ Cable eliminado de Conexiones: " .. cable.Name)
						break
					end
				end
			end
		end
	end

	-- Notificar clientes para borrar partículas
	if pulseEvent then
		pulseEvent:FireAllClients("StopPulse", poste1, poste2)
	end

	-- Borrar Etiquetas de Peso en workspace
	for _, child in ipairs(workspace:GetChildren()) do
		if child.Name == "EtiquetaPeso_" .. poste1.Name .. "_" .. poste2.Name or 
			child.Name == "EtiquetaPeso_" .. poste2.Name .. "_" .. poste1.Name then
			child:Destroy()
		end
	end

	-- Resetear colores
	local partes = {poste1:FindFirstChild("Part"), poste1:FindFirstChild("Selector"), poste1:FindFirstChild("Poste"), poste1.PrimaryPart}
	for _, p in ipairs(partes) do if p then p.Color = Color3.fromRGB(196, 196, 196) end end

	print("════════════════════════════")
	print("🔌 DESCONEXIÓN EXITOSA (Nivel " .. nivelIDPoste .. ")")

	-- Disparar evento para re-verificar energía
	local serverEvents = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Bindables")
	local eventoConexion = serverEvents:WaitForChild("ConexionCambiada")

	if eventoConexion then
		eventoConexion:Fire(nivelIDPoste)
	end
end

-- Función principal de conexión
local function conectarPostes(poste1, poste2, att1, att2, player)
	-- 1. DETECTAR NIVEL DE LOS POSTES
	local nivelID1, configNivel1 = NivelUtils.obtenerNivelDelPoste(poste1)
	local nivelID2, configNivel2 = NivelUtils.obtenerNivelDelPoste(poste2)

	-- VALIDACIÓN DE NIVEL DE JUGADOR
	if not NivelUtils.puedeModificarNivel(player, nivelID1) then
		print("🔒 Este poste pertenece al Nivel " .. nivelID1)
		return
	end

	-- Validación: No conectar postes de niveles distintos
	if nivelID1 ~= nivelID2 then
		print("🚫 ERROR: No puedes conectar postes de niveles distintos.")
		return
	end

	local configNivel = configNivel1

	-- VALIDAR ADYACENCIA PERMITIDA
	if not NivelUtils.esConexionValida(poste1.Name, poste2.Name, nivelID1) then
		print("🚫 CONEXIÓN INVÁLIDA: Diseño no permite conexión.")
		return
	end

	-- Validar duplicados (Si existe, desconecta)
	local connections1 = poste1:FindFirstChild("Connections")
	if not connections1 then
		connections1 = Instance.new("Folder")
		connections1.Name = "Connections"
		connections1.Parent = poste1
	end
	
	local connections2 = poste2:FindFirstChild("Connections")
	if not connections2 then
		connections2 = Instance.new("Folder")
		connections2.Name = "Connections"
		connections2.Parent = poste2
	end

	if connections1:FindFirstChild(poste2.Name) then
		print("🔄 Ya conectados. Desconectando...")
		desconectarPostes(poste1, poste2, player)
		return
	end

	-- 2. Calcular distancia (Peso)
	local distanciaStuds = (att1.WorldPosition - att2.WorldPosition).Magnitude
	local distanciaMetros = distanciaStuds / 4
	distanciaMetros = math.floor(distanciaMetros)

	-- 3. CALCULAR COSTO
	local costoPorMetro = configNivel.CostoPorMetro
	local costoTotal = distanciaMetros * costoPorMetro

	-- 4. VERIFICAR DINERO DE JUGADOR
	local leaderstats = player:FindFirstChild("leaderstats")
	local money = leaderstats and leaderstats:FindFirstChild("Money")

	if not money then return end

	if money.Value < costoTotal then
		print("🚫 FONDOS INSUFICIENTES. Necesitas:", costoTotal, "Tienes:", money.Value)
		return
	end

	-- 5. DESCONTAR DINERO
	money.Value = money.Value - costoTotal

	-- ✅ 6. CREAR CABLE VISUAL - EN CARPETA CONEXIONES
	local rope = Instance.new("RopeConstraint")
	rope.Name = "Cable_" .. poste1.Name .. "_" .. poste2.Name
	rope.Attachment0 = att1
	rope.Attachment1 = att2
	rope.Length = distanciaStuds
	rope.Visible = true
	rope.Thickness = 0.15
	rope.Color = BrickColor.new("Black")
	
	-- Encontrar o crear carpeta Conexiones
	local carpetaPostes = poste1.Parent
	local carpetaConexiones = carpetaPostes:FindFirstChild("Conexiones")
	if not carpetaConexiones then
		carpetaConexiones = Instance.new("Folder")
		carpetaConexiones.Name = "Conexiones"
		carpetaConexiones.Parent = carpetaPostes
	end

	-- ✅ CORRECCIÓN: Parentear en la carpeta Conexiones
	rope.Parent = carpetaConexiones

	print("✅ Cable creado en: " .. rope:GetFullName())

	-- 6a. PARTÍCULAS (Visualización dirigida según el grafo)
	local esBidireccional = true
	local nodoOrigen = poste1
	local nodoDestino = poste2

	-- Verificar definición del grafo para dirección
	if configNivel and configNivel.Adyacencias then
		local ady = configNivel.Adyacencias
		local p1 = poste1.Name
		local p2 = poste2.Name

		local puedeIr_1to2 = false
		local puedeIr_2to1 = false

		if ady[p1] and table.find(ady[p1], p2) then puedeIr_1to2 = true end
		if ady[p2] and table.find(ady[p2], p1) then puedeIr_2to1 = true end

		if puedeIr_1to2 and puedeIr_2to1 then
			esBidireccional = true
		elseif puedeIr_1to2 then
			esBidireccional = false
			nodoOrigen = poste1
			nodoDestino = poste2
		elseif puedeIr_2to1 then
			esBidireccional = false
			nodoOrigen = poste2
			nodoDestino = poste1
		end
	end

	if pulseEvent then
		pulseEvent:FireAllClients("StartPulse", nodoOrigen, nodoDestino, esBidireccional)
	end

	-- 7. VISUALIZAR PESO (PEDAGOGÍA) - Estas etiquetas sí van en workspace
	local midPoint = (att1.WorldPosition + att2.WorldPosition) / 2
	local etiquetaPart = Instance.new("Part")
	etiquetaPart.Name = "EtiquetaPeso_" .. poste1.Name .. "_" .. poste2.Name
	etiquetaPart.Size = Vector3.new(0.5, 0.5, 0.5)
	etiquetaPart.Transparency = 1 
	etiquetaPart.Anchored = true
	etiquetaPart.CanCollide = false
	etiquetaPart.Position = midPoint
	etiquetaPart.Parent = workspace

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 80, 0, 40)
	bb.StudsOffset = Vector3.new(0, 2, 0)
	bb.AlwaysOnTop = true
	bb.Parent = etiquetaPart

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1,0,1,0)
	lbl.BackgroundTransparency = 1
	lbl.Text = string.format("%d m", distanciaMetros)
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.TextStrokeTransparency = 0
	lbl.Font = Enum.Font.FredokaOne
	lbl.TextSize = 20
	lbl.Parent = bb

	-- Reproducir sonido de éxito
	reproducirSonido(SOUND_CONNECT_ID, att2)

	-- 8. Guardar datos lógicos
	local connections1 = poste1:FindFirstChild("Connections")
	local connections2 = poste2:FindFirstChild("Connections")

	local c1 = Instance.new("NumberValue")
	c1.Name = poste2.Name
	c1.Value = distanciaMetros
	c1.Parent = connections1

	local c2 = Instance.new("NumberValue")
	c2.Name = poste1.Name
	c2.Value = distanciaMetros
	c2.Parent = connections2

	-- Evento de Gameplay (Luces)
	local serverEvents = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Bindables")
	local eventoConexion = serverEvents:WaitForChild("ConexionCambiada")

	if eventoConexion then
		eventoConexion:Fire(nivelID1)
	end
end

-- Manejo del click
local function onClick(selector, player)
	local poste = getPosteFromSelector(selector)
	local seleccionActual = selecciones[player]

	-- 1. PRIMER CLICK (Seleccionar inicio)
	if not seleccionActual then
		selecciones[player] = selector
		print("👉 Seleccionado Inicio:", poste.Name)

		-- Sonido click
		reproducirSonido(SOUND_CLICK_ID, selector)

		-- Iniciar visualización de cable en cliente
		local att = getAttachment(selector)
		if att then
			cableDragEvent:FireClient(player, "Start", att)
		end
		return
	end

	-- 2. SEGUNDO CLICK
	local posteAnterior = getPosteFromSelector(seleccionActual)

	-- Si hace click en el mismo poste, cancelar
	if poste == posteAnterior then
		print("❌ Mismo poste. Cancelando selección.")
		selecciones[player] = nil
		cableDragEvent:FireClient(player, "Stop")
		return
	end

	-- Obtener attachments
	local att1 = getAttachment(seleccionActual)
	local att2 = getAttachment(selector)

	if not att1 or not att2 then
		warn("⚠️ Error: No se encontraron attachments")
		selecciones[player] = nil
		cableDragEvent:FireClient(player, "Stop")
		return
	end

	-- Realizar conexión
	conectarPostes(posteAnterior, poste, att1, att2, player)

	-- Limpiar selección
	selecciones[player] = nil
	cableDragEvent:FireClient(player, "Stop")
end

-- ============================================
-- REGISTRAR CLICK DETECTORS
-- ============================================
local function registrarPostes(carpetaPostes)
	for _, poste in ipairs(carpetaPostes:GetChildren()) do
		if poste:IsA("Model") then
			local selector = poste:FindFirstChild("Selector")
			if selector then
				local clickDetector = selector:FindFirstChild("ClickDetector")
				if clickDetector then
					clickDetector.MouseClick:Connect(function(player)
						onClick(selector, player)
					end)
				end
			end
		end
	end
	print("✅ ClickDetectors registrados en:", carpetaPostes:GetFullName())
end

-- Buscar carpetas de postes en todos los niveles
for _, nivel in ipairs(workspace:GetChildren()) do
	if string.match(nivel.Name, "^Nivel") then
		local objetos = nivel:FindFirstChild("Objetos")
		if objetos then
			local postesFolder = objetos:FindFirstChild("Postes")
			if postesFolder then
				registrarPostes(postesFolder)
			end
		end
	end
end

print("✅ ConectarCables.server.lua (CORREGIDO) cargado - Cables ahora se parentean en postes")