-- ServerScriptService/SistemasGameplay/ServicioEnergia.lua
-- Sistema centralizado para gestionar la propagación de energía (BFS) desde Generadores
-- y notificar a los clientes el porcentaje de energía por zona.

local ServicioEnergia = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GrafoHelpers      = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("GrafoHelpers"))
local ValidadorConexiones = require(script.Parent:WaitForChild("ValidadorConexiones"))

-- ── Estado interno ────────────────────────────────────────────────────────────
local _activo = false
local _nivelID = nil
local _config = nil
local _generadores = {}
local _adyacencias = {}
local _zonas = {}
local _eventoProgresoEnergia = nil
local _conexionEstado = nil

-- ── Helpers ───────────────────────────────────────────────────────────────────

-- Limpia y prepara las zonas y generadores para la evaluación.
local function indexarNivel()
	_generadores = {}
	_zonas = {}

	if not _config then return end

	-- Indexar Generadores
	if _config.Generadores then
		for _, gen in ipairs(_config.Generadores) do
			_generadores[gen] = true
		end
	end

	-- Indexar nodos requeridos por cada zona (para porcentaje)
	if _config.Zonas then
		for zonaID, _ in pairs(_config.Zonas) do
			local nodos = GrafoHelpers.nodosDeZona(_adyacencias, zonaID, _config)
			_zonas[zonaID] = nodos
			if #nodos > 0 then
				print(string.format("[ServicioEnergia] Zona indexada: %s (Nodos: %d)", zonaID, #nodos))
			else
				print(string.format("[ServicioEnergia] Zona indexada VACÍA: %s (0 nodos encontrados)", zonaID))
			end
		end
	else
		warn("[ServicioEnergia] ⚠ _config.Zonas es nil o vacío!")
	end
	local countZonas = 0
	for _ in pairs(_zonas) do countZonas = countZonas + 1 end
	print(string.format("[ServicioEnergia] Total zonas indexadas: %d", countZonas))
end

-- Ejecuta un BFS multi-raíz desde todos los generadores para encontrar la red encendida
local function calcularRedEnergizada()
	local energizados = {}
	local cola = {}

	-- Agregar todos los generadores definidos que estén en el grafo
	for gen, _ in pairs(_generadores) do
		energizados[gen] = true
		table.insert(cola, gen)
	end
	
	local cabeza = 1
	while cabeza <= #cola do
		local actual = cola[cabeza]
		cabeza = cabeza + 1

		local vecinos = ValidadorConexiones.obtenerConexiones(actual)
		for _, vecino in ipairs(vecinos) do
			if not energizados[vecino] then
				energizados[vecino] = true
				table.insert(cola, vecino)
			end
		end
	end

	local count = 0
	for _ in pairs(energizados) do count = count + 1 end
	print(string.format("[ServicioEnergia] BFS energía: %d nodos energizados", count))
	return energizados
end

-- Evalúa cada zona y envía los progresos
local function evaluarPropagacion()
	if not _activo then
		warn("[ServicioEnergia] evaluarPropagacion() llamado pero _activo = false")
		return
	end
	if not _eventoProgresoEnergia then
		warn("[ServicioEnergia] evaluarPropagacion() llamado pero _eventoProgresoEnergia es nil")
		return
	end

	local redEnergizada = calcularRedEnergizada()

	local countZonas = 0
	for _ in pairs(_zonas) do countZonas = countZonas + 1 end
	print(string.format("[ServicioEnergia] Evaluando %d zonas...", countZonas))
	for zonaID, nodosEnZona in pairs(_zonas) do
		local energizadosCount = 0
		local totalCount = 0

		for _, nodo in ipairs(nodosEnZona) do
			if not _generadores[nodo] then
				totalCount = totalCount + 1
				if redEnergizada[nodo] then
					energizadosCount = energizadosCount + 1
				end
			end
		end

		local porcentaje = 0
		if totalCount > 0 then
			porcentaje = math.clamp(energizadosCount / totalCount, 0, 1)
		end

		print(string.format("[ServicioEnergia] → Zona %s: %d/%d nodos energizados (%.0f%%)", zonaID, energizadosCount, totalCount, porcentaje * 100))
		_eventoProgresoEnergia:FireAllClients(zonaID, porcentaje)
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- API PÚBLICA
-- ════════════════════════════════════════════════════════════════════════════

function ServicioEnergia.activar(config, nivelID, eventos)
	_activo = true
	_nivelID = nivelID
	_config = config
	_adyacencias = config and config.Adyacencias or {}

	if eventos then
		_eventoProgresoEnergia = eventos:FindFirstChild("ProgresoEnergia")
	end

	indexarNivel()

	-- Suscribir a los movimientos de cables
	if _conexionEstado then _conexionEstado:Disconnect() end
	_conexionEstado = ValidadorConexiones.alCambiarEstado(function(estado, nodoA, nodoB)
		if _activo then
			evaluarPropagacion()
		end
	end)

	-- Forzar evaluación inicial (por si arranca con generadores ya puestos o zonas nulas)
	task.delay(1, function()
		if _activo then evaluarPropagacion() end
	end)

	print(string.format("[ServicioEnergia] Activado — Nivel %s / Generadores: %d", tostring(nivelID), #(_config.Generadores or {})))
end

function ServicioEnergia.desactivar()
	_activo = false
	_nivelID = nil
	_config = nil
	_generadores = {}
	_adyacencias = {}
	_zonas = {}
	_eventoProgresoEnergia = nil

	if _conexionEstado then
		_conexionEstado:Disconnect()
		_conexionEstado = nil
	end
	
	print("[ServicioEnergia] Desactivado")
end

return ServicioEnergia
