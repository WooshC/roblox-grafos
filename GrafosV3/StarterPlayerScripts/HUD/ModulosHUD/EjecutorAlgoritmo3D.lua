-- StarterPlayerScripts/HUD/ModulosHUD/EjecutorAlgoritmo3D.lua
-- Orquesta la simulacion de algoritmos directamente sobre los nodos 3D del workspace.
--
-- Aristas: se construyen UNA SOLA VEZ al iniciar la simulacion.
-- En cada paso solo se actualiza Color/Material/Transparency via tween.
-- Particulas: sistema de versiones identico a ViewportAnalisis (sin duplicados).

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RS           = game:GetService("ReplicatedStorage")

local AlgoritmosGrafo    = require(script.Parent.AlgoritmosGrafo)
local LevelsConfig       = require(RS:WaitForChild("Config"):WaitForChild("LevelsConfig"))
local PresetTween        = require(RS:WaitForChild("Efectos"):WaitForChild("PresetTween"))
local SelectorAlgUI      = require(script.Parent.SelectorAlgUI)
local ConstantesAnalisis = require(script.Parent.ModuloAnalisis.ConstantesAnalisis)

local jugador = Players.LocalPlayer

local EjecutorAlgoritmo3D = {}

-- ════════════════════════════════════════════════════════════════
-- CONFIGURACION
-- ════════════════════════════════════════════════════════════════
local VEL_PASO_SEGUNDOS = 1.5  -- tiempo base entre pasos (ahora respeta tambien la animacion)
local _simVersion       = 0

local COL_NODO = {
	INICIO   = ConstantesAnalisis.COL_ACTUAL,    -- naranja
	VISITADO = ConstantesAnalisis.COL_VISITADO,  -- verde
	ACTUAL   = ConstantesAnalisis.COL_ACTUAL,    -- naranja
}

local COL_ARISTA_DEFAULT = ConstantesAnalisis.COL_ARISTA_DEFAULT
local COL_ARISTA_VISIT   = ConstantesAnalisis.COL_ARISTA_VISIT
local COL_ARISTA_NUEVA   = ConstantesAnalisis.COL_ARISTA_NUEVA
local COL_ARISTA_DEFECT  = Color3.fromRGB(200, 50, 50)

local ALPHA_DEFAULT = 0.55
local ALPHA_ACTIVA  = 0.0
local MAT_DEFAULT   = Enum.Material.SmoothPlastic
local MAT_NEON      = Enum.Material.Neon

local COL_PART_NUEVA = ConstantesAnalisis.COL_PART_NUEVA
local COL_PART_VISIT = ConstantesAnalisis.COL_PART_VISIT
local VEL_PART       = 40
local FREQ_PART      = 0.55
local TAM_PART       = 2.0
local TAM_ARISTA     = 0.5

local TWEEN_ARISTA = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_NODO   = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local ID_LUZ_PREFIX = "EjecAlg_Luz_"

-- ════════════════════════════════════════════════════════════════
-- ESTADO INTERNO
-- ════════════════════════════════════════════════════════════════
local estado = {
	activo          = false,
	pasos           = {},
	pasoActual      = 0,
	totalPasos      = 0,
	autoPlaying     = false,
	algoritmoActual = nil,
	zonaAnclada     = nil,
	nivelID         = nil,
	matrizData      = nil,
	adyacencias     = {},
	nodoInicio      = nil,
	nodoFin         = nil,
	tareaAutoPlay   = nil,

	originalNodos   = {},
	nodosEncendidos = {},
	lucesTemporales = {},

	-- aristaMap[key] = { part, esDefectuosa, nomA, nomB, posA, posB }
	-- Los cilindros se crean una vez y solo se tween su color/alpha
	aristaMap       = {},

	partActivas     = {},

	hudGui          = nil,
	btnEjecutar     = nil,
	selectorAlg     = nil,
	pills           = {},
}

