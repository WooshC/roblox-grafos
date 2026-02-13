-- ReplicatedStorage/Utilidades/NivelUtils.lua
-- Utilidades compartidas para manejo de niveles y postes
-- Mejorado para buscar en ServerStorage y clonar modelos

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))

local NivelUtils = {}

-- Cache para mejorar rendimiento
local _cacheNiveles = {}
local _cachePostes = {}

-- ============================================
-- DETECCIÓN DE NIVELES
-- ============================================

--- Obtiene el modelo de nivel desde ServerStorage (o Workspace como fallback)
--- Si está en ServerStorage, lo clona al Workspace
--- @param nivelID number
--- @return Model|nil
function NivelUtils.obtenerModeloNivel(nivelID)
	-- Verificar cache primero
	if _cacheNiveles[nivelID] then
		local cached = _cacheNiveles[nivelID]
		if cached and cached.Parent then 
			return cached 
		end
		_cacheNiveles[nivelID] = nil -- Limpiar cache si fue destruido
	end

	local config = LevelsConfig[nivelID]
	if not config then 
		warn("❌ NivelUtils: Config de nivel " .. nivelID .. " no existe")
		return nil 
	end

	local nombreModelo = config.Modelo
	if not nombreModelo then
		warn("❌ NivelUtils: Nivel " .. nivelID .. " no tiene nombre de modelo")
		return nil
	end

	local modelo = nil

	-- PRIORIDAD 1: Buscar en Workspace (si ya está cargado)
	modelo = Workspace:FindFirstChild(nombreModelo)
	if modelo then
		print("✅ NivelUtils: Modelo '" .. nombreModelo .. "' encontrado en Workspace")
		_cacheNiveles[nivelID] = modelo
		return modelo
	end

	-- PRIORIDAD 2: Buscar en ServerStorage y clonar
	print("🔍 NivelUtils: Buscando '" .. nombreModelo .. "' en ServerStorage...")

	local modeloEnStorage = ServerStorage:FindFirstChild(nombreModelo)
	if modeloEnStorage then
		print("✅ NivelUtils: Modelo '" .. nombreModelo .. "' encontrado en ServerStorage")

		-- Clonar el modelo
		modelo = modeloEnStorage:Clone()
		modelo.Name = nombreModelo  -- Mantener nombre original (o cambiar a "NivelActual" en LevelService)
		modelo.Parent = Workspace

		print("✅ NivelUtils: Modelo '" .. nombreModelo .. "' clonado a Workspace")
		_cacheNiveles[nivelID] = modelo
		return modelo
	end

	-- FALLBACK para Nivel 0: Buscar nombres alternativos
	if nivelID == 0 then
		modelo = Workspace:FindFirstChild("Nivel0_Tutorial")
		if modelo then
			_cacheNiveles[nivelID] = modelo
			return modelo
		end

		modelo = ServerStorage:FindFirstChild("Nivel0_Tutorial")
		if modelo then
			modelo = modelo:Clone()
			modelo.Parent = Workspace
			_cacheNiveles[nivelID] = modelo
			return modelo
		end
	end

	-- FALLBACK para Nivel 1: Buscar nombres alternativos
	if nivelID == 1 then
		modelo = Workspace:FindFirstChild("Nivel1")
		if modelo then
			_cacheNiveles[nivelID] = modelo
			return modelo
		end

		modelo = Workspace:FindFirstChild("Nivel1_Basico")
		if modelo then
			_cacheNiveles[nivelID] = modelo
			return modelo
		end

		modelo = ServerStorage:FindFirstChild("Nivel1")
		if modelo then
			modelo = modelo:Clone()
			modelo.Parent = Workspace
			_cacheNiveles[nivelID] = modelo
			return modelo
		end

		modelo = ServerStorage:FindFirstChild("Nivel1_Basico")
		if modelo then
			modelo = modelo:Clone()
			modelo.Parent = Workspace
			_cacheNiveles[nivelID] = modelo
			return modelo
		end
	end

	warn("❌ NivelUtils: Modelo de Nivel " .. nivelID .. " no encontrado en ServerStorage ni Workspace")
	return nil
