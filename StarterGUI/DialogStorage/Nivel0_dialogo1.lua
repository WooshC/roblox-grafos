local dialogueKitModule = require(script.Parent.Parent.DialogueKit)
local dialoguePrompt = workspace:WaitForChild("Nivel0_Tutorial"):WaitForChild("DialoguePrompts"):WaitForChild("TestPrompt1").PromptPart.ProximityPrompt

-- ============================================================================
-- 1. ZONA DE EDICIÓN FÁCIL
-- Aquí defines tus diálogos usando la estructura simple.
-- ============================================================================

local DATA_DIALOGOS = {
	-- 1. INTRODUCCIÓN Y CONTEXTO
	["Bienvenida"] = {
		Actor = "Carlos",
		Expresion = "Serio", -- Carlos está estresado por el trabajo
		Texto = "¡Por fin llegas! Disculpa el caos... la energia de la ciudad esta fallando. ¿Tú eres el nuevo aprendiz, verdad? ¿Cómo te llamas?",
		Opciones = {
			{ Texto = "Soy Tocino, vengo a ayudar.", Siguiente = "Saludo_Tocino" }
		}
	},

	["Saludo_Tocino"] = {
		Actor = "Carlos",
		Expresion = "Presentacion", -- Alivio al ver que sí vino
		Texto = "Así que tú eres Tocino. Bienvenido a 'Redes y Caminos'. Soy Carlos. Me alegra ver que alguien respondió al llamado.",
		Siguiente = "Explicacion_Problema"
	},

	["Explicacion_Problema"] = {
		Actor = "Carlos",
		Expresion = "Enojado", -- Frustración con el estado del pueblo
		Texto = {
			"Villa Conexa es un desastre. Cortes de luz, tráfico colapsado, rutas que no llevan a ningún lado...",
			"Todo es culpa del Alcalde. Lleva años aprobando 'soluciones rápidas' y baratas para aparentar progreso."
		},
		Siguiente = "La_Mision"
	},

	["La_Mision"] = {
		Actor = "Carlos",
		Expresion = "Serio",
		Texto = {
			"El Alcalde nos contrató creyendo que pondremos otro parche temporal por poco dinero. Pero se equivoca.",
			"Tú y yo no vamos a improvisar. Vamos a reestructurar todo el pueblo usando Lógica y Planificación."
		},
		Siguiente = "Rol_Tocino"
	},

	["Rol_Tocino"] = {
		Actor = "Carlos",
		Expresion = "Serio",
		Texto = "Sé que no tienes experiencia, Tocino, y es probable que cometas errores al principio. Es parte del proceso.",
		Siguiente = "Conceptos_Nodos" -- Transición al tema educativo
	},

	-- 2. ENSEÑANZA (TUTORIAL)
	["Conceptos_Nodos"] = {
		Actor = "Carlos",
		Expresion = "Sonriente", 
		Texto = "Empecemos. Para arreglar el caos, debes entender las partes de la red.",
		Siguiente = "Explicacion_Generador"
	},

	["Explicacion_Generador"] = {
		Actor = "Sistema",
		Expresion = "Generador",
		Texto = "Todo comienza aquí: el **GENERADOR**. Es la fuente de energía de cada nivel.",
		Siguiente = "Explicacion_Nodos"
	},

	["Explicacion_Nodos"] = {
		Actor = "Sistema",
		Expresion = "Nodo",
		Texto = "La energía debe viajar a través de los postes. En nuestro esquema, los llamamos **NODOS**. Son los puntos de conexión.",
		Siguiente = "Explicacion_Aristas"
	},

	["Explicacion_Aristas"] = {
		Actor = "Sistema",
		Expresion = "Arista",
		Texto = "Para unir los nodos usamos cables, que llamamos **ARISTAS**. Sin ellas, la energía no fluye.",
		Siguiente = "Explicacion_Conexion"
	},

	["Explicacion_Conexion"] = {
		Actor = "Sistema",
		Expresion = "Arista_conectada",
		Texto = "Al unir el **Generador** con un nodo, verás un pulso de energía azul. ¡Eso significa que la corriente está viajando por la **ARISTA**!",
		Siguiente = "Explicacion_Energia"
	},

	["Explicacion_Energia"] = {
		Actor = "Sistema",
		Expresion = "Arista_energizada",
		Texto = "Si lo haces bien, la energía fluirá y el cable se iluminará. Esa es la señal de éxito.",
		Siguiente = "Explicacion_Objetivo"
	},

	["Explicacion_Objetivo"] = {
		Actor = "Sistema",
		Expresion = "NodoPrincipal",
		Texto = "Tu misión final es llevar la energía desde el Generador hasta el **NODO PRINCIPAL** (Transformador). ¡Búscalo y enciéndelo!",
		Siguiente = "Entrega_Mapa"
	},

	["Entrega_Mapa"] = {
		Actor = "Carlos",
		Expresion = "Serio",
		Texto = "Para que no te pierdas, aquí tienes un **MAPA** de la zona. Úsalo para ver la red desde arriba.",
		Siguiente = "Pista_Manual"
	},

	["Pista_Manual"] = {
		Actor = "Carlos",
		Expresion = "Serio",
		Texto = "Ah, y vas a necesitar el **MANUAL DE ALGORITMOS**. Creo que deje la tablet cerca del Generador, en la bodega.",
		Siguiente = "Invitacion_Practica"
	},

	["Invitacion_Practica"] = {
		Actor = "Carlos",
		Expresion = "Serio",
		Texto = "Suficiente teoría. Ve a la mesa, recoge el mapa y conecta el Generador. ¡Manos a la obra!",
		Opciones = {
			{ Texto = "¡Entendido, gracias!", Siguiente = "Confirmacion_Final" }
		}
	},

	["Confirmacion_Final"] = {
		Actor = "Carlos",
		Expresion = "Sonriente",
		Texto = "¡Confío en ti. Suerte!",
		Siguiente = "FIN"
	}
}

