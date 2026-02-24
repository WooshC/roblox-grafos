# roblox-grafos — Deuda Técnica Unificada (Rev. 2)

> **Propósito**: Documento único que unifica `REFACTORING.md` y `roblox-grafos-deuda-tecnica.md`, incorpora todos los nuevos problemas encontrados en análisis profundo de código, y define prioridades de sprint.
>
> **Estado**: Los archivos anteriores (`REFACTORING.md` y `roblox-grafos-deuda-tecnica.md`) quedan obsoletos. Este es el documento de referencia.
>
> **Revisión 2**: Segunda revisión profunda del código. Se marcan ítems resueltos, se corrigen descripciones obsoletas y se agregan 10 nuevos errores encontrados.
>
> **Fase 1** (2026-02-24): Corrección de todos los bugs críticos P0. P0-1, P0-2, P0-3, P0-5, P0-6 resueltos.

---

## Tabla de contenido

1. [Sprint anterior — Matriz dirigida/no dirigida ✅ COMPLETADO](#1-sprint-anterior--corrección-de-la-matriz-de-adyacencia)
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

## 1. Sprint anterior — Corrección de la matriz de adyacencia

> ✅ **COMPLETADO** — Los tres focos descritos abajo ya están corregidos en el código actual. Esta sección queda como referencia histórica.

### Síntoma (ya resuelto)

En la Zona 3 (Grafos Dirigidos), la matriz mostraba `1` en ambas celdas `A[i][j]` y `A[j][i]` aunque la arista fuera unidireccional.

### Lo que se corrigió

#### Foco 1 — `GraphUtils.lua : getAdjacencyMatrix()` ✅

```lua
-- ACTUAL (corregido): acepta parámetro opcional adyacencias
function GraphUtils.getAdjacencyMatrix(nodes, cables, adyacencias)
    -- ...
    if adyacencias then
        local aToB = adyacencias[nA] and table.find(adyacencias[nA], nB)
        local bToA = adyacencias[nB] and table.find(adyacencias[nB], nA)
        local fallback = not aToB and not bToA
        if aToB or fallback then matrix[idxA][idxB] = 1 end
        if bToA or fallback then matrix[idxB][idxA] = 1 end
    else
        matrix[idxA][idxB] = 1
        matrix[idxB][idxA] = 1
    end
end
```

#### Foco 2 — `GraphTheoryService.server.lua` ✅

Ya obtiene `levelCfg.Adyacencias` y lo pasa al llenado de la matriz, respetando direccionalidad.

#### Foco 3 — `MatrixManager.lua : calcularGrados()` ✅

Detecta dígrafos comparando `matrix[r][c]` con `matrix[c][r]`. Funciona correctamente una vez que la matriz llega asimétrica del servidor.

### Tests que deben pasar (ya verificables)

- **Zona 1 / 2**: La matriz sigue siendo simétrica.
- **Zona 3**: `M[X][Y] = peso` pero `M[Y][X] = 0` cuando solo existe `X→Y`.
- **MatrixManager**: Los grados de entrada/salida en un dígrafo son correctos y distintos.

---

## 2. Bugs Críticos (P0) — Backlog

### ~~P0-1 — Variable `fallos` usada sin declarar en `VisualizadorAlgoritmos`~~ ✅ RESUELTO

> **Fase 1**: Corregido en `VisualizadorAlgoritmos.server.lua` L391: `Fallos = fallos` → `Fallos = cablesFaltantes`.

```lua
-- CORREGIDO
return {Aciertos = aciertos, Fallos = cablesFaltantes, Bonus = puntosNetos}
```

---

### ~~P0-2 — `task.wait(1)` como mecanismo de espera de servicios (condición de carrera)~~ ✅ RESUELTO

> **Fase 1**: `Init.server.lua` ahora crea `ServicesReady` BindableEvent y lo dispara al final de la inicialización. Los 4 scripts dependientes reemplazaron `task.wait(1)` por `ServicesReady.Event:Wait()`.

```lua
-- CORREGIDO en cada script dependiente
ReplicatedStorage:WaitForChild("Events"):WaitForChild("Bindables"):WaitForChild("ServicesReady").Event:Wait()
```

---

### ~~P0-3 — Doble listener `RequestPlayLevel` — condición de carrera al iniciar nivel~~ ✅ RESUELTO

> **Fase 1**: Eliminado el listener de `Init.server.lua`. `ManagerData.lua::setupLevelForPlayer()` ahora llama explícitamente a `LevelService:loadLevel(levelId)` vía `_G.Services.Level` antes de buscar el modelo en Workspace, garantizando que `NivelActual` exista cuando se hace el teletransporte. (Los errores "Modelo de nivel no encontrado" y "No se encontró Spawn" quedaron resueltos con este cambio.)

---

### ~~P0-4 — `GameplayEvents` otorga recompensas dobles vía `LevelCompletedEvent`~~ ✅ RESUELTO

> **Revisión 2**: `GameplayEvents.server.lua` ya no tiene un handler `LevelCompletedEvent.OnServerEvent`. Las recompensas se otorgan únicamente desde `MissionService.checkVictoryCondition()` mediante la guardia `VictoryProcessed`. Este bug está resuelto en la versión actual.

---

### ~~P0-5 — `VisualizadorAlgoritmos` cuelga indefinidamente en `WaitForChild("RestaurarObjetos")`~~ ✅ RESUELTO

> **Fase 1**: `Init.server.lua` ahora crea `RestaurarObjetos`, `GuardarInventario`, `AristaConectada` y `DesbloquearObjeto` como BindableEvents antes de disparar `ServicesReady`. El `WaitForChild` en `VisualizadorAlgoritmos` ahora usa timeout de 10 s como salvaguarda.

---

### ~~P0-6 — `GestorEventos` también bloquea en `WaitForChild("RestaurarObjetos")`~~ ✅ RESUELTO

> **Fase 1**: `GestorEventos.server.lua` reemplazó el polling infinito (`waitForService`) por `ServicesReady.Event:Wait()`. Los eventos `RestaurarObjetos` y `DesbloquearObjeto` ya existen cuando `GestorEventos` arranca porque `Init.server.lua` los crea antes de disparar `ServicesReady`.

---

## 3. Problemas de Alta Severidad (P1) — Backlog

### P1-1 — `LevelService.getLevelProgress()` — `cablesPlaced` siempre es 0

**Archivo**: `ServerScriptService/Services/LevelService.lua` ~L354

```lua
local cables = graphService:getCables()  -- tabla hash { [key] = info }
return { cablesPlaced = #cables, ... }   -- #hash siempre = 0
```

`graphService:getCables()` retorna un mapa `{[string] = info}`. El operador `#` en Lua sobre tablas con claves string **siempre retorna 0**. El progreso del nivel siempre reporta `CablesPlaced = 0` al cliente.

**Corrección**: Usar `TableUtils.countKeys(cables)` (ver P1-5).

---

### P1-2 — `UIService.updateEnergyStatus()` y `updateProgress()` — `#energized` siempre 0

**Archivo**: `ServerScriptService/Services/UIService.lua` ~L132, ~L155

```lua
NodesEnergized = #progress.energized  -- L132, hash map
TotalEnergized = #energized           -- L155, hash map
```

`energyService:calculateEnergy()` retorna `{[nodeName] = true}` — mapa hash. `#energized` siempre 0. El cliente siempre ve `NodesEnergized = 0` y `TotalEnergized = 0`.

**Corrección**: `TableUtils.countKeys(energized)`.

---

### P1-3 — `EnergyService.findCriticalNodes()` — nunca detecta nodos críticos

**Archivo**: `ServerScriptService/Services/EnergyService.lua` línea 166

```lua
local visitedWithout = GraphUtils.bfs(sourceNode, tempCables)
local visitedWith    = GraphUtils.bfs(sourceNode, cables)
if #visitedWithout < #visitedWith then  -- siempre false: 0 < 0
    table.insert(critical, node)
end
```

Misma causa que P1-1 y P1-2: `#` sobre mapa hash retorna 0. Adicionalmente `EnergyService:debug()` imprime `"Total nodos energizados: " .. #energized` que siempre imprime 0.

**Corrección**: `TableUtils.countKeys(visitedWithout) < TableUtils.countKeys(visitedWith)`

---

### P1-4 — `RewardService.giveCompletionRewards()` — acceso a `player.leaderstats` sin guardia

**Archivo**: `ServerScriptService/Services/RewardService.lua` línea 386

```lua
local presupuestoUsado = config.DineroInicial - (player.leaderstats.Money.Value or 0)
```

Si `player.leaderstats` es `nil` (datos aún no cargados), la línea lanza nil-index error. El `or 0` solo protege `Money.Value`, no `player.leaderstats` ni `Money`.

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

### P1-6 — `AudioService.stopAmbiance()` es un stub vacío — sonidos de ambiente nunca se detienen

**Archivo**: `ServerScriptService/Services/AudioService.lua` líneas 298–300

> **Revisión 2**: En la versión anterior de `AudioService`, el bug documentado era el uso de `RunService.RenderStepped` en un script de servidor. Ese código ya fue eliminado en la refactorización. El bug actual es diferente:

```lua
function AudioService:stopAmbiance()
    print("🌍 AudioService: Ambiente detenido")
    -- Sin implementación real
end
```

`playAmbiance()` crea un `Sound` con `Looped = true` en `workspace` pero no guarda referencia. `stopAmbiance()` solo imprime un mensaje. Los sonidos de ambiente se acumulan en workspace y nunca paran.

**Corrección**: Guardar referencia al sonido de ambiente y detenerlo en `stopAmbiance()`.

---

### P1-7 — `LevelService.canConnect()` solo valida `A→B`, no `B→A`

**Archivo**: `ServerScriptService/Services/LevelService.lua` líneas 374–383

```lua
function LevelService:canConnect(nodoA, nodoB)
    local adyacentes = levelConfig.Adyacencias[nombreA]
    if not adyacentes then return false end  -- falla si solo existe Adyacencias[B]
```

Para grafos no dirigidos donde la configuración define la arista solo en un sentido (`Adyacencias[B] = {A}` pero no `Adyacencias[A]`), `canConnect(A, B)` retorna `false`, bloqueando una conexión legítima.

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

**Archivo**: `ServerScriptService/Services/AlgorithmService.lua` líneas 152, 170, 235

```lua
local distancias = GraphUtils.dijkstra(nodoInicio, cables)  -- nodoInicio es Instance
```

`GraphUtils.dijkstra(startName, cables)` espera un `string`. `dist[Instance] = 0` se inicializa, pero los lookups posteriores usan `dist["NodeName"]` → siempre `nil`. El resultado es siempre una tabla vacía.

**Corrección**:
```lua
local distancias, prev = GraphUtils.dijkstra(nodoInicio.Name, cables)
```

---

### P1-9 — `AlgorithmService` — tres implementaciones incompatibles de Dijkstra/BFS

| Módulo | Dijkstra | BFS |
|---|---|---|
| `Algoritmos.lua` | Peso = 1 fijo, trabaja con `Adyacencias` de config | Calcula distancia física desde Workspace (nombre hardcodeado) |
| `GraphUtils.lua` | Pesos desde cables, espera string | Sin distancia física |
| `AlgorithmService.lua` | Llama `GraphUtils` con firma incorrecta (P1-8) | Llama `Algoritmos.BFSVisual()` |

**Corrección**: Una sola implementación canónica en `GraphUtils.lua`. `Algoritmos.lua` pasa a ser módulo de visualización que delega en `GraphUtils`.

---

### P1-10 — `GestorEventos.server.lua` — polling activo sin límite real

**Archivo**: `ServerScriptService/GestorEventos.server.lua` líneas 8–18

```lua
local function waitForService(serviceName)
    local attempts = 0
    while not _G.Services or not _G.Services[serviceName] do
        if attempts > 30 then
            warn("..."); attempts = 0  -- Reinicia intentos, loop infinito
        end
        task.wait(0.5)
        attempts = attempts + 1
    end
end
```

El contador de intentos se reinicia a 0 cada 30 ciclos (15 segundos). El loop es efectivamente infinito si el servicio nunca carga. Con el mecanismo `ServicesReady` de P0-2, este patrón desaparece completamente.

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

### P1-12 — `GraphService.clearAllCables()` y `LevelService.resetLevel()` no destruyen cables visuales — cables permanecen al reiniciar

**Archivo**: `ServerScriptService/Services/GraphService.lua` líneas 208–216 y `LevelService.lua` línea 280

```lua
-- clearAllCables(): solo limpia el diccionario, no destruye RopeConstraints
cables = {}
```

`LevelService.resetLevel()` llama a `graphService:clearAllCables()`, que solo vacía el diccionario interno de cables. Los `RopeConstraint`s físicos en la carpeta `Conexiones` del nivel **permanecen visibles** para el jugador. Después del reinicio, el grafo visual no coincide con el estado lógico.

`SistemaUI_reinicio.server.lua` limpia `CableFantasmaAlgoritmo` y `EtiquetaPeso` en workspace, pero **no** los cables reales en la carpeta `Conexiones`.

**Corrección**: `clearAllCables()` debe destruir cada `cableInstance`:
```lua
for key, cableInfo in pairs(cables) do
    if cableInfo.cableInstance and cableInfo.cableInstance.Parent then
        cableInfo.cableInstance:Destroy()
    end
    cableRemovedEvent:Fire(cableInfo.nodeA, cableInfo.nodeB, cableInfo.cableInstance)
end
cables = {}
```

---

### P1-13 — `ClickDetector` hijo de `RopeConstraint` es inoperante

**Archivo**: `ServerScriptService/Gameplay/ConectarCables.server.lua` líneas 226–233

```lua
local cableClickDetector = Instance.new("ClickDetector")
cableClickDetector.Parent = rope  -- rope es un RopeConstraint
```

En Roblox, `ClickDetector` solo funciona cuando es hijo de `BasePart`. Al parentarlo a un `RopeConstraint`, nunca dispara `MouseClick`. La funcionalidad de "clic en el cable para desconectarlo" está completamente rota.

**Corrección**: Crear un `Part` auxiliar invisible posicionado en el centro del cable y parentar el `ClickDetector` a él, o manejar la desconexión con otro mecanismo (p. ej., UI de clic en la etiqueta de peso).

---

### P1-14 — `GraphService.getDistances()` y `EnergyService.getEnergyCost()` pasan `Instance` a `GraphUtils.dijkstra`

**Archivos**: `ServerScriptService/Services/GraphService.lua` línea 173, `EnergyService.lua` línea 137

```lua
-- GraphService.lua L173
function GraphService:getDistances(startNode)
    return GraphUtils.dijkstra(startNode, cables)  -- startNode es Instance
end

-- EnergyService.lua L137
function EnergyService:getEnergyCost(sourceNode)
    return GraphUtils.dijkstra(sourceNode, graphService:getCables())  -- Instance
end
```

Misma causa raíz que P1-8. `dijkstra` espera un `string`. El resultado es siempre distancias vacías (o con clave `[Instance]` inaccesible por string). Cualquier consumidor de `getDistances()` o `getEnergyCost()` recibirá datos incorrectos.

**Corrección**:
```lua
return GraphUtils.dijkstra(startNode.Name, cables)
```

---

### P1-15 — `MissionService.Validators.ARISTA_DIRIGIDA` usa clave simétrica — no puede validar dirección

**Archivo**: `ServerScriptService/Services/MissionService.lua` líneas 56–63

```lua
Validators.ARISTA_DIRIGIDA = function(params, estado)
    local k1 = origen < destino and (origen .. "_" .. destino) or (destino .. "_" .. origen)
    return conexiones[k1] == true
end
```

El validador usa exactamente la misma clave simétrica que `ARISTA_CREADA`. Los cables se almacenan con clave alfabética (`getCableKey`) independientemente de la dirección de conexión. Por tanto, `ARISTA_DIRIGIDA` es funcionalmente idéntico a `ARISTA_CREADA` y no puede verificar que la conexión vaya en un sentido específico.

**Corrección**: El estado del juego (`estado.conexionesActivas`) debe incluir claves orientadas (separadas) para poder distinguir `A→B` de `B→A`. Alternativamente, añadir `estado.aristasDirigidas = { ["A>B"] = true }` basado en `config.Adyacencias`.

---

## 4. Problemas de Severidad Media (P2) — Backlog

### P2-1 — `GraphUtils.getDistance()` no existe — llamada en 2 archivos produce error

**Archivos**: `AlgorithmService.lua` y `GraphTheoryService.server.lua`

`GraphUtils.lua` no define `getDistance()`. `AlgorithmService.lua` la llama en líneas 204 y 219 — lanza nil-function call error. `calcularDistancia()` existe localmente en `GraphTheoryService` sin exportar.

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

**Archivo**: `ServerScriptService/Services/RewardService.lua` línea 393

```lua
local moneyReward = self:giveMoneyForLevel(player, nivelID, (1 - presupuestoUsado / config.DineroInicial))
-- 0/0 → NaN / Inf en Nivel 0 (Tutorial con DineroInicial = 0)
```

**Corrección**:
```lua
local completionRatio = config.DineroInicial > 0
    and (1 - presupuestoUsado / config.DineroInicial)
    or 1.0
local moneyReward = self:giveMoneyForLevel(player, nivelID, completionRatio)
```

---

### P2-3 — `ManagerData.lua` — llamadas a funciones inexistentes de `NivelUtils`

**Archivo**: `ServerScriptService/Base_Datos/ManagerData.lua` líneas 195–196, 214–215

```lua
if NivelUtils and NivelUtils.obtenerModeloNivel then  -- nunca true
if NivelUtils and NivelUtils.obtenerPosicionSpawn then -- nunca true
```

`NivelUtils.lua` no define estas funciones. Las condiciones son siempre falsas; el código cae al fallback. Los TODOs nunca se resuelven.

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

**Archivo**: `ServerScriptService/Services/MissionService.lua` líneas 302–306, 405–408

`checkVictoryCondition()` y `buildFullGameState()` acceden a `_G.Services.Energy`, `_G.Services.Reward`, `_G.Services.Audio`, `_G.Services.UI` en cada llamada (que ocurre con cada cambio de cable). `setDependencies()` solo inyecta `LevelService` y `GraphService`.

**Corrección**: Añadir los 4 servicios restantes a `setDependencies()` e inyectarlos desde `Init.server.lua`.

---

### P2-6 — `MissionService.buildFullGameState()` — `require()` dentro de función frecuente

**Archivo**: `ServerScriptService/Services/MissionService.lua` línea 290

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

`LevelService.loadLevel()` renombra el nivel a `"NivelActual"`. La búsqueda siempre retorna `nil` → todas las posiciones físicas en `BFSVisual` son `Vector3.new(0,0,0)` → `distanciaTotal = 0`.

---

### P2-8 — `ControladorEscenario.server.lua` — `wait()` legado y `iniciarPulsos` bloqueante en `PlayerAdded`

**Archivo**: `ServerScriptService/ControladorEscenario.server.lua` líneas 83, 91

```lua
wait(2)  -- L83: API legada
-- ...
Players.PlayerAdded:Connect(iniciarPulsos)  -- L91: sin task.spawn — bloquea 2s por jugador
```

`wait()` puede acumular delays mayores bajo carga. `iniciarPulsos` se llama directamente (no en `task.spawn`) en el handler `PlayerAdded`, bloqueando la conexión 2 segundos por cada jugador nuevo.

**Corrección**: `task.wait(2)` y wrappear en `task.spawn`:
```lua
Players.PlayerAdded:Connect(function(p) task.spawn(iniciarPulsos, p) end)
```

---

### P2-9 — `RewardService.validateAndUnlockAchievements()` — `progress.dineroRestante` no existe

**Archivo**: `ServerScriptService/Services/RewardService.lua` líneas 312–317

`LevelService:getLevelProgress()` retorna `{nodesConnected, totalNodes, cablesPlaced, energized, completed}`. No incluye `dineroRestante`. El fallback en línea 316 accede a `player.leaderstats.Money` sin guardia (mismo problema que P1-4).

---

### P2-10 — `LevelService.getCables()` expone tabla interna sin copia defensiva

**Archivo**: `ServerScriptService/Services/LevelService.lua` líneas 258–262

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

Estos tres métodos están definidos pero nunca se llaman desde `Init.server.lua`. El manejo real de eventos se hace directamente en `GameplayEvents.server.lua`. Son dead code que podría confundir en mantenimiento.

---

### P2-12 — `Enums.Colors` — `Conectado` y `Energizado` tienen el mismo color

**Archivo**: `ReplicatedStorage/Shared/Enums.lua` líneas 13–14

```lua
Conectado = Color3.fromRGB(0, 255, 0),
Energizado = Color3.fromRGB(0, 255, 0),  -- idéntico
```

`GameplayEvents.server.lua` usa `BrickColor.new("Cyan")` para energizado, creando inconsistencia entre `Enums` y el código que aplica los colores.

---

### P2-13 — `AudioService` — volúmenes por defecto duplicados en `unmuteAll()`

**Archivo**: `ServerScriptService/Services/AudioService.lua`

Los valores `bgm = 0.5`, `sfx = 0.7`, `voice = 0.8`, `ambient = 0.3` aparecen dos veces: en la inicialización (líneas 14–19) y en `unmuteAll()` (líneas 223–227). Si se cambia un valor en un lugar, el otro queda desincronizado.

---

### P2-14 — `VisualizadorAlgoritmos` no usa `GraphUtils.getPostesFolder()`

**Archivo**: `ServerScriptService/Gameplay/VisualizadorAlgoritmos.server.lua` líneas 55–74

30 líneas de lógica propia que reinventa `GraphUtils.getPostesFolder()`. Incluye fallbacks hardcodeados a `"Nivel0_Tutorial"` y `"Nivel1"` que ignoran `"NivelActual"`.

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

### P2-16 — Doble reproducción de sonido al conectar cables

**Archivo**: `ServerScriptService/Gameplay/ConectarCables.server.lua` líneas 310–311

```lua
reproducirSonido(SOUND_CONNECT_NAME, att2)       -- llama AudioService:playSound()
if AudioService then AudioService:playCableConnected() end  -- también llama AudioService:playSound("CableConnect")
```

`reproducirSonido()` ya llama a `AudioService:playSound()` internamente. `playCableConnected()` llama a `playSound("CableConnect")` de nuevo. El sonido de conexión se reproduce **dos veces** en cada cable conectado.

**Corrección**: Eliminar una de las dos llamadas (preferiblemente `reproducirSonido()`).

---

### P2-17 — `_G.CompleteLevel` siempre sobreescribe `HighScore` aunque el nuevo sea menor

**Archivo**: `ServerScriptService/Base_Datos/ManagerData.lua` líneas 309–310

```lua
lvlData.HighScore = scoreObtained  -- sin comparar con valor previo
lvlData.Stars = starsObtained      -- sin comparar con valor previo
```

Si el jugador repite un nivel y obtiene menos puntos o estrellas que antes, el récord empeora. Viola el concepto de "high score".

**Corrección**:
```lua
lvlData.HighScore = math.max(lvlData.HighScore or 0, scoreObtained)
lvlData.Stars = math.max(lvlData.Stars or 0, starsObtained)
```

---

### P2-18 — `AudioService.stopAmbiance()` es un stub sin implementación

> **Nota**: Véase P1-6 para la descripción completa. Documentado aquí también para claridad del backlog de `AudioService`.

---

### P2-19 — `RewardService.debug()` — `#ACHIEVEMENTS` siempre imprime 0

**Archivo**: `ServerScriptService/Services/RewardService.lua` línea 456

```lua
print("Logros disponibles: " .. #ACHIEVEMENTS)
```

`ACHIEVEMENTS` es una tabla con claves string (no secuencial). `#ACHIEVEMENTS` en Lua retorna 0. El mensaje de debug siempre imprime `"Logros disponibles: 0"` aunque haya 9 logros definidos.

**Corrección**:
```lua
local n = 0; for _ in pairs(ACHIEVEMENTS) do n = n + 1 end
print("Logros disponibles: " .. n)
```

---

### P2-20 — `UIService.initializePlayerUI()` usa `task.wait(1)` sin `ServicesReady`

**Archivo**: `ServerScriptService/Services/UIService.lua` línea 398

```lua
function UIService:initializePlayerUI(player)
    task.wait(1)  -- Mismo antipatrón que P0-2
    self:updateLevelUI()
```

Aunque no bloquea el hilo principal (se llama dentro de un handler de PlayerAdded), retrasa la UI del nuevo jugador en 1 segundo de forma arbitraria. Se soluciona con el mecanismo `ServicesReady` de P0-2.

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
| DUP-7 | Doble `Players.PlayerAdded` para `MissionService:initializePlayer` | `MissionService.lua` (L142), `GameplayEvents.server.lua` (L218) | P2 |
| DUP-8 | Bloque `_refreshAndRestoreSelection` duplicado en `MatrixManager` | `MatrixManager.lua` (L573–600 y L638–665) | P2 |
| DUP-9 | `findPostes()` local en `MatrixManager` vs `GraphUtils.getPostesFolder()` | `MatrixManager.lua` (L490–498), `GraphUtils.lua` | P2 |
| DUP-10 | Constante `4 studs = 1 metro` hardcodeada | `ConectarCables.server.lua` (L192), `AlgorithmService.lua` (L208, 221), `GraphTheoryService.server.lua` (L156), `Algoritmos.lua` (L155) | P2 |
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

### AP-7 — `BloqueoService` cargado en disco pero no inicializado (Revisión 2)

`ServerScriptService/Services/BloqueoService.lua` existe en la carpeta pero `Init.server.lua` no lo carga con `loadService("BloqueoService")`. El servicio nunca se activa.

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
│                                           BindableEvents necesarios (incl. RestaurarObjetos);
│                                           eliminar listener duplicado RequestPlayLevel;
│                                           ser el único creador de Events/Remotes y Bindables;
│                                           cargar BloqueoService si se requiere
├── GestorEventos.server.lua   ← MODIFICAR: eliminar WaitForChild("RestaurarObjetos"), usar ServicesReady
├── ControladorEscenario.server.lua ← MODIFICAR: wait() → task.wait(), spawn iniciarPulsos
│                                               en PlayerAdded
├── Base_Datos/
│   └── ManagerData.lua        ← MODIFICAR: pcall en require(NivelUtils), eliminar refs a
│                                           funciones inexistentes de NivelUtils, centralizar
│                                           creación de Events/Remotes en Init,
│                                           math.max en CompleteLevel para HighScore/Stars
├── Gameplay/
│   ├── ConectarCables.server.lua      ← MODIFICAR: ServicesReady, eliminar doble sonido,
│   │                                               fix ClickDetector en RopeConstraint,
│   │                                               Enums.STUDS_PER_METER, Enums.CableColors
│   ├── GameplayEvents.server.lua      ← MODIFICAR: ServicesReady, Enums.CableColors
│   ├── GraphTheoryService.server.lua  ← MODIFICAR: ServicesReady, usar AliasUtils
│   │                                               en vez de safeGetNodeZone
│   ├── SistemaUI_reinicio.server.lua  ← MODIFICAR: ServicesReady, limpiar Conexiones en reset
│   └── VisualizadorAlgoritmos.server.lua ← MODIFICAR: fix var fallos,
│                                               GraphUtils.getPostesFolder,
│                                               ServicesReady (elimina WaitForChild bloqueante)
└── Services/
    ├── AlgorithmService.lua   ← MODIFICAR: fix firma dijkstra (.Name), reconstructPath real,
    │                                       GraphUtils.getDistance, unificar implementaciones
    ├── AudioService.lua       ← MODIFICAR: implementar stopAmbiance(), centralizar volúmenes
    ├── BloqueoService.lua     ← REGISTRAR en Init.server.lua si se necesita
    ├── EnergyService.lua      ← MODIFICAR: countKeys en findCriticalNodes,
    │                                       fix .Name en getEnergyCost/dijkstra
    ├── GraphService.lua       ← MODIFICAR: getConnectionCount → GraphUtils.degree,
    │                                       clearAllCables → destruir RopeConstraints,
    │                                       fix .Name en getDistances
    ├── InventoryService.lua   ← sin cambios
    ├── LevelService.lua       ← MODIFICAR: fix canConnect bidireccional, getCables copia
    │                                       defensiva, cablesPlaced con countKeys,
    │                                       require(LevelsConfig) al top-level
    ├── MissionService.lua     ← MODIFICAR: inyectar RewardService/UIService/AudioService/
    │                                       EnergyService via setDependencies,
    │                                       require GraphUtils al top-level,
    │                                       fix ARISTA_DIRIGIDA con claves orientadas
    ├── RewardService.lua      ← MODIFICAR: fix división por cero DineroInicial = 0,
    │                                       fix progress.dineroRestante, guardia leaderstats,
    │                                       fix #ACHIEVEMENTS en debug
    └── UIService.lua          ← MODIFICAR: eliminar código muerto onConnectionChanged etc.,
                                            countKeys para energized, alinear Enums.Colors,
                                            fix task.wait(1) en initializePlayerUI

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
│   ├── Zona4_dialogo.lua          ← REVISAR: ya existe — verificar si hereda bugs de Zona1-3
│   │                                           (boilerplate duplicado, naranja, getPos en Models)
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
| `GraphUtils.lua` | Modificar | ~~SPRINT~~ ✅ | Fix matriz dirigida completado; pendiente: `getDistance()` (P2-1), `buildAdjList()` |
| `GraphTheoryService.server.lua` | Modificar | P0 | ServicesReady, eliminar safeGetNodeZone → AliasUtils |
| `TableUtils.lua` | **Crear** | P1 | `countKeys()` — requerido por P1-1/2/3 |
| `Init.server.lua` | Modificar | P0 | `ServicesReady`, todos los BindableEvents (incl. RestaurarObjetos), eliminar listener duplicado RequestPlayLevel |
| `GameplayEvents.server.lua` | Modificar | P0 | ServicesReady |
| `GestorEventos.server.lua` | Modificar | P0 | Eliminar WaitForChild("RestaurarObjetos") bloqueante → ServicesReady |
| `VisualizadorAlgoritmos.server.lua` | Modificar | P0/P1 | Var `fallos` (P0-1), WaitForChild bloqueante (P0-5), usar GraphUtils.getPostesFolder |
| `GraphService.lua` | Modificar | P1 | `clearAllCables` destruir RopeConstraints (P1-12), `getDistances` fix .Name (P1-14), `getConnectionCount` → `GraphUtils.degree` |
| `EnergyService.lua` | Modificar | P1 | `countKeys` en `findCriticalNodes`, fix .Name en `getEnergyCost` (P1-14) |
| `LevelService.lua` | Modificar | P1 | `canConnect` bidireccional, `cablesPlaced` con `countKeys`, `require(LevelsConfig)` al top-level |
| `UIService.lua` | Modificar | P1 | `countKeys` para energized, eliminar código muerto, fix `task.wait(1)` en initializePlayerUI (P2-20) |
| `AudioService.lua` | Modificar | P1 | Implementar `stopAmbiance()` (P1-6), centralizar volúmenes (P2-13) |
| `AlgorithmService.lua` | Modificar | P1 | Firma dijkstra `.Name` (P1-8), `reconstructPath` real, `getDistance` |
| `RewardService.lua` | Modificar | P1/P2 | División por cero (P2-2), guardia `leaderstats` (P1-4), `dineroRestante` (P2-9), fix `#ACHIEVEMENTS` (P2-19) |
| `MissionService.lua` | Modificar | P1/P2 | Inyección completa de dependencias (P2-5), `require` al top-level (P2-6), fix `ARISTA_DIRIGIDA` (P1-15) |
| `ConectarCables.server.lua` | Modificar | P1/P2 | ServicesReady, fix ClickDetector en RopeConstraint (P1-13), eliminar doble sonido (P2-16) |
| `GestorEventos.server.lua` | Modificar | P1 | Eliminar polling → `ServicesReady` (P1-10) |
| `Zona1_dialogo.lua` | Modificar | P1 | `getPos()` en Model (P1-11), `SharedDialogConfig`, `ZoneDialogActivator` |
| `ControladorEscenario.server.lua` | Modificar | P2 | `wait()` → `task.wait()` (P2-8), spawn en `PlayerAdded` |
| `ManagerData.lua` | Modificar | P2 | `pcall` en require (P2-4), eliminar refs a funciones inexistentes (P2-3), `math.max` en HighScore (P2-17) |
| `MatrixManager.lua` | Modificar | P2 | `_refreshAndRestoreSelection()`, `AliasUtils`, `getPostesFolder`, eliminar `_G._matrixRefreshPending` |
| `Algoritmos.lua` | Modificar | P2 | Buscar `NivelActual` (P2-7), usar `GraphUtils.getDistance` |
| `LevelsConfig.lua` | Modificar | P2 | Deprecar `NombresPostes` |
| `Enums.lua` | Modificar | P2 | `STUDS_PER_METER`, `CableColors`, alinear `Conectado ≠ Energizado` (P2-12) |
| `Zona2_dialogo.lua` | Modificar | P2 | `SharedDialogConfig`, `ZoneDialogActivator` |
| `Zona3_dialogo.lua` | Modificar | P2 | Ídem + verificar naranja |
| `Zona4_dialogo.lua` | **Revisar** | P2 | Ya existe — auditar si tiene bugs de Zona1-3 |
| `Zona1_NodeFeedback.lua` | Modificar | P2 | `AliasUtils`, `DialogUtils.esperarKitLibre` |
| `NonAdjacentFeedback.lua` | Modificar | P2 | `DialogUtils.esperarKitLibre` |
| `SharedDialogConfig.lua` | **Crear** | P2 | Colores + cámara compartidos |
| `ZoneDialogActivator.lua` | **Crear** | P2 | Boilerplate activación de zona |
| `DialogUtils.lua` | **Crear** | P2 | `esperarKitLibre()`, `getPos(instance)` |
| `Constants.lua` | **Crear** | P2 | `STUDS_PER_METER`, `TIMEOUT_DEFAULT`, `MAX_LEVELS` |
| `NivelUtils.lua` | **Eliminar** | P2 | Supersedido por `AliasUtils` + `LevelService` |

---

## 9. Orden de Implementación Global

### Fase 0 — Correcciones de sprint (ya completadas) ✅

1. ~~Fix `GraphTheoryService.server.lua` — pasar `Adyacencias` al builder de matriz~~
2. ~~Fix `GraphUtils.getAdjacencyMatrix()` — parámetro opcional `adyacencias`~~
3. ~~Verificar `MatrixManager.calcularGrados()`~~

### Fase 1 — Bugs críticos (P0) ✅ COMPLETADA

4. ✅ Crear `ServicesReady` BindableEvent en `Init.server.lua` + reemplazar todos los `task.wait(1)` y WaitForChild bloqueantes
5. ✅ Crear **todos** los BindableEvents en `Init.server.lua`: `RestaurarObjetos`, `GuardarInventario`, `AristaConectada`, `DesbloquearObjeto`
6. ✅ Eliminar listener duplicado `RequestPlayLevel` de `Init.server.lua`
7. ✅ Fix `VisualizadorAlgoritmos` — var `fallos` → `cablesFaltantes`
8. ✅ Fix `GestorEventos` — reemplazar polling infinito + `WaitForChild("RestaurarObjetos")` bloqueante por `ServicesReady`

### Fase 2 — Bugs funcionales graves (P1)

9. Crear `TableUtils.lua` con `countKeys()`
10. Fix `GraphService.clearAllCables()` — destruir RopeConstraints físicos (P1-12)
11. Fix `LevelService.getLevelProgress()` — `countKeys(cables)`
12. Fix `UIService.updateEnergyStatus/updateProgress()` — `countKeys(energized)`
13. Fix `EnergyService.findCriticalNodes()` — `countKeys`
14. Fix `EnergyService.getEnergyCost()` y `GraphService.getDistances()` — pasar `.Name` a dijkstra (P1-14)
15. Fix `RewardService` — guardia `leaderstats`, división por cero
16. Fix `AudioService.stopAmbiance()` — implementación real
17. Fix `LevelService.canConnect()` — validar `B→A`
18. Fix `AlgorithmService` — firma dijkstra `.Name`, `reconstructPath` real
19. Exportar `GraphUtils.getDistance()`
20. Fix `Zona1_dialogo.lua` — `getPos()` en Model
21. Fix `ClickDetector en RopeConstraint` — mecanismo alternativo (P1-13)
22. Fix `MissionService.Validators.ARISTA_DIRIGIDA` — claves orientadas (P1-15)

### Fase 3 — Arquitectura y dependencias (P1/P2)

23. ✅ Eliminar polling de `GestorEventos` (cubierto por ServicesReady — resuelto en Fase 1)
24. Migrar `MissionService` a inyección completa de dependencias (P2-5)
25. `require GraphUtils` al top-level en `MissionService` (P2-6)
26. Fix `ManagerData` — `pcall` en `require(NivelUtils)`, `math.max` en HighScore (P2-17)
27. Fix `Algoritmos.lua` — buscar `NivelActual`, usar `GraphUtils.getDistance`
28. Fix `ControladorEscenario` — `wait()` → `task.wait()`, spawn en PlayerAdded
29. Fix doble sonido en `ConectarCables` (P2-16)
30. Fix `RewardService.debug()` — `#ACHIEVEMENTS` (P2-19)

### Fase 4 — Deduplicación y limpieza (P2)

31. Crear `Constants.lua` con `STUDS_PER_METER`, `TIMEOUT_DEFAULT`, `MAX_LEVELS`
32. Añadir `CableColors` y `STUDS_PER_METER` a `Enums.lua`, alinear colores (P2-12)
33. Centralizar `buildAdjList()` en `GraphUtils`, eliminar duplicación DUP-17
34. `GraphService.getConnectionCount` → `GraphUtils.degree`
35. Extraer `_refreshAndRestoreSelection()` en `MatrixManager` + usar `AliasUtils`
36. Crear `SharedDialogConfig.lua` + `ZoneDialogActivator.lua` + `DialogUtils.lua`
37. Migrar `Zona1/2/3_dialogo.lua` a módulos compartidos
38. Auditar y corregir `Zona4_dialogo.lua` (ya existe, puede heredar bugs)
39. Eliminar `NivelUtils.lua` (verificar consumidores antes con Grep)
40. Deprecar `NombresPostes` en `LevelsConfig.lua`
41. Registrar/auditar `BloqueoService.lua` (AP-7)

---

## 10. Tests Post-Refactorización

| Test | Criterio de éxito |
|---|---|
| Zona 1 (no dirigido) — matriz | `M[i][j] == M[j][i]` para todos los nodos conectados ✅ |
| Zona 3 (dirigido) — matriz | `M[X][Y] = peso` y `M[Y][X] = 0` cuando solo existe `X→Y` ✅ |
| MatrixManager — grados en dígrafo | Grado entrada ≠ grado salida para nodos asimétricos ✅ |
| Tutorial (Nivel 0) — recompensas | Completar sin producir `NaN`; el jugador recibe recompensas exactamente una vez |
| `findCriticalNodes` | Crear nodo puente manualmente → aparece en la lista retornada |
| `AlgorithmService.executeDijkstra` | El camino reconstruido contiene nodos intermedios, no solo `{inicio, fin}` |
| `canConnect` bidireccional | Zona 3: arista en sentido correcto → aceptada; sentido inverso → rechazada |
| `ServicesReady` | En Studio Output, todos los scripts dependientes imprimen sus servicios correctamente sin errores en los primeros 3 segundos |
| Progreso de nivel | `CablesPlaced` y `NodesEnergized` muestran valores > 0 cuando hay cables conectados |
| Recompensas únicas | Completar un nivel otorga dinero/XP/estrellas exactamente una vez (sin duplicados) |
| Diálogo de Zona 1 | La escena de cámara en postes no lanza error de `.Position` en un Model |
| Reset de nivel | Después de reiniciar, los cables visuales (RopeConstraints) desaparecen del nivel |
| Click en cable | El cable responde al click del jugador para desconectarse (nuevo mecanismo) |
| Desconexión única | Al conectar un cable, el sonido CableConnect se reproduce **una sola vez** |
| HighScore acumulativo | Completar un nivel con menor puntaje no reduce el récord anterior |
| Dijkstra (energía) | `EnergyService:getEnergyCost()` retorna distancias reales (no tabla vacía) |
| ARISTA_DIRIGIDA | La misión solo se completa si la conexión va en el sentido configurado |
