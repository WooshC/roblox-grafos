# GrafosV3 - Agent Documentation

## Project Overview

**GrafosV3** is an educational Roblox game that teaches graph theory concepts through interactive gameplay. Players connect nodes (representing graph vertices) with cables (edges) to solve puzzles across multiple levels with increasing complexity.

The game covers concepts including:
- Nodes and edges (Nodos y Aristas)
- Node degree (Grado de Nodo)
- Directed graphs (Grafos Dirigidos)
- Graph connectivity (Conectividad)
- BFS/DFS traversal algorithms
- Dijkstra's shortest path algorithm

## Technology Stack

- **Platform**: Roblox
- **Language**: Lua
- **Architecture**: Client-Server model with strict separation of concerns
- **Data Persistence**: Roblox DataStore for player progress

## Project Structure

```
GrafosV3/
├── DialogoKit/                              # [LEGACY] Old dialog system (reference only)
│   └── ...
│
├── ReplicatedStorage/                       # Shared between client and server
│   ├── Audio/
│   │   └── ConfigAudio.lua                  # Centralized audio configuration
│   ├── Compartido/                          # Shared modules (client & server)
│   │   ├── GestorColisiones.lua             # Roof/collision visibility manager
│   │   └── ServicioCamara.lua               # Centralized camera control
│   ├── Config/
│   │   └── LevelsConfig.lua                 # Single source of truth for level data
│   ├── DialogoData/                         # Dialog data files
│   │   ├── Nivel0_CarlosBienvenida.lua      # Example dialog data
│   │   └── Bienvenida_1.lua                 # Tutorial dialog
│   └── Efectos/
│       ├── BillboardNombres.lua
│       ├── EfectosCable.lua
│       ├── EfectosHighlight.lua             # Centralized Highlight system (Roblox)
│       ├── EfectosNodo.lua
│       └── PresetTween.lua
│
├── ServerScriptService/                     # Server-side only
│   ├── Nucleo/
│   │   ├── 00_EventRegistry.server.lua      # Creates RemoteEvents on startup
│   │   └── Boot.server.lua                  # Main server entry point
│   ├── Servicios/
│   │   ├── CargadorNiveles.lua              # Level loading/unloading
│   │   ├── ServicioDatos.lua                # DataStore wrapper
│   │   └── ServicioProgreso.lua             # Player progress tracking
│   └── SistemasGameplay/
│       ├── ConectarCables.lua               # Core cable connection system
│       ├── GestorZonas.lua                  # Zone detection system
│       ├── ServicioMisiones.lua             # Mission/objective system
│       ├── ServicioPuntaje.lua              # Score tracking
│       └── ValidadorConexiones.lua          # Connection validation
│
└── StarterPlayerScripts/                    # Client-side only
    ├── Nucleo/
    │   └── ClientBoot.client.lua            # Client entry point
    ├── Compartido/
    │   └── ControladorAudio.client.lua      # Centralized audio controller
    ├── Dialogo/                               # Dialog system (gameplay only)
    │   ├── ControladorDialogo.client.lua    # Dialog orchestrator
    │   ├── DialogoGUISystem.lua             # Main dialog system
    │   ├── DialogoController.lua            # Dialog logic controller
    │   ├── DialogoRenderer.lua              # Visual effects
    │   ├── DialogoEvents.lua                # Button events
    │   ├── DialogoNarrator.lua              # Audio narration
    │   └── DialogoTTS.lua                   # Roblox AudioTextToSpeech API (ES/EN/IT/DE/FR)
    ├── HUD/
    │   ├── ControladorHUD.client.lua        # HUD orchestrator
    │   └── ModulosHUD/
    │       ├── EfectosMapa.lua
    │       ├── EfectosZonas.lua              # Zone billboards (map mode only)
    │       ├── EstadoConexiones.lua
    │       ├── EventosHUD.lua
    │       ├── ModuloMapa.lua
    │       ├── PanelMisionesHUD.lua
    │       ├── PuntajeHUD.lua
    │       ├── TransicionHUD.lua
    │       └── VictoriaHUD.lua
    ├── Menu/
    │   ├── AudioMenu.client.lua             # Menu-specific audio
    │   └── ControladorMenu.client.lua       # Level selection menu
    └── SistemasGameplay/
        ├── AudioGameplay.client.lua         # Gameplay-specific audio
        ├── ControladorColisiones.client.lua # Roof visibility controller (auto-init)
        ├── ControladorEfectos.client.lua    # Visual effects controller
        └── ParticulasConexion.client.lua    # Particles on cable connections
```

