-- ReplicatedStorage/DialogoData/DialogosNivel1/Nivel1_Parque.lua
-- Diálogo de la Zona 4 (Parque del Barrio) — Nivel 1: El Barrio Antiguo
-- Concepto BFS: Grafo Conexo Completo

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
	["Nivel1_Parque"] = {
		Zona  = "Zona_Parque_4",
		Nivel = 1,
		Lineas = {
			{
				Id        = "intro_parque",
				Numero    = 1,
				Actor     = "Carlos",
				Expresion = "Sonriente",
				Texto     = "¡El Parque del Barrio! Un espacio con 4 postes de alumbrado, una Fuente Central y un Kiosco. Seis nodos en total. Es la última pieza del rompecabezas. Una vez que los conectes a la red, BFS los cubre todos en solo 2 capas.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.moverHaciaObjetivo("Fuente_z4", { altura = 42, angulo = 68, duracion = 1.8 })
					EfectosDialogo.resaltarNodo("Fuente_z4", "ADYACENTE")
					EfectosDialogo.resaltarNodo("Poste1_z4", "ERROR")
					EfectosDialogo.resaltarNodo("Poste2_z4", "ERROR")
					EfectosDialogo.resaltarNodo("Poste3_z4", "ERROR")
					EfectosDialogo.resaltarNodo("Poste4_z4", "ERROR")
					EfectosDialogo.resaltarNodo("Kiosco_z4", "ERROR")
					EfectosDialogo.mostrarLabel("Poste1_z4", "Sin luz", "ERROR")
					EfectosDialogo.mostrarLabel("Fuente_z4", "Sin luz", "ERROR")
				end,
				Siguiente = "pregunta_capas",
			},
			{
				Id        = "pregunta_capas",
				Numero    = 2,
				Actor     = "Carlos",
				Expresion = "Pensativo",
				Texto     = "Poste 1 conecta con Poste 2 y la Fuente. Fuente conecta con Poste 3 y el Kiosco. Poste 3 llega a Poste 4. Si BFS parte desde Poste 1… ¿cuántas capas necesita para visitar los 6 nodos?",
				Opciones = {
					{ Texto = "1 capa.",  Siguiente = "resp_incorrecta" },
					{ Texto = "2 capas.", Siguiente = "resp_correcta"   },
					{ Texto = "6 capas.", Siguiente = "resp_incorrecta" },
				},
			},
			{
				Id        = "resp_correcta",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Extasiado",
				Texto     = "¡Exacto! Capa 1: Poste 2 y Fuente. Capa 2: Poste 3, Kiosco y Poste 4. Dos capas son suficientes porque el grafo del Parque está bien conectado. ¡Ahora tiende los cables y enciende todo el barrio!",
				Evento = function()
					local jugador = game:GetService("Players").LocalPlayer
					if jugador then
						local puntajeActual = jugador:GetAttribute("PuntajeDialogo") or 0
						jugador:SetAttribute("PuntajeDialogo", puntajeActual + 100)
					end
					notificarRespuestaCorrecta()
				end,
				Opciones = { { Texto = "¡Vamos!", Siguiente = "instruccion" } },
			},
			{
				Id        = "resp_incorrecta",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Triste",
				Texto     = "No exactamente. BFS agrupa los nodos por distancia en saltos. Poste 2 y Fuente están a 1 salto del Poste 1; Poste 3, Kiosco y Poste 4 están a 2 saltos. Dos capas cubren los 6 nodos porque el grafo es compacto.",
				Opciones = { { Texto = "Entendido", Siguiente = "instruccion" } },
			},
			{
				Id        = "instruccion",
				Numero    = 4,
				Actor     = "Sistema",
				Texto     = "Conecta el Poste 1 al Poste de las Canchas para unir el subgrafo aislado. Luego enlaza la Fuente y los demás postes para iluminar el Parque al 100%. Cuando todo el barrio brille, habrás formado un Grafo Conexo completo. ¡Victoria!",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					ServicioCamara.restaurar(1.5)
				end,
				Siguiente = "FIN",
			},
		},
		Metadata = { TiempoDeEspera = 0.5, VelocidadTypewriter = 0.03, PuedeOmitir = true, OcultarHUD = true, UsarTTS = true },
		Configuracion = { bloquearMovimiento = true, bloquearSalto = true, apuntarCamara = true, ocultarTechos = true },
	},
}
return DIALOGOS