end

--- Obtiene la carpeta de postes de un nivel
--- Busca en estructura: Nivel/Objetos/Postes
--- @param nivelID number
--- @return Folder|nil
function NivelUtils.obtenerCarpetaPostes(nivelID)
	local modelo = NivelUtils.obtenerModeloNivel(nivelID)
	if not modelo then 
		warn("❌ NivelUtils: No se pudo obtener modelo del nivel " .. nivelID)
		return nil 
	end

	-- PRIORIDAD 1: Estructura correcta Objetos/Postes
	local objetos = modelo:FindFirstChild("Objetos")
	if objetos then
		local postes = objetos:FindFirstChild("Postes")
		if postes then
			print("✅ NivelUtils: Carpeta Postes encontrada en Objetos")
			return postes
		end
		warn("⚠️ NivelUtils: Carpeta 'Postes' no existe dentro de 'Objetos'")
	end

	-- FALLBACK: Buscar "Postes" directamente en el modelo
	local postesDirect = modelo:FindFirstChild("Postes")
	if postesDirect then
		print("⚠️ NivelUtils: Usando 'Postes' directamente (estructura alternativa)")
		return postesDirect
	end

	warn("❌ NivelUtils: No se encontró carpeta 'Postes' en nivel " .. nivelID)
	print("   Estructura buscada: Nivel > Objetos > Postes")
	print("   Estructura encontrada en modelo: ")
	for _, child in ipairs(modelo:GetChildren()) do
		print("      - " .. child.Name .. " (" .. child.ClassName .. ")")
	end

	return nil
end

--- Detecta el nivel al que pertenece un poste
--- @param poste Model
--- @return number nivelID, table config
function NivelUtils.obtenerNivelDelPoste(poste)
	-- Buscar en jerarquía hacia arriba
	local ancestor = poste:FindFirstAncestor("Nivel0_Tutorial")
	if ancestor then
		return 0, LevelsConfig[0]
	end

	ancestor = poste:FindFirstAncestor("Nivel1")
	if ancestor then
		return 1, LevelsConfig[1]
	end

	ancestor = poste:FindFirstAncestor("Nivel1_Basico")
	if ancestor then
		return 1, LevelsConfig[1]
	end

	-- Buscar por nombre del modelo en config
	for nivelID, config in pairs(LevelsConfig) do
		if config.Modelo then
			ancestor = poste:FindFirstAncestor(config.Modelo)
			if ancestor then
				return nivelID, config
			end
		end
	end

	-- Fallback
	return 1, LevelsConfig[1]
end

--- Detecta el nivel activo del jugador
--- @return number nivelID, Folder|nil carpetaPostes
function NivelUtils.obtenerDatosNivelActivo()
	-- Buscar en Workspace primero
	if Workspace:FindFirstChild("Nivel1") or Workspace:FindFirstChild("Nivel1_Basico") then
		return 1, NivelUtils.obtenerCarpetaPostes(1)
	elseif Workspace:FindFirstChild("Nivel0_Tutorial") then
		return 0, NivelUtils.obtenerCarpetaPostes(0)
	elseif Workspace:FindFirstChild("NivelActual") then
		-- Buscar en el nivel actual
		local nivelActual = Workspace:FindFirstChild("NivelActual")
		if nivelActual then
			-- Intentar detectar cuál es
			local objetos = nivelActual:FindFirstChild("Objetos")
			if objetos then
				local postes = objetos:FindFirstChild("Postes")
				if postes then
					return 1, postes  -- Asumir nivel 1 por defecto
				end
			end
		end
	end

	-- Fallback
	return 1, NivelUtils.obtenerCarpetaPostes(1)
end

-- ============================================
-- BÚSQUEDA DE POSTES Y CABLES
-- ============================================

