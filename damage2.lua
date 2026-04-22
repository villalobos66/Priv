--[[
    SCRIPT 3: SIMULACIÓN DE INPUT
    Simula que el jugador está golpeando manualmente
    MÁS HUMANO = MENOS DETECTABLE
--]]

local AutoDamage = false
local RADIUS = 10

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInput = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer

local HitRemote = game:GetService("ReplicatedStorage")
    :WaitForChild("Packages")
    :WaitForChild("Knit")
    :WaitForChild("Services")
    :WaitForChild("CombatService")
    :WaitForChild("RF")
    :WaitForChild("Hit")

-- Simular movimiento de mouse
local function SimulateMouseMovement()
    local randomX = math.random(100, 700)
    local randomY = math.random(100, 500)
    VirtualInput:SendMouseMoveEvent(Vector2.new(randomX, randomY), game, 0)
end

-- Simular click
local function SimulateClick()
    SimulateMouseMovement()
    task.wait(math.random(10, 50) / 1000)
    VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    task.wait(math.random(30, 80) / 1000)
    VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

local function DealDamage(target)
    if not target or not target.Character then return end
    local hum = target.Character:FindFirstChild("Humanoid")
    local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    
    if not hum or hum.Health <= 0 then return end
    if not myHRP then return end
    
    -- Simular comportamiento humano
    SimulateClick()
    task.wait(math.random(20, 60) / 1000)
    
    pcall(function()
        HitRemote:InvokeServer(hum, myHRP.Position)
    end)
end

-- Loop con comportamiento humano
local lastAttack = 0
local currentTarget = nil

RunService.Stepped:Connect(function()
    if not AutoDamage then return end
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local myHRP = player.Character.HumanoidRootPart
    local closest = nil
    local closestDist = RADIUS
    
    -- Encontrar el enemigo más cercano
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChild("Humanoid")
            
            if hum and hum.Health > 0 and hrp then
                local dist = (hrp.Position - myHRP.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = p
                end
            end
        end
    end
    
    -- Atacar al más cercano con delay humano
    if closest then
        local now = tick()
        if now - lastAttack > math.random(400, 900) / 1000 then
            lastAttack = now
            DealDamage(closest)
        end
    end
end)

-- UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HA"
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 180, 0, 80)
frame.Position = UDim2.new(0.5, -90, 0.5, -40)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "⚡ HUMAN AUTO"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 14
title.Font = Enum.Font.GothamBold
title.Parent = frame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.7, 0, 0, 35)
toggleBtn.Position = UDim2.new(0.15, 0, 0.45, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
toggleBtn.Text = "ACTIVAR"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 12
toggleBtn.Parent = frame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = toggleBtn

toggleBtn.MouseButton1Click:Connect(function()
    AutoDamage = not AutoDamage
    if AutoDamage then
        toggleBtn.Text = "✓ ACTIVADO"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 70)
    else
        toggleBtn.Text = "ACTIVAR"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    end
end)

print("✅ Script 3 cargado - Modo humano activado")
