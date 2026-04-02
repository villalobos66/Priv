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

-- Variables para la interfaz de botones
local buttonsFrame = nil
local buttonsScreenGui = nil
local hitboxBtn = nil
local tpWalkBtn = nil
local antiRagdollBtn = nil

-- Conexiones para limpiar
local hitboxConnection = nil

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
        hitboxSizeLabel.Text = "Tamano: " .. HITBOX_SIZE
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
        walkSpeedValueLabel.Text = "Velocidad actual: " .. string.format("%.2f", WalkSpeedValue)
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
            walkSpeedBtn.Text = "LOOP WALKSPEED: ON"
            walkSpeedBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
            walkSpeedBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
        else
            walkSpeedBtn.Text = "LOOP WALKSPEED: OFF"
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
        tpSpeedValueLabel.Text = "Velocidad TP: " .. string.format("%.2f", TPSpeedValue)
    end
end

local function setTPWalkEnabled(enabled)
    TPWalkEnabled = enabled
    setupTPWalk()
    
    if tpWalkBtn then
        if enabled then
            tpWalkBtn.Text = "TP WALK\nON"
            tpWalkBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
            tpWalkBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
        else
            tpWalkBtn.Text = "TP WALK\nOFF"
            tpWalkBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
            tpWalkBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        end
    end
end

