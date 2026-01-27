local DialogueKit = {}
DialogueKit.__index = DialogueKit

-- Mock de CreateDialogue para mantener compatibilidad si el usuario no tiene el original
function DialogueKit.CreateDialogue(infoTable)
	print("--- INICIANDO DIÁLOGO (MOCK) ---")
	print("Skin:", infoTable.SkinName)
	print("Iniciando en Layer:", infoTable.InitialLayer)
	
	local currentLayerId = infoTable.InitialLayer
	local layers = infoTable.Layers
	
	-- Simulación muy básica en consola
	local function playLayer(layerId)
		local layer = layers[layerId]
		if not layer then 
			warn("Layer no encontrada:", layerId)
			return 
		end
		
		print("\n[" .. (layer.Title or "Sín Título") .. "]")
		-- Simula la imagen
		print("Imagen:", layer.DialogueImage)
		
		for _, text in ipairs(layer.Dialogue) do
			print("Combatiene:", text)
			task.wait(1) 
		end
		
		-- Mostrar opciones
		if layer.Replies then
			print("\nOpciones:")
			local options = {}
			for key, data in pairs(layer.Replies) do
				table.insert(options, {key = key, data = data})
				print("- [" .. key .. "]: " .. data.ReplyText)
			end
			
			-- Simular elección automática de la primera opción 'continue' para demo
			local continueOption = layer.Replies["_continue"]
			if continueOption then
				print(">> Auto-seleccionando Continuar...")
				playLayer(continueOption.ReplyLayer)
			elseif next(layer.Replies) == nil then
				print("--- FIN DEL DIÁLOGO ---")
			else
				print("(Esperando input del jugador - En juego real aparecerían botones)")
			end
		else
			print("--- FIN DEL DIÁLOGO ---")
		end
	end
	
	playLayer(currentLayerId)
end

return DialogueKit