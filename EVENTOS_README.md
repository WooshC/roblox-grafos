# 📡 Estructura de Eventos (ReplicatedStorage)

Aquí tienes la estructura jerárquica exacta que debes crear en **ReplicatedStorage** dentro de Roblox Studio.

```
ReplicatedStorage
└── 📂 Events
    ├── 📂 Remotes
    │   ├── ⚡ PulseEvent           (RemoteEvent)
    │   ├── ⚡ CableDragEvent       (RemoteEvent)
    │   ├── ⚡ EjecutarAlgoritmo    (RemoteEvent)
    │   ├── ⚡ ReiniciarNivel       (RemoteEvent)
    │   ├── ⚡ ActualizarInventario (RemoteEvent)
    │   ├── ⚡ ActualizarMision     (RemoteEvent)
    │   ├── ⚡ AparecerObjeto       (RemoteEvent)
    │   ├── ⚡ RequestPlayLevel     (RemoteEvent)  
    │   ├── 📞 GetAdjacencyMatrix   (RemoteFunction)
    │   ├── 📞 GetPlayerProgress    (RemoteFunction) 
    │   └── 📞 VerificarInventario  (RemoteFunction)
    │
    └── 📂 Bindables
        ├── ⚡ ConexionCambiada     (BindableEvent)
        ├── ⚡ DesbloquearObjeto    (BindableEvent)
        └── ⚡ RestaurarObjetos     (BindableEvent)
```

## 📋 Detalles de cada Evento

### 📂 Events/Remotes (Cliente ↔ Servidor)
| Nombre | Tipo | Función | Parámetros Clave |
| :--- | :--- | :--- | :--- |
| `PulseEvent` | RemoteEvent | Inicia/Detiene partículas entre postes | `Action` ("StartPulse"), `Poste1`, `Poste2`, `Bidireccional` |
| `CableDragEvent` | RemoteEvent | Visualiza el cable arrastrado por el jugador | `Action` ("Start"/"Stop"), `Attachment` |
| `EjecutarAlgoritmo` | RemoteEvent | Pide ejecutar Dijkstra/BFS | `Algoritmo`, `Inicio`, `Fin`, `NivelID` |
| `ReiniciarNivel` | RemoteEvent | Pide resetear el nivel actual | *Ninguno* |
| `ActualizarInventario`| RemoteEvent | Avisa al cliente que obtuvo un ítem | `ItemID` (ej. "Mapa"), `Tiene` (bool) |
| `ActualizarMision` | RemoteEvent | Actualiza checkbox de misiones en UI | `MisionIndex`, `Completada` (bool) |
| `RequestPlayLevel` | RemoteEvent | Solicita cargar un nivel desde el menú | `LevelID` (int) |
| `GetAdjacencyMatrix` | **RemoteFunction** | Pide datos para la tabla Matriz | *Return:* `{Headers, Matrix}` |
| `GetPlayerProgress` | **RemoteFunction** | Pide tabla de niveles desbloqueados | *Return:* `{Levels, Inventory}` |
| `VerificarInventario`| **RemoteFunction** | Chequea si el jugador tiene X ítem | *Return:* `Bool` |

### 📂 Events/Bindables (Servidor ↔ Servidor)
| Nombre | Tipo | Función |
| :--- | :--- | :--- |
| `ConexionCambiada` | BindableEvent | Avisa que un cable se conectó/desconectó (Recálculo de energía) |
| `DesbloquearObjeto` | BindableEvent | Trigger interno para dar ítems |
| `RestaurarObjetos` | BindableEvent | Trigger para resetear mapa |
