# Sistema de Audio para GrafosV3 - Resumen de Implementacion

## Como Funciona

El sistema **usa directamente los objetos Sound que ya existen** en `ReplicatedStorage/Audio/`. No usa IDs de Roblox ni crea sonidos desde cero.

### Flujo de Reproduccion

```
ReplicatedStorage/Audio/
├── SFX/CableConnect (Sound) ──┐
├── SFX/CableSnap (Sound) ─────┤
├── BGM/MusicaMenu/MusicaMenu ─┼──► ControladorAudio:Clone() ──► SoundService/AudioGrafosV3_Activo
├── Ambiente/Nivel0 (Sound) ───┤
└── Victoria/Fanfare (Sound) ──┘
```

1. Los sonidos originales se quedan en `ReplicatedStorage/Audio` (no se mueven)
2. Cuando se necesita reproducir, el `ControladorAudio` hace un `Clone()` del sonido original
3. El clon se reproduce y se destruye automaticamente al terminar (para SFX)
4. Los clones de BGM y Ambiente se mantienen activos hasta que se detienen

---

## Archivos Creados

### 1. ConfigAudio.lua
**Ubicacion:** `ReplicatedStorage/Audio/ConfigAudio.lua`

Configuracion centralizada que referencia las **rutas** a los objetos Sound existentes:

```lua
CableConnect = {
    Nombre = "CableConnect",
    Categoria = "SFX",
    Volumen = 0.7,
    Pitch = 1.0,
    Loop = false,
    Ruta = "SFX/CableConnect",  -- <-- Ruta en ReplicatedStorage/Audio/
    Descripcion = "..."
}
```

### 2. ControladorAudio.client.lua
**Ubicacion:** `StarterPlayerScripts/Compartido/ControladorAudio.client.lua`

Motor de audio que:
- Busca sonidos originales en `ReplicatedStorage/Audio/` por ruta
- Clona los sonidos para reproducirlos
- Maneja fades in/out
- Controla volumen maestro
- Limpia sonidos automaticamente

### 3. AudioMenu.client.lua
**Ubicacion:** `StarterPlayerScripts/Menu/AudioMenu.client.lua`

Audio especifico del menu:
- Se activa automaticamente al iniciar
- Reproduce `MusicaMenu` en loop
- Conecta sonidos UI a botones (hover, click, play, back)
- Cambia a `MusicaCreditos` cuando se abre creditos
- Se desactiva cuando inicia un nivel

### 4. AudioGameplay.client.lua
**Ubicacion:** `StarterPlayerScripts/SistemasGameplay/AudioGameplay.client.lua`

Audio especifico del gameplay:
- Se activa cuando el servidor envia "NivelListo"
- Reproduce ambiente del nivel (`Ambiente/Nivel0`, `Nivel1`, etc.)
- Escucha eventos del servidor:
  - `NodoSeleccionado` → Click
  - `ConexionCompletada` → CableConnect
  - `ConexionInvalida` → ConnectionFailed + CableSnap
  - `CableDesconectado` → CableSnap
  - `NivelCompletado` → Victoria (Fanfare + Tema)
- Se desactiva al volver al menu

---

## Estructura Requerida en Roblox Studio

Debes tener esta estructura en `ReplicatedStorage/Audio` (segun tu imagen):

```
ReplicatedStorage/
└── Audio/
    ├── Ambiente/
    │   ├── Nivel0 (Sound)
    │   ├── Nivel1 (Sound)
    │   ├── Nivel2 (Sound)
    │   ├── Nivel3 (Sound)
    │   └── Nivel4 (Sound)
    │
    ├── BGM/
    │   └── MusicaMenu/
    │       ├── CambiarEscena (Sound)
    │       ├── Click (Sound)
    │       ├── MusicaCreditos (Sound - Loop activado)
    │       ├── MusicaMenu (Sound - Loop activado)
    │       ├── Play (Sound)
    │       └── Seleccion (Sound)
    │
    ├── SFX/
    │   ├── CableConnect (Sound)
    │   ├── CableSnap (Sound)
    │   ├── Click (Sound)
    │   ├── ConnectionFailed (Sound)
    │   ├── Error (Sound)
    │   └── Success (Sound)
    │
    └── Victoria/
        ├── Fanfare (Sound)
        └── Tema (Sound - Loop activado)
```