-- Definición de imágenes por Actor y Expresión
local ASSETS_ACTORES = {
	Carlos = {
		Sonriente = "rbxassetid://129627081325324",
		Serio = "rbxassetid://102230620154281",
		Feliz = "rbxassetid://108906238073856",       
		Sorprendido = "rbxassetid://131165138421450", 
		Enojado = "rbxassetid://137903500304444", 
		Presentacion="rbxassetid://122672087494736"
	},
	-- Nuevo actor para mostrar objetos
	Sistema = { 
		Nodo = "rbxassetid://74761782067926", 
		Arista = "rbxassetid://134805102079212",
		NodoPrincipal = "rbxassetid://75399428160533", -- ID de la foto del Transformador
		Generador= "rbxassetid://90803355152419",
		Arista_energizada="rbxassetid://112790520179693",
		Arista_conectada="rbxassetid://140291147333433"
	}
}
-- ============================================================================
-- 2. GENERADOR AUTOMÁTICO (NO MODIFICAR)
-- Convierte tu tabla simple a la estructura compleja que requiere DialogueKit
-- ============================================================================

local function GenerarEstructura(dialogosSimples)
	local layersGeneradas = {}

	for id, nodo in pairs(dialogosSimples) do
		-- 1. Resolver Imagen
		local imagen = ""
		-- 1. Resolver Imagen
		local imagen = ""

		if ASSETS_ACTORES[nodo.Actor] then
			imagen = ASSETS_ACTORES[nodo.Actor][nodo.Expresion] or ""

			if imagen == "" then
				warn("⚠️ No hay ID definido en ASSETS_ACTORES para:", nodo.Actor, nodo.Expresion)
			end
		end

		-- 2. Resolver Texto (String o Tabla)
		local textos = {}
		if type(nodo.Texto) == "string" then
			textos = {nodo.Texto}
		else
			textos = nodo.Texto
		end

		-- Crear sonidos vacíos (nil) para cada texto
		local sonidos = {}
		for _ = 1, #textos do table.insert(sonidos, nil) end

		-- 3. Construir Layer
		local nuevaLayer = {
			Title = nodo.Actor or "Desconocido",
			DialogueImage = imagen, 
			Dialogue = textos,
			DialogueSounds = sonidos,
			Replies = {},
			Exec = {}
		}

		-- INYECCIÓN: Si es el nodo "Confirmacion_Final", hacer aparecer el objeto MAPA (Al dar click en Gracias)
		if id == "Confirmacion_Final" then
			if not nuevaLayer.Exec then nuevaLayer.Exec = {} end
			
			nuevaLayer.Exec.SpawnObject = {
				Function = function()
					print("⚡ EJECUTANDO SpawnObject desde Confirmacion_Final...")
					local ReplicatedStorage = game:GetService("ReplicatedStorage")
					-- USAR RUTA ESTÁNDAR NUEVA
					local events = ReplicatedStorage:WaitForChild("Events", 5)
					local remotes = events and events:WaitForChild("Remotes", 5)
					local event = remotes and remotes:WaitForChild("AparecerObjeto", 5)
					
					if event then
						event:FireServer(0, "Mapa")
						print("✅ Solicitud de Mapa ENVIADA (Botón presionado)")
					else
						warn("❌ CRÍTICO: No se encontró Events/Remotes/AparecerObjeto")
					end
				end,
				ExecTime = "Before", -- Ejecutar inmediatamente al entrar al nodo
				ExecContent = 1
			}
		end

		-- WORKAROUND: Inyectar función Exec para forzar cambio de imagen
		-- (Restaurado: Las imágenes funcionan con esto)
		if imagen ~= "" then
			if not nuevaLayer.Exec then nuevaLayer.Exec = {} end
			
			nuevaLayer.Exec.UpdateImage = {
				-- Buscamos el ImageLabel en PlayerGui -> Dialogue -> [Skin] -> Content -> DialogueImage
				Function = function()
					local Players = game:GetService("Players")
					local player = Players.LocalPlayer
					if player then
						local playerGui = player:FindFirstChild("PlayerGui")
						local dialogueGui = playerGui and playerGui:FindFirstChild("DialogueKit") 
						-- Buscar el Frame de DialogueKit (que suele llamarse DialogueFrame o estar dentro)
						if dialogueGui then
							local targetImage = nil
							-- Búsqueda rápida: Skins -> Hotline -> Content -> DialogueImage
							local skinFolder = dialogueGui:FindFirstChild("Skins")
							local activeSkin = skinFolder and skinFolder:FindFirstChild("Hotline")
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

		-- 4. Procesar Opciones
		if nodo.Opciones then
			for i, op in ipairs(nodo.Opciones) do
				local key = "Reply_" .. i

				-- Detectar si es despedida
				if op.Siguiente == "FIN" then
					nuevaLayer.Replies["_goodbye_"..i] = {
						ReplyText = op.Texto
					}
				else
					-- Opción normal
					nuevaLayer.Replies[key] = {
						ReplyText = op.Texto,
						ReplyLayer = op.Siguiente
					}
				end
			end
		elseif nodo.Siguiente and nodo.Siguiente ~= "FIN" then
			-- Continuación automática/lineal con botón
			nuevaLayer.Replies["_continue"] = {
				ReplyText = "Continuar...",
				ReplyLayer = nodo.Siguiente
			}
		end

		layersGeneradas[id] = nuevaLayer
	end

	return layersGeneradas
end

-- ============================================================================
-- 3. EJECUCIÓN
-- ============================================================================

dialoguePrompt.Triggered:Connect(function(player)
	-- Generamos la tabla compleja en tiempo real
	local layersComplejas = GenerarEstructura(DATA_DIALOGOS)

	-- Llamamos al módulo
	dialogueKitModule.CreateDialogue({
		InitialLayer = "Bienvenida", 
		SkinName = "Hotline", 
		Config = script:FindFirstChild("HotlineConfig") or script, 
		Layers = layersComplejas
	})
end)
