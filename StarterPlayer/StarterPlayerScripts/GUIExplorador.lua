-- ================================================================
-- GUIExplorador.client.lua (COMPLETO CON DialogueVisibilityManager)
-- Script cliente que habilita y gestiona la GUI del Explorador
-- ================================================================

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ================================================================
-- PASO 1: Crear o acceder a la GUI
-- ================================================================

print("🎨 GUIExplorador.client: Buscando GUI...")

-- Esperar a que se cree la GUI desde el script de StarterGui
local gui = playerGui:WaitForChild("GUIExplorador", 10)

if not gui then
	warn("❌ GUIExplorador no encontrada en PlayerGui")
	-- Crear fallback
	local crearGUI = require(ReplicatedStorage:WaitForChild("Explorador de Grafos - GUI Unificada"))
	if crearGUI then
		gui = crearGUI()
		if gui then
			gui.Parent = playerGui
			print("✅ GUI creada desde ReplicatedStorage")
		end
	end
end

if not gui then
	error("❌ CRÍTICO: No se pudo crear o encontrar GUIExplorador")
end

-- ================================================================
-- 🔥 CARGAR Y INICIALIZAR DialogueVisibilityManager
-- ================================================================

local DialogueVisibilityManager = require(ReplicatedStorage:WaitForChild("DialogueVisibilityManager", 5))
if DialogueVisibilityManager then
	DialogueVisibilityManager.initialize()
	print("✅ GUIExplorador: DialogueVisibilityManager integrado")
else
	warn("⚠️ GUIExplorador: DialogueVisibilityManager no encontrado")
end

-- ================================================================
-- PASO 1.5: Inicializar Servicios (Managers)
-- ================================================================
local Cliente = script.Parent:WaitForChild("Cliente")
local Services = Cliente:WaitForChild("Services")

local ButtonManager = require(Services:WaitForChild("ButtonManager"))
local MissionsManager = require(Services:WaitForChild("MissionsManager"))
local MapManager = require(Services:WaitForChild("MapManager"))
local NodeLabelManager = require(Services:WaitForChild("NodeLabelManager"))
local EventManager = require(Services:WaitForChild("EventManager"))
local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))
local MatrixManager=require(Services:WaitForChild("MatrixManager"))
print("⚙️ GUIExplorador: Inicializando servicios...")

-- Estado global compartido
local globalState = {
	mapaActivo = false,
	enMenu = false,
	zoomLevel = 60,
	modoActual="VISUAL"
}

-- Dependencias
local deps = {
	LevelsConfig = LevelsConfig,
	NodeLabelManager = NodeLabelManager,
	MissionsManager = MissionsManager,
	MapManager = MapManager,
	MatrixManager    = MatrixManager,
	globalState = globalState
}

-- Inicializar managers
NodeLabelManager.initialize(deps)
MissionsManager.initialize(globalState, gui, deps)
MapManager.initialize(globalState, gui, deps)
MatrixManager.initialize(globalState, gui, deps)
EventManager.initialize(globalState, deps)
ButtonManager.initialize(gui, deps)
ButtonManager:init() -- Conectar listeners
EventManager:init() --NUEVO: Conectar eventos remotos

print("✅ GUIExplorador: Servicios inicializados y conectados")

-- ================================================================
-- PASO 2: Habilitar la GUI cuando el nivel está listo
-- ================================================================

print("🎨 GUIExplorador.client: Habilitando GUI...")

-- Esperar a que el jugador esté en un nivel
player:GetAttributeChangedSignal("CurrentLevelID"):Connect(function()
	local levelID = player:GetAttribute("CurrentLevelID")

	if levelID and levelID >= 0 then
		-- Nivel cargado
		gui.Enabled = true
		print("✅ GUIExplorador habilitada para nivel " .. levelID)

		-- Actualizar información del nivel
		updateGUIForLevel(levelID, gui)
	else
		-- Fuera de nivel
		gui.Enabled = false
		print("🔒 GUIExplorador deshabilitada")
	end
end)

-- Trigger inicial
local initialLevel = player:GetAttribute("CurrentLevelID")
if initialLevel and initialLevel >= 0 then
	gui.Enabled = true
	print("✅ GUIExplorador habilitada (inicial) para nivel " .. initialLevel)
	updateGUIForLevel(initialLevel, gui)
else
	gui.Enabled = false
