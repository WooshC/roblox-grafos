# Sistema GrafosV3 — Plan de Arquitectura v4 (Con Sistema de Audio)

> **Regla de Oro**: Un punto de entrada. Mientras este el menu activo, TODO lo relacionado al gameplay esta completamente desconectado.
>
> **Principio**: Separacion estricta entre "Sistema de Menu" y "Sistema de Gameplay". Nunca deben coexistir activos.

---

## Convencion de Nombres (Functions in English, Files/Variables in Spanish)

| Concepto | Nombre en Codigo | Function Names |
|----------|------------------|----------------|
| Orchestrator | Orquestador | init, start, stop, cleanup |
| Manager | Gestor | load, save, get, set |
| Controller | Controlador | enable, disable, show, hide |
| Service | Servicio | activate, deactivate, process |
| Module | Modulo | require, init |
| activate | activar | activate |
| deactivate | desactivar | deactivate |
| start | iniciar | start |
| stop | detener | stop |
| cleanup | limpiar | cleanup |
| player | jugador | player |
| level | nivel | level |
| score | puntaje | score |
| mission | mision | mission |
| zone | zona | zone |
| cable | cable | cable |
| node | nodo | node |
| connection | conexion | connection |
| camera | camara | camera |
| audio | audio | audio |
| sound | sonido | sound |

---

## Estructura ACTUALIZADA de GrafosV3

```
GrafosV3/
├── ReplicatedStorage/
│   ├── Config/
│   │   └── LevelsConfig.lua              ✅ FUENTE UNICA DE VERDAD
│   │
│   ├── Efectos/                          ✅ COMPARTIDO - Efectos visuales
│   │   ├── PresetTween.lua               ✅ Configuraciones tweening
│   │   ├── EfectosNodo.lua               ✅ Efectos de seleccion nodos
│   │   ├── EfectosCable.lua              ✅ Efectos de pulso cables
│   │   └── BillboardNombres.lua          ✅ Nombres flotantes
│   │
│   └── Audio/                            🆕 NUEVO - Configuracion centralizada
│       └── ConfigAudio.lua               🆕 IDs y configuracion de sonidos
│
├── ServerScriptService/
│   ├── Nucleo/
│   │   ├── EventRegistry.server.lua      ✅ Crea eventos remotos
│   │   └── Boot.server.lua               ✅ Punto de entrada UNICO
│   │
│   ├── Servicios/
│   │   ├── ServicioDatos.lua             ✅ DataStore wrapper
│   │   ├── ServicioProgreso.lua          ✅ Progreso + LevelsConfig
│   │   └── CargadorNiveles.lua           ✅ Carga modelos + personaje
│   │
│   └── SistemasGameplay/
│       ├── ConectarCables.lua            ✅ Sistema de conexion
│       ├── ServicioMisiones.lua          ✅ Validacion de objetivos
│       ├── ServicioPuntaje.lua           ✅ Tracking de puntos
│       └── GestorZonas.lua               ✅ Deteccion de zonas
│
└── StarterPlayerScripts/
    ├── Nucleo/
    │   └── ClientBoot.client.lua         ✅ Inicializacion cliente
    │
    ├── Compartido/                       🆕 NUEVO - Modulos compartidos
    │   └── ControladorAudio.client.lua   🆕 Sistema de audio unificado
    │
    ├── Menu/
    │   ├── ControladorMenu.client.lua    ✅ UI de seleccion de niveles
    │   └── AudioMenu.client.lua          🆕 Audio especifico del menu
    │
    ├── HUD/
    │   ├── ControladorHUD.client.lua     ✅ Orquestador del HUD
    │   └── ModulosHUD/
    │       ├── EventosHUD.lua            ✅ Referencias a RemoteEvents
    │       ├── PanelMisionesHUD.lua      ✅ Panel de misiones
    │       ├── PuntajeHUD.lua            ✅ Display de puntaje
    │       ├── VictoriaHUD.lua           ✅ Pantalla de victoria
    │       ├── TransicionHUD.lua         ✅ Efectos de fade
    │       ├── EfectosMapa.lua           ✅ Efectos del mapa cenital
    │       ├── ModuloMapa.lua            ✅ Logica del mapa
    │       └── EstadoConexiones.lua      ✅ Estado de conexiones
    │
    └── SistemasGameplay/
        ├── ControladorEfectos.client.lua ✅ Efectos visuales + Highlights
        └── AudioGameplay.client.lua      🆕 Audio especifico del gameplay
```

---

## Sistema de Audio - Arquitectura

### Principios
1. **Centralizado**: Un solo `ControladorAudio` maneja TODOS los sonidos
2. **Separacion Menu/Gameplay**: Audio de menu y gameplay nunca suenan juntos
3. **Cache inteligente**: Los Sound objects se reutilizan
4. **Configuracion externa**: IDs de sonidos en `ConfigAudio.lua`

