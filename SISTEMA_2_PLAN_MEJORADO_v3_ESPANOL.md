# Sistema GrafosV3 — Plan de Arquitectura y Estado Actual

> **Regla de Oro**: Un punto de entrada. Mientras este el menu activo, TODO lo relacionado al gameplay esta completamente desconectado.
>
> **Principio**: Separacion estricta entre "Sistema de Menu" y "Sistema de Gameplay". Nunca deben coexistir activos.

---

## Convencion de Nombres (Functions in English, Files/Variables in Spanish)

| Concepto | Nombre en Codigo | Function Names |
|----------|------------------|----------------|
| Orchestrator | Orquestador | init, start, stop, cleanup |
| Manager | Gestor | load, save, get, set |
| Controller | Controlador | enable, disable, show, hide |
| Service | Servicio | activate, deactivate, process |
| Module | Modulo | require, init |
| activate | activar | activate |
| deactivate | desactivar | deactivate |
| start | iniciar | start |
| stop | detener | stop |
| cleanup | limpiar | cleanup |
| player | jugador | player |
| level | nivel | level |
| score | puntaje | score |
| mission | mision | mission |
| zone | zona | zone |
| cable | cable | cable |
| node | nodo | node |
| connection | conexion | connection |
| camera | camara | camera |

---

## Estructura ACTUAL de GrafosV3

```
GrafosV3/
├── ReplicatedStorage/
│   ├── Config/
│   │   └── LevelsConfig.lua          ✅ FUENTE UNICA DE VERDAD
│   └── Efectos/
│       ├── PresetTween.lua           ✅ Configuraciones visuales
│       ├── EfectosNodo.lua           ✅ Efectos de seleccion
│       ├── EfectosCable.lua          ✅ Efectos de pulso
│       └── BillboardNombres.lua      ✅ Nombres flotantes
│
├── ServerScriptService/
│   ├── Nucleo/
│   │   ├── EventRegistry.server.lua  ✅ Crea eventos remotos
│   │   └── Boot.server.lua           ✅ Punto de entrada UNICO
│   │
│   ├── Servicios/
│   │   ├── ServicioDatos.lua         ✅ DataStore wrapper
│   │   ├── ServicioProgreso.lua      ✅ Progreso + LevelsConfig
│   │   └── CargadorNiveles.lua       ✅ Carga modelos + personaje
│   │
│   └── SistemasGameplay/
│       ├── ConectarCables.lua        ✅ Sistema de conexion
│       ├── ServicioMisiones.lua      ✅ Validacion de misiones
│       ├── ServicioPuntaje.lua       ✅ Tracking de puntos
│       └── GestorZonas.lua           ✅ Deteccion de zonas
│
└── StarterPlayerScripts/
    ├── Nucleo/
    │   └── ClientBoot.client.lua     ✅ Inicializacion cliente
    │
    ├── Menu/
    │   └── ControladorMenu.client.lua✅ UI de seleccion de niveles
    │
    ├── HUD/
    │   ├── ControladorHUD.client.lua ✅ Orquestador del HUD
    │   └── ModulosHUD/
    │       ├── EventosHUD.lua        ✅ Referencias a RemoteEvents
    │       ├── PanelMisionesHUD.lua  ✅ Panel de misiones
    │       ├── PuntajeHUD.lua        ✅ Display de puntaje
    │       ├── VictoriaHUD.lua       ✅ Pantalla de victoria
    │       └── TransicionHUD.lua     ✅ Efectos de fade
    │
    └── SistemasGameplay/
        └── ControladorEfectos.client.lua ✅ Efectos visuales + Highlights
```

---

## Estado de Implementacion

### ✅ COMPLETADO - Fase 1: Menu y Progreso
- [x] **LevelsConfig** como fuente unica de verdad
  - Configuracion de niveles, adyacencias, nombres, puntuacion
- [x] **ServicioProgreso** - Enriquece datos de LevelsConfig con progreso del jugador
- [x] **ControladorMenu** - UI de seleccion de niveles con tarjetas
- [x] **Navegacion Menu** - Botones Jugar/Ajustes/Creditos/Salir funcionales
- [x] **Ver niveles bloqueados** - Puede ver descripcion de niveles bloqueados

