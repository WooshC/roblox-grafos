-- EstadoConexiones.lua
-- Módulo cliente para mantener el estado de conexiones entre nodos
-- Se sincroniza mediante eventos del servidor

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EstadoConexiones = {}

-- Estado local
local conexionesActivas = {} -- { ["NodoA_NodoB"] = true }
local nombresNodos = {}

-- Eventos
local Eventos = ReplicatedStorage:WaitForChild("EventosGrafosV3")
local Remotos = Eventos:WaitForChild("Remotos")

-- ================================================================
-- UTILIDADES
-- ================================================================

local function generarClave(nombreA, nombreB)
	if nombreA < nombreB then
		return nombreA .. "_" .. nombreB
	else
		return nombreB .. "_" .. nombreA
	end
end

-- ================================================================
-- GESTIÓN DE ESTADO
-- ================================================================

function EstadoConexiones.inicializar(configNivel)
	conexionesActivas = {}
	nombresNodos = {}
	
	if configNivel and configNivel.NombresNodos then
		nombresNodos = configNivel.NombresNodos
	end
	
	-- Conectar a eventos del servidor
	local notificarEvento = Remotos:FindFirstChild("NotificarSeleccionNodo")
	if notificarEvento then
		notificarEvento.OnClientEvent:Connect(function(tipoEvento, nodoA, nodoB)
			if tipoEvento == "ConexionCompletada" then
				EstadoConexiones.registrarConexion(nodoA, nodoB)
			elseif tipoEvento == "CableDesconectado" then
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
	
	local clave = generarClave(nombreA, nombreB)
	conexionesActivas[clave] = true
end

function EstadoConexiones.eliminarConexion(nombreA, nombreB)
	if typeof(nombreA) == "Instance" then
		nombreA = nombreA.Name
	end
	if typeof(nombreB) == "Instance" then
		nombreB = nombreB.Name
	end
	
	local clave = generarClave(nombreA, nombreB)
	conexionesActivas[clave] = nil
end

-- ================================================================
-- CONSULTAS
-- ================================================================

function EstadoConexiones.estaConectado(nombreA, nombreB)
	local clave = generarClave(nombreA, nombreB)
	return conexionesActivas[clave] == true
end

function EstadoConexiones.tieneConexiones(nombreNodo)
	for clave, _ in pairs(conexionesActivas) do
		if string.find(clave, nombreNodo .. "_") or string.find(clave, "_" .. nombreNodo) then
			return true
		end
	end
	return false
end

function EstadoConexiones.obtenerConexiones(nombreNodo)
	local conectados = {}
	for clave, _ in pairs(conexionesActivas) do
		local nodoA, nodoB = string.match(clave, "^(.-)_(.+)$")
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
		if string.find(clave, nombreNodo .. "_") or string.find(clave, "_" .. nombreNodo) then
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
