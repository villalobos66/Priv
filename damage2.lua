local REPEAT_AMOUNT = 999999  -- Número INFINITO de veces
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

-- ==================== UI SIMPLE (COMO LA QUE FUNCIONA) ====================
local function CreateMainFrame()
    local ScreenGui = player.PlayerGui:FindFirstChild("DamageRepeaterGUI") 
        or Instance.new("ScreenGui")
    ScreenGui.Name = "DamageRepeaterGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = player.PlayerGui
    
    -- Frame principal
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 200, 0, 120)
    Frame.Position = UDim2.new(0.5, -100, 0.5, -60)
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
    
    -- Botón de activar
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
    
    -- Texto de estado
    local StatusText = Instance.new("TextLabel")
    StatusText.Size = UDim2.new(1, 0, 0, 18)
    StatusText.Position = UDim2.new(0, 0, 0.65, 0)
    StatusText.BackgroundTransparency = 1
    StatusText.Text = "♾️ INFINITO | 0.1s de delay"
    StatusText.TextColor3 = Color3.fromRGB(100, 200, 100)
    StatusText.TextSize = 10
    StatusText.Font = Enum.Font.Gotham
    StatusText.Parent = Container
    
    -- Movimiento de ventana
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
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = input.Position
            local frameAbsPos = Frame.AbsolutePosition
            local frameSize = Frame.AbsoluteSize
            
            if mousePos.X >= frameAbsPos.X and mousePos.X <= frameAbsPos.X + frameSize.X and
               mousePos.Y >= frameAbsPos.Y and mousePos.Y <= frameAbsPos.Y + 32 then
                
                dragging = true
                dragStartMousePos = input.Position
                dragStartFramePos = Frame.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end
    end
    
    local function OnInputChanged(input, gameProcessed)
        if gameProcessed then return end
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            UpdateFramePosition(input.Position)
        end
    end
    
    UserInputService.InputBegan:Connect(OnInputBegan)
    UserInputService.InputChanged:Connect(OnInputChanged)
    
    return ToggleBtn, StatusText
end

-- ==================== FUNCIÓN PRINCIPAL ====================
local function EnableDamageRepeater()
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
                
                -- Repetición INFINITA con delay
                if damageRepeaterEnabled then
                    spawn(function()
                        for i = 1, REPEAT_AMOUNT do
                            old(self, ...)
                            wait(REPEAT_DELAY)
                        end
                    end)
                end
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
            -- Solo reconoce, no repite
            if string.find(self.Name:lower(), "hit") or 
               string.find(self.Name:lower(), "damage") or
               string.find(self.Name:lower(), "attack") or
               string.find(self.Name:lower(), "melee") then
                -- No hacer nada, solo pasar
            end
        end
        
        return old(self, ...)
    end
end

-- ==================== INICIALIZAR ====================
local ToggleBtn, StatusText = CreateMainFrame()

ToggleBtn.MouseButton1Click:Connect(function()
    damageRepeaterEnabled = not damageRepeaterEnabled
    
    if damageRepeaterEnabled then
        ToggleBtn.Text = "◉  REPEATER: ON  ◉"
        ToggleBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 85, 45)
        StatusText.Text = "✅ INFINITO ACTIVADO | Delay: " .. REPEAT_DELAY .. "s"
        StatusText.TextColor3 = Color3.fromRGB(100, 255, 100)
        EnableDamageRepeater()
        print("♾️ REPETIDOR INFINITO ACTIVADO - Cada " .. REPEAT_DELAY .. " segundos")
    else
        ToggleBtn.Text = "◉  REPEATER: OFF  ◉"
        ToggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        StatusText.Text = "⚡ REPETIDOR DESACTIVADO"
        StatusText.TextColor3 = Color3.fromRGB(255, 100, 100)
        DisableDamageRepeater()
        print("⏹️ REPETIDOR DESACTIVADO")
    end
end)

print("=" .. string.rep("=", 40))
print("♾️ INFINITE REPEATER v5 CARGADO")
print("⚡ Delay: " .. REPEAT_DELAY .. " segundos")
print("💡 Presiona el botón para activar")
print("=" .. string.rep("=", 40))