### Jerarquia de Audio en ReplicatedStorage
```
ReplicatedStorage/
└── Audio/
    ├── Ambiente/
    │   ├── Nivel0 (Sound)
    │   ├── Nivel1 (Sound)
    │   ├── Nivel2 (Sound)
    │   ├── Nivel3 (Sound)
    │   └── Nivel4 (Sound)
    │
    ├── BGM/
    │   └── MusicaMenu/
    │       ├── CambiarEscena (Sound)
    │       ├── Click (Sound)
    │       ├── MusicaCreditos (Sound)
    │       ├── MusicaMenu (Sound - Loop)
    │       ├── Play (Sound)
    │       └── Seleccion (Sound)
    │
    ├── SFX/
    │   ├── CableConnect (Sound)
    │   ├── CableSnap (Sound)
    │   ├── Click (Sound)
    │   ├── ConnectionFailed (Sound)
    │   ├── Error (Sound)
    │   └── Success (Sound)
    │
    └── Victoria/
        ├── Fanfare (Sound)
        └── Tema (Sound)
```

### Flujo de Audio

```
┌─────────────────────────────────────────────────────────────────┐
│                    ControladorAudio (Compartido)                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │   SFX Pool   │  │  BGM Channel │  │  Ambience Channel    │  │
│  │  (reusable)  │  │   (unico)    │  │     (unico)          │  │
│  └──────────────┘  └──────────────┘  └──────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              ▲
           ┌──────────────────┴──────────────────┐
           │                                     │
    ┌──────────────┐                    ┌──────────────┐
    │  AudioMenu   │                    │ AudioGameplay│
    │  (Menu only) │                    │(Gameplay only│
    └──────────────┘                    └──────────────┘
           │                                     │
    Click boton                           Conectar cable
    Hover tarjeta                         Error conexion
    Musica fondo                          Victoria
    Cambiar escena                        Ambiente nivel
```

---

## Contrato de Modulos de Audio

### ConfigAudio (ReplicatedStorage)
```lua
local ConfigAudio = {
    -- IDs de sonidos (para facilitar cambios masivos)
    IDs = {
        SFX_CLICK = "rbxassetid://XXXXXXXXX",
        SFX_CABLE_CONNECT = "rbxassetid://XXXXXXXXX",
        SFX_CABLE_SNAP = "rbxassetid://XXXXXXXXX",
        SFX_ERROR = "rbxassetid://XXXXXXXXX",
        SFX_SUCCESS = "rbxassetid://XXXXXXXXX",
        -- etc...
    },
    
    -- Volumenes por categoria
    Volumenes = {
        SFX = 0.7,
        BGM = 0.4,
        AMBIENTE = 0.3,
        UI = 0.8,
    },
    
    -- Configuracion por sonido
    Sonidos = {
        Click = {
            SoundId = "rbxassetid://...",
            Volumen = 0.8,
            Duracion = 0.2,
        },
        CableConnect = {
            SoundId = "rbxassetid://...",
            Volumen = 0.7,
            Duracion = 0.5,
        },
        -- etc...
    }
}
```

### ControladorAudio (Compartido)
```lua
-- Inicializacion
ControladorAudio.init()

-- SFX - Efectos de un solo uso
ControladorAudio.playSFX(nombreSonido, opcional: callbackAlTerminar)
ControladorAudio.playSFXEnPosicion(nombreSonido, posicion)

-- BGM - Musica de fondo (solo una a la vez)
ControladorAudio.playBGM(nombreMusica, fadeInDuracion)
ControladorAudio.stopBGM(fadeOutDuracion)
ControladorAudio.crossfadeBGM(nuevaMusica, duracion)

-- Ambiente - Sonidos ambientales del nivel
ControladorAudio.playAmbiente(nombreAmbiente, fadeInDuracion)
ControladorAudio.stopAmbiente(fadeOutDuracion)

-- UI - Sonidos de interface
ControladorAudio.playUI(tipo) -- "click", "hover", "back", "error"

-- Gameplay - Sonidos especificos del juego
ControladorAudio.playCableConectar(exito)
ControladorAudio.playVictoria()

-- Control global
ControladorAudio.setMasterVolume(volumen) -- 0-1
ControladorAudio.muteAll()
ControladorAudio.unmuteAll()
ControladorAudio.cleanup() -- Detener todo, limpiar recursos
```

