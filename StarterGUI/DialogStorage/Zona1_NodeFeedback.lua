-- Zona1_NodeFeedback.lua
-- Muestra retroalimentación de diálogo al seleccionar nodos en la Zona 1.
-- Script independiente de Zona1_dialogo.lua para evitar dependencias de OnClose
-- (el DialogueKit no implementa el callback OnClose).

local dialogueKitModule = require(script.Parent.Parent.DialogueKit)
local DialogueGenerator  = require(script.Parent.DialogueGenerator)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))

local DialogueVisibilityManager = require(
	ReplicatedStorage:WaitForChild("DialogueVisibilityManager", 5)
)

-- ================================================================
-- CONFIG
-- ================================================================

local ZONA_OBJETIVO = "Zona_Estacion_1"
local SKIN_NAME     = "Hotline"
local NODO_A        = "Nodo1_z1"
local NODO_B        = "Nodo2_z1"

-- Flags de un solo disparo
local feedbackNodoMostrado    = false
local feedbackConexionMostrado = false

-- ================================================================
-- FLECHA AZUL
-- ================================================================

local arrowPart      = nil
local arrowBounceConn = nil

local function removerFlechaAzul()
	if arrowBounceConn then
		arrowBounceConn:Disconnect()
		arrowBounceConn = nil
	end
	if arrowPart and arrowPart.Parent then
		arrowPart:Destroy()
	end
	arrowPart = nil
end

local function findPosteModel(name)
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Model") and obj.Name == name then
			return obj
		end
	end
	return nil
end

local function crearFlechaAzul(nodoModel)
	removerFlechaAzul()

	local base = nodoModel.PrimaryPart or nodoModel:FindFirstChildWhichIsA("BasePart")
	if not base then return end

	-- Parte invisible anclada sobre el nodo
	arrowPart = Instance.new("Part")
	arrowPart.Size         = Vector3.new(0.1, 0.1, 0.1)
	arrowPart.Transparency = 1
	arrowPart.CanCollide   = false
	arrowPart.Anchored     = true
	arrowPart.CastShadow   = false
	arrowPart.Position     = base.Position + Vector3.new(0, 7, 0)
	arrowPart.Parent       = workspace

	-- BillboardGui con flecha azul
	local billboard = Instance.new("BillboardGui")
	billboard.Name         = "ArrowIndicator"
	billboard.Size         = UDim2.new(0, 70, 0, 70)
	billboard.AlwaysOnTop  = true
	billboard.Parent       = arrowPart

	local label = Instance.new("TextLabel")
	label.Size                 = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text                 = "↓"
	label.TextColor3           = Color3.fromRGB(30, 144, 255)
	label.TextSize             = 58
	label.Font                 = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0.3
	label.TextStrokeColor3     = Color3.new(1, 1, 1)
	label.Parent               = billboard

	-- Animación de rebote (sube y baja)
	local baseY   = base.Position.Y + 7
	local elapsed = 0
	local RunService = game:GetService("RunService")
	arrowBounceConn = RunService.Heartbeat:Connect(function(dt)
		if not arrowPart or not arrowPart.Parent then
			arrowBounceConn:Disconnect()
			return
		end
		elapsed = elapsed + dt
		local bounce = math.sin(elapsed * 4) * 1.2
		arrowPart.Position = Vector3.new(
			base.Position.X,
			baseY + bounce,
			base.Position.Z
		)
	end)
end

-- ================================================================
-- HELPERS DE DIÁLOGO
-- ================================================================

-- Espera a que el kit cierre cualquier diálogo activo.
-- closeDialogue() en el kit llama onDialogueEnd() inmediatamente pero
-- pone currentDialogue = nil dentro de un task.delay (tween de cierre).
-- Sumamos 1 segundo extra para cubrir ese retraso.
local function esperarKitLibre()
	while DialogueVisibilityManager:isActive() do
		task.wait(0.2)
	end
	task.wait(1.0)
end

local function mostrarFeedback(data, initialLayer)
	task.spawn(function()
		esperarKitLibre()
		local layers = DialogueGenerator.GenerarEstructura(data, SKIN_NAME)
		dialogueKitModule.CreateDialogue({
			InitialLayer = initialLayer,
			SkinName     = SKIN_NAME,
			Config       = script,
			Layers       = layers,
		})
	end)
end

-- ================================================================
-- LISTENER DE SELECCIÓN DE NODOS
-- ================================================================

task.spawn(function()
	local Remotes     = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes")
	local notifyEvent = Remotes:WaitForChild("NotificarSeleccionNodo", 30)

	if not notifyEvent then
		warn("❌ Zona1_NodeFeedback: NotificarSeleccionNodo no encontrado (timeout)")
		return
	end

	notifyEvent.OnClientEvent:Connect(function(tipo, nombreNodo)
		-- Solo actuar en Zona 1
		local localPlayer = game:GetService("Players").LocalPlayer
		if localPlayer:GetAttribute("CurrentZone") ~= ZONA_OBJETIVO then return end

		-- ── Primer nodo seleccionado ──────────────────────────────────────
		if tipo == "NodoSeleccionado" and not feedbackNodoMostrado then
			feedbackNodoMostrado = true

			-- Mostrar flecha azul sobre el nodo ADYACENTE (el que falta seleccionar)
			local targetNodoName = (nombreNodo == NODO_A) and NODO_B or NODO_A
			local targetModel = findPosteModel(targetNodoName)
			if targetModel then
				crearFlechaAzul(targetModel)
			end

			local aliasNodo = (
				LevelsConfig[0].Nodos[nombreNodo]
				and LevelsConfig[0].Nodos[nombreNodo].Alias
			) or nombreNodo

			mostrarFeedback({
				["FeedbackNodo"] = {
					Actor    = "Carlos",
					Expresion = "Feliz",
					Texto    = {
						"Correcto, has seleccionado el nodo " .. aliasNodo .. ".",
						"El nodo adyacente se ha marcado con una flecha azul.",
						"Ahora selecciona ese nodo para crear una arista.",
					},
					Sonido   = {
						"rbxassetid://98229492565124",
						"rbxassetid://84437951272776",
						"rbxassetid://124195032304220",
					},
					Siguiente = "FIN",
				},
			}, "FeedbackNodo")

		-- ── Conexión completada ────────────────────────────────────────────
		elseif tipo == "ConexionCompletada" and not feedbackConexionMostrado then
			feedbackConexionMostrado = true
			removerFlechaAzul()

			mostrarFeedback({
				["FeedbackConexion"] = {
					Actor    = "Carlos",
					Expresion = "Feliz",
					Texto    = "Correcto, ahora sabes cómo conectar nodos.",
					Sonido   = "rbxassetid://98229492565124",
					Siguiente = "FIN",
				},
			}, "FeedbackConexion")
		end
	end)

	print("✅ Zona1_NodeFeedback: escuchando NotificarSeleccionNodo")
end)
