-- ==================== SCRIPT SEGURO - SIN LLAMADAS DIRECTAS ====================
-- Este script NO llama al HitRemote directamente
-- SOLO multiplica los golpes que el juego YA está haciendo

local multiplier = 10  -- Cada golpe normal se multiplica x10

-- Obtener el HitRemote
local HitRemote = game:GetService("ReplicatedStorage")
    :WaitForChild("Packages")
    :WaitForChild("Knit")
    :WaitForChild("Services")
    :WaitForChild("CombatService")
    :WaitForChild("RF")
    :WaitForChild("Hit")

-- Guardar la función original
local originalInvoke = HitRemote.InvokeServer

-- Hookear (interceptar) la función
HitRemote.InvokeServer = function(self, ...)
    local args = {...}
    
    -- Repetir el golpe múltiples veces
    for i = 1, multiplier do
        originalInvoke(self, unpack(args))
    end
    
    -- Devolver el resultado del golpe original
    return originalInvoke(self, unpack(args))
end

-- UI simple (opcional)
local player = game.Players.LocalPlayer
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MultiHit"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 160, 0, 60)
frame.Position = UDim2.new(0.5, -80, 0.5, -30)
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
title.Text = "⚡ MULTI HIT x" .. multiplier
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 12
title.Font = Enum.Font.GothamBold
title.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, 0, 0, 20)
status.Position = UDim2.new(0, 0, 0.55, 0)
status.BackgroundTransparency = 1
status.Text = "✓ Activado - Golpea normalmente"
status.TextColor3 = Color3.fromRGB(100, 255, 100)
status.TextSize = 10
status.Font = Enum.Font.Gotham
status.Parent = frame

print("✅ Multi Hit cargado - Cada golpe se multiplica x" .. multiplier)
print("💡 Ahora SOLO haz golpes normales, el script los multiplica")