-- ==================== FUNCIÓN DE ARRASTRE REUTILIZABLE ====================
local function MakeDraggable(frame, dragHandle)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    local dragConnection = nil
    local dragEndConnection = nil
    local handle = dragHandle or frame
    
    local function startDrag(input)
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        
        dragConnection = UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
               input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end)
        
        dragEndConnection = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or 
               input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
                if dragConnection then dragConnection:Disconnect() end
                if dragEndConnection then dragEndConnection:Disconnect() end
            end
        end)
    end
    
    handle.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            
            local target = UserInputService:GetMouseTarget()
            local isInteractiveButton = false
            
            if target then
                local current = target
                while current and current ~= frame do
                    if current:IsA("TextButton") or current:IsA("TextBox") then
                        isInteractiveButton = true
                        break
                    end
                    current = current.Parent
                end
            end
            
            if not isInteractiveButton then
                startDrag(input)
            end
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
    Frame.Size = UDim2.new(0, 300, 0, 60)
    Frame.Position = UDim2.new(0.5, -150, 0.02, 0)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    Frame.BackgroundTransparency = 0.1
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

    -- Barra de título para arrastrar
    local DragBar = Instance.new("Frame")
    DragBar.Size = UDim2.new(1, 0, 0, 25)
    DragBar.Position = UDim2.new(0, 0, 0, 0)
    DragBar.BackgroundTransparency = 1
    DragBar.Parent = Frame

    -- Contenedor de botones
    local ButtonsContainer = Instance.new("Frame")
    ButtonsContainer.Size = UDim2.new(0.95, 0, 0.8, 0)
    ButtonsContainer.Position = UDim2.new(0.025, 0, 0.1, 0)
    ButtonsContainer.BackgroundTransparency = 1
    ButtonsContainer.Parent = Frame

    -- Botón HITBOX
    hitboxBtn = Instance.new("TextButton")
    hitboxBtn.Size = UDim2.new(0.32, 0, 1, 0)
    hitboxBtn.Position = UDim2.new(0, 0, 0, 0)
    hitboxBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    hitboxBtn.Text = "HITBOX\nOFF"
    hitboxBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    hitboxBtn.Font = Enum.Font.GothamBold
    hitboxBtn.TextSize = 12
    hitboxBtn.TextWrapped = true
    hitboxBtn.Parent = ButtonsContainer

    local hitboxCorner = Instance.new("UICorner")
    hitboxCorner.CornerRadius = UDim.new(0, 8)
    hitboxCorner.Parent = hitboxBtn

    -- Botón TP WALK
    tpWalkBtn = Instance.new("TextButton")
    tpWalkBtn.Size = UDim2.new(0.32, 0, 1, 0)
    tpWalkBtn.Position = UDim2.new(0.34, 0, 0, 0)
    tpWalkBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    tpWalkBtn.Text = "TP WALK\nOFF"
    tpWalkBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    tpWalkBtn.Font = Enum.Font.GothamBold
    tpWalkBtn.TextSize = 12
    tpWalkBtn.TextWrapped = true
    tpWalkBtn.Parent = ButtonsContainer

    local tpWalkCorner = Instance.new("UICorner")
    tpWalkCorner.CornerRadius = UDim.new(0, 8)
    tpWalkCorner.Parent = tpWalkBtn

    -- Botón ANTI-RAGDOLL
    antiRagdollBtn = Instance.new("TextButton")
    antiRagdollBtn.Size = UDim2.new(0.32, 0, 1, 0)
    antiRagdollBtn.Position = UDim2.new(0.68, 0, 0, 0)
    antiRagdollBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    antiRagdollBtn.Text = "ANTI-RAG\nOFF"
    antiRagdollBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    antiRagdollBtn.Font = Enum.Font.GothamBold
    antiRagdollBtn.TextSize = 12
    antiRagdollBtn.TextWrapped = true
    antiRagdollBtn.Parent = ButtonsContainer

    local antiRagdollCorner = Instance.new("UICorner")
    antiRagdollCorner.CornerRadius = UDim.new(0, 8)
    antiRagdollCorner.Parent = antiRagdollBtn

    -- Botón para abrir configuración
    local ConfigButton = Instance.new("TextButton")
    ConfigButton.Size = UDim2.new(0.06, 0, 0.7, 0)
    ConfigButton.Position = UDim2.new(0.93, 0, 0.15, 0)
    ConfigButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    ConfigButton.Text = "⚙️"
    ConfigButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ConfigButton.Font = Enum.Font.GothamBold
    ConfigButton.TextSize = 18
    ConfigButton.Parent = Frame

    local configCorner = Instance.new("UICorner")
    configCorner.CornerRadius = UDim.new(0, 8)
    configCorner.Parent = ConfigButton

    -- Hacer la ventana arrastrable
    MakeDraggable(Frame, DragBar)

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
    Frame.Size = UDim2.new(0, 350, 0, 520)
    Frame.Position = UDim2.new(0.5, -175, 0.5, -260)
    Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Frame.BorderSizePixel = 0
    Frame.ClipsDescendants = true
    Frame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = Frame

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(100, 100, 255)
    UIStroke.Thickness = 2
    UIStroke.Transparency = 0.5
    UIStroke.Parent = Frame

    -- Barra de título
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 35)
    TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
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
    Title.Text = "⚙️ CONFIGURACIÓN"
    Title.TextColor3 = Color3.fromRGB(255, 200, 100)
    Title.TextSize = 14
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TitleBar

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -38, 0, 2.5)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.TextSize = 18
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Parent = TitleBar

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 8)
    CloseCorner.Parent = CloseBtn

    -- Contenido
    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(1, 0, 1, -35)
    Content.Position = UDim2.new(0, 0, 0, 35)
    Content.BackgroundTransparency = 1
    Content.Parent = Frame

    -- Sección HITBOX CONFIG
    local hitboxConfigSection = Instance.new("TextLabel")
    hitboxConfigSection.Size = UDim2.new(0.85, 0, 0, 20)
    hitboxConfigSection.Position = UDim2.new(0.075, 0, 0.02, 0)
    hitboxConfigSection.BackgroundTransparency = 1
    hitboxConfigSection.Text = "----- CONFIGURACIÓN HITBOX -----"
    hitboxConfigSection.TextColor3 = Color3.fromRGB(255, 200, 100)
    hitboxConfigSection.Font = Enum.Font.GothamBold
    hitboxConfigSection.TextSize = 11
    hitboxConfigSection.TextXAlignment = Enum.TextXAlignment.Center
    hitboxConfigSection.Parent = Content

    -- Input para tamaño del hitbox
    local hitboxSizeInput = Instance.new("TextBox")
    hitboxSizeInput.Size = UDim2.new(0.4, 0, 0, 28)
    hitboxSizeInput.Position = UDim2.new(0.075, 0, 0.07, 0)
    hitboxSizeInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    hitboxSizeInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    hitboxSizeInput.Font = Enum.Font.Gotham
    hitboxSizeInput.TextSize = 11
    hitboxSizeInput.PlaceholderText = "Tamano (0.1-100)"
    hitboxSizeInput.Text = "30"
    hitboxSizeInput.Parent = Content

    local sizeInputCorner = Instance.new("UICorner")
    sizeInputCorner.CornerRadius = UDim.new(0, 6)
    sizeInputCorner.Parent = hitboxSizeInput

    hitboxSizeLabel = Instance.new("TextLabel")
    hitboxSizeLabel.Size = UDim2.new(0.4, 0, 0, 20)
    hitboxSizeLabel.Position = UDim2.new(0.52, 0, 0.072, 0)
    hitboxSizeLabel.BackgroundTransparency = 1
    hitboxSizeLabel.Text = "Tamano: 30"
    hitboxSizeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    hitboxSizeLabel.Font = Enum.Font.Gotham
    hitboxSizeLabel.TextSize = 10
    hitboxSizeLabel.TextXAlignment = Enum.TextXAlignment.Left
    hitboxSizeLabel.Parent = Content

    -- Input para transparencia del hitbox
    local hitboxTransparencyInput = Instance.new("TextBox")
    hitboxTransparencyInput.Size = UDim2.new(0.4, 0, 0, 28)
    hitboxTransparencyInput.Position = UDim2.new(0.075, 0, 0.12, 0)
    hitboxTransparencyInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    hitboxTransparencyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    hitboxTransparencyInput.Font = Enum.Font.Gotham
    hitboxTransparencyInput.TextSize = 11
    hitboxTransparencyInput.PlaceholderText = "Transparencia (0-1)"
    hitboxTransparencyInput.Text = "1"
    hitboxTransparencyInput.Parent = Content

    local transInputCorner = Instance.new("UICorner")
    transInputCorner.CornerRadius = UDim.new(0, 6)
    transInputCorner.Parent = hitboxTransparencyInput

    hitboxTransparencyLabel = Instance.new("TextLabel")
    hitboxTransparencyLabel.Size = UDim2.new(0.4, 0, 0, 20)
    hitboxTransparencyLabel.Position = UDim2.new(0.52, 0, 0.122, 0)
    hitboxTransparencyLabel.BackgroundTransparency = 1
    hitboxTransparencyLabel.Text = "Transparencia: 1"
    hitboxTransparencyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    hitboxTransparencyLabel.Font = Enum.Font.Gotham
    hitboxTransparencyLabel.TextSize = 10
    hitboxTransparencyLabel.TextXAlignment = Enum.TextXAlignment.Left
    hitboxTransparencyLabel.Parent = Content

    -- Separador
    local separator1 = Instance.new("Frame")
    separator1.Size = UDim2.new(0.85, 0, 0, 1)
    separator1.Position = UDim2.new(0.075, 0, 0.17, 0)
    separator1.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    separator1.BorderSizePixel = 0
    separator1.Parent = Content

    -- Sección LOOP WALKSPEED
    local walkSpeedSection = Instance.new("TextLabel")
    walkSpeedSection.Size = UDim2.new(0.85, 0, 0, 20)
    walkSpeedSection.Position = UDim2.new(0.075, 0, 0.19, 0)
    walkSpeedSection.BackgroundTransparency = 1
    walkSpeedSection.Text = "----- LOOP WALKSPEED -----"
    walkSpeedSection.TextColor3 = Color3.fromRGB(255, 200, 100)
    walkSpeedSection.Font = Enum.Font.GothamBold
    walkSpeedSection.TextSize = 11
    walkSpeedSection.TextXAlignment = Enum.TextXAlignment.Center
    walkSpeedSection.Parent = Content

    -- Boton Loop WalkSpeed
    walkSpeedBtn = Instance.new("TextButton")
    walkSpeedBtn.Size = UDim2.new(0.85, 0, 0, 35)
    walkSpeedBtn.Position = UDim2.new(0.075, 0, 0.23, 0)
    walkSpeedBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    walkSpeedBtn.Text = "LOOP WALKSPEED: OFF"
    walkSpeedBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    walkSpeedBtn.Font = Enum.Font.GothamBold
    walkSpeedBtn.TextSize = 12
    walkSpeedBtn.Parent = Content

    local walkSpeedCorner = Instance.new("UICorner")
    walkSpeedCorner.CornerRadius = UDim.new(0, 8)
    walkSpeedCorner.Parent = walkSpeedBtn

    -- Input para WalkSpeed
    local walkSpeedInput = Instance.new("TextBox")
    walkSpeedInput.Size = UDim2.new(0.4, 0, 0, 28)
    walkSpeedInput.Position = UDim2.new(0.075, 0, 0.285, 0)
    walkSpeedInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    walkSpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    walkSpeedInput.Font = Enum.Font.Gotham
    walkSpeedInput.TextSize = 11
    walkSpeedInput.PlaceholderText = "Velocidad (0.1-500)"
    walkSpeedInput.Text = "16"
    walkSpeedInput.Parent = Content

    local wsInputCorner = Instance.new("UICorner")
    wsInputCorner.CornerRadius = UDim.new(0, 6)
    wsInputCorner.Parent = walkSpeedInput

    walkSpeedValueLabel = Instance.new("TextLabel")
    walkSpeedValueLabel.Size = UDim2.new(0.4, 0, 0, 20)
    walkSpeedValueLabel.Position = UDim2.new(0.52, 0, 0.287, 0)
    walkSpeedValueLabel.BackgroundTransparency = 1
    walkSpeedValueLabel.Text = "Velocidad actual: 16"
    walkSpeedValueLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    walkSpeedValueLabel.Font = Enum.Font.Gotham
    walkSpeedValueLabel.TextSize = 10
    walkSpeedValueLabel.TextXAlignment = Enum.TextXAlignment.Left
    walkSpeedValueLabel.Parent = Content

    -- Separador
    local separator2 = Instance.new("Frame")
    separator2.Size = UDim2.new(0.85, 0, 0, 1)
    separator2.Position = UDim2.new(0.075, 0, 0.335, 0)
    separator2.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    separator2.BorderSizePixel = 0
    separator2.Parent = Content

    -- Sección TP WALK CONFIG
    local tpSection = Instance.new("TextLabel")
    tpSection.Size = UDim2.new(0.85, 0, 0, 20)
    tpSection.Position = UDim2.new(0.075, 0, 0.355, 0)
    tpSection.BackgroundTransparency = 1
    tpSection.Text = "----- CONFIGURACIÓN TP WALK -----"
    tpSection.TextColor3 = Color3.fromRGB(255, 200, 100)
    tpSection.Font = Enum.Font.GothamBold
    tpSection.TextSize = 11
    tpSection.TextXAlignment = Enum.TextXAlignment.Center
    tpSection.Parent = Content

    -- Input para TP Speed
    local tpSpeedInput = Instance.new("TextBox")
    tpSpeedInput.Size = UDim2.new(0.4, 0, 0, 28)
    tpSpeedInput.Position = UDim2.new(0.075, 0, 0.395, 0)
    tpSpeedInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    tpSpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    tpSpeedInput.Font = Enum.Font.Gotham
    tpSpeedInput.TextSize = 11
    tpSpeedInput.PlaceholderText = "Velocidad TP (0.01-50)"
    tpSpeedInput.Text = "3"
    tpSpeedInput.Parent = Content

    local tpInputCorner = Instance.new("UICorner")
    tpInputCorner.CornerRadius = UDim.new(0, 6)
    tpInputCorner.Parent = tpSpeedInput

    tpSpeedValueLabel = Instance.new("TextLabel")
    tpSpeedValueLabel.Size = UDim2.new(0.4, 0, 0, 20)
    tpSpeedValueLabel.Position = UDim2.new(0.52, 0, 0.397, 0)
    tpSpeedValueLabel.BackgroundTransparency = 1
    tpSpeedValueLabel.Text = "Velocidad TP: 3"
    tpSpeedValueLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    tpSpeedValueLabel.Font = Enum.Font.Gotham
    tpSpeedValueLabel.TextSize = 10
    tpSpeedValueLabel.TextXAlignment = Enum.TextXAlignment.Left
    tpSpeedValueLabel.Parent = Content

    -- Separador
    local separator3 = Instance.new("Frame")
    separator3.Size = UDim2.new(0.85, 0, 0, 1)
    separator3.Position = UDim2.new(0.075, 0, 0.445, 0)
    separator3.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    separator3.BorderSizePixel = 0
    separator3.Parent = Content

    -- Sección TARGET
    local targetSection = Instance.new("TextLabel")
    targetSection.Size = UDim2.new(0.85, 0, 0, 20)
    targetSection.Position = UDim2.new(0.075, 0, 0.465, 0)
    targetSection.BackgroundTransparency = 1
    targetSection.Text = "----- SISTEMA TARGET -----"
    targetSection.TextColor3 = Color3.fromRGB(255, 200, 100)
    targetSection.Font = Enum.Font.GothamBold
    targetSection.TextSize = 11
    targetSection.TextXAlignment = Enum.TextXAlignment.Center
    targetSection.Parent = Content

    -- Campo de busqueda
    targetBox = Instance.new("TextBox")
    targetBox.Size = UDim2.new(0.85, 0, 0, 30)
    targetBox.Position = UDim2.new(0.075, 0, 0.505, 0)
    targetBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    targetBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    targetBox.Font = Enum.Font.Gotham
    targetBox.TextSize = 12
    targetBox.PlaceholderText = "Escribe 3+ letras para buscar"
    targetBox.Text = ""
    targetBox.Parent = Content

    local targetCorner = Instance.new("UICorner")
    targetCorner.CornerRadius = UDim.new(0, 6)
    targetCorner.Parent = targetBox

    -- Estado del target
    targetStatus = Instance.new("TextLabel")
    targetStatus.Size = UDim2.new(0.85, 0, 0, 18)
    targetStatus.Position = UDim2.new(0.075, 0, 0.56, 0)
    targetStatus.BackgroundTransparency = 1
    targetStatus.Text = "Objetivo actual: TODOS"
    targetStatus.TextColor3 = Color3.fromRGB(120, 200, 255)
    targetStatus.Font = Enum.Font.Gotham
    targetStatus.TextSize = 10
    targetStatus.TextXAlignment = Enum.TextXAlignment.Left
    targetStatus.Parent = Content

    -- Mensaje de resultado
    searchResult = Instance.new("TextLabel")
    searchResult.Size = UDim2.new(0.85, 0, 0, 18)
    searchResult.Position = UDim2.new(0.075, 0, 0.6, 0)
    searchResult.BackgroundTransparency = 1
    searchResult.Text = "Presiona Enter para buscar"
    searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
    searchResult.Font = Enum.Font.Gotham
    searchResult.TextSize = 9
    searchResult.TextXAlignment = Enum.TextXAlignment.Left
    searchResult.TextWrapped = true
    searchResult.Parent = Content

    -- Botones horizontales
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Size = UDim2.new(0.85, 0, 0, 30)
    buttonContainer.Position = UDim2.new(0.075, 0, 0.64, 0)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = Content

    -- Boton Limpiar Target
    clearTargetBtn = Instance.new("TextButton")
    clearTargetBtn.Size = UDim2.new(0.48, 0, 1, 0)
    clearTargetBtn.Position = UDim2.new(0, 0, 0, 0)
    clearTargetBtn.BackgroundColor3 = Color3.fromRGB(180, 70, 70)
    clearTargetBtn.Text = "Limpiar"
    clearTargetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearTargetBtn.Font = Enum.Font.GothamBold
    clearTargetBtn.TextSize = 11
    clearTargetBtn.Parent = buttonContainer

    local clearCorner = Instance.new("UICorner")
    clearCorner.CornerRadius = UDim.new(0, 6)
    clearCorner.Parent = clearTargetBtn

    -- Boton Targetear Mas Cercano
    closestBtn = Instance.new("TextButton")
    closestBtn.Size = UDim2.new(0.48, 0, 1, 0)
    closestBtn.Position = UDim2.new(0.52, 0, 0, 0)
    closestBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
    closestBtn.Text = "Mas Cercano"
    closestBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closestBtn.Font = Enum.Font.GothamBold
    closestBtn.TextSize = 11
    closestBtn.Parent = buttonContainer

    local closestCorner = Instance.new("UICorner")
    closestCorner.CornerRadius = UDim.new(0, 6)
    closestCorner.Parent = closestBtn

    -- Info adicional
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(0.85, 0, 0, 20)
    infoLabel.Position = UDim2.new(0.075, 0, 0.7, 0)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = "Teclas: K = Mostrar/Ocultar | E = Hitbox | R = TP Walk"
    infoLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextSize = 9
    infoLabel.TextXAlignment = Enum.TextXAlignment.Center
    infoLabel.Parent = Content

    -- Hacer la ventana arrastrable (usando la barra de título)
    MakeDraggable(Frame, TitleBar)

    return ScreenGui, Frame, CloseBtn
