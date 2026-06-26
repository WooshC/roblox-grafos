# Refactorización: centralizar lógica pura de grafo en `GrafoHelpers`

> Estado: **avanzado** — la mayoría de las duplicaciones ya fueron migradas.  
> Última actualización: 2026-06-14

## 1. Objetivo

Convertir `ReplicatedStorage/Compartido/GrafoHelpers.lua` en la **única fuente de verdad** para operaciones puras sobre grafos:

- Claves canónicas de pares de nodos.
- Lectura de pesos de arista.
- Detección de cables defectuosos (configuración estática).
- Cálculo y formato de costos.
- Construcción de matrices y conversiones de adyacencias.

El estado dinámico de conexiones (cables creados/eliminados/reemplazados por el jugador) sigue viviendo en `ServerScriptService/SistemasGameplay/ValidadorConexiones.lua`.

## 2. Principios

| Tipo de dato | Fuente de verdad | ¿Por qué? |
|--------------|------------------|-----------|
| Claves canónicas (`A|B`) | `GrafoHelpers.clavePar / parsearClave` | Un solo separador (`|`) y un solo orden (alfabético). |
| Pesos de arista (estáticos) | `GrafoHelpers.obtenerPeso` | Prueba tanto clave canónica como inversa, evita el bug "sale 4 en vez de 5". |
| Cables defectuosos (estáticos) | `GrafoHelpers.esCableDefectuoso` | Soporta `CablesDefectuosos` (array) y `Defectuosos` (set). |
| Set de defectuosos estáticos | `GrafoHelpers.defectuososSet` | Construye el set de claves canónicas en un solo lugar. |
| Costo de una arista | `GrafoHelpers.calcularCosto` | `math.floor(peso * costoPorMetro)` en un solo lugar. |
| Formato de dinero | `GrafoHelpers.formatearDinero` | Separador de miles consistente en toda la UI. |
| Matriz teórica desde `Adyacencias` | `GrafoHelpers.construirMatriz` | Unifica lógica de matrices en cliente y servidor. |
| Adyacencias desde respuesta de matriz | `GrafoHelpers.adjDesdeMatriz` | Filtra defectuosas con la misma función pura. |
| Conexiones dinámicas del jugador | `ValidadorConexiones` | Necesita estado mutable del servidor. |

## 3. API de `GrafoHelpers`

```lua
local GH = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("GrafoHelpers"))

GH.clavePar(nomA, nomB)                 -- "A|B" ordenado alfabéticamente
GH.parsearClave(clave)                    -- "A", "B"
GH.nodosDeZona(adyacencias, zonaID, config)
GH.detectarDirigido(adyacencias, nodos)
GH.obtenerPeso(configOrNivelID, nomA, nomB, default)
GH.esCableDefectuoso(configOrNivelID, nomA, nomB)
GH.defectuososSet(configOrNivelID)        -- { [clavePar] = true }
GH.calcularCosto(peso, costoPorMetro)
GH.formatearDinero(valor)
GH.adjDesdeMatriz(data, incluirDefectuosas, configOrNivelID)
GH.construirMatriz(adyacencias, nodos, esDirigido)
GH.nodosAlcanzables(adyacencias, inicio)           -- { [nomNodo] = true }
GH.nodosNoAlcanzables(adyacencias, inicio, nodos)  -- { [nomNodo] = true }
```

`configOrNivelID` acepta:
- un `number` (`nivelID`);
- una tabla `config`/`data` con `PesosAristas`/`CablesDefectuosos`/`Defectuosos`;
- una tabla plana de claves canónicas (por ejemplo `data.Defectuosos` devuelto por el servidor), que se usa directamente como set dinámico de defectuosos.

## 4. Migraciones completadas

