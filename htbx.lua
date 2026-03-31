local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- Variables principales
local HitboxEnabled = false
local AntiRagdollEnabled = false
local targetPlayer = nil
local exactTargetName = ""

-- Configuración fija del hitbox
local HITBOX_SIZE = 30
local HITBOX_TRANSPARENCY = 1

-- Variables para WalkSpeed
local WalkSpeedEnabled = false
local WalkSpeedValue = 16
local loopWalkSpeedConnection = nil

-- Variables para TP Walk
local TPWalkEnabled = false
local TPSpeedValue = 3
local tpWalkConnection = nil

-- ==================== DAMAGE REPEATER ====================
local REPEAT_AMOUNT = 26
local damageRepeaterEnabled = false
local mt = nil
local old = nil

-- Excepciones - eventos que NO se repetirán
local exceptions = {
    "SayMessageRequest",
    "MeleeUpdateEvent", 
    "NinjaBombEvent",
    "BulletUpdateEvent"
}

-- Variables para referencias de UI
local walkSpeedBtn = nil
local walkSpeedValueLabel = nil
local tpSpeedValueLabel = nil
local hitboxSizeLabel = nil
local hitboxTransparencyLabel = nil
local targetStatus = nil
local searchResult = nil
local targetBox = nil
local clearTargetBtn = nil
local closestBtn = nil
local configFrame = nil
local configScreenGui = nil
local repeatInput = nil
local repeatStatusLabel = nil

-- Variables para la interfaz de botones
local buttonsFrame = nil
local buttonsScreenGui = nil
local hitboxBtn = nil
local tpWalkBtn = nil
local antiRagdollBtn = nil
local damageRepeaterBtn = nil

-- Conexiones para limpiar
local hitboxConnection = nil

-- ==================== FUNCIONES DAMAGE REPEATER ====================
local function EnableDamageRepeater()
    if not mt then
        mt = getrawmetatable(game)
        old = mt.__namecall
        setreadonly(mt, false)
    end
    
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
                return
            end
        end
        
        return old(self, ...)
    end
end

local function DisableDamageRepeater()
    if mt then
        mt.__namecall = old
        setreadonly(mt, true)
    end
end

local function toggleDamageRepeater()
    damageRepeaterEnabled = not damageRepeaterEnabled
    
    if damageRepeaterEnabled then
        EnableDamageRepeater()
        if damageRepeaterBtn then
            damageRepeaterBtn.Text = "REP\nON"
            damageRepeaterBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
            damageRepeaterBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
        end
        if repeatStatusLabel then
            repeatStatusLabel.Text = "Repetir: " .. REPEAT_AMOUNT .. "x"
            repeatStatusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
        end
    else
        DisableDamageRepeater()
        if damageRepeaterBtn then
            damageRepeaterBtn.Text = "REP\nOFF"
            damageRepeaterBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
            damageRepeaterBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        end
        if repeatStatusLabel then
            repeatStatusLabel.Text = "Repetir: " .. REPEAT_AMOUNT .. "x"
            repeatStatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
    end
end

-- ==================== ANTI-RAGDOLL ====================
local antiRagdollConnection = nil
local currentCharacterJoints = {}

local function updateJoints(character)
    if not character then return end
    currentCharacterJoints = {}
    for _, joint in pairs(character:GetDescendants()) do
        if joint:IsA("Motor6D") then
            currentCharacterJoints[joint.Name] = {
                Part0 = joint.Part0,
                Part1 = joint.Part1,
                C0 = joint.C0,
                C1 = joint.C1
            }
        end
    end
end

local function restoreJoints()
    for name, data in pairs(currentCharacterJoints) do
        if data.Part0 and data.Part0.Parent then
            if data.Part0:FindFirstChild(name) == nil then
                local joint = Instance.new("Motor6D")
                joint.Name = name
                joint.Part0 = data.Part0
                joint.Part1 = data.Part1
                joint.C0 = data.C0
                joint.C1 = data.C1
                joint.Parent = data.Part0
            end
        end
    end
end

local function isInRagdoll(humanoid)
    if not humanoid then return false end
    local state = humanoid:GetState()
    return state == Enum.HumanoidStateType.Physics or
           state == Enum.HumanoidStateType.FallingDown or
           humanoid.PlatformStand or
           (humanoid:GetState() == Enum.HumanoidStateType.Running and humanoid.PlatformStand)
end

local function antiRagdollLoop()
    if not AntiRagdollEnabled then return end
    
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    updateJoints(character)
    
    if isInRagdoll(humanoid) then
        restoreJoints()
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
        humanoid.PlatformStand = false
        humanoid.Sit = false
        humanoid.AutoRotate = true
        rootPart.Velocity = Vector3.new(rootPart.Velocity.X, 20, rootPart.Velocity.Z)
    end
end

local function setupAntiRagdoll(character)
    if antiRagdollConnection then
        antiRagdollConnection:Disconnect()
        antiRagdollConnection = nil
    end
    
    task.wait(0.5)
    updateJoints(character)
    if AntiRagdollEnabled then
        antiRagdollConnection = RunService.Heartbeat:Connect(antiRagdollLoop)
    end
end

local function toggleAntiRagdoll()
    AntiRagdollEnabled = not AntiRagdollEnabled
    
    if AntiRagdollEnabled then
        if player.Character then
            setupAntiRagdoll(player.Character)
        end
    else
        if antiRagdollConnection then
            antiRagdollConnection:Disconnect()
            antiRagdollConnection = nil
        end
    end
end

if player.Character then
    setupAntiRagdoll(player.Character)
end

player.CharacterAdded:Connect(function(character)
    task.wait(0.5)
    setupAntiRagdoll(character)
end)

