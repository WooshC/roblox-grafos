# GrafosV3 — Cambios Implementados (Fases A, B y C)
> Fecha: 2026-03-08 | Estado: Fases A + B + C completadas

---

## FASE A — Fundación

### A1. `GrafoHelpers.lua` (NUEVO)
**Ruta:** `ReplicatedStorage/Compartido/GrafoHelpers.lua`

Módulo central compartido por servidor Y cliente. Consolida funciones duplicadas que existían en 3–4 archivos distintos.

**Funciones exportadas:**
| Función | Descripción |
|---|---|
| `clavePar(nomA, nomB)` | Clave canónica para un par de nodos. Separador `"|"` (nunca `"_"`, que colisiona con nombres de nodo). Orden normalizado A < B. |
| `parsearClave(clave)` | Inverso de `clavePar` → devuelve `(nomA, nomB)` |
| `nodosDeZona(adyacencias, zonaID, config)` | Filtra nodos por zona. Estrategia 1: mapa explícito `NodosZona[zonaID]`. Estrategia 2: sufijo `_z<N>`. Si el formato es desconocido: `warn` + `return {}` (fail-safe). |
| `detectarDirigido(adyacencias, nodos)` | `true` si existe A→B sin B→A (grafo dirigido) |

---

### A1b. `MatrizAdyacencia.server.lua` (MODIFICADO)
**Ruta:** `ServerScriptService/SistemasGameplay/MatrizAdyacencia.server.lua`

- Añadido `require(GrafoHelpers)` al inicio
- **Eliminadas** ~56 líneas: funciones locales `nodosDeZona()` y `detectarDirigido()` (duplicadas)
- Todas las llamadas internas reemplazadas por `GrafoHelpers.nodosDeZona(...)` y `GrafoHelpers.detectarDirigido(...)`

---

### A1c. `ServicioGrafosAnalisis.lua` (MODIFICADO)
**Ruta:** `ServerScriptService/SistemasGameplay/ServicioGrafosAnalisis.lua`

- Añadido `require(GrafoHelpers)` al inicio
- **Eliminadas** ~52 líneas: funciones locales `nodosDeZona()` y `detectarDirigido()` (duplicadas)
- Llamadas reemplazadas por `GrafoHelpers.nodosDeZona(...)` y `GrafoHelpers.detectarDirigido(...)`

---

### A1d. `ValidadorConexiones.lua` (MODIFICADO)
**Ruta:** `ServerScriptService/SistemasGameplay/ValidadorConexiones.lua`

**Bug corregido:** `generarClave()` usaba separador `"_"` → claves como `"NodoA_z1_NodoB_z1"` (ambiguo con nombres de nodo que ya contienen `"_"`). Las claves no coincidían con las de `ConectarCables` ni `ServicioMisiones`, causando que `contarConexiones()` siempre devolviera 0.

- Añadido `require(GrafoHelpers)`
- `generarClave()` delega a `GrafoHelpers.clavePar()` → separador `"|"` canónico
- `parsearClave()` delega a `GrafoHelpers.parsearClave()`
- Comentario actualizado: `-- { ["NodoA|NodoB"] = {...} }`

---

### A1e. `ConectarCables.lua` (MODIFICADO)
**Ruta:** `ServerScriptService/SistemasGameplay/ConectarCables.lua`

- Añadido `require(GrafoHelpers)`
- Función local `clavePar()` ahora delega: `return GrafoHelpers.clavePar(nomA, nomB)`
- **Bug corregido:** En `intentarConectar()` y `conectarNodos()`, el `FireClient` para error de dirección usaba hardcoded `"ConexionInvalida"` en lugar de la variable `tipoError`. Fix:
  ```lua
  local tipoError = esAdyacente(nomB, nomA) and "DireccionInvalida" or "ConexionInvalida"
  notificarEvento:FireClient(jugador, tipoError, selector2.Parent)
  ```

---

### A1f. `ServicioMisiones.lua` (MODIFICADO)
**Ruta:** `ServerScriptService/SistemasGameplay/ServicioMisiones.lua`

- Añadido `require(GrafoHelpers)`
- Función local `clavePar()` delega a `GrafoHelpers.clavePar(a, b)`

---

### A2. `CargadorNiveles.lua` — Inicializar ValidadorConexiones (MODIFICADO)
**Ruta:** `ServerScriptService/Servicios/CargadorNiveles.lua`

**Bug corregido (B1):** `ValidadorConexiones.configurar()` nunca se llamaba → `contarConexiones()` siempre devolvía 0 → puntuación y misiones rotas.

Cambios en `cargar()`:
```lua
-- Paso 4 (NUEVO) — antes de ConectarCables.activar()
ValidadorConexiones.configurar({
    Adyacencias = config.Adyacencias,
    nivelID     = nivelID,
})
```

