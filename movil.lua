local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer

-- Variables principales
local KillAuraEnabled = false
local ESPEnabled = false
local originalSizes = {}
local collectConnection = nil
local espConnection = nil
local lastAttackTime = 0
local targetPlayer = nil
local targetPlayerName = ""
local exactTargetName = ""

-- Variables globales para ESP
_G.FriendColor = Color3.fromRGB(0, 0, 255)
_G.EnemyColor = Color3.fromRGB(255, 0, 0)
_G.UseTeamColor = true

-- Variables para WalkSpeed
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

if not _G.Walkspeed then _G.Walkspeed = humanoid.WalkSpeed end
if not _G.loopW then _G.loopW = false end
if not _G.TPSpeed then _G.TPSpeed = 1 end
if not _G.TPWalk then _G.TPWalk = false end

getgenv().Walkspeed = _G.Walkspeed
getgenv().loopW = _G.loopW
getgenv().TPSpeed = _G.TPSpeed
getgenv().TPWalk = _G.TPWalk

local Holder
local playerConnections = {}

local PROHIBITED_USERS = {
    "Crxsyx",
    "LaCoquette6_2",
    "dewn_sz",
    "KayKayRirisangel",
    "nadmire_JL",
    "Fyro_190",
    "Msky_nlh",
    "Zdiogobreno042",
    "diogobreno0421",
    "Ikaris_BR",
    "rosado289",
    "grancheroka_br",
    "ShingekiNoKyojin_17",
    "lIIllIllllIIIlIlIlII",
    "lIIllIllllIIIlIlIlI",
    "lIIllIllllIIIlIlIll",
    "lIIllIllllIIIlIlII",
    "lIIllIllllIIIlIlIl",
    "Lily_2008063",
    "Purarisa0",
    "Gatitblox",
    "angeIovers",
    "An_uelAA1",
    "Lily_123nsw",
    "MYNAMEISJEFF711",
    "LaPuchainaaaa6",
    "mmelii_rdz",
    "lilianhofttee",
    "Alex2g36",
    "darkissoez",
    "darkissoez1",
    "darkissoez2",
    "darkissoez3",
    "darkissoez4",
    "darkissoez5",
    "darkissoez6",
    "darkissoez7",
    "darkissoez8",
    "darkissoez9",
    "darkissoez10",
    "darkissoez11",
    "darkissoez12",
    "darkissoez13",
    "darkissoez14",
    "darkissoez15",
    "darkissoez16",
    "darkissoez17",
    "botfuerte1",
    "botfuerte2",
    "botfuerte3",
    "botfuerte4",
    "botfuerte5",
    "botfuerte6",
    "botfuerte7",
    "botfuerte8",
    "botfuerte9",
    "botfuerte10",
    "botfuerte11",
    "botfuerte12",
    "botfuerte13",
    "cuffedoll",
    "bloodalt2020",
    "crxsyx121",
    "serranito206",
    "Backpackboy40",
    "Belt_kim",
    "mmaria_207",
    "rotto44",
    "trunksalexzander123",
    "xxdeidaraxx50",
    "ikanaide08",
    "naoshecid0108",
    "Mailu_7500"	
}

local attacksPerSecond = 1000
local attackCooldown = 1 / attacksPerSecond
local AURA_RANGE = 75

local HitRemote = game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("CombatService"):WaitForChild("RF"):WaitForChild("Hit")