end

-- Funciones de actualización de botones
local function updateHitboxButton()
    if HitboxEnabled then
        hitboxBtn.Text = "HITBOX\nON"
        hitboxBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
        hitboxBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
    else
        hitboxBtn.Text = "HITBOX\nOFF"
        hitboxBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
        hitboxBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end
end

local function updateTPWalkButton()
    if TPWalkEnabled then
        tpWalkBtn.Text = "TP WALK\nON"
        tpWalkBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
        tpWalkBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
    else
        tpWalkBtn.Text = "TP WALK\nOFF"
        tpWalkBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
        tpWalkBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end
end

local function updateAntiRagdollButton()
    if AntiRagdollEnabled then
        antiRagdollBtn.Text = "ANTI-RAG\nON"
        antiRagdollBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
        antiRagdollBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
    else
        antiRagdollBtn.Text = "ANTI-RAG\nOFF"
        antiRagdollBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
        antiRagdollBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end
end

local function updateWalkSpeedButton()
    if WalkSpeedEnabled then
        walkSpeedBtn.Text = "LOOP WALKSPEED: ON"
        walkSpeedBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
        walkSpeedBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
    else
        walkSpeedBtn.Text = "LOOP WALKSPEED: OFF"
        walkSpeedBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
        walkSpeedBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end
