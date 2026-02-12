# 🛠️ Sistema de Interfaz de Usuario y Recomendaciones

Este documento detalla los problemas actuales con la interfaz, las soluciones implementadas y las recomendaciones para el sistema de manejo de botones ("Inventario de Botones").

## 🚨 Problema Actual
Actualmente, al iniciar el juego, se muestra el **Menú Principal**, pero otros elementos de la interfaz (Interfaz de Roblox, Chat, Mochila, u otros botones del HUD de juego) aparecen superpuestos. Esto rompe la inmersión y hace que la pantalla se vea desordenada.

## ✅ Soluciones Aplicadas ( Cambios en la Interfaz)

### 1. Ocultar la Interfaz Nativa de Roblox (CoreGui)
Para asegurar que el Menú Principal esté limpio, hemos agregado instrucciones para deshabilitar la interfaz nativa de Roblox (Chat, Lista de Jugadores, Mochila) mientras el jugador está en el menú.
- **En el Menú**: `SetCoreGuiEnabled(Enum.CoreGuiType.All, false)`
- **Al Jugar**: `SetCoreGuiEnabled(Enum.CoreGuiType.All, true)` (o configurado según necesidad).

### 2. Gestión de Estados de UI
Se recomienda estructurar la UI en "Estados":
- **Estado Menú**: Solo visible `MenuPrincipal`. Todo lo demás oculto.
- **Estado Juego**: Visible el HUD (vidas, dinero, etc) y el botón de "Menú/Inventario". Oculto `MenuPrincipal`.

---

## 💡 Recomendación: Sistema de "Inventario" de Botones

Dado que planeas tener muchos botones (Tienda, Teletransportes, Códigos, Ajustes, Mascotas, etc.), llenarla pantalla de íconos es una mala práctica de diseño (UI Clutter).

Te recomiendo implementar un **"Menú de Gestión" (Hub Central)**.

### ¿Cómo funciona?
En lugar de tener 10 botones en la pantalla principal:
1.  Mantienes **UN SOLO botón principal** en una esquina (ej. un ícono de "Menú" o "Mochila" o un "Teléfono").
2.  Al hacer clic, se abre una ventana central (el "Inventario de Botones").
3.  Esta ventana contiene una rejilla (`UIGridLayout`) con todos los accesos directos.

### Ventajas
- **Limpieza**: Tu pantalla de juego se mantiene limpia, permitiendo ver el escenario.
- **Escalabilidad**: Puedes agregar 50 funcionalidades nuevas y solo tendrás que agregar un ícono más dentro de la ventana, sin rediseñar toda la pantalla.
- **Orden**: Puedes categorizar los botones por pestañas (ej. "Personaje", "Social", "Tienda").

### Implementación Sugerida en Roblox
1.  **ScreenGui** llamada `HUD`.
2.  **Frame** llamado `MenuDesplegable` (Oculto por defecto).
    -   Dentro: `ScrollingFrame` para permitir scroll si hay muchos botones.
    -   Dentro del ScrollingFrame: `UIGridLayout` para ordenar automáticamente los botones en filas y columnas.
3.  **TextButton** llamado `BotonMenu` (Visible siempre en el juego).
    -   Script: Al hacer click, hace `MenuDesplegable.Visible = not MenuDesplegable.Visible`.

---

## 📋 Próximos Pasos Recomendados

1.  Crear el `ScreenGui` para el HUD del juego (separado del Menú Principal).
2.  Desactivar la propiedad duplicada `ResetOnSpawn` de los ScreenGuis para evitar parpadeos.
3.  Implementar el script de "Hub Central" mencionado arriba.