-- ==================== SISTEMA DE INVISIBILIDAD FALSA ORIGINAL ====================
do
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")

    local LocalPlayer = Players.LocalPlayer
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local Humanoid = Character:WaitForChild("Humanoid")
    local RootPart = Humanoid.RootPart

    local MODE_CONFIG = {
        ["Estático"] = {
            DepthStuds = 6000,
            VerticalOffset = Vector3.new(0, -6000, 0),
            ApplyRotation = true,
            RotationCFrame = CFrame.Angles(0, 0, math.rad(180)),
            Description = "60 studs, boca abajo"
        },
        ["Parpadeo"] = {
            DepthStuds = 300,
            VerticalOffset = Vector3.new(0, -300, 0),
            ApplyRotation = true,
            RotationCFrame = CFrame.Angles(0, 0, math.rad(180)),
            Description = "Parpadea cada 0.7s"
        },
        ["AntiHS"] = {
            DepthStuds = 4.5,
            VerticalOffset = Vector3.new(0, -4.5, 0),
            ApplyRotation = false,
            RotationCFrame = CFrame.identity,
            Description = "4.5 studs, de pie (movimiento normal)"
        }
    }

    local OldPosition = RootPart.CFrame
    local LastRootCFrame = RootPart.CFrame
    local IsEnabled = false
    local FakeMode = "Estático"
    local Connections = {}
    local RenderSteps = {}

    local HighlightInstance = Instance.new("Highlight")
    HighlightInstance.Adornee = Character
    HighlightInstance.Enabled = true
    HighlightInstance.FillColor = Color3.fromRGB(255, 255, 0)
    HighlightInstance.OutlineColor = Color3.fromRGB(255, 200, 0)
    HighlightInstance.FillTransparency = 0.5
    HighlightInstance.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    HighlightInstance.Parent = game:GetService("CoreGui")

    local function GenerateUniqueName()
        return "FakeStep_" .. tostring(tick()) .. "_" .. math.random(1000, 9999)
    end

    local function Cleanup()
        for _, conn in ipairs(Connections) do
            conn:Disconnect()
        end
        Connections = {}
        for _, step in ipairs(RenderSteps) do
            RunService:UnbindFromRenderStep(step)
        end
        RenderSteps = {}
    end

    local function ActivateStaticMode(modeName)
        if IsEnabled then return end
        local config = MODE_CONFIG[modeName] or MODE_CONFIG["Estático"]
        
        Cleanup()
        IsEnabled = true
        OldPosition = RootPart.CFrame
        LastRootCFrame = RootPart.CFrame

        local step1 = GenerateUniqueName()
        local step2 = GenerateUniqueName()

        RunService:BindToRenderStep(step1, Enum.RenderPriority.Camera.Value - 5, function()
            if RootPart and IsEnabled then
                RootPart.CFrame = LastRootCFrame
            end
        end)
        table.insert(RenderSteps, step1)

        RunService:BindToRenderStep(step2, Enum.RenderPriority.Camera.Value + 5, function()
            if RootPart and IsEnabled then
                LastRootCFrame = RootPart.CFrame
                local newPosition = RootPart.Position + config.VerticalOffset
                local newCFrame
                if config.ApplyRotation then
                    newCFrame = CFrame.new(newPosition) * config.RotationCFrame
                else
                    newCFrame = CFrame.new(newPosition) * (RootPart.CFrame - RootPart.Position)
                end
                RootPart.CFrame = newCFrame
            end
        end)
        table.insert(RenderSteps, step2)

        table.insert(Connections, RunService.PreAnimation:Connect(function()
            if RootPart and IsEnabled then
                RootPart.CFrame = LastRootCFrame
            end
        end))

        table.insert(Connections, RunService.PostSimulation:Connect(function()
            if RootPart and IsEnabled then
                LastRootCFrame = RootPart.CFrame
                local newPosition = RootPart.Position + config.VerticalOffset
                local newCFrame
                if config.ApplyRotation then
                    newCFrame = CFrame.new(newPosition) * config.RotationCFrame
                else
                    newCFrame = CFrame.new(newPosition) * (RootPart.CFrame - RootPart.Position)
                end
                RootPart.CFrame = newCFrame
            end
        end))
    end

    local function ActivateLoopMode()
        if IsEnabled then return end
        local config = MODE_CONFIG["Parpadeo"]
        
        IsEnabled = true
        task.spawn(function()
            while IsEnabled and FakeMode == "Parpadeo" do
                Cleanup()
                OldPosition = RootPart.CFrame
                LastRootCFrame = RootPart.CFrame
                
                local step1 = GenerateUniqueName()
                local step2 = GenerateUniqueName()

                RunService:BindToRenderStep(step1, Enum.RenderPriority.Camera.Value - 5, function()
                    if RootPart and IsEnabled then
                        RootPart.CFrame = LastRootCFrame
                    end
                end)
                table.insert(RenderSteps, step1)

                RunService:BindToRenderStep(step2, Enum.RenderPriority.Camera.Value + 5, function()
                    if RootPart and IsEnabled then
                        LastRootCFrame = RootPart.CFrame
                        local newPosition = RootPart.Position + config.VerticalOffset
                        local newCFrame = CFrame.new(newPosition) * config.RotationCFrame
                        RootPart.CFrame = newCFrame
                    end
                end)
                table.insert(RenderSteps, step2)

                table.insert(Connections, RunService.PreAnimation:Connect(function()
                    if RootPart and IsEnabled then
                        RootPart.CFrame = LastRootCFrame
                    end
                end))

                table.insert(Connections, RunService.PostSimulation:Connect(function()
                    if RootPart and IsEnabled then
                        LastRootCFrame = RootPart.CFrame
                        local newPosition = RootPart.Position + config.VerticalOffset
                        local newCFrame = CFrame.new(newPosition) * config.RotationCFrame
                        RootPart.CFrame = newCFrame
                    end
                end))

                task.wait(0.7)
                
                if not IsEnabled or FakeMode ~= "Parpadeo" then break end
                Cleanup()
                if RootPart then 
                    RootPart.CFrame = LastRootCFrame
                end
                
                task.wait(0.1)
            end
        end)
    end

    local function DeactivateFakeInvisibility()
        if not IsEnabled then return end
        IsEnabled = false
        Cleanup()
        if RootPart then
            RootPart.CFrame = LastRootCFrame
        end
    end

    local function ToggleFakeMode()
        local modes = {"Estático", "Parpadeo", "AntiHS"}
        local currentIndex = 1
        for i, mode in ipairs(modes) do
            if mode == FakeMode then
                currentIndex = i
                break
            end
        end
        
        local nextIndex = (currentIndex % #modes) + 1
        local newMode = modes[nextIndex]
        
        local wasEnabled = IsEnabled
        DeactivateFakeInvisibility()
        
        FakeMode = newMode
        
        if wasEnabled then
            if FakeMode == "Parpadeo" then
                ActivateLoopMode()
            else
                ActivateStaticMode(FakeMode)
            end
        end
        
        return FakeMode
    end

    local function ToggleFakeInvisibility()
        if IsEnabled then
            DeactivateFakeInvisibility()
        else
            if FakeMode == "Parpadeo" then
                ActivateLoopMode()
            else
                ActivateStaticMode(FakeMode)
            end
        end
    end

    _G.ToggleFakeInvis = ToggleFakeInvisibility
    _G.ToggleFakeMode = ToggleFakeMode
    _G.GetFakeMode = function() return FakeMode end
    _G.IsFakeInvisEnabled = function() return IsEnabled end
    _G.GetModeDescription = function() return MODE_CONFIG[FakeMode].Description end

    LocalPlayer.CharacterAdded:Connect(function(newChar)
        Character = newChar
        Humanoid = newChar:WaitForChild("Humanoid")
        RootPart = Humanoid.RootPart
        OldPosition = RootPart.CFrame
        LastRootCFrame = RootPart.CFrame
        HighlightInstance.Adornee = Character
        
        if IsEnabled then
            task.wait(0.1)
            IsEnabled = false
            if FakeMode == "Parpadeo" then
                ActivateLoopMode()
            else
                ActivateStaticMode(FakeMode)
            end
        end
    end)
end

-- ==================== FUNCIONES AUXILIARES ====================
local function isPlayerProhibited(playerObj)
    if not playerObj then return false end
    for _, prohibitedName in ipairs(PROHIBITED_USERS) do
        if playerObj.Name:lower() == prohibitedName:lower() or playerObj.DisplayName:lower() == prohibitedName:lower() then
            return true
        end
    end
    return false
end

local function findPlayerByPartialName(inputText)
    if inputText == "" or inputText:lower() == "todos" or inputText:lower() == "all" then
        return nil, "TODOS"
    end
    local searchText = inputText:lower():gsub("%s+", "")
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and not isPlayerProhibited(p) then
            if p.Name:lower() == searchText or p.DisplayName:lower() == searchText then
                return p, p.Name
            end
        end
    end
    if #searchText >= 3 then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and not isPlayerProhibited(p) then
                if p.Name:lower():sub(1, #searchText) == searchText or p.DisplayName:lower():sub(1, #searchText) == searchText then
                    return p, p.Name
                end
            end
        end
    end
    return false, "Jugador no encontrado"
end

-- ==================== ESP ====================
local function createESP(playerObj)
    if not playerObj or playerObj == player or isPlayerProhibited(playerObj) or not ESPEnabled then return end

    if not Holder or not Holder.Parent then
        Holder = Instance.new("Folder", game.CoreGui)
        Holder.Name = "ESP_" .. tostring(tick())
    end

    local vHolder = Holder:FindFirstChild(playerObj.Name)
    if vHolder then vHolder:Destroy() end

    vHolder = Instance.new("Folder")
    vHolder.Name = playerObj.Name
    vHolder.Parent = Holder
    playerConnections[playerObj] = {}

    local function applyESPToCharacter(character)
        if not character or not ESPEnabled then return end
        task.spawn(function()
            local hrp = character:WaitForChild("HumanoidRootPart", 2)
            if not hrp then return end

            local box = Instance.new("BoxHandleAdornment")
            box.Size = Vector3.new(4, 7, 4)
            box.Transparency = 0.7
            box.AlwaysOnTop = true
            box.Adornee = hrp
            box.Parent = vHolder

            local nameTag = Instance.new("BillboardGui")
            nameTag.Size = UDim2.new(0, 200, 0, 50)
            nameTag.AlwaysOnTop = true
            nameTag.StudsOffset = Vector3.new(0, 5, 0)
            nameTag.Adornee = hrp
            nameTag.Parent = vHolder

            local tag = Instance.new("TextLabel", nameTag)
            tag.BackgroundTransparency = 1
            tag.Size = UDim2.new(0, 300, 0, 20)
            tag.TextSize = 22
            tag.TextStrokeTransparency = 0.4
            tag.Text = playerObj.Name
            tag.Font = Enum.Font.SourceSansBold

            local highlight = Instance.new("Highlight")
            highlight.Adornee = character
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.FillTransparency = 0.5
            highlight.Parent = vHolder

            local color = _G.UseTeamColor and playerObj.TeamColor.Color or 
                ((player.TeamColor == playerObj.TeamColor) and _G.FriendColor or _G.EnemyColor)
            box.Color3 = color
            tag.TextColor3 = color
            highlight.FillColor = color
        end)
    end

    if playerObj.Character then applyESPToCharacter(playerObj.Character) end

    local charConnection = playerObj.CharacterAdded:Connect(function(character)
        task.wait(0.5)
        if ESPEnabled and vHolder.Parent then applyESPToCharacter(character) end
    end)
    playerConnections[playerObj].charConnection = charConnection
end

local function removeESP(playerObj)
    if playerConnections[playerObj] and playerConnections[playerObj].charConnection then
        playerConnections[playerObj].charConnection:Disconnect()
    end
    playerConnections[playerObj] = nil
    if Holder and Holder.Parent then
        local vHolder = Holder:FindFirstChild(playerObj.Name)
        if vHolder then vHolder:Destroy() end
    end
end

local function toggleESP()
    ESPEnabled = not ESPEnabled
    if ESPEnabled then
        if Holder and Holder.Parent then Holder:Destroy() end
        Holder = Instance.new("Folder", game.CoreGui)
        Holder.Name = "ESP_" .. tostring(tick())
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and not isPlayerProhibited(p) then createESP(p) end
        end
        espConnection = Players.PlayerAdded:Connect(function(newPlayer)
            if not isPlayerProhibited(newPlayer) then createESP(newPlayer) end
        end)
    else
        if espConnection then espConnection:Disconnect() end
        for _, connections in pairs(playerConnections) do
            if connections.charConnection then connections.charConnection:Disconnect() end
        end
        playerConnections = {}
        if Holder then Holder:Destroy() end
    end
end

-- ==================== KILL AURA INSTANTÁNEO (SIN RETRASO AL ENCENDER) ====================
local killAuraThread = nil

local function startKillAuraLoop()
    -- Si ya hay un thread corriendo, no crear otro
    if killAuraThread then return end
    
    -- Resetear tiempo de ataque para que ataque inmediatamente
    lastAttackTime = 0
    
    killAuraThread = task.spawn(function()
        -- Cache para máxima velocidad
        local players = Players
        local myPlayer = player
        local remote = HitRemote
        local range = AURA_RANGE
        local myChar, myHRP, myPosition, currentTime
        
        while KillAuraEnabled do
            -- Verificar cada FRAME (máxima velocidad)
            task.wait()
            
            -- Obtener personaje local
            myChar = myPlayer.Character
            if not myChar then continue end
            
            myHRP = myChar:FindFirstChild("HumanoidRootPart")
            if not myHRP then continue end
            
            -- Control de tiempo (ataques por segundo)
            currentTime = tick()
            if currentTime - lastAttackTime < attackCooldown then continue end
            
            myPosition = myHRP.Position
            local closestPlayer = nil
            local closestDist = range
            
            -- Buscar enemigo más cercano
            local playerList = players:GetPlayers()
            for i = 1, #playerList do
                local p = playerList[i]
                
                if p == myPlayer then continue end
                if isPlayerProhibited(p) then continue end
                if targetPlayer and p ~= targetPlayer then continue end
                
                local char = p.Character
                if not char then continue end
                
                local hum = char:FindFirstChild("Humanoid")
                if not hum or hum.Health <= 0 then continue end
                
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hrp then continue end
                
                -- Cálculo de distancia optimizado
                local dx = hrp.Position.X - myPosition.X
                local dy = hrp.Position.Y - myPosition.Y
                local dz = hrp.Position.Z - myPosition.Z
                local distSqr = dx*dx + dy*dy + dz*dz
                
                if distSqr <= closestDist * closestDist then
                    closestDist = math.sqrt(distSqr)
                    closestPlayer = p
                end
            end
            
            -- Atacar inmediatamente si hay enemigo
            if closestPlayer then
                local targetChar = closestPlayer.Character
                if targetChar then
                    local targetHum = targetChar:FindFirstChild("Humanoid")
                    if targetHum and targetHum.Health > 0 then
                        pcall(function()
                            remote:InvokeServer(targetHum, Vector3.new(myPosition.X, myPosition.Y, myPosition.Z))
                        end)
                        lastAttackTime = currentTime
                    end
                end
            end
        end
        
        killAuraThread = nil
    end)
end

-- ==================== WALKSPEED ====================
local function getSpeedMultiplier(tpSpeed)
    return 1.5 + (tpSpeed - 1) * (148.5 / 49)
end

RunService.Heartbeat:Connect(function()
    if getgenv().loopW then
        pcall(function()
            local currentChar = player.Character
            if currentChar and currentChar:FindFirstChild("Humanoid") then
                currentChar.Humanoid.WalkSpeed = getgenv().Walkspeed
            end
        end)
    end
end)

RunService.Heartbeat:Connect(function()
    if not getgenv().TPWalk then return end
    local currentChar = player.Character
    if not currentChar then return end
    local currentHumanoid = currentChar:FindFirstChild("Humanoid")
    if not currentHumanoid then return end
    if currentHumanoid.MoveDirection.Magnitude > 0 then
        currentChar:TranslateBy(currentHumanoid.MoveDirection * 0.05 * getSpeedMultiplier(getgenv().TPSpeed))
    end
end)

-- ==================== CREAR GUI PRINCIPAL ====================
local function CreateMainFrame(titleText, sizeX, sizeY)
    sizeX = sizeX or 240
    sizeY = sizeY or 430

    local ScreenGui = player.PlayerGui:FindFirstChild("MainFrames") or Instance.new("ScreenGui")
    ScreenGui.Name = "MainFrames"
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
    UIStroke.Color = Color3.fromRGB(255,255,255)
    UIStroke.Transparency = 0.4
    UIStroke.Thickness = 1.1
    UIStroke.Parent = Frame

    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 30)
    TitleBar.BackgroundTransparency = 1
    TitleBar.Parent = Frame

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(0.7, 0, 1, 0)
    Title.Position = UDim2.new(0, 9, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = titleText or "Diogo Br"
    Title.TextColor3 = Color3.fromRGB(255,255,255)
    Title.TextSize = 15
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
    Instance.new("UICorner", MinimizeButton).CornerRadius = UDim.new(0, 6)

    local DeleteButton = Instance.new("TextButton")
    DeleteButton.Size = UDim2.new(0, 26, 0, 26)
    DeleteButton.Position = UDim2.new(1, -32, 0, 2)
    DeleteButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    DeleteButton.Text = "X"
    DeleteButton.TextColor3 = Color3.fromRGB(255, 220, 220)
    DeleteButton.Font = Enum.Font.GothamBold
    DeleteButton.TextSize = 17
    DeleteButton.Parent = TitleBar
    Instance.new("UICorner", DeleteButton).CornerRadius = UDim.new(0, 6)

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
        KillAuraEnabled = false
        ESPEnabled = false
        if killAuraThread then
            task.cancel(killAuraThread)
            killAuraThread = nil
        end
        for _, connections in pairs(playerConnections) do
            if connections.charConnection then connections.charConnection:Disconnect() end
        end
        playerConnections = {}
        if Holder then Holder:Destroy() end
        Frame:Destroy()
        if quickPanel then quickPanel:Destroy() end
    end)

    local dragging = false
    local dragStart, startPos
    Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Frame.Position
        end
    end)
    Frame.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return Content, Frame
