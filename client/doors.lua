local sharedConfig = require 'config.shared'

local function resetDoor(object, bank)
    local heading = bank.isOpened and bank.heading.open or bank.heading.closed
    SetEntityHeading(object, heading)
end

function ResetBankDoors()
    for k in pairs(sharedConfig.smallBanks) do
        local coords = sharedConfig.smallBanks[k].coords
        local object = GetClosestObjectOfType(coords.x, coords.y, coords.z, 5.0, sharedConfig.smallBanks[k].object, false, false, false)
        resetDoor(object, sharedConfig.smallBanks[k])
    end

    local paletoCoords = sharedConfig.bigBanks.paleto.coords
    local paletoObject = GetClosestObjectOfType(paletoCoords.x, paletoCoords.y, paletoCoords.z, 5.0, sharedConfig.bigBanks.paleto.object, false, false, false)
    resetDoor(paletoObject, sharedConfig.bigBanks.paleto)

    local pacificCoords = sharedConfig.bigBanks.pacific.coords[2]
    local pacificObject = GetClosestObjectOfType(pacificCoords.x, pacificCoords.y, pacificCoords.z, 20.0, sharedConfig.bigBanks.pacific.object, false, false, false)
    resetDoor(pacificObject, sharedConfig.bigBanks.pacific)
end

--- This will open the bank door of any small bank
--- @param bankId number
--- @return nil
function OpenFleecaDoor(bankId)
    local object = GetClosestObjectOfType(sharedConfig.smallBanks[bankId].coords.x, sharedConfig.smallBanks[bankId].coords.y, sharedConfig.smallBanks[bankId].coords.z, 5.0, sharedConfig.smallBanks[bankId].object, false, false, false)
    local entHeading = sharedConfig.smallBanks[bankId].heading.closed
    if object ~= 0 then
        CreateThread(function()
            while entHeading ~= sharedConfig.smallBanks[bankId].heading.open do
                SetEntityHeading(object, entHeading - 10)
                entHeading -= 0.5
                Wait(10)
            end
        end)
    end
end

--- This will open the bank door of the pacific bank
--- @return nil
function OpenPacificDoor()
    local object = GetClosestObjectOfType(sharedConfig.bigBanks.pacific.coords[2].x, sharedConfig.bigBanks.pacific.coords[2].y, sharedConfig.bigBanks.pacific.coords[2].z, 20.0, sharedConfig.bigBanks.pacific.object, false, false, false)
    local entHeading = sharedConfig.bigBanks.pacific.heading.closed
    if object ~= 0 then
        CreateThread(function()
            while entHeading > sharedConfig.bigBanks.pacific.heading.open do
                SetEntityHeading(object, entHeading - 10)
                entHeading -= 0.5
                Wait(10)
            end
        end)
    end
end

--- This will open the bank door of the paleto bank
--- @return nil
function OpenPaletoDoor()
    --Config.DoorlockAction(4, false)
    local object = GetClosestObjectOfType(sharedConfig.bigBanks.paleto.coords.x, sharedConfig.bigBanks.paleto.coords.y, sharedConfig.bigBanks.paleto.coords.z, 5.0, sharedConfig.bigBanks.paleto.object, false, false, false)
    if object ~= 0 then
        SetEntityHeading(object, sharedConfig.bigBanks.paleto.heading.open)
    end
end

RegisterNetEvent('qbx_bankrobbery:client:ClearTimeoutDoors', function()
    --Config.DoorlockAction(4, true)
    local paletoObject = GetClosestObjectOfType(sharedConfig.bigBanks.paleto.coords.x, sharedConfig.bigBanks.paleto.coords.y, sharedConfig.bigBanks.paleto.coords.z, 5.0, sharedConfig.bigBanks.paleto.object, false, false, false)
    if paletoObject ~= 0 then
        SetEntityHeading(paletoObject, sharedConfig.bigBanks.paleto.heading.closed)
    end
    local object = GetClosestObjectOfType(sharedConfig.bigBanks.pacific.coords[2].x, sharedConfig.bigBanks.pacific.coords[2].y, sharedConfig.bigBanks.pacific.coords[2].z, 20.0, sharedConfig.bigBanks.pacific.object, false, false, false)
    if object ~= 0 then
        SetEntityHeading(object, sharedConfig.bigBanks.pacific.heading.closed)
    end
    for k in pairs(sharedConfig.bigBanks.pacific.lockers) do
        sharedConfig.bigBanks.pacific.lockers[k].isBusy = false
        sharedConfig.bigBanks.pacific.lockers[k].isOpened = false
    end
    for k in pairs(sharedConfig.bigBanks.paleto.lockers) do
        sharedConfig.bigBanks.paleto.lockers[k].isBusy = false
        sharedConfig.bigBanks.paleto.lockers[k].isOpened = false
    end
    sharedConfig.bigBanks.paleto.isOpened = false
    sharedConfig.bigBanks.pacific.isOpened = false
end)

CreateThread(function()
    while true do
        local pos = GetEntityCoords(cache.ped)
        local paletoDist = #(pos - sharedConfig.bigBanks.paleto.coords)
        local pacificDist = #(pos - sharedConfig.bigBanks.pacific.coords[2])
        if paletoDist < 15 then
            if sharedConfig.bigBanks.paleto.isOpened then
                --Config.DoorlockAction(4, false)
                local object = GetClosestObjectOfType(sharedConfig.bigBanks.paleto.coords.x, sharedConfig.bigBanks.paleto.coords.y, sharedConfig.bigBanks.paleto.coords.z, 5.0, sharedConfig.bigBanks.paleto.object, false, false, false)
                if object ~= 0 then
                    SetEntityHeading(object, sharedConfig.bigBanks.paleto.heading.open)
                end
            else
                --Config.DoorlockAction(4, true)
                local object = GetClosestObjectOfType(sharedConfig.bigBanks.paleto.coords.x, sharedConfig.bigBanks.paleto.coords.y, sharedConfig.bigBanks.paleto.coords.z, 5.0, sharedConfig.bigBanks.paleto.object, false, false, false)
                if object ~= 0 then
                    SetEntityHeading(object, sharedConfig.bigBanks.paleto.heading.closed)
                end
            end
        end

        -- Pacific Check
        if pacificDist < 50 then
            if sharedConfig.bigBanks.pacific.isOpened then
                local object = GetClosestObjectOfType(sharedConfig.bigBanks.pacific.coords[2].x, sharedConfig.bigBanks.pacific.coords[2].y, sharedConfig.bigBanks.pacific.coords[2].z, 20.0, sharedConfig.bigBanks.pacific.object, false, false, false)
                if object ~= 0 then
                    SetEntityHeading(object, sharedConfig.bigBanks.pacific.heading.open)
                end
            else
                local object = GetClosestObjectOfType(sharedConfig.bigBanks.pacific.coords[2].x, sharedConfig.bigBanks.pacific.coords[2].y, sharedConfig.bigBanks.pacific.coords[2].z, 20.0, sharedConfig.bigBanks.pacific.object, false, false, false)
                if object ~= 0 then
                    SetEntityHeading(object, sharedConfig.bigBanks.pacific.heading.closed)
                end
            end
        end
        Wait(1000)
    end
end)