--- Encuentra un poste por nombre en un nivel específico
--- @param nombrePoste string
--- @param nivelID number
--- @return Model|nil
function NivelUtils.buscarPoste(nombrePoste, nivelID)
	local cacheKey = nivelID .. "_" .. nombrePoste

	-- Verificar cache
	if _cachePostes[cacheKey] then
		local cached = _cachePostes[cacheKey]
		if cached and cached.Parent then 
			return cached 
		end
		_cachePostes[cacheKey] = nil
	end

	local carpeta = NivelUtils.obtenerCarpetaPostes(nivelID)
	if not carpeta then 
		warn("❌ NivelUtils: No se pudo obtener carpeta de postes para nivel " .. nivelID)
		return nil 
	end

	local poste = carpeta:FindFirstChild(nombrePoste)
	if poste then
		_cachePostes[cacheKey] = poste
		return poste
	end

	warn("⚠️ NivelUtils: Poste '" .. nombrePoste .. "' no encontrado en nivel " .. nivelID)
	return nil
end

--- Busca un cable (RopeConstraint) entre dos postes
--- @param nodoA string
--- @param nodoB string
--- @param nivelID number
--- @return RopeConstraint|nil
function NivelUtils.buscarCable(nodoA, nodoB, nivelID)
	local carpetaPostes = NivelUtils.obtenerCarpetaPostes(nivelID)
	if not carpetaPostes then return nil end

	-- Buscar en workspace (los cables están sueltos o en carpeta Conexiones)
	local modelo = NivelUtils.obtenerModeloNivel(nivelID)
	if not modelo then return nil end

	-- PRIORIDAD 1: Buscar en carpeta Conexiones del modelo
	local carpetaConexiones = modelo:FindFirstChild("Objetos")
	if carpetaConexiones then
		carpetaConexiones = carpetaConexiones:FindFirstChild("Conexiones")
		if carpetaConexiones then
			for _, cable in ipairs(carpetaConexiones:GetChildren()) do
				if cable:IsA("RopeConstraint") then
					local p1 = cable.Attachment0 and cable.Attachment0.Parent and cable.Attachment0.Parent.Parent
					local p2 = cable.Attachment1 and cable.Attachment1.Parent and cable.Attachment1.Parent.Parent

					if p1 and p2 then
						if (p1.Name == nodoA and p2.Name == nodoB) or 
							(p1.Name == nodoB and p2.Name == nodoA) then
							return cable
						end
					end
				end
			end
		end
	end

	-- PRIORIDAD 2: Buscar en workspace (los cables pueden estar sueltos)
	for _, obj in ipairs(Workspace:GetChildren()) do
		if obj:IsA("RopeConstraint") and obj.Attachment0 and obj.Attachment1 then
			local p1 = obj.Attachment0.Parent and obj.Attachment0.Parent.Parent
			local p2 = obj.Attachment1.Parent and obj.Attachment1.Parent.Parent

			if p1 and p2 then
				if (p1.Name == nodoA and p2.Name == nodoB) or 
					(p1.Name == nodoB and p2.Name == nodoA) then
					-- Verificar que pertenecen al nivel correcto
					local nivelP1 = NivelUtils.obtenerNivelDelPoste(p1)
					if nivelP1 == nivelID then
						return obj
					end
				end
			end
		end
	end

	return nil
end

--- Obtiene todos los cables de un nivel
--- @param nivelID number
--- @return table array de RopeConstraints
function NivelUtils.obtenerCablesDelNivel(nivelID)
	local cables = {}
	local modelo = NivelUtils.obtenerModeloNivel(nivelID)
	if not modelo then return cables end

	-- Buscar en carpeta Conexiones dentro del modelo
	local carpetaConexiones = modelo:FindFirstChild("Objetos")
	if carpetaConexiones then
		carpetaConexiones = carpetaConexiones:FindFirstChild("Conexiones")
		if carpetaConexiones then
			for _, cable in ipairs(carpetaConexiones:GetChildren()) do
				if cable:IsA("RopeConstraint") then
					table.insert(cables, cable)
				end
			end
		end
	end

	-- También buscar en workspace por si hay sueltos
	for _, obj in ipairs(Workspace:GetChildren()) do
		if obj:IsA("RopeConstraint") and obj.Attachment0 and obj.Attachment1 then
			local p1 = obj.Attachment0.Parent and obj.Attachment0.Parent.Parent

			if p1 then
				local nivelP1 = NivelUtils.obtenerNivelDelPoste(p1)
				if nivelP1 == nivelID then
					table.insert(cables, obj)
				end
			end
		end
	end

	return cables
