local config = require 'config.client'

function DropFingerprint()
    if IsWearingGloves() then return end

    local coords = GetEntityCoords(cache.ped)
    if config.fingerprintChance > math.random(0, 100) then
        TriggerServerEvent('evidence:server:CreateFingerDrop', coords)
    end
end