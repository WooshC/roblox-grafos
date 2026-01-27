local objeto = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryManager = require(ReplicatedStorage:WaitForChild("Utilidades"):WaitForChild("InventoryManager"))

-- === CONFIGURACIÓN ===
-- Puedes cambiar esto en los Atributos del objeto o aquí mismo
local ID_OBJETO = objeto:GetAttribute("ID") or "ObjetoGenerico"
local NOMBRE_OBJETO = objeto:GetAttribute("Nombre") or objeto.Name
local ICONO = objeto:GetAttribute("Icono") or "📦"
local NIVEL_ID = objeto:GetAttribute("NivelID") or 0 -- Nivel al que pertenece

-- === PROXIMITY PROMPT ===
local prompt = objeto:FindFirstChild("ProximityPrompt")
if not prompt then
	prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Recoger " .. NOMBRE_OBJETO
	prompt.ObjectText = ICONO .. " " .. NOMBRE_OBJETO
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = objeto
else
    prompt.ActionText = "Recoger " .. NOMBRE_OBJETO
    prompt.ObjectText = ICONO .. " " .. NOMBRE_OBJETO
end

-- === LÓGICA DE RECOLECCIÓN ===
local recogido = false

local function ocultarObjeto()
	recogido = true
	prompt.Enabled = false
	
	if objeto:IsA("Model") then
		for _, part in ipairs(objeto:GetDescendants()) do
			if part:IsA("BasePart") or part:IsA("Decal") or part:IsA("Texture") then
				-- Guardar transparencia original si no existe
				if not part:GetAttribute("OriginalTransparency") then
					part:SetAttribute("OriginalTransparency", part.Transparency)
				end
				part.Transparency = 1
				if part:IsA("BasePart") then part.CanCollide = false end
			end
		end
	elseif objeto:IsA("BasePart") then
		if not objeto:GetAttribute("OriginalTransparency") then
			objeto:SetAttribute("OriginalTransparency", objeto.Transparency)
		end
		objeto.Transparency = 1
		objeto.CanCollide = false
	end
end

local function mostrarObjeto()
	recogido = false
	prompt.Enabled = true
	
	if objeto:IsA("Model") then
		for _, part in ipairs(objeto:GetDescendants()) do
			if part:IsA("BasePart") or part:IsA("Decal") or part:IsA("Texture") then
				local orig = part:GetAttribute("OriginalTransparency") or 0
				part.Transparency = orig
				if part:IsA("BasePart") then part.CanCollide = true end
			end
		end
	elseif objeto:IsA("BasePart") then
		local orig = objeto:GetAttribute("OriginalTransparency") or 0
		objeto.Transparency = orig
		objeto.CanCollide = true
	end
end

prompt.Triggered:Connect(function(player)
	-- Verificar Nivel (Opcional, pero recomendado)
	local stats = player:FindFirstChild("leaderstats")
	local nivelJugador = stats and stats:FindFirstChild("Nivel") and stats.Nivel.Value or 0
	
	-- Si quieres restringir por nivel descomenta esto:
    -- if nivelJugador ~= NIVEL_ID then
    --     print("⚠️ Aún no puedes recoger esto.")
    --     return
    -- end
	
	-- Lógica de Inventario
	print("🎒 " .. player.Name .. " recogió: " .. ID_OBJETO)
	InventoryManager.agregarObjeto(player, ID_OBJETO)
	
	-- Efecto visual
	ocultarObjeto()
end)

-- === SISTEMI DE REINICIO (REAPARECER) ===
local evFolder = ReplicatedStorage:WaitForChild("ServerEvents", 10)
if evFolder then
	local eventoRestaurar = evFolder:WaitForChild("RestaurarObjetos", 10)
	if eventoRestaurar then
		eventoRestaurar.Event:Connect(function(nivelReiniciado)
			if nivelReiniciado == NIVEL_ID then
				print("🔄 Restaurando objeto: " .. ID_OBJETO)
				mostrarObjeto()
			end
		end)
	end
end

print("✅ Script Recolectable iniciado para: " .. objeto.Name)
