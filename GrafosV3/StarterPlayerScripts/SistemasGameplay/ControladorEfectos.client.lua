-- StarterPlayerScripts/SistemasGameplay/ControladorEfectos.client.lua
-- Controlador de efectos visuales - Adaptado de GrafosV2

local Players = game:GetService("Players")
local Replicado = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local EfectosHighlight = require(Replicado.Efectos.EfectosHighlight)
local EfectosVideo     = require(Replicado.Efectos.EfectosVideo)
local EfectosNodo      = require(Replicado.Efectos.EfectosNodo)
local EfectosDano      = require(Replicado.Efectos.EfectosDano)
local BillboardNombres = require(Replicado.Efectos.BillboardNombres)
local GrafoHelpers     = require(Replicado:WaitForChild("Compartido"):WaitForChild("GrafoHelpers"))
local ServicioCamara   = require(Replicado:WaitForChild("Compartido"):WaitForChild("ServicioCamara"))
local LevelsConfig     = require(Replicado:WaitForChild("Config"):WaitForChild("LevelsConfig"))
local ControladorAudio = require(script.Parent.Parent
	:WaitForChild("Compartido")
	:WaitForChild("ControladorAudio"))
local GestorColisiones = require(Replicado:WaitForChild("Compartido"):WaitForChild("GestorColisiones"))
local GestorEfectos    = require(script.Parent:WaitForChild("GestorEfectos"))
local OrquestadorModos = require(script.Parent:WaitForChild("OrquestadorModos"))

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONFIGURACION Y ESTADO
-- ═══════════════════════════════════════════════════════════════════════════════

local COLOR_SELECCIONADO = Color3.fromRGB(0, 212, 255)    -- Cyan
local COLOR_ADYACENTE = Color3.fromRGB(255, 200, 50)      -- Dorado
local COLOR_ERROR = Color3.fromRGB(239, 68, 68)           -- Rojo

-- Estado
local _highlights = {}      -- Instancias Highlight creadas (referencia local, limpiar vía EfectosHighlight)
local _savedStates = {}     -- Estados originales de las partes
local _nombresNodos = {}    -- Nombres amigables desde LevelsConfig
local _nivelActualID = nil
local _nodosDaniados = {}   -- { nombreNodo → config } desde LevelsConfig
local _nodosReparadosLocal = {}  -- TG 07: { [nombreNodo] = true } nodos reparados manualmente
local _tagsCable = {}       -- { clave → BillboardGui } tags de costo en cables
local _tagsNodoCosto = {}   -- { clave → true } tags de costo previo sobre nodos adyacentes
local _tagsConexionesRestantes = {} -- { clave → true } límites visibles sobre nodos adyacentes
local _efectosConexionRecientes = {}  -- { { clon = Instance, nodo = string, tiempo = number } }
local _dialogosReparacionMostrados = {}  -- { [nombreNodo] = true }

-- Helper: solo aplicar efectos de gameplay en modo visual
local function modoVisualActivo()
	return OrquestadorModos.obtenerModoActual() == "visual"
end

-- Forward declarations: se redefinen más abajo con la implementación real.
-- Evitan errores si los handlers se ejecutan antes de que las funciones se carguen.
local obtenerPesoArista = function() return nil end
local crearTagCostoNodo = function() end
local destruirTagsNodoCosto = function() end

-- ═══════════════════════════════════════════════════════════════════════════════
-- EVENTOS REMOTOS (para ReproducirEfecto)
-- ═══════════════════════════════════════════════════════════════════════════════

local Eventos = Replicado:WaitForChild("EventosGrafosV3")
local Remotos = Eventos:WaitForChild("Remotos")

local function activarTodosNodosDaniadosDelNivel(nivelID)
	local cfg = LevelsConfig[nivelID]
	if not cfg or not cfg.Zonas then return end
	for nombreZona, zonaCfg in pairs(cfg.Zonas) do
		if zonaCfg.NodosDaniados then
			for _, nombreNodo in ipairs(zonaCfg.NodosDaniados) do
				if not _nodosReparadosLocal[nombreNodo] then
					EfectosDano.activar(nombreNodo)
				end
			end
		end
	end
end