-- ==================== FUNCIONES AUXILIARES ====================
local function findPlayerByPartialName(inputText)
    if inputText == "" or inputText:lower() == "todos" or inputText:lower() == "all" then
        return nil, "TODOS"
    end
    local searchText = inputText:lower():gsub("%s+", "")
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player then
            if p.Name:lower() == searchText then return p, p.Name end
            if p.DisplayName:lower() == searchText then return p, p.DisplayName end
        end
    end
    if #searchText >= 3 then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player then
                if p.Name:lower():sub(1, #searchText) == searchText then return p, p.Name end
                if p.DisplayName:lower():sub(1, #searchText) == searchText then return p, p.DisplayName end
            end
        end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player then
                if p.Name:lower():find(searchText, 1, true) then return p, p.Name end
                if p.DisplayName:lower():find(searchText, 1, true) then return p, p.DisplayName end
            end
        end
    end
    if #searchText > 0 and #searchText < 3 then return false, "Mínimo 3 letras" end
    return false, "No encontrado"
end

-- Funciones del hitbox
local function resetHitbox(target)
    pcall(function()
        if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local rootPart = target.Character.HumanoidRootPart
            rootPart.Size = Vector3.new(2, 2, 1)
            rootPart.Transparency = 1
            rootPart.BrickColor = BrickColor.new("Medium stone grey")
            rootPart.Material = Enum.Material.Plastic
            rootPart.CanCollide = false
        end
    end)
end

local function resetAllHitboxes()
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= player then
            resetHitbox(v)
        end
    end
end

local function applyHitboxToPlayer(target)
    pcall(function()
        if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local rootPart = target.Character.HumanoidRootPart
            rootPart.Size = Vector3.new(HITBOX_SIZE, HITBOX_SIZE, HITBOX_SIZE)
            rootPart.Transparency = HITBOX_TRANSPARENCY
            rootPart.BrickColor = BrickColor.new("Really black")
            rootPart.Material = Enum.Material.Neon
            rootPart.CanCollide = false
        end
    end)
end

local function shouldHitPlayer(playerObj)
    if playerObj == player then return false end
    if not playerObj.Character then return false end
    if not playerObj.Character:FindFirstChild("HumanoidRootPart") then return false end
    return true
end

-- Funcion para actualizar hitboxes
local function updateHitboxes()
    if not HitboxEnabled then
        resetAllHitboxes()
        return
    end
    
    if targetPlayer then
        if shouldHitPlayer(targetPlayer) then
            for _, v in pairs(Players:GetPlayers()) do
                if v ~= player and v ~= targetPlayer then
                    resetHitbox(v)
                end
            end
            applyHitboxToPlayer(targetPlayer)
        end
    else
        for _, v in pairs(Players:GetPlayers()) do
            if shouldHitPlayer(v) then
                applyHitboxToPlayer(v)
            else
                resetHitbox(v)
            end
        end
    end
end

-- Funciones para modificar hitbox
local function setHitboxSize(value)
    HITBOX_SIZE = tonumber(value)
    if hitboxSizeLabel then
        hitboxSizeLabel.Text = "Tamaño: " .. HITBOX_SIZE
    end
    if HitboxEnabled then
        updateHitboxes()
    end
end

local function setHitboxTransparency(value)
    HITBOX_TRANSPARENCY = tonumber(value)
    if hitboxTransparencyLabel then
        hitboxTransparencyLabel.Text = "Transparencia: " .. HITBOX_TRANSPARENCY
    end
    if HitboxEnabled then
        updateHitboxes()
    end
end

-- Funciones de movimiento
local function getCharacter()
    return player.Character
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildWhichIsA("Humanoid")
end

local function setupLoopWalkSpeed()
    if loopWalkSpeedConnection then
        loopWalkSpeedConnection:Disconnect()
        loopWalkSpeedConnection = nil
    end
    
    if WalkSpeedEnabled then
        loopWalkSpeedConnection = RunService.Heartbeat:Connect(function()
            local humanoid = getHumanoid()
            if humanoid and math.abs(humanoid.WalkSpeed - WalkSpeedValue) > 0.001 then
                pcall(function()
                    humanoid.WalkSpeed = WalkSpeedValue
                end)
            end
        end)
    end
end

local function setWalkSpeed(value)
    WalkSpeedValue = tonumber(value)
    local humanoid = getHumanoid()
    if humanoid then
        pcall(function()
            humanoid.WalkSpeed = WalkSpeedValue
        end)
    end
    if walkSpeedValueLabel then
        walkSpeedValueLabel.Text = "Vel actual: " .. string.format("%.2f", WalkSpeedValue)
    end
end

local function setWalkSpeedEnabled(enabled)
    WalkSpeedEnabled = enabled
    setupLoopWalkSpeed()
    
    if not enabled then
        local humanoid = getHumanoid()
        if humanoid then
            pcall(function()
                humanoid.WalkSpeed = 16
            end)
        end
    else
        local humanoid = getHumanoid()
        if humanoid then
            pcall(function()
                humanoid.WalkSpeed = WalkSpeedValue
            end)
        end
    end
    
    if walkSpeedBtn then
        if enabled then
            walkSpeedBtn.Text = "LOOP\nON"
            walkSpeedBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
            walkSpeedBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
        else
            walkSpeedBtn.Text = "LOOP\nOFF"
            walkSpeedBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
            walkSpeedBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        end
    end
end

-- Funciones para TP Walk
local function setupTPWalk()
    if tpWalkConnection then
        tpWalkConnection:Disconnect()
        tpWalkConnection = nil
    end
    
    if TPWalkEnabled then
        tpWalkConnection = RunService.Heartbeat:Connect(function()
            local char = getCharacter()
            local hum = getHumanoid()
            
            if char and hum and hum.Parent then
                if hum.MoveDirection.Magnitude > 0 then
                    pcall(function()
                        local speed = tonumber(TPSpeedValue) or 3
                        char:TranslateBy(hum.MoveDirection * speed)
                    end)
                end
            end
        end)
    end
end

local function setTPSpeed(value)
    TPSpeedValue = tonumber(value)
    if tpSpeedValueLabel then
        tpSpeedValueLabel.Text = "Vel TP: " .. string.format("%.2f", TPSpeedValue)
    end
end

local function setTPWalkEnabled(enabled)
    TPWalkEnabled = enabled
    setupTPWalk()
    
    if tpWalkBtn then
        if enabled then
            tpWalkBtn.Text = "TP\nON"
            tpWalkBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
            tpWalkBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
        else
            tpWalkBtn.Text = "TP\nOFF"
            tpWalkBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
            tpWalkBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        end
    end
end

-- ==================== FUNCIÓN DE ARRASTRE CON BARRA SUPERIOR ====================
local function MakeDraggableWithHandle(frame, handle)
    local dragging = false
    local dragStartPos = nil
    local frameStartPos = nil
    
    handle.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStartPos = input.Position
            frameStartPos = frame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
           input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStartPos
            frame.Position = UDim2.new(
                frameStartPos.X.Scale, frameStartPos.X.Offset + delta.X,
                frameStartPos.Y.Scale, frameStartPos.Y.Offset + delta.Y
            )
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ==================== INTERFAZ DE BOTONES PRINCIPALES ====================
local function CreateButtonsInterface()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ButtonsGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = player.PlayerGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 320, 0, 85)
    Frame.Position = UDim2.new(0.5, -160, 0.02, 0)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    Frame.BackgroundTransparency = 0.05
    Frame.BorderSizePixel = 0
    Frame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = Frame

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(100, 100, 255)
    UIStroke.Thickness = 1.5
    UIStroke.Transparency = 0.5
    UIStroke.Parent = Frame

    -- Barra superior (MANEJADOR DE ARRASTRE)
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 35)
    TopBar.Position = UDim2.new(0, 0, 0, 0)
    TopBar.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    TopBar.BackgroundTransparency = 0.2
    TopBar.BorderSizePixel = 0
    TopBar.Parent = Frame

    local TopBarCorner = Instance.new("UICorner")
    TopBarCorner.CornerRadius = UDim.new(0, 12)
    TopBarCorner.Parent = TopBar

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(0.6, 0, 1, 0)
    Title.Position = UDim2.new(0, 12, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "⋮⋮  PANEL DE CONTROL  ⋮⋮"
    Title.TextColor3 = Color3.fromRGB(200, 200, 255)
    Title.TextSize = 11
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TopBar

    -- Botón configuración
    local ConfigButton = Instance.new("TextButton")
    ConfigButton.Size = UDim2.new(0, 35, 0, 30)
    ConfigButton.Position = UDim2.new(1, -42, 0, 2.5)
    ConfigButton.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
    ConfigButton.Text = "⚙️"
    ConfigButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ConfigButton.Font = Enum.Font.GothamBold
    ConfigButton.TextSize = 16
    ConfigButton.Parent = TopBar

    local configCorner = Instance.new("UICorner")
    configCorner.CornerRadius = UDim.new(0, 6)
    configCorner.Parent = ConfigButton

    -- Contenedor de botones
    local ButtonsContainer = Instance.new("Frame")
    ButtonsContainer.Size = UDim2.new(0.96, 0, 0.55, 0)
    ButtonsContainer.Position = UDim2.new(0.02, 0, 0.48, 0)
    ButtonsContainer.BackgroundTransparency = 1
    ButtonsContainer.Parent = Frame

    -- Botón HITBOX
    hitboxBtn = Instance.new("TextButton")
    hitboxBtn.Size = UDim2.new(0.24, 0, 1, 0)
    hitboxBtn.Position = UDim2.new(0, 0, 0, 0)
    hitboxBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    hitboxBtn.Text = "HIT\nOFF"
    hitboxBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    hitboxBtn.Font = Enum.Font.GothamBold
    hitboxBtn.TextSize = 11
    hitboxBtn.TextWrapped = true
    hitboxBtn.Parent = ButtonsContainer

    local hitboxCorner = Instance.new("UICorner")
    hitboxCorner.CornerRadius = UDim.new(0, 8)
    hitboxCorner.Parent = hitboxBtn

    -- Botón TP WALK
    tpWalkBtn = Instance.new("TextButton")
    tpWalkBtn.Size = UDim2.new(0.24, 0, 1, 0)
    tpWalkBtn.Position = UDim2.new(0.25, 0, 0, 0)
    tpWalkBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    tpWalkBtn.Text = "TP\nOFF"
    tpWalkBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    tpWalkBtn.Font = Enum.Font.GothamBold
    tpWalkBtn.TextSize = 11
    tpWalkBtn.TextWrapped = true
    tpWalkBtn.Parent = ButtonsContainer

    local tpWalkCorner = Instance.new("UICorner")
    tpWalkCorner.CornerRadius = UDim.new(0, 8)
    tpWalkCorner.Parent = tpWalkBtn

    -- Botón ANTI-RAGDOLL
    antiRagdollBtn = Instance.new("TextButton")
    antiRagdollBtn.Size = UDim2.new(0.24, 0, 1, 0)
    antiRagdollBtn.Position = UDim2.new(0.5, 0, 0, 0)
    antiRagdollBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    antiRagdollBtn.Text = "RAG\nOFF"
    antiRagdollBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    antiRagdollBtn.Font = Enum.Font.GothamBold
    antiRagdollBtn.TextSize = 11
    antiRagdollBtn.TextWrapped = true
    antiRagdollBtn.Parent = ButtonsContainer

    local antiRagdollCorner = Instance.new("UICorner")
    antiRagdollCorner.CornerRadius = UDim.new(0, 8)
    antiRagdollCorner.Parent = antiRagdollBtn

    -- Botón DAMAGE REPEATER
    damageRepeaterBtn = Instance.new("TextButton")
    damageRepeaterBtn.Size = UDim2.new(0.24, 0, 1, 0)
    damageRepeaterBtn.Position = UDim2.new(0.75, 0, 0, 0)
    damageRepeaterBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    damageRepeaterBtn.Text = "REP\nOFF"
    damageRepeaterBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    damageRepeaterBtn.Font = Enum.Font.GothamBold
    damageRepeaterBtn.TextSize = 11
    damageRepeaterBtn.TextWrapped = true
    damageRepeaterBtn.Parent = ButtonsContainer

    local damageRepeaterCorner = Instance.new("UICorner")
    damageRepeaterCorner.CornerRadius = UDim.new(0, 8)
    damageRepeaterCorner.Parent = damageRepeaterBtn

    -- Hacer arrastrable usando la barra superior
    MakeDraggableWithHandle(Frame, TopBar)

    return ScreenGui, Frame, ConfigButton
end

-- ==================== INTERFAZ DE CONFIGURACIÓN ====================
local function CreateConfigInterface()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ConfigGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Enabled = false
    ScreenGui.Parent = player.PlayerGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 260, 0, 350)
    Frame.Position = UDim2.new(0.5, -130, 0.5, -175)
    Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Frame.BorderSizePixel = 0
    Frame.ClipsDescendants = true
    Frame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = Frame

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(100, 100, 255)
    UIStroke.Thickness = 1.5
    UIStroke.Transparency = 0.5
    UIStroke.Parent = Frame

    -- Barra de título (MANEJADOR DE ARRASTRE)
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 35)
    TitleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    TitleBar.BackgroundTransparency = 0.1
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = Frame

    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 12)
    TitleCorner.Parent = TitleBar

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(0.7, 0, 1, 0)
    Title.Position = UDim2.new(0, 12, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "⋮⋮ CONFIGURACIÓN ⋮⋮"
    Title.TextColor3 = Color3.fromRGB(255, 200, 100)
    Title.TextSize = 11
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TitleBar

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 28, 0, 28)
    CloseBtn.Position = UDim2.new(1, -34, 0, 3.5)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.TextSize = 16
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Parent = TitleBar

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 6)
    CloseCorner.Parent = CloseBtn

    -- Contenido
    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(1, 0, 1, -35)
    Content.Position = UDim2.new(0, 0, 0, 35)
    Content.BackgroundTransparency = 1
    Content.Parent = Frame

    local yOffset = 0.05

    -- Sección HITBOX
    local hitboxTitle = Instance.new("TextLabel")
    hitboxTitle.Size = UDim2.new(0.9, 0, 0, 16)
    hitboxTitle.Position = UDim2.new(0.05, 0, yOffset, 0)
    hitboxTitle.BackgroundTransparency = 1
    hitboxTitle.Text = "HITBOX"
    hitboxTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
    hitboxTitle.Font = Enum.Font.GothamBold
    hitboxTitle.TextSize = 10
    hitboxTitle.TextXAlignment = Enum.TextXAlignment.Left
    hitboxTitle.Parent = Content
    yOffset = yOffset + 0.055

    -- Tamaño
    local sizeLabel = Instance.new("TextLabel")
    sizeLabel.Size = UDim2.new(0.25, 0, 0, 20)
    sizeLabel.Position = UDim2.new(0.05, 0, yOffset, 0)
    sizeLabel.BackgroundTransparency = 1
    sizeLabel.Text = "Tamaño:"
    sizeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    sizeLabel.Font = Enum.Font.Gotham
    sizeLabel.TextSize = 9
    sizeLabel.TextXAlignment = Enum.TextXAlignment.Left
    sizeLabel.Parent = Content

    local hitboxSizeInput = Instance.new("TextBox")
    hitboxSizeInput.Size = UDim2.new(0.35, 0, 0, 22)
    hitboxSizeInput.Position = UDim2.new(0.32, 0, yOffset, 0)
    hitboxSizeInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    hitboxSizeInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    hitboxSizeInput.Font = Enum.Font.Gotham
    hitboxSizeInput.TextSize = 9
    hitboxSizeInput.PlaceholderText = "0.1-100"
    hitboxSizeInput.Text = "30"
    hitboxSizeInput.Parent = Content

    local sizeInputCorner = Instance.new("UICorner")
    sizeInputCorner.CornerRadius = UDim.new(0, 5)
    sizeInputCorner.Parent = hitboxSizeInput

    hitboxSizeLabel = Instance.new("TextLabel")
    hitboxSizeLabel.Size = UDim2.new(0.25, 0, 0, 20)
    hitboxSizeLabel.Position = UDim2.new(0.7, 0, yOffset, 0)
    hitboxSizeLabel.BackgroundTransparency = 1
    hitboxSizeLabel.Text = "Tam: 30"
    hitboxSizeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    hitboxSizeLabel.Font = Enum.Font.Gotham
    hitboxSizeLabel.TextSize = 9
    hitboxSizeLabel.TextXAlignment = Enum.TextXAlignment.Left
    hitboxSizeLabel.Parent = Content
    yOffset = yOffset + 0.055

    -- Transparencia
    local transLabel = Instance.new("TextLabel")
    transLabel.Size = UDim2.new(0.25, 0, 0, 20)
    transLabel.Position = UDim2.new(0.05, 0, yOffset, 0)
    transLabel.BackgroundTransparency = 1
    transLabel.Text = "Transparencia:"
    transLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    transLabel.Font = Enum.Font.Gotham
    transLabel.TextSize = 9
    transLabel.TextXAlignment = Enum.TextXAlignment.Left
    transLabel.Parent = Content

    local hitboxTransparencyInput = Instance.new("TextBox")
    hitboxTransparencyInput.Size = UDim2.new(0.35, 0, 0, 22)
    hitboxTransparencyInput.Position = UDim2.new(0.32, 0, yOffset, 0)
    hitboxTransparencyInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    hitboxTransparencyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    hitboxTransparencyInput.Font = Enum.Font.Gotham
    hitboxTransparencyInput.TextSize = 9
    hitboxTransparencyInput.PlaceholderText = "0-1"
    hitboxTransparencyInput.Text = "1"
    hitboxTransparencyInput.Parent = Content

    local transInputCorner = Instance.new("UICorner")
    transInputCorner.CornerRadius = UDim.new(0, 5)
    transInputCorner.Parent = hitboxTransparencyInput

    hitboxTransparencyLabel = Instance.new("TextLabel")
    hitboxTransparencyLabel.Size = UDim2.new(0.25, 0, 0, 20)
    hitboxTransparencyLabel.Position = UDim2.new(0.7, 0, yOffset, 0)
    hitboxTransparencyLabel.BackgroundTransparency = 1
    hitboxTransparencyLabel.Text = "Trans: 1"
    hitboxTransparencyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    hitboxTransparencyLabel.Font = Enum.Font.Gotham
    hitboxTransparencyLabel.TextSize = 9
    hitboxTransparencyLabel.TextXAlignment = Enum.TextXAlignment.Left
    hitboxTransparencyLabel.Parent = Content
    yOffset = yOffset + 0.06

    -- Separador
    local sep1 = Instance.new("Frame")
    sep1.Size = UDim2.new(0.9, 0, 0, 1)
    sep1.Position = UDim2.new(0.05, 0, yOffset, 0)
    sep1.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    sep1.BorderSizePixel = 0
    sep1.Parent = Content
    yOffset = yOffset + 0.05

    -- Sección LOOP WALKSPEED
    local wsTitle = Instance.new("TextLabel")
    wsTitle.Size = UDim2.new(0.9, 0, 0, 16)
    wsTitle.Position = UDim2.new(0.05, 0, yOffset, 0)
    wsTitle.BackgroundTransparency = 1
    wsTitle.Text = "LOOP WALKSPEED"
    wsTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
    wsTitle.Font = Enum.Font.GothamBold
    wsTitle.TextSize = 10
    wsTitle.TextXAlignment = Enum.TextXAlignment.Left
    wsTitle.Parent = Content
    yOffset = yOffset + 0.055

    local wsContainer = Instance.new("Frame")
    wsContainer.Size = UDim2.new(0.9, 0, 0, 30)
    wsContainer.Position = UDim2.new(0.05, 0, yOffset, 0)
    wsContainer.BackgroundTransparency = 1
    wsContainer.Parent = Content

    walkSpeedBtn = Instance.new("TextButton")
    walkSpeedBtn.Size = UDim2.new(0.35, 0, 1, 0)
    walkSpeedBtn.Position = UDim2.new(0, 0, 0, 0)
    walkSpeedBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    walkSpeedBtn.Text = "LOOP\nOFF"
    walkSpeedBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    walkSpeedBtn.Font = Enum.Font.GothamBold
    walkSpeedBtn.TextSize = 9
    walkSpeedBtn.TextWrapped = true
    walkSpeedBtn.Parent = wsContainer

    local wsBtnCorner = Instance.new("UICorner")
    wsBtnCorner.CornerRadius = UDim.new(0, 6)
    wsBtnCorner.Parent = walkSpeedBtn

    local walkSpeedInput = Instance.new("TextBox")
    walkSpeedInput.Size = UDim2.new(0.55, 0, 1, 0)
    walkSpeedInput.Position = UDim2.new(0.38, 0, 0, 0)
    walkSpeedInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    walkSpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    walkSpeedInput.Font = Enum.Font.Gotham
    walkSpeedInput.TextSize = 9
    walkSpeedInput.PlaceholderText = "Velocidad"
    walkSpeedInput.Text = "16"
    walkSpeedInput.Parent = wsContainer

    local wsInputCorner = Instance.new("UICorner")
    wsInputCorner.CornerRadius = UDim.new(0, 5)
    wsInputCorner.Parent = walkSpeedInput
    yOffset = yOffset + 0.07

    walkSpeedValueLabel = Instance.new("TextLabel")
    walkSpeedValueLabel.Size = UDim2.new(0.9, 0, 0, 16)
    walkSpeedValueLabel.Position = UDim2.new(0.05, 0, yOffset, 0)
    walkSpeedValueLabel.BackgroundTransparency = 1
    walkSpeedValueLabel.Text = "Vel actual: 16"
    walkSpeedValueLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    walkSpeedValueLabel.Font = Enum.Font.Gotham
    walkSpeedValueLabel.TextSize = 8
    walkSpeedValueLabel.TextXAlignment = Enum.TextXAlignment.Left
    walkSpeedValueLabel.Parent = Content
    yOffset = yOffset + 0.05

    -- Separador
    local sep2 = Instance.new("Frame")
    sep2.Size = UDim2.new(0.9, 0, 0, 1)
    sep2.Position = UDim2.new(0.05, 0, yOffset, 0)
    sep2.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    sep2.BorderSizePixel = 0
    sep2.Parent = Content
    yOffset = yOffset + 0.05

    -- Sección TP WALK
    local tpTitle = Instance.new("TextLabel")
    tpTitle.Size = UDim2.new(0.9, 0, 0, 16)
    tpTitle.Position = UDim2.new(0.05, 0, yOffset, 0)
    tpTitle.BackgroundTransparency = 1
    tpTitle.Text = "TP WALK"
    tpTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
    tpTitle.Font = Enum.Font.GothamBold
    tpTitle.TextSize = 10
    tpTitle.TextXAlignment = Enum.TextXAlignment.Left
    tpTitle.Parent = Content
    yOffset = yOffset + 0.055

    local tpLabel = Instance.new("TextLabel")
    tpLabel.Size = UDim2.new(0.25, 0, 0, 20)
    tpLabel.Position = UDim2.new(0.05, 0, yOffset, 0)
    tpLabel.BackgroundTransparency = 1
    tpLabel.Text = "Velocidad TP:"
    tpLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    tpLabel.Font = Enum.Font.Gotham
    tpLabel.TextSize = 9
    tpLabel.TextXAlignment = Enum.TextXAlignment.Left
    tpLabel.Parent = Content

    local tpSpeedInput = Instance.new("TextBox")
    tpSpeedInput.Size = UDim2.new(0.35, 0, 0, 22)
    tpSpeedInput.Position = UDim2.new(0.32, 0, yOffset, 0)
    tpSpeedInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    tpSpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    tpSpeedInput.Font = Enum.Font.Gotham
    tpSpeedInput.TextSize = 9
    tpSpeedInput.PlaceholderText = "0.01-50"
    tpSpeedInput.Text = "3"
    tpSpeedInput.Parent = Content

    local tpInputCorner = Instance.new("UICorner")
    tpInputCorner.CornerRadius = UDim.new(0, 5)
    tpInputCorner.Parent = tpSpeedInput

    tpSpeedValueLabel = Instance.new("TextLabel")
    tpSpeedValueLabel.Size = UDim2.new(0.25, 0, 0, 20)
    tpSpeedValueLabel.Position = UDim2.new(0.7, 0, yOffset, 0)
    tpSpeedValueLabel.BackgroundTransparency = 1
    tpSpeedValueLabel.Text = "Vel TP: 3"
    tpSpeedValueLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    tpSpeedValueLabel.Font = Enum.Font.Gotham
    tpSpeedValueLabel.TextSize = 9
    tpSpeedValueLabel.TextXAlignment = Enum.TextXAlignment.Left
    tpSpeedValueLabel.Parent = Content
    yOffset = yOffset + 0.06

    -- Separador
    local sep3 = Instance.new("Frame")
    sep3.Size = UDim2.new(0.9, 0, 0, 1)
    sep3.Position = UDim2.new(0.05, 0, yOffset, 0)
    sep3.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    sep3.BorderSizePixel = 0
    sep3.Parent = Content
    yOffset = yOffset + 0.05

    -- Sección DAMAGE REPEATER
    local repeaterTitle = Instance.new("TextLabel")
    repeaterTitle.Size = UDim2.new(0.9, 0, 0, 16)
    repeaterTitle.Position = UDim2.new(0.05, 0, yOffset, 0)
    repeaterTitle.BackgroundTransparency = 1
    repeaterTitle.Text = "DAMAGE REPEATER"
    repeaterTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
    repeaterTitle.Font = Enum.Font.GothamBold
    repeaterTitle.TextSize = 10
    repeaterTitle.TextXAlignment = Enum.TextXAlignment.Left
    repeaterTitle.Parent = Content
    yOffset = yOffset + 0.055

    local repeatLabel = Instance.new("TextLabel")
    repeatLabel.Size = UDim2.new(0.35, 0, 0, 20)
    repeatLabel.Position = UDim2.new(0.05, 0, yOffset, 0)
    repeatLabel.BackgroundTransparency = 1
    repeatLabel.Text = "Repeticiones:"
    repeatLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    repeatLabel.Font = Enum.Font.Gotham
    repeatLabel.TextSize = 9
    repeatLabel.TextXAlignment = Enum.TextXAlignment.Left
    repeatLabel.Parent = Content

    repeatInput = Instance.new("TextBox")
    repeatInput.Size = UDim2.new(0.35, 0, 0, 26)
    repeatInput.Position = UDim2.new(0.45, 0, yOffset - 0.002, 0)
    repeatInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    repeatInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    repeatInput.Font = Enum.Font.Gotham
    repeatInput.TextSize = 10
    repeatInput.PlaceholderText = "1-100"
    repeatInput.Text = tostring(REPEAT_AMOUNT)
    repeatInput.Parent = Content

    local repeatInputCorner = Instance.new("UICorner")
    repeatInputCorner.CornerRadius = UDim.new(0, 5)
    repeatInputCorner.Parent = repeatInput
    yOffset = yOffset + 0.07

    repeatStatusLabel = Instance.new("TextLabel")
    repeatStatusLabel.Size = UDim2.new(0.9, 0, 0, 16)
    repeatStatusLabel.Position = UDim2.new(0.05, 0, yOffset, 0)
    repeatStatusLabel.BackgroundTransparency = 1
    repeatStatusLabel.Text = "Repetir: " .. REPEAT_AMOUNT .. "x"
    repeatStatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    repeatStatusLabel.Font = Enum.Font.Gotham
    repeatStatusLabel.TextSize = 8
    repeatStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    repeatStatusLabel.Parent = Content
    yOffset = yOffset + 0.05

    -- Separador
    local sep4 = Instance.new("Frame")
    sep4.Size = UDim2.new(0.9, 0, 0, 1)
    sep4.Position = UDim2.new(0.05, 0, yOffset, 0)
    sep4.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    sep4.BorderSizePixel = 0
    sep4.Parent = Content
    yOffset = yOffset + 0.05

    -- Sección TARGET
    local targetTitle = Instance.new("TextLabel")
    targetTitle.Size = UDim2.new(0.9, 0, 0, 16)
    targetTitle.Position = UDim2.new(0.05, 0, yOffset, 0)
    targetTitle.BackgroundTransparency = 1
    targetTitle.Text = "TARGET"
    targetTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
    targetTitle.Font = Enum.Font.GothamBold
    targetTitle.TextSize = 10
    targetTitle.TextXAlignment = Enum.TextXAlignment.Left
    targetTitle.Parent = Content
    yOffset = yOffset + 0.055

    targetBox = Instance.new("TextBox")
    targetBox.Size = UDim2.new(0.9, 0, 0, 26)
    targetBox.Position = UDim2.new(0.05, 0, yOffset, 0)
    targetBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    targetBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    targetBox.Font = Enum.Font.Gotham
    targetBox.TextSize = 10
    targetBox.PlaceholderText = "Nombre (3+ letras)"
    targetBox.Text = ""
    targetBox.Parent = Content

    local targetCorner = Instance.new("UICorner")
    targetCorner.CornerRadius = UDim.new(0, 5)
    targetCorner.Parent = targetBox
    yOffset = yOffset + 0.07

    targetStatus = Instance.new("TextLabel")
    targetStatus.Size = UDim2.new(0.9, 0, 0, 14)
    targetStatus.Position = UDim2.new(0.05, 0, yOffset, 0)
    targetStatus.BackgroundTransparency = 1
    targetStatus.Text = "Objetivo: TODOS"
    targetStatus.TextColor3 = Color3.fromRGB(120, 200, 255)
    targetStatus.Font = Enum.Font.Gotham
    targetStatus.TextSize = 8
    targetStatus.TextXAlignment = Enum.TextXAlignment.Left
    targetStatus.Parent = Content
    yOffset = yOffset + 0.045

    searchResult = Instance.new("TextLabel")
    searchResult.Size = UDim2.new(0.9, 0, 0, 14)
    searchResult.Position = UDim2.new(0.05, 0, yOffset, 0)
    searchResult.BackgroundTransparency = 1
    searchResult.Text = "Presiona Enter"
    searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
    searchResult.Font = Enum.Font.Gotham
    searchResult.TextSize = 8
    searchResult.TextXAlignment = Enum.TextXAlignment.Left
    searchResult.Parent = Content
    yOffset = yOffset + 0.05

    -- Botones
    local btnContainer = Instance.new("Frame")
    btnContainer.Size = UDim2.new(0.9, 0, 0, 26)
    btnContainer.Position = UDim2.new(0.05, 0, yOffset, 0)
    btnContainer.BackgroundTransparency = 1
    btnContainer.Parent = Content

    clearTargetBtn = Instance.new("TextButton")
    clearTargetBtn.Size = UDim2.new(0.48, 0, 1, 0)
    clearTargetBtn.Position = UDim2.new(0, 0, 0, 0)
    clearTargetBtn.BackgroundColor3 = Color3.fromRGB(180, 70, 70)
    clearTargetBtn.Text = "Limpiar"
    clearTargetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearTargetBtn.Font = Enum.Font.GothamBold
    clearTargetBtn.TextSize = 9
    clearTargetBtn.Parent = btnContainer

    local clearCorner = Instance.new("UICorner")
    clearCorner.CornerRadius = UDim.new(0, 5)
    clearCorner.Parent = clearTargetBtn

    closestBtn = Instance.new("TextButton")
    closestBtn.Size = UDim2.new(0.48, 0, 1, 0)
    closestBtn.Position = UDim2.new(0.52, 0, 0, 0)
    closestBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
    closestBtn.Text = "Más Cercano"
    closestBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closestBtn.Font = Enum.Font.GothamBold
    closestBtn.TextSize = 9
    closestBtn.Parent = btnContainer

    local closestCorner = Instance.new("UICorner")
    closestCorner.CornerRadius = UDim.new(0, 5)
    closestCorner.Parent = closestBtn
    yOffset = yOffset + 0.07

    -- Info
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(0.9, 0, 0, 14)
    infoLabel.Position = UDim2.new(0.05, 0, yOffset, 0)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = "K=Mostrar | E=Hitbox | R=TP"
    infoLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextSize = 8
    infoLabel.TextXAlignment = Enum.TextXAlignment.Center
    infoLabel.Parent = Content

    -- Hacer arrastrable usando la barra de título
    MakeDraggableWithHandle(Frame, TitleBar)

    return ScreenGui, Frame, CloseBtn
