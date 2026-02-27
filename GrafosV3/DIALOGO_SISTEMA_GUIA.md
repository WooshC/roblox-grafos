# Sistema de Diálogos - Guía de Integración

## Resumen

El sistema de diálogos de GrafosV3 está diseñado para integrarse de forma limpia con la arquitectura existente, funcionando **solo durante el gameplay** y gestionando correctamente la interacción con el HUD.

## Estructura del Sistema

```
StarterPlayerScripts/
├── Dialogo/                              # Nuevo sistema de diálogos
│   ├── ControladorDialogo.client.lua     # Orquestador principal
│   ├── DialogoGUISystem.lua              # Sistema principal
│   ├── DialogoController.lua             # Controlador de lógica
│   ├── DialogoRenderer.lua               # Efectos visuales
│   ├── DialogoEvents.lua                 # Eventos y botones
│   └── DialogoNarrator.lua               # Audio y narración

ReplicatedStorage/
├── DialogoData/                          # Datos de diálogos
│   └── Nivel0_Dialogos.lua               # Ejemplo de diálogos

StarterGui/
└── DialogoGUI (ScreenGui)               # GUI del diálogo (debe existir)
```

## Características Principales

### 1. Integración con el HUD

Cuando un diálogo está activo:
- Se ocultan automáticamente los elementos del HUD (panel de misiones, puntaje, mapa)
- Se restauran al cerrar el diálogo
- Transiciones suaves (fade in/out)

### 2. Activación por ProximityPrompt

Los diálogos se activan automáticamente al interactuar con prompts en el nivel:

```
NivelActual/
└── DialoguePrompts/
    └── [NombreDelDialogo]/
        └── PromptPart (con ProximityPrompt)
```

### 3. Configuración por Atributos

Cada modelo de diálogo puede tener estos atributos:

| Atributo | Tipo | Descripción | Default |
|----------|------|-------------|---------|
| `DialogoID` | String | ID del diálogo en el archivo Lua | Nombre del modelo |
| `ActionText` | String | Texto de acción del prompt | "Hablar" |
| `ObjectText` | String | Texto del objeto | Nombre del modelo |
| `Tecla` | KeyCode | Tecla de activación | E |
| `Distancia` | Number | Distancia de activación | 20 |
| `HoldDuration` | Number | Tiempo de mantener presionado | 0 |
| `UnaVez` | Boolean | Solo mostrar una vez | false |
| `OcultarHUD` | Boolean | Ocultar HUD durante diálogo | true |

## Instalación Paso a Paso

### Paso 1: Crear la GUI del Diálogo

En **StarterGui**, crear un `ScreenGui` llamado **DialogoGUI** con esta estructura:

```
DialogoGUI (ScreenGui)
└── Canvas (Frame)
    ├── CharacterArea (Frame) [Opcional]
    │   ├── PortraitFrame (Frame)
    │   │   └── PortraitImage (ImageLabel)
    │   ├── CharNameFrame (Frame)
    │   │   └── CharName (TextLabel)
    │   └── Expression (TextLabel)
    │
    ├── DialogueBox (Frame)
    │   ├── SpeakerTag (Frame)
    │   │   ├── SpeakerName (TextLabel)
    │   │   └── EyeBtn (TextButton) [Opcional]
    │   ├── TextArea (Frame)
    │   │   └── DialogueText (TextLabel)
    │   └── Controls (Frame)
    │       ├── ProgressCount (TextLabel)
    │       ├── SkipBtn (TextButton)
    │       └── NextBtn (TextButton)
    │
    └── ChoicesPanel (Frame) [Inicialmente invisible]
        ├── QuestionArea (Frame)
        │   └── QuestionText (TextLabel)
        └── ChoicesList (Frame)
```

> **Nota:** Si la GUI no existe, el sistema creará una versión básica automáticamente.

### Paso 2: Configurar los Archivos

1. Copiar todos los archivos de `StarterPlayerScripts/Dialogo/` a tu proyecto
2. Copiar el ejemplo de `ReplicatedStorage/DialogoData/Nivel0_Dialogos.lua`
3. Asegurar que la GUI exista en StarterGui

### Paso 3: Configurar el Nivel

