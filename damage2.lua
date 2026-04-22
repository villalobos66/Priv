--[[
    SCRIPT 2: FIRESERVER EN LUGAR DE INVOKESERVER
    Usa FireServer que NO espera respuesta
    Menos detectable que InvokeServer
--]]

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

-- Cambiar a FireServer si es posible
local function DealDamage(target)
    if not target or not target.Character then return end
    local hum = target.Character:FindFirstChild("Humanoid")
    local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    
    if not hum or hum.Health <= 0 then return end
    if not myHRP then return end
    
    pcall(function()
        if HitRemote:IsA("RemoteEvent") then
            HitRemote:FireServer(hum, myHRP.Position)
        else
            HitRemote:InvokeServer(hum, myHRP.Position)
        end
    end)
end

-- Loop con delay aleatorio
local lastDamage = {}
local function StartLoop()
    RunService.Stepped:Connect(function()
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
                        if not lastDamage[p] or now - lastDamage[p] > math.random(300, 800) / 1000 then
                            lastDamage[p] = now
                            DealDamage(p)
                        end
                    end
                end
            end
        end
    end)
end

-- UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AD"
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 180, 0, 100)
frame.Position = UDim2.new(0.5, -90, 0.5, -50)
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
title.Text = "⚡ AUTO DAMAGE"
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
        StartLoop()
    else
        toggleBtn.Text = "ACTIVAR"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    end
end)

print("✅ Script 2 cargado - Usando FireServer cuando es posible")
