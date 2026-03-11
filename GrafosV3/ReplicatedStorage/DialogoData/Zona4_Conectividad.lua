-- ReplicatedStorage/DialogoData/Zona4_Conectividad.lua
-- Diálogo educativo de la Zona 4: Grafos Conexos — Red Eléctrica del Metro de Quito

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LevelsConfig   = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("LevelsConfig"))
local EfectosDialogo = require(ReplicatedStorage:WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
local ServicioCamara = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("ServicioCamara"))

-- ════════════════════════════════════════════════════════════════════
-- ALIASES  (nombres desde LevelsConfig[0].NombresNodos)
-- ════════════════════════════════════════════════════════════════════

local nodos  = LevelsConfig[0].NombresNodos
local aliasE = nodos["NodoE_z4"] or "Empresa Eléctrica"
local aliasA = nodos["NodoA_z4"] or "Estacion El Ejido"
local aliasB = nodos["NodoB_z4"] or "Estacion La Pradera"
local aliasC = nodos["NodoC_z4"] or "Estacion La Carolina"
local aliasF = nodos["NodoF_z4"] or "Estacion Iñaquito"
local aliasD = nodos["NodoD_z4"] or "Estacion El Labrador"

-- ════════════════════════════════════════════════════════════════════
-- HELPERS DE CÁMARA
-- ════════════════════════════════════════════════════════════════════

local function enfocarNodo(nombreNodo, opciones)
	ServicioCamara.moverHaciaObjetivo(nombreNodo, opciones)
end

-- Calcula el punto medio entre dos nodos y enfoca ahí
local function enfocarPar(nomA, nomB, opciones)
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

	local pA = getPos(nomA)
	local pB = getPos(nomB)
	if not (pA and pB) then return end

	ServicioCamara.moverHaciaObjetivo(pA:Lerp(pB, 0.5), {
		altura   = opciones and opciones.altura   or 42,
		angulo   = opciones and opciones.angulo   or 64,
		duracion = opciones and opciones.duracion or 0.8,
	})
end

-- Calcula el centroide de toda la red (6 nodos)
local function enfocarRed(opciones)
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

	local nombres = { "NodoE_z4", "NodoA_z4", "NodoB_z4", "NodoC_z4", "NodoF_z4", "NodoD_z4" }
	local suma    = Vector3.new(0, 0, 0)
	local count   = 0
	for _, nom in ipairs(nombres) do
		local p = getPos(nom)
		if p then
			suma  = suma + p
			count = count + 1
		end
	end

	if count == 0 then
		enfocarNodo("NodoA_z4", opciones)
		return
	end

	ServicioCamara.moverHaciaObjetivo(suma / count, {
		altura   = opciones and opciones.altura   or 80,
		angulo   = opciones and opciones.angulo   or 60,
		duracion = opciones and opciones.duracion or 1.0,
	})
end

-- ════════════════════════════════════════════════════════════════════
-- DATOS DEL DIÁLOGO
-- ════════════════════════════════════════════════════════════════════

