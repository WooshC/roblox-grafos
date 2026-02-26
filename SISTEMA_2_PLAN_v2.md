# Sistema 2.0 — Plan de Arquitectura (REVISADO)

> **Propósito**: Rediseño completo desde cero. Carga consciente y secuenciada de servicios,
> puntaje con aciertos/fallos/tiempo, efectos de sonido, video y partículas enriquecidos.
>
> **Regla de oro**: Ningún script lee un servicio que aún no existe.
> Cada etapa solo empieza cuando la anterior confirmó que terminó.
>
> **Versión**: 2.1 — Incorpora mejoras de arquitectura, ScoreTracker 2.0 separado de UI,
> GuiaService consciente de zonas, y menú principal con ventanas modales.

---

## Estado de Implementación (actualizado 2026-02-25)

### ✅ COMPLETADO — Etapas 0 a 3

| Archivo | Ubicación | Estado |
|---|---|---|
| `EventRegistry.server.lua` | ServerScriptService/ | ✅ Implementado |
| `Boot.server.lua` | ServerScriptService/ | ✅ Implementado |
| `DataService.lua` | ServerScriptService/ | ✅ Implementado |
| `LevelLoader.lua` | ServerScriptService/ | ✅ Implementado |
| `CamaraMenuSetup.lua` | ServerScriptService/ | ✅ Implementado |
| `crearGUIMenu.lua` | GrafosV2/ (raíz) | ✅ Funciona — ver nota ① |
| `LevelsConfig.lua` | ReplicatedStorage/Config/ | ✅ Implementado |
| `ClientBoot.lua` | StarterPlayer/StarterPlayerScripts/ | ✅ Implementado |
| `MenuController.client.lua` | StarterPlayer/StarterPlayerScripts/ | ✅ Implementado |
| `HUDController.client.lua` | StarterPlayer/StarterPlayerScripts/ | ✅ Implementado |

### 🖥️ GUIs pre-construidas (YA EXISTEN en Roblox Studio)

Ambas GUIs están creadas manualmente en Studio. **NO** generarlas por script.

| GUI | Ubicación en Studio | Notas |
|---|---|---|
| `EDAQuestMenu` (ScreenGui) | StarterGui/ | Menú principal, ya existe |
| `GUIExploradorV2` (ScreenGui) | StarterGui/ | HUD de gameplay, ya existe |

`Boot.server.lua` copia StarterGui → PlayerGui manualmente (CharacterAutoLoads = false).

### ✅ Fixes aplicados (2026-02-25)

**Fix ①: Solapamiento LevelReady**
- `ClientBoot` es la única autoridad en activar/desactivar ScreenGuis al recibir LevelReady.
- `HUDController` ya NO hace `hud.Enabled = true/false` en LevelReady — solo resetea `isReturning` y `fadeOverlay`.

**Fix ②: Listener muerto de ReturnToMenu eliminado de ClientBoot**
- `ClientBoot` eliminó su listener de `ReturnToMenu` (Boot.server.lua nunca lo dispara al cliente).
- `HUDController.doReturnToMenu()` es el dueño del flujo completo: fade → FireServer → swap GUI.

### 🔄 CAMBIOS PENDIENTES — Etapa 4 (identificados 2026-02-26)

**Cambio ①: ZoneTriggerManager — formato de zonas incompatible con LevelsConfig**
- `LevelsConfig[n].Zonas` es un diccionario `{ [nombre] = { Modo, NodosRequeridos } }` **sin campo `Trigger`**.
- `ZoneTriggerManager.activate(nivel, zonas, player)` espera un array `{ { nombre, trigger } }`.
- Resultado: **ninguna zona se registra** — ZoneEntered/ZoneExited nunca se disparan.
- **Fix**: añadir `Trigger = "NombrePart"` en cada entrada de `LevelsConfig.Zonas` y convertir el dict → array en `GameplayManager`. Ver §13.9.

**Cambio ②: Highlight visible a través de paredes (cross-room)**
- `Highlight` con `DepthMode = AlwaysOnTop` ya penetra paredes por diseño de Roblox.
- Para garantizar visibilidad total (habitaciones separadas, distancias arbitrarias), añadir un `BillboardGui` con `AlwaysOnTop = true` como complemento visual. Ver §13.10.

**Cambio ③: Módulo VisualEffects compartido cliente/servidor**
- Crear `ReplicatedStorage/Shared/VisualEffectsConfig.lua` — constantes de colores y tipos de efecto; requerido desde servidor **y** cliente.
- Crear `ServerScriptService/Services/VisualEffectsManager.lua` — API servidor que dispara `PlayEffect` (RemoteEvent) al cliente.
- Expandir `VisualEffectsService.client.lua` para escuchar `PlayEffect` además de `NotificarSeleccionNodo`, añadir BillboardGui y nuevos tipos de efecto. Ver §11.3.

### ✅ Completado — Etapa 4 (2026-02-25)

| Archivo | Estado | Notas |
|---|---|---|
| `ConectarCables.lua` | ✅ Implementado | Lógica pura: adyacencias, Beam celeste, disconnect penaliza |
| `ScoreTracker.lua` | ✅ Implementado | Aciertos, fallos, desconexiones, cronómetro |
| `VisualEffectsService.client.lua` | ✅ Implementado | Highlight Roblox (AlwaysOnTop) + Material Neon en Selector, solo flash rojo |
| `ZoneTriggerManager.lua` | ✅ Implementado | Touched+TouchEnded, ZoneEntered+ZoneExited, primeraVez flag |

**Cambios de arquitectura aplicados (Etapa 4):**
- **Beam en lugar de RopeConstraint** — cable siempre tenso (`CurveSize = 0`), celeste `RGB(0,200,255)`, `FaceCamera = true`
- **Separación lógica/visual** — `ConectarCables` solo adyacencias/estado; `VisualEffectsService` todos los efectos visuales
- **Highlight doble al seleccionar** — Roblox `Highlight` instance (`DepthMode = AlwaysOnTop`) + `Material = Neon` en BasePart del Selector en cyan; adyacentes en dorado. **Visible a través de paredes** (AlwaysOnTop renderiza encima de toda la geometría)
- **Un solo tipo de error visual** — flash rojo siempre; `DireccionInvalida` solo en log de debug
- **Disconnect penaliza puntaje** — desconectar un cable descuenta 1 conexión del puntajeBase en el HUD
- **ZoneTriggerManager** — `Touched`+`TouchEnded` en `NivelActual/Zonas/Zonas_juego/<TriggerPart>`; `ZoneEntered`+`ZoneExited` BindableEvents; `primeraVez` flag; API pública: `isEnZona()`, `isZonaVisitada()`, `getZonaActual()`
- **Zonas en LevelsConfig** — `Zonas = { { nombre, trigger } }` por nivel; añadir Parts en Studio y la entrada en config

### 🔜 PENDIENTE — Etapa 5

