-- Script principal con hitbox mejorado
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Variables principales
local HitboxEnabled = false
local targetPlayer = nil
local targetPlayerName = ""
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
local tpWalkBtn = nil
local tpSpeedValueLabel = nil
local hitboxBtn = nil
local targetStatus = nil
local searchResult = nil
local targetBox = nil
local clearTargetBtn = nil
local closestBtn = nil
local content = nil
local mainFrame = nil
local mainScreenGui = nil

-- Conexiones para limpiar
local hitboxConnection = nil

-- Lista de usuarios prohibidos
local PROHIBITED_USERS = {
    "Crxsyx", "LaCoquette6_2", "dewn_sz", "KayKayRirisangel",
    "aupyiaiumb", "nadmire_JL", "Fyro_190", "Msky_nlh",
    "Zdiogobreno042", "diogobreno0421", "Ikaris_BR", "rosado289",
    "grancheroka_br", "ShingekiNoKyojin_17", "Lily_2008063",
    "Purarisa0", "Gatitblox", "angeIovers"
}

-- Funcion para verificar si un jugador esta prohibido
local function isPlayerProhibited(playerObj)
    if not playerObj then return false end
    local playerNameLower = playerObj.Name:lower()
    for _, prohibitedName in ipairs(PROHIBITED_USERS) do
        if playerNameLower == prohibitedName:lower() then
            return true
        end
    end
    local displayNameLower = playerObj.DisplayName:lower()
    for _, prohibitedName in ipairs(PROHIBITED_USERS) do
        if displayNameLower == prohibitedName:lower() then
            return true
        end
    end
    return false
end

-- Funcion para buscar jugador por nombre parcial
local function findPlayerByPartialName(inputText)
    if inputText == "" or inputText:lower() == "todos" or inputText:lower() == "all" then
        return nil, "TODOS"
    end
    local searchText = inputText:lower():gsub("%s+", "")
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and not isPlayerProhibited(p) then
            if p.Name:lower() == searchText then
                return p, p.Name
            end
            if p.DisplayName:lower() == searchText then
                return p, p.DisplayName
            end
        end
    end
    if #searchText >= 3 then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and not isPlayerProhibited(p) then
                if p.Name:lower():sub(1, #searchText) == searchText then
                    return p, p.Name
                end
            end
        end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and not isPlayerProhibited(p) then
                if p.DisplayName:lower():sub(1, #searchText) == searchText then
                    return p, p.DisplayName
                end
            end
        end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and not isPlayerProhibited(p) then
                if p.Name:lower():find(searchText, 1, true) then
                    return p, p.Name
                end
            end
        end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and not isPlayerProhibited(p) then
                if p.DisplayName:lower():find(searchText, 1, true) then
                    return p, p.DisplayName
                end
            end
        end
    end
    if #searchText > 0 and #searchText < 3 then
        return false, "Minimo 3 letras para buscar"
    end
    return false, "Jugador no encontrado o esta en lista prohibida"
end

-- Funciones del hitbox mejoradas
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
            print("Hitbox aplicado a: " .. target.Name .. " - Tamaño: " .. HITBOX_SIZE)
        end
    end)
end

local function shouldHitPlayer(playerObj)
    if playerObj == player then return false end
    if isPlayerProhibited(playerObj) then return false end
    if not playerObj.Character then return false end
    if not playerObj.Character:FindFirstChild("HumanoidRootPart") then return false end
    return true
end

-- Funcion para actualizar hitboxes mejorada
local function updateHitboxes()
    if not HitboxEnabled then
        resetAllHitboxes()
        return
    end
    
    if targetPlayer then
        -- Modo target: solo afecta al jugador seleccionado
        if shouldHitPlayer(targetPlayer) then
            -- Resetear todos primero
            for _, v in pairs(Players:GetPlayers()) do
                if v ~= player and v ~= targetPlayer then
                    resetHitbox(v)
                end
            end
            -- Aplicar al target
            applyHitboxToPlayer(targetPlayer)
        end
    else
        -- Modo normal: afecta a todos los jugadores excepto prohibidos
        for _, v in pairs(Players:GetPlayers()) do
            if shouldHitPlayer(v) then
                applyHitboxToPlayer(v)
            else
                resetHitbox(v)
            end
        end
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
            if humanoid and humanoid.WalkSpeed ~= WalkSpeedValue then
                pcall(function()
                    humanoid.WalkSpeed = WalkSpeedValue
                end)
            end
        end)
    end
