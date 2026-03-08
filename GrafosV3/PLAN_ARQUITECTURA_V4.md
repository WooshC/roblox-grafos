# GrafosV3 — Plan de Arquitectura V4
> Fecha: 2026-03-08 | Basado en ANALISIS_CODIGO.md + inspección completa del código

---

## Regla de Oro (no negociable)

> **Un punto de entrada. Mientras el menú esté activo, TODO lo relacionado al gameplay está completamente desconectado.**

Esto se implementa con una **máquina de estados explícita** en Boot y ClientBoot.
Los estados posibles son: `MENU → CARGANDO → GAMEPLAY → MENU`.
Los handlers de eventos de gameplay **solo existen** en estado `GAMEPLAY`.

---

## Problemas Actuales — Resumen Ejecutivo

### Violaciones a la Regla de Oro
| Problema | Archivo | Impacto |
|---|---|---|
| `MapaClickNodo` y `ConectarDesdeMapa` handlers siempre conectados | Boot.server.lua:334–425 | Gameplay activo en menú |
| Scripts de gameplay siempre corriendo (StarterPlayerScripts) | ControladorEfectos, ParticulasConexion, RetroalimentacionConexion | Sin desconexión al volver al menú |
| `_G.SistemaGameplay` global mutable | Boot.server.lua, CargadorNiveles.lua | Estado compartido no controlado |
| `ControladorDialogo` se activa sin verificar si hay gameplay activo | ClientBoot → GuiaService | Diálogos posibles en menú |

### Bugs Críticos (del ANALISIS_CODIGO.md)
| # | Bug | Consecuencia |
|---|---|---|
| B1 | `ValidadorConexiones.configurar()` nunca se llama | Puntuación y misiones siempre en 0 |
| B2 | Deadlock en `ServicioCamara` línea 221 | Hilo bloqueado indefinidamente |
| B3 | `NotificarSeleccionNodo:FireClient` ANTES de `registrarConexion` | Cliente lee estado vacío |
| B4 | `GestorZonas` no limpia Touched/TouchEnded al desactivar | Crash si parte se destruye |
| B5 | `nodosDeZona()` incluye TODO ante zona desconocida | Datos incorrectos silenciosos |

### Código Duplicado
| Función | Archivos (instancias) | Problema extra |
|---|---|---|
| `nodosDeZona()` | MatrizAdyacencia + ServicioGrafosAnalisis | Fix en uno no se aplica al otro |
| `detectarDirigido()` | MatrizAdyacencia + ServicioGrafosAnalisis | Idem |
| `clavePar()` | ConectarCables + ServicioMisiones + ValidadorConexiones | Separadores distintos `|` vs `_` |
| Fetch de RemoteEvents | ControladorHUD + ClientBoot + EventosHUD | 3 rutas independientes |
| `pcall(require, moduloCables)` | Boot.server.lua (2 handlers) | Repetición sin extracción |

---

## Arquitectura Nueva

### Principio: Módulos Centrales + Efectos Compartidos

```
┌─────────────────────────────────────────────────────────┐
│                    ESTADO GLOBAL                         │
│         Boot (servidor) — ClientBoot (cliente)          │
│         Estado: MENU | CARGANDO | GAMEPLAY              │
└─────────────────────┬───────────────────────────────────┘
                      │
        ┌─────────────┴─────────────┐
        │                           │
   SISTEMA MENÚ               SISTEMA GAMEPLAY
   (aislado)                  (se activa/desactiva)
        │                           │
   ControladorMenu            CargadorNiveles
   AudioMenu                  ├── ConectarCables
   CámaraMenuScript           ├── GestorZonas
                              ├── ServicioMisiones
                              ├── ServicioPuntaje
                              └── ValidadorConexiones
                                        │
                              ┌─────────┴──────────┐
                         MÓDULOS CENTRALES    EFECTOS
                         GrafoHelpers.lua     GestorEfectos (cliente)
                         ServicioCamara       ├── EfectosNodo
                         (sin deadlock)       ├── EfectosCable
                                              ├── EfectosZonas
                                              └── BillboardNombres
```

---

## Mapa de Archivos — Cambios

### Nuevos archivos (crear)
```
ReplicatedStorage/Compartido/
└── GrafoHelpers.lua              ← nodosDeZona, detectarDirigido, clavePar (canónico)

StarterPlayerScripts/Gameplay/
└── GestorEfectos.client.lua      ← bus centralizado de efectos cliente
```

