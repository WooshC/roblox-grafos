-- ReplicatedStorage/DialogoData/Zona1_Dialogo.lua
-- Diálogo educativo de la Zona 1: Nodos y Aristas

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LevelsConfig    = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("LevelsConfig"))
local EfectosDialogo  = require(ReplicatedStorage:WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
local ServicioCamara  = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("ServicioCamara"))

-- ════════════════════════════════════════════════════════════════════
-- ALIASES
-- ════════════════════════════════════════════════════════════════════

local alias1 = LevelsConfig[0].NombresNodos["Nodo1_z1"] or "Nodo 1"
local alias2 = LevelsConfig[0].NombresNodos["Nodo2_z1"] or "Nodo 2"

-- ════════════════════════════════════════════════════════════════════
-- HELPERS DE CÁMARA (delegan en ServicioCamara directamente)
-- ════════════════════════════════════════════════════════════════════

local function enfocarNodo(nombreNodo, opciones)
	ServicioCamara.moverHaciaObjetivo(nombreNodo, opciones)
end

-- Calcula el punto medio entre los dos nodos y mueve la cámara ahí
local function enfocarMedio(opciones)
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

	local p1 = getPos("Nodo1_z1")
	local p2 = getPos("Nodo2_z1")
	if not (p1 and p2) then return end

	local mid = p1:Lerp(p2, 0.5)
	ServicioCamara.moverHaciaObjetivo(mid, {
		altura   = opciones and opciones.altura   or 22,
		angulo   = opciones and opciones.angulo   or 65,
		duracion = opciones and opciones.duracion or 1.2,
	})
end

-- ════════════════════════════════════════════════════════════════════
-- DATOS DEL DIÁLOGO
-- ════════════════════════════════════════════════════════════════════

