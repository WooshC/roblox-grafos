-- ModuloAnalisis/ViewportAnalisis.lua
-- Gestiona el ViewportFrame 3D: nodos, aristas progresivas y partículas.
--
-- Aristas en 3 capas (reconstruidas en cada paso):
--   Gris   / SmoothPlastic / 0.6 transparencia → grafo completo (fondo siempre visible)
--   Verde  / Neon          / 0   transparencia → aristas del árbol ya recorridas
--   Naranja/ Neon          / 0   transparencia → arista recién creada en este paso (aristaNueva)
--
-- Partículas: solo en la arista recién creada (aristaNueva), efecto de "energía fluyendo".

local TweenService = game:GetService("TweenService")

local E = require(script.Parent.EstadoAnalisis)
local C = require(script.Parent.ConstantesAnalisis)

local ViewportAnalisis = {}

-- ════════════════════════════════════════════════════════════════
-- POSICIÓN DE NODO EN EL NIVEL 3D
-- ════════════════════════════════════════════════════════════════

local function buscarPosNodo(nombre)
	if not E.nivelModel then return Vector3.zero end
	local grafos = E.nivelModel:FindFirstChild("Grafos")
	if not grafos then return Vector3.zero end

	for _, grafo in ipairs(grafos:GetChildren()) do
		local nodosFolder = grafo:FindFirstChild("Nodos")
		if not nodosFolder then continue end
		local nodoModelo = nodosFolder:FindFirstChild(nombre)
		if not nodoModelo then continue end

		local selector = nodoModelo:FindFirstChild("Selector")
		local posRef   = nil
		if selector then
			if selector:IsA("BasePart") then
				posRef = selector
			elseif selector:IsA("Model") then
				posRef = selector.PrimaryPart
				    or selector:FindFirstChildWhichIsA("BasePart", true)
			end
		end
		if not posRef then
			posRef = nodoModelo.PrimaryPart
			    or nodoModelo:FindFirstChildWhichIsA("BasePart", true)
		end
		if posRef then return posRef.Position end
	end
	return Vector3.zero
end

-- ════════════════════════════════════════════════════════════════
-- PARTÍCULAS
-- ════════════════════════════════════════════════════════════════

local function spawnParticulaArista(posA, posB, color)
	if not E.worldModel then return end
	local dist = (posA - posB).Magnitude
	if dist < 0.1 then return end

	local duracion = dist / C.VEL_PART

	local p = Instance.new("Part")
	p.Name       = "PartANA"
	p.Shape      = Enum.PartType.Ball
	p.Anchored   = true
	p.CanCollide = false
	p.CastShadow = false
	p.Material   = Enum.Material.Neon
	p.Size       = Vector3.new(C.TAM_PART, C.TAM_PART, C.TAM_PART)
	p.Color      = color
	p.Position   = posA
	p.Parent     = E.worldModel

	local tween = TweenService:Create(
		p,
		TweenInfo.new(duracion, Enum.EasingStyle.Linear),
		{ Position = posB }
	)
	tween.Completed:Connect(function()
		if p and p.Parent then p:Destroy() end
	end)
	tween:Play()
end

local function idConexion(nomA, nomB)
	return nomA < nomB and (nomA .. "_" .. nomB) or (nomB .. "_" .. nomA)
end

local function iniciarParticulasArista(id, posA, posB, colorAB, colorBA)
	if E.partActivas[id] then return end
	E.partActivas[id] = true

	task.spawn(function()
		while E.partActivas[id] do
			spawnParticulaArista(posA, posB, colorAB)
			task.wait(C.FREQ_PART)
		end
	end)

	task.spawn(function()
		task.wait(C.FREQ_PART / 2)
		while E.partActivas[id] do
			spawnParticulaArista(posB, posA, colorBA)
			task.wait(C.FREQ_PART)
		end
	end)
end

function ViewportAnalisis.limpiarParticulas()
	for id in pairs(E.partActivas) do
		E.partActivas[id] = nil
	end
end

-- ════════════════════════════════════════════════════════════════
-- CONSTRUIR VIEWPORT (nodos estáticos)
-- ════════════════════════════════════════════════════════════════

