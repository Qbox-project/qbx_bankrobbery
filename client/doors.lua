local bigBanks = require 'config.shared'.bigBanks

RegisterNetEvent('qb-bankrobbery:client:ClearTimeoutDoors', function()
    --Config.DoorlockAction(4, true)
    local paletoObject = GetClosestObjectOfType(bigBanks.paleto.coords.x, bigBanks.paleto.coords.y, bigBanks.paleto.coords.z, 5.0, bigBanks.paleto.object, false, false, false)
    if paletoObject ~= 0 then
        SetEntityHeading(paletoObject, bigBanks.paleto.heading.closed)
    end
    local object = GetClosestObjectOfType(bigBanks.pacific.coords[2].x, bigBanks.pacific.coords[2].y, bigBanks.pacific.coords[2].z, 20.0, bigBanks.pacific.object, false, false, false)
    if object ~= 0 then
        SetEntityHeading(object, bigBanks.pacific.heading.closed)
    end
    for k in pairs(bigBanks.pacific.lockers) do
        bigBanks.pacific.lockers[k].isBusy = false
        bigBanks.pacific.lockers[k].isOpened = false
    end
    for k in pairs(bigBanks.paleto.lockers) do
        bigBanks.paleto.lockers[k].isBusy = false
        bigBanks.paleto.lockers[k].isOpened = false
    end
    bigBanks.paleto.isOpened = false
    bigBanks.pacific.isOpened = false
end)

CreateThread(function()
    while true do
        local pos = GetEntityCoords(cache.ped)
        local paletoDist = #(pos - bigBanks.paleto.coords)
        local pacificDist = #(pos - bigBanks.pacific.coords[2])
        if paletoDist < 15 then
            if bigBanks.paleto.isOpened then
                --Config.DoorlockAction(4, false)
                local object = GetClosestObjectOfType(bigBanks.paleto.coords.x, bigBanks.paleto.coords.y, bigBanks.paleto.coords.z, 5.0, bigBanks.paleto.object, false, false, false)
                if object ~= 0 then
                    SetEntityHeading(object, bigBanks.paleto.heading.open)
                end
            else
                --Config.DoorlockAction(4, true)
                local object = GetClosestObjectOfType(bigBanks.paleto.coords.x, bigBanks.paleto.coords.y, bigBanks.paleto.coords.z, 5.0, bigBanks.paleto.object, false, false, false)
                if object ~= 0 then
                    SetEntityHeading(object, bigBanks.paleto.heading.closed)
                end
            end
        end

        -- Pacific Check
        if pacificDist < 50 then
            if bigBanks.pacific.isOpened then
                local object = GetClosestObjectOfType(bigBanks.pacific.coords[2].x, bigBanks.pacific.coords[2].y, bigBanks.pacific.coords[2].z, 20.0, bigBanks.pacific.object, false, false, false)
                if object ~= 0 then
                    SetEntityHeading(object, bigBanks.pacific.heading.open)
                end
            else
                local object = GetClosestObjectOfType(bigBanks.pacific.coords[2].x, bigBanks.pacific.coords[2].y, bigBanks.pacific.coords[2].z, 20.0, bigBanks.pacific.object, false, false, false)
                if object ~= 0 then
                    SetEntityHeading(object, bigBanks.pacific.heading.closed)
                end
            end
        end
        Wait(1000)
    end
end)
