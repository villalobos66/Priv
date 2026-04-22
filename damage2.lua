-- Script 2: Auto Damage (Daño automático)
local AutoDamage = false
local RADIUS = 12

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local HitRemote = game:GetService("ReplicatedStorage")
    :WaitForChild("Packages")
    :WaitForChild("Knit")
    :WaitForChild("Services")
    :WaitForChild("CombatService")
    :WaitForChild("RF")
    :WaitForChild("Hit")

local lastDamage = {}

local function DealDamage(target)
    if not target or not target.Character then return end
    local hum = target.Character:FindFirstChild("Humanoid")
    local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    
    if not hum or hum.Health <= 0 then return end
    if not myHRP then return end
    
    pcall(function()
        HitRemote:InvokeServer(hum, myHRP.Position)
    end)
end

-- UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AD"
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 130)
frame.Position = UDim2.new(0.5, -110, 0.5, -65)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
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

local radiusLabel = Instance.new("TextLabel")
radiusLabel.Size = UDim2.new(0.5, 0, 0, 25)
radiusLabel.Position = UDim2.new(0.05, 0, 0.4, 0)
radiusLabel.BackgroundTransparency = 1
radiusLabel.Text = "Radio: " .. RADIUS
radiusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
radiusLabel.TextSize = 12
radiusLabel.Font = Enum.Font.Gotham
radiusLabel.TextXAlignment = Enum.TextXAlignment.Left
radiusLabel.Parent = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0.9, 0, 0, 25)
statusLabel.Position = UDim2.new(0.05, 0, 0.6, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "❌ DESACTIVADO"
statusLabel.TextColor3 = Color3.fromRGB(200, 80, 80)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.4, 0, 0, 35)
toggleBtn.Position = UDim2.new(0.55, 0, 0.55, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
toggleBtn.Text = "ACTIVAR"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 12
toggleBtn.Parent = frame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = toggleBtn

local connection = nil

toggleBtn.MouseButton1Click:Connect(function()
    AutoDamage = not AutoDamage
    
    if AutoDamage then
        toggleBtn.Text = "ON"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 70)
        statusLabel.Text = "✅ ACTIVADO - Radio " .. RADIUS
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        
        if connection then connection:Disconnect() end
        connection = RunService.Heartbeat:Connect(function()
            if not AutoDamage then return end
            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
            
            local myHRP = player.Character.HumanoidRootPart
            
            for _, p in pairs(Players:GetPlayers()) do
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
        toggleBtn.Text = "ACTIVAR"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
        statusLabel.Text = "❌ DESACTIVADO"
        statusLabel.TextColor3 = Color3.fromRGB(200, 80, 80)
        if connection then connection:Disconnect() end
    end
end)

print("✅ Script 2 cargado - Auto Damage con radio " .. RADIUS)
