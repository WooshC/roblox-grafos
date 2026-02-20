# Sprint 1 — Estabilización del Flujo Menú ↔ Juego

> **Marco**: Scrum
> **Duración**: 2 semanas
> **Objetivo del sprint**: Corregir los fallos críticos que rompen la experiencia jugable de Nivel 0 y garantizar que el flujo Menú → Juego → Menú funcione de forma robusta y sin artefactos visuales.

---

## Épicas del Sprint

| ID | Épica | Descripción |
|----|-------|-------------|
| E-01 | Flujo Menú ↔ Juego | Todo lo relacionado con transiciones, visibilidad de GUI, cámara y música entre el menú principal y el gameplay |
| E-02 | Estabilidad de Servicios | Corrección de race conditions en la inicialización del servidor que causan fallos silenciosos en gameplay |
| E-03 | Integridad de Recompensas | Eliminar la doble entrega de XP/dinero/estrellas al completar un nivel |

---

## Product Backlog — Sprint 1

### E-01 · Flujo Menú ↔ Juego

---

#### US-01 · Ocultar GUIExplorador al regresar al Menú
**Como** jugador,
**cuando** completo un nivel y el sistema me devuelve al Selector de Niveles,
**quiero** que la GUI de gameplay (paneles de misiones, matriz, mapa, etc.) desaparezca completamente,
**para** que el menú principal se vea limpio sin elementos del juego encima.

**Criterios de aceptación**
- [ ] La ScreenGui `GUIExplorador` se deshabilita (`Enabled = false`) antes de mostrar el Selector de Niveles.
- [ ] Al entrar de nuevo a un nivel (StartGame), la GUI se vuelve a habilitar correctamente.
- [ ] No hay parpadeo: la GUI se oculta durante el fade-to-black, no después.

**Archivos afectados**
- `StarterGUI/MenuCameraSystem.client.lua` — handler del evento `OpenMenu`

**Prioridad**: Alta — bloqueante visual reportado
**Estimación**: 1 punto

---

#### US-02 · Ocultar GUIExplorador al iniciar el menú por primera vez
**Como** jugador,
**cuando** cargo el juego por primera vez,
**quiero** que la GUI de gameplay no sea visible en el menú principal,
**para** que la pantalla de inicio esté limpia.

**Criterios de aceptación**
- [ ] `GUIExplorador.Enabled` es `false` desde el momento en que carga el script (estado inicial `CurrentLevelID = -1`).
- [ ] El bloque de inicialización de `GUIExplorador.lua` cubre el caso de carga inicial correctamente.

**Archivos afectados**
- `StarterPlayer/StarterPlayerScripts/GUIExplorador.lua` — trigger inicial (ya existe, verificar comportamiento)

**Prioridad**: Media
**Estimación**: 1 punto

---

#### US-03 · Restaurar música y CoreGui al regresar al menú
**Como** jugador,
**cuando** regreso al Selector de Niveles desde el gameplay,
**quiero** que la música del menú se reanude y el CoreGui de Roblox (chat, mochila) permanezca oculto,
**para** tener una experiencia consistente con el primer acceso al menú.

**Criterios de aceptación**
- [ ] `ConfigurarCoreGui(false)` se llama correctamente en el handler de `OpenMenu` (ya implementado — verificar).
- [ ] `CambiarMusica(CamarasTotales.SelectorCamara)` se invoca y la música cambia sin cortes abruptos.
- [ ] Si el jugador abre y cierra el mismo escenario varias veces, la música no se reinicia innecesariamente.

**Archivos afectados**
- `StarterGUI/MenuCameraSystem.client.lua`

**Prioridad**: Media
**Estimación**: 1 punto

---

### E-02 · Estabilidad de Servicios

---

#### US-04 · Eliminar la race condition en la inicialización de servicios
**Como** desarrollador,
**cuando** el servidor arranca,
**quiero** que los scripts de gameplay (`ConectarCables`, `GameplayEvents`, `GraphTheoryService`, `SistemaUI_reinicio`) esperen a que `Init.server.lua` haya registrado todos los servicios en `_G.Services`,
**para** eliminar los fallos silenciosos causados por `task.wait(1)` hardcodeado.

**Causa raíz**: Todos los scripts de gameplay leen `_G.Services.*` después de un `task.wait(1)` fijo. Si `Init` tarda más, los servicios son `nil` y el gameplay falla sin ningún error visible.

**Criterios de aceptación**
- [ ] `Init.server.lua` dispara un `BindableEvent` llamado `ServicesReady` después de registrar todos los servicios.
- [ ] Cada script de gameplay reemplaza `task.wait(1)` por `ServicesReady.Event:Wait()`.
- [ ] El juego funciona correctamente aunque el servidor tarde más de 2 segundos en inicializar.

**Archivos afectados**
- `ServerScriptService/Init.server.lua`
- `ServerScriptService/Gameplay/ConectarCables.server.lua`
- `ServerScriptService/Gameplay/GameplayEvents.server.lua`
- `ServerScriptService/Gameplay/GraphTheoryService.server.lua`
- `ServerScriptService/Gameplay/SistemaUI_reinicio.server.lua`

