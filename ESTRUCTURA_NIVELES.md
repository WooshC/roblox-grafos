# 🏗️ Estructura del Sistema de Niveles

Este documento describe **exactamente** cómo deben estar organizados los archivos y objetos en tu proyecto de Roblox Studio para que el sistema de selección de niveles funcione.

---

## 📂 1. ReplicatedStorage (Configuración y Eventos)

Aquí se guardan los datos que tanto el Cliente como el Servidor necesitan ver.

*   `ReplicatedStorage`
    *   📄 **LevelsConfig** (ModuleScript) -> *Define los datos de cada nivel*
    *   📂 **Events** (Folder)
        *   📂 **Remotes** (Folder) -> *IMPORTANTE: La subcarpeta Remotes es necesaria*
            *   ⚡ **RequestPlayLevel** (RemoteEvent) -> *Cliente pide jugar nivel*
            *   📞 **GetPlayerProgress** (RemoteFunction) -> *Cliente pide estrellas/desbloqueos*
            *   *(Otros eventos de tu juego...)*

---

## 📂 2. ServerScriptService (Lógica del Servidor)

Aquí está el script que guarda los datos y controla el teletransporte.

*   `ServerScriptService`
    *   📂 **Base_Datos** (Folder)
        *   📜 **ManagerData** (Script - **NO** LocalScript) -> *Gestiona DataStores*

---

## 📂 3. StarterGui (Interfaz de Usuario)

Aquí es donde la estructura visual es CRÍTICA. El script del cliente espera encontrar los objetos con nombres específicos.

*   `StarterGui`
    *   📂 **MenuPrincipal** (ScreenGui)
        *   📂 **Escenarios** (Folder)
            *   📂 **SelectorNiveles** (Folder o Frame)
                *   📜 **LevelSelectorClient** (LocalScript - **Azul**) -> *Controla toda la lógica*
                *   🖼️ **AjustesFrame** (Frame) -> *Contenedor de los botones de nivel*
                    *   🔳 **UIGridLayout** (Layout)
                    *   🔘 **Nivel_0** (TextButton) -> *Tutorial*
                    *   🔘 **Nivel_1** (TextButton)
                    *   🔘 **Nivel_2** (TextButton)
                    *   ...
                *   🖼️ **Contenedor** (Frame) -> *Nuevo contenedor intermedio*
                    *   🖼️ **InfoNivelPanel** (Frame) -> *El panel lateral de detalles*
                        *   🏷️ **TituloNivel** (TextLabel)
                        *   🖼️ **ImagenContainer** (Frame)
                            *   🖼️ **ImageLabel** (ImageLabel) -> *La foto del nivel*
                        *   📜 **DescripcionScroll** (ScrollingFrame)
                            *   🏷️ **TextoDesc** (TextLabel)
                        *   🔘 **BotonJugar** (TextButton)

### ⚠️ Puntos Clave a Verificar:
1.  **Nombres Exactos:** Asegúrate de que `InfoNivelPanel` esté DENTRO de `Contenedor` si así lo configuraste en la UI.
2.  **Script Correcto:** `LevelSelectorClient` debe ser un **LocalScript** (icono de pergamino con una persona/azul), NO un Script de servidor (verde).
3.  **Eventos:** La carpeta `Remotes` dentro de `Events` es vital. Si `ManagerData` no la crea, créala manualmente.

---

## 4. Flujo de Datos

1.  **Inicio:** `LevelSelectorClient` invoca `GetPlayerProgress` al servidor.
2.  **Servidor:** `ManagerData` responde con `{Levels = {...}}`.
3.  **Cliente:** `LevelSelectorClient` colorea los botones (Azul = Desbloqueado, Gris = Bloqueado).
4.  **Selección:** Al hacer clic en un nivel desbloqueado, se llena `InfoNivelPanel`.
5.  **Jugar:** Al hacer clic en "JUGAR", se dispara `RequestPlayLevel(ID)`.
6.  **Servidor:** `ManagerData` valida y teletransporta al jugador.