end

-- Funciones de actualización de botones
local function updateHitboxButton()
    if HitboxEnabled then
        hitboxBtn.Text = "HIT\nON"
        hitboxBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
        hitboxBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
    else
        hitboxBtn.Text = "HIT\nOFF"
        hitboxBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
        hitboxBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end
end

local function updateTPWalkButton()
    if TPWalkEnabled then
        tpWalkBtn.Text = "TP\nON"
        tpWalkBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
        tpWalkBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
    else
        tpWalkBtn.Text = "TP\nOFF"
        tpWalkBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
        tpWalkBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end
end

local function updateAntiRagdollButton()
    if AntiRagdollEnabled then
        antiRagdollBtn.Text = "RAG\nON"
        antiRagdollBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
        antiRagdollBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
    else
        antiRagdollBtn.Text = "RAG\nOFF"
        antiRagdollBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
        antiRagdollBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end
end

local function updateWalkSpeedButton()
    if WalkSpeedEnabled then
        walkSpeedBtn.Text = "LOOP\nON"
        walkSpeedBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
        walkSpeedBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
    else
        walkSpeedBtn.Text = "LOOP\nOFF"
        walkSpeedBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
        walkSpeedBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end
end

local function updateDamageRepeaterButton()
    if damageRepeaterEnabled then
        damageRepeaterBtn.Text = "REP\nON"
        damageRepeaterBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
        damageRepeaterBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
    else
        damageRepeaterBtn.Text = "REP\nOFF"
        damageRepeaterBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
        damageRepeaterBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end