## Golden Rule: Strict Menu/Gameplay Separation

**The most important architectural principle**: While the menu is active, ALL gameplay-related systems are completely disconnected.

- Menu System and Gameplay System must NEVER coexist in active states
- Transition: Menu → Gameplay (fade out menu, fade in gameplay)
- Transition: Gameplay → Menu (fade out gameplay, fade in menu)
- Audio: Menu audio and Gameplay audio never play simultaneously

## Naming Conventions

### Code Language Convention
- **Functions**: Written in English (e.g., `init`, `start`, `stop`, `cleanup`)
- **Files/Variables**: Written in Spanish (e.g., `Controlador`, `Gestor`, `Servicio`)

### Module Naming Patterns

| Concept | File Name | Function Names |
|---------|-----------|----------------|
| Orchestrator | Orquestador | init, start, stop, cleanup |
| Manager | Gestor | load, save, get, set |
| Controller | Controlador | enable, disable, show, hide |
| Service | Servicio | activate, deactivate, process |
| Module | Modulo | require, init |

### Spanish Terms Used
- `activar` / `desactivar` - activate / deactivate
- `iniciar` / `detener` - start / stop
- `limpiar` - cleanup
- `jugador` - player
- `nivel` - level
- `puntaje` - score
- `mision` - mission
- `zona` - zone
- `cable` - cable
- `nodo` - node
- `conexion` - connection
- `camara` - camera
- `audio` - audio

## Audio System Architecture

The audio system uses **existing Sound objects** in `ReplicatedStorage/Audio/` rather than creating sounds from asset IDs.

### Flow
1. Original sounds stay in `ReplicatedStorage/Audio` (never moved)
2. `ControladorAudio` clones sounds when needed
3. Clones are played and auto-destroyed (for SFX)
4. BGM and Ambience clones persist until stopped

### Audio Structure Required
```
ReplicatedStorage/Audio/
├── Ambiente/
│   └── Nivel0, Nivel1, Nivel2, Nivel3, Nivel4
├── BGM/
│   └── MusicaMenu/
│       ├── CambiarEscena, Click, MusicaCreditos, MusicaMenu, Play, Seleccion
├── SFX/
│   └── CableConnect, CableSnap, Click, ConnectionFailed, Error, Success
└── Victoria/
    └── Fanfare, Tema
```

### Audio API
```lua
-- SFX (cloned, auto-destroy)
ControladorAudio.playSFX("CableConnect")
ControladorAudio.playUI("Click")

-- BGM (cloned, persists)
ControladorAudio.playBGM("MusicaMenu", fadeInDuration)
ControladorAudio.stopBGM(fadeOutDuration)
ControladorAudio.crossfadeBGM("MusicaCreditos", duration)

-- Ambience
ControladorAudio.playAmbientePorNivel(nivelID)
ControladorAudio.stopAmbiente(fadeOutDuration)

-- Gameplay helpers
ControladorAudio.playCableConectar(true)  -- success
ControladorAudio.playCableConectar(false) -- failure
ControladorAudio.playVictoria() -- Fanfare then Theme

-- Global control
ControladorAudio.setMasterVolume(0.5)
ControladorAudio.muteAll()
ControladorAudio.cleanup()
```

## Key Modules

### Boot.server.lua (Server Entry Point)
- Waits for `EventRegistry` to create RemoteEvents
- Loads core services (`ServicioProgreso`, `CargadorNiveles`)
- Handles player connection/disconnection
- Manages Menu → Gameplay transitions
- Defines `_G.SistemaGameplay` for global state

