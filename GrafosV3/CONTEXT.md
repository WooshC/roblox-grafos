# GrafosV3 — Contexto Completo del Proyecto

> Documento generado para que cualquier IA comprenda rápidamente la arquitectura, mecánicas, estructura de código y convenciones de este proyecto Roblox de educación en Teoría de Grafos.

---

## 1. Visión General

**GrafosV3** es un juego educativo de Roblox (Serious Game) que enseña conceptos de teoría de grafos y algoritmos (BFS, DFS, Dijkstra, Prim) a través de una narrativa de reparación de redes eléctricas en barrios de una ciudad.

**Personaje protagonista:** Tocino (el jugador), empleado de una empresa eléctrica.
**Personaje guía:** Carlos, su supervisor.
**Antagonista narrativo:** El alcalde, que miente sobre el estado de las redes.

---

## 2. Arquitectura General

### 2.1 Regla de Oro
> **Un solo punto de entrada.** Mientras el menú esté activo, TODO lo relacionado al gameplay está completamente desconectado. La máquina de estados dicta: `INICIO → MENU → CARGANDO → GAMEPLAY → MENU`.

### 2.2 Separación Cliente-Servidor

| Ubicación | Rol |
|---|---|
| `ServerScriptService/` | Lógica de servidor: boot, progreso, validación de conexiones, misiones, puntaje, energía, matrices de adyacencia |
| `StarterPlayerScripts/` | Lógica de cliente: HUD, menú, diálogos, efectos visuales, audio, input del jugador |
| `ReplicatedStorage/` | Datos compartidos: configuración de niveles, datos de diálogos, efectos visuales, utilidades |

### 2.3 Eventos de Red

Todos los eventos se crean en `ReplicatedStorage/EventosGrafosV3/Remotos` (y `Bindables`).

**Servidor → Cliente:** `ServidorListo`, `NivelListo`, `NivelDescargado`, `CableDragEvent`, `NotificarSeleccionNodo`, `PulsoEvent`, `ActualizarPuntuacion`, `ActualizarMisiones`, `NivelCompletado`, `ProgresoEnergia`

**Cliente → Servidor:** `IniciarNivel`, `VolverAlMenu`, `ReiniciarNivel`, `MapaClickNodo`, `ConectarDesdeMapa`, `ToggleMapaAbierto`

**RemoteFunctions:** `ObtenerProgresoJugador`, `GetAdjacencyMatrix` (estado real), `GetGrafoCompleto` (estado teórico)

---

## 3. Estructura de Carpetas y Archivos Clave

### ServerScriptService/
```
Nucleo/
  00_EventRegistry.server.lua  -- Crea TODOS los RemoteEvent/RemoteFunction/BindableEvent
  Boot.server.lua              -- Máquina de estados por jugador, orquesta carga/descarga
Servicios/
  CargadorNiveles.lua          -- Carga modelos, aplica iluminación, spawnea, inicializa sistemas
  ServicioDatos.lua            -- Wrapper DataStoreService
  ServicioProgreso.lua         -- Enriquece LevelsConfig con datos persistentes
SistemasGameplay/
  ConectarCables.lua           -- Click en nodos, crear/eliminar cables visuales (Beam)
  ValidadorConexiones.lua      -- FUENTE DE VERDAD del grafo activo. BFS, componentes conexos
  ServicioMisiones.lua         -- Motor de misiones: ARISTA_CREADA, GRADO_NODO, GRAFO_CONEXO, etc.
  ServicioPuntaje.lua          -- Tracking de métricas y cálculo de puntaje/estrellas
  ServicioEnergia.lua          -- Propagación BFS de energía desde generadores
  ServicioGrafosAnalisis.lua   -- Matriz de adyacencia TEÓRICA completa
  MatrizAdyacencia.server.lua  -- Matriz de adyacencia REAL (solo cables activos)
  GestorZonas.lua              -- Detección de triggers de zona por Touched/TouchEnded
```

