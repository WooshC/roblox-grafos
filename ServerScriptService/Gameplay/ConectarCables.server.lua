-- Importar módulos
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))
local NivelUtils = require(ReplicatedStorage:WaitForChild("Utilidades"):WaitForChild("NivelUtils"))

local posteSeleccionado = nil

-- ============================================
-- UTILIDADES LOCALES
-- ============================================

local function getPosteFromSelector(selector)
	return selector.Parent
end

local function getAttachment(selector)
	return selector:FindFirstChild("Attachment")
end

-- Función para desconectar y reembolsar
local function desconectarPostes(poste1, poste2, player)
	local connections1 = poste1:FindFirstChild("Connections")
	local connections2 = poste2:FindFirstChild("Connections")

	-- Verificar datos de conexión
	local val1 = connections1 and connections1:FindFirstChild(poste2.Name)

	if not val1 then return end -- No existe conexión real

	local distancia = val1.Value

	-- DETECTAR NIVEL DESDE EL POSTE usando utilidad
	local nivelIDPoste, configNivel = NivelUtils.obtenerNivelDelPoste(poste1)

	-- VALIDACIÓN DE NIVEL DE JUGADOR usando utilidad
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

	-- Borrar cable visual Y ETIQUETAS
	for _, child in ipairs(workspace:GetChildren()) do
		-- 1. Borrar RopeConstraint
		if child:IsA("RopeConstraint") then
			local a0 = child.Attachment0
			local a1 = child.Attachment1

			if a0 and a1 then
				local p1 = a0.Parent and a0.Parent.Parent
				local p2 = a1.Parent and a1.Parent.Parent

				if (p1 == poste1 and p2 == poste2) or (p1 == poste2 and p2 == poste1) then
					child:Destroy()
				end
			end
		end

		-- 2. Borrar Etiqueta de Peso
		if child.Name == "EtiquetaPeso_" .. poste1.Name .. "_" .. poste2.Name or 
			child.Name == "EtiquetaPeso_" .. poste2.Name .. "_" .. poste1.Name then
			child:Destroy()
		end
	end

	-- Resetear colores: Aquí deberíamos resetear SOLO los de ese nivel, pero por simplicidad
	-- podemos dejar que el Visualizador maneje limpiezas masivas, o iterar solo los vecinos.
	-- Dejamos el loop visual simple por ahora en el poste desconectado
	local partes = {poste1:FindFirstChild("Part"), poste1:FindFirstChild("Selector"), poste1:FindFirstChild("Poste"), poste1.PrimaryPart}
	for _, p in ipairs(partes) do if p then p.Color = Color3.fromRGB(196, 196, 196) end end

	
	print("════════════════════════════")
	print("🔌 DESCONEXIÓN EXITOSA (Nivel " .. nivelIDPoste .. ")")
	
	-- ⚡ DISPARAR EVENTO PARA RE-VERIFICAR ENERGÍA
	local serverEvents = game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Bindables")
	local eventoConexion = serverEvents:WaitForChild("ConexionCambiada")
	
	if eventoConexion then
		eventoConexion:Fire(nivelIDPoste)
		print("🔄 Re-verificando energía después de desconectar")
	end
	
	print("📍 Nodos:", poste1.Name, "</->", poste2.Name)
	print("💰 Reembolso:", reembolso, "monedas")
	print("💵 Dinero actual:", money.Value)
	print("════════════════════════════")
end

