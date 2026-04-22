-- Variables principales
local HitboxEnabled = false
local AntiRagdollEnabled = false
local targetPlayer = nil
local exactTargetName = ""
local targetPlayers = {}  -- TABLA de jugadores objetivo (múltiples)
local exactTargetNames = {}  -- Nombres para mostrar

-- ==================== LISTA DE PROHIBIDOS (DESDE GITHUB) ====================
local PROHIBITED_USERS = {}
@@ -474,24 +474,29 @@ local function shouldHitPlayer(playerObj)
    return true
end

-- ACTUALIZADO: Función que aplica hitbox a múltiples targets
local function updateHitboxes()
    if not HitboxEnabled then
        resetAllHitboxes()
        return
    end

    if targetPlayer then
        if shouldHitPlayer(targetPlayer) then
            for _, v in pairs(Players:GetPlayers()) do
                if v ~= player and v ~= targetPlayer and not isPlayerProhibited(v) then
                    resetHitbox(v)
                end
    -- Si hay targets específicos
    if #targetPlayers > 0 then
        -- Primero resetear hitboxes de TODOS los jugadores
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= player and not isPlayerProhibited(v) then
                resetHitbox(v)
            end
        end
        -- Luego aplicar hitbox SOLO a los targets seleccionados
        for _, target in ipairs(targetPlayers) do
            if target and shouldHitPlayer(target) then
                applyHitboxToPlayer(target)
            end
            applyHitboxToPlayer(targetPlayer)
        else
            resetHitbox(targetPlayer)
        end
    else
        -- Si no hay targets específicos, aplicar a todos los jugadores válidos
        for _, v in pairs(Players:GetPlayers()) do
            if shouldHitPlayer(v) then
                applyHitboxToPlayer(v)
@@ -690,15 +695,15 @@ local function CreateButtonsInterface()
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 208, 0, 55)  -- 320*0.65=208, 85*0.65≈55
    Frame.Size = UDim2.new(0, 208, 0, 55)
    Frame.Position = UDim2.new(0.5, -104, 0.02, 0)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    Frame.BackgroundTransparency = 0.05
    Frame.BorderSizePixel = 0
    Frame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)  -- 12*0.65≈8
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = Frame

    local UIStroke = Instance.new("UIStroke")
@@ -708,7 +713,7 @@ local function CreateButtonsInterface()
    UIStroke.Parent = Frame

    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 23)  -- 35*0.65≈23
    TopBar.Size = UDim2.new(1, 0, 0, 23)
    TopBar.Position = UDim2.new(0, 0, 0, 0)
    TopBar.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    TopBar.BackgroundTransparency = 0.2
@@ -725,19 +730,19 @@ local function CreateButtonsInterface()
    Title.BackgroundTransparency = 1
    Title.Text = "⋮⋮ PANEL ⋮⋮"
    Title.TextColor3 = Color3.fromRGB(200, 200, 255)
    Title.TextSize = 8  -- 11*0.73≈8
    Title.TextSize = 8
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TopBar

    local ConfigButton = Instance.new("TextButton")
    ConfigButton.Size = UDim2.new(0, 23, 0, 20)  -- 35*0.65≈23, 30*0.65≈20
    ConfigButton.Size = UDim2.new(0, 23, 0, 20)
    ConfigButton.Position = UDim2.new(1, -27, 0, 1.5)
    ConfigButton.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
    ConfigButton.Text = "⚙️"
    ConfigButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ConfigButton.Font = Enum.Font.GothamBold
    ConfigButton.TextSize = 11  -- 16*0.7≈11
    ConfigButton.TextSize = 11
    ConfigButton.Parent = TopBar

    local configCorner = Instance.new("UICorner")
@@ -825,8 +830,8 @@ local function CreateConfigInterface()
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 182, 0, 245)  -- 260*0.7=182, 350*0.7=245
    Frame.Position = UDim2.new(0.5, -91, 0.5, -122.5)
    Frame.Size = UDim2.new(0, 182, 0, 270)  -- Un poco más alto para mostrar múltiples targets
    Frame.Position = UDim2.new(0.5, -91, 0.5, -135)
    Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Frame.BorderSizePixel = 0
    Frame.ClipsDescendants = true
