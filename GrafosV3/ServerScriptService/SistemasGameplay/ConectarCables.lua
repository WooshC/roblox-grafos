-- ServerScriptService/SistemasGameplay/ConectarCables.lua
-- Sistema de conexion de cables entre nodos (servidor)
-- Adaptado a arquitectura V3 - Compatible con estructura:
-- Nodo (Model) -> Selector (Part) -> ClickDetector + Attachment

local ConectarCables = {}

local Workspace = game:GetService("Workspace")
local Replicado = game:GetService("ReplicatedStorage")
local Jugadores = game:GetService("Players")

-- Eventos
local Eventos = Replicado:WaitForChild("EventosGrafosV3")
local Remotos = Eventos:WaitForChild("Remotos")

-- Configuracion de niveles para nombres
local LevelsConfig = require(Replicado:WaitForChild("Config"):WaitForChild("LevelsConfig"))

-- Validador de conexiones centralizado
local ValidadorConexiones = require(script.Parent:WaitForChild("ValidadorConexiones"))

-- Estado interno
local _activo = false
local _nivel = nil
local _jugador = nil
local _nodoSeleccionado = nil
local _selectoresPorNombre = {}
local _cables = {}
local _conexiones = {}
local _lookupAdyacencias = nil
local _nivelID = nil
local _callbacks = nil  -- Callbacks para notificar a otros sistemas

-- Constantes
local COLOR_CABLE = Color3.fromRGB(0, 200, 255)
local ANCHO_CABLE = 0.13
local DISTANCIA_CLICK = 50

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════════════════

local function clavePar(nomA, nomB)
	if nomA > nomB then nomA, nomB = nomB, nomA end
	return nomA .. "|" .. nomB
end

-- El Selector es una Part dentro del Model Nodo
-- Nombre del nodo = selector.Parent.Name
local function obtenerNombreNodo(selector)
	return selector.Parent.Name
end

local function obtenerAttachment(selector)
	return selector:FindFirstChild("Attachment")
end

local function obtenerClickDetector(selector)
	return selector:FindFirstChild("ClickDetector")
end

-- Ruta: Selector (Part) -> Nodo (Model) -> Nodos (Folder) -> Grafo_ZonaX (Folder) -> Conexiones
local function obtenerCarpetaConexiones(selector)
	local nodo = selector.Parent
	local nodosFolder = nodo.Parent
	local grafo = nodosFolder.Parent
	if not grafo then return nil end
	
	local conexiones = grafo:FindFirstChild("Conexiones")
	if not conexiones then
		conexiones = Instance.new("Folder")
		conexiones.Name = "Conexiones"
		conexiones.Parent = grafo
	end
	return conexiones
end

local function construirLookupAdyacencias(adyacencias)
	if not adyacencias then return nil end
	local lookup = {}
	for nomA, vecinos in pairs(adyacencias) do
		lookup[nomA] = {}
		for _, nomB in ipairs(vecinos) do
			lookup[nomA][nomB] = true
		end
	end
	return lookup
end

local function esAdyacente(nomA, nomB)
	if _lookupAdyacencias == nil then return true end
	return (_lookupAdyacencias[nomA] and _lookupAdyacencias[nomA][nomB]) == true
end

local function esBidireccional(nomA, nomB)
	return esAdyacente(nomA, nomB) and esAdyacente(nomB, nomA)
end

local function buscarCable(nomA, nomB)
	local clave = clavePar(nomA, nomB)
	for i, cable in ipairs(_cables) do
		if cable.clave == clave then return i end
	end
	return nil
end