end

-- ================================================================
-- FUNCIÓN: Actualizar GUI para el nivel actual
-- ================================================================

function updateGUIForLevel(nivelID, guiRef)
	local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))
	local config = LevelsConfig[nivelID]

	if not config then return end

	print("🎨 GUIExplorador: Actualizando para nivel " .. nivelID)

	-- Actualizar título (si existe)
	local etiquetaTitulo = guiRef:FindFirstChild("BarraSuperior") and 
		guiRef.BarraSuperior:FindFirstChild("Titulo")
	if etiquetaTitulo then
		etiquetaTitulo.Text = "📊 " .. config.Nombre
	end

	-- Actualizar información del nivel (si existe un panel de info)
	local panelInfo = guiRef:FindFirstChild("PanelInfoGrafo")
	if panelInfo then
		local etiquetaInfo = panelInfo:FindFirstChild("EtiquetaInfoGrafo")
		local estadisticas = panelInfo:FindFirstChild("EstadisticasGrafo")

		if etiquetaInfo then
			etiquetaInfo.Text = config.Nombre
		end

		if estadisticas then
			local nodosTotales = config.NodosTotales or 0
			local aristasTotales = 0

			if config.Adyacencias then
				for _, vecinos in pairs(config.Adyacencias) do
					aristasTotales = aristasTotales + #vecinos
				end
			end

			estadisticas.Text = "Nodos: " .. nodosTotales .. " | Aristas: " .. aristasTotales
		end
	end
end

-- ================================================================
-- PASO 3: Conectar botones de modo
-- ================================================================

local referencias = _G.GUIExplorador

if referencias and referencias.GestorModos then
	local selectorModos = gui:FindFirstChild("SelectorModos")

	if selectorModos then
		local btnVisual = selectorModos:FindFirstChild("VisualBtn")
		local btnMatriz = selectorModos:FindFirstChild("MatrizBtn")
		local btnAnalisis = selectorModos:FindFirstChild("AnalisisBtn")

		if btnVisual then
			btnVisual.MouseButton1Click:Connect(function()
				referencias.GestorModos:CambiarModo("VISUAL")
			end)
		end

		if btnMatriz then
			btnMatriz.MouseButton1Click:Connect(function()
				referencias.GestorModos:CambiarModo("MATRIZ")
			end)
		end

		if btnAnalisis then
			btnAnalisis.MouseButton1Click:Connect(function()
				referencias.GestorModos:CambiarModo("ANALISIS")
			end)
		end
	end
end

-- ================================================================
-- PASO 4: Sincronización en tiempo real
-- ================================================================

-- Listener de actualización de puntos
player:WaitForChild("leaderstats", 5)
local stats = player:FindFirstChild("leaderstats")

if stats then
	local puntos = stats:FindFirstChild("Puntos")
	local estrellas = stats:FindFirstChild("Estrellas")

	if puntos then
		puntos.Changed:Connect(function(newValue)
			-- Actualizar label de puntos en la GUI
			local panelPuntuacion = gui:FindFirstChild("BarraSuperior") and
				gui.BarraSuperior:FindFirstChild("PanelPuntuacion")

			if panelPuntuacion then
				local valorPuntos = panelPuntuacion:FindFirstChild("ContenedorPuntos") and
					panelPuntuacion.ContenedorPuntos:FindFirstChild("Valor")

				if valorPuntos then
					valorPuntos.Text = tostring(newValue)
				end
			end
		end)
	end

	if estrellas then
		estrellas.Changed:Connect(function(newValue)
			-- Actualizar label de estrellas en la GUI
			local panelPuntuacion = gui:FindFirstChild("BarraSuperior") and
				gui.BarraSuperior:FindFirstChild("PanelPuntuacion")

			if panelPuntuacion then
				local valorEstrellas = panelPuntuacion:FindFirstChild("ContenedorEstrellas") and
					panelPuntuacion.ContenedorEstrellas:FindFirstChild("Valor")

				if valorEstrellas then
					local estrellasStr = ""
					for i = 1, 3 do
						estrellasStr = estrellasStr .. (i <= newValue and "⭐" or "☆")
					end
					valorEstrellas.Text = estrellasStr .. " (" .. newValue .. "/3)"
				end
			end
		end)
	end
end

print("✅ GUIExplorador.client cargado correctamente")