-- ReplicatedStorage/DialogoData/DialogosNivel2/Nivel2_CiudadGrande.lua
-- Diálogo de la Zona 1 (Ciudad Grande) — Nivel 2: La Ruta Más Corta
-- Concepto: introducción al algoritmo de Dijkstra, peso de arista y relajación.
-- Lore: continuación del Nivel 1. El Alcalde presiona por una solución rápida,
-- pero Carlos demuestra que lo importante es el costo real de cada metro de cable.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EfectosDialogo = require(ReplicatedStorage:WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
local ServicioCamara = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("ServicioCamara"))
local Utilidades = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("Utilidades"))
local LevelsConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("LevelsConfig"))

local function notificarRespuestaCorrecta()
	Utilidades.notificarDialogoCorrecto()
end

-- Alias de nodos amigables
local nombres = LevelsConfig[2].NombresNodos
local aliasGen      = nombres["Gen_Fabrica_z1"]   or "Generador"
local aliasEntrada  = nombres["Entrada_z1"]       or "Entrada"
local aliasCruce    = nombres["Cruce_z1"]         or "Cruce"
local aliasSala     = nombres["Sala_Maquinas_z1"] or "Sala de Máquinas"

local COSTO_POR_METRO = LevelsConfig[2].CostoPorMetro or 500

local function costo(peso)
	return peso * COSTO_POR_METRO
end

