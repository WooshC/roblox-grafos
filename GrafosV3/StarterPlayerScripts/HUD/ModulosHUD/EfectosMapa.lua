-- EfectosMapa.lua
-- Sistema de efectos visuales específico para el modo mapa cenital
-- Modifica las partes directamente como en GrafosV2 (sin Highlight)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local EfectosMapa = {}

-- Estado
local nombresNodos = {}
local partesOriginales = {} -- Guardar estado original para restaurar

-- Colores del modo mapa
local COLORES = {
	SELECCIONADO = Color3.fromRGB(255, 255, 255),  -- Blanco
	ADYACENTE = Color3.fromRGB(255, 200, 50),      -- Dorado
	CONECTADO = Color3.fromRGB(0, 212, 255),       -- Cyan
	AISLADO = Color3.fromRGB(239, 68, 68),         -- Rojo
}

function EfectosMapa.inicializar(configNivel)
	nombresNodos = {}
	if configNivel and configNivel.NombresNodos then
		nombresNodos = configNivel.NombresNodos
	end
end

function EfectosMapa.limpiarTodo()
	print("[EfectosMapa] Limpiando todo. Partes a restaurar:", #partesOriginales)
	
	-- Restaurar todas las partes a su estado original
	for _, data in ipairs(partesOriginales) do
		if data.parte and data.parte.Parent then
			print("[EfectosMapa] Restaurando:", data.parte.Name, "Tamaño original:", data.tamanoOriginal)
			data.parte.Color = data.colorOriginal
			data.parte.Material = data.materialOriginal
			data.parte.Transparency = data.transparencyOriginal
			-- Restaurar tamaño original
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
end

function EfectosMapa.obtenerNombreAmigable(nombreNodo)
	return nombresNodos[nombreNodo] or nombreNodo
end

function EfectosMapa.esNodoConectado(nodo)
	local connections = nodo:FindFirstChild("Connections")
	if connections and #connections:GetChildren() > 0 then
		return true
	end
	
	local grafo = nodo:FindFirstAncestorOfClass("Model")
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
	-- Buscar si ya guardamos este estado
	for _, data in ipairs(partesOriginales) do
		if data.parte == parte then
			return -- Ya guardado
		end
	end
	
	-- Guardar estado original incluyendo tamaño
	-- Usar cloned values para evitar referencias
	table.insert(partesOriginales, {
		parte = parte,
		colorOriginal = parte.Color,
		materialOriginal = parte.Material,
		transparencyOriginal = parte.Transparency,
		tamanoOriginal = Vector3.new(parte.Size.X, parte.Size.Y, parte.Size.Z) -- Clonar tamaño
	})
	
	print("[EfectosMapa] Estado guardado para:", parte.Name, "Tamaño:", parte.Size)
end

function EfectosMapa.aplicarColor(nodo, color, esSeleccionado)
	local parte = EfectosMapa.obtenerParteSelector(nodo)
	if not parte then 
		warn("[EfectosMapa] No se encontró parte para nodo:", nodo.Name)
		return 
	end
	
	-- Guardar estado original si no lo hemos hecho
	EfectosMapa.guardarEstadoOriginal(parte)
	
	-- Aplicar color y material
	parte.Color = color
	parte.Material = Enum.Material.Neon
	parte.Transparency = 0.3
	
	-- Encontrar el tamaño original guardado
	local tamanoBase = nil
	for _, data in ipairs(partesOriginales) do
		if data.parte == parte then
			tamanoBase = data.tamanoOriginal
			break
		end
	end
	
	-- Si no encontramos tamaño base, usar el actual
	if not tamanoBase then
		tamanoBase = parte.Size
	end
	
	-- Aplicar tamaño: base si no está seleccionado, 1.2x si está seleccionado
	local tamanoObjetivo = esSeleccionado and (tamanoBase * 1.2) or tamanoBase
	
	print("[EfectosMapa] Aplicando tamaño a:", nodo.Name, "Base:", tamanoBase, "Objetivo:", tamanoObjetivo, "Actual:", parte.Size, "Seleccionado:", esSeleccionado)
	
	-- Cancelar tween existente si hay uno
	if parte:IsA("BasePart") then
		-- Forzar tamaño inmediato si es muy diferente (evitar acumulación)
		if (parte.Size - tamanoBase).Magnitude > (tamanoBase.Magnitude * 0.5) then
			print("[EfectosMapa] Tamaño muy diferente, forzando reset a:", tamanoBase)
			parte.Size = tamanoBase
		end
	end
	
	-- Solo hacer tween si el tamaño es diferente
	if (parte.Size - tamanoObjetivo).Magnitude > 0.01 then
		TweenService:Create(parte, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = tamanoObjetivo
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
	
	-- Destruir billboard anterior si existe
	local workspace = game:GetService("Workspace")
	local nombreAnterior = "MapaBB_" .. nodo.Name
	local anterior = workspace:FindFirstChild(nombreAnterior)
	if anterior then
		anterior:Destroy()
	end
	
	local billboard = Instance.new("BillboardGui")
	billboard.Name = nombreAnterior
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
	print("[EfectosMapa] Actualizando efectos... nivel:", nivelActual and "OK" or "NIL")
	
	if not nivelActual then 
		warn("[EfectosMapa] nivelActual es nil")
		return 
	end
	
	local grafosFolder = nivelActual:FindFirstChild("Grafos")
	if not grafosFolder then 
		warn("[EfectosMapa] No se encontró Grafos")
		return 
	end
	
	local conteoNodos = 0
	
	for _, grafo in ipairs(grafosFolder:GetChildren()) do
		local nodosFolder = grafo:FindFirstChild("Nodos")
		if nodosFolder then
			for _, nodo in ipairs(nodosFolder:GetChildren()) do
				conteoNodos = conteoNodos + 1
				local nombre = nodo.Name
				local esSeleccionado = (nodoSeleccionado and nodoSeleccionado.Name == nombre)
				local esAdyacente = adyacentes and table.find(adyacentes, nombre)
				local conectado = EfectosMapa.esNodoConectado(nodo)
				
				-- Crear billboard
				EfectosMapa.crearBillboard(nodo)
				
				-- Determinar color
				local color
				if esSeleccionado then
					color = COLORES.SELECCIONADO
					print("[EfectosMapa] Nodo", nombre, "-> SELECCIONADO (blanco)")
				elseif esAdyacente then
					color = COLORES.ADYACENTE
					print("[EfectosMapa] Nodo", nombre, "-> ADYACENTE (dorado)")
				elseif conectado then
					color = COLORES.CONECTADO
					print("[EfectosMapa] Nodo", nombre, "-> CONECTADO (cyan)")
				else
					color = COLORES.AISLADO
					print("[EfectosMapa] Nodo", nombre, "-> AISLADO (rojo)")
				end
				
				-- Aplicar color a la parte
				EfectosMapa.aplicarColor(nodo, color, esSeleccionado)
			end
		end
	end
	
	print("[EfectosMapa] Efectos actualizados para", conteoNodos, "nodos")
end

return EfectosMapa
