-- HUDController.client.lua
-- Controla la interactividad del HUD de gameplay (GUIExploradorV2):
--   · Desactiva el HUD al inicio (el jugador empieza en el menú)
--   · LevelReady         → activa el HUD
--   · BtnSalir           → muestra el modal de confirmación
--   · BtnCancelarSalir   → cierra el modal
--   · BtnConfirmarSalir  → vuelve al menú SIN guardar progreso del nivel
--
-- Progreso descartado al salir: aciertos, fallos, tiempo, puntaje parcial.
-- Lo que SÍ se conserva: logros permanentes (cuando se implementen en DataService).
--
-- Ubicación Roblox: StarterGui/EDAQuestMenu/HUDController.client.lua  (LocalScript)

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RS           = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ── Eventos del servidor ─────────────────────────────────────────────────────
local eventsFolder  = RS:WaitForChild("Events", 10)
local remotesFolder = eventsFolder and eventsFolder:WaitForChild("Remotes", 5)

local returnToMenuEv = remotesFolder and remotesFolder:FindFirstChild("ReturnToMenu")
local levelReadyEv   = remotesFolder and remotesFolder:FindFirstChild("LevelReady")
local updateScoreEv  = remotesFolder and remotesFolder:FindFirstChild("UpdateScore")

-- ── Esperar ambas GUIs ───────────────────────────────────────────────────────
local menu = playerGui:WaitForChild("EDAQuestMenu",    30)
local hud  = playerGui:WaitForChild("GUIExploradorV2", 30)

if not hud then
	warn("[HUDController] ❌ GUIExploradorV2 no encontrado en PlayerGui.")
	return
end

-- ── Guard: evitar re-ejecución duplicada ────────────────────────────────────
-- Si GUIExploradorV2.ResetOnSpawn=false el atributo persiste → bloquea re-runs.
-- Si ResetOnSpawn=true (default) el ScreenGui se re-clona al respawn → corre fresco.
-- FIX PERMANENTE: mover este LocalScript dentro de EDAQuestMenu en Studio.
if hud:GetAttribute("HUDControllerActive") then
	print("[HUDController] Re-ejecución detectada — usando instancia anterior")
	return
end
hud:SetAttribute("HUDControllerActive", true)

-- El HUD debe estar oculto al inicio: el jugador comienza en el menú.
hud.Enabled = false

-- ── Referencias a elementos del HUD ─────────────────────────────────────────
local btnSalir     = hud:FindFirstChild("BtnSalir",          true)
local modalFondo   = hud:FindFirstChild("ModalSalirFondo",   true)
local btnCancelar  = hud:FindFirstChild("BtnCancelarSalir",  true)
local btnConfirmar = hud:FindFirstChild("BtnConfirmarSalir", true)

if not btnSalir then
	warn("[HUDController] ⚠ BtnSalir no encontrado en GUIExploradorV2.")
end

-- ── Fade de transición ───────────────────────────────────────────────────────
-- Limpiar instancias de ejecuciones previas (mismo motivo que MenuController).
local existingSalirFade = hud:FindFirstChild("SalirFade")
if existingSalirFade then existingSalirFade:Destroy() end

local fadeOverlay                  = Instance.new("Frame")
fadeOverlay.Name                   = "SalirFade"
fadeOverlay.Size                   = UDim2.new(1, 0, 1, 0)
fadeOverlay.BackgroundColor3       = Color3.new(0, 0, 0)
fadeOverlay.BackgroundTransparency = 1
fadeOverlay.BorderSizePixel        = 0
fadeOverlay.ZIndex                 = 99   -- por encima de todo el HUD
fadeOverlay.Visible                = false
fadeOverlay.Parent                 = hud

local function fadeToBlack(duration, onDone)
	fadeOverlay.Visible = true
	local tw = TweenService:Create(
		fadeOverlay,
		TweenInfo.new(duration or 0.35, Enum.EasingStyle.Linear),
		{ BackgroundTransparency = 0 }
	)
	if onDone then tw.Completed:Once(onDone) end
	tw:Play()
end

