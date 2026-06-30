-- Zona 2 (Complejo Hospitalario) — Nivel 3.
-- La rueda de prensa del Alcalde coincide con una emergencia eléctrica.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LevelsConfig      = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("LevelsConfig"))
local EfectosDialogo    = require(ReplicatedStorage:WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
local ServicioCamara    = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("ServicioCamara"))
local Utilidades        = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("Utilidades"))

local nombres = LevelsConfig[3].NombresNodos
local urgencias   = nombres["NodoHos2_z2"]
local laboratorio = nombres["NodoHos4_z2"]
local consulta    = nombres["Poste4_z2"]

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
				Expresion = "Preocupado",
				Texto = "Esta noche, la rueda de prensa del Alcalde está a punto de comenzar junto al hospital, pero ocurrió una emergencia. Entre sirenas y luces apagadas, la red se saturó exactamente donde él aseguraba haber financiado una instalación moderna y segura.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("NodoHos_z2", { altura = 32, angulo = 60, duracion = 1.5 })
					EfectosDialogo.resaltarNodo("NodoHos_z2", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("NodoHos2_z2", "ERROR")
					EfectosDialogo.resaltarNodo("NodoHos4_z2", "ERROR")
					EfectosDialogo.resaltarNodo("Poste4_z2", "ERROR")
				end,
				Siguiente = "diagnostico",
			},
			{
				Id = "diagnostico",
				Numero = 2,
				Actor = "Sistema",
				Expresion = "Procesando",
				Texto = "Diagnóstico: " .. urgencias .. ", " .. laboratorio .. " y " .. consulta .. " están dañados. Además, dos cables defectuosos interrumpen el flujo de energía.",
				Evento = function()
					EfectosDialogo.mostrarLabel("NodoHos2_z2", "NODO DAÑADO", "ERROR")
					EfectosDialogo.mostrarLabel("NodoHos4_z2", "NODO DAÑADO", "ERROR")
					EfectosDialogo.mostrarLabel("Poste4_z2", "NODO DAÑADO", "ERROR")
					EfectosDialogo.mostrarArista("NodoHos_z2", "NodoHos2_z2", "ERROR", { sinParticulas = true })
					EfectosDialogo.mostrarArista("Poste2_z2", "NodoHos4_z2", "ERROR", { sinParticulas = true })
				end,
				Siguiente = "causa",
			},
			{
				Id = "causa",
				Numero = 3,
				Actor = "Carlos",
				Expresion = "Serio",
				Texto = "Los planos revelan demasiadas conexiones redundantes. El Alcalde infló el costo de la obra agregando cables y concentró grados innecesarios en pocos nodos. La sobrecarga resultante dañó áreas críticas del hospital.",
				Siguiente = "pregunta",
			},
			{
				Id = "pregunta",
				Numero = 4,
				Actor = "Carlos",
				Expresion = "Curioso",
				Texto = "¿Qué debemos hacer para recuperar el hospital sin repetir el error?",
				Opciones = {
					{ Texto = "Reparar los nodos y cables, y usar Prim para conservar solo conexiones necesarias y económicas.", Siguiente = "respuesta_bien" },
					{ Texto = "Añadir todavía más cables a todos los nodos.", Siguiente = "respuesta_mal" },
					{ Texto = "Ignorar los pesos mientras exista alguna conexión.", Siguiente = "respuesta_mal" },
				},
			},
			{
				Id = "respuesta_bien",
				Numero = 5,
				Actor = "Carlos",
				Expresion = "Feliz",
				Texto = "Correcto. Repararemos primero y después validaremos una red mínima, conectada y sin desperdicio.",
				Evento = respuestaCorrecta,
				Opciones = {{ Texto = "Iniciar emergencia", Siguiente = "mision" }},
			},
			{
				Id = "respuesta_mal",
				Numero = 5,
				Actor = "Carlos",
				Expresion = "Serio",
				Texto = "Eso repetiría la corrupción del contrato. Debemos reparar la infraestructura y conectar solo lo necesario según Prim.",
				Opciones = {{ Texto = "Iniciar emergencia", Siguiente = "mision" }},
			},
			{
				Id = "mision",
				Numero = 6,
				Actor = "Sistema",
				Expresion = "Normal",
				Texto = "EMERGENCIA: repara los tres nodos dañados. Después retira y reemplaza los dos cables defectuosos para devolver energía a Urgencias, Laboratorio y Consulta Externa. Cuando termines, busca al Alcalde en la rueda de prensa y confronta sus cifras.",
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
