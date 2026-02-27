-- ClientBoot.lua
-- Ubicacion: StarterPlayer > StarterPlayerScripts > ClientBoot
-- Tipo: LocalScript
--
-- Refactorizado: Ahora usa OrquestadorGameplayCliente para gestionar estados.
-- UNICO responsable: Activar/desactivar EDAQuestMenu y GUIExploradorV2
--
-- Regla de Oro: Menu y Gameplay son mutuamente excluyentes.

local Players  = game:GetService("Players")
local RS       = game:GetService("ReplicatedStorage")
local UIS      = game:GetService("UserInputService")

local jugador    = Players.LocalPlayer
local playerGui = jugador:WaitForChild("PlayerGui")

-- Cargar Orquestador de Gameplay (con manejo de errores)
local OrquestadorGameplayCliente = nil
local exitoCarga, errorCarga = pcall(function()
	local gameplayFolder = script.Parent:FindFirstChild("Gameplay")
	if gameplayFolder then
		local modulo = gameplayFolder:WaitForChild("OrquestadorGameplayCliente", 5)
		if modulo then
			OrquestadorGameplayCliente = require(modulo)
		end
	end
end)

if not exitoCarga or not OrquestadorGameplayCliente then
	warn("[ClientBoot] ⚠️ No se pudo cargar OrquestadorGameplayCliente:", errorCarga)
	-- Crear version dummy para evitar crashes
	OrquestadorGameplayCliente = {
		inicializar = function() end,
		iniciarGameplay = function() end,
		detenerGameplay = function() end,
		establecerCamaraGameplay = function() end,
	}
end

-- Esperar GUI
local menu = playerGui:WaitForChild("EDAQuestMenu",    20)
local hud  = playerGui:WaitForChild("GUIExploradorV2", 20)

if not menu then 
	warn("[ClientBoot] ❌ EDAQuestMenu no encontrada")
	-- Crear GUI dummy para evitar crashes
	menu = Instance.new("ScreenGui")
	menu.Name = "EDAQuestMenu"
	menu.Enabled = true
end

if not hud then 
	warn("[ClientBoot] ❌ GUIExploradorV2 no encontrada")
	-- Crear GUI dummy
	hud = Instance.new("ScreenGui")
	hud.Name = "GUIExploradorV2"
	hud.Enabled = false
end

-- Estado inicial: Menu activo, HUD oculto
menu.Enabled = true
hud.Enabled  = false

-- ═══════════════════════════════════════════════════════════════════════════════
-- CAMARA
-- ═══════════════════════════════════════════════════════════════════════════════
local camara = workspace.CurrentCamera

local function establecerCamaraMenu()
	local objetoCamara = workspace:FindFirstChild("CamaraMenu", true)
	local parte   = objetoCamara and (
		(objetoCamara:IsA("BasePart") and objetoCamara) or
			(objetoCamara:IsA("Model")    and objetoCamara.PrimaryPart)
	)
	if parte then
		camara.CameraType = Enum.CameraType.Scriptable
		camara.CFrame     = parte.CFrame
		print("[ClientBoot] Camara → MENU (Scriptable)")
	else
		warn("[ClientBoot] ⚠️ CamaraMenu no encontrada")
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- TRANSICIONES ENTRE ESTADOS
-- ═══════════════════════════════════════════════════════════════════════════════

local function entrarAGameplay(datosNivel)
	print("[ClientBoot] 🎮 TRANSICION: Menu → Gameplay")
	
	-- 1. Ocultar menu PRIMERO
	menu.Enabled = false
	
	-- 2. Mostrar HUD
	hud.Enabled = true
	
	-- 3. Activar gameplay via Orquestador
	if OrquestadorGameplayCliente and OrquestadorGameplayCliente.iniciarGameplay then
		local idNivel = datosNivel and (datosNivel.nivelID or datosNivel.idNivel)
		local exito, error = pcall(function()
			OrquestadorGameplayCliente:iniciarGameplay(idNivel, datosNivel)
		end)
		if not exito then
			warn("[ClientBoot] ⚠️ Error al iniciar gameplay:", error)
		end
	end
	
	print("[ClientBoot] ✅ En gameplay")
end

local function volverAMenu()
	print("[ClientBoot] 🏠 TRANSICION: Gameplay → Menu")
	
	-- 1. Detener gameplay via Orquestador (limpieza completa)
	if OrquestadorGameplayCliente and OrquestadorGameplayCliente.detenerGameplay then
		local exito, error = pcall(function()
			OrquestadorGameplayCliente:detenerGameplay()
		end)
		if not exito then
			warn("[ClientBoot] ⚠️ Error al detener gameplay:", error)
		end
	end
	
	-- 2. Ocultar HUD
	hud.Enabled = false
	
	-- 3. Mostrar menu
	menu.Enabled = true
	
	-- 4. Restaurar camara de menu
	establecerCamaraMenu()
	
	-- 5. Restaurar comportamiento del mouse
	UIS.MouseBehavior = Enum.MouseBehavior.Default
	
	print("[ClientBoot] ✅ En menu")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- EVENTOS DEL SERVIDOR
-- ═══════════════════════════════════════════════════════════════════════════════
local eventsFolder  = RS:WaitForChild("Events", 15)
local remotesFolder = eventsFolder and eventsFolder:WaitForChild("Remotes", 5)

if remotesFolder then
	local nivelListoEv    = remotesFolder:WaitForChild("LevelReady",    10)
	local nivelDescargadoEv = remotesFolder:WaitForChild("LevelUnloaded", 10)

	-- LevelReady: Servidor dice que el nivel esta listo → Entrar a gameplay
	if nivelListoEv then
		nivelListoEv.OnClientEvent:Connect(function(datos)
			if datos and datos.error then 
				warn("[ClientBoot] ❌ Error del servidor:", datos.error)
				return 
			end
			entrarAGameplay(datos)
		end)
	end

	-- LevelUnloaded: Servidor dice que volvimos al menu
	if nivelDescargadoEv then
		nivelDescargadoEv.OnClientEvent:Connect(function()
			volverAMenu()
		end)
	end
else
	warn("[ClientBoot] ❌ No se encontraron Remotes")
end

-- Inicializacion
pcall(establecerCamaraMenu)
print("[ClientBoot] ✅ Activo - Esperando en menu")
