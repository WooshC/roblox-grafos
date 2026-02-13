# 🕵️ Análisis de Código y Reporte de Duplicidad (Actualizado)

Este documento detalla los problemas de duplicidad de código encontrados en todo el proyecto (`ReplicatedStorage`, `StarterPlayer`, `ServerScriptService`) y propone una arquitectura para resolver el "Spaghetti Code".

## 🚨 Problemas Detectados

### 1. Duplicidad de Lógica Crítica (Grave)
Se encontró la misma lógica de negocio dispersa en múltiples scripts.

| Funcionalidad | Archivos con Código Duplicado | Descripción del Problema |
| :--- | :--- | :--- |
| **Búsqueda de Postes y Niveles** | `VisualizadorAlgoritmos.server.lua`<br>`GameplayEvents.server.lua`<br>`ConectarCables.server.lua`<br>`Minimap.client.lua`<br>`Algoritmos.lua`<br>`Mapa.lua` | **6 Scripts** tienen su propia forma de buscar "Nivel0_Tutorial" o iterar carpetas. Aunque existe `NivelUtils.lua`, muchos scripts lo ignoran y re-implementan la búsqueda (ej: `Algoritmos.lua:getPos` vs `NivelUtils.obtenerModeloNivel`). **Riesgo:** Si renombras un nivel, el juego colapsa. |
| **Generación de Claves de Cable ("NodoA_NodoB")** | `ConectarCables.server.lua`<br>`Minimap.client.lua`<br>`VisualEffects.client.lua`<br>`VisualizadorAlgoritmos.server.lua` | Todos implementan la lógica `if A < B then A.._..B else B.._..A` para identificar cables. Si decides cambiar el separador `_` por `-`, tendrás que editar 4 archivos. |
| **Gestión de Eventos (Spaghetti)** | `GameplayEvents.server.lua`<br>`ClienteUI.client.lua`<br>`Mapa.lua` | Unos usan `ReplicatedStorage.Events.Remotes`, otros `ReplicatedStorage.ServerEvents`. No hay una fuente única de verdad para los eventos. |
| **Visualización de Algoritmos** | `VisualizadorAlgoritmos.server.lua` (Server)<br>`Minimap.client.lua` (Client) | Ambos contienen lógica de colores (`COLORES.Explorando`, etc.) y lógica de pintado. Debería haber una sola definición de constantes visuales en `Shared/Enums.lua`. |

### 2. Análisis por Directorio

#### `@[ReplicatedStorage]`
- **`Algoritmos.lua`**: Tiene lógica hardcoded (`nivelID == 0 and "Nivel0_Tutorial"`) que duplica a `NivelUtils`. Debería usar `NivelUtils` o recibir la posición de los nodos como parámetro, no buscarlos.
- **`NivelUtils.lua`**: ¡Es la solución correcta pero nadie la usa! Necesitamos refactorizar los demás scripts para que obligatoriamente usen este módulo.

#### `@[StarterPlayer]`
- **`VisualEffects.client.lua`**: Duplica la lógica de claves de cables (`obtenerClave`). Accede a "Remotes" hardcoded.
- **`Minimap.client.lua`**: Re-implementa la búsqueda de "Postes" y la lógica de colores de energía que ya existe en el servidor.
- **`ClienteUI.client.lua`**: UI masiva y hardcoded.

#### `@[ServerScriptService]`
- **`Mapa.lua`**: Script "suelto" que busca manualmente `Nivel0_Tutorial` y `ObjetosColeccionables`. Ignora `InventoryManager` en algunas partes.
- **`VisualizadorAlgoritmos.server.lua`**: Tiene su propia versión de `obtenerCarpetaPostes` ignorando `NivelUtils`.

---

## 🏗️ Propuesta de Arquitectura (Patrones de Diseño)

Implementaremos **Knit-like Architecture** (Services & Controllers) para centralizar la lógica.

### 📐 Nueva Estructura

```text
ReplicatedStorage/
├── Shared/
│   ├── Enums.lua           # Colores (Neon Orange, Lime Green), Nombres de Eventos
│   ├── GameState.lua       # Estado global tipado
│   └── Utils/
│       └── GraphUtils.lua  # ¡NUEVO! Generar claves "A_B", calcular distancias (extracción de Algoritmos.lua)
├── Services/               # Definiciones (APIs)
└── Components/             # Clases (Cable, Poste)

ServerScriptService/
├── Services/
│   ├── GraphService.lua    # ÚNICO lugar que toca los cables y nodos.
│   ├── LevelService.lua    # ÚNICO lugar que busca "NivelX" en workspace. Usa NivelUtils internamente.
│   └── PlayerDataService.lua # Dinero y Puntos.
```

## 🛠️ Plan de Acción Inmediato

1.  **Refactorizar `Algoritmos.lua` y `VisualEffects.client.lua`**: Extraer la lógica de `obtenerClave` (strings) y `getPos` a `Shared/Utils/GraphUtils.lua`.
2.  **Imponer `NivelUtils.lua`**: Reescribir `VisualizadorAlgoritmos.server.lua` y `Mapa.lua` para que USEN `NivelUtils` en lugar de buscar carpetas manualmente.
3.  **Unificar Constantes**: Crear `Enums.lua` con los colores de algoritmos y usarlo tanto en el Servidor (`Visualizador`) como en el Cliente (`Minimap`).

### ¿Por dónde empezamos?
Recomiendo **Paso 1: Unificar `NivelUtils`**. Si arreglamos la búsqueda de niveles/postes, reducimos el riesgo de bugs en un 50% inmediatamente.
