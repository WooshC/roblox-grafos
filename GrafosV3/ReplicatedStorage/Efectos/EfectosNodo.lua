-- ReplicatedStorage/Efectos/EfectosNodo.lua
-- Efectos visuales para nodos del grafo (cliente)

local TweenService = game:GetService("TweenService")
local PresetTween = require(script.Parent.PresetTween)

local EfectosNodo = {}

-- Estado de selección compartido
EfectosNodo.nodoSeleccionado = nil
EfectosNodo.nodosAdyacentes = {}

function EfectosNodo.establecerSeleccion(nombreNodo, adyacentes)
	EfectosNodo.nodoSeleccionado = nombreNodo
	EfectosNodo.nodosAdyacentes = {}
	
	if adyacentes then
		for _, vecino in ipairs(adyacentes) do
			EfectosNodo.nodosAdyacentes[vecino] = true
		end
	end
end

function EfectosNodo.limpiarSeleccion()
	EfectosNodo.nodoSeleccionado = nil
	EfectosNodo.nodosAdyacentes = {}
end

function EfectosNodo.estaSeleccionado(nombre)
	return EfectosNodo.nodoSeleccionado == nombre
end

function EfectosNodo.esAdyacente(nombre)
	return EfectosNodo.nodosAdyacentes[nombre] == true
end

function EfectosNodo.obtenerColorEstado(estado)
	local colores = {
		SELECCIONADO = PresetTween.COLORES.NODO_SELECCIONADO,
		ADYACENTE = PresetTween.COLORES.NODO_ADYACENTE,
		INICIO = PresetTween.COLORES.NODO_INICIO,
		ENERGIZADO = PresetTween.COLORES.NODO_ENERGIZADO,
		CONECTADO = PresetTween.COLORES.NODO_CONECTADO,
		DESCONECTADO = PresetTween.COLORES.NODO_DESCONECTADO,
	}
	return colores[estado] or PresetTween.COLORES.NODO_DESCONECTADO
end

function EfectosNodo.obtenerMaterialEstado(estado)
	if estado == "SELECCIONADO" or estado == "ADYACENTE" then
		return PresetTween.MATERIALES.NEON
	end
	return PresetTween.MATERIALES.PLASTICO
end

function EfectosNodo.aplicarASelector(parteSelector, estado)
	if not parteSelector or not parteSelector:IsA("BasePart") then
		return
	end
	
	local color = EfectosNodo.obtenerColorEstado(estado)
	local material = EfectosNodo.obtenerMaterialEstado(estado)
	
	-- Aplicar color y material
	parteSelector.Color = color
	parteSelector.Material = material
	
	-- Tween de tamaño según estado
	local tamanoBase = Vector3.new(2, 2, 2) -- Tamaño por defecto
	local multiplicador = 1.0
	
	if estado == "SELECCIONADO" then
		multiplicador = PresetTween.TAMANOS.NODO_SELECCIONADO
	elseif estado == "ADYACENTE" then
		multiplicador = PresetTween.TAMANOS.NODO_ADYACENTE
	end
	
	local tamanoObjetivo = tamanoBase * multiplicador
	if (parteSelector.Size - tamanoObjetivo).Magnitude > 0.01 then
		TweenService:Create(parteSelector, PresetTween.PRESETS.NODO_COLOR_CHANGE, {
			Size = tamanoObjetivo
		}):Play()
	end
end

function EfectosNodo.resetearSelector(parteSelector)
	if not parteSelector then return end
	
	if parteSelector:IsA("BasePart") then
		parteSelector.Transparency = 1
		parteSelector.Color = Color3.fromRGB(196, 196, 196)
		parteSelector.Material = PresetTween.MATERIALES.PLASTICO
	end
end

function EfectosNodo.flashError(parteSelector)
	if not parteSelector then return end
	
	local colorOriginal = parteSelector.Color
	
	-- Flash rojo
	parteSelector.Color = PresetTween.COLORES.ERROR
	parteSelector.Material = PresetTween.MATERIALES.NEON
	
	-- Volver a color original después
	task.delay(0.3, function()
		if parteSelector and parteSelector.Parent then
			TweenService:Create(parteSelector, PresetTween.PRESETS.NODO_COLOR_CHANGE, {
				Color = colorOriginal
			}):Play()
		end
	end)
end

return EfectosNodo
