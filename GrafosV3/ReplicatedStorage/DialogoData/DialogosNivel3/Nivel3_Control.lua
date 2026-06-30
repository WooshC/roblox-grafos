-- Final_1 — rueda de prensa y desenlace del nivel 3.
-- La misión solo tiene éxito si se contestan correctamente las tres preguntas.

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
			{
				Id = "inicio",
				Numero = 1,
				Actor = "Reportero",
				Expresion = "Normal",
				Texto = "En esta noche oscura, las luces de emergencia iluminan la rueda de prensa junto al Hospital Central. El Alcalde asegura que sus obras dejaron la mejor red eléctrica de la historia.",
				Evento = function()
					aciertosFinales = 0
					jugador:SetAttribute(ATRIBUTO_RESULTADO, nil)
					EfectosDialogo.limpiarTodo()
				end,
				Siguiente = "ciudadanos_felices",
			},
			{
				Id = "ciudadanos_felices",
				Numero = 2,
				Actor = "Ciudadanos",
				Expresion = "Normal",
				Texto = "¡Viva el Alcalde! Vemos postes nuevos y muchos cables. Seguramente todo ese dinero se utilizó para protegernos.",
				Siguiente = "version_alcalde",
			},
			{
				Id = "version_alcalde",
				Numero = 3,
				Actor = "Alcalde",
				Expresion = "Sonriente",
				Texto = "Así es. Cada centavo fue invertido. Cuantos más cables tiene una red, más segura es. Los costos exactos son asuntos administrativos que no necesitan preocupar a los ciudadanos.",
				Siguiente = "interrupcion",
			},
			{
				Id = "interrupcion",
				Numero = 4,
				Actor = "Carlos",
				Expresion = "Serio",
				Texto = "¡Eso es falso! Esta misma noche reparamos el hospital. Sus conexiones redundantes inflaron el presupuesto, aumentaron innecesariamente el grado de los nodos y saturaron el sistema.",
				Siguiente = "reportero_pide_pruebas",
			},
			{
				Id = "reportero_pide_pruebas",
				Numero = 5,
				Actor = "Reportero",
				Expresion = "Normal",
				Texto = "Es una acusación grave. Tendrán tres oportunidades para demostrarla con datos. Si fallan, el Alcalde podrá denunciarlos por calumnia.",
				Siguiente = "pregunta_1",
			},
			{
				Id = "pregunta_1",
				Numero = 6,
				Actor = "Reportero",
				Expresion = "Normal",
				Texto = "Primera pregunta: ¿cuál es el peso mínimo comprobado para conectar las dos zonas usando sus MST y el enlace más barato?",
				Opciones = {
					{ Texto = "41 unidades de peso: 22 residencial + 15 hospital + 4 del enlace.", Siguiente = "p1_bien", OnSelect = acertar },
					{ Texto = "37 unidades, porque las zonas no necesitan conectarse entre sí.", Siguiente = "p1_mal" },
					{ Texto = "46 unidades, porque deben utilizarse los dos enlaces entre zonas.", Siguiente = "p1_mal" },
				},
			},
			{
				Id = "p1_bien",
				Numero = 7,
				Actor = "Sistema",
				Expresion = "Feliz",
				Texto = "Evidencia correcta: el costo mínimo total se obtiene sin conexiones redundantes.",
				Siguiente = "reaccion_1",
			},
			{
				Id = "p1_mal",
				Numero = 7,
				Actor = "Alcalde",
				Expresion = "Malevolo",
				Texto = "Ni siquiera conocen el costo mínimo. Sus acusaciones empiezan a desmoronarse.",
				Siguiente = "reaccion_1",
			},
			{
				Id = "reaccion_1",
				Numero = 8,
				Actor = "Ciudadanos",
				Expresion = "Normal",
				Texto = "Queremos ver números claros. Continúen con la auditoría.",
				Siguiente = "pregunta_2",
			},
			{
				Id = "pregunta_2",
				Numero = 9,
				Actor = "Reportero",
				Expresion = "Normal",
				Texto = "Segunda pregunta: ¿por qué agregar cables innecesarios pudo causar la emergencia hospitalaria?",
				Opciones = {
					{ Texto = "Porque elevó el grado y concentró carga en nodos que terminaron saturándose.", Siguiente = "p2_bien", OnSelect = acertar },
					{ Texto = "Porque los nodos con menor grado siempre consumen más energía.", Siguiente = "p2_mal" },
					{ Texto = "Porque una red eléctrica no puede tener más de una arista.", Siguiente = "p2_mal" },
				},
			},
			{
				Id = "p2_bien",
				Numero = 10,
				Actor = "Oficial",
				Expresion = "Normal",
				Texto = "El informe de emergencia confirma esa explicación: hubo grados innecesarios y sobrecarga.",
				Siguiente = "confrontacion_ciudadana",
			},
			{
				Id = "p2_mal",
				Numero = 10,
				Actor = "Oficial",
				Expresion = "Normal",
				Texto = "Esa respuesta no coincide con el informe técnico de la emergencia.",
				Siguiente = "confrontacion_ciudadana",
			},
			{
				Id = "confrontacion_ciudadana",
				Numero = 11,
				Actor = "Ciudadanos",
				Expresion = "Normal",
				Texto = "Alcalde, ¿por qué ocultó los grados de los nodos y el costo real de cada cable?",
				Siguiente = "alcalde_evasivo",
			},
			{
				Id = "alcalde_evasivo",
				Numero = 12,
				Actor = "Alcalde",
				Expresion = "Enojado",
				Texto = "¡Porque los ciudadanos no necesitan entender algoritmos! Lo importante es que vean muchas obras.",
				Siguiente = "pregunta_3",
			},
			{
				Id = "pregunta_3",
				Numero = 13,
				Actor = "Reportero",
				Expresion = "Normal",
				Texto = "Última pregunta: ¿qué demuestra Prim frente al argumento del Alcalde?",
				Opciones = {
					{ Texto = "Que se puede conectar todo con mínimo costo, sin ciclos ni cables de más.", Siguiente = "p3_bien", OnSelect = acertar },
					{ Texto = "Que el camino entre dos nodos siempre debe usar todos los cables.", Siguiente = "p3_mal" },
					{ Texto = "Que aumentar el grado de todos los nodos reduce automáticamente el costo.", Siguiente = "p3_mal" },
				},
			},
			{
				Id = "p3_bien",
				Numero = 14,
				Actor = "Sistema",
				Expresion = "Feliz",
				Texto = "La explicación de Prim coincide con la matriz, los pesos y la red reparada.",
				Siguiente = "resultado_exito",
			},
			{
				Id = "p3_mal",
				Numero = 14,
				Actor = "Alcalde",
				Expresion = "Codicioso",
				Texto = "Tres preguntas eran suficientes para demostrar que no tienen pruebas sólidas.",
				Siguiente = "resultado_exito",
			},
			{
				Id = "resultado_exito",
				Numero = 15,
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
			{
				Id = "oficial_exito",
				Numero = 16,
				Actor = "Oficial",
				Expresion = "Normal",
				Texto = "Las pruebas quedan registradas. Abriremos una investigación por corrupción, sobrecostos y negligencia en la emergencia hospitalaria.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.restaurar(1.2)
				end,
				Siguiente = "FIN",
			},
			{
				Id = "resultado_fracaso",
				Numero = 15,
				Actor = "Ciudadanos",
				Expresion = "Normal",
				Texto = "Las respuestas no fueron suficientes. Confiamos en las obras que podemos ver y no en acusaciones sin pruebas completas.",
				Evento = function()
					marcarResultado("fracaso")
				end,
				Siguiente = "oficial_fracaso",
			},
			{
				Id = "oficial_fracaso",
				Numero = 16,
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
