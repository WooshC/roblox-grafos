-- Zona 2 (Complejo Hospitalario) — Nivel 3.
-- La rueda de prensa del Alcalde coincide con una emergencia eléctrica.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LevelsConfig      = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("LevelsConfig"))
local EfectosDialogo    = require(ReplicatedStorage:WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
local ServicioCamara    = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("ServicioCamara"))
local Utilidades        = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("Utilidades"))

local nombres = LevelsConfig[3].NombresNodos
local alcaldia    = nombres["Poste_Alcaldia_z2"]
local apoyo       = nombres["Poste_secundario_z2"]
local subestacion = nombres["Poste_principal_z2"]

local function respuestaCorrecta()
	Utilidades.notificarDialogoCorrecto()
end

local DIALOGOS = {
	["Nivel3_Rutas"] = {
		Zona = "Zona_Hospital_2",
		Nivel = 3,
		Lineas = {
			{
				Id = "rueda_prensa",
				Numero = 1,
				Actor = "Carlos",
				Expresion = "Serio",
				Texto = "La rueda de prensa está por comenzar junto al complejo hospitalario, pero tres puntos críticos quedaron dañados. La red se saturó exactamente donde el Alcalde aseguraba haber financiado una instalación moderna y segura.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Poste_principal_z2", { altura = 32, angulo = 60, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("Poste_principal_z2", "ERROR")
					EfectosDialogo.resaltarNodo("Poste_Alcaldia_z2", "ERROR")
					EfectosDialogo.resaltarNodo("Poste_secundario_z2", "ERROR")
				end,
				Siguiente = "hijo_hospital",
			},
			{
				Id = "hijo_hospital",
				Numero = 2,
				Actor = "Carlos",
				Expresion = "Triste",
				Texto = "Espera... ese mensaje es de mi esposa. Mi hijo está aquí, en una de las salas que dependen de esta subestación. Creí que veníamos a auditar un contrato; ahora escucho las alarmas y solo puedo pensar que cada segundo sin energía puede arrancármelo. Tocino, esta red tiene que sostenerse.",
				Evento = function()
					ServicioCamara.moverHaciaObjetivo("PosteHospital_z2", { altura = 24, angulo = 62, duracion = 1.2 })
					EfectosDialogo.resaltarNodo("PosteHospital_z2", "ERROR")
					EfectosDialogo.mostrarLabel("PosteHospital_z2", "HIJO DE CARLOS · EN RIESGO", "ERROR")
				end,
				Siguiente = "diagnostico",
			},
			{
				Id = "diagnostico",
				Numero = 3,
				Actor = "Sistema",
				Expresion = "Procesando",
				Texto = "Diagnóstico: " .. alcaldia .. ", " .. apoyo .. " y " .. subestacion .. " están dañados. Además, dos cables defectuosos interrumpen el flujo de energía.",
				Evento = function()
					EfectosDialogo.mostrarLabel("Poste_Alcaldia_z2", "NODO DAÑADO", "ERROR")
					EfectosDialogo.mostrarLabel("Poste_secundario_z2", "NODO DAÑADO", "ERROR")
					EfectosDialogo.mostrarLabel("Poste_principal_z2", "NODO DAÑADO", "ERROR")
					EfectosDialogo.mostrarArista("Poste_Alcaldia_z2", "Poste_secundario_z2", "ERROR", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Poste_principal_z2", "Poste_secundario_z2", "ERROR", { sinParticulas = true })
				end,
				Siguiente = "causa",
			},
			{
				Id = "causa",
				Numero = 4,
				Actor = "Carlos",
				Expresion = "Serio",
				Texto = "Los planos revelan demasiadas conexiones redundantes. El Alcalde infló el costo de la obra agregando cables y concentró grados innecesarios en pocos nodos. La sobrecarga resultante dañó áreas críticas del hospital.",
				Siguiente = "pregunta",
			},
			{
				Id = "pregunta",
				Numero = 5,
				Actor = "Carlos",
				Expresion = "Serio",
				Texto = "¿Qué debemos hacer para recuperar el hospital sin repetir el error?",
				Opciones = {
					{ Texto = "Reparar los nodos y cables, y usar Prim para conservar solo conexiones necesarias y económicas.", Siguiente = "respuesta_bien" },
					{ Texto = "Añadir todavía más cables a todos los nodos.", Siguiente = "respuesta_mal" },
					{ Texto = "Ignorar los pesos mientras exista alguna conexión.", Siguiente = "respuesta_mal" },
				},
			},
			{
				Id = "respuesta_bien",
				Numero = 6,
				Actor = "Carlos",
				Expresion = "Feliz",
				Texto = "Correcto. Repararemos primero y después construiremos un árbol de 7 nodos, 6 cables y peso máximo 22.",
				Evento = respuestaCorrecta,
				Opciones = {{ Texto = "Iniciar emergencia", Siguiente = "mision" }},
			},
			{
				Id = "respuesta_mal",
				Numero = 6,
				Actor = "Carlos",
				Expresion = "Serio",
				Texto = "Eso repetiría la corrupción del contrato. Debemos reparar la infraestructura y conectar solo lo necesario según Prim.",
				Opciones = {{ Texto = "Iniciar emergencia", Siguiente = "mision" }},
			},
			{
				Id = "mision",
				Numero = 7,
				Actor = "Sistema",
				Expresion = "Normal",
				Texto = "EMERGENCIA: repara el Poste de la Alcaldía, el Poste Secundario y la Subestación Médica. Después construye el MST hospitalario con peso 22 o menor. La red global completa debe tener 15 nodos, 14 cables y peso máximo 46.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
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
