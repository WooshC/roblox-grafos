-- StarterPlayerScripts/HUD/ModulosHUD/ModuloAnalisis.lua

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")

local E                    = require(script.EstadoAnalisis)
local C                    = require(script.ConstantesAnalisis)
local ViewportAnalisis     = require(script.ViewportAnalisis)
local PseudocodigoAnalisis = require(script.PseudocodigoAnalisis)
local PanelEstadoAnalisis  = require(script.PanelEstadoAnalisis)

local AlgoritmosGrafo = require(script.Parent.AlgoritmosGrafo)
local LevelsConfig    = require(RS:WaitForChild("Config"):WaitForChild("LevelsConfig"))
local GrafoHelpers    = require(RS:WaitForChild("Compartido"):WaitForChild("GrafoHelpers"))

local jugador = Players.LocalPlayer

local ModuloAnalisis = {}

-- ════════════════════════════════════════════════════════════════
-- LAZY-GET RemoteFunction
-- ════════════════════════════════════════════════════════════════
local function getGrafoCompletoFunc()
	if E.grafoCompletoFunc then return E.grafoCompletoFunc end
	local ok, remote = pcall(function()
		return RS:WaitForChild("EventosGrafosV3", 10)
			:WaitForChild("Remotos", 5)
			:WaitForChild("GetGrafoCompleto", 5)
	end)
	if ok and remote then
		E.grafoCompletoFunc = remote
		return remote
	end
	warn("[ModuloAnalisis] GetGrafoCompleto no encontrada")
	return nil
end

-- ════════════════════════════════════════════════════════════════
-- CONSTRUIR ADYACENCIAS DESDE LA MATRIZ
-- ════════════════════════════════════════════════════════════════
local function buildAdyacencias(data, soloValidas)
	local nivelID = jugador:GetAttribute("CurrentLevelID") or 0
	return GrafoHelpers.adjDesdeMatriz(data, not soloValidas, nivelID)
end

-- ════════════════════════════════════════════════════════════════
-- LEER AnalisisConfig PARA LA ZONA ACTIVA
-- ════════════════════════════════════════════════════════════════
local function cargarAnalisisConfig(zona)
	local nivelID = jugador:GetAttribute("CurrentLevelID") or 0
	local config  = LevelsConfig[nivelID]
	if not config or not config.AnalisisConfig then
		E.analisisConfig = nil
		E.nodoInicio     = nil
		E.nodoFin        = nil
		return
	end

	local cfg = config.AnalisisConfig[zona]
	E.analisisConfig = cfg

	if cfg then
		-- nodoInicio: usar el definido en config; si no existe, el primer header
		E.nodoInicio = cfg.nodoInicio
		E.nodoFin    = cfg.nodoFin  -- puede ser nil

		-- Filtrar las pills según los algoritmos permitidos en esta zona
		PanelEstadoAnalisis.actualizarPillsVisibles(cfg.algoritmos)

		-- Si el algo actual no está disponible en esta zona, cambiar al primero disponible
		if cfg.algoritmos and #cfg.algoritmos > 0 then
			local algoValido = false
			for _, a in ipairs(cfg.algoritmos) do
				if a == E.algoActual then algoValido = true break end
			end
			if not algoValido then
				E.algoActual = cfg.algoritmos[1]
			end
		end
	else
		-- Zona sin AnalisisConfig: mostrar todos los algoritmos, usar primer nodo
		E.nodoInicio = nil
		E.nodoFin    = nil
		PanelEstadoAnalisis.actualizarPillsVisibles(nil)  -- nil = mostrar todos
	end
end

-- ════════════════════════════════════════════════════════════════
-- AUTO-PLAY
-- ════════════════════════════════════════════════════════════════
local function detenerAutoPlay()
	E.autoPlaying = false
	if E.btnEjecRef then E.btnEjecRef.Text = "▶ Ejecutar" end
end

