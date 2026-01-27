local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. Crear evento remoto INMEDIATAMENTE
local eventoNombre = "EjecutarAlgoritmo"
local evento = ReplicatedStorage:FindFirstChild(eventoNombre) or Instance.new("RemoteEvent")
evento.Name = eventoNombre
evento.Parent = ReplicatedStorage
print("✅ Evento 'EjecutarAlgoritmo' asegurado en ReplicatedStorage")

-- 2. Cargar dependencias con manejo de errores DEPURADO
-- 2. Cargar dependencias (Nombre corregido: "Algoritmos")
local Algoritmos = nil
local moduloRef = ReplicatedStorage:WaitForChild("Algoritmos", 10) -- Se llama "Algoritmos" en Studio

if not moduloRef then
	warn("❌ CRÍTICO: NO se encontró 'Algoritmos' en ReplicatedStorage. Verifica el nombre.")
else
	local exitoLoad, resultado = pcall(require, moduloRef)
	if exitoLoad then
		Algoritmos = resultado
		print("🧠 Visualizador: Módulo 'Algoritmos' cargado correctamente.")
	else
		warn("❌ CRÍTICO: Falló el 'require' de Algoritmos.")
		warn("📄 ERROR: " .. tostring(resultado))
	end
end

-- Función Helper para encontrar la carpeta de postes según el nivel activo
local function obtenerCarpetaPostes(nivelIDOverride)
	if nivelIDOverride == 0 and workspace:FindFirstChild("Nivel0_Tutorial") then
		return workspace.Nivel0_Tutorial:FindFirstChild("Objetos") and workspace.Nivel0_Tutorial.Objetos:FindFirstChild("Postes")
	elseif nivelIDOverride == 1 and workspace:FindFirstChild("Nivel1") then
		return workspace.Nivel1:FindFirstChild("Objetos") and workspace.Nivel1.Objetos:FindFirstChild("Postes")
	end

	-- Priorizamos Nivel1 si existe (Fallback)
	if workspace:FindFirstChild("Nivel1") then
		return workspace.Nivel1:FindFirstChild("Objetos") and workspace.Nivel1.Objetos:FindFirstChild("Postes")
	elseif workspace:FindFirstChild("Nivel0_Tutorial") then
		return workspace.Nivel0_Tutorial:FindFirstChild("Objetos") and workspace.Nivel0_Tutorial.Objetos:FindFirstChild("Postes")
	else
		return workspace:FindFirstChild("Objetos") and workspace.Objetos:FindFirstChild("Postes")
	end
end

-- Bandera de éxito para el resto del script
local exito = (Algoritmos ~= nil)

-- Función para pintar un nodo
local function pintarNodo(nombreNodo, color, material, nivelID)
	local carpetaPostes = obtenerCarpetaPostes(nivelID)
	if not carpetaPostes then return end
	
	local poste = carpetaPostes:FindFirstChild(nombreNodo)
	if poste then
		local partes = {poste:FindFirstChild("Part"), poste:FindFirstChild("Selector"), poste:FindFirstChild("Poste"), poste.PrimaryPart}
		for _, p in ipairs(partes) do
			if p then
				p.Color = color
				if material then p.Material = material end
				break 
			end
		end
	end
end

-- Función para pintar un cable (arista)
-- Función para pintar un cable (arista)
local function pintarCable(nodoA, nodoB, color, grosor, nivelID)
	
	local carpetaPostes = obtenerCarpetaPostes(nivelID)
	if not carpetaPostes then return false end
	
	-- Buscamos cables existentes en el workspace (RopeConstraint)
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj:IsA("RopeConstraint") then
			local a0 = obj.Attachment0
			local a1 = obj.Attachment1
			
			if a0 and a1 then
				-- Verificar padres
				local part0 = a0.Parent
				local part1 = a1.Parent
				
				-- Necesitamos encontrar el MODELO del poste (abuelo o bisabuelo del attachment)
				-- Asumimos jerarquía: ModeloPoste -> Parte/Selector -> Attachment
				-- O ModeloPoste -> Attachment
				
				local modelA = part0:FindFirstAncestorWhichIsA("Model")
				local modelB = part1:FindFirstAncestorWhichIsA("Model")
				
				-- VALIDACIÓN ESTRICTA DE PADRES
				-- El modelo del poste debe ser hijo directo de la carpetaPostes del nivel actual
				if modelA and modelB and modelA.Parent == carpetaPostes and modelB.Parent == carpetaPostes then
					local p1 = modelA.Name
					local p2 = modelB.Name
					
					if (p1 == nodoA and p2 == nodoB) or (p1 == nodoB and p2 == nodoA) then
						obj.Color = BrickColor.new(color)
						if grosor then obj.Thickness = grosor end
						return true -- ¡Encontrado y pintado!
					end
				end
			end
		end
	end
	return false -- No encontrado
end