@@ -843,7 +848,7 @@ local function CreateConfigInterface()
    UIStroke.Parent = Frame

    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 24)  -- 35*0.7≈24
    TitleBar.Size = UDim2.new(1, 0, 0, 24)
    TitleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    TitleBar.BackgroundTransparency = 0.1
    TitleBar.BorderSizePixel = 0
@@ -865,7 +870,7 @@ local function CreateConfigInterface()
    Title.Parent = TitleBar

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 20, 0, 20)  -- 28*0.7≈20
    CloseBtn.Size = UDim2.new(0, 20, 0, 20)
    CloseBtn.Position = UDim2.new(1, -24, 0, 2)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    CloseBtn.Text = "✕"
@@ -1178,12 +1183,12 @@ local function CreateConfigInterface()
    sep4.Parent = Content
    yOffset = yOffset + 0.05

    -- Sección TARGET
    -- Sección TARGET (MÚLTIPLE CON TOGGLE)
    local targetTitle = Instance.new("TextLabel")
    targetTitle.Size = UDim2.new(0.9, 0, 0, 11)
    targetTitle.Position = UDim2.new(0.05, 0, yOffset, 0)
    targetTitle.BackgroundTransparency = 1
    targetTitle.Text = "TARGET"
    targetTitle.Text = "TARGET (TOGGLE)"
    targetTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
    targetTitle.Font = Enum.Font.GothamBold
    targetTitle.TextSize = 8
@@ -1198,7 +1203,7 @@ local function CreateConfigInterface()
    targetBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    targetBox.Font = Enum.Font.Gotham
    targetBox.TextSize = 8
    targetBox.PlaceholderText = "Nombre (3+ letras)"
    targetBox.PlaceholderText = "Nombre (Enter para añadir/quitar)"
    targetBox.Text = ""
    targetBox.Parent = Content

@@ -1208,22 +1213,23 @@ local function CreateConfigInterface()
    yOffset = yOffset + 0.07

    targetStatus = Instance.new("TextLabel")
    targetStatus.Size = UDim2.new(0.9, 0, 0, 10)
    targetStatus.Size = UDim2.new(0.9, 0, 0, 24)  -- Más alto para mostrar varios nombres
    targetStatus.Position = UDim2.new(0.05, 0, yOffset, 0)
    targetStatus.BackgroundTransparency = 1
    targetStatus.Text = "Objetivo: TODOS"
    targetStatus.Text = "Objetivos: TODOS"
    targetStatus.TextColor3 = Color3.fromRGB(120, 200, 255)
    targetStatus.Font = Enum.Font.Gotham
    targetStatus.TextSize = 6
    targetStatus.TextXAlignment = Enum.TextXAlignment.Left
    targetStatus.TextWrapped = true
    targetStatus.Parent = Content
    yOffset = yOffset + 0.045
    yOffset = yOffset + 0.09

    searchResult = Instance.new("TextLabel")
    searchResult.Size = UDim2.new(0.9, 0, 0, 10)
    searchResult.Position = UDim2.new(0.05, 0, yOffset, 0)
    searchResult.BackgroundTransparency = 1
    searchResult.Text = "Presiona Enter"
    searchResult.Text = "Escribe nombre y presiona Enter"
    searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
    searchResult.Font = Enum.Font.Gotham
    searchResult.TextSize = 6
@@ -1239,7 +1245,7 @@ local function CreateConfigInterface()
    btnContainer.Parent = Content

    clearTargetBtn = Instance.new("TextButton")
    clearTargetBtn.Size = UDim2.new(0.48, 0, 1, 0)
    clearTargetBtn.Size = UDim2.new(0.3, 0, 1, 0)
    clearTargetBtn.Position = UDim2.new(0, 0, 0, 0)
    clearTargetBtn.BackgroundColor3 = Color3.fromRGB(180, 70, 70)
    clearTargetBtn.Text = "Limpiar"
