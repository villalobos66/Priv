local REPEAT_AMOUNT = 26  -- Veces que repetirá cada golpe por tick
local KillAuraEnabled = false
local AutoDamageEnabled = false  -- Nuevo modo: daño automático puro

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- Encuentra el HitRemote automáticamente
local HitRemote = nil
local function FindHitRemote()
    -- Buscar en ReplicatedStorage
    for _, obj in pairs(game:GetService("ReplicatedStorage"):GetChildren()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            if obj.Name:lower():find("hit") or obj.Name:lower():find("damage") or obj.Name:lower():find("attack") then
                HitRemote = obj
                print("✅ HitRemote encontrado:", obj.Name)
                return
            end
        end
    end
    
    -- Buscar en Workspace
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            if obj.Name:lower():find("hit") or obj.Name:lower():find("damage") or obj.Name:lower():find("attack") then
                HitRemote = obj
                print("✅ HitRemote encontrado:", obj.Name)
                return
            end
        end
    end
    
    -- Buscar en el jugador
    for _, obj in pairs(player:GetChildren()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            if obj.Name:lower():find("hit") or obj.Name:lower():find("damage") or obj.Name:lower():find("attack") then
                HitRemote = obj
                print("✅ HitRemote encontrado:", obj.Name)
                return
            end
        end
    end
    
    print("❌ No se encontró HitRemote - Usa el nombre correcto")
end

FindHitRemote()

-- ==================== SISTEMA DE DAÑO AUTOMÁTICO ====================
local function DealDamageToTarget(target)
    if not target or not target.Character then return false end
    
    local hum = target.Character:FindFirstChild("Humanoid")
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    
    if not hum or hum.Health <= 0 then return false end
    if not hrp or not myHRP then return false end
    
    if not HitRemote then
        FindHitRemote()
        if not HitRemote then return false end
    end
    
    -- Preparar argumentos (como en tu script original)
    local args = {
        hum,  -- El humanoid del enemigo
        vector.new(myHRP.Position.X, myHRP.Position.Y, myHRP.Position.Z)  -- Posición del jugador
    }
    
    local success = false
    
    -- Aplicar daño múltiples veces
    for i = 1, REPEAT_AMOUNT do
        pcall(function()
            if HitRemote:IsA("RemoteFunction") then
                HitRemote:InvokeServer(unpack(args))
            else
                HitRemote:FireServer(unpack(args))
            end
            success = true
        end)
    end
    
    return success
end

-- Loop principal de daño automático (SIN NECESIDAD DE GOLPEAR)
local autoDamageConnection = nil

local function StartAutoDamage()
    if autoDamageConnection then return end
    
    autoDamageConnection = RunService.Heartbeat:Connect(function()
        if not AutoDamageEnabled then return end
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
        
        local myHRP = player.Character.HumanoidRootPart
        local maxRange = 15  -- Radio de daño automático (studs)
        
        -- Buscar todos los enemigos en rango
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("Humanoid") then
                local hum = p.Character.Humanoid
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                
                if hum.Health > 0 and hrp then
                    local dist = (hrp.Position - myHRP.Position).Magnitude
                    
                    -- Si está en rango, hacer daño AUTOMÁTICAMENTE
                    if dist <= maxRange then
                        DealDamageToTarget(p)
                    end
                end
            end
        end
    end)
end

local function StopAutoDamage()
    if autoDamageConnection then
        autoDamageConnection:Disconnect()
        autoDamageConnection = nil
    end
end

-- ==================== UI MEJORADA ====================
local function CreateUI()
    local ScreenGui = player.PlayerGui:FindFirstChild("AutoDamageGUI") 
        or Instance.new("ScreenGui")
    ScreenGui.Name = "AutoDamageGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = player.PlayerGui
    
    -- Frame principal
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 220, 0, 160)
    Frame.Position = UDim2.new(0.5, -110, 0.5, -80)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
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
    TopBar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    TopBar.BorderSizePixel = 0
    TopBar.Parent = Frame
    
    local TopCorner = Instance.new("UICorner")
    TopCorner.CornerRadius = UDim.new(0, 10)
    TopCorner.Parent = TopBar
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(0.7, 0, 1, 0)
    Title.Position = UDim2.new(0, 12, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "⚡ AUTO DAMAGE ⚡"
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
        AutoDamageEnabled = false
        StopAutoDamage()
        Frame:Destroy()
    end)
    
    -- Contenedor
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 1, -32)
    Container.Position = UDim2.new(0, 0, 0, 32)
    Container.BackgroundTransparency = 1
    Container.Parent = Frame
    
    -- Botón principal
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0.8, 0, 0, 45)
    ToggleBtn.Position = UDim2.new(0.1, 0, 0.1, 0)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    ToggleBtn.Text = "🔴 AUTO DAMAGE: OFF"
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.TextSize = 12
    ToggleBtn.Parent = Container
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 8)
    BtnCorner.Parent = ToggleBtn
    
    -- Configuración de repeticiones
    local RepeatLabel = Instance.new("TextLabel")
    RepeatLabel.Size = UDim2.new(0.45, 0, 0, 25)
    RepeatLabel.Position = UDim2.new(0.05, 0, 0.45, 0)
    RepeatLabel.BackgroundTransparency = 1
    RepeatLabel.Text = "🔄 DAÑO POR TICK:"
    RepeatLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
    RepeatLabel.TextSize = 11
    RepeatLabel.Font = Enum.Font.GothamBold
    RepeatLabel.TextXAlignment = Enum.TextXAlignment.Left
    RepeatLabel.Parent = Container
    
    local RepeatInput = Instance.new("TextBox")
    RepeatInput.Size = UDim2.new(0.35, 0, 0, 32)
    RepeatInput.Position = UDim2.new(0.6, 0, 0.42, 0)
    RepeatInput.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    RepeatInput.Text = tostring(REPEAT_AMOUNT)
    RepeatInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    RepeatInput.Font = Enum.Font.Gotham
    RepeatInput.TextSize = 14
    RepeatInput.TextXAlignment = Enum.TextXAlignment.Center
    RepeatInput.Parent = Container
    
    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 6)
    InputCorner.Parent = RepeatInput
    
    RepeatInput.FocusLost:Connect(function()
        local num = tonumber(RepeatInput.Text)
        if num and num >= 1 and num <= 100 then
            REPEAT_AMOUNT = math.floor(num)
            RepeatInput.Text = tostring(REPEAT_AMOUNT)
        else
            RepeatInput.Text = tostring(REPEAT_AMOUNT)
        end
    end)
    
    -- Estado actual
    local StatusText = Instance.new("TextLabel")
    StatusText.Size = UDim2.new(1, 0, 0, 30)
    StatusText.Position = UDim2.new(0, 0, 0.75, 0)
    StatusText.BackgroundTransparency = 1
    StatusText.Text = "⚡ Daño automático al acercarte"
    StatusText.TextColor3 = Color3.fromRGB(100, 100, 110)
    StatusText.TextSize = 9
    StatusText.Font = Enum.Font.Gotham
    StatusText.Parent = Container
    
    -- Movimiento de la UI
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
    
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStartMousePos = input.Position
            dragStartFramePos = Frame.Position
        end
    end)
    
    TopBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            UpdateFramePosition(input.Position)
        end
    end)
    
    -- Acción del botón
    ToggleBtn.MouseButton1Click:Connect(function()
        AutoDamageEnabled = not AutoDamageEnabled
        
        if AutoDamageEnabled then
            ToggleBtn.Text = "🟢 AUTO DAMAGE: ON"
            ToggleBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 90, 50)
            StatusText.Text = "✅ ACTIVADO - Dañando automáticamente (radio 15 studs)"
            StatusText.TextColor3 = Color3.fromRGB(100, 200, 100)
            StartAutoDamage()
            print("✅ Auto Damage ACTIVADO - Haciendo daño x" .. REPEAT_AMOUNT)
        else
            ToggleBtn.Text = "🔴 AUTO DAMAGE: OFF"
            ToggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            StatusText.Text = "⚡ Daño automático al acercarte"
            StatusText.TextColor3 = Color3.fromRGB(100, 100, 110)
            StopAutoDamage()
            print("❌ Auto Damage DESACTIVADO")
        end
    end)
    
    return ToggleBtn
end

-- Iniciar UI
CreateUI()
print("✅ Auto Damage System CARGADO - Hace daño automáticamente sin golpear")
