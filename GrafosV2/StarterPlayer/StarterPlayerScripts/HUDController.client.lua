-- HUDController.client.lua
-- Ubicación: StarterPlayer > StarterPlayerScripts > HUDController
-- Tipo: LocalScript
--
-- BUGS CORREGIDOS EN ESTA VERSIÓN:
--
-- [BUG 1 - CÁMARA] Al reiniciar el mismo nivel (RestartLevel), la cámara
--   quedaba fija apuntando al menú porque nadie reseteaba CameraType = Custom.
--   FIX: Forzar Custom en el listener de LevelReady (doble seguridad con ClientBoot).
--
-- [BUG 2 - PANTALLA DE VICTORIA] Los valores no aparecían en FilaTiempo,
--   FilaAciertos, etc. porque setValor() buscaba un TextLabel llamado "Valor"
--   pero en GUIExploradorV2 ese label se llama "Val".
--   FIX: Buscar "Val" primero, con fallback a "Valor" para compatibilidad.
--
-- [BUG 3 - ACIERTOS EN VICTORIA] Se mostraba snap.conexiones (cables activos
--   al final) en lugar de snap.aciertos (total histórico de conexiones correctas
--   enviado por MissionService desde ScoreTracker.aciertosTotal).
--   FIX: Usar snap.aciertos con fallback a snap.conexiones.
--
-- NOTA ARQUITECTURA: Este script NO toca hud.Enabled ni CameraType.
--   Eso es responsabilidad exclusiva de ClientBoot.client.lua.
--   Si hay un HUDController antiguo en StarterGui, ELIMINARLO.

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RS           = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ── Eventos ───────────────────────────────────────────────────────────────────
local eventsFolder   = RS:WaitForChild("Events", 15)
local remotesFolder  = eventsFolder and eventsFolder:WaitForChild("Remotes", 5)

local returnToMenuEv   = remotesFolder and remotesFolder:FindFirstChild("ReturnToMenu")
local levelReadyEv     = remotesFolder and remotesFolder:FindFirstChild("LevelReady")
local updateScoreEv    = remotesFolder and remotesFolder:FindFirstChild("UpdateScore")
local updateMissionsEv = remotesFolder and remotesFolder:WaitForChild("UpdateMissions", 5)
local levelCompletedEv = remotesFolder and remotesFolder:WaitForChild("LevelCompleted",  5)
local restartLevelEv   = remotesFolder and remotesFolder:FindFirstChild("RestartLevel")

-- ── GUI principal ─────────────────────────────────────────────────────────────
local hud = playerGui:WaitForChild("GUIExploradorV2", 30)
if not hud then warn("[HUDController] ❌ GUIExploradorV2 no encontrado"); return end

-- Evitar doble ejecución si Roblox recrea el LocalScript
if hud:GetAttribute("HUDControllerActive") then
	print("[HUDController] Ya activo — saliendo"); return
end
hud:SetAttribute("HUDControllerActive", true)

-- ── Estado ────────────────────────────────────────────────────────────────────
local _nivelID = nil

-- ── Referencias UI ────────────────────────────────────────────────────────────
local btnSalir     = hud:FindFirstChild("BtnSalir",          true)
local btnMisiones  = hud:FindFirstChild("BtnMisiones",       true)
local modalFondo   = hud:FindFirstChild("ModalSalirFondo",   true)
local btnCancelar  = hud:FindFirstChild("BtnCancelarSalir",  true)
local btnConfirmar = hud:FindFirstChild("BtnConfirmarSalir", true)
local misionFrame  = hud:FindFirstChild("MisionFrame",       true)
local misionCuerpo = misionFrame and misionFrame:FindFirstChild("Cuerpo", true)

-- ── Pantalla de victoria ──────────────────────────────────────────────────────
-- Jerarquía en GUIExploradorV2:
--   VictoriaFondo
--   └── PantallaVictoria
--       └── ContenedorPrincipal
--           ├── EstadisticasFrame
--           │   ├── FilaTiempo   → Val (TextLabel)
--           │   ├── FilaAciertos → Val (TextLabel)
--           │   ├── FilaErrores  → Val (TextLabel)
--           │   └── FilaPuntaje  → Val (TextLabel)
--           └── BotonesFrame
--               ├── BotonRepetir
--               └── BotonContinuar

local victoriaFondo = hud:FindFirstChild("VictoriaFondo", true)