Próximos archivos a crear (en orden):
1. `GameplayManager.server.lua` — orquesta activate/deactivate de todos los módulos
2. `MissionService.lua` — valida misiones por zona (condición de victoria)
3. `VictoryScreen.lua` — pantalla de resultados con desglose completo

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
12. [Menú principal — Ventanas modales](#12-menú-principal--ventanas-modales)
13. [Mejoras de arquitectura identificadas](#13-mejoras-de-arquitectura-identificadas)
14. [Patrones de diseño utilizados](#14-patrones-de-diseño-utilizados)
15. [Orden de implementación](#15-orden-de-implementación)

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
  • MenuScreen visible con cámara cinemática
  • Ventanas modales: Ajustes, Créditos, Salir
  • Música de menú en loop
  • CameraSystem del menú (secuencia cinemática en loop)
  • NO se carga nada de gameplay
  │
  ▼  (jugador abre el selector de niveles)
[Etapa 2] Selector de Niveles
  • Llama GetPlayerProgress (RemoteFunction)
  • Servidor devuelve datos de DataStore + LevelsConfig combinados
    { nivelID, nombre, desbloqueado, estrellas, highScore,
      aciertos, fallos, tiempoMejor, intentos, algoritmo }
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
    ← puntaje final (con bonus/penalizaciones) se muestra SOLO AQUÍ
    ← durante el gameplay se muestra el puntaje base acumulado
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
│   ├── LevelsConfig.lua          ← igual, con campo Puntuacion y Dificultad ampliado
│   ├── AudioConfig.lua           ← mapeo nombre→assetId de todos los sonidos
│   ├── EffectsConfig.lua         ← configuración de efectos de partículas/tweens
│   └── DifficultyConfig.lua      ← NUEVO: configuración de modos de dificultad
│
├── Shared/
│   ├── Constants.lua             ← STUDS_PER_METER, TIMEOUTS, MAX_STARS
│   ├── Enums.lua                 ← (existente, corregido)
│   ├── VisualEffectsConfig.lua   ← NUEVO: colores y tipos de efecto (accesible cliente+servidor)
│   └── Utils/
│       ├── GraphUtils.lua        ← (existente, corregido)
│       ├── TableUtils.lua        ← countKeys, deepCopy, shallowMerge
│       └── TweenUtils.lua        ← helper para tweens reutilizables
│
└── Utilidades/
    ├── AliasUtils.lua            ← (existente, sin cambios)
    └── NivelUtils.lua            ← (existente, sin cambios)

ServerScriptService/
├── Core/
│   ├── Boot.server.lua           ← punto de entrada único del servidor
│   ├── EventRegistry.server.lua  ← crea TODOS los eventos al inicio
│   └── ServiceLocator.lua        ← reemplaza _G.Services
│
├── Data/
│   └── DataService.lua           ← centraliza DataStore con campos ampliados
│
├── Services/
│   ├── LevelLoader.lua           ← solo carga/descarga el modelo de nivel
│   ├── GraphService.lua          ← (existente, corregido)
│   ├── EnergyService.lua         ← (existente, corregido)
│   ├── MissionService.lua        ← (existente, simplificado)
│   ├── ScoreTracker.lua          ← NUEVO: aciertos, fallos, cronómetro
│   ├── RewardService.lua         ← (existente, corregido)
│   ├── AudioService.lua          ← (existente, Heartbeat fix)
│   ├── EffectsService.lua        ← NUEVO: efectos server-side
│   ├── VisualEffectsManager.lua  ← NUEVO: API servidor → dispara PlayEffect al cliente
│   └── DifficultyService.lua     ← NUEVO: aplica modificadores de dificultad
│
└── Gameplay/
    ├── GameplayManager.server.lua ← activa/desactiva todos los scripts de gameplay
    ├── ConectarCables.lua         ← (existente, convertido a ModuleScript)
    ├── ZoneTriggerManager.lua     ← detecta zonas y dispara eventos
    ├── DialogueOrchestrator.lua   ← secuencia y coordina diálogos por zona
    └── AlgorithmVisualizer.lua    ← (existente VisualizadorAlgoritmos, corregido)

StarterPlayerScripts/
├── Core/
│   ├── ClientBoot.client.lua     ← punto de entrada único del cliente
│   └── ClientServiceLocator.lua  ← registro de servicios del cliente
│
└── Client/
    ├── Services/
    │   ├── ScoreManager.lua          ← muestra puntaje base en HUD (no final)
    │   ├── MatrixManager.lua         ← (existente, corregido)
    │   ├── AudioClient.lua           ← (existente)
    │   ├── VisualEffectsService.lua  ← (existente, expandido)
    │   ├── NetworkService.lua        ← (existente)
    │   └── GuiaService.lua           ← (existente, consciente de zonas)
    └── UI/
        ├── MenuScreen.lua            ← menú principal + cámara cinemática
        ├── MenuModals.lua            ← NUEVO: Ajustes, Créditos, Salir
        ├── LevelSelectorUI.lua       ← (existente, refactorizado)
        ├── HUD.lua                   ← HUD de gameplay (puntaje base, tiempo en vivo)
        ├── VictoryScreen.lua         ← pantalla de resultados FINAL con desglose
        └── TransitionScreen.lua      ← NUEVO: fade + barra de carga entre etapas

StarterGui/
└── DialogStorage/
    ├── SharedDialogConfig.lua    ← colores y config de cámara compartidos
    ├── DialogUtils.lua           ← esperarKitLibre(), getPos()
    ├── ZoneDialogActivator.lua   ← boilerplate de activación de zona
    ├── Zona1_dialogo.lua         ← (formato de datos, no código)
    ├── Zona2_dialogo.lua
    ├── Zona3_dialogo.lua
    └── Zona4_dialogo.lua
```

---

## 3. Etapa 0 — Boot del Servidor

### `EventRegistry.server.lua` (corre PRIMERO)

```
ReplicatedStorage/
└── Events/
    ├── Remotes/
    │   ├── GetPlayerProgress (RemoteFunction)
    │   ├── RequestPlayLevel (RemoteEvent)
    │   ├── CableDragEvent (RemoteEvent)
    │   ├── LevelReady (RemoteEvent)
    │   ├── LevelCompleted (RemoteEvent)
    │   ├── UpdateScore (RemoteEvent)
    │   ├── UpdateScoreFinal (RemoteEvent)
    │   ├── PulseEvent (RemoteEvent)
    │   ├── NotificarSeleccionNodo (RemoteEvent)
    │   ├── PlayEffect (RemoteEvent)
    │   ├── ApplyDifficulty (RemoteEvent)
    │   ├── ServerReady (RemoteEvent)
    │   ├── ReturnToMenu (RemoteEvent)
    │   └── LevelUnloaded (RemoteEvent)
    └── Bindables/
        ├── ServerReady (BindableEvent)
        ├── LevelLoaded (BindableEvent)
        ├── LevelUnloaded (BindableEvent)
        ├── ScoreChanged (BindableEvent)
        ├── ZoneEntered (BindableEvent)
        ├── DialogueRequested (BindableEvent)
        ├── OpenMenu (BindableEvent)
        ├── GuiaAvanzar (BindableEvent)
        └── RestaurarObjetos (BindableEvent)

### `Boot.server.lua` — Secuencia garantizada

```lua
-- 1. Esperar EventRegistry
-- 2. Cargar DataService e iniciar DataStore
-- 3. Cargar servicios en orden:
--      GraphService → EnergyService → MissionService
--      → ScoreTracker → RewardService → AudioService
--      → EffectsService → LevelLoader → DifficultyService
-- 4. Inyectar dependencias entre servicios
-- 5. Configurar listeners globales
-- 6. Registrar en ServiceLocator
-- 7. Disparar "ServerReady"
```

---

## 4. Etapa 1 — Menú Principal

**Quién lo maneja**: `ClientBoot.client.lua` + `MenuScreen.lua` + `MenuModals.lua`

Al conectarse, el cliente:
1. Espera `ServerReady`
2. Activa `MenuScreen` con cámara cinemática en loop
3. Reproduce música de menú
4. **No carga ningún sistema de gameplay**

### Ventanas Modales del Menú

```
MenuScreen
├── [JUGAR]        → abre LevelSelectorUI
├── [AJUSTES]      → abre modal de Ajustes
│     ├── Dificultad
│     │     ├── Normal (config original del nivel)
│     │     ├── Difícil (+30% nodos, tiempo limitado)
│     │     └── Experto (+60% nodos, sin ayudas visuales)
│     ├── Colores de Cable
│     │     ├── Clásico (negro)
│     │     ├── Neon (verde brillante)
│     │     └── Personalizado (color picker)
│     ├── Colores de Indicadores
│     │     ├── Zona activa
│     │     ├── Nodo seleccionado
│     │     └── Conexión válida/inválida
│     ├── Audio (volumen ambiente / SFX)
│     └── [Guardar] [Cancelar]
├── [CRÉDITOS]     → abre modal de Créditos
│     ├── Equipo de desarrollo
│     ├── Herramientas utilizadas
│     └── Agradecimientos
└── [SALIR]        → confirmación antes de cerrar
```

### `MenuModals.lua` — Estructura

```lua
-- Responsabilidades:
-- 1. Gestionar apertura/cierre de modales con animación (fade + scale)
-- 2. Persistir configuración de Ajustes en DataStore vía RemoteFunction
-- 3. Aplicar cambios de Ajustes inmediatamente en preview
-- 4. Proteger salida con diálogo de confirmación

local MenuModals = {}

function MenuModals:openSettings()   end
function MenuModals:openCredits()    end
function MenuModals:confirmExit()    end
function MenuModals:close()         end
function MenuModals:saveSettings(config) end

return MenuModals
```

### `DifficultyService.lua` — Modificadores de Dificultad

```lua
-- Aplica modificadores al LevelsConfig base según la dificultad elegida
local DIFFICULTY_MODIFIERS = {
  Normal = {
    extraNodes     = 0,        -- Nodos adicionales a agregar
    timeLimit      = nil,      -- nil = sin límite
    visualHelpers  = true,     -- Mostrar guía visual, zonas, pistas
    costMultiplier = 1.0,
  },
  Dificil = {
    extraNodes     = math.floor(totalNodes * 0.3),
    timeLimit      = 600,      -- 10 minutos
    visualHelpers  = true,
    costMultiplier = 1.5,
  },
  Experto = {
    extraNodes     = math.floor(totalNodes * 0.6),
    timeLimit      = 300,      -- 5 minutos
    visualHelpers  = false,    -- Sin zona iluminada, sin guía
    costMultiplier = 2.0,
  },
}

function DifficultyService:applyDifficulty(nivelID, difficulty)
  -- Clona la config base y le aplica los modificadores
  -- Genera nodos adicionales con posiciones procedurales
  -- Ajusta Adyacencias para los nuevos nodos
  -- Emite RemoteEvent "ApplyDifficulty" al cliente para que oculte helpers visuales
end
```

---

## 5. Etapa 2 — Selector de Niveles y Puntaje

### Datos que el servidor devuelve (ampliados)

```lua
{
  Unlocked    = true/false,
  Stars       = 0..3,
  HighScore   = number,       -- puntos totales (mejor intento)
  Aciertos    = number,       -- cables correctos en el mejor intento
  Fallos      = number,       -- intentos fallidos en el mejor intento
  TiempoMejor = number,       -- segundos del mejor intento
  Intentos    = number,       -- cuántas veces se jugó
  Dificultad  = "Normal",     -- NUEVO: dificultad del mejor intento
}
```

### UI del Score Panel

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
│  ⚙ Dificultad : Normal     │
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
  │◄─ TransitionStart ────────────────│   + DifficultyService:apply()
  │  (fade in pantalla negra)          │   1. Descargar nivel anterior
  │                                    │   2. Duplicar modelo de ServerStorage
  │◄─ LevelReady ─────────────────────│   3. GraphService:init(NivelActual)
  │  (fade out, HUD visible)           │   4. EnergyService:reset()
  │                                    │   5. ScoreTracker:startLevel(nivelID)
  │                                    │   6. GameplayManager:activate()
  │                                    │   7. GuiaService:reset()
```

### ⚠️ Problema detectado en el código actual

`ConectarCables.server.lua` usa `task.wait(1)` al inicio para esperar servicios.
Esto es una **race condition**: si el servidor tarda más de 1 segundo, el script
falla silenciosamente. La solución es usar `ServiceLocator:waitFor()`.

```lua
-- ❌ Código actual (frágil)
task.wait(1)
local LevelService = _G.Services.Level

-- ✅ Código correcto
local ServiceLocator = require(path.ServiceLocator)
local LevelService = ServiceLocator:waitFor("Level")
```

---

## 7. Etapa 4 — Gameplay Activo

### HUD durante el gamepla

```
ScreenGui "GUIExploradorV2"
│
├── BarraSuperior (Frame — barra fija top, fondo oscuro semitransparente)
│   ├── Titulo (TextLabel — oculto, compatibilidad con scripts externos)
│   ├── TitleBadge (Frame — badge con nombre del juego, izquierda)
│   │   ├── UICorner
│   │   ├── UIStroke
│   │   ├── UIPadding
│   │   ├── IconoJuego (TextLabel — emoji 📊)
│   │   └── TitleStack (Frame — stack vertical nombre + subtítulo)
│   │       ├── NombreJuego (TextLabel)
│   │       └── SubTitulo (TextLabel)
│   ├── PanelPuntuacion (Frame — chips de stats, centro)
│   │   ├── UIListLayout (horizontal)
│   │   ├── ContenedorEstrellas (Frame — chip ⭐)
│   │   │   ├── UICorner, UIStroke, UIPadding
│   │   │   ├── Icono (TextLabel)
│   │   │   ├── Valor (TextLabel)
│   │   │   └── Etiqueta (TextLabel)
│   │   ├── ContenedorPuntos (Frame — chip 🏆)
│   │   │   └── [mismos hijos]
│   │   └── ContenedorDinero (Frame — chip 💰)
│   │       └── [mismos hijos]
│   └── BarraBotonesSecundarios (Frame — botones derecha)
│       ├── UIListLayout (horizontal)
│       ├── BtnReiniciar (TextButton — amarillo)
│       └── BtnFinalizar (TextButton — verde, oculto)
│
├── BarraBotonesMain (Frame — botones flotantes top-left)
│   ├── UICorner, UIStroke, UIPadding
│   ├── UIListLayout (horizontal)
│   ├── BtnMapa (TextButton — verde)
│   ├── BtnMisiones (TextButton — violeta)
│   ├── BtnSalir (TextButton — rojo)
│   ├── BtnAlgoritmo (TextButton — invisible, compatibilidad)
│   └── BtnMatriz (TextButton — invisible, compatibilidad)
│
├── SelectorModos (Frame — pills de modo, bottom-left)
│   ├── UICorner, UIStroke, UIPadding
│   ├── UIListLayout (horizontal)
│   ├── VisualBtn (TextButton — verde activo)
│   ├── MatrizBtn (TextButton — azul inactivo)
│   └── AnalisisBtn (TextButton — naranja inactivo)
│
├── ContenedorMiniMapa (Frame — minimapa bottom-right)
│   ├── UICorner, UIStroke
│   ├── Header (Frame — cabecera verde oscura)
│   │   ├── UIPadding
│   │   └── Titulo (TextLabel)
│   ├── Vista (ViewportFrame — render 3D del grafo)  ← renombrado
│   │   └── WorldModel (WorldModel — contenedor de partes 3D)  ← NUEVO
│   └── PanelInfoGrafo (Frame — estadísticas nodos/aristas/tipo)
│       ├── UIPadding, UIListLayout (horizontal)
│       ├── EtiquetaInfoGrafo (TextLabel — oculto, compat.)
│       ├── EstadisticasGrafo (TextLabel — oculto, compat.)
│       ├── StatNodos (Frame — chip NODOS)
│       ├── StatAristas (Frame — chip ARISTAS)
│       └── StatTipo (Frame — chip TIPO)
│
├── PanelMatrizAdyacencia (Frame — panel matemático, derecha, oculto)
│   ├── UICorner, UIStroke
│   ├── MatrizHeader (Frame — cabecera azul)
│   │   ├── UIPadding
│   │   ├── TituloMatriz (TextLabel)
│   │   └── BtnCerrarMatriz (TextButton — X rojo)
│   ├── MarcoInfoNodo (Frame — info del nodo seleccionado)
│   │   ├── UICorner, UIStroke, UIPadding
│   │   ├── UIGridLayout (2×2)
│   │   ├── FilaNodo, FilaGrado, FilaEntrada, FilaSalida (Frames)
│   └── CuadriculaMatriz (ScrollingFrame — tabla de adyacencia)
│
├── MisionFrame (Frame — panel misiones, oculto)
│   ├── UICorner, UIStroke
│   ├── MisHeader (Frame — cabecera violeta)
│   │   ├── UIPadding
│   │   ├── Titulo (TextLabel)
│   │   └── BtnCerrarMisiones (TextButton — X rojo)
│   └── Cuerpo (ScrollingFrame — lista de misiones)
│       ├── UIPadding
│       └── UIListLayout (vertical)
│
├── PantallaMapaGrande (Frame — mapa fullscreen, ZIndex 5, oculto)
│   ├── MapaHeader (Frame — cabecera verde oscura)
│   │   ├── UIPadding, UIStroke
│   │   ├── MapaTitulo (TextLabel)
│   │   └── MapaBotones (Frame)
│   │       ├── UIListLayout (horizontal)
│   │       ├── BtnMisionesEnMapa (TextButton — violeta)
│   │       ├── BtnMatematico (TextButton — azul)
│   │       └── BtnCerrarMapa (TextButton — rojo)
│   ├── MapaInfoStrip (Frame — banda de stats nodos/aristas/tipo)
│   │   ├── UIPadding, UIListLayout (horizontal)
│   │   └── MapInfoNodos, MapInfoAristas, MapInfoTipo (Frames — pills)
│   └── VisorMapa (ViewportFrame — render 3D del mapa completo)
│
├── OverlayAnalisis (Frame — fondo oscuro análisis, ZIndex 15, oculto)
│   └── PanelAnalisis (Frame — panel central, ZIndex 16)
│       ├── UICorner, UIStroke
│       ├── EncabezadoAnalisis (Frame — cabecera naranja)
│       │   ├── UIPadding
│       │   ├── TituloAnalisis (TextLabel)
│       │   ├── SubtituloAnalisis (TextLabel)
│       │   ├── PillsAlgo (Frame — pills BFS/DFS/Dijkstra/Prim)
│       │   │   ├── UIListLayout (horizontal)
│       │   │   ├── PillBFS, PillDFS, PillDijkstra, PillPrim (TextButtons)
│       │   ├── BtnEjecutarAlgo (TextButton — naranja ▶)
│       │   └── BtnCerrarAnalisis (TextButton — X rojo)
│       └── PanelDatos (Frame — 3 columnas)
│           ├── UIListLayout (horizontal)
│           ├── ColGrafo (Frame — viewport + leyenda)
│           │   ├── ColGrafoTitulo (TextLabel)
│           │   ├── VisorGrafoAna (ViewportFrame)
│           │   └── LeyendaGrafo (Frame — grid 2×2)
│           │       ├── UIGridLayout
│           │       └── Leg1…Leg4 (Frames — dot + label)
│           ├── ColPasos (Frame — estado del algoritmo)
│           │   ├── ColPasosTitulo (TextLabel)
│           │   ├── BarraRecorrido (Frame — path actual)
│           │   ├── TarjetaPaso (Frame — paso actual)
│           │   ├── ScrollEstado (ScrollingFrame — log de pasos)
│           │   └── ControlesAnalisis (Frame — controles)
│           │       ├── UIListLayout (horizontal)
│           │       ├── BtnAnterior (TextButton — ⬅)
│           │       ├── BarraProgreso (Frame — barra progreso)
│           │       │   └── RellenoProgreso (Frame — fill naranja→oro)
│           │       │       └── UIGradient
│           │       ├── BtnSiguiente (TextButton — naranja)
│           │       └── BtnSalirAnalisis (TextButton — X rojo)
│           └── ColCodigo (Frame — pseudocódigo + métricas)
│               ├── ColCodigoTitulo (TextLabel)
│               ├── ScrollPseudocodigo (ScrollingFrame)
│               └── MetricasAnalisis (Frame)
│                   ├── UIStroke, UIPadding
│                   ├── InsigniaComplejidad (TextLabel — O(V+E))
│                   ├── MetricaPasos (TextLabel)
│                   └── MetricaNodos (TextLabel)
│
├── VictoriaFondo (Frame — overlay victoria, ZIndex 20, oculto)
│   └── PantallaVictoria (CanvasGroup — panel central, ZIndex 21)
│       └── ContenedorPrincipal (Frame)
│           ├── UICorner, UIStroke
│           ├── VictoriaHead (Frame — cabecera dorada)
│           │   ├── UIPadding
│           │   ├── TituloVictoria (TextLabel — ¡NIVEL COMPLETADO!)
│           │   ├── SubtituloVictoria (TextLabel)
│           │   └── EstrellasMostrar (Frame — 3 estrellas)
│           │       ├── UIListLayout (horizontal)
│           │       └── Estrella1, Estrella2, Estrella3 (ImageLabels)
│           ├── EstadisticasFrame (Frame — filas de stats)
│           │   ├── UIListLayout (vertical)
│           │   ├── FilaTiempo (Frame — ⏱ Tiempo)
│           │   ├── FilaAciertos (Frame — 🔗 Conexiones)
│           │   ├── FilaErrores (Frame — ❌ Errores)
│           │   └── FilaPuntaje (Frame — 🏆 Puntaje Final, dorado)
│           └── BotonesFrame (Frame)
│               ├── UIListLayout (horizontal)
│               ├── BotonRepetir (TextButton — amarillo)
│               └── BotonContinuar (TextButton — verde)
│
├── Leyenda (Frame — leyenda de nodos, bottom-right, oculta)
│   ├── UICorner, UIStroke, UIPadding
│   ├── UIListLayout (vertical)
│   ├── LeyendaTitulo (TextLabel)
│   ├── LegInicial (Frame — dot azul)
│   ├── LegEnergizado (Frame — dot verde)
│   ├── LegMeta (Frame — dot dorado)
│   ├── LegAdyacente (Frame — dot naranja)
│   └── LegAislado (Frame — dot rojo)
│
├── GuiaHUD (Frame — HUD guía navegación, oculto)
│   ├── UICorner, UIStroke, UIPadding
│   └── GuiaLabel (TextLabel — 🧭 Dirígete a: —)
│
└── ModalSalirFondo (Frame — overlay modal salir, ZIndex 30, oculto)
    └── ModalSalir (Frame — panel central, ZIndex 31)
        ├── UICorner, UIStroke
        ├── ModalHead (Frame — cabecera roja)
        │   ├── UIPadding
        │   ├── ModalIcono (TextLabel — 🚪)
        │   └── ModalTitleStack (Frame)
        │       ├── ModalTitulo (TextLabel — ¿SALIR DEL NIVEL?)
        │       └── ModalSub (TextLabel — advertencia)
        ├── ModalBody (Frame — mensaje de advertencia)
        │   ├── UICorner, UIStroke, UIPadding
        │   └── ModalMsg (TextLabel — texto wrap)
        ├── ModalBtns (Frame — botones confirmar/cancelar)
        │   ├── UIListLayout (horizontal)
        │   ├── BtnCancelarSalir (TextButton — neutro)
        │   └── BtnConfirmarSalir (TextButton — rojo)
        └── ModalNote (Frame — nota logros guardados)
            └── ModalNoteLabel (TextLabel — 💾)
```

> **Importante**: El HUD muestra el **puntaje base acumulado** (sin penalizaciones
> ni bonus de tiempo). El desglose completo aparece SOLO en la pantalla de victoria.

### `ConectarCables.lua` — Integración con ScoreTracker

```lua
-- Al conectar exitosamente:
ScoreTracker:registrarConexion()      -- +1 conexión → puntajeBase sube en HUD

-- Al intentar conexión inválida:
ScoreTracker:registrarFallo()         -- +1 fallo (resta puntos al final, NO en HUD)

-- Al desconectar un cable (hitbox click o reconectar el mismo par):
ScoreTracker:registrarDesconexion()   -- -1 conexión → puntajeBase baja en HUD
```

### `VisualEffectsService.client.lua` — Efectos de selección

Escucha `NotificarSeleccionNodo` (RemoteEvent) y aplica efectos localmente:

```
NodoSeleccionado → SelectionBox CYAN en nodo seleccionado
                 → SelectionBox DORADO en cada nodo adyacente
SeleccionCancelada / ConexionCompletada / CableDesconectado → limpiar todo
ConexionInvalida   → limpiar + flash ROJO   en nodo destino (no son adyacentes)
DireccionInvalida  → limpiar + flash NARANJA en nodo destino (arista existe al revés)
```

Los Beams (cables conectados) son creados server-side con color celeste brillante
`RGB(0, 200, 255)`, `CurveSize = 0` (siempre tenso), `FaceCamera = true`.

### `GuiaService.lua` — Consciente de zonas y dificultad

```lua
-- En dificultad Experto: visualHelpers = false
-- GuiaService no muestra waypoints ni flechas
-- Solo funciona la guía textual interna de las misiones

function GuiaService:activate(dificultad)
  if dificultad == "Experto" then
    self.enabled = false  -- No mostrar guía visual
    return
  end
  -- Lógica normal de waypoints
end
```

### `ZoneTriggerManager.lua` — Detección de zonas

```lua
-- Al entrar a una zona:
-- 1. Marca al jugador con CurrentZone attribute
-- 2. Dispara ZoneEntered BindableEvent
-- 3. DialogueOrchestrator recibe el evento y activa el diálogo
-- 4. MissionsManager filtra sus misiones por la zona actual
-- 5. GuiaService avanza si la zona coincide con el paso actual

-- NUEVO: Registrar la primera vez que se entra a cada zona
-- para reproducir efectos de "descubrimiento" solo 1 vez
```

---

## 8. Etapa 5 — Victoria y Resultados

### Flujo de victoria

```
MissionService detecta victoria
  │
  ▼
ScoreTracker:finalize()
  → { conexiones=13, fallos=2, tiempo=222, puntajeBase=650 }
  │
  ▼
RewardService:calculateRewards(snapshot, config)
  → { estrellas=3, xp=500, bonusTiempo=200, penalizacion=20 }
  │
  ▼
PuntajeFinal = puntajeBase - penalizacion + bonusTiempo
  │
  ▼
DataService:saveResult(player, nivelID, resultado)
  │
  ▼
RemoteEvent "LevelCompleted" → cliente con payload COMPLETO
  → VictoryScreen muestra desglose completo
```

### Pantalla de resultados (desglose completo)

```
┌─────────────────────────────────────────┐
│           ¡NIVEL COMPLETADO!            │
│                 ★ ★ ★                   │
│                                         │
│  Puntaje final    1 250 pts             │
│  ─────────────────────────────          │
│  ✓ Conexiones      13  (+650 pts)      │
│  ✗ Fallos           2  ( −20 pts)      │
│  ⏱ Tiempo        3:42  (+200 pts)      │
│  ⭐ Bonus misión       (+420 pts)      │
│                                         │
│  XP ganada: +500                        │
│                                         │
│  [ MENÚ ]      [ REINTENTAR ]           │
└─────────────────────────────────────────┘
```

> **Nota de UX**: Durante el gameplay, el jugador solo ve "📊 340 pts" en el HUD.
> La suma con bonificaciones y penalizaciones es una sorpresa positiva al final.

---

## 9. Etapa 6 — Vuelta al Menú

```
Jugador presiona "Menú"
  │
  ▼
TransitionScreen fade in
  │
  ▼
RemoteEvent "ReturnToMenu"
  │
  ▼
Servidor: GameplayManager:deactivate()
           LevelLoader:unload()
           GraphService:clear()
           EnergyService:reset()
           ScoreTracker:reset()
  │
  ▼
Servidor → BindableEvent "OpenMenu"
  │
  ▼
Cliente: TransitionScreen fade out
         MenuScreen activo con cámara cinemática
         LevelSelectorUI recarga datos (con nuevo highscore)
```

---

## 10. Sistema de Puntaje 2.0

### Cálculo del puntaje

```
PuntajeBase    = conexiones × PuntosConexion   (visible en HUD durante gameplay)
Penalizacion   = fallos × PenaFallo            (oculto durante gameplay)
BonusTiempo    = tiempo < Umbral1 → +200
                 tiempo < Umbral2 → +100
                 tiempo ≥ Umbral2 → 0
BonusMisiones  = suma de puntos de misiones completadas
PuntajeFinal   = max(0, PuntajeBase + BonusMisiones − Penalizacion + BonusTiempo)
```

> ⚠️ **Separación HUD / Resultados**:
> - **HUD** → muestra `PuntajeBase` acumulado (conexiones × PuntosConexion)
> - **Pantalla de resultados** → muestra `PuntajeFinal` con desglose completo

### `LevelsConfig.Puntuacion` ampliado

```lua
Puntuacion = {
  TresEstrellas  = 1000,
  DosEstrellas   = 600,
  RecompensaXP   = 500,
  BonusTiempo    = {
    Umbral1 = 120,   -- < 2 min → +200 pts
    Umbral2 = 300,   -- < 5 min → +100 pts
  },
  PuntosConexion = 50,   -- por cable correcto colocado
  PenaFallo      = 10,   -- por intento inválido
},
```

### Lo que se persiste en DataStore

```lua
{
  Unlocked    = true,
  Stars       = 3,
  HighScore   = 1250,      -- puntaje FINAL (con bonus/penal)
  Aciertos    = 13,        -- conexiones del mejor intento
  Fallos      = 2,
  TiempoMejor = 222,
  Intentos    = 4,
  Dificultad  = "Normal",  -- NUEVO
}
```

Solo se actualiza si `PuntajeFinal > HighScore` anterior.

---

## 11. Sistema de Efectos

### 11.1 Efectos de Sonido

```lua
-- AudioConfig.lua
return {
  CableConnect    = "rbxassetid://...",
  CableSnap       = "rbxassetid://...",
  CableError      = "rbxassetid://...",
  CableRemove     = "rbxassetid://...",
  MenuClick       = "rbxassetid://...",
  LevelStart      = "rbxassetid://...",
  ZoneEnter       = "rbxassetid://...",
  VictoryFanfare  = "rbxassetid://...",
  Stars1          = "rbxassetid://...",
  Stars2          = "rbxassetid://...",
  Stars3          = "rbxassetid://...",
  Ambient_Menu    = "rbxassetid://...",
  Ambient_Nivel0  = "rbxassetid://...",
}
```

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

```lua
VisualEffects:nodeSelected(nodo)        -- highlight + scale up
VisualEffects:nodeDeselected(nodo)      -- vuelve al estado normal
VisualEffects:nodeConnected(nodo)       -- flash verde + partícula chispa
VisualEffects:nodeError(nodo)           -- flash rojo + shake pequeño
VisualEffects:nodeEnergized(nodo)       -- glow cian pulsante
VisualEffects:cableConnected(cable)     -- fade in + glow
VisualEffects:cableRemoved(cable)       -- fade out rápido
VisualEffects:zoneUnlocked(zona)        -- rayos de luz + partículas doradas
VisualEffects:zoneComplete(zona)        -- sello verde sobre la zona
VisualEffects:fadeIn(duration)
VisualEffects:fadeOut(duration)
VisualEffects:victoryConfetti()
VisualEffects:starPopIn(count)
```

### 11.3 Módulo Compartido de Efectos Visuales

Los efectos visuales se dividen en tres capas para que **cualquier script del servidor o del cliente** pueda solicitar efectos sin acoplarse a la implementación.

#### Estructura de archivos

```
ReplicatedStorage/Shared/
└── VisualEffectsConfig.lua         ← NUEVO: constantes (requerido desde cliente Y servidor)

ServerScriptService/Services/
└── VisualEffectsManager.lua        ← NUEVO: API servidor — dispara PlayEffect (RemoteEvent)

StarterPlayerScripts/Client/Services/
└── VisualEffectsService.client.lua ← ACTUALIZADO: escucha PlayEffect + NotificarSeleccionNodo
```

#### `VisualEffectsConfig.lua` — Constantes compartidas

```lua
-- ReplicatedStorage/Shared/VisualEffectsConfig.lua
-- Sin llamadas a API de Roblox → seguro desde servidor y cliente
return {
  Colors = {
    Selected  = Color3.fromRGB(0,   212, 255),  -- cyan   (nodo seleccionado)
    Adjacent  = Color3.fromRGB(255, 200,  50),  -- dorado (adyacentes)
    Invalid   = Color3.fromRGB(239,  68,  68),  -- rojo   (error)
    Connected = Color3.fromRGB(80,  255, 120),  -- verde  (conexión exitosa)
    Energized = Color3.fromRGB(0,   200, 255),  -- cian   (nodo energizado pulsante)
  },
  Durations = { Flash = 0.35, Pulse = 1.2, FadeIn = 0.2 },
  Effects = {
    -- Strings usados como primer argumento en PlayEffect RemoteEvent
    NODE_SELECTED   = "NodeSelected",   -- arg1=nodoModel, arg2=adjModels[]
    NODE_ERROR      = "NodeError",      -- arg1=nodoModel  (flash rojo)
    NODE_ENERGIZED  = "NodeEnergized",  -- arg1=nodoModel  (glow cian pulsante)
    CABLE_CONNECTED = "CableConnected", -- arg1=nomA, arg2=nomB
    CABLE_REMOVED   = "CableRemoved",   -- arg1=nomA, arg2=nomB
    ZONE_COMPLETE   = "ZoneComplete",   -- arg1=zonaID
    CLEAR_ALL       = "ClearAll",
  },
}
```

#### `VisualEffectsManager.lua` — API del servidor

```lua
-- ServerScriptService/Services/VisualEffectsManager.lua
-- El servidor NUNCA aplica efectos visuales directamente.
-- Solo dispara PlayEffect (RemoteEvent) al cliente correspondiente.
local VEM = {}
local _ev = nil

function VEM.init(remotes)
  _ev = remotes:FindFirstChild("PlayEffect")
end
-- Efecto para un jugador específico
function VEM.fire(player, effectType, ...)
  if _ev then _ev:FireClient(player, effectType, ...) end
end
-- Efecto para todos los jugadores
function VEM.fireAll(effectType, ...)
  if _ev then _ev:FireAllClients(effectType, ...) end
end
return VEM
```

#### `VisualEffectsService.client.lua` — Ampliaciones

Escucha **dos** RemoteEvents:
- `NotificarSeleccionNodo` — selección/cancelación de nodos (sin cambios, compatibilidad total)
- `PlayEffect` — todos los demás efectos disparados por cualquier sistema del servidor

| Efecto nuevo | Implementación cliente |
|---|---|
| **Cross-room highlight** | `BillboardGui` con `AlwaysOnTop = true` sobre el Selector |
| **Energized glow** | `Highlight` cian + TweenService en `FillTransparency` (pulso) |
| **Zone complete** | Partícula dorada sobre el centro de la zona |
| **Cable flash verde** | Flash verde breve en ambos nodos al conectar |

`clearAll()` destruye `_billboards[]` junto con `_highlights[]` y restaura `_savedStates[]`.

#### Cómo usar desde cualquier sistema servidor

```lua
local VEM = require(ServerScriptService.Services.VisualEffectsManager)
local VEC = require(RS.Shared.VisualEffectsConfig)

-- Desde ConectarCables: error de conexión
VEM.fire(player, VEC.Effects.NODE_ERROR, nodoModel)

-- Desde MissionService: zona completada
VEM.fireAll(VEC.Effects.ZONE_COMPLETE, "Zona_Estacion_1")
```

> **Regla de seguridad**: Solo el servidor dispara `PlayEffect:FireClient`. El RemoteEvent es de solo lectura para el cliente — no puede abusar de él para forzar efectos en otros jugadores.

---

## 12. Menú Principal — Ventanas Modales

### Diseño visual del menú

```
┌────────────────────────────────────────────────┐
│                                                │
│    [vista cinemática de los niveles en loop]   │
│                                                │
│                                                │
│         EXPLORADOR DE GRAFOS                   │
│         ─────────────────────                  │
│         [ ▶  JUGAR ]                           │
│         [ ⚙  AJUSTES ]                         │
│         [ ℹ  CRÉDITOS ]                        │
│         [ ✕  SALIR ]                           │
│                                                │
└────────────────────────────────────────────────┘
```

### Modal de Ajustes

```
┌────────────────────────────────────────┐
│  ⚙ AJUSTES                        [✕] │
│  ─────────────────────────────────    │
│                                       │
│  DIFICULTAD                           │
│  ● Normal   ○ Difícil   ○ Experto    │
│                                       │
│  COLORES DE CABLE                     │
│  ● Clásico  ○ Neon  ○ Personalizado  │
│  Color: [████████] (color picker)     │
│                                       │
│  COLORES DE INDICADORES               │
│  Zona activa:      [████] (picker)    │
│  Nodo seleccionado:[████] (picker)    │
│  Válido/Inválido:  [████] (picker)    │
│                                       │
│  AUDIO                                │
│  Ambiente: [══════════════] 70%       │
│  Efectos:  [══════════════] 80%       │
│                                       │
│        [Guardar]   [Cancelar]         │
└────────────────────────────────────────┘
```

**Descripción de la dificultad**:
- **Normal**: Niveles como están diseñados. Guía visual activa.
- **Difícil**: +30% de nodos en el mapa. Presupuesto reducido 20%. Límite de 10 min.
- **Experto**: +60% de nodos. Sin guía visual. Sin pistas de zona. Límite de 5 min.

### Modal de Créditos

```
┌────────────────────────────────────────┐
│  ℹ CRÉDITOS                       [✕] │
│  ─────────────────────────────────    │
│                                       │
│  EXPLORADOR DE GRAFOS v2.0            │
│  Un juego educativo de teoría de      │
│  grafos para Roblox.                  │
│                                       │
│  DESARROLLO                           │
│  • [Nombre del desarrollador]         │
│                                       │
│  HERRAMIENTAS                         │
│  • Roblox Studio                      │
│  • Lua 5.1                            │
│                                       │
│  INSPIRACIÓN                          │
│  • Teoría de grafos aplicada          │
│  • Diseño educativo gamificado        │
│                                       │
│              [Cerrar]                 │
└────────────────────────────────────────┘
```

### Modal de Salir (confirmación)

```
┌──────────────────────────────────┐
│  ¿Salir del juego?               │
│                                  │
│  Tu progreso guardado se         │
│  mantendrá para la próxima vez.  │
│                                  │
│  [Cancelar]    [Salir]           │
└──────────────────────────────────┘
```

---

## 13. Mejoras de Arquitectura Identificadas

### 13.1 Eliminar `_G.Services` — Race Conditions

**Problema actual**: Múltiples scripts usan `task.wait(1)` y luego leen `_G.Services.X`.
Si el servidor tarda, falla silenciosamente sin error claro.

```lua
-- ❌ Problemático en: ConectarCables.server.lua, GraphTheoryService.server.lua,
--    VisualizadorAlgoritmos.server.lua, MissionService.lua
task.wait(1)
local LevelService = _G.Services.Level

-- ✅ Solución con ServiceLocator
local LevelService = ServiceLocator:waitFor("Level")
-- waitFor() yields hasta que el servicio exista, con timeout explícito
```

### 13.2 MisionService — Validador GRAFO_CONEXO incompleto

**Problema detectado**:

```lua
-- En MissionService.lua, Validators.GRAFO_CONEXO:
-- Solo verifica si los nodos son alcanzables desde el primero de la lista.
-- NO verifica que todos sean alcanzables ENTRE SÍ (solo desde nodos[1]).
-- Esto puede dar falsos positivos si el grafo tiene componentes separadas.
```

**Solución**:

```lua
Validators.GRAFO_CONEXO = function(params, estado)
  local nodos = params.Nodos or {}
  if #nodos == 0 then return false end

  -- Verificar conectividad bidireccional: cada nodo alcanza a todos
  for _, raiz in ipairs(nodos) do
    local alcDesdeRaiz = estado.alcanzablesDesde[raiz] or {}
    for _, destino in ipairs(nodos) do
      if not alcDesdeRaiz[destino] then
        return false
      end
    end
  end
  return true
end
```

### 13.3 ScoreTracker separado de MissionService

**Problema actual**: `MissionService` suma puntos directamente a `leaderstats.Puntos`
cuando completa misiones. Esto mezcla responsabilidades y hace difícil calcular el
puntaje final correctamente.

**Solución**: `ScoreTracker` es el único que toca `leaderstats.Puntos` durante gameplay.
`MissionService` emite eventos de misión completada; `ScoreTracker` los escucha y suma.

```lua
-- MissionService emite:
missionCompletedEvent:Fire(missionId, missionPoints)

-- ScoreTracker escucha:
MissionService:onMissionCompleted(function(id, pts)
  self.baseScore = self.baseScore + pts
  self:_notifyClient()  -- RemoteEvent UpdateScore
end)
```

### 13.4 ConectarCables — Cable visual y hitbox ✅ RESUELTO

**Solución implementada**:
- Cable visual: **`Beam`** (no `RopeConstraint`). Siempre tenso (`CurveSize0/1 = 0`),
  color celeste brillante, `FaceCamera = true`.
- Click-to-disconnect: `BasePart` hitbox invisible centrado en el cable con `ClickDetector`.
- El `Beam` es hijo del hitbox → ambos se destruyen juntos con `hitbox:Destroy()`.
- Desconectar llama `ScoreTracker:registrarDesconexion()` (descuenta del puntaje base visible).

```lua
-- Estructura en Conexiones/
-- ├── Hitbox_NomA_NomB (Part, invisible, anchored)
-- │   ├── Cable_NomA_NomB (Beam, celeste, CurveSize=0)
-- │   └── ClickDetector
```

### 13.5 GuiaService — Debería avanzar por zonas completadas

**Problema actual**: `GuiaService` avanza manualmente con `GuiaAvanzar:Fire(id)`.
El paso `zona1` tiene `Zona = "Zona_Estacion_1"` definido en el config, pero
no hay código que conecte automáticamente "todas las misiones de la zona completadas"
con "avanzar el waypoint de la guía".

**Solución**: `GameplayManager` conecta `MissionService:onZoneComplete` con
`GuiaService:advanceToNextStep`.

```lua
-- En GameplayManager:activate()
MissionService:onZoneComplete(function(zonaID)
  GuiaService:advanceByZone(zonaID)
end)
```

### 13.6 DataService — Inventario no usa índice por ID

**Problema actual**: El inventario se guarda como array `{ "item1", "item2" }`.
Al verificar si tiene un item se usa `table.find()`, que es O(n). Con inventarios
grandes, esto puede ser lento.

**Solución**: Guardar como diccionario `{ item1 = true, item2 = true }`.

```lua
-- DataService al cargar:
local inventoryDict = {}
for _, itemId in ipairs(rawInventory or {}) do
  inventoryDict[itemId] = true
end
data.Inventory = inventoryDict

-- Al guardar, convertir de vuelta a array para DataStore
local inventoryArray = {}
for itemId, _ in pairs(data.Inventory) do
  table.insert(inventoryArray, itemId)
end
MainStore:SetAsync(key, { ..., Inventory = inventoryArray })
```

### 13.7 AudioService — `playSound` crea nueva instancia cada vez

**Problema actual**: `AudioService:playSound()` crea un nuevo `Sound` en Workspace
para cada reproducción y usa `Debris` para limpiar. Esto puede acumular muchos
objetos si se reproducen sonidos rápidamente.

**Solución**: Pool de instancias de sonido reutilizables.

```lua
local soundPool = {}

local function getSoundInstance(soundId)
  for _, s in ipairs(soundPool) do
    if not s.IsPlaying then
      s.SoundId = soundId
      return s
    end
  end
  -- Crear nueva si el pool está lleno
  local s = Instance.new("Sound")
  s.Parent = game:GetService("SoundService")
  table.insert(soundPool, s)
  return s
end
```

### 13.8 VictoryScreen — Debe recibir datos de ScoreTracker, no leer leaderstats

**Problema actual**: `VictoryScreenManager` muestra stats que toma del evento
`LevelCompleted`, pero el payload puede ser incompleto si `ScoreTracker` no
se inicializó correctamente.

**Solución**: Garantizar que el payload de `LevelCompleted` siempre incluya:

```lua
{
  nivelID      = number,
  puntajeBase  = number,   -- sum(conexiones × PuntosConexion)
  bonusMision  = number,   -- sum(misiones.Puntos)
  penalizacion = number,   -- fallos × PenaFallo
  bonusTiempo  = number,   -- según tiempo
  puntajeFinal = number,   -- total
  conexiones   = number,
  fallos       = number,
  tiempo       = number,   -- segundos
  estrellas    = number,
  xp           = number,
}
```

### 13.9 ZoneTriggerManager — Formato incompatible con LevelsConfig

**Problema detectado**:

`LevelsConfig[n].Zonas` es un diccionario sin campo `Trigger`:

```lua
Zonas = {
  ["Zona_Estacion_1"] = { Modo = "ALL", NodosRequeridos = {...} },  -- ❌ sin Trigger
}
```

`ZoneTriggerManager.activate(nivel, zonas, player)` espera un **array** con el nombre de la `BasePart` trigger:

```lua
{ { nombre = "Zona_Estacion_1", trigger = "ZonaTrigger_Estacion1" } }
```

Sin ese campo, `triggerPart` es `nil` para todas las zonas y **ningún detector Touched/TouchEnded se registra**.

**Solución**:

1. Añadir campo `Trigger` en cada entrada de `LevelsConfig.Zonas` que deba detectarse físicamente:

```lua
["Zona_Estacion_1"] = {
  Modo = "ALL", Descripcion = "...", NodosRequeridos = {...},
  Trigger = "ZonaTrigger_Estacion1",  -- ← NUEVO: nombre de la BasePart en Zonas_juego/
},
```

2. En `GameplayManager`, convertir el dict al array antes de llamar `ZoneTriggerManager.activate()`:

```lua
local zonasArray = {}
for nombre, cfg in pairs(levelCfg.Zonas or {}) do
  if cfg.Trigger then  -- zonas con Oculta=true o sin trigger se omiten
    table.insert(zonasArray, { nombre = nombre, trigger = cfg.Trigger })
  end
end
ZoneTriggerManager.activate(nivel, zonasArray, player)
```

3. Crear en Studio las `BasePart` (`CanCollide = false`, `Transparency = 1`) dentro de `NivelActual/Zonas/Zonas_juego/` con los nombres correspondientes.

### 13.10 VisualEffectsService — Highlight visible a través de paredes (cross-room)

**Situación actual**:
`Highlight` con `DepthMode = AlwaysOnTop` renderiza sobre toda la geometría de Roblox, incluyendo paredes. Sin embargo, el icono puede pasar desapercibido si el nodo está en otra habitación o a gran distancia.

**Mejora — BillboardGui pulsante complementario**:

```lua
-- En VisualEffectsService: addBillboard(selectorBasePart, color)
local _billboards = {}

local function addBillboard(part, color)
  if not part or not part:IsA("BasePart") then return end
  local bb = Instance.new("BillboardGui")
  bb.Adornee               = part
  bb.StudsOffset           = Vector3.new(0, 4, 0)
  bb.StudsOffsetWorldSpace = true    -- siempre vertical, ignora rotación del nodo
  bb.AlwaysOnTop           = true    -- ✅ visible a través de paredes y geometría
  bb.Size                  = UDim2.fromOffset(50, 50)
  bb.ResetOnSpawn          = false
  bb.Parent                = Workspace

  local icon = Instance.new("TextLabel")
  icon.Size                = UDim2.fromScale(1, 1)
  icon.BackgroundTransparency = 1
  icon.Text                = "●"
  icon.TextColor3          = color
  icon.TextScaled          = true
  icon.Parent              = bb
  table.insert(_billboards, bb)
end

-- clearAll() ampliado:
local function clearAll()
  for _, h in ipairs(_highlights)  do if h.Parent then h:Destroy() end end
  for _, b in ipairs(_billboards)  do if b.Parent then b:Destroy() end end
  for _, s in ipairs(_savedStates) do
    if s.part and s.part.Parent then
      s.part.Color        = s.origColor
      s.part.Material     = s.origMat
      s.part.Transparency = s.origTransp
    end
  end
  _highlights, _billboards, _savedStates = {}, {}, {}
end
```

`highlightNode()` llama también a `addBillboard(basePart, color)` junto con `addHighlight()` y `styleBasePart()`.

**Resultado**: El jugador ve el outline del `Highlight` **+** el ícono flotante del `BillboardGui` con `AlwaysOnTop`, independientemente de su posición en el mapa.

---

## 14. Patrones de Diseño Utilizados

### Service Locator (reemplaza `_G.Services`)

```lua
function ServiceLocator:register(name, service) end
function ServiceLocator:get(name) end           -- assert si no existe
function ServiceLocator:waitFor(name, timeout)  end  -- yield hasta que exista
```

### Observer / Event-Driven

```
EventRegistry → ServerReady
Boot → registra servicios
Boot → escucha LevelLoaded → activa GameplayManager
GameplayManager → activa módulos → escuchan eventos de gameplay
GameplayManager → desactiva → desconectan todos sus listeners
```

### Module Pattern con activate/deactivate

```lua
function ConectarCables.activate(nivelActual, services) end
function ConectarCables.deactivate() end
```

### Data-Driven Dialogues

Los diálogos son **tablas de datos**, no código. `DialogueOrchestrator` es el motor.

### Separation of Concerns — Puntaje

- `ScoreTracker` → calcula y almacena puntos en tiempo real
- `HUD` → muestra puntaje BASE (sin bonus/penal) durante gameplay
- `VictoryScreen` → muestra puntaje FINAL con desglose completo
- `MissionService` → emite eventos de misión, NO modifica leaderstats directamente

---

## 15. Orden de Implementación

### Fase 0 — Infraestructura (sin tocar gameplay)

1. Crear `EventRegistry.server.lua`
2. Crear `ServiceLocator.lua` (server y client)
3. Crear `TableUtils.lua` con `countKeys()`, `deepCopy()`, `shallowMerge()`
4. Crear `Constants.lua`
5. **FIX**: Reemplazar todos los `task.wait(1) + _G.Services.X` por `ServiceLocator:waitFor()`

### Fase 1 — Boot y carga ordenada

6. Crear `Boot.server.lua`
7. Crear `LevelLoader.lua`
8. Corregir `GraphService`, `EnergyService`, `MissionService` para recibir servicios por parámetro
9. **FIX**: Validador `GRAFO_CONEXO` en `MissionService`
10. **FIX**: `ClickDetector` en cables → hitbox de `BasePart`

### Fase 2 — Puntaje y separación de responsabilidades

11. Crear `ScoreTracker.lua` desacoplado de `MissionService`
12. Actualizar `MissionService` para emitir eventos en lugar de modificar `leaderstats`
13. Ampliar `LevelsConfig` con `PuntosConexion`, `PenaFallo`, `BonusTiempo`
14. Ampliar `DataService` para persistir campos nuevos y usar inventario como diccionario
15. Actualizar `VictoryScreen` para mostrar desglose completo
16. Actualizar `HUD` para mostrar solo puntaje base

### Fase 3 — Gameplay consciente

17. Crear `GameplayManager.server.lua`
18. Convertir `ConectarCables` a ModuleScript con `activate`/`deactivate`
19. Crear `ZoneTriggerManager.lua`
20. Conectar `ZoneTriggerManager` → `GuiaService` automáticamente
21. Crear `DialogueOrchestrator.lua` con formato de datos
22. Migrar diálogos de Zona 1 al nuevo formato (prueba piloto)
23. Migrar Zonas 2, 3 y 4

### Fase 3b — Módulo VisualEffects compartido y fixes de zonas (Etapa 4)

24. **FIX §13.9** — Añadir campo `Trigger` en cada entrada de `LevelsConfig.Zonas` + conversión dict→array en `GameplayManager` antes de llamar `ZoneTriggerManager.activate()`
25. Crear `ReplicatedStorage/Shared/VisualEffectsConfig.lua` — constantes compartidas (colores, tipos de efecto)
26. Crear `ServerScriptService/Services/VisualEffectsManager.lua` — API servidor (`VEM.fire`, `VEM.fireAll`)
27. Expandir `VisualEffectsService.client.lua`: escuchar `PlayEffect` RemoteEvent, añadir `addBillboard()` con `AlwaysOnTop = true` (§13.10), implementar efectos `NODE_ENERGIZED`, `CABLE_CONNECTED`, `ZONE_COMPLETE`
28. Actualizar `ConectarCables.lua` para usar `VEM.fire(player, VEC.Effects.NODE_ERROR, nodoModel)` y `VEM.fire(player, VEC.Effects.CABLE_CONNECTED, nomA, nomB)` en lugar de `NotificarSeleccionNodo` directo para estos eventos

### Fase 4 — Menú y Ajustes

24. Crear `MenuScreen.lua` con cámara cinemática en loop
25. Crear `MenuModals.lua` (Ajustes, Créditos, Salir)
26. Crear `DifficultyConfig.lua` y `DifficultyService.lua`
27. Conectar Ajustes → DataStore (persistir configuración del jugador)
28. Aplicar colores de cable / indicadores desde configuración guardada

### Fase 5 — Efectos

29. Crear `AudioConfig.lua` y mapear todos los sonidos
30. Crear pool de sonidos en `AudioService`
31. Crear `TransitionScreen.lua`
32. Expandir `VisualEffectsService` con efectos de nodo y cable
33. Añadir partículas en `EffectsService`
34. Implementar `CameraEffects`

### Fase 6 — Pulido y validación

35. Tests de race conditions: `ServerReady` llega antes que cualquier gameplay
36. Tests de puntaje: verificar que HUD muestra base, pantalla final muestra total
37. Tests de dificultad: normal/difícil/experto funcionan correctamente
38. Tests de sonido: cada efecto suena en el momento correcto
39. Stress test: volver al menú y re-entrar 3 veces sin memory leaks

---

## Notas y Decisiones de Diseño

- **`_G` queda eliminado** completamente. `ServiceLocator` lo reemplaza.

- **Separación HUD / Resultados**: El jugador ve progreso positivo durante el juego
  (solo conexiones que suman). La "sorpresa" de bonus/penalizaciones al final
  incentiva terminar bien sin frustrar durante el juego.

- **Ajustes de dificultad**: Los modificadores se aplican a una copia de `LevelsConfig`,
  nunca al original. Cambiar dificultad entre intentos es seguro.

- **Inventario como diccionario**: Más eficiente para lookups; se serializa a array
  solo al guardar en DataStore.

- **Hitbox de cable**: Más confiable que `ClickDetector` en `RopeConstraint`.
  El hitbox sigue el cable visualmente y detecta clicks correctamente.

- **GuiaService consciente de dificultad**: En Experto, la guía visual desaparece
  completamente, añadiendo desafío sin romper el sistema de misiones.

- **Pool de sonidos**: Evita crear/destruir objetos de sonido frecuentemente,
  mejorando el rendimiento en momentos de muchas conexiones rápidas.
