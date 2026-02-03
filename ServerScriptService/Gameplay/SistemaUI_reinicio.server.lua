-- SistemaUI.server.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LevelsConfig = require(ReplicatedStorage:WaitForChild("LevelsConfig"))
local InventoryManager = require(ReplicatedStorage:WaitForChild("Utilidades"):WaitForChild("InventoryManager"))

-- 1. CREAR EVENTO REMOTO (Backend)
-- 1. REFERENCIA A EVENTOS ESTÁTICOS
local Events = ReplicatedStorage:WaitForChild("Events")
local Remotes = Events:WaitForChild("Remotes")
local Bindables = Events:WaitForChild("Bindables")

local remoteEvent = Remotes:WaitForChild("ReiniciarNivel")

-- La GUI ahora se maneja desde el Cliente (StarterPlayerScripts)

-- =======================================================
-- INICIALIZACIÓN DE EVENTOS PARA SCRIPTS INDIVIDUALES
-- =======================================================
local eventsFolder = ReplicatedStorage:WaitForChild("Events")
local bindables = eventsFolder:WaitForChild("Bindables")
local remotes = eventsFolder:WaitForChild("Remotes")

-- Referencias a Eventos Estandarizados
local eventoRestaurar = bindables:WaitForChild("RestaurarObjetos")
local eventoDesbloquear = bindables:WaitForChild("DesbloquearObjeto")

-- Soporte Legacy (Opcional: Si existe la carpeta antigua, la usamos de puente, sino no)
local serverEvents = ReplicatedStorage:FindFirstChild("ServerEvents")
local eventoLegacy = nil
if serverEvents then
	eventoLegacy = serverEvents:FindFirstChild("RestaurarObjetos")
end

print("✅ SistemaUI: Eventos inicializados correctamente (Estándar).")


-- 3. LÓGICA DEL SERVIDOR (RESETEAR)
remoteEvent.OnServerEvent:Connect(function(player)
	print("🔄 SOLICITUD DE REINICIO RECIBIDA:", player.Name)
	
	-- 1. Obtener Nivel Actual
	local nivelID = 1 -- Default
	local stats = player:FindFirstChild("leaderstats")
	if stats and stats:FindFirstChild("Nivel") then
		nivelID = stats.Nivel.Value
	end
	
	-- 2. Restablecer dinero según configuración del Nivel
	local config = LevelsConfig[nivelID] or LevelsConfig[0]
	local dineroBase = config.DineroInicial or 2000
	
	if stats and stats:FindFirstChild("Money") then
		stats.Money.Value = dineroBase
		print("💰 Dinero restablecido a $" .. dineroBase .. " (Nivel " .. nivelID .. ")")
	end
	
	-- Resetear Puntos y Estrellas del nivel actual
	if stats then
		if stats:FindFirstChild("Puntos") then
			stats.Puntos.Value = 0
		end
		if stats:FindFirstChild("Estrellas") then
			stats.Estrellas.Value = 0
		end
		print("⭐ Puntaje y estrellas reseteados")
	end
	
	-- Resetear objetos del nivel actual
	if config.Objetos then
		local objetosIDs = {}
		for _, obj in ipairs(config.Objetos) do
			table.insert(objetosIDs, obj.ID)
		end
		InventoryManager.resetearNivel(player, nivelID, objetosIDs)
	end
	
	-- 3. Eliminar cables visuales
	-- (Esto borra todos los del workspace por simplicidad, pero está bien ya que limpia fantasmas también)
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj:IsA("RopeConstraint") or obj.Name == "CableFantasma" then
			obj:Destroy()
		elseif string.sub(obj.Name, 1, 8) == "Etiqueta" then -- Borra EtiquetaPeso... y EtiquetaFantasma...
			obj:Destroy()
		end
	end
	
	-- 4. Encontrar carpeta de postes del Nivel Actual
	local postesFolder = nil
	local nombreModelo = config.Modelo -- ej: "Nivel0_Tutorial"
	
	if workspace:FindFirstChild(nombreModelo) then
		postesFolder = workspace[nombreModelo]:FindFirstChild("Objetos") and workspace[nombreModelo].Objetos:FindFirstChild("Postes")
	end
	
	-- Fallback para Nivel 1 si carpeta se llama "Nivel1" en vez de "Nivel1_Basico"
	if not postesFolder and nivelID == 1 and workspace:FindFirstChild("Nivel1") then
		postesFolder = workspace.Nivel1:FindFirstChild("Objetos") and workspace.Nivel1.Objetos:FindFirstChild("Postes")
	end

	if postesFolder then
		for _, poste in ipairs(postesFolder:GetChildren()) do
			if poste:IsA("Model") then -- Solo limpiar Modelos (Postes), no carpetas extra
				-- Limpiar conexiones lógicas
				local connections = poste:FindFirstChild("Connections")
				if connections then
					connections:ClearAllChildren()
				end
				
				-- Resetear Colores
				local partes = {poste:FindFirstChild("Part"), poste:FindFirstChild("Selector"), poste:FindFirstChild("Poste"), poste.PrimaryPart}
				for _, p in ipairs(partes) do
					if p then
						p.Color = Color3.fromRGB(196, 196, 196)
						p.Material = Enum.Material.Plastic
					end
				end
			end
		end
		print("🧹 Postes limpiados en: " .. (postesFolder.Parent.Parent.Name))
	else
		warn("⚠️ No se encontró la carpeta de postes para limpiar en Nivel " .. nivelID)
	end
	
	-- 5. Notificar cambio en conexiones (Para apagar luces)
	local eventoConexion = Bindables:FindFirstChild("ConexionCambiada")
	
	if eventoConexion then
		-- Esperar un frame por seguridad para asegurar que los cables se borraron
		task.delay(0.1, function()
			eventoConexion:Fire(nivelID) 
		end)
	end
	
	-- 6. Restaurar objetos recolectables (Scripting individual)
	-- Disparar evento para scripts del usuario (Legacy)
	if eventoLegacy then
		eventoLegacy:Fire(nivelID)
		print("📢 Evento Legacy 'RestaurarObjetos' disparado para Nivel " .. nivelID)
	end
	
	-- También disparar evento interno si existe
	local eventoRestaurar = Bindables:FindFirstChild("RestaurarObjetos")
	if eventoRestaurar then
		eventoRestaurar:Fire(nivelID)
	end
	
	-- 7. Notificar a los clientes para que limpien visuales locales (Partículas, etc.)
	print("📡 SistemaUI: Enviando señal de reinicio a TODOS los clientes...")
	remoteEvent:FireAllClients()
	
	print("✅ NIVEL REINICIADO")
end)
