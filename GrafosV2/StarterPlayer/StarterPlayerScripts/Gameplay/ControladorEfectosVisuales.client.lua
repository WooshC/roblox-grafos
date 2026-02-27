-- ControladorEfectosVisuales.client.lua
-- REFACTORIZADO: Ahora implementa activar/desactivar para limpieza completa.
--
-- Regla de Oro: Cuando volvemos al menu, NO debe quedar NINGUN efecto visual.

local Players   = game:GetService("Players")
local RS        = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ControladorEfectosVisuales = {}

-- Estado
ControladorEfectosVisuales._activo = false
ControladorEfectosVisuales._conexiones = {}
ControladorEfectosVisuales._nivelID = nil
ControladorEfectosVisuales._nombresNodos = {}

-- Referencias a eventos
ControladorEfectosVisuales._eventoNotificar = nil
ControladorEfectosVisuales._eventoPlayEffect = nil

-- ── Colores ──────────────────────────────────────────────────────────────────
local COLOR_SELECCIONADO = Color3.fromRGB(0,   212, 255)  -- cyan: nodo seleccionado
local COLOR_ADYACENTE    = Color3.fromRGB(255, 200,  50)  -- dorado: nodos adyacentes
local COLOR_INVALIDO     = Color3.fromRGB(239,  68,  68)  -- rojo: conexion invalida
local COLOR_ENERGIZADO   = Color3.fromRGB(0,   200, 255)  -- cian: nodo energizado

-- ── Estado de efectos ─────────────────────────────────────────────────────────
local _highlights  = {}  -- Instancias Highlight
local _savedStates = {}  -- Estado original de partes modificadas
local _billboards  = {}  -- BillboardGui creados

-- ═══════════════════════════════════════════════════════════════════════════════
-- ACTIVAR: Iniciar el controlador y conectar eventos
-- ═══════════════════════════════════════════════════════════════════════════════
function ControladorEfectosVisuales:activar()
	if self._activo then
		self:desactivar()
	end
	
	print("[ControladorEfectosVisuales] ▶️ Activando...")
	
	self._activo = true
	self._conexiones = {}
	
	-- Cargar configuracion de niveles
	local exito, LevelsConfig = pcall(function()
		return require(RS:WaitForChild("Config", 5):WaitForChild("LevelsConfig", 5))
	end)
	
	-- Actualizar tabla de nombres cuando carga un nivel
	local eventsFolder = RS:WaitForChild("Events", 10)
	local remotesFolder = eventsFolder and eventsFolder:WaitForChild("Remotes", 5)
	
	if remotesFolder then
		-- Evento LevelReady para saber que nivel estamos jugando
		local nivelListo = remotesFolder:FindFirstChild("LevelReady")
		if nivelListo then
			local conn = nivelListo.OnClientEvent:Connect(function(datos)
				if datos and datos.nivelID ~= nil then
					self._nivelID = datos.nivelID
					if exito and LevelsConfig then
						local cfg = LevelsConfig[self._nivelID]
						self._nombresNodos = (cfg and cfg.NombresNodos) or {}
					end
				end
			end)
			table.insert(self._conexiones, conn)
		end
		
		-- Evento principal de notificacion
		self._eventoNotificar = remotesFolder:FindFirstChild("NotificarSeleccionNodo")
		if self._eventoNotificar then
			local conn = self._eventoNotificar.OnClientEvent:Connect(function(...)
				if not self._activo then return end
				self:_manejarNotificacion(...)
			end)
			table.insert(self._conexiones, conn)
		end
		
		-- Evento PlayEffect
		self._eventoPlayEffect = remotesFolder:FindFirstChild("PlayEffect")
		if self._eventoPlayEffect then
			local conn = self._eventoPlayEffect.OnClientEvent:Connect(function(...)
				if not self._activo then return end
				self:_manejarPlayEffect(...)
			end)
			table.insert(self._conexiones, conn)
		end
	end
	
	print("[ControladorEfectosVisuales] ✅ Activo")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- DESACTIVAR: Limpiar TODO y desconectar eventos
-- ═══════════════════════════════════════════════════════════════════════════════
function ControladorEfectosVisuales:desactivar()
	if not self._activo then
		return
	end
	
	print("[ControladorEfectosVisuales] ⏹️ Desactivando...")
	
	-- 1. Limpiar todos los efectos visuales
	self:limpiarTodo()
	
	-- 2. Desconectar TODOS los eventos
	for _, conn in ipairs(self._conexiones) do
		if conn and typeof(conn) == "RBXScriptConnection" then
			pcall(function() conn:Disconnect() end)
		end
	end
	self._conexiones = {}
	
	-- 3. Limpiar estado
	self._activo = false
	self._nivelID = nil
	self._nombresNodos = {}
	self._eventoNotificar = nil
	self._eventoPlayEffect = nil
	
	print("[ControladorEfectosVisuales] ⬛ Desactivado completamente")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- LIMPIAR TODO: Destruir highlights, billboards, restaurar partes
-- ═══════════════════════════════════════════════════════════════════════════════
function ControladorEfectosVisuales:limpiarTodo()
	-- Destruir highlights
	for _, h in ipairs(_highlights) do
		if h and h.Parent then
			pcall(function() h:Destroy() end)
		end
	end
	_highlights = {}
	
	-- Destruir billboards
	for _, b in ipairs(_billboards) do
		if b and b.Parent then
			pcall(function() b:Destroy() end)
		end
	end
	_billboards = {}
	
	-- Restaurar partes modificadas
	for _, state in ipairs(_savedStates) do
		if state.part and state.part.Parent then
			pcall(function()
				state.part.Color = state.origColor
				state.part.Material = state.origMat
				state.part.Transparency = state.origTransp
			end)
		end
	end
	_savedStates = {}
	
	print("[ControladorEfectosVisuales] 🧹 Efectos limpiados")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- HANDLERS DE EVENTOS (internos)
