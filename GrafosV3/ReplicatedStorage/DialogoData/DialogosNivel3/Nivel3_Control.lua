
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EfectosDialogo    = require(ReplicatedStorage:WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
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
		Zona = "Zona_Alcaldia",
		Nivel = 3,
		Lineas = {
			-- 1. Apertura de la rueda de prensa
			{
				Id = "inicio",
				Numero = 1,
				Actor = "Sistema",
				Expresion = "Normal",
				Texto = "Es medianoche en Villa Conexa. Las luces de emergencia del hospital se reflejan sobre la plaza. Frente a la Alcaldía, cámaras y micrófonos cercan el atril mientras la multitud contiene el aliento.",
				Evento = function()
					aciertosFinales = 0
					jugador:SetAttribute(ATRIBUTO_RESULTADO, nil)
					EfectosDialogo.limpiarTodo()
				end,
				Siguiente = "apertura_reportero",
			},
			{
				Id = "apertura_reportero",
				Numero = 2,
				Actor = "Reportero",
				Expresion = "Normal",
				Texto = "Señor Alcalde, esta transmisión es en vivo. Explique por qué su red millonaria dejó los quirófanos al borde de la oscuridad. Cada palabra quedará registrada.",
				Siguiente = "ciudadanos_felices",
			},

			-- 2. Ciudadanos aplauden los "logros" visibles
			{
				Id = "ciudadanos_felices",
				Numero = 2,
				Actor = "Sistema",
				Expresion = "Normal",
				Texto = "La plaza hierve en murmullos. Algunos levantan carteles a favor del Alcalde; otros miran las ventanas intermitentes del hospital. Hay cables por todas partes, sí... pero esta noche nadie confunde cantidad con seguridad.",
				Siguiente = "version_alcalde",
			},

			-- 3. El Alcalde presume su obra
			{
				Id = "version_alcalde",
				Numero = 3,
				Actor = "Alcalde",
				Expresion = "Sonriente",
				Texto = "No permitan que una falla aislada manche años de progreso. Mi administración tendió más cable que ninguna otra. Una ciudad cubierta de cobre es una ciudad protegida. Los costos son laberintos contables; no cargas que deban llevar ustedes. Déjenme gobernar.",
				Siguiente = "interrupcion",
			},

			-- 4. Carlos interrumpe con evidencia de todos los niveles
			{
				Id = "interrupcion",
				Numero = 4,
				Actor = "Carlos",
				Expresion = "Serio",
				Texto = "Mi hijo estaba en ese hospital cuando las luces cayeron. Escuché detenerse las máquinas detrás de una puerta que no podía abrir. No vengo como ingeniero resentido; vengo como padre. Seguimos su cableado barrio por barrio: BFS abrió el mapa, DFS entró en sus callejones, Dijkstra siguió el rastro del dinero y Prim separó la red necesaria de la telaraña que usted cobró.",
				Siguiente = "alcalde_defiende",
			},

			-- 5. El Alcalde intenta defenderse
			{
				Id = "alcalde_defiende",
				Numero = 5,
				Actor = "Alcalde",
				Expresion = "Enojado",
				Texto = "Una historia conmovedora no es una auditoría, Carlos. Está usando a su hijo para convertir números incomprensibles en una cacería política. Mi red une cada barrio. Si encontró callejones, quizá fue porque usted necesitaba perderse para fabricar un culpable.",
				Siguiente = "reportero_pide_pruebas",
			},

			-- 6. El Reportero abre el cuestionamiento
			{
				Id = "reportero_pide_pruebas",
				Numero = 6,
				Actor = "Reportero",
				Expresion = "Normal",
				Texto = "Basta de discursos. Pondré cuatro piezas del expediente sobre la mesa: BFS, DFS, Dijkstra y Prim. Tocino responderá. Tras cada respuesta veremos si la multitud se acerca a la verdad... o si el Alcalde consigue enterrarla bajo otra capa de cable.",
				Siguiente = "pregunta_1",
			},

			-- Primera prueba: BFS
			{
				Id = "pregunta_1",
				Numero = 7,
				Actor = "Reportero",
				Expresion = "Normal",
				Texto = "Primera prueba. Cuando el apagón se extendió por el Barrio Antiguo como tinta sobre un plano, necesitábamos inspeccionar primero todos los postes cercanos al generador y luego avanzar barrio por barrio. ¿Qué hizo BFS?",
				Opciones = {
					{ Texto = "Siguió una sola rama hasta el fondo antes de revisar los vecinos cercanos.", Siguiente = "p1_mal" },
					{ Texto = "Usó una cola y recorrió la red por niveles, como ondas de luz que alcanzan primero los postes más cercanos.", Siguiente = "p1_bien", OnSelect = acertar },
					{ Texto = "Sumó el precio de todos los cables para encontrar la ruta más barata.", Siguiente = "p1_mal" },
				},
			},

			-- 8a. Respuesta correcta P1
			{
				Id = "p1_bien",
				Numero = 8,
				Actor = "Sistema",
				Expresion = "Feliz",
				Texto = "La pantalla confirma el recorrido: una ola ordenada, capa por capa. Los ciudadanos señalan los barrios que quedaron fuera. BFS no inventó el apagón; mostró exactamente dónde dejó de propagarse la luz.",
				Siguiente = "reaccion_1",
			},

			-- 8b. Respuesta incorrecta P1
			{
				Id = "p1_mal",
				Numero = 8,
				Actor = "Alcalde",
				Expresion = "Malevolo",
				Texto = "Confunden una cola con una prueba. Si eso es lo mejor que tienen, su acusación ya comenzó a desmoronarse.",
				Siguiente = "reaccion_1",
			},

			-- 9. Reacción ciudadana antes de P2
			{
				Id = "reaccion_1",
				Numero = 9,
				Actor = "Sistema",
				Expresion = "Normal",
				Texto = "Un murmullo recorre la plaza como corriente por un cable desnudo. El Reportero no concede pausa; desliza una segunda hoja del expediente.",
				Siguiente = "pregunta_recorridos",
			},

			-- Segunda prueba: DFS
			{
				Id = "pregunta_recorridos",
				Numero = 10,
				Actor = "Reportero",
				Expresion = "Normal",
				Texto = "Segunda prueba. Había que entrar en cada ramal sospechoso, seguirlo hasta donde muriera y retroceder para abrir el siguiente. ¿Cómo avanzó DFS por esa red?",
				Opciones = {
					{ Texto = "Visitó simultáneamente todos los nodos de la misma distancia.", Siguiente = "recorridos_mal" },
					{ Texto = "Escogió siempre la arista de menor peso para evitar ciclos.", Siguiente = "recorridos_mal" },
					{ Texto = "Profundizó por una rama usando pila o recursión y, al hallar un callejón, retrocedió hasta encontrar otra salida.", Siguiente = "recorridos_bien", OnSelect = acertar },
				},
			},
			{
				Id = "recorridos_bien",
				Numero = 11,
				Actor = "Sistema",
				Expresion = "Feliz",
				Texto = "El trazado se hunde por una rama, toca fondo y regresa. Varias personas asienten: reconocen sus propias calles en aquel recorrido. DFS fue una linterna entrando en cada túnel que el contrato fingía no ver.",
				Siguiente = "pregunta_2",
			},
			{
				Id = "recorridos_mal",
				Numero = 11,
				Actor = "Sistema",
				Expresion = "Triste",
				Texto = "El Alcalde golpea el atril. «Ni siquiera saben cómo siguieron sus propios cables». Los murmullos se vuelven incómodos. DFS debía profundizar y retroceder; la respuesta dejó ese túnel a oscuras.",
				Siguiente = "pregunta_2",
			},

			-- Tercera prueba: Dijkstra
			{
				Id = "pregunta_2",
				Numero = 10,
				Actor = "Reportero",
				Expresion = "Normal",
				Texto = "Tercera prueba. El Alcalde vendió una ruta directa como si pocas esquinas significaran poco dinero. Pero cada cable llevaba un precio escondido, como piedras dentro de un maletín. ¿Qué comparó Dijkstra?",
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
				Actor = "Sistema",
				Expresion = "Feliz",
				Texto = "El Oficial levanta las facturas. Dijkstra sumó cada peso acumulado y la supuesta ruta «directa» resultó ser la más cara. La plaza deja de murmurar: ahora cuenta.",
				Siguiente = "confrontacion_ciudadana",
			},

			-- 11b. Respuesta incorrecta P2
			{
				Id = "p2_mal",
				Numero = 11,
				Actor = "Sistema",
				Expresion = "Triste",
				Texto = "El Oficial cierra la carpeta. Sin costo acumulado no hay rastro del dinero. El Alcalde aprovecha el silencio: «Ven fantasmas donde solo hay infraestructura».",
				Siguiente = "confrontacion_ciudadana",
			},

			-- 12. Confrontación ciudadana
			{
				Id = "confrontacion_ciudadana",
				Numero = 12,
				Actor = "Ciudadanos",
				Expresion = "Normal",
				Texto = "¡Aquí están nuestros recibos, las fotografías y las órdenes de compra! ¿Por qué ocultó el peso de cada cable? ¿Cuánto valía para usted la vida de quienes estaban conectados al hospital?",
				Siguiente = "alcalde_evasivo",
			},

			-- 13. El Alcalde se vuelve evasivo
			{
				Id = "alcalde_evasivo",
				Numero = 13,
				Actor = "Alcalde",
				Expresion = "Enojado",
				Texto = "La ciudad no se gobierna con diagramas. Se gobierna con confianza, y ustedes me la dieron. Si el hospital falló, fue sabotaje. Carlos tenía acceso, motivos y una tragedia personal perfecta para fabricar esta escena.",
				Siguiente = "pregunta_3",
			},

			-- Cuarta prueba: Prim
			{
				Id = "pregunta_3",
				Numero = 14,
				Actor = "Reportero",
				Expresion = "Normal",
				Texto = "Última prueba. Imagine la ciudad como un bosque de postes: todos deben quedar unidos, pero cada ciclo es una soga de cobre cobrada dos veces. ¿Qué demuestra el árbol de expansión mínima construido por Prim?",
				Opciones = {
					{ Texto = "Que el camino entre dos nodos siempre debe usar todos los cables disponibles.", Siguiente = "p3_mal" },
					{ Texto = "Que se puede conectar toda la red con el mínimo tendido de cable, sin ciclos ni desperdicio, reduciendo costos y saturación.", Siguiente = "p3_bien", OnSelect = acertar },
					{ Texto = "Que aumentar el grado de todos los nodos reduce automáticamente el costo.", Siguiente = "p3_mal" },
				},
			},

			-- 15a. Respuesta correcta P3
			{
				Id = "p3_bien",
				Numero = 15,
				Actor = "Sistema",
				Expresion = "Feliz",
				Texto = "La matriz cae sobre la pantalla como una sentencia: 20 unidades en el Sector Residencial, 22 en el Hospital y 4 en el enlace. Peso mínimo total: 46. Prim dejó toda la ciudad conectada y cortó cada ciclo donde podía esconderse un sobrecosto.",
				Siguiente = "resultado_exito",
			},

			-- 15b. Respuesta incorrecta P3
			{
				Id = "p3_mal",
				Numero = 15,
				Actor = "Alcalde",
				Expresion = "Codicioso",
				Texto = "No pueden distinguir una obra de un árbol. Mi red conecta todo; sus números solo podan la seguridad de esta ciudad.",
				Siguiente = "resultado_exito",
			},

			-- Resultado: la luz del hospital simboliza el veredicto.
			{
				Id = "resultado_exito",
				Numero = 16,
				Actor = "Sistema",
				Expresion = "Feliz",
				Texto = "Las cuatro rutas encajan. La plaza estalla: ya no es ruido, es una sola voz. En la colina, las ventanas del hospital se encienden una tras otra, como si la verdad encontrara por fin un camino hasta cada habitación.",
				Condicion = function()
					return aciertosFinales == 4
				end,
				Evento = function()
					marcarResultado("exito")
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("PosteHospital_z2", "EXITO")
					EfectosDialogo.mostrarLabel("PosteHospital_z2", "LA VERDAD SALE A LA LUZ", "EXITO")
					EfectosDialogo.blink("PosteHospital_z2", "EXITO", 4)
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
				Texto = "Queda detenido mientras investigamos corrupción, sobrecostos y negligencia. Esta vez los números no serán enterrados. Carlos, su hijo está a salvo; el hospital vuelve a tener energía estable.",
				Siguiente = "FIN",
			},

			-- 18. Resultado: fracaso
			{
				Id = "resultado_fracaso",
				Numero = 16,
				Actor = "Sistema",
				Expresion = "Normal",
				Texto = "FALLO DE AUDITORÍA. El Alcalde alza los brazos y sus partidarios ahogan las dudas con aplausos. Las pruebas quedan incompletas y la multitud comienza a dispersarse. Carlos permanece inmóvil, pensando en su hijo y en una verdad que no logró atravesar la plaza.",
				Evento = function()
					marcarResultado("fracaso")
					EfectosDialogo.limpiarTodo()
				end,
				Siguiente = "oficial_fracaso",
			},

			-- 19. Oficial en caso de fracaso
			{
				Id = "oficial_fracaso",
				Numero = 17,
				Actor = "Oficial",
				Expresion = "Normal",
				Texto = "Sin una cadena completa de pruebas no puedo detenerlo. Señor Alcalde, puede retirarse. Su oficina queda autorizada para presentar cargos por calumnia.",
				Condicion = function()
					return aciertosFinales < 4
				end,
				Siguiente = "FIN",
			},
		},
		EventoSalida = function()
			if jugador:GetAttribute(ATRIBUTO_RESULTADO) == nil then
				aciertosFinales = 0
				marcarResultado("fracaso")
			end
		end,
		Metadata = { TiempoDeEspera = 0.5, VelocidadTypewriter = 0.03, PuedeOmitir = true, OcultarHUD = true, UsarTTS = true },
		Configuracion = { bloquearMovimiento = true, bloquearSalto = true, apuntarCamara = true, ocultarTechos = true },
	},
}

return DIALOGOS