### AudioMenu (Menu)
```lua
-- Se activa cuando el menu esta visible
AudioMenu.activar()

-- Se desactiva cuando inicia el gameplay
AudioMenu.desactivar()

-- Eventos que dispara internamente:
-- - Hover en tarjeta de nivel -> playUI("hover")
-- - Click en boton -> playUI("click") 
-- - Cambiar escena -> playBGM("MusicaMenu")
-- - Mostrar creditos -> playBGM("MusicaCreditos")
```

### AudioGameplay (Gameplay)
```lua
-- Se activa cuando inicia un nivel
AudioGameplay.activar(nivelID)

-- Se desactiva cuando vuelve al menu
AudioGameplay.desactivar()

-- Eventos que escucha:
-- - ConexionExitosa -> playCableConectar(true)
-- - ConexionFallida -> playCableConectar(false)
-- - Victoria -> playVictoria()
-- - Entrada/Salida zona -> cambiar ambiente
```

---

## Integracion Audio con Eventos Existentes

### Eventos de Menu -> AudioMenu
| Evento | Sonido |
|--------|--------|
| MouseEnter tarjeta nivel | UI_Hover |
| Click tarjeta nivel | UI_Click |
| Click boton Jugar | UI_Play |
| Click boton Back | UI_Back |
| Mostrar pantalla niveles | BGM_MusicaMenu |
| Mostrar creditos | BGM_MusicaCreditos |

### Eventos de Gameplay -> AudioGameplay
| Evento Servidor | Sonido Cliente |
|-----------------|----------------|
| ConexionCompletada | SFX_CableConnect |
| ConexionInvalida | SFX_ConnectionFailed + SFX_CableSnap |
| CableDesconectado | SFX_CableSnap |
| NivelListo | Ambiente_NivelX |
| NivelCompletado | Victoria_Fanfare + Victoria_Tema |
| EntrarZona | (cambiar ambiente si aplica) |

---

## Estado de Implementacion

### ✅ COMPLETADO - Fases 1-6 (ver plan anterior)
- [x] Menu y Progreso
- [x] Carga de Niveles  
- [x] Sistema de Conexion de Cables
- [x] Efectos Visuales
- [x] Sistemas Adicionales de Gameplay
- [x] HUD de Gameplay

### 🆕 NUEVO - Fase 7: Sistema de Audio
- [ ] **ConfigAudio** - Configuracion centralizada de sonidos
- [ ] **ControladorAudio** - Motor de audio unificado
- [ ] **AudioMenu** - Sonidos especificos del menu
- [ ] **AudioGameplay** - Sonidos especificos del gameplay
- [ ] **Integracion** - Conectar con eventos existentes

### ⏳ PENDIENTE - Fase 8: Optimizaciones
- [ ] **SistemaCamara unificado** - Un solo modulo para control de camara
- [ ] **GestorColisiones** - Manejo de techos/colisiones del nivel
- [ ] **OrquestadorGameplay formal** - Modulo explicito que coordina todo

---

## Checklist de "Gameplay Desconectado" (Actualizado)

Al volver al menu, se verifica:

- [x] No hay listeners de entrada activos (clics en nodos no hacen nada)
- [x] No hay highlights visibles en el workspace
- [x] No hay billboards flotando
- [x] No hay cables siendo renderizados
- [x] La camara esta en modo Menu (Scriptable, posicion fija)
- [x] El HUD de gameplay esta oculto completamente
- [ ] El techo esta restaurado a su estado original
- [ ] Las colisiones estan restauradas
- [x] No hay referencias al "NivelActual" en ningun sistema activo
- [x] **TODOS los sonidos de gameplay detenidos**
- [x] **Musica de menu activada**
- [x] **Ambiente del nivel detenido**

---

## Mejoras en Efectos Visuales (Consolidacion)

### Problema Identificado
Algunos modulos implementan sus propios efectos visuales cuando deberian usar el `ControladorEfectos` compartido.

### Solucion: ControladorEfectos Centralizado

```lua
-- ANTI-PATRON (evitar):
local function miEfectoFlash()
    -- Crear highlight local
    local h = Instance.new("Highlight")
    -- ...
end

-- PATRON CORRECTO (usar):
local ControladorEfectos = require(path)
ControladorEfectos.flashError(part)
ControladorEfectos.highlightNode(nodo, color)
ControladorEfectos.showBillboard(nodo, texto)
```

### Modulos que DEBEN usar ControladorEfectos:
| Modulo | Uso Actual | Deberia usar |
|--------|-----------|--------------|
| ModuloMapa | Crear billboards propios | ControladorEfectos.showBillboard |
| VictoriaHUD | Efectos de confeti local | ControladorEfectos.celebracionVictoria |
| PanelMisiones | Highlights de misiones | ControladorEfectos.highlightMision |

