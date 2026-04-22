local REPEAT_AMOUNT = 999999  -- INFINITO (número muy alto)
local REPEAT_DELAY = 0.1      -- Delay de 0.1 segundos

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

-- Tabla para almacenar remotes reconocidos permanentemente
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
    Frame.Size = UDim2.new(0, 220, 0, 175)
    Frame.Position = UDim2.new(0.5, -110, 0.5, -87)
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
    
    -- Barra superior
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 32)
    TopBar.Position = UDim2.new(0, 0, 0, 0)
    TopBar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    TopBar.BorderSizePixel = 0
    TopBar.Parent = Frame
    
    local TopCorner = Instance.new("UICorner")
    TopCorner.CornerRadius = UDim.new(0, 10)
    TopCorner.Parent = TopBar
    
    -- Título
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(0.7, 0, 1, 0)
    Title.Position = UDim2.new(0, 12, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "♾️ INFINITE REPEATER"
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
    
    -- Contenedor
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
    
    -- Botón de activar
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0.8, 0, 0, 40)
    ToggleBtn.Position = UDim2.new(0.1, 0, 0.1, 0)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    ToggleBtn.Text = "◉  REPEATER: OFF  ◉"
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.TextSize = 12
    ToggleBtn.Parent = Container
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 8)
    ToggleCorner.Parent = ToggleBtn
    
    -- Sección de delay
    local DelaySection = Instance.new("Frame")
    DelaySection.Size = UDim2.new(1, 0, 0, 45)
    DelaySection.Position = UDim2.new(0, 0, 0.45, 0)
    DelaySection.BackgroundTransparency = 1
    DelaySection.Parent = Container
    
    -- Label de delay
    local DelayLabel = Instance.new("TextLabel")
    DelayLabel.Size = UDim2.new(0.45, 0, 0, 25)
    DelayLabel.Position = UDim2.new(0.05, 0, 0, 0)
    DelayLabel.BackgroundTransparency = 1
    DelayLabel.Text = "⚡ VELOCIDAD (s):"
    DelayLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
    DelayLabel.TextSize = 11
    DelayLabel.Font = Enum.Font.GothamBold
    DelayLabel.TextXAlignment = Enum.TextXAlignment.Left
    DelayLabel.Parent = DelaySection
    
    -- Input de delay
    local DelayInput = Instance.new("TextBox")
    DelayInput.Size = UDim2.new(0.35, 0, 0, 32)
    DelayInput.Position = UDim2.new(0.6, 0, 0, -3)
    DelayInput.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    DelayInput.Text = string.format("%.1f", REPEAT_DELAY)
    DelayInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    DelayInput.Font = Enum.Font.Gotham
    DelayInput.TextSize = 14
    DelayInput.TextXAlignment = Enum.TextXAlignment.Center
    DelayInput.Parent = DelaySection
    
    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 6)
    InputCorner.Parent = DelayInput
    
    -- Indicador
    local RangeHint = Instance.new("TextLabel")
    RangeHint.Size = UDim2.new(0.35, 0, 0, 15)
    RangeHint.Position = UDim2.new(0.6, 0, 0.7, 0)
    RangeHint.BackgroundTransparency = 1
    RangeHint.Text = "(0.01 - 1.0)"
    RangeHint.TextColor3 = Color3.fromRGB(120, 120, 130)
    RangeHint.TextSize = 9
    RangeHint.Font = Enum.Font.Gotham
    RangeHint.TextXAlignment = Enum.TextXAlignment.Center
    RangeHint.Parent = DelaySection
    
    -- Contador de remotes
    local RemoteCounter = Instance.new("TextLabel")
    RemoteCounter.Size = UDim2.new(1, 0, 0, 15)
    RemoteCounter.Position = UDim2.new(0, 0, 0.75, 0)
    RemoteCounter.BackgroundTransparency = 1
    RemoteCounter.Text = "📡 Remotes reconocidos: 0"
    RemoteCounter.TextColor3 = Color3.fromRGB(100, 100, 110)
    RemoteCounter.TextSize = 9
    RemoteCounter.Font = Enum.Font.Gotham
    RemoteCounter.Parent = Container
    
    DelayInput.FocusLost:Connect(function()
        local num = tonumber(DelayInput.Text)
        if num and num >= 0.01 and num <= 1.0 then
            REPEAT_DELAY = num
            DelayInput.Text = string.format("%.2f", REPEAT_DELAY)
        else
            DelayInput.Text = string.format("%.1f", REPEAT_DELAY)
        end
    end)
    
    -- Estado actual
    local StatusText = Instance.new("TextLabel")
    StatusText.Size = UDim2.new(1, 0, 0, 18)
    StatusText.Position = UDim2.new(0, 0, 0.88, 0)
    StatusText.BackgroundTransparency = 1
    StatusText.Text = "♾️ INFINITO | " .. string.format("%.1f", REPEAT_DELAY) .. "s de delay"
    StatusText.TextColor3 = Color3.fromRGB(100, 200, 100)
    StatusText.TextSize = 8
    StatusText.Font = Enum.Font.Gotham
    StatusText.Parent = Container
    
    -- Movimiento
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
    
    return ToggleBtn, DelayInput, StatusText, RemoteCounter