### ClientBoot.client.lua (Client Entry Point)
- Loads `ControladorAudio` first (shared system)
- Waits for server ready signal
- Manages GUI state (Menu vs HUD)

### LevelsConfig.lua (Single Source of Truth)
Centralized configuration for all levels including:
- Level metadata (name, description, image, tag, section)
- Scoring rules (three-star threshold, XP reward, penalties)
- Graph adjacencies (valid node connections)
- Zones and triggers
- Node display names
- Missions/objectives

### ConectarCables.lua (Core Gameplay)
- Handles node selection and cable creation
- Validates connections against `LevelsConfig` adjacencies
- Supports both in-world clicks and map-based connections
- Creates visual Beams between nodes
- Triggers callbacks for scoring and missions

### CargadorNiveles.lua (Level Management)
- Loads level models from `ServerStorage`
- Spawns and positions player character
- Initializes gameplay systems in order:
  1. `ServicioPuntaje`
  2. `ServicioMisiones`
  3. `GestorZonas`
  4. `ConectarCables`
- Unloads systems in reverse order when returning to menu

## RemoteEvents Structure

All RemoteEvents are created in `ReplicatedStorage/EventosGrafosV3/Remotos/` by `EventRegistry.server.lua`:

| Event | Direction | Purpose |
|-------|-----------|---------|
| `ServidorListo` | Server → Client | Server ready, show menu |
| `ObtenerProgresoJugador` | Client ↔ Server | Get player progress data |
| `IniciarNivel` | Client → Server | Player clicked play |
| `NivelListo` | Server → Client | Level loaded, show HUD |
| `NivelDescargado` | Server → Client | Level unloaded, show menu |
| `VolverAlMenu` | Client → Server | Player wants to exit |
| `CableDragEvent` | Server → Client | Show cable drag preview |
| `NotificarSeleccionNodo` | Server → Client | Node selection effects |
| `PulsoEvent` | Server → Client | Energy pulse animation |
| `ActualizarPuntuacion` | Server → Client | Real-time score updates |
| `PuntuacionFinal` | Server → Client | Final level results |
| `ActualizarMisiones` | Server → Client | Mission panel updates |
| `NivelCompletado` | Server → Client | Victory screen trigger |
| `MapaClickNodo` | Client → Server | Click on overhead map node |
| `ConectarDesdeMapa` | Client → Server | Request connection from map |

## Level Node Structure

Each node in a level must follow this hierarchy:
```
Nodo (Model)
├── Decoracion/          (optional Model)
└── Selector            (BasePart) ← REQUIRED
    ├── Attachment      (Attachment) ← For Beam
    └── ClickDetector   (ClickDetector) ← For clicks
```

Requirements:
- `Selector` must be a `BasePart` with `CanQuery = true`
- `ClickDetector.MaxActivationDistance = 50` (studs)
- Does NOT require `CanCollide = true`

## Camera Service Architecture

**NEW**: Centralized camera control system to avoid code duplication and camera state conflicts.

### ServicioCamara (Shared Module)
Located in `ReplicatedStorage/Compartido/ServicioCamara.lua`

Used by:
- `ModuloMapa` - Overhead map view
- `ControladorDialogo` - Dialog camera movements
- Any other system needing camera control

### API
```lua
local ServicioCamara = require(RS.Compartido.ServicioCamara)

-- Save current camera state
ServicioCamara.guardarEstado()

-- Move camera to CFrame with animation
ServicioCamara.moverA(cframeObjetivo, duracion, suave, onComplete)

-- Move camera to TOP-DOWN view over a target
ServicioCamara.moverTopDown(enfoque, altura, duracion)
-- enfoque can be: string (node name), Vector3, BasePart, or Model

-- Restore camera to saved state
ServicioCamara.restaurar(duracion)
ServicioCamara.restaurarInmediato()

-- Quick block/unblock (set Scriptable without moving)
ServicioCamara.bloquear()
ServicioCamara.liberar()
```

