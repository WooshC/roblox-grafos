-- ReplicatedStorage/DialogoData/DialogosNivel2/Nivel2_Laberinto.lua
-- Diálogo de la Zona 1 (Barrio Laberinto) — Nivel 2: La Fábrica de Señales
-- Flujo conciso: emergencia → explicación DFS rápida → pregunta → a jugar

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EfectosDialogo = require(ReplicatedStorage:WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
local ServicioCamara = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("ServicioCamara"))

-- Evento para notificar respuestas correctas al servidor
local function notificarRespuestaCorrecta()
	local eventos = ReplicatedStorage:FindFirstChild("EventosGrafosV3")
	if eventos then
		local remotos = eventos:FindFirstChild("Remotos")
		if remotos then
			local evento = remotos:FindFirstChild("DialogoCorrecto")
			if evento then
				evento:FireServer()
			end
		end
	end
end

local DIALOGOS = {
	["Nivel2_Laberinto"] = {
		Zona  = "Zona_Laberinto_1",
		Nivel = 2,
		Lineas = {
			{
				Id        = "explosion",
				Numero    = 1,
				Actor     = "Sistema",
				Texto     = "⚠️ ALERTA CRÍTICA: El transformador del Laberinto explotó. Tienes 60 segundos para reconectar la red desde el Generador.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Gen_Fabrica_z1", { altura = 35, angulo = 75, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Gen_Fabrica_z1", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Entrada_z1", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Cruce_z1", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Sala_Maquinas_z1", "ADYACENTE")
				end,
				Siguiente = "emergencia_carlos",
			},
			{
				Id        = "emergencia_carlos",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Extasiado",
				Texto     = "¡Tocino, esto es grave! El transformador principal del Laberinto sobrecargó. Si no reconectamos la red en 60 segundos, los sistemas de respaldo fallarán y perderemos toda la energía del sector.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Gen_Fabrica_z1", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("Gen_Fabrica_z1", "¡RESTAURA LA RED!", "SELECCIONADO")
				end,
				Siguiente = "dfs_rapido",
			},
			{
				Id        = "dfs_rapido",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "Usa DFS: Búsqueda en Profundidad. DFS usa una Pila (LIFO) — el último nodo descubierto es el primero en explorar. Eso hace que bucees hasta el fondo de una rama antes de probar otra. Es perfecto para laberintos como este.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Gen_Fabrica_z1", { altura = 25, angulo = 65, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Gen_Fabrica_z1", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("Gen_Fabrica_z1", "Generador Fábrica", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Entrada_z1", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Cruce_z1", "ADYACENTE")
				end,
				Siguiente = "pregunta_pila",
			},
			{
				Id        = "pregunta_pila",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Curioso",
				Texto     = "Pregunta rápida: ¿por qué DFS usa una pila y no una cola como BFS?",
				Opciones = {
					{ Texto = "Porque la pila LIFO hace que siempre exploremos el nodo más reciente, adentrándonos en profundidad.", Siguiente = "resp_pila_bien" },
					{ Texto = "Porque la pila es más rápida que la cola en todas las situaciones.", Siguiente = "resp_pila_mal" },
					{ Texto = "Porque DFS no necesita recordar los nodos visitados.", Siguiente = "resp_pila_mal2" },
				},
			},
			{
				Id        = "resp_pila_bien",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "¡Exacto! La pila LIFO garantiza que DFS siempre explore la rama más reciente primero, adentrándose en profundidad antes que en amplitud. Eso es lo que necesitamos aquí.",
				Evento = function()
					local jugador = game:GetService("Players").LocalPlayer
					if jugador then
						local puntajeActual = jugador:GetAttribute("PuntajeDialogo") or 0
						jugador:SetAttribute("PuntajeDialogo", puntajeActual + 100)
					end
					notificarRespuestaCorrecta()
				end,
				Opciones = { { Texto = "A conectar", Siguiente = "instruccion_final" } },
			},
			{
				Id        = "resp_pila_mal",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No exactamente. La velocidad no es la razón. La clave es el orden: pila LIFO = profundidad primero; cola FIFO = amplitud primero. DFS necesita profundidad para laberintos.",
				Opciones = { { Texto = "Entendido", Siguiente = "instruccion_final" } },
			},
			{
				Id        = "resp_pila_mal2",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No, DFS sí necesita recordar los nodos visitados. La diferencia está en el orden de exploración: BFS usa cola FIFO; DFS usa pila LIFO. Ambos necesitan una lista de visitados.",
				Opciones = { { Texto = "Entendido", Siguiente = "instruccion_final" } },
			},
			{
				Id        = "instruccion_final",
				Numero    = 1,
				Actor     = "Sistema",
				Texto     = "Conecta los cables desde el Generador usando DFS. Abre el Panel de Análisis (Tab) si necesitas ayuda. ¡Rápido, el tiempo corre!",
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
