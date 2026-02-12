local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Módulos
local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))
local NivelUtils = require(ReplicatedStorage:WaitForChild("Utilidades"):WaitForChild("NivelUtils"))
local MisionManager = require(ReplicatedStorage:WaitForChild("Utilidades"):WaitForChild("MisionManager"))

-- Inicializar gestor de misiones
MisionManager.init()

-- Eventos
local Events = ReplicatedStorage:WaitForChild("Events")
local Bindables = Events:WaitForChild("Bindables")
local Remotes = Events:WaitForChild("Remotes")

local eventoConexion = Bindables:WaitForChild("ConexionCambiada")
local eventoVisualizarBFS = Remotes:WaitForChild("EjecutarAlgoritmo")

-- ============================================
-- FUNCIÓN CENTRALIZADA DE ACTUALIZACIÓN DE PUNTAJE
-- ============================================
local function actualizarPuntajeYEstrellas(player, nivelID)
	local config = LevelsConfig[nivelID]
	if not config or not config.Misiones then 
		warn("⚠️ No hay misiones configuradas para nivel " .. nivelID)
		return 
	end

	local totalMisiones = #config.Misiones
	if totalMisiones == 0 then return end

	-- Contar misiones completadas
	local misionesCompletadas = 0
	for i = 1, totalMisiones do
		if MisionManager.obtenerEstado(player, i) then
			misionesCompletadas = misionesCompletadas + 1
		end
	end

	-- Regla de 3: (misionesCompletadas / totalMisiones) * 1200
	local maxPuntos = 1200
	local puntosActuales = math.floor((misionesCompletadas / totalMisiones) * maxPuntos)

	-- Actualizar leaderstats
	local stats = player:FindFirstChild("leaderstats")
	if not stats then 
		warn("⚠️ leaderstats no encontrado para " .. player.Name)
		return 
	end

	-- Actualizar Puntos
	local puntos = stats:FindFirstChild("Puntos")
	if puntos then
		if puntos.Value ~= puntosActuales then
			puntos.Value = puntosActuales
			print("💰 Puntaje actualizado: " .. player.Name .. " → " .. puntosActuales .. " pts (" .. misionesCompletadas .. "/" .. totalMisiones .. ")")
		end
	else
		warn("⚠️ IntValue 'Puntos' no encontrado en leaderstats")
	end

	-- Actualizar Estrellas
	local estrellas = stats:FindFirstChild("Estrellas")
	if estrellas then
		local nuevasEstrellas = 0
		if puntosActuales >= 1200 then 
			nuevasEstrellas = 3
		elseif puntosActuales >= 800 then 
			nuevasEstrellas = 2
		elseif puntosActuales > 0 then 
			nuevasEstrellas = 1
		end

		if estrellas.Value ~= nuevasEstrellas then
			estrellas.Value = nuevasEstrellas
			print("⭐ Estrellas actualizadas: " .. player.Name .. " → " .. nuevasEstrellas)
		end
	end
end

-- ============================================
-- CONFIGURACIÓN DE LUCES POR ZONAS
-- ============================================
local function activarComponentesZona(zona, estado)
	for _, componente in ipairs(zona:GetDescendants()) do
		if componente:IsA("Light") or componente:IsA("ParticleEmitter") or componente:IsA("Beam") then
			componente.Enabled = estado
		elseif componente:IsA("BasePart") then
			if not componente:GetAttribute("MaterialOriginal") then
				componente:SetAttribute("MaterialOriginal", componente.Material.Name)
			end

			local materialOriginal = componente:GetAttribute("MaterialOriginal")
			if materialOriginal == "Neon" or componente.Material == Enum.Material.Neon then
				if estado then
					componente.Material = Enum.Material.Neon
				else
					componente.Material = Enum.Material.Plastic
				end
			end
		end
	end
end

