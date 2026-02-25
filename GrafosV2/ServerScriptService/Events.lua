-- EventRegistry.lua
-- ModuleScript ubicado en: ReplicatedStorage/EventRegistry.lua
-- 
-- Propósito: Proveer acceso centralizado a todos los eventos ya creados
-- manualmente en ReplicatedStorage/Events. No crea ni destruye nada.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Buscar la carpeta Events (debe existir, creada manualmente)
local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
if not eventsFolder then
	error("No se encontró la carpeta 'Events' en ReplicatedStorage. Créala manualmente con la estructura requerida.")
end

-- Función helper para obtener todos los hijos de una carpeta como diccionario
local function getChildrenAsDict(folder)
	local dict = {}
	if folder then
		for _, child in ipairs(folder:GetChildren()) do
			dict[child.Name] = child
		end
	end
	return dict
end

-- Construir la tabla de eventos
local Events = {
	Remotes = getChildrenAsDict(eventsFolder:FindFirstChild("Remotes")),
	Bindables = getChildrenAsDict(eventsFolder:FindFirstChild("Bindables")),
}

-- Verificación opcional: avisar si faltan carpetas
if not Events.Remotes then
	warn("EventRegistry: No se encontró la carpeta 'Remotes' dentro de Events.")
end
if not Events.Bindables then
	warn("EventRegistry: No se encontró la carpeta 'Bindables' dentro de Events.")
end

return Events