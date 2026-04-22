-- Script con UI garantizada
local player = game.Players.LocalPlayer

-- Esperar a que PlayerGui exista
local playerGui = player:WaitForChild("PlayerGui")

-- Forzar creación de UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoDamageUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Frame principal
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 120)
frame.Position = UDim2.new(0.5, -100, 0.5, -60)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
frame.BackgroundTransparency = 0
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundTransparency = 1
title.Text = "⚡ AUTO DAMAGE"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.Parent = frame

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0.6, 0, 0, 40)
btn.Position = UDim2.new(0.2, 0, 0.45, 0)
btn.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
btn.Text = "ACTIVAR"
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 14
btn.Parent = frame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = btn

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, 0, 0, 25)
status.Position = UDim2.new(0, 0, 0.8, 0)
status.BackgroundTransparency = 1
status.Text = "❌ DESACTIVADO"
status.TextColor3 = Color3.fromRGB(200, 80, 80)
status.TextSize = 11
status.Font = Enum.Font.Gotham
status.Parent = frame

-- Hacer UI arrastrable
local dragging = false
local dragStart
local frameStart

btn.MouseButton1Down:Connect(function()
    dragging = true
    dragStart = game:GetService("UserInputService"):GetMouseLocation()
    frameStart = frame.Position
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(frameStart.X.Scale, frameStart.X.Offset + delta.X, frameStart.Y.Scale, frameStart.Y.Offset + delta.Y)
    end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- Variables del script
local AutoDamage = false
local RADIUS = 12
local lastDamage = {}

local HitRemote = game:GetService("ReplicatedStorage")
    :WaitForChild("Packages")
    :WaitForChild("Knit")
    :WaitForChild("Services")
    :WaitForChild("CombatService")
    :WaitForChild("RF")
    :WaitForChild("Hit")

local function DealDamage(target)
    if not target or not target.Character then return end
    local hum = target.Character:FindFirstChild("Humanoid")
    local myChar = player.Character
    if not myChar then return end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not hum or hum.Health <= 0 then return end
    if not myHRP then return end
    
    pcall(function()
        HitRemote:InvokeServer(hum, myHRP.Position)
    end)
end

local connection = nil

btn.MouseButton1Click:Connect(function()
    AutoDamage = not AutoDamage
    
    if AutoDamage then
        btn.Text = "ON ✓"
        btn.BackgroundColor3 = Color3.fromRGB(70, 130, 70)
        status.Text = "✅ ACTIVADO - Radio " .. RADIUS
        status.TextColor3 = Color3.fromRGB(100, 255, 100)
        
        if connection then connection:Disconnect() end
        connection = game:GetService("RunService").Heartbeat:Connect(function()
            if not AutoDamage then return end
            if not player.Character then return end
            local myHRP = player.Character:FindFirstChild("HumanoidRootPart")
            if not myHRP then return end
            
            for _, p in pairs(game:GetService("Players"):GetPlayers()) do
                if p ~= player and p.Character then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    local hum = p.Character:FindFirstChild("Humanoid")
                    if hum and hum.Health > 0 and hrp then
                        local dist = (hrp.Position - myHRP.Position).Magnitude
                        if dist <= RADIUS then
                            local now = tick()
                            if not lastDamage[p] or now - lastDamage[p] > 0.3 then
                                lastDamage[p] = now
                                DealDamage(p)
                            end
                        end
                    end
                end
            end
        end)
    else
        btn.Text = "ACTIVAR"
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
        status.Text = "❌ DESACTIVADO"
        status.TextColor3 = Color3.fromRGB(200, 80, 80)
        if connection then connection:Disconnect() end
    end
end)

print("✅ UI CREADA - La ventana debería aparecer en el centro de la pantalla")
print("📍 Si no ves la ventana, revisa que no haya otro ScreenGui bloqueando")
