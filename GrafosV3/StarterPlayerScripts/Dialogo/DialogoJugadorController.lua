-- StarterPlayerScripts/Dialogo/DialogoJugadorController.lua
-- Control del jugador durante diálogos: movimiento, HUD, click aéreo.
-- Extraído de ControladorDialogo.client.lua para cumplir SRP.
-- NO conoce nada sobre diálogos, líneas de texto, ni eventos al servidor
-- (excepto los necesarios para click aéreo: ConectarDesdeMapa / MapaClickNodo).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")

local DialogoJugadorController = {}

local jugador = Players.LocalPlayer
local playerGui = jugador:WaitForChild("PlayerGui")

local ServicioCamara = require(RS:WaitForChild("Compartido"):WaitForChild("ServicioCamara"))

-- ═══════════════════════════════════════════════════════════════════════════════
-- ESTADO INTERNO
-- ═══════════════════════════════════════════════════════════════════════════════

local estadoJugador = {
	humanoid = nil,
	camaraOriginal = nil,
	cframeOriginal = nil,
	walkSpeedOriginal = nil,
	jumpPowerOriginal = nil,
	jumpHeightOriginal = nil,
}

local _clickAereoConexion = nil
local _primerNodoAereo    = nil

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPERS (frágiles, mantenidos tal cual para zero-breaking)
-- ═══════════════════════════════════════════════════════════════════════════════

function DialogoJugadorController.obtenerHudGui()
	local gui = playerGui:FindFirstChild("GUIExploradorV2")
	if gui then return gui end

	for _, child in ipairs(playerGui:GetChildren()) do
		if child:IsA("ScreenGui") then
			if child.Name:match("HUD") or child.Name:match("Explorador") or child.Name:match("Gameplay") then
				return child
			end
		end
	end
	return nil
end

function DialogoJugadorController.obtenerModuloMapa()
	local playerScripts = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerScripts")
	if not playerScripts then return nil end
	local HUD = playerScripts:FindFirstChild("HUD")
	if not HUD then return nil end
	local ModulosHUD = HUD:FindFirstChild("ModulosHUD")
	if not ModulosHUD then return nil end
	local exito, modulo = pcall(function()
		return require(ModulosHUD:FindFirstChild("ModuloMapa"))
	end)
	return exito and modulo or nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- MOVIMIENTO
-- ═══════════════════════════════════════════════════════════════════════════════

function DialogoJugadorController.bloquear(config)
	config = config or {}
	local personaje = jugador.Character
	if not personaje then return end

	local humanoid = personaje:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Guardar estado original
	estadoJugador.humanoid = humanoid
	estadoJugador.walkSpeedOriginal = humanoid.WalkSpeed
	estadoJugador.jumpPowerOriginal = humanoid.JumpPower
	estadoJugador.jumpHeightOriginal = humanoid.JumpHeight

	if config.bloquearMovimiento then
		humanoid.WalkSpeed = 0
	end

	if config.bloquearSalto then
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
	end

	if config.apuntarCamara then
		ServicioCamara.bloquear()
	end

	print("[DialogoJugadorController] Movimiento bloqueado")
end

function DialogoJugadorController.desbloquear()
	if estadoJugador.humanoid then
		local personaje = jugador.Character
		if personaje then
			local humanoid = personaje:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = estadoJugador.walkSpeedOriginal or 16
				humanoid.JumpPower = estadoJugador.jumpPowerOriginal or 50
				humanoid.JumpHeight = estadoJugador.jumpHeightOriginal or 7.2
			end
		end
		ServicioCamara.restaurar(0.5)
		print("[DialogoJugadorController] Movimiento restaurado")
	end

	estadoJugador = {
		humanoid = nil,
		camaraOriginal = nil,
		cframeOriginal = nil,
		walkSpeedOriginal = nil,
		jumpPowerOriginal = nil,
		jumpHeightOriginal = nil,
	}
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- HUD
-- ═══════════════════════════════════════════════════════════════════════════════

function DialogoJugadorController.ocultarHUD()
	local hud = DialogoJugadorController.obtenerHudGui()
	if hud then
		hud:SetAttribute("EnabledAntesDialogo", hud.Enabled)
		hud.Enabled = false
		print("[DialogoJugadorController] HUD ocultado:", hud.Name)
	else
		warn("[DialogoJugadorController] No se encontró HUD para ocultar")
	end
