-- ReplicatedStorage/Compartido/ServicioCamara.lua
-- Servicio centralizado para control de cámara
-- Usado por: ModuloMapa, ControladorDialogo, y otros sistemas que necesiten controlar la cámara

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local ServicioCamara = {}

-- Estado
local estadoOriginal = nil
local enTransicion = false

-- ═══════════════════════════════════════════════════════════════════════════════
-- FUNCIONES AUXILIARES
-- ═══════════════════════════════════════════════════════════════════════════════

---Obtiene la posición de un punto de enfoque (string, BasePart, Model, Vector3)
function ServicioCamara.obtenerPosicion(enfoque)
	if typeof(enfoque) == "Vector3" then
		return enfoque
	elseif typeof(enfoque) == "string" then
		-- Buscar nodo con ese nombre
		local nivel = Workspace:FindFirstChild("NivelActual")
		if nivel then
			local nodo = nivel:FindFirstChild(enfoque, true)
			if nodo then
				-- Si es un Model, buscar el Selector
				if nodo:IsA("Model") then
					local selector = nodo:FindFirstChild("Selector")
					if selector and selector:IsA("BasePart") then
						return selector.Position
					else
						return nodo:GetPivot().Position
					end
				elseif nodo:IsA("BasePart") then
					return nodo.Position
				end
			end
		end
		end
	elseif enfoque and enfoque:IsA("BasePart") then
		return enfoque.Position
	elseif enfoque and enfoque:IsA("Model") then
		local selector = enfoque:FindFirstChild("Selector")
		if selector and selector:IsA("BasePart") then
			return selector.Position
		else
			return enfoque:GetPivot().Position
		end
	end
	return nil
end

---Guarda el estado actual de la cámara
function ServicioCamara.guardarEstado()
	local camara = Workspace.CurrentCamera
	estadoOriginal = {
		CFrame = camara.CFrame,
		CameraType = camara.CameraType,
		CameraSubject = camara.CameraSubject
	}
	return estadoOriginal
end

---Obtiene el estado guardado (sin guardar nuevo)
function ServicioCamara.obtenerEstadoGuardado()
	return estadoOriginal
end

---Verifica si hay un estado guardado
function ServicioCamara.tieneEstadoGuardado()
	return estadoOriginal ~= nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- MOVIMIENTO DE CÁMARA
-- ═══════════════════════════════════════════════════════════════════════════════

---Mueve la cámara a un CFrame específico con animación
-- @param cframeObjetivo CFrame - Posición objetivo
-- @param duracion number - Duración de la transición (default: 0.5)
-- @param suave boolean - Si usar easing suave (default: true)
-- @param onComplete function - Callback al terminar (opcional)
function ServicioCamara.moverA(cframeObjetivo, duracion, suave, onComplete)
	duracion = duracion or 0.5
	suave = suave ~= false -- true por defecto
	
	if enTransicion then
		warn("[ServicioCamara] Ya hay una transición en curso")
	end
	
	local camara = Workspace.CurrentCamera
	enTransicion = true
	
	-- Guardar estado si no está guardado
	if not estadoOriginal then
		ServicioCamara.guardarEstado()
	end
	
	-- Cambiar a Scriptable
	camara.CameraType = Enum.CameraType.Scriptable
	
	-- Animar
	task.spawn(function()
		local inicio = tick()
		local cframeInicial = camara.CFrame
		
		while tick() - inicio < duracion do
			local alpha = (tick() - inicio) / duracion
			if suave then
				alpha = math.sin(alpha * math.pi / 2) -- Easing suave
			end
			camara.CFrame = cframeInicial:Lerp(cframeObjetivo, alpha)
			task.wait(0.016)
		end
		
		camara.CFrame = cframeObjetivo
		enTransicion = false
		
		if onComplete then
			onComplete()
		end
	end)
end

---Mueve la cámara a una posición TOP-DOWN (cenital) sobre un objetivo
-- @param enfoque any - string (nombre nodo), Vector3, BasePart, o Model
-- @param altura number - Altura sobre el objetivo (default: 13)
-- @param duracion number - Duración de la transición (default: 0.8)
function ServicioCamara.moverTopDown(enfoque, altura, duracion)
	altura = altura or 13
	
	local posicionObjetivo = ServicioCamara.obtenerPosicion(enfoque)
	if not posicionObjetivo then
		warn("[ServicioCamara] No se pudo obtener posición del enfoque:", enfoque)
		return false
	end
	
	local posicionCamara = posicionObjetivo + Vector3.new(0, altura, 0)
	local nuevoCFrame = CFrame.lookAt(posicionCamara, posicionObjetivo)
	
	ServicioCamara.moverA(nuevoCFrame, duracion, true)
	return true
end

---Restaura la cámara a su estado original
-- @param duracion number - Duración de la transición (default: 0.5)
function ServicioCamara.restaurar(duracion)
	duracion = duracion or 0.5
	
	if not estadoOriginal then
		warn("[ServicioCamara] No hay estado guardado para restaurar")
		Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
		return
	end
	
	if enTransicion then
		-- Esperar a que termine la transición actual
		repeat task.wait(0.016) until not enTransicion
	end
	
	local camara = Workspace.CurrentCamera
	enTransicion = true
	
	-- Animar restauración
	task.spawn(function()
		local inicio = tick()
		local cframeInicial = camara.CFrame
		local cframeFinal = estadoOriginal.CFrame
		
		while tick() - inicio < duracion do
			local alpha = (tick() - inicio) / duracion
			alpha = math.sin(alpha * math.pi / 2)
			camara.CFrame = cframeInicial:Lerp(cframeFinal, alpha)
			task.wait(0.016)
		end
		
		camara.CFrame = cframeFinal
		camara.CameraType = estadoOriginal.CameraType
		camara.CameraSubject = estadoOriginal.CameraSubject
		
		enTransicion = false
		estadoOriginal = nil -- Limpiar estado después de restaurar
	end)
end

---Restauración inmediata (sin animación)
function ServicioCamara.restaurarInmediato()
	if not estadoOriginal then
		Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
		return
	end
	
	local camara = Workspace.CurrentCamera
	camara.CFrame = estadoOriginal.CFrame
	camara.CameraType = estadoOriginal.CameraType
	camara.CameraSubject = estadoOriginal.CameraSubject
	
	enTransicion = false
	estadoOriginal = nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN RÁPIDA
-- ═══════════════════════════════════════════════════════════════════════════════

---Configura la cámara para modo Scriptable (bloqueo sin mover)
function ServicioCamara.bloquear()
	local camara = Workspace.CurrentCamera
	if not estadoOriginal then
		ServicioCamara.guardarEstado()
	end
	camara.CameraType = Enum.CameraType.Scriptable
end

---Libera la cámara (vuelve a Custom)
function ServicioCamara.liberar()
	Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONSULTA DE ESTADO
-- ═══════════════════════════════════════════════════════════════════════════════

function ServicioCamara.estaEnTransicion()
	return enTransicion
end

function ServicioCamara.obtenerCFrame()
	return Workspace.CurrentCamera.CFrame
end

function ServicioCamara.obtenerTipo()
	return Workspace.CurrentCamera.CameraType
end

return ServicioCamara
