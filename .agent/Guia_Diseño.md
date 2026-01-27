# 📐 Guía de Diseño - Redes y Caminos (Roblox)

## 🎮 Estructura de Niveles en Roblox Studio

### 📁 Jerarquía Estándar de un Nivel (Actualizada 2026)

```
Nivel0_Tutorial (Model)
├── 📂 DialoguePrompts
│   ├── TestPrompt1 (ProximityPrompt)
│   ├── TestPrompt2 (ProximityPrompt)
│   └── ... (Más diálogos según necesites)
│
├── 📂 Objetos
│   ├── 📂 Postes (Nodos con energía)
│   │   ├── PostePanel (Model) - Generador/Inicio
│   │   │   ├── Selector (BasePart) - Para click y visualización
│   │   │   │   ├── Attachment
│   │   │   │   └── ClickDetector
│   │   │   └── Connections (Folder) - Se crea automáticamente
│   │   │
│   │   ├── Poste1 (Model)
│   │   ├── Poste2 (Model)
│   │   ├── Poste3 (Model)
│   │   ├── PosteFinal (Model) - Meta
│   │   └── toma_corriente (Model) - Nodo especial
│   │
│   └── 📂 [Futuros tipos de nodos]
│       ├── Carreteras (sin energía)
│       ├── Tuberías
│       └── etc.
│
├── 📂 Techos
│   ├── Techo1 (BasePart)
│   ├── Techo2 (BasePart)
│   └── ... (Se vuelven transparentes en modo mapa)
│
├── 📂 Zonas ⚡ NUEVA ESTRUCTURA
│   ├── 📂 Zona_Luz_1
│   │   ├── Ceiling_Light (Model) - Elemento iluminable
│   │   │   └── 📂 ComponentesEnergeticos
│   │   │       ├── base (BasePart con Material.Neon)
│   │   │       ├── PointLight (Light)
│   │   │       └── ... (Más componentes)
│   │   │
│   │   └── [Otros elementos de esta zona]
│   │
│   ├── 📂 Zona_Luz_2
│   │   ├── Ceiling_Light (Model)
│   │   │   └── 📂 ComponentesEnergeticos
│   │   │       └── base (BasePart con Material.Neon)
│   │   │
│   │   └── Puerta (Model) - Elemento bloqueado
│   │       ├── DoorObjects
│   │       │   └── Sounds
│   │       ├── ProximityPrompt
│   │       └── Script_bloqueo (Script)
│   │
│   └── [Más zonas según necesites]
│
├── 🎯 SpawnLocation (SpawnLocation)
│   └── (Roblox lo proporciona por defecto)
│
└── 📜 [Scripts del servidor]
    └── (Opcional, mejor tenerlos en ServerScriptService)
```

---

## 🔧 Componentes Clave

### 1. **Postes (Nodos con Energía)**

#### Estructura de un Poste:
```
PosteX (Model)
├── Selector (BasePart) - Para interacción
│   ├── Attachment (Attachment) - Para cables
│   ├── ClickDetector (ClickDetector)
│   └── Propiedades:
│       ├── Anchored = true
│       ├── CanCollide = true
│       ├── Size = Vector3.new(2, 10, 2) (aprox)
│       └── Color = Color3.fromRGB(139, 69, 19) (marrón)
│
└── Connections (Folder) - Se crea automáticamente por script
    └── [ObjectValues con referencias a postes conectados]
```

#### ⚡ Atributos del Poste (se setean automáticamente):
- `Energizado` (boolean) - Si tiene energía o no

#### 🎨 Estados Visuales (cables):
| Estado | Color Cable | Thickness |
|--------|-------------|-----------|
| Sin Energía | Gris oscuro `Dark stone grey` | 0.2 |
| Con Energía | Cyan `Cyan` | 0.3 |

---

### 2. **Zonas (Sistema de Iluminación)**

#### ⚡ NUEVA ESTRUCTURA - Carpeta Zonas

Todos los niveles deben tener una carpeta `Zonas` que contiene subcarpetas para cada zona iluminable.

#### Nomenclatura de Zonas:
- `Zona_Luz_1`, `Zona_Luz_2`, etc.
- Nombres case-sensitive (deben coincidir exactamente con LevelsConfig)

#### Estructura de una Zona:
```
Zona_Luz_X (Folder)
├── [Elemento1] (Model) - Ej: Ceiling_Light
│   └── ComponentesEnergeticos (Folder)
│       ├── base (BasePart con Material.Neon)
│       ├── PointLight (Light)
│       └── ... (Más componentes)
│
├── [Elemento2] (Model)
│   └── ComponentesEnergeticos (Folder)
│       └── ...
│
└── [Otros elementos que pertenecen a esta zona]
```

