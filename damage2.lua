-- Verificar si estamos en un entorno válido
if not game or not game:GetService("Players") then
    warn("Entorno no válido para ejecutar el script")
    return
end

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Esperar a que el jugador esté listo
if not player then
    game:GetService("Players").PlayerAdded:Wait()
    player = Players.LocalPlayer
end

-- Esperar a que la GUI del jugador exista
repeat wait() until player and player.PlayerGui

local REPEAT_AMOUNT = 999999  -- Valor alto para simular infinito
local REPEAT_DELAY = 0.1      -- Delay de 0.1 segundos entre repeticiones

-- Excepciones - eventos que NO se repetirán
local exceptions = {
    "SayMessageRequest",
    "MeleeUpdateEvent", 
    "NinjaBombEvent",
    "BulletUpdateEvent"
}

-- Variables para UI
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local damageRepeaterEnabled = false

-- Tabla para almacenar remotes reconocidos permanentemente
local recognizedRemotes = {}

-- Variables para el hook
local mt = nil
local old = nil
local hookActive = false

-- ==================== FUNCIONES DEL REPETIDOR ====================
local function SetupHook()
    if hookActive then return end
    
    local success, result = pcall(function()
        mt = getrawmetatable(game)
        old = mt.__namecall
        setreadonly(mt, false)
        hookActive = true
        return true
    end)
    
    if not success then
        warn("No se pudo obtener el metatable: " .. tostring(result))
        return false
    end
    return true
end

local function EnableDamageRepeater()
    if not SetupHook() then return end
    
    mt.__namecall = function(self, ...)
        local method = getnamecallmethod()
        
        -- Verificar excepciones
        for _, exception in pairs(exceptions) do
            if type(self) == "Instance" and self.Name == exception then
                return old(self, ...)
            end
        end
        
        if method == "FireServer" or method == "InvokeServer" then
            -- Verificar si es un remote de golpe/damage
            local isDamageRemote = false
            local remoteName = ""
            
            if type(self) == "Instance" then
                remoteName = self.Name
                
                if string.find(remoteName:lower(), "hit") or 
                   string.find(remoteName:lower(), "damage") or
                   string.find(remoteName:lower(), "attack") or
                   string.find(remoteName:lower(), "melee") or
                   string.find(remoteName:lower(), "punch") or
                   string.find(remoteName:lower(), "slash") then
                    isDamageRemote = true
                    
                    -- Guardar el remote reconocido
                    if not recognizedRemotes[remoteName] then
                        recognizedRemotes[remoteName] = {
                            name = remoteName,
                            hits = 0,
                            firstSeen = tick()
                        }
                        print("🔍 Remote reconocido:", remoteName)
                    end
                    
                    recognizedRemotes[remoteName].hits = recognizedRemotes[remoteName].hits + 1
                end
                
                -- Verificar si ya fue reconocido
                if not isDamageRemote and recognizedRemotes[remoteName] then
                    isDamageRemote = true
                end
            end
            
            -- Repetición INFINITA
            if isDamageRemote and damageRepeaterEnabled then
                -- Ejecutar la original
                local result = old(self, ...)
                
                -- Repetir en segundo plano
                task.spawn(function()
                    for i = 1, REPEAT_AMOUNT do
                        old(self, ...)
                        if REPEAT_DELAY > 0 then
                            task.wait(REPEAT_DELAY)
                        end
                    end
                end)
                
                return result
            end
        end
        
        return old(self, ...)
    end
end

local function DisableDamageRepeater()
    if not mt or not old then 
        if SetupHook() then
            mt.__namecall = old
        end
        return 
    end
    
    -- Modo pasivo: reconoce pero no repite
    mt.__namecall = function(self, ...)
        local method = getnamecallmethod()
        
        for _, exception in pairs(exceptions) do
            if type(self) == "Instance" and self.Name == exception then
                return old(self, ...)
            end
        end
        
        if method == "FireServer" or method == "InvokeServer" then
            if type(self) == "Instance" then
                local remoteName = self.Name
                
                if string.find(remoteName:lower(), "hit") or 
                   string.find(remoteName:lower(), "damage") or
                   string.find(remoteName:lower(), "attack") or
                   string.find(remoteName:lower(), "melee") or
                   string.find(remoteName:lower(), "punch") or
                   string.find(remoteName:lower(), "slash") then
                    
                    if not recognizedRemotes[remoteName] then
                        recognizedRemotes[remoteName] = {
                            name = remoteName,
                            hits = 0,
                            firstSeen = tick()
                        }
                        print("🔍 Remote reconocido (pasivo):", remoteName)
                    end
                    
                    recognizedRemotes[remoteName].hits = recognizedRemotes[remoteName].hits + 1
                end
            end
        end
        
        return old(self, ...)
    end
