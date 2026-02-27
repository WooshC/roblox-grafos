# Sistema 2.0 — Plan de Arquitectura MEJORADO v3

> **Regla de Oro**: Un punto de entrada. Mientras esté el menú activo, TODO lo relacionado al gameplay está completamente desconectado.
>
> **Principio**: Separación estricta entre "Sistema de Menú" y "Sistema de Gameplay". Nunca deben coexistir activos.

---

## Estado Actual (Problemas Identificados)

### 1. Desconexión Incompleta del Gameplay
| Problema | Ubicación | Impacto |
|----------|-----------|---------|
| `VisualEffectsService` no tiene `deactivate()` | Cliente | Highlights persistentes al volver al menú |
| `ZoneTriggerManager` conserva `_player` referencia | Servidor | Referencias huérfanas |
| Múltiples listeners en `ClientBoot` no se desconectan | Cliente | Memory leaks potenciales |
| `HUDMapa` puede quedar abierto al salir | Cliente | Estado inconsistente de UI |

### 2. Redundancia en Manejo de Cámara
```
HUDMapa/CameraManager.lua  →  savePlayerCamera(), hideRoof()
Effects/CameraEffects.lua  →  saveState(), hideRoof()
ClientBoot.lua             →  setCameraGame(), setCameraMenu()
MenuController.lua         →  setupMenuCamera()
```
**Problema**: 4 lugares diferentes manejan la cámara. Debe haber UNO solo.

### 3. Módulos con Múltiples Responsabilidades
| Módulo | Responsabilidades Actuales | Debería ser |
|--------|---------------------------|-------------|
| `ConectarCables` | Lógica de cables + Efectos visuales (pulse) + Score tracking | Solo lógica de cables |
| `MissionService` | Validación de misiones + Guardar en DataStore + Calcular estrellas | Solo validación |
| `HUDController` | Orquestador + Recibe eventos + Delega | Mezcla confusa |

### 4. Falta de GameplayOrchestrator
Actualmente `Boot.server.lua` activa/desactiva manualmente cada módulo:
```lua
-- Código actual (problema)
MissionService.activate(...)
ConectarCables.activate(...)
ZoneTriggerManager.activate(...)
ScoreTracker:startLevel(...)
-- ... y así con 5+ módulos
```

Debería ser:
```lua
-- Código deseado
GameplayOrchestrator:startLevel(...)
-- ...
GameplayOrchestrator:stopLevel()
```

---

## Nueva Arquitectura: "El Gran Interruptor"

### Concepto Central
```
┌─────────────────────────────────────────────────────────────────┐
│                        SERVIDOR                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │               GameplayOrchestrator                      │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐    │   │
│  │  │ Cables  │  │  Zonas  │  │ Misiones│  │  Score  │    │   │
│  │  │ Module  │  │ Module  │  │ Module  │  │ Module  │    │   │
│  │  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘    │   │
│  │       └─────────────┴─────────────┴─────────────┘       │   │
│  │                      ↓ UN SOLO activate()                │   │
│  └─────────────────────────────────────────────────────────┘   │
│                           ↑↓                                    │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                  MenuOrchestrator (siempre activo)      │   │
│  │         Solo maneja: UI + Cámara Menú + Progreso        │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              ↑↓
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENTE                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              ClientGameplayOrchestrator                 │   │
│  │     Activa/desactiva TODO el gameplay visual a la vez   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                           ↑↓                                    │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              ClientMenuOrchestrator (siempre activo)    │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Estructura de Carpetas NUEVA

```
ServerScriptService/
├── Core/
│   ├── Boot.server.lua              ← Solo carga servicios base
│   ├── EventRegistry.server.lua     ← Sin cambios
│   └── ServerLifecycle.lua          ← NUEVO: Controla estados globales
│
├── Menu/                            ← NUEVO: Todo lo del menú (siempre activo)
│   ├── MenuOrchestrator.lua         ← Gestiona estado del menú
│   └── PlayerProgressService.lua    ← Mueve progreso aquí desde DataService
│
└── Gameplay/                        ← Solo existe durante gameplay
    ├── GameplayOrchestrator.lua     ← NUEVO: ÚNICO punto de entrada/salida
    ├── Modules/                     ← NUEVO: Subcarpeta
    │   ├── CableConnectionModule.lua ← Renombrado desde ConectarCables
    │   ├── ZoneTriggerModule.lua     ← Renombrado desde ZoneTriggerManager
    │   └── MissionValidationModule.lua← Renombrado desde MissionService
    └── Services/
        ├── ScoreTracker.lua          ← Solo tracking, sin UI
        └── LevelLifecycle.lua        ← NUEVO: Maneja init/cleanup de nivel

