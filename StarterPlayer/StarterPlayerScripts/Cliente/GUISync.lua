-- ================================================================
-- GUISync.client.lua
-- Sincroniza leaderstats (Puntos, Estrellas, Dinero) con la UI
-- en tiempo real
-- ================================================================

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("🔄 [GUISync] Iniciando sincronización de UI...")

-- ================================================================
-- ESPERAR A QUE LA GUI ESTÉ LISTA
-- ================================================================

local gui = playerGui:WaitForChild("GUIExplorador", 10)
if not gui then
	warn("❌ GUISync: GUIExplorador no encontrada después de 10s")
	return
end

print("✅ GUISync: GUIExplorador encontrada")

-- ================================================================
-- OBTENER REFERENCIAS A LA BARRA SUPERIOR
-- ================================================================

local barraSuperior = gui:FindFirstChild("BarraSuperior")
if not barraSuperior then
	warn("❌ GUISync: BarraSuperior no encontrada")
	return
end

local panelPuntuacion = barraSuperior:FindFirstChild("PanelPuntuacion")
if not panelPuntuacion then
	warn("❌ GUISync: PanelPuntuacion no encontrada")
	return
end

print("✅ GUISync: Paneles encontrados")

-- ================================================================
-- OBTENER REFERENCIAS A LOS LABELS
-- ================================================================

-- Contenedor de Puntos
local contenedorPuntos = panelPuntuacion:FindFirstChild("ContenedorPuntos")
local valorPuntos = nil
if contenedorPuntos then
	local marcoPuntos = contenedorPuntos:FindFirstChild("MarcoPuntos")
	if marcoPuntos then
		valorPuntos = marcoPuntos:FindFirstChild("Valor")
	end
end

-- Contenedor de Estrellas
local contenedorEstrellas = panelPuntuacion:FindFirstChild("ContenedorEstrellas")
local valorEstrellas = nil
if contenedorEstrellas then
	local marcoEstrellas = contenedorEstrellas:FindFirstChild("MarcoEstrellas")
	if marcoEstrellas then
		valorEstrellas = marcoEstrellas:FindFirstChild("Valor")
	end
end

-- Contenedor de Dinero
local contenedorDinero = panelPuntuacion:FindFirstChild("ContenedorDinero")
local valorDinero = nil
if contenedorDinero then
	local marcoDinero = contenedorDinero:FindFirstChild("MarcoDinero")
	if marcoDinero then
		valorDinero = marcoDinero:FindFirstChild("Valor")
	end
end

print("📊 GUISync: Labels encontrados")
print("   ✓ Puntos:", valorPuntos ~= nil)
print("   ✓ Estrellas:", valorEstrellas ~= nil)
print("   ✓ Dinero:", valorDinero ~= nil)

-- ================================================================
-- ESPERAR A LEADERSTATS
-- ================================================================

local stats = player:WaitForChild("leaderstats", 5)
if not stats then
	warn("❌ GUISync: leaderstats no encontrado después de 5s")
	return
end

print("✅ GUISync: leaderstats encontrado")

-- ================================================================
-- CONECTAR PUNTOS
-- ================================================================

local puntos = stats:WaitForChild("Puntos", 5)
if puntos then
	if valorPuntos then
		-- Establecer valor inicial
		valorPuntos.Text = tostring(puntos.Value)
		print("💰 [GUISync] Valor inicial de Puntos: " .. puntos.Value)

		-- Conectar a cambios futuros
		puntos.Changed:Connect(function(newValue)
			valorPuntos.Text = tostring(newValue)
			print("💰 [GUISync] Puntos actualizado a: " .. newValue)
		end)
	else
		warn("⚠️ GUISync: No se encontró label para Puntos")
	end
else
	warn("⚠️ GUISync: Puntos no encontrado en leaderstats")
end

-- ================================================================
-- CONECTAR ESTRELLAS
-- ================================================================

local estrellas = stats:WaitForChild("Estrellas", 5)
if estrellas then
	if valorEstrellas then
		-- Función para convertir número a estrellas
		local function formatearEstrellas(cantidad)
			local str = ""
			for i = 1, 3 do
				str = str .. (i <= cantidad and "⭐" or "☆")
			end
			str = str .. " (" .. cantidad .. "/3)"
			return str
		end

		-- Establecer valor inicial
		valorEstrellas.Text = formatearEstrellas(estrellas.Value)
		print("⭐ [GUISync] Valor inicial de Estrellas: " .. estrellas.Value)

		-- Conectar a cambios futuros
		estrellas.Changed:Connect(function(newValue)
			valorEstrellas.Text = formatearEstrellas(newValue)
			print("⭐ [GUISync] Estrellas actualizado a: " .. newValue)
		end)
	else
		warn("⚠️ GUISync: No se encontró label para Estrellas")
	end
else
	warn("⚠️ GUISync: Estrellas no encontrado en leaderstats")
end

-- ================================================================
-- CONECTAR DINERO
-- ================================================================

local dinero = stats:FindFirstChild("Money")
if dinero then
	if valorDinero then
		-- Establecer valor inicial
		valorDinero.Text = "$" .. tostring(dinero.Value)
		print("💵 [GUISync] Valor inicial de Dinero: " .. dinero.Value)

		-- Conectar a cambios futuros
		dinero.Changed:Connect(function(newValue)
			valorDinero.Text = "$" .. tostring(newValue)
			print("💵 [GUISync] Dinero actualizado a: " .. newValue)
		end)
	else
		warn("⚠️ GUISync: No se encontró label para Dinero")
	end
else
	warn("⚠️ GUISync: Money no encontrado en leaderstats")
end

-- ================================================================
-- CONFIRMACIÓN FINAL
-- ================================================================

print("╔════════════════════════════════════════════╗")
print("║  ✅ GUISync ACTIVO Y SINCRONIZANDO       ║")
print("║  Los cambios en leaderstats se reflejan   ║")
print("║  automáticamente en la UI                 ║")
print("╚════════════════════════════════════════════╝")