En tu modelo de nivel (`ServerStorage/Niveles/Nivel0`):

1. Crear una carpeta llamada **DialoguePrompts**
2. Dentro, crear un **Modelo** (ej: "TestPrompt1")
3. Dentro del modelo, crear un **Part** llamado **PromptPart**
4. Agregar un **ProximityPrompt** como hijo de PromptPart

#### Configurar Atributos del Modelo

Selecciona el modelo y en el panel de Propiedades > Atributos, agrega:

```lua
DialogoID = "Nivel0_Intro"        -- ID del diálogo en el archivo Lua
ActionText = "Hablar"              -- Texto del botón
ObjectText = "Carlos"              -- Nombre mostrado
Tecla = Enum.KeyCode.E             -- Tecla de activación
Distancia = 20                     -- Rango de activación
UnaVez = true                      -- Solo mostrar una vez
OcultarHUD = true                  -- Ocultar HUD durante diálogo
```

### Paso 4: Crear los Diálogos

Editar `ReplicatedStorage/DialogoData/Nivel0_Dialogos.lua` con tus propios diálogos:

```lua
local DIALOGOS = {
    ["MiDialogo"] = {
        Zona = "Tutorial",
        Nivel = 0,
        
        Lineas = {
            {
                Id = "linea_1",
                Numero = 1,
                Actor = "Carlos",
                Expresion = "Feliz",
                Texto = "¡Hola! Bienvenido al juego.",
                Siguiente = "linea_2"
            },
            {
                Id = "linea_2",
                Numero = 2,
                Actor = "Carlos",
                Expresion = "Normal",
                Texto = "Aquí aprenderás sobre grafos.",
                Siguiente = "FIN"
            }
        },
        
        Metadata = {
            TiempoDeEspera = 0.5,
            VelocidadTypewriter = 0.03,
            PuedeOmitir = true,
            OcultarUI = true
        }
    }
}

return DIALOGOS
```

## API del Sistema

### Desde otros scripts del cliente:

```lua
-- Obtener el controlador
local ControladorDialogo = _G.ControladorDialogo

-- Iniciar un diálogo programáticamente
ControladorDialogo.iniciar("MiDialogo", {
    nivelID = 0,
    datoPersonalizado = "valor"
})

-- Verificar si hay diálogo activo
if ControladorDialogo.estaActivo() then
    print("Hay un diálogo en curso")
end

-- Cerrar diálogo actual
ControladorDialogo.cerrar()

-- Acceso avanzado al sistema
local sistema = ControladorDialogo.obtenerSistema()
sistema:Skip()  -- Saltar al final
```

### Eventos en Líneas de Diálogo:

```lua
{
    Id = "mi_linea",
    Actor = "Carlos",
    Texto = "Mira este efecto...",
    
    -- Evento al mostrar esta línea
    Evento = function(gui, metadata)
        -- gui: Referencia a elementos GUI
        -- metadata: Datos pasados al iniciar el diálogo
        
        -- Ejemplo: Resaltar un objeto en el mundo
        local nivel = workspace:FindFirstChild("NivelActual")
        if nivel then
            local nodo = nivel:FindFirstChild("Nodo1", true)
            if nodo then
                -- Hacer algo con el nodo
            end
        end
    end,
    
    Siguiente = "siguiente_linea"
}
```

## Controles del Jugador

| Tecla/Botón | Acción |
|-------------|--------|
| **E** (o configurada) | Activar prompt de diálogo |
| **Espacio / Enter** | Siguiente línea |
| **Click en CONTINUAR** | Siguiente línea |
| **ESC** | Saltar diálogo |
| **Click en SALTAR** | Saltar diálogo |
| **H** | Mostrar/ocultar personaje |
| **Flecha Derecha** | Siguiente línea |
| **Flecha Izquierda** | Línea anterior |

## Solución de Problemas

### El diálogo no aparece
1. Verificar que `DialogoGUI` existe en StarterGui
2. Verificar que el archivo de diálogos está en `ReplicatedStorage/DialogoData/`
3. Verificar que el ID del diálogo coincide
4. Revisar Output por errores

### El prompt no responde
1. Verificar que `PromptPart` tiene un `ProximityPrompt`
2. Verificar que el jugador está dentro del rango (`Distancia`)
3. Verificar que el atributo `DialogoID` es correcto

