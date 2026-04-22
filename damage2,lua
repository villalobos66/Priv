local REPEAT_AMOUNT = 26  -- Número de veces que repetirá cada daño

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

-- Variables para UI y sistema de proximidad
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local damageRepeaterEnabled = false
local proximityDamageEnabled = false
local proximityRadius = 15 -- Radio en studs para detectar enemigos
local enemiesInRange = {}
local currentTarget = nil

-- ==================== UI MEJORADA Y ORDENADA ====================
local function CreateMainFrame()
    local ScreenGui = player.PlayerGui:FindFirstChild("DamageRepeaterGUI") 
        or Instance.new("ScreenGui")
    ScreenGui.Name = "DamageRepeaterGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = player.PlayerGui
    
    -- Frame principal (más grande para más opciones)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 240, 0, 200)
    Frame.Position = UDim2.new(0.5, -120, 0.5, -100)
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
    Title.Text = "⚡ PROXIMITY DAMAGE"
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
        if proximityDamageEnabled then
            proximityDamageEnabled = false
        end
        Frame:Destroy()
    end)
    
    -- Contenedor principal de contenido
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 1, -32)
    Container.Position = UDim2.new(0, 0, 0, 32)
    Container.BackgroundTransparency = 1
    Container.Parent = Frame
    
    -- Botón principal: Modo Proximidad
    local ProximityBtn = Instance.new("TextButton")
    ProximityBtn.Size = UDim2.new(0.8, 0, 0, 40)
    ProximityBtn.Position = UDim2.new(0.1, 0, 0.05, 0)
    ProximityBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    ProximityBtn.Text = "🔘 PROXIMITY: OFF 🔘"
    ProximityBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
    ProximityBtn.Font = Enum.Font.GothamBold
    ProximityBtn.TextSize = 12
    ProximityBtn.Parent = Container
    
    local ProxCorner = Instance.new("UICorner")
    ProxCorner.CornerRadius = UDim.new(0, 8)
    ProxCorner.Parent = ProximityBtn
    
    -- Botón secundario: Modo Golpes (opcional)
    local HitRepeaterBtn = Instance.new("TextButton")
    HitRepeaterBtn.Size = UDim2.new(0.8, 0, 0, 35)
    HitRepeaterBtn.Position = UDim2.new(0.1, 0, 0.28, 0)
    HitRepeaterBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    HitRepeaterBtn.Text = "👊 HIT REPEATER: OFF 👊"
    HitRepeaterBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    HitRepeaterBtn.Font = Enum.Font.Gotham
    HitRepeaterBtn.TextSize = 11
    HitRepeaterBtn.Parent = Container
    
    local HitCorner = Instance.new("UICorner")
    HitCorner.CornerRadius = UDim.new(0, 8)
    HitCorner.Parent = HitRepeaterBtn
    
    -- Sección de configuración
    local ConfigSection = Instance.new("Frame")
    ConfigSection.Size = UDim2.new(1, 0, 0, 70)
    ConfigSection.Position = UDim2.new(0, 0, 0.55, 0)
    ConfigSection.BackgroundTransparency = 1
    ConfigSection.Parent = Container
    
    -- Radio de proximidad
    local RadiusLabel = Instance.new("TextLabel")
    RadiusLabel.Size = UDim2.new(0.45, 0, 0, 25)
    RadiusLabel.Position = UDim2.new(0.05, 0, 0, 0)
    RadiusLabel.BackgroundTransparency = 1
    RadiusLabel.Text = "📡 RADIO (studs):"
    RadiusLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
    RadiusLabel.TextSize = 11
    RadiusLabel.Font = Enum.Font.GothamBold
    RadiusLabel.TextXAlignment = Enum.TextXAlignment.Left
    RadiusLabel.Parent = ConfigSection
    
    local RadiusInput = Instance.new("TextBox")
    RadiusInput.Size = UDim2.new(0.35, 0, 0, 32)
    RadiusInput.Position = UDim2.new(0.6, 0, 0, -3)
    RadiusInput.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    RadiusInput.Text = tostring(proximityRadius)
    RadiusInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    RadiusInput.Font = Enum.Font.Gotham
    RadiusInput.TextSize = 14
    RadiusInput.TextXAlignment = Enum.TextXAlignment.Center
    RadiusInput.Parent = ConfigSection
    
    local RadiusCorner = Instance.new("UICorner")
    RadiusCorner.CornerRadius = UDim.new(0, 6)
    RadiusCorner.Parent = RadiusInput
    
    -- Repeticiones
    local RepeatLabel = Instance.new("TextLabel")
    RepeatLabel.Size = UDim2.new(0.45, 0, 0, 25)
    RepeatLabel.Position = UDim2.new(0.05, 0, 0.45, 0)
    RepeatLabel.BackgroundTransparency = 1
    RepeatLabel.Text = "🔄 DAÑO POR VEZ:"
    RepeatLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
    RepeatLabel.TextSize = 11
    RepeatLabel.Font = Enum.Font.GothamBold
    RepeatLabel.TextXAlignment = Enum.TextXAlignment.Left
    RepeatLabel.Parent = ConfigSection
    
    local RepeatInput = Instance.new("TextBox")
    RepeatInput.Size = UDim2.new(0.35, 0, 0, 32)
    RepeatInput.Position = UDim2.new(0.6, 0, 0.42, 0)
    RepeatInput.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    RepeatInput.Text = tostring(REPEAT_AMOUNT)
    RepeatInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    RepeatInput.Font = Enum.Font.Gotham
    RepeatInput.TextSize = 14
    RepeatInput.TextXAlignment = Enum.TextXAlignment.Center
    RepeatInput.Parent = ConfigSection
    
    local RepeatCorner = Instance.new("UICorner")
    RepeatCorner.CornerRadius = UDim.new(0, 6)
    RepeatCorner.Parent = RepeatInput
    
    -- Estado actual
    local StatusText = Instance.new("TextLabel")
    StatusText.Size = UDim2.new(1, 0, 0, 30)
    StatusText.Position = UDim2.new(0, 0, 0.85, 0)
    StatusText.BackgroundTransparency = 1
    StatusText.Text = "⚡ Daño automático al acercarte"
    StatusText.TextColor3 = Color3.fromRGB(100, 100, 110)
    StatusText.TextSize = 9
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
    
    return ProximityBtn, HitRepeaterBtn, RadiusInput, RepeatInput, StatusText
