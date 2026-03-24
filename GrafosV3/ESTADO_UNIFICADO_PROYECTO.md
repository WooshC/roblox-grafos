# Reporte de Estado Unificado del Proyecto (GrafosV3)
> **Fecha:** 2026-03-14
> **Contenido:** Consolidación de `ANALISIS_CODIGO.md`, `CAMBIOS_IMPLEMENTADOS.md`, y los **nuevos hallazgos** de arquitectura producto de una revisión en profundidad de los módulos de HUD y Diálogo.

---

## 1. NUEVOS HALLAZGOS Y DUPLICIDADES RECIENTES ⚠️

A pesar de las resoluciones de las Fases A, B y C, una revisión detallada del proyecto actual revela duplicidades estructurales persistentes en el lado del cliente y dependencias ocultas críticas:

### 1.1 Suscripciones masivas directas al RemoteEvent `NotificarSeleccionNodo`
Aunque en la **Fase C** se implementó `GestorEfectos` para unificar 3 conexiones duplicadas al evento `NotificarSeleccionNodo` referidas a los efectos visuales y de highlight, una inspección de los módulos de HUD y Audio revela que **SÍ HAY duplicidad de escuchar este RemoteEvent** a través de todo el cliente.
* **Archivos implicados:** `ModuloMatriz.lua`, `ModuloMapa.lua`, `Minimap.lua`, `EstadoConexiones.lua`, `ControladorDialogo.client.lua`, `AudioGameplay.client.lua` y `RetroalimentacionConexion.client.lua`.
* **Problema:** En lugar de utilizar un `EventBus` o despachar eventos de cliente local a local, más de 7 módulos locales se están suscribiendo al mismo evento remoto directamente, definiendo sus propias funciones de validación. Esto dificulta la trazabilidad y puede causar race-conditions en el cliente.
* **Fix propuesto:** Extender el uso de `GestorEfectos` para ser un **`GestorEventosCliente`** omnipotente que reciba la redil de la señal del RemoteEvent y envíe Bindables o Signals locales (`OnNodoSeleccionado`, `OnConexionHecha`) al resto de módulos (HUD, Audio, Diálogos).

### 1.2 Fragmentación en la Obtención del Estado (Attributes)
Se observó en el código una alta repetición de cadenas de texto explícitas para rastrear el estado actual del jugador.
* **Archivos implicados:** Principalmente módulos del HUD (`ModuloMatriz`, `VictoriaHUD`, `ModuloAnalisis`, `ModuloMapa`) y componentes Gameplay (`GuiaService`, `GestorZonas`). 
* **Problema:** Se repite en ambos lados repetidamente `jugador:GetAttribute("ZonaActual") or ""` y `jugador:GetAttribute("CurrentLevelID") or 0`. Si estos atributos cambian de nombre o se altera la lógica de almacenamiento (ej. moverse a un DataStore cacheado en un Module), se tendrían que refactorizar cerca de 15 archivos.
* **Fix propuesto:** Crear un módulo ligero `EstadoJugador.lua` (o `GameStateManager`) que disponga de funciones como `EstadoJugador.getNivelActual()`, `EstadoJugador.getZonaActual()`, centralizando esto tanto local como en el servidor. 

### 1.3 `obtenerHudGui()` en el `ControladorDialogo.client.lua` y acoplamientos del HUD
* **Problema:** En `ControladorDialogo.client.lua`, para poder ocultar/mostrar elementos, la función interna `obtenerHudGui()` realiza un loop iterativo (for-loop) sobre todos los GUI del jugador, buscando dependencias con `match("HUD")` o `match("Explorador")`. Este es un patrón inestable de acoplamiento.
* **Fix propuesto:** Convertir a un módulo organizador del HUD (un HUDManager) al que `ControladorDialogo` pueda llamar `HUDManager.setDialogMode(true)`, quitándole la responsabilidad de recorrer/ocultar partes del GUI manualmente.

---

## 2. CAMBIOS IMPLEMENTADOS HASTA LA FECHA (Fases A, B y C) ✅

