# Plan Estético y Educativo: Nivel 1 — El Barrio Antiguo (La Ferroviaria)

Este documento es el **Plan Base** para crear la estética y la estructura educativa del Nivel 1. El objetivo principal es usar la planicie del Barrio Antiguo (un sector periférico inspirado en La Ferroviaria/Quitumbe, completamente llano sin montañas ni elevaciones) para enseñar el algoritmo **BFS (Breadth-First Search)** mediante el Módulo de Análisis HUD.

---

## 1. La Narrativa y el Problema

**El Encargo Real:**
La campaña sigue el crecimiento de Tocino dentro de la empresa eléctrica, enfrentando el desorden dejado por el alcalde. En el Barrio Antiguo, los vecinos se quejan de que la luz va y viene misteriosamente. El alcalde asegura que "todo el barrio está electrificado", pero miente. Debido al cableado negligente, hay manzanas enteras desconectadas.

**El Desafío (Cobertura por Zonas y Conectividad Global):**
No buscamos la ruta más rápida a un solo destino, nuestro objetivo es **Cobertura y Conectividad**. Tocino debe identificar qué casas están desconectadas (nodos aislados) usando su Analizador y luego "tender cables" en el mundo 3D para integrarlas a la red principal.

*Algoritmo (BFS)*: Para comprender cómo fluye teóricamente la luz en el grafo que acaban de reparar (o que van a reparar), el jugador usa el **Panel de Análisis**. Visualmente en la HUD, verá el pseudocódigo ejecutándose y cómo BFS explora los nodos vecinos **capa por capa**. 

*Victoria*: Si el jugador conecta correctamente todas las aristas exigidas, forma el Grafo Conexo y completa el nivel. 
*Derrota o Advertencia Visual*: Si analizan la red sin repararla primero, el BFS se detendrá prematuramente al vaciar su cola, revelando en la interfaz la existencia de Nodos/Componentes Aislados.

---

## 2. Refuerzo de Conceptos y "Puntos por Sabiduría"

A lo largo del nivel, Carlos lanzará preguntas didácticas. Responder correctamente da **+100 Puntos**.

Temas a reforzar:
- ¿Cómo explora el algoritmo BFS la cola? (En Anillos/Capas procesando todos los vecinos inmediatos primero).
- ¿Qué ventaja nos garantiza una red plana analizada por BFS? (Hallar las rutas mínimas usando el menor número de saltos/postes).
- ¿Qué significa que el algoritmo vacíe su cola y deje nodos sin visitar? (Existencia de Nodos y Componentes Aislados).
- ¿Qué se logra al conectar físicamente a todos sin dejar nodos aislados? (Un Grafo 100% Conexo global).

---

## 3. Plan Estético: Las 4 Zonas del Barrio (Totalmente Planas)

### Zona 1: La Estación Plana (Centro de Distribución)
- **Concepto BFS:** Expansión Capa por Capa (Cola FIFO).
- **Mecánica:** El jugador estudia el Analizador viendo cómo BFS encola el Generador Principal y expande a sus vecinos inmediatos, capa a capa.
- **Narrativa:** "El alcalde jura que todo funciona. Abre el panel Analizador para ver cómo BFS realmente procesa la red y revélalo."

### Zona 2: El Mercado Central
- **Concepto BFS:** Distancia Mínima en Saltos.
- **Mecánica:** El jugador entiende en el Analizador que BFS llega a cada nodo por la menor cantidad posible de postes atravesados.
- **Narrativa:** "Al expandirse en capas organizadas, BFS siempre descubrirá el camino a cada puesto del mercado que requiera atravesar la menor cantidad de postes."

### Zona 3: Las Canchas Barriales
- **Concepto BFS:** Nodos y Subgrafos Aislados.
- **Mecánica:** Al estudiar la red actual en el HUD, BFS procesará media zona y agotará su cola abruptamente, dejando nodos oscuros de las Canchas sin indexar.
- **Narrativa:** "¡El alcalde mintió! El algoritmo de exploración terminó, pero estas casas quedaron fuera. Hemos hallado un Componente Aislado por falta de cableado."

### Zona 4: Parque del Barrio
- **Concepto BFS:** Grafo Conexo Completo.
- **Mecánica:** Al tender los puentes faltantes en el mapa 3D y lograr el objetivo del sistema, el último chequeo garantizará que el 100% del mapa nivelado está interconectado en un Grafo Conexo.
- **Narrativa:** "Logramos la conectividad total. Al reparar las conexiones formamos un Grafo Conexo. ¡Victoria!"

---

## 4. Estructura Requerida en Studio (`ServerStorage/Niveles/Nivel1`)

```text
Nivel1/
├── Escenario/ (Mallas 3D del Barrio, terrenos planos sin pendientes)
├── Grafos/
│   └── Grafo_Barrio/
│       ├── Conexiones/ (Cables iniciales vacíos en zonas críticas a reparar)
│       ├── Meta/ (Activo=true)
│       └── Nodos/ 
│           ├── Generador Principal / Casa Estación 1 / Casa Estación 2
│           ├── Poste del Mercado / Puesto del Mercado
│           ├── Poste de las Canchas / Casa de las Canchas
│           └── Poste del Parque / Casa del Parque 1 / Casa del Parque 2
└── Zonas/
    └── Triggers/
        ├── ZonaTrigger_Bulevar (Estación)
        ├── ZonaTrigger_Ronda (Mercado)
        ├── ZonaTrigger_SantoDomingo (Canchas)
        └── ZonaTrigger_Panecillo (Parque)
```

*(Nota de Sistema: Los scripts y nombres base de los GameObjects como triggers o archivos de diálogo se han preservado con sus nombres de iteraciones pasadas (Bulevar, Panecillo, etc.) por estabilidad, sin embargo los nombres mostrados en GUI y mecánicas corresponden a La Ferroviaria/Barrio Antiguo y al análisis educativo.)*