### Eventos para Efectos Centralizados
```lua
-- El ControladorEfectos expone:
ControladorEfectos.highlightNode(nodo, tipo)       -- "seleccionado", "adyacente", "error"
ControladorEfectos.clearHighlights()                -- Limpiar todos
ControladorEfectos.flashError(modelo)               -- Flash rojo
ControladorEfectos.showBillboard(parte, texto)      -- Mostrar nombre
ControladorEfectos.hideAllBillboards()              -- Ocultar nombres
ControladorEfectos.pulseCable(beam, velocidad)      -- Pulso de energia
ControladorEfectos.stopAllEffects()                 -- Detener todo (cleanup)
```

---

## Flujo de Transicion con Audio

### Menu -> Gameplay
```
1. Jugador clickea "JUGAR"
2. AudioMenu: playUI("click")
3. AudioMenu: crossfade BGM -> silencio (0.5s)
4. Boot.server: iniciar carga nivel
5. Cliente: mostrar pantalla de carga
6. NivelListo: recibido del servidor
7. AudioGameplay: activar(nivelID)
   - fadeIn ambiente del nivel
   - preparar SFX pool
8. HUD: mostrar
```

### Gameplay -> Menu
```
1. Jugador completa nivel o clickea "SALIR"
2. AudioGameplay: playVictoria() (si completo)
3. Boot.server: descargar nivel
4. AudioGameplay: fadeOut ambiente (1s)
5. NivelDescargado: recibido
6. AudioGameplay: desactivar()
7. AudioMenu: activar()
   - playBGM("MusicaMenu")
8. Menu: mostrar
```

---

## Notas de Implementacion

### Estructura del Selector (sin cambios)
El Selector dentro de cada nodo debe ser:
```
Nodo (Model)
├── Decoracion/          (Model opcional)
└── Selector            (BasePart) ← OBLIGATORIO
    ├── Attachment      (Attachment) ← Para el Beam
    └── ClickDetector   (ClickDetector) ← Para clicks
```

### ClickDetector Configuracion (sin cambios)
- `MaxActivationDistance = 50` (studs)
- No requiere `CanCollide = true`
- El Selector debe tener `CanQuery = true`

### Audio Performance Tips
- Usar `Sound:Play()` en lugar de clonar Sounds repetidamente
- Limitar SFX simultaneos (max 5-6)
- Usar `RollOffMode = Linear` para sonidos 3D
- Precargar sonidos comunes al inicio

---

## Archivos Nuevos a Crear

### 1. ReplicatedStorage/Audio/ConfigAudio.lua
Configuracion centralizada de todos los sonidos del juego.

### 2. StarterPlayerScripts/Compartido/ControladorAudio.client.lua
Motor de audio unificado. Se carga antes que Menu y Gameplay.

### 3. StarterPlayerScripts/Menu/AudioMenu.client.lua
Controlador de audio especifico para el menu.

### 4. StarterPlayerScripts/SistemasGameplay/AudioGameplay.client.lua
Controlador de audio especifico para el gameplay.

---

## Cambios en Archivos Existentes

### ControladorMenu.client.lua
- Agregar import de `AudioMenu`
- Llamar `AudioMenu.activar()` en inicializacion
- Llamar `AudioMenu.desactivar()` cuando inicia nivel
- Agregar sonidos a eventos de hover/click

### ClientBoot.client.lua
- Agregar carga de `ControladorAudio`
- Inicializar sistema de audio antes que Menu

### ControladorEfectos.client.lua
- Agregar funciones para efectos centralizados
- Exponer API para otros modulos

### ConectarCables.lua (Servidor)
- Agregar eventos de sonido en notificaciones al cliente
- (Opcional) Trigger sonidos desde servidor

---

## Proximos Pasos Recomendados

### 1. Sistema de Audio (Priority: HIGH)
- [ ] Crear estructura de carpetas en ReplicatedStorage/Audio
- [ ] Implementar ConfigAudio con placeholders
- [ ] Implementar ControladorAudio con pool de SFX
- [ ] Implementar AudioMenu con BGM
- [ ] Implementar AudioGameplay con SFX
- [ ] Integrar con eventos existentes

### 2. Consolidacion de Efectos (Priority: MEDIUM)
- [ ] Refactorizar ModuloMapa para usar ControladorEfectos
- [ ] Agregar funciones faltantes a ControladorEfectos
- [ ] Documentar API de efectos

### 3. Persistencia Mejorada (Priority: MEDIUM)
- [ ] Guardar estado parcial de nivel
- [ ] Sistema de checkpoints

### 4. Analytics (Priority: LOW)
- [ ] Tracking de patrones de errores
- [ ] Metricas de tiempo por zona

---

*Documento actualizado: 2026-02-27*
*Version: GrafosV3 - Sistema Completo con Audio*
