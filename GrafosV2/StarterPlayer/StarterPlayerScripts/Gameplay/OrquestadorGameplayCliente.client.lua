-- OrquestadorGameplayCliente.client.lua
-- UNICO responsable: Activar/desactivar TODO el gameplay visual del cliente.
--
-- Regla de Oro: Cuando volvemos al menu, TODO el gameplay visual debe desaparecer.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local jugadorLocal = Players.LocalPlayer
local camara = workspace.CurrentCamera

local OrquestadorGameplayCliente = {}

-- Referencias a sistemas
local SISTEMAS = {}
local CONEXIONES = {}

-- Estado
OrquestadorGameplayCliente.activo = false
OrquestadorGameplayCliente.idNivelActual = nil

-- ═══════════════════════════════════════════════════════════════════════════════
-- CARGAR SISTEMA SEGURO
-- ═══════════════════════════════════════════════════════════════════════════════
local function cargarSistemaSeguro(nombres, ubicacionBase)
	if not ubicacionBase then return nil end
	
	for _, nombre in ipairs(nombres) do
		local modulo = ubicacionBase:FindFirstChild(nombre)
		if modulo then
			local exito, resultado = pcall(function()
				return require(modulo)
			end)
			if exito then
				return resultado
			else
				warn("[OrquestadorGameplayCliente] Error cargando " .. nombre .. ": " .. tostring(resultado))
			end
		end
	end
	return nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- INICIALIZAR: Cargar referencias a sistemas
-- ═══════════════════════════════════════════════════════════════════════════════
function OrquestadorGameplayCliente:inicializar()
	print("[OrquestadorGameplayCliente] Inicializando...")
	
	-- Buscar carpetas
	local nucleoHUD = script.Parent:FindFirstChild("HUDModules")
	local nucleoVisual = script.Parent:FindFirstChild("VisualEffectsService")
	
	-- Cargar sistemas con nombres alternativos
	SISTEMAS.hud = cargarSistemaSeguro(
		{"HUDFade", "Fade"},
		nucleoHUD
	)
	
	-- NUEVO: Usar ControladorEfectosVisuales refactorizado
	SISTEMAS.efectosVisuales = cargarSistemaSeguro(
		{"ControladorEfectosVisuales", "VisualEffectsService"},
		script.Parent
	)
	
	-- Fallback al sistema antiguo si existe
	if not SISTEMAS.efectosVisuales and nucleoVisual then
		SISTEMAS.efectosVisuales = cargarSistemaSeguro(
			{"VisualEffectsService"},
			script.Parent
		)
	end
	
	SISTEMAS.misiones = cargarSistemaSeguro(
		{"HUDMisionPanel", "MisionPanel"},
		nucleoHUD
	)
	
	SISTEMAS.puntaje = cargarSistemaSeguro(
		{"HUDScore", "Score"},
		nucleoHUD
	)
	
	SISTEMAS.victoria = cargarSistemaSeguro(
		{"HUDVictory", "Victory"},
		nucleoHUD
	)
	
	-- Reportar
	print("[OrquestadorGameplayCliente] Sistemas cargados:")
	print("  - HUD Fade: " .. (SISTEMAS.hud and "✅" or "❌"))
	print("  - Efectos Visuales: " .. (SISTEMAS.efectosVisuales and "✅" or "❌"))
	print("  - Misiones: " .. (SISTEMAS.misiones and "✅" or "❌"))
	print("  - Puntaje: " .. (SISTEMAS.puntaje and "✅" or "❌"))
	print("  - Victoria: " .. (SISTEMAS.victoria and "✅" or "❌"))
	
	print("[OrquestadorGameplayCliente] ✅ Inicializado")
	return self
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- INICIAR GAMEPLAY: Llamado cuando recibimos LevelReady del servidor
-- ═══════════════════════════════════════════════════════════════════════════════
function OrquestadorGameplayCliente:iniciarGameplay(idNivel, datosNivel)
	if self.activo then
		print("[OrquestadorGameplayCliente] ⚠️ Gameplay ya activo, reiniciando...")
		self:detenerGameplay()
	end
	
	print("[OrquestadorGameplayCliente] ▶️ INICIAR GAMEPLAY | Nivel:", idNivel)
	
	self.activo = true
	self.idNivelActual = idNivel
	
	-- Guardar atributo para otros scripts
	jugadorLocal:SetAttribute("NivelActualID", idNivel)
	
	-- 1. Activar HUD (usando HUDFade existente)
	if SISTEMAS.hud and SISTEMAS.hud.reset then
		local exito, error = pcall(function()
			SISTEMAS.hud.reset()
		end)
		if not exito then
			warn("[OrquestadorGameplayCliente] Error reseteando HUD:", error)
		end
	end
	
	-- 2. Activar efectos visuales (limpiara cualquier cosa previa)
	if SISTEMAS.efectosVisuales then
		local exito, error = pcall(function()
			SISTEMAS.efectosVisuales:activar()
		end)
		if not exito then
			warn("[OrquestadorGameplayCliente] Error activando efectos visuales:", error)
		end
	end
	
	-- 3. Configurar camara de gameplay
	self:establecerCamaraGameplay()
	
	-- 4. Escuchar eventos del servidor
	self:conectarEventosServidor()
	
	print("[OrquestadorGameplayCliente] ✅ Gameplay visual activo")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- DETENER GAMEPLAY: Llamado cuando volvemos al menu
