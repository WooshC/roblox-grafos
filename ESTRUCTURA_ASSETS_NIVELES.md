# Estructura de Assets y Niveles — Sistema 2.0

> **Proposito**: Referencia de la estructura de carpetas para niveles (ServerStorage/Workspace)
> y assets compartidos (ReplicatedStorage). Disenada para la Fase 1 del Sistema 2.0: carga de niveles.
>
> **Regla de oro**: Lo que es fijo y reutilizable vive pre-creado en ReplicatedStorage.
> Lo que varia por contexto de gameplay (posiciones, colores, relaciones entre nodos) se genera en runtime por codigo.

---

## Tabla de Contenido

1. [Estructura de un Nivel](#1-estructura-de-un-nivel)
2. [Jerarquia de Nodos](#2-jerarquia-de-nodos)
3. [Logica de Grafos Multiples](#3-logica-de-grafos-multiples)
4. [Que se pre-crea vs que se genera por codigo](#4-que-se-pre-crea-vs-que-se-genera-por-codigo)
5. [Assets en ReplicatedStorage](#5-assets-en-replicatedstorage)
6. [Notas de Implementacion](#6-notas-de-implementacion)
7. [Checklist — Fase 1 (Carga de Nivel)](#7-checklist--fase-1-carga-de-nivel)

---

## 1. Estructura de un Nivel

El modelo vive en `ServerStorage` y se clona a `Workspace/NivelActual` al cargarse.
El nombre del modelo en ServerStorage debe coincidir con el campo `Modelo` en `LevelsConfig`.

Esta es la estructura **real y de referencia** confirmada en Studio. Cualquier nivel nuevo
debe seguir exactamente esta jerarquia.

```
ServerStorage/
└── Nivel1/                              (Model) ← se clona como "NivelActual"
    │
    ├── DialoguePrompts/                 (Folder) ← ProximityPrompts para iniciar dialogos
    │   └── TestPrompt1/                 (Model)
    │       └── PromptPart               (BasePart)
    │           └── ProximityPrompt      (ProximityPrompt)
    │
    ├── Escenario/                       (Folder) ← geometria visual y colisiones
    │   ├── Colisionadores/              (Folder)
    │   │   ├── Bloqueos/                (Folder) ← InvisibleWalls laterales y limites
    │   │   └── Techos/                  (Folder)
    │   │       └── Techo                (BasePart)
    │   └── Decoracion/                  (Folder) ← Parts puramente visuales
    │
    ├── Grafos/                          (Folder) ← coleccion de todos los grafos del nivel
    │   └── Grafo_Zona1/                 (Folder) ← un grafo por zona de puzzle
    │       ├── Conexiones/              (Folder) ← vacio; Beams se crean aqui en runtime
    │       ├── Meta/                    (Folder) ← metadatos del grafo
    │       │   ├── Activo               (BoolValue)   = false
    │       │   ├── GrafoID              (StringValue) = "Grafo_Zona1"
    │       │   └── RequiereGenerador    (BoolValue)   = true/false
    │       └── Nodos/                   (Folder) ← todos los nodos de este grafo
    │           ├── Nodo1_z1/            (Model)  ← ver seccion 2 para estructura interna
    │           │   ├── Decoracion/      (Model)  ← visual del poste, luces, cables decorativos
    │           │   └── Selector/        (Model)  ← hitbox de interaccion
    │           │       ├── Attachment   (Attachment) ← anclaje para Beams
    │           │       └── ClickDetector (ClickDetector)
    │           ├── Nodo2_z1/            (Model)
    │           │   ├── Decoracion/      (Model)
    │           │   └── Selector/        (Model)
    │           │       ├── Attachment   (Attachment)
    │           │       └── ClickDetector (ClickDetector)
    │           └── Nodo3_z1/            (Model)
    │               ├── Decoracion/      (Model)
    │               └── Selector/        (Model)
    │                   ├── Attachment   (Attachment)
    │                   └── ClickDetector (ClickDetector)
    │
    ├── Meta/                            (Folder) ← metadatos del nivel
    │   ├── Algoritmo                    (IntValue)    ← ID del algoritmo del nivel
    │   ├── NivelID                      (IntValue)    = 1
    │   └── NombreDisplay                (StringValue) = "El Primer Circuito"
    │
    ├── Navegacion/                      (Folder) ← puntos de referencia espaciales
    │   └── Waypoints/                   (Folder) ← ver seccion sobre Waypoints mas abajo
    │
    ├── ObjetosColeccionables/           (Folder) ← objetos con los que el jugador interactua
    │   ├── MapaModel/                   (Model)  ← mapa fisico del nivel en el mundo
    │   └── Tablet_Algoritmos/           (Model)  ← tablet con info del algoritmo del nivel
    │
    ├── Zonas/                           (Folder) ← triggers de gameplay
    │   ├── Zonas_juego/                 (Folder) ← triggers invisibles de gameplay
    │   │   ├── Zona_Estacion_1          (BasePart) ← Transparency=1, CanCollide=false
    │   │   ├── Zona_Estacion_2          (BasePart)
    │   │   ├── Zona_Estacion_3          (BasePart)
    │   │   └── Zona_Estacion_4          (BasePart)
    │   └── Zonas_luz/                   (Folder) ← zonas que controlan iluminacion (opcional)
    │
    ├── SpawnLocation                    (SpawnLocation) ← punto de aparicion del jugador
    └── Carlos/                          (Model) ← NPC guia del nivel (opcional)
```

---

## 2. Jerarquia de Nodos

Cada nodo dentro de `Grafo_ZonaX/Nodos/` sigue esta estructura interna.
La convencion de nombre es `NodoN_zX` donde `N` es el numero del nodo y `X` el numero de zona.

```
Nodo1_z1/                                (Model) ← PrimaryPart debe apuntar a la Part del Selector
│
├── Decoracion/                          (Model) ← todo lo visual: poste, luces, adornos
│   └── (Parts, SpecialMesh, etc.)           no afecta gameplay; solo apariencia
│
└── Selector/                            (Model) ← la parte que el juego "lee" y el jugador clickea
    ├── Attachment                       (Attachment) ← anclaje para Beams de los cables
    └── ClickDetector                    (ClickDetector) ← detecta interaccion del jugador
```

**Por que esta separado en Decoracion y Selector:**
`Decoracion` puede cambiar libremente en Studio sin afectar el gameplay — se pueden
agregar luces, cambiar colores, anadir efectos sin tocar la logica. `Selector` es el
contrato con el codigo: `ConectarCables` siempre busca el `ClickDetector` y el `Attachment`
dentro de `Selector`, sin importar como luzca la decoracion.

> **Nota**: `PrimaryPart` del Model debe apuntar a la Part dentro de `Selector` para que
> los servicios obtengan la posicion world correctamente con `:GetPivot()`.

---

## 3. Logica de Grafos Multiples

Con esta estructura, `ConectarCables` opera sobre un grafo a la vez y puede
activarlos progresivamente conforme el jugador avanza.

```lua
-- ConectarCables recibe el Folder del grafo, no el nivel completo
ConectarCables.activar(nivelActual.Grafos.Grafo_Zona1, adyacencias, jugador, nivelID, callbacks)

-- GestorZonas activa el siguiente grafo al entrar en una zona
-- Jugador entra Zona2
--   → GestorZonas dispara evento
--   → ConectarCables se activa para "Grafo_Zona2"
--   → Grafo_Zona2.Meta.Activo = true
--   → ServicioMisiones registra misiones del nuevo grafo
```

Si `Grafo_Zona2.Meta.RequiereGenerador = false`, recibe energia desde una
conexion proveniente de `Grafo_Zona1`. Esa relacion entre grafos se define
en `LevelsConfig`, no en la jerarquia de instancias del nivel.

---

## 4. Que se pre-crea vs que se genera por codigo

La division no es "todo en ReplicatedStorage" ni "todo por codigo" — es una decision
por tipo de asset segun que tanto varia en runtime.

### Pre-creado en ReplicatedStorage (fijo y reutilizable)

| Asset | Por que pre-crearlo |
|---|---|
| BGM y Ambiente (Sound) | Sus IDs nunca cambian; cargarlos por codigo es innecesario |
| SFX (Sound) | Siempre el mismo sonido para el mismo evento |
| ParticleEmitter base | La textura, fisica y forma base son fijas; solo color/intensidad varia |
| Templates de UI | Estructura HTML/GUI fija; solo el contenido varia por codigo |
| Beam templates | La apariencia base es fija; Attachments se reasignan en runtime |
| BillboardGui templates | El layout es fijo; el texto se escribe por codigo |

### Generado por codigo en runtime (varia por gameplay)

| Asset | Por que generarlo por codigo |
|---|---|
| Beams (cables) | Posicion y longitud dependen de que nodos conecta el jugador |
| Color y propiedades de ParticleEmitter | Cambia segun el estado del nodo, tipo de conexion o evento |
| Highlights / SelectionBox | El objeto seleccionado cambia cada interaccion |
| Tweens de color y posicion | Dependen del estado actual de cada Part |
| Texto en BillboardGui | Nombre del nodo, peso de arista, puntaje — siempre dinamico |
| Attachment0/1 de Beams | Se asignan a los nodos especificos del grafo activo |

### Particulas — regla especifica

El `ParticleEmitter` **nunca** se crea desde cero por codigo. Lo que si hace
`ControladorEfectos` despues de clonar el template es modificar sus propiedades
antes de emitir, por ejemplo:

```lua
-- ControladorEfectos clona el template base
local clone = ReplicatedStorage.Efectos.Particulas.Chispa:Clone()
local emitter = clone:FindFirstChildWhichIsA("ParticleEmitter")

-- Modifica propiedades segun el contexto
emitter.Color = ColorSequence.new(colorDelNodo)   -- color del nodo conectado
emitter.Rate = intensidad                          -- mas intenso si es conexion clave
emitter.SpreadAngle = Vector2.new(spread, spread)  -- mas disperso en errores

clone.Part.CFrame = posicionDelNodo
clone.Parent = workspace
game:GetService("Debris"):AddItem(clone, duracion)
```

Esto permite efectos visualmente distintos (chispa azul para BFS, verde para arbol,
roja para error) sin duplicar emitters en ReplicatedStorage.

---

## 5. Assets en ReplicatedStorage

Todos los assets fijos que servidor y cliente comparten. Se clonan o referencian
desde aqui — nunca se instancian de cero por codigo.

```
ReplicatedStorage/
│
├── Audio/                               (Folder) ← todos los sonidos del juego
│   │
│   ├── SFX/                             (Folder) ← efectos de sonido cortos, no looped
│   │   ├── CableConnect                 (Sound) ← al conectar un cable exitosamente
│   │   ├── CableDisconnect              (Sound) ← al desconectar un cable
│   │   ├── CableSnap                    (Sound) ← intento de conexion invalida
│   │   ├── NodoActivado                 (Sound) ← nodo recibe energia
│   │   ├── NodoApagado                  (Sound) ← nodo pierde energia
│   │   ├── Error                        (Sound) ← accion no permitida
│   │   ├── Click                        (Sound) ← interaccion generica de UI
│   │   ├── Hover                        (Sound) ← hover sobre botones
│   │   ├── MisionCompleta               (Sound) ← mision individual completada
│   │   └── Acierto                      (Sound) ← respuesta/conexion correcta
│   │
│   ├── BGM/                             (Folder) ← musica de fondo, Looped = true
│   │   ├── MenuPrincipal                (Sound)
│   │   ├── Gameplay_Tranquilo           (Sound) ← fase inicial del nivel
│   │   ├── Gameplay_Tenso               (Sound) ← fase final / presion de tiempo
│   │   └── Victoria                     (Sound) ← Looped = false
│   │
│   ├── Ambiente/                        (Folder) ← sonido ambiental, Looped = true
│   │   ├── Electricidad                 (Sound) ← zumbido electrico suave
│   │   └── Viento                       (Sound) ← ambiente exterior
│   │
│   └── Voz/                             (Folder) ← narracion de dialogos, opcional por fase
│       ├── Carlos_Intro_01              (Sound)
│       └── ...
│
├── Efectos/                             (Folder) ← particulas, beams, billboards
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
│   │   └── BeamCable/                   (Model) ← cable visual entre nodos
│   │       ├── Beam                     (Beam)
│   │       ├── Attachment0              (Attachment) ← placeholder
│   │       └── Attachment1              (Attachment) ← placeholder
│   │
│   └── Billboards/                      (Folder) ← templates clonados en runtime
│       └── EtiquetaNodo                 (BillboardGui) ← muestra nombre del nodo
│
├── Config/                              (Folder) ← configuracion del juego
│   └── LevelsConfig                     (ModuleScript) ← definicion de todos los niveles
│
└── Shared/                              (Folder) ← ModuleScripts compartidos server/client
    ├── Constants                        (ModuleScript) ← STUDS_PER_METER, TIMEOUTS, MAX_STARS
    └── Utils/                           (Folder)
        ├── GraphUtils                   (ModuleScript)
        ├── TableUtils                   (ModuleScript) ← countKeys, deepCopy, shallowMerge
        └── TweenUtils                   (ModuleScript) ← helper para tweens reutilizables
```

---

## 6. Notas de Implementacion

### Sonidos en ReplicatedStorage vs SoundService

Los sonidos viven en `ReplicatedStorage/Audio/` porque los servicios (server) los referencia
para replicar efectos, y el cliente tambien puede leerlos para efectos locales.
`SoundService` es mas adecuado para musica global persistente que no necesita ser referenciada por scripts.

### ParticleEmitters — clonar y modificar, nunca crear desde cero

Cada Model en `Efectos/Particulas/` contiene una `BasePart` con el `ParticleEmitter` configurado
con valores base. `ControladorEfectos` lo clona y **antes de emitir** modifica las propiedades
que dependen del contexto: `Color`, `Rate`, `SpeedRange`, `SpreadAngle`, etc.
Esto permite un mismo emitter base producir efectos visualmente distintos segun el gameplay
(color del nodo, tipo de algoritmo, severidad del error) sin duplicar assets.
Ver seccion 4 para el patron de codigo.

### Beams — los Attachments son placeholders

Los templates en `Efectos/Beams/` incluyen `Attachment0` y `Attachment1` como placeholders.
En runtime, `ConectarCables` clona el template y reasigna ambos attachments a los
`Attachment` que ya existen dentro de los nodos del nivel activo.

### Templates de UI — clonar una sola vez

Los templates en `UI/` se clonan **una sola vez** al inicio del cliente y se
muestran/ocultan segun la etapa activa. No se crean nuevas instancias durante
el gameplay para evitar memory leaks.

### Waypoints — para que sirven

Los `Waypoints` dentro de `Navegacion/` son `BasePart` invisibles distribuidas por el
nivel que definen la **ruta sugerida** que el jugador deberia seguir para completar
los objetivos en orden.

`GuiaService` (futuro) los lee en secuencia y mueve un indicador visual (flecha o icono flotante)
hacia el waypoint activo, senalando al jugador hacia donde ir a continuacion. Cuando el
jugador llega o completa el objetivo asociado, `GuiaService` avanza al siguiente waypoint.

```
Navegacion/
└── Waypoints/
    ├── WP_01    ← BasePart invisible, apunta hacia la Tablet_Algoritmos al inicio
    ├── WP_02    ← apunta hacia el Grafo_Zona1 cuando empieza el puzzle
    ├── WP_03    ← apunta hacia un nodo especifico si el jugador se pierde
    └── WP_04    ← apunta hacia la salida cuando el nivel esta completo
```

En el nivel actual no hay waypoints definidos aun — se anaden una vez que el flujo
de misiones este claro. Por ahora `Navegacion/Waypoints/` queda vacio como placeholder.

### Separacion Decoracion / Selector en nodos

`Decoracion` puede modificarse libremente en Studio sin afectar gameplay.
`Selector` es el contrato con el codigo — `ConectarCables` siempre busca
`ClickDetector` y `Attachment` dentro de `Selector` y nunca dentro de `Decoracion`.

### Callbacks Pattern para Sistemas de Gameplay

Los servicios de gameplay se comunican via callbacks en lugar de dependencias directas:

```lua
-- En CargadorNiveles.cargar()
local callbacks = {
    onCableCreado = function(nomA, nomB)
        ServicioMisiones.alCrearCable(nomA, nomB)
        ServicioPuntaje:registrarConexion(jugador)
    end,
    onCableEliminado = function(nomA, nomB)
        ServicioMisiones.alEliminarCable(nomA, nomB)
        ServicioPuntaje:registrarDesconexion(jugador)
    end,
    onNodoSeleccionado = function(nomNodo)
        ServicioMisiones.alSeleccionarNodo(nomNodo)
    end,
    onFalloConexion = function()
        ServicioPuntaje:registrarFallo(jugador)
    end
}

ConectarCables.activar(nivel, adyacencias, jugador, nivelID, callbacks)
```

Esto desacopla `ConectarCables` de los servicios especificos.

---

## 7. Checklist — Fase 1 (Carga de Nivel)

Lo minimo necesario para que `CargadorNiveles.cargar(nivelID, jugador)` funcione correctamente.

### En ServerStorage
- [ ] Model del nivel con nombre exactamente igual al campo `Modelo` en `LevelsConfig`
- [ ] Folder `Grafos/` con al menos un `Grafo_ZonaX/`
- [ ] Cada grafo tiene: `Nodos/` (Folder), `Conexiones/` (Folder vacio), `Meta/` con `GrafoID` y `Activo`
- [ ] Al menos un nodo valido con: `Selector` (Model/BasePart), `ClickDetector`, `Attachment`
- [ ] `PrimaryPart` de cada nodo (Model) apunta a su `Selector`
- [ ] Folder `Zonas/Zonas_juego/` con triggers invisibles para cada zona de misiones
- [ ] `SpawnLocation` en posicion accesible

### En ReplicatedStorage
- [ ] `Config/LevelsConfig` (ModuleScript) con entrada para el nivelID a cargar
- [ ] `Efectos/Beams/BeamCable` (Model) con Beam template
- [ ] `Efectos/Particulas/` con templates de particulas (opcional pero recomendado)

### En LevelsConfig (para el nivel)
- [ ] `Adyacencias` definidas para todos los nodos conectables
- [ ] `NombresNodos` para mostrar nombres amigables
- [ ] `Misiones` array con objetivos del nivel
- [ ] `Zonas` con triggers correspondientes a las parts en `Zonas/Zonas_juego/`
- [ ] `Puntuacion` con umbrales de estrellas

### Validacion de carga
- [ ] `CargadorNiveles.cargar(0, jugador)` no produce `warn` ni `error` en Output
- [ ] `Workspace/NivelActual` existe despues de llamar cargar
- [ ] El jugador aparece en el `SpawnLocation`
- [ ] Los nodos son clickeables (ClickDetector responde)
- [ ] `ServicioMisiones` notifica misiones iniciales al cliente

---

*Ultima actualizacion: Sistema 2.1 — Estructura confirmada en Studio, Callbacks pattern documentado, Fase 1 (Carga de Nivel)*
