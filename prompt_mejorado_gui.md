# PROMPT MEJORADO: Sistema de Modos GUI para Juego de Teoría de Grafos

## 🎯 CONTEXTO DEL PROYECTO

**Juego educativo 3D sobre teoría de grafos en Roblox**

Estado actual:
- ✅ **GraphService** centralizado: gestiona nodos, cables, eventos de cambios
- ✅ **LevelService**: carga/descarga niveles, acceso a configuración (LevelConfig)
- ✅ **EnergyService**: calcula nodos energizados mediante BFS
- ✅ **AlgorithmService**: ejecuta algoritmos paso a paso
- ✅ **GraphUtils**: utilidades de búsqueda (BFS, DFS, Dijkstra), matriz de adyacencia
- ✅ **UIService**: base para actualización de UI (necesita refactorización para modos)
- ✅ **EventBus en ReplicatedStorage.Events.Remotes/Bindables**

**Arquitectura cliente-servidor:**
- Server: ServerScriptService/Services/*.lua
- Client: LocalScripts en StarterGui/StarterPlayer
- Eventos: RemoteEvents/RemoteFunctions en ReplicatedStorage.Events.Remotes

---

## 📋 ESPECIFICACIÓN DE MODOS GUI

### 1️⃣ MODO VISUAL (Construction Mode)
**Objetivo:** Exploración y construcción libre del grafo en 3D

**Interfaz visible:**
- HUD superior izquierda: Contador de conexiones realizadas
- Minimapa dinámica (esquina inferior derecha)
  - Muestra nodos como puntos
  - Cables como líneas conectantes
  - Actualización en tiempo real
  - Zoom/Pan opcional

**Comportamiento:**
- Jugador mueve libremente en 3D (movimiento normal)
- Click en nodo: se resaltan visualmente los nodos adyacentes permitidos (según LevelConfig)
  - Colores: Verde (válidos), Gris (inválidos)
  - Distancia visual u otro efecto (partículas, aura, outline)
- Drag entre dos nodos válidos: crea conexión
- No se muestra matriz de adyacencia
- No se ejecutan algoritmos
- Minimapa se actualiza al crear/borrar cables

**Requisitos técnicos:**
- Sistema de resaltado visual (Material color change, Transparency, Particles)
- Observador de cambios en GraphService (onCableAdded, onCableRemoved)
- Renderización del minimapa dinámico
- Sincronización bidireccional: clic 3D ↔ selección visual

---

### 2️⃣ MODO MATEMÁTICO (Matrix Mode)
**Objetivo:** Representación formal del grafo con matriz de adyacencia dinámica

**Interfaz visible:**
- Panel lateral tipo HUD derecha (ancho ~400px, altura completa pantalla)
  - Sección 1: Información nodo seleccionado
    - Nombre, grado, entrada, salida
    - Vecinos listados
  - Sección 2: Matriz de adyacencia NxN
    - Scroll si es necesario
    - Filas y columnas con headers (nombres de nodos)
    - Valores: 0 o peso (distancia en studs)
- Fondo 3D completamente visible y jugable

**Comportamiento:**
- Toda la lógica del MODO VISUAL se mantiene
- Click en nodo en 3D:
  - Se resalta su fila Y columna en la matriz
  - Panel muestra información del nodo
- Drag cable en 3D:
  - Celda correspondiente [i,j] cambia de 0 a peso con animación
  - Anima cambio de color (rojo → verde gradualmente)
  - Se actualiza grado del nodo
- Drag para borrar cable:
  - Celda vuelve a 0 con animación inversa
- Cambio de nodo seleccionado:
  - Resaltado anterior desaparece
  - Nuevo resaltado aparece con transición suave

**Requisitos técnicos:**
- Generación dinámica de matriz según #nodos
- Observador de GraphService que actualiza celdas
- Sistema de sincronización bidireccional (selección 3D ↔ fila/columna resaltada)
- Animación de transición de color en celdas
- Cálculo en tiempo real de grado, entrada, salida

---

### 3️⃣ MODO ANÁLISIS (Analysis Mode)
**Objetivo:** Ejecución paso a paso de algoritmo con interfaz centralizada

**Interfaz visible:**
- Fondo 3D oscurecido (oscuro pero visible, ~0.3 opacidad)
- Panel central grande (centrado en pantalla):
  ```
  ┌─────────────────────────────────┐
  │   ALGORITMO: BFS                │
  ├─────────────────────────────────┤
  │  Minimap | Nodo actual          │
  │  (pequeño)| Grado: X            │
  │          | Entrada: X           │
  ├─────────────────────────────────┤
  │  COLA: [A, B, C]                │
  │  VISITADOS: [A, B]              │
  │  DISTANCIAS: A(0), B(1), C(2)   │
  ├─────────────────────────────────┤
  │  Matriz resaltando nodo actual  │
  │  (versión reducida o tooltip)   │
  ├─────────────────────────────────┤
  │  [← Anterior] [Siguiente →]     │
  │  [Reiniciar] [Salir]            │
  └─────────────────────────────────┘
  ```

**Comportamiento:**
- Jugador NO puede moverse libremente
- Click "Siguiente paso":
  - AlgorithmService genera siguiente estado
  - Se visualiza en 3D:
    - Nodo actual: brilla (color distincto)
    - Nodos visitados: color fijo (ej. naranja)
    - Camino actual: cables destacados
  - Panel actualiza: cola, visitados, distancias
  - Matriz resalta nodo actual
  - Puntos se calculan según coincidencia con solución esperada
- Click "Anterior":
  - Retrocede a estado previo (si existe historial)
  - Deshace visualización anterior
- Click "Reiniciar":
  - Vuelve al inicio del algoritmo
- Click "Salir":
  - Vuelve a MODO VISUAL
  - Se muestra puntuación final

**Requisitos técnicos:**
- Motor de simulación independiente (AlgorithmSimulator)
- Historial de estados para retroceso (stack de estados)
- Validación de pasos (comparar con solución óptima)
- Sistema de puntuación dinámico
- Sincronización visual 3D ↔ panel información
- Resaltado de nodos/cables según estado del algoritmo

---

## 🏗️ ARQUITECTURA PROPUESTA

### Carpeta Structure
```
ServerScriptService/
├── Services/
│   ├── GraphService.lua          [✅ Existe - Sin cambios]
│   ├── UIService.lua              [⚠️ Refactorizar para modos]
│   ├── ModeManager.lua            [🆕 Orquestar cambios de modo]
│   ├── VisualModeService.lua      [🆕 Lógica MODO VISUAL]
│   ├── MatrixModeService.lua      [🆕 Lógica MODO MATEMÁTICO]
│   ├── AnalysisModeService.lua    [🆕 Lógica MODO ANÁLISIS]
│   ├── AlgorithmSimulator.lua     [🆕 Motor independiente de algoritmo]
│   └── ... (otros servicios existentes)
│
└── Utils/
    ├── EventFactory.lua           [🆕 Factory centralizado de eventos]
    └── HistoryManager.lua         [🆕 Gestión de historial para retroceso]

StarterGui/
└── Modos/
    ├── VisualMode/
    │   ├── UI.lua                 [🆕 Script cliente para VISUAL]
    │   ├── Minimap.lua            [🆕 Renderización minimapa]
    │   └── NodeHighlighter.lua    [🆕 Resaltado de nodos]
    │
    ├── MatrixMode/
    │   ├── UI.lua                 [🆕 Script cliente para MATRIZ]
    │   ├── MatrixRenderer.lua     [🆕 Generación dinámico matriz]
    │   ├── MatrixAnimator.lua     [🆕 Animaciones de celdas]
    │   └── InfoPanel.lua          [🆕 Panel información nodo]
    │
    └── AnalysisMode/
        ├── UI.lua                 [🆕 Script cliente para ANÁLISIS]
        ├── AlgorithmPanel.lua     [🆕 Panel central con información]
        ├── Visualizer.lua         [🆕 Resaltado algoritmo en 3D]
        └── Scoreboard.lua         [🆕 Sistema de puntos]
```

### Flujo de Eventos

```
Modo Actual: VISUAL
     │
     ├─ Jugador click nodo
     │   └─ VisualModeService:selectNode()
     │       └─ Emite "NodeSelected" 
     │           └─ GraphService recibe → resalta vecinos
     │
     ├─ Jugador arrastra cable
     │   └─ VisualModeService:createConnection()
     │       └─ GraphService:connectNodes()
     │           ├─ Emite "CableAdded"
     │           ├─ UIService actualiza minimapa
     │           └─ MatrixModeService (escucha inactivo) actualiza matriz interna
     │
     └─ Jugador presiona "Ir a Análisis"
         └─ ModeManager:switchMode("ANALYSIS")
             ├─ VisualModeService:cleanup()
             ├─ AnalysisModeService:init()
             │   ├─ AlgorithmSimulator:initialize(startNode)
             │   ├─ AnalysisModeService emite "AnalysisStarted"
             │   └─ Cliente renderiza panel central
             └─ Fondo 3D oscurecido
```

### Estado Global (GraphState + ModeState)

```lua
-- Server: Compartido a través de servicios
GraphState = {
    nodes = GraphService:getNodes(),           -- Array
    cables = GraphService:getCables(),         -- Table { key = {nodeA, nodeB} }
    selectedNode = nil,                        -- Instance
    currentLevel = LevelService:getCurrentLevel(),
    levelConfig = LevelService:getLevelConfig()
}

-- Server: ModeManager mantiene
ModeState = {
    currentMode = "VISUAL",  -- "VISUAL" | "MATRIX" | "ANALYSIS"
    previousMode = nil,
    modeData = {
        [VISUAL] = { selectedNode = nil, highlightedNeighbors = {} },
        [MATRIX] = { selectedNode = nil, highlightedRow = nil, highlightedCol = nil },
        [ANALYSIS] = { 
            algorithmType = "BFS", 
            currentStep = 0, 
            queue = {}, 
            visited = {}, 
            distances = {},
            score = 0
        }
    }
}
```

---

## 🔌 Patrón Observer + EventBus

**EventBus centralizado en ReplicatedStorage.Events:**

```
Remotes (RemoteEvents para Cliente ↔ Servidor):
├── RequestMode(modeName)          -- Cliente → Servidor (cambiar modo)
├── SelectNode(nodeName)           -- Cliente → Servidor (seleccionar nodo)
├── CreateConnection(nodeA, nodeB) -- Cliente → Servidor (crear cable)
├── DeleteConnection(nodeA, nodeB) -- Cliente → Servidor (eliminar cable)
├── NextAlgorithmStep()            -- Cliente → Servidor (siguiente paso)
├── PreviousAlgorithmStep()        -- Cliente → Servidor (paso anterior)
└── GetCurrentState()              -- Cliente → Servidor (sincronizar estado)

RemoteFunctions (para peticiones síncronas):
├── GetGraphState()                -- Retorna nodos, cables actuales
├── GetModeState()                 -- Retorna estado del modo actual
├── GetAdjacencyMatrix()           -- Retorna matriz NxN
└── ValidateAlgorithmStep()        -- Valida si paso es correcto

Bindables (eventos internos del servidor):
├── GraphChanged(changeType, nodeA, nodeB)
├── ModeChanged(oldMode, newMode)
├── NodeSelected(nodeName)
├── AlgorithmStepExecuted(stepData)
└── AlgorithmCompleted(score)
```

**En cliente (LocalScripts):**
```lua
-- Escuchar cambios del servidor
local graphChangedEvent = ReplicatedStorage.Events.Bindables:WaitForChild("GraphChanged")
graphChangedEvent.Event:Connect(function(changeType, nodeA, nodeB)
    if changeType == "added" then
        -- Animar aparición de cable
    elseif changeType == "removed" then
        -- Animar desaparición de cable
    end
end)

-- Emitir acciones del jugador
local selectNodeRemote = ReplicatedStorage.Events.Remotes:WaitForChild("SelectNode")
selectNodeRemote:FireServer(nodeName)
```

---

## 🎨 Requisitos Visuales

### MODO VISUAL
- **Resaltado de nodos válidos:** Emitir particles o cambiar material a color verde brillante
- **Minimapa:**
  - Viewport en esquina inferior derecha (500x400px)
  - Nodos como círculos 10px
  - Cables como líneas 2px
  - Color nodos: gris por defecto, dorado si seleccionado
  - Color cables: blanco por defecto, verde si nuevo
  - Actualización cada 0.1s

### MODO MATEMÁTICO
- **Matriz:**
  - Fuente monoespaciada
  - Headers row/col: fondo gris oscuro
  - Celdas valor 0: texto gris
  - Celdas con peso: texto blanco/verde
  - Fila/columna resaltada: fondo verde translúcido
  - Animación color: duración 0.3s (ease-in-out)
- **Panel información:**
  - Fondo: panel semi-transparente
  - Título nodo en grande
  - Datos en grid compacto

### MODO ANÁLISIS
- **Fondo oscuro:**
  - ScreenGui con Transparency 0.7, Color negro
  - Cubre todo el viewport
- **Panel central:**
  - Tamaño: 700x800px (centrado)
  - Fondo: panel con borde redondeado
  - Sombra drop-shadow
  - Scroll interno si contenido > 800px
- **Colores del algoritmo:**
  - Nodo actual: Rojo brillante
  - Nodo visitado: Naranja
  - Camino óptimo: Verde
  - Cable activo: Cyan/Azul
- **Animaciones:**
  - Nodo visitado: pulsa (scale 1.0 → 1.3 → 1.0)
  - Cable destacado: brilla suavemente
  - Cambio de paso: fade out anterior → fade in nuevo

---

## 📊 Validación de Lógica

### MODO VISUAL
- ✅ Puede conectar cualquier par de nodos (sin restricción)
- ✅ Minimapa actualiza en tiempo real
- ✅ Datos se guardan en GraphState

### MODO MATEMÁTICO
- ✅ Matriz refleja cables en GraphState
- ✅ Celdas se animan al crear/borrar cables
- ✅ Fila/columna se resaltan correctamente
- ✅ Información del nodo es precisa

### MODO ANÁLISIS
- ✅ AlgorithmSimulator genera pasos válidos
- ✅ Historial permite retroceso
- ✅ Puntos se calculan comparando con solución óptima
- ✅ Al salir, puntos se guardan

---

## 🚀 Próximos Pasos Para Desarrollo

1. **Crear ModeManager.lua** - Orquestar cambios de modo, limpiar estado anterior
2. **Crear VisualModeService.lua** - Lógica de selección y resaltado
3. **Crear MatrixModeService.lua** - Cálculo dinámico y sincronización matriz
4. **Crear AnalysisModeService.lua + AlgorithmSimulator.lua** - Motor paso a paso
5. **Crear UI clients** - Scripts en StarterGui para cada modo
6. **Conectar EventBus** - Asegurar todas las RemoteEvents/Bindables funcionan
7. **Testing & Animaciones** - Refinar transiciones y feedback visual

---

## ✅ Integración con Sistema Existente

- **GraphService:** Sin cambios, continúa siendo fuente única de verdad
- **LevelService:** Sin cambios, proporciona config de nivel
- **EnergyService:** Sin cambios, usado en modo análisis para validación
- **AlgorithmService:** Refactorizar para usar AlgorithmSimulator (desacoplamiento)
- **UIService:** Refactorizar para coordinar actualización de UIs por modo
- **Eventos:** Ampliar con nuevos eventos específicos de modo

---

Este prompt mejora el anterior integrando:
✅ Arquitectura actual del proyecto
✅ Servicios existentes (GraphService, LevelService, etc.)
✅ Sistema de eventos centralizado
✅ Patrón Observer con EventBus
✅ Flujo cliente-servidor de Roblox
✅ Requisitos visuales concretos
✅ Validación testeable de cada modo