@@ -1252,11 +1258,25 @@ local function CreateConfigInterface()
    clearCorner.CornerRadius = UDim.new(0, 4)
    clearCorner.Parent = clearTargetBtn

    removeLastBtn = Instance.new("TextButton")
    removeLastBtn.Size = UDim2.new(0.3, 0, 1, 0)
    removeLastBtn.Position = UDim2.new(0.34, 0, 0, 0)
    removeLastBtn.BackgroundColor3 = Color3.fromRGB(200, 130, 50)
    removeLastBtn.Text = "Quitar Últ"
    removeLastBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    removeLastBtn.Font = Enum.Font.GothamBold
    removeLastBtn.TextSize = 7
    removeLastBtn.Parent = btnContainer

    local removeLastCorner = Instance.new("UICorner")
    removeLastCorner.CornerRadius = UDim.new(0, 4)
    removeLastCorner.Parent = removeLastBtn

    closestBtn = Instance.new("TextButton")
    closestBtn.Size = UDim2.new(0.48, 0, 1, 0)
    closestBtn.Position = UDim2.new(0.52, 0, 0, 0)
    closestBtn.Size = UDim2.new(0.36, 0, 1, 0)
    closestBtn.Position = UDim2.new(0.64, 0, 0, 0)
    closestBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
    closestBtn.Text = "Más Cercano"
    closestBtn.Text = "Añadir Cerca"
    closestBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closestBtn.Font = Enum.Font.GothamBold
    closestBtn.TextSize = 7
@@ -1288,14 +1308,14 @@ local function CreateConfigInterface()
                searchResult.Text = "✓ Tamaño cambiado"
                searchResult.TextColor3 = Color3.fromRGB(80, 255, 80)
                task.wait(1.5)
                searchResult.Text = "Presiona Enter"
                searchResult.Text = "Escribe nombre y presiona Enter"
                searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
            else
                hitboxSizeInput.Text = tostring(HITBOX_SIZE)
                searchResult.Text = "✗ Tam inválido"
                searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
                task.wait(2)
                searchResult.Text = "Presiona Enter"
                searchResult.Text = "Escribe nombre y presiona Enter"
                searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
            end
        end
@@ -1309,14 +1329,14 @@ local function CreateConfigInterface()
                searchResult.Text = "✓ Transparencia cambiada"
                searchResult.TextColor3 = Color3.fromRGB(80, 255, 80)
                task.wait(1.5)
                searchResult.Text = "Presiona Enter"
                searchResult.Text = "Escribe nombre y presiona Enter"
                searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
            else
                hitboxTransparencyInput.Text = tostring(HITBOX_TRANSPARENCY)
                searchResult.Text = "✗ Trans inválida"
                searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
                task.wait(2)
                searchResult.Text = "Presiona Enter"
                searchResult.Text = "Escribe nombre y presiona Enter"
                searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
            end
        end
@@ -1330,14 +1350,14 @@ local function CreateConfigInterface()
                searchResult.Text = "✓ Velocidad cambiada"
                searchResult.TextColor3 = Color3.fromRGB(80, 255, 80)
                task.wait(1.5)
                searchResult.Text = "Presiona Enter"
                searchResult.Text = "Escribe nombre y presiona Enter"
                searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
            else
                walkSpeedInput.Text = tostring(WalkSpeedValue)
                searchResult.Text = "✗ Vel inválida"
                searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
                task.wait(2)
                searchResult.Text = "Presiona Enter"
                searchResult.Text = "Escribe nombre y presiona Enter"
                searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
            end
        end
@@ -1351,14 +1371,14 @@ local function CreateConfigInterface()
                searchResult.Text = "✓ Vel TP cambiada"
                searchResult.TextColor3 = Color3.fromRGB(80, 255, 80)
                task.wait(1.5)
                searchResult.Text = "Presiona Enter"
                searchResult.Text = "Escribe nombre y presiona Enter"
                searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
            else
                tpSpeedInput.Text = tostring(TPSpeedValue)
                searchResult.Text = "✗ Vel TP inválida"
                searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
                task.wait(2)
                searchResult.Text = "Presiona Enter"
                searchResult.Text = "Escribe nombre y presiona Enter"
                searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
            end
        end
