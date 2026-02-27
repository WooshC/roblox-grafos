-- CameraEffects.lua
-- Efectos de cámara y techo para el mapa

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CameraEffects = {}

-- Estado del techo
CameraEffects.techoValoresOriginales = {}
CameraEffects.techoCapturado = false
CameraEffects.techoEstaOculto = false

-- Estado de cámara
CameraEffects.originalState = nil

-- ================================================================
-- FUNCIONES DEL TECHO (Integradas de MapManager antiguo)
-- ================================================================

function CameraEffects.captureRoof(nivelModel)
	if CameraEffects.techoCapturado then return end
	if not nivelModel then return end

	-- Buscar en nueva estructura: Escenario/Colisionadores/Techos
	local escenario = nivelModel:FindFirstChild("Escenario")
	if escenario then
		local colisionadores = escenario:FindFirstChild("Colisionadores")
		if colisionadores then
			local techosFolder = colisionadores:FindFirstChild("Techos")
			if techosFolder then
				for _, part in ipairs(techosFolder:GetChildren()) do
					if part:IsA("BasePart") then
						CameraEffects.techoValoresOriginales[part] = {
							Transparency = part.Transparency,
							CastShadow = part.CastShadow,
							CanQuery = part.CanQuery,
						}
					end
				end
			end
		end
	end

	-- Fallback: buscar folder Techos directo o por nombre
	if next(CameraEffects.techoValoresOriginales) == nil then
		local techosFolder = nivelModel:FindFirstChild("Techos")
		if techosFolder then
			for _, part in ipairs(techosFolder:GetChildren()) do
				if part:IsA("BasePart") then
					CameraEffects.techoValoresOriginales[part] = {
						Transparency = part.Transparency,
						CastShadow = part.CastShadow,
						CanQuery = part.CanQuery,
					}
				end
			end
		end

		-- Buscar por nombre en todo el nivel
		for _, part in ipairs(nivelModel:GetDescendants()) do
			if part:IsA("BasePart") and (part.Name:lower():find("techo") or part.Name:lower():find("roof")) then
				if not CameraEffects.techoValoresOriginales[part] then
					CameraEffects.techoValoresOriginales[part] = {
						Transparency = part.Transparency,
						CastShadow = part.CastShadow,
						CanQuery = part.CanQuery,
					}
				end
			end
		end
	end

	CameraEffects.techoCapturado = true
	print("[CameraEffects] Techos capturados:", #CameraEffects.techoValoresOriginales)
end

function CameraEffects.hideRoof()
	if CameraEffects.techoEstaOculto then return end
	if not CameraEffects.techoCapturado then return end

	for part, orig in pairs(CameraEffects.techoValoresOriginales) do
		if part and part.Parent then
			part.Transparency = 0.95
			part.CastShadow = false
			part.CanQuery = false
		end
	end

	CameraEffects.techoEstaOculto = true
	print("[CameraEffects] Techos ocultados")
end

function CameraEffects.showRoof()
	if not CameraEffects.techoEstaOculto then return end

	for part, orig in pairs(CameraEffects.techoValoresOriginales) do
		if part and part.Parent then
			part.Transparency = orig.Transparency
			part.CastShadow = orig.CastShadow
			part.CanQuery = orig.CanQuery
		end
	end

	CameraEffects.techoEstaOculto = false
	print("[CameraEffects] Techos restaurados")
end

function CameraEffects.resetRoof()
	CameraEffects.techoValoresOriginales = {}
	CameraEffects.techoCapturado = false
	CameraEffects.techoEstaOculto = false
end

-- ================================================================
-- FUNCIONES DE CÁMARA
-- ================================================================

function CameraEffects.saveState(camera)
	if not camera then return end

	CameraEffects.originalState = {
		CFrame = camera.CFrame,
		CameraType = camera.CameraType,
		CameraSubject = camera.CameraSubject
	}

	return CameraEffects.originalState
end

function CameraEffects.restoreState(camera)
	if not camera or not CameraEffects.originalState then return end

	camera.CameraType = CameraEffects.originalState.CameraType
	camera.CameraSubject = CameraEffects.originalState.CameraSubject
	camera.CFrame = CameraEffects.originalState.CFrame

	CameraEffects.originalState = nil
end

function CameraEffects.tweenToMapView(camera, targetCFrame, onComplete)
	if not camera then return end

	camera.CameraType = Enum.CameraType.Scriptable

	local tween = TweenService:Create(camera, TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut), {
		CFrame = targetCFrame
	})

	if onComplete then
		tween.Completed:Once(onComplete)
	end

	tween:Play()
	return tween
end

function CameraEffects.tweenToPlayerView(camera, targetCFrame, onComplete)
	if not camera then return end

	local tween = TweenService:Create(camera, TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut), {
		CFrame = targetCFrame
	})

	tween.Completed:Once(function()
		if CameraEffects.originalState then
			camera.CameraType = CameraEffects.originalState.CameraType
			camera.CameraSubject = CameraEffects.originalState.CameraSubject
		end
		if onComplete then
			onComplete()
		end
	end)

	tween:Play()
	return tween
end

function CameraEffects.calculateMapBounds(nivelModel)
	if not nivelModel then return nil end

	local boundsMin = Vector3.new(math.huge, math.huge, math.huge)
	local boundsMax = Vector3.new(-math.huge, -math.huge, -math.huge)
	local partCount = 0

	for _, part in ipairs(nivelModel:GetDescendants()) do
		if part:IsA("BasePart") then
			partCount = partCount + 1
			boundsMin = Vector3.new(
				math.min(boundsMin.X, part.Position.X - part.Size.X/2),
				math.min(boundsMin.Y, part.Position.Y - part.Size.Y/2),
				math.min(boundsMin.Z, part.Position.Z - part.Size.Z/2)
			)
			boundsMax = Vector3.new(
				math.max(boundsMax.X, part.Position.X + part.Size.X/2),
				math.max(boundsMax.Y, part.Position.Y + part.Size.Y/2),
				math.max(boundsMax.Z, part.Position.Z + part.Size.Z/2)
			)
		end
	end

	if partCount == 0 then return nil end

	local centro = (boundsMin + boundsMax) / 2
	local tamanio = boundsMax - boundsMin

	return {
		Center = centro,
		Size = tamanio,
		Min = boundsMin,
		Max = boundsMax,
		PartCount = partCount
	}
end

function CameraEffects.calculateOverheadCFrame(bounds, alturaAdicional)
	if not bounds then return nil end

	alturaAdicional = alturaAdicional or 50
	local altura = math.max(bounds.Size.X, bounds.Size.Z) * 0.6 + alturaAdicional

	return CFrame.new(bounds.Center.X, bounds.Max.Y + altura, bounds.Center.Z) * 
		CFrame.Angles(math.rad(-90), 0, 0)
end

function CameraEffects.followPlayer(camera, playerPosition, altura)
	altura = altura or 80
	camera.CFrame = CFrame.new(playerPosition + Vector3.new(0, altura, 0), playerPosition)
end

return CameraEffects