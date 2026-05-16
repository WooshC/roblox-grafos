-- StarterPlayerScripts/HUD/ModulosHUD/TimerEmergenciaHUD.lua
-- HUD de timer para misiones de emergencia con tiempo límite

local TimerEmergenciaHUD = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local jugador = Players.LocalPlayer
local playerGui = jugador:WaitForChild("PlayerGui")

-- Referencias UI
local _hudGui = nil
local _frame = nil
local _labelTiempo = nil
local _labelTitulo = nil
local _activo = false
local _parpadeoTween = nil

-- Colores
local COLOR_VERDE = Color3.fromRGB(46, 204, 64)
local COLOR_AMARILLO = Color3.fromRGB(241, 196, 15)
local COLOR_ROJO = Color3.fromRGB(231, 76, 60)
local COLOR_FONDO = Color3.fromRGB(30, 30, 30)
local COLOR_FONDO_ROJO = Color3.fromRGB(80, 20, 20)

function TimerEmergenciaHUD.init(hudGui)
	_hudGui = hudGui

	-- Crear frame principal dinámicamente
	_frame = Instance.new("Frame")
	_frame.Name = "TimerEmergencia"
	_frame.Size = UDim2.new(0, 220, 0, 70)
	_frame.Position = UDim2.new(0.5, -110, 0, 80)
	_frame.BackgroundColor3 = COLOR_FONDO
	_frame.BackgroundTransparency = 0.2
	_frame.BorderSizePixel = 0
	_frame.Visible = false
	_frame.ZIndex = 15
	_frame.Parent = hudGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = _frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = COLOR_VERDE
	stroke.Thickness = 2
	stroke.Parent = _frame

	-- Label de título
	_labelTitulo = Instance.new("TextLabel")
	_labelTitulo.Name = "Titulo"
	_labelTitulo.Size = UDim2.new(1, 0, 0, 22)
	_labelTitulo.Position = UDim2.new(0, 0, 0, 4)
	_labelTitulo.BackgroundTransparency = 1
	_labelTitulo.Text = "🚨 EMERGENCIA"
	_labelTitulo.TextColor3 = COLOR_ROJO
	_labelTitulo.TextScaled = true
	_labelTitulo.Font = Enum.Font.GothamBold
	_labelTitulo.ZIndex = 16
	_labelTitulo.Parent = _frame

	-- Label de tiempo
	_labelTiempo = Instance.new("TextLabel")
	_labelTiempo.Name = "Tiempo"
	_labelTiempo.Size = UDim2.new(1, 0, 0, 38)
	_labelTiempo.Position = UDim2.new(0, 0, 0, 26)
	_labelTiempo.BackgroundTransparency = 1
	_labelTiempo.Text = "01:00"
	_labelTiempo.TextColor3 = COLOR_VERDE
	_labelTiempo.TextScaled = true
	_labelTiempo.Font = Enum.Font.GothamBlack
	_labelTiempo.ZIndex = 16
	_labelTiempo.Parent = _frame

	print("[TimerEmergenciaHUD] Inicializado")
end

local function formatearTiempo(segundos)
	local m = math.floor(segundos / 60)
	local s = segundos % 60
	return string.format("%02d:%02d", m, s)
end

local function detenerParpadeo()
	if _parpadeoTween then
		_parpadeoTween:Cancel()
		_parpadeoTween = nil
	end
end

local function iniciarParpadeo()
	detenerParpadeo()
	local info = TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	_parpadeoTween = TweenService:Create(_frame, info, { BackgroundColor3 = COLOR_FONDO_ROJO })
	_parpadeoTween:Play()
end

function TimerEmergenciaHUD.actualizar(restante, texto, expirado, completada)
	if not _frame then return end

	if completada then
		-- Emergencia superada
		_frame.Visible = false
		detenerParpadeo()
		_activo = false
		return
	end

	if expirado or restante <= 0 then
		-- Tiempo agotado
		_labelTiempo.Text = "00:00"
		_labelTiempo.TextColor3 = COLOR_ROJO
		_labelTitulo.Text = "⏰ TIEMPO AGOTADO"
		_frame.BackgroundColor3 = COLOR_FONDO_ROJO
		iniciarParpadeo()
		task.delay(3, function()
			if _frame then _frame.Visible = false end
			detenerParpadeo()
			_activo = false
		end)
		return
	end

	-- Timer pausado (durante diálogos)
	if texto == "PAUSADO" then
		if not _activo then
			_activo = true
			_frame.Visible = true
		end
		_labelTiempo.Text = formatearTiempo(restante)
		_labelTitulo.Text = "⏸️ PAUSADO"
		_labelTiempo.TextColor3 = Color3.fromRGB(150, 150, 150)
		local stroke = _frame:FindFirstChildOfClass("UIStroke")
		if stroke then stroke.Color = Color3.fromRGB(150, 150, 150) end
		detenerParpadeo()
		_frame.BackgroundColor3 = COLOR_FONDO
		return
	end

	-- Timer activo
	if not _activo then
		_activo = true
		_frame.Visible = true
		detenerParpadeo()
		_frame.BackgroundColor3 = COLOR_FONDO
	end

	_labelTiempo.Text = formatearTiempo(restante)
	_labelTitulo.Text = "🚨 EMERGENCIA"

	-- Cambiar colores según tiempo restante
	local stroke = _frame:FindFirstChildOfClass("UIStroke")
	if restante <= 5 then
		_labelTiempo.TextColor3 = COLOR_ROJO
		if stroke then stroke.Color = COLOR_ROJO end
		iniciarParpadeo()
	elseif restante <= 15 then
		_labelTiempo.TextColor3 = COLOR_ROJO
		if stroke then stroke.Color = COLOR_ROJO end
		detenerParpadeo()
	elseif restante <= 30 then
		_labelTiempo.TextColor3 = COLOR_AMARILLO
		if stroke then stroke.Color = COLOR_AMARILLO end
		detenerParpadeo()
	else
		_labelTiempo.TextColor3 = COLOR_VERDE
		if stroke then stroke.Color = COLOR_VERDE end
		detenerParpadeo()
	end
end

function TimerEmergenciaHUD.ocultar()
	if _frame then
		_frame.Visible = false
		detenerParpadeo()
		_activo = false
	end
end

function TimerEmergenciaHUD.limpiar()
	ocultar()
	if _frame then
		_frame:Destroy()
		_frame = nil
	end
end

return TimerEmergenciaHUD