@@ -1430,50 +1450,92 @@ local function updateDamageRepeaterButton()
    end
end

-- ACTUALIZADO: Muestra la lista de objetivos
local function updateTargetStatus()
    if targetPlayer then
        targetStatus.Text = "Objetivo: " .. exactTargetName
    if #targetPlayers > 0 then
        local names = {}
        for i, target in ipairs(targetPlayers) do
            table.insert(names, exactTargetNames[target] or target.Name)
        end
        local displayText = "Objetivos: " .. table.concat(names, ", ")
        if #displayText > 35 then
            displayText = displayText:sub(1, 32) .. "..."
        end
        targetStatus.Text = displayText
        targetStatus.TextColor3 = Color3.fromRGB(80, 255, 80)
        targetBox.Text = exactTargetName
    else
        targetStatus.Text = "Objetivo: TODOS"
        targetStatus.Text = "Objetivos: TODOS"
        targetStatus.TextColor3 = Color3.fromRGB(120, 200, 255)
    end
end

local function searchAndSetTarget()
    local searchText = targetBox.Text:gsub("%s+", "")
    local foundPlayer, resultName = findPlayerByPartialName(searchText)
    if foundPlayer then
        targetPlayer = foundPlayer
        exactTargetName = resultName
        updateTargetStatus()
        searchResult.Text = "✓ Encontrado: " .. exactTargetName
        searchResult.TextColor3 = Color3.fromRGB(80, 255, 80)
        if HitboxEnabled then
            updateHitboxes()
-- NUEVA FUNCIÓN: Añade o quita un jugador (TOGGLE)
local function toggleTarget(playerObj, displayName)
    if not playerObj then return false end
    if playerObj == player then
        searchResult.Text = "✗ No te puedes añadir a ti mismo"
        searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
        return false
    end
    if isPlayerProhibited(playerObj) then
        searchResult.Text = "✗ Usuario prohibido"
        searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
        return false
    end
    
    -- Buscar si ya está en la lista
    for i, existing in ipairs(targetPlayers) do
        if existing == playerObj then
            -- Si está, lo eliminamos
            table.remove(targetPlayers, i)
            exactTargetNames[playerObj] = nil
            updateTargetStatus()
            searchResult.Text = "🗑️ Eliminado: " .. (displayName or playerObj.Name)
            searchResult.TextColor3 = Color3.fromRGB(255, 150, 50)
            if HitboxEnabled then
                updateHitboxes()
            end
            return true
        end
    elseif foundPlayer == nil then
        targetPlayer = nil
        exactTargetName = "TODOS"
    end
    
    -- Si no está, lo añadimos
    table.insert(targetPlayers, playerObj)
    exactTargetNames[playerObj] = displayName or playerObj.Name
    updateTargetStatus()
    searchResult.Text = "✓ Añadido: " .. (displayName or playerObj.Name)
    searchResult.TextColor3 = Color3.fromRGB(80, 255, 80)
    if HitboxEnabled then
        updateHitboxes()
    end
    return true
end

-- ACTUALIZADO: Elimina el último objetivo añadido
local function removeLastTarget()
    if #targetPlayers > 0 then
        local removed = table.remove(targetPlayers)
        local removedName = exactTargetNames[removed] or removed.Name
        exactTargetNames[removed] = nil
        updateTargetStatus()
        searchResult.Text = "✓ Modo: TODOS"
        searchResult.TextColor3 = Color3.fromRGB(120, 200, 255)
        searchResult.Text = "🗑️ Eliminado: " .. removedName
        searchResult.TextColor3 = Color3.fromRGB(255, 150, 50)
        if HitboxEnabled then
            updateHitboxes()
        end
    else
        searchResult.Text = resultName
        searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
        searchResult.Text = "⚠️ No hay objetivos para eliminar"
        searchResult.TextColor3 = Color3.fromRGB(255, 150, 50)
    end
    task.wait(2)
    if searchResult.Text:sub(1,1) == "✓" or searchResult.Text:find("no encontrado") or searchResult.Text:find("Minimo") then
        searchResult.Text = "Presiona Enter"
    if searchResult.Text:sub(1,1) == "✓" or searchResult.Text:sub(1,1) == "🗑️" or searchResult.Text:sub(1,1) == "⚠️" then
        searchResult.Text = "Escribe nombre y presiona Enter"
        searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end

