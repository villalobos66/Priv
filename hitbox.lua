local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Variables principales
local HitboxEnabled = false
local targetPlayer = nil
local exactTargetName = ""

-- ==================== LISTA DE PROHIBIDOS (DESDE GITHUB) ====================
local PROHIBITED_USERS = {}

-- Cargar lista desde GitHub
local function cargarListaProhibidos()
    local success, resultado = pcall(function()
        local url = "https://raw.githubusercontent.com/villalobos66/personalizado/main/LisPro.lua"
        local listaRaw = game:HttpGet(url)
        local listaFunc = loadstring(listaRaw)
        if listaFunc then
            return listaFunc()
        end
        return nil
    end)
    return success and resultado or nil
end

-- Cargar la lista
local listaExterna = cargarListaProhibidos()
if listaExterna and type(listaExterna) == "table" and #listaExterna > 0 then
    PROHIBITED_USERS = listaExterna
    print("✅ Lista de prohibidos cargada desde GitHub. Total: " .. #PROHIBITED_USERS .. " usuarios")
else
    PROHIBITED_USERS = {}
    print("⚠️ No se pudo cargar lista de prohibidos. Lista vacía.")
end

-- Función para verificar si un jugador está prohibido
local function isPlayerProhibited(playerObj)
    if not playerObj then return false end
    if playerObj == player then return false end
    local playerNameLower = playerObj.Name:lower()
    local displayNameLower = playerObj.DisplayName:lower()
    for _, prohibitedName in ipairs(PROHIBITED_USERS) do
        local prohibitedLower = tostring(prohibitedName):lower()
        if playerNameLower == prohibitedLower or displayNameLower == prohibitedLower then
            return true
        end
    end
    return false
end

-- ==================== CONFIGURACIÓN HITBOX ====================
local HITBOX_SIZE = 30
local HITBOX_TRANSPARENCY = 0.5
local HITBOX_COLOR = Color3.fromRGB(255, 0, 0)

-- Funciones de hitbox
local function resetHitbox(target)
    pcall(function()
        if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local rootPart = target.Character.HumanoidRootPart
            rootPart.Size = Vector3.new(2, 2, 1)
            rootPart.Transparency = 1
            rootPart.BrickColor = BrickColor.new("Medium stone grey")
            rootPart.Material = Enum.Material.Plastic
            rootPart.CanCollide = false
            rootPart.Color = Color3.fromRGB(255, 255, 255)
        end
    end)
end

local function resetAllHitboxes()
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= player and not isPlayerProhibited(v) then
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
            rootPart.Color = HITBOX_COLOR
            rootPart.BrickColor = BrickColor.new("Really red")
            rootPart.Material = Enum.Material.SmoothPlastic
            rootPart.CanCollide = false
            rootPart.Reflectance = 0
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

local function updateHitboxes()
    if not HitboxEnabled then
        resetAllHitboxes()
        return
    end
    
    if targetPlayer then
        if shouldHitPlayer(targetPlayer) then
            for _, v in pairs(Players:GetPlayers()) do
                if v ~= player and v ~= targetPlayer and not isPlayerProhibited(v) then
                    resetHitbox(v)
                end
            end
            applyHitboxToPlayer(targetPlayer)
        else
            resetHitbox(targetPlayer)
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

-- ==================== FUNCIONES DE TARGET ====================
local function findPlayerByPartialName(inputText)
    if inputText == "" or inputText:lower() == "todos" or inputText:lower() == "all" then
        return nil, "TODOS"
    end
    local searchText = inputText:lower():gsub("%s+", "")
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and not isPlayerProhibited(p) then
            if p.Name:lower() == searchText then return p, p.Name end
            if p.DisplayName:lower() == searchText then return p, p.DisplayName end
        end
    end
    if #searchText >= 3 then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and not isPlayerProhibited(p) then
                if p.Name:lower():sub(1, #searchText) == searchText then return p, p.Name end
                if p.DisplayName:lower():sub(1, #searchText) == searchText then return p, p.DisplayName end
            end
        end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and not isPlayerProhibited(p) then
                if p.Name:lower():find(searchText, 1, true) then return p, p.Name end
                if p.DisplayName:lower():find(searchText, 1, true) then return p, p.DisplayName end
            end
        end
    end
    if #searchText > 0 and #searchText < 3 then return false, "Mínimo 3 letras" end
    return false, "No encontrado"
end

-- ==================== FUNCIÓN DE ARRASTRE ====================
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

-- ==================== INTERFAZ PRINCIPAL ====================
local function CreateButtonsInterface()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "HitboxGUI"
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
    Title.Text = "⋮⋮ HITBOX EXPANDER ⋮⋮"
    Title.TextColor3 = Color3.fromRGB(200, 200, 255)
    Title.TextSize = 11
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TopBar

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

    local ButtonsContainer = Instance.new("Frame")
    ButtonsContainer.Size = UDim2.new(0.96, 0, 0.55, 0)
    ButtonsContainer.Position = UDim2.new(0.02, 0, 0.48, 0)
    ButtonsContainer.BackgroundTransparency = 1
    ButtonsContainer.Parent = Frame

    hitboxBtn = Instance.new("TextButton")
    hitboxBtn.Size = UDim2.new(1, 0, 1, 0)
    hitboxBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    hitboxBtn.Text = "HITBOX\nOFF"
    hitboxBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    hitboxBtn.Font = Enum.Font.GothamBold
    hitboxBtn.TextSize = 14
    hitboxBtn.TextWrapped = true
    hitboxBtn.Parent = ButtonsContainer

    local hitboxCorner = Instance.new("UICorner")
    hitboxCorner.CornerRadius = UDim.new(0, 8)
    hitboxCorner.Parent = hitboxBtn

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
    Frame.Size = UDim2.new(0, 260, 0, 260)
    Frame.Position = UDim2.new(0.5, -130, 0.5, -130)
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
    hitboxTransparencyInput.Text = "0.5"
    hitboxTransparencyInput.Parent = Content

    local transInputCorner = Instance.new("UICorner")
    transInputCorner.CornerRadius = UDim.new(0, 5)
    transInputCorner.Parent = hitboxTransparencyInput

    hitboxTransparencyLabel = Instance.new("TextLabel")
    hitboxTransparencyLabel.Size = UDim2.new(0.25, 0, 0, 20)
    hitboxTransparencyLabel.Position = UDim2.new(0.7, 0, yOffset, 0)
    hitboxTransparencyLabel.BackgroundTransparency = 1
    hitboxTransparencyLabel.Text = "Trans: 0.5"
    hitboxTransparencyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    hitboxTransparencyLabel.Font = Enum.Font.Gotham
    hitboxTransparencyLabel.TextSize = 9
    hitboxTransparencyLabel.TextXAlignment = Enum.TextXAlignment.Left
    hitboxTransparencyLabel.Parent = Content
    yOffset = yOffset + 0.07

    -- Separador
    local sep1 = Instance.new("Frame")
    sep1.Size = UDim2.new(0.9, 0, 0, 1)
    sep1.Position = UDim2.new(0.05, 0, yOffset, 0)
    sep1.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    sep1.BorderSizePixel = 0
    sep1.Parent = Content
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
    infoLabel.Text = "K=Mostrar | E=Hitbox"
    infoLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextSize = 8
    infoLabel.TextXAlignment = Enum.TextXAlignment.Center
    infoLabel.Parent = Content

    -- CONECTAR EVENTOS DE LOS INPUTS
    hitboxSizeInput.FocusLost:Connect(function(enter)
        if enter then
            local val = tonumber(hitboxSizeInput.Text)
            if val and val >= 0.1 and val <= 100 then
                setHitboxSize(val)
                searchResult.Text = "✓ Tamaño cambiado a " .. val
                searchResult.TextColor3 = Color3.fromRGB(80, 255, 80)
                task.wait(1.5)
                searchResult.Text = "Presiona Enter"
                searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
            else
                hitboxSizeInput.Text = tostring(HITBOX_SIZE)
                searchResult.Text = "✗ Tam inválido (0.1-100)"
                searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
                task.wait(2)
                searchResult.Text = "Presiona Enter"
                searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
            end
        end
    end)

    hitboxTransparencyInput.FocusLost:Connect(function(enter)
        if enter then
            local val = tonumber(hitboxTransparencyInput.Text)
            if val and val >= 0 and val <= 1 then
                setHitboxTransparency(val)
                searchResult.Text = "✓ Transparencia cambiada a " .. val
                searchResult.TextColor3 = Color3.fromRGB(80, 255, 80)
                task.wait(1.5)
                searchResult.Text = "Presiona Enter"
                searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
            else
                hitboxTransparencyInput.Text = tostring(HITBOX_TRANSPARENCY)
                searchResult.Text = "✗ Trans inválida (0-1)"
                searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
                task.wait(2)
                searchResult.Text = "Presiona Enter"
                searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
            end
        end
    end)

    MakeDraggableWithHandle(Frame, TitleBar)

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

configButton.MouseButton1Click:Connect(function()
    configGUI.Enabled = not configGUI.Enabled
end)

closeConfigBtn.MouseButton1Click:Connect(function()
    configGUI.Enabled = false
end)

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
    end
end)

-- Loop principal del hitbox
hitboxConnection = RunService.Heartbeat:Connect(updateHitboxes)

-- Inicialización
updateTargetStatus()
updateHitboxButton()
setHitboxSize(30)
setHitboxTransparency(0.5)

print("=== HITBOX EXPANDER + TARGET ===")
print("✅ Hitbox con transparencia funcional")
print("✅ Sistema de target individual o TODOS")
print("✅ Lista de prohibidos: " .. #PROHIBITED_USERS .. " usuarios")
print("✅ Teclas: K=Mostrar | E=Hitbox")
