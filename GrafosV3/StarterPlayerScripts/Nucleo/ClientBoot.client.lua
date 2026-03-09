-- StarterPlayerScripts/Nucleo/ClientBoot.client.lua
-- Punto de entrada del cliente para GrafosV3.
--
-- REGLA DE ORO: Mientras el menú está activo, TODO lo relacionado al gameplay
-- está completamente desconectado. Solo el menú maneja sus eventos.
--
-- Estados: INICIO → MENU → GAMEPLAY → MENU

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")

local jugador   = Players.LocalPlayer
local playerGui = jugador:WaitForChild("PlayerGui")

print("[GrafosV3] === ClientBoot Iniciando ===")

-- ═══════════════════════════════════════════════════════════════════════════════
-- MÁQUINA DE ESTADOS (Regla de Oro)
-- ═══════════════════════════════════════════════════════════════════════════════

local MODO = { INICIO = "INICIO", MENU = "MENU", GAMEPLAY = "GAMEPLAY" }
local _modoActual = MODO.INICIO

local function setModo(nuevoModo)
	if _modoActual == nuevoModo then return end
	print("[ClientBoot] Modo:", _modoActual, "→", nuevoModo)
	_modoActual = nuevoModo
end

local function estaEnMenu()
	return _modoActual == MODO.MENU
end

local function estaEnGameplay()
	return _modoActual == MODO.GAMEPLAY
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 1. CARGAR SISTEMAS COMPARTIDOS
-- ═══════════════════════════════════════════════════════════════════════════════

local StarterPlayerScripts = game:GetService("StarterPlayer").StarterPlayerScripts

local ControladorAudio = nil
task.spawn(function()
	local compartido = StarterPlayerScripts:WaitForChild("Compartido", 5)
	if not compartido then
		warn("[ClientBoot] Carpeta Compartido no encontrada")
		return
	end
	local moduloAudio = compartido:WaitForChild("ControladorAudio", 5)
	if moduloAudio then
		local ok, res = pcall(require, moduloAudio)
		if ok then
			ControladorAudio = res
			print("[ClientBoot] ControladorAudio cargado")
		else
			warn("[ClientBoot] Error en ControladorAudio:", res)
		end
	else
		warn("[ClientBoot] ControladorAudio no encontrado")
	end
end)

-- GuiaService: auto-init (se conecta internamente a NivelListo/NivelDescargado)
task.spawn(function()
	local sistemasFolder = StarterPlayerScripts:WaitForChild("SistemasGameplay", 10)
	if not sistemasFolder then
		warn("[ClientBoot] SistemasGameplay no encontrado (GuiaService no cargado)")
		return
	end
	local guiaModulo = sistemasFolder:WaitForChild("GuiaService", 10)
	if guiaModulo then
		local ok, err = pcall(require, guiaModulo)
		if not ok then warn("[ClientBoot] Error en GuiaService:", err) end
	else
		warn("[ClientBoot] GuiaService no encontrado")
	end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 2. ESPERAR ESTRUCTURA DE EVENTOS
-- ═══════════════════════════════════════════════════════════════════════════════

local eventos = RS:WaitForChild("EventosGrafosV3")
local remotos = eventos:WaitForChild("Remotos")

-- ═══════════════════════════════════════════════════════════════════════════════
-- 3. CONFIGURAR GUI INICIAL
-- ═══════════════════════════════════════════════════════════════════════════════

local menuGui = playerGui:WaitForChild("EDAQuestMenu")
local hudGui  = playerGui:WaitForChild("GUIExploradorV2")

-- Estado inicial: todo oculto hasta que el servidor confirme
menuGui.Enabled = false
hudGui.Enabled  = false

print("[ClientBoot] Esperando ServidorListo...")

-- ═══════════════════════════════════════════════════════════════════════════════
-- 4. HANDLERS DE EVENTOS (Regla de Oro aplicada)
-- ═══════════════════════════════════════════════════════════════════════════════

-- ServidorListo: el servidor terminó de inicializarse → activar menú
local servidorListo = remotos:WaitForChild("ServidorListo")
servidorListo.OnClientEvent:Connect(function()
	-- Prevenir doble-activación si ya estamos en MENU
	if estaEnMenu() then
		print("[ClientBoot] ServidorListo ignorado — ya en MENU")
		return
	end

	print("[ClientBoot] ServidorListo → activando Menu")
	setModo(MODO.MENU)

	menuGui.Enabled = true
	hudGui.Enabled  = false
end)

-- NivelListo: el nivel se cargó en el servidor → mostrar HUD de gameplay
local nivelListo = remotos:WaitForChild("NivelListo")
nivelListo.OnClientEvent:Connect(function(data)
	if data and data.error then
		warn("[ClientBoot] Error en NivelListo:", data.error)
		-- Asegurar que el menú quede visible si hubo error
		setModo(MODO.MENU)
		menuGui.Enabled = true
		hudGui.Enabled  = false
		return
	end

	-- Prevenir doble-activación
	if estaEnGameplay() then
		print("[ClientBoot] NivelListo ignorado — ya en GAMEPLAY")
		return
	end

	print("[ClientBoot] NivelListo → activando Gameplay (nivel:", tostring(data and data.nivelID), ")")
	setModo(MODO.GAMEPLAY)

	menuGui.Enabled = false
	hudGui.Enabled  = true
end)

-- NivelDescargado: el nivel fue descargado → volver al menú
local nivelDescargado = remotos:WaitForChild("NivelDescargado")
nivelDescargado.OnClientEvent:Connect(function()
	-- Prevenir doble-activación si ya estamos en MENU
	if estaEnMenu() then
		print("[ClientBoot] NivelDescargado ignorado — ya en MENU")
		return
	end

	print("[ClientBoot] NivelDescargado → volviendo al Menu")
	setModo(MODO.MENU)

	menuGui.Enabled = true
	hudGui.Enabled  = false
end)

print("[ClientBoot] === Inicialización Completa ===")
