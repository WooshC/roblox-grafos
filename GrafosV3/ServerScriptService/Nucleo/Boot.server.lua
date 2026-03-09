-- GrafosV3 - Boot.server.lua
-- Punto de entrada UNICO del servidor.
-- Responsabilidad: Iniciar el sistema y gestionar el ciclo de vida del jugador.
--
-- REGLA DE ORO: Mientras el menu esta activo, TODO lo relacionado al gameplay
-- esta completamente desconectado.
--
-- Estados por jugador: MENU → CARGANDO → GAMEPLAY → MENU

local Servidores = game:GetService("ServerScriptService")
local Jugadores  = game:GetService("Players")
local Replicado  = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- Sin spawn automatico (el menu no necesita personaje)
Jugadores.CharacterAutoLoads = false

print("[GrafosV3] === Boot Servidor Iniciando ===")

-- ═══════════════════════════════════════════════════════════════════════════════
-- 1. ESPERAR EVENTOS (creados por EventRegistry.server.lua)
-- ═══════════════════════════════════════════════════════════════════════════════
local Eventos = Replicado:WaitForChild("EventosGrafosV3", 15)
if not Eventos then
	error("[GrafosV3] CRITICO: EventosGrafosV3 no encontrado. Asegurate de que EventRegistry.server.lua este en ServerScriptService/Nucleo/")
end

local Remotos = Eventos:WaitForChild("Remotos", 10)
if not Remotos then
	error("[GrafosV3] CRITICO: EventosGrafosV3/Remotos no encontrado")
end

-- Helper: buscar evento con timeout
local function esperarEvento(nombre, timeout)
	timeout = timeout or 5
	local evento = Remotos:FindFirstChild(nombre)
	if evento then return evento end

	local startTime = tick()
	while not evento and (tick() - startTime) < timeout do
		task.wait(0.1)
		evento = Remotos:FindFirstChild(nombre)
	end

	if not evento then
		warn("[Boot.server] Evento no encontrado después de " .. timeout .. "s: " .. nombre)
	end
	return evento
end

print("[GrafosV3] Eventos conectados correctamente")

-- ═══════════════════════════════════════════════════════════════════════════════
-- 2. MÁQUINA DE ESTADOS POR JUGADOR (Regla de Oro)
-- ═══════════════════════════════════════════════════════════════════════════════
-- Cada jugador tiene su propio estado. Los handlers de gameplay solo actúan
-- cuando el jugador está en estado GAMEPLAY.

local ESTADO = { MENU = "MENU", CARGANDO = "CARGANDO", GAMEPLAY = "GAMEPLAY" }

local _estado = {}  -- [userId] = ESTADO.*
local _ctx    = {}  -- [userId] = { cables = Module, misiones = Module }

local function setEstado(jugador, nuevoEstado)
	_estado[jugador.UserId] = nuevoEstado
end

local function estaEnGameplay(jugador)
	return _estado[jugador.UserId] == ESTADO.GAMEPLAY
end

-- Cachear módulos de gameplay ya cargados (Lua devuelve desde caché, costo ~0)
local function construirContexto(jugador)
	local sistemasCarpeta = Servidores:FindFirstChild("SistemasGameplay")
	if not sistemasCarpeta then return {} end

	local ctx = {}

	local mCables = sistemasCarpeta:FindFirstChild("ConectarCables")
	if mCables then
		local ok, ref = pcall(require, mCables)
		if ok then ctx.cables = ref end
	end

	local mMisiones = sistemasCarpeta:FindFirstChild("ServicioMisiones")
	if mMisiones then
		local ok, ref = pcall(require, mMisiones)
		if ok then ctx.misiones = ref end
	end

	return ctx
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 3. CARGAR SERVICIOS CORE
-- ═══════════════════════════════════════════════════════════════════════════════
local ServicioProgreso = nil
local CargadorNiveles  = nil

local function cargarServicios()
	local carpetaServicios = script.Parent.Parent:WaitForChild("Servicios")

	local moduloProgreso = carpetaServicios:FindFirstChild("ServicioProgreso")
	if moduloProgreso then
		local ok, resultado = pcall(require, moduloProgreso)
		if ok then
			ServicioProgreso = resultado
			print("[GrafosV3] ServicioProgreso cargado")
		else
			warn("[GrafosV3] Error en ServicioProgreso:", resultado)
		end
	end

	local moduloCargador = carpetaServicios:FindFirstChild("CargadorNiveles")
	if moduloCargador then
		local ok, resultado = pcall(require, moduloCargador)
		if ok then
			CargadorNiveles = resultado
			print("[GrafosV3] CargadorNiveles cargado")
		else
			warn("[GrafosV3] Error en CargadorNiveles:", resultado)
		end
	end
end

cargarServicios()

