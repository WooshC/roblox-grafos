-- SistemaCamara.lua
-- UNIFICADO: Un solo lugar para controlar la camara en todos los estados.
--
-- Estados:
--   - MENU: Camara estatica cinematica
--   - GAMEPLAY: Camara sigue al jugador
--   - MAPA: Camara cenital del mapa

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local SistemaCamara = {}

-- Estados validos
SistemaCamara.Estado = {
	MENU     = "menu",
	GAMEPLAY = "gameplay",
	MAPA     = "mapa",
}

-- Variables de estado
SistemaCamara.estadoActual = nil
SistemaCamara.conexionLimpieza = nil
SistemaCamara.conexionSeguimiento = nil
SistemaCamara.estadoOriginal = nil

-- Configuracion
SistemaCamara.config = {
	alturaCamaraMapa = 80,
	velocidadTween = 0.4,
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- ESTABLECER MENU: Camara estatica en posicion cinematica
-- ═══════════════════════════════════════════════════════════════════════════════
function SistemaCamara:establecerMenu()
	if self.estadoActual == self.Estado.MENU then 
		print("[SistemaCamara] Ya en MENU")
		return 
	end
	
	self:_limpiarEstadoAnterior()
	print("[SistemaCamara] ▶️ Cambiando a MENU")
	
	local camara = workspace.CurrentCamera
	local objetoCamaraMenu = workspace:FindFirstChild("CamaraMenu", true)
	
	camara.CameraType = Enum.CameraType.Scriptable
	
	if objetoCamaraMenu then
		local cframeObjetivo
		if objetoCamaraMenu:IsA("BasePart") then
			cframeObjetivo = objetoCamaraMenu.CFrame
		elseif objetoCamaraMenu:IsA("Model") and objetoCamaraMenu.PrimaryPart then
			cframeObjetivo = objetoCamaraMenu.PrimaryPart.CFrame
		end
		
		if cframeObjetivo then
			-- Tween suave a la posicion
			local tween = TweenService:Create(camara, TweenInfo.new(self.config.velocidadTween), {
				CFrame = cframeObjetivo
			})
			tween:Play()
		end
	else
		warn("[SistemaCamara] ⚠️ CamaraMenu no encontrada en workspace")
	end
	
	self.estadoActual = self.Estado.MENU
	print("[SistemaCamara] ✅ MENU activo")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- ESTABLECER GAMEPLAY: Camara sigue al jugador
-- ═══════════════════════════════════════════════════════════════════════════════
function SistemaCamara:establecerGameplay(jugador)
	jugador = jugador or Players.LocalPlayer
	if not jugador then
		warn("[SistemaCamara] ❌ No hay jugador para establecer gameplay")
		return
	end
	
	if self.estadoActual == self.Estado.GAMEPLAY then 
		print("[SistemaCamara] Ya en GAMEPLAY")
		return 
	end
	
	self:_limpiarEstadoAnterior()
	print("[SistemaCamara] ▶️ Cambiando a GAMEPLAY")
	
	local camara = workspace.CurrentCamera
	
	-- Guardar estado anterior si venimos de menu
	if self.estadoActual == self.Estado.MENU then
		self.estadoOriginal = {
			cameraType = camara.CameraType,
			cframe = camara.CFrame,
		}
	end
	
	local function establecerSujeto(personaje)
		local humanoide = personaje:FindFirstChildOfClass("Humanoid")
		if humanoide then
			camara.CameraType = Enum.CameraType.Custom
			camara.CameraSubject = humanoide
			print("[SistemaCamara]   ✓ Sujeto asignado:", personaje.Name)
		else
			warn("[SistemaCamara] ⚠️ No se encontro Humanoid en", personaje.Name)
		end
	end
	
	-- Si ya hay personaje, asignar inmediatamente
	if jugador.Character then
		task.spawn(function()
			task.wait(0.1) -- Pequeno delay para fisica
			establecerSujeto(jugador.Character)
		end)
	end
	
	-- Escuchar futuros spawns (RestartLevel)
	self.conexionLimpieza = jugador.CharacterAdded:Connect(function(nuevoPersonaje)
		task.spawn(function()
			task.wait(0.1)
			local humanoide = nuevoPersonaje:FindFirstChildOfClass("Humanoid")
				or nuevoPersonaje:WaitForChild("Humanoid", 5)
			if humanoide then
				camara.CameraType = Enum.CameraType.Custom
				camara.CameraSubject = humanoide
				print("[SistemaCamara]   ✓ Sujeto actualizado tras respawn")
			end
		end)
	end)
	
	self.estadoActual = self.Estado.GAMEPLAY
	print("[SistemaCamara] ✅ GAMEPLAY activo")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- ESTABLECER MAPA: Vista cenital que sigue al jugador
-- ═══════════════════════════════════════════════════════════════════════════════
function SistemaCamara:establecerMapa(nivelModelo, jugador)
	jugador = jugador or Players.LocalPlayer
	
	if self.estadoActual == self.Estado.MAPA then 
		print("[SistemaCamara] Ya en MAPA")
		return 
	end
	
	self:_limpiarEstadoAnterior()
	print("[SistemaCamara] ▶️ Cambiando a MAPA")
	
	local camara = workspace.CurrentCamera
	
	-- Calcular bounds del nivel
	local bounds = self:calcularLimites(nivelModelo)
	if not bounds then
		warn("[SistemaCamara] ❌ No se pudieron calcular limites del nivel")
		return
	end
	
	-- Calcular posicion cenital
	local altura = math.max(bounds.tamano.X, bounds.tamano.Z) * 0.6 + 50
	local cframeObjetivo = CFrame.new(
		bounds.centro.X, 
		bounds.max.Y + altura, 
		bounds.centro.Z
	) * CFrame.Angles(math.rad(-90), 0, 0)
	
	-- Tween a posicion
	camara.CameraType = Enum.CameraType.Scriptable
	local tween = TweenService:Create(camara, TweenInfo.new(self.config.velocidadTween), {
		CFrame = cframeObjetivo
	})
	tween:Play()
	
	-- Iniciar seguimiento del jugador
	if jugador then
		self.conexionSeguimiento = RunService.RenderStepped:Connect(function()
			if not jugador.Character then return end
			local raiz = jugador.Character:FindFirstChild("HumanoidRootPart")
			if not raiz then return end
			
			-- Mantener altura pero seguir posicion X,Z del jugador
			camara.CFrame = CFrame.new(
				raiz.Position.X,
				bounds.max.Y + altura,
				raiz.Position.Z
			) * CFrame.Angles(math.rad(-90), 0, 0)
		end)
	end
	
	self.estadoActual = self.Estado.MAPA
	print("[SistemaCamara] ✅ MAPA activo")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CALCULAR LIMITES DEL NIVEL
-- ═══════════════════════════════════════════════════════════════════════════════
function SistemaCamara:calcularLimites(nivelModelo)
	if not nivelModelo then return nil end
	
	local min = Vector3.new(math.huge, math.huge, math.huge)
	local max = Vector3.new(-math.huge, -math.huge, -math.huge)
	local conteoPartes = 0
	
	for _, parte in ipairs(nivelModelo:GetDescendants()) do
		if parte:IsA("BasePart") then
			conteoPartes = conteoPartes + 1
			min = Vector3.new(
				math.min(min.X, parte.Position.X - parte.Size.X/2),
				math.min(min.Y, parte.Position.Y - parte.Size.Y/2),
				math.min(min.Z, parte.Position.Z - parte.Size.Z/2)
			)
			max = Vector3.new(
				math.max(max.X, parte.Position.X + parte.Size.X/2),
				math.max(max.Y, parte.Position.Y + parte.Size.Y/2),
				math.max(max.Z, parte.Position.Z + parte.Size.Z/2)
			)
		end
	end
	
	if conteoPartes == 0 then return nil end
	
	return {
		centro = (min + max) / 2,
		tamano = max - min,
		min = min,
		max = max,
		conteoPartes = conteoPartes,
	}
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- LIMPIAR ESTADO ANTERIOR
-- ═══════════════════════════════════════════════════════════════════════════════
function SistemaCamara:_limpiarEstadoAnterior()
	-- Desconectar conexiones
	if self.conexionLimpieza then
		self.conexionLimpieza:Disconnect()
		self.conexionLimpieza = nil
	end
	
	if self.conexionSeguimiento then
		self.conexionSeguimiento:Disconnect()
		self.conexionSeguimiento = nil
	end
	
	print("[SistemaCamara] 🧹 Estado anterior limpiado")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONSULTAS
-- ═══════════════════════════════════════════════════════════════════════════════
function SistemaCamara:obtenerEstado()
	return self.estadoActual
end

function SistemaCamara:estaEnMenu()
	return self.estadoActual == self.Estado.MENU
end

function SistemaCamara:estaEnGameplay()
	return self.estadoActual == self.Estado.GAMEPLAY
end

function SistemaCamara:estaEnMapa()
	return self.estadoActual == self.Estado.MAPA
end

return SistemaCamara
