-- StarterPlayer/StarterPlayerScripts/Cliente/Services/ButtonManager.lua
-- ✅ BtnMisiones correctamente hace toggle del MisionFrame
-- ✅ BtnMatriz ahora activa el Modo Matemático (MatrixManager)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ButtonManager = {}

local screenGui      = nil
local MapManager     = nil
local MissionsManager = nil
local MatrixManager  = nil   -- 🔥 NUEVO
local LevelsConfig   = nil
local globalState    = nil   -- 🔥 NUEVO: referencia al estado compartido

-- Referencias a botones
local btnReiniciar = nil
local btnMapa      = nil
local btnAlgo      = nil
local btnMisiones  = nil
local btnMatriz    = nil
local btnFinalizar = nil

-- Remotes
local Remotes        = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes")
local eventoReiniciar = Remotes:WaitForChild("ReiniciarNivel", 10)
local eventoAlgo      = Remotes:WaitForChild("EjecutarAlgoritmo", 10)

-- ============================================
-- HELPERS: Buscar botones
-- ============================================

local function findButton(gui, name)
	-- Prioridad 1: BarraBotonesMain
	local barra = gui:FindFirstChild("BarraBotonesMain")
	if barra then
		local btn = barra:FindFirstChild(name)
		if btn then return btn end
	end
	-- Prioridad 2: Directo en GUI
	return gui:FindFirstChild(name)
end

-- ============================================
-- GESTOR DE MODOS (centralizado aquí)
-- ============================================

local GestorModos = {}

function GestorModos:CambiarModo(modo)
	if not screenGui then return end

	-- Referencias (lazy lookup para no depender del orden de init)
	local contenedorMiniMapa    = screenGui:FindFirstChild("ContenedorMiniMapa",    true)
	local panelMatrizAdyacencia = screenGui:FindFirstChild("PanelMatrizAdyacencia", true)
	local overlayAnalisis       = screenGui:FindFirstChild("OverlayAnalisis",       true)
	local misionFrame           = screenGui:FindFirstChild("MisionFrame",           true)
	local _btnAlgoritmo         = screenGui:FindFirstChild("BtnAlgoritmo",          true)
	local _btnMapa              = screenGui:FindFirstChild("BtnMapa",               true)
	local _btnMisiones          = screenGui:FindFirstChild("BtnMisiones",           true)

	-- 1. Ocultar solo los paneles principales (NO el minimapa)
	if panelMatrizAdyacencia then panelMatrizAdyacencia.Visible = false end
	if overlayAnalisis       then overlayAnalisis.Visible       = false end
	if misionFrame           then misionFrame.Visible           = false end

	-- 2. Desactivar modo matemático si salimos de él
	if globalState and globalState.modoActual == "MATEMATICO" and modo ~= "MATEMATICO" then
		if MatrixManager then MatrixManager.desactivar() end
	end

	-- 3. Activar el nuevo modo
	if modo == "VISUAL" then
		if contenedorMiniMapa then contenedorMiniMapa.Visible = true end
		if _btnAlgoritmo      then _btnAlgoritmo.Visible      = true end
		if _btnMapa           then _btnMapa.Visible           = true end
		if _btnMisiones       then _btnMisiones.Visible       = true end
		if globalState then globalState.modoActual = "VISUAL" end
		print("✅ MODO VISUAL ACTIVADO")

	elseif modo == "MATEMATICO" then
		-- Ocultar minimapa en modo matemático, solo botones de mapa/misiones
		if contenedorMiniMapa then contenedorMiniMapa.Visible = false end
		if _btnMapa           then _btnMapa.Visible           = true end
		if _btnMisiones       then _btnMisiones.Visible       = true end
		-- Ocultar solo el botón de algoritmo en modo matemático
		if _btnAlgoritmo      then _btnAlgoritmo.Visible      = false end
		
		if MatrixManager then
			MatrixManager.activar()          -- muestra panel + solicita matriz al servidor
		elseif panelMatrizAdyacencia then
			panelMatrizAdyacencia.Visible = true   -- fallback si MatrixManager no está listo
		end
		if globalState then globalState.modoActual = "MATEMATICO" end
		print("✅ MODO MATEMÁTICO ACTIVADO (sin minimapa)")

	elseif modo == "ANALISIS" then
		if overlayAnalisis then overlayAnalisis.Visible = true end
		if _btnAlgoritmo   then _btnAlgoritmo.Visible   = true end
		if globalState then globalState.modoActual = "ANALISIS" end
		print("✅ MODO ANÁLISIS ACTIVADO")
	end

	-- Actualizar referencia global por compatibilidad con GUIExplorador.lua
	if _G.GUIExplorador then
		_G.GUIExplorador.GestorModos = GestorModos
	end
end

-- ============================================
-- INICIALIZACIÓN
-- ============================================

