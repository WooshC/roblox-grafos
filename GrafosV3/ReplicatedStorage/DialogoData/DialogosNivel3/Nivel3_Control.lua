-- ReplicatedStorage/DialogoData/DialogosNivel3/Nivel3_Control.lua
-- Diálogo de la Zona 3 (Centro de Control) — Nivel 3: El Árbol de Expansión Mínima
-- Concepto: Aplicaciones de MST, eficiencia de Prim y cierre del nivel.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LevelsConfig      = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("LevelsConfig"))
local EfectosDialogo    = require(ReplicatedStorage:WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
local ServicioCamara    = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("ServicioCamara"))

-- Evento para notificar respuestas correctas al servidor
local Utilidades = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("Utilidades"))

local function notificarRespuestaCorrecta()
	Utilidades.notificarDialogoCorrecto()
end

-- ════════════════════════════════════════════════════════════════════
-- ALIASES
-- ════════════════════════════════════════════════════════════════════

local nombres       = LevelsConfig[3].NombresNodos
local configNivel   = LevelsConfig[3]
local costoPorMetro = configNivel.CostoPorMetro
local presupuesto   = configNivel.Presupuesto.Inicial

local aliasBodega   = nombres["Gen_Bodega_z1"]      or "Generador Bodega"
local aliasPlaza    = nombres["Plaza_z2"]           or "Plaza Central"
local aliasCentro   = nombres["Centro_Control_z3"]  or "Centro de Control"
local aliasAntena   = nombres["Antena_z3"]          or "Antena Principal"
local aliasSubest   = nombres["Subestacion_z3"]     or "Subestacion Electrica"
local aliasTerminal = nombres["Terminal_z3"]        or "Terminal de Red"

-- ════════════════════════════════════════════════════════════════════
-- DATOS DEL DIÁLOGO
-- ════════════════════════════════════════════════════════════════════

