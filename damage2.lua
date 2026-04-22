--[[
    SCRIPT 1: HOOK DEL REMOTE
    Este script NO llama al remote directamente
    Solo multiplica los golpes NORMALES del juego
    Es el MÁS SEGURO porque el juego ya está golpeando
--]]

local multiplier = 5  -- Cada golpe normal se multiplica x5 (cambia este número)

local HitRemote = game:GetService("ReplicatedStorage")
    :WaitForChild("Packages")
    :WaitForChild("Knit")
    :WaitForChild("Services")
    :WaitForChild("CombatService")
    :WaitForChild("RF")
    :WaitForChild("Hit")

local oldInvoke = HitRemote.InvokeServer

HitRemote.InvokeServer = function(self, ...)
    local args = {...}
    
    -- Repetir el golpe varias veces
    for i = 1, multiplier do
        oldInvoke(self, unpack(args))
    end
    
    return oldInvoke(self, unpack(args))
end

-- UI simple
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MH"
screenGui.ResetOnSpawn = false
screenGui.Parent = game.Players.LocalPlayer.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 150, 0, 80)
frame.Position = UDim2.new(0.5, -75, 0.5, -40)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "⚡ MULTI HIT"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 14
title.Font = Enum.Font.GothamBold
title.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, 0, 0, 25)
status.Position = UDim2.new(0, 0, 0.4, 0)
status.BackgroundTransparency = 1
status.Text = "Multiplicador: x" .. multiplier
status.TextColor3 = Color3.fromRGB(150, 150, 150)
status.TextSize = 11
status.Font = Enum.Font.Gotham
status.Parent = frame

local enabled = true
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.6, 0, 0, 25)
toggleBtn.Position = UDim2.new(0.2, 0, 0.65, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 70)
toggleBtn.Text = "ACTIVADO"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 11
toggleBtn.Parent = frame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = toggleBtn

toggleBtn.MouseButton1Click:Connect(function()
    enabled = not enabled
    if enabled then
        HitRemote.InvokeServer = function(self, ...)
            for i = 1, multiplier do
                oldInvoke(self, unpack(...))
            end
            return oldInvoke(self, unpack(...))
        end
        toggleBtn.Text = "ACTIVADO"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 70)
        status.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        HitRemote.InvokeServer = oldInvoke
        toggleBtn.Text = "DESACTIVADO"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(130, 70, 70)
        status.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end)

print("✅ Script 1 cargado - Multiplicador x" .. multiplier)
