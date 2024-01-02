local config = require 'config.client'
local sharedConfig = require 'config.shared'
isLoggedIn = LocalPlayer.state['isLoggedIn']
currentThermiteGate = 0
CurrentCops = 0
isDrilling = false
local closestBank = 0
local inElectronickitZone = false
local copsCalled = false
local refreshed = false
local currentLocker = 0

-- Handlers

--- This will reset the bank doors to the position that they should be in, so if the bank is still open, it will open the door and vise versa
--- @return nil
local function resetBankDoors()
    for k in pairs(sharedConfig.smallBanks) do
        local object = GetClosestObjectOfType(sharedConfig.smallBanks[k].coords.x, sharedConfig.smallBanks[k].coords.y, sharedConfig.smallBanks[k].coords.z, 5.0, sharedConfig.smallBanks[k].object, false, false, false)
        if not sharedConfig.smallBanks[k].isOpened then
            SetEntityHeading(object, sharedConfig.smallBanks[k].heading.closed)
        else
            SetEntityHeading(object, sharedConfig.smallBanks[k].heading.open)
        end
    end
    if not sharedConfig.bigBanks.paleto.isOpened then
        local paletoObject = GetClosestObjectOfType(sharedConfig.bigBanks.paleto.coords.x, sharedConfig.bigBanks.paleto.coords.y, sharedConfig.bigBanks.paleto.coords.z, 5.0, sharedConfig.bigBanks.paleto.object, false, false, false)
        SetEntityHeading(paletoObject, sharedConfig.bigBanks.paleto.heading.closed)
    else
        local paletoObject = GetClosestObjectOfType(sharedConfig.bigBanks.paleto.coords.x, sharedConfig.bigBanks.paleto.coords.y, sharedConfig.bigBanks.paleto.coords.z, 5.0, sharedConfig.bigBanks.paleto.object, false, false, false)
        SetEntityHeading(paletoObject, sharedConfig.bigBanks.paleto.heading.open)
    end
    if not sharedConfig.bigBanks.pacific.isOpened then
        local pacificObject = GetClosestObjectOfType(sharedConfig.bigBanks.pacific.coords[2].x, sharedConfig.bigBanks.pacific.coords[2].y, sharedConfig.bigBanks.pacific.coords[2].z, 20.0, sharedConfig.bigBanks.pacific.object, false, false, false)
        SetEntityHeading(pacificObject, sharedConfig.bigBanks.pacific.heading.closed)
    else
        local pacificObject = GetClosestObjectOfType(sharedConfig.bigBanks.pacific.coords[2].x, sharedConfig.bigBanks.pacific.coords[2].y, sharedConfig.bigBanks.pacific.coords[2].z, 20.0, sharedConfig.bigBanks.pacific.object, false, false, false)
        SetEntityHeading(pacificObject, sharedConfig.bigBanks.pacific.heading.open)
    end
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    resetBankDoors()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    local config1, config2, config3 = lib.callback.await('qb-bankrobbery:server:GetConfig', false)
    sharedConfig.powerStations = config1
    sharedConfig.bigBanks = config2
    sharedConfig.smallBanks = config3
    resetBankDoors()
    isLoggedIn = true
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    isLoggedIn = false
end)

-- Functions

--- This will open the bank door of the paleto bank
--- @return nil
local function openPaletoDoor()
    --Config.DoorlockAction(4, false)
    local object = GetClosestObjectOfType(sharedConfig.bigBanks.paleto.coords.x, sharedConfig.bigBanks.paleto.coords.y, sharedConfig.bigBanks.paleto.coords.z, 5.0, sharedConfig.bigBanks.paleto.object, false, false, false)
    if object ~= 0 then
        SetEntityHeading(object, sharedConfig.bigBanks.paleto.heading.open)
    end
end

--- This will open the bank door of the pacific bank
--- @return nil
local function openPacificDoor()
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

--- This is triggered once the hack at a small bank is done
--- @param success boolean
--- @return nil
local function onHackDone(success)
    TriggerEvent('mhacking:hide')
    if not success then return end
    TriggerServerEvent('qb-bankrobbery:server:setBankState', closestBank)
end