**Prioridad**: Alta — bug crítico P0
**Estimación**: 3 puntos

---

#### US-05 · Eliminar el listener duplicado de RequestPlayLevel
**Como** desarrollador,
**cuando** un jugador solicita jugar un nivel,
**quiero** que la solicitud se procese exactamente una vez,
**para** evitar que el nivel se cargue dos veces o que los servicios se inicialicen en estado inconsistente.

**Causa raíz**: Tanto `Init.server.lua` (~L169) como `ManagerData.lua` conectan `RequestPlayEvent.OnServerEvent`, procesando la misma petición dos veces en carrera.

**Criterios de aceptación**
- [ ] Solo existe un punto de escucha para `RequestPlayEvent.OnServerEvent`.
- [ ] El listener vive únicamente en `ManagerData.lua` (responsable de la persistencia y del arranque del nivel).
- [ ] El listener en `Init.server.lua` queda eliminado.

**Archivos afectados**
- `ServerScriptService/Init.server.lua`
- `ServerScriptService/Base_Datos/ManagerData.lua`

**Prioridad**: Alta — bug crítico P0
**Estimación**: 2 puntos

---

### E-03 · Integridad de Recompensas

---

#### US-06 · Corregir la doble entrega de recompensas al completar un nivel
**Como** jugador,
**cuando** completo un nivel,
**quiero** recibir mis XP, dinero y estrellas exactamente una vez,
**para** que mi progreso guardado sea correcto.

**Causa raíz**:
`MissionService.checkVictoryCondition()` llama a `RewardService:giveCompletionRewards()` **y** dispara `LevelCompletedEvent`.
`GameplayEvents.server.lua` escucha ese evento y llama a `giveCompletionRewards()` **una segunda vez**.
El jugador recibe todo el doble.

**Criterios de aceptación**
- [ ] `giveCompletionRewards()` se llama exactamente una vez por victoria.
- [ ] `MissionService` solo dispara el evento; no llama directamente a `RewardService`.
- [ ] `GameplayEvents` es el único punto que llama a `giveCompletionRewards()` en respuesta al evento.
- [ ] Las leaderstats del jugador muestran valores correctos tras completar el nivel.

**Archivos afectados**
- `ServerScriptService/Services/MissionService.lua`
- `ServerScriptService/Gameplay/GameplayEvents.server.lua`

**Prioridad**: Alta — bug crítico P0
**Estimación**: 2 puntos

---

## Resumen del Sprint Backlog

| ID | Historia | Épica | Prioridad | Puntos | Estado |
|----|----------|-------|-----------|--------|--------|
| US-01 | Ocultar GUIExplorador al regresar al menú | E-01 | Alta | 1 | **En progreso** |
| US-02 | Ocultar GUIExplorador al inicio | E-01 | Media | 1 | Pendiente |
| US-03 | Restaurar música y CoreGui al regresar | E-01 | Media | 1 | Pendiente |
| US-04 | Race condition en inicialización de servicios | E-02 | Alta | 3 | Pendiente |
| US-05 | Listener duplicado de RequestPlayLevel | E-02 | Alta | 2 | Pendiente |
| US-06 | Doble entrega de recompensas | E-03 | Alta | 2 | Pendiente |
| **Total** | | | | **10 pts** | |

---

## Definition of Done (DoD)

Una historia se considera **Done** cuando:
1. El cambio de código está implementado y no rompe otras funcionalidades.
2. El comportamiento descrito en los criterios de aceptación puede verificarse manualmente en Roblox Studio (Play Solo o playtest en servidor local).
3. No aparecen errores nuevos en el Output de Roblox Studio relacionados con los archivos modificados.
4. El archivo `DEUDA_TECNICA.md` refleja el ítem como resuelto.

---

## Elementos fuera del Sprint 1 (Product Backlog)

Los siguientes ítems son reconocidos pero quedan para sprints futuros:

| Ítem | Severidad | Sprint sugerido |
|------|-----------|-----------------|
| `#hashTable` siempre 0 — `getLevelProgress`, `calculateEnergy`, `findCriticalNodes` | P1 | Sprint 2 |
| `AudioService.fadeInSound` nunca ejecuta (RenderStepped en servidor) | P1 | Sprint 2 |
| `AlgorithmService` pasa Instance en lugar de string a Dijkstra | P1 | Sprint 2 |
| Tres implementaciones de Dijkstra incompatibles | P1 | Sprint 2 |
| `Zona1_dialogo.lua`: Model no tiene .Position (crash en cutscene) | P1 | Sprint 2 |
| Eliminar `NivelUtils.lua` y centralizar en `AliasUtils.lua` | P2 | Sprint 3 |
| Niveles 1–4: implementar contenido real | Feature | Sprint 4+ |
| Crear `TableUtils.lua`, `SharedDialogConfig.lua`, `Constants.lua` | Refactoring | Sprint 3 |
| Eliminar `_G.Services` como service locator global | Arquitectura | Sprint 4 |
