# Sistema 2.0 — Plan de Arquitectura MEJORADO v3 (ESPAÑOL)

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
| roof | techo |
| collision | colision |

---

## Estado Actual (Problemas Identificados)

### 1. Desconexion Incompleta del Gameplay
| Problema | Ubicacion | Impacto |
|----------|-----------|---------|
| `VisualEffectsService` no tiene `desactivar()` | Cliente | Highlights persistentes al volver al menu |
| `ZoneTriggerManager` conserva `_player` referencia | Servidor | Referencias huerfanas |
| Múltiples listeners en `ClientBoot` no se desconectan | Cliente | Memory leaks potenciales |
| `HUDMapa` puede quedar abierto al salir | Cliente | Estado inconsistente de UI |

### 2. Redundancia en Manejo de Camara
```
HUDMapa/CameraManager.lua  →  guardarCamaraJugador(), ocultarTecho()
Effects/CameraEffects.lua  →  guardarEstado(), ocultarTecho()
ClientBoot.lua             →  establecerCamaraJuego(), establecerCamaraMenu()
MenuController.lua         →  configurarCamaraMenu()
```
**Problema**: 4 lugares diferentes manejan la camara. Debe haber UNO solo.

### 3. Modulos con Multiples Responsabilidades
| Modulo | Responsabilidades Actuales | Deberia ser |
|--------|---------------------------|-------------|
| `ConectarCables` | Logica de cables + Efectos visuales (pulse) + Score tracking | Solo logica de cables |
| `MissionService` | Validacion de misiones + Guardar en DataStore + Calcular estrellas | Solo validacion |
| `HUDController` | Orquestador + Recibe eventos + Delega | Mezcla confusa |

---

## Nueva Arquitectura: "El Gran Interruptor"

### Concepto Central
```
┌─────────────────────────────────────────────────────────────────┐
│                        SERVIDOR                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │               OrquestadorGameplay                       │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐    │   │
│  │  │ Cables  │  │  Zonas  │  │ Misiones│  │  Puntaje│    │   │
│  │  │ Modulo  │  │ Modulo  │  │ Modulo  │  │ Modulo  │    │   │
│  │  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘    │   │
│  │       └─────────────┴─────────────┴─────────────┘       │   │
│  │                      ↓ UN SOLO activar()                 │   │
│  └─────────────────────────────────────────────────────────┘   │
│                           ↑↓                                    │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │           OrquestadorMenu (siempre activo)              │   │
│  │         Solo maneja: UI + Camara Menu + Progreso        │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              ↑↓
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENTE                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │           OrquestadorGameplayCliente                    │   │
│  │     Activa/desactiva TODO el gameplay visual a la vez   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                           ↑↓                                    │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │           OrquestadorMenuCliente (siempre activo)       │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Estructura de Carpetas NUEVA (Nombres en Espanol)

```
ServerScriptService/
├── Nucleo/
│   ├── InicioServidor.server.lua       ← Solo carga servicios base
│   ├── RegistroEventos.server.lua      ← Sin cambios
│   └── CicloVidaServidor.lua           ← NUEVO: Controla estados globales
│
├── Menu/                               ← NUEVO: Todo del menu (siempre activo)
│   ├── OrquestadorMenu.lua             ← Gestiona estado del menu
│   └── ServicioProgresoJugador.lua     ← Mueve progreso aqui
│
└── Gameplay/                           ← Solo existe durante gameplay
    ├── OrquestadorGameplay.lua         ← NUEVO: UNICO punto de entrada/salida
    ├── Modulos/                        ← NUEVO: Subcarpeta
    │   ├── ModuloConexionCables.lua    ← Renombrado desde ConectarCables
    │   ├── ModuloDeteccionZonas.lua    ← Renombrado desde ZoneTriggerManager
    │   └── ModuloValidacionMisiones.lua← Renombrado desde MissionService
    └── Servicios/
        ├── RegistroPuntaje.lua         ← Solo tracking, sin UI
        └── CicloVidaNivel.lua          ← NUEVO: Maneja init/cleanup de nivel