--- This will open the bank door of any small bank
--- @param bankId number
--- @return nil
local function openBankDoor(bankId)
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

--- This will trigger the sequence of opening a safe locker of a bank
--- @param bankId string | number
--- @param lockerId number
--- @return nil
function openLocker(bankId, lockerId) -- Globally Used
    local pos = GetEntityCoords(cache.ped)
    DropFingerprint()
    TriggerServerEvent('qb-bankrobbery:server:setLockerState', bankId, lockerId, 'isBusy', true)
    if bankId == 'paleto' then
        local hasItem = exports.ox_inventory:Search('count', 'drill') > 0
        if hasItem then
            -- loadAnimDict('anim@heists@fleeca_bank@drilling')
            -- TaskPlayAnim(cache.ped, 'anim@heists@fleeca_bank@drilling', 'drill_straight_idle', 3.0, 3.0, -1, 1, 0, false, false, false)
            local drillObject = CreateObject(`hei_prop_heist_drill`, pos.x, pos.y, pos.z, true, true, true)
            AttachEntityToEntity(drillObject, cache.ped, GetPedBoneIndex(cache.ped, 57005), 0.14, 0, -0.01, 90.0, -90.0, 180.0, true, true, false, true, 1, true)
            isDrilling = true
            if lib.progressBar({
                duration = 25000,
                label = Lang:t('general.breaking_open_safe'),
                canCancel = true,
                useWhileDead = false,
                disable = {
                    move = true,
                    car = true,
                    mouse = false,
                    combat = true
                },
                anim = {
                    dict = 'anim@heists@fleeca_bank@drilling',
                    clip = 'drill_straight_idle',
                    flag = 1
                }
            }) then
                DetachEntity(drillObject, true, true)
                DeleteObject(drillObject)
                TriggerServerEvent('qb-bankrobbery:server:setLockerState', bankId, lockerId, 'isOpened', true)
                TriggerServerEvent('qb-bankrobbery:server:setLockerState', bankId, lockerId, 'isBusy', false)
                TriggerServerEvent('qb-bankrobbery:server:recieveItem', 'paleto', bankId, lockerId)
                exports.qbx_core:Notify(Lang:t('success.success_message'), 'success')
                SetTimeout(500, function()
                    isDrilling = false
                end)
            else
                TriggerServerEvent('qb-bankrobbery:server:setLockerState', bankId, lockerId, 'isBusy', false)
                DetachEntity(drillObject, true, true)
                DeleteObject(drillObject)
                exports.qbx_core:Notify(Lang:t('error.cancel_message'), 'error')
                SetTimeout(500, function()
                    isDrilling = false
                end)
            end
        else
            exports.qbx_core:Notify(Lang:t('error.safe_too_strong'), 'error')
            TriggerServerEvent('qb-bankrobbery:server:setLockerState', bankId, lockerId, 'isBusy', false)
        end
    elseif bankId == 'pacific' then
        local hasItem = exports.ox_inventory:Search('count', 'drill') > 0
        if hasItem then
            local drillObject = CreateObject(`hei_prop_heist_drill`, pos.x, pos.y, pos.z, true, true, true)
            AttachEntityToEntity(drillObject, cache.ped, GetPedBoneIndex(cache.ped, 57005), 0.14, 0, -0.01, 90.0, -90.0, 180.0, true, true, false, true, 1, true)
            isDrilling = true
            if lib.progressBar({
                duration = 25000,
                label = Lang:t('general.breaking_open_safe'),
                canCancel = true,
                useWhileDead = false,
                disable = {
                    move = true,
                    car = true,
                    mouse = false,
                    combat = true
                },
                anim = {
                    dict = 'anim@heists@fleeca_bank@drilling',
                    clip = 'drill_straight_idle',
                    flag = 1
                }
            }) then
                DetachEntity(drillObject, true, true)
                DeleteObject(drillObject)

                TriggerServerEvent('qb-bankrobbery:server:setLockerState', bankId, lockerId, 'isOpened', true)
                TriggerServerEvent('qb-bankrobbery:server:setLockerState', bankId, lockerId, 'isBusy', false)
                TriggerServerEvent('qb-bankrobbery:server:recieveItem', 'pacific', bankId, lockerId)
                exports.qbx_core:Notify(Lang:t('success.success_message'), 'success')
                SetTimeout(500, function()
                    isDrilling = false
                end)
            else
                TriggerServerEvent('qb-bankrobbery:server:setLockerState', bankId, lockerId, 'isBusy', false)
                DetachEntity(drillObject, true, true)
                DeleteObject(drillObject)
                exports.qbx_core:Notify(Lang:t('error.cancel_message'), 'error')
                SetTimeout(500, function()
                    isDrilling = false
                end)
            end
        else
            exports.qbx_core:Notify(Lang:t('error.safe_too_strong'), 'error')
            TriggerServerEvent('qb-bankrobbery:server:setLockerState', bankId, lockerId, 'isBusy', false)
        end
    else
        isDrilling = true
        if lib.progressBar({
            duration = 32000,
            label = Lang:t('general.breaking_open_safe'),
            canCancel = true,
            useWhileDead = false,
            disable = {
                move = true,
                car = true,
                mouse = false,
                combat = true
            },
            anim = {
                dict = 'anim@gangops@facility@servers@',
                clip = 'hotwire',
                flag = 1
            }
        }) then
            TriggerServerEvent('qb-bankrobbery:server:setLockerState', bankId, lockerId, 'isOpened', true)
            TriggerServerEvent('qb-bankrobbery:server:setLockerState', bankId, lockerId, 'isBusy', false)
            TriggerServerEvent('qb-bankrobbery:server:recieveItem', 'small', bankId, lockerId)
            exports.qbx_core:Notify(Lang:t('success.success_message'), 'success')
            SetTimeout(500, function()
                isDrilling = false
            end)
        else
            TriggerServerEvent('qb-bankrobbery:server:setLockerState', bankId, lockerId, 'isBusy', false)
            exports.qbx_core:Notify(Lang:t('error.cancel_message'), 'error')
            SetTimeout(500, function()
                isDrilling = false
            end)
        end
    end
    CreateThread(function()
        while isDrilling do
            TriggerServerEvent('hud:server:GainStress', math.random(4, 8))
            Wait(10000)
        end
    end)
