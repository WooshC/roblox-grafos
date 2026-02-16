local DialogueGenerator = {}

-- ============================================================================
-- CONFIGURACIÓN DE ASSETS (IMÁGENES Y SONIDOS)
-- ============================================================================
local ASSETS_ACTORES = {
	Carlos = {
		Sonriente = "rbxassetid://129627081325324",
		Serio = "rbxassetid://102230620154281",
		Feliz = "rbxassetid://108906238073856",       
		Sorprendido = "rbxassetid://131165138421450", 
		Enojado = "rbxassetid://137903500304444", 
		Presentacion = "rbxassetid://122672087494736",
		-- Sonido por defecto para Carlos
		Sonido = "rbxassetid://9119713990" 
	},
	Sistema = { 
		Nodo = "rbxassetid://74761782067926", 
		Arista = "rbxassetid://134805102079212",
		NodoPrincipal = "rbxassetid://75399428160533",
		Generador = "rbxassetid://90803355152419",
		Arista_energizada = "rbxassetid://112790520179693",
		Arista_conectada = "rbxassetid://140291147333433",
		-- Sonido por defecto para Sistema
		Sonido = "rbxassetid://9119713990"
	}
}

-- Función auxiliar para obtener datos del actor
function DialogueGenerator.GetActorData(actorName)
	return ASSETS_ACTORES[actorName]
end

-- ============================================================================
-- GENERADOR DE ESTRUCTURA
-- ============================================================================
function DialogueGenerator.GenerarEstructura(dialogosSimples, skinName)
	local layersGeneradas = {}

	for id, nodo in pairs(dialogosSimples) do
		-- 1. Resolver Imagen y Sonido
		local imagen = ""
		local sonidoId = nil

		local actorData = ASSETS_ACTORES[nodo.Actor]
		if actorData then
			imagen = actorData[nodo.Expresion] or ""
			if imagen == "" then
				warn("⚠️ No hay ID definido en ASSETS_ACTORES para:", nodo.Actor, nodo.Expresion)
			end
			-- Usar sonido específico del nodo o el defecto del actor
			sonidoId = nodo.Sonido or actorData.Sonido
		else
			-- Si el actor no existe en assets, usar defaults
			sonidoId = nodo.Sonido
		end

		-- 2. Resolver Texto (String o Tabla)
		local textos = {}
		if type(nodo.Texto) == "string" then
			textos = {nodo.Texto}
		else
			textos = nodo.Texto
		end

		-- 3. Configurar Sonidos para cada fragmento de texto
		local sonidos = {}

		if type(nodo.Sonido) == "table" then
			-- Caso: Lista de audios (Narración específica por segmento)
			sonidos = nodo.Sonido
		else
			-- Caso: Audio único o default (Efecto de sonido / Blip repetido)
			-- Si nodo.Sonido es nil, buscamos el default del actor
			local sonidoDefault = nodo.Sonido
			if not sonidoDefault and actorData then
				sonidoDefault = actorData.Sonido
			end

			for _ = 1, #textos do 
				table.insert(sonidos, sonidoDefault) 
			end
		end

		-- 4. Construir Layer
		local nuevaLayer = {
			Title = nodo.Actor or "Desconocido",
			DialogueImage = imagen, 
			Dialogue = textos,
			DialogueSounds = sonidos,
			Replies = {},
			Exec = {}
		}

		-- INYECCIÓN GENÉRICA: Soporte para 'Evento' definido en el nodo
		if nodo.Evento and type(nodo.Evento) == "function" then
			if not nuevaLayer.Exec then nuevaLayer.Exec = {} end

			nuevaLayer.Exec.CustomEvent = {
				Function = nodo.Evento,
				ExecTime = "Before",
				ExecContent = 1
			}
		end

		-- INYECCIÓN: Lógica especial para Confirmacion_Final (Mapa)
		-- Mantenemos esto aquí por compatibilidad, o se podría mover a un callback externo
		if id == "Confirmacion_Final" then
			if not nuevaLayer.Exec then nuevaLayer.Exec = {} end

			nuevaLayer.Exec.SpawnObject = {
				Function = function()
					print("⚡ EJECUTANDO SpawnObject desde Confirmacion_Final...")
					local ReplicatedStorage = game:GetService("ReplicatedStorage")
					local events = ReplicatedStorage:WaitForChild("Events", 5)
					local remotes = events and events:WaitForChild("Remotes", 5)
					local event = remotes and remotes:WaitForChild("AparecerObjeto", 5)

					if event then
						event:FireServer(0, "Mapa")
						print("✅ Solicitud de Mapa ENVIADA")
					end
				end,
				ExecTime = "Before",
				ExecContent = 1
			}
		end

		-- WORKAROUND: Inyectar función Exec para forzar cambio de imagen
		if imagen ~= "" then
			if not nuevaLayer.Exec then nuevaLayer.Exec = {} end

			nuevaLayer.Exec.UpdateImage = {
				Function = function()
					local Players = game:GetService("Players")
					local player = Players.LocalPlayer
					if player then
						local playerGui = player:FindFirstChild("PlayerGui")
						local dialogueGui = playerGui and playerGui:FindFirstChild("DialogueKit") 
						if dialogueGui then
							local targetImage = nil
							-- Búsqueda: Skins -> SKIN_NAME -> Content -> DialogueImage
							local skinFolder = dialogueGui:FindFirstChild("Skins")
							local activeSkin = skinFolder and skinFolder:FindFirstChild(skinName)
							local content = activeSkin and activeSkin:FindFirstChild("Content")
							targetImage = content and content:FindFirstChild("DialogueImage")

							if targetImage and targetImage:IsA("ImageLabel") then
								targetImage.Image = imagen
							end
						end
					end
				end,
				ExecTime = "Before",
				ExecContent = 1
			}
		end

		-- 5. Procesar Opciones
		if nodo.Opciones then
			for i, op in ipairs(nodo.Opciones) do
				local key = "Reply_" .. i
				if op.Siguiente == "FIN" then
					nuevaLayer.Replies["_goodbye_"..i] = { ReplyText = op.Texto }
				else
					nuevaLayer.Replies[key] = {
						ReplyText = op.Texto,
						ReplyLayer = op.Siguiente
					}
				end
			end
		elseif nodo.Siguiente and nodo.Siguiente ~= "FIN" then
			nuevaLayer.Replies["_continue"] = {
				ReplyText = "Continuar...",
				ReplyLayer = nodo.Siguiente
			}
		end

		layersGeneradas[id] = nuevaLayer
	end

	return layersGeneradas
end

return DialogueGenerator
