# GrafosV3 — Análisis de Código
> Revisión automática de 65 archivos Lua. Fecha: 2026-03-08

---

## Top 10 Issues por Impacto

| # | Severidad | Problema | Archivo | Líneas |
|---|-----------|----------|---------|--------|
| 1 | 🔴 CRÍTICO | `nodosDeZona()` duplicada | MatrizAdyacencia.server.lua + ServicioGrafosAnalisis.lua | 62-93 / 26-55 |
| 2 | 🔴 CRÍTICO | `detectarDirigido()` duplicada | MatrizAdyacencia.server.lua + ServicioGrafosAnalisis.lua | 98-118 / 57-77 |
| 3 | 🔴 CRÍTICO | ValidadorConexiones nunca se inicializa | Boot.server.lua / CargadorNiveles.lua | — |
| 4 | 🔴 CRÍTICO | Posible deadlock en transición de cámara | ServicioCamara.lua | 89-94, 221 |
| 5 | 🟠 ALTO | `clavePar()` triplicada con separadores distintos | ConectarCables, ServicioMisiones, ValidadorConexiones | 43 / 28 / 21 |
| 6 | 🟠 ALTO | pcall sin contexto: errores silenciosos | Boot.server.lua | 69-77, 83-92 |
| 7 | 🟠 ALTO | RemoteEvents sin validar nil antes de :Fire | ConectarCables.lua | 242, 261, 294… |
| 8 | 🟠 ALTO | Busy-wait sin timeout en restaurar cámara | ServicioCamara.lua | 221 |
| 9 | 🟡 MEDIO | Números mágicos no configurables (cable) | ConectarCables.lua | 35-37 |
| 10 | 🟡 MEDIO | GetGrafoCompleto devuelve nil silenciosamente | ModuloAnalisis.lua | 22-35 |

---

## 1. Código Duplicado

### 1.1 `nodosDeZona()` — CRÍTICO
- `ServerScriptService/SistemasGameplay/MatrizAdyacencia.server.lua` líneas 62–93
- `ServerScriptService/SistemasGameplay/ServicioGrafosAnalisis.lua` líneas 26–55
Lógica idéntica para filtrar nodos por zona. Un fix en uno no se aplica al otro.
**Fix:** extraer a `ReplicatedStorage/Compartido/GrafoHelpers.lua`

### 1.2 `detectarDirigido()` — CRÍTICO
- `MatrizAdyacencia.server.lua` líneas 98–118
- `ServicioGrafosAnalisis.lua` líneas 57–77
Detección de dígrafo duplicada. Bugs se propagan de forma independiente.
**Fix:** mover al mismo `GrafoHelpers.lua` compartido

### 1.3 `clavePar()` triplicada con separadores inconsistentes — ALTO
```lua
-- ConectarCables.lua (línea 43) y ServicioMisiones.lua (línea 28):
return nomA .. "|" .. nomB

-- ValidadorConexiones.lua (línea 21):
return nomA .. "_" .. nomB   -- ← separador diferente, genera claves distintas
```
El separador `"_"` en ValidadorConexiones rompe la búsqueda cruzada de cables.
**Fix:** una sola función en `GrafoHelpers.lua` con `"|"` como separador canónico

### 1.4 Patrón require+check repetido en Boot.server.lua — MEDIO
Los handlers `MapaClickNodo` (líneas 334–368) y `ConectarDesdeMapa` (líneas 374–425) repiten el mismo bloque de `pcall(require, moduloCables)`.
**Fix:** extraer `local function requireCables()` al inicio de Boot

### 1.5 Fetch de RemoteEvents duplicado — MEDIO
`ControladorHUD.client.lua`, `ClientBoot.client.lua` y `EventosHUD.lua` obtienen `EventosGrafosV3.Remotos` cada uno por su cuenta.
**Fix:** centralizar en `EventosHUD` y re-exportar el objeto `remotos`

---

## 2. Código Muerto / Sin Usar

### 2.1 `SistemaGameplay.iniciar()` / `.terminar()` nunca se llaman
- `Boot.server.lua` líneas 278–328
El objeto `SistemaGameplay` se declara pero sus métodos `iniciar` y `terminar` no son invocados desde ningún event handler.

### 2.2 `LevelsConfig` — niveles 1–4 con `Adyacencias = {}` y `Zonas = {}`
Si alguien carga esos niveles, el juego no reporta ningún error pero todo falla en silencio.
**Fix:** validación de esquema al cargar el nivel

---

## 3. Patrones Frágiles

### 3.1 Deadlock en cámara — CRÍTICO
**Archivo:** `ReplicatedStorage/Compartido/ServicioCamara.lua` línea 221
```lua
repeat task.wait(0.016) until not enTransicion
```
Si `restaurar()` se llama mientras hay una transición en curso, entra en un busy-wait infinito. Si la primera transición nunca termina (crash), el hilo queda bloqueado para siempre.
**Fix:** agregar timeout + cancelar el task.spawn previo al iniciar una nueva transición

### 3.2 `nodosDeZona()` incluye TODO si el formato de zona es desconocido
**Archivo:** `MatrizAdyacencia.server.lua` líneas 76–92
```lua
else
  incluir = true  -- formato desconocido: incluir TODO
```
Si `zonaID` no tiene el sufijo `_N`, la matriz incluye nodos de otras zonas sin advertir.
**Fix:** `warn()` explícito y `incluir = false` como fallback seguro