local DIALOGOS = {
	["Nivel2_CiudadGrande"] = {
		Zona  = "Zona_Laberinto_1",
		Nivel = 2,
		Lineas = {
			-- 1. El Alcalde presiona por una solución rápida
			{
				Id        = "alcalde_presion",
				Numero    = 1,
				Actor     = "Alcalde",
				Expresion = "Disgustado",
				Texto     = "Carlos, ¿aún sigue usted husmeando? El Barrio Antiguo ya tiene luz. Ahora la Ciudad Grande está sin conexión y los ciudadanos exigen resultados. Conecten todo por el camino más corto y dejen de perder tiempo.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Gen_Fabrica_z1", { altura = 35, angulo = 75, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Gen_Fabrica_z1", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Entrada_z1", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Cruce_z1", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Sala_Maquinas_z1", "ADYACENTE")
				end,
				Siguiente = "carlos_responde",
			},

			-- 2. Carlos responde con la lección del Nivel 1
			{
				Id        = "carlos_responde",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Con todo respeto, señor Alcalde, en el Barrio Antiguo aprendimos que 'más corto en saltos' no significa 'mejor'. BFS y DFS nos mostraron dónde se cortó la red, pero ahora debemos auditar costos. Conectar por el camino con menos postes puede salir más caro.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Gen_Fabrica_z1", { altura = 28, angulo = 65, duracion = 1.2 })
					EfectosDialogo.resaltarNodo("Gen_Fabrica_z1", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("Gen_Fabrica_z1", aliasGen, "SELECCIONADO")
				end,
				Siguiente = "alcalde_enfurece",
			},

			-- 3. El Alcalde insiste en su versión
			{
				Id        = "alcalde_enfurece",
				Numero    = 3,
				Actor     = "Alcalde",
				Expresion = "Furioso",
				Texto     = "¡Insolencia! Mi plan de electrificación fue aprobado por los mejores técnicos. Ustedes solo necesitan tender cables, no cuestionar cada decisión. Menos saltos = menos material = menos dinero. ¡Hasta un niño lo entiende!",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Gen_Fabrica_z1", { altura = 35, angulo = 70, duracion = 1.2 })
				end,
				Siguiente = "intro_dijkstra",
			},

			-- 4. Carlos presenta Dijkstra como respuesta
			{
				Id        = "intro_dijkstra",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Presentacion",
				Texto     = "Tocino, el Alcalde confunde saltos con metros. Aquí usaremos el algoritmo de Dijkstra: suma el costo real de cada cable y elige la ruta más barata en dinero, no la que tiene menos postes.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Gen_Fabrica_z1", { altura = 30, angulo = 62, duracion = 1.2 })
					EfectosDialogo.resaltarNodo("Gen_Fabrica_z1", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Entrada_z1", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Cruce_z1", "ADYACENTE")
					EfectosDialogo.mostrarLabel("Gen_Fabrica_z1", "Inicio: " .. aliasGen)
				end,
				Siguiente = "peso_y_costo",
			},

			-- 5. Peso y costo
			{
				Id        = "peso_y_costo",
				Numero    = 5,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Cada arista tiene un peso: metros de cable. Como cada metro cuesta $" .. COSTO_POR_METRO .. ", multiplicamos peso × " .. COSTO_POR_METRO .. " para saber el dinero que gastamos. Por ejemplo, una arista de 2 metros cuesta $" .. costo(2) .. ", y una de 5 metros cuesta $" .. costo(5) .. ".",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Gen_Fabrica_z1", { altura = 26, angulo = 58, duracion = 1.2 })
					EfectosDialogo.resaltarNodo("Gen_Fabrica_z1", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Entrada_z1", "ADYACENTE")
					EfectosDialogo.mostrarArista("Gen_Fabrica_z1", "Entrada_z1", "SELECCIONADO", { sinParticulas = true })
					EfectosDialogo.mostrarLabel("Gen_Fabrica_z1", "2 m → $" .. costo(2), "SELECCIONADO")
					EfectosDialogo.mostrarLabel("Entrada_z1", "Adyacente", "ADYACENTE")
				end,
				Siguiente = "relajacion",
			},

			-- 6. Relajación
			{
				Id        = "relajacion",
				Numero    = 6,
				Actor     = "Carlos",
				Expresion = "Presentacion",
				Texto     = "El corazón de Dijkstra es la RELAJACIÓN: cuando encontramos una forma más barata de llegar a un nodo, actualizamos su costo mínimo. Si llegar por un camino cuesta menos que por otro, ¡guardamos el más barato!",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Sala_Maquinas_z1", { altura = 28, angulo = 60, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Sala_Maquinas_z1", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Entrada_z1", "ADYACENTE")
					EfectosDialogo.mostrarLabel("Sala_Maquinas_z1", "Destino: " .. aliasSala)
				end,
				Siguiente = "ejemplo_rutas",
			},

			-- 7. Ejemplo de rutas
			{
				Id        = "ejemplo_rutas",
				Numero    = 7,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Mira las dos formas de llegar a la " .. aliasSala .. ". Por la Entrada: 2 + 3 = 5 metros ($" .. costo(5) .. "). Por el Cruce: 5 + ... mucho más. Dijkstra elegirá la ruta de la Entrada porque su costo acumulado es menor, aunque ambas lleguen al mismo sitio.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Gen_Fabrica_z1", { altura = 32, angulo = 65, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Gen_Fabrica_z1", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Entrada_z1", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Sala_Maquinas_z1", "EXITO")
					task.delay(0.3, function()
						EfectosDialogo.mostrarArista("Gen_Fabrica_z1", "Entrada_z1", "SELECCIONADO", { sinParticulas = true })
						EfectosDialogo.mostrarArista("Entrada_z1", "Sala_Maquinas_z1", "SELECCIONADO", { sinParticulas = true })
					end)
					task.delay(0.6, function()
						EfectosDialogo.mostrarLabel("Gen_Fabrica_z1", "0 m")
						EfectosDialogo.mostrarLabel("Entrada_z1", "2 m")
						EfectosDialogo.mostrarLabel("Sala_Maquinas_z1", "5 m ✓")
					end)
				end,
				Siguiente = "pregunta_dijkstra",
			},

			-- 8. Pregunta de validación
			{
				Id        = "pregunta_dijkstra",
				Numero    = 8,
				Actor     = "Carlos",
				Expresion = "Sonriente",
				Texto     = "Pregunta rápida: ¿qué criterio usa Dijkstra para elegir el mejor camino?",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Cruce_z1", { altura = 28, angulo = 60, duracion = 1.0 })
					EfectosDialogo.resaltarNodo("Cruce_z1", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("Cruce_z1", "¿Por dónde voy?")
				end,
				Opciones = {
					{ Texto = "La suma total de pesos (costo acumulado) desde el inicio hasta el destino.", Siguiente = "resp_dijkstra_bien" },
					{ Texto = "La cantidad de nodos que visita, sin importar los pesos.", Siguiente = "resp_dijkstra_mal" },
					{ Texto = "El orden alfabético de los nombres de los nodos.", Siguiente = "resp_dijkstra_mal2" },
				},
			},

			-- 9a. Respuesta correcta
			{
				Id        = "resp_dijkstra_bien",
				Numero    = 9,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "¡Exacto! Dijkstra siempre busca el camino con el menor costo acumulado. Por eso necesita conocer los pesos de las aristas y no solo la estructura del grafo.",
				Evento = function()
					local jugador = game:GetService("Players").LocalPlayer
					if jugador then
						local puntajeActual = jugador:GetAttribute("PuntajeDialogo") or 0
						jugador:SetAttribute("PuntajeDialogo", puntajeActual + 100)
					end
					notificarRespuestaCorrecta()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Sala_Maquinas_z1", "EXITO")
					EfectosDialogo.blink("Sala_Maquinas_z1", "EXITO", 3)
				end,
				Opciones = { { Texto = "A conectar", Siguiente = "instruccion_final" } },
			},

			-- 9b. Respuesta incorrecta 1
			{
				Id        = "resp_dijkstra_mal",
				Numero    = 9,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Casi, pero no. Contar nodos es lo que hace BFS para hallar el camino con menos saltos. Dijkstra va más allá: suma los pesos y elige la ruta más barata en costo total.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Entrada_z1", "ERROR")
					EfectosDialogo.mostrarLabel("Entrada_z1", "No solo saltos")
				end,
				Opciones = { { Texto = "Entendido", Siguiente = "instruccion_final" } },
			},

			-- 9c. Respuesta incorrecta 2
			{
				Id        = "resp_dijkstra_mal2",
				Numero    = 9,
				Actor     = "Carlos",
				Expresion = "Enojado",
				Texto     = "¡No! Dijkstra no mira el nombre de los nodos. Mira los pesos de las aristas y compara costos acumulados para elegir el camino más económico.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Cruce_z1", "ERROR")
					EfectosDialogo.mostrarLabel("Cruce_z1", "Depende del peso")
				end,
				Opciones = { { Texto = "Entendido", Siguiente = "instruccion_final" } },
			},

			-- 10. Instrucción final
			{
				Id        = "instruccion_final",
				Numero    = 10,
				Actor     = "Sistema",
				Texto     = "Conecta la red desde " .. aliasGen .. " hasta " .. aliasSala .. " gastando lo menos posible. Abre el Panel de Análisis (Tecla Tab) para ejecutar Dijkstra. ¡Cuida el presupuesto!",
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
