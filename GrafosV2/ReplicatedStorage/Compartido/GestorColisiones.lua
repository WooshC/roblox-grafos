-- GestorColisiones.lua
-- UNICO responsable: Gestionar visibilidad de techos y colisiones.
--
-- Funciones:
--   - capturar(): Guardar estado original de techos
--   - ocultarTecho(): Hacer techos invisibles/pasables
--   - restaurar(): Volver al estado original
--   - liberar(): Limpiar referencias

local GestorColisiones = {}

-- Variables de estado
GestorColisiones.estadosGuardados = {}
GestorColisiones.estaCapturado = false
GestorColisiones.estaOculto = false

-- Configuracion
GestorColisiones.config = {
	transparenciaOculta = 0.95,
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- CAPTURAR: Guardar estado original de techos del nivel
-- ═══════════════════════════════════════════════════════════════════════════════
function GestorColisiones:capturar(nivelModelo)
	if not nivelModelo then
		warn("[GestorColisiones] ❌ No se proporciono modelo de nivel")
		return
	end
	
	-- Limpiar captura previa
	self:liberar()
	
	local techos = self:_buscarTechos(nivelModelo)
	
	for _, parte in ipairs(techos) do
		self.estadosGuardados[parte] = {
			transparencia = parte.Transparency,
			castShadow = parte.CastShadow,
			canCollide = parte.CanCollide,
			canQuery = parte.CanQuery,
		}
	end
	
	self.estaCapturado = true
	print(string.format("[GestorColisiones] ✅ Capturados %d techos", #techos))
	return #techos
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- BUSCAR TECHOS: Encontrar todas las partes que son techos
-- ═══════════════════════════════════════════════════════════════════════════════
function GestorColisiones:_buscarTechos(nivelModelo)
	local techos = {}
	
	-- Buscar en estructura nueva: Escenario/Colisionadores/Techos
	local escenario = nivelModelo:FindFirstChild("Escenario")
	if escenario then
		local colisionadores = escenario:FindFirstChild("Colisionadores")
		if colisionadores then
			local carpetaTechos = colisionadores:FindFirstChild("Techos")
			if carpetaTechos then
				for _, parte in ipairs(carpetaTechos:GetChildren()) do
					if parte:IsA("BasePart") then
						table.insert(techos, parte)
					end
				end
			end
		end
	end
	
	-- Fallback: buscar carpeta Techos directa
	if #techos == 0 then
		local carpetaTechos = nivelModelo:FindFirstChild("Techos")
		if carpetaTechos then
			for _, parte in ipairs(carpetaTechos:GetChildren()) do
				if parte:IsA("BasePart") then
					table.insert(techos, parte)
				end
			end
		end
	end
	
	-- Fallback: buscar por nombre en todo el nivel
	if #techos == 0 then
		for _, parte in ipairs(nivelModelo:GetDescendants()) do
			if parte:IsA("BasePart") then
				local nombreMinuscula = parte.Name:lower()
				if nombreMinuscula:find("techo") or nombreMinuscula:find("roof") or 
				   nombreMinuscula:find("ceiling") or nombreMinuscula:find("techo") then
					table.insert(techos, parte)
				end
			end
		end
	end
	
	return techos
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- OCULTAR TECHO: Hacer techos invisibles y pasables (para vista de mapa)
-- ═══════════════════════════════════════════════════════════════════════════════
function GestorColisiones:ocultarTecho()
	if not self.estaCapturado then
		warn("[GestorColisiones] ⚠️ No hay techos capturados. Llamar capturar() primero.")
		return
	end
	
	if self.estaOculto then
		print("[GestorColisiones] Techos ya estan ocultos")
		return
	end
	
	local conteo = 0
	for parte, original in pairs(self.estadosGuardados) do
		if parte and parte.Parent then
			parte.Transparency = self.config.transparenciaOculta
			parte.CastShadow = false
			parte.CanQuery = false
			-- No cambiamos CanCollide para evitar que el jugador caiga al vacio
			conteo = conteo + 1
		end
	end
	
	self.estaOculto = true
	print(string.format("[GestorColisiones] ✅ %d techos ocultados", conteo))
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- RESTAURAR: Volver al estado original
-- ═══════════════════════════════════════════════════════════════════════════════
function GestorColisiones:restaurar()
	if not self.estaCapturado then
		warn("[GestorColisiones] ⚠️ No hay techos capturados")
		return
	end
	
	if not self.estaOculto then
		print("[GestorColisiones] Techos no estaban ocultos")
		return
	end
	
	local conteo = 0
	for parte, original in pairs(self.estadosGuardados) do
		if parte and parte.Parent then
			parte.Transparency = original.transparencia
			parte.CastShadow = original.castShadow
			parte.CanCollide = original.canCollide
			parte.CanQuery = original.canQuery
			conteo = conteo + 1
		end
	end
	
	self.estaOculto = false
	print(string.format("[GestorColisiones] ✅ %d techos restaurados", conteo))
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- LIBERAR: Limpiar referencias (llamar al salir del nivel)
-- ═══════════════════════════════════════════════════════════════════════════════
function GestorColisiones:liberar()
	-- Restaurar primero si estan ocultos
	if self.estaOculto then
		self:restaurar()
	end
	
	self.estadosGuardados = {}
	self.estaCapturado = false
	self.estaOculto = false
	
	print("[GestorColisiones] 🧹 Referencias liberadas")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONSULTAS
-- ═══════════════════════════════════════════════════════════════════════════════
function GestorColisiones:tieneTechosCapturados()
	return self.estaCapturado
end

function GestorColisiones:obtenerConteoTechos()
	local conteo = 0
	for _ in pairs(self.estadosGuardados) do
		conteo = conteo + 1
	end
	return conteo
end

return GestorColisiones