#### Carpeta ComponentesEnergeticos:
Debe contener:
- **Luces**: `PointLight`, `SpotLight`, `SurfaceLight`
- **Efectos**: `ParticleEmitter`, `Beam`
- **Partes Neon**: `BasePart` con `Material = Enum.Material.Neon`

#### Comportamiento automático:
```lua
-- Cuando la zona tiene energía (estado = true):
Light.Enabled = true
ParticleEmitter.Enabled = true
BasePart.Material = Enum.Material.Neon

-- Sin energía (estado = false):
Light.Enabled = false
ParticleEmitter.Enabled = false
BasePart.Material = Enum.Material.Plastic
```

---

### 3. **DialoguePrompts**

Carpeta para todos los diálogos del nivel usando `ProximityPrompt`.

#### Ejemplo de configuración:
```lua
-- En el ProximityPrompt
ActionText = "Hablar"
ObjectText = "Tutor"
HoldDuration = 0
MaxActivationDistance = 10
```

---

### 4. **Techos**

Partes que se vuelven transparentes en modo mapa.

#### Propiedades recomendadas:
```lua
Transparency = 0 (normal)
CastShadow = true
Material = Enum.Material.SmoothPlastic
```

#### En modo mapa:
```lua
Transparency = 0.95
CastShadow = false
```

---

## 📝 Configuración en LevelsConfig.lua (Actualizada)

### Formato Nuevo (Sistema de Misiones v2.0):

```lua
LevelsConfig[0] = {
    -- Información básica
    Nombre = "Campo de Entrenamiento",
    Modelo = "Nivel0_Tutorial", -- Nombre del modelo en workspace
    Descripcion = "Aprende los conceptos básicos: Nodos, Aristas y Pesos.",
    
    -- Economía
    DineroInicial = 2000,
    CostoPorMetro = 2,
    
    -- Algoritmo
    Algoritmo = "BFS",
    
    -- Grafo
    NodoInicio = "PostePanel", -- Generador
    NodoFin = "PosteFinal", -- Meta
    NodosTotales = 6, -- Total de postes
    
    Adyacencias = {
        ["PostePanel"] = {"Poste1", "Poste3", "toma_corriente"},
        ["Poste1"] = {"PostePanel", "PosteFinal", "Poste2"},
        ["Poste2"] = {"Poste1", "PosteFinal", "Poste3"},
        ["Poste3"] = {"PostePanel", "PosteFinal"},
        ["PosteFinal"] = {"Poste3", "Poste1", "Poste2", "toma_corriente"},
        ["toma_corriente"] = {"PostePanel"}
    },
    
    -- ⚡ NUEVO: Misiones con validadores declarativos
    Misiones = {
        {
            ID = 1,
            Texto = "Conecta el Generador a la Torre 1 (Poste1)",
            Tipo = "NODO_ENERGIZADO",
            Parametros = {
                Nodo = "Poste1"
            }
        },
        {
            ID = 2,
            Texto = "¡Llega a la Torre de Control!",
            Tipo = "NODO_ENERGIZADO",
            Parametros = {
                Nodo = "PosteFinal"
            }
        },
        {
            ID = 3,
            Texto = "¡Energiza toda la red! (6/6 nodos)",
            Tipo = "TODOS_LOS_NODOS",
            Parametros = {
                Cantidad = 6
            }
        },
        {
            ID = 4,
            Texto = "Energiza la Toma de Corriente y recoge el mapa",
            Tipo = "NODO_ENERGIZADO",
            Parametros = {
                Nodo = "toma_corriente"
            }
        }
    },
    
    -- ⚡ NUEVO: Configuración de Nodos y Zonas
    Nodos = {
        PostePanel = { 
            Zona = nil,  -- No pertenece a ninguna zona (es el generador)
            Alias = "Generador"
        },
        Poste1 = { 
            Zona = "Zona_Luz_1",
            Alias = "Torre 1"
        },
        Poste2 = { 
            Zona = "Zona_Luz_1",
            Alias = "Torre 2"
        },
        Poste3 = { 
            Zona = "Zona_Luz_1",
            Alias = "Torre 3"
        },
        PosteFinal = { 
            Zona = "Zona_Luz_1",
            Alias = "Torre Control"
        },
        toma_corriente = { 
            Zona = "Zona_Luz_2",  -- ⚡ Zona específica
            Alias = "Toma Corriente"
        }
    },
    
    -- ⚡ NUEVO: Configuración de Zonas
    Zonas = {
        ["Zona_Luz_1"] = {
            Modo = "ANY",  -- Se enciende si AL MENOS UN nodo tiene energía
            Descripcion = "Sector principal (Poste1, Poste2, Poste3, PosteFinal)"
        },
        ["Zona_Luz_2"] = {
            Modo = "ANY",  -- Se enciende si toma_corriente tiene energía
            Descripcion = "Sector secundario (toma_corriente)"
        }
    },
    
    -- Nombres Personalizados
    NombresPostes = {
        ["PostePanel"] = "Generador",
        ["PosteFinal"] = "Torre Control",
        ["Poste1"] = "Torre 1",
        ["Poste2"] = "Torre 2",
        ["Poste3"] = "Torre 3",
        ["toma_corriente"] = "Toma Corriente"
    },
    
    -- Puntuación
    Puntuacion = {
        TresEstrellas = 100,
        DosEstrellas = 200,
        RecompensaXP = 50
    }
}
```

