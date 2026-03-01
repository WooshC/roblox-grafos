-- ReplicatedStorage/Efectos/EfectosVideo.lua
-- Efectos VFX especiales: clona instancias desde ReplicatedStorage/EfectosVideo/
-- y las reproduce en el espacio del juego (Selector de nodos)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local EfectosVideo = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN POR DEFECTO
-- ═══════════════════════════════════════════════════════════════════════════════

local CONFIG_DEFAULT = {
	nombreEfecto = "EfectoConexion",
	multiplicadorTamano = 3,
	duracion = 1
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- INTERNOS
-- ═══════════════════════════════════════════════════════════════════════════════

local function getCarpetaVFX()
	return ReplicatedStorage:FindFirstChild("EfectosVideo")
end

-- Escala un Model completo (tamaños + posiciones relativas) respecto a un CFrame central
local function escalarModelo(modelo, factor, centroCFrame)
	for _, part in ipairs(modelo:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Size = part.Size * factor
			local relPos = centroCFrame:PointToObjectSpace(part.Position)
			local newPos  = centroCFrame:PointToWorldSpace(relPos * factor)
			part.CFrame   = CFrame.new(newPos) * (part.CFrame - part.CFrame.Position)
			part.Anchored   = true
			part.CanCollide = false
			part.CastShadow = false
		end
	end
end

-- Busca el Selector (BasePart) de un nodo a partir de su nombre en Workspace
local function buscarSelector(nombreNodo)
	local nodo = Workspace:FindFirstChild(nombreNodo, true)
	if not nodo or not nodo:IsA("Model") then return nil end

	local selector = nodo:FindFirstChild("Selector")
	if not selector then return nil end

	if selector:IsA("BasePart") then
		return selector
	elseif selector:IsA("Model") then
		return selector:FindFirstChildOfClass("BasePart")
	end
	return nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- API PÚBLICA
-- ═══════════════════════════════════════════════════════════════════════════════

---Clona un efecto y lo reproduce centrado en una BasePart.
-- El clon se escala `multiplicadorTamano` veces (default 3) y se destruye
-- tras `duracion` segundos (default 1).
--
-- @param nombreEfecto string  - Nombre del efecto en ReplicatedStorage/EfectosVideo/
-- @param parte        BasePart - Part donde se reproduce (Selector del nodo)
-- @param multiplicadorTamano number - Factor de escala (default 3)
-- @param duracion     number  - Segundos hasta destruir (default 1)
-- @return Instance|nil - El clon creado
function EfectosVideo.reproducirEnParte(nombreEfecto, parte, multiplicadorTamano, duracion)
	if not parte or not parte.Parent then return nil end

	local carpeta = getCarpetaVFX()
	if not carpeta then
		warn("[EfectosVideo] Carpeta 'EfectosVideo' no encontrada en ReplicatedStorage")
		return nil
	end

	local plantilla = carpeta:FindFirstChild(nombreEfecto)
	if not plantilla then
		warn("[EfectosVideo] Efecto no encontrado:", nombreEfecto)
		return nil
	end

	multiplicadorTamano = multiplicadorTamano or CONFIG_DEFAULT.multiplicadorTamano
	duracion            = duracion or CONFIG_DEFAULT.duracion

	local clon = plantilla:Clone()

	if clon:IsA("BasePart") then
		-- ── Caso simple: la plantilla es una sola BasePart ──
		clon.Size       = clon.Size * multiplicadorTamano
		clon.CFrame     = parte.CFrame
		clon.Anchored   = true
		clon.CanCollide = false
		clon.CastShadow = false
		clon.Parent     = Workspace

	elseif clon:IsA("Model") then
		-- ── Caso Model: escalar todas las partes desde el centro ──
		local centro = clon.PrimaryPart
			and clon.PrimaryPart.CFrame
			or parte.CFrame

		-- Primero mover al destino (antes de escalar para que el pivot sea correcto)
		if clon.PrimaryPart then
			clon:SetPrimaryPartCFrame(parte.CFrame)
		else
			-- Si no hay PrimaryPart mover cada parte manualmente
			local offset = parte.CFrame.Position - (clon:GetModelCFrame().Position)
			for _, part in ipairs(clon:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CFrame = part.CFrame + offset
				end
			end
		end

		escalarModelo(clon, multiplicadorTamano, parte.CFrame)
		clon.Parent = Workspace

	else
		-- ── Fallback: ParticleEmitter, BillboardGui, etc. — anclar al Selector ──
		clon.Parent = parte
	end

	-- Apagar ParticleEmitters a mitad de la duración para que terminen naturalmente
	task.delay(duracion * 0.5, function()
		if clon and clon.Parent then
			for _, desc in ipairs(clon:GetDescendants()) do
				if desc:IsA("ParticleEmitter") then
					desc.Enabled = false
				end
			end
			if clon:IsA("ParticleEmitter") then
				clon.Enabled = false
			end
		end
	end)

	-- Destruir tras la duración
	task.delay(duracion, function()
		if clon and clon.Parent then
			clon:Destroy()
		end
	end)

	return clon
end

---Reproduce el efecto de conexión en el Selector de un nodo buscado por nombre.
-- Atajo para uso desde ControladorEfectos.
--
-- @param nombreNodo   string - Nombre del nodo en Workspace (buscado recursivamente)
-- @param nombreEfecto string - Nombre del efecto (default "EfectoConexion")
-- @param multiplicadorTamano number - Factor de escala (default 3)
-- @param duracion     number - Segundos hasta destruir (default 1)
-- @return Instance|nil
function EfectosVideo.reproducirConexion(nombreNodo, nombreEfecto, multiplicadorTamano, duracion)
	-- Usar valores por defecto si no se proporcionan
	nombreEfecto = nombreEfecto or CONFIG_DEFAULT.nombreEfecto
	multiplicadorTamano = multiplicadorTamano or CONFIG_DEFAULT.multiplicadorTamano
	duracion = duracion or CONFIG_DEFAULT.duracion

	local selector = buscarSelector(nombreNodo)
	if not selector then
		warn("[EfectosVideo] No se encontró Selector para nodo:", nombreNodo)
		return nil
	end

	return EfectosVideo.reproducirEnParte(nombreEfecto, selector, multiplicadorTamano, duracion)
end

return EfectosVideo