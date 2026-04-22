local AutoDamageEnabled = false
local RADIUS = 8  -- Radio más pequeño (menos sospechoso)
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
    if not hum or hum.Health <= 0 then return end
    
    local now = tick()
    if lastDamage[target] and now - lastDamage[target] < 1 then return end  -- Delay 0.3 segundos
    lastDamage[target] = now
    
    local myHRP = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    
    pcall(function()
        HitRemote:InvokeServer(hum, myHRP.Position)
    end)
end

-- Usar Stepped (más lento que Heartbeat)
game:GetService("RunService").Stepped:Connect(function()
    if not AutoDamageEnabled then return end
    -- Código...
end)