-- ═══════════════════════════════════════════════════════════════════════════════
-- 4. FUNCIONES DE GUI
-- ═══════════════════════════════════════════════════════════════════════════════
local function copiarGuiAJugador(jugador)
	local playerGui = jugador:FindFirstChild("PlayerGui")
	if not playerGui then
		playerGui = Instance.new("PlayerGui")
		playerGui.Name = "PlayerGui"
		playerGui.Parent = jugador
	end

	local copiadas = 0
	for _, gui in ipairs(StarterGui:GetChildren()) do
		if gui:IsA("ScreenGui") and not playerGui:FindFirstChild(gui.Name) then
			gui:Clone().Parent = playerGui
			copiadas = copiadas + 1
		end
	end

	if copiadas == 0 then
		warn("[GrafosV3] No se copio ninguna GUI. Verifica StarterGui.")
	end
	return copiadas > 0
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 5. JUGADOR CONECTADO
-- ═══════════════════════════════════════════════════════════════════════════════
local function alJugadorConectado(jugador)
	print("[GrafosV3] Jugador conectado:", jugador.Name)

	-- Estado inicial: MENU
	setEstado(jugador, ESTADO.MENU)

	-- Copiar GUI (menu state)
	task.spawn(function()
		copiarGuiAJugador(jugador)
	end)

	-- Cargar datos del jugador
	task.spawn(function()
		if ServicioProgreso and ServicioProgreso.cargar then
			ServicioProgreso.cargar(jugador)
		end
	end)

	-- Notificar al cliente (menu listo)
	task.delay(2, function()
		if jugador and jugador.Parent then
			local servidorListo = Remotos:FindFirstChild("ServidorListo")
			if servidorListo then
				servidorListo:FireClient(jugador)
				print("[GrafosV3] ServidorListo enviado a", jugador.Name)
			end
		end
	end)
end

Jugadores.PlayerAdded:Connect(alJugadorConectado)

-- Para jugadores ya conectados (Play Solo)
for _, jugador in ipairs(Jugadores:GetPlayers()) do
	copiarGuiAJugador(jugador)
	alJugadorConectado(jugador)
end

