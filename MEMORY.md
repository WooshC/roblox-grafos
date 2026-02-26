# EDA Quest — Roblox Grafos Project Memory

## Proyecto
Juego serio educativo de teoría de grafos en Roblox. Lua 5.1. Versión en desarrollo: **v2**.

## Estructura de archivos
- `GarfosV1/` — código de referencia (TYPO: es GarfosV1, no GrafosV1)
- `GrafosV2/` — nueva implementación en progreso
- `SISTEMA_2_PLAN_v2.md` — plan arquitectural completo de v2

## GrafosV2 — Estado actual (Fase 0 completada)

### Archivos creados
```
GrafosV2/
├── crearGUIMenu.lua               ← GUI builder (StarterGui, ejecutar como LocalScript o cmd bar)
├── ReplicatedStorage/
│   └── Config/
│       └── LevelsConfig.lua      ← Fuente única de config de niveles (require desde servidor y cliente)
├── ServerScriptService/
│   ├── EventRegistry.server.lua  ← Crea todos los eventos en ReplicatedStorage/EDAEvents
│   ├── Boot.server.lua           ← Punto entrada servidor, escucha RequestPlayLevel/ReturnToMenu
│   ├── LevelLoader.lua           ← ModuleScript: carga/descarga modelo de nivel
│   └── DataService.lua           ← ModuleScript: DataStore progreso jugador
└── StarterGui/
    └── MenuController.client.lua ← LocalScript: toda la interactividad del menú
```

### Roblox Studio — dónde colocar cada archivo
| Archivo | Ubicación en Studio |
|---------|---------------------|
| crearGUIMenu.lua | StarterGui (LocalScript) |
| EventRegistry.server.lua | ServerScriptService/EDAv2/ (Script) |
| Boot.server.lua | ServerScriptService/EDAv2/ (Script) |
| LevelLoader.lua | ServerScriptService/EDAv2/ (ModuleScript) |
| MenuController.client.lua | StarterGui/EDAv2/ (LocalScript) |

### Orden de ejecución en Roblox
1. EventRegistry (crea EDAEvents en RS) → debe correr ANTES de Boot
2. Boot (require LevelLoader, escucha eventos)
3. Cliente: MenuController (busca EDAQuestMenu en PlayerGui)

### Eventos creados (ReplicatedStorage/EDAEvents/Remotes)
- ServerReady, RequestPlayLevel, LevelReady, LevelUnloaded, UpdateVolume, ReturnToMenu

## Patrones clave
- **No usar _G.Services** — en Fase 0 Boot carga LevelLoader directamente
- Sliders: Track es TextButton, MouseButton1Down + UserInputService.InputChanged
- Nivel se guarda en Workspace como "NivelActual" (clonado desde ServerStorage/Niveles/)

## Flujo menú funcional
1. crearGUIMenu.lua crea la ScreenGui (EDAQuestMenu) en StarterGui
2. MenuController.client.lua espera EDAQuestMenu en PlayerGui y conecta eventos
3. Play → RequestPlayLevel:FireServer(id) → LevelLoader:load() → LevelReady:FireClient()
4. MenuController recibe LevelReady → fade out → root.Visible = false

## Patrones de robustez implementados
- LevelLoader: LoadCharacter en pcall → LevelReady siempre se dispara aunque falle el spawn
- Boot: si pcall de LevelLoader falla → FireClient LevelReady con error (desbloquea pantalla negra)
- Boot: ReturnToMenu → LevelUnloaded:FireClient → MenuController restaura menú
- MenuController: watchdog 10s → si LevelReady no llega, fadeOut + goToLevels
- MenuController: LevelUnloaded handler → root.Enabled=true + setupMenuCamera + goToMenu
- Cámara del menú: workspace:FindFirstChild("CamaraMenu", true) → CameraType.Scriptable + CFrame
- Al entrar al nivel: restoreGameCamera() → CameraType.Custom (sigue al personaje)

## Estado Etapa 4 — Gameplay activo (2026-02-26)

### Archivos Etapa 4 implementados
- `ConectarCables.lua` — lógica conexión/desconexión, adyacencias, Beam celeste
- `ScoreTracker.lua` — aciertos/fallos/cronómetro
- `VisualEffectsService.client.lua` — Highlight AlwaysOnTop + Material Neon en Selector
- `ZoneTriggerManager.lua` — Touched+TouchEnded, ZoneEntered+ZoneExited BindableEvents

