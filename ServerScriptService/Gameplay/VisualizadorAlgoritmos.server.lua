local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("▶️ INICIANDO VisualizadorAlgoritmos.server.lua...")

-- 1. Referencia a Eventos
local eventsFolder = ReplicatedStorage:WaitForChild("Events")
local remotesFolder = eventsFolder:WaitForChild("Remotes")
local bindables = eventsFolder:WaitForChild("Bindables")

local evento = remotesFolder:WaitForChild("EjecutarAlgoritmo")
local LevelCompletedEvent = remotesFolder:FindFirstChild("LevelCompleted")

print("✅ Visualizador: Evento EjecutarAlgoritmo encontrado.")

-- 2. Cargar Dependencias
local Algoritmos = nil
local moduloRef = nil

if ReplicatedStorage:FindFirstChild("Algoritmos") then
	moduloRef = ReplicatedStorage.Algoritmos
elseif ReplicatedStorage:FindFirstChild("Utilidades") and ReplicatedStorage.Utilidades:FindFirstChild("Algoritmos") then
	moduloRef = ReplicatedStorage.Utilidades.Algoritmos
end

if not moduloRef then
	warn("❌ CRÍTICO: NO se encontró módulo 'Algoritmos'")
else
	local exitoLoad, resultado = pcall(require, moduloRef)
	if exitoLoad then
		Algoritmos = resultado
		print("✅ Visualizador: Módulo Algoritmos cargado ÉXITOSAMENTE.")
	else
		warn("❌ Error: " .. tostring(resultado))
	end
end

-- ============================================
-- ESTADO DEL VISUALIZADOR
-- ============================================
local estadoAlgoritmo = {} -- { [nivelID] = { resultado = table, yaValidado = bool } }

-- ============================================
-- COLORES DEL ALGORITMO (Diferenciados)
-- ============================================
local COLORES = {
	Explorando = Color3.fromRGB(255, 140, 0),  -- Naranja brillante
	Actual = Color3.fromRGB(255, 69, 0),       -- Naranja rojizo
	CaminoFinal = Color3.fromRGB(138, 43, 226),-- Violeta brillante
	CableExplorando = "Deep orange",
	CableFinal = "Royal purple"
}

-- Función Helper para encontrar la carpeta de postes
local function obtenerCarpetaPostes(nivelIDOverride)
	if nivelIDOverride == 0 and workspace:FindFirstChild("Nivel0_Tutorial") then
		return workspace.Nivel0_Tutorial:FindFirstChild("Objetos") and workspace.Nivel0_Tutorial.Objetos:FindFirstChild("Postes")
	elseif nivelIDOverride == 1 and workspace:FindFirstChild("Nivel1") then
		return workspace.Nivel1:FindFirstChild("Objetos") and workspace.Nivel1.Objetos:FindFirstChild("Postes")
	end

	if workspace:FindFirstChild("Nivel1") then
		return workspace.Nivel1:FindFirstChild("Objetos") and workspace.Nivel1.Objetos:FindFirstChild("Postes")
	elseif workspace:FindFirstChild("Nivel0_Tutorial") then
		return workspace.Nivel0_Tutorial:FindFirstChild("Objetos") and workspace.Nivel0_Tutorial.Objetos:FindFirstChild("Postes")
	else
		return workspace:FindFirstChild("Objetos") and workspace.Objetos:FindFirstChild("Postes")
	end
end

local exito = (Algoritmos ~= nil)

-- Pintar nodo
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

-- Pintar cable
local function pintarCable(nodoA, nodoB, color, grosor, nivelID)
	local carpetaPostes = obtenerCarpetaPostes(nivelID)
	if not carpetaPostes then return false end

	for _, obj in ipairs(workspace:GetChildren()) do
		if obj:IsA("RopeConstraint") then
			local a0 = obj.Attachment0
			local a1 = obj.Attachment1

			if a0 and a1 then
				local part0 = a0.Parent
				local part1 = a1.Parent

				local modelA = part0:FindFirstAncestorWhichIsA("Model")
				local modelB = part1:FindFirstAncestorWhichIsA("Model")

				if modelA and modelB and modelA.Parent == carpetaPostes and modelB.Parent == carpetaPostes then
					local p1 = modelA.Name
					local p2 = modelB.Name

					if (p1 == nodoA and p2 == nodoB) or (p1 == nodoB and p2 == nodoA) then
						obj.Color = BrickColor.new(color)
						if grosor then obj.Thickness = grosor end
						return true
					end
				end
			end
		end
	end
	return false
end

local ejecucionActual = 0

local function crearCableFantasma(nodoA, nodoB, color, nivelID)
	local carpetaPostes = obtenerCarpetaPostes(nivelID)
	local objA = carpetaPostes and carpetaPostes:FindFirstChild(nodoA)
	local objB = carpetaPostes and carpetaPostes:FindFirstChild(nodoB)

	if objA and objB then
		local attA = objA:FindFirstChild("Attachment", true) 
		local attB = objB:FindFirstChild("Attachment", true)

		if attA and attB then
			local rope = Instance.new("RopeConstraint")
			rope.Name = "CableFantasmaAlgoritmo" -- Nombre único
			rope.Attachment0 = attA
			rope.Attachment1 = attB
			rope.Length = (attA.WorldPosition - attB.WorldPosition).Magnitude
			rope.Visible = true
			rope.Thickness = 0.4
			rope.Color = BrickColor.new(color)
			rope.Parent = workspace

			return rope
		end
	end
	return nil