local function targetClosest()
-- ACTUALIZADO: Añade el jugador más cercano (si no está, lo añade)
local function addClosestTarget()
    local closestDistance = math.huge
    local closestPlayer = nil

@@ -1492,42 +1554,64 @@ local function targetClosest()
    end

    if closestPlayer then
        targetPlayer = closestPlayer
        exactTargetName = closestPlayer.DisplayName .. " (" .. closestPlayer.Name .. ")"
        updateTargetStatus()
        targetBox.Text = closestPlayer.Name
        searchResult.Text = "✓ Target: " .. exactTargetName
        searchResult.TextColor3 = Color3.fromRGB(80, 255, 80)
        if HitboxEnabled then
            updateHitboxes()
        end
        task.wait(2)
        searchResult.Text = "Presiona Enter"
        searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
        toggleTarget(closestPlayer, closestPlayer.DisplayName .. " (" .. closestPlayer.Name .. ")")
    else
        searchResult.Text = "✗ No hay jugadores"
        searchResult.Text = "✗ No hay jugadores cercanos disponibles"
        searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
        task.wait(2)
        searchResult.Text = "Presiona Enter"
        searchResult.Text = "Escribe nombre y presiona Enter"
        searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end

local function clearTarget()
    targetPlayer = nil
    exactTargetName = "TODOS"
-- ACTUALIZADO: Limpia TODOS los objetivos
local function clearTargets()
    targetPlayers = {}
    exactTargetNames = {}
    targetBox.Text = ""
    updateTargetStatus()
    searchResult.Text = "✓ Target limpiado"
    searchResult.Text = "✓ Todos los objetivos eliminados"
    searchResult.TextColor3 = Color3.fromRGB(120, 200, 255)
    if HitboxEnabled then
        updateHitboxes()
    end
    task.wait(2)
    searchResult.Text = "Presiona Enter"
    searchResult.Text = "Escribe nombre y presiona Enter"
    searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
end

-- ACTUALIZADO: Busca y aplica TOGGLE al jugador (añade o quita)
local function searchAndToggleTarget()
    local searchText = targetBox.Text:gsub("%s+", "")
    if searchText == "" or searchText:lower() == "todos" or searchText:lower() == "all" then
        searchResult.Text = "⚠️ Escribe un nombre específico"
        searchResult.TextColor3 = Color3.fromRGB(255, 150, 50)
        task.wait(2)
        searchResult.Text = "Escribe nombre y presiona Enter"
        searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
        targetBox.Text = ""
        return
    end
    
    local foundPlayer, resultName = findPlayerByPartialName(searchText)
    if foundPlayer then
        toggleTarget(foundPlayer, resultName)
        targetBox.Text = ""
    elseif foundPlayer == nil then
        searchResult.Text = "✓ Modo TODOS - escribe un nombre para añadir/quitar"
        searchResult.TextColor3 = Color3.fromRGB(120, 200, 255)
    else
        searchResult.Text = resultName
        searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
    end
    
    task.wait(2)
    if searchResult.Text:sub(1,1) == "✓" or searchResult.Text:sub(1,1) == "🗑️" or searchResult.Text:sub(1,1) == "⚠️" or searchResult.Text:find("no encontrado") then
        searchResult.Text = "Escribe nombre y presiona Enter"
        searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end

-- Crear las dos interfaces
local buttonsGUI, buttonsFrame, configButton = CreateButtonsInterface()
local configGUI, configFrame, closeConfigBtn = CreateConfigInterface()
@@ -1600,30 +1684,40 @@ end