Cambios en `descargar()`:
```lua
-- NUEVO — después de ConectarCables.desactivar()
ValidadorConexiones.limpiar()
```

---

## FASE B — Bugs Críticos

### B3. `ServicioCamara.lua` — Fix deadlock (MODIFICADO)
**Ruta:** `ReplicatedStorage/Compartido/ServicioCamara.lua`

**Bug corregido (B2):** `restaurar()` tenía `repeat task.wait(0.016) until not enTransicion` sin timeout. Si la tarea de animación crasheaba antes de poner `enTransicion = false`, el hilo se bloqueaba indefinidamente.

Cambios:
- Nueva variable de estado: `local _taskActual = nil` — handle del `task.spawn` de la transición activa
- `moverA()`: cancela tarea anterior con `task.cancel(_taskActual)` antes de iniciar nueva; guarda handle
- `restaurar()`:
  1. Cancela `_taskActual` si existe (elimina el bloqueo)
  2. Si `enTransicion` aún es true, espera con **timeout de 2s** (no infinito)
  3. Si el timeout se agota, fuerza `enTransicion = false` con warn
  4. Inicia la animación de restauración y guarda su handle en `_taskActual`

---

### B7. `ConectarCables.lua` — Fix `DireccionInvalida` (MODIFICADO)
(Descrito en A1e — mismo archivo)

---

### B8. `GestorZonas.lua` — Verificación cleanup (SIN CAMBIOS)
**Ruta:** `ServerScriptService/SistemasGameplay/GestorZonas.lua`

Verificado: el archivo ya tenía `table.insert(_conexiones, connEntrada)` y `table.insert(_conexiones, connSalida)`, y `desactivar()` ya llamaba `conn:Disconnect()` en un loop. No se requirieron cambios.

---

## FASE C — Regla de Oro

### C4. `Boot.server.lua` — Máquina de estados + eliminar `_G` (REESCRITO)
**Ruta:** `ServerScriptService/Nucleo/Boot.server.lua`

**Problema:** Handlers `MapaClickNodo` y `ConectarDesdeMapa` siempre conectados. `_G.SistemaGameplay` como anti-patrón global compartido.

**Cambios:**

Máquina de estados por jugador:
```lua
local ESTADO = { MENU = "MENU", CARGANDO = "CARGANDO", GAMEPLAY = "GAMEPLAY" }
local _estado = {}  -- [userId] = ESTADO.*
local _ctx    = {}  -- [userId] = { cables = Module, misiones = Module }
```

- `setEstado(jugador, nuevoEstado)` — transición de estado
- `estaEnGameplay(jugador)` — guard para handlers
- `construirContexto(jugador)` — cachea referencias a ConectarCables y ServicioMisiones después de cargar el nivel (evita `pcall(require,...)` en cada evento)

Handlers de gameplay con guard:
```lua
-- MapaClickNodo y ConectarDesdeMapa:
if not estaEnGameplay(jugador) then return end
local ctx = _ctx[jugador.UserId]
if not ctx then return end
```

Flujo de transiciones:
- `IniciarNivel` → `CARGANDO` → `pcall(CargadorNiveles.cargar)` → `GAMEPLAY` (éxito) o `MENU` (error)
- `VolverAlMenu` → `MENU` primero (Regla de Oro), luego `descargar()`
- `ReiniciarNivel` → `CARGANDO` → `descargar` → `cargar` → `GAMEPLAY` o `MENU`
- `PlayerRemoving` → limpia `_estado[userId]` y `_ctx[userId]`

**Eliminado:** Todo el bloque `_G.SistemaGameplay` (~50 líneas)

---

### C4b. `CargadorNiveles.lua` — Eliminar `_G.SistemaGameplay` (MODIFICADO)
**Ruta:** `ServerScriptService/Servicios/CargadorNiveles.lua`

- **Eliminada** función `obtenerSistemaGameplay()` (accedía a `_G.SistemaGameplay`)
- **Eliminada** llamada `sg.terminar(_jugadorActual)` en `descargar()`
- **Eliminada** llamada `sg.iniciar(nivelID, jugador)` en `cargar()`

---

### C5. `ClientBoot.client.lua` — Máquina de estados cliente (REESCRITO)
**Ruta:** `StarterPlayerScripts/Nucleo/ClientBoot.client.lua`

**Problema:** Sin estado explícito, posibles doble-activaciones de menú/HUD.

Máquina de estados:
```lua
local MODO = { INICIO = "INICIO", MENU = "MENU", GAMEPLAY = "GAMEPLAY" }
local _modoActual = MODO.INICIO
```