end

local content, mainFrame = CreateMainFrame("Diogo Br - Alei💖", 240, 430)

-- ==================== PANEL DE 4 BOTONES RÁPIDOS ====================
local ScreenGui = player.PlayerGui:FindFirstChild("MainFrames")
local quickPanel = Instance.new("Frame")
quickPanel.Name = "QuickPanel"
quickPanel.Size = UDim2.new(0, 50, 0, 200)
quickPanel.Position = UDim2.new(0, mainFrame.Position.X.Offset + 240 + 1, 0.5, -100)
quickPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
quickPanel.BackgroundTransparency = 0.1
quickPanel.BorderSizePixel = 0
quickPanel.Parent = ScreenGui
Instance.new("UICorner", quickPanel).CornerRadius = UDim.new(0, 8)

local quickStroke = Instance.new("UIStroke")
quickStroke.Color = Color3.fromRGB(255,255,255)
quickStroke.Transparency = 0.4
quickStroke.Thickness = 1
quickStroke.Parent = quickPanel

local quickTitle = Instance.new("TextLabel")
quickTitle.Size = UDim2.new(1, 0, 0, 20)
quickTitle.Position = UDim2.new(0, 0, 0, -20)
quickTitle.BackgroundTransparency = 1
quickTitle.Text = "ATAJO"
quickTitle.TextColor3 = Color3.fromRGB(0, 200, 255)
quickTitle.Font = Enum.Font.GothamBold
quickTitle.TextSize = 10
quickTitle.TextScaled = true
quickTitle.Parent = quickPanel

