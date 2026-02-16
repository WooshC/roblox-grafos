-- ================================================================
-- MissionsManager.lua (ACTUALIZADO CON SOPORTE DE ZONAS)
-- Gestiona panel de misiones y filtra por zona actual del jugador
-- ================================================================

local MissionsManager = {}
MissionsManager.__index = MissionsManager

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Dependencias
local LevelsConfig = nil
local NivelUtils = require(ReplicatedStorage:WaitForChild("Utilidades"):WaitForChild("NivelUtils"))
local player = Players.LocalPlayer

-- Estado
local state = nil
local misionFrame = nil
local tituloMision = nil
local estadoMisiones = {false, false, false, false, false, false, false, false}
local zonaActual = nil  -- 🔥 NUEVO: Zona actual del jugador
local modoVista = "zona"  -- 🔥 "zona" o "general"

-- ================================================================
-- INICIALIZACIÓN
-- ================================================================

--- Inyecta dependencias y referencias de UI
function MissionsManager.initialize(globalState, screenGui, deps)
	state = globalState
	LevelsConfig = deps.LevelsConfig

	misionFrame = screenGui:WaitForChild("MisionFrame", 5)
	tituloMision = misionFrame and misionFrame:FindFirstChild("Titulo")

	-- 🔥 NUEVO: Listener para cambios de zona del jugador
	player:GetAttributeChangedSignal("CurrentZone"):Connect(function()
		local newZone = player:GetAttribute("CurrentZone")
		MissionsManager:setZone(newZone)
	end)

	print("✅ MissionsManager: Inicializado con soporte de zonas")
end

--- Activa/desactiva panel de misiones
function MissionsManager:toggle()
	if not misionFrame then 
		warn("❌ MissionsManager: MisionFrame no referencia")
		return 
	end

	if misionFrame.Visible then
		self:hide()
	else
		self:show()
	end
end

--- Muestra panel de misiones
function MissionsManager:show()
	if not misionFrame then return end

	misionFrame.Visible = true
	self:_populateMissions()
end

--- Oculta panel de misiones
function MissionsManager:hide()
	if not misionFrame then return end

	misionFrame.Visible = false
end

-- ================================================================
-- 🔥 NUEVO: GESTIÓN DE ZONAS
-- ================================================================

--- Establece la zona actual y recarga misiones
function MissionsManager:setZone(zonaID)
	zonaActual = zonaID
	
	-- Si el panel está visible, actualizar
	if misionFrame and misionFrame.Visible then
		self:_populateMissions()
	end
	
	print("🗺️ MissionsManager: Zona cambiada a " .. tostring(zonaID))
end

--- Cambia entre vista por zona o vista general
function MissionsManager:setViewMode(mode)
	if mode ~= "zona" and mode ~= "general" then
		warn("⚠️ Modo inválido: " .. tostring(mode))
		return
	end
	
	modoVista = mode
	
	if misionFrame and misionFrame.Visible then
		self:_populateMissions()
	end
end

-- ================================================================
-- POBLACIÓN DE MISIONES (ACTUALIZADO)
-- ================================================================