Guards en los 3 handlers:
- `ServidorListo` → si ya en `MENU`, ignora (previene doble-activación)
- `NivelListo` → si `data.error`, vuelve a `MENU`; si ya en `GAMEPLAY`, ignora
- `NivelDescargado` → si ya en `MENU`, ignora

Carga de sistemas compartidos con `warn` específico por fallo:
- `ControladorAudio` — en `task.spawn` para no bloquear
- `GuiaService` — en `task.spawn` con `WaitForChild` y warn si no se encuentra

---

### C6. `GestorEfectos.lua` (NUEVO — ModuleScript)
**Ruta:** `StarterPlayerScripts/SistemasGameplay/GestorEfectos.lua`

**Nota importante:** Debe ser `.lua` (ModuleScript), NO `.client.lua` (LocalScript). Los LocalScripts no son `require()`-ables.

Bus centralizado de efectos visuales. Reemplaza las 3 conexiones directas a `NotificarSeleccionNodo` por una sola.

API:
```lua
GestorEfectos.registrar(tipoEfecto, handler)  -- múltiples handlers por tipo permitidos
GestorEfectos.emitir(tipoEfecto, params)       -- despacho local (sin red)
```

Funcionamiento:
- Escucha `NotificarSeleccionNodo` **una sola vez**
- Al recibir `(tipoEvento, arg1, arg2)`, llama `emitir(tipoEvento, { arg1=arg1, arg2=arg2 })`
- Cada `emitir` ejecuta todos los handlers registrados para ese tipo con `pcall` (error en un handler no rompe los demás)

Tipos despachados:
| Tipo | arg1 | arg2 |
|---|---|---|
| `NodoSeleccionado` | Model del nodo | `{Model,...}` adyacentes |
| `ConexionCompletada` | string nodoA | string nodoB |
| `CableDesconectado` | string nodoA | string nodoB |
| `SeleccionCancelada` | — | — |
| `ConexionInvalida` | Model del nodo | — |
| `DireccionInvalida` | Model del nodo | — |

---

### C6b. `ControladorEfectos.client.lua` (MODIFICADO)
**Ruta:** `StarterPlayerScripts/SistemasGameplay/ControladorEfectos.client.lua`

- **Eliminado** bloque de carga de `ParticulasConexion` (ya no es su responsabilidad)
- **Eliminada** conexión directa a `NotificarSeleccionNodo`
- **Añadido** `require(script.Parent:WaitForChild("GestorEfectos"))`
- Registra 6 handlers:
  - `NodoSeleccionado` — highlight cyan + highlights dorados adyacentes + billboards
  - `ConexionCompletada` — `clearAll()` + VFX `EfectoConexion` en cada selector
  - `CableDesconectado` — `clearAll()`
  - `SeleccionCancelada` — `clearAll()`
  - `ConexionInvalida` — `clearAll()` + flash rojo
  - `DireccionInvalida` — `clearAll()` + flash rojo

---

### C6c. `RetroalimentacionConexion.client.lua` (MODIFICADO)
**Ruta:** `StarterPlayerScripts/SistemasGameplay/RetroalimentacionConexion.client.lua`

- **Eliminada** dependencia directa de `ReplicatedStorage/EventosGrafosV3` y conexión a `NotificarSeleccionNodo`
- **Añadido** `require(script.Parent:WaitForChild("GestorEfectos"))`
- Registra 2 handlers:
  - `ConexionInvalida` → abre diálogo `"Feedback_ConexionInvalida"`
  - `DireccionInvalida` → abre diálogo `"Feedback_DireccionInvalida"`
- Guards mantenidos: `controlador` disponible, `!controlador.estaActivo()`, `!mapaEstaAbierto()`

---

### C6d. `ParticulasConexion.client.lua` (MODIFICADO)
**Ruta:** `StarterPlayerScripts/SistemasGameplay/ParticulasConexion.client.lua`

- **Eliminada** conexión directa a `NotificarSeleccionNodo`
- **Eliminado** `_G.ParticulasConexion = ParticulasConexion` (anti-patrón global)
- **Eliminada** API pública (`iniciar`, `detener`, `esConexionDirigida`, `configurar`) y el `return` final — nadie la requiere; es un LocalScript auto-ejecutable
- **Añadido** `require(script.Parent:WaitForChild("GestorEfectos"))`
- Registra 2 handlers:
  - `ConexionCompletada` → `iniciarFlujoParticulas(nodoA .. "_" .. nodoB, ...)`
  - `CableDesconectado` → `detenerFlujoParticulas` con clave directa E inversa

---

## Resumen de archivos por categoría

