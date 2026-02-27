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
│   ├── Config/
│   │   └── LevelsConfig.lua                 # Single source of truth for level data
│   ├── Compartido/                          # Shared modules
│   ├── DialogoData/                         # Dialog data files
│   │   └── Nivel0_Dialogos.lua              # Example dialog data
│   └── Efectos/
│   ├── Audio/
│   │   └── ConfigAudio.lua                  # Centralized audio configuration
│   ├── Config/
│   │   └── LevelsConfig.lua                 # Single source of truth for level data
│   ├── Compartido/                          # Shared modules (currently empty)
│   └── Efectos/
│       ├── BillboardNombres.lua
│       ├── EfectosCable.lua
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
        └── ControladorEfectos.client.lua    # Visual effects controller
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

### Dialog System (New Implementation)

The dialog system is now integrated into the main architecture and only works during gameplay.

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
4. Player triggers prompt → Dialog starts
5. HUD hides automatically, dialog UI shows
6. On close: HUD restores

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
        │   └── UnaVez = true
        └── PromptPart (Part)
            └── ProximityPrompt
```

#### Creating Dialog Content
1. Create/edit file in `ReplicatedStorage/DialogoData/NivelX_Dialogos.lua`
2. Define dialogs with lines, options, and metadata
3. Set `DialogoID` attribute on the prompt model to match the dialog key

See `DIALOGO_SISTEMA_GUIA.md` for complete documentation.

## Important Notes

- **No Character Auto-Load**: `Players.CharacterAutoLoads = false` in menu
- **Single Entry Point**: `Boot.server.lua` for server, `ClientBoot.client.lua` for client
- **Strict Cleanup**: All systems must properly cleanup when returning to menu
- **Audio Separation**: Menu and Gameplay audio never overlap
- **Event-Driven**: Heavy use of RemoteEvents for client-server communication
