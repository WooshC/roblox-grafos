-- ValidadorConexiones.lua
-- Módulo centralizado para validación y seguimiento de conexiones entre nodos
-- Basado en el sistema de GarfosV1 pero adaptado para GrafosV3

local ValidadorConexiones = {}

-- Estado interno
local conexiones = {} -- { ["NodoA_NodoB"] = { nodoA = Instance, nodoB = Instance, cable = Instance } }
local configNivel = nil
local adyacencias = nil

-- Eventos
local conexionCreada = Instance.new("BindableEvent")
local conexionEliminada = Instance.new("BindableEvent")
local estadoCambiado = Instance.new("BindableEvent")

-- ================================================================
-- UTILIDADES INTERNAS
-- ================================================================

local function generarClave(nombreA, nombreB)
	-- Clave consistente independiente del orden
	if nombreA < nombreB then
		return nombreA .. "_" .. nombreB
	else
		return nombreB .. "_" .. nombreA
	end
end

local function parsearClave(clave)
	local parts = string.split(clave, "_")
	return parts[1], parts[2]
end

-- ================================================================
-- CONFIGURACIÓN
-- ================================================================

function ValidadorConexiones.configurar(config)
	configNivel = config
	adyacencias = config and config.Adyacencias
end

function ValidadorConexiones.limpiar()
	conexiones = {}
	configNivel = nil
	adyacencias = nil
end

-- ================================================================
-- VALIDACIÓN DE ADYACENCIA
-- ================================================================

--[[
	Verifica si dos nodos son adyacentes según la configuración del nivel.
	Para grafos dirigidos, verifica la dirección válida.
	
	@param nombreA string - Nombre del primer nodo
	@param nombreB string - Nombre del segundo nodo
	@return boolean - true si la conexión es válida según adyacencias
	@return string|nil - tipo de validación: "bidireccional", "unidireccional", "inversa", nil si no es válida
]]
function ValidadorConexiones.esAdyacente(nombreA, nombreB)
	if not adyacencias then return false, nil end
	if not nombreA or not nombreB then return false, nil end
	if nombreA == nombreB then return false, nil end
	
	local puedeAtoB = adyacencias[nombreA] and table.find(adyacencias[nombreA], nombreB) ~= nil
	local puedeBtoA = adyacencias[nombreB] and table.find(adyacencias[nombreB], nombreA) ~= nil
	
	if puedeAtoB and puedeBtoA then
		return true, "bidireccional"
	elseif puedeAtoB then
		return true, "unidireccional"
	elseif puedeBtoA then
		return true, "inversa"
	else
		return false, nil
	end
end

--[[
	Valida si se puede crear una conexión entre dos nodos.
	Considera: adyacencia, conexión existente, y direccionalidad.
	
	@param nombreA string - Nombre del primer nodo
	@param nombreB string - Nombre del segundo nodo
	@return boolean - true si se permite la conexión
	@return string|nil - mensaje de error si no se permite
]]
function ValidadorConexiones.puedeConectar(nombreA, nombreB)
	-- Verificar adyacencia
	local esAdyacente, tipo = ValidadorConexiones.esAdyacente(nombreA, nombreB)
	if not esAdyacente then
		return false, "NoAdyacente"
	end
	
	-- Verificar si ya están conectados
	if ValidadorConexiones.estaConectado(nombreA, nombreB) then
		return true, "YaConectado" -- Permitido para toggle (desconectar)
	end
	
	return true, tipo
end

-- ================================================================
-- GESTIÓN DE CONEXIONES
-- ================================================================

