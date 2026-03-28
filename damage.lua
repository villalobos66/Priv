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
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local damageRepeaterEnabled = false
local collectConnection = nil

-- ==================== UI CON TAMAÑO REDUCIDO (70%) Y SOPORTE TÁCTIL ====================
local function CreateMainFrame()
    local ScreenGui = player.PlayerGui:FindFirstChild("DamageRepeaterGUI") 
        or Instance.new("ScreenGui")
    ScreenGui.Name = "DamageRepeaterGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = player.PlayerGui
    
    -- Frame principal con tamaño reducido al 70%
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 196, 0, 126)  -- 280*0.7=196, 180*0.7=126
    Frame.Position = UDim2.new(0.5, -98, 0.5, -63)  -- Centrado con nuevo tamaño
    Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Frame.BorderSizePixel = 0
    Frame.ClipsDescendants = true
    Frame.Parent = ScreenGui
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)  -- 12*0.7≈8
    UICorner.Parent = Frame
    
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(255, 255, 255)
    UIStroke.Transparency = 0.4
    UIStroke.Thickness = 1
    UIStroke.Parent = Frame
    
    -- Título (tamaño reducido)
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 28)  -- 40*0.7=28
    Title.Position = UDim2.new(0, 0, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "💥 Damage Repeater 💥"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 13  -- 18*0.7≈13
    Title.Font = Enum.Font.GothamBold
    Title.Parent = Frame
    
    -- Botón de activar/desactivar (tamaño reducido)
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0.85, 0, 0, 35)  -- 50*0.7=35
    toggleBtn.Position = UDim2.new(0.075, 0, 0.22, 0)  -- 0.3*0.7≈0.21 ajustado
    toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    toggleBtn.Text = "DAMAGE REPEATER: OFF"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 11  -- 16*0.7≈11
    toggleBtn.Parent = Frame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 7)  -- 10*0.7=7
    btnCorner.Parent = toggleBtn
    
    -- Info de repetición (tamaño reducido)
    local repeatInfo = Instance.new("TextLabel")
    repeatInfo.Size = UDim2.new(0.85, 0, 0, 21)  -- 30*0.7=21
    repeatInfo.Position = UDim2.new(0.075, 0, 0.55, 0)  -- 0.65*0.7≈0.455 ajustado
    repeatInfo.BackgroundTransparency = 1
    repeatInfo.Text = "🔁 Cada golpe se repite " .. REPEAT_AMOUNT .. " veces"
    repeatInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
    repeatInfo.TextSize = 8  -- 12*0.7≈8
    repeatInfo.Font = Enum.Font.Gotham
    repeatInfo.TextXAlignment = Enum.TextXAlignment.Center
    repeatInfo.Parent = Frame
    
    -- Label para repeticiones (tamaño reducido)
    local sliderLabel = Instance.new("TextLabel")
    sliderLabel.Size = UDim2.new(0.4, 0, 0, 14)  -- 20*0.7=14
    sliderLabel.Position = UDim2.new(0.05, 0, 0.7, 0)  -- 0.82*0.7≈0.574 ajustado
    sliderLabel.BackgroundTransparency = 1
    sliderLabel.Text = "Repeticiones:"
    sliderLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    sliderLabel.TextSize = 8  -- 12*0.7≈8
    sliderLabel.Font = Enum.Font.Gotham
    sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
    sliderLabel.Parent = Frame
    
    -- Input para cambiar cantidad de repeticiones (tamaño reducido)
    local repeatInput = Instance.new("TextBox")
    repeatInput.Size = UDim2.new(0.3, 0, 0, 21)  -- 30*0.7=21
    repeatInput.Position = UDim2.new(0.65, 0, 0.68, 0)  -- 0.8*0.7=0.56 ajustado
    repeatInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    repeatInput.Text = tostring(REPEAT_AMOUNT)
    repeatInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    repeatInput.Font = Enum.Font.Gotham
    repeatInput.TextSize = 10  -- 14*0.7≈10
    repeatInput.Parent = Frame
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)  -- 8*0.7≈6
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
    
    -- Botón de cerrar (tamaño reducido)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 21, 0, 21)  -- 30*0.7=21
    closeBtn.Position = UDim2.new(1, -25, 0, 4)  -- -35*0.7≈-25, 5*0.7≈4
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 13  -- 18*0.7≈13
    closeBtn.Parent = Frame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)  -- 8*0.7≈6
    closeCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        -- Restaurar metatable original
        if damageRepeaterEnabled then
            mt.__namecall = old
            setreadonly(mt, true)
        end
        Frame:Destroy()
    end)
    
    -- ==================== SOPORTE PARA MOVER CON TÁCTIL ====================
    local dragging = false
    local dragStartPos = nil
    local dragStartMousePos = nil
    local dragStartFramePos = nil
    
    -- Función para mover el frame
    local function UpdateFramePosition(inputPosition)
        if not dragging then return end
        
        local delta = inputPosition - dragStartMousePos
        local newXOffset = dragStartFramePos.X.Offset + delta.X
        local newYOffset = dragStartFramePos.Y.Offset + delta.Y
        
        Frame.Position = UDim2.new(
            dragStartFramePos.X.Scale, newXOffset,
            dragStartFramePos.Y.Scale, newYOffset
        )
    end
    
    -- Detectar inicio de arrastre (tanto mouse como táctil)
    local function OnInputBegan(input, gameProcessed)
        if gameProcessed then return end
        
        -- Detectar si es click izquierdo o toque táctil
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            
            -- Verificar si se hizo click en el título (área arrastrable)
            local mousePos = input.Position
            local frameAbsPos = Frame.AbsolutePosition
            local frameSize = Frame.AbsoluteSize
            
            -- Área del título para arrastrar (parte superior del frame)
            if mousePos.X >= frameAbsPos.X and mousePos.X <= frameAbsPos.X + frameSize.X and
               mousePos.Y >= frameAbsPos.Y and mousePos.Y <= frameAbsPos.Y + 28 then  -- Altura del título
                
                dragging = true
                dragStartMousePos = input.Position
                dragStartFramePos = Frame.Position
                
                -- Pequeña animación de feedback al tocar
                TweenService:Create(Title, TweenInfo.new(0.1), {TextColor3 = Color3.fromRGB(200, 200, 200)}):Play()
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        TweenService:Create(Title, TweenInfo.new(0.1), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                    end
                end)
            end
        end
    end
    
    -- Detectar movimiento (mouse y táctil)
    local function OnInputChanged(input, gameProcessed)
        if gameProcessed then return end
        
        if dragging then
            if input.UserInputType == Enum.UserInputType.MouseMovement or
               input.UserInputType == Enum.UserInputType.Touch then
                UpdateFramePosition(input.Position)
            end
        end
    end
    
    -- Conectar eventos para mouse y táctil
    UserInputService.InputBegan:Connect(OnInputBegan)
    UserInputService.InputChanged:Connect(OnInputChanged)
    
    -- También soporte para mouse (por si acaso)
    Title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStartMousePos = input.Position
            dragStartFramePos = Frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    Title.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            UpdateFramePosition(input.Position)
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
            -- Verificar si parece ser un golpe/daño
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

print("🎯 Damage Repeater cargado - Interfaz al 70% con soporte táctil")