StarterPlayerScripts/
├── Nucleo/
│   ├── InicioCliente.client.lua        ← Refactorizado: solo orquesta
│   └── CicloVidaCliente.lua            ← NUEVO: Gestiona estados cliente
│
├── Menu/                               ← NUEVO: Todo del menu (siempre activo)
│   ├── OrquestadorMenuCliente.lua      ← Gestiona menu + camara menu
│   ├── ControladorMenu.client.lua      ← Mueve aqui
│   └── SelectorNivelesUI.lua           ← UI de seleccion de niveles
│
└── Gameplay/                           ← Solo durante gameplay
    ├── OrquestadorGameplayCliente.lua  ← NUEVO: UNICO punto de entrada/salida
    ├── HUD/
    │   ├── ControladorHUD.client.lua   ← Mueve aqui, simplificado
    │   ├── Modulos/
    │   │   ├── MostradorPuntaje.lua    ← Solo muestra puntaje
    │   │   ├── PanelMisiones.lua       ← Solo misiones
    │   │   ├── PantallaVictoria.lua    ← Solo pantalla victoria
    │   │   └── SistemaMapa/
    │   │       ├── OrquestadorMapa.lua    ← NUEVO: Controla TODO el mapa
    │   │       ├── ControladorCamara.lua  ← Solo camara del mapa
    │   │       └── ControladorTecho.lua   ← Solo techo/colisiones
    │   └── CicloVidaHUD.lua            ← NUEVO: Init/cleanup de HUD
    │
    └── Visual/
        ├── ControladorEfectosVisuales.client.lua  ← Refactorizado con cleanup
        └── ResaltadorNodos.lua                    ← Solo highlights de nodos

ReplicatedStorage/
├── Configuracion/
│   └── ConfiguracionNiveles.lua
├── Compartido/
│   ├── Constantes.lua
│   ├── ConfiguracionEfectosVisuales.lua
│   └── Enumeraciones.lua
└── Efectos/                            ← DEPRECADO: Mover y eliminar
    ├── EfectosCamara.lua
    ├── EfectosNodos.lua
    ├── EfectosZonas.lua
    └── PresetsTween.lua
```

---

## Contratos de Modulos (Interfaz Estandar)

### Todo modulo de Gameplay DEBE implementar:

```lua
local MiModulo = {}

-- Estado
MiModulo._activo = false
MiModulo._funcionesLimpieza = {}  -- Funciones de limpieza registradas

-- ═══════════════════════════════════════════════════════════════════════════════
-- ACTIVAR: Iniciar el modulo. SOLO aqui se conectan eventos/listeners.
-- ═══════════════════════════════════════════════════════════════════════════════
function MiModulo.activar(contexto)
    if MiModulo._activo then MiModulo.desactivar() end
    
    MiModulo._activo = true
    MiModulo._funcionesLimpieza = {}
    
    -- Registrar limpieza automatica
    MiModulo._registrarLimpieza(function()
        -- Desconectar listeners, destruir instancias, etc.
    end)
    
    print("[MiModulo] activar")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- DESACTIVAR: Detener completamente. LLAMAR SIEMPRE al salir del gameplay.
-- ═══════════════════════════════════════════════════════════════════════════════
function MiModulo.desactivar()
    if not MiModulo._activo then return end
    
    MiModulo._activo = false
    
    -- Ejecutar todas las funciones de limpieza registradas
    for _, fn in ipairs(MiModulo._funcionesLimpieza) do
        pcall(fn)
    end
    MiModulo._funcionesLimpieza = {}
    
    print("[MiModulo] desactivar")
end

-- Helper para registrar limpieza
function MiModulo._registrarLimpieza(fn)
    table.insert(MiModulo._funcionesLimpieza, fn)
end