end

-- Funcion para actualizar estado del target
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

-- Funcion para buscar y establecer target
local function searchAndSetTarget()
    local searchText = targetBox.Text:gsub("%s+", "")
    local foundPlayer, resultName = findPlayerByPartialName(searchText)
    if foundPlayer then
        targetPlayer = foundPlayer
        exactTargetName = resultName
        updateTargetStatus()
        searchResult.Text = "Encontrado: " .. exactTargetName
        searchResult.TextColor3 = Color3.fromRGB(80, 255, 80)
        if HitboxEnabled then
            updateHitboxes()
        end
    elseif foundPlayer == nil then
        targetPlayer = nil
        exactTargetName = "TODOS"
        updateTargetStatus()
        searchResult.Text = "Modo: TODOS"
        searchResult.TextColor3 = Color3.fromRGB(120, 200, 255)
        if HitboxEnabled then
            updateHitboxes()
        end
    else
        searchResult.Text = resultName
        searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
    end
    task.wait(3)
    if searchResult.Text:sub(1,1) == "E" or searchResult.Text:find("no encontrado") or searchResult.Text:find("Minimo") then
        searchResult.Text = "Presiona Enter para buscar"
        searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end

-- Funcion para targetear al jugador mas cercano
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
        searchResult.Text = "Target mas cercano: " .. exactTargetName
        searchResult.TextColor3 = Color3.fromRGB(80, 255, 80)
        if HitboxEnabled then
            updateHitboxes()
        end
        task.wait(2)
        searchResult.Text = "Presiona Enter para buscar"
        searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
    else
        searchResult.Text = "No hay jugadores cercanos"
        searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
        task.wait(2)
        searchResult.Text = "Presiona Enter para buscar"
        searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end