### Archivos modificados (cambios concretos)
```
ServerScriptService/Nucleo/
└── Boot.server.lua               ← máquina de estados + handlers condicionados al estado

ServerScriptService/Servicios/
└── CargadorNiveles.lua           ← llamar ValidadorConexiones.configurar() + sin _G

ReplicatedStorage/Compartido/
└── ServicioCamara.lua            ← fix deadlock (timeout + cancelar tarea previa)

ServerScriptService/SistemasGameplay/
├── ConectarCables.lua            ← fix orden registro/notificación + usar GrafoHelpers.clavePar
├── GestorZonas.lua               ← fix cleanup de conexiones Touched
├── MatrizAdyacencia.server.lua   ← usar GrafoHelpers (eliminar duplicados)
├── ServicioGrafosAnalisis.lua    ← usar GrafoHelpers (eliminar duplicados)
├── ServicioMisiones.lua          ← usar GrafoHelpers.clavePar
└── ValidadorConexiones.lua       ← usar GrafoHelpers.clavePar

StarterPlayerScripts/Nucleo/
└── ClientBoot.client.lua         ← máquina de estados cliente + activar/desactivar gameplay

StarterPlayerScripts/HUD/
└── ControladorHUD.client.lua     ← solicitar efectos a GestorEfectos (no directo)

StarterPlayerScripts/SistemasGameplay/
├── ControladorEfectos.client.lua ← registrarse en GestorEfectos
├── ParticulasConexion.client.lua ← registrarse en GestorEfectos
└── RetroalimentacionConexion.client.lua ← registrarse en GestorEfectos
```

### Archivos sin cambio
```
00_EventRegistry.server.lua     (ya correcto)
LevelsConfig.lua                (ya correcto)
AlgoritmosGrafo.lua             (ya correcto)
ModuloAnalisis/ (sub-módulos)   (ya correctos)
ServicioPuntaje.lua             (ya correcto)
DialogoData/                    (ya correcto)
```

---

## Tareas — Orden de Prioridad

Las tareas están ordenadas de mayor a menor impacto. Completar las primeras 4 elimina todos los bugs críticos.

---

### TAREA 1 — Crear `GrafoHelpers.lua` ⭐ FUNDACIÓN
**Archivo:** `ReplicatedStorage/Compartido/GrafoHelpers.lua`
**Prioridad:** CRÍTICA (otros módulos dependen de esto)

```lua
-- ReplicatedStorage/Compartido/GrafoHelpers.lua
local GrafoHelpers = {}

-- Separador canónico para clavePar.
-- NUNCA usar "_" como separador (colisiona con nombres de nodos que usan "_").
local SEP = "|"

-- clavePar: genera clave única para un par de nodos (orden normalizado A < B).
-- Usado por: ConectarCables, ValidadorConexiones, ServicioMisiones
function GrafoHelpers.clavePar(nomA, nomB)
    if nomA < nomB then
        return nomA .. SEP .. nomB
    else
        return nomB .. SEP .. nomA
    end
end

-- nodosDeZona: filtra lista de nombres de nodo por zona.
-- zonaID: string del tipo "Zona_Estacion_1"
-- Si el formato de zona es desconocido, EXCLUYE el nodo con warn (fail-safe).
function GrafoHelpers.nodosDeZona(todosNodos, zonaID)
    -- Extrae sufijo numérico: "Zona_Estacion_1" → "z1", "Zona_Estacion_2" → "z2"
    local n = zonaID:match("_(%d+)$")
    if not n then
        warn("[GrafoHelpers] nodosDeZona: formato de zona desconocido:", zonaID,
             "— se excluyen todos los nodos (fail-safe)")
        return {}
    end
    local sufijo = "_z" .. n
    local resultado = {}
    for _, nom in ipairs(todosNodos) do
        if nom:sub(-#sufijo) == sufijo then
            table.insert(resultado, nom)
        end
    end
    return resultado
end

-- detectarDirigido: devuelve true si el grafo de adyacencias es dirigido.
-- Un grafo es dirigido si existe A→B sin B→A.
function GrafoHelpers.detectarDirigido(adyacencias)
    for nodoA, vecinos in pairs(adyacencias) do
        for _, nodoB in ipairs(vecinos) do
            local vecinosB = adyacencias[nodoB]
            if not vecinosB then return true end
            local tieneReversa = false
            for _, v in ipairs(vecinosB) do
                if v == nodoA then tieneReversa = true; break end
            end
            if not tieneReversa then return true end
        end
    end
    return false
end

-- parsearClave: inverso de clavePar, devuelve (nomA, nomB).
function GrafoHelpers.parsearClave(clave)
    return clave:match("^(.+)" .. SEP .. "(.+)$")
end

return GrafoHelpers
```