### Camera State Management
The service handles camera state automatically:
- Saves original state on first camera operation
- Prevents multiple simultaneous transitions
- Cleans up state after restore

## Collision/Roof Management Architecture

**NEW**: Centralized roof/ceiling visibility management system.

### GestorColisiones (Shared Module)
Located in `ReplicatedStorage/Compartido/GestorColisiones.lua`

**Responsabilidad única**: Gestionar la visibilidad de techos y colisiones.

Used by:
- `ControladorColisiones` (client) - Auto-initializes on level load
- `ModuloMapa` - Hides/shows roofs when opening/closing map
- `ControladorDialogo` - Can hide roofs during specific dialogs

### ControladorColisiones (Client Controller)
Located in `StarterPlayerScripts/SistemasGameplay/ControladorColisiones.client.lua`

Automatically initializes the `GestorColisiones` when a level loads:
- Captures roof state on `NivelListo` event
- Cleans up on `NivelDescargado` event

### API - GestorColisiones
```lua
local GestorColisiones = require(RS.Compartido.GestorColisiones)

-- Capture roof state from level model (call once on level load)
GestorColisiones:capturar(nivelModelo)

-- Hide roofs (for overhead map view)
GestorColisiones:ocultarTecho()

-- Restore roofs to original state
GestorColisiones:restaurar()

-- Clean up references (call on level unload)
GestorColisiones:liberar()

-- Check if roofs are captured
GestorColisiones:tieneTechosCapturados()
```

### API - ControladorColisiones (Global)
```lua
-- Access via _G.ControladorColisiones
local CC = _G.ControladorColisiones

-- Hide/restore roofs manually
CC.ocultarTechos()
CC.restaurarTechos()
CC.tieneTechos()

-- Access underlying GestorColisiones
local Gestor = CC.obtenerGestor()
```

### Usage in Dialogs
To hide roofs during a specific dialog:
```lua
-- In dialog data file or prompt attributes:
config = {
    ocultarTechos = true  -- Hide roofs during this dialog
}

-- Or programmatically:
ControladorDialogo.iniciar("MiDialogo", {
    ocultarTechos = true
})
```

### Architecture Benefits
1. **Single Responsibility**: Only one system manages roof state
2. **No Duplication**: Map and Dialogs don't duplicate roof logic
3. **Automatic Cleanup**: Controller handles level load/unload automatically
4. **State Safety**: Original state is preserved and can be restored

## Zone Billboard System (Map Mode)

**NEW**: Billboards showing zone descriptions appear only in map mode.

### EfectosZonas (HUD Module)
Located in `StarterPlayerScripts/HUD/ModulosHUD/EfectosZonas.lua`

**Responsibility**: Display zone description billboards above zone triggers when the map is open.

Features:
- Shows zone descriptions from `LevelsConfig.Zonas[*].Descripcion`
- Only visible in map mode
- Automatically hides the billboard of the player's current zone
- Updates when player enters/exits zones

### Configuration in LevelsConfig
```lua
Zonas = {
    ["Zona_Estacion_1"] = { 
        Trigger = "ZonaTrigger_Estacion1",  -- Name of the trigger part
        Descripcion = "Nodos y Aristas"     -- Text shown in billboard
    },
    -- ... more zones
}
```

### How It Works
1. When map opens (`ModuloMapa.abrir()`):
   - Creates billboards above all zone triggers
   - Shows all zone descriptions
   - Hides the billboard of the current zone (if any)

2. When player enters a zone:
   - `ZonaActual` attribute changes on player
   - Billboard for that zone is hidden
   - Billboard for previous zone is shown again

3. When map closes:
   - All zone billboards are hidden

### API - EfectosZonas
```lua
local EfectosZonas = require(script.Parent.EfectosZonas)

-- Initialize (called by ModuloMapa)
EfectosZonas.inicializar(nivelModel, configNivel)

-- Show all zone billboards (hides current zone automatically)
EfectosZonas.mostrarTodos()

-- Hide all zone billboards
EfectosZonas.ocultarTodos()

-- Set current zone (hides its billboard, shows previous)
EfectosZonas.establecerZonaActual(nombreZona)

-- Update visibility based on current zone
EfectosZonas.actualizarVisibilidad()

-- Clean up all billboards
EfectosZonas.limpiar()
```

