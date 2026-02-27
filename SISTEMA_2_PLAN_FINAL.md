# PLAN FINAL - Arquitectura Refactorizada

## ✅ COMPLETADO

### Regla de Oro Implementada
> **Mientras esté el menú activo, TODO lo de gameplay está desconectado.**

---

## Estructura Final

### Servidor
```
ServerScriptService/
├── Boot.server.lua                    ✅ Carga segura, GUI inmediata
├── Gameplay/
│   ├── OrquestadorGameplay.lua        ✅ Control maestro
│   └── Modulos/
│       ├── ModuloConexionCables.lua   ✅ Wrapper
│       ├── ModuloDeteccionZonas.lua   ✅ Wrapper  
│       └── ModuloValidacionMisiones.lua ✅ Wrapper
├── ConectarCables.lua                 (legacy)
├── ZoneTriggerManager.lua             (legacy)
├── MissionService.lua                 (legacy)
├── ScoreTracker.lua                   (legacy)
├── LevelLoader.lua
├── DataService.lua
└── 00_EventRegistry.lua
```

### Cliente
```
StarterPlayerScripts/
├── ClientBoot.lua                     ✅ Transiciones Menu↔Gameplay
├── Gameplay/
│   ├── OrquestadorGameplayCliente.lua ✅ Control maestro cliente
│   └── ControladorEfectosVisuales.lua ✅ Efectos con activar/desactivar
├── HUDModules/
│   ├── HUDFade.lua
│   ├── HUDScore.lua
│   ├── HUDMisionPanel.lua
│   ├── HUDVictory.lua
│   └── HUDMapa/
│       ├── init.lua                   ✅ Usa SistemaCamara
│       ├── ZoneManager.lua            ✅ Ahora con fallback integrado
│       ├── NodeManager.lua
│       └── InputManager.lua
└── VisualEffectsService.client.lua    ✅ Deprecado (auto-silencia)
```

### Compartido
```
ReplicatedStorage/
└── Compartido/
    ├── SistemaCamara.lua              ✅ Camara unificada
    └── GestorColisiones.lua           ✅ Techos unificados
```

---

## Cambios Clave

### 1. Copia Inmediata de GUI
- Boot copia la GUI **inmediatamente** al jugador conectarse
- No espera a nada

### 2. Sin Dependencias Rotas
- ZoneManager ahora tiene **funciones fallback** integradas
- No depende de `ReplicatedStorage.Effects`
- Todos los `require` están envueltos en `pcall`

### 3. Limpieza Garantizada
- `OrquestadorGameplay:detenerNivel()` limpia TODO
- `OrquestadorGameplayCliente:detenerGameplay()` limpia TODO
- Efectos visuales, highlights, billboards = eliminados

---

## Flujo de Datos

```
MENU (jugador en lobby)
  ↓
[JUGADOR CLICK "JUGAR"] → RequestPlayLevel → Server
  ↓
Server: LevelLoader:load() + OrquestadorGameplay:iniciarNivel()
  ↓
Server: LevelReady → Cliente
  ↓
Cliente: OrquestadorGameplayCliente:iniciarGameplay()
  ↓
GAMEPLAY ACTIVO (HUD, efectos, input)
  ↓
[VICTORIA] → LevelCompleted → Cliente muestra pantalla
  ↓
[JUGADOR CLICK "MENU"] → ReturnToMenu → Server
  ↓
Server: OrquestadorGameplay:detenerNivel() + LevelLoader:unload()
  ↓
Server: LevelUnloaded → Cliente
  ↓
Cliente: OrquestadorGameplayCliente:detenerGameplay()
  ↓
MENU (todo limpio, sin fugas)
```

---

## Testing Verificado

- ✅ Entrar a nivel
- ✅ Conectar cables
- ✅ Seleccionar nodos
- ✅ Abrir mapa (techo oculto, camara cenital, zonas highlight)
- ✅ Cerrar mapa (techo restaurado)
- ✅ Completar nivel (pantalla victoria)
- ✅ Volver al menú (limpio)
- ✅ Reiniciar nivel

---

## Resumen de Arquitectura

| Aspecto | Antes | Después |
|---------|-------|---------|
| **Entrada gameplay** | Boot llama 5+ modulos manualmente | Un `OrquestadorGameplay:iniciarNivel()` |
| **Salida gameplay** | Boot llama 5+ desactivar manualmente | Un `OrquestadorGameplay:detenerNivel()` |
| **Cámara** | 4 scripts diferentes | Un `SistemaCamara` con estados |
| **Techos** | En CameraEffects + CameraManager | Un `GestorColisiones` dedicado |
| **Efectos visuales** | Servicio sin cleanup | Controlador con `desactivar()` |
| **ZoneEffects** | Dependencia externa | Funciones fallback integradas |
| **Estructura** | Plana, todo mezclado | Separada: Menu/Gameplay/Nucleo |
| **Idioma** | Ingles y español mezclado | TODO en español |
