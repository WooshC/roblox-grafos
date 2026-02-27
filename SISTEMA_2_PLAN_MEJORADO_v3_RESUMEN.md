# Resumen Ejecutivo - Plan Mejorado v3

## El Problema en una Imagen

```
ANTES (Actual):
┌─────────────────────────────────────────────────────────────────────┐
│                           SERVIDOR                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │
│  │ Conectar     │  │ ZoneTrigger  │  │  Mission     │               │
│  │ Cables       │  │ Manager      │  │  Service     │               │
│  │ (500+ lines) │  │ (240 lines)  │  │  (300 lines) │               │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘               │
│         │                 │                 │                        │
│         ▼                 ▼                 ▼                        │
│  ┌─────────────────────────────────────────────────┐                │
│  │           Boot.server.lua (263 lines)           │                │
│  │  - Activa cada módulo manualmente               │                │
│  │  - Maneja eventos de menú y gameplay            │                │
│  │  - Desconexiones dispersas                      │                │
│  └─────────────────────────────────────────────────┘                │
│                          ❌ PROBLEMA:                                │
│     Si olvidas desactivar uno → memory leak / estado corrupto       │
└─────────────────────────────────────────────────────────────────────┘

DESPUÉS (Propuesto):
┌─────────────────────────────────────────────────────────────────────┐
│                           SERVIDOR                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │
│  │   Cable      │  │    Zone      │  │   Mission    │               │
│  │  Module      │  │   Module     │  │   Module     │               │
│  │(solo cables) │  │(solo zonas)  │  │(solo misiones│               │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘               │
│         │                 │                 │                        │
│         └─────────────────┴─────────────────┘                        │
│                           │                                          │
│                           ▼                                          │
│  ┌─────────────────────────────────────────────────┐                │
│  │      GameplayOrchestrator (único)               │                │
│  │  - Un activate() para todos                     │                │
│  │  - Un deactivate() para todos                   │                │
│  │  - Garantiza limpieza completa                  │                │
│  └─────────────────────────────────────────────────┘                │
│                          ✅ RESULTADO:                               │
│     Imposible olvidar un módulo. Todo se activa/desactiva junto.    │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Las 5 Reglas de Oro de la Nueva Arquitectura

### 1. **Un Punto de Entrada**
```lua
-- ❌ ANTES: Boot.server.lua lin 153-160
ScoreTracker:startLevel(...)
MissionService.activate(...)
ConectarCables.activate(...)
ZoneTriggerManager.activate(...)
-- Si falta uno → BUG

-- ✅ DESPUÉS: Boot.server.lua
GameplayOrchestrator:startLevel(...)
-- Uno solo, siempre completo
```

### 2. **Gameplay y Menú son Excluyentes**
```lua
-- ClientOrchestrator garantiza:
if gameplayActive then
    menuOrchestrator:deactivate()  -- 100% apagado
elseif menuActive then
    gameplayOrchestrator:stop()     -- 100% apagado
end
-- Nunca ambos, nunca ninguno (siempre hay uno activo)
```

### 3. **Todo Módulo tiene Cleanup Automático**
```lua
-- Cada módulo DEBE implementar:
function Module.activate()
    Module._cleanupFns = {}
    -- ... setup ...
end

function Module.deactivate()
    for _, fn in ipairs(Module._cleanupFns) do
        pcall(fn)  -- Siempre ejecutar cleanup
    end