end

-- Events

RegisterNetEvent('electronickit:UseElectronickit', function()
    DropFingerprint()

    if closestBank == 0 or not inElectronickitZone then return end

    local isBusy = lib.callback.await('qb-bankrobbery:server:isRobberyActive', false)
    if isBusy then return exports.qbx_core:Notify(Lang:t('error.security_lock_active'), 'error', 5500) end

    if CurrentCops < config.minFleecaPolice then return exports.qbx_core:Notify(Lang:t('error.minimum_police_required', {police = config.minFleecaPolice}), 'error') end
    if sharedConfig.smallBanks[closestBank].isOpened then return exports.qbx_core:Notify(Lang:t('error.bank_already_open'), 'error') end

    local hasItems = (exports.ox_inventory:Search('count', 'trojan_usb') > 0) and (exports.ox_inventory:Search('count', 'electronickit') > 0)
    if not hasItems then return exports.qbx_core:Notify(Lang:t('error.missing_item'), 'error') end

    if lib.progressBar({
        duration = 7500,
        label = Lang:t('general.connecting_hacking_device'),
        canCancel = true,
        useWhileDead = false,
        disable = {
            move = true,
            car = true,
            mouse = false,
            combat = true
        },
        anim = {
            dict = 'anim@gangops@facility@servers@',
            clip = 'hotwire',
            flag = 1
        }
    }) then
        TriggerServerEvent('qb-bankrobbery:server:removeElectronicKit')
        TriggerEvent('mhacking:show')
        TriggerEvent('mhacking:start', math.random(6, 7), math.random(12, 15), onHackDone)
        if copsCalled or not sharedConfig.smallBanks[closestBank].alarm then return end
        TriggerServerEvent('qb-bankrobbery:server:callCops', 'small', closestBank, sharedConfig.smallBanks[closestBank].coords)
        copsCalled = true
        SetTimeout(60000 * config.outlawCooldown, function() copsCalled = false end)
    else
        exports.qbx_core:Notify(Lang:t('error.cancel_message'), 'error')
    end
end)

