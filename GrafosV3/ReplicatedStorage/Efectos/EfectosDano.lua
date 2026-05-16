-- ReplicatedStorage/Efectos/EfectosDano.lua
-- Efectos persistentes de daño en nodos usando Fire + Smoke nativos de Roblox.
-- Se activan al entrar a una zona con emergencia y se desactivan al completarla.

local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local EfectosDano = {}

-- Mapa de efectos activos: { nombreNodo → Instance (emisor con Fire/Smoke) }
local _efectosActivos = {}

-- Busca el Selector (BasePart) de un nodo dentro de NivelActual
local function buscarSelector(nombreNodo)
	local nivel = Workspace:FindFirstChild("NivelActual")
	if not nivel then return nil end
	local nodo = nivel:FindFirstChild(nombreNodo, true)
	if not nodo or not nodo:IsA("Model") then return nil end

	local selector = nodo:FindFirstChild("Selector")
	if not selector then return nil end
	if selector:IsA("BasePart") then return selector end
	if selector:IsA("Model") then return selector:FindFirstChildOfClass("BasePart") end
	return nil
end

---Activa el efecto de daño constante en un nodo.
-- @param nombreNodo string
function EfectosDano.activar(nombreNodo)
	if _efectosActivos[nombreNodo] then return end

	local selector = buscarSelector(nombreNodo)
	if not selector then
		-- Reintentar: el nivel puede no haberse replicado todavía
		task.delay(0.3, function()
			if not _efectosActivos[nombreNodo] then
				EfectosDano.activar(nombreNodo)
			end
		end)
		return
	end

	print("[EfectosDano] ⚡ Activando daño en:", nombreNodo)

	-- Emisor invisible posicionado sobre el nodo
	local emisor = Instance.new("Part")
	emisor.Name = "Dano_Emisor"
	emisor.Anchored = true
	emisor.CanCollide = false
	emisor.Transparency = 1
	emisor.Size = Vector3.new(2, 2, 2)
	emisor.Position = selector.Position + Vector3.new(0, 4, 0)
	emisor.Parent = selector

	-- Fuego nativo de Roblox (chispas + llamas)
	local fuego = Instance.new("Fire")
	fuego.Name = "Dano_Fuego"
	fuego.Color = Color3.fromRGB(255, 120, 30)
	fuego.SecondaryColor = Color3.fromRGB(255, 60, 10)
	fuego.Size = 6
	fuego.Heat = 8
	fuego.Parent = emisor

	-- Humo nativo de Roblox
	local humo = Instance.new("Smoke")
	humo.Name = "Dano_Humo"
	humo.Color = Color3.fromRGB(80, 80, 80)
	humo.Size = 4
	humo.Opacity = 0.5
	humo.RiseVelocity = 3
	humo.Parent = emisor

	-- Luz parpadeante naranja
	local luz = Instance.new("PointLight")
	luz.Name = "Dano_Luz"
	luz.Color = Color3.fromRGB(255, 80, 20)
	luz.Brightness = 3
	luz.Range = 15
	luz.Parent = emisor

	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	TweenService:Create(luz, tweenInfo, { Brightness = 0.5 }):Play()

	_efectosActivos[nombreNodo] = emisor
end

---Desactiva el efecto de daño en un nodo (fade-out y destrucción).
-- @param nombreNodo string
function EfectosDano.desactivar(nombreNodo)
	local emisor = _efectosActivos[nombreNodo]
	if not emisor then return end

	print("[EfectosDano] ✅ Reparando nodo, desactivando daño:", nombreNodo)

	local fuego = emisor:FindFirstChild("Dano_Fuego")
	local humo = emisor:FindFirstChild("Dano_Humo")
	local luz = emisor:FindFirstChild("Dano_Luz")

	-- Apagar fuego y humo
	if fuego then fuego.Enabled = false end
	if humo then humo.Enabled = false end
	if luz then
		TweenService:Create(luz, TweenInfo.new(0.5), { Brightness = 0 }):Play()
	end

	-- Destruir tras 1.5 segundos
	task.delay(1.5, function()
		if emisor and emisor.Parent then
			emisor:Destroy()
		end
	end)

	_efectosActivos[nombreNodo] = nil
end

---Desactiva todos los efectos de daño activos.
function EfectosDano.limpiarTodo()
	for nombreNodo, _ in pairs(_efectosActivos) do
		EfectosDano.desactivar(nombreNodo)
	end
	_efectosActivos = {}
end

---Devuelve si un nodo tiene efecto de daño activo.
function EfectosDano.estaActivo(nombreNodo)
	return _efectosActivos[nombreNodo] ~= nil
end

return EfectosDano
