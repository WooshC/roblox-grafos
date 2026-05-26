with open('ServerScriptService/SistemasGameplay/ServicioMisiones.lua', 'r', encoding='utf-8') as f:
    lines = f.readlines()

start_idx = 190
end_idx = 335

new_block = """-- ════════════════════════════════════════════════════════════════════════════
-- TIMER DE EMERGENCIA (delegado a TimerEmergencia.lua)
-- ════════════════════════════════════════════════════════════════════════════

local function _onTimerExpirado(misionID)
	-- Penalización: -500 puntos por fallar la emergencia
	_puntosAcum = math.max(0, _puntosAcum - 500)
	if _servicioPuntaje then _servicioPuntaje:fijarPuntajeMision(_jugador, _puntosAcum, calcularEstrellasHelper(_puntosAcum)) end
	print(string.format("[ServicioMisiones] 💥 Penalización -500 pts | Puntaje actual: %d", _puntosAcum))
	verificarYNotificar()
end

local function _crearTimerEmergencia()
	_timerEmergencia = TimerEmergencia.nuevo({
		eventoTimer = _eventoTimerEmergencia,
		jugador     = _jugador,
		onExpirado  = _onTimerExpirado,
	})
end

local function iniciarTimerEmergenciaSiPendiente(nombreZona)
	if not nombreZona or nombreZona == "" then return end
	if not _timerEmergencia then return end
	for _, m in ipairs(_misiones) do
		if m.Zona == nombreZona and m.Tipo == "EMERGENCIA" and not _completadas[m.ID] then
			if _timerEmergencia:obtenerMisionID() ~= m.ID and not _timerEmergencia:estaFallido() and not _timerEmergencia:estaCompletado() then
				_timerEmergencia:iniciar(m)
			end
			break
		end
	end
end

"""

new_lines = lines[:start_idx] + [new_block] + lines[end_idx:]

with open('ServerScriptService/SistemasGameplay/ServicioMisiones.lua', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print("Reemplazado timer en ServicioMisiones.lua")
