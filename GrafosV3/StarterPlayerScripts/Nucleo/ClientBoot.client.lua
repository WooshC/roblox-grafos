-- GrafosV3 - ClientBoot.client.lua
-- Punto de entrada UNICO del cliente.
-- Responsabilidad: Gestionar el ciclo de vida de la UI (Menu <-> Gameplay)

local Jugadores = game:GetService("Players")
local Replicado = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

local jugadorLocal = Jugadores.LocalPlayer
local playerGui = jugadorLocal:WaitForChild("PlayerGui")

print("[GrafosV3] === ClientBoot Iniciando ===")

-- ═══════════════════════════════════════════════════════════════════════════════
-- 1. ESPERAR EVENTOS DEL SERVIDOR
-- ═══════════════════════════════════════════════════════════════════════════════
local carpetaEventos = Replicado:WaitForChild("Events", 10)
if not carpetaEventos then
	error("[GrafosV3] ❌ No se encontro Events en ReplicatedStorage")
end

local remotes = carpetaEventos:WaitForChild("Remotes", 5)
if not remotes then
	error("[GrafosV3] ❌ No se encontro Remotes en Events")
end

-- Referencias a eventos
local ServerReady = remotes:WaitForChild("ServerReady", 10)
local LevelReady = remotes:WaitForChild("LevelReady", 10)
local LevelUnloaded = remotes:WaitForChild("LevelUnloaded", 10)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 2. REFERENCIAS A GUI
-- ═══════════════════════════════════════════════════════════════════════════════
local guiMenu = nil
local guiHUD = nil

local function buscarGUI()
	if guiMenu and guiHUD then return true end
	
	guiMenu = playerGui:FindFirstChild("EDAQuestMenu")
	guiHUD = playerGui:FindFirstChild("GUIExploradorV2")
	
	if guiMenu and guiHUD then
		print("[GrafosV3] ✅ GUI encontradas:")
		print("  - EDAQuestMenu:", guiMenu and "✅" or "❌")
		print("  - GUIExploradorV2:", guiHUD and "✅" or "❌")
		return true
	end
	
	return false
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 3. CONFIGURACION INICIAL
-- ═══════════════════════════════════════════════════════════════════════════════
local function configurarCamaraMenu()
	local camara = workspace.CurrentCamera
	local camaraMenu = workspace:WaitForChild("CamaraMenu", 5)
	
	if camaraMenu then
		local parte = camaraMenu:IsA("BasePart") and camaraMenu or camaraMenu:FindFirstChildWhichIsA("BasePart")
		if parte then
			camara.CameraType = Enum.CameraType.Scriptable
			camara.CFrame = parte.CFrame
			print("[GrafosV3] Camara configurada en MENU")
		end
	else
		warn("[GrafosV3] ⚠️ CamaraMenu no encontrada en Workspace")
	end
end

local function mostrarMenu()
	print("[GrafosV3] Mostrando MENU")
	
	if guiMenu then
		guiMenu.Enabled = true
	else
		warn("[GrafosV3] ❌ guiMenu es nil")
	end
	
	if guiHUD then
		guiHUD.Enabled = false
	end
	
	configurarCamaraMenu()
	UIS.MouseBehavior = Enum.MouseBehavior.Default
end

local function mostrarGameplay()
	print("[GrafosV3] Mostrando GAMEPLAY")
	
	if guiMenu then
		guiMenu.Enabled = false
	end
	
	if guiHUD then
		guiHUD.Enabled = true
	else
		warn("[GrafosV3] ⚠️ guiHUD es nil (esperado si aun no existe)")
	end
	
	-- Configurar camara de gameplay
	local camara = workspace.CurrentCamera
	camara.CameraType = Enum.CameraType.Custom
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 4. HANDLERS DE EVENTOS DEL SERVIDOR
-- ═══════════════════════════════════════════════════════════════════════════════

-- ServerReady: El servidor esta listo y la GUI deberia estar copiada
if ServerReady then
	ServerReady.OnClientEvent:Connect(function()
		print("[GrafosV3] ServerReady recibido")
		
		-- Buscar GUI (con reintentos)
		local intentos = 0
		while not buscarGUI() and intentos < 30 do
			task.wait(0.1)
			intentos = intentos + 1
		end
		
		if guiMenu then
			mostrarMenu()
			
			-- Cargar el menu
			local menuController = script.Parent.Parent:FindFirstChild("Menu")
			if menuController then
				local moduloMenu = menuController:FindFirstChild("ControladorMenu")
				if moduloMenu then
					task.spawn(function()
						local exito, err = pcall(function()
							require(moduloMenu)
						end)
						if not exito then
							warn("[GrafosV3] Error cargando ControladorMenu:", err)
						end
					end)
				end
			end
		else
			warn("[GrafosV3] ❌ No se encontraron las GUI después de 3s")
		end
	end)
else
	warn("[GrafosV3] ❌ ServerReady no encontrado")
end

-- LevelReady: Entrar a gameplay
if LevelReady then
	LevelReady.OnClientEvent:Connect(function(datos)
		print("[GrafosV3] LevelReady recibido:", datos and datos.nivelID)
		
		if datos and datos.error then
			warn("[GrafosV3] ❌ Error del servidor:", datos.error)
			return
		end
		
		mostrarGameplay()
	end)
end

-- LevelUnloaded: Volver al menu
if LevelUnloaded then
	LevelUnloaded.OnClientEvent:Connect(function()
		print("[GrafosV3] LevelUnloaded recibido")
		mostrarMenu()
	end)
end

print("[GrafosV3] === ClientBoot Listo - Esperando ServerReady ===")