### Archivos NUEVOS
| Archivo | Tipo | Descripción |
|---|---|---|
| `ReplicatedStorage/Compartido/GrafoHelpers.lua` | ModuleScript | Funciones canónicas: `clavePar`, `parsearClave`, `nodosDeZona`, `detectarDirigido` |
| `StarterPlayerScripts/SistemasGameplay/GestorEfectos.lua` | ModuleScript | Bus centralizado de efectos visuales |

### Archivos MODIFICADOS (servidor)
| Archivo | Cambio principal |
|---|---|
| `ServerScriptService/Nucleo/Boot.server.lua` | Máquina de estados por jugador; eliminado `_G.SistemaGameplay` |
| `ServerScriptService/Servicios/CargadorNiveles.lua` | `ValidadorConexiones.configurar()` + `limpiar()`; eliminado `_G` |
| `ServerScriptService/SistemasGameplay/ValidadorConexiones.lua` | Separador `"|"` vía `GrafoHelpers.clavePar` |
| `ServerScriptService/SistemasGameplay/ConectarCables.lua` | `GrafoHelpers.clavePar`; fix `DireccionInvalida` hardcodeada |
| `ServerScriptService/SistemasGameplay/ServicioMisiones.lua` | `GrafoHelpers.clavePar` |
| `ServerScriptService/SistemasGameplay/MatrizAdyacencia.server.lua` | Eliminadas funciones duplicadas; usa `GrafoHelpers` |
| `ServerScriptService/SistemasGameplay/ServicioGrafosAnalisis.lua` | Eliminadas funciones duplicadas; usa `GrafoHelpers` |

### Archivos MODIFICADOS (cliente)
| Archivo | Cambio principal |
|---|---|
| `ReplicatedStorage/Compartido/ServicioCamara.lua` | Fix deadlock: `_taskActual` + `task.cancel` + timeout 2s |
| `StarterPlayerScripts/Nucleo/ClientBoot.client.lua` | Máquina de estados `INICIO→MENU→GAMEPLAY`; guards doble-activación |
| `StarterPlayerScripts/SistemasGameplay/ControladorEfectos.client.lua` | Registrado en `GestorEfectos`; eliminada conexión directa |
| `StarterPlayerScripts/SistemasGameplay/RetroalimentacionConexion.client.lua` | Registrado en `GestorEfectos`; eliminada conexión directa |
| `StarterPlayerScripts/SistemasGameplay/ParticulasConexion.client.lua` | Registrado en `GestorEfectos`; eliminados `_G` y API pública |

### Archivos ELIMINADOS
| Archivo | Motivo |
|---|---|
| `StarterPlayerScripts/SistemasGameplay/GestorEfectos.client.lua` | Error de tipo: `.client.lua` es LocalScript, no requirable. Reemplazado por `GestorEfectos.lua` |

---

## Bugs corregidos

| ID | Descripción | Archivo | Fix |
|---|---|---|---|
| B1 | `ValidadorConexiones.configurar()` nunca llamado → conteo siempre 0 | CargadorNiveles.lua | Llamada añadida antes de `ConectarCables.activar()` |
| B2 | Deadlock en `ServicioCamara.restaurar()` sin timeout | ServicioCamara.lua | `task.cancel()` + timeout 2s |
| B3 | `FireClient("ConexionInvalida")` hardcodeado en lugar de `tipoError` | ConectarCables.lua | Variable `tipoError` usada correctamente |
| B4 | Separador `"_"` en `ValidadorConexiones` vs `"|"` en el resto | ValidadorConexiones.lua | `GrafoHelpers.clavePar()` unifica separador |
| B5 | `nodosDeZona()` duplicada con comportamiento diferente en 2 archivos | MatrizAdyacencia + ServicioGrafosAnalisis | Consolidada en `GrafoHelpers` |
| B6 | `_G.SistemaGameplay` anti-patrón global compartido | Boot + CargadorNiveles | Eliminado; reemplazado por estado explícito por jugador |
| B7 | `_G.ParticulasConexion` anti-patrón global | ParticulasConexion | Eliminado; ya no necesario |
| B8 | 3 conexiones duplicadas a `NotificarSeleccionNodo` | ControladorEfectos + ParticulasConexion + RetroalimentacionConexion | Una sola conexión en `GestorEfectos` |

---

## Pendiente — Fase D

| # | Tarea | Impacto |
|---|---|---|
| 10 | Nil-checks tras `WaitForChild` en cadena | Robustez — crash silencioso si falta un hijo |
| 11 | `pcall` sin contexto de error en Boot | Debug — mensajes de error sin información útil |
| 12 | `require` redundante de módulos en handlers | Limpieza — ya resuelto parcialmente con `_ctx` |
| 13 | Validar `LevelsConfig` al cargar + llenar niveles 1–4 | Datos — nivel vacío falla en silencio |