end

-- ==================== SISTEMA DE PROXIMIDAD ====================
local function FindEnemiesInRange()
    enemiesInRange = {}
    local rootPos = humanoidRootPart.Position
    
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            local otherChar = otherPlayer.Character
            if otherChar and otherChar:FindFirstChild("HumanoidRootPart") and otherChar:FindFirstChild("Humanoid") then
                local otherRoot = otherChar.HumanoidRootPart
                local distance = (rootPos - otherRoot.Position).Magnitude
                
                if distance <= proximityRadius then
                    table.insert(enemiesInRange, otherPlayer)
                end
            end
        end
    end
end

local function DealDamageToTarget(target)
    if not target or not target.Character then return end
    
    -- Buscar eventos remotos de daño (común en muchos juegos)
    local remoteEvents = {
        game:GetService("ReplicatedStorage"):FindFirstChild("Damage"),
        game:GetService("ReplicatedStorage"):FindFirstChild("DealDamage"),
        game:GetService("ReplicatedStorage"):FindFirstChild("Attack"),
        game:GetService("ReplicatedStorage"):FindFirstChild("Hit"),
        game:GetService("ReplicatedStorage"):FindFirstChild("RemoteEvent"),
    }
    
    for _, remote in pairs(remoteEvents) do
        if remote and remote:IsA("RemoteEvent") then
            for i = 1, REPEAT_AMOUNT do
                remote:FireServer(target.Character.HumanoidRootPart, target.Character.Humanoid)
                remote:FireServer(target.Character)
                remote:FireServer(target)
                remote:FireServer(target.Character.HumanoidRootPart.Position)
            end
        elseif remote and remote:IsA("RemoteFunction") then
            for i = 1, REPEAT_AMOUNT do
                remote:InvokeServer(target.Character.HumanoidRootPart, target.Character.Humanoid)
            end
        end
    end
    
    -- Método alternativo: buscar en el jugador
    local playerRemote = target:FindFirstChild("RemoteEvent") or target:FindFirstChild("DamageRemote")
    if playerRemote then
        for i = 1, REPEAT_AMOUNT do
            playerRemote:FireServer(target.Character.Humanoid)
        end
    end
