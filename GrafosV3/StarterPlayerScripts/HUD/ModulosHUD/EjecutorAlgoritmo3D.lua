-- EjecutorAlgoritmo3D.lua
-- Orquesta la simulación de algoritmos directamente sobre los nodos 3D del workspace.
-- Soporta modo automático (auto‑play) con validación guiada de conexiones reales.
-- Integra el PanelAlgoritmo3D para mostrar información y mensajes contextuales.

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RS           = game:GetService("ReplicatedStorage")

local AlgoritmosGrafo    = require(script.Parent.AlgoritmosGrafo)
local LevelsConfig       = require(RS:WaitForChild("Config"):WaitForChild("LevelsConfig"))
local PresetTween        = require(RS:WaitForChild("Efectos"):WaitForChild("PresetTween"))
local BillboardNombres   = require(RS:WaitForChild("Efectos"):WaitForChild("BillboardNombres"))
local SelectorAlgUI      = require(script.Parent.SelectorAlgUI)
local PanelAlgoritmo3D   = require(script.Parent.PanelAlgoritmo3D)
local GrafoHelpers       = require(RS:WaitForChild("Compartido"):WaitForChild("GrafoHelpers"))
local COLORES            = AlgoritmosGrafo.COLORES
local EfectosHighlight   = require(RS:WaitForChild("Efectos"):WaitForChild("EfectosHighlight"))
local GestorEfectos      = require(script.Parent.Parent.Parent:WaitForChild("SistemasGameplay"):WaitForChild("GestorEfectos"))
local OrquestadorModos   = require(script.Parent.Parent.Parent:WaitForChild("SistemasGameplay"):WaitForChild("OrquestadorModos"))
local EstadoConexiones   = require(script.Parent:WaitForChild("EstadoConexiones"))

local jugador = Players.LocalPlayer

-- Remotes
local ConectarDesdeMapa = RS:WaitForChild("EventosGrafosV3"):WaitForChild("Remotos"):FindFirstChild("ConectarDesdeMapa")
if not ConectarDesdeMapa then
	warn("[EjecutorAlgoritmo3D] ConectarDesdeMapa no encontrado — no se podrá desconectar aristas incorrectas")
end

local GetAdjacencyMatrix = RS:WaitForChild("EventosGrafosV3"):WaitForChild("Remotos"):FindFirstChild("GetAdjacencyMatrix")
if not GetAdjacencyMatrix then
	warn("[EjecutorAlgoritmo3D] GetAdjacencyMatrix no encontrado — no se podrá validar aristas")
end

local EjecutorAlgoritmo3D = {}

-- ════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ════════════════════════════════════════════════════════════════
local VEL_PASO_SEGUNDOS = 1.5
local CACHE_TOPOLOGIA_SEG = 1.0
local _simVersion       = 0

local VEL_PART       = COLORES.PARTICULA.nueva.velocidad
local FREQ_PART      = COLORES.PARTICULA.nueva.frecuencia
local TAM_PART       = COLORES.PARTICULA.nueva.tamano
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

	aristaMap       = {},
	tagsArista      = {},
	partActivas     = {},

	hudGui          = nil,
	btnEjecutar     = nil,

	modoGuiado        = false,
	esperandoArista   = false,
	aristaEsperada    = nil,
	aristasProcesadas = {},

	ultimaTopologia     = nil,
	ultimaConsultaTime  = 0,
	guiaAristaActual    = nil,
	aristaDefectuosaKey = nil,
	billboardsEjecucion = {},
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
-- ADYACENCIAS Y ARISTAS
-- ════════════════════════════════════════════════════════════════
local function buildAdyacencias(data, soloValidas)
	-- Usar el set dinámico de defectuosos del servidor si viene en data.
	return GrafoHelpers.adjDesdeMatriz(data, not soloValidas, data)
end

local function existeArista(nomA, nomB)
	local lista = estado.adyacencias[nomA]
	if not lista then return false end
	for _, v in ipairs(lista) do
		if v == nomB then return true end
	end
	return false
end

local function claveArista(a, b)
	return GrafoHelpers.clavePar(a, b)
end

local function keyAristaMap(nomA, nomB)
	local esDirigido = estado.matrizData and estado.matrizData.EsDirigido or false
	return esDirigido and (nomA .. "->" .. nomB) or claveArista(nomA, nomB)
end

-- ════════════════════════════════════════════════════════════════
-- ETIQUETAS DE PESO/COSTO
-- ════════════════════════════════════════════════════════════════
local function crearTagArista(nomA, nomB, part)
	if not part then return end
	local key = claveArista(nomA, nomB)
	if estado.tagsArista[key] then return end
	local peso = GrafoHelpers.obtenerPeso(estado.nivelID, nomA, nomB, 0)
	if not peso or peso <= 0 then return end
	local cfg   = LevelsConfig[estado.nivelID] or {}
	local costo = GrafoHelpers.calcularCosto(peso, cfg.CostoPorMetro or 500)
	local texto = "Peso: " .. peso .. " | Costo: " .. GrafoHelpers.formatearDinero(costo)
	local bb = BillboardNombres.crear(
		part,
		texto,
		"CABLE_COSTO",
		"TagPesoArista_" .. key,
		{ tamano = UDim2.new(0, 220, 0, 22) }
	)
	estado.tagsArista[key] = bb
end

local function destruirTagsArista()
	for key, tag in pairs(estado.tagsArista) do
		if tag and tag.Parent then tag:Destroy() end
		estado.tagsArista[key] = nil
	end
end