local function resetFade()
	fadeOverlay.BackgroundTransparency = 1
	fadeOverlay.Visible = false
end

-- ── Modal de confirmación ────────────────────────────────────────────────────
local function showModal()
	if modalFondo then modalFondo.Visible = true end
end

local function hideModal()
	if modalFondo then modalFondo.Visible = false end
end

-- ── Volver al menú (confirmado) ──────────────────────────────────────────────
-- Boot.server.lua recibe ReturnToMenu → LevelLoader:unload() → personaje destruido.
-- DataService:saveResult() NO se llama → el progreso parcial se descarta.
local isReturning = false

local function doReturnToMenu()
	if isReturning then return end
	isReturning = true

	hideModal()

	fadeToBlack(0.4, function()
		-- Notificar al servidor: descarga el nivel sin guardar progreso
		if returnToMenuEv then
			returnToMenuEv:FireServer()
		end

		-- Restaurar menú en el Selector de Niveles (no en FrameMenu)
		-- El jugador ya eligió un nivel → lógico volver al selector
		if menu then
			-- Ocultar el overlay de carga antes de mostrar el menú.
			-- MenuController también lo reseteará cuando reciba LevelUnloaded,
			-- pero hacerlo aquí evita el parpadeo negro si hay latencia de red.
			local loadingOverlay = menu:FindFirstChild("NivelCargadoFrame")
			if loadingOverlay then
				loadingOverlay.Visible = false
				loadingOverlay.BackgroundTransparency = 1
			end

			local function setVisible(name, visible)
				local f = menu:FindFirstChild(name)
				if f then f.Visible = visible end
			end
			setVisible("FrameMenu",     false)
			setVisible("FrameLevels",   true)
			setVisible("FrameSettings", false)
			setVisible("FrameCredits",  false)
			setVisible("FrameExit",     false)
			menu.Enabled = true
		end

		-- Apagar el HUD
		hud.Enabled = false
		isReturning = false
		resetFade()

		print("[HUDController] Vuelto al menú — progreso del nivel descartado")
	end)
end

-- ── Conectar botones ─────────────────────────────────────────────────────────
if btnSalir     then btnSalir.MouseButton1Click:Connect(showModal)          end
if btnCancelar  then btnCancelar.MouseButton1Click:Connect(hideModal)        end
if btnConfirmar then btnConfirmar.MouseButton1Click:Connect(doReturnToMenu)  end

-- ── Preparar HUD cuando el nivel está listo ──────────────────────────────────
-- ClientBoot es quien activa hud.Enabled = true.
-- Aquí solo reseteamos estado interno (fade y flag de retorno).
if levelReadyEv then
	levelReadyEv.OnClientEvent:Connect(function(data)
		if data and data.error then return end  -- nivel no encontrado, no hacer nada

		resetFade()
		isReturning = false
		print("[HUDController] HUD preparado — Nivel", data and data.nivelID)
	end)
end

-- ── Actualizar puntaje en el HUD (puntajeBase, sin penalizaciones) ───────────
-- ScoreTracker dispara UpdateScore cada vez que hay una conexión válida.
-- El HUD muestra SOLO puntajeBase (la sorpresa de bonus/penal es en la pantalla final).
if updateScoreEv then
	-- Buscar el TextLabel de puntaje dentro de GUIExploradorV2
	-- Ruta esperada según el plan: BarraSuperior/PanelPuntuacion/ContenedorPuntos/Valor
	local function getScoreLabel()
		local barra = hud:FindFirstChild("BarraSuperior")
		if not barra then return nil end
		local panel = barra:FindFirstChild("PanelPuntuacion")
		if not panel then return nil end
		local chip = panel:FindFirstChild("ContenedorPuntos")
		if not chip then return nil end
		return chip:FindFirstChild("Valor")
	end

	updateScoreEv.OnClientEvent:Connect(function(data)
		if not hud.Enabled then return end  -- ignorar si el HUD no está activo
		local label = getScoreLabel()
		if label then
			label.Text = tostring(data.puntajeBase or 0)
		end
	end)
end

print("[EDA v2] ✅ HUDController activo")
