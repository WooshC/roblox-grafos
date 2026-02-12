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
-- Eventos
local Events = ReplicatedStorage:WaitForChild("Events")
local Bindables = Events:WaitForChild("Bindables")
local Remotes = Events:WaitForChild("Remotes")

local eventoConexion = Bindables:WaitForChild("ConexionCambiada")

-- Evento para visualización de BFS (botón algoritmo)
-- NOTA: Unificado nombre a 'EjecutarAlgoritmo' para coincidir con Cliente
local eventoVisualizarBFS = Remotes:WaitForChild("EjecutarAlgoritmo")

-- ============================================
-- CONFIGURACIÓN DE LUCES POR ZONAS
-- ============================================

-- Función para activar/desactivar componentes energéticos de una zona
local function activarComponentesZona(zona, estado)
	for _, componente in ipairs(zona:GetDescendants()) do
		-- Activar/desactivar luces, partículas y beams
		if componente:IsA("Light") or componente:IsA("ParticleEmitter") or componente:IsA("Beam") then
			componente.Enabled = estado

			-- Activar/desactivar partes con material Neon
		elseif componente:IsA("BasePart") then
			-- Guardar material original si no existe
			if not componente:GetAttribute("MaterialOriginal") then
				componente:SetAttribute("MaterialOriginal", componente.Material.Name)
			end

			-- Si el componente tiene Neon o debería tenerlo
			local materialOriginal = componente:GetAttribute("MaterialOriginal")
			if materialOriginal == "Neon" or componente.Material == Enum.Material.Neon then
				if estado then
					-- Encender: Material Neon
					componente.Material = Enum.Material.Neon
				else
					-- Apagar: Material Plastic (o el original si no era Neon)
					componente.Material = Enum.Material.Plastic
				end
			end
		end
	end
end

-- Función para actualizar puntaje y estrellas
local function actualizarPuntajeGlobal(nivelID, resultados)
	local config = LevelsConfig[nivelID]
	if not config or not config.Misiones then return end

	local totalMisiones = #config.Misiones
	if totalMisiones == 0 then return end

	local misionesCompletadas = 0
	-- resultados es un mapa [id] = bool, iteramos los valores
	for _, completada in pairs(resultados) do
		if completada then misionesCompletadas = misionesCompletadas + 1 end
	end

	local maxPuntos = 1200
	-- Regla de 3: Total -> 1200, Completadas -> X
	local puntosActuales = math.floor((misionesCompletadas / totalMisiones) * maxPuntos)

	-- Actualizar a todos los jugadores (modelo cooperativo/local)
	for _, player in ipairs(Players:GetPlayers()) do
		local stats = player:FindFirstChild("leaderstats")
		if stats then
			local ptos = stats:FindFirstChild("Puntos")
			local estrellas = stats:FindFirstChild("Estrellas")

			if ptos then 
				if ptos.Value ~= puntosActuales then
					ptos.Value = puntosActuales
					print("⭐ Puntaje actualizado: " .. puntosActuales .. " (" .. misionesCompletadas .. "/" .. totalMisiones .. " misiones)")
				end
			end

			if estrellas then
				local nuevasEstrellas = 0
				if puntosActuales >= 1200 then 
					nuevasEstrellas = 3
				elseif puntosActuales >= 800 then 
					nuevasEstrellas = 2
				elseif puntosActuales > 0 then 
					nuevasEstrellas = 1
				end
				estrellas.Value = nuevasEstrellas
			end
		end
	end
end

-- Función principal: Actualizar luces de todas las zonas según nodos energizados