end

local function ProximityDamageLoop()
    while proximityDamageEnabled and RunService.RenderStepped:Wait() do
        FindEnemiesInRange()
        
        for _, enemy in pairs(enemiesInRange) do
            DealDamageToTarget(enemy)
        end
        
        -- Actualizar UI con contador de enemigos
        local statusText = game.Players.LocalPlayer.PlayerGui.DamageRepeaterGUI:FindFirstChild("Frame")
        if statusText then
            local container = statusText:FindFirstChild("Container")
            if container then
                local status = container:FindFirstChildWhichIsA("TextLabel")
                if status and status.Text:find("📡") then
                    status.Text = "📡 Enemigos cerca: " .. #enemiesInRange .. " | Daño x" .. REPEAT_AMOUNT
                end
            end
        end
    end
end

-- ==================== FUNCIÓN GOLPES (REPEATER TRADICIONAL) ====================
local hitRepeaterEnabled = false

local function EnableHitRepeater()
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
                
                for i = 1, REPEAT_AMOUNT do
                    old(self, ...)
                end
            end
        end
        
        return old(self, ...)
    end
end

local function DisableHitRepeater()
    mt.__namecall = old
end

-- ==================== INICIALIZAR ====================
local ProximityBtn, HitRepeaterBtn, RadiusInput, RepeatInput, StatusText = CreateMainFrame()

-- Actualizar valores de inputs
RadiusInput.FocusLost:Connect(function()
    local num = tonumber(RadiusInput.Text)
    if num and num >= 5 and num <= 50 then
        proximityRadius = num
        RadiusInput.Text = tostring(proximityRadius)
    else
        RadiusInput.Text = tostring(proximityRadius)
    end
end)

RepeatInput.FocusLost:Connect(function()
    local num = tonumber(RepeatInput.Text)
    if num and num >= 1 and num <= 100 then
        REPEAT_AMOUNT = math.floor(num)
        RepeatInput.Text = tostring(REPEAT_AMOUNT)
    else
        RepeatInput.Text = tostring(REPEAT_AMOUNT)
    end
end)

-- Botón de proximidad
ProximityBtn.MouseButton1Click:Connect(function()
    proximityDamageEnabled = not proximityDamageEnabled
    
    if proximityDamageEnabled then
        ProximityBtn.Text = "🔘 PROXIMITY: ON 🔘"
        ProximityBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
        ProximityBtn.BackgroundColor3 = Color3.fromRGB(45, 85, 45)
        StatusText.Text = "✅ ACTIVADO - Daño automático en radio " .. proximityRadius .. " studs"
        StatusText.TextColor3 = Color3.fromRGB(100, 200, 100)
        
        -- Iniciar loop
        coroutine.wrap(ProximityDamageLoop)()
    else
        ProximityBtn.Text = "🔘 PROXIMITY: OFF 🔘"
        ProximityBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
        ProximityBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        StatusText.Text = "⚡ Modo desactivado - Actívalo para daño automático"
        StatusText.TextColor3 = Color3.fromRGB(100, 100, 110)
    end
end)

-- Botón de hit repeater
HitRepeaterBtn.MouseButton1Click:Connect(function()
    hitRepeaterEnabled = not hitRepeaterEnabled
    
    if hitRepeaterEnabled then
        HitRepeaterBtn.Text = "👊 HIT REPEATER: ON 👊"
        HitRepeaterBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
        HitRepeaterBtn.BackgroundColor3 = Color3.fromRGB(45, 65, 45)
        EnableHitRepeater()
        StatusText.Text = "✅ HIT REPEATER activado - Repite golpes " .. REPEAT_AMOUNT .. "x"
    else
        HitRepeaterBtn.Text = "👊 HIT REPEATER: OFF 👊"
        HitRepeaterBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        HitRepeaterBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        DisableHitRepeater()
        if not proximityDamageEnabled then
            StatusText.Text = "⚡ Activa PROXIMITY o HIT REPEATER"
        end
    end
end)

print("✅ Proximity Damage System cargado - Daño automático por cercanía")
