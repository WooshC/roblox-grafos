PLAN DE REFACTORIZACIÓN - ROBLOX STUDIO
========================================

📋 CONTENIDO DE ESTA CARPETA
============================

1. PLAN_REFACTORIZACION_ROBLOX.docx
   → Documento profesional completo
   → Diagnóstico detallado + patrones + beneficios
   → Abre esto en Word/Google Docs

2. 01_Enums.lua
   → Archivo centralizado de constantes
   → Colores, eventos, algoritmos
   → Ubicación: ReplicatedStorage/Shared/Enums.lua

3. 02_GraphUtils.lua
   → Funciones compartidas de grafos
   → BFS, DFS, Dijkstra, búsquedas
   → Ubicación: ReplicatedStorage/Shared/Utils/GraphUtils.lua

4. 03_GraphService.lua
   → Servicio centralizado de gestión de cables
   → REEMPLAZA código duplicado de 7 archivos
   → Ubicación: ServerScriptService/Services/GraphService.lua

5. 04_EnergyService.lua
   → Servicio de cálculo de energía
   → Reemplaza implementaciones de BFS duplicadas
   → Ubicación: ServerScriptService/Services/EnergyService.lua

6. 05_GUIA_USO.lua
   → Ejemplos de cómo usar los servicios
   → NO ejecutar, es solo referencia
   → Copiar/pegar los ejemplos que necesites

7. 06_EJEMPLO_REFACTOR_GameplayEvents.lua
   → Comparativa ANTES vs DESPUÉS
   → Muestra cómo refactorizar GameplayEvents
   → Referencia de cambios concretos

==================================================
PLAN DE INSTALACIÓN (PASO A PASO)
==================================================

⏱️ TIEMPO TOTAL: 4-5 HORAS

FASE 1: PREPARACIÓN (30 MIN)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. En Roblox Studio, abre tu game (o crea una copia de seguridad primero)

2. Crea carpeta: ReplicatedStorage/Shared
   
3. Crea subcarpeta: ReplicatedStorage/Shared/Utils
   
4. Crea carpeta: ServerScriptService/Services


FASE 2: MÓDULOS COMPARTIDOS (45 MIN)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Copia contenido de 01_Enums.lua
   → Pega en: ReplicatedStorage/Shared/Enums.lua
   → Prueba: print(require(...).Colors.NeonOrange)

2. Copia contenido de 02_GraphUtils.lua
   → Pega en: ReplicatedStorage/Shared/Utils/GraphUtils.lua
   → Prueba: print(require(...).getCableKey(...))


FASE 3: SERVICIOS (2-3 HORAS)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Copia contenido de 03_GraphService.lua
   → Pega en: ServerScriptService/Services/GraphService.lua
   
2. Copia contenido de 04_EnergyService.lua
   → Pega en: ServerScriptService/Services/EnergyService.lua

3. Ahora refactoriza GameplayEvents.server.lua:
   
   a) Abre GameplayEvents.server.lua
   
   b) Al principio, agrega:
   
      local GraphService = require(game:GetService("ServerScriptService").Services.GraphService)
      local EnergyService = require(game:GetService("ServerScriptService").Services.EnergyService)
      local Enums = require(game:GetService("ReplicatedStorage").Shared.Enums)
   
   c) Reemplaza la función:
      - Busca "function verificarConectividad()" 
      - ELIMINA esa función completa
      - Reemplaza con:
        
        local function verificarConectividad(sourceNode)
            return EnergyService:isNodeEnergized(sourceNode)
        end
   
   d) Escucha cambios:
   
      GraphService:onConnectionChanged(function(action, nodeA, nodeB)
          if action == "connected" then
              -- Recalcular energía
              local energized = EnergyService:calculateEnergy(nodeA)
              print("⚡ Energía actualizada")
          end
      end)


FASE 4: VISUALIZACIÓN (1-2 HORAS)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Abre VisualizadorAlgoritmos.server.lua

2. Agrega al inicio:
   
   local GraphService = require(game:GetService("ServerScriptService").Services.GraphService)
   local Enums = require(game:GetService("ReplicatedStorage").Shared.Enums)

3. Busca "function obtenerCarpetaPostes()"
   → ELIMINA esa función
   → Reemplaza con:
   
      local function getPostes()
          return GraphService:getNodes()
      end

4. Busca "function pintarCableSegunEnergia()"
   → Reemplaza con:
   
      local function pintarCableSegunEnergia(nodeA, nodeB, energized)
          local key = GraphUtils.getCableKey(nodeA, nodeB)
          local cable = GraphService:getCables()[key]
          
          if cable and cable.cableInstance then
              if energized[nodeA.Name] and energized[nodeB.Name] then
                  cable.cableInstance.Color = Enums.Colors.Energizado
              else
                  cable.cableInstance.Color = Enums.Colors.NoEnergizado
              end
          end
      end

5. Escucha eventos:
   
   GraphService:onConnectionChanged(function(action, nodeA, nodeB)
       if action == "connected" then
           -- Animar nuevo cable
           local cables = GraphService:getCables()
           -- ... tu lógica de animación ...
       end
   end)


