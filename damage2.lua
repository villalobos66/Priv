-- ==================== INTERFAZ UNIVERSAL ====================
-- Funciona en la mayoría de los juegos (Blox Fruits, King Legacy, etc)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- ==================== CONFIGURACIÓN ====================
local settings = {
    enabled = false,
    mode = "MultiHit",  -- MultiHit, AutoDamage, Range
    multiplier = 10,
    radius = 15,
    delay = 0.3,
    hitChance = 100,  -- Porcentaje de acierto (100 = siempre)
}

-- ==================== DETECTAR REMOTE AUTOMÁTICAMENTE ====================
local HitRemote = nil

local function FindHitRemote()
    local possiblePaths = {
        -- Paths comunes
        game:GetService("ReplicatedStorage"):FindFirstChild("Packages"),
        game:GetService("ReplicatedStorage"):FindFirstChild("Knit"),
        game:GetService("ReplicatedStorage"):FindFirstChild("Combat"),
        game:GetService("ReplicatedStorage"):FindFirstChild("Damage"),
        game:GetService("ReplicatedStorage"):FindFirstChild("Attack"),
        game:GetService("ReplicatedStorage"):FindFirstChild("Hit"),
        game:GetService("ReplicatedStorage"):FindFirstChild("Remote"),
        game:GetService("ReplicatedStorage"):FindFirstChild("Events"),
        
        -- Nombres comunes
        game:GetService("ReplicatedStorage"):FindFirstChild("HitRemote"),
        game:GetService("ReplicatedStorage"):FindFirstChild("DamageRemote"),
        game:GetService("ReplicatedStorage"):FindFirstChild("AttackRemote"),
        game:GetService("ReplicatedStorage"):FindFirstChild("CombatRemote"),
    }
    
    -- Buscar en paths anidados
    for _, path in pairs(possiblePaths) do
        if path then
            if path:IsA("RemoteEvent") or path:IsA("RemoteFunction") then
                HitRemote = path
                return HitRemote
            end
            
            -- Buscar dentro del path
            for _, child in pairs(path:GetChildren()) do
                if child.Name:lower():find("hit") or child.Name:lower():find("damage") or child.Name:lower():find("attack") then
                    if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                        HitRemote = child
                        return HitRemote
                    end
                end
            end
        end
    end
    
    -- Buscar en todo ReplicatedStorage
    for _, obj in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local name = obj.Name:lower()
            if name:find("hit") or name:find("damage") or name:find("attack") or name:find("combat") then
                HitRemote = obj
                return HitRemote
            end
        end
    end
    
    return nil
end

-- ==================== HOOK DEL REMOTE ====================
local originalInvoke = nil
local hooked = false

local function HookRemote()
    if not HitRemote then return false end
    if hooked then return true end
    
    if HitRemote:IsA("RemoteFunction") then
        originalInvoke = HitRemote.InvokeServer
        HitRemote.InvokeServer = function(self, ...)
            if settings.enabled and settings.mode == "MultiHit" then
                local args = {...}
                for i = 1, settings.multiplier do
                    originalInvoke(self, unpack(args))
                end
            end
            return originalInvoke(self, ...)
        end
        hooked = true
        return true
    elseif HitRemote:IsA("RemoteEvent") then
        originalInvoke = HitRemote.FireServer
        HitRemote.FireServer = function(self, ...)
            if settings.enabled and settings.mode == "MultiHit" then
                local args = {...}
                for i = 1, settings.multiplier do
                    originalInvoke(self, unpack(args))
                end
            end
            return originalInvoke(self, ...)
        end
        hooked = true
        return true
    end
    
    return false
end

-- ==================== AUTO DAMAGE (SIN GOLPEAR) ====================
local autoDamageConnection = nil
local lastDamage = {}

local function DealAutoDamage(target)
    if not HitRemote then return end
    if not target or not target.Character then return end
    
    local hum = target.Character:FindFirstChild("Humanoid")
    local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    
    if not hum or hum.Health <= 0 then return end
    if not myHRP then return end
    
    -- Randomizar éxito
    if math.random(1, 100) > settings.hitChance then return end
    
    local args = {hum, myHRP.Position}
    
    pcall(function()
        if HitRemote:IsA("RemoteFunction") then
            HitRemote:InvokeServer(unpack(args))
        else
            HitRemote:FireServer(unpack(args))
        end
    end)
