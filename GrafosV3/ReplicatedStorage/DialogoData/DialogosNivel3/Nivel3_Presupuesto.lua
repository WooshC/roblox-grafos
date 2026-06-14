-- ReplicatedStorage/DialogoData/DialogosNivel3/Nivel3_Presupuesto.lua
-- Diálogo de la Zona 1 (Oficina de Presupuesto) — Nivel 3: El Árbol de Expansión Mínima
-- Concepto: Introducción a MST, el algoritmo de Prim y gestión del presupuesto.

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
local aliasPNorte   = nombres["Poste_Norte_z1"]     or "Poste Norte"
local aliasPSur     = nombres["Poste_Sur_z1"]       or "Poste Sur"
local aliasCruceN   = nombres["Cruce_Norte_z2"]     or "Cruce Norte"
local aliasMercado  = nombres["Mercado_z2"]         or "Mercado Central"
local aliasPlaza    = nombres["Plaza_z2"]           or "Plaza Central"

-- ════════════════════════════════════════════════════════════════════
-- DATOS DEL DIÁLOGO
-- ════════════════════════════════════════════════════════════════════

local DIALOGOS = {
	["Nivel3_Presupuesto"] = {
		Zona  = "Zona_Presupuesto_1",
		Nivel = 3,
		Lineas = {
			-- ── 1. PROBLEMA DEL PRESUPUESTO ─────────────────────────────────
			{
				Id        = "intro_presupuesto",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Preocupado",
				Texto     = "Tocino, el alcalde nos dio un presupuesto ajustado: $" .. tostring(presupuesto) .. " para tender cables. Cada metro cuesta $" .. tostring(costoPorMetro) .. ", así que cada conexión pesa en el bolsillo. Necesitamos conectar el pueblo gastando el mínimo cable posible. 🪙",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Gen_Bodega_z1", { altura = 25, angulo = 65, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Gen_Bodega_z1", "SELECCIONADO")
				end,
				Siguiente = "concepto_mst",
			},
			-- ── 2. ¿QUÉ ES MST? ─────────────────────────────────────────────
			{
				Id        = "concepto_mst",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Presentacion",
				Texto     = "Este problema se llama Árbol de Expansión Mínima, o MST. Significa elegir un conjunto de aristas que conecten TODOS los nodos sin formar ciclos y con el menor costo total. Piensa en él como el plan de tendido más ahorrativo.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Gen_Bodega_z1", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Poste_Norte_z1", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Poste_Sur_z1", "ADYACENTE")
				end,
				Siguiente = "diferencia_dijkstra",
			},
			-- ── 3. DIJKSTRA VS PRIM ─────────────────────────────────────────
			{
				Id        = "diferencia_dijkstra",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "No lo confundas con Dijkstra. Dijkstra busca el camino más corto desde un origen a un destino: suma distancias desde el origen. Prim no tiene destino: su meta es conectar todos los nodos al menor costo total. En Prim, la 'key' de cada nodo es el peso de la arista que lo conecta al árbol ya construido.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Gen_Bodega_z1", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("Gen_Bodega_z1", "Raíz")
					EfectosDialogo.mostrarArista("Gen_Bodega_z1", "Poste_Norte_z1", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Gen_Bodega_z1", "Poste_Sur_z1", "ADYACENTE", { sinParticulas = true })
					EfectosDialogo.mostrarLabel("Poste_Norte_z1", "key = 4")
					EfectosDialogo.mostrarLabel("Poste_Sur_z1", "key = 7")
				end,
				Siguiente = "concepto_prim",
			},
			-- ── 4. REGLA DE PRIM ────────────────────────────────────────────
			{
				Id        = "concepto_prim",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Presentacion",
				Texto     = "Prim es un algoritmo 'codicioso'. Empieza en un nodo raíz —aquí la " .. aliasBodega .. "— y hace crecer el árbol paso a paso. En cada paso elige la arista de MENOR peso que conecte un nodo NUEVO al árbol que ya tenemos. 🌱",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Gen_Bodega_z1", "SELECCIONADO")
					EfectosDialogo.mostrarArista("Gen_Bodega_z1", "Poste_Norte_z1", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Gen_Bodega_z1", "Poste_Sur_z1", "ADYACENTE", { sinParticulas = true })
					EfectosDialogo.mostrarLabel("Poste_Norte_z1", "4 m")
					EfectosDialogo.mostrarLabel("Poste_Sur_z1", "7 m")
				end,
				Siguiente = "ejemplo_presupuesto",
			},
			-- ── 5. EJEMPLO PARCIAL ──────────────────────────────────────────
			{
				Id        = "ejemplo_presupuesto",
				Numero    = 5,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Mira este ejemplo parcial: conectar " .. aliasBodega .. " → " .. aliasPNorte .. " (4 m) → " .. aliasCruceN .. " (3 m) → " .. aliasMercado .. " (3 m) → " .. aliasPlaza .. " (2 m) cuesta 4+3+3+2 = 12 metros, es decir $6000. Prim te ayuda a encontrar estas elecciones baratas primero, sin derrochar cable.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.mostrarArista("Gen_Bodega_z1", "Poste_Norte_z1", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Poste_Norte_z1", "Cruce_Norte_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Cruce_Norte_z2", "Mercado_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Mercado_z2", "Plaza_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.resaltarNodo("Gen_Bodega_z1", "EXITO")
					EfectosDialogo.resaltarNodo("Poste_Norte_z1", "EXITO")
					EfectosDialogo.resaltarNodo("Cruce_Norte_z2", "EXITO")
					EfectosDialogo.resaltarNodo("Mercado_z2", "EXITO")
					EfectosDialogo.resaltarNodo("Plaza_z2", "EXITO")
					ServicioCamara.moverHaciaObjetivo("Plaza_z2", { altura = 35, angulo = 70, duracion = 1.5 })
				end,
				Siguiente = "pregunta_prim",
			},
			-- ── 6. PREGUNTA DE OPCIÓN MÚLTIPLE ──────────────────────────────
			{
				Id        = "pregunta_prim",
				Numero    = 6,
				Actor     = "Carlos",
				Expresion = "Curioso",
				Texto     = "Pregunta rápida: ¿cuál es la diferencia principal entre Dijkstra y Prim?",
				Opciones = {
					{ Texto = "Dijkstra busca el camino más corto origen-destino; Prim conecta todos los nodos con el menor costo total.", Siguiente = "resp_prim_bien" },
					{ Texto = "Ambos hacen exactamente lo mismo, solo cambian los nombres.", Siguiente = "resp_prim_mal" },
					{ Texto = "Dijkstra solo sirve para grafos no ponderados.", Siguiente = "resp_prim_mal2" },
				},
			},
			-- Respuesta correcta
			{
				Id        = "resp_prim_bien",
				Numero    = 7,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "¡Exacto! Dijkstra resuelve 'cómo llegar de A a B lo más barato posible'. Prim resuelve 'cómo conectar todos los puntos lo más barato posible'. Son primos, pero con objetivos distintos. 🎯",
				Evento = function()
					local jugador = game:GetService("Players").LocalPlayer
					if jugador then
						local puntajeActual = jugador:GetAttribute("PuntajeDialogo") or 0
						jugador:SetAttribute("PuntajeDialogo", puntajeActual + 100)
					end
					notificarRespuestaCorrecta()
				end,
				Opciones = { { Texto = "Continuar", Siguiente = "presupuesto_instruccion" } },
			},
			-- Respuesta incorrecta 1
			{
				Id        = "resp_prim_mal",
				Numero    = 7,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Casi, pero no. Dijkstra y Prim sí se parecen en que usan una estructura greedy, pero resuelven problemas distintos. Dijkstra busca camino mínimo origen-destino; Prim busca el árbol de expansión mínima que conecte todo el grafo.",
				Opciones = { { Texto = "Entendido", Siguiente = "presupuesto_instruccion" } },
			},
			-- Respuesta incorrecta 2
			{
				Id        = "resp_prim_mal2",
				Numero    = 7,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No exactamente. Dijkstra está pensado precisamente para grafos ponderados con pesos no negativos. Su diferencia con Prim es el objetivo: Dijkstra mide distancia acumulada desde un origen, Prim mide el peso de la arista que conecta al árbol.",
				Opciones = { { Texto = "Entendido", Siguiente = "presupuesto_instruccion" } },
			},
			-- ── 8. GESTIÓN DEL PRESUPUESTO ──────────────────────────────────
			{
				Id        = "presupuesto_instruccion",
				Numero    = 8,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Ahora, la parte práctica. Tienes $" .. tostring(presupuesto) .. " al empezar y cada metro gasta $" .. tostring(costoPorMetro) .. ". Prim minimiza los metros de cable, pero en una misión real debes decidir qué conexiones son prioritarias. No siempre podrás tender todo de golpe; elige primero lo que más nodos ilumine por menos dinero.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Gen_Bodega_z1", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Poste_Norte_z1", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Poste_Sur_z1", "ADYACENTE")
					ServicioCamara.moverHaciaObjetivo("Gen_Bodega_z1", { altura = 35, angulo = 70, duracion = 1.5 })
				end,
				Siguiente = "instruccion_final",
			},
			-- ── 9. INSTRUCCIÓN FINAL ────────────────────────────────────────
			{
				Id        = "instruccion_final",
				Numero    = 9,
				Actor     = "Sistema",
				Texto     = "Presupuesto inicial: $" .. tostring(presupuesto) .. ". Costo por metro: $" .. tostring(costoPorMetro) .. ". Planifica con Prim en el Panel de Análisis (Tecla Tab). Elige siempre el cable más barato que conecte un nodo nuevo a la red. 🎮",
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
