--[[
    ╔════════════════════════════════════════════════════════════════╗
    ║           TEMPLATE DE DIALOGOS — ZONA 1 (EJEMPLO)              ║
    ║      Copiar y modificar este archivo para tus propias zonas    ║
    ╚════════════════════════════════════════════════════════════════╝
    
    UBICACIÓN: ReplicatedStorage > DialogoData > Zona1_Dialogos.lua
    
    CÓMO USAR:
    1. Copiar este archivo
    2. Cambiar el nombre a tu zona (ej: Zona2_Dialogos.lua)
    3. Modificar la tabla DIALOGOS con tus diálogos
    4. Hacer que tu juego llame a: DialogoGUISystem:Play("Zona1_Intro", metadata)
]]

local DIALOGOS = {
    
    -- ════════════════════════════════════════════════════════════════
    -- PRIMER DIÁLOGO: Introducción
    -- ════════════════════════════════════════════════════════════════
    
    ["Zona1_Intro"] = {
        -- Información de la zona
        Zona = "Zona1",
        Nivel = 1,
        
        -- Líneas del diálogo
        Lineas = {
            {
                Id = "intro_1",
                Numero = 1,
                Actor = "Carlos",
                Expresion = "Feliz",
                Texto = "Bienvenido a la Zona 1.",
                ImagenPersonaje = "rbxassetid://0",  -- Cambiar por tu ID
                Audio = "rbxassetid://0",             -- Cambiar por tu ID
                Evento = function(gui, metadata)
                    print("[Zona1] Línea 1 - Intro")
                    -- Aquí puedes poner efectos, movimientos de cámara, etc.
                end,
                Siguiente = "intro_2"
            },
            {
                Id = "intro_2",
                Numero = 2,
                Actor = "Carlos",
                Expresion = "Feliz",
                Texto = "Aqui aprenderás qué es un nodo y una conexión.",
                ImagenPersonaje = "rbxassetid://0",
                Audio = "rbxassetid://0",
                Evento = function(gui, metadata)
                    print("[Zona1] Línea 2 - Concepto de nodos")
                end,
                Siguiente = "concepto_nodo"
            },
            {
                Id = "concepto_nodo",
                Numero = 3,
                Actor = "Sistema",
                Expresion = "Normal",
                Texto = "Un nodo es un punto en una red.",
                ImagenPersonaje = nil,  -- Sin personaje en esta línea
                Audio = "rbxassetid://0",
                Evento = function(gui, metadata)
                    print("[Zona1] Línea 3 - Explicación")
                end,
                Siguiente = "preguntas"
            },
            
            -- ────────────────────────────────────────────────────────
            -- PREGUNTA CON OPCIONES
            -- ────────────────────────────────────────────────────────
            
            {
                Id = "preguntas",
                Numero = 4,
                Actor = "Carlos",
                Expresion = "Serio",
                Texto = "¿Qué es un nodo?",
                ImagenPersonaje = "rbxassetid://0",
                Audio = "rbxassetid://0",
                
                -- OPCIONES (hace que aparezca el panel de opciones)
                Opciones = {
                    {
                        Numero = 1,
                        Texto = "Un punto en una red que puede conectarse con otros",
                        Pista = "CORRECTO",
                        Color = Color3.fromRGB(0, 229, 160),  -- Verde
                        EsCorrecta = true,
                        Siguiente = "respuesta_correcta",
                        OnSelect = function(gui, metadata)
                            print("[Zona1] Respuesta correcta!")
                            metadata.Zona1_RespuestaCorrecta = true
                        end
                    },
                    {
                        Numero = 2,
                        Texto = "Una línea que conecta dos puntos",
                        Pista = "INCORRECTO",
                        Color = Color3.fromRGB(244, 63, 94),  -- Rojo
                        EsCorrecta = false,
                        Siguiente = "respuesta_incorrecta",
                        OnSelect = function(gui, metadata)
                            print("[Zona1] Respuesta incorrecta")
                            metadata.Zona1_RespuestaCorrecta = false
                        end
                    },
                    {
                        Numero = 3,
                        Texto = "Un color en la pantalla",
                        Pista = "INCORRECTO",
                        Color = Color3.fromRGB(244, 63, 94),  -- Rojo
                        EsCorrecta = false,
                        Siguiente = "respuesta_incorrecta",
                        OnSelect = function(gui, metadata)
                            print("[Zona1] Respuesta incorrecta")
                            metadata.Zona1_RespuestaCorrecta = false
                        end
                    }
                },
                
                Siguiente = "preguntas"  -- Default si no selecciona (no se usa)
            },
            
            -- ────────────────────────────────────────────────────────
            -- RESPUESTAS
            -- ────────────────────────────────────────────────────────
            
            {
                Id = "respuesta_correcta",
                Numero = 5,
                Actor = "Carlos",
                Expresion = "Feliz",
                Texto = "Correcto! Un nodo es un punto en una red.",
                ImagenPersonaje = "rbxassetid://0",
                Audio = "rbxassetid://0",
                Evento = function(gui, metadata)
                    print("[Zona1] Respuesta correcta - Evento")
                    -- Reproducir sonido de éxito
                    -- Mostrar efecto visual
                end,
                Siguiente = "despedida"
            },
            
            {
                Id = "respuesta_incorrecta",
                Numero = 5,
                Actor = "Carlos",
                Expresion = "Serio",
                Texto = "No, esa respuesta es incorrecta. Piénsalo de nuevo.",
                ImagenPersonaje = "rbxassetid://0",
                Audio = "rbxassetid://0",
                Evento = function(gui, metadata)
                    print("[Zona1] Respuesta incorrecta - Evento")
                end,
                Siguiente = "preguntas"  -- Volver a la pregunta
            },
            
            -- ────────────────────────────────────────────────────────
            -- DESPEDIDA
            -- ────────────────────────────────────────────────────────
            
            {
                Id = "despedida",
                Numero = 6,
                Actor = "Carlos",
                Expresion = "Feliz",
                Texto = "Excelente! Ya entiendes los nodos. Que disfrutes tu aventura!",
                ImagenPersonaje = "rbxassetid://0",
                Audio = "rbxassetid://0",
                Evento = function(gui, metadata)
                    print("[Zona1] Diálogo terminado")
                    -- Desbloquear siguiente zona
                    -- Guardar progreso
                    -- Reproducir animación de éxito
                end,
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
    -- SEGUNDO DIÁLOGO: Concepto de Aristas
    -- ════════════════════════════════════════════════════════════════
    
    ["Zona1_Aristas"] = {
        Zona = "Zona1",
        Nivel = 2,
        Lineas = {
            {
                Id = "arista_1",
                Numero = 1,
                Actor = "Carlos",
                Expresion = "Serio",
                Texto = "Ahora aprenderás qué es una arista.",
                ImagenPersonaje = "rbxassetid://0",
                Audio = "rbxassetid://0",
                Siguiente = "arista_2"
            },
            {
                Id = "arista_2",
                Numero = 2,
                Actor = "Carlos",
                Expresion = "Normal",
                Texto = "Una arista es una línea que conecta dos nodos.",
                ImagenPersonaje = "rbxassetid://0",
                Audio = "rbxassetid://0",
                Siguiente = "FIN"
            }
        },
        Metadata = {
            TiempoDeEspera = 0.5,
            VelocidadTypewriter = 0.03,
            PuedeOmitir = true
        }
    }
}

return DIALOGOS

--[[
    ════════════════════════════════════════════════════════════════
    GUÍA DE MODIFICACIÓN
    ════════════════════════════════════════════════════════════════
    
    1. CREAR UN NUEVO DIÁLOGO:
       Agrega una nueva entrada en la tabla DIALOGOS:
       
       ["MiNuevoDialogo"] = {
           Zona = "Zona2",
           Nivel = 1,
           Lineas = { ... }
       }
    
    2. AGREGAR UNA LÍNEA:
       {
           Id = "id_unico",              -- Identificador único
           Numero = 1,                   -- Número secuencial
           Actor = "Nombre",             -- Quién habla
           Expresion = "Feliz",          -- Emoción
           Texto = "Qué dices?",         -- Lo que dice
           ImagenPersonaje = "rbxassetid://...",  -- Imagen (opcional)
           Audio = "rbxassetid://...",   -- Sonido (opcional)
           Evento = function(gui, metadata) end,  -- Código (opcional)
           Siguiente = "siguiente_id"    -- Siguiente línea
       }
    
    3. AGREGAR OPCIONES:
       Opciones = {
           {
               Numero = 1,
               Texto = "Texto de opción",
               Pista = "CORRECTO",
               Color = Color3.fromRGB(0, 229, 160),
               EsCorrecta = true,
               Siguiente = "siguiente_id",
               OnSelect = function(gui, metadata) end
           }
       }
    
    4. EXPRESIONES DISPONIBLES:
       - NORMAL
       - FELIZ
       - SERIO
       - SORPRENDIDO
       - ENOJADO
       - TRISTE
       (Puedes agregar más según tu diseño)
    
    5. COLORES PARA OPCIONES:
       - Verde (correcto): Color3.fromRGB(0, 229, 160)
       - Rojo (incorrecto): Color3.fromRGB(244, 63, 94)
       - Amarillo (advertencia): Color3.fromRGB(251, 191, 36)
       - Cian (default): Color3.fromRGB(0, 207, 255)
    
    6. PARA TERMINAR EL DIÁLOGO:
       Siguiente = "FIN"
]]