-- ════════════════════════════════════════════════════════════════
-- BILLBOARDS DE GUÍA (nodo inicio / destino en modo guiado)
-- ════════════════════════════════════════════════════════════════
local function destruirBillboardsGuia()
	BillboardNombres.destruirPorPrefijo("AlgGuia_BB_NodoInicio_")
	BillboardNombres.destruirPorPrefijo("AlgGuia_BB_NodoDestino_")
end

local function crearBillboardsGuia(nomA, nomB)
	destruirBillboardsGuia()

	local selA = obtenerSelector(buscarNodoWorkspace(nomA))
	local selB = obtenerSelector(buscarNodoWorkspace(nomB))

	if selA then
		local colInicio = COLORES.NODO.inicio.color
		BillboardNombres.crear(selA, "INICIO", "NODO_GUIA", "AlgGuia_BB_NodoInicio_" .. nomA, {
			colorTexto = colInicio,
			colorBorde = colInicio,
			textoFlecha = "▲",
		})
	end

	if selB then
		local colDestino = COLORES.NODO.destino.color
		BillboardNombres.crear(selB, "DESTINO", "NODO_GUIA", "AlgGuia_BB_NodoDestino_" .. nomB, {
			colorTexto = colDestino,
			colorBorde = colDestino,
		})
	end
end

local function actualizarBillboardsGuia(aristaEsperada)
	if not aristaEsperada then
		if estado.guiaAristaActual then
			destruirBillboardsGuia()
			estado.guiaAristaActual = nil
		end
		return
	end

	local key = aristaEsperada[1] .. "->" .. aristaEsperada[2]
	if estado.guiaAristaActual == key then return end

	estado.guiaAristaActual = key
	crearBillboardsGuia(aristaEsperada[1], aristaEsperada[2])
end

-- ════════════════════════════════════════════════════════════════
-- BILLBOARDS DE EJECUCIÓN VISUAL (modo no guiado)
-- ════════════════════════════════════════════════════════════════
local function limpiarBillboardsEjecucion()
	for _, key in ipairs(estado.billboardsEjecucion) do
		BillboardNombres.destruir(key)
	end
	estado.billboardsEjecucion = {}
end

local function crearBillboardNodoActual(nombre)
	limpiarBillboardsEjecucion()
	local sel = obtenerSelector(buscarNodoWorkspace(nombre))
	if not sel then return end
	local alias = PanelAlgoritmo3D.getAlias(nombre) or nombre
	local key = "AlgEjec_BB_NodoActual_" .. nombre
	local colActual = COLORES.NODO.actual.color
	BillboardNombres.crear(sel, "Visitando nodo\n" .. alias, "NODO_GUIA", key, {
		colorTexto = colActual,
		colorBorde = colActual,
		textoFlecha = "▼",
	})
	table.insert(estado.billboardsEjecucion, key)
end

local function colorCapaBFS(capa, capaMaxima)
	local profundidad = capaMaxima > 0 and (capa / capaMaxima) or 0
	local tono = profundidad * 0.75 -- rojo → naranja → amarillo → verde → azul → violeta
	local luminosidad = 1 - (profundidad * 0.45)
	return Color3.fromHSV(tono, 0.85, luminosidad)
end

local function crearBillboardsResultadoRecorrido(step)
	local algoritmo = estado.algoritmoActual
	if algoritmo ~= "bfs" and algoritmo ~= "dfs" then return end
	if not step then return end

	limpiarBillboardsEjecucion()

	local capaMaxima = 0
	if algoritmo == "bfs" then
		for _, capa in pairs(step.distancias or {}) do
			if typeof(capa) == "number" and capa > capaMaxima then
				capaMaxima = capa
			end
		end
	end

	local ordenDFS = {}
	if algoritmo == "dfs" then
		for posicion, nombre in ipairs(step.visitados or {}) do
			ordenDFS[nombre] = posicion
		end
	end

	local headers = estado.matrizData and estado.matrizData.Headers or {}
	for _, nombre in ipairs(headers) do
		local sel = obtenerSelector(buscarNodoWorkspace(nombre))
		if sel then
			local texto
			local color

			if algoritmo == "bfs" then
				local capa = step.distancias and step.distancias[nombre]
				if typeof(capa) == "number" then
					texto = "Capa BFS: " .. tostring(capa)
					color = colorCapaBFS(capa, capaMaxima)
				else
					texto = "Sin alcanzar"
					color = COLORES.NODO.no_usado.color
				end
			else
				local posicion = ordenDFS[nombre]
				if posicion then
					texto = "Salida DFS: " .. tostring(posicion)
					color = COLORES.NODO.visitado.color
				else
					texto = "Sin visitar"
					color = COLORES.NODO.no_usado.color
				end
			end

			local key = "AlgEjec_BB_Resultado_" .. algoritmo .. "_" .. nombre
			BillboardNombres.crear(sel, texto, "NODO_NIVEL", key, {
				colorTexto = Color3.new(1, 1, 1),
				colorBorde = color,
				grosorBorde = 3,
				transparenciaBorde = 0,
			})
			table.insert(estado.billboardsEjecucion, key)
		end
	end
end

