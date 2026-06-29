-- EstadoConexiones.lua
-- Módulo cliente para mantener el estado de conexiones entre nodos
-- Se sincroniza mediante eventos del servidor

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GrafoHelpers = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("GrafoHelpers"))

local EstadoConexiones = {}

-- Estado local
local conexionesActivas = {} -- { ["NodoA|NodoB"] = true }
local nombresNodos = {}

-- Eventos
local Eventos = ReplicatedStorage:WaitForChild("EventosGrafosV3")
local Remotos = Eventos:WaitForChild("Remotos")

-- ================================================================
-- UTILIDADES
-- ================================================================

-- ================================================================
-- GESTIÓN DE ESTADO
-- ================================================================

local GestorEfectos = require(script.Parent.Parent.Parent:WaitForChild("SistemasGameplay"):WaitForChild("GestorEfectos"))

-- Conectar a eventos del servidor via GestorEfectos (único listener centralizado)
GestorEfectos.registrar("ConexionCompletada", function(params)
	local nodoA, nodoB = params.arg1, params.arg2
	EstadoConexiones.registrarConexion(nodoA, nodoB)
end)

GestorEfectos.registrar("CableDesconectado", function(params)
	local nodoA, nodoB = params.arg1, params.arg2
	EstadoConexiones.eliminarConexion(nodoA, nodoB)
end)

function EstadoConexiones.inicializar(configNivel)
	print("[EstadoConexiones][DEBUG] inicializar llamado — limpiando conexiones")
	conexionesActivas = {}
	nombresNodos = {}

	if configNivel and configNivel.NombresNodos then
		nombresNodos = configNivel.NombresNodos
	end

	-- Registrar cables iniciales del nivel (el servidor no siempre notifica estas conexiones al cliente)
	if configNivel and configNivel.CablesIniciales then
		for _, par in ipairs(configNivel.CablesIniciales) do
			local nomA, nomB = par[1], par[2]
			if nomA and nomB then
				print(string.format("[EstadoConexiones][DEBUG] registrando cable inicial %s-%s", tostring(nomA), tostring(nomB)))
				EstadoConexiones.registrarConexion(nomA, nomB)
			end
		end
	end

	-- Nuevo evento específico para actualización de estado de conexiones
	local actualizarEstadoEvento = Remotos:FindFirstChild("ActualizarEstadoConexiones")
	if actualizarEstadoEvento then
		actualizarEstadoEvento.OnClientEvent:Connect(function(accion, nodoA, nodoB)
			if accion == "conectar" then
				EstadoConexiones.registrarConexion(nodoA, nodoB)
			elseif accion == "desconectar" then
				EstadoConexiones.eliminarConexion(nodoA, nodoB)
			end
		end)
	end
end

function EstadoConexiones.limpiar()
	conexionesActivas = {}
end

function EstadoConexiones.registrarConexion(nombreA, nombreB)
	if typeof(nombreA) == "Instance" then
		nombreA = nombreA.Name
	end
	if typeof(nombreB) == "Instance" then
		nombreB = nombreB.Name
	end

	local clave = GrafoHelpers.clavePar(nombreA, nombreB)
	print(string.format("[EstadoConexiones][DEBUG] registrarConexion clave=%s", tostring(clave)))
	conexionesActivas[clave] = true
end

function EstadoConexiones.eliminarConexion(nombreA, nombreB)
	if typeof(nombreA) == "Instance" then
		nombreA = nombreA.Name
	end
	if typeof(nombreB) == "Instance" then
		nombreB = nombreB.Name
	end

	local clave = GrafoHelpers.clavePar(nombreA, nombreB)
	print(string.format("[EstadoConexiones][DEBUG] eliminarConexion clave=%s", tostring(clave)))
	conexionesActivas[clave] = nil
end

-- ================================================================
-- CONSULTAS
-- ================================================================

function EstadoConexiones.estaConectado(nombreA, nombreB)
	local clave = GrafoHelpers.clavePar(nombreA, nombreB)
	return conexionesActivas[clave] == true
end

function EstadoConexiones.tieneConexiones(nombreNodo)
	for clave, _ in pairs(conexionesActivas) do
		local nodoA, nodoB = GrafoHelpers.parsearClave(clave)
		if nodoA == nombreNodo or nodoB == nombreNodo then
			return true
		end
	end
	return false
end

function EstadoConexiones.obtenerConexiones(nombreNodo)
	local conectados = {}
	for clave, _ in pairs(conexionesActivas) do
		local nodoA, nodoB = GrafoHelpers.parsearClave(clave)
		if nodoA == nombreNodo then
			table.insert(conectados, nodoB)
		elseif nodoB == nombreNodo then
			table.insert(conectados, nodoA)
		end
	end
	return conectados
end

function EstadoConexiones.obtenerGrado(nombreNodo)
	local count = 0
	for clave, _ in pairs(conexionesActivas) do
		local nodoA, nodoB = GrafoHelpers.parsearClave(clave)
		if nodoA == nombreNodo or nodoB == nombreNodo then
			count = count + 1
		end
	end
	return count
end

function EstadoConexiones.obtenerTodasLasConexiones()
	local lista = {}
	for clave, _ in pairs(conexionesActivas) do
		table.insert(lista, clave)
	end
	return lista
end

-- ================================================================
-- DEPURACIÓN
-- ================================================================

function EstadoConexiones.obtenerEstadoDebug()
	return {
		conexiones = conexionesActivas,
		cantidad = 0
	}
end

return EstadoConexiones
