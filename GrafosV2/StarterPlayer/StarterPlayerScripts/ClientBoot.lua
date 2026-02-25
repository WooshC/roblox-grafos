-- ClientBoot.client.lua
-- Gestiona el ciclo de vida de las GUIs del cliente para EDA Quest v2.
--
-- Responsabilidades:
--   1. Activar EDAQuestMenu al inicio (estaba desactivada por defecto)
--   2. Al recibir LevelReady → apagar EDAQuestMenu + encender GUIExploradorV2
--   3. Al recibir señal de volver al menú → apagar GUIExploradorV2 + encender EDAQuestMenu
--
-- Ubicación Roblox: StarterPlayerScripts/ClientBoot.client.lua  (LocalScript)
-- ⚠️ Debe existir en StarterPlayerScripts (NO en StarterGui), ya que lee PlayerGui.

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ── 1. Esperar y activar EDAQuestMenu ─────────────────────────────────────
-- MenuController.client.lua (en StarterGui) genera la GUI; esperamos a que exista.
local menu = playerGui:WaitForChild("EDAQuestMenu", 20)
if not menu then
	warn("[ClientBoot] ❌ EDAQuestMenu no encontrada en PlayerGui después de 20 s.")
	warn("[ClientBoot]    Verifica que crearGUIMenu.lua esté en StarterGui y corra correctamente.")
	-- Intentar encontrarla de todas formas (puede aparecer tarde)
	menu = playerGui:FindFirstChild("EDAQuestMenu")
end

if menu then
	menu.Enabled = true
	print("[ClientBoot] ✅ EDAQuestMenu activada")
else
	warn("[ClientBoot] ⚠ EDAQuestMenu no encontrada — el menú no será visible")
end

-- ── 2. Conectar con eventos del servidor ───────────────────────────────────
local eventsFolder = RS:WaitForChild("Events", 15)
if not eventsFolder then
	warn("[ClientBoot] ❌ Carpeta Events no encontrada. ¿Están creados los RemoteEvents en Studio?")
	return
end

local remotesFolder = eventsFolder:WaitForChild("Remotes", 5)
if not remotesFolder then
	warn("[ClientBoot] ❌ Carpeta Remotes no encontrada dentro de Events.")
	return
end

local levelReadyEv = remotesFolder:WaitForChild("LevelReady", 5)
-- ReturnToMenu: Boot.server.lua NUNCA dispara este evento al cliente.
-- El flujo de vuelta al menú lo maneja HUDController.doReturnToMenu() directamente.

-- ── Helper: obtener GUIExploradorV2 (puede no existir al inicio) ───────────
local function getExplorador()
	return playerGui:FindFirstChild("GUIExploradorV2")
end

-- ── 3. Al cargar nivel → swap de GUIs ─────────────────────────────────────
if levelReadyEv then
	levelReadyEv.OnClientEvent:Connect(function(data)
		-- Si hay error en la carga, MenuController ya maneja el fallback.
		-- ClientBoot NO debe activar GUIExploradorV2 en ese caso.
		if data and data.error then
			print("[ClientBoot] LevelReady con error — no se activa GUIExploradorV2")
			return
		end

		-- Desactivar menú
		-- MenuController ya hace root.Enabled = false, pero lo reforzamos aquí.
		if menu then
			menu.Enabled = false
			print("[ClientBoot] EDAQuestMenu desactivada (nivel cargado)")
		end

		-- Activar GUI de gameplay
		local explorador = getExplorador()
		if explorador then
			explorador.Enabled = true
			print("[ClientBoot] ✅ GUIExploradorV2 activada — nivel:", data and data.nivelID or "?")
		else
			warn("[ClientBoot] ⚠ GUIExploradorV2 no encontrada en PlayerGui.")
			warn("[ClientBoot]   Asegúrate de que GUIExploradorV2 esté en StarterGui con Enabled=false.")
		end
	end)
else
	warn("[ClientBoot] LevelReady RemoteEvent no encontrado")
end

-- ── 4. Vuelta al menú ──────────────────────────────────────────────────────
-- El swap de GUIs al volver al menú lo gestiona HUDController.doReturnToMenu().
-- ClientBoot solo es responsable de activar GUIs al cargar un nivel (paso 3 arriba).

print("[ClientBoot] ✅ Activo — gestionando ciclo de vida de GUIs")