-- Recolectar todos los Selectores (Part) del nivel
local function recolectarSelectores()
	_selectoresPorNombre = {}
	if not _nivel then return {} end
	
	local selectores = {}
	local grafosFolder = _nivel:FindFirstChild("Grafos")
	if not grafosFolder then
		warn("[ConectarCables] No se encontro carpeta 'Grafos' en NivelActual")
		return selectores
	end
	
	for _, grafo in ipairs(grafosFolder:GetChildren()) do
		local nodosFolder = grafo:FindFirstChild("Nodos")
		if nodosFolder then
			for _, nodo in ipairs(nodosFolder:GetChildren()) do
				if nodo:IsA("Model") then
					local selector = nodo:FindFirstChild("Selector")
					-- El Selector debe ser una BasePart
					if selector and selector:IsA("BasePart") then
						table.insert(selectores, selector)
						_selectoresPorNombre[nodo.Name] = selector
						
						-- Verificar que tenga ClickDetector
						if not obtenerClickDetector(selector) then
							warn("[ConectarCables] Selector sin ClickDetector:", nodo.Name)
						end
						-- Verificar que tenga Attachment
						if not obtenerAttachment(selector) then
							warn("[ConectarCables] Selector sin Attachment:", nodo.Name)
						end
					else
						warn("[ConectarCables] Nodo sin Selector (BasePart):", nodo.Name)
					end
				end
			end
		end
	end
	return selectores
end

-- Obtener modelos de nodos adyacentes
local function obtenerModelosAdyacentes(nomA)
	if not _lookupAdyacencias or not _lookupAdyacencias[nomA] then return {} end
	
	local modelos = {}
	for nomVecino, _ in pairs(_lookupAdyacencias[nomA]) do
		local selectorVecino = _selectoresPorNombre[nomVecino]
		if selectorVecino then
			table.insert(modelos, selectorVecino.Parent)
		end
	end
	return modelos
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CREAR/ELIMINAR CABLES
-- ═══════════════════════════════════════════════════════════════════════════════

local function crearCable(selector1, selector2)
	local nomA = obtenerNombreNodo(selector1)
	local nomB = obtenerNombreNodo(selector2)
	local clave = clavePar(nomA, nomB)
	
	local att1 = obtenerAttachment(selector1)
	local att2 = obtenerAttachment(selector2)
	local conexiones = obtenerCarpetaConexiones(selector1)
	
	if not att1 or not att2 then
		warn("[ConectarCables] Faltan Attachments:", nomA, nomB)
		return
	end
	if not conexiones then
		warn("[ConectarCables] No se encontro Conexiones para", nomA)
		return
	end
	
	-- Hitbox invisible para click-to-disconnect
	local mid = (att1.WorldPosition + att2.WorldPosition) / 2
	local distancia = (att1.WorldPosition - att2.WorldPosition).Magnitude
	
	local hitbox = Instance.new("Part")
	hitbox.Name = "Hitbox_" .. clave
	hitbox.Size = Vector3.new(0.4, 0.4, distancia)
	hitbox.CFrame = CFrame.lookAt(att1.WorldPosition, att2.WorldPosition) * CFrame.new(0, 0, -distancia/2)
	hitbox.Transparency = 1
	hitbox.CanCollide = false
	hitbox.Anchored = true
	hitbox.Parent = conexiones
	
	-- Beam visual
	local beam = Instance.new("Beam")
	beam.Name = "Cable_" .. clave
	beam.Attachment0 = att1
	beam.Attachment1 = att2
	beam.Color = ColorSequence.new(COLOR_CABLE)
	beam.Width0 = ANCHO_CABLE
	beam.Width1 = ANCHO_CABLE
	beam.CurveSize0 = 0
	beam.CurveSize1 = 0
	beam.LightEmission = 0.6
	beam.LightInfluence = 0.4
	beam.Transparency = NumberSequence.new(0)
	beam.FaceCamera = true
	beam.Segments = 10
	beam.Parent = hitbox
	
	-- ClickDetector para desconectar
	local cd = Instance.new("ClickDetector")
	cd.MaxActivationDistance = DISTANCIA_CLICK
	cd.Parent = hitbox
	
	local entrada = {
		clave = clave,
		beam = beam,
		hitbox = hitbox,
		nomA = nomA,
		nomB = nomB
	}
	table.insert(_cables, entrada)
	
	-- Evento de desconexion
	local conn = cd.MouseClick:Connect(function(pl)
		if pl ~= _jugador then return end
		for i, cable in ipairs(_cables) do
			if cable.hitbox == hitbox then
				local nomA, nomB = cable.nomA, cable.nomB
				cable.hitbox:Destroy()
				table.remove(_cables, i)
				
				-- Notificar a cliente
				local notificarEvento = Remotos:FindFirstChild("NotificarSeleccionNodo")
				if notificarEvento then
					notificarEvento:FireClient(pl, "CableDesconectado", nomA, nomB)
				end
				
				-- Notificar a sistemas via callbacks
				if _callbacks and _callbacks.onCableEliminado then
					_callbacks.onCableEliminado(nomA, nomB)
				end
				
				-- Registrar en validador centralizado
				ValidadorConexiones.eliminarConexion(nomA, nomB)
				
				print("[ConectarCables] Cable desconectado:", cable.clave)
				break
			end
		end
	end)
	table.insert(_conexiones, conn)
	
	-- Notificar pulso de energia
	local pulseEvento = Remotos:FindFirstChild("PulsoEvent")
	if pulseEvento then
		local bidir = esBidireccional(nomA, nomB)
		pulseEvento:FireClient(_jugador, "IniciarPulso", selector1.Parent, selector2.Parent, bidir)
	end
	
	-- Notificar a sistemas via callbacks
	if _callbacks and _callbacks.onCableCreado then
		_callbacks.onCableCreado(nomA, nomB)
	end
	
	-- Registrar en validador centralizado
	ValidadorConexiones.registrarConexion(selector1.Parent, selector2.Parent, beam)
	
	print("[ConectarCables] Cable creado:", clave)
