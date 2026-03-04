-- StarterPlayerScripts/HUD/ModulosHUD/ModuloAnalisis.lua
-- Orquestador principal del Modo Análisis.
-- Sub-módulos (hijos de este ModuleScript en Studio):
--   EstadoAnalisis, ConstantesAnalisis, ViewportAnalisis,
--   PseudocodigoAnalisis, PanelEstadoAnalisis
--
-- API pública (sin cambios respecto a la versión anterior):
--   ModuloAnalisis.inicializar(hudGui)
--   ModuloAnalisis.configurarNivel(nivelModel, nivelID, configNivel)
--   ModuloAnalisis.abrir()
--   ModuloAnalisis.cerrar()
--   ModuloAnalisis.limpiar()
--   ModuloAnalisis.estaAbierto() -> bool

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")

-- Sub-módulos (hijos en Studio → script.<Nombre>)
local E                  = require(script.EstadoAnalisis)
local C                  = require(script.ConstantesAnalisis)
local ViewportAnalisis   = require(script.ViewportAnalisis)
local PseudocodigoAnalisis = require(script.PseudocodigoAnalisis)
local PanelEstadoAnalisis  = require(script.PanelEstadoAnalisis)

-- Sibling (en la misma carpeta ModulosHUD)
local AlgoritmosGrafo = require(script.Parent.AlgoritmosGrafo)

local jugador = Players.LocalPlayer

local ModuloAnalisis = {}

-- ════════════════════════════════════════════════════════════════
-- LAZY-GET RemoteFunction GetGrafoCompleto
-- ════════════════════════════════════════════════════════════════
local function getGrafoCompletoFunc()
	if E.grafoCompletoFunc then return E.grafoCompletoFunc end
	local ok, remote = pcall(function()
		return RS:WaitForChild("EventosGrafosV3", 10)
		          :WaitForChild("Remotos", 5)
		          :WaitForChild("GetGrafoCompleto", 5)
	end)
	if ok and remote then
		E.grafoCompletoFunc = remote
		return remote
	end
	warn("[ModuloAnalisis] GetGrafoCompleto no encontrada")
	return nil
end

-- ════════════════════════════════════════════════════════════════
-- CONSTRUIR ADYACENCIAS DESDE LA MATRIZ
-- ════════════════════════════════════════════════════════════════
local function buildAdyacencias(data)
	local adj     = {}
	local headers = data.Headers
	local n       = #headers
	for i = 1, n do
		local nomA = headers[i]
		adj[nomA]  = adj[nomA] or {}
		local fila = data.Matrix[i]
		if fila then
			for j = 1, n do
				if (fila[j] or 0) > 0 then
					table.insert(adj[nomA], headers[j])
				end
			end
		end
	end
	return adj
end

-- ════════════════════════════════════════════════════════════════
-- AUTO-PLAY
-- ════════════════════════════════════════════════════════════════
local function detenerAutoPlay()
	E.autoPlaying = false
	if E.btnEjecRef then E.btnEjecRef.Text = "▶ Ejecutar" end
end

local function iniciarAutoPlay()
	if E.autoPlaying then
		detenerAutoPlay()
		return
	end
	if E.totalPasos == 0 then return end

	E.autoPlaying = true
	if E.btnEjecRef then E.btnEjecRef.Text = "⏹ Parar" end

	task.spawn(function()
		if E.pasoActual >= E.totalPasos then
			E.pasoActual = 0
		end
		while E.autoPlaying and E.pasoActual < E.totalPasos do
			task.wait(C.VEL_AUTO)
			if not E.autoPlaying then break end
			E.pasoActual = E.pasoActual + 1
			PanelEstadoAnalisis.aplicarPaso(E.pasos[E.pasoActual])
		end
		detenerAutoPlay()
	end)
end