-- Función Helper para crear cable fantasma
local function crearCableFantasma(nodoA, nodoB, color, nivelID)
	local carpetaPostes = obtenerCarpetaPostes(nivelID)
	local objA = carpetaPostes and carpetaPostes:FindFirstChild(nodoA)
	local objB = carpetaPostes and carpetaPostes:FindFirstChild(nodoB)
	
	if objA and objB then
		local attA = objA:FindFirstChild("Attachment", true) 
		local attB = objB:FindFirstChild("Attachment", true)
		
		if attA and attB then
			local rope = Instance.new("RopeConstraint")
			rope.Name = "CableFantasma"
			rope.Attachment0 = attA
			rope.Attachment1 = attB
			rope.Length = (attA.WorldPosition - attB.WorldPosition).Magnitude
			rope.Visible = true
			rope.Thickness = 0.3
			rope.Color = BrickColor.new(color)
			rope.Parent = workspace
			
			-- Etiqueta Fantasma
			local midPoint = (attA.WorldPosition + attB.WorldPosition) / 2
			local dist = (attA.WorldPosition - attB.WorldPosition).Magnitude
			
			local etiquetaPart = Instance.new("Part")
			etiquetaPart.Name = "EtiquetaFantasma"
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
			lbl.Text = math.floor(dist) .. "m"
			lbl.TextColor3 = color
			lbl.TextStrokeTransparency = 0
			lbl.Font = Enum.Font.FredokaOne
			lbl.TextSize = 18
			lbl.Parent = bb
			
			return rope
		end
	end
	return nil
end

-- Escuchar evento
evento.OnServerEvent:Connect(function(player, algoritmo, nodoInicio, nodoFin, nivelID)
	-- [Resto del código de inicialización igual...]
	nivelID = nivelID or 1 
	print("📡 SEÑAL RECIBIDA: " .. tostring(algoritmo) .. " en Nivel: " .. nivelID)
	
	if not exito then
		warn("❌ No se puede ejecutar: Módulo de algoritmos roto.")
		return
	end

	-- Función de limpieza
	local function limpiarVisualizacion()
		print("🧹 Limpiando visualización anterior en Nivel " .. nivelID)
		
		-- 1. Restaurar Colores de Postes
		local carpetaPostes = obtenerCarpetaPostes(nivelID)
		if carpetaPostes then
			for _, poste in ipairs(carpetaPostes:GetChildren()) do
				local partes = {poste:FindFirstChild("Part"), poste:FindFirstChild("Selector"), poste:FindFirstChild("Poste"), poste.PrimaryPart}
				for _, p in ipairs(partes) do
					if p then
						p.Color = Color3.fromRGB(196, 196, 196) -- Color Base (Gris)
						p.Material = Enum.Material.Plastic
					end
				end
			end
		end
		
		-- 2. Eliminar elementos temporales
		for _, obj in ipairs(workspace:GetChildren()) do
			if obj.Name == "CableFantasma" or obj.Name == "EtiquetaFantasma" then
				obj:Destroy()
			end
		end
	end

	-- Admitimos BFS o Dijkstra (visualización idéntica en grafos unitarios)
	if algoritmo == "Dijkstra" or algoritmo == "BFS" then
		limpiarVisualizacion()
		print("🧠 Ejecutando Algoritmo Visual [" .. algoritmo .. "]: " .. tostring(nodoInicio) .. " -> " .. tostring(nodoFin))
		
		local resultado = Algoritmos.DijkstraVisual(nodoInicio, nodoFin, nivelID)
		
		if not resultado then 
			print("❌ Error: Dijkstra devolvió nil")
			return 
		end
		
		print("🔍 Pasos encontrados: " .. #resultado.Pasos)
		
		-- ANIMACIÓN DEL PROCESO
		for _, paso in ipairs(resultado.Pasos) do
			if paso.Tipo == "NodoActual" then
				pintarNodo(paso.Nodo, Color3.fromRGB(255, 215, 0), Enum.Material.Neon, nivelID)
				task.wait(0.6)
				
			elseif paso.Tipo == "Explorando" then
				pintarNodo(paso.Nodo, Color3.fromRGB(52, 152, 219), Enum.Material.Glass, nivelID)
				
				-- Intentar pintar cable REAL, si no, crear FANTASMA
				local pintado = pintarCable(paso.Nodo, paso.Origen, Color3.fromRGB(52, 152, 219), 0.3, nivelID)
				if not pintado then
					crearCableFantasma(paso.Nodo, paso.Origen, Color3.fromRGB(52, 152, 219), nivelID)
				end
				
				task.wait(0.3)
			
			elseif paso.Tipo == "Destino" then
				print("🎯 Destino encontrado en el grafo")
			end
		end
		
		-- CAMINO FINAL
		if resultado.CaminoFinal and #resultado.CaminoFinal > 0 then
			print("🏁 Camino encontrado! Costo: " .. resultado.CostoTotal)
			
			-- NOTA: No limpiamos visualización aquí para que se vea el rastro de exploración + camino.
			-- Si quieres limpiar solo exploración, habría que etiquetar diferente los objetos.
			-- limpiarVisualizacion() 
			
			local camino = resultado.CaminoFinal
			for i = 1, #camino do
				local nodoActual = camino[i]
				local nodoSiguiente = camino[i+1]
				
				pintarNodo(nodoActual, Color3.fromRGB(46, 204, 113), Enum.Material.Neon, nivelID)
				
				if nodoSiguiente then
					local cableExistente = pintarCable(nodoActual, nodoSiguiente, Color3.fromRGB(46, 204, 113), 0.5, nivelID)
					if not cableExistente then
						crearCableFantasma(nodoActual, nodoSiguiente, Color3.fromRGB(46, 204, 113), nivelID)
					end
					task.wait(0.2)
				end
			end
		else
			print("⚠️ No existe camino entre " .. nodoInicio .. " y " .. nodoFin)
		end
	end
end)