if targetBox then
    targetBox.FocusLost:Connect(function(enter)
        if enter then searchAndSetTarget() end
        if enter then searchAndToggleTarget() end
    end)
end

if clearTargetBtn then
    clearTargetBtn.MouseButton1Click:Connect(clearTarget)
    clearTargetBtn.MouseButton1Click:Connect(clearTargets)
end

if removeLastBtn then
    removeLastBtn.MouseButton1Click:Connect(removeLastTarget)
end

if closestBtn then
    closestBtn.MouseButton1Click:Connect(targetClosest)
    closestBtn.MouseButton1Click:Connect(addClosestTarget)
end

-- Eventos de jugadores
-- Eventos de jugadores (actualizado para manejar múltiples targets)
Players.PlayerRemoving:Connect(function(p)
    if targetPlayer == p then
        targetPlayer = nil
        exactTargetName = "TODOS"
        if targetBox then targetBox.Text = "" end
    local wasRemoved = false
    for i, target in ipairs(targetPlayers) do
        if target == p then
            table.remove(targetPlayers, i)
            exactTargetNames[p] = nil
            wasRemoved = true
            break
        end
    end
    if wasRemoved then
        updateTargetStatus()
        if searchResult then
            searchResult.Text = "⚠️ Objetivo salió"
            searchResult.Text = "⚠️ " .. p.Name .. " salió del juego"
            searchResult.TextColor3 = Color3.fromRGB(255, 150, 50)
            task.wait(2)
            searchResult.Text = "Presiona Enter"
            searchResult.Text = "Escribe nombre y presiona Enter"
            searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
        if HitboxEnabled then
@@ -1634,16 +1728,39 @@ end)

Players.PlayerAdded:Connect(function(p)
    task.wait(1)
    if HitboxEnabled and shouldHitPlayer(p) then
        applyHitboxToPlayer(p)
    if HitboxEnabled then
        -- Solo aplicar hitbox si está en la lista de targets O si no hay targets específicos
        local isTarget = #targetPlayers == 0
        if not isTarget then
            for _, target in ipairs(targetPlayers) do
                if target == p then
                    isTarget = true
                    break
                end
            end
        end
        if isTarget and shouldHitPlayer(p) then
            applyHitboxToPlayer(p)
        end
    end
end)

for _, p in pairs(Players:GetPlayers()) do
    p.CharacterAdded:Connect(function(character)
        task.wait(0.5)
        if HitboxEnabled and shouldHitPlayer(p) then
            applyHitboxToPlayer(p)
        if HitboxEnabled then
            local isTarget = #targetPlayers == 0
            if not isTarget then
                for _, target in ipairs(targetPlayers) do
                    if target == p then
                        isTarget = true
                        break
                    end
                end
            end
            if isTarget and shouldHitPlayer(p) then
                applyHitboxToPlayer(p)
            end
        end
    end)
end
@@ -1685,12 +1802,9 @@ setHitboxSize(30)
setHitboxTransparency(0.5)

print("=== HITBOX EXPANDER + DAMAGE REPEATER OPTIMIZADO ===")
print("✅ TOGGLE TARGETS - Escribe un nombre: si está se quita, si no está se añade")
print("✅ Damage Repeater AHORA SOLO REPITE GOLPES - NO MÁS DEFORMACIÓN")
print("✅ Los jugadores en la lista de prohibidos NO son afectados por el repeater")
print("✅ Lista de eventos IGNORADOS para evitar deformación:")
print("   - Animation, Emote, Pose, Movement, Jump, Sit, Ragdoll, etc.")
print("✅ Lista de eventos que SÍ se repiten:")
print("   - Hit, Damage, MeleeHit, Punch, Kick, Attack, SwordHit, etc.")
print("✅ Límite de " .. MAX_REPEAT_PER_SECOND .. " repeticiones por segundo")
print("✅ Hitbox con transparencia funcional")
print("✅ Lista de prohibidos: " .. #PROHIBITED_USERS .. " usuarios")