**Cambios en otros archivos tras crear GrafoHelpers:**
- `MatrizAdyacencia.server.lua`: eliminar funciones `nodosDeZona` (líneas 62-93) y `detectarDirigido` (líneas 98-118), añadir `local GH = require(RS.Compartido.GrafoHelpers)` y sustituir llamadas.
- `ServicioGrafosAnalisis.lua`: idem eliminar líneas 26-55 y 57-77.
- `ConectarCables.lua` línea 43: cambiar a `GH.clavePar(nomA, nomB)`.
- `ServicioMisiones.lua` línea 28: idem.
- `ValidadorConexiones.lua` línea 21: idem (actualmente usa `_`, esto es el bug de separador).

---

### TAREA 2 — Inicializar `ValidadorConexiones` en `CargadorNiveles` ⭐ BUG CRÍTICO B1
**Archivo:** `ServerScriptService/Servicios/CargadorNiveles.lua`

**Problema:** `ValidadorConexiones.configurar(config)` nunca se llama → `contarConexiones()` siempre devuelve 0 → misiones y puntuación rotas.

**Fix — insertar justo antes de activar ConectarCables:**
```lua
-- ANTES de ConectarCables.activar(...)
ValidadorConexiones.configurar({
    adyacencias = config.Adyacencias,
    nivelID     = nivelID,
})
```

**Ubicación en CargadorNiveles.cargar():** después de `ServicioMisiones.activar(...)` y antes de `ConectarCables.activar(...)`.

---

### TAREA 3 — Corregir deadlock en `ServicioCamara` ⭐ BUG CRÍTICO B2
**Archivo:** `ReplicatedStorage/Compartido/ServicioCamara.lua` línea 221

**Problema actual:**
```lua
-- línea 221 — busy-wait sin timeout, se bloquea si enTransicion nunca se pone false
repeat task.wait(0.016) until not enTransicion
```

**Fix — reemplazar `restaurar()` completo:**
```lua
function ServicioCamara.restaurar(duracion)
    -- Cancelar transición anterior si existe
    if _taskTransicion then
        task.cancel(_taskTransicion)
        _taskTransicion = nil
    end

    -- Si hay transición en curso, esperar con timeout de 2s
    local t0 = tick()
    while enTransicion and (tick() - t0) < 2 do
        task.wait(0.016)
    end
    if enTransicion then
        warn("[ServicioCamara] restaurar: timeout esperando transición — forzando restauración")
        enTransicion = false
    end

    if not estadoGuardado then return end
    ServicioCamara.moverA(estadoGuardado.cframe, duracion or 0.6, true, function()
        ServicioCamara.liberar()
    end)
end
```

**Cambio adicional:** En `moverA()`, guardar el handle del `task.spawn` en `_taskTransicion` para que `restaurar()` pueda cancelarlo.

```lua
-- Al inicio de moverA():
if _taskTransicion then
    task.cancel(_taskTransicion)
end
enTransicion = true
_taskTransicion = task.spawn(function()
    -- ... lógica de tween existente ...
    enTransicion = false
    _taskTransicion = nil
end)
```

**Variable nueva al inicio del módulo:**
```lua
local _taskTransicion = nil  -- handle del task.spawn de la transición activa
```

---

### TAREA 4 — Máquina de estados en Boot (Regla de Oro) ⭐ ARQUITECTURA
**Archivo:** `ServerScriptService/Nucleo/Boot.server.lua`

**Problema:** Los handlers `MapaClickNodo` y `ConectarDesdeMapa` están conectados permanentemente, incluso cuando el jugador está en el menú. `_G.SistemaGameplay` es un anti-patrón global.

**Solución — introducir estado explícito:**