### Visual Style
- Black background with transparency
- Cyan border
- White text with GothamBold font
- Always on top rendering
- Positioned 8 studs above the trigger part

## Highlight System (Roblox Highlight Instances)

**NEW**: Centralized system using Roblox's native Highlight instances for visual effects.

### EfectosHighlight (Shared Module)
Located in `ReplicatedStorage/Efectos/EfectosHighlight.lua`

**Responsibility**: Manage Roblox Highlight instances for zones, nodes, and error effects.

Features:
- Type-based highlight configurations (ZONA, SELECCIONADO, ADYACENTE, ERROR)
- Automatic cleanup and management
- Flash effects for errors
- Integration with zone and node systems

### Highlight Types

| Type | Fill Color | Outline | Use Case |
|------|------------|---------|----------|
| ZONA | Cyan | Cyan | Zone triggers in map mode |
| SELECCIONADO | Cyan | Cyan | Selected node |
| ADYACENTE | Gold | Gold | Adjacent/Connectable nodes |
| ERROR | Red | Red | Invalid connection flash |

### API - EfectosHighlight
```lua
local EfectosHighlight = require(ReplicatedStorage.Efectos.EfectosHighlight)

-- Create a persistent highlight
EfectosHighlight.crear("NombreUnico", adornee, "ZONA")
EfectosHighlight.crear("NombreUnico", adornee, "SELECCIONADO")
EfectosHighlight.crear("NombreUnico", adornee, "ADYACENTE")

-- Create a temporary flash effect (auto-destroys)
EfectosHighlight.flash("NombreUnico", adornee, "ERROR", 0.5)

-- Destroy a specific highlight
EfectosHighlight.destruir("NombreUnico")

-- Clean all highlights
EfectosHighlight.limpiarTodo()

-- Clean by type
EfectosHighlight.limpiarPorTipo("ZONA")

-- Node-specific helpers
EfectosHighlight.resaltarNodo(nodoModel, "SELECCIONADO")
EfectosHighlight.resaltarAdyacente(nodoModel)
EfectosHighlight.flashErrorNodo(nodoModel, 0.5)
EfectosHighlight.limpiarNodo(nodoModel)

-- Zone-specific helpers
EfectosHighlight.resaltarZona(nombreZona, parteTrigger)
EfectosHighlight.limpiarZona(nombreZona)
EfectosHighlight.limpiarTodasZonas()
```

### Integration with Node Selection

When a node is selected:
1. `ControladorEfectos` receives "NodoSeleccionado" event
2. Creates Highlight for selected node (cyan)
3. Creates Highlights for adjacent nodes (gold)
4. Clears previous highlights

When connection fails:
1. `ControladorEfectos` receives "ConexionInvalida" event
2. Creates ERROR highlight with flash effect
3. Auto-destroys after animation

### Integration with Zone Map View

When map opens:
1. `EfectosZonas` creates billboards AND highlights for each zone
2. Highlights make zone triggers visible through walls
3. Current zone highlight is dimmed (player is there)

When player enters zone:
1. `ModuloMapa` detects ZonaActual change
2. Dim highlight of current zone
3. Restore highlight of previous zone

## Development Guidelines

### Adding a New Sound
1. Create Sound object in `ReplicatedStorage/Audio/` (in appropriate subfolder)
2. Add configuration to `ConfigAudio.lua` with path
3. Use via `ControladorAudio.playSFX("Name")` or appropriate method

### Adding a New Level
1. Add level configuration to `LevelsConfig.lua`
2. Create level model in `ServerStorage`
3. Ensure node structure follows conventions
4. Add adjacency definitions for valid connections

### Dialog System (Refactored Implementation)

The dialog system is now integrated into the main architecture and only works during gameplay.

#### Important: Map Auto-Close
**Before any dialog starts, the map is automatically closed if open.** This prevents camera state conflicts and ensures the dialog camera movements work correctly.

