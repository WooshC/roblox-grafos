# Plan: Sistema de Audio Ambiental + Pantalla de Victoria

> **Estado**: Plan aprobado pendiente de implementación
> **Sprint**: 2
> **Épicas cubiertas**: Audio del juego, Flujo de victoria, Estadísticas de sesión

---

## Índice

1. [Diagnóstico del estado actual](#1-diagnóstico-del-estado-actual)
2. [Arquitectura propuesta](#2-arquitectura-propuesta)
3. [Estructura de carpetas de sonido](#3-estructura-de-carpetas-de-sonido)
4. [Cambios en LevelsConfig](#4-cambios-en-levelsconfig)
5. [Nuevo módulo: AudioClient](#5-nuevo-módulo-audioclient)
6. [Seguimiento de estadísticas de sesión](#6-seguimiento-de-estadísticas-de-sesión)
7. [Nuevo módulo: VictoryScreenManager](#7-nuevo-módulo-victoryscreenmanager)
8. [Flujo completo de victoria](#8-flujo-completo-de-victoria)
9. [Bug crítico a eliminar antes de implementar](#9-bug-crítico-a-eliminar-antes-de-implementar)
10. [Cambios en archivos existentes](#10-cambios-en-archivos-existentes)
11. [Lista de tareas de implementación](#11-lista-de-tareas-de-implementación)

---

## 1. Diagnóstico del estado actual

### Problemas encontrados en AudioService (servidor)

| Problema | Archivo | Línea aprox. |
|----------|---------|--------------|
| `fadeInSound` / `fadeOutSound` usan `RenderStepped` — nunca dispara en servidor | `AudioService.lua` | 210, 231 |
| `playVictoryMusic()` se llama desde servidor pero no produce fades ni controla timing | `MissionService.lua` | 429 |
| Volúmenes por defecto hardcodeados en dos lugares distintos | `AudioService.lua` | 14–19 y 268–272 |

**Conclusión**: la música, el ambiente y la fanfarria de victoria deben manejarse en el **cliente**. Los SFX cortos (cable conectado/desconectado, error) pueden quedarse en el servidor porque no necesitan fades.

### Bug crítico en el flujo de victoria

En `GameplayEvents.server.lua` líneas 241–245 existe este bloque:

```lua
local OpenMenuEvent = Bindables:FindFirstChild("OpenMenu")
if OpenMenuEvent then
    OpenMenuEvent:Fire()  -- ← DISPARA INMEDIATAMENTE, antes de cualquier pantalla
end
```

Este código se ejecuta nada más detectarse la victoria. El menú se abre sin que el jugador haya visto nada. **Debe eliminarse** — `OpenMenu` solo se debe disparar cuando el jugador pulse "Continuar" en la pantalla de resultados.

---

## 2. Arquitectura propuesta

```
SERVIDOR                            CLIENTE
─────────────────────               ─────────────────────────────────────────
MissionService                      AudioClient
  detecta victoria          →         recibe LevelCompletedEvent con stats
  calcula stats (tiempo,              reproduce Fanfare (~3s)
  errores, aciertos)        →         cuando Fanfare termina:
  FireClient(stats)                     VictoryScreenManager.mostrar(stats)
                                          botón "Repetir" → ResetLevelEvent:FireServer()
                                          botón "Continuar" → OpenMenu:Fire() (BindableEvent)
```

**Principio**: el servidor solo calcula y envía datos. Todo lo visual y auditivo del resultado vive en el cliente.

---

## 3. Estructura de carpetas de sonido

Crear en Roblox Studio (no por código). Los `Sound` objects se crean en el editor con sus `SoundId` asignados manualmente.

```
ReplicatedStorage/
└── Audio/                        ← ya existe, se reorganiza internamente
    ├── SFX/                      ← sonidos cortos de gameplay (mover aquí los existentes)
    │   ├── CableConnect
    │   ├── CableSnap
    │   ├── Error
    │   ├── Success
    │   ├── MisionCompleta        ← NUEVO (jingle ~1s al completar misión)
    │   └── ZonaCompleta          ← NUEVO (jingle ~1.5s al activar zona)
    ├── Ambiente/                 ← NUEVO – loops por nivel
    │   ├── Nivel0                (laboratorio: zumbido eléctrico, ventiladores)
    │   ├── Nivel2                (ciudad: viento suave, tráfico lejano)
    │   ├── Nivel3                (industrial: maquinaria, vapor)
    │   └── Nivel4                (metrópolis activa)
    └── Victoria/                 ← NUEVO – música de resultados
        ├── Fanfare               (jingle corto ~3–4s, suena AL completar)
        └── Tema                  (música larga, suena DURANTE la pantalla de resultados)
```

**Nota**: los nombres (`"Nivel0"`, `"Fanfare"`, etc.) son los `Name` exactos de los objetos `Sound` en Studio. Son los mismos strings que se usarán en `LevelsConfig.Audio`.

---

## 4. Cambios en LevelsConfig

Agregar campo `Audio` a cada entrada de nivel. El valor es el nombre del `Sound` en la subcarpeta correspondiente de `ReplicatedStorage/Audio/`.

```lua
-- Nivel 0 (Laboratorio de Grafos)
LevelsConfig[0] = {
    -- ... todos los campos existentes sin cambios ...
    Audio = {
        Ambiente = "Nivel0",    -- ReplicatedStorage/Audio/Ambiente/Nivel0
        Victoria = "Fanfare",   -- ReplicatedStorage/Audio/Victoria/Fanfare
        TemaVictoria = "Tema",  -- ReplicatedStorage/Audio/Victoria/Tema (durante resultados)
    }
}

-- Nivel 2
LevelsConfig[2] = {
    -- ...
    Audio = { Ambiente = "Nivel2", Victoria = "Fanfare", TemaVictoria = "Tema" }
}

-- Niveles 3 y 4: igual, con sus respectivos Ambiente
LevelsConfig[3] = {
    Audio = { Ambiente = "Nivel3", Victoria = "Fanfare", TemaVictoria = "Tema" }
}

LevelsConfig[4] = {
    Audio = { Ambiente = "Nivel4", Victoria = "Fanfare", TemaVictoria = "Tema" }
}
```

Si un nivel no tiene `Audio` o el `Sound` no existe en Studio, el AudioClient simplemente no reproduce nada (sin error).

---

## 5. Nuevo módulo: AudioClient

**Ubicación**: `StarterPlayer/StarterPlayerScripts/Cliente/Services/AudioClient.lua`

**Responsabilidad exclusiva**: toda la música, ambiente y stingers en el cliente usando `TweenService` para fades.

### 5.1 Funciones públicas

| Función | Descripción |
|---------|-------------|
| `AudioClient.initialize(deps)` | Se llama desde `GUIExplorador.lua` |
| `AudioClient:iniciarAmbiente(nivelID)` | Fade in del ambiente del nivel |
| `AudioClient:detenerAmbiente()` | Fade out de todo el ambiente |
| `AudioClient:reproducirFanfare(nivelID, callback)` | Reproduce Fanfare; llama `callback` al terminar |
| `AudioClient:reproducirTemaVictoria(nivelID)` | Reproduce loop de Tema durante resultados |
| `AudioClient:detenerTodo()` | Fade out de todos los sonidos activos |
| `AudioClient:reproducirStinger(nombre)` | SFX cortos: MisionCompleta, ZonaCompleta |

### 5.2 Eventos a escuchar

| Evento | Tipo | Acción |
|--------|------|--------|
| `player:GetAttributeChangedSignal("CurrentLevelID")` | Atributo | Si `>= 0`: `iniciarAmbiente(id)`. Si `-1`: `detenerTodo()` |
| `LevelCompletedEvent.OnClientEvent` | RemoteEvent | Llama `reproducirFanfare()` → cuando termina, notifica a `VictoryScreenManager` |
| `LocalZoneChanged` (fase futura) | BindableEvent | `reproducirStinger("ZonaCompleta")` |

### 5.3 Fades con TweenService

```lua
-- Ejemplo de fade in (usa TweenService, funciona en cliente)
local TweenService = game:GetService("TweenService")

local function fadeIn(sound, duracion)
    sound.Volume = 0
    sound:Play()
    TweenService:Create(sound, TweenInfo.new(duracion), { Volume = targetVolume }):Play()
end

local function fadeOut(sound, duracion, callback)
    local tween = TweenService:Create(sound, TweenInfo.new(duracion), { Volume = 0 })
    tween.Completed:Connect(function()
        sound:Stop()
        if callback then callback() end
    end)
    tween:Play()
end
```

### 5.4 Integración en GUIExplorador.lua

```lua
-- En GUIExplorador.lua, después de inicializar MatrixManager:
local AudioClient = require(Services:WaitForChild("AudioClient"))
AudioClient.initialize(deps)
-- AudioClient empieza a escuchar CurrentLevelID y LevelCompletedEvent automáticamente
```

---

## 6. Seguimiento de estadísticas de sesión

La pantalla de victoria mostrará: **tiempo**, **errores**, **aciertos**, **puntaje**, **estrellas**.

### 6.1 Qué datos ya existen

| Estadística | Origen actual |
|-------------|---------------|
| Puntaje | `leaderstats.Puntos.Value` |
| Estrellas | `leaderstats.Estrellas.Value` |
| Aciertos | `estado.numConexiones` en `MissionService:buildFullGameState()` |

### 6.2 Qué datos hay que agregar

#### Tiempo de sesión

- **Cuándo iniciar**: cuando `LevelService:loadLevel()` completa, el servidor hace `player:SetAttribute("LevelStartTime", os.time())`.
- **Cuándo calcular**: en `MissionService:checkVictoryCondition()` al detectar victoria:
  ```lua
  local startTime = player:GetAttribute("LevelStartTime") or os.time()
  local tiempoSegundos = os.time() - startTime
  ```

#### Contador de errores

- **Qué es un error**: un intento de conexión rechazado (nodos no adyacentes, presupuesto insuficiente).
- **Dónde incrementar**: en `ConectarCables.server.lua`, cuando la validación falla y se notifica al cliente de error. Actualmente ya existe lógica de rechazo — solo hay que contar.
- **Dónde guardar**: `player:SetAttribute("NivelErrores", contador)`. Se resetea en `LevelService:resetLevel()` y cuando se carga un nivel.

### 6.3 Payload del LevelCompletedEvent (ampliado)

Actualmente envía: `(player, nivelID, estrellas, puntos)`

**Nuevo payload** (tabla en lugar de argumentos sueltos para extensibilidad):

```lua
LevelCompletedEvent:FireClient(player, {
    nivelID   = nivelID,
    puntos    = puntos,
    estrellas = estrellas,
    tiempo    = tiempoSegundos,   -- número entero, segundos
    errores   = erroresCount,     -- intentos fallidos
    aciertos  = numConexiones,    -- cables correctamente colocados
})
```

El cliente usa esta tabla para poblar la pantalla de victoria.

---

## 7. Nuevo módulo: VictoryScreenManager

**Ubicación**: `StarterPlayer/StarterPlayerScripts/Cliente/Services/VictoryScreenManager.lua`

**Responsabilidad**: mostrar/ocultar la pantalla de resultados y manejar sus botones.

### 7.1 Funciones públicas

| Función | Descripción |
|---------|-------------|
| `VictoryScreenManager.initialize(gui, deps)` | Inyecta refs. `gui` = GUIExplorador |
| `VictoryScreenManager:mostrar(stats)` | Puebla la UI con stats y hace fade in |
| `VictoryScreenManager:ocultar()` | Hace fade out y limpia |

### 7.2 La pantalla (ScreenGui o Frame dentro de GUIExplorador)

Elemento a crear en Roblox Studio dentro de `GUIExplorador` (ScreenGui existente):

```
GUIExplorador/
└── PantallaVictoria            ← Frame, inicialmente Visible=false
    ├── FondoOscuro             ← Frame negro semitransparente (backdrop)
    ├── ContenedorPrincipal     ← Frame centrado, fondo oscuro/card
    │   ├── TituloVictoria      ← Label "¡NIVEL COMPLETADO!"
    │   ├── EstrellasMostrar    ← 3x ImageLabel (estrella llena/vacía)
    │   ├── EstadisticasFrame   ← Frame con grid de stats
    │   │   ├── FilaTiempo      ← "⏱ Tiempo: 2:34"
    │   │   ├── FilaAciertos    ← "✅ Conexiones: 5"
    │   │   ├── FilaErrores     ← "❌ Errores: 2"
    │   │   └── FilaPuntaje     ← "⭐ Puntaje: 1250"
    │   └── BotonesFrame        ← Frame horizontal
    │       ├── BotonRepetir    ← TextButton "🔄 Repetir"
    │       └── BotonContinuar  ← TextButton "▶ Continuar"
```

### 7.3 Comportamiento de los botones

#### Botón "Repetir"
1. `VictoryScreenManager:ocultar()`
2. Dispara `ResetNivelEvent:FireServer()` (RemoteEvent existente o nuevo)
3. El servidor llama `LevelService:resetLevel()`
4. La pantalla desaparece, el jugador sigue en el nivel

#### Botón "Continuar"
1. `VictoryScreenManager:ocultar()`
2. `AudioClient:detenerTodo()`
3. Dispara el BindableEvent `OpenMenu:Fire()` (el mismo que usa el menú actualmente)
4. El flujo de `MenuCameraSystem` toma el control (ya implementado y funcional)

**El evento `OpenMenu` NUNCA se dispara automáticamente desde el servidor. Solo desde este botón.**

### 7.4 Integración en GUIExplorador.lua

```lua
local VictoryScreenManager = require(Services:WaitForChild("VictoryScreenManager"))
VictoryScreenManager.initialize(gui, deps)
-- VictoryScreenManager es notificado por AudioClient cuando la Fanfare termina
```

---

## 8. Flujo completo de victoria

```
[SERVIDOR]
MissionService:checkVictoryCondition()
  → victoria detectada por primera vez (VictoryProcessed = false)
  → RewardService:giveCompletionRewards()
  → _G.CompleteLevel(player, estrellas, puntos)
  → calcula: tiempo = os.time() - LevelStartTime
  → calcula: errores = player:GetAttribute("NivelErrores")
  → calcula: aciertos = numConexiones (del gameState)
  → LevelCompletedEvent:FireClient(player, { nivelID, puntos, estrellas, tiempo, errores, aciertos })
  ✗ NO dispara OpenMenu (se elimina esa línea)
  ✗ NO llama AudioService:playVictoryMusic() (el cliente lo maneja)

[CLIENTE — AudioClient]
  ← recibe LevelCompletedEvent con stats
  → guarda las stats localmente
  → detenerAmbiente() con fade out (0.5s)
  → reproducirFanfare(nivelID):
      - busca Audio/Victoria/Fanfare en ReplicatedStorage
      - :Play()
      - espera a que termine (Sound.Ended o TimeLength + pequeño delay)
      - cuando termina → callback a VictoryScreenManager

[CLIENTE — VictoryScreenManager]
  ← recibe callback de AudioClient con stats
  → AudioClient:reproducirTemaVictoria(nivelID)  ← suena mientras el jugador ve resultados
  → poblar UI con stats:
      Tiempo    → formatear en "M:SS"
      Aciertos  → número directo
      Errores   → número directo
      Puntaje   → número con separador de miles
      Estrellas → 1–3 ImageLabels de estrella llena/vacía
  → PantallaVictoria.Visible = true + fade in

[CLIENTE — Interacción del jugador]
  OPCIÓN A: click "Repetir"
    → VictoryScreenManager:ocultar()
    → ResetNivelEvent:FireServer()
    → AudioClient:iniciarAmbiente(nivelID)  ← vuelve el ambiente

  OPCIÓN B: click "Continuar"
    → VictoryScreenManager:ocultar()
    → AudioClient:detenerTodo()
    → OpenMenu:Fire()  ← MenuCameraSystem toma el control
```

---

## 9. Bug crítico a eliminar antes de implementar

**Archivo**: `ServerScriptService/Gameplay/GameplayEvents.server.lua`
**Líneas**: 224–246

```lua
-- BLOQUE A ELIMINAR COMPLETAMENTE:
local LevelCompletedEvent = Remotes:FindFirstChild("LevelCompleted")

if LevelCompletedEvent then
    LevelCompletedEvent.OnServerEvent:Connect(function(player, nivelID, estrellas, puntos)
        print("🏆 " .. player.Name .. " completó Nivel " .. nivelID)
        if RewardService then RewardService:giveCompletionRewards(player, nivelID) end  -- doble recompensa
        if UIService then UIService:notifyLevelComplete() end
        if AudioService then AudioService:playVictoryMusic() end  -- no funciona en server

        if LevelCompletedEvent then
            LevelCompletedEvent:FireClient(player, nivelID, estrellas, puntos)
        end

        local OpenMenuEvent = Bindables:FindFirstChild("OpenMenu")
        if OpenMenuEvent then
            OpenMenuEvent:Fire()  -- ← ABRE EL MENÚ SIN QUE EL JUGADOR LO PIDA
        end
    end)
end
```

**Por qué eliminarlo**:
- `MissionService` ya es el único responsable de detectar la victoria y disparar `LevelCompletedEvent:FireClient`. No hay razón para que el cliente dispare de vuelta al servidor.
- Este bloque causaba doble recompensa (US-06 del Sprint 1).
- El `OpenMenu:Fire()` automático impide que aparezca cualquier pantalla de resultados.

---

## 10. Cambios en archivos existentes

| Archivo | Cambio |
|---------|--------|
| `GameplayEvents.server.lua` | Eliminar bloque `LevelCompletedEvent.OnServerEvent` completo (líneas 224–246) |
| `MissionService.lua` | Ampliar payload de `LevelCompletedEvent:FireClient` con stats (tiempo, errores, aciertos). Leer `LevelStartTime` y `NivelErrores` del player |
| `LevelService.lua` | En `loadLevel()`: `player:SetAttribute("LevelStartTime", os.time())` y `player:SetAttribute("NivelErrores", 0)` |
| `ConectarCables.server.lua` | Cuando se rechaza una conexión por adyacencia o presupuesto: `player:SetAttribute("NivelErrores", (player:GetAttribute("NivelErrores") or 0) + 1)` |
| `GUIExplorador.lua` | Inicializar `AudioClient` y `VictoryScreenManager` |
| `EventManager.lua` | Pasar el evento `LevelCompletedEvent` a `AudioClient` (o que AudioClient lo escuche directamente) |
| `AudioService.lua` (servidor) | Eliminar `fadeInSound` / `fadeOutSound` (código muerto). Conservar SFX de cable |
| `LevelsConfig.lua` | Agregar campo `Audio = {}` a los niveles 0, 2, 3 y 4 |

---

## 11. Lista de tareas de implementación

### Fase 0 — Preparación en Roblox Studio (sin código)
- [ ] Crear carpeta `Ambiente/` dentro de `ReplicatedStorage/Audio/`
- [ ] Crear carpeta `Victoria/` dentro de `ReplicatedStorage/Audio/`
- [ ] Crear `Sound` objects: `Nivel0`, `Nivel2`, `Nivel3`, `Nivel4` en `Ambiente/`
- [ ] Crear `Sound` objects: `Fanfare`, `Tema` en `Victoria/`
- [ ] Asignar `SoundId` reales a todos los `Sound` objects (en Studio)
- [ ] Crear `Frame` `PantallaVictoria` dentro de `GUIExplorador` ScreenGui (con todos sus hijos descritos en §7.2)

### Fase 1 — Bug fix crítico (servidor)
- [ ] Eliminar bloque `LevelCompletedEvent.OnServerEvent` de `GameplayEvents.server.lua`

### Fase 2 — Seguimiento de estadísticas (servidor)
- [ ] `LevelService.loadLevel()`: agregar `LevelStartTime` y `NivelErrores` en player attributes
- [ ] `LevelService.resetLevel()`: resetear `NivelErrores = 0` y `LevelStartTime = os.time()`
- [ ] `ConectarCables.server.lua`: incrementar `NivelErrores` en rechazos
- [ ] `MissionService.checkVictoryCondition()`: ampliar payload de `FireClient` con `{ tiempo, errores, aciertos, puntos, estrellas, nivelID }`

### Fase 3 — LevelsConfig
- [ ] Agregar campo `Audio` a los 4 niveles en `LevelsConfig.lua`

### Fase 4 — AudioClient (cliente, nuevo archivo)
- [ ] Crear `AudioClient.lua` con `initialize`, `iniciarAmbiente`, `detenerAmbiente`, `reproducirFanfare`, `reproducirTemaVictoria`, `detenerTodo`
- [ ] Conectar a `CurrentLevelID` attribute
- [ ] Conectar a `LevelCompletedEvent`

### Fase 5 — VictoryScreenManager (cliente, nuevo archivo)
- [ ] Crear `VictoryScreenManager.lua` con `initialize`, `mostrar(stats)`, `ocultar()`
- [ ] Conectar botón "Repetir": ocultar pantalla + `ResetNivelEvent:FireServer()`
- [ ] Conectar botón "Continuar": ocultar pantalla + `AudioClient:detenerTodo()` + `OpenMenu:Fire()`

### Fase 6 — Integración en GUIExplorador.lua
- [ ] `require` y `initialize` de `AudioClient`
- [ ] `require` y `initialize` de `VictoryScreenManager`
- [ ] Pasar `VictoryScreenManager` como dependencia a `AudioClient` (para el callback de Fanfare)

### Fase 7 — Limpieza de AudioService (servidor)
- [ ] Eliminar `fadeInSound` y `fadeOutSound` de `AudioService.lua`
- [ ] Eliminar la llamada a `AudioService:playVictoryMusic()` de `MissionService.lua`

### Fase 8 — QA
- [ ] Completar Nivel 0 → Fanfare suena → Pantalla de victoria aparece con datos correctos
- [ ] Click "Repetir" → Nivel se resetea → Ambiente vuelve → Pantalla desaparece
- [ ] Click "Continuar" → Fade → Selector de Niveles → GUIExplorador oculta
- [ ] Tiempo formateado correctamente (M:SS)
- [ ] Errores se incrementan solo con intentos rechazados (no con desconexiones manuales)
- [ ] Aciertos coincide con el número de cables colocados al momento de victoria