end

-- ==================== FUNCIÓN PRINCIPAL (INFINITA) ====================
local function EnableDamageRepeater()
    mt.__namecall = function(self, ...)
        local method = getnamecallmethod()
        
        for _, exception in pairs(exceptions) do
            if self.Name == exception then
                return old(self, ...)
            end
        end
        
        if method == "FireServer" or method == "InvokeServer" then
            local isDamageRemote = false
            
            if string.find(self.Name:lower(), "hit") or 
               string.find(self.Name:lower(), "damage") or
               string.find(self.Name:lower(), "attack") or
               string.find(self.Name:lower(), "melee") then
                isDamageRemote = true
                
                if not recognizedRemotes[self.Name] then
                    recognizedRemotes[self.Name] = {
                        name = self.Name,
                        hits = 0,
                        firstSeen = tick()
                    }
                    print("🔍 Remote reconocido:", self.Name)
                end
                
                recognizedRemotes[self.Name].hits = recognizedRemotes[self.Name].hits + 1
            end
            
            if not isDamageRemote and recognizedRemotes[self.Name] then
                isDamageRemote = true
            end
            
            -- REPETICIÓN INFINITA CON DELAY
            if isDamageRemote and damageRepeaterEnabled then
                -- Usar spawn para no congelar
                spawn(function()
                    for i = 1, REPEAT_AMOUNT do
                        old(self, ...)
                        if REPEAT_DELAY > 0 then
                            wait(REPEAT_DELAY)
                        end
                    end
                end)
            end
        end
        
        return old(self, ...)
    end
end

local function DisableDamageRepeater()
    mt.__namecall = function(self, ...)
        local method = getnamecallmethod()
        
        for _, exception in pairs(exceptions) do
            if self.Name == exception then
                return old(self, ...)
            end
        end
        
        if method == "FireServer" or method == "InvokeServer" then
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
                    print("🔍 Remote reconocido (pasivo):", self.Name)
                end
                
                recognizedRemotes[self.Name].hits = recognizedRemotes[self.Name].hits + 1
            end
            
            if recognizedRemotes[self.Name] then
                recognizedRemotes[self.Name].lastSeen = tick()
            end
        end
        
        return old(self, ...)
    end
end

-- ==================== ACTUALIZAR UI ====================
local function UpdateRemoteCounter(RemoteCounter)
    if RemoteCounter then
        local count = 0
        for _ in pairs(recognizedRemotes) do
            count = count + 1
        end
        RemoteCounter.Text = "📡 Remotes reconocidos: " .. count
        if count > 0 then
            RemoteCounter.TextColor3 = Color3.fromRGB(100, 200, 100)
        else
            RemoteCounter.TextColor3 = Color3.fromRGB(100, 100, 110)
        end
    end
end

-- ==================== INICIALIZAR ====================
local ToggleBtn, DelayInput, StatusText, RemoteCounter = CreateMainFrame()

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
        StatusText.Text = "✅ INFINITO - " .. string.format("%.2f", REPEAT_DELAY) .. "s entre golpes"
        StatusText.TextColor3 = Color3.fromRGB(100, 200, 100)
        EnableDamageRepeater()
        print("✅ REPETIDOR INFINITO ACTIVADO - Delay: " .. REPEAT_DELAY .. "s")
    else
        ToggleBtn.Text = "◉  REPEATER: OFF  ◉"
        ToggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        StatusText.Text = "⚡ Modo pasivo - Reconociendo remotes"
        StatusText.TextColor3 = Color3.fromRGB(255, 200, 100)
        DisableDamageRepeater()
        print("⏹️ REPETIDOR DESACTIVADO")
    end
end)

DelayInput.FocusLost:Connect(function()
    if damageRepeaterEnabled then
        StatusText.Text = "✅ INFINITO - " .. string.format("%.2f", REPEAT_DELAY) .. "s entre golpes"
    end
end)

print("♾️ INFINITE REPEATER CARGADO")
print("⚡ Delay configurable: " .. REPEAT_DELAY .. " segundos")
print("💡 Activa el repetidor desde la interfaz")