local function iniciarAutoPlay()
	if E.autoPlaying then detenerAutoPlay(); return end
	if E.totalPasos == 0 then return end

	E.autoPlaying = true
	if E.btnEjecRef then E.btnEjecRef.Text = "⏹ Parar" end

	task.spawn(function()
		if E.pasoActual >= E.totalPasos then E.pasoActual = 0 end
		while E.autoPlaying and E.pasoActual < E.totalPasos do
			task.wait(C.VEL_AUTO)
			if not E.autoPlaying then break end
			E.pasoActual = E.pasoActual + 1
			PanelEstadoAnalisis.aplicarPaso(E.pasos[E.pasoActual])
		end
		
		if E.autoPlaying and E.modoValidacion then
			-- Finalizó el auto-play de validación exitosamente
			local inicio = E.nodoInicio or E.matrizData.Headers[1]
			local aisladosSet = GrafoHelpers.nodosNoAlcanzables(E.adyacencias, inicio, E.matrizData.Headers)
			
			local aislados = {}
			for _, n in ipairs(E.matrizData.Headers) do
				if aisladosSet[n] then
					table.insert(aislados, E.matrizData.NombresNodos[n] or n)
				end
			end
			
			if #aislados > 0 then
				local zonaId = jugador:GetAttribute("ZonaActual") or ""
				local nivelID = jugador:GetAttribute("CurrentLevelID") or 0
				local cfg = LevelsConfig[nivelID]
				local zonaNombre = (cfg and cfg.Zonas and cfg.Zonas[zonaId]) and cfg.Zonas[zonaId].Descripcion or zonaId
				PanelEstadoAnalisis.mostrarMensajeDesc("¡Error! " .. zonaNombre .. " - Nodo(s) aislados detectados: " .. table.concat(aislados, ", ") .. " por cable defectuoso o falta de conexión.")
			else
				PanelEstadoAnalisis.mostrarMensajeDesc("✓ Grafo analizado. No hay nodos aislados en la estructura construída.")
			end
			-- Mantenemos modoValidacion = true para que el UI pueda colorear los nodos finales de rojo
			E.validacionTerminada = true
			-- Forzamos re-dibujo para reflejar los nodos aislados en la UI
			PanelEstadoAnalisis.actualizarScrollEstado(E.pasos[E.pasoActual])

			-- Restaurar el algoritmo original del análisis
			if E.algoOriginalValidacion then
				E.algoActual = E.algoOriginalValidacion
				E.algoOriginalValidacion = nil
				PanelEstadoAnalisis.actualizarPills(E.algoActual)
				PseudocodigoAnalisis.reconstruirPseudocodigo(E.algoActual)
			end
		end
		detenerAutoPlay()
	end)
end