local btnHeight = 40
local btnSpacing = 5
local startY = 10

local quickKill = Instance.new("TextButton")
quickKill.Size = UDim2.new(0.9, 0, 0, btnHeight)
quickKill.Position = UDim2.new(0.05, 0, 0, startY)
quickKill.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
quickKill.Text = "AURA"
quickKill.TextColor3 = Color3.fromRGB(255, 80, 80)
quickKill.Font = Enum.Font.GothamBold
quickKill.TextSize = 12
quickKill.Parent = quickPanel
Instance.new("UICorner", quickKill).CornerRadius = UDim.new(0, 5)

local quickFake = Instance.new("TextButton")
quickFake.Size = UDim2.new(0.9, 0, 0, btnHeight)
quickFake.Position = UDim2.new(0.05, 0, 0, startY + btnHeight + btnSpacing)
quickFake.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
quickFake.Text = "INVIS"
quickFake.TextColor3 = Color3.fromRGB(255, 255, 100)
quickFake.Font = Enum.Font.GothamBold
quickFake.TextSize = 12
quickFake.Parent = quickPanel
Instance.new("UICorner", quickFake).CornerRadius = UDim.new(0, 5)

local quickTP = Instance.new("TextButton")
quickTP.Size = UDim2.new(0.9, 0, 0, btnHeight)
quickTP.Position = UDim2.new(0.05, 0, 0, startY + (btnHeight + btnSpacing) * 2)
quickTP.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
quickTP.Text = "TPW"
quickTP.TextColor3 = Color3.fromRGB(100, 255, 255)
quickTP.Font = Enum.Font.GothamBold
quickTP.TextSize = 12
quickTP.Parent = quickPanel
Instance.new("UICorner", quickTP).CornerRadius = UDim.new(0, 5)

