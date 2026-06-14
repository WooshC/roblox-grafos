-- ReplicatedStorage/DialogoData/DialogosNivel3/Nivel3_Rutas.lua
-- Diálogo de la Zona 2 (Rutas de Suministro) — Nivel 3: El Árbol de Expansión Mínima
-- Concepto: Prim paso a paso, regla del corte y elección de aristas mínimas.

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
local aliasCruceS   = nombres["Cruce_Sur_z2"]       or "Cruce Sur"
local aliasMercado  = nombres["Mercado_z2"]         or "Mercado Central"
local aliasTaller   = nombres["Taller_z2"]          or "Taller Municipal"
local aliasPlaza    = nombres["Plaza_z2"]           or "Plaza Central"

-- ════════════════════════════════════════════════════════════════════
-- DATOS DEL DIÁLOGO
-- ════════════════════════════════════════════════════════════════════

local DIALOGOS = {
	["Nivel3_Rutas"] = {
		Zona  = "Zona_Rutas_2",
		Nivel = 3,
		Lineas = {
			-- ── 1. INTRODUCCIÓN A LAS RUTAS ─────────────────────────────────
			{
				Id        = "intro_rutas",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "Bienvenido a las Rutas de Suministro. Aquí vamos a ver cómo Prim elige cables. Cada número en el mapa representa los metros de cable que necesitas para tender entre dos puntos. 📏",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Cruce_Norte_z2", { altura = 28, angulo = 60, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Cruce_Norte_z2", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Mercado_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Taller_z2", "ADYACENTE")
					EfectosDialogo.mostrarArista("Cruce_Norte_z2", "Mercado_z2", "ADYACENTE", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Cruce_Norte_z2", "Taller_z2", "ADYACENTE", { sinParticulas = true })
				end,
				Siguiente = "raiz_prim",
			},
			-- ── 2. PASO 1: ELEGIR LA RAÍZ ───────────────────────────────────
			{
				Id        = "raiz_prim",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Presentacion",
				Texto     = "Paso 1 de Prim: elegimos la raíz. En este nivel siempre partimos de la " .. aliasBodega .. ". Ese nodo ya forma parte del árbol que vamos a hacer crecer.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Gen_Bodega_z1", { altura = 26, angulo = 60, duracion = 1.2 })
					EfectosDialogo.resaltarNodo("Gen_Bodega_z1", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("Gen_Bodega_z1", "en MST")
				end,
				Siguiente = "corte_inicial",
			},
			-- ── 3. PASO 2: EL CORTE ─────────────────────────────────────────
			{
				Id        = "corte_inicial",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "Paso 2: miramos todas las aristas que cruzan desde el árbol al resto del grafo. Al inicio solo salen de la " .. aliasBodega .. ": hacia el " .. aliasPNorte .. " (4 m) y el " .. aliasPSur .. " (7 m).",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Gen_Bodega_z1", "SELECCIONADO")
					EfectosDialogo.mostrarArista("Gen_Bodega_z1", "Poste_Norte_z1", "ADYACENTE", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Gen_Bodega_z1", "Poste_Sur_z1", "ADYACENTE", { sinParticulas = true })
					EfectosDialogo.mostrarLabel("Poste_Norte_z1", "4 m")
					EfectosDialogo.mostrarLabel("Poste_Sur_z1", "7 m")
				end,
				Siguiente = "primera_elec",
			},
			-- ── 4. PRIMERA ELECCIÓN ─────────────────────────────────────────
			{
				Id        = "primera_elec",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Extasiado",
				Texto     = "Paso 3: elegimos la arista de MENOR peso. El " .. aliasPNorte .. " gana con 4 metros. Ahora el árbol tiene la " .. aliasBodega .. " y el " .. aliasPNorte .. ".",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Gen_Bodega_z1", "EXITO")
					EfectosDialogo.resaltarNodo("Poste_Norte_z1", "SELECCIONADO")
					EfectosDialogo.mostrarArista("Gen_Bodega_z1", "Poste_Norte_z1", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Gen_Bodega_z1", "Poste_Sur_z1", "ADYACENTE", { sinParticulas = true })
					EfectosDialogo.mostrarLabel("Poste_Norte_z1", "en MST")
					EfectosDialogo.mostrarLabel("Poste_Sur_z1", "key = 7")
				end,
				Siguiente = "segunda_elec",
			},
			-- ── 5. SEGUNDA ELECCIÓN ─────────────────────────────────────────
			{
				Id        = "segunda_elec",
				Numero    = 5,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Volvemos a revisar el corte. Desde el árbol salen: " .. aliasBodega .. " → " .. aliasPSur .. " (7 m) y " .. aliasPNorte .. " → " .. aliasCruceN .. " (3 m). La más barata es el " .. aliasCruceN .. ", así que lo añadimos.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Gen_Bodega_z1", "EXITO")
					EfectosDialogo.resaltarNodo("Poste_Norte_z1", "EXITO")
					EfectosDialogo.resaltarNodo("Cruce_Norte_z2", "SELECCIONADO")
					EfectosDialogo.mostrarArista("Gen_Bodega_z1", "Poste_Norte_z1", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Poste_Norte_z1", "Cruce_Norte_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Gen_Bodega_z1", "Poste_Sur_z1", "ADYACENTE", { sinParticulas = true })
					EfectosDialogo.mostrarLabel("Cruce_Norte_z2", "en MST")
					EfectosDialogo.mostrarLabel("Poste_Sur_z1", "key = 7")
				end,
				Siguiente = "tercera_elec",
			},
			-- ── 6. TERCERA ELECCIÓN ─────────────────────────────────────────
			{
				Id        = "tercera_elec",
				Numero    = 6,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "Sigamos. Desde el árbol actual, las opciones baratas son " .. aliasCruceN .. " → " .. aliasMercado .. " (3 m) y " .. aliasCruceN .. " → " .. aliasTaller .. " (8 m). Prim elige el " .. aliasMercado .. " (3 m). Nota: no importa cuánto cuesten los metros desde la raíz; importa solo el peso de la arista que conecta al árbol.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Gen_Bodega_z1", "EXITO")
					EfectosDialogo.resaltarNodo("Poste_Norte_z1", "EXITO")
					EfectosDialogo.resaltarNodo("Cruce_Norte_z2", "EXITO")
					EfectosDialogo.resaltarNodo("Mercado_z2", "SELECCIONADO")
					EfectosDialogo.mostrarArista("Poste_Norte_z1", "Cruce_Norte_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Cruce_Norte_z2", "Mercado_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Cruce_Norte_z2", "Taller_z2", "ADYACENTE", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Mercado_z2", "Plaza_z2", "ADYACENTE", { sinParticulas = true })
					EfectosDialogo.mostrarLabel("Mercado_z2", "en MST")
					EfectosDialogo.mostrarLabel("Taller_z2", "key = 8")
					EfectosDialogo.mostrarLabel("Plaza_z2", "key = 2")
				end,
				Siguiente = "pregunta_corte",
			},
			-- ── 7. PREGUNTA DE OPCIÓN MÚLTIPLE ──────────────────────────────
			{
				Id        = "pregunta_corte",
				Numero    = 7,
				Actor     = "Carlos",
				Expresion = "Curioso",
				Texto     = "El árbol ahora tiene la " .. aliasBodega .. ", el " .. aliasPNorte .. ", el " .. aliasCruceN .. " y el " .. aliasMercado .. ". ¿Qué arista tenderá Prim a continuación?",
				Opciones = {
					{ Texto = aliasMercado .. " → " .. aliasPlaza .. " (2 m)", Siguiente = "resp_corte_bien" },
					{ Texto = aliasCruceN .. " → " .. aliasTaller .. " (8 m)", Siguiente = "resp_corte_mal" },
					{ Texto = aliasPlaza .. " → Centro de Control (5 m)", Siguiente = "resp_corte_mal2" },
				},
			},
			-- Respuesta correcta
			{
				Id        = "resp_corte_bien",
				Numero    = 8,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "¡Correcto! La arista más barata que conecta un nodo nuevo al árbol es " .. aliasMercado .. " → " .. aliasPlaza .. " con solo 2 metros. Prim siempre elige la opción de menor peso en el corte, sin importar la distancia desde la raíz.",
				Evento = function()
					local jugador = game:GetService("Players").LocalPlayer
					if jugador then
						local puntajeActual = jugador:GetAttribute("PuntajeDialogo") or 0
						jugador:SetAttribute("PuntajeDialogo", puntajeActual + 100)
					end
					notificarRespuestaCorrecta()
				end,
				Opciones = { { Texto = "Continuar", Siguiente = "paso_cuatro" } },
			},
			-- Respuesta incorrecta 1
			{
				Id        = "resp_corte_mal",
				Numero    = 8,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No exactamente. " .. aliasCruceN .. " → " .. aliasTaller .. " cuesta 8 metros, mucho más que otras opciones disponibles. Prim nunca elegiría una arista cara mientras haya una más barata que conecte un nodo nuevo.",
				Opciones = { { Texto = "Entendido", Siguiente = "paso_cuatro" } },
			},
			-- Respuesta incorrecta 2
			{
				Id        = "resp_corte_mal2",
				Numero    = 8,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Casi, pero la " .. aliasPlaza .. " aún no está en el árbol, así que no puedes tender desde ella todavía. Prim solo considera aristas que unan un nodo DENTRO del árbol con uno FUERA de él.",
				Opciones = { { Texto = "Entendido", Siguiente = "paso_cuatro" } },
			},
			-- ── 9. CONTINUACIÓN DEL EJEMPLO ─────────────────────────────────
			{
				Id        = "paso_cuatro",
				Numero    = 9,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "Si seguimos, la " .. aliasPlaza .. " se une por 2 metros. Después, desde la red podríamos elegir " .. aliasPlaza .. " → " .. aliasTaller .. " (1 m), luego " .. aliasPlaza .. " → Centro de Control (5 m)... Siempre la arista más barata que traiga un nodo nuevo. Esa es la magia de Prim. ✨",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Gen_Bodega_z1", "EXITO")
					EfectosDialogo.resaltarNodo("Poste_Norte_z1", "EXITO")
					EfectosDialogo.resaltarNodo("Cruce_Norte_z2", "EXITO")
					EfectosDialogo.resaltarNodo("Mercado_z2", "EXITO")
					EfectosDialogo.resaltarNodo("Plaza_z2", "SELECCIONADO")
					EfectosDialogo.mostrarArista("Mercado_z2", "Plaza_z2", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Plaza_z2", "Taller_z2", "ADYACENTE", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Plaza_z2", "Centro_Control_z3", "ADYACENTE", { sinParticulas = true })
					EfectosDialogo.mostrarLabel("Plaza_z2", "en MST")
					EfectosDialogo.mostrarLabel("Taller_z2", "1 m")
					EfectosDialogo.mostrarLabel("Centro_Control_z3", "5 m")
				end,
				Siguiente = "consejo_presupuesto",
			},
			-- ── 10. CONSEJO DE PRESUPUESTO ──────────────────────────────────
			{
				Id        = "consejo_presupuesto",
				Numero    = 10,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Recuerda: Prim minimiza los metros totales de cable, pero dentro de cada misión debes administrar los $" .. tostring(presupuesto) .. ". No tires cables caros si unos más baratos iluminan más nodos. Prioriza las conexiones que más aporten por menos dinero.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Plaza_z2", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Taller_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Centro_Control_z3", "ADYACENTE")
					ServicioCamara.moverHaciaObjetivo("Plaza_z2", { altura = 30, angulo = 65, duracion = 1.5 })
				end,
				Siguiente = "instruccion_final",
			},
			-- ── 11. INSTRUCCIÓN FINAL ───────────────────────────────────────
			{
				Id        = "instruccion_final",
				Numero    = 11,
				Actor     = "Sistema",
				Texto     = "Conecta las rutas de suministro respetando el presupuesto. Usa el Panel de Análisis con Prim (Tecla Tab) para ver paso a paso cuál cable elegir. Recuerda: Prim prioriza la arista más barata que traiga un nodo nuevo a la red.",
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
