-- ================================================================
-- VisibilityManager.lua
-- Controla visibilidad de botones según contexto (menú/gameplay)
-- ================================================================

local VisibilityManager = {}
VisibilityManager.__index = VisibilityManager

local RunService = game:GetService("RunService")

-- Estado
local state = nil

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

--- Inicia detector de cambio de menú
function VisibilityManager:init()
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
end

--- Actualiza visibilidad de botones según estado
function VisibilityManager:updateGameplayUI(estaEnMenu)
	state.enMenu = estaEnMenu

	-- Minimap HUD visibility
	if minimapGui then
		minimapGui.Enabled = not estaEnMenu
	end

	for _, btn in ipairs(botonesGameplay) do
		if not btn then continue end

		if estaEnMenu then
			-- Ocultar todo en menú
			btn.Visible = false
		else
			-- En gameplay, mostrar según condiciones
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

return VisibilityManager