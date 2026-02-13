# Plan de Implementación: Minimapa con ViewportFrame (Estilo GTA/Genérico) 🗺️�

Este documento detalla la implementación de un minimapa utilizando `ViewportFrame`. Es la solución ideal si buscas algo funcional, visualmente claro (fondo negro + nodos brillantes + puntero) y fácil de mantener sin complicaciones matemáticas excesivas.

## � Objetivo
Crear un minimapa circular o cuadrado en la esquina de la pantalla que muestre:
1.  **Fondo:** Negro sólido.
2.  **Contenido:** Los nodos (Postes) y conexiones del grafo en colores vivos (Neon).
3.  **Jugador:** Un puntero (flecha) en el centro que indica la posición y rotación del usuario.

---

## �️ ¿Por qué ViewportFrame?
Es la forma "nativa" de Roblox de mostrar objetos 3D en la interfaz 2D. 
- **Facilidad:** No tienes que calcular coordenadas X/Y en pantalla. Solo pones una cámara virtual arriba del jugador y Roblox hace el resto.
- **Dinamismo:** Si cambias el color de un nodo en el juego real, puedes replicar ese cambio fácilmente en el minimapa.

---

## � Pasos de Implementación

### 1. Configuración de la GUI
1.  Crear un `ScreenGui` llamado `MinimapGUI`.
2.  Dentro, crear un `Frame` borde (opcional) y dentro un `ViewportFrame`.
    *   **Propiedades:**
        *   `BackgroundColor3`: `0, 0, 0` (Negro).
        *   `BackgroundTransparency`: `0` (O si quieres transparencia leve, 0.5).
        *   `Size`: `UDim2.new(0, 200, 0, 200)` (Tamaño fijo).
        *   `Position`: Esquina inferior izquierda o derecha.
        *   **(Opcional) Máscara Circular:** Si quieres que sea redondo, pon el `ViewportFrame` dentro de un frame con `UICorner` (CornerRadius 1,0).

### 2. Preparación del "Mundo Miniatura"
Necesitamos clonar los objetos que queremos ver dentro del `ViewportFrame`. **No clones todo el mapa**, solo lo importante.

*   **Script Local (MinimapController):**
    *   Al iniciar, busca la carpeta de `Postes` y `Conexiones`.
    *   Clona estas partes dentro del `ViewportFrame`.
    *   **Optimización Visual:** Al clonar, cambia el material a `Neon` y usa colores brillantes para que resalten sobre el fondo negro. Elimina texturas o detalles innecesarios de los clones.

### 3. La Cámara del Minimapa
El `ViewportFrame` necesita su propia `Camera`.

```lua
local camera = Instance.new("Camera")
camera.FieldOfView = 50 -- Ajusta para el zoom
viewportFrame.CurrentCamera = camera
```

### 4. Actualización en Tiempo Real (El Puntero del Jugador)
Aquí hay dos estilos, el estilo GTA suele tener al jugador siempre en el centro.

**Lógica del Loop (RunService.RenderStepped):**

1.  **Obtener posición del jugador:** `HumanoidRootPart.Position`.
2.  **Mover la Cámara:** Coloca la cámara justo encima del jugador, mirando hacia abajo.
    ```lua
    local alturaCamara = 150 -- Distancia visual (Zoom)
    local playerPos = rootPart.Position
    
    -- Opción A: Mapa que ROTA con el jugador (Estilo GTA)
    -- La cámara se posiciona arriba y rota igual que el RootPart
    local nuevaCFrame = CFrame.new(playerPos + Vector3.new(0, alturaCamara, 0), playerPos)
    -- Ajustar rotación para que coincida con la mirada del jugador...
    
    -- Opción B: Mapa FIJO (Norte siempre arriba) - MÁS FÁCIL DE LEER PARA GRAFOS
    camera.CFrame = CFrame.new(playerPos.X, alturaCamara, playerPos.Z) * CFrame.Angles(math.rad(-90), 0, 0)
    ```

3.  **El Puntero (Flecha):**
    *   En lugar de una parte 3D, es mejor usar una `ImageLabel` (flecha) pegada en el centro del `ViewportFrame` (por encima, ZIndex más alto).
    *   Si usas **Opción A (Mapa Rota)**: La flecha siempre apunta hacia ARRIBA.
    *   Si usas **Opción B (Mapa Fijo)**: La flecha rota según la orientación del `HumanoidRootPart`.
        `flecha.Rotation = -rootPart.Orientation.Y`

---

## ❓ Preguntas Frecuentes

### ¿Es esta la forma más fácil?
**Sí y No.**
*   **Sí, es la más flexible:** Porque funciona automáticamente aunque muevas los nodos o cambies el nivel. `ViewportFrame` maneja la proyección 3D por ti.
*   **¿Hay algo más fácil?**
    *   **Imagen Estática:** Tomar una captura de pantalla del mapa visto desde arriba, ponerla en un `ImageLabel` y simplemente mover la imagen dentro de un marco con `ClipsDescendants=true`.
    *   *Por qué NO te recomiendo la imagen estática:* Porque tu juego trata sobre **Grafos y Algoritmos**. Probablemente los nodos cambien de color (visitado, camino óptimo, etc.). Una imagen estática no mostrará esos cambios de color en vivo. El `ViewportFrame` sí puede hacerlo (si actualizas el color de los clones).

### ¿Cómo hago que los grafos aparezcan ahí?
Simplemente asegúrate de que cuando tu script de algoritmos pinte un nodo en el `workspace`, también envíe una señal (o un evento) para pintar el nodo correspondiente (el clon) dentro del `ViewportFrame`.

---

## 🚀 Resumen del Plan
1.  Crear **GUI** con `ViewportFrame` negro.
2.  **Script:** Clonar `Postes` al `ViewportFrame` (convertirlos en bloquecitos Neon).
3.  **RenderStepped:** Mover la `Camera` del ViewportFrame para seguir la `Position` X/Z del jugador desde arriba.
4.  Poner una **Imagen (Flecha)** en el centro de la GUI para representar al jugador.

