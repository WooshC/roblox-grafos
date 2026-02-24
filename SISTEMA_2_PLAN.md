# Sistema 2.0 — Plan de Arquitectura

> **Propósito**: Rediseño completo desde cero. Carga consciente y secuenciada de servicios,
> puntaje con aciertos/fallos/tiempo, efectos de sonido, video y partículas enriquecidos.
>
> **Regla de oro**: Ningún script lee un servicio que aún no existe.
> Cada etapa solo empieza cuando la anterior confirmó que terminó.

---

## Tabla de Contenido

1. [Visión general del flujo](#1-visión-general-del-flujo)
2. [Nueva estructura de carpetas](#2-nueva-estructura-de-carpetas)
3. [Etapa 0 — Boot del servidor](#3-etapa-0--boot-del-servidor)
4. [Etapa 1 — Menú principal](#4-etapa-1--menú-principal)
5. [Etapa 2 — Selector de niveles y puntaje](#5-etapa-2--selector-de-niveles-y-puntaje)
6. [Etapa 3 — Carga del nivel](#6-etapa-3--carga-del-nivel)
7. [Etapa 4 — Gameplay activo](#7-etapa-4--gameplay-activo)
8. [Etapa 5 — Victoria y resultados](#8-etapa-5--victoria-y-resultados)
9. [Etapa 6 — Vuelta al menú](#9-etapa-6--vuelta-al-menú)
10. [Sistema de puntaje 2.0](#10-sistema-de-puntaje-20)
11. [Sistema de efectos](#11-sistema-de-efectos)
12. [Patrones de diseño utilizados](#12-patrones-de-diseño-utilizados)
13. [Orden de implementación](#13-orden-de-implementación)

---

## 1. Visión General del Flujo

```
SERVIDOR arranca
  │
  ▼
[Etapa 0] Boot
  • EventRegistry crea TODOS los RemoteEvents y BindableEvents
  • ServiceLocator inicializa
  • DataService inicia (DataStore)
  • Servicios base se cargan e inyectan
  • BindableEvent "ServerReady" se dispara
  │
  ▼
[Etapa 1] Menú Principal  (cliente llega aquí por defecto)
  • MenuScreen visible
  • Música de menú
  • CameraSystem del menú activo
  • NO se carga nada de gameplay
  │
  ▼  (jugador abre el selector de niveles)
[Etapa 2] Selector de Niveles
  • Llama GetPlayerProgress (RemoteFunction)
  • Servidor devuelve datos de DataStore + LevelsConfig combinados
    { nivelID, nombre, desbloqueado, estrellas, highScore,
      aciertos, fallos, tiempoMejor, algoritmo }
  • UI construye tarjetas con esta info
  • Score panel muestra aciertos/fallos/tiempo del intento previo
  │
  ▼  (jugador presiona "Jugar")
[Etapa 3] Carga del Nivel
  • Cliente muestra pantalla de transición (fade + barra de carga)
  • Servidor recibe RequestPlayLevel(nivelID)
  • LevelLoader:
      1. Duplica modelo de ServerStorage → Workspace/NivelActual
      2. Inicializa GraphService con los postes del nivel
      3. EnergyService se resetea
      4. ScoreTracker resetea aciertos/fallos/cronómetro
      5. GameplayManager activa los scripts de gameplay
  • Servidor dispara RemoteEvent "LevelReady" al cliente
  • Cliente sale del menú, activa HUD
  │
  ▼
[Etapa 4] Gameplay Activo
  • ConectarCables — conectar/desconectar aristas
  • ZoneTriggerManager — dispara diálogos y eventos al entrar en zonas
  • DialogueOrchestrator — reproduce diálogos en secuencia
  • ScoreTracker — suma aciertos, registra fallos, corre el cronómetro
  • MatrixManager (cliente) — actualiza la matriz de adyacencia
  • MissionService — valida objetivos
  • GuiaService — mueve el waypoint al siguiente objetivo
  • EffectsService — efectos de sonido y visuales en cada acción
  │
  ▼  (se completan todas las misiones)
[Etapa 5] Victoria y Resultados
  • ScoreTracker detiene el cronómetro
  • RewardService calcula estrellas, XP, bonus de tiempo
  • DataService guarda el resultado en DataStore
  • Pantalla de resultados: aciertos, fallos, tiempo, estrellas, puntos
  • Efectos de victoria (fanfare, confeti, cámara cinemática)
  │
  ▼  (jugador presiona "Volver al Menú")
[Etapa 6] Cleanup y Vuelta al Menú
  • GameplayManager desactiva todos los scripts de gameplay
  • LevelLoader destruye NivelActual del Workspace
  • GraphService/EnergyService se limpian
  • EffectsService detiene todos los efectos activos
  • Cliente vuelve a Etapa 1
```

---

## 2. Nueva Estructura de Carpetas

```
ReplicatedStorage/
├── Config/
│   ├── LevelsConfig.lua          ← igual, pero con campo Puntuacion mejorado
│   ├── AudioConfig.lua           ← NUEVO: mapeo nombre→assetId de todos los sonidos
│   └── EffectsConfig.lua         ← NUEVO: configuración de efectos de partículas/tweens
│
├── Shared/
│   ├── Constants.lua             ← NUEVO: STUDS_PER_METER, TIMEOUTS, MAX_STARS
│   ├── Enums.lua                 ← (existente, corregido)
│   └── Utils/
│       ├── GraphUtils.lua        ← (existente, corregido)
│       ├── TableUtils.lua        ← NUEVO: countKeys, deepCopy
│       └── TweenUtils.lua        ← NUEVO: helper para tweens reutilizables
│
└── Utilidades/
    └── AliasUtils.lua            ← (existente, sin cambios)

ServerScriptService/
├── Core/
│   ├── Boot.server.lua           ← NUEVO: punto de entrada único del servidor
│   ├── EventRegistry.server.lua  ← NUEVO: crea TODOS los eventos al inicio
│   └── ServiceLocator.lua        ← NUEVO: reemplaza _G.Services
│
├── Data/
│   └── DataService.lua           ← NUEVO: centraliza DataStore (reemplaza ManagerData)
│
├── Services/
│   ├── LevelLoader.lua           ← NUEVO: solo carga/descarga el modelo de nivel
│   ├── GraphService.lua          ← (existente, corregido)
│   ├── EnergyService.lua         ← (existente, corregido)
│   ├── MissionService.lua        ← (existente, simplificado)
│   ├── ScoreTracker.lua          ← NUEVO: aciertos, fallos, cronómetro
│   ├── RewardService.lua         ← (existente, corregido)
│   ├── AudioService.lua          ← (existente, Heartbeat fix)
│   └── EffectsService.lua        ← NUEVO: efectos server-side (explosiones, luces)
│
└── Gameplay/
    ├── GameplayManager.server.lua ← NUEVO: activa/desactiva todos los scripts de gameplay
    ├── ConectarCables.lua         ← (existente, convertido a ModuleScript)
    ├── ZoneTriggerManager.lua     ← NUEVO: detecta zonas y dispara eventos
    ├── DialogueOrchestrator.lua   ← NUEVO: secuencia y coordina diálogos por zona
    └── AlgorithmVisualizer.lua    ← (existente VisualizadorAlgoritmos, corregido)

StarterPlayerScripts/
├── Core/
│   ├── ClientBoot.client.lua     ← NUEVO: punto de entrada único del cliente
│   └── ClientServiceLocator.lua  ← NUEVO: registro de servicios del cliente
│
└── Client/
    ├── Services/
    │   ├── ScoreManager.lua      ← (existente, mejorado con aciertos/fallos/tiempo)
    │   ├── MatrixManager.lua     ← (existente, corregido)
    │   ├── AudioClient.lua       ← (existente)
    │   ├── VisualEffectsService.lua ← (existente, expandido)
    │   ├── NetworkService.lua    ← (existente)
    │   └── GuiaService.lua       ← (existente)
    └── UI/
        ├── MenuScreen.lua        ← gestión de la pantalla del menú
        ├── LevelSelectorUI.lua   ← (existente LevelSelectorClient, refactorizado)
        ├── HUD.lua               ← HUD de gameplay (puntaje, tiempo en vivo)
        ├── VictoryScreen.lua     ← (existente, mejorado)
        └── TransitionScreen.lua  ← NUEVO: fade + barra de carga entre etapas

StarterGui/
└── DialogStorage/
    ├── SharedDialogConfig.lua    ← NUEVO: colores y config de cámara compartidos
    ├── DialogUtils.lua           ← NUEVO: esperarKitLibre(), getPos()
    ├── ZoneDialogActivator.lua   ← NUEVO: boilerplate de activación de zona
    ├── Zona1_dialogo.lua         ← (existente, usa módulos compartidos)
    ├── Zona2_dialogo.lua
    ├── Zona3_dialogo.lua
    └── Zona4_dialogo.lua
```

---

## 3. Etapa 0 — Boot del Servidor

### `EventRegistry.server.lua` (corre PRIMERO, antes que todo)

Responsabilidad única: crear todos los RemoteEvents, RemoteFunctions y BindableEvents en
ReplicatedStorage/Events/ antes de que cualquier otro script los necesite.

```
ReplicatedStorage/Events/
├── Remotes/
│   ├── GetPlayerProgress   (RemoteFunction)
│   ├── RequestPlayLevel    (RemoteEvent)
│   ├── CableDragEvent      (RemoteEvent)
│   ├── LevelReady          (RemoteEvent)  ← NUEVO
│   ├── LevelCompleted      (RemoteEvent)
│   ├── UpdateScore         (RemoteEvent)  ← NUEVO: aciertos/fallos/tiempo en vivo
│   ├── PulseEvent          (RemoteEvent)
│   ├── NotificarSeleccionNodo (RemoteEvent)
│   └── PlayEffect          (RemoteEvent)  ← NUEVO: efectos cliente desde servidor
└── Bindables/
    ├── ServerReady         (BindableEvent) ← NUEVO: señal que el servidor terminó de cargar
    ├── LevelLoaded         (BindableEvent)
    ├── LevelUnloaded       (BindableEvent)
    ├── ScoreChanged        (BindableEvent) ← NUEVO
    ├── ZoneEntered         (BindableEvent) ← NUEVO
    ├── DialogueRequested   (BindableEvent) ← NUEVO
    ├── OpenMenu            (BindableEvent)
    ├── GuiaAvanzar         (BindableEvent)
    └── RestaurarObjetos    (BindableEvent)
```

### `Boot.server.lua` — Secuencia de inicio garantizada

```lua
-- Pseudocódigo del flujo

-- 1. Esperar EventRegistry (corre antes por orden de script)
-- 2. Cargar DataService e iniciar sesión DataStore
-- 3. Cargar servicios en orden:
--      GraphService → EnergyService → MissionService
--      → ScoreTracker → RewardService → AudioService
--      → EffectsService → LevelLoader
-- 4. Inyectar dependencias entre servicios
-- 5. Configurar listeners de eventos globales:
--      RequestPlayLevel → LevelLoader:load(nivelID)
--      LevelLoaded     → activar GameplayManager
--      LevelUnloaded   → desactivar GameplayManager
-- 6. Registrar todos los servicios en ServiceLocator
-- 7. Disparar BindableEvent "ServerReady"
```

### `ServiceLocator.lua` — Reemplaza `_G.Services`

```lua
-- En lugar de _G.Services.Level, cualquier script hace:
local ServiceLocator = require(path.to.ServiceLocator)
local LevelLoader = ServiceLocator:get("LevelLoader")

-- ServiceLocator también ofrece:
ServiceLocator:waitFor("LevelLoader")  -- espera hasta que esté disponible
```

**Ventaja**: no hay race conditions. Los scripts nunca usan `task.wait(1)`.
Los scripts de Gameplay se cargan DESPUÉS de que `LevelLoaded` se dispara,
no al inicio del servidor.

---

## 4. Etapa 1 — Menú Principal

**Quién lo maneja**: `ClientBoot.client.lua` + `MenuScreen.lua`

Al conectarse, el cliente:
1. Espera la señal `ServerReady` (BindableEvent vía RemoteEvent si es necesario)
2. Activa `MenuScreen` — solo muestra el menú principal
3. Activa `MenuCameraSystem` — cámara cinemática del menú
4. Reproduce música de menú vía `AudioClient`
5. **No carga ningún sistema de gameplay**

### Transición al Selector de Niveles

Cuando el jugador presiona "Jugar":
1. `MenuScreen` dispara evento local `OpenLevelSelector`
2. `LevelSelectorUI` recibe el evento y llama `GetPlayerProgress:InvokeServer()`
3. Transición suave con fade

---

## 5. Etapa 2 — Selector de Niveles y Puntaje

### Datos que el servidor devuelve (ampliados)

```lua
-- GetPlayerProgress devuelve por cada nivel:
{
  Unlocked   = true/false,
  Stars      = 0..3,
  HighScore  = number,      -- puntos totales (mejor intento)
  Aciertos   = number,      -- cables correctos en el mejor intento
  Fallos     = number,      -- intentos fallidos en el mejor intento
  TiempoMejor = number,     -- segundos del mejor intento
  Intentos   = number,      -- cuántas veces se jugó
}
```

Estos datos se combinan con `LevelsConfig[nivelID]` para construir la tarjeta:

```lua
-- LevelsConfig.Puntuacion (ampliado para 2.0)
Puntuacion = {
  TresEstrellas  = 1000,    -- puntaje mínimo para 3 estrellas
  DosEstrellas   = 600,
  RecompensaXP   = 500,
  BonusTiempo    = {        -- NUEVO: bonus si terminas rápido
    Umbral1 = 120,          -- menos de 2 min → +200 pts
    Umbral2 = 300,          -- menos de 5 min → +100 pts
  },
  PuntosAcierto  = 50,      -- NUEVO: puntos por cable correcto
  PenaFallo      = 10,      -- NUEVO: se restan por intento fallido
},
```

### UI del Score Panel (LevelSelectorUI)

```
┌─────────────────────────────┐
│  NIVEL 0 · EDUCATIVO        │
│  Laboratorio de Grafos      │
│                             │
│  ★ ★ ★    1250 pts         │
│  ─────────────────────────  │
│  ✓ Aciertos   : 13         │
│  ✗ Fallos     :  2         │
│  ⏱ Mejor tiempo: 3m 42s    │
│  🔁 Intentos  :  4         │
│                             │
│  [ ▶ JUGAR NIVEL 0 ]       │
└─────────────────────────────┘
```

---

## 6. Etapa 3 — Carga del Nivel

### Secuencia cliente-servidor

```
Cliente                              Servidor
  │                                    │
  │── RequestPlayLevel(nivelID) ──────►│
  │                                    │ LevelLoader:load(nivelID)
  │◄─ TransitionStart ────────────────│   1. Descargar nivel anterior (si hay)
  │  (fade in pantalla negra)          │   2. Duplicar modelo de ServerStorage
  │                                    │      → Workspace/NivelActual
  │◄─ LevelReady ─────────────────────│   3. GraphService:init(NivelActual)
  │  (fade out, HUD visible)           │   4. EnergyService:reset()
  │                                    │   5. ScoreTracker:startLevel(nivelID)
  │                                    │   6. GameplayManager:activate()
  │                                    │   7. BindableEvent LevelLoaded:Fire()
```

### `LevelLoader.lua` — Solo carga y descarga modelos

```lua
-- Responsabilidades:
-- 1. Encontrar el modelo en ServerStorage por config.Modelo
-- 2. Duplicarlo a Workspace con nombre "NivelActual"
-- 3. Disparar callbacks onLevelLoaded / onLevelUnloaded
-- 4. NO inicializa servicios de grafo (eso es Boot.server.lua quien escucha LevelLoaded)
```

### `GameplayManager.server.lua` — Activa scripts de gameplay

Los scripts de gameplay (ConectarCables, ZoneTriggerManager, etc.) son **ModuleScripts**,
no Scripts. `GameplayManager` los require y los activa cuando el nivel está listo.
Esto garantiza que nunca corren sin un nivel activo.

```lua
-- Al recibir LevelLoaded:
GameplayManager:activate(nivelActual, config)
  -- Llama: ConectarCables.activate(nivelActual)
  -- Llama: ZoneTriggerManager.activate(nivelActual, config)
  -- Llama: DialogueOrchestrator.activate(config)
  -- Llama: AlgorithmVisualizer.activate(nivelActual)

-- Al recibir LevelUnloaded:
GameplayManager:deactivate()
  -- Llama: ConectarCables.deactivate()
  -- Llama: ZoneTriggerManager.deactivate()
  -- (desconecta todos los listeners de gameplay)
```

---

## 7. Etapa 4 — Gameplay Activo

### `ConectarCables.lua` — Cable Connector (ahora ModuleScript)

Misma lógica que el actual, pero:
- Sin `task.wait(1)` al inicio
- Recibe servicios vía parámetro al activarse, no desde `_G`
- Al conectar exitosamente → `ScoreTracker:registrarAcierto()`
- Al fallar una conexión → `ScoreTracker:registrarFallo()`
- Dispara `EffectsService:play("CableConnect", nodoA.Position)`

### `ZoneTriggerManager.lua` — NUEVO

Detecta cuando el jugador entra en una zona del nivel (Part con nombre `Zona_Estacion_X`)
y dispara el evento `ZoneEntered` para que `DialogueOrchestrator` lo recoja.

```lua
-- Al entrar en una zona:
ZoneEntered:Fire({ zona = "Zona_Estacion_1", player = player })

-- También dispara efectos ambientales:
EffectsService:playZoneAmbience(zona)
```

### `DialogueOrchestrator.lua` — NUEVO

Centraliza toda la lógica de diálogos. Reemplaza los 4 archivos `Zona*_dialogo.lua`
con una arquitectura de datos:

```lua
-- Estructura de un diálogo:
{
  zona      = "Zona_Estacion_1",
  trigger   = "ZONA_ENTRAR",    -- o "MISION_COMPLETADA", "NODO_SELECCIONADO"
  personaje = "Carlos",
  lineas    = {
    "Bienvenido a la Zona 1...",
    "Aquí aprenderás sobre nodos y aristas."
  },
  camara    = { target = "Nodo1_z1", offset = Vector3.new(0,5,10) },
  postAction = function() ... end,  -- opcional
}
```

Los archivos `Zona*_dialogo.lua` existentes se migran a **tablas de datos** que
`DialogueOrchestrator` consume. La lógica de reproducción está en un solo lugar.

### `ScoreTracker.lua` — NUEVO

```lua
-- Estado interno:
local aciertos    = 0
local fallos      = 0
local tiempoInicio = 0
local tiempoActual = 0

-- API:
ScoreTracker:startLevel(nivelID)   -- resetea y arranca el cronómetro
ScoreTracker:registrarAcierto()    -- +PuntosAcierto pts, notifica cliente
ScoreTracker:registrarFallo()      -- +PenaFallo penalización, notifica cliente
ScoreTracker:getSnapshot()         -- { aciertos, fallos, tiempo, puntaje }
ScoreTracker:finalize()            -- detiene cronómetro, retorna snapshot final

-- Notifica al cliente en tiempo real vía RemoteEvent "UpdateScore":
-- { aciertos=N, fallos=N, tiempo=N, puntaje=N }
```

### HUD del cliente (tiempo real)

```
┌──────────────────────────────────────────────┐
│  ✓ Aciertos: 5   ✗ Fallos: 1   ⏱ 02:34     │
│  Puntaje: 340 pts                            │
└──────────────────────────────────────────────┘
```

---

## 8. Etapa 5 — Victoria y Resultados

### Flujo de victoria

```
MissionService detecta victoria
  │
  ▼
ScoreTracker:finalize()
  → { aciertos=13, fallos=2, tiempo=222, puntaje=1250 }
  │
  ▼
RewardService:calculateRewards(snapshot, config)
  → { estrellas=3, xp=500, bonusTiempo=200 }
  │
  ▼
DataService:saveResult(player, nivelID, resultado)
  │
  ▼
RemoteEvent "LevelCompleted" → cliente
  → VictoryScreen muestra resultados
  → EffectsService:playVictory()
```

### Pantalla de resultados

```
┌─────────────────────────────────────────┐
│           ¡NIVEL COMPLETADO!            │
│                 ★ ★ ★                   │
│                                         │
│  Puntaje final    1250 pts              │
│  ─────────────────────────────          │
│  ✓ Aciertos        13  (+650 pts)      │
│  ✗ Fallos           2  ( −20 pts)      │
│  ⏱ Tiempo        3:42  (+200 pts)      │
│  ⭐ Bonus base         (+420 pts)      │
│                                         │
│  XP ganada: +500                        │
│                                         │
│  [ MENÚ ]      [ REINTENTAR ]           │
└─────────────────────────────────────────┘
```

---

## 9. Etapa 6 — Vuelta al Menú

```
Jugador presiona "Menú"
  │
  ▼
Cliente: TransitionScreen fade in
  │
  ▼
Cliente → RemoteEvent "ReturnToMenu"
  │
  ▼
Servidor: GameplayManager:deactivate()
           LevelLoader:unload()
           GraphService:clear()
           EnergyService:reset()
  │
  ▼
Servidor → BindableEvent "OpenMenu"
  │
  ▼
Cliente: TransitionScreen fade out
         MenuScreen activo
         LevelSelectorUI recarga datos (con nuevo highscore reflejado)
```

---

## 10. Sistema de Puntaje 2.0

### Cálculo del puntaje

```
PuntajeBase    = aciertos × PuntosAcierto
Penalizacion   = fallos × PenaFallo
BonusTiempo    = tiempo < Umbral1 → +200
                 tiempo < Umbral2 → +100
                 tiempo ≥ Umbral2 → 0
PuntajeFinal   = max(0, PuntajeBase − Penalizacion + BonusTiempo)

Estrellas:
  PuntajeFinal ≥ TresEstrellas → 3 estrellas
  PuntajeFinal ≥ DosEstrellas  → 2 estrellas
  PuntajeFinal > 0             → 1 estrella
  PuntajeFinal = 0             → 0 estrellas
```

### Lo que se persiste en DataStore por nivel

```lua
{
  Unlocked    = true,
  Stars       = 3,
  HighScore   = 1250,      -- mejor puntaje total
  Aciertos    = 13,        -- del intento de HighScore
  Fallos      = 2,         -- del intento de HighScore
  TiempoMejor = 222,       -- segundos del mejor intento
  Intentos    = 4,         -- total de partidas jugadas
}
```

Solo se actualiza si el nuevo puntaje supera el `HighScore` previo.

---

## 11. Sistema de Efectos

### 11.1 Efectos de Sonido

#### `AudioConfig.lua` (centralizado en ReplicatedStorage/Config/)

```lua
return {
  -- Gameplay
  CableConnect    = "rbxassetid://...",   -- cable conectado con éxito
  CableSnap       = "rbxassetid://...",   -- click al seleccionar nodo
  CableError      = "rbxassetid://...",   -- conexión inválida
  CableRemove     = "rbxassetid://...",   -- cable desconectado

  -- UI
  MenuClick       = "rbxassetid://...",
  LevelStart      = "rbxassetid://...",   -- fanfare corto al entrar al nivel
  ZoneEnter       = "rbxassetid://...",   -- subtle chime al entrar a zona

  -- Victoria
  VictoryFanfare  = "rbxassetid://...",
  Stars1          = "rbxassetid://...",
  Stars2          = "rbxassetid://...",
  Stars3          = "rbxassetid://...",   -- fanfare mayor

  -- Ambientes (loops)
  Ambient_Menu    = "rbxassetid://...",
  Ambient_Nivel0  = "rbxassetid://...",
}
```

#### Cuándo suena qué

| Acción                        | Sonido           |
|-------------------------------|------------------|
| Seleccionar un nodo           | CableSnap        |
| Conectar cable exitosamente   | CableConnect     |
| Intentar conexión inválida    | CableError       |
| Desconectar cable             | CableRemove      |
| Entrar a zona nueva           | ZoneEnter        |
| Iniciar nivel                 | LevelStart       |
| Completar nivel (1 estrella)  | Stars1           |
| Completar nivel (2 estrellas) | Stars2           |
| Completar nivel (3 estrellas) | Stars3           |

### 11.2 Efectos Visuales (cliente)

#### `VisualEffectsService.lua` — funciones disponibles

```lua
-- Efectos de nodo
VisualEffects:nodeSelected(nodo)        -- highlight + ligero scale up
VisualEffects:nodeDeselected(nodo)      -- vuelve al estado normal
VisualEffects:nodeConnected(nodo)       -- flash verde + partícula chispa
VisualEffects:nodeError(nodo)           -- flash rojo + shake pequeño
VisualEffects:nodeEnergized(nodo)       -- glow cian pulsante

-- Efectos de cable
VisualEffects:cableConnected(cable)     -- fade in del cable + glow brief
VisualEffects:cableRemoved(cable)       -- fade out rápido

-- Efectos de zona
VisualEffects:zoneUnlocked(zona)        -- rayos de luz + partículas doradas
VisualEffects:zoneComplete(zona)        -- sello verde sobre la zona

-- Efectos de pantalla (TransitionScreen)
VisualEffects:fadeIn(duration)          -- negro → transparente
VisualEffects:fadeOut(duration)         -- transparente → negro
VisualEffects:cinemaBarIn()             -- barras negras arriba/abajo (cinemático)
VisualEffects:cinemaBarOut()            -- barras desaparecen

-- Efectos de victoria
VisualEffects:victoryConfetti()         -- partículas de confeti
VisualEffects:starPopIn(count)          -- animación de estrellas apareciendo
```

### 11.3 Efectos de Partículas (servidor, en el Workspace)

Colocados en `EffectsService.lua` del servidor. Se replican al cliente automáticamente
porque son instancias del Workspace.

| Efecto                | Descripción                                              |
|-----------------------|----------------------------------------------------------|
| Chispa de conexión    | ParticleEmitter breve en el punto de conexión del cable  |
| Error de conexión     | ParticleEmitter rojo en el nodo inválido                 |
| Nodo energizado       | Glow + PointLight dinámico con pulso                     |
| Zona completada       | Explosión de partículas doradas + PointLight breve       |

### 11.4 Efectos de Cámara (cliente)

`CameraEffects.lua` (dentro de VisualEffectsService o módulo separado):

```lua
-- Transición al entrar al nivel
CameraEffects:levelIntro(nivelActual)
  -- 1. Cámara inicia lejos/arriba (vista aérea del nivel)
  -- 2. Tween suave hasta la posición del personaje
  -- 3. CinemaBarOut al llegar

-- Diálogo cinemático
CameraEffects:focusOn(target, duration)
  -- Hace lerp de la cámara hacia 'target' mientras dura el diálogo

-- Sacudida al error
CameraEffects:shake(intensity, duration)

-- Vuelo de cámara al completar zona
CameraEffects:zoneCompleteFlyover(zona)
```

### 11.5 Efectos de Pantalla de Transición

`TransitionScreen.lua` gestiona una Frame negra (ZIndex máximo) con:
- `fadeIn(t)` — negro en `t` segundos
- `fadeOut(t)` — transparente en `t` segundos
- `showLoadingBar(progress)` — barra de carga durante Level Loading (0..1)

---

## 12. Patrones de Diseño Utilizados

### Service Locator (reemplaza `_G.Services`)

```lua
-- ServiceLocator.lua
local services = {}
local pendingCallbacks = {}

function ServiceLocator:register(name, service)
  services[name] = service
  if pendingCallbacks[name] then
    for _, cb in ipairs(pendingCallbacks[name]) do cb(service) end
    pendingCallbacks[name] = nil
  end
end

function ServiceLocator:get(name)
  assert(services[name], "Servicio no registrado: " .. name)
  return services[name]
end

function ServiceLocator:waitFor(name)
  -- retorna una Promise/yield hasta que el servicio se registre
end
```

### Observer / Event-Driven (Staged Loading)

Los módulos de gameplay no se inicializan solos. `GameplayManager` los activa
cuando `LevelLoaded` se dispara. El patrón es:

```
EventRegistry → dispara ServerReady
Boot escucha ServerReady → registra servicios
Boot escucha LevelLoaded → activa GameplayManager
GameplayManager activa módulos → ellos escuchan eventos de gameplay
GameplayManager desactiva módulos → ellos desconectan todos sus listeners
```

### Module Pattern (todos los scripts de gameplay)

En lugar de `Script` con código top-level, cada pieza de gameplay es un `ModuleScript`:

```lua
-- ConectarCables.lua (ModuleScript)
local ConectarCables = {}
local connections = {}

function ConectarCables.activate(nivelActual, services)
  -- conectar eventos, inicializar estado
  connections[1] = remoteEvent.OnServerEvent:Connect(...)
end

function ConectarCables.deactivate()
  for _, conn in ipairs(connections) do conn:Disconnect() end
  connections = {}
end

return ConectarCables
```

### Data-Driven Dialogues

Los diálogos no son código, son datos. `DialogueOrchestrator` ejecuta cualquier
tabla de diálogo sin conocer el contenido. Agregar Zona 5 solo requiere
agregar una tabla en `ZonaX_dialogo.lua`, no código nuevo.

---

## 13. Orden de Implementación

### Fase 0 — Infraestructura (sin tocar gameplay)

1. Crear `EventRegistry.server.lua` — todos los eventos en un lugar
2. Crear `ServiceLocator.lua` (server y client)
3. Crear `TableUtils.lua` con `countKeys()`, `deepCopy()`
4. Crear `Constants.lua` con `STUDS_PER_METER`, `MAX_STARS`, etc.

### Fase 1 — Boot y carga ordenada

5. Crear `Boot.server.lua` — reemplaza `Init.server.lua`
   - Espera EventRegistry, carga servicios, dispara ServicesReady
6. Crear `LevelLoader.lua` — extrae la lógica de carga de `LevelService`
7. Corregir `GraphService`, `EnergyService`, `MissionService` para recibir
   servicios vía parámetro (no `_G`)

### Fase 2 — Puntaje

8. Crear `ScoreTracker.lua` — aciertos, fallos, cronómetro
9. Ampliar `LevelsConfig` con `PuntosAcierto`, `PenaFallo`, `BonusTiempo`
10. Ampliar `DataService` para persistir aciertos/fallos/tiempo
11. Actualizar `LevelSelectorUI` para mostrar stats ampliados

### Fase 3 — Gameplay consciente

12. Crear `GameplayManager.server.lua`
13. Convertir `ConectarCables` a ModuleScript con `activate`/`deactivate`
14. Crear `ZoneTriggerManager.lua`
15. Crear `DialogueOrchestrator.lua` con formato de datos
16. Migrar `Zona1_dialogo.lua` al nuevo formato (primero solo la Zona 1 como prueba)
17. Migrar Zona 2, 3 y 4

### Fase 4 — Efectos

18. Crear `AudioConfig.lua` y mapear todos los sonidos existentes
19. Refactorizar `AudioService` (fix Heartbeat, centralizar volúmenes)
20. Crear `TransitionScreen.lua` (fade in/out, barra de carga)
21. Expandir `VisualEffectsService` con efectos de nodo y cable
22. Añadir partículas en `EffectsService` (servidor)
23. Implementar `CameraEffects` (intro de nivel, focus en diálogo, shake)

### Fase 5 — Pantalla de victoria mejorada

24. Rediseñar `VictoryScreen` para mostrar aciertos/fallos/tiempo/bonus
25. Animación de estrellas (`starPopIn`)
26. Confeti (`victoryConfetti`)
27. Efectos de sonido de victoria por número de estrellas

### Fase 6 — Pulido y validación

28. Tests de carga: verificar que `ServerReady` llega antes que cualquier
    script de gameplay intente leer servicios
29. Tests de puntaje: nivel 0 con 0 DineroInicial → sin NaN
30. Tests de efectos: cada efecto sonoro suena en el momento correcto
31. Stress test: volver al menú y re-entrar al nivel 3 veces seguidas
    sin memory leaks (connections desconectadas correctamente)

---

## Notas y Decisiones de Diseño

- **`_G` queda eliminado** excepto para compatibilidad temporal durante la migración.
  Una vez que Boot y ServiceLocator funcionan, se retira completamente.

- **Los ModuleScripts de Gameplay no tienen estado global**. Todo el estado
  se resetea en `activate()` y se limpia en `deactivate()`. Esto hace que
  re-entrar al nivel siempre empiece limpio.

- **`LevelLoader` solo mueve modelos**. No conoce grafo, energía ni misiones.
  Boot.server.lua escucha `LevelLoaded` y orquesta la inicialización de servicios.

- **Los diálogos son datos, no código**. `DialogueOrchestrator` es el motor;
  los archivos `Zona*_dialogo.lua` son configuración. Agregar una zona nueva
  es cuestión de minutos, no de copiar boilerplate.

- **El puntaje 2.0 es aditivo**. El jugador siempre ve su progreso crecer:
  cada cable correcto suma. Los fallos restan poco. El bonus de tiempo premia
  la eficiencia sin castigar a los jugadores lentos que igual completan el nivel.
