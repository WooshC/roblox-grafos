-- EfectosMapa.lua
-- Sistema de efectos visuales específico para el modo mapa cenital
-- Cambia color en el Selector Y añade Highlight en el Model del nodo

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require lazy para evitar problemas de resolución del type-checker
local _EfectosHighlight = nil
local function getEfectosHighlight()
	if not _EfectosHighlight then
		_EfectosHighlight = require(ReplicatedStorage.Efectos.EfectosHighlight)
	end
	return _EfectosHighlight
end

local BillboardNombres = require(ReplicatedStorage.Efectos.BillboardNombres)
local GestorEfectos = require(script.Parent.Parent.Parent:WaitForChild("SistemasGameplay"):WaitForChild("GestorEfectos"))

local EfectosMapa = {}

-- Estado
local nombresNodos = {}
local partesOriginales = {} -- Guardar estado original para restaurar
local beamsOriginales = {} -- Guardar estado original de los beams
local configNivelGlobal = nil

-- Red energizada recibida desde ServicioEnergia (fuente de verdad en tiempo real)
local redEnergizadaServidor = nil

-- Módulo de estado de conexiones (se inicializa luego)
local EstadoConexiones = nil

-- Colores del modo mapa (para la part del Selector)
local COLORES = {
	SELECCIONADO    = Color3.fromRGB(255, 255, 255),  -- Blanco
	ADYACENTE       = Color3.fromRGB(255, 200, 50),   -- Dorado
	CONECTADO       = Color3.fromRGB(0, 212, 255),    -- Cyan (Energizado)
	CONEXION_MINIMA = Color3.fromRGB(59, 130, 246),   -- Azul (tiene relación/adayacencia)
	AISLADO         = Color3.fromRGB(239, 68, 68),    -- Rojo oscuro
	INICIAL         = Color3.fromRGB(85, 170, 255),   -- Azul (compatibilidad)
	SIN_ENERGIA     = Color3.fromRGB(255, 50, 100),   -- Rosado (reservado para aristas)
}

-- Tipos de Highlight por estado (para el Model)
local HIGHLIGHT_TIPO = {
	SELECCIONADO    = "SELECCIONADO",
	ADYACENTE       = "ADYACENTE",
	CONECTADO       = "CONECTADO",
	CONEXION_MINIMA = "CONEXION_MINIMA",
	AISLADO         = "AISLADO",
	INICIAL         = "INICIAL",
}

function EfectosMapa.inicializar(configNivel, estadoConexionesModulo)
	nombresNodos = {}
	configNivelGlobal = configNivel
	-- No reseteamos redEnergizadaServidor aquí: el evento puede llegar antes de configurarNivel.
	if configNivel and configNivel.NombresNodos then
		nombresNodos = configNivel.NombresNodos
	end
	EstadoConexiones = estadoConexionesModulo
end

function EfectosMapa.limpiarRedEnergizada()
	redEnergizadaServidor = nil
end

function EfectosMapa.actualizarRedEnergizada(redEnergizada)
	redEnergizadaServidor = redEnergizada
end

function EfectosMapa.obtenerRedEnergizada()
	return redEnergizadaServidor
end

function EfectosMapa.limpiarTodo()
	-- Restaurar todas las partes a su estado original
	for _, data in ipairs(partesOriginales) do
		if data.parte and data.parte.Parent then
			data.parte.Color = data.colorOriginal
			data.parte.Material = data.materialOriginal
			data.parte.Transparency = data.transparencyOriginal
			if data.tamanoOriginal then
				data.parte.Size = data.tamanoOriginal
			end
		end
	end
	-- NOTA: no limpiar partesOriginales aquí; la caché debe sobrevivir entre
	-- aperturas del mapa para no guardar estados intermedios como originales.

	-- Restaurar Beams
	for _, data in ipairs(beamsOriginales) do
		if data.beam and data.beam.Parent then
			data.beam.Color = data.colorOriginal
		end
	end
	-- NOTA: tampoco limpiar beamsOriginales aquí.

	-- Limpiar billboards
	BillboardNombres.destruirPorPrefijo("MapaBB_")

	-- Limpiar Highlights de nodos del mapa
	getEfectosHighlight().limpiarMapaNodos()
end

function EfectosMapa.limpiarCacheOriginales()
	partesOriginales = {}
	beamsOriginales = {}
end

function EfectosMapa.obtenerNombreAmigable(nombreNodo)
	return nombresNodos[nombreNodo] or nombreNodo
end

