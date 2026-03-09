-- ReplicatedStorage/Compartido/ServicioCamara.lua
-- Servicio centralizado para control de cámara
-- Usado por: ModuloMapa, ControladorDialogo, y otros sistemas que necesiten controlar la cámara

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local ServicioCamara = {}

-- Estado
local estadoOriginal = nil
local enTransicion   = false
local _taskActual    = nil  -- handle del task.spawn de la transición activa

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
	
	-- Cancelar transición anterior si existe
	if _taskActual then
		task.cancel(_taskActual)
		_taskActual    = nil
		enTransicion   = false
	end

	local camara = Workspace.CurrentCamera
	enTransicion = true

	-- Guardar estado si no está guardado
	if not estadoOriginal then
		ServicioCamara.guardarEstado()
		print("[ServicioCamara] Estado guardado antes de mover")
	end

	-- Cambiar a Scriptable
	camara.CameraType = Enum.CameraType.Scriptable

	print("[ServicioCamara] Moviendo cámara a:", cframeObjetivo.Position, "Duración:", duracion)

	-- Animar en tarea independiente; guardar handle para poder cancelar
	_taskActual = task.spawn(function()
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
		_taskActual   = nil

		print("[ServicioCamara] Cámara movida exitosamente")

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
	local nuevoCFrame = CFrame.new(posicionCamara) * CFrame.Angles(math.rad(-90), 0, 0)

	ServicioCamara.moverA(nuevoCFrame, duracion, true)
	return true
end

---Mueve la cámara hacia un objetivo con altura y ángulo configurables.
-- Soporta desde vista completamente cenital hasta vistas inclinadas/cinematográficas.
--
-- @param enfoque any - string (nombre nodo), Vector3, BasePart, o Model
-- @param opciones table:
--   altura    number  (default 13) — altura de la cámara por encima del objetivo
--   angulo    number  (default 90) — ángulo de elevación en grados:
--                                     90 = cenital (top-down puro)
--                                     60 = 60° (inclinado, estilo estrategia)
--                                     45 = isométrico
--                                     30 = más horizontal, cinematográfico
--   distancia number  (default 0)  — desplazamiento horizontal adicional (aleja la cámara)
--   duracion  number  (default 0.8)
--   suave     bool    (default true)
--   onComplete function (opcional) — callback al terminar la animación
--
-- Ejemplos:
--   ServicioCamara.moverHaciaObjetivo("Nodo1_z1", { altura=20, angulo=90 })  -- cenital
--   ServicioCamara.moverHaciaObjetivo("Nodo1_z1", { altura=15, angulo=60 })  -- inclinado
--   ServicioCamara.moverHaciaObjetivo("Nodo1_z1", { altura=10, angulo=45, distancia=5 }) -- isométrico + offset
function ServicioCamara.moverHaciaObjetivo(enfoque, opciones)
	opciones = opciones or {}
	local altura    = opciones.altura    or 13
	local angulo    = opciones.angulo    or 90
	local distancia = opciones.distancia or 0
	local duracion  = opciones.duracion  or 0.8

	local posObjetivo = ServicioCamara.obtenerPosicion(enfoque)
	if not posObjetivo then
		warn("[ServicioCamara] moverHaciaObjetivo: no se pudo obtener posición:", tostring(enfoque))
		return false
	end

	-- Para que el vector cámara→objetivo forme el ángulo de elevación pedido,
	-- la distancia horizontal necesaria es: d = altura * cos(angulo) / sin(angulo)
	local rad  = math.rad(angulo)
	local sinA = math.sin(rad)
	local cosA = math.cos(rad)
	local d_back = (sinA > 0.02) and (altura * cosA / sinA) or 0

	local posicionCamara = posObjetivo + Vector3.new(0, altura, d_back + distancia)

	local nuevoCFrame
	if angulo >= 85 then
		-- Cerca de cenital: orientación explícita para evitar artefacto de CFrame.lookAt
		nuevoCFrame = CFrame.new(posicionCamara) * CFrame.Angles(math.rad(-90), 0, 0)
	else
		nuevoCFrame = CFrame.lookAt(posicionCamara, posObjetivo)
	end

	ServicioCamara.moverA(nuevoCFrame, duracion, opciones.suave ~= false, opciones.onComplete)
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
	
	print("[ServicioCamara] Restaurando cámara...")

	-- Cancelar transición activa (evita esperar y elimina riesgo de deadlock)
	if _taskActual then
		task.cancel(_taskActual)
		_taskActual  = nil
		enTransicion = false
	end

	-- Si aún hay transición en curso (no tenemos handle), esperar con timeout de 2s
	if enTransicion then
		local t0 = tick()
		while enTransicion and (tick() - t0) < 2 do
			task.wait(0.016)
		end
		if enTransicion then
			warn("[ServicioCamara] restaurar: timeout esperando transición — forzando restauración")
			enTransicion = false
		end
	end

	local camara = Workspace.CurrentCamera
	enTransicion = true

	-- Animar restauración
	_taskActual = task.spawn(function()
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

		enTransicion  = false
		_taskActual   = nil
		estadoOriginal = nil -- Limpiar estado después de restaurar

		print("[ServicioCamara] Cámara restaurada exitosamente")
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