**Importante:** Los sonidos originales deben tener configurado:
- `Looped = true` para MusicaMenu, MusicaCreditos, Ambiente, Tema
- `Looped = false` para SFX y efectos

---

## API del ControladorAudio

```lua
local ControladorAudio = require(path.to.ControladorAudio)

-- SFX (clonado y autodestruccion)
ControladorAudio.playSFX("CableConnect")
ControladorAudio.playSFX("CableSnap")
ControladorAudio.playSFX("Success")

-- UI (tambien usa SFX)
ControladorAudio.playUI("Click")
ControladorAudio.playUI("Play")
ControladorAudio.playUI("Back")

-- BGM (clonado, persiste hasta stop)
ControladorAudio.playBGM("MusicaMenu", fadeInDuracion)
ControladorAudio.stopBGM(fadeOutDuracion)
ControladorAudio.crossfadeBGM("MusicaCreditos", duracion)

-- Ambiente (clonado, persiste hasta stop)
ControladorAudio.playAmbientePorNivel(nivelID) -- Nivel0, Nivel1, etc.
ControladorAudio.stopAmbiente(fadeOutDuracion)

-- Gameplay helpers
ControladorAudio.playCableConectar(true)  -- exito
ControladorAudio.playCableConectar(false) -- fallo
ControladorAudio.playNodoSeleccionado()
ControladorAudio.playVictoria() -- Fanfare luego Tema

-- Control global
ControladorAudio.setMasterVolume(0.5) -- 0 a 1
ControladorAudio.muteAll()
ControladorAudio.unmuteAll()
ControladorAudio.cleanup() -- Detener todo
```

---

## Separacion Menu/Gameplay

| Estado | Audio Activo |
|--------|-------------|
| En Menu | AudioMenu (BGM, UI clicks) |
| En Gameplay | AudioGameplay (SFX, Ambiente) |
| Transicion Menu→Gameplay | Fade out BGM → Fade in Ambiente |
| Transicion Gameplay→Menu | Fade out Ambiente → Fade in BGM |

**Nunca suenan ambos al mismo tiempo.**

---

## Como Agregar Nuevos Sonidos

### Paso 1: Crear el objeto Sound en Roblox Studio
1. Ve a `ReplicatedStorage/Audio/`
2. Crea el objeto Sound en la carpeta correspondiente (SFX, BGM, etc.)
3. Sube tu archivo de audio o usa el que ya tienes
4. Configura `Looped` segun corresponda

### Paso 2: Agregar configuracion
Edita `ConfigAudio.lua`:

```lua
SFX = {
    -- ... sonidos existentes ...
    MiNuevoSonido = {
        Nombre = "MiNuevoSonido",
        Categoria = "SFX",
        Volumen = 0.7,
        Pitch = 1.0,
        Loop = false,
        Ruta = "SFX/MiNuevoSonido", -- Ruta en ReplicatedStorage/Audio
        Descripcion = "Descripcion del sonido"
    },
}
```

### Paso 3: Usar el sonido
```lua
ControladorAudio.playSFX("MiNuevoSonido")
```

---

## Performance

- **Sin clonado innecesario**: Los sonidos originales nunca se mueven de `ReplicatedStorage`
- **Pool limitado**: Maximo 6 SFX simultaneos (configurable)
- **Auto-cleanup**: Los SFX se destruyen automaticamente al terminar
- **Reutilizacion**: BGM y Ambiente se clonan una vez y se reusan

---

## Troubleshooting

### No se escuchan sonidos
- Verificar que los objetos Sound existan en `ReplicatedStorage/Audio`
- Revisar que las rutas en `ConfigAudio.lua` sean correctas
- Verificar que el volumen maestro no este en 0
- Revisar que `SoundService` no este muteado

### Errores en consola
- `[ControladorAudio] No se encontro: XXX` → La ruta en ConfigAudio no coincide con la estructura
- `[ControladorAudio] El objeto no es un Sound` → Hay una carpeta con nombre de sonido

### Musica no hace loop
- Verificar que el objeto Sound original tenga `Looped = true`
- El clon hereda esta propiedad

---

*Implementado: 2026-02-27*
*Version: GrafosV3 con Sistema de Audio (usando objetos Sound existentes)*