### StarterPlayerScripts/
```
Nucleo/
  ClientBoot.client.lua        -- Máquina de estados cliente: MENU ↔ GAMEPLAY
Compartido/
  ControladorAudio.client.lua  -- Audio con crossfading, volúmenes dinámicos
Dialogo/
  ControladorDialogo.client.lua -- Orquestador: bloqueo jugador, cámara, HUD, click aéreo
  DialogoController.lua         -- Lógica de líneas, opciones, eventos, expresiones
  DialogoRenderer.lua           -- Typewriter, transiciones, animaciones
  DialogoGUISystem.lua          -- Sistema principal: Play, Next, Skip, SelectChoice, LoadDialogue
  DialogoEvents.lua             -- Input: botones, teclado (ESPACIO/ENTER=Continuar, ESC=Saltar)
  DialogoExpressions.lua        -- Catálogo de imágenes por personaje/expresión
  DialogoNarrator.lua           -- Reproducción de audio y TTS
  DialogoTTS.lua                -- Texto a Voz con AudioTextToSpeech API de Roblox
  DialogoButtonHighlighter.lua  -- Destacar botones HUD durante diálogos
HUD/
  ModulosHUD/                   -- Panel misiones, minimapa, matriz, análisis, victoria, etc.
Menu/
  ControladorMenu.client.lua    -- Menú principal con tarjetas de niveles
  AudioMenu.client.lua          -- Audio del menú
SistemasGameplay/
  ControladorEfectos.client.lua -- Aplica highlights y billboards
  GestorEfectos.lua             -- Patrón pub/sub para eventos remotos
  SistemaEnergia.client.lua     -- Enciende/apaga luces según progreso de energía
  GuiaService.lua               -- Beam guía con flechas hacia objetivos
  RetroalimentacionConexion.client.lua -- Feedback visual de errores
  ParticulasConexion.client.lua -- Bolas de luz con Trail por las aristas
```

### ReplicatedStorage/
```
Config/
  LevelsConfig.lua             -- FUENTE ÚNICA DE VERDAD para todos los niveles
DialogoData/
  DialogosNivel0/              -- Bienvenida, Zona1_NodosAristas, Zona2_GradoNodo, Zona4_Conectividad
  DialogosNivel1/              -- Nivel1_Estacion, Nivel1_Mercado, Nivel1_Canchas, Nivel1_Parque
  Feedback_Conexiones.lua      -- Diálogos de error: ConexionInvalida, DireccionInvalida
Compartido/
  GrafoHelpers.lua             -- clavePar, parsearClave, nodosDeZona, detectarDirigido
  ServicioCamara.lua           -- moverHaciaObjetivo, restaurar, bloquear (anti-deadlock)
  GestorColisiones.lua         -- Ocultar/restaurar techos para vista cenital
Efectos/
  EfectosDialogo.lua           -- resaltarNodo, mostrarLabel, mostrarArista, blink, limpiarTodo
  EfectosHighlight.lua         -- Sistema centralizado de Highlights de Roblox
  BillboardNombres.lua         -- Etiquetas flotantes 3D
  EfectosCable.lua             -- Beams con pulso UV de energía
  PresetTween.lua              -- Configuraciones de tweening reutilizables
  EfectosVideo.lua             -- Efectos de video generales
  EfectosNodo.lua              -- Efectos de nodos
Audio/
  ConfigAudio.lua              -- Configuración de audio
```

---

## 4. Sistema de Diálogos (Muy Importante)

### 4.1 Estructura de un Archivo de Diálogo

```lua
local DIALOGOS = {
    ["ID_Dialogo"] = {
        Zona  = "Zona_Nombre_1",      -- Debe coincidir con LevelsConfig[nivel].Zonas
        Nivel = 1,
        Lineas = {
            {
                Id        = "identificador_unico",
                Numero    = 1,
                Actor     = "Carlos",              -- Personaje que habla
                Expresion = "Sonriente",           -- Debe existir en DialogoExpressions
                Texto     = "Texto del diálogo...",
                Evento = function()
                    -- Efectos visuales, movimiento de cámara, etc.
                    EfectosDialogo.limpiarTodo()
                    ServicioCamara.moverHaciaObjetivo("NombreNodo", { altura=25, angulo=65, duracion=1.5 })
                    EfectosDialogo.resaltarNodo("NombreNodo", "SELECCIONADO")
                    EfectosDialogo.mostrarLabel("NombreNodo", "Etiqueta", "SELECCIONADO")
                end,
                Opciones = {
                    { Texto = "Opción A", Siguiente = "id_siguiente_correcto" },
                    { Texto = "Opción B", Siguiente = "id_siguiente_incorrecto" },
                },
                EsperarAccion = { tipo = "conectarNodos", nodoA = "X", nodoB = "Y" },
                Siguiente = "id_siguiente_linea",  -- "FIN" termina el diálogo
            },
        },
        Metadata = {
            TiempoDeEspera = 0.5,
            VelocidadTypewriter = 0.03,
            PuedeOmitir = true,
            OcultarHUD = true,
            UsarTTS = true,
        },
        Configuracion = {
            bloquearMovimiento = true,
            bloquearSalto = true,
            apuntarCamara = true,
            ocultarTechos = true,
            permitirConexiones = false,  -- true = permite click aéreo durante diálogo
        },
        EventoSaltar = function()
            -- Se ejecuta al presionar Saltar
            EfectosDialogo.limpiarTodo()
            ServicioCamara.restaurar(0)
        end,
        EventoSalida = function()
            -- Se ejecuta al cerrar el diálogo
            EfectosDialogo.limpiarTodo()
        end,
    }
}
return DIALOGOS
```

