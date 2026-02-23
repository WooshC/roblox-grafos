-- ReplicatedStorage/DialogueVisibilityManager.lua
-- Controla la visibilidad de la GUI durante diálogos
-- ✅ FIX: Cierra mapa, restablece cámara y bloquea salto del personaje

local DialogueVisibilityManager = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Referencias
local guiExplorador = nil
local dialogueKit = nil
local isDialogueActive = false

-- ============================================
-- HELPERS INTERNOS
-- ============================================

--- Obtiene MapManager si está disponible (cargado por GUIExplorador)
local function getMapManager()
	-- MapManager es un módulo local del cliente, accedemos vía _G si fue expuesto,
	-- o buscamos el estado del mapa a través del evento/atributo del jugador.
	-- La forma más segura: disparar un BindableEvent para que MapManager se desactive.
	local Events = ReplicatedStorage:FindFirstChild("Events")
	if not Events then return nil end
	local Bindables = Events:FindFirstChild("Bindables")
	if not Bindables then return nil end
	return Bindables:FindFirstChild("ForceCloseMap")
end

--- Restaura la cámara al modo Custom (personaje)
local function restoreCamera()
	local camera = workspace.CurrentCamera
	if not camera then return end

	-- Si la cámara está en modo Scriptable, animarla de vuelta
	if camera.CameraType == Enum.CameraType.Scriptable then
		local char = player.Character
		local head = char and char:FindFirstChild("Head")

		if head then
			local targetCFrame = CFrame.new(
				head.Position + Vector3.new(0, 5, 10),
				head.Position
			)
			local tweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			TweenService:Create(camera, tweenInfo, {CFrame = targetCFrame}):Play()
			task.wait(0.6)
		end

		camera.CameraType = Enum.CameraType.Custom
		print("📷 DialogueVisibilityManager: Cámara restaurada a Custom")
	end
end

--- Bloquea/desbloquea el salto y movimiento extra del personaje
local function setPlayerMovementLocked(locked)
	local char = player.Character
	if not char then return end

	local humanoid = char:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then return end

	if locked then
		-- Guardar estado original en atributos del Humanoid para restaurar después
		humanoid:SetAttribute("_dlg_JumpPower",  humanoid.JumpPower)
		humanoid:SetAttribute("_dlg_JumpHeight", humanoid.JumpHeight)
		humanoid:SetAttribute("_dlg_WalkSpeed",  humanoid.WalkSpeed)
		humanoid.JumpPower  = 0
		humanoid.JumpHeight = 0
		humanoid.WalkSpeed  = 0   -- inmovilizar completamente durante el diálogo
		print("🔒 DialogueVisibilityManager: Movimiento bloqueado")
	else
		-- Restaurar valores originales (o valores por defecto de Roblox si no se guardaron)
		local savedJumpPower  = humanoid:GetAttribute("_dlg_JumpPower")
		local savedJumpHeight = humanoid:GetAttribute("_dlg_JumpHeight")
		local savedWalkSpeed  = humanoid:GetAttribute("_dlg_WalkSpeed")
		humanoid.JumpPower  = savedJumpPower  or 50
		humanoid.JumpHeight = savedJumpHeight or 7.2
		humanoid.WalkSpeed  = savedWalkSpeed  or 16
		humanoid:SetAttribute("_dlg_JumpPower",  nil)
		humanoid:SetAttribute("_dlg_JumpHeight", nil)
		humanoid:SetAttribute("_dlg_WalkSpeed",  nil)
		print("🔓 DialogueVisibilityManager: Movimiento restaurado")
	end
end

-- ============================================
-- INICIALIZACIÓN
-- ============================================

