-- ReplicatedStorage/Utilidades/NivelUtils.lua
-- Utilidades compartidas para manejo de niveles y postes
-- CLIENTE Y SERVIDOR
-- Solo lectura de Workspace, no gestiona cargas ni ServerStorage

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))

local NivelUtils = {}

-- Cache para mejorar rendimiento de búsqueda
local _cachePostes = {}

-- ============================================
-- DETECCIÓN Y HELPER FUNCIONES
-- ============================================

--- Obtiene el modelo de nivel ACTIVO en Workspace
--- NO CARGA ni CLONA, solo busca lo que ya existe
--- @param nivelID number (Opcional, si es nil busca cualquiera)
--- @return Model|nil
function NivelUtils.obtenerModeloNivel(nivelID)
	-- Verificar si existe el estándar "NivelActual"
	local nivelActual = Workspace:FindFirstChild("NivelActual")
	if nivelActual then return nivelActual end

	-- Fallback: Buscar por nombre específico si tenemos ID
	if nivelID then
		local config = LevelsConfig[nivelID]
		if config and config.Modelo then
			local modelo = Workspace:FindFirstChild(config.Modelo)
			if modelo then return modelo end
		end

		-- Fallback legacy
		if nivelID == 0 then return Workspace:FindFirstChild("Nivel0_Tutorial") end
		if nivelID == 1 then return Workspace:FindFirstChild("Nivel1") or Workspace:FindFirstChild("Nivel1_Basico") end
	end

	-- Búsqueda genérica si no hay ID o no se encontró
	for _, child in ipairs(Workspace:GetChildren()) do
		if string.match(child.Name, "^Nivel") then
			return child
		end
	end

	return nil
end

--- Obtiene la carpeta de postes de un nivel
--- Busca en estructura: Nivel/Objetos/Postes
--- @param nivelID number (Opcional)
--- @return Folder|nil
function NivelUtils.obtenerCarpetaPostes(nivelID)
	local modelo = NivelUtils.obtenerModeloNivel(nivelID)
	if not modelo then return nil end

	-- PRIORIDAD 1: Estructura correcta Objetos/Postes
	local objetos = modelo:FindFirstChild("Objetos")
	if objetos then
		local postes = objetos:FindFirstChild("Postes")
		if postes then return postes end
	end

	-- FALLBACK: Buscar "Postes" directamente en el modelo
	local postesDirect = modelo:FindFirstChild("Postes")
	if postesDirect then return postesDirect end

	return nil
end

--- Detecta el nivel al que pertenece un poste
--- @param poste Model
--- @return number nivelID, table config
function NivelUtils.obtenerNivelDelPoste(poste)
	-- Buscar ancestro común
	local ancestro = poste:FindFirstAncestor("NivelActual")

	-- Si no está en "NivelActual", buscar nombres específicos
	if not ancestro then
		for nivelID, config in pairs(LevelsConfig) do
			if config.Modelo then
				ancestro = poste:FindFirstAncestor(config.Modelo)
				if ancestro then return nivelID, config end
			end
		end
	end

	-- Si encontramos ancestro genérico, intentar deducir
	return 0, LevelsConfig[0] -- Default seguro
end

-- ============================================
-- BÚSQUEDA DE POSTES Y CABLES
-- ============================================

--- Encuentra un poste por nombre en un nivel específico
--- @param nombrePoste string
--- @param nivelID number
--- @return Model|nil
function NivelUtils.buscarPoste(nombrePoste, nivelID)
	local cacheKey = (nivelID or "curr") .. "_" .. nombrePoste

	if _cachePostes[cacheKey] and _cachePostes[cacheKey].Parent then
		return _cachePostes[cacheKey]
	end

	local carpeta = NivelUtils.obtenerCarpetaPostes(nivelID)
	if not carpeta then return nil end

	local poste = carpeta:FindFirstChild(nombrePoste)
	if poste then
		_cachePostes[cacheKey] = poste
		return poste
	end

	return nil
end

--- Busca un cable (RopeConstraint) entre dos postes
--- @param nodoA string
--- @param nodoB string
--- @param nivelID number (opcional)
--- @return RopeConstraint|nil
function NivelUtils.buscarCable(nodoA, nodoB, nivelID)
	local cables = NivelUtils.obtenerCablesDelNivel(nivelID)

	for _, cable in ipairs(cables) do
		local att0 = cable.Attachment0
		local att1 = cable.Attachment1

		if att0 and att1 then
			local p1 = att0.Parent and att0.Parent.Parent
			local p2 = att1.Parent and att1.Parent.Parent

			if p1 and p2 then
				if (p1.Name == nodoA and p2.Name == nodoB) or 
					(p1.Name == nodoB and p2.Name == nodoA) then
					return cable
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

	-- 1. Buscar objeto SpawnLocation
	for _, child in ipairs(modelo:GetDescendants()) do
		if child:IsA("SpawnLocation") then
			return child.Position + Vector3.new(0, 5, 0)
		end
	end

	-- 2. Buscar por nombre "Spawn"
	local spawnObj = modelo:FindFirstChild("Spawn", true)
	if spawnObj and spawnObj:IsA("BasePart") then
		return spawnObj.Position + Vector3.new(0, 5, 0)
	end

	-- 3. Usar generador (NodoInicio)
	local config = LevelsConfig[nivelID]
	if config and config.NodoInicio then
		local posteInicio = NivelUtils.buscarPoste(config.NodoInicio, nivelID)
		if posteInicio then
			if posteInicio:IsA("Model") then
				return posteInicio:GetPivot().Position + Vector3.new(5, 5, 5)
			else
				return posteInicio.Position + Vector3.new(5, 5, 5)
			end
		end
	end

	return nil
end

-- ============================================
-- VALIDACIONES
-- ============================================

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
-- UTILIDADES
-- ============================================

function NivelUtils.limpiarCache()
	_cachePostes = {}
end

return NivelUtils