end

local function setWalkSpeed(value)
    WalkSpeedValue = value
    local humanoid = getHumanoid()
    if humanoid then
        pcall(function()
            humanoid.WalkSpeed = value
        end)
    end
    if walkSpeedValueLabel then
        walkSpeedValueLabel.Text = "Velocidad actual: " .. value
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
    TPSpeedValue = value
    if tpSpeedValueLabel then
        tpSpeedValueLabel.Text = "Velocidad TP: " .. value
    end
end

local function setTPWalkEnabled(enabled)
    TPWalkEnabled = enabled
    setupTPWalk()
    
    if tpWalkBtn then
        if enabled then
            tpWalkBtn.Text = "TP WALK: ON"
            tpWalkBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
            tpWalkBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
        else
            tpWalkBtn.Text = "TP WALK: OFF"
            tpWalkBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
            tpWalkBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        end
    end
end

-- Loop principal del hitbox con Heartbeat para mejor rendimiento
hitboxConnection = RunService.Heartbeat:Connect(updateHitboxes)

-- Crear GUI con movimiento táctil mejorado
local function CreateMainFrame(titleText, sizeX, sizeY)
    sizeX = sizeX or 280
    sizeY = sizeY or 420

    local existingGui = player.PlayerGui:FindFirstChild("HitboxGUI")
    if existingGui then
        existingGui:Destroy()
    end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "HitboxGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = player.PlayerGui

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, sizeX, 0, sizeY)
    Frame.Position = UDim2.new(0.5, -sizeX/2, 0.5, -sizeY/2)
    Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Frame.BorderSizePixel = 0
    Frame.ClipsDescendants = true
    Frame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 9)
    UICorner.Parent = Frame

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(255, 255, 255)
    UIStroke.Transparency = 0.4
    UIStroke.Thickness = 1.1
    UIStroke.Parent = Frame

    -- Barra de título
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 30)
    TitleBar.BackgroundTransparency = 1
    TitleBar.Parent = Frame

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(0.7, 0, 1, 0)
    Title.Position = UDim2.new(0, 9, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = titleText or "Hitbox Expander + Movement"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 14
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TitleBar

    local MinimizeButton = Instance.new("TextButton")
    MinimizeButton.Size = UDim2.new(0, 26, 0, 26)
    MinimizeButton.Position = UDim2.new(1, -60, 0, 2)
    MinimizeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    MinimizeButton.Text = "-"
    MinimizeButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    MinimizeButton.Font = Enum.Font.GothamBold
    MinimizeButton.TextSize = 18
    MinimizeButton.Parent = TitleBar

    local MinCorner = Instance.new("UICorner")
    MinCorner.CornerRadius = UDim.new(0, 6)
    MinCorner.Parent = MinimizeButton

    local DeleteButton = Instance.new("TextButton")
    DeleteButton.Size = UDim2.new(0, 26, 0, 26)
    DeleteButton.Position = UDim2.new(1, -32, 0, 2)
    DeleteButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    DeleteButton.Text = "X"
    DeleteButton.TextColor3 = Color3.fromRGB(255, 220, 220)
    DeleteButton.Font = Enum.Font.GothamBold
    DeleteButton.TextSize = 17
    DeleteButton.Parent = TitleBar

    local DelCorner = Instance.new("UICorner")
    DelCorner.CornerRadius = UDim.new(0, 6)
    DelCorner.Parent = DeleteButton

    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, 0, 1, -30)
    Content.Position = UDim2.new(0, 0, 0, 30)
    Content.BackgroundTransparency = 1
    Content.Parent = Frame

    local minimized = false
    local originalSizeY = sizeY

    MinimizeButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            Frame.Size = UDim2.new(0, sizeX, 0, 30)
            MinimizeButton.Text = "+"
            Content.Visible = false
        else
            Frame.Size = UDim2.new(0, sizeX, 0, originalSizeY)
            MinimizeButton.Text = "-"
            Content.Visible = true
        end
    end)

    DeleteButton.MouseButton1Click:Connect(function()
        if loopWalkSpeedConnection then loopWalkSpeedConnection:Disconnect() end
        if tpWalkConnection then tpWalkConnection:Disconnect() end
        if hitboxConnection then hitboxConnection:Disconnect() end
        Frame:Destroy()
        ScreenGui:Destroy()
    end)

    -- Sistema de arrastre mejorado
    local dragging = false
    local dragStart = nil
    local startPos = nil
    local dragConnection = nil
    local dragEndConnection = nil
    
    local function startDrag(input)
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
        
        dragConnection = UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
               input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                Frame.Position = UDim2.new(
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
    
    Frame.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            
            local target = UserInputService:GetMouseTarget()
            local isInteractiveButton = false
            
            if target then
                local current = target
                while current and current ~= Frame do
                    if (current:IsA("TextButton") and (current == MinimizeButton or current == DeleteButton)) or
                       current:IsA("TextBox") then
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

    return Content, Frame, ScreenGui
end

-- Esperar a que el personaje cargue
repeat task.wait() until player.Character and player.Character:FindFirstChild("Humanoid")

-- Crear GUI
content, mainFrame, mainScreenGui = CreateMainFrame("Hitbox Expander + Movement", 280, 420)

-- Seccion HITBOX
local hitboxSection = Instance.new("TextLabel")
hitboxSection.Size = UDim2.new(0.85, 0, 0, 20)
hitboxSection.Position = UDim2.new(0.075, 0, 0, 0)
hitboxSection.BackgroundTransparency = 1
hitboxSection.Text = "----- HITBOX -----"
hitboxSection.TextColor3 = Color3.fromRGB(255, 200, 100)
hitboxSection.Font = Enum.Font.GothamBold
hitboxSection.TextSize = 11
hitboxSection.TextXAlignment = Enum.TextXAlignment.Center
hitboxSection.Parent = content

-- Boton principal de activacion
hitboxBtn = Instance.new("TextButton")
hitboxBtn.Size = UDim2.new(0.85, 0, 0, 35)
hitboxBtn.Position = UDim2.new(0.075, 0, 0.07, 0)
hitboxBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
hitboxBtn.Text = "HITBOX: OFF"
hitboxBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
hitboxBtn.Font = Enum.Font.GothamBold
hitboxBtn.TextSize = 13
hitboxBtn.Parent = content

local hitboxCorner = Instance.new("UICorner")
hitboxCorner.CornerRadius = UDim.new(0, 8)
hitboxCorner.Parent = hitboxBtn

-- Info del hitbox
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(0.85, 0, 0, 18)
infoLabel.Position = UDim2.new(0.075, 0, 0.12, 0)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "Tamano: " .. HITBOX_SIZE .. " | Transparente"
infoLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 10
infoLabel.TextXAlignment = Enum.TextXAlignment.Center
infoLabel.Parent = content

-- Separador
local separator1 = Instance.new("Frame")
separator1.Size = UDim2.new(0.85, 0, 0, 1)
separator1.Position = UDim2.new(0.075, 0, 0.16, 0)
separator1.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
separator1.BorderSizePixel = 0
separator1.Parent = content

-- Seccion MOVIMIENTO
local movementSection = Instance.new("TextLabel")
movementSection.Size = UDim2.new(0.85, 0, 0, 20)
movementSection.Position = UDim2.new(0.075, 0, 0.19, 0)
movementSection.BackgroundTransparency = 1
movementSection.Text = "----- MOVIMIENTO -----"
movementSection.TextColor3 = Color3.fromRGB(255, 200, 100)
movementSection.Font = Enum.Font.GothamBold
movementSection.TextSize = 11
movementSection.TextXAlignment = Enum.TextXAlignment.Center
movementSection.Parent = content

-- Boton Loop WalkSpeed
walkSpeedBtn = Instance.new("TextButton")
walkSpeedBtn.Size = UDim2.new(0.85, 0, 0, 32)
walkSpeedBtn.Position = UDim2.new(0.075, 0, 0.24, 0)
walkSpeedBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
walkSpeedBtn.Text = "LOOP WALKSPEED: OFF"
walkSpeedBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
walkSpeedBtn.Font = Enum.Font.GothamBold
walkSpeedBtn.TextSize = 12
walkSpeedBtn.Parent = content

local walkSpeedCorner = Instance.new("UICorner")
walkSpeedCorner.CornerRadius = UDim.new(0, 8)
walkSpeedCorner.Parent = walkSpeedBtn

-- Valor de WalkSpeed
walkSpeedValueLabel = Instance.new("TextLabel")
walkSpeedValueLabel.Size = UDim2.new(0.85, 0, 0, 18)
walkSpeedValueLabel.Position = UDim2.new(0.075, 0, 0.285, 0)
walkSpeedValueLabel.BackgroundTransparency = 1
walkSpeedValueLabel.Text = "Velocidad actual: 16"
walkSpeedValueLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
walkSpeedValueLabel.Font = Enum.Font.Gotham
walkSpeedValueLabel.TextSize = 10
walkSpeedValueLabel.TextXAlignment = Enum.TextXAlignment.Center
walkSpeedValueLabel.Parent = content

-- Input para WalkSpeed
local walkSpeedInput = Instance.new("TextBox")
walkSpeedInput.Size = UDim2.new(0.4, 0, 0, 25)
walkSpeedInput.Position = UDim2.new(0.075, 0, 0.32, 0)
walkSpeedInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
walkSpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
walkSpeedInput.Font = Enum.Font.Gotham
walkSpeedInput.TextSize = 11
walkSpeedInput.PlaceholderText = "Velocidad (16-100)"
walkSpeedInput.Text = "16"
walkSpeedInput.Parent = content

local wsInputCorner = Instance.new("UICorner")
wsInputCorner.CornerRadius = UDim.new(0, 6)
wsInputCorner.Parent = walkSpeedInput

-- Boton TP Walk
tpWalkBtn = Instance.new("TextButton")
tpWalkBtn.Size = UDim2.new(0.85, 0, 0, 32)
tpWalkBtn.Position = UDim2.new(0.075, 0, 0.37, 0)
tpWalkBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
tpWalkBtn.Text = "TP WALK: OFF"
tpWalkBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
tpWalkBtn.Font = Enum.Font.GothamBold
tpWalkBtn.TextSize = 12
tpWalkBtn.Parent = content

local tpWalkCorner = Instance.new("UICorner")
tpWalkCorner.CornerRadius = UDim.new(0, 8)
tpWalkCorner.Parent = tpWalkBtn

-- Valor de TP Speed
tpSpeedValueLabel = Instance.new("TextLabel")
tpSpeedValueLabel.Size = UDim2.new(0.85, 0, 0, 18)
tpSpeedValueLabel.Position = UDim2.new(0.075, 0, 0.415, 0)
tpSpeedValueLabel.BackgroundTransparency = 1
tpSpeedValueLabel.Text = "Velocidad TP: 3"
tpSpeedValueLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
tpSpeedValueLabel.Font = Enum.Font.Gotham
tpSpeedValueLabel.TextSize = 10
tpSpeedValueLabel.TextXAlignment = Enum.TextXAlignment.Center
tpSpeedValueLabel.Parent = content

-- Input para TP Speed
local tpSpeedInput = Instance.new("TextBox")
tpSpeedInput.Size = UDim2.new(0.4, 0, 0, 25)
tpSpeedInput.Position = UDim2.new(0.075, 0, 0.45, 0)
tpSpeedInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
tpSpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
tpSpeedInput.Font = Enum.Font.Gotham
tpSpeedInput.TextSize = 11
tpSpeedInput.PlaceholderText = "Velocidad TP (1-20)"
tpSpeedInput.Text = "3"
tpSpeedInput.Parent = content

local tpInputCorner = Instance.new("UICorner")
tpInputCorner.CornerRadius = UDim.new(0, 6)
tpInputCorner.Parent = tpSpeedInput

-- Separador
local separator2 = Instance.new("Frame")
separator2.Size = UDim2.new(0.85, 0, 0, 1)
separator2.Position = UDim2.new(0.075, 0, 0.49, 0)
separator2.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
separator2.BorderSizePixel = 0
separator2.Parent = content

-- Seccion TARGET
local targetSection = Instance.new("TextLabel")
targetSection.Size = UDim2.new(0.85, 0, 0, 20)
targetSection.Position = UDim2.new(0.075, 0, 0.52, 0)
targetSection.BackgroundTransparency = 1
targetSection.Text = "----- SISTEMA TARGET -----"
targetSection.TextColor3 = Color3.fromRGB(255, 200, 100)
targetSection.Font = Enum.Font.GothamBold
targetSection.TextSize = 11
targetSection.TextXAlignment = Enum.TextXAlignment.Center
targetSection.Parent = content

-- Campo de busqueda
targetBox = Instance.new("TextBox")
targetBox.Size = UDim2.new(0.85, 0, 0, 28)
targetBox.Position = UDim2.new(0.075, 0, 0.57, 0)
targetBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
targetBox.TextColor3 = Color3.fromRGB(255, 255, 255)
targetBox.Font = Enum.Font.Gotham
targetBox.TextSize = 12
targetBox.PlaceholderText = "Escribe 3+ letras para buscar"
targetBox.Text = ""
targetBox.Parent = content

local targetCorner = Instance.new("UICorner")
targetCorner.CornerRadius = UDim.new(0, 6)
targetCorner.Parent = targetBox

-- Estado del target
targetStatus = Instance.new("TextLabel")
targetStatus.Size = UDim2.new(0.85, 0, 0, 18)
targetStatus.Position = UDim2.new(0.075, 0, 0.62, 0)
targetStatus.BackgroundTransparency = 1
targetStatus.Text = "Objetivo actual: TODOS"
targetStatus.TextColor3 = Color3.fromRGB(120, 200, 255)
targetStatus.Font = Enum.Font.Gotham
targetStatus.TextSize = 10
targetStatus.TextXAlignment = Enum.TextXAlignment.Left
targetStatus.Parent = content

-- Mensaje de resultado
searchResult = Instance.new("TextLabel")
searchResult.Size = UDim2.new(0.85, 0, 0, 18)
searchResult.Position = UDim2.new(0.075, 0, 0.66, 0)
searchResult.BackgroundTransparency = 1
searchResult.Text = "Presiona Enter para buscar"
searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
searchResult.Font = Enum.Font.Gotham
searchResult.TextSize = 9
searchResult.TextXAlignment = Enum.TextXAlignment.Left
searchResult.TextWrapped = true
searchResult.Parent = content

-- Botones horizontales
local buttonContainer = Instance.new("Frame")
buttonContainer.Size = UDim2.new(0.85, 0, 0, 30)
buttonContainer.Position = UDim2.new(0.075, 0, 0.70, 0)
buttonContainer.BackgroundTransparency = 1
buttonContainer.Parent = content

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
        targetPlayerName = exactTargetName
        updateTargetStatus()
        searchResult.Text = "Encontrado: " .. exactTargetName
        searchResult.TextColor3 = Color3.fromRGB(80, 255, 80)
    elseif foundPlayer == nil then
        targetPlayer = nil
        exactTargetName = "TODOS"
        targetPlayerName = ""
        updateTargetStatus()
        searchResult.Text = "Modo: TODOS"
        searchResult.TextColor3 = Color3.fromRGB(120, 200, 255)
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
        if v ~= player and not isPlayerProhibited(v) then
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
        targetPlayerName = closestPlayer.Name
        updateTargetStatus()
        targetBox.Text = closestPlayer.Name
        searchResult.Text = "Target mas cercano: " .. exactTargetName
        searchResult.TextColor3 = Color3.fromRGB(80, 255, 80)
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
    targetPlayerName = ""
    targetBox.Text = ""
    updateTargetStatus()
    searchResult.Text = "Target limpiado - Modo TODOS"
    searchResult.TextColor3 = Color3.fromRGB(120, 200, 255)
    task.wait(2)
    searchResult.Text = "Presiona Enter para buscar"
    searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
end

-- Conectar eventos
hitboxBtn.MouseButton1Click:Connect(function()
    HitboxEnabled = not HitboxEnabled
    if HitboxEnabled then
        hitboxBtn.Text = "HITBOX: ON"
        hitboxBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
        hitboxBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
        print("Hitbox activado - Tamano: " .. HITBOX_SIZE)
        -- Aplicar inmediatamente
        updateHitboxes()
    else
        hitboxBtn.Text = "HITBOX: OFF"
        hitboxBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
        hitboxBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        print("Hitbox desactivado")
        resetAllHitboxes()
    end
end)

walkSpeedBtn.MouseButton1Click:Connect(function()
    setWalkSpeedEnabled(not WalkSpeedEnabled)
end)

walkSpeedInput.FocusLost:Connect(function(enter)
    if enter then
        local value = tonumber(walkSpeedInput.Text)
        if value and value >= 16 and value <= 500 then
            setWalkSpeed(value)
        else
            walkSpeedInput.Text = tostring(WalkSpeedValue)
            searchResult.Text = "Velocidad invalida (16-500)"
            searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
            task.wait(2)
            if searchResult.Text:find("invalida") then
                searchResult.Text = "Presiona Enter para buscar"
                searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
            end
        end
    end
end)

tpWalkBtn.MouseButton1Click:Connect(function()
    setTPWalkEnabled(not TPWalkEnabled)
end)

tpSpeedInput.FocusLost:Connect(function(enter)
    if enter then
        local value = tonumber(tpSpeedInput.Text)
        if value and value >= 1 and value <= 50 then
            setTPSpeed(value)
        else
            tpSpeedInput.Text = tostring(TPSpeedValue)
            searchResult.Text = "Velocidad TP invalida (1-50)"
            searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
            task.wait(2)
            if searchResult.Text:find("invalida") then
                searchResult.Text = "Presiona Enter para buscar"
                searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
            end
        end
    end
end)

targetBox.FocusLost:Connect(function(enter)
    if enter then searchAndSetTarget() end
end)

clearTargetBtn.MouseButton1Click:Connect(clearTarget)
closestBtn.MouseButton1Click:Connect(targetClosest)

-- Actualizar cuando un jugador sale
Players.PlayerRemoving:Connect(function(p)
    if targetPlayer == p then
        targetPlayer = nil
        exactTargetName = "TODOS"
        targetBox.Text = ""
        updateTargetStatus()
        searchResult.Text = "El objetivo salio del juego"
        searchResult.TextColor3 = Color3.fromRGB(255, 150, 50)
        task.wait(2)
        searchResult.Text = "Presiona Enter para buscar"
        searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end)

-- Detectar cuando un jugador entra para aplicar hitbox si está activado
Players.PlayerAdded:Connect(function(p)
    task.wait(1) -- Esperar a que el personaje cargue
    if HitboxEnabled and shouldHitPlayer(p) then
        applyHitboxToPlayer(p)
    end
end)

-- Detectar cuando el personaje de un jugador aparece
local function onCharacterAdded(playerObj, character)
    task.wait(0.5)
    if HitboxEnabled and shouldHitPlayer(playerObj) then
        applyHitboxToPlayer(playerObj)
    end
end

for _, p in pairs(Players:GetPlayers()) do
    p.CharacterAdded:Connect(function(character)
        onCharacterAdded(p, character)
    end)
end

-- Tecla para abrir/cerrar (F)
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.F then
        if mainFrame then
            mainFrame.Visible = not mainFrame.Visible
        end
    end
end)

-- Inicializacion
updateTargetStatus()
setWalkSpeed(16)
setTPSpeed(3)

print("Hitbox Expander + Movement cargado")
print("Hitbox: Tamano " .. HITBOX_SIZE .. " | Transparente")
print("Loop WalkSpeed: OFF | TP Walk: OFF")
print("Tecla F para abrir/cerrar")
print("Arrastra cualquier parte de la ventana para moverla")