end

local function updateTargetStatus()
    if targetPlayer then
        targetStatus.Text = "Objetivo: " .. exactTargetName
        targetStatus.TextColor3 = Color3.fromRGB(80, 255, 80)
        targetBox.Text = exactTargetName
    else
        targetStatus.Text = "Objetivo: TODOS"
        targetStatus.TextColor3 = Color3.fromRGB(120, 200, 255)
    end
end

local function searchAndSetTarget()
    local searchText = targetBox.Text:gsub("%s+", "")
    local foundPlayer, resultName = findPlayerByPartialName(searchText)
    if foundPlayer then
        targetPlayer = foundPlayer
        exactTargetName = resultName
        updateTargetStatus()
        searchResult.Text = "✓ Encontrado: " .. exactTargetName
        searchResult.TextColor3 = Color3.fromRGB(80, 255, 80)
        if HitboxEnabled then
            updateHitboxes()
        end
    elseif foundPlayer == nil then
        targetPlayer = nil
        exactTargetName = "TODOS"
        updateTargetStatus()
        searchResult.Text = "✓ Modo: TODOS"
        searchResult.TextColor3 = Color3.fromRGB(120, 200, 255)
        if HitboxEnabled then
            updateHitboxes()
        end
    else
        searchResult.Text = resultName
        searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
    end
    task.wait(2)
    if searchResult.Text:sub(1,1) == "✓" or searchResult.Text:find("no encontrado") or searchResult.Text:find("Minimo") then
        searchResult.Text = "Presiona Enter"
        searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end

