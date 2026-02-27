# Sistema GrafosV3 — Plan de Arquitectura y Estado Actual

> **Regla de Oro**: Un punto de entrada. Mientras este el menu activo, TODO lo relacionado al gameplay esta completamente desconectado.
>
> **Principio**: Separacion estricta entre "Sistema de Menu" y "Sistema de Gameplay". Nunca deben coexistir activos.

---

## Convencion de Nombres (TODO en Espanol)

| Concepto | Nombre en Codigo |
|----------|------------------|
| Orchestrator | Orquestador |
| Manager | Gestor |
| Controller | Controlador |
| Service | Servicio |
| Module | Modulo |
| activate | activar |
| deactivate | desactivar |
| start | iniciar |
| stop | detener |
| cleanup | limpiar |
| player | jugador |
| level | nivel |
| score | puntaje |
| mission | mision |
| zone | zona |
| cable | cable |
| node | nodo |
| connection | conexion |
| camera | camara |

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
│       └── ConectarCables.lua        ✅ Sistema de conexion
│
└── StarterPlayerScripts/
    ├── Nucleo/
    │   └── ClientBoot.client.lua     ✅ Inicializacion cliente
    │
    ├── Menu/
    │   └── ControladorMenu.client.lua✅ UI de seleccion de niveles
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

### ⏳ PENDIENTE - Fase 5: Sistemas Adicionales de Gameplay
- [ ] **Sistema de Misiones** - Validacion de objetivos
- [ ] **Sistema de Puntaje** - Tracking de puntos, aciertos, fallos
- [ ] **Sistema de Zonas** - Deteccion de entrada/salida de zonas
- [ ] **Sistema de Victoria** - Detecta cuando se completan objetivos
- [ ] **Guardar resultado** - Persiste puntuacion al completar nivel

### ⏳ PENDIENTE - Fase 6: HUD de Gameplay
- [ ] **HUDController** - Panel de misiones durante gameplay
- [ ] **MostradorPuntaje** - Puntos en tiempo real
- [ ] **PanelMisiones** - Lista de misiones activas
- [ ] **PantallaVictoria** - Al completar el nivel

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
    ├── Activar ConectarCables (si hay adyacencias)
    └── Notificar cliente: NivelListo
```

### Seleccion de Nodo (Cliente→Servidor→Cliente)
```
Jugador clickea Selector
    ↓
ClickDetector → ConectarCables (servidor)
    ↓
Servidor valida adyacencia con LevelsConfig
    ↓
Servidor notifica: NotificarSeleccionNodo → Cliente
    ↓
ControladorEfectos: Highlight + Billboard
```

### Conexion de Cable
```
Primer clic: Nodo A seleccionado (cyan) + adyacentes (dorado)
Segundo clic: Nodo B
    ↓
Si son adyacentes:
    - Crear Beam visual
    - Pulso de energia
    - Limpiar seleccion
Si NO son adyacentes:
    - Flash rojo en nodo B
    - Limpiar seleccion
```

---

## Contrato de Modulos Implementados

### ConectarCables (Servidor)
```lua
ConectarCables.activar(nivel, adyacencias, jugador, nivelID)
    -- Conecta ClickDetectors de todos los nodos
    -- Escucha clicks para crear/eliminar cables
    
ConectarCables.desactivar()
    -- Desconecta listeners
    -- Destruye cables existentes
    
ConectarCables.estaActivo() → boolean
```

### ControladorEfectos (Cliente)
```lua
-- Escucha eventos remotos:
--   "NodoSeleccionado"  → Highlight cyan + Billboard + adyacentes dorados
--   "SeleccionCancelada"→ Limpiar todo
--   "ConexionCompletada"→ Limpiar todo
--   "ConexionInvalida"  → Flash rojo
--   "CableDesconectado" → Limpiar todo
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
    
    -- Para puntuacion (futuro)
    Puntuacion = {
        TresEstrellas = number,
        DosEstrellas = number,
        PuntosConexion = number,
        PenaFallo = number,
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

### 1. Sistema de Misiones (Priority: HIGH)
Crear modulo que valide cuando el jugador completa objetivos:
- Conectar nodos especificos
- Seleccionar nodos especificos
- Completar todas las conexiones de un grafo

### 2. Sistema de Puntaje (Priority: HIGH)
- Tracking de conexiones exitosas (+puntos)
- Tracking de fallos (-puntos)
- Tiempo transcurrido
- Calcular estrellas al final

### 3. Guardar Progreso (Priority: MEDIUM)
- Guardar puntuacion al completar nivel
- Desbloquear siguiente nivel
- Guardar estrellas obtenidas

### 4. HUD de Gameplay (Priority: MEDIUM)
- Mostrar misiones actuales
- Mostrar puntuacion en tiempo real
- Mostrar tiempo transcurrido

### 5. Mejoras Visuales (Priority: LOW)
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

### Highlight de Roblox
Se usa `Instance.new("Highlight")` para el efecto de seleccion:
- `FillColor` - Color de relleno
- `OutlineColor` - Color del borde
- `DepthMode = AlwaysOnTop` - Siempre visible

---

## Cambios Realizados vs Plan Original

| Aspecto | Plan Original | Implementacion Actual |
|---------|---------------|----------------------|
| **Estructura** | OrquestadorGameplay explicito | Boot.server maneja orquestacion implicita |
| **Carpetas** | Menu/Gameplay/Servicios separados | Menu/SistemasGameplay/Servicios |
| **Efectos** | ResaltadorNodos.lua | ControladorEfectos.client.lua integrado |
| **Camara** | SistemaCamara unificado | Logica en CargadorNiveles + ControladorMenu |
| **Nombres** | Sistema separado | BillboardNombres integrado en ControladorEfectos |

---

## Archivos Deprecados/Eliminados de GrafosV2

- `VisualEffectsService.client.lua` → Reemplazado por `ControladorEfectos.client.lua`
- `CameraEffects.lua` → Logica movida a `CargadorNiveles`
- `ZoneTriggerManager.lua` → No migrado aun (pendiente)
- `MissionService.lua` → No migrado aun (pendiente)
- `ScoreTracker.lua` → No migrado aun (pendiente)
- `DataService.lua` → Reemplazado por `ServicioProgreso.lua`

---

*Documento actualizado: Fecha actual*
*Version: GrafosV3 - Estado Actual*