### 4.2 Actores Disponibles y Expresiones

**Carlos** (personaje principal):
- `Sonriente`, `Serio`, `Feliz`, `Sorprendido`, `Enojado`, `Presentacion`, `Normal`, `Triste`, `Pensativo`, `Curioso`, `Extasiado`

**Sistema** (sin imagen de personaje, usa iconos):
- `Nodo`, `Arista`, `NodoPrincipal`, `Generador`, `Arista_energizada`, `Arista_conectada`, `Normal`

### 4.3 Funciones de EfectosDialogo (usadas en Eventos)

| Función | Uso |
|---|---|
| `EfectosDialogo.limpiarTodo()` | Limpia TODOS los efectos del diálogo |
| `EfectosDialogo.resaltarNodo("NombreNodo", "TIPO")` | Highlight sobre nodo. TIPOS: `SELECCIONADO`, `ADYACENTE`, `CONECTADO`, `AISLADO`, `EXITO`, `ERROR` |
| `EfectosDialogo.mostrarLabel("NombreNodo", "Texto", "TIPO")` | Etiqueta flotante sobre nodo |
| `EfectosDialogo.mostrarArista("A", "B", "TIPO", {sinParticulas=true, dirigido=false})` | Beam visual falso entre nodos |
| `EfectosDialogo.blink("NombreNodo", "TIPO", ciclos)` | Parpadeo de highlight |
| `EfectosDialogo.quitarArista("A", "B")` | Quita arista falsa |

### 4.4 Funciones de ServicioCamara (usadas en Eventos)

| Función | Uso |
|---|---|
| `ServicioCamara.moverHaciaObjetivo("NombreNodo", {altura=25, angulo=65, duracion=1.5})` | Mueve cámara con ángulo configurable. `angulo=90` = cenital puro |
| `ServicioCamara.restaurar(1.2)` | Restaura cámara al jugador |
| `ServicioCamara.bloquear()` | Bloquea cámara (Scriptable) sin mover |

### 4.5 Cómo se Disparan los Diálogos

1. **Por Zona:** Cuando el jugador entra a una zona (atributo `ZonaActual` cambia), `ControladorDialogo.client.lua` busca el `Dialogo` configurado en `LevelsConfig[nivel].Zonas[nombreZona].Dialogo` y lo inicia automáticamente.
2. **Por Prompt:** Si hay `DialoguePrompts` en el nivel con `ProximityPrompt`, al presionar E se inicia el diálogo configurado.
3. **Programáticamente:** `_G.ControladorDialogo.iniciar("ID_Dialogo", opciones)`

### 4.6 Interactividad en Diálogos

- `Opciones`: Muestra botones A/B/C... con navegación a diferentes líneas.
- `EsperarAccion`: Bloquea el avance hasta que el jugador realice una acción de gameplay.
  - `{ tipo = "seleccionarNodo", nodo = "NombreNodo" }`
  - `{ tipo = "conectarNodos", nodoA = "A", nodoB = "B" }`
- `DestacarBoton`: Resalta un botón del HUD durante el diálogo (tutorial).

---

## 5. Configuración de Niveles (LevelsConfig)

### 5.1 Nivel 0: Laboratorio de Grafos (Tutorial)
- **Conceptos:** Nodos, Aristas, Adyacencia, Grado
- **Zonas:** Nodos y Aristas → Grado de Nodo → Grafos Dirigidos → Conectividad
- **Algoritmo:** Grafos No Dirigidos

### 5.2 Nivel 1: El Barrio Antiguo (La Ferroviaria)
- **Conceptos:** Onda por Capas, Mínimo de Saltos, Nodos Aislados, Grafo Conexo
- **Algoritmo:** BFS
- **Ambientación:** Medianoche (`Reloj=0`), iluminación azul oscura, linterna del jugador activa
- **Zonas:**
  - `Zona_Ferroviaria_1` (Estación Plana): BFS capa por capa
  - `Zona_Mercado_2` (Mercado Central): Distancia mínima en saltos
  - `Zona_Canchas_3` (Las Canchas): Nodos y subgrafos aislados
  - `Zona_Parque_4` (Parque del Barrio): Grafo conexo completo
