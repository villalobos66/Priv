local REPEAT_AMOUNT = 26  -- Número de veces que repetirá cada golpe

-- Excepciones - eventos que NO se repetirán
local exceptions = {
    "SayMessageRequest",
    "MeleeUpdateEvent", 
    "NinjaBombEvent",
    "BulletUpdateEvent"
}

-- Interceptar y repetir llamadas remotas
local mt = getrawmetatable(game)
local old = mt.__namecall
setreadonly(mt, false)

-- Variables para UI
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local damageRepeaterEnabled = false

-- NUEVO: Tabla para almacenar remotes reconocidos permanentemente
local recognizedRemotes = {}

-- ==================== UI MEJORADA Y ORDENADA ====================
local function CreateMainFrame()
    local ScreenGui = player.PlayerGui:FindFirstChild("DamageRepeaterGUI") 
        or Instance.new("ScreenGui")
    ScreenGui.Name = "DamageRepeaterGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = player.PlayerGui
    
    -- Frame principal
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 200, 0, 160)  -- Aumentado para mostrar más info
    Frame.Position = UDim2.new(0.5, -100, 0.5, -80)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Frame.BorderSizePixel = 0
    Frame.ClipsDescendants = true
    Frame.Parent = ScreenGui
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = Frame
    
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(255, 255, 255)
    UIStroke.Transparency = 0.3
    UIStroke.Thickness = 1
    UIStroke.Parent = Frame
    
    -- Barra superior (arrastrable)
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 32)
    TopBar.Position = UDim2.new(0, 0, 0, 0)
    TopBar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    TopBar.BorderSizePixel = 0
    TopBar.Parent = Frame
    
    local TopCorner = Instance.new("UICorner")
    TopCorner.CornerRadius = UDim.new(0, 10)
    TopCorner.Parent = TopBar
    
    -- Icono y título
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(0.7, 0, 1, 0)
    Title.Position = UDim2.new(0, 12, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "⚡ DAMAGE REPEATER"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 12
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TopBar
    
    -- Botón cerrar
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 24, 0, 24)
    CloseBtn.Position = UDim2.new(1, -30, 0, 4)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 14
    CloseBtn.Parent = TopBar
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 6)
    CloseCorner.Parent = CloseBtn
    
    CloseBtn.MouseButton1Click:Connect(function()
        if damageRepeaterEnabled then
            mt.__namecall = old
            setreadonly(mt, true)
        end
        Frame:Destroy()
    end)
    
    -- Contenedor principal de contenido
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 1, -32)
    Container.Position = UDim2.new(0, 0, 0, 32)
    Container.BackgroundTransparency = 1
    Container.Parent = Frame
    
    -- Línea divisoria
    local Divider = Instance.new("Frame")
    Divider.Size = UDim2.new(0.9, 0, 0, 1)
    Divider.Position = UDim2.new(0.05, 0, 0, 0)
    Divider.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    Divider.BorderSizePixel = 0
    Divider.Parent = Container
    
    -- Botón de activar (centrado y más grande)
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0.8, 0, 0, 40)
    ToggleBtn.Position = UDim2.new(0.1, 0, 0.15, 0)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    ToggleBtn.Text = "◉  REPEATER: OFF  ◉"
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.TextSize = 12
    ToggleBtn.Parent = Container
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 8)
    ToggleCorner.Parent = ToggleBtn
    
    -- Efecto hover
    ToggleBtn.MouseEnter:Connect(function()
        if not damageRepeaterEnabled then
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
        else
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 90, 50)
        end
    end)
    
    ToggleBtn.MouseLeave:Connect(function()
        if not damageRepeaterEnabled then
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        else
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 85, 45)
        end
    end)
    
    -- Sección de repeticiones
    local RepeatSection = Instance.new("Frame")
    RepeatSection.Size = UDim2.new(1, 0, 0, 45)
    RepeatSection.Position = UDim2.new(0, 0, 0.55, 0)
    RepeatSection.BackgroundTransparency = 1
    RepeatSection.Parent = Container
    
    -- Label de repeticiones
    local RepeatLabel = Instance.new("TextLabel")
    RepeatLabel.Size = UDim2.new(0.45, 0, 0, 25)
    RepeatLabel.Position = UDim2.new(0.05, 0, 0, 0)
    RepeatLabel.BackgroundTransparency = 1
    RepeatLabel.Text = "🔄 REPETICIONES:"
    RepeatLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
    RepeatLabel.TextSize = 11
    RepeatLabel.Font = Enum.Font.GothamBold
    RepeatLabel.TextXAlignment = Enum.TextXAlignment.Left
    RepeatLabel.Parent = RepeatSection
    
    -- Input de repeticiones
    local RepeatInput = Instance.new("TextBox")
    RepeatInput.Size = UDim2.new(0.35, 0, 0, 32)
    RepeatInput.Position = UDim2.new(0.6, 0, 0, -3)
    RepeatInput.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    RepeatInput.Text = tostring(REPEAT_AMOUNT)
    RepeatInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    RepeatInput.Font = Enum.Font.Gotham
    RepeatInput.TextSize = 14
    RepeatInput.TextXAlignment = Enum.TextXAlignment.Center
    RepeatInput.Parent = RepeatSection
    
    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 6)
    InputCorner.Parent = RepeatInput
    
    -- Indicador de rango
    local RangeHint = Instance.new("TextLabel")
    RangeHint.Size = UDim2.new(0.35, 0, 0, 15)
    RangeHint.Position = UDim2.new(0.6, 0, 0.7, 0)
    RangeHint.BackgroundTransparency = 1
    RangeHint.Text = "(1 - 100)"
    RangeHint.TextColor3 = Color3.fromRGB(120, 120, 130)
    RangeHint.TextSize = 9
    RangeHint.Font = Enum.Font.Gotham
    RangeHint.TextXAlignment = Enum.TextXAlignment.Center
    RangeHint.Parent = RepeatSection
    
    -- NUEVO: Contador de remotes reconocidos
    local RemoteCounter = Instance.new("TextLabel")
    RemoteCounter.Size = UDim2.new(1, 0, 0, 15)
    RemoteCounter.Position = UDim2.new(0, 0, 0.85, 0)
    RemoteCounter.BackgroundTransparency = 1
    RemoteCounter.Text = "📡 Remotes reconocidos: 0"
    RemoteCounter.TextColor3 = Color3.fromRGB(100, 100, 110)
    RemoteCounter.TextSize = 9
    RemoteCounter.Font = Enum.Font.Gotham
    RemoteCounter.Parent = Container
    
    RepeatInput.FocusLost:Connect(function()
        local num = tonumber(RepeatInput.Text)
        if num and num >= 1 and num <= 100 then
            REPEAT_AMOUNT = math.floor(num)
            RepeatInput.Text = tostring(REPEAT_AMOUNT)
        else
            RepeatInput.Text = tostring(REPEAT_AMOUNT)
        end
    end)
    
    -- Estado actual (texto informativo pequeño)
    local StatusText = Instance.new("TextLabel")
    StatusText.Size = UDim2.new(1, 0, 0, 18)
    StatusText.Position = UDim2.new(0, 0, 0.93, 0)
    StatusText.BackgroundTransparency = 1
    StatusText.Text = "⚡ Guarda remotes incluso cuando está apagado"
    StatusText.TextColor3 = Color3.fromRGB(100, 100, 110)
    StatusText.TextSize = 8
    StatusText.Font = Enum.Font.Gotham
    StatusText.Parent = Container
    
    -- ==================== MOVIMIENTO TÁCTIL ====================
    local dragging = false
    local dragStartMousePos = nil
    local dragStartFramePos = nil
    
    local function UpdateFramePosition(inputPosition)
        if not dragging then return end
        local delta = inputPosition - dragStartMousePos
        Frame.Position = UDim2.new(
            dragStartFramePos.X.Scale, 
            dragStartFramePos.X.Offset + delta.X,
            dragStartFramePos.Y.Scale, 
            dragStartFramePos.Y.Offset + delta.Y
        )
    end
    
    local function OnInputBegan(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            
            local mousePos = input.Position
            local frameAbsPos = Frame.AbsolutePosition
            local frameSize = Frame.AbsoluteSize
            
            if mousePos.X >= frameAbsPos.X and mousePos.X <= frameAbsPos.X + frameSize.X and
               mousePos.Y >= frameAbsPos.Y and mousePos.Y <= frameAbsPos.Y + 32 then
                
                dragging = true
                dragStartMousePos = input.Position
                dragStartFramePos = Frame.Position
                
                TweenService:Create(TopBar, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(45, 45, 50)}):Play()
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        TweenService:Create(TopBar, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(30, 30, 35)}):Play()
                    end
                end)
            end
        end
    end
    
    local function OnInputChanged(input, gameProcessed)
        if gameProcessed then return end
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
           input.UserInputType == Enum.UserInputType.Touch) then
            UpdateFramePosition(input.Position)
        end
    end
    
    UserInputService.InputBegan:Connect(OnInputBegan)
    UserInputService.InputChanged:Connect(OnInputChanged)
    
    return ToggleBtn, RepeatInput, StatusText, RemoteCounter