local quickESP = Instance.new("TextButton")
quickESP.Size = UDim2.new(0.9, 0, 0, btnHeight)
quickESP.Position = UDim2.new(0.05, 0, 0, startY + (btnHeight + btnSpacing) * 3)
quickESP.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
quickESP.Text = "ESP"
quickESP.TextColor3 = Color3.fromRGB(255, 80, 80)
quickESP.Font = Enum.Font.GothamBold
quickESP.TextSize = 12
quickESP.Parent = quickPanel
Instance.new("UICorner", quickESP).CornerRadius = UDim.new(0, 5)

local function updateQuickPanelPosition()
    quickPanel.Position = UDim2.new(0, mainFrame.Position.X.Offset + 240 + 1, 0.5, -100)
end

mainFrame:GetPropertyChangedSignal("Position"):Connect(updateQuickPanelPosition)

local function makeDraggable(frame)
    local dragging = false
    local dragStart, startPos
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    
    frame.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

makeDraggable(mainFrame)
makeDraggable(quickPanel)

-- Botones principales dentro del menú
local espBtn = Instance.new("TextButton")
espBtn.Size = UDim2.new(0.4, 0, 0, 30)
espBtn.Position = UDim2.new(0.075, 0, 0.03, 0)
espBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
espBtn.Text = "ESP: OFF"
espBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
espBtn.Font = Enum.Font.GothamBold
espBtn.TextSize = 12
espBtn.Parent = content
Instance.new("UICorner", espBtn).CornerRadius = UDim.new(0, 8)

local auraBtn = Instance.new("TextButton")
auraBtn.Size = UDim2.new(0.4, 0, 0, 30)
auraBtn.Position = UDim2.new(0.525, 0, 0.03, 0)
auraBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
auraBtn.Text = "KillAura: OFF"
auraBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
auraBtn.Font = Enum.Font.GothamBold
auraBtn.TextSize = 12
auraBtn.Parent = content
Instance.new("UICorner", auraBtn).CornerRadius = UDim.new(0, 8)

-- Speed config
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0.85, 0, 0, 15)
speedLabel.Position = UDim2.new(0.075, 0, 0.12, 0)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Ataques por Segundo (1-5000):"
speedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextSize = 11
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = content

local speedContainer = Instance.new("Frame")
speedContainer.Size = UDim2.new(0.85, 0, 0, 26)
speedContainer.Position = UDim2.new(0.075, 0, 0.16, 0)
speedContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
speedContainer.Parent = content
Instance.new("UICorner", speedContainer).CornerRadius = UDim.new(0, 6)

local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(0.8, 0, 0.8, 0)
speedBox.Position = UDim2.new(0.1, 0, 0.1, 0)
speedBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
speedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
speedBox.Font = Enum.Font.Gotham
speedBox.TextSize = 12
speedBox.Text = "1000"
speedBox.Parent = speedContainer
Instance.new("UICorner", speedBox).CornerRadius = UDim.new(0, 5)

local applySpeedBtn = Instance.new("TextButton")
applySpeedBtn.Size = UDim2.new(0.2, 0, 0.8, 0)
applySpeedBtn.Position = UDim2.new(0.78, 0, 0.1, 0)
applySpeedBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
applySpeedBtn.Text = "Aplicar"
applySpeedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
applySpeedBtn.Font = Enum.Font.GothamBold
applySpeedBtn.TextSize = 11
applySpeedBtn.Parent = speedContainer
Instance.new("UICorner", applySpeedBtn).CornerRadius = UDim.new(0, 5)