-- ════════════════════════════════════════════════════════════════
-- WORKSPACE HELPERS
-- ════════════════════════════════════════════════════════════════
local function buscarNodoWorkspace(nombre)
	local nivel = workspace:FindFirstChild("NivelActual")
	if not nivel then return nil end
	local grafos = nivel:FindFirstChild("Grafos")
	if not grafos then return nil end
	for _, grafo in ipairs(grafos:GetChildren()) do
		local f = grafo:FindFirstChild("Nodos")
		if f then
			local m = f:FindFirstChild(nombre)
			if m then return m end
		end
	end
	return nil
end

local function obtenerSelector(nodoModelo)
	if not nodoModelo then return nil end
	local sel = nodoModelo:FindFirstChild("Selector")
	if not sel then return nil end
	if sel:IsA("BasePart") then return sel end
	if sel:IsA("Model") then
		return sel.PrimaryPart or sel:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

local function buscarPosNodo(nombre)
	local sel = obtenerSelector(buscarNodoWorkspace(nombre))
	return sel and sel.Position or nil
end

-- ════════════════════════════════════════════════════════════════
-- ADYACENCIAS
-- ════════════════════════════════════════════════════════════════
local function buildAdyacencias(data, soloValidas)
	local adj = {}
	local headers = data.Headers
	for i = 1, #headers do
		local nomA = headers[i]
		adj[nomA]  = adj[nomA] or {}
		local fila = data.Matrix[i]
		if fila then
			for j = 1, #headers do
				local val = fila[j] or 0
				if val > 0 then
					if soloValidas and val == 2 then continue end
					table.insert(adj[nomA], headers[j])
				end
			end
		end
	end
	return adj
end

local function existeArista(nomA, nomB)
	local lista = estado.adyacencias[nomA]
	if not lista then return false end
	for _, v in ipairs(lista) do
		if v == nomB then return true end
	end
	return false
end

-- ════════════════════════════════════════════════════════════════
-- REMOTE FUNCTION
-- ════════════════════════════════════════════════════════════════
local _grafoCompletoFunc = nil
local function getGrafoCompletoFunc()
	if _grafoCompletoFunc then return _grafoCompletoFunc end
	local ok, remote = pcall(function()
		return RS:WaitForChild("EventosGrafosV3", 10)
			:WaitForChild("Remotos", 5)
			:WaitForChild("GetGrafoCompleto", 5)
	end)
	if ok and remote then _grafoCompletoFunc = remote; return remote end
	warn("[EjecutorAlgoritmo3D] GetGrafoCompleto no encontrada")
	return nil
end

-- ════════════════════════════════════════════════════════════════
-- NODOS
-- ════════════════════════════════════════════════════════════════
local function guardarEstadoOriginal(sel, nombre)
	if estado.originalNodos[nombre] then return end
	if not sel or not sel:IsA("BasePart") then return end
	estado.originalNodos[nombre] = {
		Color        = sel.Color,
		Material     = sel.Material,
		Transparency = sel.Transparency,
		Size         = sel.Size,
	}
end

local function restaurarNodo(nombre)
	local orig = estado.originalNodos[nombre]
	if not orig then return end
	local sel = obtenerSelector(buscarNodoWorkspace(nombre))
	if not sel or not sel:IsA("BasePart") then return end
	sel.Material = orig.Material
	TweenService:Create(sel, TWEEN_NODO, {
		Color = orig.Color, Transparency = orig.Transparency, Size = orig.Size,
	}):Play()
end

