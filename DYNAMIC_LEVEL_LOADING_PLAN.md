# Plan de Carga Dinámica de Niveles (Optimización de Memoria)

Actualmente, todos los niveles existen como Modelos en el `Workspace` simultáneamente, lo que consume memoria innecesaria y puede causar lag en dispositivos de gama baja. Este plan describe cómo migrar a un sistema de carga dinámica bajo demanda.

## 1. Arquitectura Propuesta

### A. Almacenamiento (ServerStorage)
En lugar de tener todos los niveles en `Workspace`, los moveremos a una carpeta en `ServerStorage`.
- **Ventaja**: El contenido en `ServerStorage` NO se descarga a los clientes hasta que el servidor lo decide.
- **Estructura**:
  ```
  ServerStorage/
  └── Niveles/
      ├── Nivel0_Tutorial (Model)
      ├── Nivel1 (Model)
      ├── ...
  ```

### B. Ciclo de Vida del Nivel (ControladorEscenario)
El script existente `ControladorEscenario.server.lua` (o `ManagerData`) será responsable de:
1. **Limpiar**: Destruir el nivel actual del `Workspace` cuando el jugador se vaya o cambie.
2. **Clonar**: Tomar el modelo del nivel solicitado desde `ServerStorage`.
3. **Posicionar**: Colocar el clon en el `Workspace`.
4. **Teletransportar**: Mover al jugador al `SpawnLocation` del nuevo nivel.

---

## 2. Pasos de Implementación

### Paso 1: Mover Modelos
1. Crear una carpeta llamada `NivelesDisponibles` en `ServerStorage`.
2. Arrastrar todos los modelos de niveles (`Nivel0_Tutorial`, `Nivel1`, etc.) desde `Workspace` a esa carpeta.

### Paso 2: Modificar `NivelUtils.lua`
Actualizar la función utilitaria para buscar niveles en `ServerStorage` si no están en `Workspace`.

```lua
-- NivelUtils.lua (Concepto)
function NivelUtils.cargarNivel(nivelID)
    -- Verificar si ya está cargado
    if workspace:FindFirstChild("Nivel" .. nivelID) then return workspace["Nivel" .. nivelID] end
    
    -- Si no, clonar desde ServerStorage
    local origen = game.ServerStorage.NivelesDisponibles:FindFirstChild("Nivel" .. nivelID)
    if origen then
        local nuevoNivel = origen:Clone()
        nuevoNivel.Parent = workspace
        return nuevoNivel
    end
    return nil
end
```

### Paso 3: Gestión de Memoria (Unload)
Cuando un jugador solicita un nivel diferente:
1. Identificar el nivel anterior.
2. Usar `:Destroy()` en el modelo del nivel anterior *solo si nadie más lo está usando* (para multiplayer, si es un juego single-player instanciado, se borra siempre. Si es multiplayer compartido en un mismo mapa, **NO** se puede borrar dinámicamente si otros jugadores están ahí).

**Nota Importante (Multiplayer):**
Si todos los jugadores deben ver todos los niveles (un mundo abierto compartido), la carga dinámica es compleja (requiere *StreamingEnabled*).
Si el juego es por "Salas" o "Teletransporte" donde solo importa tu nivel actual:
- **Solución Ideal**: Usar `Place` separados para cada nivel (Universe).
- **Solución Intermedia**: Cargar el nivel solo para el cliente (`LocalScript` clona de `ReplicatedStorage`), pero esto no es seguro para lógica de servidor.
- **Solución Recomendada (Roblox Grafos)**: Como parece ser un juego de puzzle single-player o cooperativo local:
  - Mantener solo el nivel ACTIVO en Workspace.
  - Al cambiar, `workspace.NivelActual:Destroy()`, `NivelNuevo:Clone()`.

### Paso 4: StreamingEnabled (Alternativa Rápida)
Si no quieres programar la carga/descarga manual:
1. Activar `Workspace.StreamingEnabled = true`.
2. Configurar `StreamingMinRadius` y `StreamingTargetRadius`.
3. Roblox gestionará automáticamente la memoria descargando visualmente lo que está lejos.

---

## 3. Recomendación Inmediata

Dado que tu juego usa scripts de servidor para validar grafos (`GameplayEvents`, `Visualizador`), el servidor **necesita** acceso físico a los nodos.

**Estrategia "Swap":**
1. Al iniciar la partida (`RequestPlayLevel`), el servidor verifica si el nivel ya está en Workspace.
2. Si es un juego de 1 solo jugador activo (o lobby + 1 jugador), el servidor borra cualquier "NivelX" anterior y carga el nuevo.
3. Si hay múltiples jugadores en distintos niveles simultáneamente, esta estrategia **NO** ahorra memoria del servidor (porque debe tener todos cargados), pero sí puede ahorrar memoria del cliente si los niveles están muy separados física y espacialmente (usando StreamingEnabled).

### Plan de Acción
1. **Mover Niveles**: A `ServerStorage`.
2. **Actualizar `ManagerData`**: Para clonar el nivel al recibir `RequestPlayLevel`.
3. **Destruir Anterior**: Asegurar limpieza antes de clonar.

Esto reducirá drásticamente los tiempos de carga inicial y el lag.
