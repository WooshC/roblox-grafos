-- ReplicatedStorage/DialogoData/DialogosNivel2/Nivel2_BarrioOeste.lua
-- Diálogo de la Zona 2 (Barrio Oeste) — Nivel 2: La Ruta Más Corta
-- Concepto: Dijkstra elige la ruta más barata, no la de menos saltos.
-- Lore: el Alcalde propone una ruta "directa" (menos saltos), pero Carlos
-- demuestra que la ruta con más saltos puede ser más económica.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LevelsConfig   = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("LevelsConfig"))
local EfectosDialogo = require(ReplicatedStorage:WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
local ServicioCamara = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("ServicioCamara"))
local Utilidades = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("Utilidades"))

local function notificarRespuestaCorrecta()
	Utilidades.notificarDialogoCorrecto()
end

-- ════════════════════════════════════════════════════════════════════
-- ALIASES Y HELPERS
-- ════════════════════════════════════════════════════════════════════

local nombres = LevelsConfig[2].NombresNodos

local aliasCruce    = nombres["Cruce_z1"]         or "Cruce"
local aliasTunelN   = nombres["Tunel_Norte_z2"]   or "Avenida Norte"
local aliasTunelS   = nombres["Paso_Sur_z2"]      or "Avenida Sur"
local aliasCisterna = nombres["Cisterna_z2"]      or "Cisterna"
local aliasAlmacen  = nombres["Almacen_z2"]       or "Almacén"
local aliasPuente   = nombres["Puente_z2"]        or "Puente"

local COSTO_POR_METRO = LevelsConfig[2].CostoPorMetro or 500

local function costo(peso)
	return peso * COSTO_POR_METRO
end

local function enfocarNodo(nombreNodo, opciones)
	ServicioCamara.moverHaciaObjetivo(nombreNodo, opciones or { altura = 26, angulo = 60, duracion = 1.2 })
end

local function enfocarGrupo(nombresNodos, opciones)
	local nivel = workspace:FindFirstChild("NivelActual")
	if not nivel then return end

	local function getPos(nombre)
		local obj = nivel:FindFirstChild(nombre, true)
		if not obj then return nil end
		if obj:IsA("Model") then
			local s = obj:FindFirstChild("Selector")
			if s then
				if s:IsA("BasePart") then return s.Position end
				local bp = s:FindFirstChildOfClass("BasePart")
				if bp then return bp.Position end
			end
			return obj:GetPivot().Position
		elseif obj:IsA("BasePart") then
			return obj.Position
		end
		return nil
	end

	local suma  = Vector3.new(0, 0, 0)
	local count = 0
	for _, nom in ipairs(nombresNodos) do
		local p = getPos(nom)
		if p then
			suma  = suma + p
			count = count + 1
		end
	end

	if count == 0 then return end

	ServicioCamara.moverHaciaObjetivo(suma / count, {
		altura   = opciones and opciones.altura   or 30,
		angulo   = opciones and opciones.angulo   or 62,
		duracion = opciones and opciones.duracion or 1.2,
	})
end

-- Recorre visualmente una ruta, moviendo la cámara de nodo en nodo para que
-- cada salto se vea en lugar de limitarse a enumerarlo en el texto.
local recorridoActual = 0
local function recorrerRuta(nodos, pesosAcumulados, estadoFinal)
	recorridoActual = recorridoActual + 1
	local idRecorrido = recorridoActual

	task.spawn(function()
		for indice, nodo in ipairs(nodos) do
			if idRecorrido ~= recorridoActual then return end

			enfocarNodo(nodo, { altura = 22, angulo = 58, duracion = 1.3 })
			EfectosDialogo.resaltarNodo(
				nodo,
				indice == #nodos and (estadoFinal or "EXITO") or "SELECCIONADO"
			)
			EfectosDialogo.mostrarLabel(nodo, tostring(pesosAcumulados[indice]) .. " m")

			if indice > 1 then
				EfectosDialogo.mostrarArista(
					nodos[indice - 1],
					nodo,
					estadoFinal or "SELECCIONADO",
					{ sinParticulas = true }
				)
			end

			task.wait(1.55)
		end
	end)
end