local DIALOGOS = {
	["Nivel3_Control"] = {
		Zona  = "Zona_Control_3",
		Nivel = 3,
		Lineas = {
			-- ── 1. INTRODUCCIÓN AL CENTRO DE CONTROL ──────────────────────
			{
				Id        = "intro_control",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Sonriente",
				Texto     = "Llegamos al " .. aliasCentro .. ". Desde aquí se ve toda la red del pueblo en las pantallas. Usando Prim hemos aprendido a tender cables con el mínimo desperdicio posible. 🖥️",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Centro_Control_z3", { altura = 25, angulo = 60, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Centro_Control_z3", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Antena_z3", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Subestacion_z3", "ADYACENTE")
				end,
				Siguiente = "pregunta_app",
			},
			-- ── 2. PREGUNTA DE OPCIÓN MÚLTIPLE ──────────────────────────────
			{
				Id        = "pregunta_app",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Curioso",
				Texto     = "Pregunta: ¿dónde se usa un Árbol de Expansión Mínima en la vida real?",
				Opciones = {
					{ Texto = "Para diseñar redes eléctricas, fibra óptica y carreteras con el menor costo total.", Siguiente = "resp_app_bien" },
					{ Texto = "Para ordenar listas de nombres alfabéticamente.", Siguiente = "resp_app_mal" },
					{ Texto = "Para encontrar el camino más corto entre dos ciudades en un GPS.", Siguiente = "resp_app_mal2" },
				},
			},
			-- Respuesta correcta
			{
				Id        = "resp_app_bien",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "¡Correcto! El MST sirve para planificar redes donde queremos conectar muchos puntos sin gastar de más: electricidad, fibra óptica, carreteras, circuitos impresos, e incluso agrupación de datos. 🌐",
				Evento = function()
					local jugador = game:GetService("Players").LocalPlayer
					if jugador then
						local puntajeActual = jugador:GetAttribute("PuntajeDialogo") or 0
						jugador:SetAttribute("PuntajeDialogo", puntajeActual + 100)
					end
					notificarRespuestaCorrecta()
				end,
				Opciones = { { Texto = "Continuar", Siguiente = "complejidad" } },
			},
			-- Respuesta incorrecta 1
			{
				Id        = "resp_app_mal",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No exactamente. Ordenar nombres es un problema de ordenamiento, no de grafos. El MST aparece cuando queremos conectar puntos minimizando el costo total de las conexiones.",
				Opciones = { { Texto = "Entendido", Siguiente = "complejidad" } },
			},
			-- Respuesta incorrecta 2
			{
				Id        = "resp_app_mal2",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Eso describe Dijkstra, no Prim. Un GPS busca la ruta más corta entre dos puntos. El MST busca conectar TODOS los puntos con el menor costo total, sin importar un par origen-destino específico.",
				Opciones = { { Texto = "Entendido", Siguiente = "complejidad" } },
			},
			-- ── 4. COMPLEJIDAD DE PRIM ────────────────────────────────────
			{
				Id        = "complejidad",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "Hablemos de eficiencia. Con una matriz de adyacencia, Prim es O(N²) porque cada vez busca el nodo con la key mínima recorriendo todos los nodos. Con una lista de adyacencia más un Min-Heap, baja a O((N + A) · log N). Para grafos grandes y dispersos, la segunda versión es mucho más rápida.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Centro_Control_z3", "SELECCIONADO")
					EfectosDialogo.mostrarArista("Centro_Control_z3", "Antena_z3", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Centro_Control_z3", "Subestacion_z3", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Antena_z3", "Terminal_z3", "ADYACENTE", { sinParticulas = true })
					EfectosDialogo.mostrarLabel("Antena_z3", "3 m")
					EfectosDialogo.mostrarLabel("Subestacion_z3", "4 m")
					EfectosDialogo.mostrarLabel("Terminal_z3", "2 m")
				end,
				Siguiente = "prim_vs_dijkstra",
			},
			-- ── 5. PRIM VS DIJKSTRA ───────────────────────────────────────
			{
				Id        = "prim_vs_dijkstra",
				Numero    = 5,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "Repasemos la diferencia clave. Dijkstra resuelve camino mínimo desde un origen: cada nodo guarda la distancia acumulada desde la raíz. Prim resuelve MST: cada nodo guarda el peso de la arista más barata que lo conecta al árbol. Son 'primos', pero resuelven problemas distintos. 🧠",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Gen_Bodega_z1", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Terminal_z3", "SELECCIONADO")
					EfectosDialogo.mostrarArista("Gen_Bodega_z1", "Poste_Norte_z1", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Poste_Norte_z1", "Cruce_Norte_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Cruce_Norte_z2", "Mercado_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Mercado_z2", "Plaza_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Plaza_z2", "Centro_Control_z3", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Centro_Control_z3", "Antena_z3", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Antena_z3", "Terminal_z3", "SELECCIONADO", { sinParticulas = true })
					ServicioCamara.moverHaciaObjetivo("Plaza_z2", { altura = 40, angulo = 75, duracion = 2 })
				end,
				Siguiente = "cierre_presupuesto",
			},
			-- ── 6. CIERRE DEL PRESUPUESTO ───────────────────────────────────
			{
				Id        = "cierre_presupuesto",
				Numero    = 6,
				Actor     = "Carlos",
				Expresion = "Sonriente",
				Texto     = "En este nivel aprendiste a no derrochar cable. Prim te da la estrategia 'greedy': crece el árbol siempre por la conexión más barata. Pero recuerda que el presupuesto es de $" .. tostring(presupuesto) .. " y cada metro cuesta $" .. tostring(costoPorMetro) .. ", así que en cada misión elige primero las conexiones más urgentes y económicas.",
				Siguiente = "cierre_nivel",
			},
			-- ── 7. CIERRE DEL NIVEL ─────────────────────────────────────────
			{
				Id        = "cierre_nivel",
				Numero    = 7,
				Actor     = "Carlos",
				Expresion = "Extasiado",
				Texto     = "¡Gran trabajo, Tocino! Villa Conexa ahora sabe conectar sus nodos con el mínimo cable posible gracias a Prim. En el próximo nivel usaremos todo esto en un reto aún mayor. ¡Nos vemos pronto! 🎉",
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
