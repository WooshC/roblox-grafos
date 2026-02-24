# roblox-grafos — Análisis Completo de Deuda Técnica

> **Propósito**: Extiende el `REFACTORING.md` existente con todos los problemas adicionales detectados en el análisis profundo del código. Se organiza por severidad e incluye la estructura de carpetas recomendada.

---

## Tabla de contenido

1. [Resumen ejecutivo](#1-resumen-ejecutivo)
2. [Bugs críticos P0](#2-bugs-críticos-p0)
3. [Problemas de alta severidad P1](#3-problemas-de-alta-severidad-p1)
4. [Problemas de severidad media P2](#4-problemas-de-severidad-media-p2)
5. [Duplicaciones adicionales](#5-duplicaciones-adicionales-no-documentadas)
6. [Estructura de carpetas recomendada](#6-estructura-de-carpetas-recomendada)
7. [Tabla maestra de cambios](#7-tabla-maestra-de-cambios)
8. [Orden de implementación](#8-orden-de-implementación)
9. [Tests post-refactorización](#9-tests-post-refactorización)

---

## 1. Resumen ejecutivo

| Categoría | Cantidad |
|---|---|
| Bugs críticos nuevos (P0) | 3 |
| Problemas altos nuevos (P1) | 8 |
| Problemas medios nuevos (P2) | 11 |
| Duplicaciones adicionales (además de las 9 del REFACTORING.md) | 6 |

Los problemas del `REFACTORING.md` original **no se repiten aquí** — este documento los complementa. Léelos en conjunto.

---

## 2. Bugs Críticos (P0)

### 2.1 Bug original del REFACTORING.md — Matriz simétrica en dígrafos

Ya documentado. Ver sección 1 del `REFACTORING.md` para el plan de corrección completo.

---

### 2.2 `fallos` usada sin declarar en `VisualizadorAlgoritmos`

**Archivo**: `ServerScriptService/Gameplay/VisualizadorAlgoritmos.server.lua`

```lua
-- ACTUAL — `fallos` nunca fue declarada ni asignada
return {Aciertos = aciertos, Fallos = fallos, Bonus = puntosNetos}
```

En `validarRutaJugador()` se calculan `cablesFaltantes` y `cablesExtra`, pero la tabla de retorno referencia `fallos` que no existe. En Lua, leer una variable local no declarada retorna `nil` silenciosamente, así que el error no explota —simplemente el retorno de la función siempre lleva `Fallos = nil`. Como el llamador ignora el retorno, el bug queda oculto indefinidamente.

**Corrección**:
```lua
return {Aciertos = aciertos, Fallos = cablesFaltantes, Bonus = puntosNetos}
```

---

### 2.3 `task.wait(1)` como mecanismo de espera de servicios

**Archivos**: `ConectarCables.server.lua`, `GameplayEvents.server.lua`, `VisualizadorAlgoritmos.server.lua`, `SistemaUI_reinicio.server.lua`

Todos estos scripts hacen `task.wait(1)` y luego acceden a `_G.Services.X`. Si `Init.server.lua` tarda más de 1 segundo (DataStore lento, carga pesada), los scripts leen `nil` y fallan silenciosamente. No hay retry ni manejo de error robusto.

**Corrección** — crear un `BindableEvent` en `Init.server.lua` que se dispare cuando todos los servicios estén listos:

```lua
-- Al final de Init.server.lua
local ServicesReady = Instance.new("BindableEvent")
ServicesReady.Name = "ServicesReady"
ServicesReady.Parent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Bindables")
ServicesReady:Fire()

-- En cada script dependiente, reemplazar task.wait(1) por:
ReplicatedStorage
  :WaitForChild("Events")
  :WaitForChild("Bindables")
  :WaitForChild("ServicesReady").Event:Wait()
```

---

### 2.4 Doble listener de `RequestPlayLevel` — condición de carrera

**Archivos**: `ServerScriptService/Init.server.lua` (líneas ~126–132) y `ServerScriptService/Base_Datos/ManagerData.lua`

Ambos scripts conectan `RequestPlayEvent.OnServerEvent`. Cuando el cliente dispara `RequestPlayLevel`, los dos handlers corren:

- `ManagerData.lua` — teletransporta al jugador, resetea dinero y atributos.
- `Init.server.lua` — llama `LevelService:loadLevel()` que también modifica atributos.

El orden de ejecución no está garantizado → condición de carrera al iniciar un nivel.

**Corrección**: Eliminar el listener duplicado de `Init.server.lua`. `ManagerData.lua` ya llama a `setupLevelForPlayer` que internamente llama a `LevelService:loadLevel()`.

---

## 3. Problemas de Alta Severidad (P1)

### 3.1 `RunService.RenderStepped` usado en el servidor

**Archivo**: `ServerScriptService/Services/AudioService.lua` — funciones `fadeInSound` y `fadeOutSound`

```lua
connection = game:GetService("RunService").RenderStepped:Connect(function()
    -- Este callback NUNCA se ejecuta en el servidor
end)
```

`RenderStepped` es un evento del cliente que ocurre entre frames de render. En un `Script` de servidor, **nunca dispara**. Los fades de audio en el servidor son no-operativos de forma silenciosa.

**Corrección**: Reemplazar por `RunService.Heartbeat` si el fade ocurre en el servidor, o mover toda la lógica de fade al cliente donde tiene sentido.

---

### 3.2 `canConnect()` en `LevelService` solo valida `A → B`, no `B → A`

**Archivo**: `ServerScriptService/Services/LevelService.lua`

```lua
function LevelService:canConnect(nodoA, nodoB)
    local adyacentes = levelConfig.Adyacencias[nombreA]
    if not adyacentes then return false end  -- ← falla si solo existe Adyacencias[B]
    for _, nombre in pairs(adyacentes) do
        if nombre == nombreB then return true end
    end
    return false
end
```

Si la conexión es válida solo en sentido `B → A` (Adyacencias[B] contiene A pero Adyacencias[A] no contiene B), `canConnect(posteA, posteB)` retorna `false` bloqueando una conexión legítima. Afecta directamente a los grafos dirigidos de la Zona 3.

**Corrección**:
```lua
function LevelService:canConnect(nodoA, nodoB)
    if not levelConfig or not levelConfig.Adyacencias then return true end
    local ady = levelConfig.Adyacencias
    local aToB = ady[nombreA] and table.find(ady[nombreA], nombreB)
    local bToA = ady[nombreB] and table.find(ady[nombreB], nombreA)
    return aToB ~= nil or bToA ~= nil  -- el cable físico puede existir en cualquier dirección
end
```

---

### 3.3 `AlgorithmService` tiene implementaciones duplicadas e incompatibles con `GraphUtils`

**Archivo**: `ServerScriptService/Services/AlgorithmService.lua`

Hay tres implementaciones paralelas de los mismos algoritmos con diferencias sutiles:

| Módulo | Dijkstra | BFS |
|---|---|---|
| `Algoritmos.lua` | Peso = 1 fijo | Calcula distancia física desde Workspace |
| `GraphUtils.lua` | Pesos desde `Connections` folder | No calcula distancia física |
| `AlgorithmService.lua` | Llama `GraphUtils.dijkstra()` con firma incorrecta | Llama `Algoritmos.BFSVisual()` |

**Corrección**: Una sola implementación en `GraphUtils.lua`. `Algoritmos.lua` se convierte en un módulo de visualización que delega en `GraphUtils` internamente.

---

### 3.4 `AlgorithmService` llama a `GraphUtils.dijkstra()` pasando `Instance` en lugar de `string`

**Archivo**: `ServerScriptService/Services/AlgorithmService.lua`

```lua
function AlgorithmService:getOptimalPath(startNode, endNode, algoritmo)
    -- startNode es una Instance, pero GraphUtils.dijkstra espera un string (nombre)
    local distancias = GraphUtils.dijkstra(startNode, graphService:getCables())
end
```

`GraphUtils.dijkstra(startName, cables)` espera un `string`. Al pasarle una `Instance`, `dist[startName]` nunca se inicializa como `0` y el resultado es siempre una tabla vacía. `reconstructPath` tampoco reconstruye el camino real — siempre retorna `{startNode.Name, endNode.Name}`.

**Corrección**:
```lua
local distancias, prev = GraphUtils.dijkstra(startNode.Name, graphService:getCables())
-- Implementar reconstructPath usando la tabla prev real
```

---

### 3.5 `EnergyService.findCriticalNodes()` — `#` en tabla con claves string siempre retorna 0

**Archivo**: `ServerScriptService/Services/EnergyService.lua`

```lua
local visitedWithout = GraphUtils.bfs(sourceNode, tempCables)
local visitedWith    = GraphUtils.bfs(sourceNode, cables)

if #visitedWithout < #visitedWith then   -- ← siempre false
    table.insert(critical, node)
end
```

`GraphUtils.bfs()` retorna `{ [nodeName] = true }` — una tabla con claves string, no un array. El operador `#` sobre tablas con claves string **siempre retorna 0** en Lua. La función nunca detecta nodos críticos.

**Corrección**:
```lua
local function countKeys(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

if countKeys(visitedWithout) < countKeys(visitedWith) then
    table.insert(critical, node)
end
```

Esta función debería vivir en el nuevo `TableUtils.lua` (ver §6).

---

### 3.6 `MissionService` accede a `_G.Services` directamente rompiendo la inyección de dependencias

**Archivo**: `ServerScriptService/Services/MissionService.lua`

```lua
function MissionService:checkVictoryCondition(player)
    -- MissionService tiene setDependencies(), pero esto lo rompe:
    local RewardService = _G.Services and _G.Services.Reward
    local AudioService  = _G.Services and _G.Services.Audio
    local UIService     = _G.Services and _G.Services.UI
end
```

`MissionService` recibe dependencias vía `setDependencies()`, pero para `RewardService`, `UIService` y `AudioService` accede directamente a `_G.Services`, creando un acoplamiento circular implícito. Si el orden de carga cambia, falla silenciosamente.

**Corrección**: Añadir `rewardService`, `uiService`, `audioService` a `MissionService:setDependencies()` e inyectarlos desde `Init.server.lua`.

---

### 3.7 `VisualizadorAlgoritmos` bloquea con `WaitForChild` en el top-level

**Archivo**: `ServerScriptService/Gameplay/VisualizadorAlgoritmos.server.lua`

```lua
-- Esta línea está en el top-level del script, fuera de funciones:
local restaurarEvent = bindables:WaitForChild("RestaurarObjetos")
```

Si `RestaurarObjetos` aún no fue creado cuando este script arranca (carrera con `GestorEventos.server.lua`), el script se bloquea indefinidamente. El fix de `ServicesReady` de §2.3 resuelve esto, pero también es necesario crear todos los `BindableEvent`s en `Init.server.lua` antes de que arranquen los demás scripts.

---

### 3.8 `GestorEventos.server.lua` usa polling activo para esperar servicios

**Archivo**: `ServerScriptService/GestorEventos.server.lua`

```lua
local function waitForService(serviceName)
    while not _G.Services or not _G.Services[serviceName] do
        task.wait(0.5)   -- ← polling cada 500ms indefinidamente
        attempts = attempts + 1
    end
end
```

Este patrón bloquea el hilo del script en un loop. Con el mecanismo `ServicesReady` propuesto en §2.3 esto desaparece completamente.

---

## 4. Problemas de Severidad Media (P2)

### 4.1 `GraphUtils.getDistance()` no existe pero es llamada en 2 archivos

**Archivos**: `ServerScriptService/Services/AlgorithmService.lua`, y como función local sin exportar en `GraphTheoryService.server.lua`

```lua
-- AlgorithmService.lua — produce error en runtime:
totalCost = totalCost + GraphUtils.getDistance(nodeA, nodeB)
```

`GraphUtils.lua` no define ninguna función `getDistance()`. `calcularDistancia()` existe localmente en `GraphTheoryService` pero nunca fue exportada.

**Corrección**: Añadir a `GraphUtils.lua`:
```lua
function GraphUtils.getDistance(nodeA, nodeB)
    if not nodeA or not nodeB then return 0 end
    local posA = nodeA:IsA("Model") and (nodeA.PrimaryPart and nodeA.PrimaryPart.Position or nodeA:GetPivot().Position) or nodeA.Position
    local posB = nodeB:IsA("Model") and (nodeB.PrimaryPart and nodeB.PrimaryPart.Position or nodeB:GetPivot().Position) or nodeB.Position
    return (posA - posB).Magnitude
end
```

---

### 4.2 `RewardService.giveCompletionRewards()` — división por cero cuando `DineroInicial = 0`

**Archivo**: `ServerScriptService/Services/RewardService.lua`

```lua
local moneyReward = self:giveMoneyForLevel(
    player, nivelID,
    (1 - presupuestoUsado / config.DineroInicial)  -- ← 0/0 = nan en el Nivel 0
)
```

El Nivel 0 (Tutorial) tiene `DineroInicial = 0`. Esto produce `nan` que se propaga a toda la cadena de recompensas.

**Corrección**:
```lua
local completionRatio = config.DineroInicial > 0
    and (1 - presupuestoUsado / config.DineroInicial)
    or 1.0
```

---

### 4.3 `ManagerData.lua` llama funciones inexistentes de `NivelUtils`

**Archivo**: `ServerScriptService/Base_Datos/ManagerData.lua`

```lua
if NivelUtils and NivelUtils.obtenerModeloNivel then
    nivelModel = NivelUtils.obtenerModeloNivel(levelId)   -- No existe
end
-- ...
if NivelUtils and NivelUtils.obtenerPosicionSpawn then
    targetPosition = NivelUtils.obtenerPosicionSpawn(levelId)   -- No existe
end
```

`NivelUtils.lua` no define `obtenerModeloNivel` ni `obtenerPosicionSpawn`. Las condiciones siempre son falsas, el código cae al fallback y estos TODOs implícitos nunca se resuelven.

---

### 4.4 `ControladorEscenario.server.lua` usa `wait()` legado

**Archivo**: `ServerScriptService/ControladorEscenario.server.lua`

```lua
wait(2)  -- API legada de Roblox
```

Desde 2022 Roblox recomienda `task.wait()`. La función `wait()` puede acumularse y producir delays mayores a los esperados bajo carga del servidor.

**Corrección**: Reemplazar por `task.wait(2)`.

---

### 4.5 `Algoritmos.lua` busca nodos directamente en `Workspace` con ruta hardcodeada

**Archivo**: `ReplicatedStorage/Algoritmos.lua`

```lua
local function getPos(nombre)
    local nivelName = (nivelID == 0) and "Nivel0_Tutorial" or ("Nivel" .. nivelID)
    local modelo = workspace:FindFirstChild(nivelName)  -- ← ignora "NivelActual"
    -- ...
end
```

Este módulo vive en `ReplicatedStorage` pero accede a `Workspace` con nombres hardcodeados. `LevelService` renombra el nivel a `NivelActual`, así que la búsqueda falla y todas las distancias físicas de BFS retornan `0`.

---

### 4.6 `MissionService.buildFullGameState()` hace `require()` dentro de una función frecuente

**Archivo**: `ServerScriptService/Services/MissionService.lua`

```lua
function MissionService:buildFullGameState(player)
    -- Esta línea está DENTRO de la función, llamada en cada cambio de conexión:
    local GraphUtils = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"):WaitForChild("GraphUtils"))
end
```

Aunque `require()` cachea el módulo, el `WaitForChild` encadenado tiene overhead en cada llamada. Debe moverse al top-level del módulo junto a las otras dependencias.

---

### 4.7 `AudioService` — memory leak potencial en `fadeIn/Out`

**Archivo**: `ServerScriptService/Services/AudioService.lua`

Las funciones `fadeInSound` y `fadeOutSound` crean conexiones a `RunService` en variables locales. Si el `Sound` es destruido por `Debris:AddItem` antes de que el fade termine, la conexión permanece activa referenciando un objeto destruido hasta que `progress >= 1`. Con muchos sonidos, esto acumula conexiones huérfanas.

**Corrección**:
```lua
local sound_ref = sound  -- captura débil
connection = RunService.Heartbeat:Connect(function()
    if not sound_ref or not sound_ref.Parent then
        connection:Disconnect()
        return
    end
    -- ... lógica de fade
end)
```

---

### 4.8 `LevelService.getCables()` expone la tabla interna sin copia

**Archivo**: `ServerScriptService/Services/LevelService.lua`

```lua
function LevelService:getCables()
    if graphService then return graphService:getCables() end
    return {}
end
```

`graphService:getCables()` retorna la referencia directa a la tabla interna `cables`. Cualquier consumidor de `LevelService:getCables()` puede mutar la tabla accidentalmente. No es un bug activo pero es una superficie de error futura.

---

### 4.9 `ManagerData.lua` — `require(NivelUtils)` en top-level sin `pcall`

**Archivo**: `ServerScriptService/Base_Datos/ManagerData.lua`

```lua
local NivelUtils = require(ReplicatedStorage:WaitForChild("Utilidades"):WaitForChild("NivelUtils"))
```

Si `NivelUtils.lua` tiene un error de sintaxis o de carga, `ManagerData` completo falla y los jugadores no pueden conectarse ni guardar datos. Un error en un módulo auxiliar no debería tumbar la persistencia de datos.

**Corrección**:
```lua
local ok, NivelUtils = pcall(require, ReplicatedStorage:WaitForChild("Utilidades"):WaitForChild("NivelUtils"))
if not ok then
    warn("⚠️ ManagerData: NivelUtils no cargó correctamente, usando fallbacks")
    NivelUtils = nil
end
```

---

### 4.10 `RewardService.validateAndUnlockAchievements()` — `progress.dineroRestante` no existe

**Archivo**: `ServerScriptService/Services/RewardService.lua`

```lua
local progress = levelService:getLevelProgress()
-- progress nunca incluye dineroRestante, el campo no existe en getLevelProgress()
local gastado = presupuesto - progress.dineroRestante
```

`LevelService:getLevelProgress()` retorna `{ nodesConnected, totalNodes, cablesPlaced, energized, completed }`. No incluye `dineroRestante`. El código cae al fallback manual, pero el comentario `-- Nota: progress debería tener dineroRestante` indica que esto es un TODO sin resolver.

---

### 4.11 `VisualizadorAlgoritmos` no usa `LevelService` ni `GraphUtils` para buscar postes

**Archivo**: `ServerScriptService/Gameplay/VisualizadorAlgoritmos.server.lua`

La función local `obtenerCarpetaPostes()` tiene 30 líneas de lógica propia que reinventa lo que ya hace `GraphUtils.getPostesFolder()`. Fue escrita antes de la arquitectura de servicios y nunca migrada.

**Corrección**: Reemplazar por:
```lua
local function obtenerCarpetaPostes()
    local nivel = (_G.Services and _G.Services.Level) and _G.Services.Level:getCurrentLevel()
    return nivel and GraphUtils.getPostesFolder(nivel)
end
```

---

## 5. Duplicaciones Adicionales no Documentadas

Las siguientes duplicaciones complementan las 9 ya listadas en el `REFACTORING.md` original.

### 5.1 `NivelUtils.getNodeAlias()` duplica `AliasUtils.getNodeAlias()`

`NivelUtils.lua` (línea ~41) implementa exactamente la misma lógica `Nodos[name].Alias → NombresPostes → fallback` que `AliasUtils.lua`. Es la duplicación más directa: mismo algoritmo, mismo fallback, misma firma.

### 5.2 `calcularDistancia()` definida localmente en 3 archivos sin exportar

La misma función aparece en:
- `GraphTheoryService.server.lua` — como función local `calcularDistancia(nodeA, nodeB)`
- `AlgorithmService.lua` — llamada como `GraphUtils.getDistance()` (no existe)
- `Algoritmos.lua` — cálculo inline en `getPos()`

Ninguno la exporta. `GraphUtils.getDistance()` es la solución (ver §4.1).

### 5.3 Constante `4 studs = 1 metro` hardcodeada en 4 archivos

```lua
-- ConectarCables.server.lua:
local distanciaMetros = math.floor(distanciaStuds / 4)

-- GraphTheoryService.server.lua:
matrix[i][j] = math.floor(distStuds / 4)

-- Algoritmos.lua:
local distanciaMetros = math.floor(distanciaTotal / 4)

-- AlgorithmService.lua:
return math.floor(distancia / 4)
```

Si el diseño del mapa cambia la escala, hay que buscar y reemplazar en 4 archivos.

**Corrección**: Añadir a `Enums.lua`:
```lua
Enums.STUDS_PER_METER = 4
```

### 5.4 Colores de cables como strings/literales en 4 archivos

`Enums.lua` ya define colores como `Color3`, pero los cables usan `BrickColor.new()` hardcodeados en:
- `GameplayEvents.server.lua`: `BrickColor.new("Lime green")`, `"Cyan"`, `"Black"`
- `VisualizadorAlgoritmos.server.lua`: tabla `COLORES` con strings de BrickColor
- `ControladorEscenario.server.lua`: `BrickColor.new("Black")`
- `ConectarCables.server.lua`: `BrickColor.new("Black")`

**Corrección**: Añadir a `Enums.lua`:
```lua
Enums.CableColors = {
    Desconectado = BrickColor.new("Black"),
    Conectado    = BrickColor.new("Lime green"),
    Energizado   = BrickColor.new("Cyan"),
    Explorando   = BrickColor.new("Neon orange"),
    CaminoFinal  = BrickColor.new("Lime green"),
}
```

### 5.5 Búsqueda de `PostesFolder` reimplementada en 3 lugares

| Archivo | Implementación |
|---|---|
| `GraphUtils.getPostesFolder()` | Busca `Objetos/Postes` o `Postes` recursivo |
| `VisualizadorAlgoritmos` — `obtenerCarpetaPostes()` | 30 líneas de lógica propia con fallbacks por nombre de nivel |
| `LevelService.getPostes()` | Delega a `GraphUtils` pero con ruta diferente |

`VisualizadorAlgoritmos` es el outlier que debe migrarse (ver §4.11).

### 5.6 Patrón `pcall(require, modulo)` aplicado inconsistentemente

`VisualizadorAlgoritmos.server.lua` usa `pcall` al cargar `Algoritmos.lua`. El resto de scripts usan `require()` desnudo. Un error de sintaxis en cualquier módulo puede tumbar scripts críticos como `ManagerData`.

---

## 6. Estructura de Carpetas Recomendada

```
ReplicatedStorage/
├── Shared/
│   ├── Constants.lua          ← NUEVO: constantes extraídas (STUDS_PER_METER, etc.)
│   ├── Enums.lua              ← MODIFICAR: añadir CableColors (BrickColor) + STUDS_PER_METER
│   └── Utils/
│       ├── GraphUtils.lua     ← MODIFICAR: añadir getDistance(), getAdjacencyMatrix con
│       │                                   parámetro adyacencias, buildAdjList(), exportar
│       │                                   calcularDistancia
│       └── TableUtils.lua     ← NUEVO: countKeys() para tablas con claves string
├── Utilidades/
│   ├── AliasUtils.lua         ← sin cambios (módulo canónico)
│   └── NivelUtils.lua         ← ELIMINAR tras migrar todos los consumidores
├── Algoritmos.lua             ← MODIFICAR: usar GraphUtils.getDistance(), no buscar en Workspace
├── LevelsConfig.lua           ← MODIFICAR: deprecar NombresPostes
└── Economia.lua               ← sin cambios

ServerScriptService/
├── Init.server.lua            ← MODIFICAR: añadir ServicesReady BindableEvent,
│                                           crear todos los BindableEvents aquí,
│                                           eliminar listener duplicado RequestPlayLevel
├── Base_Datos/
│   └── ManagerData.lua        ← MODIFICAR: pcall en require, eliminar refs a funciones
│                                           inexistentes de NivelUtils
├── Gameplay/
│   ├── ConectarCables.server.lua       ← MODIFICAR: usar Enums.STUDS_PER_METER y CableColors
│   ├── GameplayEvents.server.lua       ← MODIFICAR: usar Enums.CableColors
│   ├── GraphTheoryService.server.lua   ← MODIFICAR: fix bug matriz dirigida,
│   │                                               eliminar safeGetNodeZone,
│   │                                               usar AliasUtils
│   ├── SistemaUI_reinicio.server.lua   ← MODIFICAR: usar ServicesReady
│   └── VisualizadorAlgoritmos.server.lua ← MODIFICAR: fix var `fallos`, usar
│                                               GraphUtils.getPostesFolder,
│                                               Heartbeat en lugar de RenderStepped,
│                                               WaitForChild bloqueante
├── GestorEventos.server.lua   ← MODIFICAR: eliminar polling, usar ServicesReady
├── ControladorEscenario.server.lua ← MODIFICAR: wait() → task.wait()
└── Services/
    ├── AlgorithmService.lua   ← MODIFICAR: fix GraphUtils.getDistance, fix firma dijkstra,
    │                                       eliminar duplicación con Algoritmos.lua,
    │                                       reconstructPath real
    ├── AudioService.lua       ← MODIFICAR: RenderStepped → Heartbeat, fix memory leak
    ├── EnergyService.lua      ← MODIFICAR: fix findCriticalNodes con countKeys
    ├── GraphService.lua       ← MODIFICAR: getConnectionCount delega a GraphUtils.degree
    ├── InventoryService.lua   ← sin cambios
    ├── LevelService.lua       ← MODIFICAR: fix canConnect bidireccional, fix getCables copia
    ├── MissionService.lua     ← MODIFICAR: inyectar RewardService/UIService/AudioService via
    │                                       setDependencies, mover require GraphUtils al top-level
    ├── RewardService.lua      ← MODIFICAR: fix división por cero DineroInicial = 0,
    │                                       fix progress.dineroRestante inexistente
    └── UIService.lua          ← sin cambios funcionales

StarterGUI/DialogStorage/
├── SharedDialogConfig.lua     ← CREAR: colores + offsets de cámara compartidos
├── ZoneDialogActivator.lua    ← CREAR: boilerplate de activación de zona
├── Zona1_dialogo.lua          ← MODIFICAR
├── Zona2_dialogo.lua          ← MODIFICAR
├── Zona3_dialogo.lua          ← MODIFICAR (verificar naranja RGB 140 vs 165)
└── Zona4_dialogo.lua          ← CREAR usando SharedDialogConfig desde el inicio

StarterPlayer/.../
└── MatrixManager.lua          ← MODIFICAR: extraer _refreshAndRestoreSelection(),
                                            usar AliasUtils, eliminar getAlias local
```

---

## 7. Tabla Maestra de Cambios

| Archivo | Acción | Prioridad | Motivo principal |
|---|---|---|---|
| `GraphUtils.lua` | Modificar | P0 / P2 | Bug matriz, añadir `getDistance`, `buildAdjList`, `countKeys` |
| `GraphTheoryService.server.lua` | Modificar | P0 / P1 | Bug matriz dirigida + `safeGetNodeZone` |
| `VisualizadorAlgoritmos.server.lua` | Modificar | P0 / P1 | Var `fallos` sin declarar, `RenderStepped`, `WaitForChild` bloqueante |
| `Init.server.lua` | Modificar | P0 / P1 | `ServicesReady` event, listener duplicado `RequestPlayLevel` |
| `LevelService.lua` | Modificar | P1 | `canConnect()` no valida `B→A`, `getCables` sin copia defensiva |
| `AudioService.lua` | Modificar | P1 | `RenderStepped` inoperativo en servidor |
| `AlgorithmService.lua` | Modificar | P1 | `getDistance` inexistente, firma dijkstra errónea, `reconstructPath` roto |
| `EnergyService.lua` | Modificar | P1 | `#` en tabla de claves string siempre retorna 0 |
| `MissionService.lua` | Modificar | P1 / P2 | `_G.Services` directo, `require` dentro de función frecuente |
| `GestorEventos.server.lua` | Modificar | P1 | Polling activo → `ServicesReady` |
| `RewardService.lua` | Modificar | P2 | División por cero `DineroInicial = 0`, `progress.dineroRestante` inexistente |
| `ManagerData.lua` | Modificar | P2 | Funciones inexistentes de `NivelUtils`, `require` sin `pcall` |
| `MatrixManager.lua` | Modificar | P2 | Bloque refresco duplicado, `getAlias` local |
| `GraphService.lua` | Modificar | P2 | `getConnectionCount` duplica `GraphUtils.degree` |
| `ControladorEscenario.server.lua` | Modificar | P2 | `wait()` legado → `task.wait()` |
| `Algoritmos.lua` | Modificar | P2 | Workspace hardcodeado, mismos algoritmos que `GraphUtils` |
| `LevelsConfig.lua` | Modificar | P2 | Deprecar `NombresPostes` |
| `Enums.lua` | Modificar | P2 | Añadir `STUDS_PER_METER` y `CableColors` (BrickColor) |
| `TableUtils.lua` | **Crear** | P1 | `countKeys()` para tablas con claves string |
| `SharedDialogConfig.lua` | **Crear** | P2 | Colores + cámara compartidos entre Zona_dialogo |
| `ZoneDialogActivator.lua` | **Crear** | P2 | Boilerplate activación de zona |
| `NivelUtils.lua` | **Eliminar** | P2 | Supersedido por `AliasUtils` + `LevelService` |

---

## 8. Orden de Implementación

El orden respeta las dependencias y minimiza el riesgo de regresiones.

### Fase 1 — Bugs críticos (implementar primero)

1. Fix §2.2: Declarar `fallos = cablesFaltantes` en `VisualizadorAlgoritmos`
2. Fix §2.3: Crear `ServicesReady` `BindableEvent` en `Init` + reemplazar `task.wait(1)` en todos los scripts dependientes
3. Fix §2.4: Eliminar listener duplicado `RequestPlayLevel` de `Init.server.lua`
4. Fix §2.1 (REFACTORING.md original): Bug matriz adyacencia en `GraphTheoryService` + `GraphUtils`

### Fase 2 — Bugs funcionales de servicios

5. Fix §4.1: Exportar `GraphUtils.getDistance()`
6. Fix §3.1: `AudioService` `RenderStepped` → `Heartbeat`
7. Fix §3.2: `LevelService.canConnect()` validar `B→A`
8. Fix §3.4: `AlgorithmService.dijkstra` usar `.Name`, `reconstructPath` real
9. Fix §3.5: `EnergyService.findCriticalNodes` — crear `TableUtils.lua` con `countKeys`
10. Fix §4.2: `RewardService` división por cero

### Fase 3 — Arquitectura y dependencias

11. Crear `TableUtils.lua`
12. Centralizar `STUDS_PER_METER` y `CableColors` en `Enums.lua`
13. Migrar `MissionService` a inyección completa de dependencias (§3.6)
14. Centralizar búsqueda de `PostesFolder` — `VisualizadorAlgoritmos` usa `GraphUtils.getPostesFolder`
15. Fix §4.9: `ManagerData.lua` — `pcall` en `require(NivelUtils)`

### Fase 4 — Deduplicación y limpieza

16. Eliminar `NivelUtils.lua` (migrar consumidores a `AliasUtils`)
17. `MatrixManager`: extraer `_refreshAndRestoreSelection()` + usar `AliasUtils`
18. `GraphService.getConnectionCount` → delegar a `GraphUtils.degree`
19. `Algoritmos.lua`: delegar en `GraphUtils` internamente
20. Crear `SharedDialogConfig.lua` + `ZoneDialogActivator.lua`
21. Deprecar `NombresPostes` en `LevelsConfig.lua`

---

## 9. Tests Post-Refactorización

- **Zona 1**: Verificar que la matriz sigue siendo simétrica tras el fix del bug P0.
- **Zona 3**: Verificar que `M[X][Y] ≠ 0` y `M[Y][X] = 0` en grafos dirigidos.
- **Tutorial (Nivel 0)**: Verificar que `RewardService` no produce `NaN` al completar.
- **Algoritmos**: Ejecutar BFS y Dijkstra → verificar que la animación completa sin errores en el Output de Studio.
- **ServicesReady**: Verificar en Studio que el evento se dispara antes de que cualquier script dependiente lea `_G.Services`.
- **`findCriticalNodes`**: Crear manualmente un nodo puente entre dos grupos y verificar que aparece en la lista retornada.
- **`AlgorithmService.executeDijkstra`**: Verificar que el camino reconstruido contiene los nodos intermedios, no solo `{inicio, fin}`.
- **`canConnect` bidireccional**: En la Zona 3 intentar crear una arista en el sentido correcto → debe aceptarse. En el sentido inverso → debe rechazarse.

---

> **Nota sobre `Zona4_dialogo.lua`**: No existe aún. Al crearlo, usar `SharedDialogConfig` y `ZoneDialogActivator` desde el inicio para no reintroducir la deuda documentada en el `REFACTORING.md` original.
