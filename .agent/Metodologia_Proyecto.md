# 🛠️ Metodología del Proyecto

Para garantizar el éxito tanto en la calidad educativa como en el desarrollo técnico del juego serio, este proyecto implementa un enfoque **híbrido** que combina una metodología de diseño centrado en el usuario (**iPlus**) con un marco de trabajo ágil de desarrollo de software (**SCRUM**).

---

## 1. Metodología de Diseño: iPlus
**Enfoque:** Centrado en el Usuario (User-Centered Design).
**Objetivo:** Asegurar que el juego resuelva las necesidades reales de aprendizaje y sea usable para los estudiantes.

La metodología iPlus se aplica en las fases iniciales y de validación del proyecto, estructurándose en las siguientes etapas iterativas:

### 🔍 Fase 1: Investigación (Analysis)
En esta etapa se busca comprender el contexto y al usuario final.
*   **Actividades:**
    *   Revisión de literatura sobre didáctica de grafos.
    *   Entrevistas con estudiantes para identificar sus "puntos de dolor" al aprender BFS, Dijkstra y Prim.
    *   Definición de *User Personas* (ej. "El estudiante visual", "El estudiante lógico").
*   **Entregable:** Documento de Requisitos de Usuario y Matriz de Necesidades Educativas.

### 🎨 Fase 2: Ideación y Diseño (Design)
Se traducen los requisitos en soluciones visuales y mecánicas de juego.
*   **Actividades:**
    *   Diseño de flujos de usuario (User Journeys): ¿Cómo interactúa el estudiante desde que entra al juego hasta que completa un algoritmo?
    *   Creación de **Wireframes** de la interfaz de usuario (UI).
    *   Diseño de mecánicas en papel (Paper Prototyping) antes de programar.
*   **Entregable:** Prototipos de baja fidelidad y Guía de Estilo Visual.

### 🧪 Fase 3: Prototipado y Evaluación (Prototyping & User)
Ciclo de construcción rápida y validación.
*   **Actividades:**
    *   Desarrollo de prototipos funcionales (Grey box) en Roblox.
    *   Sesiones de prueba con usuarios reales (estudiantes) para validar la usabilidad.
    *   Evaluación mediante escala **SUS (System Usability Scale)**.
*   **Entregable:** Reportes de feedback y lista de mejoras para el siguiente ciclo.

---

## 2. Metodología de Desarrollo: SCRUM
**Enfoque:** Ágil / Iterativo e Incremental.
**Objetivo:** Gestionar la complejidad técnica y asegurar entregas funcionales constantes en el plazo de 4 meses.

El desarrollo técnico se organiza en **Sprints de 2 semanas**, permitiendo adaptar el producto a medida que se descubren nuevos desafíos técnicos (como la implementación de grafos dirigidos o el algoritmo de Prim).

### 👥 Roles Adaptados
*   **Product Owner (Profesor Guía / Tesista):** Define la visión del producto y prioriza las historias de usuario (ej. "Como estudiante, quiero ver cuánto cuesta conectar dos nodos").
*   **Scrum Master & Development Team (Tesista):** Encargado de la implementación técnica, aseguramiento de calidad y gestión de impedimentos.

### ⏱️ Ciclo del Sprint (2 Semanas)
1.  **Sprint Planning:** Selección de tareas del *Product Backlog* (Pila del Producto) para las próximas 2 semanas.
2.  **Ejecución:** Desarrollo de código (Scripting Lua), construcción de mapas y diseño de UI.
3.  **Daily Stand-up (Personal):** Revisión diaria de progreso: ¿Qué hice ayer? ¿Qué haré hoy? ¿Qué me bloquea?
4.  **Sprint Review:** Demostración del incremento funcional (ej. "El algoritmo Dijkstra ya calcula la ruta más corta, aunque aún no tiene efectos visuales finales").
5.  **Sprint Retrospective:** Análisis de mejoras en el proceso de trabajo.

### 📝 Artefactos Principales
*   **Product Backlog:** Lista maestra de todas las funcionalidades deseadas (Algoritmos, Niveles, UI, Sonidos).
*   **Sprint Backlog:** Tareas específicas comprometidas para el sprint actual.
*   **Incremento:** Versión jugable del juego al final de cada sprint.

---

## 🔄 Integración de Metodologías

| Aspecto | iPlus (Diseño) | SCRUM (Desarrollo) | Sinergia |
| :--- | :--- | :--- | :--- |
| **Foco** | ¿Qué necesitan los estudiantes? | ¿Cómo lo construimos eficientemente? | iPlus define el "Qué", SCRUM resuelve el "Cómo". |
| **Iteración** | Prototipos y Feedback | Sprints y Código funcional | El feedback de iPlus alimenta el Backlog de SCRUM. |
| **Usuario** | Participa en entrevistas y pruebas | Recibe incrementos de software | El estudiante valida cada incremento generado en los Sprints. |

Esta combinación asegura que no solo se construya el juego correctamente (calidad técnica), sino que se construya el juego correcto para el aprendizaje (calidad pedagógica).