local function marcarRutaCortaDijkstra(step)
	if estado.algoritmoActual ~= "dijkstra" then return end
	if not step or not step.aristasRecorridas or #step.aristasRecorridas == 0 then return end

	limpiarBillboardsEjecucion()
	local setNodos = {}
	for _, arista in ipairs(step.aristasRecorridas) do
		setNodos[arista[1]] = true
		setNodos[arista[2]] = true
	end
	for nombre in pairs(setNodos) do
		local sel = obtenerSelector(buscarNodoWorkspace(nombre))
		if sel then
			local alias = PanelAlgoritmo3D.getAlias(nombre) or nombre
			local key = "AlgEjec_BB_RutaCorta_" .. nombre
			local colCamino = COLORES.NODO.camino_final.color
			BillboardNombres.crear(sel, "Ruta más corta\n" .. alias, "NODO_GUIA", key, {
				colorTexto = colCamino,
				colorBorde = colCamino,
				textoFlecha = "★",
			})
			table.insert(estado.billboardsEjecucion, key)
		end
	end
end

local function ocultarBillboardAristaDefectuosa()
	if estado.aristaDefectuosaKey then
		BillboardNombres.destruir(estado.aristaDefectuosaKey)
		estado.aristaDefectuosaKey = nil
	end
end

local function mostrarBillboardAristaDefectuosa(nomA, nomB)
	local mapKey = keyAristaMap(nomA, nomB)
	local info = estado.aristaMap[mapKey]
	if not info or not info.part then
		ocultarBillboardAristaDefectuosa()
		return
	end

	local key = "AlgGuia_BB_AristaDefectuosa_" .. mapKey
	if estado.aristaDefectuosaKey == key then return end

	ocultarBillboardAristaDefectuosa()
	BillboardNombres.crear(info.part, "⚠️ DEFECTUOSO", "ARISTA_DANIADA", key)
	estado.aristaDefectuosaKey = key
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
-- NODOS (efectos 3D)
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

local function encenderNodo(nombre, tipoColor, distancia)
	local sel = obtenerSelector(buscarNodoWorkspace(nombre))
	if not sel or not sel:IsA("BasePart") then return 0 end
	guardarEstadoOriginal(sel, nombre)
	estado.nodosEncendidos[nombre] = true

	local cfg = COLORES.NODO[tipoColor] or COLORES.NODO.visitado
	sel.Material = cfg.material
	TweenService:Create(sel, TWEEN_NODO, {
		Color = cfg.color,
		Transparency = cfg.transparencia,
	}):Play()

	local previa = sel:FindFirstChild(ID_LUZ_PREFIX .. nombre)
	if previa then previa:Destroy() end

	local brillo, rango = cfg.brillo, cfg.rango
	if brillo > 0 then
		-- En BFS, los nodos más lejanos del origen brillan menos para leer la "ola".
		if tipoColor == "visitado" and typeof(distancia) == "number" and distancia > 0 then
			local factor = math.max(0.35, 1 - distancia * 0.15)
			brillo = brillo * factor
			rango  = rango  * factor
		end
		local luz = Instance.new("PointLight")
		luz.Name = ID_LUZ_PREFIX .. nombre
		luz.Color = cfg.color
		luz.Brightness = 0
		luz.Range = 0
		luz.Parent = sel
		estado.lucesTemporales[nombre] = luz
		TweenService:Create(luz, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Brightness = brillo, Range = rango }):Play()
	end

	return 0.5
end

-- ════════════════════════════════════════════════════════════════
-- PARTÍCULAS
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
				spawnParticula(posA, posB, COLORES.PARTICULA.nueva.color)
				task.wait(FREQ_PART)
			end
		end)
	end
	if not esDirigido or dirBA then
		local v = version
		task.spawn(function()
			task.wait(FREQ_PART / 2)
			while estado.partActivas[id] == v do
				spawnParticula(posB, posA, COLORES.PARTICULA.recorrida.color)
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
-- CONSTRUIR / ACTUALIZAR ARISTAS 3D
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
			local key = claveArista(nomA, nomB)
			if not esDirigido then
				if vistosND[key] then continue end
				vistosND[key] = true
			end

			local posA = buscarPosNodo(nomA)
			local posB = buscarPosNodo(nomB)
			if not posA or not posB then continue end

			local dist = (posA - posB).Magnitude
			if dist < 0.1 then continue end

			local esDefectuosa = false
			local setDinamico = estado.matrizData and estado.matrizData.Defectuosos
			if setDinamico then
				esDefectuosa = GrafoHelpers.esCableDefectuoso(setDinamico, nomA, nomB)
			end

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
			part.CanQuery   = false
			part.Size         = Vector3.new(dist, TAM_ARISTA, TAM_ARISTA)
			part.CFrame       = CFrame.fromMatrix(centro, ejeX, ejeY, ejeZ)

			local cfg = esDefectuosa and COLORES.ARISTA.defectuosa or COLORES.ARISTA.sin_explorar
			part.Material     = cfg.material
			part.Color        = cfg.color
			part.Transparency = 1
			part.Parent       = parentFolder

			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Cylinder
			mesh.Scale    = Vector3.new(1, 1, 1)
			mesh.Parent   = part

			TweenService:Create(part, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Transparency = cfg.transparencia }):Play()

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

end

local function asignarRolAristas(step)
	local roles = {}
	if not step then return roles end

	-- Prioridad: nueva > recorrida > candidata > sin_explorar
	for _, arista in ipairs(step.aristasCandidatas or {}) do
		local key = claveArista(arista[1], arista[2])
		if not roles[key] then
			roles[key] = "candidata"
		end
	end

	for _, arista in ipairs(step.aristasRecorridas or {}) do
		local key = claveArista(arista[1], arista[2])
		roles[key] = "recorrida"
	end

	if step.aristaNueva then
		local key = claveArista(step.aristaNueva[1], step.aristaNueva[2])
		roles[key] = "nueva"
	end

	return roles
