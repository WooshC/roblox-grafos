# Guía de Creación: Nivel 1 — El Barrio de las Sombras (BFS y Conectividad)

Esta guía detalla cómo configurar el **Nivel 1** en Roblox Studio. El objetivo es enseñar el algoritmo **BFS (Breadth-First Search)** y el concepto de **Conectividad** mediante una narrativa de restauración eléctrica.

---

## 1. Conceptos Educativos (Lo que el jugador aprenderá)

### A. Algoritmo BFS (Breadth-First Search)
En este nivel, el BFS es el **"Pulso de Energía"**. 
- **Mecánica**: El pulso comienza en un nodo (Generador) y se expande a todos sus vecinos directos simultáneamente (Nivel 1), luego a los vecinos de esos vecinos (Nivel 2), y así sucesivamente.
- **Visualización**: El jugador verá cómo la luz "viaja" por los cables nivel por nivel.

### B. Conectividad y Componentes
- **Grafo Conexo**: Un sistema donde existe un camino entre cualquier par de nodos. El objetivo final es que el barrio sea un grafo conexo.
- **Nodos Aislados**: Casas que no tienen cables. El BFS no puede alcanzarlas.
- **Componentes Conexas**: Grupos de casas que están conectadas entre sí pero separadas del resto del barrio. El jugador debe usar cables para "unir" estas islas al generador.

---

## 2. Estructura de Zonas y Exploración

El nivel se divide en tres sectores progresivos:

### Sector 1: El Centro del Barrio (`Zona_Generador`)
- **Ubicación**: Donde se encuentra el `Generador Central`.
- **Objetivo**: Conectar las primeras casas (`Casa_A`, `Casa_B`, `Casa_C`) para entender el flujo básico.
- **Nodos Clave**: `Generador`, `Casa_A`, `Casa_B`, `Casa_C`.

### Sector 2: El Puente Eléctrico (`Zona_Calle`)
- **Ubicación**: Una calle larga que une el centro con la zona alejada.
- **Objetivo**: Crear un camino crítico usando un poste intermedio. Sin este poste, la energía no puede cruzar.
- **Nodos Clave**: `Poste_Calle`.

### Sector 3: La Periferia (`Zona_Periferia`)
- **Ubicación**: El sector más alejado y oscuro.
- **Objetivo**: Identificar que las casas de este sector forman una "isla" (componente aislada) y tender un cable desde la Calle Principal para integrarlas.
- **Nodos Clave**: `Casa_D`, `Casa_E`, `Casa_F` (Casa del Alcalde).

---

## 3. Jerarquía en Roblox Studio (`ServerStorage`)

```
Nivel1/
├── Escenario/
│   ├── Suelo_Barrio (BasePart)
│   └── Decoracion_Casas/ (Folder con modelos visuales)
├── Grafos/
│   └── Grafo_Barrio/
│       ├── Conexiones/ (Folder vacío)
│       ├── Meta/ (Activo=true, GrafoID="Grafo_Barrio")
│       └── Nodos/ 
│           ├── Generador/
│           ├── Casa_A/ ... Casa_C/
│           ├── Poste_Calle/
│           └── Casa_D/ ... Casa_F/
├── Zonas/
│   └── Triggers/
│       ├── ZonaTrigger_Generador (BasePart)
│       ├── ZonaTrigger_Calle (BasePart)
│       └── ZonaTrigger_Periferia (BasePart)
└── SpawnLocation
```

---

## 4. Configuración de Misiones (`LevelsConfig.lua`)

Las misiones guían al jugador de forma didáctica:
1.  **Misión 101**: Familiarización con el nodo raíz (Generador).
2.  **Misión 102**: Primera conexión (Arista).
3.  **Misión 103**: Extensión de red (Cruzar el puente).
4.  **Misión 104**: Exploración de nodos aislados (Casa del Alcalde).
5.  **Misión 105**: **Objetivo Final BFS**: Lograr que el grafo sea conexo.

---

## 5. Gameplay y Feedback

1.  **Detección de Fallas**: Si el jugador lanza un BFS y el pulso se detiene en `Casa_B`, Carlos le dirá que la energía no puede saltar al poste sin un cable.
2.  **Victoria**: Al completar la última conexión, el BFS iluminará la `Casa_F`, disparando la pantalla de victoria.

> [!IMPORTANT]
> Los nombres de los nodos en Studio DEBEN coincidir exactamente con los nombres en `LevelsConfig.lua` y en los archivos de diálogo (`Nivel1_Intro`, `Nivel1_Calle`, `Nivel1_Periferia`) para su correcto funcionamiento.