end

local function eliminarCable(indice)
	local cable = _cables[indice]
	if cable then
		if cable.hitbox and cable.hitbox.Parent then
			cable.hitbox:Destroy()
		end
		table.remove(_cables, indice)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- LOGICA DE CONEXION
-- ═══════════════════════════════════════════════════════════════════════════════

local function intentarConectar(jugador, selector1, selector2)
	local nomA = obtenerNombreNodo(selector1)
	local nomB = obtenerNombreNodo(selector2)
	
	local function finalizar()
		_nodoSeleccionado = nil
		local dragEvento = Remotos:FindFirstChild("CableDragEvent")
		if dragEvento then
			dragEvento:FireClient(jugador, "Detener")
		end
	end
	
	-- Mismo nodo -> deseleccionar
	if nomA == nomB then
		local notificarEvento = Remotos:FindFirstChild("NotificarSeleccionNodo")
		if notificarEvento then
			notificarEvento:FireClient(jugador, "SeleccionCancelada")
		end
		finalizar()
		return
	end
	
	-- Ya conectados -> desconectar
	local indice = buscarCable(nomA, nomB)
	if indice then
		local cable = _cables[indice]
		local nomA, nomB = cable.nomA, cable.nomB
		eliminarCable(indice)
		
		local notificarEvento = Remotos:FindFirstChild("NotificarSeleccionNodo")
		if notificarEvento then
			notificarEvento:FireClient(jugador, "CableDesconectado", nomA, nomB)
		end
		
		-- Notificar a sistemas via callbacks
		if _callbacks and _callbacks.onCableEliminado then
			_callbacks.onCableEliminado(nomA, nomB)
		end
		
		-- Registrar en validador centralizado
		ValidadorConexiones.eliminarConexion(nomA, nomB)
		
		print("[ConectarCables] Cable desconectado via clic en nodos:", nomA, "|", nomB)
		
		finalizar()
		return
	end
	
	-- Verificar adyacencia segun LevelsConfig
	if esAdyacente(nomA, nomB) then
		crearCable(selector1, selector2)
		
		local notificarEvento = Remotos:FindFirstChild("NotificarSeleccionNodo")
		if notificarEvento then
			notificarEvento:FireClient(jugador, "ConexionCompletada", nomA, nomB)
		end
	else
		-- Error: no son adyacentes
		local tipoError = esAdyacente(nomB, nomA) and "DireccionInvalida" or "ConexionInvalida"
		
		local notificarEvento = Remotos:FindFirstChild("NotificarSeleccionNodo")
		if notificarEvento then
			notificarEvento:FireClient(jugador, "ConexionInvalida", selector2.Parent)
		end
		
		-- Notificar fallo via callbacks
		if _callbacks and _callbacks.onFalloConexion then
			_callbacks.onFalloConexion()
		end
		
		print("[ConectarCables] Fallo (" .. tipoError .. "):", nomA, "->", nomB)
	end
	
	finalizar()
