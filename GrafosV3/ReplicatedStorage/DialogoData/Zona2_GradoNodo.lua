-- ReplicatedStorage/DialogoData/Zona2_GradoNodo.lua
-- Diálogo educativo de la Zona 2: Grado de Nodo

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LevelsConfig   = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("LevelsConfig"))
local EfectosDialogo = require(ReplicatedStorage:WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
local ServicioCamara = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("ServicioCamara"))

-- ════════════════════════════════════════════════════════════════════
-- ALIASES
-- ════════════════════════════════════════════════════════════════════

local nodos       = LevelsConfig[0].NombresNodos
local aliasCentro = nodos["NodoCentro_z2"] or "Nodo Central"
local aliasA      = nodos["NodoA_z2"]      or "Vecino A"
local aliasB      = nodos["NodoB_z2"]      or "Vecino B"
local aliasC      = nodos["NodoC_z2"]      or "Vecino C"
local aliasD      = nodos["NodoD_z2"]      or "Vecino D"

-- ════════════════════════════════════════════════════════════════════
-- HELPERS DE CÁMARA
-- ════════════════════════════════════════════════════════════════════

local function enfocarNodo(nombreNodo, opciones)
	ServicioCamara.moverHaciaObjetivo(nombreNodo, opciones)
end

-- Calcula el centroide de los 5 nodos de la estrella y mueve la cámara ahí
local function enfocarEstrella(opciones)
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

	local nombres = { "NodoCentro_z2", "NodoA_z2", "NodoB_z2", "NodoC_z2", "NodoD_z2" }
	local suma  = Vector3.new(0, 0, 0)
	local count = 0
	for _, nom in ipairs(nombres) do
		local p = getPos(nom)
		if p then
			suma  = suma + p
			count = count + 1
		end
	end

	if count == 0 then
		enfocarNodo("NodoCentro_z2", opciones)
		return
	end

	ServicioCamara.moverHaciaObjetivo(suma / count, {
		altura   = opciones and opciones.altura   or 28,
		angulo   = opciones and opciones.angulo   or 62,
		duracion = opciones and opciones.duracion or 1.2,
	})
end

-- ════════════════════════════════════════════════════════════════════
-- DATOS DEL DIÁLOGO
-- ════════════════════════════════════════════════════════════════════

