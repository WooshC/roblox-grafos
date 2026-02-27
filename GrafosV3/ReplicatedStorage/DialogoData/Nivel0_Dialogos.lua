-- ReplicatedStorage/DialogoData/Nivel0_Dialogos.lua
-- Datos de diálogos para el Nivel 0 (Tutorial)

--[[
    ╔════════════════════════════════════════════════════════════════╗
    ║           DIÁLOGOS DEL NIVEL 0 — TUTORIAL DE GRAFOS            ║
    ║      Ejemplo de configuración de diálogos para el juego        ║
    ╚════════════════════════════════════════════════════════════════╝
    
    CÓMO USAR:
    1. Colocar este archivo en ReplicatedStorage/DialogoData/
    2. Crear los prompts en el nivel: NivelActual/DialoguePrompts/
    3. Configurar atributos en los modelos de diálogo
]]

local DIALOGOS = {
	
	-- ════════════════════════════════════════════════════════════════
	-- DIÁLOGO DE PRUEBA: Dialogo1 (para pruebas rápidas)
	-- ════════════════════════════════════════════════════════════════
	
	["Dialogo1"] = {
		Zona = "Tutorial",
		Nivel = 0,
		
		Lineas = {
			{
				Id = "test_1",
				Numero = 1,
				Actor = "Carlos",
				Expresion = "Feliz",
				Texto = "¡Hola! Este es un diálogo de prueba. El sistema de diálogos está funcionando correctamente.",
				ImagenPersonaje = "rbxassetid://0",
				Siguiente = "test_2"
			},
			{
				Id = "test_2",
				Numero = 2,
				Actor = "Carlos",
				Expresion = "Normal",
				Texto = "Puedes crear más diálogos editando el archivo Nivel0_Dialogos.lua en ReplicatedStorage/DialogoData/",
				Siguiente = "FIN"
			}
		},
		
		Metadata = {
			TiempoDeEspera = 0.5,
			VelocidadTypewriter = 0.03,
			PuedeOmitir = true,
			OcultarUI = true,
			UsarTTS = true
		}
	},
	
	-- ════════════════════════════════════════════════════════════════
	-- DIÁLOGO 1: Introducción al juego
	-- ════════════════════════════════════════════════════════════════
	
	["Nivel0_Intro"] = {
		-- Información del diálogo
		Zona = "Tutorial",
		Nivel = 0,
		
		-- Líneas del diálogo
		Lineas = {
			{
				Id = "intro_1",
				Numero = 1,
				Actor = "Carlos",
				Expresion = "Feliz",
				Texto = "¡Bienvenido a GrafosV3! Soy Carlos, tu guía en este mundo de grafos.",
				ImagenPersonaje = "rbxassetid://0",  -- Cambiar por ID de imagen
				Audio = "rbxassetid://0",             -- Cambiar por ID de audio
				Evento = function(gui, metadata)
					print("[Nivel0] Intro - Línea 1 mostrada")
					-- Aquí puedes añadir efectos especiales
				end,
				Siguiente = "intro_2"
			},
			{
				Id = "intro_2",
				Numero = 2,
				Actor = "Carlos",
				Expresion = "Normal",
				Texto = "En este juego aprenderás los conceptos fundamentales de la teoría de grafos de forma interactiva.",
				ImagenPersonaje = "rbxassetid://0",
				Audio = "rbxassetid://0",
				Siguiente = "intro_3"
			},
			{
				Id = "intro_3",
				Numero = 3,
				Actor = "Carlos",
				Expresion = "Serio",
				Texto = "Un grafo está formado por nodos (puntos) y aristas (conexiones entre nodos).",
				ImagenPersonaje = "rbxassetid://0",
				Audio = "rbxassetid://0",
				Evento = function(gui, metadata)
					-- Podrías resaltar los nodos en el mundo aquí
					print("[Nivel0] Resaltando nodos...")
				end,
				Siguiente = "intro_4"
			},
			{
				Id = "intro_4",
				Numero = 4,
				Actor = "Carlos",
				Expresion = "Feliz",
				Texto = "¡Vamos a practicar! Conecta los nodos usando cables para completar los desafíos.",
				ImagenPersonaje = "rbxassetid://0",
				Audio = "rbxassetid://0",
				Siguiente = "FIN"
			}
		},
		
		-- Configuración del diálogo
		Metadata = {
			TiempoDeEspera = 0.5,
			VelocidadTypewriter = 0.03,
			PuedeOmitir = true,
			MostrarCamara = true,
			OcultarUI = true
		}
	},
	
	-- ════════════════════════════════════════════════════════════════
	-- DIÁLOGO 2: Explicación de nodos con pregunta
	-- ════════════════════════════════════════════════════════════════
	
	["Nivel0_Nodos"] = {
		Zona = "Tutorial",
		Nivel = 0,
		
		Lineas = {
			{
				Id = "nodos_1",
				Numero = 1,
				Actor = "Carlos",
				Expresion = "Normal",
				Texto = "Los nodos son los elementos básicos de un grafo. Representan objetos, lugares o entidades.",
				ImagenPersonaje = "rbxassetid://0",
				Siguiente = "nodos_2"
			},
			{
				Id = "nodos_2",
				Numero = 2,
				Actor = "Carlos",
				Expresion = "Serio",
				Texto = "En este nivel, cada círculo que ves es un nodo. Tu objetivo es conectarlos correctamente.",
				ImagenPersonaje = "rbxassetid://0",
				Siguiente = "pregunta_nodos"
			},
			
			-- ────────────────────────────────────────────────────────
			-- PREGUNTA CON OPCIONES
			-- ────────────────────────────────────────────────────────
			
			{
				Id = "pregunta_nodos",
				Numero = 3,
				Actor = "Carlos",
				Expresion = "Serio",
				Texto = "¿Qué representa un nodo en un grafo?",
				ImagenPersonaje = "rbxassetid://0",
				
				Opciones = {
					{
						Numero = 1,
						Texto = "Un punto o vértice en la red",
						Pista = "¡CORRECTO!",
						Color = Color3.fromRGB(0, 229, 160),  -- Verde
						EsCorrecta = true,
						Siguiente = "respuesta_correcta",
						OnSelect = function(gui, metadata)
							print("[Nivel0] Respuesta correcta seleccionada")
							-- Reproducir sonido de éxito
						end
					},
					{
						Numero = 2,
						Texto = "Una línea de conexión",
						Pista = "Incorrecto",
						Color = Color3.fromRGB(244, 63, 94),  -- Rojo
						EsCorrecta = false,
						Siguiente = "respuesta_incorrecta",
						OnSelect = function(gui, metadata)
							print("[Nivel0] Respuesta incorrecta seleccionada")
						end
					},
					{
						Numero = 3,
						Texto = "El peso de una conexión",
						Pista = "Incorrecto",
						Color = Color3.fromRGB(244, 63, 94),  -- Rojo
						EsCorrecta = false,
						Siguiente = "respuesta_incorrecta",
						OnSelect = function(gui, metadata)
							print("[Nivel0] Respuesta incorrecta seleccionada")
						end
					}
				},
				
				Siguiente = "pregunta_nodos"
			},
			
			-- ────────────────────────────────────────────────────────
			-- RESPUESTAS
			-- ────────────────────────────────────────────────────────
			
			{
				Id = "respuesta_correcta",
				Numero = 4,
				Actor = "Carlos",
				Expresion = "Feliz",
				Texto = "¡Exacto! Un nodo es un punto o vértice. Las líneas que los conectan se llaman aristas.",
				ImagenPersonaje = "rbxassetid://0",
				Evento = function(gui, metadata)
					-- Marcar progreso
					metadata.respuestaCorrecta = true
				end,
				Siguiente = "despedida"
			},
			
			{
				Id = "respuesta_incorrecta",
				Numero = 4,
				Actor = "Carlos",
				Expresion = "Triste",
				Texto = "No es correcto. Un nodo es el punto o vértice, no la conexión. Las conexiones son las aristas.",
				ImagenPersonaje = "rbxassetid://0",
				Siguiente = "pregunta_nodos"  -- Volver a la pregunta
			},
			
			-- ────────────────────────────────────────────────────────
			-- DESPEDIDA
			-- ────────────────────────────────────────────────────────
			
			{
				Id = "despedida",
				Numero = 5,
				Actor = "Carlos",
				Expresion = "Feliz",
				Texto = "¡Bien hecho! Ahora que sabes qué es un nodo, intenta conectar los nodos del nivel usando cables.",
				ImagenPersonaje = "rbxassetid://0",
				Siguiente = "FIN"
			}
		},
		
		Metadata = {
			TiempoDeEspera = 0.5,
			VelocidadTypewriter = 0.03,
			PuedeOmitir = true,
			OcultarUI = true
		}
	},
	
	-- ════════════════════════════════════════════════════════════════
	-- DIÁLOGO 3: Consejo rápido
	-- ════════════════════════════════════════════════════════════════
	
	["Nivel0_Consejo"] = {
		Zona = "Tutorial",
		Nivel = 0,
		
		Lineas = {
			{
				Id = "consejo_1",
				Numero = 1,
				Actor = "Sistema",
				Expresion = "Normal",
				Texto = "Consejo: Puedes usar el mapa en la esquina superior derecha para ver todos los nodos del nivel.",
				ImagenPersonaje = nil,  -- Sin personaje
				Siguiente = "consejo_2"
			},
			{
				Id = "consejo_2",
				Numero = 2,
				Actor = "Sistema",
				Expresion = "Normal",
				Texto = "Haz clic en los nodos del mapa para conectarlos rápidamente sin moverte.",
				Siguiente = "FIN"
			}
		},
		
		Metadata = {
			TiempoDeEspera = 0.3,
			VelocidadTypewriter = 0.02,
			PuedeOmitir = true,
			OcultarUI = false  -- No ocultar UI para este diálogo corto
		}
	},
	
	-- ════════════════════════════════════════════════════════════════
	-- DIÁLOGO 4: Ejemplo de voz femenina (María)
	-- ════════════════════════════════════════════════════════════════
	
	["Nivel0_Maria"] = {
		Zona = "Tutorial",
		Nivel = 0,
		
		Lineas = {
			{
				Id = "maria_1",
				Numero = 1,
				Actor = "Maria",           -- Usará VoiceId "3" (Spanish Female)
				Expresion = "Feliz",
				Texto = "¡Hola! Soy María. También puedo ayudarte a aprender sobre grafos.",
				ImagenPersonaje = "rbxassetid://0",
				Siguiente = "maria_2"
			},
			{
				Id = "maria_2",
				Numero = 2,
				Actor = "Maria",
				Expresion = "Normal",
				Texto = "Los grafos son muy útiles en la vida real. Los usamos en GPS, redes sociales y mucho más.",
				Siguiente = "FIN"
			}
		},
		
		Metadata = {
			TiempoDeEspera = 0.5,
			VelocidadTypewriter = 0.03,
			PuedeOmitir = true,
			OcultarUI = true,
			UsarTTS = true  -- Habilitar Texto a Voz
		}
	}
}