-- Target selection
local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(0.85, 0, 0, 15)
targetLabel.Position = UDim2.new(0.075, 0, 0.25, 0)
targetLabel.BackgroundTransparency = 1
targetLabel.Text = "Objetivo Específico:"
targetLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
targetLabel.Font = Enum.Font.Gotham
targetLabel.TextSize = 11
targetLabel.TextXAlignment = Enum.TextXAlignment.Left
targetLabel.Parent = content

local targetBox = Instance.new("TextBox")
targetBox.Size = UDim2.new(0.85, 0, 0, 26)
targetBox.Position = UDim2.new(0.075, 0, 0.29, 0)
targetBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
targetBox.TextColor3 = Color3.fromRGB(255, 255, 255)
targetBox.Font = Enum.Font.Gotham
targetBox.TextSize = 12
targetBox.PlaceholderText = "Escribe nombre"
targetBox.Text = ""
targetBox.Parent = content
Instance.new("UICorner", targetBox).CornerRadius = UDim.new(0, 6)

local targetStatus = Instance.new("TextLabel")
targetStatus.Size = UDim2.new(0.85, 0, 0, 15)
targetStatus.Position = UDim2.new(0.075, 0, 0.35, 0)
targetStatus.BackgroundTransparency = 1
targetStatus.Text = "Objetivo actual: TODOS"
targetStatus.TextColor3 = Color3.fromRGB(120, 200, 255)
targetStatus.Font = Enum.Font.Gotham
targetStatus.TextSize = 9
targetStatus.TextXAlignment = Enum.TextXAlignment.Left
targetStatus.Parent = content

-- Speed controls
local speedTitle = Instance.new("TextLabel")
speedTitle.Size = UDim2.new(0.85, 0, 0, 15)
speedTitle.Position = UDim2.new(0.075, 0, 0.45, 0)
speedTitle.BackgroundTransparency = 1
speedTitle.Text = "CONTROLES DE VELOCIDAD"
speedTitle.TextColor3 = Color3.fromRGB(0, 200, 255)
speedTitle.Font = Enum.Font.GothamBold
speedTitle.TextSize = 12
speedTitle.TextXAlignment = Enum.TextXAlignment.Left
speedTitle.Parent = content

local loopWBtn = Instance.new("TextButton")
loopWBtn.Size = UDim2.new(0.4, 0, 0, 23)
loopWBtn.Position = UDim2.new(0.075, 0, 0.49, 0)
loopWBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
loopWBtn.Text = "Loop WS: OFF"
loopWBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
loopWBtn.Font = Enum.Font.Gotham
loopWBtn.TextSize = 11
loopWBtn.Parent = content
Instance.new("UICorner", loopWBtn).CornerRadius = UDim.new(0, 5)

local walkSpeedBox = Instance.new("TextBox")
walkSpeedBox.Size = UDim2.new(0.4, 0, 0, 23)
walkSpeedBox.Position = UDim2.new(0.525, 0, 0.49, 0)
walkSpeedBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
walkSpeedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
walkSpeedBox.Font = Enum.Font.Gotham
walkSpeedBox.TextSize = 11
walkSpeedBox.Text = tostring(getgenv().Walkspeed)
walkSpeedBox.Parent = content
Instance.new("UICorner", walkSpeedBox).CornerRadius = UDim.new(0, 5)

local tpWalkBtn = Instance.new("TextButton")
tpWalkBtn.Size = UDim2.new(0.4, 0, 0, 23)
tpWalkBtn.Position = UDim2.new(0.075, 0, 0.54, 0)
tpWalkBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
tpWalkBtn.Text = "TP Walk: OFF"
tpWalkBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tpWalkBtn.Font = Enum.Font.Gotham
tpWalkBtn.TextSize = 11
tpWalkBtn.Parent = content
Instance.new("UICorner", tpWalkBtn).CornerRadius = UDim.new(0, 5)

local tpSpeedBox = Instance.new("TextBox")
tpSpeedBox.Size = UDim2.new(0.4, 0, 0, 23)
tpSpeedBox.Position = UDim2.new(0.525, 0, 0.54, 0)
tpSpeedBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
tpSpeedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
tpSpeedBox.Font = Enum.Font.Gotham
tpSpeedBox.TextSize = 11
tpSpeedBox.Text = tostring(getgenv().TPSpeed)
tpSpeedBox.Parent = content
Instance.new("UICorner", tpSpeedBox).CornerRadius = UDim.new(0, 5)

-- Fake invis section
local fakeTitle = Instance.new("TextLabel")
fakeTitle.Size = UDim2.new(0.85, 0, 0, 15)
fakeTitle.Position = UDim2.new(0.075, 0, 0.63, 0)
fakeTitle.BackgroundTransparency = 1
fakeTitle.Text = "FAKE INVISIBILIDAD"
fakeTitle.TextColor3 = Color3.fromRGB(255, 255, 0)
fakeTitle.Font = Enum.Font.GothamBold
fakeTitle.TextSize = 12
fakeTitle.TextXAlignment = Enum.TextXAlignment.Left
fakeTitle.Parent = content

local fakeInvisBtn = Instance.new("TextButton")
fakeInvisBtn.Size = UDim2.new(0.4, 0, 0, 23)
fakeInvisBtn.Position = UDim2.new(0.075, 0, 0.67, 0)
fakeInvisBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
fakeInvisBtn.Text = "Fake Invis: OFF"
fakeInvisBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
fakeInvisBtn.Font = Enum.Font.GothamBold
fakeInvisBtn.TextSize = 11
fakeInvisBtn.Parent = content
Instance.new("UICorner", fakeInvisBtn).CornerRadius = UDim.new(0, 5)

local modeBtn = Instance.new("TextButton")
modeBtn.Size = UDim2.new(0.4, 0, 0, 23)
modeBtn.Position = UDim2.new(0.525, 0, 0.67, 0)
modeBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
modeBtn.Text = "ESTÁTICO"
modeBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
modeBtn.Font = Enum.Font.GothamBold
modeBtn.TextSize = 11
modeBtn.Parent = content
Instance.new("UICorner", modeBtn).CornerRadius = UDim.new(0, 5)