local DIALOGOS = {

	["Zona1_NodosAristas"] = {
		Zona  = "Zona_Estacion_1",
		Nivel = 0,

		Lineas = {

			-- ── 1. BIENVENIDA ─────────────────────────────────────────
			{
				Id        = "inicio",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Sonriente",
				Texto     = "Bienvenido a la Zona 1. Aquí aprenderás qué es un nodo y qué es una conexión.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					enfocarNodo("Nodo1_z1", { altura = 22, angulo = 60, duracion = 1.5 })
				end,
				Siguiente = "concepto_nodo",
			},

			-- ── 2. CONCEPTO: NODO ─────────────────────────────────────
			{
				Id        = "concepto_nodo",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "Observa este punto frente a ti. Eso es un NODO. En teoría de grafos representa un elemento dentro de una red.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Nodo1_z1", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("Nodo1_z1", alias1, "SELECCIONADO")
					enfocarNodo("Nodo1_z1", { altura = 15, angulo = 65, duracion = 1.2 })
				end,
				Siguiente = "concepto_nodo_2",
			},

			-- ── 3. NODO: CONTINUACIÓN ─────────────────────────────────
			{
				Id        = "concepto_nodo_2",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Un nodo puede representar cualquier cosa: una persona, una ciudad, una computadora… Lo importante es que es un punto que puede conectarse con otros.",
				-- sin Evento: se mantiene el estado visual de la línea anterior
				Siguiente = "nodo_aislado",
			},

			-- ── 4. NODO AISLADO ───────────────────────────────────────
			{
				Id        = "nodo_aislado",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Un nodo sin conexiones está aislado. No forma parte de ninguna red.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					-- Ambos en rojo: sin conexión = aislados
					EfectosDialogo.resaltarNodo("Nodo1_z1", "AISLADO")
					EfectosDialogo.resaltarNodo("Nodo2_z1", "AISLADO")
					EfectosDialogo.mostrarLabel("Nodo1_z1", alias1, "AISLADO")
					EfectosDialogo.mostrarLabel("Nodo2_z1", alias2, "AISLADO")
					enfocarMedio({ altura = 22, angulo = 65, duracion = 1.2 })
				end,
				Siguiente = "concepto_arista",
			},

			-- ── 5. CONCEPTO: ARISTA ───────────────────────────────────
			{
				Id        = "concepto_arista",
				Numero    = 5,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Cuando conectas dos nodos, creas una ARISTA. La arista es la relación entre ellos.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					-- Ambos cyan: relacionados
					EfectosDialogo.resaltarNodo("Nodo1_z1", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Nodo2_z1", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("Nodo1_z1", alias1)
					EfectosDialogo.mostrarLabel("Nodo2_z1", alias2)
					-- Arista falsa con beam + billboard "⟵ ARISTA ⟶"
					task.delay(0.4, function()
						EfectosDialogo.mostrarArista("Nodo1_z1", "Nodo2_z1", "SELECCIONADO")
					end)
					enfocarMedio({ altura = 22, angulo = 65, duracion = 1.2 })
				end,
				Siguiente = "instruccion_origen",
			},

			-- ── 6. INSTRUCCIÓN: ORIGEN ────────────────────────────────
			{
				Id        = "instruccion_origen",
				Numero    = 6,
				Actor     = "Sistema",
				Expresion = "Normal",
				Texto     = "Selecciona el nodo de origen (" .. alias1 .. ").",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Nodo1_z1", "EXITO")
					EfectosDialogo.mostrarLabel("Nodo1_z1", alias1)
					-- Parpadeo: 4 ciclos de 0.35s on / 0.25s off
					EfectosDialogo.blink("Nodo1_z1", "EXITO", 4)
					enfocarNodo("Nodo1_z1", { altura = 14, angulo = 70, duracion = 1.0 })
				end,
				Siguiente = "instruccion_destino",
			},

			-- ── 7. INSTRUCCIÓN: DESTINO ───────────────────────────────
			{
				Id        = "instruccion_destino",
				Numero    = 7,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Luego selecciona el nodo destino (" .. alias2 .. ").",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					-- Nodo 1 "ya elegido" (cyan suave), Nodo 2 próxima acción (dorado)
					EfectosDialogo.resaltarNodo("Nodo1_z1", "CONECTADO")
					EfectosDialogo.resaltarNodo("Nodo2_z1", "ADYACENTE")
					EfectosDialogo.mostrarLabel("Nodo1_z1", alias1)
					EfectosDialogo.mostrarLabel("Nodo2_z1", alias2)
					EfectosDialogo.blink("Nodo2_z1", "ADYACENTE", 4)
					enfocarNodo("Nodo2_z1", { altura = 14, angulo = 70, duracion = 1.0 })
				end,
				Siguiente = "instruccion_resultado",
			},

			-- ── 8. RESULTADO ──────────────────────────────────────────
			{
				Id        = "instruccion_resultado",
				Numero    = 8,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "Así crearás una arista entre los dos nodos.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Nodo1_z1", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Nodo2_z1", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("Nodo1_z1", alias1)
					EfectosDialogo.mostrarLabel("Nodo2_z1", alias2)
					task.delay(0.4, function()
						EfectosDialogo.mostrarArista("Nodo1_z1", "Nodo2_z1", "EXITO")
					end)
					enfocarMedio({ altura = 22, angulo = 65, duracion = 1.0 })
				end,
				Siguiente = "confirmacion",
			},

			-- ── 9. CONFIRMACIÓN ───────────────────────────────────────
			{
				Id        = "confirmacion",
				Numero    = 9,
				Actor     = "Carlos",
				Expresion = "Sonriente",
				Texto     = "Ahora es tu turno. ¡Conecta los nodos!",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.restaurar(0.8)
				end,
				Siguiente = "FIN",
			},
		},

		Metadata = {
			TiempoDeEspera      = 0.5,
			VelocidadTypewriter = 0.03,
			PuedeOmitir         = true,
			OcultarHUD          = true,
			UsarTTS             = false,
		},

		Configuracion = {
			bloquearMovimiento = true,
			bloquearSalto      = true,
			bloquearCarrera    = true,
			apuntarCamara      = true,
			permitirConexiones = false,
			ocultarTechos      = true,
		},
	},
}

return DIALOGOS