### ✅ COMPLETADO - Fase 2: Carga de Niveles
- [x] **CargadorNiveles** - Clona modelo desde ServerStorage
- [x] **Spawn de personaje** - Teletransporta al SpawnLocation del nivel
- [x] **Transicion Menu→Gameplay** - Oculta menu, muestra mundo
- [x] **Transicion Gameplay→Menu** - Descarga nivel, vuelve a menu

### ✅ COMPLETADO - Fase 3: Sistema de Conexion de Cables
- [x] **ConectarCables** (servidor) - Logica de conexion/desconexion
- [x] **Adyacencias desde LevelsConfig** - Valida conexiones segun configuracion
- [x] **Click en Selector** - Detecta clicks en partes Selector
- [x] **Crear cables** - Crea Beam visual entre nodos
- [x] **Desconectar** - Click en cable existente lo elimina
- [x] **Distancia de click** - 50 studs de alcance

### ✅ COMPLETADO - Fase 4: Efectos Visuales
- [x] **ControladorEfectos** (cliente) - Recibe eventos del servidor
- [x] **Highlight nativo de Roblox** - Outline + fill semitransparente
- [x] **Nodo seleccionado** - Color cyan brillante
- [x] **Nodos adyacentes** - Color dorado/amarillo
- [x] **Flash de error** - Rojo breve al conectar nodos no adyacentes
- [x] **Billboard con nombre** - Muestra nombre del nodo al seleccionar
- [x] **Nombres desde LevelsConfig** - Usa NombresNodos del config
- [x] **Limpiar al desconectar** - Resetea colores correctamente

### ✅ COMPLETADO - Fase 5: Sistemas Adicionales de Gameplay
- [x] **ServicioMisiones** - Validacion de objetivos con revocacion
- [x] **ServicioPuntaje** - Tracking de puntos, aciertos, fallos
- [x] **GestorZonas** - Deteccion de entrada/salida de zonas
- [x] **Sistema de Victoria** - Detecta cuando se completan objetivos
- [x] **Guardar resultado** - Persiste puntuacion al completar nivel

### ✅ COMPLETADO - Fase 6: HUD de Gameplay
- [x] **ControladorHUD** - Panel de misiones durante gameplay
- [x] **PuntajeHUD** - Puntos en tiempo real (ContenedorEstrellas/Puntos/Dinero)
- [x] **PanelMisionesHUD** - Lista de misiones activas con modo zona/resumen
- [x] **VictoriaHUD** - Al completar el nivel con estadisticas

### ⏳ PENDIENTE - Fase 7: Optimizaciones
- [ ] **SistemaCamara unificado** - Un solo modulo para control de camara
- [ ] **GestorColisiones** - Manejo de techos/colisiones del nivel
- [ ] **OrquestadorGameplay formal** - Modulo explicito que coordina todo

---

## Flujo de Datos Actual

### Carga de Nivel (Servidor)
```
Boot.server:IniciarNivel → CargadorNiveles.cargar()
    ├── Clonar modelo NivelX → Workspace/NivelActual
    ├── Spawn personaje en SpawnLocation
    ├── Activar ServicioPuntaje (init + iniciarNivel)
    ├── Activar ServicioMisiones (activar con config, puntaje, progreso)
    ├── Activar GestorZonas (si hay zonas configuradas)
    ├── Activar ConectarCables (si hay adyacencias, con callbacks)
    └── Notificar cliente: NivelListo
```

### Conexion de Cable con Callbacks
```
Jugador clickea nodos
    ↓
ConectarCables.intentarConectar()
    ↓
Si es conexion nueva:
    - Crear Beam visual
    - Callback onCableCreado(nomA, nomB)
        - ServicioMisiones.alCrearCable() → verificar misiones
        - ServicioPuntaje.registrarConexion() → +aciertos
    - Notificar cliente: ConexionCompletada
    
Si es desconexion (re-click en nodos conectados):
    - Eliminar Beam
    - Callback onCableEliminado(nomA, nomB)
        - ServicioMisiones.alEliminarCable() → revocar mision
        - ServicioPuntaje.registrarDesconexion()
    - Notificar cliente: CableDesconectado
```