### Archivos creados Fase 3b (completado)
- `GrafosV2/ReplicatedStorage/Shared/VisualEffectsConfig.lua` — constantes Colors/Durations/Effects (requirable desde ambos lados)
- `GrafosV2/ServerScriptService/VisualEffectsManager.lua` — VEM.init(remotes) / VEM.fire(player, type, ...) / VEM.fireAll(type, ...)

### VisualEffectsService.client.lua — ampliaciones
- `addBillboard(part, color)` — BillboardGui con `AlwaysOnTop=true` para visibilidad cross-room
- `clearAll()` ahora también destruye `_billboards[]`
- `highlightNode()` llama a `addBillboard()` además de Highlight + styleBasePart
- Escucha `PlayEffect` RemoteEvent: NodeSelected, NodeError, NodeEnergized, CableConnected, CableRemoved, ZoneComplete, ClearAll

## Bug fixes aplicados (2026-02-26)
- **Boot.server.lua**: `config.Zonas` (dict) → ahora se convierte con `buildZonasArray()` antes de llamar ZoneTriggerManager. Sin esta conversión `#dict==0` hacía que ZTM retornara inmediatamente.
- **VisualEffectsService.client.lua**: `FindFirstChild("PlayEffect")` → `WaitForChild("PlayEffect", 5)` para garantizar que se conecte aunque EventRegistry tarde.
- **GameplayManager.server.lua**: eliminado. Era redundante con Boot (punto de entrada único).
- **LevelsConfig.lua**: simplificado — solo campos que el código actual lee. Misiones, Objetos, Guia, Audio, BonusTiempo, Nodos eliminados.

## Patrones de estructura de nivel esperados (Studio)
```
NivelActual/
├── Grafos/
│   └── Grafo_ZonaX/
│       ├── Nodos/
│       │   └── NodoModel/
│       │       ├── Decoracion/
│       │       └── Selector/           ← BasePart o Model
│       │           ├── Attachment
│       │           └── ClickDetector
│       └── Conexiones/                 ← carpeta vacía (Beams se crean en runtime)
└── Zonas/
    └── Zonas_juego/
        ├── ZonaTrigger_Estacion1       ← BasePart, CanCollide=false, Transparency=1
        ├── ZonaTrigger_Estacion2
        ├── ZonaTrigger_Estacion3
        └── ZonaTrigger_Estacion4
```

## Etapa 5 completada (2026-02-26) — Sistema de misiones

### Archivos nuevos/modificados
- `MissionService.lua` — evalúa NODO_SELECCIONADO, ARISTA_CREADA, ARISTA_DIRIGIDA, GRADO_NODO, GRAFO_CONEXO; misiones permanentes; dispara UpdateMissions y LevelCompleted
- `HUDController.client.lua` — reescrito: panel misiones dinámico + pantalla de victoria
- `ConectarCables.lua` — 5to param `missionService`; callbacks onCableCreated/Removed/onNodeSelected
- `LevelsConfig.lua` — Misiones en Nivel 0; NombresPostes → NombresNodos
- `VisualEffectsService.client.lua` — billboard muestra NombresNodos del nodo
- `00_EventRegistry.lua` — +UpdateMissions, +LevelCompleted, +RestartLevel RemoteEvents
- `Boot.server.lua` — carga MissionService; ZoneEntered/Exited→MissionService; RestartLevel handler

### Flujo de misiones
1. Boot activa MissionService.activate(config, nivelID, player, remotes, ScoreTracker)
2. ConectarCables llama onCableCreated/Removed/onNodeSelected en MissionService
3. Boot conecta ZoneEntered/Exited BindableEvents → MissionService.onZoneEntered/Exited
4. Misiones completadas → UpdateMissions:FireClient → HUDController.rebuildMisionPanel
5. allComplete → LevelCompleted:FireClient(finalize()) → showVictory

## Próximas fases pendientes
- Verificar estructura de nivel en Studio (Grafos/Grafo_ZonaX/Nodos/ y Zonas/Zonas_juego/)
- Guardar resultado en DataService al completar nivel
- Calcular estrellas en VictoriaFondo (TresEstrellas/DosEstrellas)
