# Workspace / Postes

Esta carpeta contiene todos los postes (nodos) del grafo.

## 🏛️ Componentes

### Panel (Model)
**Tipo**: Model  
**Propósito**: Nodo principal del grafo (origen)

**Características especiales**:
- ✅ `IsPanel` (BoolValue) = true
- ✅ Color dorado (255, 215, 0)
- ✅ Material: Metal
- ✅ Altura: 15 studs
- ✅ BillboardGui con texto "⚡ PANEL PRINCIPAL"
- ✅ Posición fija: (0, 5, 0)

Ver: `Panel.txt` para estructura completa

---

### Poste1, Poste2, ... (Models)
**Tipo**: Model  
**Propósito**: Nodos estándar del grafo

**Características**:
- Color marrón (139, 69, 19)
- Material: Wood
- Altura: 10 studs
- Posición aleatoria

Ver: `Poste1.txt` para estructura completa

---

## 📦 Estructura de un Poste

```
Poste (Model)
├── Selector (Part)
│   ├── Attachment       ← Para cables
│   └── ClickDetector    ← Para selección
└── Connections (Folder) ← Referencias a vecinos
```

---

## 🔌 Conexiones

Cuando dos postes se conectan:

1. **Visual**: Se crea un RopeConstraint entre los Attachments
2. **Datos**: Se crean ObjectValues en ambas carpetas Connections
3. **Grafo**: Se registra la arista en GrafoModule

Ejemplo:
```
Panel ←──[RopeConstraint]──→ Poste1
  ↓                              ↓
Connections/                 Connections/
  Connection_Poste1            Connection_Panel
  (ObjectValue)                (ObjectValue)
```

---

## 🎮 Interacción

1. Jugador hace click en un poste
2. ClickDetector dispara evento
3. ConectarCables.server.lua procesa el click
4. Al seleccionar dos postes, se crea la conexión

---

## 🔧 Creación Manual

Si prefieres crear postes manualmente en lugar de usar `CrearPostes.server.lua`:

```lua
-- 1. Crear Model
local poste = Instance.new("Model")
poste.Name = "Poste1"
poste.Parent = workspace.Postes

-- 2. Crear Selector (Part)
local selector = Instance.new("Part")
selector.Name = "Selector"
selector.Size = Vector3.new(2, 10, 2)
selector.Anchored = true
selector.Color = Color3.fromRGB(139, 69, 19)
selector.Material = Enum.Material.Wood
selector.Parent = poste

-- 3. Crear Attachment
local attachment = Instance.new("Attachment")
attachment.Parent = selector

-- 4. Crear ClickDetector
local clickDetector = Instance.new("ClickDetector")
clickDetector.MaxActivationDistance = 32
clickDetector.Parent = selector

-- 5. Crear carpeta Connections
local connections = Instance.new("Folder")
connections.Name = "Connections"
connections.Parent = poste

-- 6. Establecer PrimaryPart
poste.PrimaryPart = selector
```

---

## 📄 Archivos de Documentación

- `Panel.txt` - Estructura completa del Panel Principal
- `Poste1.txt` - Estructura completa de un Poste estándar
- `RopeConstraint_Cable.txt` - Documentación de cables visuales

---

## 🎯 Representación en el Grafo

```lua
-- En GrafoModule.lua
grafo = {
    ["Panel"] = {
        ["Poste1"] = 25.5,  -- distancia en studs
        ["Poste2"] = 30.2
    },
    ["Poste1"] = {
        ["Panel"] = 25.5,
        ["Poste3"] = 15.8
    },
    -- ...
}
```

---

## 💡 Tips

- Mantén una distancia mínima de 20 studs entre postes
- El Panel debe ser fácilmente identificable (color dorado)
- Usa nombres descriptivos: Panel, Poste1, Poste2, etc.
- No olvides el `IsPanel = true` en el Panel Principal