--[[
	Registra una nueva conexión entre dos nodos.
	
	@param nodoA Instance - Modelo/Part del primer nodo
	@param nodoB Instance - Modelo/Part del segundo nodo
	@param cable Instance - Instancia del cable visual (opcional)
	@return boolean - true si se registró correctamente
]]
function ValidadorConexiones.registrarConexion(nodoA, nodoB, cable)
	if not nodoA or not nodoB then return false end
	
	local clave = generarClave(nodoA.Name, nodoB.Name)
	
	-- Si ya existe, eliminarla (toggle)
	if conexiones[clave] then
		ValidadorConexiones.eliminarConexion(nodoA.Name, nodoB.Name)
		return true
	end
	
	conexiones[clave] = {
		nodoA = nodoA,
		nodoB = nodoB,
		cable = cable,
		tiempo = tick()
	}
	
	conexionCreada:Fire(nodoA, nodoB, cable)
	estadoCambiado:Fire("conectado", nodoA, nodoB)
	
	return true
end

--[[
	Elimina una conexión existente.
	
	@param nombreA string - Nombre del primer nodo
	@param nombreB string - Nombre del segundo nodo
	@return boolean - true si se eliminó correctamente
]]
function ValidadorConexiones.eliminarConexion(nombreA, nombreB)
	local clave = generarClave(nombreA, nombreB)
	local data = conexiones[clave]
	
	if not data then return false end
	
	conexiones[clave] = nil
	
	conexionEliminada:Fire(data.nodoA, data.nodoB, data.cable)
	estadoCambiado:Fire("desconectado", data.nodoA, data.nodoB)
	
	return true
end

-- ================================================================
-- CONSULTAS DE ESTADO
-- ================================================================

--[[
	Verifica si dos nodos están conectados.
	
	@param nombreA string - Nombre del primer nodo
	@param nombreB string - Nombre del segundo nodo
	@return boolean - true si están conectados
]]
function ValidadorConexiones.estaConectado(nombreA, nombreB)
	local clave = generarClave(nombreA, nombreB)
	return conexiones[clave] ~= nil
end

--[[
	Obtiene todas las conexiones de un nodo.
	
	@param nombreNodo string - Nombre del nodo
	@return table - lista de nombres de nodos conectados
]]
function ValidadorConexiones.obtenerConexiones(nombreNodo)
	local conectados = {}
	
	for clave, data in pairs(conexiones) do
		if data.nodoA.Name == nombreNodo then
			table.insert(conectados, data.nodoB.Name)
		elseif data.nodoB.Name == nombreNodo then
			table.insert(conectados, data.nodoA.Name)
		end
	end
	
	return conectados
end

--[[
	Verifica si un nodo tiene al menos una conexión.
	
	@param nombreNodo string - Nombre del nodo
	@return boolean - true si tiene conexiones
]]
function ValidadorConexiones.tieneConexiones(nombreNodo)
	for clave, data in pairs(conexiones) do
		if data.nodoA.Name == nombreNodo or data.nodoB.Name == nombreNodo then
			return true
		end
	end
	return false
end

--[[
	Obtiene el grado de un nodo (número de conexiones).
	
	@param nombreNodo string - Nombre del nodo
	@return number - cantidad de conexiones
]]
function ValidadorConexiones.obtenerGrado(nombreNodo)
	local count = 0
	for clave, data in pairs(conexiones) do
		if data.nodoA.Name == nombreNodo or data.nodoB.Name == nombreNodo then
			count = count + 1
		end
	end
	return count
end

--[[
	Obtiene todos los vecinos adyacentes que aún no están conectados.
	Útil para mostrar opciones disponibles.
	
	@param nombreNodo string - Nombre del nodo
	@return table - lista de nombres de nodos adyacentes no conectados
]]
function ValidadorConexiones.obtenerVecinosPendientes(nombreNodo)
	if not adyacencias or not adyacencias[nombreNodo] then
		return {}
	end
	
	local pendientes = {}
	for _, vecino in ipairs(adyacencias[nombreNodo]) do
		if not ValidadorConexiones.estaConectado(nombreNodo, vecino) then
			table.insert(pendientes, vecino)
		end
	end
	return pendientes
end

-- ================================================================
-- ANÁLISIS DE GRAFO
-- ================================================================

