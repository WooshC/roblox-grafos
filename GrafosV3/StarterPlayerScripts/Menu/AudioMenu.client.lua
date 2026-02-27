-- StarterPlayerScripts/Menu/AudioMenu.client.lua
-- Controlador de audio especifico para el Menu.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayerScripts = game:GetService("StarterPlayer").StarterPlayerScripts

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("[AudioMenu] Script iniciado")

-- Esperar y obtener ControladorAudio
local ControladorAudio = nil
local exito, resultado = pcall(function()
	local modulo = StarterPlayerScripts:WaitForChild("Compartido", 5):WaitForChild("ControladorAudio", 5)
	return require(modulo)
end)

if exito then
	ControladorAudio = resultado
	print("[AudioMenu] ControladorAudio cargado")
else
	warn("[AudioMenu] Error cargando ControladorAudio:", resultado)
	return -- Terminar si no hay audio
end

-- Estado
local _activo = false
local _conexionesUI = {}      -- Conexiones de UI (botones, hover)
local _conexionesEventos = {} -- Conexiones a eventos del servidor/modales
local _bgmActual = "MusicaMenu"
local _menuGui = nil

-- ═══════════════════════════════════════════════════════════════════════════════
-- FUNCIONES AUXILIARES
-- ═══════════════════════════════════════════════════════════════════════════════

local function conectarSonidoHover(elemento)
	if not elemento then return end
	local conn = elemento.MouseEnter:Connect(function()
		if _activo and ControladorAudio then
			ControladorAudio.playUI("Hover")
		end
	end)
	table.insert(_conexionesUI, conn)
end

local function conectarSonidoClick(elemento, sonidoEspecial)
	if not elemento then return end
	local conn = elemento.MouseButton1Click:Connect(function()
		if _activo and ControladorAudio then
			if sonidoEspecial then
				ControladorAudio.playUI(sonidoEspecial)
			else
				ControladorAudio.playUI("Click")
			end
		end
	end)
	table.insert(_conexionesUI, conn)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONEXION DE SONIDOS A UI (se llama cada vez que se activa)
-- ═══════════════════════════════════════════════════════════════════════════════

