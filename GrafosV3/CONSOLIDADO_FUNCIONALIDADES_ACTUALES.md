# GrafosV3 — Consolidado de Funcionalidades Actuales
> Documentación técnica exhaustiva basada en el código real del proyecto. Enumeración de funciones, mecánicas y sistemas que actualmente están **implementados y operativos**.

---

## 1. La Regla de Oro del Sistema
> **REGLA DE ORO:** Un solo punto de entrada. Mientras el menú esté activo, TODO lo relacionado al gameplay está completamente desconectado. Nunca coexisten sistemas activos. La máquina de estados dicta el ciclo de vida del jugador obligatoriamente: `INICIO → MENU → CARGANDO → GAMEPLAY → MENU`.

---

## 2. Ciclo de Vida e Inicialización (Boot Stage)
La carga del juego es determinista y controlada en fases estrictas:
- **`00_EventRegistry.server.lua` (Pre-Boot):** Se auto-ejecuta como el primer elemento absoluto. Construye físicamente la carpeta `EventosGrafosV3` en `ReplicatedStorage` y registra dinámicamente cada `RemoteEvent`, `RemoteFunction` y `BindableEvent` necesario para el juego. Garantiza que cuando los clientes arranquen, los canales de comunicación ya existan obligatoriamente.
- **`Boot.server.lua` (Servidor):** Instancia la máquina de estados. Mantiene a los jugadores desconectados de físicas (sin autospawn) hasta que eligen un nivel. Al elegir, utiliza `CargadorNiveles.lua` para destruir el mapa viejo, instanciar el nivel nuevo desde `ServerStorage`, teleportar al jugador y encender los submotores (Misiones, Zonas, Puntuación).
- **`ClientBoot.client.lua` (Cliente):** Mimetiza la máquina de estados en el frontend. Oculta el HUD general y muestra la GUI de Menú Principal hasta recibir el evento server `NivelListo`, momento en el cual apaga el menú e inicializa las GUI de gameplay.

---

## 3. Núcleo Matemático y Teoría de Grafos
- **`MatrizAdyacencia.server.lua`:** Actúa como el puente lógico entre lo físico y lo matemático. Constantemente inspecciona el nivel en busca de conexiones eléctricas físicas activas (`Hitboxes_A|B`) y las cruza contra el `LevelsConfig`. Genera dinámicamente una Matriz de Adyacencia `NxN` y la provee a los clientes (vía `GetAdjacencyMatrix`) para que el frontend pueda dibujar algoritmos.
- **`GrafoHelpers.lua`:** La librería centralizada del juego. Normaliza las claves de búsqueda usando el formato estricto *pipe* (`NodoA|NodoB`). Estandariza funciones crudas como `detectarDirigido()` y la extracción de `nodosDeZona()`, forzando a todo script externo a hablar el mismo idioma para evitar corromper la Matriz.
- **Análisis de Algoritmos (`AlgoritmosGrafo.lua` / `ServicioGrafosAnalisis.lua`):** Motores matemáticos que corren BFS/DFS simulados, validando si las zonas constituyen subgrafos conexos o tienen componentes aislados.

---

## 4. Lógica Físico Espacial y Jugabilidad
- **Conectividad Física (`ConectarCables.lua` / `ValidadorConexiones.lua`):** Los jugadores hacen clic en nodos adyacentes lógicos para tender conexiones de energía físicas. El sistema en tiempo real valida en ambas direcciones comprobando contra `GrafoHelpers` si la acción es legal para el grafo actual, y spawnea los Hitboxes que la Matriz de Adyacencia leerá después.
- **Detección por Zonas (`GestorZonas.lua`):** Detecta físicamente en qué subgrafo (barrio/área) está el jugador parado utilizando `ZoneTriggers`. Controla el paso de mensajes apagando y prendiendo subzonas independientemente para evitar sobrecarga del servidor.
- **Ocultamiento Cenital (`GestorColisiones.lua`):** Al activar la cámara aérea (Mapa), un bus local intercepta los techos del mapa elevando sus CFrame `10000` studs en el aire y haciéndolos transparentes para dejar a la vista el circuito y permitir al jugador usar el mouse interactivo sin que la geometría estorbe sus "raycasts".

