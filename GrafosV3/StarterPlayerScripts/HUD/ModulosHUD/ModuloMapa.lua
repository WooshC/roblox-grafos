-- StarterPlayerScripts/HUD/ModulosHUD/ModuloMapa.lua
-- Modulo de Mapa Cenital para GrafosV3
-- Corregido: efectos visuales, nombres amigables, cierre correcto

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EfectosNodo = require(ReplicatedStorage.Efectos.EfectosNodo)
local EfectosMapa = require(script.Parent.EfectosMapa)
local EfectosZonas = require(script.Parent.EfectosZonas)
local EstadoConexiones = require(script.Parent.EstadoConexiones)
local PresetTween = require(ReplicatedStorage.Efectos.PresetTween)
local LevelsConfig = require(ReplicatedStorage.Config.LevelsConfig)
local ServicioCamara = require(ReplicatedStorage.Compartido.ServicioCamara)
local GestorColisiones = require(ReplicatedStorage.Compartido.GestorColisiones)

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
local conexionZona = nil -- Para escuchar cambios de zona
local camara = workspace.CurrentCamera
local jugador = Players.LocalPlayer

-- Referencias UI
local hudGui = nil
local frameMapa = nil
local btnMapa = nil
local btnCerrarMapa = nil

-- El estado de cámara lo maneja ServicioCamara
-- Los techos los gestiona GestorColisiones (ControladorColisiones.client.lua)
-- Los billboards de zonas los gestiona EfectosZonas

-- Estado de selección en el mapa
local nodoSeleccionadoMapa = nil
local adyacentesSeleccionados = {}

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
		
		-- Escuchar cambios de conexiones para actualizar colores en tiempo real
		local notificarSeleccion = eventosFolder.Remotos:FindFirstChild("NotificarSeleccionNodo")
		if notificarSeleccion then
			notificarSeleccion.OnClientEvent:Connect(function(eventType, arg1, arg2)
				-- Si el mapa está abierto y hay un evento de conexión/desconexión, actualizar
				if mapaAbierto then
					if eventType == "ConexionCompletada" or eventType == "CableDesconectado" then
						print("[ModuloMapa] Conexión cambiada, actualizando efectos...")
						task.wait(0.1) -- Pequeño delay para que el servidor actualice primero
						_actualizarHighlights()
					end
				end
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
	selectores = {}

	-- Inicializar efectos del mapa y estado de conexiones
	EstadoConexiones.inicializar(config)
	EfectosMapa.inicializar(config, EstadoConexiones)
	
	-- Inicializar efectos de zonas (billboards)
	EfectosZonas.inicializar(nivelModel, config)
	
	-- Desconectar listener anterior si existe
	if conexionZona then
		conexionZona:Disconnect()
		conexionZona = nil
	end
	
	-- Escuchar cambios de zona para ocultar/mostrar billboards
	conexionZona = jugador:GetAttributeChangedSignal("ZonaActual"):Connect(function()
		local nuevaZona = jugador:GetAttribute("ZonaActual")
		print("[ModuloMapa] Zona cambiada a:", nuevaZona)
		
		-- Actualizar zona en EfectosZonas
		EfectosZonas.establecerZonaActual(nuevaZona)
		
		-- Si el mapa está abierto, actualizar visibilidad de billboards
		if mapaAbierto then
			EfectosZonas.actualizarVisibilidad()
		end
	end)

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
-- EFECTOS VISUALES DEL MAPA
-- ================================================================

function _actualizarHighlights()
	print("[ModuloMapa] Actualizando highlights...")
	
	-- Usar el módulo de efectos del mapa
	local adyacentes = {}
	if nodoSeleccionadoMapa and configNivel and configNivel.Adyacencias then
		adyacentes = configNivel.Adyacencias[nodoSeleccionadoMapa.Name] or {}
	end
	
	print("[ModuloMapa] Nivel:", nivelActual and nivelActual.Name or "NIL", "Nodo seleccionado:", nodoSeleccionadoMapa and nodoSeleccionadoMapa.Name or "NINGUNO")
	
	EfectosMapa.actualizarTodos(nivelActual, nodoSeleccionadoMapa, adyacentes)
end

-- ================================================================
-- CALCULOS DE CAMARA
-- ================================================================

-- [DEPRECATED] Ahora se usa ServicioCamara.guardarEstado()
function _guardarEstadoCamara()
	ServicioCamara.guardarEstado()
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

-- [REFACTOR] Usa ServicioCamara para el movimiento
function _hacerTweenCamara(cframeObjetivo, onComplete)
	-- Usar ServicioCamara para movimiento animado
	ServicioCamara.moverA(cframeObjetivo, 0.4, true, onComplete)
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
		_actualizarHighlights()

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

		-- Limpiar selección y actualizar después de un momento
		nodoSeleccionadoMapa = nil
		_actualizarHighlights() -- Actualizar inmediatamente (selección limpia)
		
		-- Actualizar de nuevo después de que el servidor procese la conexión
		task.delay(0.2, function()
			if mapaAbierto then
				_actualizarHighlights()
			end
		end)
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

	-- Limpiar cualquier estado residual de ejecuciones anteriores
	EfectosMapa.limpiarTodo()

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

	-- Guardar estado de camara (usando ServicioCamara)
	ServicioCamara.guardarEstado()

	-- Ocultar techos usando GestorColisiones
	GestorColisiones:ocultarTecho()

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
	
	-- Mostrar efectos de todos los nodos inmediatamente
	_actualizarHighlights()
	
	-- Mostrar billboards de zonas (la zona actual se oculta automáticamente)
	EfectosZonas.mostrarTodos()

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

	-- Limpiar efectos del mapa
	EfectosMapa.limpiarTodo()

	-- Limpiar selección
	pcall(function()
		EfectosNodo.limpiarSeleccion()
	end)

	-- Restaurar techos usando GestorColisiones
	GestorColisiones:restaurar()
	
	-- Ocultar billboards de zonas
	EfectosZonas.ocultarTodos()

	-- Restaurar camara usando ServicioCamara
	ServicioCamara.restaurar(0.4)

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
	
	-- Desconectar listener de zona
	if conexionZona then
		conexionZona:Disconnect()
		conexionZona = nil
	end

	_detenerSeguimiento()
	_detenerEscuchaInput()
	EfectosMapa.limpiarTodo()
	EfectosZonas.limpiar()
	EstadoConexiones.limpiar()

	-- Limpiar estado
	nodoSeleccionadoMapa = nil
	nivelActual = nil
	nivelID = 0
	configNivel = nil
	nombresNodos = {}
	selectores = {}
	
	-- Limpiar estado de cámara si quedó alguno
	if ServicioCamara.tieneEstadoGuardado() then
		ServicioCamara.restaurarInmediato()
	end

	estaActivo = false

	print("[ModuloMapa] Limpieza completada")
end

return ModuloMapa
