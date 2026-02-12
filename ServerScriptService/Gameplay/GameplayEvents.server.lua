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
	if not config or not config.Misiones then return end

	local totalMisiones = #config.Misiones
	if totalMisiones == 0 then return end

	-- Contar misiones completadas
	local misionesCompletadas = 0
	for i = 1, totalMisiones do
		if MisionManager.obtenerEstado(player, i) then
			misionesCompletadas = misionesCompletadas + 1
		end
	end

	-- Regla de 3: (completadas / total) × 1200
	local maxPuntos = 1200
	local puntosActuales = math.floor((misionesCompletadas / totalMisiones) * maxPuntos)

	-- Actualizar leaderstats
	local stats = player:FindFirstChild("leaderstats")
	if not stats then return end

	-- Actualizar Puntos
	local puntos = stats:FindFirstChild("Puntos")
	if puntos and puntos.Value ~= puntosActuales then
		puntos.Value = puntosActuales
		print("💰 " .. player.Name .. " → " .. puntosActuales .. " pts (" .. misionesCompletadas .. "/" .. totalMisiones .. ")")
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
			print("⭐ " .. player.Name .. " → " .. nuevasEstrellas .. " estrellas")
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
				componente.Material = estado and Enum.Material.Neon or Enum.Material.Plastic
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
				nodosPorZona[zonaAsignada] = nodosPorZona[zonaAsignada] or {}
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

			estadoZona = (modoActivacion == "ALL") and (nodosEnergizados == #nodosRequeridos) or (nodosEnergizados > 0)
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
local function pintarCablesSegunEnergia(nivelID, visitados, llegoAlFinal)
	local todosLosCables = NivelUtils.obtenerCablesDelNivel(nivelID)

	for _, cable in ipairs(todosLosCables) do
		if not cable.Parent then continue end

		local p1 = cable.Attachment0 and cable.Attachment0.Parent and cable.Attachment0.Parent.Parent
		local p2 = cable.Attachment1 and cable.Attachment1.Parent and cable.Attachment1.Parent.Parent

		if p1 and p2 then
			local ambosEnergizados = visitados[p1.Name] and visitados[p2.Name]

			if ambosEnergizados then
				cable.Color = llegoAlFinal and BrickColor.new("Lime green") or BrickColor.new("Cyan")
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
						-- Actualizar misiones
						local estadoJuego = MisionManager.construirEstadoJuego(visitados, numNodosConectados, config, nil, {})
						local resultados = MisionManager.verificarTodasLasMisiones(config, estadoJuego)

						for misionID, completada in pairs(resultados) do
							MisionManager.actualizarMisionGlobal(misionID, completada)
						end

						-- Actualizar puntaje para jugadores en este nivel
						for _, player in ipairs(Players:GetPlayers()) do
							if player:GetAttribute("CurrentLevelID") == nivelID then
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
	
	actualizarLucesZonas(nivelID)
end

initNivel(0)
initNivel(1)

-- Escuchar cambios en conexiones
eventoConexion.Event:Connect(function(nivelID)
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
local function calcularEstrellas(nivelID, puntos)
	local config = LevelsConfig[nivelID]
	if not config or not config.ScoreThresholds then
		return puntos > 0 and 1 or 0
	end

	local thresholds = config.ScoreThresholds
	if puntos >= (thresholds.Gold or 9999) then return 3
	elseif puntos >= (thresholds.Silver or 9999) then return 2
	elseif puntos >= (thresholds.Bronze or 9999) then return 1
	else return 0 end
end

local LevelCompletedEvent = Remotes:FindFirstChild("LevelCompleted")
if LevelCompletedEvent then
	LevelCompletedEvent.OnServerEvent:Connect(function(player, nivelID, estrellas, puntos)
		local stats = player:FindFirstChild("leaderstats")
		if stats then
			local puntosVal = stats:FindFirstChild("Puntos") or stats:FindFirstChild("Score")
			if puntosVal then
				puntos = puntosVal.Value
			end
		end

		estrellas = calcularEstrellas(nivelID, puntos)

		if stats then
			local estrellasVal = stats:FindFirstChild("Estrellas")
			if estrellasVal then
				estrellasVal.Value = estrellas
			end
		end

		if not player:GetAttribute("CurrentLevelID") then
			player:SetAttribute("CurrentLevelID", nivelID)
		end

		if _G.CompleteLevel then
			_G.CompleteLevel(player, estrellas, puntos)
		end

		task.wait(1)
		local OpenMenuEvent = Bindables:FindFirstChild("OpenMenu")
		if OpenMenuEvent then
			OpenMenuEvent:Fire()
			LevelCompletedEvent:FireClient(player, nivelID, estrellas, puntos)
		end

		print("🎉 Nivel " .. nivelID .. " completado: " .. estrellas .. "⭐ | " .. puntos .. " pts")
	end)
end

print("⚡ GameplayEvents v2.1 - Sistema de puntaje activo")