RegisterNetEvent('qb-bankrobbery:client:setBankState', function(bankId)
    if bankId == 'paleto' then
        sharedConfig.bigBanks.paleto.isOpened = true
        openPaletoDoor()
    elseif bankId == 'pacific' then
        sharedConfig.bigBanks.pacific.isOpened = true
        openPacificDoor()
    else
        sharedConfig.smallBanks[bankId].isOpened = true
        openBankDoor(bankId)
    end
end)

RegisterNetEvent('qb-bankrobbery:client:enableAllBankSecurity', function()
    for k in pairs(sharedConfig.smallBanks) do
        sharedConfig.smallBanks[k].alarm = true
    end
end)

RegisterNetEvent('qb-bankrobbery:client:disableAllBankSecurity', function()
    for k in pairs(sharedConfig.smallBanks) do
        sharedConfig.smallBanks[k].alarm = false
    end
end)

RegisterNetEvent('qb-bankrobbery:client:BankSecurity', function(key, status)
    if type(key) == 'table' and table.type(key) == 'array' then
        for _, v in pairs(key) do
            sharedConfig.smallBanks[v].alarm = status
        end
    elseif type(key) == 'number' then
        sharedConfig.smallBanks[key].alarm = status
    else
        error(Lang:t('error.wrong_type', {receiver = 'qb-bankrobbery:client:BankSecurity', argument = 'key', receivedType = type(key), receivedValue = key, expected = 'table/array'}))
    end
end)

RegisterNetEvent('qb-bankrobbery:client:setLockerState', function(bankId, lockerId, state, bool)
    if bankId == 'paleto' then
        sharedConfig.bigBanks.paleto.lockers[lockerId][state] = bool
    elseif bankId == 'pacific' then
        sharedConfig.bigBanks.pacific.lockers[lockerId][state] = bool
    else
        sharedConfig.smallBanks[bankId].lockers[lockerId][state] = bool
    end
end)

RegisterNetEvent('qb-bankrobbery:client:ResetFleecaLockers', function(BankId)
    sharedConfig.smallBanks[BankId].isOpened = false
    for k in pairs(sharedConfig.smallBanks[BankId].lockers) do
        sharedConfig.smallBanks[BankId].lockers[k].isOpened = false
        sharedConfig.smallBanks[BankId].lockers[k].isBusy = false
    end
end)

RegisterNetEvent('qb-bankrobbery:client:robberyCall', function(type, coords)
    if not isLoggedIn then return end
    local PlayerJob = exports.qbx_core:GetPlayerData().job
    if PlayerJob.name ~= 'police' or not PlayerJob.onduty then return end
    if type == 'small' then
        PlaySound(-1, 'Lose_1st', 'GTAO_FM_Events_Soundset', false, 0, true)
        TriggerServerEvent('police:server:policeAlert', Lang:t('general.fleeca_robbery_alert'))
    elseif type == 'paleto' then
        PlaySound(-1, 'Lose_1st', 'GTAO_FM_Events_Soundset', false, 0, true)
        Wait(100)
        PlaySoundFrontend( -1, 'Beep_Red', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true)
        Wait(100)
        PlaySound(-1, 'Lose_1st', 'GTAO_FM_Events_Soundset', false, 0, true)
        Wait(100)
        PlaySoundFrontend( -1, 'Beep_Red', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true)
        TriggerServerEvent('police:server:policeAlert', Lang:t('general.paleto_robbery_alert'))
    elseif type == 'pacific' then
        PlaySound(-1, 'Lose_1st', 'GTAO_FM_Events_Soundset', false, 0, true)
        Wait(100)
        PlaySoundFrontend( -1, 'Beep_Red', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true)
        Wait(100)
        PlaySound(-1, 'Lose_1st', 'GTAO_FM_Events_Soundset', false, 0, true)
        Wait(100)
        PlaySoundFrontend( -1, 'Beep_Red', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true)
        TriggerServerEvent('police:server:policeAlert', Lang:t('general.pacific_robbery_alert'))
    end
    local transG = 250
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 487)
    SetBlipColour(blip, 4)
    SetBlipDisplay(blip, 4)
    SetBlipAlpha(blip, transG)
    SetBlipScale(blip, 1.2)
    SetBlipFlashes(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Lang:t('general.bank_robbery_police_call'))
    EndTextCommandSetBlipName(blip)
    while transG ~= 0 do
        Wait(180 * 4)
        transG = transG - 1
        SetBlipAlpha(blip, transG)
        if transG == 0 then
            SetBlipSprite(blip, 2)
            RemoveBlip(blip)
            return
        end
    end
