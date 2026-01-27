local Economia = {}

-- Obtener dinero del jugador
function Economia.getDinero(player)
	if player and player:FindFirstChild("leaderstats") then
		return player.leaderstats.Money.Value
	end
	return 0
end

-- Descontar dinero (retorna true si se pudo, false si no)
function Economia.gastar(player, cantidad)
	if not player or not player:FindFirstChild("leaderstats") then return false end
	
	local money = player.leaderstats.Money
	
	if money.Value >= cantidad then
		money.Value = money.Value - cantidad
		return true
	else
		return false
	end
end

return Economia
