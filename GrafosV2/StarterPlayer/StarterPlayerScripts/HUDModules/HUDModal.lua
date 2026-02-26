-- HUDModal.lua
-- Maneja el modal de confirmación para salir al menú principal
-- Uso: local HUDModal = require(HUDModules.HUDModal)

local HUDModal = {}

local parentHud = nil
local fadeModule = nil

local modalFondo = nil
local btnCancelar = nil
local btnConfirmar = nil
local btnSalir = nil
local isReturning = false

function HUDModal.init(hudRef, fadeRef)
	parentHud = hudRef
	fadeModule = fadeRef
	
	modalFondo = parentHud:FindFirstChild("ModalSalirFondo", true)
	btnCancelar = parentHud:FindFirstChild("BtnCancelarSalir", true)
	btnConfirmar = parentHud:FindFirstChild("BtnConfirmarSalir", true)
	btnSalir = parentHud:FindFirstChild("BtnSalir", true) or parentHud:FindFirstChild("BtnSalirMain", true)
	
	HUDModal._connectButtons()
end

function HUDModal._showModal()
	if modalFondo then
		modalFondo.Visible = true
	end
end

function HUDModal._hideModal()
	if modalFondo then
		modalFondo.Visible = false
	end
end

function HUDModal._doReturnToMenu()
	if isReturning then return end
	isReturning = true
	
	HUDModal._hideModal()
	
	fadeModule.fadeToBlack(0.4, function()
		-- Enviar evento al servidor para volver al menú
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local returnToMenuEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes"):WaitForChild("ReturnToMenu")
		if returnToMenuEvent then
			returnToMenuEvent:FireServer()
		end
		
		-- Ocultar pantalla de victoria si está visible
		local victoriaFondo = parentHud:FindFirstChild("VictoriaFondo", true)
		if victoriaFondo then
			victoriaFondo.Visible = false
		end
		
		fadeModule.reset()
		isReturning = false
	end)
end

function HUDModal._connectButtons()
	if btnSalir then
		btnSalir.MouseButton1Click:Connect(HUDModal._showModal)
	end
	if btnCancelar then
		btnCancelar.MouseButton1Click:Connect(HUDModal._hideModal)
	end
	if btnConfirmar then
		btnConfirmar.MouseButton1Click:Connect(HUDModal._doReturnToMenu)
	end
end

return HUDModal
