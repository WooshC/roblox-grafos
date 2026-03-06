-- ModuloAnalisis/ViewportAnalisis.lua
-- Gestiona el ViewportFrame 3D: nodos, aristas progresivas y partículas.
--
-- Partículas direccionales:
--   Grafo NO dirigido → partículas en AMBAS direcciones (A→B y B→A)
--   Grafo DIRIGIDO    → partícula solo en la dirección que existe en adyacencias (A→B)
--
-- Para determinar la dirección de cada arista se consulta E.adyacencias y E.matrizData.EsDirigido.
--
-- FIX (duplicación de partículas):
--   reconstruirAristas ya NO llama limpiarParticulas() globalmente en cada paso.
--   En su lugar compara el conjunto activo anterior con el nuevo:
--     • IDs que desaparecen  → se detienen (versión → 0)
--     • IDs que permanecen   → se dejan intactos (sin reiniciar)
--     • IDs genuinamente nuevos → se inician por primera vez
--   limpiarParticulas() se reserva para el reset completo (cambio de algoritmo / cierre).

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
-- HELPERS DE DIRECCIÓN
-- ════════════════════════════════════════════════════════════════

-- Devuelve true si nomA → nomB existe en adyacencias
local function existeArista(nomA, nomB)
	local lista = E.adyacencias[nomA]
	if not lista then return false end
	for _, v in ipairs(lista) do
		if v == nomB then return true end
	end
	return false
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

-- ── Sistema de versiones ──────────────────────────────────────────────────────
-- E.partActivas[id] guarda un número de versión (entero).
-- Cada loop spawn captura su versión al nacer; si al despertar la versión
-- en E.partActivas ya es distinta (o nil / 0), el loop se considera zombie y muere.
-- Así se eliminan los loops que estaban en task.wait cuando se llamó limpiar().

local function iniciarParticulasArista(id, nomA, nomB, posA, posB, esDirigido)
	-- Incrementar versión → invalida todos los loops anteriores de este id
	local version = (E.partActivas[id] or 0) + 1
	E.partActivas[id] = version

	local aDirigidoAB = esDirigido and existeArista(nomA, nomB)
	local aDirigidoBA = esDirigido and existeArista(nomB, nomA)

	-- Dirección A → B
	if not esDirigido or aDirigidoAB then
		local v = version
		task.spawn(function()
			while E.partActivas[id] == v do
				spawnParticulaArista(posA, posB, C.COL_PART_NUEVA)
				task.wait(C.FREQ_PART)
			end
		end)
	end

	-- Dirección B → A (solo si no dirigido, o si existe la arista inversa)
	if not esDirigido or aDirigidoBA then
		local v = version
		task.spawn(function()
			task.wait(C.FREQ_PART / 2)   -- desfase para que no salgan juntas
			while E.partActivas[id] == v do
				spawnParticulaArista(posB, posA, C.COL_PART_VISIT)
				task.wait(C.FREQ_PART)
			end
		end)
	end
end

-- Detiene loops de un ID específico sin tocar los demás.
local function detenerParticulasId(id)
	if E.partActivas[id] then
		E.partActivas[id] = 0
		E.partActivas[id] = nil
	end
end

-- Reset total: para cuando se cambia de algoritmo, se cierra el panel, etc.
function ViewportAnalisis.limpiarParticulas()
	for id in pairs(E.partActivas) do
		E.partActivas[id] = 0
	end
	table.clear(E.partActivas)
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
-- RECONSTRUIR ARISTAS — 3 capas progresivas + partículas direccionales
-- ════════════════════════════════════════════════════════════════

function ViewportAnalisis.reconstruirAristas(step)
	-- 1. Destruir cilindros de aristas del frame anterior
	for _, part in ipairs(E.aristaParts) do
		if part and part.Parent then part:Destroy() end
	end
	E.aristaParts = {}

	-- 2. Calcular el NUEVO conjunto de IDs que deben tener partículas activas
	local nuevoSetPart = {}   -- [id] = { nomA, nomB, posA, posB }

	-- 3. Clasificar aristas del paso
	local recorridasSet = {}
	local nuevaKey      = nil

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

	-- 4. ¿Es dirigido el grafo de esta zona?
	local esDirigido = E.matrizData and E.matrizData.EsDirigido or false

	-- 5. Dibujar TODAS las aristas del grafo completo
	local vistosND = {}   -- para grafos no dirigidos: evitar duplicar cilindros

	for nomA, lista in pairs(E.adyacencias) do
		for _, nomB in ipairs(lista) do

			-- Key canónica (para clasificar estado)
			local key = nomA < nomB and (nomA .. "|" .. nomB) or (nomB .. "|" .. nomA)

			-- Para NO dirigido: dibujar solo una vez por par
			if not esDirigido then
				if vistosND[key] then continue end
				vistosND[key] = true
			end

			local posA = E.posicionesNodos[nomA]
			local posB = E.posicionesNodos[nomB]
			if not posA or not posB then continue end

			local dist = (posA - posB).Magnitude
			if dist < 0.1 then continue end

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

			-- Para grafos dirigidos: desplazar ligeramente el cilindro del lado
			-- de la dirección para que A→B y B→A sean visualmente distintos.
			local posACil, posBCil = posA, posB
			if esDirigido then
				local dir    = (posB - posA)
				local perpXZ = Vector3.new(-dir.Z, 0, dir.X).Unit * (C.TAM_ARISTA * 0.8)
				posACil = posA + perpXZ
				posBCil = posB + perpXZ
			end

			local centro = (posACil + posBCil) / 2
			local arista = Instance.new("Part")
			arista.Name        = "AristaANA"
			arista.Anchored    = true
			arista.CanCollide  = false
			arista.CastShadow  = false
			arista.Material    = mat
			arista.Size        = Vector3.new(C.TAM_ARISTA, C.TAM_ARISTA, dist)
			arista.CFrame      = CFrame.lookAt(centro, posBCil)
			arista.Color       = color
			arista.Transparency = alpha
			arista.Parent      = E.worldModel

			table.insert(E.aristaParts, arista)

			-- Registrar qué IDs necesitan partículas en este paso
			if esNueva or esRecorrida then
				local id = esDirigido
					and (nomA .. "_>" .. nomB)
					or  idConexion(nomA, nomB)
				nuevoSetPart[id] = { nomA = nomA, nomB = nomB, posA = posA, posB = posB }
			end
		end
	end

	-- 6. Sincronización de partículas: SOLO toca lo que cambia
	--    a) Detener IDs que ya no deben estar activos
	for id in pairs(E.partActivas) do
		if not nuevoSetPart[id] then
			detenerParticulasId(id)
		end
	end
	--    b) Iniciar SOLO los IDs genuinamente nuevos (no existían antes)
	for id, info in pairs(nuevoSetPart) do
		if not E.partActivas[id] then
			iniciarParticulasArista(id, info.nomA, info.nomB, info.posA, info.posB, esDirigido)
		end
	end
end

return ViewportAnalisis