-- Actualizar nombres cuando carga un nivel (via GestorEfectos)
GestorEfectos.registrar("NivelListo", function(params)
	local data = params.arg1
	if data and data.nivelID ~= nil then
		_nivelActualID = data.nivelID
		local cfg = LevelsConfig[data.nivelID]
		_nombresNodos = (cfg and cfg.NombresNodos) or {}
		print("[ControladorEfectos] Nombres cargados para nivel", data.nivelID)
		-- Activar efectos de daño de TODAS las zonas con nodos dañados
		activarTodosNodosDaniadosDelNivel(data.nivelID)
	end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- EFECTOS DE DAÑO POR ZONA
-- Se activan al cargar el nivel para TODAS las zonas con nodos dañados.
-- Se mantienen activos al cambiar de zona (no se limpian al salir).
-- Se desactivan solo cuando el nodo es reparado manualmente o la emergencia termina.
-- ═══════════════════════════════════════════════════════════════════════════════

local jugador = Players.LocalPlayer

local function obtenerNodosDaniadosDeZona(nombreZona)
	if not _nivelActualID then return nil end
	local cfg = LevelsConfig[_nivelActualID]
	if not cfg or not cfg.Zonas then return nil end
	local zonaCfg = cfg.Zonas[nombreZona]
	return zonaCfg and zonaCfg.NodosDaniados or nil
end

local function activarNodosDaniadosDeZona(nombreZona)
	local nodosDaniados = obtenerNodosDaniadosDeZona(nombreZona)
	if nodosDaniados then
		print(string.format("[ControladorEfectos] Zona '%s' tiene nodos dañados:", nombreZona), table.concat(nodosDaniados, ", "))
		for _, nombreNodo in ipairs(nodosDaniados) do
			-- TG 07: no reactivar efectos en nodos ya reparados manualmente
			if not _nodosReparadosLocal[nombreNodo] then
				EfectosDano.activar(nombreNodo)
			end
		end
	end
end

local function manejarCambioZona()
	local zonaActual = jugador:GetAttribute("ZonaActual") or ""

	-- TG 07: NO limpiar efectos de daño al cambiar de zona.
	-- Los nodos dañados deben seguir visiblemente dañados hasta ser reparados.
	if zonaActual == "" then return end

	activarNodosDaniadosDeZona(zonaActual)
end

jugador:GetAttributeChangedSignal("ZonaActual"):Connect(manejarCambioZona)

-- Escuchar emergencia completada para limpiar daño
local timerEmergenciaEv = Remotos:WaitForChild("TimerEmergencia", 10)
if timerEmergenciaEv then
	timerEmergenciaEv.OnClientEvent:Connect(function(restante, texto, expirado, completada)
		if completada then
			print("[ControladorEfectos] Emergencia superada — limpiando efectos de daño")
			EfectosDano.limpiarTodo()
		end
	end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Obtener el selector de un nodo (puede ser BasePart o Model)
local function getSelector(nodoModel)
	local selector = nodoModel:FindFirstChild("Selector")
	if not selector then return nil, nil end

	if selector:IsA("BasePart") then
		return selector, selector
	end

	-- Selector es un Model, buscar BasePart dentro
	local part = selector:FindFirstChildOfClass("BasePart")
	return selector, part
end

-- Crear Highlight usando el sistema centralizado
local function addHighlight(adornee, color, tipo)
	local tipoHighlight = tipo or "SELECCIONADO"
	if color == COLOR_ADYACENTE then
		tipoHighlight = "ADYACENTE"
	elseif color == COLOR_ERROR then
		tipoHighlight = "ERROR"
	end

	local nombre = "Nodo_" .. (adornee.Name or tostring(adornee))
	return EfectosHighlight.crear(nombre, adornee, tipoHighlight)
end

-- Cambiar estilo de una BasePart y guardar estado original
local function styleBasePart(part, color)
	if not part then return end

	-- Guardar estado original solo una vez por parte; si ya existe, reemplazar
	-- para evitar que un estado intermedio (p. ej. amarillo de adyacente)
	-- quede como "original" al limpiar.
	for i, state in ipairs(_savedStates) do
		if state.part == part then
			table.remove(_savedStates, i)
			break
		end
	end
	table.insert(_savedStates, {
		part = part,
		origColor = part.Color,
		origMat = part.Material,
		origTransp = part.Transparency,
	})

	-- Aplicar nuevo estilo
	part.Color = color
	part.Material = Enum.Material.Neon
	part.Transparency = 0.10
end

-- Crear Billboard con nombre del nodo usando el sistema centralizado
local function addBillboard(part, color, nodeName)
	if not part or not part:IsA("BasePart") then return end

	local displayName = _nombresNodos[nodeName] or nodeName or ""
	local clave = "CE_" .. (nodeName or tostring(part))

	BillboardNombres.crear(part, displayName, "NODO_INTERACCION", clave, {
		colorBorde = color,
		colorTexto = color,
	})
end

-- Highlight completo de un nodo (modelo + billboard en selector)
local function highlightNode(nodoModel, color)
	local _, basePart = getSelector(nodoModel)
	-- Highlight va en el MODELO, no en el selector
	addHighlight(nodoModel, color)
	if basePart then
		styleBasePart(basePart, color)
		addBillboard(basePart, color, nodoModel.Name)
	end
end

local function mostrarConexionesRestantes(nodoModel, nombreNodo, conexionesRestantes)
	if not nodoModel or not nombreNodo or type(conexionesRestantes) ~= "table" then return end
	local restantes = conexionesRestantes[nombreNodo]
	if restantes == nil then return end

	local _, basePart = getSelector(nodoModel)
	if not basePart then return end

	local clave = "GRADO_RESTANTE_" .. nombreNodo
	local color = restantes > 0
		and Color3.fromRGB(255, 220, 80)
		or Color3.fromRGB(239, 68, 68)
	BillboardNombres.crear(
		basePart,
		"Conexiones restantes: " .. tostring(restantes),
		"NODO_CONEXIONES_RESTANTES",
		clave,
		{ colorBorde = color, colorTexto = color }
	)
	_tagsConexionesRestantes[clave] = true
end

-- Limpiar TODOS los efectos y restaurar estados originales
local function clearAll()
	EfectosNodo.limpiarSeleccion()
	-- Destruir todos los Highlights gestionados por EfectosHighlight
	EfectosHighlight.limpiarTodo()
	_highlights = {}

	-- Destruir billboards gestionados por BillboardNombres
	BillboardNombres.destruirPorPrefijo("CE_")
	destruirTagsNodoCosto()
	BillboardNombres.destruirPorPrefijo("GRADO_RESTANTE_")
	_tagsConexionesRestantes = {}

	-- Restaurar partes modificadas
	for _, state in ipairs(_savedStates) do
		if state.part and state.part.Parent then
			state.part.Color = state.origColor
			state.part.Material = state.origMat
			state.part.Transparency = state.origTransp
		end
	end
	_savedStates = {}
end

-- Flash de error usando Highlight
local function flashModel(model, color, duration)
	if not model then return end

	-- Usar el sistema de highlights para el error
	local selector = model:FindFirstChild("Selector")
	if selector then
		EfectosHighlight.flashErrorNodo(model, duration or 0.5)
	else
		-- Fallback: cambiar color de partes directamente
		local parts = {}
		local originals = {}

		for _, desc in ipairs(model:GetDescendants()) do
			if desc:IsA("BasePart") then
				table.insert(parts, desc)
				table.insert(originals, desc.Color)
				desc.Color = color
			end
		end

		task.delay(duration or 0.35, function()
			for i, part in ipairs(parts) do
				if part and part.Parent then
					part.Color = originals[i]
				end
			end
		end)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- EVENTOS (via GestorEfectos — conexión única centralizada)
-- ═══════════════════════════════════════════════════════════════════════════════

-- Nodo seleccionado: arg1 = Model nodo, arg2 = {Model,...} adyacentes,
-- arg3 = { [nombreNodo] = conexionesRestantes }
GestorEfectos.registrar("NodoSeleccionado", function(params)
	if not modoVisualActivo() then return end
	local arg1, arg2, conexionesRestantes = params.arg1, params.arg2, params.arg3
	clearAll()
	local adyNames = {}
	if type(arg2) == "table" then
		for _, adjModel in ipairs(arg2) do
			if typeof(adjModel) == "Instance" then
				table.insert(adyNames, adjModel.Name)
			elseif type(adjModel) == "string" then
				table.insert(adyNames, adjModel)
			end
		end
	end
	local nomSeleccionado = (typeof(arg1) == "Instance" and arg1.Name) or (type(arg1) == "string" and arg1) or nil
	EfectosNodo.establecerSeleccion(nomSeleccionado, adyNames)
	if arg1 then
		highlightNode(arg1, COLOR_SELECCIONADO)
		mostrarConexionesRestantes(arg1, nomSeleccionado, conexionesRestantes)
	end
	if type(arg2) == "table" then
		for _, adjModel in ipairs(arg2) do
			if adjModel and adjModel ~= arg1 then
				local nomAdj = (typeof(adjModel) == "Instance" and adjModel.Name) or (type(adjModel) == "string" and adjModel) or nil
				highlightNode(adjModel, COLOR_ADYACENTE)
				if nomSeleccionado and nomAdj then
					crearTagCostoNodo(nomAdj, nomSeleccionado, nomAdj)
				end
				mostrarConexionesRestantes(adjModel, nomAdj, conexionesRestantes)
			end
		end
	end
end)

-- Helper: formatear dinero como ",XXX"

-- Helper: buscar hitbox de un cable en el workspace
local function buscarHitboxCable(nomA, nomB)
	local nivel = Workspace:FindFirstChild("NivelActual")
	if not nivel then return nil end
	local clave = "Hitbox_" .. GrafoHelpers.clavePar(nomA, nomB)
	return nivel:FindFirstChild(clave, true)
end

-- Helper: crear tag de costo sobre un cable
local function crearTagCosto(nomA, nomB, peso)
	if not peso or peso <= 0 then return end
	if not _nivelActualID then return end
	local costoPorMetro = (LevelsConfig[_nivelActualID] or {}).CostoPorMetro or 0
	if costoPorMetro <= 0 then return end

	local costoTotal = GrafoHelpers.calcularCosto(peso, costoPorMetro)
	local hitbox = buscarHitboxCable(nomA, nomB)
	if not hitbox then return end

	local claveTag = "COSTO_" .. GrafoHelpers.clavePar(nomA, nomB)
	local texto = string.format("Peso: %d | Costo: %s", peso, GrafoHelpers.formatearDinero(costoTotal))
	BillboardNombres.crear(hitbox, texto, "CABLE_COSTO", claveTag, {
		tamano = UDim2.new(0, 220, 0, 22),
	})
	_tagsCable[claveTag] = true
end

-- Helper: destruir tag de costo de un cable
local function destruirTagCosto(nomA, nomB)
	local claveTag = "COSTO_" .. GrafoHelpers.clavePar(nomA, nomB)
	BillboardNombres.destruir(claveTag)
	_tagsCable[claveTag] = nil
end

-- Helper: obtener peso de arista desde LevelsConfig (no dirigida)
obtenerPesoArista = function(nomA, nomB)
	return GrafoHelpers.obtenerPeso(_nivelActualID, nomA, nomB)
end

-- Helper: crear tag de costo previo sobre un nodo adyacente
crearTagCostoNodo = function(nomNodo, nomA, nomB)
	if not nomNodo or not nomA or not nomB then return end
	local peso = obtenerPesoArista(nomA, nomB)
	if not peso or peso <= 0 then return end
	if not _nivelActualID then return end
	local costoPorMetro = (LevelsConfig[_nivelActualID] or {}).CostoPorMetro or 0
	if costoPorMetro <= 0 then return end

	local costoTotal = GrafoHelpers.calcularCosto(peso, costoPorMetro)
	local nivel = Workspace:FindFirstChild("NivelActual")
	if not nivel then return end
	local nodo = nivel:FindFirstChild(nomNodo, true)
	if not nodo then return end
	local _, basePart = getSelector(nodo)
	if not basePart then return end

	local claveTag = "COSTO_NODO_" .. GrafoHelpers.clavePar(nomA, nomB)
	BillboardNombres.crear(basePart, GrafoHelpers.formatearDinero(costoTotal), "NODO_COSTO_PREVIEW", claveTag)
	_tagsNodoCosto[claveTag] = true
end

-- Implementaciones reales de las funciones declaradas arriba.
destruirTagsNodoCosto = function()
	for claveTag, _ in pairs(_tagsNodoCosto) do
		BillboardNombres.destruir(claveTag)
	end
	_tagsNodoCosto = {}
end

-- Conexión completada: efecto VFX en cada Selector + tag de costo
GestorEfectos.registrar("ConexionCompletada", function(params)
	if not modoVisualActivo() then return end
	local nomA, nomB, peso = params.arg1, params.arg2, params.arg3
	clearAll()
	local ahora = tick()
	if nomA then
		local clon = EfectosVideo.reproducirConexion(nomA, "EfectoConexion", 5, 2)
		if clon then
			table.insert(_efectosConexionRecientes, { clon = clon, nodo = nomA, tiempo = ahora })
		end
	end
	if nomB then
		local clon = EfectosVideo.reproducirConexion(nomB, "EfectoConexion", 5, 2)
		if clon then
			table.insert(_efectosConexionRecientes, { clon = clon, nodo = nomB, tiempo = ahora })
		end
	end
	crearTagCosto(nomA, nomB, peso)

	-- Limpiar entradas antiguas (> 5 segundos)
	local limite = ahora - 5
	local filtrados = {}
	for _, e in ipairs(_efectosConexionRecientes) do
		if e.tiempo > limite and e.clon and e.clon.Parent then
			table.insert(filtrados, e)
		end
	end
	_efectosConexionRecientes = filtrados
end)

-- Destruir efectos de conexión asociados a un nodo (para evitar partículas flotantes tras sobrecarga)
local function destruirEfectosConexionRecientes(nombreNodo)
	local ahora = tick()
	local limite = ahora - 2
	local filtrados = {}
	for _, e in ipairs(_efectosConexionRecientes) do
		if e.nodo == nombreNodo and e.tiempo > limite and e.clon and e.clon.Parent then
			pcall(function() e.clon:Destroy() end)
		else
			if e.clon and e.clon.Parent then
				table.insert(filtrados, e)
			end
		end
	end
	_efectosConexionRecientes = filtrados

	-- Limpieza adicional: destruir cualquier VFX_Conexion con el atributo del nodo
	for _, inst in ipairs(CollectionService:GetTagged("VFX_Conexion")) do
		if inst:GetAttribute("NodoVFX") == nombreNodo and inst.Parent then
			pcall(function() inst:Destroy() end)
		end
	end
end

-- Cable creado por el servidor (precargados al inicio del nivel)
GestorEfectos.registrar("CableCreadoConPeso", function(params)
	local nomA, nomB, peso = params.arg1, params.arg2, params.arg3
	crearTagCosto(nomA, nomB, peso)
end)

-- Cable desconectado: limpiar highlights y destruir tag de costo
GestorEfectos.registrar("CableDesconectado", function(params)
	if not modoVisualActivo() then return end
	clearAll()
	local nomA, nomB = params.arg1, params.arg2
	if nomA and nomB then
		destruirTagCosto(nomA, nomB)
	end
end)

-- Selección cancelada
GestorEfectos.registrar("SeleccionCancelada", function(_params)
	if not modoVisualActivo() then return end
	clearAll()
end)

-- Error de conexión: flash rojo
GestorEfectos.registrar("ConexionInvalida", function(params)
	if not modoVisualActivo() then return end
	clearAll()
	flashModel(params.arg1, COLOR_ERROR, 0.35)
end)

GestorEfectos.registrar("DireccionInvalida", function(params)
	if not modoVisualActivo() then return end
	clearAll()
	flashModel(params.arg1, COLOR_ERROR, 0.35)
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- LIMPIEZA AL CAMBIAR DE MODO O DESCARGAR NIVEL
-- ═══════════════════════════════════════════════════════════════════════════════

-- Al cambiar a un modo que no es visual, limpiar efectos de gameplay
GestorEfectos.registrar("CambioModo", function(params)
	local nuevoModo = params.modo
	if nuevoModo ~= "visual" then
		clearAll()
	end
end)

-- Al descargar el nivel, limpiar todo el estado
GestorEfectos.registrar("NivelDescargado", function(_params)
	print("[ControladorEfectos] Nivel descargado — limpiando efectos")
	EfectosDano.limpiarTodo()
	_nodosDaniados = {}
	_nodosReparadosLocal = {}
	_nivelActualID = nil
	_efectosConexionRecientes = {}
	_dialogosReparacionMostrados = {}
	for claveTag, _ in pairs(_tagsCable) do
		BillboardNombres.destruir(claveTag)
	end
	_tagsCable = {}
	destruirTagsNodoCosto()
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- EVENTOS REMOTOS DIRECTOS (ReproducirEfecto)
-- ═══════════════════════════════════════════════════════════════════════════════

local function conectarReproducirEfecto()
	local reproducirEfectoEv = Remotos:FindFirstChild("ReproducirEfecto")
	if not reproducirEfectoEv then
		-- Esperar a que exista (EventRegistry puede tardar en crearlo)
		local eventosRS = game:GetService("ReplicatedStorage"):WaitForChild("EventosGrafosV3", 10)
		local remotosRS = eventosRS and eventosRS:WaitForChild("Remotos", 10)
		if remotosRS then
			reproducirEfectoEv = remotosRS:WaitForChild("ReproducirEfecto", 10)
		end
	end
	
	if reproducirEfectoEv then
		reproducirEfectoEv.OnClientEvent:Connect(function(tipoEfecto, arg1, arg2)
			-- print(string.format("[ControladorEfectos] Recibido efecto: %s | arg1=%s", tostring(tipoEfecto), tostring(arg1)))
			if tipoEfecto == "LIMPIAR_DANO" then
				-- print("[ControladorEfectos] Limpiando efectos de daño por evento remoto")
				EfectosDano.limpiarTodo()
			end
		end)
		print("[ControladorEfectos] Conectado a ReproducirEfecto")
	else
		warn("[ControladorEfectos] ReproducirEfecto no encontrado — efectos de emergencia desactivados")
	end
end

conectarReproducirEfecto()

-- TG 07: Escuchar eventos de reparacion de nodos via GestorEfectos
GestorEfectos.registrar("ClicReparacion", function(params)
	-- Feedback visual sutil en cada clic de reparacion
	local nombreNodo = type(params.arg1) == "string" and params.arg1 or nil
	local restantes = tonumber(params.arg2) or 0
	if nombreNodo then
		-- Sonido de click de reparacion
		ControladorAudio.playSonidoArreglando()
		-- Pequeno flash dorado en el nodo
		local nivel = Workspace:FindFirstChild("NivelActual")
		local nodo = nil
		local basePart = nil
		if nivel then
			nodo = nivel:FindFirstChild(nombreNodo, true)
			if nodo then
				flashModel(nodo, Color3.fromRGB(255, 220, 50), 0.15)
				basePart = getSelector(nodo)
			end
		end

		-- Al primer clic, informar si la reparación quita o mantiene el límite de grado
		if restantes == 2 and not _dialogosReparacionMostrados[nombreNodo] then
			_dialogosReparacionMostrados[nombreNodo] = true
			local nivelID = player:GetAttribute("CurrentLevelID") or 0
			local cfgNodo = LevelsConfig[nivelID]
				    and LevelsConfig[nivelID].LimitesGrado
				    and LevelsConfig[nivelID].LimitesGrado[nombreNodo]
			local quitaLimite = cfgNodo and cfgNodo.QuitarLimiteAlReparar == true
			local claveDialogo = quitaLimite and "Feedback_RepararQuitaLimite" or "Feedback_RepararMantieneLimite"

			if _G.ControladorDialogo and not _G.ControladorDialogo.estaActivo() then
				_G.ControladorDialogo.iniciar(claveDialogo, {
					promptPart = basePart,
					ocultarHUD = false,
					restricciones = {
						bloquearMovimiento = false,
						bloquearSalto = false,
						apuntarCamara = false,
						permitirConexiones = true,
					},
				})
			end
		end
	end
end)

GestorEfectos.registrar("NodoReparado", function(params)
	local nombreNodo = type(params.arg1) == "string" and params.arg1 or nil
	if nombreNodo then
		local cfgNivel = _nivelActualID and LevelsConfig[_nivelActualID]
		local cfgLimite = cfgNivel and cfgNivel.LimitesGrado and cfgNivel.LimitesGrado[nombreNodo]
		if cfgLimite and cfgLimite.QuitarLimiteAlReparar == true then
			local claveLimite = "GRADO_RESTANTE_" .. nombreNodo
			BillboardNombres.destruir(claveLimite)
			_tagsConexionesRestantes[claveLimite] = nil
		end
		-- Marcar como reparado para no reactivar al volver a la zona
		_nodosReparadosLocal[nombreNodo] = true
		-- Sonido de reparacion
		ControladorAudio.playNodoReparar()
		-- Limpiar efectos de daño de este nodo
		EfectosDano.desactivar(nombreNodo)
		-- Flash verde de exito
		local nivel = Workspace:FindFirstChild("NivelActual")
		if nivel then
			local nodo = nivel:FindFirstChild(nombreNodo, true)
			if nodo then
				flashModel(nodo, Color3.fromRGB(46, 204, 113), 0.4)
			end
		end
	end
end)

GestorEfectos.registrar("FaltaDineroReparacion", function(params)
	local nombreNodo = type(params.arg1) == "string" and params.arg1 or nil
	local costo = tonumber(params.arg2) or 0
	-- Flash rojo intenso indicando falta de fondos
	local nivel = Workspace:FindFirstChild("NivelActual")
	if nivel and nombreNodo then
		local nodo = nivel:FindFirstChild(nombreNodo, true)
		if nodo then
			flashModel(nodo, Color3.fromRGB(255, 0, 0), 0.5)
		end
	end
	-- Sonido de error
	ControladorAudio.playSFX("Error")
end)

GestorEfectos.registrar("FaltaDineroCable", function(params)
	local nomA = type(params.arg1) == "string" and params.arg1 or nil
	local nomB = type(params.arg2) == "string" and params.arg2 or nil
	local peso = tonumber(params.arg3) or 0
	-- Flash rojo en ambos nodos
	local nivel = Workspace:FindFirstChild("NivelActual")
	if nivel then
		local nodoA = nomA and nivel:FindFirstChild(nomA, true)
		local nodoB = nomB and nivel:FindFirstChild(nomB, true)
		if nodoA then flashModel(nodoA, Color3.fromRGB(255, 0, 0), 0.35) end
		if nodoB then flashModel(nodoB, Color3.fromRGB(255, 0, 0), 0.35) end
	end
	-- Sonido de error
	ControladorAudio.playSFX("ConnectionFailed")
end)

GestorEfectos.registrar("NodoSobrecargado", function(params)
	local nombreNodo = type(params.arg1) == "string" and params.arg1 or nil
	if not nombreNodo then return end

	local nivel = Workspace:FindFirstChild("NivelActual")
	local nodo = nivel and nivel:FindFirstChild(nombreNodo, true)
	local _, basePart = nodo and getSelector(nodo)
	local claveBB = "SOBRECARGA_" .. nombreNodo

	-- 1. Ocultar techos para la cinemática, guardar si ya estaban ocultos
	local techosYaOcultos = GestorColisiones.estaOculto
	if not techosYaOcultos then
		GestorColisiones:ocultarTecho()
	end

	-- 2. Guardar estado y mover cámara al nodo afectado
	ServicioCamara.guardarEstado()
	ServicioCamara.moverHaciaObjetivo(nombreNodo, {
		altura = 18,
		angulo = 65,
		duracion = 0.8,
	})

	-- 3. Billboard temporal
	if basePart then
		BillboardNombres.crear(basePart, "NODO SOBRECARGADO", "NODO_DANIADO", claveBB)
	end

	-- 4. Sonido, efectos de daño y flash
	ControladorAudio.playSFX("Explosion")
	EfectosDano.activar(nombreNodo)
	if nodo then
		flashModel(nodo, Color3.fromRGB(255, 0, 0), 0.6)
	end

	-- 5. Limpiar efectos de conexión recientes para evitar partículas flotantes
	destruirEfectosConexionRecientes(nombreNodo)

	-- 6. Esperar, quitar billboard, restaurar cámara e iniciar diálogo de feedback
	task.delay(2.5, function()
		BillboardNombres.destruir(claveBB)
		-- Restaurar techos solo si no estaban ocultos antes de la cinemática
		-- (por ejemplo, si el mapa está abierto no debemos restaurarlos)
		if not techosYaOcultos then
			GestorColisiones:restaurar()
		end
		ServicioCamara.restaurar(0.6)
		task.delay(0.7, function()
			if _G.ControladorDialogo and not _G.ControladorDialogo.estaActivo() then
				_G.ControladorDialogo.iniciar("Feedback_NodoSobrecargado", {
					promptPart = basePart,
					ocultarHUD = false,
					restricciones = {
						bloquearMovimiento = false,
						bloquearSalto = false,
						apuntarCamara = false,
						permitirConexiones = true,
					},
				})
			end
		end)
	end)
end)

print("[ControladorEfectos] Sistema de efectos inicializado")
