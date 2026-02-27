-- ReplicatedStorage/Audio/ConfigAudio.lua
-- Configuracion centralizada de todos los sonidos del juego.
-- FUENTE UNICA DE VERDAD para configuracion de audio.
--
-- Estructura EXISTENTE en ReplicatedStorage/Audio:
--   Audio/
--   ├── Ambiente/
--   │   └── Nivel0, Nivel1, Nivel2, Nivel3, Nivel4
--   ├── BGM/
--   │   └── MusicaMenu/
--   │       ├── CambiarEscena, Click, MusicaCreditos, MusicaMenu, Play, Seleccion
--   ├── SFX/
--   │   └── CableConnect, CableSnap, Click, ConnectionFailed, Error, Success
--   └── Victoria/
--       └── Fanfare, Tema

local ConfigAudio = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- VOLUMENES POR CATEGORIA
-- ═══════════════════════════════════════════════════════════════════════════════

ConfigAudio.Volumenes = {
	MASTER = 1.0,        -- Volumen maestro (afecta todo)
	SFX = 0.7,           -- Efectos de sonido
	BGM = 0.4,           -- Musica de fondo
	AMBIENTE = 0.3,      -- Sonidos ambientales
	UI = 0.8,            -- Interfaz de usuario
	VICTORIA = 0.6,      -- Musica de victoria
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONFIGURACION DE SONIDOS
-- ═══════════════════════════════════════════════════════════════════════════════

ConfigAudio.Sonidos = {
	
	-- ============================================
	-- SFX - EFECTOS DE SONIDO
	-- ============================================
	-- NOTA: Estos sonidos deben existir en ReplicatedStorage/Audio/SFX/
	SFX = {
		CableConnect = {
			Nombre = "CableConnect",
			Categoria = "SFX",
			Volumen = 0.7,
			Pitch = 1.0,
			Loop = false,
			Ruta = "SFX/CableConnect", -- Ruta dentro de ReplicatedStorage/Audio
			Descripcion = "Sonido cuando se conecta un cable exitosamente"
		},
		CableSnap = {
			Nombre = "CableSnap",
			Categoria = "SFX",
			Volumen = 0.6,
			Pitch = 1.0,
			Loop = false,
			Ruta = "SFX/CableSnap",
			Descripcion = "Sonido cuando se desconecta un cable"
		},
		ConnectionFailed = {
			Nombre = "ConnectionFailed",
			Categoria = "SFX",
			Volumen = 0.6,
			Pitch = 0.9,
			Loop = false,
			Ruta = "SFX/ConnectionFailed",
			Descripcion = "Sonido de error al intentar conectar nodos no adyacentes"
		},
		Error = {
			Nombre = "Error",
			Categoria = "SFX",
			Volumen = 0.5,
			Pitch = 1.0,
			Loop = false,
			Ruta = "SFX/Error",
			Descripcion = "Sonido de error generico"
		},
		Success = {
			Nombre = "Success",
			Categoria = "SFX",
			Volumen = 0.7,
			Pitch = 1.0,
			Loop = false,
			Ruta = "SFX/Success",
			Descripcion = "Sonido de exito/confirmacion"
		},
		NodoSeleccionado = {
			Nombre = "NodoSeleccionado",
			Categoria = "SFX",
			Volumen = 0.4,
			Pitch = 1.1,
			Loop = false,
			Ruta = "SFX/Click", -- Usar Click como seleccion de nodo
			Descripcion = "Sonido al seleccionar un nodo"
		},
	},
	
	-- ============================================
	-- UI - INTERFAZ DE USUARIO
	-- ============================================
	-- NOTA: Estos sonidos deben existir en ReplicatedStorage/Audio/BGM/MusicaMenu/
	UI = {
		Click = {
			Nombre = "Click",
			Categoria = "UI",
			Volumen = 0.5,
			Pitch = 1.0,
			Loop = false,
			Ruta = "BGM/MusicaMenu/Click",
			Descripcion = "Click estandar en botones"
		},
		Hover = {
			Nombre = "Hover",
			Categoria = "UI",
			Volumen = 0.2,
			Pitch = 1.2,
			Loop = false,
			Ruta = "BGM/MusicaMenu/Seleccion", -- Usar Seleccion como hover
			Descripcion = "Hover sobre elementos interactivos"
		},
		Back = {
			Nombre = "Back",
			Categoria = "UI",
			Volumen = 0.4,
			Pitch = 0.9,
			Loop = false,
			Ruta = "BGM/MusicaMenu/Click", -- Usar Click para back tambien
			Descripcion = "Volver atras/cancelar"
		},
		Play = {
			Nombre = "Play",
			Categoria = "UI",
			Volumen = 0.6,
			Pitch = 1.0,
			Loop = false,
			Ruta = "BGM/MusicaMenu/Play",
			Descripcion = "Iniciar juego/nivel"
		},
		Seleccion = {
			Nombre = "Seleccion",
			Categoria = "UI",
			Volumen = 0.5,
			Pitch = 1.0,
			Loop = false,
			Ruta = "BGM/MusicaMenu/Seleccion",
			Descripcion = "Seleccionar nivel/opcion"
		},
		CambiarEscena = {
			Nombre = "CambiarEscena",
			Categoria = "UI",
			Volumen = 0.4,
			Pitch = 1.0,
			Loop = false,
			Ruta = "BGM/MusicaMenu/CambiarEscena",
			Descripcion = "Transicion entre pantallas"
		},
	},
	
	-- ============================================
	-- BGM - MUSICA DE FONDO (Menu)
	-- ============================================
	-- NOTA: Estos sonidos deben existir en ReplicatedStorage/Audio/BGM/MusicaMenu/
	BGM = {
		MusicaMenu = {
			Nombre = "MusicaMenu",
			Categoria = "BGM",
			Volumen = 1.0,       -- Volumen base (la categoria BGM aplica 0.4)
			Pitch = 1.0,
			Loop = true,
			Ruta = "BGM/MusicaMenu/MusicaMenu",
			Descripcion = "Musica de fondo del menu principal"
		},
		MusicaCreditos = {
			Nombre = "MusicaCreditos",
			Categoria = "BGM",
			Volumen = 1.0,       -- Volumen base maximo (la categoria BGM aplica 0.4)
			Pitch = 1.0,
			Loop = true,
			Ruta = "BGM/MusicaMenu/MusicaCreditos",
			Descripcion = "Musica de la pantalla de creditos"
		},
	},
	
	-- ============================================
	-- AMBIENTE - SONIDOS DE NIVEL
	-- ============================================
	-- NOTA: Estos sonidos deben existir en ReplicatedStorage/Audio/Ambiente/
	AMBIENTE = {
		Nivel0 = {
			Nombre = "Nivel0",
			Categoria = "AMBIENTE",
			Volumen = 0.25,
			Pitch = 1.0,
			Loop = true,
			Ruta = "Ambiente/Nivel0",
			Descripcion = "Ambiente del Laboratorio de Grafos"
		},
		Nivel1 = {
			Nombre = "Nivel1",
			Categoria = "AMBIENTE",
			Volumen = 0.25,
			Pitch = 1.0,
			Loop = true,
			Ruta = "Ambiente/Nivel1",
			Descripcion = "Ambiente de La Red Desconectada"
		},
		Nivel2 = {
			Nombre = "Nivel2",
			Categoria = "AMBIENTE",
			Volumen = 0.25,
			Pitch = 1.0,
			Loop = true,
			Ruta = "Ambiente/Nivel2",
			Descripcion = "Ambiente de La Fabrica de Senales"
		},
		Nivel3 = {
			Nombre = "Nivel3",
			Categoria = "AMBIENTE",
			Volumen = 0.25,
			Pitch = 1.0,
			Loop = true,
			Ruta = "Ambiente/Nivel3",
			Descripcion = "Ambiente de El Puente Roto"
		},
		Nivel4 = {
			Nombre = "Nivel4",
			Categoria = "AMBIENTE",
			Volumen = 0.25,
			Pitch = 1.0,
			Loop = true,
			Ruta = "Ambiente/Nivel4",
			Descripcion = "Ambiente de Ruta Minima"
		},
	},
	
	-- ============================================
	-- VICTORIA - MUSICA DE COMPLETADO
	-- ============================================
	-- NOTA: Estos sonidos deben existir en ReplicatedStorage/Audio/Victoria/
	VICTORIA = {
		Fanfare = {
			Nombre = "Fanfare",
			Categoria = "VICTORIA",
			Volumen = 0.7,
			Pitch = 1.0,
			Loop = false,
			Ruta = "Victoria/Fanfare",
			Descripcion = "Fanfarria al completar nivel"
		},
		Tema = {
			Nombre = "Tema",
			Categoria = "VICTORIA",
			Volumen = 0.5,
			Pitch = 1.0,
			Loop = true,
			Ruta = "Victoria/Tema",
			Descripcion = "Musica de fondo en pantalla de victoria"
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- FUNCIONES AUXILIARES
-- ═══════════════════════════════════════════════════════════════════════════════

-- Obtener configuracion de un sonido especifico
function ConfigAudio.obtenerConfig(categoria, nombre)
	if ConfigAudio.Sonidos[categoria] and ConfigAudio.Sonidos[categoria][nombre] then
		return ConfigAudio.Sonidos[categoria][nombre]
	end
	return nil
end

-- Obtener volumen base de una categoria
function ConfigAudio.obtenerVolumenCategoria(categoria)
	return ConfigAudio.Volumenes[categoria] or 0.5
end

-- Calcular volumen final aplicando master y categoria
function ConfigAudio.calcularVolumen(categoria, volumenSonido)
	local volMaster = ConfigAudio.Volumenes.MASTER
	local volCategoria = ConfigAudio.Volumenes[categoria] or 1
	volumenSonido = volumenSonido or 1
	return volMaster * volCategoria * volumenSonido
end

-- Lista de todos los sonidos para precarga
function ConfigAudio.obtenerTodosLosSonidos()
	local lista = {}
	for categoria, sonidos in pairs(ConfigAudio.Sonidos) do
		for nombre, config in pairs(sonidos) do
			table.insert(lista, {
				Categoria = categoria,
				Nombre = nombre,
				Config = config
			})
		end
	end
	return lista
end

return ConfigAudio