-- Navegar jerarquía exacta
local _pantalla     = victoriaFondo and victoriaFondo:FindFirstChild("PantallaVictoria")
local _contenedor   = _pantalla     and _pantalla:FindFirstChild("ContenedorPrincipal")
local victoriaStats = _contenedor   and _contenedor:FindFirstChild("EstadisticasFrame")
local _botonesFrame = _contenedor   and _contenedor:FindFirstChild("BotonesFrame")
local botonRepetir   = _botonesFrame and _botonesFrame:FindFirstChild("BotonRepetir")
local botonContinuar = _botonesFrame and _botonesFrame:FindFirstChild("BotonContinuar")

-- Fallbacks si la jerarquía es diferente en Studio
if not victoriaStats  then victoriaStats  = hud:FindFirstChild("EstadisticasFrame", true) end
if not botonRepetir   then botonRepetir   = hud:FindFirstChild("BotonRepetir",      true) end
if not botonContinuar then botonContinuar = hud:FindFirstChild("BotonContinuar",    true) end

-- Diagnóstico al arrancar (útil para depurar en Output de Studio)
print("[HUDController] victoriaFondo:", victoriaFondo and "✅" or "❌ NO ENCONTRADO")
print("[HUDController] victoriaStats:", victoriaStats and "✅" or "❌ NO ENCONTRADO")
print("[HUDController] botonRepetir:",  botonRepetir  and "✅" or "❌ NO ENCONTRADO")
print("[HUDController] botonContinuar:",botonContinuar and "✅" or "❌ NO ENCONTRADO")

-- ── Fade overlay ──────────────────────────────────────────────────────────────
do local old = hud:FindFirstChild("SalirFade"); if old then old:Destroy() end end

local fadeOverlay = Instance.new("Frame")
fadeOverlay.Name                   = "SalirFade"
fadeOverlay.Size                   = UDim2.new(1, 0, 1, 0)
fadeOverlay.BackgroundColor3       = Color3.new(0, 0, 0)
fadeOverlay.BackgroundTransparency = 1
fadeOverlay.BorderSizePixel        = 0
fadeOverlay.ZIndex                 = 99
fadeOverlay.Visible                = false
fadeOverlay.Parent                 = hud

local function fadeToBlack(dur, cb)
	fadeOverlay.Visible = true
	local tw = TweenService:Create(
		fadeOverlay,
		TweenInfo.new(dur or 0.35, Enum.EasingStyle.Linear),
		{ BackgroundTransparency = 0 }
	)
	if cb then tw.Completed:Once(cb) end
	tw:Play()
end

local function resetFade()
	fadeOverlay.BackgroundTransparency = 1
	fadeOverlay.Visible = false
end

-- ── Modal ─────────────────────────────────────────────────────────────────────
local function showModal() if modalFondo then modalFondo.Visible = true  end end
local function hideModal() if modalFondo then modalFondo.Visible = false end end

-- ── Navegación ────────────────────────────────────────────────────────────────
local isReturning = false

local function doReturnToMenu()
	if isReturning then return end
	isReturning = true
	hideModal()
	fadeToBlack(0.4, function()
		-- ReturnToMenu → Boot hace cleanup y dispara LevelUnloaded
		-- ClientBoot recibe LevelUnloaded → activa menú + cámara
		if returnToMenuEv then returnToMenuEv:FireServer() end
		if victoriaFondo  then victoriaFondo.Visible = false end
		resetFade()
		isReturning = false
	end)
end

local function doRestartLevel()
	if isReturning or not _nivelID then return end
	isReturning = true
	if victoriaFondo then victoriaFondo.Visible = false end
	fadeToBlack(0.3, function()
		-- Boot recarga nivel → dispara LevelReady → ClientBoot fija cámara Custom
		if restartLevelEv then restartLevelEv:FireServer(_nivelID) end
		resetFade()
		isReturning = false
		print("[HUDController] RestartLevel enviado →", _nivelID)
	end)
end

-- ════════════════════════════════════════════════════════════════════════════
-- PANEL DE MISIONES
-- ════════════════════════════════════════════════════════════════════════════

local misionPanelOpen = false
local COLOR_COMPLETA  = Color3.fromRGB(80,  200, 120)
local COLOR_PENDIENTE = Color3.fromRGB(200, 200, 200)
local COLOR_ZONA_BG   = Color3.fromRGB(30,  30,  50)
local COLOR_ZONA_ACT  = Color3.fromRGB(30,  50,  90)
local ROW_H = 22

