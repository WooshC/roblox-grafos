-- LevelsConfig.lua
-- Fuente única de verdad para la configuración de todos los niveles.
-- Ubicación Roblox: ReplicatedStorage/Config/LevelsConfig  (ModuleScript)
-- Accesible tanto desde el servidor (LevelLoader, DataService) como desde el cliente.

return {
	[0] = { Nombre = "Laboratorio de Grafos", Modelo = "Nivel0",   Algoritmo = nil },
	[1] = { Nombre = "La Red Desconectada",   Modelo = "Nivel1",   Algoritmo = "Conectividad" },
	[2] = { Nombre = "La Fábrica de Señales", Modelo = "Nivel2",   Algoritmo = "BFS/DFS" },
	[3] = { Nombre = "El Puente Roto",        Modelo = "Nivel3",   Algoritmo = "Grafos Dirigidos" },
	[4] = { Nombre = "Ruta Mínima",           Modelo = "Nivel4",   Algoritmo = "Dijkstra" },
}