local fakeInvisInfo = Instance.new("TextLabel")
fakeInvisInfo.Size = UDim2.new(0.85, 0, 0, 20)
fakeInvisInfo.Position = UDim2.new(0.075, 0, 0.72, 0)
fakeInvisInfo.BackgroundTransparency = 1
fakeInvisInfo.Text = "Modo: ESTÁTICO - INACTIVO"
fakeInvisInfo.TextColor3 = Color3.fromRGB(150, 255, 150)
fakeInvisInfo.Font = Enum.Font.Gotham
fakeInvisInfo.TextSize = 8
fakeInvisInfo.TextWrapped = true
fakeInvisInfo.Parent = content

local keysInfo = Instance.new("TextLabel")
keysInfo.Size = UDim2.new(0.85, 0, 0, 20)
keysInfo.Position = UDim2.new(0.075, 0, 0.77, 0)
keysInfo.BackgroundTransparency = 1
keysInfo.Text = "Teclas: Q=ESP, E=Kill, R=TP, T=Fake, Z=Modo"
keysInfo.TextColor3 = Color3.fromRGB(200, 200, 100)
keysInfo.Font = Enum.Font.GothamBold
keysInfo.TextSize = 8
keysInfo.TextWrapped = true
keysInfo.Parent = content

-- ==================== FUNCIONES UI ====================
local function updateQuickButtons()
    if KillAuraEnabled then
        quickKill.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
        quickKill.TextColor3 = Color3.fromRGB(80, 255, 80)
    else
        quickKill.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        quickKill.TextColor3 = Color3.fromRGB(255, 80, 80)
    end
    
    local fakeOn = _G.IsFakeInvisEnabled and _G.IsFakeInvisEnabled() or false
    if fakeOn then
        quickFake.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
        quickFake.TextColor3 = Color3.fromRGB(80, 255, 80)
    else
        quickFake.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        quickFake.TextColor3 = Color3.fromRGB(255, 255, 100)
    end
    
    if getgenv().TPWalk then
        quickTP.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
        quickTP.TextColor3 = Color3.fromRGB(80, 255, 80)
    else
        quickTP.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        quickTP.TextColor3 = Color3.fromRGB(100, 255, 255)
    end
    
    if ESPEnabled then
        quickESP.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
        quickESP.TextColor3 = Color3.fromRGB(80, 255, 80)
    else
        quickESP.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        quickESP.TextColor3 = Color3.fromRGB(255, 80, 80)
    end
end

local function updateFakeUI()
    local currentMode = _G.GetFakeMode and _G.GetFakeMode() or "Estático"
    local isEnabled = _G.IsFakeInvisEnabled and _G.IsFakeInvisEnabled() or false
    local modeDesc = _G.GetModeDescription and _G.GetModeDescription() or ""
    
    if currentMode == "Estático" then
        modeBtn.Text = "ESTÁTICO"
        fakeInvisInfo.Text = string.format("Modo: ESTÁTICO (%s) - %s", modeDesc, isEnabled and "ACTIVO" or "INACTIVO")
    elseif currentMode == "Parpadeo" then
        modeBtn.Text = "PARPADEO"
        fakeInvisInfo.Text = string.format("Modo: PARPADEO (%s) - %s", modeDesc, isEnabled and "ACTIVO" or "INACTIVO")
    else
        modeBtn.Text = "ANTI HS"
        fakeInvisInfo.Text = string.format("Modo: ANTI HS (%s) - %s", modeDesc, isEnabled and "ACTIVO" or "INACTIVO")
    end
    
    if isEnabled then
        fakeInvisBtn.Text = "Fake Invis: ON"
        fakeInvisBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
        fakeInvisBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
    else
        fakeInvisBtn.Text = "Fake Invis: OFF"
        fakeInvisBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
        fakeInvisBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end
end

local function updateLoopUI()
    if getgenv().loopW then
        loopWBtn.Text = "Loop WS: ON"
        loopWBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    else
        loopWBtn.Text = "Loop WS: OFF"
        loopWBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end
end

local function updateTPUI()
    if getgenv().TPWalk then
        tpWalkBtn.Text = "TP Walk: ON"
        tpWalkBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    else
        tpWalkBtn.Text = "TP Walk: OFF"
        tpWalkBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end
    updateQuickButtons()
end

local function applySpeed()
    local text = speedBox.Text:gsub("%s+", "")
    if text == "" then
        speedBox.Text = "1000"
        attacksPerSecond = 1000
        attackCooldown = 1 / 1000
        return
    end
    local num = tonumber(text)
    if num and num >= 1 and num <= 5000 then
        attacksPerSecond = math.floor(num)
        attackCooldown = 1 / attacksPerSecond
        applySpeedBtn.Text = "✓"
        task.wait(0.5)
        applySpeedBtn.Text = "Aplicar"
    else
        speedBox.Text = "1000"
        attacksPerSecond = 1000
        attackCooldown = 1 / 1000
        applySpeedBtn.Text = "X"
        task.wait(0.5)
        applySpeedBtn.Text = "Aplicar"
    end
end

local function updateTargetStatus()
    if targetPlayer then
        targetStatus.Text = "Objetivo actual: " .. exactTargetName
        targetStatus.TextColor3 = Color3.fromRGB(80, 255, 80)
        targetBox.Text = exactTargetName
    else
        targetStatus.Text = "Objetivo actual: TODOS"
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
    elseif foundPlayer == nil then
        targetPlayer = nil
        exactTargetName = "TODOS"
        updateTargetStatus()
    end
end

