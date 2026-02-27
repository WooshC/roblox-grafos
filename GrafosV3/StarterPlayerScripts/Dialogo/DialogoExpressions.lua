-- StarterPlayerScripts/Dialogo/DialogoExpressions.lua
-- Módulo centralizado de expresiones e imágenes de personajes
-- Cada expresión es una imagen del personaje

local DialogoExpressions = {}

-- ============================================================================
-- ASSETS DE PERSONAJES (Expresiones = Imágenes)
-- ============================================================================

local ASSETS_PERSONAJES = {
	Carlos = {
		-- Expresiones principales
		Sonriente = "rbxassetid://129627081325324",
		Serio = "rbxassetid://102230620154281",
		Feliz = "rbxassetid://108906238073856",
		Sorprendido = "rbxassetid://131165138421450",
		Enojado = "rbxassetid://137903500304444",
		Presentacion = "rbxassetid://122672087494736",
		Normal = "rbxassetid://129627081325324",  -- Default: Sonriente
		Triste = "rbxassetid://102230620154281",   -- Default: Serio
	},
	
	Maria = {
		Sonriente = "rbxassetid://0",  -- Reemplazar con IDs reales
		Serio = "rbxassetid://0",
		Feliz = "rbxassetid://0",
		Sorprendido = "rbxassetid://0",
		Normal = "rbxassetid://0",
	},
	
	Sistema = {
		-- Iconos del sistema/tutorial
		Nodo = "rbxassetid://74761782067926",
		Arista = "rbxassetid://134805102079212",
		NodoPrincipal = "rbxassetid://75399428160533",
		Generador = "rbxassetid://90803355152419",
		Arista_energizada = "rbxassetid://112790520179693",
		Arista_conectada = "rbxassetid://140291147333433",
		Normal = "rbxassetid://74761782067926",  -- Default: Nodo
	},
	
	-- Personaje por defecto (fallback)
	Default = {
		Normal = "rbxassetid://0",
		Feliz = "rbxassetid://0",
		Serio = "rbxassetid://0",
	}
}

-- ============================================================================
-- FUNCIONES PÚBLICAS
-- ============================================================================

---Obtiene el AssetId de una expresión de un personaje
-- @param nombrePersonaje string - Nombre del personaje (ej: "Carlos")
-- @param expresion string - Nombre de la expresión (ej: "Sonriente")
-- @return string - AssetId de la imagen
function DialogoExpressions.GetExpression(nombrePersonaje, expresion)
	local personaje = ASSETS_PERSONAJES[nombrePersonaje]
	
	-- Si el personaje no existe, usar default
	if not personaje then
		personaje = ASSETS_PERSONAJES.Default
	end
	
	-- Buscar la expresión específica
	local assetId = personaje[expresion]
	
	-- Si no existe la expresión, usar "Normal" o la primera disponible
	if not assetId or assetId == "rbxassetid://0" then
		assetId = personaje.Normal or personaje.Sonriente or personaje.Feliz
	end
	
	-- Si sigue sin haber asset, retornar nil
	if assetId == "rbxassetid://0" then
		return nil
	end
	
	return assetId
end

---Obtiene todas las expresiones disponibles de un personaje
-- @param nombrePersonaje string - Nombre del personaje
-- @return table - Tabla con todas las expresiones {Expresion = AssetId}
function DialogoExpressions.GetAllExpressions(nombrePersonaje)
	return ASSETS_PERSONAJES[nombrePersonaje] or ASSETS_PERSONAJES.Default
end

---Registra un nuevo personaje con sus expresiones
-- @param nombrePersonaje string - Nombre del nuevo personaje
-- @param expresiones table - Tabla de expresiones {Expresion = AssetId}
function DialogoExpressions.RegisterCharacter(nombrePersonaje, expresiones)
	ASSETS_PERSONAJES[nombrePersonaje] = expresiones
	print("[DialogoExpressions] Personaje registrado:", nombrePersonaje)
end

---Verifica si un personaje existe
-- @param nombrePersonaje string
-- @return boolean
function DialogoExpressions.CharacterExists(nombrePersonaje)
	return ASSETS_PERSONAJES[nombrePersonaje] ~= nil
end

---Lista todos los personajes disponibles
-- @return table - Array con nombres de personajes
function DialogoExpressions.ListCharacters()
	local lista = {}
	for nombre, _ in pairs(ASSETS_PERSONAJES) do
		table.insert(lista, nombre)
	end
	return lista
end

---Obtiene la expresión default de un personaje
-- @param nombrePersonaje string
-- @return string - AssetId de la expresión default
function DialogoExpressions.GetDefaultExpression(nombrePersonaje)
	local personaje = ASSETS_PERSONAJES[nombrePersonaje]
	if not personaje then
		return ASSETS_PERSONAJES.Default.Normal
	end
	
	return personaje.Normal or personaje.Sonriente or personaje.Feliz or "rbxassetid://0"
end

return DialogoExpressions