-- Limpiar al desconectar
Jugadores.PlayerRemoving:Connect(function(jugador)
	_estado[jugador.UserId] = nil
	_ctx[jugador.UserId]    = nil
	if ServicioProgreso and ServicioProgreso.alJugadorSalir then
		ServicioProgreso.alJugadorSalir(jugador)
	end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 6. HANDLERS MENÚ (siempre activos)
-- ═══════════════════════════════════════════════════════════════════════════════

-- ObtenerProgresoJugador: el menu solicita datos del jugador
local obtenerProgreso = Remotos:WaitForChild("ObtenerProgresoJugador")
obtenerProgreso.OnServerInvoke = function(jugador)
	if ServicioProgreso and ServicioProgreso.obtenerProgresoParaCliente then
		return ServicioProgreso.obtenerProgresoParaCliente(jugador)
	end

	-- Fallback desde LevelsConfig
	local LevelsConfig = require(Replicado:WaitForChild("Config"):WaitForChild("LevelsConfig"))
	local resultado = {}
	for i = 0, 4 do
		local config = LevelsConfig[i] or {}
		resultado[tostring(i)] = {
			nivelID     = i,
			nombre      = config.Nombre or ("Nivel " .. i),
			descripcion = config.DescripcionCorta or "",
			imageId     = config.ImageId or "",
			tag         = config.Tag or ("NIVEL " .. i),
			algoritmo   = config.Algoritmo,
			seccion     = config.Seccion or "NIVELES",
			conceptos   = config.Conceptos or {},
			status      = (i == 0) and "disponible" or "bloqueado",
			estrellas   = 0, highScore = 0, aciertos = 0,
			fallos      = 0, tiempoMejor = 0, intentos = 0,
		}
	end
	return resultado
end

-- IniciarNivel: jugador quiere jugar un nivel
local iniciarNivel = Remotos:WaitForChild("IniciarNivel")
iniciarNivel.OnServerEvent:Connect(function(jugador, idNivel)
	print("[GrafosV3] IniciarNivel - Jugador:", jugador.Name, "Nivel:", idNivel)

	setEstado(jugador, ESTADO.CARGANDO)
	_ctx[jugador.UserId] = nil

	if CargadorNiveles then
		local ok, err = pcall(CargadorNiveles.cargar, idNivel, jugador)
		if ok then
			-- Cachear referencias a módulos ya cargados (Regla de Oro: contexto listo)
			_ctx[jugador.UserId] = construirContexto(jugador)
			setEstado(jugador, ESTADO.GAMEPLAY)
		else
			warn("[GrafosV3] Error al cargar nivel:", err)
			setEstado(jugador, ESTADO.MENU)
			-- Notificar error al cliente para desbloquear pantalla
			local nivelListo = Remotos:FindFirstChild("NivelListo")
			if nivelListo then
				nivelListo:FireClient(jugador, { nivelID = idNivel, error = tostring(err) })
			end
		end
	else
		warn("[GrafosV3] CargadorNiveles no disponible")
		setEstado(jugador, ESTADO.MENU)
		local nivelListo = Remotos:FindFirstChild("NivelListo")
		if nivelListo then
			nivelListo:FireClient(jugador, { nivelID = idNivel, error = "Servidor no listo" })
		end
	end
end)

-- VolverAlMenu: jugador quiere salir del nivel
local volverAlMenu = Remotos:WaitForChild("VolverAlMenu")
volverAlMenu.OnServerEvent:Connect(function(jugador)
	print("[GrafosV3] VolverAlMenu - Jugador:", jugador.Name)

	-- PRIMERO: cambiar estado (Regla de Oro — gameplay handlers desconectados)
	setEstado(jugador, ESTADO.MENU)
	_ctx[jugador.UserId] = nil

	if CargadorNiveles then
		CargadorNiveles.descargar()
	end

	if jugador.Character then
		jugador.Character:Destroy()
	end

	local nivelDescargado = Remotos:FindFirstChild("NivelDescargado")
	if nivelDescargado then
		nivelDescargado:FireClient(jugador)
	end
end)

-- ReiniciarNivel: jugador quiere reiniciar el nivel actual
local reiniciarNivel = Remotos:WaitForChild("ReiniciarNivel")
reiniciarNivel.OnServerEvent:Connect(function(jugador, nivelID)
	print("[GrafosV3] ReiniciarNivel - Jugador:", jugador.Name, "Nivel:", nivelID)

	setEstado(jugador, ESTADO.CARGANDO)
	_ctx[jugador.UserId] = nil

	if CargadorNiveles then
		CargadorNiveles.descargar()
		task.wait(0.5)
		local ok, err = pcall(CargadorNiveles.cargar, nivelID, jugador)
		if ok then
			_ctx[jugador.UserId] = construirContexto(jugador)
			setEstado(jugador, ESTADO.GAMEPLAY)
		else
			warn("[GrafosV3] Error al reiniciar nivel:", err)
			setEstado(jugador, ESTADO.MENU)
		end
	end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 7. HANDLERS GAMEPLAY (guardiados por estaEnGameplay — Regla de Oro)
-- ═══════════════════════════════════════════════════════════════════════════════

-- MapaClickNodo: jugador clickeó un nodo desde el mapa cenital
local mapaClickNodo = esperarEvento("MapaClickNodo", 10)
if mapaClickNodo then
	mapaClickNodo.OnServerEvent:Connect(function(jugador, nombreNodo)
		-- REGLA DE ORO: ignorar si no está en gameplay
		if not estaEnGameplay(jugador) then return end
		if not nombreNodo then return end

		local ctx = _ctx[jugador.UserId]
		if not ctx then return end

		print("[GrafosV3] MapaClickNodo - Jugador:", jugador.Name, "Nodo:", nombreNodo)

		-- Notificar a ServicioMisiones
		if ctx.misiones and ctx.misiones.estaActivo() then
			pcall(ctx.misiones.alSeleccionarNodo, nombreNodo)
		end

		-- Enviar efectos visuales al cliente
		if ctx.cables and ctx.cables.estaActivo() then
			local nodoModel, adyacentesModels = ctx.cables.obtenerInfoNodo(nombreNodo)
			if nodoModel then
				local notificar = Remotos:FindFirstChild("NotificarSeleccionNodo")
				if notificar then
					notificar:FireClient(jugador, "NodoSeleccionado", nodoModel, adyacentesModels)
				end
			end
		end
	end)
else
	warn("[Boot.server] Evento MapaClickNodo no encontrado")
end

-- ConectarDesdeMapa: jugador quiere conectar dos nodos desde el mapa
local conectarDesdeMapa = esperarEvento("ConectarDesdeMapa", 10)
if conectarDesdeMapa then
	conectarDesdeMapa.OnServerEvent:Connect(function(jugador, nodoA, nodoB)
		-- REGLA DE ORO: ignorar si no está en gameplay
		if not estaEnGameplay(jugador) then return end
		if not nodoA or not nodoB then return end

		local ctx = _ctx[jugador.UserId]
		if not ctx then return end

		print("[GrafosV3] ConectarDesdeMapa - Jugador:", jugador.Name, nodoA, "->", nodoB)

		if ctx.cables and ctx.cables.estaActivo() and ctx.cables.conectarNodos then
			ctx.cables.conectarNodos(nodoA, nodoB, jugador)
		else
			warn("[GrafosV3] ConectarCables no activo o sin conectarNodos")
		end
	end)
else
	warn("[Boot.server] Evento ConectarDesdeMapa no encontrado")
end

print("[GrafosV3] === Boot Servidor Listo ===")
print("[GrafosV3] Estado inicial: todos los jugadores en MENU")