StarterPlayerScripts/
├── Core/
│   ├── ClientBoot.client.lua        ← Refactorizado: solo orquesta
│   └── ClientLifecycle.lua          ← NUEVO: Gestiona estados cliente
│
├── Menu/                            ← NUEVO: Todo lo del menú (siempre activo)
│   ├── ClientMenuOrchestrator.lua   ← Gestiona menú + cámara menú
│   ├── MenuController.client.lua    ← Mueve aquí
│   └── LevelSelectorUI.lua          ← UI de selección de niveles
│
└── Gameplay/                        ← Solo durante gameplay
    ├── ClientGameplayOrchestrator.lua ← NUEVO: ÚNICO punto de entrada/salida
    ├── HUD/
    │   ├── HUDController.client.lua   ← Mueve aquí, simplificado
    │   ├── Modules/
    │   │   ├── ScoreDisplay.lua       ← Solo muestra puntaje
    │   │   ├── MissionPanel.lua       ← Solo misiones
    │   │   ├── VictoryScreen.lua      ← Solo pantalla victoria
    │   │   └── MapSystem/
    │   │       ├── MapOrchestrator.lua  ← NUEVO: Controla TODO el mapa
    │   │       ├── CameraController.lua ← Solo cámara del mapa
    │   │       └── RoofController.lua   ← Solo techo/colisiones
    │   └── HUDLifecycle.lua           ← NUEVO: Init/cleanup de HUD
    │
    └── Visual/
        ├── VisualEffectsService.client.lua  ← Refactorizado con cleanup
        └── NodeHighlighter.lua              ← Solo highlights de nodos

ReplicatedStorage/
├── Config/
│   └── LevelsConfig.lua
├── Shared/
│   ├── Constants.lua
│   ├── VisualEffectsConfig.lua
│   └── Enums.lua
└── Effects/
    ├── CameraEffects.lua            ← DEPRECADO: Mover a CameraController
    ├── NodeEffects.lua              ← DEPRECADO: Mover a NodeHighlighter
    ├── ZoneEffects.lua              ← DEPRECADO: Integrar en ZoneTriggerModule
    └── TweenPresets.lua             ← Mantener como utilidad
```

---

## Contratos de Módulos (Interfaz Estándar)

### Todo módulo de Gameplay DEBE implementar:

```lua
local MyModule = {}

-- Estado
MyModule._active = false
MyModule._cleanupFns = {}  -- Funciones de limpieza registradas

-- ═══════════════════════════════════════════════════════════════════════════════
-- ACTIVATE: Iniciar el módulo. SOLO aquí se conectan eventos/listeners.
-- ═══════════════════════════════════════════════════════════════════════════════
function MyModule.activate(context)
    if MyModule._active then MyModule.deactivate() end
    
    MyModule._active = true
    MyModule._cleanupFns = {}
    
    -- Registrar cleanup automático
    MyModule._registerCleanup(function()
        -- Desconectar listeners, destruir instancias, etc.
    end)
    
    print("[MyModule] activate")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- DEACTIVATE: Detener completamente. LLAMAR SIEMPRE al salir del gameplay.
-- ═══════════════════════════════════════════════════════════════════════════════
function MyModule.deactivate()
    if not MyModule._active then return end
    
    MyModule._active = false
    
    -- Ejecutar todas las funciones de cleanup registradas
    for _, fn in ipairs(MyModule._cleanupFns) do
        pcall(fn)
    end
    MyModule._cleanupFns = {}
    
    print("[MyModule] deactivate")