### El HUD no se oculta
1. Verificar que `OcultarHUD` no está en `false`
2. Verificar que los nombres de los frames en el HUD coinciden con la configuración

### Audio no se reproduce
1. Verificar que los IDs de audio son válidos
2. Verificar que el volumen del sistema no está en 0
3. Revisar Output por errores de audio

## Ejemplo Completo

### Estructura en Roblox Studio:

```
StarterGui
└── DialogoGUI (ScreenGui)
    └── [Tu GUI de diálogo]

StarterPlayerScripts
└── Dialogo
    └── [Todos los archivos del sistema]

ReplicatedStorage
├── DialogoData
│   └── Nivel0_Dialogos.lua
└── [Resto de tu juego]

ServerStorage
└── Niveles
    └── Nivel0 (Modelo)
        ├── DialoguePrompts (Folder)
        │   └── TestPrompt1 (Model)
        │       └── PromptPart (Part)
        │           └── ProximityPrompt
        ├── Escenario
        ├── Grafos
        └── [Resto del nivel]
```

### Flujo de Ejecución:

1. Jugador entra al nivel
2. `CargadorNiveles` clona el nivel a `Workspace/NivelActual`
3. `ControladorDialogo` detecta el nivel cargado
4. Busca prompts en `NivelActual/DialoguePrompts/`
5. Configura los ProximityPrompt encontrados
6. Jugador se acerca y presiona E
7. Se inicia el diálogo correspondiente
8. HUD se oculta, aparece el diálogo
9. Al terminar, HUD se restaura

## Texto a Voz (TTS)

El sistema usa la **API oficial AudioTextToSpeech de Roblox** (disponible desde 2025), que soporta:

| Idioma | VoiceId Masculino | VoiceId Femenino |
|--------|-------------------|------------------|
| **Español** | "2" | "3" |
| **Inglés** | "0" (David) | "1" |
| **Italiano** | "4" | "5" |
| **Alemán** | "6" | "7" |
| **Francés** | "8" | "9" |

### Configurar TTS para un Personaje

```lua
local DialogoTTS = ControladorDialogo.obtenerSistema().narrator.tts

-- Registrar voz personalizada
DialogoTTS:RegistrarVoz("MiPersonaje", {
    voiceId = "2",      -- Spanish Male
    volumen = 0.6,
    velocidad = 1.0
})

-- Cambiar idioma
DialogoTTS:SetIdioma(DialogoTTS.IDIOMAS.ESPANOL)
```

### Cómo funciona el TTS

Cuando se muestra una línea de diálogo:

1. Si la línea tiene `Audio` específico → Se reproduce ese audio
2. Si no tiene audio pero tiene `Texto` → Se usa AudioTextToSpeech:
   - El texto se envía a la API de Roblox
   - Se reproduce la voz sintetizada
   - El personaje habla en el idioma configurado

### Deshabilitar TTS

```lua
-- Desde el archivo de datos del diálogo
Metadata = {
    UsarTTS = false  -- Deshabilita TTS para este diálogo
}

-- O programáticamente
ControladorDialogo.obtenerSistema().narrator.tts:SetHabilitado(false)
```

## Notas Importantes

- **Solo durante gameplay**: Los diálogos solo funcionan cuando hay un nivel cargado
- **No se superponen**: No se pueden mostrar dos diálogos simultáneamente
- **Limpieza automática**: Al salir del nivel, se cierran los diálogos activos
- **Persistencia**: El atributo `DialogoVisto_[ID]` guarda si el jugador ya vio un diálogo de una sola vez
- **TTS Requiere**: Roblox Studio/Cliente versión 2025+ con AudioTextToSpeech API habilitada

## Próximos Pasos Sugeridos

1. **Personalizar la GUI**: Adaptar los colores y estilos al diseño de tu juego
2. **Agregar personajes**: Crear imágenes de personajes para mostrar en el diálogo
3. **Audio**: Grabar o conseguir audios para las líneas de diálogo
4. **Más niveles**: Crear archivos de diálogo para cada nivel
5. **Eventos avanzados**: Usar los eventos de línea para resaltar objetos, mover cámara, etc.
