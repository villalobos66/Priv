-- Script de AutoDamage - Versión estable
-- By: TuNombre

local AutoDamage = false
local HitRemote = nil

-- Intentar obtener el remote de daño
local success, err = pcall(function()
    HitRemote = game:GetService("ReplicatedStorage")
        :WaitForChild("Packages")
        :WaitForChild("Knit")
        :WaitForChild("Services")
        :WaitForChild("CombatService")
        :WaitForChild("RF")
        :WaitForChild("Hit")
end)

if not success then
    warn("Error al obtener el remote:", err)
    warn("El script no funcionará correctamente")
end

-- Loop principal con wait()
spawn(function()
    while true do
        if AutoDamage then
            local player = game.Players.LocalPlayer
            local myChar = player.Character
            
            if myChar then
                local myHRP = myChar:FindFirstChild("HumanoidRootPart")
                
                if myHRP then
                    local nearestTarget = nil
                    local nearestDist = 10
                    
                    -- Buscar el jugador más cercano
                    for _, targetPlayer in pairs(game:GetService("Players"):GetPlayers()) do
                        if targetPlayer ~= player and targetPlayer.Character then
                            local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                            local targetHum = targetPlayer.Character:FindFirstChild("Humanoid")
                            
                            if targetHum and targetHum.Health > 0 and targetHRP then
                                local dist = (targetHRP.Position - myHRP.Position).Magnitude
                                
                                if dist < nearestDist then
                                    nearestDist = dist
                                    nearestTarget = targetPlayer
                                end
                            end
                        end
                    end
                    
                    -- Atacar al objetivo más cercano si está a distancia
                    if nearestTarget and nearestDist <= 7 then
                        local targetHum = nearestTarget.Character:FindFirstChild("Humanoid")
                        
                        if HitRemote and targetHum then
                            pcall(function()
                                HitRemote:InvokeServer(targetHum, myHRP.Position)
                            end)
                        end
                    end
                end
            end
        end
        
        wait(2) -- Delay de 2 segundos entre ataques
    end
end)

-- Crear UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoDamageGUI"
screenGui.Parent = game.Players.LocalPlayer.PlayerGui

local btn = Instance.new("TextButton")
btn.Name = "ToggleButton"
btn.Size = UDim2.new(0, 60, 0, 60)
btn.Position = UDim2.new(0.9, -70, 0.1, 0)
btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
btn.BackgroundTransparency = 0.3
btn.Text = "⚔️"
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.TextSize = 30
btn.Font = Enum.Font.GothamBold
btn.Parent = screenGui

-- Efecto de esquinas redondeadas
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 30)
corner.Parent = btn

-- Texto de estado
local statusText = Instance.new("TextLabel")
statusText.Name = "Status"
statusText.Size = UDim2.new(0, 60, 0, 20)
statusText.Position = UDim2.new(0, 0, 1, 5)
statusText.BackgroundTransparency = 1
statusText.Text = "OFF"
statusText.TextColor3 = Color3.fromRGB(255, 50, 50)
statusText.TextSize = 14
statusText.Font = Enum.Font.GothamBold
statusText.Parent = btn

-- Función del botón
btn.MouseButton1Click:Connect(function()
    AutoDamage = not AutoDamage
    
    -- Cambiar apariencia según estado
    if AutoDamage then
        btn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        statusText.Text = "ON"
        statusText.TextColor3 = Color3.fromRGB(50, 255, 50)
        print("[AutoDamage] Activado - Atacando cada 2 segundos")
    else
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        statusText.Text = "OFF"
        statusText.TextColor3 = Color3.fromRGB(255, 50, 50)
        print("[AutoDamage] Desactivado")
    end
end)

-- Mensaje de inicio
print("[AutoDamage] Script cargado correctamente")
print("[AutoDamage] Presiona el botón ⚔️ para activar/desactivar")
