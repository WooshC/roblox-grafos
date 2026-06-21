-- ReplicatedStorage/DialogoData/Zona4_Conectividad.lua
-- Diálogo educativo de la Zona 4: Grafos Conexos — Red Eléctrica del Metro de Quito

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LevelsConfig   = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("LevelsConfig"))
local EfectosDialogo = require(ReplicatedStorage:WaitForChild("Efectos"):WaitForChild("EfectosDialogo"))
local ServicioCamara = require(ReplicatedStorage:WaitForChild("Compartido"):WaitForChild("ServicioCamara"))

-- ════════════════════════════════════════════════════════════════════
-- ALIASES  (nombres desde LevelsConfig[0].NombresNodos)
-- ════════════════════════════════════════════════════════════════════

local nodos  = LevelsConfig[0].NombresNodos
local aliasE = nodos["NodoE_z4"] or "Empresa Eléctrica"
local aliasA = nodos["NodoA_z4"] or "Estacion El Ejido"
local aliasB = nodos["NodoB_z4"] or "Estacion La Pradera"
local aliasC = nodos["NodoC_z4"] or "Estacion La Carolina"
local aliasF = nodos["NodoF_z4"] or "Estacion Iñaquito"
local aliasD = nodos["NodoD_z4"] or "Estacion El Labrador"

-- ════════════════════════════════════════════════════════════════════
-- HELPERS DE CÁMARA
-- ════════════════════════════════════════════════════════════════════

local function enfocarNodo(nombreNodo, opciones)
	ServicioCamara.moverHaciaObjetivo(nombreNodo, opciones)
end

-- Calcula el punto medio entre dos nodos y enfoca ahí
local function enfocarPar(nomA, nomB, opciones)
	local nivel = workspace:FindFirstChild("NivelActual")
	if not nivel then return end

	local function getPos(nombre)
		local obj = nivel:FindFirstChild(nombre, true)
		if not obj then return nil end
		if obj:IsA("Model") then
			local s = obj:FindFirstChild("Selector")
			if s then
				if s:IsA("BasePart") then return s.Position end
				local bp = s:FindFirstChildOfClass("BasePart")
				if bp then return bp.Position end
			end
			return obj:GetPivot().Position
		elseif obj:IsA("BasePart") then
			return obj.Position
		end
		return nil
	end

	local pA = getPos(nomA)
	local pB = getPos(nomB)
	if not (pA and pB) then return end

	ServicioCamara.moverHaciaObjetivo(pA:Lerp(pB, 0.5), {
		altura   = opciones and opciones.altura   or 42,
		angulo   = opciones and opciones.angulo   or 64,
		duracion = opciones and opciones.duracion or 0.8,
	})
end

-- Calcula el centroide de toda la red (6 nodos)
local function enfocarRed(opciones)
	local nivel = workspace:FindFirstChild("NivelActual")
	if not nivel then return end

	local function getPos(nombre)
		local obj = nivel:FindFirstChild(nombre, true)
		if not obj then return nil end
		if obj:IsA("Model") then
			local s = obj:FindFirstChild("Selector")
			if s then
				if s:IsA("BasePart") then return s.Position end
				local bp = s:FindFirstChildOfClass("BasePart")
				if bp then return bp.Position end
			end
			return obj:GetPivot().Position
		elseif obj:IsA("BasePart") then
			return obj.Position
		end
		return nil
	end

	local nombres = { "NodoE_z4", "NodoA_z4", "NodoB_z4", "NodoC_z4", "NodoF_z4", "NodoD_z4" }
	local suma    = Vector3.new(0, 0, 0)
	local count   = 0
	for _, nom in ipairs(nombres) do
		local p = getPos(nom)
		if p then
			suma  = suma + p
			count = count + 1
		end
	end

	if count == 0 then
		enfocarNodo("NodoA_z4", opciones)
		return
	end

	ServicioCamara.moverHaciaObjetivo(suma / count, {
		altura   = opciones and opciones.altura   or 80,
		angulo   = opciones and opciones.angulo   or 60,
		duracion = opciones and opciones.duracion or 1.0,
	})
