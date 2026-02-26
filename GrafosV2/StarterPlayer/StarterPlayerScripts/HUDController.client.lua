-- HUDController.client.lua
-- Controla el HUD de gameplay (GUIExploradorV2):
--   · LevelReady         → activa el HUD, resetea estado
--   · BtnSalir           → modal de confirmación de salida
--   · BtnMisiones        → abre/cierra el panel de misiones
--   · UpdateMissions     → reconstruye el panel dinámicamente
--   · LevelCompleted     → muestra pantalla de victoria
--   · BotonRepetir       → RestartLevel (mismo nivel)
--   · BotonContinuar     → ReturnToMenu (selector de niveles)
--
-- Panel de misiones — comportamiento:
--   · Vista resumen: todas las zonas con contador (ej. "Zona 1 · 1/2 ✓")
--   · Vista detalle: al entrar a una zona, sus misiones se expanden con texto completo
--   · Misiones completadas aparecen tachadas (strikethrough via TextLabel.RichText)
--   · Todo se reconstruye en cada UpdateMissions recibido (dinámico)
--
-- Ubicación Roblox: StarterPlayer/StarterPlayerScripts/HUDController.client.lua

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RS           = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ── Eventos ───────────────────────────────────────────────────────────────────
local eventsFolder  = RS:WaitForChild("Events", 15)
local remotesFolder = eventsFolder and eventsFolder:WaitForChild("Remotes", 5)

local returnToMenuEv  = remotesFolder and remotesFolder:FindFirstChild("ReturnToMenu")
local levelReadyEv    = remotesFolder and remotesFolder:FindFirstChild("LevelReady")
local updateScoreEv   = remotesFolder and remotesFolder:FindFirstChild("UpdateScore")
local updateMissionsEv = remotesFolder and remotesFolder:WaitForChild("UpdateMissions", 5)
local levelCompletedEv = remotesFolder and remotesFolder:WaitForChild("LevelCompleted",  5)
local restartLevelEv  = remotesFolder and remotesFolder:FindFirstChild("RestartLevel")

-- ── Esperar ambas GUIs ────────────────────────────────────────────────────────
local menu = playerGui:WaitForChild("EDAQuestMenu",    30)
local hud  = playerGui:WaitForChild("GUIExploradorV2", 30)

if not hud then
	warn("[HUDController] ❌ GUIExploradorV2 no encontrado en PlayerGui.")
	return
end

if hud:GetAttribute("HUDControllerActive") then
	print("[HUDController] Re-ejecución detectada — saliendo")
	return
end
hud:SetAttribute("HUDControllerActive", true)
hud.Enabled = false

-- ── Nivel actual (recibido en LevelReady) ─────────────────────────────────────
local _nivelID = nil

-- ── Referencias a elementos del HUD ──────────────────────────────────────────
local btnSalir     = hud:FindFirstChild("BtnSalir",          true)
local btnMisiones  = hud:FindFirstChild("BtnMisiones",       true)
local modalFondo   = hud:FindFirstChild("ModalSalirFondo",   true)
local btnCancelar  = hud:FindFirstChild("BtnCancelarSalir",  true)
local btnConfirmar = hud:FindFirstChild("BtnConfirmarSalir", true)
local misionFrame  = hud:FindFirstChild("MisionFrame",       true)
local misionCuerpo = misionFrame and misionFrame:FindFirstChild("Cuerpo", true)
local victoriaFondo    = hud:FindFirstChild("VictoriaFondo",     true)
local botonRepetir     = victoriaFondo and victoriaFondo:FindFirstChild("BotonRepetir",   true)
local botonContinuar   = victoriaFondo and victoriaFondo:FindFirstChild("BotonContinuar", true)
local victoriaStats    = victoriaFondo and victoriaFondo:FindFirstChild("EstadisticasFrame", true)

-- ── Fade overlay ──────────────────────────────────────────────────────────────
local existingSalirFade = hud:FindFirstChild("SalirFade")
if existingSalirFade then existingSalirFade:Destroy() end

local fadeOverlay                  = Instance.new("Frame")
fadeOverlay.Name                   = "SalirFade"
fadeOverlay.Size                   = UDim2.new(1, 0, 1, 0)
fadeOverlay.BackgroundColor3       = Color3.new(0, 0, 0)
fadeOverlay.BackgroundTransparency = 1
fadeOverlay.BorderSizePixel        = 0
fadeOverlay.ZIndex                 = 99
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

