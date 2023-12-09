local sharedConfig = require 'config.shared'

RegisterNetEvent('qb-bankrobbery:client:ClearTimeoutDoors', function()
    --Config.DoorlockAction(4, true)
    local PaletoObject = GetClosestObjectOfType(sharedConfig.bigBanks["paleto"]["coords"]["x"], sharedConfig.bigBanks["paleto"]["coords"]["y"], sharedConfig.bigBanks["paleto"]["coords"]["z"], 5.0, sharedConfig.bigBanks["paleto"]["object"], false, false, false)
    if PaletoObject ~= 0 then
        SetEntityHeading(PaletoObject, sharedConfig.bigBanks["paleto"]["heading"].closed)
    end
    local object = GetClosestObjectOfType(sharedConfig.bigBanks["pacific"]["coords"][2]["x"], sharedConfig.bigBanks["pacific"]["coords"][2]["y"], sharedConfig.bigBanks["pacific"]["coords"][2]["z"], 20.0, sharedConfig.bigBanks["pacific"]["object"], false, false, false)
    if object ~= 0 then
        SetEntityHeading(object, sharedConfig.bigBanks["pacific"]["heading"].closed)
    end
    for k in pairs(sharedConfig.bigBanks["pacific"]["lockers"]) do
        sharedConfig.bigBanks["pacific"]["lockers"][k]["isBusy"] = false
        sharedConfig.bigBanks["pacific"]["lockers"][k]["isOpened"] = false
    end
    for k in pairs(sharedConfig.bigBanks["paleto"]["lockers"]) do
        sharedConfig.bigBanks["paleto"]["lockers"][k]["isBusy"] = false
        sharedConfig.bigBanks["paleto"]["lockers"][k]["isOpened"] = false
    end
    sharedConfig.bigBanks["paleto"]["isOpened"] = false
    sharedConfig.bigBanks["pacific"]["isOpened"] = false
end)

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local PaletoDist = #(pos - sharedConfig.bigBanks["paleto"]["coords"])
        local PacificDist = #(pos - sharedConfig.bigBanks["pacific"]["coords"][2])
        if PaletoDist < 15 then
            if sharedConfig.bigBanks["paleto"]["isOpened"] then
                --Config.DoorlockAction(4, false)
                local object = GetClosestObjectOfType(sharedConfig.bigBanks["paleto"]["coords"]["x"], sharedConfig.bigBanks["paleto"]["coords"]["y"], sharedConfig.bigBanks["paleto"]["coords"]["z"], 5.0, sharedConfig.bigBanks["paleto"]["object"], false, false, false)
                if object ~= 0 then
                    SetEntityHeading(object, sharedConfig.bigBanks["paleto"]["heading"].open)
                end
            else
                --Config.DoorlockAction(4, true)
                local object = GetClosestObjectOfType(sharedConfig.bigBanks["paleto"]["coords"]["x"], sharedConfig.bigBanks["paleto"]["coords"]["y"], sharedConfig.bigBanks["paleto"]["coords"]["z"], 5.0, sharedConfig.bigBanks["paleto"]["object"], false, false, false)
                if object ~= 0 then
                    SetEntityHeading(object, sharedConfig.bigBanks["paleto"]["heading"].closed)
                end
            end
        end

        -- Pacific Check
        if PacificDist < 50 then
            if sharedConfig.bigBanks["pacific"]["isOpened"] then
                local object = GetClosestObjectOfType(sharedConfig.bigBanks["pacific"]["coords"][2]["x"], sharedConfig.bigBanks["pacific"]["coords"][2]["y"], sharedConfig.bigBanks["pacific"]["coords"][2]["z"], 20.0, sharedConfig.bigBanks["pacific"]["object"], false, false, false)
                if object ~= 0 then
                    SetEntityHeading(object, sharedConfig.bigBanks["pacific"]["heading"].open)
                end
            else
                local object = GetClosestObjectOfType(sharedConfig.bigBanks["pacific"]["coords"][2]["x"], sharedConfig.bigBanks["pacific"]["coords"][2]["y"], sharedConfig.bigBanks["pacific"]["coords"][2]["z"], 20.0, sharedConfig.bigBanks["pacific"]["object"], false, false, false)
                if object ~= 0 then
                    SetEntityHeading(object, sharedConfig.bigBanks["pacific"]["heading"].closed)
                end
            end
        end
        Wait(1000)
    end
end)
