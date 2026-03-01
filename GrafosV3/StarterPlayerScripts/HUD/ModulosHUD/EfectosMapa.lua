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

local EfectosMapa = {}

-- Estado
local nombresNodos = {}
local partesOriginales = {} -- Guardar estado original para restaurar

-- Módulo de estado de conexiones (se inicializa luego)
local EstadoConexiones = nil

-- Colores del modo mapa (para la part del Selector)
local COLORES = {
	SELECCIONADO = Color3.fromRGB(255, 255, 255),  -- Blanco
	ADYACENTE    = Color3.fromRGB(255, 200, 50),   -- Dorado
	CONECTADO    = Color3.fromRGB(0, 212, 255),    -- Cyan
	AISLADO      = Color3.fromRGB(239, 68, 68),    -- Rojo
}

-- Tipos de Highlight por estado (para el Model)
local HIGHLIGHT_TIPO = {
	SELECCIONADO = "SELECCIONADO",
	ADYACENTE    = "ADYACENTE",
	CONECTADO    = "CONECTADO",
	AISLADO      = "AISLADO",
}

function EfectosMapa.inicializar(configNivel, estadoConexionesModulo)
	nombresNodos = {}
	if configNivel and configNivel.NombresNodos then
		nombresNodos = configNivel.NombresNodos
	end
	EstadoConexiones = estadoConexionesModulo
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
	partesOriginales = {}

	-- Limpiar billboards
	local workspace = game:GetService("Workspace")
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj.Name:match("^MapaBB_") or obj.Name:match("^MapaLabel_") then
			obj:Destroy()
		end
	end

	-- Limpiar Highlights de nodos del mapa
	getEfectosHighlight().limpiarMapaNodos()
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

	local workspace = game:GetService("Workspace")
	local nombreBB = "MapaBB_" .. nodo.Name
	local anterior = workspace:FindFirstChild(nombreBB)
	if anterior then anterior:Destroy() end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = nombreBB
	billboard.Adornee = parteAdornar
	billboard.Size = UDim2.new(0, 160, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 5.5, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.Parent = workspace

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = EfectosMapa.obtenerNombreAmigable(nodo.Name)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.1
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.Parent = billboard

	return billboard
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

	for _, grafo in ipairs(grafosFolder:GetChildren()) do
		local nodosFolder = grafo:FindFirstChild("Nodos")
		if nodosFolder then
			for _, nodo in ipairs(nodosFolder:GetChildren()) do
				local nombre      = nodo.Name
				local esSeleccionado = (nodoSeleccionado and nodoSeleccionado.Name == nombre)
				local esAdyacente    = adyacentes and table.find(adyacentes, nombre)
				local conectado      = EfectosMapa.esNodoConectado(nodo)

				-- Determinar estado
				local colorParte, tipoHighlight
				if esSeleccionado then
					colorParte    = COLORES.SELECCIONADO
					tipoHighlight = HIGHLIGHT_TIPO.SELECCIONADO
				elseif esAdyacente then
					colorParte    = COLORES.ADYACENTE
					tipoHighlight = HIGHLIGHT_TIPO.ADYACENTE
				elseif conectado then
					colorParte    = COLORES.CONECTADO
					tipoHighlight = HIGHLIGHT_TIPO.CONECTADO
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
	end
end

return EfectosMapa
