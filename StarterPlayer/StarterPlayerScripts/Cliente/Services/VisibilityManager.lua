-- ================================================================
-- VisibilityManager.lua
-- Controla visibilidad de botones según contexto (menú/gameplay)
-- ================================================================

local VisibilityManager = {}
VisibilityManager.__index = VisibilityManager

local RunService = game:GetService("RunService")

-- Estado
local state = nil
local enDialogo = false

-- Referencias de UI
local btnReiniciar = nil
local btnMapa = nil
local btnAlgo = nil
local btnMisiones = nil
local btnMatriz = nil
local btnFinalizar = nil
local lblPuntaje = nil
local minimapGui = nil

-- Lista de botones de gameplay
local botonesGameplay = {}

-- ================================================================
-- INICIALIZACIÓN
-- ================================================================

--- Inyecta referencias de UI y estado global
function VisibilityManager.initialize(globalState, screenGui, minimapGuiRef)
	state = globalState
	minimapGui = minimapGuiRef

	-- Obtener referencias a botones
	btnReiniciar = screenGui:WaitForChild("BtnReiniciar", 5)
	btnMapa = screenGui:WaitForChild("BtnMapa", 5)
	btnAlgo = screenGui:WaitForChild("BtnAlgo", 5)
	btnMisiones = screenGui:WaitForChild("BtnMisiones", 5)
	btnMatriz = screenGui:WaitForChild("BtnMatriz", 5)
	btnFinalizar = screenGui:WaitForChild("BtnFinalizar", 5)
	lblPuntaje = screenGui:WaitForChild("LabelPuntaje", 5)

	-- Construir tabla de botones
	botonesGameplay = {btnReiniciar, btnMapa, btnAlgo, btnMisiones, btnMatriz, btnFinalizar, lblPuntaje}

	-- Visibilidad inicial (no en menú)
	VisibilityManager:updateGameplayUI(true)

	print("✅ VisibilityManager: Inicializado")
end

--- Inicia detector de cambio de menú y visibilidad del techo
function VisibilityManager:init()
	-- Loop de monitoreo de cámara (Menú/Gameplay)
	task.spawn(function()
		while task.wait(0.5) do
			local cam = workspace.CurrentCamera
			if cam then
				if cam.CameraType == Enum.CameraType.Scriptable and not state.mapaActivo then
					-- En menú (cámara scriptable + mapa no activo)
					if not state.enMenu then
						self:updateGameplayUI(true)
					end
				elseif cam.CameraType == Enum.CameraType.Custom then
					-- En gameplay
					if state.enMenu then
						self:updateGameplayUI(false)
					end
				end
			end
		end
	end)

	-- Loop de monitoreo para el techo (Mapa Activo/Inactivo)
	-- Se usa Heartbeat para respuesta rápida al abrir/cerrar mapa
	local lastMapState = false
	RunService.Heartbeat:Connect(function()
		if state.mapaActivo ~= lastMapState then
			lastMapState = state.mapaActivo
			self:updateTechoVisibility()
		end
	end)
end

--- Establece si el jugador está en un diálogo
function VisibilityManager:setDialogueMode(active)
	enDialogo = active
	self:updateGameplayUI(state.enMenu)
end

--- Actualiza visibilidad de botones según estado
function VisibilityManager:updateGameplayUI(estaEnMenu)
	state.enMenu = estaEnMenu

	-- Si está en diálogo, forzar ocultar todo (similar a menú)
	local ocultarTodo = estaEnMenu or enDialogo

	-- Minimap HUD visibility
	if minimapGui then
		minimapGui.Enabled = not ocultarTodo
	end

	for _, btn in ipairs(botonesGameplay) do
		if not btn then continue end

		if ocultarTodo then
			-- Ocultar todo en menú o diálogo
			btn.Visible = false
		else
			-- En gameplay normal, mostrar según condiciones
			if btn == btnFinalizar then
				btn.Visible = false -- Se activa por evento
			elseif btn == btnMapa then
				btn.Visible = state.tieneMapa
			elseif btn == btnAlgo then
				btn.Visible = state.tieneAlgo
			elseif btn == lblPuntaje then
				btn.Visible = true
			else
				btn.Visible = true
			end
		end
	end
end

--- Actualiza visibilidad individual de un botón
function VisibilityManager:updateButton(btnName, visible)
	local btn = self:getButton(btnName)
	if btn then
		btn.Visible = visible
	end
end

--- Obtiene referencia a botón por nombre
function VisibilityManager:getButton(btnName)
	if btnName == "Reiniciar" then return btnReiniciar end
	if btnName == "Mapa" then return btnMapa end
	if btnName == "Algo" then return btnAlgo end
	if btnName == "Misiones" then return btnMisiones end
	if btnName == "Matriz" then return btnMatriz end
	if btnName == "Finalizar" then return btnFinalizar end
	if btnName == "Puntaje" then return lblPuntaje end
	return nil
end

--- Toggles Techo visibility in NivelActual
function VisibilityManager:toggleTecho(visible)
	local opacity = visible and 0 or 1
	local active = visible
	
	-- Buscar objeto "Techo" SOLAMENTE en NivelActual
	local nivelActual = workspace:FindFirstChild("NivelActual")
	if nivelActual then
		local techoObj = nivelActual:FindFirstChild("Techo", true) -- Puede ser Part, Model o Folder
		
		if techoObj then
			local parts = {}
			
			-- Si el objeto mismo es una parte
			if techoObj:IsA("BasePart") then
				table.insert(parts, techoObj)
			end
			
			-- Y sus descendientes
			for _, p in ipairs(techoObj:GetDescendants()) do
				if p:IsA("BasePart") then
					table.insert(parts, p)
				end
			end
			
			for _, part in ipairs(parts) do
				part.Transparency = opacity
				part.CanCollide = active
				part.CastShadow = active
				part.CanQuery = active -- Evita que raycasts lo detecten
				part.CanTouch = active -- Evita eventos de touch
			end
		end
	end
end

--- Wrapper para actualizar visibilidad de techo basado en estado global (usado por MapManager o externamente)
function VisibilityManager:updateTechoVisibility()
	-- El techo debe estar visible SOLO si NO está el mapa activo
	-- (Y opcionalmente si no estamos en modo cutscene, pero eso lo maneja el diálogo aparte por ahora)
	local debeMostrarTecho = not state.mapaActivo
	self:toggleTecho(debeMostrarTecho)
end

return VisibilityManager