-- ═══════════════════════════════════════════════════════════════════════════════

function ControladorEfectosVisuales:_manejarNotificacion(tipoEvento, arg1, arg2)
	if tipoEvento == "NodoSeleccionado" then
		-- arg1 = nodoModel, arg2 = adjModels[]
		self:limpiarTodo()
		if arg1 then
			self:_resaltarNodo(arg1, COLOR_SELECCIONADO)
		end
		if type(arg2) == "table" then
			for _, adjModel in ipairs(arg2) do
				if adjModel and adjModel ~= arg1 then
					self:_resaltarNodo(adjModel, COLOR_ADYACENTE)
				end
			end
		end
		
	elseif tipoEvento == "SeleccionCancelada"
		or tipoEvento == "ConexionCompletada"
		or tipoEvento == "CableDesconectado" then
		self:limpiarTodo()
		
	elseif tipoEvento == "ConexionInvalida" then
		self:limpiarTodo()
		self:_flashModelo(arg1, COLOR_INVALIDO, 0.35)
		
	end
end

function ControladorEfectosVisuales:_manejarPlayEffect(tipoEfecto, arg1, arg2)
	if tipoEfecto == "NodeSelected" then
		self:limpiarTodo()
		if arg1 then self:_resaltarNodo(arg1, COLOR_SELECCIONADO) end
		if type(arg2) == "table" then
			for _, adjModel in ipairs(arg2) do
				if adjModel and adjModel ~= arg1 then
					self:_resaltarNodo(adjModel, COLOR_ADYACENTE)
				end
			end
		end
		
	elseif tipoEfecto == "NodeError" then
		self:limpiarTodo()
		self:_flashModelo(arg1, COLOR_INVALIDO, 0.35)
		
	elseif tipoEfecto == "NodeEnergized" then
		self:limpiarTodo()
		if arg1 then self:_resaltarNodo(arg1, COLOR_ENERGIZADO) end
		
	elseif tipoEfecto == "CableConnected"
		or tipoEfecto == "CableRemoved"
		or tipoEfecto == "ZoneComplete"
		or tipoEfecto == "ClearAll" then
		self:limpiarTodo()
		
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPERS (migrados del archivo original)
-- ═══════════════════════════════════════════════════════════════════════════════

function ControladorEfectosVisuales:_obtenerSelectorTarget(nodoModel)
	local selector = nodoModel:FindFirstChild("Selector")
	if not selector then return nil, nil end
	if selector:IsA("BasePart") then
		return selector, selector
	end
	local parte = selector:FindFirstChildOfClass("BasePart")
	return selector, parte
end

function ControladorEfectosVisuales:_agregarHighlight(adornee, color)
	local h = Instance.new("Highlight")
	h.Adornee = adornee
	h.FillColor = color
	h.FillTransparency = 0.45
	h.OutlineColor = color
	h.OutlineTransparency = 0
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Parent = Workspace
	table.insert(_highlights, h)
end

function ControladorEfectosVisuales:_estilizarParte(parte, color)
	if not parte then return end
	table.insert(_savedStates, {
		part = parte,
		origColor = parte.Color,
		origMat = parte.Material,
		origTransp = parte.Transparency,
	})
	parte.Color = color
	parte.Material = Enum.Material.Neon
	parte.Transparency = 0.10
end

function ControladorEfectosVisuales:_agregarBillboard(parte, color, nombreNodo)
	if not parte or not parte:IsA("BasePart") then return end
	
	local bb = Instance.new("BillboardGui")
	bb.Adornee = parte
	bb.StudsOffsetWorldSpace = Vector3.new(0, 4.5, 0)
	bb.AlwaysOnTop = true
	bb.Size = UDim2.fromOffset(120, 32)
	bb.ResetOnSpawn = false
	bb.Parent = Workspace
	
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.new(0, 0, 0)
	bg.BackgroundTransparency = 0.45
	bg.BorderSizePixel = 0
	bg.Parent = bb
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = bg
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 2
	stroke.Parent = bg
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = nombreNodo or ""
	label.TextColor3 = color
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = bg
	
	table.insert(_billboards, bb)
end

function ControladorEfectosVisuales:_resaltarNodo(nodoModel, color)
	local adornee, parteBase = self:_obtenerSelectorTarget(nodoModel)
	if adornee then
		self:_agregarHighlight(adornee, color)
	end
	if parteBase then
		local nombreNodo = self._nombresNodos[nodoModel.Name] or nodoModel.Name
		self:_estilizarParte(parteBase, color)
		self:_agregarBillboard(parteBase, color, nombreNodo)
	end
end

function ControladorEfectosVisuales:_flashModelo(modelo, colorFlash, duracion)
	if not modelo then return end
	local partes = {}
	local originales = {}
	
	for _, desc in ipairs(modelo:GetDescendants()) do
		if desc:IsA("BasePart") then
			table.insert(partes, desc)
			table.insert(originales, desc.Color)
			desc.Color = colorFlash
		end
	end
	
	task.delay(duracion or 0.35, function()
		for i, parte in ipairs(partes) do
			if parte and parte.Parent then
				parte.Color = originales[i]
			end
		end
	end)
end

-- API publica para uso manual
ControladorEfectosVisuales.limpiarTodo = ControladorEfectosVisuales.limpiarTodo
ControladorEfectosVisuales.clearAll = ControladorEfectosVisuales.lpiarTodo  -- Alias para compatibilidad

print("[ControladorEfectosVisuales] 📦 Modulo cargado (use :activar() para iniciar)")

return ControladorEfectosVisuales
