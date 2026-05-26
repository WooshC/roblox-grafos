-- ServerScriptService/SistemasGameplay/TimerEmergencia.lua
-- Timer de emergencia con tiempo límite para misiones tipo EMERGENCIA.
-- Extraído de ServicioMisiones.lua para cumplir SRP.
-- Responsabilidad única: gestionar el countdown, pausas por diálogo, y notificar al cliente.

local TimerEmergencia = {}
TimerEmergencia.__index = TimerEmergencia

local RunService = game:GetService("RunService")

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONSTRUCTOR
-- ═══════════════════════════════════════════════════════════════════════════════

---Crea una nueva instancia del timer de emergencia.
-- @param config table
--   - eventoTimer: RemoteEvent — canal TimerEmergencia hacia el cliente
--   - jugador: Player — jugador al que se notifica
--   - onExpirado: function(misionID) — llamado cuando el tiempo se agota
--   - onEmergenciaSuperada: function(misionID, textoMision) — llamado al completar
function TimerEmergencia.nuevo(config)
	local self = setmetatable({}, TimerEmergencia)
	self._eventoTimer   = config.eventoTimer
	self._jugador       = config.jugador
	self._onExpirado    = config.onExpirado
	self._onSuperada    = config.onEmergenciaSuperada

	-- Estado interno
	self._conn              = nil
	self._deadline          = nil
	self._misionID          = nil
	self._textoMision       = nil
	self._fallido           = false
	self._completado        = false
	self._pausado           = false
	self._tiempoRestantePausa = nil
	self._ultimoSegundo     = nil
	self._debePausarseAlIniciar = false

	return self
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- MÉTODOS PÚBLICOS
-- ═══════════════════════════════════════════════════════════════════════════════

function TimerEmergencia:iniciar(mision)
	-- No reiniciar si ya está activo para la misma misión
	if self._misionID == mision.ID and self._conn then
		print(string.format("[TimerEmergencia] ⚠️ Timer %d ya activo, no se reinicia", mision.ID))
		return
	end
	-- No reiniciar si ya finalizó
	if self._fallido or self._completado then
		print(string.format("[TimerEmergencia] ⚠️ Timer %d ya finalizó (fallido=%s, completado=%s)",
			mision.ID, tostring(self._fallido), tostring(self._completado)))
		return
	end

	self:detener()

	local tiempoLimite = mision.Parametros and mision.Parametros.TiempoLimite or 60
	self._deadline    = tick() + tiempoLimite
	self._misionID    = mision.ID
	self._textoMision = mision.Texto
	self._fallido     = false
	self._completado  = false
	self._pausado     = false
	self._tiempoRestantePausa = nil

	print(string.format("[TimerEmergencia] 🚨 EMERGENCIA %d iniciada | Tiempo: %ds", mision.ID, tiempoLimite))

	-- Si se pidió pausa antes de que el timer existiera, pausar inmediatamente
	if self._debePausarseAlIniciar then
		self._debePausarseAlIniciar = false
		self._pausado = true
		self._tiempoRestantePausa = tiempoLimite
		print(string.format("[TimerEmergencia] 🚨 EMERGENCIA %d iniciada Y PAUSADA — restante: %ds", mision.ID, tiempoLimite))
		self:_notificarCliente(tiempoLimite, "PAUSADO")
	else
		self:_notificarCliente(tiempoLimite, mision.Texto)
	end

	-- Loop de actualización cada segundo
	self._ultimoSegundo = nil
	self._conn = RunService.Heartbeat:Connect(function()
		if not self._deadline or not self._jugador or not self._jugador.Parent then return end
		if self._pausado then return end

		local restante = math.max(0, math.floor(self._deadline - tick()))
		local segundoActual = math.floor(tick())

		if segundoActual == self._ultimoSegundo then return end
		self._ultimoSegundo = segundoActual

		self:_notificarCliente(restante, self._textoMision)

		if restante <= 0 then
			self._fallido = true
			print(string.format("[TimerEmergencia] ⏰ EMERGENCIA %d FALLIDA — Tiempo agotado", self._misionID))
			self:_notificarCliente(0, self._textoMision, true)
			if self._onExpirado then
				self._onExpirado(self._misionID)
			end
			self:detener()
		end
	end)
end

function TimerEmergencia:pausar()
	if self._pausado then return end
	if not self._conn or not self._deadline then
		-- Timer aún no existe; marcar para pausar al iniciar
		self._debePausarseAlIniciar = true
		print("[TimerEmergencia] ⏸️ Marca de pausa pendiente (timer aún no existe)")
		return
	end
	self._tiempoRestantePausa = math.max(0, self._deadline - tick())
	self._pausado = true
	print(string.format("[TimerEmergencia] ⏸️ Pausado — restante: %.0fs", self._tiempoRestantePausa))
	self:_notificarCliente(math.floor(self._tiempoRestantePausa), "PAUSADO")
end

function TimerEmergencia:reanudar()
	-- Limpiar marca de pausa pendiente si el timer aún no existía
	if self._debePausarseAlIniciar then
		self._debePausarseAlIniciar = false
		print("[TimerEmergencia] ▶️ Marca de pausa pendiente limpiada")
	end
	if not self._pausado or self._tiempoRestantePausa == nil then return end
	self._deadline = tick() + self._tiempoRestantePausa
	self._pausado = false
	self._tiempoRestantePausa = nil
	self._ultimoSegundo = nil
	print(string.format("[TimerEmergencia] ▶️ Reanudado — deadline: %.0fs", self._deadline - tick()))
	-- Notificar inmediatamente para evitar demora de 1s
	self:_notificarCliente(math.max(0, math.floor(self._deadline - tick())), self._textoMision)
end

function TimerEmergencia:detener()
	if self._conn then
		self._conn:Disconnect()
		self._conn = nil
	end
	self._deadline = nil
	self._misionID = nil
	self._textoMision = nil
end

function TimerEmergencia:marcarComoSuperada()
	if self._completado then return end
	self._completado = true
	print(string.format("[TimerEmergencia] 🎉 EMERGENCIA %d SUPERADA", self._misionID or 0))
	self:_notificarCliente(-1, self._textoMision or "EMERGENCIA", false, true)
	if self._onSuperada and self._misionID then
		self._onSuperada(self._misionID, self._textoMision)
	end
	self:detener()
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONSULTAS DE ESTADO
-- ═══════════════════════════════════════════════════════════════════════════════

function TimerEmergencia:estaActivo()
	return self._conn ~= nil
end

function TimerEmergencia:estaPausado()
	return self._pausado
end

function TimerEmergencia:estaFallido()
	return self._fallido
end

function TimerEmergencia:estaCompletado()
	return self._completado
end

function TimerEmergencia:obtenerMisionID()
	return self._misionID
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- PRIVADOS
-- ═══════════════════════════════════════════════════════════════════════════════

function TimerEmergencia:_notificarCliente(restante, texto, expirado, completada)
	if not self._eventoTimer or not self._jugador then return end
	self._eventoTimer:FireClient(self._jugador, restante, texto or "EMERGENCIA", expirado or false, completada or false)
end

return TimerEmergencia