- **Cables iniciales:** `Gen_Estacion_z1→Casa_Estacion1_z1`, `Parque_z1→Poste_Mercado_z2`
- **Cables defectuosos:** `Poste_Canchas_z3→Casa_Canchas_z3` (visual pero no enruta)

### 5.3 Niveles 2-4 (Plantillas vacías)
- Nivel 2: La Fábrica de Señales (BFS + DFS)
- Nivel 3: El Puente Roto (Grafos Dirigidos)
- Nivel 4: Ruta Mínima (Dijkstra)

---

## 6. Sistemas de Gameplay Clave

### 6.1 Conexión de Cables
- Click en `Selector` (parte del nodo) → selecciona origen
- Click en otro `Selector` → crea cable si son adyacentes en `LevelsConfig.Adyacencias`
- Toggle: si ya están conectados, al hacer click se desconectan
- Visual: `Beam` entre `Attachment`s + `Part` hitbox invisible con `ClickDetector`

### 6.2 ValidadorConexiones (Fuente de Verdad)
- `registrarConexion()` / `eliminarConexion()`
- `obtenerAlcanzables(inicio)` → BFS
- `contarComponentes(nombresNodos)` → BFS por componentes
- `esGrafoConexo(nombresNodos)`
- Cables defectuosos: se registran pero se omiten en BFS (marcados con valor `2` en matriz)

### 6.3 Motor de Misiones
Tipos de misión implementados:
- `NODO_SELECCIONADO`: El jugador selecciona un nodo específico o ANY
- `ARISTA_CREADA`: Conecta dos nodos específicos
- `GRADO_NODO`: Alcanza grado mínimo en un nodo
- `GRAFO_CONEXO`: Todos los nodos de un subconjunto están conectados entre sí
- Las misiones de cableado NO son permanentes: desconectar revoca la misión

### 6.4 Sistema de Puntaje
- `PuntosConexion` (default 50) por cada cable válido
- `PenaFallo` (default 10-20) por cada intento inválido
- `PuntosPreguntaCorrecta` (100) por respuestas correctas en diálogos
- Estrellas: 3 estrellas si supera umbral, 2 estrellas si supera umbral menor

### 6.5 Propagación de Energía
- BFS multi-raíz desde `LevelsConfig.Generadores`
- Calcula `% nodos energizados` por zona
- Cliente recibe `ProgresoEnergia` y enciende/apaga luces progresivamente

### 6.6 Panel de Análisis (Tab)
- Simulador pedagógico con 4 algoritmos: BFS, DFS, Dijkstra, Prim
- Pseudocódigo resaltado línea a línea
- Viewport 3D con partículas direccionales
- Detecta nodos aislados en la topología real del jugador
- Configurado por zona en `LevelsConfig[nivel].AnalisisConfig`

---

## 7. Convenciones de Código

### 7.1 Nombres de Nodos
- Formato: `NombreDescriptivo_z<N>` donde N = número de zona
- Ejemplos: `Gen_Estacion_z1`, `Poste_Mercado_z2`, `Casa_Canchas_z3`, `Fuente_z4`
- El separador canónico de pares es `|` (pipe), NUNCA `_` (porque los nombres de nodo usan `_`)

### 7.2 Zonas
- Formato ID: `Zona_NombreDescriptivo_N` (ej: `Zona_Ferroviaria_1`, `Zona_Mercado_2`)
- Triggers: `ZonaTrigger_Nombre` (ej: `ZonaTrigger_Inicio`, `ZonaTrigger_Mercado`)
- Los nodos de una zona pueden identificarse por sufijo `_zN` o por mapa explícito `NodosZona`

### 7.3 Estructura del Nivel en Workspace
```
NivelActual/
  Escenario/
  Grafos/
    Grafo_Barrio/
      Nodos/
        Nodo1/
          Selector (BasePart con ClickDetector + Attachment)
          Decoracion/
      Conexiones/
      Meta/
  Zonas/
    Triggers/
      ZonaTrigger_XXX (BasePart con CanCollide=false, Transparency=1)
  DialoguePrompts/  (opcional)
    PromptCarlos/
      PromptPart (BasePart con ProximityPrompt)
```

---

## 8. Funciones y Sistemas No Documentados en Consolidado Original

