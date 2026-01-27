-- GestorObjetos.server.lua
-- REEMPLAZO DE ObjetosColeccionables.server.lua
-- Sistema de recolección de objetos en el nivel

print("🚀 GESTOR DE OBJETOS INICIANDO v3.0...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Intentar cargar módulos con pcall por seguridad
local success, result = pcall(function()
	return {
		LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig", 10)),
		InventoryManager = require(ReplicatedStorage:WaitForChild("Utilidades"):WaitForChild("InventoryManager", 10)),
		NivelUtils = require(ReplicatedStorage:WaitForChild("Utilidades"):WaitForChild("NivelUtils", 10))
	}
end)

if not success then
	warn("❌ ERROR CARGANDO MÓDULOS EN GESTOR OBJETOS: " .. tostring(result))
	return -- Abortar si fallan los módulos
end

local Modulos = result
local LevelsConfig = Modulos.LevelsConfig
local InventoryManager = Modulos.InventoryManager
local NivelUtils = Modulos.NivelUtils

print("✅ Módulos cargados correctamente en GestorObjetos")

-- Inicializar inventario
InventoryManager.init()

-- ============================================
-- GESTIÓN DE OBJETOS COLECCIONABLES
-- ============================================

--- Configura un objeto coleccionable
local function configurarObjeto(objetoModel, objetoConfig, nivelID)
	-- Buscar o crear ProximityPrompt
	local prompt = objetoModel:FindFirstChild("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "ProximityPrompt"
		prompt.ActionText = "Recoger " .. objetoConfig.Nombre
		prompt.ObjectText = objetoConfig.Icono .. " " .. objetoConfig.Nombre
		prompt.HoldDuration = 0.5
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = objetoModel
	else
		-- Actualizar existente
		prompt.ActionText = "Recoger " .. objetoConfig.Nombre
		prompt.ObjectText = objetoConfig.Icono .. " " .. objetoConfig.Nombre
		prompt.Enabled = true
	end
	
	-- Listener para recolección (Evitar múltiples conexiones)
	if objetoModel:GetAttribute("Conectado") then return end
	objetoModel:SetAttribute("Conectado", true)

	prompt.Triggered:Connect(function(player)
		-- Verificar que el jugador esté en el nivel correcto
		local stats = player:FindFirstChild("leaderstats")
		local nivelJugador = stats and stats:FindFirstChild("Nivel") and stats.Nivel.Value or 0
		
		if nivelJugador ~= nivelID then
			print("⚠️ " .. player.Name .. " intentó recoger objeto de otro nivel")
			return
		end
		
		-- Agregar al inventario
		InventoryManager.agregarObjeto(player, objetoConfig.ID)
		
		-- Efecto visual: OCULTAR en vez de Destroy
		ocultarObjeto(objetoModel)
		
		print("✅ " .. player.Name .. " recogió: " .. objetoConfig.Nombre)
	end)
	
	objetoModel:SetAttribute("ObjetoID", objetoConfig.ID)
end

--- Inicializa objetos de un nivel al cargar
local function inicializarObjetosNivel(nivelID)
	local config = LevelsConfig[nivelID]
	if not config or not config.Objetos then return end
	
	local nivelModel = NivelUtils.obtenerModeloNivel(nivelID)
	if not nivelModel then return end
	
	-- Buscar carpeta de objetos (Soporte para ambos nombres)
	local carpetaObjetos = nivelModel:FindFirstChild("ObjetosColeccionables")
	if not carpetaObjetos then
		carpetaObjetos = nivelModel:FindFirstChild("Items") -- Fallback
	end
	
	if not carpetaObjetos then 
		print("⚠️ [GestorObjetos] No se encontró carpeta 'ObjetosColeccionables' o 'Items' en Nivel " .. nivelID)
		return 
	end
	
	print("🎁 Inicializando objetos coleccionables para Nivel " .. nivelID)
	
	-- Configurar cada objeto que ya exista físicamente
	for _, objetoConfig in ipairs(config.Objetos) do
		-- Buscamos por nombre de modelo
		local modeloNombre = objetoConfig.Modelo or objetoConfig.ID
		local objetoModel = carpetaObjetos:FindFirstChild(modeloNombre)
		
		print("   🔎 Buscando objeto: " .. modeloNombre .. " (ID: " .. objetoConfig.ID .. ")")
		
		if objetoModel then
			print("      ✅ ENCONTRADO el modelo: " .. modeloNombre)
			configurarObjeto(objetoModel, objetoConfig, nivelID)
			
			-- Asegurar visibilidad completa (Recursiva)
			for _, v in ipairs(objetoModel:GetDescendants()) do
				if v:IsA("BasePart") then v.Transparency = 0 end
				if v:IsA("ProximityPrompt") then v.Enabled = true end
			end
			
			-- Si es el Mapa, ocultarlo inicialmente (esperar a evento)
			if objetoConfig.ID == "Mapa" then
				print("      👻 Ocultando Mapa inicialmente...")
				for _, v in ipairs(objetoModel:GetDescendants()) do
					if v:IsA("BasePart") then v.Transparency = 1 end
					if v:IsA("ProximityPrompt") then v.Enabled = false end
				end
			end
		else
			warn("      ❌ NO SE ENCONTRÓ el modelo: " .. modeloNombre .. " en la carpeta " .. carpetaObjetos.Name)
		end
	end
end

-- ============================================
-- EVENTOS PARA APARECER OBJETOS (Scripting)
-- ============================================

-- ============================================
-- EVENTOS PARA APARECER OBJETOS (Scripting)
-- ============================================

local Events = ReplicatedStorage:WaitForChild("Events")
local Remotes = Events:WaitForChild("Remotes")
local Bindables = Events:WaitForChild("Bindables")

local eventoAparecer = Remotes:WaitForChild("AparecerObjeto")
local eventoDesbloquear = Bindables:WaitForChild("DesbloquearObjeto")
local eventoRestaurar = Bindables:WaitForChild("RestaurarObjetos")

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

local function ocultarObjeto(modelo)
	modelo:SetAttribute("Recolectado", true)
	
	local prompt = modelo:FindFirstChild("ProximityPrompt")
	if prompt then prompt.Enabled = false end
	
	for _, child in ipairs(modelo:GetDescendants()) do
		if child:IsA("BasePart") or child:IsA("Decal") or child:IsA("Texture") then
			-- Guardar transparencia original si no existe
			if not child:GetAttribute("OriginalTransparency") then
				child:SetAttribute("OriginalTransparency", child.Transparency)
			end
			child.Transparency = 1
		end
	end
end

local function restaurarObjetoVisual(modelo)
	modelo:SetAttribute("Recolectado", false)
	modelo:SetAttribute("Conectado", false) -- Permitir reconexión de eventos si fuera necesario (aunque aquí es una sola vez)
	
	local prompt = modelo:FindFirstChild("ProximityPrompt")
	if prompt then prompt.Enabled = true end
	
	for _, child in ipairs(modelo:GetDescendants()) do
		if child:IsA("BasePart") or child:IsA("Decal") or child:IsA("Texture") then
			local original = child:GetAttribute("OriginalTransparency")
			if original then
				child.Transparency = original
			else
				child.Transparency = 0 -- Fallback default
			end
		end
	end
end

eventoAparecer.OnServerEvent:Connect(function(player, nivelID, objetoID)
	-- Verificar si ya lo tiene
	if InventoryManager.tieneObjeto(player, objetoID) then
		return
	end
	
	print("✨ Solicitud de aparición recibida para: " .. tostring(objetoID))
	
	-- Disparar evento local
	eventoDesbloquear:Fire(objetoID, nivelID)
end)

-- 🟢 EVENTO RESTAURAR: Reactivar objetos al reiniciar nivel
eventoRestaurar.Event:Connect(function(nivelID)
	print("♻️ Restaurando objetos visuales para Nivel " .. nivelID)
	
	local config = LevelsConfig[nivelID]
	if not config then return end
	
	local nivelModel = NivelUtils.obtenerModeloNivel(nivelID)
	if not nivelModel then return end
	
	-- Buscar carpetas de objetos
	local carpetas = {nivelModel:FindFirstChild("ObjetosColeccionables"), nivelModel:FindFirstChild("Items")}
	
	for _, carpeta in ipairs(carpetas) do
		if carpeta then
			for _, objeto in ipairs(carpeta:GetChildren()) do
				if objeto:IsA("Model") then
					-- Solo restaurar si estaba recolectado
					if objeto:GetAttribute("Recolectado") == true then
						restaurarObjetoVisual(objeto)
					end
					
					-- Caso especial: Mapa (siempre oculto al inicio)
					if objeto:GetAttribute("ObjetoID") == "Mapa" then
						-- El mapa se mantiene oculto hasta desbloquearlo, o se restaura a su estado "listo para recoger"?
						-- Si se reinicia el nivel, el jugador pierde el mapa, así que debe aparecer para recogerse de nuevo
						-- pero si la logica original lo ocultaba...
						-- Asumimos que "Restaurar" lo deja listo para recoger.
						
						-- Si el objeto Mapa requiere un evento especial para aparecer inicialmente (DesbloquearObjeto),
						-- entonces deberíamos ocultarlo de nuevo.
						-- Revisar lógica inicial:
						-- if objetoConfig.ID == "Mapa" then ... Ocultando Mapa inicialmente ... end
						
						-- POR SIMPLICIDAD: Lo dejamos visible (listo para recoger) si es parte del reinicio normal,
						-- SALVO que el juego requiera gatillarlo.
						-- Como se borró del inventario, el usuario debe poder recogerlo.
						-- Si estaba invisible por defecto, ocultarlo.
						
						-- TODO: Verificar lógica específica del Mapa. Por ahora, restaurar lo hace visible.
					end
				end
			end
		end
	end
end)

-- Listener del Prompt modificado para usar Ocultar en vez de Destroy
-- (Esta función se llama dentro de configurarObjeto)
local function conectarLogicaRecoleccion(prompt, objetoModel, objetoConfig, nivelID)
	prompt.Triggered:Connect(function(player)
		local stats = player:FindFirstChild("leaderstats")
		local nivelJugador = stats and stats:FindFirstChild("Nivel") and stats.Nivel.Value or 0
		
		if nivelJugador ~= nivelID then
			print("⚠️ Nivel incorrecto")
			return
		end
		
		InventoryManager.agregarObjeto(player, objetoConfig.ID)
		
		-- REEMPLAZO DE DESTROY:
		ocultarObjeto(objetoModel)
		
		print("✅ " .. player.Name .. " recogió: " .. objetoConfig.Nombre)
	end)
end


-- ============================================
-- INIT
-- ============================================

-- Inicialización automática eliminada para dar control a scripts individuales


Players.PlayerAdded:Connect(function(player)
	InventoryManager.inicializarJugador(player)
	player.CharacterAdded:Connect(function()
		task.wait(1)
		InventoryManager.sincronizarConCliente(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	InventoryManager.limpiarJugador(player)
end)

print("✅ GESTOR DE OBJETOS CARGADO (ServerScriptService ROOT)")