### 3.3 Orden incorrecto: registro antes de notificar al cliente
**Archivo:** `ConectarCables.lua` líneas 237–269
El cliente recibe `NodoSeleccionado` (línea 261) antes de que el servidor registre la conexión en `ValidadorConexiones` (línea 269). Si el cliente consulta el estado inmediatamente, lee datos vacíos.
**Fix:** `ValidadorConexiones.registrarConexion()` primero, luego `FireClient()`

### 3.4 `GestorZonas.lua` — conexiones Touched no se limpian al destruir la parte
**Archivo:** `GestorZonas.lua` líneas 88–101
Si `triggerPart` se destruye durante gameplay, las conexiones `Touched`/`TouchEnded` quedan vivas y pueden crashear.
**Fix:** guardar todas las conexiones en un array y desconectarlas en `desactivar()`

---

## 4. Manejo de Errores Faltante

### 4.1 ValidadorConexiones nunca se inicializa — CRÍTICO
**Archivos:** `Boot.server.lua`, `CargadorNiveles.lua`
`ValidadorConexiones` es required en `ConectarCables.lua` (línea 20) y `ServicioMisiones.lua` (línea 8), pero `.configurar(config)` nunca se llama en ningún punto del arranque.
**Consecuencia:** `ValidadorConexiones.contarConexiones()` siempre devuelve 0. La puntuación y misiones basadas en conteo de conexiones están rotas.
**Fix:** llamar `ValidadorConexiones.configurar(config)` en `CargadorNiveles.cargar()` tras clonar el modelo

### 4.2 pcall sin contexto en Boot
**Archivo:** `Boot.server.lua` líneas 69–77
```lua
if exito then
  ServicioProgreso = resultado
else
  warn("[GrafosV3] Error:", resultado)
  -- continúa sin ServicioProgreso
end
-- ... más abajo:
ServicioProgreso.cargar(jugador)  -- crash si ServicioProgreso es nil
```
**Fix:** `if not ServicioProgreso then return end` o early return con error claro

### 4.3 `WaitForChild` sin chequeo de nil en cadena
**Archivo:** `EventosHUD.lua` líneas 7–8
```lua
local eventosFolder = RS:WaitForChild("EventosGrafosV3", 15)
local remotosFolder = eventosFolder:WaitForChild("Remotos", 5)
-- Si eventosFolder es nil → crash en segunda línea
```
**Fix:**
```lua
local eventosFolder = RS:WaitForChild("EventosGrafosV3", 15)
assert(eventosFolder, "[EventosHUD] EventosGrafosV3 no encontrado")
```

### 4.4 RemoteEvents disparados sin verificar existencia
**Archivo:** `ConectarCables.lua` líneas 242, 261, 294, 300, 318, 336, 344
```lua
local notificarEvento = Remotos:FindFirstChild("NotificarSeleccionNodo")
if notificarEvento then
  notificarEvento:FireClient(...)
-- Si no existe: silencio total, el cliente nunca recibe el evento
```
**Fix:** `WaitForChild` con timeout en `activar()`, no `FindFirstChild` lazy en cada llamada

### 4.5 ModuloAnalisis: `GetGrafoCompleto` nil silencioso
**Archivo:** `ModuloAnalisis.lua` líneas 22–35
Si la RemoteFunction no existe, devuelve `nil` y el módulo sigue ejecutando. El análisis de grafos falla con errores crípticos.
**Fix:** `error()` explícito o un flag `disponible = false` que deshabilite el módulo

---

## 5. Arquitectura

### 5.1 `_G.SistemaGameplay` — anti-patrón global
**Archivos:** `Boot.server.lua` (escritura), `CargadorNiveles.lua` línea 121 (lectura)
Variable global mutable accesible desde cualquier módulo. Si otro script escribe en ella, el comportamiento es impredecible.
**Fix:** pasar la referencia explícitamente como parámetro a `CargadorNiveles`

### 5.2 Acoplamiento fuerte vía callbacks en CargadorNiveles
**Archivo:** `CargadorNiveles.lua` líneas 269–326
`ConectarCables`, `MissionService` y `ScoreTracker` se acoplan mediante closures. Si cambia la firma de un callback, rompe silenciosamente.
**Fix:** usar BindableEvents para comunicación inter-servicio

### 5.3 ValidadorConexiones: estado mutable compartido servidor/cliente
`ValidadorConexiones` tiene una tabla `conexiones` mutable. Si algún día se requiere desde el cliente, cada lado tiene estado diferente sin sincronización.
**Fix:** convertir en módulo solo-lectura en cliente; el servidor es la fuente de verdad

---

## 6. Números Mágicos

**Archivo:** `ConectarCables.lua` líneas 35–37
```lua
local COLOR_CABLE     = Color3.fromRGB(0, 200, 255)
local ANCHO_CABLE     = 0.13
local DISTANCIA_CLICK = 50
```
No son configurables por nivel.
**Fix:** mover a `LevelsConfig[nivelID].CablesConfig = { color, ancho, distanciaClick }`

---

## Acciones Recomendadas (orden de prioridad)

1. **Crear `GrafoHelpers.lua`** — mover `nodosDeZona`, `detectarDirigido`, `clavePar` (unifica 3 duplicados + fix separador)
2. **Inicializar `ValidadorConexiones`** en `CargadorNiveles.cargar()` — fix crítico para puntuación y misiones
3. **Corregir deadlock de cámara** en `ServicioCamara.lua` — agregar cancelación + timeout
4. **Agregar nil-checks** tras cada `WaitForChild` en `EventosHUD.lua` y `Boot.server.lua`
5. **Invertir orden** registro/notificación en `ConectarCables.lua` (líneas 261 vs 269)
6. **Llenar LevelsConfig** para niveles 1–4 (Adyacencias + Zonas)