-- ════════════════════════════════════════════════════════════════
-- EJECUTAR ALGORITMO
-- ════════════════════════════════════════════════════════════════
local function ejecutarAlgoritmo()
	if not E.matrizData then return end

	detenerAutoPlay()

	local nodos = E.matrizData.Headers
	local fn    = AlgoritmosGrafo[E.algoActual]
	if not fn then
		warn("[ModuloAnalisis] Algoritmo desconocido:", E.algoActual)
		return
	end

	E.pasos      = fn(nodos, E.adyacencias, nodos[1])
	E.totalPasos = #E.pasos
	E.pasoActual = 1

	if E.totalPasos > 0 then
		PanelEstadoAnalisis.aplicarPaso(E.pasos[E.pasoActual])
	end

	print(string.format("[ModuloAnalisis] %s — %d pasos sobre %d nodos",
		E.algoActual:upper(), E.totalPasos, #nodos))
end

-- ════════════════════════════════════════════════════════════════
-- PILLS
-- ════════════════════════════════════════════════════════════════
local function seleccionarAlgo(algo)
	E.algoActual = algo
	PanelEstadoAnalisis.actualizarPills(algo)
	PseudocodigoAnalisis.reconstruirPseudocodigo(algo)
	if E.matrizData then ejecutarAlgoritmo() end
end

-- ════════════════════════════════════════════════════════════════
-- CARGAR GRAFO COMPLETO DESDE SERVIDOR
-- ════════════════════════════════════════════════════════════════
local function cargarGrafoCompleto(zona, onExito, onFallo)
	local fn = getGrafoCompletoFunc()
	if not fn then
		if onFallo then onFallo("GetGrafoCompleto no disponible") end
		return
	end
	task.spawn(function()
		local ok, datos = pcall(function() return fn:InvokeServer(zona) end)
		if ok and datos and not datos.SinZona and #datos.Headers > 0 then
			E.matrizData  = datos
			E.adyacencias = buildAdyacencias(datos)
			if onExito then onExito() end
		else
			if onFallo then onFallo("Sin datos para zona: " .. zona) end
		end
	end)
end

-- ════════════════════════════════════════════════════════════════
-- HELPER: limpiar estado visual sin destruir overlay
-- ════════════════════════════════════════════════════════════════
local function limpiarEstadoVisual()
	detenerAutoPlay()
	ViewportAnalisis.limpiarParticulas()
	for _, p in ipairs(E.aristaParts) do if p and p.Parent then p:Destroy() end end
	E.aristaParts = {}
	if E.worldModel then E.worldModel:ClearAllChildren() end
	E.nodoParts       = {}
	E.posicionesNodos = {}
	E.matrizData      = nil
	E.adyacencias     = {}
	E.pasos           = {}
	E.pasoActual      = 0
	E.totalPasos      = 0
end

-- ════════════════════════════════════════════════════════════════
-- API PÚBLICA
-- ════════════════════════════════════════════════════════════════

function ModuloAnalisis.inicializar(hudGui)
	E.hudGui = hudGui

	E.overlay = hudGui:FindFirstChild("OverlayAnalisis", true)
	if not E.overlay then
		warn("[ModuloAnalisis] OverlayAnalisis no encontrado en GUIExploradorV2")
		return
	end
	E.overlay.Visible = false

	-- ViewportFrame
	E.visor = C.buscar(E.overlay, "VisorGrafoAna")
	if E.visor then
		E.worldModel = E.visor:FindFirstChild("WorldModel")
		if not E.worldModel then
			E.worldModel        = Instance.new("WorldModel")
			E.worldModel.Parent = E.visor
		end

		E.camAnalisis = E.visor.CurrentCamera
		if not E.camAnalisis then
			E.camAnalisis             = Instance.new("Camera")
			E.camAnalisis.FieldOfView = 70
			E.camAnalisis.Parent      = E.visor
			E.visor.CurrentCamera     = E.camAnalisis
		end
	else
		warn("[ModuloAnalisis] VisorGrafoAna no encontrado")
	end

	-- Pills de algoritmo
	for algo, _ in pairs(PanelEstadoAnalisis.PILL_NAMES) do
		local pillName = PanelEstadoAnalisis.PILL_NAMES[algo]
		local pill = C.buscar(E.overlay, pillName)
		if pill then
			local a = algo
			pill.MouseButton1Click:Connect(function()
				seleccionarAlgo(a)
			end)
		end
	end

	-- BtnEjecutarAlgo → toggle auto-play
	local btnEjec = C.buscar(E.overlay, "BtnEjecutarAlgo")
	if btnEjec then
		E.btnEjecRef = btnEjec
		btnEjec.MouseButton1Click:Connect(function()
			if not E.abierto then return end
			if E.totalPasos == 0 then
				local zona = jugador:GetAttribute("ZonaActual") or ""
				if zona == "" then
					PanelEstadoAnalisis.mostrarMensajeDesc("Entra en una zona para analizar su grafo.")
					return
				end
				PanelEstadoAnalisis.mostrarMensajeDesc("Cargando datos…")
				cargarGrafoCompleto(zona,
					function()
						ViewportAnalisis.construirViewport()
						ejecutarAlgoritmo()
					end,
					function(msg)
						PanelEstadoAnalisis.mostrarMensajeDesc(msg)
					end
				)
			else
				iniciarAutoPlay()
			end
		end)
	end

	-- Botones cerrar
	local btnCerrar = C.buscar(E.overlay, "BtnCerrarAnalisis")
	if btnCerrar then
		btnCerrar.MouseButton1Click:Connect(function() ModuloAnalisis.cerrar() end)
	end
	local btnSalir = C.buscar(E.overlay, "BtnSalirAnalisis")
	if btnSalir then
		btnSalir.MouseButton1Click:Connect(function() ModuloAnalisis.cerrar() end)
	end

	-- BtnSiguiente
	local btnSig = C.buscar(E.overlay, "BtnSiguiente")
	if btnSig then
		btnSig.MouseButton1Click:Connect(function()
			if not E.abierto or E.totalPasos == 0 then return end
			detenerAutoPlay()
			if E.pasoActual < E.totalPasos then
				E.pasoActual = E.pasoActual + 1
				PanelEstadoAnalisis.aplicarPaso(E.pasos[E.pasoActual])
			end
		end)
	end

	-- BtnAnterior
	local btnAnt = C.buscar(E.overlay, "BtnAnterior")
	if btnAnt then
		btnAnt.MouseButton1Click:Connect(function()
			if not E.abierto or E.totalPasos == 0 then return end
			detenerAutoPlay()
			if E.pasoActual > 1 then
				E.pasoActual = E.pasoActual - 1
				PanelEstadoAnalisis.aplicarPaso(E.pasos[E.pasoActual])
			end
		end)
	end

	-- Escuchar cambios de zona mientras está abierto
	jugador:GetAttributeChangedSignal("ZonaActual"):Connect(function()
		if not E.abierto then return end
		limpiarEstadoVisual()
		local zona = jugador:GetAttribute("ZonaActual") or ""
		if zona == "" then
			PanelEstadoAnalisis.mostrarMensajeDesc("Entra en una zona para ver el análisis.")
			PanelEstadoAnalisis.actualizarScrollEstado(nil)
			return
		end
		PanelEstadoAnalisis.mostrarMensajeDesc("Cargando zona: " .. zona .. "…")
		cargarGrafoCompleto(zona,
			function()
				ViewportAnalisis.construirViewport()
				seleccionarAlgo(E.algoActual)
			end,
			function(msg)
				PanelEstadoAnalisis.mostrarMensajeDesc(msg)
			end
		)
	end)

	-- AnalisisBtn en SelectorModos
	local selectorModos = hudGui:FindFirstChild("SelectorModos", true)
	if selectorModos then
		local analisisBtn = selectorModos:FindFirstChild("AnalisisBtn")
		if analisisBtn then
			analisisBtn.MouseButton1Click:Connect(function()
				if E.abierto then
					ModuloAnalisis.cerrar()
				else
					ModuloAnalisis.abrir()
				end
			end)
		else
			warn("[ModuloAnalisis] AnalisisBtn no encontrado en SelectorModos")
		end
	else
		warn("[ModuloAnalisis] SelectorModos no encontrado")
	end

	-- Estado inicial de UI
	PanelEstadoAnalisis.actualizarPills(E.algoActual)
	PseudocodigoAnalisis.reconstruirPseudocodigo(E.algoActual)

	print("[ModuloAnalisis] Inicializado ✅")
end

function ModuloAnalisis.configurarNivel(nivelModelParam, nivelIDParam, _configNivel)
	E.nivelModel = nivelModelParam
	E.nivelID    = nivelIDParam
end

function ModuloAnalisis.abrir()
	if not E.overlay then
		warn("[ModuloAnalisis] Overlay no disponible — ¿inicializar() fue llamado?")
		return
	end

	E.abierto         = true
	E.overlay.Visible = true

	local zona = jugador:GetAttribute("ZonaActual") or ""
	if zona == "" then
		PanelEstadoAnalisis.mostrarMensajeDesc("Entra en una zona para ver el análisis de su grafo.")
		PanelEstadoAnalisis.actualizarScrollEstado(nil)
		print("[ModuloAnalisis] Abierto (sin zona activa)")
		return
	end

	PanelEstadoAnalisis.mostrarMensajeDesc("Cargando grafo completo…")

	cargarGrafoCompleto(zona,
		function()
			ViewportAnalisis.construirViewport()
			seleccionarAlgo(E.algoActual)
		end,
		function(msg)
			E.matrizData = nil
			PanelEstadoAnalisis.mostrarMensajeDesc(msg)
			PanelEstadoAnalisis.actualizarScrollEstado(nil)
		end
	)

	print("[ModuloAnalisis] Abierto — zona:", zona)
end

function ModuloAnalisis.cerrar()
	detenerAutoPlay()
	E.abierto = false
	if E.overlay then E.overlay.Visible = false end
	print("[ModuloAnalisis] Cerrado")
end

function ModuloAnalisis.limpiar()
	limpiarEstadoVisual()
	E.nivelModel = nil
	E.nivelID    = nil
	if E.overlay then E.overlay.Visible = false end
	E.abierto = false
	print("[ModuloAnalisis] Limpiado")
end

function ModuloAnalisis.estaAbierto()
	return E.abierto
end

return ModuloAnalisis