end

-- Helper para registrar cleanup
function MyModule._registerCleanup(fn)
    table.insert(MyModule._cleanupFns, fn)
end

return MyModule
```

---

## GameplayOrchestrator (Servidor)

```lua
-- GameplayOrchestrator.lua
-- ÚNICO responsable: Activar/desactivar TODO el sistema de gameplay como unidad.

local GameplayOrchestrator = {}

-- Módulos gestionados (orden importa para inicialización)
local MODULES = {}

function GameplayOrchestrator:init()
    MODULES = {
        score       = require(script.Parent.Modules.ScoreTracker),
        cables      = require(script.Parent.Modules.CableConnectionModule),
        zones       = require(script.Parent.Modules.ZoneTriggerModule),
        missions    = require(script.Parent.Modules.MissionValidationModule),
    }
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- INICIAR GAMEPLAY: Llamado UNA VEZ cuando el jugador entra a un nivel
-- ═══════════════════════════════════════════════════════════════════════════════
function GameplayOrchestrator:startLevel(player, nivelID, config)
    print("[GameplayOrchestrator] ▶️ START LEVEL", nivelID)
    
    local context = {
        player = player,
        nivelID = nivelID,
        config = config,
        nivelActual = workspace:FindFirstChild("NivelActual"),
    }
    
    -- ORDEN CRÍTICO de inicialización
    MODULES.score:activate(context)        -- 1. Score primero (otros lo usan)
    MODULES.zones:activate(context)        -- 2. Zonas (misiones dependen de esto)
    MODULES.missions:activate(context)     -- 3. Misiones (necesitan zonas)
    MODULES.cables:activate(context)       -- 4. Cables (necesitan misiones para callbacks)
    
    print("[GameplayOrchestrator] ✅ Gameplay activo")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- DETENER GAMEPLAY: Llamado UNA VEZ cuando el jugador sale del nivel
-- ═══════════════════════════════════════════════════════════════════════════════
function GameplayOrchestrator:stopLevel()
    print("[GameplayOrchestrator] ⏹️ STOP LEVEL")
    
    -- ORDEN INVERSO de limpieza
    MODULES.cables:deactivate()     -- 1. Cables primero (deja de detectar input)
    MODULES.missions:deactivate()   -- 2. Misiones
    MODULES.zones:deactivate()      -- 3. Zonas
    MODULES.score:deactivate()      -- 4. Score al final
    
    print("[GameplayOrchestrator] ⬛ Gameplay detenido")
end

return GameplayOrchestrator
```

---

## ClientGameplayOrchestrator (Cliente)

```lua
-- ClientGameplayOrchestrator.client.lua
-- ÚNICO responsable: Activar/desactivar TODO el gameplay visual.

local ClientGameplayOrchestrator = {}

local SYSTEMS = {}

function ClientGameplayOrchestrator:init()
    SYSTEMS = {
        hud        = require(script.Parent.HUD.HUDLifecycle),
        visualFx   = require(script.Parent.Visual.VisualEffectsService),
        input      = require(script.Parent.Input.InputManager),
    }
end

function ClientGameplayOrchestrator:startGameplay(nivelID)
    print("[ClientGameplayOrchestrator] ▶️ START")
    
    -- 1. Activar HUD
    SYSTEMS.hud:activate(nivelID)
    
    -- 2. Activar efectos visuales
    SYSTEMS.visualFx:activate()
    
    -- 3. Activar input de gameplay
    SYSTEMS.input:activate()
    
    -- 4. Cámara de gameplay (desde ClientOrchestrator)
    self:_setCameraGameplay()
end

function ClientGameplayOrchestrator:stopGameplay()
    print("[ClientGameplayOrchestrator] ⏹️ STOP")
    
    -- ORDEN INVERSO
    SYSTEMS.input:deactivate()      -- 1. Input primero (deja de escuchar)
    SYSTEMS.visualFx:deactivate()   -- 2. Limpiar efectos
    SYSTEMS.hud:deactivate()        -- 3. HUD
    -- 4. Cámara se maneja desde ClientOrchestrator