function ButtonManager.initialize(gui, dependencies)
	screenGui      = gui
	MapManager     = dependencies.MapManager
	MissionsManager = dependencies.MissionsManager
	MatrixManager  = dependencies.MatrixManager  
	LevelsConfig   = dependencies.LevelsConfig
	globalState    = dependencies.globalState      -- 

	btnReiniciar = findButton(gui, "BtnReiniciar")
	btnMapa      = findButton(gui, "BtnMapa")
	btnAlgo      = findButton(gui, "BtnAlgo")
	btnMisiones  = findButton(gui, "BtnMisiones")
	btnMatriz    = findButton(gui, "BtnMatriz")
	btnFinalizar = findButton(gui, "BtnFinalizar")

	-- Debug
	local found = {}
	for name, ref in pairs({
		BtnReiniciar = btnReiniciar,
		BtnMapa      = btnMapa,
		BtnAlgo      = btnAlgo,
		BtnMisiones  = btnMisiones,
		BtnMatriz    = btnMatriz,
		BtnFinalizar = btnFinalizar,
		}) do
		table.insert(found, name .. "=" .. (ref and "✅" or "❌"))
	end
	print("🔘 ButtonManager botones: " .. table.concat(found, " | "))
end

-- ============================================
-- CONEXIÓN DE LISTENERS
-- ============================================

function ButtonManager:init()
	if not screenGui then
		warn("❌ ButtonManager: screenGui no inicializado")
		return
	end

	-- ── REINICIAR ───────────────────────────────────────────────
	if btnReiniciar then
		btnReiniciar.MouseButton1Click:Connect(function()
			if eventoReiniciar then
				eventoReiniciar:FireServer()
				btnReiniciar.Text = "⏳ ..."
				task.wait(1)
				btnReiniciar.Text = "🔄 REINICIAR"
				print("🔄 Reinicio solicitado")
			end
		end)
	end

	-- ── MAPA ────────────────────────────────────────────────────
	if btnMapa then
		btnMapa.MouseButton1Click:Connect(function()
			if MapManager then
				MapManager:toggle()
				print("🗺️ Toggle mapa")
			end
		end)
	end

	-- ── ALGORITMO ───────────────────────────────────────────────
	if btnAlgo then
		btnAlgo.MouseButton1Click:Connect(function()
			local player  = Players.LocalPlayer
			local nivelID = player:GetAttribute("CurrentLevelID")
			if not nivelID or nivelID == -1 then nivelID = 0 end

			local config = LevelsConfig[nivelID]
			if not config then
				warn("⚠️ No hay configuración para Nivel " .. tostring(nivelID))
				return
			end

			local algoritmo  = config.Algoritmo or "BFS"
			local nodoInicio = config.NodoInicio
			local nodoFin    = config.NodoFin

			if not nodoInicio or not nodoFin then
				warn("⚠️ Nivel " .. nivelID .. " no tiene NodoInicio o NodoFin")
				return
			end

			print("🧠 Solicitando algoritmo: " .. algoritmo)
			if eventoAlgo then
				eventoAlgo:FireServer(algoritmo, nodoInicio, nodoFin, nivelID)
			end
		end)
	end

	-- ── MISIONES ────────────────────────────────────────────────
	if btnMisiones then
		btnMisiones.MouseButton1Click:Connect(function()
			print("📋 BtnMisiones clickeado")

			if MissionsManager then
				if MapManager and MapManager:isActive() then
					MapManager:disable()
					task.wait(0.1)
				end
				MissionsManager:toggle()
			else
				warn("❌ MissionsManager no disponible en ButtonManager")
			end
		end)
		print("✅ ButtonManager: listener BtnMisiones conectado")
	else
		warn("❌ ButtonManager: BtnMisiones NO encontrado")
	end

	-- ── MATRIZ → MODO MATEMÁTICO ────────────────────────────────
	if btnMatriz then
		btnMatriz.MouseButton1Click:Connect(function()
			-- Toggle: si ya estamos en modo matemático, volver a visual
			local modoActual = globalState and globalState.modoActual or "VISUAL"

			if modoActual == "MATEMATICO" then
				GestorModos:CambiarModo("VISUAL")
			else
				GestorModos:CambiarModo("MATEMATICO")
			end
		end)
		print("✅ ButtonManager: listener BtnMatriz (Modo Matemático) conectado")
	else
		warn("❌ ButtonManager: BtnMatriz NO encontrado")
	end

	-- ── FINALIZAR ───────────────────────────────────────────────
	if btnFinalizar then
		btnFinalizar.MouseButton1Click:Connect(function()
			print("🏆 Finalizar nivel solicitado")
		end)
	end

	-- ── BOTONES DE MODOS (SelectorModos) ────────────────────────
	local selectorModos = screenGui:FindFirstChild("SelectorModos", true)
	if selectorModos then
		local btnVisual   = selectorModos:FindFirstChild("VisualBtn")
		local btnMatrizM  = selectorModos:FindFirstChild("MatrizBtn")   -- Modo Matemático
		local btnAnalisis = selectorModos:FindFirstChild("AnalisisBtn")

		if btnVisual   then btnVisual.MouseButton1Click:Connect(function()   GestorModos:CambiarModo("VISUAL")     end) end
		if btnMatrizM  then btnMatrizM.MouseButton1Click:Connect(function()  GestorModos:CambiarModo("MATEMATICO") end) end
		if btnAnalisis then btnAnalisis.MouseButton1Click:Connect(function() GestorModos:CambiarModo("ANALISIS")   end) end
		print("✅ ButtonManager: SelectorModos conectado")
	end

	-- Modo inicial
	GestorModos:CambiarModo("VISUAL")

	print("✅ ButtonManager: Todos los listeners conectados")
end

return ButtonManager