local function actualizarLucesZonas(nivelID)
	local config = LevelsConfig[nivelID]
	if not config then return end

	local nivelModel = NivelUtils.obtenerModeloNivel(nivelID)
	if not nivelModel then return end

	local carpetaZonas = nivelModel:FindFirstChild("Zonas")
	local contenedorZonas = carpetaZonas or nivelModel

	local zonasEncontradas = {}
	for _, child in ipairs(contenedorZonas:GetChildren()) do
		if string.match(child.Name, "^[Zz]ona[_]?[Ll]uz") and child:IsA("Folder") then
			table.insert(zonasEncontradas, child)
		end
	end

	if #zonasEncontradas == 0 then return end

	local nodosPorZona = {}

	if config.Nodos then
		for nombreNodo, infoNodo in pairs(config.Nodos) do
			local zonaAsignada = infoNodo.Zona
			if zonaAsignada then
				if not nodosPorZona[zonaAsignada] then
					nodosPorZona[zonaAsignada] = {}
				end
				table.insert(nodosPorZona[zonaAsignada], nombreNodo)
			end
		end
	end

	nodosPorZona["Zona_luz"] = {}
	if config.Nodos then
		for nombreNodo, _ in pairs(config.Nodos) do
			table.insert(nodosPorZona["Zona_luz"], nombreNodo)
		end
	end

	for _, zona in ipairs(zonasEncontradas) do
		local nombreZona = zona.Name
		local nodosRequeridos = nodosPorZona[nombreZona] or {}
		local estadoZona = false

		if #nodosRequeridos > 0 then
			local modoActivacion = "ANY"
			if config.Zonas and config.Zonas[nombreZona] then
				modoActivacion = config.Zonas[nombreZona].Modo or "ANY"
			end

			local nodosEnergizados = 0
			for _, nombreNodo in ipairs(nodosRequeridos) do
				local poste = NivelUtils.buscarPoste(nombreNodo, nivelID)
				if poste and poste:GetAttribute("Energizado") == true then
					nodosEnergizados = nodosEnergizados + 1
				end
			end

			if modoActivacion == "ALL" then
				estadoZona = (nodosEnergizados == #nodosRequeridos)
			else
				estadoZona = (nodosEnergizados > 0)
			end
		end

		local componentesEncontrados = {}
		for _, descendiente in ipairs(zona:GetDescendants()) do
			if descendiente.Name == "ComponentesEnergeticos" and descendiente:IsA("Folder") then
				table.insert(componentesEncontrados, descendiente)
			end
		end

		if #componentesEncontrados > 0 then
			for _, carpeta in ipairs(componentesEncontrados) do
				activarComponentesZona(carpeta, estadoZona)
			end
		else
			activarComponentesZona(zona, estadoZona)
		end
	end
end

-- ============================================
-- VERIFICACIÓN DE CONECTIVIDAD
-- ============================================
local cablesYaProcesados = {}

local function pintarCablesSegunEnergia(nivelID, visitados, llegoAlFinal)
	local todosLosCables = NivelUtils.obtenerCablesDelNivel(nivelID)

	for _, cable in ipairs(todosLosCables) do
		if not cable.Parent then continue end

		local p1 = cable.Attachment0 and cable.Attachment0.Parent and cable.Attachment0.Parent.Parent
		local p2 = cable.Attachment1 and cable.Attachment1.Parent and cable.Attachment1.Parent.Parent

		if p1 and p2 then
			local ambosEnergizados = visitados[p1.Name] and visitados[p2.Name]

			if ambosEnergizados then
				if llegoAlFinal then
					cable.Color = BrickColor.new("Lime green")
				else
					cable.Color = BrickColor.new("Cyan")
				end
				cable.Thickness = 0.3
			else
				cable.Color = BrickColor.new("Dark stone grey")
				cable.Thickness = 0.2
			end
		end
	end
end

local function verificarConectividad(nivelID, modoVisualizacion)
	modoVisualizacion = modoVisualizacion or false

	print("🔍 verificarConectividad - Nivel: " .. nivelID .. " | Modo visualización: " .. tostring(modoVisualizacion))

	local config = LevelsConfig[nivelID]
	if not config then return end

	local carpetaPostes = NivelUtils.obtenerCarpetaPostes(nivelID)
	if not carpetaPostes then return end

	local visitados = {}

	if not modoVisualizacion then
		for _, poste in ipairs(carpetaPostes:GetChildren()) do
			poste:SetAttribute("Energizado", false)
		end
	end

	-- BFS: Propagación de energía
	local cola = { config.NodoInicio }
	visitados[config.NodoInicio] = true

	if not modoVisualizacion then
		local posteInicio = NivelUtils.buscarPoste(config.NodoInicio, nivelID)
		if posteInicio then posteInicio:SetAttribute("Energizado", true) end
	end

	local numNodosConectados = 1

	while #cola > 0 do
		if modoVisualizacion then task.wait(1.0) end

		local nombreActual = table.remove(cola, 1)
		local posteActual = NivelUtils.buscarPoste(nombreActual, nivelID)

		if posteActual then
			if not modoVisualizacion then
				posteActual:SetAttribute("Energizado", true)
			end

			local vecinos = {}
			if modoVisualizacion then
				if config.Adyacencias and config.Adyacencias[nombreActual] then
					vecinos = config.Adyacencias[nombreActual]
				end
			else
				local conns = posteActual:FindFirstChild("Connections")
				if conns then
					for _, v in ipairs(conns:GetChildren()) do
						table.insert(vecinos, v.Name)
					end
				end
			end

			for _, nombreVecino in ipairs(vecinos) do
				if not visitados[nombreVecino] and NivelUtils.buscarPoste(nombreVecino, nivelID) then
					visitados[nombreVecino] = true
					table.insert(cola, nombreVecino)
					numNodosConectados = numNodosConectados + 1

					if not modoVisualizacion then
						print("✅ Nodo energizado: " .. nombreVecino)

						-- 🔥 ACTUALIZAR MISIONES INMEDIATAMENTE
						local estadoJuego = MisionManager.construirEstadoJuego(visitados, numNodosConectados, config, nil, {})
						local resultados = MisionManager.verificarTodasLasMisiones(config, estadoJuego)

						-- Actualizar estado de cada misión
						for misionID, completada in pairs(resultados) do
							MisionManager.actualizarMisionGlobal(misionID, completada)
						end

						-- 🔥 ACTUALIZAR PUNTAJE PARA TODOS LOS JUGADORES
						for _, player in ipairs(Players:GetPlayers()) do
							local playerNivelID = player:GetAttribute("CurrentLevelID")
							if playerNivelID == nivelID then
								actualizarPuntajeYEstrellas(player, nivelID)
							end
						end
					end
				end
			end
		end
	end

	local llegoAlFinal = visitados[config.NodoFin] == true

	if not modoVisualizacion then
		pintarCablesSegunEnergia(nivelID, visitados, llegoAlFinal)
		actualizarLucesZonas(nivelID)
	end

	return visitados, llegoAlFinal
end

-- ============================================
-- INICIALIZACIÓN
-- ============================================
local function initNivel(nivelID)
	task.wait(1)
	print("🔌 Inicializando Nivel " .. nivelID)

	actualizarLucesZonas(nivelID)

	local config = LevelsConfig[nivelID]
	if not config then return end

	local carpetaPostes = NivelUtils.obtenerCarpetaPostes(nivelID)

	if carpetaPostes then
		for _, poste in ipairs(carpetaPostes:GetChildren()) do
			if poste:IsA("Model") then
				poste:SetAttribute("Energizado", false)
			end
		end

		local inicio = NivelUtils.buscarPoste(config.NodoInicio, nivelID)
		if inicio then
			inicio:SetAttribute("Energizado", true)
		end
	end
end

initNivel(0)
initNivel(1)

-- Escuchar cambios en conexiones
eventoConexion.Event:Connect(function(nivelID)
	print("🔔 Evento ConexionCambiada recibido para Nivel " .. nivelID)
	verificarConectividad(nivelID, false)
end)

-- Gestión de jugadores para misiones
Players.PlayerAdded:Connect(function(player)
	MisionManager.inicializarJugador(player)
end)

Players.PlayerRemoving:Connect(function(player)
	MisionManager.limpiarJugador(player)
end)

-- ============================================
-- EVENTO: Finalizar Nivel
-- ============================================
-- ============================================
-- EVENTO: Finalizar Nivel
-- ============================================
local function calcularEstrellas(nivelID, puntosBaseMisiones)
	local config = LevelsConfig[nivelID]
	if not config then return 0 end
	
	-- Support both naming conventions (Puntuacion or ScoreThresholds)
	local thresholds = config.Puntuacion or config.ScoreThresholds
	if not thresholds then
		return puntosBaseMisiones > 0 and 1 or 0
	end

	-- Extract thresholds with support for English/Spanish keys
	local scoreTres = thresholds.TresEstrellas or thresholds.Gold or 1200
	local scoreDos = thresholds.DosEstrellas or thresholds.Silver or 800
	local scoreUna = thresholds.UnaEstrella or thresholds.Bronze or 100

	if puntosBaseMisiones >= scoreTres then return 3
	elseif puntosBaseMisiones >= scoreDos then return 2
	elseif puntosBaseMisiones >= scoreUna then return 1
	else return 0 end
end

local LevelCompletedEvent = Remotes:FindFirstChild("LevelCompleted")
if LevelCompletedEvent then
	LevelCompletedEvent.OnServerEvent:Connect(function(player, nivelID, estrellas, puntosTotalConBono)
		print("🏆 Jugador " .. player.Name .. " completó Nivel " .. nivelID)

		-- 1. Calcular puntos BASE solo por misiones para las estrellas
		local config = LevelsConfig[nivelID]
		local totalMisiones = config and config.Misiones and #config.Misiones or 1
		local misionesCompletadas = 0
		
		for i = 1, totalMisiones do
			if MisionManager.obtenerEstado(player, i) then
				misionesCompletadas = misionesCompletadas + 1
			end
		end

		-- Puntos base según misiones (sin bonos)
		local thresholds = config.Puntuacion or config.ScoreThresholds or {}
		local maxPuntosBase = thresholds.TresEstrellas or thresholds.Gold or 1200
		local puntosBaseMisiones = math.floor((misionesCompletadas / totalMisiones) * maxPuntosBase)
		
		print("📊 Desglose: Misiones " .. misionesCompletadas .. "/" .. totalMisiones .. " -> Base: " .. puntosBaseMisiones .. " | Total con Bonos: " .. puntosTotalConBono)

		-- 2. Calcular estrellas usando SOLO los puntos base de las misiones
		estrellas = calcularEstrellas(nivelID, puntosBaseMisiones)

		-- 3. Actualizar Leaderstats (Puntos totales se guardan como moneda, Estrellas según misiones)
		local stats = player:FindFirstChild("leaderstats")
		if stats then
			-- Guardamos el total con bonos como "Puntos" acumulados (para ranking o moneda)
			local puntosVal = stats:FindFirstChild("Puntos") or stats:FindFirstChild("Score")
			if puntosVal then
				puntosVal.Value = puntosTotalConBono
			end
			
			local estrellasVal = stats:FindFirstChild("Estrellas")
			if estrellasVal then
				estrellasVal.Value = estrellas
			end
		end

		print("   📊 Guardando - Estrellas: " .. estrellas .. " | Puntos Totales: " .. puntosTotalConBono)

		if not player:GetAttribute("CurrentLevelID") then
			player:SetAttribute("CurrentLevelID", nivelID)
		end

		if _G.CompleteLevel then
			_G.CompleteLevel(player, estrellas, puntosTotalConBono)
			print("✅ Progreso guardado via _G.CompleteLevel")
		else
			warn("❌ _G.CompleteLevel no está disponible")
		end

		task.wait(1)
		local OpenMenuEvent = Bindables:FindFirstChild("OpenMenu")
		if OpenMenuEvent then
			OpenMenuEvent:Fire()
			LevelCompletedEvent:FireClient(player, nivelID, estrellas, puntosTotalConBono)
		end

		print("🎉 Nivel " .. nivelID .. " finalizado. Regresando al menú...")
	end)
	print("✅ Listener LevelCompleted registrado")
else
	warn("❌ Evento LevelCompleted no encontrado en Remotes")
end

print("⚡ GameplayEvents v2.2 - Estrellas basadas solo en Misiones")
