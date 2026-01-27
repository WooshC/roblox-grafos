# 🧠 Documentación de Algoritmos - BFS y Dijkstra

## 📚 Índice
1. [Introducción](#introducción)
2. [BFS (Breadth-First Search)](#bfs-breadth-first-search)
3. [Dijkstra](#dijkstra)
4. [Cuándo Usar Cada Uno](#cuándo-usar-cada-uno)
5. [Configuración de Velocidad](#configuración-de-velocidad)

---

## 🎯 Introducción

En **Redes y Caminos**, usamos dos algoritmos de grafos para diferentes propósitos:

- **BFS**: Para propagación de energía en tiempo real (cuando conectas cables)
- **Dijkstra**: Para visualización educativa del camino óptimo

---

## 🌊 BFS (Breadth-First Search)

### ¿Qué es?
**BFS** es un algoritmo que explora un grafo nivel por nivel, como ondas en el agua.

### ¿Dónde se usa?
📍 **Archivo:** `ServerScriptService/Gameplay/GameplayEvents.server.lua`
📍 **Función:** `verificarConectividad()`
📍 **Líneas:** 88-145

### ¿Cuándo se ejecuta?
Se ejecuta **automáticamente** cada vez que:
- Conectas un cable nuevo
- Desconectas un cable
- Se dispara el evento `ConexionCambiada`

### Cómo Funciona (Paso a Paso)

```lua
-- 1. INICIALIZACIÓN
local cola = { config.NodoInicio }  -- Empezamos en el generador
local visitados = {}
visitados[config.NodoInicio] = true

-- 2. PROPAGACIÓN (BFS)
while #cola > 0 do
    task.wait(0.5)  -- ⚡ VELOCIDAD DE VISUALIZACIÓN
    
    local nodoActual = table.remove(cola, 1)  -- Sacar primero de la cola
    
    -- Marcar como energizado
    posteActual:SetAttribute("Energizado", true)
    
    -- Explorar vecinos
    for _, vecino in ipairs(conexiones) do
        if not visitados[vecino] then
            visitados[vecino] = true
            table.insert(cola, vecino)  -- Agregar al final de la cola
            
            -- Pintar cable
            cable.Color = BrickColor.new("Cyan")
        end
    end
end
```

### Visualización del Proceso

```
Paso 1: Generador (PostePanel)
        ↓
Paso 2: Poste1, Poste3 (vecinos directos)
        ↓
Paso 3: Poste2, PosteFinal (siguiente nivel)
        ↓
Paso 4: Todos los nodos conectados
```

### Características
- ✅ **Simple y rápido**
- ✅ **Explora nivel por nivel**
- ✅ **No considera pesos** (todas las conexiones son iguales)
- ✅ **Perfecto para propagación de energía**

### Velocidad de Visualización

**Ubicación:** Línea 101 en `GameplayEvents.server.lua`

```lua
task.wait(0.5)  -- 🐢 VELOCIDAD: 0.5 segundos por nodo
```

**Cómo hacerlo más lento:**
```lua
task.wait(1.0)   -- Más lento (1 segundo por nodo)
task.wait(1.5)   -- Muy lento (1.5 segundos)
task.wait(2.0)   -- Súper lento (2 segundos)
```

**Cómo hacerlo más rápido:**
```lua
task.wait(0.2)   -- Más rápido
task.wait(0.1)   -- Muy rápido
task.wait(0)     -- Instantáneo (no recomendado)
```

---

## 🎯 Dijkstra

### ¿Qué es?
**Dijkstra** es un algoritmo que encuentra el **camino más corto** considerando los **pesos** (distancias) de cada conexión.

### ¿Dónde se usa?
📍 **Archivo:** `ReplicatedStorage/Algoritmos.lua`
📍 **Función:** `DijkstraVisual()`
📍 **Líneas:** 83-162

### ¿Cuándo se ejecuta?
Se ejecuta **manualmente** cuando:
- El jugador presiona el botón "🧠 ALGORITMO"
- Se dispara desde `VisualizadorAlgoritmos.server.lua`

### Cómo Funciona (Paso a Paso)

```lua
-- 1. INICIALIZACIÓN
distancias = {
    PostePanel = 0,      -- Inicio
    Poste1 = ∞,
    Poste2 = ∞,
    PosteFinal = ∞
}

-- 2. ITERACIÓN
while hay_nodos_sin_visitar do
    -- Elegir nodo con menor distancia
    nodoActual = nodo_con_menor_distancia()
    
    -- Explorar vecinos
    for cada vecino do
        nuevaDistancia = distancia[nodoActual] + peso_arista
        
        if nuevaDistancia < distancia[vecino] then
            distancia[vecino] = nuevaDistancia
            previo[vecino] = nodoActual
        end
    end
end

-- 3. RECONSTRUIR CAMINO
camino = backtrack desde destino hasta inicio
```

### Ejemplo Visual

```
Grafo:
    PostePanel --10m--> Poste1 --5m--> PosteFinal
         |                               ↑
        15m                             8m
         ↓                               |
       Poste3 -------------------------+

Dijkstra encuentra: PostePanel → Poste1 → PosteFinal (15m total)
En lugar de:        PostePanel → Poste3 → PosteFinal (23m total)
```

### Características
- ✅ **Encuentra el camino MÁS CORTO**
- ✅ **Considera pesos** (distancias reales)
- ✅ **Educativo** (muestra el proceso paso a paso)
- ✅ **Visualización con cables fantasma**

### Velocidad de Visualización

**Ubicación:** Línea 225 en `VisualizadorAlgoritmos.server.lua`

```lua
task.wait(0.3)  -- Velocidad de exploración
```

**Para el camino final:**
```lua
task.wait(0.2)  -- Velocidad de dibujo del camino
```

---

## 🔀 Cuándo Usar Cada Uno

### Usa BFS cuando:
- ✅ Necesitas propagar energía en tiempo real
- ✅ No importan las distancias
- ✅ Quieres ver cómo se expande la red
- ✅ Todas las conexiones tienen el mismo "costo"

**Ejemplo:** Nivel 0 (Tutorial) - Enseñar conectividad básica

```lua
LevelsConfig[0] = {
    Algoritmo = "BFS",  -- ✅ Perfecto para tutorial
    -- ...
}
```

### Usa Dijkstra cuando:
- ✅ Necesitas el camino más corto
- ✅ Las distancias importan
- ✅ Quieres enseñar optimización
- ✅ Hay múltiples rutas posibles

**Ejemplo:** Nivel 2 (Avanzado) - Optimización de costos

```lua
LevelsConfig[2] = {
    Algoritmo = "Dijkstra",  -- ✅ Enseña optimización
    CostoPorMetro = 50,      -- Penaliza rutas largas
    -- ...
}
```

---

## ⚙️ Configuración de Velocidad

### Para BFS (Propagación de Energía)

**Archivo:** `GameplayEvents.server.lua` línea 101

```lua
-- LENTO (Educativo)
task.wait(1.0)   -- 1 segundo por nodo
-- Bueno para: Tutorial, explicar el proceso

-- NORMAL (Recomendado)
task.wait(0.5)   -- 0.5 segundos por nodo
-- Bueno para: Juego normal, balance entre velocidad y visualización

-- RÁPIDO (Avanzado)
task.wait(0.2)   -- 0.2 segundos por nodo
-- Bueno para: Niveles avanzados, jugadores experimentados
```

### Para Dijkstra (Visualización)

**Archivo:** `VisualizadorAlgoritmos.server.lua` líneas 225 y 254

```lua
-- Exploración de nodos
task.wait(0.5)   -- Más lento = más educativo

-- Dibujo del camino final
task.wait(0.3)   -- Más rápido = más satisfactorio
```

---

## 📊 Comparación Rápida

| Característica | BFS | Dijkstra |
|----------------|-----|----------|
| **Complejidad** | O(V + E) | O(V² + E) |
| **Considera pesos** | ❌ No | ✅ Sí |
| **Encuentra camino óptimo** | Solo si pesos = 1 | ✅ Siempre |
| **Velocidad** | ⚡ Rápido | 🐢 Más lento |
| **Uso en el juego** | Propagación de energía | Visualización educativa |
| **Cuándo se ejecuta** | Automático (al conectar) | Manual (botón) |

---

## 🎮 Ejemplos de Configuración

### Nivel Tutorial (BFS Lento)
```lua
LevelsConfig[0] = {
    Nombre = "Tutorial",
    Algoritmo = "BFS",
    -- En GameplayEvents.server.lua línea 101:
    -- task.wait(1.0)  -- Muy lento para enseñar
}
```

### Nivel Intermedio (BFS Normal)
```lua
LevelsConfig[1] = {
    Nombre = "Primera Red",
    Algoritmo = "BFS",
    -- task.wait(0.5)  -- Velocidad normal
}
```

### Nivel Avanzado (Dijkstra)
```lua
LevelsConfig[2] = {
    Nombre = "Optimización",
    Algoritmo = "Dijkstra",
    CostoPorMetro = 50,  -- Penaliza rutas largas
    -- Enseña a encontrar el camino más eficiente
}
```

---

## 🔧 Modificar la Velocidad de BFS

### Opción 1: Velocidad Global (Todos los Niveles)

**Archivo:** `GameplayEvents.server.lua` línea 101

```lua
-- ANTES:
task.wait(0.5)

-- DESPUÉS (más lento):
task.wait(1.0)
```

### Opción 2: Velocidad por Nivel (Avanzado)

Agregar en `LevelsConfig.lua`:

```lua
LevelsConfig[0] = {
    -- ...
    VelocidadBFS = 1.0,  -- Lento para tutorial
}

LevelsConfig[1] = {
    -- ...
    VelocidadBFS = 0.5,  -- Normal
}

LevelsConfig[2] = {
    -- ...
    VelocidadBFS = 0.2,  -- Rápido para avanzados
}
```

Luego en `GameplayEvents.server.lua` línea 101:

```lua
-- ANTES:
task.wait(0.5)

-- DESPUÉS:
local velocidad = config.VelocidadBFS or 0.5
task.wait(velocidad)
```

---

## 📝 Notas Importantes

1. **BFS no usa el módulo `Algoritmos.lua`**
   - Está implementado directamente en `GameplayEvents.server.lua`
   - Es más eficiente para propagación en tiempo real

2. **Dijkstra usa el módulo `Algoritmos.lua`**
   - Más complejo, calcula distancias reales
   - Genera pasos de visualización

3. **Velocidad afecta la experiencia**
   - Muy lento = Aburrido
   - Muy rápido = No se entiende
   - Recomendado: 0.5-1.0 segundos para tutorial

4. **Los cables se pintan durante BFS**
   - Cyan = Explorando
   - Verde = Circuito completo
   - Negro = Sin energía

---

**Última actualización:** 2026-01-23
**Versión:** 1.0
