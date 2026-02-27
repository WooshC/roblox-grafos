-- StarterPlayerScripts/HUD/ModulosHUD/ModuloMapa.lua
-- Modulo de Mapa Cenital para GrafosV3
-- Corregido: efectos visuales, nombres amigables, cierre correcto

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EfectosNodo = require(ReplicatedStorage.Efectos.EfectosNodo)
local PresetTween = require(ReplicatedStorage.Efectos.PresetTween)
local LevelsConfig = require(ReplicatedStorage.Config.LevelsConfig)

local ModuloMapa = {}

-- Estado
local estaActivo = false
local mapaAbierto = false
local nivelActual = nil
local nivelID = 0
local configNivel = nil
local nombresNodos = {}
local selectores = {}
local conexionRender = nil
local conexionInput = nil
local conexionVictoria = nil
local camara = workspace.CurrentCamera
local jugador = Players.LocalPlayer

-- Referencias UI
local hudGui = nil
local frameMapa = nil
local btnMapa = nil
local btnCerrarMapa = nil

-- Estado de camara
local estadoCamaraOriginal = nil
local techosOriginales = {}
local techosCapturados = false

-- Estado de selección en el mapa
local nodoSeleccionadoMapa = nil
local highlights = {}
local billboards = {}

-- Configuracion
local CONFIG = {
	alturaCamara = 80,
	velocidadTween = 0.4,
	maxDistanciaRaycast = 1000
}

-- ================================================================
-- INICIALIZACION
-- ================================================================

function ModuloMapa.inicializar(hudRef)
	hudGui = hudRef
	
	-- Buscar referencias UI
	frameMapa = hudGui:FindFirstChild("PantallaMapaGrande", true)
	btnMapa = hudGui:FindFirstChild("BtnMapa", true)
	
	if frameMapa then
		btnCerrarMapa = frameMapa:FindFirstChild("BtnCerrarMapa", true)
	end
	
	-- Configurar botones
	_conectarBotones()
	
	-- Conectar a evento de victoria para cerrar mapa automáticamente
	local eventosFolder = ReplicatedStorage:FindFirstChild("EventosGrafosV3")
	if eventosFolder then
		local nivelCompletado = eventosFolder.Remotos:FindFirstChild("NivelCompletado")
		if nivelCompletado then
			conexionVictoria = nivelCompletado.OnClientEvent:Connect(function()
				print("[ModuloMapa] Nivel completado - cerrando mapa automáticamente")
				ModuloMapa.cerrar()
			end)
		end
	end
	
	-- Inicialmente oculto
	if frameMapa then
		frameMapa.Visible = false
	end
	
	estaActivo = true
	print("[ModuloMapa] Inicializado")
end

function _conectarBotones()
	-- Boton principal de mapa (toggle)
	if btnMapa then
		btnMapa.MouseButton1Click:Connect(function()
			if mapaAbierto then
				ModuloMapa.cerrar()
			else
				ModuloMapa.abrir()
			end
		end)
	end
	
	-- Boton cerrar dentro del mapa
	if btnCerrarMapa then
		btnCerrarMapa.MouseButton1Click:Connect(ModuloMapa.cerrar)
	end
end

-- ================================================================
-- CONFIGURACION DEL NIVEL
-- ================================================================

function ModuloMapa.configurarNivel(nivelModel, id, config)
	nivelActual = nivelModel
	nivelID = id
	configNivel = config
	nombresNodos = {}
	selectores = {}
	
	-- Cargar nombres amigables desde LevelsConfig
	if config and config.NombresNodos then
		nombresNodos = config.NombresNodos
	elseif LevelsConfig[id] and LevelsConfig[id].NombresNodos then
		nombresNodos = LevelsConfig[id].NombresNodos
	end
	
	-- NOTA: No recolectamos selectores aquí para evitar interferencias
	-- Los selectores se recolectan solo cuando se abre el mapa
end