-- Funcion para limpiar target
local function clearTarget()
    targetPlayer = nil
    exactTargetName = "TODOS"
    targetBox.Text = ""
    updateTargetStatus()
    searchResult.Text = "Target limpiado - Modo TODOS"
    searchResult.TextColor3 = Color3.fromRGB(120, 200, 255)
    if HitboxEnabled then
        updateHitboxes()
    end
    task.wait(2)
    searchResult.Text = "Presiona Enter para buscar"
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

configButton.MouseButton1Click:Connect(function()
    configGUI.Enabled = not configGUI.Enabled
end)

closeConfigBtn.MouseButton1Click:Connect(function()
    configGUI.Enabled = false
end)

-- Eventos de configuración
local function findTextBoxes()
    local content = configFrame:FindFirstChild("Content")
    if not content then return end
    
    local textBoxes = {}
    for _, v in pairs(content:GetChildren()) do
        if v:IsA("TextBox") then
            table.insert(textBoxes, v)
        end
    end
    
    local hitboxSizeInput, hitboxTransparencyInput, walkSpeedInput, tpSpeedInput
    
    for _, tb in pairs(textBoxes) do
        if tb.PlaceholderText and tb.PlaceholderText:find("Tamano") then
            hitboxSizeInput = tb
        elseif tb.PlaceholderText and tb.PlaceholderText:find("Transparencia") then
            hitboxTransparencyInput = tb
        elseif tb.PlaceholderText and tb.PlaceholderText:find("Velocidad") and not tb.PlaceholderText:find("TP") then
            walkSpeedInput = tb
        elseif tb.PlaceholderText and tb.PlaceholderText:find("Velocidad TP") then
            tpSpeedInput = tb
        end
    end
    
    if hitboxSizeInput then
        hitboxSizeInput.FocusLost:Connect(function(enter)
            if enter then
                local value = tonumber(hitboxSizeInput.Text)
                if value and value >= 0.1 and value <= 100 then
                    setHitboxSize(value)
                else
                    hitboxSizeInput.Text = tostring(HITBOX_SIZE)
                    if searchResult then
                        searchResult.Text = "Tamano invalido (0.1-100)"
                        searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
                        task.wait(2)
                        if searchResult.Text:find("invalido") then
                            searchResult.Text = "Presiona Enter para buscar"
                            searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
                        end
                    end
                end
            end
        end)
    end
    
    if hitboxTransparencyInput then
        hitboxTransparencyInput.FocusLost:Connect(function(enter)
            if enter then
                local value = tonumber(hitboxTransparencyInput.Text)
                if value and value >= 0 and value <= 1 then
                    setHitboxTransparency(value)
                else
                    hitboxTransparencyInput.Text = tostring(HITBOX_TRANSPARENCY)
                    if searchResult then
                        searchResult.Text = "Transparencia invalida (0-1)"
                        searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
                        task.wait(2)
                        if searchResult.Text:find("invalida") then
                            searchResult.Text = "Presiona Enter para buscar"
                            searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
                        end
                    end
                end
            end
        end)
    end
    
    if walkSpeedInput then
        walkSpeedInput.FocusLost:Connect(function(enter)
            if enter then
                local value = tonumber(walkSpeedInput.Text)
                if value and value >= 0.1 and value <= 500 then
                    setWalkSpeed(value)
                else
                    walkSpeedInput.Text = tostring(WalkSpeedValue)
                    if searchResult then
                        searchResult.Text = "Velocidad invalida (0.1-500)"
                        searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
                        task.wait(2)
                        if searchResult.Text:find("invalida") then
                            searchResult.Text = "Presiona Enter para buscar"
                            searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
                        end
                    end
                end
            end
        end)
    end
    
    if tpSpeedInput then
        tpSpeedInput.FocusLost:Connect(function(enter)
            if enter then
                local value = tonumber(tpSpeedInput.Text)
                if value and value >= 0.01 and value <= 50 then
                    setTPSpeed(value)
                else
                    tpSpeedInput.Text = tostring(TPSpeedValue)
                    if searchResult then
                        searchResult.Text = "Velocidad TP invalida (0.01-50)"
                        searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
                        task.wait(2)
                        if searchResult.Text:find("invalida") then
                            searchResult.Text = "Presiona Enter para buscar"
                            searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
                        end
                    end
                end
            end
        end)
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
            searchResult.Text = "El objetivo salio del juego"
            searchResult.TextColor3 = Color3.fromRGB(255, 150, 50)
            task.wait(2)
            searchResult.Text = "Presiona Enter para buscar"
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

-- Teclas:
-- K = Mostrar/Ocultar barra de botones
-- E = Activar/Desactivar Hitbox
-- R = Activar/Desactivar TP Walk
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
setWalkSpeed(16)
setTPSpeed(3)
setHitboxSize(30)
setHitboxTransparency(1)

print("=== HITBOX EXPANDER + MOVEMENT + ANTI-RAGDOLL ===")
print("✅ Dos interfaces separadas y ARRASTRABLES:")
print("   - Barra de botones (HITBOX | TP WALK | ANTI-RAGDOLL)")
print("   - Ventana de configuración (abrir con ⚙️)")
print("✅ Arrastra cualquier interfaz haciendo clic en la barra superior")
print("✅ Hitbox expander (tamaño y transparencia configurables)")
print("✅ Loop WalkSpeed y TP Walk (soporte para 0.01)")
print("✅ Sistema Target con búsqueda parcial")
print("✅ Teclas:")
print("   K = Mostrar/Ocultar barra de botones")
print("   E = Activar/Desactivar HITBOX")
print("   R = Activar/Desactivar TP WALK")
