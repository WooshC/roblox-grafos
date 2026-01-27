local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local InventoryManager = require(ReplicatedStorage:WaitForChild("Utilidades"):WaitForChild("InventoryManager"))

-- === REFERENCIA AL OBJETO ===
-- El script está en ServerScriptService, así que debemos buscar el modelo en el Workspace
local NIVEL_ID = 0
local NOMBRE_MODELO = "MapaModel"
local objeto = nil

-- Intentar buscar el modelo
local nivelModel = workspace:WaitForChild("Nivel" .. NIVEL_ID .. "_Tutorial", 10)
if nivelModel then
	local carpeta = nivelModel:FindFirstChild("ObjetosColeccionables") or nivelModel:FindFirstChild("Items")
	if carpeta then
		objeto = carpeta:WaitForChild(NOMBRE_MODELO, 10)
	end
end

if not objeto then
	warn("❌ SCRIPT MAPA: No se encontró el modelo " .. NOMBRE_MODELO .. " en Nivel " .. NIVEL_ID)
	return -- Abortar si no hay modelo
end

-- === CONFIGURACIÓN MANUAL ===
local ID_OBJETO = "Mapa"
local NOMBRE_OBJETO = "Mapa del Pueblo"
local NIVEL_ID = 0 -- Pertenece al Tutorial

-- === ESTADO INICIAL ===
-- El Mapa empieza oculto y desactivado
local activo = false 
local debounce = false
local historiaCompletada = false -- 🔒 Variable de estado para controlar "trampas"

-- === FUNCIONES VISIBILIDAD ===
local function ocultarObjeto()
	activo = false
	if objeto:IsA("Model") then
		for _, part in ipairs(objeto:GetDescendants()) do
			if part:IsA("BasePart") or part:IsA("Decal") then
				if not part:GetAttribute("OriginalTransparency") then
					part:SetAttribute("OriginalTransparency", part.Transparency)
				end
				part.Transparency = 1
				-- Hacemos CanCollide false para que no estorbe, pero CanTouch debe ser false para evitar triggers fantasma
				if part:IsA("BasePart") then 
					part.CanCollide = false 
					part.CanTouch = false
				end
			end
		end
	end
end

local function mostrarObjeto()
	activo = true
	debounce = false -- Resetear debounce al aparecer
	if objeto:IsA("Model") then
		for _, part in ipairs(objeto:GetDescendants()) do
			if part:IsA("BasePart") or part:IsA("Decal") then
				part.Transparency = part:GetAttribute("OriginalTransparency") or 0
				if part:IsA("BasePart") then 
					part.CanCollide = true -- O false si es fantasma, pero dejémoslo true para que se sienta
					part.CanTouch = true
				end
			end
		end
	end
	print("🗺️ MAPA APARECIDO - Listo para recoger")
end

-- Ocultar al inicio del script
ocultarObjeto()

-- === LÓGICA DE RECOLECCIÓN (TOQUE) ===
local function alTocar(hit)
	if not activo or debounce then return end

	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)

	if player then
		debounce = true
		print("🎒 " .. player.Name .. " tocó y recogió: " .. ID_OBJETO)
		InventoryManager.agregarObjeto(player, ID_OBJETO)

		-- Efecto de sonido (Opcional)
		local sonido = Instance.new("Sound")
		sonido.SoundId = "rbxassetid://12221967" -- Sonido "Coin" genérico
		sonido.Parent = character.Head
		sonido:Play()
		game.Debris:AddItem(sonido, 1)

		-- Desaparecer
		activo = false
		ocultarObjeto()
	end
end

-- Conectar evento Touched a todas las partes del modelo
if objeto:IsA("Model") then
	for _, child in ipairs(objeto:GetDescendants()) do
		if child:IsA("BasePart") then
			child.Touched:Connect(alTocar)
		end
	end
elseif objeto:IsA("BasePart") then
	objeto.Touched:Connect(alTocar)
end

-- === ESCUCHAR APARICIÓN (Diálogo) ===
local evFolder = ReplicatedStorage:WaitForChild("ServerEvents", 10)
if evFolder then
	local eventoDesbloquear = evFolder:WaitForChild("DesbloquearObjeto", 10)
	if eventoDesbloquear then
		eventoDesbloquear.Event:Connect(function(idSolicitado, nivelSolicitado)
			if idSolicitado == ID_OBJETO then -- Solo si me llaman a mí
				historiaCompletada = true -- 🔓 DESBLOQUEADO PERMANENTEMENTE (hasta que recargue el server)
				mostrarObjeto()
			end
		end)
	end

	-- === ESCUCHAR RESTAURACIÓN (Reinicio) ===
	local eventoRestaurar = evFolder:WaitForChild("RestaurarObjetos", 10)
	if eventoRestaurar then
		eventoRestaurar.Event:Connect(function(nivelReiniciado)
			if nivelReiniciado == NIVEL_ID then
				-- Al reiniciar, mostramos el objeto SOLO si ya pasamos la historia
				if historiaCompletada then
					mostrarObjeto()
				else
					ocultarObjeto()
				end
			end
		end)
	end
end

print("✅ Script MAPA (TOQUE + ANTI-TRAMPA) iniciado")