-- ════════════════════════════════════════════════════════════════════
-- DATOS DEL DIÁLOGO
-- ════════════════════════════════════════════════════════════════════

local DIALOGOS = {
	["Nivel2_BarrioOeste"] = {
		Zona  = "Zona_BarrioOeste_2",
		Nivel = 2,
		Lineas = {

			-- ── 1. EL ALCALDE PROPONE UNA RUTA DIRECTA ─────────────────
			{
				Id        = "alcalde_ruta_directa",
				Numero    = 1,
				Actor     = "Alcalde",
				Expresion = "Sonriente",
				Texto     = "¡Por fin una zona donde todo es sencillo! Desde el " .. aliasCruce .. " hasta el " .. aliasPuente .. " se ve una avenida directa. Menos postes, menos complicaciones. ¿Qué más quieren? Conecten esa y dejen de dar vueltas.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					enfocarNodo("Cruce_z1", { altura = 30, angulo = 62, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Cruce_z1", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("Cruce_z1", aliasCruce)
					EfectosDialogo.resaltarNodo("Tunel_Norte_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Paso_Sur_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Puente_z2", "ADYACENTE")
				end,
				Siguiente = "carlos_duda",
			},

			-- ── 2. CARLOS DUDA DE LA PROPUESTA ─────────────────────────
			{
				Id        = "carlos_duda",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Señor Alcalde, en el Barrio Antiguo aprendimos que usted siempre prefiere las obras que se ven: más postes, más cables, más gasto. Pero una ruta 'directa' no siempre es la más barata. Vamos a comparar los números.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					enfocarGrupo({"Cruce_z1", "Tunel_Norte_z2", "Cisterna_z2", "Paso_Sur_z2", "Puente_z2"}, { altura = 32, angulo = 58, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Cruce_z1", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Tunel_Norte_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Paso_Sur_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Puente_z2", "ADYACENTE")
				end,
				Siguiente = "alcalde_defiende",
			},

			-- ── 3. EL ALCALDE SE DEFIENDE ──────────────────────────────
			{
				Id        = "alcalde_defiende",
				Numero    = 3,
				Actor     = "Alcalde",
				Expresion = "Codicioso",
				Texto     = "¡Mis obras son transparentes! La avenida directa es obvia: dos postes en línea recta. Cualquier ciudadano lo aprobaría. Si ustedes la descartan, estarán desperdiciando dinero público en zigzagueos innecesarios.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					enfocarGrupo({"Cruce_z1", "Paso_Sur_z2", "Puente_z2"}, { altura = 28, angulo = 60, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Cruce_z1", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Paso_Sur_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Puente_z2", "ADYACENTE")
				end,
				Siguiente = "ruta_norte",
			},

			-- ── 4. RUTA NORTE ───────────────────────────────────────────
			{
				Id        = "ruta_norte",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Mira esta primera ruta. Tiene 3 saltos; observa cómo avanzamos de nodo en nodo. Sus pesos suman 2 + 4 + 1 = 7 metros, así que cuesta $" .. costo(7) .. ".",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					recorrerRuta(
						{"Cruce_z1", "Tunel_Norte_z2", "Cisterna_z2", "Puente_z2"},
						{0, 2, 6, 7},
						"EXITO"
					)
				end,
				Siguiente = "ruta_sur",
			},

			-- ── 5. RUTA SUR ─────────────────────────────────────────────
			{
				Id        = "ruta_sur",
				Numero    = 5,
				Actor     = "Carlos",
				Expresion = "Presentacion",
				Texto     = "Ahora mira esta otra ruta. Tiene solo 2 saltos; sigamos otra vez la cámara nodo por nodo. Sus pesos suman 6 + 2 = 8 metros, es decir, $" .. costo(8) .. ". ¡Menos saltos, pero más dinero!",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					recorrerRuta(
						{"Cruce_z1", "Paso_Sur_z2", "Puente_z2"},
						{0, 6, 8},
						"ERROR"
					)
				end,
				Siguiente = "comparacion",
			},

			-- ── 6. COMPARACIÓN ──────────────────────────────────────────
			{
				Id        = "comparacion",
				Numero    = 6,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Dijkstra elegirá la ruta Norte porque 7 metros < 8 metros. Esto demuestra que Dijkstra no siempre elige el camino con menos saltos: elige el camino con menor costo acumulado. Esa es la diferencia clave con BFS.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					enfocarGrupo({"Cruce_z1", "Tunel_Norte_z2", "Cisterna_z2", "Paso_Sur_z2", "Puente_z2"}, { altura = 32, angulo = 58, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Cruce_z1", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Tunel_Norte_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Cisterna_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Puente_z2", "EXITO")
					EfectosDialogo.resaltarNodo("Paso_Sur_z2", "ERROR")
					task.delay(0.4, function()
						EfectosDialogo.mostrarArista("Cruce_z1", "Tunel_Norte_z2", "SELECCIONADO", { sinParticulas = true })
						EfectosDialogo.mostrarArista("Tunel_Norte_z2", "Cisterna_z2", "SELECCIONADO", { sinParticulas = true })
						EfectosDialogo.mostrarArista("Cisterna_z2", "Puente_z2", "SELECCIONADO", { sinParticulas = true })
						EfectosDialogo.mostrarArista("Cruce_z1", "Paso_Sur_z2", "ERROR", { sinParticulas = true })
						EfectosDialogo.mostrarArista("Paso_Sur_z2", "Puente_z2", "ERROR", { sinParticulas = true })
					end)
					task.delay(0.8, function()
						EfectosDialogo.mostrarLabel("Tunel_Norte_z2", "Ruta barata ✓")
						EfectosDialogo.mostrarLabel("Paso_Sur_z2", "Menos saltos, más cara")
					end)
				end,
				Siguiente = "pregunta_ruta",
			},

			-- ── 7. PREGUNTA DE VALIDACIÓN ───────────────────────────────
			{
				Id        = "pregunta_ruta",
				Numero    = 7,
				Actor     = "Carlos",
				Expresion = "Sonriente",
				Texto     = "Pregunta de Dijkstra: cuando dos rutas llegan al mismo destino, ¿cómo decide el algoritmo cuál conservar?",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					enfocarNodo("Puente_z2", { altura = 28, angulo = 60, duracion = 1.0 })
					EfectosDialogo.resaltarNodo("Puente_z2", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("Puente_z2", "¿Cómo decide Dijkstra?")
				end,
				Opciones = {
					{ Texto = "Conserva la ruta con menos saltos, aunque la suma de pesos sea mayor.", Siguiente = "resp_ruta_mal" },
					{ Texto = "Conserva la primera ruta descubierta y ya no vuelve a compararla.", Siguiente = "resp_ruta_mal2" },
					{ Texto = "Conserva la ruta con menor peso acumulado, aunque tenga más saltos.", Siguiente = "resp_ruta_bien" },
				},
			},

			-- ── 8a. RESPUESTA CORRECTA ──────────────────────────────────
			{
				Id        = "resp_ruta_bien",
				Numero    = 8,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "¡Correcto! Dijkstra compara el peso acumulado. Aquí conserva la ruta de 7 metros y descarta la de 8, aunque la primera tenga más saltos. Esa es la diferencia esencial frente a buscar solo el menor número de pasos.",
				Evento = function()
					local jugador = game:GetService("Players").LocalPlayer
					if jugador then
						local puntajeActual = jugador:GetAttribute("PuntajeDialogo") or 0
						jugador:SetAttribute("PuntajeDialogo", puntajeActual + 100)
					end
					notificarRespuestaCorrecta()
					EfectosDialogo.limpiarTodo()
					enfocarGrupo({"Cruce_z1", "Tunel_Norte_z2", "Cisterna_z2", "Puente_z2"}, { altura = 28, angulo = 60, duracion = 1.2 })
					EfectosDialogo.resaltarNodo("Cruce_z1", "EXITO")
					EfectosDialogo.resaltarNodo("Tunel_Norte_z2", "EXITO")
					EfectosDialogo.resaltarNodo("Cisterna_z2", "EXITO")
					EfectosDialogo.resaltarNodo("Puente_z2", "EXITO")
					task.delay(0.3, function()
						EfectosDialogo.mostrarArista("Cruce_z1", "Tunel_Norte_z2", "EXITO", { sinParticulas = true })
						EfectosDialogo.mostrarArista("Tunel_Norte_z2", "Cisterna_z2", "EXITO", { sinParticulas = true })
						EfectosDialogo.mostrarArista("Cisterna_z2", "Puente_z2", "EXITO", { sinParticulas = true })
					end)
				end,
				Opciones = { { Texto = "Continuar", Siguiente = "relajacion_barrio" } },
			},

			-- ── 8b. RESPUESTA INCORRECTA 1 ──────────────────────────────
			{
				Id        = "resp_ruta_mal",
				Numero    = 8,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No. Dijkstra no minimiza la cantidad de saltos: minimiza el peso acumulado. Por eso descarta la ruta de 2 saltos que pesa 8 y conserva la ruta de 3 saltos que pesa 7.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					enfocarGrupo({"Cruce_z1", "Paso_Sur_z2", "Puente_z2"}, { altura = 26, angulo = 60, duracion = 1.0 })
					EfectosDialogo.resaltarNodo("Cruce_z1", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Paso_Sur_z2", "ERROR")
					EfectosDialogo.resaltarNodo("Puente_z2", "ERROR")
					EfectosDialogo.mostrarLabel("Paso_Sur_z2", "6 m")
					EfectosDialogo.mostrarLabel("Puente_z2", "8 m ✗")
				end,
				Opciones = { { Texto = "Entendido", Siguiente = "relajacion_barrio" } },
			},

			-- ── 8c. RESPUESTA INCORRECTA 2 ──────────────────────────────
			{
				Id        = "resp_ruta_mal2",
				Numero    = 8,
				Actor     = "Carlos",
				Expresion = "Enojado",
				Texto     = "No. Dijkstra puede mejorar una distancia que descubrió antes. Cada vez que encuentra un camino más barato, actualiza el costo conocido mediante la relajación.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					enfocarNodo("Cruce_z1", { altura = 28, angulo = 60, duracion = 1.0 })
					EfectosDialogo.resaltarNodo("Cruce_z1", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("Cruce_z1", "Compara y actualiza")
				end,
				Opciones = { { Texto = "Entendido", Siguiente = "relajacion_barrio" } },
			},

			-- ── 9. RELAJACIÓN EN ACCIÓN ─────────────────────────────────
			{
				Id        = "relajacion_barrio",
				Numero    = 9,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Fíjate cómo funciona la relajación: al llegar al " .. aliasPuente .. " por primera vez desde el Sur, cuesta 8. Pero al encontrar el camino por el Norte, cuesta 7. Como 7 < 8, ¡actualizamos el costo mínimo del Puente!",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					enfocarNodo("Puente_z2", { altura = 26, angulo = 60, duracion = 1.0 })
					EfectosDialogo.resaltarNodo("Puente_z2", "SELECCIONADO")
					EfectosDialogo.blink("Puente_z2", "SELECCIONADO", 4)
					task.delay(0.3, function()
						EfectosDialogo.mostrarLabel("Puente_z2", "8 m → 7 m")
					end)
				end,
				Siguiente = "instruccion_final",
			},

			-- ── 10. INSTRUCCIÓN FINAL ────────────────────────────────────
			{
				Id        = "instruccion_final",
				Numero    = 10,
				Actor     = "Sistema",
				Texto     = "Conecta el Barrio Oeste eligiendo la ruta más barata. Recuerda: Dijkstra prioriza el costo acumulado, no los saltos. Abre el Panel de Análisis con la tecla T para ver el algoritmo paso a paso.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.restaurar(1.2)
				end,
				Siguiente = "FIN",
			},
		},

		Metadata = {
			TiempoDeEspera      = 0.5,
			VelocidadTypewriter = 0.03,
			PuedeOmitir         = true,
			OcultarHUD          = true,
			UsarTTS             = true,
		},

		Configuracion = {
			bloquearMovimiento = true,
			bloquearSalto      = true,
			apuntarCamara      = true,
			ocultarTechos      = true,
		},

		EventoSaltar = function()
			EfectosDialogo.limpiarTodo()
			ServicioCamara.restaurar(0)
		end,
	},
}

return DIALOGOS