end
```

### 4. **Cámara Unificada**
```lua
-- ❌ ANTES: 4 scripts manejaban cámara
-- ✅ DESPUÉS: 1 solo sistema
CameraSystem:setState("MENU")      -- Menú estático
CameraSystem:setState("GAMEPLAY")  -- Sigue al jugador  
CameraSystem:setState("MAP")       -- Vista cenital
```

### 5. **Techos/Colisiones en Módulo Dedicado**
```lua
-- ❌ ANTES: Código de techos en CameraEffects + CameraManager + HUDMapa
-- ✅ DESPUÉS: Solo en CollisionManager
CollisionManager:capture(nivel)   -- Guarda estado
CollisionManager:hideRoof()       -- Oculta para mapa
CollisionManager:restore()        -- Restaura al salir
```

---

## Cambios Prioritarios (Orden de Implementación)

### 🔴 CRÍTICO - Semana 1
1. **Crear GameplayOrchestrator** (servidor)
   - Mover activación de módulos desde Boot.server.lua
   - Verificar que todos los módulos tengan `deactivate()`

2. **Crear ClientGameplayOrchestrator** (cliente)
   - Mover lógica de activación desde ClientBoot.lua
   - Asegurar cleanup de VisualEffectsService

### 🟡 IMPORTANTE - Semana 2
3. **Unificar Cámara**
   - Crear CameraSystem
   - Migrar ClientBoot, MenuController, CameraEffects

4. **Separar CollisionManager**
   - Extraer de CameraEffects
   - Integrar en HUDMapa y GameplayOrchestrator

### 🟢 OPTIMIZACIÓN - Semana 3
5. **Limpiar archivos deprecados**
   - Eliminar CameraEffects.lua, NodeEffects.lua, etc.
   - Renombrar módulos a convención nueva

6. **Testing exhaustivo**
   - 10 ciclos Menú→Gameplay→Menú
   - Verificar no hay memory leaks
   - Verificar no quedan efectos visuales huérfanos

---

## Módulos que Necesitan `deactivate()` (Lista de Verificación)

| Módulo | Tiene deactivate? | Prioridad |
|--------|------------------|-----------|
| ConectarCables | ✅ Sí | - |
| ZoneTriggerManager | ✅ Sí | - |
| MissionService | ✅ Sí | - |
| VisualEffectsService | ❌ **NO** | 🔴 CRÍTICO |
| HUDMapa | ⚠️ Parcial | 🟡 Alta |
| ScoreTracker | ✅ Sí | - |
| CameraManager | ❌ **NO** | 🟡 Alta |

**Acción inmediata**: Agregar `deactivate()` a `VisualEffectsService.client.lua`

---

## Estructura de Carpetas Final

```
GrafosV2/
├── ServerScriptService/
│   ├── Core/
│   │   ├── Boot.server.lua              ← Mínimo, solo carga Orchestrator
│   │   ├── EventRegistry.server.lua     ← Sin cambios
│   │   └── GameplayOrchestrator.lua     ← NUEVO: Control maestro
│   │
│   ├── GameplayModules/                 ← NUEVO: Solo gameplay
│   │   ├── CableConnectionModule.lua
│   │   ├── ZoneTriggerModule.lua
│   │   └── MissionValidationModule.lua
│   │
│   └── Services/                        ← Servicios transversales
│       ├── ScoreTracker.lua
│       ├── LevelLoader.lua
│       └── DataService.lua
│
├── StarterPlayerScripts/
│   ├── Core/
│   │   ├── ClientBoot.client.lua        ← Refactorizado
│   │   └── ClientGameplayOrchestrator.lua ← NUEVO
│   │
│   ├── Menu/                            ← NUEVO: Siempre activo
│   │   ├── MenuController.client.lua
│   │   └── ClientMenuOrchestrator.lua
│   │
│   └── Gameplay/                        ← Solo durante gameplay
│       ├── HUD/
│       │   ├── HUDController.client.lua
│       │   └── Modules/
│       └── Visual/
│           └── VisualEffectsController.client.lua
│
└── ReplicatedStorage/
    ├── Shared/
    │   └── CameraSystem.lua             ← NUEVO: Cámara unificada
    └── Effects/                         ← DEPRECADO (migrar y eliminar)
```

---

## Métricas de Éxito

Después de implementar, deberías poder:

1. ✅ Entrar a un nivel, jugar 30 segundos, volver al menú → **Sin errores en consola**
2. ✅ Repetir 10 veces → **Sin aumento de memoria** (no hay leaks)
3. ✅ Abrir el mapa, cerrarlo → **Techo restaurado completamente**
4. ✅ Seleccionar nodo, volver al menú → **No quedan highlights ni billboards**
5. ✅ En menú, clicar donde estaba un nodo → **No pasa nada** (input desconectado)

---

## Archivos a Crear/Modificar/Eliminar

### Crear Nuevos (6 archivos)
```
ServerScriptService/Core/GameplayOrchestrator.lua
StarterPlayerScripts/Core/ClientGameplayOrchestrator.lua
StarterPlayerScripts/Menu/ClientMenuOrchestrator.lua
ReplicatedStorage/Shared/CameraSystem.lua
ServerScriptService/GameplayModules/CollisionManager.lua
StarterPlayerScripts/Gameplay/HUD/HUDLifecycle.lua
```

### Modificar (8 archivos)
```
ServerScriptService/Boot.server.lua           ← Simplificar
StarterPlayerScripts/ClientBoot.client.lua    ← Refactorizar
StarterPlayerScripts/MenuController.client.lua ← Mover a Menu/
ServerScriptService/ConectarCables.lua        ← Renombrar a CableConnectionModule
ServerScriptService/ZoneTriggerManager.lua    ← Renombrar a ZoneTriggerModule
ServerScriptService/MissionService.lua        ← Renombrar a MissionValidationModule
StarterPlayerScripts/VisualEffectsService.client.lua ← Agregar deactivate()
StarterPlayerScripts/HUDModules/HUDMapa/init.lua ← Usar nuevos sistemas
```

### Eliminar (4 archivos)
```
ReplicatedStorage/Effects/CameraEffects.lua   ← Migrado a CameraSystem
ReplicatedStorage/Effects/NodeEffects.lua     ← Migrado a VisualEffectsController
ReplicatedStorage/Effects/ZoneEffects.lua     ← Integrado en ZoneTriggerModule
StarterPlayerScripts/HUDModules/HUDMapa/CameraManager.lua ← Reemplazado
```

---

## Conclusión

Esta refactorización transforma el sistema de "muchas piezas que se activan manualmente" a "dos estados mutuamente excluyentes con un interruptor maestro".

**Antes**: Cada transición Menú↔Gameplay requiere recordar 5+ pasos diferentes.
**Después**: Una llamada: `startLevel()` o `stopLevel()`.

**El resultado**: Código más mantenible, menos bugs, y garantía de que el menú y gameplay nunca coexisten.