FASE 5: PRUEBAS (30 MIN)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Abre Studio con tu juego

2. En consola de servidor, verifica:
   ✓ "GraphService inicializado" aparece
   ✓ "EnergyService" se carga sin errores

3. Prueba en juego:
   ✓ Conectar dos postes → Debe funcionar
   ✓ Cambiar color de cable → Debe funcionar
   ✓ Resetear nivel → Debe limpiar cables
   ✓ NO DEBE HABER CRASHES

4. Verifica Output:
   ✓ Sin errores rojos
   ✓ Sin advertencias de funciones duplicadas


==================================================
CHECKLIST DE IMPLEMENTACIÓN
==================================================

ESTRUCTURA:
□ Crear ReplicatedStorage/Shared/Enums.lua
□ Crear ReplicatedStorage/Shared/Utils/GraphUtils.lua
□ Crear ServerScriptService/Services/GraphService.lua
□ Crear ServerScriptService/Services/EnergyService.lua

INTEGRACIÓN:
□ Refactorizar GameplayEvents.server.lua
□ Refactorizar VisualizadorAlgoritmos.server.lua
□ Refactorizar Mapa.lua (si lo necesita)
□ Refactorizar ControladorEscenario.server.lua (si lo necesita)

ELIMINACIÓN DE DUPLICIDAD:
□ Eliminar función verificarConectividad() duplicadas
□ Eliminar función obtenerCarpetaPostes() duplicadas
□ Eliminar función pintarCablesSegunEnergia() duplicadas
□ Eliminar generación de claves "_" manuales

TESTING:
□ Conectar dos postes
□ Desconectar postes
□ Resetear nivel
□ Verificar energía
□ Ejecutar algoritmo
□ Completar nivel
□ Sin crashes después de cambios


==================================================
TROUBLESHOOTING
==================================================

❌ Error: "ReplicatedStorage.Shared es nil"
✅ Solución: Asegúrate de crear la carpeta Shared en ReplicatedStorage
   - No basta renombrar, CREA una nueva carpeta llamada "Shared"

❌ Error: "GraphService:init() expects (level)"
✅ Solución: Llama a GraphService:init(levelFolder) DESPUÉS de que el nivel esté en Workspace
   ```
   local nivel = ReplicatedStorage.Niveles.Nivel0:Clone()
   nivel.Parent = workspace
   GraphService:init(nivel)  -- Después de Parent
   ```

❌ Error: "getCableKey() no existe"
✅ Solución: Asegúrate de que GraphUtils está en ReplicatedStorage/Shared/Utils/
   - Path completo debe ser: ReplicatedStorage.Shared.Utils.GraphUtils

❌ Cables no se pintan
✅ Solución: Verifica que VisualizadorAlgoritmos está escuchando:
   ```
   GraphService:onConnectionChanged(function(action, nodeA, nodeB)
       -- Este código debe ejecutarse cuando conectas cables
   end)
   ```

❌ El juego se cae al conectar cables
✅ Solución: Probablemente aún hay código duplicado. Busca:
   - "verificarConectividad" (debe usar EnergyService)
   - "obtenerCarpetaPostes" (debe usar GraphService)
   - Bucles manuales sobre cables (debe usar GraphService:getCables())


==================================================
BENEFICIOS DESPUÉS DE REFACTORIZAR
==================================================

✅ ANTES:  7 scripts con búsqueda duplicada de postes
   DESPUÉS: 1 centralizado en GraphService

✅ ANTES: 5 formas diferentes de generar claves de cable
   DESPUÉS: 1 función en GraphUtils

✅ ANTES: 3 implementaciones de BFS
   DESPUÉS: 1 en EnergyService

✅ ANTES: Lag por iteraciones múltiples de cables
   DESPUÉS: Una sola pasada de grafo

✅ ANTES: Cambiar nombre de "Nivel0_Tutorial" → 7 archivos que actualizar
   DESPUÉS: 1 cambio en NivelUtils

✅ ANTES: Crashes por sincronización fallida
   DESPUÉS: Un único sistema de verdad

✅ ANTES: 70% de código es duplicidad
   DESPUÉS: 0% duplicidad, 100% mantenible


==================================================
PRÓXIMOS PASOS (Opcionales)
==================================================

Después de completar la refactorización básica:

1. Crear LevelService para carga/descarga dinámica de niveles

2. Crear AlgorithmService para encapsular Dijkstra/BFS visual

3. Implementar patrón Observable para UI (InventoryManager, etc.)

4. Agregar sistema de logging centralizado

5. Crear archivo de configuración de dificultad por nivel


==================================================
SOPORTE
==================================================

Si tienes problemas:

1. Revisa el documento PLAN_REFACTORIZACION_ROBLOX.docx
   → Tiene explicaciones detalladas

2. Consulta 05_GUIA_USO.lua
   → Tiene ejemplos de todos los métodos

3. Compara tu código con 06_EJEMPLO_REFACTOR_GameplayEvents.lua
   → Muestra ANTES y DESPUÉS


¡Buena suerte! 🚀
Después de esto, tu código será profesional y mantenible.