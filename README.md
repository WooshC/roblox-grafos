# 🎮 Redes y Caminos - Juego Serio Educativo sobre Grafos

> **Juego educativo desarrollado en Roblox para el aprendizaje interactivo de Teoría de Grafos y Algoritmos**

[![Roblox](https://img.shields.io/badge/Plataforma-Roblox-00A2FF?style=for-the-badge&logo=roblox)](https://www.roblox.com)
[![Lua](https://img.shields.io/badge/Lenguaje-Lua-2C2D72?style=for-the-badge&logo=lua)](https://www.lua.org)
[![Estado](https://img.shields.io/badge/Estado-En%20Desarrollo-yellow?style=for-the-badge)]()

---

## 📖 Historia del Juego

**Carlos** es un joven emprendedor que vive en un pueblo caótico donde los semáforos cambian sin sentido, los cables están mal tendidos y las rutas son ineficientes. La infraestructura eléctrica y de comunicación es un desastre, y el alcalde solo se preocupa por aparentar progreso sin resolver problemas reales.

Cansado de ver cómo el caos afecta la vida diaria, Carlos funda **"Redes y Caminos"**, una empresa dedicada a reorganizar las conexiones del pueblo de forma eficiente, clara y sostenible. El alcalde, presionado por los constantes fallos, contrata a Carlos convencido de que será solo otro parche temporal.

Carlos busca aprendices para ayudarlo en esta transformación. Entre los interesados aparece **Tocino**, un joven curioso pero sin experiencia. Bajo la guía de Carlos, Tocino aprenderá a través de errores y aciertos cómo optimizar redes, encontrar caminos eficientes y resolver problemas algorítmicos reales.

---

## 🎯 Objetivos del Proyecto

### Objetivo General

Desarrollar un juego serio educativo que apoye el aprendizaje de grafos dirigidos y no dirigidos, permitiendo a los estudiantes visualizar y aplicar de forma interactiva algoritmos fundamentales, fortaleciendo su comprensión conceptual y práctica dentro de la asignatura **Estructuras de Datos y Algoritmos**.

### Objetivos Específicos

1. **Analizar** la literatura científica relacionada con juegos serios y casos específicos de su uso en educación.

2. **Diseñar** el juego aplicando un enfoque centrado en el usuario mediante la metodología **iPlus** para las fases de análisis y diseño.

3. **Desarrollar** el proyecto utilizando el marco de trabajo **SCRUM** para lograr una implementación iterativa y adaptativa.

4. **Implementar** niveles educativos que enseñen algoritmos de grafos (BFS, DFS, Dijkstra, Prim/Kruskal, Floyd-Warshall) de forma interactiva y visual.

5. **Evaluar** la funcionalidad y usabilidad del juego mediante pruebas con estudiantes y expertos, obteniendo métricas de satisfacción y aprendizaje.

6. **Publicar** el juego en línea (Roblox) para que esté disponible como recurso educativo complementario para estudiantes y profesores.

7. **Documentar** el proyecto mediante la memoria de tesis, incluyendo decisiones de diseño, resultados de pruebas y sugerencias de evolución futura.

8. **Producir** material de apoyo (video tutorial de instalación, configuración y uso) para facilitar la adopción del juego.

---

## 🎓 Alcance del Proyecto

Este juego serio se ha diseñado para ayudar a estudiantes de ingeniería y computación a construir bases sólidas en el manejo de **grafos dirigidos y no dirigidos** mediante exploración práctica y experimentación en tiempo real.

### ¿Qué ofrece el juego?

#### 🔧 Interacción Práctica
- **Crear y modificar grafos libremente**: Conectar nodos (postes), crear aristas (cables) y observar cómo cambian las propiedades del grafo al instante.
- **Gestión de recursos**: Presupuesto limitado que obliga a tomar decisiones estratégicas sobre qué conexiones hacer.
- **Retroalimentación inmediata**: Mensajes e indicadores que explican aciertos y errores en el momento de la práctica.

#### 📊 Visualización de Algoritmos
- **Ver dentro de los algoritmos**: Observar paso a paso cómo funcionan BFS, DFS y Dijkstra.
- **Animaciones educativas**: Cables fantasma que muestran la exploración del algoritmo, colores que indican el estado de cada nodo, y etiquetas con distancias.
- **Comparación de algoritmos**: Entender las diferencias entre búsqueda en amplitud (BFS) y caminos mínimos (Dijkstra).

#### 🎮 Aprendizaje Gamificado
- **Misiones progresivas**: Sistema de objetivos que guía el aprendizaje de forma estructurada.
- **Niveles de dificultad creciente**: Desde conceptos básicos hasta problemas complejos de optimización.
- **Modo mapa**: Vista aérea que facilita la planificación y comprensión de la red completa.

### Limitaciones y Enfoque

**Este juego NO pretende:**
- Reemplazar las clases teóricas de Estructuras de Datos
- Ser un simulador profesional de redes eléctricas
- Cubrir todos los algoritmos de grafos existentes

**Este juego SÍ pretende:**
- Ser un **complemento práctico** a la teoría vista en clase
- Hacer los conceptos abstractos **visibles y manipulables**
- Fomentar el **aprendizaje autónomo** mediante experimentación
- Proporcionar un entorno **seguro para cometer errores** y aprender de ellos

---

## 🗺️ Mundos y Niveles del Juego

### Nivel 0: El Taller de Operaciones (Tutorial) ✅ **IMPLEMENTADO**

**Concepto:** Introducción a los conceptos básicos de grafos.

**Objetivos de Aprendizaje:**
- Comprender qué es un **nodo** (poste) y una **arista** (cable)
- Entender el concepto de **grafo conectado**
- Aprender sobre **pesos** (distancias) en las aristas
- Distinguir entre **circuito abierto** y **circuito cerrado**

**Mecánicas Implementadas:**
- ✅ Conexión manual de cables entre postes
- ✅ Sistema de costos (presupuesto limitado)
- ✅ Cálculo automático de distancias
- ✅ Propagación de energía en tiempo real
- ✅ Sistema de misiones progresivas (3 misiones)
- ✅ Visualización de BFS con cables fantasma
- ✅ Modo mapa con vista aérea
- ✅ Indicadores visuales de nodos energizados

**Algoritmo Principal:** BFS (Búsqueda en Amplitud)

**Estado Actual:** 🟢 **Funcional y completo**

---

### Nivel 1: El Barrio Laberíntico 🚧 **PLANIFICADO**

**Concepto:** Algoritmos de recorrido (BFS / DFS)

**Objetivos de Aprendizaje:**
- Diferenciar entre **BFS** (amplitud) y **DFS** (profundidad)
- Entender cuándo usar cada algoritmo
- Comprender el concepto de **visitado** vs **no visitado**
- Aplicar recorridos para **mapear** una red completa

**Mecánicas Propuestas:**
- 🔲 Barrio con callejones sin salida
- 🔲 Cableado cortado en múltiples puntos
- 🔲 Misión: Visitar TODOS los nodos para mapear el daño
- 🔲 Comparación visual entre BFS y DFS
- 🔲 Métricas: Número de pasos, orden de visita

**Algoritmos:** BFS y DFS

**Estado:** 📋 Diseñado, pendiente de implementación

---

### Nivel 2: La Avenida del Presupuesto 🚧 **PLANIFICADO**

**Concepto:** Árboles de Expansión Mínima (MST)

**Objetivos de Aprendizaje:**
- Comprender qué es un **Árbol de Expansión Mínima**
- Diferenciar entre **Prim** y **Kruskal**
- Optimizar costos evitando **ciclos innecesarios**
- Entender el concepto de **conectividad mínima**

**Mecánicas Propuestas:**
- 🔲 Nueva urbanización sin electricidad
- 🔲 Presupuesto muy limitado
- 🔲 Misión: Conectar TODOS los edificios con el menor costo
- 🔲 Visualización de ciclos detectados
- 🔲 Comparación de costo: Solución del jugador vs MST óptimo

**Algoritmos:** Prim y Kruskal

**Estado:** 📋 Diseñado, pendiente de implementación

---

### Nivel 3: El Distrito de Emergencias 🚧 **PLANIFICADO**

**Concepto:** Caminos Mínimos (Dijkstra)

**Objetivos de Aprendizaje:**
- Encontrar el **camino más corto** entre dos puntos
- Comprender la **relajación de aristas**
- Diferenciar entre "corto visualmente" y "corto en costo"
- Aplicar Dijkstra en situaciones de emergencia

**Mecánicas Propuestas:**
- 🔲 Hospital sin energía (emergencia)
- 🔲 Planta eléctrica como origen
- 🔲 Misión: Encontrar la ruta MÁS RÁPIDA
- 🔲 Visualización de distancias acumuladas
- 🔲 Comparación con rutas alternativas

**Algoritmo:** Dijkstra

**Estado:** 📋 Diseñado, pendiente de implementación

---

### Nivel 4: La Plaza de Planificación Central 🚧 **PLANIFICADO**

**Concepto:** Caminos de Todos los Pares (Floyd-Warshall)

**Objetivos de Aprendizaje:**
- Calcular caminos mínimos entre **todos los pares** de nodos
- Comprender la **matriz de distancias**
- Optimizar una red completa
- Entender cómo mejorar un camino intermedio beneficia a toda la red

**Mecánicas Propuestas:**
- 🔲 Rediseño total del transporte del pueblo
- 🔲 Múltiples edificios importantes
- 🔲 Misión: Optimizar TODAS las rutas posibles
- 🔲 Visualización de matriz de distancias
- 🔲 Heatmap de eficiencia de rutas

**Algoritmo:** Floyd-Warshall

**Estado:** 📋 Diseñado, pendiente de implementación

---

## 🏗️ Arquitectura del Proyecto

### Estructura de Carpetas

```
roblox-grafos/
├── ReplicatedStorage/
│   ├── LevelsConfig.lua          # Configuración de todos los niveles
│   ├── Algoritmos.lua             # Implementación de Dijkstra
│   └── Utilidades/
│       ├── NivelUtils.lua         # Funciones compartidas de niveles
│       └── MisionManager.lua      # Sistema de misiones
│
├── ServerScriptService/
│   ├── Base_Datos/
│   │   └── ManagerData.lua        # Gestión de datos y spawn
│   └── Gameplay/
│       ├── ConectarCables.server.lua      # Lógica de conexión manual
│       ├── GameplayEvents.server.lua      # Propagación de energía (BFS)
│       ├── VisualizadorAlgoritmos.server.lua  # Visualización de algoritmos
│       └── SistemaUI_reinicio.server.lua  # Reinicio de niveles
│
├── StarterPlayer/
│   └── StarterPlayerScripts/
│       └── ClienteUI.client.lua   # Interfaz de usuario (mapa, misiones, botones)
│
└── Workspace/
    ├── Nivel0_Tutorial/           # Modelo del nivel tutorial
    │   ├── Objetos/Postes/        # Nodos del grafo
    │   ├── Zona_luz/              # Elementos que se iluminan
    │   ├── Techos/                # Techos que se ocultan en modo mapa
    │   └── SpawnLocation          # Punto de aparición
    └── [Niveles futuros...]
```

### Módulos Principales

#### 🎮 Cliente (StarterPlayerScripts)
- **ClienteUI.client.lua**: Interfaz completa del jugador
  - Modo mapa con vista aérea
  - Panel de misiones
  - Botones de control (Reiniciar, Mapa, Algoritmo, Misiones)
  - Visualización de nodos energizados

#### 🖥️ Servidor (ServerScriptService)

**Gameplay:**
- **ConectarCables**: Lógica de conexión manual de cables
  - Validación de adyacencias
  - Cálculo de costos
  - Gestión de presupuesto

- **GameplayEvents**: Propagación de energía
  - BFS en tiempo real (instantáneo)
  - BFS con visualización (lento, educativo)
  - Actualización de luces
  - Cables fantasma para demostración

- **VisualizadorAlgoritmos**: Visualización de Dijkstra
  - Animación paso a paso
  - Cables fantasma
  - Etiquetas de distancia

**Datos:**
- **ManagerData**: Gestión de jugadores
  - Sistema de spawn
  - Datos persistentes
  - Teletransporte entre niveles

#### 🔧 Utilidades (ReplicatedStorage)

- **NivelUtils**: Funciones compartidas
  - Búsqueda de postes y cables
  - Validaciones de nivel
  - Cache de rendimiento

- **MisionManager**: Sistema de misiones
  - Estado por jugador
  - Actualización incremental
  - Eventos de progreso

- **LevelsConfig**: Configuración centralizada
  - Adyacencias del grafo
  - Misiones por nivel
  - Parámetros de dificultad

---

## 🎨 Características Implementadas

### ✅ Sistema de Conexión Manual
- Click en postes para seleccionar
- Conexión de cables con validación de adyacencias
- Cálculo automático de distancias (studs → metros)
- Sistema de costos por metro
- Desconexión con reembolso

### ✅ Propagación de Energía
- **Modo Normal**: Instantáneo (al conectar cables)
- **Modo Visualización**: Lento (1 seg/nodo) para aprendizaje
- Actualización de luces en tiempo real
- Indicadores visuales de nodos energizados

### ✅ Sistema de Misiones
- 3 misiones progresivas por nivel
- Actualización en tiempo real
- Estado persistente (se mantiene al cerrar/abrir mapa)
- Indicadores visuales (✅ completada)

### ✅ Modo Mapa
- Vista aérea con cámara fija
- Zoom bloqueado para evitar crashes
- Etiquetas de nodos con nombres personalizados
- Indicadores de distancia al jugador
- Colores según estado (energizado/sin energía/inicio)
- Techos transparentes para mejor visibilidad

### ✅ Visualización de Algoritmos
- **BFS**: Cables fantasma que muestran exploración nivel por nivel
- **Dijkstra**: Animación de exploración + camino óptimo
- Etiquetas con distancias
- Colores diferenciados (exploración vs camino final)

### ✅ Sistema de UI
- Botones: Reiniciar, Mapa, Algoritmo, Misiones
- Panel de misiones independiente
- Indicadores de dinero y nivel
- Mensajes de feedback

---

## 🛠️ Tecnologías Utilizadas

- **Plataforma**: Roblox Studio
- **Lenguaje**: Lua 5.1
- **Arquitectura**: Cliente-Servidor
- **Metodología**: SCRUM (sprints iterativos)
- **Diseño**: iPlus (centrado en el usuario)

---

## 📊 Estado Actual del Proyecto

### Nivel 0 (Tutorial): 🟢 **95% Completo**

#### ✅ Implementado
- [x] Grafo con 5 nodos (Generador, Torre 1-3, Torre Control)
- [x] Sistema de conexión manual de cables
- [x] Propagación de energía (BFS)
- [x] Sistema de misiones (3 misiones)
- [x] Visualización de BFS con cables fantasma
- [x] Modo mapa con vista aérea
- [x] Sistema de costos y presupuesto
- [x] Indicadores visuales de energía
- [x] Panel de misiones independiente
- [x] Botón de reinicio
- [x] Documentación de algoritmos

#### 🚧 Pendiente
- [ ] Indicador visual de energía en postes (sin modo mapa)
- [ ] Tutorial interactivo paso a paso
- [ ] Diálogos con Carlos (NPC)
- [ ] Animaciones de feedback al completar misiones
- [ ] Sonidos de feedback

### Niveles 1-4: 📋 **Diseñados, 0% Implementados**

---

## 🎯 Roadmap de Desarrollo

### Sprint Actual: Nivel 0 - Pulido Final
- [ ] Agregar indicadores visuales de energía (BillboardGui en postes)
- [ ] Implementar tutorial interactivo
- [ ] Agregar NPC Carlos con diálogos
- [ ] Sonidos y efectos visuales
- [ ] Pruebas de usabilidad con estudiantes

### Sprint 2: Nivel 1 - Barrio Laberíntico
- [ ] Diseñar mapa del barrio
- [ ] Implementar DFS
- [ ] Comparación visual BFS vs DFS
- [ ] Sistema de "nodos dañados"
- [ ] Misiones de mapeo completo

### Sprint 3: Nivel 2 - Avenida del Presupuesto
- [ ] Implementar algoritmo de Prim
- [ ] Implementar algoritmo de Kruskal
- [ ] Detección de ciclos
- [ ] Visualización de MST
- [ ] Comparación de costos

### Sprint 4: Nivel 3 - Distrito de Emergencias
- [ ] Mejorar visualización de Dijkstra
- [ ] Sistema de emergencias (tiempo límite)
- [ ] Comparación de rutas
- [ ] Métricas de eficiencia

### Sprint 5: Nivel 4 - Plaza Central
- [ ] Implementar Floyd-Warshall
- [ ] Matriz de distancias visual
- [ ] Heatmap de eficiencia
- [ ] Optimización global

### Sprint 6: Evaluación y Publicación
- [ ] Pruebas con estudiantes
- [ ] Encuestas de usabilidad
- [ ] Ajustes basados en feedback
- [ ] Publicación en Roblox
- [ ] Video tutorial
- [ ] Documentación final

---

## 📚 Documentación Adicional

- [Guía de Diseño de Niveles](.agent/Guia_Diseño.md)
- [Documentación de Algoritmos BFS y Dijkstra](.agent/Algoritmos_BFS_Dijkstra.md)
- [Resumen de Mejoras Implementadas](.agent/RESUMEN_FINAL.md)

---

## 👥 Equipo de Desarrollo

**Desarrollador Principal**: [Tu Nombre]
**Rol**: Diseño, Programación, Testing
**Institución**: [Tu Universidad]
**Asignatura**: Estructuras de Datos y Algoritmos

---

## 📄 Licencia

Este proyecto es parte de una tesis de grado y está disponible con fines educativos.

---

## 🙏 Agradecimientos

- A los estudiantes que participaron en las pruebas de usabilidad
- A los profesores que brindaron feedback sobre el diseño pedagógico
- A la comunidad de Roblox por los recursos y documentación

---

**Última actualización**: Enero 2026
**Versión**: 0.9 (Nivel 0 casi completo)