local function encenderNodo(nombre, tipoColor)
	local sel = obtenerSelector(buscarNodoWorkspace(nombre))
	if not sel or not sel:IsA("BasePart") then return 0 end
	guardarEstadoOriginal(sel, nombre)
	estado.nodosEncendidos[nombre] = true

	local col  = COL_NODO[tipoColor] or COL_NODO.VISITADO
	local neon = (tipoColor == "ACTUAL" or tipoColor == "VISITADO" or tipoColor == "INICIO")
	if neon then sel.Material = PresetTween.MATERIALES.NEON end
	TweenService:Create(sel, TWEEN_NODO, {
		Color = col, Transparency = 0.15,
	}):Play()

	local previa = sel:FindFirstChild(ID_LUZ_PREFIX .. nombre)
	if previa then previa:Destroy() end
	local luz = Instance.new("PointLight")
	luz.Name = ID_LUZ_PREFIX .. nombre
	luz.Color = col; luz.Brightness = 0; luz.Range = 0; luz.Parent = sel
	estado.lucesTemporales[nombre] = luz
	TweenService:Create(luz, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Brightness = 6, Range = 24 }):Play()

	return 0.5  -- duracion maxima del tween de nodo/luz
end

-- ════════════════════════════════════════════════════════════════
-- PARTICULAS
-- ════════════════════════════════════════════════════════════════
local function spawnParticula(posA, posB, color)
	local dist = (posA - posB).Magnitude
	if dist < 0.1 then return end
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball; p.Anchored = true; p.CanCollide = false
	p.CastShadow = false; p.Material = Enum.Material.Neon
	p.Size = Vector3.new(TAM_PART, TAM_PART, TAM_PART)
	p.Color = color; p.Position = posA
	p.Parent = workspace:FindFirstChild("NivelActual") or workspace
	local tw = TweenService:Create(p,
		TweenInfo.new(dist / VEL_PART, Enum.EasingStyle.Linear), { Position = posB })
	tw.Completed:Connect(function() if p and p.Parent then p:Destroy() end end)
	tw:Play()
end

local function idConexion(nomA, nomB)
	return nomA < nomB and (nomA .. "_" .. nomB) or (nomB .. "_" .. nomA)
end

local function iniciarParticulasArista(id, nomA, nomB, posA, posB, esDirigido)
	local version = (estado.partActivas[id] or 0) + 1
	estado.partActivas[id] = version

	local dirAB = esDirigido and existeArista(nomA, nomB)
	local dirBA = esDirigido and existeArista(nomB, nomA)

	if not esDirigido or dirAB then
		local v = version
		task.spawn(function()
			while estado.partActivas[id] == v do
				spawnParticula(posA, posB, COL_PART_NUEVA)
				task.wait(FREQ_PART)
			end
		end)
	end
	if not esDirigido or dirBA then
		local v = version
		task.spawn(function()
			task.wait(FREQ_PART / 2)
			while estado.partActivas[id] == v do
				spawnParticula(posB, posA, COL_PART_VISIT)
				task.wait(FREQ_PART)
			end
		end)
	end
end

local function detenerParticulasId(id)
	if estado.partActivas[id] then
		estado.partActivas[id] = 0
		estado.partActivas[id] = nil
	end
end

local function limpiarTodasParticulas()
	for id in pairs(estado.partActivas) do estado.partActivas[id] = 0 end
	table.clear(estado.partActivas)
end