end

-- ==================== UI ====================
local function CreateMainFrame()
    local ScreenGui = player.PlayerGui:FindFirstChild("DamageRepeaterGUI")
    
    if ScreenGui then
        ScreenGui:Destroy()
    end
    
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "DamageRepeaterGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = player.PlayerGui
    
    -- Frame principal
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 240, 0, 180)
    Frame.Position = UDim2.new(0.5, -120, 0.5, -90)
    Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    Frame.BorderSizePixel = 0
    Frame.ClipsDescendants = true
    Frame.Parent = ScreenGui
    Frame.BackgroundTransparency = 0
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = Frame
    
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(255, 255, 255)
    UIStroke.Transparency = 0.2
    UIStroke.Thickness = 1
    UIStroke.Parent = Frame
    
    -- Barra superior
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 35)
    TopBar.Position = UDim2.new(0, 0, 0, 0)
    TopBar.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    TopBar.BorderSizePixel = 0
    TopBar.Parent = Frame
    
    local TopCorner = Instance.new("UICorner")
    TopCorner.CornerRadius = UDim.new(0, 12)
    TopCorner.Parent = TopBar
    
    -- Título
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(0.7, 0, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "⚡ INFINITE REPEATER"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 13
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TopBar
    
    -- Botón cerrar
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 26, 0, 26)
    CloseBtn.Position = UDim2.new(1, -33, 0, 4.5)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 14
    CloseBtn.Parent = TopBar
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 8)
    CloseCorner.Parent = CloseBtn
    
    CloseBtn.MouseButton1Click:Connect(function()
        if damageRepeaterEnabled then
            if mt and old then
                mt.__namecall = old
            end
        end
        ScreenGui:Destroy()
    end)
    
    -- Contenedor
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 1, -35)
    Container.Position = UDim2.new(0, 0, 0, 35)
    Container.BackgroundTransparency = 1
    Container.Parent = Frame
    
    -- Botón toggle
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0.85, 0, 0, 42)
    ToggleBtn.Position = UDim2.new(0.075, 0, 0.12, 0)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    ToggleBtn.Text = "◉  REPEATER: OFF  ◉"
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.TextSize = 13
    ToggleBtn.Parent = Container
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 8)
    ToggleCorner.Parent = ToggleBtn
    
    -- Sección delay
    local DelayFrame = Instance.new("Frame")
    DelayFrame.Size = UDim2.new(1, 0, 0, 45)
    DelayFrame.Position = UDim2.new(0, 0, 0.42, 0)
    DelayFrame.BackgroundTransparency = 1
    DelayFrame.Parent = Container
    
    local DelayLabel = Instance.new("TextLabel")
    DelayLabel.Size = UDim2.new(0.5, 0, 0, 25)
    DelayLabel.Position = UDim2.new(0.05, 0, 0, 0)
    DelayLabel.BackgroundTransparency = 1
    DelayLabel.Text = "⚡ VELOCIDAD (segundos):"
    DelayLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
    DelayLabel.TextSize = 11
    DelayLabel.Font = Enum.Font.GothamBold
    DelayLabel.TextXAlignment = Enum.TextXAlignment.Left
    DelayLabel.Parent = DelayFrame
    
    local DelayInput = Instance.new("TextBox")
    DelayInput.Size = UDim2.new(0.35, 0, 0, 32)
    DelayInput.Position = UDim2.new(0.6, 0, 0, -3)
    DelayInput.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    DelayInput.Text = string.format("%.1f", REPEAT_DELAY)
    DelayInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    DelayInput.Font = Enum.Font.Gotham
    DelayInput.TextSize = 14
    DelayInput.TextXAlignment = Enum.TextXAlignment.Center
    DelayInput.Parent = DelayFrame
    
    local DelayCorner = Instance.new("UICorner")
    DelayCorner.CornerRadius = UDim.new(0, 6)
    DelayCorner.Parent = DelayInput
    
    -- Contador
    local CounterLabel = Instance.new("TextLabel")
    CounterLabel.Size = UDim2.new(0.9, 0, 0, 18)
    CounterLabel.Position = UDim2.new(0.05, 0, 0.7, 0)
    CounterLabel.BackgroundTransparency = 1
    CounterLabel.Text = "📡 Remotes reconocidos: 0"
    CounterLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
    CounterLabel.TextSize = 10
    CounterLabel.Font = Enum.Font.Gotham
    CounterLabel.TextXAlignment = Enum.TextXAlignment.Left
    CounterLabel.Parent = Container
    
    -- Estado
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(0.9, 0, 0, 16)
    StatusLabel.Position = UDim2.new(0.05, 0, 0.82, 0)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "♾️ INFINITO | 0.1s de delay"
    StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
    StatusLabel.TextSize = 9
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Parent = Container
    
    -- Funciones de la UI
    DelayInput.FocusLost:Connect(function()
        local num = tonumber(DelayInput.Text)
        if num and num >= 0.01 and num <= 1.0 then
            REPEAT_DELAY = num
            DelayInput.Text = string.format("%.2f", REPEAT_DELAY)
            if damageRepeaterEnabled then
                StatusLabel.Text = "✅ INFINITO | " .. string.format("%.2f", REPEAT_DELAY) .. "s de delay"
                StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            end
        else
            DelayInput.Text = string.format("%.1f", REPEAT_DELAY)
        end
    end)
    
    -- Hover effects
    ToggleBtn.MouseEnter:Connect(function()
        if not damageRepeaterEnabled then
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
        else
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(55, 95, 55)
        end
    end)
    
    ToggleBtn.MouseLeave:Connect(function()
        if not damageRepeaterEnabled then
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        else
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 85, 45)
        end
    end)
    
    -- Toggle function
    ToggleBtn.MouseButton1Click:Connect(function()
        damageRepeaterEnabled = not damageRepeaterEnabled
        
        if damageRepeaterEnabled then
            ToggleBtn.Text = "◉  REPEATER: ON  ◉"
            ToggleBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 85, 45)
            StatusLabel.Text = "✅ INFINITO | " .. string.format("%.2f", REPEAT_DELAY) .. "s de delay"
            StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            EnableDamageRepeater()
            print("✅ REPEATER ACTIVADO - Repetición infinita cada " .. REPEAT_DELAY .. "s")
        else
            ToggleBtn.Text = "◉  REPEATER: OFF  ◉"
            ToggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            StatusLabel.Text = "⚡ Modo pasivo - Reconociendo remotes"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
            DisableDamageRepeater()
            print("⏹️ REPEATER DESACTIVADO - Modo pasivo")
        end
    end)
    
    -- Actualizar contador
    task.spawn(function()
        while ScreenGui and ScreenGui.Parent do
            task.wait(1)
            local count = 0
            for _ in pairs(recognizedRemotes) do
                count = count + 1
            end
            CounterLabel.Text = "📡 Remotes reconocidos: " .. count
            if count > 0 then
                CounterLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            end
        end
    end)
    
    -- Movimiento de la ventana
    local dragging = false
    local dragStart = nil
    local frameStart = nil
    
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            frameStart = Frame.Position
        end
    end)
    
    TopBar.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            Frame.Position = UDim2.new(frameStart.X.Scale, frameStart.X.Offset + delta.X, frameStart.Y.Scale, frameStart.Y.Offset + delta.Y)
        end
    end)
    
    TopBar.InputEnded:Connect(function()
        dragging = false
    end)
    
    return ScreenGui
end

-- ==================== INICIAR ====================
print("=" .. string.rep("=", 40))
print("⚡ INFINITE DAMAGE REPEATER v4")
print("=" .. string.rep("=", 40))
print("🎯 Cargando interfaz...")

local success, err = pcall(function()
    SetupHook()
    CreateMainFrame()
end)

if success then
    print("✅ Interfaz creada exitosamente")
    print("💡 Activa el repetidor desde la interfaz")
    print("⚡ Velocidad configurable (0.01s - 1.0s)")
    print("♾️ Repetición INFINITA sin congelamiento")
else
    warn("❌ Error al cargar: " .. tostring(err))
    print("💡 Asegúrate de ejecutar esto en un ejecutor compatible")
end