function _collectarSelectores()
	selectores = {}
	
	if not nivelActual then return end
	
	local grafosFolder = nivelActual:FindFirstChild("Grafos")
	if not grafosFolder then return end
	
	for _, grafo in ipairs(grafosFolder:GetChildren()) do
		local nodosFolder = grafo:FindFirstChild("Nodos")
		if nodosFolder then
			for _, nodo in ipairs(nodosFolder:GetChildren()) do
				local selector = nodo:FindFirstChild("Selector")
				if selector then
					if selector:IsA("BasePart") then
						table.insert(selectores, selector)
					elseif selector:IsA("Model") then
						-- Buscar parte física dentro del modelo
						for _, part in ipairs(selector:GetDescendants()) do
							if part:IsA("BasePart") then
								table.insert(selectores, part)
								break
							end
						end
					end
				end
			end
		end
	end
	
	print("[ModuloMapa] Selectores collectados:", #selectores)
end

-- ================================================================
-- GESTION DEL TECHO
-- ================================================================

function _capturarTechos()
	if techosCapturados then return end
	if not nivelActual then return end
	
	techosOriginales = {}
	
	-- Buscar en estructura: Escenario/Colisionadores/Techos
	local escenario = nivelActual:FindFirstChild("Escenario")
	if escenario then
		local colisionadores = escenario:FindFirstChild("Colisionadores")
		if colisionadores then
			local techosFolder = colisionadores:FindFirstChild("Techos")
			if techosFolder then
				for _, part in ipairs(techosFolder:GetChildren()) do
					if part:IsA("BasePart") then
						techosOriginales[part] = {
							Transparency = part.Transparency,
							CastShadow = part.CastShadow,
							CanQuery = part.CanQuery
						}
					end
				end
			end
		end
	end
	
	-- Fallback: buscar folder Techos directo
	if next(techosOriginales) == nil then
		local techosFolder = nivelActual:FindFirstChild("Techos")
		if techosFolder then
			for _, part in ipairs(techosFolder:GetChildren()) do
				if part:IsA("BasePart") then
					techosOriginales[part] = {
						Transparency = part.Transparency,
						CastShadow = part.CastShadow,
						CanQuery = part.CanQuery
					}
				end
			end
		end
	end
	
	techosCapturados = true
end

function _ocultarTechos()
	if not techosCapturados then return end
	
	for part, orig in pairs(techosOriginales) do
		if part and part.Parent then
			part.Transparency = 0.95
			part.CastShadow = false
			part.CanQuery = false
		end
	end
end

function _mostrarTechos()
	for part, orig in pairs(techosOriginales) do
		if part and part.Parent then
			part.Transparency = orig.Transparency
			part.CastShadow = orig.CastShadow
			part.CanQuery = orig.CanQuery
		end
	end
end

function _resetearTechos()
	techosOriginales = {}
	techosCapturados = false
end

-- ================================================================
-- EFECTOS VISUALES DEL MAPA
-- ================================================================

function _obtenerNombreAmigable(nombreNodo)
	return nombresNodos[nombreNodo] or nombreNodo
end

function _crearHighlight(nodo, color, esSeleccionado)
	local decoracion = nodo:FindFirstChild("Decoracion")
	if not decoracion then return nil end
	
	local highlight = Instance.new("Highlight")
	highlight.Name = "MapaHighlight_" .. nodo.Name
	highlight.Adornee = decoracion
	highlight.FillColor = color
	highlight.FillTransparency = esSeleccionado and 0.2 or 0.5
	highlight.OutlineColor = color
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = workspace
	
	highlights[nodo.Name] = highlight
	
	return highlight
end

function _crearLabelNodo(nodo, color)
	local selector = nodo:FindFirstChild("Selector")
	if not selector then return end
	
	-- Buscar una parte BasePart para el billboard
	local parteAdornar = nil
	if selector:IsA("BasePart") then
		parteAdornar = selector
	elseif selector:IsA("Model") then
		for _, part in ipairs(selector:GetDescendants()) do
			if part:IsA("BasePart") then
				parteAdornar = part
				break
			end
		end
	end
	
	if not parteAdornar then return end
	
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "MapaLabel_" .. nodo.Name
	billboard.Adornee = parteAdornar
	billboard.Size = UDim2.new(0, 150, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = workspace
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = _obtenerNombreAmigable(nodo.Name)
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.3
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.Parent = billboard
	
	billboards[nodo.Name] = billboard
end

function _limpiarHighlights()
	for _, highlight in pairs(highlights) do
		if highlight then highlight:Destroy() end
	end
	highlights = {}
	
	for _, billboard in pairs(billboards) do
		if billboard then billboard:Destroy() end
	end
	billboards = {}
end

function _actualizarHighlights()
	_limpiarHighlights()
	
	if not nivelActual then return end
	if not nodoSeleccionadoMapa then return end
	
	local grafosFolder = nivelActual:FindFirstChild("Grafos")
	if not grafosFolder then return end
	
	local nombreSeleccionado = nodoSeleccionadoMapa.Name
	
	-- Obtener adyacentes
	local adyacentes = {}
	if configNivel and configNivel.Adyacencias then
		adyacentes = configNivel.Adyacencias[nombreSeleccionado] or {}
	end
	
	for _, grafo in ipairs(grafosFolder:GetChildren()) do
		local nodosFolder = grafo:FindFirstChild("Nodos")
		if nodosFolder then
			for _, nodo in ipairs(nodosFolder:GetChildren()) do
				local nombre = nodo.Name
				
				if nombre == nombreSeleccionado then
					-- Nodo seleccionado: Cyan brillante
					_crearHighlight(nodo, Color3.fromRGB(0, 212, 255), true)
					_crearLabelNodo(nodo, Color3.fromRGB(0, 212, 255))
					
				elseif table.find(adyacentes, nombre) then
					-- Nodo adyacente: Dorado
					_crearHighlight(nodo, Color3.fromRGB(255, 200, 50), false)
					_crearLabelNodo(nodo, Color3.fromRGB(255, 200, 50))
				end
			end
		end
	end
end

-- ================================================================
-- CALCULOS DE CAMARA
-- ================================================================

function _guardarEstadoCamara()
	estadoCamaraOriginal = {
		CFrame = camara.CFrame,
		CameraType = camara.CameraType,
		CameraSubject = camara.CameraSubject
	}
end

function _calcularBoundsNivel()
	if not nivelActual then return nil end
	
	local boundsMin = Vector3.new(math.huge, math.huge, math.huge)
	local boundsMax = Vector3.new(-math.huge, -math.huge, -math.huge)
	local conteoPartes = 0
	
	for _, part in ipairs(nivelActual:GetDescendants()) do
		if part:IsA("BasePart") then
			conteoPartes = conteoPartes + 1
			boundsMin = Vector3.new(
				math.min(boundsMin.X, part.Position.X - part.Size.X/2),
				math.min(boundsMin.Y, part.Position.Y - part.Size.Y/2),
				math.min(boundsMin.Z, part.Position.Z - part.Size.Z/2)
			)
			boundsMax = Vector3.new(
				math.max(boundsMax.X, part.Position.X + part.Size.X/2),
				math.max(boundsMax.Y, part.Position.Y + part.Size.Y/2),
				math.max(boundsMax.Z, part.Position.Z + part.Size.Z/2)
			)
		end
	end
	
	if conteoPartes == 0 then return nil end
	
	return {
		Centro = (boundsMin + boundsMax) / 2,
		Tamanio = boundsMax - boundsMin,
		Min = boundsMin,
		Max = boundsMax
	}
end

function _calcularCFrameCenital(bounds)
	if not bounds then return nil end
	
	local altura = math.max(bounds.Tamanio.X, bounds.Tamanio.Z) * 0.6 + 30
	
	return CFrame.new(bounds.Centro.X, bounds.Max.Y + altura, bounds.Centro.Z) * 
		CFrame.Angles(math.rad(-90), 0, 0)
end

function _hacerTweenCamara(cframeObjetivo, onComplete)
	camara.CameraType = Enum.CameraType.Scriptable
	
	local tween = TweenService:Create(camara, TweenInfo.new(
		CONFIG.velocidadTween, 
		Enum.EasingStyle.Cubic, 
		Enum.EasingDirection.InOut
	), {
		CFrame = cframeObjetivo
	})
	
	if onComplete then
		tween.Completed:Once(onComplete)
	end
	
	tween:Play()
	return tween
end

function _iniciarSeguimientoJugador()
	if conexionRender then
		conexionRender:Disconnect()
	end
	
	conexionRender = RunService.RenderStepped:Connect(function()
		if not mapaAbierto then return end
		
		local personaje = jugador.Character
		local root = personaje and personaje:FindFirstChild("HumanoidRootPart")
		if not root then return end
		
		local pos = root.Position
		camara.CFrame = CFrame.new(
			pos.X, 
			pos.Y + CONFIG.alturaCamara, 
			pos.Z
		) * CFrame.Angles(math.rad(-90), 0, 0)
	end)
end

function _detenerSeguimiento()
	if conexionRender then
		conexionRender:Disconnect()
		conexionRender = nil
	end
end

-- ================================================================
-- INPUT Y SELECCION DE NODOS
-- ================================================================

function _iniciarEscuchaInput()
	if conexionInput then
		conexionInput:Disconnect()
		conexionInput = nil
	end
	
	if #selectores == 0 then
		warn("[ModuloMapa] No hay selectores para escuchar input")
		return
	end
	
	conexionInput = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		if not mapaAbierto then return end
		if camara.CameraType ~= Enum.CameraType.Scriptable then return end
		
		local mousePos = UserInputService:GetMouseLocation()
		local ray = camara:ViewportPointToRay(mousePos.X, mousePos.Y)
		
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = selectores
		
		local resultado = workspace:Raycast(ray.Origin, ray.Direction * CONFIG.maxDistanciaRaycast, params)
		
		if resultado and resultado.Instance then
			local selectorPart = resultado.Instance
			local nodo = _obtenerNodoDesdeSelector(selectorPart)
			
			if nodo then
				_onNodoClickeado(nodo, selectorPart)
			end
		end
	end)
end

function _detenerEscuchaInput()
	if conexionInput then
		conexionInput:Disconnect()
		conexionInput = nil
	end
end

function _obtenerNodoDesdeSelector(selectorPart)
	local nodo = selectorPart:FindFirstAncestorOfClass("Model")
	while nodo and not nodo:FindFirstChild("Selector") do
		nodo = nodo.Parent
		if nodo == nivelActual then
			return nil
		end
	end
	return nodo
end

function _onNodoClickeado(nodo, selectorPart)
	local nombreNodo = nodo.Name
	
	-- Lógica de selección de dos nodos para conexión
	if nodoSeleccionadoMapa == nil then
		-- Primer nodo seleccionado
		nodoSeleccionadoMapa = nodo
		_actualizarHighlights()
		
		-- Notificar al servidor
		local eventosFolder = ReplicatedStorage:FindFirstChild("EventosGrafosV3")
		if eventosFolder then
			local notificarEvent = eventosFolder.Remotos:FindFirstChild("MapaClickNodo")
			if notificarEvent then
				notificarEvent:FireServer(nombreNodo)
			end
		end
		
		print("[ModuloMapa] Primer nodo seleccionado:", nombreNodo)
		
	elseif nodoSeleccionadoMapa == nodo then
		-- Click en el mismo nodo: cancelar selección
		nodoSeleccionadoMapa = nil
		_limpiarHighlights()
		
		print("[ModuloMapa] Selección cancelada")
		
	else
		-- Segundo nodo seleccionado: intentar conectar
		local nodoA = nodoSeleccionadoMapa.Name
		local nodoB = nombreNodo
		
		print("[ModuloMapa] Intentando conectar:", nodoA, "->", nodoB)
		
		-- Enviar solicitud de conexión al servidor
		local eventosFolder = ReplicatedStorage:FindFirstChild("EventosGrafosV3")
		if eventosFolder then
			local conectarEvent = eventosFolder.Remotos:FindFirstChild("ConectarDesdeMapa")
			if conectarEvent then
				conectarEvent:FireServer(nodoA, nodoB)
			end
		end
		
		-- Limpiar selección
		nodoSeleccionadoMapa = nil
		_limpiarHighlights()
	end
end

-- ================================================================
-- API PUBLICA - ABRIR / CERRAR
-- ================================================================

function ModuloMapa.abrir()
	if mapaAbierto then return end
	if not frameMapa then
		warn("[ModuloMapa] Frame del mapa no encontrado")
		return
	end
	if not nivelActual then
		warn("[ModuloMapa] No hay nivel configurado")
		return
	end
	
	-- Recolectar selectores SOLO cuando se abre el mapa
	_collectarSelectores()
	
	if #selectores == 0 then
		warn("[ModuloMapa] No hay selectores para interactuar")
		return
	end
	
	mapaAbierto = true
	
	-- Cambiar texto del boton
	if btnMapa then
		btnMapa.Text = "❌ CERRAR"
	end
	
	-- Mostrar frame
	frameMapa.Visible = true
	
	-- Guardar estado de camara
	_guardarEstadoCamara()
	
	-- Capturar y ocultar techos
	_capturarTechos()
	_ocultarTechos()
	
	-- Calcular posicion cenital
	local bounds = _calcularBoundsNivel()
	local cframeCenital = _calcularCFrameCenital(bounds)
	
	if cframeCenital then
		_hacerTweenCamara(cframeCenital, function()
			_iniciarSeguimientoJugador()
		end)
	end
	
	-- Iniciar escucha de input
	_iniciarEscuchaInput()
	
	print("[ModuloMapa] Mapa abierto")
end

function ModuloMapa.cerrar()
	if not mapaAbierto then return end
	
	print("[ModuloMapa] Cerrando mapa...")
	
	mapaAbierto = false
	nodoSeleccionadoMapa = nil
	
	-- Cambiar texto del boton
	if btnMapa then
		btnMapa.Text = "🗺️ MAPA"
	end
	
	-- Detener seguimiento e input
	_detenerSeguimiento()
	_detenerEscuchaInput()
	
	-- Limpiar highlights
	_limpiarHighlights()
	
	-- Limpiar selección
	pcall(function()
		EfectosNodo.limpiarSeleccion()
	end)
	
	-- Mostrar techos
	_mostrarTechos()
	
	-- Restaurar camara con tween
	if estadoCamaraOriginal then
		local exito, err = pcall(function()
			_hacerTweenCamara(estadoCamaraOriginal.CFrame, function()
				camara.CameraType = estadoCamaraOriginal.CameraType
				camara.CameraSubject = estadoCamaraOriginal.CameraSubject
			end)
		end)
		
		if not exito then
			-- Fallback: restaurar directamente
			camara.CameraType = estadoCamaraOriginal.CameraType
			camara.CameraSubject = estadoCamaraOriginal.CameraSubject
			camara.CFrame = estadoCamaraOriginal.CFrame
		end
	end
	
	-- Ocultar frame
	if frameMapa then
		frameMapa.Visible = false
	end
	
	print("[ModuloMapa] Mapa cerrado")
end

function ModuloMapa.estaAbierto()
	return mapaAbierto
end

-- ================================================================
-- LIMPIEZA
-- ================================================================

function ModuloMapa.limpiar()
	print("[ModuloMapa] Iniciando limpieza...")
	
	-- Cerrar mapa si está abierto
	if mapaAbierto then
		ModuloMapa.cerrar()
	end
	
	-- Desconectar conexiones
	if conexionVictoria then
		conexionVictoria:Disconnect()
		conexionVictoria = nil
	end
	
	_detenerSeguimiento()
	_detenerEscuchaInput()
	_limpiarHighlights()
	
	-- Limpiar estado
	nodoSeleccionadoMapa = nil
	nivelActual = nil
	nivelID = 0
	configNivel = nil
	nombresNodos = {}
	selectores = {}
	estadoCamaraOriginal = nil
	_resetearTechos()
	
	estaActivo = false
	
	print("[ModuloMapa] Limpieza completada")
end

return ModuloMapa