-- ── Modal salir ───────────────────────────────────────────────────────────────
local function showModal()   if modalFondo then modalFondo.Visible = true  end end
local function hideModal()   if modalFondo then modalFondo.Visible = false end end

-- ── Volver al menú ────────────────────────────────────────────────────────────
local isReturning = false

local function doReturnToMenu()
	if isReturning then return end
	isReturning = true
	hideModal()

	fadeToBlack(0.4, function()
		if returnToMenuEv then returnToMenuEv:FireServer() end

		if menu then
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

		if victoriaFondo then victoriaFondo.Visible = false end
		hud.Enabled = false
		isReturning = false
		resetFade()
		print("[HUDController] Vuelto al menú")
	end)
end

-- ── Reiniciar nivel ───────────────────────────────────────────────────────────
local function doRestartLevel()
	if isReturning or not _nivelID then return end
	isReturning = true
	if victoriaFondo then victoriaFondo.Visible = false end

	fadeToBlack(0.3, function()
		if restartLevelEv then restartLevelEv:FireServer(_nivelID) end
		resetFade()
		isReturning = false
		print("[HUDController] RestartLevel —", _nivelID)
	end)
end

-- ════════════════════════════════════════════════════════════════════════════
-- PANEL DE MISIONES
-- ════════════════════════════════════════════════════════════════════════════

local misionPanelOpen = false

local function toggleMisiones()
	if not misionFrame then return end
	misionPanelOpen = not misionPanelOpen
	misionFrame.Visible = misionPanelOpen
end

-- Colores para estados
local COLOR_COMPLETA  = Color3.fromRGB(80, 200, 120)
local COLOR_PENDIENTE = Color3.fromRGB(200, 200, 200)
local COLOR_ZONA_BG   = Color3.fromRGB(30, 30, 50)
local COLOR_ZONA_ACT  = Color3.fromRGB(30, 50, 90)

-- Crea un TextLabel simple en un parent
local function makeLabel(parent, text, color, size, bold, richText)
	local lbl                   = Instance.new("TextLabel")
	lbl.Size                    = size or UDim2.new(1, 0, 0, 24)
	lbl.BackgroundTransparency  = 1
	lbl.Text                    = text
	lbl.TextColor3              = color or Color3.new(1, 1, 1)
	lbl.TextScaled              = false
	lbl.TextSize                = 14
	lbl.Font                    = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	lbl.TextXAlignment          = Enum.TextXAlignment.Left
	lbl.RichText                = richText or false
	lbl.Parent                  = parent
	return lbl
end

-- ════════════════════════════════════════════════════════════════════════════
-- PANEL DE MISIONES — rebuildMisionPanel (reemplaza la función actual)
-- ════════════════════════════════════════════════════════════════════════════
--
-- Comportamiento:
--   · Sin zona activa  → vista RESUMEN: una fila por zona con contador (0/n) o ✅
--   · Con zona activa  → vista DETALLE: SOLO las misiones de esa zona, con
--                        descripción completa y tachado si están completadas.
--                        Las demás zonas NO aparecen.
--
-- Este bloque reemplaza la función rebuildMisionPanel en HUDController.client.lua

local COLOR_COMPLETA  = Color3.fromRGB(80, 200, 120)
local COLOR_PENDIENTE = Color3.fromRGB(200, 200, 200)
local COLOR_ZONA_BG   = Color3.fromRGB(30, 30, 50)
local COLOR_ZONA_ACT  = Color3.fromRGB(30, 50, 90)

local function makeLabel(parent, text, color, size, bold, richText)
	local lbl                   = Instance.new("TextLabel")
	lbl.Size                    = size or UDim2.new(1, 0, 0, 24)
	lbl.BackgroundTransparency  = 1
	lbl.Text                    = text
	lbl.TextColor3              = color or Color3.new(1, 1, 1)
	lbl.TextScaled              = false
	lbl.TextSize                = 14
	lbl.Font                    = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	lbl.TextXAlignment          = Enum.TextXAlignment.Left
	lbl.RichText                = richText or false
	lbl.Parent                  = parent
	return lbl
end