end

-- ==================== FUNCIÓN PRINCIPAL (CON RECONOCIMIENTO PERMANENTE) ====================
local function EnableDamageRepeater()
    mt.__namecall = function(self, ...)
        local method = getnamecallmethod()
        
        for _, exception in pairs(exceptions) do
            if self.Name == exception then
                return old(self, ...)
            end
        end
        
        if method == "FireServer" or method == "InvokeServer" then
            -- Verificar si es un remote de golpe/damage
            local isDamageRemote = false
            
            if string.find(self.Name:lower(), "hit") or 
               string.find(self.Name:lower(), "damage") or
               string.find(self.Name:lower(), "attack") or
               string.find(self.Name:lower(), "melee") then
                isDamageRemote = true
                
                -- NUEVO: Guardar el remote reconocido permanentemente
                if not recognizedRemotes[self.Name] then
                    recognizedRemotes[self.Name] = {
                        name = self.Name,
                        hits = 0,
                        firstSeen = tick()
                    }
                    print("🔍 Remote reconocido y guardado permanentemente:", self.Name)
                end
                
                -- Actualizar contador de hits
                recognizedRemotes[self.Name].hits = recognizedRemotes[self.Name].hits + 1
            end
            
            -- NUEVO: Verificar si este remote ya fue reconocido anteriormente
            if not isDamageRemote and recognizedRemotes[self.Name] then
                isDamageRemote = true  -- Este remote ya fue identificado como damage remote
            end
            
            -- Repetir SOLO si es un remote de daño O si ya fue reconocido
            if isDamageRemote and damageRepeaterEnabled then
                for i = 1, REPEAT_AMOUNT do
                    old(self, ...)
                end
            end
        end
        
        return old(self, ...)
    end