### Victoria y Guardado
```
ServicioMisiones.verificarYNotificar()
    ↓
Todas las misiones completadas
    ↓
ServicioPuntaje.finalizar() → snapshot con puntaje, tiempo, aciertos, fallos
    ↓
ServicioProgreso.guardarResultado()
    - Incrementar intentos
    - Guardar puntaje, estrellas, aciertos, fallos, tiempo
    - Desbloquear siguiente nivel si tiene estrellas
    ↓
NivelCompletado → Cliente muestra VictoriaHUD
```

---

## Contrato de Modulos Implementados

### ConectarCables (Servidor)
```lua
ConectarCables.activar(nivel, adyacencias, jugador, nivelID, callbacks)
    -- callbacks: { onCableCreado, onCableEliminado, onNodoSeleccionado, onFalloConexion }
    
ConectarCables.desactivar()
    -- Desconecta listeners, destruye cables
    
ConectarCables.estaActivo() → boolean
```

### ServicioMisiones (Servidor)
```lua
ServicioMisiones.activar(config, nivelID, jugador, eventos, servicioPuntaje, servicioProgreso)
    -- Inicia tracking de misiones desde LevelsConfig
    
ServicioMisiones.alCrearCable(nomA, nomB)
    -- Valida misiones tipo ARISTA_CREADA
    
ServicioMisiones.alEliminarCable(nomA, nomB)
    -- Revoca misiones no permanentes
    
ServicioMisiones.alSeleccionarNodo(nomNodo)
    -- Valida misiones tipo NODO_SELECCIONADO
    
ServicioMisiones.alEntrarZona(nombre) / alSalirZona(nombre)
    -- Actualiza zonaActual y notifica cliente
```

### ServicioPuntaje (Servidor)
```lua
ServicioPuntaje:init(eventoActualizarPuntuacion)
ServicioPuntaje:iniciarNivel(jugador, nivelID, puntosConexion, penaFallo)
ServicioPuntaje:registrarConexion(jugador) -- +1 acierto
ServicioPuntaje:registrarDesconexion(jugador)
ServicioPuntaje:registrarFallo(jugador) -- +1 fallo
ServicioPuntaje:fijarPuntajeMision(jugador, puntos) -- Actualiza HUD
ServicioPuntaje:finalizar(jugador) → snapshot completo
```

### ControladorHUD (Cliente)
```lua
-- Eventos manejados:
--   NivelListo → activar HUD, resetear estado
--   ActualizarMisiones → PanelMisionesHUD.reconstruir()
--   ActualizarPuntuacion → PuntajeHUD.fijar()
--   NivelCompletado → VictoriaHUD.mostrar()
--   ZonaActual (atributo) → actualizar modo panel
```

### LevelsConfig (Configuracion)
```lua
LevelsConfig[nivelID] = {
    Nombre = string,
    DescripcionCorta = string,
    ImageId = string,
    Modelo = string,           -- Nombre del modelo en ServerStorage
    Algoritmo = string,
    Seccion = string,
    Tag = string,
    Conceptos = {string},
    
    -- Para ConectarCables
    Adyacencias = {
        ["NodoA"] = {"NodoB", "NodoC"},
    },
    
    -- Para Billboards
    NombresNodos = {
        ["NodoA"] = "Nombre Amigable",
    },
    
    -- Para puntuacion
    Puntuacion = {
        TresEstrellas = number,
        DosEstrellas = number,
        PuntosConexion = number,
        PenaFallo = number,
    },
    
    -- Para misiones
    Misiones = {
        {
            ID = number,
            Zona = "Zona_Estacion_1",
            Texto = "Conecta Nodo A con Nodo B",
            Tipo = "ARISTA_CREADA", -- o NODO_SELECCIONADO, GRADO_NODO, etc.
            Puntos = 100,
            Parametros = { NodoA = "Nodo1", NodoB = "Nodo2" }
        }
    },
    
    -- Para zonas
    Zonas = {
        ["Zona_Estacion_1"] = { 
            Trigger = "ZonaTrigger_Estacion1", 
            Descripcion = "Nodos y Aristas" 
        }
    }
}
```