-- ════════════════════════════════════════════════════════════════
-- CONSTRUIR ARISTAS — una sola vez al iniciar
-- ════════════════════════════════════════════════════════════════
local function construirAristas()
	for _, info in pairs(estado.aristaMap) do
		if info.part and info.part.Parent then info.part:Destroy() end
	end
	estado.aristaMap = {}

	if not estado.matrizData then return end

	local parentFolder = workspace:FindFirstChild("NivelActual") or workspace
	local esDirigido   = estado.matrizData.EsDirigido or false
	local vistosND     = {}

	for nomA, lista in pairs(estado.adyacencias) do
		for _, nomB in ipairs(lista) do

			local key = nomA < nomB and (nomA .. "|" .. nomB) or (nomB .. "|" .. nomA)

			if not esDirigido then
				if vistosND[key] then continue end
				vistosND[key] = true
			end

			local posA = buscarPosNodo(nomA)
			local posB = buscarPosNodo(nomB)
			if not posA or not posB then continue end

			local dist = (posA - posB).Magnitude
			if dist < 0.1 then continue end

			local valMatrix = 0
			local idxA = table.find(estado.matrizData.Headers, nomA)
			local idxB = table.find(estado.matrizData.Headers, nomB)
			if idxA and idxB and estado.matrizData.Matrix[idxA] then
				valMatrix = estado.matrizData.Matrix[idxA][idxB] or 0
			end
			local esDefectuosa = (valMatrix == 2)

			local posACil, posBCil = posA, posB
			if esDirigido then
				local dir    = (posB - posA)
				local perpXZ = Vector3.new(-dir.Z, 0, dir.X).Unit * (TAM_ARISTA * 0.8)
				posACil = posA + perpXZ
				posBCil = posB + perpXZ
			end

			local centro = (posACil + posBCil) / 2
			local ejeX   = (posBCil - posACil).Unit
			local ejeY   = Vector3.new(0, 1, 0)
			if math.abs(ejeX:Dot(ejeY)) > 0.99 then ejeY = Vector3.new(1, 0, 0) end
			local ejeZ = ejeX:Cross(ejeY).Unit
			ejeY = ejeZ:Cross(ejeX).Unit

			local part = Instance.new("Part")
			part.Name         = "EjecAlg_Arista"
			part.Anchored     = true
			part.CanCollide   = false
			part.CastShadow   = false
			part.Size         = Vector3.new(dist, TAM_ARISTA, TAM_ARISTA)
			part.CFrame       = CFrame.fromMatrix(centro, ejeX, ejeY, ejeZ)
			part.Material     = esDefectuosa and MAT_NEON    or MAT_DEFAULT
			part.Color        = esDefectuosa and COL_ARISTA_DEFECT or COL_ARISTA_DEFAULT
			part.Transparency = 1           -- empieza invisible para aparecer con tween
			part.Parent       = parentFolder

			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Cylinder
			mesh.Scale    = Vector3.new(1, 1, 1)
			mesh.Parent   = part

			-- Aparecer gradualmente (no de golpe) para que la red no se construya instantaneamente
			local alphaFinal = esDefectuosa and ALPHA_ACTIVA or ALPHA_DEFAULT
			TweenService:Create(part, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Transparency = alphaFinal }):Play()

			local mapKey = esDirigido and (nomA .. "->" .. nomB) or key
			estado.aristaMap[mapKey] = {
				part         = part,
				esDefectuosa = esDefectuosa,
				nomA         = nomA,
				nomB         = nomB,
				posA         = posA,
				posB         = posB,
			}
		end
	end

	local count = 0
	for _ in pairs(estado.aristaMap) do count = count + 1 end
	print(string.format("[EjecutorAlgoritmo3D] %d aristas construidas", count))
end

-- ════════════════════════════════════════════════════════════════
-- ACTUALIZAR ARISTAS — solo tween color/alpha, SIN destruir/crear
-- ════════════════════════════════════════════════════════════════
local function actualizarAristas(step)
	if not estado.matrizData then return 0 end
	local esDirigido = estado.matrizData.EsDirigido or false

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

	local nuevoSetPart = {}

	for _, info in pairs(estado.aristaMap) do
		if info.esDefectuosa then continue end

		local nomA, nomB = info.nomA, info.nomB
		local key = nomA < nomB and (nomA .. "|" .. nomB) or (nomB .. "|" .. nomA)

		local esNueva     = (key == nuevaKey)
		local esRecorrida = recorridasSet[key] == true

		local color, alpha, mat
		if esNueva then
			color = COL_ARISTA_NUEVA; alpha = ALPHA_ACTIVA; mat = MAT_NEON
		elseif esRecorrida then
			color = COL_ARISTA_VISIT; alpha = ALPHA_ACTIVA; mat = MAT_NEON
		else
			color = COL_ARISTA_DEFAULT; alpha = ALPHA_DEFAULT; mat = MAT_DEFAULT
		end

		local part = info.part
		if part and part.Parent then
			part.Material = mat
			TweenService:Create(part, TWEEN_ARISTA, {
				Color        = color,
				Transparency = alpha,
			}):Play()
		end

		if esNueva or esRecorrida then
			local pid = esDirigido and (nomA .. "_>" .. nomB) or idConexion(nomA, nomB)
			nuevoSetPart[pid] = info
		end
	end

	-- Sincronizar particulas
	for id in pairs(estado.partActivas) do
		if not nuevoSetPart[id] then detenerParticulasId(id) end
	end
	for id, info in pairs(nuevoSetPart) do
		if not estado.partActivas[id] then
			iniciarParticulasArista(id, info.nomA, info.nomB, info.posA, info.posB, esDirigido)
		end
	end

	return TWEEN_ARISTA.Time  -- duracion de la animacion de aristas