-- Función principal: Actualizar luces de todas las zonas según nodos energizados
local function actualizarLucesZonas(nivelID)
	local config = LevelsConfig[nivelID]
	if not config then return end

	local nivelModel = NivelUtils.obtenerModeloNivel(nivelID)
	if not nivelModel then return end

	-- Buscar carpeta "Zonas" primero
	local carpetaZonas = nivelModel:FindFirstChild("Zonas")
	local contenedorZonas = carpetaZonas or nivelModel  -- Si no hay carpeta Zonas, buscar directamente en el nivel

	-- Buscar todas las carpetas de zonas (Zona_luz, Zona_luz_1, Zona_Luz_2, etc.)
	local zonasEncontradas = {}
	for _, child in ipairs(contenedorZonas:GetChildren()) do
		-- Buscar con diferentes variaciones de nombre (Zona_luz, Zona_Luz, ZonaLuz)
		if string.match(child.Name, "^[Zz]ona[_]?[Ll]uz") and child:IsA("Folder") then
			table.insert(zonasEncontradas, child)
		end
	end

	if #zonasEncontradas == 0 then
		print("⚠️ No se encontraron zonas de luz en Nivel " .. nivelID)
		if carpetaZonas then
			print("   📁 Carpeta 'Zonas' encontrada pero vacía o sin zonas válidas")
		else
			print("   📁 No se encontró carpeta 'Zonas' en el nivel")
		end
		return
	end

	print("💡 Actualizando " .. #zonasEncontradas .. " zona(s) de luz en Nivel " .. nivelID)

	-- PASO 1: Construir tabla de nodos por zona (dinámicamente)
	local nodosPorZona = {}

	if config.Nodos then
		-- Iterar sobre todos los nodos configurados
		for nombreNodo, infoNodo in pairs(config.Nodos) do
			local zonaAsignada = infoNodo.Zona

			if zonaAsignada then
				-- Inicializar tabla si no existe
				if not nodosPorZona[zonaAsignada] then
					nodosPorZona[zonaAsignada] = {}
				end

				-- Agregar nodo a su zona
				table.insert(nodosPorZona[zonaAsignada], nombreNodo)
			end
		end
	end

	-- Agregar zona especial "Zona_luz" que incluye TODOS los nodos
	nodosPorZona["Zona_luz"] = {}
	if config.Nodos then
		for nombreNodo, _ in pairs(config.Nodos) do
			table.insert(nodosPorZona["Zona_luz"], nombreNodo)
		end
	end

	-- PASO 2: Procesar cada zona encontrada en el workspace
	for _, zona in ipairs(zonasEncontradas) do
		local nombreZona = zona.Name
		local nodosRequeridos = nodosPorZona[nombreZona] or {}
		local estadoZona = false

		if #nodosRequeridos > 0 then
			-- Obtener modo de activación (ANY o ALL)
			local modoActivacion = "ANY"  -- Por defecto
			if config.Zonas and config.Zonas[nombreZona] then
				modoActivacion = config.Zonas[nombreZona].Modo or "ANY"
			end

			-- Verificar cuántos nodos están energizados
			local nodosEnergizados = 0
			for _, nombreNodo in ipairs(nodosRequeridos) do
				local poste = NivelUtils.buscarPoste(nombreNodo, nivelID)
				if poste and poste:GetAttribute("Energizado") == true then
					nodosEnergizados = nodosEnergizados + 1
				end
			end

			-- Determinar estado según modo
			if modoActivacion == "ALL" then
				-- Todos los nodos deben estar energizados
				estadoZona = (nodosEnergizados == #nodosRequeridos)
			else
				-- Al menos un nodo debe estar energizado (modo ANY)
				estadoZona = (nodosEnergizados > 0)
			end

			print("   🔌 " .. nombreZona .. " [" .. modoActivacion .. "]: " .. nodosEnergizados .. "/" .. #nodosRequeridos .. " nodos → " .. (estadoZona and "✅ ON" or "❌ OFF"))
		else
			print("   ⚠️ " .. nombreZona .. " sin nodos asignados")
		end

		-- Buscar ComponentesEnergeticos en cualquier nivel de profundidad
		local componentesEncontrados = {}

		-- Buscar en todos los descendientes de la zona
		for _, descendiente in ipairs(zona:GetDescendants()) do
			if descendiente.Name == "ComponentesEnergeticos" and descendiente:IsA("Folder") then
				table.insert(componentesEncontrados, descendiente)
			end
		end

		-- Activar/desactivar componentes
		if #componentesEncontrados > 0 then
			-- Si hay carpetas ComponentesEnergeticos, usarlas
			for _, carpeta in ipairs(componentesEncontrados) do
				activarComponentesZona(carpeta, estadoZona)
			end
		else
			-- Si no hay ComponentesEnergeticos, buscar directamente en la zona (estructura antigua)
			activarComponentesZona(zona, estadoZona)
		end
	end
end

-- ============================================
-- VERIFICACIÓN DE ENERGÍA (Propagación Incremental)
-- ============================================

-- Cache de cables ya procesados para evitar reseteos innecesarios
local cablesYaProcesados = {}

-- Función para crear cable fantasma (visualización)
local function crearCableFantasma(nodoA, nodoB, color, nivelID)
	local carpetaPostes = NivelUtils.obtenerCarpetaPostes(nivelID)
	local objA = carpetaPostes and carpetaPostes:FindFirstChild(nodoA)
	local objB = carpetaPostes and carpetaPostes:FindFirstChild(nodoB)

	if objA and objB then
		local attA = objA:FindFirstChild("Attachment", true) 
		local attB = objB:FindFirstChild("Attachment", true)

		if attA and attB then
			local rope = Instance.new("RopeConstraint")
			rope.Name = "CableFantasmaBFS"
			rope.Attachment0 = attA
			rope.Attachment1 = attB
			rope.Length = (attA.WorldPosition - attB.WorldPosition).Magnitude
			rope.Visible = true
			rope.Thickness = 0.3
			rope.Color = color  -- color ya es BrickColor
			rope.Parent = workspace

			-- Etiqueta Fantasma
			local midPoint = (attA.WorldPosition + attB.WorldPosition) / 2
			local dist = (attA.WorldPosition - attB.WorldPosition).Magnitude / 5 -- Convertir a metros

			local etiquetaPart = Instance.new("Part")
			etiquetaPart.Name = "EtiquetaFantasmaBFS"
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
			lbl.Text = string.format("%.1fm", dist)
			lbl.TextColor3 = color.Color
			lbl.TextStrokeTransparency = 0
			lbl.Font = Enum.Font.FredokaOne
			lbl.TextSize = 18
			lbl.Parent = bb

			return rope
		end
	end
	return nil
end

-- Función para limpiar cables fantasma
local function limpiarCablesFantasma()
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj.Name == "CableFantasmaBFS" or obj.Name == "EtiquetaFantasmaBFS" then
			obj:Destroy()
		end
	end
end

-- ============================================
-- PINTADO DE CABLES (Separado de la lógica)
-- ============================================

local function pintarCablesSegunEnergia(nivelID, visitados, llegoAlFinal)
	local todosLosCables = NivelUtils.obtenerCablesDelNivel(nivelID)
	
	for _, cable in ipairs(todosLosCables) do
		if not cable.Parent then continue end -- Cable destruido
		
		-- Obtener postes conectados
		local p1 = cable.Attachment0 and cable.Attachment0.Parent and cable.Attachment0.Parent.Parent
		local p2 = cable.Attachment1 and cable.Attachment1.Parent and cable.Attachment1.Parent.Parent
		
		if p1 and p2 then
			local ambosEnergizados = visitados[p1.Name] and visitados[p2.Name]
			
			if ambosEnergizados then
				-- Cable energizado
				if llegoAlFinal then
					cable.Color = BrickColor.new("Lime green") -- Completo
				else
					cable.Color = BrickColor.new("Cyan") -- Parcial
				end
				cable.Thickness = 0.3
			else
				-- Cable sin energía
				cable.Color = BrickColor.new("Dark stone grey")
				cable.Thickness = 0.2
			end
		end
	end
end

-- ============================================
-- VERIFICACIÓN DE CONECTIVIDAD (Solo lógica)
-- ============================================

local function verificarConectividad(nivelID, modoVisualizacion)
	modoVisualizacion = modoVisualizacion or false

	if modoVisualizacion then limpiarCablesFantasma() end

	local config = LevelsConfig[nivelID]
	if not config then return end

	local carpetaPostes = NivelUtils.obtenerCarpetaPostes(nivelID)
	if not carpetaPostes then return end

	local visitados = {}

	-- Resetear estado de energía
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

			-- Vecinos a explorar
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

					if modoVisualizacion then
						print("   -> " .. nombreVecino)
						local cable = NivelUtils.buscarCable(nombreActual, nombreVecino, nivelID)
						if cable then
							cable.Color = BrickColor.new("Cyan")
							cable.Thickness = 0.3
						else
							crearCableFantasma(nombreActual, nombreVecino, BrickColor.new("Cyan"), nivelID)
						end
					else
						-- ACTUALIZAR MISIONES
						local estadoJuego = MisionManager.construirEstadoJuego(visitados, numNodosConectados, config, nil, {})
						local resultados = MisionManager.verificarTodasLasMisiones(config, estadoJuego)
						
						for misionID, completada in pairs(resultados) do
							MisionManager.actualizarMisionGlobal(misionID, completada)
						end
						
						actualizarPuntajeGlobal(nivelID, resultados)
					end
				end
			end
		end
	end

	local llegoAlFinal = visitados[config.NodoFin] == true

	-- PINTAR CABLES (CAPA SEPARADA)
	if not modoVisualizacion then
		pintarCablesSegunEnergia(nivelID, visitados, llegoAlFinal)
		actualizarLucesZonas(nivelID)
	else
		if llegoAlFinal then
			print("✅ Camino encontrado!")
			task.wait(0.5)
			for _, obj in ipairs(workspace:GetChildren()) do
				if obj.Name == "CableFantasmaBFS" then
					obj.Color = BrickColor.new("Lime green")
					obj.Thickness = 0.4
				end
			end
		else
			print("❌ Camino incompleto")
		end
	end
	
	return visitados, llegoAlFinal -- Retornar para futuras validaciones
end

-- ============================================
-- INICIALIZACIÓN
-- ============================================

local function initNivel(nivelID)
	task.wait(1)
	print("🔌 Inicializando Nivel " .. nivelID)

	actualizarLucesZonas(nivelID)  -- Apagar todas las zonas al iniciar

	local config = LevelsConfig[nivelID]
	if not config then return end

	local carpetaPostes = NivelUtils.obtenerCarpetaPostes(nivelID)

	if carpetaPostes then
		for _, poste in ipairs(carpetaPostes:GetChildren()) do
			if poste:IsA("Model") then
				poste:SetAttribute("Energizado", false)
			end
		end

		-- Encender nodo inicio
		local inicio = NivelUtils.buscarPoste(config.NodoInicio, nivelID)
		if inicio then
			inicio:SetAttribute("Energizado", true)
		end
	end
end

-- Inicializar niveles
initNivel(0)
initNivel(1)

-- Escuchar cambios en conexiones (INSTANTÁNEO - sin visualización)
eventoConexion.Event:Connect(function(nivelID)
	print("🔔 Evento ConexionCambiada recibido para Nivel " .. nivelID)
	verificarConectividad(nivelID, false)  -- false = instantáneo
end)

-- Escuchar petición de visualización BFS (DESACTIVADO EN ESTE SCRIPT)
-- La visualización ahora la maneja "VisualizadorAlgoritmos.server.lua"
-- para evitar conflictos y duplicidad.
-- eventoVisualizarBFS.OnServerEvent:Connect(function(player, nivelID) ... end)

-- Gestión de jugadores para misiones
Players.PlayerAdded:Connect(function(player)
	MisionManager.inicializarJugador(player)
end)

Players.PlayerRemoving:Connect(function(player)
	MisionManager.limpiarJugador(player)
end)

print("⚡ GameplayEvents v2.0 cargado (Modular + Incremental)")