return MiModulo
```

---

## OrquestadorGameplay (Servidor)

```lua
-- OrquestadorGameplay.lua
-- UNICO responsable: Activar/desactivar TODO el sistema de gameplay como unidad.

local OrquestadorGameplay = {}

-- Modulos gestionados (orden importa para inicializacion)
local MODULOS = {}

function OrquestadorGameplay:inicializar()
    MODULOS = {
        puntaje     = require(script.Parent.Modulos.RegistroPuntaje),
        cables      = require(script.Parent.Modulos.ModuloConexionCables),
        zonas       = require(script.Parent.Modulos.ModuloDeteccionZonas),
        misiones    = require(script.Parent.Modulos.ModuloValidacionMisiones),
    }
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- INICIAR GAMEPLAY: Llamado UNA VEZ cuando el jugador entra a un nivel
-- ═══════════════════════════════════════════════════════════════════════════════
function OrquestadorGameplay:iniciarNivel(jugador, idNivel, configuracion)
    print("[OrquestadorGameplay] ▶️ INICIAR NIVEL", idNivel)
    
    local contexto = {
        jugador = jugador,
        idNivel = idNivel,
        configuracion = configuracion,
        nivelActual = workspace:FindFirstChild("NivelActual"),
    }
    
    -- ORDEN CRITICO de inicializacion
    MODULOS.puntaje:activar(contexto)      -- 1. Puntaje primero (otros lo usan)
    MODULOS.zonas:activar(contexto)        -- 2. Zonas (misiones dependen de esto)
    MODULOS.misiones:activar(contexto)     -- 3. Misiones (necesitan zonas)
    MODULOS.cables:activar(contexto)       -- 4. Cables (necesitan misiones para callbacks)
    
    print("[OrquestadorGameplay] ✅ Gameplay activo")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- DETENER GAMEPLAY: Llamado UNA VEZ cuando el jugador sale del nivel
-- ═══════════════════════════════════════════════════════════════════════════════
function OrquestadorGameplay:detenerNivel()
    print("[OrquestadorGameplay] ⏹️ DETENER NIVEL")
    
    -- ORDEN INVERSO de limpieza
    MODULOS.cables:desactivar()     -- 1. Cables primero (deja de detectar input)
    MODULOS.misiones:desactivar()   -- 2. Misiones
    MODULOS.zonas:desactivar()      -- 3. Zonas
    MODULOS.puntaje:desactivar()    -- 4. Puntaje al final
    
    print("[OrquestadorGameplay] ⬛ Gameplay detenido")
end

return OrquestadorGameplay
```

---

## OrquestadorGameplayCliente (Cliente)

```lua
-- OrquestadorGameplayCliente.client.lua
-- UNICO responsable: Activar/desactivar TODO el gameplay visual.

local OrquestadorGameplayCliente = {}

local SISTEMAS = {}

function OrquestadorGameplayCliente:inicializar()
    SISTEMAS = {
        hud        = require(script.Parent.HUD.CicloVidaHUD),
        efectosVisuales = require(script.Parent.Visual.ControladorEfectosVisuales),
        entrada    = require(script.Parent.Entrada.GestorEntrada),
    }
end

function OrquestadorGameplayCliente:iniciarGameplay(idNivel)
    print("[OrquestadorGameplayCliente] ▶️ INICIAR")
    
    -- 1. Activar HUD
    SISTEMAS.hud:activar(idNivel)
    
    -- 2. Activar efectos visuales
    SISTEMAS.efectosVisuales:activar()
    
    -- 3. Activar input de gameplay
    SISTEMAS.entrada:activar()
    
    -- 4. Camara de gameplay (desde OrquestadorCliente)
    self:_establecerCamaraGameplay()
end