---

## 🎯 Tipos de Validadores de Misiones

### 1. `NODOS_MINIMOS`
Verifica que al menos X nodos estén energizados.
```lua
{
    Tipo = "NODOS_MINIMOS",
    Parametros = { Cantidad = 3 }
}
```

### 2. `NODO_ENERGIZADO`
Verifica que un nodo específico esté energizado.
```lua
{
    Tipo = "NODO_ENERGIZADO",
    Parametros = { Nodo = "PosteFinal" }
}
```

### 3. `TODOS_LOS_NODOS`
Verifica que TODOS los nodos del nivel estén energizados.
```lua
{
    Tipo = "TODOS_LOS_NODOS",
    Parametros = { Cantidad = 6 }
}
```

### 4. `ZONA_ACTIVADA`
Verifica que una zona específica esté encendida.
```lua
{
    Tipo = "ZONA_ACTIVADA",
    Parametros = { Zona = "Zona_Luz_2" }
}
```

### 5. `PRESUPUESTO_RESTANTE`
Verifica que el jugador tenga al menos X dinero.
```lua
{
    Tipo = "PRESUPUESTO_RESTANTE",
    Parametros = { Cantidad = 500 }
}
```

### 6. `NODOS_LISTA`
Verifica que TODOS los nodos de una lista estén energizados.
```lua
{
    Tipo = "NODOS_LISTA",
    Parametros = { 
        Nodos = {"Poste1", "Poste2", "Poste3"} 
    }
}
```

### 7. `CUSTOM`
Permite lógica personalizada.
```lua
{
    Tipo = "CUSTOM",
    Parametros = {
        Validador = function(estado)
            return estado.numNodosConectados > 3 
                   and estado.dineroRestante > 100
        end
    }
}
```

---

## 🎨 Cómo Crear un Nuevo Nivel

### Paso 1: Crear el Modelo en Studio
1. Crea un `Model` llamado `NivelX_Nombre`
2. Agrega las carpetas: `DialoguePrompts`, `Objetos`, `Techos`, `Zonas`
3. Dentro de `Objetos`, crea la carpeta `Postes`
4. Dentro de `Zonas`, crea carpetas `Zona_Luz_1`, `Zona_Luz_2`, etc.

### Paso 2: Crear Postes
1. Crea un `Model` para cada poste
2. Dentro del modelo:
   - `Selector` (BasePart)
     - `Attachment` (para cables)
     - `ClickDetector`
3. Asigna `PrimaryPart = Selector`

### Paso 3: Configurar Zonas
1. Dentro de cada `Zona_Luz_X`, crea Models (ej: `Ceiling_Light`)
2. Dentro de cada Model, crea carpeta `ComponentesEnergeticos`
3. Agrega luces, efectos y partes Neon dentro de `ComponentesEnergeticos`

### Paso 4: Agregar SpawnLocation
1. Inserta un `SpawnLocation` de Roblox
2. Posiciónalo donde quieres que aparezca el jugador

### Paso 5: Configurar en LevelsConfig.lua
```lua
LevelsConfig[X] = {
    Nombre = "Tu Nivel",
    Modelo = "NivelX_Nombre",
    NodoInicio = "PosteGenerador",
    NodoFin = "PosteMeta",
    NodosTotales = 8,
    
    Adyacencias = {
        -- Define qué postes se pueden conectar
    },
    
    Misiones = {
        {
            ID = 1,
            Texto = "...",
            Tipo = "NODO_ENERGIZADO",
            Parametros = { Nodo = "Poste1" }
        }
    },
    
    Nodos = {
        Poste1 = { Zona = "Zona_Luz_1", Alias = "Torre 1" }
    },
    
    Zonas = {
        ["Zona_Luz_1"] = { Modo = "ANY", Descripcion = "..." }
    }
}
```

