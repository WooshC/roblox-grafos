-- ReplicatedStorage/DialogoData/Zona3_GrafosDirigidos.lua
-- Diálogo educativo de la Zona 3: Grafos Dirigidos (Dígrafos)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LevelsConfig   = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("LevelsConfig"))
local EfectosDialogo = require(ReplicatedStorage:WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
local ServicioCamara = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("ServicioCamara"))

-- ════════════════════════════════════════════════════════════════════
-- ALIASES  (nombres desde LevelsConfig[0].NombresNodos)
-- ════════════════════════════════════════════════════════════════════

local nodos  = LevelsConfig[0].NombresNodos
local aliasA = nodos["NodoA_z3"] or "Nodo A"
local aliasB = nodos["NodoB_z3"] or "Nodo B"
local aliasC = nodos["NodoC_z3"] or "Nodo C"

-- ════════════════════════════════════════════════════════════════════
-- HELPERS DE CÁMARA
-- ════════════════════════════════════════════════════════════════════

local function enfocarNodo(nombreNodo, opciones)
	ServicioCamara.moverHaciaObjetivo(nombreNodo, opciones)
end

-- Calcula el centroide de los tres nodos de la cadena (A, B, C)
local function enfocarCadena(opciones)
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

	local nombres = { "NodoA_z3", "NodoB_z3", "NodoC_z3" }
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
		enfocarNodo("NodoA_z3", opciones)
		return
	end

	ServicioCamara.moverHaciaObjetivo(suma / count, {
		altura   = opciones and opciones.altura   or 26,
		angulo   = opciones and opciones.angulo   or 63,
		duracion = opciones and opciones.duracion or 1.2,
	})
end

-- ════════════════════════════════════════════════════════════════════
-- DATOS DEL DIÁLOGO
-- ════════════════════════════════════════════════════════════════════