return DIALOGOS

--[[
    ════════════════════════════════════════════════════════════════
    GUÍA DE REFERENCIA RÁPIDA
    ════════════════════════════════════════════════════════════════
    
    ESTRUCTURA DE UNA LÍNEA:
    {
        Id = "identificador_unico",
        Numero = 1,
        Actor = "Nombre del personaje",
        Expresion = "Feliz|Normal|Serio|Triste|Enojado|Sorprendido",
        Texto = "Lo que dice el personaje",
        ImagenPersonaje = "rbxassetid://12345",
        Audio = "rbxassetid://67890",
        Evento = function(gui, metadata) ... end,
        Siguiente = "id_siguiente_linea" o "FIN"
    }
    
    ESTRUCTURA DE OPCIONES:
    Opciones = {
        {
            Numero = 1,
            Texto = "Texto de la opción",
            Pista = "Texto de ayuda",
            Color = Color3.fromRGB(0, 229, 160),
            EsCorrecta = true|false,
            Siguiente = "id_siguiente",
            OnSelect = function(gui, metadata) ... end
        }
    }
    
    METADATA DEL DIÁLOGO:
    Metadata = {
        TiempoDeEspera = 0.5,        -- Espera antes de empezar
        VelocidadTypewriter = 0.03,  -- Velocidad del efecto máquina de escribir
        PuedeOmitir = true,          -- Se puede saltar el diálogo
        MostrarCamara = true,        -- Mostrar efectos de cámara
        OcultarUI = true             -- Ocultar HUD durante el diálogo
    }
]]


return DIALOGOS