local DIALOGOS = {

	["Zona2_GradoNodo"] = {
		Zona  = "Zona_Estacion_2",
		Nivel = 0,

		Lineas = {

			-- ── 1. BIENVENIDA ─────────────────────────────────────────
			{
				Id        = "inicio",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Sonriente",
				Texto     = "Bienvenido a la Zona 2. Aquí vas a aprender una propiedad fundamental de los nodos: el GRADO.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					enfocarNodo("NodoCentro_z2", { altura = 24, angulo = 60, duracion = 1.5 })
				end,
				Siguiente = "que_es_grado",
			},

			-- ── 2. QUÉ ES EL GRADO ───────────────────────────────────
			{
				Id        = "que_es_grado",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "El GRADO de un nodo es el número de aristas que tiene conectadas. Cada conexión suma exactamente uno al grado.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("NodoCentro_z2", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("NodoCentro_z2", aliasCentro, "SELECCIONADO")
					enfocarNodo("NodoCentro_z2", { altura = 18, angulo = 65, duracion = 1.2 })
				end,
				Siguiente = "grado_0",
			},

			-- ── 3. GRADO 0: AISLADO ───────────────────────────────────
			{
				Id        = "grado_0",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Sin ninguna conexión, el grado es CERO. El nodo existe en la red, pero está completamente aislado: no puede enviar ni recibir nada.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("NodoCentro_z2", "AISLADO")
					EfectosDialogo.mostrarLabel("NodoCentro_z2", aliasCentro .. "  ·  Grado: 0", "AISLADO")
					enfocarNodo("NodoCentro_z2", { altura = 18, angulo = 65, duracion = 1.0 })
				end,
				Siguiente = "grado_1",
			},

			-- ── 4. GRADO 1 ────────────────────────────────────────────
			{
				Id        = "grado_1",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "En cuanto le conectamos un vecino, el grado sube a UNO. Ahora tiene una arista que lo une al resto de la red.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("NodoCentro_z2", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("NodoA_z2",      "ADYACENTE")
					EfectosDialogo.mostrarLabel("NodoCentro_z2", aliasCentro .. "  ·  Grado: 1")
					EfectosDialogo.mostrarLabel("NodoA_z2",      aliasA)
					task.delay(0.4, function()
						EfectosDialogo.mostrarArista("NodoCentro_z2", "NodoA_z2", "SELECCIONADO")
					end)
					enfocarEstrella({ altura = 24, angulo = 65, duracion = 1.2 })
				end,
				Siguiente = "grado_estrella",
			},

			-- ── 5. GRADO ESTRELLA (4) ─────────────────────────────────
			{
				Id        = "grado_estrella",
				Numero    = 5,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "Con cuatro vecinos conectados, el grado es CUATRO. Este tipo de grafo —un nodo central conectado a todos los demás— se llama GRAFO ESTRELLA.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("NodoCentro_z2", "EXITO")
					EfectosDialogo.resaltarNodo("NodoA_z2",      "ADYACENTE")
					EfectosDialogo.resaltarNodo("NodoB_z2",      "ADYACENTE")
					EfectosDialogo.resaltarNodo("NodoC_z2",      "ADYACENTE")
					EfectosDialogo.resaltarNodo("NodoD_z2",      "ADYACENTE")
					EfectosDialogo.mostrarLabel("NodoCentro_z2", aliasCentro .. "  ·  Grado: 4", "EXITO")
					EfectosDialogo.mostrarLabel("NodoA_z2", aliasA)
					EfectosDialogo.mostrarLabel("NodoB_z2", aliasB)
					EfectosDialogo.mostrarLabel("NodoC_z2", aliasC)
					EfectosDialogo.mostrarLabel("NodoD_z2", aliasD)
					task.delay(0.4, function()
						EfectosDialogo.mostrarArista("NodoCentro_z2", "NodoA_z2", "EXITO")
						EfectosDialogo.mostrarArista("NodoCentro_z2", "NodoB_z2", "EXITO")
						EfectosDialogo.mostrarArista("NodoCentro_z2", "NodoC_z2", "EXITO")
						EfectosDialogo.mostrarArista("NodoCentro_z2", "NodoD_z2", "EXITO")
					end)
					enfocarEstrella({ altura = 28, angulo = 60, duracion = 1.2 })
				end,
				Siguiente = "pregunta",
			},

			-- ── 6. PREGUNTA DE VALIDACIÓN ─────────────────────────────
			{
				Id        = "pregunta",
				Numero    = 6,
				Actor     = "Carlos",
				Expresion = "Sorprendido",
				Texto     = "Antes de empezar a conectar... Si el " .. aliasCentro .. " tiene cuatro vecinos, ¿cuál será su grado?",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("NodoCentro_z2", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("NodoA_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("NodoB_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("NodoC_z2", "ADYACENTE")
					EfectosDialogo.resaltarNodo("NodoD_z2", "ADYACENTE")
					EfectosDialogo.mostrarLabel("NodoCentro_z2", aliasCentro .. "  ·  ¿Grado?")
					enfocarEstrella({ altura = 28, angulo = 60, duracion = 1.0 })
				end,
				Opciones = {
					{ Texto = "Grado 4", Siguiente = "respuesta_correcta"   },
					{ Texto = "Grado 1", Siguiente = "respuesta_incorrecta" },
					{ Texto = "Grado 8", Siguiente = "respuesta_incorrecta" },
				},
			},

			-- ── 7a. RESPUESTA CORRECTA ────────────────────────────────
			-- Usa Opciones de un solo botón para forzar el salto a la instrucción,
			-- evitando que Next() secuencial caiga en la línea de respuesta incorrecta.
			{
				Id        = "respuesta_correcta",
				Numero    = 7,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "¡Exacto! Cuatro vecinos = cuatro aristas = grado 4. El concepto está claro.",
				Opciones = {
					{ Texto = "Continuar", Siguiente = "instruccion_conectar" },
				},
			},

			-- ── 7b. RESPUESTA INCORRECTA ──────────────────────────────
			{
				Id        = "respuesta_incorrecta",
				Numero    = 7,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No exactamente. El grado cuenta aristas, no nodos vecinos en total. Con cuatro vecinos conectados, el " .. aliasCentro .. " tendrá grado 4, uno por cada arista.",
				Opciones = {
					{ Texto = "Entendido", Siguiente = "instruccion_conectar" },
				},
			},

			-- ── 8. INSTRUCCIÓN: CONECTAR PRIMER VECINO ────────────────
			{
				Id        = "instruccion_conectar",
				Numero    = 8,
				Actor     = "Sistema",
				Expresion = "Normal",
				Texto     = "Haz clic en el " .. aliasCentro .. " y luego en el " .. aliasA .. " para crear tu primera arista.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("NodoCentro_z2", "EXITO")
					EfectosDialogo.resaltarNodo("NodoA_z2",      "ADYACENTE")
					EfectosDialogo.mostrarLabel("NodoCentro_z2", aliasCentro .. "  ·  1º clic")
					EfectosDialogo.mostrarLabel("NodoA_z2",      aliasA .. "  ·  2º clic")
					EfectosDialogo.blink("NodoCentro_z2", "EXITO",    3)
					EfectosDialogo.blink("NodoA_z2",      "ADYACENTE", 3)
					enfocarEstrella({ altura = 24, angulo = 65, duracion = 1.0 })
				end,
				EsperarAccion = { tipo = "conectarNodos", nodoA = "NodoCentro_z2", nodoB = "NodoA_z2" },
				Siguiente = "resultado",
			},

			-- ── 9. RESULTADO ──────────────────────────────────────────
			{
				Id        = "resultado",
				Numero    = 9,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "¡Bien hecho! Ya creaste la primera arista. Conecta los tres vecinos restantes para completar la misión y alcanzar grado 4.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					task.delay(0.3, function()
						EfectosDialogo.mostrarArista("NodoCentro_z2", "NodoA_z2", "EXITO", { sinParticulas = true })
					end)
					enfocarEstrella({ altura = 28, angulo = 60, duracion = 1.0 })
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
			permitirConexiones = true,   -- necesario para la línea interactiva 8 (conectarNodos)
			ocultarTechos      = true,
		},
	},
}

return DIALOGOS