A continuación, un resumen de los logros principales alcanzados previamente, reflejados en el historial del desarrollo:

### FASE A — Fundación
- **Centralización Matemática (`GrafoHelpers.lua`):** Se extrajeron las funciones vitales `clavePar`, `parsearClave`, `nodosDeZona` y `detectarDirigido` que estaban triplicadas (`ServicioGrafosAnalisis`, `MatrizAdyacencia`, `ConectarCables`, etc.), unificando la lógica y evitando posibles derivaciones de errores. Se solventó críticamente un desajuste del separador de llaves `_` y `|`.
- Se introdujo `ValidadorConexiones.configurar()` en **CargadorNiveles.lua** (esto fue vital porque misiones y puntaje leían conexiones y devolvían `0` debido a faltas en la inicialización).

### FASE B — Bugs Críticos
- Se solventó un **Deadlock CRÍTICO** en `ServicioCamara.lua` incorporando *task.cancel()* y un timeout de restauración (2s) ante cuelgues durante `restaurar()`.
- Modificación del `FireClient("ConexionInvalida")` repetido que enviaba errores estáticos pre-procesando la variante `DireccionInvalida` para grafos estructurados.

### FASE C — Regla de Oro / Estado Transicional
- Se erradicó por completo el uso de estados globales como `_G.SistemaGameplay` y `_G.ParticulasConexion`, transformando el core en máquinas de estados bien configuradas: 
  - Manejo por servidor (`Boot.server.lua`: MENU $\rightarrow$ CARGANDO $\rightarrow$ GAMEPLAY)
  - Manejo por cliente (`ClientBoot.client.lua`: INICIO $\rightarrow$ MENU $\rightarrow$ GAMEPLAY con Guards para doble pulsación).
- Se forjó el **GestorEfectos.lua** como un Bus centralizado de *Highlighting y Partículas*, erradicando escuchas repetidas parciales del HUD visual.

---

## 3. ASUNTOS PENDIENTES ORIGINALES (Por abordar) ⏳

Derivado del `ANALISIS_CODIGO.md` original, las siguientes asignaturas continúan abiertas y deben considerarse prioritarias para el desarrollo venidero:

| Tarea | Impacto y Detalle |
|---|---|
| **Nil-checks tras `WaitForChild`** | *Robustez:* Faltan aserciones a los componentes de red/carpetas (Ej: `EventosHUD.lua` y `Boot.server.lua`). Un timeout no gestionado de `WaitForChild` provocará fallos silenciosos y detendrá cadenas de eventos importantes. |
| **`pcall` ciego en Boot** | *Debuging:* El boot no muestra un mensaje descriptivo si un servicio de requerimientos falla silenciosamente. Se recomienda un early return con un error detallado si por ejemplo dependencias base no cargan. |
| **Validar `LevelsConfig`** | *Datos:* Cargar niveles vacíos (ej. niveles 1-4 listados en Configura sin un mapa validado) falla silenciosamente. Se necesita un comprobador de esquema antes de iniciar la instanciación de un mapa. |
| **Invertir Orden FireClient** | *Desincronización:* En `ConectarCables`, se lanza primero el `FireClient` y luego se muta `ValidadorConexiones.registrarConexion()`. Si el cliente consulta sus conexiones en el instante exacto, verá datos antiguos. |

---

### Resumen de Próximos Pasos (Hoja de Ruta Resultante)
1. **Unificación de Eventos Remotos**: Mover las suscripciones locales al evento `NotificarSeleccionNodo` dispersas en los controladores HUD hacia un gestor de eventos del cliente único.
2. **Implementar GlobalState (Cliente y Servidor)**: Reemplazar las repetitivas lecturas de atributos (`ZonaActual`, `CurrentLevelID`) con un módulo `GameStateManager`.
3. **Refinar `ControladorDialogo`**: Aislar la responsabilidad de oscurecimiento y mostrar UI hacia un Administrador de GUI en lugar de iterar objetos físicamente desde el script de diálogos.
4. **Completar validaciones pendientes**: Nil-checking en llamadas a la red, reordenamiento de llamadas y validación estructural del JSON de niveles.