end

local function resetearAristas()
	for _, info in pairs(estado.aristaMap) do
		if not info.esDefectuosa and info.part and info.part.Parent then
			info.part.Material = MAT_DEFAULT
			TweenService:Create(info.part, TWEEN_ARISTA, {
				Color        = COL_ARISTA_DEFAULT,
				Transparency = ALPHA_DEFAULT,
			}):Play()
		end
	end
	limpiarTodasParticulas()
end

-- ════════════════════════════════════════════════════════════════
-- LIMPIAR TODO
-- ════════════════════════════════════════════════════════════════
local function limpiarEfectos3D()
	estado.autoPlaying   = false
	estado.tareaAutoPlay = nil

	for nombre in pairs(estado.nodosEncendidos) do restaurarNodo(nombre) end
	for _, luz in pairs(estado.lucesTemporales) do
		if luz and luz.Parent then luz:Destroy() end
	end
	estado.lucesTemporales = {}
	estado.nodosEncendidos = {}
	estado.originalNodos   = {}

	for _, info in pairs(estado.aristaMap) do
		if info.part and info.part.Parent then info.part:Destroy() end
	end
	estado.aristaMap = {}

	limpiarTodasParticulas()
end

-- ════════════════════════════════════════════════════════════════
-- APLICAR PASO 3D
-- ════════════════════════════════════════════════════════════════
local function aplicarPaso3D(step)
	if not step then return 0 end

	local maxDuracion = 0
	local headers = estado.matrizData and estado.matrizData.Headers or {}
	for _, nome in ipairs(headers) do
		local dur = 0
		if nome == step.nodoActual then
			dur = encenderNodo(nome, "ACTUAL")
		elseif nome == estado.nodoInicio and not estado.nodosEncendidos[nome] then
			dur = encenderNodo(nome, "INICIO")
		elseif table.find(step.visitados or {}, nome) then
			dur = encenderNodo(nome, "VISITADO")
		end
		if dur > maxDuracion then maxDuracion = dur end
	end

	local durAristas = actualizarAristas(step)
	if durAristas > maxDuracion then maxDuracion = durAristas end

	return maxDuracion
end

-- ════════════════════════════════════════════════════════════════
-- AUTO-PLAY
-- ════════════════════════════════════════════════════════════════
local function detenerAutoPlay()
	estado.autoPlaying = false
	if estado.btnEjecutar then estado.btnEjecutar.Text = "Ejecutar Algoritmo" end
end

