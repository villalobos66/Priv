--[[
    Script ofuscado para evitar detección básica
    Mantiene la misma funcionalidad
--]]

local a = false  -- AutoDamageEnabled
local b = 15     -- RADIUS

local c = game:GetService("Players")
local d = game:GetService("RunService")
local e = c.LocalPlayer

-- HitRemote ofuscado
local f = game:GetService("ReplicatedStorage")
    :WaitForChild("Packages")
    :WaitForChild("Knit")
    :WaitForChild("Services")
    :WaitForChild("CombatService")
    :WaitForChild("RF")
    :WaitForChild("Hit")

-- Función de daño ofuscada
local function g(h)  -- h = target
    if not h or not h.Character then return end
    
    local i = h.Character:FindFirstChild("Humanoid")
    local j = e.Character and e.Character:FindFirstChild("HumanoidRootPart")
    
    if not i or i.Health <= 0 then return end
    if not j then return end
    
    local k = {i, j.Position}
    
    pcall(function()
        f:InvokeServer(unpack(k))
    end)
end

-- Loop principal ofuscado
local l = nil

local function m()
    if l then return end
    
    l = d.Heartbeat:Connect(function()
        if not a then return end
        if not e.Character or not e.Character:FindFirstChild("HumanoidRootPart") then return end
        
        local j = e.Character.HumanoidRootPart
        
        for _, n in pairs(c:GetPlayers()) do
            if n ~= e and n.Character then
                local o = n.Character:FindFirstChild("HumanoidRootPart")
                local i = n.Character:FindFirstChild("Humanoid")
                
                if i and i.Health > 0 and o then
                    local p = (o.Position - j.Position).Magnitude
                    
                    if p <= b then
                        g(n)
                    end
                end
            end
        end
    end)
end

local function q()
    if l then
        l:Disconnect()
        l = nil
    end
end

-- UI ofuscada
local function r()
    local s = Instance.new("ScreenGui")
    s.Name = "U"  -- Nombre genérico
    s.ResetOnSpawn = false
    s.Parent = e.PlayerGui
    
    local t = Instance.new("Frame")
    t.Size = UDim2.new(0, 180, 0, 80)
    t.Position = UDim2.new(0.5, -90, 0.5, -40)
    t.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    t.BackgroundTransparency = 0.15
    t.BorderSizePixel = 0
    t.Parent = s
    
    local u = Instance.new("UICorner")
    u.CornerRadius = UDim.new(0, 8)
    u.Parent = t
    
    local v = Instance.new("TextLabel")
    v.Size = UDim2.new(1, 0, 0, 28)
    v.BackgroundTransparency = 1
    v.Text = "⚡"
    v.TextColor3 = Color3.fromRGB(255, 255, 255)
    v.TextSize = 14
    v.Font = Enum.Font.GothamBold
    v.Parent = t
    
    local w = Instance.new("TextButton")
    w.Size = UDim2.new(0.7, 0, 0, 30)
    w.Position = UDim2.new(0.15, 0, 0.45, 0)
    w.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    w.Text = ">"
    w.TextColor3 = Color3.fromRGB(255, 255, 255)
    w.Font = Enum.Font.GothamBold
    w.TextSize = 12
    w.Parent = t
    
    local x = Instance.new("UICorner")
    x.CornerRadius = UDim.new(0, 6)
    x.Parent = w
    
    w.MouseButton1Click:Connect(function()
        a = not a
        
        if a then
            w.Text = "✓"
            w.BackgroundColor3 = Color3.fromRGB(70, 130, 70)
            m()
        else
            w.Text = ">"
            w.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
            q()
        end
    end)
end

-- Iniciar
r()