--[[
	Realiza BFS desde un nodo para encontrar todos los alcanzables.
	
	@param nombreInicio string - Nodo de inicio
	@return table - mapa { [nombreNodo] = true } de nodos alcanzables
]]
function ValidadorConexiones.obtenerAlcanzables(nombreInicio)
	local alcanzables = {}
	local cola = { nombreInicio }
	alcanzables[nombreInicio] = true
	
	local cabeza = 1
	while cabeza <= #cola do
		local actual = cola[cabeza]
		cabeza = cabeza + 1
		
		local vecinos = ValidadorConexiones.obtenerConexiones(actual)
		for _, vecino in ipairs(vecinos) do
			if not alcanzables[vecino] then
				alcanzables[vecino] = true
				table.insert(cola, vecino)
			end
		end
	end
	
	return alcanzables
end

--[[
	Cuenta componentes conexos en el grafo actual.
	
	@param nombresNodos table - lista de todos los nombres de nodos en el nivel
	@return number - cantidad de componentes conexos
]]
function ValidadorConexiones.contarComponentes(nombresNodos)
	local visitados = {}
	local componentes = 0
	
	for _, nombre in ipairs(nombresNodos) do
		if not visitados[nombre] then
			componentes = componentes + 1
			local alcanzables = ValidadorConexiones.obtenerAlcanzables(nombre)
			for n, _ in pairs(alcanzables) do
				visitados[n] = true
			end
		end
	end
	
	return componentes
end

--[[
	Verifica si todos los nodos están conectados entre sí (grafo conexo).
	
	@param nombresNodos table - lista de todos los nombres de nodos
	@return boolean - true si el grafo es conexo
]]
function ValidadorConexiones.esGrafoConexo(nombresNodos)
	if #nombresNodos == 0 then return true end
	
	local alcanzables = ValidadorConexiones.obtenerAlcanzables(nombresNodos[1])
	
	for _, nombre in ipairs(nombresNodos) do
		if not alcanzables[nombre] then
			return false
		end
	end
	
	return true
end

-- ================================================================
-- MATRIZ DE ADYACENCIA
-- ================================================================

--[[
	Genera la matriz de adyacencia del estado actual.
	
	@param nombresNodos table - lista ordenada de nombres de nodos
	@return table - matriz n×n donde 1 indica conexión
]]
function ValidadorConexiones.generarMatrizAdyacencia(nombresNodos)
	local n = #nombresNodos
	local matriz = {}
	local nombreAIndice = {}
	
	-- Inicializar matriz vacía
	for i = 1, n do
		matriz[i] = {}
		for j = 1, n do
			matriz[i][j] = 0
		end
		nombreAIndice[nombresNodos[i]] = i
	end
	
	-- Marcar conexiones
	for clave, data in pairs(conexiones) do
		local idxA = nombreAIndice[data.nodoA.Name]
		local idxB = nombreAIndice[data.nodoB.Name]
		if idxA and idxB then
			matriz[idxA][idxB] = 1
			matriz[idxB][idxA] = 1 -- No dirigida
		end
	end
	
	return matriz
end

-- ================================================================
-- EVENTOS
-- ================================================================

function ValidadorConexiones.alCrearConexion(callback)
	return conexionCreada.Event:Connect(callback)
end

function ValidadorConexiones.alEliminarConexion(callback)
	return conexionEliminada.Event:Connect(callback)
end

function ValidadorConexiones.alCambiarEstado(callback)
	return estadoCambiado.Event:Connect(callback)
end

-- ================================================================
-- DEPURACIÓN
-- ================================================================

function ValidadorConexiones.obtenerEstadoDebug()
	local lista = {}
	for clave, data in pairs(conexiones) do
		table.insert(lista, {
			clave = clave,
			nodoA = data.nodoA.Name,
			nodoB = data.nodoB.Name
		})
	end
	return lista
end

return ValidadorConexiones
