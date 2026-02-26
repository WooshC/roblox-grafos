# Plan de Refactorización — HUDController

## Problema actual

`HUDController.client.lua` ya tiene ~300 líneas y concentra:
- Gestión de eventos de Roblox (referencias, conexiones)
- Lógica de fade/transición
- Lógica del modal de salida
- Construcción dinámica del panel de misiones
- Pantalla de victoria
- Actualización del score en HUD

Cada nueva feature (diálogos, guía, tienda, etc.) lo haría crecer sin control.

---

## Solución propuesta: módulos LocalScript bajo StarterPlayerScripts

```
StarterPlayerScripts/
├── HUDController.client.lua        ← orquestador puro (~60 líneas)
└── HUDModules/                     ← carpeta de módulos (ModuleScripts)
    ├── HUDEvents.lua               ← referencias centralizadas a RemoteEvents
    ├── HUDMisionPanel.lua          ← panel de misiones (rebuildMisionPanel)
    ├── HUDVictory.lua              ← pantalla de victoria (showVictory)
    ├── HUDScore.lua                ← label de puntaje en BarraSuperior
    ├── HUDFade.lua                 ← overlay de fade negro (fadeToBlack, resetFade)
    └── HUDModal.lua                ← modal de confirmación de salida
```

---

## Responsabilidad de cada módulo

### `HUDController.client.lua` (orquestador)
Solo conecta eventos al inicio y delega en los módulos.
```lua
local HUDEvents    = require(HUDModules.HUDEvents)
local HUDMision    = require(HUDModules.HUDMisionPanel)
local HUDVictory   = require(HUDModules.HUDVictory)
local HUDScore     = require(HUDModules.HUDScore)
local HUDFade      = require(HUDModules.HUDFade)
local HUDModal     = require(HUDModules.HUDModal)

-- LevelReady
HUDEvents.levelReady:Connect(function(data)
    HUDFade.reset()
    HUDMision.reset()
    HUDVictory.hide()
    hud.Enabled = true
end)

-- UpdateMissions
HUDEvents.updateMissions:Connect(function(data)
    HUDMision.rebuild(data)
end)

-- UpdateScore
HUDEvents.updateScore:Connect(function(data)
    HUDScore.set(data.puntajeBase)
end)

-- LevelCompleted
HUDEvents.levelCompleted:Connect(function(snap)
    HUDVictory.show(snap)
end)

-- Botones
HUDModal.connectButtons(hud, HUDFade)
HUDMision.connectToggle(hud)
HUDVictory.connectButtons(hud, HUDFade)
```

---

### `HUDEvents.lua`
Centraliza todas las referencias a RemoteEvents para que ningún módulo tenga que hacer `WaitForChild` por su cuenta.
```lua
local M = {}
local RS      = game:GetService("ReplicatedStorage")
local remotes = RS:WaitForChild("Events"):WaitForChild("Remotes")

M.levelReady      = remotes:WaitForChild("LevelReady")
M.updateMissions  = remotes:WaitForChild("UpdateMissions")
M.updateScore     = remotes:WaitForChild("UpdateScore")
M.levelCompleted  = remotes:WaitForChild("LevelCompleted")
M.returnToMenu    = remotes:WaitForChild("ReturnToMenu")
M.restartLevel    = remotes:WaitForChild("RestartLevel")

return M
```

---

### `HUDMisionPanel.lua`
Toda la lógica de construir el panel de misiones: `rebuild(data)`, `reset()`, `connectToggle(hud)`.
- Vista resumen (fuera de zona): contador por zona.
- Vista detalle (dentro de zona): misiones de esa zona con tachado RichText.

---

### `HUDVictory.lua`
`show(snap)`, `hide()`, `connectButtons(hud, fade)`.
Rellena las estadísticas de la pantalla de victoria a partir del snapshot.

---

### `HUDScore.lua`
`set(valor)` — encuentra `BarraSuperior/PanelPuntuacion/ContenedorPuntos/Valor` y actualiza el texto.

---

### `HUDFade.lua`
`fadeToBlack(duration, callback)`, `reset()` — maneja el overlay negro de transición.

---

### `HUDModal.lua`
`connectButtons(hud, fade)` — conecta BtnSalir, BtnCancelar, BtnConfirmar con la lógica de ReturnToMenu.

---

## Reglas de diseño para los módulos

1. **Sin estado global compartido entre módulos** — cada módulo guarda su propio estado local. Si dos módulos necesitan comunicarse, lo hacen a través del orquestador (HUDController) o mediante parámetros explícitos.
2. **Cada módulo recibe el `hud` ScreenGui como parámetro en su función `init` o `connectButtons`** — nunca lo busca por sí solo en PlayerGui para evitar carreras de timing.
3. **Agregar una nueva feature = crear un nuevo módulo** — el orquestador solo llama `require` y conecta eventos. Nunca crece más de ~80 líneas.
4. **Nombres de módulo con prefijo `HUD`** — fácil de identificar en el Explorer de Studio.

---

## Orden de migración sugerido

| Paso | Acción | Esfuerzo |
|------|--------|----------|
| 1 | Crear carpeta `HUDModules` en StarterPlayerScripts | Bajo |
| 2 | Extraer `HUDFade.lua` (más aislado, sin dependencias) | Bajo |
| 3 | Extraer `HUDScore.lua` (3 líneas de lógica) | Bajo |
| 4 | Extraer `HUDModal.lua` | Bajo |
| 5 | Extraer `HUDVictory.lua` | Medio |
| 6 | Extraer `HUDMisionPanel.lua` (la más grande) | Medio |
| 7 | Extraer `HUDEvents.lua` y simplificar orquestador | Bajo |

Cada paso es independiente y reversible. Se puede migrar de a uno sin romper el resto.
