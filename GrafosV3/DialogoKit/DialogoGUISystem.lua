--[[
    ╔════════════════════════════════════════════════════════════════╗
    ║               DIALOGOGUISYSTEM — SISTEMA PRINCIPAL             ║
    ║            Centro de control de todos los diálogos              ║
    ╚════════════════════════════════════════════════════════════════╝
    
    USO:
    local DialogoGUISystem = require(path.to.this.module)
    DialogoGUISystem:Play("DialogueKey", metadata)
]]

local DialogoGUISystem = {}
DialogoGUISystem.__index = DialogoGUISystem

-- ════════════════════════════════════════════════════════════════
-- ESTADO GLOBAL
-- ════════════════════════════════════════════════════════════════

DialogoGUISystem.gui = {}
DialogoGUISystem.isPlaying = false
DialogoGUISystem.currentDialogue = {}
DialogoGUISystem.currentLineIndex = 1
DialogoGUISystem.metadata = {}
DialogoGUISystem.controller = nil
DialogoGUISystem.renderer = nil
DialogoGUISystem.narrator = nil
DialogoGUISystem.events = nil

-- ════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ════════════════════════════════════════════════════════════════

function DialogoGUISystem:Init()
    print("[DialogoGUISystem] Inicializando sistema...")
    
    -- Cargar módulos dependientes
    local DialogoGUIBuilder = require(script:FindFirstAncestorOfClass("StarterGui"):FindFirstChild("DialogoGUI") or script.Parent)
    local DialogoController = require(script.Parent:FindFirstChild("DialogoController"))
    local DialogoRenderer = require(script.Parent:FindFirstChild("DialogoRenderer"))
    local DialogoNarrator = require(script.Parent:FindFirstChild("DialogoNarrator"))
    local DialogoEvents = require(script.Parent:FindFirstChild("DialogoEvents"))
    
    -- Crear GUI
    local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    self.gui = DialogoGUIBuilder:Create(playerGui)
    
    -- Inicializar módulos
    self.controller = DialogoController.new(self.gui, self)
    self.renderer = DialogoRenderer.new(self.gui)
    self.narrator = DialogoNarrator.new()
    self.events = DialogoEvents.new(self.gui, self.controller)
    
    print("[DialogoGUISystem] ✓ Sistema inicializado")
end

-- ════════════════════════════════════════════════════════════════
-- API PÚBLICA
-- ════════════════════════════════════════════════════════════════

---Inicia la reproducción de un diálogo
function DialogoGUISystem:Play(dialogueKey, metadata)
    if self.isPlaying then
        print("[DialogoGUISystem] ⚠ Ya hay un diálogo en reproducción")
        return false
    end
    
    -- Cargar datos del diálogo
    local dialogueData = self:LoadDialogue(dialogueKey)
    if not dialogueData then
        print("[DialogoGUISystem] ✗ No se encontró diálogo: " .. dialogueKey)
        return false
    end
    
    self.isPlaying = true
    self.currentDialogue = dialogueData
    self.currentLineIndex = 1
    self.metadata = metadata or {}
    
    print("[DialogoGUISystem] ▶ Iniciando diálogo: " .. dialogueKey)
    
    -- Iniciar reproducción
    self.gui.screenGui.Visible = true
    self.controller:RenderLine(self.currentLineIndex)
    
    return true
end

---Avanza a la siguiente línea
function DialogoGUISystem:Next()
    if not self.isPlaying then return end
    
    self.currentLineIndex = self.currentLineIndex + 1
    
    if self.currentLineIndex > #self.currentDialogue.Lineas then
        self:Close()
        return
    end
    
    self.controller:RenderLine(self.currentLineIndex)
end

---Retrocede a la línea anterior
function DialogoGUISystem:Previous()
    if not self.isPlaying then return end
    
    if self.currentLineIndex > 1 then
        self.currentLineIndex = self.currentLineIndex - 1
        self.controller:RenderLine(self.currentLineIndex)
    end
end

