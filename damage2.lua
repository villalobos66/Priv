-- Script 1: Multiplicador de golpes (MÁS SEGURO)
local multiplier = 5

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
    for i = 1, multiplier do
        oldInvoke(self, unpack(args))
    end
    return oldInvoke(self, unpack(args))
end

-- UI Funcional
local player = game.Players.LocalPlayer
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MH"
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 100)
frame.Position = UDim2.new(0.5, -100, 0.5, -50)
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
title.Text = "⚡ MULTI HIT"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, 0, 0, 25)
status.Position = UDim2.new(0, 0, 0.4, 0)
status.BackgroundTransparency = 1
status.Text = "Multiplicador: x" .. multiplier
status.TextColor3 = Color3.fromRGB(200, 200, 200)
status.TextSize = 12
status.Font = Enum.Font.Gotham
status.Parent = frame

local enabled = true
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.5, 0, 0, 30)
toggleBtn.Position = UDim2.new(0.25, 0, 0.65, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 70)
toggleBtn.Text = "ON"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 14
toggleBtn.Parent = frame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = toggleBtn

local function setEnabled(state)
    enabled = state
    if enabled then
        toggleBtn.Text = "ON"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 70)
        status.TextColor3 = Color3.fromRGB(100, 255, 100)
        status.Text = "✓ ACTIVADO - x" .. multiplier
        HitRemote.InvokeServer = function(self, ...)
            for i = 1, multiplier do
                oldInvoke(self, ...)
            end
            return oldInvoke(self, ...)
        end
    else
        toggleBtn.Text = "OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(130, 70, 70)
        status.TextColor3 = Color3.fromRGB(200, 200, 200)
        status.Text = "❌ DESACTIVADO - x" .. multiplier
        HitRemote.InvokeServer = oldInvoke
    end
end

toggleBtn.MouseButton1Click:Connect(function()
    setEnabled(not enabled)
end)

setEnabled(true)
print("✅ Script 1 cargado - Multiplicador x" .. multiplier)