```lua
-- Al inicio de Boot.server.lua
local EstadoSistema = {
    MENU      = "MENU",
    CARGANDO  = "CARGANDO",
    GAMEPLAY  = "GAMEPLAY",
}

local _estadoActual = {}  -- [userId] = EstadoSistema.*
local _conexionesGameplay = {}  -- [userId] = { lista de RBXScriptConnections }

local function estaEnGameplay(jugador)
    return _estadoActual[jugador.UserId] == EstadoSistema.GAMEPLAY
end

local function setEstado(jugador, nuevoEstado)
    _estadoActual[jugador.UserId] = nuevoEstado
end
```

**Handlers condicionados por estado:**
```lua
-- MapaClickNodo y ConectarDesdeMapa: solo actuar si el jugador está en GAMEPLAY
Remotos.MapaClickNodo.OnServerEvent:Connect(function(jugador, ...)
    if not estaEnGameplay(jugador) then return end
    -- ... lógica existente ...
end)

Remotos.ConectarDesdeMapa.OnServerEvent:Connect(function(jugador, ...)
    if not estaEnGameplay(jugador) then return end
    -- ... lógica existente ...
end)
```

**Transiciones de estado:**
```lua
-- En handler IniciarNivel:
setEstado(jugador, EstadoSistema.CARGANDO)
local ok, err = pcall(CargadorNiveles.cargar, nivelID, jugador)
if ok then
    setEstado(jugador, EstadoSistema.GAMEPLAY)
else
    setEstado(jugador, EstadoSistema.MENU)
    warn("[Boot] Error cargando nivel:", err)
end

-- En handler VolverAlMenu:
setEstado(jugador, EstadoSistema.MENU)
CargadorNiveles.descargar(jugador)
```

**Eliminar `_G.SistemaGameplay`:** Pasar la referencia explícitamente como parámetro a `CargadorNiveles.cargar(nivelID, jugador, sistemaGameplay)` o eliminarla si los métodos `iniciar`/`terminar` no se usan (ver sección código muerto).

---

### TAREA 5 — Máquina de estados en ClientBoot (Regla de Oro) ⭐ ARQUITECTURA
**Archivo:** `StarterPlayerScripts/Nucleo/ClientBoot.client.lua`

**Problema:** Scripts de gameplay (`ControladorEfectos`, `ParticulasConexion`, `RetroalimentacionConexion`) están en `StarterPlayerScripts` y corren siempre, sin mecanismo de desactivación.

**Solución — ClientBoot como orquestador de sistemas:**

```lua
-- ClientBoot.client.lua — estructura nueva

local sistemaMenu     = require(script.Parent.Menu.ControladorMenu)
local sistemaHUD      = require(script.Parent.HUD.ControladorHUD)
local gestorEfectos   = require(script.Parent.Gameplay.GestorEfectos)

-- Estado inicial: solo menú activo
local function activarMenu()
    sistemaHUD.desactivar()
    gestorEfectos.desactivar()
    sistemaMenu.activar()
end

local function activarGameplay(data)
    sistemaMenu.desactivar()
    gestorEfectos.activar()
    sistemaHUD.activar(data)
end

-- Escuchar eventos del servidor
Remotos.ServidorListo.OnClientEvent:Connect(function(datosProgreso)
    activarMenu()
end)

Remotos.NivelListo.OnClientEvent:Connect(function(nivelID, data)
    activarGameplay(data)
end)

Remotos.NivelDescargado.OnClientEvent:Connect(function()
    activarMenu()
end)
```

**Cada sistema implementa `activar()` / `desactivar()`** — interfaz uniforme.

---

### TAREA 6 — Crear `GestorEfectos.client.lua` (bus de efectos) ⭐ EFECTOS COMPARTIDOS
**Archivo:** `StarterPlayerScripts/Gameplay/GestorEfectos.client.lua`

**Problema:** `ControladorEfectos`, `ParticulasConexion`, `RetroalimentacionConexion` y el HUD se acoplan directamente entre sí. Cualquier módulo que necesite un efecto debe conocer la implementación concreta.

**Solución — Bus centralizado de efectos:**

