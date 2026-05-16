-- ReplicatedStorage/DialogoData/DialogosNivel2/Nivel2_Oficina.lua
-- Diálogo de la Zona 3 (Oficina de Análisis) — Nivel 2: La Fábrica de Señales
-- Concepto: Usos de DFS, comparación con BFS y cierre del nivel.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EfectosDialogo = require(ReplicatedStorage:WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
local ServicioCamara = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("ServicioCamara"))

-- Evento para notificar respuestas correctas al servidor
local function notificarRespuestaCorrecta()
	local eventos = ReplicatedStorage:FindFirstChild("EventosGrafosV3")
	if eventos then
		local remotos = eventos:FindFirstChild("Remotos")
		if remotos then
			local evento = remotos:FindFirstChild("DialogoCorrecto")
			if evento then
				evento:FireServer()
			end
		end
	end
end

local DIALOGOS = {
	["Nivel2_Oficina"] = {
		Zona  = "Zona_Oficina_3",
		Nivel = 2,
		Lineas = {
			{
				Id        = "intro_oficina",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Sonriente",
				Texto     = "Llegamos a la Oficina de Análisis. Desde aquí podemos ver todo el mapa de la fábrica en las pantallas. Ahora que conoces BFS y DFS, hablemos de cuándo usar cada uno.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Oficina_z3", { altura = 25, angulo = 60, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Oficina_z3", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Servidor_z3", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Antena_z3", "ADYACENTE")
				end,
				Siguiente = "comparacion_bfs_dfs",
			},
			{
				Id        = "comparacion_bfs_dfs",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "BFS es mejor para encontrar el camino más corto en número de pasos, porque explora por niveles. DFS es mejor para explorar si existe un camino, detectar ciclos en el grafo, y recorrer ramas completas antes de pasar a la siguiente.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Oficina_z3", "SELECCIONADO")
					EfectosDialogo.mostrarArista("Oficina_z3", "Servidor_z3", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Oficina_z3", "Antena_z3", "ADYACENTE", { sinParticulas = true })
				end,
				Siguiente = "pregunta_uso",
			},
			{
				Id        = "pregunta_uso",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Curioso",
				Texto     = "Pregunta: en Villa Conexa, ¿en qué situación específica sería mejor usar DFS en lugar de BFS?",
				Opciones = {
					{ Texto = "Cuando quiero verificar si hay un ciclo en la red eléctrica que podría causar cortocircuitos.", Siguiente = "resp_uso_bien" },
					{ Texto = "Cuando quiero encontrar la ruta con menos postes entre dos barrios.", Siguiente = "resp_uso_mal" },
					{ Texto = "Cuando quiero encender todas las luces lo más rápido posible por nivel.", Siguiente = "resp_uso_mal2" },
				},
			},
			{
				Id        = "resp_uso_bien",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "¡Exacto! DFS detecta ciclos de forma natural: si durante el recorrido encuentras una arista que lleva a un nodo ya en la pila, hay un ciclo. Un ciclo mal diseñado en la red eléctrica puede causar cortocircuitos. BFS es menos intuitivo para esa detección.",
				Evento = function()
					local jugador = game:GetService("Players").LocalPlayer
					if jugador then
						local puntajeActual = jugador:GetAttribute("PuntajeDialogo") or 0
						jugador:SetAttribute("PuntajeDialogo", puntajeActual + 100)
					end
					notificarRespuestaCorrecta()
				end,
				Opciones = { { Texto = "Continuar", Siguiente = "recursividad" } },
			},
			{
				Id        = "resp_uso_mal",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No exactamente. Encontrar la ruta con menos postes es trabajo de BFS, porque explora por niveles y garantiza el camino más corto en saltos. DFS podría encontrar un camino, pero no necesariamente el más corto.",
				Opciones = { { Texto = "Entendido", Siguiente = "recursividad" } },
			},
			{
				Id        = "resp_uso_mal2",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No, encender luces por nivel es exactamente lo que hace BFS. DFS no prioriza niveles; se adentra en una rama sin importar la distancia. Para propagación uniforme, BFS es la elección correcta.",
				Opciones = { { Texto = "Entendido", Siguiente = "recursividad" } },
			},
			{
				Id        = "recursividad",
				Numero    = 5,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "Por cierto, DFS también puede implementarse de forma recursiva, y de hecho es la forma más elegante. En la implementación recursiva, la pila del sistema operativo reemplaza a la pila explícita. Cada llamada recursiva es como apilar un nodo. Ambas versiones producen el mismo resultado.",
				Siguiente = "resumen",
			},
			{
				Id        = "resumen",
				Numero    = 6,
				Actor     = "Carlos",
				Expresion = "Presentacion",
				Texto     = "Recuerda siempre: BFS para distancias y niveles, DFS para exploración completa y detección de ciclos. Ambos son búsquedas ciegas: no saben dónde está la meta, simplemente exploran todo de forma ordenada. En el siguiente nivel aprenderás un algoritmo que sí usa los pesos para tomar decisiones inteligentes.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Oficina_z3", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Servidor_z3", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Antena_z3", "ADYACENTE")
					ServicioCamara.moverHaciaObjetivo("Gen_Fabrica_z1", { altura = 40, angulo = 75, duracion = 2 })
				end,
				Siguiente = "cierre_nivel",
			},
			{
				Id        = "cierre_nivel",
				Numero    = 7,
				Actor     = "Carlos",
				Expresion = "Extasiado",
				Texto     = "¡Excelente trabajo, Tocino! Has explorado toda la fábrica usando DFS. Dominaste la pila LIFO, el backtracking y la diferencia fundamental con BFS. La red de la fábrica está completamente verificada. ¡Nos vemos en el siguiente nivel!",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.restaurar(1.2)
				end,
				Siguiente = "FIN",
			},
		},
		Metadata = { TiempoDeEspera = 0.5, VelocidadTypewriter = 0.03, PuedeOmitir = true, OcultarHUD = true, UsarTTS = true },
		Configuracion = { bloquearMovimiento = true, bloquearSalto = true, apuntarCamara = true, ocultarTechos = true },
		EventoSaltar = function()
			EfectosDialogo.limpiarTodo()
			ServicioCamara.restaurar(0)
		end,
	},
}
return DIALOGOS
