# EDA Quest — Arquitectura de Referencia
> Sistema 2.0 · Etapas 1 a 4 · Estado: 2026-02-26
>
> **Regla de oro:** ningún script lee un servicio que aún no existe.
> Cada etapa solo empieza cuando la anterior confirmó que terminó.

---

## Tabla de Contenido
1. [Árbol completo de archivos](#árbol-completo-de-archivos)
2. [Eventos — mapa completo](#eventos--mapa-completo)
3. [Etapa 1 — Menú Principal](#etapa-1--menú-principal)
4. [Etapa 2 — Carga del Nivel](#etapa-2--carga-del-nivel)
5. [Etapa 3 — Gameplay Activo](#etapa-3--gameplay-activo)
6. [Etapa 4 — Victoria y Vuelta al Menú](#etapa-4--victoria-y-vuelta-al-menú)

---

## Árbol completo de archivos

```
ServerScriptService/
├── 00_EventRegistry.lua        Script      — corre PRIMERO; crea todos los eventos
├── Boot.server.lua             Script      — punto de entrada único del servidor
├── DataService.lua             ModuleScript
├── LevelLoader.lua             ModuleScript
├── ScoreTracker.lua            ModuleScript
├── ConectarCables.lua          ModuleScript
├── MissionService.lua          ModuleScript
└── ZoneTriggerManager.lua      ModuleScript

StarterPlayer/StarterPlayerScripts/
├── ClientBoot.lua                      LocalScript
├── MenuController.client.lua           LocalScript
├── HUDController.client.lua            LocalScript
└── VisualEffectsService.client.lua     LocalScript

StarterGui/                             ← GUIs pre-construidas en Studio, NO generar por script
├── EDAQuestMenu       ScreenGui        — menú principal
└── GUIExploradorV2    ScreenGui        — HUD de gameplay

ReplicatedStorage/
├── Config/
│   └── LevelsConfig.lua        ModuleScript — fuente única de verdad de niveles
└── Events/                     ← creado por 00_EventRegistry.lua
    ├── Remotes/
    │   ├── GetPlayerProgress   RemoteFunction
    │   ├── RequestPlayLevel    RemoteEvent
    │   ├── LevelReady          RemoteEvent
    │   ├── LevelUnloaded       RemoteEvent
    │   ├── LevelCompleted      RemoteEvent
    │   ├── UpdateScore         RemoteEvent
    │   ├── UpdateMissions      RemoteEvent
    │   ├── NotificarSeleccionNodo  RemoteEvent
    │   ├── CableDragEvent      RemoteEvent
    │   ├── PulseEvent          RemoteEvent
    │   ├── ReturnToMenu        RemoteEvent
    │   ├── RestartLevel        RemoteEvent
    │   └── ServerReady         RemoteEvent
    └── Bindables/
        ├── LevelLoaded         BindableEvent
        ├── LevelUnloaded       BindableEvent
        ├── ZoneEntered         BindableEvent
        └── ZoneExited          BindableEvent

ServerStorage/
└── Niveles/
    └── Nivel0      Model — clonado a Workspace/NivelActual al cargar
```

---

## Eventos — mapa completo

| Evento | Tipo | Emisor | Receptor | Cuándo |
|---|---|---|---|---|
| `ServerReady` | RemoteEvent | Boot | MenuController | Servidor listo tras copiar GUI |
| `GetPlayerProgress` | RemoteFunction | MenuController | DataService | Cargar tarjetas de nivel |
| `RequestPlayLevel` | RemoteEvent | MenuController | Boot | Jugador presiona Jugar |
| `LevelReady` | RemoteEvent | LevelLoader | ClientBoot, MenuController, HUDController | Nivel cargado y personaje listo |
| `UpdateScore` | RemoteEvent | ScoreTracker | HUDController | Puntaje base cambia durante gameplay |
| `UpdateMissions` | RemoteEvent | MissionService | HUDController | Estado de misiones cambia |
| `NotificarSeleccionNodo` | RemoteEvent | ConectarCables | VisualEffectsService | Nodo seleccionado / conexión / error |
| `CableDragEvent` | RemoteEvent | ConectarCables | VisualEffectsService | Preview de arrastre de cable |
| `PulseEvent` | RemoteEvent | ConectarCables | VisualEffectsService | Flujo de energía en cable |
| `LevelCompleted` | RemoteEvent | MissionService | HUDController | Todas las misiones completas |
| `RestartLevel` | RemoteEvent | HUDController | Boot | Jugador presiona Repetir |
| `ReturnToMenu` | RemoteEvent | HUDController | Boot | Jugador presiona Continuar / Confirmar salir |
| `LevelUnloaded` | RemoteEvent | Boot | ClientBoot, MenuController | Nivel destruido (vuelta al menú) |
| `LevelLoaded` | BindableEvent | LevelLoader | (servicios servidor internos) | Modelo colocado en Workspace |
| `LevelUnloaded` | BindableEvent | LevelLoader | (servicios servidor internos) | Modelo destruido de Workspace |
| `ZoneEntered` | BindableEvent | ZoneTriggerManager | Boot → MissionService | Jugador entra en zona |
| `ZoneExited` | BindableEvent | ZoneTriggerManager | Boot → MissionService | Jugador sale de zona |

---

## Etapa 1 — Menú Principal

El jugador siempre llega aquí al conectarse. No se carga ningún sistema de gameplay.

### Responsabilidades

| Archivo | Responsabilidad única |
|---|---|
| `00_EventRegistry.lua` | Crea **todos** los RemoteEvents y BindableEvents antes que cualquier otro script. |
| `Boot.server.lua` | Inicia DataService, copia StarterGui → PlayerGui manualmente, dispara `ServerReady`. |
| `DataService.lua` | Carga datos del jugador desde DataStore. Expone `getProgressForClient()`. |
| `ClientBoot.lua` | **Autoridad única** sobre `.Enabled` de ScreenGuis y `CameraType`. Al arrancar: menú ON, HUD OFF, cámara Scriptable. |
| `MenuController.client.lua` | Renderiza tarjetas de nivel, InfoContent/StatsGrid, navegación S1↔S2, envía `RequestPlayLevel`. **Nunca** toca `.Enabled` ni `CameraType`. |

### Flujo de arranque

```
Servidor arranca
  ├── 00_EventRegistry.lua  →  crea Events/Remotes/* y Events/Bindables/*
  └── Boot.server.lua
        ├── DataService:load(player)
        ├── copyGuiToPlayer(player)       ← CharacterAutoLoads=false; Roblox no lo hace solo
        └── task.delay(2) → ServerReady:FireClient(player)

Cliente recibe ServerReady
  └── MenuController → GetPlayerProgress:InvokeServer()
        └── buildGrid(data)  →  tarjetas + InfoContent
```

### Árbol de GUI — EDAQuestMenu

```
EDAQuestMenu  (ScreenGui)
├── FrameMenu      (S1)
│   └── MenuPanel
│       ├── BtnPlay
│       ├── BtnSettings
│       ├── BtnCredits
│       └── BtnExit
├── FrameLevels    (S2)
│   ├── GridArea   (ScrollingFrame)
│   │   └── Card0..Card4   (TextButton — generadas dinámicamente por MenuController)
│   ├── Placeholder          (visible sin selección)
│   ├── InfoContent          (visible al seleccionar tarjeta)
│   │   ├── Hero
│   │   └── InfoBody
│   │       ├── InfoTag, InfoName, InfoDesc
│   │       ├── Stars  (Star1, Star2, Star3)
│   │       ├── StatsGrid
│   │       │   ├── StatScore   →  Valor  (TextLabel)
│   │       │   ├── StatStatus  →  Valor
│   │       │   ├── StatAciert  →  Valor
│   │       │   ├── StatFallos  →  Valor
│   │       │   ├── StatTiempo  →  Valor
│   │       │   └── StatInten   →  Valor
│   │       └── Tags
│   └── PlayButton
├── FrameSettings  (S3 — modal ajustes)
├── FrameCredits   (S4 — modal créditos)
└── FrameExit      (S5 — modal salir)
```

> **Regla — autoridad sobre ScreenGuis:**
> `ClientBoot` es el ÚNICO que cambia `.Enabled` y `CameraType`.
> `MenuController` y `HUDController` nunca los tocan.

---

## Etapa 2 — Carga del Nivel

El jugador presiona Jugar. El servidor carga el modelo, spawna al personaje, activa los servicios. El cliente oculta el menú y activa el HUD.

### Responsabilidades

| Archivo | Responsabilidad única |
|---|---|
| `Boot.server.lua` | Recibe `RequestPlayLevel`. Llama LevelLoader, luego activa ScoreTracker → MissionService → ConectarCables → ZoneTriggerManager en ese orden. |
| `LevelLoader.lua` | Clona modelo desde `ServerStorage/Niveles/` → `Workspace/NivelActual`. Destruye y recrea el personaje. Dispara `LevelReady`. |
| `ClientBoot.lua` | Recibe `LevelReady`: `EDAQuestMenu.Enabled=false`, `GUIExploradorV2.Enabled=true`, `CameraType=Custom`, asigna `CameraSubject` al Humanoid (con fallback a `CharacterAdded` para RestartLevel). |
| `MenuController.client.lua` | Recibe `LevelReady`: solo cierra el LoadingFrame. No toca `.Enabled`. |
| `HUDController.client.lua` | Recibe `LevelReady`: fuerza `CameraType=Custom` (doble seguridad con ClientBoot), resetea fade y estados de UI. |

### Flujo de carga

```
MenuController  →  RequestPlayLevel:FireServer(nivelID)
                                                      │
                                         Boot.server.lua
                                           ├── LevelLoader:load(nivelID, player)
                                           │     ├── LevelLoader:unload()        ← destruye NivelActual anterior
                                           │     ├── clonar modelo → Workspace/NivelActual
                                           │     ├── player:LoadCharacter()  +  teleport a SpawnLocation
                                           │     └── LevelReady:FireClient(player, payload)
                                           │
                                           ├── ScoreTracker:startLevel(player, nivelID, ...)
                                           ├── MissionService.activate(config, nivelID, player, ...)
                                           ├── ConectarCables.activate(nivelActual, adyacencias, player, ...)
                                           └── ZoneTriggerManager.activate(nivelActual, zonasArr, player)

Cliente recibe LevelReady
  ├── ClientBoot      →  Enabled swap  +  CameraType=Custom  +  CameraSubject=Humanoid
  ├── MenuController  →  cierra LoadingFrame
  └── HUDController   →  CameraType=Custom (doble seguridad)  +  resetea UI
```

### Árbol de Workspace/NivelActual

```
Workspace/
└── NivelActual  (Model — clonado desde ServerStorage/Niveles/<Modelo>)
    ├── Grafos/
    │   └── Grafo_ZonaX/
    │       ├── Nodos/
    │       │   └── <NodoModel>/
    │       │       ├── Decoracion/     ← visual, no tocado por lógica de gameplay
    │       │       └── Selector/       ← BasePart de interacción
    │       │           ├── Attachment  ← anclaje para Beam (pre-creado en Studio)
    │       │           └── ClickDetector
    │       └── Conexiones/             ← vacío al cargar; Beams + hitboxes se crean en runtime
    ├── Zonas/
    │   └── Zonas_juego/
    │       ├── ZonaTrigger_Estacion1   ← BasePart, CanCollide=false, Transparency=1
    │       ├── ZonaTrigger_Estacion2
    │       ├── ZonaTrigger_Estacion3
    │       └── ZonaTrigger_Estacion4
    └── SpawnLocation                   ← Enabled=false (LevelLoader la desactiva)
```

> **Regla — CharacterAutoLoads = false:**
> `LevelLoader` es el ÚNICO que llama `player:LoadCharacter()`.
> Fuera de un nivel no existe personaje.

---

## Etapa 3 — Gameplay Activo

El nivel está cargado. El jugador conecta nodos, entra en zonas, y las misiones se evalúan en tiempo real.

### Responsabilidades

| Archivo | Responsabilidad única |
|---|---|
| `ConectarCables.lua` | Lógica pura de conexión/desconexión. Crea Beams + hitboxes. Llama `ScoreTracker:registrarConexion()` **antes** de `crearCable()`. Notifica a MissionService de cada cable creado/eliminado. |
| `ScoreTracker.lua` | Registra `aciertosTotal` (histórico, **nunca baja**), `conexiones` (cables activos, sube y baja), `fallos`. Notifica HUD vía `UpdateScore`. Expone `finalize()` con snapshot completo. |
| `MissionService.lua` | Evalúa misiones contra estado del grafo en cada cambio. Dispara `UpdateMissions` al cliente. Dispara `LevelCompleted` cuando `allComplete=true`. |
| `ZoneTriggerManager.lua` | Detecta entrada/salida de zonas via `Touched`+`TouchEnded`. Dispara `ZoneEntered` y `ZoneExited` (BindableEvents). |
| `HUDController.client.lua` | Muestra puntaje base en HUD (`UpdateScore`). Reconstruye panel de misiones (`UpdateMissions`). Nunca toca `.Enabled`. |
| `VisualEffectsService.client.lua` | Recibe `NotificarSeleccionNodo`. Aplica `Highlight` + `BillboardGui` a nodos seleccionados y adyacentes. Flash rojo en errores. |
| `LevelsConfig.lua` | Fuente única de verdad: `Nombre`, `Adyacencias`, `Zonas` (con campo `Trigger`), `Misiones`, `NombresNodos`, `Puntuacion`. |

### Flujo de conexión de cable

```
Clic 1 — Jugador selecciona Nodo A
  └── ConectarCables → selectNodo(selectorA)
        ├── MissionService.onNodeSelected(nomA)
        └── NotificarSeleccionNodo:FireClient(player, nodoModel, adjModels)
              └── VisualEffectsService → Highlight cyan en A, dorado en adyacentes

Clic 2 — Jugador selecciona Nodo B
  └── ConectarCables → tryConnect(player, selectorA, selectorB)
        │
        ├── isAdjacent(A, B) = true
        │     ├── ScoreTracker:registrarConexion(player)   ← PRIMERO (crítico, ver nota abajo)
        │     ├── crearCable(selectorA, selectorB)
        │     │     ├── Beam celeste + hitbox en Conexiones/
        │     │     └── MissionService.onCableCreated(nomA, nomB)
        │     │           └── checkAndNotify() → evalúa misiones → UpdateMissions:FireClient
        │     └── NotificarSeleccionNodo:FireClient("ConexionCompletada")
        │
        └── isAdjacent(A, B) = false
              ├── ScoreTracker:registrarFallo(player)
              └── NotificarSeleccionNodo:FireClient("ConexionInvalida")
                    └── VisualEffectsService → flash rojo en Nodo B
```

> **⚠️ Regla crítica — orden en `tryConnect()`:**
> `ScoreTracker:registrarConexion()` debe ir **antes** de `crearCable()`.
> `crearCable()` llama `MissionService.onCableCreated()` sincrónicamente,
> que puede disparar `checkAndNotify()` → `finalize()` en el mismo frame.
> Si `registrarConexion` va después, `finalize()` captura `aciertos=0`.

### Flujo de zonas

```
Jugador entra en ZonaTrigger_EstacionX  (Touched)
  └── ZoneTriggerManager → _touchingPerZone[zona][part] = true
        └── transición ninguna→alguna → ZoneEntered:Fire({ player, nombre, primeraVez })
              └── Boot → MissionService.onZoneEntered(nombre)

Jugador sale de ZonaTrigger_EstacionX  (TouchEnded)
  └── ZoneTriggerManager → _touchingPerZone[zona][part] = nil
        └── transición alguna→ninguna → ZoneExited:Fire({ player, nombre })
              └── Boot → MissionService.onZoneExited(nombre)
```

### ScoreTracker — campos internos

| Campo | Comportamiento |
|---|---|
| `aciertosTotal` | Solo sube. Se incrementa en `registrarConexion()`. Nunca baja. Es el valor que `finalize()` devuelve como `snap.aciertos`. |
| `conexiones` | Sube en `registrarConexion()`, baja en `registrarDesconexion()`. Refleja cables activos en este momento. |
| `fallos` | Solo sube. Se incrementa en `registrarFallo()`. |
| `misionPuntaje` | Seteado por `MissionService` vía `setMisionPuntaje()`. Es el puntaje visible en el HUD. |

### Árbol de GUI — GUIExploradorV2 (HUD)

```
GUIExploradorV2  (ScreenGui)
├── BarraSuperior
│   ├── TitleBadge
│   ├── PanelPuntuacion
│   │   └── ContenedorPuntos
│   │       └── Val          (TextLabel — puntaje base, actualizado por UpdateScore)
│   └── BarraBotonesSecundarios
│       └── BtnSalir
├── BarraBotonesMain
│   ├── BtnMisiones          → toggle MisionFrame
│   └── BtnSalir             → muestra ModalSalirFondo
├── MisionFrame              (oculto por defecto)
│   ├── MisHeader
│   │   └── BtnCerrarMisiones
│   └── Cuerpo               (ScrollingFrame — reconstruido en cada UpdateMissions)
├── VictoriaFondo            (oculto — se muestra al recibir LevelCompleted)
│   └── PantallaVictoria
│       └── ContenedorPrincipal
│           ├── VictoriaHead
│           │   ├── TituloVictoria
│           │   └── EstrellasMostrar  (Estrella1, Estrella2, Estrella3)
│           ├── EstadisticasFrame
│           │   ├── FilaTiempo   →  Val  (TextLabel)
│           │   ├── FilaAciertos →  Val
│           │   ├── FilaErrores  →  Val
│           │   └── FilaPuntaje  →  Val
│           └── BotonesFrame
│               ├── BotonRepetir    →  RestartLevel:FireServer(nivelID)
│               └── BotonContinuar  →  ReturnToMenu:FireServer()
└── ModalSalirFondo          (oculto por defecto)
    └── ModalSalir
        ├── BtnCancelarSalir
        └── BtnConfirmarSalir  →  ReturnToMenu:FireServer()
```

> **Regla — nombre del TextLabel de valores:**
> Todos los labels que muestran valores se llaman `Val` (no `Valor`).
> Los scripts buscan `"Val"` primero con fallback a `"Valor"` por compatibilidad.
> Aplica a: `ContenedorPuntos`, `FilaTiempo`, `FilaAciertos`, `FilaErrores`, `FilaPuntaje`,
> y todos los hijos de `StatsGrid` (`StatScore`, `StatAciert`, `StatFallos`, etc.).

---

## Etapa 4 — Victoria y Vuelta al Menú

`MissionService` detecta que todas las misiones están completas. El servidor finaliza el puntaje, guarda el resultado, y el cliente muestra la pantalla de victoria.

### Responsabilidades

| Archivo | Responsabilidad única |
|---|---|
| `MissionService.lua` | Detecta `allComplete` → llama `ScoreTracker:finalize()` → guarda en `DataService` → dispara `LevelCompleted` con el snapshot. |
| `ScoreTracker.lua` | `finalize()` devuelve `{ nivelID, conexiones, aciertos, fallos, tiempo, puntajeBase }`. |
| `DataService.lua` | `saveResult()` persiste `highScore`, `estrellas`, `aciertos`, `fallos`, `tiempoMejor`, `intentos`. |
| `HUDController.client.lua` | Recibe `LevelCompleted` → `showVictory(snap)`: llena `FilaTiempo`, `FilaAciertos` (`snap.aciertos`), `FilaErrores`, `FilaPuntaje`. |
| `Boot.server.lua` | Recibe `RestartLevel`: limpia todo y recarga el mismo nivel. Recibe `ReturnToMenu`: limpia todo y dispara `LevelUnloaded`. |
| `ClientBoot.lua` | Recibe `LevelUnloaded`: `GUIExploradorV2.Enabled=false`, `EDAQuestMenu.Enabled=true`, `CameraType=Scriptable`. |

### Flujo de victoria

```
MissionService → checkAndNotify() → allComplete = true
  │
  ├── ScoreTracker:finalize(player)
  │     └── snap = {
  │           nivelID,
  │           conexiones,          ← cables activos al terminar
  │           aciertos,            ← aciertosTotal histórico (nunca fue 0 si conectó)
  │           fallos,
  │           tiempo,
  │           puntajeBase
  │         }
  │
  ├── DataService:saveResult(player, nivelID, {
  │       highScore   = snap.puntajeBase,
  │       estrellas   = según TresEstrellas / DosEstrellas,
  │       aciertos    = snap.conexiones,
  │       fallos      = snap.fallos,
  │       tiempoMejor = snap.tiempo,
  │       intentos    = intentos + 1
  │   })
  │
  └── LevelCompleted:FireClient(player, snap)
        └── HUDController → showVictory(snap)
              ├── FilaTiempo.Val   = "mm:ss"
              ├── FilaAciertos.Val = snap.aciertos  (fallback: snap.conexiones)
              ├── FilaErrores.Val  = snap.fallos
              └── FilaPuntaje.Val  = snap.puntajeBase
```

### Flujo de RestartLevel

```
BotonRepetir → RestartLevel:FireServer(nivelID)
  │
  └── Boot.server.lua
        ├── MissionService.deactivate()
        ├── ConectarCables.deactivate()
        ├── ZoneTriggerManager.deactivate()
        ├── ScoreTracker:reset(player)
        ├── LevelLoader:unload()  +  player.Character:Destroy()
        └── LevelLoader:load(nivelID, player)      ← igual que primera carga
              └── LevelReady:FireClient(player, payload)
                    └── ClientBoot
                          ├── CameraType = Custom
                          ├── si personaje existe  →  CameraSubject = Humanoid
                          └── si no existe         →  CharacterAdded → asigna Subject
```

### Flujo de ReturnToMenu

```
BotonContinuar (o BtnConfirmarSalir) → ReturnToMenu:FireServer()
  │
  └── Boot.server.lua
        ├── MissionService.deactivate()
        ├── ConectarCables.deactivate()
        ├── ZoneTriggerManager.deactivate()
        ├── ScoreTracker:reset(player)
        ├── LevelLoader:unload()  +  player.Character:Destroy()
        └── LevelUnloaded:FireClient(player)
              │
              ├── ClientBoot
              │     ├── GUIExploradorV2.Enabled = false
              │     ├── EDAQuestMenu.Enabled    = true
              │     └── CameraType = Scriptable  +  CFrame = CamaraMenu
              │
              └── MenuController
                    ├── progressLoaded = false
                    └── loadProgress()
                          └── GetPlayerProgress:InvokeServer()
                                └── reapplySelection() + updateSidebar(LEVELS[selectedLevelID])
```
