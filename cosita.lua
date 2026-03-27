local settings = {
    repeatamount = 26,
    -- Solo eventos de ataque
    attackEvents = {"AttackEvent", "DamageEvent", "HitEvent", "SwingEvent", "MeleeEvent"}
}

local mt = getrawmetatable(game)
local old = mt.__namecall
setreadonly(mt, false)

mt.__namecall = function(uh, ...)
    local method = getnamecallmethod()
    
    -- Verificar si es un evento remoto (FireServer/InvokeServer)
    if method == "FireServer" or method == "InvokeServer" then
        -- Verificar si el nombre del objeto coincide con algún evento de ataque
        for _, attackName in next, settings.attackEvents do
            if uh.Name == attackName then
                -- Repetir el ataque
                for i = 1, settings.repeatamount do
                    old(uh, ...)
                end
                break
            end
        end
    end
    
    return old(uh, ...)
end

setreadonly(mt, true)
