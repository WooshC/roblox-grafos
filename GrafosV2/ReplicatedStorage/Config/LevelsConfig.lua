-- ReplicatedStorage/Config/LevelsConfig.lua
-- FUENTE ÚNICA DE VERDAD para todos los niveles.
-- Solo contiene campos que el código actual lee.
--
-- Campos usados actualmente:
--   Nombre, DescripcionCorta, ImageId, Modelo → MenuController
--   Puntuacion.*                               → Boot → ScoreTracker / DataService
--   Adyacencias                                → Boot → ConectarCables
--   Zonas[x].Trigger                           → Boot → ZoneTriggerManager
--   NombresPostes                              → GUI de nodos
--
-- Ubicación Roblox: ReplicatedStorage/Config/LevelsConfig  (ModuleScript)

local LevelsConfig = {}

-- ============================================
-- NIVEL 0: LABORATORIO DE GRAFOS
-- ============================================
LevelsConfig[0] = {
	Nombre           = "Laboratorio de Grafos",
	DescripcionCorta = "Aprende teoría de grafos a través de 4 zonas educativas.",
	ImageId          = "rbxassetid://87116895331866",
	Modelo           = "Nivel0",

	Puntuacion = {
		TresEstrellas  = 1000,
		DosEstrellas   = 600,
		RecompensaXP   = 500,
		PuntosConexion = 50,
		PenaFallo      = 10,
	},

	-- Qué conexiones son válidas. Boot pasa esto a ConectarCables.
	-- nil = modo permisivo (todo nodo conecta con todo).
	Adyacencias = {
		["Nodo1_z1"] = {"Nodo2_z1"},
		["Nodo2_z1"] = {"Nodo1_z1"},

		["Nodo1_z2"] = {"Nodo2_z2", "Nodo3_z2", "Nodo4_z2"},
		["Nodo2_z2"] = {"Nodo1_z2"},
		["Nodo3_z2"] = {"Nodo1_z2"},
		["Nodo4_z2"] = {"Nodo1_z2"},

		["Nodo1_z3"] = {"Nodo2_z3"},
		["Nodo2_z3"] = {"Nodo3_z3"},
		["Nodo3_z3"] = {},

		["Nodo1_z4"] = {"Nodo2_z4", "Nodo3_z4"},
		["Nodo2_z4"] = {"Nodo1_z4", "Nodo3_z4"},
		["Nodo3_z4"] = {"Nodo1_z4", "Nodo2_z4"},
		["Nodo4_z4"] = {"Nodo3_z4", "Nodo2_z4"},

		["PostePanel"]      = {"toma_corriente"},
		["toma_corriente"]  = {"PostePanel"},
	},

	-- Trigger = nombre de la BasePart en NivelActual/Zonas/Zonas_juego/
	-- Boot convierte este dict al array que ZoneTriggerManager espera.
	Zonas = {
		["Zona_Estacion_1"] = { Trigger = "ZonaTrigger_Estacion1" },
		["Zona_Estacion_2"] = { Trigger = "ZonaTrigger_Estacion2" },
		["Zona_Estacion_3"] = { Trigger = "ZonaTrigger_Estacion3" },
		["Zona_Estacion_4"] = { Trigger = "ZonaTrigger_Estacion4" },
	},

	-- Nombres amigables de nodos para GUIs y logs
	NombresPostes = {
		["Nodo1_z1"] = "Nodo 1",    ["Nodo2_z1"] = "Nodo 2",
		["Nodo1_z2"] = "Centro",    ["Nodo2_z2"] = "Vecino 1",
		["Nodo3_z2"] = "Vecino 2",  ["Nodo4_z2"] = "Vecino 3",
		["Nodo1_z3"] = "Nodo X",    ["Nodo2_z3"] = "Nodo Y",    ["Nodo3_z3"] = "Nodo Z",
		["Nodo1_z4"] = "Nodo 1",    ["Nodo2_z4"] = "Nodo 2",    ["Nodo3_z4"] = "Nodo 3",
		["PostePanel"]     = "Panel Central",
		["toma_corriente"] = "Tableta Especial",
	},
}

-- ============================================
-- NIVEL 1 — stub (no implementado aún)
-- ============================================
LevelsConfig[1] = {
	Nombre           = "La Red Desconectada",
	DescripcionCorta = "Identifica componentes y conéctalos para restaurar la red.",
	ImageId          = "rbxassetid://1234567891",
	Modelo           = "Nivel1",
	Puntuacion = { TresEstrellas=1500, DosEstrellas=900, RecompensaXP=150, PuntosConexion=50, PenaFallo=10 },
	Adyacencias = {},
	Zonas       = {},
}

-- ============================================
-- NIVEL 2 — stub
-- ============================================
LevelsConfig[2] = {
	Nombre           = "La Fábrica de Señales",
	DescripcionCorta = "Una zona más amplia requiere planificación cuidadosa.",
	ImageId          = "rbxassetid://1234567892",
	Modelo           = "Nivel2",
	Puntuacion = { TresEstrellas=2500, DosEstrellas=1500, RecompensaXP=200, PuntosConexion=50, PenaFallo=10 },
	Adyacencias = {},
	Zonas       = {},
}

-- ============================================
-- NIVEL 3 — stub
-- ============================================
LevelsConfig[3] = {
	Nombre           = "El Puente Roto",
	DescripcionCorta = "Alta demanda de energía y rutas costosas.",
	ImageId          = "rbxassetid://1234567893",
	Modelo           = "Nivel3",
	Puntuacion = { TresEstrellas=4000, DosEstrellas=2500, RecompensaXP=300, PuntosConexion=50, PenaFallo=10 },
	Adyacencias = {},
	Zonas       = {},
}

-- ============================================
-- NIVEL 4 — stub
-- ============================================
LevelsConfig[4] = {
	Nombre           = "Ruta Mínima",
	DescripcionCorta = "El desafío final de optimización.",
	ImageId          = "rbxassetid://1234567894",
	Modelo           = "Nivel4",
	Puntuacion = { TresEstrellas=8000, DosEstrellas=5000, RecompensaXP=500, PuntosConexion=50, PenaFallo=10 },
	Adyacencias = {},
	Zonas       = {},
}

return LevelsConfig