end

return ClientGameplayOrchestrator
```

---

## ClientOrchestrator (Cliente - Control Maestro)

```lua
-- ClientOrchestrator.client.lua
-- ÚNICO script que decide: ¿Estoy en Menú o en Gameplay?

local ClientOrchestrator = {}

local menuOrchestrator = nil
local gameplayOrchestrator = nil

function ClientOrchestrator:init()
    menuOrchestrator = require(script.Parent.Menu.ClientMenuOrchestrator)
    gameplayOrchestrator = require(script.Parent.Gameplay.ClientGameplayOrchestrator)
    
    menuOrchestrator:init()
    gameplayOrchestrator:init()
    
    -- Escuchar eventos del servidor
    self:_connectServerEvents()
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- TRANSICIÓN: Menú → Gameplay
-- ═══════════════════════════════════════════════════════════════════════════════
function ClientOrchestrator:enterGameplay(nivelID)
    print("[ClientOrchestrator] 🎮 MENU → GAMEPLAY")
    
    -- 1. Desactivar menú COMPLETAMENTE
    menuOrchestrator:deactivate()
    
    -- 2. Activar gameplay
    gameplayOrchestrator:startGameplay(nivelID)
    
    -- 3. Cámara de gameplay
    self:_setCameraGameplay()
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- TRANSICIÓN: Gameplay → Menú
-- ═══════════════════════════════════════════════════════════════════════════════
function ClientOrchestrator:returnToMenu()
    print("[ClientOrchestrator] 🏠 GAMEPLAY → MENU")
    
    -- 1. Desactivar gameplay COMPLETAMENTE
    gameplayOrchestrator:stopGameplay()
    
    -- 2. Activar menú
    menuOrchestrator:activate()
    
    -- 3. Cámara de menú
    self:_setCameraMenu()
end

return ClientOrchestrator
```

---

## Refactorización de Cámara (UNIFICADA)

### Antes (4 lugares):
```lua
-- ClientBoot.lua
local function setCameraMenu() ... end
local function setCameraGame() ... end

-- MenuController.lua
local function setupMenuCamera() ... end

-- CameraEffects.lua
function CameraEffects.tweenToMapView() ... end
function CameraEffects.tweenToPlayerView() ... end

-- CameraManager.lua (wrapper de CameraEffects)
```

### Después (1 solo):
```lua
-- Shared/CameraSystem.lua  (o Server/Client separados si es necesario)
local CameraSystem = {}

-- Estados válidos
CameraSystem.State = {
    MENU     = "menu",      -- Cámara cinemática estática
    GAMEPLAY = "gameplay",  -- Cámara sigue al jugador
    MAP      = "map",       -- Cámara cenital del mapa
}

local currentState = nil
local _cleanup = nil

-- ═══════════════════════════════════════════════════════════════════════════════
-- MENÚ: Cámara estática en posición cinemática
-- ═══════════════════════════════════════════════════════════════════════════════
function CameraSystem:setMenu()
    if currentState == self.State.MENU then return end
    self:_cleanupPrevious()
    
    local camera = workspace.CurrentCamera
    local menuCam = workspace:FindFirstChild("CamaraMenu", true)
    
    camera.CameraType = Enum.CameraType.Scriptable
    if menuCam then
        camera.CFrame = menuCam:IsA("BasePart") and menuCam.CFrame or menuCam.PrimaryPart.CFrame
    end
    
    currentState = self.State.MENU
    print("[CameraSystem] → MENU")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- GAMEPLAY: Cámara sigue al personaje
-- ═══════════════════════════════════════════════════════════════════════════════
function CameraSystem:setGameplay()
    if currentState == self.State.GAMEPLAY then return end
    self:_cleanupPrevious()
    
    local camera = workspace.CurrentCamera
    local player = game.Players.LocalPlayer
    
    camera.CameraType = Enum.CameraType.Custom
    
    local function setSubject(char)
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            camera.CameraSubject = humanoid
        end
    end
    
    if player.Character then
        setSubject(player.Character)
    end
    
    -- Registrar cleanup
    _cleanup = player.CharacterAdded:Connect(setSubject)
    
    currentState = self.State.GAMEPLAY
    print("[CameraSystem] → GAMEPLAY")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- MAPA: Cámara cenital que sigue al jugador