end

local function aplicarEstiloArista(info, rol)
	local cfg = COLORES.ARISTA[rol] or COLORES.ARISTA.sin_explorar
	local part = info.part
	if not part or not part.Parent then return end

	part.Material = cfg.material
	TweenService:Create(part, TWEEN_ARISTA, {
		Color        = cfg.color,
		Transparency = cfg.transparencia,
	}):Play()
end

local function actualizarAristas(step)
	if not estado.matrizData then return 0 end
	local esDirigido = estado.matrizData.EsDirigido or false

	local roles = asignarRolAristas(step)
	local nuevoSetPart = {}

	for mapKey, info in pairs(estado.aristaMap) do
		if info.esDefectuosa then continue end

		local key = claveArista(info.nomA, info.nomB)
		local rol = roles[key] or "sin_explorar"
		local rolPrevio = estado.aristasProcesadas[key]

		if rolPrevio ~= rol then
			aplicarEstiloArista(info, rol)
			estado.aristasProcesadas[key] = rol

			if rol == "recorrida" or rol == "camino_final" then
				crearTagArista(info.nomA, info.nomB, info.part)
			end
		end

		-- Animación de backtrack en DFS: arista "cierra" brevemente antes de consolidarse
		if estado.algoritmoActual == "dfs" and step.esBacktrack and step.nodoActual then
			local u = step.nodoActual
			if (info.nomA == u or info.nomB == u) and rol == "recorrida" then
				aplicarEstiloArista(info, "sin_explorar")
				task.delay(0.25, function()
					if info.part and info.part.Parent then
						aplicarEstiloArista(info, "recorrida")
					end
				end)
			end
		end

		-- Partículas solo para aristas activas en el árbol/camino
		if rol == "nueva" or rol == "recorrida" or rol == "camino_final" then
			local pid = esDirigido and (info.nomA .. "_>" .. info.nomB) or idConexion(info.nomA, info.nomB)
			nuevoSetPart[pid] = info
		end
	end

	for id in pairs(estado.partActivas) do
		if not nuevoSetPart[id] then detenerParticulasId(id) end
	end
	for id, info in pairs(nuevoSetPart) do
		if not estado.partActivas[id] then
			iniciarParticulasArista(id, info.nomA, info.nomB, info.posA, info.posB, esDirigido)
		end
	end

	return TWEEN_ARISTA.Time
end