local function rebuildMisionPanel(data)
	if not misionCuerpo then return end

	-- Limpiar contenido anterior
	for _, child in ipairs(misionCuerpo:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end

	local misiones    = data.misiones   or {}
	local completadas = {}
	for _, id in ipairs(data.completadas or {}) do completadas[id] = true end
	local zonaActual  = data.zonaActual   -- nil si el jugador no está en ninguna zona

	-- Agrupar misiones por zona (respetando orden de aparición)
	local zonas      = {}  -- { [zona] = { mision, ... } }
	local zonasOrder = {}

	for _, m in ipairs(misiones) do
		local zona = m.Zona or "BONUS"
		if not zonas[zona] then
			zonas[zona] = {}
			table.insert(zonasOrder, zona)
		end
		table.insert(zonas[zona], m)
	end

	local ROW_H = 26

	-- ══════════════════════════════════════════════════════════════════════
	-- VISTA DETALLE: jugador dentro de una zona
	-- Muestra SOLO las misiones de esa zona con descripción completa.
	-- ══════════════════════════════════════════════════════════════════════
	if zonaActual and zonas[zonaActual] then
		local listaZona = zonas[zonaActual]

		-- Cabecera de la zona actual
		local header          = Instance.new("Frame")
		header.Size           = UDim2.new(1, 0, 0, ROW_H + 4)
		header.BackgroundColor3 = COLOR_ZONA_ACT
		header.BorderSizePixel  = 0
		header.Parent           = misionCuerpo
		local hPad = Instance.new("UIPadding")
		hPad.PaddingLeft = UDim.new(0, 8)
		hPad.PaddingRight = UDim.new(0, 8)
		hPad.Parent = header
		local hCorner = Instance.new("UICorner")
		hCorner.CornerRadius = UDim.new(0, 4)
		hCorner.Parent = header

		local nombreZona = zonaActual == "BONUS" and "⭐ BONUS" or zonaActual:gsub("_", " ")
		makeLabel(header, "📍 " .. nombreZona,
			Color3.fromRGB(255, 220, 100),
			UDim2.new(1, -16, 1, 0), true, false)

		-- Misiones de la zona con descripción completa
		for _, m in ipairs(listaZona) do
			local done = completadas[m.ID] == true

			local row          = Instance.new("Frame")
			row.Size           = UDim2.new(1, 0, 0, ROW_H + 8)
			row.BackgroundColor3 = done
				and Color3.fromRGB(20, 50, 30)
				or  Color3.fromRGB(25, 25, 45)
			row.BorderSizePixel  = 0
			row.Parent           = misionCuerpo

			local rPad = Instance.new("UIPadding")
			rPad.PaddingLeft  = UDim.new(0, 14)
			rPad.PaddingRight = UDim.new(0, 8)
			rPad.Parent = row

			local rCorner = Instance.new("UICorner")
			rCorner.CornerRadius = UDim.new(0, 4)
			rCorner.Parent = row

			local puntos = m.Puntos and m.Puntos > 0 and (" (+%d pts)"):format(m.Puntos) or ""
			local icono  = done and "✅ " or "○ "

			if done then
				-- Tachado con RichText
				makeLabel(row,
					string.format('<s>%s%s%s</s>', icono, m.Texto, puntos),
					COLOR_COMPLETA,
					UDim2.new(1, -22, 1, 0), false, true)
			else
				makeLabel(row,
					icono .. m.Texto .. puntos,
					COLOR_PENDIENTE,
					UDim2.new(1, -22, 1, 0), false, false)
			end
		end

		-- ══════════════════════════════════════════════════════════════════════
		-- VISTA RESUMEN: jugador fuera de toda zona
		-- Muestra una fila por zona con contador (0/n) o ✅
		-- ══════════════════════════════════════════════════════════════════════
	else
		for _, zona in ipairs(zonasOrder) do
			local listaZona = zonas[zona]
			local total     = #listaZona
			local complCount = 0
			for _, m in ipairs(listaZona) do
				if completadas[m.ID] then complCount = complCount + 1 end
			end
			local allZonaDone = (complCount >= total)

			local header          = Instance.new("Frame")
			header.Size           = UDim2.new(1, 0, 0, ROW_H + 4)
			header.BackgroundColor3 = COLOR_ZONA_BG
			header.BorderSizePixel  = 0
			header.Parent           = misionCuerpo

			local hPad = Instance.new("UIPadding")
			hPad.PaddingLeft  = UDim.new(0, 8)
			hPad.PaddingRight = UDim.new(0, 8)
			hPad.Parent = header

			local hCorner = Instance.new("UICorner")
			hCorner.CornerRadius = UDim.new(0, 4)
			hCorner.Parent = header

			local nombreZona  = zona == "BONUS" and "⭐ BONUS" or zona:gsub("_", " ")
			local contadorStr = allZonaDone and "✅" or (complCount .. "/" .. total)
			makeLabel(header,
				string.format("%s  ·  %s", nombreZona, contadorStr),
				allZonaDone and COLOR_COMPLETA or Color3.fromRGB(220, 220, 255),
				UDim2.new(1, -16, 1, 0), true, false)
		end
	end

	-- Actualizar canvas
	local layout = misionCuerpo:FindFirstChildOfClass("UIListLayout")
	if layout then
		misionCuerpo.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
	end
end
-- ════════════════════════════════════════════════════════════════════════════
-- PANTALLA DE VICTORIA — showVictory (reemplaza la función actual)
-- ════════════════════════════════════════════════════════════════════════════
--
-- Jerarquía esperada (según GUIExploradorV2):
--
--   VictoriaFondo (Frame)
--   └── PantallaVictoria (CanvasGroup)
--       └── ContenedorPrincipal (Frame)
--           ├── VictoriaHead (Frame)
--           │   └── EstrellasMostrar (Frame)
--           │       └── Estrella1, Estrella2, Estrella3 (ImageLabel)
--           ├── EstadisticasFrame (Frame)
--           │   ├── FilaTiempo   (Frame) → Valor (TextLabel)
--           │   ├── FilaAciertos (Frame) → Valor (TextLabel)
--           │   ├── FilaErrores  (Frame) → Valor (TextLabel)
--           │   └── FilaPuntaje  (Frame) → Valor (TextLabel)
--           └── BotonesFrame (Frame)
--               ├── BotonRepetir   (TextButton)
--               └── BotonContinuar (TextButton)
--
-- REEMPLAZA en HUDController.client.lua:
--   1. Las referencias de botonRepetir y botonContinuar en la sección de referencias
--   2. La función showVictory completa
--   3. Las conexiones de botones de victoria al final del script
-- ════════════════════════════════════════════════════════════════════════════

-- ── Referencias a la pantalla de victoria ────────────────────────────────────
-- Reemplaza estas líneas en la sección "Referencias a elementos del HUD":
--
--   local victoriaFondo    = hud:FindFirstChild("VictoriaFondo",     true)
--   local botonRepetir     = victoriaFondo and victoriaFondo:FindFirstChild("BotonRepetir",   true)
--   local botonContinuar   = victoriaFondo and victoriaFondo:FindFirstChild("BotonContinuar", true)
--   local victoriaStats    = victoriaFondo and victoriaFondo:FindFirstChild("EstadisticasFrame", true)
--
-- Por estas:

local victoriaFondo = hud:FindFirstChild("VictoriaFondo", true)

-- Navegar la jerarquía exacta para no confundir elementos
local _pantalla     = victoriaFondo
	and victoriaFondo:FindFirstChild("PantallaVictoria")
local _contenedor   = _pantalla
	and _pantalla:FindFirstChild("ContenedorPrincipal")
local victoriaStats = _contenedor
	and _contenedor:FindFirstChild("EstadisticasFrame")
local _botonesFrame = _contenedor
	and _contenedor:FindFirstChild("BotonesFrame")
local botonRepetir   = _botonesFrame and _botonesFrame:FindFirstChild("BotonRepetir")
local botonContinuar = _botonesFrame and _botonesFrame:FindFirstChild("BotonContinuar")
local _victoriaHead  = _contenedor and _contenedor:FindFirstChild("VictoriaHead")
local _estrellasMostrar = _victoriaHead and _victoriaHead:FindFirstChild("EstrellasMostrar")

-- ── showVictory ───────────────────────────────────────────────────────────────
local function showVictory(snap)
	if not victoriaFondo then
		warn("[HUDController] VictoriaFondo no encontrado en GUIExploradorV2")
		return
	end

	if victoriaStats and snap then

		-- Helper: encuentra el TextLabel "Valor" como hijo DIRECTO de la fila
		local function setValor(filaName, texto)
			local fila = victoriaStats:FindFirstChild(filaName)
			if not fila then
				warn("[HUDController] showVictory: fila no encontrada →", filaName)
				return
			end
			local lbl = fila:FindFirstChild("Valor") or fila:FindFirstChild("V")
			if not lbl then
				warn("[HUDController] showVictory: 'Valor' no encontrado en", filaName)
				return
			end
			lbl.Text = tostring(texto)
		end

		-- Tiempo formateado mm:ss
		local t   = snap.tiempo or 0
		local min = math.floor(t / 60)
		local seg = t % 60
		setValor("FilaTiempo",    string.format("%d:%02d", min, seg))
		setValor("FilaAciertos",  tostring(snap.conexiones  or 0))
		setValor("FilaErrores",   tostring(snap.fallos      or 0))
		setValor("FilaPuntaje",   tostring(snap.puntajeBase or 0))
	end

	-- Estrellas (opcional: mostrar según puntaje si tienes umbrales)
	-- Por ahora las muestra todas activas. Adaptar si LevelsConfig tiene TresEstrellas/DosEstrellas.
	if _estrellasMostrar then
		-- Aquí podrías apagar estrellas según snap.puntajeBase vs config.
		-- Por defecto dejamos las 3 visibles (ya deben estar así en Studio).
	end

	victoriaFondo.Visible = true
	print("[HUDController] 🏆 Pantalla de victoria mostrada — puntaje:", snap and snap.puntajeBase or "?")
end

-- ── Conexiones de botones de victoria ────────────────────────────────────────
-- Reemplaza las líneas al final de HUDController:
--
--   if botonRepetir   then botonRepetir.MouseButton1Click:Connect(doRestartLevel)  end
--   if botonContinuar then botonContinuar.MouseButton1Click:Connect(doReturnToMenu) end
--
-- Por estas (ya son idénticas en lógica, pero ahora botonRepetir/botonContinuar
-- apuntan a los nodos correctos dentro de BotonesFrame):

if botonRepetir   then botonRepetir.MouseButton1Click:Connect(doRestartLevel)   end
if botonContinuar then botonContinuar.MouseButton1Click:Connect(doReturnToMenu)  end

-- ════════════════════════════════════════════════════════════════════════════
-- SCORE EN HUD
-- ════════════════════════════════════════════════════════════════════════════

local function getScoreLabel()
	local barra = hud:FindFirstChild("BarraSuperior")
	if not barra then return nil end
	local panel = barra:FindFirstChild("PanelPuntuacion")
	if not panel then return nil end
	local chip  = panel:FindFirstChild("ContenedorPuntos")
	if not chip  then return nil end
	return chip:FindFirstChild("Valor")
end

-- ════════════════════════════════════════════════════════════════════════════
-- CONECTAR EVENTOS
-- ════════════════════════════════════════════════════════════════════════════

-- Botones salir
if btnSalir     then btnSalir.MouseButton1Click:Connect(showModal)         end
if btnCancelar  then btnCancelar.MouseButton1Click:Connect(hideModal)       end
if btnConfirmar then btnConfirmar.MouseButton1Click:Connect(doReturnToMenu) end

-- Botón misiones
if btnMisiones then
	btnMisiones.MouseButton1Click:Connect(toggleMisiones)
end

-- Panel misiones: cerrar desde botón interno
local btnCerrarMisiones = misionFrame and misionFrame:FindFirstChild("BtnCerrarMisiones", true)
if btnCerrarMisiones then
	btnCerrarMisiones.MouseButton1Click:Connect(function()
		misionPanelOpen = false
		if misionFrame then misionFrame.Visible = false end
	end)
end

-- LevelReady → resetear estado y guardar nivelID
if levelReadyEv then
	levelReadyEv.OnClientEvent:Connect(function(data)
		if data and data.error then return end
		_nivelID = data and data.nivelID
		resetFade()
		isReturning = false
		misionPanelOpen = false
		if misionFrame then misionFrame.Visible = false end
		if victoriaFondo then victoriaFondo.Visible = false end
		hud.Enabled = true
		print("[HUDController] HUD preparado — Nivel", _nivelID)
	end)
end

-- UpdateMissions → reconstruir panel dinámicamente
if updateMissionsEv then
	updateMissionsEv.OnClientEvent:Connect(function(data)
		if not data then return end
		rebuildMisionPanel(data)

		-- Si panel está abierto, mantenerlo abierto con el nuevo contenido
		if misionFrame then
			misionFrame.Visible = misionPanelOpen
		end
	end)
end

-- LevelCompleted → mostrar victoria
if levelCompletedEv then
	levelCompletedEv.OnClientEvent:Connect(function(snap)
		showVictory(snap)
	end)
end


-- UpdateScore → mostrar puntaje base en HUD
if updateScoreEv then
	updateScoreEv.OnClientEvent:Connect(function(data)
		if not hud.Enabled then return end
		local label = getScoreLabel()
		if label then
			label.Text = tostring(data.puntajeBase or 0)
		end
	end)
end

print("[EDA v2] ✅ HUDController activo")
