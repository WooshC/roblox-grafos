-- Zona 1 (Sector Residencial) — Nivel 3.
-- Introduce Prim y las primeras evidencias de sobrecostos del Alcalde.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LevelsConfig      = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("LevelsConfig"))
local EfectosDialogo    = require(ReplicatedStorage:WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
local ServicioCamara    = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("ServicioCamara"))
local Utilidades        = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("Utilidades"))

local nombres = LevelsConfig[3].NombresNodos
local presupuesto = LevelsConfig[3].Presupuesto.Inicial
local costoPorMetro = LevelsConfig[3].CostoPorMetro

local subestacion = nombres["Gen_Estacion_z1"]
local parque      = nombres["Parque_z1"]
local casaPinos   = nombres["Casa_Estacion1_z1"]

local function respuestaCorrecta()
	Utilidades.notificarDialogoCorrecto()
end

local DIALOGOS = {
	["Nivel3_Presupuesto"] = {
		Zona = "Zona_Residencial_1",
		Nivel = 3,
		Lineas = {
			{
				Id = "contratos",
				Numero = 1,
				Actor = "Carlos",
				Expresion = "Preocupado",
				Texto = "Esta noche, mientras revisaba los contratos del Alcalde, encontré algo raro. Presupuestó cables entre casi todas las viviendas, incluso donde no hacían falta. Cada conexión extra aumenta el costo y también el grado de los nodos hasta saturar la red.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Gen_Estacion_z1", { altura = 28, angulo = 62, duracion = 1.4 })
					EfectosDialogo.resaltarNodo("Gen_Estacion_z1", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("Casa_Estacion1_z1", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Parque_z1", "ADYACENTE")
				end,
				Siguiente = "problema_grados",
			},
			{
				Id = "problema_grados",
				Numero = 2,
				Actor = "Carlos",
				Expresion = "Serio",
				Texto = "El problema no es solo económico. Agregar aristas innecesarias eleva el grado de postes y subestaciones. Cuando demasiados cables concentran la carga en un nodo, el sistema se sobrecalienta y puede dejar sectores enteros sin energía.",
				Siguiente = "solucion_prim",
			},
			{
				Id = "solucion_prim",
				Numero = 3,
				Actor = "Sistema",
				Expresion = "Normal",
				Texto = "Prim permite auditar la propuesta: conecta todos los nodos con un Árbol de Expansión Mínima, sin ciclos y con el menor peso total. Para el sector residencial, la solución óptima pesa 20.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Gen_Estacion_z1", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("Gen_Estacion_z1", subestacion .. " · raíz")
					EfectosDialogo.mostrarArista("Gen_Estacion_z1", "Poste_Parque2_z1", "ADYACENTE", { sinParticulas = true })
				end,
				Siguiente = "pregunta_mst",
			},
			{
				Id = "pregunta_mst",
				Numero = 4,
				Actor = "Carlos",
				Expresion = "Curioso",
				Texto = "¿Por qué una red con más cables no siempre es mejor?",
				Opciones = {
					{ Texto = "Porque puede crear ciclos, elevar costos y saturar nodos sin mejorar la conectividad.", Siguiente = "respuesta_bien" },
					{ Texto = "Porque Prim solo funciona cuando no existen cables.", Siguiente = "respuesta_mal" },
					{ Texto = "Porque todas las aristas deben tener el mismo peso.", Siguiente = "respuesta_mal" },
				},
			},
			{
				Id = "respuesta_bien",
				Numero = 5,
				Actor = "Carlos",
				Expresion = "Feliz",
				Texto = "Exacto. Un MST usa solo las aristas necesarias. Eso reduce el costo y evita grados artificialmente altos.",
				Evento = respuestaCorrecta,
				Opciones = {{ Texto = "Continuar", Siguiente = "rueda_prensa" }},
			},
			{
				Id = "respuesta_mal",
				Numero = 5,
				Actor = "Carlos",
				Expresion = "Serio",
				Texto = "La clave es evitar conexiones redundantes. Los ciclos y grados innecesarios cuestan más y pueden sobrecargar la infraestructura.",
				Opciones = {{ Texto = "Entendido", Siguiente = "rueda_prensa" }},
			},
			{
				Id = "rueda_prensa",
				Numero = 6,
				Actor = "Carlos",
				Expresion = "Preocupado",
				Texto = "El presupuesto disponible es de $" .. presupuesto .. " y cada unidad de peso cuesta $" .. costoPorMetro .. ". El árbol residencial óptimo cuesta $10 000 y la red global, antes de reparaciones, $23 000. Cada ciclo innecesario puede dejarnos sin margen.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("Casa_Estacion1_z1", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("Casa_Estacion1_z1", casaPinos .. " · enlace al hospital")
					EfectosDialogo.mostrarLabel("Parque_z1", parque)
					ServicioCamara.restaurar(1.2)
				end,
				Siguiente = "FIN",
			},
		},
		Metadata = { TiempoDeEspera = 0.5, VelocidadTypewriter = 0.03, PuedeOmitir = true, OcultarHUD = true, UsarTTS = true },
		Configuracion = { bloquearMovimiento = true, bloquearSalto = true, apuntarCamara = true, ocultarTechos = true },
	},
}

return DIALOGOS
