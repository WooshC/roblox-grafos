# 🕵️ Análisis de Código y Reporte de Duplicidad (Actualizado)

Este documento detalla los problemas de duplicidad de código encontrados en todo el proyecto (`ReplicatedStorage`, `StarterPlayer`, `ServerScriptService`) y propone una arquitectura para resolver el "Spaghetti Code".

## 🚨 Problemas Detectados

### 1. Duplicidad de Lógica Crítica (Grave)
Se encontró la misma lógica de negocio dispersa en múltiples scripts.

| Funcionalidad | Archivos con Código Duplicado | Descripción del Problema |
| :--- | :--- | :--- |
| **Búsqueda de Postes y Niveles** | `VisualizadorAlgoritmos.server.lua`<br>`GameplayEvents.server.lua`<br>`ConectarCables.server.lua`<br>`Minimap.client.lua`<br>`Algoritmos.lua`<br>`Mapa.lua`<br>`ControladorEscenario.server.lua` | **7 Scripts** tienen su propia forma de buscar niveles (ej: `workspace:FindFirstChild("Nivel"..ID)`). Aunque `NivelUtils.lua` existe y es la solución correcta, `VisualizadorAlgoritmos`, `Mapa`, y `Algoritmos` lo ignoran y re-implementan la búsqueda manualmente. **Riesgo:** Alta fragilidad ante cambios de nombre en workspace. |
| **Generación de Claves de Cable ("NodoA_NodoB")** | `ConectarCables.server.lua`<br>`Minimap.client.lua`<br>`VisualEffects.client.lua`<br>`VisualizadorAlgoritmos.server.lua`<br>`Algoritmos.lua` | Todos implementan la lógica `if A < B then A.._..B else B.._..A` para identificar cables. Esto debe centralizarse en `GraphUtils` o `NivelUtils`. |
| **Iteración y Pintado de Cables** | `GameplayEvents.server.lua`<br>`VisualizadorAlgoritmos.server.lua`<br>`VisualEffects.client.lua` | Múltiples scripts iteran sobre los `RopeConstraint` en workspace o carpetas de conexiones para cambiar su color/grosor. La lógica de "buscar cable entre A y B" está triplicada. |
| **Lógica de Grafos (BFS/Recorrido)** | `Algoritmos.lua` (Visual)<br>`GameplayEvents.server.lua` (Lógico)<br>`VisualizadorAlgoritmos.server.lua` (Validación) | Hay 3 implementaciones de recorrido de grafos: una para mostrar la animación, otra para calcular la energía real del juego, y otra para validar la ruta del jugador. Si cambias la regla de conexión, debes actualizar las 3. |

### 2. Análisis por Directorio

#### `@[ReplicatedStorage]`
- **`Algoritmos.lua`**: 
  - Función `getPos` (líneas 136-147) busca manualmente "Nivel0_Tutorial" iterando workspace. **Debería usar `NivelUtils`**.
  - Lógica de visualización mezclada con lógica de cálculo.
- **`NivelUtils.lua`**: 
  - Es el módulo "correcto" pero está subutilizado.
- **`Utilidades/InventoryManager.lua`**:
  - Parece estar aislado y funcionado bien, pero `Mapa.lua` debería integrarse mejor con él.

#### `@[ServerScriptService]`
- **`Mapa.lua`**: 
  - Script "suelto" sin modularidad. 
  - Busca hardcoded `Nivel0_Tutorial` y `ObjetosColeccionables`.
  - Maneja eventos de UI y lógica de juego mezclados.
- **`ControladorEscenario.server.lua`**:
  - Re-implementa la **creación de cables** (RopeConstraint, Attachments) que ya existe en `ConectarCables`. Debería haber una función `CableService.conectar(posteA, posteB)`.
- **`Gameplay/VisualizadorAlgoritmos.server.lua`**:
  - **DUPLICACIÓN**: Tiene su propia función `obtenerCarpetaPostes` que es idéntica a la de `NivelUtils`.
  - **DUPLICACIÓN**: Re-implementa la validación de conexiones del jugador (`validarRutaJugador`), generando claves de cables manualmente.
  - Genera "Cables Fantasma" directamente en Workspace, ensuciando la jerarquía.
- **`Gameplay/GameplayEvents.server.lua`**:
  - Implementa su propio **BFS** para energizar la red (`verificarConectividad`).
  - Itera manualmente los cables para cambiar colores (`pintarCablesSegunEnergia`), duplicando lógica visual de `VisualizadorAlgoritmos`.

---

## 🏗️ Propuesta de Arquitectura (Patrones de Diseño)

Implementaremos **Knit-like Architecture** (Services & Controllers) para centralizar la lógica.

### 📐 Nueva Estructura Sugerida

```text
ReplicatedStorage/
├── Shared/
│   ├── Enums.lua           # Colores (Neon Orange, Lime Green), Nombres de Eventos
│   ├── Utils/
│       ├── GraphUtils.lua  # Generar claves "A_B", calcular distancias
│       └── NivelUtils.lua  # (EXISTENTE) Centralizar TODAS las búsquedas de objetos
├── Services/               # Definiciones de APIs
└── Components/             # Clases (Cable, Poste)

ServerScriptService/
├── Services/
│   ├── GraphService.lua    # ÚNICO lugar que toca los cables y nodos (Crear, destruir, validar conex).
│   ├── EnergyService.lua   # Lógica de "energizar" la red (BFS lógico).
│   ├── LevelService.lua    # Gestión de niveles y spawning.
│   └── AlgorithmService.lua # Ejecución y validación de algoritmos (Dijkstra, BFS).
```

## 🛠️ Plan de Acción Inmediato

1.  **Refactorizar `Algoritmos.lua`**: Eliminar `getPos` y pasarle las posiciones o usar `NivelUtils` inyectado.
2.  **Limpiar `VisualizadorAlgoritmos.server.lua`**:
    - Reemplazar `obtenerCarpetaPostes` con `require(NivelUtils).obtenerCarpetaPostes`.
    - Extraer la lógica de `validarRutaJugador` a un `GraphUtils` compartido.
3.  **Centralizar Creación de Cables**: Mover la lógica de crear `RopeConstraint` de `ConectarCables` y `ControladorEscenario` a un módulo `CableConnector`.
4.  **Estandarizar Eventos**: Crear `ReplicatedStorage/Shared/Enums.lua` para listar todos los nombres de eventos y colores.

### ¿Por dónde empezamos?
**Paso 1: Migración a `NivelUtils`**. Editar `VisualizadorAlgoritmos.server.lua` y `Mapa.lua` para que usen obligatoriamente `NivelUtils`. Esto eliminará el código repetido de búsqueda de carpetas inmediatamente.