end)

CreateThread(function()
    while true do
        if closestBank ~= 0 then
            if not refreshed then
                resetBankDoors()
                refreshed = true
            end
        else
            refreshed = false
        end
        Wait(1000)
    end
end)

CreateThread(function()
    while true do -- This is kept for the resetBankDoors function to be executed outside of the polyzone
        local pos = GetEntityCoords(cache.ped)
        local inRange = false
        if isLoggedIn then
            for k, v in pairs(sharedConfig.smallBanks) do
                local dist = #(pos - v.coords)
                if dist < 15 then
                    closestBank = k
                    inRange = true
                end
            end
            if not inRange then closestBank = 0 end
        end
        Wait(1000)
    end
end)

CreateThread(function()
    for i = 1, #sharedConfig.smallBanks do
        lib.zones.box({
            name = 'fleeca_'..i..'_coords_electronickit',
            coords = sharedConfig.smallBanks[i].coords,
            size = vec3(1, 1, 2),
            rotation = sharedConfig.smallBanks[i].coords.closed,
            debug = false
        })
        for k in pairs(sharedConfig.smallBanks[i].lockers) do
            if config.useTarget then
                exports.ox_target:addBoxZone({
                    coords = sharedConfig.smallBanks[i].lockers[k].coords,
                    size = vec3(1, 1, 2),
                    rotation = sharedConfig.smallBanks[i].heading.closed,
                    debug = false,
                    drawSprite = true,
                    options = {
                        {
                            label = Lang:t('general.break_safe_open_option_target'),
                            name = 'fleeca_'..i..'_coords_locker_'..k,
                            icon = 'fa-solid fa-vault',
                            distance = 1.5,
                            canInteract = function()
                                return closestBank ~= 0 and not isDrilling and sharedConfig.smallBanks[i].isOpened and not sharedConfig.smallBanks[i].lockers[k].isOpened and not sharedConfig.smallBanks[i].lockers[k].isBusy
                            end,
                            onSelect = function()
                                openLocker(closestBank, k)
                            end,
                        },
                    },
                })
            else
                lib.zones.box({
                    name = 'fleeca_'..i..'_coords_locker_'..k,
                    coords = sharedConfig.smallBanks[i].lockers[k].coords,
                    size = vec3(1, 1, 2),
                    rotation = sharedConfig.smallBanks[i].heading.closed,
                    debug = false,
                    onEnter = function()
                        if closestBank ~= 0 and not isDrilling and sharedConfig.smallBanks[i].isOpened and not sharedConfig.smallBanks[i].lockers[k].isOpened and not sharedConfig.smallBanks[i].lockers[k].isBusy then
                            lib.showTextUI(Lang:t('general.break_safe_open_option_drawtext'), {position = 'right-center'})
                            currentLocker = k
                        end
                    end,
                    onExit = function()
                        if currentLocker == k then
                            currentLocker = 0
                            lib.hideTextUI()
                        end
                    end,
                })
            end
        end
    end
    if not config.useTarget then
        while true do
            local sleep = 1000
            if isLoggedIn then
                for i = 1, #sharedConfig.smallBanks do
                    if currentLocker ~= 0 and not isDrilling and sharedConfig.smallBanks[i].isOpened and not sharedConfig.smallBanks[i].lockers[currentLocker].isOpened and not sharedConfig.smallBanks[i].lockers[currentLocker].isBusy then
                        sleep = 0
                        if IsControlJustPressed(0, 38) then
                            lib.hideTextUI()
                            Wait(500)
                            if CurrentCops >= config.minFleecaPolice then
                                openLocker(closestBank, currentLocker)
                            else
                                exports.qbx_core:Notify(Lang:t('error.minimum_police_required', {police = config.minFleecaPolice}), 'error')
                            end
                            sleep = 1000
                        end
                    end
                end
            end
            Wait(sleep)
        end
    end
end)
