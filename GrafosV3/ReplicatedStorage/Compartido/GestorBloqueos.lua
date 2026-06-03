-- GestorBloqueos.lua
-- UNICO responsable: Gestionar bloqueos/muros del nivel (captura y eliminacion).
--
-- Funciones:
--   - capturar(): Guardar referencias a bloqueos del nivel
--   - eliminar(nombre): Destruir un bloqueo por nombre
--   - eliminarPorDialogo(dialogoID): Eliminar bloqueos configurados para un dialogo
--   - eliminarPorZona(zonaNombre): Eliminar bloqueos configurados al completar una zona
--   - liberar(): Limpiar referencias

local GestorBloqueos = {}

-- Variables de estado
GestorBloqueos.bloqueos = {}
GestorBloqueos.estaCapturado = false

-- ═══════════════════════════════════════════════════════════════════════════════
-- CAPTURAR: Guardar referencias a bloqueos del nivel
-- ═══════════════════════════════════════════════════════════════════════════════
function GestorBloqueos:capturar(nivelModelo)
	if not nivelModelo then
		warn("[GestorBloqueos] No se proporciono modelo de nivel")
		return
	end

	-- Limpiar captura previa
	self:liberar()

	local bloqueos = self:_buscarBloqueos(nivelModelo)

	for _, parte in ipairs(bloqueos) do
		self.bloqueos[parte.Name] = parte
	end

	self.estaCapturado = true
	print(string.format("[GestorBloqueos] Capturados %d bloqueos", #bloqueos))
	return #bloqueos
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- BUSCAR BLOQUEOS: Encontrar todas las partes o modelos que son bloqueos
-- ═══════════════════════════════════════════════════════════════════════════════
function GestorBloqueos:_buscarBloqueos(nivelModelo)
	local bloqueos = {}

	-- Buscar en estructura: Escenario/Colisionadores/Bloqueos
	local escenario = nivelModelo:FindFirstChild("Escenario")
	if escenario then
		local colisionadores = escenario:FindFirstChild("Colisionadores")
		if colisionadores then
			local carpetaBloqueos = colisionadores:FindFirstChild("Bloqueos")
			if carpetaBloqueos then
				for _, parte in ipairs(carpetaBloqueos:GetChildren()) do
					if parte:IsA("BasePart") or parte:IsA("Model") then
						table.insert(bloqueos, parte)
					end
				end
			end
		end
	end

	-- Fallback: buscar carpeta Bloqueos directa
	if #bloqueos == 0 then
		local carpetaBloqueos = nivelModelo:FindFirstChild("Bloqueos")
		if carpetaBloqueos then
			for _, parte in ipairs(carpetaBloqueos:GetChildren()) do
				if parte:IsA("BasePart") or parte:IsA("Model") then
					table.insert(bloqueos, parte)
				end
			end
		end
	end

	return bloqueos
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- ELIMINAR: Destruir un bloqueo por nombre
-- ═══════════════════════════════════════════════════════════════════════════════
function GestorBloqueos:eliminar(nombre)
	if not self.estaCapturado then
		warn("[GestorBloqueos] No hay bloqueos capturados. Llamar capturar() primero.")
		return false
	end

	local parte = self.bloqueos[nombre]
	if parte and parte.Parent then
		parte:Destroy()
		self.bloqueos[nombre] = nil
		print(string.format("[GestorBloqueos] Bloqueo eliminado: %s", nombre))
		return true
	else
		warn(string.format("[GestorBloqueos] Bloqueo no encontrado: %s", nombre))
		return false
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- ELIMINAR POR DIALOGO: Eliminar bloqueos configurados para un dialogo especifico
-- ═══════════════════════════════════════════════════════════════════════════════
function GestorBloqueos:eliminarPorDialogo(dialogoID)
	if not self.estaCapturado then
		warn("[GestorBloqueos] No hay bloqueos capturados.")
		return
	end

	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local jugador = Players.LocalPlayer
	if not jugador then return end

	local nivelID = jugador:GetAttribute("CurrentLevelID") or 0
	local LevelsConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("LevelsConfig"))
	local config = LevelsConfig[nivelID]
	if not config or not config.Bloqueos then return end

	local eliminados = 0
	for nombreBloqueo, condicion in pairs(config.Bloqueos) do
		if type(condicion) == "table" and condicion.Dialogo == dialogoID then
			if self:eliminar(nombreBloqueo) then
				eliminados = eliminados + 1
			end
		end
	end

	if eliminados > 0 then
		print(string.format("[GestorBloqueos] %d bloqueo(s) eliminado(s) por dialogo '%s'", eliminados, dialogoID))
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- ELIMINAR POR ZONA: Eliminar bloqueos configurados al completar una zona
-- ═══════════════════════════════════════════════════════════════════════════════
function GestorBloqueos:eliminarPorZona(zonaNombre)
	if not self.estaCapturado then
		warn("[GestorBloqueos] No hay bloqueos capturados.")
		return
	end

	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local jugador = Players.LocalPlayer
	if not jugador then return end

	local nivelID = jugador:GetAttribute("CurrentLevelID") or 0
	local LevelsConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("LevelsConfig"))
	local config = LevelsConfig[nivelID]
	if not config or not config.Bloqueos then return end

	local eliminados = 0
	for nombreBloqueo, condicion in pairs(config.Bloqueos) do
		if type(condicion) == "table" and condicion.Zona == zonaNombre then
			if self:eliminar(nombreBloqueo) then
				eliminados = eliminados + 1
			end
		end
	end

	if eliminados > 0 then
		print(string.format("[GestorBloqueos] %d bloqueo(s) eliminado(s) por zona '%s'", eliminados, zonaNombre))
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- LIBERAR: Limpiar referencias (llamar al salir del nivel)
-- ═══════════════════════════════════════════════════════════════════════════════
function GestorBloqueos:liberar()
	self.bloqueos = {}
	self.estaCapturado = false
	print("[GestorBloqueos] Referencias liberadas")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONSULTAS
-- ═══════════════════════════════════════════════════════════════════════════════
function GestorBloqueos:tieneBloqueosCapturados()
	return self.estaCapturado
end

function GestorBloqueos:obtenerConteoBloqueos()
	local conteo = 0
	for _ in pairs(self.bloqueos) do
		conteo = conteo + 1
	end
	return conteo
end

return GestorBloqueos