-- ════════════════════════════════════════════════════════════════
-- EJECUTAR ALGORITMO
-- ════════════════════════════════════════════════════════════════
local function ejecutarAlgoritmo()
	if not E.matrizData then return end

	detenerAutoPlay()

	local nodos = E.matrizData.Headers
	local fn    = AlgoritmosGrafo[E.algoActual]
	if not fn then
		warn("[ModuloAnalisis] Algoritmo desconocido:", E.algoActual)
		return
	end

	-- Usar nodoInicio de AnalisisConfig; fallback al primer nodo de la lista
	local inicio = E.nodoInicio
	if not inicio or not table.find(nodos, inicio) then
		inicio = nodos[1]
	end

	local pesosFn = nil
	if E.algoActual == "dijkstra" or E.algoActual == "prim" then
		pesosFn = function(a, b) return GrafoHelpers.obtenerPeso(E.matrizData, a, b, 1) end
	end

	if E.algoActual == "dijkstra" then
		E.pasos = fn(nodos, E.adyacencias, inicio, pesosFn, E.nodoFin)
	elseif pesosFn then
		E.pasos = fn(nodos, E.adyacencias, inicio, pesosFn)
	else
		E.pasos = fn(nodos, E.adyacencias, inicio)
	end
	E.totalPasos = #E.pasos
	E.pasoActual = 1

	-- Mostrar intro pedagógica del algoritmo en la descripción inicial
	PanelEstadoAnalisis.mostrarIntroAlgo(E.algoActual, inicio)

	if E.totalPasos > 0 then
		PanelEstadoAnalisis.aplicarPaso(E.pasos[E.pasoActual])
	end

	print(string.format("[ModuloAnalisis] %s desde '%s' — %d pasos sobre %d nodos",
		E.algoActual:upper(), inicio, E.totalPasos, #nodos))
end

-- ════════════════════════════════════════════════════════════════
-- SELECCIONAR ALGORITMO
-- ════════════════════════════════════════════════════════════════
local function seleccionarAlgo(algo)
	-- Si el usuario cambia manualmente de algoritmo durante una validación,
	-- cancelamos el modo validación para no restaurar un algoritmo obsoleto al cerrar.
	if E.algoOriginalValidacion then
		E.modoValidacion         = false
		E.validacionTerminada    = false
		E.algoOriginalValidacion = nil
	end

	E.algoActual = algo
	PanelEstadoAnalisis.actualizarPills(algo)
	PseudocodigoAnalisis.reconstruirPseudocodigo(algo)
	if E.matrizData then ejecutarAlgoritmo() end
end

-- ════════════════════════════════════════════════════════════════
-- CARGAR GRAFO COMPLETO DESDE SERVIDOR
-- ════════════════════════════════════════════════════════════════
local function cargarGrafoCompleto(zona, onExito, onFallo)
	local fn = getGrafoCompletoFunc()
	if not fn then
		if onFallo then onFallo("GetGrafoCompleto no disponible") end
		return
	end
	task.spawn(function()
		local ok, datos = pcall(function() return fn:InvokeServer(zona) end)
		if ok and datos and not datos.SinZona and #datos.Headers > 0 then
			E.matrizData      = datos
			E.idealMatrizData = datos
			E.adyacencias     = buildAdyacencias(datos, false)
			E.adyacenciasVisuales = nil
			E.nodosDaniados   = datos.NodosDaniados or {}
			if onExito then onExito() end
		else
			if onFallo then onFallo("Sin datos para zona: " .. zona) end
		end
	end)
end

-- ════════════════════════════════════════════════════════════════
-- HELPER: limpiar estado visual
-- ════════════════════════════════════════════════════════════════
local function limpiarEstadoVisual()
	detenerAutoPlay()
	ViewportAnalisis.limpiarParticulas()
	for _, p in ipairs(E.aristaParts) do if p and p.Parent then p:Destroy() end end
	E.aristaParts     = {}
	if E.worldModel then E.worldModel:ClearAllChildren() end
	E.nodoParts       = {}
	E.posicionesNodos = {}
	E.matrizData      = nil
	E.adyacencias     = {}
	E.pasos           = {}
	E.pasoActual      = 0
	E.totalPasos      = 0
	E.modoValidacion  = false
	E.nodosDaniados   = {}
	E.nodosReparados  = {}
	E.camOffsetX      = 0
	E.camOffsetZ      = 0
	E.camZoom         = 1
end

-- ════════════════════════════════════════════════════════════════
-- API PÚBLICA
-- ════════════════════════════════════════════════════════════════

local function crearBotonesNavegacion()
	if not E.visor then return end

	local function crearBoton(parent, nombre, texto, pos, size)
		local btn = Instance.new("TextButton")
		btn.Name = nombre
		btn.Text = texto
		btn.Size = size
		btn.Position = pos
		btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.TextSize = 18
		btn.Font = Enum.Font.GothamBold
		btn.AutoButtonColor = true
		btn.Parent = parent
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = btn
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(90, 90, 100)
		stroke.Thickness = 1
		stroke.Parent = btn
		return btn
	end

	local navFrame = Instance.new("Frame")
	navFrame.Name = "ControlesNavegacion"
	navFrame.Size = UDim2.new(0, 155, 0, 74)
	navFrame.Position = UDim2.new(1, -165, 1, -84)
	navFrame.BackgroundTransparency = 0.4
	navFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	navFrame.BorderSizePixel = 0
	navFrame.Parent = E.visor
	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 8)
	frameCorner.Parent = navFrame

	local s = UDim2.new(0, 36, 0, 30)
	local z = UDim2.new(0, 30, 0, 28)

	crearBoton(navFrame, "BtnNavIzq", "←", UDim2.new(0, 4, 0, 22), s)
	crearBoton(navFrame, "BtnNavArr", "↑", UDim2.new(0, 42, 0, 4), s)
	crearBoton(navFrame, "BtnNavAba", "↓", UDim2.new(0, 42, 0, 40), s)
	crearBoton(navFrame, "BtnNavDer", "→", UDim2.new(0, 80, 0, 22), s)
	crearBoton(navFrame, "BtnZoomMas", "+", UDim2.new(0, 122, 0, 4), z)
	crearBoton(navFrame, "BtnZoomMen", "-", UDim2.new(0, 122, 0, 40), z)

	local function mover(dx, dz)
		if not E.camAnalisis then return end
		E.camOffsetX = E.camOffsetX + dx
		E.camOffsetZ = E.camOffsetZ + dz
		ViewportAnalisis.aplicarCamara()
	end
	local function zoom(factor)
		if not E.camAnalisis then return end
		E.camZoom = math.clamp(E.camZoom * factor, C.ZOOM_MIN, C.ZOOM_MAX)
		ViewportAnalisis.aplicarCamara()
	end

	navFrame:WaitForChild("BtnNavIzq").MouseButton1Click:Connect(function() mover(-C.PAN_STEP, 0) end)
	navFrame:WaitForChild("BtnNavArr").MouseButton1Click:Connect(function() mover(0, -C.PAN_STEP) end)
	navFrame:WaitForChild("BtnNavAba").MouseButton1Click:Connect(function() mover(0, C.PAN_STEP) end)
	navFrame:WaitForChild("BtnNavDer").MouseButton1Click:Connect(function() mover(C.PAN_STEP, 0) end)
	navFrame:WaitForChild("BtnZoomMas").MouseButton1Click:Connect(function() zoom(1 - C.ZOOM_STEP) end)
	navFrame:WaitForChild("BtnZoomMen").MouseButton1Click:Connect(function() zoom(1 + C.ZOOM_STEP) end)
end

function ModuloAnalisis.inicializar(hudGui)
	E.hudGui = hudGui

	E.overlay = hudGui:FindFirstChild("OverlayAnalisis", true)
	if not E.overlay then
		warn("[ModuloAnalisis] OverlayAnalisis no encontrado")
		return
	end
	E.overlay.Visible = false

	-- ViewportFrame
	E.visor = C.buscar(E.overlay, "VisorGrafoAna")
	if E.visor then
		E.worldModel = E.visor:FindFirstChild("WorldModel")
		if not E.worldModel then
			E.worldModel        = Instance.new("WorldModel")
			E.worldModel.Parent = E.visor
		end
		E.camAnalisis = E.visor.CurrentCamera
		if not E.camAnalisis then
			E.camAnalisis             = Instance.new("Camera")
			E.camAnalisis.FieldOfView = 70
			E.camAnalisis.Parent      = E.visor
			E.visor.CurrentCamera     = E.camAnalisis
		end
	else
		warn("[ModuloAnalisis] VisorGrafoAna no encontrado")
	end

	-- Botones de navegación del viewport
	crearBotonesNavegacion()

	-- Pills de algoritmo
	for algo, _ in pairs(PanelEstadoAnalisis.PILL_NAMES) do
		local pill = C.buscar(E.overlay, PanelEstadoAnalisis.PILL_NAMES[algo])
		if pill then
			local a = algo
			pill.MouseButton1Click:Connect(function() seleccionarAlgo(a) end)
		end
	end

	-- BtnEjecutarAlgo → toggle auto-play
	local btnEjec = C.buscar(E.overlay, "BtnEjecutarAlgo")
	if btnEjec then
		E.btnEjecRef = btnEjec
		btnEjec.MouseButton1Click:Connect(function()
			if not E.abierto then return end
			
			-- Si el usuario viene de terminar una validación y presiona "Ejecutar", restablecemos el grafo completo
			if E.validacionTerminada then
				E.modoValidacion      = false
				E.validacionTerminada = false
				
				if E.idealMatrizData then
					E.matrizData = E.idealMatrizData
				end
				
				E.adyacencias         = buildAdyacencias(E.matrizData, false)
				E.adyacenciasVisuales = nil
				
				PanelEstadoAnalisis.mostrarMensajeDesc("Restaurando simulación de grafo ideal...")
				ViewportAnalisis.construirViewport()
				ejecutarAlgoritmo()
				iniciarAutoPlay()
				return
			end
			
			if E.totalPasos == 0 then
				local zona = jugador:GetAttribute("ZonaActual") or ""
				if zona == "" then
					PanelEstadoAnalisis.mostrarMensajeDesc("Entra en una zona para analizar su grafo.")
					return
				end
				PanelEstadoAnalisis.mostrarMensajeDesc("Cargando datos…")
				cargarGrafoCompleto(zona,
					function()
						ViewportAnalisis.construirViewport()
						ejecutarAlgoritmo()
					end,
					function(msg) PanelEstadoAnalisis.mostrarMensajeDesc(msg) end
				)
			else
				iniciarAutoPlay()
			end
		end)
	end

	-- Boton Validar Nodos Aislados
	if btnEjec then
		local btnValidar = btnEjec.Parent:FindFirstChild("BtnValidarAislados")
		if not btnValidar then
			btnValidar = btnEjec:Clone()
			btnValidar.Name = "BtnEjecutarProbarRed"
			btnValidar.Text = "Ejecutar/Probar Red"
			btnValidar.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
			btnValidar.Parent = btnEjec.Parent
			-- Si usa UIListLayout, solo cambiamos el LayoutOrder
			btnValidar.LayoutOrder = (btnEjec.LayoutOrder or 0) + 1
			-- Si no usa UIListLayout, lo colocamos a la izquierda del boton de Ejecutar
			if not btnEjec.Parent:FindFirstChildOfClass("UIListLayout") then
				btnValidar.Size = UDim2.new(0, 160, btnEjec.Size.Y.Scale, btnEjec.Size.Y.Offset)
				btnValidar.Position = UDim2.new(
					btnEjec.Position.X.Scale, 
					btnEjec.Position.X.Offset - 180, 
					btnEjec.Position.Y.Scale, 
					btnEjec.Position.Y.Offset
				)
			end
		end
		
		btnValidar.MouseButton1Click:Connect(function()
			if not E.abierto or not E.matrizData then return end
			detenerAutoPlay()
			
			PanelEstadoAnalisis.mostrarMensajeDesc("Obteniendo topología real de conexiones...")
			
			-- Usar explícitamente GetAdjacencyMatrix para obtener las conexiones REALES armadas por el jugador
			local rf = RS:WaitForChild("EventosGrafosV3"):WaitForChild("Remotos"):WaitForChild("GetAdjacencyMatrix")
			task.spawn(function()
				local zona = jugador:GetAttribute("ZonaActual") or ""
				local ok, realData = pcall(function() return rf:InvokeServer(zona) end)
				
				if ok and realData and not realData.SinZona then
					-- Guardar algoritmo activo y forzar BFS para la validación de conectividad
					E.algoOriginalValidacion = E.algoActual
					E.algoActual             = "bfs"

					E.modoValidacion      = true
					E.validacionTerminada = false
					E.matrizData          = realData
					E.nodosDaniados       = realData.NodosDaniados or {}
					
					-- Ignora cables defectuosos para el backend
					E.adyacencias         = buildAdyacencias(realData, true) 
					-- Visualmente dibuja todos (incluso defectuosos)
					E.adyacenciasVisuales = buildAdyacencias(realData, false)
					
					ViewportAnalisis.construirViewport()
					
					-- Ejecutamos BFS sobre las adyacencias reales para detectar nodos aislados
					ejecutarAlgoritmo()
					PanelEstadoAnalisis.mostrarMensajeDesc("Validando nodos aislados a partir de tus conexiones...")
					iniciarAutoPlay()
				else
					PanelEstadoAnalisis.mostrarMensajeDesc("Error al obtener la topología física.")
				end
			end)
		end)
	end

	-- Botones cerrar
	local btnCerrar = C.buscar(E.overlay, "BtnCerrarAnalisis")
	if btnCerrar then btnCerrar.MouseButton1Click:Connect(function() ModuloAnalisis.cerrar() end) end
	local btnSalir = C.buscar(E.overlay, "BtnSalirAnalisis")
	if btnSalir then btnSalir.MouseButton1Click:Connect(function() ModuloAnalisis.cerrar() end) end

	-- BtnSiguiente
	local btnSig = C.buscar(E.overlay, "BtnSiguiente")
	if btnSig then
		btnSig.MouseButton1Click:Connect(function()
			if not E.abierto or E.totalPasos == 0 then return end
			detenerAutoPlay()
			if E.pasoActual < E.totalPasos then
				E.pasoActual = E.pasoActual + 1
				PanelEstadoAnalisis.aplicarPaso(E.pasos[E.pasoActual])
			end
		end)
	end

	-- BtnAnterior
	local btnAnt = C.buscar(E.overlay, "BtnAnterior")
	if btnAnt then
		btnAnt.MouseButton1Click:Connect(function()
			if not E.abierto or E.totalPasos == 0 then return end
			detenerAutoPlay()
			if E.pasoActual > 1 then
				E.pasoActual = E.pasoActual - 1
				PanelEstadoAnalisis.aplicarPaso(E.pasos[E.pasoActual])
			end
		end)
	end

	-- Cambio de zona → recargar grafo y config
	jugador:GetAttributeChangedSignal("ZonaActual"):Connect(function()
		if not E.abierto then return end
		limpiarEstadoVisual()
		local zona = jugador:GetAttribute("ZonaActual") or ""
		if zona == "" then
			PanelEstadoAnalisis.mostrarMensajeDesc("Entra en una zona para ver el análisis.")
			PanelEstadoAnalisis.actualizarScrollEstado(nil)
			return
		end
		cargarAnalisisConfig(zona)
		PanelEstadoAnalisis.mostrarMensajeDesc("Cargando zona: " .. zona .. "…")
		cargarGrafoCompleto(zona,
			function()
				ViewportAnalisis.construirViewport()
				seleccionarAlgo(E.algoActual)
			end,
			function(msg) PanelEstadoAnalisis.mostrarMensajeDesc(msg) end
		)
	end)

	-- AnalisisBtn en SelectorModos
	local selectorModos = hudGui:FindFirstChild("SelectorModos", true)
	if selectorModos then
		local analisisBtn = selectorModos:FindFirstChild("AnalisisBtn")
		if analisisBtn then
			analisisBtn.MouseButton1Click:Connect(function()
				if E.abierto then ModuloAnalisis.cerrar() else ModuloAnalisis.abrir() end
			end)
		end
	end

	PanelEstadoAnalisis.actualizarPills(E.algoActual)
	PseudocodigoAnalisis.reconstruirPseudocodigo(E.algoActual)

	-- Escuchar reparacion de nodos (TG 07)
	local ok2, remotos = pcall(function()
		return RS:WaitForChild("EventosGrafosV3", 10):WaitForChild("Remotos", 5)
	end)
	if ok2 and remotos then
		local notifyEvent = remotos:FindFirstChild("NotificarSeleccionNodo")
		if notifyEvent then
			notifyEvent.OnClientEvent:Connect(function(tipo, arg1)
				if tipo == "NodoReparado" then
					local nombre = type(arg1) == "string" and arg1 or nil
					if nombre then
						E.nodosReparados[nombre] = true
						print("[ModuloAnalisis] Nodo reparado:", nombre)
						-- Refrescar viewport si esta abierto
						if E.abierto and E.worldModel then
							ViewportAnalisis.construirViewport()
							if E.totalPasos > 0 and E.pasos[E.pasoActual] then
								ViewportAnalisis.reconstruirAristas(E.pasos[E.pasoActual])
							end
						end
					end
				end
			end)
		end
	end

	print("[ModuloAnalisis] Inicializado ✅")
end

function ModuloAnalisis.configurarNivel(nivelModelParam, nivelIDParam, _configNivel)
	E.nivelModel = nivelModelParam
	E.nivelID    = nivelIDParam
end

function ModuloAnalisis.abrir()
	if not E.overlay then
		warn("[ModuloAnalisis] Overlay no disponible")
		return
	end

	E.abierto         = true
	E.overlay.Visible = true

	local zona = jugador:GetAttribute("ZonaActual") or ""
	if zona == "" then
		PanelEstadoAnalisis.mostrarMensajeDesc("Entra en una zona para ver el análisis de su grafo.")
		PanelEstadoAnalisis.actualizarScrollEstado(nil)
		return
	end

	-- Cargar config de la zona antes de ejecutar
	cargarAnalisisConfig(zona)
	PanelEstadoAnalisis.mostrarMensajeDesc("Cargando grafo completo…")

	cargarGrafoCompleto(zona,
		function()
			ViewportAnalisis.construirViewport()
			seleccionarAlgo(E.algoActual)
		end,
		function(msg)
			E.matrizData = nil
			PanelEstadoAnalisis.mostrarMensajeDesc(msg)
			PanelEstadoAnalisis.actualizarScrollEstado(nil)
		end
	)

	print("[ModuloAnalisis] Abierto — zona:", zona)
end

function ModuloAnalisis.cerrar()
	detenerAutoPlay()

	-- Si se cierra durante una validación, restaurar el algoritmo original
	if E.algoOriginalValidacion then
		E.algoActual = E.algoOriginalValidacion
		E.algoOriginalValidacion = nil
		PanelEstadoAnalisis.actualizarPills(E.algoActual)
		PseudocodigoAnalisis.reconstruirPseudocodigo(E.algoActual)
	end

	E.abierto = false
	if E.overlay then E.overlay.Visible = false end
	print("[ModuloAnalisis] Cerrado")
end

function ModuloAnalisis.limpiar()
	limpiarEstadoVisual()
	E.nivelModel = nil
	E.nivelID    = nil
	if E.overlay then E.overlay.Visible = false end
	E.abierto = false
	print("[ModuloAnalisis] Limpiado")
end

function ModuloAnalisis.estaAbierto()
	return E.abierto
end

return ModuloAnalisis