local config = require 'config.client'

function DropFingerprint()
    if IsWearingGloves() then return end
    if config.fingerprintChance > math.random(0, 100) then
        local coords = GetEntityCoords(cache.ped)
        TriggerServerEvent('evidence:server:CreateFingerDrop', coords)
    end
end