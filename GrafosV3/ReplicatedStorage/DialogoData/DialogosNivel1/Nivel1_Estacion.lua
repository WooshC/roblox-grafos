-- ReplicatedStorage/DialogoData/DialogosNivel1/Nivel1_Estacion.lua
-- Diálogo de la Zona 1 (Estación Plana) — Nivel 1: El Barrio Antiguo
-- Introducción general a algoritmos de recorrido: DFS (Pila) vs BFS (Cola)

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EfectosDialogo = require(ReplicatedStorage:WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
local ServicioCamara = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("ServicioCamara"))

local function toggleTecho(visible)
	local nivel = Workspace:FindFirstChild("NivelActual")
	if nivel then
		local techo = nivel:FindFirstChild("Techo", true)
		if techo then techo.Transparency = visible and 0 or 1 end
	end
end

local DIALOGOS = {
	["Nivel1_Estacion"] = {
		Zona  = "Zona_Ferroviaria_1",
		Nivel = 1,

		Lineas = {
			-- 1. Bienvenida al Barrio Antiguo
			{
				Id        = "intro_estacion",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Preocupado",
				Texto     = "¡Tocino! Este es tu primer encargo real. Estamos en el Barrio Antiguo... y mira esto. A las doce de la noche, todo debería estar iluminado, pero las casas están a oscuras.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Gen_Estacion_z1", { altura = 25, angulo = 65, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Gen_Estacion_z1", "SELECCIONADO")
				end,
				Siguiente = "alcalde_radio",
			},

			-- 2. El Alcalde se defiende por radio
			{
				Id        = "alcalde_radio",
				Numero    = 2,
				Actor     = "Alcalde",
				Expresion = "Disgustado_Alcade",
				Texto     = "¿Qué ocurre en el Barrio Antiguo? Mi plan de electrificación fue impecable. Todas las casas estaban conectadas cuando firmé el proyecto. No puede haber fallos... a menos que alguien haya manipulado la red sin autorización.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Gen_Estacion_z1", { altura = 35, angulo = 70, duracion = 1.2 })
				end,
				Siguiente = "carlos_sobrecarga",
			},

			-- 3. Carlos revela la verdad: cables dañados y sobrecarga
			{
				Id        = "carlos_sobrecarga",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Con todo respeto, señor Alcalde, su 'plan impecable' tenía cables mal aislados y uniones precarias. Una sobrecarga en el Mercado Central derribó el poste principal. La energía rebotó por toda la red como una bola de pinball. Eso no es 'manipulación': es un grafo mal diseñado que colapsó bajo presión.",
				Evento = function()
					EfectosDialogo.resaltarNodo("Poste_Mercado_z2", "ERROR")
					EfectosDialogo.mostrarLabel("Poste_Mercado_z2", "Poste caído", "ERROR")
				end,
				Siguiente = "por_que_algoritmo",
			},

			-- 4. ¿Por qué necesitamos algoritmos?
			{
				Id        = "por_que_algoritmo",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "No podemos revisar casa por casa al azar. El barrio tiene decenas de postes y cables enredados. Necesitamos una estrategia sistemática que nos diga exactamente dónde se cortó la red y en qué orden reconectar cada nodo. Eso es un algoritmo de recorrido.",
				Evento = function()
					EfectosDialogo.mostrarLabel("Gen_Estacion_z1", "Generador Principal", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Casa_Estacion1_z1", "AISLADO")
					EfectosDialogo.resaltarNodo("Casa_Estacion2_z1", "AISLADO")
				end,
				Siguiente = "pila_vs_cola",
			},

			-- 5. Pila (DFS) vs Cola (BFS)
			{
				Id        = "pila_vs_cola",
				Numero    = 5,
				Actor     = "Sistema",
				Expresion = "Normal",
				Texto     = "Existen dos estrategias principales. DFS usa una PILA: se adentra lo más posible por una rama antes de retroceder. Es como explorar un callejón hasta el final antes de volver. BFS usa una COLA: explora todos los vecinos de una capa antes de pasar a la siguiente. Es como revisar todas las casas de una cuadra antes de avanzar.",
				Siguiente = "por_que_dfs",
			},

			-- 6. ¿Por qué DFS es útil aquí?
			{
				Id        = "por_que_dfs",
				Numero    = 6,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "DFS es perfecto para encontrar el camino más profundo y descubrir dónde se cortó la conexión. Si hay un cable roto al final de una calle, DFS lo encontrará antes de dispersarse. Más adelante, en el Mercado, usaremos BFS para cubrir zonas amplias capa por capa.",
				Siguiente = "btn_ejecutar",
			},

			-- 7. Botón Ejecutar Algoritmo (con puntero)
			{
				Id        = "btn_ejecutar",
				Numero    = 7,
				Actor     = "Sistema",
				Expresion = "Normal",
				Texto     = "Presiona el botón Ejecutar Algoritmo para ver cómo DFS explora la red paso a paso desde el Generador Principal. Observa cómo la pila LIFO decide qué nodo visita a continuación. dentro del panel de analisis",

				DestacarBoton = {
					nombre         = "BtnEjecutarAlg",
					escala         = 1.3,
					duracion       = 0.4,
					animacion      = "pulse",
					flecha         = true,
					punteroDesde   = "dialogo",
					punteroEstilo  = "flecha",
					textoAyuda     = "Click para ejecutar algoritmo",
					oscurecerFondo = true,
					alTerminar     = "restaurar",
				},

				Siguiente = "mostrar_carlos",
			},

			-- 8. Enfocar cámara en Carlos
			{
				Id        = "mostrar_carlos",
				Numero    = 8,
				Actor     = "Sistema",
				Expresion = "Normal",
				Texto     = "Carlos es tu instructor. Te espera cerca de la entrada. Ve a hablar con él cuando estés listo.",

				Evento = function(gui, metadata)
					toggleTecho(false)

					local nivelActual = Workspace:FindFirstChild("NivelActual")
					local objetivoCarlos = nil
					if nivelActual then
						objetivoCarlos = nivelActual:FindFirstChild("Objetivo_Carlos", true)
					end

					if objetivoCarlos then
						_G.ControladorDialogo.moverCamara(objetivoCarlos, {
							altura   = 18,
							angulo   = 55,
							duracion = 1.2,
						})
					end
				end,

				Siguiente = "alerta_emergencia",
			},

			-- 9. Alerta de emergencia en el Mercado
			{
				Id        = "alerta_emergencia",
				Numero    = 9,
				Actor     = "Sistema",
				Expresion = "Serio",
				Texto     = "ATENCIÓN: Hemos detectado una emergencia eléctrica en el Mercado Central. El Poste del Mercado está dañado por una sobrecarga. Cuando llegues, acércate al nodo dañado y haz clic repetidamente sobre él para repararlo antes de tender cables. Si no restableces la conexión a tiempo, la emergencia se propagará por todo el barrio.",
				Evento = function()
					EfectosDialogo.resaltarNodo("Poste_Mercado_z2", "ERROR")
				end,
				Siguiente = "instruccion_final",
			},

			-- 10. Instrucción final + activar guía
			{
				Id        = "instruccion_final",
				Numero    = 10,
				Actor     = "Sistema",
				Expresion = "Normal",
				Texto     = "Conecta las casas de la Estación al generador. Luego avanza al Mercado para aprender BFS. ¡Suerte!",

				Evento = function(gui, metadata)
					_G.ControladorDialogo.restaurarCamara(0.6)
					toggleTecho(true)
				end,

				Siguiente = "FIN",
			},
		},

		Metadata = {
			TiempoDeEspera      = 0.5,
			VelocidadTypewriter = 0.03,
			PuedeOmitir         = true,
			OcultarHUD          = false,
			UsarTTS             = true,
			DelayTTS            = 0.15,
		},

		Configuracion = {
			bloquearMovimiento = true,
			bloquearSalto      = true,
			bloquearCarrera    = true,
			apuntarCamara      = true,
			permitirConexiones = false,
			ocultarTechos      = true,
		},

		EventoSaltar = function()
			EfectosDialogo.limpiarTodo()
			ServicioCamara.restaurar(0)
		end,
	},
}

return DIALOGOS