-- ════════════════════════════════════════════════════════════════
-- LIMPIEZA
-- ════════════════════════════════════════════════════════════════
local function limpiarEfectos3D()
	estado.autoPlaying   = false
	estado.tareaAutoPlay = nil
	estado.modoGuiado    = false
	estado.esperandoArista = false
	estado.aristaEsperada  = nil

	for nombre in pairs(estado.nodosEncendidos) do restaurarNodo(nombre) end
	for _, luz in pairs(estado.lucesTemporales) do
		if luz and luz.Parent then luz:Destroy() end
	end
	estado.lucesTemporales = {}
	estado.nodosEncendidos = {}
	estado.originalNodos   = {}
	table.clear(estado.aristasProcesadas)

	for _, info in pairs(estado.aristaMap) do
		if info.part and info.part.Parent then info.part:Destroy() end
	end
	estado.aristaMap = {}

	destruirTagsArista()

	BillboardNombres.destruirPorPrefijo("AlgGuia_BB_")
	local todosHighlights = EfectosHighlight.obtenerTodos()
	local aEliminar = {}
	for nombre in pairs(todosHighlights) do
		if nombre:sub(1, #"AlgGuia_Nodo_") == "AlgGuia_Nodo_" then
			table.insert(aEliminar, nombre)
		end
	end
	for _, nombre in ipairs(aEliminar) do
		EfectosHighlight.destruir(nombre)
	end

	limpiarTodasParticulas()
	destruirBillboardsGuia()
	estado.guiaAristaActual = nil
	ocultarBillboardAristaDefectuosa()
	limpiarBillboardsEjecucion()
	PanelAlgoritmo3D.ocultar()
end

-- ════════════════════════════════════════════════════════════════
-- APLICAR PASO 3D
-- ════════════════════════════════════════════════════════════════
local function aplicarPaso3D(step)
	if not step then return 0 end

	local maxDuracion = 0
	local headers = estado.matrizData and estado.matrizData.Headers or {}

	local visitadosSet = {}
	for _, nome in ipairs(step.visitados or {}) do
		visitadosSet[nome] = true
	end

	local pendientesSet = {}
	for _, item in ipairs(step.pendientes or {}) do
		local nome = tostring(item):match("^(.-)=") or tostring(item)
		pendientesSet[nome] = true
	end

	for _, nome in ipairs(headers) do
		local tipoColor = nil
		local distancia = nil

		if nome == step.nodoActual then
			tipoColor = "actual"
		elseif nome == estado.nodoInicio then
			tipoColor = "inicio"
		elseif nome == estado.nodoFin and estado.algoritmoActual == "dijkstra" then
			tipoColor = "destino"
		elseif visitadosSet[nome] then
			tipoColor = "visitado"
		elseif pendientesSet[nome] then
			tipoColor = "en_estructura"
		end

		if estado.algoritmoActual == "bfs" and step.distancias then
			distancia = step.distancias[nome]
		end

		if tipoColor then
			local dur = encenderNodo(nome, tipoColor, distancia)
			if dur > maxDuracion then maxDuracion = dur end
		end
	end

	local durAristas = actualizarAristas(step)
	if durAristas > maxDuracion then maxDuracion = durAristas end

	if estado.algoritmoActual == "dijkstra" and estado.pasoActual == estado.totalPasos then
		local function destacarCaminoFinalDijkstra(s)
			if estado.algoritmoActual ~= "dijkstra" or not s then return end
			local aristas = s.aristasRecorridas or {}
			if #aristas == 0 then return end

			local caminoSet = {}
			local aristasCaminoSet = {}
			for _, arista in ipairs(aristas) do
				local a, b = arista[1], arista[2]
				caminoSet[a] = true; caminoSet[b] = true
				aristasCaminoSet[claveArista(a, b)] = true
			end

			-- Atenuar nodos y aristas que no forman parte del camino óptimo
			for nombre in pairs(estado.nodosEncendidos) do
				if not caminoSet[nombre] then
					encenderNodo(nombre, "no_usado")
				end
			end
			for nombre in pairs(caminoSet) do
				encenderNodo(nombre, "camino_final")
			end

			for _, info in pairs(estado.aristaMap) do
				if info.part and info.part.Parent and not info.esDefectuosa then
					local key = claveArista(info.nomA, info.nomB)
					if aristasCaminoSet[key] then
						estado.aristasProcesadas[key] = "camino_final"
						aplicarEstiloArista(info, "camino_final")
					else
						estado.aristasProcesadas[key] = "no_usado"
						aplicarEstiloArista(info, "no_usado")
					end
				end
			end
			limpiarTodasParticulas()
		end
		destacarCaminoFinalDijkstra(step)
	end

	if estado.pasoActual == estado.totalPasos then
		crearBillboardsResultadoRecorrido(step)
	end

	PanelAlgoritmo3D.aplicarPaso(step, estado.pasoActual, estado.totalPasos)
	return maxDuracion
end

-- ════════════════════════════════════════════════════════════════
-- CONSULTA DE TOPOLOGÍA REAL
-- ════════════════════════════════════════════════════════════════
local function consultarTopologiaReal()
	if not GetAdjacencyMatrix then
		warn("[EjecutorAlgoritmo3D] GetAdjacencyMatrix no disponible")
		return { conectada = false, aristaDefectuosa = false, nodosDaniados = {} }
	end
	local ahora = tick()
	if estado.ultimaTopologia and (ahora - estado.ultimaConsultaTime) < CACHE_TOPOLOGIA_SEG then
		return estado.ultimaTopologia
	end

	local zona = estado.zonaAnclada or jugador:GetAttribute("ZonaActual") or ""
	local ok, realData = pcall(function() return GetAdjacencyMatrix:InvokeServer(zona) end)
	if not ok then
		warn("[EjecutorAlgoritmo3D] Error al consultar topología:", tostring(realData))
		return { conectada = false, aristaDefectuosa = false, nodosDaniados = {} }
	end
	if not realData or realData.SinZona then
		warn("[EjecutorAlgoritmo3D] Topología sin zona:", zona)
		return { conectada = false, aristaDefectuosa = false, nodosDaniados = {} }
	end

	local resultado = {
		Headers = realData.Headers or {},
		Matrix = realData.Matrix or {},
		NodosDaniados = realData.NodosDaniados or {},
		Defectuosos = realData.Defectuosos or {},
	}
	estado.ultimaTopologia = resultado
	estado.ultimaConsultaTime = tick()
	return resultado
end

local function verificarAristaEnTopologia(topologia, nomA, nomB)
	local headers = topologia.Headers or {}
	local matrix  = topologia.Matrix or {}
	local idxA, idxB = nil, nil
	for i, h in ipairs(headers) do
		if h == nomA then idxA = i end
		if h == nomB then idxB = i end
	end
	if not idxA or not idxB then
		warn("[EjecutorAlgoritmo3D] Arista no encontrada en headers:", nomA, nomB)
		return false
	end
	local valAB = matrix[idxA] and matrix[idxA][idxB]
	local valBA = matrix[idxB] and matrix[idxB][idxA]
	local conectada = (valAB and valAB > 0) or (valBA and valBA > 0)
	if not conectada then return false end
	-- Usar el set dinámico de la topología real (refleja destrucciones/reconexiones)
	local fuenteDefectuosos = topologia.Defectuosos or (estado.matrizData and estado.matrizData.Defectuosos) or nil
	local defectuosa = GrafoHelpers.esCableDefectuoso(fuenteDefectuosos or estado.nivelID, nomA, nomB)
	return true, defectuosa
end

local function invalidarCacheTopologia()
	estado.ultimaTopologia = nil
	estado.ultimaConsultaTime = 0
end

-- ════════════════════════════════════════════════════════════════
-- MODO AUTO‑PLAY CON VALIDACIÓN GUIADA
-- ════════════════════════════════════════════════════════════════
local function aristaPerteneceSolucionFinal(arista)
	if estado.algoritmoActual ~= "prim" and estado.algoritmoActual ~= "dijkstra" then
		return true
	end

	local pasoFinal = estado.pasos[estado.totalPasos]
	if not pasoFinal then return false end

	local keyBuscada = claveArista(arista[1], arista[2])
	for _, aristaFinal in ipairs(pasoFinal.aristasRecorridas or {}) do
		if claveArista(aristaFinal[1], aristaFinal[2]) == keyBuscada then
			return true
		end
	end
	return false
end

local function obtenerAristaEsperadaDelPaso(step)
	if step and step.aristaNueva then
		local arista = { step.aristaNueva[1], step.aristaNueva[2] }

		-- En guiado, Dijkstra solo solicita el camino mínimo final y Prim
		-- únicamente las aristas que quedaron en el árbol de expansión mínimo.
		-- Los pasos exploratorios se siguen mostrando, pero no exigen conexión.
		if aristaPerteneceSolucionFinal(arista) then
			return arista
		end
	end
	return nil
end

local function iniciarValidacionGuiada()
	if estado.autoPlaying then return end
	if estado.totalPasos == 0 then return end
	estado.autoPlaying = true
	estado.guiaAristaActual = nil
	if estado.btnEjecutar then estado.btnEjecutar.Text = "Validando conexiones" end

	local miVersion = _simVersion

	estado.tareaAutoPlay = task.spawn(function()
		while estado.autoPlaying and estado.pasoActual <= estado.totalPasos and _simVersion == miVersion do
			local step = estado.pasos[estado.pasoActual]

			aplicarPaso3D(step)

			-- ====== VERIFICAR NODO ACTUAL ======
			if step.nodoActual then
				while estado.autoPlaying and _simVersion == miVersion and PanelAlgoritmo3D.nodoEstaDaniado(step.nodoActual) do
					local selector = obtenerSelector(buscarNodoWorkspace(step.nodoActual))
					PanelAlgoritmo3D.mostrarMensajeNodoDaniado(step.nodoActual, selector)
					local topologia = consultarTopologiaReal()
					estado.nodosDaniados = topologia.NodosDaniados or {}
					PanelAlgoritmo3D.actualizarNodosDaniados(estado.nodosDaniados)
					PanelAlgoritmo3D.aplicarPaso(step, estado.pasoActual, estado.totalPasos)
					task.wait(0.5)
				end
				if not estado.autoPlaying or _simVersion ~= miVersion then break end
			end
			-- Nodo actual ya reparado: permitir que el panel refleje el paso
			PanelAlgoritmo3D.desactivarModoEspera()

			-- ====== VERIFICAR ARISTA ESPERADA ======
			local aristaEsperada = obtenerAristaEsperadaDelPaso(step)
			actualizarBillboardsGuia(aristaEsperada)

			if aristaEsperada then
				local avanzo = false
				local a, b = aristaEsperada[1], aristaEsperada[2]

				while estado.autoPlaying and _simVersion == miVersion and not avanzo do
					local topologia = consultarTopologiaReal()
					estado.nodosDaniados = topologia.NodosDaniados or {}
					PanelAlgoritmo3D.actualizarNodosDaniados(estado.nodosDaniados)
					PanelAlgoritmo3D.aplicarPaso(step, estado.pasoActual, estado.totalPasos)

					-- Verificar si alguno de los dos nodos está dañado (usando el panel que considera reparaciones)
					local nodoDanado = nil
					if PanelAlgoritmo3D.nodoEstaDaniado(a) then
						nodoDanado = a
					elseif PanelAlgoritmo3D.nodoEstaDaniado(b) then
						nodoDanado = b
					end

					if nodoDanado then
						local selector = obtenerSelector(buscarNodoWorkspace(nodoDanado))
						PanelAlgoritmo3D.mostrarMensajeNodoDaniado(nodoDanado, selector)
						ocultarBillboardAristaDefectuosa()
					else
						-- Ambos nodos están bien: verificar la arista
						local conectada, defectuosa = verificarAristaEnTopologia(topologia, a, b)
						if conectada then
							if defectuosa then
								PanelAlgoritmo3D.mostrarMensajeDefectuoso(aristaEsperada)
								mostrarBillboardAristaDefectuosa(a, b)
							else
								PanelAlgoritmo3D.mostrarMensajeCorrecto(aristaEsperada)
								PanelAlgoritmo3D.repararArista(a, b)
								ocultarBillboardAristaDefectuosa()
								task.wait(1.2)
								avanzo = true
							end
						else
							PanelAlgoritmo3D.mostrarMensajeEspera(aristaEsperada)
							ocultarBillboardAristaDefectuosa()
						end
					end

					if not avanzo then task.wait(0.5) end
				end
			else
				-- Paso sin arista nueva: esperar y avanzar
				ocultarBillboardAristaDefectuosa()
				task.wait(math.max(VEL_PASO_SEGUNDOS, 0.5))
			end

			if not estado.autoPlaying or _simVersion ~= miVersion then break end
			estado.pasoActual = estado.pasoActual + 1
		end

		if estado.autoPlaying and _simVersion == miVersion and estado.pasoActual > estado.totalPasos then
			if estado.btnEjecutar then estado.btnEjecutar.Text = "Ejecutar Algoritmo" end
			estado.autoPlaying = false
			task.delay(3, function()
				if not estado.activo and not estado.autoPlaying and _simVersion == miVersion then
					limpiarEfectos3D()
					estado.activo = false
					estado.pasos = {}
					estado.pasoActual = 0
					estado.totalPasos = 0
					estado.zonaAnclada = nil
				end
			end)
		end
	end)
end

-- ════════════════════════════════════════════════════════════════
-- MODO EJECUCIÓN VISUAL (auto‑play sin validación de conexiones)
-- ════════════════════════════════════════════════════════════════
local function iniciarEjecucionVisual()
	if estado.autoPlaying then return end
	if estado.totalPasos == 0 then return end
	estado.autoPlaying = true
	estado.modoGuiado = false
	if estado.btnEjecutar then estado.btnEjecutar.Text = "Ejecutando visualización" end

	local miVersion = _simVersion

	estado.tareaAutoPlay = task.spawn(function()
		while estado.autoPlaying and estado.pasoActual <= estado.totalPasos and _simVersion == miVersion do
			local step = estado.pasos[estado.pasoActual]

			aplicarPaso3D(step)

			if step.nodoActual then
				crearBillboardNodoActual(step.nodoActual)
			end

			task.wait(math.max(VEL_PASO_SEGUNDOS, 1.0))

			if not estado.autoPlaying or _simVersion ~= miVersion then break end
			estado.pasoActual = estado.pasoActual + 1
		end

		if estado.autoPlaying and _simVersion == miVersion and estado.pasoActual > estado.totalPasos then
			local stepFinal = estado.pasos[estado.totalPasos]
			if estado.algoritmoActual == "dijkstra" and stepFinal then
				marcarRutaCortaDijkstra(stepFinal)
			end

			if estado.btnEjecutar then estado.btnEjecutar.Text = "Ejecutar Algoritmo" end
			estado.autoPlaying = false
			task.delay(4, function()
				if not estado.activo and not estado.autoPlaying and _simVersion == miVersion then
					limpiarEfectos3D()
					estado.activo = false
					estado.pasos = {}
					estado.pasoActual = 0
					estado.totalPasos = 0
					estado.zonaAnclada = nil
				end
			end)
		end
	end)
end

-- ════════════════════════════════════════════════════════════════
-- INICIAR SIMULACIÓN
-- ════════════════════════════════════════════════════════════════
local function iniciarSimulacion(algo)
	limpiarEfectos3D()
	_simVersion = _simVersion + 1
	local miVersion = _simVersion

	local zona = estado.zonaAnclada or jugador:GetAttribute("ZonaActual") or ""
	if zona == "" then
		warn("[EjecutorAlgoritmo3D] No hay zona anclada ni actual")
		return
	end
	if not estado.zonaAnclada then estado.zonaAnclada = zona end

	local nivelID = jugador:GetAttribute("CurrentLevelID") or 0
	estado.nivelID = nivelID
	local config = LevelsConfig[nivelID]
	local analisisCfg = config and config.AnalisisConfig and config.AnalisisConfig[zona] or nil

	local nodoInicio = analisisCfg and analisisCfg.nodoInicio or nil
	estado.nodoFin   = analisisCfg and analisisCfg.nodoFin or nil
	estado.algoritmoActual = algo

	local fn = getGrafoCompletoFunc()
	if not fn then
		warn("[EjecutorAlgoritmo3D] GetGrafoCompleto no disponible")
		return
	end

	task.spawn(function()
		local ok, datos = pcall(function() return fn:InvokeServer(zona) end)
		if _simVersion ~= miVersion then return end
		if not ok or not datos or datos.SinZona or #datos.Headers == 0 then
			warn("[EjecutorAlgoritmo3D] Sin datos para zona:", zona)
			return
		end

		estado.matrizData  = datos
		estado.adyacencias = buildAdyacencias(datos, false)

		local nodos = datos.Headers
		if not nodoInicio or not table.find(nodos, nodoInicio) then
			nodoInicio = nodos[1]
		end
		estado.nodoInicio = nodoInicio

		local fnAlgo = AlgoritmosGrafo[algo]
		if not fnAlgo then
			warn("[EjecutorAlgoritmo3D] Algoritmo desconocido:", algo)
			return
		end

		local function pesoArista(a, b)
			local peso = GrafoHelpers.obtenerPeso(estado.nivelID, a, b, 1)
			return peso > 0 and peso or math.huge
		end

		local pasos
		if algo == "dijkstra" then
			pasos = fnAlgo(nodos, estado.adyacencias, nodoInicio, pesoArista, estado.nodoFin)
		elseif algo == "prim" then
			pasos = fnAlgo(nodos, estado.adyacencias, nodoInicio, pesoArista)
		else
			pasos = fnAlgo(nodos, estado.adyacencias, nodoInicio)
		end

		estado.pasos      = pasos
		estado.totalPasos = #estado.pasos
		estado.pasoActual = 1
		estado.activo     = true

		print(string.format("[EjecutorAlgoritmo3D] %s desde '%s' — %d pasos sobre %d nodos (zona: %s)",
			algo:upper(), nodoInicio, estado.totalPasos, #nodos, zona))

		PanelAlgoritmo3D.mostrar(algo, nodoInicio, estado.nodoFin, estado.matrizData, estado.adyacencias)

		construirAristas()
		task.wait(0.8)  -- pausa para que el jugador vea la red

		if SelectorAlgUI.estaModoGuiado() then
			iniciarValidacionGuiada()
		else
			iniciarEjecucionVisual()
		end
	end)
end

-- ════════════════════════════════════════════════════════════════
-- SELECTOR DE ALGORITMOS (GUI)
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
		SelectorAlgUI.mostrar({})
	end
end

local function toggleSelector()
	if estado.activo or estado.autoPlaying or estado.modoGuiado then
		limpiarEfectos3D()
		estado.activo = false
		estado.pasos = {}
		estado.pasoActual = 0
		estado.totalPasos = 0
		estado.zonaAnclada = nil
		SelectorAlgUI.ocultar()
		if estado.btnEjecutar then estado.btnEjecutar.Text = "Ejecutar Algoritmo" end
		OrquestadorModos.setModo("visual")
		return
	end
	if SelectorAlgUI.estaVisible() then
		SelectorAlgUI.ocultar()
	else
		mostrarSelector()
	end
end

-- ════════════════════════════════════════════════════════════════
-- API PÚBLICA
-- ════════════════════════════════════════════════════════════════
function EjecutorAlgoritmo3D.inicializar(hudGui)
	estado.hudGui = hudGui

	estado.btnEjecutar = hudGui:FindFirstChild("BtnEjecutadorAlgoritmo", true)
	if not estado.btnEjecutar then
		warn("[EjecutorAlgoritmo3D] BtnEjecutadorAlgoritmo no encontrado")
	else
		estado.btnEjecutar.MouseButton1Click:Connect(toggleSelector)
	end

	SelectorAlgUI.inicializar(hudGui)
	PanelAlgoritmo3D.inicializar(hudGui)
	PanelAlgoritmo3D.setCerrarCallback(function()
		limpiarEfectos3D()
		PanelAlgoritmo3D.ocultar()
		estado.activo = false
		estado.pasos = {}
		estado.pasoActual = 0
		estado.totalPasos = 0
		estado.zonaAnclada = nil
		if estado.btnEjecutar then estado.btnEjecutar.Text = "Ejecutar Algoritmo" end
		OrquestadorModos.setModo("visual")
	end)
	SelectorAlgUI.conectarCerrar(function()
		SelectorAlgUI.ocultar()
	end)

	-- Escuchar conexiones/desconexiones
	GestorEfectos.registrar("ConexionCompletada", function(params)
		local nomA = params.arg1
		local nomB = params.arg2
		if type(nomA) == "string" and type(nomB) == "string" then
			invalidarCacheTopologia()

			-- Actualizar la parte 3D de esa arista si existe y era defectuosa
			local mapKey = keyAristaMap(nomA, nomB)
			local info = estado.aristaMap[mapKey]
			if info and info.part and info.part.Parent then
				-- Ya no es defectuosa: restaurar color y material por defecto
				info.esDefectuosa = false
				aplicarEstiloArista(info, "sin_explorar")
				-- Detener partículas si las había
				local pid = estado.matrizData and estado.matrizData.EsDirigido
					and (nomA .. "_>" .. nomB)
					or  idConexion(nomA, nomB)
				detenerParticulasId(pid)
			end
		end
	end)

	GestorEfectos.registrar("CableDesconectado", function(params)
		local nomA = params.arg1
		local nomB = params.arg2
		if type(nomA) == "string" and type(nomB) == "string" then
			invalidarCacheTopologia()

			-- Si la arista existe en el mapa, restaurarla al estado default
			local mapKey = keyAristaMap(nomA, nomB)
			local info = estado.aristaMap[mapKey]
			if info and info.part and info.part.Parent then
				aplicarEstiloArista(info, "sin_explorar")
				local pid = estado.matrizData and estado.matrizData.EsDirigido
					and (nomA .. "_>" .. nomB)
					or  idConexion(nomA, nomB)
				detenerParticulasId(pid)
			end
		end
	end)

	-- Escuchar reparación de nodos via GestorEfectos
	GestorEfectos.registrar("NodoReparado", function(params)
		local nombre = type(params.arg1) == "string" and params.arg1 or nil
		if nombre then
			PanelAlgoritmo3D.marcarNodoReparado(nombre)
			invalidarCacheTopologia()
		end
	end)

	local pillNames = {
		bfs = "PillBFS",
		dfs = "PillDFS",
		dijkstra = "PillDijkstra",
		prim = "PillPrim",
	}
	for algo, _ in pairs(pillNames) do
		SelectorAlgUI.conectarPill(algo, function()
			if estado.activo or estado.autoPlaying or estado.modoGuiado then
				limpiarEfectos3D()
				estado.activo = false
				estado.pasos = {}
				estado.pasoActual = 0
				estado.totalPasos = 0
			end
			estado.zonaAnclada = jugador:GetAttribute("ZonaActual") or ""
			SelectorAlgUI.ocultar()
			OrquestadorModos.setModo("algoritmo3d")
			iniciarSimulacion(algo)
		end)
	end

	jugador:GetAttributeChangedSignal("ZonaActual"):Connect(function()
		if estado.activo or estado.autoPlaying or estado.modoGuiado then return end
		if SelectorAlgUI.estaVisible() then
			mostrarSelector()
		end
	end)

	print("[EjecutorAlgoritmo3D] ===== INICIALIZADO =====")
	print("[EjecutorAlgoritmo3D] SelectorAlgUI cargado:", tostring(SelectorAlgUI ~= nil))
end

-- Registrarse en el orquestador de modos
OrquestadorModos.registrarModo("algoritmo3d", {
	activar = function() end,
	limpiar = function(modoDestino)
		if modoDestino == "mapa" then return end

		limpiarEfectos3D()
		PanelAlgoritmo3D.ocultar()
		estado.activo = false
		estado.pasos = {}
		estado.pasoActual = 0
		estado.totalPasos = 0
		estado.zonaAnclada = nil
		if estado.btnEjecutar then estado.btnEjecutar.Text = "Ejecución Algoritmica" end
	end,
})

function EjecutorAlgoritmo3D.limpiar()
	limpiarEfectos3D()
	estado.activo = false
	estado.pasos = {}
	estado.pasoActual = 0
	estado.totalPasos = 0
	estado.zonaAnclada = nil
	estado.matrizData = nil
	estado.adyacencias = {}
	estado.ultimaTopologia = nil
	estado.ultimaConsultaTime = 0
	if estado.btnEjecutar then estado.btnEjecutar.Text = "Ejecución Algoritmica" end
	OrquestadorModos.setModo("visual")
	SelectorAlgUI.ocultar()
	PanelAlgoritmo3D.ocultar()
end

return EjecutorAlgoritmo3D
