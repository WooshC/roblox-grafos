-- StarterPlayerScripts/HUD/ModulosHUD/ModuloMapa.lua
-- Modulo de Mapa Cenital para GrafosV3
-- Adaptado desde GrafosV2/HUDMapa con arquitectura simplificada

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EfectosNodo = require(ReplicatedStorage.Efectos.EfectosNodo)
local PresetTween = require(ReplicatedStorage.Efectos.PresetTween)

local ModuloMapa = {}

-- Estado
local estaActivo = false
local mapaAbierto = false
local nivelActual = nil
local nivelID = 0
local configNivel = nil
local selectores = {}
local conexionRender = nil
local conexionInput = nil
local camara = workspace.CurrentCamera
local jugador = Players.LocalPlayer

-- Referencias UI
local hudGui = nil
local frameMapa = nil
local btnMapa = nil
local btnCerrarMapa = nil
local btnMisionesEnMapa = nil
local btnMatematico = nil

-- Estado de camara
local estadoCamaraOriginal = nil
local techosOriginales = {}
local techosCapturados = false

-- Estado de conexion en el mapa
local nodoSeleccionadoMapa = nil  -- Primer nodo seleccionado en el mapa
local highlights = {}  -- Tabla de highlights creados

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
	
	-- Buscar referencias UI segun estructura GUIExploradorV2
	frameMapa = hudGui:FindFirstChild("PantallaMapaGrande", true)
	btnMapa = hudGui:FindFirstChild("BtnMapa", true)
	
	if frameMapa then
		btnCerrarMapa = frameMapa:FindFirstChild("BtnCerrarMapa", true)
		btnMisionesEnMapa = frameMapa:FindFirstChild("BtnMisionesEnMapa", true)
		btnMatematico = frameMapa:FindFirstChild("BtnMatematico", true)
	end
	
	-- Configurar botones
	_conectarBotones()
	
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
	
	-- Boton misiones en mapa (placeholder)
	if btnMisionesEnMapa then
		btnMisionesEnMapa.MouseButton1Click:Connect(function()
			print("[ModuloMapa] BtnMisionesEnMapa clickeado")
			-- TODO: Integrar con PanelMisionesHUD
		end)
	end
	
	-- Boton matematico (placeholder)
	if btnMatematico then
		btnMatematico.MouseButton1Click:Connect(function()
			print("[ModuloMapa] BtnMatematico clickeado")
			-- TODO: Mostrar panel de matriz de adyacencia
		end)
	end
end

-- ================================================================
-- CONFIGURACION DEL NIVEL
-- ================================================================