-- ==================== FUNCIONES PRINCIPALES ====================
local function toggleESPButton()
    toggleESP()
    if ESPEnabled then
        espBtn.Text = "ESP: ON"
        espBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
        espBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
    else
        espBtn.Text = "ESP: OFF"
        espBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
        espBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end
    updateQuickButtons()
end

local function toggleKillAura()
    KillAuraEnabled = not KillAuraEnabled
    
    if KillAuraEnabled then
        -- Actualizar UI primero
        auraBtn.Text = "KillAura: ON"
        auraBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
        auraBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
        updateQuickButtons()
        
        -- Iniciar el loop (ataca inmediatamente)
        startKillAuraLoop()
    else
        auraBtn.Text = "KillAura: OFF"
        auraBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
        auraBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        updateQuickButtons()
        
        -- Detener el loop
        if killAuraThread then
            task.cancel(killAuraThread)
            killAuraThread = nil
        end
        lastAttackTime = 0
    end
end

-- ==================== CONEXIONES ====================
espBtn.MouseButton1Click:Connect(toggleESPButton)
auraBtn.MouseButton1Click:Connect(toggleKillAura)
applySpeedBtn.MouseButton1Click:Connect(applySpeed)
speedBox.FocusLost:Connect(function(enter) if enter then applySpeed() end end)
speedBox:GetPropertyChangedSignal("Text"):Connect(function()
    local cleaned = speedBox.Text:gsub("[^0-9]", "")
    if cleaned ~= speedBox.Text then speedBox.Text = cleaned end
    if #cleaned > 4 then speedBox.Text = cleaned:sub(1, 4) end
end)

targetBox.FocusLost:Connect(function(enter) if enter then searchAndSetTarget() end end)
targetBox:GetPropertyChangedSignal("Text"):Connect(function()
    if targetBox.Text:gsub("%s+", "") == "" then
        targetPlayer = nil
        exactTargetName = "TODOS"
        updateTargetStatus()
    end
end)

loopWBtn.MouseButton1Click:Connect(function()
    getgenv().loopW = not getgenv().loopW
    _G.loopW = getgenv().loopW
    updateLoopUI()
end)

walkSpeedBox.FocusLost:Connect(function(enter)
    if enter then
        local val = tonumber(walkSpeedBox.Text)
        if val then
            getgenv().Walkspeed = val
            _G.Walkspeed = val
        end
    end
end)

tpWalkBtn.MouseButton1Click:Connect(function()
    getgenv().TPWalk = not getgenv().TPWalk
    _G.TPWalk = getgenv().TPWalk
    updateTPUI()
end)

tpSpeedBox.FocusLost:Connect(function(enter)
    if enter then
        local val = tonumber(tpSpeedBox.Text)
        if val then
            val = math.clamp(val, 1, 50)
            getgenv().TPSpeed = val
            _G.TPSpeed = val
            tpSpeedBox.Text = tostring(val)
        end
    end
end)

fakeInvisBtn.MouseButton1Click:Connect(function()
    if _G.ToggleFakeInvis then
        _G.ToggleFakeInvis()
        updateFakeUI()
        updateQuickButtons()
    end
end)

modeBtn.MouseButton1Click:Connect(function()
    if _G.ToggleFakeMode then
        _G.ToggleFakeMode()
        updateFakeUI()
        updateQuickButtons()
    end
end)

quickKill.MouseButton1Click:Connect(toggleKillAura)
quickFake.MouseButton1Click:Connect(function()
    if _G.ToggleFakeInvis then
        _G.ToggleFakeInvis()
        updateFakeUI()
        updateQuickButtons()
    end
end)
quickTP.MouseButton1Click:Connect(function()
    getgenv().TPWalk = not getgenv().TPWalk
    _G.TPWalk = getgenv().TPWalk
    updateTPUI()
end)
quickESP.MouseButton1Click:Connect(toggleESPButton)

-- Teclas
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Q then
        toggleESPButton()
    elseif input.KeyCode == Enum.KeyCode.E then
        toggleKillAura()
    elseif input.KeyCode == Enum.KeyCode.R then
        getgenv().TPWalk = not getgenv().TPWalk
        _G.TPWalk = getgenv().TPWalk
        updateTPUI()
    elseif input.KeyCode == Enum.KeyCode.T then
        if _G.ToggleFakeInvis then
            _G.ToggleFakeInvis()
            updateFakeUI()
            updateQuickButtons()
        end
    elseif input.KeyCode == Enum.KeyCode.Z then
        if _G.ToggleFakeMode then
            _G.ToggleFakeMode()
            updateFakeUI()
            updateQuickButtons()
        end
    end
end)

-- CharacterAdded
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    if getgenv().loopW then humanoid.WalkSpeed = getgenv().Walkspeed end
    walkSpeedBox.Text = tostring(getgenv().Walkspeed)
    tpSpeedBox.Text = tostring(getgenv().TPSpeed)
    updateLoopUI()
    updateTPUI()
end)

-- Inicialización
updateTargetStatus()
applySpeed()
updateLoopUI()
updateTPUI()
updateFakeUI()
updateQuickButtons()

-- Jugadores
Players.PlayerAdded:Connect(function(p)
    if not isPlayerProhibited(p) and ESPEnabled then createESP(p) end
end)

Players.PlayerRemoving:Connect(function(p)
    if targetPlayer == p then
        targetPlayer = nil
        exactTargetName = "TODOS"
        targetBox.Text = ""
        updateTargetStatus()
    end
    removeESP(p)
end)

-- Protección anti-vacío
game:GetService("Workspace").FallenPartsDestroyHeight = 0/0

print("=== SCRIPT CARGADO CORRECTAMENTE ===")
print("✅ Kill Aura INSTANTÁNEO - Ataca inmediatamente al encender")
print("✅ Botón y Kill Aura se activan al mismo tiempo")
print("✅ Teclas: Q=ESP, E=Kill, R=TP, T=Fake, Z=Modo")
