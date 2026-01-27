# Sistema de Objetos Coleccionables - Guía de Configuración

## 📋 Resumen
Sistema flexible para agregar objetos coleccionables en cada nivel que desbloquean funcionalidades (Mapa, Algoritmos, etc.)

## 🎯 Características
- ✅ Objetos aparecen cuando energizas nodos específicos
- ✅ Persistencia entre niveles (si completas nivel 0, mantienes los objetos)
- ✅ Reset al reiniciar el nivel actual
- ✅ Configuración fácil en `LevelsConfig.lua`

## 🛠️ Cómo Configurar un Objeto

### 1. Crear el Modelo en Roblox Studio

1. **Crea una carpeta** llamada `ObjetosColeccionables` dentro del modelo del nivel (ej: `Nivel0_Tutorial`)
   
2. **Agrega un Model** dentro de `ObjetosColeccionables` con el **ID del objeto** como nombre
   - Ejemplo: `Mapa` o `Algoritmo_BFS`
   
3. **Agrega las partes visuales** al Model (el objeto que verá el jugador)
   - Puede ser un modelo de la Toolbox o uno personalizado
   
4. **El script agregará automáticamente** el `ProximityPrompt`

### 2. Configurar en LevelsConfig.lua

Agrega el objeto en la tabla `Objetos` del nivel:

```lua
Objetos = {
    {
        ID = "Mapa",  -- Nombre del Model en ObjetosColeccionables
        Nombre = "Mapa de Villa Conexa",
        Descripcion = "Desbloquea la vista de mapa",
        Icono = "🗺️",
        NodoAsociado = "toma_corriente"  -- Aparece cuando este nodo se energiza
    },
    {
        ID = "Algoritmo_BFS",
        Nombre = "Manual de BFS",
        Descripcion = "Desbloquea el algoritmo BFS",
        Icono = "🧠",
        NodoAsociado = "PosteFinal"
    }
}
```

## 📁 Estructura en Workspace

```
Workspace
└── Nivel0_Tutorial
    ├── Objetos
    │   └── Postes
    │       ├── PostePanel
    │       ├── Poste1
    │       └── ...
    └── ObjetosColeccionables  ← CREAR ESTA CARPETA
        ├── Mapa  ← Model con el objeto visual
        └── Algoritmo_BFS  ← Model con el objeto visual
```

## 🎮 Cómo Funciona

1. **Al iniciar el nivel**: Los objetos están ocultos (Transparency = 1)
2. **Cuando energizas el nodo asociado**: El objeto aparece
3. **El jugador se acerca**: Ve el ProximityPrompt "Recoger [Nombre]"
4. **Al recoger**: 
   - Se agrega al inventario
   - El objeto desaparece
   - Se desbloquea la funcionalidad (Mapa/Algoritmo)
5. **Al reiniciar el nivel**: Los objetos de ese nivel se pierden
6. **Al pasar al siguiente nivel**: Los objetos anteriores se mantienen

## 🔧 Tipos de Objetos Predefinidos

### Mapa (ID: "Mapa")
- Desbloquea el botón 🗺️ MAPA
- Permite ver la vista aérea del nivel

### Algoritmo (ID: "Algoritmo_BFS", "Algoritmo_Dijkstra", etc.)
- Desbloquea el botón 🧠 ALGORITMO
- Permite ejecutar visualizaciones de algoritmos

## ➕ Agregar Nuevos Tipos de Objetos

1. **Agrega la configuración** en `LevelsConfig.lua`
2. **Crea el Model** en `ObjetosColeccionables`
3. **Actualiza `ClienteUI.client.lua`** para manejar el nuevo tipo (si desbloquea botones)

## 🐛 Troubleshooting

### "No se encontró modelo para objeto: X"
- Verifica que el nombre del Model coincida exactamente con el `ID` en LevelsConfig
- Asegúrate de que esté dentro de la carpeta `ObjetosColeccionables`

### "El objeto no aparece"
- Verifica que el `NodoAsociado` esté correctamente escrito
- Asegúrate de que el nodo se energice correctamente
- Revisa la consola para ver logs de debug

### "El objeto no se puede recoger"
- Verifica que el ProximityPrompt esté habilitado
- Asegúrate de estar en el nivel correcto

## 📝 Ejemplo Completo

```lua
-- En LevelsConfig.lua, Nivel 0
Objetos = {
    {
        ID = "Mapa",
        Nombre = "Mapa de Villa Conexa",
        Descripcion = "Desbloquea la vista de mapa",
        Icono = "🗺️",
        NodoAsociado = "toma_corriente"
    }
}
```

```
Workspace > Nivel0_Tutorial > ObjetosColeccionables > Mapa
    └── [Partes del modelo visual]
```

¡Listo! El sistema manejará automáticamente la aparición, recolección y persistencia del objeto.