function DialogueVisibilityManager.initialize()
	-- Esperar a que DialogueKit esté disponible
	task.spawn(function()
		dialogueKit = playerGui:WaitForChild("DialogueKit", 10)
		if dialogueKit then
			print("✅ DialogueVisibilityManager: DialogueKit encontrado")
		end
	end)

	-- Esperar a que GUIExplorador esté disponible
	task.spawn(function()
		guiExplorador = playerGui:WaitForChild("GUIExplorador", 10)
		if guiExplorador then
			print("✅ DialogueVisibilityManager: GUIExplorador encontrada")
		end
	end)

	-- Asegurar que el BindableEvent ForceCloseMap existe para comunicación
	task.spawn(function()
		local Events = ReplicatedStorage:WaitForChild("Events", 10)
		if not Events then return end
		local Bindables = Events:FindFirstChild("Bindables")
		if not Bindables then
			Bindables = Instance.new("Folder")
			Bindables.Name = "Bindables"
			Bindables.Parent = Events
		end

		if not Bindables:FindFirstChild("ForceCloseMap") then
			local evt = Instance.new("BindableEvent")
			evt.Name = "ForceCloseMap"
			evt.Parent = Bindables
		end

		if not Bindables:FindFirstChild("LocalZoneChanged") then
			local evt = Instance.new("BindableEvent")
			evt.Name = "LocalZoneChanged"
			evt.Parent = Bindables
		end
	end)

	-- Restaurar movimiento si el personaje cambia (respawn durante diálogo)
	player.CharacterAdded:Connect(function(char)
		if isDialogueActive then
			-- El personaje respawneó durante un diálogo; re-aplicar bloqueo
			task.wait(0.1)
			setPlayerMovementLocked(true)
		end
	end)

	print("✅ DialogueVisibilityManager: Inicializado")
end

-- ============================================
-- HELPERS DE TECHO (via BindableEvents)
-- MapManager es el ÚNICO dueño del estado del techo.
-- ============================================

local function dispararEvento(nombre)
	local Events = ReplicatedStorage:FindFirstChild("Events")
	if not Events then return end
	local Bindables = Events:FindFirstChild("Bindables")
	if not Bindables then return end
	local evt = Bindables:FindFirstChild(nombre)
	if evt then
		evt:Fire()
		print("📡 DialogueVisibilityManager: Disparado " .. nombre)
	end
end

local function ocultarTecho()
	dispararEvento("ShowRoof")
end

local function restaurarTecho()
	dispararEvento("RestoreRoof")
end

-- ============================================
-- INICIO DE DIÁLOGO
-- ============================================

--- Llama esto cuando un diálogo comienza
function DialogueVisibilityManager:onDialogueStart()
	if isDialogueActive then return end
	isDialogueActive = true

	-- 1. Ocultar GUIExplorador
	if guiExplorador then
		guiExplorador.Enabled = false
		print("🔒 DialogueVisibilityManager: GUIExplorador ocultada")
	end

	-- 2. Cerrar mapa (sin restaurar techo) + ocultar techo en secuencia correcta
	task.spawn(function()
		-- Primero cerrar el mapa (ForceCloseMap)
		local Events = ReplicatedStorage:FindFirstChild("Events")
		if Events then
			local Bindables = Events:FindFirstChild("Bindables")
			if Bindables then
				local forceCloseMap = Bindables:FindFirstChild("ForceCloseMap")
				if forceCloseMap then
					forceCloseMap:Fire()
					print("🗺️ DialogueVisibilityManager: ForceCloseMap disparado")
				end
			end
		end

		-- Pequeño delay para que MapManager procese el cierre
		task.wait(0.05)

		-- Luego pedir al MapManager que oculte el techo (ShowRoof)
		-- MapManager capturará los originales AHORA (después de que el mapa se cerró)
		-- Pero si el mapa ya los había capturado antes, los conserva.
		ocultarTecho()
	end)

	-- 3. Restaurar cámara
	task.spawn(function()
		task.wait(0.1)
		restoreCamera()
	end)

	-- 4. Bloquear salto
	setPlayerMovementLocked(true)
end

-- ============================================
-- FIN DE DIÁLOGO
-- ============================================

--- Llama esto cuando un diálogo termina
function DialogueVisibilityManager:onDialogueEnd()
	if not isDialogueActive then return end
	isDialogueActive = false

	-- 1. Restaurar GUIExplorador
	if guiExplorador then
		guiExplorador.Enabled = true
		print("📖 DialogueVisibilityManager: GUIExplorador restaurada")
	end

	-- 2. Restaurar techo
	restaurarTecho()

	-- 3. Desbloquear salto
	setPlayerMovementLocked(false)
end

-- ============================================
-- GETTER DE ESTADO
-- ============================================

function DialogueVisibilityManager:isActive()
	return isDialogueActive
end

return DialogueVisibilityManager