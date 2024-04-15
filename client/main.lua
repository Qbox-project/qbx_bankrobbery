local config = require 'config.client'
local sharedConfig = require 'config.shared'
isLoggedIn = LocalPlayer.state.isLoggedIn
isDrilling = false

function DropFingerprint()
    if qbx.isWearingGloves() then return end
    if config.fingerprintChance > math.random(0, 100) then
        local coords = GetEntityCoords(cache.ped)
        TriggerServerEvent('evidence:server:CreateFingerDrop', coords)
    end
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    ResetBankDoors()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    local config1, config2, config3 = lib.callback.await('qbx_bankrobbery:server:GetConfig', false)
    sharedConfig.powerStations = config1
    sharedConfig.bigBanks = config2
    sharedConfig.smallBanks = config3
    ResetBankDoors()
    isLoggedIn = true
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    isLoggedIn = false
end)

RegisterNetEvent('qbx_bankrobbery:client:setBankState', function(bankId)
    if bankId == 'paleto' then
        sharedConfig.bigBanks.paleto.isOpened = true
        OpenPaletoDoor()
    elseif bankId == 'pacific' then
        sharedConfig.bigBanks.pacific.isOpened = true
        OpenPacificDoor()
    else
        sharedConfig.smallBanks[bankId].isOpened = true
        OpenFleecaDoor(bankId)
    end
end)

RegisterNetEvent('qbx_bankrobbery:client:setLockerState', function(bankId, lockerId, state, bool)
    if bankId == 'paleto' then
        sharedConfig.bigBanks.paleto.lockers[lockerId][state] = bool
    elseif bankId == 'pacific' then
        sharedConfig.bigBanks.pacific.lockers[lockerId][state] = bool
    else
        sharedConfig.smallBanks[bankId].lockers[lockerId][state] = bool
    end
end)