local function iniciarAutoPlay()
	if estado.autoPlaying then detenerAutoPlay(); return end
	if estado.totalPasos == 0 then return end
	estado.autoPlaying = true
	if estado.btnEjecutar then estado.btnEjecutar.Text = "Detener Algoritmo" end

	estado.tareaAutoPlay = task.spawn(function()
		if estado.pasoActual >= estado.totalPasos then
			estado.pasoActual = 1
			-- Reinicio: resetear aristas a gris y nodos a su color original
			resetearAristas()
			for nombre in pairs(estado.nodosEncendidos) do restaurarNodo(nombre) end
			for _, luz in pairs(estado.lucesTemporales) do
				if luz and luz.Parent then luz:Destroy() end
			end
			estado.lucesTemporales = {}
			estado.nodosEncendidos = {}
			estado.originalNodos   = {}
		end

		while estado.autoPlaying and estado.pasoActual <= estado.totalPasos do
			local durAnim = aplicarPaso3D(estado.pasos[estado.pasoActual])
			-- Esperamos lo que dure la animacion del paso o el tiempo base,
			-- lo que sea MAYOR, para que no se solapen pasos ni se vea todo de golpe.
			task.wait(math.max(VEL_PASO_SEGUNDOS, durAnim))
			if not estado.autoPlaying then break end
			estado.pasoActual = estado.pasoActual + 1
		end

		if estado.autoPlaying and estado.pasoActual > estado.totalPasos then
			if estado.btnEjecutar then estado.btnEjecutar.Text = "Ejecutar Algoritmo" end
			estado.autoPlaying = false
			-- Esperar 3 segundos para que el jugador vea el resultado final, luego limpiar todo
			task.delay(3, function()
				if not estado.activo and not estado.autoPlaying then
					limpiarEfectos3D()
					estado.activo = false; estado.pasos = {}
					estado.pasoActual = 0; estado.totalPasos = 0
					estado.zonaAnclada = nil
				end
			end)
		end
	end)
end

