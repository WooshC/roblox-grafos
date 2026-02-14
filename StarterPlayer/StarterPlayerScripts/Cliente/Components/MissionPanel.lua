local MissionPanel = {}

function MissionPanel.show(screenGui, missionList, missionStatus)
	local misionFrame = screenGui:FindFirstChild("MisionFrame")
	if not misionFrame then return end
	
	misionFrame.Visible = true
	
	-- Limpiar hijos existentes (menos titulo y boton cerrar)
	local tituloMision = misionFrame:FindFirstChild("Titulo")
	local btnCerrar = misionFrame:FindFirstChild("BtnCerrar")
	
	for _, child in ipairs(misionFrame:GetChildren()) do
		if child:IsA("TextLabel") and child ~= tituloMision and child ~= btnCerrar then
			child:Destroy()
		end
	end
	
	-- Poblar lista
	for i, misionConfig in ipairs(missionList or {}) do
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -10, 0, 25)
		lbl.BackgroundTransparency = 1

		local texto
		if type(misionConfig) == "table" then
			texto = misionConfig.Texto or "Misión sin texto"
		else
			texto = tostring(misionConfig)
		end

		local completada = missionStatus and missionStatus[i]

		if completada then
			lbl.Text = "✅ " .. texto
			lbl.TextColor3 = Color3.fromRGB(46, 204, 113)
			lbl.TextTransparency = 0.3
		else
			lbl.Text = "  " .. texto
			lbl.TextColor3 = Color3.new(1,1,1)
			lbl.TextTransparency = 0
		end

		lbl.Font = Enum.Font.GothamMedium
		lbl.TextSize = 14
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextWrapped = true
		lbl.AutomaticSize = Enum.AutomaticSize.Y
		lbl.Parent = misionFrame
	end
end

function MissionPanel.hide(screenGui)
	if screenGui then
		local misionFrame = screenGui:FindFirstChild("MisionFrame")
		if misionFrame then
			misionFrame.Visible = false
		end
	end
end

function MissionPanel.updateStatus(screenGui, index, completed)
	local misionFrame = screenGui:FindFirstChild("MisionFrame")
	if not misionFrame or not misionFrame.Visible then return end
	
	local labels = {}
	local tituloMision = misionFrame:FindFirstChild("Titulo")
	local btnCerrar = misionFrame:FindFirstChild("BtnCerrar")
	
	for _, child in ipairs(misionFrame:GetChildren()) do
		if child:IsA("TextLabel") and child ~= tituloMision and child ~= btnCerrar then
			table.insert(labels, child)
		end
	end
	
	local lbl = labels[index]
	if lbl and not string.find(lbl.Text, "✅") and completed then
		lbl.TextColor3 = Color3.fromRGB(46, 204, 113)
		lbl.TextTransparency = 0.3
		lbl.Text = "✅ " .. lbl.Text
	end
end

return MissionPanel
