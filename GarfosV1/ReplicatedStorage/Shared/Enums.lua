-- ReplicatedStorage/Shared/Enums.lua
-- Centraliza TODOS los nombres de eventos, colores y constantes
-- Así, si cambias algo, lo cambias en UN SOLO LUGAR

local Enums = {}

-- ============================================
-- COLORES
-- ============================================
Enums.Colors = {
	-- Cable Estados
	Desconectado = Color3.fromRGB(255, 165, 0),  -- Naranja
	Conectado = Color3.fromRGB(0, 255, 0),       -- Lima Verde
	Energizado = Color3.fromRGB(0, 255, 0),      -- Verde
	NoEnergizado = Color3.fromRGB(255, 0, 0),    -- Rojo

	-- Nodos
	NodoActivo = Color3.fromRGB(0, 0, 255),      -- Azul
	NodoInactivo = Color3.fromRGB(128, 128, 128) -- Gris
}

-- ============================================
-- EVENTOS (Remote Names)
-- ============================================
Enums.Events = {
	-- RemoteEvents (una dirección)
	EjecutarAlgoritmo = "EjecutarAlgoritmo",
	CableDragEvent = "CableDragEvent",
	PulseEvent = "PulseEvent",
	ReiniciarNivel = "ReiniciarNivel",
	ActualizarInventario = "ActualizarInventario",
	ActualizarMision = "ActualizarMision",
	AparecerObjeto = "AparecerObjeto",
	RequestPlayLevel = "RequestPlayLevel",

	-- RemoteFunctions (bidireccionales)
	GetAdjacencyMatrix = "GetAdjacencyMatrix",
	GetPlayerProgress = "GetPlayerProgress",
	VerificarInventario = "VerificarInventario",

	-- BindableEvents (servidor interno)
	ConexionCambiada = "ConexionCambiada",
	DesbloquearObjeto = "DesbloquearObjeto",
	RestaurarObjetos = "RestaurarObjetos",
	OpenMenu = "OpenMenu"
}

-- ============================================
-- ESTADOS DE JUEGO
-- ============================================
Enums.GameState = {
	Menu = "Menu",
	Gameplay = "Gameplay",
	Paused = "Paused",
	LevelComplete = "LevelComplete"
}

-- ============================================
-- ALGORITMOS DISPONIBLES
-- ============================================
Enums.Algorithms = {
	BFS = "BFS",
	DFS = "DFS",
	DIJKSTRA = "DIJKSTRA"
}

-- ============================================
-- GROSOR Y TAMAÑO DE CABLES
-- ============================================
Enums.Cable = {
	NormalThickness = 0.15,
	SelectedThickness = 0.25,
	EnergyThickness = 0.3,

	-- Velocidad de animación
	AnimationSpeed = 0.5
}

return Enums