```lua
-- In ControladorDialogo.iniciarDialogo()
if ModuloMapa.estaAbierto() then
    ModuloMapa.cerrar()
    task.wait(0.1) -- Wait for cleanup
end
```

#### Camera Movement in Dialogs
The camera does **NOT** move automatically when the dialog starts. Camera movements happen only when:
1. A dialog line has an `Evento` function that calls `ControladorDialogo.moverCamara()`
2. Explicitly called via the dialog's event system

**Example dialog with camera movement:**
```lua
{
    Id = "zona_1",
    Actor = "Carlos",
    Texto = "Dirígete a la Zona 1...",
    
    Evento = function(gui, metadata)
        -- Move camera only when this line is shown
        _G.ControladorDialogo.moverCamara("Nodo1_z1", 1.0)
    end,
    
    Siguiente = "confirmacion_final"
}
```

#### Structure
```
StarterPlayerScripts/Dialogo/          # Dialog modules
ReplicatedStorage/DialogoData/         # Dialog content data
StarterGui/DialogoGUI                  # Dialog UI (ScreenGui)
```

#### Activation Flow
1. Level loads → `NivelActual` created in Workspace
2. `ControladorDialogo` detects level and searches for `DialoguePrompts` folder
3. ProximityPrompts are automatically configured
4. Player triggers prompt → **Map closes if open** → Dialog starts
5. Player movement blocked, HUD hidden, dialog UI shows
6. Camera moves only when dialog lines request it
7. On close: movement restored, camera restored, HUD restored

#### Level Setup for Dialogs
```
NivelActual (Model)
└── DialoguePrompts (Folder)
    └── [DialogModel] (Model)
        ├── Attributes:
        │   ├── DialogoID = "Nivel0_Intro"
        │   ├── ActionText = "Hablar"
        │   ├── ObjectText = "Carlos"
        │   ├── Distancia = 20
        │   ├── UnaVez = true
        │   ├── BloquearMovimiento = true    -- Block player movement
        │   ├── BloquearSalto = true         -- Block jumping
        │   ├── ApuntarCamara = true         -- Block camera (Scriptable)
        │   └── PermitirConexiones = false   -- Allow cable connections
        └── PromptPart (Part)
            └── ProximityPrompt
```

#### Dialog Configuration Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `DialogoID` | String | Model name | ID matching the dialog in Lua file |
| `BloquearMovimiento` | Boolean | true | Block player walk |
| `BloquearSalto` | Boolean | true | Block jumping |
| `BloquearCarrera` | Boolean | true | Block sprint |
| `ApuntarCamara` | Boolean | true | Block camera (sets Scriptable) |
| `PermitirConexiones` | Boolean | false | Allow cable connections during dialog |
| `OcultarHUD` | Boolean | true | Hide HUD during dialog |
| `UnaVez` | Boolean | false | Only show dialog once |

#### Creating Dialog Content
1. Create/edit file in `ReplicatedStorage/DialogoData/NivelX_Dialogos.lua`
2. Define dialogs with lines, options, and metadata
3. Set `DialogoID` attribute on the prompt model to match the dialog key

See `DIALOGO_SISTEMA_GUIA.md` for complete documentation.

### Connection Particles System

Visual particle effects traveling along cable connections.

#### Features
- Particles travel from node to node along connections
- **Directed graphs**: One-way particle flow
- **Undirected graphs**: Two-way particle flow (A→B and B→A)
- Configurable speed, color, and frequency

#### Location
```
StarterPlayerScripts/SistemasGameplay/ParticulasConexion.client.lua
```

#### Usage
Particles start automatically when connections are created via `CableCreado` RemoteEvent.

## Important Notes

- **No Character Auto-Load**: `Players.CharacterAutoLoads = false` in menu
- **Single Entry Point**: `Boot.server.lua` for server, `ClientBoot.client.lua` for client
- **Strict Cleanup**: All systems must properly cleanup when returning to menu
- **Audio Separation**: Menu and Gameplay audio never overlap
- **Event-Driven**: Heavy use of RemoteEvents for client-server communication