---

## 5. Misiones, Progresión y Puntuaciones
- **Motor de Misiones (`ServicioMisiones.lua`):** Creado dinámicamente con cada nivel. Lee el `LevelsConfig` y se suscribe a los Handlers de los Cables. Vigila constantemente si se requiere conectar Nodos de Misión (ej: `Centro` con `Periferia`). Al completarlas, dispara estados de validación por zona.
- **Puntuación y Victoria (`ServicioPuntaje.lua`):** Otorga un número específico de puntos (+100 por acierto de quiz, puntos por conectar cables, restas por deshacer). Cuando `ServicioMisiones` dictamina mapa resuelto, este módulo dispara la cadena que finaliza y bloquea el nivel (`Victoria!`).
- **Almacenamiento Local (`ServicioProgreso.lua` / `ServicioDatos.lua`):** Guarda silenciosamente el mejor Record (High Score), Estrellas obtenidas, Tiempo record y desbloqueos, y se las transfiere al menú la próxima vez que el jugador inicia.

---

## 6. Sistemas de Interfaz Dinámica (HUD y Menú)
- **Menú Principal (`ControladorMenu.client.lua`):** Renderiza dinámicamente las tarjetas gráficas (Cards) de niveles agrupándolas por "Secciones". Lee el Progreso y cambia el estado visual (Candado, Jugar, Reintentar), animando barras de compleción de currícula.
- **Panel Interfaz Dinámico (`PanelMisionesHUD.lua`):** Panel lateral izquierdo in-game. Escucha los cambios del `GestorZonas` para reconstruir sus listas de checkboxes. Da feedback en vivo a medida que accionas cables.
- **Módulo de Análisis Visual (`ModuloAnalisis` / `ModuloMapa`):** Tecla `Tab` para la tablet de escaneo. Tecla `M` para activar el dron aéreo permitiendo trazar cables a larga distancia en el plano 2D.
- **Cierre del Nivel (`VictoriaHUD` / `TransicionHUD`):** Produce un Flash/Cortinilla para frenar en seco el Input del jugador en pro de festejar la obtención del nivel e inyectar el feedback general.

---

## 7. Efectos de Audio y Video Centralizados (Fase 7 Sistema 2)
- **Motor Maestro de Audio (`ControladorAudio.client` / `ConfigAudio`):** Controlador universal independiente.
    - Maneja volúmenes (Master, Ambiente, BGM, SFX y Victoria).
    - Reproduce `UI/Click`, `UI/Play`, y la música por nivel dinámicamente.
    - Soporta de manera nativa *Crossfading* inteligente de músicas al pasar entre menú y juego y controla el fade para las "Fanfarrias" de final de nivel que reemplazan a los ruidos del entorno temporalmente.
- **Bus Global de FX (`GestorEfectos.lua` / `ControladorEfectos.client`):** Proxy que evita lag instruyendo a los clientes que animen lo siguiente simulado:
    - **Cables con Pulso Eléctrico (`EfectosCable.lua`):** Un cable magnético (`Beam`) se tiñe de un color según `PresetTween` y un módulo `RunService` aplica el desplazamiento `UV` infinito de una textura de destellos para simular flujo de corriente eléctrica.
    - **Billboards Variables (`BillboardNombres.lua`):** Módulo matemático que ancla carteles GUI flotantes a objetos 3D ignorando sombras dinámicas u obstrucciones de luz, cambiando esquemas de color entre `Zona` (`Cyan`), `NodoInteraccion` (`Blanco`) y estado de selección en el Mapa mediante Interpolación Linear Suave (`PresetTween`).
- **Control Fino de Cámara (`ServicioCamara.lua`):** Incluye anidación anti-Deadlock. Rota sin problemas entre enfoques Isométricos o de Persona cancelando transiciones cruzadas, impidiendo estancarse al hablar con un Personaje Guía.