-- Función principal de conexión
local function conectarPostes(poste1, poste2, att1, att2, player)
	-- 1. DETECTAR NIVEL DE LOS POSTES usando utilidad
	local nivelID1, configNivel1 = NivelUtils.obtenerNivelDelPoste(poste1)
	local nivelID2, configNivel2 = NivelUtils.obtenerNivelDelPoste(poste2)

	-- VALIDACIÓN DE NIVEL DE JUGADOR usando utilidad
	if not NivelUtils.puedeModificarNivel(player, nivelID1) then
		local stats = player:FindFirstChild("leaderstats")
		local nivelJugador = stats and stats:FindFirstChild("Nivel") and stats.Nivel.Value or 0
		print("🔒 Este poste pertenece al Nivel " .. nivelID1 .. ". Tú estás en el Nivel " .. nivelJugador)
		return
	end

	-- Validación: No conectar postes de niveles distintos
	if nivelID1 ~= nivelID2 then
		print("🚫 ERROR: No puedes conectar postes de niveles distintos.")
		return
	end

	local configNivel = configNivel1

	-- 0. VALIDAR ADYACENCIA PERMITIDA usando utilidad
	if not NivelUtils.esConexionValida(poste1.Name, poste2.Name, nivelID1) then
		print("🚫 CONEXIÓN INVÁLIDA: El diseño del nivel no permite conectar " .. poste1.Name .. " con " .. poste2.Name)
		return
	end
	-- 1. Validar duplicados (Si existe, desconecta)
	local connections1 = poste1:FindFirstChild("Connections")

	if connections1:FindFirstChild(poste2.Name) then
		print("🔄 Ya conectados. Desconectando...")
		desconectarPostes(poste1, poste2, player)
		return
	end

	-- 2. Calcular distancia (Peso)
	local distanciaStuds = (att1.WorldPosition - att2.WorldPosition).Magnitude
	-- Conversión: 1 metro = 5 studs (aprox, para juego)
	local distanciaMetros = distanciaStuds / 5
	distanciaMetros = math.floor(distanciaMetros * 10) / 10 -- Redondear a 1 decimal

	-- 3. CALCULAR COSTO
	local costoPorMetro = configNivel.CostoPorMetro
	local costoTotal = math.floor(distanciaMetros * costoPorMetro)

	-- 4. VERIFICAR DINERO DE JUGADOR
	local leaderstats = player:FindFirstChild("leaderstats")
	local money = leaderstats and leaderstats:FindFirstChild("Money")

	if not money then
		print("❌ Error: No se encontró el dinero del jugador")
		return
	end

	if money.Value < costoTotal then
		print("🚫 FONDOS INSUFICIENTES. Necesitas:", costoTotal, "Tienes:", money.Value)
		return
	end

	-- 5. DESCONTAR DINERO
	money.Value = money.Value - costoTotal

	-- 6. Crear cable visual
	local rope = Instance.new("RopeConstraint")
	rope.Attachment0 = att1
	rope.Attachment1 = att2
	rope.Length = distanciaStuds -- El cable visual usa STUDS reales
	rope.Visible = true
	rope.Thickness = 0.15
	rope.Color = BrickColor.new("Black")
	rope.Parent = workspace

	-- 7. VISUALIZAR PESO (PEDAGOGÍA) - ETIQUETA FLOTANTE CON LA DISTANCIA
	local midPoint = (att1.WorldPosition + att2.WorldPosition) / 2
	local etiquetaPart = Instance.new("Part")
	-- Importante: Nombre único para poder encontrarla y borrarla después
	etiquetaPart.Name = "EtiquetaPeso_" .. poste1.Name .. "_" .. poste2.Name
	etiquetaPart.Size = Vector3.new(0.5, 0.5, 0.5)
	etiquetaPart.Transparency = 1 -- Invisible
	etiquetaPart.Anchored = true
	etiquetaPart.CanCollide = false
	etiquetaPart.Position = midPoint
	etiquetaPart.Parent = workspace

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 80, 0, 40)
	bb.StudsOffset = Vector3.new(0, 2, 0) -- Un poco arriba del cable
	bb.AlwaysOnTop = true
	bb.Parent = etiquetaPart

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1,0,1,0)
	lbl.BackgroundTransparency = 1
	lbl.Text = distanciaMetros .. "m" -- Ej: "4.2m"
	lbl.TextColor3 = Color3.new(1, 1, 1) -- Texto Blanco
	lbl.TextStrokeTransparency = 0 -- Borde negro para leer mejor
	lbl.Font = Enum.Font.FredokaOne
	lbl.TextSize = 20
	lbl.Parent = bb

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
	local serverEvents = game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Bindables")
	local eventoConexion = serverEvents:WaitForChild("ConexionCambiada")

	if eventoConexion then
		print("🔔 Disparando evento ConexionCambiada para Nivel " .. nivelID1)
		eventoConexion:Fire(nivelID1)
	else
		warn("⚠️ No se encontró el evento ConexionCambiada")
	end

	-- 9. Logs
	print("════════════════════════════")
	print("🔌 CONEXIÓN EXITOSA")
	print("📍 Nodos:", poste1.Name, "<->", poste2.Name)
	print("📏 Peso (Arista):", distanciaMetros, "m")
	print("💰 Costo:", costoTotal, "monedas")
	print("💵 Dinero restante:", money.Value)
	print("════════════════════════════")
end

-- Manejo del click
local function onClick(selector, player)
	local poste = getPosteFromSelector(selector)

	if not posteSeleccionado then
		posteSeleccionado = selector
		print("👉 Seleccionado:", poste.Name)
		return
	end

	if posteSeleccionado == selector then 
		print("⚠️ Mismo poste seleccionado")
		return 
	end

	local poste1 = getPosteFromSelector(posteSeleccionado)
	local poste2 = poste
	local att1 = getAttachment(posteSeleccionado)
	local att2 = getAttachment(selector)

	if att1 and att2 then
		conectarPostes(poste1, poste2, att1, att2, player)
	end

	posteSeleccionado = nil
end

-- Inicialización
local function setupPoste(poste)
	if not poste:FindFirstChild("Connections") then
		local f = Instance.new("Folder")
		f.Name = "Connections"
		f.Parent = poste
	end

	local selector = poste:FindFirstChild("Selector")
	if selector then
		local cd = selector:FindFirstChild("ClickDetector")
		if cd then
			cd.MouseClick:Connect(function(player)
				onClick(selector, player)
			end)
		end
	end
end

-- Inicialización GLOBAL de todos los niveles detectados
-- Ya no dependemos solo del "nivel activo", sino que iniciamos todo lo que veamos en Workspace

local function inicializarNimel(nombreNivel)
	local nivelFolder = workspace:FindFirstChild(nombreNivel)
	if not nivelFolder then return end

	local objetos = nivelFolder:FindFirstChild("Objetos")
	local postesFolder = objetos and objetos:FindFirstChild("Postes")

	if postesFolder then
		print("🔌 Inicializando postes para: " .. nombreNivel)
		for _, poste in ipairs(postesFolder:GetChildren()) do
			if poste:IsA("Model") then
				setupPoste(poste)
			end
		end

		-- Escuchar nuevos postes
		postesFolder.ChildAdded:Connect(function(child)
			if child:IsA("Model") then setupPoste(child) end
		end)
	end
end

-- Inicializamos ambos niveles si existen
inicializarNimel("Nivel0_Tutorial")
inicializarNimel("Nivel1")

print("✅ Script ConectarCables v3.2 cargado (Multinivel)")