```lua
-- GestorEfectos.client.lua
local GestorEfectos = {}

-- Registro de handlers por tipo de efecto
local _handlers = {}
local _activo = false

-- API para módulos de efecto: registrar qué tipos manejan
function GestorEfectos.registrar(tipoEfecto, handler)
    _handlers[tipoEfecto] = handler
end

-- API para sistemas que quieren emitir efectos
-- Uso: GestorEfectos.emitir("NodoSeleccionado", { nodo = nodoModel })
function GestorEfectos.emitir(tipoEfecto, params)
    if not _activo then return end
    local handler = _handlers[tipoEfecto]
    if handler then
        local ok, err = pcall(handler, params)
        if not ok then
            warn("[GestorEfectos] Error en efecto", tipoEfecto, ":", err)
        end
    else
        warn("[GestorEfectos] Sin handler para:", tipoEfecto)
    end
end

function GestorEfectos.activar()
    _activo = true
end

function GestorEfectos.desactivar()
    _activo = false
    -- Limpiar efectos visuales activos
    GestorEfectos.emitir("LimpiarTodo", {})
end

return GestorEfectos
```

**Tipos de efectos canónicos:**
| Tipo | Quién lo emite | Quién lo maneja |
|---|---|---|
| `NodoSeleccionado` | ConectarCables (via evento) | EfectosHighlight, BillboardNombres |
| `NodoDeseleccionado` | ConectarCables | EfectosHighlight |
| `CableCreado` | PulsoEvent | ParticulasConexion, EfectosCable |
| `CableEliminado` | ConectarCables | EfectosCable |
| `FalloConexion` | ConectarCables | RetroalimentacionConexion |
| `ZonaEntrada` | GestorZonas | EfectosZonas |
| `NivelCompletado` | ServicioMisiones | VictoriaHUD |
| `LimpiarTodo` | GestorEfectos.desactivar() | Todos los módulos de efecto |

**Módulos de efecto se registran en su `init()`:**
```lua
-- ControladorEfectos.client.lua
local GestorEfectos = require(...)

local function init()
    GestorEfectos.registrar("NodoSeleccionado", function(p)
        EfectosHighlight.activar(p.nodo)
        BillboardNombres.mostrar(p.nodo, p.nombre)
    end)
    GestorEfectos.registrar("LimpiarTodo", function()
        EfectosHighlight.limpiar()
        BillboardNombres.limpiar()
    end)
end
```

---

### TAREA 7 — Fix orden registro/notificación en `ConectarCables` ⭐ BUG CRÍTICO B3
**Archivo:** `ServerScriptService/SistemasGameplay/ConectarCables.lua` líneas 237–269

**Problema:** `NotificarSeleccionNodo:FireClient` (línea 261) ocurre ANTES de `ValidadorConexiones.registrarConexion()` (línea 269).

**Fix — reordenar la función `crearCable`:**
```lua
local function crearCable(sel1, sel2, jugador)
    -- 1. Crear objetos visuales (Hitbox, Beam, ClickDetector)
    local hitbox = crearHitbox(sel1, sel2)
    local beam   = crearBeam(sel1, sel2)
    -- 2. REGISTRAR EN VALIDADOR PRIMERO (fuente de verdad)
    ValidadorConexiones.registrarConexion(nomA, nomB, hitbox)
    -- 3. Notificar al cliente (ahora el estado ya está registrado)
    Remotos.NotificarSeleccionNodo:FireClient(jugador, "ConexionCompletada", nomA, nomB)
    -- 4. Callbacks (misiones, puntuación)
    if _callbacks.onCableCreado then
        _callbacks.onCableCreado(nomA, nomB)
    end
    -- 5. Efectos (pulso visual)
    Remotos.PulsoEvent:FireClient(jugador, "IniciarPulso", hitbox)
end
```

---

### TAREA 8 — Fix cleanup en `GestorZonas` ⭐ BUG CRÍTICO B4
**Archivo:** `ServerScriptService/SistemasGameplay/GestorZonas.lua` líneas 88–101

**Problema:** Conexiones `Touched`/`TouchEnded` no se guardan → no se pueden desconectar.

**Fix:**
```lua
-- Al inicio del módulo
local _conexionesActivas = {}  -- lista de RBXScriptConnections

-- En activar(), al conectar cada trigger:
local c1 = triggerPart.Touched:Connect(onTouched)
local c2 = triggerPart.TouchEnded:Connect(onTouchEnded)
table.insert(_conexionesActivas, c1)
table.insert(_conexionesActivas, c2)

-- En desactivar():
function GestorZonas.desactivar()
    for _, conn in ipairs(_conexionesActivas) do
        conn:Disconnect()
    end
    _conexionesActivas = {}
    _tocandoPorZona   = {}
    _enZona           = {}
end
```