function ViewportAnalisis.construirViewport()
	if not E.visor or not E.worldModel or not E.matrizData then return end

	ViewportAnalisis.limpiarParticulas()
	E.worldModel:ClearAllChildren()
	E.nodoParts       = {}
	E.aristaParts     = {}
	E.posicionesNodos = {}

	local headers = E.matrizData.Headers

	for _, nome in ipairs(headers) do
		local pos = buscarPosNodo(nome)
		E.posicionesNodos[nome] = pos

		local part        = Instance.new("Part")
		part.Name         = nome .. "_ANA"
		part.Shape        = Enum.PartType.Ball
		part.Anchored     = true
		part.CanCollide   = false
		part.CastShadow   = false
		part.Material     = Enum.Material.SmoothPlastic
		part.Size         = Vector3.new(C.TAM_NODO, C.TAM_NODO, C.TAM_NODO)
		part.Color        = C.COL_DEFAULT
		part.CFrame       = CFrame.new(pos)
		part.Parent       = E.worldModel

		E.nodoParts[nome] = part
	end

	-- Cámara top-down sobre el centroide
	local n = 0
	local sumX, sumY, sumZ = 0, 0, 0
	for _, pos in pairs(E.posicionesNodos) do
		sumX = sumX + pos.X
		sumY = sumY + pos.Y
		sumZ = sumZ + pos.Z
		n    = n + 1
	end

	if n > 0 and E.camAnalisis then
		local cx = sumX / n
		local cy = sumY / n
		local cz = sumZ / n

		local maxR = 0
		for _, pos in pairs(E.posicionesNodos) do
			local r = math.sqrt((pos.X - cx)^2 + (pos.Z - cz)^2)
			if r > maxR then maxR = r end
		end
		local altura = math.max(30, maxR * 2.5)

		E.camAnalisis.CFrame      = CFrame.new(cx, cy + altura, cz) * CFrame.Angles(math.rad(-90), 0, 0)
		E.camAnalisis.FieldOfView = 70
	end

	print("[ViewportAnalisis] Viewport construido —", #headers, "nodos")
end

-- ════════════════════════════════════════════════════════════════
-- RECONSTRUIR ARISTAS — 3 capas progresivas
-- ════════════════════════════════════════════════════════════════

function ViewportAnalisis.reconstruirAristas(step)
	-- 1. Destruir aristas anteriores
	for _, part in ipairs(E.aristaParts) do
		if part and part.Parent then part:Destroy() end
	end
	E.aristaParts = {}

	-- 2. Detener partículas
	ViewportAnalisis.limpiarParticulas()

	-- 3. Construir sets para clasificar aristas
	local recorridasSet = {}  -- { ["A|B"] = true } aristas del árbol acumuladas
	local nuevaKey      = nil -- "A|B" de la arista recién creada

	if step then
		for _, arista in ipairs(step.aristasRecorridas or {}) do
			local a, b = arista[1], arista[2]
			local key  = a < b and (a .. "|" .. b) or (b .. "|" .. a)
			recorridasSet[key] = true
		end

		if step.aristaNueva then
			local a, b = step.aristaNueva[1], step.aristaNueva[2]
			nuevaKey = a < b and (a .. "|" .. b) or (b .. "|" .. a)
		end
	end

	-- 4. Dibujar TODAS las aristas del grafo completo
	local vistos = {}
	for nomA, lista in pairs(E.adyacencias) do
		for _, nomB in ipairs(lista) do
			local key = nomA < nomB and (nomA .. "|" .. nomB) or (nomB .. "|" .. nomA)
			if vistos[key] then continue end
			vistos[key] = true

			local posA = E.posicionesNodos[nomA]
			local posB = E.posicionesNodos[nomB]
			if not posA or not posB then continue end

			local dist = (posA - posB).Magnitude
			if dist < 0.1 then continue end

			-- Clasificar arista
			local esNueva     = (key == nuevaKey)
			local esRecorrida = recorridasSet[key]

			local color, alpha, mat
			if esNueva then
				color = C.COL_ARISTA_NUEVA
				alpha = 0
				mat   = Enum.Material.Neon
			elseif esRecorrida then
				color = C.COL_ARISTA_VISIT
				alpha = 0
				mat   = Enum.Material.Neon
			else
				color = C.COL_ARISTA_DEFAULT
				alpha = 0.55
				mat   = Enum.Material.SmoothPlastic
			end

			-- Crear cilindro
			local centro       = (posA + posB) / 2
			local arista       = Instance.new("Part")
			arista.Name        = "AristaANA"
			arista.Anchored    = true
			arista.CanCollide  = false
			arista.CastShadow  = false
			arista.Material    = mat
			arista.Size        = Vector3.new(C.TAM_ARISTA, C.TAM_ARISTA, dist)
			arista.CFrame      = CFrame.lookAt(centro, posB)
			arista.Color       = color
			arista.Transparency = alpha
			arista.Parent      = E.worldModel

			table.insert(E.aristaParts, arista)

			-- Partículas solo en la arista nueva (recién creada)
			if esNueva then
				local id = idConexion(nomA, nomB)
				iniciarParticulasArista(id, posA, posB, C.COL_PART_NUEVA, C.COL_PART_NUEVA)
			end
		end
	end
end

return ViewportAnalisis