---Salta al final del diálogo
function DialogoGUISystem:Skip()
    if not self.isPlaying then return end
    
    self.currentLineIndex = #self.currentDialogue.Lineas
    self.controller:RenderLine(self.currentLineIndex)
end

---Selecciona una opción
function DialogoGUISystem:SelectChoice(optionIndex)
    if not self.isPlaying then return end
    
    local linea = self.currentDialogue.Lineas[self.currentLineIndex]
    if not linea.Opciones or not linea.Opciones[optionIndex] then return end
    
    local opcion = linea.Opciones[optionIndex]
    
    -- Ejecutar callback de la opción
    if opcion.OnSelect then
        opcion.OnSelect(self.gui, self.metadata)
    end
    
    -- Ejecutar siguiente
    if opcion.Siguiente and opcion.Siguiente ~= "FIN" then
        self:GoToLine(opcion.Siguiente)
    else
        self:Close()
    end
end

---Va a una línea específica por ID
function DialogoGUISystem:GoToLine(lineId)
    if not self.isPlaying then return end
    
    for i, linea in ipairs(self.currentDialogue.Lineas) do
        if linea.Id == lineId then
            self.currentLineIndex = i
            self.controller:RenderLine(self.currentLineIndex)
            return true
        end
    end
    
    print("[DialogoGUISystem] ⚠ Línea no encontrada: " .. lineId)
    return false
end

---Pausa el diálogo
function DialogoGUISystem:Pause()
    if self.narrator then
        self.narrator:Stop()
    end
end

---Reanuda el diálogo
function DialogoGUISystem:Resume()
    local linea = self.currentDialogue.Lineas[self.currentLineIndex]
    if linea and linea.Audio then
        self.narrator:Play(linea.Audio)
    end
end

---Cierra el diálogo y limpia
function DialogoGUISystem:Close()
    if not self.isPlaying then return end
    
    self.isPlaying = false
    self.gui.screenGui.Visible = false
    self.narrator:Stop()
    
    print("[DialogoGUISystem] ◼ Diálogo cerrado")
    
    -- Disparar evento de cierre
    if self.onClose then
        self.onClose()
    end
end

---Establece callback al cerrar
function DialogoGUISystem:OnClose(callback)
    self.onClose = callback
end

-- ════════════════════════════════════════════════════════════════
-- CARGA DE DIÁLOGOS
-- ════════════════════════════════════════════════════════════════

---Carga un diálogo de ReplicatedStorage o caché
function DialogoGUISystem:LoadDialogue(key)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local DialogoData = ReplicatedStorage:FindFirstChild("DialogoData")
    
    if not DialogoData then
        print("[DialogoGUISystem] ✗ Carpeta DialogoData no encontrada")
        return nil
    end
    
    -- Buscar en archivos Lua
    for _, module in pairs(DialogoData:GetChildren()) do
        if module:IsA("ModuleScript") then
            local data = require(module)
            if data[key] then
                return data[key]
            end
        end
    end
    
    print("[DialogoGUISystem] ✗ Diálogo no encontrado: " .. key)
    return nil
end

-- ════════════════════════════════════════════════════════════════
-- UTILIDADES
-- ════════════════════════════════════════════════════════════════

---Obtiene la línea actual
function DialogoGUISystem:GetCurrentLine()
    return self.currentDialogue.Lineas[self.currentLineIndex]
end

---Obtiene el índice actual
function DialogoGUISystem:GetLineIndex()
    return self.currentLineIndex
end

---Obtiene el total de líneas
function DialogoGUISystem:GetTotalLines()
    return #self.currentDialogue.Lineas
end

---Obtiene si está reproduciendo
function DialogoGUISystem:IsPlaying()
    return self.isPlaying
end

-- ════════════════════════════════════════════════════════════════
-- INSTANCIA SINGLETON
-- ════════════════════════════════════════════════════════════════

local instance = nil

function DialogoGUISystem.new()
    if not instance then
        instance = setmetatable({}, DialogoGUISystem)
        instance:Init()
    end
    return instance
end

-- Exportar
return DialogoGUISystem.new()