-- ═══════════════════════════════════════════════════════════════════════════════
function OrquestadorGameplayCliente:detenerGameplay()
	if not self.activo then
		print("[OrquestadorGameplayCliente] ⏹️ No hay gameplay activo")
		return
	end
	
	print("[OrquestadorGameplayCliente] ⏹️ DETENER GAMEPLAY")
	
	-- ORDEN INVERSO: Desconectar primero, limpiar despues
	
	-- 1. Desconectar TODOS los eventos primero (deja de escuchar)
	for _, conexion in ipairs(CONEXIONES) do
		if conexion and typeof(conexion) == "RBXScriptConnection" then
			pcall(function() conexion:Disconnect() end)
		end
	end
	CONEXIONES = {}
	
	-- 2. Desactivar efectos visuales (limpieza completa)
	if SISTEMAS.efectosVisuales then
		local exito, error = pcall(function()
			SISTEMAS.efectosVisuales:desactivar()
		end)
		if not exito then
			warn("[OrquestadorGameplayCliente] Error desactivando efectos visuales:", error)
		end
	end
	
	-- 3. Resetear HUD
	if SISTEMAS.hud and SISTEMAS.hud.reset then
		pcall(function()
			SISTEMAS.hud.reset()
		end)
	end
	
	-- 4. Ocultar pantalla de victoria si esta visible
	if SISTEMAS.victoria and SISTEMAS.victoria.hide then
		pcall(function()
			SISTEMAS.victoria.hide()
		end)
	end
	
	-- 5. Limpiar atributos
	jugadorLocal:SetAttribute("NivelActualID", nil)
	
	-- 6. Limpiar estado
	self.activo = false
	self.idNivelActual = nil
	
	print("[OrquestadorGameplayCliente] ⬛ Gameplay visual detenido")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONFIGURAR CAMARA GAMEPLAY
-- ═══════════════════════════════════════════════════════════════════════════════
function OrquestadorGameplayCliente:establecerCamaraGameplay()
	camara.CameraType = Enum.CameraType.Custom
	
	local function establecerSujeto(personaje)
		local humanoide = personaje:FindFirstChildOfClass("Humanoid")
		if humanoide then
			-- Pequeno delay para que la fisica este lista
			task.wait(0.1)
			camara.CameraSubject = humanoide
			camara.CameraType = Enum.CameraType.Custom
			print("[OrquestadorGameplayCliente] Camara → GAMEPLAY (sujeto asignado)")
		end
	end
	
	-- Si ya hay personaje, asignar inmediatamente
	if jugadorLocal.Character then
		task.spawn(function()
			establecerSujeto(jugadorLocal.Character)
		end)
	end
	
	-- Escuchar cuando spawnee nuevo personaje (RestartLevel)
	local conexion = jugadorLocal.CharacterAdded:Connect(function(nuevoPersonaje)
		task.spawn(function()
			task.wait(0.1)
			local humanoide = nuevoPersonaje:FindFirstChildOfClass("Humanoid")
				or nuevoPersonaje:WaitForChild("Humanoid", 5)
			if humanoide then
				camara.CameraType = Enum.CameraType.Custom
				camara.CameraSubject = humanoide
				print("[OrquestadorGameplayCliente] Camara → sujeto actualizado tras respawn")
			end
		end)
	end)
	
	table.insert(CONEXIONES, conexion)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONECTAR EVENTOS DEL SERVIDOR
-- ═══════════════════════════════════════════════════════════════════════════════
function OrquestadorGameplayCliente:conectarEventosServidor()
	local RS = ReplicatedStorage
	local eventsFolder = RS:WaitForChild("Events", 10)
	if not eventsFolder then return end
	
	local remotesFolder = eventsFolder:WaitForChild("Remotes", 5)
	if not remotesFolder then return end
	
	-- Evento de actualizacion de puntaje
	local actualizarPuntajeEv = remotesFolder:FindFirstChild("UpdateScore")
	if actualizarPuntajeEv and SISTEMAS.puntaje then
		local conn = actualizarPuntajeEv.OnClientEvent:Connect(function(datos)
			if not self.activo then return end
			if SISTEMAS.puntaje.set then
				pcall(function()
					SISTEMAS.puntaje.set(datos.puntajeBase or datos.puntaje or 0)
				end)
			end
		end)
		table.insert(CONEXIONES, conn)
	end
	
	-- Evento de actualizacion de misiones
	local actualizarMisionesEv = remotesFolder:FindFirstChild("UpdateMissions")
	if actualizarMisionesEv and SISTEMAS.misiones then
		local conn = actualizarMisionesEv.OnClientEvent:Connect(function(datos)
			if not self.activo then return end
			if SISTEMAS.misiones.rebuild then
				pcall(function()
					SISTEMAS.misiones.rebuild(datos)
				end)
			end
		end)
		table.insert(CONEXIONES, conn)
	end
	
	-- Evento de nivel completado (victoria)
	local nivelCompletadoEv = remotesFolder:FindFirstChild("LevelCompleted")
	if nivelCompletadoEv and SISTEMAS.victoria then
		local conn = nivelCompletadoEv.OnClientEvent:Connect(function(snapshot)
			if not self.activo then return end
			if SISTEMAS.victoria.show then
				pcall(function()
					SISTEMAS.victoria.show(snapshot)
				end)
			end
		end)
		table.insert(CONEXIONES, conn)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONSULTAS
-- ═══════════════════════════════════════════════════════════════════════════════
function OrquestadorGameplayCliente:estaActivo()
	return self.activo
end

function OrquestadorGameplayCliente:obtenerNivelActual()
	return self.idNivelActual
end

-- Inicializar automaticamente (con manejo de errores)
pcall(function()
	OrquestadorGameplayCliente:inicializar()
end)

return OrquestadorGameplayCliente
