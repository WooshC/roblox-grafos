-- init.lua
-- API publica de HUDMapa - orquestador principal
-- REFACTORIZADO: Ahora usa SistemaCamara y GestorColisiones unificados

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Sub-modulos
local GestorZonas = require(script.Parent.ZoneManager)
local GestorNodos = require(script.Parent.NodeManager)
local GestorEntrada = require(script.Parent.InputManager)

-- NUEVO: Sistemas unificados desde ReplicatedStorage.Compartido
local SistemaCamara = require(ReplicatedStorage:WaitForChild("Compartido", 5):WaitForChild("SistemaCamara", 5))
local GestorColisiones = require(ReplicatedStorage:WaitForChild("Compartido", 5):WaitForChild("GestorColisiones", 5))

-- Effects (legacy - deprecado gradualmente)
local EfectosNodo = require(ReplicatedStorage.Effects.NodeEffects)

local HUDMapa = {}

-- Estado
HUDMapa.mapaAbierto = false
local jugador = Players.LocalPlayer
local camara = workspace.CurrentCamera

-- Referencias UI
local hudPadre = nil
local marcoMapa = nil
local botonMapa = nil
local botonCerrarMapa = nil

-- Configuracion
local CONFIG = {
	alturaCamara = 80,
	velocidadTween = 0.4
}

-- Referencias externas
local PanelMisionesHUD = nil
local eventoClickMapa = nil
local ConfiguracionNiveles = nil

-- ═══════════════════════════════════════════════════════════════════════════════
-- INICIALIZACION
-- ═══════════════════════════════════════════════════════════════════════════════
function HUDMapa.init(hudRef, deps)
	hudPadre = hudRef
	PanelMisionesHUD = deps and deps.HUDMisionPanel

	-- UI
	marcoMapa = hudPadre:FindFirstChild("PantallaMapaGrande", true)
	botonMapa = hudPadre:FindFirstChild("BtnMapa", true)
	botonCerrarMapa = hudPadre:FindFirstChild("BtnCerrarMapa", true)

	-- Config
	ConfiguracionNiveles = _G.LevelsConfig or require(ReplicatedStorage.Config.LevelsConfig)

	-- Evento remoto
	task.spawn(function()
		local Events = ReplicatedStorage:WaitForChild("Events", 10)
		if Events then
			local Remotes = Events:WaitForChild("Remotes", 10)
			if Remotes then
				eventoClickMapa = Remotes:WaitForChild("MapaClickNodo", 10)
			end
		end
	end)

	-- Inicializar sub-modulos
	if GestorNodos.init then
		GestorNodos.init()
	end

	HUDMapa._conectarBotones()
	print("[HUDMapa] ✅ Inicializado con SistemaCamara unificado")
end

function HUDMapa._conectarBotones()
	if botonMapa then
		botonMapa.MouseButton1Click:Connect(function()
			if HUDMapa.mapaAbierto then
				HUDMapa.cerrar()
			else
				HUDMapa.abrir()
			end
		end)
	end

	if botonCerrarMapa then
		botonCerrarMapa.MouseButton1Click:Connect(HUDMapa.cerrar)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- ABRIR MAPA
-- ═══════════════════════════════════════════════════════════════════════════════
function HUDMapa.abrir()
	if HUDMapa.mapaAbierto then return end
	HUDMapa.mapaAbierto = true

	if botonMapa then
		botonMapa.Text = "❌ CERRAR MAPA"
	end

	marcoMapa.Visible = true

	-- NUEVO: Usar SistemaCamara para cambiar a modo MAPA
	local nivelActual = workspace:FindFirstChild("NivelActual")
	if not nivelActual then 
		warn("[HUDMapa] No se encontro NivelActual")
		return 
	end

	-- Capturar y ocultar techo usando GestorColisiones
	GestorColisiones:capturar(nivelActual)
	GestorColisiones:ocultarTecho()

	-- Usar SistemaCamara para vista cenital
	SistemaCamara:establecerMapa(nivelActual, jugador)

	-- Inicializar managers
	local nivelID = jugador:GetAttribute("NivelActualID") or 0
	local nivelConfig = ConfiguracionNiveles[nivelID]

	GestorNodos.init(nivelActual, nivelConfig)

	-- Zonas con delay para sincronizacion
	local datosMisiones = PanelMisionesHUD and PanelMisionesHUD.getMissionState and PanelMisionesHUD.getMissionState()

	task.delay(0.3, function()
		GestorZonas.highlightAllZones(nivelActual, nivelID, datosMisiones, ConfiguracionNiveles)
	end)

	-- Input
	GestorEntrada.init(nivelActual, HUDMapa._alClickearNodo)
	GestorEntrada.startListening()

	print("[HUDMapa] ✅ Mapa abierto")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CERRAR MAPA
-- ═══════════════════════════════════════════════════════════════════════════════
function HUDMapa.cerrar()
	if not HUDMapa.mapaAbierto then return end
	HUDMapa.mapaAbierto = false

	if botonMapa then
		botonMapa.Text = "🗺️ MAPA"
	end

	marcoMapa.Visible = false

	-- Limpiar managers
	GestorZonas.cleanup()
	SistemaCamara:establecerGameplay(jugador)  -- Volver a camara de gameplay
	GestorEntrada.stopListening()
	GestorNodos.clearSelection()
	GestorNodos.resetAllSelectors()

	-- Restaurar techo
	GestorColisiones:restaurar()
	GestorColisiones:liberar()

	print("[HUDMapa] ✅ Mapa cerrado")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CALLBACKS
-- ═══════════════════════════════════════════════════════════════════════════════
function HUDMapa._alClickearNodo(poste, selectorPart)
	local nombre = poste.Name
	local nivelID = jugador:GetAttribute("NivelActualID") or 0

	-- Toggle seleccion
	if EfectosNodo.selectedNode == nombre then
		GestorNodos.clearSelection()
	else
		-- Calcular adyacentes
		local adyacentes = {}
		local config = ConfiguracionNiveles[nivelID]
		if config and config.Adyacencias then
			adyacentes = config.Adyacencias[nombre] or {}
		end
		GestorNodos.setSelection(nombre, adyacentes)
	end

	-- Notificar servidor
	if eventoClickMapa then
		pcall(function()
			eventoClickMapa:FireServer(selectorPart)
		end)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- API PUBLICA ADICIONAL
-- ═══════════════════════════════════════════════════════════════════════════════
function HUDMapa.actualizarZonas(datosMisiones)
	if not HUDMapa.mapaAbierto then return end

	GestorZonas.cleanup()
	local nivelActual = workspace:FindFirstChild("NivelActual")
	local nivelID = jugador:GetAttribute("NivelActualID") or 0

	if nivelActual then
		GestorZonas.highlightAllZones(nivelActual, nivelID, datosMisiones, ConfiguracionNiveles)
	end
end

function HUDMapa.estaAbierto()
	return HUDMapa.mapaAbierto
end

-- Alias para compatibilidad
HUDMapa.isOpen = HUDMapa.estaAbierto

-- ═══════════════════════════════════════════════════════════════════════════════
-- API DE TECHO (Compatibilidad con codigo antiguo)
-- ═══════════════════════════════════════════════════════════════════════════════
function HUDMapa.showRoof()
	GestorColisiones:restaurar()
end

function HUDMapa.hideRoof()
	GestorColisiones:ocultarTecho()
end

function HUDMapa.restoreRoof()
	GestorColisiones:restaurar()
end

function HUDMapa.resetRoofCache()
	GestorColisiones:liberar()
end

return HUDMapa