end

-- Handler de click en Selector
local function alClickearSelector(jugador, selector)
	if jugador ~= _jugador then return end
	if not _activo then return end
	
	if _nodoSeleccionado == nil then
		-- Primer clic: seleccionar nodo
		_nodoSeleccionado = selector
		
		local nomA = obtenerNombreNodo(selector)
		local modeloNodo = selector.Parent
		local modelosAdyacentes = obtenerModelosAdyacentes(nomA)
		
		-- Notificar al cliente para efectos visuales (el cliente obtiene nombres de LevelsConfig)
		local notificarEvento = Remotos:FindFirstChild("NotificarSeleccionNodo")
		if notificarEvento then
			notificarEvento:FireClient(jugador, "NodoSeleccionado", modeloNodo, modelosAdyacentes)
		end
		
		-- Notificar a sistemas via callbacks
		if _callbacks and _callbacks.onNodoSeleccionado then
			_callbacks.onNodoSeleccionado(nomA)
		end
		
		-- Iniciar preview de arrastre
		local dragEvento = Remotos:FindFirstChild("CableDragEvent")
		if dragEvento then
			local att1 = obtenerAttachment(selector)
			local vecinos = {}
			if _lookupAdyacencias and _lookupAdyacencias[nomA] then
				for nomV, _ in pairs(_lookupAdyacencias[nomA]) do
					table.insert(vecinos, nomV)
				end
			end
			if att1 then
				dragEvento:FireClient(jugador, "Iniciar", att1, vecinos)
			end
		end
		
	elseif _nodoSeleccionado == selector then
		-- Mismo nodo: cancelar seleccion
		_nodoSeleccionado = nil
		local notificarEvento = Remotos:FindFirstChild("NotificarSeleccionNodo")
		if notificarEvento then
			notificarEvento:FireClient(jugador, "SeleccionCancelada")
		end
		
		local dragEvento = Remotos:FindFirstChild("CableDragEvent")
		if dragEvento then
			dragEvento:FireClient(jugador, "Detener")
		end
		
	else
		-- Segundo clic en otro nodo: intentar conectar
		intentarConectar(jugador, _nodoSeleccionado, selector)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- INTERFAZ PUBLICA
-- ═══════════════════════════════════════════════════════════════════════════════