function EfectosMapa.esNodoConectado(nodo)
	-- Usar el módulo de estado si está disponible
	if EstadoConexiones and EstadoConexiones.tieneConexiones then
		return EstadoConexiones.tieneConexiones(nodo.Name)
	end

	-- Fallback: buscar Beams en la carpeta Conexiones del grafo padre
	local grafo = nodo.Parent and nodo.Parent.Parent
	if grafo then
		local conexionesFolder = grafo:FindFirstChild("Conexiones")
		if conexionesFolder then
			for _, cable in ipairs(conexionesFolder:GetChildren()) do
				local beam = cable:FindFirstChildOfClass("Beam")
				if beam then
					local att0 = beam.Attachment0
					local att1 = beam.Attachment1
					if att0 and att1 then
						local parent0 = att0:FindFirstAncestorOfClass("Model")
						local parent1 = att1:FindFirstAncestorOfClass("Model")
						if parent0 == nodo or parent1 == nodo then
							return true
						end
					end
				end
			end
		end
	end

	return false
end

function EfectosMapa.tieneRelacionMinima(nodo)
	-- Una "conexión mínima" es un cable físico real conectado al nodo.
	return EfectosMapa.esNodoConectado(nodo)
end

function EfectosMapa.obtenerParteSelector(nodo)
	local selector = nodo:FindFirstChild("Selector")
	if not selector then return nil end

	if selector:IsA("BasePart") then
		return selector
	elseif selector:IsA("Model") then
		for _, part in ipairs(selector:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "Attachment" then
				return part
			end
		end
	end

	return nil
end

function EfectosMapa.guardarEstadoOriginal(parte)
	for _, data in ipairs(partesOriginales) do
		if data.parte == parte then
			return -- Ya guardado, no sobrescribir
		end
	end

	table.insert(partesOriginales, {
		parte              = parte,
		colorOriginal      = parte.Color,
		materialOriginal   = parte.Material,
		transparencyOriginal = parte.Transparency,
		tamanoOriginal     = Vector3.new(parte.Size.X, parte.Size.Y, parte.Size.Z),
	})
end

function EfectosMapa.guardarEstadosOriginalesNivel(nivelModel)
	if not nivelModel then return end
	for _, nodo in ipairs(nivelModel:GetDescendants()) do
		if nodo:IsA("Model") and nodo.Name:find("_zN$") then
			local parte = EfectosMapa.obtenerParteSelector(nodo)
			if parte then
				EfectosMapa.guardarEstadoOriginal(parte)
			end
		end
	end
	local conexionesFolder = nivelModel:FindFirstChild("Conexiones", true)
	if conexionesFolder then
		for _, cable in ipairs(conexionesFolder:GetChildren()) do
			local beam = cable:FindFirstChildOfClass("Beam")
			if beam then
				EfectosMapa.guardarEstadoBeamOriginal(beam)
			end
		end
	end
end

function EfectosMapa.guardarEstadoBeamOriginal(beam)
	for _, data in ipairs(beamsOriginales) do
		if data.beam == beam then
			return
		end
	end

	table.insert(beamsOriginales, {
		beam = beam,
		colorOriginal = beam.Color
	})
end

function EfectosMapa.aplicarColor(nodo, color, esSeleccionado)
	local parte = EfectosMapa.obtenerParteSelector(nodo)
	if not parte then
		warn("[EfectosMapa] No se encontró Selector para nodo:", nodo.Name)
		return
	end

	EfectosMapa.guardarEstadoOriginal(parte)

	-- Cambiar color y material del Selector
	parte.Color = color
	parte.Material = Enum.Material.Neon
	parte.Transparency = 0.0

	-- Escala del Selector: ligeramente mayor si está seleccionado
	local tamanoBase
	for _, data in ipairs(partesOriginales) do
		if data.parte == parte then
			tamanoBase = data.tamanoOriginal
			break
		end
	end
	tamanoBase = tamanoBase or parte.Size

	if parte:IsA("BasePart") then
		if (parte.Size - tamanoBase).Magnitude > (tamanoBase.Magnitude * 0.5) then
			parte.Size = tamanoBase
		end
	end

	local tamanoObjetivo = esSeleccionado and (tamanoBase * 1.2) or tamanoBase
	if (parte.Size - tamanoObjetivo).Magnitude > 0.01 then
		TweenService:Create(parte, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = tamanoObjetivo,
		}):Play()
	end
end

function EfectosMapa.crearBillboard(nodo)
	local selector = nodo:FindFirstChild("Selector")
	if not selector then return nil end

	local parteAdornar = nil
	if selector:IsA("BasePart") then
		parteAdornar = selector
	elseif selector:IsA("Model") then
		for _, part in ipairs(selector:GetDescendants()) do
			if part:IsA("BasePart") then
				parteAdornar = part
				break
			end
		end
	end

	if not parteAdornar then return nil end

	return BillboardNombres.crear(
		parteAdornar,
		EfectosMapa.obtenerNombreAmigable(nodo.Name),
		"NODO_MAPA",
		"MapaBB_" .. nodo.Name
	)