function ModuloMapa.configurarNivel(nivelModel, id, config)
	nivelActual = nivelModel
	nivelID = id
	configNivel = config
	selectores = {}
	
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
						-- El Selector es directamente una BasePart
						table.insert(selectores, selector)
					elseif selector:IsA("Model") then
						-- El Selector es un Model - buscar cualquier BasePart dentro de él
						-- que NO sea solo un Attachment
						local parteEncontrada = nil
						
						-- Primero buscar una parte llamada "Hitbox", "ClickBox" o similar
						for _, part in ipairs(selector:GetDescendants()) do
							if part:IsA("BasePart") then
								if part.Name:lower():match("hitbox") or 
								   part.Name:lower():match("click") or
								   part.Name:lower():match("selector") then
									parteEncontrada = part
									break
								end
							end
						end
						
						-- Si no encontramos parte específica, tomar la primera BasePart
						if not parteEncontrada then
							for _, part in ipairs(selector:GetDescendants()) do
								if part:IsA("BasePart") then
									parteEncontrada = part
									break
								end
							end
						end
						
						if parteEncontrada then
							table.insert(selectores, parteEncontrada)
						else
							-- Si no hay parte, agregar el modelo mismo (para debug)
							warn("[ModuloMapa] Selector sin BasePart:", nodo.Name)
						end
					end
				end
			end
		end
	end
	
	print("[ModuloMapa] Selectores collectados:", #selectores)
	
	-- Debug: listar selectores encontrados
	for i, sel in ipairs(selectores) do
		print(string.format("  [%d] %s (tipo: %s)", i, sel.Name, sel.ClassName))
	end
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
		
		-- Buscar por nombre
		for _, part in ipairs(nivelActual:GetDescendants()) do
			if part:IsA("BasePart") and (part.Name:lower():find("techo") or part.Name:lower():find("roof")) then
				if not techosOriginales[part] then
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
	print("[ModuloMapa] Techos capturados:", #techosOriginales)
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
	
	print("[ModuloMapa] Techos ocultados")
end

function _mostrarTechos()
	for part, orig in pairs(techosOriginales) do
		if part and part.Parent then
			part.Transparency = orig.Transparency
			part.CastShadow = orig.CastShadow
			part.CanQuery = orig.CanQuery
		end
	end
	
	print("[ModuloMapa] Techos restaurados")
end

function _resetearTechos()
	techosOriginales = {}
	techosCapturados = false
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
		
		-- Mantener camara cenital pero seguir al jugador horizontalmente
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
-- EFECTOS VISUALES DEL MAPA (sin modificar selectores físicos)
-- ================================================================

local _highlights = {}  -- Tabla de highlights creados

function _crearHighlight(nodo, color, esSeleccionado)
	local selector = nodo:FindFirstChild("Selector")
	if not selector then return nil end
	
	-- Buscar el adorno apropiado
	local adorno = nil
	if selector:IsA("BasePart") then
		adorno = selector
	elseif selector:IsA("Model") then
		-- Para modelos, usar la parte de decoración o el modelo mismo
		local decoracion = nodo:FindFirstChild("Decoracion")
		if decoracion then
			adorno = decoracion
		else
			adorno = selector
		end
	end
	
	if not adorno then return nil end
	
	local highlight = Instance.new("Highlight")
	highlight.Name = "MapaHighlight_" .. nodo.Name
	highlight.Adornee = adorno
	highlight.FillColor = color
	highlight.FillTransparency = esSeleccionado and 0.3 or 0.6
	highlight.OutlineColor = color
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = workspace
	
	highlights[nodo.Name] = highlight
	
	-- También crear un BillboardGui con el nombre del nodo
	local parteVisible = nil
	if selector:IsA("BasePart") then
		parteVisible = selector
	elseif selector:IsA("Model") then
		-- Buscar una parte visible dentro del selector
		for _, part in ipairs(selector:GetDescendants()) do
			if part:IsA("BasePart") then
				parteVisible = part
				break
			end
		end
	end
	
	if parteVisible then
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "MapaLabel_" .. nodo.Name
		billboard.Adornee = parteVisible
		billboard.Size = UDim2.new(0, 100, 0, 30)
		billboard.StudsOffset = Vector3.new(0, 4, 0)
		billboard.AlwaysOnTop = true
		billboard.Parent = workspace
		
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = nodo.Name
		label.TextColor3 = color
		label.TextStrokeTransparency = 0.5
		label.TextStrokeColor3 = Color3.new(0, 0, 0)
		label.Font = Enum.Font.GothamBold
		label.TextSize = 14
		label.Parent = billboard
		
		highlights[nodo.Name .. "_label"] = billboard
	end
	
	return highlight
end

function _limpiarHighlights()
	for nombre, obj in pairs(highlights) do
		if obj then
			obj:Destroy()
		end
	end
	highlights = {}
end

function _actualizarHighlights()
	_limpiarHighlights()
	
	if not nivelActual then return end
	
	-- Usar el estado local del mapa si existe, sino el de EfectosNodo
	local nodoSel = nodoSeleccionadoMapa and nodoSeleccionadoMapa.Name or EfectosNodo.nodoSeleccionado
	if not nodoSel then return end
	
	-- Crear highlight para el nodo seleccionado (cyan brillante)
	local grafosFolder = nivelActual:FindFirstChild("Grafos")
	if not grafosFolder then return end
	
	for _, grafo in ipairs(grafosFolder:GetChildren()) do
		local nodosFolder = grafo:FindFirstChild("Nodos")
		if nodosFolder then
			for _, nodo in ipairs(nodosFolder:GetChildren()) do
				if nodo.Name == nodoSel then
					_crearHighlight(nodo, Color3.fromRGB(0, 212, 255), true) -- Cyan, seleccionado
				end
				
				-- Verificar si es adyacente
				if EfectosNodo.esAdyacente(nodo.Name) then
					_crearHighlight(nodo, Color3.fromRGB(255, 200, 50), false) -- Dorado, adyacente
				end
			end
		end
	end
end

-- ================================================================
-- INPUT Y SELECCION DE NODOS
-- ================================================================

function _iniciarEscuchaInput()
	-- Desconectar conexión anterior si existe
	if conexionInput then
		conexionInput:Disconnect()
		conexionInput = nil
	end
	
	if #selectores == 0 then
		warn("[ModuloMapa] No hay selectores para escuchar input")
		return
	end
	
	print("[ModuloMapa] Iniciando escucha de input para mapa...")
	
	conexionInput = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		-- Si el juego ya procesó el input (ej: ClickDetector), ignorar
		if gameProcessed then return end
		
		-- Solo procesar clicks izquierdos del mouse
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		
		-- Solo procesar si el mapa está abierto
		if not mapaAbierto then return end
		
		-- Asegurar que la cámara esté en modo Scriptable (modo mapa)
		if camara.CameraType ~= Enum.CameraType.Scriptable then
			return
		end
		
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
				print("[ModuloMapa] Nodo clickeado en mapa:", nodo.Name)
				_onNodoClickeado(nodo, selectorPart)
				-- Marcar el input como procesado para evitar que otros sistemas lo manejen
				-- durante el modo mapa
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
	print("[ModuloMapa] Nodo clickeado:", nombreNodo)
	
	-- Lógica de selección de dos nodos para conexión
	if nodoSeleccionadoMapa == nil then
		-- Primer nodo seleccionado
		nodoSeleccionadoMapa = nodo
		
		-- Mostrar adyacentes para guía visual
		local adyacentes = {}
		if configNivel and configNivel.Adyacencias then
			adyacentes = configNivel.Adyacencias[nombreNodo] or {}
		end
		
		EfectosNodo.establecerSeleccion(nombreNodo, adyacentes)
		_actualizarHighlights()
		
		-- Notificar al servidor sobre la selección (para efectos y misiones)
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
		EfectosNodo.limpiarSeleccion()
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
				print("[ModuloMapa] Solicitud de conexión enviada al servidor")
			else
				warn("[ModuloMapa] Evento ConectarDesdeMapa no encontrado")
			end
		end
		
		-- Limpiar selección
		nodoSeleccionadoMapa = nil
		EfectosNodo.limpiarSeleccion()
		_limpiarHighlights()
	end
end

function _resetearVisualesNodos()
	-- Limpiar solo los highlights, NO modificar los selectores físicos
	_limpiarHighlights()
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
			-- Al completar el tween, iniciar seguimiento
			_iniciarSeguimientoJugador()
		end)
	end
	
	-- Iniciar escucha de input
	_iniciarEscuchaInput()
	
	-- Actualizar highlights
	_actualizarHighlights()
	
	print("[ModuloMapa] Mapa abierto")
end

function ModuloMapa.cerrar()
	if not mapaAbierto then return end
	
	print("[ModuloMapa] Cerrando mapa...")
	
	mapaAbierto = false
	
	-- Cambiar texto del boton
	if btnMapa then
		btnMapa.Text = "🗺️ MAPA"
	end
	
	-- Detener seguimiento e input PRIMERO
	_detenerSeguimiento()
	_detenerEscuchaInput()
	
	-- Limpiar seleccion y visuales
	local exito1, err1 = pcall(function()
		EfectosNodo.limpiarSeleccion()
	end)
	if not exito1 then warn("[ModuloMapa] Error limpiando seleccion:", err1) end
	
	local exito2, err2 = pcall(function()
		_resetearVisualesNodos()
	end)
	if not exito2 then warn("[ModuloMapa] Error reseteando visuales:", err2) end
	
	-- Limpiar estado de selección del mapa
	nodoSeleccionadoMapa = nil
	
	-- Mostrar techos
	local exito3, err3 = pcall(function()
		_mostrarTechos()
	end)
	if not exito3 then warn("[ModuloMapa] Error mostrando techos:", err3) end
	
	-- Restaurar camara con tween
	if estadoCamaraOriginal then
		local exito4, err4 = pcall(function()
			_hacerTweenCamara(estadoCamaraOriginal.CFrame, function()
				camara.CameraType = estadoCamaraOriginal.CameraType
				camara.CameraSubject = estadoCamaraOriginal.CameraSubject
			end)
		end)
		if not exito4 then 
			warn("[ModuloMapa] Error restaurando camara:", err4)
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
	
	if mapaAbierto then
		local exito, err = pcall(function()
			ModuloMapa.cerrar()
		end)
		if not exito then
			warn("[ModuloMapa] Error al cerrar durante limpieza:", err)
			-- Forzar cierre del estado
			mapaAbierto = false
		end
	end
	
	-- Desconectar todo
	_detenerSeguimiento()
	_detenerEscuchaInput()
	
	-- Limpiar estado
	pcall(function()
		EfectosNodo.limpiarSeleccion()
	end)
	
	-- Limpiar highlights
	_limpiarHighlights()
	
	-- Resetear estado de selección del mapa
	nodoSeleccionadoMapa = nil
	
	_resetearTechos()
	
	nivelActual = nil
	nivelID = 0
	configNivel = nil
	selectores = {}
	estadoCamaraOriginal = nil
	estaActivo = false
	
	print("[ModuloMapa] Limpieza completada")
end

return ModuloMapa
