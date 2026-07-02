-- Final_1 — rueda de prensa y desenlace del nivel 3.
-- La misión solo tiene éxito si se contestan correctamente las tres preguntas.
-- Estructura narrativa:
--   1. Rueda de prensa: el Alcalde presume sus "logros".
--   2. Carlos lo interrumpe con evidencia acumulada de los niveles 0, 1, 2 y 3.
--   3. El Reportero cuestiona al Alcalde con 3 preguntas integradoras.
--   4. Las respuestas correctas demuestran que sus números no cuadran.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EfectosDialogo    = require(ReplicatedStorage:WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
local ServicioCamara    = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("ServicioCamara"))
local Utilidades        = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("Utilidades"))

local jugador = Players.LocalPlayer
local aciertosFinales = 0
local ATRIBUTO_RESULTADO = "ResultadoDialogo_Final_1"

local function acertar()
	aciertosFinales = aciertosFinales + 1
	Utilidades.notificarDialogoCorrecto()
end

local function marcarResultado(resultado)
	jugador:SetAttribute(ATRIBUTO_RESULTADO, resultado)
end

local DIALOGOS = {
	["Final_1"] = {
		Zona = "Zona_Hospital_2",
		Nivel = 3,
		Lineas = {
			-- 1. Apertura de la rueda de prensa
			{
				Id = "inicio",
				Numero = 1,
				Actor = "Reportero",
				Expresion = "Normal",
				Texto = "Buenas noches. Estamos en vivo desde el Hospital Central, donde el Alcalde ha convocado una rueda de prensa para presentar los resultados de su plan de modernización eléctrica. Las luces de emergencia aún parpadean tras la falla de hace minutos.",
				Evento = function()
					aciertosFinales = 0
					jugador:SetAttribute(ATRIBUTO_RESULTADO, nil)
					EfectosDialogo.limpiarTodo()
				end,
				Siguiente = "ciudadanos_felices",
			},

			-- 2. Ciudadanos aplauden los "logros" visibles
			{
				Id = "ciudadanos_felices",
				Numero = 2,
				Actor = "Ciudadanos",
				Expresion = "Normal",
				Texto = "¡Viva el Alcalde! Vemos postes nuevos, cables por todas partes y obras en cada barrio. ¡Eso es progreso! Seguramente todo ese dinero se utilizó para protegernos.",
				Siguiente = "version_alcalde",
			},

			-- 3. El Alcalde presume su obra
			{
				Id = "version_alcalde",
				Numero = 3,
				Actor = "Alcalde",
				Expresion = "Sonriente",
				Texto = "Gracias, gracias. Mi administración ha instalado más cableado que ninguna otra en la historia de Villa Conexa. Cuantos más cables tiene una red, más segura es. Los costos exactos son asuntos administrativos que no necesitan preocupar a los ciudadanos.",
				Siguiente = "interrupcion",
			},

			-- 4. Carlos interrumpe con evidencia de todos los niveles
			{
				Id = "interrupcion",
				Numero = 4,
				Actor = "Carlos",
				Expresion = "Serio",
				Texto = "¡Eso es falso! Esta misma noche reparamos el hospital. Pero no empezó aquí: en el Barrio Antiguo, BFS y DFS revelaron un grafo desconexo que dejó familias a oscuras. En la Ciudad Grande, Dijkstra demostró que sus 'rutas directas' costaban más que las alternativas. Y ahora, en el Sector Residencial y el Hospital, Prim demuestra que sus conexiones redundantes inflaron el presupuesto, elevaron el grado de los nodos y saturaron el sistema.",
				Siguiente = "alcalde_defiende",
			},

			-- 5. El Alcalde intenta defenderse
			{
				Id = "alcalde_defiende",
				Numero = 5,
				Actor = "Alcalde",
				Expresion = "Enojado",
				Texto = "¡Son solo teorías de un ingeniero resentido! Mi plan conecta todo: la Estación, el Mercado, las Canchas, el Parque, la Ciudad, la Oficina, el Sector Residencial y ahora el Hospital. ¿Acaso no ven que todo está unido?",
				Siguiente = "reportero_pide_pruebas",
			},

			-- 6. El Reportero abre el cuestionamiento
			{
				Id = "reportero_pide_pruebas",
				Numero = 6,
				Actor = "Reportero",
				Expresion = "Normal",
				Texto = "Es una acusación grave. Ingeniero, tiene tres oportunidades para demostrar con datos lo que aprendieron en cada zona. Si fallan, el Alcalde podrá denunciarlos por calumnia.",
				Siguiente = "pregunta_1",
			},

			-- 7. Pregunta 1: conectividad, grados y sobrecarga (Niveles 0 y 1)
			{
				Id = "pregunta_1",
				Numero = 7,
				Actor = "Reportero",
				Expresion = "Normal",
				Texto = "Primera pregunta: en el Barrio Antiguo, BFS y DFS revelaron que la red del Alcalde no llegaba a todos los nodos. ¿Qué combinación de problemas explica por qué una red con 'muchos cables' puede dejar sectores sin luz y causar emergencias?",
				Opciones = {
					{ Texto = "Porque los cables estaban mal distribuidos: nodos aislados, grafos desconexos y postes sobrecargados por exceso de grado.", Siguiente = "p1_bien", OnSelect = acertar },
					{ Texto = "Porque BFS y DFS siempre dejan nodos sin visitar a propósito.", Siguiente = "p1_mal" },
					{ Texto = "Porque cuanto mayor es el grado de un nodo, menos energía consume.", Siguiente = "p1_mal" },
				},
			},

			-- 8a. Respuesta correcta P1
			{
				Id = "p1_bien",
				Numero = 8,
				Actor = "Sistema",
				Expresion = "Feliz",
				Texto = "Evidencia correcta: en el Laboratorio de Grafos aprendimos que un nodo aislado no recibe energía, y en el Mercado Central vimos que un poste con grado excesivo puede sobrecargarse. La cantidad de cables no importa si no están bien distribuidos.",
				Siguiente = "reaccion_1",
			},

			-- 8b. Respuesta incorrecta P1
			{
				Id = "p1_mal",
				Numero = 8,
				Actor = "Alcalde",
				Expresion = "Malevolo",
				Texto = "Ni siquiera entienden por qué falló la red. Sus acusaciones empiezan a desmoronarse.",
				Siguiente = "reaccion_1",
			},

			-- 9. Reacción ciudadana antes de P2
			{
				Id = "reaccion_1",
				Numero = 9,
				Actor = "Ciudadanos",
				Expresion = "Normal",
				Texto = "Queremos ver números claros. Continúen con la auditoría.",
				Siguiente = "pregunta_2",
			},

			-- 10. Pregunta 2: Dijkstra, pesos y costo acumulado (Nivel 2)
			{
				Id = "pregunta_2",
				Numero = 10,
				Actor = "Reportero",
				Expresion = "Normal",
				Texto = "Segunda pregunta: en la Ciudad Grande y el Barrio Oeste, Dijkstra demostró que el Alcalde confundía distancia con dinero. ¿Por qué una ruta con menos saltos no siempre es la más barata?",
				Opciones = {
					{ Texto = "Porque cada arista tiene un peso o costo distinto; Dijkstra suma el costo acumulado, no solo cuenta los saltos.", Siguiente = "p2_bien", OnSelect = acertar },
					{ Texto = "Porque el Alcalde siempre elige la ruta con más postes.", Siguiente = "p2_mal" },
					{ Texto = "Porque Dijkstra solo funciona cuando todas las aristas tienen el mismo peso.", Siguiente = "p2_mal" },
				},
			},

			-- 11a. Respuesta correcta P2
			{
				Id = "p2_bien",
				Numero = 11,
				Actor = "Oficial",
				Expresion = "Normal",
				Texto = "El informe de la Oficina de Análisis respalda esa explicación: la ruta 'directa' propuesta por el Alcalde costaba más que las alternativas calculadas por Dijkstra. Cada metro de cable a $500 suma.",
				Siguiente = "confrontacion_ciudadana",
			},

			-- 11b. Respuesta incorrecta P2
			{
				Id = "p2_mal",
				Numero = 11,
				Actor = "Oficial",
				Expresion = "Normal",
				Texto = "Esa respuesta no coincide con el informe técnico de la Oficina de Análisis. Los pesos de las aristas determinan el costo real.",
				Siguiente = "confrontacion_ciudadana",
			},

			-- 12. Confrontación ciudadana
			{
				Id = "confrontacion_ciudadana",
				Numero = 12,
				Actor = "Ciudadanos",
				Expresion = "Normal",
				Texto = "Alcalde, ¿por qué ocultó los grados de los nodos y el costo real de cada cable? Usted dijo que 'más cables es más seguridad', pero esta noche el Hospital estuvo a punto de quedar a oscuras.",
				Siguiente = "alcalde_evasivo",
			},

			-- 13. El Alcalde se vuelve evasivo
			{
				Id = "alcalde_evasivo",
				Numero = 13,
				Actor = "Alcalde",
				Expresion = "Enojado",
				Texto = "¡Porque los ciudadanos no necesitan entender algoritmos! Lo importante es que vean muchas obras. Si el hospital falló fue por un sabotaje, no por mis números.",
				Siguiente = "pregunta_3",
			},

			-- 14. Pregunta 3: Prim y MST (Nivel 3)
			{
				Id = "pregunta_3",
				Numero = 14,
				Actor = "Reportero",
				Expresion = "Normal",
				Texto = "Última pregunta: en el Sector Residencial y el Complejo Hospitalario, Prim construyó el Árbol de Expansión Mínima. ¿qué demuestra ese resultado frente al argumento del Alcalde de que 'más cables = más seguridad'?",
				Opciones = {
					{ Texto = "Que se puede conectar toda la red con el mínimo tendido de cable, sin ciclos ni desperdicio, reduciendo costos y saturación.", Siguiente = "p3_bien", OnSelect = acertar },
					{ Texto = "Que el camino entre dos nodos siempre debe usar todos los cables disponibles.", Siguiente = "p3_mal" },
					{ Texto = "Que aumentar el grado de todos los nodos reduce automáticamente el costo.", Siguiente = "p3_mal" },
				},
			},

			-- 15a. Respuesta correcta P3
			{
				Id = "p3_bien",
				Numero = 15,
				Actor = "Sistema",
				Expresion = "Feliz",
				Texto = "La explicación de Prim coincide con la matriz, los pesos y la red reparada: 22 unidades en el Sector Residencial, 15 en el Hospital y 4 en el enlace entre zonas, para un total mínimo de 41.",
				Siguiente = "resultado_exito",
			},

			-- 15b. Respuesta incorrecta P3
			{
				Id = "p3_mal",
				Numero = 15,
				Actor = "Alcalde",
				Expresion = "Codicioso",
				Texto = "Tres preguntas eran suficientes para demostrar que no tienen pruebas sólidas. Mi plan conecta todo y eso es lo que importa.",
				Siguiente = "resultado_exito",
			},

			-- 16. Resultado: éxito si aciertos == 3
			{
				Id = "resultado_exito",
				Numero = 16,
				Actor = "Ciudadanos",
				Expresion = "Normal",
				Texto = "¡Las tres pruebas coinciden! Alcalde, infló los costos y puso en peligro al hospital. Exigimos una investigación.",
				Condicion = function()
					return aciertosFinales == 3
				end,
				Evento = function()
					marcarResultado("exito")
				end,
				SiguienteSiFalso = "resultado_fracaso",
				Siguiente = "oficial_exito",
			},

			-- 17. Oficial confirma investigación
			{
				Id = "oficial_exito",
				Numero = 17,
				Actor = "Oficial",
				Expresion = "Normal",
				Texto = "Las pruebas quedan registradas. Abriremos una investigación por corrupción, sobrecostos y negligencia en la emergencia hospitalaria.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.restaurar(1.2)
				end,
				Siguiente = "FIN",
			},

			-- 18. Resultado: fracaso
			{
				Id = "resultado_fracaso",
				Numero = 16,
				Actor = "Ciudadanos",
				Expresion = "Normal",
				Texto = "Las respuestas no fueron suficientes. Confiamos en las obras que podemos ver y no en acusaciones sin pruebas completas.",
				Evento = function()
					marcarResultado("fracaso")
				end,
				Siguiente = "oficial_fracaso",
			},

			-- 19. Oficial en caso de fracaso
			{
				Id = "oficial_fracaso",
				Numero = 17,
				Actor = "Oficial",
				Expresion = "Normal",
				Texto = "El Alcalde presentará una denuncia por calumnia. La rueda de prensa ha terminado.",
				Condicion = function()
					return aciertosFinales < 3
				end,
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.restaurar(1.2)
				end,
				Siguiente = "FIN",
			},
		},
		Metadata = { TiempoDeEspera = 0.5, VelocidadTypewriter = 0.03, PuedeOmitir = false, OcultarHUD = true, UsarTTS = true },
		Configuracion = { bloquearMovimiento = true, bloquearSalto = true, apuntarCamara = true, ocultarTechos = true },
	},
}

return DIALOGOS