| Archivo | Cambio realizado |
|---------|------------------|
| `ServerScriptService/SistemasGameplay/ValidadorConexiones.lua` | Eliminados envoltorios `generarClave` y `parsearClave`; usa `GrafoHelpers` directamente. |
| `ServerScriptService/SistemasGameplay/ConectarCables.lua` | Eliminados envoltorios `clavePar` y `obtenerPesoArista`; usa `GrafoHelpers.clavePar` y `GrafoHelpers.obtenerPeso`. |
| `ServerScriptService/SistemasGameplay/ServicioMisiones.lua` | Eliminado envoltorio `clavePar`; usa `GrafoHelpers.clavePar`. |
| `ServerScriptService/SistemasGameplay/ServicioGrafosAnalisis.lua` | Usa `GrafoHelpers.construirMatriz` y `GrafoHelpers.defectuososSet`. |
| `ServerScriptService/SistemasGameplay/MatrizAdyacencia.server.lua` | Devuelve pesos reales en `Matrix` y el set `Defectuosos` separado; usa `ValidadorConexiones` para estado dinámico. |
| `ServerScriptService/Servicios/CargadorNiveles.lua` | Callbacks `onCableEliminado` y `onAntesCrearCable` usan `GrafoHelpers.obtenerPeso` y `GrafoHelpers.calcularCosto` (se reparó corrupción de texto). |
| `StarterPlayerScripts/SistemasGameplay/ControladorEfectos.client.lua` | Claves inline `.. "|" ..` reemplazadas por `GrafoHelpers.clavePar`; usa `calcularCosto` y `formatearDinero`. |
| `StarterPlayerScripts/HUD/ModulosHUD/EjecutorAlgoritmo3D.lua` | Eliminado `obtenerPesoArista` local; lee pesos/costos/defectuosos desde `GrafoHelpers`. |
| `StarterPlayerScripts/HUD/ModulosHUD/ModuloMatriz.lua` | Eliminado `esCableDefectuoso` local; usa `GrafoHelpers.esCableDefectuoso`. |
| `StarterPlayerScripts/HUD/ModulosHUD/ModuloAnalisis/PanelEstadoAnalisis.lua` | Cálculo de peso/costo total acumulado usa `GrafoHelpers`. |
| `StarterPlayerScripts/HUD/ModulosHUD/ModuloAnalisis/PanelEstadoAnalisis.lua` | Modo validación resalta nodos no alcanzables con `GrafoHelpers.nodosNoAlcanzables`. |
| `StarterPlayerScripts/HUD/ModulosHUD/ModuloAnalisis.lua` | Modo validación fuerza BFS y usa `GrafoHelpers.nodosNoAlcanzables` para el mensaje final. |
| `StarterPlayerScripts/HUD/ModulosHUD/ModuloAnalisis/ViewportAnalisis.lua` | Usa `GrafoHelpers.clavePar` y `GrafoHelpers.esCableDefectuoso`. |
| `StarterPlayerScripts/HUD/ModulosHUD/EstadoConexiones.lua` | Eliminado envoltorio `generarClave`; parseo de claves centralizado en `GrafoHelpers.parsearClave`. |
| `StarterPlayerScripts/HUD/ModulosHUD/Minimap.lua` | Clave inline reemplazada por `GrafoHelpers.clavePar`. |
| `StarterPlayerScripts/HUD/ModulosHUD/PuntajeHUD.lua` | Eliminado `formatearDinero` local; usa `GrafoHelpers.formatearDinero`. |
| `ReplicatedStorage/Efectos/EfectosDialogo.lua` | Eliminado envoltorio `clavePar`; usa `GrafoHelpers.clavePar`. |

## 5. Duplicaciones menores que aún quedan

| Archivo | Detalle | ¿Recomendación? |
|---------|---------|-----------------|
| `StarterPlayerScripts/SistemasGameplay/ControladorEfectos.client.lua` | Lee `LevelsConfig[_nivelActualID].CostoPorMetro` directamente para validar si hay costo. | Opcional. No es lógica de grafo, es lectura de config. |
| `StarterPlayerScripts/HUD/ModulosHUD/ModuloAnalisis/PanelEstadoAnalisis.lua` | Lee `E.matrizData.CostoPorMetro` / `LevelsConfig[nivelID].CostoPorMetro` directamente. | Opcional. `GrafoHelpers.calcularCosto` ya se usa; solo falta lector de config. |
| `ReplicatedStorage/DialogoData/DialogosNivel*/*.lua` | Leen `LevelsConfig[nivel].CostoPorMetro` para textos de diálogo. | Intencional: scripts de diálogo no necesitan depender de `GrafoHelpers`. |

## 6. Decisiones técnicas clave

### 6.1 Separación `Matrix` vs `Defectuosos`

El valor `2` ya no significa "defectuoso". `Matrix` contiene el peso real (o `1` si es binaria) y `Defectuosos` es un set de claves canónicas. Esto evita que un peso real igual a `2` sea interpretado como defectuoso.

### 6.2 Lectura bidireccional del peso

`GrafoHelpers.obtenerPeso` prueba:

1. `PesosAristas[clavePar(A,B)]`
2. `PesosAristas[B|A]` (clave invertida)
3. `default`

Esto resuelve el bug donde una arista configurada como `Gen_Fabrica|Entrada` no se encontraba porque `clavePar` normaliza a `Entrada|Gen_Fabrica`.

### 6.3 Costo total acumulado en el panel

- **Dijkstra**: usa `distancias[nodoFin]` (o `nodoActual` si aún no hay fin).
- **Prim / BFS**: suma `GrafoHelpers.obtenerPeso` de cada arista recorrida.

### 6.4 Tags y hitboxes usan claves canónicas

`ControladorEfectos` ya no genera claves `COSTO_A|B` y `COSTO_B|A`. Usa siempre `GrafoHelpers.clavePar`, eliminando duplicados y bugs por orden invertido.

### 6.5 Validación de nodos aislados con BFS

El modo "Ejecutar/Probar Red" fuerza `E.algoActual = "bfs"` para recorrer la red real del jugador. Al final del BFS, `GrafoHelpers.nodosNoAlcanzables` determina qué nodos no fueron alcanzados desde el origen; esos nodos se pintan de rojo. El algoritmo original del análisis se restaura al terminar o al cerrar el panel.

## 7. Próximos pasos opcionales

1. **Limpiar lecturas de `CostoPorMetro`** en `ControladorEfectos` y `PanelEstadoAnalisis` si se decide que también deben pasar por `GrafoHelpers`.
2. **Probar en Roblox Studio** todos los niveles (especialmente creación/eliminación de cables y matriz de adyacencia).
3. **Actualizar/agregar tests** si el proyecto los tiene.
4. **Reescribir diálogos Nivel 2 y Nivel 3** (pendiente de diseño de contenido, no técnico).

## 8. Notas de migración segura

- Antes de reemplazar, **releer el archivo**; el código puede tener cambios recientes.
- Prefiere `StrReplaceFile` con la cadena exacta del archivo en lugar de reemplazos globales.
- No hay intérprete Lua/Luau en el entorno; las pruebas deben hacerse en Roblox Studio.
- No modificar `ServicioGrafosAnalisis` salvo para delegar lecturas puras; su arquitectura general queda fuera de este refactor.