local DIALOGOS = {

	["Zona3_GrafosDirigidos"] = {
		Zona  = "Zona_Estacion_3",
		Nivel = 0,

		Lineas = {

			-- ── 1. BIENVENIDA ─────────────────────────────────────────
			{
				Id        = "inicio",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Sonriente",
				Texto     = "Bienvenido a la Zona 3. Hasta ahora las aristas no tenían dirección. Aquí aprenderás qué pasa cuando sí la tienen.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					enfocarNodo("NodoA_z3", { altura = 22, angulo = 60, duracion = 1.5 })
				end,
				Siguiente = "concepto_nodirigido",
			},

			-- ── 2. REPASO: GRAFO NO DIRIGIDO ─────────────────────────
			{
				Id        = "concepto_nodirigido",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "En un grafo no dirigido, la arista entre dos nodos funciona en ambos sentidos: si " .. aliasA .. " llega a " .. aliasB .. ", entonces " .. aliasB .. " también llega a " .. aliasA .. ".",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("NodoA_z3", "CONECTADO")
					EfectosDialogo.resaltarNodo("NodoB_z3", "CONECTADO")
					EfectosDialogo.mostrarLabel("NodoA_z3", aliasA)
					EfectosDialogo.mostrarLabel("NodoB_z3", aliasB)
					task.delay(0.4, function()
						EfectosDialogo.mostrarArista("NodoA_z3", "NodoB_z3", "CONECTADO", { dirigido = false })
					end)
					enfocarCadena({ altura = 22, angulo = 65, duracion = 1.2 })
				end,
				Siguiente = "concepto_dirigido",
			},

			-- ── 3. CONCEPTO: GRAFO DIRIGIDO ───────────────────────────
			{
				Id        = "concepto_dirigido",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "Un GRAFO DIRIGIDO —o dígrafo— tiene aristas con flecha. Cada flecha indica en qué sentido fluye la información: solo de origen a destino.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("NodoA_z3", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("NodoB_z3", "ADYACENTE")
					EfectosDialogo.mostrarLabel("NodoA_z3", aliasA .. "  →")
					EfectosDialogo.mostrarLabel("NodoB_z3", aliasB)
					task.delay(0.4, function()
						EfectosDialogo.mostrarArista("NodoA_z3", "NodoB_z3", "SELECCIONADO", { dirigido = true })
					end)
					enfocarCadena({ altura = 22, angulo = 65, duracion = 1.2 })
				end,
				Siguiente = "direccion_importa",
			},

			-- ── 4. LA DIRECCIÓN IMPORTA ───────────────────────────────
			{
				Id        = "direccion_importa",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "La dirección importa. Si solo existe la flecha " .. aliasA .. " → " .. aliasB .. ", el " .. aliasA .. " puede enviar al " .. aliasB .. ", pero el " .. aliasB .. " NO puede enviar al " .. aliasA .. ".",
				-- sin Evento: se mantiene el estado visual de la línea anterior
				Siguiente = "concepto_camino",
			},

			-- ── 5. CONCEPTO: CAMINO DIRIGIDO ──────────────────────────
			{
				Id        = "concepto_camino",
				Numero    = 5,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Cuando encadenamos flechas — " .. aliasA .. " → " .. aliasB .. " → " .. aliasC .. " — creamos un CAMINO DIRIGIDO. La información puede viajar de " .. aliasA .. " hasta " .. aliasC .. " siguiendo ese orden.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("NodoA_z3", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("NodoB_z3", "ADYACENTE")
					EfectosDialogo.resaltarNodo("NodoC_z3", "ADYACENTE")
					EfectosDialogo.mostrarLabel("NodoA_z3", aliasA .. "  →")
					EfectosDialogo.mostrarLabel("NodoB_z3", aliasB .. "  →")
					EfectosDialogo.mostrarLabel("NodoC_z3", aliasC)
					task.delay(0.4, function()
						EfectosDialogo.mostrarArista("NodoA_z3", "NodoB_z3", "SELECCIONADO", { dirigido = true })
						EfectosDialogo.mostrarArista("NodoB_z3", "NodoC_z3", "SELECCIONADO", { dirigido = true })
					end)
					enfocarCadena({ altura = 26, angulo = 63, duracion = 1.2 })
				end,
				Siguiente = "pregunta",
			},

			-- ── 6. PREGUNTA DE VALIDACIÓN ─────────────────────────────
			{
				Id        = "pregunta",
				Numero    = 6,
				Actor     = "Carlos",
				Expresion = "Sorprendido",
				Texto     = "En el dígrafo " .. aliasA .. " → " .. aliasB .. " → " .. aliasC .. ", ¿puede el " .. aliasB .. " enviar datos directamente al " .. aliasA .. "?",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("NodoA_z3", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("NodoB_z3", "ADYACENTE")
					EfectosDialogo.resaltarNodo("NodoC_z3", "ADYACENTE")
					EfectosDialogo.mostrarLabel("NodoA_z3", aliasA)
					EfectosDialogo.mostrarLabel("NodoB_z3", aliasB)
					EfectosDialogo.mostrarLabel("NodoC_z3", aliasC)
					task.delay(0.4, function()
						EfectosDialogo.mostrarArista("NodoA_z3", "NodoB_z3", "SELECCIONADO", { dirigido = true })
						EfectosDialogo.mostrarArista("NodoB_z3", "NodoC_z3", "SELECCIONADO", { dirigido = true })
					end)
					enfocarCadena({ altura = 26, angulo = 63, duracion = 1.0 })
				end,
				Opciones = {
					{ Texto = "No, solo en sentido contrario",      Siguiente = "respuesta_correcta"   },
					{ Texto = "Sí, la arista va en ambos sentidos", Siguiente = "respuesta_incorrecta" },
				},
			},

			-- ── 7a. RESPUESTA CORRECTA ────────────────────────────────
			{
				Id        = "respuesta_correcta",
				Numero    = 7,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "¡Correcto! La flecha " .. aliasA .. " → " .. aliasB .. " solo permite el flujo de " .. aliasA .. " hacia " .. aliasB .. ". Para el sentido inverso haría falta una segunda flecha.",
				Opciones = {
					{ Texto = "¡Entendido!", Siguiente = "instruccion_ab" },
				},
			},

			-- ── 7b. RESPUESTA INCORRECTA ──────────────────────────────
			{
				Id        = "respuesta_incorrecta",
				Numero    = 7,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No exactamente. En un dígrafo cada flecha tiene un único sentido. La flecha " .. aliasA .. " → " .. aliasB .. " solo permite el flujo de " .. aliasA .. " a " .. aliasB .. ". El camino inverso requeriría una flecha separada.",
				Opciones = {
					{ Texto = "Entendido", Siguiente = "instruccion_ab" },
				},
			},

			-- ── 8. INSTRUCCIÓN: CONECTAR A → B ────────────────────────
			{
				Id        = "instruccion_ab",
				Numero    = 8,
				Actor     = "Sistema",
				Expresion = "Normal",
				Texto     = "Construye el dígrafo. Primero conecta " .. aliasA .. " → " .. aliasB .. ": haz clic en " .. aliasA .. " y luego en " .. aliasB .. ".",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("NodoA_z3", "EXITO")
					EfectosDialogo.resaltarNodo("NodoB_z3", "ADYACENTE")
					EfectosDialogo.mostrarLabel("NodoA_z3", aliasA .. "  ·  1º clic")
					EfectosDialogo.mostrarLabel("NodoB_z3", aliasB .. "  ·  2º clic")
					EfectosDialogo.blink("NodoA_z3", "EXITO",     3)
					EfectosDialogo.blink("NodoB_z3", "ADYACENTE", 3)
					enfocarCadena({ altura = 24, angulo = 65, duracion = 1.0 })
				end,
				EsperarAccion = { tipo = "conectarNodos", nodoA = "NodoA_z3", nodoB = "NodoB_z3" },
				Siguiente = "instruccion_bc",
			},

			-- ── 9. INSTRUCCIÓN: CONECTAR B → C ────────────────────────
			{
				Id        = "instruccion_bc",
				Numero    = 9,
				Actor     = "Sistema",
				Expresion = "Normal",
				Texto     = "Ahora conecta " .. aliasB .. " → " .. aliasC .. ". Haz clic en " .. aliasB .. " y luego en " .. aliasC .. " para completar el camino dirigido.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("NodoA_z3", "CONECTADO")
					EfectosDialogo.resaltarNodo("NodoB_z3", "EXITO")
					EfectosDialogo.resaltarNodo("NodoC_z3", "ADYACENTE")
					EfectosDialogo.mostrarLabel("NodoA_z3", aliasA)
					EfectosDialogo.mostrarLabel("NodoB_z3", aliasB .. "  ·  1º clic")
					EfectosDialogo.mostrarLabel("NodoC_z3", aliasC .. "  ·  2º clic")
					EfectosDialogo.blink("NodoB_z3", "EXITO",     3)
					EfectosDialogo.blink("NodoC_z3", "ADYACENTE", 3)
					enfocarCadena({ altura = 24, angulo = 65, duracion = 1.0 })
				end,
				EsperarAccion = { tipo = "conectarNodos", nodoA = "NodoB_z3", nodoB = "NodoC_z3" },
				Siguiente = "resultado",
			},

			-- ── 10. RESULTADO ─────────────────────────────────────────
			{
				Id        = "resultado",
				Numero    = 10,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "¡Excelente! Has construido el camino dirigido " .. aliasA .. " → " .. aliasB .. " → " .. aliasC .. ". Eso es un dígrafo en acción.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					task.delay(0.3, function()
						EfectosDialogo.mostrarArista("NodoA_z3", "NodoB_z3", "EXITO", { dirigido = true, sinParticulas = true })
						EfectosDialogo.mostrarArista("NodoB_z3", "NodoC_z3", "EXITO", { dirigido = true, sinParticulas = true })
					end)
					enfocarCadena({ altura = 26, angulo = 63, duracion = 1.0 })
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
			bloquearCarrera    = true,
			apuntarCamara      = true,
			permitirConexiones = true,   -- necesario para las líneas interactivas 8 y 9
			ocultarTechos      = true,
			cerrarMapa         = true,
		},
	},
}

return DIALOGOS