end

local function DisableDamageRepeater()
    -- No desactivamos completamente, solo evitamos que repita
    -- pero seguimos reconociendo remotes
    mt.__namecall = function(self, ...)
        local method = getnamecallmethod()
        
        for _, exception in pairs(exceptions) do
            if self.Name == exception then
                return old(self, ...)
            end
        end
        
        if method == "FireServer" or method == "InvokeServer" then
            -- NUEVO: SEGUIR RECONOCIENDO REMOTES aunque esté apagado
            if string.find(self.Name:lower(), "hit") or 
               string.find(self.Name:lower(), "damage") or
               string.find(self.Name:lower(), "attack") or
               string.find(self.Name:lower(), "melee") then
                
                if not recognizedRemotes[self.Name] then
                    recognizedRemotes[self.Name] = {
                        name = self.Name,
                        hits = 0,
                        firstSeen = tick()
                    }
                    print("🔍 Remote reconocido (en modo pasivo):", self.Name)
                end
                
                recognizedRemotes[self.Name].hits = recognizedRemotes[self.Name].hits + 1
            end
            
            -- Verificar remotes previamente reconocidos
            if recognizedRemotes[self.Name] then
                -- Solo registramos, no repetimos
                recognizedRemotes[self.Name].lastSeen = tick()
            end
        end
        
        return old(self, ...)
    end
end

-- ==================== FUNCIÓN PARA ACTUALIZAR UI DE REMOTES ====================
local function UpdateRemoteCounter(RemoteCounter)
    if RemoteCounter then
        local count = 0
        for _ in pairs(recognizedRemotes) do
            count = count + 1
        end
        RemoteCounter.Text = "📡 Remotes reconocidos: " .. count .. " (permanentes)"
        
        -- Cambiar color si hay remotes
        if count > 0 then
            RemoteCounter.TextColor3 = Color3.fromRGB(100, 200, 100)
        else
            RemoteCounter.TextColor3 = Color3.fromRGB(100, 100, 110)
        end
    end
end

-- ==================== INICIALIZAR ====================
local ToggleBtn, RepeatInput, StatusText, RemoteCounter = CreateMainFrame()

-- Hilo para actualizar contador de remotes
spawn(function()
    while true do
        wait(1)
        UpdateRemoteCounter(RemoteCounter)
    end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    damageRepeaterEnabled = not damageRepeaterEnabled
    
    if damageRepeaterEnabled then
        ToggleBtn.Text = "◉  REPEATER: ON  ◉"
        ToggleBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 85, 45)
        StatusText.Text = "✅ ACTIVADO - Repitiendo " .. REPEAT_AMOUNT .. "x cada golpe"
        StatusText.TextColor3 = Color3.fromRGB(100, 200, 100)
        EnableDamageRepeater()
    else
        ToggleBtn.Text = "◉  REPEATER: OFF  ◉"
        ToggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        StatusText.Text = "⚡ Modo pasivo - Reconociendo remotes (no repite)"
        StatusText.TextColor3 = Color3.fromRGB(255, 200, 100)
        DisableDamageRepeater()
    end
end)

-- Actualizar texto de estado cuando cambia el número de repeticiones
RepeatInput.FocusLost:Connect(function()
    if damageRepeaterEnabled then
        StatusText.Text = "✅ ACTIVADO - Repitiendo " .. REPEAT_AMOUNT .. "x cada golpe"
    end
end)

-- Mostrar remotes reconocidos en consola (opcional)
local function PrintRecognizedRemotes()
    print("=== REMOTES RECONOCIDOS PERMANENTEMENTE ===")
    for name, data in pairs(recognizedRemotes) do
        print(string.format("📡 %s - Hits: %d - Primera vez: %s", 
            name, 
            data.hits,
            os.date("%H:%M:%S", data.firstSeen)
        ))
    end
    print("===========================================")
end

-- Comando opcional para ver remotes (escribe "remotes" en la consola)
local oldPrint = print
print = function(...)
    local args = {...}
    if args[1] == "remotes" then
        PrintRecognizedRemotes()
    else
        oldPrint(...)
    end
end

print("✅ Damage Repeater v2 cargado - Guarda remotes permanentemente")
print("💡 Los remotes reconocidos se mantienen incluso al apagar/encender")
print("💡 Escribe 'remotes' en la consola para ver la lista")

-- Iniciar en modo pasivo (reconociendo pero sin repetir)
DisableDamageRepeater()