---

## Checklist de "Gameplay Desconectado"

Al volver al menu, se verifica:

- [x] No hay listeners de entrada activos (clics en nodos no hacen nada)
- [x] No hay highlights visibles en el workspace
- [x] No hay billboards flotando
- [x] No hay cables siendo renderizados
- [x] La camara esta en modo Menu (Scriptable, posicion fija)
- [x] El HUD de gameplay esta oculto completamente
- [ ] El techo esta restaurado a su estado original
- [ ] Las colisiones estan restauradas
- [x] No hay referencias al "NivelActual" en ningun sistema activo

---

## Proximos Pasos Recomendados

### 1. Persistencia Mejorada (Priority: MEDIUM)
- Guardar estado parcial de nivel (progreso dentro del nivel)
- Sistema de checkpoints para niveles largos

### 2. Analytics (Priority: LOW)
- Tracking de patrones de errores
- Metricas de tiempo por zona
- Frecuencia de uso de ayudas

### 3. Mejoras Visuales (Priority: LOW)
- Animaciones de transicion
- Efectos de particulas al conectar
- Sonidos de conexion/error

---

## Notas de Implementacion

### Estructura del Selector
El Selector dentro de cada nodo debe ser:
```
Nodo (Model)
├── Decoracion/          (Model opcional)
└── Selector            (BasePart) ← OBLIGATORIO
    ├── Attachment      (Attachment) ← Para el Beam
    └── ClickDetector   (ClickDetector) ← Para clicks
```

### ClickDetector Configuracion
- `MaxActivationDistance = 50` (studs)
- No requiere `CanCollide = true`
- El Selector debe tener `CanQuery = true`

### Callbacks Pattern
Los callbacks permiten desacoplar ConectarCables de los servicios:
```lua
local callbacks = {
    onCableCreado = function(nomA, nomB) ... end,
    onCableEliminado = function(nomA, nomB) ... end,
    onNodoSeleccionado = function(nomNodo) ... end,
    onFalloConexion = function() ... end
}
ConectarCables.activar(nivel, adyacencias, jugador, nivelID, callbacks)
```

---

## Cambios Realizados vs Plan Original

| Aspecto | Plan Original | Implementacion Actual |
|---------|---------------|----------------------|
| **Estructura** | OrquestadorGameplay explicito | Boot.server maneja orquestacion implicita |
| **Carpetas** | Menu/Gameplay/Servicios separados | Menu/SistemasGameplay/Servicios |
| **Efectos** | ResaltadorNodos.lua | ControladorEfectos.client.lua integrado |
| **Camara** | SistemaCamara unificado | Logica en CargadorNiveles + ControladorMenu |
| **Nombres** | Sistema separado | BillboardNombres integrado en ControladorEfectos |
| **Misiones** | MissionService (V2) | ServicioMisiones con revocacion |
| **Puntaje** | ScoreTracker (V2) | ServicioPuntaje con callbacks |
| **Zonas** | ZoneTriggerManager (V2) | GestorZonas integrado |

---

## Archivos Deprecados/Eliminados de GrafosV2

- `VisualEffectsService.client.lua` → Reemplazado por `ControladorEfectos.client.lua`
- `CameraEffects.lua` → Logica movida a `CargadorNiveles`
- `ZoneTriggerManager.lua` → Migrado a `GestorZonas.lua`
- `MissionService.lua` → Migrado a `ServicioMisiones.lua`
- `ScoreTracker.lua` → Migrado a `ServicioPuntaje.lua`
- `DataService.lua` → Reemplazado por `ServicioProgreso.lua`

---

*Documento actualizado: Fecha actual*
*Version: GrafosV3 - Sistema Completo*