--- Llena el panel con misiones filtradas
function MissionsManager:_populateMissions()
	if not misionFrame then return end

	local nivelID = player:GetAttribute("CurrentLevelID") or 0
	local config = LevelsConfig[nivelID] or LevelsConfig[0]
	
	-- Limpiar labels antiguos
	for _, child in ipairs(misionFrame:GetChildren()) do
		if child:IsA("TextLabel") and child ~= tituloMision then
			child:Destroy()
		end
	end

	-- 🔥 FILTRAR MISIONES SEGÚN MODO
	local listaMisiones = {}
	
	if modoVista == "zona" and zonaActual and zonaActual ~= "" then
		-- MODO ZONA: Mostrar solo misiones de la zona actual
		listaMisiones = NivelUtils.getMissionsByZone(nivelID, zonaActual)
		
		-- Actualizar título
		if tituloMision then
			local zonaConfig = NivelUtils.getZoneConfig(nivelID, zonaActual)
			tituloMision.Text = zonaConfig and zonaConfig.Descripcion or zonaActual
		end
		
	elseif modoVista == "zona" and (not zonaActual or zonaActual == "") then
		-- FUERA DE ZONA: Mostrar resumen de todas las zonas
		self:_showZoneSummary(nivelID, config)
		return
		
	else
		-- MODO GENERAL: Mostrar todas las misiones
		listaMisiones = config.Misiones or {}
		
		if tituloMision then
			tituloMision.Text = "📋 MISIONES"
		end
	end

	-- Crear labels para cada misión
	for i, misionConfig in ipairs(listaMisiones) do
		self:_createMissionLabel(misionConfig, i)
	end
	
	print("📋 MissionsManager: " .. #listaMisiones .. " misiones mostradas (modo: " .. modoVista .. ")")
end

--- 🔥 NUEVO: Muestra resumen de zonas cuando está fuera
function MissionsManager:_showZoneSummary(nivelID, config)
	if tituloMision then
		tituloMision.Text = "🗺️ VISTA GENERAL"
	end
	
	local zonas = NivelUtils.getZoneList(nivelID)
	
	for _, zona in ipairs(zonas) do
		local misiones = NivelUtils.getMissionsByZone(nivelID, zona.ID)
		local completadas = 0
		
		for _, m in ipairs(misiones) do
			if estadoMisiones[m.ID] then
				completadas = completadas + 1
			end
		end
		
		-- Crear label de resumen
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -10, 0, 30)
		lbl.BackgroundTransparency = 0.7
		lbl.BackgroundColor3 = completadas == #misiones 
			and Color3.fromRGB(46, 204, 113) 
			or Color3.fromRGB(52, 73, 94)
		
		local icon = completadas == #misiones and "✅" or "📍"
		lbl.Text = string.format("%s %s (%d/%d)", icon, zona.Descripcion or zona.ID, completadas, #misiones)
		
		lbl.TextColor3 = Color3.new(1, 1, 1)
		lbl.Font = Enum.Font.GothamMedium
		lbl.TextSize = 14
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent = misionFrame
		
		-- Esquinas redondeadas
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = lbl
	end
	
	-- Misiones bonus (sin zona)
	local bonus = NivelUtils.getGlobalMissions(nivelID)
	if #bonus > 0 then
		local sepLabel = Instance.new("TextLabel")
		sepLabel.Size = UDim2.new(1, 0, 0, 25)
		sepLabel.BackgroundTransparency = 1
		sepLabel.Text = "⭐ BONUS"
		sepLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		sepLabel.Font = Enum.Font.GothamBold
		sepLabel.TextSize = 16
		sepLabel.TextXAlignment = Enum.TextXAlignment.Left
		sepLabel.Parent = misionFrame
		
		for _, mision in ipairs(bonus) do
			self:_createMissionLabel(mision, mision.ID)
		end
	end
end

--- Crea un label para una misión
function MissionsManager:_createMissionLabel(misionConfig, indice)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -10, 0, 25)
	lbl.BackgroundTransparency = 1

	-- Extraer texto de la misión
	local texto = type(misionConfig) == "table" 
		and (misionConfig.Texto or "Misión sin texto") 
		or tostring(misionConfig)

	-- Aplicar estado guardado
	if estadoMisiones[indice] or (type(misionConfig) == "table" and estadoMisiones[misionConfig.ID]) then
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

-- ================================================================
-- ACTUALIZACIÓN DE ESTADO (SIN CAMBIOS)
-- ================================================================

--- Actualiza estado de una misión específica
function MissionsManager:updateMissionStatus(indice, completada)
	estadoMisiones[indice] = completada

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
	zonaActual = nil
end

return MissionsManager