local function targetClosest()
    local closestDistance = math.huge
    local closestPlayer = nil
    
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= player then
            pcall(function()
                if v.Character and v.Character:FindFirstChild("HumanoidRootPart") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local distance = (v.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                    if distance < closestDistance then
                        closestDistance = distance
                        closestPlayer = v
                    end
                end
            end)
        end
    end
    
    if closestPlayer then
        targetPlayer = closestPlayer
        exactTargetName = closestPlayer.DisplayName .. " (" .. closestPlayer.Name .. ")"
        updateTargetStatus()
        targetBox.Text = closestPlayer.Name
        searchResult.Text = "✓ Target: " .. exactTargetName
        searchResult.TextColor3 = Color3.fromRGB(80, 255, 80)
        if HitboxEnabled then
            updateHitboxes()
        end
        task.wait(2)
        searchResult.Text = "Presiona Enter"
        searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
    else
        searchResult.Text = "✗ No hay jugadores"
        searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
        task.wait(2)
        searchResult.Text = "Presiona Enter"
        searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end

local function clearTarget()
    targetPlayer = nil
    exactTargetName = "TODOS"
    targetBox.Text = ""
    updateTargetStatus()
    searchResult.Text = "✓ Target limpiado"
    searchResult.TextColor3 = Color3.fromRGB(120, 200, 255)
    if HitboxEnabled then
        updateHitboxes()
    end
    task.wait(2)
    searchResult.Text = "Presiona Enter"
    searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
end

-- Crear las dos interfaces
local buttonsGUI, buttonsFrame, configButton = CreateButtonsInterface()
local configGUI, configFrame, closeConfigBtn = CreateConfigInterface()

-- Conectar eventos
hitboxBtn.MouseButton1Click:Connect(function()
    HitboxEnabled = not HitboxEnabled
    updateHitboxButton()
    if HitboxEnabled then
        updateHitboxes()
    else
        resetAllHitboxes()
    end
end)

tpWalkBtn.MouseButton1Click:Connect(function()
    setTPWalkEnabled(not TPWalkEnabled)
    updateTPWalkButton()
end)

antiRagdollBtn.MouseButton1Click:Connect(function()
    toggleAntiRagdoll()
    updateAntiRagdollButton()
end)

damageRepeaterBtn.MouseButton1Click:Connect(function()
    toggleDamageRepeater()
    updateDamageRepeaterButton()
end)

configButton.MouseButton1Click:Connect(function()
    configGUI.Enabled = not configGUI.Enabled
end)

closeConfigBtn.MouseButton1Click:Connect(function()
    configGUI.Enabled = false
end)

-- Evento para el input de repeticiones
if repeatInput then
    repeatInput.FocusLost:Connect(function()
        local num = tonumber(repeatInput.Text)
        if num and num >= 1 and num <= 100 then
            REPEAT_AMOUNT = math.floor(num)
            repeatInput.Text = tostring(REPEAT_AMOUNT)
            if repeatStatusLabel then
                repeatStatusLabel.Text = "Repetir: " .. REPEAT_AMOUNT .. "x"
                if damageRepeaterEnabled then
                    repeatStatusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
                else
                    repeatStatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
                end
            end
            if damageRepeaterEnabled then
                DisableDamageRepeater()
                EnableDamageRepeater()
            end
        else
            repeatInput.Text = tostring(REPEAT_AMOUNT)
        end
    end)
end

-- Eventos de configuración
local function findTextBoxes()
    local content = configFrame:FindFirstChild("Content")
    if not content then return end
    
    for _, v in pairs(content:GetDescendants()) do
        if v:IsA("TextBox") then
            if v.PlaceholderText == "0.1-100" then
                v.FocusLost:Connect(function(enter)
                    if enter then
                        local val = tonumber(v.Text)
                        if val and val >= 0.1 and val <= 100 then
                            setHitboxSize(val)
                        else
                            v.Text = tostring(HITBOX_SIZE)
                            searchResult.Text = "✗ Tam inválido"
                            task.wait(1.5)
                            searchResult.Text = "Presiona Enter"
                        end
                    end
                end)
            elseif v.PlaceholderText == "0-1" then
                v.FocusLost:Connect(function(enter)
                    if enter then
                        local val = tonumber(v.Text)
                        if val and val >= 0 and val <= 1 then
                            setHitboxTransparency(val)
                        else
                            v.Text = tostring(HITBOX_TRANSPARENCY)
                            searchResult.Text = "✗ Trans inválida"
                            task.wait(1.5)
                            searchResult.Text = "Presiona Enter"
                        end
                    end
                end)
            elseif v.PlaceholderText == "Velocidad" then
                v.FocusLost:Connect(function(enter)
                    if enter then
                        local val = tonumber(v.Text)
                        if val and val >= 0.1 and val <= 500 then
                            setWalkSpeed(val)
                        else
                            v.Text = tostring(WalkSpeedValue)
                            searchResult.Text = "✗ Vel inválida"
                            task.wait(1.5)
                            searchResult.Text = "Presiona Enter"
                        end
                    end
                end)
            elseif v.PlaceholderText == "0.01-50" then
                v.FocusLost:Connect(function(enter)
                    if enter then
                        local val = tonumber(v.Text)
                        if val and val >= 0.01 and val <= 50 then
                            setTPSpeed(val)
                        else
                            v.Text = tostring(TPSpeedValue)
                            searchResult.Text = "✗ Vel TP inválida"
                            task.wait(1.5)
                            searchResult.Text = "Presiona Enter"
                        end
                    end
                end)
            end
        end
    end
end

task.wait(0.5)
findTextBoxes()

if walkSpeedBtn then
    walkSpeedBtn.MouseButton1Click:Connect(function()
        setWalkSpeedEnabled(not WalkSpeedEnabled)
        updateWalkSpeedButton()
    end)
end

if targetBox then
    targetBox.FocusLost:Connect(function(enter)
        if enter then searchAndSetTarget() end
    end)
end

if clearTargetBtn then
    clearTargetBtn.MouseButton1Click:Connect(clearTarget)
end

if closestBtn then
    closestBtn.MouseButton1Click:Connect(targetClosest)
end

-- Eventos de jugadores
Players.PlayerRemoving:Connect(function(p)
    if targetPlayer == p then
        targetPlayer = nil
        exactTargetName = "TODOS"
        if targetBox then targetBox.Text = "" end
        updateTargetStatus()
        if searchResult then
            searchResult.Text = "⚠️ Objetivo salió"
            searchResult.TextColor3 = Color3.fromRGB(255, 150, 50)
            task.wait(2)
            searchResult.Text = "Presiona Enter"
            searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
        if HitboxEnabled then
            updateHitboxes()
        end
    end
end)

Players.PlayerAdded:Connect(function(p)
    task.wait(1)
    if HitboxEnabled and shouldHitPlayer(p) then
        applyHitboxToPlayer(p)
    end
end)

for _, p in pairs(Players:GetPlayers()) do
    p.CharacterAdded:Connect(function(character)
        task.wait(0.5)
        if HitboxEnabled and shouldHitPlayer(p) then
            applyHitboxToPlayer(p)
        end
    end)
end

-- Teclas
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.K then
        if buttonsGUI then
            buttonsGUI.Enabled = not buttonsGUI.Enabled
        end
    elseif input.KeyCode == Enum.KeyCode.E then
        HitboxEnabled = not HitboxEnabled
        updateHitboxButton()
        if HitboxEnabled then
            updateHitboxes()
        else
            resetAllHitboxes()
        end
    elseif input.KeyCode == Enum.KeyCode.R then
        setTPWalkEnabled(not TPWalkEnabled)
        updateTPWalkButton()
    end
end)

-- Loop principal del hitbox
hitboxConnection = RunService.Heartbeat:Connect(updateHitboxes)

-- Inicialización
updateTargetStatus()
updateHitboxButton()
updateTPWalkButton()
updateAntiRagdollButton()
updateWalkSpeedButton()
updateDamageRepeaterButton()
setWalkSpeed(16)
setTPSpeed(3)
setHitboxSize(30)
setHitboxTransparency(1)

print("=== HITBOX EXPANDER + MOVEMENT + ANTI-RAGDOLL + DAMAGE REPEATER ===")
print("✅ Arrastre funcionando - Toca y arrastra la BARRA SUPERIOR de cada ventana")
print("✅ Barra superior con texto '⋮⋮ PANEL DE CONTROL ⋮⋮' y '⋮⋮ CONFIGURACIÓN ⋮⋮'")
print("✅ Funciona con MOUSE (botón izquierdo) y TÁCTIL (dedo)")
print("✅ Tecla K = Mostrar/Ocultar panel de botones")
print("✅ Tecla E = Activar/Desactivar HITBOX")
print("✅ Tecla R = Activar/Desactivar TP WALK")
