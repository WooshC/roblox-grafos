-- ReplicatedStorage/DialogoData/DialogosNivel2/Nivel2_BarrioOeste.lua
-- Diálogo de la Zona 2 (Barrio Oeste) — Nivel 2: La Gran Ciudad
-- Concepto: DFS paso a paso, Backtracking y comparación con BFS (Pila vs Cola).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LevelsConfig   = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("LevelsConfig"))
local EfectosDialogo = require(ReplicatedStorage:WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
local ServicioCamara = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("ServicioCamara"))

-- Evento para notificar respuestas correctas al servidor
local Utilidades = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("Utilidades"))

local function notificarRespuestaCorrecta()
	Utilidades.notificarDialogoCorrecto()
end

-- ════════════════════════════════════════════════════════════════════
-- ALIASES Y HELPERS
-- ════════════════════════════════════════════════════════════════════

local nombres = LevelsConfig[2].NombresNodos

local aliasGen      = nombres["Gen_Fabrica_z1"]   or "Generador"
local aliasEntrada  = nombres["Entrada_z1"]       or "Entrada"
local aliasCruce    = nombres["Cruce_z1"]         or "Cruce"
local aliasTunelN   = nombres["Tunel_Norte_z2"]   or "Túnel Norte"
local aliasTunelS   = nombres["Tunel_Sur_z2"]     or "Túnel Sur"
local aliasPuente   = nombres["Puente_z2"]        or "Puente"
local aliasCisterna = nombres["Cisterna_z2"]      or "Cisterna"
local aliasAlmacen  = nombres["Almacen_z2"]       or "Almacén"

local function enfocarNodo(nombreNodo, opciones)
	ServicioCamara.moverHaciaObjetivo(nombreNodo, opciones or { altura = 26, angulo = 60, duracion = 1.2 })
end

