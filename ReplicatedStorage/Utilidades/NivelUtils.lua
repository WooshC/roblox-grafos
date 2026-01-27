-- NivelUtils.lua
-- Utilidades compartidas para manejo de niveles y postes
-- Evita duplicación de código entre scripts

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))

local NivelUtils = {}

-- Cache para mejorar rendimiento
local _cacheNiveles = {}
local _cachePostes = {}

-- ============================================
-- DETECCIÓN DE NIVELES
-- ============================================

--- Obtiene el modelo de nivel desde workspace
--- @param nivelID number
--- @return Model|nil
function NivelUtils.obtenerModeloNivel(nivelID)
	if _cacheNiveles[nivelID] then
		local cached = _cacheNiveles[nivelID]
		if cached.Parent then return cached end
		_cacheNiveles[nivelID] = nil -- Limpiar cache si fue destruido
	end
	
	local config = LevelsConfig[nivelID]
	if not config then return nil end
	
	local modelo = workspace:FindFirstChild(config.Modelo)
	
	-- Fallback para Nivel 1
	if not modelo and nivelID == 1 then
		modelo = workspace:FindFirstChild("Nivel1")
	end
	
	if modelo then
		_cacheNiveles[nivelID] = modelo
	end
	
	return modelo
end

--- Obtiene la carpeta de postes de un nivel
--- @param nivelID number
--- @return Folder|nil
function NivelUtils.obtenerCarpetaPostes(nivelID)
	local modelo = NivelUtils.obtenerModeloNivel(nivelID)
	if not modelo then return nil end
	
	local objetos = modelo:FindFirstChild("Objetos")
	if not objetos then return nil end
	
	return objetos:FindFirstChild("Postes")
end

--- Detecta el nivel al que pertenece un poste
--- @param poste Model
--- @return number nivelID, table config
function NivelUtils.obtenerNivelDelPoste(poste)
	-- Buscar en jerarquía
	if poste:FindFirstAncestor("Nivel0_Tutorial") then
		return 0, LevelsConfig[0]
	elseif poste:FindFirstAncestor("Nivel1") or poste:FindFirstAncestor("Nivel1_Basico") then
		return 1, LevelsConfig[1]
	else
		-- Fallback
		return 1, LevelsConfig[1]
	end
end

--- Detecta el nivel activo del jugador
--- @return number nivelID, Folder|nil carpetaPostes
function NivelUtils.obtenerDatosNivelActivo()
	if workspace:FindFirstChild("Nivel1") or workspace:FindFirstChild("Nivel1_Basico") then
		return 1, NivelUtils.obtenerCarpetaPostes(1)
	elseif workspace:FindFirstChild("Nivel0_Tutorial") then
		return 0, NivelUtils.obtenerCarpetaPostes(0)
	else
		return 1, NivelUtils.obtenerCarpetaPostes(1)
	end
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
	
	if _cachePostes[cacheKey] then
		local cached = _cachePostes[cacheKey]
		if cached.Parent then return cached end
		_cachePostes[cacheKey] = nil
	end
	
	local carpeta = NivelUtils.obtenerCarpetaPostes(nivelID)
	if not carpeta then return nil end
	
	local poste = carpeta:FindFirstChild(nombrePoste)
	if poste then
		_cachePostes[cacheKey] = poste
	end
	
	return poste
end

--- Busca un cable (RopeConstraint) entre dos postes
--- @param nodoA string
--- @param nodoB string
--- @param nivelID number
--- @return RopeConstraint|nil
function NivelUtils.buscarCable(nodoA, nodoB, nivelID)
	local carpetaPostes = NivelUtils.obtenerCarpetaPostes(nivelID)
	if not carpetaPostes then return nil end
	
	-- Buscar en workspace (los cables están sueltos)
	for _, obj in ipairs(workspace:GetChildren()) do
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
	local carpetaPostes = NivelUtils.obtenerCarpetaPostes(nivelID)
	if not carpetaPostes then return cables end
	
	for _, obj in ipairs(workspace:GetChildren()) do
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
end

return NivelUtils
