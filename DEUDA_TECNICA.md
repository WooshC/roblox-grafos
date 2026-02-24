# roblox-grafos — Deuda Técnica Unificada

> **Propósito**: Documento único que unifica `REFACTORING.md` y `roblox-grafos-deuda-tecnica.md`, incorpora todos los nuevos problemas encontrados en análisis profundo de código, y define prioridades de sprint.
>
> **Estado**: Los archivos anteriores (`REFACTORING.md` y `roblox-grafos-deuda-tecnica.md`) quedan obsoletos. Este es el documento de referencia.

---

## Tabla de contenido

1. [Sprint actual — Matriz dirigida/no dirigida](#1-sprint-actual--corrección-de-la-matriz-de-adyacencia)
2. [Backlog — Bugs críticos P0](#2-bugs-críticos-p0--backlog)
3. [Backlog — Alta severidad P1](#3-problemas-de-alta-severidad-p1--backlog)
4. [Backlog — Severidad media P2](#4-problemas-de-severidad-media-p2--backlog)
5. [Duplicaciones de código](#5-duplicaciones-de-código)
6. [Antipatrones de arquitectura](#6-antipatrones-de-arquitectura)
7. [Estructura de carpetas recomendada](#7-estructura-de-carpetas-recomendada)
8. [Tabla maestra de cambios](#8-tabla-maestra-de-cambios)
9. [Orden de implementación global](#9-orden-de-implementación-global)
10. [Tests post-refactorización](#10-tests-post-refactorización)

---

## 1. Sprint actual — Corrección de la matriz de adyacencia

> **Objetivo del sprint**: Hacer que la matriz de adyacencia distinga correctamente grafos dirigidos (Zona 3) de grafos no dirigidos (Zonas 1 y 2). Todo lo demás va a backlog.

### Síntoma

En la Zona 3 (Grafos Dirigidos), la matriz muestra `1` en ambas celdas `A[i][j]` y `A[j][i]` aunque la arista sea unidireccional (`X → Y` pero no `Y → X`). La matriz siempre aparece simétrica.

### Causa raíz — tres focos encadenados

#### Foco 1 — `GraphUtils.lua : getCableKey()`

```lua
-- ACTUAL (ordena alfabéticamente → trata todo como no-dirigido)
if nameA < nameB then
    return nameA .. "_" .. nameB
else
    return nameB .. "_" .. nameA
end
```

La clave aplana la dirección. La clave simétrica es correcta para **almacenar** el cable físico (objeto único), pero **no** para consultar si una arista dirigida va en un sentido concreto.

#### Foco 2 — `GraphUtils.lua : getAdjacencyMatrix()`

```lua
-- ACTUAL (siempre pone 1 en ambas direcciones)
matrix[idxA][idxB] = 1
matrix[idxB][idxA] = 1
```

Sin importar la dirección de la arista, rellena ambas celdas.

#### Foco 3 — `GraphTheoryService.server.lua : getAdjacencyMatrix()`

```lua
-- ACTUAL (delega en areConnected, que tampoco sabe de dirección)
if GraphUtils.areConnected(nodeA, nodeB, cables) then
    matrix[i][j] = peso   -- y también matrix[j][i] = peso
```

### Información disponible

`LevelsConfig[zonaID].Adyacencias` ya codifica la direccionalidad:

```lua
-- Zona 3: cadena X → Y → Z
["Nodo1_z3"] = {"Nodo2_z3"},
["Nodo2_z3"] = {"Nodo3_z3"},
["Nodo3_z3"] = {},
```

Regla de llenado:

| `Ady[A]` contiene B | `Ady[B]` contiene A | Interpretación | Celdas a rellenar |
|---|---|---|---|
| ✅ | ✅ | Bidireccional | `M[A][B]` y `M[B][A]` |
| ✅ | ❌ | Dirigido A → B | Solo `M[A][B]` |
| ❌ | ✅ | Dirigido B → A | Solo `M[B][A]` |
| ❌ | ❌ | Sin adyacencias definidas | Ambas celdas (fallback) |

### Plan de corrección (3 pasos)

**Paso 1 — `GraphTheoryService.server.lua`**

Obtener `config.Adyacencias` desde `LevelService:getLevelConfig()` y pasarlo al constructor de la matriz. Al iterar cables:

```
Para cada cable (nodeA ↔ nodeB):
  puedeIr_AB = Adyacencias[A.Name] contiene B.Name
  puedeIr_BA = Adyacencias[B.Name] contiene A.Name

  si puedeIr_AB  → matrix[idx_A][idx_B] = peso
  si puedeIr_BA  → matrix[idx_B][idx_A] = peso
  si ninguno definido → ambas celdas = peso  (fallback)
```

**Paso 2 — `GraphUtils.lua : getAdjacencyMatrix()`**

Añadir parámetro opcional `adyacencias`. Si se provee, usar la lógica del Paso 1. Si no (uso genérico), mantener comportamiento bidireccional actual.

```lua
function GraphUtils.getAdjacencyMatrix(nodes, cables, adyacencias)
    -- ...
    for _, info in pairs(cables) do
        local nA, nB = info.nodeA.Name, info.nodeB.Name
        local ady = adyacencias or {}
        local aToB = ady[nA] and table.find(ady[nA], nB)
        local bToA = ady[nB] and table.find(ady[nB], nA)
        local fallback = not adyacencias or (not aToB and not bToA)
        if aToB or fallback then matrix[idxA][idxB] = 1 end
        if bToA or fallback then matrix[idxB][idxA] = 1 end
    end
end
```

**Paso 3 — verificar `MatrixManager.lua : calcularGrados()`**

La función ya detecta dígrafos comparando `matrix[r][c]` con `matrix[c][r]`. Una vez que el servidor envíe la matriz asimétrica correcta, la detección funciona sin cambios. Verificar que `gTotal = esDigrafo and (gEntrada + gSalida) or gEntrada` es correcto (ya está bien implementado).

### Tests del sprint

- **Zona 1 / 2**: La matriz sigue siendo simétrica.
- **Zona 3**: `M[X][Y] = peso` pero `M[Y][X] = 0` cuando solo existe `X→Y`.
- **MatrixManager**: Los grados de entrada/salida en un dígrafo son correctos y distintos.

---

## 2. Bugs Críticos (P0) — Backlog

### P0-1 — Variable `fallos` usada sin declarar en `VisualizadorAlgoritmos`

**Archivo**: `ServerScriptService/Gameplay/VisualizadorAlgoritmos.server.lua` línea 391

```lua
-- ACTUAL — fallos nunca fue declarada
return {Aciertos = aciertos, Fallos = fallos, Bonus = puntosNetos}
```

En Lua, leer una local no declarada retorna `nil` silenciosamente. El campo `Fallos` siempre es `nil`.

**Corrección**:
```lua
return {Aciertos = aciertos, Fallos = cablesFaltantes, Bonus = puntosNetos}
```

---

### P0-2 — `task.wait(1)` como mecanismo de espera de servicios (condición de carrera)

**Archivos**: `ConectarCables.server.lua` (L8), `GameplayEvents.server.lua` (L7), `SistemaUI_reinicio.server.lua` (L8), `GraphTheoryService.server.lua` (L8)

Todos leen `_G.Services.*` tras un `task.wait(1)` fijo. Si `Init.server.lua` tarda más de 1 segundo, los scripts leen `nil` y fallan silenciosamente.

**Corrección** — crear `ServicesReady` BindableEvent en `Init.server.lua`:
```lua
-- Final de Init.server.lua
local ServicesReady = Instance.new("BindableEvent")
ServicesReady.Name = "ServicesReady"
ServicesReady.Parent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Bindables")
ServicesReady:Fire()

-- En cada script dependiente, reemplazar task.wait(1) por:
ReplicatedStorage:WaitForChild("Events"):WaitForChild("Bindables"):WaitForChild("ServicesReady").Event:Wait()
```

---

### P0-3 — Doble listener `RequestPlayLevel` — condición de carrera al iniciar nivel

**Archivos**: `Init.server.lua` (~L126–132) y `ManagerData.lua`

Ambos conectan `RequestPlayEvent.OnServerEvent`. Cuando el cliente dispara `RequestPlayLevel`, los dos handlers corren en orden no garantizado → condición de carrera en atributos del jugador.

**Corrección**: Eliminar el listener de `Init.server.lua`. `ManagerData.lua` ya llama internamente a `LevelService:loadLevel()`.

---

### P0-4 — `GameplayEvents` otorga recompensas dobles vía `LevelCompletedEvent`

**Archivo**: `GameplayEvents.server.lua` y `MissionService.lua`

`MissionService.checkVictoryCondition()` llama a `RewardService:giveCompletionRewards()` al detectar victoria y luego dispara `LevelCompletedEvent:FireClient()`. El cliente recibe esto y vuelve a dispara `LevelCompletedEvent` al servidor. El handler `LevelCompletedEvent.OnServerEvent` en `GameplayEvents.server.lua` llama a `giveCompletionRewards()` **por segunda vez**. El jugador recibe XP, dinero y estrellas duplicados.

**Corrección**: Eliminar la llamada a `giveCompletionRewards` del handler `LevelCompletedEvent.OnServerEvent` en `GameplayEvents.server.lua` o protegerlo con el mismo atributo `VictoryProcessed`.

---

### P0-5 — `VisualizadorAlgoritmos` cuelga indefinidamente en `WaitForChild("RestaurarObjetos")`

**Archivo**: `ServerScriptService/Gameplay/VisualizadorAlgoritmos.server.lua` línea 518 (top-level)

`WaitForChild("RestaurarObjetos")` bloquea el script indefinidamente. `RestaurarObjetos` no es creado por ningún script de forma garantizada antes de que arranque el visualizador.

**Corrección**: Crear todos los `BindableEvent`s necesarios en `Init.server.lua` antes de que arranquen los scripts dependientes (parte de la solución P0-2).

---

## 3. Problemas de Alta Severidad (P1) — Backlog

### P1-1 — `LevelService.getLevelProgress()` — `cablesPlaced` siempre es 0

**Archivo**: `ServerScriptService/Services/LevelService.lua` ~L349

```lua
local cables = graphService:getCables()  -- tabla hash { [key] = info }
return { cablesPlaced = #cables, ... }   -- #hash siempre = 0
```

`graphService:getCables()` retorna un mapa `{[string] = info}`. El operador `#` en Lua sobre tablas con claves string **siempre retorna 0**. El progreso del nivel siempre reporta `CablesPlaced = 0` al cliente.

**Corrección**: Usar `TableUtils.countKeys(cables)` (ver P1-5).

---

### P1-2 — `UIService.updateEnergyStatus()` y `updateProgress()` — `#energized` siempre 0

**Archivo**: `ServerScriptService/Services/UIService.lua` ~L132, ~L155

`energyService:calculateEnergy()` y `GraphUtils.bfs()` retornan `{[nodeName] = true}` — mapa hash. `#energized` siempre 0. El cliente siempre ve `NodesEnergized = 0` y `TotalEnergized = 0`.

**Corrección**: `TableUtils.countKeys(energized)`.

---

### P1-3 — `EnergyService.findCriticalNodes()` — nunca detecta nodos críticos

**Archivo**: `ServerScriptService/Services/EnergyService.lua`

```lua
local visitedWithout = GraphUtils.bfs(sourceNode, tempCables)
local visitedWith    = GraphUtils.bfs(sourceNode, cables)
if #visitedWithout < #visitedWith then  -- siempre false
    table.insert(critical, node)
end
```

Misma causa que P1-1 y P1-2: `#` sobre mapa hash retorna 0.

**Corrección**: `TableUtils.countKeys(visitedWithout) < TableUtils.countKeys(visitedWith)`.

---

### P1-4 — `RewardService.giveCompletionRewards()` — acceso a `player.leaderstats` sin guardia

**Archivo**: `ServerScriptService/Services/RewardService.lua` ~L386

```lua
local presupuestoUsado = config.DineroInicial - (player.leaderstats.Money.Value or 0)
```

Si `player.leaderstats` es `nil` (datos aún no cargados), la línea falla con nil-index error. El `or 0` solo protege `Money.Value`, no `player.leaderstats` ni `Money`.

**Corrección**:
```lua
local leaderstats = player:FindFirstChild("leaderstats")
local moneyValue = leaderstats and leaderstats:FindFirstChild("Money") and leaderstats.Money.Value or 0
local presupuestoUsado = config.DineroInicial - moneyValue
```

---

### P1-5 — Crear `TableUtils.lua` con `countKeys()` — requerido por P1-1, P1-2, P1-3

**Archivo a crear**: `ReplicatedStorage/Shared/Utils/TableUtils.lua`

```lua
local TableUtils = {}

function TableUtils.countKeys(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

return TableUtils
```

---

### P1-6 — `RunService.RenderStepped` en scripts de servidor — audio fade inoperativo

**Archivo**: `ServerScriptService/Services/AudioService.lua` líneas 210, 231

`RenderStepped` es un evento del cliente. En un `Script` de servidor, **nunca dispara**. Las funciones `fadeInSound` y `fadeOutSound` son silenciosamente no-operativas.

**Corrección**: Reemplazar `RunService.RenderStepped` por `RunService.Heartbeat`.

**Adicionalmente**: las conexiones no se desconectan si el `Sound` es destruido antes de que termine el fade, acumulando conexiones huérfanas:
```lua
connection = RunService.Heartbeat:Connect(function()
    if not sound or not sound.Parent then
        connection:Disconnect()
        return
    end
    -- ... lógica de fade
end)
```

---

### P1-7 — `LevelService.canConnect()` solo valida `A→B`, no `B→A`

**Archivo**: `ServerScriptService/Services/LevelService.lua`

```lua
function LevelService:canConnect(nodoA, nodoB)
    local adyacentes = levelConfig.Adyacencias[nombreA]
    if not adyacentes then return false end  -- falla si solo existe Adyacencias[B]
```

Si la conexión válida va en sentido `B→A`, `canConnect(A, B)` retorna `false` bloqueando una conexión legítima.

**Corrección**:
```lua
function LevelService:canConnect(nodoA, nodoB)
    if not levelConfig or not levelConfig.Adyacencias then return true end
    local ady = levelConfig.Adyacencias
    local aToB = ady[nombreA] and table.find(ady[nombreA], nombreB)
    local bToA = ady[nombreB] and table.find(ady[nombreB], nombreA)
    return aToB ~= nil or bToA ~= nil
end
```

---

### P1-8 — `AlgorithmService` pasa `Instance` en lugar de `string` a `GraphUtils.dijkstra`

**Archivo**: `ServerScriptService/Services/AlgorithmService.lua` líneas 152, 166, 231

```lua
local distancias = GraphUtils.dijkstra(nodoInicio, cables)  -- nodoInicio es Instance
```

`GraphUtils.dijkstra(startName, cables)` espera un `string`. `dist[Instance] = 0` se inicializa, pero los lookups posteriores usan `dist["NodeName"]` → siempre `nil`. El resultado es siempre una tabla vacía o el camino siempre se reconstruye como `{inicio, fin}` sin intermedios.

**Corrección**:
```lua
local distancias, prev = GraphUtils.dijkstra(nodoInicio.Name, cables)
-- Implementar reconstructPath usando la tabla `prev` real
```

---

### P1-9 — `AlgorithmService` — tres implementaciones incompatibles de Dijkstra/BFS

| Módulo | Dijkstra | BFS |
|---|---|---|
| `Algoritmos.lua` | Peso = 1 fijo | Calcula distancia física desde Workspace |
| `GraphUtils.lua` | Pesos desde cables | Sin distancia física |
| `AlgorithmService.lua` | Llama `GraphUtils` con firma incorrecta (P1-8) | Llama `Algoritmos.BFSVisual()` |

**Corrección**: Una sola implementación canónica en `GraphUtils.lua`. `Algoritmos.lua` pasa a ser módulo de visualización que delega en `GraphUtils`.

---

### P1-10 — `GestorEventos.server.lua` — polling activo bloquea hilo indefinidamente

**Archivo**: `ServerScriptService/GestorEventos.server.lua` líneas 8–18

```lua
while not _G.Services or not _G.Services[serviceName] do
    task.wait(0.5)  -- loop infinito si el servicio nunca carga
end
```

Con el mecanismo `ServicesReady` de P0-2, este patrón desaparece completamente.

---

### P1-11 — `Zona1_dialogo.lua` — `n1.Position` en un Model causa error en runtime

**Archivo**: `StarterGUI/DialogStorage/Zona1_dialogo.lua` línea ~134

```lua
local midPoint = n1.Position:Lerp(n2.Position, 0.5)
```

Los postes son `Model`s, no `Part`s. `Model` no tiene `.Position`. Lanza error en runtime.

**Corrección**:
```lua
local function getPos(instance)
    if instance:IsA("Model") then
        return instance.PrimaryPart and instance.PrimaryPart.Position or instance:GetPivot().Position
    end
    return instance.Position
end
local midPoint = getPos(n1):Lerp(getPos(n2), 0.5)
```

---

## 4. Problemas de Severidad Media (P2) — Backlog

### P2-1 — `GraphUtils.getDistance()` no existe — llamada en 2 archivos produce error

**Archivos**: `AlgorithmService.lua` y `GraphTheoryService.server.lua`

`GraphUtils.lua` no define `getDistance()`. `calcularDistancia()` existe localmente en `GraphTheoryService` sin exportar.

**Corrección** — añadir a `GraphUtils.lua`:
```lua
function GraphUtils.getDistance(nodeA, nodeB)
    if not nodeA or not nodeB then return 0 end
    local function pos(n)
        if n:IsA("Model") then
            return n.PrimaryPart and n.PrimaryPart.Position or n:GetPivot().Position
        end
        return n.Position
    end
    return (pos(nodeA) - pos(nodeB)).Magnitude
end
```

---

### P2-2 — `RewardService.giveCompletionRewards()` — división por cero cuando `DineroInicial = 0`

**Archivo**: `ServerScriptService/Services/RewardService.lua`

```lua
(1 - presupuestoUsado / config.DineroInicial)  -- 0/0 = nan en Nivel 0 (Tutorial)
```

**Corrección**:
```lua
local completionRatio = config.DineroInicial > 0
    and (1 - presupuestoUsado / config.DineroInicial)
    or 1.0
```

---

### P2-3 — `ManagerData.lua` — llamadas a funciones inexistentes de `NivelUtils`

**Archivo**: `ServerScriptService/Base_Datos/ManagerData.lua`

```lua
if NivelUtils and NivelUtils.obtenerModeloNivel then  -- nunca true
if NivelUtils and NivelUtils.obtenerPosicionSpawn then  -- nunca true
```

`NivelUtils.lua` no define estas funciones. Las condiciones son siempre falsas; el código cae al fallback y estos TODOs nunca se resuelven.

---

### P2-4 — `ManagerData.lua` — `require(NivelUtils)` sin `pcall`

**Archivo**: `ServerScriptService/Base_Datos/ManagerData.lua` línea 8

Si `NivelUtils.lua` tiene un error de sintaxis, `ManagerData` completo falla → sin persistencia de datos para ningún jugador.

**Corrección**:
```lua
local ok, NivelUtils = pcall(require, ReplicatedStorage:WaitForChild("Utilidades"):WaitForChild("NivelUtils"))
if not ok then warn("⚠️ ManagerData: NivelUtils no cargó, usando fallbacks") ; NivelUtils = nil end
```

---

### P2-5 — `MissionService` accede a `_G.Services` dentro de funciones frecuentes

**Archivo**: `ServerScriptService/Services/MissionService.lua` líneas 302–304, 405–407

`checkVictoryCondition()` y `buildFullGameState()` acceden a `_G.Services.Reward`, `_G.Services.Audio`, `_G.Services.UI`, `_G.Services.Energy` en cada llamada. `setDependencies()` solo inyecta `LevelService` y `GraphService`.

**Corrección**: Añadir los 4 servicios restantes a `setDependencies()` e inyectarlos desde `Init.server.lua`.

---

### P2-6 — `MissionService.buildFullGameState()` — `require()` dentro de función frecuente

**Archivo**: `ServerScriptService/Services/MissionService.lua`

```lua
function MissionService:buildFullGameState(player)
    local GraphUtils = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"):WaitForChild("GraphUtils"))
```

`WaitForChild` encadenado dentro de una función llamada en cada cambio de conexión. Mover al top-level del módulo.

---

### P2-7 — `Algoritmos.lua` busca nodos en Workspace con nombre hardcodeado, ignorando `NivelActual`

**Archivo**: `ReplicatedStorage/Algoritmos.lua` líneas 138–141

```lua
local nivelName = (nivelID == 0) and "Nivel0_Tutorial" or ("Nivel" .. nivelID)
local modelo = workspace:FindFirstChild(nivelName)  -- ignora "NivelActual"
```

`LevelService.loadLevel()` renombra el nivel a `"NivelActual"`. La búsqueda siempre retorna `nil` → todas las distancias BFS son `0`.

---

### P2-8 — `ControladorEscenario.server.lua` — `wait()` legado

**Archivo**: `ServerScriptService/ControladorEscenario.server.lua` línea 83

```lua
wait(2)  -- API legada
```

`wait()` puede acumular delays mayores bajo carga. **Corrección**: `task.wait(2)`.

Adicionalmente, `iniciarPulsos(p)` se llama directamente (no en `task.spawn`) en el handler `PlayerAdded` (línea 91), bloqueando esa conexión 2 segundos por cada jugador.

---

### P2-9 — `RewardService.validateAndUnlockAchievements()` — `progress.dineroRestante` no existe

**Archivo**: `ServerScriptService/Services/RewardService.lua`

`LevelService:getLevelProgress()` retorna `{nodesConnected, totalNodes, cablesPlaced, energized, completed}`. No incluye `dineroRestante`. El código cae al fallback y hay un comentario `-- Nota: progress debería tener dineroRestante` que indica un TODO sin resolver.

---

### P2-10 — `LevelService.getCables()` expone tabla interna sin copia defensiva

**Archivo**: `ServerScriptService/Services/LevelService.lua`

```lua
function LevelService:getCables()
    if graphService then return graphService:getCables() end
    return {}
end
```

Retorna la referencia directa a la tabla interna. Cualquier consumidor puede mutarla accidentalmente.

---

### P2-11 — `UIService.onConnectionChanged/onLevelLoaded/onLevelReset()` — código muerto

**Archivo**: `ServerScriptService/Services/UIService.lua`

Estos tres métodos están definidos pero nunca se llaman desde `Init.server.lua`. El manejo real de eventos se hace directamente en `GameplayEvents.server.lua`.

---

### P2-12 — `Enums.Colors` — `Conectado` y `Energizado` tienen el mismo color

**Archivo**: `ReplicatedStorage/Shared/Enums.lua`

```lua
Conectado = Color3.fromRGB(0, 255, 0),
Energizado = Color3.fromRGB(0, 255, 0),  -- idéntico
```

`GameplayEvents.server.lua` usa `BrickColor.new("Cyan")` para energizado, creando inconsistencia entre `Enums` y el código que aplica los colores.

---

### P2-13 — `AudioService` — volúmenes por defecto duplicados en `unmuteAll()`

**Archivo**: `ServerScriptService/Services/AudioService.lua`

Los valores `bgm = 0.5`, `sfx = 0.7`, `voice = 0.8`, `ambient = 0.3` aparecen dos veces: en la inicialización (líneas 14–19) y en `unmuteAll()` (líneas 267–271). Si se cambia un valor en un lugar, el otro queda desincronizado.

---

### P2-14 — `VisualizadorAlgoritmos` no usa `GraphUtils.getPostesFolder()`

**Archivo**: `ServerScriptService/Gameplay/VisualizadorAlgoritmos.server.lua` líneas 55–74

30 líneas de lógica propia que reinventa `GraphUtils.getPostesFolder()`.

**Corrección**:
```lua
local function obtenerCarpetaPostes()
    local nivel = (_G.Services and _G.Services.Level) and _G.Services.Level:getCurrentLevel()
    return nivel and GraphUtils.getPostesFolder(nivel)
end
```

---

### P2-15 — `ManagerData` crea `Events/Remotes` y `UIService.init()` también los crea

Ambos scripts verifican y crean `Events/Remotes` independientemente. No hay un único script responsable de la infraestructura de eventos.

---

## 5. Duplicaciones de Código

| ID | Descripción | Archivos afectados | Prioridad |
|---|---|---|---|
| DUP-1 | `getAlias/getNodeAlias` en 4 implementaciones independientes | `AliasUtils.lua` (canónico), `NivelUtils.lua`, `MatrixManager.lua` (L29), `Zona1_NodeFeedback.lua` (L90) | P2 |
| DUP-2 | `esperarKitLibre()` — función de espera de diálogo idéntica | `Zona1_NodeFeedback.lua` (L179), `NonAdjacentFeedback.lua` (L22) | P2 |
| DUP-3 | Boilerplate `checkZone` / activación de zona | `Zona1_dialogo.lua` (L270–317), `Zona2_dialogo.lua` (L440–481), `Zona3_dialogo.lua` (L362–403) | P2 |
| DUP-4 | Reset de dinero/puntos/estrellas duplicado | `ManagerData.lua` (L241–253), `SistemaUI_reinicio.server.lua` (L66–77) | P2 |
| DUP-5 | `calcularDistancia()` local sin exportar en 3 archivos | `GraphTheoryService.server.lua`, `AlgorithmService.lua` (la llama como `getDistance` inexistente), `Algoritmos.lua` (inline) | P1 |
| DUP-6 | `require(LevelsConfig)` dentro de 4 métodos distintos de `LevelService` | `LevelService.lua` métodos `init`, `loadLevel`, `getLevelInfo`, `getAllLevels` | P2 |
| DUP-7 | Doble `Players.PlayerAdded` para `MissionService:initializePlayer` | `MissionService.lua` (L142), `GameplayEvents.server.lua` (L215) | P2 |
| DUP-8 | Bloque `_refreshAndRestoreSelection` duplicado en `MatrixManager` | `MatrixManager.lua` (L573–600 y L638–665) | P2 |
| DUP-9 | `findPostes()` local en `MatrixManager` vs `GraphUtils.getPostesFolder()` | `MatrixManager.lua` (L490–498), `GraphUtils.lua` | P2 |
| DUP-10 | Constante `4 studs = 1 metro` hardcodeada | `ConectarCables.server.lua` (L178), `AlgorithmService.lua` (L208, 221), `GraphTheoryService.server.lua` (L148), `Algoritmos.lua` (L155) | P2 |
| DUP-11 | `BrickColor` de cables hardcodeados como strings | `GameplayEvents.server.lua`, `VisualizadorAlgoritmos.server.lua`, `ControladorEscenario.server.lua`, `ConectarCables.server.lua` | P2 |
| DUP-12 | `obtenerCarpetaPostes()` reimplementada | `VisualizadorAlgoritmos.server.lua` (L55–74), `GraphUtils.getPostesFolder()`, `LevelService.getPostes()` | P2 |
| DUP-13 | Colores COLORES y CONFIG.CAMARA idénticos en 3 archivos de zona | `Zona1_dialogo.lua`, `Zona2_dialogo.lua`, `Zona3_dialogo.lua` | P2 |
| DUP-14 | `NivelUtils.getNodeAlias()` duplica `AliasUtils.getNodeAlias()` | `NivelUtils.lua` (L46), `AliasUtils.lua` (L20) | P2 |
| DUP-15 | `NombresPostes` en `LevelsConfig` duplica `Nodos[name].Alias` | `LevelsConfig.lua` — todas las entradas de nivel | P2 |
| DUP-16 | `GraphService.getConnectionCount()` duplica `GraphUtils.degree()` | `GraphService.lua` (L147), `GraphUtils.lua` (L141) | P2 |
| DUP-17 | Construcción de lista de adyacencia `adj` inline en BFS y DFS | `GraphUtils.bfs()`, `GraphUtils.dfs()` — mismo bloque de 8 líneas | P2 |
| DUP-18 | `safeGetNodeZone()` en `GraphTheoryService` reimplementa `AliasUtils.getNodeZone()` | `GraphTheoryService.server.lua` (L78), `AliasUtils.lua` | P2 |

---

## 6. Antipatrones de Arquitectura

### AP-1 — `_G.Services` como contenedor global de servicios

Todos los scripts de Gameplay acceden a servicios vía `_G.Services.*` tras un `task.wait(1)` fijo. No hay garantía de orden de carga. El mecanismo `ServicesReady` (P0-2) es el reemplazo correcto.

### AP-2 — `_G.CompleteLevel` y `_G.CollectItem` como funciones globales

`ManagerData.lua` exporta estas dos funciones en la tabla global. Si `ManagerData` falla al cargar, las funciones son `nil` y los llamadores (p. ej. `MissionService`) solo lanzan un `warn`. No hay mecanismo de recuperación.

### AP-3 — `_G._matrixRefreshPending` como flag de debounce global

`MatrixManager.lua` usa el namespace global como variable de módulo. Puede colisionar con otros scripts.

### AP-4 — Patrón `pcall(require)` aplicado inconsistentemente

`VisualizadorAlgoritmos.server.lua` usa `pcall` al cargar módulos. Todos los demás scripts usan `require()` desnudo. Un error de sintaxis en cualquier módulo puede tumbar scripts críticos como `ManagerData`.

### AP-5 — Inconsistencia en cleanup de diálogos

`Zona1_dialogo.lua` usa callback `OnClose`. `Zona2_dialogo.lua` y `Zona3_dialogo.lua` usan nodo `"Cierre_Z*"` con campo `Evento`. Comportamiento divergente ante el mismo evento de cierre.

### AP-6 — Grosor de RopeConstraint desde `Enums.Cable` solo en `ConectarCables`

`Enums.Cable` define `NormalThickness`, `SelectedThickness`, `EnergyThickness`. Solo `ConectarCables.server.lua` los usa. `VisualizadorAlgoritmos`, `GameplayEvents` y `GraphTheoryService` usan valores hardcodeados distintos (0.4, 0.5, 0.25, 0.3, 0.2).

---

## 7. Estructura de Carpetas Recomendada

```
ReplicatedStorage/
├── Shared/
│   ├── Constants.lua          ← NUEVO: STUDS_PER_METER, TIMEOUT_DEFAULT, MAX_LEVELS
│   ├── Enums.lua              ← MODIFICAR: añadir CableColors (BrickColor), STUDS_PER_METER,
│   │                                       alinear Conectado ≠ Energizado
│   └── Utils/
│       ├── GraphUtils.lua     ← MODIFICAR: getDistance(), getAdjacencyMatrix con parámetro
│       │                                   adyacencias, buildAdjList(), exportar calcularDistancia
│       └── TableUtils.lua     ← NUEVO: countKeys(), deepCopy(), shallowCopy()
├── Utilidades/
│   ├── AliasUtils.lua         ← sin cambios (módulo canónico de alias/zona)
│   └── NivelUtils.lua         ← ELIMINAR tras migrar todos los consumidores
├── Algoritmos.lua             ← MODIFICAR: usar GraphUtils.getDistance(), buscar por "NivelActual"
│                                           en lugar de nombre hardcodeado
├── LevelsConfig.lua           ← MODIFICAR: deprecar NombresPostes
├── Economia.lua               ← sin cambios
└── DialogueVisibilityManager.lua ← sin cambios

ServerScriptService/
├── Init.server.lua            ← MODIFICAR: crear ServicesReady BindableEvent y todos los
│                                           BindableEvents necesarios; eliminar listener
│                                           duplicado RequestPlayLevel; ser el único creador
│                                           de Events/Remotes y Events/Bindables
├── GestorEventos.server.lua   ← MODIFICAR: eliminar polling, usar ServicesReady
├── ControladorEscenario.server.lua ← MODIFICAR: wait() → task.wait(), spawn iniciarPulsos
│                                               en PlayerAdded
├── Base_Datos/
│   └── ManagerData.lua        ← MODIFICAR: pcall en require(NivelUtils), eliminar refs a
│                                           funciones inexistentes de NivelUtils, centralizar
│                                           creación de Events/Remotes en Init
├── Gameplay/
│   ├── ConectarCables.server.lua      ← MODIFICAR: ServicesReady, Enums.STUDS_PER_METER,
│   │                                               Enums.CableColors
│   ├── GameplayEvents.server.lua      ← MODIFICAR: ServicesReady, Enums.CableColors,
│   │                                               eliminar doble-reward de LevelCompletedEvent
│   ├── GraphTheoryService.server.lua  ← MODIFICAR: fix bug matriz dirigida (SPRINT ACTUAL),
│   │                                               eliminar safeGetNodeZone,
│   │                                               usar AliasUtils, ServicesReady
│   ├── SistemaUI_reinicio.server.lua  ← MODIFICAR: ServicesReady
│   └── VisualizadorAlgoritmos.server.lua ← MODIFICAR: fix var fallos, GraphUtils.getPostesFolder,
│                                               Heartbeat en lugar de RenderStepped,
│                                               ServicesReady (elimina WaitForChild bloqueante)
└── Services/
    ├── AlgorithmService.lua   ← MODIFICAR: fix firma dijkstra (.Name), reconstructPath real,
    │                                       GraphUtils.getDistance, unificar implementaciones
    ├── AudioService.lua       ← MODIFICAR: RenderStepped → Heartbeat, fix memory leak,
    │                                       centralizar volúmenes por defecto
    ├── EnergyService.lua      ← MODIFICAR: countKeys en findCriticalNodes
    ├── GraphService.lua       ← MODIFICAR: getConnectionCount → GraphUtils.degree
    ├── InventoryService.lua   ← sin cambios
    ├── LevelService.lua       ← MODIFICAR: fix canConnect bidireccional, getCables copia
    │                                       defensiva, cablesPlaced con countKeys,
    │                                       require(LevelsConfig) al top-level
    ├── MissionService.lua     ← MODIFICAR: inyectar RewardService/UIService/AudioService/
    │                                       EnergyService via setDependencies,
    │                                       require GraphUtils al top-level
    ├── RewardService.lua      ← MODIFICAR: fix división por cero DineroInicial = 0,
    │                                       fix progress.dineroRestante, guardia leaderstats
    └── UIService.lua          ← MODIFICAR: eliminar código muerto onConnectionChanged etc.,
                                            countKeys para energized, alinear Enums.Colors

StarterGUI/
├── DialogStorage/
│   ├── SharedDialogConfig.lua     ← CREAR: COLORES compartidos (normalizar naranja),
│   │                                        CONFIG.CAMARA compartido, SKIN_NAME
│   ├── ZoneDialogActivator.lua    ← CREAR: encapsula yaSeMostro + listener CurrentZone
│   │                                        + task.delay(1) de comprobación inicial
│   ├── DialogUtils.lua            ← CREAR: esperarKitLibre(), getPos(instance)
│   ├── Zona1_dialogo.lua          ← MODIFICAR: usar SharedDialogConfig, ZoneDialogActivator,
│   │                                            DialogUtils.getPos, unificar OnClose
│   ├── Zona2_dialogo.lua          ← MODIFICAR: ídem
│   ├── Zona3_dialogo.lua          ← MODIFICAR: ídem, verificar naranja RGB
│   ├── Zona4_dialogo.lua          ← CREAR usando SharedDialogConfig y ZoneDialogActivator
│   │                                           desde el inicio (no reintroducir deuda)
│   ├── Zona1_NodeFeedback.lua     ← MODIFICAR: usar AliasUtils, DialogUtils.esperarKitLibre
│   ├── NonAdjacentFeedback.lua    ← MODIFICAR: usar DialogUtils.esperarKitLibre
│   ├── DialogueGenerator.lua      ← sin cambios
│   └── Nivel0_dialogo1.lua        ← sin cambios
└── Dialogkit.module.lua           ← sin cambios

StarterPlayer/StarterPlayerScripts/
└── Cliente/
    └── Services/
        └── MatrixManager.lua      ← MODIFICAR: extraer _refreshAndRestoreSelection(),
                                                usar AliasUtils (eliminar getAlias local),
                                                usar GraphUtils.getPostesFolder,
                                                eliminar _G._matrixRefreshPending
```

---

## 8. Tabla Maestra de Cambios

| Archivo | Acción | Prioridad | Motivos principales |
|---|---|---|---|
| `GraphUtils.lua` | Modificar | **SPRINT** | Fix matriz dirigida; `buildAdjList()`, `getDistance()` |
| `GraphTheoryService.server.lua` | Modificar | **SPRINT** | Fix bug matriz + `safeGetNodeZone` |
| `TableUtils.lua` | **Crear** | P1 | `countKeys()` — requerido por P1-1/2/3 |
| `Init.server.lua` | Modificar | P0 | `ServicesReady`, todos los BindableEvents, eliminar listener duplicado |
| `GameplayEvents.server.lua` | Modificar | P0 | Eliminar doble-reward `LevelCompletedEvent` |
| `VisualizadorAlgoritmos.server.lua` | Modificar | P0/P1 | Var `fallos`, `RenderStepped`, `WaitForChild` bloqueante |
| `EnergyService.lua` | Modificar | P1 | `countKeys` en `findCriticalNodes` |
| `LevelService.lua` | Modificar | P1 | `canConnect` bidireccional, `cablesPlaced` con `countKeys` |
| `UIService.lua` | Modificar | P1 | `countKeys` para energized, eliminar código muerto |
| `AudioService.lua` | Modificar | P1 | `Heartbeat`, memory leak, volúmenes centralizados |
| `AlgorithmService.lua` | Modificar | P1 | Firma dijkstra `.Name`, `reconstructPath`, `getDistance` |
| `RewardService.lua` | Modificar | P1/P2 | División por cero, guardia `leaderstats`, `dineroRestante` |
| `GestorEventos.server.lua` | Modificar | P1 | Eliminar polling → `ServicesReady` |
| `MissionService.lua` | Modificar | P1/P2 | Inyección completa de dependencias, `require` al top-level |
| `Zona1_dialogo.lua` | Modificar | P1 | `getPos()` en Model, `SharedDialogConfig`, `ZoneDialogActivator` |
| `ControladorEscenario.server.lua` | Modificar | P2 | `wait()` → `task.wait()`, spawn en `PlayerAdded` |
| `ManagerData.lua` | Modificar | P2 | `pcall` en require, eliminar refs a funciones inexistentes |
| `MatrixManager.lua` | Modificar | P2 | `_refreshAndRestoreSelection()`, `AliasUtils`, `getPostesFolder` |
| `GraphService.lua` | Modificar | P2 | `getConnectionCount` → `GraphUtils.degree` |
| `Algoritmos.lua` | Modificar | P2 | Buscar `NivelActual`, usar `GraphUtils.getDistance` |
| `LevelsConfig.lua` | Modificar | P2 | Deprecar `NombresPostes` |
| `Enums.lua` | Modificar | P2 | `STUDS_PER_METER`, `CableColors`, alinear `Conectado ≠ Energizado` |
| `Zona2_dialogo.lua` | Modificar | P2 | `SharedDialogConfig`, `ZoneDialogActivator` |
| `Zona3_dialogo.lua` | Modificar | P2 | Ídem + verificar naranja |
| `Zona1_NodeFeedback.lua` | Modificar | P2 | `AliasUtils`, `DialogUtils.esperarKitLibre` |
| `NonAdjacentFeedback.lua` | Modificar | P2 | `DialogUtils.esperarKitLibre` |
| `SharedDialogConfig.lua` | **Crear** | P2 | Colores + cámara compartidos |
| `ZoneDialogActivator.lua` | **Crear** | P2 | Boilerplate activación de zona |
| `DialogUtils.lua` | **Crear** | P2 | `esperarKitLibre()`, `getPos(instance)` |
| `Constants.lua` | **Crear** | P2 | `STUDS_PER_METER`, `TIMEOUT_DEFAULT`, `MAX_LEVELS` |
| `Zona4_dialogo.lua` | **Crear** | P2 | Usar `SharedDialogConfig` + `ZoneDialogActivator` desde el inicio |
| `NivelUtils.lua` | **Eliminar** | P2 | Supersedido por `AliasUtils` + `LevelService` |

---

## 9. Orden de Implementación Global

### Sprint Actual

1. Fix `GraphTheoryService.server.lua` — pasar `Adyacencias` al builder de matriz, consultar direccionalidad
2. Fix `GraphUtils.getAdjacencyMatrix()` — añadir parámetro opcional `adyacencias`
3. Verificar `MatrixManager.calcularGrados()` — debe funcionar sin cambios una vez que la matriz llega correcta

### Fase 1 — Bugs críticos (P0)

4. Crear `ServicesReady` BindableEvent en `Init.server.lua` + reemplazar todos los `task.wait(1)`
5. Crear todos los BindableEvents en `Init.server.lua` (elimina el WaitForChild bloqueante de VisualizadorAlgoritmos)
6. Eliminar listener duplicado `RequestPlayLevel` de `Init.server.lua`
7. Fix `VisualizadorAlgoritmos` — var `fallos = cablesFaltantes`
8. Fix `GameplayEvents` — eliminar doble-reward de `LevelCompletedEvent.OnServerEvent`

### Fase 2 — Bugs funcionales de servicios (P1)

9. Crear `TableUtils.lua` con `countKeys()`
10. Fix `LevelService.getLevelProgress()` — `countKeys(cables)`
11. Fix `UIService.updateEnergyStatus/updateProgress()` — `countKeys(energized)`
12. Fix `EnergyService.findCriticalNodes()` — `countKeys`
13. Fix `RewardService` — guardia `leaderstats`, división por cero
14. Fix `AudioService` — `Heartbeat`, memory leak
15. Fix `LevelService.canConnect()` — validar `B→A`
16. Fix `AlgorithmService` — firma dijkstra `.Name`, `reconstructPath` real
17. Exportar `GraphUtils.getDistance()`
18. Fix `Zona1_dialogo.lua` — `getPos()` en Model

### Fase 3 — Arquitectura y dependencias (P1/P2)

19. Eliminar polling de `GestorEventos` (cubierto por ServicesReady)
20. Migrar `MissionService` a inyección completa de dependencias
21. Fix `ManagerData` — `pcall` en `require(NivelUtils)`
22. Fix `Algoritmos.lua` — buscar `NivelActual`, usar `GraphUtils.getDistance`
23. Fix `ControladorEscenario` — `wait()` → `task.wait()`, spawn en PlayerAdded

### Fase 4 — Deduplicación y limpieza (P2)

24. Crear `Constants.lua` con `STUDS_PER_METER`, `TIMEOUT_DEFAULT`, `MAX_LEVELS`
25. Añadir `CableColors` y `STUDS_PER_METER` a `Enums.lua`, alinear colores
26. Centralizar `buildAdjList()` en `GraphUtils`, eliminar duplicación DUP-17
27. `GraphService.getConnectionCount` → `GraphUtils.degree`
28. Extraer `_refreshAndRestoreSelection()` en `MatrixManager` + usar `AliasUtils`
29. Crear `SharedDialogConfig.lua` + `ZoneDialogActivator.lua` + `DialogUtils.lua`
30. Migrar `Zona1/2/3_dialogo.lua` a módulos compartidos
31. Crear `Zona4_dialogo.lua` desde el inicio con los módulos compartidos
32. Eliminar `NivelUtils.lua` (verificar consumidores antes con Grep)
33. Deprecar `NombresPostes` en `LevelsConfig.lua`

---

## 10. Tests Post-Refactorización

| Test | Criterio de éxito |
|---|---|
| Zona 1 (no dirigido) — matriz | `M[i][j] == M[j][i]` para todos los nodos conectados |
| Zona 3 (dirigido) — matriz | `M[X][Y] = peso` y `M[Y][X] = 0` cuando solo existe `X→Y` |
| MatrixManager — grados en dígrafo | Grado entrada ≠ grado salida para nodos asimétricos |
| Tutorial (Nivel 0) — recompensas | Completar sin producir `NaN`; el jugador recibe recompensas exactamente una vez |
| `findCriticalNodes` | Crear nodo puente manualmente → aparece en la lista retornada |
| `AlgorithmService.executeDijkstra` | El camino reconstruido contiene nodos intermedios, no solo `{inicio, fin}` |
| `canConnect` bidireccional | Zona 3: arista en sentido correcto → aceptada; sentido inverso → rechazada |
| `ServicesReady` | En Studio Output, todos los scripts dependientes imprimen sus servicios correctamente sin errores en los primeros 3 segundos |
| Progreso de nivel | `CablesPlaced` y `NodesEnergized` muestran valores > 0 cuando hay cables conectados |
| Recompensas únicas | Completar un nivel otorga dinero/XP/estrellas exactamente una vez (sin duplicados) |
| Diálogo de Zona 1 | La escena de cámara en postes no lanza error de `.Position` en un Model |
| Audio fades | El sonido hace fade in/out correctamente en el servidor (verificar con `print` en Heartbeat) |