--- This will trigger the sequence of opening a safe locker of a bank
--- @param bankId string | number
--- @param lockerId number
--- @return nil
function OpenLocker(bankId, lockerId) -- Globally Used
    local pos = GetEntityCoords(cache.ped)
    DropFingerprint()
    TriggerServerEvent('qbx_bankrobbery:server:setLockerState', bankId, lockerId, 'isBusy', true)
    if bankId == 'paleto' then
        local hasItem = exports.ox_inventory:Search('count', 'drill') > 0
        if hasItem then
            -- loadAnimDict('anim@heists@fleeca_bank@drilling')
            -- TaskPlayAnim(cache.ped, 'anim@heists@fleeca_bank@drilling', 'drill_straight_idle', 3.0, 3.0, -1, 1, 0, false, false, false)
            local drillObject = CreateObject(`hei_prop_heist_drill`, pos.x, pos.y, pos.z, true, true, true)
            AttachEntityToEntity(drillObject, cache.ped, GetPedBoneIndex(cache.ped, 57005), 0.14, 0, -0.01, 90.0, -90.0, 180.0, true, true, false, true, 1, true)
            isDrilling = true
            if lib.progressBar({
                duration = 20000,
                label = locale('general.breaking_open_safe'),
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
                TriggerServerEvent('qbx_bankrobbery:server:setLockerState', bankId, lockerId, 'isOpened', true)
                TriggerServerEvent('qbx_bankrobbery:server:setLockerState', bankId, lockerId, 'isBusy', false)
                TriggerServerEvent('qbx_bankrobbery:server:recieveItem', 'paleto', bankId, lockerId)
                exports.qbx_core:Notify(locale('success.success_message'), 'success')
                SetTimeout(500, function()
                    isDrilling = false
                end)
            else
                TriggerServerEvent('qbx_bankrobbery:server:setLockerState', bankId, lockerId, 'isBusy', false)
                DetachEntity(drillObject, true, true)
                DeleteObject(drillObject)
                exports.qbx_core:Notify(locale('error.cancel_message'), 'error')
                SetTimeout(500, function()
                    isDrilling = false
                end)
            end
        else
            exports.qbx_core:Notify(locale('error.safe_too_strong'), 'error')
            TriggerServerEvent('qbx_bankrobbery:server:setLockerState', bankId, lockerId, 'isBusy', false)
        end
    elseif bankId == 'pacific' then
        local hasItem = exports.ox_inventory:Search('count', 'drill') > 0
        if hasItem then
            local drillObject = CreateObject(`hei_prop_heist_drill`, pos.x, pos.y, pos.z, true, true, true)
            AttachEntityToEntity(drillObject, cache.ped, GetPedBoneIndex(cache.ped, 57005), 0.14, 0, -0.01, 90.0, -90.0, 180.0, true, true, false, true, 1, true)
            isDrilling = true
            if lib.progressBar({
                duration = 20000,
                label = locale('general.breaking_open_safe'),
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

                TriggerServerEvent('qbx_bankrobbery:server:setLockerState', bankId, lockerId, 'isOpened', true)
                TriggerServerEvent('qbx_bankrobbery:server:setLockerState', bankId, lockerId, 'isBusy', false)
                TriggerServerEvent('qbx_bankrobbery:server:recieveItem', 'pacific', bankId, lockerId)
                exports.qbx_core:Notify(locale('success.success_message'), 'success')
                SetTimeout(500, function()
                    isDrilling = false
                end)
            else
                TriggerServerEvent('qbx_bankrobbery:server:setLockerState', bankId, lockerId, 'isBusy', false)
                DetachEntity(drillObject, true, true)
                DeleteObject(drillObject)
                exports.qbx_core:Notify(locale('error.cancel_message'), 'error')
                SetTimeout(500, function()
                    isDrilling = false
                end)
            end
        else
            exports.qbx_core:Notify(locale('error.safe_too_strong'), 'error')
            TriggerServerEvent('qbx_bankrobbery:server:setLockerState', bankId, lockerId, 'isBusy', false)
        end
    else
        isDrilling = true
        if lib.progressBar({
            duration = 20000,
            label = locale('general.breaking_open_safe'),
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
            TriggerServerEvent('qbx_bankrobbery:server:setLockerState', bankId, lockerId, 'isOpened', true)
            TriggerServerEvent('qbx_bankrobbery:server:setLockerState', bankId, lockerId, 'isBusy', false)
            TriggerServerEvent('qbx_bankrobbery:server:recieveItem', 'small', bankId, lockerId)
            exports.qbx_core:Notify(locale('success.success_message'), 'success')
            SetTimeout(500, function()
                isDrilling = false
            end)
        else
            TriggerServerEvent('qbx_bankrobbery:server:setLockerState', bankId, lockerId, 'isBusy', false)
            exports.qbx_core:Notify(locale('error.cancel_message'), 'error')
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

RegisterNetEvent('qbx_bankrobbery:client:robberyCall', function(type, coords)
    if not isLoggedIn or QBX.PlayerData.job.type ~= 'leo' or not QBX.PlayerData.job.onduty then return end
    if type == 'small' then
        PlaySound(-1, 'Lose_1st', 'GTAO_FM_Events_Soundset', false, 0, true)
        TriggerServerEvent('police:server:policeAlert', locale('general.fleeca_robbery_alert'))
    elseif type == 'paleto' then
        PlaySound(-1, 'Lose_1st', 'GTAO_FM_Events_Soundset', false, 0, true)
        Wait(100)
        PlaySoundFrontend( -1, 'Beep_Red', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true)
        Wait(100)
        PlaySound(-1, 'Lose_1st', 'GTAO_FM_Events_Soundset', false, 0, true)
        Wait(100)
        PlaySoundFrontend( -1, 'Beep_Red', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true)
        TriggerServerEvent('police:server:policeAlert', locale('general.paleto_robbery_alert'))
    elseif type == 'pacific' then
        PlaySound(-1, 'Lose_1st', 'GTAO_FM_Events_Soundset', false, 0, true)
        Wait(100)
        PlaySoundFrontend( -1, 'Beep_Red', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true)
        Wait(100)
        PlaySound(-1, 'Lose_1st', 'GTAO_FM_Events_Soundset', false, 0, true)
        Wait(100)
        PlaySoundFrontend( -1, 'Beep_Red', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true)
        TriggerServerEvent('police:server:policeAlert', locale('general.pacific_robbery_alert'))
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
    AddTextComponentString(locale('general.bank_robbery_police_call'))
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