end

function DialogoJugadorController.mostrarHUD()
	local hud = DialogoJugadorController.obtenerHudGui()
	if hud then
		local eraEnabled = hud:GetAttribute("EnabledAntesDialogo")
		if eraEnabled ~= false then
			hud.Enabled = true
		end
		print("[DialogoJugadorController] HUD mostrado:", hud.Name)
	else
		for _, gui in ipairs(playerGui:GetChildren()) do
			if gui:IsA("ScreenGui") and gui:GetAttribute("EnabledAntesDialogo") ~= nil then
				gui.Enabled = gui:GetAttribute("EnabledAntesDialogo")
				print("[DialogoJugadorController] HUD restaurado (fallback):", gui.Name)
			end
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CLICK AÉREO
-- ═══════════════════════════════════════════════════════════════════════════════

local function _recolectarSelectores()
	local lista = {}
	local nivel = workspace:FindFirstChild("NivelActual")
	if not nivel then return lista end
	local grafos = nivel:FindFirstChild("Grafos")
	if not grafos then return lista end
	for _, grafo in ipairs(grafos:GetChildren()) do
		local nodos = grafo:FindFirstChild("Nodos")
		if nodos then
			for _, nodo in ipairs(nodos:GetChildren()) do
				if nodo:IsA("Model") then
					local sel = nodo:FindFirstChild("Selector")
					if sel and sel:IsA("BasePart") then
						table.insert(lista, sel)
					end
				end
			end
		end
	end
	return lista
end

---Activa el modo click aéreo (raycast desde cámara cenital).
-- @param onSeleccionarNodo function(string) — callback cuando el jugador selecciona un nodo
function DialogoJugadorController.activarClickAereo(onSeleccionarNodo)
	if _clickAereoConexion then return end

	local selectores = _recolectarSelectores()
	if #selectores == 0 then
		warn("[DialogoJugadorController] Click aéreo: sin selectores")
		return
	end

	-- Suprimir ClickDetectors del servidor mientras el diálogo maneja los clics
	jugador:SetAttribute("MapaAbierto", true)

	local camara = workspace.CurrentCamera
	local eventos = RS:WaitForChild("EventosGrafosV3")
	local remotos = eventos:WaitForChild("Remotos")
	local conectarEvento = remotos:FindFirstChild("ConectarDesdeMapa")
	local mapaNodoEvento  = remotos:FindFirstChild("MapaClickNodo")

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = selectores

	_primerNodoAereo = nil

	_clickAereoConexion = UIS.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

		local mousePos = UIS:GetMouseLocation()
		local ray = camara:ViewportPointToRay(mousePos.X, mousePos.Y)
		local resultado = workspace:Raycast(ray.Origin, ray.Direction * 2000, params)

		if not (resultado and resultado.Instance) then
			_primerNodoAereo = nil
			return
		end

		local selector  = resultado.Instance
		local nodo      = selector.Parent
		if not (nodo and nodo:IsA("Model")) then return end
		local nombreNodo = nodo.Name

		if _primerNodoAereo == nil then
			_primerNodoAereo = nombreNodo
			if mapaNodoEvento then mapaNodoEvento:FireServer(nombreNodo) end
			if onSeleccionarNodo then
				onSeleccionarNodo(nombreNodo)
			end
		elseif _primerNodoAereo == nombreNodo then
			_primerNodoAereo = nil  -- cancelar
		else
			local nodoA = _primerNodoAereo
			_primerNodoAereo = nil
			if conectarEvento then
				conectarEvento:FireServer(nodoA, nombreNodo)
			end
		end
	end)

	print("[DialogoJugadorController] Click aéreo activado —", #selectores, "selectores")
end

function DialogoJugadorController.desactivarClickAereo()
	if _clickAereoConexion then
		_clickAereoConexion:Disconnect()
		_clickAereoConexion = nil
	end
	_primerNodoAereo = nil
	-- Limpiar atributo sólo si el mapa real no está abierto
	local mapa = DialogoJugadorController.obtenerModuloMapa()
	if not (mapa and mapa.estaAbierto and mapa.estaAbierto()) then
		jugador:SetAttribute("MapaAbierto", nil)
	end
	print("[DialogoJugadorController] Click aéreo desactivado")
end

return DialogoJugadorController