---

## 8. Sistema de Diálogos Narrativos y Educativos (Nuevo — Completo)
- **`DialogoGUISystem.lua`:** Sistema principal de diálogos. Carga diálogos desde `ReplicatedStorage/DialogoData`, gestiona reproducción línea por línea, opciones múltiples, navegación Next/Previous/Skip, y saltos condicionales (`GoToLine`). Soporta singleton pattern.
- **`ControladorDialogo.client.lua`:** Orquestador que integra diálogos con el HUD y el gameplay. Bloquea/desbloquea movimiento del jugador, oculta/restaura HUD, controla cámara, gestiona click aéreo durante diálogos cenitales, y conecta `ProximityPrompts` del nivel.
- **`DialogoController.lua`:** Controlador de lógica de líneas. Renderiza speaker, expresión, texto typewriter, opciones con layout adaptativo (2 botones = grid horizontal, 3+ = lista vertical), y ejecuta eventos personalizados por línea.
- **`DialogoRenderer.lua`:** Efectos visuales del diálogo. Typewriter con velocidad configurable, fade in/out, animación de retrato, pulso, temblor, flash de pantalla.
- **`DialogoEvents.lua`:** Input del sistema de diálogos. Botones Continuar/Saltar/Ojo, teclado (ESPACIO/ENTER=Continuar, ESC=Saltar, H=Ojo, Flechas=Navegación).
- **`DialogoExpressions.lua`:** Catálogo centralizado de imágenes de personajes por expresión. Soporta: `Carlos` (Sonriente, Serio, Feliz, Sorprendido, Enojado, Presentacion, Normal, Triste, Pensativo, Curioso, Extasiado), `Sistema` (iconos de nodo/arista/generador), `Maria`, y fallback `Default`.
- **`DialogoNarrator.lua`:** Sistema de audio para diálogos. Reproduce audio personalizado o usa TTS (Texto a Voz). Integra con `ControladorAudio` centralizado cuando está disponible.
- **`DialogoTTS.lua`:** Implementación de Texto a Voz usando la API oficial `AudioTextToSpeech` de Roblox. Soporta múltiples idiomas (es, en, it, de, fr) y voces configurables por personaje. Incluye pipeline de audio completo (AudioTextToSpeech → Wire → AudioDeviceOutput).
- **`DialogoButtonHighlighter.lua`:** Resalta botones del HUD durante tutoriales (modo pulse, flecha animada, oscurecimiento de fondo).

### Funcionalidades avanzadas de diálogos:
- **`EsperarAccion`:** Diálogos interactivos que pausan hasta que el jugador realiza una acción de gameplay:
  - `seleccionarNodo`: El jugador debe hacer clic en un nodo específico.
  - `conectarNodos`: El jugador debe conectar dos nodos específicos.
- **`DestacarBoton`:** Resalta botones del HUD (`BtnMapa`, etc.) con animaciones y flechas guía.
- **`EventoSaltar` / `EventoSalida`:** Callbacks de limpieza al saltar o cerrar diálogo.
- **Click Aéreo:** Durante diálogos con cámara cenital (`ocultarTechos=true` + `permitirConexiones=true`), usa raycast desde la cámara para seleccionar nodos sin depender de `ClickDetector`.
- **Forwarding de Acciones:** Escucha `NotificarSeleccionNodo` del servidor y traduce eventos de gameplay para avanzar diálogos con `EsperarAccion`.

---

