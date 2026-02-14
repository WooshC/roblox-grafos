-- ================================================================
-- MissionsManager.lua
-- Gestiona panel de misiones y actualizaciones de estado
-- ================================================================

local MissionsManager = {}
MissionsManager.__index = MissionsManager

local Players = game:GetService("Players")

-- Dependencias
local LevelsConfig = nil
local player = Players.LocalPlayer

-- Estado
local state = nil
local misionFrame = nil
local tituloMision = nil
local estadoMisiones = {false, false, false, false, false, false, false, false}

-- ================================================================
-- INICIALIZACIÓN
-- ================================================================

--- Inyecta dependencias y referencias de UI
function MissionsManager.initialize(globalState, screenGui, deps)
	state = globalState
	LevelsConfig = deps.LevelsConfig

	misionFrame = screenGui:WaitForChild("MisionFrame", 5)
	tituloMision = misionFrame and misionFrame:FindFirstChild("Titulo")

	print("✅ MissionsManager: Inicializado")
end

--- Activa/desactiva panel de misiones
-- (Implementado en ClienteUI para resolver dependencias circulares)
function MissionsManager:toggle()
	-- Stub placeholder
    warn("MissionsManager: toggle() should be overwritten by ClienteUI")
end

--- Muestra panel de misiones
function MissionsManager:show()
	if not misionFrame then return end

	misionFrame.Visible = true
	self:_populateMissions()

	print("✅ MissionsManager: Panel mostrado")
end

--- Oculta panel de misiones
function MissionsManager:hide()
	if not misionFrame then return end

	misionFrame.Visible = false

	print("✅ MissionsManager: Panel ocultado")
end

--- Llena el panel con misiones del nivel actual
function MissionsManager:_populateMissions()
	if not misionFrame then return end

	local nivelID = player:GetAttribute("CurrentLevelID") or 0
	local config = LevelsConfig[nivelID] or LevelsConfig[0]
	local listaMisiones = config.Misiones or {"¡Conecta la red eléctrica!"}

	-- Limpiar labels antiguos
	for _, child in ipairs(misionFrame:GetChildren()) do
		if child:IsA("TextLabel") and child ~= tituloMision then
			child:Destroy()
		end
	end

	-- Crear nuevos labels
	for i, misionConfig in ipairs(listaMisiones) do
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -10, 0, 25)
		lbl.BackgroundTransparency = 1

		-- Extraer texto de la misión
		local texto = type(misionConfig) == "table" 
			and (misionConfig.Texto or "Misión sin texto") 
			or tostring(misionConfig)

		-- Aplicar estado guardado
		if estadoMisiones[i] then
			lbl.Text = "✅ " .. texto
			lbl.TextColor3 = Color3.fromRGB(46, 204, 113)
			lbl.TextTransparency = 0.3
		else
			lbl.Text = "  " .. texto
			lbl.TextColor3 = Color3.new(1, 1, 1)
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

--- Actualiza estado de una misión específica
function MissionsManager:updateMissionStatus(indice, completada)
	estadoMisiones[indice] = completada

	-- Si panel no está visible, no actualizar visualmente
	if not misionFrame or not misionFrame.Visible then
		return
	end

	-- Buscar label correspondiente
	local labels = {}
	for _, child in ipairs(misionFrame:GetChildren()) do
		if child:IsA("TextLabel") and child ~= tituloMision then
			table.insert(labels, child)
		end
	end

	local lbl = labels[indice]
	if lbl and not string.find(lbl.Text, "✅") then
		lbl.TextColor3 = Color3.fromRGB(46, 204, 113)
		lbl.TextTransparency = 0.3
		lbl.Text = "✅ " .. lbl.Text
		print("✅ Misión " .. indice .. " marcada como completada")
	end
end

--- Obtiene estado de misión
function MissionsManager:getMissionStatus(indice)
	return estadoMisiones[indice] or false
end

--- Resetea todas las misiones
function MissionsManager:resetAll()
	for i = 1, 8 do
		estadoMisiones[i] = false
	end
	print("🔄 MissionsManager: Todas las misiones reseteadas")
end

return MissionsManager