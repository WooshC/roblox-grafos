# GrafosV3 — Pendientes e Incumplimientos
> Documento consolidado con desviaciones respecto a PLAN_ARQUITECTURA_V4 y SISTEMA_2_PLAN_MEJORADO_v4.

Este documento recopila todas las faltas a la arquitectura pactada que **NO han sido implementadas** en el código actual. (Se verificó con éxito profundo que tanto la `Arquitectura de Audio V2`, `Gestores de Efectos/Billboards`, `Gestor de Colisiones` y la Librería Central `GrafoHelpers` operan excepcionalmente de acuerdo al plan prescrito).

---

## 1. Optimización y Robustez Crítica (V4 Fases Finales)
Las tareas encomendadas bajo sección "Robustez y Limpieza" (Pendientes 10, 11 y 12 del Plan Arquitectura V4) no fueron atendidas durante el despliegue del juego:
- **`WaitForChild` sin aserciones preventivas:** Los scripts principales (ej. `Boot.server` o `EventosHUD`) llaman `WaitForChild(X, segundos)` devolviendo `nil` si hay asincronía de red y continúan la ejecución de Lua en lugar de abortar de manera vistosa con `assert()`. Esto podría colgar la pantalla de carga permanentemente silenciando el error por Consola en casos de Lag Severo ("Falla Silenciosa").
- **Coste Computacional Local de `Require` en Handlers:** El archivo orquestador `Boot.server.lua` sigue cargando mediante `pcall(require, moduloCables)` *cada vez* que el jugador detona eventos de click remotos (`MapaClickNodo`, `ConectarDesdeMapa`). Estas referencias debieron aislarse previamente hacia variables temporales dentro del ambiente del jugador en la fase de inicialización `ESTADO_CARGANDO`, para restarle latencia e impacto por uso intensivo de IO en el disco al servidor global.
- **Validación Faltante en LevelsConfig:** No existe un chequeo de seguridad primario en `CargadorNiveles.cargar` que aborte automáticamente (antes de clonar la pesada geometría de miles de parts de Instancia) si por un error humano el array virtual de `LevelsConfig[N]` carece del componente core `Adyacencias = {}`. Los Niveles 2, 3 y 4 continúan vacíos de lógica pero el jugador podría intentar abrirlos desde el menú y trabar su Cliente de Juego.

---

## Conclusión Central
La arquitectura en su núcleo está **100% sana y alineada** al `Plan V4` final. Lo único restante en esta versión técnica de GrafosV3 para darlo como un producto seguro anti-hackers y anti-lag recae unánimemente en la "Programación Defensiva", debiendo implementar validadores anti-nulo en las rutinas de inyección antes expresadas.