local function conectarSonidosUI()
	-- Limpiar conexiones UI anteriores
	for _, conn in ipairs(_conexionesUI) do
		if conn then conn:Disconnect() end
	end
	_conexionesUI = {}
	
	if not _menuGui then
		_menuGui = playerGui:FindFirstChild("EDAQuestMenu")
		if not _menuGui then
			warn("[AudioMenu] No se encontro EDAQuestMenu")
			return
		end
	end
	
	print("[AudioMenu] Conectando sonidos a UI...")
	
	-- Frames
	local frameMenu = _menuGui:FindFirstChild("FrameMenu")
	local frameLevels = _menuGui:FindFirstChild("FrameLevels")
	local frameSettings = _menuGui:FindFirstChild("FrameSettings")
	local frameCredits = _menuGui:FindFirstChild("FrameCredits")
	local frameExit = _menuGui:FindFirstChild("FrameExit")
	
	if not frameMenu or not frameLevels then
		warn("[AudioMenu] Frames principales no encontrados")
		return
	end
	
	-- ============================================
	-- BOTONES MENU PRINCIPAL
	-- ============================================
	
	-- Boton JUGAR en menu principal
	local btnPlay = frameMenu:FindFirstChild("BtnPlay", true)
	if btnPlay then
		conectarSonidoHover(btnPlay)
		conectarSonidoClick(btnPlay, "Play")
		print("[AudioMenu] Conectado: BtnPlay")
	end
	
	-- Boton AJUSTES
	local btnSettings = frameMenu:FindFirstChild("BtnSettings", true)
	if btnSettings then
		conectarSonidoHover(btnSettings)
		conectarSonidoClick(btnSettings)
	end
	
	-- Boton CREDITOS - Cambia musica a creditos
	local btnCredits = frameMenu:FindFirstChild("BtnCredits", true)
	if btnCredits then
		conectarSonidoHover(btnCredits)
		local conn = btnCredits.MouseButton1Click:Connect(function()
			if _activo and ControladorAudio then
				ControladorAudio.playUI("Seleccion")
				
				-- Solo cambiar si no estamos ya en creditos
				if _bgmActual ~= "MusicaCreditos" then
					print("[AudioMenu] Cambiando a MusicaCreditos")
					_bgmActual = "MusicaCreditos"
					ControladorAudio.crossfadeBGM("MusicaCreditos", 2.0)
				end
			end
		end)
		table.insert(_conexionesUI, conn)
	end
	
	-- Boton SALIR
	local btnExit = frameMenu:FindFirstChild("BtnExit", true)
	if btnExit then
		conectarSonidoHover(btnExit)
		conectarSonidoClick(btnExit)
	end
	
	-- ============================================
	-- BOTONES SELECTOR DE NIVELES
	-- ============================================
	
	-- Boton VOLVER en selector de niveles
	local topBar = frameLevels:FindFirstChild("LevelTopBar")
	if topBar then
		local topCenter = topBar:FindFirstChild("TopCenter")
		if topCenter then
			local backBtn = topCenter:FindFirstChild("BackBtn")
			if backBtn then
				conectarSonidoHover(backBtn)
				conectarSonidoClick(backBtn, "Back")
			end
		end
	end
	
	-- Boton JUGAR en sidebar
	local levelMainArea = frameLevels:FindFirstChild("LevelMainArea")
	if levelMainArea then
		local sidebar = levelMainArea:FindFirstChild("LevelSidebar")
		if sidebar then
			local playArea = sidebar:FindFirstChild("PlayArea")
			if playArea then
				local playButton = playArea:FindFirstChild("PlayButton")
				if playButton then
					conectarSonidoHover(playButton)
					local conn = playButton.MouseButton1Click:Connect(function()
						if _activo and ControladorAudio then
							if not playButton.Text:find("BLOQUEADO") then
								ControladorAudio.playUI("Play")
							end
						end
					end)
					table.insert(_conexionesUI, conn)
				end
			end
		end
	end
	
	-- ============================================
	-- BOTONES CERRAR EN MODALES + MONITOREO
	-- ============================================
	
	for _, modal in ipairs({frameSettings, frameCredits, frameExit}) do
		if modal then
			-- Monitorear cierre del modal para volver a musica del menu
			local connVisible = modal:GetPropertyChangedSignal("Visible"):Connect(function()
				if not _activo or not ControladorAudio then return end
				
				-- Si el frame se acaba de ocultar (cerrado) y es creditos
				if not modal.Visible then
					local nombre = modal.Name
					print("[AudioMenu] Modal cerrado: " .. nombre)
					
					-- Si estabamos en creditos, volver a musica del menu
					if nombre == "FrameCredits" and _bgmActual == "MusicaCreditos" then
						print("[AudioMenu] Volviendo a MusicaMenu desde Creditos")
						_bgmActual = "MusicaMenu"
						ControladorAudio.crossfadeBGM("MusicaMenu", 2.0)
					end
				end
			end)
			table.insert(_conexionesUI, connVisible)
			
			-- Boton cerrar (X)
			local closeBtn = modal:FindFirstChild("CloseBtn", true)
			if closeBtn then
				conectarSonidoHover(closeBtn)
				conectarSonidoClick(closeBtn, "Back")
			end
			
			-- Boton cancelar
			local cancelBtn = modal:FindFirstChild("CancelBtn", true)
			if cancelBtn then
				conectarSonidoHover(cancelBtn)
				conectarSonidoClick(cancelBtn, "Back")
			end
			
			-- Boton OK/Guardar
			local okBtn = modal:FindFirstChild("OkBtn", true) or modal:FindFirstChild("SaveBtn", true)
			if okBtn then
				conectarSonidoHover(okBtn)
				conectarSonidoClick(okBtn)
			end
		end
	end
	
	print("[AudioMenu] Sonidos conectados exitosamente - Total: " .. #_conexionesUI)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- ACTIVACION / DESACTIVACION
-- ═══════════════════════════════════════════════════════════════════════════════

local function activar()
	if _activo then return end
	_activo = true
	
	print("[AudioMenu] Activando audio del menu")
	
	-- IMPORTANTE: Reconectar sonidos UI cada vez que se activa
	conectarSonidosUI()
	
	-- Resetear tracking de BGM
	_bgmActual = "MusicaMenu"
	
	if ControladorAudio then
		-- IMPORTANTE: Detener cualquier musica de victoria que este sonando
		-- Verificar que la funcion existe antes de llamarla
		if ControladorAudio.stopVictoria then
			ControladorAudio.stopVictoria(1.0)
		else
			-- Fallback: solo detener BGM
			if ControladorAudio.stopBGM then
				ControladorAudio.stopBGM(1.0)
			end
		end
		
		-- Pequena pausa antes de iniciar musica del menu
		task.delay(0.5, function()
			if _activo and ControladorAudio and ControladorAudio.playBGM then
				ControladorAudio.playBGM("MusicaMenu", 2.0)
			end
		end)
	end
end

local function desactivar()
	if not _activo then return end
	_activo = false
	
	print("[AudioMenu] Desactivando audio del menu")
	
	-- Desconectar conexiones UI
	for _, conn in ipairs(_conexionesUI) do
		if conn then conn:Disconnect() end
	end
	_conexionesUI = {}
	
	if ControladorAudio then
		-- Fade out mas largo para transiciones suaves
		ControladorAudio.stopBGM(2.0)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- EVENTOS DEL SERVIDOR
-- ═══════════════════════════════════════════════════════════════════════════════

local Eventos = ReplicatedStorage:WaitForChild("EventosGrafosV3", 10)
if Eventos then
	local Remotos = Eventos:WaitForChild("Remotos")
	
	-- Nivel listo - desactivar menu
	local nivelListo = Remotos:WaitForChild("NivelListo")
	local conn1 = nivelListo.OnClientEvent:Connect(function()
		desactivar()
	end)
	table.insert(_conexionesEventos, conn1)
	
	-- Nivel descargado - activar menu
	local nivelDescargado = Remotos:WaitForChild("NivelDescargado")
	local conn2 = nivelDescargado.OnClientEvent:Connect(function()
		activar()
	end)
	table.insert(_conexionesEventos, conn2)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- INICIALIZACION
-- ═══════════════════════════════════════════════════════════════════════════════

print("[AudioMenu] Inicializando...")

-- Esperar un momento para que el menu esté listo
task.delay(1, function()
	-- Conectar UI inicialmente
	conectarSonidosUI()
	-- Activar audio
	activar()
end)

print("[AudioMenu] Sistema de audio del menu inicializado")
