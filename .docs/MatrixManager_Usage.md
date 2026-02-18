# MatrixManager - Guía de Uso

## Características Principales

### 1. Tamaño de Celda Configurable
El tamaño de celda ahora es configurable con un mínimo de **10px**.

**Por defecto**: Al activar el modo matemático, el tamaño de celda se establece en **10px** para una vista más compacta.

#### Cambiar el tamaño de celda dinámicamente:

```lua
-- Desde cualquier script cliente que tenga acceso a MatrixManager
local MatrixManager = require(Services:WaitForChild("MatrixManager"))

-- Configurar tamaño de celda a 20px
MatrixManager.setCellSize(20)

-- Configurar tamaño de celda a 10px (mínimo)
MatrixManager.setCellSize(10)

-- Configurar tamaño de celda a 48px (tamaño original)
MatrixManager.setCellSize(48)
```

### 2. Modo Mapa en Modo Matemático
Ahora puedes usar el **mapa** mientras estás en **modo matemático**:

- ✅ El minimapa permanece visible
- ✅ Los botones de Mapa y Misiones están disponibles
- ✅ Puedes abrir el mapa completo con el botón "Mapa"
- ✅ Al seleccionar nodos en el mapa, se resaltan automáticamente en la matriz

### 3. Sincronización Mapa ↔ Matriz
Cuando seleccionas nodos en el mapa:

1. **Primer click**: El nodo se resalta en amarillo en la matriz
2. **Segundo click**: Se conectan los nodos y la matriz se actualiza automáticamente
3. **Click en el mismo nodo**: Se cancela la selección

### 4. Actualización en Tiempo Real
La matriz se actualiza automáticamente cuando:

- ✅ Cambias de zona
- ✅ Conectas o desconectas cables (en modo normal o mapa)
- ✅ Seleccionas un nodo en el mundo 3D
- ✅ Seleccionas un nodo en el mapa

### 5. Información del Nodo Seleccionado
Al seleccionar un nodo (en 3D o en el mapa), se muestra:

- **Nombre del nodo** (alias legible)
- **Grado total**: Número total de conexiones
- **Grado de entrada**: Número de aristas que llegan al nodo
- **Grado de salida**: Número de aristas que salen del nodo

## Ejemplo de Uso Completo

```lua
-- En GUIExplorador.lua o cualquier script cliente

-- 1. Activar modo matemático
ButtonManager:CambiarModo("MATEMATICO")

-- 2. Configurar tamaño de celda personalizado (opcional)
MatrixManager.setCellSize(15)  -- 15px por celda

-- 3. Abrir el mapa (ahora disponible en modo matemático)
MapManager:toggle()

-- 4. Seleccionar nodos en el mapa
-- Los nodos se resaltarán automáticamente en la matriz

-- 5. Volver a modo visual
ButtonManager:CambiarModo("VISUAL")
```

## Configuración por Nivel

Si quieres configurar diferentes tamaños de celda para diferentes niveles, puedes agregar esto en `LevelsConfig.lua`:

```lua
LevelsConfig[0] = {
    -- ... otras configuraciones ...
    MatrixCellSize = 10,  -- Tamaño de celda para este nivel
}
```

Y luego en `MatrixManager.activar()`:

```lua
local config = LevelsConfig[player:GetAttribute("CurrentLevelID") or 0]
local cellSize = config and config.MatrixCellSize or 10
MatrixManager.setCellSize(cellSize)
```

## Notas Técnicas

- **Mínimo**: 10px (más pequeño puede hacer ilegible el texto)
- **Máximo**: Sin límite, pero 48px es el tamaño original
- **Recomendado**: 10-20px para matrices grandes, 30-48px para matrices pequeñas