end

function EfectosMapa.actualizarTodos(nivelActual, nodoSeleccionado, adyacentes)
	if not nivelActual then
		warn("[EfectosMapa] nivelActual es nil")
		return
	end

	local grafosFolder = nivelActual:FindFirstChild("Grafos")
	if not grafosFolder then
		warn("[EfectosMapa] No se encontró carpeta Grafos")
		return
	end
	
	-- Fuente de verdad de energía: ServicioEnergia envía la red energizada en tiempo real.
	-- Si aún no llega datos, hacemos BFS local como fallback (útil durante carga o desconexiones).
	local nodosEnergizados = redEnergizadaServidor
	if not nodosEnergizados and configNivelGlobal and configNivelGlobal.Generadores and EstadoConexiones then
		nodosEnergizados = {}
		local queue = {}
		for _, gen in ipairs(configNivelGlobal.Generadores) do
			nodosEnergizados[gen] = true
			table.insert(queue, gen)
		end

		while #queue > 0 do
			local actual = table.remove(queue, 1)
			local vecinos = EstadoConexiones.obtenerConexiones(actual)
			if vecinos then
				for _, vecino in ipairs(vecinos) do
					if not nodosEnergizados[vecino] then
						nodosEnergizados[vecino] = true
						table.insert(queue, vecino)
					end
				end
			end
		end
	end
	-- Asegurar que siempre sea una tabla usable
	if not nodosEnergizados then
		nodosEnergizados = {}
	end

	for _, grafo in ipairs(grafosFolder:GetChildren()) do
		local nodosFolder = grafo:FindFirstChild("Nodos")
		if nodosFolder then
			for _, nodo in ipairs(nodosFolder:GetChildren()) do
				local nombre      = nodo.Name
				local esSeleccionado = (nodoSeleccionado and nodoSeleccionado.Name == nombre)
				local esAdyacente    = adyacentes and table.find(adyacentes, nombre)
				local tieneRelacion  = EfectosMapa.tieneRelacionMinima(nodo)
				local tieneEnergia   = nodosEnergizados[nombre] == true

				-- Determinar estado: prioridad energía real del ServicioEnergia
				local colorParte, tipoHighlight
				if esSeleccionado then
					colorParte    = COLORES.SELECCIONADO
					tipoHighlight = HIGHLIGHT_TIPO.SELECCIONADO
				elseif esAdyacente then
					colorParte    = COLORES.ADYACENTE
					tipoHighlight = HIGHLIGHT_TIPO.ADYACENTE
				elseif tieneEnergia then
					colorParte    = COLORES.CONECTADO
					tipoHighlight = HIGHLIGHT_TIPO.CONECTADO
				elseif tieneRelacion then
					-- Tiene al menos una adyacencia/relación posible (incluye generadores y cables sin energía)
					colorParte    = COLORES.CONEXION_MINIMA
					tipoHighlight = HIGHLIGHT_TIPO.CONEXION_MINIMA
				else
					colorParte    = COLORES.AISLADO
					tipoHighlight = HIGHLIGHT_TIPO.AISLADO
				end

				-- Billboard de nombre
				EfectosMapa.crearBillboard(nodo)

				-- Color en el Selector (part)
				EfectosMapa.aplicarColor(nodo, colorParte, esSeleccionado)

				-- Highlight en el Model completo
				getEfectosHighlight().resaltarNodoMapa(nodo, tipoHighlight)
			end
		end
		
		-- Recorrer cables/aristas para actualizarlos según energía
		local conexionesFolder = grafo:FindFirstChild("Conexiones")
		if conexionesFolder then
			for _, child in ipairs(conexionesFolder:GetChildren()) do
				local beam = child:FindFirstChildOfClass("Beam")
				if beam then
					local nomA, nomB = string.match(child.Name, "^Hitbox_(.+)|(.+)$")
					if nomA and nomB then
						EfectosMapa.guardarEstadoBeamOriginal(beam)
						-- Un cable transmite energía solo si ambos extremos tienen energía (están en la red del Generador)
						if nodosEnergizados[nomA] and nodosEnergizados[nomB] then
							beam.Color = ColorSequence.new(COLORES.CONECTADO) -- Celeste/Azul
						else
							beam.Color = ColorSequence.new(COLORES.SIN_ENERGIA) -- Rosado
						end
					end
				end
			end
		end
	end
end

-- Al descargar el nivel limpiar efectos del mapa y la caché de originales
GestorEfectos.registrar("NivelDescargado", function(_params)
	EfectosMapa.limpiarTodo()
	EfectosMapa.limpiarCacheOriginales()
	EfectosMapa.limpiarRedEnergizada()
end)

return EfectosMapa
