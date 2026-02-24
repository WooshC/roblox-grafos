# Guía de Refactorización — roblox-grafos

> **Propósito**: Documento de trabajo que describe el bug de la matriz, las duplicaciones de código encontradas y las acciones concretas a tomar (crear, modificar, eliminar). No contiene cambios de código todavía.

---

## Tabla de contenido

1. [Bug crítico — Matriz no distingue grafos dirigidos/no dirigidos](#1-bug-crítico--matriz-no-distingue-grafos-dirigidosno-dirigidos)
2. [Duplicación de código](#2-duplicación-de-código)
3. [Archivos a modificar](#3-archivos-a-modificar)
4. [Archivos a crear](#4-archivos-a-crear)
5. [Archivos a eliminar o deprecar](#5-archivos-a-eliminar-o-deprecar)
6. [Resumen de cambios por archivo](#6-resumen-de-cambios-por-archivo)

---

## 1. Bug crítico — Matriz no distingue grafos dirigidos/no dirigidos

### Síntoma

En la Zona 3 (Grafos Dirigidos), la matriz de adyacencia muestra `1` en ambas celdas `A[i][j]` y `A[j][i]` aunque la arista sea unidireccional (`X → Y` pero no `Y → X`). La matriz aparece siempre simétrica, lo que es correcto solo para grafos no dirigidos.

### Causa raíz — cadena de responsabilidades

El problema tiene **tres focos** encadenados:

#### Foco 1 — `GraphUtils.lua : getCableKey()` (línea 272)

```lua
-- ACTUAL (siempre ordena alfabéticamente → trata todo como no-dirigido)
if nameA < nameB then
    return nameA .. "_" .. nameB
else
    return nameB .. "_" .. nameA
end
```

La clave aplana la dirección. Si existe `X→Y`, la clave es `Nodo1_z3_Nodo2_z3`. Si luego se consulta `Y→X`, la misma clave existe, lo que hace parecer que la conexión es bidireccional.

> La clave simétrica es correcta para **almacenar** cables físicos (el cable es un objeto único), pero **no** para consultar si una arista dirigida va en determinado sentido.

#### Foco 2 — `GraphUtils.lua : getAdjacencyMatrix()` (línea 362)

```lua
-- ACTUAL (siempre pone 1 en ambas direcciones → siempre simétrico)
matrix[idxA][idxB] = 1
matrix[idxB][idxA] = 1
```

Sin importar si la conexión es dirigida, rellena ambas celdas. Nunca consulta si la arista tiene una sola dirección.

#### Foco 3 — `GraphTheoryService.server.lua : getAdjacencyMatrix()` (línea 145)

```lua
-- ACTUAL (delega en areConnected, que tampoco sabe de dirección)
if GraphUtils.areConnected(nodeA, nodeB, cables) then
    matrix[i][j] = ...   -- pone peso en ambas direcciones (líneas 147-148)
```

Aunque aquí se calcula el peso con la distancia, el valor se escribe igualmente para `matrix[i][j]` y `matrix[j][i]`.

### Información disponible para resolver el bug

`LevelsConfig[0].Adyacencias` ya codifica correctamente la direccionalidad:

```lua
-- Zona 3: cadena X → Y → Z (no existe vuelta)
["Nodo1_z3"] = {"Nodo2_z3"},   -- X puede ir a Y
["Nodo2_z3"] = {"Nodo3_z3"},   -- Y puede ir a Z
["Nodo3_z3"] = {},             -- Z no puede ir a ninguno
```

Para una arista entre nodos A y B, la dirección se determina así:

| `Adyacencias[A]` contiene B | `Adyacencias[B]` contiene A | Interpretación          | Celda a rellenar          |
|---|---|---|---|
| ✅ | ✅ | No dirigido / bidireccional | `M[A][B] = 1` y `M[B][A] = 1` |
| ✅ | ❌ | Dirigido: A → B | Solo `M[A][B] = 1`        |
| ❌ | ✅ | Dirigido: B → A | Solo `M[B][A] = 1`        |
| ❌ | ❌ | Sin Adyacencias definidas   | Tratar como bidireccional |

### Plan de corrección

**Paso 1** — `GraphTheoryService.server.lua`

Obtener `config.Adyacencias` desde `LevelService:getLevelConfig()` y pasárselo a la función que construye la matriz. Al iterar los cables, consultar la tabla de adyacencias para decidir cuántas celdas llenar:

```
Para cada cable (nodeA ↔ nodeB):
  puedeIr_AB = Adyacencias[A.Name] contiene B.Name
  puedeIr_BA = Adyacencias[B.Name] contiene A.Name

  si puedeIr_AB  → matrix[idx_A][idx_B] = peso
  si puedeIr_BA  → matrix[idx_B][idx_A] = peso
  si ninguno definido → ambas celdas = peso   (fallback)
```

**Paso 2** — `GraphUtils.lua : getAdjacencyMatrix()`

Añadir un parámetro opcional `adyacencias` (la tabla de `LevelsConfig`). Si se provee, usar la misma lógica del Paso 1. Si no se provee (uso genérico), mantener el comportamiento actual (bidireccional).

**Paso 3** — `MatrixManager.lua : calcularGrados()`

La función ya detecta si la matriz es un dígrafo comparando `matrix[r][c]` con `matrix[c][r]`. Una vez que el servidor envíe la matriz correctamente asimétrica, esta detección funcionará sin cambios. Sin embargo, hay que verificar que el cálculo de `gTotal` para no-dígrafos es `gEntrada` (no `gEntrada + gSalida`), lo cual ya está implementado correctamente:

```lua
local gTotal = esDigrafo and (gEntrada + gSalida) or gEntrada
```

---

## 2. Duplicación de código

### 2.1 `CONFIG.COLORES` — idéntico en los tres archivos de diálogo de zona

Los tres archivos (`Zona1_dialogo.lua`, `Zona2_dialogo.lua`, `Zona3_dialogo.lua`) definen exactamente la misma paleta de colores:

```lua
COLORES = {
    azul        = Color3.fromRGB(0, 170, 255),
    verde       = Color3.fromRGB(0, 255, 0),
    rojo        = Color3.fromRGB(255, 0, 0),
    amarillo    = Color3.fromRGB(255, 255, 0),
    naranja     = Color3.fromRGB(255, 165, 0),   -- Zona2 usa 165, Zona3 usa 140
    verde_debil = Color3.fromRGB(100, 200, 100),
}
```

> Zona3 tiene un valor ligeramente diferente para `naranja` (140 vs 165). Al centralizar hay que normalizar o exponer ambas variantes.

### 2.2 `CONFIG.CAMARA` — offsets idénticos en Zona2 y Zona3

Zona1 define offsets distintos (tiene nombres distintos), pero Zona2 y Zona3 comparten:

```lua
CAMARA = {
    offset_alto  = Vector3.new(18, 40, 18),
    offset_medio = Vector3.new(12, 28, 12),
    offset_cerca = Vector3.new(10, 20, 10),
    duracion     = 1.5,
}
```

### 2.3 Boilerplate de activación de diálogo — idéntico en los tres archivos de zona

Las tres zonas repiten este bloque (con nombres distintos solo en los prints):

```lua
local yaSeMostro = false

local function checkZone(newZone)
    if yaSeMostro then return end
    if newZone ~= CONFIG.ZONA_OBJETIVO then return end
    local player = game.Players.LocalPlayer
    if not player.Character then return end
    yaSeMostro = true
    -- ... iniciar diálogo ...
end

local player = game.Players.LocalPlayer
player:GetAttributeChangedSignal("CurrentZone"):Connect(function()
    checkZone(player:GetAttribute("CurrentZone"))
end)
task.delay(1, function()
    local zona = player:GetAttribute("CurrentZone")
    if zona then checkZone(zona) end
end)
```

También existe diferencia menor: `Zona1_dialogo.lua` pasa `OnClose` a `CreateDialogue`, pero `Zona2_dialogo.lua` y `Zona3_dialogo.lua` no lo hacen (el cleanup va en `Cierre_Z#.Evento`). Esta inconsistencia también debe unificarse.

### 2.4 `MatrixManager.lua` — lógica de refresco post-conexión duplicada

El mismo bloque de código aparece dos veces dentro de `MatrixManager.initialize()`: una vez en el handler de `CableDragEvent "Stop"` (líneas ~579–600) y otra vez en el handler de `NotificarSeleccionNodo "ConexionCompletada"` (líneas ~638–665):

```lua
-- (duplicado A)  Stop → refrescar + mantener selección
local nodoSeleccionadoNombre = ...
task.delay(0.3, function()
    MatrixManager.refrescar()
    task.wait(0.1)
    if nodoSeleccionadoNombre and matrizData ... then
        local nuevoIdx = getHeaderIdx(nodoSeleccionadoNombre)
        if nuevoIdx then
            ...actualizarInfoNodo / resaltarEnMatriz...
        else
            ...limpiar...
        end
    end
end)

-- (duplicado B)  ConexionCompletada → misma lógica exacta
```

### 2.5 `MatrixManager.lua : getAlias()` — reimplementa `AliasUtils.getNodeAlias()`

`MatrixManager.lua` define su propia función `getAlias()` (línea 29) que hace exactamente lo mismo que `AliasUtils.getNodeAlias()` de `ReplicatedStorage/Utilidades/AliasUtils.lua`.

### 2.6 `LevelsConfig.lua` — `NombresPostes` duplica `Nodos[name].Alias`

Cada nivel tiene dos tablas que almacenan el mismo nombre visible de cada nodo:

```lua
Nodos = {
    ["Nodo1_z1"] = { Alias = "Nodo 1", ... },
    ...
}
NombresPostes = {
    ["Nodo1_z1"] = "Nodo 1",   -- ← mismo dato
    ...
}
```

`AliasUtils.getNodeAlias()` ya tiene un fallback a `NombresPostes` para compatibilidad histórica. Una vez que todo el código usa `Nodos[name].Alias`, `NombresPostes` puede eliminarse.

### 2.7 `GraphService : getConnectionCount()` — duplica `GraphUtils.degree()`

```lua
-- GraphService (línea 147)
function GraphService:getConnectionCount(node)
    local count = 0
    for key, cable in pairs(cables) do
        if cable.nodeA == node or cable.nodeB == node then
            count = count + 1
        end
    end
    return count
end

-- GraphUtils (línea 141)
function GraphUtils.degree(nodeName, cables)
    local count = 0
    for _, info in pairs(cables) do
        if info.nodeA.Name == nodeName or info.nodeB.Name == nodeName then
            count = count + 1
        end
    end
    return count
end
```

### 2.8 `GraphUtils` — construcción de lista de adyacencia inline en BFS y DFS

`GraphUtils.bfs()` y `GraphUtils.dfs()` construyen la misma tabla `adj` interna (iterando cables para construir `adj[nA] → {nB}`) sin compartir esa lógica:

```lua
-- En bfs() y dfs() aparece exactamente esto:
local adj = {}
for _, info in pairs(cables) do
    local nA = info.nodeA.Name
    local nB = info.nodeB.Name
    if not adj[nA] then adj[nA] = {} end
    if not adj[nB] then adj[nB] = {} end
    table.insert(adj[nA], nB)
    table.insert(adj[nB], nA)
end
```

### 2.9 `GraphTheoryService.server.lua : safeGetNodeZone()` — reimplementa lógica ya existente

`GraphTheoryService` define internamente `safeGetNodeZone()` (línea 78) que primero intenta llamar a `NivelUtils.getNodeZone()` y si falla reescribe la lógica manualmente. Esta misma funcionalidad existe en `AliasUtils.getNodeZone()` sin posibilidad de fallo.

---

## 3. Archivos a modificar

### `ReplicatedStorage/Shared/Utils/GraphUtils.lua`

- **`getAdjacencyMatrix(nodes, cables [, adyacencias])`**: Añadir parámetro opcional `adyacencias`. Cuando esté presente, usar la tabla para determinar la dirección de cada arista en lugar de siempre poner `matrix[i][j] = 1` y `matrix[j][i] = 1`.
- **`buildAdjList(cables)`**: Extraer la construcción de la lista de adyacencia a una función privada reutilizable por `bfs()`, `dfs()` y `dijkstra()` para eliminar la duplicación 2.8.

### `ServerScriptService/Gameplay/GraphTheoryService.server.lua`

- **`getAdjacencyMatrix(player, zonaID)`**: Obtener `config.Adyacencias` del nivel y usarla al construir la matriz para soportar aristas dirigidas (corrección del bug 1).
- **Eliminar `safeGetNodeZone()`**: Reemplazar con `AliasUtils.getNodeZone()` (ya está disponible via `require`).

### `StarterPlayer/.../MatrixManager.lua`

- **Extraer helper `_refreshAndRestoreSelection()`**: Consolidar las dos apariciones idénticas del bloque de refresco post-conexión (duplicación 2.4) en una función privada.
- **Reemplazar `getAlias()`**: Eliminar la función local y usar `AliasUtils.getNodeAlias()` directamente (duplicación 2.5). Requiere añadir `AliasUtils` a las dependencias.

### `ServerScriptService/Services/GraphService.lua`

- **`getConnectionCount(node)`**: Reemplazar el bucle manual con una llamada a `GraphUtils.degree(node.Name, cables)` (duplicación 2.7).

### `StarterGUI/DialogStorage/Zona1_dialogo.lua`

- **Extraer colores y offsets compartidos** hacia un módulo centralizado (duplicaciones 2.1, 2.2).
- **Extraer boilerplate de activación** hacia una función o módulo compartido (duplicación 2.3).
- **Unificar patrón de cleanup**: Zona1 usa `OnClose` callback, el resto usa `Cierre_Zn.Evento`. Elegir uno y aplicarlo consistentemente.

### `StarterGUI/DialogStorage/Zona2_dialogo.lua`

- Mismos cambios que Zona1 para colores, cámara y boilerplate de activación.

### `StarterGUI/DialogStorage/Zona3_dialogo.lua`

- Mismos cambios que Zona1/2 para colores, cámara y boilerplate.
- Verificar valor de `naranja` al normalizar (actualmente RGB 255, 140, 0 vs 255, 165, 0 en Zona2).

### `ReplicatedStorage/LevelsConfig.lua`

- **Deprecar `NombresPostes`**: Marcar con comentario `-- @deprecated usar Nodos[name].Alias`. Una vez que nadie la consuma, eliminarla en el siguiente paso.

---

## 4. Archivos a crear

### `StarterGUI/DialogStorage/SharedDialogConfig.lua`

Módulo que exporte la configuración compartida entre diálogos de zona:

```
SharedDialogConfig = {
    COLORES = {
        azul, verde, rojo, amarillo, naranja, naranja_fuerte, verde_debil, cian
    },
    CAMARA = {
        offset_alto, offset_medio, offset_cerca, duracion
    },
    SKIN_NAME = "Hotline",
}
```

Cada archivo de zona haría `require(SharedDialogConfig)` en lugar de redefinir estas tablas.

### `StarterGUI/DialogStorage/ZoneDialogActivator.lua`

Módulo que encapsula el patrón de activación de diálogo:

```
ZoneDialogActivator.init(config, onActivate)
  -- Crea la variable yaSeMostro internamente
  -- Registra el listener de CurrentZone
  -- Registra el task.delay(1, ...) de comprobación inicial
  -- Llama a onActivate() cuando la zona coincide con config.ZONA_OBJETIVO
```

Cada zona llama solo `ZoneDialogActivator.init(CONFIG, function() ... end)` y desaparece el boilerplate repetido.

---

## 5. Archivos a eliminar o deprecar

### `ReplicatedStorage/Utilidades/NivelUtils.lua`

Actualmente es el único módulo que `GraphTheoryService` intenta llamar con `NivelUtils.getNodeZone()`, pero cuando falla cae en código duplicado. `AliasUtils.lua` ya ofrece `getNodeAlias`, `getNodeZone`, `getNodesInZone` y más. Una vez que `GraphTheoryService` migre a `AliasUtils`, `NivelUtils` puede eliminarse siempre que no tenga otros consumidores.

> **Verificar** con `Grep` si algún otro archivo usa `NivelUtils` antes de eliminar.

### `NombresPostes` en `LevelsConfig`

No es un archivo independiente sino una tabla dentro de `LevelsConfig.lua`. Una vez que `MatrixManager` y cualquier otro consumidor usen exclusivamente `Nodos[name].Alias` (a través de `AliasUtils`), la tabla `NombresPostes` puede borrarse de cada entrada de nivel.

---

## 6. Resumen de cambios por archivo

| Archivo | Acción | Motivo |
|---|---|---|
| `GraphUtils.lua` | Modificar | Soporte de grafos dirigidos en `getAdjacencyMatrix()`; extraer `buildAdjList()` |
| `GraphTheoryService.server.lua` | Modificar | Pasar `Adyacencias` al builder de matriz; eliminar `safeGetNodeZone()` |
| `MatrixManager.lua` | Modificar | Deduplicar bloque de refresco; usar `AliasUtils` |
| `GraphService.lua` | Modificar | Delegar `getConnectionCount()` a `GraphUtils.degree()` |
| `Zona1_dialogo.lua` | Modificar | Centralizar colores, cámara y activación |
| `Zona2_dialogo.lua` | Modificar | Centralizar colores, cámara y activación |
| `Zona3_dialogo.lua` | Modificar | Centralizar colores, cámara y activación; verificar `naranja` |
| `LevelsConfig.lua` | Modificar | Deprecar `NombresPostes` |
| `SharedDialogConfig.lua` | **Crear** | Paleta de colores y offsets de cámara compartidos |
| `ZoneDialogActivator.lua` | **Crear** | Patrón de activación de diálogo sin boilerplate |
| `NivelUtils.lua` | **Eliminar** (verificar consumidores) | Supersedido por `AliasUtils.lua` |

---

## Notas adicionales

- **Orden de implementación sugerido**: Empezar por el bug de la matriz (sección 1) ya que es el único cambio funcional. El resto son refactorizaciones que no alteran el comportamiento observado.
- **`Zona4_dialogo.lua`** no existe aún. Al crearlo, usar desde el inicio `SharedDialogConfig` y `ZoneDialogActivator` para no volver a introducir la deuda.
- **Tests manuales post-fix de matriz**: Verificar en Zona 2 (no dirigido) que la matriz sigue siendo simétrica. Verificar en Zona 3 (dirigido) que `M[X][Y] = peso` pero `M[Y][X] = 0` cuando solo existe la arista X→Y.
