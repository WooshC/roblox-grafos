# FASE 4: Migración Final y Limpieza

## Objetivo
- Mover módulos legacy a sus carpetas definitivas
- Crear `CicloVidaHUD` unificado
- Eliminar/deprecar archivos redundantes
- Testing completo de transiciones

---

## 1. Estructura Final de Carpetas

```
ServerScriptService/
├── Nucleo/
│   ├── InicioServidor.server.lua
│   ├── RegistroEventos.server.lua
│   └── OrquestadorGameplay.lua         ✅ YA EXISTE
│
├── Gameplay/
│   ├── Modulos/
│   │   ├── ModuloConexionCables.lua    ← MOVER desde ConectarCables
│   │   ├── ModuloDeteccionZonas.lua    ← MOVER desde ZoneTriggerManager
│   │   ├── ModuloValidacionMisiones.lua← MOVER desde MissionService
│   │   └── CicloVidaNivel.lua          ← NUEVO
│   └── Servicios/
│       └── RegistroPuntaje.lua         ← MOVER desde ScoreTracker
│
└── Menu/
    └── ServicioProgresoJugador.lua     ← NUEVO (extraer de DataService)

StarterPlayerScripts/
├── Nucleo/
│   ├── ClientBoot.lua                  ✅ YA EXISTE
│   └── OrquestadorGameplayCliente.lua  ✅ YA EXISTE
│
├── Gameplay/
│   ├── ControladorEfectosVisuales.lua  ✅ YA EXISTE
│   ├── HUD/
│   │   ├── CicloVidaHUD.lua            ← NUEVO
│   │   └── Modulos/
│   │       ├── MostradorPuntaje.lua    ← MOVER desde HUDScore
│   │       ├── PanelMisiones.lua       ← MOVER desde HUDMisionPanel
│   │       ├── PantallaVictoria.lua    ← MOVER desde HUDVictory
│   │       └── SistemaMapa/
│   │           ├── init.lua            ✅ YA EXISTE
│   │           ├── GestorZonas.lua     ← MOVER desde ZoneManager
│   │           ├── GestorNodos.lua     ← MOVER desde NodeManager
│   │           └── GestorEntrada.lua   ← MOVER desde InputManager
│   └── Visual/
│       └── ControladorEfectosVisuales.lua  ← YA EXISTE
│
└── Menu/
    └── ControladorMenu.lua             ← MOVER desde MenuController

ReplicatedStorage/
├── Compartido/
│   ├── SistemaCamara.lua               ✅ YA EXISTE
│   └── GestorColisiones.lua            ✅ YA EXISTE
└── Efectos/                            ← DEPRECADO (eliminar gradualmente)
    ├── CameraEffects.lua               ❌ ELIMINAR (reemplazado por SistemaCamara)
    ├── NodeEffects.lua                 ❌ ELIMINAR (integrado en ControladorEfectosVisuales)
    └── ZoneEffects.lua                 ❌ ELIMINAR (integrado en ModuloDeteccionZonas)
```

---

## 2. Archivos a Mover/Renombrar

### Servidor
| Origen | Destino | Acción |
|--------|---------|--------|
| ConectarCables.lua | Gameplay/Modulos/ModuloConexionCables.lua | Mover + Renombrar |
| ZoneTriggerManager.lua | Gameplay/Modulos/ModuloDeteccionZonas.lua | Mover + Renombrar |
| MissionService.lua | Gameplay/Modulos/ModuloValidacionMisiones.lua | Mover + Renombrar |
| ScoreTracker.lua | Gameplay/Servicios/RegistroPuntaje.lua | Mover + Renombrar |

### Cliente
| Origen | Destino | Acción |
|--------|---------|--------|
| HUDModules/HUDScore.lua | Gameplay/HUD/Modulos/MostradorPuntaje.lua | Mover + Renombrar |
| HUDModules/HUDMisionPanel.lua | Gameplay/HUD/Modulos/PanelMisiones.lua | Mover + Renombrar |
| HUDModules/HUDVictory.lua | Gameplay/HUD/Modulos/PantallaVictoria.lua | Mover + Renombrar |
| HUDModules/HUDMapa/ZoneManager.lua | Gameplay/HUD/Modulos/SistemaMapa/GestorZonas.lua | Mover + Renombrar |
| HUDModules/HUDMapa/NodeManager.lua | Gameplay/HUD/Modulos/SistemaMapa/GestorNodos.lua | Mover + Renombrar |
| HUDModules/HUDMapa/InputManager.lua | Gameplay/HUD/Modulos/SistemaMapa/GestorEntrada.lua | Mover + Renombrar |
| HUDModules/HUDMapa/CameraManager.lua | ❌ ELIMINAR (reemplazado por SistemaCamara) |
| MenuController.client.lua | Menu/ControladorMenu.client.lua | Mover + Renombrar |

---

## 3. Nuevos Archivos a Crear

### CicloVidaNivel.lua (Servidor)
Gestiona el ciclo de vida completo de un nivel:
- Pre-carga
- Activación
- Actualización (tick)
- Desactivación
- Post-limpieza

### CicloVidaHUD.lua (Cliente)
Gestiona el ciclo de vida del HUD:
- Inicialización
- Mostrar/Ocultar
- Limpieza completa

---

## 4. Checklist de Deprecación

### Scripts a Eliminar
- [ ] CameraEffects.lua (reemplazado por SistemaCamara)
- [ ] CameraManager.lua (reemplazado por SistemaCamara)
- [ ] NodeEffects.lua (integrado en ControladorEfectosVisuales)
- [ ] ZoneEffects.lua (integrado en ModuloDeteccionZonas)

### Scripts a Deprecar (mantener vacíos)
- [ ] VisualEffectsService.client.lua (ya está hecho)

---

## 5. Testing Checklist

### Transiciones
- [ ] Menú → Nivel (3 veces)
- [ ] Nivel → Menú (3 veces)
- [ ] Nivel → Reiniciar (2 veces)

### Funcionalidad
- [ ] Conectar cables funciona
- [ ] Seleccionar nodos funciona (sin duplicados)
- [ ] Misiones se actualizan
- [ ] Puntaje se actualiza
- [ ] Mapa se abre/cierra correctamente
- [ ] Techos se ocultan/restauran
- [ ] Camara cenital está a buena distancia

### Limpieza
- [ ] No hay billboards huérfanos al volver al menú
- [ ] No hay highlights persistentes
- [ ] No hay memory leaks (consola limpia)
