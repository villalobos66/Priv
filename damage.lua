local REPEAT_AMOUNT = 26  -- Número de veces que repetirá cada golpe

-- Excepciones - eventos que NO se repetirán
local exceptions = {
    "SayMessageRequest",
    "MeleeUpdateEvent", 
    "NinjaBombEvent",
    "BulletUpdateEvent"
}

-- Interceptar y repetir llamadas remotas (como el primer script)
local mt = getrawmetatable(game)
local old = mt.__namecall
setreadonly(mt, false)

-- Variables para UI
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local damageRepeaterEnabled = false
local collectConnection = nil

-- ==================== UI PARA CONTROLAR EL REPETIDOR ====================
local function CreateMainFrame()
    local ScreenGui = player.PlayerGui:FindFirstChild("DamageRepeaterGUI") 
        or Instance.new("ScreenGui")
    ScreenGui.Name = "DamageRepeaterGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = player.PlayerGui
    
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 280, 0, 180)
    Frame.Position = UDim2.new(0.5, -140, 0.5, -90)
    Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Frame.BorderSizePixel = 0
    Frame.ClipsDescendants = true
    Frame.Parent = ScreenGui
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = Frame
    
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(255, 255, 255)
    UIStroke.Transparency = 0.4
    UIStroke.Thickness = 1.5
    UIStroke.Parent = Frame
    
    -- Título
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.Position = UDim2.new(0, 0, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "💥 Damage Repeater 💥"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 18
    Title.Font = Enum.Font.GothamBold
    Title.Parent = Frame
    
    -- Botón de activar/desactivar
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0.85, 0, 0, 50)
    toggleBtn.Position = UDim2.new(0.075, 0, 0.3, 0)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    toggleBtn.Text = "DAMAGE REPEATER: OFF"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 16
    toggleBtn.Parent = Frame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 10)
    btnCorner.Parent = toggleBtn
    
    -- Info de repetición
    local repeatInfo = Instance.new("TextLabel")
    repeatInfo.Size = UDim2.new(0.85, 0, 0, 30)
    repeatInfo.Position = UDim2.new(0.075, 0, 0.65, 0)
    repeatInfo.BackgroundTransparency = 1
    repeatInfo.Text = "🔁 Cada golpe se repite " .. REPEAT_AMOUNT .. " veces"
    repeatInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
    repeatInfo.TextSize = 12
    repeatInfo.Font = Enum.Font.Gotham
    repeatInfo.TextXAlignment = Enum.TextXAlignment.Center
    repeatInfo.Parent = Frame
    
    -- Input para cambiar cantidad de repeticiones
    local sliderLabel = Instance.new("TextLabel")
    sliderLabel.Size = UDim2.new(0.4, 0, 0, 20)
    sliderLabel.Position = UDim2.new(0.05, 0, 0.82, 0)
    sliderLabel.BackgroundTransparency = 1
    sliderLabel.Text = "Repeticiones:"
    sliderLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    sliderLabel.TextSize = 12
    sliderLabel.Font = Enum.Font.Gotham
    sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
    sliderLabel.Parent = Frame
    
    local repeatInput = Instance.new("TextBox")
    repeatInput.Size = UDim2.new(0.3, 0, 0, 30)
    repeatInput.Position = UDim2.new(0.65, 0, 0.8, 0)
    repeatInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    repeatInput.Text = tostring(REPEAT_AMOUNT)
    repeatInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    repeatInput.Font = Enum.Font.Gotham
    repeatInput.TextSize = 14
    repeatInput.Parent = Frame
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 8)
    inputCorner.Parent = repeatInput
    
    repeatInput.FocusLost:Connect(function()
        local num = tonumber(repeatInput.Text)
        if num and num > 0 and num <= 100 then
            REPEAT_AMOUNT = math.floor(num)
            repeatInput.Text = tostring(REPEAT_AMOUNT)
            repeatInfo.Text = "🔁 Cada golpe se repite " .. REPEAT_AMOUNT .. " veces"
        else
            repeatInput.Text = tostring(REPEAT_AMOUNT)
        end
    end)
    
    -- Botón de cerrar
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.Parent = Frame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        -- Restaurar metatable original
        if damageRepeaterEnabled then
            mt.__namecall = old
            setreadonly(mt, true)
        end
        Frame:Destroy()
    end)
    
    -- Hacer draggable
    local dragging, dragInput, dragStart, startPos
    Title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = Frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    Title.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    return toggleBtn, repeatInfo
end

-- ==================== FUNCIÓN PRINCIPAL DEL REPETIDOR ====================
local function EnableDamageRepeater()
    -- Modificar __namecall para repetir llamadas remotas
    mt.__namecall = function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        
        -- Verificar excepciones
        for _, exception in pairs(exceptions) do
            if self.Name == exception then
                return old(self, ...)
            end
        end
        
        -- Si es FireServer o InvokeServer, repetir la llamada
        if method == "FireServer" or method == "InvokeServer" then
            -- Verificar si parece ser un golpe/daño (opcional)
            local isDamageCall = false
            
            -- Intentar detectar si es un golpe (por el nombre del remote o los argumentos)
            if string.find(self.Name:lower(), "hit") or 
               string.find(self.Name:lower(), "damage") or
               string.find(self.Name:lower(), "attack") or
               string.find(self.Name:lower(), "melee") then
                isDamageCall = true
            end
            
            -- Si es un golpe identificado O si está activado para todos
            if isDamageCall or damageRepeaterEnabled then
                -- Repetir la llamada REPEAT_AMOUNT veces
                for i = 1, REPEAT_AMOUNT do
                    old(self, ...)
                end
            end
        end
        
        -- Ejecutar la llamada original una vez también
        return old(self, ...)
    end
end

local function DisableDamageRepeater()
    mt.__namecall = old
end

-- ==================== INICIALIZAR UI ====================
local toggleBtn, repeatInfo = CreateMainFrame()

toggleBtn.MouseButton1Click:Connect(function()
    damageRepeaterEnabled = not damageRepeaterEnabled
    
    if damageRepeaterEnabled then
        toggleBtn.Text = "DAMAGE REPEATER: ON"
        toggleBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
        EnableDamageRepeater()
        print("✅ Damage Repeater ACTIVADO - Cada golpe se repite " .. REPEAT_AMOUNT .. " veces")
    else
        toggleBtn.Text = "DAMAGE REPEATER: OFF"
        toggleBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        DisableDamageRepeater()
        print("❌ Damage Repeater DESACTIVADO")
    end
end)

print("🎯 Damage Repeater cargado - Actívalo para repetir todos los golpes de daño")
