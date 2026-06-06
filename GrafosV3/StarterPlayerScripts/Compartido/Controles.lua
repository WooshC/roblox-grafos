-- StarterPlayerScripts/Compartido/Controles.lua
-- Módulo centralizado de controles y atajos de teclado del juego
-- Registro único de teclas para evitar conflictos y facilitar mantenimiento

--[[
    ╔════════════════════════════════════════════════════════════════╗
    ║                    CONTROLES CENTRALIZADOS                     ║
    ║     Registro único de atajos de teclado para el juego          ║
    ╚════════════════════════════════════════════════════════════════╝

    ── TECLAS BLOQUEADAS POR ROBLOX (no usar) ──────────────────────

    Las siguientes teclas NO se deben registrar porque Roblox las
    intercepta a nivel de cliente o tienen comportamientos reservados
    que no se pueden anular:

    • Tab              → Navegación entre elementos UI de Roblox.
                         El juego nunca recibe este input.

    • Escape (Esc)     → Abre el menú principal de Roblox (Pause).
                         Aunque InputBegan puede detectarla antes de
                         que aparezca el menú, su comportamiento
                         primario no es anulable. Usarla puede causar
                         que el menú aparezca junto con la acción.

    • F9               → Abre la consola de desarrollador de Roblox.

    • F11              → Alterna pantalla completa (navegador / cliente).

    • F12              → Herramientas de desarrollador (DevTools) en
                         algunos clientes de escritorio.

    • LeftAlt / RightAlt
                       → Reservadas para atajos del sistema operativo
                         y del cliente de Roblox.

    • LeftWindows / RightWindows / LeftSuper / RightSuper
                       → Teclas del sistema operativo, nunca llegan
                         al juego.

    • PrintScreen      → Captura de pantalla del sistema.

    • Combinaciones Ctrl+W, Ctrl+N, Ctrl+T, Ctrl+R, etc.
                       → Atajos del navegador/cliente; no se deben
                         asignar para evitar cerrar la pestaña o
                         recargar la página accidentalmente.

    ── TECLAS EN USO ACTUALMENTE ───────────────────────────────────

    Tecla   │ Función
    ────────┼───────────────────────────────────────────────
    M       │ Abrir / cerrar Mapa Cenital
    T       │ Abrir / cerrar Panel de Análisis
    F       │ Abrir / cerrar Matriz de Adyacencia
    Y       │ Abrir / cerrar Panel de Misiones

    ── TECLAS DEL SISTEMA DE DIÁLOGO ──────────────────────────────

    Estas teclas están gestionadas por DialogoEvents.lua y solo
    funcionan mientras un diálogo está activo:

    Tecla   │ Función
    ────────┼───────────────────────────────────────────────
    Space   │ Continuar diálogo / completar texto

    Para agregar una nueva tecla de diálogo, modificar directamente
    DialogoEvents.lua, ya que ese sistema requiere un contexto activo
    y manejo especial de conexiones/desconexiones.

    ── CÓMO AGREGAR UNA NUEVA TECLA GLOBAL ────────────────────────

    1. Añade una entrada en la tabla ACCIONES (abajo).
    2. Implementa la función toggle / callback.
    3. Opcional: añade la tecla a la tabla TECLAS_EN_USO.
    4. Documenta la tecla en los comentarios de arriba.

    Ejemplo:
        [Enum.KeyCode.I] = {
            nombre = "Inventario",
            accion = function(abierto)
                if abierto then cerrarInventario() else abrirInventario() end
            end,
            estado = function() return inventarioAbierto end,
        },
]]

local UserInputService = game:GetService("UserInputService")

local Controles = {}

-- Tabla pública de teclas actualmente registradas (solo informativa)
Controles.TECLAS_EN_USO = {
    { tecla = "M", funcion = "Mapa Cenital" },
    { tecla = "T", funcion = "Panel de Análisis" },
    { tecla = "F", funcion = "Matriz de Adyacencia" },
    { tecla = "Y", funcion = "Panel de Misiones" },
}

-- Referencias a módulos HUD (se asignan vía init)
local _modulos = {}

-- Tabla de acciones: cada entrada define toggle + estado
local ACCIONES = {}

-- ════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ════════════════════════════════════════════════════════════════