end

-- ════════════════════════════════════════════════════════════════════
-- DATOS DEL DIÁLOGO
-- ════════════════════════════════════════════════════════════════════

local DIALOGOS = {

	["Zona4_Conectividad"] = {
		Zona  = "Zona_Estacion_4",
		Nivel = 0,

		-- Limpia efectos visuales al cerrar o al pulsar Saltar
		EventoSalida = function() EfectosDialogo.limpiarTodo() end,

		Lineas = {

			-- ── 1. LLAMADA DEL ALCALDE SOBRE EL BARRIO ANTIGUO ─
			{
				Id        = "llamada_inicio",
				Numero    = 1,
				Actor     = "Sistema",
				Expresion = "Normal",
				Texto     = "El teléfono de Carlos suena. Es el Alcalde...",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					local StarterPlayerScripts = game:GetService("StarterPlayer").StarterPlayerScripts
					local moduloAudio = StarterPlayerScripts:FindFirstChild("Compartido", true)
					if moduloAudio then
						moduloAudio = moduloAudio:FindFirstChild("ControladorAudio")
					end
					if moduloAudio then
						local exito, ControladorAudio = pcall(function()
							return require(moduloAudio)
						end)
						if exito and ControladorAudio and ControladorAudio.playSFX then
							ControladorAudio.playSFX("TelefonoSonando")
						end
					end
				end,
				Siguiente = "alcalde_llamada_1",
			},
			{
				Id        = "alcalde_llamada_1",
				Numero    = 2,
				Actor     = "Alcalde",
				Expresion = "Furioso",
				Texto     = "¡Carlos! El Barrio Antiguo está a oscuras. Mandé a cablear todo, pero los opositores sabotearon mis conexiones y un transformador explotó.",
				Siguiente = "carlos_respuesta_1",
			},
			{
				Id        = "carlos_respuesta_1",
				Numero    = 3,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Señor Alcalde, si el barrio está a oscuras es porque el grafo eléctrico no es conexo. La corriente no llega a todos los nodos. Iremos, pero primero termino esta simulación con mi aprendiz.",
				Siguiente = "concepto_conexo",
			},

			-- ── 2. CONCEPTO: COMPONENTES CONEXAS Y GRAFO CONEXO ─
			{
				Id        = "concepto_conexo",
				Numero    = 4,
				Actor     = "Carlos",
				Expresion = "Feliz",
				Texto     = "Mira esta red. Cuando todos los nodos están unidos por al menos un camino, el grafo es CONEXO y la energía llega a todas las estaciones.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					for _, nom in ipairs({"NodoE_z4","NodoA_z4","NodoB_z4","NodoC_z4","NodoF_z4","NodoD_z4"}) do
						EfectosDialogo.resaltarNodo(nom, "CONECTADO")
						EfectosDialogo.mostrarLabel(nom, nodos[nom] or nom)
					end
					task.delay(0.2, function()
						EfectosDialogo.mostrarArista("NodoE_z4", "NodoA_z4", "CONECTADO", { dirigido = false })
						EfectosDialogo.mostrarArista("NodoA_z4", "NodoB_z4", "CONECTADO", { dirigido = false })
						EfectosDialogo.mostrarArista("NodoB_z4", "NodoC_z4", "CONECTADO", { dirigido = false })
						EfectosDialogo.mostrarArista("NodoC_z4", "NodoF_z4", "CONECTADO", { dirigido = false })
						EfectosDialogo.mostrarArista("NodoF_z4", "NodoD_z4", "CONECTADO", { dirigido = false })
					end)
					enfocarRed({ altura = 80, angulo = 60, duracion = 0.9 })
				end,
				Siguiente = "concepto_desconexo",
			},
			{
				Id        = "concepto_desconexo",
				Numero    = 5,
				Actor     = "Carlos",
				Expresion = "Serio",
				Texto     = "Si falta algún cable, el grafo queda DESCONECTADO y se forman COMPONENTES CONEXAS aisladas. La energía no puede saltar de una componente a otra.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					EfectosDialogo.resaltarNodo("NodoE_z4", "SELECCIONADO")
					EfectosDialogo.resaltarNodo("NodoA_z4", "SELECCIONADO")
					EfectosDialogo.mostrarLabel("NodoE_z4", aliasE .. "  (comp. 1)")
					EfectosDialogo.mostrarLabel("NodoA_z4", aliasA .. "  (comp. 1)")
					EfectosDialogo.resaltarNodo("NodoF_z4", "ADYACENTE")
					EfectosDialogo.resaltarNodo("NodoD_z4", "ADYACENTE")
					EfectosDialogo.mostrarLabel("NodoF_z4", aliasF .. "  (comp. 2)")
					EfectosDialogo.mostrarLabel("NodoD_z4", aliasD .. "  (comp. 2)")
					EfectosDialogo.resaltarNodo("NodoB_z4", "AISLADO")
					EfectosDialogo.resaltarNodo("NodoC_z4", "AISLADO")
					EfectosDialogo.mostrarLabel("NodoB_z4", aliasB, "AISLADO")
					EfectosDialogo.mostrarLabel("NodoC_z4", aliasC, "AISLADO")
					task.delay(0.2, function()
						EfectosDialogo.mostrarArista("NodoE_z4", "NodoA_z4", "SELECCIONADO", { dirigido = false })
						EfectosDialogo.mostrarArista("NodoF_z4", "NodoD_z4", "ADYACENTE", { dirigido = false })
					end)
					enfocarRed({ altura = 80, angulo = 60, duracion = 0.9 })
				end,
				Siguiente = "sigue_misiones",
			},

			-- ── 3. INDICACIÓN DE MISIONES ─
			{
				Id        = "sigue_misiones",
				Numero    = 6,
				Actor     = "Sistema",
				Expresion = "Normal",
				Texto     = "Sigue las misiones del panel de misiones. Tu objetivo es conectar toda la red y hacer que el grafo sea completamente conexo.",
				Evento = function()
					EfectosDialogo.limpiarTodo()
					for _, nom in ipairs({"NodoE_z4","NodoA_z4","NodoB_z4","NodoC_z4","NodoF_z4","NodoD_z4"}) do
						EfectosDialogo.resaltarNodo(nom, "AISLADO")
						EfectosDialogo.mostrarLabel(nom, nodos[nom] or nom, "AISLADO")
					end
					enfocarRed({ altura = 80, angulo = 60, duracion = 0.9 })
				end,
				Siguiente = "advertencia_sobrecarga",
			},

			-- ── 4. ADVERTENCIA DE SOBRECARGA ─
			{
				Id        = "advertencia_sobrecarga",
				Numero    = 7,
				Actor     = "Sistema",
				Expresion = "Normal",
				Texto     = "Advertencia: el transformador de " .. aliasC .. " es viejo. Si le conectas más de dos cables, se sobrecargará, explotará y quedará dañado. Repararlo costará dinero. Planifica bien tus conexiones.",
				Siguiente = "FIN",
			},
		},

		Metadata = {
			TiempoDeEspera      = 0.2,
			VelocidadTypewriter = 0.02,
			PuedeOmitir         = true,
			OcultarHUD          = true,
			UsarTTS             = true,
		},

		Configuracion = {
			bloquearMovimiento = true,
			bloquearSalto      = true,
			bloquearCarrera    = true,
			apuntarCamara      = true,
			permitirConexiones = true,   -- necesario para las líneas interactivas 14 y 15
			ocultarTechos      = true,
			cerrarMapa         = true,
		},
	},
}

return DIALOGOS