## 9. Efectos Visuales Específicos para Diálogos (Nuevo)
- **`EfectosDialogo.lua`:** Sistema exclusivo de efectos visuales para el sistema de diálogos:
  - `resaltarNodo(nombre, tipo)` — Highlight sobre nodo (tipos: SELECCIONADO, ADYACENTE, CONECTADO, AISLADO, EXITO, ERROR).
  - `mostrarLabel(nombre, texto, tipo)` — Etiqueta flotante 3D sobre nodo con color del tipo.
  - `mostrarArista(A, B, tipo, opciones)` — Beam visual falso entre nodos con billboard "ARISTA", partículas direccionales (cyan A→B, rosa B→A), y pulso de grosor.
  - `blink(nombre, tipo, ciclos)` — Parpadeo de highlight N veces.
  - `limpiarTodo()` — Limpia highlights, labels, aristas falsas, blinks y parts temporales.
- **`Feedback_Conexiones.lua`:** Diálogos automáticos de retroalimentación ante errores:
  - `Feedback_ConexionInvalida`: Cuando el jugador intenta conectar nodos no adyacentes.
  - `Feedback_DireccionInvalida`: Cuando el jugador intenta conectar en dirección incorrecta en un dígrafo.

---

## 10. Sistemas de Gameplay del Lado del Cliente (Nuevo)
- **`GestorEfectos.lua` / `ControladorEfectos.client.lua`:** Patrón pub/sub centralizado que evita múltiples conexiones al mismo RemoteEvent. Aplica highlights (cyan selección, dorado adyacente, rojo error) y billboards con nombres amigables de nodos.
- **`ParticulasConexion.client.lua`:** Bolas de luz con `PointLight` y `Trail` que viajan por las aristas. Dirección A→B (cyan) y B→A (rosa) para grafos no dirigidos.
- **`SistemaEnergia.client.lua`:** Apaga **todos** los componentes luminosos (`PointLight`, `SpotLight`, `SurfaceLight`, `Beam`, `ParticleEmitter`, `Neon`) al cargar nivel. Los enciende progresivamente con `Tween` según eventos `ProgresoEnergia` del servidor.
- **`GuiaService.lua`:** Sistema de guía visual con `Beam` texturizado con flechas animadas desde la cabeza del jugador hasta el objetivo. Auto-avance por completitud de zona. Se conecta a `NivelListo`/`NivelDescargado`.
- **`RetroalimentacionConexion.client.lua`:** Feedback visual inmediato al intentar conexiones inválidas. Lanza diálogos de `Feedback_Conexiones` vía `_G.ControladorDialogo.iniciar()`.

---

## 11. Configuración de Audio (Nuevo)
- **`ConfigAudio.lua`:** Configuración centralizada de categorías de audio: Master, Ambiente, BGM, SFX, Victoria. Define IDs de sonidos por nivel y por evento UI.

---

## 12. Sistema de Requisito de Diálogos para 3 Estrellas (Nuevo)
- **`DialogoCorrecto` (RemoteEvent):** Cliente → Servidor. Se dispara cada vez que el jugador responde correctamente una pregunta de diálogo.
- **`Boot.server.lua`:** Mantiene un contador `_dialogosCorrectos[userId]` por jugador. Se reinicia al iniciar/reiniciar nivel. Expone `_G.ObtenerDialogosCorrectos(jugador)` para que otros sistemas lo consulten.
- **`LevelsConfig[nivel].RequiereDialogosCorrectos`:** Campo booleano opcional. Si es `true`, el nivel exige responder todas las preguntas de diálogo correctamente para obtener 3 estrellas.
- **`LevelsConfig[nivel].TotalPreguntasDialogo`:** Número total de preguntas de diálogo en el nivel.
- **`ServicioMisiones.calcularEstrellasHelper()`:** Si `RequiereDialogosCorrectos` es true y el jugador no alcanzó `TotalPreguntasDialogo`, limita las estrellas a 2 máximo (aunque el puntaje supere el umbral de 3 estrellas).
- **`VictoriaHUD.lua`:** Detecta el campo `estrellasLimitadasPorDialogos` en el snapshot de victoria y muestra un mensaje informativo en el subtítulo: *"¡Respondiste algunas preguntas incorrectamente! Vuelve a intentarlo para obtener 3 estrellas."* (color amarillo). Si no aplica, restaura el subtítulo a *"¡Nivel completado!"*.