---

## Architecture Observations & Future Improvements

### Code Duplication Resolved

#### Camera Control (FIXED)
**Before**: Camera code was duplicated in:
- `ModuloMapa.lua` - Map overhead view
- `ControladorDialogo.client.lua` - Dialog camera movements

**Solution**: Created `ServicioCamara` in `ReplicatedStorage/Compartido/`
- Centralized camera state management
- Consistent animation/easing
- Prevents conflicting camera operations

### Systems Integration Issues Resolved

#### Map vs Dialog Camera Conflict (FIXED)
**Problem**: If map was open when dialog started, both systems tried to control the camera simultaneously, causing bugs.

**Solution**: 
```lua
-- ControladorDialogo now closes map before starting any dialog
if ModuloMapa.estaAbierto() then
    ModuloMapa.cerrar()
    task.wait(0.1)
end
```

### Recommended Future Improvements

#### 1. Unified Visual Effects System
**Current State**: 
- `EfectosNodo.lua` - Node effects
- `EfectosCable.lua` - Cable effects  
- `EfectosMapa.lua` - Map effects
- `DialogoRenderer.lua` - Dialog effects

**Recommendation**: Create `ServicioEfectosVisuales` with:
```lua
ServicioEfectosVisuales.aplicar(nodo, tipoEfecto, configuracion)
ServicioEfectosVisuales.limpiar(nodo)
ServicioEfectosVisuales.limpiarTodo()
```

#### 2. Centralized Input Management
**Current State**: Each system handles its own input:
- `ModuloMapa` - Map click detection
- `ConectarCables` - In-world clicks
- `ControladorDialogo` - Dialog options

**Recommendation**: Create `ServicioInput` that:
- Prioritizes active systems (Dialog > Map > Gameplay)
- Prevents conflicting input handling
- Provides clean input state queries

#### 3. State Machine for Game States
**Current State**: Boolean flags scattered across systems:
```lua
-- In ControladorDialogo
dialogoActivo = false

-- In ModuloMapa
mapaAbierto = false

-- In HUD
hudActivo = false
```

**Recommendation**: Centralized state machine:
```lua
ServicioEstado.cambiar("MENU")      -- Menu state
ServicioEstado.cambiar("GAMEPLAY")  -- Normal gameplay
ServicioEstado.cambiar("MAPA")      -- Map open
ServicioEstado.cambiar("DIALOGO")   -- Dialog active

-- Automatic handling:
-- Entering DIALOGO: closes MAPA, blocks input
-- Entering MAPA: blocks GAMEPLAY input
```

#### 4. Event Bus System
**Current State**: Direct RemoteEvent connections everywhere

**Recommendation**: Event bus for decoupled communication:
```lua
-- Publisher
ServicioEventos.publicar("NodoSeleccionado", nodo)

-- Subscriber
ServicioEventos.suscribir("NodoSeleccionado", function(nodo)
    -- Handle selection
end)
```

#### 5. Service Locator Pattern
**Current State**: Services accessed via `_G` or direct requires

**Recommendation**: Centralized service registry:
```lua
local ServicioX = Servicios.obtener("ServicioX")
-- Instead of:
local ServicioX = require(path.to.ServicioX)
-- or
_G.ServicioX
```

### Current Anti-Patterns to Avoid

1. **Direct `_G` usage**: Use dependency injection or service locator
2. **Polling with loops**: Use events instead of `while true` loops
3. **Deep nesting**: Flatten nested if-statements with early returns
4. **Magic numbers**: Move to CONFIG tables
5. **String literals**: Use constants for event names, attribute names

### Testing Checklist for New Features

- [ ] Works when map is open
- [ ] Works when dialog is active
- [ ] Proper cleanup on level exit
- [ ] Proper cleanup on return to menu
- [ ] Audio doesn't overlap between states
- [ ] Camera state restored correctly
- [ ] HUD shows/hides correctly
- [ ] No memory leaks (disconnected events)