---

## ⚠️ Problemas Comunes y Soluciones

### Problema: Zona no se enciende
**Causa:** Nombre de zona no coincide exactamente

**Solución:** 
- Verifica que el nombre en workspace sea exactamente igual a LevelsConfig
- Los nombres son **case-sensitive**: `Zona_Luz_1` ≠ `Zona_luz_1`

### Problema: Cables no se actualizan al desconectar
**Causa:** Sistema de verificación de energía no se ejecuta

**Solución:** 
- El evento `ConexionCambiada` se dispara automáticamente
- Verifica que `GameplayEvents.server.lua` esté activo
- Los cables se resetean a gris y luego se pintan de cyan si tienen energía

### Problema: Postes no se detectan
**Solución:** Verifica que:
- El `Model` tiene un `PrimaryPart` asignado
- El `Selector` tiene un `Attachment`
- El `ClickDetector` está dentro del `Selector`

### Problema: Luces no se encienden
**Solución:** Verifica que:
- Las luces están dentro de `Zonas/Zona_Luz_X/[Model]/ComponentesEnergeticos`
- El nombre de la carpeta es exactamente `ComponentesEnergeticos`
- El nodo está configurado en `LevelsConfig.Nodos` con la zona correcta

---

## 📊 Checklist para Nuevo Nivel

- [ ] Modelo creado con nombre `NivelX_Nombre`
- [ ] Carpetas creadas: `DialoguePrompts`, `Objetos/Postes`, `Techos`, `Zonas`
- [ ] Zonas creadas: `Zona_Luz_1`, `Zona_Luz_2`, etc.
- [ ] Todos los postes tienen:
  - [ ] `Selector` con `Attachment` y `ClickDetector`
  - [ ] `PrimaryPart` asignado
- [ ] Cada zona tiene:
  - [ ] Models con `ComponentesEnergeticos`
  - [ ] Luces/efectos dentro de `ComponentesEnergeticos`
- [ ] `SpawnLocation` colocado
- [ ] Configuración en `LevelsConfig.lua`:
  - [ ] `Nombre`, `Modelo`, `Descripcion`
  - [ ] `DineroInicial`, `CostoPorMetro`
  - [ ] `NodoInicio`, `NodoFin`, `NodosTotales`
  - [ ] `Adyacencias` completas
  - [ ] `Misiones` con validadores
  - [ ] `Nodos` con zonas asignadas
  - [ ] `Zonas` configuradas
  - [ ] `NombresPostes` (opcional)
- [ ] Probado en Studio:
  - [ ] Spawn funciona
  - [ ] Postes se pueden clickear
  - [ ] Cables se crean y se actualizan
  - [ ] Luces se encienden al energizar nodos
  - [ ] Misiones se marcan correctamente
  - [ ] Cables se apagan al desconectar

---

## 🎓 Mejores Prácticas

1. **Nomenclatura consistente:**
   - Postes: `PosteX` donde X es número o nombre descriptivo
   - Generador siempre: `PostePanel`
   - Meta siempre: `PosteFinal`
   - Zonas: `Zona_Luz_X` donde X es número

2. **Organización:**
   - Usa carpetas para agrupar objetos similares
   - Nombra todo claramente (case-sensitive)
   - Usa `PrimaryPart` en todos los `Model`
   - Agrupa componentes energéticos en `ComponentesEnergeticos`

3. **Optimización:**
   - Máximo 3 luces por zona
   - Usa `Anchored = true` en partes estáticas
   - Minimiza `GetDescendants()` en loops

4. **Testing:**
   - Prueba cada nivel en modo solo
   - Verifica todas las misiones
   - Confirma que el spawn funciona
   - Revisa que las luces se encienden
   - Prueba desconectar cables (deben apagarse)

---

## 🚀 Funcionalidades Implementadas

### ✅ Sistema de Misiones v2.0
- Validadores declarativos
- 10+ tipos de validadores
- Fácil agregar nuevas misiones
- Soporte para lógica personalizada

### ✅ Sistema de Zonas
- Múltiples zonas por nivel
- Modos: `ANY` (al menos un nodo) o `ALL` (todos los nodos)
- Actualización automática de luces
- Búsqueda flexible de componentes

### ✅ Actualización de Cables
- Reseteo automático al desconectar
- Colores: Gris (sin energía), Cyan (con energía)
- Verificación instantánea

---

**Última actualización:** 2026-01-24
**Versión:** 3.0 - Sistema de Zonas y Misiones v2.0
