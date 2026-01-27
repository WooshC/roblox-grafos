# 📄 Problemática y Propuesta de Solución

## 🌟 PROPUESTA GENERAL

La propuesta consiste en el diseño, desarrollo y validación de un **juego serio educativo en la plataforma Roblox**, orientado a transformar la enseñanza de la **Teoría de Grafos** en una experiencia inmersiva y gamificada.

Este proyecto plantea una solución tecnológica accesible vía web que permite a los estudiantes de **Estructuras de Datos** simular, construir y manipular interactivamente **grafos dirigidos y no dirigidos**. A través de un entorno 3D, los alumnos podrán visualizar en tiempo real y **paso a paso** la ejecución de algortimos fundamentales: de recorrido (**BFS**), de rutas óptimas (**Dijkstra**) y de árboles de expansión mínima (**Prim**).

La iniciativa se fundamenta en dos pilares metodológicos: **iPlus** (Diseño Centrado en el Usuario) para asegurar que la interfaz y las mecánicas respondan a las necesidades pedagógicas reales, y **SCRUM** para un desarrollo ágil e incremental. El resultado final será una herramienta de acceso libre, validada empíricamente con estudiantes, que busca fortalecer el **razonamiento lógico-matemático** y reducir la barrera de abstracción inherente a estos temas complejos.

---

## 1. Planteamiento del Problema

La asignatura de **Estructuras de Datos** es fundamental en la formación de ingenieros de software, pero presenta desafíos significativos en su enseñanza y aprendizaje, específicamente en el tema de la **Teoría de Grafos**:

*   **Abstracción Conceptual:** Los conceptos de grafos (nodos, aristas, peso, dirección) y sus algoritmos asociados (recorridos, rutas óptimas) son altamente abstractos. Los estudiantes a menudo tienen dificultades para visualizar cómo operan estos algoritmos internamente paso a paso.
*   **Limitaciones de Métodos Tradicionales:** La enseñanza tradicional basada en pizarrón, diapositivas estáticas o trazas manuales en papel resulta insuficiente para capturar la naturaleza dinámica e iterativa de algoritmos como BFS, Dijkstra o Prim. No permite una experimentación "en vivo" donde el estudiante pueda ver las consecuencias inmediatas de modificar un grafo.
*   **Brecha Generacional en Herramientas:** A pesar de que los estudiantes actuales son nativos digitales, las herramientas educativas a menudo no aprovechan los entornos interactivos y lúdicos con los que están familiarizados, desaprovechando oportunidades para aumentar la motivación y el compromiso (engagement).
*   **Falta de Contextualización Práctica:** A menudo se enseñan los algoritmos como recetas matemáticas sin una conexión clara con problemas reales (como redes de telecomunicaciones o mapas), dificultando que el estudiante desarrolle un verdadero **razonamiento lógico-matemático** aplicado.

**En resumen:** Existe una carencia de herramientas interactivas modernas que permitan la visualización dinámica y la experimentación activa con grafos dirigidos/no dirigidos y sus algoritmos, lo que dificulta la comprensión profunda y desmotiva al estudiante.

---

## 2. Detalle de la Solución

Para abordar esta problemática, se detalla el desarrollo de la solución con los siguientes componentes clave:

### 💡 Componentes de la Propuesta

1.  **Entorno de Simulación Interactivo (Roblox):**
    *   Se utilizará Roblox Studio para crear un entorno 3D donde los conceptos abstractos se "tangibilizan": los nodos son postes/estructuras físicas, las aristas son cables o conexiones visibles, y los pesos se representan visualmente (longitud, costo).
    *   Este entorno permite la manipulación directa: el estudiante puede crear, conectar y modificar grafos **dirigidos y no dirigidos** en tiempo real.

2.  **Visualización Algorítmica Paso a Paso:**
    *   La herramienta no solo dará el resultado final, sino que **ejecutará visualmente** los algoritmos clave:
        *   **BFS (Recorrido):** Mostrará la onda de expansión nivel por nivel.
        *   **Dijkstra (Rutas Óptimas):** Visualizará la relajación de aristas y la selección de caminos de menor costo.
        *   **Prim (Árbol de Expansión Mínima):** Mostrará la construcción progresiva de la red más eficiente.

3.  **Metodología de Diseño Centrada en el Usuario (iPlus):**
    *   A diferencia de un software educativo genérico, esta propuesta se diseñará aplicando la metodología **iPlus**, asegurando que la interfaz y las mecánicas de juego respondan a las necesidades reales de aprendizaje y usabilidad detectadas en los estudiantes durante la fase de análisis.

4.  **Enfoque de Desarrollo Ágil (SCRUM):**
    *   El desarrollo se realizará en iteraciones (Sprints) que permitirán tener versiones funcionales incrementales, asegurando que se cubran tanto los aspectos técnicos complejos (grafos dirigidos, optimización) como los educativos.

5.  **Validación Empírica:**
    *   La propuesta incluye una **fase de evaluación formal** con estudiantes para medir no solo la usabilidad (SUS) sino también el impacto en la satisfacción y la percepción de aprendizaje, proporcionando evidencia académica de la efectividad de la herramienta.

### 🎯 Valor Diferencial
Esta propuesta transforma el aprendizaje pasivo de estructuras de datos en una **experiencia activa y lúdica**, donde el estudiante "juega" a construir y optimizar redes, fortaleciendo su razonamiento lógico-matemático de manera intuitiva antes de enfrentarse a la implementación en código puro.