-- ═══════════════════════════════════════════════════════════════════════════════
function CameraSystem:setMap(nivelModel)
    if currentState == self.State.MAP then return end
    self:_cleanupPrevious()
    
    -- Implementación similar a CameraEffects actual
    -- pero con cleanup automático registrado
    
    currentState = self.State.MAP
    print("[CameraSystem] → MAP")
end

function CameraSystem:_cleanupPrevious()
    if _cleanup then
        _cleanup:Disconnect()
        _cleanup = nil
    end
end

return CameraSystem
```

---

## Refactorización de Techos/Colisiones (Módulo Único)

```lua
-- Gameplay/CollisionManager.lua
-- ÚNICO responsable: Gestionar visibilidad de techos y colisiones

local CollisionManager = {}

local _savedStates = {}
local _active = false

-- ═══════════════════════════════════════════════════════════════════════════════
-- CAPTURAR: Guardar estado original de techos del nivel
-- ═══════════════════════════════════════════════════════════════════════════════
function CollisionManager:capture(nivelModel)
    self:release()  -- Limpiar captura previa
    
    local techos = self:_findTechos(nivelModel)
    
    for _, part in ipairs(techos) do
        _savedStates[part] = {
            Transparency = part.Transparency,
            CastShadow = part.CastShadow,
            CanCollide = part.CanCollide,
            CanQuery = part.CanQuery,
        }
    end
    
    print("[CollisionManager] Capturados", #techos, "techos")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- OCULTAR: Hacer techos invisibles/pasables (para mapa)
-- ═══════════════════════════════════════════════════════════════════════════════
function CollisionManager:hideRoof()
    for part, orig in pairs(_savedStates) do
        if part.Parent then
            part.Transparency = 0.95
            part.CastShadow = false
            part.CanQuery = false
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- RESTAURAR: Volver al estado original
-- ═══════════════════════════════════════════════════════════════════════════════
function CollisionManager:restore()
    for part, orig in pairs(_savedStates) do
        if part.Parent then
            part.Transparency = orig.Transparency
            part.CastShadow = orig.CastShadow
            part.CanCollide = orig.CanCollide
            part.CanQuery = orig.CanQuery
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- LIBERAR: Limpiar referencias
-- ═══════════════════════════════════════════════════════════════════════════════
function CollisionManager:release()
    _savedStates = {}
end

return CollisionManager
```

---

## Eventos y Comunicación

### Eventos de Gameplay (BindableEvents - Servidor)
```lua
-- Server/BindableEvents.lua
local Events = {}

-- Gameplay → Otros sistemas gameplay
Events.Gameplay = {
    ZoneEntered     = BindableEvent,  -- { player, zoneName }
    ZoneExited      = BindableEvent,  -- { player, zoneName }
    CableCreated    = BindableEvent,  -- { from, to }
    CableRemoved    = BindableEvent,  -- { from, to }
    NodeSelected    = BindableEvent,  -- { nodeName }
    MissionComplete = BindableEvent,  -- { missionID }
    ScoreChanged    = BindableEvent,  -- { newScore }
}

-- GameplayOrchestrator → Server
Events.Lifecycle = {
    LevelStarted    = BindableEvent,  -- { nivelID, player }
    LevelCompleted  = BindableEvent,  -- { nivelID, player, stats }
    LevelAbandoned  = BindableEvent,  -- { nivelID, player }
}

return Events
```

### Eventos Cliente-Servidor (RemoteEvents)
```lua
-- Solo estos eventos cruzan la red:
Remotes = {
    -- Servidor → Cliente
    LevelReady       = RemoteEvent,  -- Inicia gameplay
    LevelUnloaded    = RemoteEvent,  -- Termina gameplay
    UpdateScore      = RemoteEvent,  -- Puntaje actualizado
    UpdateMissions   = RemoteEvent,  -- Estado misiones
    LevelCompleted   = RemoteEvent,  -- Victoria
    
    -- Cliente → Servidor
    RequestPlayLevel = RemoteEvent,  -- Pedir iniciar nivel
    ReturnToMenu     = RemoteEvent,  -- Volver al menú
    RestartLevel     = RemoteEvent,  -- Reiniciar nivel
    MapNodeClicked   = RemoteEvent,  -- Click en nodo desde mapa
}
```

---

## Plan de Migración Paso a Paso

### Fase 1: Preparación (Sin cambiar comportamiento)
1. Crear `GameplayOrchestrator` vacío que solo loguea
2. Crear `ClientGameplayOrchestrator` vacío
3. Verificar que todo sigue funcionando igual

### Fase 2: Migración Servidor
4. Mover `ConectarCables` → `CableConnectionModule` con contrato activate/deactivate
5. Mover `ZoneTriggerManager` → `ZoneTriggerModule` con contrato
6. Mover `MissionService` → `MissionValidationModule` con contrato
7. Conectar `GameplayOrchestrator` en `Boot.server.lua`
8. Probar: ¿Se activan/desactivan todos juntos?

### Fase 3: Migración Cliente
9. Crear `CameraSystem` unificado
10. Crear `CollisionManager` unificado
11. Mover `VisualEffectsService` → `VisualEffectsController` con cleanup
12. Crear `ClientGameplayOrchestrator`
13. Probar transiciones Menú↔Gameplay

### Fase 4: Limpieza
14. Eliminar archivos deprecados:
    - `CameraEffects.lua` → mover funcionalidad a `CameraSystem`
    - `NodeEffects.lua` → integrar en `VisualEffectsController`
    - `ZoneEffects.lua` → integrar en `ZoneTriggerModule`
    - `HUDMapa/CameraManager.lua` → usar `CameraSystem`

### Fase 5: Validación
15. Test: 10 transiciones Menú→Gameplay→Menú sin memory leaks
16. Test: Mapa se abre/cierra correctamente
17. Test: Reiniciar nivel funciona
18. Test: Al volver al menú, no quedan highlights/efectos

---

## Checklist de "Gameplay Desconectado"

Al volver al menú, verificar que:

- [ ] No hay listeners de input activos (clics en nodos no hacen nada)
- [ ] No hay highlights visibles en el workspace
- [ ] No hay billboards flotando
- [ ] No hay cables siendo renderizados (aunque los objetos existan)
- [ ] La cámara está en modo Menú (Scriptable, posición fija)
- [ ] El HUD de gameplay está oculto completamente
- [ ] No hay música/sonidos de gameplay
- [ ] No hay procesos en segundo plano (tweens, loops)
- [ ] El techo está restaurado a su estado original
- [ ] Las colisiones están restauradas
- [ ] No hay referencias al "NivelActual" en ningún sistema activo

---

## Resumen de Cambios Clave

| Aspecto | Antes | Después |
|---------|-------|---------|
| **Entrada gameplay** | Boot llama 5+ módulos manualmente | Un `GameplayOrchestrator:startLevel()` |
| **Salida gameplay** | Boot llama 5+ deactivate manualmente | Un `GameplayOrchestrator:stopLevel()` |
| **Cámara** | 4 scripts diferentes | Un `CameraSystem` con estados |
| **Techos** | En CameraEffects + CameraManager | Un `CollisionManager` dedicado |
| **Efectos visuales** | Servicio sin cleanup | Controlador con `deactivate()` |
| **Estructura** | Plana, todo mezclado | Separada: Menu/Gameplay/Core |
| **Contratos** | Cada uno diferente | Todos: `activate()` / `deactivate()` |

---

> **Nota final**: Esta arquitectura garantiza que el sistema de menú y el sistema de gameplay sean mutuamente excluyentes. No puede haber "fugas" de estado porque cada sistema es responsable de su propia limpieza y el Orchestrator verifica que todo esté detenido antes de activar el otro.