function OrquestadorGameplayCliente:detenerGameplay()
    print("[OrquestadorGameplayCliente] ⏹️ DETENER")
    
    -- ORDEN INVERSO
    SISTEMAS.entrada:desactivar()      -- 1. Entrada primero (deja de escuchar)
    SISTEMAS.efectosVisuales:desactivar() -- 2. Limpiar efectos
    SISTEMAS.hud:desactivar()          -- 3. HUD
    -- 4. Camara se maneja desde OrquestadorCliente
end

return OrquestadorGameplayCliente
```

---

## SistemaCamara (UNIFICADO)

```lua
-- Compartido/SistemaCamara.lua
local SistemaCamara = {}

-- Estados validos
SistemaCamara.Estado = {
    MENU     = "menu",      -- Camara estatica cinematica
    GAMEPLAY = "gameplay",  -- Camara sigue al jugador  
    MAPA     = "mapa",      -- Camara cenital del mapa
}

local estadoActual = nil
local _limpieza = nil

function SistemaCamara:establecerMenu()
    if estadoActual == self.Estado.MENU then return end
    self:_limpiarAnterior()
    
    local camara = workspace.CurrentCamera
    local camaraMenu = workspace:FindFirstChild("CamaraMenu", true)
    
    camara.CameraType = Enum.CameraType.Scriptable
    if camaraMenu then
        camara.CFrame = camaraMenu:IsA("BasePart") and camaraMenu.CFrame or camaraMenu.PrimaryPart.CFrame
    end
    
    estadoActual = self.Estado.MENU
    print("[SistemaCamara] → MENU")
end

function SistemaCamara:establecerGameplay()
    if estadoActual == self.Estado.GAMEPLAY then return end
    self:_limpiarAnterior()
    
    local camara = workspace.CurrentCamera
    local jugador = game.Players.LocalPlayer
    
    camara.CameraType = Enum.CameraType.Custom
    
    local function establecerSujeto(personaje)
        local humanoide = personaje:FindFirstChildOfClass("Humanoid")
        if humanoide then
            camara.CameraSubject = humanoide
        end
    end
    
    if jugador.Character then
        establecerSujeto(jugador.Character)
    end
    
    _limpieza = jugador.CharacterAdded:Connect(establecerSujeto)
    estadoActual = self.Estado.GAMEPLAY
    print("[SistemaCamara] → GAMEPLAY")
end

function SistemaCamara:establecerMapa(nivelModelo)
    if estadoActual == self.Estado.MAPA then return end
    self:_limpiarAnterior()
    -- ... implementacion similar
    estadoActual = self.Estado.MAPA
    print("[SistemaCamara] → MAPA")
end

function SistemaCamara:_limpiarAnterior()
    if _limpieza then
        _limpieza:Disconnect()
        _limpieza = nil
    end
end

return SistemaCamara
```

---

## GestorColisiones (Modulo Unico para Techos)

```lua
-- Gameplay/Modulos/GestorColisiones.lua
local GestorColisiones = {}

local _estadosGuardados = {}
local _activo = false