-- Calcula el centroide de varios nodos para enfocar un grupo
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
				Texto     = "Llegamos al Barrio Oeste. Mira cómo la red se divide desde el Cruce Principal en dos direcciones. DFS va a elegir un camino y seguirlo hasta el fondo.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					enfocarNodo("Cruce_z1", { altura = 30, angulo = 62, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Cruce_z1", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("Cruce_z1", aliasCruce)
					EfectosDialogo.resaltarNodo("Tunel_Norte_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Tunel_Sur_z2", "ADYACENTE")
				end,
				Siguiente = "concepto_pila",
			},

			-- ── 2. CONCEPTO: PILA LIFO ──────────────────────────────────
			{
				Id        = "concepto_pila",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Presentacion",
				Texto     = "DFS usa una PILA. Recuerda: LIFO — Last In, First Out. El último en entrar es el primero en salir. Es como una pila de platos: apilas uno arriba del otro, y siempre sacas el de arriba primero.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					enfocarNodo("Gen_Fabrica_z1", { altura = 26, angulo = 58, duracion = 1.2 })
					EfectosDialogo.resaltarNodo("Gen_Fabrica_z1", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("Gen_Fabrica_z1", "PILA: [ ]  (vacía)")
				end,
				Siguiente = "dfs_paso1_generador",
			},

			-- ── 3. PASO 1: APILAR GENERADOR ─────────────────────────────
			{
				Id        = "dfs_paso1_generador",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Paso 1: Apilamos el nodo inicial, el " .. aliasGen .. ". Ahora la pila tiene un solo elemento. Él está en el tope, así que es el siguiente que procesaremos.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					enfocarNodo("Gen_Fabrica_z1", { altura = 22, angulo = 65, duracion = 1.0 })
					EfectosDialogo.resaltarNodo("Gen_Fabrica_z1", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("Gen_Fabrica_z1", "PILA: [Gen]  ← TOPE")
					EfectosDialogo.blink("Gen_Fabrica_z1", "EXITO", 2)
				end,
				Siguiente = "dfs_paso2_desapila_gen",
			},

			-- ── 4. PASO 2: DESAPILAR GENERADOR, APILAR VECINOS ──────────
			{
				Id        = "dfs_paso2_desapila_gen",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Paso 2: Sacamos el " .. aliasGen .. " de la pila y lo marcamos visitado. Sus vecinos son " .. aliasEntrada .. " y " .. aliasCruce .. ". Los apilamos en orden. Como " .. aliasCruce .. " se apila después, queda arriba... ¡en el tope!",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					enfocarGrupo({"Gen_Fabrica_z1", "Entrada_z1", "Cruce_z1"}, { altura = 28, angulo = 60, duracion = 1.2 })
					EfectosDialogo.resaltarNodo("Gen_Fabrica_z1", "EXITO")
					EfectosDialogo.mostrarLabel("Gen_Fabrica_z1", aliasGen .. " ✓ visitado")
					task.delay(0.3, function()
						EfectosDialogo.mostrarArista("Gen_Fabrica_z1", "Entrada_z1", "SELECCIONADO", { sinParticulas = true })
						EfectosDialogo.mostrarArista("Gen_Fabrica_z1", "Cruce_z1", "SELECCIONADO", { sinParticulas = true })
					end)
					task.delay(0.6, function()
						EfectosDialogo.resaltarNodo("Entrada_z1", "ADYACENTE")
						EfectosDialogo.resaltarNodo("Cruce_z1", "SELECCIONADO")
						EfectosDialogo.mostrarLabel("Entrada_z1", "PILA: [Ent]  ← abajo")
						EfectosDialogo.mostrarLabel("Cruce_z1",   "PILA: [Ent, Cruce]  ← TOPE")
					end)
				end,
				Siguiente = "dfs_paso3_cruce",
			},

			-- ── 5. PASO 3: CRUCE ES EL TOPE ─────────────────────────────
			{
				Id        = "dfs_paso3_cruce",
				Numero    = 5,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Paso 3: El tope de la pila es " .. aliasCruce .. ", así que DFS lo saca y lo visita. Sus vecinos son " .. aliasTunelN .. " y " .. aliasTunelS .. ". Se apilan arriba. ¿Quién queda en el tope? El que se apiló último: " .. aliasTunelS .. ".",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					enfocarNodo("Cruce_z1", { altura = 24, angulo = 65, duracion = 1.0 })
					EfectosDialogo.resaltarNodo("Cruce_z1", "EXITO")
					EfectosDialogo.mostrarLabel("Cruce_z1", aliasCruce .. " ✓ visitado")
					task.delay(0.3, function()
						EfectosDialogo.mostrarArista("Cruce_z1", "Tunel_Norte_z2", "SELECCIONADO", { sinParticulas = true })
						EfectosDialogo.mostrarArista("Cruce_z1", "Tunel_Sur_z2", "SELECCIONADO", { sinParticulas = true })
					end)
					task.delay(0.6, function()
						EfectosDialogo.resaltarNodo("Tunel_Norte_z2", "ADYACENTE")
						EfectosDialogo.resaltarNodo("Tunel_Sur_z2", "SELECCIONADO")
						EfectosDialogo.mostrarLabel("Tunel_Norte_z2", "PILA: [Ent, T.Norte]  ← abajo")
						EfectosDialogo.mostrarLabel("Tunel_Sur_z2",   "PILA: [Ent, T.Norte, T.Sur]  ← TOPE")
					end)
				end,
				Siguiente = "dfs_paso4_tunel_sur",
			},

			-- ── 6. PASO 4: TÚNEL SUR ES EL TOPE ─────────────────────────
			{
				Id        = "dfs_paso4_tunel_sur",
				Numero    = 6,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Paso 4: DFS saca el tope: " .. aliasTunelS .. ". Lo visita y apila su vecino: " .. aliasPuente .. ". La pila ahora es: [Entrada, Túnel Norte, Puente]. Observa cómo DFS se adentra por la rama Sur sin mirar atrás.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					enfocarNodo("Tunel_Sur_z2", { altura = 22, angulo = 65, duracion = 1.0 })
					EfectosDialogo.resaltarNodo("Tunel_Sur_z2", "EXITO")
					EfectosDialogo.mostrarLabel("Tunel_Sur_z2", aliasTunelS .. " ✓ visitado")
					task.delay(0.3, function()
						EfectosDialogo.mostrarArista("Tunel_Sur_z2", "Puente_z2", "SELECCIONADO", { sinParticulas = true })
					end)
					task.delay(0.6, function()
						EfectosDialogo.resaltarNodo("Puente_z2", "SELECCIONADO")
						EfectosDialogo.mostrarLabel("Puente_z2", "PILA: [Ent, T.Norte, Puente]  ← TOPE")
					end)
				end,
				Siguiente = "dfs_paso5_puente",
			},

			-- ── 7. PASO 5: PUENTE ES EL TOPE ────────────────────────────
			{
				Id        = "dfs_paso5_puente",
				Numero    = 7,
				Actor     = "Carlos",
				Expresion = "Extasiado",
				Texto     = "Paso 5: Sacamos el " .. aliasPuente .. ". Desde aquí, DFS ve dos vecinos: la " .. aliasCisterna .. " y el " .. aliasAlmacen .. ". Ambos se apilan. El tope ahora es el " .. aliasAlmacen .. ", porque se apiló después. ¡La pila decide el camino!",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					enfocarNodo("Puente_z2", { altura = 22, angulo = 65, duracion = 1.0 })
					EfectosDialogo.resaltarNodo("Puente_z2", "EXITO")
					EfectosDialogo.mostrarLabel("Puente_z2", aliasPuente .. " ✓ visitado")
					task.delay(0.3, function()
						EfectosDialogo.mostrarArista("Puente_z2", "Cisterna_z2", "SELECCIONADO", { sinParticulas = true })
						EfectosDialogo.mostrarArista("Puente_z2", "Almacen_z2", "SELECCIONADO", { sinParticulas = true })
					end)
					task.delay(0.6, function()
						EfectosDialogo.resaltarNodo("Cisterna_z2", "ADYACENTE")
						EfectosDialogo.resaltarNodo("Almacen_z2", "SELECCIONADO")
						EfectosDialogo.mostrarLabel("Cisterna_z2", "PILA: [Ent, T.Norte, Cisterna]  ← abajo")
						EfectosDialogo.mostrarLabel("Almacen_z2",  "PILA: [Ent, T.Norte, Cist, Alm]  ← TOPE")
					end)
				end,
				Siguiente = "dfs_paso6_almacen",
			},

			-- ── 8. PASO 6: ALMACÉN ES EL TOPE ───────────────────────────
			{
				Id        = "dfs_paso6_almacen",
				Numero    = 8,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Paso 6: DFS saca el " .. aliasAlmacen .. ". Pero… ¡no tiene vecinos sin visitar! Es un callejón sin salida. ¿Qué hace la pila ahora? No puede avanzar, así que debe retroceder. Eso se llama BACKTRACKING.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					enfocarNodo("Almacen_z2", { altura = 20, angulo = 65, duracion = 1.0 })
					EfectosDialogo.resaltarNodo("Almacen_z2", "ERROR")
					EfectosDialogo.mostrarLabel("Almacen_z2", aliasAlmacen .. " — ¡sin salida!")
					task.delay(0.6, function()
						EfectosDialogo.mostrarLabel("Almacen_z2", "PILA: desapila ← [Ent, T.Norte, Cist]")
						EfectosDialogo.blink("Almacen_z2", "ERROR", 3)
					end)
				end,
				Siguiente = "dfs_paso7_backtracking",
			},

			-- ── 9. PASO 7: BACKTRACKING ─────────────────────────────────
			{
				Id        = "dfs_paso7_backtracking",
				Numero    = 9,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "Paso 7: DFS desapila y vuelve a la " .. aliasCisterna .. ". Tampoco tiene vecinos nuevos. Desapila de nuevo y vuelve al " .. aliasPuente .. ", luego al " .. aliasTunelS .. "… Retrocede hasta encontrar un nodo con vecinos sin visitar. ¡Esa es la magia del backtracking!",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					enfocarGrupo({"Puente_z2", "Cisterna_z2", "Almacen_z2"}, { altura = 26, angulo = 60, duracion = 1.2 })
					EfectosDialogo.resaltarNodo("Almacen_z2", "AISLADO")
					EfectosDialogo.resaltarNodo("Cisterna_z2", "AISLADO")
					EfectosDialogo.resaltarNodo("Puente_z2", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("Almacen_z2",  aliasAlmacen  .. " ✗ desapilado")
					EfectosDialogo.mostrarLabel("Cisterna_z2", aliasCisterna .. " ✗ desapilado")
					EfectosDialogo.mostrarLabel("Puente_z2",   aliasPuente   .. " — buscando rama…")
					task.delay(0.8, function()
						EfectosDialogo.mostrarLabel("Puente_z2", "PILA: [Ent, T.Norte] ← ahora tope")
					end)
				end,
				Siguiente = "pregunta_backtracking",
			},

			-- ── 10. PREGUNTA DE VALIDACIÓN ──────────────────────────────
			{
				Id        = "pregunta_backtracking",
				Numero    = 10,
				Actor     = "Carlos",
				Expresion = "Curioso",
				Texto     = "Pregunta: cuando DFS llega a un nodo sin vecinos sin visitar, ¿qué hace el algoritmo?",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					enfocarNodo("Cruce_z1", { altura = 28, angulo = 60, duracion = 1.0 })
					EfectosDialogo.resaltarNodo("Cruce_z1", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("Cruce_z1", "¿Y ahora qué?")
				end,
				Opciones = {
					{ Texto = "Retrocede al nodo anterior y prueba otra rama disponible.", Siguiente = "resp_back_bien" },
					{ Texto = "Se detiene y termina la exploración completamente.", Siguiente = "resp_back_mal" },
					{ Texto = "Salta a un nodo aleatorio del grafo que aún no haya visitado.", Siguiente = "resp_back_mal2" },
				},
			},

			-- ── 11a. RESPUESTA CORRECTA ─────────────────────────────────
			{
				Id        = "resp_back_bien",
				Numero    = 11,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "¡Correcto! Eso se llama backtracking. DFS retrocede por la pila hasta encontrar un nodo que tenga vecinos sin visitar. Luego prueba esa nueva rama. Es la esencia de DFS: avanzar hasta no poder más, y entonces retroceder para explorar alternativas.",
				Evento = function()
					local jugador = game:GetService("Players").LocalPlayer
					if jugador then
						local puntajeActual = jugador:GetAttribute("PuntajeDialogo") or 0
						jugador:SetAttribute("PuntajeDialogo", puntajeActual + 100)
					end
					notificarRespuestaCorrecta()
					EfectosDialogo.limpiarTodo()
					enfocarNodo("Cruce_z1", { altura = 26, angulo = 60, duracion = 1.0 })
					EfectosDialogo.resaltarNodo("Cruce_z1", "EXITO")
					EfectosDialogo.mostrarLabel("Cruce_z1", "¡Backtracking correcto!")
				end,
				Opciones = { { Texto = "Continuar", Siguiente = "comparacion_bfs_dfs" } },
			},

			-- ── 11b. RESPUESTA INCORRECTA 1 ─────────────────────────────
			{
				Id        = "resp_back_mal",
				Numero    = 11,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No, DFS no termina ahí. Esa es la magia del backtracking: cuando un nodo no tiene más vecinos sin visitar, DFS desapila y retrocede al nodo anterior. Sigue retrocediendo hasta encontrar una rama que aún no haya explorado.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					enfocarGrupo({"Puente_z2", "Almacen_z2"}, { altura = 24, angulo = 62, duracion = 1.0 })
					EfectosDialogo.resaltarNodo("Almacen_z2", "ERROR")
					EfectosDialogo.resaltarNodo("Puente_z2", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("Almacen_z2", "Sin salida…")
					EfectosDialogo.mostrarLabel("Puente_z2", "…retrocede aquí")
				end,
				Opciones = { { Texto = "Entendido", Siguiente = "comparacion_bfs_dfs" } },
			},

			-- ── 11c. RESPUESTA INCORRECTA 2 ─────────────────────────────
			{
				Id        = "resp_back_mal2",
				Numero    = 11,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No, DFS nunca salta aleatoriamente. El orden de exploración está completamente determinado por la pila LIFO. Retrocede sistemáticamente por el camino que vino, probando cada rama que quedó pendiente.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					enfocarGrupo({"Puente_z2", "Almacen_z2"}, { altura = 24, angulo = 62, duracion = 1.0 })
					EfectosDialogo.resaltarNodo("Almacen_z2", "ERROR")
					EfectosDialogo.resaltarNodo("Puente_z2", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("Almacen_z2", "Sin salida…")
					EfectosDialogo.mostrarLabel("Puente_z2", "…retrocede aquí")
				end,
				Opciones = { { Texto = "Entendido", Siguiente = "comparacion_bfs_dfs" } },
			},

			-- ── 12. COMPARACIÓN: BFS (COLA) vs DFS (PILA) ───────────────
			{
				Id        = "comparacion_bfs_dfs",
				Numero    = 12,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "¿Notas la diferencia con BFS? BFS usa una COLA: FIFO — First In, First Out. El primero en entrar es el primero en salir. El orden BFS desde el Generador sería: Generador, Entrada, Cruce, Sala Máquinas, Túnel Norte, Túnel Sur, Cisterna, Almacén, Puente… En cambio DFS, con su PILA LIFO, se fue directo hasta el fondo de la rama Sur antes de regresar. ¡Dos estructuras, dos comportamientos completamente distintos!",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					enfocarGrupo({"Gen_Fabrica_z1", "Cruce_z1", "Tunel_Sur_z2", "Puente_z2"}, { altura = 32, angulo = 58, duracion = 1.5 })
					-- Resalta el camino DFS (rama Sur profunda)
					EfectosDialogo.resaltarNodo("Gen_Fabrica_z1", "EXITO")
					EfectosDialogo.resaltarNodo("Cruce_z1", "EXITO")
					EfectosDialogo.resaltarNodo("Tunel_Sur_z2", "EXITO")
					EfectosDialogo.resaltarNodo("Puente_z2", "EXITO")
					task.delay(0.4, function()
						EfectosDialogo.mostrarArista("Gen_Fabrica_z1", "Cruce_z1", "EXITO", { sinParticulas = true })
						EfectosDialogo.mostrarArista("Cruce_z1", "Tunel_Sur_z2", "EXITO", { sinParticulas = true })
						EfectosDialogo.mostrarArista("Tunel_Sur_z2", "Puente_z2", "EXITO", { sinParticulas = true })
					end)
					task.delay(0.8, function()
						EfectosDialogo.mostrarLabel("Gen_Fabrica_z1", "BFS: COLA [Gen, Ent, Cruce, …]")
						EfectosDialogo.mostrarLabel("Puente_z2", "DFS: PILA [Gen, Cruce, T.Sur, Puente]")
					end)
				end,
				Siguiente = "instruccion_final",
			},

			-- ── 13. INSTRUCCIÓN FINAL ───────────────────────────────────
			{
				Id        = "instruccion_final",
				Numero    = 13,
				Actor     = "Sistema",
				Texto     = "Conecta las calles del Barrio Oeste respetando el orden de ramificación del grafo. Abre el Panel de Análisis con DFS para visualizar el backtracking en acción. Avanza hacia la Oficina de Análisis cuando estés listo.",
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