function ConectarCables.activar(nivel, adyacencias, jugador, nivelID, callbacks)
	if _activo then
		ConectarCables.desactivar()
	end
	
	_nivel = nivel
	_jugador = jugador
	_nivelID = nivelID
	_nodoSeleccionado = nil
	_cables = {}
	_conexiones = {}
	_lookupAdyacencias = construirLookupAdyacencias(adyacencias)
	_callbacks = callbacks or {}
	_activo = true
	
	-- Configurar validador centralizado
	ValidadorConexiones.configurar({ Adyacencias = adyacencias })
	
	local selectores = recolectarSelectores()
	print("[ConectarCables] Activado - Nodos:", #selectores)
	
	-- Configurar cada selector
	for _, selector in ipairs(selectores) do
		-- El selector debe ser clickeable
		selector.CanCollide = false
		selector.CanQuery = true -- Necesario para ClickDetector
		selector.CanTouch = false
		
		-- Configurar ClickDetector
		local cd = obtenerClickDetector(selector)
		if cd then
			cd.MaxActivationDistance = DISTANCIA_CLICK
			
			local conn = cd.MouseClick:Connect(function(pl)
				alClickearSelector(pl, selector)
			end)
			table.insert(_conexiones, conn)
		end
	end
end

function ConectarCables.desactivar()
	_activo = false
	_nodoSeleccionado = nil
	
	-- Desconectar listeners
	for _, conn in ipairs(_conexiones) do
		conn:Disconnect()
	end
	_conexiones = {}
	
	-- Destruir cables
	for _, cable in ipairs(_cables) do
		if cable.hitbox and cable.hitbox.Parent then
			cable.hitbox:Destroy()
		end
	end
	_cables = {}
	
	-- Detener pulsos
	local pulseEvento = Remotos:FindFirstChild("PulsoEvent")
	if pulseEvento then
		pulseEvento:FireClient(_jugador, "DetenerTodos")
	end
	
	_nivel = nil
	_jugador = nil
	_nivelID = nil
	_lookupAdyacencias = nil
	_selectoresPorNombre = {}
	
	-- Limpiar validador centralizado
	ValidadorConexiones.limpiar()
	_callbacks = nil
	
	print("[ConectarCables] Desactivado")
end

function ConectarCables.obtenerConexiones()
	local resultado = {}
	for _, cable in ipairs(_cables) do
		table.insert(resultado, cable.clave)
	end
	return resultado
end

function ConectarCables.estaActivo()
	return _activo
end

function ConectarCables.obtenerValidador()
	return ValidadorConexiones
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONEXIÓN DESDE EL MAPA (API pública para el mapa cenital)
-- ═══════════════════════════════════════════════════════════════════════════════

function ConectarCables.conectarNodos(nombreNodoA, nombreNodoB, jugador)
	if not _activo then
		warn("[ConectarCables] conectarNodos ignorado - sistema no activo")
		return false
	end
	
	if not _lookupAdyacencias then
		warn("[ConectarCables] conectarNodos ignorado - no hay adyacencias")
		return false
	end
	
	-- Obtener selectores por nombre
	local selectorA = _selectoresPorNombre[nombreNodoA]
	local selectorB = _selectoresPorNombre[nombreNodoB]
	
	if not selectorA or not selectorB then
		warn("[ConectarCables] Selector no encontrado:", nombreNodoA, "o", nombreNodoB)
		return false
	end
	
	-- Verificar si ya están conectados (toggle desconexión)
	local indice = buscarCable(nombreNodoA, nombreNodoB)
	if indice then
		-- Desconectar
		local cable = _cables[indice]
		local nomA, nomB = cable.nomA, cable.nomB
		eliminarCable(indice)
		
		local notificarEvento = Remotos:FindFirstChild("NotificarSeleccionNodo")
		if notificarEvento then
			notificarEvento:FireClient(jugador, "CableDesconectado", nomA, nomB)
		end
		
		if _callbacks and _callbacks.onCableEliminado then
			_callbacks.onCableEliminado(nomA, nomB)
		end
		
		-- Registrar en validador centralizado
		ValidadorConexiones.eliminarConexion(nomA, nomB)
		
		print("[ConectarCables] Cable desconectado desde mapa:", nomA, "|", nomB)
		return true
	end
	
	-- Verificar adyacencia
	if not esAdyacente(nombreNodoA, nombreNodoB) then
		-- Error: no son adyacentes
		local tipoError = esAdyacente(nombreNodoB, nombreNodoA) and "DireccionInvalida" or "ConexionInvalida"
		
		local notificarEvento = Remotos:FindFirstChild("NotificarSeleccionNodo")
		if notificarEvento then
			notificarEvento:FireClient(jugador, "ConexionInvalida", selectorB.Parent)
		end
		
		if _callbacks and _callbacks.onFalloConexion then
			_callbacks.onFalloConexion()
		end
		
		print("[ConectarCables] Fallo desde mapa (" .. tipoError .. "):", nombreNodoA, "->", nombreNodoB)
		return false
	end
	
	-- Crear la conexión
	crearCable(selectorA, selectorB)
	
	local notificarEvento = Remotos:FindFirstChild("NotificarSeleccionNodo")
	if notificarEvento then
		notificarEvento:FireClient(jugador, "ConexionCompletada", nombreNodoA, nombreNodoB)
	end
	
	print("[ConectarCables] Conexión creada desde mapa:", nombreNodoA, "|", nombreNodoB)
	return true
end

return ConectarCables