---

### TAREA 9 — Fix `nodosDeZona` fallback ⭐ BUG MEDIO B5
**Impacto:** ya resuelto en TAREA 1 (`GrafoHelpers.nodosDeZona` usa `return {}` + `warn()`).
Solo asegurarse de que MatrizAdyacencia y ServicioGrafosAnalisis llamen a `GH.nodosDeZona(...)`.

---

### TAREA 10 — Fix nil-checks tras `WaitForChild` ⭐ ROBUSTEZ
**Archivo:** `EventosHUD.lua` líneas 7–8

```lua
-- ANTES:
local eventosFolder = RS:WaitForChild("EventosGrafosV3", 15)
local remotosFolder = eventosFolder:WaitForChild("Remotos", 5)

-- DESPUÉS:
local eventosFolder = RS:WaitForChild("EventosGrafosV3", 15)
assert(eventosFolder, "[EventosHUD] EventosGrafosV3 no encontrado en ReplicatedStorage")
local remotosFolder = eventosFolder:WaitForChild("Remotos", 5)
assert(remotosFolder, "[EventosHUD] Remotos no encontrado en EventosGrafosV3")
```

Aplicar el mismo patrón en `Boot.server.lua` para cada `WaitForChild` en cadena.

---

### TAREA 11 — Fix pcall sin contexto en Boot ⭐ ROBUSTEZ
**Archivo:** `Boot.server.lua` líneas 69–77

```lua
-- ANTES:
local exito, resultado = pcall(require, ServicioProgreso)
if exito then
    ServicioProgreso = resultado
else
    warn("[GrafosV3] Error:", resultado)
end
-- ... más abajo: ServicioProgreso.cargar(jugador)  → crash si nil

-- DESPUÉS:
local exito, resultado = pcall(require, pathServicioProgreso)
if not exito then
    error("[Boot] No se pudo cargar ServicioProgreso: " .. tostring(resultado))
end
local ServicioProgreso = resultado
```

Patrón: si un módulo crítico falla al cargar, **el servidor debe fallar ruidosamente**, no silenciosamente.

---

### TAREA 12 — Extraer helper `requireCables()` en Boot ⭐ LIMPIEZA
**Archivo:** `Boot.server.lua` líneas 334–425

Los handlers `MapaClickNodo` y `ConectarDesdeMapa` repiten:
```lua
local ok, cables = pcall(require, moduloCables)
if not ok then ... end
```

**Fix:** Extraer al inicio de Boot (después de que CARGANDO → GAMEPLAY):
```lua
-- En CargadorNiveles.cargar(), guardar referencia en contexto del jugador:
_contextoGameplay[jugador.UserId] = {
    cables  = ConectarCables,
    misiones = ServicioMisiones,
    -- etc.
}

-- En Boot, los handlers solo acceden al contexto:
Remotos.MapaClickNodo.OnServerEvent:Connect(function(jugador, ...)
    if not estaEnGameplay(jugador) then return end
    local ctx = _contextoGameplay[jugador.UserId]
    ctx.cables.alClickearDesdeMapa(jugador, ...)
end)
```

---

### TAREA 13 — Llenar LevelsConfig niveles 1–4 ⭐ DATOS
**Archivo:** `ReplicatedStorage/Config/LevelsConfig.lua`

Niveles 1–4 tienen `Adyacencias = {}` y `Zonas = {}` → el juego falla en silencio.

**Fix:** Agregar validación al cargar:
```lua
-- En CargadorNiveles.cargar(), antes de clonar el modelo:
local config = LevelsConfig[nivelID]
assert(config, "[CargadorNiveles] Nivel " .. nivelID .. " no existe en LevelsConfig")
assert(next(config.Adyacencias), "[CargadorNiveles] Nivel " .. nivelID .. " sin Adyacencias")
```

Y completar los datos de los niveles faltantes con la estructura real del modelo en Studio.

---

## Resumen de Implementación

