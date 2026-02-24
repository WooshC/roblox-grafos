# Estructura de Assets y Niveles — Sistema 2.0

> **Propósito**: Referencia de la estructura de carpetas para niveles (ServerStorage/Workspace)
> y assets compartidos (ReplicatedStorage). Diseñada para la Fase 1 del Sistema 2.0: carga de niveles.
>
> **Regla de oro**: Lo que es fijo y reutilizable vive pre-creado en ReplicatedStorage.
> Lo que varía por contexto de gameplay (posiciones, colores, relaciones entre nodos) se genera en runtime por código.

---

## Tabla de Contenido

1. [Estructura de un Nivel](#1-estructura-de-un-nivel)
2. [Jerarquía de Nodos](#2-jerarquía-de-nodos)
3. [Lógica de Grafos Múltiples](#3-lógica-de-grafos-múltiples)
4. [Qué se pre-crea vs qué se genera por código](#4-qué-se-pre-crea-vs-qué-se-genera-por-código)
5. [Assets en ReplicatedStorage](#5-assets-en-replicatedstorage)
6. [Notas de Implementación](#6-notas-de-implementación)
7. [Checklist — Fase 1 (Carga de Nivel)](#7-checklist--fase-1-carga-de-nivel)

---

## 1. Estructura de un Nivel

El modelo vive en `ServerStorage` y se clona a `Workspace/NivelActual` al cargarse.
El nombre del modelo en ServerStorage debe coincidir con el campo `Modelo` en `LevelsConfig`.

Cada nivel puede tener uno o más grafos independientes. Cada grafo representa
una zona o puzzle separado. Si un grafo requiere generador de energía, ese
nodo vive **dentro** del propio grafo.

```
ServerStorage/
└── Nivel1/                              (Model) ← se clona como "NivelActual"
    │
    ├── Grafos/                          (Folder) ← colección de todos los grafos del nivel
    │   │
    │   ├── Grafo_Zona1/                 (Folder) ← grafo independiente con generador
    │   │   ├── Nodos/                   (Folder) ← todos los nodos de este grafo
    │   │   │   ├── NodoA/               (Model)  ← ver sección 2 para estructura interna
    │   │   │   ├── NodoB/               (Model)
    │   │   │   ├── NodoC/               (Model)
    │   │   │   └── Generador/           (Model)  ← nodo fuente de energía del grafo
    │   │   │       ├── Part             (BasePart)   ← visual principal
    │   │   │       ├── Attachment       (Attachment) ← anclaje para cables
    │   │   │       └── [Tag: "Generador"]
    │   │   ├── Conexiones/              (Folder) ← vacío; RopeConstraints se crean aquí en runtime
    │   │   └── Meta/                    (Folder) ← metadatos del grafo
    │   │       ├── GrafoID              (StringValue) = "Grafo_Zona1"
    │   │       ├── Activo               (BoolValue)   = false
    │   │       └── RequiereGenerador    (BoolValue)   = true
    │   │
    │   ├── Grafo_Zona2/                 (Folder) ← grafo sin generador propio
    │   │   ├── Nodos/                   (Folder)
    │   │   │   ├── NodoD/               (Model)
    │   │   │   └── NodoE/               (Model)
    │   │   ├── Conexiones/              (Folder) ← vacío al inicio
    │   │   └── Meta/                    (Folder)
    │   │       ├── GrafoID              (StringValue) = "Grafo_Zona2"
    │   │       ├── Activo               (BoolValue)   = false
    │   │       └── RequiereGenerador    (BoolValue)   = false
    │   │
    │   └── Grafo_ZonaN/                 (Folder) ← se añaden más grafos según el nivel
    │       └── ...
    │
    ├── Zonas/                           (Folder) ← triggers para diálogos y eventos
    │   ├── Zona1/                       (Model)
    │   │   ├── Trigger                  (BasePart) ← Transparency=1, CanCollide=false
    │   │   └── [Tag: "ZonaTrigger"]
    │   ├── Zona2/                       (Model)
    │   └── ...
    │
    ├── Navegacion/                      (Folder) ← puntos de referencia espaciales
    │   ├── SpawnPoint                   (BasePart) ← donde aparece el jugador al cargar
    │   ├── CamaraInicio                 (BasePart) ← CFrame objetivo de la cámara al entrar
    │   └── Waypoints/                   (Folder)
    │       ├── WP_01                    (BasePart) ← el Name define el orden de la guía
    │       ├── WP_02                    (BasePart)
    │       └── ...
    │
    ├── Escenario/                       (Folder) ← geometría visual y colisiones
    │   ├── Decoracion/                  (Folder) ← Parts puramente visuales
    │   └── Colisionadores/              (Folder) ← InvisibleWalls, suelo, límites
    │
    └── Meta/                            (Folder) ← metadatos del nivel
        ├── NivelID                      (IntValue)    = 1
        ├── NombreDisplay                (StringValue) = "El Primer Circuito"
        └── Algoritmo                    (StringValue) = "BFS" | "DFS" | "PRIM"
```

---

## 2. Jerarquía de Nodos

Cada nodo dentro de `Grafo_ZonaX/Nodos/` sigue esta estructura interna.
El nombre del Model (`NodoA`, `NodoB`, etc.) es el identificador del nodo en el grafo.

```
NodoA/                                   (Model) ← PrimaryPart debe apuntar a Part
│
├── Part                                 (BasePart)   ← visual principal del poste
│   └── [Attribute: "NodoID" = "NodoA"]  ← identifica el nodo desde la Part
│
├── Selector                             (BasePart)      ← hitbox exclusivo para el click
│   ├── ClickDetector                    (ClickDetector) ← detecta interacción del jugador
│   └── [Attribute: "Seleccionable" = true]
│
├── Attachment                           (Attachment) ← anclaje para RopeConstraints
│                                           debe estar dentro de Part, no suelto en el Model
│
├── EstadoVisual/                        (Folder)
│   ├── LuzActiva                        (BasePart) ← visible cuando el nodo tiene energía
│   └── LuzInactiva                      (BasePart) ← visible por defecto
│
└── [Tags CollectionService]
    ├── "Nodo"                           ← todos los nodos del grafo
    └── "NodoInteractivo"                ← nodos que el jugador puede seleccionar
```

> **Nota**: `PrimaryPart` del Model debe apuntar a `Part` para que
> `GraphService` pueda obtener la posición world correctamente con `:GetPivot()`.

---

## 3. Lógica de Grafos Múltiples

Con esta estructura, `GraphService` opera sobre un grafo a la vez y puede
activarlos progresivamente conforme el jugador avanza.

```lua
-- GraphService recibe el Folder del grafo, no el nivel completo
GraphService:loadGrafo(nivelActual.Grafos.Grafo_Zona1)

-- ZoneTriggerManager activa el siguiente grafo al entrar en una zona
-- Jugador entra Zona2
--   → ZoneTriggerManager dispara evento
--   → GraphService:loadGrafo("Grafo_Zona2")
--   → Grafo_Zona2.Meta.Activo = true
--   → MissionService registra misiones del nuevo grafo
```

Si `Grafo_Zona2.Meta.RequiereGenerador = false`, recibe energía desde una
conexión proveniente de `Grafo_Zona1`. Esa relación entre grafos se define
en `LevelsConfig`, no en la jerarquía de instancias del nivel.

---

## 4. Qué se pre-crea vs qué se genera por código

La división no es "todo en ReplicatedStorage" ni "todo por código" — es una decisión
por tipo de asset según qué tanto varía en runtime.

### Pre-creado en ReplicatedStorage (fijo y reutilizable)

| Asset | Por qué pre-crearlo |
|---|---|
| BGM y Ambiente (Sound) | Sus IDs nunca cambian; cargarlos por código es innecesario |
| SFX (Sound) | Siempre el mismo sonido para el mismo evento |
| ParticleEmitter base | La textura, física y forma base son fijas; solo color/intensidad varía |
| Templates de UI | Estructura HTML/GUI fija; solo el contenido varía por código |
| Beam templates | La apariencia base es fija; Attachments se reasignan en runtime |
| BillboardGui templates | El layout es fijo; el texto se escribe por código |

### Generado por código en runtime (varía por gameplay)

| Asset | Por qué generarlo por código |
|---|---|
| RopeConstraints (cables) | Posición y longitud dependen de qué nodos conecta el jugador |
| Color y propiedades de ParticleEmitter | Cambia según el estado del nodo, tipo de conexión o evento |
| Highlights / SelectionBox | El objeto seleccionado cambia cada interacción |
| Tweens de color y posición | Dependen del estado actual de cada Part |
| Texto en BillboardGui | Nombre del nodo, peso de arista, puntaje — siempre dinámico |
| Attachment0/1 de Beams | Se asignan a los nodos específicos del grafo activo |

### Partículas — regla específica

El `ParticleEmitter` **nunca** se crea desde cero por código. Lo que sí hace
`EffectsService` después de clonar el template es modificar sus propiedades
antes de emitir, por ejemplo:

```lua
-- EffectsService clona el template base
local clone = ReplicatedStorage.Efectos.Particulas.Chispa:Clone()
local emitter = clone:FindFirstChildWhichIsA("ParticleEmitter")

-- Modifica propiedades según el contexto
emitter.Color = ColorSequence.new(colorDelNodo)   -- color del nodo conectado
emitter.Rate = intensidad                          -- más intenso si es conexión clave
emitter.SpreadAngle = Vector2.new(spread, spread)  -- más disperso en errores

clone.Part.CFrame = posicionDelNodo
clone.Parent = workspace
game:GetService("Debris"):AddItem(clone, duracion)
```

Esto permite efectos visualmente distintos (chispa azul para BFS, verde para árbol,
roja para error) sin duplicar emitters en ReplicatedStorage.

### Efectos de video — opciones en Roblox

Roblox no tiene un sistema de video nativo con control total, pero hay dos opciones:

**`VideoFrame`** — instancia nativa de Roblox que reproduce archivos `.webm` subidos
como asset. Funciona dentro de `SurfaceGui` o `ScreenGui`. Es viable para cutscenes
de intro de nivel o pantalla de victoria. Requiere que el video pase moderación de Roblox.

**Spritesheet animado** — se sube un spritesheet de frames y se anima por código
cambiando `ImageRectOffset` en un `ImageLabel`. Es el método más usado para efectos
cortos en gameplay (destellos, explosiones, energía fluyendo). Más control, sin moderación.

Para este proyecto la recomendación es:
- `VideoFrame` para intro cinemática de nivel o victoria si se desea algo cinematográfico
- Spritesheet animado para efectos cortos dentro del gameplay

---

## 5. Assets en ReplicatedStorage

Todos los assets fijos que servidor y cliente comparten. Se clonan o referencian
desde aquí — nunca se instancian de cero por código.

```
ReplicatedStorage/
│
├── Audio/                               (Folder) ← todos los sonidos del juego
│   │
│   ├── SFX/                             (Folder) ← efectos de sonido cortos, no looped
│   │   ├── CableConnect                 (Sound) ← al conectar un cable exitosamente
│   │   ├── CableDisconnect              (Sound) ← al desconectar un cable
│   │   ├── CableSnap                    (Sound) ← intento de conexión inválida
│   │   ├── NodoActivado                 (Sound) ← nodo recibe energía
│   │   ├── NodoApagado                  (Sound) ← nodo pierde energía
│   │   ├── Error                        (Sound) ← acción no permitida
│   │   ├── Click                        (Sound) ← interacción genérica de UI
│   │   ├── Hover                        (Sound) ← hover sobre botones
│   │   ├── MisionCompleta               (Sound) ← misión individual completada
│   │   └── Acierto                      (Sound) ← respuesta/conexión correcta
│   │
│   ├── BGM/                             (Folder) ← música de fondo, Looped = true
│   │   ├── MenuPrincipal                (Sound)
│   │   ├── Gameplay_Tranquilo           (Sound) ← fase inicial del nivel
│   │   ├── Gameplay_Tenso               (Sound) ← fase final / presión de tiempo
│   │   └── Victoria                     (Sound) ← Looped = false
│   │
│   ├── Ambiente/                        (Folder) ← sonido ambiental, Looped = true
│   │   ├── Electricidad                 (Sound) ← zumbido eléctrico suave
│   │   └── Viento                       (Sound) ← ambiente exterior
│   │
│   └── Voz/                             (Folder) ← narración de diálogos, opcional por fase
│       ├── Carlos_Intro_01              (Sound)
│       └── ...
│
├── Efectos/                             (Folder) ← partículas, beams, billboards
│   │
│   ├── Particulas/                      (Folder)
│   │   ├── Chispa/                      (Model) ← al conectar cable
│   │   │   ├── Part                     (BasePart)
│   │   │   └── Emitter                  (ParticleEmitter)
│   │   ├── EnergiaPulso/                (Model) ← pulso en nodo activo
│   │   │   ├── Part                     (BasePart)
│   │   │   └── Emitter                  (ParticleEmitter)
│   │   ├── ExplosionError/              (Model) ← error/fallo
│   │   │   ├── Part                     (BasePart)
│   │   │   └── Emitter                  (ParticleEmitter)
│   │   ├── Confeti/                     (Model) ← victoria
│   │   │   ├── Part                     (BasePart)
│   │   │   └── Emitter                  (ParticleEmitter)
│   │   └── BrilloNodo/                  (Model) ← highlight de waypoint activo
│   │       ├── Part                     (BasePart)
│   │       └── Emitter                  (ParticleEmitter)
│   │
│   ├── Beams/                           (Folder)
│   │   ├── BeamRuta/                    (Model) ← visualizador de camino del algoritmo
│   │   │   ├── Beam                     (Beam)
│   │   │   ├── Attachment0              (Attachment) ← placeholder, se reasigna en runtime
│   │   │   └── Attachment1              (Attachment) ← placeholder, se reasigna en runtime
│   │   └── BeamEnergia/                 (Model) ← flujo de energía entre nodos activos
│   │       ├── Beam                     (Beam)
│   │       ├── Attachment0              (Attachment)
│   │       └── Attachment1              (Attachment)
│   │
│   └── Billboards/                      (Folder) ← templates clonados en runtime
│       ├── EtiquetaNodo                 (BillboardGui) ← muestra nombre/peso del nodo
│       └── IndicadorWaypoint            (BillboardGui) ← flecha guía del siguiente objetivo
│
├── UI/                                  (Folder) ← templates clonados una sola vez al inicio
│   ├── DialogueBubble                   (ScreenGui) ← ventana de diálogos
│   ├── HUD_Template                     (ScreenGui) ← HUD de gameplay
│   ├── ToastNotification                (Frame)     ← notificaciones emergentes
│   └── LoadingScreen                    (ScreenGui) ← pantalla de transición/fade
│
├── Config/                              (Folder) ← configuración del juego
│   ├── LevelsConfig                     (ModuleScript) ← definición de todos los niveles
│   ├── AudioConfig                      (ModuleScript) ← mapeo nombre → assetId de sonidos
│   ├── EffectsConfig                    (ModuleScript) ← configuración de partículas/tweens
│   └── DifficultyConfig                 (ModuleScript) ← modos de dificultad
│
└── Shared/                              (Folder) ← ModuleScripts compartidos server/client
    ├── Constants                        (ModuleScript) ← STUDS_PER_METER, TIMEOUTS, MAX_STARS
    ├── Enums                            (ModuleScript)
    └── Utils/                           (Folder)
        ├── GraphUtils                   (ModuleScript)
        ├── TableUtils                   (ModuleScript) ← countKeys, deepCopy, shallowMerge
        └── TweenUtils                   (ModuleScript) ← helper para tweens reutilizables
```

---

## 6. Notas de Implementación

### Sonidos en ReplicatedStorage vs SoundService

Los sonidos viven en `ReplicatedStorage/Audio/` porque `AudioService` (servidor) los referencia
para replicar efectos, y el cliente también puede leerlos para efectos locales.
`SoundService` es más adecuado para música global persistente que no necesita ser referenciada por scripts.

### ParticleEmitters — clonar y modificar, nunca crear desde cero

Cada Model en `Efectos/Particulas/` contiene una `BasePart` con el `ParticleEmitter` configurado
con valores base. `EffectsService` lo clona y **antes de emitir** modifica las propiedades
que dependen del contexto: `Color`, `Rate`, `SpeedRange`, `SpreadAngle`, etc.
Esto permite un mismo emitter base producir efectos visualmente distintos según el gameplay
(color del nodo, tipo de algoritmo, severidad del error) sin duplicar assets.
Ver sección 4 para el patrón de código.

### Beams — los Attachments son placeholders

Los templates en `Efectos/Beams/` incluyen `Attachment0` y `Attachment1` como placeholders.
En runtime, `EffectsService` clona el template y reasigna ambos attachments a los
`Attachment` que ya existen dentro de los nodos del nivel activo.

### Templates de UI — clonar una sola vez

Los templates en `UI/` se clonan **una sola vez** al inicio del cliente y se
muestran/ocultan según la etapa activa. No se crean nuevas instancias durante
el gameplay para evitar memory leaks.

### Tags de CollectionService

Los tags (`"Nodo"`, `"ZonaTrigger"`, `"Generador"`) se asignan directamente en Studio
sobre cada instancia. Los servicios usan `CollectionService:GetTagged()` en lugar de
iterar carpetas, lo que desacopla la lógica de la jerarquía de instancias exacta.

### Grafos — activación progresiva

`Grafo_ZonaX.Meta.Activo` arranca en `false`. `GraphService:loadGrafo()` lo pone en `true`
y registra sus nodos. Esto permite que un nivel tenga varios puzzles en el mismo
espacio sin que `GraphService` mezcle nodos de grafos distintos.

---

## 7. Checklist — Fase 1 (Carga de Nivel)

Lo mínimo necesario para que `LevelService:loadLevel(nivelID)` funcione correctamente.

### En ServerStorage
- [ ] Model del nivel con nombre exactamente igual al campo `Modelo` en `LevelsConfig`
- [ ] Folder `Grafos/` con al menos un `Grafo_ZonaX/`
- [ ] Cada grafo tiene: `Nodos/` (Folder), `Conexiones/` (Folder vacío), `Meta/` con `GrafoID` y `Activo`
- [ ] Al menos un nodo válido con: `Part` (BasePart), `Selector` (BasePart), `ClickDetector`, `Attachment`
- [ ] `PrimaryPart` de cada nodo (Model) apunta a su `Part`
- [ ] Si `RequiereGenerador = true`, existe un Model `Generador/` dentro de `Nodos/`
- [ ] Folder `Navegacion/` con `SpawnPoint` (BasePart)
- [ ] Folder `Meta/` con `NivelID` (IntValue) y `NombreDisplay` (StringValue)

### En ReplicatedStorage
- [ ] `Config/LevelsConfig` (ModuleScript) con entrada para el nivelID a cargar
- [ ] `Shared/Enums` (ModuleScript) accesible
- [ ] `Shared/Utils/GraphUtils` (ModuleScript) accesible
- [ ] `Audio/SFX/` con al menos `CableConnect` (Sound) y `Error` (Sound)

### Validación de carga
- [ ] `LevelService:loadLevel(1)` no produce `warn` ni `error` en Output
- [ ] `Workspace/NivelActual` existe después de llamar loadLevel
- [ ] `GraphService:loadGrafo("Grafo_Zona1")` reporta el número correcto de nodos
- [ ] `player:GetAttribute("CurrentLevelID")` devuelve el ID correcto
- [ ] `Grafo_Zona1.Meta.Activo` pasa a `true` después de `loadGrafo`

---

*Última actualización: Sistema 2.1 — Grafos por zona, división pre-creado vs runtime, Fase 1 (Carga de Nivel)*
