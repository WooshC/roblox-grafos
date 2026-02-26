# HUDController — Documentación de Módulos

**Sistema:** EDA Quest v2.0  
**Ubicación:** `StarterPlayer > StarterPlayerScripts > HUDController.client.lua`  
**Tipo:** LocalScript orquestador + 6 módulos ModuleScript

---

## Arquitectura General

StarterPlayerScripts/
├── HUDController.client.lua      ← Orquestador puro (~50 líneas)
└── HUDModules/                   ← Carpeta de módulos
├── HUDEvents.lua             ← Referencias centralizadas a RemoteEvents
├── HUDFade.lua               ← Overlay de fade negro para transiciones
├── HUDScore.lua              ← Label de puntaje en BarraSuperior
├── HUDModal.lua              ← Modal de confirmación de salida
├── HUDMisionPanel.lua        ← Panel desplegable de misiones
└── HUDVictory.lua            ← Pantalla de victoria con estadísticas


**Regla de oro:** Ningún módulo accede directamente a `PlayerGui`. Todos reciben `hud` (GUIExploradorV2) vía `init()`.

---

## HUDController.client.lua

**Responsabilidad única:** Conectar eventos del servidor y delegar a módulos especializados.

**No hace:**
- No manipula UI directamente
- No busca objetos en PlayerGui
- No tiene lógica de negocio

**Flujo de inicio:**
1. Espera `GUIExploradorV2` en PlayerGui
2. Marca atributo `HUDControllerActive` para evitar doble ejecución
3. Inicializa 6 módulos con `init(hud)` o `init(hud, fadeModule)`
4. Conecta 4 eventos del servidor: `LevelReady`, `UpdateMissions`, `UpdateScore`, `LevelCompleted`

**Eventos conectados:**

| Evento | Módulo destino | Acción |
|--------|---------------|--------|
| `LevelReady` | Todos | Reset estado, forzar cámara Custom |
| `UpdateMissions` | HUDMisionPanel | Reconstruir panel con nuevas misiones |
| `UpdateScore` | HUDScore | Actualizar label de puntaje |
| `LevelCompleted` | HUDVictory | Mostrar pantalla de victoria |

---

## HUDEvents.lua

**Responsabilidad única:** Centralizar todas las referencias a RemoteEvents para que ningún otro módulo haga `WaitForChild` por su cuenta.

**Eventos expuestos:**

| Nombre | Tipo | Dirección | Uso |
|--------|------|-----------|-----|
| `levelReady` | RemoteEvent | Servidor → Cliente | Nivel cargado, resetear HUD |
| `updateMissions` | RemoteEvent | Servidor → Cliente | Estado de misiones cambió |
| `updateScore` | RemoteEvent | Servidor → Cliente | Puntaje base actualizado |
| `levelCompleted` | RemoteEvent | Servidor → Cliente | Todas las misiones completas |
| `returnToMenu` | RemoteEvent | Cliente → Servidor | Volver al menú principal |
| `restartLevel` | RemoteEvent | Cliente → Servidor | Reiniciar nivel actual |

**Patrón de uso:**
```lua
local HUDEvents = require(HUDModules.HUDEvents)
-- Escuchar servidor:
HUDEvents.levelReady.OnClientEvent:Connect(callback)
-- Enviar a servidor:
HUDEvents.returnToMenu:FireServer()

HUDFade.lua
Responsabilidad única: Manejar el overlay negro de transición (fade in/out).
Estado interno:
fadeOverlay: Frame negro creado dinámicamente con ZIndex=99
parentHud: Referencia a GUIExploradorV2


API pública:
| Función                           | Parámetros                               | Descripción                                           |
| --------------------------------- | ---------------------------------------- | ----------------------------------------------------- |
| `init(hud)`                       | `hud: ScreenGui`                         | Crea overlay, limpia anterior si existe               |
| `fadeToBlack(duration, callback)` | `duration: number?, callback: function?` | Anima transparency 1→0, opcional callback al terminar |
| `reset()`                         | -                                        | Oculta overlay, resetea transparency a 1              |


HUDFade.fadeToBlack(0.4, function()
    -- Enviar evento al servidor
    HUDFade.reset()
end)


BarraSuperior
└── PanelPuntuacion
    └── ContenedorPuntos
        └── Val (o "Valor" como fallback)


scoreLabel: Referencia cacheada al TextLabel

| Función      | Parámetros       | Descripción                                  |
| ------------ | ---------------- | -------------------------------------------- |
| `init(hud)`  | `hud: ScreenGui` | Busca y cachea el label de puntaje           |
| `set(valor)` | `valor: number`  | Actualiza texto del label (con fallback a 0) |



úsqueda del label:
Primero busca en ruta exacta: BarraSuperior/PanelPuntuacion/ContenedorPuntos/Val
Fallback recursivo: FindFirstChild("ContenedorPuntos", true) → Val o Valor
HUDModal.lua
Responsabilidad única: Manejar el modal de confirmación para salir al menú principal.
Elementos UI gestionados:
ModalSalirFondo — Frame contenedor del modal
BtnCancelarSalir — Botón cancelar (oculta modal)
BtnConfirmarSalir — Botón confirmar (ejecuta vuelta al menú)
BtnSalir / BtnSalirMain — Botón que abre el modal
Estado interno:
isReturning: boolean — Previene doble ejecución
Dependencias:
Requiere fadeModule (HUDFade) para transición al salir

| Función                 | Parámetros                          | Descripción                               |
| ----------------------- | ----------------------------------- | ----------------------------------------- |
| `init(hud, fadeModule)` | `hud: ScreenGui, fadeModule: table` | Conecta botones del modal                 |
| `_showModal()`          | -                                   | Muestra ModalSalirFondo                   |
| `_hideModal()`          | -                                   | Oculta ModalSalirFondo                    |
| `_doReturnToMenu()`     | -                                   | Fade → negro, envía ReturnToMenu, resetea |


Flujo de salida:
Jugador presiona BtnSalir → _showModal()
Jugador presiona BtnConfirmarSalir → _doReturnToMenu()
Fade a negro (0.4s)
ReturnToMenu:FireServer()
Ocultar VictoriaFondo si está visible
fadeModule.reset()
isReturning = false
HUDMisionPanel.lua
Responsabilidad única: Construir y manejar el panel desplegable de misiones del nivel actual.
Elementos UI gestionados:
MisionFrame — Frame contenedor del panel
Cuerpo — ScrollingFrame con lista de misiones
BtnMisiones — Botón toggle del panel
BtnCerrarMisiones — Botón cerrar (X)
Estado interno:
isPanelOpen: boolean — Visibilidad actual del panel
Constantes visuales:
COLOR_COMPLETA — Verde (80, 200, 120) para misiones completadas
COLOR_PENDIENTE — Gris claro (200, 200, 200) para pendientes
COLOR_ZONA_BG — Azul oscuro (30, 30, 50) para headers inactivos
COLOR_ZONA_ACTIVA — Azul medio (30, 50, 90) para zona actual
ROW_HEIGHT — 22 píxeles de alto por fila


| Función                | Parámetros           | Descripción                             |
| ---------------------- | -------------------- | --------------------------------------- |
| `init(hud)`            | `hud: ScreenGui`     | Conecta botones toggle y cerrar         |
| `toggle()`             | -                    | Alterna visibilidad del panel           |
| `reset()`              | -                    | Cierra panel, limpia contenido          |
| `clear()`              | -                    | Destruye todos los elementos del Cuerpo |
| `rebuild(missionData)` | `missionData: table` | Reconstruye panel completo              |