### Fase A — Fundación (hacer primero, sin esto nada funciona correctamente)
| # | Tarea | Archivos | Estado |
|---|---|---|---|
| 1 | Crear GrafoHelpers.lua | GrafoHelpers.lua (nuevo) | ⬜ |
| 1b | Usar GrafoHelpers en MatrizAdyacencia + ServicioGrafosAnalisis | 2 archivos | ⬜ |
| 1c | Usar GrafoHelpers.clavePar en ConectarCables + ServicioMisiones + ValidadorConexiones | 3 archivos | ⬜ |
| 2 | Inicializar ValidadorConexiones en CargadorNiveles | CargadorNiveles.lua | ⬜ |

### Fase B — Bugs Críticos (funcionalidad rota)
| # | Tarea | Archivos | Estado |
|---|---|---|---|
| 3 | Fix deadlock ServicioCamara | ServicioCamara.lua | ⬜ |
| 7 | Fix orden registro/notificación | ConectarCables.lua | ⬜ |
| 8 | Fix cleanup GestorZonas | GestorZonas.lua | ⬜ |

### Fase C — Regla de Oro (separación menú/gameplay)
| # | Tarea | Archivos | Estado |
|---|---|---|---|
| 4 | Máquina de estados Boot.server.lua | Boot.server.lua | ⬜ |
| 5 | Máquina de estados ClientBoot | ClientBoot.client.lua | ⬜ |
| 6 | Crear GestorEfectos.client.lua | GestorEfectos.client.lua (nuevo) | ⬜ |
| 6b | Adaptar módulos de efecto para registrarse | ControladorEfectos, Particulas, Retroalimentacion | ⬜ |

### Fase D — Robustez y Limpieza
| # | Tarea | Archivos | Estado |
|---|---|---|---|
| 10 | Nil-checks WaitForChild | EventosHUD.lua, Boot.server.lua | ⬜ |
| 11 | Fix pcall sin contexto | Boot.server.lua | ⬜ |
| 12 | Extraer requireCables() helper | Boot.server.lua | ⬜ |
| 13 | Validar LevelsConfig al cargar + llenar niveles 1-4 | CargadorNiveles.lua, LevelsConfig.lua | ⬜ |

---

## Interfaz Uniforme de Sistemas

Todos los módulos de gameplay (servidor y cliente) deben implementar esta interfaz:

### Servidor (módulos requeridos por CargadorNiveles)
```lua
M.activar(config)   -- inicializar con datos del nivel
M.desactivar()      -- limpiar completamente, sin rastros
```

### Cliente (módulos requeridos por ClientBoot)
```lua
M.activar(data)     -- inicializar HUD/efectos del nivel
M.desactivar()      -- ocultar y limpiar
```

### Módulos de efecto (se registran en GestorEfectos)
```lua
-- En su init():
GestorEfectos.registrar("TipoEfecto", handlerFn)
GestorEfectos.registrar("LimpiarTodo", limpiarFn)
```

---

## Diagrama de Flujo — Regla de Oro

```
SERVIDOR                              CLIENTE
────────                              ───────
PlayerAdded
  setEstado(MENU)
  NivelListo × (no se dispara)
  ServidorListo:FireClient ─────────→ activarMenu()
                                        sistemaMenu.activar()
                                        sistemaHUD.desactivar()
                                        gestorEfectos.desactivar()

IniciarNivel:OnServerEvent
  setEstado(CARGANDO)
  CargadorNiveles.cargar()
    ValidadorConexiones.configurar()
    ServicioPuntaje.activar()
    ServicioMisiones.activar()
    GestorZonas.activar()
    ConectarCables.activar()
  setEstado(GAMEPLAY)
  NivelListo:FireClient ────────────→ activarGameplay(data)
                                        sistemaMenu.desactivar()
                                        gestorEfectos.activar()
                                        sistemaHUD.activar(data)

VolverAlMenu:OnServerEvent
  setEstado(MENU)
  CargadorNiveles.descargar()
    ConectarCables.desactivar()
    GestorZonas.desactivar()
    ServicioMisiones.desactivar()
    ServicioPuntaje.desactivar()
    ValidadorConexiones.limpiar()
  NivelDescargado:FireClient ───────→ activarMenu()
                                        sistemaHUD.desactivar()
                                        gestorEfectos.desactivar()
                                        sistemaMenu.activar()

MapaClickNodo:OnServerEvent
  if not estaEnGameplay(jugador): return  ← REGLA DE ORO
  ctx.cables.alClickearDesdeMapa(...)
```
