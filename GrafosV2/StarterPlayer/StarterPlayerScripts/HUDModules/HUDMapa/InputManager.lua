-- InputManager.lua
-- Manejo de input para el mapa

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InputManager = {}

InputManager.clickConnection = nil
InputManager.selectores = {}
InputManager.nivelActual = nil
InputManager.onNodeClicked = nil

function InputManager.init(nivelModel, onNodeClickCallback)
	InputManager.nivelActual = nivelModel
	InputManager.onNodeClicked = onNodeClickCallback
	InputManager.collectSelectors()
end

function InputManager.collectSelectors()
	InputManager.selectores = {}

	if not InputManager.nivelActual then return end

	local grafosFolder = InputManager.nivelActual:FindFirstChild("Grafos")
	if not grafosFolder then return end

	for _, grafo in ipairs(grafosFolder:GetChildren()) do
		local nodosFolder = grafo:FindFirstChild("Nodos")
		if nodosFolder then
			for _, poste in ipairs(nodosFolder:GetChildren()) do
				local sel = poste:FindFirstChild("Selector")
				if sel then
					if sel:IsA("BasePart") then
						sel.CanQuery = true
						table.insert(InputManager.selectores, sel)
					elseif sel:IsA("Model") then
						for _, part in ipairs(sel:GetDescendants()) do
							if part:IsA("BasePart") and part.Name ~= "Attachment" then
								part.CanQuery = true
								table.insert(InputManager.selectores, part)
								break
							end
						end
					end
				end
			end
		end
	end
end

function InputManager.startListening()
	if InputManager.clickConnection then
		InputManager.clickConnection:Disconnect()
	end

	if #InputManager.selectores == 0 then
		warn("[InputManager] No hay selectores para click")
		return
	end

	InputManager.clickConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

		local camera = workspace.CurrentCamera
		local mouseLocation = UserInputService:GetMouseLocation()
		local ray = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)

		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = InputManager.selectores

		local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)

		if result and result.Instance then
			local selectorPart = result.Instance
			local poste = InputManager.getNodeFromSelector(selectorPart)

			if poste and InputManager.onNodeClicked then
				InputManager.onNodeClicked(poste, selectorPart)
			end
		end
	end)
end

function InputManager.getNodeFromSelector(selectorPart)
	local poste = selectorPart:FindFirstAncestorOfClass("Model")
	while poste and not poste:FindFirstChild("Selector") do
		poste = poste.Parent
		if poste == InputManager.nivelActual then 
			return nil
		end
	end
	return poste
end

function InputManager.stopListening()
	if InputManager.clickConnection then
		InputManager.clickConnection:Disconnect()
		InputManager.clickConnection = nil
	end
end

return InputManager