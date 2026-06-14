-- ReplicatedStorage/DialogoData/DialogosNivel2/Nivel2_BarrioOeste.lua
-- Diálogo de la Zona 2 (Barrio Oeste) — Nivel 2: La Ruta Más Corta
-- Concepto: Dijkstra elige la ruta más barata, no la de menos saltos.

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
local aliasTunelS   = nombres["Tunel_Sur_z2"]     or "Avenida Sur"
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

-- ════════════════════════════════════════════════════════════════════
-- DATOS DEL DIÁLOGO
-- ════════════════════════════════════════════════════════════════════

local DIALOGOS = {
	["Nivel2_BarrioOeste"] = {
		Zona  = "Zona_BarrioOeste_2",
		Nivel = 2,
		Lineas = {

			-- ── 1. INTRODUCCIÓN ─────────────────────────────────────────
			{
				Id        = "intro_barrio",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "Llegamos al Barrio Oeste. Desde el " .. aliasCruce .. " hay dos caminos hacia el " .. aliasPuente .. ". Uno parece directo, pero Dijkstra no se deja engañar por la apariencia: suma los metros y elige el más barato.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					enfocarNodo("Cruce_z1", { altura = 30, angulo = 62, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Cruce_z1", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("Cruce_z1", aliasCruce)
					EfectosDialogo.resaltarNodo("Tunel_Norte_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Tunel_Sur_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Puente_z2", "ADYACENTE")
				end,
				Siguiente = "ruta_norte",
			},

			-- ── 2. RUTA NORTE ───────────────────────────────────────────
			{
				Id        = "ruta_norte",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Mira la ruta Norte: " .. aliasCruce .. " → " .. aliasTunelN .. " → " .. aliasCisterna .. " → " .. aliasPuente .. ". Tiene 3 saltos, pero sus pesos son 2 + 4 + 1 = 7 metros. Eso cuesta $" .. costo(7) .. ".",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					enfocarGrupo({"Cruce_z1", "Tunel_Norte_z2", "Cisterna_z2", "Puente_z2"}, { altura = 28, angulo = 60, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Cruce_z1", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Tunel_Norte_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Cisterna_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Puente_z2", "EXITO")
					task.delay(0.3, function()
						EfectosDialogo.mostrarArista("Cruce_z1", "Tunel_Norte_z2", "SELECCIONADO", { sinParticulas = true })
						EfectosDialogo.mostrarArista("Tunel_Norte_z2", "Cisterna_z2", "SELECCIONADO", { sinParticulas = true })
						EfectosDialogo.mostrarArista("Cisterna_z2", "Puente_z2", "SELECCIONADO", { sinParticulas = true })
					end)
					task.delay(0.6, function()
						EfectosDialogo.mostrarLabel("Cruce_z1", "0 m")
						EfectosDialogo.mostrarLabel("Tunel_Norte_z2", "2 m")
						EfectosDialogo.mostrarLabel("Cisterna_z2", "6 m")
						EfectosDialogo.mostrarLabel("Puente_z2", "7 m")
					end)
				end,
				Siguiente = "ruta_sur",
			},

			-- ── 3. RUTA SUR ─────────────────────────────────────────────
			{
				Id        = "ruta_sur",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Ahora la ruta Sur: " .. aliasCruce .. " → " .. aliasTunelS .. " → " .. aliasPuente .. ". Solo 2 saltos, pero pesa 6 + 2 = 8 metros, es decir, $" .. costo(8) .. ". ¡Más corta en saltos, más cara en dinero!",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					enfocarGrupo({"Cruce_z1", "Tunel_Sur_z2", "Puente_z2"}, { altura = 28, angulo = 60, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Cruce_z1", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Tunel_Sur_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Puente_z2", "ERROR")
					task.delay(0.3, function()
						EfectosDialogo.mostrarArista("Cruce_z1", "Tunel_Sur_z2", "SELECCIONADO", { sinParticulas = true })
						EfectosDialogo.mostrarArista("Tunel_Sur_z2", "Puente_z2", "SELECCIONADO", { sinParticulas = true })
					end)
					task.delay(0.6, function()
						EfectosDialogo.mostrarLabel("Cruce_z1", "0 m")
						EfectosDialogo.mostrarLabel("Tunel_Sur_z2", "6 m")
						EfectosDialogo.mostrarLabel("Puente_z2", "8 m ✗")
					end)
				end,
				Siguiente = "comparacion",
			},

			-- ── 4. COMPARACIÓN ──────────────────────────────────────────
			{
				Id        = "comparacion",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Presentacion",
				Texto     = "Dijkstra elegirá la ruta Norte porque 7 metros < 8 metros. Esto demuestra que Dijkstra no siempre elige el camino con menos saltos: elige el camino con menor costo acumulado. Esa es la diferencia clave con BFS.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					enfocarGrupo({"Cruce_z1", "Tunel_Norte_z2", "Cisterna_z2", "Tunel_Sur_z2", "Puente_z2"}, { altura = 32, angulo = 58, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Cruce_z1", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Tunel_Norte_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Cisterna_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Puente_z2", "EXITO")
					EfectosDialogo.resaltarNodo("Tunel_Sur_z2", "ERROR")
					task.delay(0.4, function()
						EfectosDialogo.mostrarArista("Cruce_z1", "Tunel_Norte_z2", "SELECCIONADO", { sinParticulas = true })
						EfectosDialogo.mostrarArista("Tunel_Norte_z2", "Cisterna_z2", "SELECCIONADO", { sinParticulas = true })
						EfectosDialogo.mostrarArista("Cisterna_z2", "Puente_z2", "SELECCIONADO", { sinParticulas = true })
						EfectosDialogo.mostrarArista("Cruce_z1", "Tunel_Sur_z2", "ERROR", { sinParticulas = true })
						EfectosDialogo.mostrarArista("Tunel_Sur_z2", "Puente_z2", "ERROR", { sinParticulas = true })
					end)
					task.delay(0.8, function()
						EfectosDialogo.mostrarLabel("Tunel_Norte_z2", "Ruta barata ✓")
						EfectosDialogo.mostrarLabel("Tunel_Sur_z2", "Más saltos, más cara")
					end)
				end,
				Siguiente = "pregunta_ruta",
			},

			-- ── 5. PREGUNTA DE VALIDACIÓN ───────────────────────────────
			{
				Id        = "pregunta_ruta",
				Numero    = 5,
				Actor     = "Carlos",
				Expresion = "Curioso",
				Texto     = "Pregunta: desde el " .. aliasCruce .. " hasta el " .. aliasPuente .. ", ¿cuál es la ruta más barata según Dijkstra?",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					enfocarNodo("Puente_z2", { altura = 28, angulo = 60, duracion = 1.0 })
					EfectosDialogo.resaltarNodo("Puente_z2", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("Puente_z2", "¿Norte o Sur?")
				end,
				Opciones = {
					{ Texto = "Norte: Cruce → Avenida Norte → Cisterna → Puente (7 m, $" .. costo(7) .. ")", Siguiente = "resp_ruta_bien" },
					{ Texto = "Sur: Cruce → Avenida Sur → Puente (8 m, $" .. costo(8) .. ")", Siguiente = "resp_ruta_mal" },
					{ Texto = "Ambas cuestan lo mismo.", Siguiente = "resp_ruta_mal2" },
				},
			},

			-- ── 6a. RESPUESTA CORRECTA ──────────────────────────────────
			{
				Id        = "resp_ruta_bien",
				Numero    = 6,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "¡Correcto! La ruta Norte cuesta $" .. costo(7) .. ", mientras que la Sur cuesta $" .. costo(8) .. ". Dijkstra siempre elige la más barata, aunque tenga más saltos.",
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

			-- ── 6b. RESPUESTA INCORRECTA 1 ──────────────────────────────
			{
				Id        = "resp_ruta_mal",
				Numero    = 6,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No. La ruta Sur es más cara: 6 + 2 = 8 metros ($" .. costo(8) .. "). Aunque tiene menos saltos, Dijkstra descarta el camino más costoso y se queda con el Norte.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					enfocarGrupo({"Cruce_z1", "Tunel_Sur_z2", "Puente_z2"}, { altura = 26, angulo = 60, duracion = 1.0 })
					EfectosDialogo.resaltarNodo("Cruce_z1", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Tunel_Sur_z2", "ERROR")
					EfectosDialogo.resaltarNodo("Puente_z2", "ERROR")
					EfectosDialogo.mostrarLabel("Tunel_Sur_z2", "6 m")
					EfectosDialogo.mostrarLabel("Puente_z2", "8 m ✗")
				end,
				Opciones = { { Texto = "Entendido", Siguiente = "relajacion_barrio" } },
			},

			-- ── 6c. RESPUESTA INCORRECTA 2 ──────────────────────────────
			{
				Id        = "resp_ruta_mal2",
				Numero    = 6,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No, no cuestan lo mismo. La ruta Norte suma 7 metros ($" .. costo(7) .. ") y la Sur suma 8 metros ($" .. costo(8) .. "). Dijkstra distingue esas diferencias y elige la menor.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					enfocarNodo("Cruce_z1", { altura = 28, angulo = 60, duracion = 1.0 })
					EfectosDialogo.resaltarNodo("Cruce_z1", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("Cruce_z1", "Norte 7 m ≠ Sur 8 m")
				end,
				Opciones = { { Texto = "Entendido", Siguiente = "relajacion_barrio" } },
			},

			-- ── 7. RELAJACIÓN EN ACCIÓN ─────────────────────────────────
			{
				Id        = "relajacion_barrio",
				Numero    = 7,
				Actor     = "Carlos",
				Expresion = "Pensativo",
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

			-- ── 8. INSTRUCCIÓN FINAL ────────────────────────────────────
			{
				Id        = "instruccion_final",
				Numero    = 8,
				Actor     = "Sistema",
				Texto     = "Conecta el Barrio Oeste eligiendo la ruta más barata. Recuerda: Dijkstra prioriza el costo acumulado, no los saltos. Abre el Panel de Análisis (Tecla Tab) para ver el algoritmo paso a paso.",
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