local function makeLabel(parent, text, color, size, bold, richText)
	local lbl = Instance.new("TextLabel")
	lbl.Size               = size or UDim2.new(1, 0, 0, ROW_H)
	lbl.BackgroundTransparency = 1
	lbl.Text           = text
	lbl.TextColor3     = color or Color3.new(1,1,1)
	lbl.TextScaled     = false
	lbl.TextSize       = 14
	lbl.Font           = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.RichText       = richText or false
	lbl.Parent         = parent
	return lbl
end

local function rebuildMisionPanel(data)
	if not misionCuerpo then return end
	for _, c in ipairs(misionCuerpo:GetChildren()) do
		if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
	end
	if not data then return end

	local misiones    = data.misiones    or {}
	local completadas = data.completadas or {}
	local zonaActual  = data.zonaActual

	local compSet = {}
	for _, id in ipairs(completadas) do compSet[id] = true end

	local zonas, zonaList = {}, {}
	for _, m in ipairs(misiones) do
		local z = m.Zona or "SIN_ZONA"
		if not zonas[z] then zonas[z] = {}; table.insert(zonaList, z) end
		table.insert(zonas[z], m)
	end

	for _, zona in ipairs(zonaList) do
		local lista = zonas[zona]
		local total, done = #lista, 0
		for _, m in ipairs(lista) do if compSet[m.ID] then done = done + 1 end end
		local allDone  = (done >= total)
		local esActiva = (zonaActual == zona)

		local header = Instance.new("Frame")
		header.Size             = UDim2.new(1, 0, 0, ROW_H + 4)
		header.BackgroundColor3 = esActiva and COLOR_ZONA_ACT or COLOR_ZONA_BG
		header.BorderSizePixel  = 0
		header.Parent           = misionCuerpo
		do
			local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 4); c.Parent = header
			local p = Instance.new("UIPadding")
			p.PaddingLeft  = UDim.new(0, 8)
			p.PaddingRight = UDim.new(0, 8)
			p.Parent = header
		end
		makeLabel(header,
			string.format("%s  ·  %s", zona:gsub("_", " "), allDone and "✅" or (done.."/"..total)),
			allDone and COLOR_COMPLETA or Color3.fromRGB(220, 220, 255),
			UDim2.new(1, -16, 1, 0), true, false)

		if esActiva then
			for _, m in ipairs(lista) do
				local isDone = compSet[m.ID] == true
				local puntos = m.Puntos and m.Puntos > 0 and (" (+%d pts)"):format(m.Puntos) or ""
				local icono  = isDone and "✅ " or "○ "
				local row    = Instance.new("Frame")
				row.Size               = UDim2.new(1, 0, 0, ROW_H + 16)
				row.BackgroundTransparency = 1
				row.Parent             = misionCuerpo
				if isDone then
					makeLabel(row, string.format("<s>%s%s%s</s>", icono, m.Texto or "?", puntos),
						COLOR_COMPLETA, UDim2.new(1, -22, 1, 0), false, true)
				else
					makeLabel(row, icono .. (m.Texto or "?") .. puntos,
						COLOR_PENDIENTE, UDim2.new(1, -22, 1, 0), false, false)
				end
			end
		end
	end

	local layout = misionCuerpo:FindFirstChildOfClass("UIListLayout")
	if layout then
		misionCuerpo.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
	end
end

local function toggleMisiones()
	if not misionFrame then return end
	misionPanelOpen = not misionPanelOpen
	misionFrame.Visible = misionPanelOpen
end

-- ════════════════════════════════════════════════════════════════════════════
-- SCORE EN HUD DURANTE GAMEPLAY
-- ════════════════════════════════════════════════════════════════════════════

local function getScoreLabel()
	local barra = hud:FindFirstChild("BarraSuperior")
	local panel = barra and barra:FindFirstChild("PanelPuntuacion")
	local chip  = panel and panel:FindFirstChild("ContenedorPuntos")
	if chip then
		return chip:FindFirstChild("Val") or chip:FindFirstChild("Valor")
	end
	-- Fallback recursivo
	local chip2 = hud:FindFirstChild("ContenedorPuntos", true)
	if chip2 then
		return chip2:FindFirstChild("Val") or chip2:FindFirstChild("Valor")
	end
	return nil
end

-- ════════════════════════════════════════════════════════════════════════════
-- PANTALLA DE VICTORIA
-- ════════════════════════════════════════════════════════════════════════════