end

local function StartAutoDamage()
    if autoDamageConnection then return end
    
    autoDamageConnection = RunService.Heartbeat:Connect(function()
        if not settings.enabled or settings.mode ~= "AutoDamage" then return end
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
        
        local myHRP = player.Character.HumanoidRootPart
        
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                local hum = p.Character:FindFirstChild("Humanoid")
                
                if hum and hum.Health > 0 and hrp then
                    local dist = (hrp.Position - myHRP.Position).Magnitude
                    
                    if dist <= settings.radius then
                        local now = tick()
                        if not lastDamage[p] or now - lastDamage[p] > settings.delay then
                            lastDamage[p] = now
                            DealAutoDamage(p)
                        end
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

-- ==================== INTERFAZ UNIVERSAL ====================
local function CreateUniversalUI()
    -- Esperar a que PlayerGui exista
    local playerGui = player:WaitForChild("PlayerGui")
    
    local ScreenGui = playerGui:FindFirstChild("UniversalGUI") or Instance.new("ScreenGui")
    ScreenGui.Name = "UniversalGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = playerGui
    
    -- Frame principal
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 260, 0, 280)
    Frame.Position = UDim2.new(0.5, -130, 0.5, -140)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    Frame.BackgroundTransparency = 0.05
    Frame.BorderSizePixel = 0
    Frame.ClipsDescendants = true
    Frame.Parent = ScreenGui
    
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
    TopBar.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    TopBar.BorderSizePixel = 0
    TopBar.Parent = Frame
    
    local TopCorner = Instance.new("UICorner")
    TopCorner.CornerRadius = UDim.new(0, 12)
    TopCorner.Parent = TopBar
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(0.7, 0, 1, 0)
    Title.Position = UDim2.new(0, 12, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "⚡ UNIVERSAL DAMAGE ⚡"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 11
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TopBar
    
    -- Botón cerrar
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 26, 0, 26)
    CloseBtn.Position = UDim2.new(1, -32, 0, 4)
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
        settings.enabled = false
        StopAutoDamage()
        Frame:Destroy()
    end)
    
    -- Contenedor
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 1, -35)
    Container.Position = UDim2.new(0, 0, 0, 35)
    Container.BackgroundTransparency = 1
    Container.Parent = Frame
    
    -- Botón principal ON/OFF
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0.85, 0, 0, 40)
    ToggleBtn.Position = UDim2.new(0.075, 0, 0.05, 0)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    ToggleBtn.Text = "🔴 REPEATER: OFF"
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.TextSize = 12
    ToggleBtn.Parent = Container
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 8)
    ToggleCorner.Parent = ToggleBtn
    
    -- Selector de modo
    local ModeLabel = Instance.new("TextLabel")
    ModeLabel.Size = UDim2.new(0.4, 0, 0, 20)
    ModeLabel.Position = UDim2.new(0.05, 0, 0.22, 0)
    ModeLabel.BackgroundTransparency = 1
    ModeLabel.Text = "📁 MODO:"
    ModeLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
    ModeLabel.TextSize = 11
    ModeLabel.Font = Enum.Font.GothamBold
    ModeLabel.TextXAlignment = Enum.TextXAlignment.Left
    ModeLabel.Parent = Container
    
    local ModeDropdown = Instance.new("TextButton")
    ModeDropdown.Size = UDim2.new(0.45, 0, 0, 28)
    ModeDropdown.Position = UDim2.new(0.5, 0, 0.2, 0)
    ModeDropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    ModeDropdown.Text = "MultiHit"
    ModeDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
    ModeDropdown.Font = Enum.Font.Gotham
    ModeDropdown.TextSize = 11
    ModeDropdown.Parent = Container
    
    local ModeCorner = Instance.new("UICorner")
    ModeCorner.CornerRadius = UDim.new(0, 6)
    ModeCorner.Parent = ModeDropdown
    
    local modes = {"MultiHit", "AutoDamage"}
    local modeIndex = 1
    
    ModeDropdown.MouseButton1Click:Connect(function()
        modeIndex = modeIndex % #modes + 1
        settings.mode = modes[modeIndex]
        ModeDropdown.Text = settings.mode
        
        if settings.enabled then
            if settings.mode == "AutoDamage" then
                StartAutoDamage()
            else
                StopAutoDamage()
            end
        end
    end)
    
    -- Multiplicador (solo para MultiHit)
    local MultiLabel = Instance.new("TextLabel")
    MultiLabel.Size = UDim2.new(0.4, 0, 0, 20)
    MultiLabel.Position = UDim2.new(0.05, 0, 0.38, 0)
    MultiLabel.BackgroundTransparency = 1
    MultiLabel.Text = "🔁 MULTIPLICADOR:"
    MultiLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
    MultiLabel.TextSize = 11
    MultiLabel.Font = Enum.Font.GothamBold
    MultiLabel.TextXAlignment = Enum.TextXAlignment.Left
    MultiLabel.Parent = Container
    
    local MultiInput = Instance.new("TextBox")
    MultiInput.Size = UDim2.new(0.35, 0, 0, 28)
    MultiInput.Position = UDim2.new(0.6, 0, 0.36, 0)
    MultiInput.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    MultiInput.Text = tostring(settings.multiplier)
    MultiInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    MultiInput.Font = Enum.Font.Gotham
    MultiInput.TextSize = 12
    MultiInput.TextXAlignment = Enum.TextXAlignment.Center
    MultiInput.Parent = Container
    
    local MultiCorner = Instance.new("UICorner")
    MultiCorner.CornerRadius = UDim.new(0, 6)
    MultiCorner.Parent = MultiInput
    
    MultiInput.FocusLost:Connect(function()
        local num = tonumber(MultiInput.Text)
        if num and num >= 1 and num <= 50 then
            settings.multiplier = math.floor(num)
            MultiInput.Text = tostring(settings.multiplier)
        else
            MultiInput.Text = tostring(settings.multiplier)
        end
    end)
    
    -- Radio (solo para AutoDamage)
    local RadiusLabel = Instance.new("TextLabel")
    RadiusLabel.Size = UDim2.new(0.4, 0, 0, 20)
    RadiusLabel.Position = UDim2.new(0.05, 0, 0.54, 0)
    RadiusLabel.BackgroundTransparency = 1
    RadiusLabel.Text = "📡 RADIO (studs):"
    RadiusLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
    RadiusLabel.TextSize = 11
    RadiusLabel.Font = Enum.Font.GothamBold
    RadiusLabel.TextXAlignment = Enum.TextXAlignment.Left
    RadiusLabel.Parent = Container
    
    local RadiusInput = Instance.new("TextBox")
    RadiusInput.Size = UDim2.new(0.35, 0, 0, 28)
    RadiusInput.Position = UDim2.new(0.6, 0, 0.52, 0)
    RadiusInput.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    RadiusInput.Text = tostring(settings.radius)
    RadiusInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    RadiusInput.Font = Enum.Font.Gotham
    RadiusInput.TextSize = 12
    RadiusInput.TextXAlignment = Enum.TextXAlignment.Center
    RadiusInput.Parent = Container
    
    local RadiusCorner = Instance.new("UICorner")
    RadiusCorner.CornerRadius = UDim.new(0, 6)
    RadiusCorner.Parent = RadiusInput
    
    RadiusInput.FocusLost:Connect(function()
        local num = tonumber(RadiusInput.Text)
        if num and num >= 5 and num <= 50 then
            settings.radius = math.floor(num)
            RadiusInput.Text = tostring(settings.radius)
        else
            RadiusInput.Text = tostring(settings.radius)
        end
    end)
    
    -- Delay
    local DelayLabel = Instance.new("TextLabel")
    DelayLabel.Size = UDim2.new(0.4, 0, 0, 20)
    DelayLabel.Position = UDim2.new(0.05, 0, 0.7, 0)
    DelayLabel.BackgroundTransparency = 1
    DelayLabel.Text = "⏱ DELAY (seg):"
    DelayLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
    DelayLabel.TextSize = 11
    DelayLabel.Font = Enum.Font.GothamBold
    DelayLabel.TextXAlignment = Enum.TextXAlignment.Left
    DelayLabel.Parent = Container
    
    local DelayInput = Instance.new("TextBox")
    DelayInput.Size = UDim2.new(0.35, 0, 0, 28)
    DelayInput.Position = UDim2.new(0.6, 0, 0.68, 0)
    DelayInput.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    DelayInput.Text = tostring(settings.delay)
    DelayInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    DelayInput.Font = Enum.Font.Gotham
    DelayInput.TextSize = 12
    DelayInput.TextXAlignment = Enum.TextXAlignment.Center
    DelayInput.Parent = Container
    
    local DelayCorner = Instance.new("UICorner")
    DelayCorner.CornerRadius = UDim.new(0, 6)
    DelayCorner.Parent = DelayInput
    
    DelayInput.FocusLost:Connect(function()
        local num = tonumber(DelayInput.Text)
        if num and num >= 0.05 and num <= 2 then
            settings.delay = num
            DelayInput.Text = tostring(settings.delay)
        else
            DelayInput.Text = tostring(settings.delay)
        end
    end)
    
    -- Estado
    local StatusText = Instance.new("TextLabel")
    StatusText.Size = UDim2.new(0.95, 0, 0, 25)
    StatusText.Position = UDim2.new(0.025, 0, 0.88, 0)
    StatusText.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    StatusText.BackgroundTransparency = 0.5
    StatusText.Text = "⚡ Esperando..."
    StatusText.TextColor3 = Color3.fromRGB(150, 150, 160)
    StatusText.TextSize = 9
    StatusText.Font = Enum.Font.Gotham
    StatusText.Parent = Container
    
    local StatusCorner = Instance.new("UICorner")
    StatusCorner.CornerRadius = UDim.new(0, 6)
    StatusCorner.Parent = StatusText
    
    -- Movimiento de UI
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
    
    TopBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            Frame.Position = UDim2.new(frameStart.X.Scale, frameStart.X.Offset + delta.X, frameStart.Y.Scale, frameStart.Y.Offset + delta.Y)
        end
    end)
    
    -- Acción del botón principal
    ToggleBtn.MouseButton1Click:Connect(function()
        settings.enabled = not settings.enabled
        
        if settings.enabled then
            ToggleBtn.Text = "🟢 REPEATER: ON"
            ToggleBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 90, 50)
            
            if settings.mode == "MultiHit" then
                HookRemote()
                StatusText.Text = "✅ MultiHit activado - x" .. settings.multiplier
                StatusText.TextColor3 = Color3.fromRGB(100, 255, 100)
                if autoDamageConnection then StopAutoDamage() end
            else
                StartAutoDamage()
                StatusText.Text = "✅ AutoDamage activado - Radio " .. settings.radius .. " studs"
                StatusText.TextColor3 = Color3.fromRGB(100, 255, 100)
            end
        else
            ToggleBtn.Text = "🔴 REPEATER: OFF"
            ToggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
            StatusText.Text = "❌ Desactivado"
            StatusText.TextColor3 = Color3.fromRGB(200, 80, 80)
            StopAutoDamage()
            
            if hooked then
                if HitRemote and HitRemote:IsA("RemoteFunction") then
                    HitRemote.InvokeServer = originalInvoke
                elseif HitRemote and HitRemote:IsA("RemoteEvent") then
                    HitRemote.FireServer = originalInvoke
                end
                hooked = false
            end
        end
    end)
    
    return ToggleBtn
end

-- ==================== INICIAR ====================
-- Detectar remote automáticamente
FindHitRemote()

if HitRemote then
    print("✅ Remote encontrado:", HitRemote.Name)
    print("📁 Tipo:", HitRemote.ClassName)
else
    print("⚠️ No se encontró remote automáticamente")
    print("💡 Puedes especificarlo manualmente")
end

-- Crear UI
CreateUniversalUI()
print("✅ Interfaz Universal cargada")
print("📌 Modos: MultiHit (multiplica golpes) | AutoDamage (daño automático)")