function GestorColisiones:capturar(nivelModelo)
    self:liberar()
    
    local techos = self:_buscarTechos(nivelModelo)
    
    for _, parte in ipairs(techos) do
        _estadosGuardados[parte] = {
            Transparency = parte.Transparency,
            CastShadow = parte.CastShadow,
            CanCollide = parte.CanCollide,
            CanQuery = parte.CanQuery,
        }
    end
    
    print("[GestorColisiones] Capturados", #techos, "techos")
end

function GestorColisiones:ocultarTecho()
    for parte, original in pairs(_estadosGuardados) do
        if parte.Parent then
            parte.Transparency = 0.95
            parte.CastShadow = false
            parte.CanQuery = false
        end
    end
end

function GestorColisiones:restaurar()
    for parte, original in pairs(_estadosGuardados) do
        if parte.Parent then
            parte.Transparency = original.Transparency
            parte.CastShadow = original.CastShadow
            parte.CanCollide = original.CanCollide
            parte.CanQuery = original.CanQuery
        end
    end
end

function GestorColisiones:liberar()
    _estadosGuardados = {}
end

return GestorColisiones
```

---

## Plan de Migracion Paso a Paso

### ✅ Fase 1: Preparacion - COMPLETADA
1. ✅ Crear `OrquestadorGameplay` - Controla activacion/desactivacion de modulos servidor
2. ✅ Crear `OrquestadorGameplayCliente` - Controla activacion/desactivacion de sistemas cliente
3. ✅ Crear `SistemaCamara` - Unificacion de control de camara
4. ✅ Crear `GestorColisiones` - Unificacion de gestion de techos
5. ✅ Modificar `Boot.server.lua` para usar OrquestadorGameplay
6. ✅ Modificar `ClientBoot.lua` para usar OrquestadorGameplayCliente

### ✅ Fase 2: Migracion de Efectos Visuales - COMPLETADA
1. ✅ Crear `ControladorEfectosVisuales` con `activar()` y `desactivar()`
2. ✅ Integrar en `OrquestadorGameplayCliente`
3. ✅ Actualizar `HUDMapa/init.lua` para usar nuevos sistemas

### 🔄 Fase 3: Migracion de Camara y Colisiones - EN PROGRESO

### Fase 2: Migracion Servidor
4. Mover `ConectarCables` → `ModuloConexionCables` con contrato activar/desactivar
5. Mover `ZoneTriggerManager` → `ModuloDeteccionZonas` con contrato
6. Mover `MissionService` → `ModuloValidacionMisiones` con contrato
7. Conectar `OrquestadorGameplay` en `InicioServidor.server.lua`
8. Probar: ¿Se activan/desactivan todos juntos?

### Fase 3: Migracion Cliente
9. Crear `SistemaCamara` unificado
10. Crear `GestorColisiones` unificado
11. Mover `VisualEffectsService` → `ControladorEfectosVisuales` con cleanup
12. Crear `OrquestadorGameplayCliente`
13. Probar transiciones Menu↔Gameplay

### Fase 4: Limpieza
14. Eliminar archivos deprecados:
    - `EfectosCamara.lua` → migrar a `SistemaCamara`
    - `EfectosNodos.lua` → migrar a `ControladorEfectosVisuales`
    - `EfectosZonas.lua` → integrar en `ModuloDeteccionZonas`

---

## Checklist de "Gameplay Desconectado"

Al volver al menu, verificar que:

- [ ] No hay listeners de entrada activos (clics en nodos no hacen nada)
- [ ] No hay highlights visibles en el workspace
- [ ] No hay billboards flotando
- [ ] No hay cables siendo renderizados
- [ ] La camara esta en modo Menu (Scriptable, posicion fija)
- [ ] El HUD de gameplay esta oculto completamente
- [ ] No hay musica/sonidos de gameplay
- [ ] No hay procesos en segundo plano (tweens, loops)
- [ ] El techo esta restaurado a su estado original
- [ ] Las colisiones estan restauradas
- [ ] No hay referencias al "NivelActual" en ningun sistema activo

---

## Resumen de Cambios Clave

| Aspecto | Antes | Despues |
|---------|-------|---------|
| **Entrada gameplay** | Boot llama 5+ modulos manualmente | Un `OrquestadorGameplay:iniciarNivel()` |
| **Salida gameplay** | Boot llama 5+ desactivar manualmente | Un `OrquestadorGameplay:detenerNivel()` |
| **Camara** | 4 scripts diferentes | Un `SistemaCamara` con estados |
| **Techos** | En EfectosCamara + CameraManager | Un `GestorColisiones` dedicado |
| **Efectos visuales** | Servicio sin cleanup | Controlador con `desactivar()` |
| **Estructura** | Plana, todo mezclado | Separada: Menu/Gameplay/Nucleo |
| **Contratos** | Cada uno diferente | Todos: `activar()` / `desactivar()` |
| **Idioma** | Ingles y espanol mezclado | TODO en espanol |