-- ════════════════════════════════════════════════════════════════
-- INICIAR SIMULACION
-- ════════════════════════════════════════════════════════════════
local function iniciarSimulacion(algo)
	limpiarEfectos3D()
	_simVersion = _simVersion + 1
	local miVersion = _simVersion

	local zona = estado.zonaAnclada or jugador:GetAttribute("ZonaActual") or ""
	if zona == "" then warn("[EjecutorAlgoritmo3D] No hay zona anclada ni actual"); return end
	if not estado.zonaAnclada then estado.zonaAnclada = zona end
	zona = estado.zonaAnclada

	local nivelID     = jugador:GetAttribute("CurrentLevelID") or 0
	local config      = LevelsConfig[nivelID]
	local analisisCfg = config and config.AnalisisConfig and config.AnalisisConfig[zona] or nil

	local nodoInicio       = analisisCfg and analisisCfg.nodoInicio or nil
	estado.nodoFin         = analisisCfg and analisisCfg.nodoFin or nil
	estado.algoritmoActual = algo

	local fn = getGrafoCompletoFunc()
	if not fn then warn("[EjecutorAlgoritmo3D] GetGrafoCompleto no disponible"); return end

	task.spawn(function()
		local ok, datos = pcall(function() return fn:InvokeServer(zona) end)
		if _simVersion ~= miVersion then return end
		if not ok or not datos or datos.SinZona or #datos.Headers == 0 then
			warn("[EjecutorAlgoritmo3D] Sin datos para zona:", zona); return
		end

		estado.matrizData  = datos
		estado.adyacencias = buildAdyacencias(datos, false)

		local nodos = datos.Headers
		if not nodoInicio or not table.find(nodos, nodoInicio) then
			nodoInicio = nodos[1]
		end
		estado.nodoInicio = nodoInicio

		local fnAlgo = AlgoritmosGrafo[algo]
		if not fnAlgo then warn("[EjecutorAlgoritmo3D] Algoritmo desconocido:", algo); return end

		estado.pasos      = fnAlgo(nodos, estado.adyacencias, nodoInicio)
		estado.totalPasos = #estado.pasos
		estado.pasoActual = 1
		estado.activo     = true

		print(string.format("[EjecutorAlgoritmo3D] %s desde '%s' — %d pasos sobre %d nodos (zona: %s)",
			algo:upper(), nodoInicio, estado.totalPasos, #nodos, zona))

		construirAristas()   -- una sola vez, con tween de aparicion
		task.wait(0.8)         -- pequena pausa para que el jugador vea la red formarse
		iniciarAutoPlay()
	end)
end

-- ════════════════════════════════════════════════════════════════
-- GUI (delegado a SelectorAlgUI)
-- ════════════════════════════════════════════════════════════════
local function mostrarSelector()
	local zona        = jugador:GetAttribute("ZonaActual") or ""
	local nivelID     = jugador:GetAttribute("CurrentLevelID") or 0
	local config      = LevelsConfig[nivelID]
	local analisisCfg = config and config.AnalisisConfig and config.AnalisisConfig[zona] or nil
	local algoritmos  = analisisCfg and analisisCfg.algoritmos
	if algoritmos and #algoritmos > 0 then
		SelectorAlgUI.mostrar(algoritmos)
	else
		SelectorAlgUI.mostrar({})  -- oculta todas las pills si la zona no tiene algoritmos
	end
end

local function toggleSelector()
	if estado.activo or estado.autoPlaying then
		limpiarEfectos3D()
		estado.activo = false; estado.pasos = {}
		estado.pasoActual = 0; estado.totalPasos = 0
		estado.zonaAnclada = nil
		SelectorAlgUI.ocultar()
		if estado.btnEjecutar then estado.btnEjecutar.Text = "Ejecutar Algoritmo" end
		return
	end
	if SelectorAlgUI.estaVisible() then
		SelectorAlgUI.ocultar()
	else
		mostrarSelector()
	end
end

-- ════════════════════════════════════════════════════════════════
-- API PUBLICA
-- ════════════════════════════════════════════════════════════════
function EjecutorAlgoritmo3D.inicializar(hudGui)
	estado.hudGui = hudGui

	estado.btnEjecutar = hudGui:FindFirstChild("BtnEjecutarAlg", true)
	if not estado.btnEjecutar then
		warn("[EjecutorAlgoritmo3D] BtnEjecutarAlg no encontrado")
	else
		estado.btnEjecutar.MouseButton1Click:Connect(toggleSelector)
	end

	-- Inicializar UI del selector (estilizado, animado, responsivo)
	SelectorAlgUI.inicializar(hudGui)
	SelectorAlgUI.conectarCerrar(function()
		SelectorAlgUI.ocultar()
	end)

	local pillNames = {
		bfs = "PillBFS", dfs = "PillDFS",
		dijkstra = "PillDijkstra", prim = "PillPrim",
	}
	for algo, _ in pairs(pillNames) do
		SelectorAlgUI.conectarPill(algo, function()
			if estado.activo or estado.autoPlaying then
				limpiarEfectos3D()
				estado.activo = false; estado.pasos = {}
				estado.pasoActual = 0; estado.totalPasos = 0
			end
			estado.zonaAnclada = jugador:GetAttribute("ZonaActual") or ""
			SelectorAlgUI.ocultar()
			iniciarSimulacion(algo)
		end)
	end

	-- Actualizar pills en tiempo real si el jugador cambia de zona mientras el selector esta abierto
	jugador:GetAttributeChangedSignal("ZonaActual"):Connect(function()
		if estado.activo or estado.autoPlaying then return end
		if SelectorAlgUI.estaVisible() then
			mostrarSelector()
		end
	end)

	print("[EjecutorAlgoritmo3D] ===== INICIALIZADO =====")
	print("[EjecutorAlgoritmo3D] SelectorAlgUI cargado:", tostring(SelectorAlgUI ~= nil))
end

function EjecutorAlgoritmo3D.limpiar()
	limpiarEfectos3D()
	estado.activo = false; estado.pasos = {}
	estado.pasoActual = 0; estado.totalPasos = 0
	estado.zonaAnclada = nil; estado.matrizData = nil
	estado.adyacencias = {}
	if estado.btnEjecutar then estado.btnEjecutar.Text = "Ejecutar Algoritmo" end
	SelectorAlgUI.ocultar()
end

return EjecutorAlgoritmo3D