end

-- ============================================
-- SPAWN LOCATIONS
-- ============================================

--- Busca el SpawnLocation de un nivel con prioridad correcta
--- @param nivelID number
--- @return Vector3|nil posición de spawn
function NivelUtils.obtenerPosicionSpawn(nivelID)
	local modelo = NivelUtils.obtenerModeloNivel(nivelID)
	if not modelo then return nil end

	local config = LevelsConfig[nivelID]
	local spawnLoc = nil

	-- 1. PRIORIDAD MÁXIMA: Buscar SpawnLocation por CLASE
	for _, child in ipairs(modelo:GetDescendants()) do
		if child:IsA("SpawnLocation") then
			spawnLoc = child
			break
		end
	end

	-- 2. Buscar por nombre "Spawn"
	if not spawnLoc then
		for _, child in ipairs(modelo:GetDescendants()) do
			if string.find(child.Name, "Spawn") then
				spawnLoc = child
				break
			end
		end
	end

	-- 3. Calcular posición
	if spawnLoc then
		if spawnLoc:IsA("BasePart") then
			return spawnLoc.Position + Vector3.new(0, 5, 0)
		elseif spawnLoc:IsA("Model") then
			return spawnLoc:GetPivot().Position + Vector3.new(0, 5, 0)
		end
	end

	-- 4. ÚLTIMO RECURSO: Usar generador (NodoInicio)
	if config and config.NodoInicio then
		local posteInicio = NivelUtils.buscarPoste(config.NodoInicio, nivelID)
		if posteInicio then
			if posteInicio:IsA("Model") then
				return posteInicio:GetPivot().Position + Vector3.new(5, 5, 5)
			elseif posteInicio:IsA("BasePart") then
				return posteInicio.Position + Vector3.new(5, 5, 5)
			end
		end
	end

	return nil
end

-- ============================================
-- VALIDACIONES
-- ============================================

--- Verifica si un jugador puede modificar un nivel
--- @param player Player
--- @param nivelID number
--- @return boolean
function NivelUtils.puedeModificarNivel(player, nivelID)
	local stats = player:FindFirstChild("leaderstats")
	local nivelJugador = stats and stats:FindFirstChild("Nivel") and stats.Nivel.Value or 0
	return nivelJugador == nivelID
end

--- Verifica si una conexión es válida según las adyacencias
--- @param nodoA string
--- @param nodoB string
--- @param nivelID number
--- @return boolean
function NivelUtils.esConexionValida(nodoA, nodoB, nivelID)
	local config = LevelsConfig[nivelID]
	if not config or not config.Adyacencias then return false end

	local permitidos = config.Adyacencias[nodoA]
	if not permitidos then return false end

	for _, nombreDestino in ipairs(permitidos) do
		if nombreDestino == nodoB then
			return true
		end
	end

	return false
end

-- ============================================
-- LIMPIEZA DE CACHE
-- ============================================

--- Limpia el cache (útil al cambiar de nivel)
function NivelUtils.limpiarCache()
	_cacheNiveles = {}
	_cachePostes = {}
	print("🧹 NivelUtils: Cache limpiado")
end

-- ============================================
-- DEBUG
-- ============================================

--- Imprime información de debug sobre los niveles
function NivelUtils.debug()
	print("\n📊 ===== DEBUG NivelUtils =====")

	print("\n📁 Contenido de ServerStorage:")
	for _, child in ipairs(ServerStorage:GetChildren()) do
		print("   - " .. child.Name .. " (" .. child.ClassName .. ")")
	end

	print("\n📁 Contenido de Workspace:")
	for _, child in ipairs(Workspace:GetChildren()) do
		if string.match(child.Name, "^Nivel") or child.Name == "NivelActual" then
			print("   - " .. child.Name .. " (" .. child.ClassName .. ")")
		end
	end

	print("\n===== Fin DEBUG =====\n")
end

return NivelUtils