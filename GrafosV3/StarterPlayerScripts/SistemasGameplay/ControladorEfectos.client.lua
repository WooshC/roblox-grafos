-- StarterPlayerScripts/SistemasGameplay/ControladorEfectos.client.lua
-- Controlador de efectos visuales en el cliente
-- Recibe eventos del servidor y aplica efectos usando los módulos de Efectos

local Players = game:GetService("Players")
local Replicado = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local jugador = Players.LocalPlayer

-- Cargar módulos de efectos
local Efectos = Replicado:WaitForChild("Efectos")
local EfectosNodo = require(Efectos:WaitForChild("EfectosNodo"))
local EfectosCable = require(Efectos:WaitForChild("EfectosCable"))

-- Eventos
local Eventos = Replicado:WaitForChild("EventosGrafosV3")
local Remotos = Eventos:WaitForChild("Remotos")

-- Referencias a eventos remotos
local notificarSeleccionNodo = Remotos:WaitForChild("NotificarSeleccionNodo")
local cableDragEvent = Remotos:WaitForChild("CableDragEvent")
local pulsoEvent = Remotos:WaitForChild("PulsoEvent")

-- Estado local
local previewArrastre = nil

-- ═══════════════════════════════════════════════════════════════════════════════
-- HANDLERS DE EFECTOS DE NODO
-- ═══════════════════════════════════════════════════════════════════════════════

local function alSeleccionarNodo(modeloNodo, modelosAdyacentes)
	-- Resetear selección anterior
	EfectosNodo.limpiarSeleccion()
	
	-- Establecer nueva selección
	local nombresAdyacentes = {}
	if modelosAdyacentes then
		for _, modelo in ipairs(modelosAdyacentes) do
			table.insert(nombresAdyacentes, modelo.Name)
		end
	end
	EfectosNodo.establecerSeleccion(modeloNodo.Name, nombresAdyacentes)
	
	-- Aplicar efectos visuales
	local selector = modeloNodo:FindFirstChild("Selector")
	if selector then
		local parte = selector:IsA("BasePart") and selector or selector:FindFirstChildWhichIsA("BasePart")
		if parte then
			EfectosNodo.aplicarASelector(parte, "SELECCIONADO")
		end
	end
	
	-- Aplicar efectos a adyacentes
	for _, modeloAdyacente in ipairs(modelosAdyacentes or {}) do
		local selectorAdj = modeloAdyacente:FindFirstChild("Selector")
		if selectorAdj then
			local parteAdj = selectorAdj:IsA("BasePart") and selectorAdj or selectorAdj:FindFirstChildWhichIsA("BasePart")
			if parteAdj then
				EfectosNodo.aplicarASelector(parteAdj, "ADYACENTE")
			end
		end
	end
end

local function alCancelarSeleccion()
	-- Resetear todos los selectores del nivel
	local nivelActual = Workspace:FindFirstChild("NivelActual")
	if nivelActual then
		for _, selector in ipairs(nivelActual:GetDescendants()) do
			if selector.Name == "Selector" then
				local parte = selector:IsA("BasePart") and selector or selector:FindFirstChildWhichIsA("BasePart")
				if parte then
					EfectosNodo.resetearSelector(parte)
				end
			end
		end
	end
	
	EfectosNodo.limpiarSeleccion()
end

local function alConexionInvalida(modeloNodo)
	-- Flash de error en el nodo
	local selector = modeloNodo:FindFirstChild("Selector")
	if selector then
		local parte = selector:IsA("BasePart") and selector or selector:FindFirstChildWhichIsA("BasePart")
		if parte then
			EfectosNodo.flashError(parte)
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- HANDLERS DE EFECTOS DE CABLE
-- ═══════════════════════════════════════════════════════════════════════════════

local function iniciarPreviewArrastre(attachment, vecinos)
	-- El preview se maneja con el mouse
	if previewArrastre then
		previewArrastre.destruir()
		previewArrastre = nil
	end
end

local function detenerPreviewArrastre()
	if previewArrastre then
		previewArrastre.destruir()
		previewArrastre = nil
	end
end

local function iniciarPulso(nodoOrigen, nodoDestino, esBidireccional)
	-- Buscar el beam entre estos nodos
	local nivelActual = Workspace:FindFirstChild("NivelActual")
	if not nivelActual then return end
	
	-- Buscar cable por nombre
	local nomA, nomB = nodoOrigen.Name, nodoDestino.Name
	if nomA > nomB then nomA, nomB = nomB, nomA end
	local nombreCable = "Cable_" .. nomA .. "|" .. nomB
	
	for _, beam in ipairs(nivelActual:GetDescendants()) do
		if beam:IsA("Beam") and beam.Name == nombreCable then
			EfectosCable.iniciarPulso(beam, esBidireccional)
			break
		end
	end
end

local function detenerTodosLosPulsos()
	EfectosCable.detenerTodosLosPulsos()
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONEXION DE EVENTOS
-- ═══════════════════════════════════════════════════════════════════════════════

-- NotificarSeleccionNodo: selección, deselección, errores
notificarSeleccionNodo.OnClientEvent:Connect(function(tipoEvento, arg1, arg2)
	if tipoEvento == "NodoSeleccionado" then
		alSeleccionarNodo(arg1, arg2)
		
	elseif tipoEvento == "SeleccionCancelada" then
		alCancelarSeleccion()
		
	elseif tipoEvento == "ConexionInvalida" then
		alConexionInvalida(arg1)
		
	elseif tipoEvento == "ConexionCompletada" then
		-- La conexión se completó, mantener selección o resetear según diseño
		alCancelarSeleccion()
		
	elseif tipoEvento == "CableDesconectado" then
		-- Opcional: efecto visual de desconexión
		print("[ControladorEfectos] Cable desconectado:", arg1, "-", arg2)
	end
end)

-- CableDragEvent: preview de arrastre
cableDragEvent.OnClientEvent:Connect(function(accion, attachment, vecinos)
	if accion == "Iniciar" then
		iniciarPreviewArrastre(attachment, vecinos)
	elseif accion == "Detener" then
		detenerPreviewArrastre()
	end
end)

-- PulsoEvent: efectos de energía
pulsoEvent.OnClientEvent:Connect(function(accion, arg1, arg2, arg3)
	if accion == "IniciarPulso" then
		iniciarPulso(arg1, arg2, arg3)
	elseif accion == "DetenerTodos" then
		detenerTodosLosPulsos()
	end
end)

print("[ControladorEfectos] Sistema de efectos inicializado")