local function showVictory(snap)
	if not victoriaFondo then
		warn("[HUDController] ❌ VictoriaFondo no encontrado — no se puede mostrar victoria")
		return
	end

	if victoriaStats and snap then
		-- BUG 2 FIX: buscar "Val" primero (nombre confirmado por el usuario),
		-- con fallback a "Valor" por compatibilidad con versiones anteriores.
		local function setValor(filaName, texto)
			local fila = victoriaStats:FindFirstChild(filaName)
			if not fila then
				warn("[HUDController] ⚠ Fila no encontrada:", filaName, "en EstadisticasFrame")
				return
			end
			local lbl = fila:FindFirstChild("Val") or fila:FindFirstChild("Valor")
			if not lbl then
				warn("[HUDController] ⚠ No se encontró 'Val' ni 'Valor' en fila:", filaName)
				-- Debug: listar hijos de la fila para identificar el nombre real
				for _, hijo in ipairs(fila:GetChildren()) do
					print("  Hijo en", filaName, "→", hijo.Name, "/", hijo.ClassName)
				end
				return
			end
			lbl.Text = tostring(texto)
		end

		local t = snap.tiempo or 0

		setValor("FilaTiempo",   string.format("%d:%02d", math.floor(t / 60), t % 60))

		-- BUG 3 FIX: usar snap.aciertos (aciertosTotal enviado por MissionService),
		-- no snap.conexiones (que solo cuenta cables activos al terminar).
		setValor("FilaAciertos", tostring(snap.aciertos   or snap.conexiones or 0))
		setValor("FilaErrores",  tostring(snap.fallos      or 0))
		setValor("FilaPuntaje",  tostring(snap.puntajeBase or 0))
	else
		if not victoriaStats then
			warn("[HUDController] ❌ victoriaStats (EstadisticasFrame) no encontrado")
		end
		if not snap then
			warn("[HUDController] ❌ snap es nil — LevelCompleted no mandó datos")
		end
	end

	victoriaFondo.Visible = true
	print(string.format("[HUDController] 🏆 Victoria | aciertos=%s fallos=%s puntaje=%s tiempo=%s",
		tostring(snap and (snap.aciertos or snap.conexiones) or "?"),
		tostring(snap and snap.fallos or "?"),
		tostring(snap and snap.puntajeBase or "?"),
		tostring(snap and snap.tiempo or "?")))
end

-- ════════════════════════════════════════════════════════════════════════════
-- CONECTAR EVENTOS
-- ════════════════════════════════════════════════════════════════════════════

if btnSalir     then btnSalir.MouseButton1Click:Connect(showModal)         end
if btnCancelar  then btnCancelar.MouseButton1Click:Connect(hideModal)       end
if btnConfirmar then btnConfirmar.MouseButton1Click:Connect(doReturnToMenu) end
if btnMisiones  then btnMisiones.MouseButton1Click:Connect(toggleMisiones)  end

local btnCerrar = misionFrame and misionFrame:FindFirstChild("BtnCerrarMisiones", true)
if btnCerrar then
	btnCerrar.MouseButton1Click:Connect(function()
		misionPanelOpen = false
		if misionFrame then misionFrame.Visible = false end
	end)
end

if botonRepetir   then botonRepetir.MouseButton1Click:Connect(doRestartLevel)  end
if botonContinuar then botonContinuar.MouseButton1Click:Connect(doReturnToMenu) end

-- ── LevelReady ────────────────────────────────────────────────────────────────
if levelReadyEv then
	levelReadyEv.OnClientEvent:Connect(function(data)
		if data and data.error then return end
		workspace.CurrentCamera.CameraType = Enum.CameraType.Custom

		resetFade()
		isReturning     = false
		misionPanelOpen = false
		if misionFrame   then misionFrame.Visible   = false end
		if victoriaFondo then victoriaFondo.Visible = false end

		print("[HUDController] LevelReady | cámara → Custom")
	end)
end
-- ── UpdateMissions ────────────────────────────────────────────────────────────
if updateMissionsEv then
	updateMissionsEv.OnClientEvent:Connect(function(data)
		if not data then return end
		rebuildMisionPanel(data)
		if misionFrame then misionFrame.Visible = misionPanelOpen end
	end)
end

-- ── LevelCompleted ────────────────────────────────────────────────────────────
if levelCompletedEv then
	levelCompletedEv.OnClientEvent:Connect(function(snap)
		print("[HUDController] LevelCompleted recibido:", snap ~= nil and "con datos" or "SIN DATOS")
		showVictory(snap)
	end)
end

-- ── UpdateScore ───────────────────────────────────────────────────────────────
if updateScoreEv then
	updateScoreEv.OnClientEvent:Connect(function(data)
		local label = getScoreLabel()
		if label then
			label.Text = tostring(data.puntajeBase or 0)
		end
	end)
end

print("[EDA v2] ✅ HUDController activo")