Los siguientes sistemas están implementados y operativos pero NO aparecían en el consolidado original:

1. **Sistema de Diálogos completo** (DialogoGUISystem, ControladorDialogo, DialogoController, DialogoRenderer, DialogoEvents)
2. **Texto a Voz (TTS)** con AudioTextToSpeech API de Roblox (DialogoTTS, DialogoNarrator)
3. **EfectosDialogo** (resaltarNodo, mostrarLabel, mostrarArista, blink, limpiarTodo)
4. **ServicioCamara** (moverHaciaObjetivo con ángulo configurable, anti-deadlock)
5. **DialogoExpressions** (catálogo de imágenes por personaje/expresión)
6. **Feedback de Conexiones** (diálogos automáticos de error: ConexionInvalida, DireccionInvalida)
7. **Sistema de Guía** (GuiaService: Beam con flechas animadas hacia objetivos)
8. **Click Aéreo en Diálogos** (raycast desde cámara cenital para conectar nodos durante diálogos)
9. **EsperarAccion en Diálogos** (interactividad: seleccionarNodo, conectarNodos)
10. **DestacarBoton en Diálogos** (tutorial interactivo que resalta botones HUD)
11. **Sistema de Partículas de Conexión** (bolas de luz con PointLight y Trail)
12. **Retroalimentación de Conexiones** (feedback visual inmediato al error)
13. **Sistema de Energía Visual** (apaga/enciende luces del nivel progresivamente)
14. **EventoSalida en Diálogos** (limpieza automática al cerrar diálogo)
15. **DialogoButtonHighlighter** (señalización de botones HUD durante tutoriales)

---

## 9. Dependencias Clave

- **ValidadorConexiones** es la base: lo usan ConectarCables, ServicioEnergia, ServicioMisiones, ServicioPuntaje, MatrizAdyacencia.
- **ConectarCables** orquesta la interacción del jugador y notifica vía callbacks.
- **CargadorNiveles** es el orquestador de nivel: inicializa y para todos los demás sistemas.
- **Boot.server** protege todo con la máquina de estados (`estaEnGameplay`).
- **LevelsConfig** es la fuente única de verdad para datos de niveles.
- **DialogoData** encapsula la pedagogía narrativa.

---

## 10. Requisito Especial del Nivel 1: Diálogos Correctos para 3 Estrellas

El Nivel 1 tiene un requisito especial configurado en `LevelsConfig[1]`:
- `RequiereDialogosCorrectos = true`
- `TotalPreguntasDialogo = 5` (1 en Estación + 2 en Mercado + 1 en Canchas + 1 en Parque)

**Flujo:**
1. El cliente envía `DialogoCorrecto:FireServer()` al responder correctamente cada pregunta.
2. `Boot.server.lua` lleva un contador `_dialogosCorrectos[userId]`.
3. Al finalizar el nivel, `ServicioMisiones.calcularEstrellasHelper()` verifica si el jugador tiene todas las respuestas correctas.
4. Si no las tiene, limita las estrellas a **2 máximo**, aunque el puntaje supere el umbral de 3 estrellas.
5. `VictoriaHUD.lua` muestra un mensaje amarillo en el subtítulo: *"¡Respondiste algunas preguntas incorrectamente! Vuelve a intentarlo para obtener 3 estrellas."*

## 11. Tips para Modificar Diálogos

1. **Siempre usar `EfectosDialogo.limpiarTodo()`** al inicio de cada Evento para evitar efectos acumulados.
2. **Restaurar cámara** al final del diálogo: `ServicioCamara.restaurar(1.2)`.
3. **Los nombres de nodo** deben coincidir EXACTAMENTE con los definidos en `LevelsConfig[nivel].NombresNodos`.
4. **Las zonas** deben coincidir con `LevelsConfig[nivel].Zonas`.
5. **Las expresiones** deben existir en `DialogoExpressions.lua`.
6. **Para interactividad:** usar `EsperarAccion` con `permitirConexiones = true` en Configuracion.
7. **Para tutoriales:** usar `DestacarBoton` para resaltar botones del HUD.
8. **Para preguntas:** usar `Opciones` con `Siguiente` apuntando a líneas de respuesta correcta/incorrecta.
9. **Para requisito de 3 estrellas:** llamar `notificarRespuestaCorrecta()` (o `DialogoCorrecto:FireServer()`) en el `Evento` de cada respuesta correcta.
10. **Cerrar con "FIN"** la última línea o usar `Opciones` que apunten a "FIN".