---Registra los módulos HUD que serán controlados por teclas.
---@param modulos table Tabla con las referencias a los módulos.
function Controles.init(modulos)
    _modulos = modulos or {}

    -- ── Mapa Cenital (M) ──
    ACCIONES[Enum.KeyCode.M] = {
        nombre = "Mapa Cenital",
        accion = function()
            local mapa = _modulos.ModuloMapa
            if not mapa then return end
            if mapa.estaAbierto() then
                mapa.cerrar()
            else
                mapa.abrir()
            end
        end,
    }

    -- ── Panel de Análisis (T) ──
    ACCIONES[Enum.KeyCode.T] = {
        nombre = "Panel de Análisis",
        accion = function()
            local m = _modulos.ModuloAnalisis
            local mapa = _modulos.ModuloMapa
            if not m then return end
            if m.estaAbierto() then
                m.cerrar()
            else
                m.abrir()
            end
            -- Sincronizar leyenda igual que los botones UI del mapa
            if mapa and mapa.estaAbierto() then mapa.ocultarLeyenda() end
        end,
    }

    -- ── Matriz de Adyacencia (F) ──
    ACCIONES[Enum.KeyCode.F] = {
        nombre = "Matriz de Adyacencia",
        accion = function()
            local m = _modulos.ModuloMatriz
            local mapa = _modulos.ModuloMapa
            if not m then return end
            if m.estaAbierta() then
                m.cerrar()
            else
                m.abrir()
            end
            -- Sincronizar leyenda igual que los botones UI del mapa
            if mapa and mapa.estaAbierto() then mapa.ocultarLeyenda() end
        end,
    }

    -- ── Panel de Misiones (Y) ──
    ACCIONES[Enum.KeyCode.Y] = {
        nombre = "Panel de Misiones",
        accion = function()
            local m = _modulos.PanelMisionesHUD
            local mapa = _modulos.ModuloMapa
            if not m then return end
            m.alternar()
            -- Sincronizar leyenda igual que el botón UI del mapa
            if mapa and mapa.estaAbierto() then mapa.ocultarLeyenda() end
        end,
    }

    -- Conectar el listener global de teclado
    UserInputService.InputBegan:Connect(Controles._onInputBegan)

    print("[Controles] Módulo central iniciado. Teclas activas: " .. Controles._listarTeclas())
end

-- ════════════════════════════════════════════════════════════════
-- MANEJO DE INPUT
-- ════════════════════════════════════════════════════════════════

function Controles._onInputBegan(input, gameProcessed)
    -- Ignorar input no-keyboard
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    -- Ignorar si el jugador está escribiendo en un TextBox o si
    -- Roblox ya procesó el input (ej. clic en un botón UI)
    if gameProcessed or UserInputService:GetFocusedTextBox() then return end

    local cfg = ACCIONES[input.KeyCode]
    if not cfg then return end

    -- Ejecutar acción
    local ok, err = pcall(cfg.accion)
    if not ok then
        warn("[Controles] Error al ejecutar '" .. cfg.nombre .. "': " .. tostring(err))
    end
end

-- ════════════════════════════════════════════════════════════════
-- UTILIDADES
-- ════════════════════════════════════════════════════════════════

---Devuelve un string con las teclas activas (para logs / depuración).
function Controles._listarTeclas()
    local partes = {}
    for keyCode, cfg in pairs(ACCIONES) do
        table.insert(partes, cfg.nombre .. " [" .. tostring(keyCode.Name) .. "]")
    end
    return table.concat(partes, ", ")
end

---Registra dinámicamente una nueva tecla en tiempo de ejecución.
---@param keyCode Enum.KeyCode La tecla a registrar.
---@param nombre string Nombre descriptivo de la acción.
---@param accion function Función a ejecutar cuando se pulse la tecla.
function Controles.registrar(keyCode, nombre, accion)
    if ACCIONES[keyCode] then
        warn("[Controles] La tecla " .. tostring(keyCode.Name) .. " ya está registrada para: " .. ACCIONES[keyCode].nombre)
        return
    end

    ACCIONES[keyCode] = {
        nombre = nombre,
        accion = accion,
    }

    table.insert(Controles.TECLAS_EN_USO, {
        tecla = tostring(keyCode.Name),
        funcion = nombre,
    })

    print("[Controles] Tecla registrada: " .. tostring(keyCode.Name) .. " → " .. nombre)
end

---Elimina el registro de una tecla.
---@param keyCode Enum.KeyCode La tecla a desregistrar.
function Controles.desregistrar(keyCode)
    if not ACCIONES[keyCode] then return end
    print("[Controles] Tecla desregistrada: " .. tostring(keyCode.Name) .. " → " .. ACCIONES[keyCode].nombre)
    ACCIONES[keyCode] = nil
end

---Verifica si una tecla está actualmente registrada.
---@param keyCode Enum.KeyCode
---@return boolean
function Controles.estaRegistrada(keyCode)
    return ACCIONES[keyCode] ~= nil
end

---Devuelve la tabla de acciones (solo lectura; útil para depuración).
function Controles.obtenerAcciones()
    local copia = {}
    for k, v in pairs(ACCIONES) do
        copia[k] = { nombre = v.nombre }
    end
    return copia
end

return Controles