end

-- ============================================
-- LIMPIEZA COMPLETA (Borra cables y restaura colores)
-- ============================================
local function limpiarVisualizacionCompleta(nivelID)
	print("🧹 Limpiando visualización del algoritmo...")

	-- 1. Eliminar cables fantasma
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj.Name == "CableFantasmaAlgoritmo" or obj.Name == "EtiquetaFantasmaAlgo" then
			obj:Destroy()
		end
	end

	-- 2. Restaurar colores de postes
	local carpetaPostes = obtenerCarpetaPostes(nivelID)
	if carpetaPostes then
		for _, poste in ipairs(carpetaPostes:GetChildren()) do
			local partes = {poste:FindFirstChild("Part"), poste:FindFirstChild("Selector"), poste.PrimaryPart}
			for _, p in ipairs(partes) do
				if p then
					p.Color = Color3.fromRGB(196, 196, 196)
					p.Material = Enum.Material.Plastic
				end
			end
		end
	end

	print("✅ Visualización limpiada")
end

-- Helper para contar keys
local function tableKeys(t)
	local keys = {}
	for k, _ in pairs(t) do table.insert(keys, k) end
	return keys
end

-- ============================================
-- VALIDACIÓN Y BONUS (Cables, no Nodos)
-- ============================================
local function validarRutaJugador(nivelID, player, resultadoAlgoritmo)
	if not resultadoAlgoritmo or not resultadoAlgoritmo.Pasos then return end

	local estado = estadoAlgoritmo[nivelID]
	if estado.yaValidado then
		print("⚠️ Validación ya ejecutada. Ejecuta el algoritmo de nuevo para recalcular.")
		return
	end

	local carpetaPostes = obtenerCarpetaPostes(nivelID)
	if not carpetaPostes then return end

	-- ========================================
	-- 1. CABLES DEL JUGADOR (Conexiones reales)
	-- ========================================
	local cablesJugador = {} -- { ["NodoA_NodoB"] = true }

	for _, poste in ipairs(carpetaPostes:GetChildren()) do
		local conns = poste:FindFirstChild("Connections")
		if conns then
			for _, val in ipairs(conns:GetChildren()) do
				local nombreVecino = val.Name
				-- Clave ordenada para evitar duplicados (A-B = B-A)
				local clave = poste.Name < nombreVecino 
					and (poste.Name .. "_" .. nombreVecino) 
					or (nombreVecino .. "_" .. poste.Name)
				cablesJugador[clave] = true
			end
		end
	end

	-- ========================================
	-- 2. CABLES EXPLORADOS POR BFS (Todo lo que visitó)
	-- ========================================
	local cablesOptimos = {} -- { ["NodoA_NodoB"] = true }

	-- Extraer de los pasos del algoritmo
	for _, paso in ipairs(resultadoAlgoritmo.Pasos) do
		if paso.Tipo == "Explorando" and paso.Nodo and paso.Origen then
			local clave = paso.Nodo < paso.Origen 
				and (paso.Nodo .. "_" .. paso.Origen) 
				or (paso.Origen .. "_" .. paso.Nodo)
			cablesOptimos[clave] = true
		end
	end

	-- ========================================
	-- 3. COMPARAR
	-- ========================================
	local aciertos = 0
	local fallos = 0

	for cable, _ in pairs(cablesJugador) do
		if cablesOptimos[cable] then
			aciertos = aciertos + 1
		else
			fallos = fallos + 1
		end
	end

	local bonusPuntos = aciertos * 100
	local penalizacion = fallos * 50
	local puntosNetos = math.max(0, bonusPuntos - penalizacion)

	print("🎯 VALIDACIÓN (Cables):")
	print("   ✅ Aciertos: " .. aciertos .. " cables correctos (+'" .. bonusPuntos .. " pts)")
	print("   ❌ Fallos: " .. fallos .. " cables innecesarios (-" .. penalizacion .. " pts)")
	print("   🔍 BFS exploró: " .. #tableKeys(cablesOptimos) .. " cables")
	print("   🎮 Jugador usó: " .. #tableKeys(cablesJugador) .. " cables")
	print("   💰 BONUS NETO: " .. puntosNetos)

	-- Aplicar bonus AL PUNTAJE BASE
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		-- Intentar encontrar el stat de puntos (puede llamarse "Puntos" o "Score")
		local puntos = stats:FindFirstChild("Puntos") or stats:FindFirstChild("Score")

		if puntos then
			local puntosAntes = puntos.Value
			puntos.Value = puntos.Value + puntosNetos
			print("💾 Bonus aplicado: " .. puntosAntes .. " → " .. puntos.Value)
		else
			warn("⚠️ No se encontró leaderstat 'Puntos' o 'Score'. Stats disponibles:")
			for _, child in ipairs(stats:GetChildren()) do
				warn("   - " .. child.Name)
			end
		end
	else
		warn("⚠️ leaderstats no encontrado para " .. player.Name)
	end

	estado.yaValidado = true

	return {Aciertos = aciertos, Fallos = fallos, Bonus = puntosNetos}
end

-- Escuchar evento PRINCIPAL
evento.OnServerEvent:Connect(function(player, algoritmo, nodoInicio, nodoFin, nivelID)
	nivelID = nivelID or 0
	print("📡 SEÑAL: " .. tostring(algoritmo) .. " en Nivel: " .. nivelID)

	if not exito then
		warn("❌ Módulo no cargado")
		return
	end

	-- SIEMPRE limpiar antes de ejecutar (no toggle)
	limpiarVisualizacionCompleta(nivelID)

	-- Resetear validación si ya existía (permitir recalculo)
	if estadoAlgoritmo[nivelID] then
		estadoAlgoritmo[nivelID].yaValidado = false
		print("🔄 Reiniciando validación...")
	end

	ejecucionActual = ejecucionActual + 1
	local miEjecucionID = ejecucionActual

	print("🧠 Ejecutando [" .. algoritmo .. "]: " .. nodoInicio .. " -> " .. nodoFin)

	local resultado = nil
	if algoritmo == "Dijkstra" and Algoritmos.DijkstraVisual then
		resultado = Algoritmos.DijkstraVisual(nodoInicio, nodoFin, nivelID)
	elseif algoritmo == "BFS" and Algoritmos.BFSVisual then
		resultado = Algoritmos.BFSVisual(nodoInicio, nodoFin, nivelID)
	end

	if not resultado then 
		print("❌ Error: Algoritmo devolvió nil")
		return 
	end

	-- Inicializar estado
	if not estadoAlgoritmo[nivelID] then
		estadoAlgoritmo[nivelID] = {}
	end
	estadoAlgoritmo[nivelID].resultado = resultado
	estadoAlgoritmo[nivelID].yaValidado = false

	print("🔍 Pasos: " .. #(resultado.Pasos or {}))

	if not resultado.Pasos then return end

	-- ANIMACIÓN
	for _, paso in ipairs(resultado.Pasos) do
		if miEjecucionID ~= ejecucionActual then return end

		if paso.Tipo == "NodoActual" then
			pintarNodo(paso.Nodo, COLORES.Actual, Enum.Material.Neon, nivelID)
			task.wait(1.5)

		elseif paso.Tipo == "Explorando" then
			pintarNodo(paso.Nodo, COLORES.Explorando, Enum.Material.Glass, nivelID)

			local pintado = pintarCable(paso.Nodo, paso.Origen, COLORES.CableExplorando, 0.4, nivelID)
			if not pintado then
				crearCableFantasma(paso.Nodo, paso.Origen, COLORES.CableExplorando, nivelID)
			end

			task.wait(0.8)

		elseif paso.Tipo == "Destino" then
			print("🎯 Destino encontrado")
		end
	end

	if miEjecucionID ~= ejecucionActual then return end

	-- CAMINO FINAL
	if resultado.CaminoFinal and #resultado.CaminoFinal > 0 then
		print("🏁 Camino óptimo encontrado!")

		local camino = resultado.CaminoFinal
		for i = 1, #camino do
			if miEjecucionID ~= ejecucionActual then return end

			local nodoActual = camino[i]
			local nodoSiguiente = camino[i+1]

			pintarNodo(nodoActual, COLORES.CaminoFinal, Enum.Material.Neon, nivelID)

			if nodoSiguiente then
				local existe = pintarCable(nodoActual, nodoSiguiente, COLORES.CableFinal, 0.5, nivelID)
				if not existe then
					crearCableFantasma(nodoActual, nodoSiguiente, COLORES.CableFinal, nivelID)
				end
				task.wait(0.2)
			end
		end

		-- VALIDAR RUTA DEL JUGADOR
		task.wait(1)
		validarRutaJugador(nivelID, player, resultado)

		print("✅ Algoritmo completado. Visualización permanece visible para análisis.")
	else
		print("⚠️ No existe camino")
		task.wait(2)
		limpiarVisualizacionCompleta(nivelID)
	end
end)

-- Limpieza al reiniciar
local restaurarEvent = bindables:WaitForChild("RestaurarObjetos")

if restaurarEvent then
	restaurarEvent.Event:Connect(function()
		print("🛑 Reinicio detectado, limpiando algoritmo")
		ejecucionActual = ejecucionActual + 1
		for nivelID, _ in pairs(estadoAlgoritmo) do
			toggleVisualizacion(nivelID, true) -- Forzar ocultar
			estadoAlgoritmo[nivelID] = nil
		end
	end)
end

print("✅ VisualizadorAlgoritmos.server.lua INICIADO CORRECTAMENTE")