local DIALOGOS = {

	["Zona4_Conectividad"] = {
		Zona  = "Zona_Estacion_4",
		Nivel = 0,

		-- Limpia efectos visuales al cerrar o al pulsar Saltar
		EventoSalida = function() EfectosDialogo.limpiarTodo() end,

		Lineas = {

			-- ── 1-2. BIENVENIDA / CONTEXTO ───────────────────────────
			{
				Id        = "inicio_a",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Sonriente",
				Texto     = "¡Bienvenido a la Zona 4! La red eléctrica del Metro de Quito está incompleta. Las estaciones ya existen, pero nadie las ha cableado todavía.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					for _, nom in ipairs({"NodoE_z4","NodoA_z4","NodoB_z4","NodoC_z4","NodoF_z4","NodoD_z4"}) do
						EfectosDialogo.resaltarNodo(nom, "AISLADO")
					end
					EfectosDialogo.mostrarLabel("NodoE_z4", aliasE, "AISLADO")
					EfectosDialogo.mostrarLabel("NodoA_z4", aliasA, "AISLADO")
					EfectosDialogo.mostrarLabel("NodoD_z4", aliasD, "AISLADO")
					enfocarRed({ altura = 80, angulo = 58, duracion = 1.2 })
				end,
				Siguiente = "inicio_b",
			},
			{
				Id        = "inicio_b",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Sonriente",
				Texto     = "Sin conexión no hay luz, y sin luz no hay metro. Tu trabajo es unir toda la red y lograr que la electricidad llegue hasta cada estación.",
				Siguiente = "concepto_conexo_a",
			},

			-- ── 3-4. CONCEPTO: GRAFO CONEXO ──────────────────────────
			{
				Id        = "concepto_conexo_a",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "Cuando hay un camino entre cualquier par de nodos de una red, los matemáticos la llaman GRAFO CONEXO.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					for _, nom in ipairs({"NodoE_z4","NodoA_z4","NodoB_z4","NodoC_z4","NodoF_z4","NodoD_z4"}) do
						EfectosDialogo.resaltarNodo(nom, "CONECTADO")
						EfectosDialogo.mostrarLabel(nom, nodos[nom] or nom)
					end
					task.delay(0.2, function()
						EfectosDialogo.mostrarArista("NodoE_z4", "NodoA_z4", "CONECTADO", { dirigido = false })
						EfectosDialogo.mostrarArista("NodoA_z4", "NodoB_z4", "CONECTADO", { dirigido = false })
						EfectosDialogo.mostrarArista("NodoA_z4", "NodoC_z4", "CONECTADO", { dirigido = false })
						EfectosDialogo.mostrarArista("NodoB_z4", "NodoC_z4", "CONECTADO", { dirigido = false })
						EfectosDialogo.mostrarArista("NodoB_z4", "NodoD_z4", "CONECTADO", { dirigido = false })
						EfectosDialogo.mostrarArista("NodoC_z4", "NodoF_z4", "CONECTADO", { dirigido = false })
						EfectosDialogo.mostrarArista("NodoF_z4", "NodoD_z4", "CONECTADO", { dirigido = false })
					end)
					enfocarRed({ altura = 80, angulo = 60, duracion = 0.9 })
				end,
				Siguiente = "concepto_conexo_b",
			},
			{
				Id        = "concepto_conexo_b",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "En nuestro caso, si el grafo es conexo, la energía que sale de la Empresa Eléctrica puede llegar hasta cada estación del metro.",
				Siguiente = "concepto_desconexo_a",
			},

			-- ── 5-6. CONCEPTO: GRAFO DESCONECTADO ────────────────────
			{
				Id        = "concepto_desconexo_a",
				Numero    = 5,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Ahora bien, si falta algún cable, el grafo queda DESCONECTADO. La red se divide en grupos aislados, que llamamos COMPONENTES CONEXAS.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					for _, nom in ipairs({"NodoE_z4","NodoA_z4","NodoB_z4","NodoC_z4","NodoF_z4","NodoD_z4"}) do
						EfectosDialogo.resaltarNodo(nom, "AISLADO")
						EfectosDialogo.mostrarLabel(nom, nodos[nom] or nom, "AISLADO")
					end
					enfocarRed({ altura = 80, angulo = 60, duracion = 0.9 })
				end,
				Siguiente = "concepto_desconexo_b",
			},
			{
				Id        = "concepto_desconexo_b",
				Numero    = 6,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "La electricidad no puede saltar de un grupo al otro. Simplemente se detiene donde termina el cable.",
				Siguiente = "ejemplo_a",
			},

			-- ── 7-8. EJEMPLO: DOS COMPONENTES ────────────────────────
			{
				Id        = "ejemplo_a",
				Numero    = 7,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Mira este ejemplo. La fuente, " .. aliasE .. ", solo llega hasta " .. aliasA .. ". Al norte, " .. aliasF .. " llega hasta " .. aliasD .. ".",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("NodoE_z4", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("NodoA_z4", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("NodoE_z4", aliasE .. "  (comp. 1)")
					EfectosDialogo.mostrarLabel("NodoA_z4", aliasA .. "  (comp. 1)")
					task.delay(0.2, function()
						EfectosDialogo.mostrarArista("NodoE_z4", "NodoA_z4", "SELECCIONADO", { dirigido = false })
					end)
					EfectosDialogo.resaltarNodo("NodoF_z4", "ADYACENTE")
					EfectosDialogo.resaltarNodo("NodoD_z4", "ADYACENTE")
					EfectosDialogo.mostrarLabel("NodoF_z4", aliasF .. "  (comp. 2)")
					EfectosDialogo.mostrarLabel("NodoD_z4", aliasD .. "  (comp. 2)")
					task.delay(0.3, function()
						EfectosDialogo.mostrarArista("NodoF_z4", "NodoD_z4", "ADYACENTE", { dirigido = false })
					end)
					EfectosDialogo.resaltarNodo("NodoB_z4", "AISLADO")
					EfectosDialogo.resaltarNodo("NodoC_z4", "AISLADO")
					EfectosDialogo.mostrarLabel("NodoB_z4", aliasB, "AISLADO")
					EfectosDialogo.mostrarLabel("NodoC_z4", aliasC, "AISLADO")
					enfocarRed({ altura = 80, angulo = 60, duracion = 0.9 })
				end,
				Siguiente = "ejemplo_b",
			},
			{
				Id        = "ejemplo_b",
				Numero    = 8,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Los dos grupos existen, pero no hay ningún cable que los una. Son dos componentes separadas, y la energía no puede cruzar de una a la otra.",
				Siguiente = "pregunta_setup",
			},

			-- ── 9-10. PREGUNTA DE VALIDACIÓN ─────────────────────────
			{
				Id        = "pregunta_setup",
				Numero    = 9,
				Actor     = "Carlos",
				Expresion = "Sorprendido",
				Texto     = "Los dos grupos están aislados. " .. aliasE .. " y " .. aliasA .. " forman una componente al sur. " .. aliasF .. " y " .. aliasD .. " forman otra al norte. No hay ningún cable entre ellas.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("NodoE_z4", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("NodoA_z4", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("NodoF_z4", "ADYACENTE")
					EfectosDialogo.resaltarNodo("NodoD_z4", "ADYACENTE")
					EfectosDialogo.resaltarNodo("NodoB_z4", "AISLADO")
					EfectosDialogo.resaltarNodo("NodoC_z4", "AISLADO")
					EfectosDialogo.mostrarLabel("NodoE_z4", aliasE)
					EfectosDialogo.mostrarLabel("NodoA_z4", aliasA)
					EfectosDialogo.mostrarLabel("NodoF_z4", aliasF)
					EfectosDialogo.mostrarLabel("NodoD_z4", aliasD)
					task.delay(0.2, function()
						EfectosDialogo.mostrarArista("NodoE_z4", "NodoA_z4", "SELECCIONADO", { dirigido = false })
						EfectosDialogo.mostrarArista("NodoF_z4", "NodoD_z4", "ADYACENTE",   { dirigido = false })
					end)
					enfocarRed({ altura = 80, angulo = 60, duracion = 0.9 })
				end,
				Siguiente = "pregunta",
			},
			{
				Id        = "pregunta",
				Numero    = 10,
				Actor     = "Carlos",
				Expresion = "Sorprendido",
				Texto     = "¿Crees que la electricidad puede llegar desde " .. aliasE .. " hasta " .. aliasD .. ", si entre los dos grupos no hay ningún cable?",
				Opciones = {
					{ Texto = "No, el grafo está desconectado",             Siguiente = "respuesta_correcta"     },
					{ Texto = "Sí, la electricidad siempre encuentra paso", Siguiente = "respuesta_incorrecta_a" },
				},
			},

			-- ── 11. RESPUESTA CORRECTA ────────────────────────────────
			{
				Id        = "respuesta_correcta",
				Numero    = 11,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "¡Exacto! Sin un cable que una los dos grupos, la corriente no tiene por dónde llegar hasta " .. aliasD .. ". Hay dos componentes separadas sin ningún puente entre ellas. Para solucionarlo necesitas tender los cables que faltan.",
				Opciones = {
					{ Texto = "¡Entendido, a conectar!", Siguiente = "instruccion_ea" },
				},
			},

			-- ── 12-13. RESPUESTA INCORRECTA ───────────────────────────
			{
				Id        = "respuesta_incorrecta_a",
				Numero    = 12,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "En realidad no. La electricidad solo viaja por donde hay cables, igual que en un grafo: solo puede recorrer las aristas que existen.",
				Siguiente = "respuesta_incorrecta_b",
			},
			{
				Id        = "respuesta_incorrecta_b",
				Numero    = 13,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Si no hay un camino continuo de " .. aliasE .. " a " .. aliasD .. ", la energía simplemente no llega. Eso es lo que significa un grafo desconectado.",
				Opciones = {
					{ Texto = "Entendido", Siguiente = "instruccion_ea" },
				},
			},

			-- ── 14. INSTRUCCIÓN: CONECTAR E — A ───────────────────────
			{
				Id        = "instruccion_ea",
				Numero    = 14,
				Actor     = "Sistema",
				Expresion = "Normal",
				Texto     = "Empecemos por el principio. Conecta " .. aliasE .. " con " .. aliasA .. "; ese es el cable de entrada, la fuente de energía de todo el metro. Haz clic en " .. aliasE .. " primero, y luego en " .. aliasA .. ".",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("NodoE_z4", "EXITO")
					EfectosDialogo.resaltarNodo("NodoA_z4", "ADYACENTE")
					for _, nom in ipairs({"NodoB_z4","NodoC_z4","NodoF_z4","NodoD_z4"}) do
						EfectosDialogo.resaltarNodo(nom, "AISLADO")
					end
					EfectosDialogo.mostrarLabel("NodoE_z4", aliasE .. "  ·  1º clic")
					EfectosDialogo.mostrarLabel("NodoA_z4", aliasA .. "  ·  2º clic")
					EfectosDialogo.blink("NodoE_z4", "EXITO",     3)
					EfectosDialogo.blink("NodoA_z4", "ADYACENTE", 3)
					enfocarPar("NodoE_z4", "NodoA_z4", { altura = 64, angulo = 64, duracion = 0.8 })
				end,
				EsperarAccion = { tipo = "conectarNodos", nodoA = "NodoE_z4", nodoB = "NodoA_z4" },
				Siguiente = "instruccion_fd",
			},

			-- ── 15. INSTRUCCIÓN: CONECTAR F — D ───────────────────────
			{
				Id        = "instruccion_fd",
				Numero    = 15,
				Actor     = "Sistema",
				Expresion = "Normal",
				Texto     = "¡Bien hecho! Ahora ve al extremo norte y tiende el cable entre " .. aliasF .. " y " .. aliasD .. ". Haz clic en " .. aliasF .. " primero, y luego en " .. aliasD .. ".",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("NodoE_z4", "CONECTADO")
					EfectosDialogo.resaltarNodo("NodoA_z4", "CONECTADO")
					EfectosDialogo.resaltarNodo("NodoF_z4", "EXITO")
					EfectosDialogo.resaltarNodo("NodoD_z4", "ADYACENTE")
					EfectosDialogo.resaltarNodo("NodoB_z4", "AISLADO")
					EfectosDialogo.resaltarNodo("NodoC_z4", "AISLADO")
					EfectosDialogo.mostrarLabel("NodoE_z4", aliasE)
					EfectosDialogo.mostrarLabel("NodoA_z4", aliasA)
					EfectosDialogo.mostrarLabel("NodoF_z4", aliasF .. "  ·  1º clic")
					EfectosDialogo.mostrarLabel("NodoD_z4", aliasD .. "  ·  2º clic")
					EfectosDialogo.blink("NodoF_z4", "EXITO",     3)
					EfectosDialogo.blink("NodoD_z4", "ADYACENTE", 3)
					task.delay(0.15, function()
						EfectosDialogo.mostrarArista("NodoE_z4", "NodoA_z4", "CONECTADO", { dirigido = false, sinParticulas = true })
					end)
					enfocarPar("NodoF_z4", "NodoD_z4", { altura = 64, angulo = 64, duracion = 0.8 })
				end,
				EsperarAccion = { tipo = "conectarNodos", nodoA = "NodoF_z4", nodoB = "NodoD_z4" },
				Siguiente = "resultado_a",
			},

			-- ── 16-17. RESULTADO ──────────────────────────────────────
			{
				Id        = "resultado_a",
				Numero    = 16,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "¡Muy bien! Ya cableaste los dos extremos: " .. aliasE .. " con " .. aliasA .. " al sur, y " .. aliasF .. " con " .. aliasD .. " al norte.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("NodoE_z4", "EXITO")
					EfectosDialogo.resaltarNodo("NodoA_z4", "EXITO")
					EfectosDialogo.resaltarNodo("NodoF_z4", "EXITO")
					EfectosDialogo.resaltarNodo("NodoD_z4", "EXITO")
					EfectosDialogo.resaltarNodo("NodoB_z4", "AISLADO")
					EfectosDialogo.resaltarNodo("NodoC_z4", "AISLADO")
					EfectosDialogo.mostrarLabel("NodoB_z4", aliasB .. "  ← falta", "AISLADO")
					EfectosDialogo.mostrarLabel("NodoC_z4", aliasC .. "  ← falta", "AISLADO")
					task.delay(0.3, function()
						EfectosDialogo.mostrarArista("NodoE_z4", "NodoA_z4", "EXITO", { dirigido = false, sinParticulas = true })
						EfectosDialogo.mostrarArista("NodoF_z4", "NodoD_z4", "EXITO", { dirigido = false, sinParticulas = true })
					end)
					enfocarRed({ altura = 80, angulo = 60, duracion = 0.9 })
				end,
				Siguiente = "resultado_b",
			},
			{
				Id        = "resultado_b",
				Numero    = 17,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = aliasB .. " y " .. aliasC .. " todavía están sin conexión. Conecta las estaciones restantes para que el grafo sea completamente conexo y la luz de la zona se encienda.",
				Siguiente = "FIN",
			},
		},

		Metadata = {
			TiempoDeEspera      = 0.2,
			VelocidadTypewriter = 0.02,
			PuedeOmitir         = true,
			OcultarHUD          = true,
			UsarTTS             = true,
		},

		Configuracion = {
			bloquearMovimiento = true,
			bloquearSalto      = true,
			bloquearCarrera    = true,
			apuntarCamara      = true,
			permitirConexiones = true,   -- necesario para las líneas interactivas 14 y 15
			ocultarTechos      = true,
			cerrarMapa         = true,
		},
	},
}

return DIALOGOS
