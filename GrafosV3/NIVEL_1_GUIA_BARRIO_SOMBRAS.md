# Plan Estético y Educativo: Nivel 1 — El Barrio de las Sombras (Centro Histórico de Quito)

Este documento es el **Plan Base** para crear la estética y la estructura educativa del Nivel 1. El objetivo principal es usar la arquitectura del Centro Histórico de Quito para enseñar el algoritmo **BFS (Breadth-First Search)** aplicado a **Subgrafos (Zonas)**, y su relación con el concepto de un **Grafo Conexo Global**.

---

## 1. La Narrativa y el Problema

**El Encargo Real:**
Los vecinos del Centro Histórico están a oscuras. Debido al cableado antiguo, el sistema eléctrico se ha fragmentado en sectores aislados. El alcalde jura que "la red principal funciona", pero miente.

**El Desafío (Cobertura por Zonas y Conectividad Global):**
La electricidad en Quito funciona por distritos (Zonas). Tu misión es reparar el cableado de forma local, zona por zona, asegurando que cada sector reciba energía. 
Sin embargo, arreglar un sector no sirve si no está enlazado a la red principal. Por tanto, el jugador actúa como un técnico que verifica mediante BFS la cobertura local de cada **Subgrafo** (su zona actual), y debe crear "conexiones puente" entre sectores para que la energía fluya hacia la siguiente zona.

Al encender la última zona en El Panecillo, habrás logrado que todos los subgrafos se unan en un único **Grafo Conexo**, donde el 100% de la ciudad está interconectada.

---

## 2. Refuerzo de Conceptos y "Puntos por Sabiduría"

A lo largo del nivel, Carlos lanzará **Preguntas de Validación** didácticas sobre conectividad. Responder estas preguntas correctamente recompensará al jugador con **+100 Puntos**.

Temas a reforzar:
- ¿Qué significa explorar los niveles de un BFS localmente?
- ¿Cómo actúa un "nodo puente" entre dos subgrafos?
- ¿Qué es un Componente Aislado en la perspectiva de una zona entera?
- Si unimos todos los subgrafos, ¿qué obtenemos? (Un Grafo Conexo).

---

## 3. Plan Estético: Las 4 Zonas de Quito y BFS Local

A continuación, la división en 4 zonas clave. El modo análisis y las luces se activan de forma local e independiente conforme resuelves cada sector:

### Zona 1: Bulevar 24 de Mayo (`Zona_Bulevar`)
- **Estética:** Adoquines anchos, bancas coloniales, faroles de suelo.
- **Análisis BFS:** Inicia en el Transformador del Bulevar. El pulso revisa únicamente la cobertura del subgrafo central (Nivel 1 y Nivel 2 locales).
- **Mecánica y Luz:** Al conectar "Museo de la Ciudad", se ilumina toda la *CarpetaLuz* del Bulevar.
- **Narrativa:** "Este es nuestro corazón eléctrico. Aquí aprendemos a mapear los vecinos directos".

### Zona 2: Calle La Ronda (`Zona_Ronda`)
- **Estética:** Calle estrecha y empedrada, balcones de madera llenos de geranios, faroles anclados a la pared.
- **Análisis BFS:** Se inicia en el "Poste La Ronda". El pulso verifica que la estrecha calle esté cubierta de extremo a extremo.
- **Mecánica y Luz:** Se debe crear una arista puente desde el Bulevar hacia La Ronda. Al completarla, la zona romántica se enciende.
- **Narrativa:** "Para que este sector reciba luz, la energía debe heredar el pulso cruzando desde el Bulevar a través de un nodo puente. BFS nos mostrará si la calle entera tiene cobertura local".

### Zona 3: Plaza de Santo Domingo (`Zona_SantoDomingo`)
- **Estética:** Plaza abierta, monumentos, imponente fachada de adobe/roca de la Iglesia.
- **Análisis BFS:** Analiza el subgrafo de la plaza. Carlos usará el Panel para mostrar por qué, aunque esta zona local tenga luz, la conexión principal se "corta" de cara a la montaña.
- **Mecánica y Luz:** Se exige conectar el Taller a la Iglesia. La plaza se enciende, relevando el problema mayor.
- **Narrativa:** "La plaza está a salvo, pero BFS se detiene abruptamente en la Cafetería. Delante de nosotros hay un sector entero en penumbras: un Componente Aislado masivo".

### Zona 4: El Panecillo (`Zona_Panecillo`)
- **Estética:** Pendiente pronunciada que corona en la estatua monumental de la Virgen de Quito.
- **Análisis BFS:** Inicia en la escalinata ("Poste Subida"). BFS trepará internamente los nodos de la montaña.
- **Mecánica y Victoria:** El jugador conecta el último gran "puente" (Cafetería hacia Poste Subida). Al restaurar esta componente aislada y conectar sus nodos locales, la Virgen se ilumina.
- **Narrativa Clímax:** "Al unir este último subgrafo a la red, cada zona de Quito forma parte de la misma telaraña. Hemos creado un Grafo Conexo global y la ciudad brilla entera".

---

## 4. Estructura Requerida en Studio (`ServerStorage/Niveles/Nivel1`)

```text
Nivel1/
├── Escenario/ (Mallas 3D de Quito Colonial, adoquines, balcones)
├── Grafos/
│   └── Grafo_Barrio/
│       ├── Conexiones/ (Cables iniciales vacíos en la cima)
│       ├── Meta/ (Activo=true)
│       └── Nodos/ 
│           ├── Transformador_Bulevar / Casa_Bulevar1 / Casa_Bulevar2
│           ├── Poste_LaRonda / Taller_LaRonda
│           ├── Iglesia_SantoDomingo / Casa_Plaza
│           └── Poste_Subida / Virgen_Panecillo / Restaurante_Panecillo
└── Zonas/
    └── Triggers/
        ├── ZonaTrigger_Bulevar
        ├── ZonaTrigger_Ronda
        ├── ZonaTrigger_SantoDomingo
        └── ZonaTrigger_Panecillo
```

*(No olvides crear posteriormente los archivos `DialogoData/DialogosNivel1/Nivel1_Bulevar.lua`, `Nivel1_Ronda.lua`, etc., e incluir en ellos las opciones con el flag `OpcionCorrecta = true` para otorgar los 100 puntos).*

